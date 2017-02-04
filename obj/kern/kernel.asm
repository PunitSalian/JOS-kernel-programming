
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f0100046:	b8 50 49 11 f0       	mov    $0xf0114950,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 b2 1c 00 00       	call   f0101d0f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 21 10 f0       	push   $0xf01021c0
f010006f:	e8 b2 11 00 00       	call   f0101226 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 c5 09 00 00       	call   f0100a3e <mem_init>
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
f0100093:	83 3d 40 49 11 f0 00 	cmpl   $0x0,0xf0114940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 49 11 f0    	mov    %esi,0xf0114940

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
f01000b0:	68 db 21 10 f0       	push   $0xf01021db
f01000b5:	e8 6c 11 00 00       	call   f0101226 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 3c 11 00 00       	call   f0101200 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 98 26 10 f0 	movl   $0xf0102698,(%esp)
f01000cb:	e8 56 11 00 00       	call   f0101226 <cprintf>
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
f01000f2:	68 f3 21 10 f0       	push   $0xf01021f3
f01000f7:	e8 2a 11 00 00       	call   f0101226 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 f8 10 00 00       	call   f0101200 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 98 26 10 f0 	movl   $0xf0102698,(%esp)
f010010f:	e8 12 11 00 00       	call   f0101226 <cprintf>
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
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
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
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
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
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 60 23 10 f0 	movzbl -0xfefdca0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 60 23 10 f0 	movzbl -0xfefdca0(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a 60 22 10 f0 	movzbl -0xfefdda0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 40 22 10 f0 	mov    -0xfefddc0(,%ecx,4),%ecx
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
f0100268:	68 0d 22 10 f0       	push   $0xf010220d
f010026d:	e8 b4 0f 00 00       	call   f0101226 <cprintf>
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
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 3b 19 00 00       	call   f0101d5c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
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
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
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
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
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
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
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
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
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
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
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
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
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
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
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
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
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
f01005eb:	68 19 22 10 f0       	push   $0xf0102219
f01005f0:	e8 31 0c 00 00       	call   f0101226 <cprintf>
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
f0100631:	68 60 24 10 f0       	push   $0xf0102460
f0100636:	68 7e 24 10 f0       	push   $0xf010247e
f010063b:	68 83 24 10 f0       	push   $0xf0102483
f0100640:	e8 e1 0b 00 00       	call   f0101226 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 ec 24 10 f0       	push   $0xf01024ec
f010064d:	68 8c 24 10 f0       	push   $0xf010248c
f0100652:	68 83 24 10 f0       	push   $0xf0102483
f0100657:	e8 ca 0b 00 00       	call   f0101226 <cprintf>
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
f0100669:	68 95 24 10 f0       	push   $0xf0102495
f010066e:	e8 b3 0b 00 00       	call   f0101226 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 14 25 10 f0       	push   $0xf0102514
f0100680:	e8 a1 0b 00 00       	call   f0101226 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 3c 25 10 f0       	push   $0xf010253c
f0100697:	e8 8a 0b 00 00       	call   f0101226 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 a1 21 10 00       	push   $0x1021a1
f01006a4:	68 a1 21 10 f0       	push   $0xf01021a1
f01006a9:	68 60 25 10 f0       	push   $0xf0102560
f01006ae:	e8 73 0b 00 00       	call   f0101226 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 43 11 00       	push   $0x114300
f01006bb:	68 00 43 11 f0       	push   $0xf0114300
f01006c0:	68 84 25 10 f0       	push   $0xf0102584
f01006c5:	e8 5c 0b 00 00       	call   f0101226 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 49 11 00       	push   $0x114950
f01006d2:	68 50 49 11 f0       	push   $0xf0114950
f01006d7:	68 a8 25 10 f0       	push   $0xf01025a8
f01006dc:	e8 45 0b 00 00       	call   f0101226 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 4d 11 f0       	mov    $0xf0114d4f,%eax
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
f0100702:	68 cc 25 10 f0       	push   $0xf01025cc
f0100707:	e8 1a 0b 00 00       	call   f0101226 <cprintf>
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
f0100726:	68 f8 25 10 f0       	push   $0xf01025f8
f010072b:	e8 f6 0a 00 00       	call   f0101226 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 1c 26 10 f0 	movl   $0xf010261c,(%esp)
f0100737:	e8 ea 0a 00 00       	call   f0101226 <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ae 24 10 f0       	push   $0xf01024ae
f0100747:	e8 6c 13 00 00       	call   f0101ab8 <readline>
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
f010077b:	68 b2 24 10 f0       	push   $0xf01024b2
f0100780:	e8 4d 15 00 00       	call   f0101cd2 <strchr>
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
f010079b:	68 b7 24 10 f0       	push   $0xf01024b7
f01007a0:	e8 81 0a 00 00       	call   f0101226 <cprintf>
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
f01007c4:	68 b2 24 10 f0       	push   $0xf01024b2
f01007c9:	e8 04 15 00 00       	call   f0101cd2 <strchr>
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
f01007ea:	68 7e 24 10 f0       	push   $0xf010247e
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 7d 14 00 00       	call   f0101c74 <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 8c 24 10 f0       	push   $0xf010248c
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 66 14 00 00       	call   f0101c74 <strcmp>
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
f0100831:	ff 14 85 4c 26 10 f0 	call   *-0xfefd9b4(,%eax,4)


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
f010084a:	68 d4 24 10 f0       	push   $0xf01024d4
f010084f:	e8 d2 09 00 00       	call   f0101226 <cprintf>
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

f0100864 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100864:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f010086b:	75 11                	jne    f010087e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010086d:	ba 4f 59 11 f0       	mov    $0xf011594f,%edx
f0100872:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100878:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f010087e:	85 c0                	test   %eax,%eax
f0100880:	74 2e                	je     f01008b0 <boot_alloc+0x4c>
	{
	result=nextfree;
f0100882:	8b 0d 38 45 11 f0    	mov    0xf0114538,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f0100888:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010088e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100894:	01 ca                	add    %ecx,%edx
f0100896:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f010089c:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f01008a1:	05 00 00 0f 00       	add    $0xf0000,%eax
f01008a6:	c1 e0 0c             	shl    $0xc,%eax
f01008a9:	39 c2                	cmp    %eax,%edx
f01008ab:	77 09                	ja     f01008b6 <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f01008ad:	89 c8                	mov    %ecx,%eax
f01008af:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f01008b0:	a1 38 45 11 f0       	mov    0xf0114538,%eax
f01008b5:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008b6:	55                   	push   %ebp
f01008b7:	89 e5                	mov    %esp,%ebp
f01008b9:	83 ec 0c             	sub    $0xc,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f01008bc:	68 5c 26 10 f0       	push   $0xf010265c
f01008c1:	6a 79                	push   $0x79
f01008c3:	68 6c 26 10 f0       	push   $0xf010266c
f01008c8:	e8 be f7 ff ff       	call   f010008b <_panic>

f01008cd <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01008cd:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f01008d3:	c1 f8 03             	sar    $0x3,%eax
f01008d6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008d9:	89 c2                	mov    %eax,%edx
f01008db:	c1 ea 0c             	shr    $0xc,%edx
f01008de:	39 15 44 49 11 f0    	cmp    %edx,0xf0114944
f01008e4:	77 18                	ja     f01008fe <page2kva+0x31>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01008e6:	55                   	push   %ebp
f01008e7:	89 e5                	mov    %esp,%ebp
f01008e9:	83 ec 08             	sub    $0x8,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008ec:	50                   	push   %eax
f01008ed:	68 64 28 10 f0       	push   $0xf0102864
f01008f2:	6a 52                	push   $0x52
f01008f4:	68 78 26 10 f0       	push   $0xf0102678
f01008f9:	e8 8d f7 ff ff       	call   f010008b <_panic>
}

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
f01008fe:	2d 00 00 00 10       	sub    $0x10000000,%eax
}
f0100903:	c3                   	ret    

f0100904 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	56                   	push   %esi
f0100908:	53                   	push   %ebx
f0100909:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010090b:	83 ec 0c             	sub    $0xc,%esp
f010090e:	50                   	push   %eax
f010090f:	e8 ab 08 00 00       	call   f01011bf <mc146818_read>
f0100914:	89 c6                	mov    %eax,%esi
f0100916:	83 c3 01             	add    $0x1,%ebx
f0100919:	89 1c 24             	mov    %ebx,(%esp)
f010091c:	e8 9e 08 00 00       	call   f01011bf <mc146818_read>
f0100921:	c1 e0 08             	shl    $0x8,%eax
f0100924:	09 f0                	or     %esi,%eax
}
f0100926:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100929:	5b                   	pop    %ebx
f010092a:	5e                   	pop    %esi
f010092b:	5d                   	pop    %ebp
f010092c:	c3                   	ret    

f010092d <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010092d:	55                   	push   %ebp
f010092e:	89 e5                	mov    %esp,%ebp
f0100930:	53                   	push   %ebx
f0100931:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100934:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100939:	eb 4d                	jmp    f0100988 <page_init+0x5b>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE)))
f010093b:	85 db                	test   %ebx,%ebx
f010093d:	74 46                	je     f0100985 <page_init+0x58>
f010093f:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100945:	76 16                	jbe    f010095d <page_init+0x30>
f0100947:	b8 00 00 00 00       	mov    $0x0,%eax
f010094c:	e8 13 ff ff ff       	call   f0100864 <boot_alloc>
f0100951:	05 00 00 00 10       	add    $0x10000000,%eax
f0100956:	c1 e8 0c             	shr    $0xc,%eax
f0100959:	39 c3                	cmp    %eax,%ebx
f010095b:	76 28                	jbe    f0100985 <page_init+0x58>
f010095d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100964:	89 c2                	mov    %eax,%edx
f0100966:	03 15 4c 49 11 f0    	add    0xf011494c,%edx
f010096c:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100972:	8b 0d 3c 45 11 f0    	mov    0xf011453c,%ecx
f0100978:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f010097a:	03 05 4c 49 11 f0    	add    0xf011494c,%eax
f0100980:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100985:	83 c3 01             	add    $0x1,%ebx
f0100988:	3b 1d 44 49 11 f0    	cmp    0xf0114944,%ebx
f010098e:	72 ab                	jb     f010093b <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100990:	83 c4 04             	add    $0x4,%esp
f0100993:	5b                   	pop    %ebx
f0100994:	5d                   	pop    %ebp
f0100995:	c3                   	ret    

f0100996 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100996:	55                   	push   %ebp
f0100997:	89 e5                	mov    %esp,%ebp
f0100999:	53                   	push   %ebx
f010099a:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f010099d:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f01009a3:	85 db                	test   %ebx,%ebx
f01009a5:	74 58                	je     f01009ff <page_alloc+0x69>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f01009a7:	8b 03                	mov    (%ebx),%eax
f01009a9:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
  	tempage->pp_link = NULL;
f01009ae:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
f01009b4:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01009b8:	74 45                	je     f01009ff <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009ba:	89 d8                	mov    %ebx,%eax
f01009bc:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f01009c2:	c1 f8 03             	sar    $0x3,%eax
f01009c5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c8:	89 c2                	mov    %eax,%edx
f01009ca:	c1 ea 0c             	shr    $0xc,%edx
f01009cd:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f01009d3:	72 12                	jb     f01009e7 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d5:	50                   	push   %eax
f01009d6:	68 64 28 10 f0       	push   $0xf0102864
f01009db:	6a 52                	push   $0x52
f01009dd:	68 78 26 10 f0       	push   $0xf0102678
f01009e2:	e8 a4 f6 ff ff       	call   f010008b <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f01009e7:	83 ec 04             	sub    $0x4,%esp
f01009ea:	68 00 10 00 00       	push   $0x1000
f01009ef:	6a 00                	push   $0x0
f01009f1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f6:	50                   	push   %eax
f01009f7:	e8 13 13 00 00       	call   f0101d0f <memset>
f01009fc:	83 c4 10             	add    $0x10,%esp

  	return tempage;
	

}
f01009ff:	89 d8                	mov    %ebx,%eax
f0100a01:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a04:	c9                   	leave  
f0100a05:	c3                   	ret    

f0100a06 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100a06:	55                   	push   %ebp
f0100a07:	89 e5                	mov    %esp,%ebp
f0100a09:	83 ec 08             	sub    $0x8,%esp
f0100a0c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100a0f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100a14:	75 0f                	jne    f0100a25 <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100a16:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100a1c:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100a1e:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	}
	else
	panic("page ref not zero \n");
}
f0100a23:	eb 17                	jmp    f0100a3c <page_free+0x36>
	{
	pp->pp_link=page_free_list;
	page_free_list=pp;	
	}
	else
	panic("page ref not zero \n");
f0100a25:	83 ec 04             	sub    $0x4,%esp
f0100a28:	68 86 26 10 f0       	push   $0xf0102686
f0100a2d:	68 4e 01 00 00       	push   $0x14e
f0100a32:	68 6c 26 10 f0       	push   $0xf010266c
f0100a37:	e8 4f f6 ff ff       	call   f010008b <_panic>
}
f0100a3c:	c9                   	leave  
f0100a3d:	c3                   	ret    

f0100a3e <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100a3e:	55                   	push   %ebp
f0100a3f:	89 e5                	mov    %esp,%ebp
f0100a41:	57                   	push   %edi
f0100a42:	56                   	push   %esi
f0100a43:	53                   	push   %ebx
f0100a44:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a47:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a4c:	e8 b3 fe ff ff       	call   f0100904 <nvram_read>
f0100a51:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a53:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a58:	e8 a7 fe ff ff       	call   f0100904 <nvram_read>
f0100a5d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a5f:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a64:	e8 9b fe ff ff       	call   f0100904 <nvram_read>
f0100a69:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100a6c:	85 c0                	test   %eax,%eax
f0100a6e:	74 07                	je     f0100a77 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100a70:	05 00 40 00 00       	add    $0x4000,%eax
f0100a75:	eb 0b                	jmp    f0100a82 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100a77:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a7d:	85 f6                	test   %esi,%esi
f0100a7f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100a82:	89 c2                	mov    %eax,%edx
f0100a84:	c1 ea 02             	shr    $0x2,%edx
f0100a87:	89 15 44 49 11 f0    	mov    %edx,0xf0114944
	npages_basemem = basemem / (PGSIZE / 1024);
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a8d:	89 c2                	mov    %eax,%edx
f0100a8f:	29 da                	sub    %ebx,%edx
f0100a91:	52                   	push   %edx
f0100a92:	53                   	push   %ebx
f0100a93:	50                   	push   %eax
f0100a94:	68 88 28 10 f0       	push   $0xf0102888
f0100a99:	e8 88 07 00 00       	call   f0101226 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100a9e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100aa3:	e8 bc fd ff ff       	call   f0100864 <boot_alloc>
f0100aa8:	a3 48 49 11 f0       	mov    %eax,0xf0114948
	memset(kern_pgdir, 0, PGSIZE);
f0100aad:	83 c4 0c             	add    $0xc,%esp
f0100ab0:	68 00 10 00 00       	push   $0x1000
f0100ab5:	6a 00                	push   $0x0
f0100ab7:	50                   	push   %eax
f0100ab8:	e8 52 12 00 00       	call   f0101d0f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100abd:	a1 48 49 11 f0       	mov    0xf0114948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ac2:	83 c4 10             	add    $0x10,%esp
f0100ac5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100aca:	77 15                	ja     f0100ae1 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100acc:	50                   	push   %eax
f0100acd:	68 c4 28 10 f0       	push   $0xf01028c4
f0100ad2:	68 a0 00 00 00       	push   $0xa0
f0100ad7:	68 6c 26 10 f0       	push   $0xf010266c
f0100adc:	e8 aa f5 ff ff       	call   f010008b <_panic>
f0100ae1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100ae7:	83 ca 05             	or     $0x5,%edx
f0100aea:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(sizeof(struct PageInfo)*npages);
f0100af0:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100af5:	c1 e0 03             	shl    $0x3,%eax
f0100af8:	e8 67 fd ff ff       	call   f0100864 <boot_alloc>
f0100afd:	a3 4c 49 11 f0       	mov    %eax,0xf011494c
	memset(pages,0,sizeof(struct PageInfo)*npages);
f0100b02:	83 ec 04             	sub    $0x4,%esp
f0100b05:	8b 35 44 49 11 f0    	mov    0xf0114944,%esi
f0100b0b:	8d 14 f5 00 00 00 00 	lea    0x0(,%esi,8),%edx
f0100b12:	52                   	push   %edx
f0100b13:	6a 00                	push   $0x0
f0100b15:	50                   	push   %eax
f0100b16:	e8 f4 11 00 00       	call   f0101d0f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100b1b:	e8 0d fe ff ff       	call   f010092d <page_init>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100b20:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100b25:	83 c4 10             	add    $0x10,%esp
f0100b28:	85 c0                	test   %eax,%eax
f0100b2a:	75 17                	jne    f0100b43 <mem_init+0x105>
		panic("'page_free_list' is a null pointer!");
f0100b2c:	83 ec 04             	sub    $0x4,%esp
f0100b2f:	68 e8 28 10 f0       	push   $0xf01028e8
f0100b34:	68 ee 01 00 00       	push   $0x1ee
f0100b39:	68 6c 26 10 f0       	push   $0xf010266c
f0100b3e:	e8 48 f5 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b43:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b46:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b49:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b4c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b4f:	89 c2                	mov    %eax,%edx
f0100b51:	2b 15 4c 49 11 f0    	sub    0xf011494c,%edx
f0100b57:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b5d:	0f 95 c2             	setne  %dl
f0100b60:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b63:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b67:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b69:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6d:	8b 00                	mov    (%eax),%eax
f0100b6f:	85 c0                	test   %eax,%eax
f0100b71:	75 dc                	jne    f0100b4f <mem_init+0x111>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b76:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b7f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b82:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b84:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100b87:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
f0100b8d:	eb 54                	jmp    f0100be3 <mem_init+0x1a5>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b8f:	89 d8                	mov    %ebx,%eax
f0100b91:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100b97:	c1 f8 03             	sar    $0x3,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b9a:	89 c2                	mov    %eax,%edx
f0100b9c:	c1 e2 0c             	shl    $0xc,%edx
f0100b9f:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100ba4:	75 3b                	jne    f0100be1 <mem_init+0x1a3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ba6:	89 d0                	mov    %edx,%eax
f0100ba8:	c1 e8 0c             	shr    $0xc,%eax
f0100bab:	3b 05 44 49 11 f0    	cmp    0xf0114944,%eax
f0100bb1:	72 12                	jb     f0100bc5 <mem_init+0x187>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bb3:	52                   	push   %edx
f0100bb4:	68 64 28 10 f0       	push   $0xf0102864
f0100bb9:	6a 52                	push   $0x52
f0100bbb:	68 78 26 10 f0       	push   $0xf0102678
f0100bc0:	e8 c6 f4 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bc5:	83 ec 04             	sub    $0x4,%esp
f0100bc8:	68 80 00 00 00       	push   $0x80
f0100bcd:	68 97 00 00 00       	push   $0x97
f0100bd2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100bd8:	52                   	push   %edx
f0100bd9:	e8 31 11 00 00       	call   f0101d0f <memset>
f0100bde:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100be1:	8b 1b                	mov    (%ebx),%ebx
f0100be3:	85 db                	test   %ebx,%ebx
f0100be5:	75 a8                	jne    f0100b8f <mem_init+0x151>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100be7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bec:	e8 73 fc ff ff       	call   f0100864 <boot_alloc>
f0100bf1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bf4:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100bf9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bfc:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
		assert(pp < pages + npages);
f0100c02:	8b 35 44 49 11 f0    	mov    0xf0114944,%esi
f0100c08:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0100c0b:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c0e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c11:	89 c2                	mov    %eax,%edx
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c13:	be 00 00 00 00       	mov    $0x0,%esi
f0100c18:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100c1b:	e9 30 01 00 00       	jmp    f0100d50 <mem_init+0x312>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c20:	39 d1                	cmp    %edx,%ecx
f0100c22:	76 19                	jbe    f0100c3d <mem_init+0x1ff>
f0100c24:	68 9a 26 10 f0       	push   $0xf010269a
f0100c29:	68 a6 26 10 f0       	push   $0xf01026a6
f0100c2e:	68 08 02 00 00       	push   $0x208
f0100c33:	68 6c 26 10 f0       	push   $0xf010266c
f0100c38:	e8 4e f4 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100c3d:	39 fa                	cmp    %edi,%edx
f0100c3f:	72 19                	jb     f0100c5a <mem_init+0x21c>
f0100c41:	68 bb 26 10 f0       	push   $0xf01026bb
f0100c46:	68 a6 26 10 f0       	push   $0xf01026a6
f0100c4b:	68 09 02 00 00       	push   $0x209
f0100c50:	68 6c 26 10 f0       	push   $0xf010266c
f0100c55:	e8 31 f4 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c5a:	89 d0                	mov    %edx,%eax
f0100c5c:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c5f:	a8 07                	test   $0x7,%al
f0100c61:	74 19                	je     f0100c7c <mem_init+0x23e>
f0100c63:	68 0c 29 10 f0       	push   $0xf010290c
f0100c68:	68 a6 26 10 f0       	push   $0xf01026a6
f0100c6d:	68 0a 02 00 00       	push   $0x20a
f0100c72:	68 6c 26 10 f0       	push   $0xf010266c
f0100c77:	e8 0f f4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c7c:	c1 f8 03             	sar    $0x3,%eax
f0100c7f:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c82:	85 c0                	test   %eax,%eax
f0100c84:	75 19                	jne    f0100c9f <mem_init+0x261>
f0100c86:	68 cf 26 10 f0       	push   $0xf01026cf
f0100c8b:	68 a6 26 10 f0       	push   $0xf01026a6
f0100c90:	68 0d 02 00 00       	push   $0x20d
f0100c95:	68 6c 26 10 f0       	push   $0xf010266c
f0100c9a:	e8 ec f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c9f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ca4:	75 19                	jne    f0100cbf <mem_init+0x281>
f0100ca6:	68 e0 26 10 f0       	push   $0xf01026e0
f0100cab:	68 a6 26 10 f0       	push   $0xf01026a6
f0100cb0:	68 0e 02 00 00       	push   $0x20e
f0100cb5:	68 6c 26 10 f0       	push   $0xf010266c
f0100cba:	e8 cc f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cbf:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cc4:	75 19                	jne    f0100cdf <mem_init+0x2a1>
f0100cc6:	68 40 29 10 f0       	push   $0xf0102940
f0100ccb:	68 a6 26 10 f0       	push   $0xf01026a6
f0100cd0:	68 0f 02 00 00       	push   $0x20f
f0100cd5:	68 6c 26 10 f0       	push   $0xf010266c
f0100cda:	e8 ac f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cdf:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ce4:	75 19                	jne    f0100cff <mem_init+0x2c1>
f0100ce6:	68 f9 26 10 f0       	push   $0xf01026f9
f0100ceb:	68 a6 26 10 f0       	push   $0xf01026a6
f0100cf0:	68 10 02 00 00       	push   $0x210
f0100cf5:	68 6c 26 10 f0       	push   $0xf010266c
f0100cfa:	e8 8c f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cff:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d04:	76 3f                	jbe    f0100d45 <mem_init+0x307>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d06:	89 c3                	mov    %eax,%ebx
f0100d08:	c1 eb 0c             	shr    $0xc,%ebx
f0100d0b:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d0e:	77 12                	ja     f0100d22 <mem_init+0x2e4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d10:	50                   	push   %eax
f0100d11:	68 64 28 10 f0       	push   $0xf0102864
f0100d16:	6a 52                	push   $0x52
f0100d18:	68 78 26 10 f0       	push   $0xf0102678
f0100d1d:	e8 69 f3 ff ff       	call   f010008b <_panic>
f0100d22:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d27:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d2a:	76 1e                	jbe    f0100d4a <mem_init+0x30c>
f0100d2c:	68 64 29 10 f0       	push   $0xf0102964
f0100d31:	68 a6 26 10 f0       	push   $0xf01026a6
f0100d36:	68 11 02 00 00       	push   $0x211
f0100d3b:	68 6c 26 10 f0       	push   $0xf010266c
f0100d40:	e8 46 f3 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d45:	83 c6 01             	add    $0x1,%esi
f0100d48:	eb 04                	jmp    f0100d4e <mem_init+0x310>
		else
			++nfree_extmem;
f0100d4a:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d4e:	8b 12                	mov    (%edx),%edx
f0100d50:	85 d2                	test   %edx,%edx
f0100d52:	0f 85 c8 fe ff ff    	jne    f0100c20 <mem_init+0x1e2>
f0100d58:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d5b:	85 f6                	test   %esi,%esi
f0100d5d:	7f 19                	jg     f0100d78 <mem_init+0x33a>
f0100d5f:	68 13 27 10 f0       	push   $0xf0102713
f0100d64:	68 a6 26 10 f0       	push   $0xf01026a6
f0100d69:	68 19 02 00 00       	push   $0x219
f0100d6e:	68 6c 26 10 f0       	push   $0xf010266c
f0100d73:	e8 13 f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100d78:	85 db                	test   %ebx,%ebx
f0100d7a:	7f 19                	jg     f0100d95 <mem_init+0x357>
f0100d7c:	68 25 27 10 f0       	push   $0xf0102725
f0100d81:	68 a6 26 10 f0       	push   $0xf01026a6
f0100d86:	68 1a 02 00 00       	push   $0x21a
f0100d8b:	68 6c 26 10 f0       	push   $0xf010266c
f0100d90:	e8 f6 f2 ff ff       	call   f010008b <_panic>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100d95:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d9a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d9d:	85 c9                	test   %ecx,%ecx
f0100d9f:	75 1e                	jne    f0100dbf <mem_init+0x381>
		panic("'pages' is a null pointer!");
f0100da1:	83 ec 04             	sub    $0x4,%esp
f0100da4:	68 36 27 10 f0       	push   $0xf0102736
f0100da9:	68 2b 02 00 00       	push   $0x22b
f0100dae:	68 6c 26 10 f0       	push   $0xf010266c
f0100db3:	e8 d3 f2 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f0100db8:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100dbb:	8b 00                	mov    (%eax),%eax
f0100dbd:	eb 00                	jmp    f0100dbf <mem_init+0x381>
f0100dbf:	85 c0                	test   %eax,%eax
f0100dc1:	75 f5                	jne    f0100db8 <mem_init+0x37a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100dc3:	83 ec 0c             	sub    $0xc,%esp
f0100dc6:	6a 00                	push   $0x0
f0100dc8:	e8 c9 fb ff ff       	call   f0100996 <page_alloc>
f0100dcd:	89 c7                	mov    %eax,%edi
f0100dcf:	83 c4 10             	add    $0x10,%esp
f0100dd2:	85 c0                	test   %eax,%eax
f0100dd4:	75 19                	jne    f0100def <mem_init+0x3b1>
f0100dd6:	68 51 27 10 f0       	push   $0xf0102751
f0100ddb:	68 a6 26 10 f0       	push   $0xf01026a6
f0100de0:	68 33 02 00 00       	push   $0x233
f0100de5:	68 6c 26 10 f0       	push   $0xf010266c
f0100dea:	e8 9c f2 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100def:	83 ec 0c             	sub    $0xc,%esp
f0100df2:	6a 00                	push   $0x0
f0100df4:	e8 9d fb ff ff       	call   f0100996 <page_alloc>
f0100df9:	89 c6                	mov    %eax,%esi
f0100dfb:	83 c4 10             	add    $0x10,%esp
f0100dfe:	85 c0                	test   %eax,%eax
f0100e00:	75 19                	jne    f0100e1b <mem_init+0x3dd>
f0100e02:	68 67 27 10 f0       	push   $0xf0102767
f0100e07:	68 a6 26 10 f0       	push   $0xf01026a6
f0100e0c:	68 34 02 00 00       	push   $0x234
f0100e11:	68 6c 26 10 f0       	push   $0xf010266c
f0100e16:	e8 70 f2 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100e1b:	83 ec 0c             	sub    $0xc,%esp
f0100e1e:	6a 00                	push   $0x0
f0100e20:	e8 71 fb ff ff       	call   f0100996 <page_alloc>
f0100e25:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e28:	83 c4 10             	add    $0x10,%esp
f0100e2b:	85 c0                	test   %eax,%eax
f0100e2d:	75 19                	jne    f0100e48 <mem_init+0x40a>
f0100e2f:	68 7d 27 10 f0       	push   $0xf010277d
f0100e34:	68 a6 26 10 f0       	push   $0xf01026a6
f0100e39:	68 35 02 00 00       	push   $0x235
f0100e3e:	68 6c 26 10 f0       	push   $0xf010266c
f0100e43:	e8 43 f2 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100e48:	39 f7                	cmp    %esi,%edi
f0100e4a:	75 19                	jne    f0100e65 <mem_init+0x427>
f0100e4c:	68 93 27 10 f0       	push   $0xf0102793
f0100e51:	68 a6 26 10 f0       	push   $0xf01026a6
f0100e56:	68 38 02 00 00       	push   $0x238
f0100e5b:	68 6c 26 10 f0       	push   $0xf010266c
f0100e60:	e8 26 f2 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100e65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e68:	39 c7                	cmp    %eax,%edi
f0100e6a:	74 04                	je     f0100e70 <mem_init+0x432>
f0100e6c:	39 c6                	cmp    %eax,%esi
f0100e6e:	75 19                	jne    f0100e89 <mem_init+0x44b>
f0100e70:	68 ac 29 10 f0       	push   $0xf01029ac
f0100e75:	68 a6 26 10 f0       	push   $0xf01026a6
f0100e7a:	68 39 02 00 00       	push   $0x239
f0100e7f:	68 6c 26 10 f0       	push   $0xf010266c
f0100e84:	e8 02 f2 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e89:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0100e8f:	8b 15 44 49 11 f0    	mov    0xf0114944,%edx
f0100e95:	c1 e2 0c             	shl    $0xc,%edx
f0100e98:	89 f8                	mov    %edi,%eax
f0100e9a:	29 c8                	sub    %ecx,%eax
f0100e9c:	c1 f8 03             	sar    $0x3,%eax
f0100e9f:	c1 e0 0c             	shl    $0xc,%eax
f0100ea2:	39 d0                	cmp    %edx,%eax
f0100ea4:	72 19                	jb     f0100ebf <mem_init+0x481>
f0100ea6:	68 a5 27 10 f0       	push   $0xf01027a5
f0100eab:	68 a6 26 10 f0       	push   $0xf01026a6
f0100eb0:	68 3a 02 00 00       	push   $0x23a
f0100eb5:	68 6c 26 10 f0       	push   $0xf010266c
f0100eba:	e8 cc f1 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0100ebf:	89 f0                	mov    %esi,%eax
f0100ec1:	29 c8                	sub    %ecx,%eax
f0100ec3:	c1 f8 03             	sar    $0x3,%eax
f0100ec6:	c1 e0 0c             	shl    $0xc,%eax
f0100ec9:	39 c2                	cmp    %eax,%edx
f0100ecb:	77 19                	ja     f0100ee6 <mem_init+0x4a8>
f0100ecd:	68 c2 27 10 f0       	push   $0xf01027c2
f0100ed2:	68 a6 26 10 f0       	push   $0xf01026a6
f0100ed7:	68 3b 02 00 00       	push   $0x23b
f0100edc:	68 6c 26 10 f0       	push   $0xf010266c
f0100ee1:	e8 a5 f1 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0100ee6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ee9:	29 c8                	sub    %ecx,%eax
f0100eeb:	c1 f8 03             	sar    $0x3,%eax
f0100eee:	c1 e0 0c             	shl    $0xc,%eax
f0100ef1:	39 c2                	cmp    %eax,%edx
f0100ef3:	77 19                	ja     f0100f0e <mem_init+0x4d0>
f0100ef5:	68 df 27 10 f0       	push   $0xf01027df
f0100efa:	68 a6 26 10 f0       	push   $0xf01026a6
f0100eff:	68 3c 02 00 00       	push   $0x23c
f0100f04:	68 6c 26 10 f0       	push   $0xf010266c
f0100f09:	e8 7d f1 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0100f0e:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f13:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0100f16:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0100f1d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0100f20:	83 ec 0c             	sub    $0xc,%esp
f0100f23:	6a 00                	push   $0x0
f0100f25:	e8 6c fa ff ff       	call   f0100996 <page_alloc>
f0100f2a:	83 c4 10             	add    $0x10,%esp
f0100f2d:	85 c0                	test   %eax,%eax
f0100f2f:	74 19                	je     f0100f4a <mem_init+0x50c>
f0100f31:	68 fc 27 10 f0       	push   $0xf01027fc
f0100f36:	68 a6 26 10 f0       	push   $0xf01026a6
f0100f3b:	68 43 02 00 00       	push   $0x243
f0100f40:	68 6c 26 10 f0       	push   $0xf010266c
f0100f45:	e8 41 f1 ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0100f4a:	83 ec 0c             	sub    $0xc,%esp
f0100f4d:	57                   	push   %edi
f0100f4e:	e8 b3 fa ff ff       	call   f0100a06 <page_free>
	page_free(pp1);
f0100f53:	89 34 24             	mov    %esi,(%esp)
f0100f56:	e8 ab fa ff ff       	call   f0100a06 <page_free>
	page_free(pp2);
f0100f5b:	83 c4 04             	add    $0x4,%esp
f0100f5e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f61:	e8 a0 fa ff ff       	call   f0100a06 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100f6d:	e8 24 fa ff ff       	call   f0100996 <page_alloc>
f0100f72:	89 c6                	mov    %eax,%esi
f0100f74:	83 c4 10             	add    $0x10,%esp
f0100f77:	85 c0                	test   %eax,%eax
f0100f79:	75 19                	jne    f0100f94 <mem_init+0x556>
f0100f7b:	68 51 27 10 f0       	push   $0xf0102751
f0100f80:	68 a6 26 10 f0       	push   $0xf01026a6
f0100f85:	68 4a 02 00 00       	push   $0x24a
f0100f8a:	68 6c 26 10 f0       	push   $0xf010266c
f0100f8f:	e8 f7 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100f94:	83 ec 0c             	sub    $0xc,%esp
f0100f97:	6a 00                	push   $0x0
f0100f99:	e8 f8 f9 ff ff       	call   f0100996 <page_alloc>
f0100f9e:	89 c7                	mov    %eax,%edi
f0100fa0:	83 c4 10             	add    $0x10,%esp
f0100fa3:	85 c0                	test   %eax,%eax
f0100fa5:	75 19                	jne    f0100fc0 <mem_init+0x582>
f0100fa7:	68 67 27 10 f0       	push   $0xf0102767
f0100fac:	68 a6 26 10 f0       	push   $0xf01026a6
f0100fb1:	68 4b 02 00 00       	push   $0x24b
f0100fb6:	68 6c 26 10 f0       	push   $0xf010266c
f0100fbb:	e8 cb f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fc0:	83 ec 0c             	sub    $0xc,%esp
f0100fc3:	6a 00                	push   $0x0
f0100fc5:	e8 cc f9 ff ff       	call   f0100996 <page_alloc>
f0100fca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100fcd:	83 c4 10             	add    $0x10,%esp
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	75 19                	jne    f0100fed <mem_init+0x5af>
f0100fd4:	68 7d 27 10 f0       	push   $0xf010277d
f0100fd9:	68 a6 26 10 f0       	push   $0xf01026a6
f0100fde:	68 4c 02 00 00       	push   $0x24c
f0100fe3:	68 6c 26 10 f0       	push   $0xf010266c
f0100fe8:	e8 9e f0 ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100fed:	39 fe                	cmp    %edi,%esi
f0100fef:	75 19                	jne    f010100a <mem_init+0x5cc>
f0100ff1:	68 93 27 10 f0       	push   $0xf0102793
f0100ff6:	68 a6 26 10 f0       	push   $0xf01026a6
f0100ffb:	68 4e 02 00 00       	push   $0x24e
f0101000:	68 6c 26 10 f0       	push   $0xf010266c
f0101005:	e8 81 f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010100a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010100d:	39 c6                	cmp    %eax,%esi
f010100f:	74 04                	je     f0101015 <mem_init+0x5d7>
f0101011:	39 c7                	cmp    %eax,%edi
f0101013:	75 19                	jne    f010102e <mem_init+0x5f0>
f0101015:	68 ac 29 10 f0       	push   $0xf01029ac
f010101a:	68 a6 26 10 f0       	push   $0xf01026a6
f010101f:	68 4f 02 00 00       	push   $0x24f
f0101024:	68 6c 26 10 f0       	push   $0xf010266c
f0101029:	e8 5d f0 ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010102e:	83 ec 0c             	sub    $0xc,%esp
f0101031:	6a 00                	push   $0x0
f0101033:	e8 5e f9 ff ff       	call   f0100996 <page_alloc>
f0101038:	83 c4 10             	add    $0x10,%esp
f010103b:	85 c0                	test   %eax,%eax
f010103d:	74 19                	je     f0101058 <mem_init+0x61a>
f010103f:	68 fc 27 10 f0       	push   $0xf01027fc
f0101044:	68 a6 26 10 f0       	push   $0xf01026a6
f0101049:	68 50 02 00 00       	push   $0x250
f010104e:	68 6c 26 10 f0       	push   $0xf010266c
f0101053:	e8 33 f0 ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101058:	89 f0                	mov    %esi,%eax
f010105a:	e8 6e f8 ff ff       	call   f01008cd <page2kva>
f010105f:	83 ec 04             	sub    $0x4,%esp
f0101062:	68 00 10 00 00       	push   $0x1000
f0101067:	6a 01                	push   $0x1
f0101069:	50                   	push   %eax
f010106a:	e8 a0 0c 00 00       	call   f0101d0f <memset>
	page_free(pp0);
f010106f:	89 34 24             	mov    %esi,(%esp)
f0101072:	e8 8f f9 ff ff       	call   f0100a06 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101077:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010107e:	e8 13 f9 ff ff       	call   f0100996 <page_alloc>
f0101083:	83 c4 10             	add    $0x10,%esp
f0101086:	85 c0                	test   %eax,%eax
f0101088:	75 19                	jne    f01010a3 <mem_init+0x665>
f010108a:	68 0b 28 10 f0       	push   $0xf010280b
f010108f:	68 a6 26 10 f0       	push   $0xf01026a6
f0101094:	68 55 02 00 00       	push   $0x255
f0101099:	68 6c 26 10 f0       	push   $0xf010266c
f010109e:	e8 e8 ef ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01010a3:	39 c6                	cmp    %eax,%esi
f01010a5:	74 19                	je     f01010c0 <mem_init+0x682>
f01010a7:	68 29 28 10 f0       	push   $0xf0102829
f01010ac:	68 a6 26 10 f0       	push   $0xf01026a6
f01010b1:	68 56 02 00 00       	push   $0x256
f01010b6:	68 6c 26 10 f0       	push   $0xf010266c
f01010bb:	e8 cb ef ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f01010c0:	89 f0                	mov    %esi,%eax
f01010c2:	e8 06 f8 ff ff       	call   f01008cd <page2kva>
f01010c7:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01010cd:	80 38 00             	cmpb   $0x0,(%eax)
f01010d0:	74 19                	je     f01010eb <mem_init+0x6ad>
f01010d2:	68 39 28 10 f0       	push   $0xf0102839
f01010d7:	68 a6 26 10 f0       	push   $0xf01026a6
f01010dc:	68 59 02 00 00       	push   $0x259
f01010e1:	68 6c 26 10 f0       	push   $0xf010266c
f01010e6:	e8 a0 ef ff ff       	call   f010008b <_panic>
f01010eb:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01010ee:	39 d0                	cmp    %edx,%eax
f01010f0:	75 db                	jne    f01010cd <mem_init+0x68f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01010f2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010f5:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f01010fa:	83 ec 0c             	sub    $0xc,%esp
f01010fd:	56                   	push   %esi
f01010fe:	e8 03 f9 ff ff       	call   f0100a06 <page_free>
	page_free(pp1);
f0101103:	89 3c 24             	mov    %edi,(%esp)
f0101106:	e8 fb f8 ff ff       	call   f0100a06 <page_free>
	page_free(pp2);
f010110b:	83 c4 04             	add    $0x4,%esp
f010110e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101111:	e8 f0 f8 ff ff       	call   f0100a06 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101116:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f010111b:	83 c4 10             	add    $0x10,%esp
f010111e:	eb 05                	jmp    f0101125 <mem_init+0x6e7>
		--nfree;
f0101120:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101123:	8b 00                	mov    (%eax),%eax
f0101125:	85 c0                	test   %eax,%eax
f0101127:	75 f7                	jne    f0101120 <mem_init+0x6e2>
		--nfree;
	assert(nfree == 0);
f0101129:	85 db                	test   %ebx,%ebx
f010112b:	74 19                	je     f0101146 <mem_init+0x708>
f010112d:	68 43 28 10 f0       	push   $0xf0102843
f0101132:	68 a6 26 10 f0       	push   $0xf01026a6
f0101137:	68 66 02 00 00       	push   $0x266
f010113c:	68 6c 26 10 f0       	push   $0xf010266c
f0101141:	e8 45 ef ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101146:	83 ec 0c             	sub    $0xc,%esp
f0101149:	68 cc 29 10 f0       	push   $0xf01029cc
f010114e:	e8 d3 00 00 00       	call   f0101226 <cprintf>
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	panic("lab2 part 1 ends /n");
f0101153:	83 c4 0c             	add    $0xc,%esp
f0101156:	68 4e 28 10 f0       	push   $0xf010284e
f010115b:	68 b6 00 00 00       	push   $0xb6
f0101160:	68 6c 26 10 f0       	push   $0xf010266c
f0101165:	e8 21 ef ff ff       	call   f010008b <_panic>

f010116a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010116a:	55                   	push   %ebp
f010116b:	89 e5                	mov    %esp,%ebp
f010116d:	83 ec 08             	sub    $0x8,%esp
f0101170:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101173:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101177:	83 e8 01             	sub    $0x1,%eax
f010117a:	66 89 42 04          	mov    %ax,0x4(%edx)
f010117e:	66 85 c0             	test   %ax,%ax
f0101181:	75 0c                	jne    f010118f <page_decref+0x25>
		page_free(pp);
f0101183:	83 ec 0c             	sub    $0xc,%esp
f0101186:	52                   	push   %edx
f0101187:	e8 7a f8 ff ff       	call   f0100a06 <page_free>
f010118c:	83 c4 10             	add    $0x10,%esp
}
f010118f:	c9                   	leave  
f0101190:	c3                   	ret    

f0101191 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101191:	55                   	push   %ebp
f0101192:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101194:	b8 00 00 00 00       	mov    $0x0,%eax
f0101199:	5d                   	pop    %ebp
f010119a:	c3                   	ret    

f010119b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010119b:	55                   	push   %ebp
f010119c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010119e:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a3:	5d                   	pop    %ebp
f01011a4:	c3                   	ret    

f01011a5 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011a5:	55                   	push   %ebp
f01011a6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01011a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ad:	5d                   	pop    %ebp
f01011ae:	c3                   	ret    

f01011af <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011af:	55                   	push   %ebp
f01011b0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01011b2:	5d                   	pop    %ebp
f01011b3:	c3                   	ret    

f01011b4 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011b4:	55                   	push   %ebp
f01011b5:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ba:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01011bd:	5d                   	pop    %ebp
f01011be:	c3                   	ret    

f01011bf <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01011bf:	55                   	push   %ebp
f01011c0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01011c2:	ba 70 00 00 00       	mov    $0x70,%edx
f01011c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ca:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01011cb:	ba 71 00 00 00       	mov    $0x71,%edx
f01011d0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01011d1:	0f b6 c0             	movzbl %al,%eax
}
f01011d4:	5d                   	pop    %ebp
f01011d5:	c3                   	ret    

f01011d6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01011d6:	55                   	push   %ebp
f01011d7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01011d9:	ba 70 00 00 00       	mov    $0x70,%edx
f01011de:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e1:	ee                   	out    %al,(%dx)
f01011e2:	ba 71 00 00 00       	mov    $0x71,%edx
f01011e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ea:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01011eb:	5d                   	pop    %ebp
f01011ec:	c3                   	ret    

f01011ed <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01011ed:	55                   	push   %ebp
f01011ee:	89 e5                	mov    %esp,%ebp
f01011f0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01011f3:	ff 75 08             	pushl  0x8(%ebp)
f01011f6:	e8 05 f4 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01011fb:	83 c4 10             	add    $0x10,%esp
f01011fe:	c9                   	leave  
f01011ff:	c3                   	ret    

f0101200 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101200:	55                   	push   %ebp
f0101201:	89 e5                	mov    %esp,%ebp
f0101203:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101206:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010120d:	ff 75 0c             	pushl  0xc(%ebp)
f0101210:	ff 75 08             	pushl  0x8(%ebp)
f0101213:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101216:	50                   	push   %eax
f0101217:	68 ed 11 10 f0       	push   $0xf01011ed
f010121c:	e8 c9 03 00 00       	call   f01015ea <vprintfmt>
	return cnt;
}
f0101221:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101224:	c9                   	leave  
f0101225:	c3                   	ret    

f0101226 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010122c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010122f:	50                   	push   %eax
f0101230:	ff 75 08             	pushl  0x8(%ebp)
f0101233:	e8 c8 ff ff ff       	call   f0101200 <vcprintf>
	va_end(ap);

	return cnt;
}
f0101238:	c9                   	leave  
f0101239:	c3                   	ret    

f010123a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010123a:	55                   	push   %ebp
f010123b:	89 e5                	mov    %esp,%ebp
f010123d:	57                   	push   %edi
f010123e:	56                   	push   %esi
f010123f:	53                   	push   %ebx
f0101240:	83 ec 14             	sub    $0x14,%esp
f0101243:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101246:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101249:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010124c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010124f:	8b 1a                	mov    (%edx),%ebx
f0101251:	8b 01                	mov    (%ecx),%eax
f0101253:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101256:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010125d:	eb 7f                	jmp    f01012de <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010125f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101262:	01 d8                	add    %ebx,%eax
f0101264:	89 c6                	mov    %eax,%esi
f0101266:	c1 ee 1f             	shr    $0x1f,%esi
f0101269:	01 c6                	add    %eax,%esi
f010126b:	d1 fe                	sar    %esi
f010126d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101270:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101273:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101276:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101278:	eb 03                	jmp    f010127d <stab_binsearch+0x43>
			m--;
f010127a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010127d:	39 c3                	cmp    %eax,%ebx
f010127f:	7f 0d                	jg     f010128e <stab_binsearch+0x54>
f0101281:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101285:	83 ea 0c             	sub    $0xc,%edx
f0101288:	39 f9                	cmp    %edi,%ecx
f010128a:	75 ee                	jne    f010127a <stab_binsearch+0x40>
f010128c:	eb 05                	jmp    f0101293 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010128e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101291:	eb 4b                	jmp    f01012de <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101293:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101296:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101299:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010129d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01012a0:	76 11                	jbe    f01012b3 <stab_binsearch+0x79>
			*region_left = m;
f01012a2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01012a5:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01012a7:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01012aa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01012b1:	eb 2b                	jmp    f01012de <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01012b3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01012b6:	73 14                	jae    f01012cc <stab_binsearch+0x92>
			*region_right = m - 1;
f01012b8:	83 e8 01             	sub    $0x1,%eax
f01012bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01012be:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01012c1:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01012c3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01012ca:	eb 12                	jmp    f01012de <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01012cc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01012cf:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01012d1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01012d5:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01012d7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01012de:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01012e1:	0f 8e 78 ff ff ff    	jle    f010125f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01012e7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01012eb:	75 0f                	jne    f01012fc <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01012ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012f0:	8b 00                	mov    (%eax),%eax
f01012f2:	83 e8 01             	sub    $0x1,%eax
f01012f5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01012f8:	89 06                	mov    %eax,(%esi)
f01012fa:	eb 2c                	jmp    f0101328 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01012fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012ff:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101301:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101304:	8b 0e                	mov    (%esi),%ecx
f0101306:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101309:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010130c:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010130f:	eb 03                	jmp    f0101314 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101311:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101314:	39 c8                	cmp    %ecx,%eax
f0101316:	7e 0b                	jle    f0101323 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101318:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010131c:	83 ea 0c             	sub    $0xc,%edx
f010131f:	39 df                	cmp    %ebx,%edi
f0101321:	75 ee                	jne    f0101311 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101323:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101326:	89 06                	mov    %eax,(%esi)
	}
}
f0101328:	83 c4 14             	add    $0x14,%esp
f010132b:	5b                   	pop    %ebx
f010132c:	5e                   	pop    %esi
f010132d:	5f                   	pop    %edi
f010132e:	5d                   	pop    %ebp
f010132f:	c3                   	ret    

f0101330 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101330:	55                   	push   %ebp
f0101331:	89 e5                	mov    %esp,%ebp
f0101333:	57                   	push   %edi
f0101334:	56                   	push   %esi
f0101335:	53                   	push   %ebx
f0101336:	83 ec 1c             	sub    $0x1c,%esp
f0101339:	8b 7d 08             	mov    0x8(%ebp),%edi
f010133c:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010133f:	c7 06 ec 29 10 f0    	movl   $0xf01029ec,(%esi)
	info->eip_line = 0;
f0101345:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010134c:	c7 46 08 ec 29 10 f0 	movl   $0xf01029ec,0x8(%esi)
	info->eip_fn_namelen = 9;
f0101353:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010135a:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010135d:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101364:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010136a:	76 11                	jbe    f010137d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010136c:	b8 35 90 10 f0       	mov    $0xf0109035,%eax
f0101371:	3d f1 73 10 f0       	cmp    $0xf01073f1,%eax
f0101376:	77 19                	ja     f0101391 <debuginfo_eip+0x61>
f0101378:	e9 62 01 00 00       	jmp    f01014df <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010137d:	83 ec 04             	sub    $0x4,%esp
f0101380:	68 f6 29 10 f0       	push   $0xf01029f6
f0101385:	6a 7f                	push   $0x7f
f0101387:	68 03 2a 10 f0       	push   $0xf0102a03
f010138c:	e8 fa ec ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101391:	80 3d 34 90 10 f0 00 	cmpb   $0x0,0xf0109034
f0101398:	0f 85 48 01 00 00    	jne    f01014e6 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010139e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01013a5:	b8 f0 73 10 f0       	mov    $0xf01073f0,%eax
f01013aa:	2d 20 2c 10 f0       	sub    $0xf0102c20,%eax
f01013af:	c1 f8 02             	sar    $0x2,%eax
f01013b2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01013b8:	83 e8 01             	sub    $0x1,%eax
f01013bb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01013be:	83 ec 08             	sub    $0x8,%esp
f01013c1:	57                   	push   %edi
f01013c2:	6a 64                	push   $0x64
f01013c4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01013c7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01013ca:	b8 20 2c 10 f0       	mov    $0xf0102c20,%eax
f01013cf:	e8 66 fe ff ff       	call   f010123a <stab_binsearch>
	if (lfile == 0)
f01013d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013d7:	83 c4 10             	add    $0x10,%esp
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	0f 84 0b 01 00 00    	je     f01014ed <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01013e2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01013e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013e8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01013eb:	83 ec 08             	sub    $0x8,%esp
f01013ee:	57                   	push   %edi
f01013ef:	6a 24                	push   $0x24
f01013f1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01013f4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01013f7:	b8 20 2c 10 f0       	mov    $0xf0102c20,%eax
f01013fc:	e8 39 fe ff ff       	call   f010123a <stab_binsearch>

	if (lfun <= rfun) {
f0101401:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101404:	83 c4 10             	add    $0x10,%esp
f0101407:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010140a:	7f 31                	jg     f010143d <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010140c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010140f:	c1 e0 02             	shl    $0x2,%eax
f0101412:	8d 90 20 2c 10 f0    	lea    -0xfefd3e0(%eax),%edx
f0101418:	8b 88 20 2c 10 f0    	mov    -0xfefd3e0(%eax),%ecx
f010141e:	b8 35 90 10 f0       	mov    $0xf0109035,%eax
f0101423:	2d f1 73 10 f0       	sub    $0xf01073f1,%eax
f0101428:	39 c1                	cmp    %eax,%ecx
f010142a:	73 09                	jae    f0101435 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010142c:	81 c1 f1 73 10 f0    	add    $0xf01073f1,%ecx
f0101432:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101435:	8b 42 08             	mov    0x8(%edx),%eax
f0101438:	89 46 10             	mov    %eax,0x10(%esi)
f010143b:	eb 06                	jmp    f0101443 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010143d:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0101440:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101443:	83 ec 08             	sub    $0x8,%esp
f0101446:	6a 3a                	push   $0x3a
f0101448:	ff 76 08             	pushl  0x8(%esi)
f010144b:	e8 a3 08 00 00       	call   f0101cf3 <strfind>
f0101450:	2b 46 08             	sub    0x8(%esi),%eax
f0101453:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101456:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101459:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010145c:	8d 04 85 20 2c 10 f0 	lea    -0xfefd3e0(,%eax,4),%eax
f0101463:	83 c4 10             	add    $0x10,%esp
f0101466:	eb 06                	jmp    f010146e <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101468:	83 eb 01             	sub    $0x1,%ebx
f010146b:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010146e:	39 fb                	cmp    %edi,%ebx
f0101470:	7c 34                	jl     f01014a6 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0101472:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0101476:	80 fa 84             	cmp    $0x84,%dl
f0101479:	74 0b                	je     f0101486 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010147b:	80 fa 64             	cmp    $0x64,%dl
f010147e:	75 e8                	jne    f0101468 <debuginfo_eip+0x138>
f0101480:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0101484:	74 e2                	je     f0101468 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101486:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101489:	8b 14 85 20 2c 10 f0 	mov    -0xfefd3e0(,%eax,4),%edx
f0101490:	b8 35 90 10 f0       	mov    $0xf0109035,%eax
f0101495:	2d f1 73 10 f0       	sub    $0xf01073f1,%eax
f010149a:	39 c2                	cmp    %eax,%edx
f010149c:	73 08                	jae    f01014a6 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010149e:	81 c2 f1 73 10 f0    	add    $0xf01073f1,%edx
f01014a4:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01014a6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01014a9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01014ac:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01014b1:	39 cb                	cmp    %ecx,%ebx
f01014b3:	7d 44                	jge    f01014f9 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f01014b5:	8d 53 01             	lea    0x1(%ebx),%edx
f01014b8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01014bb:	8d 04 85 20 2c 10 f0 	lea    -0xfefd3e0(,%eax,4),%eax
f01014c2:	eb 07                	jmp    f01014cb <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01014c4:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01014c8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01014cb:	39 ca                	cmp    %ecx,%edx
f01014cd:	74 25                	je     f01014f4 <debuginfo_eip+0x1c4>
f01014cf:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01014d2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01014d6:	74 ec                	je     f01014c4 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01014d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01014dd:	eb 1a                	jmp    f01014f9 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01014df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014e4:	eb 13                	jmp    f01014f9 <debuginfo_eip+0x1c9>
f01014e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014eb:	eb 0c                	jmp    f01014f9 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01014ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014f2:	eb 05                	jmp    f01014f9 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01014f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014fc:	5b                   	pop    %ebx
f01014fd:	5e                   	pop    %esi
f01014fe:	5f                   	pop    %edi
f01014ff:	5d                   	pop    %ebp
f0101500:	c3                   	ret    

f0101501 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101501:	55                   	push   %ebp
f0101502:	89 e5                	mov    %esp,%ebp
f0101504:	57                   	push   %edi
f0101505:	56                   	push   %esi
f0101506:	53                   	push   %ebx
f0101507:	83 ec 1c             	sub    $0x1c,%esp
f010150a:	89 c7                	mov    %eax,%edi
f010150c:	89 d6                	mov    %edx,%esi
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101514:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101517:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010151a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010151d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101522:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101525:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101528:	39 d3                	cmp    %edx,%ebx
f010152a:	72 05                	jb     f0101531 <printnum+0x30>
f010152c:	39 45 10             	cmp    %eax,0x10(%ebp)
f010152f:	77 45                	ja     f0101576 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101531:	83 ec 0c             	sub    $0xc,%esp
f0101534:	ff 75 18             	pushl  0x18(%ebp)
f0101537:	8b 45 14             	mov    0x14(%ebp),%eax
f010153a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010153d:	53                   	push   %ebx
f010153e:	ff 75 10             	pushl  0x10(%ebp)
f0101541:	83 ec 08             	sub    $0x8,%esp
f0101544:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101547:	ff 75 e0             	pushl  -0x20(%ebp)
f010154a:	ff 75 dc             	pushl  -0x24(%ebp)
f010154d:	ff 75 d8             	pushl  -0x28(%ebp)
f0101550:	e8 cb 09 00 00       	call   f0101f20 <__udivdi3>
f0101555:	83 c4 18             	add    $0x18,%esp
f0101558:	52                   	push   %edx
f0101559:	50                   	push   %eax
f010155a:	89 f2                	mov    %esi,%edx
f010155c:	89 f8                	mov    %edi,%eax
f010155e:	e8 9e ff ff ff       	call   f0101501 <printnum>
f0101563:	83 c4 20             	add    $0x20,%esp
f0101566:	eb 18                	jmp    f0101580 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101568:	83 ec 08             	sub    $0x8,%esp
f010156b:	56                   	push   %esi
f010156c:	ff 75 18             	pushl  0x18(%ebp)
f010156f:	ff d7                	call   *%edi
f0101571:	83 c4 10             	add    $0x10,%esp
f0101574:	eb 03                	jmp    f0101579 <printnum+0x78>
f0101576:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101579:	83 eb 01             	sub    $0x1,%ebx
f010157c:	85 db                	test   %ebx,%ebx
f010157e:	7f e8                	jg     f0101568 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101580:	83 ec 08             	sub    $0x8,%esp
f0101583:	56                   	push   %esi
f0101584:	83 ec 04             	sub    $0x4,%esp
f0101587:	ff 75 e4             	pushl  -0x1c(%ebp)
f010158a:	ff 75 e0             	pushl  -0x20(%ebp)
f010158d:	ff 75 dc             	pushl  -0x24(%ebp)
f0101590:	ff 75 d8             	pushl  -0x28(%ebp)
f0101593:	e8 b8 0a 00 00       	call   f0102050 <__umoddi3>
f0101598:	83 c4 14             	add    $0x14,%esp
f010159b:	0f be 80 11 2a 10 f0 	movsbl -0xfefd5ef(%eax),%eax
f01015a2:	50                   	push   %eax
f01015a3:	ff d7                	call   *%edi
}
f01015a5:	83 c4 10             	add    $0x10,%esp
f01015a8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015ab:	5b                   	pop    %ebx
f01015ac:	5e                   	pop    %esi
f01015ad:	5f                   	pop    %edi
f01015ae:	5d                   	pop    %ebp
f01015af:	c3                   	ret    

f01015b0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01015b6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01015ba:	8b 10                	mov    (%eax),%edx
f01015bc:	3b 50 04             	cmp    0x4(%eax),%edx
f01015bf:	73 0a                	jae    f01015cb <sprintputch+0x1b>
		*b->buf++ = ch;
f01015c1:	8d 4a 01             	lea    0x1(%edx),%ecx
f01015c4:	89 08                	mov    %ecx,(%eax)
f01015c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c9:	88 02                	mov    %al,(%edx)
}
f01015cb:	5d                   	pop    %ebp
f01015cc:	c3                   	ret    

f01015cd <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01015cd:	55                   	push   %ebp
f01015ce:	89 e5                	mov    %esp,%ebp
f01015d0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01015d3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01015d6:	50                   	push   %eax
f01015d7:	ff 75 10             	pushl  0x10(%ebp)
f01015da:	ff 75 0c             	pushl  0xc(%ebp)
f01015dd:	ff 75 08             	pushl  0x8(%ebp)
f01015e0:	e8 05 00 00 00       	call   f01015ea <vprintfmt>
	va_end(ap);
}
f01015e5:	83 c4 10             	add    $0x10,%esp
f01015e8:	c9                   	leave  
f01015e9:	c3                   	ret    

f01015ea <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01015ea:	55                   	push   %ebp
f01015eb:	89 e5                	mov    %esp,%ebp
f01015ed:	57                   	push   %edi
f01015ee:	56                   	push   %esi
f01015ef:	53                   	push   %ebx
f01015f0:	83 ec 2c             	sub    $0x2c,%esp
f01015f3:	8b 75 08             	mov    0x8(%ebp),%esi
f01015f6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01015f9:	8b 7d 10             	mov    0x10(%ebp),%edi
f01015fc:	eb 12                	jmp    f0101610 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01015fe:	85 c0                	test   %eax,%eax
f0101600:	0f 84 42 04 00 00    	je     f0101a48 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0101606:	83 ec 08             	sub    $0x8,%esp
f0101609:	53                   	push   %ebx
f010160a:	50                   	push   %eax
f010160b:	ff d6                	call   *%esi
f010160d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101610:	83 c7 01             	add    $0x1,%edi
f0101613:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101617:	83 f8 25             	cmp    $0x25,%eax
f010161a:	75 e2                	jne    f01015fe <vprintfmt+0x14>
f010161c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0101620:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101627:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010162e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0101635:	b9 00 00 00 00       	mov    $0x0,%ecx
f010163a:	eb 07                	jmp    f0101643 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010163c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010163f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101643:	8d 47 01             	lea    0x1(%edi),%eax
f0101646:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101649:	0f b6 07             	movzbl (%edi),%eax
f010164c:	0f b6 d0             	movzbl %al,%edx
f010164f:	83 e8 23             	sub    $0x23,%eax
f0101652:	3c 55                	cmp    $0x55,%al
f0101654:	0f 87 d3 03 00 00    	ja     f0101a2d <vprintfmt+0x443>
f010165a:	0f b6 c0             	movzbl %al,%eax
f010165d:	ff 24 85 9c 2a 10 f0 	jmp    *-0xfefd564(,%eax,4)
f0101664:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101667:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010166b:	eb d6                	jmp    f0101643 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010166d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101670:	b8 00 00 00 00       	mov    $0x0,%eax
f0101675:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101678:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010167b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010167f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101682:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101685:	83 f9 09             	cmp    $0x9,%ecx
f0101688:	77 3f                	ja     f01016c9 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010168a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010168d:	eb e9                	jmp    f0101678 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010168f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101692:	8b 00                	mov    (%eax),%eax
f0101694:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101697:	8b 45 14             	mov    0x14(%ebp),%eax
f010169a:	8d 40 04             	lea    0x4(%eax),%eax
f010169d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01016a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01016a3:	eb 2a                	jmp    f01016cf <vprintfmt+0xe5>
f01016a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016a8:	85 c0                	test   %eax,%eax
f01016aa:	ba 00 00 00 00       	mov    $0x0,%edx
f01016af:	0f 49 d0             	cmovns %eax,%edx
f01016b2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01016b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01016b8:	eb 89                	jmp    f0101643 <vprintfmt+0x59>
f01016ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01016bd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01016c4:	e9 7a ff ff ff       	jmp    f0101643 <vprintfmt+0x59>
f01016c9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01016cc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01016cf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01016d3:	0f 89 6a ff ff ff    	jns    f0101643 <vprintfmt+0x59>
				width = precision, precision = -1;
f01016d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01016df:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01016e6:	e9 58 ff ff ff       	jmp    f0101643 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01016eb:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01016ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01016f1:	e9 4d ff ff ff       	jmp    f0101643 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01016f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01016f9:	8d 78 04             	lea    0x4(%eax),%edi
f01016fc:	83 ec 08             	sub    $0x8,%esp
f01016ff:	53                   	push   %ebx
f0101700:	ff 30                	pushl  (%eax)
f0101702:	ff d6                	call   *%esi
			break;
f0101704:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101707:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010170a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010170d:	e9 fe fe ff ff       	jmp    f0101610 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101712:	8b 45 14             	mov    0x14(%ebp),%eax
f0101715:	8d 78 04             	lea    0x4(%eax),%edi
f0101718:	8b 00                	mov    (%eax),%eax
f010171a:	99                   	cltd   
f010171b:	31 d0                	xor    %edx,%eax
f010171d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010171f:	83 f8 06             	cmp    $0x6,%eax
f0101722:	7f 0b                	jg     f010172f <vprintfmt+0x145>
f0101724:	8b 14 85 f4 2b 10 f0 	mov    -0xfefd40c(,%eax,4),%edx
f010172b:	85 d2                	test   %edx,%edx
f010172d:	75 1b                	jne    f010174a <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f010172f:	50                   	push   %eax
f0101730:	68 29 2a 10 f0       	push   $0xf0102a29
f0101735:	53                   	push   %ebx
f0101736:	56                   	push   %esi
f0101737:	e8 91 fe ff ff       	call   f01015cd <printfmt>
f010173c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010173f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101742:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101745:	e9 c6 fe ff ff       	jmp    f0101610 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010174a:	52                   	push   %edx
f010174b:	68 b8 26 10 f0       	push   $0xf01026b8
f0101750:	53                   	push   %ebx
f0101751:	56                   	push   %esi
f0101752:	e8 76 fe ff ff       	call   f01015cd <printfmt>
f0101757:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010175a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010175d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101760:	e9 ab fe ff ff       	jmp    f0101610 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101765:	8b 45 14             	mov    0x14(%ebp),%eax
f0101768:	83 c0 04             	add    $0x4,%eax
f010176b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010176e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101771:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101773:	85 ff                	test   %edi,%edi
f0101775:	b8 22 2a 10 f0       	mov    $0xf0102a22,%eax
f010177a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010177d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101781:	0f 8e 94 00 00 00    	jle    f010181b <vprintfmt+0x231>
f0101787:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010178b:	0f 84 98 00 00 00    	je     f0101829 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101791:	83 ec 08             	sub    $0x8,%esp
f0101794:	ff 75 d0             	pushl  -0x30(%ebp)
f0101797:	57                   	push   %edi
f0101798:	e8 0c 04 00 00       	call   f0101ba9 <strnlen>
f010179d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01017a0:	29 c1                	sub    %eax,%ecx
f01017a2:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01017a5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01017a8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01017ac:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01017af:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01017b2:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01017b4:	eb 0f                	jmp    f01017c5 <vprintfmt+0x1db>
					putch(padc, putdat);
f01017b6:	83 ec 08             	sub    $0x8,%esp
f01017b9:	53                   	push   %ebx
f01017ba:	ff 75 e0             	pushl  -0x20(%ebp)
f01017bd:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01017bf:	83 ef 01             	sub    $0x1,%edi
f01017c2:	83 c4 10             	add    $0x10,%esp
f01017c5:	85 ff                	test   %edi,%edi
f01017c7:	7f ed                	jg     f01017b6 <vprintfmt+0x1cc>
f01017c9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01017cc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01017cf:	85 c9                	test   %ecx,%ecx
f01017d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01017d6:	0f 49 c1             	cmovns %ecx,%eax
f01017d9:	29 c1                	sub    %eax,%ecx
f01017db:	89 75 08             	mov    %esi,0x8(%ebp)
f01017de:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01017e1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01017e4:	89 cb                	mov    %ecx,%ebx
f01017e6:	eb 4d                	jmp    f0101835 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01017e8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01017ec:	74 1b                	je     f0101809 <vprintfmt+0x21f>
f01017ee:	0f be c0             	movsbl %al,%eax
f01017f1:	83 e8 20             	sub    $0x20,%eax
f01017f4:	83 f8 5e             	cmp    $0x5e,%eax
f01017f7:	76 10                	jbe    f0101809 <vprintfmt+0x21f>
					putch('?', putdat);
f01017f9:	83 ec 08             	sub    $0x8,%esp
f01017fc:	ff 75 0c             	pushl  0xc(%ebp)
f01017ff:	6a 3f                	push   $0x3f
f0101801:	ff 55 08             	call   *0x8(%ebp)
f0101804:	83 c4 10             	add    $0x10,%esp
f0101807:	eb 0d                	jmp    f0101816 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0101809:	83 ec 08             	sub    $0x8,%esp
f010180c:	ff 75 0c             	pushl  0xc(%ebp)
f010180f:	52                   	push   %edx
f0101810:	ff 55 08             	call   *0x8(%ebp)
f0101813:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101816:	83 eb 01             	sub    $0x1,%ebx
f0101819:	eb 1a                	jmp    f0101835 <vprintfmt+0x24b>
f010181b:	89 75 08             	mov    %esi,0x8(%ebp)
f010181e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101821:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101824:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101827:	eb 0c                	jmp    f0101835 <vprintfmt+0x24b>
f0101829:	89 75 08             	mov    %esi,0x8(%ebp)
f010182c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010182f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101832:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101835:	83 c7 01             	add    $0x1,%edi
f0101838:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010183c:	0f be d0             	movsbl %al,%edx
f010183f:	85 d2                	test   %edx,%edx
f0101841:	74 23                	je     f0101866 <vprintfmt+0x27c>
f0101843:	85 f6                	test   %esi,%esi
f0101845:	78 a1                	js     f01017e8 <vprintfmt+0x1fe>
f0101847:	83 ee 01             	sub    $0x1,%esi
f010184a:	79 9c                	jns    f01017e8 <vprintfmt+0x1fe>
f010184c:	89 df                	mov    %ebx,%edi
f010184e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101851:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101854:	eb 18                	jmp    f010186e <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101856:	83 ec 08             	sub    $0x8,%esp
f0101859:	53                   	push   %ebx
f010185a:	6a 20                	push   $0x20
f010185c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010185e:	83 ef 01             	sub    $0x1,%edi
f0101861:	83 c4 10             	add    $0x10,%esp
f0101864:	eb 08                	jmp    f010186e <vprintfmt+0x284>
f0101866:	89 df                	mov    %ebx,%edi
f0101868:	8b 75 08             	mov    0x8(%ebp),%esi
f010186b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010186e:	85 ff                	test   %edi,%edi
f0101870:	7f e4                	jg     f0101856 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101872:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101875:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101878:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010187b:	e9 90 fd ff ff       	jmp    f0101610 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101880:	83 f9 01             	cmp    $0x1,%ecx
f0101883:	7e 19                	jle    f010189e <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0101885:	8b 45 14             	mov    0x14(%ebp),%eax
f0101888:	8b 50 04             	mov    0x4(%eax),%edx
f010188b:	8b 00                	mov    (%eax),%eax
f010188d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101890:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101893:	8b 45 14             	mov    0x14(%ebp),%eax
f0101896:	8d 40 08             	lea    0x8(%eax),%eax
f0101899:	89 45 14             	mov    %eax,0x14(%ebp)
f010189c:	eb 38                	jmp    f01018d6 <vprintfmt+0x2ec>
	else if (lflag)
f010189e:	85 c9                	test   %ecx,%ecx
f01018a0:	74 1b                	je     f01018bd <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01018a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01018a5:	8b 00                	mov    (%eax),%eax
f01018a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018aa:	89 c1                	mov    %eax,%ecx
f01018ac:	c1 f9 1f             	sar    $0x1f,%ecx
f01018af:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01018b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01018b5:	8d 40 04             	lea    0x4(%eax),%eax
f01018b8:	89 45 14             	mov    %eax,0x14(%ebp)
f01018bb:	eb 19                	jmp    f01018d6 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01018bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01018c0:	8b 00                	mov    (%eax),%eax
f01018c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018c5:	89 c1                	mov    %eax,%ecx
f01018c7:	c1 f9 1f             	sar    $0x1f,%ecx
f01018ca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01018cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01018d0:	8d 40 04             	lea    0x4(%eax),%eax
f01018d3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01018d6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01018d9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01018dc:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01018e1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01018e5:	0f 89 0e 01 00 00    	jns    f01019f9 <vprintfmt+0x40f>
				putch('-', putdat);
f01018eb:	83 ec 08             	sub    $0x8,%esp
f01018ee:	53                   	push   %ebx
f01018ef:	6a 2d                	push   $0x2d
f01018f1:	ff d6                	call   *%esi
				num = -(long long) num;
f01018f3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01018f6:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01018f9:	f7 da                	neg    %edx
f01018fb:	83 d1 00             	adc    $0x0,%ecx
f01018fe:	f7 d9                	neg    %ecx
f0101900:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101903:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101908:	e9 ec 00 00 00       	jmp    f01019f9 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010190d:	83 f9 01             	cmp    $0x1,%ecx
f0101910:	7e 18                	jle    f010192a <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0101912:	8b 45 14             	mov    0x14(%ebp),%eax
f0101915:	8b 10                	mov    (%eax),%edx
f0101917:	8b 48 04             	mov    0x4(%eax),%ecx
f010191a:	8d 40 08             	lea    0x8(%eax),%eax
f010191d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101920:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101925:	e9 cf 00 00 00       	jmp    f01019f9 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010192a:	85 c9                	test   %ecx,%ecx
f010192c:	74 1a                	je     f0101948 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f010192e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101931:	8b 10                	mov    (%eax),%edx
f0101933:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101938:	8d 40 04             	lea    0x4(%eax),%eax
f010193b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010193e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101943:	e9 b1 00 00 00       	jmp    f01019f9 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101948:	8b 45 14             	mov    0x14(%ebp),%eax
f010194b:	8b 10                	mov    (%eax),%edx
f010194d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101952:	8d 40 04             	lea    0x4(%eax),%eax
f0101955:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101958:	b8 0a 00 00 00       	mov    $0xa,%eax
f010195d:	e9 97 00 00 00       	jmp    f01019f9 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101962:	83 ec 08             	sub    $0x8,%esp
f0101965:	53                   	push   %ebx
f0101966:	6a 58                	push   $0x58
f0101968:	ff d6                	call   *%esi
			putch('X', putdat);
f010196a:	83 c4 08             	add    $0x8,%esp
f010196d:	53                   	push   %ebx
f010196e:	6a 58                	push   $0x58
f0101970:	ff d6                	call   *%esi
			putch('X', putdat);
f0101972:	83 c4 08             	add    $0x8,%esp
f0101975:	53                   	push   %ebx
f0101976:	6a 58                	push   $0x58
f0101978:	ff d6                	call   *%esi
			break;
f010197a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010197d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101980:	e9 8b fc ff ff       	jmp    f0101610 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101985:	83 ec 08             	sub    $0x8,%esp
f0101988:	53                   	push   %ebx
f0101989:	6a 30                	push   $0x30
f010198b:	ff d6                	call   *%esi
			putch('x', putdat);
f010198d:	83 c4 08             	add    $0x8,%esp
f0101990:	53                   	push   %ebx
f0101991:	6a 78                	push   $0x78
f0101993:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101995:	8b 45 14             	mov    0x14(%ebp),%eax
f0101998:	8b 10                	mov    (%eax),%edx
f010199a:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010199f:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01019a2:	8d 40 04             	lea    0x4(%eax),%eax
f01019a5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01019a8:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01019ad:	eb 4a                	jmp    f01019f9 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01019af:	83 f9 01             	cmp    $0x1,%ecx
f01019b2:	7e 15                	jle    f01019c9 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01019b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01019b7:	8b 10                	mov    (%eax),%edx
f01019b9:	8b 48 04             	mov    0x4(%eax),%ecx
f01019bc:	8d 40 08             	lea    0x8(%eax),%eax
f01019bf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01019c2:	b8 10 00 00 00       	mov    $0x10,%eax
f01019c7:	eb 30                	jmp    f01019f9 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01019c9:	85 c9                	test   %ecx,%ecx
f01019cb:	74 17                	je     f01019e4 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01019cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01019d0:	8b 10                	mov    (%eax),%edx
f01019d2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01019d7:	8d 40 04             	lea    0x4(%eax),%eax
f01019da:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01019dd:	b8 10 00 00 00       	mov    $0x10,%eax
f01019e2:	eb 15                	jmp    f01019f9 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01019e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01019e7:	8b 10                	mov    (%eax),%edx
f01019e9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01019ee:	8d 40 04             	lea    0x4(%eax),%eax
f01019f1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01019f4:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01019f9:	83 ec 0c             	sub    $0xc,%esp
f01019fc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101a00:	57                   	push   %edi
f0101a01:	ff 75 e0             	pushl  -0x20(%ebp)
f0101a04:	50                   	push   %eax
f0101a05:	51                   	push   %ecx
f0101a06:	52                   	push   %edx
f0101a07:	89 da                	mov    %ebx,%edx
f0101a09:	89 f0                	mov    %esi,%eax
f0101a0b:	e8 f1 fa ff ff       	call   f0101501 <printnum>
			break;
f0101a10:	83 c4 20             	add    $0x20,%esp
f0101a13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a16:	e9 f5 fb ff ff       	jmp    f0101610 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101a1b:	83 ec 08             	sub    $0x8,%esp
f0101a1e:	53                   	push   %ebx
f0101a1f:	52                   	push   %edx
f0101a20:	ff d6                	call   *%esi
			break;
f0101a22:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101a28:	e9 e3 fb ff ff       	jmp    f0101610 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101a2d:	83 ec 08             	sub    $0x8,%esp
f0101a30:	53                   	push   %ebx
f0101a31:	6a 25                	push   $0x25
f0101a33:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101a35:	83 c4 10             	add    $0x10,%esp
f0101a38:	eb 03                	jmp    f0101a3d <vprintfmt+0x453>
f0101a3a:	83 ef 01             	sub    $0x1,%edi
f0101a3d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101a41:	75 f7                	jne    f0101a3a <vprintfmt+0x450>
f0101a43:	e9 c8 fb ff ff       	jmp    f0101610 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101a48:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101a4b:	5b                   	pop    %ebx
f0101a4c:	5e                   	pop    %esi
f0101a4d:	5f                   	pop    %edi
f0101a4e:	5d                   	pop    %ebp
f0101a4f:	c3                   	ret    

f0101a50 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101a50:	55                   	push   %ebp
f0101a51:	89 e5                	mov    %esp,%ebp
f0101a53:	83 ec 18             	sub    $0x18,%esp
f0101a56:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a59:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101a5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101a5f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101a63:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101a66:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101a6d:	85 c0                	test   %eax,%eax
f0101a6f:	74 26                	je     f0101a97 <vsnprintf+0x47>
f0101a71:	85 d2                	test   %edx,%edx
f0101a73:	7e 22                	jle    f0101a97 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101a75:	ff 75 14             	pushl  0x14(%ebp)
f0101a78:	ff 75 10             	pushl  0x10(%ebp)
f0101a7b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101a7e:	50                   	push   %eax
f0101a7f:	68 b0 15 10 f0       	push   $0xf01015b0
f0101a84:	e8 61 fb ff ff       	call   f01015ea <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101a89:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101a8c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a92:	83 c4 10             	add    $0x10,%esp
f0101a95:	eb 05                	jmp    f0101a9c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101a97:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101a9c:	c9                   	leave  
f0101a9d:	c3                   	ret    

f0101a9e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101a9e:	55                   	push   %ebp
f0101a9f:	89 e5                	mov    %esp,%ebp
f0101aa1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101aa4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101aa7:	50                   	push   %eax
f0101aa8:	ff 75 10             	pushl  0x10(%ebp)
f0101aab:	ff 75 0c             	pushl  0xc(%ebp)
f0101aae:	ff 75 08             	pushl  0x8(%ebp)
f0101ab1:	e8 9a ff ff ff       	call   f0101a50 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101ab6:	c9                   	leave  
f0101ab7:	c3                   	ret    

f0101ab8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101ab8:	55                   	push   %ebp
f0101ab9:	89 e5                	mov    %esp,%ebp
f0101abb:	57                   	push   %edi
f0101abc:	56                   	push   %esi
f0101abd:	53                   	push   %ebx
f0101abe:	83 ec 0c             	sub    $0xc,%esp
f0101ac1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101ac4:	85 c0                	test   %eax,%eax
f0101ac6:	74 11                	je     f0101ad9 <readline+0x21>
		cprintf("%s", prompt);
f0101ac8:	83 ec 08             	sub    $0x8,%esp
f0101acb:	50                   	push   %eax
f0101acc:	68 b8 26 10 f0       	push   $0xf01026b8
f0101ad1:	e8 50 f7 ff ff       	call   f0101226 <cprintf>
f0101ad6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101ad9:	83 ec 0c             	sub    $0xc,%esp
f0101adc:	6a 00                	push   $0x0
f0101ade:	e8 3e eb ff ff       	call   f0100621 <iscons>
f0101ae3:	89 c7                	mov    %eax,%edi
f0101ae5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101ae8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101aed:	e8 1e eb ff ff       	call   f0100610 <getchar>
f0101af2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	79 18                	jns    f0101b10 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101af8:	83 ec 08             	sub    $0x8,%esp
f0101afb:	50                   	push   %eax
f0101afc:	68 10 2c 10 f0       	push   $0xf0102c10
f0101b01:	e8 20 f7 ff ff       	call   f0101226 <cprintf>
			return NULL;
f0101b06:	83 c4 10             	add    $0x10,%esp
f0101b09:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b0e:	eb 79                	jmp    f0101b89 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101b10:	83 f8 08             	cmp    $0x8,%eax
f0101b13:	0f 94 c2             	sete   %dl
f0101b16:	83 f8 7f             	cmp    $0x7f,%eax
f0101b19:	0f 94 c0             	sete   %al
f0101b1c:	08 c2                	or     %al,%dl
f0101b1e:	74 1a                	je     f0101b3a <readline+0x82>
f0101b20:	85 f6                	test   %esi,%esi
f0101b22:	7e 16                	jle    f0101b3a <readline+0x82>
			if (echoing)
f0101b24:	85 ff                	test   %edi,%edi
f0101b26:	74 0d                	je     f0101b35 <readline+0x7d>
				cputchar('\b');
f0101b28:	83 ec 0c             	sub    $0xc,%esp
f0101b2b:	6a 08                	push   $0x8
f0101b2d:	e8 ce ea ff ff       	call   f0100600 <cputchar>
f0101b32:	83 c4 10             	add    $0x10,%esp
			i--;
f0101b35:	83 ee 01             	sub    $0x1,%esi
f0101b38:	eb b3                	jmp    f0101aed <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101b3a:	83 fb 1f             	cmp    $0x1f,%ebx
f0101b3d:	7e 23                	jle    f0101b62 <readline+0xaa>
f0101b3f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101b45:	7f 1b                	jg     f0101b62 <readline+0xaa>
			if (echoing)
f0101b47:	85 ff                	test   %edi,%edi
f0101b49:	74 0c                	je     f0101b57 <readline+0x9f>
				cputchar(c);
f0101b4b:	83 ec 0c             	sub    $0xc,%esp
f0101b4e:	53                   	push   %ebx
f0101b4f:	e8 ac ea ff ff       	call   f0100600 <cputchar>
f0101b54:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101b57:	88 9e 40 45 11 f0    	mov    %bl,-0xfeebac0(%esi)
f0101b5d:	8d 76 01             	lea    0x1(%esi),%esi
f0101b60:	eb 8b                	jmp    f0101aed <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101b62:	83 fb 0a             	cmp    $0xa,%ebx
f0101b65:	74 05                	je     f0101b6c <readline+0xb4>
f0101b67:	83 fb 0d             	cmp    $0xd,%ebx
f0101b6a:	75 81                	jne    f0101aed <readline+0x35>
			if (echoing)
f0101b6c:	85 ff                	test   %edi,%edi
f0101b6e:	74 0d                	je     f0101b7d <readline+0xc5>
				cputchar('\n');
f0101b70:	83 ec 0c             	sub    $0xc,%esp
f0101b73:	6a 0a                	push   $0xa
f0101b75:	e8 86 ea ff ff       	call   f0100600 <cputchar>
f0101b7a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101b7d:	c6 86 40 45 11 f0 00 	movb   $0x0,-0xfeebac0(%esi)
			return buf;
f0101b84:	b8 40 45 11 f0       	mov    $0xf0114540,%eax
		}
	}
}
f0101b89:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b8c:	5b                   	pop    %ebx
f0101b8d:	5e                   	pop    %esi
f0101b8e:	5f                   	pop    %edi
f0101b8f:	5d                   	pop    %ebp
f0101b90:	c3                   	ret    

f0101b91 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101b91:	55                   	push   %ebp
f0101b92:	89 e5                	mov    %esp,%ebp
f0101b94:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101b97:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b9c:	eb 03                	jmp    f0101ba1 <strlen+0x10>
		n++;
f0101b9e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101ba1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101ba5:	75 f7                	jne    f0101b9e <strlen+0xd>
		n++;
	return n;
}
f0101ba7:	5d                   	pop    %ebp
f0101ba8:	c3                   	ret    

f0101ba9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101ba9:	55                   	push   %ebp
f0101baa:	89 e5                	mov    %esp,%ebp
f0101bac:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101baf:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101bb2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bb7:	eb 03                	jmp    f0101bbc <strnlen+0x13>
		n++;
f0101bb9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101bbc:	39 c2                	cmp    %eax,%edx
f0101bbe:	74 08                	je     f0101bc8 <strnlen+0x1f>
f0101bc0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101bc4:	75 f3                	jne    f0101bb9 <strnlen+0x10>
f0101bc6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101bc8:	5d                   	pop    %ebp
f0101bc9:	c3                   	ret    

f0101bca <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101bca:	55                   	push   %ebp
f0101bcb:	89 e5                	mov    %esp,%ebp
f0101bcd:	53                   	push   %ebx
f0101bce:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bd1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101bd4:	89 c2                	mov    %eax,%edx
f0101bd6:	83 c2 01             	add    $0x1,%edx
f0101bd9:	83 c1 01             	add    $0x1,%ecx
f0101bdc:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101be0:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101be3:	84 db                	test   %bl,%bl
f0101be5:	75 ef                	jne    f0101bd6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101be7:	5b                   	pop    %ebx
f0101be8:	5d                   	pop    %ebp
f0101be9:	c3                   	ret    

f0101bea <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101bea:	55                   	push   %ebp
f0101beb:	89 e5                	mov    %esp,%ebp
f0101bed:	53                   	push   %ebx
f0101bee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101bf1:	53                   	push   %ebx
f0101bf2:	e8 9a ff ff ff       	call   f0101b91 <strlen>
f0101bf7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101bfa:	ff 75 0c             	pushl  0xc(%ebp)
f0101bfd:	01 d8                	add    %ebx,%eax
f0101bff:	50                   	push   %eax
f0101c00:	e8 c5 ff ff ff       	call   f0101bca <strcpy>
	return dst;
}
f0101c05:	89 d8                	mov    %ebx,%eax
f0101c07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101c0a:	c9                   	leave  
f0101c0b:	c3                   	ret    

f0101c0c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101c0c:	55                   	push   %ebp
f0101c0d:	89 e5                	mov    %esp,%ebp
f0101c0f:	56                   	push   %esi
f0101c10:	53                   	push   %ebx
f0101c11:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c14:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101c17:	89 f3                	mov    %esi,%ebx
f0101c19:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101c1c:	89 f2                	mov    %esi,%edx
f0101c1e:	eb 0f                	jmp    f0101c2f <strncpy+0x23>
		*dst++ = *src;
f0101c20:	83 c2 01             	add    $0x1,%edx
f0101c23:	0f b6 01             	movzbl (%ecx),%eax
f0101c26:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101c29:	80 39 01             	cmpb   $0x1,(%ecx)
f0101c2c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101c2f:	39 da                	cmp    %ebx,%edx
f0101c31:	75 ed                	jne    f0101c20 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101c33:	89 f0                	mov    %esi,%eax
f0101c35:	5b                   	pop    %ebx
f0101c36:	5e                   	pop    %esi
f0101c37:	5d                   	pop    %ebp
f0101c38:	c3                   	ret    

f0101c39 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101c39:	55                   	push   %ebp
f0101c3a:	89 e5                	mov    %esp,%ebp
f0101c3c:	56                   	push   %esi
f0101c3d:	53                   	push   %ebx
f0101c3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101c44:	8b 55 10             	mov    0x10(%ebp),%edx
f0101c47:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101c49:	85 d2                	test   %edx,%edx
f0101c4b:	74 21                	je     f0101c6e <strlcpy+0x35>
f0101c4d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101c51:	89 f2                	mov    %esi,%edx
f0101c53:	eb 09                	jmp    f0101c5e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101c55:	83 c2 01             	add    $0x1,%edx
f0101c58:	83 c1 01             	add    $0x1,%ecx
f0101c5b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101c5e:	39 c2                	cmp    %eax,%edx
f0101c60:	74 09                	je     f0101c6b <strlcpy+0x32>
f0101c62:	0f b6 19             	movzbl (%ecx),%ebx
f0101c65:	84 db                	test   %bl,%bl
f0101c67:	75 ec                	jne    f0101c55 <strlcpy+0x1c>
f0101c69:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101c6b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101c6e:	29 f0                	sub    %esi,%eax
}
f0101c70:	5b                   	pop    %ebx
f0101c71:	5e                   	pop    %esi
f0101c72:	5d                   	pop    %ebp
f0101c73:	c3                   	ret    

f0101c74 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101c74:	55                   	push   %ebp
f0101c75:	89 e5                	mov    %esp,%ebp
f0101c77:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101c7a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101c7d:	eb 06                	jmp    f0101c85 <strcmp+0x11>
		p++, q++;
f0101c7f:	83 c1 01             	add    $0x1,%ecx
f0101c82:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101c85:	0f b6 01             	movzbl (%ecx),%eax
f0101c88:	84 c0                	test   %al,%al
f0101c8a:	74 04                	je     f0101c90 <strcmp+0x1c>
f0101c8c:	3a 02                	cmp    (%edx),%al
f0101c8e:	74 ef                	je     f0101c7f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101c90:	0f b6 c0             	movzbl %al,%eax
f0101c93:	0f b6 12             	movzbl (%edx),%edx
f0101c96:	29 d0                	sub    %edx,%eax
}
f0101c98:	5d                   	pop    %ebp
f0101c99:	c3                   	ret    

f0101c9a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101c9a:	55                   	push   %ebp
f0101c9b:	89 e5                	mov    %esp,%ebp
f0101c9d:	53                   	push   %ebx
f0101c9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ca1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101ca4:	89 c3                	mov    %eax,%ebx
f0101ca6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101ca9:	eb 06                	jmp    f0101cb1 <strncmp+0x17>
		n--, p++, q++;
f0101cab:	83 c0 01             	add    $0x1,%eax
f0101cae:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101cb1:	39 d8                	cmp    %ebx,%eax
f0101cb3:	74 15                	je     f0101cca <strncmp+0x30>
f0101cb5:	0f b6 08             	movzbl (%eax),%ecx
f0101cb8:	84 c9                	test   %cl,%cl
f0101cba:	74 04                	je     f0101cc0 <strncmp+0x26>
f0101cbc:	3a 0a                	cmp    (%edx),%cl
f0101cbe:	74 eb                	je     f0101cab <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101cc0:	0f b6 00             	movzbl (%eax),%eax
f0101cc3:	0f b6 12             	movzbl (%edx),%edx
f0101cc6:	29 d0                	sub    %edx,%eax
f0101cc8:	eb 05                	jmp    f0101ccf <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101cca:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101ccf:	5b                   	pop    %ebx
f0101cd0:	5d                   	pop    %ebp
f0101cd1:	c3                   	ret    

f0101cd2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101cd2:	55                   	push   %ebp
f0101cd3:	89 e5                	mov    %esp,%ebp
f0101cd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cd8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101cdc:	eb 07                	jmp    f0101ce5 <strchr+0x13>
		if (*s == c)
f0101cde:	38 ca                	cmp    %cl,%dl
f0101ce0:	74 0f                	je     f0101cf1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101ce2:	83 c0 01             	add    $0x1,%eax
f0101ce5:	0f b6 10             	movzbl (%eax),%edx
f0101ce8:	84 d2                	test   %dl,%dl
f0101cea:	75 f2                	jne    f0101cde <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101cec:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101cf1:	5d                   	pop    %ebp
f0101cf2:	c3                   	ret    

f0101cf3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101cf3:	55                   	push   %ebp
f0101cf4:	89 e5                	mov    %esp,%ebp
f0101cf6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cf9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101cfd:	eb 03                	jmp    f0101d02 <strfind+0xf>
f0101cff:	83 c0 01             	add    $0x1,%eax
f0101d02:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101d05:	38 ca                	cmp    %cl,%dl
f0101d07:	74 04                	je     f0101d0d <strfind+0x1a>
f0101d09:	84 d2                	test   %dl,%dl
f0101d0b:	75 f2                	jne    f0101cff <strfind+0xc>
			break;
	return (char *) s;
}
f0101d0d:	5d                   	pop    %ebp
f0101d0e:	c3                   	ret    

f0101d0f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101d0f:	55                   	push   %ebp
f0101d10:	89 e5                	mov    %esp,%ebp
f0101d12:	57                   	push   %edi
f0101d13:	56                   	push   %esi
f0101d14:	53                   	push   %ebx
f0101d15:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101d18:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101d1b:	85 c9                	test   %ecx,%ecx
f0101d1d:	74 36                	je     f0101d55 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101d1f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101d25:	75 28                	jne    f0101d4f <memset+0x40>
f0101d27:	f6 c1 03             	test   $0x3,%cl
f0101d2a:	75 23                	jne    f0101d4f <memset+0x40>
		c &= 0xFF;
f0101d2c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101d30:	89 d3                	mov    %edx,%ebx
f0101d32:	c1 e3 08             	shl    $0x8,%ebx
f0101d35:	89 d6                	mov    %edx,%esi
f0101d37:	c1 e6 18             	shl    $0x18,%esi
f0101d3a:	89 d0                	mov    %edx,%eax
f0101d3c:	c1 e0 10             	shl    $0x10,%eax
f0101d3f:	09 f0                	or     %esi,%eax
f0101d41:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101d43:	89 d8                	mov    %ebx,%eax
f0101d45:	09 d0                	or     %edx,%eax
f0101d47:	c1 e9 02             	shr    $0x2,%ecx
f0101d4a:	fc                   	cld    
f0101d4b:	f3 ab                	rep stos %eax,%es:(%edi)
f0101d4d:	eb 06                	jmp    f0101d55 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101d4f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101d52:	fc                   	cld    
f0101d53:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101d55:	89 f8                	mov    %edi,%eax
f0101d57:	5b                   	pop    %ebx
f0101d58:	5e                   	pop    %esi
f0101d59:	5f                   	pop    %edi
f0101d5a:	5d                   	pop    %ebp
f0101d5b:	c3                   	ret    

f0101d5c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101d5c:	55                   	push   %ebp
f0101d5d:	89 e5                	mov    %esp,%ebp
f0101d5f:	57                   	push   %edi
f0101d60:	56                   	push   %esi
f0101d61:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d64:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101d67:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101d6a:	39 c6                	cmp    %eax,%esi
f0101d6c:	73 35                	jae    f0101da3 <memmove+0x47>
f0101d6e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101d71:	39 d0                	cmp    %edx,%eax
f0101d73:	73 2e                	jae    f0101da3 <memmove+0x47>
		s += n;
		d += n;
f0101d75:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101d78:	89 d6                	mov    %edx,%esi
f0101d7a:	09 fe                	or     %edi,%esi
f0101d7c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101d82:	75 13                	jne    f0101d97 <memmove+0x3b>
f0101d84:	f6 c1 03             	test   $0x3,%cl
f0101d87:	75 0e                	jne    f0101d97 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101d89:	83 ef 04             	sub    $0x4,%edi
f0101d8c:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101d8f:	c1 e9 02             	shr    $0x2,%ecx
f0101d92:	fd                   	std    
f0101d93:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101d95:	eb 09                	jmp    f0101da0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101d97:	83 ef 01             	sub    $0x1,%edi
f0101d9a:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101d9d:	fd                   	std    
f0101d9e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101da0:	fc                   	cld    
f0101da1:	eb 1d                	jmp    f0101dc0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101da3:	89 f2                	mov    %esi,%edx
f0101da5:	09 c2                	or     %eax,%edx
f0101da7:	f6 c2 03             	test   $0x3,%dl
f0101daa:	75 0f                	jne    f0101dbb <memmove+0x5f>
f0101dac:	f6 c1 03             	test   $0x3,%cl
f0101daf:	75 0a                	jne    f0101dbb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101db1:	c1 e9 02             	shr    $0x2,%ecx
f0101db4:	89 c7                	mov    %eax,%edi
f0101db6:	fc                   	cld    
f0101db7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101db9:	eb 05                	jmp    f0101dc0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101dbb:	89 c7                	mov    %eax,%edi
f0101dbd:	fc                   	cld    
f0101dbe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101dc0:	5e                   	pop    %esi
f0101dc1:	5f                   	pop    %edi
f0101dc2:	5d                   	pop    %ebp
f0101dc3:	c3                   	ret    

f0101dc4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101dc4:	55                   	push   %ebp
f0101dc5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101dc7:	ff 75 10             	pushl  0x10(%ebp)
f0101dca:	ff 75 0c             	pushl  0xc(%ebp)
f0101dcd:	ff 75 08             	pushl  0x8(%ebp)
f0101dd0:	e8 87 ff ff ff       	call   f0101d5c <memmove>
}
f0101dd5:	c9                   	leave  
f0101dd6:	c3                   	ret    

f0101dd7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101dd7:	55                   	push   %ebp
f0101dd8:	89 e5                	mov    %esp,%ebp
f0101dda:	56                   	push   %esi
f0101ddb:	53                   	push   %ebx
f0101ddc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ddf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101de2:	89 c6                	mov    %eax,%esi
f0101de4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101de7:	eb 1a                	jmp    f0101e03 <memcmp+0x2c>
		if (*s1 != *s2)
f0101de9:	0f b6 08             	movzbl (%eax),%ecx
f0101dec:	0f b6 1a             	movzbl (%edx),%ebx
f0101def:	38 d9                	cmp    %bl,%cl
f0101df1:	74 0a                	je     f0101dfd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101df3:	0f b6 c1             	movzbl %cl,%eax
f0101df6:	0f b6 db             	movzbl %bl,%ebx
f0101df9:	29 d8                	sub    %ebx,%eax
f0101dfb:	eb 0f                	jmp    f0101e0c <memcmp+0x35>
		s1++, s2++;
f0101dfd:	83 c0 01             	add    $0x1,%eax
f0101e00:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101e03:	39 f0                	cmp    %esi,%eax
f0101e05:	75 e2                	jne    f0101de9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101e07:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101e0c:	5b                   	pop    %ebx
f0101e0d:	5e                   	pop    %esi
f0101e0e:	5d                   	pop    %ebp
f0101e0f:	c3                   	ret    

f0101e10 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101e10:	55                   	push   %ebp
f0101e11:	89 e5                	mov    %esp,%ebp
f0101e13:	53                   	push   %ebx
f0101e14:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101e17:	89 c1                	mov    %eax,%ecx
f0101e19:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101e1c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101e20:	eb 0a                	jmp    f0101e2c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101e22:	0f b6 10             	movzbl (%eax),%edx
f0101e25:	39 da                	cmp    %ebx,%edx
f0101e27:	74 07                	je     f0101e30 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101e29:	83 c0 01             	add    $0x1,%eax
f0101e2c:	39 c8                	cmp    %ecx,%eax
f0101e2e:	72 f2                	jb     f0101e22 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101e30:	5b                   	pop    %ebx
f0101e31:	5d                   	pop    %ebp
f0101e32:	c3                   	ret    

f0101e33 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101e33:	55                   	push   %ebp
f0101e34:	89 e5                	mov    %esp,%ebp
f0101e36:	57                   	push   %edi
f0101e37:	56                   	push   %esi
f0101e38:	53                   	push   %ebx
f0101e39:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e3c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101e3f:	eb 03                	jmp    f0101e44 <strtol+0x11>
		s++;
f0101e41:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101e44:	0f b6 01             	movzbl (%ecx),%eax
f0101e47:	3c 20                	cmp    $0x20,%al
f0101e49:	74 f6                	je     f0101e41 <strtol+0xe>
f0101e4b:	3c 09                	cmp    $0x9,%al
f0101e4d:	74 f2                	je     f0101e41 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101e4f:	3c 2b                	cmp    $0x2b,%al
f0101e51:	75 0a                	jne    f0101e5d <strtol+0x2a>
		s++;
f0101e53:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101e56:	bf 00 00 00 00       	mov    $0x0,%edi
f0101e5b:	eb 11                	jmp    f0101e6e <strtol+0x3b>
f0101e5d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101e62:	3c 2d                	cmp    $0x2d,%al
f0101e64:	75 08                	jne    f0101e6e <strtol+0x3b>
		s++, neg = 1;
f0101e66:	83 c1 01             	add    $0x1,%ecx
f0101e69:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101e6e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101e74:	75 15                	jne    f0101e8b <strtol+0x58>
f0101e76:	80 39 30             	cmpb   $0x30,(%ecx)
f0101e79:	75 10                	jne    f0101e8b <strtol+0x58>
f0101e7b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101e7f:	75 7c                	jne    f0101efd <strtol+0xca>
		s += 2, base = 16;
f0101e81:	83 c1 02             	add    $0x2,%ecx
f0101e84:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101e89:	eb 16                	jmp    f0101ea1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101e8b:	85 db                	test   %ebx,%ebx
f0101e8d:	75 12                	jne    f0101ea1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101e8f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101e94:	80 39 30             	cmpb   $0x30,(%ecx)
f0101e97:	75 08                	jne    f0101ea1 <strtol+0x6e>
		s++, base = 8;
f0101e99:	83 c1 01             	add    $0x1,%ecx
f0101e9c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101ea1:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ea6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101ea9:	0f b6 11             	movzbl (%ecx),%edx
f0101eac:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101eaf:	89 f3                	mov    %esi,%ebx
f0101eb1:	80 fb 09             	cmp    $0x9,%bl
f0101eb4:	77 08                	ja     f0101ebe <strtol+0x8b>
			dig = *s - '0';
f0101eb6:	0f be d2             	movsbl %dl,%edx
f0101eb9:	83 ea 30             	sub    $0x30,%edx
f0101ebc:	eb 22                	jmp    f0101ee0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101ebe:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101ec1:	89 f3                	mov    %esi,%ebx
f0101ec3:	80 fb 19             	cmp    $0x19,%bl
f0101ec6:	77 08                	ja     f0101ed0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101ec8:	0f be d2             	movsbl %dl,%edx
f0101ecb:	83 ea 57             	sub    $0x57,%edx
f0101ece:	eb 10                	jmp    f0101ee0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101ed0:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101ed3:	89 f3                	mov    %esi,%ebx
f0101ed5:	80 fb 19             	cmp    $0x19,%bl
f0101ed8:	77 16                	ja     f0101ef0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101eda:	0f be d2             	movsbl %dl,%edx
f0101edd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101ee0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101ee3:	7d 0b                	jge    f0101ef0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101ee5:	83 c1 01             	add    $0x1,%ecx
f0101ee8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101eec:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101eee:	eb b9                	jmp    f0101ea9 <strtol+0x76>

	if (endptr)
f0101ef0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101ef4:	74 0d                	je     f0101f03 <strtol+0xd0>
		*endptr = (char *) s;
f0101ef6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ef9:	89 0e                	mov    %ecx,(%esi)
f0101efb:	eb 06                	jmp    f0101f03 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101efd:	85 db                	test   %ebx,%ebx
f0101eff:	74 98                	je     f0101e99 <strtol+0x66>
f0101f01:	eb 9e                	jmp    f0101ea1 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101f03:	89 c2                	mov    %eax,%edx
f0101f05:	f7 da                	neg    %edx
f0101f07:	85 ff                	test   %edi,%edi
f0101f09:	0f 45 c2             	cmovne %edx,%eax
}
f0101f0c:	5b                   	pop    %ebx
f0101f0d:	5e                   	pop    %esi
f0101f0e:	5f                   	pop    %edi
f0101f0f:	5d                   	pop    %ebp
f0101f10:	c3                   	ret    
f0101f11:	66 90                	xchg   %ax,%ax
f0101f13:	66 90                	xchg   %ax,%ax
f0101f15:	66 90                	xchg   %ax,%ax
f0101f17:	66 90                	xchg   %ax,%ax
f0101f19:	66 90                	xchg   %ax,%ax
f0101f1b:	66 90                	xchg   %ax,%ax
f0101f1d:	66 90                	xchg   %ax,%ax
f0101f1f:	90                   	nop

f0101f20 <__udivdi3>:
f0101f20:	55                   	push   %ebp
f0101f21:	57                   	push   %edi
f0101f22:	56                   	push   %esi
f0101f23:	53                   	push   %ebx
f0101f24:	83 ec 1c             	sub    $0x1c,%esp
f0101f27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0101f2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0101f2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101f33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101f37:	85 f6                	test   %esi,%esi
f0101f39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101f3d:	89 ca                	mov    %ecx,%edx
f0101f3f:	89 f8                	mov    %edi,%eax
f0101f41:	75 3d                	jne    f0101f80 <__udivdi3+0x60>
f0101f43:	39 cf                	cmp    %ecx,%edi
f0101f45:	0f 87 c5 00 00 00    	ja     f0102010 <__udivdi3+0xf0>
f0101f4b:	85 ff                	test   %edi,%edi
f0101f4d:	89 fd                	mov    %edi,%ebp
f0101f4f:	75 0b                	jne    f0101f5c <__udivdi3+0x3c>
f0101f51:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f56:	31 d2                	xor    %edx,%edx
f0101f58:	f7 f7                	div    %edi
f0101f5a:	89 c5                	mov    %eax,%ebp
f0101f5c:	89 c8                	mov    %ecx,%eax
f0101f5e:	31 d2                	xor    %edx,%edx
f0101f60:	f7 f5                	div    %ebp
f0101f62:	89 c1                	mov    %eax,%ecx
f0101f64:	89 d8                	mov    %ebx,%eax
f0101f66:	89 cf                	mov    %ecx,%edi
f0101f68:	f7 f5                	div    %ebp
f0101f6a:	89 c3                	mov    %eax,%ebx
f0101f6c:	89 d8                	mov    %ebx,%eax
f0101f6e:	89 fa                	mov    %edi,%edx
f0101f70:	83 c4 1c             	add    $0x1c,%esp
f0101f73:	5b                   	pop    %ebx
f0101f74:	5e                   	pop    %esi
f0101f75:	5f                   	pop    %edi
f0101f76:	5d                   	pop    %ebp
f0101f77:	c3                   	ret    
f0101f78:	90                   	nop
f0101f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f80:	39 ce                	cmp    %ecx,%esi
f0101f82:	77 74                	ja     f0101ff8 <__udivdi3+0xd8>
f0101f84:	0f bd fe             	bsr    %esi,%edi
f0101f87:	83 f7 1f             	xor    $0x1f,%edi
f0101f8a:	0f 84 98 00 00 00    	je     f0102028 <__udivdi3+0x108>
f0101f90:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101f95:	89 f9                	mov    %edi,%ecx
f0101f97:	89 c5                	mov    %eax,%ebp
f0101f99:	29 fb                	sub    %edi,%ebx
f0101f9b:	d3 e6                	shl    %cl,%esi
f0101f9d:	89 d9                	mov    %ebx,%ecx
f0101f9f:	d3 ed                	shr    %cl,%ebp
f0101fa1:	89 f9                	mov    %edi,%ecx
f0101fa3:	d3 e0                	shl    %cl,%eax
f0101fa5:	09 ee                	or     %ebp,%esi
f0101fa7:	89 d9                	mov    %ebx,%ecx
f0101fa9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101fad:	89 d5                	mov    %edx,%ebp
f0101faf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101fb3:	d3 ed                	shr    %cl,%ebp
f0101fb5:	89 f9                	mov    %edi,%ecx
f0101fb7:	d3 e2                	shl    %cl,%edx
f0101fb9:	89 d9                	mov    %ebx,%ecx
f0101fbb:	d3 e8                	shr    %cl,%eax
f0101fbd:	09 c2                	or     %eax,%edx
f0101fbf:	89 d0                	mov    %edx,%eax
f0101fc1:	89 ea                	mov    %ebp,%edx
f0101fc3:	f7 f6                	div    %esi
f0101fc5:	89 d5                	mov    %edx,%ebp
f0101fc7:	89 c3                	mov    %eax,%ebx
f0101fc9:	f7 64 24 0c          	mull   0xc(%esp)
f0101fcd:	39 d5                	cmp    %edx,%ebp
f0101fcf:	72 10                	jb     f0101fe1 <__udivdi3+0xc1>
f0101fd1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101fd5:	89 f9                	mov    %edi,%ecx
f0101fd7:	d3 e6                	shl    %cl,%esi
f0101fd9:	39 c6                	cmp    %eax,%esi
f0101fdb:	73 07                	jae    f0101fe4 <__udivdi3+0xc4>
f0101fdd:	39 d5                	cmp    %edx,%ebp
f0101fdf:	75 03                	jne    f0101fe4 <__udivdi3+0xc4>
f0101fe1:	83 eb 01             	sub    $0x1,%ebx
f0101fe4:	31 ff                	xor    %edi,%edi
f0101fe6:	89 d8                	mov    %ebx,%eax
f0101fe8:	89 fa                	mov    %edi,%edx
f0101fea:	83 c4 1c             	add    $0x1c,%esp
f0101fed:	5b                   	pop    %ebx
f0101fee:	5e                   	pop    %esi
f0101fef:	5f                   	pop    %edi
f0101ff0:	5d                   	pop    %ebp
f0101ff1:	c3                   	ret    
f0101ff2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ff8:	31 ff                	xor    %edi,%edi
f0101ffa:	31 db                	xor    %ebx,%ebx
f0101ffc:	89 d8                	mov    %ebx,%eax
f0101ffe:	89 fa                	mov    %edi,%edx
f0102000:	83 c4 1c             	add    $0x1c,%esp
f0102003:	5b                   	pop    %ebx
f0102004:	5e                   	pop    %esi
f0102005:	5f                   	pop    %edi
f0102006:	5d                   	pop    %ebp
f0102007:	c3                   	ret    
f0102008:	90                   	nop
f0102009:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102010:	89 d8                	mov    %ebx,%eax
f0102012:	f7 f7                	div    %edi
f0102014:	31 ff                	xor    %edi,%edi
f0102016:	89 c3                	mov    %eax,%ebx
f0102018:	89 d8                	mov    %ebx,%eax
f010201a:	89 fa                	mov    %edi,%edx
f010201c:	83 c4 1c             	add    $0x1c,%esp
f010201f:	5b                   	pop    %ebx
f0102020:	5e                   	pop    %esi
f0102021:	5f                   	pop    %edi
f0102022:	5d                   	pop    %ebp
f0102023:	c3                   	ret    
f0102024:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102028:	39 ce                	cmp    %ecx,%esi
f010202a:	72 0c                	jb     f0102038 <__udivdi3+0x118>
f010202c:	31 db                	xor    %ebx,%ebx
f010202e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102032:	0f 87 34 ff ff ff    	ja     f0101f6c <__udivdi3+0x4c>
f0102038:	bb 01 00 00 00       	mov    $0x1,%ebx
f010203d:	e9 2a ff ff ff       	jmp    f0101f6c <__udivdi3+0x4c>
f0102042:	66 90                	xchg   %ax,%ax
f0102044:	66 90                	xchg   %ax,%ax
f0102046:	66 90                	xchg   %ax,%ax
f0102048:	66 90                	xchg   %ax,%ax
f010204a:	66 90                	xchg   %ax,%ax
f010204c:	66 90                	xchg   %ax,%ax
f010204e:	66 90                	xchg   %ax,%ax

f0102050 <__umoddi3>:
f0102050:	55                   	push   %ebp
f0102051:	57                   	push   %edi
f0102052:	56                   	push   %esi
f0102053:	53                   	push   %ebx
f0102054:	83 ec 1c             	sub    $0x1c,%esp
f0102057:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010205b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010205f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102063:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102067:	85 d2                	test   %edx,%edx
f0102069:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010206d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102071:	89 f3                	mov    %esi,%ebx
f0102073:	89 3c 24             	mov    %edi,(%esp)
f0102076:	89 74 24 04          	mov    %esi,0x4(%esp)
f010207a:	75 1c                	jne    f0102098 <__umoddi3+0x48>
f010207c:	39 f7                	cmp    %esi,%edi
f010207e:	76 50                	jbe    f01020d0 <__umoddi3+0x80>
f0102080:	89 c8                	mov    %ecx,%eax
f0102082:	89 f2                	mov    %esi,%edx
f0102084:	f7 f7                	div    %edi
f0102086:	89 d0                	mov    %edx,%eax
f0102088:	31 d2                	xor    %edx,%edx
f010208a:	83 c4 1c             	add    $0x1c,%esp
f010208d:	5b                   	pop    %ebx
f010208e:	5e                   	pop    %esi
f010208f:	5f                   	pop    %edi
f0102090:	5d                   	pop    %ebp
f0102091:	c3                   	ret    
f0102092:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102098:	39 f2                	cmp    %esi,%edx
f010209a:	89 d0                	mov    %edx,%eax
f010209c:	77 52                	ja     f01020f0 <__umoddi3+0xa0>
f010209e:	0f bd ea             	bsr    %edx,%ebp
f01020a1:	83 f5 1f             	xor    $0x1f,%ebp
f01020a4:	75 5a                	jne    f0102100 <__umoddi3+0xb0>
f01020a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01020aa:	0f 82 e0 00 00 00    	jb     f0102190 <__umoddi3+0x140>
f01020b0:	39 0c 24             	cmp    %ecx,(%esp)
f01020b3:	0f 86 d7 00 00 00    	jbe    f0102190 <__umoddi3+0x140>
f01020b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01020bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01020c1:	83 c4 1c             	add    $0x1c,%esp
f01020c4:	5b                   	pop    %ebx
f01020c5:	5e                   	pop    %esi
f01020c6:	5f                   	pop    %edi
f01020c7:	5d                   	pop    %ebp
f01020c8:	c3                   	ret    
f01020c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01020d0:	85 ff                	test   %edi,%edi
f01020d2:	89 fd                	mov    %edi,%ebp
f01020d4:	75 0b                	jne    f01020e1 <__umoddi3+0x91>
f01020d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01020db:	31 d2                	xor    %edx,%edx
f01020dd:	f7 f7                	div    %edi
f01020df:	89 c5                	mov    %eax,%ebp
f01020e1:	89 f0                	mov    %esi,%eax
f01020e3:	31 d2                	xor    %edx,%edx
f01020e5:	f7 f5                	div    %ebp
f01020e7:	89 c8                	mov    %ecx,%eax
f01020e9:	f7 f5                	div    %ebp
f01020eb:	89 d0                	mov    %edx,%eax
f01020ed:	eb 99                	jmp    f0102088 <__umoddi3+0x38>
f01020ef:	90                   	nop
f01020f0:	89 c8                	mov    %ecx,%eax
f01020f2:	89 f2                	mov    %esi,%edx
f01020f4:	83 c4 1c             	add    $0x1c,%esp
f01020f7:	5b                   	pop    %ebx
f01020f8:	5e                   	pop    %esi
f01020f9:	5f                   	pop    %edi
f01020fa:	5d                   	pop    %ebp
f01020fb:	c3                   	ret    
f01020fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102100:	8b 34 24             	mov    (%esp),%esi
f0102103:	bf 20 00 00 00       	mov    $0x20,%edi
f0102108:	89 e9                	mov    %ebp,%ecx
f010210a:	29 ef                	sub    %ebp,%edi
f010210c:	d3 e0                	shl    %cl,%eax
f010210e:	89 f9                	mov    %edi,%ecx
f0102110:	89 f2                	mov    %esi,%edx
f0102112:	d3 ea                	shr    %cl,%edx
f0102114:	89 e9                	mov    %ebp,%ecx
f0102116:	09 c2                	or     %eax,%edx
f0102118:	89 d8                	mov    %ebx,%eax
f010211a:	89 14 24             	mov    %edx,(%esp)
f010211d:	89 f2                	mov    %esi,%edx
f010211f:	d3 e2                	shl    %cl,%edx
f0102121:	89 f9                	mov    %edi,%ecx
f0102123:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102127:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010212b:	d3 e8                	shr    %cl,%eax
f010212d:	89 e9                	mov    %ebp,%ecx
f010212f:	89 c6                	mov    %eax,%esi
f0102131:	d3 e3                	shl    %cl,%ebx
f0102133:	89 f9                	mov    %edi,%ecx
f0102135:	89 d0                	mov    %edx,%eax
f0102137:	d3 e8                	shr    %cl,%eax
f0102139:	89 e9                	mov    %ebp,%ecx
f010213b:	09 d8                	or     %ebx,%eax
f010213d:	89 d3                	mov    %edx,%ebx
f010213f:	89 f2                	mov    %esi,%edx
f0102141:	f7 34 24             	divl   (%esp)
f0102144:	89 d6                	mov    %edx,%esi
f0102146:	d3 e3                	shl    %cl,%ebx
f0102148:	f7 64 24 04          	mull   0x4(%esp)
f010214c:	39 d6                	cmp    %edx,%esi
f010214e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102152:	89 d1                	mov    %edx,%ecx
f0102154:	89 c3                	mov    %eax,%ebx
f0102156:	72 08                	jb     f0102160 <__umoddi3+0x110>
f0102158:	75 11                	jne    f010216b <__umoddi3+0x11b>
f010215a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010215e:	73 0b                	jae    f010216b <__umoddi3+0x11b>
f0102160:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102164:	1b 14 24             	sbb    (%esp),%edx
f0102167:	89 d1                	mov    %edx,%ecx
f0102169:	89 c3                	mov    %eax,%ebx
f010216b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010216f:	29 da                	sub    %ebx,%edx
f0102171:	19 ce                	sbb    %ecx,%esi
f0102173:	89 f9                	mov    %edi,%ecx
f0102175:	89 f0                	mov    %esi,%eax
f0102177:	d3 e0                	shl    %cl,%eax
f0102179:	89 e9                	mov    %ebp,%ecx
f010217b:	d3 ea                	shr    %cl,%edx
f010217d:	89 e9                	mov    %ebp,%ecx
f010217f:	d3 ee                	shr    %cl,%esi
f0102181:	09 d0                	or     %edx,%eax
f0102183:	89 f2                	mov    %esi,%edx
f0102185:	83 c4 1c             	add    $0x1c,%esp
f0102188:	5b                   	pop    %ebx
f0102189:	5e                   	pop    %esi
f010218a:	5f                   	pop    %edi
f010218b:	5d                   	pop    %ebp
f010218c:	c3                   	ret    
f010218d:	8d 76 00             	lea    0x0(%esi),%esi
f0102190:	29 f9                	sub    %edi,%ecx
f0102192:	19 d6                	sbb    %edx,%esi
f0102194:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102198:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010219c:	e9 18 ff ff ff       	jmp    f01020b9 <__umoddi3+0x69>
