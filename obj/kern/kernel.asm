
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 50 69 11 f0       	mov    $0xf0116950,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 d4 30 00 00       	call   f0103131 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 35 10 f0       	push   $0xf01035e0
f010006f:	e8 d4 25 00 00       	call   f0102648 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 29 0f 00 00       	call   f0100fa2 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 97 06 00 00       	call   f010071d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 69 11 f0 00 	cmpl   $0x0,0xf0116940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 69 11 f0    	mov    %esi,0xf0116940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 fb 35 10 f0       	push   $0xf01035fb
f01000b5:	e8 8e 25 00 00       	call   f0102648 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 5e 25 00 00       	call   f0102622 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 54 3b 10 f0 	movl   $0xf0103b54,(%esp)
f01000cb:	e8 78 25 00 00       	call   f0102648 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 40 06 00 00       	call   f010071d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 13 36 10 f0       	push   $0xf0103613
f01000f7:	e8 4c 25 00 00       	call   f0102648 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 1a 25 00 00       	call   f0102622 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 54 3b 10 f0 	movl   $0xf0103b54,(%esp)
f010010f:	e8 34 25 00 00       	call   f0102648 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 80 37 10 f0 	movzbl -0xfefc880(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 80 37 10 f0 	movzbl -0xfefc880(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 80 36 10 f0 	movzbl -0xfefc980(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 60 36 10 f0 	mov    -0xfefc9a0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 2d 36 10 f0       	push   $0xf010362d
f010026d:	e8 d6 23 00 00       	call   f0102648 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 5d 2d 00 00       	call   f010317e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 39 36 10 f0       	push   $0xf0103639
f01005f0:	e8 53 20 00 00       	call   f0102648 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 80 38 10 f0       	push   $0xf0103880
f0100636:	68 9e 38 10 f0       	push   $0xf010389e
f010063b:	68 a3 38 10 f0       	push   $0xf01038a3
f0100640:	e8 03 20 00 00       	call   f0102648 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 0c 39 10 f0       	push   $0xf010390c
f010064d:	68 ac 38 10 f0       	push   $0xf01038ac
f0100652:	68 a3 38 10 f0       	push   $0xf01038a3
f0100657:	e8 ec 1f 00 00       	call   f0102648 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 b5 38 10 f0       	push   $0xf01038b5
f010066e:	e8 d5 1f 00 00       	call   f0102648 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 34 39 10 f0       	push   $0xf0103934
f0100680:	e8 c3 1f 00 00       	call   f0102648 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 5c 39 10 f0       	push   $0xf010395c
f0100697:	e8 ac 1f 00 00       	call   f0102648 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 c1 35 10 00       	push   $0x1035c1
f01006a4:	68 c1 35 10 f0       	push   $0xf01035c1
f01006a9:	68 80 39 10 f0       	push   $0xf0103980
f01006ae:	e8 95 1f 00 00       	call   f0102648 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 a4 39 10 f0       	push   $0xf01039a4
f01006c5:	e8 7e 1f 00 00       	call   f0102648 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 c8 39 10 f0       	push   $0xf01039c8
f01006dc:	e8 67 1f 00 00       	call   f0102648 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 6d 11 f0       	mov    $0xf0116d4f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 ec 39 10 f0       	push   $0xf01039ec
f0100707:	e8 3c 1f 00 00       	call   f0102648 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	5d                   	pop    %ebp
f010071c:	c3                   	ret    

f010071d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071d:	55                   	push   %ebp
f010071e:	89 e5                	mov    %esp,%ebp
f0100720:	57                   	push   %edi
f0100721:	56                   	push   %esi
f0100722:	53                   	push   %ebx
f0100723:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100726:	68 18 3a 10 f0       	push   $0xf0103a18
f010072b:	e8 18 1f 00 00       	call   f0102648 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 3c 3a 10 f0 	movl   $0xf0103a3c,(%esp)
f0100737:	e8 0c 1f 00 00       	call   f0102648 <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ce 38 10 f0       	push   $0xf01038ce
f0100747:	e8 8e 27 00 00       	call   f0102eda <readline>
f010074c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010074e:	83 c4 10             	add    $0x10,%esp
f0100751:	85 c0                	test   %eax,%eax
f0100753:	74 ea                	je     f010073f <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100755:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010075c:	be 00 00 00 00       	mov    $0x0,%esi
f0100761:	eb 0a                	jmp    f010076d <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100763:	c6 03 00             	movb   $0x0,(%ebx)
f0100766:	89 f7                	mov    %esi,%edi
f0100768:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010076b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010076d:	0f b6 03             	movzbl (%ebx),%eax
f0100770:	84 c0                	test   %al,%al
f0100772:	74 63                	je     f01007d7 <monitor+0xba>
f0100774:	83 ec 08             	sub    $0x8,%esp
f0100777:	0f be c0             	movsbl %al,%eax
f010077a:	50                   	push   %eax
f010077b:	68 d2 38 10 f0       	push   $0xf01038d2
f0100780:	e8 6f 29 00 00       	call   f01030f4 <strchr>
f0100785:	83 c4 10             	add    $0x10,%esp
f0100788:	85 c0                	test   %eax,%eax
f010078a:	75 d7                	jne    f0100763 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010078c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078f:	74 46                	je     f01007d7 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100791:	83 fe 0f             	cmp    $0xf,%esi
f0100794:	75 14                	jne    f01007aa <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100796:	83 ec 08             	sub    $0x8,%esp
f0100799:	6a 10                	push   $0x10
f010079b:	68 d7 38 10 f0       	push   $0xf01038d7
f01007a0:	e8 a3 1e 00 00       	call   f0102648 <cprintf>
f01007a5:	83 c4 10             	add    $0x10,%esp
f01007a8:	eb 95                	jmp    f010073f <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007aa:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ad:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007b1:	eb 03                	jmp    f01007b6 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007b3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007b6:	0f b6 03             	movzbl (%ebx),%eax
f01007b9:	84 c0                	test   %al,%al
f01007bb:	74 ae                	je     f010076b <monitor+0x4e>
f01007bd:	83 ec 08             	sub    $0x8,%esp
f01007c0:	0f be c0             	movsbl %al,%eax
f01007c3:	50                   	push   %eax
f01007c4:	68 d2 38 10 f0       	push   $0xf01038d2
f01007c9:	e8 26 29 00 00       	call   f01030f4 <strchr>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	85 c0                	test   %eax,%eax
f01007d3:	74 de                	je     f01007b3 <monitor+0x96>
f01007d5:	eb 94                	jmp    f010076b <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007d7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007de:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007df:	85 f6                	test   %esi,%esi
f01007e1:	0f 84 58 ff ff ff    	je     f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e7:	83 ec 08             	sub    $0x8,%esp
f01007ea:	68 9e 38 10 f0       	push   $0xf010389e
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 9f 28 00 00       	call   f0103096 <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 ac 38 10 f0       	push   $0xf01038ac
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 88 28 00 00       	call   f0103096 <strcmp>
f010080e:	83 c4 10             	add    $0x10,%esp
f0100811:	85 c0                	test   %eax,%eax
f0100813:	75 2f                	jne    f0100844 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100815:	b8 01 00 00 00       	mov    $0x1,%eax
f010081a:	eb 05                	jmp    f0100821 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010081c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100821:	83 ec 04             	sub    $0x4,%esp
f0100824:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100827:	01 d0                	add    %edx,%eax
f0100829:	ff 75 08             	pushl  0x8(%ebp)
f010082c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010082f:	51                   	push   %ecx
f0100830:	56                   	push   %esi
f0100831:	ff 14 85 6c 3a 10 f0 	call   *-0xfefc594(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	78 1d                	js     f010085c <monitor+0x13f>
f010083f:	e9 fb fe ff ff       	jmp    f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100844:	83 ec 08             	sub    $0x8,%esp
f0100847:	ff 75 a8             	pushl  -0x58(%ebp)
f010084a:	68 f4 38 10 f0       	push   $0xf01038f4
f010084f:	e8 f4 1d 00 00       	call   f0102648 <cprintf>
f0100854:	83 c4 10             	add    $0x10,%esp
f0100857:	e9 e3 fe ff ff       	jmp    f010073f <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010085f:	5b                   	pop    %ebx
f0100860:	5e                   	pop    %esi
f0100861:	5f                   	pop    %edi
f0100862:	5d                   	pop    %ebp
f0100863:	c3                   	ret    

f0100864 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100864:	55                   	push   %ebp
f0100865:	89 e5                	mov    %esp,%ebp
f0100867:	56                   	push   %esi
f0100868:	53                   	push   %ebx
f0100869:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010086b:	83 ec 0c             	sub    $0xc,%esp
f010086e:	50                   	push   %eax
f010086f:	e8 6d 1d 00 00       	call   f01025e1 <mc146818_read>
f0100874:	89 c6                	mov    %eax,%esi
f0100876:	83 c3 01             	add    $0x1,%ebx
f0100879:	89 1c 24             	mov    %ebx,(%esp)
f010087c:	e8 60 1d 00 00       	call   f01025e1 <mc146818_read>
f0100881:	c1 e0 08             	shl    $0x8,%eax
f0100884:	09 f0                	or     %esi,%eax
}
f0100886:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100889:	5b                   	pop    %ebx
f010088a:	5e                   	pop    %esi
f010088b:	5d                   	pop    %ebp
f010088c:	c3                   	ret    

f010088d <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010088d:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100894:	75 11                	jne    f01008a7 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100896:	ba 4f 79 11 f0       	mov    $0xf011794f,%edx
f010089b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008a1:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f01008a7:	85 c0                	test   %eax,%eax
f01008a9:	74 2e                	je     f01008d9 <boot_alloc+0x4c>
	{
	result=nextfree;
f01008ab:	8b 0d 38 65 11 f0    	mov    0xf0116538,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f01008b1:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01008b7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008bd:	01 ca                	add    %ecx,%edx
f01008bf:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f01008c5:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f01008ca:	05 00 00 0f 00       	add    $0xf0000,%eax
f01008cf:	c1 e0 0c             	shl    $0xc,%eax
f01008d2:	39 c2                	cmp    %eax,%edx
f01008d4:	77 09                	ja     f01008df <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f01008d6:	89 c8                	mov    %ecx,%eax
f01008d8:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f01008d9:	a1 38 65 11 f0       	mov    0xf0116538,%eax
f01008de:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008df:	55                   	push   %ebp
f01008e0:	89 e5                	mov    %esp,%ebp
f01008e2:	83 ec 0c             	sub    $0xc,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f01008e5:	68 7c 3a 10 f0       	push   $0xf0103a7c
f01008ea:	6a 79                	push   $0x79
f01008ec:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01008f1:	e8 95 f7 ff ff       	call   f010008b <_panic>

f01008f6 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008f6:	89 d1                	mov    %edx,%ecx
f01008f8:	c1 e9 16             	shr    $0x16,%ecx
f01008fb:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008fe:	a8 01                	test   $0x1,%al
f0100900:	74 52                	je     f0100954 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100902:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100907:	89 c1                	mov    %eax,%ecx
f0100909:	c1 e9 0c             	shr    $0xc,%ecx
f010090c:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0100912:	72 1b                	jb     f010092f <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100914:	55                   	push   %ebp
f0100915:	89 e5                	mov    %esp,%ebp
f0100917:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010091a:	50                   	push   %eax
f010091b:	68 84 3d 10 f0       	push   $0xf0103d84
f0100920:	68 f1 02 00 00       	push   $0x2f1
f0100925:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010092a:	e8 5c f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010092f:	c1 ea 0c             	shr    $0xc,%edx
f0100932:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100938:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010093f:	89 c2                	mov    %eax,%edx
f0100941:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100944:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100949:	85 d2                	test   %edx,%edx
f010094b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100950:	0f 44 c2             	cmove  %edx,%eax
f0100953:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100954:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100959:	c3                   	ret    

f010095a <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010095a:	55                   	push   %ebp
f010095b:	89 e5                	mov    %esp,%ebp
f010095d:	57                   	push   %edi
f010095e:	56                   	push   %esi
f010095f:	53                   	push   %ebx
f0100960:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100963:	84 c0                	test   %al,%al
f0100965:	0f 85 72 02 00 00    	jne    f0100bdd <check_page_free_list+0x283>
f010096b:	e9 7f 02 00 00       	jmp    f0100bef <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100970:	83 ec 04             	sub    $0x4,%esp
f0100973:	68 a8 3d 10 f0       	push   $0xf0103da8
f0100978:	68 34 02 00 00       	push   $0x234
f010097d:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100982:	e8 04 f7 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100987:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010098a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010098d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100990:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100993:	89 c2                	mov    %eax,%edx
f0100995:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010099b:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009a1:	0f 95 c2             	setne  %dl
f01009a4:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009a7:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009ab:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009ad:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009b1:	8b 00                	mov    (%eax),%eax
f01009b3:	85 c0                	test   %eax,%eax
f01009b5:	75 dc                	jne    f0100993 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009ba:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009c3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009c6:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009c8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009cb:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d0:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009d5:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f01009db:	eb 53                	jmp    f0100a30 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009dd:	89 d8                	mov    %ebx,%eax
f01009df:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01009e5:	c1 f8 03             	sar    $0x3,%eax
f01009e8:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009eb:	89 c2                	mov    %eax,%edx
f01009ed:	c1 ea 16             	shr    $0x16,%edx
f01009f0:	39 f2                	cmp    %esi,%edx
f01009f2:	73 3a                	jae    f0100a2e <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009f4:	89 c2                	mov    %eax,%edx
f01009f6:	c1 ea 0c             	shr    $0xc,%edx
f01009f9:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01009ff:	72 12                	jb     f0100a13 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a01:	50                   	push   %eax
f0100a02:	68 84 3d 10 f0       	push   $0xf0103d84
f0100a07:	6a 52                	push   $0x52
f0100a09:	68 98 3a 10 f0       	push   $0xf0103a98
f0100a0e:	e8 78 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a13:	83 ec 04             	sub    $0x4,%esp
f0100a16:	68 80 00 00 00       	push   $0x80
f0100a1b:	68 97 00 00 00       	push   $0x97
f0100a20:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a25:	50                   	push   %eax
f0100a26:	e8 06 27 00 00       	call   f0103131 <memset>
f0100a2b:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a2e:	8b 1b                	mov    (%ebx),%ebx
f0100a30:	85 db                	test   %ebx,%ebx
f0100a32:	75 a9                	jne    f01009dd <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a34:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a39:	e8 4f fe ff ff       	call   f010088d <boot_alloc>
f0100a3e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a41:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a47:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
		assert(pp < pages + npages);
f0100a4d:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100a52:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a55:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a58:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a5b:	be 00 00 00 00       	mov    $0x0,%esi
f0100a60:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a63:	e9 30 01 00 00       	jmp    f0100b98 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a68:	39 ca                	cmp    %ecx,%edx
f0100a6a:	73 19                	jae    f0100a85 <check_page_free_list+0x12b>
f0100a6c:	68 a6 3a 10 f0       	push   $0xf0103aa6
f0100a71:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100a76:	68 4e 02 00 00       	push   $0x24e
f0100a7b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100a80:	e8 06 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a85:	39 fa                	cmp    %edi,%edx
f0100a87:	72 19                	jb     f0100aa2 <check_page_free_list+0x148>
f0100a89:	68 c7 3a 10 f0       	push   $0xf0103ac7
f0100a8e:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100a93:	68 4f 02 00 00       	push   $0x24f
f0100a98:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100a9d:	e8 e9 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa2:	89 d0                	mov    %edx,%eax
f0100aa4:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aa7:	a8 07                	test   $0x7,%al
f0100aa9:	74 19                	je     f0100ac4 <check_page_free_list+0x16a>
f0100aab:	68 cc 3d 10 f0       	push   $0xf0103dcc
f0100ab0:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100ab5:	68 50 02 00 00       	push   $0x250
f0100aba:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100abf:	e8 c7 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ac4:	c1 f8 03             	sar    $0x3,%eax
f0100ac7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100aca:	85 c0                	test   %eax,%eax
f0100acc:	75 19                	jne    f0100ae7 <check_page_free_list+0x18d>
f0100ace:	68 db 3a 10 f0       	push   $0xf0103adb
f0100ad3:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100ad8:	68 53 02 00 00       	push   $0x253
f0100add:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100ae2:	e8 a4 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ae7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100aec:	75 19                	jne    f0100b07 <check_page_free_list+0x1ad>
f0100aee:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100af3:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100af8:	68 54 02 00 00       	push   $0x254
f0100afd:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100b02:	e8 84 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b07:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b0c:	75 19                	jne    f0100b27 <check_page_free_list+0x1cd>
f0100b0e:	68 00 3e 10 f0       	push   $0xf0103e00
f0100b13:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100b18:	68 55 02 00 00       	push   $0x255
f0100b1d:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100b22:	e8 64 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b27:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b2c:	75 19                	jne    f0100b47 <check_page_free_list+0x1ed>
f0100b2e:	68 05 3b 10 f0       	push   $0xf0103b05
f0100b33:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100b38:	68 56 02 00 00       	push   $0x256
f0100b3d:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100b42:	e8 44 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b47:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b4c:	76 3f                	jbe    f0100b8d <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b4e:	89 c3                	mov    %eax,%ebx
f0100b50:	c1 eb 0c             	shr    $0xc,%ebx
f0100b53:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b56:	77 12                	ja     f0100b6a <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b58:	50                   	push   %eax
f0100b59:	68 84 3d 10 f0       	push   $0xf0103d84
f0100b5e:	6a 52                	push   $0x52
f0100b60:	68 98 3a 10 f0       	push   $0xf0103a98
f0100b65:	e8 21 f5 ff ff       	call   f010008b <_panic>
f0100b6a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b72:	76 1e                	jbe    f0100b92 <check_page_free_list+0x238>
f0100b74:	68 24 3e 10 f0       	push   $0xf0103e24
f0100b79:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100b7e:	68 57 02 00 00       	push   $0x257
f0100b83:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100b88:	e8 fe f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b8d:	83 c6 01             	add    $0x1,%esi
f0100b90:	eb 04                	jmp    f0100b96 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b92:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b96:	8b 12                	mov    (%edx),%edx
f0100b98:	85 d2                	test   %edx,%edx
f0100b9a:	0f 85 c8 fe ff ff    	jne    f0100a68 <check_page_free_list+0x10e>
f0100ba0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100ba3:	85 f6                	test   %esi,%esi
f0100ba5:	7f 19                	jg     f0100bc0 <check_page_free_list+0x266>
f0100ba7:	68 1f 3b 10 f0       	push   $0xf0103b1f
f0100bac:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100bb1:	68 5f 02 00 00       	push   $0x25f
f0100bb6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100bbb:	e8 cb f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100bc0:	85 db                	test   %ebx,%ebx
f0100bc2:	7f 42                	jg     f0100c06 <check_page_free_list+0x2ac>
f0100bc4:	68 31 3b 10 f0       	push   $0xf0103b31
f0100bc9:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0100bce:	68 60 02 00 00       	push   $0x260
f0100bd3:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100bd8:	e8 ae f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bdd:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100be2:	85 c0                	test   %eax,%eax
f0100be4:	0f 85 9d fd ff ff    	jne    f0100987 <check_page_free_list+0x2d>
f0100bea:	e9 81 fd ff ff       	jmp    f0100970 <check_page_free_list+0x16>
f0100bef:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100bf6:	0f 84 74 fd ff ff    	je     f0100970 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bfc:	be 00 04 00 00       	mov    $0x400,%esi
f0100c01:	e9 cf fd ff ff       	jmp    f01009d5 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c06:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c09:	5b                   	pop    %ebx
f0100c0a:	5e                   	pop    %esi
f0100c0b:	5f                   	pop    %edi
f0100c0c:	5d                   	pop    %ebp
f0100c0d:	c3                   	ret    

f0100c0e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c0e:	55                   	push   %ebp
f0100c0f:	89 e5                	mov    %esp,%ebp
f0100c11:	53                   	push   %ebx
f0100c12:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c15:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c1a:	eb 4d                	jmp    f0100c69 <page_init+0x5b>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE)))
f0100c1c:	85 db                	test   %ebx,%ebx
f0100c1e:	74 46                	je     f0100c66 <page_init+0x58>
f0100c20:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100c26:	76 16                	jbe    f0100c3e <page_init+0x30>
f0100c28:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c2d:	e8 5b fc ff ff       	call   f010088d <boot_alloc>
f0100c32:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c37:	c1 e8 0c             	shr    $0xc,%eax
f0100c3a:	39 c3                	cmp    %eax,%ebx
f0100c3c:	76 28                	jbe    f0100c66 <page_init+0x58>
f0100c3e:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100c45:	89 c2                	mov    %eax,%edx
f0100c47:	03 15 4c 69 11 f0    	add    0xf011694c,%edx
f0100c4d:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100c53:	8b 0d 3c 65 11 f0    	mov    0xf011653c,%ecx
f0100c59:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100c5b:	03 05 4c 69 11 f0    	add    0xf011694c,%eax
f0100c61:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c66:	83 c3 01             	add    $0x1,%ebx
f0100c69:	3b 1d 44 69 11 f0    	cmp    0xf0116944,%ebx
f0100c6f:	72 ab                	jb     f0100c1c <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100c71:	83 c4 04             	add    $0x4,%esp
f0100c74:	5b                   	pop    %ebx
f0100c75:	5d                   	pop    %ebp
f0100c76:	c3                   	ret    

f0100c77 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100c77:	55                   	push   %ebp
f0100c78:	89 e5                	mov    %esp,%ebp
f0100c7a:	53                   	push   %ebx
f0100c7b:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0100c7e:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100c84:	85 db                	test   %ebx,%ebx
f0100c86:	74 58                	je     f0100ce0 <page_alloc+0x69>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0100c88:	8b 03                	mov    (%ebx),%eax
f0100c8a:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
  	tempage->pp_link = NULL;
f0100c8f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
f0100c95:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c99:	74 45                	je     f0100ce0 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c9b:	89 d8                	mov    %ebx,%eax
f0100c9d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100ca3:	c1 f8 03             	sar    $0x3,%eax
f0100ca6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ca9:	89 c2                	mov    %eax,%edx
f0100cab:	c1 ea 0c             	shr    $0xc,%edx
f0100cae:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100cb4:	72 12                	jb     f0100cc8 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb6:	50                   	push   %eax
f0100cb7:	68 84 3d 10 f0       	push   $0xf0103d84
f0100cbc:	6a 52                	push   $0x52
f0100cbe:	68 98 3a 10 f0       	push   $0xf0103a98
f0100cc3:	e8 c3 f3 ff ff       	call   f010008b <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f0100cc8:	83 ec 04             	sub    $0x4,%esp
f0100ccb:	68 00 10 00 00       	push   $0x1000
f0100cd0:	6a 00                	push   $0x0
f0100cd2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd7:	50                   	push   %eax
f0100cd8:	e8 54 24 00 00       	call   f0103131 <memset>
f0100cdd:	83 c4 10             	add    $0x10,%esp

  	return tempage;
	

}
f0100ce0:	89 d8                	mov    %ebx,%eax
f0100ce2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ce5:	c9                   	leave  
f0100ce6:	c3                   	ret    

f0100ce7 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ce7:	55                   	push   %ebp
f0100ce8:	89 e5                	mov    %esp,%ebp
f0100cea:	83 ec 08             	sub    $0x8,%esp
f0100ced:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100cf0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100cf5:	75 0f                	jne    f0100d06 <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100cf7:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100cfd:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100cff:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	}
	else
	panic("page ref not zero \n");
}
f0100d04:	eb 17                	jmp    f0100d1d <page_free+0x36>
	{
	pp->pp_link=page_free_list;
	page_free_list=pp;	
	}
	else
	panic("page ref not zero \n");
f0100d06:	83 ec 04             	sub    $0x4,%esp
f0100d09:	68 42 3b 10 f0       	push   $0xf0103b42
f0100d0e:	68 57 01 00 00       	push   $0x157
f0100d13:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100d18:	e8 6e f3 ff ff       	call   f010008b <_panic>
}
f0100d1d:	c9                   	leave  
f0100d1e:	c3                   	ret    

f0100d1f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d1f:	55                   	push   %ebp
f0100d20:	89 e5                	mov    %esp,%ebp
f0100d22:	83 ec 08             	sub    $0x8,%esp
f0100d25:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d28:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d2c:	83 e8 01             	sub    $0x1,%eax
f0100d2f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d33:	66 85 c0             	test   %ax,%ax
f0100d36:	75 0c                	jne    f0100d44 <page_decref+0x25>
		page_free(pp);
f0100d38:	83 ec 0c             	sub    $0xc,%esp
f0100d3b:	52                   	push   %edx
f0100d3c:	e8 a6 ff ff ff       	call   f0100ce7 <page_free>
f0100d41:	83 c4 10             	add    $0x10,%esp
}
f0100d44:	c9                   	leave  
f0100d45:	c3                   	ret    

f0100d46 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d46:	55                   	push   %ebp
f0100d47:	89 e5                	mov    %esp,%ebp
f0100d49:	57                   	push   %edi
f0100d4a:	56                   	push   %esi
f0100d4b:	53                   	push   %ebx
f0100d4c:	83 ec 0c             	sub    $0xc,%esp
f0100d4f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0100d52:	89 de                	mov    %ebx,%esi
f0100d54:	c1 ee 16             	shr    $0x16,%esi
f0100d57:	c1 e6 02             	shl    $0x2,%esi
f0100d5a:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0100d5d:	8b 06                	mov    (%esi),%eax
f0100d5f:	a8 01                	test   $0x1,%al
f0100d61:	74 2f                	je     f0100d92 <pgdir_walk+0x4c>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f0100d63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d68:	89 c2                	mov    %eax,%edx
f0100d6a:	c1 ea 0c             	shr    $0xc,%edx
f0100d6d:	39 15 44 69 11 f0    	cmp    %edx,0xf0116944
f0100d73:	77 15                	ja     f0100d8a <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d75:	50                   	push   %eax
f0100d76:	68 84 3d 10 f0       	push   $0xf0103d84
f0100d7b:	68 84 01 00 00       	push   $0x184
f0100d80:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100d85:	e8 01 f3 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100d8a:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100d90:	eb 77                	jmp    f0100e09 <pgdir_walk+0xc3>
	  } else {
		//page table page not exist
		if(!create || 
f0100d92:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d96:	74 7f                	je     f0100e17 <pgdir_walk+0xd1>
f0100d98:	83 ec 0c             	sub    $0xc,%esp
f0100d9b:	6a 01                	push   $0x1
f0100d9d:	e8 d5 fe ff ff       	call   f0100c77 <page_alloc>
f0100da2:	83 c4 10             	add    $0x10,%esp
f0100da5:	85 c0                	test   %eax,%eax
f0100da7:	74 75                	je     f0100e1e <pgdir_walk+0xd8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da9:	89 c1                	mov    %eax,%ecx
f0100dab:	2b 0d 4c 69 11 f0    	sub    0xf011694c,%ecx
f0100db1:	c1 f9 03             	sar    $0x3,%ecx
f0100db4:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db7:	89 ca                	mov    %ecx,%edx
f0100db9:	c1 ea 0c             	shr    $0xc,%edx
f0100dbc:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100dc2:	72 12                	jb     f0100dd6 <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc4:	51                   	push   %ecx
f0100dc5:	68 84 3d 10 f0       	push   $0xf0103d84
f0100dca:	6a 52                	push   $0x52
f0100dcc:	68 98 3a 10 f0       	push   $0xf0103a98
f0100dd1:	e8 b5 f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100dd6:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100ddc:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0100dde:	85 ff                	test   %edi,%edi
f0100de0:	74 43                	je     f0100e25 <pgdir_walk+0xdf>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f0100de2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100de7:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100ded:	77 15                	ja     f0100e04 <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100def:	57                   	push   %edi
f0100df0:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0100df5:	68 8d 01 00 00       	push   $0x18d
f0100dfa:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100dff:	e8 87 f2 ff ff       	call   f010008b <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0100e04:	83 c9 07             	or     $0x7,%ecx
f0100e07:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f0100e09:	c1 eb 0a             	shr    $0xa,%ebx
f0100e0c:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100e12:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100e15:	eb 13                	jmp    f0100e2a <pgdir_walk+0xe4>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f0100e17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e1c:	eb 0c                	jmp    f0100e2a <pgdir_walk+0xe4>
f0100e1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e23:	eb 05                	jmp    f0100e2a <pgdir_walk+0xe4>
f0100e25:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f0100e2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e2d:	5b                   	pop    %ebx
f0100e2e:	5e                   	pop    %esi
f0100e2f:	5f                   	pop    %edi
f0100e30:	5d                   	pop    %ebp
f0100e31:	c3                   	ret    

f0100e32 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e32:	55                   	push   %ebp
f0100e33:	89 e5                	mov    %esp,%ebp
f0100e35:	57                   	push   %edi
f0100e36:	56                   	push   %esi
f0100e37:	53                   	push   %ebx
f0100e38:	83 ec 1c             	sub    $0x1c,%esp
f0100e3b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0100e3e:	c1 e9 0c             	shr    $0xc,%ecx
f0100e41:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f0100e44:	89 d6                	mov    %edx,%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f0100e46:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e4e:	29 d0                	sub    %edx,%eax
f0100e50:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0100e53:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e56:	83 c8 01             	or     $0x1,%eax
f0100e59:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0100e5c:	eb 25                	jmp    f0100e83 <boot_map_region+0x51>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f0100e5e:	83 ec 04             	sub    $0x4,%esp
f0100e61:	6a 01                	push   $0x1
f0100e63:	56                   	push   %esi
f0100e64:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e67:	e8 da fe ff ff       	call   f0100d46 <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0100e6c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100e72:	0b 5d d8             	or     -0x28(%ebp),%ebx
f0100e75:	89 18                	mov    %ebx,(%eax)
		va+=PGSIZE;
f0100e77:	81 c6 00 10 00 00    	add    $0x1000,%esi
		pa+=PGSIZE;
		i++;
f0100e7d:	83 c7 01             	add    $0x1,%edi
f0100e80:	83 c4 10             	add    $0x10,%esp
f0100e83:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e86:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0100e89:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100e8c:	75 d0                	jne    f0100e5e <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f0100e8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e91:	5b                   	pop    %ebx
f0100e92:	5e                   	pop    %esi
f0100e93:	5f                   	pop    %edi
f0100e94:	5d                   	pop    %ebp
f0100e95:	c3                   	ret    

f0100e96 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	83 ec 0c             	sub    $0xc,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f0100e9c:	6a 00                	push   $0x0
f0100e9e:	ff 75 0c             	pushl  0xc(%ebp)
f0100ea1:	ff 75 08             	pushl  0x8(%ebp)
f0100ea4:	e8 9d fe ff ff       	call   f0100d46 <pgdir_walk>
	
	if(pt == NULL)
f0100ea9:	83 c4 10             	add    $0x10,%esp
f0100eac:	85 c0                	test   %eax,%eax
f0100eae:	74 31                	je     f0100ee1 <page_lookup+0x4b>
	return NULL;
	
	*pte_store = pt;
f0100eb0:	8b 55 10             	mov    0x10(%ebp),%edx
f0100eb3:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb5:	8b 00                	mov    (%eax),%eax
f0100eb7:	c1 e8 0c             	shr    $0xc,%eax
f0100eba:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100ec0:	72 14                	jb     f0100ed6 <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0100ec2:	83 ec 04             	sub    $0x4,%esp
f0100ec5:	68 90 3e 10 f0       	push   $0xf0103e90
f0100eca:	6a 4b                	push   $0x4b
f0100ecc:	68 98 3a 10 f0       	push   $0xf0103a98
f0100ed1:	e8 b5 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100ed6:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100edc:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	
  return pa2page(PTE_ADDR(*pt));	
f0100edf:	eb 05                	jmp    f0100ee6 <page_lookup+0x50>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f0100ee1:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0100ee6:	c9                   	leave  
f0100ee7:	c3                   	ret    

f0100ee8 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ee8:	55                   	push   %ebp
f0100ee9:	89 e5                	mov    %esp,%ebp
f0100eeb:	53                   	push   %ebx
f0100eec:	83 ec 18             	sub    $0x18,%esp
f0100eef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f0100ef2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f0100ef9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100efc:	50                   	push   %eax
f0100efd:	53                   	push   %ebx
f0100efe:	ff 75 08             	pushl  0x8(%ebp)
f0100f01:	e8 90 ff ff ff       	call   f0100e96 <page_lookup>
f0100f06:	83 c4 10             	add    $0x10,%esp
f0100f09:	85 c0                	test   %eax,%eax
f0100f0b:	74 0f                	je     f0100f1c <page_remove+0x34>
		page_decref(page);
f0100f0d:	83 ec 0c             	sub    $0xc,%esp
f0100f10:	50                   	push   %eax
f0100f11:	e8 09 fe ff ff       	call   f0100d1f <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f16:	0f 01 3b             	invlpg (%ebx)
f0100f19:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
	*pt=0;
f0100f1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f1f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0100f25:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f28:	c9                   	leave  
f0100f29:	c3                   	ret    

f0100f2a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f2a:	55                   	push   %ebp
f0100f2b:	89 e5                	mov    %esp,%ebp
f0100f2d:	57                   	push   %edi
f0100f2e:	56                   	push   %esi
f0100f2f:	53                   	push   %ebx
f0100f30:	83 ec 10             	sub    $0x10,%esp
f0100f33:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f36:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f0100f39:	6a 01                	push   $0x1
f0100f3b:	57                   	push   %edi
f0100f3c:	ff 75 08             	pushl  0x8(%ebp)
f0100f3f:	e8 02 fe ff ff       	call   f0100d46 <pgdir_walk>
 

    if (pte != NULL) {
f0100f44:	83 c4 10             	add    $0x10,%esp
f0100f47:	85 c0                	test   %eax,%eax
f0100f49:	74 4a                	je     f0100f95 <page_insert+0x6b>
f0100f4b:	89 c3                	mov    %eax,%ebx
     
        if (*pte & PTE_P)
f0100f4d:	f6 00 01             	testb  $0x1,(%eax)
f0100f50:	74 0f                	je     f0100f61 <page_insert+0x37>
            page_remove(pgdir, va);
f0100f52:	83 ec 08             	sub    $0x8,%esp
f0100f55:	57                   	push   %edi
f0100f56:	ff 75 08             	pushl  0x8(%ebp)
f0100f59:	e8 8a ff ff ff       	call   f0100ee8 <page_remove>
f0100f5e:	83 c4 10             	add    $0x10,%esp
   
       if (page_free_list == pp)
f0100f61:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100f66:	39 f0                	cmp    %esi,%eax
f0100f68:	75 07                	jne    f0100f71 <page_insert+0x47>
            page_free_list = page_free_list->pp_link;
f0100f6a:	8b 00                	mov    (%eax),%eax
f0100f6c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
    else {
     //   pte = pgdir_walk(pgdir, va, 1);
       // if (!pte)
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f0100f71:	89 f0                	mov    %esi,%eax
f0100f73:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100f79:	c1 f8 03             	sar    $0x3,%eax
f0100f7c:	c1 e0 0c             	shl    $0xc,%eax
f0100f7f:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f82:	83 ca 01             	or     $0x1,%edx
f0100f85:	09 d0                	or     %edx,%eax
f0100f87:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f0100f89:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

return 0;
f0100f8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f93:	eb 05                	jmp    f0100f9a <page_insert+0x70>
            page_free_list = page_free_list->pp_link;
    }
    else {
     //   pte = pgdir_walk(pgdir, va, 1);
       // if (!pte)
            return -E_NO_MEM;
f0100f95:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f0100f9a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9d:	5b                   	pop    %ebx
f0100f9e:	5e                   	pop    %esi
f0100f9f:	5f                   	pop    %edi
f0100fa0:	5d                   	pop    %ebp
f0100fa1:	c3                   	ret    

f0100fa2 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fa2:	55                   	push   %ebp
f0100fa3:	89 e5                	mov    %esp,%ebp
f0100fa5:	57                   	push   %edi
f0100fa6:	56                   	push   %esi
f0100fa7:	53                   	push   %ebx
f0100fa8:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100fab:	b8 15 00 00 00       	mov    $0x15,%eax
f0100fb0:	e8 af f8 ff ff       	call   f0100864 <nvram_read>
f0100fb5:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100fb7:	b8 17 00 00 00       	mov    $0x17,%eax
f0100fbc:	e8 a3 f8 ff ff       	call   f0100864 <nvram_read>
f0100fc1:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100fc3:	b8 34 00 00 00       	mov    $0x34,%eax
f0100fc8:	e8 97 f8 ff ff       	call   f0100864 <nvram_read>
f0100fcd:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	74 07                	je     f0100fdb <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100fd4:	05 00 40 00 00       	add    $0x4000,%eax
f0100fd9:	eb 0b                	jmp    f0100fe6 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100fdb:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100fe1:	85 f6                	test   %esi,%esi
f0100fe3:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100fe6:	89 c2                	mov    %eax,%edx
f0100fe8:	c1 ea 02             	shr    $0x2,%edx
f0100feb:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ff1:	89 c2                	mov    %eax,%edx
f0100ff3:	29 da                	sub    %ebx,%edx
f0100ff5:	52                   	push   %edx
f0100ff6:	53                   	push   %ebx
f0100ff7:	50                   	push   %eax
f0100ff8:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0100ffd:	e8 46 16 00 00       	call   f0102648 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101002:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101007:	e8 81 f8 ff ff       	call   f010088d <boot_alloc>
f010100c:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0101011:	83 c4 0c             	add    $0xc,%esp
f0101014:	68 00 10 00 00       	push   $0x1000
f0101019:	6a 00                	push   $0x0
f010101b:	50                   	push   %eax
f010101c:	e8 10 21 00 00       	call   f0103131 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101021:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101026:	83 c4 10             	add    $0x10,%esp
f0101029:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010102e:	77 15                	ja     f0101045 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101030:	50                   	push   %eax
f0101031:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0101036:	68 a0 00 00 00       	push   $0xa0
f010103b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101040:	e8 46 f0 ff ff       	call   f010008b <_panic>
f0101045:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010104b:	83 ca 05             	or     $0x5,%edx
f010104e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(sizeof(struct PageInfo)*npages);
f0101054:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101059:	c1 e0 03             	shl    $0x3,%eax
f010105c:	e8 2c f8 ff ff       	call   f010088d <boot_alloc>
f0101061:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
	memset(pages,0,sizeof(struct PageInfo)*npages);
f0101066:	83 ec 04             	sub    $0x4,%esp
f0101069:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f010106f:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101076:	52                   	push   %edx
f0101077:	6a 00                	push   $0x0
f0101079:	50                   	push   %eax
f010107a:	e8 b2 20 00 00       	call   f0103131 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010107f:	e8 8a fb ff ff       	call   f0100c0e <page_init>

	check_page_free_list(1);
f0101084:	b8 01 00 00 00       	mov    $0x1,%eax
f0101089:	e8 cc f8 ff ff       	call   f010095a <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010108e:	83 c4 10             	add    $0x10,%esp
f0101091:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f0101098:	75 17                	jne    f01010b1 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f010109a:	83 ec 04             	sub    $0x4,%esp
f010109d:	68 56 3b 10 f0       	push   $0xf0103b56
f01010a2:	68 71 02 00 00       	push   $0x271
f01010a7:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01010ac:	e8 da ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010b1:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01010b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010bb:	eb 05                	jmp    f01010c2 <mem_init+0x120>
		++nfree;
f01010bd:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010c0:	8b 00                	mov    (%eax),%eax
f01010c2:	85 c0                	test   %eax,%eax
f01010c4:	75 f7                	jne    f01010bd <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010c6:	83 ec 0c             	sub    $0xc,%esp
f01010c9:	6a 00                	push   $0x0
f01010cb:	e8 a7 fb ff ff       	call   f0100c77 <page_alloc>
f01010d0:	89 c7                	mov    %eax,%edi
f01010d2:	83 c4 10             	add    $0x10,%esp
f01010d5:	85 c0                	test   %eax,%eax
f01010d7:	75 19                	jne    f01010f2 <mem_init+0x150>
f01010d9:	68 71 3b 10 f0       	push   $0xf0103b71
f01010de:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01010e3:	68 79 02 00 00       	push   $0x279
f01010e8:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01010ed:	e8 99 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01010f2:	83 ec 0c             	sub    $0xc,%esp
f01010f5:	6a 00                	push   $0x0
f01010f7:	e8 7b fb ff ff       	call   f0100c77 <page_alloc>
f01010fc:	89 c6                	mov    %eax,%esi
f01010fe:	83 c4 10             	add    $0x10,%esp
f0101101:	85 c0                	test   %eax,%eax
f0101103:	75 19                	jne    f010111e <mem_init+0x17c>
f0101105:	68 87 3b 10 f0       	push   $0xf0103b87
f010110a:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010110f:	68 7a 02 00 00       	push   $0x27a
f0101114:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101119:	e8 6d ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010111e:	83 ec 0c             	sub    $0xc,%esp
f0101121:	6a 00                	push   $0x0
f0101123:	e8 4f fb ff ff       	call   f0100c77 <page_alloc>
f0101128:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010112b:	83 c4 10             	add    $0x10,%esp
f010112e:	85 c0                	test   %eax,%eax
f0101130:	75 19                	jne    f010114b <mem_init+0x1a9>
f0101132:	68 9d 3b 10 f0       	push   $0xf0103b9d
f0101137:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010113c:	68 7b 02 00 00       	push   $0x27b
f0101141:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101146:	e8 40 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010114b:	39 f7                	cmp    %esi,%edi
f010114d:	75 19                	jne    f0101168 <mem_init+0x1c6>
f010114f:	68 b3 3b 10 f0       	push   $0xf0103bb3
f0101154:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101159:	68 7e 02 00 00       	push   $0x27e
f010115e:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101163:	e8 23 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101168:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010116b:	39 c6                	cmp    %eax,%esi
f010116d:	74 04                	je     f0101173 <mem_init+0x1d1>
f010116f:	39 c7                	cmp    %eax,%edi
f0101171:	75 19                	jne    f010118c <mem_init+0x1ea>
f0101173:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101178:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010117d:	68 7f 02 00 00       	push   $0x27f
f0101182:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101187:	e8 ff ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010118c:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101192:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f0101198:	c1 e2 0c             	shl    $0xc,%edx
f010119b:	89 f8                	mov    %edi,%eax
f010119d:	29 c8                	sub    %ecx,%eax
f010119f:	c1 f8 03             	sar    $0x3,%eax
f01011a2:	c1 e0 0c             	shl    $0xc,%eax
f01011a5:	39 d0                	cmp    %edx,%eax
f01011a7:	72 19                	jb     f01011c2 <mem_init+0x220>
f01011a9:	68 c5 3b 10 f0       	push   $0xf0103bc5
f01011ae:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01011b3:	68 80 02 00 00       	push   $0x280
f01011b8:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01011bd:	e8 c9 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011c2:	89 f0                	mov    %esi,%eax
f01011c4:	29 c8                	sub    %ecx,%eax
f01011c6:	c1 f8 03             	sar    $0x3,%eax
f01011c9:	c1 e0 0c             	shl    $0xc,%eax
f01011cc:	39 c2                	cmp    %eax,%edx
f01011ce:	77 19                	ja     f01011e9 <mem_init+0x247>
f01011d0:	68 e2 3b 10 f0       	push   $0xf0103be2
f01011d5:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01011da:	68 81 02 00 00       	push   $0x281
f01011df:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01011e4:	e8 a2 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01011e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011ec:	29 c8                	sub    %ecx,%eax
f01011ee:	c1 f8 03             	sar    $0x3,%eax
f01011f1:	c1 e0 0c             	shl    $0xc,%eax
f01011f4:	39 c2                	cmp    %eax,%edx
f01011f6:	77 19                	ja     f0101211 <mem_init+0x26f>
f01011f8:	68 ff 3b 10 f0       	push   $0xf0103bff
f01011fd:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101202:	68 82 02 00 00       	push   $0x282
f0101207:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010120c:	e8 7a ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101211:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101216:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101219:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101220:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101223:	83 ec 0c             	sub    $0xc,%esp
f0101226:	6a 00                	push   $0x0
f0101228:	e8 4a fa ff ff       	call   f0100c77 <page_alloc>
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	85 c0                	test   %eax,%eax
f0101232:	74 19                	je     f010124d <mem_init+0x2ab>
f0101234:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101239:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010123e:	68 89 02 00 00       	push   $0x289
f0101243:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101248:	e8 3e ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010124d:	83 ec 0c             	sub    $0xc,%esp
f0101250:	57                   	push   %edi
f0101251:	e8 91 fa ff ff       	call   f0100ce7 <page_free>
	page_free(pp1);
f0101256:	89 34 24             	mov    %esi,(%esp)
f0101259:	e8 89 fa ff ff       	call   f0100ce7 <page_free>
	page_free(pp2);
f010125e:	83 c4 04             	add    $0x4,%esp
f0101261:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101264:	e8 7e fa ff ff       	call   f0100ce7 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101269:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101270:	e8 02 fa ff ff       	call   f0100c77 <page_alloc>
f0101275:	89 c6                	mov    %eax,%esi
f0101277:	83 c4 10             	add    $0x10,%esp
f010127a:	85 c0                	test   %eax,%eax
f010127c:	75 19                	jne    f0101297 <mem_init+0x2f5>
f010127e:	68 71 3b 10 f0       	push   $0xf0103b71
f0101283:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101288:	68 90 02 00 00       	push   $0x290
f010128d:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101297:	83 ec 0c             	sub    $0xc,%esp
f010129a:	6a 00                	push   $0x0
f010129c:	e8 d6 f9 ff ff       	call   f0100c77 <page_alloc>
f01012a1:	89 c7                	mov    %eax,%edi
f01012a3:	83 c4 10             	add    $0x10,%esp
f01012a6:	85 c0                	test   %eax,%eax
f01012a8:	75 19                	jne    f01012c3 <mem_init+0x321>
f01012aa:	68 87 3b 10 f0       	push   $0xf0103b87
f01012af:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01012b4:	68 91 02 00 00       	push   $0x291
f01012b9:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01012be:	e8 c8 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01012c3:	83 ec 0c             	sub    $0xc,%esp
f01012c6:	6a 00                	push   $0x0
f01012c8:	e8 aa f9 ff ff       	call   f0100c77 <page_alloc>
f01012cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012d0:	83 c4 10             	add    $0x10,%esp
f01012d3:	85 c0                	test   %eax,%eax
f01012d5:	75 19                	jne    f01012f0 <mem_init+0x34e>
f01012d7:	68 9d 3b 10 f0       	push   $0xf0103b9d
f01012dc:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01012e1:	68 92 02 00 00       	push   $0x292
f01012e6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01012eb:	e8 9b ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012f0:	39 fe                	cmp    %edi,%esi
f01012f2:	75 19                	jne    f010130d <mem_init+0x36b>
f01012f4:	68 b3 3b 10 f0       	push   $0xf0103bb3
f01012f9:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01012fe:	68 94 02 00 00       	push   $0x294
f0101303:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101308:	e8 7e ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010130d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101310:	39 c6                	cmp    %eax,%esi
f0101312:	74 04                	je     f0101318 <mem_init+0x376>
f0101314:	39 c7                	cmp    %eax,%edi
f0101316:	75 19                	jne    f0101331 <mem_init+0x38f>
f0101318:	68 ec 3e 10 f0       	push   $0xf0103eec
f010131d:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101322:	68 95 02 00 00       	push   $0x295
f0101327:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010132c:	e8 5a ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101331:	83 ec 0c             	sub    $0xc,%esp
f0101334:	6a 00                	push   $0x0
f0101336:	e8 3c f9 ff ff       	call   f0100c77 <page_alloc>
f010133b:	83 c4 10             	add    $0x10,%esp
f010133e:	85 c0                	test   %eax,%eax
f0101340:	74 19                	je     f010135b <mem_init+0x3b9>
f0101342:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101347:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010134c:	68 96 02 00 00       	push   $0x296
f0101351:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101356:	e8 30 ed ff ff       	call   f010008b <_panic>
f010135b:	89 f0                	mov    %esi,%eax
f010135d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101363:	c1 f8 03             	sar    $0x3,%eax
f0101366:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101369:	89 c2                	mov    %eax,%edx
f010136b:	c1 ea 0c             	shr    $0xc,%edx
f010136e:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101374:	72 12                	jb     f0101388 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101376:	50                   	push   %eax
f0101377:	68 84 3d 10 f0       	push   $0xf0103d84
f010137c:	6a 52                	push   $0x52
f010137e:	68 98 3a 10 f0       	push   $0xf0103a98
f0101383:	e8 03 ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101388:	83 ec 04             	sub    $0x4,%esp
f010138b:	68 00 10 00 00       	push   $0x1000
f0101390:	6a 01                	push   $0x1
f0101392:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101397:	50                   	push   %eax
f0101398:	e8 94 1d 00 00       	call   f0103131 <memset>
	page_free(pp0);
f010139d:	89 34 24             	mov    %esi,(%esp)
f01013a0:	e8 42 f9 ff ff       	call   f0100ce7 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013ac:	e8 c6 f8 ff ff       	call   f0100c77 <page_alloc>
f01013b1:	83 c4 10             	add    $0x10,%esp
f01013b4:	85 c0                	test   %eax,%eax
f01013b6:	75 19                	jne    f01013d1 <mem_init+0x42f>
f01013b8:	68 2b 3c 10 f0       	push   $0xf0103c2b
f01013bd:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01013c2:	68 9b 02 00 00       	push   $0x29b
f01013c7:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01013cc:	e8 ba ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01013d1:	39 c6                	cmp    %eax,%esi
f01013d3:	74 19                	je     f01013ee <mem_init+0x44c>
f01013d5:	68 49 3c 10 f0       	push   $0xf0103c49
f01013da:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01013df:	68 9c 02 00 00       	push   $0x29c
f01013e4:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01013e9:	e8 9d ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013ee:	89 f0                	mov    %esi,%eax
f01013f0:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01013f6:	c1 f8 03             	sar    $0x3,%eax
f01013f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013fc:	89 c2                	mov    %eax,%edx
f01013fe:	c1 ea 0c             	shr    $0xc,%edx
f0101401:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101407:	72 12                	jb     f010141b <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101409:	50                   	push   %eax
f010140a:	68 84 3d 10 f0       	push   $0xf0103d84
f010140f:	6a 52                	push   $0x52
f0101411:	68 98 3a 10 f0       	push   $0xf0103a98
f0101416:	e8 70 ec ff ff       	call   f010008b <_panic>
f010141b:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101421:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101427:	80 38 00             	cmpb   $0x0,(%eax)
f010142a:	74 19                	je     f0101445 <mem_init+0x4a3>
f010142c:	68 59 3c 10 f0       	push   $0xf0103c59
f0101431:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101436:	68 9f 02 00 00       	push   $0x29f
f010143b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101440:	e8 46 ec ff ff       	call   f010008b <_panic>
f0101445:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101448:	39 d0                	cmp    %edx,%eax
f010144a:	75 db                	jne    f0101427 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010144c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010144f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101454:	83 ec 0c             	sub    $0xc,%esp
f0101457:	56                   	push   %esi
f0101458:	e8 8a f8 ff ff       	call   f0100ce7 <page_free>
	page_free(pp1);
f010145d:	89 3c 24             	mov    %edi,(%esp)
f0101460:	e8 82 f8 ff ff       	call   f0100ce7 <page_free>
	page_free(pp2);
f0101465:	83 c4 04             	add    $0x4,%esp
f0101468:	ff 75 d4             	pushl  -0x2c(%ebp)
f010146b:	e8 77 f8 ff ff       	call   f0100ce7 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101470:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101475:	83 c4 10             	add    $0x10,%esp
f0101478:	eb 05                	jmp    f010147f <mem_init+0x4dd>
		--nfree;
f010147a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010147d:	8b 00                	mov    (%eax),%eax
f010147f:	85 c0                	test   %eax,%eax
f0101481:	75 f7                	jne    f010147a <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101483:	85 db                	test   %ebx,%ebx
f0101485:	74 19                	je     f01014a0 <mem_init+0x4fe>
f0101487:	68 63 3c 10 f0       	push   $0xf0103c63
f010148c:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101491:	68 ac 02 00 00       	push   $0x2ac
f0101496:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010149b:	e8 eb eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014a0:	83 ec 0c             	sub    $0xc,%esp
f01014a3:	68 0c 3f 10 f0       	push   $0xf0103f0c
f01014a8:	e8 9b 11 00 00       	call   f0102648 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014b4:	e8 be f7 ff ff       	call   f0100c77 <page_alloc>
f01014b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	75 19                	jne    f01014dc <mem_init+0x53a>
f01014c3:	68 71 3b 10 f0       	push   $0xf0103b71
f01014c8:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01014cd:	68 05 03 00 00       	push   $0x305
f01014d2:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01014d7:	e8 af eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014dc:	83 ec 0c             	sub    $0xc,%esp
f01014df:	6a 00                	push   $0x0
f01014e1:	e8 91 f7 ff ff       	call   f0100c77 <page_alloc>
f01014e6:	89 c3                	mov    %eax,%ebx
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	75 19                	jne    f0101508 <mem_init+0x566>
f01014ef:	68 87 3b 10 f0       	push   $0xf0103b87
f01014f4:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01014f9:	68 06 03 00 00       	push   $0x306
f01014fe:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101503:	e8 83 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101508:	83 ec 0c             	sub    $0xc,%esp
f010150b:	6a 00                	push   $0x0
f010150d:	e8 65 f7 ff ff       	call   f0100c77 <page_alloc>
f0101512:	89 c6                	mov    %eax,%esi
f0101514:	83 c4 10             	add    $0x10,%esp
f0101517:	85 c0                	test   %eax,%eax
f0101519:	75 19                	jne    f0101534 <mem_init+0x592>
f010151b:	68 9d 3b 10 f0       	push   $0xf0103b9d
f0101520:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101525:	68 07 03 00 00       	push   $0x307
f010152a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010152f:	e8 57 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101534:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101537:	75 19                	jne    f0101552 <mem_init+0x5b0>
f0101539:	68 b3 3b 10 f0       	push   $0xf0103bb3
f010153e:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101543:	68 0a 03 00 00       	push   $0x30a
f0101548:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010154d:	e8 39 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101552:	39 c3                	cmp    %eax,%ebx
f0101554:	74 05                	je     f010155b <mem_init+0x5b9>
f0101556:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101559:	75 19                	jne    f0101574 <mem_init+0x5d2>
f010155b:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101560:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101565:	68 0b 03 00 00       	push   $0x30b
f010156a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010156f:	e8 17 eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101574:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101579:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010157c:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101583:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	6a 00                	push   $0x0
f010158b:	e8 e7 f6 ff ff       	call   f0100c77 <page_alloc>
f0101590:	83 c4 10             	add    $0x10,%esp
f0101593:	85 c0                	test   %eax,%eax
f0101595:	74 19                	je     f01015b0 <mem_init+0x60e>
f0101597:	68 1c 3c 10 f0       	push   $0xf0103c1c
f010159c:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01015a1:	68 12 03 00 00       	push   $0x312
f01015a6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01015ab:	e8 db ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01015b0:	83 ec 04             	sub    $0x4,%esp
f01015b3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015b6:	50                   	push   %eax
f01015b7:	6a 00                	push   $0x0
f01015b9:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015bf:	e8 d2 f8 ff ff       	call   f0100e96 <page_lookup>
f01015c4:	83 c4 10             	add    $0x10,%esp
f01015c7:	85 c0                	test   %eax,%eax
f01015c9:	74 19                	je     f01015e4 <mem_init+0x642>
f01015cb:	68 2c 3f 10 f0       	push   $0xf0103f2c
f01015d0:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01015d5:	68 15 03 00 00       	push   $0x315
f01015da:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01015df:	e8 a7 ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01015e4:	6a 02                	push   $0x2
f01015e6:	6a 00                	push   $0x0
f01015e8:	53                   	push   %ebx
f01015e9:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015ef:	e8 36 f9 ff ff       	call   f0100f2a <page_insert>
f01015f4:	83 c4 10             	add    $0x10,%esp
f01015f7:	85 c0                	test   %eax,%eax
f01015f9:	78 19                	js     f0101614 <mem_init+0x672>
f01015fb:	68 64 3f 10 f0       	push   $0xf0103f64
f0101600:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101605:	68 18 03 00 00       	push   $0x318
f010160a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010160f:	e8 77 ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101614:	83 ec 0c             	sub    $0xc,%esp
f0101617:	ff 75 d4             	pushl  -0x2c(%ebp)
f010161a:	e8 c8 f6 ff ff       	call   f0100ce7 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010161f:	6a 02                	push   $0x2
f0101621:	6a 00                	push   $0x0
f0101623:	53                   	push   %ebx
f0101624:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010162a:	e8 fb f8 ff ff       	call   f0100f2a <page_insert>
f010162f:	83 c4 20             	add    $0x20,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	74 19                	je     f010164f <mem_init+0x6ad>
f0101636:	68 94 3f 10 f0       	push   $0xf0103f94
f010163b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101640:	68 1c 03 00 00       	push   $0x31c
f0101645:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010164a:	e8 3c ea ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010164f:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101655:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f010165a:	89 c1                	mov    %eax,%ecx
f010165c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010165f:	8b 17                	mov    (%edi),%edx
f0101661:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101667:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010166a:	29 c8                	sub    %ecx,%eax
f010166c:	c1 f8 03             	sar    $0x3,%eax
f010166f:	c1 e0 0c             	shl    $0xc,%eax
f0101672:	39 c2                	cmp    %eax,%edx
f0101674:	74 19                	je     f010168f <mem_init+0x6ed>
f0101676:	68 c4 3f 10 f0       	push   $0xf0103fc4
f010167b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101680:	68 1d 03 00 00       	push   $0x31d
f0101685:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010168a:	e8 fc e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010168f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101694:	89 f8                	mov    %edi,%eax
f0101696:	e8 5b f2 ff ff       	call   f01008f6 <check_va2pa>
f010169b:	89 da                	mov    %ebx,%edx
f010169d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016a0:	c1 fa 03             	sar    $0x3,%edx
f01016a3:	c1 e2 0c             	shl    $0xc,%edx
f01016a6:	39 d0                	cmp    %edx,%eax
f01016a8:	74 19                	je     f01016c3 <mem_init+0x721>
f01016aa:	68 ec 3f 10 f0       	push   $0xf0103fec
f01016af:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01016b4:	68 1e 03 00 00       	push   $0x31e
f01016b9:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01016be:	e8 c8 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01016c3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016c8:	74 19                	je     f01016e3 <mem_init+0x741>
f01016ca:	68 6e 3c 10 f0       	push   $0xf0103c6e
f01016cf:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01016d4:	68 1f 03 00 00       	push   $0x31f
f01016d9:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01016de:	e8 a8 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01016e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016e6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01016eb:	74 19                	je     f0101706 <mem_init+0x764>
f01016ed:	68 7f 3c 10 f0       	push   $0xf0103c7f
f01016f2:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01016f7:	68 20 03 00 00       	push   $0x320
f01016fc:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101701:	e8 85 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101706:	6a 02                	push   $0x2
f0101708:	68 00 10 00 00       	push   $0x1000
f010170d:	56                   	push   %esi
f010170e:	57                   	push   %edi
f010170f:	e8 16 f8 ff ff       	call   f0100f2a <page_insert>
f0101714:	83 c4 10             	add    $0x10,%esp
f0101717:	85 c0                	test   %eax,%eax
f0101719:	74 19                	je     f0101734 <mem_init+0x792>
f010171b:	68 1c 40 10 f0       	push   $0xf010401c
f0101720:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101725:	68 23 03 00 00       	push   $0x323
f010172a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010172f:	e8 57 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101734:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101739:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010173e:	e8 b3 f1 ff ff       	call   f01008f6 <check_va2pa>
f0101743:	89 f2                	mov    %esi,%edx
f0101745:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010174b:	c1 fa 03             	sar    $0x3,%edx
f010174e:	c1 e2 0c             	shl    $0xc,%edx
f0101751:	39 d0                	cmp    %edx,%eax
f0101753:	74 19                	je     f010176e <mem_init+0x7cc>
f0101755:	68 58 40 10 f0       	push   $0xf0104058
f010175a:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010175f:	68 24 03 00 00       	push   $0x324
f0101764:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101769:	e8 1d e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010176e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101773:	74 19                	je     f010178e <mem_init+0x7ec>
f0101775:	68 90 3c 10 f0       	push   $0xf0103c90
f010177a:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010177f:	68 25 03 00 00       	push   $0x325
f0101784:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101789:	e8 fd e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010178e:	83 ec 0c             	sub    $0xc,%esp
f0101791:	6a 00                	push   $0x0
f0101793:	e8 df f4 ff ff       	call   f0100c77 <page_alloc>
f0101798:	83 c4 10             	add    $0x10,%esp
f010179b:	85 c0                	test   %eax,%eax
f010179d:	74 19                	je     f01017b8 <mem_init+0x816>
f010179f:	68 1c 3c 10 f0       	push   $0xf0103c1c
f01017a4:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01017a9:	68 28 03 00 00       	push   $0x328
f01017ae:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01017b3:	e8 d3 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017b8:	6a 02                	push   $0x2
f01017ba:	68 00 10 00 00       	push   $0x1000
f01017bf:	56                   	push   %esi
f01017c0:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01017c6:	e8 5f f7 ff ff       	call   f0100f2a <page_insert>
f01017cb:	83 c4 10             	add    $0x10,%esp
f01017ce:	85 c0                	test   %eax,%eax
f01017d0:	74 19                	je     f01017eb <mem_init+0x849>
f01017d2:	68 1c 40 10 f0       	push   $0xf010401c
f01017d7:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01017dc:	68 2b 03 00 00       	push   $0x32b
f01017e1:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01017e6:	e8 a0 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017eb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017f0:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01017f5:	e8 fc f0 ff ff       	call   f01008f6 <check_va2pa>
f01017fa:	89 f2                	mov    %esi,%edx
f01017fc:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101802:	c1 fa 03             	sar    $0x3,%edx
f0101805:	c1 e2 0c             	shl    $0xc,%edx
f0101808:	39 d0                	cmp    %edx,%eax
f010180a:	74 19                	je     f0101825 <mem_init+0x883>
f010180c:	68 58 40 10 f0       	push   $0xf0104058
f0101811:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101816:	68 2c 03 00 00       	push   $0x32c
f010181b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101820:	e8 66 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101825:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010182a:	74 19                	je     f0101845 <mem_init+0x8a3>
f010182c:	68 90 3c 10 f0       	push   $0xf0103c90
f0101831:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101836:	68 2d 03 00 00       	push   $0x32d
f010183b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101840:	e8 46 e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101845:	83 ec 0c             	sub    $0xc,%esp
f0101848:	6a 00                	push   $0x0
f010184a:	e8 28 f4 ff ff       	call   f0100c77 <page_alloc>
f010184f:	83 c4 10             	add    $0x10,%esp
f0101852:	85 c0                	test   %eax,%eax
f0101854:	74 19                	je     f010186f <mem_init+0x8cd>
f0101856:	68 1c 3c 10 f0       	push   $0xf0103c1c
f010185b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101860:	68 31 03 00 00       	push   $0x331
f0101865:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010186a:	e8 1c e8 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010186f:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f0101875:	8b 02                	mov    (%edx),%eax
f0101877:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010187c:	89 c1                	mov    %eax,%ecx
f010187e:	c1 e9 0c             	shr    $0xc,%ecx
f0101881:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0101887:	72 15                	jb     f010189e <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101889:	50                   	push   %eax
f010188a:	68 84 3d 10 f0       	push   $0xf0103d84
f010188f:	68 34 03 00 00       	push   $0x334
f0101894:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101899:	e8 ed e7 ff ff       	call   f010008b <_panic>
f010189e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01018a6:	83 ec 04             	sub    $0x4,%esp
f01018a9:	6a 00                	push   $0x0
f01018ab:	68 00 10 00 00       	push   $0x1000
f01018b0:	52                   	push   %edx
f01018b1:	e8 90 f4 ff ff       	call   f0100d46 <pgdir_walk>
f01018b6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01018b9:	8d 51 04             	lea    0x4(%ecx),%edx
f01018bc:	83 c4 10             	add    $0x10,%esp
f01018bf:	39 d0                	cmp    %edx,%eax
f01018c1:	74 19                	je     f01018dc <mem_init+0x93a>
f01018c3:	68 88 40 10 f0       	push   $0xf0104088
f01018c8:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01018cd:	68 35 03 00 00       	push   $0x335
f01018d2:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01018d7:	e8 af e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01018dc:	6a 06                	push   $0x6
f01018de:	68 00 10 00 00       	push   $0x1000
f01018e3:	56                   	push   %esi
f01018e4:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01018ea:	e8 3b f6 ff ff       	call   f0100f2a <page_insert>
f01018ef:	83 c4 10             	add    $0x10,%esp
f01018f2:	85 c0                	test   %eax,%eax
f01018f4:	74 19                	je     f010190f <mem_init+0x96d>
f01018f6:	68 c8 40 10 f0       	push   $0xf01040c8
f01018fb:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101900:	68 38 03 00 00       	push   $0x338
f0101905:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010190a:	e8 7c e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010190f:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101915:	ba 00 10 00 00       	mov    $0x1000,%edx
f010191a:	89 f8                	mov    %edi,%eax
f010191c:	e8 d5 ef ff ff       	call   f01008f6 <check_va2pa>
f0101921:	89 f2                	mov    %esi,%edx
f0101923:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101929:	c1 fa 03             	sar    $0x3,%edx
f010192c:	c1 e2 0c             	shl    $0xc,%edx
f010192f:	39 d0                	cmp    %edx,%eax
f0101931:	74 19                	je     f010194c <mem_init+0x9aa>
f0101933:	68 58 40 10 f0       	push   $0xf0104058
f0101938:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010193d:	68 39 03 00 00       	push   $0x339
f0101942:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101947:	e8 3f e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010194c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101951:	74 19                	je     f010196c <mem_init+0x9ca>
f0101953:	68 90 3c 10 f0       	push   $0xf0103c90
f0101958:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010195d:	68 3a 03 00 00       	push   $0x33a
f0101962:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101967:	e8 1f e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010196c:	83 ec 04             	sub    $0x4,%esp
f010196f:	6a 00                	push   $0x0
f0101971:	68 00 10 00 00       	push   $0x1000
f0101976:	57                   	push   %edi
f0101977:	e8 ca f3 ff ff       	call   f0100d46 <pgdir_walk>
f010197c:	83 c4 10             	add    $0x10,%esp
f010197f:	f6 00 04             	testb  $0x4,(%eax)
f0101982:	75 19                	jne    f010199d <mem_init+0x9fb>
f0101984:	68 08 41 10 f0       	push   $0xf0104108
f0101989:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010198e:	68 3b 03 00 00       	push   $0x33b
f0101993:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101998:	e8 ee e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010199d:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01019a2:	f6 00 04             	testb  $0x4,(%eax)
f01019a5:	75 19                	jne    f01019c0 <mem_init+0xa1e>
f01019a7:	68 a1 3c 10 f0       	push   $0xf0103ca1
f01019ac:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01019b1:	68 3c 03 00 00       	push   $0x33c
f01019b6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01019bb:	e8 cb e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019c0:	6a 02                	push   $0x2
f01019c2:	68 00 10 00 00       	push   $0x1000
f01019c7:	56                   	push   %esi
f01019c8:	50                   	push   %eax
f01019c9:	e8 5c f5 ff ff       	call   f0100f2a <page_insert>
f01019ce:	83 c4 10             	add    $0x10,%esp
f01019d1:	85 c0                	test   %eax,%eax
f01019d3:	74 19                	je     f01019ee <mem_init+0xa4c>
f01019d5:	68 1c 40 10 f0       	push   $0xf010401c
f01019da:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01019df:	68 3f 03 00 00       	push   $0x33f
f01019e4:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01019e9:	e8 9d e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01019ee:	83 ec 04             	sub    $0x4,%esp
f01019f1:	6a 00                	push   $0x0
f01019f3:	68 00 10 00 00       	push   $0x1000
f01019f8:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019fe:	e8 43 f3 ff ff       	call   f0100d46 <pgdir_walk>
f0101a03:	83 c4 10             	add    $0x10,%esp
f0101a06:	f6 00 02             	testb  $0x2,(%eax)
f0101a09:	75 19                	jne    f0101a24 <mem_init+0xa82>
f0101a0b:	68 3c 41 10 f0       	push   $0xf010413c
f0101a10:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101a15:	68 40 03 00 00       	push   $0x340
f0101a1a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101a1f:	e8 67 e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a24:	83 ec 04             	sub    $0x4,%esp
f0101a27:	6a 00                	push   $0x0
f0101a29:	68 00 10 00 00       	push   $0x1000
f0101a2e:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a34:	e8 0d f3 ff ff       	call   f0100d46 <pgdir_walk>
f0101a39:	83 c4 10             	add    $0x10,%esp
f0101a3c:	f6 00 04             	testb  $0x4,(%eax)
f0101a3f:	74 19                	je     f0101a5a <mem_init+0xab8>
f0101a41:	68 70 41 10 f0       	push   $0xf0104170
f0101a46:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101a4b:	68 41 03 00 00       	push   $0x341
f0101a50:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101a55:	e8 31 e6 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101a5a:	6a 02                	push   $0x2
f0101a5c:	68 00 00 40 00       	push   $0x400000
f0101a61:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a64:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a6a:	e8 bb f4 ff ff       	call   f0100f2a <page_insert>
f0101a6f:	83 c4 10             	add    $0x10,%esp
f0101a72:	85 c0                	test   %eax,%eax
f0101a74:	78 19                	js     f0101a8f <mem_init+0xaed>
f0101a76:	68 a8 41 10 f0       	push   $0xf01041a8
f0101a7b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101a80:	68 44 03 00 00       	push   $0x344
f0101a85:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101a8a:	e8 fc e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a8f:	6a 02                	push   $0x2
f0101a91:	68 00 10 00 00       	push   $0x1000
f0101a96:	53                   	push   %ebx
f0101a97:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a9d:	e8 88 f4 ff ff       	call   f0100f2a <page_insert>
f0101aa2:	83 c4 10             	add    $0x10,%esp
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	74 19                	je     f0101ac2 <mem_init+0xb20>
f0101aa9:	68 e0 41 10 f0       	push   $0xf01041e0
f0101aae:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101ab3:	68 47 03 00 00       	push   $0x347
f0101ab8:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101abd:	e8 c9 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ac2:	83 ec 04             	sub    $0x4,%esp
f0101ac5:	6a 00                	push   $0x0
f0101ac7:	68 00 10 00 00       	push   $0x1000
f0101acc:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101ad2:	e8 6f f2 ff ff       	call   f0100d46 <pgdir_walk>
f0101ad7:	83 c4 10             	add    $0x10,%esp
f0101ada:	f6 00 04             	testb  $0x4,(%eax)
f0101add:	74 19                	je     f0101af8 <mem_init+0xb56>
f0101adf:	68 70 41 10 f0       	push   $0xf0104170
f0101ae4:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101ae9:	68 48 03 00 00       	push   $0x348
f0101aee:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101af3:	e8 93 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101af8:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101afe:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b03:	89 f8                	mov    %edi,%eax
f0101b05:	e8 ec ed ff ff       	call   f01008f6 <check_va2pa>
f0101b0a:	89 c1                	mov    %eax,%ecx
f0101b0c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b0f:	89 d8                	mov    %ebx,%eax
f0101b11:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101b17:	c1 f8 03             	sar    $0x3,%eax
f0101b1a:	c1 e0 0c             	shl    $0xc,%eax
f0101b1d:	39 c1                	cmp    %eax,%ecx
f0101b1f:	74 19                	je     f0101b3a <mem_init+0xb98>
f0101b21:	68 1c 42 10 f0       	push   $0xf010421c
f0101b26:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101b2b:	68 4b 03 00 00       	push   $0x34b
f0101b30:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101b35:	e8 51 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b3a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b3f:	89 f8                	mov    %edi,%eax
f0101b41:	e8 b0 ed ff ff       	call   f01008f6 <check_va2pa>
f0101b46:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b49:	74 19                	je     f0101b64 <mem_init+0xbc2>
f0101b4b:	68 48 42 10 f0       	push   $0xf0104248
f0101b50:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101b55:	68 4c 03 00 00       	push   $0x34c
f0101b5a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101b5f:	e8 27 e5 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b64:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b69:	74 19                	je     f0101b84 <mem_init+0xbe2>
f0101b6b:	68 b7 3c 10 f0       	push   $0xf0103cb7
f0101b70:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101b75:	68 4e 03 00 00       	push   $0x34e
f0101b7a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101b7f:	e8 07 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b84:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b89:	74 19                	je     f0101ba4 <mem_init+0xc02>
f0101b8b:	68 c8 3c 10 f0       	push   $0xf0103cc8
f0101b90:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101b95:	68 4f 03 00 00       	push   $0x34f
f0101b9a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101b9f:	e8 e7 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ba4:	83 ec 0c             	sub    $0xc,%esp
f0101ba7:	6a 00                	push   $0x0
f0101ba9:	e8 c9 f0 ff ff       	call   f0100c77 <page_alloc>
f0101bae:	83 c4 10             	add    $0x10,%esp
f0101bb1:	39 c6                	cmp    %eax,%esi
f0101bb3:	75 04                	jne    f0101bb9 <mem_init+0xc17>
f0101bb5:	85 c0                	test   %eax,%eax
f0101bb7:	75 19                	jne    f0101bd2 <mem_init+0xc30>
f0101bb9:	68 78 42 10 f0       	push   $0xf0104278
f0101bbe:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101bc3:	68 52 03 00 00       	push   $0x352
f0101bc8:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101bcd:	e8 b9 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101bd2:	83 ec 08             	sub    $0x8,%esp
f0101bd5:	6a 00                	push   $0x0
f0101bd7:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101bdd:	e8 06 f3 ff ff       	call   f0100ee8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101be2:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101be8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bed:	89 f8                	mov    %edi,%eax
f0101bef:	e8 02 ed ff ff       	call   f01008f6 <check_va2pa>
f0101bf4:	83 c4 10             	add    $0x10,%esp
f0101bf7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101bfa:	74 19                	je     f0101c15 <mem_init+0xc73>
f0101bfc:	68 9c 42 10 f0       	push   $0xf010429c
f0101c01:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101c06:	68 56 03 00 00       	push   $0x356
f0101c0b:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101c10:	e8 76 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c1a:	89 f8                	mov    %edi,%eax
f0101c1c:	e8 d5 ec ff ff       	call   f01008f6 <check_va2pa>
f0101c21:	89 da                	mov    %ebx,%edx
f0101c23:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101c29:	c1 fa 03             	sar    $0x3,%edx
f0101c2c:	c1 e2 0c             	shl    $0xc,%edx
f0101c2f:	39 d0                	cmp    %edx,%eax
f0101c31:	74 19                	je     f0101c4c <mem_init+0xcaa>
f0101c33:	68 48 42 10 f0       	push   $0xf0104248
f0101c38:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101c3d:	68 57 03 00 00       	push   $0x357
f0101c42:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101c47:	e8 3f e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101c4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c51:	74 19                	je     f0101c6c <mem_init+0xcca>
f0101c53:	68 6e 3c 10 f0       	push   $0xf0103c6e
f0101c58:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101c5d:	68 58 03 00 00       	push   $0x358
f0101c62:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101c67:	e8 1f e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c6c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c71:	74 19                	je     f0101c8c <mem_init+0xcea>
f0101c73:	68 c8 3c 10 f0       	push   $0xf0103cc8
f0101c78:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101c7d:	68 59 03 00 00       	push   $0x359
f0101c82:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101c87:	e8 ff e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c8c:	6a 00                	push   $0x0
f0101c8e:	68 00 10 00 00       	push   $0x1000
f0101c93:	53                   	push   %ebx
f0101c94:	57                   	push   %edi
f0101c95:	e8 90 f2 ff ff       	call   f0100f2a <page_insert>
f0101c9a:	83 c4 10             	add    $0x10,%esp
f0101c9d:	85 c0                	test   %eax,%eax
f0101c9f:	74 19                	je     f0101cba <mem_init+0xd18>
f0101ca1:	68 c0 42 10 f0       	push   $0xf01042c0
f0101ca6:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101cab:	68 5c 03 00 00       	push   $0x35c
f0101cb0:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101cb5:	e8 d1 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101cba:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cbf:	75 19                	jne    f0101cda <mem_init+0xd38>
f0101cc1:	68 d9 3c 10 f0       	push   $0xf0103cd9
f0101cc6:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101ccb:	68 5d 03 00 00       	push   $0x35d
f0101cd0:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101cd5:	e8 b1 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101cda:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101cdd:	74 19                	je     f0101cf8 <mem_init+0xd56>
f0101cdf:	68 e5 3c 10 f0       	push   $0xf0103ce5
f0101ce4:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101ce9:	68 5e 03 00 00       	push   $0x35e
f0101cee:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101cf3:	e8 93 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101cf8:	83 ec 08             	sub    $0x8,%esp
f0101cfb:	68 00 10 00 00       	push   $0x1000
f0101d00:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101d06:	e8 dd f1 ff ff       	call   f0100ee8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d0b:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101d11:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d16:	89 f8                	mov    %edi,%eax
f0101d18:	e8 d9 eb ff ff       	call   f01008f6 <check_va2pa>
f0101d1d:	83 c4 10             	add    $0x10,%esp
f0101d20:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d23:	74 19                	je     f0101d3e <mem_init+0xd9c>
f0101d25:	68 9c 42 10 f0       	push   $0xf010429c
f0101d2a:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101d2f:	68 62 03 00 00       	push   $0x362
f0101d34:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101d39:	e8 4d e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d3e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d43:	89 f8                	mov    %edi,%eax
f0101d45:	e8 ac eb ff ff       	call   f01008f6 <check_va2pa>
f0101d4a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d4d:	74 19                	je     f0101d68 <mem_init+0xdc6>
f0101d4f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d54:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101d59:	68 63 03 00 00       	push   $0x363
f0101d5e:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101d63:	e8 23 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101d68:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d6d:	74 19                	je     f0101d88 <mem_init+0xde6>
f0101d6f:	68 fa 3c 10 f0       	push   $0xf0103cfa
f0101d74:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101d79:	68 64 03 00 00       	push   $0x364
f0101d7e:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101d83:	e8 03 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d88:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d8d:	74 19                	je     f0101da8 <mem_init+0xe06>
f0101d8f:	68 c8 3c 10 f0       	push   $0xf0103cc8
f0101d94:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101d99:	68 65 03 00 00       	push   $0x365
f0101d9e:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101da3:	e8 e3 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101da8:	83 ec 0c             	sub    $0xc,%esp
f0101dab:	6a 00                	push   $0x0
f0101dad:	e8 c5 ee ff ff       	call   f0100c77 <page_alloc>
f0101db2:	83 c4 10             	add    $0x10,%esp
f0101db5:	85 c0                	test   %eax,%eax
f0101db7:	74 04                	je     f0101dbd <mem_init+0xe1b>
f0101db9:	39 c3                	cmp    %eax,%ebx
f0101dbb:	74 19                	je     f0101dd6 <mem_init+0xe34>
f0101dbd:	68 20 43 10 f0       	push   $0xf0104320
f0101dc2:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101dc7:	68 68 03 00 00       	push   $0x368
f0101dcc:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101dd1:	e8 b5 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101dd6:	83 ec 0c             	sub    $0xc,%esp
f0101dd9:	6a 00                	push   $0x0
f0101ddb:	e8 97 ee ff ff       	call   f0100c77 <page_alloc>
f0101de0:	83 c4 10             	add    $0x10,%esp
f0101de3:	85 c0                	test   %eax,%eax
f0101de5:	74 19                	je     f0101e00 <mem_init+0xe5e>
f0101de7:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101dec:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101df1:	68 6b 03 00 00       	push   $0x36b
f0101df6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101dfb:	e8 8b e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e00:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101e06:	8b 11                	mov    (%ecx),%edx
f0101e08:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e11:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101e17:	c1 f8 03             	sar    $0x3,%eax
f0101e1a:	c1 e0 0c             	shl    $0xc,%eax
f0101e1d:	39 c2                	cmp    %eax,%edx
f0101e1f:	74 19                	je     f0101e3a <mem_init+0xe98>
f0101e21:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0101e26:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101e2b:	68 6e 03 00 00       	push   $0x36e
f0101e30:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101e35:	e8 51 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101e3a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e43:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e48:	74 19                	je     f0101e63 <mem_init+0xec1>
f0101e4a:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0101e4f:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101e54:	68 70 03 00 00       	push   $0x370
f0101e59:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101e5e:	e8 28 e2 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101e63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e66:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e6c:	83 ec 0c             	sub    $0xc,%esp
f0101e6f:	50                   	push   %eax
f0101e70:	e8 72 ee ff ff       	call   f0100ce7 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e75:	83 c4 0c             	add    $0xc,%esp
f0101e78:	6a 01                	push   $0x1
f0101e7a:	68 00 10 40 00       	push   $0x401000
f0101e7f:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101e85:	e8 bc ee ff ff       	call   f0100d46 <pgdir_walk>
f0101e8a:	89 c7                	mov    %eax,%edi
f0101e8c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e8f:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101e94:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e97:	8b 40 04             	mov    0x4(%eax),%eax
f0101e9a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e9f:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101ea5:	89 c2                	mov    %eax,%edx
f0101ea7:	c1 ea 0c             	shr    $0xc,%edx
f0101eaa:	83 c4 10             	add    $0x10,%esp
f0101ead:	39 ca                	cmp    %ecx,%edx
f0101eaf:	72 15                	jb     f0101ec6 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101eb1:	50                   	push   %eax
f0101eb2:	68 84 3d 10 f0       	push   $0xf0103d84
f0101eb7:	68 77 03 00 00       	push   $0x377
f0101ebc:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101ec1:	e8 c5 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ec6:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ecb:	39 c7                	cmp    %eax,%edi
f0101ecd:	74 19                	je     f0101ee8 <mem_init+0xf46>
f0101ecf:	68 0b 3d 10 f0       	push   $0xf0103d0b
f0101ed4:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101ed9:	68 78 03 00 00       	push   $0x378
f0101ede:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101ee3:	e8 a3 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ee8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101eeb:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ef2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101efb:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101f01:	c1 f8 03             	sar    $0x3,%eax
f0101f04:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f07:	89 c2                	mov    %eax,%edx
f0101f09:	c1 ea 0c             	shr    $0xc,%edx
f0101f0c:	39 d1                	cmp    %edx,%ecx
f0101f0e:	77 12                	ja     f0101f22 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f10:	50                   	push   %eax
f0101f11:	68 84 3d 10 f0       	push   $0xf0103d84
f0101f16:	6a 52                	push   $0x52
f0101f18:	68 98 3a 10 f0       	push   $0xf0103a98
f0101f1d:	e8 69 e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f22:	83 ec 04             	sub    $0x4,%esp
f0101f25:	68 00 10 00 00       	push   $0x1000
f0101f2a:	68 ff 00 00 00       	push   $0xff
f0101f2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f34:	50                   	push   %eax
f0101f35:	e8 f7 11 00 00       	call   f0103131 <memset>
	page_free(pp0);
f0101f3a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f3d:	89 3c 24             	mov    %edi,(%esp)
f0101f40:	e8 a2 ed ff ff       	call   f0100ce7 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f45:	83 c4 0c             	add    $0xc,%esp
f0101f48:	6a 01                	push   $0x1
f0101f4a:	6a 00                	push   $0x0
f0101f4c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101f52:	e8 ef ed ff ff       	call   f0100d46 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f57:	89 fa                	mov    %edi,%edx
f0101f59:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101f5f:	c1 fa 03             	sar    $0x3,%edx
f0101f62:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f65:	89 d0                	mov    %edx,%eax
f0101f67:	c1 e8 0c             	shr    $0xc,%eax
f0101f6a:	83 c4 10             	add    $0x10,%esp
f0101f6d:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0101f73:	72 12                	jb     f0101f87 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f75:	52                   	push   %edx
f0101f76:	68 84 3d 10 f0       	push   $0xf0103d84
f0101f7b:	6a 52                	push   $0x52
f0101f7d:	68 98 3a 10 f0       	push   $0xf0103a98
f0101f82:	e8 04 e1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101f87:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f90:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f96:	f6 00 01             	testb  $0x1,(%eax)
f0101f99:	74 19                	je     f0101fb4 <mem_init+0x1012>
f0101f9b:	68 23 3d 10 f0       	push   $0xf0103d23
f0101fa0:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0101fa5:	68 82 03 00 00       	push   $0x382
f0101faa:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0101faf:	e8 d7 e0 ff ff       	call   f010008b <_panic>
f0101fb4:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101fb7:	39 d0                	cmp    %edx,%eax
f0101fb9:	75 db                	jne    f0101f96 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101fbb:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101fc0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101fcf:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101fd2:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101fd8:	83 ec 0c             	sub    $0xc,%esp
f0101fdb:	50                   	push   %eax
f0101fdc:	e8 06 ed ff ff       	call   f0100ce7 <page_free>
	page_free(pp1);
f0101fe1:	89 1c 24             	mov    %ebx,(%esp)
f0101fe4:	e8 fe ec ff ff       	call   f0100ce7 <page_free>
	page_free(pp2);
f0101fe9:	89 34 24             	mov    %esi,(%esp)
f0101fec:	e8 f6 ec ff ff       	call   f0100ce7 <page_free>

	cprintf("check_page() succeeded!\n");
f0101ff1:	c7 04 24 3a 3d 10 f0 	movl   $0xf0103d3a,(%esp)
f0101ff8:	e8 4b 06 00 00       	call   f0102648 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f0101ffd:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102002:	83 c4 10             	add    $0x10,%esp
f0102005:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010200a:	77 15                	ja     f0102021 <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010200c:	50                   	push   %eax
f010200d:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0102012:	68 c4 00 00 00       	push   $0xc4
f0102017:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010201c:	e8 6a e0 ff ff       	call   f010008b <_panic>
f0102021:	83 ec 08             	sub    $0x8,%esp
f0102024:	6a 05                	push   $0x5
f0102026:	05 00 00 00 10       	add    $0x10000000,%eax
f010202b:	50                   	push   %eax
f010202c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102031:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102036:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010203b:	e8 f2 ed ff ff       	call   f0100e32 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102040:	83 c4 10             	add    $0x10,%esp
f0102043:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102048:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010204d:	77 15                	ja     f0102064 <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010204f:	50                   	push   %eax
f0102050:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0102055:	68 d4 00 00 00       	push   $0xd4
f010205a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010205f:	e8 27 e0 ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f0102064:	83 ec 08             	sub    $0x8,%esp
f0102067:	6a 02                	push   $0x2
f0102069:	68 00 c0 10 00       	push   $0x10c000
f010206e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102073:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102078:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010207d:	e8 b0 ed ff ff       	call   f0100e32 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f0102082:	83 c4 08             	add    $0x8,%esp
f0102085:	6a 03                	push   $0x3
f0102087:	6a 00                	push   $0x0
f0102089:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010208e:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102093:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0102098:	e8 95 ed ff ff       	call   f0100e32 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010209d:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020a3:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f01020a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020ab:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01020b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01020b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020ba:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020c0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01020c3:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020c6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020cb:	eb 55                	jmp    f0102122 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020cd:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01020d3:	89 f0                	mov    %esi,%eax
f01020d5:	e8 1c e8 ff ff       	call   f01008f6 <check_va2pa>
f01020da:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01020e1:	77 15                	ja     f01020f8 <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020e3:	57                   	push   %edi
f01020e4:	68 6c 3e 10 f0       	push   $0xf0103e6c
f01020e9:	68 c4 02 00 00       	push   $0x2c4
f01020ee:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01020f3:	e8 93 df ff ff       	call   f010008b <_panic>
f01020f8:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01020ff:	39 c2                	cmp    %eax,%edx
f0102101:	74 19                	je     f010211c <mem_init+0x117a>
f0102103:	68 44 43 10 f0       	push   $0xf0104344
f0102108:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010210d:	68 c4 02 00 00       	push   $0x2c4
f0102112:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102117:	e8 6f df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010211c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102122:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102125:	77 a6                	ja     f01020cd <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102127:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010212a:	c1 e7 0c             	shl    $0xc,%edi
f010212d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102132:	eb 30                	jmp    f0102164 <mem_init+0x11c2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102134:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010213a:	89 f0                	mov    %esi,%eax
f010213c:	e8 b5 e7 ff ff       	call   f01008f6 <check_va2pa>
f0102141:	39 c3                	cmp    %eax,%ebx
f0102143:	74 19                	je     f010215e <mem_init+0x11bc>
f0102145:	68 78 43 10 f0       	push   $0xf0104378
f010214a:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010214f:	68 c9 02 00 00       	push   $0x2c9
f0102154:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102159:	e8 2d df ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010215e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102164:	39 fb                	cmp    %edi,%ebx
f0102166:	72 cc                	jb     f0102134 <mem_init+0x1192>
f0102168:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010216d:	89 da                	mov    %ebx,%edx
f010216f:	89 f0                	mov    %esi,%eax
f0102171:	e8 80 e7 ff ff       	call   f01008f6 <check_va2pa>
f0102176:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010217c:	39 c2                	cmp    %eax,%edx
f010217e:	74 19                	je     f0102199 <mem_init+0x11f7>
f0102180:	68 a0 43 10 f0       	push   $0xf01043a0
f0102185:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010218a:	68 cd 02 00 00       	push   $0x2cd
f010218f:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102194:	e8 f2 de ff ff       	call   f010008b <_panic>
f0102199:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010219f:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01021a5:	75 c6                	jne    f010216d <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021a7:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01021ac:	89 f0                	mov    %esi,%eax
f01021ae:	e8 43 e7 ff ff       	call   f01008f6 <check_va2pa>
f01021b3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021b6:	74 51                	je     f0102209 <mem_init+0x1267>
f01021b8:	68 e8 43 10 f0       	push   $0xf01043e8
f01021bd:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01021c2:	68 ce 02 00 00       	push   $0x2ce
f01021c7:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01021cc:	e8 ba de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01021d1:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01021d6:	72 36                	jb     f010220e <mem_init+0x126c>
f01021d8:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01021dd:	76 07                	jbe    f01021e6 <mem_init+0x1244>
f01021df:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021e4:	75 28                	jne    f010220e <mem_init+0x126c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01021e6:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01021ea:	0f 85 83 00 00 00    	jne    f0102273 <mem_init+0x12d1>
f01021f0:	68 53 3d 10 f0       	push   $0xf0103d53
f01021f5:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01021fa:	68 d6 02 00 00       	push   $0x2d6
f01021ff:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102204:	e8 82 de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102209:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010220e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102213:	76 3f                	jbe    f0102254 <mem_init+0x12b2>
				assert(pgdir[i] & PTE_P);
f0102215:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102218:	f6 c2 01             	test   $0x1,%dl
f010221b:	75 19                	jne    f0102236 <mem_init+0x1294>
f010221d:	68 53 3d 10 f0       	push   $0xf0103d53
f0102222:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102227:	68 da 02 00 00       	push   $0x2da
f010222c:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102231:	e8 55 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102236:	f6 c2 02             	test   $0x2,%dl
f0102239:	75 38                	jne    f0102273 <mem_init+0x12d1>
f010223b:	68 64 3d 10 f0       	push   $0xf0103d64
f0102240:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102245:	68 db 02 00 00       	push   $0x2db
f010224a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010224f:	e8 37 de ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102254:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102258:	74 19                	je     f0102273 <mem_init+0x12d1>
f010225a:	68 75 3d 10 f0       	push   $0xf0103d75
f010225f:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102264:	68 dd 02 00 00       	push   $0x2dd
f0102269:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010226e:	e8 18 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102273:	83 c0 01             	add    $0x1,%eax
f0102276:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010227b:	0f 86 50 ff ff ff    	jbe    f01021d1 <mem_init+0x122f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102281:	83 ec 0c             	sub    $0xc,%esp
f0102284:	68 18 44 10 f0       	push   $0xf0104418
f0102289:	e8 ba 03 00 00       	call   f0102648 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010228e:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102293:	83 c4 10             	add    $0x10,%esp
f0102296:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010229b:	77 15                	ja     f01022b2 <mem_init+0x1310>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010229d:	50                   	push   %eax
f010229e:	68 6c 3e 10 f0       	push   $0xf0103e6c
f01022a3:	68 ec 00 00 00       	push   $0xec
f01022a8:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01022ad:	e8 d9 dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01022b2:	05 00 00 00 10       	add    $0x10000000,%eax
f01022b7:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01022ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01022bf:	e8 96 e6 ff ff       	call   f010095a <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01022c4:	0f 20 c0             	mov    %cr0,%eax
f01022c7:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01022ca:	0d 23 00 05 80       	or     $0x80050023,%eax
f01022cf:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01022d2:	83 ec 0c             	sub    $0xc,%esp
f01022d5:	6a 00                	push   $0x0
f01022d7:	e8 9b e9 ff ff       	call   f0100c77 <page_alloc>
f01022dc:	89 c3                	mov    %eax,%ebx
f01022de:	83 c4 10             	add    $0x10,%esp
f01022e1:	85 c0                	test   %eax,%eax
f01022e3:	75 19                	jne    f01022fe <mem_init+0x135c>
f01022e5:	68 71 3b 10 f0       	push   $0xf0103b71
f01022ea:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01022ef:	68 9d 03 00 00       	push   $0x39d
f01022f4:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01022f9:	e8 8d dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01022fe:	83 ec 0c             	sub    $0xc,%esp
f0102301:	6a 00                	push   $0x0
f0102303:	e8 6f e9 ff ff       	call   f0100c77 <page_alloc>
f0102308:	89 c7                	mov    %eax,%edi
f010230a:	83 c4 10             	add    $0x10,%esp
f010230d:	85 c0                	test   %eax,%eax
f010230f:	75 19                	jne    f010232a <mem_init+0x1388>
f0102311:	68 87 3b 10 f0       	push   $0xf0103b87
f0102316:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010231b:	68 9e 03 00 00       	push   $0x39e
f0102320:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102325:	e8 61 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010232a:	83 ec 0c             	sub    $0xc,%esp
f010232d:	6a 00                	push   $0x0
f010232f:	e8 43 e9 ff ff       	call   f0100c77 <page_alloc>
f0102334:	89 c6                	mov    %eax,%esi
f0102336:	83 c4 10             	add    $0x10,%esp
f0102339:	85 c0                	test   %eax,%eax
f010233b:	75 19                	jne    f0102356 <mem_init+0x13b4>
f010233d:	68 9d 3b 10 f0       	push   $0xf0103b9d
f0102342:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102347:	68 9f 03 00 00       	push   $0x39f
f010234c:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102351:	e8 35 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102356:	83 ec 0c             	sub    $0xc,%esp
f0102359:	53                   	push   %ebx
f010235a:	e8 88 e9 ff ff       	call   f0100ce7 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010235f:	89 f8                	mov    %edi,%eax
f0102361:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102367:	c1 f8 03             	sar    $0x3,%eax
f010236a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010236d:	89 c2                	mov    %eax,%edx
f010236f:	c1 ea 0c             	shr    $0xc,%edx
f0102372:	83 c4 10             	add    $0x10,%esp
f0102375:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f010237b:	72 12                	jb     f010238f <mem_init+0x13ed>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010237d:	50                   	push   %eax
f010237e:	68 84 3d 10 f0       	push   $0xf0103d84
f0102383:	6a 52                	push   $0x52
f0102385:	68 98 3a 10 f0       	push   $0xf0103a98
f010238a:	e8 fc dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010238f:	83 ec 04             	sub    $0x4,%esp
f0102392:	68 00 10 00 00       	push   $0x1000
f0102397:	6a 01                	push   $0x1
f0102399:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010239e:	50                   	push   %eax
f010239f:	e8 8d 0d 00 00       	call   f0103131 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023a4:	89 f0                	mov    %esi,%eax
f01023a6:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01023ac:	c1 f8 03             	sar    $0x3,%eax
f01023af:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023b2:	89 c2                	mov    %eax,%edx
f01023b4:	c1 ea 0c             	shr    $0xc,%edx
f01023b7:	83 c4 10             	add    $0x10,%esp
f01023ba:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01023c0:	72 12                	jb     f01023d4 <mem_init+0x1432>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023c2:	50                   	push   %eax
f01023c3:	68 84 3d 10 f0       	push   $0xf0103d84
f01023c8:	6a 52                	push   $0x52
f01023ca:	68 98 3a 10 f0       	push   $0xf0103a98
f01023cf:	e8 b7 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01023d4:	83 ec 04             	sub    $0x4,%esp
f01023d7:	68 00 10 00 00       	push   $0x1000
f01023dc:	6a 02                	push   $0x2
f01023de:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023e3:	50                   	push   %eax
f01023e4:	e8 48 0d 00 00       	call   f0103131 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01023e9:	6a 02                	push   $0x2
f01023eb:	68 00 10 00 00       	push   $0x1000
f01023f0:	57                   	push   %edi
f01023f1:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01023f7:	e8 2e eb ff ff       	call   f0100f2a <page_insert>
	assert(pp1->pp_ref == 1);
f01023fc:	83 c4 20             	add    $0x20,%esp
f01023ff:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102404:	74 19                	je     f010241f <mem_init+0x147d>
f0102406:	68 6e 3c 10 f0       	push   $0xf0103c6e
f010240b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102410:	68 a4 03 00 00       	push   $0x3a4
f0102415:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010241a:	e8 6c dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010241f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102426:	01 01 01 
f0102429:	74 19                	je     f0102444 <mem_init+0x14a2>
f010242b:	68 38 44 10 f0       	push   $0xf0104438
f0102430:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102435:	68 a5 03 00 00       	push   $0x3a5
f010243a:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010243f:	e8 47 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102444:	6a 02                	push   $0x2
f0102446:	68 00 10 00 00       	push   $0x1000
f010244b:	56                   	push   %esi
f010244c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102452:	e8 d3 ea ff ff       	call   f0100f2a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102457:	83 c4 10             	add    $0x10,%esp
f010245a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102461:	02 02 02 
f0102464:	74 19                	je     f010247f <mem_init+0x14dd>
f0102466:	68 5c 44 10 f0       	push   $0xf010445c
f010246b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102470:	68 a7 03 00 00       	push   $0x3a7
f0102475:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010247a:	e8 0c dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010247f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102484:	74 19                	je     f010249f <mem_init+0x14fd>
f0102486:	68 90 3c 10 f0       	push   $0xf0103c90
f010248b:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102490:	68 a8 03 00 00       	push   $0x3a8
f0102495:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010249a:	e8 ec db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010249f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024a4:	74 19                	je     f01024bf <mem_init+0x151d>
f01024a6:	68 fa 3c 10 f0       	push   $0xf0103cfa
f01024ab:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01024b0:	68 a9 03 00 00       	push   $0x3a9
f01024b5:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01024ba:	e8 cc db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024bf:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024c6:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c9:	89 f0                	mov    %esi,%eax
f01024cb:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01024d1:	c1 f8 03             	sar    $0x3,%eax
f01024d4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d7:	89 c2                	mov    %eax,%edx
f01024d9:	c1 ea 0c             	shr    $0xc,%edx
f01024dc:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01024e2:	72 12                	jb     f01024f6 <mem_init+0x1554>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e4:	50                   	push   %eax
f01024e5:	68 84 3d 10 f0       	push   $0xf0103d84
f01024ea:	6a 52                	push   $0x52
f01024ec:	68 98 3a 10 f0       	push   $0xf0103a98
f01024f1:	e8 95 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024f6:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01024fd:	03 03 03 
f0102500:	74 19                	je     f010251b <mem_init+0x1579>
f0102502:	68 80 44 10 f0       	push   $0xf0104480
f0102507:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010250c:	68 ab 03 00 00       	push   $0x3ab
f0102511:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102516:	e8 70 db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010251b:	83 ec 08             	sub    $0x8,%esp
f010251e:	68 00 10 00 00       	push   $0x1000
f0102523:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102529:	e8 ba e9 ff ff       	call   f0100ee8 <page_remove>
	assert(pp2->pp_ref == 0);
f010252e:	83 c4 10             	add    $0x10,%esp
f0102531:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102536:	74 19                	je     f0102551 <mem_init+0x15af>
f0102538:	68 c8 3c 10 f0       	push   $0xf0103cc8
f010253d:	68 b2 3a 10 f0       	push   $0xf0103ab2
f0102542:	68 ad 03 00 00       	push   $0x3ad
f0102547:	68 8c 3a 10 f0       	push   $0xf0103a8c
f010254c:	e8 3a db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102551:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0102557:	8b 11                	mov    (%ecx),%edx
f0102559:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010255f:	89 d8                	mov    %ebx,%eax
f0102561:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102567:	c1 f8 03             	sar    $0x3,%eax
f010256a:	c1 e0 0c             	shl    $0xc,%eax
f010256d:	39 c2                	cmp    %eax,%edx
f010256f:	74 19                	je     f010258a <mem_init+0x15e8>
f0102571:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0102576:	68 b2 3a 10 f0       	push   $0xf0103ab2
f010257b:	68 b0 03 00 00       	push   $0x3b0
f0102580:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0102585:	e8 01 db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010258a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102590:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102595:	74 19                	je     f01025b0 <mem_init+0x160e>
f0102597:	68 7f 3c 10 f0       	push   $0xf0103c7f
f010259c:	68 b2 3a 10 f0       	push   $0xf0103ab2
f01025a1:	68 b2 03 00 00       	push   $0x3b2
f01025a6:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01025ab:	e8 db da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01025b0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01025b6:	83 ec 0c             	sub    $0xc,%esp
f01025b9:	53                   	push   %ebx
f01025ba:	e8 28 e7 ff ff       	call   f0100ce7 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025bf:	c7 04 24 ac 44 10 f0 	movl   $0xf01044ac,(%esp)
f01025c6:	e8 7d 00 00 00       	call   f0102648 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01025cb:	83 c4 10             	add    $0x10,%esp
f01025ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025d1:	5b                   	pop    %ebx
f01025d2:	5e                   	pop    %esi
f01025d3:	5f                   	pop    %edi
f01025d4:	5d                   	pop    %ebp
f01025d5:	c3                   	ret    

f01025d6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01025d6:	55                   	push   %ebp
f01025d7:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01025d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025dc:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01025df:	5d                   	pop    %ebp
f01025e0:	c3                   	ret    

f01025e1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01025e1:	55                   	push   %ebp
f01025e2:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025e4:	ba 70 00 00 00       	mov    $0x70,%edx
f01025e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01025ec:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01025ed:	ba 71 00 00 00       	mov    $0x71,%edx
f01025f2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01025f3:	0f b6 c0             	movzbl %al,%eax
}
f01025f6:	5d                   	pop    %ebp
f01025f7:	c3                   	ret    

f01025f8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01025f8:	55                   	push   %ebp
f01025f9:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025fb:	ba 70 00 00 00       	mov    $0x70,%edx
f0102600:	8b 45 08             	mov    0x8(%ebp),%eax
f0102603:	ee                   	out    %al,(%dx)
f0102604:	ba 71 00 00 00       	mov    $0x71,%edx
f0102609:	8b 45 0c             	mov    0xc(%ebp),%eax
f010260c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010260d:	5d                   	pop    %ebp
f010260e:	c3                   	ret    

f010260f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010260f:	55                   	push   %ebp
f0102610:	89 e5                	mov    %esp,%ebp
f0102612:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102615:	ff 75 08             	pushl  0x8(%ebp)
f0102618:	e8 e3 df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010261d:	83 c4 10             	add    $0x10,%esp
f0102620:	c9                   	leave  
f0102621:	c3                   	ret    

f0102622 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102622:	55                   	push   %ebp
f0102623:	89 e5                	mov    %esp,%ebp
f0102625:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102628:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010262f:	ff 75 0c             	pushl  0xc(%ebp)
f0102632:	ff 75 08             	pushl  0x8(%ebp)
f0102635:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102638:	50                   	push   %eax
f0102639:	68 0f 26 10 f0       	push   $0xf010260f
f010263e:	e8 c9 03 00 00       	call   f0102a0c <vprintfmt>
	return cnt;
}
f0102643:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102646:	c9                   	leave  
f0102647:	c3                   	ret    

f0102648 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102648:	55                   	push   %ebp
f0102649:	89 e5                	mov    %esp,%ebp
f010264b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010264e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102651:	50                   	push   %eax
f0102652:	ff 75 08             	pushl  0x8(%ebp)
f0102655:	e8 c8 ff ff ff       	call   f0102622 <vcprintf>
	va_end(ap);

	return cnt;
}
f010265a:	c9                   	leave  
f010265b:	c3                   	ret    

f010265c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010265c:	55                   	push   %ebp
f010265d:	89 e5                	mov    %esp,%ebp
f010265f:	57                   	push   %edi
f0102660:	56                   	push   %esi
f0102661:	53                   	push   %ebx
f0102662:	83 ec 14             	sub    $0x14,%esp
f0102665:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102668:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010266b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010266e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102671:	8b 1a                	mov    (%edx),%ebx
f0102673:	8b 01                	mov    (%ecx),%eax
f0102675:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102678:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010267f:	eb 7f                	jmp    f0102700 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102681:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102684:	01 d8                	add    %ebx,%eax
f0102686:	89 c6                	mov    %eax,%esi
f0102688:	c1 ee 1f             	shr    $0x1f,%esi
f010268b:	01 c6                	add    %eax,%esi
f010268d:	d1 fe                	sar    %esi
f010268f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102692:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102695:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102698:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010269a:	eb 03                	jmp    f010269f <stab_binsearch+0x43>
			m--;
f010269c:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010269f:	39 c3                	cmp    %eax,%ebx
f01026a1:	7f 0d                	jg     f01026b0 <stab_binsearch+0x54>
f01026a3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01026a7:	83 ea 0c             	sub    $0xc,%edx
f01026aa:	39 f9                	cmp    %edi,%ecx
f01026ac:	75 ee                	jne    f010269c <stab_binsearch+0x40>
f01026ae:	eb 05                	jmp    f01026b5 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01026b0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01026b3:	eb 4b                	jmp    f0102700 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01026b5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026b8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026bb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01026bf:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026c2:	76 11                	jbe    f01026d5 <stab_binsearch+0x79>
			*region_left = m;
f01026c4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01026c7:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01026c9:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026cc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026d3:	eb 2b                	jmp    f0102700 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01026d5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026d8:	73 14                	jae    f01026ee <stab_binsearch+0x92>
			*region_right = m - 1;
f01026da:	83 e8 01             	sub    $0x1,%eax
f01026dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026e0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026e3:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026e5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026ec:	eb 12                	jmp    f0102700 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01026ee:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026f1:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026f3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026f7:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026f9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102700:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102703:	0f 8e 78 ff ff ff    	jle    f0102681 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102709:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010270d:	75 0f                	jne    f010271e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010270f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102712:	8b 00                	mov    (%eax),%eax
f0102714:	83 e8 01             	sub    $0x1,%eax
f0102717:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010271a:	89 06                	mov    %eax,(%esi)
f010271c:	eb 2c                	jmp    f010274a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010271e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102721:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102723:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102726:	8b 0e                	mov    (%esi),%ecx
f0102728:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010272b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010272e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102731:	eb 03                	jmp    f0102736 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102733:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102736:	39 c8                	cmp    %ecx,%eax
f0102738:	7e 0b                	jle    f0102745 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010273a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010273e:	83 ea 0c             	sub    $0xc,%edx
f0102741:	39 df                	cmp    %ebx,%edi
f0102743:	75 ee                	jne    f0102733 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102745:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102748:	89 06                	mov    %eax,(%esi)
	}
}
f010274a:	83 c4 14             	add    $0x14,%esp
f010274d:	5b                   	pop    %ebx
f010274e:	5e                   	pop    %esi
f010274f:	5f                   	pop    %edi
f0102750:	5d                   	pop    %ebp
f0102751:	c3                   	ret    

f0102752 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102752:	55                   	push   %ebp
f0102753:	89 e5                	mov    %esp,%ebp
f0102755:	57                   	push   %edi
f0102756:	56                   	push   %esi
f0102757:	53                   	push   %ebx
f0102758:	83 ec 1c             	sub    $0x1c,%esp
f010275b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010275e:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102761:	c7 06 d8 44 10 f0    	movl   $0xf01044d8,(%esi)
	info->eip_line = 0;
f0102767:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010276e:	c7 46 08 d8 44 10 f0 	movl   $0xf01044d8,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102775:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010277c:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010277f:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102786:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010278c:	76 11                	jbe    f010279f <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010278e:	b8 72 bc 10 f0       	mov    $0xf010bc72,%eax
f0102793:	3d fd 9e 10 f0       	cmp    $0xf0109efd,%eax
f0102798:	77 19                	ja     f01027b3 <debuginfo_eip+0x61>
f010279a:	e9 62 01 00 00       	jmp    f0102901 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010279f:	83 ec 04             	sub    $0x4,%esp
f01027a2:	68 e2 44 10 f0       	push   $0xf01044e2
f01027a7:	6a 7f                	push   $0x7f
f01027a9:	68 ef 44 10 f0       	push   $0xf01044ef
f01027ae:	e8 d8 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027b3:	80 3d 71 bc 10 f0 00 	cmpb   $0x0,0xf010bc71
f01027ba:	0f 85 48 01 00 00    	jne    f0102908 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01027c0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01027c7:	b8 fc 9e 10 f0       	mov    $0xf0109efc,%eax
f01027cc:	2d 0c 47 10 f0       	sub    $0xf010470c,%eax
f01027d1:	c1 f8 02             	sar    $0x2,%eax
f01027d4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01027da:	83 e8 01             	sub    $0x1,%eax
f01027dd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01027e0:	83 ec 08             	sub    $0x8,%esp
f01027e3:	57                   	push   %edi
f01027e4:	6a 64                	push   $0x64
f01027e6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01027e9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01027ec:	b8 0c 47 10 f0       	mov    $0xf010470c,%eax
f01027f1:	e8 66 fe ff ff       	call   f010265c <stab_binsearch>
	if (lfile == 0)
f01027f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027f9:	83 c4 10             	add    $0x10,%esp
f01027fc:	85 c0                	test   %eax,%eax
f01027fe:	0f 84 0b 01 00 00    	je     f010290f <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102804:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102807:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010280a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010280d:	83 ec 08             	sub    $0x8,%esp
f0102810:	57                   	push   %edi
f0102811:	6a 24                	push   $0x24
f0102813:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102816:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102819:	b8 0c 47 10 f0       	mov    $0xf010470c,%eax
f010281e:	e8 39 fe ff ff       	call   f010265c <stab_binsearch>

	if (lfun <= rfun) {
f0102823:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102826:	83 c4 10             	add    $0x10,%esp
f0102829:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010282c:	7f 31                	jg     f010285f <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010282e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102831:	c1 e0 02             	shl    $0x2,%eax
f0102834:	8d 90 0c 47 10 f0    	lea    -0xfefb8f4(%eax),%edx
f010283a:	8b 88 0c 47 10 f0    	mov    -0xfefb8f4(%eax),%ecx
f0102840:	b8 72 bc 10 f0       	mov    $0xf010bc72,%eax
f0102845:	2d fd 9e 10 f0       	sub    $0xf0109efd,%eax
f010284a:	39 c1                	cmp    %eax,%ecx
f010284c:	73 09                	jae    f0102857 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010284e:	81 c1 fd 9e 10 f0    	add    $0xf0109efd,%ecx
f0102854:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102857:	8b 42 08             	mov    0x8(%edx),%eax
f010285a:	89 46 10             	mov    %eax,0x10(%esi)
f010285d:	eb 06                	jmp    f0102865 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010285f:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102862:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102865:	83 ec 08             	sub    $0x8,%esp
f0102868:	6a 3a                	push   $0x3a
f010286a:	ff 76 08             	pushl  0x8(%esi)
f010286d:	e8 a3 08 00 00       	call   f0103115 <strfind>
f0102872:	2b 46 08             	sub    0x8(%esi),%eax
f0102875:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102878:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010287b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010287e:	8d 04 85 0c 47 10 f0 	lea    -0xfefb8f4(,%eax,4),%eax
f0102885:	83 c4 10             	add    $0x10,%esp
f0102888:	eb 06                	jmp    f0102890 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010288a:	83 eb 01             	sub    $0x1,%ebx
f010288d:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102890:	39 fb                	cmp    %edi,%ebx
f0102892:	7c 34                	jl     f01028c8 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0102894:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0102898:	80 fa 84             	cmp    $0x84,%dl
f010289b:	74 0b                	je     f01028a8 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010289d:	80 fa 64             	cmp    $0x64,%dl
f01028a0:	75 e8                	jne    f010288a <debuginfo_eip+0x138>
f01028a2:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01028a6:	74 e2                	je     f010288a <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01028a8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028ab:	8b 14 85 0c 47 10 f0 	mov    -0xfefb8f4(,%eax,4),%edx
f01028b2:	b8 72 bc 10 f0       	mov    $0xf010bc72,%eax
f01028b7:	2d fd 9e 10 f0       	sub    $0xf0109efd,%eax
f01028bc:	39 c2                	cmp    %eax,%edx
f01028be:	73 08                	jae    f01028c8 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01028c0:	81 c2 fd 9e 10 f0    	add    $0xf0109efd,%edx
f01028c6:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028c8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01028cb:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028ce:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028d3:	39 cb                	cmp    %ecx,%ebx
f01028d5:	7d 44                	jge    f010291b <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f01028d7:	8d 53 01             	lea    0x1(%ebx),%edx
f01028da:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028dd:	8d 04 85 0c 47 10 f0 	lea    -0xfefb8f4(,%eax,4),%eax
f01028e4:	eb 07                	jmp    f01028ed <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01028e6:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01028ea:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01028ed:	39 ca                	cmp    %ecx,%edx
f01028ef:	74 25                	je     f0102916 <debuginfo_eip+0x1c4>
f01028f1:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01028f4:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01028f8:	74 ec                	je     f01028e6 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01028ff:	eb 1a                	jmp    f010291b <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102901:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102906:	eb 13                	jmp    f010291b <debuginfo_eip+0x1c9>
f0102908:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010290d:	eb 0c                	jmp    f010291b <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010290f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102914:	eb 05                	jmp    f010291b <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102916:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010291b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010291e:	5b                   	pop    %ebx
f010291f:	5e                   	pop    %esi
f0102920:	5f                   	pop    %edi
f0102921:	5d                   	pop    %ebp
f0102922:	c3                   	ret    

f0102923 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102923:	55                   	push   %ebp
f0102924:	89 e5                	mov    %esp,%ebp
f0102926:	57                   	push   %edi
f0102927:	56                   	push   %esi
f0102928:	53                   	push   %ebx
f0102929:	83 ec 1c             	sub    $0x1c,%esp
f010292c:	89 c7                	mov    %eax,%edi
f010292e:	89 d6                	mov    %edx,%esi
f0102930:	8b 45 08             	mov    0x8(%ebp),%eax
f0102933:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102936:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102939:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010293c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010293f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102944:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102947:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010294a:	39 d3                	cmp    %edx,%ebx
f010294c:	72 05                	jb     f0102953 <printnum+0x30>
f010294e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102951:	77 45                	ja     f0102998 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102953:	83 ec 0c             	sub    $0xc,%esp
f0102956:	ff 75 18             	pushl  0x18(%ebp)
f0102959:	8b 45 14             	mov    0x14(%ebp),%eax
f010295c:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010295f:	53                   	push   %ebx
f0102960:	ff 75 10             	pushl  0x10(%ebp)
f0102963:	83 ec 08             	sub    $0x8,%esp
f0102966:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102969:	ff 75 e0             	pushl  -0x20(%ebp)
f010296c:	ff 75 dc             	pushl  -0x24(%ebp)
f010296f:	ff 75 d8             	pushl  -0x28(%ebp)
f0102972:	e8 c9 09 00 00       	call   f0103340 <__udivdi3>
f0102977:	83 c4 18             	add    $0x18,%esp
f010297a:	52                   	push   %edx
f010297b:	50                   	push   %eax
f010297c:	89 f2                	mov    %esi,%edx
f010297e:	89 f8                	mov    %edi,%eax
f0102980:	e8 9e ff ff ff       	call   f0102923 <printnum>
f0102985:	83 c4 20             	add    $0x20,%esp
f0102988:	eb 18                	jmp    f01029a2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010298a:	83 ec 08             	sub    $0x8,%esp
f010298d:	56                   	push   %esi
f010298e:	ff 75 18             	pushl  0x18(%ebp)
f0102991:	ff d7                	call   *%edi
f0102993:	83 c4 10             	add    $0x10,%esp
f0102996:	eb 03                	jmp    f010299b <printnum+0x78>
f0102998:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010299b:	83 eb 01             	sub    $0x1,%ebx
f010299e:	85 db                	test   %ebx,%ebx
f01029a0:	7f e8                	jg     f010298a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01029a2:	83 ec 08             	sub    $0x8,%esp
f01029a5:	56                   	push   %esi
f01029a6:	83 ec 04             	sub    $0x4,%esp
f01029a9:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029ac:	ff 75 e0             	pushl  -0x20(%ebp)
f01029af:	ff 75 dc             	pushl  -0x24(%ebp)
f01029b2:	ff 75 d8             	pushl  -0x28(%ebp)
f01029b5:	e8 b6 0a 00 00       	call   f0103470 <__umoddi3>
f01029ba:	83 c4 14             	add    $0x14,%esp
f01029bd:	0f be 80 fd 44 10 f0 	movsbl -0xfefbb03(%eax),%eax
f01029c4:	50                   	push   %eax
f01029c5:	ff d7                	call   *%edi
}
f01029c7:	83 c4 10             	add    $0x10,%esp
f01029ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029cd:	5b                   	pop    %ebx
f01029ce:	5e                   	pop    %esi
f01029cf:	5f                   	pop    %edi
f01029d0:	5d                   	pop    %ebp
f01029d1:	c3                   	ret    

f01029d2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01029d2:	55                   	push   %ebp
f01029d3:	89 e5                	mov    %esp,%ebp
f01029d5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01029d8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01029dc:	8b 10                	mov    (%eax),%edx
f01029de:	3b 50 04             	cmp    0x4(%eax),%edx
f01029e1:	73 0a                	jae    f01029ed <sprintputch+0x1b>
		*b->buf++ = ch;
f01029e3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01029e6:	89 08                	mov    %ecx,(%eax)
f01029e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01029eb:	88 02                	mov    %al,(%edx)
}
f01029ed:	5d                   	pop    %ebp
f01029ee:	c3                   	ret    

f01029ef <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01029ef:	55                   	push   %ebp
f01029f0:	89 e5                	mov    %esp,%ebp
f01029f2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01029f5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01029f8:	50                   	push   %eax
f01029f9:	ff 75 10             	pushl  0x10(%ebp)
f01029fc:	ff 75 0c             	pushl  0xc(%ebp)
f01029ff:	ff 75 08             	pushl  0x8(%ebp)
f0102a02:	e8 05 00 00 00       	call   f0102a0c <vprintfmt>
	va_end(ap);
}
f0102a07:	83 c4 10             	add    $0x10,%esp
f0102a0a:	c9                   	leave  
f0102a0b:	c3                   	ret    

f0102a0c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a0c:	55                   	push   %ebp
f0102a0d:	89 e5                	mov    %esp,%ebp
f0102a0f:	57                   	push   %edi
f0102a10:	56                   	push   %esi
f0102a11:	53                   	push   %ebx
f0102a12:	83 ec 2c             	sub    $0x2c,%esp
f0102a15:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a18:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a1b:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102a1e:	eb 12                	jmp    f0102a32 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102a20:	85 c0                	test   %eax,%eax
f0102a22:	0f 84 42 04 00 00    	je     f0102e6a <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102a28:	83 ec 08             	sub    $0x8,%esp
f0102a2b:	53                   	push   %ebx
f0102a2c:	50                   	push   %eax
f0102a2d:	ff d6                	call   *%esi
f0102a2f:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102a32:	83 c7 01             	add    $0x1,%edi
f0102a35:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102a39:	83 f8 25             	cmp    $0x25,%eax
f0102a3c:	75 e2                	jne    f0102a20 <vprintfmt+0x14>
f0102a3e:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102a42:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102a49:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102a50:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102a57:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102a5c:	eb 07                	jmp    f0102a65 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102a61:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a65:	8d 47 01             	lea    0x1(%edi),%eax
f0102a68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a6b:	0f b6 07             	movzbl (%edi),%eax
f0102a6e:	0f b6 d0             	movzbl %al,%edx
f0102a71:	83 e8 23             	sub    $0x23,%eax
f0102a74:	3c 55                	cmp    $0x55,%al
f0102a76:	0f 87 d3 03 00 00    	ja     f0102e4f <vprintfmt+0x443>
f0102a7c:	0f b6 c0             	movzbl %al,%eax
f0102a7f:	ff 24 85 88 45 10 f0 	jmp    *-0xfefba78(,%eax,4)
f0102a86:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102a89:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102a8d:	eb d6                	jmp    f0102a65 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a92:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a97:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102a9a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102a9d:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102aa1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102aa4:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102aa7:	83 f9 09             	cmp    $0x9,%ecx
f0102aaa:	77 3f                	ja     f0102aeb <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102aac:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102aaf:	eb e9                	jmp    f0102a9a <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102ab1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ab4:	8b 00                	mov    (%eax),%eax
f0102ab6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102ab9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102abc:	8d 40 04             	lea    0x4(%eax),%eax
f0102abf:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ac2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102ac5:	eb 2a                	jmp    f0102af1 <vprintfmt+0xe5>
f0102ac7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102aca:	85 c0                	test   %eax,%eax
f0102acc:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ad1:	0f 49 d0             	cmovns %eax,%edx
f0102ad4:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ad7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ada:	eb 89                	jmp    f0102a65 <vprintfmt+0x59>
f0102adc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102adf:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102ae6:	e9 7a ff ff ff       	jmp    f0102a65 <vprintfmt+0x59>
f0102aeb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102aee:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102af1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102af5:	0f 89 6a ff ff ff    	jns    f0102a65 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102afb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102afe:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b01:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b08:	e9 58 ff ff ff       	jmp    f0102a65 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102b0d:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b10:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102b13:	e9 4d ff ff ff       	jmp    f0102a65 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b1b:	8d 78 04             	lea    0x4(%eax),%edi
f0102b1e:	83 ec 08             	sub    $0x8,%esp
f0102b21:	53                   	push   %ebx
f0102b22:	ff 30                	pushl  (%eax)
f0102b24:	ff d6                	call   *%esi
			break;
f0102b26:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b29:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102b2f:	e9 fe fe ff ff       	jmp    f0102a32 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b34:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b37:	8d 78 04             	lea    0x4(%eax),%edi
f0102b3a:	8b 00                	mov    (%eax),%eax
f0102b3c:	99                   	cltd   
f0102b3d:	31 d0                	xor    %edx,%eax
f0102b3f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102b41:	83 f8 06             	cmp    $0x6,%eax
f0102b44:	7f 0b                	jg     f0102b51 <vprintfmt+0x145>
f0102b46:	8b 14 85 e0 46 10 f0 	mov    -0xfefb920(,%eax,4),%edx
f0102b4d:	85 d2                	test   %edx,%edx
f0102b4f:	75 1b                	jne    f0102b6c <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102b51:	50                   	push   %eax
f0102b52:	68 15 45 10 f0       	push   $0xf0104515
f0102b57:	53                   	push   %ebx
f0102b58:	56                   	push   %esi
f0102b59:	e8 91 fe ff ff       	call   f01029ef <printfmt>
f0102b5e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b61:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102b67:	e9 c6 fe ff ff       	jmp    f0102a32 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102b6c:	52                   	push   %edx
f0102b6d:	68 c4 3a 10 f0       	push   $0xf0103ac4
f0102b72:	53                   	push   %ebx
f0102b73:	56                   	push   %esi
f0102b74:	e8 76 fe ff ff       	call   f01029ef <printfmt>
f0102b79:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b7c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b82:	e9 ab fe ff ff       	jmp    f0102a32 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102b87:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b8a:	83 c0 04             	add    $0x4,%eax
f0102b8d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102b90:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b93:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102b95:	85 ff                	test   %edi,%edi
f0102b97:	b8 0e 45 10 f0       	mov    $0xf010450e,%eax
f0102b9c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102b9f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ba3:	0f 8e 94 00 00 00    	jle    f0102c3d <vprintfmt+0x231>
f0102ba9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102bad:	0f 84 98 00 00 00    	je     f0102c4b <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bb3:	83 ec 08             	sub    $0x8,%esp
f0102bb6:	ff 75 d0             	pushl  -0x30(%ebp)
f0102bb9:	57                   	push   %edi
f0102bba:	e8 0c 04 00 00       	call   f0102fcb <strnlen>
f0102bbf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102bc2:	29 c1                	sub    %eax,%ecx
f0102bc4:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102bc7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102bca:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102bce:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bd1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102bd4:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bd6:	eb 0f                	jmp    f0102be7 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102bd8:	83 ec 08             	sub    $0x8,%esp
f0102bdb:	53                   	push   %ebx
f0102bdc:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bdf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102be1:	83 ef 01             	sub    $0x1,%edi
f0102be4:	83 c4 10             	add    $0x10,%esp
f0102be7:	85 ff                	test   %edi,%edi
f0102be9:	7f ed                	jg     f0102bd8 <vprintfmt+0x1cc>
f0102beb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102bee:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102bf1:	85 c9                	test   %ecx,%ecx
f0102bf3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bf8:	0f 49 c1             	cmovns %ecx,%eax
f0102bfb:	29 c1                	sub    %eax,%ecx
f0102bfd:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c00:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c03:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c06:	89 cb                	mov    %ecx,%ebx
f0102c08:	eb 4d                	jmp    f0102c57 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c0a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c0e:	74 1b                	je     f0102c2b <vprintfmt+0x21f>
f0102c10:	0f be c0             	movsbl %al,%eax
f0102c13:	83 e8 20             	sub    $0x20,%eax
f0102c16:	83 f8 5e             	cmp    $0x5e,%eax
f0102c19:	76 10                	jbe    f0102c2b <vprintfmt+0x21f>
					putch('?', putdat);
f0102c1b:	83 ec 08             	sub    $0x8,%esp
f0102c1e:	ff 75 0c             	pushl  0xc(%ebp)
f0102c21:	6a 3f                	push   $0x3f
f0102c23:	ff 55 08             	call   *0x8(%ebp)
f0102c26:	83 c4 10             	add    $0x10,%esp
f0102c29:	eb 0d                	jmp    f0102c38 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102c2b:	83 ec 08             	sub    $0x8,%esp
f0102c2e:	ff 75 0c             	pushl  0xc(%ebp)
f0102c31:	52                   	push   %edx
f0102c32:	ff 55 08             	call   *0x8(%ebp)
f0102c35:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c38:	83 eb 01             	sub    $0x1,%ebx
f0102c3b:	eb 1a                	jmp    f0102c57 <vprintfmt+0x24b>
f0102c3d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c40:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c43:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c46:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c49:	eb 0c                	jmp    f0102c57 <vprintfmt+0x24b>
f0102c4b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c4e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c51:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c54:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c57:	83 c7 01             	add    $0x1,%edi
f0102c5a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c5e:	0f be d0             	movsbl %al,%edx
f0102c61:	85 d2                	test   %edx,%edx
f0102c63:	74 23                	je     f0102c88 <vprintfmt+0x27c>
f0102c65:	85 f6                	test   %esi,%esi
f0102c67:	78 a1                	js     f0102c0a <vprintfmt+0x1fe>
f0102c69:	83 ee 01             	sub    $0x1,%esi
f0102c6c:	79 9c                	jns    f0102c0a <vprintfmt+0x1fe>
f0102c6e:	89 df                	mov    %ebx,%edi
f0102c70:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c73:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c76:	eb 18                	jmp    f0102c90 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102c78:	83 ec 08             	sub    $0x8,%esp
f0102c7b:	53                   	push   %ebx
f0102c7c:	6a 20                	push   $0x20
f0102c7e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102c80:	83 ef 01             	sub    $0x1,%edi
f0102c83:	83 c4 10             	add    $0x10,%esp
f0102c86:	eb 08                	jmp    f0102c90 <vprintfmt+0x284>
f0102c88:	89 df                	mov    %ebx,%edi
f0102c8a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c8d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c90:	85 ff                	test   %edi,%edi
f0102c92:	7f e4                	jg     f0102c78 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c94:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102c97:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c9d:	e9 90 fd ff ff       	jmp    f0102a32 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ca2:	83 f9 01             	cmp    $0x1,%ecx
f0102ca5:	7e 19                	jle    f0102cc0 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102ca7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102caa:	8b 50 04             	mov    0x4(%eax),%edx
f0102cad:	8b 00                	mov    (%eax),%eax
f0102caf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cb2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102cb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb8:	8d 40 08             	lea    0x8(%eax),%eax
f0102cbb:	89 45 14             	mov    %eax,0x14(%ebp)
f0102cbe:	eb 38                	jmp    f0102cf8 <vprintfmt+0x2ec>
	else if (lflag)
f0102cc0:	85 c9                	test   %ecx,%ecx
f0102cc2:	74 1b                	je     f0102cdf <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102cc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc7:	8b 00                	mov    (%eax),%eax
f0102cc9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ccc:	89 c1                	mov    %eax,%ecx
f0102cce:	c1 f9 1f             	sar    $0x1f,%ecx
f0102cd1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102cd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd7:	8d 40 04             	lea    0x4(%eax),%eax
f0102cda:	89 45 14             	mov    %eax,0x14(%ebp)
f0102cdd:	eb 19                	jmp    f0102cf8 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102cdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ce2:	8b 00                	mov    (%eax),%eax
f0102ce4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ce7:	89 c1                	mov    %eax,%ecx
f0102ce9:	c1 f9 1f             	sar    $0x1f,%ecx
f0102cec:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102cef:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf2:	8d 40 04             	lea    0x4(%eax),%eax
f0102cf5:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102cf8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102cfb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102cfe:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d03:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d07:	0f 89 0e 01 00 00    	jns    f0102e1b <vprintfmt+0x40f>
				putch('-', putdat);
f0102d0d:	83 ec 08             	sub    $0x8,%esp
f0102d10:	53                   	push   %ebx
f0102d11:	6a 2d                	push   $0x2d
f0102d13:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d15:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d18:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102d1b:	f7 da                	neg    %edx
f0102d1d:	83 d1 00             	adc    $0x0,%ecx
f0102d20:	f7 d9                	neg    %ecx
f0102d22:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d25:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d2a:	e9 ec 00 00 00       	jmp    f0102e1b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d2f:	83 f9 01             	cmp    $0x1,%ecx
f0102d32:	7e 18                	jle    f0102d4c <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102d34:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d37:	8b 10                	mov    (%eax),%edx
f0102d39:	8b 48 04             	mov    0x4(%eax),%ecx
f0102d3c:	8d 40 08             	lea    0x8(%eax),%eax
f0102d3f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d42:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d47:	e9 cf 00 00 00       	jmp    f0102e1b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102d4c:	85 c9                	test   %ecx,%ecx
f0102d4e:	74 1a                	je     f0102d6a <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102d50:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d53:	8b 10                	mov    (%eax),%edx
f0102d55:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d5a:	8d 40 04             	lea    0x4(%eax),%eax
f0102d5d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d60:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d65:	e9 b1 00 00 00       	jmp    f0102e1b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102d6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d6d:	8b 10                	mov    (%eax),%edx
f0102d6f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d74:	8d 40 04             	lea    0x4(%eax),%eax
f0102d77:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d7a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d7f:	e9 97 00 00 00       	jmp    f0102e1b <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102d84:	83 ec 08             	sub    $0x8,%esp
f0102d87:	53                   	push   %ebx
f0102d88:	6a 58                	push   $0x58
f0102d8a:	ff d6                	call   *%esi
			putch('X', putdat);
f0102d8c:	83 c4 08             	add    $0x8,%esp
f0102d8f:	53                   	push   %ebx
f0102d90:	6a 58                	push   $0x58
f0102d92:	ff d6                	call   *%esi
			putch('X', putdat);
f0102d94:	83 c4 08             	add    $0x8,%esp
f0102d97:	53                   	push   %ebx
f0102d98:	6a 58                	push   $0x58
f0102d9a:	ff d6                	call   *%esi
			break;
f0102d9c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102da2:	e9 8b fc ff ff       	jmp    f0102a32 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102da7:	83 ec 08             	sub    $0x8,%esp
f0102daa:	53                   	push   %ebx
f0102dab:	6a 30                	push   $0x30
f0102dad:	ff d6                	call   *%esi
			putch('x', putdat);
f0102daf:	83 c4 08             	add    $0x8,%esp
f0102db2:	53                   	push   %ebx
f0102db3:	6a 78                	push   $0x78
f0102db5:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102db7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dba:	8b 10                	mov    (%eax),%edx
f0102dbc:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102dc1:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102dc4:	8d 40 04             	lea    0x4(%eax),%eax
f0102dc7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102dca:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102dcf:	eb 4a                	jmp    f0102e1b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dd1:	83 f9 01             	cmp    $0x1,%ecx
f0102dd4:	7e 15                	jle    f0102deb <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102dd6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd9:	8b 10                	mov    (%eax),%edx
f0102ddb:	8b 48 04             	mov    0x4(%eax),%ecx
f0102dde:	8d 40 08             	lea    0x8(%eax),%eax
f0102de1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102de4:	b8 10 00 00 00       	mov    $0x10,%eax
f0102de9:	eb 30                	jmp    f0102e1b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102deb:	85 c9                	test   %ecx,%ecx
f0102ded:	74 17                	je     f0102e06 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102def:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df2:	8b 10                	mov    (%eax),%edx
f0102df4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102df9:	8d 40 04             	lea    0x4(%eax),%eax
f0102dfc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102dff:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e04:	eb 15                	jmp    f0102e1b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e06:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e09:	8b 10                	mov    (%eax),%edx
f0102e0b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e10:	8d 40 04             	lea    0x4(%eax),%eax
f0102e13:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e16:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e1b:	83 ec 0c             	sub    $0xc,%esp
f0102e1e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e22:	57                   	push   %edi
f0102e23:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e26:	50                   	push   %eax
f0102e27:	51                   	push   %ecx
f0102e28:	52                   	push   %edx
f0102e29:	89 da                	mov    %ebx,%edx
f0102e2b:	89 f0                	mov    %esi,%eax
f0102e2d:	e8 f1 fa ff ff       	call   f0102923 <printnum>
			break;
f0102e32:	83 c4 20             	add    $0x20,%esp
f0102e35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e38:	e9 f5 fb ff ff       	jmp    f0102a32 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e3d:	83 ec 08             	sub    $0x8,%esp
f0102e40:	53                   	push   %ebx
f0102e41:	52                   	push   %edx
f0102e42:	ff d6                	call   *%esi
			break;
f0102e44:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e4a:	e9 e3 fb ff ff       	jmp    f0102a32 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e4f:	83 ec 08             	sub    $0x8,%esp
f0102e52:	53                   	push   %ebx
f0102e53:	6a 25                	push   $0x25
f0102e55:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e57:	83 c4 10             	add    $0x10,%esp
f0102e5a:	eb 03                	jmp    f0102e5f <vprintfmt+0x453>
f0102e5c:	83 ef 01             	sub    $0x1,%edi
f0102e5f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e63:	75 f7                	jne    f0102e5c <vprintfmt+0x450>
f0102e65:	e9 c8 fb ff ff       	jmp    f0102a32 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e6d:	5b                   	pop    %ebx
f0102e6e:	5e                   	pop    %esi
f0102e6f:	5f                   	pop    %edi
f0102e70:	5d                   	pop    %ebp
f0102e71:	c3                   	ret    

f0102e72 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e72:	55                   	push   %ebp
f0102e73:	89 e5                	mov    %esp,%ebp
f0102e75:	83 ec 18             	sub    $0x18,%esp
f0102e78:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e7b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102e7e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e81:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102e85:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102e88:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102e8f:	85 c0                	test   %eax,%eax
f0102e91:	74 26                	je     f0102eb9 <vsnprintf+0x47>
f0102e93:	85 d2                	test   %edx,%edx
f0102e95:	7e 22                	jle    f0102eb9 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e97:	ff 75 14             	pushl  0x14(%ebp)
f0102e9a:	ff 75 10             	pushl  0x10(%ebp)
f0102e9d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102ea0:	50                   	push   %eax
f0102ea1:	68 d2 29 10 f0       	push   $0xf01029d2
f0102ea6:	e8 61 fb ff ff       	call   f0102a0c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102eab:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102eae:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eb4:	83 c4 10             	add    $0x10,%esp
f0102eb7:	eb 05                	jmp    f0102ebe <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102eb9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102ebe:	c9                   	leave  
f0102ebf:	c3                   	ret    

f0102ec0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ec0:	55                   	push   %ebp
f0102ec1:	89 e5                	mov    %esp,%ebp
f0102ec3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102ec6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102ec9:	50                   	push   %eax
f0102eca:	ff 75 10             	pushl  0x10(%ebp)
f0102ecd:	ff 75 0c             	pushl  0xc(%ebp)
f0102ed0:	ff 75 08             	pushl  0x8(%ebp)
f0102ed3:	e8 9a ff ff ff       	call   f0102e72 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102ed8:	c9                   	leave  
f0102ed9:	c3                   	ret    

f0102eda <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102eda:	55                   	push   %ebp
f0102edb:	89 e5                	mov    %esp,%ebp
f0102edd:	57                   	push   %edi
f0102ede:	56                   	push   %esi
f0102edf:	53                   	push   %ebx
f0102ee0:	83 ec 0c             	sub    $0xc,%esp
f0102ee3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102ee6:	85 c0                	test   %eax,%eax
f0102ee8:	74 11                	je     f0102efb <readline+0x21>
		cprintf("%s", prompt);
f0102eea:	83 ec 08             	sub    $0x8,%esp
f0102eed:	50                   	push   %eax
f0102eee:	68 c4 3a 10 f0       	push   $0xf0103ac4
f0102ef3:	e8 50 f7 ff ff       	call   f0102648 <cprintf>
f0102ef8:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102efb:	83 ec 0c             	sub    $0xc,%esp
f0102efe:	6a 00                	push   $0x0
f0102f00:	e8 1c d7 ff ff       	call   f0100621 <iscons>
f0102f05:	89 c7                	mov    %eax,%edi
f0102f07:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f0a:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f0f:	e8 fc d6 ff ff       	call   f0100610 <getchar>
f0102f14:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f16:	85 c0                	test   %eax,%eax
f0102f18:	79 18                	jns    f0102f32 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f1a:	83 ec 08             	sub    $0x8,%esp
f0102f1d:	50                   	push   %eax
f0102f1e:	68 fc 46 10 f0       	push   $0xf01046fc
f0102f23:	e8 20 f7 ff ff       	call   f0102648 <cprintf>
			return NULL;
f0102f28:	83 c4 10             	add    $0x10,%esp
f0102f2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f30:	eb 79                	jmp    f0102fab <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f32:	83 f8 08             	cmp    $0x8,%eax
f0102f35:	0f 94 c2             	sete   %dl
f0102f38:	83 f8 7f             	cmp    $0x7f,%eax
f0102f3b:	0f 94 c0             	sete   %al
f0102f3e:	08 c2                	or     %al,%dl
f0102f40:	74 1a                	je     f0102f5c <readline+0x82>
f0102f42:	85 f6                	test   %esi,%esi
f0102f44:	7e 16                	jle    f0102f5c <readline+0x82>
			if (echoing)
f0102f46:	85 ff                	test   %edi,%edi
f0102f48:	74 0d                	je     f0102f57 <readline+0x7d>
				cputchar('\b');
f0102f4a:	83 ec 0c             	sub    $0xc,%esp
f0102f4d:	6a 08                	push   $0x8
f0102f4f:	e8 ac d6 ff ff       	call   f0100600 <cputchar>
f0102f54:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f57:	83 ee 01             	sub    $0x1,%esi
f0102f5a:	eb b3                	jmp    f0102f0f <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f5c:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f5f:	7e 23                	jle    f0102f84 <readline+0xaa>
f0102f61:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f67:	7f 1b                	jg     f0102f84 <readline+0xaa>
			if (echoing)
f0102f69:	85 ff                	test   %edi,%edi
f0102f6b:	74 0c                	je     f0102f79 <readline+0x9f>
				cputchar(c);
f0102f6d:	83 ec 0c             	sub    $0xc,%esp
f0102f70:	53                   	push   %ebx
f0102f71:	e8 8a d6 ff ff       	call   f0100600 <cputchar>
f0102f76:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f79:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0102f7f:	8d 76 01             	lea    0x1(%esi),%esi
f0102f82:	eb 8b                	jmp    f0102f0f <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102f84:	83 fb 0a             	cmp    $0xa,%ebx
f0102f87:	74 05                	je     f0102f8e <readline+0xb4>
f0102f89:	83 fb 0d             	cmp    $0xd,%ebx
f0102f8c:	75 81                	jne    f0102f0f <readline+0x35>
			if (echoing)
f0102f8e:	85 ff                	test   %edi,%edi
f0102f90:	74 0d                	je     f0102f9f <readline+0xc5>
				cputchar('\n');
f0102f92:	83 ec 0c             	sub    $0xc,%esp
f0102f95:	6a 0a                	push   $0xa
f0102f97:	e8 64 d6 ff ff       	call   f0100600 <cputchar>
f0102f9c:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f9f:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102fa6:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0102fab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fae:	5b                   	pop    %ebx
f0102faf:	5e                   	pop    %esi
f0102fb0:	5f                   	pop    %edi
f0102fb1:	5d                   	pop    %ebp
f0102fb2:	c3                   	ret    

f0102fb3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102fb3:	55                   	push   %ebp
f0102fb4:	89 e5                	mov    %esp,%ebp
f0102fb6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fbe:	eb 03                	jmp    f0102fc3 <strlen+0x10>
		n++;
f0102fc0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fc3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102fc7:	75 f7                	jne    f0102fc0 <strlen+0xd>
		n++;
	return n;
}
f0102fc9:	5d                   	pop    %ebp
f0102fca:	c3                   	ret    

f0102fcb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102fcb:	55                   	push   %ebp
f0102fcc:	89 e5                	mov    %esp,%ebp
f0102fce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fd4:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fd9:	eb 03                	jmp    f0102fde <strnlen+0x13>
		n++;
f0102fdb:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fde:	39 c2                	cmp    %eax,%edx
f0102fe0:	74 08                	je     f0102fea <strnlen+0x1f>
f0102fe2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102fe6:	75 f3                	jne    f0102fdb <strnlen+0x10>
f0102fe8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102fea:	5d                   	pop    %ebp
f0102feb:	c3                   	ret    

f0102fec <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102fec:	55                   	push   %ebp
f0102fed:	89 e5                	mov    %esp,%ebp
f0102fef:	53                   	push   %ebx
f0102ff0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102ff6:	89 c2                	mov    %eax,%edx
f0102ff8:	83 c2 01             	add    $0x1,%edx
f0102ffb:	83 c1 01             	add    $0x1,%ecx
f0102ffe:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103002:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103005:	84 db                	test   %bl,%bl
f0103007:	75 ef                	jne    f0102ff8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103009:	5b                   	pop    %ebx
f010300a:	5d                   	pop    %ebp
f010300b:	c3                   	ret    

f010300c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010300c:	55                   	push   %ebp
f010300d:	89 e5                	mov    %esp,%ebp
f010300f:	53                   	push   %ebx
f0103010:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103013:	53                   	push   %ebx
f0103014:	e8 9a ff ff ff       	call   f0102fb3 <strlen>
f0103019:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010301c:	ff 75 0c             	pushl  0xc(%ebp)
f010301f:	01 d8                	add    %ebx,%eax
f0103021:	50                   	push   %eax
f0103022:	e8 c5 ff ff ff       	call   f0102fec <strcpy>
	return dst;
}
f0103027:	89 d8                	mov    %ebx,%eax
f0103029:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010302c:	c9                   	leave  
f010302d:	c3                   	ret    

f010302e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010302e:	55                   	push   %ebp
f010302f:	89 e5                	mov    %esp,%ebp
f0103031:	56                   	push   %esi
f0103032:	53                   	push   %ebx
f0103033:	8b 75 08             	mov    0x8(%ebp),%esi
f0103036:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103039:	89 f3                	mov    %esi,%ebx
f010303b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010303e:	89 f2                	mov    %esi,%edx
f0103040:	eb 0f                	jmp    f0103051 <strncpy+0x23>
		*dst++ = *src;
f0103042:	83 c2 01             	add    $0x1,%edx
f0103045:	0f b6 01             	movzbl (%ecx),%eax
f0103048:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010304b:	80 39 01             	cmpb   $0x1,(%ecx)
f010304e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103051:	39 da                	cmp    %ebx,%edx
f0103053:	75 ed                	jne    f0103042 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103055:	89 f0                	mov    %esi,%eax
f0103057:	5b                   	pop    %ebx
f0103058:	5e                   	pop    %esi
f0103059:	5d                   	pop    %ebp
f010305a:	c3                   	ret    

f010305b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010305b:	55                   	push   %ebp
f010305c:	89 e5                	mov    %esp,%ebp
f010305e:	56                   	push   %esi
f010305f:	53                   	push   %ebx
f0103060:	8b 75 08             	mov    0x8(%ebp),%esi
f0103063:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103066:	8b 55 10             	mov    0x10(%ebp),%edx
f0103069:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010306b:	85 d2                	test   %edx,%edx
f010306d:	74 21                	je     f0103090 <strlcpy+0x35>
f010306f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103073:	89 f2                	mov    %esi,%edx
f0103075:	eb 09                	jmp    f0103080 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103077:	83 c2 01             	add    $0x1,%edx
f010307a:	83 c1 01             	add    $0x1,%ecx
f010307d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103080:	39 c2                	cmp    %eax,%edx
f0103082:	74 09                	je     f010308d <strlcpy+0x32>
f0103084:	0f b6 19             	movzbl (%ecx),%ebx
f0103087:	84 db                	test   %bl,%bl
f0103089:	75 ec                	jne    f0103077 <strlcpy+0x1c>
f010308b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010308d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103090:	29 f0                	sub    %esi,%eax
}
f0103092:	5b                   	pop    %ebx
f0103093:	5e                   	pop    %esi
f0103094:	5d                   	pop    %ebp
f0103095:	c3                   	ret    

f0103096 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103096:	55                   	push   %ebp
f0103097:	89 e5                	mov    %esp,%ebp
f0103099:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010309c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010309f:	eb 06                	jmp    f01030a7 <strcmp+0x11>
		p++, q++;
f01030a1:	83 c1 01             	add    $0x1,%ecx
f01030a4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01030a7:	0f b6 01             	movzbl (%ecx),%eax
f01030aa:	84 c0                	test   %al,%al
f01030ac:	74 04                	je     f01030b2 <strcmp+0x1c>
f01030ae:	3a 02                	cmp    (%edx),%al
f01030b0:	74 ef                	je     f01030a1 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01030b2:	0f b6 c0             	movzbl %al,%eax
f01030b5:	0f b6 12             	movzbl (%edx),%edx
f01030b8:	29 d0                	sub    %edx,%eax
}
f01030ba:	5d                   	pop    %ebp
f01030bb:	c3                   	ret    

f01030bc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01030bc:	55                   	push   %ebp
f01030bd:	89 e5                	mov    %esp,%ebp
f01030bf:	53                   	push   %ebx
f01030c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01030c3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030c6:	89 c3                	mov    %eax,%ebx
f01030c8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01030cb:	eb 06                	jmp    f01030d3 <strncmp+0x17>
		n--, p++, q++;
f01030cd:	83 c0 01             	add    $0x1,%eax
f01030d0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01030d3:	39 d8                	cmp    %ebx,%eax
f01030d5:	74 15                	je     f01030ec <strncmp+0x30>
f01030d7:	0f b6 08             	movzbl (%eax),%ecx
f01030da:	84 c9                	test   %cl,%cl
f01030dc:	74 04                	je     f01030e2 <strncmp+0x26>
f01030de:	3a 0a                	cmp    (%edx),%cl
f01030e0:	74 eb                	je     f01030cd <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01030e2:	0f b6 00             	movzbl (%eax),%eax
f01030e5:	0f b6 12             	movzbl (%edx),%edx
f01030e8:	29 d0                	sub    %edx,%eax
f01030ea:	eb 05                	jmp    f01030f1 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01030ec:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01030f1:	5b                   	pop    %ebx
f01030f2:	5d                   	pop    %ebp
f01030f3:	c3                   	ret    

f01030f4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01030f4:	55                   	push   %ebp
f01030f5:	89 e5                	mov    %esp,%ebp
f01030f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030fa:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030fe:	eb 07                	jmp    f0103107 <strchr+0x13>
		if (*s == c)
f0103100:	38 ca                	cmp    %cl,%dl
f0103102:	74 0f                	je     f0103113 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103104:	83 c0 01             	add    $0x1,%eax
f0103107:	0f b6 10             	movzbl (%eax),%edx
f010310a:	84 d2                	test   %dl,%dl
f010310c:	75 f2                	jne    f0103100 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010310e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103113:	5d                   	pop    %ebp
f0103114:	c3                   	ret    

f0103115 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103115:	55                   	push   %ebp
f0103116:	89 e5                	mov    %esp,%ebp
f0103118:	8b 45 08             	mov    0x8(%ebp),%eax
f010311b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010311f:	eb 03                	jmp    f0103124 <strfind+0xf>
f0103121:	83 c0 01             	add    $0x1,%eax
f0103124:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103127:	38 ca                	cmp    %cl,%dl
f0103129:	74 04                	je     f010312f <strfind+0x1a>
f010312b:	84 d2                	test   %dl,%dl
f010312d:	75 f2                	jne    f0103121 <strfind+0xc>
			break;
	return (char *) s;
}
f010312f:	5d                   	pop    %ebp
f0103130:	c3                   	ret    

f0103131 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103131:	55                   	push   %ebp
f0103132:	89 e5                	mov    %esp,%ebp
f0103134:	57                   	push   %edi
f0103135:	56                   	push   %esi
f0103136:	53                   	push   %ebx
f0103137:	8b 7d 08             	mov    0x8(%ebp),%edi
f010313a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010313d:	85 c9                	test   %ecx,%ecx
f010313f:	74 36                	je     f0103177 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103141:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103147:	75 28                	jne    f0103171 <memset+0x40>
f0103149:	f6 c1 03             	test   $0x3,%cl
f010314c:	75 23                	jne    f0103171 <memset+0x40>
		c &= 0xFF;
f010314e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103152:	89 d3                	mov    %edx,%ebx
f0103154:	c1 e3 08             	shl    $0x8,%ebx
f0103157:	89 d6                	mov    %edx,%esi
f0103159:	c1 e6 18             	shl    $0x18,%esi
f010315c:	89 d0                	mov    %edx,%eax
f010315e:	c1 e0 10             	shl    $0x10,%eax
f0103161:	09 f0                	or     %esi,%eax
f0103163:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103165:	89 d8                	mov    %ebx,%eax
f0103167:	09 d0                	or     %edx,%eax
f0103169:	c1 e9 02             	shr    $0x2,%ecx
f010316c:	fc                   	cld    
f010316d:	f3 ab                	rep stos %eax,%es:(%edi)
f010316f:	eb 06                	jmp    f0103177 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103171:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103174:	fc                   	cld    
f0103175:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103177:	89 f8                	mov    %edi,%eax
f0103179:	5b                   	pop    %ebx
f010317a:	5e                   	pop    %esi
f010317b:	5f                   	pop    %edi
f010317c:	5d                   	pop    %ebp
f010317d:	c3                   	ret    

f010317e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010317e:	55                   	push   %ebp
f010317f:	89 e5                	mov    %esp,%ebp
f0103181:	57                   	push   %edi
f0103182:	56                   	push   %esi
f0103183:	8b 45 08             	mov    0x8(%ebp),%eax
f0103186:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103189:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010318c:	39 c6                	cmp    %eax,%esi
f010318e:	73 35                	jae    f01031c5 <memmove+0x47>
f0103190:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103193:	39 d0                	cmp    %edx,%eax
f0103195:	73 2e                	jae    f01031c5 <memmove+0x47>
		s += n;
		d += n;
f0103197:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010319a:	89 d6                	mov    %edx,%esi
f010319c:	09 fe                	or     %edi,%esi
f010319e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01031a4:	75 13                	jne    f01031b9 <memmove+0x3b>
f01031a6:	f6 c1 03             	test   $0x3,%cl
f01031a9:	75 0e                	jne    f01031b9 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01031ab:	83 ef 04             	sub    $0x4,%edi
f01031ae:	8d 72 fc             	lea    -0x4(%edx),%esi
f01031b1:	c1 e9 02             	shr    $0x2,%ecx
f01031b4:	fd                   	std    
f01031b5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031b7:	eb 09                	jmp    f01031c2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01031b9:	83 ef 01             	sub    $0x1,%edi
f01031bc:	8d 72 ff             	lea    -0x1(%edx),%esi
f01031bf:	fd                   	std    
f01031c0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01031c2:	fc                   	cld    
f01031c3:	eb 1d                	jmp    f01031e2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031c5:	89 f2                	mov    %esi,%edx
f01031c7:	09 c2                	or     %eax,%edx
f01031c9:	f6 c2 03             	test   $0x3,%dl
f01031cc:	75 0f                	jne    f01031dd <memmove+0x5f>
f01031ce:	f6 c1 03             	test   $0x3,%cl
f01031d1:	75 0a                	jne    f01031dd <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01031d3:	c1 e9 02             	shr    $0x2,%ecx
f01031d6:	89 c7                	mov    %eax,%edi
f01031d8:	fc                   	cld    
f01031d9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031db:	eb 05                	jmp    f01031e2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01031dd:	89 c7                	mov    %eax,%edi
f01031df:	fc                   	cld    
f01031e0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01031e2:	5e                   	pop    %esi
f01031e3:	5f                   	pop    %edi
f01031e4:	5d                   	pop    %ebp
f01031e5:	c3                   	ret    

f01031e6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01031e6:	55                   	push   %ebp
f01031e7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01031e9:	ff 75 10             	pushl  0x10(%ebp)
f01031ec:	ff 75 0c             	pushl  0xc(%ebp)
f01031ef:	ff 75 08             	pushl  0x8(%ebp)
f01031f2:	e8 87 ff ff ff       	call   f010317e <memmove>
}
f01031f7:	c9                   	leave  
f01031f8:	c3                   	ret    

f01031f9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01031f9:	55                   	push   %ebp
f01031fa:	89 e5                	mov    %esp,%ebp
f01031fc:	56                   	push   %esi
f01031fd:	53                   	push   %ebx
f01031fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103201:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103204:	89 c6                	mov    %eax,%esi
f0103206:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103209:	eb 1a                	jmp    f0103225 <memcmp+0x2c>
		if (*s1 != *s2)
f010320b:	0f b6 08             	movzbl (%eax),%ecx
f010320e:	0f b6 1a             	movzbl (%edx),%ebx
f0103211:	38 d9                	cmp    %bl,%cl
f0103213:	74 0a                	je     f010321f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103215:	0f b6 c1             	movzbl %cl,%eax
f0103218:	0f b6 db             	movzbl %bl,%ebx
f010321b:	29 d8                	sub    %ebx,%eax
f010321d:	eb 0f                	jmp    f010322e <memcmp+0x35>
		s1++, s2++;
f010321f:	83 c0 01             	add    $0x1,%eax
f0103222:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103225:	39 f0                	cmp    %esi,%eax
f0103227:	75 e2                	jne    f010320b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103229:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010322e:	5b                   	pop    %ebx
f010322f:	5e                   	pop    %esi
f0103230:	5d                   	pop    %ebp
f0103231:	c3                   	ret    

f0103232 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103232:	55                   	push   %ebp
f0103233:	89 e5                	mov    %esp,%ebp
f0103235:	53                   	push   %ebx
f0103236:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103239:	89 c1                	mov    %eax,%ecx
f010323b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010323e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103242:	eb 0a                	jmp    f010324e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103244:	0f b6 10             	movzbl (%eax),%edx
f0103247:	39 da                	cmp    %ebx,%edx
f0103249:	74 07                	je     f0103252 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010324b:	83 c0 01             	add    $0x1,%eax
f010324e:	39 c8                	cmp    %ecx,%eax
f0103250:	72 f2                	jb     f0103244 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103252:	5b                   	pop    %ebx
f0103253:	5d                   	pop    %ebp
f0103254:	c3                   	ret    

f0103255 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103255:	55                   	push   %ebp
f0103256:	89 e5                	mov    %esp,%ebp
f0103258:	57                   	push   %edi
f0103259:	56                   	push   %esi
f010325a:	53                   	push   %ebx
f010325b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010325e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103261:	eb 03                	jmp    f0103266 <strtol+0x11>
		s++;
f0103263:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103266:	0f b6 01             	movzbl (%ecx),%eax
f0103269:	3c 20                	cmp    $0x20,%al
f010326b:	74 f6                	je     f0103263 <strtol+0xe>
f010326d:	3c 09                	cmp    $0x9,%al
f010326f:	74 f2                	je     f0103263 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103271:	3c 2b                	cmp    $0x2b,%al
f0103273:	75 0a                	jne    f010327f <strtol+0x2a>
		s++;
f0103275:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103278:	bf 00 00 00 00       	mov    $0x0,%edi
f010327d:	eb 11                	jmp    f0103290 <strtol+0x3b>
f010327f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103284:	3c 2d                	cmp    $0x2d,%al
f0103286:	75 08                	jne    f0103290 <strtol+0x3b>
		s++, neg = 1;
f0103288:	83 c1 01             	add    $0x1,%ecx
f010328b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103290:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103296:	75 15                	jne    f01032ad <strtol+0x58>
f0103298:	80 39 30             	cmpb   $0x30,(%ecx)
f010329b:	75 10                	jne    f01032ad <strtol+0x58>
f010329d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01032a1:	75 7c                	jne    f010331f <strtol+0xca>
		s += 2, base = 16;
f01032a3:	83 c1 02             	add    $0x2,%ecx
f01032a6:	bb 10 00 00 00       	mov    $0x10,%ebx
f01032ab:	eb 16                	jmp    f01032c3 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01032ad:	85 db                	test   %ebx,%ebx
f01032af:	75 12                	jne    f01032c3 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01032b1:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032b6:	80 39 30             	cmpb   $0x30,(%ecx)
f01032b9:	75 08                	jne    f01032c3 <strtol+0x6e>
		s++, base = 8;
f01032bb:	83 c1 01             	add    $0x1,%ecx
f01032be:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01032c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01032cb:	0f b6 11             	movzbl (%ecx),%edx
f01032ce:	8d 72 d0             	lea    -0x30(%edx),%esi
f01032d1:	89 f3                	mov    %esi,%ebx
f01032d3:	80 fb 09             	cmp    $0x9,%bl
f01032d6:	77 08                	ja     f01032e0 <strtol+0x8b>
			dig = *s - '0';
f01032d8:	0f be d2             	movsbl %dl,%edx
f01032db:	83 ea 30             	sub    $0x30,%edx
f01032de:	eb 22                	jmp    f0103302 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01032e0:	8d 72 9f             	lea    -0x61(%edx),%esi
f01032e3:	89 f3                	mov    %esi,%ebx
f01032e5:	80 fb 19             	cmp    $0x19,%bl
f01032e8:	77 08                	ja     f01032f2 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01032ea:	0f be d2             	movsbl %dl,%edx
f01032ed:	83 ea 57             	sub    $0x57,%edx
f01032f0:	eb 10                	jmp    f0103302 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01032f2:	8d 72 bf             	lea    -0x41(%edx),%esi
f01032f5:	89 f3                	mov    %esi,%ebx
f01032f7:	80 fb 19             	cmp    $0x19,%bl
f01032fa:	77 16                	ja     f0103312 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01032fc:	0f be d2             	movsbl %dl,%edx
f01032ff:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103302:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103305:	7d 0b                	jge    f0103312 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103307:	83 c1 01             	add    $0x1,%ecx
f010330a:	0f af 45 10          	imul   0x10(%ebp),%eax
f010330e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103310:	eb b9                	jmp    f01032cb <strtol+0x76>

	if (endptr)
f0103312:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103316:	74 0d                	je     f0103325 <strtol+0xd0>
		*endptr = (char *) s;
f0103318:	8b 75 0c             	mov    0xc(%ebp),%esi
f010331b:	89 0e                	mov    %ecx,(%esi)
f010331d:	eb 06                	jmp    f0103325 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010331f:	85 db                	test   %ebx,%ebx
f0103321:	74 98                	je     f01032bb <strtol+0x66>
f0103323:	eb 9e                	jmp    f01032c3 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103325:	89 c2                	mov    %eax,%edx
f0103327:	f7 da                	neg    %edx
f0103329:	85 ff                	test   %edi,%edi
f010332b:	0f 45 c2             	cmovne %edx,%eax
}
f010332e:	5b                   	pop    %ebx
f010332f:	5e                   	pop    %esi
f0103330:	5f                   	pop    %edi
f0103331:	5d                   	pop    %ebp
f0103332:	c3                   	ret    
f0103333:	66 90                	xchg   %ax,%ax
f0103335:	66 90                	xchg   %ax,%ax
f0103337:	66 90                	xchg   %ax,%ax
f0103339:	66 90                	xchg   %ax,%ax
f010333b:	66 90                	xchg   %ax,%ax
f010333d:	66 90                	xchg   %ax,%ax
f010333f:	90                   	nop

f0103340 <__udivdi3>:
f0103340:	55                   	push   %ebp
f0103341:	57                   	push   %edi
f0103342:	56                   	push   %esi
f0103343:	53                   	push   %ebx
f0103344:	83 ec 1c             	sub    $0x1c,%esp
f0103347:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010334b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010334f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103353:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103357:	85 f6                	test   %esi,%esi
f0103359:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010335d:	89 ca                	mov    %ecx,%edx
f010335f:	89 f8                	mov    %edi,%eax
f0103361:	75 3d                	jne    f01033a0 <__udivdi3+0x60>
f0103363:	39 cf                	cmp    %ecx,%edi
f0103365:	0f 87 c5 00 00 00    	ja     f0103430 <__udivdi3+0xf0>
f010336b:	85 ff                	test   %edi,%edi
f010336d:	89 fd                	mov    %edi,%ebp
f010336f:	75 0b                	jne    f010337c <__udivdi3+0x3c>
f0103371:	b8 01 00 00 00       	mov    $0x1,%eax
f0103376:	31 d2                	xor    %edx,%edx
f0103378:	f7 f7                	div    %edi
f010337a:	89 c5                	mov    %eax,%ebp
f010337c:	89 c8                	mov    %ecx,%eax
f010337e:	31 d2                	xor    %edx,%edx
f0103380:	f7 f5                	div    %ebp
f0103382:	89 c1                	mov    %eax,%ecx
f0103384:	89 d8                	mov    %ebx,%eax
f0103386:	89 cf                	mov    %ecx,%edi
f0103388:	f7 f5                	div    %ebp
f010338a:	89 c3                	mov    %eax,%ebx
f010338c:	89 d8                	mov    %ebx,%eax
f010338e:	89 fa                	mov    %edi,%edx
f0103390:	83 c4 1c             	add    $0x1c,%esp
f0103393:	5b                   	pop    %ebx
f0103394:	5e                   	pop    %esi
f0103395:	5f                   	pop    %edi
f0103396:	5d                   	pop    %ebp
f0103397:	c3                   	ret    
f0103398:	90                   	nop
f0103399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033a0:	39 ce                	cmp    %ecx,%esi
f01033a2:	77 74                	ja     f0103418 <__udivdi3+0xd8>
f01033a4:	0f bd fe             	bsr    %esi,%edi
f01033a7:	83 f7 1f             	xor    $0x1f,%edi
f01033aa:	0f 84 98 00 00 00    	je     f0103448 <__udivdi3+0x108>
f01033b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01033b5:	89 f9                	mov    %edi,%ecx
f01033b7:	89 c5                	mov    %eax,%ebp
f01033b9:	29 fb                	sub    %edi,%ebx
f01033bb:	d3 e6                	shl    %cl,%esi
f01033bd:	89 d9                	mov    %ebx,%ecx
f01033bf:	d3 ed                	shr    %cl,%ebp
f01033c1:	89 f9                	mov    %edi,%ecx
f01033c3:	d3 e0                	shl    %cl,%eax
f01033c5:	09 ee                	or     %ebp,%esi
f01033c7:	89 d9                	mov    %ebx,%ecx
f01033c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033cd:	89 d5                	mov    %edx,%ebp
f01033cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033d3:	d3 ed                	shr    %cl,%ebp
f01033d5:	89 f9                	mov    %edi,%ecx
f01033d7:	d3 e2                	shl    %cl,%edx
f01033d9:	89 d9                	mov    %ebx,%ecx
f01033db:	d3 e8                	shr    %cl,%eax
f01033dd:	09 c2                	or     %eax,%edx
f01033df:	89 d0                	mov    %edx,%eax
f01033e1:	89 ea                	mov    %ebp,%edx
f01033e3:	f7 f6                	div    %esi
f01033e5:	89 d5                	mov    %edx,%ebp
f01033e7:	89 c3                	mov    %eax,%ebx
f01033e9:	f7 64 24 0c          	mull   0xc(%esp)
f01033ed:	39 d5                	cmp    %edx,%ebp
f01033ef:	72 10                	jb     f0103401 <__udivdi3+0xc1>
f01033f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01033f5:	89 f9                	mov    %edi,%ecx
f01033f7:	d3 e6                	shl    %cl,%esi
f01033f9:	39 c6                	cmp    %eax,%esi
f01033fb:	73 07                	jae    f0103404 <__udivdi3+0xc4>
f01033fd:	39 d5                	cmp    %edx,%ebp
f01033ff:	75 03                	jne    f0103404 <__udivdi3+0xc4>
f0103401:	83 eb 01             	sub    $0x1,%ebx
f0103404:	31 ff                	xor    %edi,%edi
f0103406:	89 d8                	mov    %ebx,%eax
f0103408:	89 fa                	mov    %edi,%edx
f010340a:	83 c4 1c             	add    $0x1c,%esp
f010340d:	5b                   	pop    %ebx
f010340e:	5e                   	pop    %esi
f010340f:	5f                   	pop    %edi
f0103410:	5d                   	pop    %ebp
f0103411:	c3                   	ret    
f0103412:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103418:	31 ff                	xor    %edi,%edi
f010341a:	31 db                	xor    %ebx,%ebx
f010341c:	89 d8                	mov    %ebx,%eax
f010341e:	89 fa                	mov    %edi,%edx
f0103420:	83 c4 1c             	add    $0x1c,%esp
f0103423:	5b                   	pop    %ebx
f0103424:	5e                   	pop    %esi
f0103425:	5f                   	pop    %edi
f0103426:	5d                   	pop    %ebp
f0103427:	c3                   	ret    
f0103428:	90                   	nop
f0103429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103430:	89 d8                	mov    %ebx,%eax
f0103432:	f7 f7                	div    %edi
f0103434:	31 ff                	xor    %edi,%edi
f0103436:	89 c3                	mov    %eax,%ebx
f0103438:	89 d8                	mov    %ebx,%eax
f010343a:	89 fa                	mov    %edi,%edx
f010343c:	83 c4 1c             	add    $0x1c,%esp
f010343f:	5b                   	pop    %ebx
f0103440:	5e                   	pop    %esi
f0103441:	5f                   	pop    %edi
f0103442:	5d                   	pop    %ebp
f0103443:	c3                   	ret    
f0103444:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103448:	39 ce                	cmp    %ecx,%esi
f010344a:	72 0c                	jb     f0103458 <__udivdi3+0x118>
f010344c:	31 db                	xor    %ebx,%ebx
f010344e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103452:	0f 87 34 ff ff ff    	ja     f010338c <__udivdi3+0x4c>
f0103458:	bb 01 00 00 00       	mov    $0x1,%ebx
f010345d:	e9 2a ff ff ff       	jmp    f010338c <__udivdi3+0x4c>
f0103462:	66 90                	xchg   %ax,%ax
f0103464:	66 90                	xchg   %ax,%ax
f0103466:	66 90                	xchg   %ax,%ax
f0103468:	66 90                	xchg   %ax,%ax
f010346a:	66 90                	xchg   %ax,%ax
f010346c:	66 90                	xchg   %ax,%ax
f010346e:	66 90                	xchg   %ax,%ax

f0103470 <__umoddi3>:
f0103470:	55                   	push   %ebp
f0103471:	57                   	push   %edi
f0103472:	56                   	push   %esi
f0103473:	53                   	push   %ebx
f0103474:	83 ec 1c             	sub    $0x1c,%esp
f0103477:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010347b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010347f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103483:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103487:	85 d2                	test   %edx,%edx
f0103489:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010348d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103491:	89 f3                	mov    %esi,%ebx
f0103493:	89 3c 24             	mov    %edi,(%esp)
f0103496:	89 74 24 04          	mov    %esi,0x4(%esp)
f010349a:	75 1c                	jne    f01034b8 <__umoddi3+0x48>
f010349c:	39 f7                	cmp    %esi,%edi
f010349e:	76 50                	jbe    f01034f0 <__umoddi3+0x80>
f01034a0:	89 c8                	mov    %ecx,%eax
f01034a2:	89 f2                	mov    %esi,%edx
f01034a4:	f7 f7                	div    %edi
f01034a6:	89 d0                	mov    %edx,%eax
f01034a8:	31 d2                	xor    %edx,%edx
f01034aa:	83 c4 1c             	add    $0x1c,%esp
f01034ad:	5b                   	pop    %ebx
f01034ae:	5e                   	pop    %esi
f01034af:	5f                   	pop    %edi
f01034b0:	5d                   	pop    %ebp
f01034b1:	c3                   	ret    
f01034b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034b8:	39 f2                	cmp    %esi,%edx
f01034ba:	89 d0                	mov    %edx,%eax
f01034bc:	77 52                	ja     f0103510 <__umoddi3+0xa0>
f01034be:	0f bd ea             	bsr    %edx,%ebp
f01034c1:	83 f5 1f             	xor    $0x1f,%ebp
f01034c4:	75 5a                	jne    f0103520 <__umoddi3+0xb0>
f01034c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01034ca:	0f 82 e0 00 00 00    	jb     f01035b0 <__umoddi3+0x140>
f01034d0:	39 0c 24             	cmp    %ecx,(%esp)
f01034d3:	0f 86 d7 00 00 00    	jbe    f01035b0 <__umoddi3+0x140>
f01034d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01034e1:	83 c4 1c             	add    $0x1c,%esp
f01034e4:	5b                   	pop    %ebx
f01034e5:	5e                   	pop    %esi
f01034e6:	5f                   	pop    %edi
f01034e7:	5d                   	pop    %ebp
f01034e8:	c3                   	ret    
f01034e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034f0:	85 ff                	test   %edi,%edi
f01034f2:	89 fd                	mov    %edi,%ebp
f01034f4:	75 0b                	jne    f0103501 <__umoddi3+0x91>
f01034f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01034fb:	31 d2                	xor    %edx,%edx
f01034fd:	f7 f7                	div    %edi
f01034ff:	89 c5                	mov    %eax,%ebp
f0103501:	89 f0                	mov    %esi,%eax
f0103503:	31 d2                	xor    %edx,%edx
f0103505:	f7 f5                	div    %ebp
f0103507:	89 c8                	mov    %ecx,%eax
f0103509:	f7 f5                	div    %ebp
f010350b:	89 d0                	mov    %edx,%eax
f010350d:	eb 99                	jmp    f01034a8 <__umoddi3+0x38>
f010350f:	90                   	nop
f0103510:	89 c8                	mov    %ecx,%eax
f0103512:	89 f2                	mov    %esi,%edx
f0103514:	83 c4 1c             	add    $0x1c,%esp
f0103517:	5b                   	pop    %ebx
f0103518:	5e                   	pop    %esi
f0103519:	5f                   	pop    %edi
f010351a:	5d                   	pop    %ebp
f010351b:	c3                   	ret    
f010351c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103520:	8b 34 24             	mov    (%esp),%esi
f0103523:	bf 20 00 00 00       	mov    $0x20,%edi
f0103528:	89 e9                	mov    %ebp,%ecx
f010352a:	29 ef                	sub    %ebp,%edi
f010352c:	d3 e0                	shl    %cl,%eax
f010352e:	89 f9                	mov    %edi,%ecx
f0103530:	89 f2                	mov    %esi,%edx
f0103532:	d3 ea                	shr    %cl,%edx
f0103534:	89 e9                	mov    %ebp,%ecx
f0103536:	09 c2                	or     %eax,%edx
f0103538:	89 d8                	mov    %ebx,%eax
f010353a:	89 14 24             	mov    %edx,(%esp)
f010353d:	89 f2                	mov    %esi,%edx
f010353f:	d3 e2                	shl    %cl,%edx
f0103541:	89 f9                	mov    %edi,%ecx
f0103543:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103547:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010354b:	d3 e8                	shr    %cl,%eax
f010354d:	89 e9                	mov    %ebp,%ecx
f010354f:	89 c6                	mov    %eax,%esi
f0103551:	d3 e3                	shl    %cl,%ebx
f0103553:	89 f9                	mov    %edi,%ecx
f0103555:	89 d0                	mov    %edx,%eax
f0103557:	d3 e8                	shr    %cl,%eax
f0103559:	89 e9                	mov    %ebp,%ecx
f010355b:	09 d8                	or     %ebx,%eax
f010355d:	89 d3                	mov    %edx,%ebx
f010355f:	89 f2                	mov    %esi,%edx
f0103561:	f7 34 24             	divl   (%esp)
f0103564:	89 d6                	mov    %edx,%esi
f0103566:	d3 e3                	shl    %cl,%ebx
f0103568:	f7 64 24 04          	mull   0x4(%esp)
f010356c:	39 d6                	cmp    %edx,%esi
f010356e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103572:	89 d1                	mov    %edx,%ecx
f0103574:	89 c3                	mov    %eax,%ebx
f0103576:	72 08                	jb     f0103580 <__umoddi3+0x110>
f0103578:	75 11                	jne    f010358b <__umoddi3+0x11b>
f010357a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010357e:	73 0b                	jae    f010358b <__umoddi3+0x11b>
f0103580:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103584:	1b 14 24             	sbb    (%esp),%edx
f0103587:	89 d1                	mov    %edx,%ecx
f0103589:	89 c3                	mov    %eax,%ebx
f010358b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010358f:	29 da                	sub    %ebx,%edx
f0103591:	19 ce                	sbb    %ecx,%esi
f0103593:	89 f9                	mov    %edi,%ecx
f0103595:	89 f0                	mov    %esi,%eax
f0103597:	d3 e0                	shl    %cl,%eax
f0103599:	89 e9                	mov    %ebp,%ecx
f010359b:	d3 ea                	shr    %cl,%edx
f010359d:	89 e9                	mov    %ebp,%ecx
f010359f:	d3 ee                	shr    %cl,%esi
f01035a1:	09 d0                	or     %edx,%eax
f01035a3:	89 f2                	mov    %esi,%edx
f01035a5:	83 c4 1c             	add    $0x1c,%esp
f01035a8:	5b                   	pop    %ebx
f01035a9:	5e                   	pop    %esi
f01035aa:	5f                   	pop    %edi
f01035ab:	5d                   	pop    %ebp
f01035ac:	c3                   	ret    
f01035ad:	8d 76 00             	lea    0x0(%esi),%esi
f01035b0:	29 f9                	sub    %edi,%ecx
f01035b2:	19 d6                	sbb    %edx,%esi
f01035b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035bc:	e9 18 ff ff ff       	jmp    f01034d9 <__umoddi3+0x69>
