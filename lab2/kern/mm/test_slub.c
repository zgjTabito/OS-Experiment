#include <slub.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

// 基本功能测试
void slub_test_basic(void) {
    cprintf("=== SLUB Basic Function Test ===\n");
    
    // 测试不同大小的分配
    void *ptr8 = slub_alloc(8);
    cprintf("Allocated 8 bytes at %p\n", ptr8);
    assert(ptr8 != NULL);
    
    void *ptr16 = slub_alloc(16);
    cprintf("Allocated 16 bytes at %p\n", ptr16);
    assert(ptr16 != NULL);
    
    void *ptr32 = slub_alloc(32);
    cprintf("Allocated 32 bytes at %p\n", ptr32);
    assert(ptr32 != NULL);
    
    // 测试数据写入和读取
    strcpy((char*)ptr8, "test8");
    strcpy((char*)ptr16, "test16");
    strcpy((char*)ptr32, "test32");
    
    assert(strcmp((char*)ptr8, "test8") == 0);
    assert(strcmp((char*)ptr16, "test16") == 0);
    assert(strcmp((char*)ptr32, "test32") == 0);
    
    // 释放内存
    slub_free(ptr8, 8);
    slub_free(ptr16, 16);
    slub_free(ptr32, 32);
    cprintf("Basic test passed: allocation, usage, and freeing work correctly\n\n");
}

// 边界情况测试
void slub_test_boundary(void) {
    cprintf("=== SLUB Boundary Case Test ===\n");
    
    // 测试过小的分配（应该使用最小的缓存）
    void *ptr1 = slub_alloc(1);
    cprintf("Allocated 1 byte at %p (should use slub-8)\n", ptr1);
    assert(ptr1 != NULL);
    slub_free(ptr1, 1);
    
    // 测试刚好等于缓存大小的分配
    void *ptr2048 = slub_alloc(2048);
    cprintf("Allocated 2048 bytes at %p\n", ptr2048);
    assert(ptr2048 != NULL);
    slub_free(ptr2048, 2048);
    
    // 测试超出最大缓存大小的分配（应该失败）
    void *ptr_large = slub_alloc(3000);
    cprintf("Allocated 3000 bytes at %p (should be NULL)\n", ptr_large);
    assert(ptr_large == NULL);
    
    cprintf("Boundary test passed: edge cases handled correctly\n\n");
}

// 碎片测试
void slub_test_fragmentation(void) {
    cprintf("=== SLUB Fragmentation Test ===\n");
    
    #define NUM_ALLOCS 20
    void *pointers[NUM_ALLOCS];
    
    // 分配多个对象
    for (int i = 0; i < NUM_ALLOCS; i++) {
        pointers[i] = slub_alloc(64);
        assert(pointers[i] != NULL);
        // 写入数据以便验证
        *(int*)pointers[i] = i;
    }
    
    cprintf("Allocated %d objects of 64 bytes\n", NUM_ALLOCS);
    
    // 验证数据完整性
    for (int i = 0; i < NUM_ALLOCS; i++) {
        assert(*(int*)pointers[i] == i);
    }
    
    // 交错释放
    for (int i = 0; i < NUM_ALLOCS; i += 2) {
        slub_free(pointers[i], 64);
    }
    
    cprintf("Freed every other object\n");
    
    // 重新分配
    for (int i = 0; i < NUM_ALLOCS; i += 2) {
        pointers[i] = slub_alloc(64);
        assert(pointers[i] != NULL);
        *(int*)pointers[i] = i * 2;
    }
    
    // 最终验证
    for (int i = 0; i < NUM_ALLOCS; i++) {
        if (i % 2 == 0) {
            assert(*(int*)pointers[i] == i * 2);
        } else {
            assert(*(int*)pointers[i] == i);
        }
    }
    
    // 清理
    for (int i = 0; i < NUM_ALLOCS; i++) {
        slub_free(pointers[i], 64);
    }
    
    cprintf("Fragmentation test passed: object reuse works correctly\n\n");
}

// 性能测试
void slub_test_performance(void) {
    cprintf("=== SLUB Performance Test ===\n");
    
    #define PERF_ALLOCS 50
    void *ptrs[PERF_ALLOCS];
    
    // 测试分配性能
    for (int i = 0; i < PERF_ALLOCS; i++) {
        ptrs[i] = slub_alloc(128);
        assert(ptrs[i] != NULL);
    }
    
    cprintf("Rapid allocation of %d objects completed\n", PERF_ALLOCS);
    
    // 测试释放性能
    for (int i = 0; i < PERF_ALLOCS; i++) {
        slub_free(ptrs[i], 128);
    }
    
    cprintf("Rapid freeing of %d objects completed\n", PERF_ALLOCS);
    
    // 测试混合操作
    for (int round = 0; round < 3; round++) {
        for (int i = 0; i < 10; i++) {
            ptrs[i] = slub_alloc(256);
            assert(ptrs[i] != NULL);
        }
        
        for (int i = 0; i < 10; i++) {
            slub_free(ptrs[i], 256);
        }
    }
    
    cprintf("Mixed alloc/free cycles completed\n");
    cprintf("Performance test passed: no crashes during stress testing\n\n");
}

// 综合自测试
void slub_self_test(void) {
    cprintf("\nStarting SLUB Self Tests...\n");
    cprintf("=============================\n");
    
    slub_test_basic();
    slub_test_boundary();
    slub_test_fragmentation();
    slub_test_performance();
    
    cprintf("All SLUB tests completed successfully!\n");
    cprintf("SLUB allocator is working correctly.\n\n");
}
