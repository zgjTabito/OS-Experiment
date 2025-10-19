#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <buddy_pmm.h>

// 以“页”为单位的 buddy 管理，最大阶设置得稍大以覆盖 128MB/4KB≈32768 页
#define BUDDY_MAX_ORDER  15  // 2^20 页远超本实验内存规模，足够安全

typedef struct {
    list_entry_t free_list[BUDDY_MAX_ORDER + 1];
    size_t nr_free;                 // 当前空闲页总数
    struct Page *base;              // 被 buddy 管理的起始页
    size_t npages;                  // 管理的页总数
} buddy_area_t;

static buddy_area_t buddy_area;

#define FL(order) (buddy_area.free_list[(order)])
#define NR_FREE   (buddy_area.nr_free)

static inline size_t order2size(unsigned order) { return ((size_t)1) << order; }

static inline unsigned size2order_ceil(size_t n) {
    unsigned o = 0; size_t s = 1;
    while (s < n && o < BUDDY_MAX_ORDER) { s <<= 1; o++; }
    return o;
}

static inline size_t page_index(struct Page *p) { return (size_t)(p - buddy_area.base); }

static inline int in_managed_range(struct Page *p) {
    if (buddy_area.base == NULL) return 0;
    size_t idx = page_index(p);
    return idx < buddy_area.npages;
}

// 在某阶空闲链表中查找指定页头（完全匹配指针）
static list_entry_t *find_in_order_list(unsigned order, struct Page *head) {
    list_entry_t *le = &FL(order);
    while ((le = list_next(le)) != &FL(order)) {
        struct Page *p = le2page(le, page_link);
        if (p == head) return le;
    }
    return NULL;
}

static void buddy_lists_init(void) {
    for (unsigned i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_init(&FL(i));
    }
}

static void buddy_init(void) {
    buddy_lists_init();
    NR_FREE = 0;
    buddy_area.base = NULL;
    buddy_area.npages = 0;
}

// 将一个块（按阶）插入并尝试向上与伙伴块合并
static void insert_and_merge(struct Page *block, unsigned order) {
    size_t size = order2size(order);
    // 自底向上尝试合并
    while (order < BUDDY_MAX_ORDER) {
        size_t idx = page_index(block);
        size_t buddy_idx = idx ^ size;           // XOR 找到同阶 buddy
        if (buddy_idx >= buddy_area.npages) break; // 越界则不能合并
        struct Page *buddy = buddy_area.base + buddy_idx;
        // buddy 必须在同阶空闲链表中作为头
        list_entry_t *le = find_in_order_list(order, buddy);
        if (le == NULL) break; // 找不到，不能合并

        // 从链表摘下 buddy
        list_del(le);
        ClearPageProperty(buddy);
        buddy->property = 0;

        // 合并后新的头应是较小索引者
        if (buddy_idx < idx) {
            ClearPageProperty(block);
            block->property = 0;
            block = buddy;
            idx = buddy_idx;
        }

        // 阶数+1，继续尝试
        order++;
        size <<= 1;
    }

    // 将合并后的大块挂回相应阶
    block->property = order2size(order);
    SetPageProperty(block);
    list_add(&FL(order), &(block->page_link));
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    // 记录整体管理区间（假设只调用一次；若多次调用，要求相互不重叠）
    if (buddy_area.base == NULL) {
        buddy_area.base = base;
        buddy_area.npages = n;
    } else {
        assert(base == buddy_area.base && n == buddy_area.npages);
    }

    // 先清理每页标志为“可用且非头”
    for (struct Page *p = base; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        ClearPageReserved(p);
    }

    buddy_lists_init();
    NR_FREE = 0;

    // 将整段内存切分为尽可能大的、按对齐的 2^order 块，挂入对应 free_list
    size_t offset = 0;                 // 相对 base 的页索引
    size_t rem = n;
    while (rem > 0) {
        // 找到满足对齐且不超过 rem 的最大块
        size_t size = 1;
        unsigned order = 0;
        // 按照 buddy 对齐规则：只有当 offset 按 2^(order+1) 对齐、且不超过 rem 时，才继续增大
        while ((order + 1) <= BUDDY_MAX_ORDER && (size << 1) <= rem && ((offset % (size << 1)) == 0)) {
            size <<= 1;
            order++;
        }

        struct Page *p = base + offset;
        p->property = size;
        SetPageProperty(p);
        list_add(&FL(order), &(p->page_link));

        NR_FREE += size;
        offset += size;
        rem    -= size;
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > NR_FREE) return NULL;

    unsigned need_order = size2order_ceil(n);
    unsigned got_order = need_order;

    // 找到不小于 need_order 的第一个非空阶
    while (got_order <= BUDDY_MAX_ORDER && list_empty(&FL(got_order))) {
        got_order++;
    }
    if (got_order > BUDDY_MAX_ORDER) return NULL;

    // 取出该阶的一个块
    list_entry_t *le = list_next(&FL(got_order));
    struct Page *blk = le2page(le, page_link);
    list_del(le);
    ClearPageProperty(blk);
    size_t cur_size = order2size(got_order);

    // 向下二分直到 need_order，把右半块挂回低一阶链表
    while (got_order > need_order) {
        got_order--;
        cur_size >>= 1;
        struct Page *right = blk + cur_size; // 右半块
        right->property = cur_size;
        SetPageProperty(right);
        list_add(&FL(got_order), &(right->page_link));
    }

    // 严格幂次：整块 2^need_order 记为已分配；不归还尾部
    size_t alloc_size = order2size(need_order);
    NR_FREE -= alloc_size;

    // 在块头记录“实际分配的幂次块大小”，方便统一按整块释放
    blk->property = alloc_size;

    // 整块标记为 Reserved（已分配），且清 Property
    for (size_t i = 0; i < alloc_size; i++) {
        struct Page *pg = blk + i;
        ClearPageProperty(pg);
        SetPageReserved(pg);
        set_page_ref(pg, 0);
    }

    return blk;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    // 优先使用分配时记录的“实际分配大小”（严格幂次）
    size_t alloc_size = base->property;
    if (alloc_size == 0) {
        // 没记录就要求外部 n 本身是 2 的幂
        assert((n & (n - 1)) == 0);              // n 是 2^k
        alloc_size = n;
    }
    // 必须在受管范围内
    assert(in_managed_range(base) && in_managed_range(base + alloc_size - 1));

    // 对齐性检查：块头必须按 alloc_size 对齐（严格 buddy 不变式）
    size_t idx = page_index(base);
    assert((idx % alloc_size) == 0);

    // 将整块 2^k 页从“已分配”改为空闲
    for (struct Page *p = base; p != base + alloc_size; p++) {
        assert(PageReserved(p));          // 必须是已分配页
        ClearPageReserved(p);
        ClearPageProperty(p);             // 已分配态不应带 Property，这里确保清理干净
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = 0;

    // 作为一个完整的 2^k 块插回并向上合并
    unsigned order = 0;
    while (((size_t)1 << order) < alloc_size) order++;
    insert_and_merge(base, order);

    // 计数：一次性返还整块
    NR_FREE += alloc_size;
}


static size_t buddy_nr_free_pages(void) { return NR_FREE; }


// 遍历所有阶，校验空闲链表基本不变式并返回空闲页总数
static size_t scan_free_and_check(void) {
    size_t sum = 0;
    for (unsigned o = 0; o <= BUDDY_MAX_ORDER; o++) {
        list_entry_t *head = &FL(o), *le = head;
        while ((le = list_next(le)) != head) {
            struct Page *p = le2page(le, page_link);
            assert(in_managed_range(p));
            assert(!PageReserved(p));
            assert(PageProperty(p));
            assert(p->property == order2size(o));
            sum += p->property;
        }
    }
    return sum;
}

static void check_pages_range_and_flags(struct Page *p, size_t n) {
    assert(in_managed_range(p));
    assert(in_managed_range(p + n - 1));
    for (size_t i = 0; i < n; i++) {
        struct Page *pg = p + i;
        assert(PageReserved(pg));
        assert(!PageProperty(pg));
        assert(page_ref(pg) == 0);
    }
}

// 简单一致性自检：分配/释放后空闲页总数应恢复，链表不变式成立
static void buddy_check(void) {
    // 空闲链表初始化/状态检查 + 空闲页计数检查
    size_t before_sum = scan_free_and_check();
    assert(before_sum == NR_FREE);

    // 页面分配
    struct Page *a = alloc_pages(1);
    struct Page *b = alloc_pages(2);
    struct Page *c = alloc_pages(3);
    struct Page *d = alloc_pages(5);
    assert(a && b && c && d);

    // 页面地址检查 + 地址范围检查 + 引用计数 + 属性检查
    check_pages_range_and_flags(a, a->property ? a->property : order2size(size2order_ceil(1)));
    check_pages_range_and_flags(b, b->property ? b->property : order2size(size2order_ceil(2)));
    check_pages_range_and_flags(c, c->property ? c->property : order2size(size2order_ceil(3)));
    check_pages_range_and_flags(d, d->property ? d->property : order2size(size2order_ceil(5)));

    // 分配后空闲页面计数状态检查 + 空闲链表状态检查
    size_t after_alloc_sum = scan_free_and_check();
    size_t consumed = (a->property ? a->property : order2size(size2order_ceil(1)))
                    + (b->property ? b->property : order2size(size2order_ceil(2)))
                    + (c->property ? c->property : order2size(size2order_ceil(3)))
                    + (d->property ? d->property : order2size(size2order_ceil(5)));
    assert(before_sum == after_alloc_sum + consumed);
    assert(NR_FREE == after_alloc_sum);

    // 释放页面检查（释放后应合并、计数恢复）
    free_pages(a, 1);
    free_pages(b, 2);
    free_pages(c, 3);
    free_pages(d, 5);

    size_t after_free_sum = scan_free_and_check();
    assert(after_free_sum == before_sum);
    assert(NR_FREE == before_sum);

    // 内存分配失败检查
    struct Page *too = alloc_pages(buddy_area.npages + 1);
    assert(too == NULL);

    // 多页分配检查 + 页面合并和释放检查
    struct Page *e = alloc_pages(8);
    assert(e);
    check_pages_range_and_flags(e, e->property ? e->property : 8);
    free_pages(e, 8);
    assert(scan_free_and_check() == before_sum);

    // 再次分配页面检查 + 释放后检查空闲链表 + 空闲页面链表状态恢复
    struct Page *f = alloc_pages(6);
    struct Page *g = alloc_pages(7);
    assert(f && g);
    free_pages(f, 6);
    free_pages(g, 7);
    assert(scan_free_and_check() == before_sum);
    assert(NR_FREE == before_sum);
}


const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
