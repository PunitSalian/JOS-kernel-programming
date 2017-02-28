
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 0d 53 00 00       	call   f010536e <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 00 5a 10 f0       	push   $0xf0105a00
f010006d:	e8 17 36 00 00       	call   f0103689 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 e7 35 00 00       	call   f0103663 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 70 6c 10 f0 	movl   $0xf0106c70,(%esp)
f0100083:	e8 01 36 00 00       	call   f0103689 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 66 08 00 00       	call   f01008fb <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 c0 26 f0       	mov    $0xf026c008,%eax
f01000a6:	2d a0 97 22 f0       	sub    $0xf02297a0,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 a0 97 22 f0       	push   $0xf02297a0
f01000b3:	e8 94 4c 00 00       	call   f0104d4c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 6c 5a 10 f0       	push   $0xf0105a6c
f01000ca:	e8 ba 35 00 00       	call   f0103689 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 a3 11 00 00       	call   f0101277 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 97 2d 00 00       	call   f0102e70 <env_init>
	trap_init();
f01000d9:	e8 92 36 00 00       	call   f0103770 <trap_init>

	// Lab 4 multiprocessor initialization functions
	 mp_init();
f01000de:	e8 81 4f 00 00       	call   f0105064 <mp_init>
	lapic_init();
f01000e3:	e8 a1 52 00 00       	call   f0105389 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 c3 34 00 00       	call   f01035b0 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 e3 54 00 00       	call   f01055dc <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 24 5a 10 f0       	push   $0xf0105a24
f010010f:	6a 55                	push   $0x55
f0100111:	68 87 5a 10 f0       	push   $0xf0105a87
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 ca 4f 10 f0       	mov    $0xf0104fca,%eax
f0100123:	2d 50 4f 10 f0       	sub    $0xf0104f50,%eax
f0100128:	50                   	push   %eax
f0100129:	68 50 4f 10 f0       	push   $0xf0104f50
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 61 4c 00 00       	call   f0104d99 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 27 52 00 00       	call   f010536e <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010016b:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 56 53 00 00       	call   f01054d7 <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0100196:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 b8 0d 22 f0       	push   $0xf0220db8
f01001a9:	e8 a2 2e 00 00       	call   f0103050 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 27 3f 00 00       	call   f01040da <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 48 5a 10 f0       	push   $0xf0105a48
f01001cb:	6a 6c                	push   $0x6c
f01001cd:	68 87 5a 10 f0       	push   $0xf0105a87
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 8a 51 00 00       	call   f010536e <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 93 5a 10 f0       	push   $0xf0105a93
f01001ed:	e8 97 34 00 00       	call   f0103689 <cprintf>

	lapic_init();
f01001f2:	e8 92 51 00 00       	call   f0105389 <lapic_init>
	env_init_percpu();
f01001f7:	e8 44 2c 00 00       	call   f0102e40 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 9c 34 00 00       	call   f010369d <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 68 51 00 00       	call   f010536e <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 b8 53 00 00       	call   f01055dc <spin_lock>
	//
	// Your code here:

	// Remove this after you finish Exercise 4
	lock_kernel();
    sched_yield();	
f0100224:	e8 b1 3e 00 00       	call   f01040da <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 a9 5a 10 f0       	push   $0xf0105aa9
f010023e:	e8 46 34 00 00       	call   f0103689 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 14 34 00 00       	call   f0103663 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 70 6c 10 f0 	movl   $0xf0106c70,(%esp)
f0100256:	e8 2e 34 00 00       	call   f0103689 <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f01002a0:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f8 00 00 00    	je     f01003cb <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002d3:	a8 20                	test   $0x20,%al
f01002d5:	0f 85 f6 00 00 00    	jne    f01003d1 <kbd_proc_data+0x10c>
f01002db:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 36                	jns    f0100335 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 20 5c 10 f0 	movzbl -0xfefa3e0(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 20 5c 10 f0 	movzbl -0xfefa3e0(%edx),%eax
f0100358:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010035e:	0f b6 8a 20 5b 10 f0 	movzbl -0xfefa4e0(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d 00 5b 10 f0 	mov    -0xfefa500(,%ecx,4),%ecx
f0100378:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010037f:	a8 08                	test   $0x8,%al
f0100381:	74 1b                	je     f010039e <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100383:	89 da                	mov    %ebx,%edx
f0100385:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100388:	83 f9 19             	cmp    $0x19,%ecx
f010038b:	77 05                	ja     f0100392 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010038d:	83 eb 20             	sub    $0x20,%ebx
f0100390:	eb 0c                	jmp    f010039e <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 19             	cmp    $0x19,%edx
f010039b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 33                	jne    f01003d7 <kbd_proc_data+0x112>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 2b                	jne    f01003d7 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 c3 5a 10 f0       	push   $0xf0105ac3
f01003b4:	e8 d0 32 00 00       	call   f0103689 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	ba 92 00 00 00       	mov    $0x92,%edx
f01003be:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c7:	89 d8                	mov    %ebx,%eax
f01003c9:	eb 0e                	jmp    f01003d9 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d0:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d7:	89 d8                	mov    %ebx,%eax
}
f01003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003dc:	c9                   	leave  
f01003dd:	c3                   	ret    

f01003de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
f01003e1:	57                   	push   %edi
f01003e2:	56                   	push   %esi
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 1c             	sub    $0x1c,%esp
f01003e7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003e9:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ee:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f8:	eb 09                	jmp    f0100403 <cons_putc+0x25>
f01003fa:	89 ca                	mov    %ecx,%edx
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	ec                   	in     (%dx),%al
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100400:	83 c3 01             	add    $0x1,%ebx
f0100403:	89 f2                	mov    %esi,%edx
f0100405:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100406:	a8 20                	test   $0x20,%al
f0100408:	75 08                	jne    f0100412 <cons_putc+0x34>
f010040a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100410:	7e e8                	jle    f01003fa <cons_putc+0x1c>
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100417:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010041c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100422:	be 79 03 00 00       	mov    $0x379,%esi
f0100427:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042c:	eb 09                	jmp    f0100437 <cons_putc+0x59>
f010042e:	89 ca                	mov    %ecx,%edx
f0100430:	ec                   	in     (%dx),%al
f0100431:	ec                   	in     (%dx),%al
f0100432:	ec                   	in     (%dx),%al
f0100433:	ec                   	in     (%dx),%al
f0100434:	83 c3 01             	add    $0x1,%ebx
f0100437:	89 f2                	mov    %esi,%edx
f0100439:	ec                   	in     (%dx),%al
f010043a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100440:	7f 04                	jg     f0100446 <cons_putc+0x68>
f0100442:	84 c0                	test   %al,%al
f0100444:	79 e8                	jns    f010042e <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100455:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100460:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100461:	89 fa                	mov    %edi,%edx
f0100463:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100469:	89 f8                	mov    %edi,%eax
f010046b:	80 cc 07             	or     $0x7,%ah
f010046e:	85 d2                	test   %edx,%edx
f0100470:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100473:	89 f8                	mov    %edi,%eax
f0100475:	0f b6 c0             	movzbl %al,%eax
f0100478:	83 f8 09             	cmp    $0x9,%eax
f010047b:	74 74                	je     f01004f1 <cons_putc+0x113>
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	7f 0a                	jg     f010048c <cons_putc+0xae>
f0100482:	83 f8 08             	cmp    $0x8,%eax
f0100485:	74 14                	je     f010049b <cons_putc+0xbd>
f0100487:	e9 99 00 00 00       	jmp    f0100525 <cons_putc+0x147>
f010048c:	83 f8 0a             	cmp    $0xa,%eax
f010048f:	74 3a                	je     f01004cb <cons_putc+0xed>
f0100491:	83 f8 0d             	cmp    $0xd,%eax
f0100494:	74 3d                	je     f01004d3 <cons_putc+0xf5>
f0100496:	e9 8a 00 00 00       	jmp    f0100525 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010049b:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004ef:	eb 52                	jmp    f0100543 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 e3 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 d9 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 cf fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 c5 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 bb fe ff ff       	call   f01003de <cons_putc>
f0100523:	eb 1e                	jmp    f0100543 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100525:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 31 48 00 00       	call   f0104d99 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010056e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100574:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057a:	83 c4 10             	add    $0x10,%esp
f010057d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100582:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100585:	39 d0                	cmp    %edx,%eax
f0100587:	75 f4                	jne    f010057d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100589:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f01005a6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005a9:	89 d8                	mov    %ebx,%eax
f01005ab:	66 c1 e8 08          	shr    $0x8,%ax
f01005af:	89 f2                	mov    %esi,%edx
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c2:	5b                   	pop    %ebx
f01005c3:	5e                   	pop    %esi
f01005c4:	5f                   	pop    %edi
f01005c5:	5d                   	pop    %ebp
f01005c6:	c3                   	ret    

f01005c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005c7:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005ce:	74 11                	je     f01005e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005d6:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005db:	e8 a2 fc ff ff       	call   f0100282 <cons_intr>
}
f01005e0:	c9                   	leave  
f01005e1:	f3 c3                	repz ret 

f01005e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e3:	55                   	push   %ebp
f01005e4:	89 e5                	mov    %esp,%ebp
f01005e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005e9:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005ee:	e8 8f fc ff ff       	call   f0100282 <cons_intr>
}
f01005f3:	c9                   	leave  
f01005f4:	c3                   	ret    

f01005f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005fb:	e8 c7 ff ff ff       	call   f01005c7 <serial_intr>
	kbd_intr();
f0100600:	e8 de ff ff ff       	call   f01005e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100605:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f010060a:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f010061b:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100622:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100624:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062a:	75 11                	jne    f010063d <cons_getc+0x48>
			cons.rpos = 0;
f010062c:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f0100633:	00 00 00 
f0100636:	eb 05                	jmp    f010063d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	57                   	push   %edi
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100648:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100656:	5a a5 
	if (*cp != 0xA55A) {
f0100658:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100663:	74 11                	je     f0100676 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100665:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f010066c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100674:	eb 16                	jmp    f010068c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100676:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010067d:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f0100684:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100687:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010068c:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f0100692:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100697:	89 fa                	mov    %edi,%edx
f0100699:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069a:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069d:	89 da                	mov    %ebx,%edx
f010069f:	ec                   	in     (%dx),%al
f01006a0:	0f b6 c8             	movzbl %al,%ecx
f01006a3:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 da                	mov    %ebx,%edx
f01006b0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b1:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 5c 2e 00 00       	call   f0103538 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e6:	89 f2                	mov    %esi,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006ee:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006f9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ee                   	out    %al,(%dx)
f0100701:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100706:	b8 00 00 00 00       	mov    $0x0,%eax
f010070b:	ee                   	out    %al,(%dx)
f010070c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100711:	b8 03 00 00 00       	mov    $0x3,%eax
f0100716:	ee                   	out    %al,(%dx)
f0100717:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100727:	b8 01 00 00 00       	mov    $0x1,%eax
f010072c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100732:	ec                   	in     (%dx),%al
f0100733:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100735:	83 c4 10             	add    $0x10,%esp
f0100738:	3c ff                	cmp    $0xff,%al
f010073a:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f0100741:	89 f2                	mov    %esi,%edx
f0100743:	ec                   	in     (%dx),%al
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	80 f9 ff             	cmp    $0xff,%cl
f010074a:	75 10                	jne    f010075c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 cf 5a 10 f0       	push   $0xf0105acf
f0100754:	e8 30 2f 00 00       	call   f0103689 <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010075f:	5b                   	pop    %ebx
f0100760:	5e                   	pop    %esi
f0100761:	5f                   	pop    %edi
f0100762:	5d                   	pop    %ebp
f0100763:	c3                   	ret    

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 6c fc ff ff       	call   f01003de <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 76 fe ff ff       	call   f01005f5 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100795:	68 20 5d 10 f0       	push   $0xf0105d20
f010079a:	68 3e 5d 10 f0       	push   $0xf0105d3e
f010079f:	68 43 5d 10 f0       	push   $0xf0105d43
f01007a4:	e8 e0 2e 00 00       	call   f0103689 <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 cc 5d 10 f0       	push   $0xf0105dcc
f01007b1:	68 4c 5d 10 f0       	push   $0xf0105d4c
f01007b6:	68 43 5d 10 f0       	push   $0xf0105d43
f01007bb:	e8 c9 2e 00 00       	call   f0103689 <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	68 55 5d 10 f0       	push   $0xf0105d55
f01007c8:	68 5d 5d 10 f0       	push   $0xf0105d5d
f01007cd:	68 43 5d 10 f0       	push   $0xf0105d43
f01007d2:	e8 b2 2e 00 00       	call   f0103689 <cprintf>
	return 0;
}
f01007d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dc:	c9                   	leave  
f01007dd:	c3                   	ret    

f01007de <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007de:	55                   	push   %ebp
f01007df:	89 e5                	mov    %esp,%ebp
f01007e1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e4:	68 67 5d 10 f0       	push   $0xf0105d67
f01007e9:	e8 9b 2e 00 00       	call   f0103689 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ee:	83 c4 08             	add    $0x8,%esp
f01007f1:	68 0c 00 10 00       	push   $0x10000c
f01007f6:	68 f4 5d 10 f0       	push   $0xf0105df4
f01007fb:	e8 89 2e 00 00       	call   f0103689 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 0c 00 10 00       	push   $0x10000c
f0100808:	68 0c 00 10 f0       	push   $0xf010000c
f010080d:	68 1c 5e 10 f0       	push   $0xf0105e1c
f0100812:	e8 72 2e 00 00       	call   f0103689 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 f1 59 10 00       	push   $0x1059f1
f010081f:	68 f1 59 10 f0       	push   $0xf01059f1
f0100824:	68 40 5e 10 f0       	push   $0xf0105e40
f0100829:	e8 5b 2e 00 00       	call   f0103689 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 a0 97 22 00       	push   $0x2297a0
f0100836:	68 a0 97 22 f0       	push   $0xf02297a0
f010083b:	68 64 5e 10 f0       	push   $0xf0105e64
f0100840:	e8 44 2e 00 00       	call   f0103689 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100845:	83 c4 0c             	add    $0xc,%esp
f0100848:	68 08 c0 26 00       	push   $0x26c008
f010084d:	68 08 c0 26 f0       	push   $0xf026c008
f0100852:	68 88 5e 10 f0       	push   $0xf0105e88
f0100857:	e8 2d 2e 00 00       	call   f0103689 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010085c:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f0100861:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100866:	83 c4 08             	add    $0x8,%esp
f0100869:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010086e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100874:	85 c0                	test   %eax,%eax
f0100876:	0f 48 c2             	cmovs  %edx,%eax
f0100879:	c1 f8 0a             	sar    $0xa,%eax
f010087c:	50                   	push   %eax
f010087d:	68 ac 5e 10 f0       	push   $0xf0105eac
f0100882:	e8 02 2e 00 00       	call   f0103689 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100887:	b8 00 00 00 00       	mov    $0x0,%eax
f010088c:	c9                   	leave  
f010088d:	c3                   	ret    

f010088e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010088e:	55                   	push   %ebp
f010088f:	89 e5                	mov    %esp,%ebp
f0100891:	56                   	push   %esi
f0100892:	53                   	push   %ebx
f0100893:	83 ec 20             	sub    $0x20,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100896:	89 eb                	mov    %ebp,%ebx
	while(pointer)
	{
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",pointer, pointer[1], pointer[2], pointer[3], pointer[4], pointer[5], pointer[6]);
	    //cprintf("ebp %08x eip %08x args %08x %08x  %08x \n",pointer, &pointer[1], &pointer[2], &pointer[3], pointer[4]);

	    debuginfo_eip(pointer[1],&info);
f0100898:	8d 75 e0             	lea    -0x20(%ebp),%esi

	uint32_t *pointer;
	pointer=(uint32_t *) read_ebp();

	struct Eipdebuginfo info;
	while(pointer)
f010089b:	eb 4e                	jmp    f01008eb <mon_backtrace+0x5d>
	{
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",pointer, pointer[1], pointer[2], pointer[3], pointer[4], pointer[5], pointer[6]);
f010089d:	ff 73 18             	pushl  0x18(%ebx)
f01008a0:	ff 73 14             	pushl  0x14(%ebx)
f01008a3:	ff 73 10             	pushl  0x10(%ebx)
f01008a6:	ff 73 0c             	pushl  0xc(%ebx)
f01008a9:	ff 73 08             	pushl  0x8(%ebx)
f01008ac:	ff 73 04             	pushl  0x4(%ebx)
f01008af:	53                   	push   %ebx
f01008b0:	68 d8 5e 10 f0       	push   $0xf0105ed8
f01008b5:	e8 cf 2d 00 00       	call   f0103689 <cprintf>
	    //cprintf("ebp %08x eip %08x args %08x %08x  %08x \n",pointer, &pointer[1], &pointer[2], &pointer[3], pointer[4]);

	    debuginfo_eip(pointer[1],&info);
f01008ba:	83 c4 18             	add    $0x18,%esp
f01008bd:	56                   	push   %esi
f01008be:	ff 73 04             	pushl  0x4(%ebx)
f01008c1:	e8 25 3a 00 00       	call   f01042eb <debuginfo_eip>
	    cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(pointer[1]-info.eip_fn_addr));
f01008c6:	83 c4 08             	add    $0x8,%esp
f01008c9:	8b 43 04             	mov    0x4(%ebx),%eax
f01008cc:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008cf:	50                   	push   %eax
f01008d0:	ff 75 e8             	pushl  -0x18(%ebp)
f01008d3:	ff 75 ec             	pushl  -0x14(%ebp)
f01008d6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01008d9:	ff 75 e0             	pushl  -0x20(%ebp)
f01008dc:	68 80 5d 10 f0       	push   $0xf0105d80
f01008e1:	e8 a3 2d 00 00       	call   f0103689 <cprintf>
	    
	    //cprintf("\nebp[0] = %x\n",pointer[0]);
	    pointer=(uint32_t *)pointer[0];
f01008e6:	8b 1b                	mov    (%ebx),%ebx
f01008e8:	83 c4 20             	add    $0x20,%esp

	uint32_t *pointer;
	pointer=(uint32_t *) read_ebp();

	struct Eipdebuginfo info;
	while(pointer)
f01008eb:	85 db                	test   %ebx,%ebx
f01008ed:	75 ae                	jne    f010089d <mon_backtrace+0xf>
	    
	    //cprintf("\nebp[0] = %x\n",pointer[0]);
	    pointer=(uint32_t *)pointer[0];
	}
return 0;
}
f01008ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008f7:	5b                   	pop    %ebx
f01008f8:	5e                   	pop    %esi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	57                   	push   %edi
f01008ff:	56                   	push   %esi
f0100900:	53                   	push   %ebx
f0100901:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100904:	68 0c 5f 10 f0       	push   $0xf0105f0c
f0100909:	e8 7b 2d 00 00       	call   f0103689 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010090e:	c7 04 24 30 5f 10 f0 	movl   $0xf0105f30,(%esp)
f0100915:	e8 6f 2d 00 00       	call   f0103689 <cprintf>

	if (tf != NULL)
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100921:	74 0e                	je     f0100931 <monitor+0x36>
		print_trapframe(tf);
f0100923:	83 ec 0c             	sub    $0xc,%esp
f0100926:	ff 75 08             	pushl  0x8(%ebp)
f0100929:	e8 0e 32 00 00       	call   f0103b3c <print_trapframe>
f010092e:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100931:	83 ec 0c             	sub    $0xc,%esp
f0100934:	68 90 5d 10 f0       	push   $0xf0105d90
f0100939:	e8 b7 41 00 00       	call   f0104af5 <readline>
f010093e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100940:	83 c4 10             	add    $0x10,%esp
f0100943:	85 c0                	test   %eax,%eax
f0100945:	74 ea                	je     f0100931 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100947:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010094e:	be 00 00 00 00       	mov    $0x0,%esi
f0100953:	eb 0a                	jmp    f010095f <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100955:	c6 03 00             	movb   $0x0,(%ebx)
f0100958:	89 f7                	mov    %esi,%edi
f010095a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010095d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010095f:	0f b6 03             	movzbl (%ebx),%eax
f0100962:	84 c0                	test   %al,%al
f0100964:	74 63                	je     f01009c9 <monitor+0xce>
f0100966:	83 ec 08             	sub    $0x8,%esp
f0100969:	0f be c0             	movsbl %al,%eax
f010096c:	50                   	push   %eax
f010096d:	68 94 5d 10 f0       	push   $0xf0105d94
f0100972:	e8 98 43 00 00       	call   f0104d0f <strchr>
f0100977:	83 c4 10             	add    $0x10,%esp
f010097a:	85 c0                	test   %eax,%eax
f010097c:	75 d7                	jne    f0100955 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010097e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100981:	74 46                	je     f01009c9 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100983:	83 fe 0f             	cmp    $0xf,%esi
f0100986:	75 14                	jne    f010099c <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100988:	83 ec 08             	sub    $0x8,%esp
f010098b:	6a 10                	push   $0x10
f010098d:	68 99 5d 10 f0       	push   $0xf0105d99
f0100992:	e8 f2 2c 00 00       	call   f0103689 <cprintf>
f0100997:	83 c4 10             	add    $0x10,%esp
f010099a:	eb 95                	jmp    f0100931 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010099c:	8d 7e 01             	lea    0x1(%esi),%edi
f010099f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009a3:	eb 03                	jmp    f01009a8 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009a5:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009a8:	0f b6 03             	movzbl (%ebx),%eax
f01009ab:	84 c0                	test   %al,%al
f01009ad:	74 ae                	je     f010095d <monitor+0x62>
f01009af:	83 ec 08             	sub    $0x8,%esp
f01009b2:	0f be c0             	movsbl %al,%eax
f01009b5:	50                   	push   %eax
f01009b6:	68 94 5d 10 f0       	push   $0xf0105d94
f01009bb:	e8 4f 43 00 00       	call   f0104d0f <strchr>
f01009c0:	83 c4 10             	add    $0x10,%esp
f01009c3:	85 c0                	test   %eax,%eax
f01009c5:	74 de                	je     f01009a5 <monitor+0xaa>
f01009c7:	eb 94                	jmp    f010095d <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009c9:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d0:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009d1:	85 f6                	test   %esi,%esi
f01009d3:	0f 84 58 ff ff ff    	je     f0100931 <monitor+0x36>
f01009d9:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009de:	83 ec 08             	sub    $0x8,%esp
f01009e1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e4:	ff 34 85 60 5f 10 f0 	pushl  -0xfefa0a0(,%eax,4)
f01009eb:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ee:	e8 be 42 00 00       	call   f0104cb1 <strcmp>
f01009f3:	83 c4 10             	add    $0x10,%esp
f01009f6:	85 c0                	test   %eax,%eax
f01009f8:	75 21                	jne    f0100a1b <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01009fa:	83 ec 04             	sub    $0x4,%esp
f01009fd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a00:	ff 75 08             	pushl  0x8(%ebp)
f0100a03:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a06:	52                   	push   %edx
f0100a07:	56                   	push   %esi
f0100a08:	ff 14 85 68 5f 10 f0 	call   *-0xfefa098(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a0f:	83 c4 10             	add    $0x10,%esp
f0100a12:	85 c0                	test   %eax,%eax
f0100a14:	78 25                	js     f0100a3b <monitor+0x140>
f0100a16:	e9 16 ff ff ff       	jmp    f0100931 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a1b:	83 c3 01             	add    $0x1,%ebx
f0100a1e:	83 fb 03             	cmp    $0x3,%ebx
f0100a21:	75 bb                	jne    f01009de <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a23:	83 ec 08             	sub    $0x8,%esp
f0100a26:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a29:	68 b6 5d 10 f0       	push   $0xf0105db6
f0100a2e:	e8 56 2c 00 00       	call   f0103689 <cprintf>
f0100a33:	83 c4 10             	add    $0x10,%esp
f0100a36:	e9 f6 fe ff ff       	jmp    f0100931 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a3b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a3e:	5b                   	pop    %ebx
f0100a3f:	5e                   	pop    %esi
f0100a40:	5f                   	pop    %edi
f0100a41:	5d                   	pop    %ebp
f0100a42:	c3                   	ret    

f0100a43 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a43:	55                   	push   %ebp
f0100a44:	89 e5                	mov    %esp,%ebp
f0100a46:	56                   	push   %esi
f0100a47:	53                   	push   %ebx
f0100a48:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a4a:	83 ec 0c             	sub    $0xc,%esp
f0100a4d:	50                   	push   %eax
f0100a4e:	e8 b7 2a 00 00       	call   f010350a <mc146818_read>
f0100a53:	89 c6                	mov    %eax,%esi
f0100a55:	83 c3 01             	add    $0x1,%ebx
f0100a58:	89 1c 24             	mov    %ebx,(%esp)
f0100a5b:	e8 aa 2a 00 00       	call   f010350a <mc146818_read>
f0100a60:	c1 e0 08             	shl    $0x8,%eax
f0100a63:	09 f0                	or     %esi,%eax
}
f0100a65:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a68:	5b                   	pop    %ebx
f0100a69:	5e                   	pop    %esi
f0100a6a:	5d                   	pop    %ebp
f0100a6b:	c3                   	ret    

f0100a6c <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a6c:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100a73:	75 11                	jne    f0100a86 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a75:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a7a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a80:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f0100a86:	85 c0                	test   %eax,%eax
f0100a88:	74 2e                	je     f0100ab8 <boot_alloc+0x4c>
	{
	result=nextfree;
f0100a8a:	8b 0d 38 a2 22 f0    	mov    0xf022a238,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f0100a90:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a96:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a9c:	01 ca                	add    %ecx,%edx
f0100a9e:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f0100aa4:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100aa9:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100aae:	c1 e0 0c             	shl    $0xc,%eax
f0100ab1:	39 c2                	cmp    %eax,%edx
f0100ab3:	77 09                	ja     f0100abe <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f0100ab5:	89 c8                	mov    %ecx,%eax
f0100ab7:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f0100ab8:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
f0100abd:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100abe:	55                   	push   %ebp
f0100abf:	89 e5                	mov    %esp,%ebp
f0100ac1:	83 ec 0c             	sub    $0xc,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f0100ac4:	68 84 5f 10 f0       	push   $0xf0105f84
f0100ac9:	6a 7c                	push   $0x7c
f0100acb:	68 94 5f 10 f0       	push   $0xf0105f94
f0100ad0:	e8 6b f5 ff ff       	call   f0100040 <_panic>

f0100ad5 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ad5:	89 d1                	mov    %edx,%ecx
f0100ad7:	c1 e9 16             	shr    $0x16,%ecx
f0100ada:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100add:	a8 01                	test   $0x1,%al
f0100adf:	74 52                	je     f0100b33 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ae1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ae6:	89 c1                	mov    %eax,%ecx
f0100ae8:	c1 e9 0c             	shr    $0xc,%ecx
f0100aeb:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100af1:	72 1b                	jb     f0100b0e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100af3:	55                   	push   %ebp
f0100af4:	89 e5                	mov    %esp,%ebp
f0100af6:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af9:	50                   	push   %eax
f0100afa:	68 24 5a 10 f0       	push   $0xf0105a24
f0100aff:	68 a1 03 00 00       	push   $0x3a1
f0100b04:	68 94 5f 10 f0       	push   $0xf0105f94
f0100b09:	e8 32 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b0e:	c1 ea 0c             	shr    $0xc,%edx
f0100b11:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b17:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b1e:	89 c2                	mov    %eax,%edx
f0100b20:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b23:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b28:	85 d2                	test   %edx,%edx
f0100b2a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b2f:	0f 44 c2             	cmove  %edx,%eax
f0100b32:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b38:	c3                   	ret    

f0100b39 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b39:	55                   	push   %ebp
f0100b3a:	89 e5                	mov    %esp,%ebp
f0100b3c:	57                   	push   %edi
f0100b3d:	56                   	push   %esi
f0100b3e:	53                   	push   %ebx
f0100b3f:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b42:	84 c0                	test   %al,%al
f0100b44:	0f 85 a0 02 00 00    	jne    f0100dea <check_page_free_list+0x2b1>
f0100b4a:	e9 ad 02 00 00       	jmp    f0100dfc <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b4f:	83 ec 04             	sub    $0x4,%esp
f0100b52:	68 cc 62 10 f0       	push   $0xf01062cc
f0100b57:	68 d4 02 00 00       	push   $0x2d4
f0100b5c:	68 94 5f 10 f0       	push   $0xf0105f94
f0100b61:	e8 da f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b66:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b69:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b6c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b6f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b72:	89 c2                	mov    %eax,%edx
f0100b74:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100b7a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b80:	0f 95 c2             	setne  %dl
f0100b83:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b86:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b8a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b8c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b90:	8b 00                	mov    (%eax),%eax
f0100b92:	85 c0                	test   %eax,%eax
f0100b94:	75 dc                	jne    f0100b72 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b99:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ba5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ba7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100baa:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100baf:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bb4:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100bba:	eb 53                	jmp    f0100c0f <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bbc:	89 d8                	mov    %ebx,%eax
f0100bbe:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100bc4:	c1 f8 03             	sar    $0x3,%eax
f0100bc7:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bca:	89 c2                	mov    %eax,%edx
f0100bcc:	c1 ea 16             	shr    $0x16,%edx
f0100bcf:	39 f2                	cmp    %esi,%edx
f0100bd1:	73 3a                	jae    f0100c0d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd3:	89 c2                	mov    %eax,%edx
f0100bd5:	c1 ea 0c             	shr    $0xc,%edx
f0100bd8:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100bde:	72 12                	jb     f0100bf2 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be0:	50                   	push   %eax
f0100be1:	68 24 5a 10 f0       	push   $0xf0105a24
f0100be6:	6a 58                	push   $0x58
f0100be8:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0100bed:	e8 4e f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bf2:	83 ec 04             	sub    $0x4,%esp
f0100bf5:	68 80 00 00 00       	push   $0x80
f0100bfa:	68 97 00 00 00       	push   $0x97
f0100bff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c04:	50                   	push   %eax
f0100c05:	e8 42 41 00 00       	call   f0104d4c <memset>
f0100c0a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c0d:	8b 1b                	mov    (%ebx),%ebx
f0100c0f:	85 db                	test   %ebx,%ebx
f0100c11:	75 a9                	jne    f0100bbc <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c13:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c18:	e8 4f fe ff ff       	call   f0100a6c <boot_alloc>
f0100c1d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c20:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c26:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100c2c:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100c31:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c34:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c37:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c3a:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c3d:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c42:	e9 52 01 00 00       	jmp    f0100d99 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c47:	39 ca                	cmp    %ecx,%edx
f0100c49:	73 19                	jae    f0100c64 <check_page_free_list+0x12b>
f0100c4b:	68 ae 5f 10 f0       	push   $0xf0105fae
f0100c50:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100c55:	68 ee 02 00 00       	push   $0x2ee
f0100c5a:	68 94 5f 10 f0       	push   $0xf0105f94
f0100c5f:	e8 dc f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c64:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c67:	72 19                	jb     f0100c82 <check_page_free_list+0x149>
f0100c69:	68 cf 5f 10 f0       	push   $0xf0105fcf
f0100c6e:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100c73:	68 ef 02 00 00       	push   $0x2ef
f0100c78:	68 94 5f 10 f0       	push   $0xf0105f94
f0100c7d:	e8 be f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c82:	89 d0                	mov    %edx,%eax
f0100c84:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c87:	a8 07                	test   $0x7,%al
f0100c89:	74 19                	je     f0100ca4 <check_page_free_list+0x16b>
f0100c8b:	68 f0 62 10 f0       	push   $0xf01062f0
f0100c90:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100c95:	68 f0 02 00 00       	push   $0x2f0
f0100c9a:	68 94 5f 10 f0       	push   $0xf0105f94
f0100c9f:	e8 9c f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ca4:	c1 f8 03             	sar    $0x3,%eax
f0100ca7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100caa:	85 c0                	test   %eax,%eax
f0100cac:	75 19                	jne    f0100cc7 <check_page_free_list+0x18e>
f0100cae:	68 e3 5f 10 f0       	push   $0xf0105fe3
f0100cb3:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100cb8:	68 f3 02 00 00       	push   $0x2f3
f0100cbd:	68 94 5f 10 f0       	push   $0xf0105f94
f0100cc2:	e8 79 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cc7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ccc:	75 19                	jne    f0100ce7 <check_page_free_list+0x1ae>
f0100cce:	68 f4 5f 10 f0       	push   $0xf0105ff4
f0100cd3:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100cd8:	68 f4 02 00 00       	push   $0x2f4
f0100cdd:	68 94 5f 10 f0       	push   $0xf0105f94
f0100ce2:	e8 59 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ce7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cec:	75 19                	jne    f0100d07 <check_page_free_list+0x1ce>
f0100cee:	68 24 63 10 f0       	push   $0xf0106324
f0100cf3:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100cf8:	68 f5 02 00 00       	push   $0x2f5
f0100cfd:	68 94 5f 10 f0       	push   $0xf0105f94
f0100d02:	e8 39 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d07:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d0c:	75 19                	jne    f0100d27 <check_page_free_list+0x1ee>
f0100d0e:	68 0d 60 10 f0       	push   $0xf010600d
f0100d13:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100d18:	68 f6 02 00 00       	push   $0x2f6
f0100d1d:	68 94 5f 10 f0       	push   $0xf0105f94
f0100d22:	e8 19 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d27:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d2c:	0f 86 f1 00 00 00    	jbe    f0100e23 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d32:	89 c7                	mov    %eax,%edi
f0100d34:	c1 ef 0c             	shr    $0xc,%edi
f0100d37:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d3a:	77 12                	ja     f0100d4e <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d3c:	50                   	push   %eax
f0100d3d:	68 24 5a 10 f0       	push   $0xf0105a24
f0100d42:	6a 58                	push   $0x58
f0100d44:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0100d49:	e8 f2 f2 ff ff       	call   f0100040 <_panic>
f0100d4e:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d54:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d57:	0f 86 b6 00 00 00    	jbe    f0100e13 <check_page_free_list+0x2da>
f0100d5d:	68 48 63 10 f0       	push   $0xf0106348
f0100d62:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100d67:	68 f7 02 00 00       	push   $0x2f7
f0100d6c:	68 94 5f 10 f0       	push   $0xf0105f94
f0100d71:	e8 ca f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d76:	68 27 60 10 f0       	push   $0xf0106027
f0100d7b:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100d80:	68 f9 02 00 00       	push   $0x2f9
f0100d85:	68 94 5f 10 f0       	push   $0xf0105f94
f0100d8a:	e8 b1 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d8f:	83 c6 01             	add    $0x1,%esi
f0100d92:	eb 03                	jmp    f0100d97 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d94:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d97:	8b 12                	mov    (%edx),%edx
f0100d99:	85 d2                	test   %edx,%edx
f0100d9b:	0f 85 a6 fe ff ff    	jne    f0100c47 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100da1:	85 f6                	test   %esi,%esi
f0100da3:	7f 19                	jg     f0100dbe <check_page_free_list+0x285>
f0100da5:	68 44 60 10 f0       	push   $0xf0106044
f0100daa:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100daf:	68 01 03 00 00       	push   $0x301
f0100db4:	68 94 5f 10 f0       	push   $0xf0105f94
f0100db9:	e8 82 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100dbe:	85 db                	test   %ebx,%ebx
f0100dc0:	7f 19                	jg     f0100ddb <check_page_free_list+0x2a2>
f0100dc2:	68 56 60 10 f0       	push   $0xf0106056
f0100dc7:	68 ba 5f 10 f0       	push   $0xf0105fba
f0100dcc:	68 02 03 00 00       	push   $0x302
f0100dd1:	68 94 5f 10 f0       	push   $0xf0105f94
f0100dd6:	e8 65 f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ddb:	83 ec 0c             	sub    $0xc,%esp
f0100dde:	68 90 63 10 f0       	push   $0xf0106390
f0100de3:	e8 a1 28 00 00       	call   f0103689 <cprintf>
}
f0100de8:	eb 49                	jmp    f0100e33 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dea:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100def:	85 c0                	test   %eax,%eax
f0100df1:	0f 85 6f fd ff ff    	jne    f0100b66 <check_page_free_list+0x2d>
f0100df7:	e9 53 fd ff ff       	jmp    f0100b4f <check_page_free_list+0x16>
f0100dfc:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100e03:	0f 84 46 fd ff ff    	je     f0100b4f <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e09:	be 00 04 00 00       	mov    $0x400,%esi
f0100e0e:	e9 a1 fd ff ff       	jmp    f0100bb4 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e13:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e18:	0f 85 76 ff ff ff    	jne    f0100d94 <check_page_free_list+0x25b>
f0100e1e:	e9 53 ff ff ff       	jmp    f0100d76 <check_page_free_list+0x23d>
f0100e23:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e28:	0f 85 61 ff ff ff    	jne    f0100d8f <check_page_free_list+0x256>
f0100e2e:	e9 43 ff ff ff       	jmp    f0100d76 <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100e33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e36:	5b                   	pop    %ebx
f0100e37:	5e                   	pop    %esi
f0100e38:	5f                   	pop    %edi
f0100e39:	5d                   	pop    %ebp
f0100e3a:	c3                   	ret    

f0100e3b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e3b:	55                   	push   %ebp
f0100e3c:	89 e5                	mov    %esp,%ebp
f0100e3e:	53                   	push   %ebx
f0100e3f:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e42:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e47:	eb 52                	jmp    f0100e9b <page_init+0x60>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE))||i==MPENTRY_PADDR/PGSIZE)
f0100e49:	85 db                	test   %ebx,%ebx
f0100e4b:	74 4b                	je     f0100e98 <page_init+0x5d>
f0100e4d:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100e53:	76 16                	jbe    f0100e6b <page_init+0x30>
f0100e55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e5a:	e8 0d fc ff ff       	call   f0100a6c <boot_alloc>
f0100e5f:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e64:	c1 e8 0c             	shr    $0xc,%eax
f0100e67:	39 c3                	cmp    %eax,%ebx
f0100e69:	76 2d                	jbe    f0100e98 <page_init+0x5d>
f0100e6b:	83 fb 07             	cmp    $0x7,%ebx
f0100e6e:	74 28                	je     f0100e98 <page_init+0x5d>
f0100e70:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100e77:	89 c2                	mov    %eax,%edx
f0100e79:	03 15 90 ae 22 f0    	add    0xf022ae90,%edx
f0100e7f:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100e85:	8b 0d 40 a2 22 f0    	mov    0xf022a240,%ecx
f0100e8b:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100e8d:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e93:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e98:	83 c3 01             	add    $0x1,%ebx
f0100e9b:	3b 1d 88 ae 22 f0    	cmp    0xf022ae88,%ebx
f0100ea1:	72 a6                	jb     f0100e49 <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100ea3:	83 c4 04             	add    $0x4,%esp
f0100ea6:	5b                   	pop    %ebx
f0100ea7:	5d                   	pop    %ebp
f0100ea8:	c3                   	ret    

f0100ea9 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ea9:	55                   	push   %ebp
f0100eaa:	89 e5                	mov    %esp,%ebp
f0100eac:	53                   	push   %ebx
f0100ead:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0100eb0:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100eb6:	85 db                	test   %ebx,%ebx
f0100eb8:	74 58                	je     f0100f12 <page_alloc+0x69>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0100eba:	8b 03                	mov    (%ebx),%eax
f0100ebc:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
  	tempage->pp_link = NULL;
f0100ec1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
f0100ec7:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ecb:	74 45                	je     f0100f12 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ecd:	89 d8                	mov    %ebx,%eax
f0100ecf:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100ed5:	c1 f8 03             	sar    $0x3,%eax
f0100ed8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100edb:	89 c2                	mov    %eax,%edx
f0100edd:	c1 ea 0c             	shr    $0xc,%edx
f0100ee0:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100ee6:	72 12                	jb     f0100efa <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee8:	50                   	push   %eax
f0100ee9:	68 24 5a 10 f0       	push   $0xf0105a24
f0100eee:	6a 58                	push   $0x58
f0100ef0:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0100ef5:	e8 46 f1 ff ff       	call   f0100040 <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f0100efa:	83 ec 04             	sub    $0x4,%esp
f0100efd:	68 00 10 00 00       	push   $0x1000
f0100f02:	6a 00                	push   $0x0
f0100f04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f09:	50                   	push   %eax
f0100f0a:	e8 3d 3e 00 00       	call   f0104d4c <memset>
f0100f0f:	83 c4 10             	add    $0x10,%esp

  	return tempage;
	

}
f0100f12:	89 d8                	mov    %ebx,%eax
f0100f14:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f17:	c9                   	leave  
f0100f18:	c3                   	ret    

f0100f19 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f19:	55                   	push   %ebp
f0100f1a:	89 e5                	mov    %esp,%ebp
f0100f1c:	83 ec 08             	sub    $0x8,%esp
f0100f1f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100f22:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f27:	75 0f                	jne    f0100f38 <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100f29:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f2f:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100f31:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	}
	else
	panic("page ref not zero \n");
}
f0100f36:	eb 17                	jmp    f0100f4f <page_free+0x36>
	{
	pp->pp_link=page_free_list;
	page_free_list=pp;	
	}
	else
	panic("page ref not zero \n");
f0100f38:	83 ec 04             	sub    $0x4,%esp
f0100f3b:	68 67 60 10 f0       	push   $0xf0106067
f0100f40:	68 95 01 00 00       	push   $0x195
f0100f45:	68 94 5f 10 f0       	push   $0xf0105f94
f0100f4a:	e8 f1 f0 ff ff       	call   f0100040 <_panic>
}
f0100f4f:	c9                   	leave  
f0100f50:	c3                   	ret    

f0100f51 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f51:	55                   	push   %ebp
f0100f52:	89 e5                	mov    %esp,%ebp
f0100f54:	83 ec 08             	sub    $0x8,%esp
f0100f57:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f5a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f5e:	83 e8 01             	sub    $0x1,%eax
f0100f61:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f65:	66 85 c0             	test   %ax,%ax
f0100f68:	75 0c                	jne    f0100f76 <page_decref+0x25>
		page_free(pp);
f0100f6a:	83 ec 0c             	sub    $0xc,%esp
f0100f6d:	52                   	push   %edx
f0100f6e:	e8 a6 ff ff ff       	call   f0100f19 <page_free>
f0100f73:	83 c4 10             	add    $0x10,%esp
}
f0100f76:	c9                   	leave  
f0100f77:	c3                   	ret    

f0100f78 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f78:	55                   	push   %ebp
f0100f79:	89 e5                	mov    %esp,%ebp
f0100f7b:	57                   	push   %edi
f0100f7c:	56                   	push   %esi
f0100f7d:	53                   	push   %ebx
f0100f7e:	83 ec 0c             	sub    $0xc,%esp
f0100f81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0100f84:	89 de                	mov    %ebx,%esi
f0100f86:	c1 ee 16             	shr    $0x16,%esi
f0100f89:	c1 e6 02             	shl    $0x2,%esi
f0100f8c:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0100f8f:	8b 06                	mov    (%esi),%eax
f0100f91:	a8 01                	test   $0x1,%al
f0100f93:	74 2f                	je     f0100fc4 <pgdir_walk+0x4c>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f0100f95:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f9a:	89 c2                	mov    %eax,%edx
f0100f9c:	c1 ea 0c             	shr    $0xc,%edx
f0100f9f:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f0100fa5:	77 15                	ja     f0100fbc <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fa7:	50                   	push   %eax
f0100fa8:	68 24 5a 10 f0       	push   $0xf0105a24
f0100fad:	68 c2 01 00 00       	push   $0x1c2
f0100fb2:	68 94 5f 10 f0       	push   $0xf0105f94
f0100fb7:	e8 84 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100fbc:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100fc2:	eb 77                	jmp    f010103b <pgdir_walk+0xc3>
	  } else {
		//page table page not exist
		if(!create || 
f0100fc4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fc8:	74 7f                	je     f0101049 <pgdir_walk+0xd1>
f0100fca:	83 ec 0c             	sub    $0xc,%esp
f0100fcd:	6a 01                	push   $0x1
f0100fcf:	e8 d5 fe ff ff       	call   f0100ea9 <page_alloc>
f0100fd4:	83 c4 10             	add    $0x10,%esp
f0100fd7:	85 c0                	test   %eax,%eax
f0100fd9:	74 75                	je     f0101050 <pgdir_walk+0xd8>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fdb:	89 c1                	mov    %eax,%ecx
f0100fdd:	2b 0d 90 ae 22 f0    	sub    0xf022ae90,%ecx
f0100fe3:	c1 f9 03             	sar    $0x3,%ecx
f0100fe6:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe9:	89 ca                	mov    %ecx,%edx
f0100feb:	c1 ea 0c             	shr    $0xc,%edx
f0100fee:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100ff4:	72 12                	jb     f0101008 <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff6:	51                   	push   %ecx
f0100ff7:	68 24 5a 10 f0       	push   $0xf0105a24
f0100ffc:	6a 58                	push   $0x58
f0100ffe:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0101003:	e8 38 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101008:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f010100e:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0101010:	85 ff                	test   %edi,%edi
f0101012:	74 43                	je     f0101057 <pgdir_walk+0xdf>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f0101014:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101019:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010101f:	77 15                	ja     f0101036 <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101021:	57                   	push   %edi
f0101022:	68 48 5a 10 f0       	push   $0xf0105a48
f0101027:	68 cb 01 00 00       	push   $0x1cb
f010102c:	68 94 5f 10 f0       	push   $0xf0105f94
f0101031:	e8 0a f0 ff ff       	call   f0100040 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0101036:	83 c9 07             	or     $0x7,%ecx
f0101039:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f010103b:	c1 eb 0a             	shr    $0xa,%ebx
f010103e:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101044:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0101047:	eb 13                	jmp    f010105c <pgdir_walk+0xe4>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f0101049:	b8 00 00 00 00       	mov    $0x0,%eax
f010104e:	eb 0c                	jmp    f010105c <pgdir_walk+0xe4>
f0101050:	b8 00 00 00 00       	mov    $0x0,%eax
f0101055:	eb 05                	jmp    f010105c <pgdir_walk+0xe4>
f0101057:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f010105c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010105f:	5b                   	pop    %ebx
f0101060:	5e                   	pop    %esi
f0101061:	5f                   	pop    %edi
f0101062:	5d                   	pop    %ebp
f0101063:	c3                   	ret    

f0101064 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101064:	55                   	push   %ebp
f0101065:	89 e5                	mov    %esp,%ebp
f0101067:	57                   	push   %edi
f0101068:	56                   	push   %esi
f0101069:	53                   	push   %ebx
f010106a:	83 ec 1c             	sub    $0x1c,%esp
f010106d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0101070:	c1 e9 0c             	shr    $0xc,%ecx
f0101073:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f0101076:	89 d6                	mov    %edx,%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f0101078:	bf 00 00 00 00       	mov    $0x0,%edi
f010107d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101080:	29 d0                	sub    %edx,%eax
f0101082:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0101085:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101088:	83 c8 01             	or     $0x1,%eax
f010108b:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f010108e:	eb 25                	jmp    f01010b5 <boot_map_region+0x51>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f0101090:	83 ec 04             	sub    $0x4,%esp
f0101093:	6a 01                	push   $0x1
f0101095:	56                   	push   %esi
f0101096:	ff 75 dc             	pushl  -0x24(%ebp)
f0101099:	e8 da fe ff ff       	call   f0100f78 <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f010109e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01010a4:	0b 5d d8             	or     -0x28(%ebp),%ebx
f01010a7:	89 18                	mov    %ebx,(%eax)
		va+=PGSIZE;
f01010a9:	81 c6 00 10 00 00    	add    $0x1000,%esi
		pa+=PGSIZE;
		i++;
f01010af:	83 c7 01             	add    $0x1,%edi
f01010b2:	83 c4 10             	add    $0x10,%esp
f01010b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010b8:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f01010bb:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01010be:	75 d0                	jne    f0101090 <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f01010c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010c3:	5b                   	pop    %ebx
f01010c4:	5e                   	pop    %esi
f01010c5:	5f                   	pop    %edi
f01010c6:	5d                   	pop    %ebp
f01010c7:	c3                   	ret    

f01010c8 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010c8:	55                   	push   %ebp
f01010c9:	89 e5                	mov    %esp,%ebp
f01010cb:	83 ec 0c             	sub    $0xc,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f01010ce:	6a 00                	push   $0x0
f01010d0:	ff 75 0c             	pushl  0xc(%ebp)
f01010d3:	ff 75 08             	pushl  0x8(%ebp)
f01010d6:	e8 9d fe ff ff       	call   f0100f78 <pgdir_walk>
	
	if(pt == NULL)
f01010db:	83 c4 10             	add    $0x10,%esp
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	74 31                	je     f0101113 <page_lookup+0x4b>
	return NULL;
	
	*pte_store = pt;
f01010e2:	8b 55 10             	mov    0x10(%ebp),%edx
f01010e5:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e7:	8b 00                	mov    (%eax),%eax
f01010e9:	c1 e8 0c             	shr    $0xc,%eax
f01010ec:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01010f2:	72 14                	jb     f0101108 <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f01010f4:	83 ec 04             	sub    $0x4,%esp
f01010f7:	68 b4 63 10 f0       	push   $0xf01063b4
f01010fc:	6a 51                	push   $0x51
f01010fe:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0101103:	e8 38 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101108:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f010110e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	
  return pa2page(PTE_ADDR(*pt));	
f0101111:	eb 05                	jmp    f0101118 <page_lookup+0x50>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f0101113:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0101118:	c9                   	leave  
f0101119:	c3                   	ret    

f010111a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010111a:	55                   	push   %ebp
f010111b:	89 e5                	mov    %esp,%ebp
f010111d:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101120:	e8 49 42 00 00       	call   f010536e <cpunum>
f0101125:	6b c0 74             	imul   $0x74,%eax,%eax
f0101128:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010112f:	74 16                	je     f0101147 <tlb_invalidate+0x2d>
f0101131:	e8 38 42 00 00       	call   f010536e <cpunum>
f0101136:	6b c0 74             	imul   $0x74,%eax,%eax
f0101139:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010113f:	8b 55 08             	mov    0x8(%ebp),%edx
f0101142:	39 50 60             	cmp    %edx,0x60(%eax)
f0101145:	75 06                	jne    f010114d <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101147:	8b 45 0c             	mov    0xc(%ebp),%eax
f010114a:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f010114d:	c9                   	leave  
f010114e:	c3                   	ret    

f010114f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010114f:	55                   	push   %ebp
f0101150:	89 e5                	mov    %esp,%ebp
f0101152:	56                   	push   %esi
f0101153:	53                   	push   %ebx
f0101154:	83 ec 14             	sub    $0x14,%esp
f0101157:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010115a:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f010115d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f0101164:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101167:	50                   	push   %eax
f0101168:	56                   	push   %esi
f0101169:	53                   	push   %ebx
f010116a:	e8 59 ff ff ff       	call   f01010c8 <page_lookup>
f010116f:	83 c4 10             	add    $0x10,%esp
f0101172:	85 c0                	test   %eax,%eax
f0101174:	74 16                	je     f010118c <page_remove+0x3d>
		page_decref(page);
f0101176:	83 ec 0c             	sub    $0xc,%esp
f0101179:	50                   	push   %eax
f010117a:	e8 d2 fd ff ff       	call   f0100f51 <page_decref>
		tlb_invalidate(pgdir, va);
f010117f:	83 c4 08             	add    $0x8,%esp
f0101182:	56                   	push   %esi
f0101183:	53                   	push   %ebx
f0101184:	e8 91 ff ff ff       	call   f010111a <tlb_invalidate>
f0101189:	83 c4 10             	add    $0x10,%esp
	}
	*pt=0;
f010118c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010118f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0101195:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101198:	5b                   	pop    %ebx
f0101199:	5e                   	pop    %esi
f010119a:	5d                   	pop    %ebp
f010119b:	c3                   	ret    

f010119c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010119c:	55                   	push   %ebp
f010119d:	89 e5                	mov    %esp,%ebp
f010119f:	57                   	push   %edi
f01011a0:	56                   	push   %esi
f01011a1:	53                   	push   %ebx
f01011a2:	83 ec 10             	sub    $0x10,%esp
f01011a5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011a8:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f01011ab:	6a 01                	push   $0x1
f01011ad:	57                   	push   %edi
f01011ae:	ff 75 08             	pushl  0x8(%ebp)
f01011b1:	e8 c2 fd ff ff       	call   f0100f78 <pgdir_walk>
 

    if (pte != NULL) {
f01011b6:	83 c4 10             	add    $0x10,%esp
f01011b9:	85 c0                	test   %eax,%eax
f01011bb:	74 4a                	je     f0101207 <page_insert+0x6b>
f01011bd:	89 c3                	mov    %eax,%ebx
     
        if (*pte & PTE_P)
f01011bf:	f6 00 01             	testb  $0x1,(%eax)
f01011c2:	74 0f                	je     f01011d3 <page_insert+0x37>
            page_remove(pgdir, va);
f01011c4:	83 ec 08             	sub    $0x8,%esp
f01011c7:	57                   	push   %edi
f01011c8:	ff 75 08             	pushl  0x8(%ebp)
f01011cb:	e8 7f ff ff ff       	call   f010114f <page_remove>
f01011d0:	83 c4 10             	add    $0x10,%esp
   
       if (page_free_list == pp)
f01011d3:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01011d8:	39 f0                	cmp    %esi,%eax
f01011da:	75 07                	jne    f01011e3 <page_insert+0x47>
            page_free_list = page_free_list->pp_link;
f01011dc:	8b 00                	mov    (%eax),%eax
f01011de:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
    }
    else {
    
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f01011e3:	89 f0                	mov    %esi,%eax
f01011e5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01011eb:	c1 f8 03             	sar    $0x3,%eax
f01011ee:	c1 e0 0c             	shl    $0xc,%eax
f01011f1:	8b 55 14             	mov    0x14(%ebp),%edx
f01011f4:	83 ca 01             	or     $0x1,%edx
f01011f7:	09 d0                	or     %edx,%eax
f01011f9:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f01011fb:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

return 0;
f0101200:	b8 00 00 00 00       	mov    $0x0,%eax
f0101205:	eb 05                	jmp    f010120c <page_insert+0x70>
       if (page_free_list == pp)
            page_free_list = page_free_list->pp_link;
    }
    else {
    
            return -E_NO_MEM;
f0101207:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f010120c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010120f:	5b                   	pop    %ebx
f0101210:	5e                   	pop    %esi
f0101211:	5f                   	pop    %edi
f0101212:	5d                   	pop    %ebp
f0101213:	c3                   	ret    

f0101214 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101214:	55                   	push   %ebp
f0101215:	89 e5                	mov    %esp,%ebp
f0101217:	53                   	push   %ebx
f0101218:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f010121b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010121e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101224:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (base + size > MMIOLIM)
f010122a:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f0101230:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101233:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f0101238:	76 17                	jbe    f0101251 <mmio_map_region+0x3d>
		panic("overflow MMIOLIM\n");
f010123a:	83 ec 04             	sub    $0x4,%esp
f010123d:	68 7b 60 10 f0       	push   $0xf010607b
f0101242:	68 82 02 00 00       	push   $0x282
f0101247:	68 94 5f 10 f0       	push   $0xf0105f94
f010124c:	e8 ef ed ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, base, size, pa, PTE_P|PTE_W|PTE_PCD|PTE_PWT);
f0101251:	83 ec 08             	sub    $0x8,%esp
f0101254:	6a 1b                	push   $0x1b
f0101256:	ff 75 08             	pushl  0x8(%ebp)
f0101259:	89 d9                	mov    %ebx,%ecx
f010125b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101260:	e8 ff fd ff ff       	call   f0101064 <boot_map_region>
	uintptr_t retaddr = base;
f0101265:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
	base += size;
f010126a:	01 c3                	add    %eax,%ebx
f010126c:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)retaddr;
}
f0101272:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101275:	c9                   	leave  
f0101276:	c3                   	ret    

f0101277 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101277:	55                   	push   %ebp
f0101278:	89 e5                	mov    %esp,%ebp
f010127a:	57                   	push   %edi
f010127b:	56                   	push   %esi
f010127c:	53                   	push   %ebx
f010127d:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101280:	b8 15 00 00 00       	mov    $0x15,%eax
f0101285:	e8 b9 f7 ff ff       	call   f0100a43 <nvram_read>
f010128a:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010128c:	b8 17 00 00 00       	mov    $0x17,%eax
f0101291:	e8 ad f7 ff ff       	call   f0100a43 <nvram_read>
f0101296:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101298:	b8 34 00 00 00       	mov    $0x34,%eax
f010129d:	e8 a1 f7 ff ff       	call   f0100a43 <nvram_read>
f01012a2:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01012a5:	85 c0                	test   %eax,%eax
f01012a7:	74 07                	je     f01012b0 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01012a9:	05 00 40 00 00       	add    $0x4000,%eax
f01012ae:	eb 0b                	jmp    f01012bb <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01012b0:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01012b6:	85 f6                	test   %esi,%esi
f01012b8:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01012bb:	89 c2                	mov    %eax,%edx
f01012bd:	c1 ea 02             	shr    $0x2,%edx
f01012c0:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
	npages_basemem = basemem / (PGSIZE / 1024);
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012c6:	89 c2                	mov    %eax,%edx
f01012c8:	29 da                	sub    %ebx,%edx
f01012ca:	52                   	push   %edx
f01012cb:	53                   	push   %ebx
f01012cc:	50                   	push   %eax
f01012cd:	68 d4 63 10 f0       	push   $0xf01063d4
f01012d2:	e8 b2 23 00 00       	call   f0103689 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012d7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012dc:	e8 8b f7 ff ff       	call   f0100a6c <boot_alloc>
f01012e1:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f01012e6:	83 c4 0c             	add    $0xc,%esp
f01012e9:	68 00 10 00 00       	push   $0x1000
f01012ee:	6a 00                	push   $0x0
f01012f0:	50                   	push   %eax
f01012f1:	e8 56 3a 00 00       	call   f0104d4c <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012f6:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012fb:	83 c4 10             	add    $0x10,%esp
f01012fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101303:	77 15                	ja     f010131a <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101305:	50                   	push   %eax
f0101306:	68 48 5a 10 f0       	push   $0xf0105a48
f010130b:	68 a3 00 00 00       	push   $0xa3
f0101310:	68 94 5f 10 f0       	push   $0xf0105f94
f0101315:	e8 26 ed ff ff       	call   f0100040 <_panic>
f010131a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101320:	83 ca 05             	or     $0x5,%edx
f0101323:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo *)boot_alloc(sizeof(struct PageInfo)*npages);
f0101329:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010132e:	c1 e0 03             	shl    $0x3,%eax
f0101331:	e8 36 f7 ff ff       	call   f0100a6c <boot_alloc>
f0101336:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages,0,sizeof(struct PageInfo)*npages);
f010133b:	83 ec 04             	sub    $0x4,%esp
f010133e:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0101344:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010134b:	52                   	push   %edx
f010134c:	6a 00                	push   $0x0
f010134e:	50                   	push   %eax
f010134f:	e8 f8 39 00 00       	call   f0104d4c <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	
	
	envs=(struct Env *)boot_alloc(sizeof(struct Env)*NENV);
f0101354:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101359:	e8 0e f7 ff ff       	call   f0100a6c <boot_alloc>
f010135e:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101363:	e8 d3 fa ff ff       	call   f0100e3b <page_init>

	check_page_free_list(1);
f0101368:	b8 01 00 00 00       	mov    $0x1,%eax
f010136d:	e8 c7 f7 ff ff       	call   f0100b39 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101372:	83 c4 10             	add    $0x10,%esp
f0101375:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f010137c:	75 17                	jne    f0101395 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f010137e:	83 ec 04             	sub    $0x4,%esp
f0101381:	68 8d 60 10 f0       	push   $0xf010608d
f0101386:	68 15 03 00 00       	push   $0x315
f010138b:	68 94 5f 10 f0       	push   $0xf0105f94
f0101390:	e8 ab ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101395:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010139a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010139f:	eb 05                	jmp    f01013a6 <mem_init+0x12f>
		++nfree;
f01013a1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a4:	8b 00                	mov    (%eax),%eax
f01013a6:	85 c0                	test   %eax,%eax
f01013a8:	75 f7                	jne    f01013a1 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013aa:	83 ec 0c             	sub    $0xc,%esp
f01013ad:	6a 00                	push   $0x0
f01013af:	e8 f5 fa ff ff       	call   f0100ea9 <page_alloc>
f01013b4:	89 c7                	mov    %eax,%edi
f01013b6:	83 c4 10             	add    $0x10,%esp
f01013b9:	85 c0                	test   %eax,%eax
f01013bb:	75 19                	jne    f01013d6 <mem_init+0x15f>
f01013bd:	68 a8 60 10 f0       	push   $0xf01060a8
f01013c2:	68 ba 5f 10 f0       	push   $0xf0105fba
f01013c7:	68 1d 03 00 00       	push   $0x31d
f01013cc:	68 94 5f 10 f0       	push   $0xf0105f94
f01013d1:	e8 6a ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01013d6:	83 ec 0c             	sub    $0xc,%esp
f01013d9:	6a 00                	push   $0x0
f01013db:	e8 c9 fa ff ff       	call   f0100ea9 <page_alloc>
f01013e0:	89 c6                	mov    %eax,%esi
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	85 c0                	test   %eax,%eax
f01013e7:	75 19                	jne    f0101402 <mem_init+0x18b>
f01013e9:	68 be 60 10 f0       	push   $0xf01060be
f01013ee:	68 ba 5f 10 f0       	push   $0xf0105fba
f01013f3:	68 1e 03 00 00       	push   $0x31e
f01013f8:	68 94 5f 10 f0       	push   $0xf0105f94
f01013fd:	e8 3e ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101402:	83 ec 0c             	sub    $0xc,%esp
f0101405:	6a 00                	push   $0x0
f0101407:	e8 9d fa ff ff       	call   f0100ea9 <page_alloc>
f010140c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010140f:	83 c4 10             	add    $0x10,%esp
f0101412:	85 c0                	test   %eax,%eax
f0101414:	75 19                	jne    f010142f <mem_init+0x1b8>
f0101416:	68 d4 60 10 f0       	push   $0xf01060d4
f010141b:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101420:	68 1f 03 00 00       	push   $0x31f
f0101425:	68 94 5f 10 f0       	push   $0xf0105f94
f010142a:	e8 11 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010142f:	39 f7                	cmp    %esi,%edi
f0101431:	75 19                	jne    f010144c <mem_init+0x1d5>
f0101433:	68 ea 60 10 f0       	push   $0xf01060ea
f0101438:	68 ba 5f 10 f0       	push   $0xf0105fba
f010143d:	68 22 03 00 00       	push   $0x322
f0101442:	68 94 5f 10 f0       	push   $0xf0105f94
f0101447:	e8 f4 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010144c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010144f:	39 c6                	cmp    %eax,%esi
f0101451:	74 04                	je     f0101457 <mem_init+0x1e0>
f0101453:	39 c7                	cmp    %eax,%edi
f0101455:	75 19                	jne    f0101470 <mem_init+0x1f9>
f0101457:	68 10 64 10 f0       	push   $0xf0106410
f010145c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101461:	68 23 03 00 00       	push   $0x323
f0101466:	68 94 5f 10 f0       	push   $0xf0105f94
f010146b:	e8 d0 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101470:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101476:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f010147c:	c1 e2 0c             	shl    $0xc,%edx
f010147f:	89 f8                	mov    %edi,%eax
f0101481:	29 c8                	sub    %ecx,%eax
f0101483:	c1 f8 03             	sar    $0x3,%eax
f0101486:	c1 e0 0c             	shl    $0xc,%eax
f0101489:	39 d0                	cmp    %edx,%eax
f010148b:	72 19                	jb     f01014a6 <mem_init+0x22f>
f010148d:	68 fc 60 10 f0       	push   $0xf01060fc
f0101492:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101497:	68 24 03 00 00       	push   $0x324
f010149c:	68 94 5f 10 f0       	push   $0xf0105f94
f01014a1:	e8 9a eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014a6:	89 f0                	mov    %esi,%eax
f01014a8:	29 c8                	sub    %ecx,%eax
f01014aa:	c1 f8 03             	sar    $0x3,%eax
f01014ad:	c1 e0 0c             	shl    $0xc,%eax
f01014b0:	39 c2                	cmp    %eax,%edx
f01014b2:	77 19                	ja     f01014cd <mem_init+0x256>
f01014b4:	68 19 61 10 f0       	push   $0xf0106119
f01014b9:	68 ba 5f 10 f0       	push   $0xf0105fba
f01014be:	68 25 03 00 00       	push   $0x325
f01014c3:	68 94 5f 10 f0       	push   $0xf0105f94
f01014c8:	e8 73 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d0:	29 c8                	sub    %ecx,%eax
f01014d2:	c1 f8 03             	sar    $0x3,%eax
f01014d5:	c1 e0 0c             	shl    $0xc,%eax
f01014d8:	39 c2                	cmp    %eax,%edx
f01014da:	77 19                	ja     f01014f5 <mem_init+0x27e>
f01014dc:	68 36 61 10 f0       	push   $0xf0106136
f01014e1:	68 ba 5f 10 f0       	push   $0xf0105fba
f01014e6:	68 26 03 00 00       	push   $0x326
f01014eb:	68 94 5f 10 f0       	push   $0xf0105f94
f01014f0:	e8 4b eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014f5:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01014fa:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014fd:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101504:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101507:	83 ec 0c             	sub    $0xc,%esp
f010150a:	6a 00                	push   $0x0
f010150c:	e8 98 f9 ff ff       	call   f0100ea9 <page_alloc>
f0101511:	83 c4 10             	add    $0x10,%esp
f0101514:	85 c0                	test   %eax,%eax
f0101516:	74 19                	je     f0101531 <mem_init+0x2ba>
f0101518:	68 53 61 10 f0       	push   $0xf0106153
f010151d:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101522:	68 2d 03 00 00       	push   $0x32d
f0101527:	68 94 5f 10 f0       	push   $0xf0105f94
f010152c:	e8 0f eb ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101531:	83 ec 0c             	sub    $0xc,%esp
f0101534:	57                   	push   %edi
f0101535:	e8 df f9 ff ff       	call   f0100f19 <page_free>
	page_free(pp1);
f010153a:	89 34 24             	mov    %esi,(%esp)
f010153d:	e8 d7 f9 ff ff       	call   f0100f19 <page_free>
	page_free(pp2);
f0101542:	83 c4 04             	add    $0x4,%esp
f0101545:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101548:	e8 cc f9 ff ff       	call   f0100f19 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101554:	e8 50 f9 ff ff       	call   f0100ea9 <page_alloc>
f0101559:	89 c6                	mov    %eax,%esi
f010155b:	83 c4 10             	add    $0x10,%esp
f010155e:	85 c0                	test   %eax,%eax
f0101560:	75 19                	jne    f010157b <mem_init+0x304>
f0101562:	68 a8 60 10 f0       	push   $0xf01060a8
f0101567:	68 ba 5f 10 f0       	push   $0xf0105fba
f010156c:	68 34 03 00 00       	push   $0x334
f0101571:	68 94 5f 10 f0       	push   $0xf0105f94
f0101576:	e8 c5 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010157b:	83 ec 0c             	sub    $0xc,%esp
f010157e:	6a 00                	push   $0x0
f0101580:	e8 24 f9 ff ff       	call   f0100ea9 <page_alloc>
f0101585:	89 c7                	mov    %eax,%edi
f0101587:	83 c4 10             	add    $0x10,%esp
f010158a:	85 c0                	test   %eax,%eax
f010158c:	75 19                	jne    f01015a7 <mem_init+0x330>
f010158e:	68 be 60 10 f0       	push   $0xf01060be
f0101593:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101598:	68 35 03 00 00       	push   $0x335
f010159d:	68 94 5f 10 f0       	push   $0xf0105f94
f01015a2:	e8 99 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	6a 00                	push   $0x0
f01015ac:	e8 f8 f8 ff ff       	call   f0100ea9 <page_alloc>
f01015b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	75 19                	jne    f01015d4 <mem_init+0x35d>
f01015bb:	68 d4 60 10 f0       	push   $0xf01060d4
f01015c0:	68 ba 5f 10 f0       	push   $0xf0105fba
f01015c5:	68 36 03 00 00       	push   $0x336
f01015ca:	68 94 5f 10 f0       	push   $0xf0105f94
f01015cf:	e8 6c ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d4:	39 fe                	cmp    %edi,%esi
f01015d6:	75 19                	jne    f01015f1 <mem_init+0x37a>
f01015d8:	68 ea 60 10 f0       	push   $0xf01060ea
f01015dd:	68 ba 5f 10 f0       	push   $0xf0105fba
f01015e2:	68 38 03 00 00       	push   $0x338
f01015e7:	68 94 5f 10 f0       	push   $0xf0105f94
f01015ec:	e8 4f ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f4:	39 c7                	cmp    %eax,%edi
f01015f6:	74 04                	je     f01015fc <mem_init+0x385>
f01015f8:	39 c6                	cmp    %eax,%esi
f01015fa:	75 19                	jne    f0101615 <mem_init+0x39e>
f01015fc:	68 10 64 10 f0       	push   $0xf0106410
f0101601:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101606:	68 39 03 00 00       	push   $0x339
f010160b:	68 94 5f 10 f0       	push   $0xf0105f94
f0101610:	e8 2b ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101615:	83 ec 0c             	sub    $0xc,%esp
f0101618:	6a 00                	push   $0x0
f010161a:	e8 8a f8 ff ff       	call   f0100ea9 <page_alloc>
f010161f:	83 c4 10             	add    $0x10,%esp
f0101622:	85 c0                	test   %eax,%eax
f0101624:	74 19                	je     f010163f <mem_init+0x3c8>
f0101626:	68 53 61 10 f0       	push   $0xf0106153
f010162b:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101630:	68 3a 03 00 00       	push   $0x33a
f0101635:	68 94 5f 10 f0       	push   $0xf0105f94
f010163a:	e8 01 ea ff ff       	call   f0100040 <_panic>
f010163f:	89 f0                	mov    %esi,%eax
f0101641:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101647:	c1 f8 03             	sar    $0x3,%eax
f010164a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164d:	89 c2                	mov    %eax,%edx
f010164f:	c1 ea 0c             	shr    $0xc,%edx
f0101652:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101658:	72 12                	jb     f010166c <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010165a:	50                   	push   %eax
f010165b:	68 24 5a 10 f0       	push   $0xf0105a24
f0101660:	6a 58                	push   $0x58
f0101662:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0101667:	e8 d4 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010166c:	83 ec 04             	sub    $0x4,%esp
f010166f:	68 00 10 00 00       	push   $0x1000
f0101674:	6a 01                	push   $0x1
f0101676:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010167b:	50                   	push   %eax
f010167c:	e8 cb 36 00 00       	call   f0104d4c <memset>
	page_free(pp0);
f0101681:	89 34 24             	mov    %esi,(%esp)
f0101684:	e8 90 f8 ff ff       	call   f0100f19 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101689:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101690:	e8 14 f8 ff ff       	call   f0100ea9 <page_alloc>
f0101695:	83 c4 10             	add    $0x10,%esp
f0101698:	85 c0                	test   %eax,%eax
f010169a:	75 19                	jne    f01016b5 <mem_init+0x43e>
f010169c:	68 62 61 10 f0       	push   $0xf0106162
f01016a1:	68 ba 5f 10 f0       	push   $0xf0105fba
f01016a6:	68 3f 03 00 00       	push   $0x33f
f01016ab:	68 94 5f 10 f0       	push   $0xf0105f94
f01016b0:	e8 8b e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016b5:	39 c6                	cmp    %eax,%esi
f01016b7:	74 19                	je     f01016d2 <mem_init+0x45b>
f01016b9:	68 80 61 10 f0       	push   $0xf0106180
f01016be:	68 ba 5f 10 f0       	push   $0xf0105fba
f01016c3:	68 40 03 00 00       	push   $0x340
f01016c8:	68 94 5f 10 f0       	push   $0xf0105f94
f01016cd:	e8 6e e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016d2:	89 f0                	mov    %esi,%eax
f01016d4:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01016da:	c1 f8 03             	sar    $0x3,%eax
f01016dd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016e0:	89 c2                	mov    %eax,%edx
f01016e2:	c1 ea 0c             	shr    $0xc,%edx
f01016e5:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01016eb:	72 12                	jb     f01016ff <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016ed:	50                   	push   %eax
f01016ee:	68 24 5a 10 f0       	push   $0xf0105a24
f01016f3:	6a 58                	push   $0x58
f01016f5:	68 a0 5f 10 f0       	push   $0xf0105fa0
f01016fa:	e8 41 e9 ff ff       	call   f0100040 <_panic>
f01016ff:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101705:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010170b:	80 38 00             	cmpb   $0x0,(%eax)
f010170e:	74 19                	je     f0101729 <mem_init+0x4b2>
f0101710:	68 90 61 10 f0       	push   $0xf0106190
f0101715:	68 ba 5f 10 f0       	push   $0xf0105fba
f010171a:	68 43 03 00 00       	push   $0x343
f010171f:	68 94 5f 10 f0       	push   $0xf0105f94
f0101724:	e8 17 e9 ff ff       	call   f0100040 <_panic>
f0101729:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010172c:	39 d0                	cmp    %edx,%eax
f010172e:	75 db                	jne    f010170b <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101730:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101733:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f0101738:	83 ec 0c             	sub    $0xc,%esp
f010173b:	56                   	push   %esi
f010173c:	e8 d8 f7 ff ff       	call   f0100f19 <page_free>
	page_free(pp1);
f0101741:	89 3c 24             	mov    %edi,(%esp)
f0101744:	e8 d0 f7 ff ff       	call   f0100f19 <page_free>
	page_free(pp2);
f0101749:	83 c4 04             	add    $0x4,%esp
f010174c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010174f:	e8 c5 f7 ff ff       	call   f0100f19 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101754:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101759:	83 c4 10             	add    $0x10,%esp
f010175c:	eb 05                	jmp    f0101763 <mem_init+0x4ec>
		--nfree;
f010175e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101761:	8b 00                	mov    (%eax),%eax
f0101763:	85 c0                	test   %eax,%eax
f0101765:	75 f7                	jne    f010175e <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f0101767:	85 db                	test   %ebx,%ebx
f0101769:	74 19                	je     f0101784 <mem_init+0x50d>
f010176b:	68 9a 61 10 f0       	push   $0xf010619a
f0101770:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101775:	68 50 03 00 00       	push   $0x350
f010177a:	68 94 5f 10 f0       	push   $0xf0105f94
f010177f:	e8 bc e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101784:	83 ec 0c             	sub    $0xc,%esp
f0101787:	68 30 64 10 f0       	push   $0xf0106430
f010178c:	e8 f8 1e 00 00       	call   f0103689 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101791:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101798:	e8 0c f7 ff ff       	call   f0100ea9 <page_alloc>
f010179d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017a0:	83 c4 10             	add    $0x10,%esp
f01017a3:	85 c0                	test   %eax,%eax
f01017a5:	75 19                	jne    f01017c0 <mem_init+0x549>
f01017a7:	68 a8 60 10 f0       	push   $0xf01060a8
f01017ac:	68 ba 5f 10 f0       	push   $0xf0105fba
f01017b1:	68 b6 03 00 00       	push   $0x3b6
f01017b6:	68 94 5f 10 f0       	push   $0xf0105f94
f01017bb:	e8 80 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017c0:	83 ec 0c             	sub    $0xc,%esp
f01017c3:	6a 00                	push   $0x0
f01017c5:	e8 df f6 ff ff       	call   f0100ea9 <page_alloc>
f01017ca:	89 c3                	mov    %eax,%ebx
f01017cc:	83 c4 10             	add    $0x10,%esp
f01017cf:	85 c0                	test   %eax,%eax
f01017d1:	75 19                	jne    f01017ec <mem_init+0x575>
f01017d3:	68 be 60 10 f0       	push   $0xf01060be
f01017d8:	68 ba 5f 10 f0       	push   $0xf0105fba
f01017dd:	68 b7 03 00 00       	push   $0x3b7
f01017e2:	68 94 5f 10 f0       	push   $0xf0105f94
f01017e7:	e8 54 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017ec:	83 ec 0c             	sub    $0xc,%esp
f01017ef:	6a 00                	push   $0x0
f01017f1:	e8 b3 f6 ff ff       	call   f0100ea9 <page_alloc>
f01017f6:	89 c6                	mov    %eax,%esi
f01017f8:	83 c4 10             	add    $0x10,%esp
f01017fb:	85 c0                	test   %eax,%eax
f01017fd:	75 19                	jne    f0101818 <mem_init+0x5a1>
f01017ff:	68 d4 60 10 f0       	push   $0xf01060d4
f0101804:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101809:	68 b8 03 00 00       	push   $0x3b8
f010180e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101813:	e8 28 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101818:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010181b:	75 19                	jne    f0101836 <mem_init+0x5bf>
f010181d:	68 ea 60 10 f0       	push   $0xf01060ea
f0101822:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101827:	68 bb 03 00 00       	push   $0x3bb
f010182c:	68 94 5f 10 f0       	push   $0xf0105f94
f0101831:	e8 0a e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101836:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101839:	74 04                	je     f010183f <mem_init+0x5c8>
f010183b:	39 c3                	cmp    %eax,%ebx
f010183d:	75 19                	jne    f0101858 <mem_init+0x5e1>
f010183f:	68 10 64 10 f0       	push   $0xf0106410
f0101844:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101849:	68 bc 03 00 00       	push   $0x3bc
f010184e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101853:	e8 e8 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101858:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010185d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101860:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101867:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010186a:	83 ec 0c             	sub    $0xc,%esp
f010186d:	6a 00                	push   $0x0
f010186f:	e8 35 f6 ff ff       	call   f0100ea9 <page_alloc>
f0101874:	83 c4 10             	add    $0x10,%esp
f0101877:	85 c0                	test   %eax,%eax
f0101879:	74 19                	je     f0101894 <mem_init+0x61d>
f010187b:	68 53 61 10 f0       	push   $0xf0106153
f0101880:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101885:	68 c3 03 00 00       	push   $0x3c3
f010188a:	68 94 5f 10 f0       	push   $0xf0105f94
f010188f:	e8 ac e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101894:	83 ec 04             	sub    $0x4,%esp
f0101897:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010189a:	50                   	push   %eax
f010189b:	6a 00                	push   $0x0
f010189d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018a3:	e8 20 f8 ff ff       	call   f01010c8 <page_lookup>
f01018a8:	83 c4 10             	add    $0x10,%esp
f01018ab:	85 c0                	test   %eax,%eax
f01018ad:	74 19                	je     f01018c8 <mem_init+0x651>
f01018af:	68 50 64 10 f0       	push   $0xf0106450
f01018b4:	68 ba 5f 10 f0       	push   $0xf0105fba
f01018b9:	68 c6 03 00 00       	push   $0x3c6
f01018be:	68 94 5f 10 f0       	push   $0xf0105f94
f01018c3:	e8 78 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018c8:	6a 02                	push   $0x2
f01018ca:	6a 00                	push   $0x0
f01018cc:	53                   	push   %ebx
f01018cd:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018d3:	e8 c4 f8 ff ff       	call   f010119c <page_insert>
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	78 19                	js     f01018f8 <mem_init+0x681>
f01018df:	68 88 64 10 f0       	push   $0xf0106488
f01018e4:	68 ba 5f 10 f0       	push   $0xf0105fba
f01018e9:	68 c9 03 00 00       	push   $0x3c9
f01018ee:	68 94 5f 10 f0       	push   $0xf0105f94
f01018f3:	e8 48 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01018f8:	83 ec 0c             	sub    $0xc,%esp
f01018fb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018fe:	e8 16 f6 ff ff       	call   f0100f19 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101903:	6a 02                	push   $0x2
f0101905:	6a 00                	push   $0x0
f0101907:	53                   	push   %ebx
f0101908:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010190e:	e8 89 f8 ff ff       	call   f010119c <page_insert>
f0101913:	83 c4 20             	add    $0x20,%esp
f0101916:	85 c0                	test   %eax,%eax
f0101918:	74 19                	je     f0101933 <mem_init+0x6bc>
f010191a:	68 b8 64 10 f0       	push   $0xf01064b8
f010191f:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101924:	68 cd 03 00 00       	push   $0x3cd
f0101929:	68 94 5f 10 f0       	push   $0xf0105f94
f010192e:	e8 0d e7 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101933:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101939:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010193e:	89 c1                	mov    %eax,%ecx
f0101940:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101943:	8b 17                	mov    (%edi),%edx
f0101945:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010194b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010194e:	29 c8                	sub    %ecx,%eax
f0101950:	c1 f8 03             	sar    $0x3,%eax
f0101953:	c1 e0 0c             	shl    $0xc,%eax
f0101956:	39 c2                	cmp    %eax,%edx
f0101958:	74 19                	je     f0101973 <mem_init+0x6fc>
f010195a:	68 e8 64 10 f0       	push   $0xf01064e8
f010195f:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101964:	68 ce 03 00 00       	push   $0x3ce
f0101969:	68 94 5f 10 f0       	push   $0xf0105f94
f010196e:	e8 cd e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101973:	ba 00 00 00 00       	mov    $0x0,%edx
f0101978:	89 f8                	mov    %edi,%eax
f010197a:	e8 56 f1 ff ff       	call   f0100ad5 <check_va2pa>
f010197f:	89 da                	mov    %ebx,%edx
f0101981:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101984:	c1 fa 03             	sar    $0x3,%edx
f0101987:	c1 e2 0c             	shl    $0xc,%edx
f010198a:	39 d0                	cmp    %edx,%eax
f010198c:	74 19                	je     f01019a7 <mem_init+0x730>
f010198e:	68 10 65 10 f0       	push   $0xf0106510
f0101993:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101998:	68 cf 03 00 00       	push   $0x3cf
f010199d:	68 94 5f 10 f0       	push   $0xf0105f94
f01019a2:	e8 99 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019a7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019ac:	74 19                	je     f01019c7 <mem_init+0x750>
f01019ae:	68 a5 61 10 f0       	push   $0xf01061a5
f01019b3:	68 ba 5f 10 f0       	push   $0xf0105fba
f01019b8:	68 d0 03 00 00       	push   $0x3d0
f01019bd:	68 94 5f 10 f0       	push   $0xf0105f94
f01019c2:	e8 79 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01019c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ca:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019cf:	74 19                	je     f01019ea <mem_init+0x773>
f01019d1:	68 b6 61 10 f0       	push   $0xf01061b6
f01019d6:	68 ba 5f 10 f0       	push   $0xf0105fba
f01019db:	68 d1 03 00 00       	push   $0x3d1
f01019e0:	68 94 5f 10 f0       	push   $0xf0105f94
f01019e5:	e8 56 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019ea:	6a 02                	push   $0x2
f01019ec:	68 00 10 00 00       	push   $0x1000
f01019f1:	56                   	push   %esi
f01019f2:	57                   	push   %edi
f01019f3:	e8 a4 f7 ff ff       	call   f010119c <page_insert>
f01019f8:	83 c4 10             	add    $0x10,%esp
f01019fb:	85 c0                	test   %eax,%eax
f01019fd:	74 19                	je     f0101a18 <mem_init+0x7a1>
f01019ff:	68 40 65 10 f0       	push   $0xf0106540
f0101a04:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101a09:	68 d4 03 00 00       	push   $0x3d4
f0101a0e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101a13:	e8 28 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a18:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a1d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a22:	e8 ae f0 ff ff       	call   f0100ad5 <check_va2pa>
f0101a27:	89 f2                	mov    %esi,%edx
f0101a29:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a2f:	c1 fa 03             	sar    $0x3,%edx
f0101a32:	c1 e2 0c             	shl    $0xc,%edx
f0101a35:	39 d0                	cmp    %edx,%eax
f0101a37:	74 19                	je     f0101a52 <mem_init+0x7db>
f0101a39:	68 7c 65 10 f0       	push   $0xf010657c
f0101a3e:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101a43:	68 d5 03 00 00       	push   $0x3d5
f0101a48:	68 94 5f 10 f0       	push   $0xf0105f94
f0101a4d:	e8 ee e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a52:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a57:	74 19                	je     f0101a72 <mem_init+0x7fb>
f0101a59:	68 c7 61 10 f0       	push   $0xf01061c7
f0101a5e:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101a63:	68 d6 03 00 00       	push   $0x3d6
f0101a68:	68 94 5f 10 f0       	push   $0xf0105f94
f0101a6d:	e8 ce e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a72:	83 ec 0c             	sub    $0xc,%esp
f0101a75:	6a 00                	push   $0x0
f0101a77:	e8 2d f4 ff ff       	call   f0100ea9 <page_alloc>
f0101a7c:	83 c4 10             	add    $0x10,%esp
f0101a7f:	85 c0                	test   %eax,%eax
f0101a81:	74 19                	je     f0101a9c <mem_init+0x825>
f0101a83:	68 53 61 10 f0       	push   $0xf0106153
f0101a88:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101a8d:	68 d9 03 00 00       	push   $0x3d9
f0101a92:	68 94 5f 10 f0       	push   $0xf0105f94
f0101a97:	e8 a4 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a9c:	6a 02                	push   $0x2
f0101a9e:	68 00 10 00 00       	push   $0x1000
f0101aa3:	56                   	push   %esi
f0101aa4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101aaa:	e8 ed f6 ff ff       	call   f010119c <page_insert>
f0101aaf:	83 c4 10             	add    $0x10,%esp
f0101ab2:	85 c0                	test   %eax,%eax
f0101ab4:	74 19                	je     f0101acf <mem_init+0x858>
f0101ab6:	68 40 65 10 f0       	push   $0xf0106540
f0101abb:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101ac0:	68 dc 03 00 00       	push   $0x3dc
f0101ac5:	68 94 5f 10 f0       	push   $0xf0105f94
f0101aca:	e8 71 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101acf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ad4:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ad9:	e8 f7 ef ff ff       	call   f0100ad5 <check_va2pa>
f0101ade:	89 f2                	mov    %esi,%edx
f0101ae0:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101ae6:	c1 fa 03             	sar    $0x3,%edx
f0101ae9:	c1 e2 0c             	shl    $0xc,%edx
f0101aec:	39 d0                	cmp    %edx,%eax
f0101aee:	74 19                	je     f0101b09 <mem_init+0x892>
f0101af0:	68 7c 65 10 f0       	push   $0xf010657c
f0101af5:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101afa:	68 dd 03 00 00       	push   $0x3dd
f0101aff:	68 94 5f 10 f0       	push   $0xf0105f94
f0101b04:	e8 37 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b09:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b0e:	74 19                	je     f0101b29 <mem_init+0x8b2>
f0101b10:	68 c7 61 10 f0       	push   $0xf01061c7
f0101b15:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101b1a:	68 de 03 00 00       	push   $0x3de
f0101b1f:	68 94 5f 10 f0       	push   $0xf0105f94
f0101b24:	e8 17 e5 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b29:	83 ec 0c             	sub    $0xc,%esp
f0101b2c:	6a 00                	push   $0x0
f0101b2e:	e8 76 f3 ff ff       	call   f0100ea9 <page_alloc>
f0101b33:	83 c4 10             	add    $0x10,%esp
f0101b36:	85 c0                	test   %eax,%eax
f0101b38:	74 19                	je     f0101b53 <mem_init+0x8dc>
f0101b3a:	68 53 61 10 f0       	push   $0xf0106153
f0101b3f:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101b44:	68 e2 03 00 00       	push   $0x3e2
f0101b49:	68 94 5f 10 f0       	push   $0xf0105f94
f0101b4e:	e8 ed e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b53:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101b59:	8b 02                	mov    (%edx),%eax
f0101b5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b60:	89 c1                	mov    %eax,%ecx
f0101b62:	c1 e9 0c             	shr    $0xc,%ecx
f0101b65:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101b6b:	72 15                	jb     f0101b82 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b6d:	50                   	push   %eax
f0101b6e:	68 24 5a 10 f0       	push   $0xf0105a24
f0101b73:	68 e5 03 00 00       	push   $0x3e5
f0101b78:	68 94 5f 10 f0       	push   $0xf0105f94
f0101b7d:	e8 be e4 ff ff       	call   f0100040 <_panic>
f0101b82:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b87:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b8a:	83 ec 04             	sub    $0x4,%esp
f0101b8d:	6a 00                	push   $0x0
f0101b8f:	68 00 10 00 00       	push   $0x1000
f0101b94:	52                   	push   %edx
f0101b95:	e8 de f3 ff ff       	call   f0100f78 <pgdir_walk>
f0101b9a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b9d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ba0:	83 c4 10             	add    $0x10,%esp
f0101ba3:	39 d0                	cmp    %edx,%eax
f0101ba5:	74 19                	je     f0101bc0 <mem_init+0x949>
f0101ba7:	68 ac 65 10 f0       	push   $0xf01065ac
f0101bac:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101bb1:	68 e6 03 00 00       	push   $0x3e6
f0101bb6:	68 94 5f 10 f0       	push   $0xf0105f94
f0101bbb:	e8 80 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bc0:	6a 06                	push   $0x6
f0101bc2:	68 00 10 00 00       	push   $0x1000
f0101bc7:	56                   	push   %esi
f0101bc8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101bce:	e8 c9 f5 ff ff       	call   f010119c <page_insert>
f0101bd3:	83 c4 10             	add    $0x10,%esp
f0101bd6:	85 c0                	test   %eax,%eax
f0101bd8:	74 19                	je     f0101bf3 <mem_init+0x97c>
f0101bda:	68 ec 65 10 f0       	push   $0xf01065ec
f0101bdf:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101be4:	68 e9 03 00 00       	push   $0x3e9
f0101be9:	68 94 5f 10 f0       	push   $0xf0105f94
f0101bee:	e8 4d e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bf3:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101bf9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bfe:	89 f8                	mov    %edi,%eax
f0101c00:	e8 d0 ee ff ff       	call   f0100ad5 <check_va2pa>
f0101c05:	89 f2                	mov    %esi,%edx
f0101c07:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c0d:	c1 fa 03             	sar    $0x3,%edx
f0101c10:	c1 e2 0c             	shl    $0xc,%edx
f0101c13:	39 d0                	cmp    %edx,%eax
f0101c15:	74 19                	je     f0101c30 <mem_init+0x9b9>
f0101c17:	68 7c 65 10 f0       	push   $0xf010657c
f0101c1c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101c21:	68 ea 03 00 00       	push   $0x3ea
f0101c26:	68 94 5f 10 f0       	push   $0xf0105f94
f0101c2b:	e8 10 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c30:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c35:	74 19                	je     f0101c50 <mem_init+0x9d9>
f0101c37:	68 c7 61 10 f0       	push   $0xf01061c7
f0101c3c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101c41:	68 eb 03 00 00       	push   $0x3eb
f0101c46:	68 94 5f 10 f0       	push   $0xf0105f94
f0101c4b:	e8 f0 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c50:	83 ec 04             	sub    $0x4,%esp
f0101c53:	6a 00                	push   $0x0
f0101c55:	68 00 10 00 00       	push   $0x1000
f0101c5a:	57                   	push   %edi
f0101c5b:	e8 18 f3 ff ff       	call   f0100f78 <pgdir_walk>
f0101c60:	83 c4 10             	add    $0x10,%esp
f0101c63:	f6 00 04             	testb  $0x4,(%eax)
f0101c66:	75 19                	jne    f0101c81 <mem_init+0xa0a>
f0101c68:	68 2c 66 10 f0       	push   $0xf010662c
f0101c6d:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101c72:	68 ec 03 00 00       	push   $0x3ec
f0101c77:	68 94 5f 10 f0       	push   $0xf0105f94
f0101c7c:	e8 bf e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c81:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101c86:	f6 00 04             	testb  $0x4,(%eax)
f0101c89:	75 19                	jne    f0101ca4 <mem_init+0xa2d>
f0101c8b:	68 d8 61 10 f0       	push   $0xf01061d8
f0101c90:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101c95:	68 ed 03 00 00       	push   $0x3ed
f0101c9a:	68 94 5f 10 f0       	push   $0xf0105f94
f0101c9f:	e8 9c e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ca4:	6a 02                	push   $0x2
f0101ca6:	68 00 10 00 00       	push   $0x1000
f0101cab:	56                   	push   %esi
f0101cac:	50                   	push   %eax
f0101cad:	e8 ea f4 ff ff       	call   f010119c <page_insert>
f0101cb2:	83 c4 10             	add    $0x10,%esp
f0101cb5:	85 c0                	test   %eax,%eax
f0101cb7:	74 19                	je     f0101cd2 <mem_init+0xa5b>
f0101cb9:	68 40 65 10 f0       	push   $0xf0106540
f0101cbe:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101cc3:	68 f0 03 00 00       	push   $0x3f0
f0101cc8:	68 94 5f 10 f0       	push   $0xf0105f94
f0101ccd:	e8 6e e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cd2:	83 ec 04             	sub    $0x4,%esp
f0101cd5:	6a 00                	push   $0x0
f0101cd7:	68 00 10 00 00       	push   $0x1000
f0101cdc:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ce2:	e8 91 f2 ff ff       	call   f0100f78 <pgdir_walk>
f0101ce7:	83 c4 10             	add    $0x10,%esp
f0101cea:	f6 00 02             	testb  $0x2,(%eax)
f0101ced:	75 19                	jne    f0101d08 <mem_init+0xa91>
f0101cef:	68 60 66 10 f0       	push   $0xf0106660
f0101cf4:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101cf9:	68 f1 03 00 00       	push   $0x3f1
f0101cfe:	68 94 5f 10 f0       	push   $0xf0105f94
f0101d03:	e8 38 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d08:	83 ec 04             	sub    $0x4,%esp
f0101d0b:	6a 00                	push   $0x0
f0101d0d:	68 00 10 00 00       	push   $0x1000
f0101d12:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d18:	e8 5b f2 ff ff       	call   f0100f78 <pgdir_walk>
f0101d1d:	83 c4 10             	add    $0x10,%esp
f0101d20:	f6 00 04             	testb  $0x4,(%eax)
f0101d23:	74 19                	je     f0101d3e <mem_init+0xac7>
f0101d25:	68 94 66 10 f0       	push   $0xf0106694
f0101d2a:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101d2f:	68 f2 03 00 00       	push   $0x3f2
f0101d34:	68 94 5f 10 f0       	push   $0xf0105f94
f0101d39:	e8 02 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d3e:	6a 02                	push   $0x2
f0101d40:	68 00 00 40 00       	push   $0x400000
f0101d45:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d48:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d4e:	e8 49 f4 ff ff       	call   f010119c <page_insert>
f0101d53:	83 c4 10             	add    $0x10,%esp
f0101d56:	85 c0                	test   %eax,%eax
f0101d58:	78 19                	js     f0101d73 <mem_init+0xafc>
f0101d5a:	68 cc 66 10 f0       	push   $0xf01066cc
f0101d5f:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101d64:	68 f5 03 00 00       	push   $0x3f5
f0101d69:	68 94 5f 10 f0       	push   $0xf0105f94
f0101d6e:	e8 cd e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d73:	6a 02                	push   $0x2
f0101d75:	68 00 10 00 00       	push   $0x1000
f0101d7a:	53                   	push   %ebx
f0101d7b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d81:	e8 16 f4 ff ff       	call   f010119c <page_insert>
f0101d86:	83 c4 10             	add    $0x10,%esp
f0101d89:	85 c0                	test   %eax,%eax
f0101d8b:	74 19                	je     f0101da6 <mem_init+0xb2f>
f0101d8d:	68 04 67 10 f0       	push   $0xf0106704
f0101d92:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101d97:	68 f8 03 00 00       	push   $0x3f8
f0101d9c:	68 94 5f 10 f0       	push   $0xf0105f94
f0101da1:	e8 9a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101da6:	83 ec 04             	sub    $0x4,%esp
f0101da9:	6a 00                	push   $0x0
f0101dab:	68 00 10 00 00       	push   $0x1000
f0101db0:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101db6:	e8 bd f1 ff ff       	call   f0100f78 <pgdir_walk>
f0101dbb:	83 c4 10             	add    $0x10,%esp
f0101dbe:	f6 00 04             	testb  $0x4,(%eax)
f0101dc1:	74 19                	je     f0101ddc <mem_init+0xb65>
f0101dc3:	68 94 66 10 f0       	push   $0xf0106694
f0101dc8:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101dcd:	68 f9 03 00 00       	push   $0x3f9
f0101dd2:	68 94 5f 10 f0       	push   $0xf0105f94
f0101dd7:	e8 64 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ddc:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101de2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101de7:	89 f8                	mov    %edi,%eax
f0101de9:	e8 e7 ec ff ff       	call   f0100ad5 <check_va2pa>
f0101dee:	89 c1                	mov    %eax,%ecx
f0101df0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101df3:	89 d8                	mov    %ebx,%eax
f0101df5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101dfb:	c1 f8 03             	sar    $0x3,%eax
f0101dfe:	c1 e0 0c             	shl    $0xc,%eax
f0101e01:	39 c1                	cmp    %eax,%ecx
f0101e03:	74 19                	je     f0101e1e <mem_init+0xba7>
f0101e05:	68 40 67 10 f0       	push   $0xf0106740
f0101e0a:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101e0f:	68 fc 03 00 00       	push   $0x3fc
f0101e14:	68 94 5f 10 f0       	push   $0xf0105f94
f0101e19:	e8 22 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e1e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e23:	89 f8                	mov    %edi,%eax
f0101e25:	e8 ab ec ff ff       	call   f0100ad5 <check_va2pa>
f0101e2a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e2d:	74 19                	je     f0101e48 <mem_init+0xbd1>
f0101e2f:	68 6c 67 10 f0       	push   $0xf010676c
f0101e34:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101e39:	68 fd 03 00 00       	push   $0x3fd
f0101e3e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101e43:	e8 f8 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e48:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e4d:	74 19                	je     f0101e68 <mem_init+0xbf1>
f0101e4f:	68 ee 61 10 f0       	push   $0xf01061ee
f0101e54:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101e59:	68 ff 03 00 00       	push   $0x3ff
f0101e5e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101e63:	e8 d8 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e68:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e6d:	74 19                	je     f0101e88 <mem_init+0xc11>
f0101e6f:	68 ff 61 10 f0       	push   $0xf01061ff
f0101e74:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101e79:	68 00 04 00 00       	push   $0x400
f0101e7e:	68 94 5f 10 f0       	push   $0xf0105f94
f0101e83:	e8 b8 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e88:	83 ec 0c             	sub    $0xc,%esp
f0101e8b:	6a 00                	push   $0x0
f0101e8d:	e8 17 f0 ff ff       	call   f0100ea9 <page_alloc>
f0101e92:	83 c4 10             	add    $0x10,%esp
f0101e95:	39 c6                	cmp    %eax,%esi
f0101e97:	75 04                	jne    f0101e9d <mem_init+0xc26>
f0101e99:	85 c0                	test   %eax,%eax
f0101e9b:	75 19                	jne    f0101eb6 <mem_init+0xc3f>
f0101e9d:	68 9c 67 10 f0       	push   $0xf010679c
f0101ea2:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101ea7:	68 03 04 00 00       	push   $0x403
f0101eac:	68 94 5f 10 f0       	push   $0xf0105f94
f0101eb1:	e8 8a e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101eb6:	83 ec 08             	sub    $0x8,%esp
f0101eb9:	6a 00                	push   $0x0
f0101ebb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ec1:	e8 89 f2 ff ff       	call   f010114f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ec6:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101ecc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ed1:	89 f8                	mov    %edi,%eax
f0101ed3:	e8 fd eb ff ff       	call   f0100ad5 <check_va2pa>
f0101ed8:	83 c4 10             	add    $0x10,%esp
f0101edb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ede:	74 19                	je     f0101ef9 <mem_init+0xc82>
f0101ee0:	68 c0 67 10 f0       	push   $0xf01067c0
f0101ee5:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101eea:	68 07 04 00 00       	push   $0x407
f0101eef:	68 94 5f 10 f0       	push   $0xf0105f94
f0101ef4:	e8 47 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ef9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101efe:	89 f8                	mov    %edi,%eax
f0101f00:	e8 d0 eb ff ff       	call   f0100ad5 <check_va2pa>
f0101f05:	89 da                	mov    %ebx,%edx
f0101f07:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f0d:	c1 fa 03             	sar    $0x3,%edx
f0101f10:	c1 e2 0c             	shl    $0xc,%edx
f0101f13:	39 d0                	cmp    %edx,%eax
f0101f15:	74 19                	je     f0101f30 <mem_init+0xcb9>
f0101f17:	68 6c 67 10 f0       	push   $0xf010676c
f0101f1c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101f21:	68 08 04 00 00       	push   $0x408
f0101f26:	68 94 5f 10 f0       	push   $0xf0105f94
f0101f2b:	e8 10 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f30:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f35:	74 19                	je     f0101f50 <mem_init+0xcd9>
f0101f37:	68 a5 61 10 f0       	push   $0xf01061a5
f0101f3c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101f41:	68 09 04 00 00       	push   $0x409
f0101f46:	68 94 5f 10 f0       	push   $0xf0105f94
f0101f4b:	e8 f0 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f50:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f55:	74 19                	je     f0101f70 <mem_init+0xcf9>
f0101f57:	68 ff 61 10 f0       	push   $0xf01061ff
f0101f5c:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101f61:	68 0a 04 00 00       	push   $0x40a
f0101f66:	68 94 5f 10 f0       	push   $0xf0105f94
f0101f6b:	e8 d0 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f70:	6a 00                	push   $0x0
f0101f72:	68 00 10 00 00       	push   $0x1000
f0101f77:	53                   	push   %ebx
f0101f78:	57                   	push   %edi
f0101f79:	e8 1e f2 ff ff       	call   f010119c <page_insert>
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	85 c0                	test   %eax,%eax
f0101f83:	74 19                	je     f0101f9e <mem_init+0xd27>
f0101f85:	68 e4 67 10 f0       	push   $0xf01067e4
f0101f8a:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101f8f:	68 0d 04 00 00       	push   $0x40d
f0101f94:	68 94 5f 10 f0       	push   $0xf0105f94
f0101f99:	e8 a2 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101f9e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fa3:	75 19                	jne    f0101fbe <mem_init+0xd47>
f0101fa5:	68 10 62 10 f0       	push   $0xf0106210
f0101faa:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101faf:	68 0e 04 00 00       	push   $0x40e
f0101fb4:	68 94 5f 10 f0       	push   $0xf0105f94
f0101fb9:	e8 82 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101fbe:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101fc1:	74 19                	je     f0101fdc <mem_init+0xd65>
f0101fc3:	68 1c 62 10 f0       	push   $0xf010621c
f0101fc8:	68 ba 5f 10 f0       	push   $0xf0105fba
f0101fcd:	68 0f 04 00 00       	push   $0x40f
f0101fd2:	68 94 5f 10 f0       	push   $0xf0105f94
f0101fd7:	e8 64 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fdc:	83 ec 08             	sub    $0x8,%esp
f0101fdf:	68 00 10 00 00       	push   $0x1000
f0101fe4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101fea:	e8 60 f1 ff ff       	call   f010114f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fef:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101ff5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ffa:	89 f8                	mov    %edi,%eax
f0101ffc:	e8 d4 ea ff ff       	call   f0100ad5 <check_va2pa>
f0102001:	83 c4 10             	add    $0x10,%esp
f0102004:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102007:	74 19                	je     f0102022 <mem_init+0xdab>
f0102009:	68 c0 67 10 f0       	push   $0xf01067c0
f010200e:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102013:	68 13 04 00 00       	push   $0x413
f0102018:	68 94 5f 10 f0       	push   $0xf0105f94
f010201d:	e8 1e e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102022:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102027:	89 f8                	mov    %edi,%eax
f0102029:	e8 a7 ea ff ff       	call   f0100ad5 <check_va2pa>
f010202e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102031:	74 19                	je     f010204c <mem_init+0xdd5>
f0102033:	68 1c 68 10 f0       	push   $0xf010681c
f0102038:	68 ba 5f 10 f0       	push   $0xf0105fba
f010203d:	68 14 04 00 00       	push   $0x414
f0102042:	68 94 5f 10 f0       	push   $0xf0105f94
f0102047:	e8 f4 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010204c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102051:	74 19                	je     f010206c <mem_init+0xdf5>
f0102053:	68 31 62 10 f0       	push   $0xf0106231
f0102058:	68 ba 5f 10 f0       	push   $0xf0105fba
f010205d:	68 15 04 00 00       	push   $0x415
f0102062:	68 94 5f 10 f0       	push   $0xf0105f94
f0102067:	e8 d4 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010206c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102071:	74 19                	je     f010208c <mem_init+0xe15>
f0102073:	68 ff 61 10 f0       	push   $0xf01061ff
f0102078:	68 ba 5f 10 f0       	push   $0xf0105fba
f010207d:	68 16 04 00 00       	push   $0x416
f0102082:	68 94 5f 10 f0       	push   $0xf0105f94
f0102087:	e8 b4 df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010208c:	83 ec 0c             	sub    $0xc,%esp
f010208f:	6a 00                	push   $0x0
f0102091:	e8 13 ee ff ff       	call   f0100ea9 <page_alloc>
f0102096:	83 c4 10             	add    $0x10,%esp
f0102099:	85 c0                	test   %eax,%eax
f010209b:	74 04                	je     f01020a1 <mem_init+0xe2a>
f010209d:	39 c3                	cmp    %eax,%ebx
f010209f:	74 19                	je     f01020ba <mem_init+0xe43>
f01020a1:	68 44 68 10 f0       	push   $0xf0106844
f01020a6:	68 ba 5f 10 f0       	push   $0xf0105fba
f01020ab:	68 19 04 00 00       	push   $0x419
f01020b0:	68 94 5f 10 f0       	push   $0xf0105f94
f01020b5:	e8 86 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020ba:	83 ec 0c             	sub    $0xc,%esp
f01020bd:	6a 00                	push   $0x0
f01020bf:	e8 e5 ed ff ff       	call   f0100ea9 <page_alloc>
f01020c4:	83 c4 10             	add    $0x10,%esp
f01020c7:	85 c0                	test   %eax,%eax
f01020c9:	74 19                	je     f01020e4 <mem_init+0xe6d>
f01020cb:	68 53 61 10 f0       	push   $0xf0106153
f01020d0:	68 ba 5f 10 f0       	push   $0xf0105fba
f01020d5:	68 1c 04 00 00       	push   $0x41c
f01020da:	68 94 5f 10 f0       	push   $0xf0105f94
f01020df:	e8 5c df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01020e4:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f01020ea:	8b 11                	mov    (%ecx),%edx
f01020ec:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01020f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020f5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01020fb:	c1 f8 03             	sar    $0x3,%eax
f01020fe:	c1 e0 0c             	shl    $0xc,%eax
f0102101:	39 c2                	cmp    %eax,%edx
f0102103:	74 19                	je     f010211e <mem_init+0xea7>
f0102105:	68 e8 64 10 f0       	push   $0xf01064e8
f010210a:	68 ba 5f 10 f0       	push   $0xf0105fba
f010210f:	68 1f 04 00 00       	push   $0x41f
f0102114:	68 94 5f 10 f0       	push   $0xf0105f94
f0102119:	e8 22 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010211e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102124:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102127:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010212c:	74 19                	je     f0102147 <mem_init+0xed0>
f010212e:	68 b6 61 10 f0       	push   $0xf01061b6
f0102133:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102138:	68 21 04 00 00       	push   $0x421
f010213d:	68 94 5f 10 f0       	push   $0xf0105f94
f0102142:	e8 f9 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102147:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102150:	83 ec 0c             	sub    $0xc,%esp
f0102153:	50                   	push   %eax
f0102154:	e8 c0 ed ff ff       	call   f0100f19 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102159:	83 c4 0c             	add    $0xc,%esp
f010215c:	6a 01                	push   $0x1
f010215e:	68 00 10 40 00       	push   $0x401000
f0102163:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102169:	e8 0a ee ff ff       	call   f0100f78 <pgdir_walk>
f010216e:	89 c7                	mov    %eax,%edi
f0102170:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102173:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102178:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010217b:	8b 40 04             	mov    0x4(%eax),%eax
f010217e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102183:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0102189:	89 c2                	mov    %eax,%edx
f010218b:	c1 ea 0c             	shr    $0xc,%edx
f010218e:	83 c4 10             	add    $0x10,%esp
f0102191:	39 ca                	cmp    %ecx,%edx
f0102193:	72 15                	jb     f01021aa <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102195:	50                   	push   %eax
f0102196:	68 24 5a 10 f0       	push   $0xf0105a24
f010219b:	68 28 04 00 00       	push   $0x428
f01021a0:	68 94 5f 10 f0       	push   $0xf0105f94
f01021a5:	e8 96 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021aa:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021af:	39 c7                	cmp    %eax,%edi
f01021b1:	74 19                	je     f01021cc <mem_init+0xf55>
f01021b3:	68 42 62 10 f0       	push   $0xf0106242
f01021b8:	68 ba 5f 10 f0       	push   $0xf0105fba
f01021bd:	68 29 04 00 00       	push   $0x429
f01021c2:	68 94 5f 10 f0       	push   $0xf0105f94
f01021c7:	e8 74 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01021cc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01021cf:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01021d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021d9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021df:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01021e5:	c1 f8 03             	sar    $0x3,%eax
f01021e8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021eb:	89 c2                	mov    %eax,%edx
f01021ed:	c1 ea 0c             	shr    $0xc,%edx
f01021f0:	39 d1                	cmp    %edx,%ecx
f01021f2:	77 12                	ja     f0102206 <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021f4:	50                   	push   %eax
f01021f5:	68 24 5a 10 f0       	push   $0xf0105a24
f01021fa:	6a 58                	push   $0x58
f01021fc:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102201:	e8 3a de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102206:	83 ec 04             	sub    $0x4,%esp
f0102209:	68 00 10 00 00       	push   $0x1000
f010220e:	68 ff 00 00 00       	push   $0xff
f0102213:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102218:	50                   	push   %eax
f0102219:	e8 2e 2b 00 00       	call   f0104d4c <memset>
	page_free(pp0);
f010221e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102221:	89 3c 24             	mov    %edi,(%esp)
f0102224:	e8 f0 ec ff ff       	call   f0100f19 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102229:	83 c4 0c             	add    $0xc,%esp
f010222c:	6a 01                	push   $0x1
f010222e:	6a 00                	push   $0x0
f0102230:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102236:	e8 3d ed ff ff       	call   f0100f78 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010223b:	89 fa                	mov    %edi,%edx
f010223d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102243:	c1 fa 03             	sar    $0x3,%edx
f0102246:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102249:	89 d0                	mov    %edx,%eax
f010224b:	c1 e8 0c             	shr    $0xc,%eax
f010224e:	83 c4 10             	add    $0x10,%esp
f0102251:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0102257:	72 12                	jb     f010226b <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102259:	52                   	push   %edx
f010225a:	68 24 5a 10 f0       	push   $0xf0105a24
f010225f:	6a 58                	push   $0x58
f0102261:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102266:	e8 d5 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010226b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102271:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102274:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010227a:	f6 00 01             	testb  $0x1,(%eax)
f010227d:	74 19                	je     f0102298 <mem_init+0x1021>
f010227f:	68 5a 62 10 f0       	push   $0xf010625a
f0102284:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102289:	68 33 04 00 00       	push   $0x433
f010228e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102293:	e8 a8 dd ff ff       	call   f0100040 <_panic>
f0102298:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010229b:	39 d0                	cmp    %edx,%eax
f010229d:	75 db                	jne    f010227a <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010229f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01022a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ad:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022b3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022b6:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f01022bc:	83 ec 0c             	sub    $0xc,%esp
f01022bf:	50                   	push   %eax
f01022c0:	e8 54 ec ff ff       	call   f0100f19 <page_free>
	page_free(pp1);
f01022c5:	89 1c 24             	mov    %ebx,(%esp)
f01022c8:	e8 4c ec ff ff       	call   f0100f19 <page_free>
	page_free(pp2);
f01022cd:	89 34 24             	mov    %esi,(%esp)
f01022d0:	e8 44 ec ff ff       	call   f0100f19 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01022d5:	83 c4 08             	add    $0x8,%esp
f01022d8:	68 01 10 00 00       	push   $0x1001
f01022dd:	6a 00                	push   $0x0
f01022df:	e8 30 ef ff ff       	call   f0101214 <mmio_map_region>
f01022e4:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01022e6:	83 c4 08             	add    $0x8,%esp
f01022e9:	68 00 10 00 00       	push   $0x1000
f01022ee:	6a 00                	push   $0x0
f01022f0:	e8 1f ef ff ff       	call   f0101214 <mmio_map_region>
f01022f5:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01022f7:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01022fd:	83 c4 10             	add    $0x10,%esp
f0102300:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102306:	76 07                	jbe    f010230f <mem_init+0x1098>
f0102308:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010230d:	76 19                	jbe    f0102328 <mem_init+0x10b1>
f010230f:	68 68 68 10 f0       	push   $0xf0106868
f0102314:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102319:	68 43 04 00 00       	push   $0x443
f010231e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102323:	e8 18 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102328:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010232e:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102334:	77 08                	ja     f010233e <mem_init+0x10c7>
f0102336:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010233c:	77 19                	ja     f0102357 <mem_init+0x10e0>
f010233e:	68 90 68 10 f0       	push   $0xf0106890
f0102343:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102348:	68 44 04 00 00       	push   $0x444
f010234d:	68 94 5f 10 f0       	push   $0xf0105f94
f0102352:	e8 e9 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102357:	89 da                	mov    %ebx,%edx
f0102359:	09 f2                	or     %esi,%edx
f010235b:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102361:	74 19                	je     f010237c <mem_init+0x1105>
f0102363:	68 b8 68 10 f0       	push   $0xf01068b8
f0102368:	68 ba 5f 10 f0       	push   $0xf0105fba
f010236d:	68 46 04 00 00       	push   $0x446
f0102372:	68 94 5f 10 f0       	push   $0xf0105f94
f0102377:	e8 c4 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010237c:	39 c6                	cmp    %eax,%esi
f010237e:	73 19                	jae    f0102399 <mem_init+0x1122>
f0102380:	68 71 62 10 f0       	push   $0xf0106271
f0102385:	68 ba 5f 10 f0       	push   $0xf0105fba
f010238a:	68 48 04 00 00       	push   $0x448
f010238f:	68 94 5f 10 f0       	push   $0xf0105f94
f0102394:	e8 a7 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102399:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f010239f:	89 da                	mov    %ebx,%edx
f01023a1:	89 f8                	mov    %edi,%eax
f01023a3:	e8 2d e7 ff ff       	call   f0100ad5 <check_va2pa>
f01023a8:	85 c0                	test   %eax,%eax
f01023aa:	74 19                	je     f01023c5 <mem_init+0x114e>
f01023ac:	68 e0 68 10 f0       	push   $0xf01068e0
f01023b1:	68 ba 5f 10 f0       	push   $0xf0105fba
f01023b6:	68 4a 04 00 00       	push   $0x44a
f01023bb:	68 94 5f 10 f0       	push   $0xf0105f94
f01023c0:	e8 7b dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01023c5:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01023cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01023ce:	89 c2                	mov    %eax,%edx
f01023d0:	89 f8                	mov    %edi,%eax
f01023d2:	e8 fe e6 ff ff       	call   f0100ad5 <check_va2pa>
f01023d7:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01023dc:	74 19                	je     f01023f7 <mem_init+0x1180>
f01023de:	68 04 69 10 f0       	push   $0xf0106904
f01023e3:	68 ba 5f 10 f0       	push   $0xf0105fba
f01023e8:	68 4b 04 00 00       	push   $0x44b
f01023ed:	68 94 5f 10 f0       	push   $0xf0105f94
f01023f2:	e8 49 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01023f7:	89 f2                	mov    %esi,%edx
f01023f9:	89 f8                	mov    %edi,%eax
f01023fb:	e8 d5 e6 ff ff       	call   f0100ad5 <check_va2pa>
f0102400:	85 c0                	test   %eax,%eax
f0102402:	74 19                	je     f010241d <mem_init+0x11a6>
f0102404:	68 34 69 10 f0       	push   $0xf0106934
f0102409:	68 ba 5f 10 f0       	push   $0xf0105fba
f010240e:	68 4c 04 00 00       	push   $0x44c
f0102413:	68 94 5f 10 f0       	push   $0xf0105f94
f0102418:	e8 23 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010241d:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102423:	89 f8                	mov    %edi,%eax
f0102425:	e8 ab e6 ff ff       	call   f0100ad5 <check_va2pa>
f010242a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010242d:	74 19                	je     f0102448 <mem_init+0x11d1>
f010242f:	68 58 69 10 f0       	push   $0xf0106958
f0102434:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102439:	68 4d 04 00 00       	push   $0x44d
f010243e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102443:	e8 f8 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102448:	83 ec 04             	sub    $0x4,%esp
f010244b:	6a 00                	push   $0x0
f010244d:	53                   	push   %ebx
f010244e:	57                   	push   %edi
f010244f:	e8 24 eb ff ff       	call   f0100f78 <pgdir_walk>
f0102454:	83 c4 10             	add    $0x10,%esp
f0102457:	f6 00 1a             	testb  $0x1a,(%eax)
f010245a:	75 19                	jne    f0102475 <mem_init+0x11fe>
f010245c:	68 84 69 10 f0       	push   $0xf0106984
f0102461:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102466:	68 4f 04 00 00       	push   $0x44f
f010246b:	68 94 5f 10 f0       	push   $0xf0105f94
f0102470:	e8 cb db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102475:	83 ec 04             	sub    $0x4,%esp
f0102478:	6a 00                	push   $0x0
f010247a:	53                   	push   %ebx
f010247b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102481:	e8 f2 ea ff ff       	call   f0100f78 <pgdir_walk>
f0102486:	8b 00                	mov    (%eax),%eax
f0102488:	83 c4 10             	add    $0x10,%esp
f010248b:	83 e0 04             	and    $0x4,%eax
f010248e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102491:	74 19                	je     f01024ac <mem_init+0x1235>
f0102493:	68 c8 69 10 f0       	push   $0xf01069c8
f0102498:	68 ba 5f 10 f0       	push   $0xf0105fba
f010249d:	68 50 04 00 00       	push   $0x450
f01024a2:	68 94 5f 10 f0       	push   $0xf0105f94
f01024a7:	e8 94 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024ac:	83 ec 04             	sub    $0x4,%esp
f01024af:	6a 00                	push   $0x0
f01024b1:	53                   	push   %ebx
f01024b2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024b8:	e8 bb ea ff ff       	call   f0100f78 <pgdir_walk>
f01024bd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024c3:	83 c4 0c             	add    $0xc,%esp
f01024c6:	6a 00                	push   $0x0
f01024c8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01024cb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024d1:	e8 a2 ea ff ff       	call   f0100f78 <pgdir_walk>
f01024d6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01024dc:	83 c4 0c             	add    $0xc,%esp
f01024df:	6a 00                	push   $0x0
f01024e1:	56                   	push   %esi
f01024e2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024e8:	e8 8b ea ff ff       	call   f0100f78 <pgdir_walk>
f01024ed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01024f3:	c7 04 24 83 62 10 f0 	movl   $0xf0106283,(%esp)
f01024fa:	e8 8a 11 00 00       	call   f0103689 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
	boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f01024ff:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102504:	83 c4 10             	add    $0x10,%esp
f0102507:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010250c:	77 15                	ja     f0102523 <mem_init+0x12ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010250e:	50                   	push   %eax
f010250f:	68 48 5a 10 f0       	push   $0xf0105a48
f0102514:	68 d0 00 00 00       	push   $0xd0
f0102519:	68 94 5f 10 f0       	push   $0xf0105f94
f010251e:	e8 1d db ff ff       	call   f0100040 <_panic>
f0102523:	83 ec 08             	sub    $0x8,%esp
f0102526:	6a 05                	push   $0x5
f0102528:	05 00 00 00 10       	add    $0x10000000,%eax
f010252d:	50                   	push   %eax
f010252e:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102533:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102538:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010253d:	e8 22 eb ff ff       	call   f0101064 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE,PADDR(envs), PTE_U | PTE_P);
f0102542:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102547:	83 c4 10             	add    $0x10,%esp
f010254a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010254f:	77 15                	ja     f0102566 <mem_init+0x12ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102551:	50                   	push   %eax
f0102552:	68 48 5a 10 f0       	push   $0xf0105a48
f0102557:	68 dc 00 00 00       	push   $0xdc
f010255c:	68 94 5f 10 f0       	push   $0xf0105f94
f0102561:	e8 da da ff ff       	call   f0100040 <_panic>
f0102566:	83 ec 08             	sub    $0x8,%esp
f0102569:	6a 05                	push   $0x5
f010256b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102570:	50                   	push   %eax
f0102571:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102576:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010257b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102580:	e8 df ea ff ff       	call   f0101064 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102585:	83 c4 10             	add    $0x10,%esp
f0102588:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f010258d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102592:	77 15                	ja     f01025a9 <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102594:	50                   	push   %eax
f0102595:	68 48 5a 10 f0       	push   $0xf0105a48
f010259a:	68 e8 00 00 00       	push   $0xe8
f010259f:	68 94 5f 10 f0       	push   $0xf0105f94
f01025a4:	e8 97 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f01025a9:	83 ec 08             	sub    $0x8,%esp
f01025ac:	6a 02                	push   $0x2
f01025ae:	68 00 50 11 00       	push   $0x115000
f01025b3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025b8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025bd:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025c2:	e8 9d ea ff ff       	call   f0101064 <boot_map_region>

	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f01025c7:	83 c4 08             	add    $0x8,%esp
f01025ca:	6a 03                	push   $0x3
f01025cc:	6a 00                	push   $0x0
f01025ce:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01025d3:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01025d8:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025dd:	e8 82 ea ff ff       	call   f0101064 <boot_map_region>
f01025e2:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f01025e9:	83 c4 10             	add    $0x10,%esp
f01025ec:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f01025f1:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025f6:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01025fc:	77 15                	ja     f0102613 <mem_init+0x139c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025fe:	53                   	push   %ebx
f01025ff:	68 48 5a 10 f0       	push   $0xf0105a48
f0102604:	68 30 01 00 00       	push   $0x130
f0102609:	68 94 5f 10 f0       	push   $0xf0105f94
f010260e:	e8 2d da ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	
		uint32_t i, currstack;
	for (i=0 ; i < NCPU; i++){
		currstack = KSTACKTOP - i*(KSTKSIZE + KSTKGAP) - KSTKSIZE;
		boot_map_region(kern_pgdir, currstack, KSTKSIZE, 
f0102613:	83 ec 08             	sub    $0x8,%esp
f0102616:	6a 03                	push   $0x3
f0102618:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010261e:	50                   	push   %eax
f010261f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102624:	89 f2                	mov    %esi,%edx
f0102626:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010262b:	e8 34 ea ff ff       	call   f0101064 <boot_map_region>
f0102630:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102636:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	
		uint32_t i, currstack;
	for (i=0 ; i < NCPU; i++){
f010263c:	83 c4 10             	add    $0x10,%esp
f010263f:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102644:	39 d8                	cmp    %ebx,%eax
f0102646:	75 ae                	jne    f01025f6 <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102648:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010264e:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0102653:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102656:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010265d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102662:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102665:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010266b:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010266e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102673:	eb 55                	jmp    f01026ca <mem_init+0x1453>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102675:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010267b:	89 f8                	mov    %edi,%eax
f010267d:	e8 53 e4 ff ff       	call   f0100ad5 <check_va2pa>
f0102682:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102689:	77 15                	ja     f01026a0 <mem_init+0x1429>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010268b:	56                   	push   %esi
f010268c:	68 48 5a 10 f0       	push   $0xf0105a48
f0102691:	68 68 03 00 00       	push   $0x368
f0102696:	68 94 5f 10 f0       	push   $0xf0105f94
f010269b:	e8 a0 d9 ff ff       	call   f0100040 <_panic>
f01026a0:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026a7:	39 c2                	cmp    %eax,%edx
f01026a9:	74 19                	je     f01026c4 <mem_init+0x144d>
f01026ab:	68 fc 69 10 f0       	push   $0xf01069fc
f01026b0:	68 ba 5f 10 f0       	push   $0xf0105fba
f01026b5:	68 68 03 00 00       	push   $0x368
f01026ba:	68 94 5f 10 f0       	push   $0xf0105f94
f01026bf:	e8 7c d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026c4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01026ca:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01026cd:	77 a6                	ja     f0102675 <mem_init+0x13fe>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01026cf:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026d5:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01026d8:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01026dd:	89 da                	mov    %ebx,%edx
f01026df:	89 f8                	mov    %edi,%eax
f01026e1:	e8 ef e3 ff ff       	call   f0100ad5 <check_va2pa>
f01026e6:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01026ed:	77 15                	ja     f0102704 <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ef:	56                   	push   %esi
f01026f0:	68 48 5a 10 f0       	push   $0xf0105a48
f01026f5:	68 6d 03 00 00       	push   $0x36d
f01026fa:	68 94 5f 10 f0       	push   $0xf0105f94
f01026ff:	e8 3c d9 ff ff       	call   f0100040 <_panic>
f0102704:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f010270b:	39 d0                	cmp    %edx,%eax
f010270d:	74 19                	je     f0102728 <mem_init+0x14b1>
f010270f:	68 30 6a 10 f0       	push   $0xf0106a30
f0102714:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102719:	68 6d 03 00 00       	push   $0x36d
f010271e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102723:	e8 18 d9 ff ff       	call   f0100040 <_panic>
f0102728:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010272e:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102734:	75 a7                	jne    f01026dd <mem_init+0x1466>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102736:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102739:	c1 e6 0c             	shl    $0xc,%esi
f010273c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102741:	eb 30                	jmp    f0102773 <mem_init+0x14fc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102743:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102749:	89 f8                	mov    %edi,%eax
f010274b:	e8 85 e3 ff ff       	call   f0100ad5 <check_va2pa>
f0102750:	39 c3                	cmp    %eax,%ebx
f0102752:	74 19                	je     f010276d <mem_init+0x14f6>
f0102754:	68 64 6a 10 f0       	push   $0xf0106a64
f0102759:	68 ba 5f 10 f0       	push   $0xf0105fba
f010275e:	68 71 03 00 00       	push   $0x371
f0102763:	68 94 5f 10 f0       	push   $0xf0105f94
f0102768:	e8 d3 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010276d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102773:	39 f3                	cmp    %esi,%ebx
f0102775:	72 cc                	jb     f0102743 <mem_init+0x14cc>
f0102777:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010277c:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010277f:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102782:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102785:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010278b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010278e:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102790:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102793:	05 00 80 00 20       	add    $0x20008000,%eax
f0102798:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010279b:	89 da                	mov    %ebx,%edx
f010279d:	89 f8                	mov    %edi,%eax
f010279f:	e8 31 e3 ff ff       	call   f0100ad5 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a4:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027aa:	77 15                	ja     f01027c1 <mem_init+0x154a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ac:	56                   	push   %esi
f01027ad:	68 48 5a 10 f0       	push   $0xf0105a48
f01027b2:	68 79 03 00 00       	push   $0x379
f01027b7:	68 94 5f 10 f0       	push   $0xf0105f94
f01027bc:	e8 7f d8 ff ff       	call   f0100040 <_panic>
f01027c1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01027c4:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f01027cb:	39 d0                	cmp    %edx,%eax
f01027cd:	74 19                	je     f01027e8 <mem_init+0x1571>
f01027cf:	68 8c 6a 10 f0       	push   $0xf0106a8c
f01027d4:	68 ba 5f 10 f0       	push   $0xf0105fba
f01027d9:	68 79 03 00 00       	push   $0x379
f01027de:	68 94 5f 10 f0       	push   $0xf0105f94
f01027e3:	e8 58 d8 ff ff       	call   f0100040 <_panic>
f01027e8:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027ee:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01027f1:	75 a8                	jne    f010279b <mem_init+0x1524>
f01027f3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027f6:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01027fc:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027ff:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102801:	89 da                	mov    %ebx,%edx
f0102803:	89 f8                	mov    %edi,%eax
f0102805:	e8 cb e2 ff ff       	call   f0100ad5 <check_va2pa>
f010280a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010280d:	74 19                	je     f0102828 <mem_init+0x15b1>
f010280f:	68 d4 6a 10 f0       	push   $0xf0106ad4
f0102814:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102819:	68 7b 03 00 00       	push   $0x37b
f010281e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102823:	e8 18 d8 ff ff       	call   f0100040 <_panic>
f0102828:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010282e:	39 f3                	cmp    %esi,%ebx
f0102830:	75 cf                	jne    f0102801 <mem_init+0x158a>
f0102832:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102835:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f010283c:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102843:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102849:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f010284e:	39 f0                	cmp    %esi,%eax
f0102850:	0f 85 2c ff ff ff    	jne    f0102782 <mem_init+0x150b>
f0102856:	b8 00 00 00 00       	mov    $0x0,%eax
f010285b:	eb 2a                	jmp    f0102887 <mem_init+0x1610>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010285d:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102863:	83 fa 04             	cmp    $0x4,%edx
f0102866:	77 1f                	ja     f0102887 <mem_init+0x1610>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102868:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010286c:	75 7e                	jne    f01028ec <mem_init+0x1675>
f010286e:	68 9c 62 10 f0       	push   $0xf010629c
f0102873:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102878:	68 86 03 00 00       	push   $0x386
f010287d:	68 94 5f 10 f0       	push   $0xf0105f94
f0102882:	e8 b9 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102887:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010288c:	76 3f                	jbe    f01028cd <mem_init+0x1656>
				assert(pgdir[i] & PTE_P);
f010288e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102891:	f6 c2 01             	test   $0x1,%dl
f0102894:	75 19                	jne    f01028af <mem_init+0x1638>
f0102896:	68 9c 62 10 f0       	push   $0xf010629c
f010289b:	68 ba 5f 10 f0       	push   $0xf0105fba
f01028a0:	68 8a 03 00 00       	push   $0x38a
f01028a5:	68 94 5f 10 f0       	push   $0xf0105f94
f01028aa:	e8 91 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028af:	f6 c2 02             	test   $0x2,%dl
f01028b2:	75 38                	jne    f01028ec <mem_init+0x1675>
f01028b4:	68 ad 62 10 f0       	push   $0xf01062ad
f01028b9:	68 ba 5f 10 f0       	push   $0xf0105fba
f01028be:	68 8b 03 00 00       	push   $0x38b
f01028c3:	68 94 5f 10 f0       	push   $0xf0105f94
f01028c8:	e8 73 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028cd:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01028d1:	74 19                	je     f01028ec <mem_init+0x1675>
f01028d3:	68 be 62 10 f0       	push   $0xf01062be
f01028d8:	68 ba 5f 10 f0       	push   $0xf0105fba
f01028dd:	68 8d 03 00 00       	push   $0x38d
f01028e2:	68 94 5f 10 f0       	push   $0xf0105f94
f01028e7:	e8 54 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028ec:	83 c0 01             	add    $0x1,%eax
f01028ef:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01028f4:	0f 86 63 ff ff ff    	jbe    f010285d <mem_init+0x15e6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028fa:	83 ec 0c             	sub    $0xc,%esp
f01028fd:	68 f8 6a 10 f0       	push   $0xf0106af8
f0102902:	e8 82 0d 00 00       	call   f0103689 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102907:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010290c:	83 c4 10             	add    $0x10,%esp
f010290f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102914:	77 15                	ja     f010292b <mem_init+0x16b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102916:	50                   	push   %eax
f0102917:	68 48 5a 10 f0       	push   $0xf0105a48
f010291c:	68 06 01 00 00       	push   $0x106
f0102921:	68 94 5f 10 f0       	push   $0xf0105f94
f0102926:	e8 15 d7 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010292b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102930:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102933:	b8 00 00 00 00       	mov    $0x0,%eax
f0102938:	e8 fc e1 ff ff       	call   f0100b39 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010293d:	0f 20 c0             	mov    %cr0,%eax
f0102940:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102943:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102948:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010294b:	83 ec 0c             	sub    $0xc,%esp
f010294e:	6a 00                	push   $0x0
f0102950:	e8 54 e5 ff ff       	call   f0100ea9 <page_alloc>
f0102955:	89 c3                	mov    %eax,%ebx
f0102957:	83 c4 10             	add    $0x10,%esp
f010295a:	85 c0                	test   %eax,%eax
f010295c:	75 19                	jne    f0102977 <mem_init+0x1700>
f010295e:	68 a8 60 10 f0       	push   $0xf01060a8
f0102963:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102968:	68 65 04 00 00       	push   $0x465
f010296d:	68 94 5f 10 f0       	push   $0xf0105f94
f0102972:	e8 c9 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102977:	83 ec 0c             	sub    $0xc,%esp
f010297a:	6a 00                	push   $0x0
f010297c:	e8 28 e5 ff ff       	call   f0100ea9 <page_alloc>
f0102981:	89 c7                	mov    %eax,%edi
f0102983:	83 c4 10             	add    $0x10,%esp
f0102986:	85 c0                	test   %eax,%eax
f0102988:	75 19                	jne    f01029a3 <mem_init+0x172c>
f010298a:	68 be 60 10 f0       	push   $0xf01060be
f010298f:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102994:	68 66 04 00 00       	push   $0x466
f0102999:	68 94 5f 10 f0       	push   $0xf0105f94
f010299e:	e8 9d d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029a3:	83 ec 0c             	sub    $0xc,%esp
f01029a6:	6a 00                	push   $0x0
f01029a8:	e8 fc e4 ff ff       	call   f0100ea9 <page_alloc>
f01029ad:	89 c6                	mov    %eax,%esi
f01029af:	83 c4 10             	add    $0x10,%esp
f01029b2:	85 c0                	test   %eax,%eax
f01029b4:	75 19                	jne    f01029cf <mem_init+0x1758>
f01029b6:	68 d4 60 10 f0       	push   $0xf01060d4
f01029bb:	68 ba 5f 10 f0       	push   $0xf0105fba
f01029c0:	68 67 04 00 00       	push   $0x467
f01029c5:	68 94 5f 10 f0       	push   $0xf0105f94
f01029ca:	e8 71 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01029cf:	83 ec 0c             	sub    $0xc,%esp
f01029d2:	53                   	push   %ebx
f01029d3:	e8 41 e5 ff ff       	call   f0100f19 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029d8:	89 f8                	mov    %edi,%eax
f01029da:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01029e0:	c1 f8 03             	sar    $0x3,%eax
f01029e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029e6:	89 c2                	mov    %eax,%edx
f01029e8:	c1 ea 0c             	shr    $0xc,%edx
f01029eb:	83 c4 10             	add    $0x10,%esp
f01029ee:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01029f4:	72 12                	jb     f0102a08 <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029f6:	50                   	push   %eax
f01029f7:	68 24 5a 10 f0       	push   $0xf0105a24
f01029fc:	6a 58                	push   $0x58
f01029fe:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102a03:	e8 38 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a08:	83 ec 04             	sub    $0x4,%esp
f0102a0b:	68 00 10 00 00       	push   $0x1000
f0102a10:	6a 01                	push   $0x1
f0102a12:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a17:	50                   	push   %eax
f0102a18:	e8 2f 23 00 00       	call   f0104d4c <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a1d:	89 f0                	mov    %esi,%eax
f0102a1f:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a25:	c1 f8 03             	sar    $0x3,%eax
f0102a28:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a2b:	89 c2                	mov    %eax,%edx
f0102a2d:	c1 ea 0c             	shr    $0xc,%edx
f0102a30:	83 c4 10             	add    $0x10,%esp
f0102a33:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a39:	72 12                	jb     f0102a4d <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a3b:	50                   	push   %eax
f0102a3c:	68 24 5a 10 f0       	push   $0xf0105a24
f0102a41:	6a 58                	push   $0x58
f0102a43:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102a48:	e8 f3 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a4d:	83 ec 04             	sub    $0x4,%esp
f0102a50:	68 00 10 00 00       	push   $0x1000
f0102a55:	6a 02                	push   $0x2
f0102a57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a5c:	50                   	push   %eax
f0102a5d:	e8 ea 22 00 00       	call   f0104d4c <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a62:	6a 02                	push   $0x2
f0102a64:	68 00 10 00 00       	push   $0x1000
f0102a69:	57                   	push   %edi
f0102a6a:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102a70:	e8 27 e7 ff ff       	call   f010119c <page_insert>
	assert(pp1->pp_ref == 1);
f0102a75:	83 c4 20             	add    $0x20,%esp
f0102a78:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a7d:	74 19                	je     f0102a98 <mem_init+0x1821>
f0102a7f:	68 a5 61 10 f0       	push   $0xf01061a5
f0102a84:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102a89:	68 6c 04 00 00       	push   $0x46c
f0102a8e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102a93:	e8 a8 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a98:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a9f:	01 01 01 
f0102aa2:	74 19                	je     f0102abd <mem_init+0x1846>
f0102aa4:	68 18 6b 10 f0       	push   $0xf0106b18
f0102aa9:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102aae:	68 6d 04 00 00       	push   $0x46d
f0102ab3:	68 94 5f 10 f0       	push   $0xf0105f94
f0102ab8:	e8 83 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102abd:	6a 02                	push   $0x2
f0102abf:	68 00 10 00 00       	push   $0x1000
f0102ac4:	56                   	push   %esi
f0102ac5:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102acb:	e8 cc e6 ff ff       	call   f010119c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ad0:	83 c4 10             	add    $0x10,%esp
f0102ad3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ada:	02 02 02 
f0102add:	74 19                	je     f0102af8 <mem_init+0x1881>
f0102adf:	68 3c 6b 10 f0       	push   $0xf0106b3c
f0102ae4:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102ae9:	68 6f 04 00 00       	push   $0x46f
f0102aee:	68 94 5f 10 f0       	push   $0xf0105f94
f0102af3:	e8 48 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102af8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102afd:	74 19                	je     f0102b18 <mem_init+0x18a1>
f0102aff:	68 c7 61 10 f0       	push   $0xf01061c7
f0102b04:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102b09:	68 70 04 00 00       	push   $0x470
f0102b0e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102b13:	e8 28 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b18:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b1d:	74 19                	je     f0102b38 <mem_init+0x18c1>
f0102b1f:	68 31 62 10 f0       	push   $0xf0106231
f0102b24:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102b29:	68 71 04 00 00       	push   $0x471
f0102b2e:	68 94 5f 10 f0       	push   $0xf0105f94
f0102b33:	e8 08 d5 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b38:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b3f:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b42:	89 f0                	mov    %esi,%eax
f0102b44:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b4a:	c1 f8 03             	sar    $0x3,%eax
f0102b4d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b50:	89 c2                	mov    %eax,%edx
f0102b52:	c1 ea 0c             	shr    $0xc,%edx
f0102b55:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102b5b:	72 12                	jb     f0102b6f <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b5d:	50                   	push   %eax
f0102b5e:	68 24 5a 10 f0       	push   $0xf0105a24
f0102b63:	6a 58                	push   $0x58
f0102b65:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102b6a:	e8 d1 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b6f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b76:	03 03 03 
f0102b79:	74 19                	je     f0102b94 <mem_init+0x191d>
f0102b7b:	68 60 6b 10 f0       	push   $0xf0106b60
f0102b80:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102b85:	68 73 04 00 00       	push   $0x473
f0102b8a:	68 94 5f 10 f0       	push   $0xf0105f94
f0102b8f:	e8 ac d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b94:	83 ec 08             	sub    $0x8,%esp
f0102b97:	68 00 10 00 00       	push   $0x1000
f0102b9c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ba2:	e8 a8 e5 ff ff       	call   f010114f <page_remove>
	assert(pp2->pp_ref == 0);
f0102ba7:	83 c4 10             	add    $0x10,%esp
f0102baa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102baf:	74 19                	je     f0102bca <mem_init+0x1953>
f0102bb1:	68 ff 61 10 f0       	push   $0xf01061ff
f0102bb6:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102bbb:	68 75 04 00 00       	push   $0x475
f0102bc0:	68 94 5f 10 f0       	push   $0xf0105f94
f0102bc5:	e8 76 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bca:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102bd0:	8b 11                	mov    (%ecx),%edx
f0102bd2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102bd8:	89 d8                	mov    %ebx,%eax
f0102bda:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102be0:	c1 f8 03             	sar    $0x3,%eax
f0102be3:	c1 e0 0c             	shl    $0xc,%eax
f0102be6:	39 c2                	cmp    %eax,%edx
f0102be8:	74 19                	je     f0102c03 <mem_init+0x198c>
f0102bea:	68 e8 64 10 f0       	push   $0xf01064e8
f0102bef:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102bf4:	68 78 04 00 00       	push   $0x478
f0102bf9:	68 94 5f 10 f0       	push   $0xf0105f94
f0102bfe:	e8 3d d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c03:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c09:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c0e:	74 19                	je     f0102c29 <mem_init+0x19b2>
f0102c10:	68 b6 61 10 f0       	push   $0xf01061b6
f0102c15:	68 ba 5f 10 f0       	push   $0xf0105fba
f0102c1a:	68 7a 04 00 00       	push   $0x47a
f0102c1f:	68 94 5f 10 f0       	push   $0xf0105f94
f0102c24:	e8 17 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c29:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c2f:	83 ec 0c             	sub    $0xc,%esp
f0102c32:	53                   	push   %ebx
f0102c33:	e8 e1 e2 ff ff       	call   f0100f19 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c38:	c7 04 24 8c 6b 10 f0 	movl   $0xf0106b8c,(%esp)
f0102c3f:	e8 45 0a 00 00       	call   f0103689 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c44:	83 c4 10             	add    $0x10,%esp
f0102c47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c4a:	5b                   	pop    %ebx
f0102c4b:	5e                   	pop    %esi
f0102c4c:	5f                   	pop    %edi
f0102c4d:	5d                   	pop    %ebp
f0102c4e:	c3                   	ret    

f0102c4f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c4f:	55                   	push   %ebp
f0102c50:	89 e5                	mov    %esp,%ebp
f0102c52:	57                   	push   %edi
f0102c53:	56                   	push   %esi
f0102c54:	53                   	push   %ebx
f0102c55:	83 ec 1c             	sub    $0x1c,%esp
f0102c58:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
f0102c5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c5e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
f0102c64:	8b 45 10             	mov    0x10(%ebp),%eax
f0102c67:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102c6a:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0102c71:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102c76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm |= PTE_P;
f0102c79:	8b 75 14             	mov    0x14(%ebp),%esi
f0102c7c:	83 ce 01             	or     $0x1,%esi

	for (; addr < end; addr += PGSIZE) {
f0102c7f:	eb 3f                	jmp    f0102cc0 <user_mem_check+0x71>
		pte = pgdir_walk(env->env_pgdir, (void*) addr, 0); 
f0102c81:	83 ec 04             	sub    $0x4,%esp
f0102c84:	6a 00                	push   $0x0
f0102c86:	53                   	push   %ebx
f0102c87:	ff 77 60             	pushl  0x60(%edi)
f0102c8a:	e8 e9 e2 ff ff       	call   f0100f78 <pgdir_walk>
		
		if (!pte|| addr >= ULIM|| ((*pte & perm) != perm) ) {
f0102c8f:	83 c4 10             	add    $0x10,%esp
f0102c92:	85 c0                	test   %eax,%eax
f0102c94:	74 10                	je     f0102ca6 <user_mem_check+0x57>
f0102c96:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102c9c:	77 08                	ja     f0102ca6 <user_mem_check+0x57>
f0102c9e:	89 f2                	mov    %esi,%edx
f0102ca0:	23 10                	and    (%eax),%edx
f0102ca2:	39 d6                	cmp    %edx,%esi
f0102ca4:	74 14                	je     f0102cba <user_mem_check+0x6b>
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
f0102ca6:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102ca9:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f0102cad:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102cb3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cb8:	eb 10                	jmp    f0102cca <user_mem_check+0x7b>
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
	perm |= PTE_P;

	for (; addr < end; addr += PGSIZE) {
f0102cba:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102cc0:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102cc3:	72 bc                	jb     f0102c81 <user_mem_check+0x32>
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
			return -E_FAULT;
		}
	}

	return 0;
f0102cc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102cca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ccd:	5b                   	pop    %ebx
f0102cce:	5e                   	pop    %esi
f0102ccf:	5f                   	pop    %edi
f0102cd0:	5d                   	pop    %ebp
f0102cd1:	c3                   	ret    

f0102cd2 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102cd2:	55                   	push   %ebp
f0102cd3:	89 e5                	mov    %esp,%ebp
f0102cd5:	53                   	push   %ebx
f0102cd6:	83 ec 04             	sub    $0x4,%esp
f0102cd9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102cdc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cdf:	83 c8 04             	or     $0x4,%eax
f0102ce2:	50                   	push   %eax
f0102ce3:	ff 75 10             	pushl  0x10(%ebp)
f0102ce6:	ff 75 0c             	pushl  0xc(%ebp)
f0102ce9:	53                   	push   %ebx
f0102cea:	e8 60 ff ff ff       	call   f0102c4f <user_mem_check>
f0102cef:	83 c4 10             	add    $0x10,%esp
f0102cf2:	85 c0                	test   %eax,%eax
f0102cf4:	79 21                	jns    f0102d17 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102cf6:	83 ec 04             	sub    $0x4,%esp
f0102cf9:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102cff:	ff 73 48             	pushl  0x48(%ebx)
f0102d02:	68 b8 6b 10 f0       	push   $0xf0106bb8
f0102d07:	e8 7d 09 00 00       	call   f0103689 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d0c:	89 1c 24             	mov    %ebx,(%esp)
f0102d0f:	e8 5f 06 00 00       	call   f0103373 <env_destroy>
f0102d14:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d17:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d1a:	c9                   	leave  
f0102d1b:	c3                   	ret    

f0102d1c <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d1c:	55                   	push   %ebp
f0102d1d:	89 e5                	mov    %esp,%ebp
f0102d1f:	57                   	push   %edi
f0102d20:	56                   	push   %esi
f0102d21:	53                   	push   %ebx
f0102d22:	83 ec 0c             	sub    $0xc,%esp
f0102d25:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
f0102d27:	89 d3                	mov    %edx,%ebx
f0102d29:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
f0102d2f:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d36:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while(startadd<endadd)
f0102d3c:	eb 59                	jmp    f0102d97 <region_alloc+0x7b>
	{
	struct PageInfo* p=page_alloc(false);	
f0102d3e:	83 ec 0c             	sub    $0xc,%esp
f0102d41:	6a 00                	push   $0x0
f0102d43:	e8 61 e1 ff ff       	call   f0100ea9 <page_alloc>
	
	if(p==NULL)
f0102d48:	83 c4 10             	add    $0x10,%esp
f0102d4b:	85 c0                	test   %eax,%eax
f0102d4d:	75 17                	jne    f0102d66 <region_alloc+0x4a>
	panic("Fail to alloc a page right now in region_alloc");
f0102d4f:	83 ec 04             	sub    $0x4,%esp
f0102d52:	68 f0 6b 10 f0       	push   $0xf0106bf0
f0102d57:	68 3d 01 00 00       	push   $0x13d
f0102d5c:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0102d61:	e8 da d2 ff ff       	call   f0100040 <_panic>
	
	if(page_insert(e->env_pgdir,p,(void *)startadd,PTE_U|PTE_W)==-E_NO_MEM)
f0102d66:	6a 06                	push   $0x6
f0102d68:	53                   	push   %ebx
f0102d69:	50                   	push   %eax
f0102d6a:	ff 77 60             	pushl  0x60(%edi)
f0102d6d:	e8 2a e4 ff ff       	call   f010119c <page_insert>
f0102d72:	83 c4 10             	add    $0x10,%esp
f0102d75:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102d78:	75 17                	jne    f0102d91 <region_alloc+0x75>
	panic("page insert failed");
f0102d7a:	83 ec 04             	sub    $0x4,%esp
f0102d7d:	68 2a 6c 10 f0       	push   $0xf0106c2a
f0102d82:	68 40 01 00 00       	push   $0x140
f0102d87:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0102d8c:	e8 af d2 ff ff       	call   f0100040 <_panic>
	
	startadd+=PGSIZE;
f0102d91:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
	
	while(startadd<endadd)
f0102d97:	39 f3                	cmp    %esi,%ebx
f0102d99:	72 a3                	jb     f0102d3e <region_alloc+0x22>
	
	startadd+=PGSIZE;
		
	}
	
}
f0102d9b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d9e:	5b                   	pop    %ebx
f0102d9f:	5e                   	pop    %esi
f0102da0:	5f                   	pop    %edi
f0102da1:	5d                   	pop    %ebp
f0102da2:	c3                   	ret    

f0102da3 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102da3:	55                   	push   %ebp
f0102da4:	89 e5                	mov    %esp,%ebp
f0102da6:	56                   	push   %esi
f0102da7:	53                   	push   %ebx
f0102da8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dab:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102dae:	85 c0                	test   %eax,%eax
f0102db0:	75 1a                	jne    f0102dcc <envid2env+0x29>
		*env_store = curenv;
f0102db2:	e8 b7 25 00 00       	call   f010536e <cpunum>
f0102db7:	6b c0 74             	imul   $0x74,%eax,%eax
f0102dba:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102dc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102dc3:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102dc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dca:	eb 70                	jmp    f0102e3c <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102dcc:	89 c3                	mov    %eax,%ebx
f0102dce:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102dd4:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102dd7:	03 1d 44 a2 22 f0    	add    0xf022a244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ddd:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102de1:	74 05                	je     f0102de8 <envid2env+0x45>
f0102de3:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102de6:	74 10                	je     f0102df8 <envid2env+0x55>
		*env_store = 0;
f0102de8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102deb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102df1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102df6:	eb 44                	jmp    f0102e3c <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102df8:	84 d2                	test   %dl,%dl
f0102dfa:	74 36                	je     f0102e32 <envid2env+0x8f>
f0102dfc:	e8 6d 25 00 00       	call   f010536e <cpunum>
f0102e01:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e04:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e0a:	74 26                	je     f0102e32 <envid2env+0x8f>
f0102e0c:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e0f:	e8 5a 25 00 00       	call   f010536e <cpunum>
f0102e14:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e17:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e1d:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e20:	74 10                	je     f0102e32 <envid2env+0x8f>
		*env_store = 0;
f0102e22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e25:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e2b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e30:	eb 0a                	jmp    f0102e3c <envid2env+0x99>
	}

	*env_store = e;
f0102e32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e35:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e37:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e3c:	5b                   	pop    %ebx
f0102e3d:	5e                   	pop    %esi
f0102e3e:	5d                   	pop    %ebp
f0102e3f:	c3                   	ret    

f0102e40 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e40:	55                   	push   %ebp
f0102e41:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102e43:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102e48:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102e4b:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e50:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102e52:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102e54:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e59:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102e5b:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102e5d:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102e5f:	ea 66 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e66
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102e66:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e6b:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102e6e:	5d                   	pop    %ebp
f0102e6f:	c3                   	ret    

f0102e70 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102e70:	55                   	push   %ebp
f0102e71:	89 e5                	mov    %esp,%ebp
f0102e73:	56                   	push   %esi
f0102e74:	53                   	push   %ebx
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
		envs[i].env_link = env_free_list;
f0102e75:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
f0102e7b:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102e81:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102e84:	ba 00 00 00 00       	mov    $0x0,%edx
f0102e89:	89 c1                	mov    %eax,%ecx
f0102e8b:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f0102e8e:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f0102e95:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102e98:	89 ca                	mov    %ecx,%edx
	// Set up envs array
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
f0102e9a:	39 d8                	cmp    %ebx,%eax
f0102e9c:	75 eb                	jne    f0102e89 <env_init+0x19>
f0102e9e:	89 35 48 a2 22 f0    	mov    %esi,0xf022a248
		envs[i].env_link = env_free_list;
		envs[i].env_status = ENV_FREE;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102ea4:	e8 97 ff ff ff       	call   f0102e40 <env_init_percpu>
	
	
}
f0102ea9:	5b                   	pop    %ebx
f0102eaa:	5e                   	pop    %esi
f0102eab:	5d                   	pop    %ebp
f0102eac:	c3                   	ret    

f0102ead <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102ead:	55                   	push   %ebp
f0102eae:	89 e5                	mov    %esp,%ebp
f0102eb0:	53                   	push   %ebx
f0102eb1:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102eb4:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
f0102eba:	85 db                	test   %ebx,%ebx
f0102ebc:	0f 84 7d 01 00 00    	je     f010303f <env_alloc+0x192>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ec2:	83 ec 0c             	sub    $0xc,%esp
f0102ec5:	6a 01                	push   $0x1
f0102ec7:	e8 dd df ff ff       	call   f0100ea9 <page_alloc>
f0102ecc:	83 c4 10             	add    $0x10,%esp
f0102ecf:	85 c0                	test   %eax,%eax
f0102ed1:	0f 84 6f 01 00 00    	je     f0103046 <env_alloc+0x199>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	
	p->pp_ref++;
f0102ed7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102edc:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102ee2:	c1 f8 03             	sar    $0x3,%eax
f0102ee5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ee8:	89 c2                	mov    %eax,%edx
f0102eea:	c1 ea 0c             	shr    $0xc,%edx
f0102eed:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102ef3:	72 12                	jb     f0102f07 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ef5:	50                   	push   %eax
f0102ef6:	68 24 5a 10 f0       	push   $0xf0105a24
f0102efb:	6a 58                	push   $0x58
f0102efd:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0102f02:	e8 39 d1 ff ff       	call   f0100040 <_panic>
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
f0102f07:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f0c:	89 43 60             	mov    %eax,0x60(%ebx)
f0102f0f:	b8 00 00 00 00       	mov    $0x0,%eax
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
f0102f14:	8b 53 60             	mov    0x60(%ebx),%edx
f0102f17:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0102f1e:	83 c0 04             	add    $0x4,%eax
	p->pp_ref++;
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f0102f21:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0102f26:	75 ec                	jne    f0102f14 <env_alloc+0x67>
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];	
f0102f28:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0102f2e:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102f31:	8b 53 60             	mov    0x60(%ebx),%edx
f0102f34:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102f37:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f0102f3a:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102f3f:	75 e7                	jne    f0102f28 <env_alloc+0x7b>
		
	
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f41:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f44:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f49:	77 15                	ja     f0102f60 <env_alloc+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f4b:	50                   	push   %eax
f0102f4c:	68 48 5a 10 f0       	push   $0xf0105a48
f0102f51:	68 d6 00 00 00       	push   $0xd6
f0102f56:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0102f5b:	e8 e0 d0 ff ff       	call   f0100040 <_panic>
f0102f60:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f66:	83 ca 05             	or     $0x5,%edx
f0102f69:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102f6f:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f72:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f77:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f7c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f81:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f84:	89 da                	mov    %ebx,%edx
f0102f86:	2b 15 44 a2 22 f0    	sub    0xf022a244,%edx
f0102f8c:	c1 fa 02             	sar    $0x2,%edx
f0102f8f:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102f95:	09 d0                	or     %edx,%eax
f0102f97:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f9d:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fa0:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102fa7:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102fae:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102fb5:	83 ec 04             	sub    $0x4,%esp
f0102fb8:	6a 44                	push   $0x44
f0102fba:	6a 00                	push   $0x0
f0102fbc:	53                   	push   %ebx
f0102fbd:	e8 8a 1d 00 00       	call   f0104d4c <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102fc2:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102fc8:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102fce:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102fd4:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102fdb:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102fe1:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102fe8:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102fec:	8b 43 44             	mov    0x44(%ebx),%eax
f0102fef:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	*newenv_store = e;
f0102ff4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff7:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ff9:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102ffc:	e8 6d 23 00 00       	call   f010536e <cpunum>
f0103001:	6b c0 74             	imul   $0x74,%eax,%eax
f0103004:	83 c4 10             	add    $0x10,%esp
f0103007:	ba 00 00 00 00       	mov    $0x0,%edx
f010300c:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103013:	74 11                	je     f0103026 <env_alloc+0x179>
f0103015:	e8 54 23 00 00       	call   f010536e <cpunum>
f010301a:	6b c0 74             	imul   $0x74,%eax,%eax
f010301d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103023:	8b 50 48             	mov    0x48(%eax),%edx
f0103026:	83 ec 04             	sub    $0x4,%esp
f0103029:	53                   	push   %ebx
f010302a:	52                   	push   %edx
f010302b:	68 3d 6c 10 f0       	push   $0xf0106c3d
f0103030:	e8 54 06 00 00       	call   f0103689 <cprintf>
	return 0;
f0103035:	83 c4 10             	add    $0x10,%esp
f0103038:	b8 00 00 00 00       	mov    $0x0,%eax
f010303d:	eb 0c                	jmp    f010304b <env_alloc+0x19e>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010303f:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103044:	eb 05                	jmp    f010304b <env_alloc+0x19e>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103046:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010304b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010304e:	c9                   	leave  
f010304f:	c3                   	ret    

f0103050 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103050:	55                   	push   %ebp
f0103051:	89 e5                	mov    %esp,%ebp
f0103053:	57                   	push   %edi
f0103054:	56                   	push   %esi
f0103055:	53                   	push   %ebx
f0103056:	83 ec 34             	sub    $0x34,%esp
f0103059:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *env;
	
	int check;
	check = env_alloc(&env, 0);
f010305c:	6a 00                	push   $0x0
f010305e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103061:	50                   	push   %eax
f0103062:	e8 46 fe ff ff       	call   f0102ead <env_alloc>
	
	if (check < 0) {
f0103067:	83 c4 10             	add    $0x10,%esp
f010306a:	85 c0                	test   %eax,%eax
f010306c:	79 15                	jns    f0103083 <env_create+0x33>
		panic("env_alloc: %e", check);
f010306e:	50                   	push   %eax
f010306f:	68 52 6c 10 f0       	push   $0xf0106c52
f0103074:	68 c5 01 00 00       	push   $0x1c5
f0103079:	68 1f 6c 10 f0       	push   $0xf0106c1f
f010307e:	e8 bd cf ff ff       	call   f0100040 <_panic>
		return;
	}
	
	load_icode(env, binary);
f0103083:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103086:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	
		// read 1st page off disk
	//readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
	
	lcr3(PADDR(e->env_pgdir));
f0103089:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010308c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103091:	77 15                	ja     f01030a8 <env_create+0x58>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103093:	50                   	push   %eax
f0103094:	68 48 5a 10 f0       	push   $0xf0105a48
f0103099:	68 88 01 00 00       	push   $0x188
f010309e:	68 1f 6c 10 f0       	push   $0xf0106c1f
f01030a3:	e8 98 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01030a8:	05 00 00 00 10       	add    $0x10000000,%eax
f01030ad:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr *ph, *eph;
	struct Elf * ELFHDR=(struct Elf *) binary;
	// is this a valid ELF?
	
	if (ELFHDR->e_magic != ELF_MAGIC)
f01030b0:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030b6:	74 17                	je     f01030cf <env_create+0x7f>
		panic("Not an elf file \n");
f01030b8:	83 ec 04             	sub    $0x4,%esp
f01030bb:	68 60 6c 10 f0       	push   $0xf0106c60
f01030c0:	68 8e 01 00 00       	push   $0x18e
f01030c5:	68 1f 6c 10 f0       	push   $0xf0106c1f
f01030ca:	e8 71 cf ff ff       	call   f0100040 <_panic>

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f01030cf:	89 fb                	mov    %edi,%ebx
f01030d1:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f01030d4:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030d8:	c1 e6 05             	shl    $0x5,%esi
f01030db:	01 de                	add    %ebx,%esi
	 
	e->env_tf.tf_eip = ELFHDR->e_entry;
f01030dd:	8b 47 18             	mov    0x18(%edi),%eax
f01030e0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01030e3:	89 41 30             	mov    %eax,0x30(%ecx)
f01030e6:	eb 60                	jmp    f0103148 <env_create+0xf8>
	
	
	for (; ph < eph; ph++)
{		
	
	if (ph->p_type != ELF_PROG_LOAD) 
f01030e8:	83 3b 01             	cmpl   $0x1,(%ebx)
f01030eb:	75 58                	jne    f0103145 <env_create+0xf5>
	continue;
	
	if (ph->p_filesz > ph->p_memsz)
f01030ed:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01030f0:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01030f3:	76 17                	jbe    f010310c <env_create+0xbc>
	panic("file size greater \n");
f01030f5:	83 ec 04             	sub    $0x4,%esp
f01030f8:	68 72 6c 10 f0       	push   $0xf0106c72
f01030fd:	68 a0 01 00 00       	push   $0x1a0
f0103102:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0103107:	e8 34 cf ff ff       	call   f0100040 <_panic>
	
	region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f010310c:	8b 53 08             	mov    0x8(%ebx),%edx
f010310f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103112:	e8 05 fc ff ff       	call   f0102d1c <region_alloc>
	
	memcpy((void *) ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103117:	83 ec 04             	sub    $0x4,%esp
f010311a:	ff 73 10             	pushl  0x10(%ebx)
f010311d:	89 f8                	mov    %edi,%eax
f010311f:	03 43 04             	add    0x4(%ebx),%eax
f0103122:	50                   	push   %eax
f0103123:	ff 73 08             	pushl  0x8(%ebx)
f0103126:	e8 d6 1c 00 00       	call   f0104e01 <memcpy>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
f010312b:	8b 43 10             	mov    0x10(%ebx),%eax
f010312e:	83 c4 0c             	add    $0xc,%esp
f0103131:	8b 53 14             	mov    0x14(%ebx),%edx
f0103134:	29 c2                	sub    %eax,%edx
f0103136:	52                   	push   %edx
f0103137:	6a 00                	push   $0x0
f0103139:	03 43 08             	add    0x8(%ebx),%eax
f010313c:	50                   	push   %eax
f010313d:	e8 0a 1c 00 00       	call   f0104d4c <memset>
f0103142:	83 c4 10             	add    $0x10,%esp
	e->env_tf.tf_eip = ELFHDR->e_entry;

	
	
	
	for (; ph < eph; ph++)
f0103145:	83 c3 20             	add    $0x20,%ebx
f0103148:	39 de                	cmp    %ebx,%esi
f010314a:	77 9c                	ja     f01030e8 <env_create+0x98>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
	
}
	
   	region_alloc(e, (void *) USTACKTOP - PGSIZE, PGSIZE);
f010314c:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103151:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103156:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103159:	e8 be fb ff ff       	call   f0102d1c <region_alloc>

	lcr3(PADDR(kern_pgdir));
f010315e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103163:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103168:	77 15                	ja     f010317f <env_create+0x12f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010316a:	50                   	push   %eax
f010316b:	68 48 5a 10 f0       	push   $0xf0105a48
f0103170:	68 ac 01 00 00       	push   $0x1ac
f0103175:	68 1f 6c 10 f0       	push   $0xf0106c1f
f010317a:	e8 c1 ce ff ff       	call   f0100040 <_panic>
f010317f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103184:	0f 22 d8             	mov    %eax,%cr3
		panic("env_alloc: %e", check);
		return;
	}
	
	load_icode(env, binary);
	env->env_type = type;
f0103187:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010318a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010318d:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103190:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103193:	5b                   	pop    %ebx
f0103194:	5e                   	pop    %esi
f0103195:	5f                   	pop    %edi
f0103196:	5d                   	pop    %ebp
f0103197:	c3                   	ret    

f0103198 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103198:	55                   	push   %ebp
f0103199:	89 e5                	mov    %esp,%ebp
f010319b:	57                   	push   %edi
f010319c:	56                   	push   %esi
f010319d:	53                   	push   %ebx
f010319e:	83 ec 1c             	sub    $0x1c,%esp
f01031a1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031a4:	e8 c5 21 00 00       	call   f010536e <cpunum>
f01031a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01031ac:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031b2:	75 29                	jne    f01031dd <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031b4:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031b9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031be:	77 15                	ja     f01031d5 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031c0:	50                   	push   %eax
f01031c1:	68 48 5a 10 f0       	push   $0xf0105a48
f01031c6:	68 db 01 00 00       	push   $0x1db
f01031cb:	68 1f 6c 10 f0       	push   $0xf0106c1f
f01031d0:	e8 6b ce ff ff       	call   f0100040 <_panic>
f01031d5:	05 00 00 00 10       	add    $0x10000000,%eax
f01031da:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031dd:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031e0:	e8 89 21 00 00       	call   f010536e <cpunum>
f01031e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e8:	ba 00 00 00 00       	mov    $0x0,%edx
f01031ed:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01031f4:	74 11                	je     f0103207 <env_free+0x6f>
f01031f6:	e8 73 21 00 00       	call   f010536e <cpunum>
f01031fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01031fe:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103204:	8b 50 48             	mov    0x48(%eax),%edx
f0103207:	83 ec 04             	sub    $0x4,%esp
f010320a:	53                   	push   %ebx
f010320b:	52                   	push   %edx
f010320c:	68 86 6c 10 f0       	push   $0xf0106c86
f0103211:	e8 73 04 00 00       	call   f0103689 <cprintf>
f0103216:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103219:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103220:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103223:	89 d0                	mov    %edx,%eax
f0103225:	c1 e0 02             	shl    $0x2,%eax
f0103228:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010322b:	8b 47 60             	mov    0x60(%edi),%eax
f010322e:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103231:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103237:	0f 84 a8 00 00 00    	je     f01032e5 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010323d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103243:	89 f0                	mov    %esi,%eax
f0103245:	c1 e8 0c             	shr    $0xc,%eax
f0103248:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010324b:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f0103251:	77 15                	ja     f0103268 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103253:	56                   	push   %esi
f0103254:	68 24 5a 10 f0       	push   $0xf0105a24
f0103259:	68 ea 01 00 00       	push   $0x1ea
f010325e:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0103263:	e8 d8 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103268:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010326b:	c1 e0 16             	shl    $0x16,%eax
f010326e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103271:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103276:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010327d:	01 
f010327e:	74 17                	je     f0103297 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103280:	83 ec 08             	sub    $0x8,%esp
f0103283:	89 d8                	mov    %ebx,%eax
f0103285:	c1 e0 0c             	shl    $0xc,%eax
f0103288:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010328b:	50                   	push   %eax
f010328c:	ff 77 60             	pushl  0x60(%edi)
f010328f:	e8 bb de ff ff       	call   f010114f <page_remove>
f0103294:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103297:	83 c3 01             	add    $0x1,%ebx
f010329a:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032a0:	75 d4                	jne    f0103276 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032a2:	8b 47 60             	mov    0x60(%edi),%eax
f01032a5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032a8:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032af:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032b2:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032b8:	72 14                	jb     f01032ce <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032ba:	83 ec 04             	sub    $0x4,%esp
f01032bd:	68 b4 63 10 f0       	push   $0xf01063b4
f01032c2:	6a 51                	push   $0x51
f01032c4:	68 a0 5f 10 f0       	push   $0xf0105fa0
f01032c9:	e8 72 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032ce:	83 ec 0c             	sub    $0xc,%esp
f01032d1:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f01032d6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032d9:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032dc:	50                   	push   %eax
f01032dd:	e8 6f dc ff ff       	call   f0100f51 <page_decref>
f01032e2:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032e5:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032ec:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01032f1:	0f 85 29 ff ff ff    	jne    f0103220 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01032f7:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032fa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032ff:	77 15                	ja     f0103316 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103301:	50                   	push   %eax
f0103302:	68 48 5a 10 f0       	push   $0xf0105a48
f0103307:	68 f8 01 00 00       	push   $0x1f8
f010330c:	68 1f 6c 10 f0       	push   $0xf0106c1f
f0103311:	e8 2a cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103316:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010331d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103322:	c1 e8 0c             	shr    $0xc,%eax
f0103325:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010332b:	72 14                	jb     f0103341 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010332d:	83 ec 04             	sub    $0x4,%esp
f0103330:	68 b4 63 10 f0       	push   $0xf01063b4
f0103335:	6a 51                	push   $0x51
f0103337:	68 a0 5f 10 f0       	push   $0xf0105fa0
f010333c:	e8 ff cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103341:	83 ec 0c             	sub    $0xc,%esp
f0103344:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f010334a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010334d:	50                   	push   %eax
f010334e:	e8 fe db ff ff       	call   f0100f51 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103353:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010335a:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f010335f:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103362:	89 3d 48 a2 22 f0    	mov    %edi,0xf022a248
}
f0103368:	83 c4 10             	add    $0x10,%esp
f010336b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010336e:	5b                   	pop    %ebx
f010336f:	5e                   	pop    %esi
f0103370:	5f                   	pop    %edi
f0103371:	5d                   	pop    %ebp
f0103372:	c3                   	ret    

f0103373 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103373:	55                   	push   %ebp
f0103374:	89 e5                	mov    %esp,%ebp
f0103376:	53                   	push   %ebx
f0103377:	83 ec 04             	sub    $0x4,%esp
f010337a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010337d:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103381:	75 19                	jne    f010339c <env_destroy+0x29>
f0103383:	e8 e6 1f 00 00       	call   f010536e <cpunum>
f0103388:	6b c0 74             	imul   $0x74,%eax,%eax
f010338b:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0103391:	74 09                	je     f010339c <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103393:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f010339a:	eb 33                	jmp    f01033cf <env_destroy+0x5c>
	}

	env_free(e);
f010339c:	83 ec 0c             	sub    $0xc,%esp
f010339f:	53                   	push   %ebx
f01033a0:	e8 f3 fd ff ff       	call   f0103198 <env_free>

	if (curenv == e) {
f01033a5:	e8 c4 1f 00 00       	call   f010536e <cpunum>
f01033aa:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ad:	83 c4 10             	add    $0x10,%esp
f01033b0:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033b6:	75 17                	jne    f01033cf <env_destroy+0x5c>
		curenv = NULL;
f01033b8:	e8 b1 1f 00 00       	call   f010536e <cpunum>
f01033bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c0:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01033c7:	00 00 00 
		sched_yield();
f01033ca:	e8 0b 0d 00 00       	call   f01040da <sched_yield>
	}
}
f01033cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033d2:	c9                   	leave  
f01033d3:	c3                   	ret    

f01033d4 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033d4:	55                   	push   %ebp
f01033d5:	89 e5                	mov    %esp,%ebp
f01033d7:	53                   	push   %ebx
f01033d8:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033db:	e8 8e 1f 00 00       	call   f010536e <cpunum>
f01033e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e3:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f01033e9:	e8 80 1f 00 00       	call   f010536e <cpunum>
f01033ee:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f01033f1:	8b 65 08             	mov    0x8(%ebp),%esp
f01033f4:	61                   	popa   
f01033f5:	07                   	pop    %es
f01033f6:	1f                   	pop    %ds
f01033f7:	83 c4 08             	add    $0x8,%esp
f01033fa:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01033fb:	83 ec 04             	sub    $0x4,%esp
f01033fe:	68 9c 6c 10 f0       	push   $0xf0106c9c
f0103403:	68 2f 02 00 00       	push   $0x22f
f0103408:	68 1f 6c 10 f0       	push   $0xf0106c1f
f010340d:	e8 2e cc ff ff       	call   f0100040 <_panic>

f0103412 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103412:	55                   	push   %ebp
f0103413:	89 e5                	mov    %esp,%ebp
f0103415:	53                   	push   %ebx
f0103416:	83 ec 04             	sub    $0x4,%esp
f0103419:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// env_status : ENV_FREE, ENV_RUNNABLE, ENV_RUNNING, ENV_NOT_RUNNABLE

	if (curenv == NULL || curenv!= e) 
f010341c:	e8 4d 1f 00 00       	call   f010536e <cpunum>
f0103421:	6b c0 74             	imul   $0x74,%eax,%eax
f0103424:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010342b:	74 14                	je     f0103441 <env_run+0x2f>
f010342d:	e8 3c 1f 00 00       	call   f010536e <cpunum>
f0103432:	6b c0 74             	imul   $0x74,%eax,%eax
f0103435:	39 98 28 b0 22 f0    	cmp    %ebx,-0xfdd4fd8(%eax)
f010343b:	0f 84 a4 00 00 00    	je     f01034e5 <env_run+0xd3>
	{
		if (curenv && curenv->env_status == ENV_RUNNING)
f0103441:	e8 28 1f 00 00       	call   f010536e <cpunum>
f0103446:	6b c0 74             	imul   $0x74,%eax,%eax
f0103449:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103450:	74 29                	je     f010347b <env_run+0x69>
f0103452:	e8 17 1f 00 00       	call   f010536e <cpunum>
f0103457:	6b c0 74             	imul   $0x74,%eax,%eax
f010345a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103460:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103464:	75 15                	jne    f010347b <env_run+0x69>
			
			curenv->env_status = ENV_RUNNABLE;
f0103466:	e8 03 1f 00 00       	call   f010536e <cpunum>
f010346b:	6b c0 74             	imul   $0x74,%eax,%eax
f010346e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103474:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		curenv = e;
f010347b:	e8 ee 1e 00 00       	call   f010536e <cpunum>
f0103480:	6b c0 74             	imul   $0x74,%eax,%eax
f0103483:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	
		curenv->env_status = ENV_RUNNING;
f0103489:	e8 e0 1e 00 00       	call   f010536e <cpunum>
f010348e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103491:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103497:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		curenv->env_runs++;
f010349e:	e8 cb 1e 00 00       	call   f010536e <cpunum>
f01034a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01034a6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034ac:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f01034b0:	e8 b9 1e 00 00       	call   f010536e <cpunum>
f01034b5:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034be:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034c1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034c6:	77 15                	ja     f01034dd <env_run+0xcb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034c8:	50                   	push   %eax
f01034c9:	68 48 5a 10 f0       	push   $0xf0105a48
f01034ce:	68 58 02 00 00       	push   $0x258
f01034d3:	68 1f 6c 10 f0       	push   $0xf0106c1f
f01034d8:	e8 63 cb ff ff       	call   f0100040 <_panic>
f01034dd:	05 00 00 00 10       	add    $0x10000000,%eax
f01034e2:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034e5:	83 ec 0c             	sub    $0xc,%esp
f01034e8:	68 c0 f3 11 f0       	push   $0xf011f3c0
f01034ed:	e8 87 21 00 00       	call   f0105679 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034f2:	f3 90                	pause  
	}

	
	unlock_kernel();
	
	env_pop_tf(&(curenv->env_tf));
f01034f4:	e8 75 1e 00 00       	call   f010536e <cpunum>
f01034f9:	83 c4 04             	add    $0x4,%esp
f01034fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ff:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103505:	e8 ca fe ff ff       	call   f01033d4 <env_pop_tf>

f010350a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010350a:	55                   	push   %ebp
f010350b:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010350d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103512:	8b 45 08             	mov    0x8(%ebp),%eax
f0103515:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103516:	ba 71 00 00 00       	mov    $0x71,%edx
f010351b:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010351c:	0f b6 c0             	movzbl %al,%eax
}
f010351f:	5d                   	pop    %ebp
f0103520:	c3                   	ret    

f0103521 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103521:	55                   	push   %ebp
f0103522:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103524:	ba 70 00 00 00       	mov    $0x70,%edx
f0103529:	8b 45 08             	mov    0x8(%ebp),%eax
f010352c:	ee                   	out    %al,(%dx)
f010352d:	ba 71 00 00 00       	mov    $0x71,%edx
f0103532:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103535:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103536:	5d                   	pop    %ebp
f0103537:	c3                   	ret    

f0103538 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103538:	55                   	push   %ebp
f0103539:	89 e5                	mov    %esp,%ebp
f010353b:	56                   	push   %esi
f010353c:	53                   	push   %ebx
f010353d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103540:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103546:	80 3d 4c a2 22 f0 00 	cmpb   $0x0,0xf022a24c
f010354d:	74 5a                	je     f01035a9 <irq_setmask_8259A+0x71>
f010354f:	89 c6                	mov    %eax,%esi
f0103551:	ba 21 00 00 00       	mov    $0x21,%edx
f0103556:	ee                   	out    %al,(%dx)
f0103557:	66 c1 e8 08          	shr    $0x8,%ax
f010355b:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103560:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103561:	83 ec 0c             	sub    $0xc,%esp
f0103564:	68 a8 6c 10 f0       	push   $0xf0106ca8
f0103569:	e8 1b 01 00 00       	call   f0103689 <cprintf>
f010356e:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103571:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103576:	0f b7 f6             	movzwl %si,%esi
f0103579:	f7 d6                	not    %esi
f010357b:	0f a3 de             	bt     %ebx,%esi
f010357e:	73 11                	jae    f0103591 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103580:	83 ec 08             	sub    $0x8,%esp
f0103583:	53                   	push   %ebx
f0103584:	68 25 71 10 f0       	push   $0xf0107125
f0103589:	e8 fb 00 00 00       	call   f0103689 <cprintf>
f010358e:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103591:	83 c3 01             	add    $0x1,%ebx
f0103594:	83 fb 10             	cmp    $0x10,%ebx
f0103597:	75 e2                	jne    f010357b <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103599:	83 ec 0c             	sub    $0xc,%esp
f010359c:	68 70 6c 10 f0       	push   $0xf0106c70
f01035a1:	e8 e3 00 00 00       	call   f0103689 <cprintf>
f01035a6:	83 c4 10             	add    $0x10,%esp
}
f01035a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035ac:	5b                   	pop    %ebx
f01035ad:	5e                   	pop    %esi
f01035ae:	5d                   	pop    %ebp
f01035af:	c3                   	ret    

f01035b0 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035b0:	c6 05 4c a2 22 f0 01 	movb   $0x1,0xf022a24c
f01035b7:	ba 21 00 00 00       	mov    $0x21,%edx
f01035bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035c1:	ee                   	out    %al,(%dx)
f01035c2:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035c7:	ee                   	out    %al,(%dx)
f01035c8:	ba 20 00 00 00       	mov    $0x20,%edx
f01035cd:	b8 11 00 00 00       	mov    $0x11,%eax
f01035d2:	ee                   	out    %al,(%dx)
f01035d3:	ba 21 00 00 00       	mov    $0x21,%edx
f01035d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01035dd:	ee                   	out    %al,(%dx)
f01035de:	b8 04 00 00 00       	mov    $0x4,%eax
f01035e3:	ee                   	out    %al,(%dx)
f01035e4:	b8 03 00 00 00       	mov    $0x3,%eax
f01035e9:	ee                   	out    %al,(%dx)
f01035ea:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035ef:	b8 11 00 00 00       	mov    $0x11,%eax
f01035f4:	ee                   	out    %al,(%dx)
f01035f5:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035fa:	b8 28 00 00 00       	mov    $0x28,%eax
f01035ff:	ee                   	out    %al,(%dx)
f0103600:	b8 02 00 00 00       	mov    $0x2,%eax
f0103605:	ee                   	out    %al,(%dx)
f0103606:	b8 01 00 00 00       	mov    $0x1,%eax
f010360b:	ee                   	out    %al,(%dx)
f010360c:	ba 20 00 00 00       	mov    $0x20,%edx
f0103611:	b8 68 00 00 00       	mov    $0x68,%eax
f0103616:	ee                   	out    %al,(%dx)
f0103617:	b8 0a 00 00 00       	mov    $0xa,%eax
f010361c:	ee                   	out    %al,(%dx)
f010361d:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103622:	b8 68 00 00 00       	mov    $0x68,%eax
f0103627:	ee                   	out    %al,(%dx)
f0103628:	b8 0a 00 00 00       	mov    $0xa,%eax
f010362d:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f010362e:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103635:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103639:	74 13                	je     f010364e <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010363b:	55                   	push   %ebp
f010363c:	89 e5                	mov    %esp,%ebp
f010363e:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103641:	0f b7 c0             	movzwl %ax,%eax
f0103644:	50                   	push   %eax
f0103645:	e8 ee fe ff ff       	call   f0103538 <irq_setmask_8259A>
f010364a:	83 c4 10             	add    $0x10,%esp
}
f010364d:	c9                   	leave  
f010364e:	f3 c3                	repz ret 

f0103650 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103650:	55                   	push   %ebp
f0103651:	89 e5                	mov    %esp,%ebp
f0103653:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103656:	ff 75 08             	pushl  0x8(%ebp)
f0103659:	e8 06 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f010365e:	83 c4 10             	add    $0x10,%esp
f0103661:	c9                   	leave  
f0103662:	c3                   	ret    

f0103663 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103663:	55                   	push   %ebp
f0103664:	89 e5                	mov    %esp,%ebp
f0103666:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103669:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103670:	ff 75 0c             	pushl  0xc(%ebp)
f0103673:	ff 75 08             	pushl  0x8(%ebp)
f0103676:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103679:	50                   	push   %eax
f010367a:	68 50 36 10 f0       	push   $0xf0103650
f010367f:	e8 a3 0f 00 00       	call   f0104627 <vprintfmt>
	return cnt;
}
f0103684:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103687:	c9                   	leave  
f0103688:	c3                   	ret    

f0103689 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103689:	55                   	push   %ebp
f010368a:	89 e5                	mov    %esp,%ebp
f010368c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010368f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103692:	50                   	push   %eax
f0103693:	ff 75 08             	pushl  0x8(%ebp)
f0103696:	e8 c8 ff ff ff       	call   f0103663 <vcprintf>
	va_end(ap);

	return cnt;
}
f010369b:	c9                   	leave  
f010369c:	c3                   	ret    

f010369d <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010369d:	55                   	push   %ebp
f010369e:	89 e5                	mov    %esp,%ebp
f01036a0:	57                   	push   %edi
f01036a1:	56                   	push   %esi
f01036a2:	53                   	push   %ebx
f01036a3:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint32_t i = thiscpu->cpu_id;
f01036a6:	e8 c3 1c 00 00       	call   f010536e <cpunum>
f01036ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ae:	0f b6 b0 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%esi
f01036b5:	89 f0                	mov    %esi,%eax
f01036b7:	0f b6 d8             	movzbl %al,%ebx
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
f01036ba:	e8 af 1c 00 00       	call   f010536e <cpunum>
f01036bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c2:	89 da                	mov    %ebx,%edx
f01036c4:	f7 da                	neg    %edx
f01036c6:	c1 e2 10             	shl    $0x10,%edx
f01036c9:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01036cf:	89 90 30 b0 22 f0    	mov    %edx,-0xfdd4fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036d5:	e8 94 1c 00 00       	call   f010536e <cpunum>
f01036da:	6b c0 74             	imul   $0x74,%eax,%eax
f01036dd:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036e4:	10 00 

	// Initialize the TSS slot of the gdt.

	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t)&thiscpu->cpu_ts,
f01036e6:	83 c3 05             	add    $0x5,%ebx
f01036e9:	e8 80 1c 00 00       	call   f010536e <cpunum>
f01036ee:	89 c7                	mov    %eax,%edi
f01036f0:	e8 79 1c 00 00       	call   f010536e <cpunum>
f01036f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036f8:	e8 71 1c 00 00       	call   f010536e <cpunum>
f01036fd:	66 c7 04 dd 40 f3 11 	movw   $0x68,-0xfee0cc0(,%ebx,8)
f0103704:	f0 68 00 
f0103707:	6b ff 74             	imul   $0x74,%edi,%edi
f010370a:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f0103710:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103717:	f0 
f0103718:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f010371c:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f0103722:	c1 ea 10             	shr    $0x10,%edx
f0103725:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f010372c:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103733:	40 
f0103734:	6b c0 74             	imul   $0x74,%eax,%eax
f0103737:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010373c:	c1 e8 18             	shr    $0x18,%eax
f010373f:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
						sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f0103746:	c6 04 dd 45 f3 11 f0 	movb   $0x89,-0xfee0cbb(,%ebx,8)
f010374d:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010374e:	89 f0                	mov    %esi,%eax
f0103750:	0f b6 f0             	movzbl %al,%esi
f0103753:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f010375a:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010375d:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103762:	0f 01 18             	lidtl  (%eax)
f0103765:	0f 01 18             	lidtl  (%eax)
	ltr(GD_TSS0 + (i << 3) );
	lidt(&idt_pd);

	// Load the IDT
	lidt(&idt_pd);
}
f0103768:	83 c4 1c             	add    $0x1c,%esp
f010376b:	5b                   	pop    %ebx
f010376c:	5e                   	pop    %esi
f010376d:	5f                   	pop    %edi
f010376e:	5d                   	pop    %ebp
f010376f:	c3                   	ret    

f0103770 <trap_init>:
}


void
trap_init(void)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE],0,GD_KT,divide_zero,DPLKERN);    //CSS=kernel text
f0103776:	b8 46 3f 10 f0       	mov    $0xf0103f46,%eax
f010377b:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f0103781:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f0103788:	08 00 
f010378a:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f0103791:	c6 05 65 a2 22 f0 8e 	movb   $0x8e,0xf022a265
f0103798:	c1 e8 10             	shr    $0x10,%eax
f010379b:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
    SETGATE(idt[T_BRKPT],0,GD_KT,brkpoint,DPLUSR);
f01037a1:	b8 50 3f 10 f0       	mov    $0xf0103f50,%eax
f01037a6:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f01037ac:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f01037b3:	08 00 
f01037b5:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f01037bc:	c6 05 7d a2 22 f0 ee 	movb   $0xee,0xf022a27d
f01037c3:	c1 e8 10             	shr    $0x10,%eax
f01037c6:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
    SETGATE(idt[T_SEGNP],0,GD_KT,no_seg,DPLKERN);
f01037cc:	b8 5a 3f 10 f0       	mov    $0xf0103f5a,%eax
f01037d1:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f01037d7:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f01037de:	08 00 
f01037e0:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f01037e7:	c6 05 bd a2 22 f0 8e 	movb   $0x8e,0xf022a2bd
f01037ee:	c1 e8 10             	shr    $0x10,%eax
f01037f1:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
    SETGATE(idt[T_DEBUG],0,GD_KT,debug,DPLKERN);
f01037f7:	b8 62 3f 10 f0       	mov    $0xf0103f62,%eax
f01037fc:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f0103802:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f0103809:	08 00 
f010380b:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f0103812:	c6 05 6d a2 22 f0 8e 	movb   $0x8e,0xf022a26d
f0103819:	c1 e8 10             	shr    $0x10,%eax
f010381c:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
    SETGATE(idt[T_NMI],0,GD_KT,nmi,DPLKERN);
f0103822:	b8 6c 3f 10 f0       	mov    $0xf0103f6c,%eax
f0103827:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f010382d:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f0103834:	08 00 
f0103836:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f010383d:	c6 05 75 a2 22 f0 8e 	movb   $0x8e,0xf022a275
f0103844:	c1 e8 10             	shr    $0x10,%eax
f0103847:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
    SETGATE(idt[T_OFLOW],0,GD_KT,oflow,DPLKERN);
f010384d:	b8 76 3f 10 f0       	mov    $0xf0103f76,%eax
f0103852:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103858:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f010385f:	08 00 
f0103861:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103868:	c6 05 85 a2 22 f0 8e 	movb   $0x8e,0xf022a285
f010386f:	c1 e8 10             	shr    $0x10,%eax
f0103872:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
    SETGATE(idt[T_BOUND],0,GD_KT,bound,DPLKERN);
f0103878:	b8 80 3f 10 f0       	mov    $0xf0103f80,%eax
f010387d:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f0103883:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f010388a:	08 00 
f010388c:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f0103893:	c6 05 8d a2 22 f0 8e 	movb   $0x8e,0xf022a28d
f010389a:	c1 e8 10             	shr    $0x10,%eax
f010389d:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
    SETGATE(idt[T_ILLOP],0,GD_KT,illop,DPLKERN);
f01038a3:	b8 8a 3f 10 f0       	mov    $0xf0103f8a,%eax
f01038a8:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f01038ae:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f01038b5:	08 00 
f01038b7:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01038be:	c6 05 95 a2 22 f0 8e 	movb   $0x8e,0xf022a295
f01038c5:	c1 e8 10             	shr    $0x10,%eax
f01038c8:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
    SETGATE(idt[T_DEVICE],0,GD_KT,device,DPLKERN);
f01038ce:	b8 94 3f 10 f0       	mov    $0xf0103f94,%eax
f01038d3:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01038d9:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038e0:	08 00 
f01038e2:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01038e9:	c6 05 9d a2 22 f0 8e 	movb   $0x8e,0xf022a29d
f01038f0:	c1 e8 10             	shr    $0x10,%eax
f01038f3:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
    SETGATE(idt[T_DBLFLT],0,GD_KT,dblflt,DPLKERN);
f01038f9:	b8 9e 3f 10 f0       	mov    $0xf0103f9e,%eax
f01038fe:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f0103904:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f010390b:	08 00 
f010390d:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f0103914:	c6 05 a5 a2 22 f0 8e 	movb   $0x8e,0xf022a2a5
f010391b:	c1 e8 10             	shr    $0x10,%eax
f010391e:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6
    SETGATE(idt[T_TSS], 0, GD_KT, tss, DPLKERN);
f0103924:	b8 a6 3f 10 f0       	mov    $0xf0103fa6,%eax
f0103929:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f010392f:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f0103936:	08 00 
f0103938:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f010393f:	c6 05 b5 a2 22 f0 8e 	movb   $0x8e,0xf022a2b5
f0103946:	c1 e8 10             	shr    $0x10,%eax
f0103949:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
    SETGATE(idt[T_STACK], 0, GD_KT, stack, DPLKERN);
f010394f:	b8 ae 3f 10 f0       	mov    $0xf0103fae,%eax
f0103954:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f010395a:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103961:	08 00 
f0103963:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f010396a:	c6 05 c5 a2 22 f0 8e 	movb   $0x8e,0xf022a2c5
f0103971:	c1 e8 10             	shr    $0x10,%eax
f0103974:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
    SETGATE(idt[T_GPFLT], 0, GD_KT, gpflt, DPLKERN);
f010397a:	b8 b6 3f 10 f0       	mov    $0xf0103fb6,%eax
f010397f:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0103985:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f010398c:	08 00 
f010398e:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f0103995:	c6 05 cd a2 22 f0 8e 	movb   $0x8e,0xf022a2cd
f010399c:	c1 e8 10             	shr    $0x10,%eax
f010399f:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
    SETGATE(idt[T_PGFLT], 0, GD_KT, pgflt, DPLKERN);
f01039a5:	b8 be 3f 10 f0       	mov    $0xf0103fbe,%eax
f01039aa:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01039b0:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039b7:	08 00 
f01039b9:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01039c0:	c6 05 d5 a2 22 f0 8e 	movb   $0x8e,0xf022a2d5
f01039c7:	c1 e8 10             	shr    $0x10,%eax
f01039ca:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6
    SETGATE(idt[T_FPERR], 0, GD_KT, fperr, DPLKERN);
f01039d0:	b8 c6 3f 10 f0       	mov    $0xf0103fc6,%eax
f01039d5:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039db:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039e2:	08 00 
f01039e4:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039eb:	c6 05 e5 a2 22 f0 8e 	movb   $0x8e,0xf022a2e5
f01039f2:	c1 e8 10             	shr    $0x10,%eax
f01039f5:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6
    SETGATE(idt[T_ALIGN], 0, GD_KT, align, DPLKERN);
f01039fb:	b8 d0 3f 10 f0       	mov    $0xf0103fd0,%eax
f0103a00:	66 a3 e8 a2 22 f0    	mov    %ax,0xf022a2e8
f0103a06:	66 c7 05 ea a2 22 f0 	movw   $0x8,0xf022a2ea
f0103a0d:	08 00 
f0103a0f:	c6 05 ec a2 22 f0 00 	movb   $0x0,0xf022a2ec
f0103a16:	c6 05 ed a2 22 f0 8e 	movb   $0x8e,0xf022a2ed
f0103a1d:	c1 e8 10             	shr    $0x10,%eax
f0103a20:	66 a3 ee a2 22 f0    	mov    %ax,0xf022a2ee
    SETGATE(idt[T_MCHK], 0, GD_KT, mchk, DPLKERN);
f0103a26:	b8 d8 3f 10 f0       	mov    $0xf0103fd8,%eax
f0103a2b:	66 a3 f0 a2 22 f0    	mov    %ax,0xf022a2f0
f0103a31:	66 c7 05 f2 a2 22 f0 	movw   $0x8,0xf022a2f2
f0103a38:	08 00 
f0103a3a:	c6 05 f4 a2 22 f0 00 	movb   $0x0,0xf022a2f4
f0103a41:	c6 05 f5 a2 22 f0 8e 	movb   $0x8e,0xf022a2f5
f0103a48:	c1 e8 10             	shr    $0x10,%eax
f0103a4b:	66 a3 f6 a2 22 f0    	mov    %ax,0xf022a2f6
    SETGATE(idt[T_SIMDERR], 0, GD_KT, simderr, DPLKERN);
f0103a51:	b8 e2 3f 10 f0       	mov    $0xf0103fe2,%eax
f0103a56:	66 a3 f8 a2 22 f0    	mov    %ax,0xf022a2f8
f0103a5c:	66 c7 05 fa a2 22 f0 	movw   $0x8,0xf022a2fa
f0103a63:	08 00 
f0103a65:	c6 05 fc a2 22 f0 00 	movb   $0x0,0xf022a2fc
f0103a6c:	c6 05 fd a2 22 f0 8e 	movb   $0x8e,0xf022a2fd
f0103a73:	c1 e8 10             	shr    $0x10,%eax
f0103a76:	66 a3 fe a2 22 f0    	mov    %ax,0xf022a2fe


    SETGATE(idt[T_SYSCALL], 0, GD_KT, syscalls, DPLUSR);
f0103a7c:	b8 ec 3f 10 f0       	mov    $0xf0103fec,%eax
f0103a81:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a87:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a8e:	08 00 
f0103a90:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a97:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a9e:	c1 e8 10             	shr    $0x10,%eax
f0103aa1:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6



	// Per-CPU setup 
	trap_init_percpu();
f0103aa7:	e8 f1 fb ff ff       	call   f010369d <trap_init_percpu>
}
f0103aac:	c9                   	leave  
f0103aad:	c3                   	ret    

f0103aae <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103aae:	55                   	push   %ebp
f0103aaf:	89 e5                	mov    %esp,%ebp
f0103ab1:	53                   	push   %ebx
f0103ab2:	83 ec 0c             	sub    $0xc,%esp
f0103ab5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103ab8:	ff 33                	pushl  (%ebx)
f0103aba:	68 bc 6c 10 f0       	push   $0xf0106cbc
f0103abf:	e8 c5 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ac4:	83 c4 08             	add    $0x8,%esp
f0103ac7:	ff 73 04             	pushl  0x4(%ebx)
f0103aca:	68 cb 6c 10 f0       	push   $0xf0106ccb
f0103acf:	e8 b5 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ad4:	83 c4 08             	add    $0x8,%esp
f0103ad7:	ff 73 08             	pushl  0x8(%ebx)
f0103ada:	68 da 6c 10 f0       	push   $0xf0106cda
f0103adf:	e8 a5 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103ae4:	83 c4 08             	add    $0x8,%esp
f0103ae7:	ff 73 0c             	pushl  0xc(%ebx)
f0103aea:	68 e9 6c 10 f0       	push   $0xf0106ce9
f0103aef:	e8 95 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103af4:	83 c4 08             	add    $0x8,%esp
f0103af7:	ff 73 10             	pushl  0x10(%ebx)
f0103afa:	68 f8 6c 10 f0       	push   $0xf0106cf8
f0103aff:	e8 85 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b04:	83 c4 08             	add    $0x8,%esp
f0103b07:	ff 73 14             	pushl  0x14(%ebx)
f0103b0a:	68 07 6d 10 f0       	push   $0xf0106d07
f0103b0f:	e8 75 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b14:	83 c4 08             	add    $0x8,%esp
f0103b17:	ff 73 18             	pushl  0x18(%ebx)
f0103b1a:	68 16 6d 10 f0       	push   $0xf0106d16
f0103b1f:	e8 65 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b24:	83 c4 08             	add    $0x8,%esp
f0103b27:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b2a:	68 25 6d 10 f0       	push   $0xf0106d25
f0103b2f:	e8 55 fb ff ff       	call   f0103689 <cprintf>
}
f0103b34:	83 c4 10             	add    $0x10,%esp
f0103b37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b3a:	c9                   	leave  
f0103b3b:	c3                   	ret    

f0103b3c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b3c:	55                   	push   %ebp
f0103b3d:	89 e5                	mov    %esp,%ebp
f0103b3f:	56                   	push   %esi
f0103b40:	53                   	push   %ebx
f0103b41:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b44:	e8 25 18 00 00       	call   f010536e <cpunum>
f0103b49:	83 ec 04             	sub    $0x4,%esp
f0103b4c:	50                   	push   %eax
f0103b4d:	53                   	push   %ebx
f0103b4e:	68 89 6d 10 f0       	push   $0xf0106d89
f0103b53:	e8 31 fb ff ff       	call   f0103689 <cprintf>
	print_regs(&tf->tf_regs);
f0103b58:	89 1c 24             	mov    %ebx,(%esp)
f0103b5b:	e8 4e ff ff ff       	call   f0103aae <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b60:	83 c4 08             	add    $0x8,%esp
f0103b63:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b67:	50                   	push   %eax
f0103b68:	68 a7 6d 10 f0       	push   $0xf0106da7
f0103b6d:	e8 17 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b72:	83 c4 08             	add    $0x8,%esp
f0103b75:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b79:	50                   	push   %eax
f0103b7a:	68 ba 6d 10 f0       	push   $0xf0106dba
f0103b7f:	e8 05 fb ff ff       	call   f0103689 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b84:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103b87:	83 c4 10             	add    $0x10,%esp
f0103b8a:	83 f8 13             	cmp    $0x13,%eax
f0103b8d:	77 09                	ja     f0103b98 <print_trapframe+0x5c>
		return excnames[trapno];
f0103b8f:	8b 14 85 40 70 10 f0 	mov    -0xfef8fc0(,%eax,4),%edx
f0103b96:	eb 1f                	jmp    f0103bb7 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b98:	83 f8 30             	cmp    $0x30,%eax
f0103b9b:	74 15                	je     f0103bb2 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b9d:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ba0:	83 fa 10             	cmp    $0x10,%edx
f0103ba3:	b9 53 6d 10 f0       	mov    $0xf0106d53,%ecx
f0103ba8:	ba 40 6d 10 f0       	mov    $0xf0106d40,%edx
f0103bad:	0f 43 d1             	cmovae %ecx,%edx
f0103bb0:	eb 05                	jmp    f0103bb7 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103bb2:	ba 34 6d 10 f0       	mov    $0xf0106d34,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bb7:	83 ec 04             	sub    $0x4,%esp
f0103bba:	52                   	push   %edx
f0103bbb:	50                   	push   %eax
f0103bbc:	68 cd 6d 10 f0       	push   $0xf0106dcd
f0103bc1:	e8 c3 fa ff ff       	call   f0103689 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bc6:	83 c4 10             	add    $0x10,%esp
f0103bc9:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103bcf:	75 1a                	jne    f0103beb <print_trapframe+0xaf>
f0103bd1:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bd5:	75 14                	jne    f0103beb <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103bd7:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103bda:	83 ec 08             	sub    $0x8,%esp
f0103bdd:	50                   	push   %eax
f0103bde:	68 df 6d 10 f0       	push   $0xf0106ddf
f0103be3:	e8 a1 fa ff ff       	call   f0103689 <cprintf>
f0103be8:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103beb:	83 ec 08             	sub    $0x8,%esp
f0103bee:	ff 73 2c             	pushl  0x2c(%ebx)
f0103bf1:	68 ee 6d 10 f0       	push   $0xf0106dee
f0103bf6:	e8 8e fa ff ff       	call   f0103689 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bfb:	83 c4 10             	add    $0x10,%esp
f0103bfe:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c02:	75 49                	jne    f0103c4d <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c04:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c07:	89 c2                	mov    %eax,%edx
f0103c09:	83 e2 01             	and    $0x1,%edx
f0103c0c:	ba 6d 6d 10 f0       	mov    $0xf0106d6d,%edx
f0103c11:	b9 62 6d 10 f0       	mov    $0xf0106d62,%ecx
f0103c16:	0f 44 ca             	cmove  %edx,%ecx
f0103c19:	89 c2                	mov    %eax,%edx
f0103c1b:	83 e2 02             	and    $0x2,%edx
f0103c1e:	ba 7f 6d 10 f0       	mov    $0xf0106d7f,%edx
f0103c23:	be 79 6d 10 f0       	mov    $0xf0106d79,%esi
f0103c28:	0f 45 d6             	cmovne %esi,%edx
f0103c2b:	83 e0 04             	and    $0x4,%eax
f0103c2e:	be d0 6e 10 f0       	mov    $0xf0106ed0,%esi
f0103c33:	b8 84 6d 10 f0       	mov    $0xf0106d84,%eax
f0103c38:	0f 44 c6             	cmove  %esi,%eax
f0103c3b:	51                   	push   %ecx
f0103c3c:	52                   	push   %edx
f0103c3d:	50                   	push   %eax
f0103c3e:	68 fc 6d 10 f0       	push   $0xf0106dfc
f0103c43:	e8 41 fa ff ff       	call   f0103689 <cprintf>
f0103c48:	83 c4 10             	add    $0x10,%esp
f0103c4b:	eb 10                	jmp    f0103c5d <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c4d:	83 ec 0c             	sub    $0xc,%esp
f0103c50:	68 70 6c 10 f0       	push   $0xf0106c70
f0103c55:	e8 2f fa ff ff       	call   f0103689 <cprintf>
f0103c5a:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c5d:	83 ec 08             	sub    $0x8,%esp
f0103c60:	ff 73 30             	pushl  0x30(%ebx)
f0103c63:	68 0b 6e 10 f0       	push   $0xf0106e0b
f0103c68:	e8 1c fa ff ff       	call   f0103689 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c6d:	83 c4 08             	add    $0x8,%esp
f0103c70:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c74:	50                   	push   %eax
f0103c75:	68 1a 6e 10 f0       	push   $0xf0106e1a
f0103c7a:	e8 0a fa ff ff       	call   f0103689 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c7f:	83 c4 08             	add    $0x8,%esp
f0103c82:	ff 73 38             	pushl  0x38(%ebx)
f0103c85:	68 2d 6e 10 f0       	push   $0xf0106e2d
f0103c8a:	e8 fa f9 ff ff       	call   f0103689 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c8f:	83 c4 10             	add    $0x10,%esp
f0103c92:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c96:	74 25                	je     f0103cbd <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c98:	83 ec 08             	sub    $0x8,%esp
f0103c9b:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c9e:	68 3c 6e 10 f0       	push   $0xf0106e3c
f0103ca3:	e8 e1 f9 ff ff       	call   f0103689 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ca8:	83 c4 08             	add    $0x8,%esp
f0103cab:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103caf:	50                   	push   %eax
f0103cb0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0103cb5:	e8 cf f9 ff ff       	call   f0103689 <cprintf>
f0103cba:	83 c4 10             	add    $0x10,%esp
	}
}
f0103cbd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103cc0:	5b                   	pop    %ebx
f0103cc1:	5e                   	pop    %esi
f0103cc2:	5d                   	pop    %ebp
f0103cc3:	c3                   	ret    

f0103cc4 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cc4:	55                   	push   %ebp
f0103cc5:	89 e5                	mov    %esp,%ebp
f0103cc7:	57                   	push   %edi
f0103cc8:	56                   	push   %esi
f0103cc9:	53                   	push   %ebx
f0103cca:	83 ec 0c             	sub    $0xc,%esp
f0103ccd:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cd0:	0f 20 d6             	mov    %cr2,%esi

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	if((tf->tf_cs & 3)==0)
f0103cd3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cd7:	75 17                	jne    f0103cf0 <page_fault_handler+0x2c>
	    panic("page fault kernel mode");
f0103cd9:	83 ec 04             	sub    $0x4,%esp
f0103cdc:	68 5e 6e 10 f0       	push   $0xf0106e5e
f0103ce1:	68 63 01 00 00       	push   $0x163
f0103ce6:	68 75 6e 10 f0       	push   $0xf0106e75
f0103ceb:	e8 50 c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cf0:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cf3:	e8 76 16 00 00       	call   f010536e <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cf8:	57                   	push   %edi
f0103cf9:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cfa:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cfd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d03:	ff 70 48             	pushl  0x48(%eax)
f0103d06:	68 1c 70 10 f0       	push   $0xf010701c
f0103d0b:	e8 79 f9 ff ff       	call   f0103689 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103d10:	89 1c 24             	mov    %ebx,(%esp)
f0103d13:	e8 24 fe ff ff       	call   f0103b3c <print_trapframe>
	env_destroy(curenv);
f0103d18:	e8 51 16 00 00       	call   f010536e <cpunum>
f0103d1d:	83 c4 04             	add    $0x4,%esp
f0103d20:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d23:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d29:	e8 45 f6 ff ff       	call   f0103373 <env_destroy>
}
f0103d2e:	83 c4 10             	add    $0x10,%esp
f0103d31:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d34:	5b                   	pop    %ebx
f0103d35:	5e                   	pop    %esi
f0103d36:	5f                   	pop    %edi
f0103d37:	5d                   	pop    %ebp
f0103d38:	c3                   	ret    

f0103d39 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d39:	55                   	push   %ebp
f0103d3a:	89 e5                	mov    %esp,%ebp
f0103d3c:	57                   	push   %edi
f0103d3d:	56                   	push   %esi
f0103d3e:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d41:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d42:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103d49:	74 01                	je     f0103d4c <trap+0x13>
		asm volatile("hlt");
f0103d4b:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d4c:	e8 1d 16 00 00       	call   f010536e <cpunum>
f0103d51:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d54:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103d5a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d5f:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d63:	83 f8 02             	cmp    $0x2,%eax
f0103d66:	75 10                	jne    f0103d78 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d68:	83 ec 0c             	sub    $0xc,%esp
f0103d6b:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d70:	e8 67 18 00 00       	call   f01055dc <spin_lock>
f0103d75:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103d78:	9c                   	pushf  
f0103d79:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d7a:	f6 c4 02             	test   $0x2,%ah
f0103d7d:	74 19                	je     f0103d98 <trap+0x5f>
f0103d7f:	68 81 6e 10 f0       	push   $0xf0106e81
f0103d84:	68 ba 5f 10 f0       	push   $0xf0105fba
f0103d89:	68 2f 01 00 00       	push   $0x12f
f0103d8e:	68 75 6e 10 f0       	push   $0xf0106e75
f0103d93:	e8 a8 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d98:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d9c:	83 e0 03             	and    $0x3,%eax
f0103d9f:	66 83 f8 03          	cmp    $0x3,%ax
f0103da3:	0f 85 a0 00 00 00    	jne    f0103e49 <trap+0x110>
f0103da9:	83 ec 0c             	sub    $0xc,%esp
f0103dac:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103db1:	e8 26 18 00 00       	call   f01055dc <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103db6:	e8 b3 15 00 00       	call   f010536e <cpunum>
f0103dbb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbe:	83 c4 10             	add    $0x10,%esp
f0103dc1:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103dc8:	75 19                	jne    f0103de3 <trap+0xaa>
f0103dca:	68 9a 6e 10 f0       	push   $0xf0106e9a
f0103dcf:	68 ba 5f 10 f0       	push   $0xf0105fba
f0103dd4:	68 37 01 00 00       	push   $0x137
f0103dd9:	68 75 6e 10 f0       	push   $0xf0106e75
f0103dde:	e8 5d c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103de3:	e8 86 15 00 00       	call   f010536e <cpunum>
f0103de8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103deb:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103df1:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103df5:	75 2d                	jne    f0103e24 <trap+0xeb>
			env_free(curenv);
f0103df7:	e8 72 15 00 00       	call   f010536e <cpunum>
f0103dfc:	83 ec 0c             	sub    $0xc,%esp
f0103dff:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e02:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e08:	e8 8b f3 ff ff       	call   f0103198 <env_free>
			curenv = NULL;
f0103e0d:	e8 5c 15 00 00       	call   f010536e <cpunum>
f0103e12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e15:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103e1c:	00 00 00 
			sched_yield();
f0103e1f:	e8 b6 02 00 00       	call   f01040da <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103e24:	e8 45 15 00 00       	call   f010536e <cpunum>
f0103e29:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103e32:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e37:	89 c7                	mov    %eax,%edi
f0103e39:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e3b:	e8 2e 15 00 00       	call   f010536e <cpunum>
f0103e40:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e43:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e49:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
{
	int rval=0;
		//cprintf("error interruot %x\n", tf->tf_err);
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==14)
f0103e4f:	8b 46 28             	mov    0x28(%esi),%eax
f0103e52:	83 f8 0e             	cmp    $0xe,%eax
f0103e55:	75 11                	jne    f0103e68 <trap+0x12f>
       {
        page_fault_handler(tf);
f0103e57:	83 ec 0c             	sub    $0xc,%esp
f0103e5a:	56                   	push   %esi
f0103e5b:	e8 64 fe ff ff       	call   f0103cc4 <page_fault_handler>
f0103e60:	83 c4 10             	add    $0x10,%esp
f0103e63:	e9 9e 00 00 00       	jmp    f0103f06 <trap+0x1cd>
        return;
	}
	
	if(tf->tf_trapno==3)
f0103e68:	83 f8 03             	cmp    $0x3,%eax
f0103e6b:	75 11                	jne    f0103e7e <trap+0x145>
	{
	monitor(tf);
f0103e6d:	83 ec 0c             	sub    $0xc,%esp
f0103e70:	56                   	push   %esi
f0103e71:	e8 85 ca ff ff       	call   f01008fb <monitor>
f0103e76:	83 c4 10             	add    $0x10,%esp
f0103e79:	e9 88 00 00 00       	jmp    f0103f06 <trap+0x1cd>
	return;	
		
	}
	
	if(tf->tf_trapno==T_SYSCALL)
f0103e7e:	83 f8 30             	cmp    $0x30,%eax
f0103e81:	75 21                	jne    f0103ea4 <trap+0x16b>
	{
	rval= syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103e83:	83 ec 08             	sub    $0x8,%esp
f0103e86:	ff 76 04             	pushl  0x4(%esi)
f0103e89:	ff 36                	pushl  (%esi)
f0103e8b:	ff 76 10             	pushl  0x10(%esi)
f0103e8e:	ff 76 18             	pushl  0x18(%esi)
f0103e91:	ff 76 14             	pushl  0x14(%esi)
f0103e94:	ff 76 1c             	pushl  0x1c(%esi)
f0103e97:	e8 4b 02 00 00       	call   f01040e7 <syscall>
	tf->tf_regs.reg_eax = rval;
f0103e9c:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e9f:	83 c4 20             	add    $0x20,%esp
f0103ea2:	eb 62                	jmp    f0103f06 <trap+0x1cd>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103ea4:	83 f8 27             	cmp    $0x27,%eax
f0103ea7:	75 1a                	jne    f0103ec3 <trap+0x18a>
		cprintf("Spurious interrupt on irq 7\n");
f0103ea9:	83 ec 0c             	sub    $0xc,%esp
f0103eac:	68 a1 6e 10 f0       	push   $0xf0106ea1
f0103eb1:	e8 d3 f7 ff ff       	call   f0103689 <cprintf>
		print_trapframe(tf);
f0103eb6:	89 34 24             	mov    %esi,(%esp)
f0103eb9:	e8 7e fc ff ff       	call   f0103b3c <print_trapframe>
f0103ebe:	83 c4 10             	add    $0x10,%esp
f0103ec1:	eb 43                	jmp    f0103f06 <trap+0x1cd>


        

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103ec3:	83 ec 0c             	sub    $0xc,%esp
f0103ec6:	56                   	push   %esi
f0103ec7:	e8 70 fc ff ff       	call   f0103b3c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103ecc:	83 c4 10             	add    $0x10,%esp
f0103ecf:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ed4:	75 17                	jne    f0103eed <trap+0x1b4>
		panic("unhandled trap in kernel");
f0103ed6:	83 ec 04             	sub    $0x4,%esp
f0103ed9:	68 be 6e 10 f0       	push   $0xf0106ebe
f0103ede:	68 15 01 00 00       	push   $0x115
f0103ee3:	68 75 6e 10 f0       	push   $0xf0106e75
f0103ee8:	e8 53 c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103eed:	e8 7c 14 00 00       	call   f010536e <cpunum>
f0103ef2:	83 ec 0c             	sub    $0xc,%esp
f0103ef5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef8:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103efe:	e8 70 f4 ff ff       	call   f0103373 <env_destroy>
f0103f03:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103f06:	e8 63 14 00 00       	call   f010536e <cpunum>
f0103f0b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0e:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103f15:	74 2a                	je     f0103f41 <trap+0x208>
f0103f17:	e8 52 14 00 00       	call   f010536e <cpunum>
f0103f1c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103f25:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f29:	75 16                	jne    f0103f41 <trap+0x208>
		env_run(curenv);
f0103f2b:	e8 3e 14 00 00       	call   f010536e <cpunum>
f0103f30:	83 ec 0c             	sub    $0xc,%esp
f0103f33:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f36:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103f3c:	e8 d1 f4 ff ff       	call   f0103412 <env_run>
	else
		sched_yield();
f0103f41:	e8 94 01 00 00       	call   f01040da <sched_yield>

f0103f46 <divide_zero>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide_zero,T_DIVIDE)
f0103f46:	6a 00                	push   $0x0
f0103f48:	6a 00                	push   $0x0
f0103f4a:	e9 a6 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f4f:	90                   	nop

f0103f50 <brkpoint>:
TRAPHANDLER_NOEC(brkpoint,T_BRKPT)
f0103f50:	6a 00                	push   $0x0
f0103f52:	6a 03                	push   $0x3
f0103f54:	e9 9c 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f59:	90                   	nop

f0103f5a <no_seg>:
TRAPHANDLER(no_seg,T_SEGNP)
f0103f5a:	6a 0b                	push   $0xb
f0103f5c:	e9 94 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f61:	90                   	nop

f0103f62 <debug>:
TRAPHANDLER_NOEC(debug,T_DEBUG)
f0103f62:	6a 00                	push   $0x0
f0103f64:	6a 01                	push   $0x1
f0103f66:	e9 8a 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f6b:	90                   	nop

f0103f6c <nmi>:
TRAPHANDLER_NOEC(nmi,T_NMI)
f0103f6c:	6a 00                	push   $0x0
f0103f6e:	6a 02                	push   $0x2
f0103f70:	e9 80 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f75:	90                   	nop

f0103f76 <oflow>:
TRAPHANDLER_NOEC(oflow,T_OFLOW)
f0103f76:	6a 00                	push   $0x0
f0103f78:	6a 04                	push   $0x4
f0103f7a:	e9 76 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f7f:	90                   	nop

f0103f80 <bound>:
TRAPHANDLER_NOEC(bound,T_BOUND)
f0103f80:	6a 00                	push   $0x0
f0103f82:	6a 05                	push   $0x5
f0103f84:	e9 6c 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f89:	90                   	nop

f0103f8a <illop>:
TRAPHANDLER_NOEC(illop,T_ILLOP)
f0103f8a:	6a 00                	push   $0x0
f0103f8c:	6a 06                	push   $0x6
f0103f8e:	e9 62 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f93:	90                   	nop

f0103f94 <device>:
TRAPHANDLER_NOEC(device,T_DEVICE)
f0103f94:	6a 00                	push   $0x0
f0103f96:	6a 07                	push   $0x7
f0103f98:	e9 58 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103f9d:	90                   	nop

f0103f9e <dblflt>:
TRAPHANDLER(dblflt,T_DBLFLT)
f0103f9e:	6a 08                	push   $0x8
f0103fa0:	e9 50 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fa5:	90                   	nop

f0103fa6 <tss>:
TRAPHANDLER(tss, T_TSS)
f0103fa6:	6a 0a                	push   $0xa
f0103fa8:	e9 48 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fad:	90                   	nop

f0103fae <stack>:

TRAPHANDLER(stack, T_STACK)
f0103fae:	6a 0c                	push   $0xc
f0103fb0:	e9 40 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fb5:	90                   	nop

f0103fb6 <gpflt>:
TRAPHANDLER(gpflt, T_GPFLT)
f0103fb6:	6a 0d                	push   $0xd
f0103fb8:	e9 38 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fbd:	90                   	nop

f0103fbe <pgflt>:
TRAPHANDLER(pgflt, T_PGFLT)
f0103fbe:	6a 0e                	push   $0xe
f0103fc0:	e9 30 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fc5:	90                   	nop

f0103fc6 <fperr>:

TRAPHANDLER_NOEC(fperr, T_FPERR)
f0103fc6:	6a 00                	push   $0x0
f0103fc8:	6a 10                	push   $0x10
f0103fca:	e9 26 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fcf:	90                   	nop

f0103fd0 <align>:
TRAPHANDLER(align, T_ALIGN)
f0103fd0:	6a 11                	push   $0x11
f0103fd2:	e9 1e 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fd7:	90                   	nop

f0103fd8 <mchk>:
TRAPHANDLER_NOEC(mchk, T_MCHK)
f0103fd8:	6a 00                	push   $0x0
f0103fda:	6a 12                	push   $0x12
f0103fdc:	e9 14 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103fe1:	90                   	nop

f0103fe2 <simderr>:
TRAPHANDLER_NOEC(simderr, T_SIMDERR)
f0103fe2:	6a 00                	push   $0x0
f0103fe4:	6a 13                	push   $0x13
f0103fe6:	e9 0a 00 00 00       	jmp    f0103ff5 <_alltraps>
f0103feb:	90                   	nop

f0103fec <syscalls>:



TRAPHANDLER_NOEC(syscalls, T_SYSCALL)
f0103fec:	6a 00                	push   $0x0
f0103fee:	6a 30                	push   $0x30
f0103ff0:	e9 00 00 00 00       	jmp    f0103ff5 <_alltraps>

f0103ff5 <_alltraps>:


.globl _alltraps
_alltraps:
	pushl %ds
f0103ff5:	1e                   	push   %ds
    pushl %es
f0103ff6:	06                   	push   %es
	pushal
f0103ff7:	60                   	pusha  

	movw $GD_KD, %ax
f0103ff8:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103ffc:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0103ffe:	8e c0                	mov    %eax,%es

    pushl %esp  /* trap(%esp) */
f0104000:	54                   	push   %esp
    call trap
f0104001:	e8 33 fd ff ff       	call   f0103d39 <trap>

f0104006 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104006:	55                   	push   %ebp
f0104007:	89 e5                	mov    %esp,%ebp
f0104009:	83 ec 08             	sub    $0x8,%esp
f010400c:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0104011:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104014:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104019:	8b 02                	mov    (%edx),%eax
f010401b:	83 e8 01             	sub    $0x1,%eax
f010401e:	83 f8 02             	cmp    $0x2,%eax
f0104021:	76 10                	jbe    f0104033 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104023:	83 c1 01             	add    $0x1,%ecx
f0104026:	83 c2 7c             	add    $0x7c,%edx
f0104029:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010402f:	75 e8                	jne    f0104019 <sched_halt+0x13>
f0104031:	eb 08                	jmp    f010403b <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104033:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104039:	75 1f                	jne    f010405a <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010403b:	83 ec 0c             	sub    $0xc,%esp
f010403e:	68 90 70 10 f0       	push   $0xf0107090
f0104043:	e8 41 f6 ff ff       	call   f0103689 <cprintf>
f0104048:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010404b:	83 ec 0c             	sub    $0xc,%esp
f010404e:	6a 00                	push   $0x0
f0104050:	e8 a6 c8 ff ff       	call   f01008fb <monitor>
f0104055:	83 c4 10             	add    $0x10,%esp
f0104058:	eb f1                	jmp    f010404b <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010405a:	e8 0f 13 00 00       	call   f010536e <cpunum>
f010405f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104062:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0104069:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010406c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104071:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104076:	77 12                	ja     f010408a <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104078:	50                   	push   %eax
f0104079:	68 48 5a 10 f0       	push   $0xf0105a48
f010407e:	6a 3d                	push   $0x3d
f0104080:	68 b9 70 10 f0       	push   $0xf01070b9
f0104085:	e8 b6 bf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010408a:	05 00 00 00 10       	add    $0x10000000,%eax
f010408f:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104092:	e8 d7 12 00 00       	call   f010536e <cpunum>
f0104097:	6b d0 74             	imul   $0x74,%eax,%edx
f010409a:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01040a0:	b8 02 00 00 00       	mov    $0x2,%eax
f01040a5:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01040a9:	83 ec 0c             	sub    $0xc,%esp
f01040ac:	68 c0 f3 11 f0       	push   $0xf011f3c0
f01040b1:	e8 c3 15 00 00       	call   f0105679 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01040b6:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01040b8:	e8 b1 12 00 00       	call   f010536e <cpunum>
f01040bd:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01040c0:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f01040c6:	bd 00 00 00 00       	mov    $0x0,%ebp
f01040cb:	89 c4                	mov    %eax,%esp
f01040cd:	6a 00                	push   $0x0
f01040cf:	6a 00                	push   $0x0
f01040d1:	fb                   	sti    
f01040d2:	f4                   	hlt    
f01040d3:	eb fd                	jmp    f01040d2 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01040d5:	83 c4 10             	add    $0x10,%esp
f01040d8:	c9                   	leave  
f01040d9:	c3                   	ret    

f01040da <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01040da:	55                   	push   %ebp
f01040db:	89 e5                	mov    %esp,%ebp
f01040dd:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f01040e0:	e8 21 ff ff ff       	call   f0104006 <sched_halt>
}
f01040e5:	c9                   	leave  
f01040e6:	c3                   	ret    

f01040e7 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01040e7:	55                   	push   %ebp
f01040e8:	89 e5                	mov    %esp,%ebp
f01040ea:	53                   	push   %ebx
f01040eb:	83 ec 14             	sub    $0x14,%esp
f01040ee:	8b 45 08             	mov    0x8(%ebp),%eax
//	SYS_cputs = 0,
//	SYS_cgetc,
//	SYS_getenvid,
//	SYS_env_destroy,al
int rval=0;
	switch(syscallno){
f01040f1:	83 f8 01             	cmp    $0x1,%eax
f01040f4:	74 4d                	je     f0104143 <syscall+0x5c>
f01040f6:	83 f8 01             	cmp    $0x1,%eax
f01040f9:	72 0f                	jb     f010410a <syscall+0x23>
f01040fb:	83 f8 02             	cmp    $0x2,%eax
f01040fe:	74 4d                	je     f010414d <syscall+0x66>
f0104100:	83 f8 03             	cmp    $0x3,%eax
f0104103:	74 5e                	je     f0104163 <syscall+0x7c>
f0104105:	e9 e1 00 00 00       	jmp    f01041eb <syscall+0x104>
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.
    user_mem_assert(curenv, s, len, PTE_U);
f010410a:	e8 5f 12 00 00       	call   f010536e <cpunum>
f010410f:	6a 04                	push   $0x4
f0104111:	ff 75 10             	pushl  0x10(%ebp)
f0104114:	ff 75 0c             	pushl  0xc(%ebp)
f0104117:	6b c0 74             	imul   $0x74,%eax,%eax
f010411a:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104120:	e8 ad eb ff ff       	call   f0102cd2 <user_mem_assert>
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104125:	83 c4 0c             	add    $0xc,%esp
f0104128:	ff 75 0c             	pushl  0xc(%ebp)
f010412b:	ff 75 10             	pushl  0x10(%ebp)
f010412e:	68 c6 70 10 f0       	push   $0xf01070c6
f0104133:	e8 51 f5 ff ff       	call   f0103689 <cprintf>
int rval=0;
	switch(syscallno){
		case SYS_cputs:
			sys_cputs((char *)a1, a2);
			rval = a2;
			break;
f0104138:	83 c4 10             	add    $0x10,%esp
//	SYS_env_destroy,al
int rval=0;
	switch(syscallno){
		case SYS_cputs:
			sys_cputs((char *)a1, a2);
			rval = a2;
f010413b:	8b 45 10             	mov    0x10(%ebp),%eax
			break;
f010413e:	e9 ad 00 00 00       	jmp    f01041f0 <syscall+0x109>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104143:	e8 ad c4 ff ff       	call   f01005f5 <cons_getc>
			sys_cputs((char *)a1, a2);
			rval = a2;
			break;
		case SYS_cgetc:
			rval = sys_cgetc();
			break;
f0104148:	e9 a3 00 00 00       	jmp    f01041f0 <syscall+0x109>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010414d:	e8 1c 12 00 00       	call   f010536e <cpunum>
f0104152:	6b c0 74             	imul   $0x74,%eax,%eax
f0104155:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010415b:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_cgetc:
			rval = sys_cgetc();
			break;
		case SYS_getenvid:
			rval = sys_getenvid();
			break;
f010415e:	e9 8d 00 00 00       	jmp    f01041f0 <syscall+0x109>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104163:	83 ec 04             	sub    $0x4,%esp
f0104166:	6a 01                	push   $0x1
f0104168:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010416b:	50                   	push   %eax
f010416c:	ff 75 0c             	pushl  0xc(%ebp)
f010416f:	e8 2f ec ff ff       	call   f0102da3 <envid2env>
f0104174:	83 c4 10             	add    $0x10,%esp
f0104177:	85 c0                	test   %eax,%eax
f0104179:	78 75                	js     f01041f0 <syscall+0x109>
		return r;
	if (e == curenv)
f010417b:	e8 ee 11 00 00       	call   f010536e <cpunum>
f0104180:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104183:	6b c0 74             	imul   $0x74,%eax,%eax
f0104186:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f010418c:	75 23                	jne    f01041b1 <syscall+0xca>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010418e:	e8 db 11 00 00       	call   f010536e <cpunum>
f0104193:	83 ec 08             	sub    $0x8,%esp
f0104196:	6b c0 74             	imul   $0x74,%eax,%eax
f0104199:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010419f:	ff 70 48             	pushl  0x48(%eax)
f01041a2:	68 cb 70 10 f0       	push   $0xf01070cb
f01041a7:	e8 dd f4 ff ff       	call   f0103689 <cprintf>
f01041ac:	83 c4 10             	add    $0x10,%esp
f01041af:	eb 25                	jmp    f01041d6 <syscall+0xef>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01041b1:	8b 5a 48             	mov    0x48(%edx),%ebx
f01041b4:	e8 b5 11 00 00       	call   f010536e <cpunum>
f01041b9:	83 ec 04             	sub    $0x4,%esp
f01041bc:	53                   	push   %ebx
f01041bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01041c6:	ff 70 48             	pushl  0x48(%eax)
f01041c9:	68 e6 70 10 f0       	push   $0xf01070e6
f01041ce:	e8 b6 f4 ff ff       	call   f0103689 <cprintf>
f01041d3:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01041d6:	83 ec 0c             	sub    $0xc,%esp
f01041d9:	ff 75 f4             	pushl  -0xc(%ebp)
f01041dc:	e8 92 f1 ff ff       	call   f0103373 <env_destroy>
f01041e1:	83 c4 10             	add    $0x10,%esp
	return 0;
f01041e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01041e9:	eb 05                	jmp    f01041f0 <syscall+0x109>
			break;
		case SYS_env_destroy:
			rval = sys_env_destroy(a1);
			break;
		default:
			return -E_INVAL; 
f01041eb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return rval;
}
f01041f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041f3:	c9                   	leave  
f01041f4:	c3                   	ret    

f01041f5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01041f5:	55                   	push   %ebp
f01041f6:	89 e5                	mov    %esp,%ebp
f01041f8:	57                   	push   %edi
f01041f9:	56                   	push   %esi
f01041fa:	53                   	push   %ebx
f01041fb:	83 ec 14             	sub    $0x14,%esp
f01041fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104201:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104204:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104207:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010420a:	8b 1a                	mov    (%edx),%ebx
f010420c:	8b 01                	mov    (%ecx),%eax
f010420e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104211:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104218:	eb 7f                	jmp    f0104299 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010421a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010421d:	01 d8                	add    %ebx,%eax
f010421f:	89 c6                	mov    %eax,%esi
f0104221:	c1 ee 1f             	shr    $0x1f,%esi
f0104224:	01 c6                	add    %eax,%esi
f0104226:	d1 fe                	sar    %esi
f0104228:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010422b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010422e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104231:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104233:	eb 03                	jmp    f0104238 <stab_binsearch+0x43>
			m--;
f0104235:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104238:	39 c3                	cmp    %eax,%ebx
f010423a:	7f 0d                	jg     f0104249 <stab_binsearch+0x54>
f010423c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104240:	83 ea 0c             	sub    $0xc,%edx
f0104243:	39 f9                	cmp    %edi,%ecx
f0104245:	75 ee                	jne    f0104235 <stab_binsearch+0x40>
f0104247:	eb 05                	jmp    f010424e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104249:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010424c:	eb 4b                	jmp    f0104299 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010424e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104251:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104254:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104258:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010425b:	76 11                	jbe    f010426e <stab_binsearch+0x79>
			*region_left = m;
f010425d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104260:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104262:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104265:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010426c:	eb 2b                	jmp    f0104299 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010426e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104271:	73 14                	jae    f0104287 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104273:	83 e8 01             	sub    $0x1,%eax
f0104276:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104279:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010427c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010427e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104285:	eb 12                	jmp    f0104299 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104287:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010428a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010428c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104290:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104292:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104299:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010429c:	0f 8e 78 ff ff ff    	jle    f010421a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01042a2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01042a6:	75 0f                	jne    f01042b7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01042a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042ab:	8b 00                	mov    (%eax),%eax
f01042ad:	83 e8 01             	sub    $0x1,%eax
f01042b0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01042b3:	89 06                	mov    %eax,(%esi)
f01042b5:	eb 2c                	jmp    f01042e3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042ba:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01042bc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01042bf:	8b 0e                	mov    (%esi),%ecx
f01042c1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01042c4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01042c7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042ca:	eb 03                	jmp    f01042cf <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01042cc:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042cf:	39 c8                	cmp    %ecx,%eax
f01042d1:	7e 0b                	jle    f01042de <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01042d3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01042d7:	83 ea 0c             	sub    $0xc,%edx
f01042da:	39 df                	cmp    %ebx,%edi
f01042dc:	75 ee                	jne    f01042cc <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01042de:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01042e1:	89 06                	mov    %eax,(%esi)
	}
}
f01042e3:	83 c4 14             	add    $0x14,%esp
f01042e6:	5b                   	pop    %ebx
f01042e7:	5e                   	pop    %esi
f01042e8:	5f                   	pop    %edi
f01042e9:	5d                   	pop    %ebp
f01042ea:	c3                   	ret    

f01042eb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01042eb:	55                   	push   %ebp
f01042ec:	89 e5                	mov    %esp,%ebp
f01042ee:	57                   	push   %edi
f01042ef:	56                   	push   %esi
f01042f0:	53                   	push   %ebx
f01042f1:	83 ec 2c             	sub    $0x2c,%esp
f01042f4:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042f7:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01042fa:	c7 06 fe 70 10 f0    	movl   $0xf01070fe,(%esi)
	info->eip_line = 0;
f0104300:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104307:	c7 46 08 fe 70 10 f0 	movl   $0xf01070fe,0x8(%esi)
	info->eip_fn_namelen = 9;
f010430e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104315:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104318:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010431f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104325:	0f 87 8b 00 00 00    	ja     f01043b6 <debuginfo_eip+0xcb>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_U|PTE_P);
f010432b:	e8 3e 10 00 00       	call   f010536e <cpunum>
f0104330:	6a 05                	push   $0x5
f0104332:	6a 10                	push   $0x10
f0104334:	68 00 00 20 00       	push   $0x200000
f0104339:	6b c0 74             	imul   $0x74,%eax,%eax
f010433c:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104342:	e8 08 e9 ff ff       	call   f0102c4f <user_mem_check>
		stabs = usd->stabs;
f0104347:	a1 00 00 20 00       	mov    0x200000,%eax
f010434c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f010434f:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104355:	a1 08 00 20 00       	mov    0x200008,%eax
f010435a:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f010435d:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104363:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_U|PTE_P))
f0104366:	e8 03 10 00 00       	call   f010536e <cpunum>
f010436b:	6a 05                	push   $0x5
f010436d:	6a 0c                	push   $0xc
f010436f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104372:	6b c0 74             	imul   $0x74,%eax,%eax
f0104375:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010437b:	e8 cf e8 ff ff       	call   f0102c4f <user_mem_check>
f0104380:	83 c4 20             	add    $0x20,%esp
f0104383:	85 c0                	test   %eax,%eax
f0104385:	0f 85 83 01 00 00    	jne    f010450e <debuginfo_eip+0x223>
		return -1;
	
		if(user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U|PTE_P))
f010438b:	e8 de 0f 00 00       	call   f010536e <cpunum>
f0104390:	6a 05                	push   $0x5
f0104392:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104395:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104398:	29 ca                	sub    %ecx,%edx
f010439a:	52                   	push   %edx
f010439b:	51                   	push   %ecx
f010439c:	6b c0 74             	imul   $0x74,%eax,%eax
f010439f:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01043a5:	e8 a5 e8 ff ff       	call   f0102c4f <user_mem_check>
f01043aa:	83 c4 10             	add    $0x10,%esp
f01043ad:	85 c0                	test   %eax,%eax
f01043af:	74 1f                	je     f01043d0 <debuginfo_eip+0xe5>
f01043b1:	e9 5f 01 00 00       	jmp    f0104515 <debuginfo_eip+0x22a>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01043b6:	c7 45 d0 0c 44 11 f0 	movl   $0xf011440c,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01043bd:	c7 45 cc b5 0d 11 f0 	movl   $0xf0110db5,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01043c4:	bb b4 0d 11 f0       	mov    $0xf0110db4,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01043c9:	c7 45 d4 98 75 10 f0 	movl   $0xf0107598,-0x2c(%ebp)
		
		
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01043d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01043d3:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01043d6:	0f 83 40 01 00 00    	jae    f010451c <debuginfo_eip+0x231>
f01043dc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01043e0:	0f 85 3d 01 00 00    	jne    f0104523 <debuginfo_eip+0x238>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01043e6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01043ed:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01043f0:	c1 fb 02             	sar    $0x2,%ebx
f01043f3:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01043f9:	83 e8 01             	sub    $0x1,%eax
f01043fc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01043ff:	83 ec 08             	sub    $0x8,%esp
f0104402:	57                   	push   %edi
f0104403:	6a 64                	push   $0x64
f0104405:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104408:	89 d1                	mov    %edx,%ecx
f010440a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010440d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104410:	89 d8                	mov    %ebx,%eax
f0104412:	e8 de fd ff ff       	call   f01041f5 <stab_binsearch>
	if (lfile == 0)
f0104417:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010441a:	83 c4 10             	add    $0x10,%esp
f010441d:	85 c0                	test   %eax,%eax
f010441f:	0f 84 05 01 00 00    	je     f010452a <debuginfo_eip+0x23f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104425:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104428:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010442b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010442e:	83 ec 08             	sub    $0x8,%esp
f0104431:	57                   	push   %edi
f0104432:	6a 24                	push   $0x24
f0104434:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104437:	89 d1                	mov    %edx,%ecx
f0104439:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010443c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010443f:	89 d8                	mov    %ebx,%eax
f0104441:	e8 af fd ff ff       	call   f01041f5 <stab_binsearch>

	if (lfun <= rfun) {
f0104446:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104449:	83 c4 10             	add    $0x10,%esp
f010444c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010444f:	7f 24                	jg     f0104475 <debuginfo_eip+0x18a>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104451:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104454:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104457:	8d 14 87             	lea    (%edi,%eax,4),%edx
f010445a:	8b 02                	mov    (%edx),%eax
f010445c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010445f:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104462:	29 f9                	sub    %edi,%ecx
f0104464:	39 c8                	cmp    %ecx,%eax
f0104466:	73 05                	jae    f010446d <debuginfo_eip+0x182>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104468:	01 f8                	add    %edi,%eax
f010446a:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010446d:	8b 42 08             	mov    0x8(%edx),%eax
f0104470:	89 46 10             	mov    %eax,0x10(%esi)
f0104473:	eb 06                	jmp    f010447b <debuginfo_eip+0x190>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104475:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104478:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010447b:	83 ec 08             	sub    $0x8,%esp
f010447e:	6a 3a                	push   $0x3a
f0104480:	ff 76 08             	pushl  0x8(%esi)
f0104483:	e8 a8 08 00 00       	call   f0104d30 <strfind>
f0104488:	2b 46 08             	sub    0x8(%esi),%eax
f010448b:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010448e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104491:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104494:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104497:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010449a:	83 c4 10             	add    $0x10,%esp
f010449d:	eb 06                	jmp    f01044a5 <debuginfo_eip+0x1ba>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010449f:	83 eb 01             	sub    $0x1,%ebx
f01044a2:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01044a5:	39 fb                	cmp    %edi,%ebx
f01044a7:	7c 2d                	jl     f01044d6 <debuginfo_eip+0x1eb>
	       && stabs[lline].n_type != N_SOL
f01044a9:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01044ad:	80 fa 84             	cmp    $0x84,%dl
f01044b0:	74 0b                	je     f01044bd <debuginfo_eip+0x1d2>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044b2:	80 fa 64             	cmp    $0x64,%dl
f01044b5:	75 e8                	jne    f010449f <debuginfo_eip+0x1b4>
f01044b7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01044bb:	74 e2                	je     f010449f <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044bd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01044c0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01044c3:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01044c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01044c9:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01044cc:	29 f8                	sub    %edi,%eax
f01044ce:	39 c2                	cmp    %eax,%edx
f01044d0:	73 04                	jae    f01044d6 <debuginfo_eip+0x1eb>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044d2:	01 fa                	add    %edi,%edx
f01044d4:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044d6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01044d9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044dc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044e1:	39 cb                	cmp    %ecx,%ebx
f01044e3:	7d 51                	jge    f0104536 <debuginfo_eip+0x24b>
		for (lline = lfun + 1;
f01044e5:	8d 53 01             	lea    0x1(%ebx),%edx
f01044e8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01044eb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01044ee:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01044f1:	eb 07                	jmp    f01044fa <debuginfo_eip+0x20f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01044f3:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01044f7:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01044fa:	39 ca                	cmp    %ecx,%edx
f01044fc:	74 33                	je     f0104531 <debuginfo_eip+0x246>
f01044fe:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104501:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0104505:	74 ec                	je     f01044f3 <debuginfo_eip+0x208>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104507:	b8 00 00 00 00       	mov    $0x0,%eax
f010450c:	eb 28                	jmp    f0104536 <debuginfo_eip+0x24b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_U|PTE_P))
		return -1;
f010450e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104513:	eb 21                	jmp    f0104536 <debuginfo_eip+0x24b>
	
		if(user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U|PTE_P))
		return -1;
f0104515:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010451a:	eb 1a                	jmp    f0104536 <debuginfo_eip+0x24b>
		
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010451c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104521:	eb 13                	jmp    f0104536 <debuginfo_eip+0x24b>
f0104523:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104528:	eb 0c                	jmp    f0104536 <debuginfo_eip+0x24b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010452a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010452f:	eb 05                	jmp    f0104536 <debuginfo_eip+0x24b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104531:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104536:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104539:	5b                   	pop    %ebx
f010453a:	5e                   	pop    %esi
f010453b:	5f                   	pop    %edi
f010453c:	5d                   	pop    %ebp
f010453d:	c3                   	ret    

f010453e <printnum>:
/*
 * Print a number (base <= 16) in reverse order,
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
f010453e:	55                   	push   %ebp
f010453f:	89 e5                	mov    %esp,%ebp
f0104541:	57                   	push   %edi
f0104542:	56                   	push   %esi
f0104543:	53                   	push   %ebx
f0104544:	83 ec 1c             	sub    $0x1c,%esp
f0104547:	89 c7                	mov    %eax,%edi
f0104549:	89 d6                	mov    %edx,%esi
f010454b:	8b 45 08             	mov    0x8(%ebp),%eax
f010454e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104551:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104554:	89 55 dc             	mov    %edx,-0x24(%ebp)
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104557:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010455a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010455f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104562:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104565:	39 d3                	cmp    %edx,%ebx
f0104567:	72 05                	jb     f010456e <printnum+0x30>
f0104569:	39 45 10             	cmp    %eax,0x10(%ebp)
f010456c:	77 45                	ja     f01045b3 <printnum+0x75>
	// first recursively print all preceding (more significant) digits
f010456e:	83 ec 0c             	sub    $0xc,%esp
f0104571:	ff 75 18             	pushl  0x18(%ebp)
f0104574:	8b 45 14             	mov    0x14(%ebp),%eax
f0104577:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010457a:	53                   	push   %ebx
f010457b:	ff 75 10             	pushl  0x10(%ebp)
f010457e:	83 ec 08             	sub    $0x8,%esp
f0104581:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104584:	ff 75 e0             	pushl  -0x20(%ebp)
f0104587:	ff 75 dc             	pushl  -0x24(%ebp)
f010458a:	ff 75 d8             	pushl  -0x28(%ebp)
f010458d:	e8 de 11 00 00       	call   f0105770 <__udivdi3>
f0104592:	83 c4 18             	add    $0x18,%esp
f0104595:	52                   	push   %edx
f0104596:	50                   	push   %eax
f0104597:	89 f2                	mov    %esi,%edx
f0104599:	89 f8                	mov    %edi,%eax
f010459b:	e8 9e ff ff ff       	call   f010453e <printnum>
f01045a0:	83 c4 20             	add    $0x20,%esp
f01045a3:	eb 18                	jmp    f01045bd <printnum+0x7f>
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
f01045a5:	83 ec 08             	sub    $0x8,%esp
f01045a8:	56                   	push   %esi
f01045a9:	ff 75 18             	pushl  0x18(%ebp)
f01045ac:	ff d7                	call   *%edi
f01045ae:	83 c4 10             	add    $0x10,%esp
f01045b1:	eb 03                	jmp    f01045b6 <printnum+0x78>
f01045b3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
f01045b6:	83 eb 01             	sub    $0x1,%ebx
f01045b9:	85 db                	test   %ebx,%ebx
f01045bb:	7f e8                	jg     f01045a5 <printnum+0x67>
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}

f01045bd:	83 ec 08             	sub    $0x8,%esp
f01045c0:	56                   	push   %esi
f01045c1:	83 ec 04             	sub    $0x4,%esp
f01045c4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045c7:	ff 75 e0             	pushl  -0x20(%ebp)
f01045ca:	ff 75 dc             	pushl  -0x24(%ebp)
f01045cd:	ff 75 d8             	pushl  -0x28(%ebp)
f01045d0:	e8 cb 12 00 00       	call   f01058a0 <__umoddi3>
f01045d5:	83 c4 14             	add    $0x14,%esp
f01045d8:	0f be 80 08 71 10 f0 	movsbl -0xfef8ef8(%eax),%eax
f01045df:	50                   	push   %eax
f01045e0:	ff d7                	call   *%edi
	// then print this (the least significant) digit
f01045e2:	83 c4 10             	add    $0x10,%esp
f01045e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045e8:	5b                   	pop    %ebx
f01045e9:	5e                   	pop    %esi
f01045ea:	5f                   	pop    %edi
f01045eb:	5d                   	pop    %ebp
f01045ec:	c3                   	ret    

f01045ed <sprintputch>:
	char *buf;
	char *ebuf;
	int cnt;
};

static void
f01045ed:	55                   	push   %ebp
f01045ee:	89 e5                	mov    %esp,%ebp
f01045f0:	8b 45 0c             	mov    0xc(%ebp),%eax
sprintputch(int ch, struct sprintbuf *b)
f01045f3:	83 40 08 01          	addl   $0x1,0x8(%eax)
{
f01045f7:	8b 10                	mov    (%eax),%edx
f01045f9:	3b 50 04             	cmp    0x4(%eax),%edx
f01045fc:	73 0a                	jae    f0104608 <sprintputch+0x1b>
	b->cnt++;
f01045fe:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104601:	89 08                	mov    %ecx,(%eax)
f0104603:	8b 45 08             	mov    0x8(%ebp),%eax
f0104606:	88 02                	mov    %al,(%edx)
	if (b->buf < b->ebuf)
f0104608:	5d                   	pop    %ebp
f0104609:	c3                   	ret    

f010460a <printfmt>:
			break;
		}
	}
}

void
f010460a:	55                   	push   %ebp
f010460b:	89 e5                	mov    %esp,%ebp
f010460d:	83 ec 08             	sub    $0x8,%esp
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
	va_list ap;
f0104610:	8d 45 14             	lea    0x14(%ebp),%eax

f0104613:	50                   	push   %eax
f0104614:	ff 75 10             	pushl  0x10(%ebp)
f0104617:	ff 75 0c             	pushl  0xc(%ebp)
f010461a:	ff 75 08             	pushl  0x8(%ebp)
f010461d:	e8 05 00 00 00       	call   f0104627 <vprintfmt>
	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0104622:	83 c4 10             	add    $0x10,%esp
f0104625:	c9                   	leave  
f0104626:	c3                   	ret    

f0104627 <vprintfmt>:


// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
f0104627:	55                   	push   %ebp
f0104628:	89 e5                	mov    %esp,%ebp
f010462a:	57                   	push   %edi
f010462b:	56                   	push   %esi
f010462c:	53                   	push   %ebx
f010462d:	83 ec 2c             	sub    $0x2c,%esp
f0104630:	8b 75 08             	mov    0x8(%ebp),%esi
f0104633:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104636:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104639:	eb 12                	jmp    f010464d <vprintfmt+0x26>
	register int ch, err;
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
f010463b:	85 c0                	test   %eax,%eax
f010463d:	0f 84 42 04 00 00    	je     f0104a85 <vprintfmt+0x45e>
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104643:	83 ec 08             	sub    $0x8,%esp
f0104646:	53                   	push   %ebx
f0104647:	50                   	push   %eax
f0104648:	ff d6                	call   *%esi
f010464a:	83 c4 10             	add    $0x10,%esp
	register const char *p;
	register int ch, err;
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

f010464d:	83 c7 01             	add    $0x1,%edi
f0104650:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104654:	83 f8 25             	cmp    $0x25,%eax
f0104657:	75 e2                	jne    f010463b <vprintfmt+0x14>
f0104659:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010465d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104664:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010466b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104672:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104677:	eb 07                	jmp    f0104680 <vprintfmt+0x59>
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f0104679:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
f010467c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f0104680:	8d 47 01             	lea    0x1(%edi),%eax
f0104683:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104686:	0f b6 07             	movzbl (%edi),%eax
f0104689:	0f b6 d0             	movzbl %al,%edx
f010468c:	83 e8 23             	sub    $0x23,%eax
f010468f:	3c 55                	cmp    $0x55,%al
f0104691:	0f 87 d3 03 00 00    	ja     f0104a6a <vprintfmt+0x443>
f0104697:	0f b6 c0             	movzbl %al,%eax
f010469a:	ff 24 85 94 71 10 f0 	jmp    *-0xfef8e6c(,%eax,4)
f01046a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		// flag to pad on the right
		case '-':
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
f01046a4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01046a8:	eb d6                	jmp    f0104680 <vprintfmt+0x59>
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f01046aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01046b2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
f01046b5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01046b8:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
			for (precision = 0; ; ++fmt) {
f01046bc:	0f be 17             	movsbl (%edi),%edx
				precision = precision * 10 + ch - '0';
f01046bf:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01046c2:	83 f9 09             	cmp    $0x9,%ecx
f01046c5:	77 3f                	ja     f0104706 <vprintfmt+0xdf>
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
f01046c7:	83 c7 01             	add    $0x1,%edi
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01046ca:	eb e9                	jmp    f01046b5 <vprintfmt+0x8e>
					break;
			}
			goto process_precision;

f01046cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01046cf:	8b 00                	mov    (%eax),%eax
f01046d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01046d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01046d7:	8d 40 04             	lea    0x4(%eax),%eax
f01046da:	89 45 14             	mov    %eax,0x14(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f01046dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;

		case '*':
f01046e0:	eb 2a                	jmp    f010470c <vprintfmt+0xe5>
f01046e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046e5:	85 c0                	test   %eax,%eax
f01046e7:	ba 00 00 00 00       	mov    $0x0,%edx
f01046ec:	0f 49 d0             	cmovns %eax,%edx
f01046ef:	89 55 e0             	mov    %edx,-0x20(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f01046f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046f5:	eb 89                	jmp    f0104680 <vprintfmt+0x59>
f01046f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		case '.':
			if (width < 0)
				width = 0;
			goto reswitch;

f01046fa:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
		case '#':
f0104701:	e9 7a ff ff ff       	jmp    f0104680 <vprintfmt+0x59>
f0104706:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104709:	89 45 d0             	mov    %eax,-0x30(%ebp)
			altflag = 1;
			goto reswitch;

f010470c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104710:	0f 89 6a ff ff ff    	jns    f0104680 <vprintfmt+0x59>
		process_precision:
f0104716:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104719:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010471c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104723:	e9 58 ff ff ff       	jmp    f0104680 <vprintfmt+0x59>
			if (width < 0)
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
f0104728:	83 c1 01             	add    $0x1,%ecx
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f010472b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
f010472e:	e9 4d ff ff ff       	jmp    f0104680 <vprintfmt+0x59>
			lflag++;
			goto reswitch;

		// character
f0104733:	8b 45 14             	mov    0x14(%ebp),%eax
f0104736:	8d 78 04             	lea    0x4(%eax),%edi
f0104739:	83 ec 08             	sub    $0x8,%esp
f010473c:	53                   	push   %ebx
f010473d:	ff 30                	pushl  (%eax)
f010473f:	ff d6                	call   *%esi
		case 'c':
f0104741:	83 c4 10             	add    $0x10,%esp
		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;

		// character
f0104744:	89 7d 14             	mov    %edi,0x14(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f0104747:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'l':
			lflag++;
			goto reswitch;

		// character
		case 'c':
f010474a:	e9 fe fe ff ff       	jmp    f010464d <vprintfmt+0x26>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
f010474f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104752:	8d 78 04             	lea    0x4(%eax),%edi
f0104755:	8b 00                	mov    (%eax),%eax
f0104757:	99                   	cltd   
f0104758:	31 d0                	xor    %edx,%eax
f010475a:	29 d0                	sub    %edx,%eax
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
f010475c:	83 f8 06             	cmp    $0x6,%eax
f010475f:	7f 0b                	jg     f010476c <vprintfmt+0x145>
f0104761:	8b 14 85 ec 72 10 f0 	mov    -0xfef8d14(,%eax,4),%edx
f0104768:	85 d2                	test   %edx,%edx
f010476a:	75 1b                	jne    f0104787 <vprintfmt+0x160>
				err = -err;
f010476c:	50                   	push   %eax
f010476d:	68 20 71 10 f0       	push   $0xf0107120
f0104772:	53                   	push   %ebx
f0104773:	56                   	push   %esi
f0104774:	e8 91 fe ff ff       	call   f010460a <printfmt>
f0104779:	83 c4 10             	add    $0x10,%esp
		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;

		// error message
f010477c:	89 7d 14             	mov    %edi,0x14(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f010477f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
f0104782:	e9 c6 fe ff ff       	jmp    f010464d <vprintfmt+0x26>
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104787:	52                   	push   %edx
f0104788:	68 cc 5f 10 f0       	push   $0xf0105fcc
f010478d:	53                   	push   %ebx
f010478e:	56                   	push   %esi
f010478f:	e8 76 fe ff ff       	call   f010460a <printfmt>
f0104794:	83 c4 10             	add    $0x10,%esp
		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;

		// error message
f0104797:	89 7d 14             	mov    %edi,0x14(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f010479a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010479d:	e9 ab fe ff ff       	jmp    f010464d <vprintfmt+0x26>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
			break;

		// string
f01047a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01047a5:	83 c0 04             	add    $0x4,%eax
f01047a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01047ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01047ae:	8b 38                	mov    (%eax),%edi
		case 's':
f01047b0:	85 ff                	test   %edi,%edi
f01047b2:	b8 19 71 10 f0       	mov    $0xf0107119,%eax
f01047b7:	0f 44 f8             	cmove  %eax,%edi
			if ((p = va_arg(ap, char *)) == NULL)
f01047ba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01047be:	0f 8e 94 00 00 00    	jle    f0104858 <vprintfmt+0x231>
f01047c4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01047c8:	0f 84 98 00 00 00    	je     f0104866 <vprintfmt+0x23f>
				p = "(null)";
f01047ce:	83 ec 08             	sub    $0x8,%esp
f01047d1:	ff 75 d0             	pushl  -0x30(%ebp)
f01047d4:	57                   	push   %edi
f01047d5:	e8 0c 04 00 00       	call   f0104be6 <strnlen>
f01047da:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01047dd:	29 c1                	sub    %eax,%ecx
f01047df:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01047e2:	83 c4 10             	add    $0x10,%esp
			if (width > 0 && padc != '-')
f01047e5:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01047e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047ec:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01047ef:	89 cf                	mov    %ecx,%edi
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
f01047f1:	eb 0f                	jmp    f0104802 <vprintfmt+0x1db>
			if (width > 0 && padc != '-')
f01047f3:	83 ec 08             	sub    $0x8,%esp
f01047f6:	53                   	push   %ebx
f01047f7:	ff 75 e0             	pushl  -0x20(%ebp)
f01047fa:	ff d6                	call   *%esi
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
f01047fc:	83 ef 01             	sub    $0x1,%edi
f01047ff:	83 c4 10             	add    $0x10,%esp
f0104802:	85 ff                	test   %edi,%edi
f0104804:	7f ed                	jg     f01047f3 <vprintfmt+0x1cc>
f0104806:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104809:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010480c:	85 c9                	test   %ecx,%ecx
f010480e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104813:	0f 49 c1             	cmovns %ecx,%eax
f0104816:	29 c1                	sub    %eax,%ecx
f0104818:	89 75 08             	mov    %esi,0x8(%ebp)
f010481b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010481e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104821:	89 cb                	mov    %ecx,%ebx
f0104823:	eb 4d                	jmp    f0104872 <vprintfmt+0x24b>
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
f0104825:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104829:	74 1b                	je     f0104846 <vprintfmt+0x21f>
f010482b:	0f be c0             	movsbl %al,%eax
f010482e:	83 e8 20             	sub    $0x20,%eax
f0104831:	83 f8 5e             	cmp    $0x5e,%eax
f0104834:	76 10                	jbe    f0104846 <vprintfmt+0x21f>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104836:	83 ec 08             	sub    $0x8,%esp
f0104839:	ff 75 0c             	pushl  0xc(%ebp)
f010483c:	6a 3f                	push   $0x3f
f010483e:	ff 55 08             	call   *0x8(%ebp)
f0104841:	83 c4 10             	add    $0x10,%esp
f0104844:	eb 0d                	jmp    f0104853 <vprintfmt+0x22c>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
f0104846:	83 ec 08             	sub    $0x8,%esp
f0104849:	ff 75 0c             	pushl  0xc(%ebp)
f010484c:	52                   	push   %edx
f010484d:	ff 55 08             	call   *0x8(%ebp)
f0104850:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104853:	83 eb 01             	sub    $0x1,%ebx
f0104856:	eb 1a                	jmp    f0104872 <vprintfmt+0x24b>
f0104858:	89 75 08             	mov    %esi,0x8(%ebp)
f010485b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010485e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104861:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104864:	eb 0c                	jmp    f0104872 <vprintfmt+0x24b>
f0104866:	89 75 08             	mov    %esi,0x8(%ebp)
f0104869:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010486c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010486f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104872:	83 c7 01             	add    $0x1,%edi
f0104875:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104879:	0f be d0             	movsbl %al,%edx
f010487c:	85 d2                	test   %edx,%edx
f010487e:	74 23                	je     f01048a3 <vprintfmt+0x27c>
f0104880:	85 f6                	test   %esi,%esi
f0104882:	78 a1                	js     f0104825 <vprintfmt+0x1fe>
f0104884:	83 ee 01             	sub    $0x1,%esi
f0104887:	79 9c                	jns    f0104825 <vprintfmt+0x1fe>
f0104889:	89 df                	mov    %ebx,%edi
f010488b:	8b 75 08             	mov    0x8(%ebp),%esi
f010488e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104891:	eb 18                	jmp    f01048ab <vprintfmt+0x284>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
f0104893:	83 ec 08             	sub    $0x8,%esp
f0104896:	53                   	push   %ebx
f0104897:	6a 20                	push   $0x20
f0104899:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
f010489b:	83 ef 01             	sub    $0x1,%edi
f010489e:	83 c4 10             	add    $0x10,%esp
f01048a1:	eb 08                	jmp    f01048ab <vprintfmt+0x284>
f01048a3:	89 df                	mov    %ebx,%edi
f01048a5:	8b 75 08             	mov    0x8(%ebp),%esi
f01048a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048ab:	85 ff                	test   %edi,%edi
f01048ad:	7f e4                	jg     f0104893 <vprintfmt+0x26c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
			break;

		// string
f01048af:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01048b2:	89 45 14             	mov    %eax,0x14(%ebp)
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f01048b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048b8:	e9 90 fd ff ff       	jmp    f010464d <vprintfmt+0x26>
}

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
f01048bd:	83 f9 01             	cmp    $0x1,%ecx
f01048c0:	7e 19                	jle    f01048db <vprintfmt+0x2b4>
{
f01048c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01048c5:	8b 50 04             	mov    0x4(%eax),%edx
f01048c8:	8b 00                	mov    (%eax),%eax
f01048ca:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048cd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01048d0:	8b 45 14             	mov    0x14(%ebp),%eax
f01048d3:	8d 40 08             	lea    0x8(%eax),%eax
f01048d6:	89 45 14             	mov    %eax,0x14(%ebp)
f01048d9:	eb 38                	jmp    f0104913 <vprintfmt+0x2ec>
	if (lflag >= 2)
f01048db:	85 c9                	test   %ecx,%ecx
f01048dd:	74 1b                	je     f01048fa <vprintfmt+0x2d3>
		return va_arg(*ap, long long);
f01048df:	8b 45 14             	mov    0x14(%ebp),%eax
f01048e2:	8b 00                	mov    (%eax),%eax
f01048e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048e7:	89 c1                	mov    %eax,%ecx
f01048e9:	c1 f9 1f             	sar    $0x1f,%ecx
f01048ec:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01048ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01048f2:	8d 40 04             	lea    0x4(%eax),%eax
f01048f5:	89 45 14             	mov    %eax,0x14(%ebp)
f01048f8:	eb 19                	jmp    f0104913 <vprintfmt+0x2ec>
	else if (lflag)
		return va_arg(*ap, long);
f01048fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01048fd:	8b 00                	mov    (%eax),%eax
f01048ff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104902:	89 c1                	mov    %eax,%ecx
f0104904:	c1 f9 1f             	sar    $0x1f,%ecx
f0104907:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010490a:	8b 45 14             	mov    0x14(%ebp),%eax
f010490d:	8d 40 04             	lea    0x4(%eax),%eax
f0104910:	89 45 14             	mov    %eax,0x14(%ebp)
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
			break;

		// (signed) decimal
f0104913:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104916:	8b 4d dc             	mov    -0x24(%ebp),%ecx
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
f0104919:	b8 0a 00 00 00       	mov    $0xa,%eax
			for (; width > 0; width--)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
f010491e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104922:	0f 89 0e 01 00 00    	jns    f0104a36 <vprintfmt+0x40f>
			num = getint(&ap, lflag);
f0104928:	83 ec 08             	sub    $0x8,%esp
f010492b:	53                   	push   %ebx
f010492c:	6a 2d                	push   $0x2d
f010492e:	ff d6                	call   *%esi
			if ((long long) num < 0) {
f0104930:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104933:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104936:	f7 da                	neg    %edx
f0104938:	83 d1 00             	adc    $0x0,%ecx
f010493b:	f7 d9                	neg    %ecx
f010493d:	83 c4 10             	add    $0x10,%esp
				putch('-', putdat);
				num = -(long long) num;
f0104940:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104945:	e9 ec 00 00 00       	jmp    f0104a36 <vprintfmt+0x40f>
}

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
f010494a:	83 f9 01             	cmp    $0x1,%ecx
f010494d:	7e 18                	jle    f0104967 <vprintfmt+0x340>
{
f010494f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104952:	8b 10                	mov    (%eax),%edx
f0104954:	8b 48 04             	mov    0x4(%eax),%ecx
f0104957:	8d 40 08             	lea    0x8(%eax),%eax
f010495a:	89 45 14             	mov    %eax,0x14(%ebp)
			}
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
f010495d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104962:	e9 cf 00 00 00       	jmp    f0104a36 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104967:	85 c9                	test   %ecx,%ecx
f0104969:	74 1a                	je     f0104985 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long long);
f010496b:	8b 45 14             	mov    0x14(%ebp),%eax
f010496e:	8b 10                	mov    (%eax),%edx
f0104970:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104975:	8d 40 04             	lea    0x4(%eax),%eax
f0104978:	89 45 14             	mov    %eax,0x14(%ebp)
			}
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
f010497b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104980:	e9 b1 00 00 00       	jmp    f0104a36 <vprintfmt+0x40f>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0104985:	8b 45 14             	mov    0x14(%ebp),%eax
f0104988:	8b 10                	mov    (%eax),%edx
f010498a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010498f:	8d 40 04             	lea    0x4(%eax),%eax
f0104992:	89 45 14             	mov    %eax,0x14(%ebp)
			}
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
f0104995:	b8 0a 00 00 00       	mov    $0xa,%eax
f010499a:	e9 97 00 00 00       	jmp    f0104a36 <vprintfmt+0x40f>
			num = getuint(&ap, lflag);
			base = 10;
			goto number;

		// (unsigned) octal
		case 'o':
f010499f:	83 ec 08             	sub    $0x8,%esp
f01049a2:	53                   	push   %ebx
f01049a3:	6a 58                	push   $0x58
f01049a5:	ff d6                	call   *%esi
			// Replace this with your code.
f01049a7:	83 c4 08             	add    $0x8,%esp
f01049aa:	53                   	push   %ebx
f01049ab:	6a 58                	push   $0x58
f01049ad:	ff d6                	call   *%esi
			putch('X', putdat);
f01049af:	83 c4 08             	add    $0x8,%esp
f01049b2:	53                   	push   %ebx
f01049b3:	6a 58                	push   $0x58
f01049b5:	ff d6                	call   *%esi
			putch('X', putdat);
f01049b7:	83 c4 10             	add    $0x10,%esp
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f01049ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
f01049bd:	e9 8b fc ff ff       	jmp    f010464d <vprintfmt+0x26>
			putch('X', putdat);
			break;

		// pointer
f01049c2:	83 ec 08             	sub    $0x8,%esp
f01049c5:	53                   	push   %ebx
f01049c6:	6a 30                	push   $0x30
f01049c8:	ff d6                	call   *%esi
		case 'p':
f01049ca:	83 c4 08             	add    $0x8,%esp
f01049cd:	53                   	push   %ebx
f01049ce:	6a 78                	push   $0x78
f01049d0:	ff d6                	call   *%esi
			putch('0', putdat);
f01049d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01049d5:	8b 10                	mov    (%eax),%edx
f01049d7:	b9 00 00 00 00       	mov    $0x0,%ecx
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01049dc:	83 c4 10             	add    $0x10,%esp
			break;

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
f01049df:	8d 40 04             	lea    0x4(%eax),%eax
f01049e2:	89 45 14             	mov    %eax,0x14(%ebp)
			num = (unsigned long long)
f01049e5:	b8 10 00 00 00       	mov    $0x10,%eax
				(uintptr_t) va_arg(ap, void *);
f01049ea:	eb 4a                	jmp    f0104a36 <vprintfmt+0x40f>
}

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
f01049ec:	83 f9 01             	cmp    $0x1,%ecx
f01049ef:	7e 15                	jle    f0104a06 <vprintfmt+0x3df>
{
f01049f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01049f4:	8b 10                	mov    (%eax),%edx
f01049f6:	8b 48 04             	mov    0x4(%eax),%ecx
f01049f9:	8d 40 08             	lea    0x8(%eax),%eax
f01049fc:	89 45 14             	mov    %eax,0x14(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;

		// (unsigned) hexadecimal
		case 'x':
f01049ff:	b8 10 00 00 00       	mov    $0x10,%eax
f0104a04:	eb 30                	jmp    f0104a36 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104a06:	85 c9                	test   %ecx,%ecx
f0104a08:	74 17                	je     f0104a21 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long long);
f0104a0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a0d:	8b 10                	mov    (%eax),%edx
f0104a0f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104a14:	8d 40 04             	lea    0x4(%eax),%eax
f0104a17:	89 45 14             	mov    %eax,0x14(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;

		// (unsigned) hexadecimal
		case 'x':
f0104a1a:	b8 10 00 00 00       	mov    $0x10,%eax
f0104a1f:	eb 15                	jmp    f0104a36 <vprintfmt+0x40f>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0104a21:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a24:	8b 10                	mov    (%eax),%edx
f0104a26:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104a2b:	8d 40 04             	lea    0x4(%eax),%eax
f0104a2e:	89 45 14             	mov    %eax,0x14(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;

		// (unsigned) hexadecimal
		case 'x':
f0104a31:	b8 10 00 00 00       	mov    $0x10,%eax
			num = getuint(&ap, lflag);
			base = 16;
f0104a36:	83 ec 0c             	sub    $0xc,%esp
f0104a39:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104a3d:	57                   	push   %edi
f0104a3e:	ff 75 e0             	pushl  -0x20(%ebp)
f0104a41:	50                   	push   %eax
f0104a42:	51                   	push   %ecx
f0104a43:	52                   	push   %edx
f0104a44:	89 da                	mov    %ebx,%edx
f0104a46:	89 f0                	mov    %esi,%eax
f0104a48:	e8 f1 fa ff ff       	call   f010453e <printnum>
		number:
f0104a4d:	83 c4 20             	add    $0x20,%esp
f0104a50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a53:	e9 f5 fb ff ff       	jmp    f010464d <vprintfmt+0x26>
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
f0104a58:	83 ec 08             	sub    $0x8,%esp
f0104a5b:	53                   	push   %ebx
f0104a5c:	52                   	push   %edx
f0104a5d:	ff d6                	call   *%esi
		case '%':
f0104a5f:	83 c4 10             	add    $0x10,%esp
		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f0104a62:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
		case '%':
f0104a65:	e9 e3 fb ff ff       	jmp    f010464d <vprintfmt+0x26>
			putch(ch, putdat);
			break;

		// unrecognized escape sequence - just print it literally
f0104a6a:	83 ec 08             	sub    $0x8,%esp
f0104a6d:	53                   	push   %ebx
f0104a6e:	6a 25                	push   $0x25
f0104a70:	ff d6                	call   *%esi
		default:
f0104a72:	83 c4 10             	add    $0x10,%esp
f0104a75:	eb 03                	jmp    f0104a7a <vprintfmt+0x453>
f0104a77:	83 ef 01             	sub    $0x1,%edi
f0104a7a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a7e:	75 f7                	jne    f0104a77 <vprintfmt+0x450>
f0104a80:	e9 c8 fb ff ff       	jmp    f010464d <vprintfmt+0x26>
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
f0104a85:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a88:	5b                   	pop    %ebx
f0104a89:	5e                   	pop    %esi
f0104a8a:	5f                   	pop    %edi
f0104a8b:	5d                   	pop    %ebp
f0104a8c:	c3                   	ret    

f0104a8d <vsnprintf>:
	b->cnt++;
	if (b->buf < b->ebuf)
		*b->buf++ = ch;
}

int
f0104a8d:	55                   	push   %ebp
f0104a8e:	89 e5                	mov    %esp,%ebp
f0104a90:	83 ec 18             	sub    $0x18,%esp
f0104a93:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a96:	8b 55 0c             	mov    0xc(%ebp),%edx
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
f0104a99:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a9c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104aa0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104aa3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104aaa:	85 c0                	test   %eax,%eax
f0104aac:	74 26                	je     f0104ad4 <vsnprintf+0x47>
f0104aae:	85 d2                	test   %edx,%edx
f0104ab0:	7e 22                	jle    f0104ad4 <vsnprintf+0x47>

	if (buf == NULL || n < 1)
		return -E_INVAL;

f0104ab2:	ff 75 14             	pushl  0x14(%ebp)
f0104ab5:	ff 75 10             	pushl  0x10(%ebp)
f0104ab8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104abb:	50                   	push   %eax
f0104abc:	68 ed 45 10 f0       	push   $0xf01045ed
f0104ac1:	e8 61 fb ff ff       	call   f0104627 <vprintfmt>
	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);

f0104ac6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104ac9:	c6 00 00             	movb   $0x0,(%eax)
	// null terminate the buffer
	*b.buf = '\0';
f0104acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104acf:	83 c4 10             	add    $0x10,%esp
f0104ad2:	eb 05                	jmp    f0104ad9 <vsnprintf+0x4c>

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

f0104ad4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);

	// null terminate the buffer
	*b.buf = '\0';

f0104ad9:	c9                   	leave  
f0104ada:	c3                   	ret    

f0104adb <snprintf>:
	return b.cnt;
}

int
f0104adb:	55                   	push   %ebp
f0104adc:	89 e5                	mov    %esp,%ebp
f0104ade:	83 ec 08             	sub    $0x8,%esp
snprintf(char *buf, int n, const char *fmt, ...)
{
	va_list ap;
	int rc;
f0104ae1:	8d 45 14             	lea    0x14(%ebp),%eax

f0104ae4:	50                   	push   %eax
f0104ae5:	ff 75 10             	pushl  0x10(%ebp)
f0104ae8:	ff 75 0c             	pushl  0xc(%ebp)
f0104aeb:	ff 75 08             	pushl  0x8(%ebp)
f0104aee:	e8 9a ff ff ff       	call   f0104a8d <vsnprintf>
	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
	va_end(ap);

f0104af3:	c9                   	leave  
f0104af4:	c3                   	ret    

f0104af5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104af5:	55                   	push   %ebp
f0104af6:	89 e5                	mov    %esp,%ebp
f0104af8:	57                   	push   %edi
f0104af9:	56                   	push   %esi
f0104afa:	53                   	push   %ebx
f0104afb:	83 ec 0c             	sub    $0xc,%esp
f0104afe:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104b01:	85 c0                	test   %eax,%eax
f0104b03:	74 11                	je     f0104b16 <readline+0x21>
		cprintf("%s", prompt);
f0104b05:	83 ec 08             	sub    $0x8,%esp
f0104b08:	50                   	push   %eax
f0104b09:	68 cc 5f 10 f0       	push   $0xf0105fcc
f0104b0e:	e8 76 eb ff ff       	call   f0103689 <cprintf>
f0104b13:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104b16:	83 ec 0c             	sub    $0xc,%esp
f0104b19:	6a 00                	push   $0x0
f0104b1b:	e8 65 bc ff ff       	call   f0100785 <iscons>
f0104b20:	89 c7                	mov    %eax,%edi
f0104b22:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104b25:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104b2a:	e8 45 bc ff ff       	call   f0100774 <getchar>
f0104b2f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104b31:	85 c0                	test   %eax,%eax
f0104b33:	79 18                	jns    f0104b4d <readline+0x58>
			cprintf("read error: %e\n", c);
f0104b35:	83 ec 08             	sub    $0x8,%esp
f0104b38:	50                   	push   %eax
f0104b39:	68 08 73 10 f0       	push   $0xf0107308
f0104b3e:	e8 46 eb ff ff       	call   f0103689 <cprintf>
			return NULL;
f0104b43:	83 c4 10             	add    $0x10,%esp
f0104b46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b4b:	eb 79                	jmp    f0104bc6 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104b4d:	83 f8 08             	cmp    $0x8,%eax
f0104b50:	0f 94 c2             	sete   %dl
f0104b53:	83 f8 7f             	cmp    $0x7f,%eax
f0104b56:	0f 94 c0             	sete   %al
f0104b59:	08 c2                	or     %al,%dl
f0104b5b:	74 1a                	je     f0104b77 <readline+0x82>
f0104b5d:	85 f6                	test   %esi,%esi
f0104b5f:	7e 16                	jle    f0104b77 <readline+0x82>
			if (echoing)
f0104b61:	85 ff                	test   %edi,%edi
f0104b63:	74 0d                	je     f0104b72 <readline+0x7d>
				cputchar('\b');
f0104b65:	83 ec 0c             	sub    $0xc,%esp
f0104b68:	6a 08                	push   $0x8
f0104b6a:	e8 f5 bb ff ff       	call   f0100764 <cputchar>
f0104b6f:	83 c4 10             	add    $0x10,%esp
			i--;
f0104b72:	83 ee 01             	sub    $0x1,%esi
f0104b75:	eb b3                	jmp    f0104b2a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b77:	83 fb 1f             	cmp    $0x1f,%ebx
f0104b7a:	7e 23                	jle    f0104b9f <readline+0xaa>
f0104b7c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b82:	7f 1b                	jg     f0104b9f <readline+0xaa>
			if (echoing)
f0104b84:	85 ff                	test   %edi,%edi
f0104b86:	74 0c                	je     f0104b94 <readline+0x9f>
				cputchar(c);
f0104b88:	83 ec 0c             	sub    $0xc,%esp
f0104b8b:	53                   	push   %ebx
f0104b8c:	e8 d3 bb ff ff       	call   f0100764 <cputchar>
f0104b91:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b94:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104b9a:	8d 76 01             	lea    0x1(%esi),%esi
f0104b9d:	eb 8b                	jmp    f0104b2a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b9f:	83 fb 0a             	cmp    $0xa,%ebx
f0104ba2:	74 05                	je     f0104ba9 <readline+0xb4>
f0104ba4:	83 fb 0d             	cmp    $0xd,%ebx
f0104ba7:	75 81                	jne    f0104b2a <readline+0x35>
			if (echoing)
f0104ba9:	85 ff                	test   %edi,%edi
f0104bab:	74 0d                	je     f0104bba <readline+0xc5>
				cputchar('\n');
f0104bad:	83 ec 0c             	sub    $0xc,%esp
f0104bb0:	6a 0a                	push   $0xa
f0104bb2:	e8 ad bb ff ff       	call   f0100764 <cputchar>
f0104bb7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104bba:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104bc1:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104bc6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104bc9:	5b                   	pop    %ebx
f0104bca:	5e                   	pop    %esi
f0104bcb:	5f                   	pop    %edi
f0104bcc:	5d                   	pop    %ebp
f0104bcd:	c3                   	ret    

f0104bce <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104bce:	55                   	push   %ebp
f0104bcf:	89 e5                	mov    %esp,%ebp
f0104bd1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104bd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bd9:	eb 03                	jmp    f0104bde <strlen+0x10>
		n++;
f0104bdb:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104bde:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104be2:	75 f7                	jne    f0104bdb <strlen+0xd>
		n++;
	return n;
}
f0104be4:	5d                   	pop    %ebp
f0104be5:	c3                   	ret    

f0104be6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104be6:	55                   	push   %ebp
f0104be7:	89 e5                	mov    %esp,%ebp
f0104be9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104bec:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bef:	ba 00 00 00 00       	mov    $0x0,%edx
f0104bf4:	eb 03                	jmp    f0104bf9 <strnlen+0x13>
		n++;
f0104bf6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bf9:	39 c2                	cmp    %eax,%edx
f0104bfb:	74 08                	je     f0104c05 <strnlen+0x1f>
f0104bfd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104c01:	75 f3                	jne    f0104bf6 <strnlen+0x10>
f0104c03:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104c05:	5d                   	pop    %ebp
f0104c06:	c3                   	ret    

f0104c07 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104c07:	55                   	push   %ebp
f0104c08:	89 e5                	mov    %esp,%ebp
f0104c0a:	53                   	push   %ebx
f0104c0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c0e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104c11:	89 c2                	mov    %eax,%edx
f0104c13:	83 c2 01             	add    $0x1,%edx
f0104c16:	83 c1 01             	add    $0x1,%ecx
f0104c19:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104c1d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104c20:	84 db                	test   %bl,%bl
f0104c22:	75 ef                	jne    f0104c13 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104c24:	5b                   	pop    %ebx
f0104c25:	5d                   	pop    %ebp
f0104c26:	c3                   	ret    

f0104c27 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104c27:	55                   	push   %ebp
f0104c28:	89 e5                	mov    %esp,%ebp
f0104c2a:	53                   	push   %ebx
f0104c2b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104c2e:	53                   	push   %ebx
f0104c2f:	e8 9a ff ff ff       	call   f0104bce <strlen>
f0104c34:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104c37:	ff 75 0c             	pushl  0xc(%ebp)
f0104c3a:	01 d8                	add    %ebx,%eax
f0104c3c:	50                   	push   %eax
f0104c3d:	e8 c5 ff ff ff       	call   f0104c07 <strcpy>
	return dst;
}
f0104c42:	89 d8                	mov    %ebx,%eax
f0104c44:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104c47:	c9                   	leave  
f0104c48:	c3                   	ret    

f0104c49 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104c49:	55                   	push   %ebp
f0104c4a:	89 e5                	mov    %esp,%ebp
f0104c4c:	56                   	push   %esi
f0104c4d:	53                   	push   %ebx
f0104c4e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c54:	89 f3                	mov    %esi,%ebx
f0104c56:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c59:	89 f2                	mov    %esi,%edx
f0104c5b:	eb 0f                	jmp    f0104c6c <strncpy+0x23>
		*dst++ = *src;
f0104c5d:	83 c2 01             	add    $0x1,%edx
f0104c60:	0f b6 01             	movzbl (%ecx),%eax
f0104c63:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104c66:	80 39 01             	cmpb   $0x1,(%ecx)
f0104c69:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c6c:	39 da                	cmp    %ebx,%edx
f0104c6e:	75 ed                	jne    f0104c5d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104c70:	89 f0                	mov    %esi,%eax
f0104c72:	5b                   	pop    %ebx
f0104c73:	5e                   	pop    %esi
f0104c74:	5d                   	pop    %ebp
f0104c75:	c3                   	ret    

f0104c76 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c76:	55                   	push   %ebp
f0104c77:	89 e5                	mov    %esp,%ebp
f0104c79:	56                   	push   %esi
f0104c7a:	53                   	push   %ebx
f0104c7b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c7e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c81:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c84:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c86:	85 d2                	test   %edx,%edx
f0104c88:	74 21                	je     f0104cab <strlcpy+0x35>
f0104c8a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104c8e:	89 f2                	mov    %esi,%edx
f0104c90:	eb 09                	jmp    f0104c9b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c92:	83 c2 01             	add    $0x1,%edx
f0104c95:	83 c1 01             	add    $0x1,%ecx
f0104c98:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c9b:	39 c2                	cmp    %eax,%edx
f0104c9d:	74 09                	je     f0104ca8 <strlcpy+0x32>
f0104c9f:	0f b6 19             	movzbl (%ecx),%ebx
f0104ca2:	84 db                	test   %bl,%bl
f0104ca4:	75 ec                	jne    f0104c92 <strlcpy+0x1c>
f0104ca6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104ca8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104cab:	29 f0                	sub    %esi,%eax
}
f0104cad:	5b                   	pop    %ebx
f0104cae:	5e                   	pop    %esi
f0104caf:	5d                   	pop    %ebp
f0104cb0:	c3                   	ret    

f0104cb1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104cb1:	55                   	push   %ebp
f0104cb2:	89 e5                	mov    %esp,%ebp
f0104cb4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104cb7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104cba:	eb 06                	jmp    f0104cc2 <strcmp+0x11>
		p++, q++;
f0104cbc:	83 c1 01             	add    $0x1,%ecx
f0104cbf:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104cc2:	0f b6 01             	movzbl (%ecx),%eax
f0104cc5:	84 c0                	test   %al,%al
f0104cc7:	74 04                	je     f0104ccd <strcmp+0x1c>
f0104cc9:	3a 02                	cmp    (%edx),%al
f0104ccb:	74 ef                	je     f0104cbc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ccd:	0f b6 c0             	movzbl %al,%eax
f0104cd0:	0f b6 12             	movzbl (%edx),%edx
f0104cd3:	29 d0                	sub    %edx,%eax
}
f0104cd5:	5d                   	pop    %ebp
f0104cd6:	c3                   	ret    

f0104cd7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104cd7:	55                   	push   %ebp
f0104cd8:	89 e5                	mov    %esp,%ebp
f0104cda:	53                   	push   %ebx
f0104cdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cde:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ce1:	89 c3                	mov    %eax,%ebx
f0104ce3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104ce6:	eb 06                	jmp    f0104cee <strncmp+0x17>
		n--, p++, q++;
f0104ce8:	83 c0 01             	add    $0x1,%eax
f0104ceb:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104cee:	39 d8                	cmp    %ebx,%eax
f0104cf0:	74 15                	je     f0104d07 <strncmp+0x30>
f0104cf2:	0f b6 08             	movzbl (%eax),%ecx
f0104cf5:	84 c9                	test   %cl,%cl
f0104cf7:	74 04                	je     f0104cfd <strncmp+0x26>
f0104cf9:	3a 0a                	cmp    (%edx),%cl
f0104cfb:	74 eb                	je     f0104ce8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104cfd:	0f b6 00             	movzbl (%eax),%eax
f0104d00:	0f b6 12             	movzbl (%edx),%edx
f0104d03:	29 d0                	sub    %edx,%eax
f0104d05:	eb 05                	jmp    f0104d0c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104d07:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104d0c:	5b                   	pop    %ebx
f0104d0d:	5d                   	pop    %ebp
f0104d0e:	c3                   	ret    

f0104d0f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104d0f:	55                   	push   %ebp
f0104d10:	89 e5                	mov    %esp,%ebp
f0104d12:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d15:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d19:	eb 07                	jmp    f0104d22 <strchr+0x13>
		if (*s == c)
f0104d1b:	38 ca                	cmp    %cl,%dl
f0104d1d:	74 0f                	je     f0104d2e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104d1f:	83 c0 01             	add    $0x1,%eax
f0104d22:	0f b6 10             	movzbl (%eax),%edx
f0104d25:	84 d2                	test   %dl,%dl
f0104d27:	75 f2                	jne    f0104d1b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104d29:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d2e:	5d                   	pop    %ebp
f0104d2f:	c3                   	ret    

f0104d30 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104d30:	55                   	push   %ebp
f0104d31:	89 e5                	mov    %esp,%ebp
f0104d33:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d36:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d3a:	eb 03                	jmp    f0104d3f <strfind+0xf>
f0104d3c:	83 c0 01             	add    $0x1,%eax
f0104d3f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104d42:	38 ca                	cmp    %cl,%dl
f0104d44:	74 04                	je     f0104d4a <strfind+0x1a>
f0104d46:	84 d2                	test   %dl,%dl
f0104d48:	75 f2                	jne    f0104d3c <strfind+0xc>
			break;
	return (char *) s;
}
f0104d4a:	5d                   	pop    %ebp
f0104d4b:	c3                   	ret    

f0104d4c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104d4c:	55                   	push   %ebp
f0104d4d:	89 e5                	mov    %esp,%ebp
f0104d4f:	57                   	push   %edi
f0104d50:	56                   	push   %esi
f0104d51:	53                   	push   %ebx
f0104d52:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104d55:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104d58:	85 c9                	test   %ecx,%ecx
f0104d5a:	74 36                	je     f0104d92 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104d5c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104d62:	75 28                	jne    f0104d8c <memset+0x40>
f0104d64:	f6 c1 03             	test   $0x3,%cl
f0104d67:	75 23                	jne    f0104d8c <memset+0x40>
		c &= 0xFF;
f0104d69:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104d6d:	89 d3                	mov    %edx,%ebx
f0104d6f:	c1 e3 08             	shl    $0x8,%ebx
f0104d72:	89 d6                	mov    %edx,%esi
f0104d74:	c1 e6 18             	shl    $0x18,%esi
f0104d77:	89 d0                	mov    %edx,%eax
f0104d79:	c1 e0 10             	shl    $0x10,%eax
f0104d7c:	09 f0                	or     %esi,%eax
f0104d7e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104d80:	89 d8                	mov    %ebx,%eax
f0104d82:	09 d0                	or     %edx,%eax
f0104d84:	c1 e9 02             	shr    $0x2,%ecx
f0104d87:	fc                   	cld    
f0104d88:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d8a:	eb 06                	jmp    f0104d92 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d8f:	fc                   	cld    
f0104d90:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d92:	89 f8                	mov    %edi,%eax
f0104d94:	5b                   	pop    %ebx
f0104d95:	5e                   	pop    %esi
f0104d96:	5f                   	pop    %edi
f0104d97:	5d                   	pop    %ebp
f0104d98:	c3                   	ret    

f0104d99 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d99:	55                   	push   %ebp
f0104d9a:	89 e5                	mov    %esp,%ebp
f0104d9c:	57                   	push   %edi
f0104d9d:	56                   	push   %esi
f0104d9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104da1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104da4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104da7:	39 c6                	cmp    %eax,%esi
f0104da9:	73 35                	jae    f0104de0 <memmove+0x47>
f0104dab:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104dae:	39 d0                	cmp    %edx,%eax
f0104db0:	73 2e                	jae    f0104de0 <memmove+0x47>
		s += n;
		d += n;
f0104db2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104db5:	89 d6                	mov    %edx,%esi
f0104db7:	09 fe                	or     %edi,%esi
f0104db9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104dbf:	75 13                	jne    f0104dd4 <memmove+0x3b>
f0104dc1:	f6 c1 03             	test   $0x3,%cl
f0104dc4:	75 0e                	jne    f0104dd4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104dc6:	83 ef 04             	sub    $0x4,%edi
f0104dc9:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104dcc:	c1 e9 02             	shr    $0x2,%ecx
f0104dcf:	fd                   	std    
f0104dd0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104dd2:	eb 09                	jmp    f0104ddd <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104dd4:	83 ef 01             	sub    $0x1,%edi
f0104dd7:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104dda:	fd                   	std    
f0104ddb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104ddd:	fc                   	cld    
f0104dde:	eb 1d                	jmp    f0104dfd <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104de0:	89 f2                	mov    %esi,%edx
f0104de2:	09 c2                	or     %eax,%edx
f0104de4:	f6 c2 03             	test   $0x3,%dl
f0104de7:	75 0f                	jne    f0104df8 <memmove+0x5f>
f0104de9:	f6 c1 03             	test   $0x3,%cl
f0104dec:	75 0a                	jne    f0104df8 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104dee:	c1 e9 02             	shr    $0x2,%ecx
f0104df1:	89 c7                	mov    %eax,%edi
f0104df3:	fc                   	cld    
f0104df4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104df6:	eb 05                	jmp    f0104dfd <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104df8:	89 c7                	mov    %eax,%edi
f0104dfa:	fc                   	cld    
f0104dfb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104dfd:	5e                   	pop    %esi
f0104dfe:	5f                   	pop    %edi
f0104dff:	5d                   	pop    %ebp
f0104e00:	c3                   	ret    

f0104e01 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104e01:	55                   	push   %ebp
f0104e02:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104e04:	ff 75 10             	pushl  0x10(%ebp)
f0104e07:	ff 75 0c             	pushl  0xc(%ebp)
f0104e0a:	ff 75 08             	pushl  0x8(%ebp)
f0104e0d:	e8 87 ff ff ff       	call   f0104d99 <memmove>
}
f0104e12:	c9                   	leave  
f0104e13:	c3                   	ret    

f0104e14 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104e14:	55                   	push   %ebp
f0104e15:	89 e5                	mov    %esp,%ebp
f0104e17:	56                   	push   %esi
f0104e18:	53                   	push   %ebx
f0104e19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e1c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e1f:	89 c6                	mov    %eax,%esi
f0104e21:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104e24:	eb 1a                	jmp    f0104e40 <memcmp+0x2c>
		if (*s1 != *s2)
f0104e26:	0f b6 08             	movzbl (%eax),%ecx
f0104e29:	0f b6 1a             	movzbl (%edx),%ebx
f0104e2c:	38 d9                	cmp    %bl,%cl
f0104e2e:	74 0a                	je     f0104e3a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104e30:	0f b6 c1             	movzbl %cl,%eax
f0104e33:	0f b6 db             	movzbl %bl,%ebx
f0104e36:	29 d8                	sub    %ebx,%eax
f0104e38:	eb 0f                	jmp    f0104e49 <memcmp+0x35>
		s1++, s2++;
f0104e3a:	83 c0 01             	add    $0x1,%eax
f0104e3d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104e40:	39 f0                	cmp    %esi,%eax
f0104e42:	75 e2                	jne    f0104e26 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104e44:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e49:	5b                   	pop    %ebx
f0104e4a:	5e                   	pop    %esi
f0104e4b:	5d                   	pop    %ebp
f0104e4c:	c3                   	ret    

f0104e4d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104e4d:	55                   	push   %ebp
f0104e4e:	89 e5                	mov    %esp,%ebp
f0104e50:	53                   	push   %ebx
f0104e51:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104e54:	89 c1                	mov    %eax,%ecx
f0104e56:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e59:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104e5d:	eb 0a                	jmp    f0104e69 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e5f:	0f b6 10             	movzbl (%eax),%edx
f0104e62:	39 da                	cmp    %ebx,%edx
f0104e64:	74 07                	je     f0104e6d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104e66:	83 c0 01             	add    $0x1,%eax
f0104e69:	39 c8                	cmp    %ecx,%eax
f0104e6b:	72 f2                	jb     f0104e5f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104e6d:	5b                   	pop    %ebx
f0104e6e:	5d                   	pop    %ebp
f0104e6f:	c3                   	ret    

f0104e70 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104e70:	55                   	push   %ebp
f0104e71:	89 e5                	mov    %esp,%ebp
f0104e73:	57                   	push   %edi
f0104e74:	56                   	push   %esi
f0104e75:	53                   	push   %ebx
f0104e76:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e79:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e7c:	eb 03                	jmp    f0104e81 <strtol+0x11>
		s++;
f0104e7e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e81:	0f b6 01             	movzbl (%ecx),%eax
f0104e84:	3c 20                	cmp    $0x20,%al
f0104e86:	74 f6                	je     f0104e7e <strtol+0xe>
f0104e88:	3c 09                	cmp    $0x9,%al
f0104e8a:	74 f2                	je     f0104e7e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e8c:	3c 2b                	cmp    $0x2b,%al
f0104e8e:	75 0a                	jne    f0104e9a <strtol+0x2a>
		s++;
f0104e90:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104e93:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e98:	eb 11                	jmp    f0104eab <strtol+0x3b>
f0104e9a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e9f:	3c 2d                	cmp    $0x2d,%al
f0104ea1:	75 08                	jne    f0104eab <strtol+0x3b>
		s++, neg = 1;
f0104ea3:	83 c1 01             	add    $0x1,%ecx
f0104ea6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104eab:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104eb1:	75 15                	jne    f0104ec8 <strtol+0x58>
f0104eb3:	80 39 30             	cmpb   $0x30,(%ecx)
f0104eb6:	75 10                	jne    f0104ec8 <strtol+0x58>
f0104eb8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104ebc:	75 7c                	jne    f0104f3a <strtol+0xca>
		s += 2, base = 16;
f0104ebe:	83 c1 02             	add    $0x2,%ecx
f0104ec1:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104ec6:	eb 16                	jmp    f0104ede <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104ec8:	85 db                	test   %ebx,%ebx
f0104eca:	75 12                	jne    f0104ede <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104ecc:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104ed1:	80 39 30             	cmpb   $0x30,(%ecx)
f0104ed4:	75 08                	jne    f0104ede <strtol+0x6e>
		s++, base = 8;
f0104ed6:	83 c1 01             	add    $0x1,%ecx
f0104ed9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104ede:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ee3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104ee6:	0f b6 11             	movzbl (%ecx),%edx
f0104ee9:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104eec:	89 f3                	mov    %esi,%ebx
f0104eee:	80 fb 09             	cmp    $0x9,%bl
f0104ef1:	77 08                	ja     f0104efb <strtol+0x8b>
			dig = *s - '0';
f0104ef3:	0f be d2             	movsbl %dl,%edx
f0104ef6:	83 ea 30             	sub    $0x30,%edx
f0104ef9:	eb 22                	jmp    f0104f1d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104efb:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104efe:	89 f3                	mov    %esi,%ebx
f0104f00:	80 fb 19             	cmp    $0x19,%bl
f0104f03:	77 08                	ja     f0104f0d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104f05:	0f be d2             	movsbl %dl,%edx
f0104f08:	83 ea 57             	sub    $0x57,%edx
f0104f0b:	eb 10                	jmp    f0104f1d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104f0d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104f10:	89 f3                	mov    %esi,%ebx
f0104f12:	80 fb 19             	cmp    $0x19,%bl
f0104f15:	77 16                	ja     f0104f2d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104f17:	0f be d2             	movsbl %dl,%edx
f0104f1a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104f1d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104f20:	7d 0b                	jge    f0104f2d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104f22:	83 c1 01             	add    $0x1,%ecx
f0104f25:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104f29:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104f2b:	eb b9                	jmp    f0104ee6 <strtol+0x76>

	if (endptr)
f0104f2d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104f31:	74 0d                	je     f0104f40 <strtol+0xd0>
		*endptr = (char *) s;
f0104f33:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104f36:	89 0e                	mov    %ecx,(%esi)
f0104f38:	eb 06                	jmp    f0104f40 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104f3a:	85 db                	test   %ebx,%ebx
f0104f3c:	74 98                	je     f0104ed6 <strtol+0x66>
f0104f3e:	eb 9e                	jmp    f0104ede <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104f40:	89 c2                	mov    %eax,%edx
f0104f42:	f7 da                	neg    %edx
f0104f44:	85 ff                	test   %edi,%edi
f0104f46:	0f 45 c2             	cmovne %edx,%eax
}
f0104f49:	5b                   	pop    %ebx
f0104f4a:	5e                   	pop    %esi
f0104f4b:	5f                   	pop    %edi
f0104f4c:	5d                   	pop    %ebp
f0104f4d:	c3                   	ret    
f0104f4e:	66 90                	xchg   %ax,%ax

f0104f50 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104f50:	fa                   	cli    

	xorw    %ax, %ax
f0104f51:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104f53:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104f55:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104f57:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104f59:	0f 01 16             	lgdtl  (%esi)
f0104f5c:	74 70                	je     f0104fce <mpsearch1+0x3>
	movl    %cr0, %eax
f0104f5e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104f61:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104f65:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104f68:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104f6e:	08 00                	or     %al,(%eax)

f0104f70 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104f70:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104f74:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104f76:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104f78:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104f7a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104f7e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104f80:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104f82:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104f87:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104f8a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104f8d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104f92:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104f95:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f9b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104fa0:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0104fa5:	ff d0                	call   *%eax

f0104fa7 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104fa7:	eb fe                	jmp    f0104fa7 <spin>
f0104fa9:	8d 76 00             	lea    0x0(%esi),%esi

f0104fac <gdt>:
	...
f0104fb4:	ff                   	(bad)  
f0104fb5:	ff 00                	incl   (%eax)
f0104fb7:	00 00                	add    %al,(%eax)
f0104fb9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104fc0:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0104fc4 <gdtdesc>:
f0104fc4:	17                   	pop    %ss
f0104fc5:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104fca <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104fca:	90                   	nop

f0104fcb <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104fcb:	55                   	push   %ebp
f0104fcc:	89 e5                	mov    %esp,%ebp
f0104fce:	57                   	push   %edi
f0104fcf:	56                   	push   %esi
f0104fd0:	53                   	push   %ebx
f0104fd1:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fd4:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104fda:	89 c3                	mov    %eax,%ebx
f0104fdc:	c1 eb 0c             	shr    $0xc,%ebx
f0104fdf:	39 cb                	cmp    %ecx,%ebx
f0104fe1:	72 12                	jb     f0104ff5 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104fe3:	50                   	push   %eax
f0104fe4:	68 24 5a 10 f0       	push   $0xf0105a24
f0104fe9:	6a 57                	push   $0x57
f0104feb:	68 a5 74 10 f0       	push   $0xf01074a5
f0104ff0:	e8 4b b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104ff5:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104ffb:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104ffd:	89 c2                	mov    %eax,%edx
f0104fff:	c1 ea 0c             	shr    $0xc,%edx
f0105002:	39 ca                	cmp    %ecx,%edx
f0105004:	72 12                	jb     f0105018 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105006:	50                   	push   %eax
f0105007:	68 24 5a 10 f0       	push   $0xf0105a24
f010500c:	6a 57                	push   $0x57
f010500e:	68 a5 74 10 f0       	push   $0xf01074a5
f0105013:	e8 28 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105018:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010501e:	eb 2f                	jmp    f010504f <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105020:	83 ec 04             	sub    $0x4,%esp
f0105023:	6a 04                	push   $0x4
f0105025:	68 b5 74 10 f0       	push   $0xf01074b5
f010502a:	53                   	push   %ebx
f010502b:	e8 e4 fd ff ff       	call   f0104e14 <memcmp>
f0105030:	83 c4 10             	add    $0x10,%esp
f0105033:	85 c0                	test   %eax,%eax
f0105035:	75 15                	jne    f010504c <mpsearch1+0x81>
f0105037:	89 da                	mov    %ebx,%edx
f0105039:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f010503c:	0f b6 0a             	movzbl (%edx),%ecx
f010503f:	01 c8                	add    %ecx,%eax
f0105041:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105044:	39 d7                	cmp    %edx,%edi
f0105046:	75 f4                	jne    f010503c <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105048:	84 c0                	test   %al,%al
f010504a:	74 0e                	je     f010505a <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f010504c:	83 c3 10             	add    $0x10,%ebx
f010504f:	39 f3                	cmp    %esi,%ebx
f0105051:	72 cd                	jb     f0105020 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105053:	b8 00 00 00 00       	mov    $0x0,%eax
f0105058:	eb 02                	jmp    f010505c <mpsearch1+0x91>
f010505a:	89 d8                	mov    %ebx,%eax
}
f010505c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010505f:	5b                   	pop    %ebx
f0105060:	5e                   	pop    %esi
f0105061:	5f                   	pop    %edi
f0105062:	5d                   	pop    %ebp
f0105063:	c3                   	ret    

f0105064 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105064:	55                   	push   %ebp
f0105065:	89 e5                	mov    %esp,%ebp
f0105067:	57                   	push   %edi
f0105068:	56                   	push   %esi
f0105069:	53                   	push   %ebx
f010506a:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f010506d:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0105074:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105077:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010507e:	75 16                	jne    f0105096 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105080:	68 00 04 00 00       	push   $0x400
f0105085:	68 24 5a 10 f0       	push   $0xf0105a24
f010508a:	6a 6f                	push   $0x6f
f010508c:	68 a5 74 10 f0       	push   $0xf01074a5
f0105091:	e8 aa af ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105096:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f010509d:	85 c0                	test   %eax,%eax
f010509f:	74 16                	je     f01050b7 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f01050a1:	c1 e0 04             	shl    $0x4,%eax
f01050a4:	ba 00 04 00 00       	mov    $0x400,%edx
f01050a9:	e8 1d ff ff ff       	call   f0104fcb <mpsearch1>
f01050ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01050b1:	85 c0                	test   %eax,%eax
f01050b3:	75 3c                	jne    f01050f1 <mp_init+0x8d>
f01050b5:	eb 20                	jmp    f01050d7 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f01050b7:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01050be:	c1 e0 0a             	shl    $0xa,%eax
f01050c1:	2d 00 04 00 00       	sub    $0x400,%eax
f01050c6:	ba 00 04 00 00       	mov    $0x400,%edx
f01050cb:	e8 fb fe ff ff       	call   f0104fcb <mpsearch1>
f01050d0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01050d3:	85 c0                	test   %eax,%eax
f01050d5:	75 1a                	jne    f01050f1 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01050d7:	ba 00 00 01 00       	mov    $0x10000,%edx
f01050dc:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01050e1:	e8 e5 fe ff ff       	call   f0104fcb <mpsearch1>
f01050e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01050e9:	85 c0                	test   %eax,%eax
f01050eb:	0f 84 5d 02 00 00    	je     f010534e <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01050f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050f4:	8b 70 04             	mov    0x4(%eax),%esi
f01050f7:	85 f6                	test   %esi,%esi
f01050f9:	74 06                	je     f0105101 <mp_init+0x9d>
f01050fb:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01050ff:	74 15                	je     f0105116 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105101:	83 ec 0c             	sub    $0xc,%esp
f0105104:	68 18 73 10 f0       	push   $0xf0107318
f0105109:	e8 7b e5 ff ff       	call   f0103689 <cprintf>
f010510e:	83 c4 10             	add    $0x10,%esp
f0105111:	e9 38 02 00 00       	jmp    f010534e <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105116:	89 f0                	mov    %esi,%eax
f0105118:	c1 e8 0c             	shr    $0xc,%eax
f010511b:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0105121:	72 15                	jb     f0105138 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105123:	56                   	push   %esi
f0105124:	68 24 5a 10 f0       	push   $0xf0105a24
f0105129:	68 90 00 00 00       	push   $0x90
f010512e:	68 a5 74 10 f0       	push   $0xf01074a5
f0105133:	e8 08 af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105138:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010513e:	83 ec 04             	sub    $0x4,%esp
f0105141:	6a 04                	push   $0x4
f0105143:	68 ba 74 10 f0       	push   $0xf01074ba
f0105148:	53                   	push   %ebx
f0105149:	e8 c6 fc ff ff       	call   f0104e14 <memcmp>
f010514e:	83 c4 10             	add    $0x10,%esp
f0105151:	85 c0                	test   %eax,%eax
f0105153:	74 15                	je     f010516a <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105155:	83 ec 0c             	sub    $0xc,%esp
f0105158:	68 48 73 10 f0       	push   $0xf0107348
f010515d:	e8 27 e5 ff ff       	call   f0103689 <cprintf>
f0105162:	83 c4 10             	add    $0x10,%esp
f0105165:	e9 e4 01 00 00       	jmp    f010534e <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010516a:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010516e:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105172:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105175:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010517a:	b8 00 00 00 00       	mov    $0x0,%eax
f010517f:	eb 0d                	jmp    f010518e <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105181:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105188:	f0 
f0105189:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010518b:	83 c0 01             	add    $0x1,%eax
f010518e:	39 c7                	cmp    %eax,%edi
f0105190:	75 ef                	jne    f0105181 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105192:	84 d2                	test   %dl,%dl
f0105194:	74 15                	je     f01051ab <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105196:	83 ec 0c             	sub    $0xc,%esp
f0105199:	68 7c 73 10 f0       	push   $0xf010737c
f010519e:	e8 e6 e4 ff ff       	call   f0103689 <cprintf>
f01051a3:	83 c4 10             	add    $0x10,%esp
f01051a6:	e9 a3 01 00 00       	jmp    f010534e <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f01051ab:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f01051af:	3c 01                	cmp    $0x1,%al
f01051b1:	74 1d                	je     f01051d0 <mp_init+0x16c>
f01051b3:	3c 04                	cmp    $0x4,%al
f01051b5:	74 19                	je     f01051d0 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01051b7:	83 ec 08             	sub    $0x8,%esp
f01051ba:	0f b6 c0             	movzbl %al,%eax
f01051bd:	50                   	push   %eax
f01051be:	68 a0 73 10 f0       	push   $0xf01073a0
f01051c3:	e8 c1 e4 ff ff       	call   f0103689 <cprintf>
f01051c8:	83 c4 10             	add    $0x10,%esp
f01051cb:	e9 7e 01 00 00       	jmp    f010534e <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01051d0:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01051d4:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01051d8:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01051dd:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01051e2:	01 ce                	add    %ecx,%esi
f01051e4:	eb 0d                	jmp    f01051f3 <mp_init+0x18f>
f01051e6:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01051ed:	f0 
f01051ee:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01051f0:	83 c0 01             	add    $0x1,%eax
f01051f3:	39 c7                	cmp    %eax,%edi
f01051f5:	75 ef                	jne    f01051e6 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01051f7:	89 d0                	mov    %edx,%eax
f01051f9:	02 43 2a             	add    0x2a(%ebx),%al
f01051fc:	74 15                	je     f0105213 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01051fe:	83 ec 0c             	sub    $0xc,%esp
f0105201:	68 c0 73 10 f0       	push   $0xf01073c0
f0105206:	e8 7e e4 ff ff       	call   f0103689 <cprintf>
f010520b:	83 c4 10             	add    $0x10,%esp
f010520e:	e9 3b 01 00 00       	jmp    f010534e <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105213:	85 db                	test   %ebx,%ebx
f0105215:	0f 84 33 01 00 00    	je     f010534e <mp_init+0x2ea>
		return;
	ismp = 1;
f010521b:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f0105222:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105225:	8b 43 24             	mov    0x24(%ebx),%eax
f0105228:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010522d:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105230:	be 00 00 00 00       	mov    $0x0,%esi
f0105235:	e9 85 00 00 00       	jmp    f01052bf <mp_init+0x25b>
		switch (*p) {
f010523a:	0f b6 07             	movzbl (%edi),%eax
f010523d:	84 c0                	test   %al,%al
f010523f:	74 06                	je     f0105247 <mp_init+0x1e3>
f0105241:	3c 04                	cmp    $0x4,%al
f0105243:	77 55                	ja     f010529a <mp_init+0x236>
f0105245:	eb 4e                	jmp    f0105295 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105247:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f010524b:	74 11                	je     f010525e <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f010524d:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0105254:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105259:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f010525e:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f0105263:	83 f8 07             	cmp    $0x7,%eax
f0105266:	7f 13                	jg     f010527b <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105268:	6b d0 74             	imul   $0x74,%eax,%edx
f010526b:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f0105271:	83 c0 01             	add    $0x1,%eax
f0105274:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f0105279:	eb 15                	jmp    f0105290 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f010527b:	83 ec 08             	sub    $0x8,%esp
f010527e:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105282:	50                   	push   %eax
f0105283:	68 f0 73 10 f0       	push   $0xf01073f0
f0105288:	e8 fc e3 ff ff       	call   f0103689 <cprintf>
f010528d:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105290:	83 c7 14             	add    $0x14,%edi
			continue;
f0105293:	eb 27                	jmp    f01052bc <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105295:	83 c7 08             	add    $0x8,%edi
			continue;
f0105298:	eb 22                	jmp    f01052bc <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010529a:	83 ec 08             	sub    $0x8,%esp
f010529d:	0f b6 c0             	movzbl %al,%eax
f01052a0:	50                   	push   %eax
f01052a1:	68 18 74 10 f0       	push   $0xf0107418
f01052a6:	e8 de e3 ff ff       	call   f0103689 <cprintf>
			ismp = 0;
f01052ab:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f01052b2:	00 00 00 
			i = conf->entry;
f01052b5:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f01052b9:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01052bc:	83 c6 01             	add    $0x1,%esi
f01052bf:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01052c3:	39 c6                	cmp    %eax,%esi
f01052c5:	0f 82 6f ff ff ff    	jb     f010523a <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01052cb:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f01052d0:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01052d7:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f01052de:	75 26                	jne    f0105306 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01052e0:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f01052e7:	00 00 00 
		lapicaddr = 0;
f01052ea:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f01052f1:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01052f4:	83 ec 0c             	sub    $0xc,%esp
f01052f7:	68 38 74 10 f0       	push   $0xf0107438
f01052fc:	e8 88 e3 ff ff       	call   f0103689 <cprintf>
		return;
f0105301:	83 c4 10             	add    $0x10,%esp
f0105304:	eb 48                	jmp    f010534e <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105306:	83 ec 04             	sub    $0x4,%esp
f0105309:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f010530f:	0f b6 00             	movzbl (%eax),%eax
f0105312:	50                   	push   %eax
f0105313:	68 bf 74 10 f0       	push   $0xf01074bf
f0105318:	e8 6c e3 ff ff       	call   f0103689 <cprintf>

	if (mp->imcrp) {
f010531d:	83 c4 10             	add    $0x10,%esp
f0105320:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105323:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105327:	74 25                	je     f010534e <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105329:	83 ec 0c             	sub    $0xc,%esp
f010532c:	68 64 74 10 f0       	push   $0xf0107464
f0105331:	e8 53 e3 ff ff       	call   f0103689 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105336:	ba 22 00 00 00       	mov    $0x22,%edx
f010533b:	b8 70 00 00 00       	mov    $0x70,%eax
f0105340:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105341:	ba 23 00 00 00       	mov    $0x23,%edx
f0105346:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105347:	83 c8 01             	or     $0x1,%eax
f010534a:	ee                   	out    %al,(%dx)
f010534b:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010534e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105351:	5b                   	pop    %ebx
f0105352:	5e                   	pop    %esi
f0105353:	5f                   	pop    %edi
f0105354:	5d                   	pop    %ebp
f0105355:	c3                   	ret    

f0105356 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105356:	55                   	push   %ebp
f0105357:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105359:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f010535f:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105362:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105364:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105369:	8b 40 20             	mov    0x20(%eax),%eax
}
f010536c:	5d                   	pop    %ebp
f010536d:	c3                   	ret    

f010536e <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010536e:	55                   	push   %ebp
f010536f:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105371:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105376:	85 c0                	test   %eax,%eax
f0105378:	74 08                	je     f0105382 <cpunum+0x14>
		return lapic[ID] >> 24;
f010537a:	8b 40 20             	mov    0x20(%eax),%eax
f010537d:	c1 e8 18             	shr    $0x18,%eax
f0105380:	eb 05                	jmp    f0105387 <cpunum+0x19>
	return 0;
f0105382:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105387:	5d                   	pop    %ebp
f0105388:	c3                   	ret    

f0105389 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105389:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f010538e:	85 c0                	test   %eax,%eax
f0105390:	0f 84 21 01 00 00    	je     f01054b7 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105396:	55                   	push   %ebp
f0105397:	89 e5                	mov    %esp,%ebp
f0105399:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f010539c:	68 00 10 00 00       	push   $0x1000
f01053a1:	50                   	push   %eax
f01053a2:	e8 6d be ff ff       	call   f0101214 <mmio_map_region>
f01053a7:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f01053ac:	ba 27 01 00 00       	mov    $0x127,%edx
f01053b1:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01053b6:	e8 9b ff ff ff       	call   f0105356 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f01053bb:	ba 0b 00 00 00       	mov    $0xb,%edx
f01053c0:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01053c5:	e8 8c ff ff ff       	call   f0105356 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01053ca:	ba 20 00 02 00       	mov    $0x20020,%edx
f01053cf:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01053d4:	e8 7d ff ff ff       	call   f0105356 <lapicw>
	lapicw(TICR, 10000000); 
f01053d9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01053de:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01053e3:	e8 6e ff ff ff       	call   f0105356 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01053e8:	e8 81 ff ff ff       	call   f010536e <cpunum>
f01053ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01053f0:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01053f5:	83 c4 10             	add    $0x10,%esp
f01053f8:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f01053fe:	74 0f                	je     f010540f <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105400:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105405:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010540a:	e8 47 ff ff ff       	call   f0105356 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010540f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105414:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105419:	e8 38 ff ff ff       	call   f0105356 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010541e:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105423:	8b 40 30             	mov    0x30(%eax),%eax
f0105426:	c1 e8 10             	shr    $0x10,%eax
f0105429:	3c 03                	cmp    $0x3,%al
f010542b:	76 0f                	jbe    f010543c <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f010542d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105432:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105437:	e8 1a ff ff ff       	call   f0105356 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f010543c:	ba 33 00 00 00       	mov    $0x33,%edx
f0105441:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105446:	e8 0b ff ff ff       	call   f0105356 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f010544b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105450:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105455:	e8 fc fe ff ff       	call   f0105356 <lapicw>
	lapicw(ESR, 0);
f010545a:	ba 00 00 00 00       	mov    $0x0,%edx
f010545f:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105464:	e8 ed fe ff ff       	call   f0105356 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105469:	ba 00 00 00 00       	mov    $0x0,%edx
f010546e:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105473:	e8 de fe ff ff       	call   f0105356 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105478:	ba 00 00 00 00       	mov    $0x0,%edx
f010547d:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105482:	e8 cf fe ff ff       	call   f0105356 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105487:	ba 00 85 08 00       	mov    $0x88500,%edx
f010548c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105491:	e8 c0 fe ff ff       	call   f0105356 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105496:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010549c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01054a2:	f6 c4 10             	test   $0x10,%ah
f01054a5:	75 f5                	jne    f010549c <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f01054a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01054ac:	b8 20 00 00 00       	mov    $0x20,%eax
f01054b1:	e8 a0 fe ff ff       	call   f0105356 <lapicw>
}
f01054b6:	c9                   	leave  
f01054b7:	f3 c3                	repz ret 

f01054b9 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01054b9:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f01054c0:	74 13                	je     f01054d5 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f01054c2:	55                   	push   %ebp
f01054c3:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f01054c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01054ca:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01054cf:	e8 82 fe ff ff       	call   f0105356 <lapicw>
}
f01054d4:	5d                   	pop    %ebp
f01054d5:	f3 c3                	repz ret 

f01054d7 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01054d7:	55                   	push   %ebp
f01054d8:	89 e5                	mov    %esp,%ebp
f01054da:	56                   	push   %esi
f01054db:	53                   	push   %ebx
f01054dc:	8b 75 08             	mov    0x8(%ebp),%esi
f01054df:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01054e2:	ba 70 00 00 00       	mov    $0x70,%edx
f01054e7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01054ec:	ee                   	out    %al,(%dx)
f01054ed:	ba 71 00 00 00       	mov    $0x71,%edx
f01054f2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01054f7:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054f8:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f01054ff:	75 19                	jne    f010551a <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105501:	68 67 04 00 00       	push   $0x467
f0105506:	68 24 5a 10 f0       	push   $0xf0105a24
f010550b:	68 98 00 00 00       	push   $0x98
f0105510:	68 dc 74 10 f0       	push   $0xf01074dc
f0105515:	e8 26 ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f010551a:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105521:	00 00 
	wrv[1] = addr >> 4;
f0105523:	89 d8                	mov    %ebx,%eax
f0105525:	c1 e8 04             	shr    $0x4,%eax
f0105528:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f010552e:	c1 e6 18             	shl    $0x18,%esi
f0105531:	89 f2                	mov    %esi,%edx
f0105533:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105538:	e8 19 fe ff ff       	call   f0105356 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f010553d:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105542:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105547:	e8 0a fe ff ff       	call   f0105356 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f010554c:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105551:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105556:	e8 fb fd ff ff       	call   f0105356 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010555b:	c1 eb 0c             	shr    $0xc,%ebx
f010555e:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105561:	89 f2                	mov    %esi,%edx
f0105563:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105568:	e8 e9 fd ff ff       	call   f0105356 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010556d:	89 da                	mov    %ebx,%edx
f010556f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105574:	e8 dd fd ff ff       	call   f0105356 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105579:	89 f2                	mov    %esi,%edx
f010557b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105580:	e8 d1 fd ff ff       	call   f0105356 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105585:	89 da                	mov    %ebx,%edx
f0105587:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010558c:	e8 c5 fd ff ff       	call   f0105356 <lapicw>
		microdelay(200);
	}
}
f0105591:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105594:	5b                   	pop    %ebx
f0105595:	5e                   	pop    %esi
f0105596:	5d                   	pop    %ebp
f0105597:	c3                   	ret    

f0105598 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105598:	55                   	push   %ebp
f0105599:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010559b:	8b 55 08             	mov    0x8(%ebp),%edx
f010559e:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01055a4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01055a9:	e8 a8 fd ff ff       	call   f0105356 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01055ae:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f01055b4:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01055ba:	f6 c4 10             	test   $0x10,%ah
f01055bd:	75 f5                	jne    f01055b4 <lapic_ipi+0x1c>
		;
}
f01055bf:	5d                   	pop    %ebp
f01055c0:	c3                   	ret    

f01055c1 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01055c1:	55                   	push   %ebp
f01055c2:	89 e5                	mov    %esp,%ebp
f01055c4:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01055c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01055cd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01055d0:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01055d3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01055da:	5d                   	pop    %ebp
f01055db:	c3                   	ret    

f01055dc <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01055dc:	55                   	push   %ebp
f01055dd:	89 e5                	mov    %esp,%ebp
f01055df:	56                   	push   %esi
f01055e0:	53                   	push   %ebx
f01055e1:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01055e4:	83 3b 00             	cmpl   $0x0,(%ebx)
f01055e7:	74 14                	je     f01055fd <spin_lock+0x21>
f01055e9:	8b 73 08             	mov    0x8(%ebx),%esi
f01055ec:	e8 7d fd ff ff       	call   f010536e <cpunum>
f01055f1:	6b c0 74             	imul   $0x74,%eax,%eax
f01055f4:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01055f9:	39 c6                	cmp    %eax,%esi
f01055fb:	74 07                	je     f0105604 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01055fd:	ba 01 00 00 00       	mov    $0x1,%edx
f0105602:	eb 20                	jmp    f0105624 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105604:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105607:	e8 62 fd ff ff       	call   f010536e <cpunum>
f010560c:	83 ec 0c             	sub    $0xc,%esp
f010560f:	53                   	push   %ebx
f0105610:	50                   	push   %eax
f0105611:	68 ec 74 10 f0       	push   $0xf01074ec
f0105616:	6a 41                	push   $0x41
f0105618:	68 50 75 10 f0       	push   $0xf0107550
f010561d:	e8 1e aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105622:	f3 90                	pause  
f0105624:	89 d0                	mov    %edx,%eax
f0105626:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105629:	85 c0                	test   %eax,%eax
f010562b:	75 f5                	jne    f0105622 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f010562d:	e8 3c fd ff ff       	call   f010536e <cpunum>
f0105632:	6b c0 74             	imul   $0x74,%eax,%eax
f0105635:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010563a:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f010563d:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105640:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105642:	b8 00 00 00 00       	mov    $0x0,%eax
f0105647:	eb 0b                	jmp    f0105654 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105649:	8b 4a 04             	mov    0x4(%edx),%ecx
f010564c:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f010564f:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105651:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105654:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010565a:	76 11                	jbe    f010566d <spin_lock+0x91>
f010565c:	83 f8 09             	cmp    $0x9,%eax
f010565f:	7e e8                	jle    f0105649 <spin_lock+0x6d>
f0105661:	eb 0a                	jmp    f010566d <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105663:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010566a:	83 c0 01             	add    $0x1,%eax
f010566d:	83 f8 09             	cmp    $0x9,%eax
f0105670:	7e f1                	jle    f0105663 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105672:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105675:	5b                   	pop    %ebx
f0105676:	5e                   	pop    %esi
f0105677:	5d                   	pop    %ebp
f0105678:	c3                   	ret    

f0105679 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105679:	55                   	push   %ebp
f010567a:	89 e5                	mov    %esp,%ebp
f010567c:	57                   	push   %edi
f010567d:	56                   	push   %esi
f010567e:	53                   	push   %ebx
f010567f:	83 ec 4c             	sub    $0x4c,%esp
f0105682:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105685:	83 3e 00             	cmpl   $0x0,(%esi)
f0105688:	74 18                	je     f01056a2 <spin_unlock+0x29>
f010568a:	8b 5e 08             	mov    0x8(%esi),%ebx
f010568d:	e8 dc fc ff ff       	call   f010536e <cpunum>
f0105692:	6b c0 74             	imul   $0x74,%eax,%eax
f0105695:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f010569a:	39 c3                	cmp    %eax,%ebx
f010569c:	0f 84 a5 00 00 00    	je     f0105747 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01056a2:	83 ec 04             	sub    $0x4,%esp
f01056a5:	6a 28                	push   $0x28
f01056a7:	8d 46 0c             	lea    0xc(%esi),%eax
f01056aa:	50                   	push   %eax
f01056ab:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01056ae:	53                   	push   %ebx
f01056af:	e8 e5 f6 ff ff       	call   f0104d99 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01056b4:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01056b7:	0f b6 38             	movzbl (%eax),%edi
f01056ba:	8b 76 04             	mov    0x4(%esi),%esi
f01056bd:	e8 ac fc ff ff       	call   f010536e <cpunum>
f01056c2:	57                   	push   %edi
f01056c3:	56                   	push   %esi
f01056c4:	50                   	push   %eax
f01056c5:	68 18 75 10 f0       	push   $0xf0107518
f01056ca:	e8 ba df ff ff       	call   f0103689 <cprintf>
f01056cf:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01056d2:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01056d5:	eb 54                	jmp    f010572b <spin_unlock+0xb2>
f01056d7:	83 ec 08             	sub    $0x8,%esp
f01056da:	57                   	push   %edi
f01056db:	50                   	push   %eax
f01056dc:	e8 0a ec ff ff       	call   f01042eb <debuginfo_eip>
f01056e1:	83 c4 10             	add    $0x10,%esp
f01056e4:	85 c0                	test   %eax,%eax
f01056e6:	78 27                	js     f010570f <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01056e8:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01056ea:	83 ec 04             	sub    $0x4,%esp
f01056ed:	89 c2                	mov    %eax,%edx
f01056ef:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01056f2:	52                   	push   %edx
f01056f3:	ff 75 b0             	pushl  -0x50(%ebp)
f01056f6:	ff 75 b4             	pushl  -0x4c(%ebp)
f01056f9:	ff 75 ac             	pushl  -0x54(%ebp)
f01056fc:	ff 75 a8             	pushl  -0x58(%ebp)
f01056ff:	50                   	push   %eax
f0105700:	68 60 75 10 f0       	push   $0xf0107560
f0105705:	e8 7f df ff ff       	call   f0103689 <cprintf>
f010570a:	83 c4 20             	add    $0x20,%esp
f010570d:	eb 12                	jmp    f0105721 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010570f:	83 ec 08             	sub    $0x8,%esp
f0105712:	ff 36                	pushl  (%esi)
f0105714:	68 77 75 10 f0       	push   $0xf0107577
f0105719:	e8 6b df ff ff       	call   f0103689 <cprintf>
f010571e:	83 c4 10             	add    $0x10,%esp
f0105721:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105724:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105727:	39 c3                	cmp    %eax,%ebx
f0105729:	74 08                	je     f0105733 <spin_unlock+0xba>
f010572b:	89 de                	mov    %ebx,%esi
f010572d:	8b 03                	mov    (%ebx),%eax
f010572f:	85 c0                	test   %eax,%eax
f0105731:	75 a4                	jne    f01056d7 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105733:	83 ec 04             	sub    $0x4,%esp
f0105736:	68 7f 75 10 f0       	push   $0xf010757f
f010573b:	6a 67                	push   $0x67
f010573d:	68 50 75 10 f0       	push   $0xf0107550
f0105742:	e8 f9 a8 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105747:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f010574e:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105755:	b8 00 00 00 00       	mov    $0x0,%eax
f010575a:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f010575d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105760:	5b                   	pop    %ebx
f0105761:	5e                   	pop    %esi
f0105762:	5f                   	pop    %edi
f0105763:	5d                   	pop    %ebp
f0105764:	c3                   	ret    
f0105765:	66 90                	xchg   %ax,%ax
f0105767:	66 90                	xchg   %ax,%ax
f0105769:	66 90                	xchg   %ax,%ax
f010576b:	66 90                	xchg   %ax,%ax
f010576d:	66 90                	xchg   %ax,%ax
f010576f:	90                   	nop

f0105770 <__udivdi3>:
f0105770:	55                   	push   %ebp
f0105771:	57                   	push   %edi
f0105772:	56                   	push   %esi
f0105773:	53                   	push   %ebx
f0105774:	83 ec 1c             	sub    $0x1c,%esp
f0105777:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010577b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010577f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105783:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105787:	85 f6                	test   %esi,%esi
f0105789:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010578d:	89 ca                	mov    %ecx,%edx
f010578f:	89 f8                	mov    %edi,%eax
f0105791:	75 3d                	jne    f01057d0 <__udivdi3+0x60>
f0105793:	39 cf                	cmp    %ecx,%edi
f0105795:	0f 87 c5 00 00 00    	ja     f0105860 <__udivdi3+0xf0>
f010579b:	85 ff                	test   %edi,%edi
f010579d:	89 fd                	mov    %edi,%ebp
f010579f:	75 0b                	jne    f01057ac <__udivdi3+0x3c>
f01057a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01057a6:	31 d2                	xor    %edx,%edx
f01057a8:	f7 f7                	div    %edi
f01057aa:	89 c5                	mov    %eax,%ebp
f01057ac:	89 c8                	mov    %ecx,%eax
f01057ae:	31 d2                	xor    %edx,%edx
f01057b0:	f7 f5                	div    %ebp
f01057b2:	89 c1                	mov    %eax,%ecx
f01057b4:	89 d8                	mov    %ebx,%eax
f01057b6:	89 cf                	mov    %ecx,%edi
f01057b8:	f7 f5                	div    %ebp
f01057ba:	89 c3                	mov    %eax,%ebx
f01057bc:	89 d8                	mov    %ebx,%eax
f01057be:	89 fa                	mov    %edi,%edx
f01057c0:	83 c4 1c             	add    $0x1c,%esp
f01057c3:	5b                   	pop    %ebx
f01057c4:	5e                   	pop    %esi
f01057c5:	5f                   	pop    %edi
f01057c6:	5d                   	pop    %ebp
f01057c7:	c3                   	ret    
f01057c8:	90                   	nop
f01057c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057d0:	39 ce                	cmp    %ecx,%esi
f01057d2:	77 74                	ja     f0105848 <__udivdi3+0xd8>
f01057d4:	0f bd fe             	bsr    %esi,%edi
f01057d7:	83 f7 1f             	xor    $0x1f,%edi
f01057da:	0f 84 98 00 00 00    	je     f0105878 <__udivdi3+0x108>
f01057e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01057e5:	89 f9                	mov    %edi,%ecx
f01057e7:	89 c5                	mov    %eax,%ebp
f01057e9:	29 fb                	sub    %edi,%ebx
f01057eb:	d3 e6                	shl    %cl,%esi
f01057ed:	89 d9                	mov    %ebx,%ecx
f01057ef:	d3 ed                	shr    %cl,%ebp
f01057f1:	89 f9                	mov    %edi,%ecx
f01057f3:	d3 e0                	shl    %cl,%eax
f01057f5:	09 ee                	or     %ebp,%esi
f01057f7:	89 d9                	mov    %ebx,%ecx
f01057f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01057fd:	89 d5                	mov    %edx,%ebp
f01057ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105803:	d3 ed                	shr    %cl,%ebp
f0105805:	89 f9                	mov    %edi,%ecx
f0105807:	d3 e2                	shl    %cl,%edx
f0105809:	89 d9                	mov    %ebx,%ecx
f010580b:	d3 e8                	shr    %cl,%eax
f010580d:	09 c2                	or     %eax,%edx
f010580f:	89 d0                	mov    %edx,%eax
f0105811:	89 ea                	mov    %ebp,%edx
f0105813:	f7 f6                	div    %esi
f0105815:	89 d5                	mov    %edx,%ebp
f0105817:	89 c3                	mov    %eax,%ebx
f0105819:	f7 64 24 0c          	mull   0xc(%esp)
f010581d:	39 d5                	cmp    %edx,%ebp
f010581f:	72 10                	jb     f0105831 <__udivdi3+0xc1>
f0105821:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105825:	89 f9                	mov    %edi,%ecx
f0105827:	d3 e6                	shl    %cl,%esi
f0105829:	39 c6                	cmp    %eax,%esi
f010582b:	73 07                	jae    f0105834 <__udivdi3+0xc4>
f010582d:	39 d5                	cmp    %edx,%ebp
f010582f:	75 03                	jne    f0105834 <__udivdi3+0xc4>
f0105831:	83 eb 01             	sub    $0x1,%ebx
f0105834:	31 ff                	xor    %edi,%edi
f0105836:	89 d8                	mov    %ebx,%eax
f0105838:	89 fa                	mov    %edi,%edx
f010583a:	83 c4 1c             	add    $0x1c,%esp
f010583d:	5b                   	pop    %ebx
f010583e:	5e                   	pop    %esi
f010583f:	5f                   	pop    %edi
f0105840:	5d                   	pop    %ebp
f0105841:	c3                   	ret    
f0105842:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105848:	31 ff                	xor    %edi,%edi
f010584a:	31 db                	xor    %ebx,%ebx
f010584c:	89 d8                	mov    %ebx,%eax
f010584e:	89 fa                	mov    %edi,%edx
f0105850:	83 c4 1c             	add    $0x1c,%esp
f0105853:	5b                   	pop    %ebx
f0105854:	5e                   	pop    %esi
f0105855:	5f                   	pop    %edi
f0105856:	5d                   	pop    %ebp
f0105857:	c3                   	ret    
f0105858:	90                   	nop
f0105859:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105860:	89 d8                	mov    %ebx,%eax
f0105862:	f7 f7                	div    %edi
f0105864:	31 ff                	xor    %edi,%edi
f0105866:	89 c3                	mov    %eax,%ebx
f0105868:	89 d8                	mov    %ebx,%eax
f010586a:	89 fa                	mov    %edi,%edx
f010586c:	83 c4 1c             	add    $0x1c,%esp
f010586f:	5b                   	pop    %ebx
f0105870:	5e                   	pop    %esi
f0105871:	5f                   	pop    %edi
f0105872:	5d                   	pop    %ebp
f0105873:	c3                   	ret    
f0105874:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105878:	39 ce                	cmp    %ecx,%esi
f010587a:	72 0c                	jb     f0105888 <__udivdi3+0x118>
f010587c:	31 db                	xor    %ebx,%ebx
f010587e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105882:	0f 87 34 ff ff ff    	ja     f01057bc <__udivdi3+0x4c>
f0105888:	bb 01 00 00 00       	mov    $0x1,%ebx
f010588d:	e9 2a ff ff ff       	jmp    f01057bc <__udivdi3+0x4c>
f0105892:	66 90                	xchg   %ax,%ax
f0105894:	66 90                	xchg   %ax,%ax
f0105896:	66 90                	xchg   %ax,%ax
f0105898:	66 90                	xchg   %ax,%ax
f010589a:	66 90                	xchg   %ax,%ax
f010589c:	66 90                	xchg   %ax,%ax
f010589e:	66 90                	xchg   %ax,%ax

f01058a0 <__umoddi3>:
f01058a0:	55                   	push   %ebp
f01058a1:	57                   	push   %edi
f01058a2:	56                   	push   %esi
f01058a3:	53                   	push   %ebx
f01058a4:	83 ec 1c             	sub    $0x1c,%esp
f01058a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01058ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01058af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01058b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01058b7:	85 d2                	test   %edx,%edx
f01058b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01058bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01058c1:	89 f3                	mov    %esi,%ebx
f01058c3:	89 3c 24             	mov    %edi,(%esp)
f01058c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01058ca:	75 1c                	jne    f01058e8 <__umoddi3+0x48>
f01058cc:	39 f7                	cmp    %esi,%edi
f01058ce:	76 50                	jbe    f0105920 <__umoddi3+0x80>
f01058d0:	89 c8                	mov    %ecx,%eax
f01058d2:	89 f2                	mov    %esi,%edx
f01058d4:	f7 f7                	div    %edi
f01058d6:	89 d0                	mov    %edx,%eax
f01058d8:	31 d2                	xor    %edx,%edx
f01058da:	83 c4 1c             	add    $0x1c,%esp
f01058dd:	5b                   	pop    %ebx
f01058de:	5e                   	pop    %esi
f01058df:	5f                   	pop    %edi
f01058e0:	5d                   	pop    %ebp
f01058e1:	c3                   	ret    
f01058e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01058e8:	39 f2                	cmp    %esi,%edx
f01058ea:	89 d0                	mov    %edx,%eax
f01058ec:	77 52                	ja     f0105940 <__umoddi3+0xa0>
f01058ee:	0f bd ea             	bsr    %edx,%ebp
f01058f1:	83 f5 1f             	xor    $0x1f,%ebp
f01058f4:	75 5a                	jne    f0105950 <__umoddi3+0xb0>
f01058f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01058fa:	0f 82 e0 00 00 00    	jb     f01059e0 <__umoddi3+0x140>
f0105900:	39 0c 24             	cmp    %ecx,(%esp)
f0105903:	0f 86 d7 00 00 00    	jbe    f01059e0 <__umoddi3+0x140>
f0105909:	8b 44 24 08          	mov    0x8(%esp),%eax
f010590d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105911:	83 c4 1c             	add    $0x1c,%esp
f0105914:	5b                   	pop    %ebx
f0105915:	5e                   	pop    %esi
f0105916:	5f                   	pop    %edi
f0105917:	5d                   	pop    %ebp
f0105918:	c3                   	ret    
f0105919:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105920:	85 ff                	test   %edi,%edi
f0105922:	89 fd                	mov    %edi,%ebp
f0105924:	75 0b                	jne    f0105931 <__umoddi3+0x91>
f0105926:	b8 01 00 00 00       	mov    $0x1,%eax
f010592b:	31 d2                	xor    %edx,%edx
f010592d:	f7 f7                	div    %edi
f010592f:	89 c5                	mov    %eax,%ebp
f0105931:	89 f0                	mov    %esi,%eax
f0105933:	31 d2                	xor    %edx,%edx
f0105935:	f7 f5                	div    %ebp
f0105937:	89 c8                	mov    %ecx,%eax
f0105939:	f7 f5                	div    %ebp
f010593b:	89 d0                	mov    %edx,%eax
f010593d:	eb 99                	jmp    f01058d8 <__umoddi3+0x38>
f010593f:	90                   	nop
f0105940:	89 c8                	mov    %ecx,%eax
f0105942:	89 f2                	mov    %esi,%edx
f0105944:	83 c4 1c             	add    $0x1c,%esp
f0105947:	5b                   	pop    %ebx
f0105948:	5e                   	pop    %esi
f0105949:	5f                   	pop    %edi
f010594a:	5d                   	pop    %ebp
f010594b:	c3                   	ret    
f010594c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105950:	8b 34 24             	mov    (%esp),%esi
f0105953:	bf 20 00 00 00       	mov    $0x20,%edi
f0105958:	89 e9                	mov    %ebp,%ecx
f010595a:	29 ef                	sub    %ebp,%edi
f010595c:	d3 e0                	shl    %cl,%eax
f010595e:	89 f9                	mov    %edi,%ecx
f0105960:	89 f2                	mov    %esi,%edx
f0105962:	d3 ea                	shr    %cl,%edx
f0105964:	89 e9                	mov    %ebp,%ecx
f0105966:	09 c2                	or     %eax,%edx
f0105968:	89 d8                	mov    %ebx,%eax
f010596a:	89 14 24             	mov    %edx,(%esp)
f010596d:	89 f2                	mov    %esi,%edx
f010596f:	d3 e2                	shl    %cl,%edx
f0105971:	89 f9                	mov    %edi,%ecx
f0105973:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105977:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010597b:	d3 e8                	shr    %cl,%eax
f010597d:	89 e9                	mov    %ebp,%ecx
f010597f:	89 c6                	mov    %eax,%esi
f0105981:	d3 e3                	shl    %cl,%ebx
f0105983:	89 f9                	mov    %edi,%ecx
f0105985:	89 d0                	mov    %edx,%eax
f0105987:	d3 e8                	shr    %cl,%eax
f0105989:	89 e9                	mov    %ebp,%ecx
f010598b:	09 d8                	or     %ebx,%eax
f010598d:	89 d3                	mov    %edx,%ebx
f010598f:	89 f2                	mov    %esi,%edx
f0105991:	f7 34 24             	divl   (%esp)
f0105994:	89 d6                	mov    %edx,%esi
f0105996:	d3 e3                	shl    %cl,%ebx
f0105998:	f7 64 24 04          	mull   0x4(%esp)
f010599c:	39 d6                	cmp    %edx,%esi
f010599e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01059a2:	89 d1                	mov    %edx,%ecx
f01059a4:	89 c3                	mov    %eax,%ebx
f01059a6:	72 08                	jb     f01059b0 <__umoddi3+0x110>
f01059a8:	75 11                	jne    f01059bb <__umoddi3+0x11b>
f01059aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01059ae:	73 0b                	jae    f01059bb <__umoddi3+0x11b>
f01059b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01059b4:	1b 14 24             	sbb    (%esp),%edx
f01059b7:	89 d1                	mov    %edx,%ecx
f01059b9:	89 c3                	mov    %eax,%ebx
f01059bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01059bf:	29 da                	sub    %ebx,%edx
f01059c1:	19 ce                	sbb    %ecx,%esi
f01059c3:	89 f9                	mov    %edi,%ecx
f01059c5:	89 f0                	mov    %esi,%eax
f01059c7:	d3 e0                	shl    %cl,%eax
f01059c9:	89 e9                	mov    %ebp,%ecx
f01059cb:	d3 ea                	shr    %cl,%edx
f01059cd:	89 e9                	mov    %ebp,%ecx
f01059cf:	d3 ee                	shr    %cl,%esi
f01059d1:	09 d0                	or     %edx,%eax
f01059d3:	89 f2                	mov    %esi,%edx
f01059d5:	83 c4 1c             	add    $0x1c,%esp
f01059d8:	5b                   	pop    %ebx
f01059d9:	5e                   	pop    %esi
f01059da:	5f                   	pop    %edi
f01059db:	5d                   	pop    %ebp
f01059dc:	c3                   	ret    
f01059dd:	8d 76 00             	lea    0x0(%esi),%esi
f01059e0:	29 f9                	sub    %edi,%ecx
f01059e2:	19 d6                	sbb    %edx,%esi
f01059e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01059e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01059ec:	e9 18 ff ff ff       	jmp    f0105909 <__umoddi3+0x69>
