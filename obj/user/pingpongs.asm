
obj/user/pingpongs:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 cd 00 00 00       	call   8000fe <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t val;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 2c             	sub    $0x2c,%esp
	envid_t who;
	uint32_t i;

	i = 0;
	if ((who = sfork()) != 0) {
  80003c:	e8 c6 0f 00 00       	call   801007 <sfork>
  800041:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800044:	85 c0                	test   %eax,%eax
  800046:	74 42                	je     80008a <umain+0x57>
		cprintf("i am %08x; thisenv is %p\n", sys_getenvid(), thisenv);
  800048:	8b 1d 08 20 80 00    	mov    0x802008,%ebx
  80004e:	e8 5f 0b 00 00       	call   800bb2 <sys_getenvid>
  800053:	83 ec 04             	sub    $0x4,%esp
  800056:	53                   	push   %ebx
  800057:	50                   	push   %eax
  800058:	68 80 14 80 00       	push   $0x801480
  80005d:	e8 87 01 00 00       	call   8001e9 <cprintf>
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  800062:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800065:	e8 48 0b 00 00       	call   800bb2 <sys_getenvid>
  80006a:	83 c4 0c             	add    $0xc,%esp
  80006d:	53                   	push   %ebx
  80006e:	50                   	push   %eax
  80006f:	68 9a 14 80 00       	push   $0x80149a
  800074:	e8 70 01 00 00       	call   8001e9 <cprintf>
		ipc_send(who, 0, 0, 0);
  800079:	6a 00                	push   $0x0
  80007b:	6a 00                	push   $0x0
  80007d:	6a 00                	push   $0x0
  80007f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800082:	e8 03 10 00 00       	call   80108a <ipc_send>
  800087:	83 c4 20             	add    $0x20,%esp
	}

	while (1) {
		ipc_recv(&who, 0, 0);
  80008a:	83 ec 04             	sub    $0x4,%esp
  80008d:	6a 00                	push   $0x0
  80008f:	6a 00                	push   $0x0
  800091:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  800094:	50                   	push   %eax
  800095:	e8 87 0f 00 00       	call   801021 <ipc_recv>
		cprintf("%x got %d from %x (thisenv is %p %x)\n", sys_getenvid(), val, who, thisenv, thisenv->env_id);
  80009a:	8b 1d 08 20 80 00    	mov    0x802008,%ebx
  8000a0:	8b 7b 48             	mov    0x48(%ebx),%edi
  8000a3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8000a6:	a1 04 20 80 00       	mov    0x802004,%eax
  8000ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8000ae:	e8 ff 0a 00 00       	call   800bb2 <sys_getenvid>
  8000b3:	83 c4 08             	add    $0x8,%esp
  8000b6:	57                   	push   %edi
  8000b7:	53                   	push   %ebx
  8000b8:	56                   	push   %esi
  8000b9:	ff 75 d4             	pushl  -0x2c(%ebp)
  8000bc:	50                   	push   %eax
  8000bd:	68 b0 14 80 00       	push   $0x8014b0
  8000c2:	e8 22 01 00 00       	call   8001e9 <cprintf>
		if (val == 10)
  8000c7:	a1 04 20 80 00       	mov    0x802004,%eax
  8000cc:	83 c4 20             	add    $0x20,%esp
  8000cf:	83 f8 0a             	cmp    $0xa,%eax
  8000d2:	74 22                	je     8000f6 <umain+0xc3>
			return;
		++val;
  8000d4:	83 c0 01             	add    $0x1,%eax
  8000d7:	a3 04 20 80 00       	mov    %eax,0x802004
		ipc_send(who, 0, 0, 0);
  8000dc:	6a 00                	push   $0x0
  8000de:	6a 00                	push   $0x0
  8000e0:	6a 00                	push   $0x0
  8000e2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8000e5:	e8 a0 0f 00 00       	call   80108a <ipc_send>
		if (val == 10)
  8000ea:	83 c4 10             	add    $0x10,%esp
  8000ed:	83 3d 04 20 80 00 0a 	cmpl   $0xa,0x802004
  8000f4:	75 94                	jne    80008a <umain+0x57>
			return;
	}

}
  8000f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000f9:	5b                   	pop    %ebx
  8000fa:	5e                   	pop    %esi
  8000fb:	5f                   	pop    %edi
  8000fc:	5d                   	pop    %ebp
  8000fd:	c3                   	ret    

008000fe <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	56                   	push   %esi
  800102:	53                   	push   %ebx
  800103:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800106:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  800109:	e8 a4 0a 00 00       	call   800bb2 <sys_getenvid>
  80010e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800113:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800116:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80011b:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800120:	85 db                	test   %ebx,%ebx
  800122:	7e 07                	jle    80012b <libmain+0x2d>
		binaryname = argv[0];
  800124:	8b 06                	mov    (%esi),%eax
  800126:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80012b:	83 ec 08             	sub    $0x8,%esp
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
  800130:	e8 fe fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800135:	e8 0a 00 00 00       	call   800144 <exit>
}
  80013a:	83 c4 10             	add    $0x10,%esp
  80013d:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800140:	5b                   	pop    %ebx
  800141:	5e                   	pop    %esi
  800142:	5d                   	pop    %ebp
  800143:	c3                   	ret    

00800144 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800144:	55                   	push   %ebp
  800145:	89 e5                	mov    %esp,%ebp
  800147:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80014a:	6a 00                	push   $0x0
  80014c:	e8 20 0a 00 00       	call   800b71 <sys_env_destroy>
}
  800151:	83 c4 10             	add    $0x10,%esp
  800154:	c9                   	leave  
  800155:	c3                   	ret    

00800156 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800156:	55                   	push   %ebp
  800157:	89 e5                	mov    %esp,%ebp
  800159:	53                   	push   %ebx
  80015a:	83 ec 04             	sub    $0x4,%esp
  80015d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800160:	8b 13                	mov    (%ebx),%edx
  800162:	8d 42 01             	lea    0x1(%edx),%eax
  800165:	89 03                	mov    %eax,(%ebx)
  800167:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80016a:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80016e:	3d ff 00 00 00       	cmp    $0xff,%eax
  800173:	75 1a                	jne    80018f <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800175:	83 ec 08             	sub    $0x8,%esp
  800178:	68 ff 00 00 00       	push   $0xff
  80017d:	8d 43 08             	lea    0x8(%ebx),%eax
  800180:	50                   	push   %eax
  800181:	e8 ae 09 00 00       	call   800b34 <sys_cputs>
		b->idx = 0;
  800186:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80018c:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80018f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800193:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800196:	c9                   	leave  
  800197:	c3                   	ret    

00800198 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800198:	55                   	push   %ebp
  800199:	89 e5                	mov    %esp,%ebp
  80019b:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001a1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001a8:	00 00 00 
	b.cnt = 0;
  8001ab:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001b2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001b5:	ff 75 0c             	pushl  0xc(%ebp)
  8001b8:	ff 75 08             	pushl  0x8(%ebp)
  8001bb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001c1:	50                   	push   %eax
  8001c2:	68 56 01 80 00       	push   $0x800156
  8001c7:	e8 1a 01 00 00       	call   8002e6 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001cc:	83 c4 08             	add    $0x8,%esp
  8001cf:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001d5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001db:	50                   	push   %eax
  8001dc:	e8 53 09 00 00       	call   800b34 <sys_cputs>

	return b.cnt;
}
  8001e1:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001e7:	c9                   	leave  
  8001e8:	c3                   	ret    

008001e9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001e9:	55                   	push   %ebp
  8001ea:	89 e5                	mov    %esp,%ebp
  8001ec:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001ef:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001f2:	50                   	push   %eax
  8001f3:	ff 75 08             	pushl  0x8(%ebp)
  8001f6:	e8 9d ff ff ff       	call   800198 <vcprintf>
	va_end(ap);

	return cnt;
}
  8001fb:	c9                   	leave  
  8001fc:	c3                   	ret    

008001fd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001fd:	55                   	push   %ebp
  8001fe:	89 e5                	mov    %esp,%ebp
  800200:	57                   	push   %edi
  800201:	56                   	push   %esi
  800202:	53                   	push   %ebx
  800203:	83 ec 1c             	sub    $0x1c,%esp
  800206:	89 c7                	mov    %eax,%edi
  800208:	89 d6                	mov    %edx,%esi
  80020a:	8b 45 08             	mov    0x8(%ebp),%eax
  80020d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800210:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800213:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800216:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800219:	bb 00 00 00 00       	mov    $0x0,%ebx
  80021e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800221:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800224:	39 d3                	cmp    %edx,%ebx
  800226:	72 05                	jb     80022d <printnum+0x30>
  800228:	39 45 10             	cmp    %eax,0x10(%ebp)
  80022b:	77 45                	ja     800272 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80022d:	83 ec 0c             	sub    $0xc,%esp
  800230:	ff 75 18             	pushl  0x18(%ebp)
  800233:	8b 45 14             	mov    0x14(%ebp),%eax
  800236:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800239:	53                   	push   %ebx
  80023a:	ff 75 10             	pushl  0x10(%ebp)
  80023d:	83 ec 08             	sub    $0x8,%esp
  800240:	ff 75 e4             	pushl  -0x1c(%ebp)
  800243:	ff 75 e0             	pushl  -0x20(%ebp)
  800246:	ff 75 dc             	pushl  -0x24(%ebp)
  800249:	ff 75 d8             	pushl  -0x28(%ebp)
  80024c:	e8 9f 0f 00 00       	call   8011f0 <__udivdi3>
  800251:	83 c4 18             	add    $0x18,%esp
  800254:	52                   	push   %edx
  800255:	50                   	push   %eax
  800256:	89 f2                	mov    %esi,%edx
  800258:	89 f8                	mov    %edi,%eax
  80025a:	e8 9e ff ff ff       	call   8001fd <printnum>
  80025f:	83 c4 20             	add    $0x20,%esp
  800262:	eb 18                	jmp    80027c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800264:	83 ec 08             	sub    $0x8,%esp
  800267:	56                   	push   %esi
  800268:	ff 75 18             	pushl  0x18(%ebp)
  80026b:	ff d7                	call   *%edi
  80026d:	83 c4 10             	add    $0x10,%esp
  800270:	eb 03                	jmp    800275 <printnum+0x78>
  800272:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800275:	83 eb 01             	sub    $0x1,%ebx
  800278:	85 db                	test   %ebx,%ebx
  80027a:	7f e8                	jg     800264 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80027c:	83 ec 08             	sub    $0x8,%esp
  80027f:	56                   	push   %esi
  800280:	83 ec 04             	sub    $0x4,%esp
  800283:	ff 75 e4             	pushl  -0x1c(%ebp)
  800286:	ff 75 e0             	pushl  -0x20(%ebp)
  800289:	ff 75 dc             	pushl  -0x24(%ebp)
  80028c:	ff 75 d8             	pushl  -0x28(%ebp)
  80028f:	e8 8c 10 00 00       	call   801320 <__umoddi3>
  800294:	83 c4 14             	add    $0x14,%esp
  800297:	0f be 80 e0 14 80 00 	movsbl 0x8014e0(%eax),%eax
  80029e:	50                   	push   %eax
  80029f:	ff d7                	call   *%edi
}
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002a7:	5b                   	pop    %ebx
  8002a8:	5e                   	pop    %esi
  8002a9:	5f                   	pop    %edi
  8002aa:	5d                   	pop    %ebp
  8002ab:	c3                   	ret    

008002ac <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002ac:	55                   	push   %ebp
  8002ad:	89 e5                	mov    %esp,%ebp
  8002af:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002b2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b6:	8b 10                	mov    (%eax),%edx
  8002b8:	3b 50 04             	cmp    0x4(%eax),%edx
  8002bb:	73 0a                	jae    8002c7 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002bd:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002c0:	89 08                	mov    %ecx,(%eax)
  8002c2:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c5:	88 02                	mov    %al,(%edx)
}
  8002c7:	5d                   	pop    %ebp
  8002c8:	c3                   	ret    

008002c9 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002c9:	55                   	push   %ebp
  8002ca:	89 e5                	mov    %esp,%ebp
  8002cc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002cf:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002d2:	50                   	push   %eax
  8002d3:	ff 75 10             	pushl  0x10(%ebp)
  8002d6:	ff 75 0c             	pushl  0xc(%ebp)
  8002d9:	ff 75 08             	pushl  0x8(%ebp)
  8002dc:	e8 05 00 00 00       	call   8002e6 <vprintfmt>
	va_end(ap);
}
  8002e1:	83 c4 10             	add    $0x10,%esp
  8002e4:	c9                   	leave  
  8002e5:	c3                   	ret    

008002e6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002e6:	55                   	push   %ebp
  8002e7:	89 e5                	mov    %esp,%ebp
  8002e9:	57                   	push   %edi
  8002ea:	56                   	push   %esi
  8002eb:	53                   	push   %ebx
  8002ec:	83 ec 2c             	sub    $0x2c,%esp
  8002ef:	8b 75 08             	mov    0x8(%ebp),%esi
  8002f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002f5:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002f8:	eb 12                	jmp    80030c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002fa:	85 c0                	test   %eax,%eax
  8002fc:	0f 84 42 04 00 00    	je     800744 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800302:	83 ec 08             	sub    $0x8,%esp
  800305:	53                   	push   %ebx
  800306:	50                   	push   %eax
  800307:	ff d6                	call   *%esi
  800309:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80030c:	83 c7 01             	add    $0x1,%edi
  80030f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800313:	83 f8 25             	cmp    $0x25,%eax
  800316:	75 e2                	jne    8002fa <vprintfmt+0x14>
  800318:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80031c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800323:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80032a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800331:	b9 00 00 00 00       	mov    $0x0,%ecx
  800336:	eb 07                	jmp    80033f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800338:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80033b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033f:	8d 47 01             	lea    0x1(%edi),%eax
  800342:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800345:	0f b6 07             	movzbl (%edi),%eax
  800348:	0f b6 d0             	movzbl %al,%edx
  80034b:	83 e8 23             	sub    $0x23,%eax
  80034e:	3c 55                	cmp    $0x55,%al
  800350:	0f 87 d3 03 00 00    	ja     800729 <vprintfmt+0x443>
  800356:	0f b6 c0             	movzbl %al,%eax
  800359:	ff 24 85 a0 15 80 00 	jmp    *0x8015a0(,%eax,4)
  800360:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800363:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800367:	eb d6                	jmp    80033f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800369:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80036c:	b8 00 00 00 00       	mov    $0x0,%eax
  800371:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800374:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800377:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80037b:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80037e:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800381:	83 f9 09             	cmp    $0x9,%ecx
  800384:	77 3f                	ja     8003c5 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800386:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800389:	eb e9                	jmp    800374 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80038b:	8b 45 14             	mov    0x14(%ebp),%eax
  80038e:	8b 00                	mov    (%eax),%eax
  800390:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800393:	8b 45 14             	mov    0x14(%ebp),%eax
  800396:	8d 40 04             	lea    0x4(%eax),%eax
  800399:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80039f:	eb 2a                	jmp    8003cb <vprintfmt+0xe5>
  8003a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003a4:	85 c0                	test   %eax,%eax
  8003a6:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ab:	0f 49 d0             	cmovns %eax,%edx
  8003ae:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003b4:	eb 89                	jmp    80033f <vprintfmt+0x59>
  8003b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003b9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003c0:	e9 7a ff ff ff       	jmp    80033f <vprintfmt+0x59>
  8003c5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003c8:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003cb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003cf:	0f 89 6a ff ff ff    	jns    80033f <vprintfmt+0x59>
				width = precision, precision = -1;
  8003d5:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003d8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003db:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003e2:	e9 58 ff ff ff       	jmp    80033f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003e7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003ed:	e9 4d ff ff ff       	jmp    80033f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f5:	8d 78 04             	lea    0x4(%eax),%edi
  8003f8:	83 ec 08             	sub    $0x8,%esp
  8003fb:	53                   	push   %ebx
  8003fc:	ff 30                	pushl  (%eax)
  8003fe:	ff d6                	call   *%esi
			break;
  800400:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800403:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800406:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800409:	e9 fe fe ff ff       	jmp    80030c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80040e:	8b 45 14             	mov    0x14(%ebp),%eax
  800411:	8d 78 04             	lea    0x4(%eax),%edi
  800414:	8b 00                	mov    (%eax),%eax
  800416:	99                   	cltd   
  800417:	31 d0                	xor    %edx,%eax
  800419:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80041b:	83 f8 08             	cmp    $0x8,%eax
  80041e:	7f 0b                	jg     80042b <vprintfmt+0x145>
  800420:	8b 14 85 00 17 80 00 	mov    0x801700(,%eax,4),%edx
  800427:	85 d2                	test   %edx,%edx
  800429:	75 1b                	jne    800446 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80042b:	50                   	push   %eax
  80042c:	68 f8 14 80 00       	push   $0x8014f8
  800431:	53                   	push   %ebx
  800432:	56                   	push   %esi
  800433:	e8 91 fe ff ff       	call   8002c9 <printfmt>
  800438:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80043b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800441:	e9 c6 fe ff ff       	jmp    80030c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800446:	52                   	push   %edx
  800447:	68 01 15 80 00       	push   $0x801501
  80044c:	53                   	push   %ebx
  80044d:	56                   	push   %esi
  80044e:	e8 76 fe ff ff       	call   8002c9 <printfmt>
  800453:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800456:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800459:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80045c:	e9 ab fe ff ff       	jmp    80030c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800461:	8b 45 14             	mov    0x14(%ebp),%eax
  800464:	83 c0 04             	add    $0x4,%eax
  800467:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80046a:	8b 45 14             	mov    0x14(%ebp),%eax
  80046d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80046f:	85 ff                	test   %edi,%edi
  800471:	b8 f1 14 80 00       	mov    $0x8014f1,%eax
  800476:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800479:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80047d:	0f 8e 94 00 00 00    	jle    800517 <vprintfmt+0x231>
  800483:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800487:	0f 84 98 00 00 00    	je     800525 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80048d:	83 ec 08             	sub    $0x8,%esp
  800490:	ff 75 d0             	pushl  -0x30(%ebp)
  800493:	57                   	push   %edi
  800494:	e8 33 03 00 00       	call   8007cc <strnlen>
  800499:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80049c:	29 c1                	sub    %eax,%ecx
  80049e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004a1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004a4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ab:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ae:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b0:	eb 0f                	jmp    8004c1 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004b2:	83 ec 08             	sub    $0x8,%esp
  8004b5:	53                   	push   %ebx
  8004b6:	ff 75 e0             	pushl  -0x20(%ebp)
  8004b9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bb:	83 ef 01             	sub    $0x1,%edi
  8004be:	83 c4 10             	add    $0x10,%esp
  8004c1:	85 ff                	test   %edi,%edi
  8004c3:	7f ed                	jg     8004b2 <vprintfmt+0x1cc>
  8004c5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004c8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004cb:	85 c9                	test   %ecx,%ecx
  8004cd:	b8 00 00 00 00       	mov    $0x0,%eax
  8004d2:	0f 49 c1             	cmovns %ecx,%eax
  8004d5:	29 c1                	sub    %eax,%ecx
  8004d7:	89 75 08             	mov    %esi,0x8(%ebp)
  8004da:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e0:	89 cb                	mov    %ecx,%ebx
  8004e2:	eb 4d                	jmp    800531 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004e4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004e8:	74 1b                	je     800505 <vprintfmt+0x21f>
  8004ea:	0f be c0             	movsbl %al,%eax
  8004ed:	83 e8 20             	sub    $0x20,%eax
  8004f0:	83 f8 5e             	cmp    $0x5e,%eax
  8004f3:	76 10                	jbe    800505 <vprintfmt+0x21f>
					putch('?', putdat);
  8004f5:	83 ec 08             	sub    $0x8,%esp
  8004f8:	ff 75 0c             	pushl  0xc(%ebp)
  8004fb:	6a 3f                	push   $0x3f
  8004fd:	ff 55 08             	call   *0x8(%ebp)
  800500:	83 c4 10             	add    $0x10,%esp
  800503:	eb 0d                	jmp    800512 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800505:	83 ec 08             	sub    $0x8,%esp
  800508:	ff 75 0c             	pushl  0xc(%ebp)
  80050b:	52                   	push   %edx
  80050c:	ff 55 08             	call   *0x8(%ebp)
  80050f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800512:	83 eb 01             	sub    $0x1,%ebx
  800515:	eb 1a                	jmp    800531 <vprintfmt+0x24b>
  800517:	89 75 08             	mov    %esi,0x8(%ebp)
  80051a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80051d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800520:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800523:	eb 0c                	jmp    800531 <vprintfmt+0x24b>
  800525:	89 75 08             	mov    %esi,0x8(%ebp)
  800528:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800531:	83 c7 01             	add    $0x1,%edi
  800534:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800538:	0f be d0             	movsbl %al,%edx
  80053b:	85 d2                	test   %edx,%edx
  80053d:	74 23                	je     800562 <vprintfmt+0x27c>
  80053f:	85 f6                	test   %esi,%esi
  800541:	78 a1                	js     8004e4 <vprintfmt+0x1fe>
  800543:	83 ee 01             	sub    $0x1,%esi
  800546:	79 9c                	jns    8004e4 <vprintfmt+0x1fe>
  800548:	89 df                	mov    %ebx,%edi
  80054a:	8b 75 08             	mov    0x8(%ebp),%esi
  80054d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800550:	eb 18                	jmp    80056a <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800552:	83 ec 08             	sub    $0x8,%esp
  800555:	53                   	push   %ebx
  800556:	6a 20                	push   $0x20
  800558:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80055a:	83 ef 01             	sub    $0x1,%edi
  80055d:	83 c4 10             	add    $0x10,%esp
  800560:	eb 08                	jmp    80056a <vprintfmt+0x284>
  800562:	89 df                	mov    %ebx,%edi
  800564:	8b 75 08             	mov    0x8(%ebp),%esi
  800567:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80056a:	85 ff                	test   %edi,%edi
  80056c:	7f e4                	jg     800552 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80056e:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800571:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800574:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800577:	e9 90 fd ff ff       	jmp    80030c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80057c:	83 f9 01             	cmp    $0x1,%ecx
  80057f:	7e 19                	jle    80059a <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800581:	8b 45 14             	mov    0x14(%ebp),%eax
  800584:	8b 50 04             	mov    0x4(%eax),%edx
  800587:	8b 00                	mov    (%eax),%eax
  800589:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80058c:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80058f:	8b 45 14             	mov    0x14(%ebp),%eax
  800592:	8d 40 08             	lea    0x8(%eax),%eax
  800595:	89 45 14             	mov    %eax,0x14(%ebp)
  800598:	eb 38                	jmp    8005d2 <vprintfmt+0x2ec>
	else if (lflag)
  80059a:	85 c9                	test   %ecx,%ecx
  80059c:	74 1b                	je     8005b9 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  80059e:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a1:	8b 00                	mov    (%eax),%eax
  8005a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a6:	89 c1                	mov    %eax,%ecx
  8005a8:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ab:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b1:	8d 40 04             	lea    0x4(%eax),%eax
  8005b4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005b7:	eb 19                	jmp    8005d2 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bc:	8b 00                	mov    (%eax),%eax
  8005be:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c1:	89 c1                	mov    %eax,%ecx
  8005c3:	c1 f9 1f             	sar    $0x1f,%ecx
  8005c6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cc:	8d 40 04             	lea    0x4(%eax),%eax
  8005cf:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005d2:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005d5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005d8:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005dd:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005e1:	0f 89 0e 01 00 00    	jns    8006f5 <vprintfmt+0x40f>
				putch('-', putdat);
  8005e7:	83 ec 08             	sub    $0x8,%esp
  8005ea:	53                   	push   %ebx
  8005eb:	6a 2d                	push   $0x2d
  8005ed:	ff d6                	call   *%esi
				num = -(long long) num;
  8005ef:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005f5:	f7 da                	neg    %edx
  8005f7:	83 d1 00             	adc    $0x0,%ecx
  8005fa:	f7 d9                	neg    %ecx
  8005fc:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8005ff:	b8 0a 00 00 00       	mov    $0xa,%eax
  800604:	e9 ec 00 00 00       	jmp    8006f5 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800609:	83 f9 01             	cmp    $0x1,%ecx
  80060c:	7e 18                	jle    800626 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80060e:	8b 45 14             	mov    0x14(%ebp),%eax
  800611:	8b 10                	mov    (%eax),%edx
  800613:	8b 48 04             	mov    0x4(%eax),%ecx
  800616:	8d 40 08             	lea    0x8(%eax),%eax
  800619:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80061c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800621:	e9 cf 00 00 00       	jmp    8006f5 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800626:	85 c9                	test   %ecx,%ecx
  800628:	74 1a                	je     800644 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80062a:	8b 45 14             	mov    0x14(%ebp),%eax
  80062d:	8b 10                	mov    (%eax),%edx
  80062f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800634:	8d 40 04             	lea    0x4(%eax),%eax
  800637:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80063a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063f:	e9 b1 00 00 00       	jmp    8006f5 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8b 10                	mov    (%eax),%edx
  800649:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064e:	8d 40 04             	lea    0x4(%eax),%eax
  800651:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800654:	b8 0a 00 00 00       	mov    $0xa,%eax
  800659:	e9 97 00 00 00       	jmp    8006f5 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80065e:	83 ec 08             	sub    $0x8,%esp
  800661:	53                   	push   %ebx
  800662:	6a 58                	push   $0x58
  800664:	ff d6                	call   *%esi
			putch('X', putdat);
  800666:	83 c4 08             	add    $0x8,%esp
  800669:	53                   	push   %ebx
  80066a:	6a 58                	push   $0x58
  80066c:	ff d6                	call   *%esi
			putch('X', putdat);
  80066e:	83 c4 08             	add    $0x8,%esp
  800671:	53                   	push   %ebx
  800672:	6a 58                	push   $0x58
  800674:	ff d6                	call   *%esi
			break;
  800676:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800679:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80067c:	e9 8b fc ff ff       	jmp    80030c <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800681:	83 ec 08             	sub    $0x8,%esp
  800684:	53                   	push   %ebx
  800685:	6a 30                	push   $0x30
  800687:	ff d6                	call   *%esi
			putch('x', putdat);
  800689:	83 c4 08             	add    $0x8,%esp
  80068c:	53                   	push   %ebx
  80068d:	6a 78                	push   $0x78
  80068f:	ff d6                	call   *%esi
			num = (unsigned long long)
  800691:	8b 45 14             	mov    0x14(%ebp),%eax
  800694:	8b 10                	mov    (%eax),%edx
  800696:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80069b:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80069e:	8d 40 04             	lea    0x4(%eax),%eax
  8006a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006a4:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006a9:	eb 4a                	jmp    8006f5 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006ab:	83 f9 01             	cmp    $0x1,%ecx
  8006ae:	7e 15                	jle    8006c5 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b3:	8b 10                	mov    (%eax),%edx
  8006b5:	8b 48 04             	mov    0x4(%eax),%ecx
  8006b8:	8d 40 08             	lea    0x8(%eax),%eax
  8006bb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006be:	b8 10 00 00 00       	mov    $0x10,%eax
  8006c3:	eb 30                	jmp    8006f5 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006c5:	85 c9                	test   %ecx,%ecx
  8006c7:	74 17                	je     8006e0 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cc:	8b 10                	mov    (%eax),%edx
  8006ce:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006d3:	8d 40 04             	lea    0x4(%eax),%eax
  8006d6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006d9:	b8 10 00 00 00       	mov    $0x10,%eax
  8006de:	eb 15                	jmp    8006f5 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006e0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e3:	8b 10                	mov    (%eax),%edx
  8006e5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006ea:	8d 40 04             	lea    0x4(%eax),%eax
  8006ed:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f0:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006f5:	83 ec 0c             	sub    $0xc,%esp
  8006f8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006fc:	57                   	push   %edi
  8006fd:	ff 75 e0             	pushl  -0x20(%ebp)
  800700:	50                   	push   %eax
  800701:	51                   	push   %ecx
  800702:	52                   	push   %edx
  800703:	89 da                	mov    %ebx,%edx
  800705:	89 f0                	mov    %esi,%eax
  800707:	e8 f1 fa ff ff       	call   8001fd <printnum>
			break;
  80070c:	83 c4 20             	add    $0x20,%esp
  80070f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800712:	e9 f5 fb ff ff       	jmp    80030c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800717:	83 ec 08             	sub    $0x8,%esp
  80071a:	53                   	push   %ebx
  80071b:	52                   	push   %edx
  80071c:	ff d6                	call   *%esi
			break;
  80071e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800721:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800724:	e9 e3 fb ff ff       	jmp    80030c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800729:	83 ec 08             	sub    $0x8,%esp
  80072c:	53                   	push   %ebx
  80072d:	6a 25                	push   $0x25
  80072f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800731:	83 c4 10             	add    $0x10,%esp
  800734:	eb 03                	jmp    800739 <vprintfmt+0x453>
  800736:	83 ef 01             	sub    $0x1,%edi
  800739:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80073d:	75 f7                	jne    800736 <vprintfmt+0x450>
  80073f:	e9 c8 fb ff ff       	jmp    80030c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800744:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800747:	5b                   	pop    %ebx
  800748:	5e                   	pop    %esi
  800749:	5f                   	pop    %edi
  80074a:	5d                   	pop    %ebp
  80074b:	c3                   	ret    

0080074c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80074c:	55                   	push   %ebp
  80074d:	89 e5                	mov    %esp,%ebp
  80074f:	83 ec 18             	sub    $0x18,%esp
  800752:	8b 45 08             	mov    0x8(%ebp),%eax
  800755:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800758:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80075b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80075f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800762:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800769:	85 c0                	test   %eax,%eax
  80076b:	74 26                	je     800793 <vsnprintf+0x47>
  80076d:	85 d2                	test   %edx,%edx
  80076f:	7e 22                	jle    800793 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800771:	ff 75 14             	pushl  0x14(%ebp)
  800774:	ff 75 10             	pushl  0x10(%ebp)
  800777:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80077a:	50                   	push   %eax
  80077b:	68 ac 02 80 00       	push   $0x8002ac
  800780:	e8 61 fb ff ff       	call   8002e6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800785:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800788:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80078b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80078e:	83 c4 10             	add    $0x10,%esp
  800791:	eb 05                	jmp    800798 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800793:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800798:	c9                   	leave  
  800799:	c3                   	ret    

0080079a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80079a:	55                   	push   %ebp
  80079b:	89 e5                	mov    %esp,%ebp
  80079d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007a3:	50                   	push   %eax
  8007a4:	ff 75 10             	pushl  0x10(%ebp)
  8007a7:	ff 75 0c             	pushl  0xc(%ebp)
  8007aa:	ff 75 08             	pushl  0x8(%ebp)
  8007ad:	e8 9a ff ff ff       	call   80074c <vsnprintf>
	va_end(ap);

	return rc;
}
  8007b2:	c9                   	leave  
  8007b3:	c3                   	ret    

008007b4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007b4:	55                   	push   %ebp
  8007b5:	89 e5                	mov    %esp,%ebp
  8007b7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007ba:	b8 00 00 00 00       	mov    $0x0,%eax
  8007bf:	eb 03                	jmp    8007c4 <strlen+0x10>
		n++;
  8007c1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007c4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007c8:	75 f7                	jne    8007c1 <strlen+0xd>
		n++;
	return n;
}
  8007ca:	5d                   	pop    %ebp
  8007cb:	c3                   	ret    

008007cc <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007cc:	55                   	push   %ebp
  8007cd:	89 e5                	mov    %esp,%ebp
  8007cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007d2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007d5:	ba 00 00 00 00       	mov    $0x0,%edx
  8007da:	eb 03                	jmp    8007df <strnlen+0x13>
		n++;
  8007dc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007df:	39 c2                	cmp    %eax,%edx
  8007e1:	74 08                	je     8007eb <strnlen+0x1f>
  8007e3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007e7:	75 f3                	jne    8007dc <strnlen+0x10>
  8007e9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007eb:	5d                   	pop    %ebp
  8007ec:	c3                   	ret    

008007ed <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007ed:	55                   	push   %ebp
  8007ee:	89 e5                	mov    %esp,%ebp
  8007f0:	53                   	push   %ebx
  8007f1:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007f7:	89 c2                	mov    %eax,%edx
  8007f9:	83 c2 01             	add    $0x1,%edx
  8007fc:	83 c1 01             	add    $0x1,%ecx
  8007ff:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800803:	88 5a ff             	mov    %bl,-0x1(%edx)
  800806:	84 db                	test   %bl,%bl
  800808:	75 ef                	jne    8007f9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80080a:	5b                   	pop    %ebx
  80080b:	5d                   	pop    %ebp
  80080c:	c3                   	ret    

0080080d <strcat>:

char *
strcat(char *dst, const char *src)
{
  80080d:	55                   	push   %ebp
  80080e:	89 e5                	mov    %esp,%ebp
  800810:	53                   	push   %ebx
  800811:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800814:	53                   	push   %ebx
  800815:	e8 9a ff ff ff       	call   8007b4 <strlen>
  80081a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80081d:	ff 75 0c             	pushl  0xc(%ebp)
  800820:	01 d8                	add    %ebx,%eax
  800822:	50                   	push   %eax
  800823:	e8 c5 ff ff ff       	call   8007ed <strcpy>
	return dst;
}
  800828:	89 d8                	mov    %ebx,%eax
  80082a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80082d:	c9                   	leave  
  80082e:	c3                   	ret    

0080082f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80082f:	55                   	push   %ebp
  800830:	89 e5                	mov    %esp,%ebp
  800832:	56                   	push   %esi
  800833:	53                   	push   %ebx
  800834:	8b 75 08             	mov    0x8(%ebp),%esi
  800837:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80083a:	89 f3                	mov    %esi,%ebx
  80083c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80083f:	89 f2                	mov    %esi,%edx
  800841:	eb 0f                	jmp    800852 <strncpy+0x23>
		*dst++ = *src;
  800843:	83 c2 01             	add    $0x1,%edx
  800846:	0f b6 01             	movzbl (%ecx),%eax
  800849:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80084c:	80 39 01             	cmpb   $0x1,(%ecx)
  80084f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800852:	39 da                	cmp    %ebx,%edx
  800854:	75 ed                	jne    800843 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800856:	89 f0                	mov    %esi,%eax
  800858:	5b                   	pop    %ebx
  800859:	5e                   	pop    %esi
  80085a:	5d                   	pop    %ebp
  80085b:	c3                   	ret    

0080085c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80085c:	55                   	push   %ebp
  80085d:	89 e5                	mov    %esp,%ebp
  80085f:	56                   	push   %esi
  800860:	53                   	push   %ebx
  800861:	8b 75 08             	mov    0x8(%ebp),%esi
  800864:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800867:	8b 55 10             	mov    0x10(%ebp),%edx
  80086a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80086c:	85 d2                	test   %edx,%edx
  80086e:	74 21                	je     800891 <strlcpy+0x35>
  800870:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800874:	89 f2                	mov    %esi,%edx
  800876:	eb 09                	jmp    800881 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800878:	83 c2 01             	add    $0x1,%edx
  80087b:	83 c1 01             	add    $0x1,%ecx
  80087e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800881:	39 c2                	cmp    %eax,%edx
  800883:	74 09                	je     80088e <strlcpy+0x32>
  800885:	0f b6 19             	movzbl (%ecx),%ebx
  800888:	84 db                	test   %bl,%bl
  80088a:	75 ec                	jne    800878 <strlcpy+0x1c>
  80088c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80088e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800891:	29 f0                	sub    %esi,%eax
}
  800893:	5b                   	pop    %ebx
  800894:	5e                   	pop    %esi
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80089d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008a0:	eb 06                	jmp    8008a8 <strcmp+0x11>
		p++, q++;
  8008a2:	83 c1 01             	add    $0x1,%ecx
  8008a5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008a8:	0f b6 01             	movzbl (%ecx),%eax
  8008ab:	84 c0                	test   %al,%al
  8008ad:	74 04                	je     8008b3 <strcmp+0x1c>
  8008af:	3a 02                	cmp    (%edx),%al
  8008b1:	74 ef                	je     8008a2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008b3:	0f b6 c0             	movzbl %al,%eax
  8008b6:	0f b6 12             	movzbl (%edx),%edx
  8008b9:	29 d0                	sub    %edx,%eax
}
  8008bb:	5d                   	pop    %ebp
  8008bc:	c3                   	ret    

008008bd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008bd:	55                   	push   %ebp
  8008be:	89 e5                	mov    %esp,%ebp
  8008c0:	53                   	push   %ebx
  8008c1:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c4:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c7:	89 c3                	mov    %eax,%ebx
  8008c9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008cc:	eb 06                	jmp    8008d4 <strncmp+0x17>
		n--, p++, q++;
  8008ce:	83 c0 01             	add    $0x1,%eax
  8008d1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008d4:	39 d8                	cmp    %ebx,%eax
  8008d6:	74 15                	je     8008ed <strncmp+0x30>
  8008d8:	0f b6 08             	movzbl (%eax),%ecx
  8008db:	84 c9                	test   %cl,%cl
  8008dd:	74 04                	je     8008e3 <strncmp+0x26>
  8008df:	3a 0a                	cmp    (%edx),%cl
  8008e1:	74 eb                	je     8008ce <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008e3:	0f b6 00             	movzbl (%eax),%eax
  8008e6:	0f b6 12             	movzbl (%edx),%edx
  8008e9:	29 d0                	sub    %edx,%eax
  8008eb:	eb 05                	jmp    8008f2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008ed:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008f2:	5b                   	pop    %ebx
  8008f3:	5d                   	pop    %ebp
  8008f4:	c3                   	ret    

008008f5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008f5:	55                   	push   %ebp
  8008f6:	89 e5                	mov    %esp,%ebp
  8008f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008ff:	eb 07                	jmp    800908 <strchr+0x13>
		if (*s == c)
  800901:	38 ca                	cmp    %cl,%dl
  800903:	74 0f                	je     800914 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800905:	83 c0 01             	add    $0x1,%eax
  800908:	0f b6 10             	movzbl (%eax),%edx
  80090b:	84 d2                	test   %dl,%dl
  80090d:	75 f2                	jne    800901 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80090f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800914:	5d                   	pop    %ebp
  800915:	c3                   	ret    

00800916 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800916:	55                   	push   %ebp
  800917:	89 e5                	mov    %esp,%ebp
  800919:	8b 45 08             	mov    0x8(%ebp),%eax
  80091c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800920:	eb 03                	jmp    800925 <strfind+0xf>
  800922:	83 c0 01             	add    $0x1,%eax
  800925:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800928:	38 ca                	cmp    %cl,%dl
  80092a:	74 04                	je     800930 <strfind+0x1a>
  80092c:	84 d2                	test   %dl,%dl
  80092e:	75 f2                	jne    800922 <strfind+0xc>
			break;
	return (char *) s;
}
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	57                   	push   %edi
  800936:	56                   	push   %esi
  800937:	53                   	push   %ebx
  800938:	8b 7d 08             	mov    0x8(%ebp),%edi
  80093b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80093e:	85 c9                	test   %ecx,%ecx
  800940:	74 36                	je     800978 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800942:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800948:	75 28                	jne    800972 <memset+0x40>
  80094a:	f6 c1 03             	test   $0x3,%cl
  80094d:	75 23                	jne    800972 <memset+0x40>
		c &= 0xFF;
  80094f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800953:	89 d3                	mov    %edx,%ebx
  800955:	c1 e3 08             	shl    $0x8,%ebx
  800958:	89 d6                	mov    %edx,%esi
  80095a:	c1 e6 18             	shl    $0x18,%esi
  80095d:	89 d0                	mov    %edx,%eax
  80095f:	c1 e0 10             	shl    $0x10,%eax
  800962:	09 f0                	or     %esi,%eax
  800964:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800966:	89 d8                	mov    %ebx,%eax
  800968:	09 d0                	or     %edx,%eax
  80096a:	c1 e9 02             	shr    $0x2,%ecx
  80096d:	fc                   	cld    
  80096e:	f3 ab                	rep stos %eax,%es:(%edi)
  800970:	eb 06                	jmp    800978 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800972:	8b 45 0c             	mov    0xc(%ebp),%eax
  800975:	fc                   	cld    
  800976:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800978:	89 f8                	mov    %edi,%eax
  80097a:	5b                   	pop    %ebx
  80097b:	5e                   	pop    %esi
  80097c:	5f                   	pop    %edi
  80097d:	5d                   	pop    %ebp
  80097e:	c3                   	ret    

0080097f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80097f:	55                   	push   %ebp
  800980:	89 e5                	mov    %esp,%ebp
  800982:	57                   	push   %edi
  800983:	56                   	push   %esi
  800984:	8b 45 08             	mov    0x8(%ebp),%eax
  800987:	8b 75 0c             	mov    0xc(%ebp),%esi
  80098a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80098d:	39 c6                	cmp    %eax,%esi
  80098f:	73 35                	jae    8009c6 <memmove+0x47>
  800991:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800994:	39 d0                	cmp    %edx,%eax
  800996:	73 2e                	jae    8009c6 <memmove+0x47>
		s += n;
		d += n;
  800998:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80099b:	89 d6                	mov    %edx,%esi
  80099d:	09 fe                	or     %edi,%esi
  80099f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009a5:	75 13                	jne    8009ba <memmove+0x3b>
  8009a7:	f6 c1 03             	test   $0x3,%cl
  8009aa:	75 0e                	jne    8009ba <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009ac:	83 ef 04             	sub    $0x4,%edi
  8009af:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009b2:	c1 e9 02             	shr    $0x2,%ecx
  8009b5:	fd                   	std    
  8009b6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009b8:	eb 09                	jmp    8009c3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009ba:	83 ef 01             	sub    $0x1,%edi
  8009bd:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009c0:	fd                   	std    
  8009c1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009c3:	fc                   	cld    
  8009c4:	eb 1d                	jmp    8009e3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009c6:	89 f2                	mov    %esi,%edx
  8009c8:	09 c2                	or     %eax,%edx
  8009ca:	f6 c2 03             	test   $0x3,%dl
  8009cd:	75 0f                	jne    8009de <memmove+0x5f>
  8009cf:	f6 c1 03             	test   $0x3,%cl
  8009d2:	75 0a                	jne    8009de <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009d4:	c1 e9 02             	shr    $0x2,%ecx
  8009d7:	89 c7                	mov    %eax,%edi
  8009d9:	fc                   	cld    
  8009da:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009dc:	eb 05                	jmp    8009e3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009de:	89 c7                	mov    %eax,%edi
  8009e0:	fc                   	cld    
  8009e1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009e3:	5e                   	pop    %esi
  8009e4:	5f                   	pop    %edi
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009ea:	ff 75 10             	pushl  0x10(%ebp)
  8009ed:	ff 75 0c             	pushl  0xc(%ebp)
  8009f0:	ff 75 08             	pushl  0x8(%ebp)
  8009f3:	e8 87 ff ff ff       	call   80097f <memmove>
}
  8009f8:	c9                   	leave  
  8009f9:	c3                   	ret    

008009fa <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009fa:	55                   	push   %ebp
  8009fb:	89 e5                	mov    %esp,%ebp
  8009fd:	56                   	push   %esi
  8009fe:	53                   	push   %ebx
  8009ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800a02:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a05:	89 c6                	mov    %eax,%esi
  800a07:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a0a:	eb 1a                	jmp    800a26 <memcmp+0x2c>
		if (*s1 != *s2)
  800a0c:	0f b6 08             	movzbl (%eax),%ecx
  800a0f:	0f b6 1a             	movzbl (%edx),%ebx
  800a12:	38 d9                	cmp    %bl,%cl
  800a14:	74 0a                	je     800a20 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a16:	0f b6 c1             	movzbl %cl,%eax
  800a19:	0f b6 db             	movzbl %bl,%ebx
  800a1c:	29 d8                	sub    %ebx,%eax
  800a1e:	eb 0f                	jmp    800a2f <memcmp+0x35>
		s1++, s2++;
  800a20:	83 c0 01             	add    $0x1,%eax
  800a23:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a26:	39 f0                	cmp    %esi,%eax
  800a28:	75 e2                	jne    800a0c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a2f:	5b                   	pop    %ebx
  800a30:	5e                   	pop    %esi
  800a31:	5d                   	pop    %ebp
  800a32:	c3                   	ret    

00800a33 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a33:	55                   	push   %ebp
  800a34:	89 e5                	mov    %esp,%ebp
  800a36:	53                   	push   %ebx
  800a37:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a3a:	89 c1                	mov    %eax,%ecx
  800a3c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a3f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a43:	eb 0a                	jmp    800a4f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a45:	0f b6 10             	movzbl (%eax),%edx
  800a48:	39 da                	cmp    %ebx,%edx
  800a4a:	74 07                	je     800a53 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a4c:	83 c0 01             	add    $0x1,%eax
  800a4f:	39 c8                	cmp    %ecx,%eax
  800a51:	72 f2                	jb     800a45 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a53:	5b                   	pop    %ebx
  800a54:	5d                   	pop    %ebp
  800a55:	c3                   	ret    

00800a56 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a56:	55                   	push   %ebp
  800a57:	89 e5                	mov    %esp,%ebp
  800a59:	57                   	push   %edi
  800a5a:	56                   	push   %esi
  800a5b:	53                   	push   %ebx
  800a5c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a5f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a62:	eb 03                	jmp    800a67 <strtol+0x11>
		s++;
  800a64:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a67:	0f b6 01             	movzbl (%ecx),%eax
  800a6a:	3c 20                	cmp    $0x20,%al
  800a6c:	74 f6                	je     800a64 <strtol+0xe>
  800a6e:	3c 09                	cmp    $0x9,%al
  800a70:	74 f2                	je     800a64 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a72:	3c 2b                	cmp    $0x2b,%al
  800a74:	75 0a                	jne    800a80 <strtol+0x2a>
		s++;
  800a76:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a79:	bf 00 00 00 00       	mov    $0x0,%edi
  800a7e:	eb 11                	jmp    800a91 <strtol+0x3b>
  800a80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a85:	3c 2d                	cmp    $0x2d,%al
  800a87:	75 08                	jne    800a91 <strtol+0x3b>
		s++, neg = 1;
  800a89:	83 c1 01             	add    $0x1,%ecx
  800a8c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a91:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a97:	75 15                	jne    800aae <strtol+0x58>
  800a99:	80 39 30             	cmpb   $0x30,(%ecx)
  800a9c:	75 10                	jne    800aae <strtol+0x58>
  800a9e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800aa2:	75 7c                	jne    800b20 <strtol+0xca>
		s += 2, base = 16;
  800aa4:	83 c1 02             	add    $0x2,%ecx
  800aa7:	bb 10 00 00 00       	mov    $0x10,%ebx
  800aac:	eb 16                	jmp    800ac4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800aae:	85 db                	test   %ebx,%ebx
  800ab0:	75 12                	jne    800ac4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ab2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ab7:	80 39 30             	cmpb   $0x30,(%ecx)
  800aba:	75 08                	jne    800ac4 <strtol+0x6e>
		s++, base = 8;
  800abc:	83 c1 01             	add    $0x1,%ecx
  800abf:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800ac4:	b8 00 00 00 00       	mov    $0x0,%eax
  800ac9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800acc:	0f b6 11             	movzbl (%ecx),%edx
  800acf:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ad2:	89 f3                	mov    %esi,%ebx
  800ad4:	80 fb 09             	cmp    $0x9,%bl
  800ad7:	77 08                	ja     800ae1 <strtol+0x8b>
			dig = *s - '0';
  800ad9:	0f be d2             	movsbl %dl,%edx
  800adc:	83 ea 30             	sub    $0x30,%edx
  800adf:	eb 22                	jmp    800b03 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800ae1:	8d 72 9f             	lea    -0x61(%edx),%esi
  800ae4:	89 f3                	mov    %esi,%ebx
  800ae6:	80 fb 19             	cmp    $0x19,%bl
  800ae9:	77 08                	ja     800af3 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aeb:	0f be d2             	movsbl %dl,%edx
  800aee:	83 ea 57             	sub    $0x57,%edx
  800af1:	eb 10                	jmp    800b03 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800af3:	8d 72 bf             	lea    -0x41(%edx),%esi
  800af6:	89 f3                	mov    %esi,%ebx
  800af8:	80 fb 19             	cmp    $0x19,%bl
  800afb:	77 16                	ja     800b13 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800afd:	0f be d2             	movsbl %dl,%edx
  800b00:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b03:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b06:	7d 0b                	jge    800b13 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b08:	83 c1 01             	add    $0x1,%ecx
  800b0b:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b0f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b11:	eb b9                	jmp    800acc <strtol+0x76>

	if (endptr)
  800b13:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b17:	74 0d                	je     800b26 <strtol+0xd0>
		*endptr = (char *) s;
  800b19:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b1c:	89 0e                	mov    %ecx,(%esi)
  800b1e:	eb 06                	jmp    800b26 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b20:	85 db                	test   %ebx,%ebx
  800b22:	74 98                	je     800abc <strtol+0x66>
  800b24:	eb 9e                	jmp    800ac4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b26:	89 c2                	mov    %eax,%edx
  800b28:	f7 da                	neg    %edx
  800b2a:	85 ff                	test   %edi,%edi
  800b2c:	0f 45 c2             	cmovne %edx,%eax
}
  800b2f:	5b                   	pop    %ebx
  800b30:	5e                   	pop    %esi
  800b31:	5f                   	pop    %edi
  800b32:	5d                   	pop    %ebp
  800b33:	c3                   	ret    

00800b34 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b34:	55                   	push   %ebp
  800b35:	89 e5                	mov    %esp,%ebp
  800b37:	57                   	push   %edi
  800b38:	56                   	push   %esi
  800b39:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b3a:	b8 00 00 00 00       	mov    $0x0,%eax
  800b3f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b42:	8b 55 08             	mov    0x8(%ebp),%edx
  800b45:	89 c3                	mov    %eax,%ebx
  800b47:	89 c7                	mov    %eax,%edi
  800b49:	89 c6                	mov    %eax,%esi
  800b4b:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b4d:	5b                   	pop    %ebx
  800b4e:	5e                   	pop    %esi
  800b4f:	5f                   	pop    %edi
  800b50:	5d                   	pop    %ebp
  800b51:	c3                   	ret    

00800b52 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b52:	55                   	push   %ebp
  800b53:	89 e5                	mov    %esp,%ebp
  800b55:	57                   	push   %edi
  800b56:	56                   	push   %esi
  800b57:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b58:	ba 00 00 00 00       	mov    $0x0,%edx
  800b5d:	b8 01 00 00 00       	mov    $0x1,%eax
  800b62:	89 d1                	mov    %edx,%ecx
  800b64:	89 d3                	mov    %edx,%ebx
  800b66:	89 d7                	mov    %edx,%edi
  800b68:	89 d6                	mov    %edx,%esi
  800b6a:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b6c:	5b                   	pop    %ebx
  800b6d:	5e                   	pop    %esi
  800b6e:	5f                   	pop    %edi
  800b6f:	5d                   	pop    %ebp
  800b70:	c3                   	ret    

00800b71 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b71:	55                   	push   %ebp
  800b72:	89 e5                	mov    %esp,%ebp
  800b74:	57                   	push   %edi
  800b75:	56                   	push   %esi
  800b76:	53                   	push   %ebx
  800b77:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b7f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b84:	8b 55 08             	mov    0x8(%ebp),%edx
  800b87:	89 cb                	mov    %ecx,%ebx
  800b89:	89 cf                	mov    %ecx,%edi
  800b8b:	89 ce                	mov    %ecx,%esi
  800b8d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b8f:	85 c0                	test   %eax,%eax
  800b91:	7e 17                	jle    800baa <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b93:	83 ec 0c             	sub    $0xc,%esp
  800b96:	50                   	push   %eax
  800b97:	6a 03                	push   $0x3
  800b99:	68 24 17 80 00       	push   $0x801724
  800b9e:	6a 23                	push   $0x23
  800ba0:	68 41 17 80 00       	push   $0x801741
  800ba5:	e8 7f 05 00 00       	call   801129 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800baa:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bad:	5b                   	pop    %ebx
  800bae:	5e                   	pop    %esi
  800baf:	5f                   	pop    %edi
  800bb0:	5d                   	pop    %ebp
  800bb1:	c3                   	ret    

00800bb2 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bb2:	55                   	push   %ebp
  800bb3:	89 e5                	mov    %esp,%ebp
  800bb5:	57                   	push   %edi
  800bb6:	56                   	push   %esi
  800bb7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb8:	ba 00 00 00 00       	mov    $0x0,%edx
  800bbd:	b8 02 00 00 00       	mov    $0x2,%eax
  800bc2:	89 d1                	mov    %edx,%ecx
  800bc4:	89 d3                	mov    %edx,%ebx
  800bc6:	89 d7                	mov    %edx,%edi
  800bc8:	89 d6                	mov    %edx,%esi
  800bca:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800bcc:	5b                   	pop    %ebx
  800bcd:	5e                   	pop    %esi
  800bce:	5f                   	pop    %edi
  800bcf:	5d                   	pop    %ebp
  800bd0:	c3                   	ret    

00800bd1 <sys_yield>:

void
sys_yield(void)
{
  800bd1:	55                   	push   %ebp
  800bd2:	89 e5                	mov    %esp,%ebp
  800bd4:	57                   	push   %edi
  800bd5:	56                   	push   %esi
  800bd6:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bd7:	ba 00 00 00 00       	mov    $0x0,%edx
  800bdc:	b8 0a 00 00 00       	mov    $0xa,%eax
  800be1:	89 d1                	mov    %edx,%ecx
  800be3:	89 d3                	mov    %edx,%ebx
  800be5:	89 d7                	mov    %edx,%edi
  800be7:	89 d6                	mov    %edx,%esi
  800be9:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800beb:	5b                   	pop    %ebx
  800bec:	5e                   	pop    %esi
  800bed:	5f                   	pop    %edi
  800bee:	5d                   	pop    %ebp
  800bef:	c3                   	ret    

00800bf0 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800bf0:	55                   	push   %ebp
  800bf1:	89 e5                	mov    %esp,%ebp
  800bf3:	57                   	push   %edi
  800bf4:	56                   	push   %esi
  800bf5:	53                   	push   %ebx
  800bf6:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf9:	be 00 00 00 00       	mov    $0x0,%esi
  800bfe:	b8 04 00 00 00       	mov    $0x4,%eax
  800c03:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c06:	8b 55 08             	mov    0x8(%ebp),%edx
  800c09:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c0c:	89 f7                	mov    %esi,%edi
  800c0e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c10:	85 c0                	test   %eax,%eax
  800c12:	7e 17                	jle    800c2b <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c14:	83 ec 0c             	sub    $0xc,%esp
  800c17:	50                   	push   %eax
  800c18:	6a 04                	push   $0x4
  800c1a:	68 24 17 80 00       	push   $0x801724
  800c1f:	6a 23                	push   $0x23
  800c21:	68 41 17 80 00       	push   $0x801741
  800c26:	e8 fe 04 00 00       	call   801129 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c2e:	5b                   	pop    %ebx
  800c2f:	5e                   	pop    %esi
  800c30:	5f                   	pop    %edi
  800c31:	5d                   	pop    %ebp
  800c32:	c3                   	ret    

00800c33 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c33:	55                   	push   %ebp
  800c34:	89 e5                	mov    %esp,%ebp
  800c36:	57                   	push   %edi
  800c37:	56                   	push   %esi
  800c38:	53                   	push   %ebx
  800c39:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c3c:	b8 05 00 00 00       	mov    $0x5,%eax
  800c41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c44:	8b 55 08             	mov    0x8(%ebp),%edx
  800c47:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c4a:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c4d:	8b 75 18             	mov    0x18(%ebp),%esi
  800c50:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c52:	85 c0                	test   %eax,%eax
  800c54:	7e 17                	jle    800c6d <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c56:	83 ec 0c             	sub    $0xc,%esp
  800c59:	50                   	push   %eax
  800c5a:	6a 05                	push   $0x5
  800c5c:	68 24 17 80 00       	push   $0x801724
  800c61:	6a 23                	push   $0x23
  800c63:	68 41 17 80 00       	push   $0x801741
  800c68:	e8 bc 04 00 00       	call   801129 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c70:	5b                   	pop    %ebx
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    

00800c75 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c75:	55                   	push   %ebp
  800c76:	89 e5                	mov    %esp,%ebp
  800c78:	57                   	push   %edi
  800c79:	56                   	push   %esi
  800c7a:	53                   	push   %ebx
  800c7b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c83:	b8 06 00 00 00       	mov    $0x6,%eax
  800c88:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c8b:	8b 55 08             	mov    0x8(%ebp),%edx
  800c8e:	89 df                	mov    %ebx,%edi
  800c90:	89 de                	mov    %ebx,%esi
  800c92:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c94:	85 c0                	test   %eax,%eax
  800c96:	7e 17                	jle    800caf <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c98:	83 ec 0c             	sub    $0xc,%esp
  800c9b:	50                   	push   %eax
  800c9c:	6a 06                	push   $0x6
  800c9e:	68 24 17 80 00       	push   $0x801724
  800ca3:	6a 23                	push   $0x23
  800ca5:	68 41 17 80 00       	push   $0x801741
  800caa:	e8 7a 04 00 00       	call   801129 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800caf:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cb2:	5b                   	pop    %ebx
  800cb3:	5e                   	pop    %esi
  800cb4:	5f                   	pop    %edi
  800cb5:	5d                   	pop    %ebp
  800cb6:	c3                   	ret    

00800cb7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800cb7:	55                   	push   %ebp
  800cb8:	89 e5                	mov    %esp,%ebp
  800cba:	57                   	push   %edi
  800cbb:	56                   	push   %esi
  800cbc:	53                   	push   %ebx
  800cbd:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cc0:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cc5:	b8 08 00 00 00       	mov    $0x8,%eax
  800cca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ccd:	8b 55 08             	mov    0x8(%ebp),%edx
  800cd0:	89 df                	mov    %ebx,%edi
  800cd2:	89 de                	mov    %ebx,%esi
  800cd4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cd6:	85 c0                	test   %eax,%eax
  800cd8:	7e 17                	jle    800cf1 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cda:	83 ec 0c             	sub    $0xc,%esp
  800cdd:	50                   	push   %eax
  800cde:	6a 08                	push   $0x8
  800ce0:	68 24 17 80 00       	push   $0x801724
  800ce5:	6a 23                	push   $0x23
  800ce7:	68 41 17 80 00       	push   $0x801741
  800cec:	e8 38 04 00 00       	call   801129 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800cf1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cf4:	5b                   	pop    %ebx
  800cf5:	5e                   	pop    %esi
  800cf6:	5f                   	pop    %edi
  800cf7:	5d                   	pop    %ebp
  800cf8:	c3                   	ret    

00800cf9 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800cf9:	55                   	push   %ebp
  800cfa:	89 e5                	mov    %esp,%ebp
  800cfc:	57                   	push   %edi
  800cfd:	56                   	push   %esi
  800cfe:	53                   	push   %ebx
  800cff:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d02:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d07:	b8 09 00 00 00       	mov    $0x9,%eax
  800d0c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d0f:	8b 55 08             	mov    0x8(%ebp),%edx
  800d12:	89 df                	mov    %ebx,%edi
  800d14:	89 de                	mov    %ebx,%esi
  800d16:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d18:	85 c0                	test   %eax,%eax
  800d1a:	7e 17                	jle    800d33 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d1c:	83 ec 0c             	sub    $0xc,%esp
  800d1f:	50                   	push   %eax
  800d20:	6a 09                	push   $0x9
  800d22:	68 24 17 80 00       	push   $0x801724
  800d27:	6a 23                	push   $0x23
  800d29:	68 41 17 80 00       	push   $0x801741
  800d2e:	e8 f6 03 00 00       	call   801129 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d33:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d36:	5b                   	pop    %ebx
  800d37:	5e                   	pop    %esi
  800d38:	5f                   	pop    %edi
  800d39:	5d                   	pop    %ebp
  800d3a:	c3                   	ret    

00800d3b <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d3b:	55                   	push   %ebp
  800d3c:	89 e5                	mov    %esp,%ebp
  800d3e:	57                   	push   %edi
  800d3f:	56                   	push   %esi
  800d40:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d41:	be 00 00 00 00       	mov    $0x0,%esi
  800d46:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d4b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d4e:	8b 55 08             	mov    0x8(%ebp),%edx
  800d51:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d54:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d57:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d59:	5b                   	pop    %ebx
  800d5a:	5e                   	pop    %esi
  800d5b:	5f                   	pop    %edi
  800d5c:	5d                   	pop    %ebp
  800d5d:	c3                   	ret    

00800d5e <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d5e:	55                   	push   %ebp
  800d5f:	89 e5                	mov    %esp,%ebp
  800d61:	57                   	push   %edi
  800d62:	56                   	push   %esi
  800d63:	53                   	push   %ebx
  800d64:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d67:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d6c:	b8 0c 00 00 00       	mov    $0xc,%eax
  800d71:	8b 55 08             	mov    0x8(%ebp),%edx
  800d74:	89 cb                	mov    %ecx,%ebx
  800d76:	89 cf                	mov    %ecx,%edi
  800d78:	89 ce                	mov    %ecx,%esi
  800d7a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d7c:	85 c0                	test   %eax,%eax
  800d7e:	7e 17                	jle    800d97 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d80:	83 ec 0c             	sub    $0xc,%esp
  800d83:	50                   	push   %eax
  800d84:	6a 0c                	push   $0xc
  800d86:	68 24 17 80 00       	push   $0x801724
  800d8b:	6a 23                	push   $0x23
  800d8d:	68 41 17 80 00       	push   $0x801741
  800d92:	e8 92 03 00 00       	call   801129 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800d97:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d9a:	5b                   	pop    %ebx
  800d9b:	5e                   	pop    %esi
  800d9c:	5f                   	pop    %edi
  800d9d:	5d                   	pop    %ebp
  800d9e:	c3                   	ret    

00800d9f <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800d9f:	55                   	push   %ebp
  800da0:	89 e5                	mov    %esp,%ebp
  800da2:	53                   	push   %ebx
  800da3:	83 ec 04             	sub    $0x4,%esp
  800da6:	8b 45 08             	mov    0x8(%ebp),%eax
void *addr = (void *) utf->utf_fault_va;
  800da9:	8b 18                	mov    (%eax),%ebx
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	if ((err & FEC_WR) == 0)
  800dab:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800daf:	75 12                	jne    800dc3 <pgfault+0x24>
		panic("pgfault: faulting address [%08x] not a write\n", addr);
  800db1:	53                   	push   %ebx
  800db2:	68 50 17 80 00       	push   $0x801750
  800db7:	6a 1f                	push   $0x1f
  800db9:	68 f8 17 80 00       	push   $0x8017f8
  800dbe:	e8 66 03 00 00       	call   801129 <_panic>

	if (!(uvpt[PGNUM(addr)] & PTE_COW))
  800dc3:	89 d8                	mov    %ebx,%eax
  800dc5:	c1 e8 0c             	shr    $0xc,%eax
  800dc8:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800dcf:	f6 c4 08             	test   $0x8,%ah
  800dd2:	75 14                	jne    800de8 <pgfault+0x49>
		panic("pgfault: fault was not on a copy-on-write page\n");
  800dd4:	83 ec 04             	sub    $0x4,%esp
  800dd7:	68 80 17 80 00       	push   $0x801780
  800ddc:	6a 22                	push   $0x22
  800dde:	68 f8 17 80 00       	push   $0x8017f8
  800de3:	e8 41 03 00 00       	call   801129 <_panic>
	//   You should make three system calls.

	// LAB 4: Your code here.


	if ((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0)
  800de8:	83 ec 04             	sub    $0x4,%esp
  800deb:	6a 07                	push   $0x7
  800ded:	68 00 f0 7f 00       	push   $0x7ff000
  800df2:	6a 00                	push   $0x0
  800df4:	e8 f7 fd ff ff       	call   800bf0 <sys_page_alloc>
  800df9:	83 c4 10             	add    $0x10,%esp
  800dfc:	85 c0                	test   %eax,%eax
  800dfe:	79 12                	jns    800e12 <pgfault+0x73>
		panic("sys_page_alloc: %e\n", r);
  800e00:	50                   	push   %eax
  800e01:	68 03 18 80 00       	push   $0x801803
  800e06:	6a 30                	push   $0x30
  800e08:	68 f8 17 80 00       	push   $0x8017f8
  800e0d:	e8 17 03 00 00       	call   801129 <_panic>


	void *src_addr = (void *) ROUNDDOWN(addr, PGSIZE);
  800e12:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove(PFTEMP, src_addr, PGSIZE);
  800e18:	83 ec 04             	sub    $0x4,%esp
  800e1b:	68 00 10 00 00       	push   $0x1000
  800e20:	53                   	push   %ebx
  800e21:	68 00 f0 7f 00       	push   $0x7ff000
  800e26:	e8 54 fb ff ff       	call   80097f <memmove>

	
	if ((r = sys_page_map(0, PFTEMP, 0, src_addr, PTE_P | PTE_U | PTE_W)) < 0)
  800e2b:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800e32:	53                   	push   %ebx
  800e33:	6a 00                	push   $0x0
  800e35:	68 00 f0 7f 00       	push   $0x7ff000
  800e3a:	6a 00                	push   $0x0
  800e3c:	e8 f2 fd ff ff       	call   800c33 <sys_page_map>
  800e41:	83 c4 20             	add    $0x20,%esp
  800e44:	85 c0                	test   %eax,%eax
  800e46:	79 12                	jns    800e5a <pgfault+0xbb>
	panic("sys_page_map: %e\n", r);
  800e48:	50                   	push   %eax
  800e49:	68 17 18 80 00       	push   $0x801817
  800e4e:	6a 38                	push   $0x38
  800e50:	68 f8 17 80 00       	push   $0x8017f8
  800e55:	e8 cf 02 00 00       	call   801129 <_panic>

}
  800e5a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800e5d:	c9                   	leave  
  800e5e:	c3                   	ret    

00800e5f <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800e5f:	55                   	push   %ebp
  800e60:	89 e5                	mov    %esp,%ebp
  800e62:	57                   	push   %edi
  800e63:	56                   	push   %esi
  800e64:	53                   	push   %ebx
  800e65:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	int r;
	envid_t child_envid;

	set_pgfault_handler(pgfault);
  800e68:	68 9f 0d 80 00       	push   $0x800d9f
  800e6d:	e8 fd 02 00 00       	call   80116f <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800e72:	b8 07 00 00 00       	mov    $0x7,%eax
  800e77:	cd 30                	int    $0x30
  800e79:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800e7c:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	child_envid = sys_exofork();
	if (child_envid < 0)
  800e7f:	83 c4 10             	add    $0x10,%esp
  800e82:	85 c0                	test   %eax,%eax
  800e84:	79 12                	jns    800e98 <fork+0x39>
		panic("sys_exofork: %e\n", child_envid);
  800e86:	50                   	push   %eax
  800e87:	68 29 18 80 00       	push   $0x801829
  800e8c:	6a 75                	push   $0x75
  800e8e:	68 f8 17 80 00       	push   $0x8017f8
  800e93:	e8 91 02 00 00       	call   801129 <_panic>
  800e98:	bb 00 00 00 00       	mov    $0x0,%ebx
	if (child_envid == 0) { // child
  800e9d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800ea1:	75 21                	jne    800ec4 <fork+0x65>
		thisenv = &envs[ENVX(sys_getenvid())];
  800ea3:	e8 0a fd ff ff       	call   800bb2 <sys_getenvid>
  800ea8:	25 ff 03 00 00       	and    $0x3ff,%eax
  800ead:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800eb0:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800eb5:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  800eba:	b8 00 00 00 00       	mov    $0x0,%eax
  800ebf:	e9 3b 01 00 00       	jmp    800fff <fork+0x1a0>
	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
		
		
		uint32_t pdx = ROUNDDOWN(page_num, NPDENTRIES) / NPDENTRIES;
  800ec4:	89 d8                	mov    %ebx,%eax
  800ec6:	c1 e8 0a             	shr    $0xa,%eax
		if ((uvpd[pdx] & PTE_P) == PTE_P &&((uvpt[page_num] & PTE_P) == PTE_P)) {
  800ec9:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800ed0:	a8 01                	test   $0x1,%al
  800ed2:	0f 84 92 00 00 00    	je     800f6a <fork+0x10b>
  800ed8:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800edf:	a8 01                	test   $0x1,%al
  800ee1:	0f 84 83 00 00 00    	je     800f6a <fork+0x10b>
{
	int r;

	// LAB 4: Your code here.
	int perm = PTE_P|PTE_U;
	void *va = (void *)(pn << PGSHIFT);
  800ee7:	89 df                	mov    %ebx,%edi
  800ee9:	c1 e7 0c             	shl    $0xc,%edi
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  800eec:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
		perm |= PTE_COW;
  800ef3:	be 05 08 00 00       	mov    $0x805,%esi
	int r;

	// LAB 4: Your code here.
	int perm = PTE_P|PTE_U;
	void *va = (void *)(pn << PGSHIFT);
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  800ef8:	a8 02                	test   $0x2,%al
  800efa:	75 1d                	jne    800f19 <fork+0xba>
  800efc:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f03:	25 00 08 00 00       	and    $0x800,%eax
		perm |= PTE_COW;
  800f08:	83 f8 01             	cmp    $0x1,%eax
  800f0b:	19 f6                	sbb    %esi,%esi
  800f0d:	81 e6 00 f8 ff ff    	and    $0xfffff800,%esi
  800f13:	81 c6 05 08 00 00    	add    $0x805,%esi
	if ((r = sys_page_map(0, va, envid, va, perm)) < 0)
  800f19:	83 ec 0c             	sub    $0xc,%esp
  800f1c:	56                   	push   %esi
  800f1d:	57                   	push   %edi
  800f1e:	ff 75 e4             	pushl  -0x1c(%ebp)
  800f21:	57                   	push   %edi
  800f22:	6a 00                	push   $0x0
  800f24:	e8 0a fd ff ff       	call   800c33 <sys_page_map>
  800f29:	83 c4 20             	add    $0x20,%esp
  800f2c:	85 c0                	test   %eax,%eax
  800f2e:	79 12                	jns    800f42 <fork+0xe3>
		panic("error in duppage(), sys_page_map: %e\n", r);
  800f30:	50                   	push   %eax
  800f31:	68 b0 17 80 00       	push   $0x8017b0
  800f36:	6a 52                	push   $0x52
  800f38:	68 f8 17 80 00       	push   $0x8017f8
  800f3d:	e8 e7 01 00 00       	call   801129 <_panic>
	if ((r = sys_page_map(0, va, 0, va, perm)) < 0)
  800f42:	83 ec 0c             	sub    $0xc,%esp
  800f45:	56                   	push   %esi
  800f46:	57                   	push   %edi
  800f47:	6a 00                	push   $0x0
  800f49:	57                   	push   %edi
  800f4a:	6a 00                	push   $0x0
  800f4c:	e8 e2 fc ff ff       	call   800c33 <sys_page_map>
  800f51:	83 c4 20             	add    $0x20,%esp
  800f54:	85 c0                	test   %eax,%eax
  800f56:	79 12                	jns    800f6a <fork+0x10b>
		panic("error in duppage(), sys_page_map: %e\n", r);
  800f58:	50                   	push   %eax
  800f59:	68 b0 17 80 00       	push   $0x8017b0
  800f5e:	6a 54                	push   $0x54
  800f60:	68 f8 17 80 00       	push   $0x8017f8
  800f65:	e8 bf 01 00 00       	call   801129 <_panic>
	// We're in the parent


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
  800f6a:	83 c3 01             	add    $0x1,%ebx
  800f6d:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  800f73:	0f 85 4b ff ff ff    	jne    800ec4 <fork+0x65>
		}
	}

	// Allocate exception stack space for child
	
	if ((r = sys_page_alloc(child_envid, (void *) (UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W)) < 0)
  800f79:	83 ec 04             	sub    $0x4,%esp
  800f7c:	6a 07                	push   $0x7
  800f7e:	68 00 f0 bf ee       	push   $0xeebff000
  800f83:	ff 75 e0             	pushl  -0x20(%ebp)
  800f86:	e8 65 fc ff ff       	call   800bf0 <sys_page_alloc>
  800f8b:	83 c4 10             	add    $0x10,%esp
  800f8e:	85 c0                	test   %eax,%eax
  800f90:	79 15                	jns    800fa7 <fork+0x148>
		panic("sys_page_alloc: %e\n", r);
  800f92:	50                   	push   %eax
  800f93:	68 03 18 80 00       	push   $0x801803
  800f98:	68 8c 00 00 00       	push   $0x8c
  800f9d:	68 f8 17 80 00       	push   $0x8017f8
  800fa2:	e8 82 01 00 00       	call   801129 <_panic>

	// Set page fault handler for the child
	if ((r = sys_env_set_pgfault_upcall(child_envid, _pgfault_upcall)) < 0)
  800fa7:	83 ec 08             	sub    $0x8,%esp
  800faa:	68 c4 11 80 00       	push   $0x8011c4
  800faf:	ff 75 e0             	pushl  -0x20(%ebp)
  800fb2:	e8 42 fd ff ff       	call   800cf9 <sys_env_set_pgfault_upcall>
  800fb7:	83 c4 10             	add    $0x10,%esp
  800fba:	85 c0                	test   %eax,%eax
  800fbc:	79 15                	jns    800fd3 <fork+0x174>
		panic("sys_env_set_pgfault_upcall: %e\n", r);
  800fbe:	50                   	push   %eax
  800fbf:	68 d8 17 80 00       	push   $0x8017d8
  800fc4:	68 90 00 00 00       	push   $0x90
  800fc9:	68 f8 17 80 00       	push   $0x8017f8
  800fce:	e8 56 01 00 00       	call   801129 <_panic>

	// Mark child environment as runnable
	if ((r = sys_env_set_status(child_envid, ENV_RUNNABLE)) < 0)
  800fd3:	83 ec 08             	sub    $0x8,%esp
  800fd6:	6a 02                	push   $0x2
  800fd8:	ff 75 e0             	pushl  -0x20(%ebp)
  800fdb:	e8 d7 fc ff ff       	call   800cb7 <sys_env_set_status>
  800fe0:	83 c4 10             	add    $0x10,%esp
  800fe3:	85 c0                	test   %eax,%eax
  800fe5:	79 15                	jns    800ffc <fork+0x19d>
		panic("sys_env_set_status: %e\n", r);
  800fe7:	50                   	push   %eax
  800fe8:	68 3a 18 80 00       	push   $0x80183a
  800fed:	68 94 00 00 00       	push   $0x94
  800ff2:	68 f8 17 80 00       	push   $0x8017f8
  800ff7:	e8 2d 01 00 00       	call   801129 <_panic>

	return child_envid;
  800ffc:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
  800fff:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801002:	5b                   	pop    %ebx
  801003:	5e                   	pop    %esi
  801004:	5f                   	pop    %edi
  801005:	5d                   	pop    %ebp
  801006:	c3                   	ret    

00801007 <sfork>:

// Challenge!
int
sfork(void)
{
  801007:	55                   	push   %ebp
  801008:	89 e5                	mov    %esp,%ebp
  80100a:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  80100d:	68 52 18 80 00       	push   $0x801852
  801012:	68 9d 00 00 00       	push   $0x9d
  801017:	68 f8 17 80 00       	push   $0x8017f8
  80101c:	e8 08 01 00 00       	call   801129 <_panic>

00801021 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801021:	55                   	push   %ebp
  801022:	89 e5                	mov    %esp,%ebp
  801024:	56                   	push   %esi
  801025:	53                   	push   %ebx
  801026:	8b 75 08             	mov    0x8(%ebp),%esi
  801029:	8b 45 0c             	mov    0xc(%ebp),%eax
  80102c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.

	int r;
	if (pg == NULL)
  80102f:	85 c0                	test   %eax,%eax
		pg = (void *) KERNBASE; // KERNBASE should be rejected by sys_ipc_recv()
  801031:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
  801036:	0f 44 c2             	cmove  %edx,%eax

	if ((r = sys_ipc_recv(pg)) != 0) {
  801039:	83 ec 0c             	sub    $0xc,%esp
  80103c:	50                   	push   %eax
  80103d:	e8 1c fd ff ff       	call   800d5e <sys_ipc_recv>
  801042:	83 c4 10             	add    $0x10,%esp
  801045:	85 c0                	test   %eax,%eax
  801047:	74 16                	je     80105f <ipc_recv+0x3e>
		if (from_env_store != NULL)
  801049:	85 f6                	test   %esi,%esi
  80104b:	74 06                	je     801053 <ipc_recv+0x32>
			*from_env_store = 0;
  80104d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (perm_store != NULL)
  801053:	85 db                	test   %ebx,%ebx
  801055:	74 2c                	je     801083 <ipc_recv+0x62>
			*perm_store = 0;
  801057:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80105d:	eb 24                	jmp    801083 <ipc_recv+0x62>
		return r;
	}

	if (from_env_store != NULL)
  80105f:	85 f6                	test   %esi,%esi
  801061:	74 0a                	je     80106d <ipc_recv+0x4c>
		*from_env_store = thisenv->env_ipc_from;
  801063:	a1 08 20 80 00       	mov    0x802008,%eax
  801068:	8b 40 74             	mov    0x74(%eax),%eax
  80106b:	89 06                	mov    %eax,(%esi)
	if (perm_store != NULL)
  80106d:	85 db                	test   %ebx,%ebx
  80106f:	74 0a                	je     80107b <ipc_recv+0x5a>
		*perm_store = thisenv->env_ipc_perm;
  801071:	a1 08 20 80 00       	mov    0x802008,%eax
  801076:	8b 40 78             	mov    0x78(%eax),%eax
  801079:	89 03                	mov    %eax,(%ebx)

return thisenv->env_ipc_value;
  80107b:	a1 08 20 80 00       	mov    0x802008,%eax
  801080:	8b 40 70             	mov    0x70(%eax),%eax
	return 0;
}
  801083:	8d 65 f8             	lea    -0x8(%ebp),%esp
  801086:	5b                   	pop    %ebx
  801087:	5e                   	pop    %esi
  801088:	5d                   	pop    %ebp
  801089:	c3                   	ret    

0080108a <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80108a:	55                   	push   %ebp
  80108b:	89 e5                	mov    %esp,%ebp
  80108d:	57                   	push   %edi
  80108e:	56                   	push   %esi
  80108f:	53                   	push   %ebx
  801090:	83 ec 0c             	sub    $0xc,%esp
  801093:	8b 75 0c             	mov    0xc(%ebp),%esi
  801096:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801099:	8b 7d 14             	mov    0x14(%ebp),%edi
	// LAB 4: Your code here.
	if (pg == NULL)
		pg = (void *) KERNBASE;
  80109c:	85 db                	test   %ebx,%ebx
  80109e:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  8010a3:	0f 44 d8             	cmove  %eax,%ebx

	int r = sys_ipc_try_send(to_env, val, pg, perm);
  8010a6:	57                   	push   %edi
  8010a7:	53                   	push   %ebx
  8010a8:	56                   	push   %esi
  8010a9:	ff 75 08             	pushl  0x8(%ebp)
  8010ac:	e8 8a fc ff ff       	call   800d3b <sys_ipc_try_send>

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  8010b1:	83 c4 10             	add    $0x10,%esp
  8010b4:	eb 17                	jmp    8010cd <ipc_send+0x43>
		if (r == 0)
  8010b6:	85 c0                	test   %eax,%eax
  8010b8:	74 2e                	je     8010e8 <ipc_send+0x5e>
			return;

		sys_yield(); // release CPU before attempting to send again
  8010ba:	e8 12 fb ff ff       	call   800bd1 <sys_yield>

		r = sys_ipc_try_send(to_env, val, pg, perm);
  8010bf:	57                   	push   %edi
  8010c0:	53                   	push   %ebx
  8010c1:	56                   	push   %esi
  8010c2:	ff 75 08             	pushl  0x8(%ebp)
  8010c5:	e8 71 fc ff ff       	call   800d3b <sys_ipc_try_send>
  8010ca:	83 c4 10             	add    $0x10,%esp
	if (pg == NULL)
		pg = (void *) KERNBASE;

	int r = sys_ipc_try_send(to_env, val, pg, perm);

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  8010cd:	83 f8 f9             	cmp    $0xfffffff9,%eax
  8010d0:	74 e4                	je     8010b6 <ipc_send+0x2c>
  8010d2:	85 c0                	test   %eax,%eax
  8010d4:	74 e0                	je     8010b6 <ipc_send+0x2c>
		sys_yield(); // release CPU before attempting to send again

		r = sys_ipc_try_send(to_env, val, pg, perm);
	}

panic("ipc_send: %e\n", r);
  8010d6:	50                   	push   %eax
  8010d7:	68 68 18 80 00       	push   $0x801868
  8010dc:	6a 4a                	push   $0x4a
  8010de:	68 76 18 80 00       	push   $0x801876
  8010e3:	e8 41 00 00 00       	call   801129 <_panic>
}
  8010e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8010eb:	5b                   	pop    %ebx
  8010ec:	5e                   	pop    %esi
  8010ed:	5f                   	pop    %edi
  8010ee:	5d                   	pop    %ebp
  8010ef:	c3                   	ret    

008010f0 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  8010f0:	55                   	push   %ebp
  8010f1:	89 e5                	mov    %esp,%ebp
  8010f3:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  8010f6:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  8010fb:	6b d0 7c             	imul   $0x7c,%eax,%edx
  8010fe:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801104:	8b 52 50             	mov    0x50(%edx),%edx
  801107:	39 ca                	cmp    %ecx,%edx
  801109:	75 0d                	jne    801118 <ipc_find_env+0x28>
			return envs[i].env_id;
  80110b:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80110e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801113:	8b 40 48             	mov    0x48(%eax),%eax
  801116:	eb 0f                	jmp    801127 <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801118:	83 c0 01             	add    $0x1,%eax
  80111b:	3d 00 04 00 00       	cmp    $0x400,%eax
  801120:	75 d9                	jne    8010fb <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801122:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801127:	5d                   	pop    %ebp
  801128:	c3                   	ret    

00801129 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801129:	55                   	push   %ebp
  80112a:	89 e5                	mov    %esp,%ebp
  80112c:	56                   	push   %esi
  80112d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80112e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801131:	8b 35 00 20 80 00    	mov    0x802000,%esi
  801137:	e8 76 fa ff ff       	call   800bb2 <sys_getenvid>
  80113c:	83 ec 0c             	sub    $0xc,%esp
  80113f:	ff 75 0c             	pushl  0xc(%ebp)
  801142:	ff 75 08             	pushl  0x8(%ebp)
  801145:	56                   	push   %esi
  801146:	50                   	push   %eax
  801147:	68 80 18 80 00       	push   $0x801880
  80114c:	e8 98 f0 ff ff       	call   8001e9 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801151:	83 c4 18             	add    $0x18,%esp
  801154:	53                   	push   %ebx
  801155:	ff 75 10             	pushl  0x10(%ebp)
  801158:	e8 3b f0 ff ff       	call   800198 <vcprintf>
	cprintf("\n");
  80115d:	c7 04 24 15 18 80 00 	movl   $0x801815,(%esp)
  801164:	e8 80 f0 ff ff       	call   8001e9 <cprintf>
  801169:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80116c:	cc                   	int3   
  80116d:	eb fd                	jmp    80116c <_panic+0x43>

0080116f <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  80116f:	55                   	push   %ebp
  801170:	89 e5                	mov    %esp,%ebp
  801172:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  801175:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  80117c:	75 3c                	jne    8011ba <set_pgfault_handler+0x4b>
		
		if ((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE),PTE_U|PTE_P|PTE_W)) < 0)
  80117e:	83 ec 04             	sub    $0x4,%esp
  801181:	6a 07                	push   $0x7
  801183:	68 00 f0 bf ee       	push   $0xeebff000
  801188:	6a 00                	push   $0x0
  80118a:	e8 61 fa ff ff       	call   800bf0 <sys_page_alloc>
  80118f:	83 c4 10             	add    $0x10,%esp
  801192:	85 c0                	test   %eax,%eax
  801194:	79 12                	jns    8011a8 <set_pgfault_handler+0x39>
		panic("sys_page_alloc: %e", r);
  801196:	50                   	push   %eax
  801197:	68 a4 18 80 00       	push   $0x8018a4
  80119c:	6a 20                	push   $0x20
  80119e:	68 b7 18 80 00       	push   $0x8018b7
  8011a3:	e8 81 ff ff ff       	call   801129 <_panic>
	    sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  8011a8:	83 ec 08             	sub    $0x8,%esp
  8011ab:	68 c4 11 80 00       	push   $0x8011c4
  8011b0:	6a 00                	push   $0x0
  8011b2:	e8 42 fb ff ff       	call   800cf9 <sys_env_set_pgfault_upcall>
  8011b7:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8011ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8011bd:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  8011c2:	c9                   	leave  
  8011c3:	c3                   	ret    

008011c4 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8011c4:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8011c5:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  8011ca:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8011cc:	83 c4 04             	add    $0x4,%esp
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
    
    //trap time eip
	movl 0x28(%esp), %eax
  8011cf:	8b 44 24 28          	mov    0x28(%esp),%eax

	//current stack we need it afterwards to pop registers al
	movl %esp, %ebp
  8011d3:	89 e5                	mov    %esp,%ebp

	//switch to user stack where faulitng va occured
	movl 0x30(%esp), %esp
  8011d5:	8b 64 24 30          	mov    0x30(%esp),%esp

	// Push trap-time eip to the user stack 
	pushl %eax
  8011d9:	50                   	push   %eax

	// SAve the user stack esp again for latter use after popping general purpose registers
	movl %esp, 0x30(%ebp)
  8011da:	89 65 30             	mov    %esp,0x30(%ebp)

	// Now again go to the user trap frame
	movl %ebp, %esp
  8011dd:	89 ec                	mov    %ebp,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	
	// ignore faut  va and err	
	addl $8, %esp
  8011df:	83 c4 08             	add    $0x8,%esp

	// Pop all registers back
	popal
  8011e2:	61                   	popa   
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

	// Skip %eip
	addl $0x4, %esp
  8011e3:	83 c4 04             	add    $0x4,%esp

	// Pop eflags back
	popfl
  8011e6:	9d                   	popf   

	// Go to user stack now
	// LAB 4: Your code here.

	popl %esp
  8011e7:	5c                   	pop    %esp


	// LAB 4: Your code here.

	ret
  8011e8:	c3                   	ret    
  8011e9:	66 90                	xchg   %ax,%ax
  8011eb:	66 90                	xchg   %ax,%ax
  8011ed:	66 90                	xchg   %ax,%ax
  8011ef:	90                   	nop

008011f0 <__udivdi3>:
  8011f0:	55                   	push   %ebp
  8011f1:	57                   	push   %edi
  8011f2:	56                   	push   %esi
  8011f3:	53                   	push   %ebx
  8011f4:	83 ec 1c             	sub    $0x1c,%esp
  8011f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  8011fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  8011ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801203:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801207:	85 f6                	test   %esi,%esi
  801209:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80120d:	89 ca                	mov    %ecx,%edx
  80120f:	89 f8                	mov    %edi,%eax
  801211:	75 3d                	jne    801250 <__udivdi3+0x60>
  801213:	39 cf                	cmp    %ecx,%edi
  801215:	0f 87 c5 00 00 00    	ja     8012e0 <__udivdi3+0xf0>
  80121b:	85 ff                	test   %edi,%edi
  80121d:	89 fd                	mov    %edi,%ebp
  80121f:	75 0b                	jne    80122c <__udivdi3+0x3c>
  801221:	b8 01 00 00 00       	mov    $0x1,%eax
  801226:	31 d2                	xor    %edx,%edx
  801228:	f7 f7                	div    %edi
  80122a:	89 c5                	mov    %eax,%ebp
  80122c:	89 c8                	mov    %ecx,%eax
  80122e:	31 d2                	xor    %edx,%edx
  801230:	f7 f5                	div    %ebp
  801232:	89 c1                	mov    %eax,%ecx
  801234:	89 d8                	mov    %ebx,%eax
  801236:	89 cf                	mov    %ecx,%edi
  801238:	f7 f5                	div    %ebp
  80123a:	89 c3                	mov    %eax,%ebx
  80123c:	89 d8                	mov    %ebx,%eax
  80123e:	89 fa                	mov    %edi,%edx
  801240:	83 c4 1c             	add    $0x1c,%esp
  801243:	5b                   	pop    %ebx
  801244:	5e                   	pop    %esi
  801245:	5f                   	pop    %edi
  801246:	5d                   	pop    %ebp
  801247:	c3                   	ret    
  801248:	90                   	nop
  801249:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801250:	39 ce                	cmp    %ecx,%esi
  801252:	77 74                	ja     8012c8 <__udivdi3+0xd8>
  801254:	0f bd fe             	bsr    %esi,%edi
  801257:	83 f7 1f             	xor    $0x1f,%edi
  80125a:	0f 84 98 00 00 00    	je     8012f8 <__udivdi3+0x108>
  801260:	bb 20 00 00 00       	mov    $0x20,%ebx
  801265:	89 f9                	mov    %edi,%ecx
  801267:	89 c5                	mov    %eax,%ebp
  801269:	29 fb                	sub    %edi,%ebx
  80126b:	d3 e6                	shl    %cl,%esi
  80126d:	89 d9                	mov    %ebx,%ecx
  80126f:	d3 ed                	shr    %cl,%ebp
  801271:	89 f9                	mov    %edi,%ecx
  801273:	d3 e0                	shl    %cl,%eax
  801275:	09 ee                	or     %ebp,%esi
  801277:	89 d9                	mov    %ebx,%ecx
  801279:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80127d:	89 d5                	mov    %edx,%ebp
  80127f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801283:	d3 ed                	shr    %cl,%ebp
  801285:	89 f9                	mov    %edi,%ecx
  801287:	d3 e2                	shl    %cl,%edx
  801289:	89 d9                	mov    %ebx,%ecx
  80128b:	d3 e8                	shr    %cl,%eax
  80128d:	09 c2                	or     %eax,%edx
  80128f:	89 d0                	mov    %edx,%eax
  801291:	89 ea                	mov    %ebp,%edx
  801293:	f7 f6                	div    %esi
  801295:	89 d5                	mov    %edx,%ebp
  801297:	89 c3                	mov    %eax,%ebx
  801299:	f7 64 24 0c          	mull   0xc(%esp)
  80129d:	39 d5                	cmp    %edx,%ebp
  80129f:	72 10                	jb     8012b1 <__udivdi3+0xc1>
  8012a1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8012a5:	89 f9                	mov    %edi,%ecx
  8012a7:	d3 e6                	shl    %cl,%esi
  8012a9:	39 c6                	cmp    %eax,%esi
  8012ab:	73 07                	jae    8012b4 <__udivdi3+0xc4>
  8012ad:	39 d5                	cmp    %edx,%ebp
  8012af:	75 03                	jne    8012b4 <__udivdi3+0xc4>
  8012b1:	83 eb 01             	sub    $0x1,%ebx
  8012b4:	31 ff                	xor    %edi,%edi
  8012b6:	89 d8                	mov    %ebx,%eax
  8012b8:	89 fa                	mov    %edi,%edx
  8012ba:	83 c4 1c             	add    $0x1c,%esp
  8012bd:	5b                   	pop    %ebx
  8012be:	5e                   	pop    %esi
  8012bf:	5f                   	pop    %edi
  8012c0:	5d                   	pop    %ebp
  8012c1:	c3                   	ret    
  8012c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8012c8:	31 ff                	xor    %edi,%edi
  8012ca:	31 db                	xor    %ebx,%ebx
  8012cc:	89 d8                	mov    %ebx,%eax
  8012ce:	89 fa                	mov    %edi,%edx
  8012d0:	83 c4 1c             	add    $0x1c,%esp
  8012d3:	5b                   	pop    %ebx
  8012d4:	5e                   	pop    %esi
  8012d5:	5f                   	pop    %edi
  8012d6:	5d                   	pop    %ebp
  8012d7:	c3                   	ret    
  8012d8:	90                   	nop
  8012d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8012e0:	89 d8                	mov    %ebx,%eax
  8012e2:	f7 f7                	div    %edi
  8012e4:	31 ff                	xor    %edi,%edi
  8012e6:	89 c3                	mov    %eax,%ebx
  8012e8:	89 d8                	mov    %ebx,%eax
  8012ea:	89 fa                	mov    %edi,%edx
  8012ec:	83 c4 1c             	add    $0x1c,%esp
  8012ef:	5b                   	pop    %ebx
  8012f0:	5e                   	pop    %esi
  8012f1:	5f                   	pop    %edi
  8012f2:	5d                   	pop    %ebp
  8012f3:	c3                   	ret    
  8012f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012f8:	39 ce                	cmp    %ecx,%esi
  8012fa:	72 0c                	jb     801308 <__udivdi3+0x118>
  8012fc:	31 db                	xor    %ebx,%ebx
  8012fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801302:	0f 87 34 ff ff ff    	ja     80123c <__udivdi3+0x4c>
  801308:	bb 01 00 00 00       	mov    $0x1,%ebx
  80130d:	e9 2a ff ff ff       	jmp    80123c <__udivdi3+0x4c>
  801312:	66 90                	xchg   %ax,%ax
  801314:	66 90                	xchg   %ax,%ax
  801316:	66 90                	xchg   %ax,%ax
  801318:	66 90                	xchg   %ax,%ax
  80131a:	66 90                	xchg   %ax,%ax
  80131c:	66 90                	xchg   %ax,%ax
  80131e:	66 90                	xchg   %ax,%ax

00801320 <__umoddi3>:
  801320:	55                   	push   %ebp
  801321:	57                   	push   %edi
  801322:	56                   	push   %esi
  801323:	53                   	push   %ebx
  801324:	83 ec 1c             	sub    $0x1c,%esp
  801327:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80132b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80132f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801333:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801337:	85 d2                	test   %edx,%edx
  801339:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80133d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801341:	89 f3                	mov    %esi,%ebx
  801343:	89 3c 24             	mov    %edi,(%esp)
  801346:	89 74 24 04          	mov    %esi,0x4(%esp)
  80134a:	75 1c                	jne    801368 <__umoddi3+0x48>
  80134c:	39 f7                	cmp    %esi,%edi
  80134e:	76 50                	jbe    8013a0 <__umoddi3+0x80>
  801350:	89 c8                	mov    %ecx,%eax
  801352:	89 f2                	mov    %esi,%edx
  801354:	f7 f7                	div    %edi
  801356:	89 d0                	mov    %edx,%eax
  801358:	31 d2                	xor    %edx,%edx
  80135a:	83 c4 1c             	add    $0x1c,%esp
  80135d:	5b                   	pop    %ebx
  80135e:	5e                   	pop    %esi
  80135f:	5f                   	pop    %edi
  801360:	5d                   	pop    %ebp
  801361:	c3                   	ret    
  801362:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801368:	39 f2                	cmp    %esi,%edx
  80136a:	89 d0                	mov    %edx,%eax
  80136c:	77 52                	ja     8013c0 <__umoddi3+0xa0>
  80136e:	0f bd ea             	bsr    %edx,%ebp
  801371:	83 f5 1f             	xor    $0x1f,%ebp
  801374:	75 5a                	jne    8013d0 <__umoddi3+0xb0>
  801376:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80137a:	0f 82 e0 00 00 00    	jb     801460 <__umoddi3+0x140>
  801380:	39 0c 24             	cmp    %ecx,(%esp)
  801383:	0f 86 d7 00 00 00    	jbe    801460 <__umoddi3+0x140>
  801389:	8b 44 24 08          	mov    0x8(%esp),%eax
  80138d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801391:	83 c4 1c             	add    $0x1c,%esp
  801394:	5b                   	pop    %ebx
  801395:	5e                   	pop    %esi
  801396:	5f                   	pop    %edi
  801397:	5d                   	pop    %ebp
  801398:	c3                   	ret    
  801399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013a0:	85 ff                	test   %edi,%edi
  8013a2:	89 fd                	mov    %edi,%ebp
  8013a4:	75 0b                	jne    8013b1 <__umoddi3+0x91>
  8013a6:	b8 01 00 00 00       	mov    $0x1,%eax
  8013ab:	31 d2                	xor    %edx,%edx
  8013ad:	f7 f7                	div    %edi
  8013af:	89 c5                	mov    %eax,%ebp
  8013b1:	89 f0                	mov    %esi,%eax
  8013b3:	31 d2                	xor    %edx,%edx
  8013b5:	f7 f5                	div    %ebp
  8013b7:	89 c8                	mov    %ecx,%eax
  8013b9:	f7 f5                	div    %ebp
  8013bb:	89 d0                	mov    %edx,%eax
  8013bd:	eb 99                	jmp    801358 <__umoddi3+0x38>
  8013bf:	90                   	nop
  8013c0:	89 c8                	mov    %ecx,%eax
  8013c2:	89 f2                	mov    %esi,%edx
  8013c4:	83 c4 1c             	add    $0x1c,%esp
  8013c7:	5b                   	pop    %ebx
  8013c8:	5e                   	pop    %esi
  8013c9:	5f                   	pop    %edi
  8013ca:	5d                   	pop    %ebp
  8013cb:	c3                   	ret    
  8013cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013d0:	8b 34 24             	mov    (%esp),%esi
  8013d3:	bf 20 00 00 00       	mov    $0x20,%edi
  8013d8:	89 e9                	mov    %ebp,%ecx
  8013da:	29 ef                	sub    %ebp,%edi
  8013dc:	d3 e0                	shl    %cl,%eax
  8013de:	89 f9                	mov    %edi,%ecx
  8013e0:	89 f2                	mov    %esi,%edx
  8013e2:	d3 ea                	shr    %cl,%edx
  8013e4:	89 e9                	mov    %ebp,%ecx
  8013e6:	09 c2                	or     %eax,%edx
  8013e8:	89 d8                	mov    %ebx,%eax
  8013ea:	89 14 24             	mov    %edx,(%esp)
  8013ed:	89 f2                	mov    %esi,%edx
  8013ef:	d3 e2                	shl    %cl,%edx
  8013f1:	89 f9                	mov    %edi,%ecx
  8013f3:	89 54 24 04          	mov    %edx,0x4(%esp)
  8013f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8013fb:	d3 e8                	shr    %cl,%eax
  8013fd:	89 e9                	mov    %ebp,%ecx
  8013ff:	89 c6                	mov    %eax,%esi
  801401:	d3 e3                	shl    %cl,%ebx
  801403:	89 f9                	mov    %edi,%ecx
  801405:	89 d0                	mov    %edx,%eax
  801407:	d3 e8                	shr    %cl,%eax
  801409:	89 e9                	mov    %ebp,%ecx
  80140b:	09 d8                	or     %ebx,%eax
  80140d:	89 d3                	mov    %edx,%ebx
  80140f:	89 f2                	mov    %esi,%edx
  801411:	f7 34 24             	divl   (%esp)
  801414:	89 d6                	mov    %edx,%esi
  801416:	d3 e3                	shl    %cl,%ebx
  801418:	f7 64 24 04          	mull   0x4(%esp)
  80141c:	39 d6                	cmp    %edx,%esi
  80141e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801422:	89 d1                	mov    %edx,%ecx
  801424:	89 c3                	mov    %eax,%ebx
  801426:	72 08                	jb     801430 <__umoddi3+0x110>
  801428:	75 11                	jne    80143b <__umoddi3+0x11b>
  80142a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80142e:	73 0b                	jae    80143b <__umoddi3+0x11b>
  801430:	2b 44 24 04          	sub    0x4(%esp),%eax
  801434:	1b 14 24             	sbb    (%esp),%edx
  801437:	89 d1                	mov    %edx,%ecx
  801439:	89 c3                	mov    %eax,%ebx
  80143b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80143f:	29 da                	sub    %ebx,%edx
  801441:	19 ce                	sbb    %ecx,%esi
  801443:	89 f9                	mov    %edi,%ecx
  801445:	89 f0                	mov    %esi,%eax
  801447:	d3 e0                	shl    %cl,%eax
  801449:	89 e9                	mov    %ebp,%ecx
  80144b:	d3 ea                	shr    %cl,%edx
  80144d:	89 e9                	mov    %ebp,%ecx
  80144f:	d3 ee                	shr    %cl,%esi
  801451:	09 d0                	or     %edx,%eax
  801453:	89 f2                	mov    %esi,%edx
  801455:	83 c4 1c             	add    $0x1c,%esp
  801458:	5b                   	pop    %ebx
  801459:	5e                   	pop    %esi
  80145a:	5f                   	pop    %edi
  80145b:	5d                   	pop    %ebp
  80145c:	c3                   	ret    
  80145d:	8d 76 00             	lea    0x0(%esi),%esi
  801460:	29 f9                	sub    %edi,%ecx
  801462:	19 d6                	sbb    %edx,%esi
  801464:	89 74 24 04          	mov    %esi,0x4(%esp)
  801468:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80146c:	e9 18 ff ff ff       	jmp    801389 <__umoddi3+0x69>
