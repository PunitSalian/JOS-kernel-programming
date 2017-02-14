
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 cd 17 f0       	mov    $0xf017cd50,%eax
f010004b:	2d 2a be 17 f0       	sub    $0xf017be2a,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 2a be 17 f0       	push   $0xf017be2a
f0100058:	e8 18 3e 00 00       	call   f0103e75 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 43 10 f0       	push   $0xf0104320
f010006f:	e8 bc 2d 00 00       	call   f0102e30 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 52 0f 00 00       	call   f0100fcb <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 89 27 00 00       	call   f0102807 <env_init>
	trap_init();
f010007e:	e8 1e 2e 00 00       	call   f0102ea1 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 66 0c 13 f0       	push   $0xf0130c66
f010008d:	e8 59 29 00 00       	call   f01029eb <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 c0 17 f0    	pushl  0xf017c084
f010009b:	e8 af 2c 00 00       	call   f0102d4f <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 cd 17 f0 00 	cmpl   $0x0,0xf017cd40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 cd 17 f0    	mov    %esi,0xf017cd40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 3b 43 10 f0       	push   $0xf010433b
f01000ca:	e8 61 2d 00 00       	call   f0102e30 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 31 2d 00 00       	call   f0102e0a <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 df 52 10 f0 	movl   $0xf01052df,(%esp)
f01000e0:	e8 4b 2d 00 00       	call   f0102e30 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 40 06 00 00       	call   f0100732 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 53 43 10 f0       	push   $0xf0104353
f010010c:	e8 1f 2d 00 00       	call   f0102e30 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 ed 2c 00 00       	call   f0102e0a <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 df 52 10 f0 	movl   $0xf01052df,(%esp)
f0100124:	e8 07 2d 00 00       	call   f0102e30 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 c0 17 f0    	mov    0xf017c064,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 c0 17 f0    	mov    %edx,0xf017c064
f010016e:	88 81 60 be 17 f0    	mov    %al,-0xfe841a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 c0 17 f0 00 	movl   $0x0,0xf017c064
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 be 17 f0 40 	orl    $0x40,0xf017be40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 be 17 f0    	mov    0xf017be40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 c0 44 10 f0 	movzbl -0xfefbb40(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 be 17 f0       	mov    %eax,0xf017be40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 be 17 f0    	mov    0xf017be40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 be 17 f0    	mov    %ecx,0xf017be40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 c0 44 10 f0 	movzbl -0xfefbb40(%edx),%eax
f0100226:	0b 05 40 be 17 f0    	or     0xf017be40,%eax
f010022c:	0f b6 8a c0 43 10 f0 	movzbl -0xfefbc40(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 be 17 f0       	mov    %eax,0xf017be40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d a0 43 10 f0 	mov    -0xfefbc60(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 6d 43 10 f0       	push   $0xf010436d
f0100282:	e8 a9 2b 00 00       	call   f0102e30 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 c0 17 f0 	movzwl 0xf017c068,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 c0 17 f0    	mov    %ax,0xf017c068
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c c0 17 f0    	mov    0xf017c06c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 c0 17 f0 	addw   $0x50,0xf017c068
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 c0 17 f0 	movzwl 0xf017c068,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 c0 17 f0    	mov    %ax,0xf017c068
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 c0 17 f0 	movzwl 0xf017c068,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 c0 17 f0 	mov    %dx,0xf017c068
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c c0 17 f0    	mov    0xf017c06c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 c0 17 f0 	cmpw   $0x7cf,0xf017c068
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c c0 17 f0       	mov    0xf017c06c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 8c 3a 00 00       	call   f0103ec2 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c c0 17 f0    	mov    0xf017c06c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 c0 17 f0 	subw   $0x50,0xf017c068
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 c0 17 f0    	mov    0xf017c070,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 c0 17 f0 	movzwl 0xf017c068,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 c0 17 f0 00 	cmpb   $0x0,0xf017c074
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 c0 17 f0       	mov    0xf017c060,%eax
f01004d8:	3b 05 64 c0 17 f0    	cmp    0xf017c064,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 c0 17 f0    	mov    %edx,0xf017c060
f01004e9:	0f b6 88 60 be 17 f0 	movzbl -0xfe841a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 c0 17 f0 00 	movl   $0x0,0xf017c060
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 c0 17 f0 b4 	movl   $0x3b4,0xf017c070
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 c0 17 f0 d4 	movl   $0x3d4,0xf017c070
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 c0 17 f0    	mov    0xf017c070,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c c0 17 f0    	mov    %esi,0xf017c06c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 c0 17 f0    	mov    %ax,0xf017c068
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 c0 17 f0 	setne  0xf017c074
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 79 43 10 f0       	push   $0xf0104379
f0100605:	e8 26 28 00 00       	call   f0102e30 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 c0 45 10 f0       	push   $0xf01045c0
f010064b:	68 de 45 10 f0       	push   $0xf01045de
f0100650:	68 e3 45 10 f0       	push   $0xf01045e3
f0100655:	e8 d6 27 00 00       	call   f0102e30 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 4c 46 10 f0       	push   $0xf010464c
f0100662:	68 ec 45 10 f0       	push   $0xf01045ec
f0100667:	68 e3 45 10 f0       	push   $0xf01045e3
f010066c:	e8 bf 27 00 00       	call   f0102e30 <cprintf>
	return 0;
}
f0100671:	b8 00 00 00 00       	mov    $0x0,%eax
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067e:	68 f5 45 10 f0       	push   $0xf01045f5
f0100683:	e8 a8 27 00 00       	call   f0102e30 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 74 46 10 f0       	push   $0xf0104674
f0100695:	e8 96 27 00 00       	call   f0102e30 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 9c 46 10 f0       	push   $0xf010469c
f01006ac:	e8 7f 27 00 00       	call   f0102e30 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 01 43 10 00       	push   $0x104301
f01006b9:	68 01 43 10 f0       	push   $0xf0104301
f01006be:	68 c0 46 10 f0       	push   $0xf01046c0
f01006c3:	e8 68 27 00 00       	call   f0102e30 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 2a be 17 00       	push   $0x17be2a
f01006d0:	68 2a be 17 f0       	push   $0xf017be2a
f01006d5:	68 e4 46 10 f0       	push   $0xf01046e4
f01006da:	e8 51 27 00 00       	call   f0102e30 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 50 cd 17 00       	push   $0x17cd50
f01006e7:	68 50 cd 17 f0       	push   $0xf017cd50
f01006ec:	68 08 47 10 f0       	push   $0xf0104708
f01006f1:	e8 3a 27 00 00       	call   f0102e30 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 4f d1 17 f0       	mov    $0xf017d14f,%eax
f01006fb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100700:	83 c4 08             	add    $0x8,%esp
f0100703:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100708:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010070e:	85 c0                	test   %eax,%eax
f0100710:	0f 48 c2             	cmovs  %edx,%eax
f0100713:	c1 f8 0a             	sar    $0xa,%eax
f0100716:	50                   	push   %eax
f0100717:	68 2c 47 10 f0       	push   $0xf010472c
f010071c:	e8 0f 27 00 00       	call   f0102e30 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	c9                   	leave  
f0100727:	c3                   	ret    

f0100728 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010072b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100730:	5d                   	pop    %ebp
f0100731:	c3                   	ret    

f0100732 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100732:	55                   	push   %ebp
f0100733:	89 e5                	mov    %esp,%ebp
f0100735:	57                   	push   %edi
f0100736:	56                   	push   %esi
f0100737:	53                   	push   %ebx
f0100738:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010073b:	68 58 47 10 f0       	push   $0xf0104758
f0100740:	e8 eb 26 00 00       	call   f0102e30 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100745:	c7 04 24 7c 47 10 f0 	movl   $0xf010477c,(%esp)
f010074c:	e8 df 26 00 00       	call   f0102e30 <cprintf>

	if (tf != NULL)
f0100751:	83 c4 10             	add    $0x10,%esp
f0100754:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100758:	74 0e                	je     f0100768 <monitor+0x36>
		print_trapframe(tf);
f010075a:	83 ec 0c             	sub    $0xc,%esp
f010075d:	ff 75 08             	pushl  0x8(%ebp)
f0100760:	e8 15 28 00 00       	call   f0102f7a <print_trapframe>
f0100765:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100768:	83 ec 0c             	sub    $0xc,%esp
f010076b:	68 0e 46 10 f0       	push   $0xf010460e
f0100770:	e8 a9 34 00 00       	call   f0103c1e <readline>
f0100775:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100777:	83 c4 10             	add    $0x10,%esp
f010077a:	85 c0                	test   %eax,%eax
f010077c:	74 ea                	je     f0100768 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010077e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100785:	be 00 00 00 00       	mov    $0x0,%esi
f010078a:	eb 0a                	jmp    f0100796 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010078c:	c6 03 00             	movb   $0x0,(%ebx)
f010078f:	89 f7                	mov    %esi,%edi
f0100791:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100794:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100796:	0f b6 03             	movzbl (%ebx),%eax
f0100799:	84 c0                	test   %al,%al
f010079b:	74 63                	je     f0100800 <monitor+0xce>
f010079d:	83 ec 08             	sub    $0x8,%esp
f01007a0:	0f be c0             	movsbl %al,%eax
f01007a3:	50                   	push   %eax
f01007a4:	68 12 46 10 f0       	push   $0xf0104612
f01007a9:	e8 8a 36 00 00       	call   f0103e38 <strchr>
f01007ae:	83 c4 10             	add    $0x10,%esp
f01007b1:	85 c0                	test   %eax,%eax
f01007b3:	75 d7                	jne    f010078c <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01007b5:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007b8:	74 46                	je     f0100800 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007ba:	83 fe 0f             	cmp    $0xf,%esi
f01007bd:	75 14                	jne    f01007d3 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007bf:	83 ec 08             	sub    $0x8,%esp
f01007c2:	6a 10                	push   $0x10
f01007c4:	68 17 46 10 f0       	push   $0xf0104617
f01007c9:	e8 62 26 00 00       	call   f0102e30 <cprintf>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	eb 95                	jmp    f0100768 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01007d3:	8d 7e 01             	lea    0x1(%esi),%edi
f01007d6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007da:	eb 03                	jmp    f01007df <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007dc:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007df:	0f b6 03             	movzbl (%ebx),%eax
f01007e2:	84 c0                	test   %al,%al
f01007e4:	74 ae                	je     f0100794 <monitor+0x62>
f01007e6:	83 ec 08             	sub    $0x8,%esp
f01007e9:	0f be c0             	movsbl %al,%eax
f01007ec:	50                   	push   %eax
f01007ed:	68 12 46 10 f0       	push   $0xf0104612
f01007f2:	e8 41 36 00 00       	call   f0103e38 <strchr>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 de                	je     f01007dc <monitor+0xaa>
f01007fe:	eb 94                	jmp    f0100794 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100800:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100807:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100808:	85 f6                	test   %esi,%esi
f010080a:	0f 84 58 ff ff ff    	je     f0100768 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	68 de 45 10 f0       	push   $0xf01045de
f0100818:	ff 75 a8             	pushl  -0x58(%ebp)
f010081b:	e8 ba 35 00 00       	call   f0103dda <strcmp>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 1e                	je     f0100845 <monitor+0x113>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	68 ec 45 10 f0       	push   $0xf01045ec
f010082f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100832:	e8 a3 35 00 00       	call   f0103dda <strcmp>
f0100837:	83 c4 10             	add    $0x10,%esp
f010083a:	85 c0                	test   %eax,%eax
f010083c:	75 2f                	jne    f010086d <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010083e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100843:	eb 05                	jmp    f010084a <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100845:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010084a:	83 ec 04             	sub    $0x4,%esp
f010084d:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100850:	01 d0                	add    %edx,%eax
f0100852:	ff 75 08             	pushl  0x8(%ebp)
f0100855:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100858:	51                   	push   %ecx
f0100859:	56                   	push   %esi
f010085a:	ff 14 85 ac 47 10 f0 	call   *-0xfefb854(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	78 1d                	js     f0100885 <monitor+0x153>
f0100868:	e9 fb fe ff ff       	jmp    f0100768 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010086d:	83 ec 08             	sub    $0x8,%esp
f0100870:	ff 75 a8             	pushl  -0x58(%ebp)
f0100873:	68 34 46 10 f0       	push   $0xf0104634
f0100878:	e8 b3 25 00 00       	call   f0102e30 <cprintf>
f010087d:	83 c4 10             	add    $0x10,%esp
f0100880:	e9 e3 fe ff ff       	jmp    f0100768 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100885:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100888:	5b                   	pop    %ebx
f0100889:	5e                   	pop    %esi
f010088a:	5f                   	pop    %edi
f010088b:	5d                   	pop    %ebp
f010088c:	c3                   	ret    

f010088d <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010088d:	55                   	push   %ebp
f010088e:	89 e5                	mov    %esp,%ebp
f0100890:	56                   	push   %esi
f0100891:	53                   	push   %ebx
f0100892:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100894:	83 ec 0c             	sub    $0xc,%esp
f0100897:	50                   	push   %eax
f0100898:	e8 2c 25 00 00       	call   f0102dc9 <mc146818_read>
f010089d:	89 c6                	mov    %eax,%esi
f010089f:	83 c3 01             	add    $0x1,%ebx
f01008a2:	89 1c 24             	mov    %ebx,(%esp)
f01008a5:	e8 1f 25 00 00       	call   f0102dc9 <mc146818_read>
f01008aa:	c1 e0 08             	shl    $0x8,%eax
f01008ad:	09 f0                	or     %esi,%eax
}
f01008af:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008b2:	5b                   	pop    %ebx
f01008b3:	5e                   	pop    %esi
f01008b4:	5d                   	pop    %ebp
f01008b5:	c3                   	ret    

f01008b6 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008b6:	83 3d 78 c0 17 f0 00 	cmpl   $0x0,0xf017c078
f01008bd:	75 11                	jne    f01008d0 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008bf:	ba 4f dd 17 f0       	mov    $0xf017dd4f,%edx
f01008c4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008ca:	89 15 78 c0 17 f0    	mov    %edx,0xf017c078
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f01008d0:	85 c0                	test   %eax,%eax
f01008d2:	74 2e                	je     f0100902 <boot_alloc+0x4c>
	{
	result=nextfree;
f01008d4:	8b 0d 78 c0 17 f0    	mov    0xf017c078,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f01008da:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01008e0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008e6:	01 ca                	add    %ecx,%edx
f01008e8:	89 15 78 c0 17 f0    	mov    %edx,0xf017c078
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f01008ee:	a1 44 cd 17 f0       	mov    0xf017cd44,%eax
f01008f3:	05 00 00 0f 00       	add    $0xf0000,%eax
f01008f8:	c1 e0 0c             	shl    $0xc,%eax
f01008fb:	39 c2                	cmp    %eax,%edx
f01008fd:	77 09                	ja     f0100908 <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f01008ff:	89 c8                	mov    %ecx,%eax
f0100901:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f0100902:	a1 78 c0 17 f0       	mov    0xf017c078,%eax
f0100907:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100908:	55                   	push   %ebp
f0100909:	89 e5                	mov    %esp,%ebp
f010090b:	83 ec 0c             	sub    $0xc,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f010090e:	68 bc 47 10 f0       	push   $0xf01047bc
f0100913:	6a 7a                	push   $0x7a
f0100915:	68 cc 47 10 f0       	push   $0xf01047cc
f010091a:	e8 81 f7 ff ff       	call   f01000a0 <_panic>

f010091f <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010091f:	89 d1                	mov    %edx,%ecx
f0100921:	c1 e9 16             	shr    $0x16,%ecx
f0100924:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100927:	a8 01                	test   $0x1,%al
f0100929:	74 52                	je     f010097d <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010092b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100930:	89 c1                	mov    %eax,%ecx
f0100932:	c1 e9 0c             	shr    $0xc,%ecx
f0100935:	3b 0d 44 cd 17 f0    	cmp    0xf017cd44,%ecx
f010093b:	72 1b                	jb     f0100958 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100943:	50                   	push   %eax
f0100944:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100949:	68 34 03 00 00       	push   $0x334
f010094e:	68 cc 47 10 f0       	push   $0xf01047cc
f0100953:	e8 48 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100958:	c1 ea 0c             	shr    $0xc,%edx
f010095b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100961:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100968:	89 c2                	mov    %eax,%edx
f010096a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010096d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100972:	85 d2                	test   %edx,%edx
f0100974:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100979:	0f 44 c2             	cmove  %edx,%eax
f010097c:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010097d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100982:	c3                   	ret    

f0100983 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010098c:	84 c0                	test   %al,%al
f010098e:	0f 85 72 02 00 00    	jne    f0100c06 <check_page_free_list+0x283>
f0100994:	e9 7f 02 00 00       	jmp    f0100c18 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100999:	83 ec 04             	sub    $0x4,%esp
f010099c:	68 e8 4a 10 f0       	push   $0xf0104ae8
f01009a1:	68 72 02 00 00       	push   $0x272
f01009a6:	68 cc 47 10 f0       	push   $0xf01047cc
f01009ab:	e8 f0 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009b0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009b3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009b6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009bc:	89 c2                	mov    %eax,%edx
f01009be:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f01009c4:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009ca:	0f 95 c2             	setne  %dl
f01009cd:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009d0:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009d4:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009d6:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009da:	8b 00                	mov    (%eax),%eax
f01009dc:	85 c0                	test   %eax,%eax
f01009de:	75 dc                	jne    f01009bc <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009e3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009ec:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009ef:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009f4:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f9:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009fe:	8b 1d 7c c0 17 f0    	mov    0xf017c07c,%ebx
f0100a04:	eb 53                	jmp    f0100a59 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a06:	89 d8                	mov    %ebx,%eax
f0100a08:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0100a0e:	c1 f8 03             	sar    $0x3,%eax
f0100a11:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a14:	89 c2                	mov    %eax,%edx
f0100a16:	c1 ea 16             	shr    $0x16,%edx
f0100a19:	39 f2                	cmp    %esi,%edx
f0100a1b:	73 3a                	jae    f0100a57 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a1d:	89 c2                	mov    %eax,%edx
f0100a1f:	c1 ea 0c             	shr    $0xc,%edx
f0100a22:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f0100a28:	72 12                	jb     f0100a3c <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a2a:	50                   	push   %eax
f0100a2b:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100a30:	6a 56                	push   $0x56
f0100a32:	68 d8 47 10 f0       	push   $0xf01047d8
f0100a37:	e8 64 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a3c:	83 ec 04             	sub    $0x4,%esp
f0100a3f:	68 80 00 00 00       	push   $0x80
f0100a44:	68 97 00 00 00       	push   $0x97
f0100a49:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a4e:	50                   	push   %eax
f0100a4f:	e8 21 34 00 00       	call   f0103e75 <memset>
f0100a54:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a57:	8b 1b                	mov    (%ebx),%ebx
f0100a59:	85 db                	test   %ebx,%ebx
f0100a5b:	75 a9                	jne    f0100a06 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a62:	e8 4f fe ff ff       	call   f01008b6 <boot_alloc>
f0100a67:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a6a:	8b 15 7c c0 17 f0    	mov    0xf017c07c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a70:	8b 0d 4c cd 17 f0    	mov    0xf017cd4c,%ecx
		assert(pp < pages + npages);
f0100a76:	a1 44 cd 17 f0       	mov    0xf017cd44,%eax
f0100a7b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a7e:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a81:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a84:	be 00 00 00 00       	mov    $0x0,%esi
f0100a89:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8c:	e9 30 01 00 00       	jmp    f0100bc1 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a91:	39 ca                	cmp    %ecx,%edx
f0100a93:	73 19                	jae    f0100aae <check_page_free_list+0x12b>
f0100a95:	68 e6 47 10 f0       	push   $0xf01047e6
f0100a9a:	68 f2 47 10 f0       	push   $0xf01047f2
f0100a9f:	68 8c 02 00 00       	push   $0x28c
f0100aa4:	68 cc 47 10 f0       	push   $0xf01047cc
f0100aa9:	e8 f2 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100aae:	39 fa                	cmp    %edi,%edx
f0100ab0:	72 19                	jb     f0100acb <check_page_free_list+0x148>
f0100ab2:	68 07 48 10 f0       	push   $0xf0104807
f0100ab7:	68 f2 47 10 f0       	push   $0xf01047f2
f0100abc:	68 8d 02 00 00       	push   $0x28d
f0100ac1:	68 cc 47 10 f0       	push   $0xf01047cc
f0100ac6:	e8 d5 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100acb:	89 d0                	mov    %edx,%eax
f0100acd:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ad0:	a8 07                	test   $0x7,%al
f0100ad2:	74 19                	je     f0100aed <check_page_free_list+0x16a>
f0100ad4:	68 0c 4b 10 f0       	push   $0xf0104b0c
f0100ad9:	68 f2 47 10 f0       	push   $0xf01047f2
f0100ade:	68 8e 02 00 00       	push   $0x28e
f0100ae3:	68 cc 47 10 f0       	push   $0xf01047cc
f0100ae8:	e8 b3 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aed:	c1 f8 03             	sar    $0x3,%eax
f0100af0:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100af3:	85 c0                	test   %eax,%eax
f0100af5:	75 19                	jne    f0100b10 <check_page_free_list+0x18d>
f0100af7:	68 1b 48 10 f0       	push   $0xf010481b
f0100afc:	68 f2 47 10 f0       	push   $0xf01047f2
f0100b01:	68 91 02 00 00       	push   $0x291
f0100b06:	68 cc 47 10 f0       	push   $0xf01047cc
f0100b0b:	e8 90 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b10:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b15:	75 19                	jne    f0100b30 <check_page_free_list+0x1ad>
f0100b17:	68 2c 48 10 f0       	push   $0xf010482c
f0100b1c:	68 f2 47 10 f0       	push   $0xf01047f2
f0100b21:	68 92 02 00 00       	push   $0x292
f0100b26:	68 cc 47 10 f0       	push   $0xf01047cc
f0100b2b:	e8 70 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b30:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b35:	75 19                	jne    f0100b50 <check_page_free_list+0x1cd>
f0100b37:	68 40 4b 10 f0       	push   $0xf0104b40
f0100b3c:	68 f2 47 10 f0       	push   $0xf01047f2
f0100b41:	68 93 02 00 00       	push   $0x293
f0100b46:	68 cc 47 10 f0       	push   $0xf01047cc
f0100b4b:	e8 50 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b50:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b55:	75 19                	jne    f0100b70 <check_page_free_list+0x1ed>
f0100b57:	68 45 48 10 f0       	push   $0xf0104845
f0100b5c:	68 f2 47 10 f0       	push   $0xf01047f2
f0100b61:	68 94 02 00 00       	push   $0x294
f0100b66:	68 cc 47 10 f0       	push   $0xf01047cc
f0100b6b:	e8 30 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b70:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b75:	76 3f                	jbe    f0100bb6 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b77:	89 c3                	mov    %eax,%ebx
f0100b79:	c1 eb 0c             	shr    $0xc,%ebx
f0100b7c:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b7f:	77 12                	ja     f0100b93 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b81:	50                   	push   %eax
f0100b82:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100b87:	6a 56                	push   $0x56
f0100b89:	68 d8 47 10 f0       	push   $0xf01047d8
f0100b8e:	e8 0d f5 ff ff       	call   f01000a0 <_panic>
f0100b93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b98:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b9b:	76 1e                	jbe    f0100bbb <check_page_free_list+0x238>
f0100b9d:	68 64 4b 10 f0       	push   $0xf0104b64
f0100ba2:	68 f2 47 10 f0       	push   $0xf01047f2
f0100ba7:	68 95 02 00 00       	push   $0x295
f0100bac:	68 cc 47 10 f0       	push   $0xf01047cc
f0100bb1:	e8 ea f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bb6:	83 c6 01             	add    $0x1,%esi
f0100bb9:	eb 04                	jmp    f0100bbf <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bbb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bbf:	8b 12                	mov    (%edx),%edx
f0100bc1:	85 d2                	test   %edx,%edx
f0100bc3:	0f 85 c8 fe ff ff    	jne    f0100a91 <check_page_free_list+0x10e>
f0100bc9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bcc:	85 f6                	test   %esi,%esi
f0100bce:	7f 19                	jg     f0100be9 <check_page_free_list+0x266>
f0100bd0:	68 5f 48 10 f0       	push   $0xf010485f
f0100bd5:	68 f2 47 10 f0       	push   $0xf01047f2
f0100bda:	68 9d 02 00 00       	push   $0x29d
f0100bdf:	68 cc 47 10 f0       	push   $0xf01047cc
f0100be4:	e8 b7 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100be9:	85 db                	test   %ebx,%ebx
f0100beb:	7f 42                	jg     f0100c2f <check_page_free_list+0x2ac>
f0100bed:	68 71 48 10 f0       	push   $0xf0104871
f0100bf2:	68 f2 47 10 f0       	push   $0xf01047f2
f0100bf7:	68 9e 02 00 00       	push   $0x29e
f0100bfc:	68 cc 47 10 f0       	push   $0xf01047cc
f0100c01:	e8 9a f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c06:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f0100c0b:	85 c0                	test   %eax,%eax
f0100c0d:	0f 85 9d fd ff ff    	jne    f01009b0 <check_page_free_list+0x2d>
f0100c13:	e9 81 fd ff ff       	jmp    f0100999 <check_page_free_list+0x16>
f0100c18:	83 3d 7c c0 17 f0 00 	cmpl   $0x0,0xf017c07c
f0100c1f:	0f 84 74 fd ff ff    	je     f0100999 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c25:	be 00 04 00 00       	mov    $0x400,%esi
f0100c2a:	e9 cf fd ff ff       	jmp    f01009fe <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c32:	5b                   	pop    %ebx
f0100c33:	5e                   	pop    %esi
f0100c34:	5f                   	pop    %edi
f0100c35:	5d                   	pop    %ebp
f0100c36:	c3                   	ret    

f0100c37 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c37:	55                   	push   %ebp
f0100c38:	89 e5                	mov    %esp,%ebp
f0100c3a:	53                   	push   %ebx
f0100c3b:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c3e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c43:	eb 4d                	jmp    f0100c92 <page_init+0x5b>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE)))
f0100c45:	85 db                	test   %ebx,%ebx
f0100c47:	74 46                	je     f0100c8f <page_init+0x58>
f0100c49:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100c4f:	76 16                	jbe    f0100c67 <page_init+0x30>
f0100c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c56:	e8 5b fc ff ff       	call   f01008b6 <boot_alloc>
f0100c5b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c60:	c1 e8 0c             	shr    $0xc,%eax
f0100c63:	39 c3                	cmp    %eax,%ebx
f0100c65:	76 28                	jbe    f0100c8f <page_init+0x58>
f0100c67:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100c6e:	89 c2                	mov    %eax,%edx
f0100c70:	03 15 4c cd 17 f0    	add    0xf017cd4c,%edx
f0100c76:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100c7c:	8b 0d 7c c0 17 f0    	mov    0xf017c07c,%ecx
f0100c82:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100c84:	03 05 4c cd 17 f0    	add    0xf017cd4c,%eax
f0100c8a:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c8f:	83 c3 01             	add    $0x1,%ebx
f0100c92:	3b 1d 44 cd 17 f0    	cmp    0xf017cd44,%ebx
f0100c98:	72 ab                	jb     f0100c45 <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100c9a:	83 c4 04             	add    $0x4,%esp
f0100c9d:	5b                   	pop    %ebx
f0100c9e:	5d                   	pop    %ebp
f0100c9f:	c3                   	ret    

f0100ca0 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ca0:	55                   	push   %ebp
f0100ca1:	89 e5                	mov    %esp,%ebp
f0100ca3:	53                   	push   %ebx
f0100ca4:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0100ca7:	8b 1d 7c c0 17 f0    	mov    0xf017c07c,%ebx
f0100cad:	85 db                	test   %ebx,%ebx
f0100caf:	74 58                	je     f0100d09 <page_alloc+0x69>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0100cb1:	8b 03                	mov    (%ebx),%eax
f0100cb3:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c
  	tempage->pp_link = NULL;
f0100cb8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
f0100cbe:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100cc2:	74 45                	je     f0100d09 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cc4:	89 d8                	mov    %ebx,%eax
f0100cc6:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0100ccc:	c1 f8 03             	sar    $0x3,%eax
f0100ccf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cd2:	89 c2                	mov    %eax,%edx
f0100cd4:	c1 ea 0c             	shr    $0xc,%edx
f0100cd7:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f0100cdd:	72 12                	jb     f0100cf1 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cdf:	50                   	push   %eax
f0100ce0:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100ce5:	6a 56                	push   $0x56
f0100ce7:	68 d8 47 10 f0       	push   $0xf01047d8
f0100cec:	e8 af f3 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f0100cf1:	83 ec 04             	sub    $0x4,%esp
f0100cf4:	68 00 10 00 00       	push   $0x1000
f0100cf9:	6a 00                	push   $0x0
f0100cfb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d00:	50                   	push   %eax
f0100d01:	e8 6f 31 00 00       	call   f0103e75 <memset>
f0100d06:	83 c4 10             	add    $0x10,%esp

  	return tempage;
	

}
f0100d09:	89 d8                	mov    %ebx,%eax
f0100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d0e:	c9                   	leave  
f0100d0f:	c3                   	ret    

f0100d10 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d10:	55                   	push   %ebp
f0100d11:	89 e5                	mov    %esp,%ebp
f0100d13:	83 ec 08             	sub    $0x8,%esp
f0100d16:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100d19:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d1e:	75 0f                	jne    f0100d2f <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100d20:	8b 15 7c c0 17 f0    	mov    0xf017c07c,%edx
f0100d26:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100d28:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c
	}
	else
	panic("page ref not zero \n");
}
f0100d2d:	eb 17                	jmp    f0100d46 <page_free+0x36>
	{
	pp->pp_link=page_free_list;
	page_free_list=pp;	
	}
	else
	panic("page ref not zero \n");
f0100d2f:	83 ec 04             	sub    $0x4,%esp
f0100d32:	68 82 48 10 f0       	push   $0xf0104882
f0100d37:	68 69 01 00 00       	push   $0x169
f0100d3c:	68 cc 47 10 f0       	push   $0xf01047cc
f0100d41:	e8 5a f3 ff ff       	call   f01000a0 <_panic>
}
f0100d46:	c9                   	leave  
f0100d47:	c3                   	ret    

f0100d48 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d48:	55                   	push   %ebp
f0100d49:	89 e5                	mov    %esp,%ebp
f0100d4b:	83 ec 08             	sub    $0x8,%esp
f0100d4e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d51:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d55:	83 e8 01             	sub    $0x1,%eax
f0100d58:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d5c:	66 85 c0             	test   %ax,%ax
f0100d5f:	75 0c                	jne    f0100d6d <page_decref+0x25>
		page_free(pp);
f0100d61:	83 ec 0c             	sub    $0xc,%esp
f0100d64:	52                   	push   %edx
f0100d65:	e8 a6 ff ff ff       	call   f0100d10 <page_free>
f0100d6a:	83 c4 10             	add    $0x10,%esp
}
f0100d6d:	c9                   	leave  
f0100d6e:	c3                   	ret    

f0100d6f <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d6f:	55                   	push   %ebp
f0100d70:	89 e5                	mov    %esp,%ebp
f0100d72:	57                   	push   %edi
f0100d73:	56                   	push   %esi
f0100d74:	53                   	push   %ebx
f0100d75:	83 ec 0c             	sub    $0xc,%esp
f0100d78:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0100d7b:	89 de                	mov    %ebx,%esi
f0100d7d:	c1 ee 16             	shr    $0x16,%esi
f0100d80:	c1 e6 02             	shl    $0x2,%esi
f0100d83:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0100d86:	8b 06                	mov    (%esi),%eax
f0100d88:	a8 01                	test   $0x1,%al
f0100d8a:	74 2f                	je     f0100dbb <pgdir_walk+0x4c>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f0100d8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d91:	89 c2                	mov    %eax,%edx
f0100d93:	c1 ea 0c             	shr    $0xc,%edx
f0100d96:	39 15 44 cd 17 f0    	cmp    %edx,0xf017cd44
f0100d9c:	77 15                	ja     f0100db3 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d9e:	50                   	push   %eax
f0100d9f:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100da4:	68 96 01 00 00       	push   $0x196
f0100da9:	68 cc 47 10 f0       	push   $0xf01047cc
f0100dae:	e8 ed f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100db3:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100db9:	eb 77                	jmp    f0100e32 <pgdir_walk+0xc3>
	  } else {
		//page table page not exist
		if(!create || 
f0100dbb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100dbf:	74 7f                	je     f0100e40 <pgdir_walk+0xd1>
f0100dc1:	83 ec 0c             	sub    $0xc,%esp
f0100dc4:	6a 01                	push   $0x1
f0100dc6:	e8 d5 fe ff ff       	call   f0100ca0 <page_alloc>
f0100dcb:	83 c4 10             	add    $0x10,%esp
f0100dce:	85 c0                	test   %eax,%eax
f0100dd0:	74 75                	je     f0100e47 <pgdir_walk+0xd8>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd2:	89 c1                	mov    %eax,%ecx
f0100dd4:	2b 0d 4c cd 17 f0    	sub    0xf017cd4c,%ecx
f0100dda:	c1 f9 03             	sar    $0x3,%ecx
f0100ddd:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100de0:	89 ca                	mov    %ecx,%edx
f0100de2:	c1 ea 0c             	shr    $0xc,%edx
f0100de5:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f0100deb:	72 12                	jb     f0100dff <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ded:	51                   	push   %ecx
f0100dee:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0100df3:	6a 56                	push   $0x56
f0100df5:	68 d8 47 10 f0       	push   $0xf01047d8
f0100dfa:	e8 a1 f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100dff:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100e05:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0100e07:	85 ff                	test   %edi,%edi
f0100e09:	74 43                	je     f0100e4e <pgdir_walk+0xdf>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f0100e0b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e10:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100e16:	77 15                	ja     f0100e2d <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e18:	57                   	push   %edi
f0100e19:	68 ac 4b 10 f0       	push   $0xf0104bac
f0100e1e:	68 9f 01 00 00       	push   $0x19f
f0100e23:	68 cc 47 10 f0       	push   $0xf01047cc
f0100e28:	e8 73 f2 ff ff       	call   f01000a0 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0100e2d:	83 c9 07             	or     $0x7,%ecx
f0100e30:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f0100e32:	c1 eb 0a             	shr    $0xa,%ebx
f0100e35:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100e3b:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100e3e:	eb 13                	jmp    f0100e53 <pgdir_walk+0xe4>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f0100e40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e45:	eb 0c                	jmp    f0100e53 <pgdir_walk+0xe4>
f0100e47:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e4c:	eb 05                	jmp    f0100e53 <pgdir_walk+0xe4>
f0100e4e:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f0100e53:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e56:	5b                   	pop    %ebx
f0100e57:	5e                   	pop    %esi
f0100e58:	5f                   	pop    %edi
f0100e59:	5d                   	pop    %ebp
f0100e5a:	c3                   	ret    

f0100e5b <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e5b:	55                   	push   %ebp
f0100e5c:	89 e5                	mov    %esp,%ebp
f0100e5e:	57                   	push   %edi
f0100e5f:	56                   	push   %esi
f0100e60:	53                   	push   %ebx
f0100e61:	83 ec 1c             	sub    $0x1c,%esp
f0100e64:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0100e67:	c1 e9 0c             	shr    $0xc,%ecx
f0100e6a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f0100e6d:	89 d6                	mov    %edx,%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f0100e6f:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e74:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e77:	29 d0                	sub    %edx,%eax
f0100e79:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0100e7c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e7f:	83 c8 01             	or     $0x1,%eax
f0100e82:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0100e85:	eb 25                	jmp    f0100eac <boot_map_region+0x51>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f0100e87:	83 ec 04             	sub    $0x4,%esp
f0100e8a:	6a 01                	push   $0x1
f0100e8c:	56                   	push   %esi
f0100e8d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e90:	e8 da fe ff ff       	call   f0100d6f <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0100e95:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100e9b:	0b 5d d8             	or     -0x28(%ebp),%ebx
f0100e9e:	89 18                	mov    %ebx,(%eax)
		va+=PGSIZE;
f0100ea0:	81 c6 00 10 00 00    	add    $0x1000,%esi
		pa+=PGSIZE;
		i++;
f0100ea6:	83 c7 01             	add    $0x1,%edi
f0100ea9:	83 c4 10             	add    $0x10,%esp
f0100eac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eaf:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0100eb2:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100eb5:	75 d0                	jne    f0100e87 <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f0100eb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eba:	5b                   	pop    %ebx
f0100ebb:	5e                   	pop    %esi
f0100ebc:	5f                   	pop    %edi
f0100ebd:	5d                   	pop    %ebp
f0100ebe:	c3                   	ret    

f0100ebf <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ebf:	55                   	push   %ebp
f0100ec0:	89 e5                	mov    %esp,%ebp
f0100ec2:	83 ec 0c             	sub    $0xc,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f0100ec5:	6a 00                	push   $0x0
f0100ec7:	ff 75 0c             	pushl  0xc(%ebp)
f0100eca:	ff 75 08             	pushl  0x8(%ebp)
f0100ecd:	e8 9d fe ff ff       	call   f0100d6f <pgdir_walk>
	
	if(pt == NULL)
f0100ed2:	83 c4 10             	add    $0x10,%esp
f0100ed5:	85 c0                	test   %eax,%eax
f0100ed7:	74 31                	je     f0100f0a <page_lookup+0x4b>
	return NULL;
	
	*pte_store = pt;
f0100ed9:	8b 55 10             	mov    0x10(%ebp),%edx
f0100edc:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ede:	8b 00                	mov    (%eax),%eax
f0100ee0:	c1 e8 0c             	shr    $0xc,%eax
f0100ee3:	3b 05 44 cd 17 f0    	cmp    0xf017cd44,%eax
f0100ee9:	72 14                	jb     f0100eff <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0100eeb:	83 ec 04             	sub    $0x4,%esp
f0100eee:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0100ef3:	6a 4f                	push   $0x4f
f0100ef5:	68 d8 47 10 f0       	push   $0xf01047d8
f0100efa:	e8 a1 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100eff:	8b 15 4c cd 17 f0    	mov    0xf017cd4c,%edx
f0100f05:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	
  return pa2page(PTE_ADDR(*pt));	
f0100f08:	eb 05                	jmp    f0100f0f <page_lookup+0x50>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f0100f0a:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0100f0f:	c9                   	leave  
f0100f10:	c3                   	ret    

f0100f11 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f11:	55                   	push   %ebp
f0100f12:	89 e5                	mov    %esp,%ebp
f0100f14:	53                   	push   %ebx
f0100f15:	83 ec 18             	sub    $0x18,%esp
f0100f18:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f0100f1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f0100f22:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f25:	50                   	push   %eax
f0100f26:	53                   	push   %ebx
f0100f27:	ff 75 08             	pushl  0x8(%ebp)
f0100f2a:	e8 90 ff ff ff       	call   f0100ebf <page_lookup>
f0100f2f:	83 c4 10             	add    $0x10,%esp
f0100f32:	85 c0                	test   %eax,%eax
f0100f34:	74 0f                	je     f0100f45 <page_remove+0x34>
		page_decref(page);
f0100f36:	83 ec 0c             	sub    $0xc,%esp
f0100f39:	50                   	push   %eax
f0100f3a:	e8 09 fe ff ff       	call   f0100d48 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f3f:	0f 01 3b             	invlpg (%ebx)
f0100f42:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
	*pt=0;
f0100f45:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f48:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0100f4e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f51:	c9                   	leave  
f0100f52:	c3                   	ret    

f0100f53 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f53:	55                   	push   %ebp
f0100f54:	89 e5                	mov    %esp,%ebp
f0100f56:	57                   	push   %edi
f0100f57:	56                   	push   %esi
f0100f58:	53                   	push   %ebx
f0100f59:	83 ec 10             	sub    $0x10,%esp
f0100f5c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f5f:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f0100f62:	6a 01                	push   $0x1
f0100f64:	57                   	push   %edi
f0100f65:	ff 75 08             	pushl  0x8(%ebp)
f0100f68:	e8 02 fe ff ff       	call   f0100d6f <pgdir_walk>
 

    if (pte != NULL) {
f0100f6d:	83 c4 10             	add    $0x10,%esp
f0100f70:	85 c0                	test   %eax,%eax
f0100f72:	74 4a                	je     f0100fbe <page_insert+0x6b>
f0100f74:	89 c3                	mov    %eax,%ebx
     
        if (*pte & PTE_P)
f0100f76:	f6 00 01             	testb  $0x1,(%eax)
f0100f79:	74 0f                	je     f0100f8a <page_insert+0x37>
            page_remove(pgdir, va);
f0100f7b:	83 ec 08             	sub    $0x8,%esp
f0100f7e:	57                   	push   %edi
f0100f7f:	ff 75 08             	pushl  0x8(%ebp)
f0100f82:	e8 8a ff ff ff       	call   f0100f11 <page_remove>
f0100f87:	83 c4 10             	add    $0x10,%esp
   
       if (page_free_list == pp)
f0100f8a:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f0100f8f:	39 f0                	cmp    %esi,%eax
f0100f91:	75 07                	jne    f0100f9a <page_insert+0x47>
            page_free_list = page_free_list->pp_link;
f0100f93:	8b 00                	mov    (%eax),%eax
f0100f95:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c
    }
    else {
    
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f0100f9a:	89 f0                	mov    %esi,%eax
f0100f9c:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0100fa2:	c1 f8 03             	sar    $0x3,%eax
f0100fa5:	c1 e0 0c             	shl    $0xc,%eax
f0100fa8:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fab:	83 ca 01             	or     $0x1,%edx
f0100fae:	09 d0                	or     %edx,%eax
f0100fb0:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f0100fb2:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

return 0;
f0100fb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbc:	eb 05                	jmp    f0100fc3 <page_insert+0x70>
       if (page_free_list == pp)
            page_free_list = page_free_list->pp_link;
    }
    else {
    
            return -E_NO_MEM;
f0100fbe:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f0100fc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc6:	5b                   	pop    %ebx
f0100fc7:	5e                   	pop    %esi
f0100fc8:	5f                   	pop    %edi
f0100fc9:	5d                   	pop    %ebp
f0100fca:	c3                   	ret    

f0100fcb <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fcb:	55                   	push   %ebp
f0100fcc:	89 e5                	mov    %esp,%ebp
f0100fce:	57                   	push   %edi
f0100fcf:	56                   	push   %esi
f0100fd0:	53                   	push   %ebx
f0100fd1:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100fd4:	b8 15 00 00 00       	mov    $0x15,%eax
f0100fd9:	e8 af f8 ff ff       	call   f010088d <nvram_read>
f0100fde:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100fe0:	b8 17 00 00 00       	mov    $0x17,%eax
f0100fe5:	e8 a3 f8 ff ff       	call   f010088d <nvram_read>
f0100fea:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100fec:	b8 34 00 00 00       	mov    $0x34,%eax
f0100ff1:	e8 97 f8 ff ff       	call   f010088d <nvram_read>
f0100ff6:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100ff9:	85 c0                	test   %eax,%eax
f0100ffb:	74 07                	je     f0101004 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100ffd:	05 00 40 00 00       	add    $0x4000,%eax
f0101002:	eb 0b                	jmp    f010100f <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101004:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010100a:	85 f6                	test   %esi,%esi
f010100c:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010100f:	89 c2                	mov    %eax,%edx
f0101011:	c1 ea 02             	shr    $0x2,%edx
f0101014:	89 15 44 cd 17 f0    	mov    %edx,0xf017cd44
	npages_basemem = basemem / (PGSIZE / 1024);
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010101a:	89 c2                	mov    %eax,%edx
f010101c:	29 da                	sub    %ebx,%edx
f010101e:	52                   	push   %edx
f010101f:	53                   	push   %ebx
f0101020:	50                   	push   %eax
f0101021:	68 f0 4b 10 f0       	push   $0xf0104bf0
f0101026:	e8 05 1e 00 00       	call   f0102e30 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010102b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101030:	e8 81 f8 ff ff       	call   f01008b6 <boot_alloc>
f0101035:	a3 48 cd 17 f0       	mov    %eax,0xf017cd48
	memset(kern_pgdir, 0, PGSIZE);
f010103a:	83 c4 0c             	add    $0xc,%esp
f010103d:	68 00 10 00 00       	push   $0x1000
f0101042:	6a 00                	push   $0x0
f0101044:	50                   	push   %eax
f0101045:	e8 2b 2e 00 00       	call   f0103e75 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010104a:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010104f:	83 c4 10             	add    $0x10,%esp
f0101052:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101057:	77 15                	ja     f010106e <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101059:	50                   	push   %eax
f010105a:	68 ac 4b 10 f0       	push   $0xf0104bac
f010105f:	68 a1 00 00 00       	push   $0xa1
f0101064:	68 cc 47 10 f0       	push   $0xf01047cc
f0101069:	e8 32 f0 ff ff       	call   f01000a0 <_panic>
f010106e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101074:	83 ca 05             	or     $0x5,%edx
f0101077:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo *)boot_alloc(sizeof(struct PageInfo)*npages);
f010107d:	a1 44 cd 17 f0       	mov    0xf017cd44,%eax
f0101082:	c1 e0 03             	shl    $0x3,%eax
f0101085:	e8 2c f8 ff ff       	call   f01008b6 <boot_alloc>
f010108a:	a3 4c cd 17 f0       	mov    %eax,0xf017cd4c
	memset(pages,0,sizeof(struct PageInfo)*npages);
f010108f:	83 ec 04             	sub    $0x4,%esp
f0101092:	8b 3d 44 cd 17 f0    	mov    0xf017cd44,%edi
f0101098:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010109f:	52                   	push   %edx
f01010a0:	6a 00                	push   $0x0
f01010a2:	50                   	push   %eax
f01010a3:	e8 cd 2d 00 00       	call   f0103e75 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	
	
	envs=(struct Env *)boot_alloc(sizeof(struct Env)*NENV);
f01010a8:	b8 00 80 01 00       	mov    $0x18000,%eax
f01010ad:	e8 04 f8 ff ff       	call   f01008b6 <boot_alloc>
f01010b2:	a3 84 c0 17 f0       	mov    %eax,0xf017c084
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010b7:	e8 7b fb ff ff       	call   f0100c37 <page_init>

	check_page_free_list(1);
f01010bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01010c1:	e8 bd f8 ff ff       	call   f0100983 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01010c6:	83 c4 10             	add    $0x10,%esp
f01010c9:	83 3d 4c cd 17 f0 00 	cmpl   $0x0,0xf017cd4c
f01010d0:	75 17                	jne    f01010e9 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f01010d2:	83 ec 04             	sub    $0x4,%esp
f01010d5:	68 96 48 10 f0       	push   $0xf0104896
f01010da:	68 af 02 00 00       	push   $0x2af
f01010df:	68 cc 47 10 f0       	push   $0xf01047cc
f01010e4:	e8 b7 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010e9:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f01010ee:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010f3:	eb 05                	jmp    f01010fa <mem_init+0x12f>
		++nfree;
f01010f5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010f8:	8b 00                	mov    (%eax),%eax
f01010fa:	85 c0                	test   %eax,%eax
f01010fc:	75 f7                	jne    f01010f5 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010fe:	83 ec 0c             	sub    $0xc,%esp
f0101101:	6a 00                	push   $0x0
f0101103:	e8 98 fb ff ff       	call   f0100ca0 <page_alloc>
f0101108:	89 c7                	mov    %eax,%edi
f010110a:	83 c4 10             	add    $0x10,%esp
f010110d:	85 c0                	test   %eax,%eax
f010110f:	75 19                	jne    f010112a <mem_init+0x15f>
f0101111:	68 b1 48 10 f0       	push   $0xf01048b1
f0101116:	68 f2 47 10 f0       	push   $0xf01047f2
f010111b:	68 b7 02 00 00       	push   $0x2b7
f0101120:	68 cc 47 10 f0       	push   $0xf01047cc
f0101125:	e8 76 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010112a:	83 ec 0c             	sub    $0xc,%esp
f010112d:	6a 00                	push   $0x0
f010112f:	e8 6c fb ff ff       	call   f0100ca0 <page_alloc>
f0101134:	89 c6                	mov    %eax,%esi
f0101136:	83 c4 10             	add    $0x10,%esp
f0101139:	85 c0                	test   %eax,%eax
f010113b:	75 19                	jne    f0101156 <mem_init+0x18b>
f010113d:	68 c7 48 10 f0       	push   $0xf01048c7
f0101142:	68 f2 47 10 f0       	push   $0xf01047f2
f0101147:	68 b8 02 00 00       	push   $0x2b8
f010114c:	68 cc 47 10 f0       	push   $0xf01047cc
f0101151:	e8 4a ef ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101156:	83 ec 0c             	sub    $0xc,%esp
f0101159:	6a 00                	push   $0x0
f010115b:	e8 40 fb ff ff       	call   f0100ca0 <page_alloc>
f0101160:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101163:	83 c4 10             	add    $0x10,%esp
f0101166:	85 c0                	test   %eax,%eax
f0101168:	75 19                	jne    f0101183 <mem_init+0x1b8>
f010116a:	68 dd 48 10 f0       	push   $0xf01048dd
f010116f:	68 f2 47 10 f0       	push   $0xf01047f2
f0101174:	68 b9 02 00 00       	push   $0x2b9
f0101179:	68 cc 47 10 f0       	push   $0xf01047cc
f010117e:	e8 1d ef ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101183:	39 f7                	cmp    %esi,%edi
f0101185:	75 19                	jne    f01011a0 <mem_init+0x1d5>
f0101187:	68 f3 48 10 f0       	push   $0xf01048f3
f010118c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101191:	68 bc 02 00 00       	push   $0x2bc
f0101196:	68 cc 47 10 f0       	push   $0xf01047cc
f010119b:	e8 00 ef ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011a3:	39 c6                	cmp    %eax,%esi
f01011a5:	74 04                	je     f01011ab <mem_init+0x1e0>
f01011a7:	39 c7                	cmp    %eax,%edi
f01011a9:	75 19                	jne    f01011c4 <mem_init+0x1f9>
f01011ab:	68 2c 4c 10 f0       	push   $0xf0104c2c
f01011b0:	68 f2 47 10 f0       	push   $0xf01047f2
f01011b5:	68 bd 02 00 00       	push   $0x2bd
f01011ba:	68 cc 47 10 f0       	push   $0xf01047cc
f01011bf:	e8 dc ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011c4:	8b 0d 4c cd 17 f0    	mov    0xf017cd4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01011ca:	8b 15 44 cd 17 f0    	mov    0xf017cd44,%edx
f01011d0:	c1 e2 0c             	shl    $0xc,%edx
f01011d3:	89 f8                	mov    %edi,%eax
f01011d5:	29 c8                	sub    %ecx,%eax
f01011d7:	c1 f8 03             	sar    $0x3,%eax
f01011da:	c1 e0 0c             	shl    $0xc,%eax
f01011dd:	39 d0                	cmp    %edx,%eax
f01011df:	72 19                	jb     f01011fa <mem_init+0x22f>
f01011e1:	68 05 49 10 f0       	push   $0xf0104905
f01011e6:	68 f2 47 10 f0       	push   $0xf01047f2
f01011eb:	68 be 02 00 00       	push   $0x2be
f01011f0:	68 cc 47 10 f0       	push   $0xf01047cc
f01011f5:	e8 a6 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011fa:	89 f0                	mov    %esi,%eax
f01011fc:	29 c8                	sub    %ecx,%eax
f01011fe:	c1 f8 03             	sar    $0x3,%eax
f0101201:	c1 e0 0c             	shl    $0xc,%eax
f0101204:	39 c2                	cmp    %eax,%edx
f0101206:	77 19                	ja     f0101221 <mem_init+0x256>
f0101208:	68 22 49 10 f0       	push   $0xf0104922
f010120d:	68 f2 47 10 f0       	push   $0xf01047f2
f0101212:	68 bf 02 00 00       	push   $0x2bf
f0101217:	68 cc 47 10 f0       	push   $0xf01047cc
f010121c:	e8 7f ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101221:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101224:	29 c8                	sub    %ecx,%eax
f0101226:	c1 f8 03             	sar    $0x3,%eax
f0101229:	c1 e0 0c             	shl    $0xc,%eax
f010122c:	39 c2                	cmp    %eax,%edx
f010122e:	77 19                	ja     f0101249 <mem_init+0x27e>
f0101230:	68 3f 49 10 f0       	push   $0xf010493f
f0101235:	68 f2 47 10 f0       	push   $0xf01047f2
f010123a:	68 c0 02 00 00       	push   $0x2c0
f010123f:	68 cc 47 10 f0       	push   $0xf01047cc
f0101244:	e8 57 ee ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101249:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f010124e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101251:	c7 05 7c c0 17 f0 00 	movl   $0x0,0xf017c07c
f0101258:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010125b:	83 ec 0c             	sub    $0xc,%esp
f010125e:	6a 00                	push   $0x0
f0101260:	e8 3b fa ff ff       	call   f0100ca0 <page_alloc>
f0101265:	83 c4 10             	add    $0x10,%esp
f0101268:	85 c0                	test   %eax,%eax
f010126a:	74 19                	je     f0101285 <mem_init+0x2ba>
f010126c:	68 5c 49 10 f0       	push   $0xf010495c
f0101271:	68 f2 47 10 f0       	push   $0xf01047f2
f0101276:	68 c7 02 00 00       	push   $0x2c7
f010127b:	68 cc 47 10 f0       	push   $0xf01047cc
f0101280:	e8 1b ee ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101285:	83 ec 0c             	sub    $0xc,%esp
f0101288:	57                   	push   %edi
f0101289:	e8 82 fa ff ff       	call   f0100d10 <page_free>
	page_free(pp1);
f010128e:	89 34 24             	mov    %esi,(%esp)
f0101291:	e8 7a fa ff ff       	call   f0100d10 <page_free>
	page_free(pp2);
f0101296:	83 c4 04             	add    $0x4,%esp
f0101299:	ff 75 d4             	pushl  -0x2c(%ebp)
f010129c:	e8 6f fa ff ff       	call   f0100d10 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012a8:	e8 f3 f9 ff ff       	call   f0100ca0 <page_alloc>
f01012ad:	89 c6                	mov    %eax,%esi
f01012af:	83 c4 10             	add    $0x10,%esp
f01012b2:	85 c0                	test   %eax,%eax
f01012b4:	75 19                	jne    f01012cf <mem_init+0x304>
f01012b6:	68 b1 48 10 f0       	push   $0xf01048b1
f01012bb:	68 f2 47 10 f0       	push   $0xf01047f2
f01012c0:	68 ce 02 00 00       	push   $0x2ce
f01012c5:	68 cc 47 10 f0       	push   $0xf01047cc
f01012ca:	e8 d1 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012cf:	83 ec 0c             	sub    $0xc,%esp
f01012d2:	6a 00                	push   $0x0
f01012d4:	e8 c7 f9 ff ff       	call   f0100ca0 <page_alloc>
f01012d9:	89 c7                	mov    %eax,%edi
f01012db:	83 c4 10             	add    $0x10,%esp
f01012de:	85 c0                	test   %eax,%eax
f01012e0:	75 19                	jne    f01012fb <mem_init+0x330>
f01012e2:	68 c7 48 10 f0       	push   $0xf01048c7
f01012e7:	68 f2 47 10 f0       	push   $0xf01047f2
f01012ec:	68 cf 02 00 00       	push   $0x2cf
f01012f1:	68 cc 47 10 f0       	push   $0xf01047cc
f01012f6:	e8 a5 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012fb:	83 ec 0c             	sub    $0xc,%esp
f01012fe:	6a 00                	push   $0x0
f0101300:	e8 9b f9 ff ff       	call   f0100ca0 <page_alloc>
f0101305:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101308:	83 c4 10             	add    $0x10,%esp
f010130b:	85 c0                	test   %eax,%eax
f010130d:	75 19                	jne    f0101328 <mem_init+0x35d>
f010130f:	68 dd 48 10 f0       	push   $0xf01048dd
f0101314:	68 f2 47 10 f0       	push   $0xf01047f2
f0101319:	68 d0 02 00 00       	push   $0x2d0
f010131e:	68 cc 47 10 f0       	push   $0xf01047cc
f0101323:	e8 78 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101328:	39 fe                	cmp    %edi,%esi
f010132a:	75 19                	jne    f0101345 <mem_init+0x37a>
f010132c:	68 f3 48 10 f0       	push   $0xf01048f3
f0101331:	68 f2 47 10 f0       	push   $0xf01047f2
f0101336:	68 d2 02 00 00       	push   $0x2d2
f010133b:	68 cc 47 10 f0       	push   $0xf01047cc
f0101340:	e8 5b ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101345:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101348:	39 c7                	cmp    %eax,%edi
f010134a:	74 04                	je     f0101350 <mem_init+0x385>
f010134c:	39 c6                	cmp    %eax,%esi
f010134e:	75 19                	jne    f0101369 <mem_init+0x39e>
f0101350:	68 2c 4c 10 f0       	push   $0xf0104c2c
f0101355:	68 f2 47 10 f0       	push   $0xf01047f2
f010135a:	68 d3 02 00 00       	push   $0x2d3
f010135f:	68 cc 47 10 f0       	push   $0xf01047cc
f0101364:	e8 37 ed ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101369:	83 ec 0c             	sub    $0xc,%esp
f010136c:	6a 00                	push   $0x0
f010136e:	e8 2d f9 ff ff       	call   f0100ca0 <page_alloc>
f0101373:	83 c4 10             	add    $0x10,%esp
f0101376:	85 c0                	test   %eax,%eax
f0101378:	74 19                	je     f0101393 <mem_init+0x3c8>
f010137a:	68 5c 49 10 f0       	push   $0xf010495c
f010137f:	68 f2 47 10 f0       	push   $0xf01047f2
f0101384:	68 d4 02 00 00       	push   $0x2d4
f0101389:	68 cc 47 10 f0       	push   $0xf01047cc
f010138e:	e8 0d ed ff ff       	call   f01000a0 <_panic>
f0101393:	89 f0                	mov    %esi,%eax
f0101395:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f010139b:	c1 f8 03             	sar    $0x3,%eax
f010139e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013a1:	89 c2                	mov    %eax,%edx
f01013a3:	c1 ea 0c             	shr    $0xc,%edx
f01013a6:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f01013ac:	72 12                	jb     f01013c0 <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013ae:	50                   	push   %eax
f01013af:	68 c4 4a 10 f0       	push   $0xf0104ac4
f01013b4:	6a 56                	push   $0x56
f01013b6:	68 d8 47 10 f0       	push   $0xf01047d8
f01013bb:	e8 e0 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013c0:	83 ec 04             	sub    $0x4,%esp
f01013c3:	68 00 10 00 00       	push   $0x1000
f01013c8:	6a 01                	push   $0x1
f01013ca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013cf:	50                   	push   %eax
f01013d0:	e8 a0 2a 00 00       	call   f0103e75 <memset>
	page_free(pp0);
f01013d5:	89 34 24             	mov    %esi,(%esp)
f01013d8:	e8 33 f9 ff ff       	call   f0100d10 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013e4:	e8 b7 f8 ff ff       	call   f0100ca0 <page_alloc>
f01013e9:	83 c4 10             	add    $0x10,%esp
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	75 19                	jne    f0101409 <mem_init+0x43e>
f01013f0:	68 6b 49 10 f0       	push   $0xf010496b
f01013f5:	68 f2 47 10 f0       	push   $0xf01047f2
f01013fa:	68 d9 02 00 00       	push   $0x2d9
f01013ff:	68 cc 47 10 f0       	push   $0xf01047cc
f0101404:	e8 97 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101409:	39 c6                	cmp    %eax,%esi
f010140b:	74 19                	je     f0101426 <mem_init+0x45b>
f010140d:	68 89 49 10 f0       	push   $0xf0104989
f0101412:	68 f2 47 10 f0       	push   $0xf01047f2
f0101417:	68 da 02 00 00       	push   $0x2da
f010141c:	68 cc 47 10 f0       	push   $0xf01047cc
f0101421:	e8 7a ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101426:	89 f0                	mov    %esi,%eax
f0101428:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f010142e:	c1 f8 03             	sar    $0x3,%eax
f0101431:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101434:	89 c2                	mov    %eax,%edx
f0101436:	c1 ea 0c             	shr    $0xc,%edx
f0101439:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f010143f:	72 12                	jb     f0101453 <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101441:	50                   	push   %eax
f0101442:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0101447:	6a 56                	push   $0x56
f0101449:	68 d8 47 10 f0       	push   $0xf01047d8
f010144e:	e8 4d ec ff ff       	call   f01000a0 <_panic>
f0101453:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101459:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010145f:	80 38 00             	cmpb   $0x0,(%eax)
f0101462:	74 19                	je     f010147d <mem_init+0x4b2>
f0101464:	68 99 49 10 f0       	push   $0xf0104999
f0101469:	68 f2 47 10 f0       	push   $0xf01047f2
f010146e:	68 dd 02 00 00       	push   $0x2dd
f0101473:	68 cc 47 10 f0       	push   $0xf01047cc
f0101478:	e8 23 ec ff ff       	call   f01000a0 <_panic>
f010147d:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101480:	39 d0                	cmp    %edx,%eax
f0101482:	75 db                	jne    f010145f <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101484:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101487:	a3 7c c0 17 f0       	mov    %eax,0xf017c07c

	// free the pages we took
	page_free(pp0);
f010148c:	83 ec 0c             	sub    $0xc,%esp
f010148f:	56                   	push   %esi
f0101490:	e8 7b f8 ff ff       	call   f0100d10 <page_free>
	page_free(pp1);
f0101495:	89 3c 24             	mov    %edi,(%esp)
f0101498:	e8 73 f8 ff ff       	call   f0100d10 <page_free>
	page_free(pp2);
f010149d:	83 c4 04             	add    $0x4,%esp
f01014a0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014a3:	e8 68 f8 ff ff       	call   f0100d10 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014a8:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f01014ad:	83 c4 10             	add    $0x10,%esp
f01014b0:	eb 05                	jmp    f01014b7 <mem_init+0x4ec>
		--nfree;
f01014b2:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014b5:	8b 00                	mov    (%eax),%eax
f01014b7:	85 c0                	test   %eax,%eax
f01014b9:	75 f7                	jne    f01014b2 <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f01014bb:	85 db                	test   %ebx,%ebx
f01014bd:	74 19                	je     f01014d8 <mem_init+0x50d>
f01014bf:	68 a3 49 10 f0       	push   $0xf01049a3
f01014c4:	68 f2 47 10 f0       	push   $0xf01047f2
f01014c9:	68 ea 02 00 00       	push   $0x2ea
f01014ce:	68 cc 47 10 f0       	push   $0xf01047cc
f01014d3:	e8 c8 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014d8:	83 ec 0c             	sub    $0xc,%esp
f01014db:	68 4c 4c 10 f0       	push   $0xf0104c4c
f01014e0:	e8 4b 19 00 00       	call   f0102e30 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ec:	e8 af f7 ff ff       	call   f0100ca0 <page_alloc>
f01014f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014f4:	83 c4 10             	add    $0x10,%esp
f01014f7:	85 c0                	test   %eax,%eax
f01014f9:	75 19                	jne    f0101514 <mem_init+0x549>
f01014fb:	68 b1 48 10 f0       	push   $0xf01048b1
f0101500:	68 f2 47 10 f0       	push   $0xf01047f2
f0101505:	68 48 03 00 00       	push   $0x348
f010150a:	68 cc 47 10 f0       	push   $0xf01047cc
f010150f:	e8 8c eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101514:	83 ec 0c             	sub    $0xc,%esp
f0101517:	6a 00                	push   $0x0
f0101519:	e8 82 f7 ff ff       	call   f0100ca0 <page_alloc>
f010151e:	89 c3                	mov    %eax,%ebx
f0101520:	83 c4 10             	add    $0x10,%esp
f0101523:	85 c0                	test   %eax,%eax
f0101525:	75 19                	jne    f0101540 <mem_init+0x575>
f0101527:	68 c7 48 10 f0       	push   $0xf01048c7
f010152c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101531:	68 49 03 00 00       	push   $0x349
f0101536:	68 cc 47 10 f0       	push   $0xf01047cc
f010153b:	e8 60 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101540:	83 ec 0c             	sub    $0xc,%esp
f0101543:	6a 00                	push   $0x0
f0101545:	e8 56 f7 ff ff       	call   f0100ca0 <page_alloc>
f010154a:	89 c6                	mov    %eax,%esi
f010154c:	83 c4 10             	add    $0x10,%esp
f010154f:	85 c0                	test   %eax,%eax
f0101551:	75 19                	jne    f010156c <mem_init+0x5a1>
f0101553:	68 dd 48 10 f0       	push   $0xf01048dd
f0101558:	68 f2 47 10 f0       	push   $0xf01047f2
f010155d:	68 4a 03 00 00       	push   $0x34a
f0101562:	68 cc 47 10 f0       	push   $0xf01047cc
f0101567:	e8 34 eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010156c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010156f:	75 19                	jne    f010158a <mem_init+0x5bf>
f0101571:	68 f3 48 10 f0       	push   $0xf01048f3
f0101576:	68 f2 47 10 f0       	push   $0xf01047f2
f010157b:	68 4d 03 00 00       	push   $0x34d
f0101580:	68 cc 47 10 f0       	push   $0xf01047cc
f0101585:	e8 16 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010158a:	39 c3                	cmp    %eax,%ebx
f010158c:	74 05                	je     f0101593 <mem_init+0x5c8>
f010158e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101591:	75 19                	jne    f01015ac <mem_init+0x5e1>
f0101593:	68 2c 4c 10 f0       	push   $0xf0104c2c
f0101598:	68 f2 47 10 f0       	push   $0xf01047f2
f010159d:	68 4e 03 00 00       	push   $0x34e
f01015a2:	68 cc 47 10 f0       	push   $0xf01047cc
f01015a7:	e8 f4 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015ac:	a1 7c c0 17 f0       	mov    0xf017c07c,%eax
f01015b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015b4:	c7 05 7c c0 17 f0 00 	movl   $0x0,0xf017c07c
f01015bb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015be:	83 ec 0c             	sub    $0xc,%esp
f01015c1:	6a 00                	push   $0x0
f01015c3:	e8 d8 f6 ff ff       	call   f0100ca0 <page_alloc>
f01015c8:	83 c4 10             	add    $0x10,%esp
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	74 19                	je     f01015e8 <mem_init+0x61d>
f01015cf:	68 5c 49 10 f0       	push   $0xf010495c
f01015d4:	68 f2 47 10 f0       	push   $0xf01047f2
f01015d9:	68 55 03 00 00       	push   $0x355
f01015de:	68 cc 47 10 f0       	push   $0xf01047cc
f01015e3:	e8 b8 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01015e8:	83 ec 04             	sub    $0x4,%esp
f01015eb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015ee:	50                   	push   %eax
f01015ef:	6a 00                	push   $0x0
f01015f1:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f01015f7:	e8 c3 f8 ff ff       	call   f0100ebf <page_lookup>
f01015fc:	83 c4 10             	add    $0x10,%esp
f01015ff:	85 c0                	test   %eax,%eax
f0101601:	74 19                	je     f010161c <mem_init+0x651>
f0101603:	68 6c 4c 10 f0       	push   $0xf0104c6c
f0101608:	68 f2 47 10 f0       	push   $0xf01047f2
f010160d:	68 58 03 00 00       	push   $0x358
f0101612:	68 cc 47 10 f0       	push   $0xf01047cc
f0101617:	e8 84 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010161c:	6a 02                	push   $0x2
f010161e:	6a 00                	push   $0x0
f0101620:	53                   	push   %ebx
f0101621:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101627:	e8 27 f9 ff ff       	call   f0100f53 <page_insert>
f010162c:	83 c4 10             	add    $0x10,%esp
f010162f:	85 c0                	test   %eax,%eax
f0101631:	78 19                	js     f010164c <mem_init+0x681>
f0101633:	68 a4 4c 10 f0       	push   $0xf0104ca4
f0101638:	68 f2 47 10 f0       	push   $0xf01047f2
f010163d:	68 5b 03 00 00       	push   $0x35b
f0101642:	68 cc 47 10 f0       	push   $0xf01047cc
f0101647:	e8 54 ea ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010164c:	83 ec 0c             	sub    $0xc,%esp
f010164f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101652:	e8 b9 f6 ff ff       	call   f0100d10 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101657:	6a 02                	push   $0x2
f0101659:	6a 00                	push   $0x0
f010165b:	53                   	push   %ebx
f010165c:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101662:	e8 ec f8 ff ff       	call   f0100f53 <page_insert>
f0101667:	83 c4 20             	add    $0x20,%esp
f010166a:	85 c0                	test   %eax,%eax
f010166c:	74 19                	je     f0101687 <mem_init+0x6bc>
f010166e:	68 d4 4c 10 f0       	push   $0xf0104cd4
f0101673:	68 f2 47 10 f0       	push   $0xf01047f2
f0101678:	68 5f 03 00 00       	push   $0x35f
f010167d:	68 cc 47 10 f0       	push   $0xf01047cc
f0101682:	e8 19 ea ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101687:	8b 3d 48 cd 17 f0    	mov    0xf017cd48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010168d:	a1 4c cd 17 f0       	mov    0xf017cd4c,%eax
f0101692:	89 c1                	mov    %eax,%ecx
f0101694:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101697:	8b 17                	mov    (%edi),%edx
f0101699:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010169f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a2:	29 c8                	sub    %ecx,%eax
f01016a4:	c1 f8 03             	sar    $0x3,%eax
f01016a7:	c1 e0 0c             	shl    $0xc,%eax
f01016aa:	39 c2                	cmp    %eax,%edx
f01016ac:	74 19                	je     f01016c7 <mem_init+0x6fc>
f01016ae:	68 04 4d 10 f0       	push   $0xf0104d04
f01016b3:	68 f2 47 10 f0       	push   $0xf01047f2
f01016b8:	68 60 03 00 00       	push   $0x360
f01016bd:	68 cc 47 10 f0       	push   $0xf01047cc
f01016c2:	e8 d9 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01016c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01016cc:	89 f8                	mov    %edi,%eax
f01016ce:	e8 4c f2 ff ff       	call   f010091f <check_va2pa>
f01016d3:	89 da                	mov    %ebx,%edx
f01016d5:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016d8:	c1 fa 03             	sar    $0x3,%edx
f01016db:	c1 e2 0c             	shl    $0xc,%edx
f01016de:	39 d0                	cmp    %edx,%eax
f01016e0:	74 19                	je     f01016fb <mem_init+0x730>
f01016e2:	68 2c 4d 10 f0       	push   $0xf0104d2c
f01016e7:	68 f2 47 10 f0       	push   $0xf01047f2
f01016ec:	68 61 03 00 00       	push   $0x361
f01016f1:	68 cc 47 10 f0       	push   $0xf01047cc
f01016f6:	e8 a5 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01016fb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101700:	74 19                	je     f010171b <mem_init+0x750>
f0101702:	68 ae 49 10 f0       	push   $0xf01049ae
f0101707:	68 f2 47 10 f0       	push   $0xf01047f2
f010170c:	68 62 03 00 00       	push   $0x362
f0101711:	68 cc 47 10 f0       	push   $0xf01047cc
f0101716:	e8 85 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010171b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010171e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101723:	74 19                	je     f010173e <mem_init+0x773>
f0101725:	68 bf 49 10 f0       	push   $0xf01049bf
f010172a:	68 f2 47 10 f0       	push   $0xf01047f2
f010172f:	68 63 03 00 00       	push   $0x363
f0101734:	68 cc 47 10 f0       	push   $0xf01047cc
f0101739:	e8 62 e9 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010173e:	6a 02                	push   $0x2
f0101740:	68 00 10 00 00       	push   $0x1000
f0101745:	56                   	push   %esi
f0101746:	57                   	push   %edi
f0101747:	e8 07 f8 ff ff       	call   f0100f53 <page_insert>
f010174c:	83 c4 10             	add    $0x10,%esp
f010174f:	85 c0                	test   %eax,%eax
f0101751:	74 19                	je     f010176c <mem_init+0x7a1>
f0101753:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0101758:	68 f2 47 10 f0       	push   $0xf01047f2
f010175d:	68 66 03 00 00       	push   $0x366
f0101762:	68 cc 47 10 f0       	push   $0xf01047cc
f0101767:	e8 34 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010176c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101771:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f0101776:	e8 a4 f1 ff ff       	call   f010091f <check_va2pa>
f010177b:	89 f2                	mov    %esi,%edx
f010177d:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f0101783:	c1 fa 03             	sar    $0x3,%edx
f0101786:	c1 e2 0c             	shl    $0xc,%edx
f0101789:	39 d0                	cmp    %edx,%eax
f010178b:	74 19                	je     f01017a6 <mem_init+0x7db>
f010178d:	68 98 4d 10 f0       	push   $0xf0104d98
f0101792:	68 f2 47 10 f0       	push   $0xf01047f2
f0101797:	68 67 03 00 00       	push   $0x367
f010179c:	68 cc 47 10 f0       	push   $0xf01047cc
f01017a1:	e8 fa e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01017a6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017ab:	74 19                	je     f01017c6 <mem_init+0x7fb>
f01017ad:	68 d0 49 10 f0       	push   $0xf01049d0
f01017b2:	68 f2 47 10 f0       	push   $0xf01047f2
f01017b7:	68 68 03 00 00       	push   $0x368
f01017bc:	68 cc 47 10 f0       	push   $0xf01047cc
f01017c1:	e8 da e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01017c6:	83 ec 0c             	sub    $0xc,%esp
f01017c9:	6a 00                	push   $0x0
f01017cb:	e8 d0 f4 ff ff       	call   f0100ca0 <page_alloc>
f01017d0:	83 c4 10             	add    $0x10,%esp
f01017d3:	85 c0                	test   %eax,%eax
f01017d5:	74 19                	je     f01017f0 <mem_init+0x825>
f01017d7:	68 5c 49 10 f0       	push   $0xf010495c
f01017dc:	68 f2 47 10 f0       	push   $0xf01047f2
f01017e1:	68 6b 03 00 00       	push   $0x36b
f01017e6:	68 cc 47 10 f0       	push   $0xf01047cc
f01017eb:	e8 b0 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017f0:	6a 02                	push   $0x2
f01017f2:	68 00 10 00 00       	push   $0x1000
f01017f7:	56                   	push   %esi
f01017f8:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f01017fe:	e8 50 f7 ff ff       	call   f0100f53 <page_insert>
f0101803:	83 c4 10             	add    $0x10,%esp
f0101806:	85 c0                	test   %eax,%eax
f0101808:	74 19                	je     f0101823 <mem_init+0x858>
f010180a:	68 5c 4d 10 f0       	push   $0xf0104d5c
f010180f:	68 f2 47 10 f0       	push   $0xf01047f2
f0101814:	68 6e 03 00 00       	push   $0x36e
f0101819:	68 cc 47 10 f0       	push   $0xf01047cc
f010181e:	e8 7d e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101823:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101828:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f010182d:	e8 ed f0 ff ff       	call   f010091f <check_va2pa>
f0101832:	89 f2                	mov    %esi,%edx
f0101834:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f010183a:	c1 fa 03             	sar    $0x3,%edx
f010183d:	c1 e2 0c             	shl    $0xc,%edx
f0101840:	39 d0                	cmp    %edx,%eax
f0101842:	74 19                	je     f010185d <mem_init+0x892>
f0101844:	68 98 4d 10 f0       	push   $0xf0104d98
f0101849:	68 f2 47 10 f0       	push   $0xf01047f2
f010184e:	68 6f 03 00 00       	push   $0x36f
f0101853:	68 cc 47 10 f0       	push   $0xf01047cc
f0101858:	e8 43 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010185d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101862:	74 19                	je     f010187d <mem_init+0x8b2>
f0101864:	68 d0 49 10 f0       	push   $0xf01049d0
f0101869:	68 f2 47 10 f0       	push   $0xf01047f2
f010186e:	68 70 03 00 00       	push   $0x370
f0101873:	68 cc 47 10 f0       	push   $0xf01047cc
f0101878:	e8 23 e8 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010187d:	83 ec 0c             	sub    $0xc,%esp
f0101880:	6a 00                	push   $0x0
f0101882:	e8 19 f4 ff ff       	call   f0100ca0 <page_alloc>
f0101887:	83 c4 10             	add    $0x10,%esp
f010188a:	85 c0                	test   %eax,%eax
f010188c:	74 19                	je     f01018a7 <mem_init+0x8dc>
f010188e:	68 5c 49 10 f0       	push   $0xf010495c
f0101893:	68 f2 47 10 f0       	push   $0xf01047f2
f0101898:	68 74 03 00 00       	push   $0x374
f010189d:	68 cc 47 10 f0       	push   $0xf01047cc
f01018a2:	e8 f9 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018a7:	8b 15 48 cd 17 f0    	mov    0xf017cd48,%edx
f01018ad:	8b 02                	mov    (%edx),%eax
f01018af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018b4:	89 c1                	mov    %eax,%ecx
f01018b6:	c1 e9 0c             	shr    $0xc,%ecx
f01018b9:	3b 0d 44 cd 17 f0    	cmp    0xf017cd44,%ecx
f01018bf:	72 15                	jb     f01018d6 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018c1:	50                   	push   %eax
f01018c2:	68 c4 4a 10 f0       	push   $0xf0104ac4
f01018c7:	68 77 03 00 00       	push   $0x377
f01018cc:	68 cc 47 10 f0       	push   $0xf01047cc
f01018d1:	e8 ca e7 ff ff       	call   f01000a0 <_panic>
f01018d6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01018de:	83 ec 04             	sub    $0x4,%esp
f01018e1:	6a 00                	push   $0x0
f01018e3:	68 00 10 00 00       	push   $0x1000
f01018e8:	52                   	push   %edx
f01018e9:	e8 81 f4 ff ff       	call   f0100d6f <pgdir_walk>
f01018ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018f1:	8d 57 04             	lea    0x4(%edi),%edx
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	39 d0                	cmp    %edx,%eax
f01018f9:	74 19                	je     f0101914 <mem_init+0x949>
f01018fb:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0101900:	68 f2 47 10 f0       	push   $0xf01047f2
f0101905:	68 78 03 00 00       	push   $0x378
f010190a:	68 cc 47 10 f0       	push   $0xf01047cc
f010190f:	e8 8c e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101914:	6a 06                	push   $0x6
f0101916:	68 00 10 00 00       	push   $0x1000
f010191b:	56                   	push   %esi
f010191c:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101922:	e8 2c f6 ff ff       	call   f0100f53 <page_insert>
f0101927:	83 c4 10             	add    $0x10,%esp
f010192a:	85 c0                	test   %eax,%eax
f010192c:	74 19                	je     f0101947 <mem_init+0x97c>
f010192e:	68 08 4e 10 f0       	push   $0xf0104e08
f0101933:	68 f2 47 10 f0       	push   $0xf01047f2
f0101938:	68 7b 03 00 00       	push   $0x37b
f010193d:	68 cc 47 10 f0       	push   $0xf01047cc
f0101942:	e8 59 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101947:	8b 3d 48 cd 17 f0    	mov    0xf017cd48,%edi
f010194d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101952:	89 f8                	mov    %edi,%eax
f0101954:	e8 c6 ef ff ff       	call   f010091f <check_va2pa>
f0101959:	89 f2                	mov    %esi,%edx
f010195b:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f0101961:	c1 fa 03             	sar    $0x3,%edx
f0101964:	c1 e2 0c             	shl    $0xc,%edx
f0101967:	39 d0                	cmp    %edx,%eax
f0101969:	74 19                	je     f0101984 <mem_init+0x9b9>
f010196b:	68 98 4d 10 f0       	push   $0xf0104d98
f0101970:	68 f2 47 10 f0       	push   $0xf01047f2
f0101975:	68 7c 03 00 00       	push   $0x37c
f010197a:	68 cc 47 10 f0       	push   $0xf01047cc
f010197f:	e8 1c e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101984:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101989:	74 19                	je     f01019a4 <mem_init+0x9d9>
f010198b:	68 d0 49 10 f0       	push   $0xf01049d0
f0101990:	68 f2 47 10 f0       	push   $0xf01047f2
f0101995:	68 7d 03 00 00       	push   $0x37d
f010199a:	68 cc 47 10 f0       	push   $0xf01047cc
f010199f:	e8 fc e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019a4:	83 ec 04             	sub    $0x4,%esp
f01019a7:	6a 00                	push   $0x0
f01019a9:	68 00 10 00 00       	push   $0x1000
f01019ae:	57                   	push   %edi
f01019af:	e8 bb f3 ff ff       	call   f0100d6f <pgdir_walk>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	f6 00 04             	testb  $0x4,(%eax)
f01019ba:	75 19                	jne    f01019d5 <mem_init+0xa0a>
f01019bc:	68 48 4e 10 f0       	push   $0xf0104e48
f01019c1:	68 f2 47 10 f0       	push   $0xf01047f2
f01019c6:	68 7e 03 00 00       	push   $0x37e
f01019cb:	68 cc 47 10 f0       	push   $0xf01047cc
f01019d0:	e8 cb e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019d5:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f01019da:	f6 00 04             	testb  $0x4,(%eax)
f01019dd:	75 19                	jne    f01019f8 <mem_init+0xa2d>
f01019df:	68 e1 49 10 f0       	push   $0xf01049e1
f01019e4:	68 f2 47 10 f0       	push   $0xf01047f2
f01019e9:	68 7f 03 00 00       	push   $0x37f
f01019ee:	68 cc 47 10 f0       	push   $0xf01047cc
f01019f3:	e8 a8 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019f8:	6a 02                	push   $0x2
f01019fa:	68 00 10 00 00       	push   $0x1000
f01019ff:	56                   	push   %esi
f0101a00:	50                   	push   %eax
f0101a01:	e8 4d f5 ff ff       	call   f0100f53 <page_insert>
f0101a06:	83 c4 10             	add    $0x10,%esp
f0101a09:	85 c0                	test   %eax,%eax
f0101a0b:	74 19                	je     f0101a26 <mem_init+0xa5b>
f0101a0d:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0101a12:	68 f2 47 10 f0       	push   $0xf01047f2
f0101a17:	68 82 03 00 00       	push   $0x382
f0101a1c:	68 cc 47 10 f0       	push   $0xf01047cc
f0101a21:	e8 7a e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a26:	83 ec 04             	sub    $0x4,%esp
f0101a29:	6a 00                	push   $0x0
f0101a2b:	68 00 10 00 00       	push   $0x1000
f0101a30:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101a36:	e8 34 f3 ff ff       	call   f0100d6f <pgdir_walk>
f0101a3b:	83 c4 10             	add    $0x10,%esp
f0101a3e:	f6 00 02             	testb  $0x2,(%eax)
f0101a41:	75 19                	jne    f0101a5c <mem_init+0xa91>
f0101a43:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0101a48:	68 f2 47 10 f0       	push   $0xf01047f2
f0101a4d:	68 83 03 00 00       	push   $0x383
f0101a52:	68 cc 47 10 f0       	push   $0xf01047cc
f0101a57:	e8 44 e6 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a5c:	83 ec 04             	sub    $0x4,%esp
f0101a5f:	6a 00                	push   $0x0
f0101a61:	68 00 10 00 00       	push   $0x1000
f0101a66:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101a6c:	e8 fe f2 ff ff       	call   f0100d6f <pgdir_walk>
f0101a71:	83 c4 10             	add    $0x10,%esp
f0101a74:	f6 00 04             	testb  $0x4,(%eax)
f0101a77:	74 19                	je     f0101a92 <mem_init+0xac7>
f0101a79:	68 b0 4e 10 f0       	push   $0xf0104eb0
f0101a7e:	68 f2 47 10 f0       	push   $0xf01047f2
f0101a83:	68 84 03 00 00       	push   $0x384
f0101a88:	68 cc 47 10 f0       	push   $0xf01047cc
f0101a8d:	e8 0e e6 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101a92:	6a 02                	push   $0x2
f0101a94:	68 00 00 40 00       	push   $0x400000
f0101a99:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a9c:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101aa2:	e8 ac f4 ff ff       	call   f0100f53 <page_insert>
f0101aa7:	83 c4 10             	add    $0x10,%esp
f0101aaa:	85 c0                	test   %eax,%eax
f0101aac:	78 19                	js     f0101ac7 <mem_init+0xafc>
f0101aae:	68 e8 4e 10 f0       	push   $0xf0104ee8
f0101ab3:	68 f2 47 10 f0       	push   $0xf01047f2
f0101ab8:	68 87 03 00 00       	push   $0x387
f0101abd:	68 cc 47 10 f0       	push   $0xf01047cc
f0101ac2:	e8 d9 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ac7:	6a 02                	push   $0x2
f0101ac9:	68 00 10 00 00       	push   $0x1000
f0101ace:	53                   	push   %ebx
f0101acf:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101ad5:	e8 79 f4 ff ff       	call   f0100f53 <page_insert>
f0101ada:	83 c4 10             	add    $0x10,%esp
f0101add:	85 c0                	test   %eax,%eax
f0101adf:	74 19                	je     f0101afa <mem_init+0xb2f>
f0101ae1:	68 20 4f 10 f0       	push   $0xf0104f20
f0101ae6:	68 f2 47 10 f0       	push   $0xf01047f2
f0101aeb:	68 8a 03 00 00       	push   $0x38a
f0101af0:	68 cc 47 10 f0       	push   $0xf01047cc
f0101af5:	e8 a6 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101afa:	83 ec 04             	sub    $0x4,%esp
f0101afd:	6a 00                	push   $0x0
f0101aff:	68 00 10 00 00       	push   $0x1000
f0101b04:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101b0a:	e8 60 f2 ff ff       	call   f0100d6f <pgdir_walk>
f0101b0f:	83 c4 10             	add    $0x10,%esp
f0101b12:	f6 00 04             	testb  $0x4,(%eax)
f0101b15:	74 19                	je     f0101b30 <mem_init+0xb65>
f0101b17:	68 b0 4e 10 f0       	push   $0xf0104eb0
f0101b1c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101b21:	68 8b 03 00 00       	push   $0x38b
f0101b26:	68 cc 47 10 f0       	push   $0xf01047cc
f0101b2b:	e8 70 e5 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b30:	8b 3d 48 cd 17 f0    	mov    0xf017cd48,%edi
f0101b36:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b3b:	89 f8                	mov    %edi,%eax
f0101b3d:	e8 dd ed ff ff       	call   f010091f <check_va2pa>
f0101b42:	89 c1                	mov    %eax,%ecx
f0101b44:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b47:	89 d8                	mov    %ebx,%eax
f0101b49:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0101b4f:	c1 f8 03             	sar    $0x3,%eax
f0101b52:	c1 e0 0c             	shl    $0xc,%eax
f0101b55:	39 c1                	cmp    %eax,%ecx
f0101b57:	74 19                	je     f0101b72 <mem_init+0xba7>
f0101b59:	68 5c 4f 10 f0       	push   $0xf0104f5c
f0101b5e:	68 f2 47 10 f0       	push   $0xf01047f2
f0101b63:	68 8e 03 00 00       	push   $0x38e
f0101b68:	68 cc 47 10 f0       	push   $0xf01047cc
f0101b6d:	e8 2e e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b72:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b77:	89 f8                	mov    %edi,%eax
f0101b79:	e8 a1 ed ff ff       	call   f010091f <check_va2pa>
f0101b7e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b81:	74 19                	je     f0101b9c <mem_init+0xbd1>
f0101b83:	68 88 4f 10 f0       	push   $0xf0104f88
f0101b88:	68 f2 47 10 f0       	push   $0xf01047f2
f0101b8d:	68 8f 03 00 00       	push   $0x38f
f0101b92:	68 cc 47 10 f0       	push   $0xf01047cc
f0101b97:	e8 04 e5 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b9c:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ba1:	74 19                	je     f0101bbc <mem_init+0xbf1>
f0101ba3:	68 f7 49 10 f0       	push   $0xf01049f7
f0101ba8:	68 f2 47 10 f0       	push   $0xf01047f2
f0101bad:	68 91 03 00 00       	push   $0x391
f0101bb2:	68 cc 47 10 f0       	push   $0xf01047cc
f0101bb7:	e8 e4 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101bbc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101bc1:	74 19                	je     f0101bdc <mem_init+0xc11>
f0101bc3:	68 08 4a 10 f0       	push   $0xf0104a08
f0101bc8:	68 f2 47 10 f0       	push   $0xf01047f2
f0101bcd:	68 92 03 00 00       	push   $0x392
f0101bd2:	68 cc 47 10 f0       	push   $0xf01047cc
f0101bd7:	e8 c4 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101bdc:	83 ec 0c             	sub    $0xc,%esp
f0101bdf:	6a 00                	push   $0x0
f0101be1:	e8 ba f0 ff ff       	call   f0100ca0 <page_alloc>
f0101be6:	83 c4 10             	add    $0x10,%esp
f0101be9:	39 c6                	cmp    %eax,%esi
f0101beb:	75 04                	jne    f0101bf1 <mem_init+0xc26>
f0101bed:	85 c0                	test   %eax,%eax
f0101bef:	75 19                	jne    f0101c0a <mem_init+0xc3f>
f0101bf1:	68 b8 4f 10 f0       	push   $0xf0104fb8
f0101bf6:	68 f2 47 10 f0       	push   $0xf01047f2
f0101bfb:	68 95 03 00 00       	push   $0x395
f0101c00:	68 cc 47 10 f0       	push   $0xf01047cc
f0101c05:	e8 96 e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c0a:	83 ec 08             	sub    $0x8,%esp
f0101c0d:	6a 00                	push   $0x0
f0101c0f:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101c15:	e8 f7 f2 ff ff       	call   f0100f11 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c1a:	8b 3d 48 cd 17 f0    	mov    0xf017cd48,%edi
f0101c20:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c25:	89 f8                	mov    %edi,%eax
f0101c27:	e8 f3 ec ff ff       	call   f010091f <check_va2pa>
f0101c2c:	83 c4 10             	add    $0x10,%esp
f0101c2f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c32:	74 19                	je     f0101c4d <mem_init+0xc82>
f0101c34:	68 dc 4f 10 f0       	push   $0xf0104fdc
f0101c39:	68 f2 47 10 f0       	push   $0xf01047f2
f0101c3e:	68 99 03 00 00       	push   $0x399
f0101c43:	68 cc 47 10 f0       	push   $0xf01047cc
f0101c48:	e8 53 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c4d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c52:	89 f8                	mov    %edi,%eax
f0101c54:	e8 c6 ec ff ff       	call   f010091f <check_va2pa>
f0101c59:	89 da                	mov    %ebx,%edx
f0101c5b:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f0101c61:	c1 fa 03             	sar    $0x3,%edx
f0101c64:	c1 e2 0c             	shl    $0xc,%edx
f0101c67:	39 d0                	cmp    %edx,%eax
f0101c69:	74 19                	je     f0101c84 <mem_init+0xcb9>
f0101c6b:	68 88 4f 10 f0       	push   $0xf0104f88
f0101c70:	68 f2 47 10 f0       	push   $0xf01047f2
f0101c75:	68 9a 03 00 00       	push   $0x39a
f0101c7a:	68 cc 47 10 f0       	push   $0xf01047cc
f0101c7f:	e8 1c e4 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101c84:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c89:	74 19                	je     f0101ca4 <mem_init+0xcd9>
f0101c8b:	68 ae 49 10 f0       	push   $0xf01049ae
f0101c90:	68 f2 47 10 f0       	push   $0xf01047f2
f0101c95:	68 9b 03 00 00       	push   $0x39b
f0101c9a:	68 cc 47 10 f0       	push   $0xf01047cc
f0101c9f:	e8 fc e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ca4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ca9:	74 19                	je     f0101cc4 <mem_init+0xcf9>
f0101cab:	68 08 4a 10 f0       	push   $0xf0104a08
f0101cb0:	68 f2 47 10 f0       	push   $0xf01047f2
f0101cb5:	68 9c 03 00 00       	push   $0x39c
f0101cba:	68 cc 47 10 f0       	push   $0xf01047cc
f0101cbf:	e8 dc e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101cc4:	6a 00                	push   $0x0
f0101cc6:	68 00 10 00 00       	push   $0x1000
f0101ccb:	53                   	push   %ebx
f0101ccc:	57                   	push   %edi
f0101ccd:	e8 81 f2 ff ff       	call   f0100f53 <page_insert>
f0101cd2:	83 c4 10             	add    $0x10,%esp
f0101cd5:	85 c0                	test   %eax,%eax
f0101cd7:	74 19                	je     f0101cf2 <mem_init+0xd27>
f0101cd9:	68 00 50 10 f0       	push   $0xf0105000
f0101cde:	68 f2 47 10 f0       	push   $0xf01047f2
f0101ce3:	68 9f 03 00 00       	push   $0x39f
f0101ce8:	68 cc 47 10 f0       	push   $0xf01047cc
f0101ced:	e8 ae e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101cf2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cf7:	75 19                	jne    f0101d12 <mem_init+0xd47>
f0101cf9:	68 19 4a 10 f0       	push   $0xf0104a19
f0101cfe:	68 f2 47 10 f0       	push   $0xf01047f2
f0101d03:	68 a0 03 00 00       	push   $0x3a0
f0101d08:	68 cc 47 10 f0       	push   $0xf01047cc
f0101d0d:	e8 8e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101d12:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d15:	74 19                	je     f0101d30 <mem_init+0xd65>
f0101d17:	68 25 4a 10 f0       	push   $0xf0104a25
f0101d1c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101d21:	68 a1 03 00 00       	push   $0x3a1
f0101d26:	68 cc 47 10 f0       	push   $0xf01047cc
f0101d2b:	e8 70 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d30:	83 ec 08             	sub    $0x8,%esp
f0101d33:	68 00 10 00 00       	push   $0x1000
f0101d38:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101d3e:	e8 ce f1 ff ff       	call   f0100f11 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d43:	8b 3d 48 cd 17 f0    	mov    0xf017cd48,%edi
f0101d49:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d4e:	89 f8                	mov    %edi,%eax
f0101d50:	e8 ca eb ff ff       	call   f010091f <check_va2pa>
f0101d55:	83 c4 10             	add    $0x10,%esp
f0101d58:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d5b:	74 19                	je     f0101d76 <mem_init+0xdab>
f0101d5d:	68 dc 4f 10 f0       	push   $0xf0104fdc
f0101d62:	68 f2 47 10 f0       	push   $0xf01047f2
f0101d67:	68 a5 03 00 00       	push   $0x3a5
f0101d6c:	68 cc 47 10 f0       	push   $0xf01047cc
f0101d71:	e8 2a e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d76:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d7b:	89 f8                	mov    %edi,%eax
f0101d7d:	e8 9d eb ff ff       	call   f010091f <check_va2pa>
f0101d82:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d85:	74 19                	je     f0101da0 <mem_init+0xdd5>
f0101d87:	68 38 50 10 f0       	push   $0xf0105038
f0101d8c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101d91:	68 a6 03 00 00       	push   $0x3a6
f0101d96:	68 cc 47 10 f0       	push   $0xf01047cc
f0101d9b:	e8 00 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101da0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101da5:	74 19                	je     f0101dc0 <mem_init+0xdf5>
f0101da7:	68 3a 4a 10 f0       	push   $0xf0104a3a
f0101dac:	68 f2 47 10 f0       	push   $0xf01047f2
f0101db1:	68 a7 03 00 00       	push   $0x3a7
f0101db6:	68 cc 47 10 f0       	push   $0xf01047cc
f0101dbb:	e8 e0 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dc0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dc5:	74 19                	je     f0101de0 <mem_init+0xe15>
f0101dc7:	68 08 4a 10 f0       	push   $0xf0104a08
f0101dcc:	68 f2 47 10 f0       	push   $0xf01047f2
f0101dd1:	68 a8 03 00 00       	push   $0x3a8
f0101dd6:	68 cc 47 10 f0       	push   $0xf01047cc
f0101ddb:	e8 c0 e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101de0:	83 ec 0c             	sub    $0xc,%esp
f0101de3:	6a 00                	push   $0x0
f0101de5:	e8 b6 ee ff ff       	call   f0100ca0 <page_alloc>
f0101dea:	83 c4 10             	add    $0x10,%esp
f0101ded:	85 c0                	test   %eax,%eax
f0101def:	74 04                	je     f0101df5 <mem_init+0xe2a>
f0101df1:	39 c3                	cmp    %eax,%ebx
f0101df3:	74 19                	je     f0101e0e <mem_init+0xe43>
f0101df5:	68 60 50 10 f0       	push   $0xf0105060
f0101dfa:	68 f2 47 10 f0       	push   $0xf01047f2
f0101dff:	68 ab 03 00 00       	push   $0x3ab
f0101e04:	68 cc 47 10 f0       	push   $0xf01047cc
f0101e09:	e8 92 e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e0e:	83 ec 0c             	sub    $0xc,%esp
f0101e11:	6a 00                	push   $0x0
f0101e13:	e8 88 ee ff ff       	call   f0100ca0 <page_alloc>
f0101e18:	83 c4 10             	add    $0x10,%esp
f0101e1b:	85 c0                	test   %eax,%eax
f0101e1d:	74 19                	je     f0101e38 <mem_init+0xe6d>
f0101e1f:	68 5c 49 10 f0       	push   $0xf010495c
f0101e24:	68 f2 47 10 f0       	push   $0xf01047f2
f0101e29:	68 ae 03 00 00       	push   $0x3ae
f0101e2e:	68 cc 47 10 f0       	push   $0xf01047cc
f0101e33:	e8 68 e2 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e38:	8b 0d 48 cd 17 f0    	mov    0xf017cd48,%ecx
f0101e3e:	8b 11                	mov    (%ecx),%edx
f0101e40:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e49:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0101e4f:	c1 f8 03             	sar    $0x3,%eax
f0101e52:	c1 e0 0c             	shl    $0xc,%eax
f0101e55:	39 c2                	cmp    %eax,%edx
f0101e57:	74 19                	je     f0101e72 <mem_init+0xea7>
f0101e59:	68 04 4d 10 f0       	push   $0xf0104d04
f0101e5e:	68 f2 47 10 f0       	push   $0xf01047f2
f0101e63:	68 b1 03 00 00       	push   $0x3b1
f0101e68:	68 cc 47 10 f0       	push   $0xf01047cc
f0101e6d:	e8 2e e2 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101e72:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e7b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e80:	74 19                	je     f0101e9b <mem_init+0xed0>
f0101e82:	68 bf 49 10 f0       	push   $0xf01049bf
f0101e87:	68 f2 47 10 f0       	push   $0xf01047f2
f0101e8c:	68 b3 03 00 00       	push   $0x3b3
f0101e91:	68 cc 47 10 f0       	push   $0xf01047cc
f0101e96:	e8 05 e2 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101e9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ea4:	83 ec 0c             	sub    $0xc,%esp
f0101ea7:	50                   	push   %eax
f0101ea8:	e8 63 ee ff ff       	call   f0100d10 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ead:	83 c4 0c             	add    $0xc,%esp
f0101eb0:	6a 01                	push   $0x1
f0101eb2:	68 00 10 40 00       	push   $0x401000
f0101eb7:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101ebd:	e8 ad ee ff ff       	call   f0100d6f <pgdir_walk>
f0101ec2:	89 c7                	mov    %eax,%edi
f0101ec4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101ec7:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f0101ecc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ecf:	8b 40 04             	mov    0x4(%eax),%eax
f0101ed2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ed7:	8b 0d 44 cd 17 f0    	mov    0xf017cd44,%ecx
f0101edd:	89 c2                	mov    %eax,%edx
f0101edf:	c1 ea 0c             	shr    $0xc,%edx
f0101ee2:	83 c4 10             	add    $0x10,%esp
f0101ee5:	39 ca                	cmp    %ecx,%edx
f0101ee7:	72 15                	jb     f0101efe <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ee9:	50                   	push   %eax
f0101eea:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0101eef:	68 ba 03 00 00       	push   $0x3ba
f0101ef4:	68 cc 47 10 f0       	push   $0xf01047cc
f0101ef9:	e8 a2 e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101efe:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f03:	39 c7                	cmp    %eax,%edi
f0101f05:	74 19                	je     f0101f20 <mem_init+0xf55>
f0101f07:	68 4b 4a 10 f0       	push   $0xf0104a4b
f0101f0c:	68 f2 47 10 f0       	push   $0xf01047f2
f0101f11:	68 bb 03 00 00       	push   $0x3bb
f0101f16:	68 cc 47 10 f0       	push   $0xf01047cc
f0101f1b:	e8 80 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f20:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f23:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f33:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0101f39:	c1 f8 03             	sar    $0x3,%eax
f0101f3c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f3f:	89 c2                	mov    %eax,%edx
f0101f41:	c1 ea 0c             	shr    $0xc,%edx
f0101f44:	39 d1                	cmp    %edx,%ecx
f0101f46:	77 12                	ja     f0101f5a <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f48:	50                   	push   %eax
f0101f49:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0101f4e:	6a 56                	push   $0x56
f0101f50:	68 d8 47 10 f0       	push   $0xf01047d8
f0101f55:	e8 46 e1 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f5a:	83 ec 04             	sub    $0x4,%esp
f0101f5d:	68 00 10 00 00       	push   $0x1000
f0101f62:	68 ff 00 00 00       	push   $0xff
f0101f67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f6c:	50                   	push   %eax
f0101f6d:	e8 03 1f 00 00       	call   f0103e75 <memset>
	page_free(pp0);
f0101f72:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f75:	89 3c 24             	mov    %edi,(%esp)
f0101f78:	e8 93 ed ff ff       	call   f0100d10 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f7d:	83 c4 0c             	add    $0xc,%esp
f0101f80:	6a 01                	push   $0x1
f0101f82:	6a 00                	push   $0x0
f0101f84:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0101f8a:	e8 e0 ed ff ff       	call   f0100d6f <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f8f:	89 fa                	mov    %edi,%edx
f0101f91:	2b 15 4c cd 17 f0    	sub    0xf017cd4c,%edx
f0101f97:	c1 fa 03             	sar    $0x3,%edx
f0101f9a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f9d:	89 d0                	mov    %edx,%eax
f0101f9f:	c1 e8 0c             	shr    $0xc,%eax
f0101fa2:	83 c4 10             	add    $0x10,%esp
f0101fa5:	3b 05 44 cd 17 f0    	cmp    0xf017cd44,%eax
f0101fab:	72 12                	jb     f0101fbf <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fad:	52                   	push   %edx
f0101fae:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0101fb3:	6a 56                	push   $0x56
f0101fb5:	68 d8 47 10 f0       	push   $0xf01047d8
f0101fba:	e8 e1 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101fbf:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fc5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fc8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fce:	f6 00 01             	testb  $0x1,(%eax)
f0101fd1:	74 19                	je     f0101fec <mem_init+0x1021>
f0101fd3:	68 63 4a 10 f0       	push   $0xf0104a63
f0101fd8:	68 f2 47 10 f0       	push   $0xf01047f2
f0101fdd:	68 c5 03 00 00       	push   $0x3c5
f0101fe2:	68 cc 47 10 f0       	push   $0xf01047cc
f0101fe7:	e8 b4 e0 ff ff       	call   f01000a0 <_panic>
f0101fec:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101fef:	39 d0                	cmp    %edx,%eax
f0101ff1:	75 db                	jne    f0101fce <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101ff3:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f0101ff8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101ffe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102001:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102007:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010200a:	89 3d 7c c0 17 f0    	mov    %edi,0xf017c07c

	// free the pages we took
	page_free(pp0);
f0102010:	83 ec 0c             	sub    $0xc,%esp
f0102013:	50                   	push   %eax
f0102014:	e8 f7 ec ff ff       	call   f0100d10 <page_free>
	page_free(pp1);
f0102019:	89 1c 24             	mov    %ebx,(%esp)
f010201c:	e8 ef ec ff ff       	call   f0100d10 <page_free>
	page_free(pp2);
f0102021:	89 34 24             	mov    %esi,(%esp)
f0102024:	e8 e7 ec ff ff       	call   f0100d10 <page_free>

	cprintf("check_page() succeeded!\n");
f0102029:	c7 04 24 7a 4a 10 f0 	movl   $0xf0104a7a,(%esp)
f0102030:	e8 fb 0d 00 00       	call   f0102e30 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
	boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f0102035:	a1 4c cd 17 f0       	mov    0xf017cd4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010203a:	83 c4 10             	add    $0x10,%esp
f010203d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102042:	77 15                	ja     f0102059 <mem_init+0x108e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102044:	50                   	push   %eax
f0102045:	68 ac 4b 10 f0       	push   $0xf0104bac
f010204a:	68 ce 00 00 00       	push   $0xce
f010204f:	68 cc 47 10 f0       	push   $0xf01047cc
f0102054:	e8 47 e0 ff ff       	call   f01000a0 <_panic>
f0102059:	83 ec 08             	sub    $0x8,%esp
f010205c:	6a 05                	push   $0x5
f010205e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102063:	50                   	push   %eax
f0102064:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102069:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010206e:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f0102073:	e8 e3 ed ff ff       	call   f0100e5b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE,PADDR(envs), PTE_U | PTE_P);
f0102078:	a1 84 c0 17 f0       	mov    0xf017c084,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010207d:	83 c4 10             	add    $0x10,%esp
f0102080:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102085:	77 15                	ja     f010209c <mem_init+0x10d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102087:	50                   	push   %eax
f0102088:	68 ac 4b 10 f0       	push   $0xf0104bac
f010208d:	68 da 00 00 00       	push   $0xda
f0102092:	68 cc 47 10 f0       	push   $0xf01047cc
f0102097:	e8 04 e0 ff ff       	call   f01000a0 <_panic>
f010209c:	83 ec 08             	sub    $0x8,%esp
f010209f:	6a 05                	push   $0x5
f01020a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01020a6:	50                   	push   %eax
f01020a7:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020ac:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01020b1:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f01020b6:	e8 a0 ed ff ff       	call   f0100e5b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020bb:	83 c4 10             	add    $0x10,%esp
f01020be:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01020c3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020c8:	77 15                	ja     f01020df <mem_init+0x1114>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ca:	50                   	push   %eax
f01020cb:	68 ac 4b 10 f0       	push   $0xf0104bac
f01020d0:	68 e6 00 00 00       	push   $0xe6
f01020d5:	68 cc 47 10 f0       	push   $0xf01047cc
f01020da:	e8 c1 df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f01020df:	83 ec 08             	sub    $0x8,%esp
f01020e2:	6a 02                	push   $0x2
f01020e4:	68 00 00 11 00       	push   $0x110000
f01020e9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020ee:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020f3:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f01020f8:	e8 5e ed ff ff       	call   f0100e5b <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f01020fd:	83 c4 08             	add    $0x8,%esp
f0102100:	6a 03                	push   $0x3
f0102102:	6a 00                	push   $0x0
f0102104:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102109:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010210e:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
f0102113:	e8 43 ed ff ff       	call   f0100e5b <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102118:	8b 1d 48 cd 17 f0    	mov    0xf017cd48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010211e:	a1 44 cd 17 f0       	mov    0xf017cd44,%eax
f0102123:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102126:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010212d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102132:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102135:	8b 3d 4c cd 17 f0    	mov    0xf017cd4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010213b:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010213e:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102141:	be 00 00 00 00       	mov    $0x0,%esi
f0102146:	eb 55                	jmp    f010219d <mem_init+0x11d2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102148:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010214e:	89 d8                	mov    %ebx,%eax
f0102150:	e8 ca e7 ff ff       	call   f010091f <check_va2pa>
f0102155:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010215c:	77 15                	ja     f0102173 <mem_init+0x11a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010215e:	57                   	push   %edi
f010215f:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102164:	68 02 03 00 00       	push   $0x302
f0102169:	68 cc 47 10 f0       	push   $0xf01047cc
f010216e:	e8 2d df ff ff       	call   f01000a0 <_panic>
f0102173:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010217a:	39 d0                	cmp    %edx,%eax
f010217c:	74 19                	je     f0102197 <mem_init+0x11cc>
f010217e:	68 84 50 10 f0       	push   $0xf0105084
f0102183:	68 f2 47 10 f0       	push   $0xf01047f2
f0102188:	68 02 03 00 00       	push   $0x302
f010218d:	68 cc 47 10 f0       	push   $0xf01047cc
f0102192:	e8 09 df ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102197:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010219d:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01021a0:	77 a6                	ja     f0102148 <mem_init+0x117d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01021a2:	8b 3d 84 c0 17 f0    	mov    0xf017c084,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021a8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01021ab:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01021b0:	89 f2                	mov    %esi,%edx
f01021b2:	89 d8                	mov    %ebx,%eax
f01021b4:	e8 66 e7 ff ff       	call   f010091f <check_va2pa>
f01021b9:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01021c0:	77 15                	ja     f01021d7 <mem_init+0x120c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021c2:	57                   	push   %edi
f01021c3:	68 ac 4b 10 f0       	push   $0xf0104bac
f01021c8:	68 07 03 00 00       	push   $0x307
f01021cd:	68 cc 47 10 f0       	push   $0xf01047cc
f01021d2:	e8 c9 de ff ff       	call   f01000a0 <_panic>
f01021d7:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01021de:	39 c2                	cmp    %eax,%edx
f01021e0:	74 19                	je     f01021fb <mem_init+0x1230>
f01021e2:	68 b8 50 10 f0       	push   $0xf01050b8
f01021e7:	68 f2 47 10 f0       	push   $0xf01047f2
f01021ec:	68 07 03 00 00       	push   $0x307
f01021f1:	68 cc 47 10 f0       	push   $0xf01047cc
f01021f6:	e8 a5 de ff ff       	call   f01000a0 <_panic>
f01021fb:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102201:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102207:	75 a7                	jne    f01021b0 <mem_init+0x11e5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102209:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010220c:	c1 e7 0c             	shl    $0xc,%edi
f010220f:	be 00 00 00 00       	mov    $0x0,%esi
f0102214:	eb 30                	jmp    f0102246 <mem_init+0x127b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102216:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010221c:	89 d8                	mov    %ebx,%eax
f010221e:	e8 fc e6 ff ff       	call   f010091f <check_va2pa>
f0102223:	39 c6                	cmp    %eax,%esi
f0102225:	74 19                	je     f0102240 <mem_init+0x1275>
f0102227:	68 ec 50 10 f0       	push   $0xf01050ec
f010222c:	68 f2 47 10 f0       	push   $0xf01047f2
f0102231:	68 0b 03 00 00       	push   $0x30b
f0102236:	68 cc 47 10 f0       	push   $0xf01047cc
f010223b:	e8 60 de ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102240:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102246:	39 fe                	cmp    %edi,%esi
f0102248:	72 cc                	jb     f0102216 <mem_init+0x124b>
f010224a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010224f:	89 f2                	mov    %esi,%edx
f0102251:	89 d8                	mov    %ebx,%eax
f0102253:	e8 c7 e6 ff ff       	call   f010091f <check_va2pa>
f0102258:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f010225e:	39 c2                	cmp    %eax,%edx
f0102260:	74 19                	je     f010227b <mem_init+0x12b0>
f0102262:	68 14 51 10 f0       	push   $0xf0105114
f0102267:	68 f2 47 10 f0       	push   $0xf01047f2
f010226c:	68 0f 03 00 00       	push   $0x30f
f0102271:	68 cc 47 10 f0       	push   $0xf01047cc
f0102276:	e8 25 de ff ff       	call   f01000a0 <_panic>
f010227b:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102281:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102287:	75 c6                	jne    f010224f <mem_init+0x1284>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102289:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010228e:	89 d8                	mov    %ebx,%eax
f0102290:	e8 8a e6 ff ff       	call   f010091f <check_va2pa>
f0102295:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102298:	74 51                	je     f01022eb <mem_init+0x1320>
f010229a:	68 5c 51 10 f0       	push   $0xf010515c
f010229f:	68 f2 47 10 f0       	push   $0xf01047f2
f01022a4:	68 10 03 00 00       	push   $0x310
f01022a9:	68 cc 47 10 f0       	push   $0xf01047cc
f01022ae:	e8 ed dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022b3:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01022b8:	72 36                	jb     f01022f0 <mem_init+0x1325>
f01022ba:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022bf:	76 07                	jbe    f01022c8 <mem_init+0x12fd>
f01022c1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022c6:	75 28                	jne    f01022f0 <mem_init+0x1325>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01022c8:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01022cc:	0f 85 83 00 00 00    	jne    f0102355 <mem_init+0x138a>
f01022d2:	68 93 4a 10 f0       	push   $0xf0104a93
f01022d7:	68 f2 47 10 f0       	push   $0xf01047f2
f01022dc:	68 19 03 00 00       	push   $0x319
f01022e1:	68 cc 47 10 f0       	push   $0xf01047cc
f01022e6:	e8 b5 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022eb:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022f5:	76 3f                	jbe    f0102336 <mem_init+0x136b>
				assert(pgdir[i] & PTE_P);
f01022f7:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01022fa:	f6 c2 01             	test   $0x1,%dl
f01022fd:	75 19                	jne    f0102318 <mem_init+0x134d>
f01022ff:	68 93 4a 10 f0       	push   $0xf0104a93
f0102304:	68 f2 47 10 f0       	push   $0xf01047f2
f0102309:	68 1d 03 00 00       	push   $0x31d
f010230e:	68 cc 47 10 f0       	push   $0xf01047cc
f0102313:	e8 88 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102318:	f6 c2 02             	test   $0x2,%dl
f010231b:	75 38                	jne    f0102355 <mem_init+0x138a>
f010231d:	68 a4 4a 10 f0       	push   $0xf0104aa4
f0102322:	68 f2 47 10 f0       	push   $0xf01047f2
f0102327:	68 1e 03 00 00       	push   $0x31e
f010232c:	68 cc 47 10 f0       	push   $0xf01047cc
f0102331:	e8 6a dd ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102336:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010233a:	74 19                	je     f0102355 <mem_init+0x138a>
f010233c:	68 b5 4a 10 f0       	push   $0xf0104ab5
f0102341:	68 f2 47 10 f0       	push   $0xf01047f2
f0102346:	68 20 03 00 00       	push   $0x320
f010234b:	68 cc 47 10 f0       	push   $0xf01047cc
f0102350:	e8 4b dd ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102355:	83 c0 01             	add    $0x1,%eax
f0102358:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010235d:	0f 86 50 ff ff ff    	jbe    f01022b3 <mem_init+0x12e8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102363:	83 ec 0c             	sub    $0xc,%esp
f0102366:	68 8c 51 10 f0       	push   $0xf010518c
f010236b:	e8 c0 0a 00 00       	call   f0102e30 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102370:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102375:	83 c4 10             	add    $0x10,%esp
f0102378:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010237d:	77 15                	ja     f0102394 <mem_init+0x13c9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010237f:	50                   	push   %eax
f0102380:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102385:	68 fe 00 00 00       	push   $0xfe
f010238a:	68 cc 47 10 f0       	push   $0xf01047cc
f010238f:	e8 0c dd ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102394:	05 00 00 00 10       	add    $0x10000000,%eax
f0102399:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010239c:	b8 00 00 00 00       	mov    $0x0,%eax
f01023a1:	e8 dd e5 ff ff       	call   f0100983 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023a6:	0f 20 c0             	mov    %cr0,%eax
f01023a9:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023ac:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023b1:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023b4:	83 ec 0c             	sub    $0xc,%esp
f01023b7:	6a 00                	push   $0x0
f01023b9:	e8 e2 e8 ff ff       	call   f0100ca0 <page_alloc>
f01023be:	89 c3                	mov    %eax,%ebx
f01023c0:	83 c4 10             	add    $0x10,%esp
f01023c3:	85 c0                	test   %eax,%eax
f01023c5:	75 19                	jne    f01023e0 <mem_init+0x1415>
f01023c7:	68 b1 48 10 f0       	push   $0xf01048b1
f01023cc:	68 f2 47 10 f0       	push   $0xf01047f2
f01023d1:	68 e0 03 00 00       	push   $0x3e0
f01023d6:	68 cc 47 10 f0       	push   $0xf01047cc
f01023db:	e8 c0 dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01023e0:	83 ec 0c             	sub    $0xc,%esp
f01023e3:	6a 00                	push   $0x0
f01023e5:	e8 b6 e8 ff ff       	call   f0100ca0 <page_alloc>
f01023ea:	89 c7                	mov    %eax,%edi
f01023ec:	83 c4 10             	add    $0x10,%esp
f01023ef:	85 c0                	test   %eax,%eax
f01023f1:	75 19                	jne    f010240c <mem_init+0x1441>
f01023f3:	68 c7 48 10 f0       	push   $0xf01048c7
f01023f8:	68 f2 47 10 f0       	push   $0xf01047f2
f01023fd:	68 e1 03 00 00       	push   $0x3e1
f0102402:	68 cc 47 10 f0       	push   $0xf01047cc
f0102407:	e8 94 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010240c:	83 ec 0c             	sub    $0xc,%esp
f010240f:	6a 00                	push   $0x0
f0102411:	e8 8a e8 ff ff       	call   f0100ca0 <page_alloc>
f0102416:	89 c6                	mov    %eax,%esi
f0102418:	83 c4 10             	add    $0x10,%esp
f010241b:	85 c0                	test   %eax,%eax
f010241d:	75 19                	jne    f0102438 <mem_init+0x146d>
f010241f:	68 dd 48 10 f0       	push   $0xf01048dd
f0102424:	68 f2 47 10 f0       	push   $0xf01047f2
f0102429:	68 e2 03 00 00       	push   $0x3e2
f010242e:	68 cc 47 10 f0       	push   $0xf01047cc
f0102433:	e8 68 dc ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102438:	83 ec 0c             	sub    $0xc,%esp
f010243b:	53                   	push   %ebx
f010243c:	e8 cf e8 ff ff       	call   f0100d10 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102441:	89 f8                	mov    %edi,%eax
f0102443:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0102449:	c1 f8 03             	sar    $0x3,%eax
f010244c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010244f:	89 c2                	mov    %eax,%edx
f0102451:	c1 ea 0c             	shr    $0xc,%edx
f0102454:	83 c4 10             	add    $0x10,%esp
f0102457:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f010245d:	72 12                	jb     f0102471 <mem_init+0x14a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010245f:	50                   	push   %eax
f0102460:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0102465:	6a 56                	push   $0x56
f0102467:	68 d8 47 10 f0       	push   $0xf01047d8
f010246c:	e8 2f dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102471:	83 ec 04             	sub    $0x4,%esp
f0102474:	68 00 10 00 00       	push   $0x1000
f0102479:	6a 01                	push   $0x1
f010247b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102480:	50                   	push   %eax
f0102481:	e8 ef 19 00 00       	call   f0103e75 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102486:	89 f0                	mov    %esi,%eax
f0102488:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f010248e:	c1 f8 03             	sar    $0x3,%eax
f0102491:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102494:	89 c2                	mov    %eax,%edx
f0102496:	c1 ea 0c             	shr    $0xc,%edx
f0102499:	83 c4 10             	add    $0x10,%esp
f010249c:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f01024a2:	72 12                	jb     f01024b6 <mem_init+0x14eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024a4:	50                   	push   %eax
f01024a5:	68 c4 4a 10 f0       	push   $0xf0104ac4
f01024aa:	6a 56                	push   $0x56
f01024ac:	68 d8 47 10 f0       	push   $0xf01047d8
f01024b1:	e8 ea db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024b6:	83 ec 04             	sub    $0x4,%esp
f01024b9:	68 00 10 00 00       	push   $0x1000
f01024be:	6a 02                	push   $0x2
f01024c0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024c5:	50                   	push   %eax
f01024c6:	e8 aa 19 00 00       	call   f0103e75 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024cb:	6a 02                	push   $0x2
f01024cd:	68 00 10 00 00       	push   $0x1000
f01024d2:	57                   	push   %edi
f01024d3:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f01024d9:	e8 75 ea ff ff       	call   f0100f53 <page_insert>
	assert(pp1->pp_ref == 1);
f01024de:	83 c4 20             	add    $0x20,%esp
f01024e1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024e6:	74 19                	je     f0102501 <mem_init+0x1536>
f01024e8:	68 ae 49 10 f0       	push   $0xf01049ae
f01024ed:	68 f2 47 10 f0       	push   $0xf01047f2
f01024f2:	68 e7 03 00 00       	push   $0x3e7
f01024f7:	68 cc 47 10 f0       	push   $0xf01047cc
f01024fc:	e8 9f db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102501:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102508:	01 01 01 
f010250b:	74 19                	je     f0102526 <mem_init+0x155b>
f010250d:	68 ac 51 10 f0       	push   $0xf01051ac
f0102512:	68 f2 47 10 f0       	push   $0xf01047f2
f0102517:	68 e8 03 00 00       	push   $0x3e8
f010251c:	68 cc 47 10 f0       	push   $0xf01047cc
f0102521:	e8 7a db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102526:	6a 02                	push   $0x2
f0102528:	68 00 10 00 00       	push   $0x1000
f010252d:	56                   	push   %esi
f010252e:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f0102534:	e8 1a ea ff ff       	call   f0100f53 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102539:	83 c4 10             	add    $0x10,%esp
f010253c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102543:	02 02 02 
f0102546:	74 19                	je     f0102561 <mem_init+0x1596>
f0102548:	68 d0 51 10 f0       	push   $0xf01051d0
f010254d:	68 f2 47 10 f0       	push   $0xf01047f2
f0102552:	68 ea 03 00 00       	push   $0x3ea
f0102557:	68 cc 47 10 f0       	push   $0xf01047cc
f010255c:	e8 3f db ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102561:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102566:	74 19                	je     f0102581 <mem_init+0x15b6>
f0102568:	68 d0 49 10 f0       	push   $0xf01049d0
f010256d:	68 f2 47 10 f0       	push   $0xf01047f2
f0102572:	68 eb 03 00 00       	push   $0x3eb
f0102577:	68 cc 47 10 f0       	push   $0xf01047cc
f010257c:	e8 1f db ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102581:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102586:	74 19                	je     f01025a1 <mem_init+0x15d6>
f0102588:	68 3a 4a 10 f0       	push   $0xf0104a3a
f010258d:	68 f2 47 10 f0       	push   $0xf01047f2
f0102592:	68 ec 03 00 00       	push   $0x3ec
f0102597:	68 cc 47 10 f0       	push   $0xf01047cc
f010259c:	e8 ff da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025a1:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025a8:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025ab:	89 f0                	mov    %esi,%eax
f01025ad:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f01025b3:	c1 f8 03             	sar    $0x3,%eax
f01025b6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025b9:	89 c2                	mov    %eax,%edx
f01025bb:	c1 ea 0c             	shr    $0xc,%edx
f01025be:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f01025c4:	72 12                	jb     f01025d8 <mem_init+0x160d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025c6:	50                   	push   %eax
f01025c7:	68 c4 4a 10 f0       	push   $0xf0104ac4
f01025cc:	6a 56                	push   $0x56
f01025ce:	68 d8 47 10 f0       	push   $0xf01047d8
f01025d3:	e8 c8 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025d8:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025df:	03 03 03 
f01025e2:	74 19                	je     f01025fd <mem_init+0x1632>
f01025e4:	68 f4 51 10 f0       	push   $0xf01051f4
f01025e9:	68 f2 47 10 f0       	push   $0xf01047f2
f01025ee:	68 ee 03 00 00       	push   $0x3ee
f01025f3:	68 cc 47 10 f0       	push   $0xf01047cc
f01025f8:	e8 a3 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025fd:	83 ec 08             	sub    $0x8,%esp
f0102600:	68 00 10 00 00       	push   $0x1000
f0102605:	ff 35 48 cd 17 f0    	pushl  0xf017cd48
f010260b:	e8 01 e9 ff ff       	call   f0100f11 <page_remove>
	assert(pp2->pp_ref == 0);
f0102610:	83 c4 10             	add    $0x10,%esp
f0102613:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102618:	74 19                	je     f0102633 <mem_init+0x1668>
f010261a:	68 08 4a 10 f0       	push   $0xf0104a08
f010261f:	68 f2 47 10 f0       	push   $0xf01047f2
f0102624:	68 f0 03 00 00       	push   $0x3f0
f0102629:	68 cc 47 10 f0       	push   $0xf01047cc
f010262e:	e8 6d da ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102633:	8b 0d 48 cd 17 f0    	mov    0xf017cd48,%ecx
f0102639:	8b 11                	mov    (%ecx),%edx
f010263b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102641:	89 d8                	mov    %ebx,%eax
f0102643:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f0102649:	c1 f8 03             	sar    $0x3,%eax
f010264c:	c1 e0 0c             	shl    $0xc,%eax
f010264f:	39 c2                	cmp    %eax,%edx
f0102651:	74 19                	je     f010266c <mem_init+0x16a1>
f0102653:	68 04 4d 10 f0       	push   $0xf0104d04
f0102658:	68 f2 47 10 f0       	push   $0xf01047f2
f010265d:	68 f3 03 00 00       	push   $0x3f3
f0102662:	68 cc 47 10 f0       	push   $0xf01047cc
f0102667:	e8 34 da ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010266c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102672:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102677:	74 19                	je     f0102692 <mem_init+0x16c7>
f0102679:	68 bf 49 10 f0       	push   $0xf01049bf
f010267e:	68 f2 47 10 f0       	push   $0xf01047f2
f0102683:	68 f5 03 00 00       	push   $0x3f5
f0102688:	68 cc 47 10 f0       	push   $0xf01047cc
f010268d:	e8 0e da ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102692:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102698:	83 ec 0c             	sub    $0xc,%esp
f010269b:	53                   	push   %ebx
f010269c:	e8 6f e6 ff ff       	call   f0100d10 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026a1:	c7 04 24 20 52 10 f0 	movl   $0xf0105220,(%esp)
f01026a8:	e8 83 07 00 00       	call   f0102e30 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026ad:	83 c4 10             	add    $0x10,%esp
f01026b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026b3:	5b                   	pop    %ebx
f01026b4:	5e                   	pop    %esi
f01026b5:	5f                   	pop    %edi
f01026b6:	5d                   	pop    %ebp
f01026b7:	c3                   	ret    

f01026b8 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026b8:	55                   	push   %ebp
f01026b9:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026be:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026c1:	5d                   	pop    %ebp
f01026c2:	c3                   	ret    

f01026c3 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01026c3:	55                   	push   %ebp
f01026c4:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01026c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01026cb:	5d                   	pop    %ebp
f01026cc:	c3                   	ret    

f01026cd <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01026cd:	55                   	push   %ebp
f01026ce:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01026d0:	5d                   	pop    %ebp
f01026d1:	c3                   	ret    

f01026d2 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01026d2:	55                   	push   %ebp
f01026d3:	89 e5                	mov    %esp,%ebp
f01026d5:	57                   	push   %edi
f01026d6:	56                   	push   %esi
f01026d7:	53                   	push   %ebx
f01026d8:	83 ec 0c             	sub    $0xc,%esp
f01026db:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
f01026dd:	89 d3                	mov    %edx,%ebx
f01026df:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
f01026e5:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01026ec:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while(startadd<endadd)
f01026f2:	eb 59                	jmp    f010274d <region_alloc+0x7b>
	{
	struct PageInfo* p=page_alloc(false);	
f01026f4:	83 ec 0c             	sub    $0xc,%esp
f01026f7:	6a 00                	push   $0x0
f01026f9:	e8 a2 e5 ff ff       	call   f0100ca0 <page_alloc>
	
	if(p==NULL)
f01026fe:	83 c4 10             	add    $0x10,%esp
f0102701:	85 c0                	test   %eax,%eax
f0102703:	75 17                	jne    f010271c <region_alloc+0x4a>
	panic("Fail to alloc a page right now in region_alloc");
f0102705:	83 ec 04             	sub    $0x4,%esp
f0102708:	68 4c 52 10 f0       	push   $0xf010524c
f010270d:	68 31 01 00 00       	push   $0x131
f0102712:	68 b2 52 10 f0       	push   $0xf01052b2
f0102717:	e8 84 d9 ff ff       	call   f01000a0 <_panic>
	
	if(page_insert(e->env_pgdir,p,(void *)startadd,PTE_U|PTE_W)==-E_NO_MEM)
f010271c:	6a 06                	push   $0x6
f010271e:	53                   	push   %ebx
f010271f:	50                   	push   %eax
f0102720:	ff 77 5c             	pushl  0x5c(%edi)
f0102723:	e8 2b e8 ff ff       	call   f0100f53 <page_insert>
f0102728:	83 c4 10             	add    $0x10,%esp
f010272b:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010272e:	75 17                	jne    f0102747 <region_alloc+0x75>
	panic("page insert failed");
f0102730:	83 ec 04             	sub    $0x4,%esp
f0102733:	68 bd 52 10 f0       	push   $0xf01052bd
f0102738:	68 34 01 00 00       	push   $0x134
f010273d:	68 b2 52 10 f0       	push   $0xf01052b2
f0102742:	e8 59 d9 ff ff       	call   f01000a0 <_panic>
	
	startadd+=PGSIZE;
f0102747:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
	
	while(startadd<endadd)
f010274d:	39 f3                	cmp    %esi,%ebx
f010274f:	72 a3                	jb     f01026f4 <region_alloc+0x22>
	
	startadd+=PGSIZE;
		
	}
	
}
f0102751:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102754:	5b                   	pop    %ebx
f0102755:	5e                   	pop    %esi
f0102756:	5f                   	pop    %edi
f0102757:	5d                   	pop    %ebp
f0102758:	c3                   	ret    

f0102759 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102759:	55                   	push   %ebp
f010275a:	89 e5                	mov    %esp,%ebp
f010275c:	8b 55 08             	mov    0x8(%ebp),%edx
f010275f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102762:	85 d2                	test   %edx,%edx
f0102764:	75 11                	jne    f0102777 <envid2env+0x1e>
		*env_store = curenv;
f0102766:	a1 80 c0 17 f0       	mov    0xf017c080,%eax
f010276b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010276e:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102770:	b8 00 00 00 00       	mov    $0x0,%eax
f0102775:	eb 5e                	jmp    f01027d5 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102777:	89 d0                	mov    %edx,%eax
f0102779:	25 ff 03 00 00       	and    $0x3ff,%eax
f010277e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102781:	c1 e0 05             	shl    $0x5,%eax
f0102784:	03 05 84 c0 17 f0    	add    0xf017c084,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010278a:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010278e:	74 05                	je     f0102795 <envid2env+0x3c>
f0102790:	3b 50 48             	cmp    0x48(%eax),%edx
f0102793:	74 10                	je     f01027a5 <envid2env+0x4c>
		*env_store = 0;
f0102795:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102798:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010279e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027a3:	eb 30                	jmp    f01027d5 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01027a5:	84 c9                	test   %cl,%cl
f01027a7:	74 22                	je     f01027cb <envid2env+0x72>
f01027a9:	8b 15 80 c0 17 f0    	mov    0xf017c080,%edx
f01027af:	39 d0                	cmp    %edx,%eax
f01027b1:	74 18                	je     f01027cb <envid2env+0x72>
f01027b3:	8b 4a 48             	mov    0x48(%edx),%ecx
f01027b6:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01027b9:	74 10                	je     f01027cb <envid2env+0x72>
		*env_store = 0;
f01027bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027be:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01027c4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027c9:	eb 0a                	jmp    f01027d5 <envid2env+0x7c>
	}

	*env_store = e;
f01027cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027ce:	89 01                	mov    %eax,(%ecx)
	return 0;
f01027d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027d5:	5d                   	pop    %ebp
f01027d6:	c3                   	ret    

f01027d7 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01027d7:	55                   	push   %ebp
f01027d8:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01027da:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01027df:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01027e2:	b8 23 00 00 00       	mov    $0x23,%eax
f01027e7:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01027e9:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01027eb:	b8 10 00 00 00       	mov    $0x10,%eax
f01027f0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01027f2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01027f4:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01027f6:	ea fd 27 10 f0 08 00 	ljmp   $0x8,$0xf01027fd
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01027fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102802:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102805:	5d                   	pop    %ebp
f0102806:	c3                   	ret    

f0102807 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102807:	55                   	push   %ebp
f0102808:	89 e5                	mov    %esp,%ebp
f010280a:	56                   	push   %esi
f010280b:	53                   	push   %ebx
	cprintf("eNV INIT BEGIN \n");
f010280c:	83 ec 0c             	sub    $0xc,%esp
f010280f:	68 d0 52 10 f0       	push   $0xf01052d0
f0102814:	e8 17 06 00 00       	call   f0102e30 <cprintf>
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
		envs[i].env_link = env_free_list;
f0102819:	8b 35 84 c0 17 f0    	mov    0xf017c084,%esi
f010281f:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102825:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102828:	83 c4 10             	add    $0x10,%esp
f010282b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102830:	89 c1                	mov    %eax,%ecx
f0102832:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f0102835:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f010283c:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f010283f:	89 ca                	mov    %ecx,%edx
	// Set up envs array
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
f0102841:	39 d8                	cmp    %ebx,%eax
f0102843:	75 eb                	jne    f0102830 <env_init+0x29>
f0102845:	89 35 88 c0 17 f0    	mov    %esi,0xf017c088
		envs[i].env_link = env_free_list;
		envs[i].env_status = ENV_FREE;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f010284b:	e8 87 ff ff ff       	call   f01027d7 <env_init_percpu>
	
	cprintf("eNV INIT End \n");
f0102850:	83 ec 0c             	sub    $0xc,%esp
f0102853:	68 e1 52 10 f0       	push   $0xf01052e1
f0102858:	e8 d3 05 00 00       	call   f0102e30 <cprintf>
}
f010285d:	83 c4 10             	add    $0x10,%esp
f0102860:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102863:	5b                   	pop    %ebx
f0102864:	5e                   	pop    %esi
f0102865:	5d                   	pop    %ebp
f0102866:	c3                   	ret    

f0102867 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102867:	55                   	push   %ebp
f0102868:	89 e5                	mov    %esp,%ebp
f010286a:	53                   	push   %ebx
f010286b:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010286e:	8b 1d 88 c0 17 f0    	mov    0xf017c088,%ebx
f0102874:	85 db                	test   %ebx,%ebx
f0102876:	0f 84 5e 01 00 00    	je     f01029da <env_alloc+0x173>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010287c:	83 ec 0c             	sub    $0xc,%esp
f010287f:	6a 01                	push   $0x1
f0102881:	e8 1a e4 ff ff       	call   f0100ca0 <page_alloc>
f0102886:	83 c4 10             	add    $0x10,%esp
f0102889:	85 c0                	test   %eax,%eax
f010288b:	0f 84 50 01 00 00    	je     f01029e1 <env_alloc+0x17a>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	
	p->pp_ref++;
f0102891:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102896:	2b 05 4c cd 17 f0    	sub    0xf017cd4c,%eax
f010289c:	c1 f8 03             	sar    $0x3,%eax
f010289f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028a2:	89 c2                	mov    %eax,%edx
f01028a4:	c1 ea 0c             	shr    $0xc,%edx
f01028a7:	3b 15 44 cd 17 f0    	cmp    0xf017cd44,%edx
f01028ad:	72 12                	jb     f01028c1 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028af:	50                   	push   %eax
f01028b0:	68 c4 4a 10 f0       	push   $0xf0104ac4
f01028b5:	6a 56                	push   $0x56
f01028b7:	68 d8 47 10 f0       	push   $0xf01047d8
f01028bc:	e8 df d7 ff ff       	call   f01000a0 <_panic>
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
f01028c1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01028c6:	89 43 5c             	mov    %eax,0x5c(%ebx)
f01028c9:	b8 00 00 00 00       	mov    $0x0,%eax
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
f01028ce:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01028d1:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01028d8:	83 c0 04             	add    $0x4,%eax
	p->pp_ref++;
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f01028db:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01028e0:	75 ec                	jne    f01028ce <env_alloc+0x67>
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];	
f01028e2:	8b 15 48 cd 17 f0    	mov    0xf017cd48,%edx
f01028e8:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01028eb:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01028ee:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01028f1:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f01028f4:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01028f9:	75 e7                	jne    f01028e2 <env_alloc+0x7b>
		
	
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01028fb:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102903:	77 15                	ja     f010291a <env_alloc+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102905:	50                   	push   %eax
f0102906:	68 ac 4b 10 f0       	push   $0xf0104bac
f010290b:	68 d3 00 00 00       	push   $0xd3
f0102910:	68 b2 52 10 f0       	push   $0xf01052b2
f0102915:	e8 86 d7 ff ff       	call   f01000a0 <_panic>
f010291a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102920:	83 ca 05             	or     $0x5,%edx
f0102923:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102929:	8b 43 48             	mov    0x48(%ebx),%eax
f010292c:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102931:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102936:	ba 00 10 00 00       	mov    $0x1000,%edx
f010293b:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010293e:	89 da                	mov    %ebx,%edx
f0102940:	2b 15 84 c0 17 f0    	sub    0xf017c084,%edx
f0102946:	c1 fa 05             	sar    $0x5,%edx
f0102949:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010294f:	09 d0                	or     %edx,%eax
f0102951:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102954:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102957:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010295a:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102961:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102968:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010296f:	83 ec 04             	sub    $0x4,%esp
f0102972:	6a 44                	push   $0x44
f0102974:	6a 00                	push   $0x0
f0102976:	53                   	push   %ebx
f0102977:	e8 f9 14 00 00       	call   f0103e75 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010297c:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102982:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102988:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010298e:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102995:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010299b:	8b 43 44             	mov    0x44(%ebx),%eax
f010299e:	a3 88 c0 17 f0       	mov    %eax,0xf017c088
	*newenv_store = e;
f01029a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01029a6:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01029a8:	8b 53 48             	mov    0x48(%ebx),%edx
f01029ab:	a1 80 c0 17 f0       	mov    0xf017c080,%eax
f01029b0:	83 c4 10             	add    $0x10,%esp
f01029b3:	85 c0                	test   %eax,%eax
f01029b5:	74 05                	je     f01029bc <env_alloc+0x155>
f01029b7:	8b 40 48             	mov    0x48(%eax),%eax
f01029ba:	eb 05                	jmp    f01029c1 <env_alloc+0x15a>
f01029bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01029c1:	83 ec 04             	sub    $0x4,%esp
f01029c4:	52                   	push   %edx
f01029c5:	50                   	push   %eax
f01029c6:	68 f0 52 10 f0       	push   $0xf01052f0
f01029cb:	e8 60 04 00 00       	call   f0102e30 <cprintf>
	return 0;
f01029d0:	83 c4 10             	add    $0x10,%esp
f01029d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01029d8:	eb 0c                	jmp    f01029e6 <env_alloc+0x17f>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01029da:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01029df:	eb 05                	jmp    f01029e6 <env_alloc+0x17f>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01029e1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01029e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01029e9:	c9                   	leave  
f01029ea:	c3                   	ret    

f01029eb <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01029eb:	55                   	push   %ebp
f01029ec:	89 e5                	mov    %esp,%ebp
f01029ee:	57                   	push   %edi
f01029ef:	56                   	push   %esi
f01029f0:	53                   	push   %ebx
f01029f1:	83 ec 34             	sub    $0x34,%esp
f01029f4:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *env;
	
	int check;
	check = env_alloc(&env, 0);
f01029f7:	6a 00                	push   $0x0
f01029f9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01029fc:	50                   	push   %eax
f01029fd:	e8 65 fe ff ff       	call   f0102867 <env_alloc>
	
	if (check < 0) {
f0102a02:	83 c4 10             	add    $0x10,%esp
f0102a05:	85 c0                	test   %eax,%eax
f0102a07:	79 15                	jns    f0102a1e <env_create+0x33>
		panic("env_alloc: %e", check);
f0102a09:	50                   	push   %eax
f0102a0a:	68 05 53 10 f0       	push   $0xf0105305
f0102a0f:	68 b9 01 00 00       	push   $0x1b9
f0102a14:	68 b2 52 10 f0       	push   $0xf01052b2
f0102a19:	e8 82 d6 ff ff       	call   f01000a0 <_panic>
		return;
	}
	
	load_icode(env, binary);
f0102a1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	
		// read 1st page off disk
	//readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
	
	lcr3(PADDR(e->env_pgdir));
f0102a24:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a27:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a2c:	77 15                	ja     f0102a43 <env_create+0x58>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a2e:	50                   	push   %eax
f0102a2f:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102a34:	68 7c 01 00 00       	push   $0x17c
f0102a39:	68 b2 52 10 f0       	push   $0xf01052b2
f0102a3e:	e8 5d d6 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a43:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a48:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr *ph, *eph;
	struct Elf * ELFHDR=(struct Elf *) binary;
	// is this a valid ELF?
	
	if (ELFHDR->e_magic != ELF_MAGIC)
f0102a4b:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102a51:	74 17                	je     f0102a6a <env_create+0x7f>
		panic("Not an elf file \n");
f0102a53:	83 ec 04             	sub    $0x4,%esp
f0102a56:	68 13 53 10 f0       	push   $0xf0105313
f0102a5b:	68 82 01 00 00       	push   $0x182
f0102a60:	68 b2 52 10 f0       	push   $0xf01052b2
f0102a65:	e8 36 d6 ff ff       	call   f01000a0 <_panic>

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102a6a:	89 fb                	mov    %edi,%ebx
f0102a6c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102a6f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102a73:	c1 e6 05             	shl    $0x5,%esi
f0102a76:	01 de                	add    %ebx,%esi
	 
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102a78:	8b 47 18             	mov    0x18(%edi),%eax
f0102a7b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a7e:	89 41 30             	mov    %eax,0x30(%ecx)
	cprintf("begin copy  prog seg \n");
f0102a81:	83 ec 0c             	sub    $0xc,%esp
f0102a84:	68 25 53 10 f0       	push   $0xf0105325
f0102a89:	e8 a2 03 00 00       	call   f0102e30 <cprintf>
f0102a8e:	83 c4 10             	add    $0x10,%esp
f0102a91:	eb 60                	jmp    f0102af3 <env_create+0x108>
	
	
	for (; ph < eph; ph++)
{		
	
	if (ph->p_type != ELF_PROG_LOAD) 
f0102a93:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102a96:	75 58                	jne    f0102af0 <env_create+0x105>
	continue;
	
	if (ph->p_filesz > ph->p_memsz)
f0102a98:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102a9b:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0102a9e:	76 17                	jbe    f0102ab7 <env_create+0xcc>
	panic("file size greater \n");
f0102aa0:	83 ec 04             	sub    $0x4,%esp
f0102aa3:	68 3c 53 10 f0       	push   $0xf010533c
f0102aa8:	68 94 01 00 00       	push   $0x194
f0102aad:	68 b2 52 10 f0       	push   $0xf01052b2
f0102ab2:	e8 e9 d5 ff ff       	call   f01000a0 <_panic>
	
	region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0102ab7:	8b 53 08             	mov    0x8(%ebx),%edx
f0102aba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102abd:	e8 10 fc ff ff       	call   f01026d2 <region_alloc>
	
	memcpy((void *) ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0102ac2:	83 ec 04             	sub    $0x4,%esp
f0102ac5:	ff 73 10             	pushl  0x10(%ebx)
f0102ac8:	89 f8                	mov    %edi,%eax
f0102aca:	03 43 04             	add    0x4(%ebx),%eax
f0102acd:	50                   	push   %eax
f0102ace:	ff 73 08             	pushl  0x8(%ebx)
f0102ad1:	e8 54 14 00 00       	call   f0103f2a <memcpy>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
f0102ad6:	8b 43 10             	mov    0x10(%ebx),%eax
f0102ad9:	83 c4 0c             	add    $0xc,%esp
f0102adc:	8b 53 14             	mov    0x14(%ebx),%edx
f0102adf:	29 c2                	sub    %eax,%edx
f0102ae1:	52                   	push   %edx
f0102ae2:	6a 00                	push   $0x0
f0102ae4:	03 43 08             	add    0x8(%ebx),%eax
f0102ae7:	50                   	push   %eax
f0102ae8:	e8 88 13 00 00       	call   f0103e75 <memset>
f0102aed:	83 c4 10             	add    $0x10,%esp
	e->env_tf.tf_eip = ELFHDR->e_entry;
	cprintf("begin copy  prog seg \n");
	
	
	
	for (; ph < eph; ph++)
f0102af0:	83 c3 20             	add    $0x20,%ebx
f0102af3:	39 de                	cmp    %ebx,%esi
f0102af5:	77 9c                	ja     f0102a93 <env_create+0xa8>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
	
}
	
   	region_alloc(e, (void *) USTACKTOP - PGSIZE, PGSIZE);
f0102af7:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102afc:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102b01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b04:	e8 c9 fb ff ff       	call   f01026d2 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f0102b09:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b0e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b13:	77 15                	ja     f0102b2a <env_create+0x13f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b15:	50                   	push   %eax
f0102b16:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102b1b:	68 a0 01 00 00       	push   $0x1a0
f0102b20:	68 b2 52 10 f0       	push   $0xf01052b2
f0102b25:	e8 76 d5 ff ff       	call   f01000a0 <_panic>
f0102b2a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b2f:	0f 22 d8             	mov    %eax,%cr3
		panic("env_alloc: %e", check);
		return;
	}
	
	load_icode(env, binary);
	env->env_type = type;
f0102b32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b35:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b38:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102b3b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b3e:	5b                   	pop    %ebx
f0102b3f:	5e                   	pop    %esi
f0102b40:	5f                   	pop    %edi
f0102b41:	5d                   	pop    %ebp
f0102b42:	c3                   	ret    

f0102b43 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102b43:	55                   	push   %ebp
f0102b44:	89 e5                	mov    %esp,%ebp
f0102b46:	57                   	push   %edi
f0102b47:	56                   	push   %esi
f0102b48:	53                   	push   %ebx
f0102b49:	83 ec 1c             	sub    $0x1c,%esp
f0102b4c:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102b4f:	8b 15 80 c0 17 f0    	mov    0xf017c080,%edx
f0102b55:	39 fa                	cmp    %edi,%edx
f0102b57:	75 29                	jne    f0102b82 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102b59:	a1 48 cd 17 f0       	mov    0xf017cd48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b5e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b63:	77 15                	ja     f0102b7a <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b65:	50                   	push   %eax
f0102b66:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102b6b:	68 cf 01 00 00       	push   $0x1cf
f0102b70:	68 b2 52 10 f0       	push   $0xf01052b2
f0102b75:	e8 26 d5 ff ff       	call   f01000a0 <_panic>
f0102b7a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b7f:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b82:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102b85:	85 d2                	test   %edx,%edx
f0102b87:	74 05                	je     f0102b8e <env_free+0x4b>
f0102b89:	8b 42 48             	mov    0x48(%edx),%eax
f0102b8c:	eb 05                	jmp    f0102b93 <env_free+0x50>
f0102b8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b93:	83 ec 04             	sub    $0x4,%esp
f0102b96:	51                   	push   %ecx
f0102b97:	50                   	push   %eax
f0102b98:	68 50 53 10 f0       	push   $0xf0105350
f0102b9d:	e8 8e 02 00 00       	call   f0102e30 <cprintf>
f0102ba2:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ba5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102bac:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102baf:	89 d0                	mov    %edx,%eax
f0102bb1:	c1 e0 02             	shl    $0x2,%eax
f0102bb4:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102bb7:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102bba:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102bbd:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102bc3:	0f 84 a8 00 00 00    	je     f0102c71 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102bc9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bcf:	89 f0                	mov    %esi,%eax
f0102bd1:	c1 e8 0c             	shr    $0xc,%eax
f0102bd4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bd7:	39 05 44 cd 17 f0    	cmp    %eax,0xf017cd44
f0102bdd:	77 15                	ja     f0102bf4 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bdf:	56                   	push   %esi
f0102be0:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0102be5:	68 de 01 00 00       	push   $0x1de
f0102bea:	68 b2 52 10 f0       	push   $0xf01052b2
f0102bef:	e8 ac d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102bf4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bf7:	c1 e0 16             	shl    $0x16,%eax
f0102bfa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102bfd:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102c02:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102c09:	01 
f0102c0a:	74 17                	je     f0102c23 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c0c:	83 ec 08             	sub    $0x8,%esp
f0102c0f:	89 d8                	mov    %ebx,%eax
f0102c11:	c1 e0 0c             	shl    $0xc,%eax
f0102c14:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102c17:	50                   	push   %eax
f0102c18:	ff 77 5c             	pushl  0x5c(%edi)
f0102c1b:	e8 f1 e2 ff ff       	call   f0100f11 <page_remove>
f0102c20:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c23:	83 c3 01             	add    $0x1,%ebx
f0102c26:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102c2c:	75 d4                	jne    f0102c02 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102c2e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c31:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102c34:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102c3e:	3b 05 44 cd 17 f0    	cmp    0xf017cd44,%eax
f0102c44:	72 14                	jb     f0102c5a <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102c46:	83 ec 04             	sub    $0x4,%esp
f0102c49:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0102c4e:	6a 4f                	push   $0x4f
f0102c50:	68 d8 47 10 f0       	push   $0xf01047d8
f0102c55:	e8 46 d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102c5a:	83 ec 0c             	sub    $0xc,%esp
f0102c5d:	a1 4c cd 17 f0       	mov    0xf017cd4c,%eax
f0102c62:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c65:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102c68:	50                   	push   %eax
f0102c69:	e8 da e0 ff ff       	call   f0100d48 <page_decref>
f0102c6e:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c71:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102c75:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c78:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c7d:	0f 85 29 ff ff ff    	jne    f0102bac <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102c83:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c86:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c8b:	77 15                	ja     f0102ca2 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c8d:	50                   	push   %eax
f0102c8e:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102c93:	68 ec 01 00 00       	push   $0x1ec
f0102c98:	68 b2 52 10 f0       	push   $0xf01052b2
f0102c9d:	e8 fe d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102ca2:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ca9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cae:	c1 e8 0c             	shr    $0xc,%eax
f0102cb1:	3b 05 44 cd 17 f0    	cmp    0xf017cd44,%eax
f0102cb7:	72 14                	jb     f0102ccd <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102cb9:	83 ec 04             	sub    $0x4,%esp
f0102cbc:	68 d0 4b 10 f0       	push   $0xf0104bd0
f0102cc1:	6a 4f                	push   $0x4f
f0102cc3:	68 d8 47 10 f0       	push   $0xf01047d8
f0102cc8:	e8 d3 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102ccd:	83 ec 0c             	sub    $0xc,%esp
f0102cd0:	8b 15 4c cd 17 f0    	mov    0xf017cd4c,%edx
f0102cd6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102cd9:	50                   	push   %eax
f0102cda:	e8 69 e0 ff ff       	call   f0100d48 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102cdf:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102ce6:	a1 88 c0 17 f0       	mov    0xf017c088,%eax
f0102ceb:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102cee:	89 3d 88 c0 17 f0    	mov    %edi,0xf017c088
}
f0102cf4:	83 c4 10             	add    $0x10,%esp
f0102cf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cfa:	5b                   	pop    %ebx
f0102cfb:	5e                   	pop    %esi
f0102cfc:	5f                   	pop    %edi
f0102cfd:	5d                   	pop    %ebp
f0102cfe:	c3                   	ret    

f0102cff <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102cff:	55                   	push   %ebp
f0102d00:	89 e5                	mov    %esp,%ebp
f0102d02:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102d05:	ff 75 08             	pushl  0x8(%ebp)
f0102d08:	e8 36 fe ff ff       	call   f0102b43 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102d0d:	c7 04 24 7c 52 10 f0 	movl   $0xf010527c,(%esp)
f0102d14:	e8 17 01 00 00       	call   f0102e30 <cprintf>
f0102d19:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102d1c:	83 ec 0c             	sub    $0xc,%esp
f0102d1f:	6a 00                	push   $0x0
f0102d21:	e8 0c da ff ff       	call   f0100732 <monitor>
f0102d26:	83 c4 10             	add    $0x10,%esp
f0102d29:	eb f1                	jmp    f0102d1c <env_destroy+0x1d>

f0102d2b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102d2b:	55                   	push   %ebp
f0102d2c:	89 e5                	mov    %esp,%ebp
f0102d2e:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102d31:	8b 65 08             	mov    0x8(%ebp),%esp
f0102d34:	61                   	popa   
f0102d35:	07                   	pop    %es
f0102d36:	1f                   	pop    %ds
f0102d37:	83 c4 08             	add    $0x8,%esp
f0102d3a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102d3b:	68 66 53 10 f0       	push   $0xf0105366
f0102d40:	68 15 02 00 00       	push   $0x215
f0102d45:	68 b2 52 10 f0       	push   $0xf01052b2
f0102d4a:	e8 51 d3 ff ff       	call   f01000a0 <_panic>

f0102d4f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102d4f:	55                   	push   %ebp
f0102d50:	89 e5                	mov    %esp,%ebp
f0102d52:	83 ec 08             	sub    $0x8,%esp
f0102d55:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// env_status : ENV_FREE, ENV_RUNNABLE, ENV_RUNNING, ENV_NOT_RUNNABLE

	if (curenv == NULL || curenv!= e) 
f0102d58:	8b 15 80 c0 17 f0    	mov    0xf017c080,%edx
f0102d5e:	39 c2                	cmp    %eax,%edx
f0102d60:	75 04                	jne    f0102d66 <env_run+0x17>
f0102d62:	85 d2                	test   %edx,%edx
f0102d64:	75 48                	jne    f0102dae <env_run+0x5f>
	{
		if (curenv && curenv->env_status == ENV_RUNNING)
f0102d66:	85 d2                	test   %edx,%edx
f0102d68:	74 0d                	je     f0102d77 <env_run+0x28>
f0102d6a:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102d6e:	75 07                	jne    f0102d77 <env_run+0x28>
			
			curenv->env_status = ENV_RUNNABLE;
f0102d70:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)

		curenv = e;
f0102d77:	a3 80 c0 17 f0       	mov    %eax,0xf017c080
	
		curenv->env_status = ENV_RUNNING;
f0102d7c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		curenv->env_runs++;
f0102d83:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f0102d87:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d8a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d8f:	77 15                	ja     f0102da6 <env_run+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d91:	50                   	push   %eax
f0102d92:	68 ac 4b 10 f0       	push   $0xf0104bac
f0102d97:	68 3f 02 00 00       	push   $0x23f
f0102d9c:	68 b2 52 10 f0       	push   $0xf01052b2
f0102da1:	e8 fa d2 ff ff       	call   f01000a0 <_panic>
f0102da6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dab:	0f 22 d8             	mov    %eax,%cr3
	}

	

	cprintf("after lcr3\n");  //debug
f0102dae:	83 ec 0c             	sub    $0xc,%esp
f0102db1:	68 72 53 10 f0       	push   $0xf0105372
f0102db6:	e8 75 00 00 00       	call   f0102e30 <cprintf>
	env_pop_tf(&(curenv->env_tf));
f0102dbb:	83 c4 04             	add    $0x4,%esp
f0102dbe:	ff 35 80 c0 17 f0    	pushl  0xf017c080
f0102dc4:	e8 62 ff ff ff       	call   f0102d2b <env_pop_tf>

f0102dc9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102dc9:	55                   	push   %ebp
f0102dca:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102dcc:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dd4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102dd5:	ba 71 00 00 00       	mov    $0x71,%edx
f0102dda:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ddb:	0f b6 c0             	movzbl %al,%eax
}
f0102dde:	5d                   	pop    %ebp
f0102ddf:	c3                   	ret    

f0102de0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102de0:	55                   	push   %ebp
f0102de1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102de3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102de8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102deb:	ee                   	out    %al,(%dx)
f0102dec:	ba 71 00 00 00       	mov    $0x71,%edx
f0102df1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102df4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102df5:	5d                   	pop    %ebp
f0102df6:	c3                   	ret    

f0102df7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102df7:	55                   	push   %ebp
f0102df8:	89 e5                	mov    %esp,%ebp
f0102dfa:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102dfd:	ff 75 08             	pushl  0x8(%ebp)
f0102e00:	e8 10 d8 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102e05:	83 c4 10             	add    $0x10,%esp
f0102e08:	c9                   	leave  
f0102e09:	c3                   	ret    

f0102e0a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e0a:	55                   	push   %ebp
f0102e0b:	89 e5                	mov    %esp,%ebp
f0102e0d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e17:	ff 75 0c             	pushl  0xc(%ebp)
f0102e1a:	ff 75 08             	pushl  0x8(%ebp)
f0102e1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e20:	50                   	push   %eax
f0102e21:	68 f7 2d 10 f0       	push   $0xf0102df7
f0102e26:	e8 25 09 00 00       	call   f0103750 <vprintfmt>
	return cnt;
}
f0102e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e2e:	c9                   	leave  
f0102e2f:	c3                   	ret    

f0102e30 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e30:	55                   	push   %ebp
f0102e31:	89 e5                	mov    %esp,%ebp
f0102e33:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e36:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e39:	50                   	push   %eax
f0102e3a:	ff 75 08             	pushl  0x8(%ebp)
f0102e3d:	e8 c8 ff ff ff       	call   f0102e0a <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e42:	c9                   	leave  
f0102e43:	c3                   	ret    

f0102e44 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102e44:	55                   	push   %ebp
f0102e45:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102e47:	b8 c0 c8 17 f0       	mov    $0xf017c8c0,%eax
f0102e4c:	c7 05 c4 c8 17 f0 00 	movl   $0xf0000000,0xf017c8c4
f0102e53:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102e56:	66 c7 05 c8 c8 17 f0 	movw   $0x10,0xf017c8c8
f0102e5d:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102e5f:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102e66:	67 00 
f0102e68:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102e6e:	89 c2                	mov    %eax,%edx
f0102e70:	c1 ea 10             	shr    $0x10,%edx
f0102e73:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102e79:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102e80:	c1 e8 18             	shr    $0x18,%eax
f0102e83:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102e88:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102e8f:	b8 28 00 00 00       	mov    $0x28,%eax
f0102e94:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102e97:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102e9c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102e9f:	5d                   	pop    %ebp
f0102ea0:	c3                   	ret    

f0102ea1 <trap_init>:
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	
		int i = 0;
f0102ea1:	b8 00 00 00 00       	mov    $0x0,%eax
	for ( ; i < 32 ; i++) {
		SETGATE(idt[i], 0, GD_KT, trap_handlers[i], 0);
f0102ea6:	8b 14 85 56 a3 11 f0 	mov    -0xfee5caa(,%eax,4),%edx
f0102ead:	66 89 14 c5 a0 c0 17 	mov    %dx,-0xfe83f60(,%eax,8)
f0102eb4:	f0 
f0102eb5:	66 c7 04 c5 a2 c0 17 	movw   $0x8,-0xfe83f5e(,%eax,8)
f0102ebc:	f0 08 00 
f0102ebf:	c6 04 c5 a4 c0 17 f0 	movb   $0x0,-0xfe83f5c(,%eax,8)
f0102ec6:	00 
f0102ec7:	c6 04 c5 a5 c0 17 f0 	movb   $0x8e,-0xfe83f5b(,%eax,8)
f0102ece:	8e 
f0102ecf:	c1 ea 10             	shr    $0x10,%edx
f0102ed2:	66 89 14 c5 a6 c0 17 	mov    %dx,-0xfe83f5a(,%eax,8)
f0102ed9:	f0 

	// LAB 3: Your code here.
	
	
		int i = 0;
	for ( ; i < 32 ; i++) {
f0102eda:	83 c0 01             	add    $0x1,%eax
f0102edd:	83 f8 20             	cmp    $0x20,%eax
f0102ee0:	75 c4                	jne    f0102ea6 <trap_init+0x5>
}


void
trap_init(void)
{
f0102ee2:	55                   	push   %ebp
f0102ee3:	89 e5                	mov    %esp,%ebp
	for ( ; i < 32 ; i++) {
		SETGATE(idt[i], 0, GD_KT, trap_handlers[i], 0);
	}

	// Per-CPU setup 
	trap_init_percpu();
f0102ee5:	e8 5a ff ff ff       	call   f0102e44 <trap_init_percpu>
}
f0102eea:	5d                   	pop    %ebp
f0102eeb:	c3                   	ret    

f0102eec <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102eec:	55                   	push   %ebp
f0102eed:	89 e5                	mov    %esp,%ebp
f0102eef:	53                   	push   %ebx
f0102ef0:	83 ec 0c             	sub    $0xc,%esp
f0102ef3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102ef6:	ff 33                	pushl  (%ebx)
f0102ef8:	68 7e 53 10 f0       	push   $0xf010537e
f0102efd:	e8 2e ff ff ff       	call   f0102e30 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102f02:	83 c4 08             	add    $0x8,%esp
f0102f05:	ff 73 04             	pushl  0x4(%ebx)
f0102f08:	68 8d 53 10 f0       	push   $0xf010538d
f0102f0d:	e8 1e ff ff ff       	call   f0102e30 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102f12:	83 c4 08             	add    $0x8,%esp
f0102f15:	ff 73 08             	pushl  0x8(%ebx)
f0102f18:	68 9c 53 10 f0       	push   $0xf010539c
f0102f1d:	e8 0e ff ff ff       	call   f0102e30 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102f22:	83 c4 08             	add    $0x8,%esp
f0102f25:	ff 73 0c             	pushl  0xc(%ebx)
f0102f28:	68 ab 53 10 f0       	push   $0xf01053ab
f0102f2d:	e8 fe fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102f32:	83 c4 08             	add    $0x8,%esp
f0102f35:	ff 73 10             	pushl  0x10(%ebx)
f0102f38:	68 ba 53 10 f0       	push   $0xf01053ba
f0102f3d:	e8 ee fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102f42:	83 c4 08             	add    $0x8,%esp
f0102f45:	ff 73 14             	pushl  0x14(%ebx)
f0102f48:	68 c9 53 10 f0       	push   $0xf01053c9
f0102f4d:	e8 de fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102f52:	83 c4 08             	add    $0x8,%esp
f0102f55:	ff 73 18             	pushl  0x18(%ebx)
f0102f58:	68 d8 53 10 f0       	push   $0xf01053d8
f0102f5d:	e8 ce fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102f62:	83 c4 08             	add    $0x8,%esp
f0102f65:	ff 73 1c             	pushl  0x1c(%ebx)
f0102f68:	68 e7 53 10 f0       	push   $0xf01053e7
f0102f6d:	e8 be fe ff ff       	call   f0102e30 <cprintf>
}
f0102f72:	83 c4 10             	add    $0x10,%esp
f0102f75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f78:	c9                   	leave  
f0102f79:	c3                   	ret    

f0102f7a <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102f7a:	55                   	push   %ebp
f0102f7b:	89 e5                	mov    %esp,%ebp
f0102f7d:	56                   	push   %esi
f0102f7e:	53                   	push   %ebx
f0102f7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102f82:	83 ec 08             	sub    $0x8,%esp
f0102f85:	53                   	push   %ebx
f0102f86:	68 34 55 10 f0       	push   $0xf0105534
f0102f8b:	e8 a0 fe ff ff       	call   f0102e30 <cprintf>
	print_regs(&tf->tf_regs);
f0102f90:	89 1c 24             	mov    %ebx,(%esp)
f0102f93:	e8 54 ff ff ff       	call   f0102eec <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102f98:	83 c4 08             	add    $0x8,%esp
f0102f9b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102f9f:	50                   	push   %eax
f0102fa0:	68 38 54 10 f0       	push   $0xf0105438
f0102fa5:	e8 86 fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102faa:	83 c4 08             	add    $0x8,%esp
f0102fad:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102fb1:	50                   	push   %eax
f0102fb2:	68 4b 54 10 f0       	push   $0xf010544b
f0102fb7:	e8 74 fe ff ff       	call   f0102e30 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102fbc:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102fbf:	83 c4 10             	add    $0x10,%esp
f0102fc2:	83 f8 13             	cmp    $0x13,%eax
f0102fc5:	77 09                	ja     f0102fd0 <print_trapframe+0x56>
		return excnames[trapno];
f0102fc7:	8b 14 85 00 57 10 f0 	mov    -0xfefa900(,%eax,4),%edx
f0102fce:	eb 10                	jmp    f0102fe0 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102fd0:	83 f8 30             	cmp    $0x30,%eax
f0102fd3:	b9 02 54 10 f0       	mov    $0xf0105402,%ecx
f0102fd8:	ba f6 53 10 f0       	mov    $0xf01053f6,%edx
f0102fdd:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102fe0:	83 ec 04             	sub    $0x4,%esp
f0102fe3:	52                   	push   %edx
f0102fe4:	50                   	push   %eax
f0102fe5:	68 5e 54 10 f0       	push   $0xf010545e
f0102fea:	e8 41 fe ff ff       	call   f0102e30 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102fef:	83 c4 10             	add    $0x10,%esp
f0102ff2:	3b 1d a0 c8 17 f0    	cmp    0xf017c8a0,%ebx
f0102ff8:	75 1a                	jne    f0103014 <print_trapframe+0x9a>
f0102ffa:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102ffe:	75 14                	jne    f0103014 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103000:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103003:	83 ec 08             	sub    $0x8,%esp
f0103006:	50                   	push   %eax
f0103007:	68 70 54 10 f0       	push   $0xf0105470
f010300c:	e8 1f fe ff ff       	call   f0102e30 <cprintf>
f0103011:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103014:	83 ec 08             	sub    $0x8,%esp
f0103017:	ff 73 2c             	pushl  0x2c(%ebx)
f010301a:	68 7f 54 10 f0       	push   $0xf010547f
f010301f:	e8 0c fe ff ff       	call   f0102e30 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103024:	83 c4 10             	add    $0x10,%esp
f0103027:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010302b:	75 49                	jne    f0103076 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010302d:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103030:	89 c2                	mov    %eax,%edx
f0103032:	83 e2 01             	and    $0x1,%edx
f0103035:	ba 1c 54 10 f0       	mov    $0xf010541c,%edx
f010303a:	b9 11 54 10 f0       	mov    $0xf0105411,%ecx
f010303f:	0f 44 ca             	cmove  %edx,%ecx
f0103042:	89 c2                	mov    %eax,%edx
f0103044:	83 e2 02             	and    $0x2,%edx
f0103047:	ba 2e 54 10 f0       	mov    $0xf010542e,%edx
f010304c:	be 28 54 10 f0       	mov    $0xf0105428,%esi
f0103051:	0f 45 d6             	cmovne %esi,%edx
f0103054:	83 e0 04             	and    $0x4,%eax
f0103057:	be 5f 55 10 f0       	mov    $0xf010555f,%esi
f010305c:	b8 33 54 10 f0       	mov    $0xf0105433,%eax
f0103061:	0f 44 c6             	cmove  %esi,%eax
f0103064:	51                   	push   %ecx
f0103065:	52                   	push   %edx
f0103066:	50                   	push   %eax
f0103067:	68 8d 54 10 f0       	push   $0xf010548d
f010306c:	e8 bf fd ff ff       	call   f0102e30 <cprintf>
f0103071:	83 c4 10             	add    $0x10,%esp
f0103074:	eb 10                	jmp    f0103086 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103076:	83 ec 0c             	sub    $0xc,%esp
f0103079:	68 df 52 10 f0       	push   $0xf01052df
f010307e:	e8 ad fd ff ff       	call   f0102e30 <cprintf>
f0103083:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103086:	83 ec 08             	sub    $0x8,%esp
f0103089:	ff 73 30             	pushl  0x30(%ebx)
f010308c:	68 9c 54 10 f0       	push   $0xf010549c
f0103091:	e8 9a fd ff ff       	call   f0102e30 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103096:	83 c4 08             	add    $0x8,%esp
f0103099:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010309d:	50                   	push   %eax
f010309e:	68 ab 54 10 f0       	push   $0xf01054ab
f01030a3:	e8 88 fd ff ff       	call   f0102e30 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01030a8:	83 c4 08             	add    $0x8,%esp
f01030ab:	ff 73 38             	pushl  0x38(%ebx)
f01030ae:	68 be 54 10 f0       	push   $0xf01054be
f01030b3:	e8 78 fd ff ff       	call   f0102e30 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01030b8:	83 c4 10             	add    $0x10,%esp
f01030bb:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01030bf:	74 25                	je     f01030e6 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01030c1:	83 ec 08             	sub    $0x8,%esp
f01030c4:	ff 73 3c             	pushl  0x3c(%ebx)
f01030c7:	68 cd 54 10 f0       	push   $0xf01054cd
f01030cc:	e8 5f fd ff ff       	call   f0102e30 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01030d1:	83 c4 08             	add    $0x8,%esp
f01030d4:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01030d8:	50                   	push   %eax
f01030d9:	68 dc 54 10 f0       	push   $0xf01054dc
f01030de:	e8 4d fd ff ff       	call   f0102e30 <cprintf>
f01030e3:	83 c4 10             	add    $0x10,%esp
	}
}
f01030e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01030e9:	5b                   	pop    %ebx
f01030ea:	5e                   	pop    %esi
f01030eb:	5d                   	pop    %ebp
f01030ec:	c3                   	ret    

f01030ed <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01030ed:	55                   	push   %ebp
f01030ee:	89 e5                	mov    %esp,%ebp
f01030f0:	53                   	push   %ebx
f01030f1:	83 ec 04             	sub    $0x4,%esp
f01030f4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01030f7:	0f 20 d0             	mov    %cr2,%eax

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	if((tf->tf_cs & 3)==0)
f01030fa:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01030fe:	75 17                	jne    f0103117 <page_fault_handler+0x2a>
	    panic("page fault kernel mode");
f0103100:	83 ec 04             	sub    $0x4,%esp
f0103103:	68 ef 54 10 f0       	push   $0xf01054ef
f0103108:	68 d5 00 00 00       	push   $0xd5
f010310d:	68 06 55 10 f0       	push   $0xf0105506
f0103112:	e8 89 cf ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103117:	ff 73 30             	pushl  0x30(%ebx)
f010311a:	50                   	push   %eax
f010311b:	a1 80 c0 17 f0       	mov    0xf017c080,%eax
f0103120:	ff 70 48             	pushl  0x48(%eax)
f0103123:	68 ac 56 10 f0       	push   $0xf01056ac
f0103128:	e8 03 fd ff ff       	call   f0102e30 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010312d:	89 1c 24             	mov    %ebx,(%esp)
f0103130:	e8 45 fe ff ff       	call   f0102f7a <print_trapframe>
	env_destroy(curenv);
f0103135:	83 c4 04             	add    $0x4,%esp
f0103138:	ff 35 80 c0 17 f0    	pushl  0xf017c080
f010313e:	e8 bc fb ff ff       	call   f0102cff <env_destroy>
}
f0103143:	83 c4 10             	add    $0x10,%esp
f0103146:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103149:	c9                   	leave  
f010314a:	c3                   	ret    

f010314b <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010314b:	55                   	push   %ebp
f010314c:	89 e5                	mov    %esp,%ebp
f010314e:	57                   	push   %edi
f010314f:	56                   	push   %esi
f0103150:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103153:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103154:	9c                   	pushf  
f0103155:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103156:	f6 c4 02             	test   $0x2,%ah
f0103159:	74 19                	je     f0103174 <trap+0x29>
f010315b:	68 12 55 10 f0       	push   $0xf0105512
f0103160:	68 f2 47 10 f0       	push   $0xf01047f2
f0103165:	68 ae 00 00 00       	push   $0xae
f010316a:	68 06 55 10 f0       	push   $0xf0105506
f010316f:	e8 2c cf ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103174:	83 ec 08             	sub    $0x8,%esp
f0103177:	56                   	push   %esi
f0103178:	68 2b 55 10 f0       	push   $0xf010552b
f010317d:	e8 ae fc ff ff       	call   f0102e30 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103182:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103186:	83 e0 03             	and    $0x3,%eax
f0103189:	83 c4 10             	add    $0x10,%esp
f010318c:	66 83 f8 03          	cmp    $0x3,%ax
f0103190:	75 31                	jne    f01031c3 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103192:	a1 80 c0 17 f0       	mov    0xf017c080,%eax
f0103197:	85 c0                	test   %eax,%eax
f0103199:	75 19                	jne    f01031b4 <trap+0x69>
f010319b:	68 46 55 10 f0       	push   $0xf0105546
f01031a0:	68 f2 47 10 f0       	push   $0xf01047f2
f01031a5:	68 b4 00 00 00       	push   $0xb4
f01031aa:	68 06 55 10 f0       	push   $0xf0105506
f01031af:	e8 ec ce ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01031b4:	b9 11 00 00 00       	mov    $0x11,%ecx
f01031b9:	89 c7                	mov    %eax,%edi
f01031bb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01031bd:	8b 35 80 c0 17 f0    	mov    0xf017c080,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01031c3:	89 35 a0 c8 17 f0    	mov    %esi,0xf017c8a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==14)
f01031c9:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01031cd:	75 0c                	jne    f01031db <trap+0x90>
        page_fault_handler(tf);
f01031cf:	83 ec 0c             	sub    $0xc,%esp
f01031d2:	56                   	push   %esi
f01031d3:	e8 15 ff ff ff       	call   f01030ed <page_fault_handler>
f01031d8:	83 c4 10             	add    $0x10,%esp
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01031db:	83 ec 0c             	sub    $0xc,%esp
f01031de:	56                   	push   %esi
f01031df:	e8 96 fd ff ff       	call   f0102f7a <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01031e4:	83 c4 10             	add    $0x10,%esp
f01031e7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01031ec:	75 17                	jne    f0103205 <trap+0xba>
		panic("unhandled trap in kernel");
f01031ee:	83 ec 04             	sub    $0x4,%esp
f01031f1:	68 4d 55 10 f0       	push   $0xf010554d
f01031f6:	68 9d 00 00 00       	push   $0x9d
f01031fb:	68 06 55 10 f0       	push   $0xf0105506
f0103200:	e8 9b ce ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103205:	83 ec 0c             	sub    $0xc,%esp
f0103208:	ff 35 80 c0 17 f0    	pushl  0xf017c080
f010320e:	e8 ec fa ff ff       	call   f0102cff <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103213:	a1 80 c0 17 f0       	mov    0xf017c080,%eax
f0103218:	83 c4 10             	add    $0x10,%esp
f010321b:	85 c0                	test   %eax,%eax
f010321d:	74 06                	je     f0103225 <trap+0xda>
f010321f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103223:	74 19                	je     f010323e <trap+0xf3>
f0103225:	68 d0 56 10 f0       	push   $0xf01056d0
f010322a:	68 f2 47 10 f0       	push   $0xf01047f2
f010322f:	68 c6 00 00 00       	push   $0xc6
f0103234:	68 06 55 10 f0       	push   $0xf0105506
f0103239:	e8 62 ce ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010323e:	83 ec 0c             	sub    $0xc,%esp
f0103241:	50                   	push   %eax
f0103242:	e8 08 fb ff ff       	call   f0102d4f <env_run>
f0103247:	90                   	nop

f0103248 <thdlr0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(thdlr0, 0)
f0103248:	6a 00                	push   $0x0
f010324a:	6a 00                	push   $0x0
f010324c:	e9 28 01 00 00       	jmp    f0103379 <_alltraps>
f0103251:	90                   	nop

f0103252 <thdlr1>:
TRAPHANDLER_NOEC(thdlr1, 1)
f0103252:	6a 00                	push   $0x0
f0103254:	6a 01                	push   $0x1
f0103256:	e9 1e 01 00 00       	jmp    f0103379 <_alltraps>
f010325b:	90                   	nop

f010325c <thdlr2>:
TRAPHANDLER_NOEC(thdlr2, 2)
f010325c:	6a 00                	push   $0x0
f010325e:	6a 02                	push   $0x2
f0103260:	e9 14 01 00 00       	jmp    f0103379 <_alltraps>
f0103265:	90                   	nop

f0103266 <thdlr3>:
TRAPHANDLER_NOEC(thdlr3, 3)
f0103266:	6a 00                	push   $0x0
f0103268:	6a 03                	push   $0x3
f010326a:	e9 0a 01 00 00       	jmp    f0103379 <_alltraps>
f010326f:	90                   	nop

f0103270 <thdlr4>:
TRAPHANDLER_NOEC(thdlr4, 4)
f0103270:	6a 00                	push   $0x0
f0103272:	6a 04                	push   $0x4
f0103274:	e9 00 01 00 00       	jmp    f0103379 <_alltraps>
f0103279:	90                   	nop

f010327a <thdlr5>:
TRAPHANDLER_NOEC(thdlr5, 5)
f010327a:	6a 00                	push   $0x0
f010327c:	6a 05                	push   $0x5
f010327e:	e9 f6 00 00 00       	jmp    f0103379 <_alltraps>
f0103283:	90                   	nop

f0103284 <thdlr6>:
TRAPHANDLER_NOEC(thdlr6, 6)
f0103284:	6a 00                	push   $0x0
f0103286:	6a 06                	push   $0x6
f0103288:	e9 ec 00 00 00       	jmp    f0103379 <_alltraps>
f010328d:	90                   	nop

f010328e <thdlr7>:
TRAPHANDLER_NOEC(thdlr7, 7)
f010328e:	6a 00                	push   $0x0
f0103290:	6a 07                	push   $0x7
f0103292:	e9 e2 00 00 00       	jmp    f0103379 <_alltraps>
f0103297:	90                   	nop

f0103298 <thdlr8>:
TRAPHANDLER(thdlr8, 8)
f0103298:	6a 08                	push   $0x8
f010329a:	e9 da 00 00 00       	jmp    f0103379 <_alltraps>
f010329f:	90                   	nop

f01032a0 <thdlr9>:
TRAPHANDLER_NOEC(thdlr9, 9)
f01032a0:	6a 00                	push   $0x0
f01032a2:	6a 09                	push   $0x9
f01032a4:	e9 d0 00 00 00       	jmp    f0103379 <_alltraps>
f01032a9:	90                   	nop

f01032aa <thdlr10>:
TRAPHANDLER(thdlr10, 10)
f01032aa:	6a 0a                	push   $0xa
f01032ac:	e9 c8 00 00 00       	jmp    f0103379 <_alltraps>
f01032b1:	90                   	nop

f01032b2 <thdlr11>:
TRAPHANDLER(thdlr11, 11)
f01032b2:	6a 0b                	push   $0xb
f01032b4:	e9 c0 00 00 00       	jmp    f0103379 <_alltraps>
f01032b9:	90                   	nop

f01032ba <thdlr12>:
TRAPHANDLER(thdlr12, 12)
f01032ba:	6a 0c                	push   $0xc
f01032bc:	e9 b8 00 00 00       	jmp    f0103379 <_alltraps>
f01032c1:	90                   	nop

f01032c2 <thdlr13>:
TRAPHANDLER(thdlr13, 13)
f01032c2:	6a 0d                	push   $0xd
f01032c4:	e9 b0 00 00 00       	jmp    f0103379 <_alltraps>
f01032c9:	90                   	nop

f01032ca <thdlr14>:
TRAPHANDLER(thdlr14, 14)
f01032ca:	6a 0e                	push   $0xe
f01032cc:	e9 a8 00 00 00       	jmp    f0103379 <_alltraps>
f01032d1:	90                   	nop

f01032d2 <thdlr15>:
TRAPHANDLER_NOEC(thdlr15, 15)
f01032d2:	6a 00                	push   $0x0
f01032d4:	6a 0f                	push   $0xf
f01032d6:	e9 9e 00 00 00       	jmp    f0103379 <_alltraps>
f01032db:	90                   	nop

f01032dc <thdlr16>:
TRAPHANDLER_NOEC(thdlr16, 16)
f01032dc:	6a 00                	push   $0x0
f01032de:	6a 10                	push   $0x10
f01032e0:	e9 94 00 00 00       	jmp    f0103379 <_alltraps>
f01032e5:	90                   	nop

f01032e6 <thdlr17>:
TRAPHANDLER(thdlr17, 17)
f01032e6:	6a 11                	push   $0x11
f01032e8:	e9 8c 00 00 00       	jmp    f0103379 <_alltraps>
f01032ed:	90                   	nop

f01032ee <thdlr18>:
TRAPHANDLER_NOEC(thdlr18, 18)
f01032ee:	6a 00                	push   $0x0
f01032f0:	6a 12                	push   $0x12
f01032f2:	e9 82 00 00 00       	jmp    f0103379 <_alltraps>
f01032f7:	90                   	nop

f01032f8 <thdlr19>:
TRAPHANDLER_NOEC(thdlr19, 19)
f01032f8:	6a 00                	push   $0x0
f01032fa:	6a 13                	push   $0x13
f01032fc:	e9 78 00 00 00       	jmp    f0103379 <_alltraps>
f0103301:	90                   	nop

f0103302 <thdlr20>:
TRAPHANDLER_NOEC(thdlr20, 20)
f0103302:	6a 00                	push   $0x0
f0103304:	6a 14                	push   $0x14
f0103306:	e9 6e 00 00 00       	jmp    f0103379 <_alltraps>
f010330b:	90                   	nop

f010330c <thdlr21>:
TRAPHANDLER_NOEC(thdlr21, 21)
f010330c:	6a 00                	push   $0x0
f010330e:	6a 15                	push   $0x15
f0103310:	e9 64 00 00 00       	jmp    f0103379 <_alltraps>
f0103315:	90                   	nop

f0103316 <thdlr22>:
TRAPHANDLER_NOEC(thdlr22, 22)
f0103316:	6a 00                	push   $0x0
f0103318:	6a 16                	push   $0x16
f010331a:	e9 5a 00 00 00       	jmp    f0103379 <_alltraps>
f010331f:	90                   	nop

f0103320 <thdlr23>:
TRAPHANDLER_NOEC(thdlr23, 23)
f0103320:	6a 00                	push   $0x0
f0103322:	6a 17                	push   $0x17
f0103324:	e9 50 00 00 00       	jmp    f0103379 <_alltraps>
f0103329:	90                   	nop

f010332a <thdlr24>:
TRAPHANDLER_NOEC(thdlr24, 24)
f010332a:	6a 00                	push   $0x0
f010332c:	6a 18                	push   $0x18
f010332e:	e9 46 00 00 00       	jmp    f0103379 <_alltraps>
f0103333:	90                   	nop

f0103334 <thdlr25>:
TRAPHANDLER_NOEC(thdlr25, 25)
f0103334:	6a 00                	push   $0x0
f0103336:	6a 19                	push   $0x19
f0103338:	e9 3c 00 00 00       	jmp    f0103379 <_alltraps>
f010333d:	90                   	nop

f010333e <thdlr26>:
TRAPHANDLER_NOEC(thdlr26, 26)
f010333e:	6a 00                	push   $0x0
f0103340:	6a 1a                	push   $0x1a
f0103342:	e9 32 00 00 00       	jmp    f0103379 <_alltraps>
f0103347:	90                   	nop

f0103348 <thdlr27>:
TRAPHANDLER_NOEC(thdlr27, 27)
f0103348:	6a 00                	push   $0x0
f010334a:	6a 1b                	push   $0x1b
f010334c:	e9 28 00 00 00       	jmp    f0103379 <_alltraps>
f0103351:	90                   	nop

f0103352 <thdlr28>:
TRAPHANDLER_NOEC(thdlr28, 28)
f0103352:	6a 00                	push   $0x0
f0103354:	6a 1c                	push   $0x1c
f0103356:	e9 1e 00 00 00       	jmp    f0103379 <_alltraps>
f010335b:	90                   	nop

f010335c <thdlr29>:
TRAPHANDLER_NOEC(thdlr29, 29)
f010335c:	6a 00                	push   $0x0
f010335e:	6a 1d                	push   $0x1d
f0103360:	e9 14 00 00 00       	jmp    f0103379 <_alltraps>
f0103365:	90                   	nop

f0103366 <thdlr30>:
TRAPHANDLER_NOEC(thdlr30, 30)
f0103366:	6a 00                	push   $0x0
f0103368:	6a 1e                	push   $0x1e
f010336a:	e9 0a 00 00 00       	jmp    f0103379 <_alltraps>
f010336f:	90                   	nop

f0103370 <thdlr31>:
TRAPHANDLER_NOEC(thdlr31, 31)
f0103370:	6a 00                	push   $0x0
f0103372:	6a 1f                	push   $0x1f
f0103374:	e9 00 00 00 00       	jmp    f0103379 <_alltraps>

f0103379 <_alltraps>:


.globl _alltraps
_alltraps:
	pushl %ds
f0103379:	1e                   	push   %ds
    pushl %es
f010337a:	06                   	push   %es
	pushal
f010337b:	60                   	pusha  

	movw $GD_KD, %ax
f010337c:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103380:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0103382:	8e c0                	mov    %eax,%es

    pushl %esp  /* trap(%esp) */
f0103384:	54                   	push   %esp
    call trap
f0103385:	e8 c1 fd ff ff       	call   f010314b <trap>

f010338a <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010338a:	55                   	push   %ebp
f010338b:	89 e5                	mov    %esp,%ebp
f010338d:	83 ec 0c             	sub    $0xc,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f0103390:	68 50 57 10 f0       	push   $0xf0105750
f0103395:	6a 49                	push   $0x49
f0103397:	68 68 57 10 f0       	push   $0xf0105768
f010339c:	e8 ff cc ff ff       	call   f01000a0 <_panic>

f01033a1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01033a1:	55                   	push   %ebp
f01033a2:	89 e5                	mov    %esp,%ebp
f01033a4:	57                   	push   %edi
f01033a5:	56                   	push   %esi
f01033a6:	53                   	push   %ebx
f01033a7:	83 ec 14             	sub    $0x14,%esp
f01033aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01033ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01033b0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01033b3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01033b6:	8b 1a                	mov    (%edx),%ebx
f01033b8:	8b 01                	mov    (%ecx),%eax
f01033ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01033bd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01033c4:	eb 7f                	jmp    f0103445 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01033c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01033c9:	01 d8                	add    %ebx,%eax
f01033cb:	89 c6                	mov    %eax,%esi
f01033cd:	c1 ee 1f             	shr    $0x1f,%esi
f01033d0:	01 c6                	add    %eax,%esi
f01033d2:	d1 fe                	sar    %esi
f01033d4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01033d7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01033da:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01033dd:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01033df:	eb 03                	jmp    f01033e4 <stab_binsearch+0x43>
			m--;
f01033e1:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01033e4:	39 c3                	cmp    %eax,%ebx
f01033e6:	7f 0d                	jg     f01033f5 <stab_binsearch+0x54>
f01033e8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01033ec:	83 ea 0c             	sub    $0xc,%edx
f01033ef:	39 f9                	cmp    %edi,%ecx
f01033f1:	75 ee                	jne    f01033e1 <stab_binsearch+0x40>
f01033f3:	eb 05                	jmp    f01033fa <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01033f5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01033f8:	eb 4b                	jmp    f0103445 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01033fa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01033fd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103400:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103404:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103407:	76 11                	jbe    f010341a <stab_binsearch+0x79>
			*region_left = m;
f0103409:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010340c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010340e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103411:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103418:	eb 2b                	jmp    f0103445 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010341a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010341d:	73 14                	jae    f0103433 <stab_binsearch+0x92>
			*region_right = m - 1;
f010341f:	83 e8 01             	sub    $0x1,%eax
f0103422:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103425:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103428:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010342a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103431:	eb 12                	jmp    f0103445 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103433:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103436:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103438:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010343c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010343e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103445:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103448:	0f 8e 78 ff ff ff    	jle    f01033c6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010344e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103452:	75 0f                	jne    f0103463 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103454:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103457:	8b 00                	mov    (%eax),%eax
f0103459:	83 e8 01             	sub    $0x1,%eax
f010345c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010345f:	89 06                	mov    %eax,(%esi)
f0103461:	eb 2c                	jmp    f010348f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103463:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103466:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103468:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010346b:	8b 0e                	mov    (%esi),%ecx
f010346d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103470:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103473:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103476:	eb 03                	jmp    f010347b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103478:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010347b:	39 c8                	cmp    %ecx,%eax
f010347d:	7e 0b                	jle    f010348a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010347f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103483:	83 ea 0c             	sub    $0xc,%edx
f0103486:	39 df                	cmp    %ebx,%edi
f0103488:	75 ee                	jne    f0103478 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010348a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010348d:	89 06                	mov    %eax,(%esi)
	}
}
f010348f:	83 c4 14             	add    $0x14,%esp
f0103492:	5b                   	pop    %ebx
f0103493:	5e                   	pop    %esi
f0103494:	5f                   	pop    %edi
f0103495:	5d                   	pop    %ebp
f0103496:	c3                   	ret    

f0103497 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103497:	55                   	push   %ebp
f0103498:	89 e5                	mov    %esp,%ebp
f010349a:	57                   	push   %edi
f010349b:	56                   	push   %esi
f010349c:	53                   	push   %ebx
f010349d:	83 ec 2c             	sub    $0x2c,%esp
f01034a0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034a3:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01034a6:	c7 06 77 57 10 f0    	movl   $0xf0105777,(%esi)
	info->eip_line = 0;
f01034ac:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01034b3:	c7 46 08 77 57 10 f0 	movl   $0xf0105777,0x8(%esi)
	info->eip_fn_namelen = 9;
f01034ba:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01034c1:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01034c4:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01034cb:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01034d1:	77 21                	ja     f01034f4 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01034d3:	a1 00 00 20 00       	mov    0x200000,%eax
f01034d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01034db:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01034e0:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01034e6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01034e9:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f01034ef:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01034f2:	eb 1a                	jmp    f010350e <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01034f4:	c7 45 d0 2d f8 10 f0 	movl   $0xf010f82d,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01034fb:	c7 45 cc 79 ce 10 f0 	movl   $0xf010ce79,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103502:	b8 78 ce 10 f0       	mov    $0xf010ce78,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103507:	c7 45 d4 90 59 10 f0 	movl   $0xf0105990,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010350e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103511:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0103514:	0f 83 2b 01 00 00    	jae    f0103645 <debuginfo_eip+0x1ae>
f010351a:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f010351e:	0f 85 28 01 00 00    	jne    f010364c <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103524:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010352b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010352e:	29 d8                	sub    %ebx,%eax
f0103530:	c1 f8 02             	sar    $0x2,%eax
f0103533:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103539:	83 e8 01             	sub    $0x1,%eax
f010353c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010353f:	57                   	push   %edi
f0103540:	6a 64                	push   $0x64
f0103542:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103545:	89 c1                	mov    %eax,%ecx
f0103547:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010354a:	89 d8                	mov    %ebx,%eax
f010354c:	e8 50 fe ff ff       	call   f01033a1 <stab_binsearch>
	if (lfile == 0)
f0103551:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103554:	83 c4 08             	add    $0x8,%esp
f0103557:	85 c0                	test   %eax,%eax
f0103559:	0f 84 f4 00 00 00    	je     f0103653 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010355f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103562:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103565:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103568:	57                   	push   %edi
f0103569:	6a 24                	push   $0x24
f010356b:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010356e:	89 c1                	mov    %eax,%ecx
f0103570:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103573:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103576:	89 d8                	mov    %ebx,%eax
f0103578:	e8 24 fe ff ff       	call   f01033a1 <stab_binsearch>

	if (lfun <= rfun) {
f010357d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103580:	83 c4 08             	add    $0x8,%esp
f0103583:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103586:	7f 24                	jg     f01035ac <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103588:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010358b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010358e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103591:	8b 02                	mov    (%edx),%eax
f0103593:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103596:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103599:	29 f9                	sub    %edi,%ecx
f010359b:	39 c8                	cmp    %ecx,%eax
f010359d:	73 05                	jae    f01035a4 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010359f:	01 f8                	add    %edi,%eax
f01035a1:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01035a4:	8b 42 08             	mov    0x8(%edx),%eax
f01035a7:	89 46 10             	mov    %eax,0x10(%esi)
f01035aa:	eb 06                	jmp    f01035b2 <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01035ac:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01035af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01035b2:	83 ec 08             	sub    $0x8,%esp
f01035b5:	6a 3a                	push   $0x3a
f01035b7:	ff 76 08             	pushl  0x8(%esi)
f01035ba:	e8 9a 08 00 00       	call   f0103e59 <strfind>
f01035bf:	2b 46 08             	sub    0x8(%esi),%eax
f01035c2:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01035c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035c8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01035cb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01035ce:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01035d1:	83 c4 10             	add    $0x10,%esp
f01035d4:	eb 06                	jmp    f01035dc <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01035d6:	83 eb 01             	sub    $0x1,%ebx
f01035d9:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01035dc:	39 fb                	cmp    %edi,%ebx
f01035de:	7c 2d                	jl     f010360d <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01035e0:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01035e4:	80 fa 84             	cmp    $0x84,%dl
f01035e7:	74 0b                	je     f01035f4 <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01035e9:	80 fa 64             	cmp    $0x64,%dl
f01035ec:	75 e8                	jne    f01035d6 <debuginfo_eip+0x13f>
f01035ee:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01035f2:	74 e2                	je     f01035d6 <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01035f4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01035f7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01035fa:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01035fd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103600:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103603:	29 f8                	sub    %edi,%eax
f0103605:	39 c2                	cmp    %eax,%edx
f0103607:	73 04                	jae    f010360d <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103609:	01 fa                	add    %edi,%edx
f010360b:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010360d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103610:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103613:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103618:	39 cb                	cmp    %ecx,%ebx
f010361a:	7d 43                	jge    f010365f <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f010361c:	8d 53 01             	lea    0x1(%ebx),%edx
f010361f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103622:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103625:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103628:	eb 07                	jmp    f0103631 <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010362a:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010362e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103631:	39 ca                	cmp    %ecx,%edx
f0103633:	74 25                	je     f010365a <debuginfo_eip+0x1c3>
f0103635:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103638:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f010363c:	74 ec                	je     f010362a <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010363e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103643:	eb 1a                	jmp    f010365f <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103645:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010364a:	eb 13                	jmp    f010365f <debuginfo_eip+0x1c8>
f010364c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103651:	eb 0c                	jmp    f010365f <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103658:	eb 05                	jmp    f010365f <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010365a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010365f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103662:	5b                   	pop    %ebx
f0103663:	5e                   	pop    %esi
f0103664:	5f                   	pop    %edi
f0103665:	5d                   	pop    %ebp
f0103666:	c3                   	ret    

f0103667 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103667:	55                   	push   %ebp
f0103668:	89 e5                	mov    %esp,%ebp
f010366a:	57                   	push   %edi
f010366b:	56                   	push   %esi
f010366c:	53                   	push   %ebx
f010366d:	83 ec 1c             	sub    $0x1c,%esp
f0103670:	89 c7                	mov    %eax,%edi
f0103672:	89 d6                	mov    %edx,%esi
f0103674:	8b 45 08             	mov    0x8(%ebp),%eax
f0103677:	8b 55 0c             	mov    0xc(%ebp),%edx
f010367a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010367d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103680:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103683:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103688:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010368b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010368e:	39 d3                	cmp    %edx,%ebx
f0103690:	72 05                	jb     f0103697 <printnum+0x30>
f0103692:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103695:	77 45                	ja     f01036dc <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103697:	83 ec 0c             	sub    $0xc,%esp
f010369a:	ff 75 18             	pushl  0x18(%ebp)
f010369d:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a0:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01036a3:	53                   	push   %ebx
f01036a4:	ff 75 10             	pushl  0x10(%ebp)
f01036a7:	83 ec 08             	sub    $0x8,%esp
f01036aa:	ff 75 e4             	pushl  -0x1c(%ebp)
f01036ad:	ff 75 e0             	pushl  -0x20(%ebp)
f01036b0:	ff 75 dc             	pushl  -0x24(%ebp)
f01036b3:	ff 75 d8             	pushl  -0x28(%ebp)
f01036b6:	e8 c5 09 00 00       	call   f0104080 <__udivdi3>
f01036bb:	83 c4 18             	add    $0x18,%esp
f01036be:	52                   	push   %edx
f01036bf:	50                   	push   %eax
f01036c0:	89 f2                	mov    %esi,%edx
f01036c2:	89 f8                	mov    %edi,%eax
f01036c4:	e8 9e ff ff ff       	call   f0103667 <printnum>
f01036c9:	83 c4 20             	add    $0x20,%esp
f01036cc:	eb 18                	jmp    f01036e6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01036ce:	83 ec 08             	sub    $0x8,%esp
f01036d1:	56                   	push   %esi
f01036d2:	ff 75 18             	pushl  0x18(%ebp)
f01036d5:	ff d7                	call   *%edi
f01036d7:	83 c4 10             	add    $0x10,%esp
f01036da:	eb 03                	jmp    f01036df <printnum+0x78>
f01036dc:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01036df:	83 eb 01             	sub    $0x1,%ebx
f01036e2:	85 db                	test   %ebx,%ebx
f01036e4:	7f e8                	jg     f01036ce <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01036e6:	83 ec 08             	sub    $0x8,%esp
f01036e9:	56                   	push   %esi
f01036ea:	83 ec 04             	sub    $0x4,%esp
f01036ed:	ff 75 e4             	pushl  -0x1c(%ebp)
f01036f0:	ff 75 e0             	pushl  -0x20(%ebp)
f01036f3:	ff 75 dc             	pushl  -0x24(%ebp)
f01036f6:	ff 75 d8             	pushl  -0x28(%ebp)
f01036f9:	e8 b2 0a 00 00       	call   f01041b0 <__umoddi3>
f01036fe:	83 c4 14             	add    $0x14,%esp
f0103701:	0f be 80 81 57 10 f0 	movsbl -0xfefa87f(%eax),%eax
f0103708:	50                   	push   %eax
f0103709:	ff d7                	call   *%edi
}
f010370b:	83 c4 10             	add    $0x10,%esp
f010370e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103711:	5b                   	pop    %ebx
f0103712:	5e                   	pop    %esi
f0103713:	5f                   	pop    %edi
f0103714:	5d                   	pop    %ebp
f0103715:	c3                   	ret    

f0103716 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103716:	55                   	push   %ebp
f0103717:	89 e5                	mov    %esp,%ebp
f0103719:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010371c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103720:	8b 10                	mov    (%eax),%edx
f0103722:	3b 50 04             	cmp    0x4(%eax),%edx
f0103725:	73 0a                	jae    f0103731 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103727:	8d 4a 01             	lea    0x1(%edx),%ecx
f010372a:	89 08                	mov    %ecx,(%eax)
f010372c:	8b 45 08             	mov    0x8(%ebp),%eax
f010372f:	88 02                	mov    %al,(%edx)
}
f0103731:	5d                   	pop    %ebp
f0103732:	c3                   	ret    

f0103733 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103733:	55                   	push   %ebp
f0103734:	89 e5                	mov    %esp,%ebp
f0103736:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103739:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010373c:	50                   	push   %eax
f010373d:	ff 75 10             	pushl  0x10(%ebp)
f0103740:	ff 75 0c             	pushl  0xc(%ebp)
f0103743:	ff 75 08             	pushl  0x8(%ebp)
f0103746:	e8 05 00 00 00       	call   f0103750 <vprintfmt>
	va_end(ap);
}
f010374b:	83 c4 10             	add    $0x10,%esp
f010374e:	c9                   	leave  
f010374f:	c3                   	ret    

f0103750 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103750:	55                   	push   %ebp
f0103751:	89 e5                	mov    %esp,%ebp
f0103753:	57                   	push   %edi
f0103754:	56                   	push   %esi
f0103755:	53                   	push   %ebx
f0103756:	83 ec 2c             	sub    $0x2c,%esp
f0103759:	8b 75 08             	mov    0x8(%ebp),%esi
f010375c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010375f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103762:	eb 12                	jmp    f0103776 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103764:	85 c0                	test   %eax,%eax
f0103766:	0f 84 42 04 00 00    	je     f0103bae <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f010376c:	83 ec 08             	sub    $0x8,%esp
f010376f:	53                   	push   %ebx
f0103770:	50                   	push   %eax
f0103771:	ff d6                	call   *%esi
f0103773:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103776:	83 c7 01             	add    $0x1,%edi
f0103779:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010377d:	83 f8 25             	cmp    $0x25,%eax
f0103780:	75 e2                	jne    f0103764 <vprintfmt+0x14>
f0103782:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103786:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010378d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103794:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010379b:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037a0:	eb 07                	jmp    f01037a9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01037a5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037a9:	8d 47 01             	lea    0x1(%edi),%eax
f01037ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037af:	0f b6 07             	movzbl (%edi),%eax
f01037b2:	0f b6 d0             	movzbl %al,%edx
f01037b5:	83 e8 23             	sub    $0x23,%eax
f01037b8:	3c 55                	cmp    $0x55,%al
f01037ba:	0f 87 d3 03 00 00    	ja     f0103b93 <vprintfmt+0x443>
f01037c0:	0f b6 c0             	movzbl %al,%eax
f01037c3:	ff 24 85 0c 58 10 f0 	jmp    *-0xfefa7f4(,%eax,4)
f01037ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01037cd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01037d1:	eb d6                	jmp    f01037a9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037db:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01037de:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01037e1:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01037e5:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01037e8:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01037eb:	83 f9 09             	cmp    $0x9,%ecx
f01037ee:	77 3f                	ja     f010382f <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01037f0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01037f3:	eb e9                	jmp    f01037de <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01037f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01037f8:	8b 00                	mov    (%eax),%eax
f01037fa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01037fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103800:	8d 40 04             	lea    0x4(%eax),%eax
f0103803:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103806:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103809:	eb 2a                	jmp    f0103835 <vprintfmt+0xe5>
f010380b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010380e:	85 c0                	test   %eax,%eax
f0103810:	ba 00 00 00 00       	mov    $0x0,%edx
f0103815:	0f 49 d0             	cmovns %eax,%edx
f0103818:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010381b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010381e:	eb 89                	jmp    f01037a9 <vprintfmt+0x59>
f0103820:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103823:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010382a:	e9 7a ff ff ff       	jmp    f01037a9 <vprintfmt+0x59>
f010382f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103832:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103835:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103839:	0f 89 6a ff ff ff    	jns    f01037a9 <vprintfmt+0x59>
				width = precision, precision = -1;
f010383f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103842:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103845:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010384c:	e9 58 ff ff ff       	jmp    f01037a9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103851:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103854:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103857:	e9 4d ff ff ff       	jmp    f01037a9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010385c:	8b 45 14             	mov    0x14(%ebp),%eax
f010385f:	8d 78 04             	lea    0x4(%eax),%edi
f0103862:	83 ec 08             	sub    $0x8,%esp
f0103865:	53                   	push   %ebx
f0103866:	ff 30                	pushl  (%eax)
f0103868:	ff d6                	call   *%esi
			break;
f010386a:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010386d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103870:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103873:	e9 fe fe ff ff       	jmp    f0103776 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103878:	8b 45 14             	mov    0x14(%ebp),%eax
f010387b:	8d 78 04             	lea    0x4(%eax),%edi
f010387e:	8b 00                	mov    (%eax),%eax
f0103880:	99                   	cltd   
f0103881:	31 d0                	xor    %edx,%eax
f0103883:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103885:	83 f8 06             	cmp    $0x6,%eax
f0103888:	7f 0b                	jg     f0103895 <vprintfmt+0x145>
f010388a:	8b 14 85 64 59 10 f0 	mov    -0xfefa69c(,%eax,4),%edx
f0103891:	85 d2                	test   %edx,%edx
f0103893:	75 1b                	jne    f01038b0 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103895:	50                   	push   %eax
f0103896:	68 99 57 10 f0       	push   $0xf0105799
f010389b:	53                   	push   %ebx
f010389c:	56                   	push   %esi
f010389d:	e8 91 fe ff ff       	call   f0103733 <printfmt>
f01038a2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01038a5:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01038ab:	e9 c6 fe ff ff       	jmp    f0103776 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01038b0:	52                   	push   %edx
f01038b1:	68 04 48 10 f0       	push   $0xf0104804
f01038b6:	53                   	push   %ebx
f01038b7:	56                   	push   %esi
f01038b8:	e8 76 fe ff ff       	call   f0103733 <printfmt>
f01038bd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01038c0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01038c6:	e9 ab fe ff ff       	jmp    f0103776 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01038cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ce:	83 c0 04             	add    $0x4,%eax
f01038d1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01038d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01038d7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01038d9:	85 ff                	test   %edi,%edi
f01038db:	b8 92 57 10 f0       	mov    $0xf0105792,%eax
f01038e0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01038e3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01038e7:	0f 8e 94 00 00 00    	jle    f0103981 <vprintfmt+0x231>
f01038ed:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01038f1:	0f 84 98 00 00 00    	je     f010398f <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01038f7:	83 ec 08             	sub    $0x8,%esp
f01038fa:	ff 75 d0             	pushl  -0x30(%ebp)
f01038fd:	57                   	push   %edi
f01038fe:	e8 0c 04 00 00       	call   f0103d0f <strnlen>
f0103903:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103906:	29 c1                	sub    %eax,%ecx
f0103908:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f010390b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010390e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103912:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103915:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103918:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010391a:	eb 0f                	jmp    f010392b <vprintfmt+0x1db>
					putch(padc, putdat);
f010391c:	83 ec 08             	sub    $0x8,%esp
f010391f:	53                   	push   %ebx
f0103920:	ff 75 e0             	pushl  -0x20(%ebp)
f0103923:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103925:	83 ef 01             	sub    $0x1,%edi
f0103928:	83 c4 10             	add    $0x10,%esp
f010392b:	85 ff                	test   %edi,%edi
f010392d:	7f ed                	jg     f010391c <vprintfmt+0x1cc>
f010392f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103932:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103935:	85 c9                	test   %ecx,%ecx
f0103937:	b8 00 00 00 00       	mov    $0x0,%eax
f010393c:	0f 49 c1             	cmovns %ecx,%eax
f010393f:	29 c1                	sub    %eax,%ecx
f0103941:	89 75 08             	mov    %esi,0x8(%ebp)
f0103944:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103947:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010394a:	89 cb                	mov    %ecx,%ebx
f010394c:	eb 4d                	jmp    f010399b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010394e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103952:	74 1b                	je     f010396f <vprintfmt+0x21f>
f0103954:	0f be c0             	movsbl %al,%eax
f0103957:	83 e8 20             	sub    $0x20,%eax
f010395a:	83 f8 5e             	cmp    $0x5e,%eax
f010395d:	76 10                	jbe    f010396f <vprintfmt+0x21f>
					putch('?', putdat);
f010395f:	83 ec 08             	sub    $0x8,%esp
f0103962:	ff 75 0c             	pushl  0xc(%ebp)
f0103965:	6a 3f                	push   $0x3f
f0103967:	ff 55 08             	call   *0x8(%ebp)
f010396a:	83 c4 10             	add    $0x10,%esp
f010396d:	eb 0d                	jmp    f010397c <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f010396f:	83 ec 08             	sub    $0x8,%esp
f0103972:	ff 75 0c             	pushl  0xc(%ebp)
f0103975:	52                   	push   %edx
f0103976:	ff 55 08             	call   *0x8(%ebp)
f0103979:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010397c:	83 eb 01             	sub    $0x1,%ebx
f010397f:	eb 1a                	jmp    f010399b <vprintfmt+0x24b>
f0103981:	89 75 08             	mov    %esi,0x8(%ebp)
f0103984:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103987:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010398a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010398d:	eb 0c                	jmp    f010399b <vprintfmt+0x24b>
f010398f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103992:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103995:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103998:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010399b:	83 c7 01             	add    $0x1,%edi
f010399e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01039a2:	0f be d0             	movsbl %al,%edx
f01039a5:	85 d2                	test   %edx,%edx
f01039a7:	74 23                	je     f01039cc <vprintfmt+0x27c>
f01039a9:	85 f6                	test   %esi,%esi
f01039ab:	78 a1                	js     f010394e <vprintfmt+0x1fe>
f01039ad:	83 ee 01             	sub    $0x1,%esi
f01039b0:	79 9c                	jns    f010394e <vprintfmt+0x1fe>
f01039b2:	89 df                	mov    %ebx,%edi
f01039b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01039b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039ba:	eb 18                	jmp    f01039d4 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01039bc:	83 ec 08             	sub    $0x8,%esp
f01039bf:	53                   	push   %ebx
f01039c0:	6a 20                	push   $0x20
f01039c2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01039c4:	83 ef 01             	sub    $0x1,%edi
f01039c7:	83 c4 10             	add    $0x10,%esp
f01039ca:	eb 08                	jmp    f01039d4 <vprintfmt+0x284>
f01039cc:	89 df                	mov    %ebx,%edi
f01039ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01039d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039d4:	85 ff                	test   %edi,%edi
f01039d6:	7f e4                	jg     f01039bc <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01039d8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01039db:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01039e1:	e9 90 fd ff ff       	jmp    f0103776 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01039e6:	83 f9 01             	cmp    $0x1,%ecx
f01039e9:	7e 19                	jle    f0103a04 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f01039eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ee:	8b 50 04             	mov    0x4(%eax),%edx
f01039f1:	8b 00                	mov    (%eax),%eax
f01039f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039f6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01039f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01039fc:	8d 40 08             	lea    0x8(%eax),%eax
f01039ff:	89 45 14             	mov    %eax,0x14(%ebp)
f0103a02:	eb 38                	jmp    f0103a3c <vprintfmt+0x2ec>
	else if (lflag)
f0103a04:	85 c9                	test   %ecx,%ecx
f0103a06:	74 1b                	je     f0103a23 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103a08:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a0b:	8b 00                	mov    (%eax),%eax
f0103a0d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a10:	89 c1                	mov    %eax,%ecx
f0103a12:	c1 f9 1f             	sar    $0x1f,%ecx
f0103a15:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103a18:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a1b:	8d 40 04             	lea    0x4(%eax),%eax
f0103a1e:	89 45 14             	mov    %eax,0x14(%ebp)
f0103a21:	eb 19                	jmp    f0103a3c <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103a23:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a26:	8b 00                	mov    (%eax),%eax
f0103a28:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a2b:	89 c1                	mov    %eax,%ecx
f0103a2d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103a30:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103a33:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a36:	8d 40 04             	lea    0x4(%eax),%eax
f0103a39:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103a3c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a3f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103a42:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103a47:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103a4b:	0f 89 0e 01 00 00    	jns    f0103b5f <vprintfmt+0x40f>
				putch('-', putdat);
f0103a51:	83 ec 08             	sub    $0x8,%esp
f0103a54:	53                   	push   %ebx
f0103a55:	6a 2d                	push   $0x2d
f0103a57:	ff d6                	call   *%esi
				num = -(long long) num;
f0103a59:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a5c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103a5f:	f7 da                	neg    %edx
f0103a61:	83 d1 00             	adc    $0x0,%ecx
f0103a64:	f7 d9                	neg    %ecx
f0103a66:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103a69:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a6e:	e9 ec 00 00 00       	jmp    f0103b5f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103a73:	83 f9 01             	cmp    $0x1,%ecx
f0103a76:	7e 18                	jle    f0103a90 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103a78:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a7b:	8b 10                	mov    (%eax),%edx
f0103a7d:	8b 48 04             	mov    0x4(%eax),%ecx
f0103a80:	8d 40 08             	lea    0x8(%eax),%eax
f0103a83:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103a86:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a8b:	e9 cf 00 00 00       	jmp    f0103b5f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103a90:	85 c9                	test   %ecx,%ecx
f0103a92:	74 1a                	je     f0103aae <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103a94:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a97:	8b 10                	mov    (%eax),%edx
f0103a99:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a9e:	8d 40 04             	lea    0x4(%eax),%eax
f0103aa1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103aa4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103aa9:	e9 b1 00 00 00       	jmp    f0103b5f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103aae:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ab1:	8b 10                	mov    (%eax),%edx
f0103ab3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ab8:	8d 40 04             	lea    0x4(%eax),%eax
f0103abb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103abe:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103ac3:	e9 97 00 00 00       	jmp    f0103b5f <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103ac8:	83 ec 08             	sub    $0x8,%esp
f0103acb:	53                   	push   %ebx
f0103acc:	6a 58                	push   $0x58
f0103ace:	ff d6                	call   *%esi
			putch('X', putdat);
f0103ad0:	83 c4 08             	add    $0x8,%esp
f0103ad3:	53                   	push   %ebx
f0103ad4:	6a 58                	push   $0x58
f0103ad6:	ff d6                	call   *%esi
			putch('X', putdat);
f0103ad8:	83 c4 08             	add    $0x8,%esp
f0103adb:	53                   	push   %ebx
f0103adc:	6a 58                	push   $0x58
f0103ade:	ff d6                	call   *%esi
			break;
f0103ae0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ae3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103ae6:	e9 8b fc ff ff       	jmp    f0103776 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103aeb:	83 ec 08             	sub    $0x8,%esp
f0103aee:	53                   	push   %ebx
f0103aef:	6a 30                	push   $0x30
f0103af1:	ff d6                	call   *%esi
			putch('x', putdat);
f0103af3:	83 c4 08             	add    $0x8,%esp
f0103af6:	53                   	push   %ebx
f0103af7:	6a 78                	push   $0x78
f0103af9:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103afb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103afe:	8b 10                	mov    (%eax),%edx
f0103b00:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103b05:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103b08:	8d 40 04             	lea    0x4(%eax),%eax
f0103b0b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b0e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103b13:	eb 4a                	jmp    f0103b5f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103b15:	83 f9 01             	cmp    $0x1,%ecx
f0103b18:	7e 15                	jle    f0103b2f <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103b1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b1d:	8b 10                	mov    (%eax),%edx
f0103b1f:	8b 48 04             	mov    0x4(%eax),%ecx
f0103b22:	8d 40 08             	lea    0x8(%eax),%eax
f0103b25:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103b28:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b2d:	eb 30                	jmp    f0103b5f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103b2f:	85 c9                	test   %ecx,%ecx
f0103b31:	74 17                	je     f0103b4a <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103b33:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b36:	8b 10                	mov    (%eax),%edx
f0103b38:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b3d:	8d 40 04             	lea    0x4(%eax),%eax
f0103b40:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103b43:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b48:	eb 15                	jmp    f0103b5f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103b4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b4d:	8b 10                	mov    (%eax),%edx
f0103b4f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b54:	8d 40 04             	lea    0x4(%eax),%eax
f0103b57:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103b5a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103b5f:	83 ec 0c             	sub    $0xc,%esp
f0103b62:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103b66:	57                   	push   %edi
f0103b67:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b6a:	50                   	push   %eax
f0103b6b:	51                   	push   %ecx
f0103b6c:	52                   	push   %edx
f0103b6d:	89 da                	mov    %ebx,%edx
f0103b6f:	89 f0                	mov    %esi,%eax
f0103b71:	e8 f1 fa ff ff       	call   f0103667 <printnum>
			break;
f0103b76:	83 c4 20             	add    $0x20,%esp
f0103b79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b7c:	e9 f5 fb ff ff       	jmp    f0103776 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103b81:	83 ec 08             	sub    $0x8,%esp
f0103b84:	53                   	push   %ebx
f0103b85:	52                   	push   %edx
f0103b86:	ff d6                	call   *%esi
			break;
f0103b88:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103b8e:	e9 e3 fb ff ff       	jmp    f0103776 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103b93:	83 ec 08             	sub    $0x8,%esp
f0103b96:	53                   	push   %ebx
f0103b97:	6a 25                	push   $0x25
f0103b99:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103b9b:	83 c4 10             	add    $0x10,%esp
f0103b9e:	eb 03                	jmp    f0103ba3 <vprintfmt+0x453>
f0103ba0:	83 ef 01             	sub    $0x1,%edi
f0103ba3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103ba7:	75 f7                	jne    f0103ba0 <vprintfmt+0x450>
f0103ba9:	e9 c8 fb ff ff       	jmp    f0103776 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103bae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bb1:	5b                   	pop    %ebx
f0103bb2:	5e                   	pop    %esi
f0103bb3:	5f                   	pop    %edi
f0103bb4:	5d                   	pop    %ebp
f0103bb5:	c3                   	ret    

f0103bb6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103bb6:	55                   	push   %ebp
f0103bb7:	89 e5                	mov    %esp,%ebp
f0103bb9:	83 ec 18             	sub    $0x18,%esp
f0103bbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bbf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103bc2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103bc5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103bc9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103bcc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103bd3:	85 c0                	test   %eax,%eax
f0103bd5:	74 26                	je     f0103bfd <vsnprintf+0x47>
f0103bd7:	85 d2                	test   %edx,%edx
f0103bd9:	7e 22                	jle    f0103bfd <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103bdb:	ff 75 14             	pushl  0x14(%ebp)
f0103bde:	ff 75 10             	pushl  0x10(%ebp)
f0103be1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103be4:	50                   	push   %eax
f0103be5:	68 16 37 10 f0       	push   $0xf0103716
f0103bea:	e8 61 fb ff ff       	call   f0103750 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103bef:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103bf2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103bf8:	83 c4 10             	add    $0x10,%esp
f0103bfb:	eb 05                	jmp    f0103c02 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103bfd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103c02:	c9                   	leave  
f0103c03:	c3                   	ret    

f0103c04 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103c04:	55                   	push   %ebp
f0103c05:	89 e5                	mov    %esp,%ebp
f0103c07:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103c0a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103c0d:	50                   	push   %eax
f0103c0e:	ff 75 10             	pushl  0x10(%ebp)
f0103c11:	ff 75 0c             	pushl  0xc(%ebp)
f0103c14:	ff 75 08             	pushl  0x8(%ebp)
f0103c17:	e8 9a ff ff ff       	call   f0103bb6 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103c1c:	c9                   	leave  
f0103c1d:	c3                   	ret    

f0103c1e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103c1e:	55                   	push   %ebp
f0103c1f:	89 e5                	mov    %esp,%ebp
f0103c21:	57                   	push   %edi
f0103c22:	56                   	push   %esi
f0103c23:	53                   	push   %ebx
f0103c24:	83 ec 0c             	sub    $0xc,%esp
f0103c27:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103c2a:	85 c0                	test   %eax,%eax
f0103c2c:	74 11                	je     f0103c3f <readline+0x21>
		cprintf("%s", prompt);
f0103c2e:	83 ec 08             	sub    $0x8,%esp
f0103c31:	50                   	push   %eax
f0103c32:	68 04 48 10 f0       	push   $0xf0104804
f0103c37:	e8 f4 f1 ff ff       	call   f0102e30 <cprintf>
f0103c3c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103c3f:	83 ec 0c             	sub    $0xc,%esp
f0103c42:	6a 00                	push   $0x0
f0103c44:	e8 ed c9 ff ff       	call   f0100636 <iscons>
f0103c49:	89 c7                	mov    %eax,%edi
f0103c4b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103c4e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103c53:	e8 cd c9 ff ff       	call   f0100625 <getchar>
f0103c58:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103c5a:	85 c0                	test   %eax,%eax
f0103c5c:	79 18                	jns    f0103c76 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103c5e:	83 ec 08             	sub    $0x8,%esp
f0103c61:	50                   	push   %eax
f0103c62:	68 80 59 10 f0       	push   $0xf0105980
f0103c67:	e8 c4 f1 ff ff       	call   f0102e30 <cprintf>
			return NULL;
f0103c6c:	83 c4 10             	add    $0x10,%esp
f0103c6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c74:	eb 79                	jmp    f0103cef <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103c76:	83 f8 08             	cmp    $0x8,%eax
f0103c79:	0f 94 c2             	sete   %dl
f0103c7c:	83 f8 7f             	cmp    $0x7f,%eax
f0103c7f:	0f 94 c0             	sete   %al
f0103c82:	08 c2                	or     %al,%dl
f0103c84:	74 1a                	je     f0103ca0 <readline+0x82>
f0103c86:	85 f6                	test   %esi,%esi
f0103c88:	7e 16                	jle    f0103ca0 <readline+0x82>
			if (echoing)
f0103c8a:	85 ff                	test   %edi,%edi
f0103c8c:	74 0d                	je     f0103c9b <readline+0x7d>
				cputchar('\b');
f0103c8e:	83 ec 0c             	sub    $0xc,%esp
f0103c91:	6a 08                	push   $0x8
f0103c93:	e8 7d c9 ff ff       	call   f0100615 <cputchar>
f0103c98:	83 c4 10             	add    $0x10,%esp
			i--;
f0103c9b:	83 ee 01             	sub    $0x1,%esi
f0103c9e:	eb b3                	jmp    f0103c53 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103ca0:	83 fb 1f             	cmp    $0x1f,%ebx
f0103ca3:	7e 23                	jle    f0103cc8 <readline+0xaa>
f0103ca5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103cab:	7f 1b                	jg     f0103cc8 <readline+0xaa>
			if (echoing)
f0103cad:	85 ff                	test   %edi,%edi
f0103caf:	74 0c                	je     f0103cbd <readline+0x9f>
				cputchar(c);
f0103cb1:	83 ec 0c             	sub    $0xc,%esp
f0103cb4:	53                   	push   %ebx
f0103cb5:	e8 5b c9 ff ff       	call   f0100615 <cputchar>
f0103cba:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103cbd:	88 9e 40 c9 17 f0    	mov    %bl,-0xfe836c0(%esi)
f0103cc3:	8d 76 01             	lea    0x1(%esi),%esi
f0103cc6:	eb 8b                	jmp    f0103c53 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103cc8:	83 fb 0a             	cmp    $0xa,%ebx
f0103ccb:	74 05                	je     f0103cd2 <readline+0xb4>
f0103ccd:	83 fb 0d             	cmp    $0xd,%ebx
f0103cd0:	75 81                	jne    f0103c53 <readline+0x35>
			if (echoing)
f0103cd2:	85 ff                	test   %edi,%edi
f0103cd4:	74 0d                	je     f0103ce3 <readline+0xc5>
				cputchar('\n');
f0103cd6:	83 ec 0c             	sub    $0xc,%esp
f0103cd9:	6a 0a                	push   $0xa
f0103cdb:	e8 35 c9 ff ff       	call   f0100615 <cputchar>
f0103ce0:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103ce3:	c6 86 40 c9 17 f0 00 	movb   $0x0,-0xfe836c0(%esi)
			return buf;
f0103cea:	b8 40 c9 17 f0       	mov    $0xf017c940,%eax
		}
	}
}
f0103cef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cf2:	5b                   	pop    %ebx
f0103cf3:	5e                   	pop    %esi
f0103cf4:	5f                   	pop    %edi
f0103cf5:	5d                   	pop    %ebp
f0103cf6:	c3                   	ret    

f0103cf7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103cf7:	55                   	push   %ebp
f0103cf8:	89 e5                	mov    %esp,%ebp
f0103cfa:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103cfd:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d02:	eb 03                	jmp    f0103d07 <strlen+0x10>
		n++;
f0103d04:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d07:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103d0b:	75 f7                	jne    f0103d04 <strlen+0xd>
		n++;
	return n;
}
f0103d0d:	5d                   	pop    %ebp
f0103d0e:	c3                   	ret    

f0103d0f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103d0f:	55                   	push   %ebp
f0103d10:	89 e5                	mov    %esp,%ebp
f0103d12:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d15:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d18:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d1d:	eb 03                	jmp    f0103d22 <strnlen+0x13>
		n++;
f0103d1f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d22:	39 c2                	cmp    %eax,%edx
f0103d24:	74 08                	je     f0103d2e <strnlen+0x1f>
f0103d26:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103d2a:	75 f3                	jne    f0103d1f <strnlen+0x10>
f0103d2c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103d2e:	5d                   	pop    %ebp
f0103d2f:	c3                   	ret    

f0103d30 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103d30:	55                   	push   %ebp
f0103d31:	89 e5                	mov    %esp,%ebp
f0103d33:	53                   	push   %ebx
f0103d34:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d37:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103d3a:	89 c2                	mov    %eax,%edx
f0103d3c:	83 c2 01             	add    $0x1,%edx
f0103d3f:	83 c1 01             	add    $0x1,%ecx
f0103d42:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103d46:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103d49:	84 db                	test   %bl,%bl
f0103d4b:	75 ef                	jne    f0103d3c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103d4d:	5b                   	pop    %ebx
f0103d4e:	5d                   	pop    %ebp
f0103d4f:	c3                   	ret    

f0103d50 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103d50:	55                   	push   %ebp
f0103d51:	89 e5                	mov    %esp,%ebp
f0103d53:	53                   	push   %ebx
f0103d54:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103d57:	53                   	push   %ebx
f0103d58:	e8 9a ff ff ff       	call   f0103cf7 <strlen>
f0103d5d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103d60:	ff 75 0c             	pushl  0xc(%ebp)
f0103d63:	01 d8                	add    %ebx,%eax
f0103d65:	50                   	push   %eax
f0103d66:	e8 c5 ff ff ff       	call   f0103d30 <strcpy>
	return dst;
}
f0103d6b:	89 d8                	mov    %ebx,%eax
f0103d6d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103d70:	c9                   	leave  
f0103d71:	c3                   	ret    

f0103d72 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103d72:	55                   	push   %ebp
f0103d73:	89 e5                	mov    %esp,%ebp
f0103d75:	56                   	push   %esi
f0103d76:	53                   	push   %ebx
f0103d77:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d7a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103d7d:	89 f3                	mov    %esi,%ebx
f0103d7f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d82:	89 f2                	mov    %esi,%edx
f0103d84:	eb 0f                	jmp    f0103d95 <strncpy+0x23>
		*dst++ = *src;
f0103d86:	83 c2 01             	add    $0x1,%edx
f0103d89:	0f b6 01             	movzbl (%ecx),%eax
f0103d8c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103d8f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103d92:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d95:	39 da                	cmp    %ebx,%edx
f0103d97:	75 ed                	jne    f0103d86 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103d99:	89 f0                	mov    %esi,%eax
f0103d9b:	5b                   	pop    %ebx
f0103d9c:	5e                   	pop    %esi
f0103d9d:	5d                   	pop    %ebp
f0103d9e:	c3                   	ret    

f0103d9f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103d9f:	55                   	push   %ebp
f0103da0:	89 e5                	mov    %esp,%ebp
f0103da2:	56                   	push   %esi
f0103da3:	53                   	push   %ebx
f0103da4:	8b 75 08             	mov    0x8(%ebp),%esi
f0103da7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103daa:	8b 55 10             	mov    0x10(%ebp),%edx
f0103dad:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103daf:	85 d2                	test   %edx,%edx
f0103db1:	74 21                	je     f0103dd4 <strlcpy+0x35>
f0103db3:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103db7:	89 f2                	mov    %esi,%edx
f0103db9:	eb 09                	jmp    f0103dc4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103dbb:	83 c2 01             	add    $0x1,%edx
f0103dbe:	83 c1 01             	add    $0x1,%ecx
f0103dc1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103dc4:	39 c2                	cmp    %eax,%edx
f0103dc6:	74 09                	je     f0103dd1 <strlcpy+0x32>
f0103dc8:	0f b6 19             	movzbl (%ecx),%ebx
f0103dcb:	84 db                	test   %bl,%bl
f0103dcd:	75 ec                	jne    f0103dbb <strlcpy+0x1c>
f0103dcf:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103dd1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103dd4:	29 f0                	sub    %esi,%eax
}
f0103dd6:	5b                   	pop    %ebx
f0103dd7:	5e                   	pop    %esi
f0103dd8:	5d                   	pop    %ebp
f0103dd9:	c3                   	ret    

f0103dda <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103dda:	55                   	push   %ebp
f0103ddb:	89 e5                	mov    %esp,%ebp
f0103ddd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103de0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103de3:	eb 06                	jmp    f0103deb <strcmp+0x11>
		p++, q++;
f0103de5:	83 c1 01             	add    $0x1,%ecx
f0103de8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103deb:	0f b6 01             	movzbl (%ecx),%eax
f0103dee:	84 c0                	test   %al,%al
f0103df0:	74 04                	je     f0103df6 <strcmp+0x1c>
f0103df2:	3a 02                	cmp    (%edx),%al
f0103df4:	74 ef                	je     f0103de5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103df6:	0f b6 c0             	movzbl %al,%eax
f0103df9:	0f b6 12             	movzbl (%edx),%edx
f0103dfc:	29 d0                	sub    %edx,%eax
}
f0103dfe:	5d                   	pop    %ebp
f0103dff:	c3                   	ret    

f0103e00 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103e00:	55                   	push   %ebp
f0103e01:	89 e5                	mov    %esp,%ebp
f0103e03:	53                   	push   %ebx
f0103e04:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e07:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e0a:	89 c3                	mov    %eax,%ebx
f0103e0c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103e0f:	eb 06                	jmp    f0103e17 <strncmp+0x17>
		n--, p++, q++;
f0103e11:	83 c0 01             	add    $0x1,%eax
f0103e14:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103e17:	39 d8                	cmp    %ebx,%eax
f0103e19:	74 15                	je     f0103e30 <strncmp+0x30>
f0103e1b:	0f b6 08             	movzbl (%eax),%ecx
f0103e1e:	84 c9                	test   %cl,%cl
f0103e20:	74 04                	je     f0103e26 <strncmp+0x26>
f0103e22:	3a 0a                	cmp    (%edx),%cl
f0103e24:	74 eb                	je     f0103e11 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e26:	0f b6 00             	movzbl (%eax),%eax
f0103e29:	0f b6 12             	movzbl (%edx),%edx
f0103e2c:	29 d0                	sub    %edx,%eax
f0103e2e:	eb 05                	jmp    f0103e35 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103e30:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103e35:	5b                   	pop    %ebx
f0103e36:	5d                   	pop    %ebp
f0103e37:	c3                   	ret    

f0103e38 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103e38:	55                   	push   %ebp
f0103e39:	89 e5                	mov    %esp,%ebp
f0103e3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e3e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e42:	eb 07                	jmp    f0103e4b <strchr+0x13>
		if (*s == c)
f0103e44:	38 ca                	cmp    %cl,%dl
f0103e46:	74 0f                	je     f0103e57 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103e48:	83 c0 01             	add    $0x1,%eax
f0103e4b:	0f b6 10             	movzbl (%eax),%edx
f0103e4e:	84 d2                	test   %dl,%dl
f0103e50:	75 f2                	jne    f0103e44 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103e52:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e57:	5d                   	pop    %ebp
f0103e58:	c3                   	ret    

f0103e59 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103e59:	55                   	push   %ebp
f0103e5a:	89 e5                	mov    %esp,%ebp
f0103e5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e5f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e63:	eb 03                	jmp    f0103e68 <strfind+0xf>
f0103e65:	83 c0 01             	add    $0x1,%eax
f0103e68:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103e6b:	38 ca                	cmp    %cl,%dl
f0103e6d:	74 04                	je     f0103e73 <strfind+0x1a>
f0103e6f:	84 d2                	test   %dl,%dl
f0103e71:	75 f2                	jne    f0103e65 <strfind+0xc>
			break;
	return (char *) s;
}
f0103e73:	5d                   	pop    %ebp
f0103e74:	c3                   	ret    

f0103e75 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103e75:	55                   	push   %ebp
f0103e76:	89 e5                	mov    %esp,%ebp
f0103e78:	57                   	push   %edi
f0103e79:	56                   	push   %esi
f0103e7a:	53                   	push   %ebx
f0103e7b:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103e7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103e81:	85 c9                	test   %ecx,%ecx
f0103e83:	74 36                	je     f0103ebb <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103e85:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103e8b:	75 28                	jne    f0103eb5 <memset+0x40>
f0103e8d:	f6 c1 03             	test   $0x3,%cl
f0103e90:	75 23                	jne    f0103eb5 <memset+0x40>
		c &= 0xFF;
f0103e92:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103e96:	89 d3                	mov    %edx,%ebx
f0103e98:	c1 e3 08             	shl    $0x8,%ebx
f0103e9b:	89 d6                	mov    %edx,%esi
f0103e9d:	c1 e6 18             	shl    $0x18,%esi
f0103ea0:	89 d0                	mov    %edx,%eax
f0103ea2:	c1 e0 10             	shl    $0x10,%eax
f0103ea5:	09 f0                	or     %esi,%eax
f0103ea7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103ea9:	89 d8                	mov    %ebx,%eax
f0103eab:	09 d0                	or     %edx,%eax
f0103ead:	c1 e9 02             	shr    $0x2,%ecx
f0103eb0:	fc                   	cld    
f0103eb1:	f3 ab                	rep stos %eax,%es:(%edi)
f0103eb3:	eb 06                	jmp    f0103ebb <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103eb8:	fc                   	cld    
f0103eb9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103ebb:	89 f8                	mov    %edi,%eax
f0103ebd:	5b                   	pop    %ebx
f0103ebe:	5e                   	pop    %esi
f0103ebf:	5f                   	pop    %edi
f0103ec0:	5d                   	pop    %ebp
f0103ec1:	c3                   	ret    

f0103ec2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ec2:	55                   	push   %ebp
f0103ec3:	89 e5                	mov    %esp,%ebp
f0103ec5:	57                   	push   %edi
f0103ec6:	56                   	push   %esi
f0103ec7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eca:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ecd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103ed0:	39 c6                	cmp    %eax,%esi
f0103ed2:	73 35                	jae    f0103f09 <memmove+0x47>
f0103ed4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103ed7:	39 d0                	cmp    %edx,%eax
f0103ed9:	73 2e                	jae    f0103f09 <memmove+0x47>
		s += n;
		d += n;
f0103edb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ede:	89 d6                	mov    %edx,%esi
f0103ee0:	09 fe                	or     %edi,%esi
f0103ee2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ee8:	75 13                	jne    f0103efd <memmove+0x3b>
f0103eea:	f6 c1 03             	test   $0x3,%cl
f0103eed:	75 0e                	jne    f0103efd <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103eef:	83 ef 04             	sub    $0x4,%edi
f0103ef2:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103ef5:	c1 e9 02             	shr    $0x2,%ecx
f0103ef8:	fd                   	std    
f0103ef9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103efb:	eb 09                	jmp    f0103f06 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103efd:	83 ef 01             	sub    $0x1,%edi
f0103f00:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103f03:	fd                   	std    
f0103f04:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103f06:	fc                   	cld    
f0103f07:	eb 1d                	jmp    f0103f26 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f09:	89 f2                	mov    %esi,%edx
f0103f0b:	09 c2                	or     %eax,%edx
f0103f0d:	f6 c2 03             	test   $0x3,%dl
f0103f10:	75 0f                	jne    f0103f21 <memmove+0x5f>
f0103f12:	f6 c1 03             	test   $0x3,%cl
f0103f15:	75 0a                	jne    f0103f21 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103f17:	c1 e9 02             	shr    $0x2,%ecx
f0103f1a:	89 c7                	mov    %eax,%edi
f0103f1c:	fc                   	cld    
f0103f1d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f1f:	eb 05                	jmp    f0103f26 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103f21:	89 c7                	mov    %eax,%edi
f0103f23:	fc                   	cld    
f0103f24:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103f26:	5e                   	pop    %esi
f0103f27:	5f                   	pop    %edi
f0103f28:	5d                   	pop    %ebp
f0103f29:	c3                   	ret    

f0103f2a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103f2a:	55                   	push   %ebp
f0103f2b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103f2d:	ff 75 10             	pushl  0x10(%ebp)
f0103f30:	ff 75 0c             	pushl  0xc(%ebp)
f0103f33:	ff 75 08             	pushl  0x8(%ebp)
f0103f36:	e8 87 ff ff ff       	call   f0103ec2 <memmove>
}
f0103f3b:	c9                   	leave  
f0103f3c:	c3                   	ret    

f0103f3d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103f3d:	55                   	push   %ebp
f0103f3e:	89 e5                	mov    %esp,%ebp
f0103f40:	56                   	push   %esi
f0103f41:	53                   	push   %ebx
f0103f42:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f45:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f48:	89 c6                	mov    %eax,%esi
f0103f4a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f4d:	eb 1a                	jmp    f0103f69 <memcmp+0x2c>
		if (*s1 != *s2)
f0103f4f:	0f b6 08             	movzbl (%eax),%ecx
f0103f52:	0f b6 1a             	movzbl (%edx),%ebx
f0103f55:	38 d9                	cmp    %bl,%cl
f0103f57:	74 0a                	je     f0103f63 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103f59:	0f b6 c1             	movzbl %cl,%eax
f0103f5c:	0f b6 db             	movzbl %bl,%ebx
f0103f5f:	29 d8                	sub    %ebx,%eax
f0103f61:	eb 0f                	jmp    f0103f72 <memcmp+0x35>
		s1++, s2++;
f0103f63:	83 c0 01             	add    $0x1,%eax
f0103f66:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f69:	39 f0                	cmp    %esi,%eax
f0103f6b:	75 e2                	jne    f0103f4f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103f6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f72:	5b                   	pop    %ebx
f0103f73:	5e                   	pop    %esi
f0103f74:	5d                   	pop    %ebp
f0103f75:	c3                   	ret    

f0103f76 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103f76:	55                   	push   %ebp
f0103f77:	89 e5                	mov    %esp,%ebp
f0103f79:	53                   	push   %ebx
f0103f7a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103f7d:	89 c1                	mov    %eax,%ecx
f0103f7f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103f82:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103f86:	eb 0a                	jmp    f0103f92 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103f88:	0f b6 10             	movzbl (%eax),%edx
f0103f8b:	39 da                	cmp    %ebx,%edx
f0103f8d:	74 07                	je     f0103f96 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103f8f:	83 c0 01             	add    $0x1,%eax
f0103f92:	39 c8                	cmp    %ecx,%eax
f0103f94:	72 f2                	jb     f0103f88 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103f96:	5b                   	pop    %ebx
f0103f97:	5d                   	pop    %ebp
f0103f98:	c3                   	ret    

f0103f99 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103f99:	55                   	push   %ebp
f0103f9a:	89 e5                	mov    %esp,%ebp
f0103f9c:	57                   	push   %edi
f0103f9d:	56                   	push   %esi
f0103f9e:	53                   	push   %ebx
f0103f9f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fa2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fa5:	eb 03                	jmp    f0103faa <strtol+0x11>
		s++;
f0103fa7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103faa:	0f b6 01             	movzbl (%ecx),%eax
f0103fad:	3c 20                	cmp    $0x20,%al
f0103faf:	74 f6                	je     f0103fa7 <strtol+0xe>
f0103fb1:	3c 09                	cmp    $0x9,%al
f0103fb3:	74 f2                	je     f0103fa7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103fb5:	3c 2b                	cmp    $0x2b,%al
f0103fb7:	75 0a                	jne    f0103fc3 <strtol+0x2a>
		s++;
f0103fb9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103fbc:	bf 00 00 00 00       	mov    $0x0,%edi
f0103fc1:	eb 11                	jmp    f0103fd4 <strtol+0x3b>
f0103fc3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103fc8:	3c 2d                	cmp    $0x2d,%al
f0103fca:	75 08                	jne    f0103fd4 <strtol+0x3b>
		s++, neg = 1;
f0103fcc:	83 c1 01             	add    $0x1,%ecx
f0103fcf:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103fd4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103fda:	75 15                	jne    f0103ff1 <strtol+0x58>
f0103fdc:	80 39 30             	cmpb   $0x30,(%ecx)
f0103fdf:	75 10                	jne    f0103ff1 <strtol+0x58>
f0103fe1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103fe5:	75 7c                	jne    f0104063 <strtol+0xca>
		s += 2, base = 16;
f0103fe7:	83 c1 02             	add    $0x2,%ecx
f0103fea:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103fef:	eb 16                	jmp    f0104007 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103ff1:	85 db                	test   %ebx,%ebx
f0103ff3:	75 12                	jne    f0104007 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ff5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ffa:	80 39 30             	cmpb   $0x30,(%ecx)
f0103ffd:	75 08                	jne    f0104007 <strtol+0x6e>
		s++, base = 8;
f0103fff:	83 c1 01             	add    $0x1,%ecx
f0104002:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104007:	b8 00 00 00 00       	mov    $0x0,%eax
f010400c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010400f:	0f b6 11             	movzbl (%ecx),%edx
f0104012:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104015:	89 f3                	mov    %esi,%ebx
f0104017:	80 fb 09             	cmp    $0x9,%bl
f010401a:	77 08                	ja     f0104024 <strtol+0x8b>
			dig = *s - '0';
f010401c:	0f be d2             	movsbl %dl,%edx
f010401f:	83 ea 30             	sub    $0x30,%edx
f0104022:	eb 22                	jmp    f0104046 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104024:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104027:	89 f3                	mov    %esi,%ebx
f0104029:	80 fb 19             	cmp    $0x19,%bl
f010402c:	77 08                	ja     f0104036 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010402e:	0f be d2             	movsbl %dl,%edx
f0104031:	83 ea 57             	sub    $0x57,%edx
f0104034:	eb 10                	jmp    f0104046 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104036:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104039:	89 f3                	mov    %esi,%ebx
f010403b:	80 fb 19             	cmp    $0x19,%bl
f010403e:	77 16                	ja     f0104056 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104040:	0f be d2             	movsbl %dl,%edx
f0104043:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104046:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104049:	7d 0b                	jge    f0104056 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010404b:	83 c1 01             	add    $0x1,%ecx
f010404e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104052:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104054:	eb b9                	jmp    f010400f <strtol+0x76>

	if (endptr)
f0104056:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010405a:	74 0d                	je     f0104069 <strtol+0xd0>
		*endptr = (char *) s;
f010405c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010405f:	89 0e                	mov    %ecx,(%esi)
f0104061:	eb 06                	jmp    f0104069 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104063:	85 db                	test   %ebx,%ebx
f0104065:	74 98                	je     f0103fff <strtol+0x66>
f0104067:	eb 9e                	jmp    f0104007 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104069:	89 c2                	mov    %eax,%edx
f010406b:	f7 da                	neg    %edx
f010406d:	85 ff                	test   %edi,%edi
f010406f:	0f 45 c2             	cmovne %edx,%eax
}
f0104072:	5b                   	pop    %ebx
f0104073:	5e                   	pop    %esi
f0104074:	5f                   	pop    %edi
f0104075:	5d                   	pop    %ebp
f0104076:	c3                   	ret    
f0104077:	66 90                	xchg   %ax,%ax
f0104079:	66 90                	xchg   %ax,%ax
f010407b:	66 90                	xchg   %ax,%ax
f010407d:	66 90                	xchg   %ax,%ax
f010407f:	90                   	nop

f0104080 <__udivdi3>:
f0104080:	55                   	push   %ebp
f0104081:	57                   	push   %edi
f0104082:	56                   	push   %esi
f0104083:	53                   	push   %ebx
f0104084:	83 ec 1c             	sub    $0x1c,%esp
f0104087:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010408b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010408f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104093:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104097:	85 f6                	test   %esi,%esi
f0104099:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010409d:	89 ca                	mov    %ecx,%edx
f010409f:	89 f8                	mov    %edi,%eax
f01040a1:	75 3d                	jne    f01040e0 <__udivdi3+0x60>
f01040a3:	39 cf                	cmp    %ecx,%edi
f01040a5:	0f 87 c5 00 00 00    	ja     f0104170 <__udivdi3+0xf0>
f01040ab:	85 ff                	test   %edi,%edi
f01040ad:	89 fd                	mov    %edi,%ebp
f01040af:	75 0b                	jne    f01040bc <__udivdi3+0x3c>
f01040b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01040b6:	31 d2                	xor    %edx,%edx
f01040b8:	f7 f7                	div    %edi
f01040ba:	89 c5                	mov    %eax,%ebp
f01040bc:	89 c8                	mov    %ecx,%eax
f01040be:	31 d2                	xor    %edx,%edx
f01040c0:	f7 f5                	div    %ebp
f01040c2:	89 c1                	mov    %eax,%ecx
f01040c4:	89 d8                	mov    %ebx,%eax
f01040c6:	89 cf                	mov    %ecx,%edi
f01040c8:	f7 f5                	div    %ebp
f01040ca:	89 c3                	mov    %eax,%ebx
f01040cc:	89 d8                	mov    %ebx,%eax
f01040ce:	89 fa                	mov    %edi,%edx
f01040d0:	83 c4 1c             	add    $0x1c,%esp
f01040d3:	5b                   	pop    %ebx
f01040d4:	5e                   	pop    %esi
f01040d5:	5f                   	pop    %edi
f01040d6:	5d                   	pop    %ebp
f01040d7:	c3                   	ret    
f01040d8:	90                   	nop
f01040d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040e0:	39 ce                	cmp    %ecx,%esi
f01040e2:	77 74                	ja     f0104158 <__udivdi3+0xd8>
f01040e4:	0f bd fe             	bsr    %esi,%edi
f01040e7:	83 f7 1f             	xor    $0x1f,%edi
f01040ea:	0f 84 98 00 00 00    	je     f0104188 <__udivdi3+0x108>
f01040f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01040f5:	89 f9                	mov    %edi,%ecx
f01040f7:	89 c5                	mov    %eax,%ebp
f01040f9:	29 fb                	sub    %edi,%ebx
f01040fb:	d3 e6                	shl    %cl,%esi
f01040fd:	89 d9                	mov    %ebx,%ecx
f01040ff:	d3 ed                	shr    %cl,%ebp
f0104101:	89 f9                	mov    %edi,%ecx
f0104103:	d3 e0                	shl    %cl,%eax
f0104105:	09 ee                	or     %ebp,%esi
f0104107:	89 d9                	mov    %ebx,%ecx
f0104109:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010410d:	89 d5                	mov    %edx,%ebp
f010410f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104113:	d3 ed                	shr    %cl,%ebp
f0104115:	89 f9                	mov    %edi,%ecx
f0104117:	d3 e2                	shl    %cl,%edx
f0104119:	89 d9                	mov    %ebx,%ecx
f010411b:	d3 e8                	shr    %cl,%eax
f010411d:	09 c2                	or     %eax,%edx
f010411f:	89 d0                	mov    %edx,%eax
f0104121:	89 ea                	mov    %ebp,%edx
f0104123:	f7 f6                	div    %esi
f0104125:	89 d5                	mov    %edx,%ebp
f0104127:	89 c3                	mov    %eax,%ebx
f0104129:	f7 64 24 0c          	mull   0xc(%esp)
f010412d:	39 d5                	cmp    %edx,%ebp
f010412f:	72 10                	jb     f0104141 <__udivdi3+0xc1>
f0104131:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104135:	89 f9                	mov    %edi,%ecx
f0104137:	d3 e6                	shl    %cl,%esi
f0104139:	39 c6                	cmp    %eax,%esi
f010413b:	73 07                	jae    f0104144 <__udivdi3+0xc4>
f010413d:	39 d5                	cmp    %edx,%ebp
f010413f:	75 03                	jne    f0104144 <__udivdi3+0xc4>
f0104141:	83 eb 01             	sub    $0x1,%ebx
f0104144:	31 ff                	xor    %edi,%edi
f0104146:	89 d8                	mov    %ebx,%eax
f0104148:	89 fa                	mov    %edi,%edx
f010414a:	83 c4 1c             	add    $0x1c,%esp
f010414d:	5b                   	pop    %ebx
f010414e:	5e                   	pop    %esi
f010414f:	5f                   	pop    %edi
f0104150:	5d                   	pop    %ebp
f0104151:	c3                   	ret    
f0104152:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104158:	31 ff                	xor    %edi,%edi
f010415a:	31 db                	xor    %ebx,%ebx
f010415c:	89 d8                	mov    %ebx,%eax
f010415e:	89 fa                	mov    %edi,%edx
f0104160:	83 c4 1c             	add    $0x1c,%esp
f0104163:	5b                   	pop    %ebx
f0104164:	5e                   	pop    %esi
f0104165:	5f                   	pop    %edi
f0104166:	5d                   	pop    %ebp
f0104167:	c3                   	ret    
f0104168:	90                   	nop
f0104169:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104170:	89 d8                	mov    %ebx,%eax
f0104172:	f7 f7                	div    %edi
f0104174:	31 ff                	xor    %edi,%edi
f0104176:	89 c3                	mov    %eax,%ebx
f0104178:	89 d8                	mov    %ebx,%eax
f010417a:	89 fa                	mov    %edi,%edx
f010417c:	83 c4 1c             	add    $0x1c,%esp
f010417f:	5b                   	pop    %ebx
f0104180:	5e                   	pop    %esi
f0104181:	5f                   	pop    %edi
f0104182:	5d                   	pop    %ebp
f0104183:	c3                   	ret    
f0104184:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104188:	39 ce                	cmp    %ecx,%esi
f010418a:	72 0c                	jb     f0104198 <__udivdi3+0x118>
f010418c:	31 db                	xor    %ebx,%ebx
f010418e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104192:	0f 87 34 ff ff ff    	ja     f01040cc <__udivdi3+0x4c>
f0104198:	bb 01 00 00 00       	mov    $0x1,%ebx
f010419d:	e9 2a ff ff ff       	jmp    f01040cc <__udivdi3+0x4c>
f01041a2:	66 90                	xchg   %ax,%ax
f01041a4:	66 90                	xchg   %ax,%ax
f01041a6:	66 90                	xchg   %ax,%ax
f01041a8:	66 90                	xchg   %ax,%ax
f01041aa:	66 90                	xchg   %ax,%ax
f01041ac:	66 90                	xchg   %ax,%ax
f01041ae:	66 90                	xchg   %ax,%ax

f01041b0 <__umoddi3>:
f01041b0:	55                   	push   %ebp
f01041b1:	57                   	push   %edi
f01041b2:	56                   	push   %esi
f01041b3:	53                   	push   %ebx
f01041b4:	83 ec 1c             	sub    $0x1c,%esp
f01041b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01041bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01041bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01041c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01041c7:	85 d2                	test   %edx,%edx
f01041c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01041cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01041d1:	89 f3                	mov    %esi,%ebx
f01041d3:	89 3c 24             	mov    %edi,(%esp)
f01041d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01041da:	75 1c                	jne    f01041f8 <__umoddi3+0x48>
f01041dc:	39 f7                	cmp    %esi,%edi
f01041de:	76 50                	jbe    f0104230 <__umoddi3+0x80>
f01041e0:	89 c8                	mov    %ecx,%eax
f01041e2:	89 f2                	mov    %esi,%edx
f01041e4:	f7 f7                	div    %edi
f01041e6:	89 d0                	mov    %edx,%eax
f01041e8:	31 d2                	xor    %edx,%edx
f01041ea:	83 c4 1c             	add    $0x1c,%esp
f01041ed:	5b                   	pop    %ebx
f01041ee:	5e                   	pop    %esi
f01041ef:	5f                   	pop    %edi
f01041f0:	5d                   	pop    %ebp
f01041f1:	c3                   	ret    
f01041f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01041f8:	39 f2                	cmp    %esi,%edx
f01041fa:	89 d0                	mov    %edx,%eax
f01041fc:	77 52                	ja     f0104250 <__umoddi3+0xa0>
f01041fe:	0f bd ea             	bsr    %edx,%ebp
f0104201:	83 f5 1f             	xor    $0x1f,%ebp
f0104204:	75 5a                	jne    f0104260 <__umoddi3+0xb0>
f0104206:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010420a:	0f 82 e0 00 00 00    	jb     f01042f0 <__umoddi3+0x140>
f0104210:	39 0c 24             	cmp    %ecx,(%esp)
f0104213:	0f 86 d7 00 00 00    	jbe    f01042f0 <__umoddi3+0x140>
f0104219:	8b 44 24 08          	mov    0x8(%esp),%eax
f010421d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104221:	83 c4 1c             	add    $0x1c,%esp
f0104224:	5b                   	pop    %ebx
f0104225:	5e                   	pop    %esi
f0104226:	5f                   	pop    %edi
f0104227:	5d                   	pop    %ebp
f0104228:	c3                   	ret    
f0104229:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104230:	85 ff                	test   %edi,%edi
f0104232:	89 fd                	mov    %edi,%ebp
f0104234:	75 0b                	jne    f0104241 <__umoddi3+0x91>
f0104236:	b8 01 00 00 00       	mov    $0x1,%eax
f010423b:	31 d2                	xor    %edx,%edx
f010423d:	f7 f7                	div    %edi
f010423f:	89 c5                	mov    %eax,%ebp
f0104241:	89 f0                	mov    %esi,%eax
f0104243:	31 d2                	xor    %edx,%edx
f0104245:	f7 f5                	div    %ebp
f0104247:	89 c8                	mov    %ecx,%eax
f0104249:	f7 f5                	div    %ebp
f010424b:	89 d0                	mov    %edx,%eax
f010424d:	eb 99                	jmp    f01041e8 <__umoddi3+0x38>
f010424f:	90                   	nop
f0104250:	89 c8                	mov    %ecx,%eax
f0104252:	89 f2                	mov    %esi,%edx
f0104254:	83 c4 1c             	add    $0x1c,%esp
f0104257:	5b                   	pop    %ebx
f0104258:	5e                   	pop    %esi
f0104259:	5f                   	pop    %edi
f010425a:	5d                   	pop    %ebp
f010425b:	c3                   	ret    
f010425c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104260:	8b 34 24             	mov    (%esp),%esi
f0104263:	bf 20 00 00 00       	mov    $0x20,%edi
f0104268:	89 e9                	mov    %ebp,%ecx
f010426a:	29 ef                	sub    %ebp,%edi
f010426c:	d3 e0                	shl    %cl,%eax
f010426e:	89 f9                	mov    %edi,%ecx
f0104270:	89 f2                	mov    %esi,%edx
f0104272:	d3 ea                	shr    %cl,%edx
f0104274:	89 e9                	mov    %ebp,%ecx
f0104276:	09 c2                	or     %eax,%edx
f0104278:	89 d8                	mov    %ebx,%eax
f010427a:	89 14 24             	mov    %edx,(%esp)
f010427d:	89 f2                	mov    %esi,%edx
f010427f:	d3 e2                	shl    %cl,%edx
f0104281:	89 f9                	mov    %edi,%ecx
f0104283:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104287:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010428b:	d3 e8                	shr    %cl,%eax
f010428d:	89 e9                	mov    %ebp,%ecx
f010428f:	89 c6                	mov    %eax,%esi
f0104291:	d3 e3                	shl    %cl,%ebx
f0104293:	89 f9                	mov    %edi,%ecx
f0104295:	89 d0                	mov    %edx,%eax
f0104297:	d3 e8                	shr    %cl,%eax
f0104299:	89 e9                	mov    %ebp,%ecx
f010429b:	09 d8                	or     %ebx,%eax
f010429d:	89 d3                	mov    %edx,%ebx
f010429f:	89 f2                	mov    %esi,%edx
f01042a1:	f7 34 24             	divl   (%esp)
f01042a4:	89 d6                	mov    %edx,%esi
f01042a6:	d3 e3                	shl    %cl,%ebx
f01042a8:	f7 64 24 04          	mull   0x4(%esp)
f01042ac:	39 d6                	cmp    %edx,%esi
f01042ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01042b2:	89 d1                	mov    %edx,%ecx
f01042b4:	89 c3                	mov    %eax,%ebx
f01042b6:	72 08                	jb     f01042c0 <__umoddi3+0x110>
f01042b8:	75 11                	jne    f01042cb <__umoddi3+0x11b>
f01042ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01042be:	73 0b                	jae    f01042cb <__umoddi3+0x11b>
f01042c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01042c4:	1b 14 24             	sbb    (%esp),%edx
f01042c7:	89 d1                	mov    %edx,%ecx
f01042c9:	89 c3                	mov    %eax,%ebx
f01042cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01042cf:	29 da                	sub    %ebx,%edx
f01042d1:	19 ce                	sbb    %ecx,%esi
f01042d3:	89 f9                	mov    %edi,%ecx
f01042d5:	89 f0                	mov    %esi,%eax
f01042d7:	d3 e0                	shl    %cl,%eax
f01042d9:	89 e9                	mov    %ebp,%ecx
f01042db:	d3 ea                	shr    %cl,%edx
f01042dd:	89 e9                	mov    %ebp,%ecx
f01042df:	d3 ee                	shr    %cl,%esi
f01042e1:	09 d0                	or     %edx,%eax
f01042e3:	89 f2                	mov    %esi,%edx
f01042e5:	83 c4 1c             	add    $0x1c,%esp
f01042e8:	5b                   	pop    %ebx
f01042e9:	5e                   	pop    %esi
f01042ea:	5f                   	pop    %edi
f01042eb:	5d                   	pop    %ebp
f01042ec:	c3                   	ret    
f01042ed:	8d 76 00             	lea    0x0(%esi),%esi
f01042f0:	29 f9                	sub    %edi,%ecx
f01042f2:	19 d6                	sbb    %edx,%esi
f01042f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01042fc:	e9 18 ff ff ff       	jmp    f0104219 <__umoddi3+0x69>
