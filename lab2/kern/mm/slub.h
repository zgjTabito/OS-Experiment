#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#ifndef __ASSEMBLER__

#include <defs.h>

// SLUB 分配函数
void *slub_alloc(size_t size);
void slub_free(void *obj, size_t size);

// 测试函数
void slub_test_basic(void);
void slub_test_boundary(void);
void slub_test_fragmentation(void);
void slub_test_performance(void);
void slub_self_test(void);

// 状态检查
void slub_check(void);

// SLUB 内存管理器接口
extern const struct pmm_manager slub_pmm_manager;

#endif /* !__ASSEMBLER__ */

#endif /* __KERN_MM_SLUB_H__ */
