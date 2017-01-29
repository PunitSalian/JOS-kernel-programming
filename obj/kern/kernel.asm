
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>
#define ELFHDR		((struct Elf *) 0x10000)
// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n",x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 18 10 f0       	push   $0xf01018c0
f0100050:	e8 1f 09 00 00       	call   f0100974 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 1f 07 00 00       	call   f010079a <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n",x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 dc 18 10 f0       	push   $0xf01018dc
f0100087:	e8 e8 08 00 00       	call   f0100974 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 6c 13 00 00       	call   f010141d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 b2 04 00 00       	call   f0100568 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 18 10 f0       	push   $0xf01018f7
f01000c3:	e8 ac 08 00 00       	call   f0100974 <cprintf>
	cprintf("%d \n",ELFHDR->e_phnum);
f01000c8:	83 c4 08             	add    $0x8,%esp
f01000cb:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
f01000d2:	50                   	push   %eax
f01000d3:	68 12 19 10 f0       	push   $0xf0101912
f01000d8:	e8 97 08 00 00       	call   f0100974 <cprintf>
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000dd:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e4:	e8 57 ff ff ff       	call   f0100040 <test_backtrace>
f01000e9:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ec:	83 ec 0c             	sub    $0xc,%esp
f01000ef:	6a 00                	push   $0x0
f01000f1:	e8 11 07 00 00       	call   f0100807 <monitor>
f01000f6:	83 c4 10             	add    $0x10,%esp
f01000f9:	eb f1                	jmp    f01000ec <i386_init+0x58>

f01000fb <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000fb:	55                   	push   %ebp
f01000fc:	89 e5                	mov    %esp,%ebp
f01000fe:	56                   	push   %esi
f01000ff:	53                   	push   %ebx
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 37                	jne    f0100143 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	83 ec 04             	sub    $0x4,%esp
f010011a:	ff 75 0c             	pushl  0xc(%ebp)
f010011d:	ff 75 08             	pushl  0x8(%ebp)
f0100120:	68 17 19 10 f0       	push   $0xf0101917
f0100125:	e8 4a 08 00 00       	call   f0100974 <cprintf>
	vcprintf(fmt, ap);
f010012a:	83 c4 08             	add    $0x8,%esp
f010012d:	53                   	push   %ebx
f010012e:	56                   	push   %esi
f010012f:	e8 1a 08 00 00       	call   f010094e <vcprintf>
	cprintf("\n");
f0100134:	c7 04 24 15 19 10 f0 	movl   $0xf0101915,(%esp)
f010013b:	e8 34 08 00 00       	call   f0100974 <cprintf>
	va_end(ap);
f0100140:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100143:	83 ec 0c             	sub    $0xc,%esp
f0100146:	6a 00                	push   $0x0
f0100148:	e8 ba 06 00 00       	call   f0100807 <monitor>
f010014d:	83 c4 10             	add    $0x10,%esp
f0100150:	eb f1                	jmp    f0100143 <_panic+0x48>

f0100152 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100152:	55                   	push   %ebp
f0100153:	89 e5                	mov    %esp,%ebp
f0100155:	53                   	push   %ebx
f0100156:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100159:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010015c:	ff 75 0c             	pushl  0xc(%ebp)
f010015f:	ff 75 08             	pushl  0x8(%ebp)
f0100162:	68 2f 19 10 f0       	push   $0xf010192f
f0100167:	e8 08 08 00 00       	call   f0100974 <cprintf>
	vcprintf(fmt, ap);
f010016c:	83 c4 08             	add    $0x8,%esp
f010016f:	53                   	push   %ebx
f0100170:	ff 75 10             	pushl  0x10(%ebp)
f0100173:	e8 d6 07 00 00       	call   f010094e <vcprintf>
	cprintf("\n");
f0100178:	c7 04 24 15 19 10 f0 	movl   $0xf0101915,(%esp)
f010017f:	e8 f0 07 00 00       	call   f0100974 <cprintf>
	va_end(ap);
}
f0100184:	83 c4 10             	add    $0x10,%esp
f0100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010018a:	c9                   	leave  
f010018b:	c3                   	ret    

f010018c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010018c:	55                   	push   %ebp
f010018d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010018f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100194:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100195:	a8 01                	test   $0x1,%al
f0100197:	74 0b                	je     f01001a4 <serial_proc_data+0x18>
f0100199:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010019e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010019f:	0f b6 c0             	movzbl %al,%eax
f01001a2:	eb 05                	jmp    f01001a9 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001a9:	5d                   	pop    %ebp
f01001aa:	c3                   	ret    

f01001ab <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ab:	55                   	push   %ebp
f01001ac:	89 e5                	mov    %esp,%ebp
f01001ae:	53                   	push   %ebx
f01001af:	83 ec 04             	sub    $0x4,%esp
f01001b2:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001b4:	eb 2b                	jmp    f01001e1 <cons_intr+0x36>
		if (c == 0)
f01001b6:	85 c0                	test   %eax,%eax
f01001b8:	74 27                	je     f01001e1 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001ba:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001c0:	8d 51 01             	lea    0x1(%ecx),%edx
f01001c3:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001c9:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001d5:	75 0a                	jne    f01001e1 <cons_intr+0x36>
			cons.wpos = 0;
f01001d7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001de:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001e1:	ff d3                	call   *%ebx
f01001e3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001e6:	75 ce                	jne    f01001b6 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001e8:	83 c4 04             	add    $0x4,%esp
f01001eb:	5b                   	pop    %ebx
f01001ec:	5d                   	pop    %ebp
f01001ed:	c3                   	ret    

f01001ee <kbd_proc_data>:
f01001ee:	ba 64 00 00 00       	mov    $0x64,%edx
f01001f3:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001f4:	a8 01                	test   $0x1,%al
f01001f6:	0f 84 f8 00 00 00    	je     f01002f4 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001fc:	a8 20                	test   $0x20,%al
f01001fe:	0f 85 f6 00 00 00    	jne    f01002fa <kbd_proc_data+0x10c>
f0100204:	ba 60 00 00 00       	mov    $0x60,%edx
f0100209:	ec                   	in     (%dx),%al
f010020a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010020c:	3c e0                	cmp    $0xe0,%al
f010020e:	75 0d                	jne    f010021d <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f0100210:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100217:	b8 00 00 00 00       	mov    $0x0,%eax
f010021c:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010021d:	55                   	push   %ebp
f010021e:	89 e5                	mov    %esp,%ebp
f0100220:	53                   	push   %ebx
f0100221:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100224:	84 c0                	test   %al,%al
f0100226:	79 36                	jns    f010025e <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100228:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010022e:	89 cb                	mov    %ecx,%ebx
f0100230:	83 e3 40             	and    $0x40,%ebx
f0100233:	83 e0 7f             	and    $0x7f,%eax
f0100236:	85 db                	test   %ebx,%ebx
f0100238:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010023b:	0f b6 d2             	movzbl %dl,%edx
f010023e:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100245:	83 c8 40             	or     $0x40,%eax
f0100248:	0f b6 c0             	movzbl %al,%eax
f010024b:	f7 d0                	not    %eax
f010024d:	21 c8                	and    %ecx,%eax
f010024f:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100254:	b8 00 00 00 00       	mov    $0x0,%eax
f0100259:	e9 a4 00 00 00       	jmp    f0100302 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f010025e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100264:	f6 c1 40             	test   $0x40,%cl
f0100267:	74 0e                	je     f0100277 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100269:	83 c8 80             	or     $0xffffff80,%eax
f010026c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010026e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100271:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100277:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010027a:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100281:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100287:	0f b6 8a a0 19 10 f0 	movzbl -0xfefe660(%edx),%ecx
f010028e:	31 c8                	xor    %ecx,%eax
f0100290:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100295:	89 c1                	mov    %eax,%ecx
f0100297:	83 e1 03             	and    $0x3,%ecx
f010029a:	8b 0c 8d 80 19 10 f0 	mov    -0xfefe680(,%ecx,4),%ecx
f01002a1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002a5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002a8:	a8 08                	test   $0x8,%al
f01002aa:	74 1b                	je     f01002c7 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f01002ac:	89 da                	mov    %ebx,%edx
f01002ae:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b1:	83 f9 19             	cmp    $0x19,%ecx
f01002b4:	77 05                	ja     f01002bb <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002b6:	83 eb 20             	sub    $0x20,%ebx
f01002b9:	eb 0c                	jmp    f01002c7 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002bb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002be:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c1:	83 fa 19             	cmp    $0x19,%edx
f01002c4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002c7:	f7 d0                	not    %eax
f01002c9:	a8 06                	test   $0x6,%al
f01002cb:	75 33                	jne    f0100300 <kbd_proc_data+0x112>
f01002cd:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002d3:	75 2b                	jne    f0100300 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002d5:	83 ec 0c             	sub    $0xc,%esp
f01002d8:	68 49 19 10 f0       	push   $0xf0101949
f01002dd:	e8 92 06 00 00       	call   f0100974 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e2:	ba 92 00 00 00       	mov    $0x92,%edx
f01002e7:	b8 03 00 00 00       	mov    $0x3,%eax
f01002ec:	ee                   	out    %al,(%dx)
f01002ed:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f0:	89 d8                	mov    %ebx,%eax
f01002f2:	eb 0e                	jmp    f0100302 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002f9:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ff:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100300:	89 d8                	mov    %ebx,%eax
}
f0100302:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100305:	c9                   	leave  
f0100306:	c3                   	ret    

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100312:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100317:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100321:	eb 09                	jmp    f010032c <cons_putc+0x25>
f0100323:	89 ca                	mov    %ecx,%edx
f0100325:	ec                   	in     (%dx),%al
f0100326:	ec                   	in     (%dx),%al
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100329:	83 c3 01             	add    $0x1,%ebx
f010032c:	89 f2                	mov    %esi,%edx
f010032e:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010032f:	a8 20                	test   $0x20,%al
f0100331:	75 08                	jne    f010033b <cons_putc+0x34>
f0100333:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100339:	7e e8                	jle    f0100323 <cons_putc+0x1c>
f010033b:	89 f8                	mov    %edi,%eax
f010033d:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100340:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100345:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100346:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034b:	be 79 03 00 00       	mov    $0x379,%esi
f0100350:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100355:	eb 09                	jmp    f0100360 <cons_putc+0x59>
f0100357:	89 ca                	mov    %ecx,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	ec                   	in     (%dx),%al
f010035d:	83 c3 01             	add    $0x1,%ebx
f0100360:	89 f2                	mov    %esi,%edx
f0100362:	ec                   	in     (%dx),%al
f0100363:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100369:	7f 04                	jg     f010036f <cons_putc+0x68>
f010036b:	84 c0                	test   %al,%al
f010036d:	79 e8                	jns    f0100357 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100374:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100378:	ee                   	out    %al,(%dx)
f0100379:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010037e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100383:	ee                   	out    %al,(%dx)
f0100384:	b8 08 00 00 00       	mov    $0x8,%eax
f0100389:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038a:	89 fa                	mov    %edi,%edx
f010038c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	80 cc 07             	or     $0x7,%ah
f0100397:	85 d2                	test   %edx,%edx
f0100399:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039c:	89 f8                	mov    %edi,%eax
f010039e:	0f b6 c0             	movzbl %al,%eax
f01003a1:	83 f8 09             	cmp    $0x9,%eax
f01003a4:	74 74                	je     f010041a <cons_putc+0x113>
f01003a6:	83 f8 09             	cmp    $0x9,%eax
f01003a9:	7f 0a                	jg     f01003b5 <cons_putc+0xae>
f01003ab:	83 f8 08             	cmp    $0x8,%eax
f01003ae:	74 14                	je     f01003c4 <cons_putc+0xbd>
f01003b0:	e9 99 00 00 00       	jmp    f010044e <cons_putc+0x147>
f01003b5:	83 f8 0a             	cmp    $0xa,%eax
f01003b8:	74 3a                	je     f01003f4 <cons_putc+0xed>
f01003ba:	83 f8 0d             	cmp    $0xd,%eax
f01003bd:	74 3d                	je     f01003fc <cons_putc+0xf5>
f01003bf:	e9 8a 00 00 00       	jmp    f010044e <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003c4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003cb:	66 85 c0             	test   %ax,%ax
f01003ce:	0f 84 e6 00 00 00    	je     f01004ba <cons_putc+0x1b3>
			crt_pos--;
f01003d4:	83 e8 01             	sub    $0x1,%eax
f01003d7:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003dd:	0f b7 c0             	movzwl %ax,%eax
f01003e0:	66 81 e7 00 ff       	and    $0xff00,%di
f01003e5:	83 cf 20             	or     $0x20,%edi
f01003e8:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003ee:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003f2:	eb 78                	jmp    f010046c <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003f4:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003fb:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003fc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100403:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100409:	c1 e8 16             	shr    $0x16,%eax
f010040c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010040f:	c1 e0 04             	shl    $0x4,%eax
f0100412:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100418:	eb 52                	jmp    f010046c <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010041a:	b8 20 00 00 00       	mov    $0x20,%eax
f010041f:	e8 e3 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100424:	b8 20 00 00 00       	mov    $0x20,%eax
f0100429:	e8 d9 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010042e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100433:	e8 cf fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100438:	b8 20 00 00 00       	mov    $0x20,%eax
f010043d:	e8 c5 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100442:	b8 20 00 00 00       	mov    $0x20,%eax
f0100447:	e8 bb fe ff ff       	call   f0100307 <cons_putc>
f010044c:	eb 1e                	jmp    f010046c <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010044e:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100455:	8d 50 01             	lea    0x1(%eax),%edx
f0100458:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010045f:	0f b7 c0             	movzwl %ax,%eax
f0100462:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100468:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010046c:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100473:	cf 07 
f0100475:	76 43                	jbe    f01004ba <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100477:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010047c:	83 ec 04             	sub    $0x4,%esp
f010047f:	68 00 0f 00 00       	push   $0xf00
f0100484:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010048a:	52                   	push   %edx
f010048b:	50                   	push   %eax
f010048c:	e8 d9 0f 00 00       	call   f010146a <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100491:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100497:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010049d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004a3:	83 c4 10             	add    $0x10,%esp
f01004a6:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004ab:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ae:	39 d0                	cmp    %edx,%eax
f01004b0:	75 f4                	jne    f01004a6 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b2:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b9:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004ba:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004c5:	89 ca                	mov    %ecx,%edx
f01004c7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004c8:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004cf:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d2:	89 d8                	mov    %ebx,%eax
f01004d4:	66 c1 e8 08          	shr    $0x8,%ax
f01004d8:	89 f2                	mov    %esi,%edx
f01004da:	ee                   	out    %al,(%dx)
f01004db:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e0:	89 ca                	mov    %ecx,%edx
f01004e2:	ee                   	out    %al,(%dx)
f01004e3:	89 d8                	mov    %ebx,%eax
f01004e5:	89 f2                	mov    %esi,%edx
f01004e7:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004eb:	5b                   	pop    %ebx
f01004ec:	5e                   	pop    %esi
f01004ed:	5f                   	pop    %edi
f01004ee:	5d                   	pop    %ebp
f01004ef:	c3                   	ret    

f01004f0 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f0:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004f7:	74 11                	je     f010050a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f9:	55                   	push   %ebp
f01004fa:	89 e5                	mov    %esp,%ebp
f01004fc:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ff:	b8 8c 01 10 f0       	mov    $0xf010018c,%eax
f0100504:	e8 a2 fc ff ff       	call   f01001ab <cons_intr>
}
f0100509:	c9                   	leave  
f010050a:	f3 c3                	repz ret 

f010050c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050c:	55                   	push   %ebp
f010050d:	89 e5                	mov    %esp,%ebp
f010050f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100512:	b8 ee 01 10 f0       	mov    $0xf01001ee,%eax
f0100517:	e8 8f fc ff ff       	call   f01001ab <cons_intr>
}
f010051c:	c9                   	leave  
f010051d:	c3                   	ret    

f010051e <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010051e:	55                   	push   %ebp
f010051f:	89 e5                	mov    %esp,%ebp
f0100521:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100524:	e8 c7 ff ff ff       	call   f01004f0 <serial_intr>
	kbd_intr();
f0100529:	e8 de ff ff ff       	call   f010050c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010052e:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100533:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100539:	74 26                	je     f0100561 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010053b:	8d 50 01             	lea    0x1(%eax),%edx
f010053e:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100544:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010054b:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010054d:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100553:	75 11                	jne    f0100566 <cons_getc+0x48>
			cons.rpos = 0;
f0100555:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010055c:	00 00 00 
f010055f:	eb 05                	jmp    f0100566 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100561:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100566:	c9                   	leave  
f0100567:	c3                   	ret    

f0100568 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100568:	55                   	push   %ebp
f0100569:	89 e5                	mov    %esp,%ebp
f010056b:	57                   	push   %edi
f010056c:	56                   	push   %esi
f010056d:	53                   	push   %ebx
f010056e:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100571:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100578:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010057f:	5a a5 
	if (*cp != 0xA55A) {
f0100581:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100588:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058c:	74 11                	je     f010059f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058e:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100595:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100598:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010059d:	eb 16                	jmp    f01005b5 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010059f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a6:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005ad:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b0:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b5:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005bb:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c0:	89 fa                	mov    %edi,%edx
f01005c2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c3:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c6:	89 da                	mov    %ebx,%edx
f01005c8:	ec                   	in     (%dx),%al
f01005c9:	0f b6 c8             	movzbl %al,%ecx
f01005cc:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005cf:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d4:	89 fa                	mov    %edi,%edx
f01005d6:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d7:	89 da                	mov    %ebx,%edx
f01005d9:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005da:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005e0:	0f b6 c0             	movzbl %al,%eax
f01005e3:	09 c8                	or     %ecx,%eax
f01005e5:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005eb:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f5:	89 f2                	mov    %esi,%edx
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100608:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060d:	89 da                	mov    %ebx,%edx
f010060f:	ee                   	out    %al,(%dx)
f0100610:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100615:	b8 00 00 00 00       	mov    $0x0,%eax
f010061a:	ee                   	out    %al,(%dx)
f010061b:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100620:	b8 03 00 00 00       	mov    $0x3,%eax
f0100625:	ee                   	out    %al,(%dx)
f0100626:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010062b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100630:	ee                   	out    %al,(%dx)
f0100631:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100636:	b8 01 00 00 00       	mov    $0x1,%eax
f010063b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010063c:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100641:	ec                   	in     (%dx),%al
f0100642:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100644:	3c ff                	cmp    $0xff,%al
f0100646:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010064d:	89 f2                	mov    %esi,%edx
f010064f:	ec                   	in     (%dx),%al
f0100650:	89 da                	mov    %ebx,%edx
f0100652:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100653:	80 f9 ff             	cmp    $0xff,%cl
f0100656:	75 10                	jne    f0100668 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100658:	83 ec 0c             	sub    $0xc,%esp
f010065b:	68 55 19 10 f0       	push   $0xf0101955
f0100660:	e8 0f 03 00 00       	call   f0100974 <cprintf>
f0100665:	83 c4 10             	add    $0x10,%esp
}
f0100668:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010066b:	5b                   	pop    %ebx
f010066c:	5e                   	pop    %esi
f010066d:	5f                   	pop    %edi
f010066e:	5d                   	pop    %ebp
f010066f:	c3                   	ret    

f0100670 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100670:	55                   	push   %ebp
f0100671:	89 e5                	mov    %esp,%ebp
f0100673:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100676:	8b 45 08             	mov    0x8(%ebp),%eax
f0100679:	e8 89 fc ff ff       	call   f0100307 <cons_putc>
}
f010067e:	c9                   	leave  
f010067f:	c3                   	ret    

f0100680 <getchar>:

int
getchar(void)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100686:	e8 93 fe ff ff       	call   f010051e <cons_getc>
f010068b:	85 c0                	test   %eax,%eax
f010068d:	74 f7                	je     f0100686 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <iscons>:

int
iscons(int fdnum)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100694:	b8 01 00 00 00       	mov    $0x1,%eax
f0100699:	5d                   	pop    %ebp
f010069a:	c3                   	ret    

f010069b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010069b:	55                   	push   %ebp
f010069c:	89 e5                	mov    %esp,%ebp
f010069e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a1:	68 a0 1b 10 f0       	push   $0xf0101ba0
f01006a6:	68 be 1b 10 f0       	push   $0xf0101bbe
f01006ab:	68 c3 1b 10 f0       	push   $0xf0101bc3
f01006b0:	e8 bf 02 00 00       	call   f0100974 <cprintf>
f01006b5:	83 c4 0c             	add    $0xc,%esp
f01006b8:	68 44 1c 10 f0       	push   $0xf0101c44
f01006bd:	68 cc 1b 10 f0       	push   $0xf0101bcc
f01006c2:	68 c3 1b 10 f0       	push   $0xf0101bc3
f01006c7:	e8 a8 02 00 00       	call   f0100974 <cprintf>
f01006cc:	83 c4 0c             	add    $0xc,%esp
f01006cf:	68 6c 1c 10 f0       	push   $0xf0101c6c
f01006d4:	68 d5 1b 10 f0       	push   $0xf0101bd5
f01006d9:	68 c3 1b 10 f0       	push   $0xf0101bc3
f01006de:	e8 91 02 00 00       	call   f0100974 <cprintf>
	return 0;
}
f01006e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    

f01006ea <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006ea:	55                   	push   %ebp
f01006eb:	89 e5                	mov    %esp,%ebp
f01006ed:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f0:	68 df 1b 10 f0       	push   $0xf0101bdf
f01006f5:	e8 7a 02 00 00       	call   f0100974 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006fa:	83 c4 08             	add    $0x8,%esp
f01006fd:	68 0c 00 10 00       	push   $0x10000c
f0100702:	68 94 1c 10 f0       	push   $0xf0101c94
f0100707:	e8 68 02 00 00       	call   f0100974 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010070c:	83 c4 0c             	add    $0xc,%esp
f010070f:	68 0c 00 10 00       	push   $0x10000c
f0100714:	68 0c 00 10 f0       	push   $0xf010000c
f0100719:	68 bc 1c 10 f0       	push   $0xf0101cbc
f010071e:	e8 51 02 00 00       	call   f0100974 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	83 c4 0c             	add    $0xc,%esp
f0100726:	68 a1 18 10 00       	push   $0x1018a1
f010072b:	68 a1 18 10 f0       	push   $0xf01018a1
f0100730:	68 e0 1c 10 f0       	push   $0xf0101ce0
f0100735:	e8 3a 02 00 00       	call   f0100974 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	68 00 23 11 00       	push   $0x112300
f0100742:	68 00 23 11 f0       	push   $0xf0112300
f0100747:	68 04 1d 10 f0       	push   $0xf0101d04
f010074c:	e8 23 02 00 00       	call   f0100974 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100751:	83 c4 0c             	add    $0xc,%esp
f0100754:	68 44 29 11 00       	push   $0x112944
f0100759:	68 44 29 11 f0       	push   $0xf0112944
f010075e:	68 28 1d 10 f0       	push   $0xf0101d28
f0100763:	e8 0c 02 00 00       	call   f0100974 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100768:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010076d:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100772:	83 c4 08             	add    $0x8,%esp
f0100775:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010077a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100780:	85 c0                	test   %eax,%eax
f0100782:	0f 48 c2             	cmovs  %edx,%eax
f0100785:	c1 f8 0a             	sar    $0xa,%eax
f0100788:	50                   	push   %eax
f0100789:	68 4c 1d 10 f0       	push   $0xf0101d4c
f010078e:	e8 e1 01 00 00       	call   f0100974 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100793:	b8 00 00 00 00       	mov    $0x0,%eax
f0100798:	c9                   	leave  
f0100799:	c3                   	ret    

f010079a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 20             	sub    $0x20,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a2:	89 eb                	mov    %ebp,%ebx
	uint32_t * x=(uint32_t *)read_ebp();
	
	while(x)
	{
	cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",x,x[1],x[2],x[3],x[4],x[5],x[6]);
	debuginfo_eip(x[1], &info);
f01007a4:	8d 75 e0             	lea    -0x20(%ebp),%esi
	uint32_t ebp, eip, arg;
	struct Eipdebuginfo info;
	
	uint32_t * x=(uint32_t *)read_ebp();
	
	while(x)
f01007a7:	eb 4e                	jmp    f01007f7 <mon_backtrace+0x5d>
	{
	cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",x,x[1],x[2],x[3],x[4],x[5],x[6]);
f01007a9:	ff 73 18             	pushl  0x18(%ebx)
f01007ac:	ff 73 14             	pushl  0x14(%ebx)
f01007af:	ff 73 10             	pushl  0x10(%ebx)
f01007b2:	ff 73 0c             	pushl  0xc(%ebx)
f01007b5:	ff 73 08             	pushl  0x8(%ebx)
f01007b8:	ff 73 04             	pushl  0x4(%ebx)
f01007bb:	53                   	push   %ebx
f01007bc:	68 78 1d 10 f0       	push   $0xf0101d78
f01007c1:	e8 ae 01 00 00       	call   f0100974 <cprintf>
	debuginfo_eip(x[1], &info);
f01007c6:	83 c4 18             	add    $0x18,%esp
f01007c9:	56                   	push   %esi
f01007ca:	ff 73 04             	pushl  0x4(%ebx)
f01007cd:	e8 ac 02 00 00       	call   f0100a7e <debuginfo_eip>
	cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (x[1] - info.eip_fn_addr));
f01007d2:	83 c4 08             	add    $0x8,%esp
f01007d5:	8b 43 04             	mov    0x4(%ebx),%eax
f01007d8:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007db:	50                   	push   %eax
f01007dc:	ff 75 e8             	pushl  -0x18(%ebp)
f01007df:	ff 75 ec             	pushl  -0x14(%ebp)
f01007e2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007e5:	ff 75 e0             	pushl  -0x20(%ebp)
f01007e8:	68 f8 1b 10 f0       	push   $0xf0101bf8
f01007ed:	e8 82 01 00 00       	call   f0100974 <cprintf>
	x=(uint32_t *)x[0];
f01007f2:	8b 1b                	mov    (%ebx),%ebx
f01007f4:	83 c4 20             	add    $0x20,%esp
	uint32_t ebp, eip, arg;
	struct Eipdebuginfo info;
	
	uint32_t * x=(uint32_t *)read_ebp();
	
	while(x)
f01007f7:	85 db                	test   %ebx,%ebx
f01007f9:	75 ae                	jne    f01007a9 <mon_backtrace+0xf>
	cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (x[1] - info.eip_fn_addr));
	x=(uint32_t *)x[0];
	}

	return 0;
}
f01007fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100800:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100803:	5b                   	pop    %ebx
f0100804:	5e                   	pop    %esi
f0100805:	5d                   	pop    %ebp
f0100806:	c3                   	ret    

f0100807 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100807:	55                   	push   %ebp
f0100808:	89 e5                	mov    %esp,%ebp
f010080a:	57                   	push   %edi
f010080b:	56                   	push   %esi
f010080c:	53                   	push   %ebx
f010080d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100810:	68 ac 1d 10 f0       	push   $0xf0101dac
f0100815:	e8 5a 01 00 00       	call   f0100974 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081a:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f0100821:	e8 4e 01 00 00       	call   f0100974 <cprintf>
f0100826:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100829:	83 ec 0c             	sub    $0xc,%esp
f010082c:	68 08 1c 10 f0       	push   $0xf0101c08
f0100831:	e8 90 09 00 00       	call   f01011c6 <readline>
f0100836:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	74 ea                	je     f0100829 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100846:	be 00 00 00 00       	mov    $0x0,%esi
f010084b:	eb 0a                	jmp    f0100857 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084d:	c6 03 00             	movb   $0x0,(%ebx)
f0100850:	89 f7                	mov    %esi,%edi
f0100852:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100855:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100857:	0f b6 03             	movzbl (%ebx),%eax
f010085a:	84 c0                	test   %al,%al
f010085c:	74 63                	je     f01008c1 <monitor+0xba>
f010085e:	83 ec 08             	sub    $0x8,%esp
f0100861:	0f be c0             	movsbl %al,%eax
f0100864:	50                   	push   %eax
f0100865:	68 0c 1c 10 f0       	push   $0xf0101c0c
f010086a:	e8 71 0b 00 00       	call   f01013e0 <strchr>
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	85 c0                	test   %eax,%eax
f0100874:	75 d7                	jne    f010084d <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100876:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100879:	74 46                	je     f01008c1 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010087b:	83 fe 0f             	cmp    $0xf,%esi
f010087e:	75 14                	jne    f0100894 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100880:	83 ec 08             	sub    $0x8,%esp
f0100883:	6a 10                	push   $0x10
f0100885:	68 11 1c 10 f0       	push   $0xf0101c11
f010088a:	e8 e5 00 00 00       	call   f0100974 <cprintf>
f010088f:	83 c4 10             	add    $0x10,%esp
f0100892:	eb 95                	jmp    f0100829 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100894:	8d 7e 01             	lea    0x1(%esi),%edi
f0100897:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010089b:	eb 03                	jmp    f01008a0 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010089d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a0:	0f b6 03             	movzbl (%ebx),%eax
f01008a3:	84 c0                	test   %al,%al
f01008a5:	74 ae                	je     f0100855 <monitor+0x4e>
f01008a7:	83 ec 08             	sub    $0x8,%esp
f01008aa:	0f be c0             	movsbl %al,%eax
f01008ad:	50                   	push   %eax
f01008ae:	68 0c 1c 10 f0       	push   $0xf0101c0c
f01008b3:	e8 28 0b 00 00       	call   f01013e0 <strchr>
f01008b8:	83 c4 10             	add    $0x10,%esp
f01008bb:	85 c0                	test   %eax,%eax
f01008bd:	74 de                	je     f010089d <monitor+0x96>
f01008bf:	eb 94                	jmp    f0100855 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008c1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c9:	85 f6                	test   %esi,%esi
f01008cb:	0f 84 58 ff ff ff    	je     f0100829 <monitor+0x22>
f01008d1:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d6:	83 ec 08             	sub    $0x8,%esp
f01008d9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008dc:	ff 34 85 00 1e 10 f0 	pushl  -0xfefe200(,%eax,4)
f01008e3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e6:	e8 97 0a 00 00       	call   f0101382 <strcmp>
f01008eb:	83 c4 10             	add    $0x10,%esp
f01008ee:	85 c0                	test   %eax,%eax
f01008f0:	75 21                	jne    f0100913 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008f2:	83 ec 04             	sub    $0x4,%esp
f01008f5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f8:	ff 75 08             	pushl  0x8(%ebp)
f01008fb:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008fe:	52                   	push   %edx
f01008ff:	56                   	push   %esi
f0100900:	ff 14 85 08 1e 10 f0 	call   *-0xfefe1f8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100907:	83 c4 10             	add    $0x10,%esp
f010090a:	85 c0                	test   %eax,%eax
f010090c:	78 25                	js     f0100933 <monitor+0x12c>
f010090e:	e9 16 ff ff ff       	jmp    f0100829 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100913:	83 c3 01             	add    $0x1,%ebx
f0100916:	83 fb 03             	cmp    $0x3,%ebx
f0100919:	75 bb                	jne    f01008d6 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010091b:	83 ec 08             	sub    $0x8,%esp
f010091e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100921:	68 2e 1c 10 f0       	push   $0xf0101c2e
f0100926:	e8 49 00 00 00       	call   f0100974 <cprintf>
f010092b:	83 c4 10             	add    $0x10,%esp
f010092e:	e9 f6 fe ff ff       	jmp    f0100829 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100933:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100936:	5b                   	pop    %ebx
f0100937:	5e                   	pop    %esi
f0100938:	5f                   	pop    %edi
f0100939:	5d                   	pop    %ebp
f010093a:	c3                   	ret    

f010093b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010093b:	55                   	push   %ebp
f010093c:	89 e5                	mov    %esp,%ebp
f010093e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100941:	ff 75 08             	pushl  0x8(%ebp)
f0100944:	e8 27 fd ff ff       	call   f0100670 <cputchar>
	*cnt++;
}
f0100949:	83 c4 10             	add    $0x10,%esp
f010094c:	c9                   	leave  
f010094d:	c3                   	ret    

f010094e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010094e:	55                   	push   %ebp
f010094f:	89 e5                	mov    %esp,%ebp
f0100951:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100954:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010095b:	ff 75 0c             	pushl  0xc(%ebp)
f010095e:	ff 75 08             	pushl  0x8(%ebp)
f0100961:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100964:	50                   	push   %eax
f0100965:	68 3b 09 10 f0       	push   $0xf010093b
f010096a:	e8 42 04 00 00       	call   f0100db1 <vprintfmt>
	return cnt;
}
f010096f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100972:	c9                   	leave  
f0100973:	c3                   	ret    

f0100974 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100974:	55                   	push   %ebp
f0100975:	89 e5                	mov    %esp,%ebp
f0100977:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010097a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010097d:	50                   	push   %eax
f010097e:	ff 75 08             	pushl  0x8(%ebp)
f0100981:	e8 c8 ff ff ff       	call   f010094e <vcprintf>
	va_end(ap);

	return cnt;
}
f0100986:	c9                   	leave  
f0100987:	c3                   	ret    

f0100988 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100988:	55                   	push   %ebp
f0100989:	89 e5                	mov    %esp,%ebp
f010098b:	57                   	push   %edi
f010098c:	56                   	push   %esi
f010098d:	53                   	push   %ebx
f010098e:	83 ec 14             	sub    $0x14,%esp
f0100991:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100994:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100997:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010099a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010099d:	8b 1a                	mov    (%edx),%ebx
f010099f:	8b 01                	mov    (%ecx),%eax
f01009a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009a4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009ab:	eb 7f                	jmp    f0100a2c <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009b0:	01 d8                	add    %ebx,%eax
f01009b2:	89 c6                	mov    %eax,%esi
f01009b4:	c1 ee 1f             	shr    $0x1f,%esi
f01009b7:	01 c6                	add    %eax,%esi
f01009b9:	d1 fe                	sar    %esi
f01009bb:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009be:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009c1:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009c4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009c6:	eb 03                	jmp    f01009cb <stab_binsearch+0x43>
			m--;
f01009c8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009cb:	39 c3                	cmp    %eax,%ebx
f01009cd:	7f 0d                	jg     f01009dc <stab_binsearch+0x54>
f01009cf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009d3:	83 ea 0c             	sub    $0xc,%edx
f01009d6:	39 f9                	cmp    %edi,%ecx
f01009d8:	75 ee                	jne    f01009c8 <stab_binsearch+0x40>
f01009da:	eb 05                	jmp    f01009e1 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009dc:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009df:	eb 4b                	jmp    f0100a2c <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009e1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009e4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009e7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009eb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ee:	76 11                	jbe    f0100a01 <stab_binsearch+0x79>
			*region_left = m;
f01009f0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009f3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009f5:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009ff:	eb 2b                	jmp    f0100a2c <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a01:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a04:	73 14                	jae    f0100a1a <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a06:	83 e8 01             	sub    $0x1,%eax
f0100a09:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a0c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a0f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a11:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a18:	eb 12                	jmp    f0100a2c <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a1a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a1d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a1f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a23:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a25:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a2c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a2f:	0f 8e 78 ff ff ff    	jle    f01009ad <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a35:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a39:	75 0f                	jne    f0100a4a <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a3e:	8b 00                	mov    (%eax),%eax
f0100a40:	83 e8 01             	sub    $0x1,%eax
f0100a43:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a46:	89 06                	mov    %eax,(%esi)
f0100a48:	eb 2c                	jmp    f0100a76 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a4a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a4d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a4f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a52:	8b 0e                	mov    (%esi),%ecx
f0100a54:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a57:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a5a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5d:	eb 03                	jmp    f0100a62 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a5f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a62:	39 c8                	cmp    %ecx,%eax
f0100a64:	7e 0b                	jle    f0100a71 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a66:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a6a:	83 ea 0c             	sub    $0xc,%edx
f0100a6d:	39 df                	cmp    %ebx,%edi
f0100a6f:	75 ee                	jne    f0100a5f <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a71:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a74:	89 06                	mov    %eax,(%esi)
	}
}
f0100a76:	83 c4 14             	add    $0x14,%esp
f0100a79:	5b                   	pop    %ebx
f0100a7a:	5e                   	pop    %esi
f0100a7b:	5f                   	pop    %edi
f0100a7c:	5d                   	pop    %ebp
f0100a7d:	c3                   	ret    

f0100a7e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a7e:	55                   	push   %ebp
f0100a7f:	89 e5                	mov    %esp,%ebp
f0100a81:	57                   	push   %edi
f0100a82:	56                   	push   %esi
f0100a83:	53                   	push   %ebx
f0100a84:	83 ec 3c             	sub    $0x3c,%esp
f0100a87:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a8a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a8d:	c7 03 24 1e 10 f0    	movl   $0xf0101e24,(%ebx)
	info->eip_line = 0;
f0100a93:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a9a:	c7 43 08 24 1e 10 f0 	movl   $0xf0101e24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aa1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aa8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aab:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ab2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ab8:	76 11                	jbe    f0100acb <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aba:	b8 30 76 10 f0       	mov    $0xf0107630,%eax
f0100abf:	3d ed 59 10 f0       	cmp    $0xf01059ed,%eax
f0100ac4:	77 19                	ja     f0100adf <debuginfo_eip+0x61>
f0100ac6:	e9 a1 01 00 00       	jmp    f0100c6c <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100acb:	83 ec 04             	sub    $0x4,%esp
f0100ace:	68 2e 1e 10 f0       	push   $0xf0101e2e
f0100ad3:	6a 7f                	push   $0x7f
f0100ad5:	68 3b 1e 10 f0       	push   $0xf0101e3b
f0100ada:	e8 1c f6 ff ff       	call   f01000fb <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100adf:	80 3d 2f 76 10 f0 00 	cmpb   $0x0,0xf010762f
f0100ae6:	0f 85 87 01 00 00    	jne    f0100c73 <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aec:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100af3:	b8 ec 59 10 f0       	mov    $0xf01059ec,%eax
f0100af8:	2d 5c 20 10 f0       	sub    $0xf010205c,%eax
f0100afd:	c1 f8 02             	sar    $0x2,%eax
f0100b00:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b06:	83 e8 01             	sub    $0x1,%eax
f0100b09:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b0c:	83 ec 08             	sub    $0x8,%esp
f0100b0f:	56                   	push   %esi
f0100b10:	6a 64                	push   $0x64
f0100b12:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b15:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b18:	b8 5c 20 10 f0       	mov    $0xf010205c,%eax
f0100b1d:	e8 66 fe ff ff       	call   f0100988 <stab_binsearch>
	if (lfile == 0)
f0100b22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b25:	83 c4 10             	add    $0x10,%esp
f0100b28:	85 c0                	test   %eax,%eax
f0100b2a:	0f 84 4a 01 00 00    	je     f0100c7a <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b30:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b33:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b36:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b39:	83 ec 08             	sub    $0x8,%esp
f0100b3c:	56                   	push   %esi
f0100b3d:	6a 24                	push   $0x24
f0100b3f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b42:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b45:	b8 5c 20 10 f0       	mov    $0xf010205c,%eax
f0100b4a:	e8 39 fe ff ff       	call   f0100988 <stab_binsearch>

	if (lfun <= rfun) {
f0100b4f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b52:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b55:	83 c4 10             	add    $0x10,%esp
f0100b58:	39 d0                	cmp    %edx,%eax
f0100b5a:	7f 40                	jg     f0100b9c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b5c:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b5f:	c1 e1 02             	shl    $0x2,%ecx
f0100b62:	8d b9 5c 20 10 f0    	lea    -0xfefdfa4(%ecx),%edi
f0100b68:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b6b:	8b b9 5c 20 10 f0    	mov    -0xfefdfa4(%ecx),%edi
f0100b71:	b9 30 76 10 f0       	mov    $0xf0107630,%ecx
f0100b76:	81 e9 ed 59 10 f0    	sub    $0xf01059ed,%ecx
f0100b7c:	39 cf                	cmp    %ecx,%edi
f0100b7e:	73 09                	jae    f0100b89 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b80:	81 c7 ed 59 10 f0    	add    $0xf01059ed,%edi
f0100b86:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b89:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b8c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b8f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b92:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b97:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b9a:	eb 0f                	jmp    f0100bab <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b9c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ba5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bab:	83 ec 08             	sub    $0x8,%esp
f0100bae:	6a 3a                	push   $0x3a
f0100bb0:	ff 73 08             	pushl  0x8(%ebx)
f0100bb3:	e8 49 08 00 00       	call   f0101401 <strfind>
f0100bb8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bbb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bbe:	83 c4 08             	add    $0x8,%esp
f0100bc1:	56                   	push   %esi
f0100bc2:	6a 44                	push   $0x44
f0100bc4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bc7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bca:	b8 5c 20 10 f0       	mov    $0xf010205c,%eax
f0100bcf:	e8 b4 fd ff ff       	call   f0100988 <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f0100bd4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100bd7:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100bda:	8d 04 85 5c 20 10 f0 	lea    -0xfefdfa4(,%eax,4),%eax
f0100be1:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100be5:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100beb:	83 c4 10             	add    $0x10,%esp
f0100bee:	eb 06                	jmp    f0100bf6 <debuginfo_eip+0x178>
f0100bf0:	83 ea 01             	sub    $0x1,%edx
f0100bf3:	83 e8 0c             	sub    $0xc,%eax
f0100bf6:	39 d6                	cmp    %edx,%esi
f0100bf8:	7f 34                	jg     f0100c2e <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0100bfa:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100bfe:	80 f9 84             	cmp    $0x84,%cl
f0100c01:	74 0b                	je     f0100c0e <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c03:	80 f9 64             	cmp    $0x64,%cl
f0100c06:	75 e8                	jne    f0100bf0 <debuginfo_eip+0x172>
f0100c08:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c0c:	74 e2                	je     f0100bf0 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c0e:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c11:	8b 14 85 5c 20 10 f0 	mov    -0xfefdfa4(,%eax,4),%edx
f0100c18:	b8 30 76 10 f0       	mov    $0xf0107630,%eax
f0100c1d:	2d ed 59 10 f0       	sub    $0xf01059ed,%eax
f0100c22:	39 c2                	cmp    %eax,%edx
f0100c24:	73 08                	jae    f0100c2e <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c26:	81 c2 ed 59 10 f0    	add    $0xf01059ed,%edx
f0100c2c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c2e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c31:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c34:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c39:	39 f2                	cmp    %esi,%edx
f0100c3b:	7d 49                	jge    f0100c86 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0100c3d:	83 c2 01             	add    $0x1,%edx
f0100c40:	89 d0                	mov    %edx,%eax
f0100c42:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c45:	8d 14 95 5c 20 10 f0 	lea    -0xfefdfa4(,%edx,4),%edx
f0100c4c:	eb 04                	jmp    f0100c52 <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c4e:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c52:	39 c6                	cmp    %eax,%esi
f0100c54:	7e 2b                	jle    f0100c81 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c56:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c5a:	83 c0 01             	add    $0x1,%eax
f0100c5d:	83 c2 0c             	add    $0xc,%edx
f0100c60:	80 f9 a0             	cmp    $0xa0,%cl
f0100c63:	74 e9                	je     f0100c4e <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c65:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c6a:	eb 1a                	jmp    f0100c86 <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c71:	eb 13                	jmp    f0100c86 <debuginfo_eip+0x208>
f0100c73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c78:	eb 0c                	jmp    f0100c86 <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c7a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c7f:	eb 05                	jmp    f0100c86 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c81:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c86:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c89:	5b                   	pop    %ebx
f0100c8a:	5e                   	pop    %esi
f0100c8b:	5f                   	pop    %edi
f0100c8c:	5d                   	pop    %ebp
f0100c8d:	c3                   	ret    

f0100c8e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c8e:	55                   	push   %ebp
f0100c8f:	89 e5                	mov    %esp,%ebp
f0100c91:	57                   	push   %edi
f0100c92:	56                   	push   %esi
f0100c93:	53                   	push   %ebx
f0100c94:	83 ec 1c             	sub    $0x1c,%esp
f0100c97:	89 c7                	mov    %eax,%edi
f0100c99:	89 d6                	mov    %edx,%esi
f0100c9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c9e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ca1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ca4:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ca7:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100caa:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100caf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cb2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cb5:	39 d3                	cmp    %edx,%ebx
f0100cb7:	72 05                	jb     f0100cbe <printnum+0x30>
f0100cb9:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cbc:	77 45                	ja     f0100d03 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cbe:	83 ec 0c             	sub    $0xc,%esp
f0100cc1:	ff 75 18             	pushl  0x18(%ebp)
f0100cc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cc7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cca:	53                   	push   %ebx
f0100ccb:	ff 75 10             	pushl  0x10(%ebp)
f0100cce:	83 ec 08             	sub    $0x8,%esp
f0100cd1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cd4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cd7:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cda:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cdd:	e8 3e 09 00 00       	call   f0101620 <__udivdi3>
f0100ce2:	83 c4 18             	add    $0x18,%esp
f0100ce5:	52                   	push   %edx
f0100ce6:	50                   	push   %eax
f0100ce7:	89 f2                	mov    %esi,%edx
f0100ce9:	89 f8                	mov    %edi,%eax
f0100ceb:	e8 9e ff ff ff       	call   f0100c8e <printnum>
f0100cf0:	83 c4 20             	add    $0x20,%esp
f0100cf3:	eb 18                	jmp    f0100d0d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cf5:	83 ec 08             	sub    $0x8,%esp
f0100cf8:	56                   	push   %esi
f0100cf9:	ff 75 18             	pushl  0x18(%ebp)
f0100cfc:	ff d7                	call   *%edi
f0100cfe:	83 c4 10             	add    $0x10,%esp
f0100d01:	eb 03                	jmp    f0100d06 <printnum+0x78>
f0100d03:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d06:	83 eb 01             	sub    $0x1,%ebx
f0100d09:	85 db                	test   %ebx,%ebx
f0100d0b:	7f e8                	jg     f0100cf5 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d0d:	83 ec 08             	sub    $0x8,%esp
f0100d10:	56                   	push   %esi
f0100d11:	83 ec 04             	sub    $0x4,%esp
f0100d14:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d17:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d1a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d1d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d20:	e8 2b 0a 00 00       	call   f0101750 <__umoddi3>
f0100d25:	83 c4 14             	add    $0x14,%esp
f0100d28:	0f be 80 49 1e 10 f0 	movsbl -0xfefe1b7(%eax),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	ff d7                	call   *%edi
}
f0100d32:	83 c4 10             	add    $0x10,%esp
f0100d35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d38:	5b                   	pop    %ebx
f0100d39:	5e                   	pop    %esi
f0100d3a:	5f                   	pop    %edi
f0100d3b:	5d                   	pop    %ebp
f0100d3c:	c3                   	ret    

f0100d3d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d3d:	55                   	push   %ebp
f0100d3e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d40:	83 fa 01             	cmp    $0x1,%edx
f0100d43:	7e 0e                	jle    f0100d53 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d45:	8b 10                	mov    (%eax),%edx
f0100d47:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d4a:	89 08                	mov    %ecx,(%eax)
f0100d4c:	8b 02                	mov    (%edx),%eax
f0100d4e:	8b 52 04             	mov    0x4(%edx),%edx
f0100d51:	eb 22                	jmp    f0100d75 <getuint+0x38>
	else if (lflag)
f0100d53:	85 d2                	test   %edx,%edx
f0100d55:	74 10                	je     f0100d67 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d57:	8b 10                	mov    (%eax),%edx
f0100d59:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d5c:	89 08                	mov    %ecx,(%eax)
f0100d5e:	8b 02                	mov    (%edx),%eax
f0100d60:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d65:	eb 0e                	jmp    f0100d75 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d67:	8b 10                	mov    (%eax),%edx
f0100d69:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d6c:	89 08                	mov    %ecx,(%eax)
f0100d6e:	8b 02                	mov    (%edx),%eax
f0100d70:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d75:	5d                   	pop    %ebp
f0100d76:	c3                   	ret    

f0100d77 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d77:	55                   	push   %ebp
f0100d78:	89 e5                	mov    %esp,%ebp
f0100d7a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d7d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d81:	8b 10                	mov    (%eax),%edx
f0100d83:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d86:	73 0a                	jae    f0100d92 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d88:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d8b:	89 08                	mov    %ecx,(%eax)
f0100d8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d90:	88 02                	mov    %al,(%edx)
}
f0100d92:	5d                   	pop    %ebp
f0100d93:	c3                   	ret    

f0100d94 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d94:	55                   	push   %ebp
f0100d95:	89 e5                	mov    %esp,%ebp
f0100d97:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d9a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d9d:	50                   	push   %eax
f0100d9e:	ff 75 10             	pushl  0x10(%ebp)
f0100da1:	ff 75 0c             	pushl  0xc(%ebp)
f0100da4:	ff 75 08             	pushl  0x8(%ebp)
f0100da7:	e8 05 00 00 00       	call   f0100db1 <vprintfmt>
	va_end(ap);
}
f0100dac:	83 c4 10             	add    $0x10,%esp
f0100daf:	c9                   	leave  
f0100db0:	c3                   	ret    

f0100db1 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100db1:	55                   	push   %ebp
f0100db2:	89 e5                	mov    %esp,%ebp
f0100db4:	57                   	push   %edi
f0100db5:	56                   	push   %esi
f0100db6:	53                   	push   %ebx
f0100db7:	83 ec 2c             	sub    $0x2c,%esp
f0100dba:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dbd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dc0:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100dc3:	eb 12                	jmp    f0100dd7 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dc5:	85 c0                	test   %eax,%eax
f0100dc7:	0f 84 89 03 00 00    	je     f0101156 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100dcd:	83 ec 08             	sub    $0x8,%esp
f0100dd0:	53                   	push   %ebx
f0100dd1:	50                   	push   %eax
f0100dd2:	ff d6                	call   *%esi
f0100dd4:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dd7:	83 c7 01             	add    $0x1,%edi
f0100dda:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100dde:	83 f8 25             	cmp    $0x25,%eax
f0100de1:	75 e2                	jne    f0100dc5 <vprintfmt+0x14>
f0100de3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100de7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dee:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100df5:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100dfc:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e01:	eb 07                	jmp    f0100e0a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e03:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e06:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0a:	8d 47 01             	lea    0x1(%edi),%eax
f0100e0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e10:	0f b6 07             	movzbl (%edi),%eax
f0100e13:	0f b6 c8             	movzbl %al,%ecx
f0100e16:	83 e8 23             	sub    $0x23,%eax
f0100e19:	3c 55                	cmp    $0x55,%al
f0100e1b:	0f 87 1a 03 00 00    	ja     f010113b <vprintfmt+0x38a>
f0100e21:	0f b6 c0             	movzbl %al,%eax
f0100e24:	ff 24 85 d8 1e 10 f0 	jmp    *-0xfefe128(,%eax,4)
f0100e2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e2e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e32:	eb d6                	jmp    f0100e0a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e37:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e3f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e42:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e46:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e49:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e4c:	83 fa 09             	cmp    $0x9,%edx
f0100e4f:	77 39                	ja     f0100e8a <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e51:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e54:	eb e9                	jmp    f0100e3f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e56:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e59:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e5c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e5f:	8b 00                	mov    (%eax),%eax
f0100e61:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e67:	eb 27                	jmp    f0100e90 <vprintfmt+0xdf>
f0100e69:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e6c:	85 c0                	test   %eax,%eax
f0100e6e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e73:	0f 49 c8             	cmovns %eax,%ecx
f0100e76:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e7c:	eb 8c                	jmp    f0100e0a <vprintfmt+0x59>
f0100e7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e81:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e88:	eb 80                	jmp    f0100e0a <vprintfmt+0x59>
f0100e8a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e8d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e90:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e94:	0f 89 70 ff ff ff    	jns    f0100e0a <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e9a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e9d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ea0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ea7:	e9 5e ff ff ff       	jmp    f0100e0a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eac:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eaf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eb2:	e9 53 ff ff ff       	jmp    f0100e0a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eba:	8d 50 04             	lea    0x4(%eax),%edx
f0100ebd:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec0:	83 ec 08             	sub    $0x8,%esp
f0100ec3:	53                   	push   %ebx
f0100ec4:	ff 30                	pushl  (%eax)
f0100ec6:	ff d6                	call   *%esi
			break;
f0100ec8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ecb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ece:	e9 04 ff ff ff       	jmp    f0100dd7 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed6:	8d 50 04             	lea    0x4(%eax),%edx
f0100ed9:	89 55 14             	mov    %edx,0x14(%ebp)
f0100edc:	8b 00                	mov    (%eax),%eax
f0100ede:	99                   	cltd   
f0100edf:	31 d0                	xor    %edx,%eax
f0100ee1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ee3:	83 f8 06             	cmp    $0x6,%eax
f0100ee6:	7f 0b                	jg     f0100ef3 <vprintfmt+0x142>
f0100ee8:	8b 14 85 30 20 10 f0 	mov    -0xfefdfd0(,%eax,4),%edx
f0100eef:	85 d2                	test   %edx,%edx
f0100ef1:	75 18                	jne    f0100f0b <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100ef3:	50                   	push   %eax
f0100ef4:	68 61 1e 10 f0       	push   $0xf0101e61
f0100ef9:	53                   	push   %ebx
f0100efa:	56                   	push   %esi
f0100efb:	e8 94 fe ff ff       	call   f0100d94 <printfmt>
f0100f00:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f03:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f06:	e9 cc fe ff ff       	jmp    f0100dd7 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f0b:	52                   	push   %edx
f0100f0c:	68 6a 1e 10 f0       	push   $0xf0101e6a
f0100f11:	53                   	push   %ebx
f0100f12:	56                   	push   %esi
f0100f13:	e8 7c fe ff ff       	call   f0100d94 <printfmt>
f0100f18:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f1e:	e9 b4 fe ff ff       	jmp    f0100dd7 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f23:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f26:	8d 50 04             	lea    0x4(%eax),%edx
f0100f29:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f2c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f2e:	85 ff                	test   %edi,%edi
f0100f30:	b8 5a 1e 10 f0       	mov    $0xf0101e5a,%eax
f0100f35:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f38:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f3c:	0f 8e 94 00 00 00    	jle    f0100fd6 <vprintfmt+0x225>
f0100f42:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f46:	0f 84 98 00 00 00    	je     f0100fe4 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f4c:	83 ec 08             	sub    $0x8,%esp
f0100f4f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f52:	57                   	push   %edi
f0100f53:	e8 5f 03 00 00       	call   f01012b7 <strnlen>
f0100f58:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f5b:	29 c1                	sub    %eax,%ecx
f0100f5d:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f60:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f63:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f67:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f6a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f6d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f6f:	eb 0f                	jmp    f0100f80 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f71:	83 ec 08             	sub    $0x8,%esp
f0100f74:	53                   	push   %ebx
f0100f75:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f78:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7a:	83 ef 01             	sub    $0x1,%edi
f0100f7d:	83 c4 10             	add    $0x10,%esp
f0100f80:	85 ff                	test   %edi,%edi
f0100f82:	7f ed                	jg     f0100f71 <vprintfmt+0x1c0>
f0100f84:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f87:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f8a:	85 c9                	test   %ecx,%ecx
f0100f8c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f91:	0f 49 c1             	cmovns %ecx,%eax
f0100f94:	29 c1                	sub    %eax,%ecx
f0100f96:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f99:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f9c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f9f:	89 cb                	mov    %ecx,%ebx
f0100fa1:	eb 4d                	jmp    f0100ff0 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fa3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fa7:	74 1b                	je     f0100fc4 <vprintfmt+0x213>
f0100fa9:	0f be c0             	movsbl %al,%eax
f0100fac:	83 e8 20             	sub    $0x20,%eax
f0100faf:	83 f8 5e             	cmp    $0x5e,%eax
f0100fb2:	76 10                	jbe    f0100fc4 <vprintfmt+0x213>
					putch('?', putdat);
f0100fb4:	83 ec 08             	sub    $0x8,%esp
f0100fb7:	ff 75 0c             	pushl  0xc(%ebp)
f0100fba:	6a 3f                	push   $0x3f
f0100fbc:	ff 55 08             	call   *0x8(%ebp)
f0100fbf:	83 c4 10             	add    $0x10,%esp
f0100fc2:	eb 0d                	jmp    f0100fd1 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100fc4:	83 ec 08             	sub    $0x8,%esp
f0100fc7:	ff 75 0c             	pushl  0xc(%ebp)
f0100fca:	52                   	push   %edx
f0100fcb:	ff 55 08             	call   *0x8(%ebp)
f0100fce:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fd1:	83 eb 01             	sub    $0x1,%ebx
f0100fd4:	eb 1a                	jmp    f0100ff0 <vprintfmt+0x23f>
f0100fd6:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fd9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fdc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fdf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fe2:	eb 0c                	jmp    f0100ff0 <vprintfmt+0x23f>
f0100fe4:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fe7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fea:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fed:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ff0:	83 c7 01             	add    $0x1,%edi
f0100ff3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100ff7:	0f be d0             	movsbl %al,%edx
f0100ffa:	85 d2                	test   %edx,%edx
f0100ffc:	74 23                	je     f0101021 <vprintfmt+0x270>
f0100ffe:	85 f6                	test   %esi,%esi
f0101000:	78 a1                	js     f0100fa3 <vprintfmt+0x1f2>
f0101002:	83 ee 01             	sub    $0x1,%esi
f0101005:	79 9c                	jns    f0100fa3 <vprintfmt+0x1f2>
f0101007:	89 df                	mov    %ebx,%edi
f0101009:	8b 75 08             	mov    0x8(%ebp),%esi
f010100c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010100f:	eb 18                	jmp    f0101029 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101011:	83 ec 08             	sub    $0x8,%esp
f0101014:	53                   	push   %ebx
f0101015:	6a 20                	push   $0x20
f0101017:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101019:	83 ef 01             	sub    $0x1,%edi
f010101c:	83 c4 10             	add    $0x10,%esp
f010101f:	eb 08                	jmp    f0101029 <vprintfmt+0x278>
f0101021:	89 df                	mov    %ebx,%edi
f0101023:	8b 75 08             	mov    0x8(%ebp),%esi
f0101026:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101029:	85 ff                	test   %edi,%edi
f010102b:	7f e4                	jg     f0101011 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101030:	e9 a2 fd ff ff       	jmp    f0100dd7 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101035:	83 fa 01             	cmp    $0x1,%edx
f0101038:	7e 16                	jle    f0101050 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f010103a:	8b 45 14             	mov    0x14(%ebp),%eax
f010103d:	8d 50 08             	lea    0x8(%eax),%edx
f0101040:	89 55 14             	mov    %edx,0x14(%ebp)
f0101043:	8b 50 04             	mov    0x4(%eax),%edx
f0101046:	8b 00                	mov    (%eax),%eax
f0101048:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010104b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010104e:	eb 32                	jmp    f0101082 <vprintfmt+0x2d1>
	else if (lflag)
f0101050:	85 d2                	test   %edx,%edx
f0101052:	74 18                	je     f010106c <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101054:	8b 45 14             	mov    0x14(%ebp),%eax
f0101057:	8d 50 04             	lea    0x4(%eax),%edx
f010105a:	89 55 14             	mov    %edx,0x14(%ebp)
f010105d:	8b 00                	mov    (%eax),%eax
f010105f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101062:	89 c1                	mov    %eax,%ecx
f0101064:	c1 f9 1f             	sar    $0x1f,%ecx
f0101067:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010106a:	eb 16                	jmp    f0101082 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010106c:	8b 45 14             	mov    0x14(%ebp),%eax
f010106f:	8d 50 04             	lea    0x4(%eax),%edx
f0101072:	89 55 14             	mov    %edx,0x14(%ebp)
f0101075:	8b 00                	mov    (%eax),%eax
f0101077:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010107a:	89 c1                	mov    %eax,%ecx
f010107c:	c1 f9 1f             	sar    $0x1f,%ecx
f010107f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101082:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101085:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101088:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010108d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101091:	79 74                	jns    f0101107 <vprintfmt+0x356>
				putch('-', putdat);
f0101093:	83 ec 08             	sub    $0x8,%esp
f0101096:	53                   	push   %ebx
f0101097:	6a 2d                	push   $0x2d
f0101099:	ff d6                	call   *%esi
				num = -(long long) num;
f010109b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010109e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010a1:	f7 d8                	neg    %eax
f01010a3:	83 d2 00             	adc    $0x0,%edx
f01010a6:	f7 da                	neg    %edx
f01010a8:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010ab:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010b0:	eb 55                	jmp    f0101107 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010b2:	8d 45 14             	lea    0x14(%ebp),%eax
f01010b5:	e8 83 fc ff ff       	call   f0100d3d <getuint>
			base = 10;
f01010ba:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010bf:	eb 46                	jmp    f0101107 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010c1:	8d 45 14             	lea    0x14(%ebp),%eax
f01010c4:	e8 74 fc ff ff       	call   f0100d3d <getuint>
			base = 8;
f01010c9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010ce:	eb 37                	jmp    f0101107 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01010d0:	83 ec 08             	sub    $0x8,%esp
f01010d3:	53                   	push   %ebx
f01010d4:	6a 30                	push   $0x30
f01010d6:	ff d6                	call   *%esi
			putch('x', putdat);
f01010d8:	83 c4 08             	add    $0x8,%esp
f01010db:	53                   	push   %ebx
f01010dc:	6a 78                	push   $0x78
f01010de:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e3:	8d 50 04             	lea    0x4(%eax),%edx
f01010e6:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010e9:	8b 00                	mov    (%eax),%eax
f01010eb:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010f0:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010f3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010f8:	eb 0d                	jmp    f0101107 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010fa:	8d 45 14             	lea    0x14(%ebp),%eax
f01010fd:	e8 3b fc ff ff       	call   f0100d3d <getuint>
			base = 16;
f0101102:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101107:	83 ec 0c             	sub    $0xc,%esp
f010110a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010110e:	57                   	push   %edi
f010110f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101112:	51                   	push   %ecx
f0101113:	52                   	push   %edx
f0101114:	50                   	push   %eax
f0101115:	89 da                	mov    %ebx,%edx
f0101117:	89 f0                	mov    %esi,%eax
f0101119:	e8 70 fb ff ff       	call   f0100c8e <printnum>
			break;
f010111e:	83 c4 20             	add    $0x20,%esp
f0101121:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101124:	e9 ae fc ff ff       	jmp    f0100dd7 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101129:	83 ec 08             	sub    $0x8,%esp
f010112c:	53                   	push   %ebx
f010112d:	51                   	push   %ecx
f010112e:	ff d6                	call   *%esi
			break;
f0101130:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101133:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101136:	e9 9c fc ff ff       	jmp    f0100dd7 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010113b:	83 ec 08             	sub    $0x8,%esp
f010113e:	53                   	push   %ebx
f010113f:	6a 25                	push   $0x25
f0101141:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101143:	83 c4 10             	add    $0x10,%esp
f0101146:	eb 03                	jmp    f010114b <vprintfmt+0x39a>
f0101148:	83 ef 01             	sub    $0x1,%edi
f010114b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010114f:	75 f7                	jne    f0101148 <vprintfmt+0x397>
f0101151:	e9 81 fc ff ff       	jmp    f0100dd7 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101156:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101159:	5b                   	pop    %ebx
f010115a:	5e                   	pop    %esi
f010115b:	5f                   	pop    %edi
f010115c:	5d                   	pop    %ebp
f010115d:	c3                   	ret    

f010115e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010115e:	55                   	push   %ebp
f010115f:	89 e5                	mov    %esp,%ebp
f0101161:	83 ec 18             	sub    $0x18,%esp
f0101164:	8b 45 08             	mov    0x8(%ebp),%eax
f0101167:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010116a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010116d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101171:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101174:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010117b:	85 c0                	test   %eax,%eax
f010117d:	74 26                	je     f01011a5 <vsnprintf+0x47>
f010117f:	85 d2                	test   %edx,%edx
f0101181:	7e 22                	jle    f01011a5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101183:	ff 75 14             	pushl  0x14(%ebp)
f0101186:	ff 75 10             	pushl  0x10(%ebp)
f0101189:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010118c:	50                   	push   %eax
f010118d:	68 77 0d 10 f0       	push   $0xf0100d77
f0101192:	e8 1a fc ff ff       	call   f0100db1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101197:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010119a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010119d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011a0:	83 c4 10             	add    $0x10,%esp
f01011a3:	eb 05                	jmp    f01011aa <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011a5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011aa:	c9                   	leave  
f01011ab:	c3                   	ret    

f01011ac <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011ac:	55                   	push   %ebp
f01011ad:	89 e5                	mov    %esp,%ebp
f01011af:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011b2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011b5:	50                   	push   %eax
f01011b6:	ff 75 10             	pushl  0x10(%ebp)
f01011b9:	ff 75 0c             	pushl  0xc(%ebp)
f01011bc:	ff 75 08             	pushl  0x8(%ebp)
f01011bf:	e8 9a ff ff ff       	call   f010115e <vsnprintf>
	va_end(ap);

	return rc;
}
f01011c4:	c9                   	leave  
f01011c5:	c3                   	ret    

f01011c6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011c6:	55                   	push   %ebp
f01011c7:	89 e5                	mov    %esp,%ebp
f01011c9:	57                   	push   %edi
f01011ca:	56                   	push   %esi
f01011cb:	53                   	push   %ebx
f01011cc:	83 ec 0c             	sub    $0xc,%esp
f01011cf:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011d2:	85 c0                	test   %eax,%eax
f01011d4:	74 11                	je     f01011e7 <readline+0x21>
		cprintf("%s", prompt);
f01011d6:	83 ec 08             	sub    $0x8,%esp
f01011d9:	50                   	push   %eax
f01011da:	68 6a 1e 10 f0       	push   $0xf0101e6a
f01011df:	e8 90 f7 ff ff       	call   f0100974 <cprintf>
f01011e4:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011e7:	83 ec 0c             	sub    $0xc,%esp
f01011ea:	6a 00                	push   $0x0
f01011ec:	e8 a0 f4 ff ff       	call   f0100691 <iscons>
f01011f1:	89 c7                	mov    %eax,%edi
f01011f3:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011f6:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011fb:	e8 80 f4 ff ff       	call   f0100680 <getchar>
f0101200:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101202:	85 c0                	test   %eax,%eax
f0101204:	79 18                	jns    f010121e <readline+0x58>
			cprintf("read error: %e\n", c);
f0101206:	83 ec 08             	sub    $0x8,%esp
f0101209:	50                   	push   %eax
f010120a:	68 4c 20 10 f0       	push   $0xf010204c
f010120f:	e8 60 f7 ff ff       	call   f0100974 <cprintf>
			return NULL;
f0101214:	83 c4 10             	add    $0x10,%esp
f0101217:	b8 00 00 00 00       	mov    $0x0,%eax
f010121c:	eb 79                	jmp    f0101297 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010121e:	83 f8 08             	cmp    $0x8,%eax
f0101221:	0f 94 c2             	sete   %dl
f0101224:	83 f8 7f             	cmp    $0x7f,%eax
f0101227:	0f 94 c0             	sete   %al
f010122a:	08 c2                	or     %al,%dl
f010122c:	74 1a                	je     f0101248 <readline+0x82>
f010122e:	85 f6                	test   %esi,%esi
f0101230:	7e 16                	jle    f0101248 <readline+0x82>
			if (echoing)
f0101232:	85 ff                	test   %edi,%edi
f0101234:	74 0d                	je     f0101243 <readline+0x7d>
				cputchar('\b');
f0101236:	83 ec 0c             	sub    $0xc,%esp
f0101239:	6a 08                	push   $0x8
f010123b:	e8 30 f4 ff ff       	call   f0100670 <cputchar>
f0101240:	83 c4 10             	add    $0x10,%esp
			i--;
f0101243:	83 ee 01             	sub    $0x1,%esi
f0101246:	eb b3                	jmp    f01011fb <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101248:	83 fb 1f             	cmp    $0x1f,%ebx
f010124b:	7e 23                	jle    f0101270 <readline+0xaa>
f010124d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101253:	7f 1b                	jg     f0101270 <readline+0xaa>
			if (echoing)
f0101255:	85 ff                	test   %edi,%edi
f0101257:	74 0c                	je     f0101265 <readline+0x9f>
				cputchar(c);
f0101259:	83 ec 0c             	sub    $0xc,%esp
f010125c:	53                   	push   %ebx
f010125d:	e8 0e f4 ff ff       	call   f0100670 <cputchar>
f0101262:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101265:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010126b:	8d 76 01             	lea    0x1(%esi),%esi
f010126e:	eb 8b                	jmp    f01011fb <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101270:	83 fb 0a             	cmp    $0xa,%ebx
f0101273:	74 05                	je     f010127a <readline+0xb4>
f0101275:	83 fb 0d             	cmp    $0xd,%ebx
f0101278:	75 81                	jne    f01011fb <readline+0x35>
			if (echoing)
f010127a:	85 ff                	test   %edi,%edi
f010127c:	74 0d                	je     f010128b <readline+0xc5>
				cputchar('\n');
f010127e:	83 ec 0c             	sub    $0xc,%esp
f0101281:	6a 0a                	push   $0xa
f0101283:	e8 e8 f3 ff ff       	call   f0100670 <cputchar>
f0101288:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010128b:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101292:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101297:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010129a:	5b                   	pop    %ebx
f010129b:	5e                   	pop    %esi
f010129c:	5f                   	pop    %edi
f010129d:	5d                   	pop    %ebp
f010129e:	c3                   	ret    

f010129f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010129f:	55                   	push   %ebp
f01012a0:	89 e5                	mov    %esp,%ebp
f01012a2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012aa:	eb 03                	jmp    f01012af <strlen+0x10>
		n++;
f01012ac:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012af:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012b3:	75 f7                	jne    f01012ac <strlen+0xd>
		n++;
	return n;
}
f01012b5:	5d                   	pop    %ebp
f01012b6:	c3                   	ret    

f01012b7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012b7:	55                   	push   %ebp
f01012b8:	89 e5                	mov    %esp,%ebp
f01012ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012bd:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012c0:	ba 00 00 00 00       	mov    $0x0,%edx
f01012c5:	eb 03                	jmp    f01012ca <strnlen+0x13>
		n++;
f01012c7:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ca:	39 c2                	cmp    %eax,%edx
f01012cc:	74 08                	je     f01012d6 <strnlen+0x1f>
f01012ce:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012d2:	75 f3                	jne    f01012c7 <strnlen+0x10>
f01012d4:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012d6:	5d                   	pop    %ebp
f01012d7:	c3                   	ret    

f01012d8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012d8:	55                   	push   %ebp
f01012d9:	89 e5                	mov    %esp,%ebp
f01012db:	53                   	push   %ebx
f01012dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01012df:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012e2:	89 c2                	mov    %eax,%edx
f01012e4:	83 c2 01             	add    $0x1,%edx
f01012e7:	83 c1 01             	add    $0x1,%ecx
f01012ea:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012ee:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012f1:	84 db                	test   %bl,%bl
f01012f3:	75 ef                	jne    f01012e4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012f5:	5b                   	pop    %ebx
f01012f6:	5d                   	pop    %ebp
f01012f7:	c3                   	ret    

f01012f8 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012f8:	55                   	push   %ebp
f01012f9:	89 e5                	mov    %esp,%ebp
f01012fb:	53                   	push   %ebx
f01012fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012ff:	53                   	push   %ebx
f0101300:	e8 9a ff ff ff       	call   f010129f <strlen>
f0101305:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101308:	ff 75 0c             	pushl  0xc(%ebp)
f010130b:	01 d8                	add    %ebx,%eax
f010130d:	50                   	push   %eax
f010130e:	e8 c5 ff ff ff       	call   f01012d8 <strcpy>
	return dst;
}
f0101313:	89 d8                	mov    %ebx,%eax
f0101315:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101318:	c9                   	leave  
f0101319:	c3                   	ret    

f010131a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010131a:	55                   	push   %ebp
f010131b:	89 e5                	mov    %esp,%ebp
f010131d:	56                   	push   %esi
f010131e:	53                   	push   %ebx
f010131f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101322:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101325:	89 f3                	mov    %esi,%ebx
f0101327:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010132a:	89 f2                	mov    %esi,%edx
f010132c:	eb 0f                	jmp    f010133d <strncpy+0x23>
		*dst++ = *src;
f010132e:	83 c2 01             	add    $0x1,%edx
f0101331:	0f b6 01             	movzbl (%ecx),%eax
f0101334:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101337:	80 39 01             	cmpb   $0x1,(%ecx)
f010133a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010133d:	39 da                	cmp    %ebx,%edx
f010133f:	75 ed                	jne    f010132e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101341:	89 f0                	mov    %esi,%eax
f0101343:	5b                   	pop    %ebx
f0101344:	5e                   	pop    %esi
f0101345:	5d                   	pop    %ebp
f0101346:	c3                   	ret    

f0101347 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	56                   	push   %esi
f010134b:	53                   	push   %ebx
f010134c:	8b 75 08             	mov    0x8(%ebp),%esi
f010134f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101352:	8b 55 10             	mov    0x10(%ebp),%edx
f0101355:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101357:	85 d2                	test   %edx,%edx
f0101359:	74 21                	je     f010137c <strlcpy+0x35>
f010135b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010135f:	89 f2                	mov    %esi,%edx
f0101361:	eb 09                	jmp    f010136c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101363:	83 c2 01             	add    $0x1,%edx
f0101366:	83 c1 01             	add    $0x1,%ecx
f0101369:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010136c:	39 c2                	cmp    %eax,%edx
f010136e:	74 09                	je     f0101379 <strlcpy+0x32>
f0101370:	0f b6 19             	movzbl (%ecx),%ebx
f0101373:	84 db                	test   %bl,%bl
f0101375:	75 ec                	jne    f0101363 <strlcpy+0x1c>
f0101377:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101379:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010137c:	29 f0                	sub    %esi,%eax
}
f010137e:	5b                   	pop    %ebx
f010137f:	5e                   	pop    %esi
f0101380:	5d                   	pop    %ebp
f0101381:	c3                   	ret    

f0101382 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101382:	55                   	push   %ebp
f0101383:	89 e5                	mov    %esp,%ebp
f0101385:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101388:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010138b:	eb 06                	jmp    f0101393 <strcmp+0x11>
		p++, q++;
f010138d:	83 c1 01             	add    $0x1,%ecx
f0101390:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101393:	0f b6 01             	movzbl (%ecx),%eax
f0101396:	84 c0                	test   %al,%al
f0101398:	74 04                	je     f010139e <strcmp+0x1c>
f010139a:	3a 02                	cmp    (%edx),%al
f010139c:	74 ef                	je     f010138d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010139e:	0f b6 c0             	movzbl %al,%eax
f01013a1:	0f b6 12             	movzbl (%edx),%edx
f01013a4:	29 d0                	sub    %edx,%eax
}
f01013a6:	5d                   	pop    %ebp
f01013a7:	c3                   	ret    

f01013a8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013a8:	55                   	push   %ebp
f01013a9:	89 e5                	mov    %esp,%ebp
f01013ab:	53                   	push   %ebx
f01013ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01013af:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013b2:	89 c3                	mov    %eax,%ebx
f01013b4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013b7:	eb 06                	jmp    f01013bf <strncmp+0x17>
		n--, p++, q++;
f01013b9:	83 c0 01             	add    $0x1,%eax
f01013bc:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013bf:	39 d8                	cmp    %ebx,%eax
f01013c1:	74 15                	je     f01013d8 <strncmp+0x30>
f01013c3:	0f b6 08             	movzbl (%eax),%ecx
f01013c6:	84 c9                	test   %cl,%cl
f01013c8:	74 04                	je     f01013ce <strncmp+0x26>
f01013ca:	3a 0a                	cmp    (%edx),%cl
f01013cc:	74 eb                	je     f01013b9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013ce:	0f b6 00             	movzbl (%eax),%eax
f01013d1:	0f b6 12             	movzbl (%edx),%edx
f01013d4:	29 d0                	sub    %edx,%eax
f01013d6:	eb 05                	jmp    f01013dd <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013d8:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013dd:	5b                   	pop    %ebx
f01013de:	5d                   	pop    %ebp
f01013df:	c3                   	ret    

f01013e0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013e0:	55                   	push   %ebp
f01013e1:	89 e5                	mov    %esp,%ebp
f01013e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013ea:	eb 07                	jmp    f01013f3 <strchr+0x13>
		if (*s == c)
f01013ec:	38 ca                	cmp    %cl,%dl
f01013ee:	74 0f                	je     f01013ff <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013f0:	83 c0 01             	add    $0x1,%eax
f01013f3:	0f b6 10             	movzbl (%eax),%edx
f01013f6:	84 d2                	test   %dl,%dl
f01013f8:	75 f2                	jne    f01013ec <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013ff:	5d                   	pop    %ebp
f0101400:	c3                   	ret    

f0101401 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101401:	55                   	push   %ebp
f0101402:	89 e5                	mov    %esp,%ebp
f0101404:	8b 45 08             	mov    0x8(%ebp),%eax
f0101407:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010140b:	eb 03                	jmp    f0101410 <strfind+0xf>
f010140d:	83 c0 01             	add    $0x1,%eax
f0101410:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101413:	38 ca                	cmp    %cl,%dl
f0101415:	74 04                	je     f010141b <strfind+0x1a>
f0101417:	84 d2                	test   %dl,%dl
f0101419:	75 f2                	jne    f010140d <strfind+0xc>
			break;
	return (char *) s;
}
f010141b:	5d                   	pop    %ebp
f010141c:	c3                   	ret    

f010141d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010141d:	55                   	push   %ebp
f010141e:	89 e5                	mov    %esp,%ebp
f0101420:	57                   	push   %edi
f0101421:	56                   	push   %esi
f0101422:	53                   	push   %ebx
f0101423:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101426:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101429:	85 c9                	test   %ecx,%ecx
f010142b:	74 36                	je     f0101463 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010142d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101433:	75 28                	jne    f010145d <memset+0x40>
f0101435:	f6 c1 03             	test   $0x3,%cl
f0101438:	75 23                	jne    f010145d <memset+0x40>
		c &= 0xFF;
f010143a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010143e:	89 d3                	mov    %edx,%ebx
f0101440:	c1 e3 08             	shl    $0x8,%ebx
f0101443:	89 d6                	mov    %edx,%esi
f0101445:	c1 e6 18             	shl    $0x18,%esi
f0101448:	89 d0                	mov    %edx,%eax
f010144a:	c1 e0 10             	shl    $0x10,%eax
f010144d:	09 f0                	or     %esi,%eax
f010144f:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101451:	89 d8                	mov    %ebx,%eax
f0101453:	09 d0                	or     %edx,%eax
f0101455:	c1 e9 02             	shr    $0x2,%ecx
f0101458:	fc                   	cld    
f0101459:	f3 ab                	rep stos %eax,%es:(%edi)
f010145b:	eb 06                	jmp    f0101463 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010145d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101460:	fc                   	cld    
f0101461:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101463:	89 f8                	mov    %edi,%eax
f0101465:	5b                   	pop    %ebx
f0101466:	5e                   	pop    %esi
f0101467:	5f                   	pop    %edi
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    

f010146a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	57                   	push   %edi
f010146e:	56                   	push   %esi
f010146f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101472:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101475:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101478:	39 c6                	cmp    %eax,%esi
f010147a:	73 35                	jae    f01014b1 <memmove+0x47>
f010147c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010147f:	39 d0                	cmp    %edx,%eax
f0101481:	73 2e                	jae    f01014b1 <memmove+0x47>
		s += n;
		d += n;
f0101483:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101486:	89 d6                	mov    %edx,%esi
f0101488:	09 fe                	or     %edi,%esi
f010148a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101490:	75 13                	jne    f01014a5 <memmove+0x3b>
f0101492:	f6 c1 03             	test   $0x3,%cl
f0101495:	75 0e                	jne    f01014a5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101497:	83 ef 04             	sub    $0x4,%edi
f010149a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010149d:	c1 e9 02             	shr    $0x2,%ecx
f01014a0:	fd                   	std    
f01014a1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014a3:	eb 09                	jmp    f01014ae <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014a5:	83 ef 01             	sub    $0x1,%edi
f01014a8:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014ab:	fd                   	std    
f01014ac:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014ae:	fc                   	cld    
f01014af:	eb 1d                	jmp    f01014ce <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b1:	89 f2                	mov    %esi,%edx
f01014b3:	09 c2                	or     %eax,%edx
f01014b5:	f6 c2 03             	test   $0x3,%dl
f01014b8:	75 0f                	jne    f01014c9 <memmove+0x5f>
f01014ba:	f6 c1 03             	test   $0x3,%cl
f01014bd:	75 0a                	jne    f01014c9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014bf:	c1 e9 02             	shr    $0x2,%ecx
f01014c2:	89 c7                	mov    %eax,%edi
f01014c4:	fc                   	cld    
f01014c5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014c7:	eb 05                	jmp    f01014ce <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014c9:	89 c7                	mov    %eax,%edi
f01014cb:	fc                   	cld    
f01014cc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014ce:	5e                   	pop    %esi
f01014cf:	5f                   	pop    %edi
f01014d0:	5d                   	pop    %ebp
f01014d1:	c3                   	ret    

f01014d2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014d2:	55                   	push   %ebp
f01014d3:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014d5:	ff 75 10             	pushl  0x10(%ebp)
f01014d8:	ff 75 0c             	pushl  0xc(%ebp)
f01014db:	ff 75 08             	pushl  0x8(%ebp)
f01014de:	e8 87 ff ff ff       	call   f010146a <memmove>
}
f01014e3:	c9                   	leave  
f01014e4:	c3                   	ret    

f01014e5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014e5:	55                   	push   %ebp
f01014e6:	89 e5                	mov    %esp,%ebp
f01014e8:	56                   	push   %esi
f01014e9:	53                   	push   %ebx
f01014ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ed:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f0:	89 c6                	mov    %eax,%esi
f01014f2:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014f5:	eb 1a                	jmp    f0101511 <memcmp+0x2c>
		if (*s1 != *s2)
f01014f7:	0f b6 08             	movzbl (%eax),%ecx
f01014fa:	0f b6 1a             	movzbl (%edx),%ebx
f01014fd:	38 d9                	cmp    %bl,%cl
f01014ff:	74 0a                	je     f010150b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101501:	0f b6 c1             	movzbl %cl,%eax
f0101504:	0f b6 db             	movzbl %bl,%ebx
f0101507:	29 d8                	sub    %ebx,%eax
f0101509:	eb 0f                	jmp    f010151a <memcmp+0x35>
		s1++, s2++;
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101511:	39 f0                	cmp    %esi,%eax
f0101513:	75 e2                	jne    f01014f7 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101515:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010151a:	5b                   	pop    %ebx
f010151b:	5e                   	pop    %esi
f010151c:	5d                   	pop    %ebp
f010151d:	c3                   	ret    

f010151e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010151e:	55                   	push   %ebp
f010151f:	89 e5                	mov    %esp,%ebp
f0101521:	53                   	push   %ebx
f0101522:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101525:	89 c1                	mov    %eax,%ecx
f0101527:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010152a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010152e:	eb 0a                	jmp    f010153a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101530:	0f b6 10             	movzbl (%eax),%edx
f0101533:	39 da                	cmp    %ebx,%edx
f0101535:	74 07                	je     f010153e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101537:	83 c0 01             	add    $0x1,%eax
f010153a:	39 c8                	cmp    %ecx,%eax
f010153c:	72 f2                	jb     f0101530 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010153e:	5b                   	pop    %ebx
f010153f:	5d                   	pop    %ebp
f0101540:	c3                   	ret    

f0101541 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101541:	55                   	push   %ebp
f0101542:	89 e5                	mov    %esp,%ebp
f0101544:	57                   	push   %edi
f0101545:	56                   	push   %esi
f0101546:	53                   	push   %ebx
f0101547:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010154a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010154d:	eb 03                	jmp    f0101552 <strtol+0x11>
		s++;
f010154f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101552:	0f b6 01             	movzbl (%ecx),%eax
f0101555:	3c 20                	cmp    $0x20,%al
f0101557:	74 f6                	je     f010154f <strtol+0xe>
f0101559:	3c 09                	cmp    $0x9,%al
f010155b:	74 f2                	je     f010154f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010155d:	3c 2b                	cmp    $0x2b,%al
f010155f:	75 0a                	jne    f010156b <strtol+0x2a>
		s++;
f0101561:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101564:	bf 00 00 00 00       	mov    $0x0,%edi
f0101569:	eb 11                	jmp    f010157c <strtol+0x3b>
f010156b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101570:	3c 2d                	cmp    $0x2d,%al
f0101572:	75 08                	jne    f010157c <strtol+0x3b>
		s++, neg = 1;
f0101574:	83 c1 01             	add    $0x1,%ecx
f0101577:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010157c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101582:	75 15                	jne    f0101599 <strtol+0x58>
f0101584:	80 39 30             	cmpb   $0x30,(%ecx)
f0101587:	75 10                	jne    f0101599 <strtol+0x58>
f0101589:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010158d:	75 7c                	jne    f010160b <strtol+0xca>
		s += 2, base = 16;
f010158f:	83 c1 02             	add    $0x2,%ecx
f0101592:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101597:	eb 16                	jmp    f01015af <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101599:	85 db                	test   %ebx,%ebx
f010159b:	75 12                	jne    f01015af <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010159d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015a2:	80 39 30             	cmpb   $0x30,(%ecx)
f01015a5:	75 08                	jne    f01015af <strtol+0x6e>
		s++, base = 8;
f01015a7:	83 c1 01             	add    $0x1,%ecx
f01015aa:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015af:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b4:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015b7:	0f b6 11             	movzbl (%ecx),%edx
f01015ba:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015bd:	89 f3                	mov    %esi,%ebx
f01015bf:	80 fb 09             	cmp    $0x9,%bl
f01015c2:	77 08                	ja     f01015cc <strtol+0x8b>
			dig = *s - '0';
f01015c4:	0f be d2             	movsbl %dl,%edx
f01015c7:	83 ea 30             	sub    $0x30,%edx
f01015ca:	eb 22                	jmp    f01015ee <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015cc:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015cf:	89 f3                	mov    %esi,%ebx
f01015d1:	80 fb 19             	cmp    $0x19,%bl
f01015d4:	77 08                	ja     f01015de <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015d6:	0f be d2             	movsbl %dl,%edx
f01015d9:	83 ea 57             	sub    $0x57,%edx
f01015dc:	eb 10                	jmp    f01015ee <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015de:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015e1:	89 f3                	mov    %esi,%ebx
f01015e3:	80 fb 19             	cmp    $0x19,%bl
f01015e6:	77 16                	ja     f01015fe <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015e8:	0f be d2             	movsbl %dl,%edx
f01015eb:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015ee:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015f1:	7d 0b                	jge    f01015fe <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015f3:	83 c1 01             	add    $0x1,%ecx
f01015f6:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015fa:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015fc:	eb b9                	jmp    f01015b7 <strtol+0x76>

	if (endptr)
f01015fe:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101602:	74 0d                	je     f0101611 <strtol+0xd0>
		*endptr = (char *) s;
f0101604:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101607:	89 0e                	mov    %ecx,(%esi)
f0101609:	eb 06                	jmp    f0101611 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010160b:	85 db                	test   %ebx,%ebx
f010160d:	74 98                	je     f01015a7 <strtol+0x66>
f010160f:	eb 9e                	jmp    f01015af <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101611:	89 c2                	mov    %eax,%edx
f0101613:	f7 da                	neg    %edx
f0101615:	85 ff                	test   %edi,%edi
f0101617:	0f 45 c2             	cmovne %edx,%eax
}
f010161a:	5b                   	pop    %ebx
f010161b:	5e                   	pop    %esi
f010161c:	5f                   	pop    %edi
f010161d:	5d                   	pop    %ebp
f010161e:	c3                   	ret    
f010161f:	90                   	nop

f0101620 <__udivdi3>:
f0101620:	55                   	push   %ebp
f0101621:	57                   	push   %edi
f0101622:	56                   	push   %esi
f0101623:	53                   	push   %ebx
f0101624:	83 ec 1c             	sub    $0x1c,%esp
f0101627:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010162b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010162f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101633:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101637:	85 f6                	test   %esi,%esi
f0101639:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010163d:	89 ca                	mov    %ecx,%edx
f010163f:	89 f8                	mov    %edi,%eax
f0101641:	75 3d                	jne    f0101680 <__udivdi3+0x60>
f0101643:	39 cf                	cmp    %ecx,%edi
f0101645:	0f 87 c5 00 00 00    	ja     f0101710 <__udivdi3+0xf0>
f010164b:	85 ff                	test   %edi,%edi
f010164d:	89 fd                	mov    %edi,%ebp
f010164f:	75 0b                	jne    f010165c <__udivdi3+0x3c>
f0101651:	b8 01 00 00 00       	mov    $0x1,%eax
f0101656:	31 d2                	xor    %edx,%edx
f0101658:	f7 f7                	div    %edi
f010165a:	89 c5                	mov    %eax,%ebp
f010165c:	89 c8                	mov    %ecx,%eax
f010165e:	31 d2                	xor    %edx,%edx
f0101660:	f7 f5                	div    %ebp
f0101662:	89 c1                	mov    %eax,%ecx
f0101664:	89 d8                	mov    %ebx,%eax
f0101666:	89 cf                	mov    %ecx,%edi
f0101668:	f7 f5                	div    %ebp
f010166a:	89 c3                	mov    %eax,%ebx
f010166c:	89 d8                	mov    %ebx,%eax
f010166e:	89 fa                	mov    %edi,%edx
f0101670:	83 c4 1c             	add    $0x1c,%esp
f0101673:	5b                   	pop    %ebx
f0101674:	5e                   	pop    %esi
f0101675:	5f                   	pop    %edi
f0101676:	5d                   	pop    %ebp
f0101677:	c3                   	ret    
f0101678:	90                   	nop
f0101679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101680:	39 ce                	cmp    %ecx,%esi
f0101682:	77 74                	ja     f01016f8 <__udivdi3+0xd8>
f0101684:	0f bd fe             	bsr    %esi,%edi
f0101687:	83 f7 1f             	xor    $0x1f,%edi
f010168a:	0f 84 98 00 00 00    	je     f0101728 <__udivdi3+0x108>
f0101690:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101695:	89 f9                	mov    %edi,%ecx
f0101697:	89 c5                	mov    %eax,%ebp
f0101699:	29 fb                	sub    %edi,%ebx
f010169b:	d3 e6                	shl    %cl,%esi
f010169d:	89 d9                	mov    %ebx,%ecx
f010169f:	d3 ed                	shr    %cl,%ebp
f01016a1:	89 f9                	mov    %edi,%ecx
f01016a3:	d3 e0                	shl    %cl,%eax
f01016a5:	09 ee                	or     %ebp,%esi
f01016a7:	89 d9                	mov    %ebx,%ecx
f01016a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016ad:	89 d5                	mov    %edx,%ebp
f01016af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016b3:	d3 ed                	shr    %cl,%ebp
f01016b5:	89 f9                	mov    %edi,%ecx
f01016b7:	d3 e2                	shl    %cl,%edx
f01016b9:	89 d9                	mov    %ebx,%ecx
f01016bb:	d3 e8                	shr    %cl,%eax
f01016bd:	09 c2                	or     %eax,%edx
f01016bf:	89 d0                	mov    %edx,%eax
f01016c1:	89 ea                	mov    %ebp,%edx
f01016c3:	f7 f6                	div    %esi
f01016c5:	89 d5                	mov    %edx,%ebp
f01016c7:	89 c3                	mov    %eax,%ebx
f01016c9:	f7 64 24 0c          	mull   0xc(%esp)
f01016cd:	39 d5                	cmp    %edx,%ebp
f01016cf:	72 10                	jb     f01016e1 <__udivdi3+0xc1>
f01016d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016d5:	89 f9                	mov    %edi,%ecx
f01016d7:	d3 e6                	shl    %cl,%esi
f01016d9:	39 c6                	cmp    %eax,%esi
f01016db:	73 07                	jae    f01016e4 <__udivdi3+0xc4>
f01016dd:	39 d5                	cmp    %edx,%ebp
f01016df:	75 03                	jne    f01016e4 <__udivdi3+0xc4>
f01016e1:	83 eb 01             	sub    $0x1,%ebx
f01016e4:	31 ff                	xor    %edi,%edi
f01016e6:	89 d8                	mov    %ebx,%eax
f01016e8:	89 fa                	mov    %edi,%edx
f01016ea:	83 c4 1c             	add    $0x1c,%esp
f01016ed:	5b                   	pop    %ebx
f01016ee:	5e                   	pop    %esi
f01016ef:	5f                   	pop    %edi
f01016f0:	5d                   	pop    %ebp
f01016f1:	c3                   	ret    
f01016f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016f8:	31 ff                	xor    %edi,%edi
f01016fa:	31 db                	xor    %ebx,%ebx
f01016fc:	89 d8                	mov    %ebx,%eax
f01016fe:	89 fa                	mov    %edi,%edx
f0101700:	83 c4 1c             	add    $0x1c,%esp
f0101703:	5b                   	pop    %ebx
f0101704:	5e                   	pop    %esi
f0101705:	5f                   	pop    %edi
f0101706:	5d                   	pop    %ebp
f0101707:	c3                   	ret    
f0101708:	90                   	nop
f0101709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101710:	89 d8                	mov    %ebx,%eax
f0101712:	f7 f7                	div    %edi
f0101714:	31 ff                	xor    %edi,%edi
f0101716:	89 c3                	mov    %eax,%ebx
f0101718:	89 d8                	mov    %ebx,%eax
f010171a:	89 fa                	mov    %edi,%edx
f010171c:	83 c4 1c             	add    $0x1c,%esp
f010171f:	5b                   	pop    %ebx
f0101720:	5e                   	pop    %esi
f0101721:	5f                   	pop    %edi
f0101722:	5d                   	pop    %ebp
f0101723:	c3                   	ret    
f0101724:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101728:	39 ce                	cmp    %ecx,%esi
f010172a:	72 0c                	jb     f0101738 <__udivdi3+0x118>
f010172c:	31 db                	xor    %ebx,%ebx
f010172e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101732:	0f 87 34 ff ff ff    	ja     f010166c <__udivdi3+0x4c>
f0101738:	bb 01 00 00 00       	mov    $0x1,%ebx
f010173d:	e9 2a ff ff ff       	jmp    f010166c <__udivdi3+0x4c>
f0101742:	66 90                	xchg   %ax,%ax
f0101744:	66 90                	xchg   %ax,%ax
f0101746:	66 90                	xchg   %ax,%ax
f0101748:	66 90                	xchg   %ax,%ax
f010174a:	66 90                	xchg   %ax,%ax
f010174c:	66 90                	xchg   %ax,%ax
f010174e:	66 90                	xchg   %ax,%ax

f0101750 <__umoddi3>:
f0101750:	55                   	push   %ebp
f0101751:	57                   	push   %edi
f0101752:	56                   	push   %esi
f0101753:	53                   	push   %ebx
f0101754:	83 ec 1c             	sub    $0x1c,%esp
f0101757:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010175b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010175f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101763:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101767:	85 d2                	test   %edx,%edx
f0101769:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010176d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101771:	89 f3                	mov    %esi,%ebx
f0101773:	89 3c 24             	mov    %edi,(%esp)
f0101776:	89 74 24 04          	mov    %esi,0x4(%esp)
f010177a:	75 1c                	jne    f0101798 <__umoddi3+0x48>
f010177c:	39 f7                	cmp    %esi,%edi
f010177e:	76 50                	jbe    f01017d0 <__umoddi3+0x80>
f0101780:	89 c8                	mov    %ecx,%eax
f0101782:	89 f2                	mov    %esi,%edx
f0101784:	f7 f7                	div    %edi
f0101786:	89 d0                	mov    %edx,%eax
f0101788:	31 d2                	xor    %edx,%edx
f010178a:	83 c4 1c             	add    $0x1c,%esp
f010178d:	5b                   	pop    %ebx
f010178e:	5e                   	pop    %esi
f010178f:	5f                   	pop    %edi
f0101790:	5d                   	pop    %ebp
f0101791:	c3                   	ret    
f0101792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101798:	39 f2                	cmp    %esi,%edx
f010179a:	89 d0                	mov    %edx,%eax
f010179c:	77 52                	ja     f01017f0 <__umoddi3+0xa0>
f010179e:	0f bd ea             	bsr    %edx,%ebp
f01017a1:	83 f5 1f             	xor    $0x1f,%ebp
f01017a4:	75 5a                	jne    f0101800 <__umoddi3+0xb0>
f01017a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017aa:	0f 82 e0 00 00 00    	jb     f0101890 <__umoddi3+0x140>
f01017b0:	39 0c 24             	cmp    %ecx,(%esp)
f01017b3:	0f 86 d7 00 00 00    	jbe    f0101890 <__umoddi3+0x140>
f01017b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017c1:	83 c4 1c             	add    $0x1c,%esp
f01017c4:	5b                   	pop    %ebx
f01017c5:	5e                   	pop    %esi
f01017c6:	5f                   	pop    %edi
f01017c7:	5d                   	pop    %ebp
f01017c8:	c3                   	ret    
f01017c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017d0:	85 ff                	test   %edi,%edi
f01017d2:	89 fd                	mov    %edi,%ebp
f01017d4:	75 0b                	jne    f01017e1 <__umoddi3+0x91>
f01017d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017db:	31 d2                	xor    %edx,%edx
f01017dd:	f7 f7                	div    %edi
f01017df:	89 c5                	mov    %eax,%ebp
f01017e1:	89 f0                	mov    %esi,%eax
f01017e3:	31 d2                	xor    %edx,%edx
f01017e5:	f7 f5                	div    %ebp
f01017e7:	89 c8                	mov    %ecx,%eax
f01017e9:	f7 f5                	div    %ebp
f01017eb:	89 d0                	mov    %edx,%eax
f01017ed:	eb 99                	jmp    f0101788 <__umoddi3+0x38>
f01017ef:	90                   	nop
f01017f0:	89 c8                	mov    %ecx,%eax
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	83 c4 1c             	add    $0x1c,%esp
f01017f7:	5b                   	pop    %ebx
f01017f8:	5e                   	pop    %esi
f01017f9:	5f                   	pop    %edi
f01017fa:	5d                   	pop    %ebp
f01017fb:	c3                   	ret    
f01017fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101800:	8b 34 24             	mov    (%esp),%esi
f0101803:	bf 20 00 00 00       	mov    $0x20,%edi
f0101808:	89 e9                	mov    %ebp,%ecx
f010180a:	29 ef                	sub    %ebp,%edi
f010180c:	d3 e0                	shl    %cl,%eax
f010180e:	89 f9                	mov    %edi,%ecx
f0101810:	89 f2                	mov    %esi,%edx
f0101812:	d3 ea                	shr    %cl,%edx
f0101814:	89 e9                	mov    %ebp,%ecx
f0101816:	09 c2                	or     %eax,%edx
f0101818:	89 d8                	mov    %ebx,%eax
f010181a:	89 14 24             	mov    %edx,(%esp)
f010181d:	89 f2                	mov    %esi,%edx
f010181f:	d3 e2                	shl    %cl,%edx
f0101821:	89 f9                	mov    %edi,%ecx
f0101823:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101827:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010182b:	d3 e8                	shr    %cl,%eax
f010182d:	89 e9                	mov    %ebp,%ecx
f010182f:	89 c6                	mov    %eax,%esi
f0101831:	d3 e3                	shl    %cl,%ebx
f0101833:	89 f9                	mov    %edi,%ecx
f0101835:	89 d0                	mov    %edx,%eax
f0101837:	d3 e8                	shr    %cl,%eax
f0101839:	89 e9                	mov    %ebp,%ecx
f010183b:	09 d8                	or     %ebx,%eax
f010183d:	89 d3                	mov    %edx,%ebx
f010183f:	89 f2                	mov    %esi,%edx
f0101841:	f7 34 24             	divl   (%esp)
f0101844:	89 d6                	mov    %edx,%esi
f0101846:	d3 e3                	shl    %cl,%ebx
f0101848:	f7 64 24 04          	mull   0x4(%esp)
f010184c:	39 d6                	cmp    %edx,%esi
f010184e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101852:	89 d1                	mov    %edx,%ecx
f0101854:	89 c3                	mov    %eax,%ebx
f0101856:	72 08                	jb     f0101860 <__umoddi3+0x110>
f0101858:	75 11                	jne    f010186b <__umoddi3+0x11b>
f010185a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010185e:	73 0b                	jae    f010186b <__umoddi3+0x11b>
f0101860:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101864:	1b 14 24             	sbb    (%esp),%edx
f0101867:	89 d1                	mov    %edx,%ecx
f0101869:	89 c3                	mov    %eax,%ebx
f010186b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010186f:	29 da                	sub    %ebx,%edx
f0101871:	19 ce                	sbb    %ecx,%esi
f0101873:	89 f9                	mov    %edi,%ecx
f0101875:	89 f0                	mov    %esi,%eax
f0101877:	d3 e0                	shl    %cl,%eax
f0101879:	89 e9                	mov    %ebp,%ecx
f010187b:	d3 ea                	shr    %cl,%edx
f010187d:	89 e9                	mov    %ebp,%ecx
f010187f:	d3 ee                	shr    %cl,%esi
f0101881:	09 d0                	or     %edx,%eax
f0101883:	89 f2                	mov    %esi,%edx
f0101885:	83 c4 1c             	add    $0x1c,%esp
f0101888:	5b                   	pop    %ebx
f0101889:	5e                   	pop    %esi
f010188a:	5f                   	pop    %edi
f010188b:	5d                   	pop    %ebp
f010188c:	c3                   	ret    
f010188d:	8d 76 00             	lea    0x0(%esi),%esi
f0101890:	29 f9                	sub    %edi,%ecx
f0101892:	19 d6                	sbb    %edx,%esi
f0101894:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101898:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010189c:	e9 18 ff ff ff       	jmp    f01017b9 <__umoddi3+0x69>
