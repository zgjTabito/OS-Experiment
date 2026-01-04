
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	5b650513          	addi	a0,a0,1462 # ffffffffc02c2600 <buf>
ffffffffc0200052:	000c7617          	auipc	a2,0xc7
ffffffffc0200056:	a8e60613          	addi	a2,a2,-1394 # ffffffffc02c6ae0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	442050ef          	jal	ra,ffffffffc02054a4 <memset>
    cons_init(); // init the console
ffffffffc0200066:	0d5000ef          	jal	ra,ffffffffc020093a <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	86e58593          	addi	a1,a1,-1938 # ffffffffc02058d8 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	88650513          	addi	a0,a0,-1914 # ffffffffc02058f8 <etext+0x26>
ffffffffc020007a:	06a000ef          	jal	ra,ffffffffc02000e4 <cprintf>

    print_kerninfo();
ffffffffc020007e:	250000ef          	jal	ra,ffffffffc02002ce <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	4be000ef          	jal	ra,ffffffffc0200540 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	77e010ef          	jal	ra,ffffffffc0201804 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	123000ef          	jal	ra,ffffffffc02009ac <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12d000ef          	jal	ra,ffffffffc02009ba <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	24b020ef          	jal	ra,ffffffffc0202adc <vmm_init>
    sched_init();
ffffffffc0200096:	7a5040ef          	jal	ra,ffffffffc020503a <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	571040ef          	jal	ra,ffffffffc0204e0a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	053000ef          	jal	ra,ffffffffc02008f0 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	10d000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	719040ef          	jal	ra,ffffffffc0204fbe <cpu_idle>

ffffffffc02000aa <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02000aa:	1141                	addi	sp,sp,-16
ffffffffc02000ac:	e022                	sd	s0,0(sp)
ffffffffc02000ae:	e406                	sd	ra,8(sp)
ffffffffc02000b0:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000b2:	08b000ef          	jal	ra,ffffffffc020093c <cons_putc>
    (*cnt)++;
ffffffffc02000b6:	401c                	lw	a5,0(s0)
}
ffffffffc02000b8:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc02000ba:	2785                	addiw	a5,a5,1
ffffffffc02000bc:	c01c                	sw	a5,0(s0)
}
ffffffffc02000be:	6402                	ld	s0,0(sp)
ffffffffc02000c0:	0141                	addi	sp,sp,16
ffffffffc02000c2:	8082                	ret

ffffffffc02000c4 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02000c4:	1101                	addi	sp,sp,-32
ffffffffc02000c6:	862a                	mv	a2,a0
ffffffffc02000c8:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	00000517          	auipc	a0,0x0
ffffffffc02000ce:	fe050513          	addi	a0,a0,-32 # ffffffffc02000aa <cputch>
ffffffffc02000d2:	006c                	addi	a1,sp,12
{
ffffffffc02000d4:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d6:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000d8:	462050ef          	jal	ra,ffffffffc020553a <vprintfmt>
    return cnt;
}
ffffffffc02000dc:	60e2                	ld	ra,24(sp)
ffffffffc02000de:	4532                	lw	a0,12(sp)
ffffffffc02000e0:	6105                	addi	sp,sp,32
ffffffffc02000e2:	8082                	ret

ffffffffc02000e4 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02000e4:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e6:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc02000ea:	8e2a                	mv	t3,a0
ffffffffc02000ec:	f42e                	sd	a1,40(sp)
ffffffffc02000ee:	f832                	sd	a2,48(sp)
ffffffffc02000f0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000f2:	00000517          	auipc	a0,0x0
ffffffffc02000f6:	fb850513          	addi	a0,a0,-72 # ffffffffc02000aa <cputch>
ffffffffc02000fa:	004c                	addi	a1,sp,4
ffffffffc02000fc:	869a                	mv	a3,t1
ffffffffc02000fe:	8672                	mv	a2,t3
{
ffffffffc0200100:	ec06                	sd	ra,24(sp)
ffffffffc0200102:	e0ba                	sd	a4,64(sp)
ffffffffc0200104:	e4be                	sd	a5,72(sp)
ffffffffc0200106:	e8c2                	sd	a6,80(sp)
ffffffffc0200108:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020010a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020010c:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020010e:	42c050ef          	jal	ra,ffffffffc020553a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200112:	60e2                	ld	ra,24(sp)
ffffffffc0200114:	4512                	lw	a0,4(sp)
ffffffffc0200116:	6125                	addi	sp,sp,96
ffffffffc0200118:	8082                	ret

ffffffffc020011a <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc020011a:	0230006f          	j	ffffffffc020093c <cons_putc>

ffffffffc020011e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc020011e:	1101                	addi	sp,sp,-32
ffffffffc0200120:	e822                	sd	s0,16(sp)
ffffffffc0200122:	ec06                	sd	ra,24(sp)
ffffffffc0200124:	e426                	sd	s1,8(sp)
ffffffffc0200126:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc0200128:	00054503          	lbu	a0,0(a0)
ffffffffc020012c:	c51d                	beqz	a0,ffffffffc020015a <cputs+0x3c>
ffffffffc020012e:	0405                	addi	s0,s0,1
ffffffffc0200130:	4485                	li	s1,1
ffffffffc0200132:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200134:	009000ef          	jal	ra,ffffffffc020093c <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc0200138:	00044503          	lbu	a0,0(s0)
ffffffffc020013c:	008487bb          	addw	a5,s1,s0
ffffffffc0200140:	0405                	addi	s0,s0,1
ffffffffc0200142:	f96d                	bnez	a0,ffffffffc0200134 <cputs+0x16>
    (*cnt)++;
ffffffffc0200144:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200148:	4529                	li	a0,10
ffffffffc020014a:	7f2000ef          	jal	ra,ffffffffc020093c <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020014e:	60e2                	ld	ra,24(sp)
ffffffffc0200150:	8522                	mv	a0,s0
ffffffffc0200152:	6442                	ld	s0,16(sp)
ffffffffc0200154:	64a2                	ld	s1,8(sp)
ffffffffc0200156:	6105                	addi	sp,sp,32
ffffffffc0200158:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020015a:	4405                	li	s0,1
ffffffffc020015c:	b7f5                	j	ffffffffc0200148 <cputs+0x2a>

ffffffffc020015e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200162:	00f000ef          	jal	ra,ffffffffc0200970 <cons_getc>
ffffffffc0200166:	dd75                	beqz	a0,ffffffffc0200162 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020016e:	715d                	addi	sp,sp,-80
ffffffffc0200170:	e486                	sd	ra,72(sp)
ffffffffc0200172:	e0a6                	sd	s1,64(sp)
ffffffffc0200174:	fc4a                	sd	s2,56(sp)
ffffffffc0200176:	f84e                	sd	s3,48(sp)
ffffffffc0200178:	f452                	sd	s4,40(sp)
ffffffffc020017a:	f056                	sd	s5,32(sp)
ffffffffc020017c:	ec5a                	sd	s6,24(sp)
ffffffffc020017e:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200180:	c901                	beqz	a0,ffffffffc0200190 <readline+0x22>
ffffffffc0200182:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200184:	00005517          	auipc	a0,0x5
ffffffffc0200188:	77c50513          	addi	a0,a0,1916 # ffffffffc0205900 <etext+0x2e>
ffffffffc020018c:	f59ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
readline(const char *prompt) {
ffffffffc0200190:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200192:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200194:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200196:	4aa9                	li	s5,10
ffffffffc0200198:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020019a:	000c2b97          	auipc	s7,0xc2
ffffffffc020019e:	466b8b93          	addi	s7,s7,1126 # ffffffffc02c2600 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001a2:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02001a6:	fb9ff0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc02001aa:	00054a63          	bltz	a0,ffffffffc02001be <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001ae:	00a95a63          	bge	s2,a0,ffffffffc02001c2 <readline+0x54>
ffffffffc02001b2:	029a5263          	bge	s4,s1,ffffffffc02001d6 <readline+0x68>
        c = getchar();
ffffffffc02001b6:	fa9ff0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc02001ba:	fe055ae3          	bgez	a0,ffffffffc02001ae <readline+0x40>
            return NULL;
ffffffffc02001be:	4501                	li	a0,0
ffffffffc02001c0:	a091                	j	ffffffffc0200204 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02001c2:	03351463          	bne	a0,s3,ffffffffc02001ea <readline+0x7c>
ffffffffc02001c6:	e8a9                	bnez	s1,ffffffffc0200218 <readline+0xaa>
        c = getchar();
ffffffffc02001c8:	f97ff0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc02001cc:	fe0549e3          	bltz	a0,ffffffffc02001be <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001d0:	fea959e3          	bge	s2,a0,ffffffffc02001c2 <readline+0x54>
ffffffffc02001d4:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001d6:	e42a                	sd	a0,8(sp)
ffffffffc02001d8:	f43ff0ef          	jal	ra,ffffffffc020011a <cputchar>
            buf[i ++] = c;
ffffffffc02001dc:	6522                	ld	a0,8(sp)
ffffffffc02001de:	009b87b3          	add	a5,s7,s1
ffffffffc02001e2:	2485                	addiw	s1,s1,1
ffffffffc02001e4:	00a78023          	sb	a0,0(a5)
ffffffffc02001e8:	bf7d                	j	ffffffffc02001a6 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001ea:	01550463          	beq	a0,s5,ffffffffc02001f2 <readline+0x84>
ffffffffc02001ee:	fb651ce3          	bne	a0,s6,ffffffffc02001a6 <readline+0x38>
            cputchar(c);
ffffffffc02001f2:	f29ff0ef          	jal	ra,ffffffffc020011a <cputchar>
            buf[i] = '\0';
ffffffffc02001f6:	000c2517          	auipc	a0,0xc2
ffffffffc02001fa:	40a50513          	addi	a0,a0,1034 # ffffffffc02c2600 <buf>
ffffffffc02001fe:	94aa                	add	s1,s1,a0
ffffffffc0200200:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200204:	60a6                	ld	ra,72(sp)
ffffffffc0200206:	6486                	ld	s1,64(sp)
ffffffffc0200208:	7962                	ld	s2,56(sp)
ffffffffc020020a:	79c2                	ld	s3,48(sp)
ffffffffc020020c:	7a22                	ld	s4,40(sp)
ffffffffc020020e:	7a82                	ld	s5,32(sp)
ffffffffc0200210:	6b62                	ld	s6,24(sp)
ffffffffc0200212:	6bc2                	ld	s7,16(sp)
ffffffffc0200214:	6161                	addi	sp,sp,80
ffffffffc0200216:	8082                	ret
            cputchar(c);
ffffffffc0200218:	4521                	li	a0,8
ffffffffc020021a:	f01ff0ef          	jal	ra,ffffffffc020011a <cputchar>
            i --;
ffffffffc020021e:	34fd                	addiw	s1,s1,-1
ffffffffc0200220:	b759                	j	ffffffffc02001a6 <readline+0x38>

ffffffffc0200222 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200222:	000c7317          	auipc	t1,0xc7
ffffffffc0200226:	83630313          	addi	t1,t1,-1994 # ffffffffc02c6a58 <is_panic>
ffffffffc020022a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020022e:	715d                	addi	sp,sp,-80
ffffffffc0200230:	ec06                	sd	ra,24(sp)
ffffffffc0200232:	e822                	sd	s0,16(sp)
ffffffffc0200234:	f436                	sd	a3,40(sp)
ffffffffc0200236:	f83a                	sd	a4,48(sp)
ffffffffc0200238:	fc3e                	sd	a5,56(sp)
ffffffffc020023a:	e0c2                	sd	a6,64(sp)
ffffffffc020023c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020023e:	020e1a63          	bnez	t3,ffffffffc0200272 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200242:	4785                	li	a5,1
ffffffffc0200244:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200248:	8432                	mv	s0,a2
ffffffffc020024a:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020024c:	862e                	mv	a2,a1
ffffffffc020024e:	85aa                	mv	a1,a0
ffffffffc0200250:	00005517          	auipc	a0,0x5
ffffffffc0200254:	6b850513          	addi	a0,a0,1720 # ffffffffc0205908 <etext+0x36>
    va_start(ap, fmt);
ffffffffc0200258:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020025a:	e8bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020025e:	65a2                	ld	a1,8(sp)
ffffffffc0200260:	8522                	mv	a0,s0
ffffffffc0200262:	e63ff0ef          	jal	ra,ffffffffc02000c4 <vcprintf>
    cprintf("\n");
ffffffffc0200266:	00006517          	auipc	a0,0x6
ffffffffc020026a:	61250513          	addi	a0,a0,1554 # ffffffffc0206878 <commands+0xcf8>
ffffffffc020026e:	e77ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200272:	4501                	li	a0,0
ffffffffc0200274:	4581                	li	a1,0
ffffffffc0200276:	4601                	li	a2,0
ffffffffc0200278:	48a1                	li	a7,8
ffffffffc020027a:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc020027e:	736000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200282:	4501                	li	a0,0
ffffffffc0200284:	174000ef          	jal	ra,ffffffffc02003f8 <kmonitor>
    while (1) {
ffffffffc0200288:	bfed                	j	ffffffffc0200282 <__panic+0x60>

ffffffffc020028a <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc020028a:	715d                	addi	sp,sp,-80
ffffffffc020028c:	832e                	mv	t1,a1
ffffffffc020028e:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200290:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200292:	8432                	mv	s0,a2
ffffffffc0200294:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200296:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200298:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020029a:	00005517          	auipc	a0,0x5
ffffffffc020029e:	68e50513          	addi	a0,a0,1678 # ffffffffc0205928 <etext+0x56>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02002a2:	ec06                	sd	ra,24(sp)
ffffffffc02002a4:	f436                	sd	a3,40(sp)
ffffffffc02002a6:	f83a                	sd	a4,48(sp)
ffffffffc02002a8:	e0c2                	sd	a6,64(sp)
ffffffffc02002aa:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02002ac:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02002ae:	e37ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02002b2:	65a2                	ld	a1,8(sp)
ffffffffc02002b4:	8522                	mv	a0,s0
ffffffffc02002b6:	e0fff0ef          	jal	ra,ffffffffc02000c4 <vcprintf>
    cprintf("\n");
ffffffffc02002ba:	00006517          	auipc	a0,0x6
ffffffffc02002be:	5be50513          	addi	a0,a0,1470 # ffffffffc0206878 <commands+0xcf8>
ffffffffc02002c2:	e23ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    va_end(ap);
}
ffffffffc02002c6:	60e2                	ld	ra,24(sp)
ffffffffc02002c8:	6442                	ld	s0,16(sp)
ffffffffc02002ca:	6161                	addi	sp,sp,80
ffffffffc02002cc:	8082                	ret

ffffffffc02002ce <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002ce:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002d0:	00005517          	auipc	a0,0x5
ffffffffc02002d4:	67850513          	addi	a0,a0,1656 # ffffffffc0205948 <etext+0x76>
void print_kerninfo(void) {
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002da:	e0bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002de:	00000597          	auipc	a1,0x0
ffffffffc02002e2:	d6c58593          	addi	a1,a1,-660 # ffffffffc020004a <kern_init>
ffffffffc02002e6:	00005517          	auipc	a0,0x5
ffffffffc02002ea:	68250513          	addi	a0,a0,1666 # ffffffffc0205968 <etext+0x96>
ffffffffc02002ee:	df7ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002f2:	00005597          	auipc	a1,0x5
ffffffffc02002f6:	5e058593          	addi	a1,a1,1504 # ffffffffc02058d2 <etext>
ffffffffc02002fa:	00005517          	auipc	a0,0x5
ffffffffc02002fe:	68e50513          	addi	a0,a0,1678 # ffffffffc0205988 <etext+0xb6>
ffffffffc0200302:	de3ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200306:	000c2597          	auipc	a1,0xc2
ffffffffc020030a:	2fa58593          	addi	a1,a1,762 # ffffffffc02c2600 <buf>
ffffffffc020030e:	00005517          	auipc	a0,0x5
ffffffffc0200312:	69a50513          	addi	a0,a0,1690 # ffffffffc02059a8 <etext+0xd6>
ffffffffc0200316:	dcfff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020031a:	000c6597          	auipc	a1,0xc6
ffffffffc020031e:	7c658593          	addi	a1,a1,1990 # ffffffffc02c6ae0 <end>
ffffffffc0200322:	00005517          	auipc	a0,0x5
ffffffffc0200326:	6a650513          	addi	a0,a0,1702 # ffffffffc02059c8 <etext+0xf6>
ffffffffc020032a:	dbbff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020032e:	000c7597          	auipc	a1,0xc7
ffffffffc0200332:	bb158593          	addi	a1,a1,-1103 # ffffffffc02c6edf <end+0x3ff>
ffffffffc0200336:	00000797          	auipc	a5,0x0
ffffffffc020033a:	d1478793          	addi	a5,a5,-748 # ffffffffc020004a <kern_init>
ffffffffc020033e:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200342:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200346:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200348:	3ff5f593          	andi	a1,a1,1023
ffffffffc020034c:	95be                	add	a1,a1,a5
ffffffffc020034e:	85a9                	srai	a1,a1,0xa
ffffffffc0200350:	00005517          	auipc	a0,0x5
ffffffffc0200354:	69850513          	addi	a0,a0,1688 # ffffffffc02059e8 <etext+0x116>
}
ffffffffc0200358:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020035a:	b369                	j	ffffffffc02000e4 <cprintf>

ffffffffc020035c <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020035c:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020035e:	00005617          	auipc	a2,0x5
ffffffffc0200362:	6ba60613          	addi	a2,a2,1722 # ffffffffc0205a18 <etext+0x146>
ffffffffc0200366:	04d00593          	li	a1,77
ffffffffc020036a:	00005517          	auipc	a0,0x5
ffffffffc020036e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205a30 <etext+0x15e>
void print_stackframe(void) {
ffffffffc0200372:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200374:	eafff0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0200378 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200378:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020037a:	00005617          	auipc	a2,0x5
ffffffffc020037e:	6ce60613          	addi	a2,a2,1742 # ffffffffc0205a48 <etext+0x176>
ffffffffc0200382:	00005597          	auipc	a1,0x5
ffffffffc0200386:	6e658593          	addi	a1,a1,1766 # ffffffffc0205a68 <etext+0x196>
ffffffffc020038a:	00005517          	auipc	a0,0x5
ffffffffc020038e:	6e650513          	addi	a0,a0,1766 # ffffffffc0205a70 <etext+0x19e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200392:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200394:	d51ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc0200398:	00005617          	auipc	a2,0x5
ffffffffc020039c:	6e860613          	addi	a2,a2,1768 # ffffffffc0205a80 <etext+0x1ae>
ffffffffc02003a0:	00005597          	auipc	a1,0x5
ffffffffc02003a4:	70858593          	addi	a1,a1,1800 # ffffffffc0205aa8 <etext+0x1d6>
ffffffffc02003a8:	00005517          	auipc	a0,0x5
ffffffffc02003ac:	6c850513          	addi	a0,a0,1736 # ffffffffc0205a70 <etext+0x19e>
ffffffffc02003b0:	d35ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc02003b4:	00005617          	auipc	a2,0x5
ffffffffc02003b8:	70460613          	addi	a2,a2,1796 # ffffffffc0205ab8 <etext+0x1e6>
ffffffffc02003bc:	00005597          	auipc	a1,0x5
ffffffffc02003c0:	71c58593          	addi	a1,a1,1820 # ffffffffc0205ad8 <etext+0x206>
ffffffffc02003c4:	00005517          	auipc	a0,0x5
ffffffffc02003c8:	6ac50513          	addi	a0,a0,1708 # ffffffffc0205a70 <etext+0x19e>
ffffffffc02003cc:	d19ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    }
    return 0;
}
ffffffffc02003d0:	60a2                	ld	ra,8(sp)
ffffffffc02003d2:	4501                	li	a0,0
ffffffffc02003d4:	0141                	addi	sp,sp,16
ffffffffc02003d6:	8082                	ret

ffffffffc02003d8 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003d8:	1141                	addi	sp,sp,-16
ffffffffc02003da:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003dc:	ef3ff0ef          	jal	ra,ffffffffc02002ce <print_kerninfo>
    return 0;
}
ffffffffc02003e0:	60a2                	ld	ra,8(sp)
ffffffffc02003e2:	4501                	li	a0,0
ffffffffc02003e4:	0141                	addi	sp,sp,16
ffffffffc02003e6:	8082                	ret

ffffffffc02003e8 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003e8:	1141                	addi	sp,sp,-16
ffffffffc02003ea:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003ec:	f71ff0ef          	jal	ra,ffffffffc020035c <print_stackframe>
    return 0;
}
ffffffffc02003f0:	60a2                	ld	ra,8(sp)
ffffffffc02003f2:	4501                	li	a0,0
ffffffffc02003f4:	0141                	addi	sp,sp,16
ffffffffc02003f6:	8082                	ret

ffffffffc02003f8 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003f8:	7115                	addi	sp,sp,-224
ffffffffc02003fa:	ed5e                	sd	s7,152(sp)
ffffffffc02003fc:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003fe:	00005517          	auipc	a0,0x5
ffffffffc0200402:	6ea50513          	addi	a0,a0,1770 # ffffffffc0205ae8 <etext+0x216>
kmonitor(struct trapframe *tf) {
ffffffffc0200406:	ed86                	sd	ra,216(sp)
ffffffffc0200408:	e9a2                	sd	s0,208(sp)
ffffffffc020040a:	e5a6                	sd	s1,200(sp)
ffffffffc020040c:	e1ca                	sd	s2,192(sp)
ffffffffc020040e:	fd4e                	sd	s3,184(sp)
ffffffffc0200410:	f952                	sd	s4,176(sp)
ffffffffc0200412:	f556                	sd	s5,168(sp)
ffffffffc0200414:	f15a                	sd	s6,160(sp)
ffffffffc0200416:	e962                	sd	s8,144(sp)
ffffffffc0200418:	e566                	sd	s9,136(sp)
ffffffffc020041a:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020041c:	cc9ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200420:	00005517          	auipc	a0,0x5
ffffffffc0200424:	6f050513          	addi	a0,a0,1776 # ffffffffc0205b10 <etext+0x23e>
ffffffffc0200428:	cbdff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    if (tf != NULL) {
ffffffffc020042c:	000b8563          	beqz	s7,ffffffffc0200436 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200430:	855e                	mv	a0,s7
ffffffffc0200432:	770000ef          	jal	ra,ffffffffc0200ba2 <print_trapframe>
ffffffffc0200436:	00005c17          	auipc	s8,0x5
ffffffffc020043a:	74ac0c13          	addi	s8,s8,1866 # ffffffffc0205b80 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020043e:	00005917          	auipc	s2,0x5
ffffffffc0200442:	6fa90913          	addi	s2,s2,1786 # ffffffffc0205b38 <etext+0x266>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200446:	00005497          	auipc	s1,0x5
ffffffffc020044a:	6fa48493          	addi	s1,s1,1786 # ffffffffc0205b40 <etext+0x26e>
        if (argc == MAXARGS - 1) {
ffffffffc020044e:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200450:	00005b17          	auipc	s6,0x5
ffffffffc0200454:	6f8b0b13          	addi	s6,s6,1784 # ffffffffc0205b48 <etext+0x276>
        argv[argc ++] = buf;
ffffffffc0200458:	00005a17          	auipc	s4,0x5
ffffffffc020045c:	610a0a13          	addi	s4,s4,1552 # ffffffffc0205a68 <etext+0x196>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200460:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200462:	854a                	mv	a0,s2
ffffffffc0200464:	d0bff0ef          	jal	ra,ffffffffc020016e <readline>
ffffffffc0200468:	842a                	mv	s0,a0
ffffffffc020046a:	dd65                	beqz	a0,ffffffffc0200462 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020046c:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200470:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200472:	e1bd                	bnez	a1,ffffffffc02004d8 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200474:	fe0c87e3          	beqz	s9,ffffffffc0200462 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200478:	6582                	ld	a1,0(sp)
ffffffffc020047a:	00005d17          	auipc	s10,0x5
ffffffffc020047e:	706d0d13          	addi	s10,s10,1798 # ffffffffc0205b80 <commands>
        argv[argc ++] = buf;
ffffffffc0200482:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200484:	4401                	li	s0,0
ffffffffc0200486:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200488:	7c3040ef          	jal	ra,ffffffffc020544a <strcmp>
ffffffffc020048c:	c919                	beqz	a0,ffffffffc02004a2 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020048e:	2405                	addiw	s0,s0,1
ffffffffc0200490:	0b540063          	beq	s0,s5,ffffffffc0200530 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200494:	000d3503          	ld	a0,0(s10)
ffffffffc0200498:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020049a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020049c:	7af040ef          	jal	ra,ffffffffc020544a <strcmp>
ffffffffc02004a0:	f57d                	bnez	a0,ffffffffc020048e <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02004a2:	00141793          	slli	a5,s0,0x1
ffffffffc02004a6:	97a2                	add	a5,a5,s0
ffffffffc02004a8:	078e                	slli	a5,a5,0x3
ffffffffc02004aa:	97e2                	add	a5,a5,s8
ffffffffc02004ac:	6b9c                	ld	a5,16(a5)
ffffffffc02004ae:	865e                	mv	a2,s7
ffffffffc02004b0:	002c                	addi	a1,sp,8
ffffffffc02004b2:	fffc851b          	addiw	a0,s9,-1
ffffffffc02004b6:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02004b8:	fa0555e3          	bgez	a0,ffffffffc0200462 <kmonitor+0x6a>
}
ffffffffc02004bc:	60ee                	ld	ra,216(sp)
ffffffffc02004be:	644e                	ld	s0,208(sp)
ffffffffc02004c0:	64ae                	ld	s1,200(sp)
ffffffffc02004c2:	690e                	ld	s2,192(sp)
ffffffffc02004c4:	79ea                	ld	s3,184(sp)
ffffffffc02004c6:	7a4a                	ld	s4,176(sp)
ffffffffc02004c8:	7aaa                	ld	s5,168(sp)
ffffffffc02004ca:	7b0a                	ld	s6,160(sp)
ffffffffc02004cc:	6bea                	ld	s7,152(sp)
ffffffffc02004ce:	6c4a                	ld	s8,144(sp)
ffffffffc02004d0:	6caa                	ld	s9,136(sp)
ffffffffc02004d2:	6d0a                	ld	s10,128(sp)
ffffffffc02004d4:	612d                	addi	sp,sp,224
ffffffffc02004d6:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004d8:	8526                	mv	a0,s1
ffffffffc02004da:	7b5040ef          	jal	ra,ffffffffc020548e <strchr>
ffffffffc02004de:	c901                	beqz	a0,ffffffffc02004ee <kmonitor+0xf6>
ffffffffc02004e0:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02004e4:	00040023          	sb	zero,0(s0)
ffffffffc02004e8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004ea:	d5c9                	beqz	a1,ffffffffc0200474 <kmonitor+0x7c>
ffffffffc02004ec:	b7f5                	j	ffffffffc02004d8 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02004ee:	00044783          	lbu	a5,0(s0)
ffffffffc02004f2:	d3c9                	beqz	a5,ffffffffc0200474 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02004f4:	033c8963          	beq	s9,s3,ffffffffc0200526 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02004f8:	003c9793          	slli	a5,s9,0x3
ffffffffc02004fc:	0118                	addi	a4,sp,128
ffffffffc02004fe:	97ba                	add	a5,a5,a4
ffffffffc0200500:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200508:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020050a:	e591                	bnez	a1,ffffffffc0200516 <kmonitor+0x11e>
ffffffffc020050c:	b7b5                	j	ffffffffc0200478 <kmonitor+0x80>
ffffffffc020050e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200512:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200514:	d1a5                	beqz	a1,ffffffffc0200474 <kmonitor+0x7c>
ffffffffc0200516:	8526                	mv	a0,s1
ffffffffc0200518:	777040ef          	jal	ra,ffffffffc020548e <strchr>
ffffffffc020051c:	d96d                	beqz	a0,ffffffffc020050e <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020051e:	00044583          	lbu	a1,0(s0)
ffffffffc0200522:	d9a9                	beqz	a1,ffffffffc0200474 <kmonitor+0x7c>
ffffffffc0200524:	bf55                	j	ffffffffc02004d8 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200526:	45c1                	li	a1,16
ffffffffc0200528:	855a                	mv	a0,s6
ffffffffc020052a:	bbbff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc020052e:	b7e9                	j	ffffffffc02004f8 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200530:	6582                	ld	a1,0(sp)
ffffffffc0200532:	00005517          	auipc	a0,0x5
ffffffffc0200536:	63650513          	addi	a0,a0,1590 # ffffffffc0205b68 <etext+0x296>
ffffffffc020053a:	babff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    return 0;
ffffffffc020053e:	b715                	j	ffffffffc0200462 <kmonitor+0x6a>

ffffffffc0200540 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200540:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200542:	00005517          	auipc	a0,0x5
ffffffffc0200546:	68650513          	addi	a0,a0,1670 # ffffffffc0205bc8 <commands+0x48>
void dtb_init(void) {
ffffffffc020054a:	fc86                	sd	ra,120(sp)
ffffffffc020054c:	f8a2                	sd	s0,112(sp)
ffffffffc020054e:	e8d2                	sd	s4,80(sp)
ffffffffc0200550:	f4a6                	sd	s1,104(sp)
ffffffffc0200552:	f0ca                	sd	s2,96(sp)
ffffffffc0200554:	ecce                	sd	s3,88(sp)
ffffffffc0200556:	e4d6                	sd	s5,72(sp)
ffffffffc0200558:	e0da                	sd	s6,64(sp)
ffffffffc020055a:	fc5e                	sd	s7,56(sp)
ffffffffc020055c:	f862                	sd	s8,48(sp)
ffffffffc020055e:	f466                	sd	s9,40(sp)
ffffffffc0200560:	f06a                	sd	s10,32(sp)
ffffffffc0200562:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200564:	b81ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200568:	0000c597          	auipc	a1,0xc
ffffffffc020056c:	a985b583          	ld	a1,-1384(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200570:	00005517          	auipc	a0,0x5
ffffffffc0200574:	66850513          	addi	a0,a0,1640 # ffffffffc0205bd8 <commands+0x58>
ffffffffc0200578:	b6dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020057c:	0000c417          	auipc	s0,0xc
ffffffffc0200580:	a8c40413          	addi	s0,s0,-1396 # ffffffffc020c008 <boot_dtb>
ffffffffc0200584:	600c                	ld	a1,0(s0)
ffffffffc0200586:	00005517          	auipc	a0,0x5
ffffffffc020058a:	66250513          	addi	a0,a0,1634 # ffffffffc0205be8 <commands+0x68>
ffffffffc020058e:	b57ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200592:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200596:	00005517          	auipc	a0,0x5
ffffffffc020059a:	66a50513          	addi	a0,a0,1642 # ffffffffc0205c00 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc020059e:	120a0463          	beqz	s4,ffffffffc02006c6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005a2:	57f5                	li	a5,-3
ffffffffc02005a4:	07fa                	slli	a5,a5,0x1e
ffffffffc02005a6:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005aa:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b0:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005b6:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005be:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c8:	8ec9                	or	a3,a3,a0
ffffffffc02005ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005ce:	1b7d                	addi	s6,s6,-1
ffffffffc02005d0:	0167f7b3          	and	a5,a5,s6
ffffffffc02005d4:	8dd5                	or	a1,a1,a3
ffffffffc02005d6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02005d8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005dc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02005de:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe1940d>
ffffffffc02005e2:	10f59163          	bne	a1,a5,ffffffffc02006e4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005e6:	471c                	lw	a5,8(a4)
ffffffffc02005e8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02005ea:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02005f4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200604:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200608:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200610:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200614:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	01146433          	or	s0,s0,a7
ffffffffc020061a:	0086969b          	slliw	a3,a3,0x8
ffffffffc020061e:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200624:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200628:	8c49                	or	s0,s0,a0
ffffffffc020062a:	0166f6b3          	and	a3,a3,s6
ffffffffc020062e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200632:	0167f7b3          	and	a5,a5,s6
ffffffffc0200636:	8c55                	or	s0,s0,a3
ffffffffc0200638:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020063c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020063e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200642:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200646:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200648:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020064e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200650:	00005917          	auipc	s2,0x5
ffffffffc0200654:	60090913          	addi	s2,s2,1536 # ffffffffc0205c50 <commands+0xd0>
ffffffffc0200658:	49bd                	li	s3,15
        switch (token) {
ffffffffc020065a:	4d91                	li	s11,4
ffffffffc020065c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020065e:	00005497          	auipc	s1,0x5
ffffffffc0200662:	5ea48493          	addi	s1,s1,1514 # ffffffffc0205c48 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200666:	000a2703          	lw	a4,0(s4)
ffffffffc020066a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200672:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200682:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200688:	0087171b          	slliw	a4,a4,0x8
ffffffffc020068c:	8fd5                	or	a5,a5,a3
ffffffffc020068e:	00eb7733          	and	a4,s6,a4
ffffffffc0200692:	8fd9                	or	a5,a5,a4
ffffffffc0200694:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200696:	09778c63          	beq	a5,s7,ffffffffc020072e <dtb_init+0x1ee>
ffffffffc020069a:	00fbea63          	bltu	s7,a5,ffffffffc02006ae <dtb_init+0x16e>
ffffffffc020069e:	07a78663          	beq	a5,s10,ffffffffc020070a <dtb_init+0x1ca>
ffffffffc02006a2:	4709                	li	a4,2
ffffffffc02006a4:	00e79763          	bne	a5,a4,ffffffffc02006b2 <dtb_init+0x172>
ffffffffc02006a8:	4c81                	li	s9,0
ffffffffc02006aa:	8a56                	mv	s4,s5
ffffffffc02006ac:	bf6d                	j	ffffffffc0200666 <dtb_init+0x126>
ffffffffc02006ae:	ffb78ee3          	beq	a5,s11,ffffffffc02006aa <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	61650513          	addi	a0,a0,1558 # ffffffffc0205cc8 <commands+0x148>
ffffffffc02006ba:	a2bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006be:	00005517          	auipc	a0,0x5
ffffffffc02006c2:	64250513          	addi	a0,a0,1602 # ffffffffc0205d00 <commands+0x180>
}
ffffffffc02006c6:	7446                	ld	s0,112(sp)
ffffffffc02006c8:	70e6                	ld	ra,120(sp)
ffffffffc02006ca:	74a6                	ld	s1,104(sp)
ffffffffc02006cc:	7906                	ld	s2,96(sp)
ffffffffc02006ce:	69e6                	ld	s3,88(sp)
ffffffffc02006d0:	6a46                	ld	s4,80(sp)
ffffffffc02006d2:	6aa6                	ld	s5,72(sp)
ffffffffc02006d4:	6b06                	ld	s6,64(sp)
ffffffffc02006d6:	7be2                	ld	s7,56(sp)
ffffffffc02006d8:	7c42                	ld	s8,48(sp)
ffffffffc02006da:	7ca2                	ld	s9,40(sp)
ffffffffc02006dc:	7d02                	ld	s10,32(sp)
ffffffffc02006de:	6de2                	ld	s11,24(sp)
ffffffffc02006e0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02006e2:	b409                	j	ffffffffc02000e4 <cprintf>
}
ffffffffc02006e4:	7446                	ld	s0,112(sp)
ffffffffc02006e6:	70e6                	ld	ra,120(sp)
ffffffffc02006e8:	74a6                	ld	s1,104(sp)
ffffffffc02006ea:	7906                	ld	s2,96(sp)
ffffffffc02006ec:	69e6                	ld	s3,88(sp)
ffffffffc02006ee:	6a46                	ld	s4,80(sp)
ffffffffc02006f0:	6aa6                	ld	s5,72(sp)
ffffffffc02006f2:	6b06                	ld	s6,64(sp)
ffffffffc02006f4:	7be2                	ld	s7,56(sp)
ffffffffc02006f6:	7c42                	ld	s8,48(sp)
ffffffffc02006f8:	7ca2                	ld	s9,40(sp)
ffffffffc02006fa:	7d02                	ld	s10,32(sp)
ffffffffc02006fc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02006fe:	00005517          	auipc	a0,0x5
ffffffffc0200702:	52250513          	addi	a0,a0,1314 # ffffffffc0205c20 <commands+0xa0>
}
ffffffffc0200706:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200708:	baf1                	j	ffffffffc02000e4 <cprintf>
                int name_len = strlen(name);
ffffffffc020070a:	8556                	mv	a0,s5
ffffffffc020070c:	4f7040ef          	jal	ra,ffffffffc0205402 <strlen>
ffffffffc0200710:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200712:	4619                	li	a2,6
ffffffffc0200714:	85a6                	mv	a1,s1
ffffffffc0200716:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200718:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071a:	54f040ef          	jal	ra,ffffffffc0205468 <strncmp>
ffffffffc020071e:	e111                	bnez	a0,ffffffffc0200722 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200720:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200722:	0a91                	addi	s5,s5,4
ffffffffc0200724:	9ad2                	add	s5,s5,s4
ffffffffc0200726:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020072a:	8a56                	mv	s4,s5
ffffffffc020072c:	bf2d                	j	ffffffffc0200666 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020072e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200732:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200736:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020073a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020074a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200752:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200756:	00eaeab3          	or	s5,s5,a4
ffffffffc020075a:	00fb77b3          	and	a5,s6,a5
ffffffffc020075e:	00faeab3          	or	s5,s5,a5
ffffffffc0200762:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200764:	000c9c63          	bnez	s9,ffffffffc020077c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200768:	1a82                	slli	s5,s5,0x20
ffffffffc020076a:	00368793          	addi	a5,a3,3
ffffffffc020076e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200772:	9abe                	add	s5,s5,a5
ffffffffc0200774:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200778:	8a56                	mv	s4,s5
ffffffffc020077a:	b5f5                	j	ffffffffc0200666 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020077c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200780:	85ca                	mv	a1,s2
ffffffffc0200782:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200784:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200788:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200790:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200798:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007a2:	8d59                	or	a0,a0,a4
ffffffffc02007a4:	00fb77b3          	and	a5,s6,a5
ffffffffc02007a8:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007aa:	1502                	slli	a0,a0,0x20
ffffffffc02007ac:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ae:	9522                	add	a0,a0,s0
ffffffffc02007b0:	49b040ef          	jal	ra,ffffffffc020544a <strcmp>
ffffffffc02007b4:	66a2                	ld	a3,8(sp)
ffffffffc02007b6:	f94d                	bnez	a0,ffffffffc0200768 <dtb_init+0x228>
ffffffffc02007b8:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200768 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007bc:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007c0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007c4:	00005517          	auipc	a0,0x5
ffffffffc02007c8:	49450513          	addi	a0,a0,1172 # ffffffffc0205c58 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02007cc:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007d4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02007dc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e8:	0187d693          	srli	a3,a5,0x18
ffffffffc02007ec:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02007f0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02007f4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02007fc:	010f6f33          	or	t5,t5,a6
ffffffffc0200800:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200804:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080c:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200810:	0186f6b3          	and	a3,a3,s8
ffffffffc0200814:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200818:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081c:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200820:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200824:	8361                	srli	a4,a4,0x18
ffffffffc0200826:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020082a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020082e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200832:	00cb7633          	and	a2,s6,a2
ffffffffc0200836:	0088181b          	slliw	a6,a6,0x8
ffffffffc020083a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020083e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200852:	011b78b3          	and	a7,s6,a7
ffffffffc0200856:	005eeeb3          	or	t4,t4,t0
ffffffffc020085a:	00c6e733          	or	a4,a3,a2
ffffffffc020085e:	006c6c33          	or	s8,s8,t1
ffffffffc0200862:	010b76b3          	and	a3,s6,a6
ffffffffc0200866:	00bb7b33          	and	s6,s6,a1
ffffffffc020086a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020086e:	016c6b33          	or	s6,s8,s6
ffffffffc0200872:	01146433          	or	s0,s0,a7
ffffffffc0200876:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200878:	1702                	slli	a4,a4,0x20
ffffffffc020087a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020087c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020087e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200880:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200882:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200886:	0167eb33          	or	s6,a5,s6
ffffffffc020088a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020088c:	859ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200890:	85a2                	mv	a1,s0
ffffffffc0200892:	00005517          	auipc	a0,0x5
ffffffffc0200896:	3e650513          	addi	a0,a0,998 # ffffffffc0205c78 <commands+0xf8>
ffffffffc020089a:	84bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020089e:	014b5613          	srli	a2,s6,0x14
ffffffffc02008a2:	85da                	mv	a1,s6
ffffffffc02008a4:	00005517          	auipc	a0,0x5
ffffffffc02008a8:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205c90 <commands+0x110>
ffffffffc02008ac:	839ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008b0:	008b05b3          	add	a1,s6,s0
ffffffffc02008b4:	15fd                	addi	a1,a1,-1
ffffffffc02008b6:	00005517          	auipc	a0,0x5
ffffffffc02008ba:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205cb0 <commands+0x130>
ffffffffc02008be:	827ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008c2:	00005517          	auipc	a0,0x5
ffffffffc02008c6:	43e50513          	addi	a0,a0,1086 # ffffffffc0205d00 <commands+0x180>
        memory_base = mem_base;
ffffffffc02008ca:	000c6797          	auipc	a5,0xc6
ffffffffc02008ce:	1887bb23          	sd	s0,406(a5) # ffffffffc02c6a60 <memory_base>
        memory_size = mem_size;
ffffffffc02008d2:	000c6797          	auipc	a5,0xc6
ffffffffc02008d6:	1967bb23          	sd	s6,406(a5) # ffffffffc02c6a68 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02008da:	b3f5                	j	ffffffffc02006c6 <dtb_init+0x186>

ffffffffc02008dc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008dc:	000c6517          	auipc	a0,0xc6
ffffffffc02008e0:	18453503          	ld	a0,388(a0) # ffffffffc02c6a60 <memory_base>
ffffffffc02008e4:	8082                	ret

ffffffffc02008e6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008e6:	000c6517          	auipc	a0,0xc6
ffffffffc02008ea:	18253503          	ld	a0,386(a0) # ffffffffc02c6a68 <memory_size>
ffffffffc02008ee:	8082                	ret

ffffffffc02008f0 <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc02008f0:	02000793          	li	a5,32
ffffffffc02008f4:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02008f8:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02008fc:	67e1                	lui	a5,0x18
ffffffffc02008fe:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbfa0>
ffffffffc0200902:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200904:	4581                	li	a1,0
ffffffffc0200906:	4601                	li	a2,0
ffffffffc0200908:	4881                	li	a7,0
ffffffffc020090a:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020090e:	00005517          	auipc	a0,0x5
ffffffffc0200912:	40a50513          	addi	a0,a0,1034 # ffffffffc0205d18 <commands+0x198>
    ticks = 0;
ffffffffc0200916:	000c6797          	auipc	a5,0xc6
ffffffffc020091a:	1407bd23          	sd	zero,346(a5) # ffffffffc02c6a70 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020091e:	fc6ff06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc0200922 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200922:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200926:	67e1                	lui	a5,0x18
ffffffffc0200928:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbfa0>
ffffffffc020092c:	953e                	add	a0,a0,a5
ffffffffc020092e:	4581                	li	a1,0
ffffffffc0200930:	4601                	li	a2,0
ffffffffc0200932:	4881                	li	a7,0
ffffffffc0200934:	00000073          	ecall
ffffffffc0200938:	8082                	ret

ffffffffc020093a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020093a:	8082                	ret

ffffffffc020093c <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020093c:	100027f3          	csrr	a5,sstatus
ffffffffc0200940:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200942:	0ff57513          	zext.b	a0,a0
ffffffffc0200946:	e799                	bnez	a5,ffffffffc0200954 <cons_putc+0x18>
ffffffffc0200948:	4581                	li	a1,0
ffffffffc020094a:	4601                	li	a2,0
ffffffffc020094c:	4885                	li	a7,1
ffffffffc020094e:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200952:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200954:	1101                	addi	sp,sp,-32
ffffffffc0200956:	ec06                	sd	ra,24(sp)
ffffffffc0200958:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020095a:	05a000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020095e:	6522                	ld	a0,8(sp)
ffffffffc0200960:	4581                	li	a1,0
ffffffffc0200962:	4601                	li	a2,0
ffffffffc0200964:	4885                	li	a7,1
ffffffffc0200966:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020096a:	60e2                	ld	ra,24(sp)
ffffffffc020096c:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020096e:	a081                	j	ffffffffc02009ae <intr_enable>

ffffffffc0200970 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200970:	100027f3          	csrr	a5,sstatus
ffffffffc0200974:	8b89                	andi	a5,a5,2
ffffffffc0200976:	eb89                	bnez	a5,ffffffffc0200988 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200978:	4501                	li	a0,0
ffffffffc020097a:	4581                	li	a1,0
ffffffffc020097c:	4601                	li	a2,0
ffffffffc020097e:	4889                	li	a7,2
ffffffffc0200980:	00000073          	ecall
ffffffffc0200984:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200986:	8082                	ret
int cons_getc(void) {
ffffffffc0200988:	1101                	addi	sp,sp,-32
ffffffffc020098a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020098c:	028000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0200990:	4501                	li	a0,0
ffffffffc0200992:	4581                	li	a1,0
ffffffffc0200994:	4601                	li	a2,0
ffffffffc0200996:	4889                	li	a7,2
ffffffffc0200998:	00000073          	ecall
ffffffffc020099c:	2501                	sext.w	a0,a0
ffffffffc020099e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02009a0:	00e000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02009a4:	60e2                	ld	ra,24(sp)
ffffffffc02009a6:	6522                	ld	a0,8(sp)
ffffffffc02009a8:	6105                	addi	sp,sp,32
ffffffffc02009aa:	8082                	ret

ffffffffc02009ac <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009ba:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009be:	00000797          	auipc	a5,0x0
ffffffffc02009c2:	4a278793          	addi	a5,a5,1186 # ffffffffc0200e60 <__alltraps>
ffffffffc02009c6:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009ca:	000407b7          	lui	a5,0x40
ffffffffc02009ce:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d2:	8082                	ret

ffffffffc02009d4 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d4:	610c                	ld	a1,0(a0)
{
ffffffffc02009d6:	1141                	addi	sp,sp,-16
ffffffffc02009d8:	e022                	sd	s0,0(sp)
ffffffffc02009da:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009dc:	00005517          	auipc	a0,0x5
ffffffffc02009e0:	35c50513          	addi	a0,a0,860 # ffffffffc0205d38 <commands+0x1b8>
{
ffffffffc02009e4:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e6:	efeff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ea:	640c                	ld	a1,8(s0)
ffffffffc02009ec:	00005517          	auipc	a0,0x5
ffffffffc02009f0:	36450513          	addi	a0,a0,868 # ffffffffc0205d50 <commands+0x1d0>
ffffffffc02009f4:	ef0ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f8:	680c                	ld	a1,16(s0)
ffffffffc02009fa:	00005517          	auipc	a0,0x5
ffffffffc02009fe:	36e50513          	addi	a0,a0,878 # ffffffffc0205d68 <commands+0x1e8>
ffffffffc0200a02:	ee2ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a06:	6c0c                	ld	a1,24(s0)
ffffffffc0200a08:	00005517          	auipc	a0,0x5
ffffffffc0200a0c:	37850513          	addi	a0,a0,888 # ffffffffc0205d80 <commands+0x200>
ffffffffc0200a10:	ed4ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a14:	700c                	ld	a1,32(s0)
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	38250513          	addi	a0,a0,898 # ffffffffc0205d98 <commands+0x218>
ffffffffc0200a1e:	ec6ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a22:	740c                	ld	a1,40(s0)
ffffffffc0200a24:	00005517          	auipc	a0,0x5
ffffffffc0200a28:	38c50513          	addi	a0,a0,908 # ffffffffc0205db0 <commands+0x230>
ffffffffc0200a2c:	eb8ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a30:	780c                	ld	a1,48(s0)
ffffffffc0200a32:	00005517          	auipc	a0,0x5
ffffffffc0200a36:	39650513          	addi	a0,a0,918 # ffffffffc0205dc8 <commands+0x248>
ffffffffc0200a3a:	eaaff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3e:	7c0c                	ld	a1,56(s0)
ffffffffc0200a40:	00005517          	auipc	a0,0x5
ffffffffc0200a44:	3a050513          	addi	a0,a0,928 # ffffffffc0205de0 <commands+0x260>
ffffffffc0200a48:	e9cff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4c:	602c                	ld	a1,64(s0)
ffffffffc0200a4e:	00005517          	auipc	a0,0x5
ffffffffc0200a52:	3aa50513          	addi	a0,a0,938 # ffffffffc0205df8 <commands+0x278>
ffffffffc0200a56:	e8eff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5a:	642c                	ld	a1,72(s0)
ffffffffc0200a5c:	00005517          	auipc	a0,0x5
ffffffffc0200a60:	3b450513          	addi	a0,a0,948 # ffffffffc0205e10 <commands+0x290>
ffffffffc0200a64:	e80ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a68:	682c                	ld	a1,80(s0)
ffffffffc0200a6a:	00005517          	auipc	a0,0x5
ffffffffc0200a6e:	3be50513          	addi	a0,a0,958 # ffffffffc0205e28 <commands+0x2a8>
ffffffffc0200a72:	e72ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a76:	6c2c                	ld	a1,88(s0)
ffffffffc0200a78:	00005517          	auipc	a0,0x5
ffffffffc0200a7c:	3c850513          	addi	a0,a0,968 # ffffffffc0205e40 <commands+0x2c0>
ffffffffc0200a80:	e64ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a84:	702c                	ld	a1,96(s0)
ffffffffc0200a86:	00005517          	auipc	a0,0x5
ffffffffc0200a8a:	3d250513          	addi	a0,a0,978 # ffffffffc0205e58 <commands+0x2d8>
ffffffffc0200a8e:	e56ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a92:	742c                	ld	a1,104(s0)
ffffffffc0200a94:	00005517          	auipc	a0,0x5
ffffffffc0200a98:	3dc50513          	addi	a0,a0,988 # ffffffffc0205e70 <commands+0x2f0>
ffffffffc0200a9c:	e48ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa0:	782c                	ld	a1,112(s0)
ffffffffc0200aa2:	00005517          	auipc	a0,0x5
ffffffffc0200aa6:	3e650513          	addi	a0,a0,998 # ffffffffc0205e88 <commands+0x308>
ffffffffc0200aaa:	e3aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aae:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab0:	00005517          	auipc	a0,0x5
ffffffffc0200ab4:	3f050513          	addi	a0,a0,1008 # ffffffffc0205ea0 <commands+0x320>
ffffffffc0200ab8:	e2cff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abc:	604c                	ld	a1,128(s0)
ffffffffc0200abe:	00005517          	auipc	a0,0x5
ffffffffc0200ac2:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205eb8 <commands+0x338>
ffffffffc0200ac6:	e1eff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200aca:	644c                	ld	a1,136(s0)
ffffffffc0200acc:	00005517          	auipc	a0,0x5
ffffffffc0200ad0:	40450513          	addi	a0,a0,1028 # ffffffffc0205ed0 <commands+0x350>
ffffffffc0200ad4:	e10ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad8:	684c                	ld	a1,144(s0)
ffffffffc0200ada:	00005517          	auipc	a0,0x5
ffffffffc0200ade:	40e50513          	addi	a0,a0,1038 # ffffffffc0205ee8 <commands+0x368>
ffffffffc0200ae2:	e02ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae6:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae8:	00005517          	auipc	a0,0x5
ffffffffc0200aec:	41850513          	addi	a0,a0,1048 # ffffffffc0205f00 <commands+0x380>
ffffffffc0200af0:	df4ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af4:	704c                	ld	a1,160(s0)
ffffffffc0200af6:	00005517          	auipc	a0,0x5
ffffffffc0200afa:	42250513          	addi	a0,a0,1058 # ffffffffc0205f18 <commands+0x398>
ffffffffc0200afe:	de6ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b02:	744c                	ld	a1,168(s0)
ffffffffc0200b04:	00005517          	auipc	a0,0x5
ffffffffc0200b08:	42c50513          	addi	a0,a0,1068 # ffffffffc0205f30 <commands+0x3b0>
ffffffffc0200b0c:	dd8ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b10:	784c                	ld	a1,176(s0)
ffffffffc0200b12:	00005517          	auipc	a0,0x5
ffffffffc0200b16:	43650513          	addi	a0,a0,1078 # ffffffffc0205f48 <commands+0x3c8>
ffffffffc0200b1a:	dcaff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1e:	7c4c                	ld	a1,184(s0)
ffffffffc0200b20:	00005517          	auipc	a0,0x5
ffffffffc0200b24:	44050513          	addi	a0,a0,1088 # ffffffffc0205f60 <commands+0x3e0>
ffffffffc0200b28:	dbcff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2c:	606c                	ld	a1,192(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	44a50513          	addi	a0,a0,1098 # ffffffffc0205f78 <commands+0x3f8>
ffffffffc0200b36:	daeff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3a:	646c                	ld	a1,200(s0)
ffffffffc0200b3c:	00005517          	auipc	a0,0x5
ffffffffc0200b40:	45450513          	addi	a0,a0,1108 # ffffffffc0205f90 <commands+0x410>
ffffffffc0200b44:	da0ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b48:	686c                	ld	a1,208(s0)
ffffffffc0200b4a:	00005517          	auipc	a0,0x5
ffffffffc0200b4e:	45e50513          	addi	a0,a0,1118 # ffffffffc0205fa8 <commands+0x428>
ffffffffc0200b52:	d92ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b56:	6c6c                	ld	a1,216(s0)
ffffffffc0200b58:	00005517          	auipc	a0,0x5
ffffffffc0200b5c:	46850513          	addi	a0,a0,1128 # ffffffffc0205fc0 <commands+0x440>
ffffffffc0200b60:	d84ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b64:	706c                	ld	a1,224(s0)
ffffffffc0200b66:	00005517          	auipc	a0,0x5
ffffffffc0200b6a:	47250513          	addi	a0,a0,1138 # ffffffffc0205fd8 <commands+0x458>
ffffffffc0200b6e:	d76ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b72:	746c                	ld	a1,232(s0)
ffffffffc0200b74:	00005517          	auipc	a0,0x5
ffffffffc0200b78:	47c50513          	addi	a0,a0,1148 # ffffffffc0205ff0 <commands+0x470>
ffffffffc0200b7c:	d68ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b80:	786c                	ld	a1,240(s0)
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	48650513          	addi	a0,a0,1158 # ffffffffc0206008 <commands+0x488>
ffffffffc0200b8a:	d5aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b90:	6402                	ld	s0,0(sp)
ffffffffc0200b92:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	48c50513          	addi	a0,a0,1164 # ffffffffc0206020 <commands+0x4a0>
}
ffffffffc0200b9c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9e:	d46ff06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc0200ba2 <print_trapframe>:
{
ffffffffc0200ba2:	1141                	addi	sp,sp,-16
ffffffffc0200ba4:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	85aa                	mv	a1,a0
{
ffffffffc0200ba8:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200baa:	00005517          	auipc	a0,0x5
ffffffffc0200bae:	48e50513          	addi	a0,a0,1166 # ffffffffc0206038 <commands+0x4b8>
{
ffffffffc0200bb2:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb4:	d30ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb8:	8522                	mv	a0,s0
ffffffffc0200bba:	e1bff0ef          	jal	ra,ffffffffc02009d4 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bbe:	10043583          	ld	a1,256(s0)
ffffffffc0200bc2:	00005517          	auipc	a0,0x5
ffffffffc0200bc6:	48e50513          	addi	a0,a0,1166 # ffffffffc0206050 <commands+0x4d0>
ffffffffc0200bca:	d1aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bce:	10843583          	ld	a1,264(s0)
ffffffffc0200bd2:	00005517          	auipc	a0,0x5
ffffffffc0200bd6:	49650513          	addi	a0,a0,1174 # ffffffffc0206068 <commands+0x4e8>
ffffffffc0200bda:	d0aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bde:	11043583          	ld	a1,272(s0)
ffffffffc0200be2:	00005517          	auipc	a0,0x5
ffffffffc0200be6:	49e50513          	addi	a0,a0,1182 # ffffffffc0206080 <commands+0x500>
ffffffffc0200bea:	cfaff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bee:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf2:	6402                	ld	s0,0(sp)
ffffffffc0200bf4:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf6:	00005517          	auipc	a0,0x5
ffffffffc0200bfa:	49a50513          	addi	a0,a0,1178 # ffffffffc0206090 <commands+0x510>
}
ffffffffc0200bfe:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c00:	ce4ff06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc0200c04 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c04:	11853783          	ld	a5,280(a0)
ffffffffc0200c08:	472d                	li	a4,11
ffffffffc0200c0a:	0786                	slli	a5,a5,0x1
ffffffffc0200c0c:	8385                	srli	a5,a5,0x1
ffffffffc0200c0e:	08f76663          	bltu	a4,a5,ffffffffc0200c9a <interrupt_handler+0x96>
ffffffffc0200c12:	00005717          	auipc	a4,0x5
ffffffffc0200c16:	55670713          	addi	a4,a4,1366 # ffffffffc0206168 <commands+0x5e8>
ffffffffc0200c1a:	078a                	slli	a5,a5,0x2
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	439c                	lw	a5,0(a5)
ffffffffc0200c20:	97ba                	add	a5,a5,a4
ffffffffc0200c22:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c24:	00005517          	auipc	a0,0x5
ffffffffc0200c28:	4e450513          	addi	a0,a0,1252 # ffffffffc0206108 <commands+0x588>
ffffffffc0200c2c:	cb8ff06f          	j	ffffffffc02000e4 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c30:	00005517          	auipc	a0,0x5
ffffffffc0200c34:	4b850513          	addi	a0,a0,1208 # ffffffffc02060e8 <commands+0x568>
ffffffffc0200c38:	cacff06f          	j	ffffffffc02000e4 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3c:	00005517          	auipc	a0,0x5
ffffffffc0200c40:	46c50513          	addi	a0,a0,1132 # ffffffffc02060a8 <commands+0x528>
ffffffffc0200c44:	ca0ff06f          	j	ffffffffc02000e4 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c48:	00005517          	auipc	a0,0x5
ffffffffc0200c4c:	48050513          	addi	a0,a0,1152 # ffffffffc02060c8 <commands+0x548>
ffffffffc0200c50:	c94ff06f          	j	ffffffffc02000e4 <cprintf>
{
ffffffffc0200c54:	1141                	addi	sp,sp,-16
ffffffffc0200c56:	e406                	sd	ra,8(sp)
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        clock_set_next_event();
ffffffffc0200c58:	ccbff0ef          	jal	ra,ffffffffc0200922 <clock_set_next_event>
        ticks++;
ffffffffc0200c5c:	000c6797          	auipc	a5,0xc6
ffffffffc0200c60:	e1478793          	addi	a5,a5,-492 # ffffffffc02c6a70 <ticks>
ffffffffc0200c64:	6398                	ld	a4,0(a5)
ffffffffc0200c66:	0705                	addi	a4,a4,1
ffffffffc0200c68:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c6a:	639c                	ld	a5,0(a5)
ffffffffc0200c6c:	06400713          	li	a4,100
ffffffffc0200c70:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c74:	c79d                	beqz	a5,ffffffffc0200ca2 <interrupt_handler+0x9e>
            print_ticks();
        }
        if (current != NULL && current->rq != NULL) { sched_class_proc_tick(current); }
ffffffffc0200c76:	000c6517          	auipc	a0,0xc6
ffffffffc0200c7a:	e3a53503          	ld	a0,-454(a0) # ffffffffc02c6ab0 <current>
ffffffffc0200c7e:	cd19                	beqz	a0,ffffffffc0200c9c <interrupt_handler+0x98>
ffffffffc0200c80:	10853783          	ld	a5,264(a0)
ffffffffc0200c84:	cf81                	beqz	a5,ffffffffc0200c9c <interrupt_handler+0x98>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
        if (current != NULL && current->rq != NULL) { sched_class_proc_tick(current); }
ffffffffc0200c8a:	3880406f          	j	ffffffffc0205012 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8e:	00005517          	auipc	a0,0x5
ffffffffc0200c92:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206148 <commands+0x5c8>
ffffffffc0200c96:	c4eff06f          	j	ffffffffc02000e4 <cprintf>
        print_trapframe(tf);
ffffffffc0200c9a:	b721                	j	ffffffffc0200ba2 <print_trapframe>
}
ffffffffc0200c9c:	60a2                	ld	ra,8(sp)
ffffffffc0200c9e:	0141                	addi	sp,sp,16
ffffffffc0200ca0:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ca2:	06400593          	li	a1,100
ffffffffc0200ca6:	00005517          	auipc	a0,0x5
ffffffffc0200caa:	48250513          	addi	a0,a0,1154 # ffffffffc0206128 <commands+0x5a8>
ffffffffc0200cae:	c36ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("End of Test.\n");
ffffffffc0200cb2:	00005517          	auipc	a0,0x5
ffffffffc0200cb6:	48650513          	addi	a0,a0,1158 # ffffffffc0206138 <commands+0x5b8>
ffffffffc0200cba:	c2aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
}
ffffffffc0200cbe:	bf65                	j	ffffffffc0200c76 <interrupt_handler+0x72>

ffffffffc0200cc0 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cc0:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cc4:	1141                	addi	sp,sp,-16
ffffffffc0200cc6:	e022                	sd	s0,0(sp)
ffffffffc0200cc8:	e406                	sd	ra,8(sp)
ffffffffc0200cca:	473d                	li	a4,15
ffffffffc0200ccc:	842a                	mv	s0,a0
ffffffffc0200cce:	0ef76363          	bltu	a4,a5,ffffffffc0200db4 <exception_handler+0xf4>
ffffffffc0200cd2:	00005717          	auipc	a4,0x5
ffffffffc0200cd6:	67e70713          	addi	a4,a4,1662 # ffffffffc0206350 <commands+0x7d0>
ffffffffc0200cda:	078a                	slli	a5,a5,0x2
ffffffffc0200cdc:	97ba                	add	a5,a5,a4
ffffffffc0200cde:	439c                	lw	a5,0(a5)
ffffffffc0200ce0:	97ba                	add	a5,a5,a4
ffffffffc0200ce2:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ce4:	00005517          	auipc	a0,0x5
ffffffffc0200ce8:	59c50513          	addi	a0,a0,1436 # ffffffffc0206280 <commands+0x700>
ffffffffc0200cec:	bf8ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        tf->epc += 4;
ffffffffc0200cf0:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cf4:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cf6:	0791                	addi	a5,a5,4
ffffffffc0200cf8:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cfc:	6402                	ld	s0,0(sp)
ffffffffc0200cfe:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d00:	6800406f          	j	ffffffffc0205380 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	59c50513          	addi	a0,a0,1436 # ffffffffc02062a0 <commands+0x720>
}
ffffffffc0200d0c:	6402                	ld	s0,0(sp)
ffffffffc0200d0e:	60a2                	ld	ra,8(sp)
ffffffffc0200d10:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d12:	bd2ff06f          	j	ffffffffc02000e4 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d16:	00005517          	auipc	a0,0x5
ffffffffc0200d1a:	5aa50513          	addi	a0,a0,1450 # ffffffffc02062c0 <commands+0x740>
ffffffffc0200d1e:	b7fd                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d20:	00005517          	auipc	a0,0x5
ffffffffc0200d24:	5c050513          	addi	a0,a0,1472 # ffffffffc02062e0 <commands+0x760>
ffffffffc0200d28:	bbcff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        print_trapframe(tf);
ffffffffc0200d2c:	8522                	mv	a0,s0
ffffffffc0200d2e:	e75ff0ef          	jal	ra,ffffffffc0200ba2 <print_trapframe>
        if (current != NULL) {
ffffffffc0200d32:	000c6617          	auipc	a2,0xc6
ffffffffc0200d36:	d7e63603          	ld	a2,-642(a2) # ffffffffc02c6ab0 <current>
ffffffffc0200d3a:	ca11                	beqz	a2,ffffffffc0200d4e <exception_handler+0x8e>
            cprintf("Current process: pid=%d, name=%s\n", current->pid, current->name);
ffffffffc0200d3c:	424c                	lw	a1,4(a2)
ffffffffc0200d3e:	00005517          	auipc	a0,0x5
ffffffffc0200d42:	5ba50513          	addi	a0,a0,1466 # ffffffffc02062f8 <commands+0x778>
ffffffffc0200d46:	0b460613          	addi	a2,a2,180
ffffffffc0200d4a:	b9aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
}
ffffffffc0200d4e:	6402                	ld	s0,0(sp)
ffffffffc0200d50:	60a2                	ld	ra,8(sp)
        do_exit(-E_KILLED);
ffffffffc0200d52:	555d                	li	a0,-9
}
ffffffffc0200d54:	0141                	addi	sp,sp,16
        do_exit(-E_KILLED);
ffffffffc0200d56:	5f40306f          	j	ffffffffc020434a <do_exit>
        cprintf("Load page fault\n");
ffffffffc0200d5a:	00005517          	auipc	a0,0x5
ffffffffc0200d5e:	5c650513          	addi	a0,a0,1478 # ffffffffc0206320 <commands+0x7a0>
ffffffffc0200d62:	b7d9                	j	ffffffffc0200d28 <exception_handler+0x68>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d64:	00005517          	auipc	a0,0x5
ffffffffc0200d68:	5d450513          	addi	a0,a0,1492 # ffffffffc0206338 <commands+0x7b8>
ffffffffc0200d6c:	bf75                	j	ffffffffc0200d28 <exception_handler+0x68>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d6e:	00005517          	auipc	a0,0x5
ffffffffc0200d72:	42a50513          	addi	a0,a0,1066 # ffffffffc0206198 <commands+0x618>
ffffffffc0200d76:	bf59                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d78:	00005517          	auipc	a0,0x5
ffffffffc0200d7c:	44050513          	addi	a0,a0,1088 # ffffffffc02061b8 <commands+0x638>
ffffffffc0200d80:	b771                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d82:	00005517          	auipc	a0,0x5
ffffffffc0200d86:	45650513          	addi	a0,a0,1110 # ffffffffc02061d8 <commands+0x658>
ffffffffc0200d8a:	b749                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d8c:	00005517          	auipc	a0,0x5
ffffffffc0200d90:	46450513          	addi	a0,a0,1124 # ffffffffc02061f0 <commands+0x670>
ffffffffc0200d94:	bfa5                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d96:	00005517          	auipc	a0,0x5
ffffffffc0200d9a:	46a50513          	addi	a0,a0,1130 # ffffffffc0206200 <commands+0x680>
ffffffffc0200d9e:	b7bd                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200da0:	00005517          	auipc	a0,0x5
ffffffffc0200da4:	48050513          	addi	a0,a0,1152 # ffffffffc0206220 <commands+0x6a0>
ffffffffc0200da8:	b795                	j	ffffffffc0200d0c <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200daa:	00005517          	auipc	a0,0x5
ffffffffc0200dae:	4be50513          	addi	a0,a0,1214 # ffffffffc0206268 <commands+0x6e8>
ffffffffc0200db2:	bfa9                	j	ffffffffc0200d0c <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200db4:	8522                	mv	a0,s0
}
ffffffffc0200db6:	6402                	ld	s0,0(sp)
ffffffffc0200db8:	60a2                	ld	ra,8(sp)
ffffffffc0200dba:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200dbc:	b3dd                	j	ffffffffc0200ba2 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200dbe:	00005617          	auipc	a2,0x5
ffffffffc0200dc2:	47a60613          	addi	a2,a2,1146 # ffffffffc0206238 <commands+0x6b8>
ffffffffc0200dc6:	0b400593          	li	a1,180
ffffffffc0200dca:	00005517          	auipc	a0,0x5
ffffffffc0200dce:	48650513          	addi	a0,a0,1158 # ffffffffc0206250 <commands+0x6d0>
ffffffffc0200dd2:	c50ff0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0200dd6 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200dd6:	1101                	addi	sp,sp,-32
ffffffffc0200dd8:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dda:	000c6417          	auipc	s0,0xc6
ffffffffc0200dde:	cd640413          	addi	s0,s0,-810 # ffffffffc02c6ab0 <current>
ffffffffc0200de2:	6018                	ld	a4,0(s0)
{
ffffffffc0200de4:	ec06                	sd	ra,24(sp)
ffffffffc0200de6:	e426                	sd	s1,8(sp)
ffffffffc0200de8:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dea:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200dee:	cf1d                	beqz	a4,ffffffffc0200e2c <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200df0:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200df4:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200df8:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dfa:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dfe:	0206c463          	bltz	a3,ffffffffc0200e26 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e02:	ebfff0ef          	jal	ra,ffffffffc0200cc0 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e06:	601c                	ld	a5,0(s0)
ffffffffc0200e08:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e0c:	e499                	bnez	s1,ffffffffc0200e1a <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e0e:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e12:	8b05                	andi	a4,a4,1
ffffffffc0200e14:	e329                	bnez	a4,ffffffffc0200e56 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e16:	6f9c                	ld	a5,24(a5)
ffffffffc0200e18:	eb85                	bnez	a5,ffffffffc0200e48 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e1a:	60e2                	ld	ra,24(sp)
ffffffffc0200e1c:	6442                	ld	s0,16(sp)
ffffffffc0200e1e:	64a2                	ld	s1,8(sp)
ffffffffc0200e20:	6902                	ld	s2,0(sp)
ffffffffc0200e22:	6105                	addi	sp,sp,32
ffffffffc0200e24:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e26:	ddfff0ef          	jal	ra,ffffffffc0200c04 <interrupt_handler>
ffffffffc0200e2a:	bff1                	j	ffffffffc0200e06 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e2c:	0006c863          	bltz	a3,ffffffffc0200e3c <trap+0x66>
}
ffffffffc0200e30:	6442                	ld	s0,16(sp)
ffffffffc0200e32:	60e2                	ld	ra,24(sp)
ffffffffc0200e34:	64a2                	ld	s1,8(sp)
ffffffffc0200e36:	6902                	ld	s2,0(sp)
ffffffffc0200e38:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e3a:	b559                	j	ffffffffc0200cc0 <exception_handler>
}
ffffffffc0200e3c:	6442                	ld	s0,16(sp)
ffffffffc0200e3e:	60e2                	ld	ra,24(sp)
ffffffffc0200e40:	64a2                	ld	s1,8(sp)
ffffffffc0200e42:	6902                	ld	s2,0(sp)
ffffffffc0200e44:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e46:	bb7d                	j	ffffffffc0200c04 <interrupt_handler>
}
ffffffffc0200e48:	6442                	ld	s0,16(sp)
ffffffffc0200e4a:	60e2                	ld	ra,24(sp)
ffffffffc0200e4c:	64a2                	ld	s1,8(sp)
ffffffffc0200e4e:	6902                	ld	s2,0(sp)
ffffffffc0200e50:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e52:	2ec0406f          	j	ffffffffc020513e <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e56:	555d                	li	a0,-9
ffffffffc0200e58:	4f2030ef          	jal	ra,ffffffffc020434a <do_exit>
            if (current->need_resched)
ffffffffc0200e5c:	601c                	ld	a5,0(s0)
ffffffffc0200e5e:	bf65                	j	ffffffffc0200e16 <trap+0x40>

ffffffffc0200e60 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e60:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e64:	00011463          	bnez	sp,ffffffffc0200e6c <__alltraps+0xc>
ffffffffc0200e68:	14002173          	csrr	sp,sscratch
ffffffffc0200e6c:	712d                	addi	sp,sp,-288
ffffffffc0200e6e:	e002                	sd	zero,0(sp)
ffffffffc0200e70:	e406                	sd	ra,8(sp)
ffffffffc0200e72:	ec0e                	sd	gp,24(sp)
ffffffffc0200e74:	f012                	sd	tp,32(sp)
ffffffffc0200e76:	f416                	sd	t0,40(sp)
ffffffffc0200e78:	f81a                	sd	t1,48(sp)
ffffffffc0200e7a:	fc1e                	sd	t2,56(sp)
ffffffffc0200e7c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e7e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e80:	e8aa                	sd	a0,80(sp)
ffffffffc0200e82:	ecae                	sd	a1,88(sp)
ffffffffc0200e84:	f0b2                	sd	a2,96(sp)
ffffffffc0200e86:	f4b6                	sd	a3,104(sp)
ffffffffc0200e88:	f8ba                	sd	a4,112(sp)
ffffffffc0200e8a:	fcbe                	sd	a5,120(sp)
ffffffffc0200e8c:	e142                	sd	a6,128(sp)
ffffffffc0200e8e:	e546                	sd	a7,136(sp)
ffffffffc0200e90:	e94a                	sd	s2,144(sp)
ffffffffc0200e92:	ed4e                	sd	s3,152(sp)
ffffffffc0200e94:	f152                	sd	s4,160(sp)
ffffffffc0200e96:	f556                	sd	s5,168(sp)
ffffffffc0200e98:	f95a                	sd	s6,176(sp)
ffffffffc0200e9a:	fd5e                	sd	s7,184(sp)
ffffffffc0200e9c:	e1e2                	sd	s8,192(sp)
ffffffffc0200e9e:	e5e6                	sd	s9,200(sp)
ffffffffc0200ea0:	e9ea                	sd	s10,208(sp)
ffffffffc0200ea2:	edee                	sd	s11,216(sp)
ffffffffc0200ea4:	f1f2                	sd	t3,224(sp)
ffffffffc0200ea6:	f5f6                	sd	t4,232(sp)
ffffffffc0200ea8:	f9fa                	sd	t5,240(sp)
ffffffffc0200eaa:	fdfe                	sd	t6,248(sp)
ffffffffc0200eac:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200eb0:	100024f3          	csrr	s1,sstatus
ffffffffc0200eb4:	14102973          	csrr	s2,sepc
ffffffffc0200eb8:	143029f3          	csrr	s3,stval
ffffffffc0200ebc:	14202a73          	csrr	s4,scause
ffffffffc0200ec0:	e822                	sd	s0,16(sp)
ffffffffc0200ec2:	e226                	sd	s1,256(sp)
ffffffffc0200ec4:	e64a                	sd	s2,264(sp)
ffffffffc0200ec6:	ea4e                	sd	s3,272(sp)
ffffffffc0200ec8:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200eca:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ecc:	f0bff0ef          	jal	ra,ffffffffc0200dd6 <trap>

ffffffffc0200ed0 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ed0:	6492                	ld	s1,256(sp)
ffffffffc0200ed2:	6932                	ld	s2,264(sp)
ffffffffc0200ed4:	1004f413          	andi	s0,s1,256
ffffffffc0200ed8:	e401                	bnez	s0,ffffffffc0200ee0 <__trapret+0x10>
ffffffffc0200eda:	1200                	addi	s0,sp,288
ffffffffc0200edc:	14041073          	csrw	sscratch,s0
ffffffffc0200ee0:	10049073          	csrw	sstatus,s1
ffffffffc0200ee4:	14191073          	csrw	sepc,s2
ffffffffc0200ee8:	60a2                	ld	ra,8(sp)
ffffffffc0200eea:	61e2                	ld	gp,24(sp)
ffffffffc0200eec:	7202                	ld	tp,32(sp)
ffffffffc0200eee:	72a2                	ld	t0,40(sp)
ffffffffc0200ef0:	7342                	ld	t1,48(sp)
ffffffffc0200ef2:	73e2                	ld	t2,56(sp)
ffffffffc0200ef4:	6406                	ld	s0,64(sp)
ffffffffc0200ef6:	64a6                	ld	s1,72(sp)
ffffffffc0200ef8:	6546                	ld	a0,80(sp)
ffffffffc0200efa:	65e6                	ld	a1,88(sp)
ffffffffc0200efc:	7606                	ld	a2,96(sp)
ffffffffc0200efe:	76a6                	ld	a3,104(sp)
ffffffffc0200f00:	7746                	ld	a4,112(sp)
ffffffffc0200f02:	77e6                	ld	a5,120(sp)
ffffffffc0200f04:	680a                	ld	a6,128(sp)
ffffffffc0200f06:	68aa                	ld	a7,136(sp)
ffffffffc0200f08:	694a                	ld	s2,144(sp)
ffffffffc0200f0a:	69ea                	ld	s3,152(sp)
ffffffffc0200f0c:	7a0a                	ld	s4,160(sp)
ffffffffc0200f0e:	7aaa                	ld	s5,168(sp)
ffffffffc0200f10:	7b4a                	ld	s6,176(sp)
ffffffffc0200f12:	7bea                	ld	s7,184(sp)
ffffffffc0200f14:	6c0e                	ld	s8,192(sp)
ffffffffc0200f16:	6cae                	ld	s9,200(sp)
ffffffffc0200f18:	6d4e                	ld	s10,208(sp)
ffffffffc0200f1a:	6dee                	ld	s11,216(sp)
ffffffffc0200f1c:	7e0e                	ld	t3,224(sp)
ffffffffc0200f1e:	7eae                	ld	t4,232(sp)
ffffffffc0200f20:	7f4e                	ld	t5,240(sp)
ffffffffc0200f22:	7fee                	ld	t6,248(sp)
ffffffffc0200f24:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f26:	10200073          	sret

ffffffffc0200f2a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f2a:	812a                	mv	sp,a0
ffffffffc0200f2c:	b755                	j	ffffffffc0200ed0 <__trapret>

ffffffffc0200f2e <pa2page.part.0>:
{
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa)
ffffffffc0200f2e:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200f30:	00005617          	auipc	a2,0x5
ffffffffc0200f34:	46060613          	addi	a2,a2,1120 # ffffffffc0206390 <commands+0x810>
ffffffffc0200f38:	06900593          	li	a1,105
ffffffffc0200f3c:	00005517          	auipc	a0,0x5
ffffffffc0200f40:	47450513          	addi	a0,a0,1140 # ffffffffc02063b0 <commands+0x830>
pa2page(uintptr_t pa)
ffffffffc0200f44:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200f46:	adcff0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0200f4a <pte2page.part.0>:
{
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte)
ffffffffc0200f4a:	1141                	addi	sp,sp,-16
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
ffffffffc0200f4c:	00005617          	auipc	a2,0x5
ffffffffc0200f50:	47460613          	addi	a2,a2,1140 # ffffffffc02063c0 <commands+0x840>
ffffffffc0200f54:	07f00593          	li	a1,127
ffffffffc0200f58:	00005517          	auipc	a0,0x5
ffffffffc0200f5c:	45850513          	addi	a0,a0,1112 # ffffffffc02063b0 <commands+0x830>
pte2page(pte_t pte)
ffffffffc0200f60:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200f62:	ac0ff0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0200f66 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200f66:	100027f3          	csrr	a5,sstatus
ffffffffc0200f6a:	8b89                	andi	a5,a5,2
ffffffffc0200f6c:	e799                	bnez	a5,ffffffffc0200f7a <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f6e:	000c6797          	auipc	a5,0xc6
ffffffffc0200f72:	b2a7b783          	ld	a5,-1238(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0200f76:	6f9c                	ld	a5,24(a5)
ffffffffc0200f78:	8782                	jr	a5
{
ffffffffc0200f7a:	1141                	addi	sp,sp,-16
ffffffffc0200f7c:	e406                	sd	ra,8(sp)
ffffffffc0200f7e:	e022                	sd	s0,0(sp)
ffffffffc0200f80:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200f82:	a33ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f86:	000c6797          	auipc	a5,0xc6
ffffffffc0200f8a:	b127b783          	ld	a5,-1262(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0200f8e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f90:	8522                	mv	a0,s0
ffffffffc0200f92:	9782                	jalr	a5
ffffffffc0200f94:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200f96:	a19ff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200f9a:	60a2                	ld	ra,8(sp)
ffffffffc0200f9c:	8522                	mv	a0,s0
ffffffffc0200f9e:	6402                	ld	s0,0(sp)
ffffffffc0200fa0:	0141                	addi	sp,sp,16
ffffffffc0200fa2:	8082                	ret

ffffffffc0200fa4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200fa4:	100027f3          	csrr	a5,sstatus
ffffffffc0200fa8:	8b89                	andi	a5,a5,2
ffffffffc0200faa:	e799                	bnez	a5,ffffffffc0200fb8 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200fac:	000c6797          	auipc	a5,0xc6
ffffffffc0200fb0:	aec7b783          	ld	a5,-1300(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0200fb4:	739c                	ld	a5,32(a5)
ffffffffc0200fb6:	8782                	jr	a5
{
ffffffffc0200fb8:	1101                	addi	sp,sp,-32
ffffffffc0200fba:	ec06                	sd	ra,24(sp)
ffffffffc0200fbc:	e822                	sd	s0,16(sp)
ffffffffc0200fbe:	e426                	sd	s1,8(sp)
ffffffffc0200fc0:	842a                	mv	s0,a0
ffffffffc0200fc2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200fc4:	9f1ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200fc8:	000c6797          	auipc	a5,0xc6
ffffffffc0200fcc:	ad07b783          	ld	a5,-1328(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0200fd0:	739c                	ld	a5,32(a5)
ffffffffc0200fd2:	85a6                	mv	a1,s1
ffffffffc0200fd4:	8522                	mv	a0,s0
ffffffffc0200fd6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200fd8:	6442                	ld	s0,16(sp)
ffffffffc0200fda:	60e2                	ld	ra,24(sp)
ffffffffc0200fdc:	64a2                	ld	s1,8(sp)
ffffffffc0200fde:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200fe0:	9cfff06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0200fe4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200fe4:	100027f3          	csrr	a5,sstatus
ffffffffc0200fe8:	8b89                	andi	a5,a5,2
ffffffffc0200fea:	e799                	bnez	a5,ffffffffc0200ff8 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200fec:	000c6797          	auipc	a5,0xc6
ffffffffc0200ff0:	aac7b783          	ld	a5,-1364(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0200ff4:	779c                	ld	a5,40(a5)
ffffffffc0200ff6:	8782                	jr	a5
{
ffffffffc0200ff8:	1141                	addi	sp,sp,-16
ffffffffc0200ffa:	e406                	sd	ra,8(sp)
ffffffffc0200ffc:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200ffe:	9b7ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201002:	000c6797          	auipc	a5,0xc6
ffffffffc0201006:	a967b783          	ld	a5,-1386(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc020100a:	779c                	ld	a5,40(a5)
ffffffffc020100c:	9782                	jalr	a5
ffffffffc020100e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201010:	99fff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201014:	60a2                	ld	ra,8(sp)
ffffffffc0201016:	8522                	mv	a0,s0
ffffffffc0201018:	6402                	ld	s0,0(sp)
ffffffffc020101a:	0141                	addi	sp,sp,16
ffffffffc020101c:	8082                	ret

ffffffffc020101e <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020101e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201022:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201026:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201028:	078e                	slli	a5,a5,0x3
{
ffffffffc020102a:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020102c:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201030:	6094                	ld	a3,0(s1)
{
ffffffffc0201032:	f04a                	sd	s2,32(sp)
ffffffffc0201034:	ec4e                	sd	s3,24(sp)
ffffffffc0201036:	e852                	sd	s4,16(sp)
ffffffffc0201038:	fc06                	sd	ra,56(sp)
ffffffffc020103a:	f822                	sd	s0,48(sp)
ffffffffc020103c:	e456                	sd	s5,8(sp)
ffffffffc020103e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201040:	0016f793          	andi	a5,a3,1
{
ffffffffc0201044:	892e                	mv	s2,a1
ffffffffc0201046:	8a32                	mv	s4,a2
ffffffffc0201048:	000c6997          	auipc	s3,0xc6
ffffffffc020104c:	a4098993          	addi	s3,s3,-1472 # ffffffffc02c6a88 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201050:	efbd                	bnez	a5,ffffffffc02010ce <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201052:	14060c63          	beqz	a2,ffffffffc02011aa <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201056:	100027f3          	csrr	a5,sstatus
ffffffffc020105a:	8b89                	andi	a5,a5,2
ffffffffc020105c:	14079963          	bnez	a5,ffffffffc02011ae <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201060:	000c6797          	auipc	a5,0xc6
ffffffffc0201064:	a387b783          	ld	a5,-1480(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0201068:	6f9c                	ld	a5,24(a5)
ffffffffc020106a:	4505                	li	a0,1
ffffffffc020106c:	9782                	jalr	a5
ffffffffc020106e:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201070:	12040d63          	beqz	s0,ffffffffc02011aa <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201074:	000c6b17          	auipc	s6,0xc6
ffffffffc0201078:	a1cb0b13          	addi	s6,s6,-1508 # ffffffffc02c6a90 <pages>
ffffffffc020107c:	000b3503          	ld	a0,0(s6)
ffffffffc0201080:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201084:	000c6997          	auipc	s3,0xc6
ffffffffc0201088:	a0498993          	addi	s3,s3,-1532 # ffffffffc02c6a88 <npage>
ffffffffc020108c:	40a40533          	sub	a0,s0,a0
ffffffffc0201090:	8519                	srai	a0,a0,0x6
ffffffffc0201092:	9556                	add	a0,a0,s5
ffffffffc0201094:	0009b703          	ld	a4,0(s3)
ffffffffc0201098:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020109c:	4685                	li	a3,1
ffffffffc020109e:	c014                	sw	a3,0(s0)
ffffffffc02010a0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a2:	0532                	slli	a0,a0,0xc
ffffffffc02010a4:	16e7f763          	bgeu	a5,a4,ffffffffc0201212 <get_pte+0x1f4>
ffffffffc02010a8:	000c6797          	auipc	a5,0xc6
ffffffffc02010ac:	9f87b783          	ld	a5,-1544(a5) # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc02010b0:	6605                	lui	a2,0x1
ffffffffc02010b2:	4581                	li	a1,0
ffffffffc02010b4:	953e                	add	a0,a0,a5
ffffffffc02010b6:	3ee040ef          	jal	ra,ffffffffc02054a4 <memset>
    return page - pages + nbase;
ffffffffc02010ba:	000b3683          	ld	a3,0(s6)
ffffffffc02010be:	40d406b3          	sub	a3,s0,a3
ffffffffc02010c2:	8699                	srai	a3,a3,0x6
ffffffffc02010c4:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02010c6:	06aa                	slli	a3,a3,0xa
ffffffffc02010c8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02010cc:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02010ce:	77fd                	lui	a5,0xfffff
ffffffffc02010d0:	068a                	slli	a3,a3,0x2
ffffffffc02010d2:	0009b703          	ld	a4,0(s3)
ffffffffc02010d6:	8efd                	and	a3,a3,a5
ffffffffc02010d8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02010dc:	10e7ff63          	bgeu	a5,a4,ffffffffc02011fa <get_pte+0x1dc>
ffffffffc02010e0:	000c6a97          	auipc	s5,0xc6
ffffffffc02010e4:	9c0a8a93          	addi	s5,s5,-1600 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc02010e8:	000ab403          	ld	s0,0(s5)
ffffffffc02010ec:	01595793          	srli	a5,s2,0x15
ffffffffc02010f0:	1ff7f793          	andi	a5,a5,511
ffffffffc02010f4:	96a2                	add	a3,a3,s0
ffffffffc02010f6:	00379413          	slli	s0,a5,0x3
ffffffffc02010fa:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02010fc:	6014                	ld	a3,0(s0)
ffffffffc02010fe:	0016f793          	andi	a5,a3,1
ffffffffc0201102:	ebad                	bnez	a5,ffffffffc0201174 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201104:	0a0a0363          	beqz	s4,ffffffffc02011aa <get_pte+0x18c>
ffffffffc0201108:	100027f3          	csrr	a5,sstatus
ffffffffc020110c:	8b89                	andi	a5,a5,2
ffffffffc020110e:	efcd                	bnez	a5,ffffffffc02011c8 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201110:	000c6797          	auipc	a5,0xc6
ffffffffc0201114:	9887b783          	ld	a5,-1656(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc0201118:	6f9c                	ld	a5,24(a5)
ffffffffc020111a:	4505                	li	a0,1
ffffffffc020111c:	9782                	jalr	a5
ffffffffc020111e:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201120:	c4c9                	beqz	s1,ffffffffc02011aa <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201122:	000c6b17          	auipc	s6,0xc6
ffffffffc0201126:	96eb0b13          	addi	s6,s6,-1682 # ffffffffc02c6a90 <pages>
ffffffffc020112a:	000b3503          	ld	a0,0(s6)
ffffffffc020112e:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201132:	0009b703          	ld	a4,0(s3)
ffffffffc0201136:	40a48533          	sub	a0,s1,a0
ffffffffc020113a:	8519                	srai	a0,a0,0x6
ffffffffc020113c:	9552                	add	a0,a0,s4
ffffffffc020113e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201142:	4685                	li	a3,1
ffffffffc0201144:	c094                	sw	a3,0(s1)
ffffffffc0201146:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201148:	0532                	slli	a0,a0,0xc
ffffffffc020114a:	0ee7f163          	bgeu	a5,a4,ffffffffc020122c <get_pte+0x20e>
ffffffffc020114e:	000ab783          	ld	a5,0(s5)
ffffffffc0201152:	6605                	lui	a2,0x1
ffffffffc0201154:	4581                	li	a1,0
ffffffffc0201156:	953e                	add	a0,a0,a5
ffffffffc0201158:	34c040ef          	jal	ra,ffffffffc02054a4 <memset>
    return page - pages + nbase;
ffffffffc020115c:	000b3683          	ld	a3,0(s6)
ffffffffc0201160:	40d486b3          	sub	a3,s1,a3
ffffffffc0201164:	8699                	srai	a3,a3,0x6
ffffffffc0201166:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201168:	06aa                	slli	a3,a3,0xa
ffffffffc020116a:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020116e:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201170:	0009b703          	ld	a4,0(s3)
ffffffffc0201174:	068a                	slli	a3,a3,0x2
ffffffffc0201176:	757d                	lui	a0,0xfffff
ffffffffc0201178:	8ee9                	and	a3,a3,a0
ffffffffc020117a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020117e:	06e7f263          	bgeu	a5,a4,ffffffffc02011e2 <get_pte+0x1c4>
ffffffffc0201182:	000ab503          	ld	a0,0(s5)
ffffffffc0201186:	00c95913          	srli	s2,s2,0xc
ffffffffc020118a:	1ff97913          	andi	s2,s2,511
ffffffffc020118e:	96aa                	add	a3,a3,a0
ffffffffc0201190:	00391513          	slli	a0,s2,0x3
ffffffffc0201194:	9536                	add	a0,a0,a3
}
ffffffffc0201196:	70e2                	ld	ra,56(sp)
ffffffffc0201198:	7442                	ld	s0,48(sp)
ffffffffc020119a:	74a2                	ld	s1,40(sp)
ffffffffc020119c:	7902                	ld	s2,32(sp)
ffffffffc020119e:	69e2                	ld	s3,24(sp)
ffffffffc02011a0:	6a42                	ld	s4,16(sp)
ffffffffc02011a2:	6aa2                	ld	s5,8(sp)
ffffffffc02011a4:	6b02                	ld	s6,0(sp)
ffffffffc02011a6:	6121                	addi	sp,sp,64
ffffffffc02011a8:	8082                	ret
            return NULL;
ffffffffc02011aa:	4501                	li	a0,0
ffffffffc02011ac:	b7ed                	j	ffffffffc0201196 <get_pte+0x178>
        intr_disable();
ffffffffc02011ae:	807ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02011b2:	000c6797          	auipc	a5,0xc6
ffffffffc02011b6:	8e67b783          	ld	a5,-1818(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02011ba:	6f9c                	ld	a5,24(a5)
ffffffffc02011bc:	4505                	li	a0,1
ffffffffc02011be:	9782                	jalr	a5
ffffffffc02011c0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02011c2:	fecff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02011c6:	b56d                	j	ffffffffc0201070 <get_pte+0x52>
        intr_disable();
ffffffffc02011c8:	fecff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02011cc:	000c6797          	auipc	a5,0xc6
ffffffffc02011d0:	8cc7b783          	ld	a5,-1844(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02011d4:	6f9c                	ld	a5,24(a5)
ffffffffc02011d6:	4505                	li	a0,1
ffffffffc02011d8:	9782                	jalr	a5
ffffffffc02011da:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02011dc:	fd2ff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02011e0:	b781                	j	ffffffffc0201120 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02011e2:	00005617          	auipc	a2,0x5
ffffffffc02011e6:	20660613          	addi	a2,a2,518 # ffffffffc02063e8 <commands+0x868>
ffffffffc02011ea:	0fa00593          	li	a1,250
ffffffffc02011ee:	00005517          	auipc	a0,0x5
ffffffffc02011f2:	22250513          	addi	a0,a0,546 # ffffffffc0206410 <commands+0x890>
ffffffffc02011f6:	82cff0ef          	jal	ra,ffffffffc0200222 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02011fa:	00005617          	auipc	a2,0x5
ffffffffc02011fe:	1ee60613          	addi	a2,a2,494 # ffffffffc02063e8 <commands+0x868>
ffffffffc0201202:	0ed00593          	li	a1,237
ffffffffc0201206:	00005517          	auipc	a0,0x5
ffffffffc020120a:	20a50513          	addi	a0,a0,522 # ffffffffc0206410 <commands+0x890>
ffffffffc020120e:	814ff0ef          	jal	ra,ffffffffc0200222 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201212:	86aa                	mv	a3,a0
ffffffffc0201214:	00005617          	auipc	a2,0x5
ffffffffc0201218:	1d460613          	addi	a2,a2,468 # ffffffffc02063e8 <commands+0x868>
ffffffffc020121c:	0e900593          	li	a1,233
ffffffffc0201220:	00005517          	auipc	a0,0x5
ffffffffc0201224:	1f050513          	addi	a0,a0,496 # ffffffffc0206410 <commands+0x890>
ffffffffc0201228:	ffbfe0ef          	jal	ra,ffffffffc0200222 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020122c:	86aa                	mv	a3,a0
ffffffffc020122e:	00005617          	auipc	a2,0x5
ffffffffc0201232:	1ba60613          	addi	a2,a2,442 # ffffffffc02063e8 <commands+0x868>
ffffffffc0201236:	0f700593          	li	a1,247
ffffffffc020123a:	00005517          	auipc	a0,0x5
ffffffffc020123e:	1d650513          	addi	a0,a0,470 # ffffffffc0206410 <commands+0x890>
ffffffffc0201242:	fe1fe0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0201246 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201246:	1141                	addi	sp,sp,-16
ffffffffc0201248:	e022                	sd	s0,0(sp)
ffffffffc020124a:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020124c:	4601                	li	a2,0
{
ffffffffc020124e:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201250:	dcfff0ef          	jal	ra,ffffffffc020101e <get_pte>
    if (ptep_store != NULL)
ffffffffc0201254:	c011                	beqz	s0,ffffffffc0201258 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201256:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201258:	c511                	beqz	a0,ffffffffc0201264 <get_page+0x1e>
ffffffffc020125a:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020125c:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020125e:	0017f713          	andi	a4,a5,1
ffffffffc0201262:	e709                	bnez	a4,ffffffffc020126c <get_page+0x26>
}
ffffffffc0201264:	60a2                	ld	ra,8(sp)
ffffffffc0201266:	6402                	ld	s0,0(sp)
ffffffffc0201268:	0141                	addi	sp,sp,16
ffffffffc020126a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020126c:	078a                	slli	a5,a5,0x2
ffffffffc020126e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201270:	000c6717          	auipc	a4,0xc6
ffffffffc0201274:	81873703          	ld	a4,-2024(a4) # ffffffffc02c6a88 <npage>
ffffffffc0201278:	00e7ff63          	bgeu	a5,a4,ffffffffc0201296 <get_page+0x50>
ffffffffc020127c:	60a2                	ld	ra,8(sp)
ffffffffc020127e:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201280:	fff80537          	lui	a0,0xfff80
ffffffffc0201284:	97aa                	add	a5,a5,a0
ffffffffc0201286:	079a                	slli	a5,a5,0x6
ffffffffc0201288:	000c6517          	auipc	a0,0xc6
ffffffffc020128c:	80853503          	ld	a0,-2040(a0) # ffffffffc02c6a90 <pages>
ffffffffc0201290:	953e                	add	a0,a0,a5
ffffffffc0201292:	0141                	addi	sp,sp,16
ffffffffc0201294:	8082                	ret
ffffffffc0201296:	c99ff0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>

ffffffffc020129a <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020129a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020129c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02012a0:	f486                	sd	ra,104(sp)
ffffffffc02012a2:	f0a2                	sd	s0,96(sp)
ffffffffc02012a4:	eca6                	sd	s1,88(sp)
ffffffffc02012a6:	e8ca                	sd	s2,80(sp)
ffffffffc02012a8:	e4ce                	sd	s3,72(sp)
ffffffffc02012aa:	e0d2                	sd	s4,64(sp)
ffffffffc02012ac:	fc56                	sd	s5,56(sp)
ffffffffc02012ae:	f85a                	sd	s6,48(sp)
ffffffffc02012b0:	f45e                	sd	s7,40(sp)
ffffffffc02012b2:	f062                	sd	s8,32(sp)
ffffffffc02012b4:	ec66                	sd	s9,24(sp)
ffffffffc02012b6:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012b8:	17d2                	slli	a5,a5,0x34
ffffffffc02012ba:	e3ed                	bnez	a5,ffffffffc020139c <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02012bc:	002007b7          	lui	a5,0x200
ffffffffc02012c0:	842e                	mv	s0,a1
ffffffffc02012c2:	0ef5ed63          	bltu	a1,a5,ffffffffc02013bc <unmap_range+0x122>
ffffffffc02012c6:	8932                	mv	s2,a2
ffffffffc02012c8:	0ec5fa63          	bgeu	a1,a2,ffffffffc02013bc <unmap_range+0x122>
ffffffffc02012cc:	4785                	li	a5,1
ffffffffc02012ce:	07fe                	slli	a5,a5,0x1f
ffffffffc02012d0:	0ec7e663          	bltu	a5,a2,ffffffffc02013bc <unmap_range+0x122>
ffffffffc02012d4:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02012d6:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02012d8:	000c5c97          	auipc	s9,0xc5
ffffffffc02012dc:	7b0c8c93          	addi	s9,s9,1968 # ffffffffc02c6a88 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02012e0:	000c5c17          	auipc	s8,0xc5
ffffffffc02012e4:	7b0c0c13          	addi	s8,s8,1968 # ffffffffc02c6a90 <pages>
ffffffffc02012e8:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02012ec:	000c5d17          	auipc	s10,0xc5
ffffffffc02012f0:	7acd0d13          	addi	s10,s10,1964 # ffffffffc02c6a98 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02012f4:	00200b37          	lui	s6,0x200
ffffffffc02012f8:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02012fc:	4601                	li	a2,0
ffffffffc02012fe:	85a2                	mv	a1,s0
ffffffffc0201300:	854e                	mv	a0,s3
ffffffffc0201302:	d1dff0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc0201306:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0201308:	cd29                	beqz	a0,ffffffffc0201362 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020130a:	611c                	ld	a5,0(a0)
ffffffffc020130c:	e395                	bnez	a5,ffffffffc0201330 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc020130e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201310:	ff2466e3          	bltu	s0,s2,ffffffffc02012fc <unmap_range+0x62>
}
ffffffffc0201314:	70a6                	ld	ra,104(sp)
ffffffffc0201316:	7406                	ld	s0,96(sp)
ffffffffc0201318:	64e6                	ld	s1,88(sp)
ffffffffc020131a:	6946                	ld	s2,80(sp)
ffffffffc020131c:	69a6                	ld	s3,72(sp)
ffffffffc020131e:	6a06                	ld	s4,64(sp)
ffffffffc0201320:	7ae2                	ld	s5,56(sp)
ffffffffc0201322:	7b42                	ld	s6,48(sp)
ffffffffc0201324:	7ba2                	ld	s7,40(sp)
ffffffffc0201326:	7c02                	ld	s8,32(sp)
ffffffffc0201328:	6ce2                	ld	s9,24(sp)
ffffffffc020132a:	6d42                	ld	s10,16(sp)
ffffffffc020132c:	6165                	addi	sp,sp,112
ffffffffc020132e:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0201330:	0017f713          	andi	a4,a5,1
ffffffffc0201334:	df69                	beqz	a4,ffffffffc020130e <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0201336:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020133a:	078a                	slli	a5,a5,0x2
ffffffffc020133c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020133e:	08e7ff63          	bgeu	a5,a4,ffffffffc02013dc <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0201342:	000c3503          	ld	a0,0(s8)
ffffffffc0201346:	97de                	add	a5,a5,s7
ffffffffc0201348:	079a                	slli	a5,a5,0x6
ffffffffc020134a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020134c:	411c                	lw	a5,0(a0)
ffffffffc020134e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201352:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201354:	cf11                	beqz	a4,ffffffffc0201370 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201356:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020135a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020135e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201360:	bf45                	j	ffffffffc0201310 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0201362:	945a                	add	s0,s0,s6
ffffffffc0201364:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0201368:	d455                	beqz	s0,ffffffffc0201314 <unmap_range+0x7a>
ffffffffc020136a:	f92469e3          	bltu	s0,s2,ffffffffc02012fc <unmap_range+0x62>
ffffffffc020136e:	b75d                	j	ffffffffc0201314 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201370:	100027f3          	csrr	a5,sstatus
ffffffffc0201374:	8b89                	andi	a5,a5,2
ffffffffc0201376:	e799                	bnez	a5,ffffffffc0201384 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0201378:	000d3783          	ld	a5,0(s10)
ffffffffc020137c:	4585                	li	a1,1
ffffffffc020137e:	739c                	ld	a5,32(a5)
ffffffffc0201380:	9782                	jalr	a5
    if (flag)
ffffffffc0201382:	bfd1                	j	ffffffffc0201356 <unmap_range+0xbc>
ffffffffc0201384:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201386:	e2eff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020138a:	000d3783          	ld	a5,0(s10)
ffffffffc020138e:	6522                	ld	a0,8(sp)
ffffffffc0201390:	4585                	li	a1,1
ffffffffc0201392:	739c                	ld	a5,32(a5)
ffffffffc0201394:	9782                	jalr	a5
        intr_enable();
ffffffffc0201396:	e18ff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020139a:	bf75                	j	ffffffffc0201356 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	08468693          	addi	a3,a3,132 # ffffffffc0206420 <commands+0x8a0>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	0ac60613          	addi	a2,a2,172 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02013ac:	12200593          	li	a1,290
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	06050513          	addi	a0,a0,96 # ffffffffc0206410 <commands+0x890>
ffffffffc02013b8:	e6bfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	0ac68693          	addi	a3,a3,172 # ffffffffc0206468 <commands+0x8e8>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	08c60613          	addi	a2,a2,140 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02013cc:	12300593          	li	a1,291
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	04050513          	addi	a0,a0,64 # ffffffffc0206410 <commands+0x890>
ffffffffc02013d8:	e4bfe0ef          	jal	ra,ffffffffc0200222 <__panic>
ffffffffc02013dc:	b53ff0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>

ffffffffc02013e0 <exit_range>:
{
ffffffffc02013e0:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02013e2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02013e6:	fc86                	sd	ra,120(sp)
ffffffffc02013e8:	f8a2                	sd	s0,112(sp)
ffffffffc02013ea:	f4a6                	sd	s1,104(sp)
ffffffffc02013ec:	f0ca                	sd	s2,96(sp)
ffffffffc02013ee:	ecce                	sd	s3,88(sp)
ffffffffc02013f0:	e8d2                	sd	s4,80(sp)
ffffffffc02013f2:	e4d6                	sd	s5,72(sp)
ffffffffc02013f4:	e0da                	sd	s6,64(sp)
ffffffffc02013f6:	fc5e                	sd	s7,56(sp)
ffffffffc02013f8:	f862                	sd	s8,48(sp)
ffffffffc02013fa:	f466                	sd	s9,40(sp)
ffffffffc02013fc:	f06a                	sd	s10,32(sp)
ffffffffc02013fe:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201400:	17d2                	slli	a5,a5,0x34
ffffffffc0201402:	20079a63          	bnez	a5,ffffffffc0201616 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0201406:	002007b7          	lui	a5,0x200
ffffffffc020140a:	24f5e463          	bltu	a1,a5,ffffffffc0201652 <exit_range+0x272>
ffffffffc020140e:	8ab2                	mv	s5,a2
ffffffffc0201410:	24c5f163          	bgeu	a1,a2,ffffffffc0201652 <exit_range+0x272>
ffffffffc0201414:	4785                	li	a5,1
ffffffffc0201416:	07fe                	slli	a5,a5,0x1f
ffffffffc0201418:	22c7ed63          	bltu	a5,a2,ffffffffc0201652 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020141c:	c00009b7          	lui	s3,0xc0000
ffffffffc0201420:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0201424:	ffe00937          	lui	s2,0xffe00
ffffffffc0201428:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020142c:	5cfd                	li	s9,-1
ffffffffc020142e:	8c2a                	mv	s8,a0
ffffffffc0201430:	0125f933          	and	s2,a1,s2
ffffffffc0201434:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0201436:	000c5d17          	auipc	s10,0xc5
ffffffffc020143a:	652d0d13          	addi	s10,s10,1618 # ffffffffc02c6a88 <npage>
    return KADDR(page2pa(page));
ffffffffc020143e:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201442:	000c5717          	auipc	a4,0xc5
ffffffffc0201446:	64e70713          	addi	a4,a4,1614 # ffffffffc02c6a90 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020144a:	000c5d97          	auipc	s11,0xc5
ffffffffc020144e:	64ed8d93          	addi	s11,s11,1614 # ffffffffc02c6a98 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0201452:	c0000437          	lui	s0,0xc0000
ffffffffc0201456:	944e                	add	s0,s0,s3
ffffffffc0201458:	8079                	srli	s0,s0,0x1e
ffffffffc020145a:	1ff47413          	andi	s0,s0,511
ffffffffc020145e:	040e                	slli	s0,s0,0x3
ffffffffc0201460:	9462                	add	s0,s0,s8
ffffffffc0201462:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff3900>
        if (pde1 & PTE_V)
ffffffffc0201466:	001a7793          	andi	a5,s4,1
ffffffffc020146a:	eb99                	bnez	a5,ffffffffc0201480 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020146c:	12098463          	beqz	s3,ffffffffc0201594 <exit_range+0x1b4>
ffffffffc0201470:	400007b7          	lui	a5,0x40000
ffffffffc0201474:	97ce                	add	a5,a5,s3
ffffffffc0201476:	894e                	mv	s2,s3
ffffffffc0201478:	1159fe63          	bgeu	s3,s5,ffffffffc0201594 <exit_range+0x1b4>
ffffffffc020147c:	89be                	mv	s3,a5
ffffffffc020147e:	bfd1                	j	ffffffffc0201452 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0201480:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201484:	0a0a                	slli	s4,s4,0x2
ffffffffc0201486:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc020148a:	1cfa7263          	bgeu	s4,a5,ffffffffc020164e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020148e:	fff80637          	lui	a2,0xfff80
ffffffffc0201492:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0201494:	000806b7          	lui	a3,0x80
ffffffffc0201498:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020149a:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020149e:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02014a0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02014a2:	18f5fa63          	bgeu	a1,a5,ffffffffc0201636 <exit_range+0x256>
ffffffffc02014a6:	000c5817          	auipc	a6,0xc5
ffffffffc02014aa:	5fa80813          	addi	a6,a6,1530 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc02014ae:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02014b2:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02014b4:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02014b8:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02014ba:	00080337          	lui	t1,0x80
ffffffffc02014be:	6885                	lui	a7,0x1
ffffffffc02014c0:	a819                	j	ffffffffc02014d6 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02014c2:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02014c4:	002007b7          	lui	a5,0x200
ffffffffc02014c8:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02014ca:	08090c63          	beqz	s2,ffffffffc0201562 <exit_range+0x182>
ffffffffc02014ce:	09397a63          	bgeu	s2,s3,ffffffffc0201562 <exit_range+0x182>
ffffffffc02014d2:	0f597063          	bgeu	s2,s5,ffffffffc02015b2 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02014d6:	01595493          	srli	s1,s2,0x15
ffffffffc02014da:	1ff4f493          	andi	s1,s1,511
ffffffffc02014de:	048e                	slli	s1,s1,0x3
ffffffffc02014e0:	94da                	add	s1,s1,s6
ffffffffc02014e2:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02014e4:	0017f693          	andi	a3,a5,1
ffffffffc02014e8:	dee9                	beqz	a3,ffffffffc02014c2 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02014ea:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014ee:	078a                	slli	a5,a5,0x2
ffffffffc02014f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02014f2:	14b7fe63          	bgeu	a5,a1,ffffffffc020164e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02014f6:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02014f8:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02014fc:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0201500:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201504:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201506:	12bef863          	bgeu	t4,a1,ffffffffc0201636 <exit_range+0x256>
ffffffffc020150a:	00083783          	ld	a5,0(a6)
ffffffffc020150e:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0201510:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0201514:	629c                	ld	a5,0(a3)
ffffffffc0201516:	8b85                	andi	a5,a5,1
ffffffffc0201518:	f7d5                	bnez	a5,ffffffffc02014c4 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020151a:	06a1                	addi	a3,a3,8
ffffffffc020151c:	fed59ce3          	bne	a1,a3,ffffffffc0201514 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0201520:	631c                	ld	a5,0(a4)
ffffffffc0201522:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201524:	100027f3          	csrr	a5,sstatus
ffffffffc0201528:	8b89                	andi	a5,a5,2
ffffffffc020152a:	e7d9                	bnez	a5,ffffffffc02015b8 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020152c:	000db783          	ld	a5,0(s11)
ffffffffc0201530:	4585                	li	a1,1
ffffffffc0201532:	e032                	sd	a2,0(sp)
ffffffffc0201534:	739c                	ld	a5,32(a5)
ffffffffc0201536:	9782                	jalr	a5
    if (flag)
ffffffffc0201538:	6602                	ld	a2,0(sp)
ffffffffc020153a:	000c5817          	auipc	a6,0xc5
ffffffffc020153e:	56680813          	addi	a6,a6,1382 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc0201542:	fff80e37          	lui	t3,0xfff80
ffffffffc0201546:	00080337          	lui	t1,0x80
ffffffffc020154a:	6885                	lui	a7,0x1
ffffffffc020154c:	000c5717          	auipc	a4,0xc5
ffffffffc0201550:	54470713          	addi	a4,a4,1348 # ffffffffc02c6a90 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201554:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0201558:	002007b7          	lui	a5,0x200
ffffffffc020155c:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020155e:	f60918e3          	bnez	s2,ffffffffc02014ce <exit_range+0xee>
            if (free_pd0)
ffffffffc0201562:	f00b85e3          	beqz	s7,ffffffffc020146c <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0201566:	000d3783          	ld	a5,0(s10)
ffffffffc020156a:	0efa7263          	bgeu	s4,a5,ffffffffc020164e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020156e:	6308                	ld	a0,0(a4)
ffffffffc0201570:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201572:	100027f3          	csrr	a5,sstatus
ffffffffc0201576:	8b89                	andi	a5,a5,2
ffffffffc0201578:	efad                	bnez	a5,ffffffffc02015f2 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc020157a:	000db783          	ld	a5,0(s11)
ffffffffc020157e:	4585                	li	a1,1
ffffffffc0201580:	739c                	ld	a5,32(a5)
ffffffffc0201582:	9782                	jalr	a5
ffffffffc0201584:	000c5717          	auipc	a4,0xc5
ffffffffc0201588:	50c70713          	addi	a4,a4,1292 # ffffffffc02c6a90 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020158c:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0201590:	ee0990e3          	bnez	s3,ffffffffc0201470 <exit_range+0x90>
}
ffffffffc0201594:	70e6                	ld	ra,120(sp)
ffffffffc0201596:	7446                	ld	s0,112(sp)
ffffffffc0201598:	74a6                	ld	s1,104(sp)
ffffffffc020159a:	7906                	ld	s2,96(sp)
ffffffffc020159c:	69e6                	ld	s3,88(sp)
ffffffffc020159e:	6a46                	ld	s4,80(sp)
ffffffffc02015a0:	6aa6                	ld	s5,72(sp)
ffffffffc02015a2:	6b06                	ld	s6,64(sp)
ffffffffc02015a4:	7be2                	ld	s7,56(sp)
ffffffffc02015a6:	7c42                	ld	s8,48(sp)
ffffffffc02015a8:	7ca2                	ld	s9,40(sp)
ffffffffc02015aa:	7d02                	ld	s10,32(sp)
ffffffffc02015ac:	6de2                	ld	s11,24(sp)
ffffffffc02015ae:	6109                	addi	sp,sp,128
ffffffffc02015b0:	8082                	ret
            if (free_pd0)
ffffffffc02015b2:	ea0b8fe3          	beqz	s7,ffffffffc0201470 <exit_range+0x90>
ffffffffc02015b6:	bf45                	j	ffffffffc0201566 <exit_range+0x186>
ffffffffc02015b8:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02015ba:	e42a                	sd	a0,8(sp)
ffffffffc02015bc:	bf8ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02015c0:	000db783          	ld	a5,0(s11)
ffffffffc02015c4:	6522                	ld	a0,8(sp)
ffffffffc02015c6:	4585                	li	a1,1
ffffffffc02015c8:	739c                	ld	a5,32(a5)
ffffffffc02015ca:	9782                	jalr	a5
        intr_enable();
ffffffffc02015cc:	be2ff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02015d0:	6602                	ld	a2,0(sp)
ffffffffc02015d2:	000c5717          	auipc	a4,0xc5
ffffffffc02015d6:	4be70713          	addi	a4,a4,1214 # ffffffffc02c6a90 <pages>
ffffffffc02015da:	6885                	lui	a7,0x1
ffffffffc02015dc:	00080337          	lui	t1,0x80
ffffffffc02015e0:	fff80e37          	lui	t3,0xfff80
ffffffffc02015e4:	000c5817          	auipc	a6,0xc5
ffffffffc02015e8:	4bc80813          	addi	a6,a6,1212 # ffffffffc02c6aa0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02015ec:	0004b023          	sd	zero,0(s1)
ffffffffc02015f0:	b7a5                	j	ffffffffc0201558 <exit_range+0x178>
ffffffffc02015f2:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02015f4:	bc0ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02015f8:	000db783          	ld	a5,0(s11)
ffffffffc02015fc:	6502                	ld	a0,0(sp)
ffffffffc02015fe:	4585                	li	a1,1
ffffffffc0201600:	739c                	ld	a5,32(a5)
ffffffffc0201602:	9782                	jalr	a5
        intr_enable();
ffffffffc0201604:	baaff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201608:	000c5717          	auipc	a4,0xc5
ffffffffc020160c:	48870713          	addi	a4,a4,1160 # ffffffffc02c6a90 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0201610:	00043023          	sd	zero,0(s0)
ffffffffc0201614:	bfb5                	j	ffffffffc0201590 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201616:	00005697          	auipc	a3,0x5
ffffffffc020161a:	e0a68693          	addi	a3,a3,-502 # ffffffffc0206420 <commands+0x8a0>
ffffffffc020161e:	00005617          	auipc	a2,0x5
ffffffffc0201622:	e3260613          	addi	a2,a2,-462 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201626:	13700593          	li	a1,311
ffffffffc020162a:	00005517          	auipc	a0,0x5
ffffffffc020162e:	de650513          	addi	a0,a0,-538 # ffffffffc0206410 <commands+0x890>
ffffffffc0201632:	bf1fe0ef          	jal	ra,ffffffffc0200222 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201636:	00005617          	auipc	a2,0x5
ffffffffc020163a:	db260613          	addi	a2,a2,-590 # ffffffffc02063e8 <commands+0x868>
ffffffffc020163e:	07100593          	li	a1,113
ffffffffc0201642:	00005517          	auipc	a0,0x5
ffffffffc0201646:	d6e50513          	addi	a0,a0,-658 # ffffffffc02063b0 <commands+0x830>
ffffffffc020164a:	bd9fe0ef          	jal	ra,ffffffffc0200222 <__panic>
ffffffffc020164e:	8e1ff0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0201652:	00005697          	auipc	a3,0x5
ffffffffc0201656:	e1668693          	addi	a3,a3,-490 # ffffffffc0206468 <commands+0x8e8>
ffffffffc020165a:	00005617          	auipc	a2,0x5
ffffffffc020165e:	df660613          	addi	a2,a2,-522 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201662:	13800593          	li	a1,312
ffffffffc0201666:	00005517          	auipc	a0,0x5
ffffffffc020166a:	daa50513          	addi	a0,a0,-598 # ffffffffc0206410 <commands+0x890>
ffffffffc020166e:	bb5fe0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0201672 <page_remove>:
{
ffffffffc0201672:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201674:	4601                	li	a2,0
{
ffffffffc0201676:	ec26                	sd	s1,24(sp)
ffffffffc0201678:	f406                	sd	ra,40(sp)
ffffffffc020167a:	f022                	sd	s0,32(sp)
ffffffffc020167c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020167e:	9a1ff0ef          	jal	ra,ffffffffc020101e <get_pte>
    if (ptep != NULL)
ffffffffc0201682:	c511                	beqz	a0,ffffffffc020168e <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201684:	611c                	ld	a5,0(a0)
ffffffffc0201686:	842a                	mv	s0,a0
ffffffffc0201688:	0017f713          	andi	a4,a5,1
ffffffffc020168c:	e711                	bnez	a4,ffffffffc0201698 <page_remove+0x26>
}
ffffffffc020168e:	70a2                	ld	ra,40(sp)
ffffffffc0201690:	7402                	ld	s0,32(sp)
ffffffffc0201692:	64e2                	ld	s1,24(sp)
ffffffffc0201694:	6145                	addi	sp,sp,48
ffffffffc0201696:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201698:	078a                	slli	a5,a5,0x2
ffffffffc020169a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020169c:	000c5717          	auipc	a4,0xc5
ffffffffc02016a0:	3ec73703          	ld	a4,1004(a4) # ffffffffc02c6a88 <npage>
ffffffffc02016a4:	06e7f363          	bgeu	a5,a4,ffffffffc020170a <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02016a8:	fff80537          	lui	a0,0xfff80
ffffffffc02016ac:	97aa                	add	a5,a5,a0
ffffffffc02016ae:	079a                	slli	a5,a5,0x6
ffffffffc02016b0:	000c5517          	auipc	a0,0xc5
ffffffffc02016b4:	3e053503          	ld	a0,992(a0) # ffffffffc02c6a90 <pages>
ffffffffc02016b8:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02016ba:	411c                	lw	a5,0(a0)
ffffffffc02016bc:	fff7871b          	addiw	a4,a5,-1
ffffffffc02016c0:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02016c2:	cb11                	beqz	a4,ffffffffc02016d6 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02016c4:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02016c8:	12048073          	sfence.vma	s1
}
ffffffffc02016cc:	70a2                	ld	ra,40(sp)
ffffffffc02016ce:	7402                	ld	s0,32(sp)
ffffffffc02016d0:	64e2                	ld	s1,24(sp)
ffffffffc02016d2:	6145                	addi	sp,sp,48
ffffffffc02016d4:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02016d6:	100027f3          	csrr	a5,sstatus
ffffffffc02016da:	8b89                	andi	a5,a5,2
ffffffffc02016dc:	eb89                	bnez	a5,ffffffffc02016ee <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02016de:	000c5797          	auipc	a5,0xc5
ffffffffc02016e2:	3ba7b783          	ld	a5,954(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02016e6:	739c                	ld	a5,32(a5)
ffffffffc02016e8:	4585                	li	a1,1
ffffffffc02016ea:	9782                	jalr	a5
    if (flag)
ffffffffc02016ec:	bfe1                	j	ffffffffc02016c4 <page_remove+0x52>
        intr_disable();
ffffffffc02016ee:	e42a                	sd	a0,8(sp)
ffffffffc02016f0:	ac4ff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02016f4:	000c5797          	auipc	a5,0xc5
ffffffffc02016f8:	3a47b783          	ld	a5,932(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02016fc:	739c                	ld	a5,32(a5)
ffffffffc02016fe:	6522                	ld	a0,8(sp)
ffffffffc0201700:	4585                	li	a1,1
ffffffffc0201702:	9782                	jalr	a5
        intr_enable();
ffffffffc0201704:	aaaff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201708:	bf75                	j	ffffffffc02016c4 <page_remove+0x52>
ffffffffc020170a:	825ff0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>

ffffffffc020170e <page_insert>:
{
ffffffffc020170e:	7139                	addi	sp,sp,-64
ffffffffc0201710:	e852                	sd	s4,16(sp)
ffffffffc0201712:	8a32                	mv	s4,a2
ffffffffc0201714:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201716:	4605                	li	a2,1
{
ffffffffc0201718:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020171a:	85d2                	mv	a1,s4
{
ffffffffc020171c:	f426                	sd	s1,40(sp)
ffffffffc020171e:	fc06                	sd	ra,56(sp)
ffffffffc0201720:	f04a                	sd	s2,32(sp)
ffffffffc0201722:	ec4e                	sd	s3,24(sp)
ffffffffc0201724:	e456                	sd	s5,8(sp)
ffffffffc0201726:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201728:	8f7ff0ef          	jal	ra,ffffffffc020101e <get_pte>
    if (ptep == NULL)
ffffffffc020172c:	c961                	beqz	a0,ffffffffc02017fc <page_insert+0xee>
    page->ref += 1;
ffffffffc020172e:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0201730:	611c                	ld	a5,0(a0)
ffffffffc0201732:	89aa                	mv	s3,a0
ffffffffc0201734:	0016871b          	addiw	a4,a3,1
ffffffffc0201738:	c018                	sw	a4,0(s0)
ffffffffc020173a:	0017f713          	andi	a4,a5,1
ffffffffc020173e:	ef05                	bnez	a4,ffffffffc0201776 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201740:	000c5717          	auipc	a4,0xc5
ffffffffc0201744:	35073703          	ld	a4,848(a4) # ffffffffc02c6a90 <pages>
ffffffffc0201748:	8c19                	sub	s0,s0,a4
ffffffffc020174a:	000807b7          	lui	a5,0x80
ffffffffc020174e:	8419                	srai	s0,s0,0x6
ffffffffc0201750:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201752:	042a                	slli	s0,s0,0xa
ffffffffc0201754:	8cc1                	or	s1,s1,s0
ffffffffc0201756:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020175a:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff3900>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020175e:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201762:	4501                	li	a0,0
}
ffffffffc0201764:	70e2                	ld	ra,56(sp)
ffffffffc0201766:	7442                	ld	s0,48(sp)
ffffffffc0201768:	74a2                	ld	s1,40(sp)
ffffffffc020176a:	7902                	ld	s2,32(sp)
ffffffffc020176c:	69e2                	ld	s3,24(sp)
ffffffffc020176e:	6a42                	ld	s4,16(sp)
ffffffffc0201770:	6aa2                	ld	s5,8(sp)
ffffffffc0201772:	6121                	addi	sp,sp,64
ffffffffc0201774:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201776:	078a                	slli	a5,a5,0x2
ffffffffc0201778:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020177a:	000c5717          	auipc	a4,0xc5
ffffffffc020177e:	30e73703          	ld	a4,782(a4) # ffffffffc02c6a88 <npage>
ffffffffc0201782:	06e7ff63          	bgeu	a5,a4,ffffffffc0201800 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201786:	000c5a97          	auipc	s5,0xc5
ffffffffc020178a:	30aa8a93          	addi	s5,s5,778 # ffffffffc02c6a90 <pages>
ffffffffc020178e:	000ab703          	ld	a4,0(s5)
ffffffffc0201792:	fff80937          	lui	s2,0xfff80
ffffffffc0201796:	993e                	add	s2,s2,a5
ffffffffc0201798:	091a                	slli	s2,s2,0x6
ffffffffc020179a:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020179c:	01240c63          	beq	s0,s2,ffffffffc02017b4 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02017a0:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb9520>
ffffffffc02017a4:	fff7869b          	addiw	a3,a5,-1
ffffffffc02017a8:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02017ac:	c691                	beqz	a3,ffffffffc02017b8 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02017ae:	120a0073          	sfence.vma	s4
}
ffffffffc02017b2:	bf59                	j	ffffffffc0201748 <page_insert+0x3a>
ffffffffc02017b4:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02017b6:	bf49                	j	ffffffffc0201748 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02017b8:	100027f3          	csrr	a5,sstatus
ffffffffc02017bc:	8b89                	andi	a5,a5,2
ffffffffc02017be:	ef91                	bnez	a5,ffffffffc02017da <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02017c0:	000c5797          	auipc	a5,0xc5
ffffffffc02017c4:	2d87b783          	ld	a5,728(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02017c8:	739c                	ld	a5,32(a5)
ffffffffc02017ca:	4585                	li	a1,1
ffffffffc02017cc:	854a                	mv	a0,s2
ffffffffc02017ce:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02017d0:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02017d4:	120a0073          	sfence.vma	s4
ffffffffc02017d8:	bf85                	j	ffffffffc0201748 <page_insert+0x3a>
        intr_disable();
ffffffffc02017da:	9daff0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02017de:	000c5797          	auipc	a5,0xc5
ffffffffc02017e2:	2ba7b783          	ld	a5,698(a5) # ffffffffc02c6a98 <pmm_manager>
ffffffffc02017e6:	739c                	ld	a5,32(a5)
ffffffffc02017e8:	4585                	li	a1,1
ffffffffc02017ea:	854a                	mv	a0,s2
ffffffffc02017ec:	9782                	jalr	a5
        intr_enable();
ffffffffc02017ee:	9c0ff0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02017f2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02017f6:	120a0073          	sfence.vma	s4
ffffffffc02017fa:	b7b9                	j	ffffffffc0201748 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02017fc:	5571                	li	a0,-4
ffffffffc02017fe:	b79d                	j	ffffffffc0201764 <page_insert+0x56>
ffffffffc0201800:	f2eff0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>

ffffffffc0201804 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201804:	00006797          	auipc	a5,0x6
ffffffffc0201808:	91c78793          	addi	a5,a5,-1764 # ffffffffc0207120 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020180c:	638c                	ld	a1,0(a5)
{
ffffffffc020180e:	7159                	addi	sp,sp,-112
ffffffffc0201810:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201812:	00005517          	auipc	a0,0x5
ffffffffc0201816:	c6e50513          	addi	a0,a0,-914 # ffffffffc0206480 <commands+0x900>
    pmm_manager = &default_pmm_manager;
ffffffffc020181a:	000c5b17          	auipc	s6,0xc5
ffffffffc020181e:	27eb0b13          	addi	s6,s6,638 # ffffffffc02c6a98 <pmm_manager>
{
ffffffffc0201822:	f486                	sd	ra,104(sp)
ffffffffc0201824:	e8ca                	sd	s2,80(sp)
ffffffffc0201826:	e4ce                	sd	s3,72(sp)
ffffffffc0201828:	f0a2                	sd	s0,96(sp)
ffffffffc020182a:	eca6                	sd	s1,88(sp)
ffffffffc020182c:	e0d2                	sd	s4,64(sp)
ffffffffc020182e:	fc56                	sd	s5,56(sp)
ffffffffc0201830:	f45e                	sd	s7,40(sp)
ffffffffc0201832:	f062                	sd	s8,32(sp)
ffffffffc0201834:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201836:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020183a:	8abfe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    pmm_manager->init();
ffffffffc020183e:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201842:	000c5997          	auipc	s3,0xc5
ffffffffc0201846:	25e98993          	addi	s3,s3,606 # ffffffffc02c6aa0 <va_pa_offset>
    pmm_manager->init();
ffffffffc020184a:	679c                	ld	a5,8(a5)
ffffffffc020184c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020184e:	57f5                	li	a5,-3
ffffffffc0201850:	07fa                	slli	a5,a5,0x1e
ffffffffc0201852:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201856:	886ff0ef          	jal	ra,ffffffffc02008dc <get_memory_base>
ffffffffc020185a:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020185c:	88aff0ef          	jal	ra,ffffffffc02008e6 <get_memory_size>
    if (mem_size == 0)
ffffffffc0201860:	200505e3          	beqz	a0,ffffffffc020226a <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0201864:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201866:	00005517          	auipc	a0,0x5
ffffffffc020186a:	c5250513          	addi	a0,a0,-942 # ffffffffc02064b8 <commands+0x938>
ffffffffc020186e:	877fe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0201872:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201876:	fff40693          	addi	a3,s0,-1
ffffffffc020187a:	864a                	mv	a2,s2
ffffffffc020187c:	85a6                	mv	a1,s1
ffffffffc020187e:	00005517          	auipc	a0,0x5
ffffffffc0201882:	c5250513          	addi	a0,a0,-942 # ffffffffc02064d0 <commands+0x950>
ffffffffc0201886:	85ffe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020188a:	c8000737          	lui	a4,0xc8000
ffffffffc020188e:	87a2                	mv	a5,s0
ffffffffc0201890:	54876163          	bltu	a4,s0,ffffffffc0201dd2 <pmm_init+0x5ce>
ffffffffc0201894:	757d                	lui	a0,0xfffff
ffffffffc0201896:	000c6617          	auipc	a2,0xc6
ffffffffc020189a:	24960613          	addi	a2,a2,585 # ffffffffc02c7adf <end+0xfff>
ffffffffc020189e:	8e69                	and	a2,a2,a0
ffffffffc02018a0:	000c5497          	auipc	s1,0xc5
ffffffffc02018a4:	1e848493          	addi	s1,s1,488 # ffffffffc02c6a88 <npage>
ffffffffc02018a8:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018ac:	000c5b97          	auipc	s7,0xc5
ffffffffc02018b0:	1e4b8b93          	addi	s7,s7,484 # ffffffffc02c6a90 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02018b4:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018b6:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02018ba:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018be:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02018c0:	02f50863          	beq	a0,a5,ffffffffc02018f0 <pmm_init+0xec>
ffffffffc02018c4:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018c6:	4585                	li	a1,1
ffffffffc02018c8:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02018cc:	00679513          	slli	a0,a5,0x6
ffffffffc02018d0:	9532                	add	a0,a0,a2
ffffffffc02018d2:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd38528>
ffffffffc02018d6:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02018da:	6088                	ld	a0,0(s1)
ffffffffc02018dc:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02018de:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02018e2:	00d50733          	add	a4,a0,a3
ffffffffc02018e6:	fee7e3e3          	bltu	a5,a4,ffffffffc02018cc <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018ea:	071a                	slli	a4,a4,0x6
ffffffffc02018ec:	00e606b3          	add	a3,a2,a4
ffffffffc02018f0:	c02007b7          	lui	a5,0xc0200
ffffffffc02018f4:	2ef6ece3          	bltu	a3,a5,ffffffffc02023ec <pmm_init+0xbe8>
ffffffffc02018f8:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018fc:	77fd                	lui	a5,0xfffff
ffffffffc02018fe:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201900:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0201902:	5086eb63          	bltu	a3,s0,ffffffffc0201e18 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201906:	00005517          	auipc	a0,0x5
ffffffffc020190a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0206520 <commands+0x9a0>
ffffffffc020190e:	fd6fe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201912:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201916:	000c5917          	auipc	s2,0xc5
ffffffffc020191a:	16a90913          	addi	s2,s2,362 # ffffffffc02c6a80 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020191e:	7b9c                	ld	a5,48(a5)
ffffffffc0201920:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201922:	00005517          	auipc	a0,0x5
ffffffffc0201926:	c1650513          	addi	a0,a0,-1002 # ffffffffc0206538 <commands+0x9b8>
ffffffffc020192a:	fbafe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020192e:	00009697          	auipc	a3,0x9
ffffffffc0201932:	6d268693          	addi	a3,a3,1746 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0201936:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020193a:	c02007b7          	lui	a5,0xc0200
ffffffffc020193e:	28f6ebe3          	bltu	a3,a5,ffffffffc02023d4 <pmm_init+0xbd0>
ffffffffc0201942:	0009b783          	ld	a5,0(s3)
ffffffffc0201946:	8e9d                	sub	a3,a3,a5
ffffffffc0201948:	000c5797          	auipc	a5,0xc5
ffffffffc020194c:	12d7b823          	sd	a3,304(a5) # ffffffffc02c6a78 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201950:	100027f3          	csrr	a5,sstatus
ffffffffc0201954:	8b89                	andi	a5,a5,2
ffffffffc0201956:	4a079763          	bnez	a5,ffffffffc0201e04 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020195a:	000b3783          	ld	a5,0(s6)
ffffffffc020195e:	779c                	ld	a5,40(a5)
ffffffffc0201960:	9782                	jalr	a5
ffffffffc0201962:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201964:	6098                	ld	a4,0(s1)
ffffffffc0201966:	c80007b7          	lui	a5,0xc8000
ffffffffc020196a:	83b1                	srli	a5,a5,0xc
ffffffffc020196c:	66e7e363          	bltu	a5,a4,ffffffffc0201fd2 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201970:	00093503          	ld	a0,0(s2)
ffffffffc0201974:	62050f63          	beqz	a0,ffffffffc0201fb2 <pmm_init+0x7ae>
ffffffffc0201978:	03451793          	slli	a5,a0,0x34
ffffffffc020197c:	62079b63          	bnez	a5,ffffffffc0201fb2 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201980:	4601                	li	a2,0
ffffffffc0201982:	4581                	li	a1,0
ffffffffc0201984:	8c3ff0ef          	jal	ra,ffffffffc0201246 <get_page>
ffffffffc0201988:	60051563          	bnez	a0,ffffffffc0201f92 <pmm_init+0x78e>
ffffffffc020198c:	100027f3          	csrr	a5,sstatus
ffffffffc0201990:	8b89                	andi	a5,a5,2
ffffffffc0201992:	44079e63          	bnez	a5,ffffffffc0201dee <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201996:	000b3783          	ld	a5,0(s6)
ffffffffc020199a:	4505                	li	a0,1
ffffffffc020199c:	6f9c                	ld	a5,24(a5)
ffffffffc020199e:	9782                	jalr	a5
ffffffffc02019a0:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02019a2:	00093503          	ld	a0,0(s2)
ffffffffc02019a6:	4681                	li	a3,0
ffffffffc02019a8:	4601                	li	a2,0
ffffffffc02019aa:	85d2                	mv	a1,s4
ffffffffc02019ac:	d63ff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc02019b0:	26051ae3          	bnez	a0,ffffffffc0202424 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02019b4:	00093503          	ld	a0,0(s2)
ffffffffc02019b8:	4601                	li	a2,0
ffffffffc02019ba:	4581                	li	a1,0
ffffffffc02019bc:	e62ff0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc02019c0:	240502e3          	beqz	a0,ffffffffc0202404 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02019c4:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02019c6:	0017f713          	andi	a4,a5,1
ffffffffc02019ca:	5a070263          	beqz	a4,ffffffffc0201f6e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02019ce:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02019d0:	078a                	slli	a5,a5,0x2
ffffffffc02019d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02019d4:	58e7fb63          	bgeu	a5,a4,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02019d8:	000bb683          	ld	a3,0(s7)
ffffffffc02019dc:	fff80637          	lui	a2,0xfff80
ffffffffc02019e0:	97b2                	add	a5,a5,a2
ffffffffc02019e2:	079a                	slli	a5,a5,0x6
ffffffffc02019e4:	97b6                	add	a5,a5,a3
ffffffffc02019e6:	14fa17e3          	bne	s4,a5,ffffffffc0202334 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02019ea:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f38>
ffffffffc02019ee:	4785                	li	a5,1
ffffffffc02019f0:	12f692e3          	bne	a3,a5,ffffffffc0202314 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02019f4:	00093503          	ld	a0,0(s2)
ffffffffc02019f8:	77fd                	lui	a5,0xfffff
ffffffffc02019fa:	6114                	ld	a3,0(a0)
ffffffffc02019fc:	068a                	slli	a3,a3,0x2
ffffffffc02019fe:	8efd                	and	a3,a3,a5
ffffffffc0201a00:	00c6d613          	srli	a2,a3,0xc
ffffffffc0201a04:	0ee67ce3          	bgeu	a2,a4,ffffffffc02022fc <pmm_init+0xaf8>
ffffffffc0201a08:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201a0c:	96e2                	add	a3,a3,s8
ffffffffc0201a0e:	0006ba83          	ld	s5,0(a3)
ffffffffc0201a12:	0a8a                	slli	s5,s5,0x2
ffffffffc0201a14:	00fafab3          	and	s5,s5,a5
ffffffffc0201a18:	00cad793          	srli	a5,s5,0xc
ffffffffc0201a1c:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02022e2 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a20:	4601                	li	a2,0
ffffffffc0201a22:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201a24:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a26:	df8ff0ef          	jal	ra,ffffffffc020101e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201a2a:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a2c:	55551363          	bne	a0,s5,ffffffffc0201f72 <pmm_init+0x76e>
ffffffffc0201a30:	100027f3          	csrr	a5,sstatus
ffffffffc0201a34:	8b89                	andi	a5,a5,2
ffffffffc0201a36:	3a079163          	bnez	a5,ffffffffc0201dd8 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201a3a:	000b3783          	ld	a5,0(s6)
ffffffffc0201a3e:	4505                	li	a0,1
ffffffffc0201a40:	6f9c                	ld	a5,24(a5)
ffffffffc0201a42:	9782                	jalr	a5
ffffffffc0201a44:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201a46:	00093503          	ld	a0,0(s2)
ffffffffc0201a4a:	46d1                	li	a3,20
ffffffffc0201a4c:	6605                	lui	a2,0x1
ffffffffc0201a4e:	85e2                	mv	a1,s8
ffffffffc0201a50:	cbfff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc0201a54:	060517e3          	bnez	a0,ffffffffc02022c2 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201a58:	00093503          	ld	a0,0(s2)
ffffffffc0201a5c:	4601                	li	a2,0
ffffffffc0201a5e:	6585                	lui	a1,0x1
ffffffffc0201a60:	dbeff0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc0201a64:	02050fe3          	beqz	a0,ffffffffc02022a2 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0201a68:	611c                	ld	a5,0(a0)
ffffffffc0201a6a:	0107f713          	andi	a4,a5,16
ffffffffc0201a6e:	7c070e63          	beqz	a4,ffffffffc020224a <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0201a72:	8b91                	andi	a5,a5,4
ffffffffc0201a74:	7a078b63          	beqz	a5,ffffffffc020222a <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201a78:	00093503          	ld	a0,0(s2)
ffffffffc0201a7c:	611c                	ld	a5,0(a0)
ffffffffc0201a7e:	8bc1                	andi	a5,a5,16
ffffffffc0201a80:	78078563          	beqz	a5,ffffffffc020220a <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0201a84:	000c2703          	lw	a4,0(s8)
ffffffffc0201a88:	4785                	li	a5,1
ffffffffc0201a8a:	76f71063          	bne	a4,a5,ffffffffc02021ea <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201a8e:	4681                	li	a3,0
ffffffffc0201a90:	6605                	lui	a2,0x1
ffffffffc0201a92:	85d2                	mv	a1,s4
ffffffffc0201a94:	c7bff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc0201a98:	72051963          	bnez	a0,ffffffffc02021ca <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0201a9c:	000a2703          	lw	a4,0(s4)
ffffffffc0201aa0:	4789                	li	a5,2
ffffffffc0201aa2:	70f71463          	bne	a4,a5,ffffffffc02021aa <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201aa6:	000c2783          	lw	a5,0(s8)
ffffffffc0201aaa:	6e079063          	bnez	a5,ffffffffc020218a <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201aae:	00093503          	ld	a0,0(s2)
ffffffffc0201ab2:	4601                	li	a2,0
ffffffffc0201ab4:	6585                	lui	a1,0x1
ffffffffc0201ab6:	d68ff0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc0201aba:	6a050863          	beqz	a0,ffffffffc020216a <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0201abe:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201ac0:	00177793          	andi	a5,a4,1
ffffffffc0201ac4:	4a078563          	beqz	a5,ffffffffc0201f6e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201ac8:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201aca:	00271793          	slli	a5,a4,0x2
ffffffffc0201ace:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ad0:	48d7fd63          	bgeu	a5,a3,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ad4:	000bb683          	ld	a3,0(s7)
ffffffffc0201ad8:	fff80ab7          	lui	s5,0xfff80
ffffffffc0201adc:	97d6                	add	a5,a5,s5
ffffffffc0201ade:	079a                	slli	a5,a5,0x6
ffffffffc0201ae0:	97b6                	add	a5,a5,a3
ffffffffc0201ae2:	66fa1463          	bne	s4,a5,ffffffffc020214a <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201ae6:	8b41                	andi	a4,a4,16
ffffffffc0201ae8:	64071163          	bnez	a4,ffffffffc020212a <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0201aec:	00093503          	ld	a0,0(s2)
ffffffffc0201af0:	4581                	li	a1,0
ffffffffc0201af2:	b81ff0ef          	jal	ra,ffffffffc0201672 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201af6:	000a2c83          	lw	s9,0(s4)
ffffffffc0201afa:	4785                	li	a5,1
ffffffffc0201afc:	60fc9763          	bne	s9,a5,ffffffffc020210a <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0201b00:	000c2783          	lw	a5,0(s8)
ffffffffc0201b04:	5e079363          	bnez	a5,ffffffffc02020ea <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0201b08:	00093503          	ld	a0,0(s2)
ffffffffc0201b0c:	6585                	lui	a1,0x1
ffffffffc0201b0e:	b65ff0ef          	jal	ra,ffffffffc0201672 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201b12:	000a2783          	lw	a5,0(s4)
ffffffffc0201b16:	52079a63          	bnez	a5,ffffffffc020204a <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0201b1a:	000c2783          	lw	a5,0(s8)
ffffffffc0201b1e:	50079663          	bnez	a5,ffffffffc020202a <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201b22:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0201b26:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b28:	000a3683          	ld	a3,0(s4)
ffffffffc0201b2c:	068a                	slli	a3,a3,0x2
ffffffffc0201b2e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0201b30:	42b6fd63          	bgeu	a3,a1,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b34:	000bb503          	ld	a0,0(s7)
ffffffffc0201b38:	96d6                	add	a3,a3,s5
ffffffffc0201b3a:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0201b3c:	00d507b3          	add	a5,a0,a3
ffffffffc0201b40:	439c                	lw	a5,0(a5)
ffffffffc0201b42:	4d979463          	bne	a5,s9,ffffffffc020200a <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0201b46:	8699                	srai	a3,a3,0x6
ffffffffc0201b48:	00080637          	lui	a2,0x80
ffffffffc0201b4c:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0201b4e:	00c69713          	slli	a4,a3,0xc
ffffffffc0201b52:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201b56:	48b77e63          	bgeu	a4,a1,ffffffffc0201ff2 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201b5a:	0009b703          	ld	a4,0(s3)
ffffffffc0201b5e:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b60:	629c                	ld	a5,0(a3)
ffffffffc0201b62:	078a                	slli	a5,a5,0x2
ffffffffc0201b64:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201b66:	40b7f263          	bgeu	a5,a1,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b6a:	8f91                	sub	a5,a5,a2
ffffffffc0201b6c:	079a                	slli	a5,a5,0x6
ffffffffc0201b6e:	953e                	add	a0,a0,a5
ffffffffc0201b70:	100027f3          	csrr	a5,sstatus
ffffffffc0201b74:	8b89                	andi	a5,a5,2
ffffffffc0201b76:	30079963          	bnez	a5,ffffffffc0201e88 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0201b7a:	000b3783          	ld	a5,0(s6)
ffffffffc0201b7e:	4585                	li	a1,1
ffffffffc0201b80:	739c                	ld	a5,32(a5)
ffffffffc0201b82:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b84:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0201b88:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b8a:	078a                	slli	a5,a5,0x2
ffffffffc0201b8c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201b8e:	3ce7fe63          	bgeu	a5,a4,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b92:	000bb503          	ld	a0,0(s7)
ffffffffc0201b96:	fff80737          	lui	a4,0xfff80
ffffffffc0201b9a:	97ba                	add	a5,a5,a4
ffffffffc0201b9c:	079a                	slli	a5,a5,0x6
ffffffffc0201b9e:	953e                	add	a0,a0,a5
ffffffffc0201ba0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ba4:	8b89                	andi	a5,a5,2
ffffffffc0201ba6:	2c079563          	bnez	a5,ffffffffc0201e70 <pmm_init+0x66c>
ffffffffc0201baa:	000b3783          	ld	a5,0(s6)
ffffffffc0201bae:	4585                	li	a1,1
ffffffffc0201bb0:	739c                	ld	a5,32(a5)
ffffffffc0201bb2:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201bb4:	00093783          	ld	a5,0(s2)
ffffffffc0201bb8:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd38520>
    asm volatile("sfence.vma");
ffffffffc0201bbc:	12000073          	sfence.vma
ffffffffc0201bc0:	100027f3          	csrr	a5,sstatus
ffffffffc0201bc4:	8b89                	andi	a5,a5,2
ffffffffc0201bc6:	28079b63          	bnez	a5,ffffffffc0201e5c <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201bca:	000b3783          	ld	a5,0(s6)
ffffffffc0201bce:	779c                	ld	a5,40(a5)
ffffffffc0201bd0:	9782                	jalr	a5
ffffffffc0201bd2:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201bd4:	4b441b63          	bne	s0,s4,ffffffffc020208a <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201bd8:	00005517          	auipc	a0,0x5
ffffffffc0201bdc:	c8850513          	addi	a0,a0,-888 # ffffffffc0206860 <commands+0xce0>
ffffffffc0201be0:	d04fe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc0201be4:	100027f3          	csrr	a5,sstatus
ffffffffc0201be8:	8b89                	andi	a5,a5,2
ffffffffc0201bea:	24079f63          	bnez	a5,ffffffffc0201e48 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201bee:	000b3783          	ld	a5,0(s6)
ffffffffc0201bf2:	779c                	ld	a5,40(a5)
ffffffffc0201bf4:	9782                	jalr	a5
ffffffffc0201bf6:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201bf8:	6098                	ld	a4,0(s1)
ffffffffc0201bfa:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201bfe:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201c00:	00c71793          	slli	a5,a4,0xc
ffffffffc0201c04:	6a05                	lui	s4,0x1
ffffffffc0201c06:	02f47c63          	bgeu	s0,a5,ffffffffc0201c3e <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201c0a:	00c45793          	srli	a5,s0,0xc
ffffffffc0201c0e:	00093503          	ld	a0,0(s2)
ffffffffc0201c12:	2ee7ff63          	bgeu	a5,a4,ffffffffc0201f10 <pmm_init+0x70c>
ffffffffc0201c16:	0009b583          	ld	a1,0(s3)
ffffffffc0201c1a:	4601                	li	a2,0
ffffffffc0201c1c:	95a2                	add	a1,a1,s0
ffffffffc0201c1e:	c00ff0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc0201c22:	32050463          	beqz	a0,ffffffffc0201f4a <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201c26:	611c                	ld	a5,0(a0)
ffffffffc0201c28:	078a                	slli	a5,a5,0x2
ffffffffc0201c2a:	0157f7b3          	and	a5,a5,s5
ffffffffc0201c2e:	2e879e63          	bne	a5,s0,ffffffffc0201f2a <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201c32:	6098                	ld	a4,0(s1)
ffffffffc0201c34:	9452                	add	s0,s0,s4
ffffffffc0201c36:	00c71793          	slli	a5,a4,0xc
ffffffffc0201c3a:	fcf468e3          	bltu	s0,a5,ffffffffc0201c0a <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0201c3e:	00093783          	ld	a5,0(s2)
ffffffffc0201c42:	639c                	ld	a5,0(a5)
ffffffffc0201c44:	42079363          	bnez	a5,ffffffffc020206a <pmm_init+0x866>
ffffffffc0201c48:	100027f3          	csrr	a5,sstatus
ffffffffc0201c4c:	8b89                	andi	a5,a5,2
ffffffffc0201c4e:	24079963          	bnez	a5,ffffffffc0201ea0 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c52:	000b3783          	ld	a5,0(s6)
ffffffffc0201c56:	4505                	li	a0,1
ffffffffc0201c58:	6f9c                	ld	a5,24(a5)
ffffffffc0201c5a:	9782                	jalr	a5
ffffffffc0201c5c:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201c5e:	00093503          	ld	a0,0(s2)
ffffffffc0201c62:	4699                	li	a3,6
ffffffffc0201c64:	10000613          	li	a2,256
ffffffffc0201c68:	85d2                	mv	a1,s4
ffffffffc0201c6a:	aa5ff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc0201c6e:	44051e63          	bnez	a0,ffffffffc02020ca <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0201c72:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f38>
ffffffffc0201c76:	4785                	li	a5,1
ffffffffc0201c78:	42f71963          	bne	a4,a5,ffffffffc02020aa <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201c7c:	00093503          	ld	a0,0(s2)
ffffffffc0201c80:	6405                	lui	s0,0x1
ffffffffc0201c82:	4699                	li	a3,6
ffffffffc0201c84:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e38>
ffffffffc0201c88:	85d2                	mv	a1,s4
ffffffffc0201c8a:	a85ff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc0201c8e:	72051363          	bnez	a0,ffffffffc02023b4 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0201c92:	000a2703          	lw	a4,0(s4)
ffffffffc0201c96:	4789                	li	a5,2
ffffffffc0201c98:	6ef71e63          	bne	a4,a5,ffffffffc0202394 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201c9c:	00005597          	auipc	a1,0x5
ffffffffc0201ca0:	d0c58593          	addi	a1,a1,-756 # ffffffffc02069a8 <commands+0xe28>
ffffffffc0201ca4:	10000513          	li	a0,256
ffffffffc0201ca8:	790030ef          	jal	ra,ffffffffc0205438 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201cac:	10040593          	addi	a1,s0,256
ffffffffc0201cb0:	10000513          	li	a0,256
ffffffffc0201cb4:	796030ef          	jal	ra,ffffffffc020544a <strcmp>
ffffffffc0201cb8:	6a051e63          	bnez	a0,ffffffffc0202374 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0201cbc:	000bb683          	ld	a3,0(s7)
ffffffffc0201cc0:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201cc4:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0201cc6:	40da06b3          	sub	a3,s4,a3
ffffffffc0201cca:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201ccc:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0201cce:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0201cd0:	8031                	srli	s0,s0,0xc
ffffffffc0201cd2:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201cd6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201cd8:	30f77d63          	bgeu	a4,a5,ffffffffc0201ff2 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201cdc:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201ce0:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201ce4:	96be                	add	a3,a3,a5
ffffffffc0201ce6:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201cea:	718030ef          	jal	ra,ffffffffc0205402 <strlen>
ffffffffc0201cee:	66051363          	bnez	a0,ffffffffc0202354 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0201cf2:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0201cf6:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201cf8:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd38520>
ffffffffc0201cfc:	068a                	slli	a3,a3,0x2
ffffffffc0201cfe:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0201d00:	26f6f563          	bgeu	a3,a5,ffffffffc0201f6a <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0201d04:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d06:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201d08:	2ef47563          	bgeu	s0,a5,ffffffffc0201ff2 <pmm_init+0x7ee>
ffffffffc0201d0c:	0009b403          	ld	s0,0(s3)
ffffffffc0201d10:	9436                	add	s0,s0,a3
ffffffffc0201d12:	100027f3          	csrr	a5,sstatus
ffffffffc0201d16:	8b89                	andi	a5,a5,2
ffffffffc0201d18:	1e079163          	bnez	a5,ffffffffc0201efa <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0201d1c:	000b3783          	ld	a5,0(s6)
ffffffffc0201d20:	4585                	li	a1,1
ffffffffc0201d22:	8552                	mv	a0,s4
ffffffffc0201d24:	739c                	ld	a5,32(a5)
ffffffffc0201d26:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201d28:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0201d2a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201d2c:	078a                	slli	a5,a5,0x2
ffffffffc0201d2e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201d30:	22e7fd63          	bgeu	a5,a4,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d34:	000bb503          	ld	a0,0(s7)
ffffffffc0201d38:	fff80737          	lui	a4,0xfff80
ffffffffc0201d3c:	97ba                	add	a5,a5,a4
ffffffffc0201d3e:	079a                	slli	a5,a5,0x6
ffffffffc0201d40:	953e                	add	a0,a0,a5
ffffffffc0201d42:	100027f3          	csrr	a5,sstatus
ffffffffc0201d46:	8b89                	andi	a5,a5,2
ffffffffc0201d48:	18079d63          	bnez	a5,ffffffffc0201ee2 <pmm_init+0x6de>
ffffffffc0201d4c:	000b3783          	ld	a5,0(s6)
ffffffffc0201d50:	4585                	li	a1,1
ffffffffc0201d52:	739c                	ld	a5,32(a5)
ffffffffc0201d54:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201d56:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0201d5a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201d5c:	078a                	slli	a5,a5,0x2
ffffffffc0201d5e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201d60:	20e7f563          	bgeu	a5,a4,ffffffffc0201f6a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d64:	000bb503          	ld	a0,0(s7)
ffffffffc0201d68:	fff80737          	lui	a4,0xfff80
ffffffffc0201d6c:	97ba                	add	a5,a5,a4
ffffffffc0201d6e:	079a                	slli	a5,a5,0x6
ffffffffc0201d70:	953e                	add	a0,a0,a5
ffffffffc0201d72:	100027f3          	csrr	a5,sstatus
ffffffffc0201d76:	8b89                	andi	a5,a5,2
ffffffffc0201d78:	14079963          	bnez	a5,ffffffffc0201eca <pmm_init+0x6c6>
ffffffffc0201d7c:	000b3783          	ld	a5,0(s6)
ffffffffc0201d80:	4585                	li	a1,1
ffffffffc0201d82:	739c                	ld	a5,32(a5)
ffffffffc0201d84:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201d86:	00093783          	ld	a5,0(s2)
ffffffffc0201d8a:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0201d8e:	12000073          	sfence.vma
ffffffffc0201d92:	100027f3          	csrr	a5,sstatus
ffffffffc0201d96:	8b89                	andi	a5,a5,2
ffffffffc0201d98:	10079f63          	bnez	a5,ffffffffc0201eb6 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d9c:	000b3783          	ld	a5,0(s6)
ffffffffc0201da0:	779c                	ld	a5,40(a5)
ffffffffc0201da2:	9782                	jalr	a5
ffffffffc0201da4:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201da6:	4c8c1e63          	bne	s8,s0,ffffffffc0202282 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201daa:	00005517          	auipc	a0,0x5
ffffffffc0201dae:	c7650513          	addi	a0,a0,-906 # ffffffffc0206a20 <commands+0xea0>
ffffffffc0201db2:	b32fe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
}
ffffffffc0201db6:	7406                	ld	s0,96(sp)
ffffffffc0201db8:	70a6                	ld	ra,104(sp)
ffffffffc0201dba:	64e6                	ld	s1,88(sp)
ffffffffc0201dbc:	6946                	ld	s2,80(sp)
ffffffffc0201dbe:	69a6                	ld	s3,72(sp)
ffffffffc0201dc0:	6a06                	ld	s4,64(sp)
ffffffffc0201dc2:	7ae2                	ld	s5,56(sp)
ffffffffc0201dc4:	7b42                	ld	s6,48(sp)
ffffffffc0201dc6:	7ba2                	ld	s7,40(sp)
ffffffffc0201dc8:	7c02                	ld	s8,32(sp)
ffffffffc0201dca:	6ce2                	ld	s9,24(sp)
ffffffffc0201dcc:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0201dce:	2d40106f          	j	ffffffffc02030a2 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0201dd2:	c80007b7          	lui	a5,0xc8000
ffffffffc0201dd6:	bc7d                	j	ffffffffc0201894 <pmm_init+0x90>
        intr_disable();
ffffffffc0201dd8:	bddfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ddc:	000b3783          	ld	a5,0(s6)
ffffffffc0201de0:	4505                	li	a0,1
ffffffffc0201de2:	6f9c                	ld	a5,24(a5)
ffffffffc0201de4:	9782                	jalr	a5
ffffffffc0201de6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201de8:	bc7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201dec:	b9a9                	j	ffffffffc0201a46 <pmm_init+0x242>
        intr_disable();
ffffffffc0201dee:	bc7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0201df2:	000b3783          	ld	a5,0(s6)
ffffffffc0201df6:	4505                	li	a0,1
ffffffffc0201df8:	6f9c                	ld	a5,24(a5)
ffffffffc0201dfa:	9782                	jalr	a5
ffffffffc0201dfc:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201dfe:	bb1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e02:	b645                	j	ffffffffc02019a2 <pmm_init+0x19e>
        intr_disable();
ffffffffc0201e04:	bb1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e08:	000b3783          	ld	a5,0(s6)
ffffffffc0201e0c:	779c                	ld	a5,40(a5)
ffffffffc0201e0e:	9782                	jalr	a5
ffffffffc0201e10:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e12:	b9dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e16:	b6b9                	j	ffffffffc0201964 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201e18:	6705                	lui	a4,0x1
ffffffffc0201e1a:	177d                	addi	a4,a4,-1
ffffffffc0201e1c:	96ba                	add	a3,a3,a4
ffffffffc0201e1e:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0201e20:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201e24:	14a77363          	bgeu	a4,a0,ffffffffc0201f6a <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0201e28:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0201e2c:	fff80537          	lui	a0,0xfff80
ffffffffc0201e30:	972a                	add	a4,a4,a0
ffffffffc0201e32:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201e34:	8c1d                	sub	s0,s0,a5
ffffffffc0201e36:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0201e3a:	00c45593          	srli	a1,s0,0xc
ffffffffc0201e3e:	9532                	add	a0,a0,a2
ffffffffc0201e40:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201e42:	0009b583          	ld	a1,0(s3)
}
ffffffffc0201e46:	b4c1                	j	ffffffffc0201906 <pmm_init+0x102>
        intr_disable();
ffffffffc0201e48:	b6dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e4c:	000b3783          	ld	a5,0(s6)
ffffffffc0201e50:	779c                	ld	a5,40(a5)
ffffffffc0201e52:	9782                	jalr	a5
ffffffffc0201e54:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201e56:	b59fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e5a:	bb79                	j	ffffffffc0201bf8 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0201e5c:	b59fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0201e60:	000b3783          	ld	a5,0(s6)
ffffffffc0201e64:	779c                	ld	a5,40(a5)
ffffffffc0201e66:	9782                	jalr	a5
ffffffffc0201e68:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201e6a:	b45fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e6e:	b39d                	j	ffffffffc0201bd4 <pmm_init+0x3d0>
ffffffffc0201e70:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201e72:	b43fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e76:	000b3783          	ld	a5,0(s6)
ffffffffc0201e7a:	6522                	ld	a0,8(sp)
ffffffffc0201e7c:	4585                	li	a1,1
ffffffffc0201e7e:	739c                	ld	a5,32(a5)
ffffffffc0201e80:	9782                	jalr	a5
        intr_enable();
ffffffffc0201e82:	b2dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e86:	b33d                	j	ffffffffc0201bb4 <pmm_init+0x3b0>
ffffffffc0201e88:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201e8a:	b2bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0201e8e:	000b3783          	ld	a5,0(s6)
ffffffffc0201e92:	6522                	ld	a0,8(sp)
ffffffffc0201e94:	4585                	li	a1,1
ffffffffc0201e96:	739c                	ld	a5,32(a5)
ffffffffc0201e98:	9782                	jalr	a5
        intr_enable();
ffffffffc0201e9a:	b15fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e9e:	b1dd                	j	ffffffffc0201b84 <pmm_init+0x380>
        intr_disable();
ffffffffc0201ea0:	b15fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ea4:	000b3783          	ld	a5,0(s6)
ffffffffc0201ea8:	4505                	li	a0,1
ffffffffc0201eaa:	6f9c                	ld	a5,24(a5)
ffffffffc0201eac:	9782                	jalr	a5
ffffffffc0201eae:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201eb0:	afffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201eb4:	b36d                	j	ffffffffc0201c5e <pmm_init+0x45a>
        intr_disable();
ffffffffc0201eb6:	afffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201eba:	000b3783          	ld	a5,0(s6)
ffffffffc0201ebe:	779c                	ld	a5,40(a5)
ffffffffc0201ec0:	9782                	jalr	a5
ffffffffc0201ec2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ec4:	aebfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ec8:	bdf9                	j	ffffffffc0201da6 <pmm_init+0x5a2>
ffffffffc0201eca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201ecc:	ae9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ed0:	000b3783          	ld	a5,0(s6)
ffffffffc0201ed4:	6522                	ld	a0,8(sp)
ffffffffc0201ed6:	4585                	li	a1,1
ffffffffc0201ed8:	739c                	ld	a5,32(a5)
ffffffffc0201eda:	9782                	jalr	a5
        intr_enable();
ffffffffc0201edc:	ad3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ee0:	b55d                	j	ffffffffc0201d86 <pmm_init+0x582>
ffffffffc0201ee2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201ee4:	ad1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0201ee8:	000b3783          	ld	a5,0(s6)
ffffffffc0201eec:	6522                	ld	a0,8(sp)
ffffffffc0201eee:	4585                	li	a1,1
ffffffffc0201ef0:	739c                	ld	a5,32(a5)
ffffffffc0201ef2:	9782                	jalr	a5
        intr_enable();
ffffffffc0201ef4:	abbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ef8:	bdb9                	j	ffffffffc0201d56 <pmm_init+0x552>
        intr_disable();
ffffffffc0201efa:	abbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0201efe:	000b3783          	ld	a5,0(s6)
ffffffffc0201f02:	4585                	li	a1,1
ffffffffc0201f04:	8552                	mv	a0,s4
ffffffffc0201f06:	739c                	ld	a5,32(a5)
ffffffffc0201f08:	9782                	jalr	a5
        intr_enable();
ffffffffc0201f0a:	aa5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201f0e:	bd29                	j	ffffffffc0201d28 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f10:	86a2                	mv	a3,s0
ffffffffc0201f12:	00004617          	auipc	a2,0x4
ffffffffc0201f16:	4d660613          	addi	a2,a2,1238 # ffffffffc02063e8 <commands+0x868>
ffffffffc0201f1a:	25000593          	li	a1,592
ffffffffc0201f1e:	00004517          	auipc	a0,0x4
ffffffffc0201f22:	4f250513          	addi	a0,a0,1266 # ffffffffc0206410 <commands+0x890>
ffffffffc0201f26:	afcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f2a:	00005697          	auipc	a3,0x5
ffffffffc0201f2e:	99668693          	addi	a3,a3,-1642 # ffffffffc02068c0 <commands+0xd40>
ffffffffc0201f32:	00004617          	auipc	a2,0x4
ffffffffc0201f36:	51e60613          	addi	a2,a2,1310 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201f3a:	25100593          	li	a1,593
ffffffffc0201f3e:	00004517          	auipc	a0,0x4
ffffffffc0201f42:	4d250513          	addi	a0,a0,1234 # ffffffffc0206410 <commands+0x890>
ffffffffc0201f46:	adcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f4a:	00005697          	auipc	a3,0x5
ffffffffc0201f4e:	93668693          	addi	a3,a3,-1738 # ffffffffc0206880 <commands+0xd00>
ffffffffc0201f52:	00004617          	auipc	a2,0x4
ffffffffc0201f56:	4fe60613          	addi	a2,a2,1278 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201f5a:	25000593          	li	a1,592
ffffffffc0201f5e:	00004517          	auipc	a0,0x4
ffffffffc0201f62:	4b250513          	addi	a0,a0,1202 # ffffffffc0206410 <commands+0x890>
ffffffffc0201f66:	abcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
ffffffffc0201f6a:	fc5fe0ef          	jal	ra,ffffffffc0200f2e <pa2page.part.0>
ffffffffc0201f6e:	fddfe0ef          	jal	ra,ffffffffc0200f4a <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201f72:	00004697          	auipc	a3,0x4
ffffffffc0201f76:	70668693          	addi	a3,a3,1798 # ffffffffc0206678 <commands+0xaf8>
ffffffffc0201f7a:	00004617          	auipc	a2,0x4
ffffffffc0201f7e:	4d660613          	addi	a2,a2,1238 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201f82:	22000593          	li	a1,544
ffffffffc0201f86:	00004517          	auipc	a0,0x4
ffffffffc0201f8a:	48a50513          	addi	a0,a0,1162 # ffffffffc0206410 <commands+0x890>
ffffffffc0201f8e:	a94fe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201f92:	00004697          	auipc	a3,0x4
ffffffffc0201f96:	62668693          	addi	a3,a3,1574 # ffffffffc02065b8 <commands+0xa38>
ffffffffc0201f9a:	00004617          	auipc	a2,0x4
ffffffffc0201f9e:	4b660613          	addi	a2,a2,1206 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201fa2:	21300593          	li	a1,531
ffffffffc0201fa6:	00004517          	auipc	a0,0x4
ffffffffc0201faa:	46a50513          	addi	a0,a0,1130 # ffffffffc0206410 <commands+0x890>
ffffffffc0201fae:	a74fe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201fb2:	00004697          	auipc	a3,0x4
ffffffffc0201fb6:	5c668693          	addi	a3,a3,1478 # ffffffffc0206578 <commands+0x9f8>
ffffffffc0201fba:	00004617          	auipc	a2,0x4
ffffffffc0201fbe:	49660613          	addi	a2,a2,1174 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201fc2:	21200593          	li	a1,530
ffffffffc0201fc6:	00004517          	auipc	a0,0x4
ffffffffc0201fca:	44a50513          	addi	a0,a0,1098 # ffffffffc0206410 <commands+0x890>
ffffffffc0201fce:	a54fe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201fd2:	00004697          	auipc	a3,0x4
ffffffffc0201fd6:	58668693          	addi	a3,a3,1414 # ffffffffc0206558 <commands+0x9d8>
ffffffffc0201fda:	00004617          	auipc	a2,0x4
ffffffffc0201fde:	47660613          	addi	a2,a2,1142 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0201fe2:	21100593          	li	a1,529
ffffffffc0201fe6:	00004517          	auipc	a0,0x4
ffffffffc0201fea:	42a50513          	addi	a0,a0,1066 # ffffffffc0206410 <commands+0x890>
ffffffffc0201fee:	a34fe0ef          	jal	ra,ffffffffc0200222 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201ff2:	00004617          	auipc	a2,0x4
ffffffffc0201ff6:	3f660613          	addi	a2,a2,1014 # ffffffffc02063e8 <commands+0x868>
ffffffffc0201ffa:	07100593          	li	a1,113
ffffffffc0201ffe:	00004517          	auipc	a0,0x4
ffffffffc0202002:	3b250513          	addi	a0,a0,946 # ffffffffc02063b0 <commands+0x830>
ffffffffc0202006:	a1cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020200a:	00004697          	auipc	a3,0x4
ffffffffc020200e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0206808 <commands+0xc88>
ffffffffc0202012:	00004617          	auipc	a2,0x4
ffffffffc0202016:	43e60613          	addi	a2,a2,1086 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020201a:	23900593          	li	a1,569
ffffffffc020201e:	00004517          	auipc	a0,0x4
ffffffffc0202022:	3f250513          	addi	a0,a0,1010 # ffffffffc0206410 <commands+0x890>
ffffffffc0202026:	9fcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020202a:	00004697          	auipc	a3,0x4
ffffffffc020202e:	79668693          	addi	a3,a3,1942 # ffffffffc02067c0 <commands+0xc40>
ffffffffc0202032:	00004617          	auipc	a2,0x4
ffffffffc0202036:	41e60613          	addi	a2,a2,1054 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020203a:	23700593          	li	a1,567
ffffffffc020203e:	00004517          	auipc	a0,0x4
ffffffffc0202042:	3d250513          	addi	a0,a0,978 # ffffffffc0206410 <commands+0x890>
ffffffffc0202046:	9dcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020204a:	00004697          	auipc	a3,0x4
ffffffffc020204e:	7a668693          	addi	a3,a3,1958 # ffffffffc02067f0 <commands+0xc70>
ffffffffc0202052:	00004617          	auipc	a2,0x4
ffffffffc0202056:	3fe60613          	addi	a2,a2,1022 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020205a:	23600593          	li	a1,566
ffffffffc020205e:	00004517          	auipc	a0,0x4
ffffffffc0202062:	3b250513          	addi	a0,a0,946 # ffffffffc0206410 <commands+0x890>
ffffffffc0202066:	9bcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020206a:	00005697          	auipc	a3,0x5
ffffffffc020206e:	86e68693          	addi	a3,a3,-1938 # ffffffffc02068d8 <commands+0xd58>
ffffffffc0202072:	00004617          	auipc	a2,0x4
ffffffffc0202076:	3de60613          	addi	a2,a2,990 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020207a:	25400593          	li	a1,596
ffffffffc020207e:	00004517          	auipc	a0,0x4
ffffffffc0202082:	39250513          	addi	a0,a0,914 # ffffffffc0206410 <commands+0x890>
ffffffffc0202086:	99cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020208a:	00004697          	auipc	a3,0x4
ffffffffc020208e:	7ae68693          	addi	a3,a3,1966 # ffffffffc0206838 <commands+0xcb8>
ffffffffc0202092:	00004617          	auipc	a2,0x4
ffffffffc0202096:	3be60613          	addi	a2,a2,958 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020209a:	24100593          	li	a1,577
ffffffffc020209e:	00004517          	auipc	a0,0x4
ffffffffc02020a2:	37250513          	addi	a0,a0,882 # ffffffffc0206410 <commands+0x890>
ffffffffc02020a6:	97cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02020aa:	00005697          	auipc	a3,0x5
ffffffffc02020ae:	88668693          	addi	a3,a3,-1914 # ffffffffc0206930 <commands+0xdb0>
ffffffffc02020b2:	00004617          	auipc	a2,0x4
ffffffffc02020b6:	39e60613          	addi	a2,a2,926 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02020ba:	25900593          	li	a1,601
ffffffffc02020be:	00004517          	auipc	a0,0x4
ffffffffc02020c2:	35250513          	addi	a0,a0,850 # ffffffffc0206410 <commands+0x890>
ffffffffc02020c6:	95cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02020ca:	00005697          	auipc	a3,0x5
ffffffffc02020ce:	82668693          	addi	a3,a3,-2010 # ffffffffc02068f0 <commands+0xd70>
ffffffffc02020d2:	00004617          	auipc	a2,0x4
ffffffffc02020d6:	37e60613          	addi	a2,a2,894 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02020da:	25800593          	li	a1,600
ffffffffc02020de:	00004517          	auipc	a0,0x4
ffffffffc02020e2:	33250513          	addi	a0,a0,818 # ffffffffc0206410 <commands+0x890>
ffffffffc02020e6:	93cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02020ea:	00004697          	auipc	a3,0x4
ffffffffc02020ee:	6d668693          	addi	a3,a3,1750 # ffffffffc02067c0 <commands+0xc40>
ffffffffc02020f2:	00004617          	auipc	a2,0x4
ffffffffc02020f6:	35e60613          	addi	a2,a2,862 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02020fa:	23300593          	li	a1,563
ffffffffc02020fe:	00004517          	auipc	a0,0x4
ffffffffc0202102:	31250513          	addi	a0,a0,786 # ffffffffc0206410 <commands+0x890>
ffffffffc0202106:	91cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020210a:	00004697          	auipc	a3,0x4
ffffffffc020210e:	55668693          	addi	a3,a3,1366 # ffffffffc0206660 <commands+0xae0>
ffffffffc0202112:	00004617          	auipc	a2,0x4
ffffffffc0202116:	33e60613          	addi	a2,a2,830 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020211a:	23200593          	li	a1,562
ffffffffc020211e:	00004517          	auipc	a0,0x4
ffffffffc0202122:	2f250513          	addi	a0,a0,754 # ffffffffc0206410 <commands+0x890>
ffffffffc0202126:	8fcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020212a:	00004697          	auipc	a3,0x4
ffffffffc020212e:	6ae68693          	addi	a3,a3,1710 # ffffffffc02067d8 <commands+0xc58>
ffffffffc0202132:	00004617          	auipc	a2,0x4
ffffffffc0202136:	31e60613          	addi	a2,a2,798 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020213a:	22f00593          	li	a1,559
ffffffffc020213e:	00004517          	auipc	a0,0x4
ffffffffc0202142:	2d250513          	addi	a0,a0,722 # ffffffffc0206410 <commands+0x890>
ffffffffc0202146:	8dcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020214a:	00004697          	auipc	a3,0x4
ffffffffc020214e:	4fe68693          	addi	a3,a3,1278 # ffffffffc0206648 <commands+0xac8>
ffffffffc0202152:	00004617          	auipc	a2,0x4
ffffffffc0202156:	2fe60613          	addi	a2,a2,766 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020215a:	22e00593          	li	a1,558
ffffffffc020215e:	00004517          	auipc	a0,0x4
ffffffffc0202162:	2b250513          	addi	a0,a0,690 # ffffffffc0206410 <commands+0x890>
ffffffffc0202166:	8bcfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020216a:	00004697          	auipc	a3,0x4
ffffffffc020216e:	57e68693          	addi	a3,a3,1406 # ffffffffc02066e8 <commands+0xb68>
ffffffffc0202172:	00004617          	auipc	a2,0x4
ffffffffc0202176:	2de60613          	addi	a2,a2,734 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020217a:	22d00593          	li	a1,557
ffffffffc020217e:	00004517          	auipc	a0,0x4
ffffffffc0202182:	29250513          	addi	a0,a0,658 # ffffffffc0206410 <commands+0x890>
ffffffffc0202186:	89cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020218a:	00004697          	auipc	a3,0x4
ffffffffc020218e:	63668693          	addi	a3,a3,1590 # ffffffffc02067c0 <commands+0xc40>
ffffffffc0202192:	00004617          	auipc	a2,0x4
ffffffffc0202196:	2be60613          	addi	a2,a2,702 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020219a:	22c00593          	li	a1,556
ffffffffc020219e:	00004517          	auipc	a0,0x4
ffffffffc02021a2:	27250513          	addi	a0,a0,626 # ffffffffc0206410 <commands+0x890>
ffffffffc02021a6:	87cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02021aa:	00004697          	auipc	a3,0x4
ffffffffc02021ae:	5fe68693          	addi	a3,a3,1534 # ffffffffc02067a8 <commands+0xc28>
ffffffffc02021b2:	00004617          	auipc	a2,0x4
ffffffffc02021b6:	29e60613          	addi	a2,a2,670 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02021ba:	22b00593          	li	a1,555
ffffffffc02021be:	00004517          	auipc	a0,0x4
ffffffffc02021c2:	25250513          	addi	a0,a0,594 # ffffffffc0206410 <commands+0x890>
ffffffffc02021c6:	85cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02021ca:	00004697          	auipc	a3,0x4
ffffffffc02021ce:	5ae68693          	addi	a3,a3,1454 # ffffffffc0206778 <commands+0xbf8>
ffffffffc02021d2:	00004617          	auipc	a2,0x4
ffffffffc02021d6:	27e60613          	addi	a2,a2,638 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02021da:	22a00593          	li	a1,554
ffffffffc02021de:	00004517          	auipc	a0,0x4
ffffffffc02021e2:	23250513          	addi	a0,a0,562 # ffffffffc0206410 <commands+0x890>
ffffffffc02021e6:	83cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02021ea:	00004697          	auipc	a3,0x4
ffffffffc02021ee:	57668693          	addi	a3,a3,1398 # ffffffffc0206760 <commands+0xbe0>
ffffffffc02021f2:	00004617          	auipc	a2,0x4
ffffffffc02021f6:	25e60613          	addi	a2,a2,606 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02021fa:	22800593          	li	a1,552
ffffffffc02021fe:	00004517          	auipc	a0,0x4
ffffffffc0202202:	21250513          	addi	a0,a0,530 # ffffffffc0206410 <commands+0x890>
ffffffffc0202206:	81cfe0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020220a:	00004697          	auipc	a3,0x4
ffffffffc020220e:	53668693          	addi	a3,a3,1334 # ffffffffc0206740 <commands+0xbc0>
ffffffffc0202212:	00004617          	auipc	a2,0x4
ffffffffc0202216:	23e60613          	addi	a2,a2,574 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020221a:	22700593          	li	a1,551
ffffffffc020221e:	00004517          	auipc	a0,0x4
ffffffffc0202222:	1f250513          	addi	a0,a0,498 # ffffffffc0206410 <commands+0x890>
ffffffffc0202226:	ffdfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020222a:	00004697          	auipc	a3,0x4
ffffffffc020222e:	50668693          	addi	a3,a3,1286 # ffffffffc0206730 <commands+0xbb0>
ffffffffc0202232:	00004617          	auipc	a2,0x4
ffffffffc0202236:	21e60613          	addi	a2,a2,542 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020223a:	22600593          	li	a1,550
ffffffffc020223e:	00004517          	auipc	a0,0x4
ffffffffc0202242:	1d250513          	addi	a0,a0,466 # ffffffffc0206410 <commands+0x890>
ffffffffc0202246:	fddfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020224a:	00004697          	auipc	a3,0x4
ffffffffc020224e:	4d668693          	addi	a3,a3,1238 # ffffffffc0206720 <commands+0xba0>
ffffffffc0202252:	00004617          	auipc	a2,0x4
ffffffffc0202256:	1fe60613          	addi	a2,a2,510 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020225a:	22500593          	li	a1,549
ffffffffc020225e:	00004517          	auipc	a0,0x4
ffffffffc0202262:	1b250513          	addi	a0,a0,434 # ffffffffc0206410 <commands+0x890>
ffffffffc0202266:	fbdfd0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("DTB memory info not available");
ffffffffc020226a:	00004617          	auipc	a2,0x4
ffffffffc020226e:	22e60613          	addi	a2,a2,558 # ffffffffc0206498 <commands+0x918>
ffffffffc0202272:	06500593          	li	a1,101
ffffffffc0202276:	00004517          	auipc	a0,0x4
ffffffffc020227a:	19a50513          	addi	a0,a0,410 # ffffffffc0206410 <commands+0x890>
ffffffffc020227e:	fa5fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202282:	00004697          	auipc	a3,0x4
ffffffffc0202286:	5b668693          	addi	a3,a3,1462 # ffffffffc0206838 <commands+0xcb8>
ffffffffc020228a:	00004617          	auipc	a2,0x4
ffffffffc020228e:	1c660613          	addi	a2,a2,454 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202292:	26b00593          	li	a1,619
ffffffffc0202296:	00004517          	auipc	a0,0x4
ffffffffc020229a:	17a50513          	addi	a0,a0,378 # ffffffffc0206410 <commands+0x890>
ffffffffc020229e:	f85fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02022a2:	00004697          	auipc	a3,0x4
ffffffffc02022a6:	44668693          	addi	a3,a3,1094 # ffffffffc02066e8 <commands+0xb68>
ffffffffc02022aa:	00004617          	auipc	a2,0x4
ffffffffc02022ae:	1a660613          	addi	a2,a2,422 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02022b2:	22400593          	li	a1,548
ffffffffc02022b6:	00004517          	auipc	a0,0x4
ffffffffc02022ba:	15a50513          	addi	a0,a0,346 # ffffffffc0206410 <commands+0x890>
ffffffffc02022be:	f65fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02022c2:	00004697          	auipc	a3,0x4
ffffffffc02022c6:	3e668693          	addi	a3,a3,998 # ffffffffc02066a8 <commands+0xb28>
ffffffffc02022ca:	00004617          	auipc	a2,0x4
ffffffffc02022ce:	18660613          	addi	a2,a2,390 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02022d2:	22300593          	li	a1,547
ffffffffc02022d6:	00004517          	auipc	a0,0x4
ffffffffc02022da:	13a50513          	addi	a0,a0,314 # ffffffffc0206410 <commands+0x890>
ffffffffc02022de:	f45fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022e2:	86d6                	mv	a3,s5
ffffffffc02022e4:	00004617          	auipc	a2,0x4
ffffffffc02022e8:	10460613          	addi	a2,a2,260 # ffffffffc02063e8 <commands+0x868>
ffffffffc02022ec:	21f00593          	li	a1,543
ffffffffc02022f0:	00004517          	auipc	a0,0x4
ffffffffc02022f4:	12050513          	addi	a0,a0,288 # ffffffffc0206410 <commands+0x890>
ffffffffc02022f8:	f2bfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02022fc:	00004617          	auipc	a2,0x4
ffffffffc0202300:	0ec60613          	addi	a2,a2,236 # ffffffffc02063e8 <commands+0x868>
ffffffffc0202304:	21e00593          	li	a1,542
ffffffffc0202308:	00004517          	auipc	a0,0x4
ffffffffc020230c:	10850513          	addi	a0,a0,264 # ffffffffc0206410 <commands+0x890>
ffffffffc0202310:	f13fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202314:	00004697          	auipc	a3,0x4
ffffffffc0202318:	34c68693          	addi	a3,a3,844 # ffffffffc0206660 <commands+0xae0>
ffffffffc020231c:	00004617          	auipc	a2,0x4
ffffffffc0202320:	13460613          	addi	a2,a2,308 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202324:	21c00593          	li	a1,540
ffffffffc0202328:	00004517          	auipc	a0,0x4
ffffffffc020232c:	0e850513          	addi	a0,a0,232 # ffffffffc0206410 <commands+0x890>
ffffffffc0202330:	ef3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202334:	00004697          	auipc	a3,0x4
ffffffffc0202338:	31468693          	addi	a3,a3,788 # ffffffffc0206648 <commands+0xac8>
ffffffffc020233c:	00004617          	auipc	a2,0x4
ffffffffc0202340:	11460613          	addi	a2,a2,276 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202344:	21b00593          	li	a1,539
ffffffffc0202348:	00004517          	auipc	a0,0x4
ffffffffc020234c:	0c850513          	addi	a0,a0,200 # ffffffffc0206410 <commands+0x890>
ffffffffc0202350:	ed3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202354:	00004697          	auipc	a3,0x4
ffffffffc0202358:	6a468693          	addi	a3,a3,1700 # ffffffffc02069f8 <commands+0xe78>
ffffffffc020235c:	00004617          	auipc	a2,0x4
ffffffffc0202360:	0f460613          	addi	a2,a2,244 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202364:	26200593          	li	a1,610
ffffffffc0202368:	00004517          	auipc	a0,0x4
ffffffffc020236c:	0a850513          	addi	a0,a0,168 # ffffffffc0206410 <commands+0x890>
ffffffffc0202370:	eb3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202374:	00004697          	auipc	a3,0x4
ffffffffc0202378:	64c68693          	addi	a3,a3,1612 # ffffffffc02069c0 <commands+0xe40>
ffffffffc020237c:	00004617          	auipc	a2,0x4
ffffffffc0202380:	0d460613          	addi	a2,a2,212 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202384:	25f00593          	li	a1,607
ffffffffc0202388:	00004517          	auipc	a0,0x4
ffffffffc020238c:	08850513          	addi	a0,a0,136 # ffffffffc0206410 <commands+0x890>
ffffffffc0202390:	e93fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202394:	00004697          	auipc	a3,0x4
ffffffffc0202398:	5fc68693          	addi	a3,a3,1532 # ffffffffc0206990 <commands+0xe10>
ffffffffc020239c:	00004617          	auipc	a2,0x4
ffffffffc02023a0:	0b460613          	addi	a2,a2,180 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02023a4:	25b00593          	li	a1,603
ffffffffc02023a8:	00004517          	auipc	a0,0x4
ffffffffc02023ac:	06850513          	addi	a0,a0,104 # ffffffffc0206410 <commands+0x890>
ffffffffc02023b0:	e73fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02023b4:	00004697          	auipc	a3,0x4
ffffffffc02023b8:	59468693          	addi	a3,a3,1428 # ffffffffc0206948 <commands+0xdc8>
ffffffffc02023bc:	00004617          	auipc	a2,0x4
ffffffffc02023c0:	09460613          	addi	a2,a2,148 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02023c4:	25a00593          	li	a1,602
ffffffffc02023c8:	00004517          	auipc	a0,0x4
ffffffffc02023cc:	04850513          	addi	a0,a0,72 # ffffffffc0206410 <commands+0x890>
ffffffffc02023d0:	e53fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02023d4:	00004617          	auipc	a2,0x4
ffffffffc02023d8:	12460613          	addi	a2,a2,292 # ffffffffc02064f8 <commands+0x978>
ffffffffc02023dc:	0c900593          	li	a1,201
ffffffffc02023e0:	00004517          	auipc	a0,0x4
ffffffffc02023e4:	03050513          	addi	a0,a0,48 # ffffffffc0206410 <commands+0x890>
ffffffffc02023e8:	e3bfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02023ec:	00004617          	auipc	a2,0x4
ffffffffc02023f0:	10c60613          	addi	a2,a2,268 # ffffffffc02064f8 <commands+0x978>
ffffffffc02023f4:	08100593          	li	a1,129
ffffffffc02023f8:	00004517          	auipc	a0,0x4
ffffffffc02023fc:	01850513          	addi	a0,a0,24 # ffffffffc0206410 <commands+0x890>
ffffffffc0202400:	e23fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202404:	00004697          	auipc	a3,0x4
ffffffffc0202408:	21468693          	addi	a3,a3,532 # ffffffffc0206618 <commands+0xa98>
ffffffffc020240c:	00004617          	auipc	a2,0x4
ffffffffc0202410:	04460613          	addi	a2,a2,68 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202414:	21a00593          	li	a1,538
ffffffffc0202418:	00004517          	auipc	a0,0x4
ffffffffc020241c:	ff850513          	addi	a0,a0,-8 # ffffffffc0206410 <commands+0x890>
ffffffffc0202420:	e03fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202424:	00004697          	auipc	a3,0x4
ffffffffc0202428:	1c468693          	addi	a3,a3,452 # ffffffffc02065e8 <commands+0xa68>
ffffffffc020242c:	00004617          	auipc	a2,0x4
ffffffffc0202430:	02460613          	addi	a2,a2,36 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202434:	21700593          	li	a1,535
ffffffffc0202438:	00004517          	auipc	a0,0x4
ffffffffc020243c:	fd850513          	addi	a0,a0,-40 # ffffffffc0206410 <commands+0x890>
ffffffffc0202440:	de3fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202444 <copy_range>:
{
ffffffffc0202444:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202446:	00d667b3          	or	a5,a2,a3
{
ffffffffc020244a:	f486                	sd	ra,104(sp)
ffffffffc020244c:	f0a2                	sd	s0,96(sp)
ffffffffc020244e:	eca6                	sd	s1,88(sp)
ffffffffc0202450:	e8ca                	sd	s2,80(sp)
ffffffffc0202452:	e4ce                	sd	s3,72(sp)
ffffffffc0202454:	e0d2                	sd	s4,64(sp)
ffffffffc0202456:	fc56                	sd	s5,56(sp)
ffffffffc0202458:	f85a                	sd	s6,48(sp)
ffffffffc020245a:	f45e                	sd	s7,40(sp)
ffffffffc020245c:	f062                	sd	s8,32(sp)
ffffffffc020245e:	ec66                	sd	s9,24(sp)
ffffffffc0202460:	e86a                	sd	s10,16(sp)
ffffffffc0202462:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202464:	17d2                	slli	a5,a5,0x34
ffffffffc0202466:	20079f63          	bnez	a5,ffffffffc0202684 <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc020246a:	002007b7          	lui	a5,0x200
ffffffffc020246e:	8432                	mv	s0,a2
ffffffffc0202470:	1af66263          	bltu	a2,a5,ffffffffc0202614 <copy_range+0x1d0>
ffffffffc0202474:	8936                	mv	s2,a3
ffffffffc0202476:	18d67f63          	bgeu	a2,a3,ffffffffc0202614 <copy_range+0x1d0>
ffffffffc020247a:	4785                	li	a5,1
ffffffffc020247c:	07fe                	slli	a5,a5,0x1f
ffffffffc020247e:	18d7eb63          	bltu	a5,a3,ffffffffc0202614 <copy_range+0x1d0>
ffffffffc0202482:	5b7d                	li	s6,-1
ffffffffc0202484:	8aaa                	mv	s5,a0
ffffffffc0202486:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0202488:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020248a:	000c4c17          	auipc	s8,0xc4
ffffffffc020248e:	5fec0c13          	addi	s8,s8,1534 # ffffffffc02c6a88 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202492:	000c4b97          	auipc	s7,0xc4
ffffffffc0202496:	5feb8b93          	addi	s7,s7,1534 # ffffffffc02c6a90 <pages>
    return KADDR(page2pa(page));
ffffffffc020249a:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc020249e:	000c4c97          	auipc	s9,0xc4
ffffffffc02024a2:	5fac8c93          	addi	s9,s9,1530 # ffffffffc02c6a98 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02024a6:	4601                	li	a2,0
ffffffffc02024a8:	85a2                	mv	a1,s0
ffffffffc02024aa:	854e                	mv	a0,s3
ffffffffc02024ac:	b73fe0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc02024b0:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02024b2:	0e050c63          	beqz	a0,ffffffffc02025aa <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02024b6:	611c                	ld	a5,0(a0)
ffffffffc02024b8:	8b85                	andi	a5,a5,1
ffffffffc02024ba:	e785                	bnez	a5,ffffffffc02024e2 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02024bc:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02024be:	ff2464e3          	bltu	s0,s2,ffffffffc02024a6 <copy_range+0x62>
    return 0;
ffffffffc02024c2:	4501                	li	a0,0
}
ffffffffc02024c4:	70a6                	ld	ra,104(sp)
ffffffffc02024c6:	7406                	ld	s0,96(sp)
ffffffffc02024c8:	64e6                	ld	s1,88(sp)
ffffffffc02024ca:	6946                	ld	s2,80(sp)
ffffffffc02024cc:	69a6                	ld	s3,72(sp)
ffffffffc02024ce:	6a06                	ld	s4,64(sp)
ffffffffc02024d0:	7ae2                	ld	s5,56(sp)
ffffffffc02024d2:	7b42                	ld	s6,48(sp)
ffffffffc02024d4:	7ba2                	ld	s7,40(sp)
ffffffffc02024d6:	7c02                	ld	s8,32(sp)
ffffffffc02024d8:	6ce2                	ld	s9,24(sp)
ffffffffc02024da:	6d42                	ld	s10,16(sp)
ffffffffc02024dc:	6da2                	ld	s11,8(sp)
ffffffffc02024de:	6165                	addi	sp,sp,112
ffffffffc02024e0:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02024e2:	4605                	li	a2,1
ffffffffc02024e4:	85a2                	mv	a1,s0
ffffffffc02024e6:	8556                	mv	a0,s5
ffffffffc02024e8:	b37fe0ef          	jal	ra,ffffffffc020101e <get_pte>
ffffffffc02024ec:	c56d                	beqz	a0,ffffffffc02025d6 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02024ee:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc02024f0:	0017f713          	andi	a4,a5,1
ffffffffc02024f4:	01f7f493          	andi	s1,a5,31
ffffffffc02024f8:	16070a63          	beqz	a4,ffffffffc020266c <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc02024fc:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202500:	078a                	slli	a5,a5,0x2
ffffffffc0202502:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202506:	14d77763          	bgeu	a4,a3,ffffffffc0202654 <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc020250a:	000bb783          	ld	a5,0(s7)
ffffffffc020250e:	fff806b7          	lui	a3,0xfff80
ffffffffc0202512:	9736                	add	a4,a4,a3
ffffffffc0202514:	071a                	slli	a4,a4,0x6
ffffffffc0202516:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020251a:	10002773          	csrr	a4,sstatus
ffffffffc020251e:	8b09                	andi	a4,a4,2
ffffffffc0202520:	e345                	bnez	a4,ffffffffc02025c0 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202522:	000cb703          	ld	a4,0(s9)
ffffffffc0202526:	4505                	li	a0,1
ffffffffc0202528:	6f18                	ld	a4,24(a4)
ffffffffc020252a:	9702                	jalr	a4
ffffffffc020252c:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc020252e:	0c0d8363          	beqz	s11,ffffffffc02025f4 <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0202532:	100d0163          	beqz	s10,ffffffffc0202634 <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc0202536:	000bb703          	ld	a4,0(s7)
ffffffffc020253a:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc020253e:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0202542:	40ed86b3          	sub	a3,s11,a4
ffffffffc0202546:	8699                	srai	a3,a3,0x6
ffffffffc0202548:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020254a:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc020254e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202550:	08c7f663          	bgeu	a5,a2,ffffffffc02025dc <copy_range+0x198>
    return page - pages + nbase;
ffffffffc0202554:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc0202558:	000c4717          	auipc	a4,0xc4
ffffffffc020255c:	54870713          	addi	a4,a4,1352 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc0202560:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0202562:	8799                	srai	a5,a5,0x6
ffffffffc0202564:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0202566:	0167f733          	and	a4,a5,s6
ffffffffc020256a:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020256e:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202570:	06c77563          	bgeu	a4,a2,ffffffffc02025da <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0202574:	6605                	lui	a2,0x1
ffffffffc0202576:	953e                	add	a0,a0,a5
ffffffffc0202578:	73f020ef          	jal	ra,ffffffffc02054b6 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020257c:	86a6                	mv	a3,s1
ffffffffc020257e:	8622                	mv	a2,s0
ffffffffc0202580:	85ea                	mv	a1,s10
ffffffffc0202582:	8556                	mv	a0,s5
ffffffffc0202584:	98aff0ef          	jal	ra,ffffffffc020170e <page_insert>
            assert(ret == 0);
ffffffffc0202588:	d915                	beqz	a0,ffffffffc02024bc <copy_range+0x78>
ffffffffc020258a:	00004697          	auipc	a3,0x4
ffffffffc020258e:	4d668693          	addi	a3,a3,1238 # ffffffffc0206a60 <commands+0xee0>
ffffffffc0202592:	00004617          	auipc	a2,0x4
ffffffffc0202596:	ebe60613          	addi	a2,a2,-322 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020259a:	1af00593          	li	a1,431
ffffffffc020259e:	00004517          	auipc	a0,0x4
ffffffffc02025a2:	e7250513          	addi	a0,a0,-398 # ffffffffc0206410 <commands+0x890>
ffffffffc02025a6:	c7dfd0ef          	jal	ra,ffffffffc0200222 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02025aa:	00200637          	lui	a2,0x200
ffffffffc02025ae:	9432                	add	s0,s0,a2
ffffffffc02025b0:	ffe00637          	lui	a2,0xffe00
ffffffffc02025b4:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02025b6:	f00406e3          	beqz	s0,ffffffffc02024c2 <copy_range+0x7e>
ffffffffc02025ba:	ef2466e3          	bltu	s0,s2,ffffffffc02024a6 <copy_range+0x62>
ffffffffc02025be:	b711                	j	ffffffffc02024c2 <copy_range+0x7e>
        intr_disable();
ffffffffc02025c0:	bf4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025c4:	000cb703          	ld	a4,0(s9)
ffffffffc02025c8:	4505                	li	a0,1
ffffffffc02025ca:	6f18                	ld	a4,24(a4)
ffffffffc02025cc:	9702                	jalr	a4
ffffffffc02025ce:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02025d0:	bdefe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025d4:	bfa9                	j	ffffffffc020252e <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02025d6:	5571                	li	a0,-4
ffffffffc02025d8:	b5f5                	j	ffffffffc02024c4 <copy_range+0x80>
ffffffffc02025da:	86be                	mv	a3,a5
ffffffffc02025dc:	00004617          	auipc	a2,0x4
ffffffffc02025e0:	e0c60613          	addi	a2,a2,-500 # ffffffffc02063e8 <commands+0x868>
ffffffffc02025e4:	07100593          	li	a1,113
ffffffffc02025e8:	00004517          	auipc	a0,0x4
ffffffffc02025ec:	dc850513          	addi	a0,a0,-568 # ffffffffc02063b0 <commands+0x830>
ffffffffc02025f0:	c33fd0ef          	jal	ra,ffffffffc0200222 <__panic>
            assert(page != NULL);
ffffffffc02025f4:	00004697          	auipc	a3,0x4
ffffffffc02025f8:	44c68693          	addi	a3,a3,1100 # ffffffffc0206a40 <commands+0xec0>
ffffffffc02025fc:	00004617          	auipc	a2,0x4
ffffffffc0202600:	e5460613          	addi	a2,a2,-428 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202604:	19600593          	li	a1,406
ffffffffc0202608:	00004517          	auipc	a0,0x4
ffffffffc020260c:	e0850513          	addi	a0,a0,-504 # ffffffffc0206410 <commands+0x890>
ffffffffc0202610:	c13fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202614:	00004697          	auipc	a3,0x4
ffffffffc0202618:	e5468693          	addi	a3,a3,-428 # ffffffffc0206468 <commands+0x8e8>
ffffffffc020261c:	00004617          	auipc	a2,0x4
ffffffffc0202620:	e3460613          	addi	a2,a2,-460 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202624:	17e00593          	li	a1,382
ffffffffc0202628:	00004517          	auipc	a0,0x4
ffffffffc020262c:	de850513          	addi	a0,a0,-536 # ffffffffc0206410 <commands+0x890>
ffffffffc0202630:	bf3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
            assert(npage != NULL);
ffffffffc0202634:	00004697          	auipc	a3,0x4
ffffffffc0202638:	41c68693          	addi	a3,a3,1052 # ffffffffc0206a50 <commands+0xed0>
ffffffffc020263c:	00004617          	auipc	a2,0x4
ffffffffc0202640:	e1460613          	addi	a2,a2,-492 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202644:	19700593          	li	a1,407
ffffffffc0202648:	00004517          	auipc	a0,0x4
ffffffffc020264c:	dc850513          	addi	a0,a0,-568 # ffffffffc0206410 <commands+0x890>
ffffffffc0202650:	bd3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202654:	00004617          	auipc	a2,0x4
ffffffffc0202658:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206390 <commands+0x810>
ffffffffc020265c:	06900593          	li	a1,105
ffffffffc0202660:	00004517          	auipc	a0,0x4
ffffffffc0202664:	d5050513          	addi	a0,a0,-688 # ffffffffc02063b0 <commands+0x830>
ffffffffc0202668:	bbbfd0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020266c:	00004617          	auipc	a2,0x4
ffffffffc0202670:	d5460613          	addi	a2,a2,-684 # ffffffffc02063c0 <commands+0x840>
ffffffffc0202674:	07f00593          	li	a1,127
ffffffffc0202678:	00004517          	auipc	a0,0x4
ffffffffc020267c:	d3850513          	addi	a0,a0,-712 # ffffffffc02063b0 <commands+0x830>
ffffffffc0202680:	ba3fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202684:	00004697          	auipc	a3,0x4
ffffffffc0202688:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206420 <commands+0x8a0>
ffffffffc020268c:	00004617          	auipc	a2,0x4
ffffffffc0202690:	dc460613          	addi	a2,a2,-572 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202694:	17d00593          	li	a1,381
ffffffffc0202698:	00004517          	auipc	a0,0x4
ffffffffc020269c:	d7850513          	addi	a0,a0,-648 # ffffffffc0206410 <commands+0x890>
ffffffffc02026a0:	b83fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc02026a4 <pgdir_alloc_page>:
{
ffffffffc02026a4:	7179                	addi	sp,sp,-48
ffffffffc02026a6:	ec26                	sd	s1,24(sp)
ffffffffc02026a8:	e84a                	sd	s2,16(sp)
ffffffffc02026aa:	e052                	sd	s4,0(sp)
ffffffffc02026ac:	f406                	sd	ra,40(sp)
ffffffffc02026ae:	f022                	sd	s0,32(sp)
ffffffffc02026b0:	e44e                	sd	s3,8(sp)
ffffffffc02026b2:	8a2a                	mv	s4,a0
ffffffffc02026b4:	84ae                	mv	s1,a1
ffffffffc02026b6:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026b8:	100027f3          	csrr	a5,sstatus
ffffffffc02026bc:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02026be:	000c4997          	auipc	s3,0xc4
ffffffffc02026c2:	3da98993          	addi	s3,s3,986 # ffffffffc02c6a98 <pmm_manager>
ffffffffc02026c6:	ef8d                	bnez	a5,ffffffffc0202700 <pgdir_alloc_page+0x5c>
ffffffffc02026c8:	0009b783          	ld	a5,0(s3)
ffffffffc02026cc:	4505                	li	a0,1
ffffffffc02026ce:	6f9c                	ld	a5,24(a5)
ffffffffc02026d0:	9782                	jalr	a5
ffffffffc02026d2:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02026d4:	cc09                	beqz	s0,ffffffffc02026ee <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02026d6:	86ca                	mv	a3,s2
ffffffffc02026d8:	8626                	mv	a2,s1
ffffffffc02026da:	85a2                	mv	a1,s0
ffffffffc02026dc:	8552                	mv	a0,s4
ffffffffc02026de:	830ff0ef          	jal	ra,ffffffffc020170e <page_insert>
ffffffffc02026e2:	e915                	bnez	a0,ffffffffc0202716 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02026e4:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02026e6:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02026e8:	4785                	li	a5,1
ffffffffc02026ea:	04f71e63          	bne	a4,a5,ffffffffc0202746 <pgdir_alloc_page+0xa2>
}
ffffffffc02026ee:	70a2                	ld	ra,40(sp)
ffffffffc02026f0:	8522                	mv	a0,s0
ffffffffc02026f2:	7402                	ld	s0,32(sp)
ffffffffc02026f4:	64e2                	ld	s1,24(sp)
ffffffffc02026f6:	6942                	ld	s2,16(sp)
ffffffffc02026f8:	69a2                	ld	s3,8(sp)
ffffffffc02026fa:	6a02                	ld	s4,0(sp)
ffffffffc02026fc:	6145                	addi	sp,sp,48
ffffffffc02026fe:	8082                	ret
        intr_disable();
ffffffffc0202700:	ab4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202704:	0009b783          	ld	a5,0(s3)
ffffffffc0202708:	4505                	li	a0,1
ffffffffc020270a:	6f9c                	ld	a5,24(a5)
ffffffffc020270c:	9782                	jalr	a5
ffffffffc020270e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202710:	a9efe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202714:	b7c1                	j	ffffffffc02026d4 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202716:	100027f3          	csrr	a5,sstatus
ffffffffc020271a:	8b89                	andi	a5,a5,2
ffffffffc020271c:	eb89                	bnez	a5,ffffffffc020272e <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020271e:	0009b783          	ld	a5,0(s3)
ffffffffc0202722:	8522                	mv	a0,s0
ffffffffc0202724:	4585                	li	a1,1
ffffffffc0202726:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0202728:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020272a:	9782                	jalr	a5
    if (flag)
ffffffffc020272c:	b7c9                	j	ffffffffc02026ee <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020272e:	a86fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202732:	0009b783          	ld	a5,0(s3)
ffffffffc0202736:	8522                	mv	a0,s0
ffffffffc0202738:	4585                	li	a1,1
ffffffffc020273a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020273c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020273e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202740:	a6efe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202744:	b76d                	j	ffffffffc02026ee <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0202746:	00004697          	auipc	a3,0x4
ffffffffc020274a:	32a68693          	addi	a3,a3,810 # ffffffffc0206a70 <commands+0xef0>
ffffffffc020274e:	00004617          	auipc	a2,0x4
ffffffffc0202752:	d0260613          	addi	a2,a2,-766 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202756:	1f800593          	li	a1,504
ffffffffc020275a:	00004517          	auipc	a0,0x4
ffffffffc020275e:	cb650513          	addi	a0,a0,-842 # ffffffffc0206410 <commands+0x890>
ffffffffc0202762:	ac1fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202766 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202766:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202768:	00004697          	auipc	a3,0x4
ffffffffc020276c:	32068693          	addi	a3,a3,800 # ffffffffc0206a88 <commands+0xf08>
ffffffffc0202770:	00004617          	auipc	a2,0x4
ffffffffc0202774:	ce060613          	addi	a2,a2,-800 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202778:	07400593          	li	a1,116
ffffffffc020277c:	00004517          	auipc	a0,0x4
ffffffffc0202780:	32c50513          	addi	a0,a0,812 # ffffffffc0206aa8 <commands+0xf28>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202784:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202786:	a9dfd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc020278a <mm_create>:
{
ffffffffc020278a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020278c:	04000513          	li	a0,64
{
ffffffffc0202790:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202792:	135000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
    if (mm != NULL)
ffffffffc0202796:	cd19                	beqz	a0,ffffffffc02027b4 <mm_create+0x2a>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0202798:	e508                	sd	a0,8(a0)
ffffffffc020279a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020279c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02027a0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02027a4:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02027a8:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02027ac:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02027b0:	02053c23          	sd	zero,56(a0)
}
ffffffffc02027b4:	60a2                	ld	ra,8(sp)
ffffffffc02027b6:	0141                	addi	sp,sp,16
ffffffffc02027b8:	8082                	ret

ffffffffc02027ba <find_vma>:
{
ffffffffc02027ba:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02027bc:	c505                	beqz	a0,ffffffffc02027e4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02027be:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02027c0:	c501                	beqz	a0,ffffffffc02027c8 <find_vma+0xe>
ffffffffc02027c2:	651c                	ld	a5,8(a0)
ffffffffc02027c4:	02f5f263          	bgeu	a1,a5,ffffffffc02027e8 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02027c8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02027ca:	00f68d63          	beq	a3,a5,ffffffffc02027e4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02027ce:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38e8>
ffffffffc02027d2:	00e5e663          	bltu	a1,a4,ffffffffc02027de <find_vma+0x24>
ffffffffc02027d6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02027da:	00e5ec63          	bltu	a1,a4,ffffffffc02027f2 <find_vma+0x38>
ffffffffc02027de:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02027e0:	fef697e3          	bne	a3,a5,ffffffffc02027ce <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02027e4:	4501                	li	a0,0
}
ffffffffc02027e6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02027e8:	691c                	ld	a5,16(a0)
ffffffffc02027ea:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02027c8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02027ee:	ea88                	sd	a0,16(a3)
ffffffffc02027f0:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02027f2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02027f6:	ea88                	sd	a0,16(a3)
ffffffffc02027f8:	8082                	ret

ffffffffc02027fa <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02027fa:	6590                	ld	a2,8(a1)
ffffffffc02027fc:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x73910>
{
ffffffffc0202800:	1141                	addi	sp,sp,-16
ffffffffc0202802:	e406                	sd	ra,8(sp)
ffffffffc0202804:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202806:	01066763          	bltu	a2,a6,ffffffffc0202814 <insert_vma_struct+0x1a>
ffffffffc020280a:	a085                	j	ffffffffc020286a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020280c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202810:	04e66863          	bltu	a2,a4,ffffffffc0202860 <insert_vma_struct+0x66>
ffffffffc0202814:	86be                	mv	a3,a5
ffffffffc0202816:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202818:	fef51ae3          	bne	a0,a5,ffffffffc020280c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020281c:	02a68463          	beq	a3,a0,ffffffffc0202844 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202820:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202824:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202828:	08e8f163          	bgeu	a7,a4,ffffffffc02028aa <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020282c:	04e66f63          	bltu	a2,a4,ffffffffc020288a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202830:	00f50a63          	beq	a0,a5,ffffffffc0202844 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202834:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202838:	05076963          	bltu	a4,a6,ffffffffc020288a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020283c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202840:	02c77363          	bgeu	a4,a2,ffffffffc0202866 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202844:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202846:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202848:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020284c:	e390                	sd	a2,0(a5)
ffffffffc020284e:	e690                	sd	a2,8(a3)
}
ffffffffc0202850:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202852:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202854:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202856:	0017079b          	addiw	a5,a4,1
ffffffffc020285a:	d11c                	sw	a5,32(a0)
}
ffffffffc020285c:	0141                	addi	sp,sp,16
ffffffffc020285e:	8082                	ret
    if (le_prev != list)
ffffffffc0202860:	fca690e3          	bne	a3,a0,ffffffffc0202820 <insert_vma_struct+0x26>
ffffffffc0202864:	bfd1                	j	ffffffffc0202838 <insert_vma_struct+0x3e>
ffffffffc0202866:	f01ff0ef          	jal	ra,ffffffffc0202766 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020286a:	00004697          	auipc	a3,0x4
ffffffffc020286e:	24e68693          	addi	a3,a3,590 # ffffffffc0206ab8 <commands+0xf38>
ffffffffc0202872:	00004617          	auipc	a2,0x4
ffffffffc0202876:	bde60613          	addi	a2,a2,-1058 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020287a:	07a00593          	li	a1,122
ffffffffc020287e:	00004517          	auipc	a0,0x4
ffffffffc0202882:	22a50513          	addi	a0,a0,554 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202886:	99dfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020288a:	00004697          	auipc	a3,0x4
ffffffffc020288e:	26e68693          	addi	a3,a3,622 # ffffffffc0206af8 <commands+0xf78>
ffffffffc0202892:	00004617          	auipc	a2,0x4
ffffffffc0202896:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020289a:	07300593          	li	a1,115
ffffffffc020289e:	00004517          	auipc	a0,0x4
ffffffffc02028a2:	20a50513          	addi	a0,a0,522 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc02028a6:	97dfd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02028aa:	00004697          	auipc	a3,0x4
ffffffffc02028ae:	22e68693          	addi	a3,a3,558 # ffffffffc0206ad8 <commands+0xf58>
ffffffffc02028b2:	00004617          	auipc	a2,0x4
ffffffffc02028b6:	b9e60613          	addi	a2,a2,-1122 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02028ba:	07200593          	li	a1,114
ffffffffc02028be:	00004517          	auipc	a0,0x4
ffffffffc02028c2:	1ea50513          	addi	a0,a0,490 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc02028c6:	95dfd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc02028ca <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02028ca:	591c                	lw	a5,48(a0)
{
ffffffffc02028cc:	1141                	addi	sp,sp,-16
ffffffffc02028ce:	e406                	sd	ra,8(sp)
ffffffffc02028d0:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02028d2:	e78d                	bnez	a5,ffffffffc02028fc <mm_destroy+0x32>
ffffffffc02028d4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02028d6:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02028d8:	00a40c63          	beq	s0,a0,ffffffffc02028f0 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02028dc:	6118                	ld	a4,0(a0)
ffffffffc02028de:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02028e0:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02028e2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02028e4:	e398                	sd	a4,0(a5)
ffffffffc02028e6:	091000ef          	jal	ra,ffffffffc0203176 <kfree>
    return listelm->next;
ffffffffc02028ea:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02028ec:	fea418e3          	bne	s0,a0,ffffffffc02028dc <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02028f0:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02028f2:	6402                	ld	s0,0(sp)
ffffffffc02028f4:	60a2                	ld	ra,8(sp)
ffffffffc02028f6:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02028f8:	07f0006f          	j	ffffffffc0203176 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02028fc:	00004697          	auipc	a3,0x4
ffffffffc0202900:	21c68693          	addi	a3,a3,540 # ffffffffc0206b18 <commands+0xf98>
ffffffffc0202904:	00004617          	auipc	a2,0x4
ffffffffc0202908:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020290c:	09e00593          	li	a1,158
ffffffffc0202910:	00004517          	auipc	a0,0x4
ffffffffc0202914:	19850513          	addi	a0,a0,408 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202918:	90bfd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc020291c <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020291c:	7139                	addi	sp,sp,-64
ffffffffc020291e:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202920:	6405                	lui	s0,0x1
ffffffffc0202922:	147d                	addi	s0,s0,-1
ffffffffc0202924:	77fd                	lui	a5,0xfffff
ffffffffc0202926:	9622                	add	a2,a2,s0
ffffffffc0202928:	962e                	add	a2,a2,a1
{
ffffffffc020292a:	f426                	sd	s1,40(sp)
ffffffffc020292c:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020292e:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0202932:	f04a                	sd	s2,32(sp)
ffffffffc0202934:	ec4e                	sd	s3,24(sp)
ffffffffc0202936:	e852                	sd	s4,16(sp)
ffffffffc0202938:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020293a:	002005b7          	lui	a1,0x200
ffffffffc020293e:	00f67433          	and	s0,a2,a5
ffffffffc0202942:	06b4e363          	bltu	s1,a1,ffffffffc02029a8 <mm_map+0x8c>
ffffffffc0202946:	0684f163          	bgeu	s1,s0,ffffffffc02029a8 <mm_map+0x8c>
ffffffffc020294a:	4785                	li	a5,1
ffffffffc020294c:	07fe                	slli	a5,a5,0x1f
ffffffffc020294e:	0487ed63          	bltu	a5,s0,ffffffffc02029a8 <mm_map+0x8c>
ffffffffc0202952:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0202954:	cd21                	beqz	a0,ffffffffc02029ac <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0202956:	85a6                	mv	a1,s1
ffffffffc0202958:	8ab6                	mv	s5,a3
ffffffffc020295a:	8a3a                	mv	s4,a4
ffffffffc020295c:	e5fff0ef          	jal	ra,ffffffffc02027ba <find_vma>
ffffffffc0202960:	c501                	beqz	a0,ffffffffc0202968 <mm_map+0x4c>
ffffffffc0202962:	651c                	ld	a5,8(a0)
ffffffffc0202964:	0487e263          	bltu	a5,s0,ffffffffc02029a8 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202968:	03000513          	li	a0,48
ffffffffc020296c:	75a000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
ffffffffc0202970:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0202972:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0202974:	02090163          	beqz	s2,ffffffffc0202996 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0202978:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020297a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020297e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0202982:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0202986:	85ca                	mv	a1,s2
ffffffffc0202988:	e73ff0ef          	jal	ra,ffffffffc02027fa <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc020298c:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020298e:	000a0463          	beqz	s4,ffffffffc0202996 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0202992:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f38>

out:
    return ret;
}
ffffffffc0202996:	70e2                	ld	ra,56(sp)
ffffffffc0202998:	7442                	ld	s0,48(sp)
ffffffffc020299a:	74a2                	ld	s1,40(sp)
ffffffffc020299c:	7902                	ld	s2,32(sp)
ffffffffc020299e:	69e2                	ld	s3,24(sp)
ffffffffc02029a0:	6a42                	ld	s4,16(sp)
ffffffffc02029a2:	6aa2                	ld	s5,8(sp)
ffffffffc02029a4:	6121                	addi	sp,sp,64
ffffffffc02029a6:	8082                	ret
        return -E_INVAL;
ffffffffc02029a8:	5575                	li	a0,-3
ffffffffc02029aa:	b7f5                	j	ffffffffc0202996 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02029ac:	00004697          	auipc	a3,0x4
ffffffffc02029b0:	18468693          	addi	a3,a3,388 # ffffffffc0206b30 <commands+0xfb0>
ffffffffc02029b4:	00004617          	auipc	a2,0x4
ffffffffc02029b8:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02029bc:	0b300593          	li	a1,179
ffffffffc02029c0:	00004517          	auipc	a0,0x4
ffffffffc02029c4:	0e850513          	addi	a0,a0,232 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc02029c8:	85bfd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc02029cc <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02029cc:	7139                	addi	sp,sp,-64
ffffffffc02029ce:	fc06                	sd	ra,56(sp)
ffffffffc02029d0:	f822                	sd	s0,48(sp)
ffffffffc02029d2:	f426                	sd	s1,40(sp)
ffffffffc02029d4:	f04a                	sd	s2,32(sp)
ffffffffc02029d6:	ec4e                	sd	s3,24(sp)
ffffffffc02029d8:	e852                	sd	s4,16(sp)
ffffffffc02029da:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02029dc:	c52d                	beqz	a0,ffffffffc0202a46 <dup_mmap+0x7a>
ffffffffc02029de:	892a                	mv	s2,a0
ffffffffc02029e0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02029e2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02029e4:	e595                	bnez	a1,ffffffffc0202a10 <dup_mmap+0x44>
ffffffffc02029e6:	a085                	j	ffffffffc0202a46 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02029e8:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02029ea:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f3908>
        vma->vm_end = vm_end;
ffffffffc02029ee:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02029f2:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02029f6:	e05ff0ef          	jal	ra,ffffffffc02027fa <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02029fa:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f48>
ffffffffc02029fe:	fe843603          	ld	a2,-24(s0)
ffffffffc0202a02:	6c8c                	ld	a1,24(s1)
ffffffffc0202a04:	01893503          	ld	a0,24(s2)
ffffffffc0202a08:	4701                	li	a4,0
ffffffffc0202a0a:	a3bff0ef          	jal	ra,ffffffffc0202444 <copy_range>
ffffffffc0202a0e:	e105                	bnez	a0,ffffffffc0202a2e <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0202a10:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0202a12:	02848863          	beq	s1,s0,ffffffffc0202a42 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202a16:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0202a1a:	fe843a83          	ld	s5,-24(s0)
ffffffffc0202a1e:	ff043a03          	ld	s4,-16(s0)
ffffffffc0202a22:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202a26:	6a0000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
ffffffffc0202a2a:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0202a2c:	fd55                	bnez	a0,ffffffffc02029e8 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0202a2e:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0202a30:	70e2                	ld	ra,56(sp)
ffffffffc0202a32:	7442                	ld	s0,48(sp)
ffffffffc0202a34:	74a2                	ld	s1,40(sp)
ffffffffc0202a36:	7902                	ld	s2,32(sp)
ffffffffc0202a38:	69e2                	ld	s3,24(sp)
ffffffffc0202a3a:	6a42                	ld	s4,16(sp)
ffffffffc0202a3c:	6aa2                	ld	s5,8(sp)
ffffffffc0202a3e:	6121                	addi	sp,sp,64
ffffffffc0202a40:	8082                	ret
    return 0;
ffffffffc0202a42:	4501                	li	a0,0
ffffffffc0202a44:	b7f5                	j	ffffffffc0202a30 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0202a46:	00004697          	auipc	a3,0x4
ffffffffc0202a4a:	0fa68693          	addi	a3,a3,250 # ffffffffc0206b40 <commands+0xfc0>
ffffffffc0202a4e:	00004617          	auipc	a2,0x4
ffffffffc0202a52:	a0260613          	addi	a2,a2,-1534 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202a56:	0cf00593          	li	a1,207
ffffffffc0202a5a:	00004517          	auipc	a0,0x4
ffffffffc0202a5e:	04e50513          	addi	a0,a0,78 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202a62:	fc0fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202a66 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0202a66:	1101                	addi	sp,sp,-32
ffffffffc0202a68:	ec06                	sd	ra,24(sp)
ffffffffc0202a6a:	e822                	sd	s0,16(sp)
ffffffffc0202a6c:	e426                	sd	s1,8(sp)
ffffffffc0202a6e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202a70:	c531                	beqz	a0,ffffffffc0202abc <exit_mmap+0x56>
ffffffffc0202a72:	591c                	lw	a5,48(a0)
ffffffffc0202a74:	84aa                	mv	s1,a0
ffffffffc0202a76:	e3b9                	bnez	a5,ffffffffc0202abc <exit_mmap+0x56>
    return listelm->next;
ffffffffc0202a78:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0202a7a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0202a7e:	02850663          	beq	a0,s0,ffffffffc0202aaa <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202a82:	ff043603          	ld	a2,-16(s0)
ffffffffc0202a86:	fe843583          	ld	a1,-24(s0)
ffffffffc0202a8a:	854a                	mv	a0,s2
ffffffffc0202a8c:	80ffe0ef          	jal	ra,ffffffffc020129a <unmap_range>
ffffffffc0202a90:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0202a92:	fe8498e3          	bne	s1,s0,ffffffffc0202a82 <exit_mmap+0x1c>
ffffffffc0202a96:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0202a98:	00848c63          	beq	s1,s0,ffffffffc0202ab0 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202a9c:	ff043603          	ld	a2,-16(s0)
ffffffffc0202aa0:	fe843583          	ld	a1,-24(s0)
ffffffffc0202aa4:	854a                	mv	a0,s2
ffffffffc0202aa6:	93bfe0ef          	jal	ra,ffffffffc02013e0 <exit_range>
ffffffffc0202aaa:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0202aac:	fe8498e3          	bne	s1,s0,ffffffffc0202a9c <exit_mmap+0x36>
    }
}
ffffffffc0202ab0:	60e2                	ld	ra,24(sp)
ffffffffc0202ab2:	6442                	ld	s0,16(sp)
ffffffffc0202ab4:	64a2                	ld	s1,8(sp)
ffffffffc0202ab6:	6902                	ld	s2,0(sp)
ffffffffc0202ab8:	6105                	addi	sp,sp,32
ffffffffc0202aba:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202abc:	00004697          	auipc	a3,0x4
ffffffffc0202ac0:	0a468693          	addi	a3,a3,164 # ffffffffc0206b60 <commands+0xfe0>
ffffffffc0202ac4:	00004617          	auipc	a2,0x4
ffffffffc0202ac8:	98c60613          	addi	a2,a2,-1652 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202acc:	0e800593          	li	a1,232
ffffffffc0202ad0:	00004517          	auipc	a0,0x4
ffffffffc0202ad4:	fd850513          	addi	a0,a0,-40 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202ad8:	f4afd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202adc <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202adc:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ade:	04000513          	li	a0,64
{
ffffffffc0202ae2:	fc06                	sd	ra,56(sp)
ffffffffc0202ae4:	f822                	sd	s0,48(sp)
ffffffffc0202ae6:	f426                	sd	s1,40(sp)
ffffffffc0202ae8:	f04a                	sd	s2,32(sp)
ffffffffc0202aea:	ec4e                	sd	s3,24(sp)
ffffffffc0202aec:	e852                	sd	s4,16(sp)
ffffffffc0202aee:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202af0:	5d6000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
    if (mm != NULL)
ffffffffc0202af4:	2e050663          	beqz	a0,ffffffffc0202de0 <vmm_init+0x304>
ffffffffc0202af8:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202afa:	e508                	sd	a0,8(a0)
ffffffffc0202afc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202afe:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202b02:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202b06:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202b0a:	02053423          	sd	zero,40(a0)
ffffffffc0202b0e:	02052823          	sw	zero,48(a0)
ffffffffc0202b12:	02053c23          	sd	zero,56(a0)
ffffffffc0202b16:	03200413          	li	s0,50
ffffffffc0202b1a:	a811                	j	ffffffffc0202b2e <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0202b1c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202b1e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202b20:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202b24:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202b26:	8526                	mv	a0,s1
ffffffffc0202b28:	cd3ff0ef          	jal	ra,ffffffffc02027fa <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202b2c:	c80d                	beqz	s0,ffffffffc0202b5e <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b2e:	03000513          	li	a0,48
ffffffffc0202b32:	594000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
ffffffffc0202b36:	85aa                	mv	a1,a0
ffffffffc0202b38:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202b3c:	f165                	bnez	a0,ffffffffc0202b1c <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0202b3e:	00004697          	auipc	a3,0x4
ffffffffc0202b42:	1ba68693          	addi	a3,a3,442 # ffffffffc0206cf8 <commands+0x1178>
ffffffffc0202b46:	00004617          	auipc	a2,0x4
ffffffffc0202b4a:	90a60613          	addi	a2,a2,-1782 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202b4e:	12c00593          	li	a1,300
ffffffffc0202b52:	00004517          	auipc	a0,0x4
ffffffffc0202b56:	f5650513          	addi	a0,a0,-170 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202b5a:	ec8fd0ef          	jal	ra,ffffffffc0200222 <__panic>
ffffffffc0202b5e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202b62:	1f900913          	li	s2,505
ffffffffc0202b66:	a819                	j	ffffffffc0202b7c <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0202b68:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202b6a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202b6c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202b70:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202b72:	8526                	mv	a0,s1
ffffffffc0202b74:	c87ff0ef          	jal	ra,ffffffffc02027fa <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202b78:	03240a63          	beq	s0,s2,ffffffffc0202bac <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b7c:	03000513          	li	a0,48
ffffffffc0202b80:	546000ef          	jal	ra,ffffffffc02030c6 <kmalloc>
ffffffffc0202b84:	85aa                	mv	a1,a0
ffffffffc0202b86:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202b8a:	fd79                	bnez	a0,ffffffffc0202b68 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0202b8c:	00004697          	auipc	a3,0x4
ffffffffc0202b90:	16c68693          	addi	a3,a3,364 # ffffffffc0206cf8 <commands+0x1178>
ffffffffc0202b94:	00004617          	auipc	a2,0x4
ffffffffc0202b98:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202b9c:	13300593          	li	a1,307
ffffffffc0202ba0:	00004517          	auipc	a0,0x4
ffffffffc0202ba4:	f0850513          	addi	a0,a0,-248 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202ba8:	e7afd0ef          	jal	ra,ffffffffc0200222 <__panic>
    return listelm->next;
ffffffffc0202bac:	649c                	ld	a5,8(s1)
ffffffffc0202bae:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202bb0:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202bb4:	16f48663          	beq	s1,a5,ffffffffc0202d20 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202bb8:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd38508>
ffffffffc0202bbc:	ffe70693          	addi	a3,a4,-2
ffffffffc0202bc0:	10d61063          	bne	a2,a3,ffffffffc0202cc0 <vmm_init+0x1e4>
ffffffffc0202bc4:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202bc8:	0ed71c63          	bne	a4,a3,ffffffffc0202cc0 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0202bcc:	0715                	addi	a4,a4,5
ffffffffc0202bce:	679c                	ld	a5,8(a5)
ffffffffc0202bd0:	feb712e3          	bne	a4,a1,ffffffffc0202bb4 <vmm_init+0xd8>
ffffffffc0202bd4:	4a1d                	li	s4,7
ffffffffc0202bd6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202bd8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202bdc:	85a2                	mv	a1,s0
ffffffffc0202bde:	8526                	mv	a0,s1
ffffffffc0202be0:	bdbff0ef          	jal	ra,ffffffffc02027ba <find_vma>
ffffffffc0202be4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202be6:	16050d63          	beqz	a0,ffffffffc0202d60 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202bea:	00140593          	addi	a1,s0,1
ffffffffc0202bee:	8526                	mv	a0,s1
ffffffffc0202bf0:	bcbff0ef          	jal	ra,ffffffffc02027ba <find_vma>
ffffffffc0202bf4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202bf6:	14050563          	beqz	a0,ffffffffc0202d40 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202bfa:	85d2                	mv	a1,s4
ffffffffc0202bfc:	8526                	mv	a0,s1
ffffffffc0202bfe:	bbdff0ef          	jal	ra,ffffffffc02027ba <find_vma>
        assert(vma3 == NULL);
ffffffffc0202c02:	16051f63          	bnez	a0,ffffffffc0202d80 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202c06:	00340593          	addi	a1,s0,3
ffffffffc0202c0a:	8526                	mv	a0,s1
ffffffffc0202c0c:	bafff0ef          	jal	ra,ffffffffc02027ba <find_vma>
        assert(vma4 == NULL);
ffffffffc0202c10:	1a051863          	bnez	a0,ffffffffc0202dc0 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202c14:	00440593          	addi	a1,s0,4
ffffffffc0202c18:	8526                	mv	a0,s1
ffffffffc0202c1a:	ba1ff0ef          	jal	ra,ffffffffc02027ba <find_vma>
        assert(vma5 == NULL);
ffffffffc0202c1e:	18051163          	bnez	a0,ffffffffc0202da0 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202c22:	00893783          	ld	a5,8(s2)
ffffffffc0202c26:	0a879d63          	bne	a5,s0,ffffffffc0202ce0 <vmm_init+0x204>
ffffffffc0202c2a:	01093783          	ld	a5,16(s2)
ffffffffc0202c2e:	0b479963          	bne	a5,s4,ffffffffc0202ce0 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202c32:	0089b783          	ld	a5,8(s3)
ffffffffc0202c36:	0c879563          	bne	a5,s0,ffffffffc0202d00 <vmm_init+0x224>
ffffffffc0202c3a:	0109b783          	ld	a5,16(s3)
ffffffffc0202c3e:	0d479163          	bne	a5,s4,ffffffffc0202d00 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202c42:	0415                	addi	s0,s0,5
ffffffffc0202c44:	0a15                	addi	s4,s4,5
ffffffffc0202c46:	f9541be3          	bne	s0,s5,ffffffffc0202bdc <vmm_init+0x100>
ffffffffc0202c4a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202c4c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202c4e:	85a2                	mv	a1,s0
ffffffffc0202c50:	8526                	mv	a0,s1
ffffffffc0202c52:	b69ff0ef          	jal	ra,ffffffffc02027ba <find_vma>
ffffffffc0202c56:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0202c5a:	c90d                	beqz	a0,ffffffffc0202c8c <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0202c5c:	6914                	ld	a3,16(a0)
ffffffffc0202c5e:	6510                	ld	a2,8(a0)
ffffffffc0202c60:	00004517          	auipc	a0,0x4
ffffffffc0202c64:	02050513          	addi	a0,a0,32 # ffffffffc0206c80 <commands+0x1100>
ffffffffc0202c68:	c7cfd0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202c6c:	00004697          	auipc	a3,0x4
ffffffffc0202c70:	03c68693          	addi	a3,a3,60 # ffffffffc0206ca8 <commands+0x1128>
ffffffffc0202c74:	00003617          	auipc	a2,0x3
ffffffffc0202c78:	7dc60613          	addi	a2,a2,2012 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202c7c:	15900593          	li	a1,345
ffffffffc0202c80:	00004517          	auipc	a0,0x4
ffffffffc0202c84:	e2850513          	addi	a0,a0,-472 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202c88:	d9afd0ef          	jal	ra,ffffffffc0200222 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0202c8c:	147d                	addi	s0,s0,-1
ffffffffc0202c8e:	fd2410e3          	bne	s0,s2,ffffffffc0202c4e <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0202c92:	8526                	mv	a0,s1
ffffffffc0202c94:	c37ff0ef          	jal	ra,ffffffffc02028ca <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202c98:	00004517          	auipc	a0,0x4
ffffffffc0202c9c:	02850513          	addi	a0,a0,40 # ffffffffc0206cc0 <commands+0x1140>
ffffffffc0202ca0:	c44fd0ef          	jal	ra,ffffffffc02000e4 <cprintf>
}
ffffffffc0202ca4:	7442                	ld	s0,48(sp)
ffffffffc0202ca6:	70e2                	ld	ra,56(sp)
ffffffffc0202ca8:	74a2                	ld	s1,40(sp)
ffffffffc0202caa:	7902                	ld	s2,32(sp)
ffffffffc0202cac:	69e2                	ld	s3,24(sp)
ffffffffc0202cae:	6a42                	ld	s4,16(sp)
ffffffffc0202cb0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202cb2:	00004517          	auipc	a0,0x4
ffffffffc0202cb6:	02e50513          	addi	a0,a0,46 # ffffffffc0206ce0 <commands+0x1160>
}
ffffffffc0202cba:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202cbc:	c28fd06f          	j	ffffffffc02000e4 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202cc0:	00004697          	auipc	a3,0x4
ffffffffc0202cc4:	ed868693          	addi	a3,a3,-296 # ffffffffc0206b98 <commands+0x1018>
ffffffffc0202cc8:	00003617          	auipc	a2,0x3
ffffffffc0202ccc:	78860613          	addi	a2,a2,1928 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202cd0:	13d00593          	li	a1,317
ffffffffc0202cd4:	00004517          	auipc	a0,0x4
ffffffffc0202cd8:	dd450513          	addi	a0,a0,-556 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202cdc:	d46fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202ce0:	00004697          	auipc	a3,0x4
ffffffffc0202ce4:	f4068693          	addi	a3,a3,-192 # ffffffffc0206c20 <commands+0x10a0>
ffffffffc0202ce8:	00003617          	auipc	a2,0x3
ffffffffc0202cec:	76860613          	addi	a2,a2,1896 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202cf0:	14e00593          	li	a1,334
ffffffffc0202cf4:	00004517          	auipc	a0,0x4
ffffffffc0202cf8:	db450513          	addi	a0,a0,-588 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202cfc:	d26fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202d00:	00004697          	auipc	a3,0x4
ffffffffc0202d04:	f5068693          	addi	a3,a3,-176 # ffffffffc0206c50 <commands+0x10d0>
ffffffffc0202d08:	00003617          	auipc	a2,0x3
ffffffffc0202d0c:	74860613          	addi	a2,a2,1864 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202d10:	14f00593          	li	a1,335
ffffffffc0202d14:	00004517          	auipc	a0,0x4
ffffffffc0202d18:	d9450513          	addi	a0,a0,-620 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202d1c:	d06fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202d20:	00004697          	auipc	a3,0x4
ffffffffc0202d24:	e6068693          	addi	a3,a3,-416 # ffffffffc0206b80 <commands+0x1000>
ffffffffc0202d28:	00003617          	auipc	a2,0x3
ffffffffc0202d2c:	72860613          	addi	a2,a2,1832 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202d30:	13b00593          	li	a1,315
ffffffffc0202d34:	00004517          	auipc	a0,0x4
ffffffffc0202d38:	d7450513          	addi	a0,a0,-652 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202d3c:	ce6fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma2 != NULL);
ffffffffc0202d40:	00004697          	auipc	a3,0x4
ffffffffc0202d44:	ea068693          	addi	a3,a3,-352 # ffffffffc0206be0 <commands+0x1060>
ffffffffc0202d48:	00003617          	auipc	a2,0x3
ffffffffc0202d4c:	70860613          	addi	a2,a2,1800 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202d50:	14600593          	li	a1,326
ffffffffc0202d54:	00004517          	auipc	a0,0x4
ffffffffc0202d58:	d5450513          	addi	a0,a0,-684 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202d5c:	cc6fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma1 != NULL);
ffffffffc0202d60:	00004697          	auipc	a3,0x4
ffffffffc0202d64:	e7068693          	addi	a3,a3,-400 # ffffffffc0206bd0 <commands+0x1050>
ffffffffc0202d68:	00003617          	auipc	a2,0x3
ffffffffc0202d6c:	6e860613          	addi	a2,a2,1768 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202d70:	14400593          	li	a1,324
ffffffffc0202d74:	00004517          	auipc	a0,0x4
ffffffffc0202d78:	d3450513          	addi	a0,a0,-716 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202d7c:	ca6fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma3 == NULL);
ffffffffc0202d80:	00004697          	auipc	a3,0x4
ffffffffc0202d84:	e7068693          	addi	a3,a3,-400 # ffffffffc0206bf0 <commands+0x1070>
ffffffffc0202d88:	00003617          	auipc	a2,0x3
ffffffffc0202d8c:	6c860613          	addi	a2,a2,1736 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202d90:	14800593          	li	a1,328
ffffffffc0202d94:	00004517          	auipc	a0,0x4
ffffffffc0202d98:	d1450513          	addi	a0,a0,-748 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202d9c:	c86fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma5 == NULL);
ffffffffc0202da0:	00004697          	auipc	a3,0x4
ffffffffc0202da4:	e7068693          	addi	a3,a3,-400 # ffffffffc0206c10 <commands+0x1090>
ffffffffc0202da8:	00003617          	auipc	a2,0x3
ffffffffc0202dac:	6a860613          	addi	a2,a2,1704 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202db0:	14c00593          	li	a1,332
ffffffffc0202db4:	00004517          	auipc	a0,0x4
ffffffffc0202db8:	cf450513          	addi	a0,a0,-780 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202dbc:	c66fd0ef          	jal	ra,ffffffffc0200222 <__panic>
        assert(vma4 == NULL);
ffffffffc0202dc0:	00004697          	auipc	a3,0x4
ffffffffc0202dc4:	e4068693          	addi	a3,a3,-448 # ffffffffc0206c00 <commands+0x1080>
ffffffffc0202dc8:	00003617          	auipc	a2,0x3
ffffffffc0202dcc:	68860613          	addi	a2,a2,1672 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202dd0:	14a00593          	li	a1,330
ffffffffc0202dd4:	00004517          	auipc	a0,0x4
ffffffffc0202dd8:	cd450513          	addi	a0,a0,-812 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202ddc:	c46fd0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(mm != NULL);
ffffffffc0202de0:	00004697          	auipc	a3,0x4
ffffffffc0202de4:	d5068693          	addi	a3,a3,-688 # ffffffffc0206b30 <commands+0xfb0>
ffffffffc0202de8:	00003617          	auipc	a2,0x3
ffffffffc0202dec:	66860613          	addi	a2,a2,1640 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0202df0:	12400593          	li	a1,292
ffffffffc0202df4:	00004517          	auipc	a0,0x4
ffffffffc0202df8:	cb450513          	addi	a0,a0,-844 # ffffffffc0206aa8 <commands+0xf28>
ffffffffc0202dfc:	c26fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202e00 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0202e00:	7179                	addi	sp,sp,-48
ffffffffc0202e02:	f022                	sd	s0,32(sp)
ffffffffc0202e04:	f406                	sd	ra,40(sp)
ffffffffc0202e06:	ec26                	sd	s1,24(sp)
ffffffffc0202e08:	e84a                	sd	s2,16(sp)
ffffffffc0202e0a:	e44e                	sd	s3,8(sp)
ffffffffc0202e0c:	e052                	sd	s4,0(sp)
ffffffffc0202e0e:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0202e10:	c135                	beqz	a0,ffffffffc0202e74 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0202e12:	002007b7          	lui	a5,0x200
ffffffffc0202e16:	04f5e663          	bltu	a1,a5,ffffffffc0202e62 <user_mem_check+0x62>
ffffffffc0202e1a:	00c584b3          	add	s1,a1,a2
ffffffffc0202e1e:	0495f263          	bgeu	a1,s1,ffffffffc0202e62 <user_mem_check+0x62>
ffffffffc0202e22:	4785                	li	a5,1
ffffffffc0202e24:	07fe                	slli	a5,a5,0x1f
ffffffffc0202e26:	0297ee63          	bltu	a5,s1,ffffffffc0202e62 <user_mem_check+0x62>
ffffffffc0202e2a:	892a                	mv	s2,a0
ffffffffc0202e2c:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0202e2e:	6a05                	lui	s4,0x1
ffffffffc0202e30:	a821                	j	ffffffffc0202e48 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0202e32:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0202e36:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0202e38:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0202e3a:	c685                	beqz	a3,ffffffffc0202e62 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0202e3c:	c399                	beqz	a5,ffffffffc0202e42 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0202e3e:	02e46263          	bltu	s0,a4,ffffffffc0202e62 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0202e42:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0202e44:	04947663          	bgeu	s0,s1,ffffffffc0202e90 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0202e48:	85a2                	mv	a1,s0
ffffffffc0202e4a:	854a                	mv	a0,s2
ffffffffc0202e4c:	96fff0ef          	jal	ra,ffffffffc02027ba <find_vma>
ffffffffc0202e50:	c909                	beqz	a0,ffffffffc0202e62 <user_mem_check+0x62>
ffffffffc0202e52:	6518                	ld	a4,8(a0)
ffffffffc0202e54:	00e46763          	bltu	s0,a4,ffffffffc0202e62 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0202e58:	4d1c                	lw	a5,24(a0)
ffffffffc0202e5a:	fc099ce3          	bnez	s3,ffffffffc0202e32 <user_mem_check+0x32>
ffffffffc0202e5e:	8b85                	andi	a5,a5,1
ffffffffc0202e60:	f3ed                	bnez	a5,ffffffffc0202e42 <user_mem_check+0x42>
            return 0;
ffffffffc0202e62:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0202e64:	70a2                	ld	ra,40(sp)
ffffffffc0202e66:	7402                	ld	s0,32(sp)
ffffffffc0202e68:	64e2                	ld	s1,24(sp)
ffffffffc0202e6a:	6942                	ld	s2,16(sp)
ffffffffc0202e6c:	69a2                	ld	s3,8(sp)
ffffffffc0202e6e:	6a02                	ld	s4,0(sp)
ffffffffc0202e70:	6145                	addi	sp,sp,48
ffffffffc0202e72:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0202e74:	c02007b7          	lui	a5,0xc0200
ffffffffc0202e78:	4501                	li	a0,0
ffffffffc0202e7a:	fef5e5e3          	bltu	a1,a5,ffffffffc0202e64 <user_mem_check+0x64>
ffffffffc0202e7e:	962e                	add	a2,a2,a1
ffffffffc0202e80:	fec5f2e3          	bgeu	a1,a2,ffffffffc0202e64 <user_mem_check+0x64>
ffffffffc0202e84:	c8000537          	lui	a0,0xc8000
ffffffffc0202e88:	0505                	addi	a0,a0,1
ffffffffc0202e8a:	00a63533          	sltu	a0,a2,a0
ffffffffc0202e8e:	bfd9                	j	ffffffffc0202e64 <user_mem_check+0x64>
        return 1;
ffffffffc0202e90:	4505                	li	a0,1
ffffffffc0202e92:	bfc9                	j	ffffffffc0202e64 <user_mem_check+0x64>

ffffffffc0202e94 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0202e94:	c94d                	beqz	a0,ffffffffc0202f46 <slob_free+0xb2>
{
ffffffffc0202e96:	1141                	addi	sp,sp,-16
ffffffffc0202e98:	e022                	sd	s0,0(sp)
ffffffffc0202e9a:	e406                	sd	ra,8(sp)
ffffffffc0202e9c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0202e9e:	e9c1                	bnez	a1,ffffffffc0202f2e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202ea0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ea4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202ea6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202ea8:	ebd9                	bnez	a5,ffffffffc0202f3e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202eaa:	000bf617          	auipc	a2,0xbf
ffffffffc0202eae:	74660613          	addi	a2,a2,1862 # ffffffffc02c25f0 <slobfree>
ffffffffc0202eb2:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202eb4:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202eb6:	679c                	ld	a5,8(a5)
ffffffffc0202eb8:	02877a63          	bgeu	a4,s0,ffffffffc0202eec <slob_free+0x58>
ffffffffc0202ebc:	00f46463          	bltu	s0,a5,ffffffffc0202ec4 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202ec0:	fef76ae3          	bltu	a4,a5,ffffffffc0202eb4 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0202ec4:	400c                	lw	a1,0(s0)
ffffffffc0202ec6:	00459693          	slli	a3,a1,0x4
ffffffffc0202eca:	96a2                	add	a3,a3,s0
ffffffffc0202ecc:	02d78a63          	beq	a5,a3,ffffffffc0202f00 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0202ed0:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0202ed2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0202ed4:	00469793          	slli	a5,a3,0x4
ffffffffc0202ed8:	97ba                	add	a5,a5,a4
ffffffffc0202eda:	02f40e63          	beq	s0,a5,ffffffffc0202f16 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0202ede:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0202ee0:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0202ee2:	e129                	bnez	a0,ffffffffc0202f24 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0202ee4:	60a2                	ld	ra,8(sp)
ffffffffc0202ee6:	6402                	ld	s0,0(sp)
ffffffffc0202ee8:	0141                	addi	sp,sp,16
ffffffffc0202eea:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202eec:	fcf764e3          	bltu	a4,a5,ffffffffc0202eb4 <slob_free+0x20>
ffffffffc0202ef0:	fcf472e3          	bgeu	s0,a5,ffffffffc0202eb4 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0202ef4:	400c                	lw	a1,0(s0)
ffffffffc0202ef6:	00459693          	slli	a3,a1,0x4
ffffffffc0202efa:	96a2                	add	a3,a3,s0
ffffffffc0202efc:	fcd79ae3          	bne	a5,a3,ffffffffc0202ed0 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0202f00:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0202f02:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0202f04:	9db5                	addw	a1,a1,a3
ffffffffc0202f06:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0202f08:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0202f0a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0202f0c:	00469793          	slli	a5,a3,0x4
ffffffffc0202f10:	97ba                	add	a5,a5,a4
ffffffffc0202f12:	fcf416e3          	bne	s0,a5,ffffffffc0202ede <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0202f16:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0202f18:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0202f1a:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0202f1c:	9ebd                	addw	a3,a3,a5
ffffffffc0202f1e:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0202f20:	e70c                	sd	a1,8(a4)
ffffffffc0202f22:	d169                	beqz	a0,ffffffffc0202ee4 <slob_free+0x50>
}
ffffffffc0202f24:	6402                	ld	s0,0(sp)
ffffffffc0202f26:	60a2                	ld	ra,8(sp)
ffffffffc0202f28:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0202f2a:	a85fd06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0202f2e:	25bd                	addiw	a1,a1,15
ffffffffc0202f30:	8191                	srli	a1,a1,0x4
ffffffffc0202f32:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202f34:	100027f3          	csrr	a5,sstatus
ffffffffc0202f38:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202f3a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202f3c:	d7bd                	beqz	a5,ffffffffc0202eaa <slob_free+0x16>
        intr_disable();
ffffffffc0202f3e:	a77fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0202f42:	4505                	li	a0,1
ffffffffc0202f44:	b79d                	j	ffffffffc0202eaa <slob_free+0x16>
ffffffffc0202f46:	8082                	ret

ffffffffc0202f48 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202f48:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202f4a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202f4c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202f50:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202f52:	814fe0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
	if (!page)
ffffffffc0202f56:	c91d                	beqz	a0,ffffffffc0202f8c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0202f58:	000c4697          	auipc	a3,0xc4
ffffffffc0202f5c:	b386b683          	ld	a3,-1224(a3) # ffffffffc02c6a90 <pages>
ffffffffc0202f60:	8d15                	sub	a0,a0,a3
ffffffffc0202f62:	8519                	srai	a0,a0,0x6
ffffffffc0202f64:	00005697          	auipc	a3,0x5
ffffffffc0202f68:	2fc6b683          	ld	a3,764(a3) # ffffffffc0208260 <nbase>
ffffffffc0202f6c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0202f6e:	00c51793          	slli	a5,a0,0xc
ffffffffc0202f72:	83b1                	srli	a5,a5,0xc
ffffffffc0202f74:	000c4717          	auipc	a4,0xc4
ffffffffc0202f78:	b1473703          	ld	a4,-1260(a4) # ffffffffc02c6a88 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202f7c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0202f7e:	00e7fa63          	bgeu	a5,a4,ffffffffc0202f92 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0202f82:	000c4697          	auipc	a3,0xc4
ffffffffc0202f86:	b1e6b683          	ld	a3,-1250(a3) # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc0202f8a:	9536                	add	a0,a0,a3
}
ffffffffc0202f8c:	60a2                	ld	ra,8(sp)
ffffffffc0202f8e:	0141                	addi	sp,sp,16
ffffffffc0202f90:	8082                	ret
ffffffffc0202f92:	86aa                	mv	a3,a0
ffffffffc0202f94:	00003617          	auipc	a2,0x3
ffffffffc0202f98:	45460613          	addi	a2,a2,1108 # ffffffffc02063e8 <commands+0x868>
ffffffffc0202f9c:	07100593          	li	a1,113
ffffffffc0202fa0:	00003517          	auipc	a0,0x3
ffffffffc0202fa4:	41050513          	addi	a0,a0,1040 # ffffffffc02063b0 <commands+0x830>
ffffffffc0202fa8:	a7afd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0202fac <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0202fac:	1101                	addi	sp,sp,-32
ffffffffc0202fae:	ec06                	sd	ra,24(sp)
ffffffffc0202fb0:	e822                	sd	s0,16(sp)
ffffffffc0202fb2:	e426                	sd	s1,8(sp)
ffffffffc0202fb4:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0202fb6:	01050713          	addi	a4,a0,16
ffffffffc0202fba:	6785                	lui	a5,0x1
ffffffffc0202fbc:	0cf77363          	bgeu	a4,a5,ffffffffc0203082 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0202fc0:	00f50493          	addi	s1,a0,15
ffffffffc0202fc4:	8091                	srli	s1,s1,0x4
ffffffffc0202fc6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202fc8:	10002673          	csrr	a2,sstatus
ffffffffc0202fcc:	8a09                	andi	a2,a2,2
ffffffffc0202fce:	e25d                	bnez	a2,ffffffffc0203074 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0202fd0:	000bf917          	auipc	s2,0xbf
ffffffffc0202fd4:	62090913          	addi	s2,s2,1568 # ffffffffc02c25f0 <slobfree>
ffffffffc0202fd8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202fdc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0202fde:	4398                	lw	a4,0(a5)
ffffffffc0202fe0:	08975e63          	bge	a4,s1,ffffffffc020307c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0202fe4:	00f68b63          	beq	a3,a5,ffffffffc0202ffa <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202fe8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0202fea:	4018                	lw	a4,0(s0)
ffffffffc0202fec:	02975a63          	bge	a4,s1,ffffffffc0203020 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0202ff0:	00093683          	ld	a3,0(s2)
ffffffffc0202ff4:	87a2                	mv	a5,s0
ffffffffc0202ff6:	fef699e3          	bne	a3,a5,ffffffffc0202fe8 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0202ffa:	ee31                	bnez	a2,ffffffffc0203056 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0202ffc:	4501                	li	a0,0
ffffffffc0202ffe:	f4bff0ef          	jal	ra,ffffffffc0202f48 <__slob_get_free_pages.constprop.0>
ffffffffc0203002:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0203004:	cd05                	beqz	a0,ffffffffc020303c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0203006:	6585                	lui	a1,0x1
ffffffffc0203008:	e8dff0ef          	jal	ra,ffffffffc0202e94 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020300c:	10002673          	csrr	a2,sstatus
ffffffffc0203010:	8a09                	andi	a2,a2,2
ffffffffc0203012:	ee05                	bnez	a2,ffffffffc020304a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0203014:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0203018:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc020301a:	4018                	lw	a4,0(s0)
ffffffffc020301c:	fc974ae3          	blt	a4,s1,ffffffffc0202ff0 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0203020:	04e48763          	beq	s1,a4,ffffffffc020306e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0203024:	00449693          	slli	a3,s1,0x4
ffffffffc0203028:	96a2                	add	a3,a3,s0
ffffffffc020302a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc020302c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc020302e:	9f05                	subw	a4,a4,s1
ffffffffc0203030:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0203032:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0203034:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0203036:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc020303a:	e20d                	bnez	a2,ffffffffc020305c <slob_alloc.constprop.0+0xb0>
}
ffffffffc020303c:	60e2                	ld	ra,24(sp)
ffffffffc020303e:	8522                	mv	a0,s0
ffffffffc0203040:	6442                	ld	s0,16(sp)
ffffffffc0203042:	64a2                	ld	s1,8(sp)
ffffffffc0203044:	6902                	ld	s2,0(sp)
ffffffffc0203046:	6105                	addi	sp,sp,32
ffffffffc0203048:	8082                	ret
        intr_disable();
ffffffffc020304a:	96bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc020304e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0203052:	4605                	li	a2,1
ffffffffc0203054:	b7d1                	j	ffffffffc0203018 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0203056:	959fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020305a:	b74d                	j	ffffffffc0202ffc <slob_alloc.constprop.0+0x50>
ffffffffc020305c:	953fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0203060:	60e2                	ld	ra,24(sp)
ffffffffc0203062:	8522                	mv	a0,s0
ffffffffc0203064:	6442                	ld	s0,16(sp)
ffffffffc0203066:	64a2                	ld	s1,8(sp)
ffffffffc0203068:	6902                	ld	s2,0(sp)
ffffffffc020306a:	6105                	addi	sp,sp,32
ffffffffc020306c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc020306e:	6418                	ld	a4,8(s0)
ffffffffc0203070:	e798                	sd	a4,8(a5)
ffffffffc0203072:	b7d1                	j	ffffffffc0203036 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0203074:	941fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0203078:	4605                	li	a2,1
ffffffffc020307a:	bf99                	j	ffffffffc0202fd0 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc020307c:	843e                	mv	s0,a5
ffffffffc020307e:	87b6                	mv	a5,a3
ffffffffc0203080:	b745                	j	ffffffffc0203020 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0203082:	00004697          	auipc	a3,0x4
ffffffffc0203086:	c8668693          	addi	a3,a3,-890 # ffffffffc0206d08 <commands+0x1188>
ffffffffc020308a:	00003617          	auipc	a2,0x3
ffffffffc020308e:	3c660613          	addi	a2,a2,966 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203092:	06300593          	li	a1,99
ffffffffc0203096:	00004517          	auipc	a0,0x4
ffffffffc020309a:	c9250513          	addi	a0,a0,-878 # ffffffffc0206d28 <commands+0x11a8>
ffffffffc020309e:	984fd0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc02030a2 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc02030a2:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc02030a4:	00004517          	auipc	a0,0x4
ffffffffc02030a8:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206d40 <commands+0x11c0>
{
ffffffffc02030ac:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc02030ae:	836fd0ef          	jal	ra,ffffffffc02000e4 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc02030b2:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02030b4:	00004517          	auipc	a0,0x4
ffffffffc02030b8:	ca450513          	addi	a0,a0,-860 # ffffffffc0206d58 <commands+0x11d8>
}
ffffffffc02030bc:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02030be:	826fd06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc02030c2 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc02030c2:	4501                	li	a0,0
ffffffffc02030c4:	8082                	ret

ffffffffc02030c6 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02030c6:	1101                	addi	sp,sp,-32
ffffffffc02030c8:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02030ca:	6905                	lui	s2,0x1
{
ffffffffc02030cc:	e822                	sd	s0,16(sp)
ffffffffc02030ce:	ec06                	sd	ra,24(sp)
ffffffffc02030d0:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02030d2:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f49>
{
ffffffffc02030d6:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02030d8:	04a7f963          	bgeu	a5,a0,ffffffffc020312a <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02030dc:	4561                	li	a0,24
ffffffffc02030de:	ecfff0ef          	jal	ra,ffffffffc0202fac <slob_alloc.constprop.0>
ffffffffc02030e2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02030e4:	c929                	beqz	a0,ffffffffc0203136 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc02030e6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02030ea:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc02030ec:	00f95763          	bge	s2,a5,ffffffffc02030fa <kmalloc+0x34>
ffffffffc02030f0:	6705                	lui	a4,0x1
ffffffffc02030f2:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02030f4:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc02030f6:	fef74ee3          	blt	a4,a5,ffffffffc02030f2 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02030fa:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02030fc:	e4dff0ef          	jal	ra,ffffffffc0202f48 <__slob_get_free_pages.constprop.0>
ffffffffc0203100:	e488                	sd	a0,8(s1)
ffffffffc0203102:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0203104:	c525                	beqz	a0,ffffffffc020316c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203106:	100027f3          	csrr	a5,sstatus
ffffffffc020310a:	8b89                	andi	a5,a5,2
ffffffffc020310c:	ef8d                	bnez	a5,ffffffffc0203146 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc020310e:	000c4797          	auipc	a5,0xc4
ffffffffc0203112:	99a78793          	addi	a5,a5,-1638 # ffffffffc02c6aa8 <bigblocks>
ffffffffc0203116:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0203118:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020311a:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc020311c:	60e2                	ld	ra,24(sp)
ffffffffc020311e:	8522                	mv	a0,s0
ffffffffc0203120:	6442                	ld	s0,16(sp)
ffffffffc0203122:	64a2                	ld	s1,8(sp)
ffffffffc0203124:	6902                	ld	s2,0(sp)
ffffffffc0203126:	6105                	addi	sp,sp,32
ffffffffc0203128:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc020312a:	0541                	addi	a0,a0,16
ffffffffc020312c:	e81ff0ef          	jal	ra,ffffffffc0202fac <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0203130:	01050413          	addi	s0,a0,16
ffffffffc0203134:	f565                	bnez	a0,ffffffffc020311c <kmalloc+0x56>
ffffffffc0203136:	4401                	li	s0,0
}
ffffffffc0203138:	60e2                	ld	ra,24(sp)
ffffffffc020313a:	8522                	mv	a0,s0
ffffffffc020313c:	6442                	ld	s0,16(sp)
ffffffffc020313e:	64a2                	ld	s1,8(sp)
ffffffffc0203140:	6902                	ld	s2,0(sp)
ffffffffc0203142:	6105                	addi	sp,sp,32
ffffffffc0203144:	8082                	ret
        intr_disable();
ffffffffc0203146:	86ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc020314a:	000c4797          	auipc	a5,0xc4
ffffffffc020314e:	95e78793          	addi	a5,a5,-1698 # ffffffffc02c6aa8 <bigblocks>
ffffffffc0203152:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0203154:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0203156:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0203158:	857fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc020315c:	6480                	ld	s0,8(s1)
}
ffffffffc020315e:	60e2                	ld	ra,24(sp)
ffffffffc0203160:	64a2                	ld	s1,8(sp)
ffffffffc0203162:	8522                	mv	a0,s0
ffffffffc0203164:	6442                	ld	s0,16(sp)
ffffffffc0203166:	6902                	ld	s2,0(sp)
ffffffffc0203168:	6105                	addi	sp,sp,32
ffffffffc020316a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc020316c:	45e1                	li	a1,24
ffffffffc020316e:	8526                	mv	a0,s1
ffffffffc0203170:	d25ff0ef          	jal	ra,ffffffffc0202e94 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0203174:	b765                	j	ffffffffc020311c <kmalloc+0x56>

ffffffffc0203176 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0203176:	c179                	beqz	a0,ffffffffc020323c <kfree+0xc6>
{
ffffffffc0203178:	1101                	addi	sp,sp,-32
ffffffffc020317a:	e822                	sd	s0,16(sp)
ffffffffc020317c:	ec06                	sd	ra,24(sp)
ffffffffc020317e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0203180:	03451793          	slli	a5,a0,0x34
ffffffffc0203184:	842a                	mv	s0,a0
ffffffffc0203186:	e7c1                	bnez	a5,ffffffffc020320e <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203188:	100027f3          	csrr	a5,sstatus
ffffffffc020318c:	8b89                	andi	a5,a5,2
ffffffffc020318e:	ebc9                	bnez	a5,ffffffffc0203220 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0203190:	000c4797          	auipc	a5,0xc4
ffffffffc0203194:	9187b783          	ld	a5,-1768(a5) # ffffffffc02c6aa8 <bigblocks>
    return 0;
ffffffffc0203198:	4601                	li	a2,0
ffffffffc020319a:	cbb5                	beqz	a5,ffffffffc020320e <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc020319c:	000c4697          	auipc	a3,0xc4
ffffffffc02031a0:	90c68693          	addi	a3,a3,-1780 # ffffffffc02c6aa8 <bigblocks>
ffffffffc02031a4:	a021                	j	ffffffffc02031ac <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc02031a6:	01048693          	addi	a3,s1,16
ffffffffc02031aa:	c3ad                	beqz	a5,ffffffffc020320c <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc02031ac:	6798                	ld	a4,8(a5)
ffffffffc02031ae:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc02031b0:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc02031b2:	fe871ae3          	bne	a4,s0,ffffffffc02031a6 <kfree+0x30>
				*last = bb->next;
ffffffffc02031b6:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc02031b8:	ee3d                	bnez	a2,ffffffffc0203236 <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc02031ba:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc02031be:	4098                	lw	a4,0(s1)
ffffffffc02031c0:	08f46b63          	bltu	s0,a5,ffffffffc0203256 <kfree+0xe0>
ffffffffc02031c4:	000c4697          	auipc	a3,0xc4
ffffffffc02031c8:	8dc6b683          	ld	a3,-1828(a3) # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc02031cc:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc02031ce:	8031                	srli	s0,s0,0xc
ffffffffc02031d0:	000c4797          	auipc	a5,0xc4
ffffffffc02031d4:	8b87b783          	ld	a5,-1864(a5) # ffffffffc02c6a88 <npage>
ffffffffc02031d8:	06f47363          	bgeu	s0,a5,ffffffffc020323e <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc02031dc:	00005517          	auipc	a0,0x5
ffffffffc02031e0:	08453503          	ld	a0,132(a0) # ffffffffc0208260 <nbase>
ffffffffc02031e4:	8c09                	sub	s0,s0,a0
ffffffffc02031e6:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc02031e8:	000c4517          	auipc	a0,0xc4
ffffffffc02031ec:	8a853503          	ld	a0,-1880(a0) # ffffffffc02c6a90 <pages>
ffffffffc02031f0:	4585                	li	a1,1
ffffffffc02031f2:	9522                	add	a0,a0,s0
ffffffffc02031f4:	00e595bb          	sllw	a1,a1,a4
ffffffffc02031f8:	dadfd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02031fc:	6442                	ld	s0,16(sp)
ffffffffc02031fe:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203200:	8526                	mv	a0,s1
}
ffffffffc0203202:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203204:	45e1                	li	a1,24
}
ffffffffc0203206:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0203208:	c8dff06f          	j	ffffffffc0202e94 <slob_free>
ffffffffc020320c:	e215                	bnez	a2,ffffffffc0203230 <kfree+0xba>
ffffffffc020320e:	ff040513          	addi	a0,s0,-16
}
ffffffffc0203212:	6442                	ld	s0,16(sp)
ffffffffc0203214:	60e2                	ld	ra,24(sp)
ffffffffc0203216:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0203218:	4581                	li	a1,0
}
ffffffffc020321a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020321c:	c79ff06f          	j	ffffffffc0202e94 <slob_free>
        intr_disable();
ffffffffc0203220:	f94fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0203224:	000c4797          	auipc	a5,0xc4
ffffffffc0203228:	8847b783          	ld	a5,-1916(a5) # ffffffffc02c6aa8 <bigblocks>
        return 1;
ffffffffc020322c:	4605                	li	a2,1
ffffffffc020322e:	f7bd                	bnez	a5,ffffffffc020319c <kfree+0x26>
        intr_enable();
ffffffffc0203230:	f7efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203234:	bfe9                	j	ffffffffc020320e <kfree+0x98>
ffffffffc0203236:	f78fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020323a:	b741                	j	ffffffffc02031ba <kfree+0x44>
ffffffffc020323c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc020323e:	00003617          	auipc	a2,0x3
ffffffffc0203242:	15260613          	addi	a2,a2,338 # ffffffffc0206390 <commands+0x810>
ffffffffc0203246:	06900593          	li	a1,105
ffffffffc020324a:	00003517          	auipc	a0,0x3
ffffffffc020324e:	16650513          	addi	a0,a0,358 # ffffffffc02063b0 <commands+0x830>
ffffffffc0203252:	fd1fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0203256:	86a2                	mv	a3,s0
ffffffffc0203258:	00003617          	auipc	a2,0x3
ffffffffc020325c:	2a060613          	addi	a2,a2,672 # ffffffffc02064f8 <commands+0x978>
ffffffffc0203260:	07700593          	li	a1,119
ffffffffc0203264:	00003517          	auipc	a0,0x3
ffffffffc0203268:	14c50513          	addi	a0,a0,332 # ffffffffc02063b0 <commands+0x830>
ffffffffc020326c:	fb7fc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203270 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0203270:	000bf797          	auipc	a5,0xbf
ffffffffc0203274:	79078793          	addi	a5,a5,1936 # ffffffffc02c2a00 <free_area>
ffffffffc0203278:	e79c                	sd	a5,8(a5)
ffffffffc020327a:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020327c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0203280:	8082                	ret

ffffffffc0203282 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0203282:	000bf517          	auipc	a0,0xbf
ffffffffc0203286:	78e56503          	lwu	a0,1934(a0) # ffffffffc02c2a10 <free_area+0x10>
ffffffffc020328a:	8082                	ret

ffffffffc020328c <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020328c:	715d                	addi	sp,sp,-80
ffffffffc020328e:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0203290:	000bf417          	auipc	s0,0xbf
ffffffffc0203294:	77040413          	addi	s0,s0,1904 # ffffffffc02c2a00 <free_area>
ffffffffc0203298:	641c                	ld	a5,8(s0)
ffffffffc020329a:	e486                	sd	ra,72(sp)
ffffffffc020329c:	fc26                	sd	s1,56(sp)
ffffffffc020329e:	f84a                	sd	s2,48(sp)
ffffffffc02032a0:	f44e                	sd	s3,40(sp)
ffffffffc02032a2:	f052                	sd	s4,32(sp)
ffffffffc02032a4:	ec56                	sd	s5,24(sp)
ffffffffc02032a6:	e85a                	sd	s6,16(sp)
ffffffffc02032a8:	e45e                	sd	s7,8(sp)
ffffffffc02032aa:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02032ac:	2a878d63          	beq	a5,s0,ffffffffc0203566 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02032b0:	4481                	li	s1,0
ffffffffc02032b2:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02032b4:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02032b8:	8b09                	andi	a4,a4,2
ffffffffc02032ba:	2a070a63          	beqz	a4,ffffffffc020356e <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02032be:	ff87a703          	lw	a4,-8(a5)
ffffffffc02032c2:	679c                	ld	a5,8(a5)
ffffffffc02032c4:	2905                	addiw	s2,s2,1
ffffffffc02032c6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02032c8:	fe8796e3          	bne	a5,s0,ffffffffc02032b4 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02032cc:	89a6                	mv	s3,s1
ffffffffc02032ce:	d17fd0ef          	jal	ra,ffffffffc0200fe4 <nr_free_pages>
ffffffffc02032d2:	6f351e63          	bne	a0,s3,ffffffffc02039ce <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02032d6:	4505                	li	a0,1
ffffffffc02032d8:	c8ffd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02032dc:	8aaa                	mv	s5,a0
ffffffffc02032de:	42050863          	beqz	a0,ffffffffc020370e <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02032e2:	4505                	li	a0,1
ffffffffc02032e4:	c83fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02032e8:	89aa                	mv	s3,a0
ffffffffc02032ea:	70050263          	beqz	a0,ffffffffc02039ee <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02032ee:	4505                	li	a0,1
ffffffffc02032f0:	c77fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02032f4:	8a2a                	mv	s4,a0
ffffffffc02032f6:	48050c63          	beqz	a0,ffffffffc020378e <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02032fa:	293a8a63          	beq	s5,s3,ffffffffc020358e <default_check+0x302>
ffffffffc02032fe:	28aa8863          	beq	s5,a0,ffffffffc020358e <default_check+0x302>
ffffffffc0203302:	28a98663          	beq	s3,a0,ffffffffc020358e <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203306:	000aa783          	lw	a5,0(s5)
ffffffffc020330a:	2a079263          	bnez	a5,ffffffffc02035ae <default_check+0x322>
ffffffffc020330e:	0009a783          	lw	a5,0(s3)
ffffffffc0203312:	28079e63          	bnez	a5,ffffffffc02035ae <default_check+0x322>
ffffffffc0203316:	411c                	lw	a5,0(a0)
ffffffffc0203318:	28079b63          	bnez	a5,ffffffffc02035ae <default_check+0x322>
    return page - pages + nbase;
ffffffffc020331c:	000c3797          	auipc	a5,0xc3
ffffffffc0203320:	7747b783          	ld	a5,1908(a5) # ffffffffc02c6a90 <pages>
ffffffffc0203324:	40fa8733          	sub	a4,s5,a5
ffffffffc0203328:	00005617          	auipc	a2,0x5
ffffffffc020332c:	f3863603          	ld	a2,-200(a2) # ffffffffc0208260 <nbase>
ffffffffc0203330:	8719                	srai	a4,a4,0x6
ffffffffc0203332:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203334:	000c3697          	auipc	a3,0xc3
ffffffffc0203338:	7546b683          	ld	a3,1876(a3) # ffffffffc02c6a88 <npage>
ffffffffc020333c:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020333e:	0732                	slli	a4,a4,0xc
ffffffffc0203340:	28d77763          	bgeu	a4,a3,ffffffffc02035ce <default_check+0x342>
    return page - pages + nbase;
ffffffffc0203344:	40f98733          	sub	a4,s3,a5
ffffffffc0203348:	8719                	srai	a4,a4,0x6
ffffffffc020334a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020334c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020334e:	4cd77063          	bgeu	a4,a3,ffffffffc020380e <default_check+0x582>
    return page - pages + nbase;
ffffffffc0203352:	40f507b3          	sub	a5,a0,a5
ffffffffc0203356:	8799                	srai	a5,a5,0x6
ffffffffc0203358:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020335a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020335c:	30d7f963          	bgeu	a5,a3,ffffffffc020366e <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0203360:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0203362:	00043c03          	ld	s8,0(s0)
ffffffffc0203366:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020336a:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020336e:	e400                	sd	s0,8(s0)
ffffffffc0203370:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0203372:	000bf797          	auipc	a5,0xbf
ffffffffc0203376:	6807af23          	sw	zero,1694(a5) # ffffffffc02c2a10 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020337a:	bedfd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc020337e:	2c051863          	bnez	a0,ffffffffc020364e <default_check+0x3c2>
    free_page(p0);
ffffffffc0203382:	4585                	li	a1,1
ffffffffc0203384:	8556                	mv	a0,s5
ffffffffc0203386:	c1ffd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_page(p1);
ffffffffc020338a:	4585                	li	a1,1
ffffffffc020338c:	854e                	mv	a0,s3
ffffffffc020338e:	c17fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_page(p2);
ffffffffc0203392:	4585                	li	a1,1
ffffffffc0203394:	8552                	mv	a0,s4
ffffffffc0203396:	c0ffd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    assert(nr_free == 3);
ffffffffc020339a:	4818                	lw	a4,16(s0)
ffffffffc020339c:	478d                	li	a5,3
ffffffffc020339e:	28f71863          	bne	a4,a5,ffffffffc020362e <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02033a2:	4505                	li	a0,1
ffffffffc02033a4:	bc3fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033a8:	89aa                	mv	s3,a0
ffffffffc02033aa:	26050263          	beqz	a0,ffffffffc020360e <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02033ae:	4505                	li	a0,1
ffffffffc02033b0:	bb7fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033b4:	8aaa                	mv	s5,a0
ffffffffc02033b6:	3a050c63          	beqz	a0,ffffffffc020376e <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02033ba:	4505                	li	a0,1
ffffffffc02033bc:	babfd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033c0:	8a2a                	mv	s4,a0
ffffffffc02033c2:	38050663          	beqz	a0,ffffffffc020374e <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02033c6:	4505                	li	a0,1
ffffffffc02033c8:	b9ffd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033cc:	36051163          	bnez	a0,ffffffffc020372e <default_check+0x4a2>
    free_page(p0);
ffffffffc02033d0:	4585                	li	a1,1
ffffffffc02033d2:	854e                	mv	a0,s3
ffffffffc02033d4:	bd1fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02033d8:	641c                	ld	a5,8(s0)
ffffffffc02033da:	20878a63          	beq	a5,s0,ffffffffc02035ee <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02033de:	4505                	li	a0,1
ffffffffc02033e0:	b87fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033e4:	30a99563          	bne	s3,a0,ffffffffc02036ee <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02033e8:	4505                	li	a0,1
ffffffffc02033ea:	b7dfd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02033ee:	2e051063          	bnez	a0,ffffffffc02036ce <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02033f2:	481c                	lw	a5,16(s0)
ffffffffc02033f4:	2a079d63          	bnez	a5,ffffffffc02036ae <default_check+0x422>
    free_page(p);
ffffffffc02033f8:	854e                	mv	a0,s3
ffffffffc02033fa:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02033fc:	01843023          	sd	s8,0(s0)
ffffffffc0203400:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0203404:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0203408:	b9dfd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_page(p1);
ffffffffc020340c:	4585                	li	a1,1
ffffffffc020340e:	8556                	mv	a0,s5
ffffffffc0203410:	b95fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_page(p2);
ffffffffc0203414:	4585                	li	a1,1
ffffffffc0203416:	8552                	mv	a0,s4
ffffffffc0203418:	b8dfd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020341c:	4515                	li	a0,5
ffffffffc020341e:	b49fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203422:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0203424:	26050563          	beqz	a0,ffffffffc020368e <default_check+0x402>
ffffffffc0203428:	651c                	ld	a5,8(a0)
ffffffffc020342a:	8385                	srli	a5,a5,0x1
ffffffffc020342c:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020342e:	54079063          	bnez	a5,ffffffffc020396e <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0203432:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0203434:	00043b03          	ld	s6,0(s0)
ffffffffc0203438:	00843a83          	ld	s5,8(s0)
ffffffffc020343c:	e000                	sd	s0,0(s0)
ffffffffc020343e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0203440:	b27fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203444:	50051563          	bnez	a0,ffffffffc020394e <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0203448:	08098a13          	addi	s4,s3,128
ffffffffc020344c:	8552                	mv	a0,s4
ffffffffc020344e:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0203450:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0203454:	000bf797          	auipc	a5,0xbf
ffffffffc0203458:	5a07ae23          	sw	zero,1468(a5) # ffffffffc02c2a10 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020345c:	b49fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0203460:	4511                	li	a0,4
ffffffffc0203462:	b05fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203466:	4c051463          	bnez	a0,ffffffffc020392e <default_check+0x6a2>
ffffffffc020346a:	0889b783          	ld	a5,136(s3)
ffffffffc020346e:	8385                	srli	a5,a5,0x1
ffffffffc0203470:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203472:	48078e63          	beqz	a5,ffffffffc020390e <default_check+0x682>
ffffffffc0203476:	0909a703          	lw	a4,144(s3)
ffffffffc020347a:	478d                	li	a5,3
ffffffffc020347c:	48f71963          	bne	a4,a5,ffffffffc020390e <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203480:	450d                	li	a0,3
ffffffffc0203482:	ae5fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203486:	8c2a                	mv	s8,a0
ffffffffc0203488:	46050363          	beqz	a0,ffffffffc02038ee <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020348c:	4505                	li	a0,1
ffffffffc020348e:	ad9fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203492:	42051e63          	bnez	a0,ffffffffc02038ce <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0203496:	418a1c63          	bne	s4,s8,ffffffffc02038ae <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020349a:	4585                	li	a1,1
ffffffffc020349c:	854e                	mv	a0,s3
ffffffffc020349e:	b07fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_pages(p1, 3);
ffffffffc02034a2:	458d                	li	a1,3
ffffffffc02034a4:	8552                	mv	a0,s4
ffffffffc02034a6:	afffd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
ffffffffc02034aa:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02034ae:	04098c13          	addi	s8,s3,64
ffffffffc02034b2:	8385                	srli	a5,a5,0x1
ffffffffc02034b4:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02034b6:	3c078c63          	beqz	a5,ffffffffc020388e <default_check+0x602>
ffffffffc02034ba:	0109a703          	lw	a4,16(s3)
ffffffffc02034be:	4785                	li	a5,1
ffffffffc02034c0:	3cf71763          	bne	a4,a5,ffffffffc020388e <default_check+0x602>
ffffffffc02034c4:	008a3783          	ld	a5,8(s4) # 1008 <_binary_obj___user_faultread_out_size-0x8f30>
ffffffffc02034c8:	8385                	srli	a5,a5,0x1
ffffffffc02034ca:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02034cc:	3a078163          	beqz	a5,ffffffffc020386e <default_check+0x5e2>
ffffffffc02034d0:	010a2703          	lw	a4,16(s4)
ffffffffc02034d4:	478d                	li	a5,3
ffffffffc02034d6:	38f71c63          	bne	a4,a5,ffffffffc020386e <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02034da:	4505                	li	a0,1
ffffffffc02034dc:	a8bfd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02034e0:	36a99763          	bne	s3,a0,ffffffffc020384e <default_check+0x5c2>
    free_page(p0);
ffffffffc02034e4:	4585                	li	a1,1
ffffffffc02034e6:	abffd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02034ea:	4509                	li	a0,2
ffffffffc02034ec:	a7bfd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02034f0:	32aa1f63          	bne	s4,a0,ffffffffc020382e <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02034f4:	4589                	li	a1,2
ffffffffc02034f6:	aaffd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    free_page(p2);
ffffffffc02034fa:	4585                	li	a1,1
ffffffffc02034fc:	8562                	mv	a0,s8
ffffffffc02034fe:	aa7fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203502:	4515                	li	a0,5
ffffffffc0203504:	a63fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203508:	89aa                	mv	s3,a0
ffffffffc020350a:	48050263          	beqz	a0,ffffffffc020398e <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020350e:	4505                	li	a0,1
ffffffffc0203510:	a57fd0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0203514:	2c051d63          	bnez	a0,ffffffffc02037ee <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0203518:	481c                	lw	a5,16(s0)
ffffffffc020351a:	2a079a63          	bnez	a5,ffffffffc02037ce <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020351e:	4595                	li	a1,5
ffffffffc0203520:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0203522:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0203526:	01643023          	sd	s6,0(s0)
ffffffffc020352a:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020352e:	a77fd0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    return listelm->next;
ffffffffc0203532:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0203534:	00878963          	beq	a5,s0,ffffffffc0203546 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0203538:	ff87a703          	lw	a4,-8(a5)
ffffffffc020353c:	679c                	ld	a5,8(a5)
ffffffffc020353e:	397d                	addiw	s2,s2,-1
ffffffffc0203540:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0203542:	fe879be3          	bne	a5,s0,ffffffffc0203538 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0203546:	26091463          	bnez	s2,ffffffffc02037ae <default_check+0x522>
    assert(total == 0);
ffffffffc020354a:	46049263          	bnez	s1,ffffffffc02039ae <default_check+0x722>
}
ffffffffc020354e:	60a6                	ld	ra,72(sp)
ffffffffc0203550:	6406                	ld	s0,64(sp)
ffffffffc0203552:	74e2                	ld	s1,56(sp)
ffffffffc0203554:	7942                	ld	s2,48(sp)
ffffffffc0203556:	79a2                	ld	s3,40(sp)
ffffffffc0203558:	7a02                	ld	s4,32(sp)
ffffffffc020355a:	6ae2                	ld	s5,24(sp)
ffffffffc020355c:	6b42                	ld	s6,16(sp)
ffffffffc020355e:	6ba2                	ld	s7,8(sp)
ffffffffc0203560:	6c02                	ld	s8,0(sp)
ffffffffc0203562:	6161                	addi	sp,sp,80
ffffffffc0203564:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0203566:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203568:	4481                	li	s1,0
ffffffffc020356a:	4901                	li	s2,0
ffffffffc020356c:	b38d                	j	ffffffffc02032ce <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020356e:	00004697          	auipc	a3,0x4
ffffffffc0203572:	80a68693          	addi	a3,a3,-2038 # ffffffffc0206d78 <commands+0x11f8>
ffffffffc0203576:	00003617          	auipc	a2,0x3
ffffffffc020357a:	eda60613          	addi	a2,a2,-294 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020357e:	11000593          	li	a1,272
ffffffffc0203582:	00004517          	auipc	a0,0x4
ffffffffc0203586:	80650513          	addi	a0,a0,-2042 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020358a:	c99fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020358e:	00004697          	auipc	a3,0x4
ffffffffc0203592:	89268693          	addi	a3,a3,-1902 # ffffffffc0206e20 <commands+0x12a0>
ffffffffc0203596:	00003617          	auipc	a2,0x3
ffffffffc020359a:	eba60613          	addi	a2,a2,-326 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020359e:	0db00593          	li	a1,219
ffffffffc02035a2:	00003517          	auipc	a0,0x3
ffffffffc02035a6:	7e650513          	addi	a0,a0,2022 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02035aa:	c79fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02035ae:	00004697          	auipc	a3,0x4
ffffffffc02035b2:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206e48 <commands+0x12c8>
ffffffffc02035b6:	00003617          	auipc	a2,0x3
ffffffffc02035ba:	e9a60613          	addi	a2,a2,-358 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02035be:	0dc00593          	li	a1,220
ffffffffc02035c2:	00003517          	auipc	a0,0x3
ffffffffc02035c6:	7c650513          	addi	a0,a0,1990 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02035ca:	c59fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02035ce:	00004697          	auipc	a3,0x4
ffffffffc02035d2:	8ba68693          	addi	a3,a3,-1862 # ffffffffc0206e88 <commands+0x1308>
ffffffffc02035d6:	00003617          	auipc	a2,0x3
ffffffffc02035da:	e7a60613          	addi	a2,a2,-390 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02035de:	0de00593          	li	a1,222
ffffffffc02035e2:	00003517          	auipc	a0,0x3
ffffffffc02035e6:	7a650513          	addi	a0,a0,1958 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02035ea:	c39fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02035ee:	00004697          	auipc	a3,0x4
ffffffffc02035f2:	92268693          	addi	a3,a3,-1758 # ffffffffc0206f10 <commands+0x1390>
ffffffffc02035f6:	00003617          	auipc	a2,0x3
ffffffffc02035fa:	e5a60613          	addi	a2,a2,-422 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02035fe:	0f700593          	li	a1,247
ffffffffc0203602:	00003517          	auipc	a0,0x3
ffffffffc0203606:	78650513          	addi	a0,a0,1926 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020360a:	c19fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020360e:	00003697          	auipc	a3,0x3
ffffffffc0203612:	7b268693          	addi	a3,a3,1970 # ffffffffc0206dc0 <commands+0x1240>
ffffffffc0203616:	00003617          	auipc	a2,0x3
ffffffffc020361a:	e3a60613          	addi	a2,a2,-454 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020361e:	0f000593          	li	a1,240
ffffffffc0203622:	00003517          	auipc	a0,0x3
ffffffffc0203626:	76650513          	addi	a0,a0,1894 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020362a:	bf9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_free == 3);
ffffffffc020362e:	00004697          	auipc	a3,0x4
ffffffffc0203632:	8d268693          	addi	a3,a3,-1838 # ffffffffc0206f00 <commands+0x1380>
ffffffffc0203636:	00003617          	auipc	a2,0x3
ffffffffc020363a:	e1a60613          	addi	a2,a2,-486 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020363e:	0ee00593          	li	a1,238
ffffffffc0203642:	00003517          	auipc	a0,0x3
ffffffffc0203646:	74650513          	addi	a0,a0,1862 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020364a:	bd9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020364e:	00004697          	auipc	a3,0x4
ffffffffc0203652:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc0203656:	00003617          	auipc	a2,0x3
ffffffffc020365a:	dfa60613          	addi	a2,a2,-518 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020365e:	0e900593          	li	a1,233
ffffffffc0203662:	00003517          	auipc	a0,0x3
ffffffffc0203666:	72650513          	addi	a0,a0,1830 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020366a:	bb9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020366e:	00004697          	auipc	a3,0x4
ffffffffc0203672:	85a68693          	addi	a3,a3,-1958 # ffffffffc0206ec8 <commands+0x1348>
ffffffffc0203676:	00003617          	auipc	a2,0x3
ffffffffc020367a:	dda60613          	addi	a2,a2,-550 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020367e:	0e000593          	li	a1,224
ffffffffc0203682:	00003517          	auipc	a0,0x3
ffffffffc0203686:	70650513          	addi	a0,a0,1798 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020368a:	b99fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(p0 != NULL);
ffffffffc020368e:	00004697          	auipc	a3,0x4
ffffffffc0203692:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0206f58 <commands+0x13d8>
ffffffffc0203696:	00003617          	auipc	a2,0x3
ffffffffc020369a:	dba60613          	addi	a2,a2,-582 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020369e:	11800593          	li	a1,280
ffffffffc02036a2:	00003517          	auipc	a0,0x3
ffffffffc02036a6:	6e650513          	addi	a0,a0,1766 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02036aa:	b79fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_free == 0);
ffffffffc02036ae:	00004697          	auipc	a3,0x4
ffffffffc02036b2:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206f48 <commands+0x13c8>
ffffffffc02036b6:	00003617          	auipc	a2,0x3
ffffffffc02036ba:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02036be:	0fd00593          	li	a1,253
ffffffffc02036c2:	00003517          	auipc	a0,0x3
ffffffffc02036c6:	6c650513          	addi	a0,a0,1734 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02036ca:	b59fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02036ce:	00004697          	auipc	a3,0x4
ffffffffc02036d2:	81a68693          	addi	a3,a3,-2022 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc02036d6:	00003617          	auipc	a2,0x3
ffffffffc02036da:	d7a60613          	addi	a2,a2,-646 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02036de:	0fb00593          	li	a1,251
ffffffffc02036e2:	00003517          	auipc	a0,0x3
ffffffffc02036e6:	6a650513          	addi	a0,a0,1702 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02036ea:	b39fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02036ee:	00004697          	auipc	a3,0x4
ffffffffc02036f2:	83a68693          	addi	a3,a3,-1990 # ffffffffc0206f28 <commands+0x13a8>
ffffffffc02036f6:	00003617          	auipc	a2,0x3
ffffffffc02036fa:	d5a60613          	addi	a2,a2,-678 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02036fe:	0fa00593          	li	a1,250
ffffffffc0203702:	00003517          	auipc	a0,0x3
ffffffffc0203706:	68650513          	addi	a0,a0,1670 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020370a:	b19fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020370e:	00003697          	auipc	a3,0x3
ffffffffc0203712:	6b268693          	addi	a3,a3,1714 # ffffffffc0206dc0 <commands+0x1240>
ffffffffc0203716:	00003617          	auipc	a2,0x3
ffffffffc020371a:	d3a60613          	addi	a2,a2,-710 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020371e:	0d700593          	li	a1,215
ffffffffc0203722:	00003517          	auipc	a0,0x3
ffffffffc0203726:	66650513          	addi	a0,a0,1638 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020372a:	af9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020372e:	00003697          	auipc	a3,0x3
ffffffffc0203732:	7ba68693          	addi	a3,a3,1978 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc0203736:	00003617          	auipc	a2,0x3
ffffffffc020373a:	d1a60613          	addi	a2,a2,-742 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020373e:	0f400593          	li	a1,244
ffffffffc0203742:	00003517          	auipc	a0,0x3
ffffffffc0203746:	64650513          	addi	a0,a0,1606 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020374a:	ad9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020374e:	00003697          	auipc	a3,0x3
ffffffffc0203752:	6b268693          	addi	a3,a3,1714 # ffffffffc0206e00 <commands+0x1280>
ffffffffc0203756:	00003617          	auipc	a2,0x3
ffffffffc020375a:	cfa60613          	addi	a2,a2,-774 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020375e:	0f200593          	li	a1,242
ffffffffc0203762:	00003517          	auipc	a0,0x3
ffffffffc0203766:	62650513          	addi	a0,a0,1574 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020376a:	ab9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020376e:	00003697          	auipc	a3,0x3
ffffffffc0203772:	67268693          	addi	a3,a3,1650 # ffffffffc0206de0 <commands+0x1260>
ffffffffc0203776:	00003617          	auipc	a2,0x3
ffffffffc020377a:	cda60613          	addi	a2,a2,-806 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020377e:	0f100593          	li	a1,241
ffffffffc0203782:	00003517          	auipc	a0,0x3
ffffffffc0203786:	60650513          	addi	a0,a0,1542 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020378a:	a99fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020378e:	00003697          	auipc	a3,0x3
ffffffffc0203792:	67268693          	addi	a3,a3,1650 # ffffffffc0206e00 <commands+0x1280>
ffffffffc0203796:	00003617          	auipc	a2,0x3
ffffffffc020379a:	cba60613          	addi	a2,a2,-838 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020379e:	0d900593          	li	a1,217
ffffffffc02037a2:	00003517          	auipc	a0,0x3
ffffffffc02037a6:	5e650513          	addi	a0,a0,1510 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02037aa:	a79fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(count == 0);
ffffffffc02037ae:	00004697          	auipc	a3,0x4
ffffffffc02037b2:	8fa68693          	addi	a3,a3,-1798 # ffffffffc02070a8 <commands+0x1528>
ffffffffc02037b6:	00003617          	auipc	a2,0x3
ffffffffc02037ba:	c9a60613          	addi	a2,a2,-870 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02037be:	14600593          	li	a1,326
ffffffffc02037c2:	00003517          	auipc	a0,0x3
ffffffffc02037c6:	5c650513          	addi	a0,a0,1478 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02037ca:	a59fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_free == 0);
ffffffffc02037ce:	00003697          	auipc	a3,0x3
ffffffffc02037d2:	77a68693          	addi	a3,a3,1914 # ffffffffc0206f48 <commands+0x13c8>
ffffffffc02037d6:	00003617          	auipc	a2,0x3
ffffffffc02037da:	c7a60613          	addi	a2,a2,-902 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02037de:	13a00593          	li	a1,314
ffffffffc02037e2:	00003517          	auipc	a0,0x3
ffffffffc02037e6:	5a650513          	addi	a0,a0,1446 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02037ea:	a39fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02037ee:	00003697          	auipc	a3,0x3
ffffffffc02037f2:	6fa68693          	addi	a3,a3,1786 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	c5a60613          	addi	a2,a2,-934 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02037fe:	13800593          	li	a1,312
ffffffffc0203802:	00003517          	auipc	a0,0x3
ffffffffc0203806:	58650513          	addi	a0,a0,1414 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020380a:	a19fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020380e:	00003697          	auipc	a3,0x3
ffffffffc0203812:	69a68693          	addi	a3,a3,1690 # ffffffffc0206ea8 <commands+0x1328>
ffffffffc0203816:	00003617          	auipc	a2,0x3
ffffffffc020381a:	c3a60613          	addi	a2,a2,-966 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020381e:	0df00593          	li	a1,223
ffffffffc0203822:	00003517          	auipc	a0,0x3
ffffffffc0203826:	56650513          	addi	a0,a0,1382 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020382a:	9f9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020382e:	00004697          	auipc	a3,0x4
ffffffffc0203832:	83a68693          	addi	a3,a3,-1990 # ffffffffc0207068 <commands+0x14e8>
ffffffffc0203836:	00003617          	auipc	a2,0x3
ffffffffc020383a:	c1a60613          	addi	a2,a2,-998 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020383e:	13200593          	li	a1,306
ffffffffc0203842:	00003517          	auipc	a0,0x3
ffffffffc0203846:	54650513          	addi	a0,a0,1350 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020384a:	9d9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020384e:	00003697          	auipc	a3,0x3
ffffffffc0203852:	7fa68693          	addi	a3,a3,2042 # ffffffffc0207048 <commands+0x14c8>
ffffffffc0203856:	00003617          	auipc	a2,0x3
ffffffffc020385a:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020385e:	13000593          	li	a1,304
ffffffffc0203862:	00003517          	auipc	a0,0x3
ffffffffc0203866:	52650513          	addi	a0,a0,1318 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020386a:	9b9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020386e:	00003697          	auipc	a3,0x3
ffffffffc0203872:	7b268693          	addi	a3,a3,1970 # ffffffffc0207020 <commands+0x14a0>
ffffffffc0203876:	00003617          	auipc	a2,0x3
ffffffffc020387a:	bda60613          	addi	a2,a2,-1062 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020387e:	12e00593          	li	a1,302
ffffffffc0203882:	00003517          	auipc	a0,0x3
ffffffffc0203886:	50650513          	addi	a0,a0,1286 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020388a:	999fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020388e:	00003697          	auipc	a3,0x3
ffffffffc0203892:	76a68693          	addi	a3,a3,1898 # ffffffffc0206ff8 <commands+0x1478>
ffffffffc0203896:	00003617          	auipc	a2,0x3
ffffffffc020389a:	bba60613          	addi	a2,a2,-1094 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020389e:	12d00593          	li	a1,301
ffffffffc02038a2:	00003517          	auipc	a0,0x3
ffffffffc02038a6:	4e650513          	addi	a0,a0,1254 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02038aa:	979fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02038ae:	00003697          	auipc	a3,0x3
ffffffffc02038b2:	73a68693          	addi	a3,a3,1850 # ffffffffc0206fe8 <commands+0x1468>
ffffffffc02038b6:	00003617          	auipc	a2,0x3
ffffffffc02038ba:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02038be:	12800593          	li	a1,296
ffffffffc02038c2:	00003517          	auipc	a0,0x3
ffffffffc02038c6:	4c650513          	addi	a0,a0,1222 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02038ca:	959fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02038ce:	00003697          	auipc	a3,0x3
ffffffffc02038d2:	61a68693          	addi	a3,a3,1562 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc02038d6:	00003617          	auipc	a2,0x3
ffffffffc02038da:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02038de:	12700593          	li	a1,295
ffffffffc02038e2:	00003517          	auipc	a0,0x3
ffffffffc02038e6:	4a650513          	addi	a0,a0,1190 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02038ea:	939fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02038ee:	00003697          	auipc	a3,0x3
ffffffffc02038f2:	6da68693          	addi	a3,a3,1754 # ffffffffc0206fc8 <commands+0x1448>
ffffffffc02038f6:	00003617          	auipc	a2,0x3
ffffffffc02038fa:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02038fe:	12600593          	li	a1,294
ffffffffc0203902:	00003517          	auipc	a0,0x3
ffffffffc0203906:	48650513          	addi	a0,a0,1158 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020390a:	919fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020390e:	00003697          	auipc	a3,0x3
ffffffffc0203912:	68a68693          	addi	a3,a3,1674 # ffffffffc0206f98 <commands+0x1418>
ffffffffc0203916:	00003617          	auipc	a2,0x3
ffffffffc020391a:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020391e:	12500593          	li	a1,293
ffffffffc0203922:	00003517          	auipc	a0,0x3
ffffffffc0203926:	46650513          	addi	a0,a0,1126 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020392a:	8f9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020392e:	00003697          	auipc	a3,0x3
ffffffffc0203932:	65268693          	addi	a3,a3,1618 # ffffffffc0206f80 <commands+0x1400>
ffffffffc0203936:	00003617          	auipc	a2,0x3
ffffffffc020393a:	b1a60613          	addi	a2,a2,-1254 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020393e:	12400593          	li	a1,292
ffffffffc0203942:	00003517          	auipc	a0,0x3
ffffffffc0203946:	44650513          	addi	a0,a0,1094 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020394a:	8d9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020394e:	00003697          	auipc	a3,0x3
ffffffffc0203952:	59a68693          	addi	a3,a3,1434 # ffffffffc0206ee8 <commands+0x1368>
ffffffffc0203956:	00003617          	auipc	a2,0x3
ffffffffc020395a:	afa60613          	addi	a2,a2,-1286 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020395e:	11e00593          	li	a1,286
ffffffffc0203962:	00003517          	auipc	a0,0x3
ffffffffc0203966:	42650513          	addi	a0,a0,1062 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020396a:	8b9fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(!PageProperty(p0));
ffffffffc020396e:	00003697          	auipc	a3,0x3
ffffffffc0203972:	5fa68693          	addi	a3,a3,1530 # ffffffffc0206f68 <commands+0x13e8>
ffffffffc0203976:	00003617          	auipc	a2,0x3
ffffffffc020397a:	ada60613          	addi	a2,a2,-1318 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020397e:	11900593          	li	a1,281
ffffffffc0203982:	00003517          	auipc	a0,0x3
ffffffffc0203986:	40650513          	addi	a0,a0,1030 # ffffffffc0206d88 <commands+0x1208>
ffffffffc020398a:	899fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020398e:	00003697          	auipc	a3,0x3
ffffffffc0203992:	6fa68693          	addi	a3,a3,1786 # ffffffffc0207088 <commands+0x1508>
ffffffffc0203996:	00003617          	auipc	a2,0x3
ffffffffc020399a:	aba60613          	addi	a2,a2,-1350 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020399e:	13700593          	li	a1,311
ffffffffc02039a2:	00003517          	auipc	a0,0x3
ffffffffc02039a6:	3e650513          	addi	a0,a0,998 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02039aa:	879fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(total == 0);
ffffffffc02039ae:	00003697          	auipc	a3,0x3
ffffffffc02039b2:	70a68693          	addi	a3,a3,1802 # ffffffffc02070b8 <commands+0x1538>
ffffffffc02039b6:	00003617          	auipc	a2,0x3
ffffffffc02039ba:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02039be:	14700593          	li	a1,327
ffffffffc02039c2:	00003517          	auipc	a0,0x3
ffffffffc02039c6:	3c650513          	addi	a0,a0,966 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02039ca:	859fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(total == nr_free_pages());
ffffffffc02039ce:	00003697          	auipc	a3,0x3
ffffffffc02039d2:	3d268693          	addi	a3,a3,978 # ffffffffc0206da0 <commands+0x1220>
ffffffffc02039d6:	00003617          	auipc	a2,0x3
ffffffffc02039da:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02039de:	11300593          	li	a1,275
ffffffffc02039e2:	00003517          	auipc	a0,0x3
ffffffffc02039e6:	3a650513          	addi	a0,a0,934 # ffffffffc0206d88 <commands+0x1208>
ffffffffc02039ea:	839fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02039ee:	00003697          	auipc	a3,0x3
ffffffffc02039f2:	3f268693          	addi	a3,a3,1010 # ffffffffc0206de0 <commands+0x1260>
ffffffffc02039f6:	00003617          	auipc	a2,0x3
ffffffffc02039fa:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02039fe:	0d800593          	li	a1,216
ffffffffc0203a02:	00003517          	auipc	a0,0x3
ffffffffc0203a06:	38650513          	addi	a0,a0,902 # ffffffffc0206d88 <commands+0x1208>
ffffffffc0203a0a:	819fc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203a0e <default_free_pages>:
{
ffffffffc0203a0e:	1141                	addi	sp,sp,-16
ffffffffc0203a10:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203a12:	14058463          	beqz	a1,ffffffffc0203b5a <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0203a16:	00659693          	slli	a3,a1,0x6
ffffffffc0203a1a:	96aa                	add	a3,a3,a0
ffffffffc0203a1c:	87aa                	mv	a5,a0
ffffffffc0203a1e:	02d50263          	beq	a0,a3,ffffffffc0203a42 <default_free_pages+0x34>
ffffffffc0203a22:	6798                	ld	a4,8(a5)
ffffffffc0203a24:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203a26:	10071a63          	bnez	a4,ffffffffc0203b3a <default_free_pages+0x12c>
ffffffffc0203a2a:	6798                	ld	a4,8(a5)
ffffffffc0203a2c:	8b09                	andi	a4,a4,2
ffffffffc0203a2e:	10071663          	bnez	a4,ffffffffc0203b3a <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0203a32:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0203a36:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203a3a:	04078793          	addi	a5,a5,64
ffffffffc0203a3e:	fed792e3          	bne	a5,a3,ffffffffc0203a22 <default_free_pages+0x14>
    base->property = n;
ffffffffc0203a42:	2581                	sext.w	a1,a1
ffffffffc0203a44:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0203a46:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203a4a:	4789                	li	a5,2
ffffffffc0203a4c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203a50:	000bf697          	auipc	a3,0xbf
ffffffffc0203a54:	fb068693          	addi	a3,a3,-80 # ffffffffc02c2a00 <free_area>
ffffffffc0203a58:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203a5a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203a5c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203a60:	9db9                	addw	a1,a1,a4
ffffffffc0203a62:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0203a64:	0ad78463          	beq	a5,a3,ffffffffc0203b0c <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0203a68:	fe878713          	addi	a4,a5,-24
ffffffffc0203a6c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0203a70:	4581                	li	a1,0
            if (base < page)
ffffffffc0203a72:	00e56a63          	bltu	a0,a4,ffffffffc0203a86 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0203a76:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0203a78:	04d70c63          	beq	a4,a3,ffffffffc0203ad0 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0203a7c:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203a7e:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0203a82:	fee57ae3          	bgeu	a0,a4,ffffffffc0203a76 <default_free_pages+0x68>
ffffffffc0203a86:	c199                	beqz	a1,ffffffffc0203a8c <default_free_pages+0x7e>
ffffffffc0203a88:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203a8c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203a8e:	e390                	sd	a2,0(a5)
ffffffffc0203a90:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203a92:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203a94:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0203a96:	00d70d63          	beq	a4,a3,ffffffffc0203ab0 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0203a9a:	ff872583          	lw	a1,-8(a4) # ff8 <_binary_obj___user_faultread_out_size-0x8f40>
        p = le2page(le, page_link);
ffffffffc0203a9e:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0203aa2:	02059813          	slli	a6,a1,0x20
ffffffffc0203aa6:	01a85793          	srli	a5,a6,0x1a
ffffffffc0203aaa:	97b2                	add	a5,a5,a2
ffffffffc0203aac:	02f50c63          	beq	a0,a5,ffffffffc0203ae4 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0203ab0:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0203ab2:	00d78c63          	beq	a5,a3,ffffffffc0203aca <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0203ab6:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0203ab8:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0203abc:	02061593          	slli	a1,a2,0x20
ffffffffc0203ac0:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0203ac4:	972a                	add	a4,a4,a0
ffffffffc0203ac6:	04e68a63          	beq	a3,a4,ffffffffc0203b1a <default_free_pages+0x10c>
}
ffffffffc0203aca:	60a2                	ld	ra,8(sp)
ffffffffc0203acc:	0141                	addi	sp,sp,16
ffffffffc0203ace:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203ad0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203ad2:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0203ad4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203ad6:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0203ad8:	02d70763          	beq	a4,a3,ffffffffc0203b06 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0203adc:	8832                	mv	a6,a2
ffffffffc0203ade:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0203ae0:	87ba                	mv	a5,a4
ffffffffc0203ae2:	bf71                	j	ffffffffc0203a7e <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0203ae4:	491c                	lw	a5,16(a0)
ffffffffc0203ae6:	9dbd                	addw	a1,a1,a5
ffffffffc0203ae8:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203aec:	57f5                	li	a5,-3
ffffffffc0203aee:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203af2:	01853803          	ld	a6,24(a0)
ffffffffc0203af6:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0203af8:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0203afa:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0203afe:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0203b00:	0105b023          	sd	a6,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x8f38>
ffffffffc0203b04:	b77d                	j	ffffffffc0203ab2 <default_free_pages+0xa4>
ffffffffc0203b06:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0203b08:	873e                	mv	a4,a5
ffffffffc0203b0a:	bf41                	j	ffffffffc0203a9a <default_free_pages+0x8c>
}
ffffffffc0203b0c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203b0e:	e390                	sd	a2,0(a5)
ffffffffc0203b10:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203b12:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203b14:	ed1c                	sd	a5,24(a0)
ffffffffc0203b16:	0141                	addi	sp,sp,16
ffffffffc0203b18:	8082                	ret
            base->property += p->property;
ffffffffc0203b1a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203b1e:	ff078693          	addi	a3,a5,-16
ffffffffc0203b22:	9e39                	addw	a2,a2,a4
ffffffffc0203b24:	c910                	sw	a2,16(a0)
ffffffffc0203b26:	5775                	li	a4,-3
ffffffffc0203b28:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203b2c:	6398                	ld	a4,0(a5)
ffffffffc0203b2e:	679c                	ld	a5,8(a5)
}
ffffffffc0203b30:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203b32:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203b34:	e398                	sd	a4,0(a5)
ffffffffc0203b36:	0141                	addi	sp,sp,16
ffffffffc0203b38:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203b3a:	00003697          	auipc	a3,0x3
ffffffffc0203b3e:	59668693          	addi	a3,a3,1430 # ffffffffc02070d0 <commands+0x1550>
ffffffffc0203b42:	00003617          	auipc	a2,0x3
ffffffffc0203b46:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203b4a:	09400593          	li	a1,148
ffffffffc0203b4e:	00003517          	auipc	a0,0x3
ffffffffc0203b52:	23a50513          	addi	a0,a0,570 # ffffffffc0206d88 <commands+0x1208>
ffffffffc0203b56:	eccfc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(n > 0);
ffffffffc0203b5a:	00003697          	auipc	a3,0x3
ffffffffc0203b5e:	56e68693          	addi	a3,a3,1390 # ffffffffc02070c8 <commands+0x1548>
ffffffffc0203b62:	00003617          	auipc	a2,0x3
ffffffffc0203b66:	8ee60613          	addi	a2,a2,-1810 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203b6a:	09000593          	li	a1,144
ffffffffc0203b6e:	00003517          	auipc	a0,0x3
ffffffffc0203b72:	21a50513          	addi	a0,a0,538 # ffffffffc0206d88 <commands+0x1208>
ffffffffc0203b76:	eacfc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203b7a <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203b7a:	c941                	beqz	a0,ffffffffc0203c0a <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0203b7c:	000bf597          	auipc	a1,0xbf
ffffffffc0203b80:	e8458593          	addi	a1,a1,-380 # ffffffffc02c2a00 <free_area>
ffffffffc0203b84:	0105a803          	lw	a6,16(a1)
ffffffffc0203b88:	872a                	mv	a4,a0
ffffffffc0203b8a:	02081793          	slli	a5,a6,0x20
ffffffffc0203b8e:	9381                	srli	a5,a5,0x20
ffffffffc0203b90:	00a7ee63          	bltu	a5,a0,ffffffffc0203bac <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203b94:	87ae                	mv	a5,a1
ffffffffc0203b96:	a801                	j	ffffffffc0203ba6 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0203b98:	ff87a683          	lw	a3,-8(a5)
ffffffffc0203b9c:	02069613          	slli	a2,a3,0x20
ffffffffc0203ba0:	9201                	srli	a2,a2,0x20
ffffffffc0203ba2:	00e67763          	bgeu	a2,a4,ffffffffc0203bb0 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203ba6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0203ba8:	feb798e3          	bne	a5,a1,ffffffffc0203b98 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203bac:	4501                	li	a0,0
}
ffffffffc0203bae:	8082                	ret
    return listelm->prev;
ffffffffc0203bb0:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203bb4:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0203bb8:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0203bbc:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0203bc0:	0068b423          	sd	t1,8(a7) # 1008 <_binary_obj___user_faultread_out_size-0x8f30>
    next->prev = prev;
ffffffffc0203bc4:	01133023          	sd	a7,0(t1) # 80000 <_binary_obj___user_matrix_out_size+0x73900>
        if (page->property > n)
ffffffffc0203bc8:	02c77863          	bgeu	a4,a2,ffffffffc0203bf8 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0203bcc:	071a                	slli	a4,a4,0x6
ffffffffc0203bce:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0203bd0:	41c686bb          	subw	a3,a3,t3
ffffffffc0203bd4:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203bd6:	00870613          	addi	a2,a4,8
ffffffffc0203bda:	4689                	li	a3,2
ffffffffc0203bdc:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203be0:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203be4:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0203be8:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0203bec:	e290                	sd	a2,0(a3)
ffffffffc0203bee:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0203bf2:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0203bf4:	01173c23          	sd	a7,24(a4)
ffffffffc0203bf8:	41c8083b          	subw	a6,a6,t3
ffffffffc0203bfc:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203c00:	5775                	li	a4,-3
ffffffffc0203c02:	17c1                	addi	a5,a5,-16
ffffffffc0203c04:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0203c08:	8082                	ret
{
ffffffffc0203c0a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203c0c:	00003697          	auipc	a3,0x3
ffffffffc0203c10:	4bc68693          	addi	a3,a3,1212 # ffffffffc02070c8 <commands+0x1548>
ffffffffc0203c14:	00003617          	auipc	a2,0x3
ffffffffc0203c18:	83c60613          	addi	a2,a2,-1988 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203c1c:	06c00593          	li	a1,108
ffffffffc0203c20:	00003517          	auipc	a0,0x3
ffffffffc0203c24:	16850513          	addi	a0,a0,360 # ffffffffc0206d88 <commands+0x1208>
{
ffffffffc0203c28:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203c2a:	df8fc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203c2e <default_init_memmap>:
{
ffffffffc0203c2e:	1141                	addi	sp,sp,-16
ffffffffc0203c30:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203c32:	c5f1                	beqz	a1,ffffffffc0203cfe <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0203c34:	00659693          	slli	a3,a1,0x6
ffffffffc0203c38:	96aa                	add	a3,a3,a0
ffffffffc0203c3a:	87aa                	mv	a5,a0
ffffffffc0203c3c:	00d50f63          	beq	a0,a3,ffffffffc0203c5a <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203c40:	6798                	ld	a4,8(a5)
ffffffffc0203c42:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0203c44:	cf49                	beqz	a4,ffffffffc0203cde <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0203c46:	0007a823          	sw	zero,16(a5)
ffffffffc0203c4a:	0007b423          	sd	zero,8(a5)
ffffffffc0203c4e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203c52:	04078793          	addi	a5,a5,64
ffffffffc0203c56:	fed795e3          	bne	a5,a3,ffffffffc0203c40 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0203c5a:	2581                	sext.w	a1,a1
ffffffffc0203c5c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203c5e:	4789                	li	a5,2
ffffffffc0203c60:	00850713          	addi	a4,a0,8
ffffffffc0203c64:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203c68:	000bf697          	auipc	a3,0xbf
ffffffffc0203c6c:	d9868693          	addi	a3,a3,-616 # ffffffffc02c2a00 <free_area>
ffffffffc0203c70:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203c72:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203c74:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203c78:	9db9                	addw	a1,a1,a4
ffffffffc0203c7a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0203c7c:	04d78a63          	beq	a5,a3,ffffffffc0203cd0 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0203c80:	fe878713          	addi	a4,a5,-24
ffffffffc0203c84:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0203c88:	4581                	li	a1,0
            if (base < page)
ffffffffc0203c8a:	00e56a63          	bltu	a0,a4,ffffffffc0203c9e <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0203c8e:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0203c90:	02d70263          	beq	a4,a3,ffffffffc0203cb4 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0203c94:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203c96:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0203c9a:	fee57ae3          	bgeu	a0,a4,ffffffffc0203c8e <default_init_memmap+0x60>
ffffffffc0203c9e:	c199                	beqz	a1,ffffffffc0203ca4 <default_init_memmap+0x76>
ffffffffc0203ca0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203ca4:	6398                	ld	a4,0(a5)
}
ffffffffc0203ca6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203ca8:	e390                	sd	a2,0(a5)
ffffffffc0203caa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203cac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203cae:	ed18                	sd	a4,24(a0)
ffffffffc0203cb0:	0141                	addi	sp,sp,16
ffffffffc0203cb2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203cb4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203cb6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0203cb8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203cba:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0203cbc:	00d70663          	beq	a4,a3,ffffffffc0203cc8 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0203cc0:	8832                	mv	a6,a2
ffffffffc0203cc2:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0203cc4:	87ba                	mv	a5,a4
ffffffffc0203cc6:	bfc1                	j	ffffffffc0203c96 <default_init_memmap+0x68>
}
ffffffffc0203cc8:	60a2                	ld	ra,8(sp)
ffffffffc0203cca:	e290                	sd	a2,0(a3)
ffffffffc0203ccc:	0141                	addi	sp,sp,16
ffffffffc0203cce:	8082                	ret
ffffffffc0203cd0:	60a2                	ld	ra,8(sp)
ffffffffc0203cd2:	e390                	sd	a2,0(a5)
ffffffffc0203cd4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203cd6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203cd8:	ed1c                	sd	a5,24(a0)
ffffffffc0203cda:	0141                	addi	sp,sp,16
ffffffffc0203cdc:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203cde:	00003697          	auipc	a3,0x3
ffffffffc0203ce2:	41a68693          	addi	a3,a3,1050 # ffffffffc02070f8 <commands+0x1578>
ffffffffc0203ce6:	00002617          	auipc	a2,0x2
ffffffffc0203cea:	76a60613          	addi	a2,a2,1898 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203cee:	04b00593          	li	a1,75
ffffffffc0203cf2:	00003517          	auipc	a0,0x3
ffffffffc0203cf6:	09650513          	addi	a0,a0,150 # ffffffffc0206d88 <commands+0x1208>
ffffffffc0203cfa:	d28fc0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(n > 0);
ffffffffc0203cfe:	00003697          	auipc	a3,0x3
ffffffffc0203d02:	3ca68693          	addi	a3,a3,970 # ffffffffc02070c8 <commands+0x1548>
ffffffffc0203d06:	00002617          	auipc	a2,0x2
ffffffffc0203d0a:	74a60613          	addi	a2,a2,1866 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0203d0e:	04700593          	li	a1,71
ffffffffc0203d12:	00003517          	auipc	a0,0x3
ffffffffc0203d16:	07650513          	addi	a0,a0,118 # ffffffffc0206d88 <commands+0x1208>
ffffffffc0203d1a:	d08fc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203d1e <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203d1e:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203d20:	9402                	jalr	s0

	jal do_exit
ffffffffc0203d22:	628000ef          	jal	ra,ffffffffc020434a <do_exit>

ffffffffc0203d26 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203d26:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203d2a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203d2e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203d30:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203d32:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203d36:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203d3a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203d3e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203d42:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203d46:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203d4a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203d4e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203d52:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203d56:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203d5a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203d5e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0203d62:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0203d64:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0203d66:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203d6a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203d6e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203d72:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0203d76:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203d7a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203d7e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203d82:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0203d86:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203d8a:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203d8e:	8082                	ret

ffffffffc0203d90 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203d90:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d92:	14800513          	li	a0,328
{
ffffffffc0203d96:	e022                	sd	s0,0(sp)
ffffffffc0203d98:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d9a:	b2cff0ef          	jal	ra,ffffffffc02030c6 <kmalloc>
ffffffffc0203d9e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203da0:	c93d                	beqz	a0,ffffffffc0203e16 <alloc_proc+0x86>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203da2:	57fd                	li	a5,-1
ffffffffc0203da4:	1782                	slli	a5,a5,0x20
ffffffffc0203da6:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203da8:	07000613          	li	a2,112
ffffffffc0203dac:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0203dae:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203db2:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203db6:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203dba:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203dbe:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203dc2:	03050513          	addi	a0,a0,48
ffffffffc0203dc6:	6de010ef          	jal	ra,ffffffffc02054a4 <memset>
        proc->tf = NULL;
        proc->pgdir = 0;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203dca:	4641                	li	a2,16
        proc->tf = NULL;
ffffffffc0203dcc:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc0203dd0:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203dd4:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203dd8:	4581                	li	a1,0
ffffffffc0203dda:	0b440513          	addi	a0,s0,180
ffffffffc0203dde:	6c6010ef          	jal	ra,ffffffffc02054a4 <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203de2:	11040793          	addi	a5,s0,272
        proc->wait_state = 0;
ffffffffc0203de6:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;
ffffffffc0203dea:	0e043c23          	sd	zero,248(s0)
ffffffffc0203dee:	10043023          	sd	zero,256(s0)
ffffffffc0203df2:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203df6:	10043423          	sd	zero,264(s0)
    elm->prev = elm->next = elm;
ffffffffc0203dfa:	10f43c23          	sd	a5,280(s0)
ffffffffc0203dfe:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;
ffffffffc0203e02:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;
ffffffffc0203e06:	12043423          	sd	zero,296(s0)
ffffffffc0203e0a:	12043823          	sd	zero,304(s0)
ffffffffc0203e0e:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;
ffffffffc0203e12:	14043023          	sd	zero,320(s0)
        proc->lab6_priority = 0;
    }
    return proc;
}
ffffffffc0203e16:	60a2                	ld	ra,8(sp)
ffffffffc0203e18:	8522                	mv	a0,s0
ffffffffc0203e1a:	6402                	ld	s0,0(sp)
ffffffffc0203e1c:	0141                	addi	sp,sp,16
ffffffffc0203e1e:	8082                	ret

ffffffffc0203e20 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e20:	000c3797          	auipc	a5,0xc3
ffffffffc0203e24:	c907b783          	ld	a5,-880(a5) # ffffffffc02c6ab0 <current>
ffffffffc0203e28:	73c8                	ld	a0,160(a5)
ffffffffc0203e2a:	900fd06f          	j	ffffffffc0200f2a <forkrets>

ffffffffc0203e2e <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203e2e:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203e30:	1141                	addi	sp,sp,-16
ffffffffc0203e32:	e406                	sd	ra,8(sp)
ffffffffc0203e34:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e38:	02f6ee63          	bltu	a3,a5,ffffffffc0203e74 <put_pgdir+0x46>
ffffffffc0203e3c:	000c3517          	auipc	a0,0xc3
ffffffffc0203e40:	c6453503          	ld	a0,-924(a0) # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc0203e44:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203e46:	82b1                	srli	a3,a3,0xc
ffffffffc0203e48:	000c3797          	auipc	a5,0xc3
ffffffffc0203e4c:	c407b783          	ld	a5,-960(a5) # ffffffffc02c6a88 <npage>
ffffffffc0203e50:	02f6fe63          	bgeu	a3,a5,ffffffffc0203e8c <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203e54:	00004517          	auipc	a0,0x4
ffffffffc0203e58:	40c53503          	ld	a0,1036(a0) # ffffffffc0208260 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203e5c:	60a2                	ld	ra,8(sp)
ffffffffc0203e5e:	8e89                	sub	a3,a3,a0
ffffffffc0203e60:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203e62:	000c3517          	auipc	a0,0xc3
ffffffffc0203e66:	c2e53503          	ld	a0,-978(a0) # ffffffffc02c6a90 <pages>
ffffffffc0203e6a:	4585                	li	a1,1
ffffffffc0203e6c:	9536                	add	a0,a0,a3
}
ffffffffc0203e6e:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203e70:	934fd06f          	j	ffffffffc0200fa4 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203e74:	00002617          	auipc	a2,0x2
ffffffffc0203e78:	68460613          	addi	a2,a2,1668 # ffffffffc02064f8 <commands+0x978>
ffffffffc0203e7c:	07700593          	li	a1,119
ffffffffc0203e80:	00002517          	auipc	a0,0x2
ffffffffc0203e84:	53050513          	addi	a0,a0,1328 # ffffffffc02063b0 <commands+0x830>
ffffffffc0203e88:	b9afc0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203e8c:	00002617          	auipc	a2,0x2
ffffffffc0203e90:	50460613          	addi	a2,a2,1284 # ffffffffc0206390 <commands+0x810>
ffffffffc0203e94:	06900593          	li	a1,105
ffffffffc0203e98:	00002517          	auipc	a0,0x2
ffffffffc0203e9c:	51850513          	addi	a0,a0,1304 # ffffffffc02063b0 <commands+0x830>
ffffffffc0203ea0:	b82fc0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0203ea4 <proc_run>:
{
ffffffffc0203ea4:	7179                	addi	sp,sp,-48
ffffffffc0203ea6:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203ea8:	000c3917          	auipc	s2,0xc3
ffffffffc0203eac:	c0890913          	addi	s2,s2,-1016 # ffffffffc02c6ab0 <current>
{
ffffffffc0203eb0:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203eb2:	00093483          	ld	s1,0(s2)
{
ffffffffc0203eb6:	f406                	sd	ra,40(sp)
ffffffffc0203eb8:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203eba:	02a48b63          	beq	s1,a0,ffffffffc0203ef0 <proc_run+0x4c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203ebe:	100027f3          	csrr	a5,sstatus
ffffffffc0203ec2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203ec4:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203ec6:	e7b9                	bnez	a5,ffffffffc0203f14 <proc_run+0x70>
            if (next->pgdir) {
ffffffffc0203ec8:	755c                	ld	a5,168(a0)
            current = proc;
ffffffffc0203eca:	00a93023          	sd	a0,0(s2)
            if (next->pgdir) {
ffffffffc0203ece:	c79d                	beqz	a5,ffffffffc0203efc <proc_run+0x58>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203ed0:	577d                	li	a4,-1
ffffffffc0203ed2:	177e                	slli	a4,a4,0x3f
ffffffffc0203ed4:	83b1                	srli	a5,a5,0xc
ffffffffc0203ed6:	8fd9                	or	a5,a5,a4
ffffffffc0203ed8:	18079073          	csrw	satp,a5
            asm volatile("sfence.vma");
ffffffffc0203edc:	12000073          	sfence.vma
            switch_to(&(prev->context), &(next->context));
ffffffffc0203ee0:	03050593          	addi	a1,a0,48
ffffffffc0203ee4:	03048513          	addi	a0,s1,48
ffffffffc0203ee8:	e3fff0ef          	jal	ra,ffffffffc0203d26 <switch_to>
    if (flag)
ffffffffc0203eec:	00099d63          	bnez	s3,ffffffffc0203f06 <proc_run+0x62>
}
ffffffffc0203ef0:	70a2                	ld	ra,40(sp)
ffffffffc0203ef2:	7482                	ld	s1,32(sp)
ffffffffc0203ef4:	6962                	ld	s2,24(sp)
ffffffffc0203ef6:	69c2                	ld	s3,16(sp)
ffffffffc0203ef8:	6145                	addi	sp,sp,48
ffffffffc0203efa:	8082                	ret
ffffffffc0203efc:	000c3797          	auipc	a5,0xc3
ffffffffc0203f00:	b7c7b783          	ld	a5,-1156(a5) # ffffffffc02c6a78 <boot_pgdir_pa>
ffffffffc0203f04:	b7f1                	j	ffffffffc0203ed0 <proc_run+0x2c>
ffffffffc0203f06:	70a2                	ld	ra,40(sp)
ffffffffc0203f08:	7482                	ld	s1,32(sp)
ffffffffc0203f0a:	6962                	ld	s2,24(sp)
ffffffffc0203f0c:	69c2                	ld	s3,16(sp)
ffffffffc0203f0e:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f10:	a9ffc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203f14:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203f16:	a9ffc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0203f1a:	6522                	ld	a0,8(sp)
ffffffffc0203f1c:	4985                	li	s3,1
ffffffffc0203f1e:	b76d                	j	ffffffffc0203ec8 <proc_run+0x24>

ffffffffc0203f20 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203f20:	7119                	addi	sp,sp,-128
ffffffffc0203f22:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f24:	000c3917          	auipc	s2,0xc3
ffffffffc0203f28:	ba490913          	addi	s2,s2,-1116 # ffffffffc02c6ac8 <nr_process>
ffffffffc0203f2c:	00092703          	lw	a4,0(s2)
{
ffffffffc0203f30:	fc86                	sd	ra,120(sp)
ffffffffc0203f32:	f8a2                	sd	s0,112(sp)
ffffffffc0203f34:	f4a6                	sd	s1,104(sp)
ffffffffc0203f36:	ecce                	sd	s3,88(sp)
ffffffffc0203f38:	e8d2                	sd	s4,80(sp)
ffffffffc0203f3a:	e4d6                	sd	s5,72(sp)
ffffffffc0203f3c:	e0da                	sd	s6,64(sp)
ffffffffc0203f3e:	fc5e                	sd	s7,56(sp)
ffffffffc0203f40:	f862                	sd	s8,48(sp)
ffffffffc0203f42:	f466                	sd	s9,40(sp)
ffffffffc0203f44:	f06a                	sd	s10,32(sp)
ffffffffc0203f46:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f48:	6785                	lui	a5,0x1
ffffffffc0203f4a:	32f75663          	bge	a4,a5,ffffffffc0204276 <do_fork+0x356>
ffffffffc0203f4e:	8a2a                	mv	s4,a0
ffffffffc0203f50:	89ae                	mv	s3,a1
ffffffffc0203f52:	8432                	mv	s0,a2
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203f54:	e3dff0ef          	jal	ra,ffffffffc0203d90 <alloc_proc>
ffffffffc0203f58:	84aa                	mv	s1,a0
ffffffffc0203f5a:	2e050f63          	beqz	a0,ffffffffc0204258 <do_fork+0x338>
    {
        goto fork_out;
    }
    proc->parent = current;
ffffffffc0203f5e:	000c3c17          	auipc	s8,0xc3
ffffffffc0203f62:	b52c0c13          	addi	s8,s8,-1198 # ffffffffc02c6ab0 <current>
ffffffffc0203f66:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f6a:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203f6c:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f6e:	ff9fc0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
    if (page != NULL)
ffffffffc0203f72:	2e050063          	beqz	a0,ffffffffc0204252 <do_fork+0x332>
    return page - pages + nbase;
ffffffffc0203f76:	000c3a97          	auipc	s5,0xc3
ffffffffc0203f7a:	b1aa8a93          	addi	s5,s5,-1254 # ffffffffc02c6a90 <pages>
ffffffffc0203f7e:	000ab683          	ld	a3,0(s5)
ffffffffc0203f82:	00004b17          	auipc	s6,0x4
ffffffffc0203f86:	2deb0b13          	addi	s6,s6,734 # ffffffffc0208260 <nbase>
ffffffffc0203f8a:	000b3783          	ld	a5,0(s6)
ffffffffc0203f8e:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203f92:	000c3b97          	auipc	s7,0xc3
ffffffffc0203f96:	af6b8b93          	addi	s7,s7,-1290 # ffffffffc02c6a88 <npage>
    return page - pages + nbase;
ffffffffc0203f9a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203f9c:	5dfd                	li	s11,-1
ffffffffc0203f9e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0203fa2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203fa4:	00cddd93          	srli	s11,s11,0xc
ffffffffc0203fa8:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203fae:	32e67a63          	bgeu	a2,a4,ffffffffc02042e2 <do_fork+0x3c2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203fb2:	000c3603          	ld	a2,0(s8)
ffffffffc0203fb6:	000c3c17          	auipc	s8,0xc3
ffffffffc0203fba:	aeac0c13          	addi	s8,s8,-1302 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc0203fbe:	000c3703          	ld	a4,0(s8)
ffffffffc0203fc2:	02863d03          	ld	s10,40(a2)
ffffffffc0203fc6:	e43e                	sd	a5,8(sp)
ffffffffc0203fc8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203fca:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203fcc:	020d0863          	beqz	s10,ffffffffc0203ffc <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc0203fd0:	100a7a13          	andi	s4,s4,256
ffffffffc0203fd4:	1c0a0163          	beqz	s4,ffffffffc0204196 <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203fd8:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203fdc:	018d3783          	ld	a5,24(s10)
ffffffffc0203fe0:	c02006b7          	lui	a3,0xc0200
ffffffffc0203fe4:	2705                	addiw	a4,a4,1
ffffffffc0203fe6:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0203fea:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203fee:	2cd7e163          	bltu	a5,a3,ffffffffc02042b0 <do_fork+0x390>
ffffffffc0203ff2:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203ff6:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203ff8:	8f99                	sub	a5,a5,a4
ffffffffc0203ffa:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203ffc:	6789                	lui	a5,0x2
ffffffffc0203ffe:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8058>
ffffffffc0204002:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204004:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204006:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204008:	87b6                	mv	a5,a3
ffffffffc020400a:	12040893          	addi	a7,s0,288
ffffffffc020400e:	00063803          	ld	a6,0(a2)
ffffffffc0204012:	6608                	ld	a0,8(a2)
ffffffffc0204014:	6a0c                	ld	a1,16(a2)
ffffffffc0204016:	6e18                	ld	a4,24(a2)
ffffffffc0204018:	0107b023          	sd	a6,0(a5)
ffffffffc020401c:	e788                	sd	a0,8(a5)
ffffffffc020401e:	eb8c                	sd	a1,16(a5)
ffffffffc0204020:	ef98                	sd	a4,24(a5)
ffffffffc0204022:	02060613          	addi	a2,a2,32
ffffffffc0204026:	02078793          	addi	a5,a5,32
ffffffffc020402a:	ff1612e3          	bne	a2,a7,ffffffffc020400e <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020402e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204032:	12098f63          	beqz	s3,ffffffffc0204170 <do_fork+0x250>
ffffffffc0204036:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020403a:	00000797          	auipc	a5,0x0
ffffffffc020403e:	de678793          	addi	a5,a5,-538 # ffffffffc0203e20 <forkret>
ffffffffc0204042:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204044:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204046:	100027f3          	csrr	a5,sstatus
ffffffffc020404a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020404c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020404e:	14079063          	bnez	a5,ffffffffc020418e <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc0204052:	000be817          	auipc	a6,0xbe
ffffffffc0204056:	5a680813          	addi	a6,a6,1446 # ffffffffc02c25f8 <last_pid.1>
ffffffffc020405a:	00082783          	lw	a5,0(a6)
ffffffffc020405e:	6709                	lui	a4,0x2
ffffffffc0204060:	0017851b          	addiw	a0,a5,1
ffffffffc0204064:	00a82023          	sw	a0,0(a6)
ffffffffc0204068:	08e55d63          	bge	a0,a4,ffffffffc0204102 <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc020406c:	000be317          	auipc	t1,0xbe
ffffffffc0204070:	59030313          	addi	t1,t1,1424 # ffffffffc02c25fc <next_safe.0>
ffffffffc0204074:	00032783          	lw	a5,0(t1)
ffffffffc0204078:	000c3417          	auipc	s0,0xc3
ffffffffc020407c:	9a040413          	addi	s0,s0,-1632 # ffffffffc02c6a18 <proc_list>
ffffffffc0204080:	08f55963          	bge	a0,a5,ffffffffc0204112 <do_fork+0x1f2>

    //    5. insert proc_struct into hash_list && proc_list
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc0204084:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204086:	45a9                	li	a1,10
ffffffffc0204088:	2501                	sext.w	a0,a0
ffffffffc020408a:	033010ef          	jal	ra,ffffffffc02058bc <hash32>
ffffffffc020408e:	02051793          	slli	a5,a0,0x20
ffffffffc0204092:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204096:	000bf797          	auipc	a5,0xbf
ffffffffc020409a:	98278793          	addi	a5,a5,-1662 # ffffffffc02c2a18 <hash_list>
ffffffffc020409e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02040a0:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040a2:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02040a4:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02040a8:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02040aa:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02040ac:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040ae:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02040b0:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02040b4:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02040b6:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02040b8:	e21c                	sd	a5,0(a2)
ffffffffc02040ba:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02040bc:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02040be:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02040c0:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040c4:	10e4b023          	sd	a4,256(s1)
ffffffffc02040c8:	c311                	beqz	a4,ffffffffc02040cc <do_fork+0x1ac>
        proc->optr->yptr = proc;
ffffffffc02040ca:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02040cc:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02040d0:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02040d2:	2785                	addiw	a5,a5,1
ffffffffc02040d4:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02040d8:	18099263          	bnez	s3,ffffffffc020425c <do_fork+0x33c>
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    //    6. call wakeup_proc to make the new child process RUNNABLE
    wakeup_proc(proc);
ffffffffc02040dc:	8526                	mv	a0,s1
ffffffffc02040de:	7af000ef          	jal	ra,ffffffffc020508c <wakeup_proc>

    //    7. set ret vaule using child proc's pid
    ret = proc->pid;
ffffffffc02040e2:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc02040e4:	70e6                	ld	ra,120(sp)
ffffffffc02040e6:	7446                	ld	s0,112(sp)
ffffffffc02040e8:	74a6                	ld	s1,104(sp)
ffffffffc02040ea:	7906                	ld	s2,96(sp)
ffffffffc02040ec:	69e6                	ld	s3,88(sp)
ffffffffc02040ee:	6a46                	ld	s4,80(sp)
ffffffffc02040f0:	6aa6                	ld	s5,72(sp)
ffffffffc02040f2:	6b06                	ld	s6,64(sp)
ffffffffc02040f4:	7be2                	ld	s7,56(sp)
ffffffffc02040f6:	7c42                	ld	s8,48(sp)
ffffffffc02040f8:	7ca2                	ld	s9,40(sp)
ffffffffc02040fa:	7d02                	ld	s10,32(sp)
ffffffffc02040fc:	6de2                	ld	s11,24(sp)
ffffffffc02040fe:	6109                	addi	sp,sp,128
ffffffffc0204100:	8082                	ret
        last_pid = 1;
ffffffffc0204102:	4785                	li	a5,1
ffffffffc0204104:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204108:	4505                	li	a0,1
ffffffffc020410a:	000be317          	auipc	t1,0xbe
ffffffffc020410e:	4f230313          	addi	t1,t1,1266 # ffffffffc02c25fc <next_safe.0>
    return listelm->next;
ffffffffc0204112:	000c3417          	auipc	s0,0xc3
ffffffffc0204116:	90640413          	addi	s0,s0,-1786 # ffffffffc02c6a18 <proc_list>
ffffffffc020411a:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020411e:	6789                	lui	a5,0x2
ffffffffc0204120:	00f32023          	sw	a5,0(t1)
ffffffffc0204124:	86aa                	mv	a3,a0
ffffffffc0204126:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204128:	6e89                	lui	t4,0x2
ffffffffc020412a:	148e0163          	beq	t3,s0,ffffffffc020426c <do_fork+0x34c>
ffffffffc020412e:	88ae                	mv	a7,a1
ffffffffc0204130:	87f2                	mv	a5,t3
ffffffffc0204132:	6609                	lui	a2,0x2
ffffffffc0204134:	a811                	j	ffffffffc0204148 <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204136:	00e6d663          	bge	a3,a4,ffffffffc0204142 <do_fork+0x222>
ffffffffc020413a:	00c75463          	bge	a4,a2,ffffffffc0204142 <do_fork+0x222>
ffffffffc020413e:	863a                	mv	a2,a4
ffffffffc0204140:	4885                	li	a7,1
ffffffffc0204142:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204144:	00878d63          	beq	a5,s0,ffffffffc020415e <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc0204148:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7ffc>
ffffffffc020414c:	fed715e3          	bne	a4,a3,ffffffffc0204136 <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc0204150:	2685                	addiw	a3,a3,1
ffffffffc0204152:	10c6d863          	bge	a3,a2,ffffffffc0204262 <do_fork+0x342>
ffffffffc0204156:	679c                	ld	a5,8(a5)
ffffffffc0204158:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020415a:	fe8797e3          	bne	a5,s0,ffffffffc0204148 <do_fork+0x228>
ffffffffc020415e:	c581                	beqz	a1,ffffffffc0204166 <do_fork+0x246>
ffffffffc0204160:	00d82023          	sw	a3,0(a6)
ffffffffc0204164:	8536                	mv	a0,a3
ffffffffc0204166:	f0088fe3          	beqz	a7,ffffffffc0204084 <do_fork+0x164>
ffffffffc020416a:	00c32023          	sw	a2,0(t1)
ffffffffc020416e:	bf19                	j	ffffffffc0204084 <do_fork+0x164>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204170:	89b6                	mv	s3,a3
ffffffffc0204172:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204176:	00000797          	auipc	a5,0x0
ffffffffc020417a:	caa78793          	addi	a5,a5,-854 # ffffffffc0203e20 <forkret>
ffffffffc020417e:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204180:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204182:	100027f3          	csrr	a5,sstatus
ffffffffc0204186:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204188:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020418a:	ec0784e3          	beqz	a5,ffffffffc0204052 <do_fork+0x132>
        intr_disable();
ffffffffc020418e:	827fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204192:	4985                	li	s3,1
ffffffffc0204194:	bd7d                	j	ffffffffc0204052 <do_fork+0x132>
    if ((mm = mm_create()) == NULL)
ffffffffc0204196:	df4fe0ef          	jal	ra,ffffffffc020278a <mm_create>
ffffffffc020419a:	8caa                	mv	s9,a0
ffffffffc020419c:	c159                	beqz	a0,ffffffffc0204222 <do_fork+0x302>
    if ((page = alloc_page()) == NULL)
ffffffffc020419e:	4505                	li	a0,1
ffffffffc02041a0:	dc7fc0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc02041a4:	cd25                	beqz	a0,ffffffffc020421c <do_fork+0x2fc>
    return page - pages + nbase;
ffffffffc02041a6:	000ab683          	ld	a3,0(s5)
ffffffffc02041aa:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02041ac:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02041b0:	40d506b3          	sub	a3,a0,a3
ffffffffc02041b4:	8699                	srai	a3,a3,0x6
ffffffffc02041b6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02041b8:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02041bc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041be:	12edf263          	bgeu	s11,a4,ffffffffc02042e2 <do_fork+0x3c2>
ffffffffc02041c2:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02041c6:	6605                	lui	a2,0x1
ffffffffc02041c8:	000c3597          	auipc	a1,0xc3
ffffffffc02041cc:	8b85b583          	ld	a1,-1864(a1) # ffffffffc02c6a80 <boot_pgdir_va>
ffffffffc02041d0:	9a36                	add	s4,s4,a3
ffffffffc02041d2:	8552                	mv	a0,s4
ffffffffc02041d4:	2e2010ef          	jal	ra,ffffffffc02054b6 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02041d8:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02041dc:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02041e0:	4785                	li	a5,1
ffffffffc02041e2:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02041e6:	8b85                	andi	a5,a5,1
ffffffffc02041e8:	4a05                	li	s4,1
ffffffffc02041ea:	c799                	beqz	a5,ffffffffc02041f8 <do_fork+0x2d8>
    {
        schedule();
ffffffffc02041ec:	753000ef          	jal	ra,ffffffffc020513e <schedule>
ffffffffc02041f0:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc02041f4:	8b85                	andi	a5,a5,1
ffffffffc02041f6:	fbfd                	bnez	a5,ffffffffc02041ec <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc02041f8:	85ea                	mv	a1,s10
ffffffffc02041fa:	8566                	mv	a0,s9
ffffffffc02041fc:	fd0fe0ef          	jal	ra,ffffffffc02029cc <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204200:	57f9                	li	a5,-2
ffffffffc0204202:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204206:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204208:	cfa5                	beqz	a5,ffffffffc0204280 <do_fork+0x360>
good_mm:
ffffffffc020420a:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc020420c:	dc0506e3          	beqz	a0,ffffffffc0203fd8 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc0204210:	8566                	mv	a0,s9
ffffffffc0204212:	855fe0ef          	jal	ra,ffffffffc0202a66 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204216:	8566                	mv	a0,s9
ffffffffc0204218:	c17ff0ef          	jal	ra,ffffffffc0203e2e <put_pgdir>
    mm_destroy(mm);
ffffffffc020421c:	8566                	mv	a0,s9
ffffffffc020421e:	eacfe0ef          	jal	ra,ffffffffc02028ca <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204222:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204224:	c02007b7          	lui	a5,0xc0200
ffffffffc0204228:	0af6e163          	bltu	a3,a5,ffffffffc02042ca <do_fork+0x3aa>
ffffffffc020422c:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204230:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204234:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204238:	83b1                	srli	a5,a5,0xc
ffffffffc020423a:	04e7ff63          	bgeu	a5,a4,ffffffffc0204298 <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc020423e:	000b3703          	ld	a4,0(s6)
ffffffffc0204242:	000ab503          	ld	a0,0(s5)
ffffffffc0204246:	4589                	li	a1,2
ffffffffc0204248:	8f99                	sub	a5,a5,a4
ffffffffc020424a:	079a                	slli	a5,a5,0x6
ffffffffc020424c:	953e                	add	a0,a0,a5
ffffffffc020424e:	d57fc0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    kfree(proc);
ffffffffc0204252:	8526                	mv	a0,s1
ffffffffc0204254:	f23fe0ef          	jal	ra,ffffffffc0203176 <kfree>
    ret = -E_NO_MEM;
ffffffffc0204258:	5571                	li	a0,-4
    return ret;
ffffffffc020425a:	b569                	j	ffffffffc02040e4 <do_fork+0x1c4>
        intr_enable();
ffffffffc020425c:	f52fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204260:	bdb5                	j	ffffffffc02040dc <do_fork+0x1bc>
                    if (last_pid >= MAX_PID)
ffffffffc0204262:	01d6c363          	blt	a3,t4,ffffffffc0204268 <do_fork+0x348>
                        last_pid = 1;
ffffffffc0204266:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204268:	4585                	li	a1,1
ffffffffc020426a:	b5c1                	j	ffffffffc020412a <do_fork+0x20a>
ffffffffc020426c:	c599                	beqz	a1,ffffffffc020427a <do_fork+0x35a>
ffffffffc020426e:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204272:	8536                	mv	a0,a3
ffffffffc0204274:	bd01                	j	ffffffffc0204084 <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204276:	556d                	li	a0,-5
ffffffffc0204278:	b5b5                	j	ffffffffc02040e4 <do_fork+0x1c4>
    return last_pid;
ffffffffc020427a:	00082503          	lw	a0,0(a6)
ffffffffc020427e:	b519                	j	ffffffffc0204084 <do_fork+0x164>
    {
        panic("Unlock failed.\n");
ffffffffc0204280:	00003617          	auipc	a2,0x3
ffffffffc0204284:	ed860613          	addi	a2,a2,-296 # ffffffffc0207158 <default_pmm_manager+0x38>
ffffffffc0204288:	04000593          	li	a1,64
ffffffffc020428c:	00003517          	auipc	a0,0x3
ffffffffc0204290:	edc50513          	addi	a0,a0,-292 # ffffffffc0207168 <default_pmm_manager+0x48>
ffffffffc0204294:	f8ffb0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204298:	00002617          	auipc	a2,0x2
ffffffffc020429c:	0f860613          	addi	a2,a2,248 # ffffffffc0206390 <commands+0x810>
ffffffffc02042a0:	06900593          	li	a1,105
ffffffffc02042a4:	00002517          	auipc	a0,0x2
ffffffffc02042a8:	10c50513          	addi	a0,a0,268 # ffffffffc02063b0 <commands+0x830>
ffffffffc02042ac:	f77fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042b0:	86be                	mv	a3,a5
ffffffffc02042b2:	00002617          	auipc	a2,0x2
ffffffffc02042b6:	24660613          	addi	a2,a2,582 # ffffffffc02064f8 <commands+0x978>
ffffffffc02042ba:	19f00593          	li	a1,415
ffffffffc02042be:	00003517          	auipc	a0,0x3
ffffffffc02042c2:	ec250513          	addi	a0,a0,-318 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc02042c6:	f5dfb0ef          	jal	ra,ffffffffc0200222 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02042ca:	00002617          	auipc	a2,0x2
ffffffffc02042ce:	22e60613          	addi	a2,a2,558 # ffffffffc02064f8 <commands+0x978>
ffffffffc02042d2:	07700593          	li	a1,119
ffffffffc02042d6:	00002517          	auipc	a0,0x2
ffffffffc02042da:	0da50513          	addi	a0,a0,218 # ffffffffc02063b0 <commands+0x830>
ffffffffc02042de:	f45fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    return KADDR(page2pa(page));
ffffffffc02042e2:	00002617          	auipc	a2,0x2
ffffffffc02042e6:	10660613          	addi	a2,a2,262 # ffffffffc02063e8 <commands+0x868>
ffffffffc02042ea:	07100593          	li	a1,113
ffffffffc02042ee:	00002517          	auipc	a0,0x2
ffffffffc02042f2:	0c250513          	addi	a0,a0,194 # ffffffffc02063b0 <commands+0x830>
ffffffffc02042f6:	f2dfb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc02042fa <kernel_thread>:
{
ffffffffc02042fa:	7129                	addi	sp,sp,-320
ffffffffc02042fc:	fa22                	sd	s0,304(sp)
ffffffffc02042fe:	f626                	sd	s1,296(sp)
ffffffffc0204300:	f24a                	sd	s2,288(sp)
ffffffffc0204302:	84ae                	mv	s1,a1
ffffffffc0204304:	892a                	mv	s2,a0
ffffffffc0204306:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204308:	4581                	li	a1,0
ffffffffc020430a:	12000613          	li	a2,288
ffffffffc020430e:	850a                	mv	a0,sp
{
ffffffffc0204310:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204312:	192010ef          	jal	ra,ffffffffc02054a4 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204316:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204318:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020431a:	100027f3          	csrr	a5,sstatus
ffffffffc020431e:	edd7f793          	andi	a5,a5,-291
ffffffffc0204322:	1207e793          	ori	a5,a5,288
ffffffffc0204326:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204328:	860a                	mv	a2,sp
ffffffffc020432a:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020432e:	00000797          	auipc	a5,0x0
ffffffffc0204332:	9f078793          	addi	a5,a5,-1552 # ffffffffc0203d1e <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204336:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204338:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020433a:	be7ff0ef          	jal	ra,ffffffffc0203f20 <do_fork>
}
ffffffffc020433e:	70f2                	ld	ra,312(sp)
ffffffffc0204340:	7452                	ld	s0,304(sp)
ffffffffc0204342:	74b2                	ld	s1,296(sp)
ffffffffc0204344:	7912                	ld	s2,288(sp)
ffffffffc0204346:	6131                	addi	sp,sp,320
ffffffffc0204348:	8082                	ret

ffffffffc020434a <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc020434a:	7179                	addi	sp,sp,-48
ffffffffc020434c:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020434e:	000c2417          	auipc	s0,0xc2
ffffffffc0204352:	76240413          	addi	s0,s0,1890 # ffffffffc02c6ab0 <current>
ffffffffc0204356:	601c                	ld	a5,0(s0)
{
ffffffffc0204358:	f406                	sd	ra,40(sp)
ffffffffc020435a:	ec26                	sd	s1,24(sp)
ffffffffc020435c:	e84a                	sd	s2,16(sp)
ffffffffc020435e:	e44e                	sd	s3,8(sp)
ffffffffc0204360:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204362:	000c2717          	auipc	a4,0xc2
ffffffffc0204366:	75673703          	ld	a4,1878(a4) # ffffffffc02c6ab8 <idleproc>
ffffffffc020436a:	0ce78c63          	beq	a5,a4,ffffffffc0204442 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc020436e:	000c2497          	auipc	s1,0xc2
ffffffffc0204372:	75248493          	addi	s1,s1,1874 # ffffffffc02c6ac0 <initproc>
ffffffffc0204376:	6098                	ld	a4,0(s1)
ffffffffc0204378:	0ee78b63          	beq	a5,a4,ffffffffc020446e <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc020437c:	0287b983          	ld	s3,40(a5)
ffffffffc0204380:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204382:	02098663          	beqz	s3,ffffffffc02043ae <do_exit+0x64>
ffffffffc0204386:	000c2797          	auipc	a5,0xc2
ffffffffc020438a:	6f27b783          	ld	a5,1778(a5) # ffffffffc02c6a78 <boot_pgdir_pa>
ffffffffc020438e:	577d                	li	a4,-1
ffffffffc0204390:	177e                	slli	a4,a4,0x3f
ffffffffc0204392:	83b1                	srli	a5,a5,0xc
ffffffffc0204394:	8fd9                	or	a5,a5,a4
ffffffffc0204396:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020439a:	0309a783          	lw	a5,48(s3)
ffffffffc020439e:	fff7871b          	addiw	a4,a5,-1
ffffffffc02043a2:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02043a6:	cb55                	beqz	a4,ffffffffc020445a <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02043a8:	601c                	ld	a5,0(s0)
ffffffffc02043aa:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc02043ae:	601c                	ld	a5,0(s0)
ffffffffc02043b0:	470d                	li	a4,3
ffffffffc02043b2:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02043b4:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043b8:	100027f3          	csrr	a5,sstatus
ffffffffc02043bc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043be:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043c0:	e3f9                	bnez	a5,ffffffffc0204486 <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc02043c2:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02043c4:	800007b7          	lui	a5,0x80000
ffffffffc02043c8:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02043ca:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02043cc:	0ec52703          	lw	a4,236(a0)
ffffffffc02043d0:	0af70f63          	beq	a4,a5,ffffffffc020448e <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc02043d4:	6018                	ld	a4,0(s0)
ffffffffc02043d6:	7b7c                	ld	a5,240(a4)
ffffffffc02043d8:	c3a1                	beqz	a5,ffffffffc0204418 <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043da:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043de:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043e0:	0985                	addi	s3,s3,1
ffffffffc02043e2:	a021                	j	ffffffffc02043ea <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02043e4:	6018                	ld	a4,0(s0)
ffffffffc02043e6:	7b7c                	ld	a5,240(a4)
ffffffffc02043e8:	cb85                	beqz	a5,ffffffffc0204418 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02043ea:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff3a00>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043ee:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02043f0:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043f2:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02043f4:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043f8:	10e7b023          	sd	a4,256(a5)
ffffffffc02043fc:	c311                	beqz	a4,ffffffffc0204400 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02043fe:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204400:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204402:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204404:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204406:	fd271fe3          	bne	a4,s2,ffffffffc02043e4 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020440a:	0ec52783          	lw	a5,236(a0)
ffffffffc020440e:	fd379be3          	bne	a5,s3,ffffffffc02043e4 <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc0204412:	47b000ef          	jal	ra,ffffffffc020508c <wakeup_proc>
ffffffffc0204416:	b7f9                	j	ffffffffc02043e4 <do_exit+0x9a>
    if (flag)
ffffffffc0204418:	020a1263          	bnez	s4,ffffffffc020443c <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020441c:	523000ef          	jal	ra,ffffffffc020513e <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204420:	601c                	ld	a5,0(s0)
ffffffffc0204422:	00003617          	auipc	a2,0x3
ffffffffc0204426:	d9660613          	addi	a2,a2,-618 # ffffffffc02071b8 <default_pmm_manager+0x98>
ffffffffc020442a:	24e00593          	li	a1,590
ffffffffc020442e:	43d4                	lw	a3,4(a5)
ffffffffc0204430:	00003517          	auipc	a0,0x3
ffffffffc0204434:	d5050513          	addi	a0,a0,-688 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204438:	debfb0ef          	jal	ra,ffffffffc0200222 <__panic>
        intr_enable();
ffffffffc020443c:	d72fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204440:	bff1                	j	ffffffffc020441c <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204442:	00003617          	auipc	a2,0x3
ffffffffc0204446:	d5660613          	addi	a2,a2,-682 # ffffffffc0207198 <default_pmm_manager+0x78>
ffffffffc020444a:	21a00593          	li	a1,538
ffffffffc020444e:	00003517          	auipc	a0,0x3
ffffffffc0204452:	d3250513          	addi	a0,a0,-718 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204456:	dcdfb0ef          	jal	ra,ffffffffc0200222 <__panic>
            exit_mmap(mm);
ffffffffc020445a:	854e                	mv	a0,s3
ffffffffc020445c:	e0afe0ef          	jal	ra,ffffffffc0202a66 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204460:	854e                	mv	a0,s3
ffffffffc0204462:	9cdff0ef          	jal	ra,ffffffffc0203e2e <put_pgdir>
            mm_destroy(mm);
ffffffffc0204466:	854e                	mv	a0,s3
ffffffffc0204468:	c62fe0ef          	jal	ra,ffffffffc02028ca <mm_destroy>
ffffffffc020446c:	bf35                	j	ffffffffc02043a8 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020446e:	00003617          	auipc	a2,0x3
ffffffffc0204472:	d3a60613          	addi	a2,a2,-710 # ffffffffc02071a8 <default_pmm_manager+0x88>
ffffffffc0204476:	21e00593          	li	a1,542
ffffffffc020447a:	00003517          	auipc	a0,0x3
ffffffffc020447e:	d0650513          	addi	a0,a0,-762 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204482:	da1fb0ef          	jal	ra,ffffffffc0200222 <__panic>
        intr_disable();
ffffffffc0204486:	d2efc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020448a:	4a05                	li	s4,1
ffffffffc020448c:	bf1d                	j	ffffffffc02043c2 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020448e:	3ff000ef          	jal	ra,ffffffffc020508c <wakeup_proc>
ffffffffc0204492:	b789                	j	ffffffffc02043d4 <do_exit+0x8a>

ffffffffc0204494 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204494:	715d                	addi	sp,sp,-80
ffffffffc0204496:	f84a                	sd	s2,48(sp)
ffffffffc0204498:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc020449a:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020449e:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02044a0:	fc26                	sd	s1,56(sp)
ffffffffc02044a2:	f052                	sd	s4,32(sp)
ffffffffc02044a4:	ec56                	sd	s5,24(sp)
ffffffffc02044a6:	e85a                	sd	s6,16(sp)
ffffffffc02044a8:	e45e                	sd	s7,8(sp)
ffffffffc02044aa:	e486                	sd	ra,72(sp)
ffffffffc02044ac:	e0a2                	sd	s0,64(sp)
ffffffffc02044ae:	84aa                	mv	s1,a0
ffffffffc02044b0:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02044b2:	000c2b97          	auipc	s7,0xc2
ffffffffc02044b6:	5feb8b93          	addi	s7,s7,1534 # ffffffffc02c6ab0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02044ba:	00050b1b          	sext.w	s6,a0
ffffffffc02044be:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02044c2:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02044c4:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02044c6:	ccbd                	beqz	s1,ffffffffc0204544 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02044c8:	0359e863          	bltu	s3,s5,ffffffffc02044f8 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02044cc:	45a9                	li	a1,10
ffffffffc02044ce:	855a                	mv	a0,s6
ffffffffc02044d0:	3ec010ef          	jal	ra,ffffffffc02058bc <hash32>
ffffffffc02044d4:	02051793          	slli	a5,a0,0x20
ffffffffc02044d8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02044dc:	000be797          	auipc	a5,0xbe
ffffffffc02044e0:	53c78793          	addi	a5,a5,1340 # ffffffffc02c2a18 <hash_list>
ffffffffc02044e4:	953e                	add	a0,a0,a5
ffffffffc02044e6:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02044e8:	a029                	j	ffffffffc02044f2 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02044ea:	f2c42783          	lw	a5,-212(s0)
ffffffffc02044ee:	02978163          	beq	a5,s1,ffffffffc0204510 <do_wait.part.0+0x7c>
ffffffffc02044f2:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02044f4:	fe851be3          	bne	a0,s0,ffffffffc02044ea <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc02044f8:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc02044fa:	60a6                	ld	ra,72(sp)
ffffffffc02044fc:	6406                	ld	s0,64(sp)
ffffffffc02044fe:	74e2                	ld	s1,56(sp)
ffffffffc0204500:	7942                	ld	s2,48(sp)
ffffffffc0204502:	79a2                	ld	s3,40(sp)
ffffffffc0204504:	7a02                	ld	s4,32(sp)
ffffffffc0204506:	6ae2                	ld	s5,24(sp)
ffffffffc0204508:	6b42                	ld	s6,16(sp)
ffffffffc020450a:	6ba2                	ld	s7,8(sp)
ffffffffc020450c:	6161                	addi	sp,sp,80
ffffffffc020450e:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204510:	000bb683          	ld	a3,0(s7)
ffffffffc0204514:	f4843783          	ld	a5,-184(s0)
ffffffffc0204518:	fed790e3          	bne	a5,a3,ffffffffc02044f8 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020451c:	f2842703          	lw	a4,-216(s0)
ffffffffc0204520:	478d                	li	a5,3
ffffffffc0204522:	0ef70b63          	beq	a4,a5,ffffffffc0204618 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204526:	4785                	li	a5,1
ffffffffc0204528:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020452a:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020452e:	411000ef          	jal	ra,ffffffffc020513e <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204532:	000bb783          	ld	a5,0(s7)
ffffffffc0204536:	0b07a783          	lw	a5,176(a5)
ffffffffc020453a:	8b85                	andi	a5,a5,1
ffffffffc020453c:	d7c9                	beqz	a5,ffffffffc02044c6 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020453e:	555d                	li	a0,-9
ffffffffc0204540:	e0bff0ef          	jal	ra,ffffffffc020434a <do_exit>
        proc = current->cptr;
ffffffffc0204544:	000bb683          	ld	a3,0(s7)
ffffffffc0204548:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020454a:	d45d                	beqz	s0,ffffffffc02044f8 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020454c:	470d                	li	a4,3
ffffffffc020454e:	a021                	j	ffffffffc0204556 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204550:	10043403          	ld	s0,256(s0)
ffffffffc0204554:	d869                	beqz	s0,ffffffffc0204526 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204556:	401c                	lw	a5,0(s0)
ffffffffc0204558:	fee79ce3          	bne	a5,a4,ffffffffc0204550 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc020455c:	000c2797          	auipc	a5,0xc2
ffffffffc0204560:	55c7b783          	ld	a5,1372(a5) # ffffffffc02c6ab8 <idleproc>
ffffffffc0204564:	0c878963          	beq	a5,s0,ffffffffc0204636 <do_wait.part.0+0x1a2>
ffffffffc0204568:	000c2797          	auipc	a5,0xc2
ffffffffc020456c:	5587b783          	ld	a5,1368(a5) # ffffffffc02c6ac0 <initproc>
ffffffffc0204570:	0cf40363          	beq	s0,a5,ffffffffc0204636 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204574:	000a0663          	beqz	s4,ffffffffc0204580 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204578:	0e842783          	lw	a5,232(s0)
ffffffffc020457c:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204580:	100027f3          	csrr	a5,sstatus
ffffffffc0204584:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204586:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204588:	e7c1                	bnez	a5,ffffffffc0204610 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020458a:	6c70                	ld	a2,216(s0)
ffffffffc020458c:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020458e:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204592:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204594:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204596:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204598:	6470                	ld	a2,200(s0)
ffffffffc020459a:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020459c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020459e:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02045a0:	c319                	beqz	a4,ffffffffc02045a6 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02045a2:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02045a4:	7c7c                	ld	a5,248(s0)
ffffffffc02045a6:	c3b5                	beqz	a5,ffffffffc020460a <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02045a8:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02045ac:	000c2717          	auipc	a4,0xc2
ffffffffc02045b0:	51c70713          	addi	a4,a4,1308 # ffffffffc02c6ac8 <nr_process>
ffffffffc02045b4:	431c                	lw	a5,0(a4)
ffffffffc02045b6:	37fd                	addiw	a5,a5,-1
ffffffffc02045b8:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02045ba:	e5a9                	bnez	a1,ffffffffc0204604 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02045bc:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02045be:	c02007b7          	lui	a5,0xc0200
ffffffffc02045c2:	04f6ee63          	bltu	a3,a5,ffffffffc020461e <do_wait.part.0+0x18a>
ffffffffc02045c6:	000c2797          	auipc	a5,0xc2
ffffffffc02045ca:	4da7b783          	ld	a5,1242(a5) # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc02045ce:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02045d0:	82b1                	srli	a3,a3,0xc
ffffffffc02045d2:	000c2797          	auipc	a5,0xc2
ffffffffc02045d6:	4b67b783          	ld	a5,1206(a5) # ffffffffc02c6a88 <npage>
ffffffffc02045da:	06f6fa63          	bgeu	a3,a5,ffffffffc020464e <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02045de:	00004517          	auipc	a0,0x4
ffffffffc02045e2:	c8253503          	ld	a0,-894(a0) # ffffffffc0208260 <nbase>
ffffffffc02045e6:	8e89                	sub	a3,a3,a0
ffffffffc02045e8:	069a                	slli	a3,a3,0x6
ffffffffc02045ea:	000c2517          	auipc	a0,0xc2
ffffffffc02045ee:	4a653503          	ld	a0,1190(a0) # ffffffffc02c6a90 <pages>
ffffffffc02045f2:	9536                	add	a0,a0,a3
ffffffffc02045f4:	4589                	li	a1,2
ffffffffc02045f6:	9affc0ef          	jal	ra,ffffffffc0200fa4 <free_pages>
    kfree(proc);
ffffffffc02045fa:	8522                	mv	a0,s0
ffffffffc02045fc:	b7bfe0ef          	jal	ra,ffffffffc0203176 <kfree>
    return 0;
ffffffffc0204600:	4501                	li	a0,0
ffffffffc0204602:	bde5                	j	ffffffffc02044fa <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204604:	baafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204608:	bf55                	j	ffffffffc02045bc <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020460a:	701c                	ld	a5,32(s0)
ffffffffc020460c:	fbf8                	sd	a4,240(a5)
ffffffffc020460e:	bf79                	j	ffffffffc02045ac <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204610:	ba4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204614:	4585                	li	a1,1
ffffffffc0204616:	bf95                	j	ffffffffc020458a <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204618:	f2840413          	addi	s0,s0,-216
ffffffffc020461c:	b781                	j	ffffffffc020455c <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020461e:	00002617          	auipc	a2,0x2
ffffffffc0204622:	eda60613          	addi	a2,a2,-294 # ffffffffc02064f8 <commands+0x978>
ffffffffc0204626:	07700593          	li	a1,119
ffffffffc020462a:	00002517          	auipc	a0,0x2
ffffffffc020462e:	d8650513          	addi	a0,a0,-634 # ffffffffc02063b0 <commands+0x830>
ffffffffc0204632:	bf1fb0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204636:	00003617          	auipc	a2,0x3
ffffffffc020463a:	ba260613          	addi	a2,a2,-1118 # ffffffffc02071d8 <default_pmm_manager+0xb8>
ffffffffc020463e:	37000593          	li	a1,880
ffffffffc0204642:	00003517          	auipc	a0,0x3
ffffffffc0204646:	b3e50513          	addi	a0,a0,-1218 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc020464a:	bd9fb0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020464e:	00002617          	auipc	a2,0x2
ffffffffc0204652:	d4260613          	addi	a2,a2,-702 # ffffffffc0206390 <commands+0x810>
ffffffffc0204656:	06900593          	li	a1,105
ffffffffc020465a:	00002517          	auipc	a0,0x2
ffffffffc020465e:	d5650513          	addi	a0,a0,-682 # ffffffffc02063b0 <commands+0x830>
ffffffffc0204662:	bc1fb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0204666 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204666:	1141                	addi	sp,sp,-16
ffffffffc0204668:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020466a:	97bfc0ef          	jal	ra,ffffffffc0200fe4 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020466e:	a55fe0ef          	jal	ra,ffffffffc02030c2 <kallocated>
    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204672:	4601                	li	a2,0
ffffffffc0204674:	4581                	li	a1,0
ffffffffc0204676:	00000517          	auipc	a0,0x0
ffffffffc020467a:	62850513          	addi	a0,a0,1576 # ffffffffc0204c9e <user_main>
ffffffffc020467e:	c7dff0ef          	jal	ra,ffffffffc02042fa <kernel_thread>
    if (pid <= 0)
ffffffffc0204682:	00a04563          	bgtz	a0,ffffffffc020468c <init_main+0x26>
ffffffffc0204686:	a071                	j	ffffffffc0204712 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204688:	2b7000ef          	jal	ra,ffffffffc020513e <schedule>
    if (code_store != NULL)
ffffffffc020468c:	4581                	li	a1,0
ffffffffc020468e:	4501                	li	a0,0
ffffffffc0204690:	e05ff0ef          	jal	ra,ffffffffc0204494 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204694:	d975                	beqz	a0,ffffffffc0204688 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204696:	00003517          	auipc	a0,0x3
ffffffffc020469a:	b8250513          	addi	a0,a0,-1150 # ffffffffc0207218 <default_pmm_manager+0xf8>
ffffffffc020469e:	a47fb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02046a2:	000c2797          	auipc	a5,0xc2
ffffffffc02046a6:	41e7b783          	ld	a5,1054(a5) # ffffffffc02c6ac0 <initproc>
ffffffffc02046aa:	7bf8                	ld	a4,240(a5)
ffffffffc02046ac:	e339                	bnez	a4,ffffffffc02046f2 <init_main+0x8c>
ffffffffc02046ae:	7ff8                	ld	a4,248(a5)
ffffffffc02046b0:	e329                	bnez	a4,ffffffffc02046f2 <init_main+0x8c>
ffffffffc02046b2:	1007b703          	ld	a4,256(a5)
ffffffffc02046b6:	ef15                	bnez	a4,ffffffffc02046f2 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02046b8:	000c2697          	auipc	a3,0xc2
ffffffffc02046bc:	4106a683          	lw	a3,1040(a3) # ffffffffc02c6ac8 <nr_process>
ffffffffc02046c0:	4709                	li	a4,2
ffffffffc02046c2:	0ae69463          	bne	a3,a4,ffffffffc020476a <init_main+0x104>
    return listelm->next;
ffffffffc02046c6:	000c2697          	auipc	a3,0xc2
ffffffffc02046ca:	35268693          	addi	a3,a3,850 # ffffffffc02c6a18 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046ce:	6698                	ld	a4,8(a3)
ffffffffc02046d0:	0c878793          	addi	a5,a5,200
ffffffffc02046d4:	06f71b63          	bne	a4,a5,ffffffffc020474a <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02046d8:	629c                	ld	a5,0(a3)
ffffffffc02046da:	04f71863          	bne	a4,a5,ffffffffc020472a <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02046de:	00003517          	auipc	a0,0x3
ffffffffc02046e2:	c2250513          	addi	a0,a0,-990 # ffffffffc0207300 <default_pmm_manager+0x1e0>
ffffffffc02046e6:	9fffb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    return 0;
}
ffffffffc02046ea:	60a2                	ld	ra,8(sp)
ffffffffc02046ec:	4501                	li	a0,0
ffffffffc02046ee:	0141                	addi	sp,sp,16
ffffffffc02046f0:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02046f2:	00003697          	auipc	a3,0x3
ffffffffc02046f6:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0207240 <default_pmm_manager+0x120>
ffffffffc02046fa:	00002617          	auipc	a2,0x2
ffffffffc02046fe:	d5660613          	addi	a2,a2,-682 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204702:	3dc00593          	li	a1,988
ffffffffc0204706:	00003517          	auipc	a0,0x3
ffffffffc020470a:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc020470e:	b15fb0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204712:	00003617          	auipc	a2,0x3
ffffffffc0204716:	ae660613          	addi	a2,a2,-1306 # ffffffffc02071f8 <default_pmm_manager+0xd8>
ffffffffc020471a:	3d300593          	li	a1,979
ffffffffc020471e:	00003517          	auipc	a0,0x3
ffffffffc0204722:	a6250513          	addi	a0,a0,-1438 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204726:	afdfb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020472a:	00003697          	auipc	a3,0x3
ffffffffc020472e:	ba668693          	addi	a3,a3,-1114 # ffffffffc02072d0 <default_pmm_manager+0x1b0>
ffffffffc0204732:	00002617          	auipc	a2,0x2
ffffffffc0204736:	d1e60613          	addi	a2,a2,-738 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020473a:	3df00593          	li	a1,991
ffffffffc020473e:	00003517          	auipc	a0,0x3
ffffffffc0204742:	a4250513          	addi	a0,a0,-1470 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204746:	addfb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020474a:	00003697          	auipc	a3,0x3
ffffffffc020474e:	b5668693          	addi	a3,a3,-1194 # ffffffffc02072a0 <default_pmm_manager+0x180>
ffffffffc0204752:	00002617          	auipc	a2,0x2
ffffffffc0204756:	cfe60613          	addi	a2,a2,-770 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020475a:	3de00593          	li	a1,990
ffffffffc020475e:	00003517          	auipc	a0,0x3
ffffffffc0204762:	a2250513          	addi	a0,a0,-1502 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204766:	abdfb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(nr_process == 2);
ffffffffc020476a:	00003697          	auipc	a3,0x3
ffffffffc020476e:	b2668693          	addi	a3,a3,-1242 # ffffffffc0207290 <default_pmm_manager+0x170>
ffffffffc0204772:	00002617          	auipc	a2,0x2
ffffffffc0204776:	cde60613          	addi	a2,a2,-802 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020477a:	3dd00593          	li	a1,989
ffffffffc020477e:	00003517          	auipc	a0,0x3
ffffffffc0204782:	a0250513          	addi	a0,a0,-1534 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204786:	a9dfb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc020478a <do_execve>:
{
ffffffffc020478a:	7171                	addi	sp,sp,-176
ffffffffc020478c:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020478e:	000c2d97          	auipc	s11,0xc2
ffffffffc0204792:	322d8d93          	addi	s11,s11,802 # ffffffffc02c6ab0 <current>
ffffffffc0204796:	000db783          	ld	a5,0(s11)
{
ffffffffc020479a:	e94a                	sd	s2,144(sp)
ffffffffc020479c:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020479e:	0287b903          	ld	s2,40(a5)
{
ffffffffc02047a2:	ed26                	sd	s1,152(sp)
ffffffffc02047a4:	f8da                	sd	s6,112(sp)
ffffffffc02047a6:	84aa                	mv	s1,a0
ffffffffc02047a8:	8b32                	mv	s6,a2
ffffffffc02047aa:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02047ac:	862e                	mv	a2,a1
ffffffffc02047ae:	4681                	li	a3,0
ffffffffc02047b0:	85aa                	mv	a1,a0
ffffffffc02047b2:	854a                	mv	a0,s2
{
ffffffffc02047b4:	f506                	sd	ra,168(sp)
ffffffffc02047b6:	e54e                	sd	s3,136(sp)
ffffffffc02047b8:	e152                	sd	s4,128(sp)
ffffffffc02047ba:	fcd6                	sd	s5,120(sp)
ffffffffc02047bc:	f4de                	sd	s7,104(sp)
ffffffffc02047be:	f0e2                	sd	s8,96(sp)
ffffffffc02047c0:	ece6                	sd	s9,88(sp)
ffffffffc02047c2:	e8ea                	sd	s10,80(sp)
ffffffffc02047c4:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02047c6:	e3afe0ef          	jal	ra,ffffffffc0202e00 <user_mem_check>
ffffffffc02047ca:	40050a63          	beqz	a0,ffffffffc0204bde <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02047ce:	4641                	li	a2,16
ffffffffc02047d0:	4581                	li	a1,0
ffffffffc02047d2:	1808                	addi	a0,sp,48
ffffffffc02047d4:	4d1000ef          	jal	ra,ffffffffc02054a4 <memset>
    memcpy(local_name, name, len);
ffffffffc02047d8:	47bd                	li	a5,15
ffffffffc02047da:	8622                	mv	a2,s0
ffffffffc02047dc:	1e87e263          	bltu	a5,s0,ffffffffc02049c0 <do_execve+0x236>
ffffffffc02047e0:	85a6                	mv	a1,s1
ffffffffc02047e2:	1808                	addi	a0,sp,48
ffffffffc02047e4:	4d3000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    if (mm != NULL)
ffffffffc02047e8:	1e090363          	beqz	s2,ffffffffc02049ce <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02047ec:	00002517          	auipc	a0,0x2
ffffffffc02047f0:	34450513          	addi	a0,a0,836 # ffffffffc0206b30 <commands+0xfb0>
ffffffffc02047f4:	92bfb0ef          	jal	ra,ffffffffc020011e <cputs>
ffffffffc02047f8:	000c2797          	auipc	a5,0xc2
ffffffffc02047fc:	2807b783          	ld	a5,640(a5) # ffffffffc02c6a78 <boot_pgdir_pa>
ffffffffc0204800:	577d                	li	a4,-1
ffffffffc0204802:	177e                	slli	a4,a4,0x3f
ffffffffc0204804:	83b1                	srli	a5,a5,0xc
ffffffffc0204806:	8fd9                	or	a5,a5,a4
ffffffffc0204808:	18079073          	csrw	satp,a5
ffffffffc020480c:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_matrix_out_size+0xffffffff7fff3930>
ffffffffc0204810:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204814:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204818:	2c070463          	beqz	a4,ffffffffc0204ae0 <do_execve+0x356>
        current->mm = NULL;
ffffffffc020481c:	000db783          	ld	a5,0(s11)
ffffffffc0204820:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204824:	f67fd0ef          	jal	ra,ffffffffc020278a <mm_create>
ffffffffc0204828:	842a                	mv	s0,a0
ffffffffc020482a:	1c050d63          	beqz	a0,ffffffffc0204a04 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc020482e:	4505                	li	a0,1
ffffffffc0204830:	f36fc0ef          	jal	ra,ffffffffc0200f66 <alloc_pages>
ffffffffc0204834:	3a050963          	beqz	a0,ffffffffc0204be6 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204838:	000c2c97          	auipc	s9,0xc2
ffffffffc020483c:	258c8c93          	addi	s9,s9,600 # ffffffffc02c6a90 <pages>
ffffffffc0204840:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204844:	000c2c17          	auipc	s8,0xc2
ffffffffc0204848:	244c0c13          	addi	s8,s8,580 # ffffffffc02c6a88 <npage>
    return page - pages + nbase;
ffffffffc020484c:	00004717          	auipc	a4,0x4
ffffffffc0204850:	a1473703          	ld	a4,-1516(a4) # ffffffffc0208260 <nbase>
ffffffffc0204854:	40d506b3          	sub	a3,a0,a3
ffffffffc0204858:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020485a:	5a7d                	li	s4,-1
ffffffffc020485c:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204860:	96ba                	add	a3,a3,a4
ffffffffc0204862:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204864:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204868:	ec3a                	sd	a4,24(sp)
ffffffffc020486a:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020486c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020486e:	38f77063          	bgeu	a4,a5,ffffffffc0204bee <do_execve+0x464>
ffffffffc0204872:	000c2a97          	auipc	s5,0xc2
ffffffffc0204876:	22ea8a93          	addi	s5,s5,558 # ffffffffc02c6aa0 <va_pa_offset>
ffffffffc020487a:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020487e:	6605                	lui	a2,0x1
ffffffffc0204880:	000c2597          	auipc	a1,0xc2
ffffffffc0204884:	2005b583          	ld	a1,512(a1) # ffffffffc02c6a80 <boot_pgdir_va>
ffffffffc0204888:	94b6                	add	s1,s1,a3
ffffffffc020488a:	8526                	mv	a0,s1
ffffffffc020488c:	42b000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204890:	7782                	ld	a5,32(sp)
ffffffffc0204892:	4398                	lw	a4,0(a5)
ffffffffc0204894:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204898:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020489a:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e7f>
ffffffffc020489e:	14f71963          	bne	a4,a5,ffffffffc02049f0 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048a2:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc02048a4:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048a6:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02048aa:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048ae:	00371793          	slli	a5,a4,0x3
ffffffffc02048b2:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02048b4:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048b6:	078e                	slli	a5,a5,0x3
ffffffffc02048b8:	97ca                	add	a5,a5,s2
ffffffffc02048ba:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02048bc:	00f97c63          	bgeu	s2,a5,ffffffffc02048d4 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02048c0:	00092783          	lw	a5,0(s2)
ffffffffc02048c4:	4705                	li	a4,1
ffffffffc02048c6:	14e78163          	beq	a5,a4,ffffffffc0204a08 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc02048ca:	77a2                	ld	a5,40(sp)
ffffffffc02048cc:	03890913          	addi	s2,s2,56
ffffffffc02048d0:	fef968e3          	bltu	s2,a5,ffffffffc02048c0 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02048d4:	4701                	li	a4,0
ffffffffc02048d6:	46ad                	li	a3,11
ffffffffc02048d8:	00100637          	lui	a2,0x100
ffffffffc02048dc:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02048e0:	8522                	mv	a0,s0
ffffffffc02048e2:	83afe0ef          	jal	ra,ffffffffc020291c <mm_map>
ffffffffc02048e6:	89aa                	mv	s3,a0
ffffffffc02048e8:	1e051263          	bnez	a0,ffffffffc0204acc <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02048ec:	6c08                	ld	a0,24(s0)
ffffffffc02048ee:	467d                	li	a2,31
ffffffffc02048f0:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02048f4:	db1fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc02048f8:	38050363          	beqz	a0,ffffffffc0204c7e <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048fc:	6c08                	ld	a0,24(s0)
ffffffffc02048fe:	467d                	li	a2,31
ffffffffc0204900:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204904:	da1fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc0204908:	34050b63          	beqz	a0,ffffffffc0204c5e <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020490c:	6c08                	ld	a0,24(s0)
ffffffffc020490e:	467d                	li	a2,31
ffffffffc0204910:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204914:	d91fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc0204918:	32050363          	beqz	a0,ffffffffc0204c3e <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020491c:	6c08                	ld	a0,24(s0)
ffffffffc020491e:	467d                	li	a2,31
ffffffffc0204920:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204924:	d81fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc0204928:	2e050b63          	beqz	a0,ffffffffc0204c1e <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc020492c:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc020492e:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204932:	6c14                	ld	a3,24(s0)
ffffffffc0204934:	2785                	addiw	a5,a5,1
ffffffffc0204936:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204938:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020493a:	c02007b7          	lui	a5,0xc0200
ffffffffc020493e:	2cf6e463          	bltu	a3,a5,ffffffffc0204c06 <do_execve+0x47c>
ffffffffc0204942:	000ab783          	ld	a5,0(s5)
ffffffffc0204946:	577d                	li	a4,-1
ffffffffc0204948:	177e                	slli	a4,a4,0x3f
ffffffffc020494a:	8e9d                	sub	a3,a3,a5
ffffffffc020494c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204950:	f654                	sd	a3,168(a2)
ffffffffc0204952:	8fd9                	or	a5,a5,a4
ffffffffc0204954:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204958:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020495a:	4581                	li	a1,0
ffffffffc020495c:	12000613          	li	a2,288
ffffffffc0204960:	8526                	mv	a0,s1
ffffffffc0204962:	343000ef          	jal	ra,ffffffffc02054a4 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204966:	7782                	ld	a5,32(sp)
ffffffffc0204968:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc020496a:	4785                	li	a5,1
ffffffffc020496c:	07fe                	slli	a5,a5,0x1f
ffffffffc020496e:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc0204970:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP & ~SSTATUS_SIE;
ffffffffc0204974:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204978:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP & ~SSTATUS_SIE;
ffffffffc020497c:	edd7f793          	andi	a5,a5,-291
ffffffffc0204980:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204984:	0b440413          	addi	s0,s0,180
ffffffffc0204988:	4641                	li	a2,16
ffffffffc020498a:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP & ~SSTATUS_SIE;
ffffffffc020498c:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204990:	8522                	mv	a0,s0
ffffffffc0204992:	313000ef          	jal	ra,ffffffffc02054a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204996:	463d                	li	a2,15
ffffffffc0204998:	180c                	addi	a1,sp,48
ffffffffc020499a:	8522                	mv	a0,s0
ffffffffc020499c:	31b000ef          	jal	ra,ffffffffc02054b6 <memcpy>
}
ffffffffc02049a0:	70aa                	ld	ra,168(sp)
ffffffffc02049a2:	740a                	ld	s0,160(sp)
ffffffffc02049a4:	64ea                	ld	s1,152(sp)
ffffffffc02049a6:	694a                	ld	s2,144(sp)
ffffffffc02049a8:	6a0a                	ld	s4,128(sp)
ffffffffc02049aa:	7ae6                	ld	s5,120(sp)
ffffffffc02049ac:	7b46                	ld	s6,112(sp)
ffffffffc02049ae:	7ba6                	ld	s7,104(sp)
ffffffffc02049b0:	7c06                	ld	s8,96(sp)
ffffffffc02049b2:	6ce6                	ld	s9,88(sp)
ffffffffc02049b4:	6d46                	ld	s10,80(sp)
ffffffffc02049b6:	6da6                	ld	s11,72(sp)
ffffffffc02049b8:	854e                	mv	a0,s3
ffffffffc02049ba:	69aa                	ld	s3,136(sp)
ffffffffc02049bc:	614d                	addi	sp,sp,176
ffffffffc02049be:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02049c0:	463d                	li	a2,15
ffffffffc02049c2:	85a6                	mv	a1,s1
ffffffffc02049c4:	1808                	addi	a0,sp,48
ffffffffc02049c6:	2f1000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    if (mm != NULL)
ffffffffc02049ca:	e20911e3          	bnez	s2,ffffffffc02047ec <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02049ce:	000db783          	ld	a5,0(s11)
ffffffffc02049d2:	779c                	ld	a5,40(a5)
ffffffffc02049d4:	e40788e3          	beqz	a5,ffffffffc0204824 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02049d8:	00003617          	auipc	a2,0x3
ffffffffc02049dc:	94860613          	addi	a2,a2,-1720 # ffffffffc0207320 <default_pmm_manager+0x200>
ffffffffc02049e0:	25a00593          	li	a1,602
ffffffffc02049e4:	00002517          	auipc	a0,0x2
ffffffffc02049e8:	79c50513          	addi	a0,a0,1948 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc02049ec:	837fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    put_pgdir(mm);
ffffffffc02049f0:	8522                	mv	a0,s0
ffffffffc02049f2:	c3cff0ef          	jal	ra,ffffffffc0203e2e <put_pgdir>
    mm_destroy(mm);
ffffffffc02049f6:	8522                	mv	a0,s0
ffffffffc02049f8:	ed3fd0ef          	jal	ra,ffffffffc02028ca <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02049fc:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc02049fe:	854e                	mv	a0,s3
ffffffffc0204a00:	94bff0ef          	jal	ra,ffffffffc020434a <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204a04:	59f1                	li	s3,-4
ffffffffc0204a06:	bfe5                	j	ffffffffc02049fe <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204a08:	02893603          	ld	a2,40(s2)
ffffffffc0204a0c:	02093783          	ld	a5,32(s2)
ffffffffc0204a10:	1cf66d63          	bltu	a2,a5,ffffffffc0204bea <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204a14:	00492783          	lw	a5,4(s2)
ffffffffc0204a18:	0017f693          	andi	a3,a5,1
ffffffffc0204a1c:	c291                	beqz	a3,ffffffffc0204a20 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204a1e:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a20:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a24:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a26:	e779                	bnez	a4,ffffffffc0204af4 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204a28:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a2a:	c781                	beqz	a5,ffffffffc0204a32 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204a2c:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204a30:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204a32:	0026f793          	andi	a5,a3,2
ffffffffc0204a36:	e3f1                	bnez	a5,ffffffffc0204afa <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204a38:	0046f793          	andi	a5,a3,4
ffffffffc0204a3c:	c399                	beqz	a5,ffffffffc0204a42 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204a3e:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204a42:	01093583          	ld	a1,16(s2)
ffffffffc0204a46:	4701                	li	a4,0
ffffffffc0204a48:	8522                	mv	a0,s0
ffffffffc0204a4a:	ed3fd0ef          	jal	ra,ffffffffc020291c <mm_map>
ffffffffc0204a4e:	89aa                	mv	s3,a0
ffffffffc0204a50:	ed35                	bnez	a0,ffffffffc0204acc <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a52:	01093b03          	ld	s6,16(s2)
ffffffffc0204a56:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a58:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a5c:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a60:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a64:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a66:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a68:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204a6a:	053b6963          	bltu	s6,s3,ffffffffc0204abc <do_execve+0x332>
ffffffffc0204a6e:	aa95                	j	ffffffffc0204be2 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a70:	6785                	lui	a5,0x1
ffffffffc0204a72:	414b0533          	sub	a0,s6,s4
ffffffffc0204a76:	9a3e                	add	s4,s4,a5
ffffffffc0204a78:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204a7c:	0149f463          	bgeu	s3,s4,ffffffffc0204a84 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204a80:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204a84:	000cb683          	ld	a3,0(s9)
ffffffffc0204a88:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a8a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204a8e:	40db86b3          	sub	a3,s7,a3
ffffffffc0204a92:	8699                	srai	a3,a3,0x6
ffffffffc0204a94:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a96:	67e2                	ld	a5,24(sp)
ffffffffc0204a98:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a9c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a9e:	14b8f863          	bgeu	a7,a1,ffffffffc0204bee <do_execve+0x464>
ffffffffc0204aa2:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204aa6:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204aa8:	9b32                	add	s6,s6,a2
ffffffffc0204aaa:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204aac:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204aae:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ab0:	207000ef          	jal	ra,ffffffffc02054b6 <memcpy>
            start += size, from += size;
ffffffffc0204ab4:	6622                	ld	a2,8(sp)
ffffffffc0204ab6:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204ab8:	053b7363          	bgeu	s6,s3,ffffffffc0204afe <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204abc:	6c08                	ld	a0,24(s0)
ffffffffc0204abe:	866a                	mv	a2,s10
ffffffffc0204ac0:	85d2                	mv	a1,s4
ffffffffc0204ac2:	be3fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc0204ac6:	8baa                	mv	s7,a0
ffffffffc0204ac8:	f545                	bnez	a0,ffffffffc0204a70 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204aca:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204acc:	8522                	mv	a0,s0
ffffffffc0204ace:	f99fd0ef          	jal	ra,ffffffffc0202a66 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204ad2:	8522                	mv	a0,s0
ffffffffc0204ad4:	b5aff0ef          	jal	ra,ffffffffc0203e2e <put_pgdir>
    mm_destroy(mm);
ffffffffc0204ad8:	8522                	mv	a0,s0
ffffffffc0204ada:	df1fd0ef          	jal	ra,ffffffffc02028ca <mm_destroy>
    return ret;
ffffffffc0204ade:	b705                	j	ffffffffc02049fe <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204ae0:	854a                	mv	a0,s2
ffffffffc0204ae2:	f85fd0ef          	jal	ra,ffffffffc0202a66 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204ae6:	854a                	mv	a0,s2
ffffffffc0204ae8:	b46ff0ef          	jal	ra,ffffffffc0203e2e <put_pgdir>
            mm_destroy(mm);
ffffffffc0204aec:	854a                	mv	a0,s2
ffffffffc0204aee:	dddfd0ef          	jal	ra,ffffffffc02028ca <mm_destroy>
ffffffffc0204af2:	b32d                	j	ffffffffc020481c <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204af4:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204af8:	fb95                	bnez	a5,ffffffffc0204a2c <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204afa:	4d5d                	li	s10,23
ffffffffc0204afc:	bf35                	j	ffffffffc0204a38 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204afe:	01093483          	ld	s1,16(s2)
ffffffffc0204b02:	02893683          	ld	a3,40(s2)
ffffffffc0204b06:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204b08:	074b7d63          	bgeu	s6,s4,ffffffffc0204b82 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204b0c:	db648fe3          	beq	s1,s6,ffffffffc02048ca <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b10:	6785                	lui	a5,0x1
ffffffffc0204b12:	00fb0533          	add	a0,s6,a5
ffffffffc0204b16:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204b1a:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204b1e:	0b44fd63          	bgeu	s1,s4,ffffffffc0204bd8 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204b22:	000cb683          	ld	a3,0(s9)
ffffffffc0204b26:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b28:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204b2c:	40db86b3          	sub	a3,s7,a3
ffffffffc0204b30:	8699                	srai	a3,a3,0x6
ffffffffc0204b32:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b34:	67e2                	ld	a5,24(sp)
ffffffffc0204b36:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b3a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b3c:	0ac5f963          	bgeu	a1,a2,ffffffffc0204bee <do_execve+0x464>
ffffffffc0204b40:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b44:	864e                	mv	a2,s3
ffffffffc0204b46:	4581                	li	a1,0
ffffffffc0204b48:	96c6                	add	a3,a3,a7
ffffffffc0204b4a:	9536                	add	a0,a0,a3
ffffffffc0204b4c:	159000ef          	jal	ra,ffffffffc02054a4 <memset>
            start += size;
ffffffffc0204b50:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204b54:	0344f463          	bgeu	s1,s4,ffffffffc0204b7c <do_execve+0x3f2>
ffffffffc0204b58:	d6e489e3          	beq	s1,a4,ffffffffc02048ca <do_execve+0x140>
ffffffffc0204b5c:	00002697          	auipc	a3,0x2
ffffffffc0204b60:	7ec68693          	addi	a3,a3,2028 # ffffffffc0207348 <default_pmm_manager+0x228>
ffffffffc0204b64:	00002617          	auipc	a2,0x2
ffffffffc0204b68:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204b6c:	2c300593          	li	a1,707
ffffffffc0204b70:	00002517          	auipc	a0,0x2
ffffffffc0204b74:	61050513          	addi	a0,a0,1552 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204b78:	eaafb0ef          	jal	ra,ffffffffc0200222 <__panic>
ffffffffc0204b7c:	ff4710e3          	bne	a4,s4,ffffffffc0204b5c <do_execve+0x3d2>
ffffffffc0204b80:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204b82:	d49b74e3          	bgeu	s6,s1,ffffffffc02048ca <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b86:	6c08                	ld	a0,24(s0)
ffffffffc0204b88:	866a                	mv	a2,s10
ffffffffc0204b8a:	85d2                	mv	a1,s4
ffffffffc0204b8c:	b19fd0ef          	jal	ra,ffffffffc02026a4 <pgdir_alloc_page>
ffffffffc0204b90:	8baa                	mv	s7,a0
ffffffffc0204b92:	dd05                	beqz	a0,ffffffffc0204aca <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b94:	6785                	lui	a5,0x1
ffffffffc0204b96:	414b0533          	sub	a0,s6,s4
ffffffffc0204b9a:	9a3e                	add	s4,s4,a5
ffffffffc0204b9c:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204ba0:	0144f463          	bgeu	s1,s4,ffffffffc0204ba8 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204ba4:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204ba8:	000cb683          	ld	a3,0(s9)
ffffffffc0204bac:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204bae:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204bb2:	40db86b3          	sub	a3,s7,a3
ffffffffc0204bb6:	8699                	srai	a3,a3,0x6
ffffffffc0204bb8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bba:	67e2                	ld	a5,24(sp)
ffffffffc0204bbc:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bc0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bc2:	02b8f663          	bgeu	a7,a1,ffffffffc0204bee <do_execve+0x464>
ffffffffc0204bc6:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bca:	4581                	li	a1,0
            start += size;
ffffffffc0204bcc:	9b32                	add	s6,s6,a2
ffffffffc0204bce:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bd0:	9536                	add	a0,a0,a3
ffffffffc0204bd2:	0d3000ef          	jal	ra,ffffffffc02054a4 <memset>
ffffffffc0204bd6:	b775                	j	ffffffffc0204b82 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bd8:	416a09b3          	sub	s3,s4,s6
ffffffffc0204bdc:	b799                	j	ffffffffc0204b22 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204bde:	59f5                	li	s3,-3
ffffffffc0204be0:	b3c1                	j	ffffffffc02049a0 <do_execve+0x216>
        while (start < end)
ffffffffc0204be2:	84da                	mv	s1,s6
ffffffffc0204be4:	bf39                	j	ffffffffc0204b02 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204be6:	59f1                	li	s3,-4
ffffffffc0204be8:	bdc5                	j	ffffffffc0204ad8 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204bea:	59e1                	li	s3,-8
ffffffffc0204bec:	b5c5                	j	ffffffffc0204acc <do_execve+0x342>
ffffffffc0204bee:	00001617          	auipc	a2,0x1
ffffffffc0204bf2:	7fa60613          	addi	a2,a2,2042 # ffffffffc02063e8 <commands+0x868>
ffffffffc0204bf6:	07100593          	li	a1,113
ffffffffc0204bfa:	00001517          	auipc	a0,0x1
ffffffffc0204bfe:	7b650513          	addi	a0,a0,1974 # ffffffffc02063b0 <commands+0x830>
ffffffffc0204c02:	e20fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c06:	00002617          	auipc	a2,0x2
ffffffffc0204c0a:	8f260613          	addi	a2,a2,-1806 # ffffffffc02064f8 <commands+0x978>
ffffffffc0204c0e:	2e200593          	li	a1,738
ffffffffc0204c12:	00002517          	auipc	a0,0x2
ffffffffc0204c16:	56e50513          	addi	a0,a0,1390 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204c1a:	e08fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c1e:	00003697          	auipc	a3,0x3
ffffffffc0204c22:	84268693          	addi	a3,a3,-1982 # ffffffffc0207460 <default_pmm_manager+0x340>
ffffffffc0204c26:	00002617          	auipc	a2,0x2
ffffffffc0204c2a:	82a60613          	addi	a2,a2,-2006 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204c2e:	2dd00593          	li	a1,733
ffffffffc0204c32:	00002517          	auipc	a0,0x2
ffffffffc0204c36:	54e50513          	addi	a0,a0,1358 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204c3a:	de8fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c3e:	00002697          	auipc	a3,0x2
ffffffffc0204c42:	7da68693          	addi	a3,a3,2010 # ffffffffc0207418 <default_pmm_manager+0x2f8>
ffffffffc0204c46:	00002617          	auipc	a2,0x2
ffffffffc0204c4a:	80a60613          	addi	a2,a2,-2038 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204c4e:	2dc00593          	li	a1,732
ffffffffc0204c52:	00002517          	auipc	a0,0x2
ffffffffc0204c56:	52e50513          	addi	a0,a0,1326 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204c5a:	dc8fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c5e:	00002697          	auipc	a3,0x2
ffffffffc0204c62:	77268693          	addi	a3,a3,1906 # ffffffffc02073d0 <default_pmm_manager+0x2b0>
ffffffffc0204c66:	00001617          	auipc	a2,0x1
ffffffffc0204c6a:	7ea60613          	addi	a2,a2,2026 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204c6e:	2db00593          	li	a1,731
ffffffffc0204c72:	00002517          	auipc	a0,0x2
ffffffffc0204c76:	50e50513          	addi	a0,a0,1294 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204c7a:	da8fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c7e:	00002697          	auipc	a3,0x2
ffffffffc0204c82:	70a68693          	addi	a3,a3,1802 # ffffffffc0207388 <default_pmm_manager+0x268>
ffffffffc0204c86:	00001617          	auipc	a2,0x1
ffffffffc0204c8a:	7ca60613          	addi	a2,a2,1994 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204c8e:	2da00593          	li	a1,730
ffffffffc0204c92:	00002517          	auipc	a0,0x2
ffffffffc0204c96:	4ee50513          	addi	a0,a0,1262 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204c9a:	d88fb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0204c9e <user_main>:
{
ffffffffc0204c9e:	1101                	addi	sp,sp,-32
    cprintf("user_main start\n");
ffffffffc0204ca0:	00003517          	auipc	a0,0x3
ffffffffc0204ca4:	80850513          	addi	a0,a0,-2040 # ffffffffc02074a8 <default_pmm_manager+0x388>
{
ffffffffc0204ca8:	ec06                	sd	ra,24(sp)
ffffffffc0204caa:	e822                	sd	s0,16(sp)
ffffffffc0204cac:	e426                	sd	s1,8(sp)
ffffffffc0204cae:	e04a                	sd	s2,0(sp)
    cprintf("user_main start\n");
ffffffffc0204cb0:	c34fb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204cb4:	000c2917          	auipc	s2,0xc2
ffffffffc0204cb8:	dfc90913          	addi	s2,s2,-516 # ffffffffc02c6ab0 <current>
ffffffffc0204cbc:	00093783          	ld	a5,0(s2)
ffffffffc0204cc0:	00003617          	auipc	a2,0x3
ffffffffc0204cc4:	80060613          	addi	a2,a2,-2048 # ffffffffc02074c0 <default_pmm_manager+0x3a0>
ffffffffc0204cc8:	00003517          	auipc	a0,0x3
ffffffffc0204ccc:	80850513          	addi	a0,a0,-2040 # ffffffffc02074d0 <default_pmm_manager+0x3b0>
ffffffffc0204cd0:	43cc                	lw	a1,4(a5)
ffffffffc0204cd2:	c12fb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    size_t len = strlen(name);
ffffffffc0204cd6:	00002517          	auipc	a0,0x2
ffffffffc0204cda:	7ea50513          	addi	a0,a0,2026 # ffffffffc02074c0 <default_pmm_manager+0x3a0>
ffffffffc0204cde:	724000ef          	jal	ra,ffffffffc0205402 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204ce2:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204ce6:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204ce8:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cec:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cee:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cf0:	6789                	lui	a5,0x2
ffffffffc0204cf2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8058>
ffffffffc0204cf6:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cf8:	8522                	mv	a0,s0
ffffffffc0204cfa:	7bc000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    current->tf = new_tf;
ffffffffc0204cfe:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204d02:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204d06:	a2668693          	addi	a3,a3,-1498 # b728 <_binary_obj___user_priority_out_size>
ffffffffc0204d0a:	00047617          	auipc	a2,0x47
ffffffffc0204d0e:	89660613          	addi	a2,a2,-1898 # ffffffffc024b5a0 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204d12:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204d14:	85a6                	mv	a1,s1
ffffffffc0204d16:	00002517          	auipc	a0,0x2
ffffffffc0204d1a:	7aa50513          	addi	a0,a0,1962 # ffffffffc02074c0 <default_pmm_manager+0x3a0>
ffffffffc0204d1e:	a6dff0ef          	jal	ra,ffffffffc020478a <do_execve>
    asm volatile(
ffffffffc0204d22:	8122                	mv	sp,s0
ffffffffc0204d24:	9acfc06f          	j	ffffffffc0200ed0 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204d28:	00002617          	auipc	a2,0x2
ffffffffc0204d2c:	7d060613          	addi	a2,a2,2000 # ffffffffc02074f8 <default_pmm_manager+0x3d8>
ffffffffc0204d30:	3c700593          	li	a1,967
ffffffffc0204d34:	00002517          	auipc	a0,0x2
ffffffffc0204d38:	44c50513          	addi	a0,a0,1100 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204d3c:	ce6fb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0204d40 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d40:	000c2797          	auipc	a5,0xc2
ffffffffc0204d44:	d707b783          	ld	a5,-656(a5) # ffffffffc02c6ab0 <current>
ffffffffc0204d48:	4705                	li	a4,1
ffffffffc0204d4a:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d4c:	4501                	li	a0,0
ffffffffc0204d4e:	8082                	ret

ffffffffc0204d50 <do_wait>:
{
ffffffffc0204d50:	1101                	addi	sp,sp,-32
ffffffffc0204d52:	e822                	sd	s0,16(sp)
ffffffffc0204d54:	e426                	sd	s1,8(sp)
ffffffffc0204d56:	ec06                	sd	ra,24(sp)
ffffffffc0204d58:	842e                	mv	s0,a1
ffffffffc0204d5a:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204d5c:	c999                	beqz	a1,ffffffffc0204d72 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204d5e:	000c2797          	auipc	a5,0xc2
ffffffffc0204d62:	d527b783          	ld	a5,-686(a5) # ffffffffc02c6ab0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d66:	7788                	ld	a0,40(a5)
ffffffffc0204d68:	4685                	li	a3,1
ffffffffc0204d6a:	4611                	li	a2,4
ffffffffc0204d6c:	894fe0ef          	jal	ra,ffffffffc0202e00 <user_mem_check>
ffffffffc0204d70:	c909                	beqz	a0,ffffffffc0204d82 <do_wait+0x32>
ffffffffc0204d72:	85a2                	mv	a1,s0
}
ffffffffc0204d74:	6442                	ld	s0,16(sp)
ffffffffc0204d76:	60e2                	ld	ra,24(sp)
ffffffffc0204d78:	8526                	mv	a0,s1
ffffffffc0204d7a:	64a2                	ld	s1,8(sp)
ffffffffc0204d7c:	6105                	addi	sp,sp,32
ffffffffc0204d7e:	f16ff06f          	j	ffffffffc0204494 <do_wait.part.0>
ffffffffc0204d82:	60e2                	ld	ra,24(sp)
ffffffffc0204d84:	6442                	ld	s0,16(sp)
ffffffffc0204d86:	64a2                	ld	s1,8(sp)
ffffffffc0204d88:	5575                	li	a0,-3
ffffffffc0204d8a:	6105                	addi	sp,sp,32
ffffffffc0204d8c:	8082                	ret

ffffffffc0204d8e <do_kill>:
{
ffffffffc0204d8e:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d90:	6789                	lui	a5,0x2
{
ffffffffc0204d92:	e406                	sd	ra,8(sp)
ffffffffc0204d94:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d96:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d9a:	17f9                	addi	a5,a5,-2
ffffffffc0204d9c:	02e7e963          	bltu	a5,a4,ffffffffc0204dce <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204da0:	842a                	mv	s0,a0
ffffffffc0204da2:	45a9                	li	a1,10
ffffffffc0204da4:	2501                	sext.w	a0,a0
ffffffffc0204da6:	317000ef          	jal	ra,ffffffffc02058bc <hash32>
ffffffffc0204daa:	02051793          	slli	a5,a0,0x20
ffffffffc0204dae:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204db2:	000be797          	auipc	a5,0xbe
ffffffffc0204db6:	c6678793          	addi	a5,a5,-922 # ffffffffc02c2a18 <hash_list>
ffffffffc0204dba:	953e                	add	a0,a0,a5
ffffffffc0204dbc:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204dbe:	a029                	j	ffffffffc0204dc8 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204dc0:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204dc4:	00870b63          	beq	a4,s0,ffffffffc0204dda <do_kill+0x4c>
ffffffffc0204dc8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204dca:	fef51be3          	bne	a0,a5,ffffffffc0204dc0 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204dce:	5475                	li	s0,-3
}
ffffffffc0204dd0:	60a2                	ld	ra,8(sp)
ffffffffc0204dd2:	8522                	mv	a0,s0
ffffffffc0204dd4:	6402                	ld	s0,0(sp)
ffffffffc0204dd6:	0141                	addi	sp,sp,16
ffffffffc0204dd8:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204dda:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204dde:	00177693          	andi	a3,a4,1
ffffffffc0204de2:	e295                	bnez	a3,ffffffffc0204e06 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204de4:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204de6:	00176713          	ori	a4,a4,1
ffffffffc0204dea:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204dee:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204df0:	fe06d0e3          	bgez	a3,ffffffffc0204dd0 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204df4:	f2878513          	addi	a0,a5,-216
ffffffffc0204df8:	294000ef          	jal	ra,ffffffffc020508c <wakeup_proc>
}
ffffffffc0204dfc:	60a2                	ld	ra,8(sp)
ffffffffc0204dfe:	8522                	mv	a0,s0
ffffffffc0204e00:	6402                	ld	s0,0(sp)
ffffffffc0204e02:	0141                	addi	sp,sp,16
ffffffffc0204e04:	8082                	ret
        return -E_KILLED;
ffffffffc0204e06:	545d                	li	s0,-9
ffffffffc0204e08:	b7e1                	j	ffffffffc0204dd0 <do_kill+0x42>

ffffffffc0204e0a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204e0a:	1101                	addi	sp,sp,-32
    int i;
    cprintf("proc_init start\n");
ffffffffc0204e0c:	00002517          	auipc	a0,0x2
ffffffffc0204e10:	70c50513          	addi	a0,a0,1804 # ffffffffc0207518 <default_pmm_manager+0x3f8>
{
ffffffffc0204e14:	e426                	sd	s1,8(sp)
ffffffffc0204e16:	ec06                	sd	ra,24(sp)
ffffffffc0204e18:	e822                	sd	s0,16(sp)
ffffffffc0204e1a:	e04a                	sd	s2,0(sp)
    cprintf("proc_init start\n");
ffffffffc0204e1c:	ac8fb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    elm->prev = elm->next = elm;
ffffffffc0204e20:	000c2797          	auipc	a5,0xc2
ffffffffc0204e24:	bf878793          	addi	a5,a5,-1032 # ffffffffc02c6a18 <proc_list>
ffffffffc0204e28:	000be497          	auipc	s1,0xbe
ffffffffc0204e2c:	bf048493          	addi	s1,s1,-1040 # ffffffffc02c2a18 <hash_list>
ffffffffc0204e30:	e79c                	sd	a5,8(a5)
ffffffffc0204e32:	e39c                	sd	a5,0(a5)
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204e34:	000c2717          	auipc	a4,0xc2
ffffffffc0204e38:	be470713          	addi	a4,a4,-1052 # ffffffffc02c6a18 <proc_list>
ffffffffc0204e3c:	87a6                	mv	a5,s1
ffffffffc0204e3e:	e79c                	sd	a5,8(a5)
ffffffffc0204e40:	e39c                	sd	a5,0(a5)
ffffffffc0204e42:	07c1                	addi	a5,a5,16
ffffffffc0204e44:	fef71de3          	bne	a4,a5,ffffffffc0204e3e <proc_init+0x34>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e48:	f49fe0ef          	jal	ra,ffffffffc0203d90 <alloc_proc>
ffffffffc0204e4c:	000c2917          	auipc	s2,0xc2
ffffffffc0204e50:	c6c90913          	addi	s2,s2,-916 # ffffffffc02c6ab8 <idleproc>
ffffffffc0204e54:	00a93023          	sd	a0,0(s2)
ffffffffc0204e58:	10050763          	beqz	a0,ffffffffc0204f66 <proc_init+0x15c>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e5c:	4789                	li	a5,2
ffffffffc0204e5e:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e60:	00004797          	auipc	a5,0x4
ffffffffc0204e64:	1a078793          	addi	a5,a5,416 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e68:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e6c:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204e6e:	4785                	li	a5,1
ffffffffc0204e70:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e72:	4641                	li	a2,16
ffffffffc0204e74:	4581                	li	a1,0
ffffffffc0204e76:	8522                	mv	a0,s0
ffffffffc0204e78:	62c000ef          	jal	ra,ffffffffc02054a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e7c:	463d                	li	a2,15
ffffffffc0204e7e:	00002597          	auipc	a1,0x2
ffffffffc0204e82:	6ca58593          	addi	a1,a1,1738 # ffffffffc0207548 <default_pmm_manager+0x428>
ffffffffc0204e86:	8522                	mv	a0,s0
ffffffffc0204e88:	62e000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e8c:	000c2717          	auipc	a4,0xc2
ffffffffc0204e90:	c3c70713          	addi	a4,a4,-964 # ffffffffc02c6ac8 <nr_process>
ffffffffc0204e94:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e96:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e9a:	4581                	li	a1,0
    nr_process++;
ffffffffc0204e9c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e9e:	4601                	li	a2,0
ffffffffc0204ea0:	fffff517          	auipc	a0,0xfffff
ffffffffc0204ea4:	7c650513          	addi	a0,a0,1990 # ffffffffc0204666 <init_main>
    nr_process++;
ffffffffc0204ea8:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204eaa:	000c2797          	auipc	a5,0xc2
ffffffffc0204eae:	c0d7b323          	sd	a3,-1018(a5) # ffffffffc02c6ab0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204eb2:	c48ff0ef          	jal	ra,ffffffffc02042fa <kernel_thread>
ffffffffc0204eb6:	842a                	mv	s0,a0
    cprintf("proc_init: init_main pid=%d\n", pid);
ffffffffc0204eb8:	85aa                	mv	a1,a0
ffffffffc0204eba:	00002517          	auipc	a0,0x2
ffffffffc0204ebe:	69650513          	addi	a0,a0,1686 # ffffffffc0207550 <default_pmm_manager+0x430>
ffffffffc0204ec2:	a22fb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    if (pid <= 0)
ffffffffc0204ec6:	08805463          	blez	s0,ffffffffc0204f4e <proc_init+0x144>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204eca:	6789                	lui	a5,0x2
ffffffffc0204ecc:	fff4071b          	addiw	a4,s0,-1
ffffffffc0204ed0:	17f9                	addi	a5,a5,-2
ffffffffc0204ed2:	0004051b          	sext.w	a0,s0
ffffffffc0204ed6:	02e7e363          	bltu	a5,a4,ffffffffc0204efc <proc_init+0xf2>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eda:	45a9                	li	a1,10
ffffffffc0204edc:	1e1000ef          	jal	ra,ffffffffc02058bc <hash32>
ffffffffc0204ee0:	02051793          	slli	a5,a0,0x20
ffffffffc0204ee4:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ee8:	96a6                	add	a3,a3,s1
ffffffffc0204eea:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204eec:	a029                	j	ffffffffc0204ef6 <proc_init+0xec>
            if (proc->pid == pid)
ffffffffc0204eee:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x800c>
ffffffffc0204ef2:	04870b63          	beq	a4,s0,ffffffffc0204f48 <proc_init+0x13e>
    return listelm->next;
ffffffffc0204ef6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ef8:	fef69be3          	bne	a3,a5,ffffffffc0204eee <proc_init+0xe4>
    return NULL;
ffffffffc0204efc:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204efe:	0b478493          	addi	s1,a5,180
ffffffffc0204f02:	4641                	li	a2,16
ffffffffc0204f04:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204f06:	000c2417          	auipc	s0,0xc2
ffffffffc0204f0a:	bba40413          	addi	s0,s0,-1094 # ffffffffc02c6ac0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f0e:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204f10:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f12:	592000ef          	jal	ra,ffffffffc02054a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f16:	463d                	li	a2,15
ffffffffc0204f18:	00002597          	auipc	a1,0x2
ffffffffc0204f1c:	67858593          	addi	a1,a1,1656 # ffffffffc0207590 <default_pmm_manager+0x470>
ffffffffc0204f20:	8526                	mv	a0,s1
ffffffffc0204f22:	594000ef          	jal	ra,ffffffffc02054b6 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f26:	00093783          	ld	a5,0(s2)
ffffffffc0204f2a:	cbb5                	beqz	a5,ffffffffc0204f9e <proc_init+0x194>
ffffffffc0204f2c:	43dc                	lw	a5,4(a5)
ffffffffc0204f2e:	eba5                	bnez	a5,ffffffffc0204f9e <proc_init+0x194>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f30:	601c                	ld	a5,0(s0)
ffffffffc0204f32:	c7b1                	beqz	a5,ffffffffc0204f7e <proc_init+0x174>
ffffffffc0204f34:	43d8                	lw	a4,4(a5)
ffffffffc0204f36:	4785                	li	a5,1
ffffffffc0204f38:	04f71363          	bne	a4,a5,ffffffffc0204f7e <proc_init+0x174>
}
ffffffffc0204f3c:	60e2                	ld	ra,24(sp)
ffffffffc0204f3e:	6442                	ld	s0,16(sp)
ffffffffc0204f40:	64a2                	ld	s1,8(sp)
ffffffffc0204f42:	6902                	ld	s2,0(sp)
ffffffffc0204f44:	6105                	addi	sp,sp,32
ffffffffc0204f46:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f48:	f2878793          	addi	a5,a5,-216
ffffffffc0204f4c:	bf4d                	j	ffffffffc0204efe <proc_init+0xf4>
        panic("create init_main failed.\n");
ffffffffc0204f4e:	00002617          	auipc	a2,0x2
ffffffffc0204f52:	62260613          	addi	a2,a2,1570 # ffffffffc0207570 <default_pmm_manager+0x450>
ffffffffc0204f56:	40300593          	li	a1,1027
ffffffffc0204f5a:	00002517          	auipc	a0,0x2
ffffffffc0204f5e:	22650513          	addi	a0,a0,550 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204f62:	ac0fb0ef          	jal	ra,ffffffffc0200222 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f66:	00002617          	auipc	a2,0x2
ffffffffc0204f6a:	5ca60613          	addi	a2,a2,1482 # ffffffffc0207530 <default_pmm_manager+0x410>
ffffffffc0204f6e:	3f300593          	li	a1,1011
ffffffffc0204f72:	00002517          	auipc	a0,0x2
ffffffffc0204f76:	20e50513          	addi	a0,a0,526 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204f7a:	aa8fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f7e:	00002697          	auipc	a3,0x2
ffffffffc0204f82:	64268693          	addi	a3,a3,1602 # ffffffffc02075c0 <default_pmm_manager+0x4a0>
ffffffffc0204f86:	00001617          	auipc	a2,0x1
ffffffffc0204f8a:	4ca60613          	addi	a2,a2,1226 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204f8e:	40a00593          	li	a1,1034
ffffffffc0204f92:	00002517          	auipc	a0,0x2
ffffffffc0204f96:	1ee50513          	addi	a0,a0,494 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204f9a:	a88fb0ef          	jal	ra,ffffffffc0200222 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f9e:	00002697          	auipc	a3,0x2
ffffffffc0204fa2:	5fa68693          	addi	a3,a3,1530 # ffffffffc0207598 <default_pmm_manager+0x478>
ffffffffc0204fa6:	00001617          	auipc	a2,0x1
ffffffffc0204faa:	4aa60613          	addi	a2,a2,1194 # ffffffffc0206450 <commands+0x8d0>
ffffffffc0204fae:	40900593          	li	a1,1033
ffffffffc0204fb2:	00002517          	auipc	a0,0x2
ffffffffc0204fb6:	1ce50513          	addi	a0,a0,462 # ffffffffc0207180 <default_pmm_manager+0x60>
ffffffffc0204fba:	a68fb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0204fbe <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204fbe:	1141                	addi	sp,sp,-16
ffffffffc0204fc0:	e022                	sd	s0,0(sp)
ffffffffc0204fc2:	e406                	sd	ra,8(sp)
ffffffffc0204fc4:	000c2417          	auipc	s0,0xc2
ffffffffc0204fc8:	aec40413          	addi	s0,s0,-1300 # ffffffffc02c6ab0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204fcc:	6018                	ld	a4,0(s0)
ffffffffc0204fce:	6f1c                	ld	a5,24(a4)
ffffffffc0204fd0:	dffd                	beqz	a5,ffffffffc0204fce <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204fd2:	16c000ef          	jal	ra,ffffffffc020513e <schedule>
ffffffffc0204fd6:	bfdd                	j	ffffffffc0204fcc <cpu_idle+0xe>

ffffffffc0204fd8 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204fd8:	1141                	addi	sp,sp,-16
ffffffffc0204fda:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204fdc:	85aa                	mv	a1,a0
{
ffffffffc0204fde:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204fe0:	00002517          	auipc	a0,0x2
ffffffffc0204fe4:	60850513          	addi	a0,a0,1544 # ffffffffc02075e8 <default_pmm_manager+0x4c8>
{
ffffffffc0204fe8:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204fea:	8fafb0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204fee:	000c2797          	auipc	a5,0xc2
ffffffffc0204ff2:	ac27b783          	ld	a5,-1342(a5) # ffffffffc02c6ab0 <current>
    if (priority == 0)
ffffffffc0204ff6:	e801                	bnez	s0,ffffffffc0205006 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204ff8:	60a2                	ld	ra,8(sp)
ffffffffc0204ffa:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204ffc:	4705                	li	a4,1
ffffffffc0204ffe:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0205002:	0141                	addi	sp,sp,16
ffffffffc0205004:	8082                	ret
ffffffffc0205006:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0205008:	1487a223          	sw	s0,324(a5)
}
ffffffffc020500c:	6402                	ld	s0,0(sp)
ffffffffc020500e:	0141                	addi	sp,sp,16
ffffffffc0205010:	8082                	ret

ffffffffc0205012 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc0205012:	000c2797          	auipc	a5,0xc2
ffffffffc0205016:	aa67b783          	ld	a5,-1370(a5) # ffffffffc02c6ab8 <idleproc>
{
ffffffffc020501a:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc020501c:	00a78c63          	beq	a5,a0,ffffffffc0205034 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc0205020:	000c2797          	auipc	a5,0xc2
ffffffffc0205024:	ab87b783          	ld	a5,-1352(a5) # ffffffffc02c6ad8 <sched_class>
ffffffffc0205028:	779c                	ld	a5,40(a5)
ffffffffc020502a:	000c2517          	auipc	a0,0xc2
ffffffffc020502e:	aa653503          	ld	a0,-1370(a0) # ffffffffc02c6ad0 <rq>
ffffffffc0205032:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc0205034:	4705                	li	a4,1
ffffffffc0205036:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc0205038:	8082                	ret

ffffffffc020503a <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc020503a:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &default_sched_class;  //sched_class = &stride_sched_class;&default_sched_class
ffffffffc020503c:	000bd717          	auipc	a4,0xbd
ffffffffc0205040:	58470713          	addi	a4,a4,1412 # ffffffffc02c25c0 <default_sched_class>
{
ffffffffc0205044:	e022                	sd	s0,0(sp)
ffffffffc0205046:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205048:	000c2797          	auipc	a5,0xc2
ffffffffc020504c:	a0078793          	addi	a5,a5,-1536 # ffffffffc02c6a48 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205050:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc0205052:	000c2517          	auipc	a0,0xc2
ffffffffc0205056:	9d650513          	addi	a0,a0,-1578 # ffffffffc02c6a28 <__rq>
ffffffffc020505a:	e79c                	sd	a5,8(a5)
ffffffffc020505c:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc020505e:	4795                	li	a5,5
ffffffffc0205060:	c95c                	sw	a5,20(a0)
    sched_class = &default_sched_class;  //sched_class = &stride_sched_class;&default_sched_class
ffffffffc0205062:	000c2417          	auipc	s0,0xc2
ffffffffc0205066:	a7640413          	addi	s0,s0,-1418 # ffffffffc02c6ad8 <sched_class>
    rq = &__rq;
ffffffffc020506a:	000c2797          	auipc	a5,0xc2
ffffffffc020506e:	a6a7b323          	sd	a0,-1434(a5) # ffffffffc02c6ad0 <rq>
    sched_class = &default_sched_class;  //sched_class = &stride_sched_class;&default_sched_class
ffffffffc0205072:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0205074:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205076:	601c                	ld	a5,0(s0)
}
ffffffffc0205078:	6402                	ld	s0,0(sp)
ffffffffc020507a:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020507c:	638c                	ld	a1,0(a5)
ffffffffc020507e:	00002517          	auipc	a0,0x2
ffffffffc0205082:	58250513          	addi	a0,a0,1410 # ffffffffc0207600 <default_pmm_manager+0x4e0>
}
ffffffffc0205086:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205088:	85cfb06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc020508c <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020508c:	4118                	lw	a4,0(a0)
{
ffffffffc020508e:	1101                	addi	sp,sp,-32
ffffffffc0205090:	ec06                	sd	ra,24(sp)
ffffffffc0205092:	e822                	sd	s0,16(sp)
ffffffffc0205094:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205096:	478d                	li	a5,3
ffffffffc0205098:	08f70363          	beq	a4,a5,ffffffffc020511e <wakeup_proc+0x92>
ffffffffc020509c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020509e:	100027f3          	csrr	a5,sstatus
ffffffffc02050a2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02050a4:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050a6:	e7bd                	bnez	a5,ffffffffc0205114 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02050a8:	4789                	li	a5,2
ffffffffc02050aa:	04f70863          	beq	a4,a5,ffffffffc02050fa <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02050ae:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02050b0:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc02050b4:	000c2797          	auipc	a5,0xc2
ffffffffc02050b8:	9fc7b783          	ld	a5,-1540(a5) # ffffffffc02c6ab0 <current>
ffffffffc02050bc:	02878363          	beq	a5,s0,ffffffffc02050e2 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc02050c0:	000c2797          	auipc	a5,0xc2
ffffffffc02050c4:	9f87b783          	ld	a5,-1544(a5) # ffffffffc02c6ab8 <idleproc>
ffffffffc02050c8:	00f40d63          	beq	s0,a5,ffffffffc02050e2 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc02050cc:	000c2797          	auipc	a5,0xc2
ffffffffc02050d0:	a0c7b783          	ld	a5,-1524(a5) # ffffffffc02c6ad8 <sched_class>
ffffffffc02050d4:	6b9c                	ld	a5,16(a5)
ffffffffc02050d6:	85a2                	mv	a1,s0
ffffffffc02050d8:	000c2517          	auipc	a0,0xc2
ffffffffc02050dc:	9f853503          	ld	a0,-1544(a0) # ffffffffc02c6ad0 <rq>
ffffffffc02050e0:	9782                	jalr	a5
    if (flag)
ffffffffc02050e2:	e491                	bnez	s1,ffffffffc02050ee <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02050e4:	60e2                	ld	ra,24(sp)
ffffffffc02050e6:	6442                	ld	s0,16(sp)
ffffffffc02050e8:	64a2                	ld	s1,8(sp)
ffffffffc02050ea:	6105                	addi	sp,sp,32
ffffffffc02050ec:	8082                	ret
ffffffffc02050ee:	6442                	ld	s0,16(sp)
ffffffffc02050f0:	60e2                	ld	ra,24(sp)
ffffffffc02050f2:	64a2                	ld	s1,8(sp)
ffffffffc02050f4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02050f6:	8b9fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02050fa:	00002617          	auipc	a2,0x2
ffffffffc02050fe:	55660613          	addi	a2,a2,1366 # ffffffffc0207650 <default_pmm_manager+0x530>
ffffffffc0205102:	05100593          	li	a1,81
ffffffffc0205106:	00002517          	auipc	a0,0x2
ffffffffc020510a:	53250513          	addi	a0,a0,1330 # ffffffffc0207638 <default_pmm_manager+0x518>
ffffffffc020510e:	97cfb0ef          	jal	ra,ffffffffc020028a <__warn>
ffffffffc0205112:	bfc1                	j	ffffffffc02050e2 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205114:	8a1fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205118:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020511a:	4485                	li	s1,1
ffffffffc020511c:	b771                	j	ffffffffc02050a8 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020511e:	00002697          	auipc	a3,0x2
ffffffffc0205122:	4fa68693          	addi	a3,a3,1274 # ffffffffc0207618 <default_pmm_manager+0x4f8>
ffffffffc0205126:	00001617          	auipc	a2,0x1
ffffffffc020512a:	32a60613          	addi	a2,a2,810 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020512e:	04200593          	li	a1,66
ffffffffc0205132:	00002517          	auipc	a0,0x2
ffffffffc0205136:	50650513          	addi	a0,a0,1286 # ffffffffc0207638 <default_pmm_manager+0x518>
ffffffffc020513a:	8e8fb0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc020513e <schedule>:

void schedule(void)
{
ffffffffc020513e:	7179                	addi	sp,sp,-48
ffffffffc0205140:	f406                	sd	ra,40(sp)
ffffffffc0205142:	f022                	sd	s0,32(sp)
ffffffffc0205144:	ec26                	sd	s1,24(sp)
ffffffffc0205146:	e84a                	sd	s2,16(sp)
ffffffffc0205148:	e44e                	sd	s3,8(sp)
ffffffffc020514a:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020514c:	100027f3          	csrr	a5,sstatus
ffffffffc0205150:	8b89                	andi	a5,a5,2
ffffffffc0205152:	4a01                	li	s4,0
ffffffffc0205154:	e3cd                	bnez	a5,ffffffffc02051f6 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205156:	000c2497          	auipc	s1,0xc2
ffffffffc020515a:	95a48493          	addi	s1,s1,-1702 # ffffffffc02c6ab0 <current>
ffffffffc020515e:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc0205160:	000c2997          	auipc	s3,0xc2
ffffffffc0205164:	97898993          	addi	s3,s3,-1672 # ffffffffc02c6ad8 <sched_class>
ffffffffc0205168:	000c2917          	auipc	s2,0xc2
ffffffffc020516c:	96890913          	addi	s2,s2,-1688 # ffffffffc02c6ad0 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc0205170:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc0205172:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205176:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc0205178:	0009b783          	ld	a5,0(s3)
ffffffffc020517c:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205180:	04e68e63          	beq	a3,a4,ffffffffc02051dc <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205184:	739c                	ld	a5,32(a5)
ffffffffc0205186:	9782                	jalr	a5
ffffffffc0205188:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020518a:	c521                	beqz	a0,ffffffffc02051d2 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc020518c:	0009b783          	ld	a5,0(s3)
ffffffffc0205190:	00093503          	ld	a0,0(s2)
ffffffffc0205194:	85a2                	mv	a1,s0
ffffffffc0205196:	6f9c                	ld	a5,24(a5)
ffffffffc0205198:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020519a:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc020519c:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc020519e:	2785                	addiw	a5,a5,1
ffffffffc02051a0:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc02051a2:	00870563          	beq	a4,s0,ffffffffc02051ac <schedule+0x6e>
        {
            proc_run(next);
ffffffffc02051a6:	8522                	mv	a0,s0
ffffffffc02051a8:	cfdfe0ef          	jal	ra,ffffffffc0203ea4 <proc_run>
    if (flag)
ffffffffc02051ac:	000a1a63          	bnez	s4,ffffffffc02051c0 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051b0:	70a2                	ld	ra,40(sp)
ffffffffc02051b2:	7402                	ld	s0,32(sp)
ffffffffc02051b4:	64e2                	ld	s1,24(sp)
ffffffffc02051b6:	6942                	ld	s2,16(sp)
ffffffffc02051b8:	69a2                	ld	s3,8(sp)
ffffffffc02051ba:	6a02                	ld	s4,0(sp)
ffffffffc02051bc:	6145                	addi	sp,sp,48
ffffffffc02051be:	8082                	ret
ffffffffc02051c0:	7402                	ld	s0,32(sp)
ffffffffc02051c2:	70a2                	ld	ra,40(sp)
ffffffffc02051c4:	64e2                	ld	s1,24(sp)
ffffffffc02051c6:	6942                	ld	s2,16(sp)
ffffffffc02051c8:	69a2                	ld	s3,8(sp)
ffffffffc02051ca:	6a02                	ld	s4,0(sp)
ffffffffc02051cc:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02051ce:	fe0fb06f          	j	ffffffffc02009ae <intr_enable>
            next = idleproc;
ffffffffc02051d2:	000c2417          	auipc	s0,0xc2
ffffffffc02051d6:	8e643403          	ld	s0,-1818(s0) # ffffffffc02c6ab8 <idleproc>
ffffffffc02051da:	b7c1                	j	ffffffffc020519a <schedule+0x5c>
    if (proc != idleproc)
ffffffffc02051dc:	000c2717          	auipc	a4,0xc2
ffffffffc02051e0:	8dc73703          	ld	a4,-1828(a4) # ffffffffc02c6ab8 <idleproc>
ffffffffc02051e4:	fae580e3          	beq	a1,a4,ffffffffc0205184 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc02051e8:	6b9c                	ld	a5,16(a5)
ffffffffc02051ea:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc02051ec:	0009b783          	ld	a5,0(s3)
ffffffffc02051f0:	00093503          	ld	a0,0(s2)
ffffffffc02051f4:	bf41                	j	ffffffffc0205184 <schedule+0x46>
        intr_disable();
ffffffffc02051f6:	fbefb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02051fa:	4a05                	li	s4,1
ffffffffc02051fc:	bfa9                	j	ffffffffc0205156 <schedule+0x18>

ffffffffc02051fe <RR_pick_next>:
    return listelm->next;
ffffffffc02051fe:	651c                	ld	a5,8(a0)
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
ffffffffc0205200:	00f50563          	beq	a0,a5,ffffffffc020520a <RR_pick_next+0xc>
        return le2proc(le, run_link);
ffffffffc0205204:	ef078513          	addi	a0,a5,-272
ffffffffc0205208:	8082                	ret
    }
    return NULL;
ffffffffc020520a:	4501                	li	a0,0
}
ffffffffc020520c:	8082                	ret

ffffffffc020520e <RR_proc_tick>:
 * is the flag variable for process switching.
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    if (proc->time_slice > 0) {
ffffffffc020520e:	1205a783          	lw	a5,288(a1)
ffffffffc0205212:	00f05563          	blez	a5,ffffffffc020521c <RR_proc_tick+0xe>
        proc->time_slice --;
ffffffffc0205216:	37fd                	addiw	a5,a5,-1
ffffffffc0205218:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0) {
ffffffffc020521c:	e399                	bnez	a5,ffffffffc0205222 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc020521e:	4785                	li	a5,1
ffffffffc0205220:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205222:	8082                	ret

ffffffffc0205224 <RR_init>:
{
ffffffffc0205224:	1141                	addi	sp,sp,-16
ffffffffc0205226:	e022                	sd	s0,0(sp)
ffffffffc0205228:	842a                	mv	s0,a0
    cprintf("RR_init called\n");
ffffffffc020522a:	00002517          	auipc	a0,0x2
ffffffffc020522e:	44650513          	addi	a0,a0,1094 # ffffffffc0207670 <default_pmm_manager+0x550>
{
ffffffffc0205232:	e406                	sd	ra,8(sp)
    cprintf("RR_init called\n");
ffffffffc0205234:	eb1fa0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    rq->proc_num = 0;
ffffffffc0205238:	4795                	li	a5,5
ffffffffc020523a:	1782                	slli	a5,a5,0x20
ffffffffc020523c:	e81c                	sd	a5,16(s0)
}
ffffffffc020523e:	60a2                	ld	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205240:	e400                	sd	s0,8(s0)
ffffffffc0205242:	e000                	sd	s0,0(s0)
ffffffffc0205244:	6402                	ld	s0,0(sp)
ffffffffc0205246:	0141                	addi	sp,sp,16
ffffffffc0205248:	8082                	ret

ffffffffc020524a <RR_dequeue>:
    return list->next == list;
ffffffffc020524a:	1185b703          	ld	a4,280(a1)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc020524e:	11058793          	addi	a5,a1,272
ffffffffc0205252:	02e78363          	beq	a5,a4,ffffffffc0205278 <RR_dequeue+0x2e>
ffffffffc0205256:	1085b683          	ld	a3,264(a1)
ffffffffc020525a:	00a69f63          	bne	a3,a0,ffffffffc0205278 <RR_dequeue+0x2e>
    __list_del(listelm->prev, listelm->next);
ffffffffc020525e:	1105b503          	ld	a0,272(a1)
    rq->proc_num --;
ffffffffc0205262:	4a90                	lw	a2,16(a3)
    prev->next = next;
ffffffffc0205264:	e518                	sd	a4,8(a0)
    next->prev = prev;
ffffffffc0205266:	e308                	sd	a0,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0205268:	10f5bc23          	sd	a5,280(a1)
ffffffffc020526c:	10f5b823          	sd	a5,272(a1)
ffffffffc0205270:	fff6079b          	addiw	a5,a2,-1
ffffffffc0205274:	ca9c                	sw	a5,16(a3)
ffffffffc0205276:	8082                	ret
{
ffffffffc0205278:	1141                	addi	sp,sp,-16
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc020527a:	00002697          	auipc	a3,0x2
ffffffffc020527e:	40668693          	addi	a3,a3,1030 # ffffffffc0207680 <default_pmm_manager+0x560>
ffffffffc0205282:	00001617          	auipc	a2,0x1
ffffffffc0205286:	1ce60613          	addi	a2,a2,462 # ffffffffc0206450 <commands+0x8d0>
ffffffffc020528a:	03b00593          	li	a1,59
ffffffffc020528e:	00002517          	auipc	a0,0x2
ffffffffc0205292:	42a50513          	addi	a0,a0,1066 # ffffffffc02076b8 <default_pmm_manager+0x598>
{
ffffffffc0205296:	e406                	sd	ra,8(sp)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc0205298:	f8bfa0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc020529c <RR_enqueue>:
    assert(list_empty(&(proc->run_link)));
ffffffffc020529c:	1185b703          	ld	a4,280(a1)
ffffffffc02052a0:	11058793          	addi	a5,a1,272
ffffffffc02052a4:	02e79d63          	bne	a5,a4,ffffffffc02052de <RR_enqueue+0x42>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02052a8:	6118                	ld	a4,0(a0)
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02052aa:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc02052ae:	e11c                	sd	a5,0(a0)
ffffffffc02052b0:	e71c                	sd	a5,8(a4)
    elm->next = next;
ffffffffc02052b2:	10a5bc23          	sd	a0,280(a1)
    elm->prev = prev;
ffffffffc02052b6:	10e5b823          	sd	a4,272(a1)
ffffffffc02052ba:	495c                	lw	a5,20(a0)
ffffffffc02052bc:	ea89                	bnez	a3,ffffffffc02052ce <RR_enqueue+0x32>
        proc->time_slice = rq->max_time_slice;
ffffffffc02052be:	12f5a023          	sw	a5,288(a1)
    rq->proc_num ++;
ffffffffc02052c2:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc02052c4:	10a5b423          	sd	a0,264(a1)
    rq->proc_num ++;
ffffffffc02052c8:	2785                	addiw	a5,a5,1
ffffffffc02052ca:	c91c                	sw	a5,16(a0)
ffffffffc02052cc:	8082                	ret
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02052ce:	fed7c8e3          	blt	a5,a3,ffffffffc02052be <RR_enqueue+0x22>
    rq->proc_num ++;
ffffffffc02052d2:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc02052d4:	10a5b423          	sd	a0,264(a1)
    rq->proc_num ++;
ffffffffc02052d8:	2785                	addiw	a5,a5,1
ffffffffc02052da:	c91c                	sw	a5,16(a0)
ffffffffc02052dc:	8082                	ret
{
ffffffffc02052de:	1141                	addi	sp,sp,-16
    assert(list_empty(&(proc->run_link)));
ffffffffc02052e0:	00002697          	auipc	a3,0x2
ffffffffc02052e4:	3f868693          	addi	a3,a3,1016 # ffffffffc02076d8 <default_pmm_manager+0x5b8>
ffffffffc02052e8:	00001617          	auipc	a2,0x1
ffffffffc02052ec:	16860613          	addi	a2,a2,360 # ffffffffc0206450 <commands+0x8d0>
ffffffffc02052f0:	02800593          	li	a1,40
ffffffffc02052f4:	00002517          	auipc	a0,0x2
ffffffffc02052f8:	3c450513          	addi	a0,a0,964 # ffffffffc02076b8 <default_pmm_manager+0x598>
{
ffffffffc02052fc:	e406                	sd	ra,8(sp)
    assert(list_empty(&(proc->run_link)));
ffffffffc02052fe:	f25fa0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0205302 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205302:	000c1797          	auipc	a5,0xc1
ffffffffc0205306:	7ae7b783          	ld	a5,1966(a5) # ffffffffc02c6ab0 <current>
}
ffffffffc020530a:	43c8                	lw	a0,4(a5)
ffffffffc020530c:	8082                	ret

ffffffffc020530e <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020530e:	4501                	li	a0,0
ffffffffc0205310:	8082                	ret

ffffffffc0205312 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc0205312:	000c1797          	auipc	a5,0xc1
ffffffffc0205316:	75e7b783          	ld	a5,1886(a5) # ffffffffc02c6a70 <ticks>
ffffffffc020531a:	0027951b          	slliw	a0,a5,0x2
ffffffffc020531e:	9d3d                	addw	a0,a0,a5
}
ffffffffc0205320:	0015151b          	slliw	a0,a0,0x1
ffffffffc0205324:	8082                	ret

ffffffffc0205326 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc0205326:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205328:	1141                	addi	sp,sp,-16
ffffffffc020532a:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc020532c:	cadff0ef          	jal	ra,ffffffffc0204fd8 <lab6_set_priority>
    return 0;
}
ffffffffc0205330:	60a2                	ld	ra,8(sp)
ffffffffc0205332:	4501                	li	a0,0
ffffffffc0205334:	0141                	addi	sp,sp,16
ffffffffc0205336:	8082                	ret

ffffffffc0205338 <sys_putc>:
    cputchar(c);
ffffffffc0205338:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020533a:	1141                	addi	sp,sp,-16
ffffffffc020533c:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020533e:	dddfa0ef          	jal	ra,ffffffffc020011a <cputchar>
}
ffffffffc0205342:	60a2                	ld	ra,8(sp)
ffffffffc0205344:	4501                	li	a0,0
ffffffffc0205346:	0141                	addi	sp,sp,16
ffffffffc0205348:	8082                	ret

ffffffffc020534a <sys_kill>:
    return do_kill(pid);
ffffffffc020534a:	4108                	lw	a0,0(a0)
ffffffffc020534c:	a43ff06f          	j	ffffffffc0204d8e <do_kill>

ffffffffc0205350 <sys_yield>:
    return do_yield();
ffffffffc0205350:	9f1ff06f          	j	ffffffffc0204d40 <do_yield>

ffffffffc0205354 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205354:	6d14                	ld	a3,24(a0)
ffffffffc0205356:	6910                	ld	a2,16(a0)
ffffffffc0205358:	650c                	ld	a1,8(a0)
ffffffffc020535a:	6108                	ld	a0,0(a0)
ffffffffc020535c:	c2eff06f          	j	ffffffffc020478a <do_execve>

ffffffffc0205360 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205360:	650c                	ld	a1,8(a0)
ffffffffc0205362:	4108                	lw	a0,0(a0)
ffffffffc0205364:	9edff06f          	j	ffffffffc0204d50 <do_wait>

ffffffffc0205368 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205368:	000c1797          	auipc	a5,0xc1
ffffffffc020536c:	7487b783          	ld	a5,1864(a5) # ffffffffc02c6ab0 <current>
ffffffffc0205370:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205372:	4501                	li	a0,0
ffffffffc0205374:	6a0c                	ld	a1,16(a2)
ffffffffc0205376:	babfe06f          	j	ffffffffc0203f20 <do_fork>

ffffffffc020537a <sys_exit>:
    return do_exit(error_code);
ffffffffc020537a:	4108                	lw	a0,0(a0)
ffffffffc020537c:	fcffe06f          	j	ffffffffc020434a <do_exit>

ffffffffc0205380 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205380:	715d                	addi	sp,sp,-80
ffffffffc0205382:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205384:	000c1497          	auipc	s1,0xc1
ffffffffc0205388:	72c48493          	addi	s1,s1,1836 # ffffffffc02c6ab0 <current>
ffffffffc020538c:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020538e:	e0a2                	sd	s0,64(sp)
ffffffffc0205390:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205392:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205394:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205396:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020539a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020539e:	0327ee63          	bltu	a5,s2,ffffffffc02053da <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc02053a2:	00391713          	slli	a4,s2,0x3
ffffffffc02053a6:	00002797          	auipc	a5,0x2
ffffffffc02053aa:	3aa78793          	addi	a5,a5,938 # ffffffffc0207750 <syscalls>
ffffffffc02053ae:	97ba                	add	a5,a5,a4
ffffffffc02053b0:	639c                	ld	a5,0(a5)
ffffffffc02053b2:	c785                	beqz	a5,ffffffffc02053da <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc02053b4:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02053b6:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02053b8:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02053ba:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02053bc:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02053be:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02053c0:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02053c2:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02053c4:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02053c6:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053c8:	0028                	addi	a0,sp,8
ffffffffc02053ca:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053cc:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053ce:	e828                	sd	a0,80(s0)
}
ffffffffc02053d0:	6406                	ld	s0,64(sp)
ffffffffc02053d2:	74e2                	ld	s1,56(sp)
ffffffffc02053d4:	7942                	ld	s2,48(sp)
ffffffffc02053d6:	6161                	addi	sp,sp,80
ffffffffc02053d8:	8082                	ret
    print_trapframe(tf);
ffffffffc02053da:	8522                	mv	a0,s0
ffffffffc02053dc:	fc6fb0ef          	jal	ra,ffffffffc0200ba2 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053e0:	609c                	ld	a5,0(s1)
ffffffffc02053e2:	86ca                	mv	a3,s2
ffffffffc02053e4:	00002617          	auipc	a2,0x2
ffffffffc02053e8:	32460613          	addi	a2,a2,804 # ffffffffc0207708 <default_pmm_manager+0x5e8>
ffffffffc02053ec:	43d8                	lw	a4,4(a5)
ffffffffc02053ee:	06c00593          	li	a1,108
ffffffffc02053f2:	0b478793          	addi	a5,a5,180
ffffffffc02053f6:	00002517          	auipc	a0,0x2
ffffffffc02053fa:	34250513          	addi	a0,a0,834 # ffffffffc0207738 <default_pmm_manager+0x618>
ffffffffc02053fe:	e25fa0ef          	jal	ra,ffffffffc0200222 <__panic>

ffffffffc0205402 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205402:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205406:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205408:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020540a:	cb81                	beqz	a5,ffffffffc020541a <strlen+0x18>
        cnt ++;
ffffffffc020540c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020540e:	00a707b3          	add	a5,a4,a0
ffffffffc0205412:	0007c783          	lbu	a5,0(a5)
ffffffffc0205416:	fbfd                	bnez	a5,ffffffffc020540c <strlen+0xa>
ffffffffc0205418:	8082                	ret
    }
    return cnt;
}
ffffffffc020541a:	8082                	ret

ffffffffc020541c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020541c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020541e:	e589                	bnez	a1,ffffffffc0205428 <strnlen+0xc>
ffffffffc0205420:	a811                	j	ffffffffc0205434 <strnlen+0x18>
        cnt ++;
ffffffffc0205422:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205424:	00f58863          	beq	a1,a5,ffffffffc0205434 <strnlen+0x18>
ffffffffc0205428:	00f50733          	add	a4,a0,a5
ffffffffc020542c:	00074703          	lbu	a4,0(a4)
ffffffffc0205430:	fb6d                	bnez	a4,ffffffffc0205422 <strnlen+0x6>
ffffffffc0205432:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205434:	852e                	mv	a0,a1
ffffffffc0205436:	8082                	ret

ffffffffc0205438 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205438:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020543a:	0005c703          	lbu	a4,0(a1)
ffffffffc020543e:	0785                	addi	a5,a5,1
ffffffffc0205440:	0585                	addi	a1,a1,1
ffffffffc0205442:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205446:	fb75                	bnez	a4,ffffffffc020543a <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205448:	8082                	ret

ffffffffc020544a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020544a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020544e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205452:	cb89                	beqz	a5,ffffffffc0205464 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205454:	0505                	addi	a0,a0,1
ffffffffc0205456:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205458:	fee789e3          	beq	a5,a4,ffffffffc020544a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020545c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205460:	9d19                	subw	a0,a0,a4
ffffffffc0205462:	8082                	ret
ffffffffc0205464:	4501                	li	a0,0
ffffffffc0205466:	bfed                	j	ffffffffc0205460 <strcmp+0x16>

ffffffffc0205468 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205468:	c20d                	beqz	a2,ffffffffc020548a <strncmp+0x22>
ffffffffc020546a:	962e                	add	a2,a2,a1
ffffffffc020546c:	a031                	j	ffffffffc0205478 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020546e:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205470:	00e79a63          	bne	a5,a4,ffffffffc0205484 <strncmp+0x1c>
ffffffffc0205474:	00b60b63          	beq	a2,a1,ffffffffc020548a <strncmp+0x22>
ffffffffc0205478:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020547c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020547e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205482:	f7f5                	bnez	a5,ffffffffc020546e <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205484:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205488:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020548a:	4501                	li	a0,0
ffffffffc020548c:	8082                	ret

ffffffffc020548e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020548e:	00054783          	lbu	a5,0(a0)
ffffffffc0205492:	c799                	beqz	a5,ffffffffc02054a0 <strchr+0x12>
        if (*s == c) {
ffffffffc0205494:	00f58763          	beq	a1,a5,ffffffffc02054a2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205498:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020549c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020549e:	fbfd                	bnez	a5,ffffffffc0205494 <strchr+0x6>
    }
    return NULL;
ffffffffc02054a0:	4501                	li	a0,0
}
ffffffffc02054a2:	8082                	ret

ffffffffc02054a4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02054a4:	ca01                	beqz	a2,ffffffffc02054b4 <memset+0x10>
ffffffffc02054a6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02054a8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02054aa:	0785                	addi	a5,a5,1
ffffffffc02054ac:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02054b0:	fec79de3          	bne	a5,a2,ffffffffc02054aa <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02054b4:	8082                	ret

ffffffffc02054b6 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02054b6:	ca19                	beqz	a2,ffffffffc02054cc <memcpy+0x16>
ffffffffc02054b8:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02054ba:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02054bc:	0005c703          	lbu	a4,0(a1)
ffffffffc02054c0:	0585                	addi	a1,a1,1
ffffffffc02054c2:	0785                	addi	a5,a5,1
ffffffffc02054c4:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02054c8:	fec59ae3          	bne	a1,a2,ffffffffc02054bc <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02054cc:	8082                	ret

ffffffffc02054ce <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02054ce:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054d2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02054d4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054d8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02054da:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054de:	f022                	sd	s0,32(sp)
ffffffffc02054e0:	ec26                	sd	s1,24(sp)
ffffffffc02054e2:	e84a                	sd	s2,16(sp)
ffffffffc02054e4:	f406                	sd	ra,40(sp)
ffffffffc02054e6:	e44e                	sd	s3,8(sp)
ffffffffc02054e8:	84aa                	mv	s1,a0
ffffffffc02054ea:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02054ec:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02054f0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02054f2:	03067e63          	bgeu	a2,a6,ffffffffc020552e <printnum+0x60>
ffffffffc02054f6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02054f8:	00805763          	blez	s0,ffffffffc0205506 <printnum+0x38>
ffffffffc02054fc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02054fe:	85ca                	mv	a1,s2
ffffffffc0205500:	854e                	mv	a0,s3
ffffffffc0205502:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205504:	fc65                	bnez	s0,ffffffffc02054fc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205506:	1a02                	slli	s4,s4,0x20
ffffffffc0205508:	00003797          	auipc	a5,0x3
ffffffffc020550c:	a4878793          	addi	a5,a5,-1464 # ffffffffc0207f50 <syscalls+0x800>
ffffffffc0205510:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205514:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205516:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205518:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020551c:	70a2                	ld	ra,40(sp)
ffffffffc020551e:	69a2                	ld	s3,8(sp)
ffffffffc0205520:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205522:	85ca                	mv	a1,s2
ffffffffc0205524:	87a6                	mv	a5,s1
}
ffffffffc0205526:	6942                	ld	s2,16(sp)
ffffffffc0205528:	64e2                	ld	s1,24(sp)
ffffffffc020552a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020552c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020552e:	03065633          	divu	a2,a2,a6
ffffffffc0205532:	8722                	mv	a4,s0
ffffffffc0205534:	f9bff0ef          	jal	ra,ffffffffc02054ce <printnum>
ffffffffc0205538:	b7f9                	j	ffffffffc0205506 <printnum+0x38>

ffffffffc020553a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020553a:	7119                	addi	sp,sp,-128
ffffffffc020553c:	f4a6                	sd	s1,104(sp)
ffffffffc020553e:	f0ca                	sd	s2,96(sp)
ffffffffc0205540:	ecce                	sd	s3,88(sp)
ffffffffc0205542:	e8d2                	sd	s4,80(sp)
ffffffffc0205544:	e4d6                	sd	s5,72(sp)
ffffffffc0205546:	e0da                	sd	s6,64(sp)
ffffffffc0205548:	fc5e                	sd	s7,56(sp)
ffffffffc020554a:	f06a                	sd	s10,32(sp)
ffffffffc020554c:	fc86                	sd	ra,120(sp)
ffffffffc020554e:	f8a2                	sd	s0,112(sp)
ffffffffc0205550:	f862                	sd	s8,48(sp)
ffffffffc0205552:	f466                	sd	s9,40(sp)
ffffffffc0205554:	ec6e                	sd	s11,24(sp)
ffffffffc0205556:	892a                	mv	s2,a0
ffffffffc0205558:	84ae                	mv	s1,a1
ffffffffc020555a:	8d32                	mv	s10,a2
ffffffffc020555c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020555e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205562:	5b7d                	li	s6,-1
ffffffffc0205564:	00003a97          	auipc	s5,0x3
ffffffffc0205568:	a18a8a93          	addi	s5,s5,-1512 # ffffffffc0207f7c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020556c:	00003b97          	auipc	s7,0x3
ffffffffc0205570:	c2cb8b93          	addi	s7,s7,-980 # ffffffffc0208198 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205574:	000d4503          	lbu	a0,0(s10)
ffffffffc0205578:	001d0413          	addi	s0,s10,1
ffffffffc020557c:	01350a63          	beq	a0,s3,ffffffffc0205590 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205580:	c121                	beqz	a0,ffffffffc02055c0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205582:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205584:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205586:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205588:	fff44503          	lbu	a0,-1(s0)
ffffffffc020558c:	ff351ae3          	bne	a0,s3,ffffffffc0205580 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205590:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205594:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205598:	4c81                	li	s9,0
ffffffffc020559a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020559c:	5c7d                	li	s8,-1
ffffffffc020559e:	5dfd                	li	s11,-1
ffffffffc02055a0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02055a4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02055aa:	0ff5f593          	zext.b	a1,a1
ffffffffc02055ae:	00140d13          	addi	s10,s0,1
ffffffffc02055b2:	04b56263          	bltu	a0,a1,ffffffffc02055f6 <vprintfmt+0xbc>
ffffffffc02055b6:	058a                	slli	a1,a1,0x2
ffffffffc02055b8:	95d6                	add	a1,a1,s5
ffffffffc02055ba:	4194                	lw	a3,0(a1)
ffffffffc02055bc:	96d6                	add	a3,a3,s5
ffffffffc02055be:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02055c0:	70e6                	ld	ra,120(sp)
ffffffffc02055c2:	7446                	ld	s0,112(sp)
ffffffffc02055c4:	74a6                	ld	s1,104(sp)
ffffffffc02055c6:	7906                	ld	s2,96(sp)
ffffffffc02055c8:	69e6                	ld	s3,88(sp)
ffffffffc02055ca:	6a46                	ld	s4,80(sp)
ffffffffc02055cc:	6aa6                	ld	s5,72(sp)
ffffffffc02055ce:	6b06                	ld	s6,64(sp)
ffffffffc02055d0:	7be2                	ld	s7,56(sp)
ffffffffc02055d2:	7c42                	ld	s8,48(sp)
ffffffffc02055d4:	7ca2                	ld	s9,40(sp)
ffffffffc02055d6:	7d02                	ld	s10,32(sp)
ffffffffc02055d8:	6de2                	ld	s11,24(sp)
ffffffffc02055da:	6109                	addi	sp,sp,128
ffffffffc02055dc:	8082                	ret
            padc = '0';
ffffffffc02055de:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02055e0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e4:	846a                	mv	s0,s10
ffffffffc02055e6:	00140d13          	addi	s10,s0,1
ffffffffc02055ea:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02055ee:	0ff5f593          	zext.b	a1,a1
ffffffffc02055f2:	fcb572e3          	bgeu	a0,a1,ffffffffc02055b6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02055f6:	85a6                	mv	a1,s1
ffffffffc02055f8:	02500513          	li	a0,37
ffffffffc02055fc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02055fe:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205602:	8d22                	mv	s10,s0
ffffffffc0205604:	f73788e3          	beq	a5,s3,ffffffffc0205574 <vprintfmt+0x3a>
ffffffffc0205608:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020560c:	1d7d                	addi	s10,s10,-1
ffffffffc020560e:	ff379de3          	bne	a5,s3,ffffffffc0205608 <vprintfmt+0xce>
ffffffffc0205612:	b78d                	j	ffffffffc0205574 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205614:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205618:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020561c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020561e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205622:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205626:	02d86463          	bltu	a6,a3,ffffffffc020564e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020562a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020562e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205632:	0186873b          	addw	a4,a3,s8
ffffffffc0205636:	0017171b          	slliw	a4,a4,0x1
ffffffffc020563a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020563c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205640:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205642:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205646:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020564a:	fed870e3          	bgeu	a6,a3,ffffffffc020562a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020564e:	f40ddce3          	bgez	s11,ffffffffc02055a6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205652:	8de2                	mv	s11,s8
ffffffffc0205654:	5c7d                	li	s8,-1
ffffffffc0205656:	bf81                	j	ffffffffc02055a6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205658:	fffdc693          	not	a3,s11
ffffffffc020565c:	96fd                	srai	a3,a3,0x3f
ffffffffc020565e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205662:	00144603          	lbu	a2,1(s0)
ffffffffc0205666:	2d81                	sext.w	s11,s11
ffffffffc0205668:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020566a:	bf35                	j	ffffffffc02055a6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020566c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205670:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205674:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205676:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205678:	bfd9                	j	ffffffffc020564e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020567a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020567c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205680:	01174463          	blt	a4,a7,ffffffffc0205688 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205684:	1a088e63          	beqz	a7,ffffffffc0205840 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205688:	000a3603          	ld	a2,0(s4)
ffffffffc020568c:	46c1                	li	a3,16
ffffffffc020568e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205690:	2781                	sext.w	a5,a5
ffffffffc0205692:	876e                	mv	a4,s11
ffffffffc0205694:	85a6                	mv	a1,s1
ffffffffc0205696:	854a                	mv	a0,s2
ffffffffc0205698:	e37ff0ef          	jal	ra,ffffffffc02054ce <printnum>
            break;
ffffffffc020569c:	bde1                	j	ffffffffc0205574 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020569e:	000a2503          	lw	a0,0(s4)
ffffffffc02056a2:	85a6                	mv	a1,s1
ffffffffc02056a4:	0a21                	addi	s4,s4,8
ffffffffc02056a6:	9902                	jalr	s2
            break;
ffffffffc02056a8:	b5f1                	j	ffffffffc0205574 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02056aa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056ac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056b0:	01174463          	blt	a4,a7,ffffffffc02056b8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02056b4:	18088163          	beqz	a7,ffffffffc0205836 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02056b8:	000a3603          	ld	a2,0(s4)
ffffffffc02056bc:	46a9                	li	a3,10
ffffffffc02056be:	8a2e                	mv	s4,a1
ffffffffc02056c0:	bfc1                	j	ffffffffc0205690 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056c2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02056c6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056c8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02056ca:	bdf1                	j	ffffffffc02055a6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02056cc:	85a6                	mv	a1,s1
ffffffffc02056ce:	02500513          	li	a0,37
ffffffffc02056d2:	9902                	jalr	s2
            break;
ffffffffc02056d4:	b545                	j	ffffffffc0205574 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056d6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02056da:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056dc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02056de:	b5e1                	j	ffffffffc02055a6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02056e0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056e2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056e6:	01174463          	blt	a4,a7,ffffffffc02056ee <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02056ea:	14088163          	beqz	a7,ffffffffc020582c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02056ee:	000a3603          	ld	a2,0(s4)
ffffffffc02056f2:	46a1                	li	a3,8
ffffffffc02056f4:	8a2e                	mv	s4,a1
ffffffffc02056f6:	bf69                	j	ffffffffc0205690 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02056f8:	03000513          	li	a0,48
ffffffffc02056fc:	85a6                	mv	a1,s1
ffffffffc02056fe:	e03e                	sd	a5,0(sp)
ffffffffc0205700:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205702:	85a6                	mv	a1,s1
ffffffffc0205704:	07800513          	li	a0,120
ffffffffc0205708:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020570a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020570c:	6782                	ld	a5,0(sp)
ffffffffc020570e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205710:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205714:	bfb5                	j	ffffffffc0205690 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205716:	000a3403          	ld	s0,0(s4)
ffffffffc020571a:	008a0713          	addi	a4,s4,8
ffffffffc020571e:	e03a                	sd	a4,0(sp)
ffffffffc0205720:	14040263          	beqz	s0,ffffffffc0205864 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205724:	0fb05763          	blez	s11,ffffffffc0205812 <vprintfmt+0x2d8>
ffffffffc0205728:	02d00693          	li	a3,45
ffffffffc020572c:	0cd79163          	bne	a5,a3,ffffffffc02057ee <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205730:	00044783          	lbu	a5,0(s0)
ffffffffc0205734:	0007851b          	sext.w	a0,a5
ffffffffc0205738:	cf85                	beqz	a5,ffffffffc0205770 <vprintfmt+0x236>
ffffffffc020573a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020573e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205742:	000c4563          	bltz	s8,ffffffffc020574c <vprintfmt+0x212>
ffffffffc0205746:	3c7d                	addiw	s8,s8,-1
ffffffffc0205748:	036c0263          	beq	s8,s6,ffffffffc020576c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020574c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020574e:	0e0c8e63          	beqz	s9,ffffffffc020584a <vprintfmt+0x310>
ffffffffc0205752:	3781                	addiw	a5,a5,-32
ffffffffc0205754:	0ef47b63          	bgeu	s0,a5,ffffffffc020584a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205758:	03f00513          	li	a0,63
ffffffffc020575c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020575e:	000a4783          	lbu	a5,0(s4)
ffffffffc0205762:	3dfd                	addiw	s11,s11,-1
ffffffffc0205764:	0a05                	addi	s4,s4,1
ffffffffc0205766:	0007851b          	sext.w	a0,a5
ffffffffc020576a:	ffe1                	bnez	a5,ffffffffc0205742 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020576c:	01b05963          	blez	s11,ffffffffc020577e <vprintfmt+0x244>
ffffffffc0205770:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205772:	85a6                	mv	a1,s1
ffffffffc0205774:	02000513          	li	a0,32
ffffffffc0205778:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020577a:	fe0d9be3          	bnez	s11,ffffffffc0205770 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020577e:	6a02                	ld	s4,0(sp)
ffffffffc0205780:	bbd5                	j	ffffffffc0205574 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205782:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205784:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205788:	01174463          	blt	a4,a7,ffffffffc0205790 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020578c:	08088d63          	beqz	a7,ffffffffc0205826 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205790:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205794:	0a044d63          	bltz	s0,ffffffffc020584e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205798:	8622                	mv	a2,s0
ffffffffc020579a:	8a66                	mv	s4,s9
ffffffffc020579c:	46a9                	li	a3,10
ffffffffc020579e:	bdcd                	j	ffffffffc0205690 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02057a0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02057a4:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02057a6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02057a8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02057ac:	8fb5                	xor	a5,a5,a3
ffffffffc02057ae:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02057b2:	02d74163          	blt	a4,a3,ffffffffc02057d4 <vprintfmt+0x29a>
ffffffffc02057b6:	00369793          	slli	a5,a3,0x3
ffffffffc02057ba:	97de                	add	a5,a5,s7
ffffffffc02057bc:	639c                	ld	a5,0(a5)
ffffffffc02057be:	cb99                	beqz	a5,ffffffffc02057d4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02057c0:	86be                	mv	a3,a5
ffffffffc02057c2:	00000617          	auipc	a2,0x0
ffffffffc02057c6:	13e60613          	addi	a2,a2,318 # ffffffffc0205900 <etext+0x2e>
ffffffffc02057ca:	85a6                	mv	a1,s1
ffffffffc02057cc:	854a                	mv	a0,s2
ffffffffc02057ce:	0ce000ef          	jal	ra,ffffffffc020589c <printfmt>
ffffffffc02057d2:	b34d                	j	ffffffffc0205574 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02057d4:	00002617          	auipc	a2,0x2
ffffffffc02057d8:	79c60613          	addi	a2,a2,1948 # ffffffffc0207f70 <syscalls+0x820>
ffffffffc02057dc:	85a6                	mv	a1,s1
ffffffffc02057de:	854a                	mv	a0,s2
ffffffffc02057e0:	0bc000ef          	jal	ra,ffffffffc020589c <printfmt>
ffffffffc02057e4:	bb41                	j	ffffffffc0205574 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02057e6:	00002417          	auipc	s0,0x2
ffffffffc02057ea:	78240413          	addi	s0,s0,1922 # ffffffffc0207f68 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057ee:	85e2                	mv	a1,s8
ffffffffc02057f0:	8522                	mv	a0,s0
ffffffffc02057f2:	e43e                	sd	a5,8(sp)
ffffffffc02057f4:	c29ff0ef          	jal	ra,ffffffffc020541c <strnlen>
ffffffffc02057f8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02057fc:	01b05b63          	blez	s11,ffffffffc0205812 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205800:	67a2                	ld	a5,8(sp)
ffffffffc0205802:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205806:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205808:	85a6                	mv	a1,s1
ffffffffc020580a:	8552                	mv	a0,s4
ffffffffc020580c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020580e:	fe0d9ce3          	bnez	s11,ffffffffc0205806 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205812:	00044783          	lbu	a5,0(s0)
ffffffffc0205816:	00140a13          	addi	s4,s0,1
ffffffffc020581a:	0007851b          	sext.w	a0,a5
ffffffffc020581e:	d3a5                	beqz	a5,ffffffffc020577e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205820:	05e00413          	li	s0,94
ffffffffc0205824:	bf39                	j	ffffffffc0205742 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205826:	000a2403          	lw	s0,0(s4)
ffffffffc020582a:	b7ad                	j	ffffffffc0205794 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020582c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205830:	46a1                	li	a3,8
ffffffffc0205832:	8a2e                	mv	s4,a1
ffffffffc0205834:	bdb1                	j	ffffffffc0205690 <vprintfmt+0x156>
ffffffffc0205836:	000a6603          	lwu	a2,0(s4)
ffffffffc020583a:	46a9                	li	a3,10
ffffffffc020583c:	8a2e                	mv	s4,a1
ffffffffc020583e:	bd89                	j	ffffffffc0205690 <vprintfmt+0x156>
ffffffffc0205840:	000a6603          	lwu	a2,0(s4)
ffffffffc0205844:	46c1                	li	a3,16
ffffffffc0205846:	8a2e                	mv	s4,a1
ffffffffc0205848:	b5a1                	j	ffffffffc0205690 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020584a:	9902                	jalr	s2
ffffffffc020584c:	bf09                	j	ffffffffc020575e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020584e:	85a6                	mv	a1,s1
ffffffffc0205850:	02d00513          	li	a0,45
ffffffffc0205854:	e03e                	sd	a5,0(sp)
ffffffffc0205856:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205858:	6782                	ld	a5,0(sp)
ffffffffc020585a:	8a66                	mv	s4,s9
ffffffffc020585c:	40800633          	neg	a2,s0
ffffffffc0205860:	46a9                	li	a3,10
ffffffffc0205862:	b53d                	j	ffffffffc0205690 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205864:	03b05163          	blez	s11,ffffffffc0205886 <vprintfmt+0x34c>
ffffffffc0205868:	02d00693          	li	a3,45
ffffffffc020586c:	f6d79de3          	bne	a5,a3,ffffffffc02057e6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205870:	00002417          	auipc	s0,0x2
ffffffffc0205874:	6f840413          	addi	s0,s0,1784 # ffffffffc0207f68 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205878:	02800793          	li	a5,40
ffffffffc020587c:	02800513          	li	a0,40
ffffffffc0205880:	00140a13          	addi	s4,s0,1
ffffffffc0205884:	bd6d                	j	ffffffffc020573e <vprintfmt+0x204>
ffffffffc0205886:	00002a17          	auipc	s4,0x2
ffffffffc020588a:	6e3a0a13          	addi	s4,s4,1763 # ffffffffc0207f69 <syscalls+0x819>
ffffffffc020588e:	02800513          	li	a0,40
ffffffffc0205892:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205896:	05e00413          	li	s0,94
ffffffffc020589a:	b565                	j	ffffffffc0205742 <vprintfmt+0x208>

ffffffffc020589c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020589c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020589e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02058a2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02058a4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02058a6:	ec06                	sd	ra,24(sp)
ffffffffc02058a8:	f83a                	sd	a4,48(sp)
ffffffffc02058aa:	fc3e                	sd	a5,56(sp)
ffffffffc02058ac:	e0c2                	sd	a6,64(sp)
ffffffffc02058ae:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02058b0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02058b2:	c89ff0ef          	jal	ra,ffffffffc020553a <vprintfmt>
}
ffffffffc02058b6:	60e2                	ld	ra,24(sp)
ffffffffc02058b8:	6161                	addi	sp,sp,80
ffffffffc02058ba:	8082                	ret

ffffffffc02058bc <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02058bc:	9e3707b7          	lui	a5,0x9e370
ffffffffc02058c0:	2785                	addiw	a5,a5,1
ffffffffc02058c2:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02058c6:	02000793          	li	a5,32
ffffffffc02058ca:	9f8d                	subw	a5,a5,a1
}
ffffffffc02058cc:	00f5553b          	srlw	a0,a0,a5
ffffffffc02058d0:	8082                	ret
