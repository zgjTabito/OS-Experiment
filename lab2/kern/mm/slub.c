#include <string.h>
#include <memlayout.h>
#include <pmm.h>
#include <slub.h>
#include <stdio.h>
#include <assert.h>
#include <defs.h>  

#define SLUB_MIN_SIZE 8
#define SLUB_MAX_SIZE 2048
#define SLUB_SIZE_NUM 10

// 手动定义 bool 类型
#ifndef true
#define true 1
#define false 0
typedef int bool;
#endif

// 手动实现 page2kva 和 kva2page
#ifndef page2kva
static inline void *page2kva(struct Page *page) {
    return (void *)(KERNBASE + page2pa(page));
}
#endif

#ifndef kva2page
static inline struct Page *kva2page(void *kva) {
    return pa2page(PADDR(kva));
}
#endif

// 外部声明默认内存管理器
extern const struct pmm_manager default_pmm_manager;

// SLUB 对象元数据（存储在对象内部）
typedef struct slub_object {
    struct slub_object *next;
    struct slub_cache *cache;     // 对象所属的缓存
} slub_object_t;

// SLUB 缓存结构
typedef struct slub_cache {
    char *name;                    // 缓存名称
    size_t object_size;           // 对象大小
    size_t actual_size;           // 实际分配大小（包含元数据和对齐）
    unsigned int object_num;      // 每个slab中的对象数量
    struct Page *slab_page;       // 当前使用的slab页面
    slub_object_t *free_list;     // 空闲对象链表
    list_entry_t full_slabs;      // 满的slab链表
    list_entry_t partial_slabs;   // 部分使用的slab链表
    list_entry_t free_slabs;      // 完全空闲的slab链表
    list_entry_t cache_link;      // 缓存链表
} slub_cache_t;

// SLUB 分配器全局结构
typedef struct {
    slub_cache_t size_caches[SLUB_SIZE_NUM];  // 不同大小的缓存
    list_entry_t cache_list;                  // 所有缓存链表
    bool initialized;                         // 初始化标志
} slub_allocator_t;

static slub_allocator_t slub_allocator;

// 全局空闲页面管理（使用不同的名称避免冲突）
static list_entry_t slub_free_list;
static size_t slub_nr_free = 0;

// 计算对齐的大小
static inline size_t slub_align_size(size_t size) {
    return (size + sizeof(void*) - 1) & ~(sizeof(void*) - 1);
}

// 计算对象大小对应的缓存索引
static int slub_size_to_index(size_t size) {
    static const size_t sizes[SLUB_SIZE_NUM] = {
        8, 16, 32, 64, 128, 256, 512, 1024, 1536, 2048
    };
    
    for (int i = 0; i < SLUB_SIZE_NUM; i++) {
        if (size <= sizes[i]) {
            return i;
        }
    }
    return -1; // 大小超出范围
}

// 从对象获取所属的slab页面
static struct Page *slub_object_to_page(void *obj) {
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
    return kva2page((void *)page_addr);
}

// 初始化SLUB分配器
static void slub_init(void) {
    if (slub_allocator.initialized) {
        return;
    }
    
    list_init(&slub_free_list);
    slub_nr_free = 0;
    
    // 初始化不同大小的缓存
    size_t sizes[SLUB_SIZE_NUM] = {8, 16, 32, 64, 128, 256, 512, 1024, 1536, 2048};
    char *names[SLUB_SIZE_NUM] = {
        "slub-8", "slub-16", "slub-32", "slub-64", "slub-128",
        "slub-256", "slub-512", "slub-1024", "slub-1536", "slub-2048"
    };
    
    for (int i = 0; i < SLUB_SIZE_NUM; i++) {
        slub_cache_t *cache = &slub_allocator.size_caches[i];
        cache->name = names[i];
        cache->object_size = sizes[i];
        cache->actual_size = slub_align_size(sizes[i] + sizeof(slub_object_t));
        cache->object_num = 0;
        cache->slab_page = NULL;
        cache->free_list = NULL;
        list_init(&cache->full_slabs);
        list_init(&cache->partial_slabs);
        list_init(&cache->free_slabs);
    }
    
    slub_allocator.initialized = true;
    cprintf("[DEBUG] SLUB initialized with %d size caches\n", SLUB_SIZE_NUM);
}

// 内存映射初始化 - 修复版本
static void slub_init_memmap(struct Page *base, size_t n) {
    cprintf("[DEBUG] slub_init_memmap: base=%p, n=%d\n", base, (int)n);
    
    // 初始化页面
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        
        // 按地址顺序插入空闲列表
        if (list_empty(&slub_free_list)) {
            list_add(&slub_free_list, &(p->page_link));
        } else {
            list_entry_t *le = &slub_free_list;
            while ((le = list_next(le)) != &slub_free_list) {
                struct Page *page = le2page(le, page_link);
                if (p < page) {
                    list_add_before(le, &(p->page_link));
                    break;
                } else if (list_next(le) == &slub_free_list) {
                    list_add(le, &(p->page_link));
                }
            }
        }
    }
    
    // 设置第一个页面为连续空闲块
    base->property = n;
    SetPageProperty(base);
    slub_nr_free += n;
    
    cprintf("[DEBUG] slub_init_memmap completed: added %d pages, total free: %d\n", 
           (int)n, (int)slub_nr_free);
}

// 为缓存分配新的slab页面 - 修复版本
static struct Page *slub_alloc_slab_page(slub_cache_t *cache) {
    cprintf("[DEBUG] slub_alloc_slab_page for cache: %s\n", cache->name);
    
    // 从空闲列表中分配页面
    if (slub_nr_free == 0) {
        cprintf("[DEBUG] No free pages available!\n");
        return NULL;
    }
    
    // 获取第一个空闲页面
    list_entry_t *le = list_next(&slub_free_list);
    if (le == &slub_free_list) {
        cprintf("[DEBUG] Free list is empty!\n");
        return NULL;
    }
    
    struct Page *page = le2page(le, page_link);
    cprintf("[DEBUG] Allocating page: %p\n", page);
    
    // 从空闲列表移除
    list_del(le);
    slub_nr_free--;
    
    // 计算页面可以容纳的对象数量 - 添加详细检查
    size_t page_size = PGSIZE;
    size_t overhead = sizeof(struct Page*);
    
    // 关键修复：检查 actual_size 是否为0
    if (cache->actual_size == 0) {
        cprintf("[ERROR] cache->actual_size is 0! object_size=%d\n", (int)cache->object_size);
        return NULL;
    }
    
    cache->object_num = (page_size - overhead) / cache->actual_size;
    
    cprintf("[DEBUG] Calculation: page_size=%d, overhead=%d, actual_size=%d, object_num=%u\n",
           (int)page_size, (int)overhead, (int)cache->actual_size, cache->object_num);
    
    // 确保至少能分配一个对象
    if (cache->object_num == 0) {
        cprintf("[WARNING] object_num was 0, setting to 1\n");
        cache->object_num = 1;
    }
    
    // 安全检查：防止对象数量过多导致无限循环
    if (cache->object_num > 1000) {
        cprintf("[WARNING] Suspiciously large object_num: %u, capping at 1000\n", cache->object_num);
        cache->object_num = 1000;
    }
    
    cprintf("[DEBUG] Page can hold %u objects of size %d\n", 
           cache->object_num, (int)cache->actual_size);
    
    // 初始化空闲链表 - 修复循环问题
    void *kva = page2kva(page);
    cprintf("[DEBUG] Page KVA: %p\n", kva);
    
    slub_object_t *current = (slub_object_t *)kva;
    
    cprintf("[DEBUG] Starting object initialization for %u objects...\n", cache->object_num);
    
    // 关键修复：添加边界检查和进度输出
    char *page_end = (char *)kva + PGSIZE;
    
    for (unsigned int i = 0; i < cache->object_num - 1; i++) {
        // 进度输出
        if (i % 50 == 0) {
            cprintf("[DEBUG] Initializing object %u/%u at %p\n", i, cache->object_num, current);
        }
        
        // 计算下一个对象位置
        char *next_addr = (char *)current + cache->actual_size;
        
        // 边界检查：确保不会超出页面边界
        if (next_addr >= page_end) {
            cprintf("[ERROR] Object %u would exceed page boundary! current=%p, next=%p, page_end=%p\n",
                   i, current, next_addr, page_end);
            cache->object_num = i + 1; // 调整实际对象数量
            cprintf("[DEBUG] Adjusted object_num to %u\n", cache->object_num);
            break;
        }
        
        slub_object_t *next = (slub_object_t *)next_addr;
        current->next = next;
        current->cache = cache;
        current = next;
    }
    
    // 处理最后一个对象
    cprintf("[DEBUG] Setting last object at %p\n", current);
    current->next = NULL;
    current->cache = cache;
    
    cache->free_list = (slub_object_t *)kva;
    cache->slab_page = page;
    
    // 添加到部分使用链表
    list_add_before(&cache->partial_slabs, &(page->page_link));
    
    cprintf("[DEBUG] Slab page setup completed. free_list=%p\n", cache->free_list);
    return page;
}

// SLUB 分配函数 - 简化调试输出
void *slub_alloc(size_t size) {
    cprintf("[DEBUG] slub_alloc: %d bytes\n", (int)size);
    
    if (!slub_allocator.initialized) {
        slub_init();
    }
    
    int index = slub_size_to_index(size);
    cprintf("[DEBUG] cache index: %d\n", index);
    
    if (index < 0) {
        cprintf("[DEBUG] Size %d too large for SLUB, need page allocator\n", (int)size);
        return NULL;
    }
    
    slub_cache_t *cache = &slub_allocator.size_caches[index];
    cprintf("[DEBUG] Using cache: %s, free_list: %p\n", cache->name, cache->free_list);
    
    // 如果当前slab没有空闲对象，分配新的slab
    if (cache->free_list == NULL) {
        cprintf("[DEBUG] No free objects, allocating new slab\n");
        if (slub_alloc_slab_page(cache) == NULL) {
            cprintf("[ERROR] Failed to allocate slab page\n");
            return NULL;
        }
        cprintf("[DEBUG] New slab allocated, free_list now: %p\n", cache->free_list);
    }
    
    // 从空闲链表中分配对象
    if (cache->free_list == NULL) {
        cprintf("[ERROR] free_list is still NULL after slab allocation!\n");
        return NULL;
    }
    
    slub_object_t *object = cache->free_list;
    cache->free_list = object->next;
    cprintf("[DEBUG] Allocated object at %p, new free_list: %p\n", object, cache->free_list);
    
    // 如果当前slab已满，移动到满链表
    if (cache->free_list == NULL && cache->slab_page != NULL) {
        struct Page *page = cache->slab_page;
        list_del(&(page->page_link));
        list_add_before(&cache->full_slabs, &(page->page_link));
        cache->slab_page = NULL;
        cprintf("[DEBUG] Slab is now full\n");
    }
    
    void *result = (void *)((char *)object + sizeof(slub_object_t));
    cprintf("[DEBUG] Returning user pointer: %p\n", result);
    return result;
}

// SLUB 释放函数
void slub_free(void *obj, size_t size) {
    if (obj == NULL) return;
    
    cprintf("[DEBUG] slub_free: obj=%p, size=%d\n", obj, (int)size);
    
    int index = slub_size_to_index(size);
    if (index < 0) {
        cprintf("[DEBUG] Size %d too large for SLUB\n", (int)size);
        return;
    }
    
    slub_cache_t *cache = &slub_allocator.size_caches[index];
    
    // 获取对象元数据
    slub_object_t *object = (slub_object_t *)((char *)obj - sizeof(slub_object_t));
    struct Page *page = slub_object_to_page(obj);
    
    // 将对象放回空闲链表
    object->next = cache->free_list;
    cache->free_list = object;
    cprintf("[DEBUG] Freed object at %p\n", object);
    
    // 更新slab状态
    bool found_in_full = false;
    list_entry_t *le = &cache->full_slabs;
    while ((le = list_next(le)) != &cache->full_slabs) {
        struct Page *p = le2page(le, page_link);
        if (p == page) {
            // 从满链表移动到部分链表
            list_del(le);
            list_add_before(&cache->partial_slabs, le);
            found_in_full = true;
            cprintf("[DEBUG] Moved slab from full to partial\n");
            break;
        }
    }
    
    // 如果slab完全空闲，可以释放回系统
    if (!found_in_full && cache->free_list != NULL) {
        // 简单实现：不立即释放完全空闲的slab
        cprintf("[DEBUG] Slab has free objects now\n");
    }
    
    // 如果这是当前slab的第一个空闲对象，设置为当前slab
    if (cache->slab_page == NULL) {
        cache->slab_page = page;
    }
}

// 适配uCore的分配函数
static struct Page *slub_alloc_pages(size_t n) {
    cprintf("[DEBUG] slub_alloc_pages: %d pages\n", (int)n);
    
    if (n > 1) {
        cprintf("[DEBUG] Multi-page allocation not supported in this SLUB impl\n");
        return NULL;
    }
    
    void *obj = slub_alloc(PGSIZE - sizeof(slub_object_t));
    if (obj == NULL) {
        cprintf("[DEBUG] SLUB allocation failed\n");
        return NULL;
    }
    
    struct Page *page = kva2page(obj);
    cprintf("[DEBUG] Mapped object %p to page %p\n", obj, page);
    return page;
}

// 适配uCore的释放函数
static void slub_free_pages(struct Page *base, size_t n) {
    cprintf("[DEBUG] slub_free_pages: base=%p, n=%d\n", base, (int)n);
    
    if (n > 1) {
        cprintf("[DEBUG] Multi-page free not supported in this SLUB impl\n");
        return;
    }
    
    void *obj = page2kva(base);
    slub_free(obj, PGSIZE - sizeof(slub_object_t));
}

// 空闲页面计数
static size_t slub_nr_free_pages(void) {
    return slub_nr_free;
}

// 统计信息函数
void slub_check(void) {
    if (!slub_allocator.initialized) {
        slub_init();
    }
    
    cprintf("SLUB Allocator Status:\n");
    cprintf("=====================\n");
    cprintf("Free pages: %d\n", (int)slub_nr_free);
    
    for (int i = 0; i < SLUB_SIZE_NUM; i++) {
        slub_cache_t *cache = &slub_allocator.size_caches[i];
        
        int partial_count = 0;
        list_entry_t *le = &cache->partial_slabs;
        while ((le = list_next(le)) != &cache->partial_slabs) {
            partial_count++;
        }
        
        int full_count = 0;
        le = &cache->full_slabs;
        while ((le = list_next(le)) != &cache->full_slabs) {
            full_count++;
        }
        
        int free_count = 0;
        le = &cache->free_slabs;
        while ((le = list_next(le)) != &cache->free_slabs) {
            free_count++;
        }
        
        cprintf("Cache %s (obj_size: %4d): partial=%d, full=%d, free=%d\n",
               cache->name, (int)cache->object_size, partial_count, full_count, free_count);
    }
}

// SLUB 内存管理器接口
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};
