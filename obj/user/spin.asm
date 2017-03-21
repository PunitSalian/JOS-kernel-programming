
obj/user/spin:     file format elf32-i386


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
  80002c:	e8 84 00 00 00       	call   8000b5 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	53                   	push   %ebx
  800037:	83 ec 10             	sub    $0x10,%esp
	envid_t env;

	cprintf("I am the parent.  Forking the child...\n");
  80003a:	68 40 13 80 00       	push   $0x801340
  80003f:	e8 5c 01 00 00       	call   8001a0 <cprintf>
	if ((env = fork()) == 0) {
  800044:	e8 cd 0d 00 00       	call   800e16 <fork>
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	85 c0                	test   %eax,%eax
  80004e:	75 12                	jne    800062 <umain+0x2f>
		cprintf("I am the child.  Spinning...\n");
  800050:	83 ec 0c             	sub    $0xc,%esp
  800053:	68 b8 13 80 00       	push   $0x8013b8
  800058:	e8 43 01 00 00       	call   8001a0 <cprintf>
  80005d:	83 c4 10             	add    $0x10,%esp
  800060:	eb fe                	jmp    800060 <umain+0x2d>
  800062:	89 c3                	mov    %eax,%ebx
		while (1)
			/* do nothing */;
	}

	cprintf("I am the parent.  Running the child...\n");
  800064:	83 ec 0c             	sub    $0xc,%esp
  800067:	68 68 13 80 00       	push   $0x801368
  80006c:	e8 2f 01 00 00       	call   8001a0 <cprintf>
	sys_yield();
  800071:	e8 12 0b 00 00       	call   800b88 <sys_yield>
	sys_yield();
  800076:	e8 0d 0b 00 00       	call   800b88 <sys_yield>
	sys_yield();
  80007b:	e8 08 0b 00 00       	call   800b88 <sys_yield>
	sys_yield();
  800080:	e8 03 0b 00 00       	call   800b88 <sys_yield>
	sys_yield();
  800085:	e8 fe 0a 00 00       	call   800b88 <sys_yield>
	sys_yield();
  80008a:	e8 f9 0a 00 00       	call   800b88 <sys_yield>
	sys_yield();
  80008f:	e8 f4 0a 00 00       	call   800b88 <sys_yield>
	sys_yield();
  800094:	e8 ef 0a 00 00       	call   800b88 <sys_yield>

	cprintf("I am the parent.  Killing the child...\n");
  800099:	c7 04 24 90 13 80 00 	movl   $0x801390,(%esp)
  8000a0:	e8 fb 00 00 00       	call   8001a0 <cprintf>
	sys_env_destroy(env);
  8000a5:	89 1c 24             	mov    %ebx,(%esp)
  8000a8:	e8 7b 0a 00 00       	call   800b28 <sys_env_destroy>
}
  8000ad:	83 c4 10             	add    $0x10,%esp
  8000b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000b3:	c9                   	leave  
  8000b4:	c3                   	ret    

008000b5 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000b5:	55                   	push   %ebp
  8000b6:	89 e5                	mov    %esp,%ebp
  8000b8:	56                   	push   %esi
  8000b9:	53                   	push   %ebx
  8000ba:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000bd:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  8000c0:	e8 a4 0a 00 00       	call   800b69 <sys_getenvid>
  8000c5:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000ca:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000cd:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000d2:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000d7:	85 db                	test   %ebx,%ebx
  8000d9:	7e 07                	jle    8000e2 <libmain+0x2d>
		binaryname = argv[0];
  8000db:	8b 06                	mov    (%esi),%eax
  8000dd:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000e2:	83 ec 08             	sub    $0x8,%esp
  8000e5:	56                   	push   %esi
  8000e6:	53                   	push   %ebx
  8000e7:	e8 47 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000ec:	e8 0a 00 00 00       	call   8000fb <exit>
}
  8000f1:	83 c4 10             	add    $0x10,%esp
  8000f4:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000f7:	5b                   	pop    %ebx
  8000f8:	5e                   	pop    %esi
  8000f9:	5d                   	pop    %ebp
  8000fa:	c3                   	ret    

008000fb <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800101:	6a 00                	push   $0x0
  800103:	e8 20 0a 00 00       	call   800b28 <sys_env_destroy>
}
  800108:	83 c4 10             	add    $0x10,%esp
  80010b:	c9                   	leave  
  80010c:	c3                   	ret    

0080010d <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80010d:	55                   	push   %ebp
  80010e:	89 e5                	mov    %esp,%ebp
  800110:	53                   	push   %ebx
  800111:	83 ec 04             	sub    $0x4,%esp
  800114:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800117:	8b 13                	mov    (%ebx),%edx
  800119:	8d 42 01             	lea    0x1(%edx),%eax
  80011c:	89 03                	mov    %eax,(%ebx)
  80011e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800121:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800125:	3d ff 00 00 00       	cmp    $0xff,%eax
  80012a:	75 1a                	jne    800146 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80012c:	83 ec 08             	sub    $0x8,%esp
  80012f:	68 ff 00 00 00       	push   $0xff
  800134:	8d 43 08             	lea    0x8(%ebx),%eax
  800137:	50                   	push   %eax
  800138:	e8 ae 09 00 00       	call   800aeb <sys_cputs>
		b->idx = 0;
  80013d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800143:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800146:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80014a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800158:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80015f:	00 00 00 
	b.cnt = 0;
  800162:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800169:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80016c:	ff 75 0c             	pushl  0xc(%ebp)
  80016f:	ff 75 08             	pushl  0x8(%ebp)
  800172:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800178:	50                   	push   %eax
  800179:	68 0d 01 80 00       	push   $0x80010d
  80017e:	e8 1a 01 00 00       	call   80029d <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800183:	83 c4 08             	add    $0x8,%esp
  800186:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80018c:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800192:	50                   	push   %eax
  800193:	e8 53 09 00 00       	call   800aeb <sys_cputs>

	return b.cnt;
}
  800198:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80019e:	c9                   	leave  
  80019f:	c3                   	ret    

008001a0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001a0:	55                   	push   %ebp
  8001a1:	89 e5                	mov    %esp,%ebp
  8001a3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001a6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001a9:	50                   	push   %eax
  8001aa:	ff 75 08             	pushl  0x8(%ebp)
  8001ad:	e8 9d ff ff ff       	call   80014f <vcprintf>
	va_end(ap);

	return cnt;
}
  8001b2:	c9                   	leave  
  8001b3:	c3                   	ret    

008001b4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001b4:	55                   	push   %ebp
  8001b5:	89 e5                	mov    %esp,%ebp
  8001b7:	57                   	push   %edi
  8001b8:	56                   	push   %esi
  8001b9:	53                   	push   %ebx
  8001ba:	83 ec 1c             	sub    $0x1c,%esp
  8001bd:	89 c7                	mov    %eax,%edi
  8001bf:	89 d6                	mov    %edx,%esi
  8001c1:	8b 45 08             	mov    0x8(%ebp),%eax
  8001c4:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001ca:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001cd:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001d0:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001d5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001d8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001db:	39 d3                	cmp    %edx,%ebx
  8001dd:	72 05                	jb     8001e4 <printnum+0x30>
  8001df:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001e2:	77 45                	ja     800229 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001e4:	83 ec 0c             	sub    $0xc,%esp
  8001e7:	ff 75 18             	pushl  0x18(%ebp)
  8001ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8001ed:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8001f0:	53                   	push   %ebx
  8001f1:	ff 75 10             	pushl  0x10(%ebp)
  8001f4:	83 ec 08             	sub    $0x8,%esp
  8001f7:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001fa:	ff 75 e0             	pushl  -0x20(%ebp)
  8001fd:	ff 75 dc             	pushl  -0x24(%ebp)
  800200:	ff 75 d8             	pushl  -0x28(%ebp)
  800203:	e8 98 0e 00 00       	call   8010a0 <__udivdi3>
  800208:	83 c4 18             	add    $0x18,%esp
  80020b:	52                   	push   %edx
  80020c:	50                   	push   %eax
  80020d:	89 f2                	mov    %esi,%edx
  80020f:	89 f8                	mov    %edi,%eax
  800211:	e8 9e ff ff ff       	call   8001b4 <printnum>
  800216:	83 c4 20             	add    $0x20,%esp
  800219:	eb 18                	jmp    800233 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80021b:	83 ec 08             	sub    $0x8,%esp
  80021e:	56                   	push   %esi
  80021f:	ff 75 18             	pushl  0x18(%ebp)
  800222:	ff d7                	call   *%edi
  800224:	83 c4 10             	add    $0x10,%esp
  800227:	eb 03                	jmp    80022c <printnum+0x78>
  800229:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80022c:	83 eb 01             	sub    $0x1,%ebx
  80022f:	85 db                	test   %ebx,%ebx
  800231:	7f e8                	jg     80021b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800233:	83 ec 08             	sub    $0x8,%esp
  800236:	56                   	push   %esi
  800237:	83 ec 04             	sub    $0x4,%esp
  80023a:	ff 75 e4             	pushl  -0x1c(%ebp)
  80023d:	ff 75 e0             	pushl  -0x20(%ebp)
  800240:	ff 75 dc             	pushl  -0x24(%ebp)
  800243:	ff 75 d8             	pushl  -0x28(%ebp)
  800246:	e8 85 0f 00 00       	call   8011d0 <__umoddi3>
  80024b:	83 c4 14             	add    $0x14,%esp
  80024e:	0f be 80 e0 13 80 00 	movsbl 0x8013e0(%eax),%eax
  800255:	50                   	push   %eax
  800256:	ff d7                	call   *%edi
}
  800258:	83 c4 10             	add    $0x10,%esp
  80025b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80025e:	5b                   	pop    %ebx
  80025f:	5e                   	pop    %esi
  800260:	5f                   	pop    %edi
  800261:	5d                   	pop    %ebp
  800262:	c3                   	ret    

00800263 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800263:	55                   	push   %ebp
  800264:	89 e5                	mov    %esp,%ebp
  800266:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800269:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80026d:	8b 10                	mov    (%eax),%edx
  80026f:	3b 50 04             	cmp    0x4(%eax),%edx
  800272:	73 0a                	jae    80027e <sprintputch+0x1b>
		*b->buf++ = ch;
  800274:	8d 4a 01             	lea    0x1(%edx),%ecx
  800277:	89 08                	mov    %ecx,(%eax)
  800279:	8b 45 08             	mov    0x8(%ebp),%eax
  80027c:	88 02                	mov    %al,(%edx)
}
  80027e:	5d                   	pop    %ebp
  80027f:	c3                   	ret    

00800280 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800286:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800289:	50                   	push   %eax
  80028a:	ff 75 10             	pushl  0x10(%ebp)
  80028d:	ff 75 0c             	pushl  0xc(%ebp)
  800290:	ff 75 08             	pushl  0x8(%ebp)
  800293:	e8 05 00 00 00       	call   80029d <vprintfmt>
	va_end(ap);
}
  800298:	83 c4 10             	add    $0x10,%esp
  80029b:	c9                   	leave  
  80029c:	c3                   	ret    

0080029d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80029d:	55                   	push   %ebp
  80029e:	89 e5                	mov    %esp,%ebp
  8002a0:	57                   	push   %edi
  8002a1:	56                   	push   %esi
  8002a2:	53                   	push   %ebx
  8002a3:	83 ec 2c             	sub    $0x2c,%esp
  8002a6:	8b 75 08             	mov    0x8(%ebp),%esi
  8002a9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002ac:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002af:	eb 12                	jmp    8002c3 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002b1:	85 c0                	test   %eax,%eax
  8002b3:	0f 84 42 04 00 00    	je     8006fb <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8002b9:	83 ec 08             	sub    $0x8,%esp
  8002bc:	53                   	push   %ebx
  8002bd:	50                   	push   %eax
  8002be:	ff d6                	call   *%esi
  8002c0:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002c3:	83 c7 01             	add    $0x1,%edi
  8002c6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002ca:	83 f8 25             	cmp    $0x25,%eax
  8002cd:	75 e2                	jne    8002b1 <vprintfmt+0x14>
  8002cf:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002d3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002da:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002e1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002e8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002ed:	eb 07                	jmp    8002f6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002f2:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f6:	8d 47 01             	lea    0x1(%edi),%eax
  8002f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002fc:	0f b6 07             	movzbl (%edi),%eax
  8002ff:	0f b6 d0             	movzbl %al,%edx
  800302:	83 e8 23             	sub    $0x23,%eax
  800305:	3c 55                	cmp    $0x55,%al
  800307:	0f 87 d3 03 00 00    	ja     8006e0 <vprintfmt+0x443>
  80030d:	0f b6 c0             	movzbl %al,%eax
  800310:	ff 24 85 a0 14 80 00 	jmp    *0x8014a0(,%eax,4)
  800317:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80031a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80031e:	eb d6                	jmp    8002f6 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800320:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800323:	b8 00 00 00 00       	mov    $0x0,%eax
  800328:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80032b:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80032e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800332:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800335:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800338:	83 f9 09             	cmp    $0x9,%ecx
  80033b:	77 3f                	ja     80037c <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80033d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800340:	eb e9                	jmp    80032b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800342:	8b 45 14             	mov    0x14(%ebp),%eax
  800345:	8b 00                	mov    (%eax),%eax
  800347:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80034a:	8b 45 14             	mov    0x14(%ebp),%eax
  80034d:	8d 40 04             	lea    0x4(%eax),%eax
  800350:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800353:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800356:	eb 2a                	jmp    800382 <vprintfmt+0xe5>
  800358:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035b:	85 c0                	test   %eax,%eax
  80035d:	ba 00 00 00 00       	mov    $0x0,%edx
  800362:	0f 49 d0             	cmovns %eax,%edx
  800365:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800368:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80036b:	eb 89                	jmp    8002f6 <vprintfmt+0x59>
  80036d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800370:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800377:	e9 7a ff ff ff       	jmp    8002f6 <vprintfmt+0x59>
  80037c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80037f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800382:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800386:	0f 89 6a ff ff ff    	jns    8002f6 <vprintfmt+0x59>
				width = precision, precision = -1;
  80038c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80038f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800392:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800399:	e9 58 ff ff ff       	jmp    8002f6 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80039e:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003a4:	e9 4d ff ff ff       	jmp    8002f6 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ac:	8d 78 04             	lea    0x4(%eax),%edi
  8003af:	83 ec 08             	sub    $0x8,%esp
  8003b2:	53                   	push   %ebx
  8003b3:	ff 30                	pushl  (%eax)
  8003b5:	ff d6                	call   *%esi
			break;
  8003b7:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003ba:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003c0:	e9 fe fe ff ff       	jmp    8002c3 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c8:	8d 78 04             	lea    0x4(%eax),%edi
  8003cb:	8b 00                	mov    (%eax),%eax
  8003cd:	99                   	cltd   
  8003ce:	31 d0                	xor    %edx,%eax
  8003d0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003d2:	83 f8 08             	cmp    $0x8,%eax
  8003d5:	7f 0b                	jg     8003e2 <vprintfmt+0x145>
  8003d7:	8b 14 85 00 16 80 00 	mov    0x801600(,%eax,4),%edx
  8003de:	85 d2                	test   %edx,%edx
  8003e0:	75 1b                	jne    8003fd <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  8003e2:	50                   	push   %eax
  8003e3:	68 f8 13 80 00       	push   $0x8013f8
  8003e8:	53                   	push   %ebx
  8003e9:	56                   	push   %esi
  8003ea:	e8 91 fe ff ff       	call   800280 <printfmt>
  8003ef:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003f2:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003f8:	e9 c6 fe ff ff       	jmp    8002c3 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003fd:	52                   	push   %edx
  8003fe:	68 01 14 80 00       	push   $0x801401
  800403:	53                   	push   %ebx
  800404:	56                   	push   %esi
  800405:	e8 76 fe ff ff       	call   800280 <printfmt>
  80040a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80040d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800410:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800413:	e9 ab fe ff ff       	jmp    8002c3 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800418:	8b 45 14             	mov    0x14(%ebp),%eax
  80041b:	83 c0 04             	add    $0x4,%eax
  80041e:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800421:	8b 45 14             	mov    0x14(%ebp),%eax
  800424:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800426:	85 ff                	test   %edi,%edi
  800428:	b8 f1 13 80 00       	mov    $0x8013f1,%eax
  80042d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800430:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800434:	0f 8e 94 00 00 00    	jle    8004ce <vprintfmt+0x231>
  80043a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80043e:	0f 84 98 00 00 00    	je     8004dc <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800444:	83 ec 08             	sub    $0x8,%esp
  800447:	ff 75 d0             	pushl  -0x30(%ebp)
  80044a:	57                   	push   %edi
  80044b:	e8 33 03 00 00       	call   800783 <strnlen>
  800450:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800453:	29 c1                	sub    %eax,%ecx
  800455:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800458:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80045b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80045f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800462:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800465:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800467:	eb 0f                	jmp    800478 <vprintfmt+0x1db>
					putch(padc, putdat);
  800469:	83 ec 08             	sub    $0x8,%esp
  80046c:	53                   	push   %ebx
  80046d:	ff 75 e0             	pushl  -0x20(%ebp)
  800470:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800472:	83 ef 01             	sub    $0x1,%edi
  800475:	83 c4 10             	add    $0x10,%esp
  800478:	85 ff                	test   %edi,%edi
  80047a:	7f ed                	jg     800469 <vprintfmt+0x1cc>
  80047c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80047f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800482:	85 c9                	test   %ecx,%ecx
  800484:	b8 00 00 00 00       	mov    $0x0,%eax
  800489:	0f 49 c1             	cmovns %ecx,%eax
  80048c:	29 c1                	sub    %eax,%ecx
  80048e:	89 75 08             	mov    %esi,0x8(%ebp)
  800491:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800494:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800497:	89 cb                	mov    %ecx,%ebx
  800499:	eb 4d                	jmp    8004e8 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80049b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80049f:	74 1b                	je     8004bc <vprintfmt+0x21f>
  8004a1:	0f be c0             	movsbl %al,%eax
  8004a4:	83 e8 20             	sub    $0x20,%eax
  8004a7:	83 f8 5e             	cmp    $0x5e,%eax
  8004aa:	76 10                	jbe    8004bc <vprintfmt+0x21f>
					putch('?', putdat);
  8004ac:	83 ec 08             	sub    $0x8,%esp
  8004af:	ff 75 0c             	pushl  0xc(%ebp)
  8004b2:	6a 3f                	push   $0x3f
  8004b4:	ff 55 08             	call   *0x8(%ebp)
  8004b7:	83 c4 10             	add    $0x10,%esp
  8004ba:	eb 0d                	jmp    8004c9 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8004bc:	83 ec 08             	sub    $0x8,%esp
  8004bf:	ff 75 0c             	pushl  0xc(%ebp)
  8004c2:	52                   	push   %edx
  8004c3:	ff 55 08             	call   *0x8(%ebp)
  8004c6:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004c9:	83 eb 01             	sub    $0x1,%ebx
  8004cc:	eb 1a                	jmp    8004e8 <vprintfmt+0x24b>
  8004ce:	89 75 08             	mov    %esi,0x8(%ebp)
  8004d1:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004d4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004d7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004da:	eb 0c                	jmp    8004e8 <vprintfmt+0x24b>
  8004dc:	89 75 08             	mov    %esi,0x8(%ebp)
  8004df:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004e2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e8:	83 c7 01             	add    $0x1,%edi
  8004eb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004ef:	0f be d0             	movsbl %al,%edx
  8004f2:	85 d2                	test   %edx,%edx
  8004f4:	74 23                	je     800519 <vprintfmt+0x27c>
  8004f6:	85 f6                	test   %esi,%esi
  8004f8:	78 a1                	js     80049b <vprintfmt+0x1fe>
  8004fa:	83 ee 01             	sub    $0x1,%esi
  8004fd:	79 9c                	jns    80049b <vprintfmt+0x1fe>
  8004ff:	89 df                	mov    %ebx,%edi
  800501:	8b 75 08             	mov    0x8(%ebp),%esi
  800504:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800507:	eb 18                	jmp    800521 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800509:	83 ec 08             	sub    $0x8,%esp
  80050c:	53                   	push   %ebx
  80050d:	6a 20                	push   $0x20
  80050f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800511:	83 ef 01             	sub    $0x1,%edi
  800514:	83 c4 10             	add    $0x10,%esp
  800517:	eb 08                	jmp    800521 <vprintfmt+0x284>
  800519:	89 df                	mov    %ebx,%edi
  80051b:	8b 75 08             	mov    0x8(%ebp),%esi
  80051e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800521:	85 ff                	test   %edi,%edi
  800523:	7f e4                	jg     800509 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800525:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800528:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80052e:	e9 90 fd ff ff       	jmp    8002c3 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800533:	83 f9 01             	cmp    $0x1,%ecx
  800536:	7e 19                	jle    800551 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800538:	8b 45 14             	mov    0x14(%ebp),%eax
  80053b:	8b 50 04             	mov    0x4(%eax),%edx
  80053e:	8b 00                	mov    (%eax),%eax
  800540:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800543:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800546:	8b 45 14             	mov    0x14(%ebp),%eax
  800549:	8d 40 08             	lea    0x8(%eax),%eax
  80054c:	89 45 14             	mov    %eax,0x14(%ebp)
  80054f:	eb 38                	jmp    800589 <vprintfmt+0x2ec>
	else if (lflag)
  800551:	85 c9                	test   %ecx,%ecx
  800553:	74 1b                	je     800570 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800555:	8b 45 14             	mov    0x14(%ebp),%eax
  800558:	8b 00                	mov    (%eax),%eax
  80055a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80055d:	89 c1                	mov    %eax,%ecx
  80055f:	c1 f9 1f             	sar    $0x1f,%ecx
  800562:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800565:	8b 45 14             	mov    0x14(%ebp),%eax
  800568:	8d 40 04             	lea    0x4(%eax),%eax
  80056b:	89 45 14             	mov    %eax,0x14(%ebp)
  80056e:	eb 19                	jmp    800589 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800570:	8b 45 14             	mov    0x14(%ebp),%eax
  800573:	8b 00                	mov    (%eax),%eax
  800575:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800578:	89 c1                	mov    %eax,%ecx
  80057a:	c1 f9 1f             	sar    $0x1f,%ecx
  80057d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800580:	8b 45 14             	mov    0x14(%ebp),%eax
  800583:	8d 40 04             	lea    0x4(%eax),%eax
  800586:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800589:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80058c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80058f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800594:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800598:	0f 89 0e 01 00 00    	jns    8006ac <vprintfmt+0x40f>
				putch('-', putdat);
  80059e:	83 ec 08             	sub    $0x8,%esp
  8005a1:	53                   	push   %ebx
  8005a2:	6a 2d                	push   $0x2d
  8005a4:	ff d6                	call   *%esi
				num = -(long long) num;
  8005a6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005a9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005ac:	f7 da                	neg    %edx
  8005ae:	83 d1 00             	adc    $0x0,%ecx
  8005b1:	f7 d9                	neg    %ecx
  8005b3:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8005b6:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005bb:	e9 ec 00 00 00       	jmp    8006ac <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c0:	83 f9 01             	cmp    $0x1,%ecx
  8005c3:	7e 18                	jle    8005dd <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  8005c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c8:	8b 10                	mov    (%eax),%edx
  8005ca:	8b 48 04             	mov    0x4(%eax),%ecx
  8005cd:	8d 40 08             	lea    0x8(%eax),%eax
  8005d0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005d3:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005d8:	e9 cf 00 00 00       	jmp    8006ac <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8005dd:	85 c9                	test   %ecx,%ecx
  8005df:	74 1a                	je     8005fb <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  8005e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e4:	8b 10                	mov    (%eax),%edx
  8005e6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005eb:	8d 40 04             	lea    0x4(%eax),%eax
  8005ee:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005f1:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005f6:	e9 b1 00 00 00       	jmp    8006ac <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fe:	8b 10                	mov    (%eax),%edx
  800600:	b9 00 00 00 00       	mov    $0x0,%ecx
  800605:	8d 40 04             	lea    0x4(%eax),%eax
  800608:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80060b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800610:	e9 97 00 00 00       	jmp    8006ac <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800615:	83 ec 08             	sub    $0x8,%esp
  800618:	53                   	push   %ebx
  800619:	6a 58                	push   $0x58
  80061b:	ff d6                	call   *%esi
			putch('X', putdat);
  80061d:	83 c4 08             	add    $0x8,%esp
  800620:	53                   	push   %ebx
  800621:	6a 58                	push   $0x58
  800623:	ff d6                	call   *%esi
			putch('X', putdat);
  800625:	83 c4 08             	add    $0x8,%esp
  800628:	53                   	push   %ebx
  800629:	6a 58                	push   $0x58
  80062b:	ff d6                	call   *%esi
			break;
  80062d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800630:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800633:	e9 8b fc ff ff       	jmp    8002c3 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800638:	83 ec 08             	sub    $0x8,%esp
  80063b:	53                   	push   %ebx
  80063c:	6a 30                	push   $0x30
  80063e:	ff d6                	call   *%esi
			putch('x', putdat);
  800640:	83 c4 08             	add    $0x8,%esp
  800643:	53                   	push   %ebx
  800644:	6a 78                	push   $0x78
  800646:	ff d6                	call   *%esi
			num = (unsigned long long)
  800648:	8b 45 14             	mov    0x14(%ebp),%eax
  80064b:	8b 10                	mov    (%eax),%edx
  80064d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800652:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800655:	8d 40 04             	lea    0x4(%eax),%eax
  800658:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80065b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800660:	eb 4a                	jmp    8006ac <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800662:	83 f9 01             	cmp    $0x1,%ecx
  800665:	7e 15                	jle    80067c <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800667:	8b 45 14             	mov    0x14(%ebp),%eax
  80066a:	8b 10                	mov    (%eax),%edx
  80066c:	8b 48 04             	mov    0x4(%eax),%ecx
  80066f:	8d 40 08             	lea    0x8(%eax),%eax
  800672:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800675:	b8 10 00 00 00       	mov    $0x10,%eax
  80067a:	eb 30                	jmp    8006ac <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80067c:	85 c9                	test   %ecx,%ecx
  80067e:	74 17                	je     800697 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800680:	8b 45 14             	mov    0x14(%ebp),%eax
  800683:	8b 10                	mov    (%eax),%edx
  800685:	b9 00 00 00 00       	mov    $0x0,%ecx
  80068a:	8d 40 04             	lea    0x4(%eax),%eax
  80068d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800690:	b8 10 00 00 00       	mov    $0x10,%eax
  800695:	eb 15                	jmp    8006ac <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800697:	8b 45 14             	mov    0x14(%ebp),%eax
  80069a:	8b 10                	mov    (%eax),%edx
  80069c:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006a1:	8d 40 04             	lea    0x4(%eax),%eax
  8006a4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006a7:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006ac:	83 ec 0c             	sub    $0xc,%esp
  8006af:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006b3:	57                   	push   %edi
  8006b4:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b7:	50                   	push   %eax
  8006b8:	51                   	push   %ecx
  8006b9:	52                   	push   %edx
  8006ba:	89 da                	mov    %ebx,%edx
  8006bc:	89 f0                	mov    %esi,%eax
  8006be:	e8 f1 fa ff ff       	call   8001b4 <printnum>
			break;
  8006c3:	83 c4 20             	add    $0x20,%esp
  8006c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006c9:	e9 f5 fb ff ff       	jmp    8002c3 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ce:	83 ec 08             	sub    $0x8,%esp
  8006d1:	53                   	push   %ebx
  8006d2:	52                   	push   %edx
  8006d3:	ff d6                	call   *%esi
			break;
  8006d5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006db:	e9 e3 fb ff ff       	jmp    8002c3 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006e0:	83 ec 08             	sub    $0x8,%esp
  8006e3:	53                   	push   %ebx
  8006e4:	6a 25                	push   $0x25
  8006e6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006e8:	83 c4 10             	add    $0x10,%esp
  8006eb:	eb 03                	jmp    8006f0 <vprintfmt+0x453>
  8006ed:	83 ef 01             	sub    $0x1,%edi
  8006f0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006f4:	75 f7                	jne    8006ed <vprintfmt+0x450>
  8006f6:	e9 c8 fb ff ff       	jmp    8002c3 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006fe:	5b                   	pop    %ebx
  8006ff:	5e                   	pop    %esi
  800700:	5f                   	pop    %edi
  800701:	5d                   	pop    %ebp
  800702:	c3                   	ret    

00800703 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800703:	55                   	push   %ebp
  800704:	89 e5                	mov    %esp,%ebp
  800706:	83 ec 18             	sub    $0x18,%esp
  800709:	8b 45 08             	mov    0x8(%ebp),%eax
  80070c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80070f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800712:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800716:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800719:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800720:	85 c0                	test   %eax,%eax
  800722:	74 26                	je     80074a <vsnprintf+0x47>
  800724:	85 d2                	test   %edx,%edx
  800726:	7e 22                	jle    80074a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800728:	ff 75 14             	pushl  0x14(%ebp)
  80072b:	ff 75 10             	pushl  0x10(%ebp)
  80072e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800731:	50                   	push   %eax
  800732:	68 63 02 80 00       	push   $0x800263
  800737:	e8 61 fb ff ff       	call   80029d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80073c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80073f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800742:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800745:	83 c4 10             	add    $0x10,%esp
  800748:	eb 05                	jmp    80074f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80074a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80074f:	c9                   	leave  
  800750:	c3                   	ret    

00800751 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800751:	55                   	push   %ebp
  800752:	89 e5                	mov    %esp,%ebp
  800754:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800757:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80075a:	50                   	push   %eax
  80075b:	ff 75 10             	pushl  0x10(%ebp)
  80075e:	ff 75 0c             	pushl  0xc(%ebp)
  800761:	ff 75 08             	pushl  0x8(%ebp)
  800764:	e8 9a ff ff ff       	call   800703 <vsnprintf>
	va_end(ap);

	return rc;
}
  800769:	c9                   	leave  
  80076a:	c3                   	ret    

0080076b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800771:	b8 00 00 00 00       	mov    $0x0,%eax
  800776:	eb 03                	jmp    80077b <strlen+0x10>
		n++;
  800778:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80077b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80077f:	75 f7                	jne    800778 <strlen+0xd>
		n++;
	return n;
}
  800781:	5d                   	pop    %ebp
  800782:	c3                   	ret    

00800783 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800783:	55                   	push   %ebp
  800784:	89 e5                	mov    %esp,%ebp
  800786:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800789:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078c:	ba 00 00 00 00       	mov    $0x0,%edx
  800791:	eb 03                	jmp    800796 <strnlen+0x13>
		n++;
  800793:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800796:	39 c2                	cmp    %eax,%edx
  800798:	74 08                	je     8007a2 <strnlen+0x1f>
  80079a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80079e:	75 f3                	jne    800793 <strnlen+0x10>
  8007a0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007a2:	5d                   	pop    %ebp
  8007a3:	c3                   	ret    

008007a4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007a4:	55                   	push   %ebp
  8007a5:	89 e5                	mov    %esp,%ebp
  8007a7:	53                   	push   %ebx
  8007a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007ae:	89 c2                	mov    %eax,%edx
  8007b0:	83 c2 01             	add    $0x1,%edx
  8007b3:	83 c1 01             	add    $0x1,%ecx
  8007b6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007ba:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007bd:	84 db                	test   %bl,%bl
  8007bf:	75 ef                	jne    8007b0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007c1:	5b                   	pop    %ebx
  8007c2:	5d                   	pop    %ebp
  8007c3:	c3                   	ret    

008007c4 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007c4:	55                   	push   %ebp
  8007c5:	89 e5                	mov    %esp,%ebp
  8007c7:	53                   	push   %ebx
  8007c8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007cb:	53                   	push   %ebx
  8007cc:	e8 9a ff ff ff       	call   80076b <strlen>
  8007d1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007d4:	ff 75 0c             	pushl  0xc(%ebp)
  8007d7:	01 d8                	add    %ebx,%eax
  8007d9:	50                   	push   %eax
  8007da:	e8 c5 ff ff ff       	call   8007a4 <strcpy>
	return dst;
}
  8007df:	89 d8                	mov    %ebx,%eax
  8007e1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007e4:	c9                   	leave  
  8007e5:	c3                   	ret    

008007e6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e6:	55                   	push   %ebp
  8007e7:	89 e5                	mov    %esp,%ebp
  8007e9:	56                   	push   %esi
  8007ea:	53                   	push   %ebx
  8007eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007f1:	89 f3                	mov    %esi,%ebx
  8007f3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f6:	89 f2                	mov    %esi,%edx
  8007f8:	eb 0f                	jmp    800809 <strncpy+0x23>
		*dst++ = *src;
  8007fa:	83 c2 01             	add    $0x1,%edx
  8007fd:	0f b6 01             	movzbl (%ecx),%eax
  800800:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800803:	80 39 01             	cmpb   $0x1,(%ecx)
  800806:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800809:	39 da                	cmp    %ebx,%edx
  80080b:	75 ed                	jne    8007fa <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80080d:	89 f0                	mov    %esi,%eax
  80080f:	5b                   	pop    %ebx
  800810:	5e                   	pop    %esi
  800811:	5d                   	pop    %ebp
  800812:	c3                   	ret    

00800813 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800813:	55                   	push   %ebp
  800814:	89 e5                	mov    %esp,%ebp
  800816:	56                   	push   %esi
  800817:	53                   	push   %ebx
  800818:	8b 75 08             	mov    0x8(%ebp),%esi
  80081b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80081e:	8b 55 10             	mov    0x10(%ebp),%edx
  800821:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800823:	85 d2                	test   %edx,%edx
  800825:	74 21                	je     800848 <strlcpy+0x35>
  800827:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80082b:	89 f2                	mov    %esi,%edx
  80082d:	eb 09                	jmp    800838 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80082f:	83 c2 01             	add    $0x1,%edx
  800832:	83 c1 01             	add    $0x1,%ecx
  800835:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800838:	39 c2                	cmp    %eax,%edx
  80083a:	74 09                	je     800845 <strlcpy+0x32>
  80083c:	0f b6 19             	movzbl (%ecx),%ebx
  80083f:	84 db                	test   %bl,%bl
  800841:	75 ec                	jne    80082f <strlcpy+0x1c>
  800843:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800845:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800848:	29 f0                	sub    %esi,%eax
}
  80084a:	5b                   	pop    %ebx
  80084b:	5e                   	pop    %esi
  80084c:	5d                   	pop    %ebp
  80084d:	c3                   	ret    

0080084e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80084e:	55                   	push   %ebp
  80084f:	89 e5                	mov    %esp,%ebp
  800851:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800854:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800857:	eb 06                	jmp    80085f <strcmp+0x11>
		p++, q++;
  800859:	83 c1 01             	add    $0x1,%ecx
  80085c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80085f:	0f b6 01             	movzbl (%ecx),%eax
  800862:	84 c0                	test   %al,%al
  800864:	74 04                	je     80086a <strcmp+0x1c>
  800866:	3a 02                	cmp    (%edx),%al
  800868:	74 ef                	je     800859 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80086a:	0f b6 c0             	movzbl %al,%eax
  80086d:	0f b6 12             	movzbl (%edx),%edx
  800870:	29 d0                	sub    %edx,%eax
}
  800872:	5d                   	pop    %ebp
  800873:	c3                   	ret    

00800874 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800874:	55                   	push   %ebp
  800875:	89 e5                	mov    %esp,%ebp
  800877:	53                   	push   %ebx
  800878:	8b 45 08             	mov    0x8(%ebp),%eax
  80087b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087e:	89 c3                	mov    %eax,%ebx
  800880:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800883:	eb 06                	jmp    80088b <strncmp+0x17>
		n--, p++, q++;
  800885:	83 c0 01             	add    $0x1,%eax
  800888:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80088b:	39 d8                	cmp    %ebx,%eax
  80088d:	74 15                	je     8008a4 <strncmp+0x30>
  80088f:	0f b6 08             	movzbl (%eax),%ecx
  800892:	84 c9                	test   %cl,%cl
  800894:	74 04                	je     80089a <strncmp+0x26>
  800896:	3a 0a                	cmp    (%edx),%cl
  800898:	74 eb                	je     800885 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80089a:	0f b6 00             	movzbl (%eax),%eax
  80089d:	0f b6 12             	movzbl (%edx),%edx
  8008a0:	29 d0                	sub    %edx,%eax
  8008a2:	eb 05                	jmp    8008a9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008a4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008a9:	5b                   	pop    %ebx
  8008aa:	5d                   	pop    %ebp
  8008ab:	c3                   	ret    

008008ac <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008ac:	55                   	push   %ebp
  8008ad:	89 e5                	mov    %esp,%ebp
  8008af:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b6:	eb 07                	jmp    8008bf <strchr+0x13>
		if (*s == c)
  8008b8:	38 ca                	cmp    %cl,%dl
  8008ba:	74 0f                	je     8008cb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008bc:	83 c0 01             	add    $0x1,%eax
  8008bf:	0f b6 10             	movzbl (%eax),%edx
  8008c2:	84 d2                	test   %dl,%dl
  8008c4:	75 f2                	jne    8008b8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008cb:	5d                   	pop    %ebp
  8008cc:	c3                   	ret    

008008cd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008cd:	55                   	push   %ebp
  8008ce:	89 e5                	mov    %esp,%ebp
  8008d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d7:	eb 03                	jmp    8008dc <strfind+0xf>
  8008d9:	83 c0 01             	add    $0x1,%eax
  8008dc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008df:	38 ca                	cmp    %cl,%dl
  8008e1:	74 04                	je     8008e7 <strfind+0x1a>
  8008e3:	84 d2                	test   %dl,%dl
  8008e5:	75 f2                	jne    8008d9 <strfind+0xc>
			break;
	return (char *) s;
}
  8008e7:	5d                   	pop    %ebp
  8008e8:	c3                   	ret    

008008e9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e9:	55                   	push   %ebp
  8008ea:	89 e5                	mov    %esp,%ebp
  8008ec:	57                   	push   %edi
  8008ed:	56                   	push   %esi
  8008ee:	53                   	push   %ebx
  8008ef:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008f2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008f5:	85 c9                	test   %ecx,%ecx
  8008f7:	74 36                	je     80092f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008f9:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ff:	75 28                	jne    800929 <memset+0x40>
  800901:	f6 c1 03             	test   $0x3,%cl
  800904:	75 23                	jne    800929 <memset+0x40>
		c &= 0xFF;
  800906:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80090a:	89 d3                	mov    %edx,%ebx
  80090c:	c1 e3 08             	shl    $0x8,%ebx
  80090f:	89 d6                	mov    %edx,%esi
  800911:	c1 e6 18             	shl    $0x18,%esi
  800914:	89 d0                	mov    %edx,%eax
  800916:	c1 e0 10             	shl    $0x10,%eax
  800919:	09 f0                	or     %esi,%eax
  80091b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80091d:	89 d8                	mov    %ebx,%eax
  80091f:	09 d0                	or     %edx,%eax
  800921:	c1 e9 02             	shr    $0x2,%ecx
  800924:	fc                   	cld    
  800925:	f3 ab                	rep stos %eax,%es:(%edi)
  800927:	eb 06                	jmp    80092f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800929:	8b 45 0c             	mov    0xc(%ebp),%eax
  80092c:	fc                   	cld    
  80092d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80092f:	89 f8                	mov    %edi,%eax
  800931:	5b                   	pop    %ebx
  800932:	5e                   	pop    %esi
  800933:	5f                   	pop    %edi
  800934:	5d                   	pop    %ebp
  800935:	c3                   	ret    

00800936 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800936:	55                   	push   %ebp
  800937:	89 e5                	mov    %esp,%ebp
  800939:	57                   	push   %edi
  80093a:	56                   	push   %esi
  80093b:	8b 45 08             	mov    0x8(%ebp),%eax
  80093e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800941:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800944:	39 c6                	cmp    %eax,%esi
  800946:	73 35                	jae    80097d <memmove+0x47>
  800948:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80094b:	39 d0                	cmp    %edx,%eax
  80094d:	73 2e                	jae    80097d <memmove+0x47>
		s += n;
		d += n;
  80094f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800952:	89 d6                	mov    %edx,%esi
  800954:	09 fe                	or     %edi,%esi
  800956:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80095c:	75 13                	jne    800971 <memmove+0x3b>
  80095e:	f6 c1 03             	test   $0x3,%cl
  800961:	75 0e                	jne    800971 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800963:	83 ef 04             	sub    $0x4,%edi
  800966:	8d 72 fc             	lea    -0x4(%edx),%esi
  800969:	c1 e9 02             	shr    $0x2,%ecx
  80096c:	fd                   	std    
  80096d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80096f:	eb 09                	jmp    80097a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800971:	83 ef 01             	sub    $0x1,%edi
  800974:	8d 72 ff             	lea    -0x1(%edx),%esi
  800977:	fd                   	std    
  800978:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80097a:	fc                   	cld    
  80097b:	eb 1d                	jmp    80099a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80097d:	89 f2                	mov    %esi,%edx
  80097f:	09 c2                	or     %eax,%edx
  800981:	f6 c2 03             	test   $0x3,%dl
  800984:	75 0f                	jne    800995 <memmove+0x5f>
  800986:	f6 c1 03             	test   $0x3,%cl
  800989:	75 0a                	jne    800995 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80098b:	c1 e9 02             	shr    $0x2,%ecx
  80098e:	89 c7                	mov    %eax,%edi
  800990:	fc                   	cld    
  800991:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800993:	eb 05                	jmp    80099a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800995:	89 c7                	mov    %eax,%edi
  800997:	fc                   	cld    
  800998:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80099a:	5e                   	pop    %esi
  80099b:	5f                   	pop    %edi
  80099c:	5d                   	pop    %ebp
  80099d:	c3                   	ret    

0080099e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80099e:	55                   	push   %ebp
  80099f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009a1:	ff 75 10             	pushl  0x10(%ebp)
  8009a4:	ff 75 0c             	pushl  0xc(%ebp)
  8009a7:	ff 75 08             	pushl  0x8(%ebp)
  8009aa:	e8 87 ff ff ff       	call   800936 <memmove>
}
  8009af:	c9                   	leave  
  8009b0:	c3                   	ret    

008009b1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009b1:	55                   	push   %ebp
  8009b2:	89 e5                	mov    %esp,%ebp
  8009b4:	56                   	push   %esi
  8009b5:	53                   	push   %ebx
  8009b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bc:	89 c6                	mov    %eax,%esi
  8009be:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c1:	eb 1a                	jmp    8009dd <memcmp+0x2c>
		if (*s1 != *s2)
  8009c3:	0f b6 08             	movzbl (%eax),%ecx
  8009c6:	0f b6 1a             	movzbl (%edx),%ebx
  8009c9:	38 d9                	cmp    %bl,%cl
  8009cb:	74 0a                	je     8009d7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009cd:	0f b6 c1             	movzbl %cl,%eax
  8009d0:	0f b6 db             	movzbl %bl,%ebx
  8009d3:	29 d8                	sub    %ebx,%eax
  8009d5:	eb 0f                	jmp    8009e6 <memcmp+0x35>
		s1++, s2++;
  8009d7:	83 c0 01             	add    $0x1,%eax
  8009da:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009dd:	39 f0                	cmp    %esi,%eax
  8009df:	75 e2                	jne    8009c3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e6:	5b                   	pop    %ebx
  8009e7:	5e                   	pop    %esi
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	53                   	push   %ebx
  8009ee:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009f1:	89 c1                	mov    %eax,%ecx
  8009f3:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009fa:	eb 0a                	jmp    800a06 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009fc:	0f b6 10             	movzbl (%eax),%edx
  8009ff:	39 da                	cmp    %ebx,%edx
  800a01:	74 07                	je     800a0a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a03:	83 c0 01             	add    $0x1,%eax
  800a06:	39 c8                	cmp    %ecx,%eax
  800a08:	72 f2                	jb     8009fc <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a0a:	5b                   	pop    %ebx
  800a0b:	5d                   	pop    %ebp
  800a0c:	c3                   	ret    

00800a0d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a0d:	55                   	push   %ebp
  800a0e:	89 e5                	mov    %esp,%ebp
  800a10:	57                   	push   %edi
  800a11:	56                   	push   %esi
  800a12:	53                   	push   %ebx
  800a13:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a16:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a19:	eb 03                	jmp    800a1e <strtol+0x11>
		s++;
  800a1b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1e:	0f b6 01             	movzbl (%ecx),%eax
  800a21:	3c 20                	cmp    $0x20,%al
  800a23:	74 f6                	je     800a1b <strtol+0xe>
  800a25:	3c 09                	cmp    $0x9,%al
  800a27:	74 f2                	je     800a1b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a29:	3c 2b                	cmp    $0x2b,%al
  800a2b:	75 0a                	jne    800a37 <strtol+0x2a>
		s++;
  800a2d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a30:	bf 00 00 00 00       	mov    $0x0,%edi
  800a35:	eb 11                	jmp    800a48 <strtol+0x3b>
  800a37:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a3c:	3c 2d                	cmp    $0x2d,%al
  800a3e:	75 08                	jne    800a48 <strtol+0x3b>
		s++, neg = 1;
  800a40:	83 c1 01             	add    $0x1,%ecx
  800a43:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a48:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a4e:	75 15                	jne    800a65 <strtol+0x58>
  800a50:	80 39 30             	cmpb   $0x30,(%ecx)
  800a53:	75 10                	jne    800a65 <strtol+0x58>
  800a55:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a59:	75 7c                	jne    800ad7 <strtol+0xca>
		s += 2, base = 16;
  800a5b:	83 c1 02             	add    $0x2,%ecx
  800a5e:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a63:	eb 16                	jmp    800a7b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a65:	85 db                	test   %ebx,%ebx
  800a67:	75 12                	jne    800a7b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a69:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a6e:	80 39 30             	cmpb   $0x30,(%ecx)
  800a71:	75 08                	jne    800a7b <strtol+0x6e>
		s++, base = 8;
  800a73:	83 c1 01             	add    $0x1,%ecx
  800a76:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a7b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a80:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a83:	0f b6 11             	movzbl (%ecx),%edx
  800a86:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a89:	89 f3                	mov    %esi,%ebx
  800a8b:	80 fb 09             	cmp    $0x9,%bl
  800a8e:	77 08                	ja     800a98 <strtol+0x8b>
			dig = *s - '0';
  800a90:	0f be d2             	movsbl %dl,%edx
  800a93:	83 ea 30             	sub    $0x30,%edx
  800a96:	eb 22                	jmp    800aba <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a98:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a9b:	89 f3                	mov    %esi,%ebx
  800a9d:	80 fb 19             	cmp    $0x19,%bl
  800aa0:	77 08                	ja     800aaa <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aa2:	0f be d2             	movsbl %dl,%edx
  800aa5:	83 ea 57             	sub    $0x57,%edx
  800aa8:	eb 10                	jmp    800aba <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800aaa:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aad:	89 f3                	mov    %esi,%ebx
  800aaf:	80 fb 19             	cmp    $0x19,%bl
  800ab2:	77 16                	ja     800aca <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ab4:	0f be d2             	movsbl %dl,%edx
  800ab7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aba:	3b 55 10             	cmp    0x10(%ebp),%edx
  800abd:	7d 0b                	jge    800aca <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800abf:	83 c1 01             	add    $0x1,%ecx
  800ac2:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ac6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ac8:	eb b9                	jmp    800a83 <strtol+0x76>

	if (endptr)
  800aca:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ace:	74 0d                	je     800add <strtol+0xd0>
		*endptr = (char *) s;
  800ad0:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad3:	89 0e                	mov    %ecx,(%esi)
  800ad5:	eb 06                	jmp    800add <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad7:	85 db                	test   %ebx,%ebx
  800ad9:	74 98                	je     800a73 <strtol+0x66>
  800adb:	eb 9e                	jmp    800a7b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800add:	89 c2                	mov    %eax,%edx
  800adf:	f7 da                	neg    %edx
  800ae1:	85 ff                	test   %edi,%edi
  800ae3:	0f 45 c2             	cmovne %edx,%eax
}
  800ae6:	5b                   	pop    %ebx
  800ae7:	5e                   	pop    %esi
  800ae8:	5f                   	pop    %edi
  800ae9:	5d                   	pop    %ebp
  800aea:	c3                   	ret    

00800aeb <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800aeb:	55                   	push   %ebp
  800aec:	89 e5                	mov    %esp,%ebp
  800aee:	57                   	push   %edi
  800aef:	56                   	push   %esi
  800af0:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800af1:	b8 00 00 00 00       	mov    $0x0,%eax
  800af6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800af9:	8b 55 08             	mov    0x8(%ebp),%edx
  800afc:	89 c3                	mov    %eax,%ebx
  800afe:	89 c7                	mov    %eax,%edi
  800b00:	89 c6                	mov    %eax,%esi
  800b02:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b04:	5b                   	pop    %ebx
  800b05:	5e                   	pop    %esi
  800b06:	5f                   	pop    %edi
  800b07:	5d                   	pop    %ebp
  800b08:	c3                   	ret    

00800b09 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b09:	55                   	push   %ebp
  800b0a:	89 e5                	mov    %esp,%ebp
  800b0c:	57                   	push   %edi
  800b0d:	56                   	push   %esi
  800b0e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b0f:	ba 00 00 00 00       	mov    $0x0,%edx
  800b14:	b8 01 00 00 00       	mov    $0x1,%eax
  800b19:	89 d1                	mov    %edx,%ecx
  800b1b:	89 d3                	mov    %edx,%ebx
  800b1d:	89 d7                	mov    %edx,%edi
  800b1f:	89 d6                	mov    %edx,%esi
  800b21:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b23:	5b                   	pop    %ebx
  800b24:	5e                   	pop    %esi
  800b25:	5f                   	pop    %edi
  800b26:	5d                   	pop    %ebp
  800b27:	c3                   	ret    

00800b28 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b28:	55                   	push   %ebp
  800b29:	89 e5                	mov    %esp,%ebp
  800b2b:	57                   	push   %edi
  800b2c:	56                   	push   %esi
  800b2d:	53                   	push   %ebx
  800b2e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b31:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b36:	b8 03 00 00 00       	mov    $0x3,%eax
  800b3b:	8b 55 08             	mov    0x8(%ebp),%edx
  800b3e:	89 cb                	mov    %ecx,%ebx
  800b40:	89 cf                	mov    %ecx,%edi
  800b42:	89 ce                	mov    %ecx,%esi
  800b44:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b46:	85 c0                	test   %eax,%eax
  800b48:	7e 17                	jle    800b61 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b4a:	83 ec 0c             	sub    $0xc,%esp
  800b4d:	50                   	push   %eax
  800b4e:	6a 03                	push   $0x3
  800b50:	68 24 16 80 00       	push   $0x801624
  800b55:	6a 23                	push   $0x23
  800b57:	68 41 16 80 00       	push   $0x801641
  800b5c:	e8 77 04 00 00       	call   800fd8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b61:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b64:	5b                   	pop    %ebx
  800b65:	5e                   	pop    %esi
  800b66:	5f                   	pop    %edi
  800b67:	5d                   	pop    %ebp
  800b68:	c3                   	ret    

00800b69 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b69:	55                   	push   %ebp
  800b6a:	89 e5                	mov    %esp,%ebp
  800b6c:	57                   	push   %edi
  800b6d:	56                   	push   %esi
  800b6e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b6f:	ba 00 00 00 00       	mov    $0x0,%edx
  800b74:	b8 02 00 00 00       	mov    $0x2,%eax
  800b79:	89 d1                	mov    %edx,%ecx
  800b7b:	89 d3                	mov    %edx,%ebx
  800b7d:	89 d7                	mov    %edx,%edi
  800b7f:	89 d6                	mov    %edx,%esi
  800b81:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b83:	5b                   	pop    %ebx
  800b84:	5e                   	pop    %esi
  800b85:	5f                   	pop    %edi
  800b86:	5d                   	pop    %ebp
  800b87:	c3                   	ret    

00800b88 <sys_yield>:

void
sys_yield(void)
{
  800b88:	55                   	push   %ebp
  800b89:	89 e5                	mov    %esp,%ebp
  800b8b:	57                   	push   %edi
  800b8c:	56                   	push   %esi
  800b8d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b8e:	ba 00 00 00 00       	mov    $0x0,%edx
  800b93:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b98:	89 d1                	mov    %edx,%ecx
  800b9a:	89 d3                	mov    %edx,%ebx
  800b9c:	89 d7                	mov    %edx,%edi
  800b9e:	89 d6                	mov    %edx,%esi
  800ba0:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800ba2:	5b                   	pop    %ebx
  800ba3:	5e                   	pop    %esi
  800ba4:	5f                   	pop    %edi
  800ba5:	5d                   	pop    %ebp
  800ba6:	c3                   	ret    

00800ba7 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800ba7:	55                   	push   %ebp
  800ba8:	89 e5                	mov    %esp,%ebp
  800baa:	57                   	push   %edi
  800bab:	56                   	push   %esi
  800bac:	53                   	push   %ebx
  800bad:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb0:	be 00 00 00 00       	mov    $0x0,%esi
  800bb5:	b8 04 00 00 00       	mov    $0x4,%eax
  800bba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bbd:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc0:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bc3:	89 f7                	mov    %esi,%edi
  800bc5:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bc7:	85 c0                	test   %eax,%eax
  800bc9:	7e 17                	jle    800be2 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bcb:	83 ec 0c             	sub    $0xc,%esp
  800bce:	50                   	push   %eax
  800bcf:	6a 04                	push   $0x4
  800bd1:	68 24 16 80 00       	push   $0x801624
  800bd6:	6a 23                	push   $0x23
  800bd8:	68 41 16 80 00       	push   $0x801641
  800bdd:	e8 f6 03 00 00       	call   800fd8 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800be2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800be5:	5b                   	pop    %ebx
  800be6:	5e                   	pop    %esi
  800be7:	5f                   	pop    %edi
  800be8:	5d                   	pop    %ebp
  800be9:	c3                   	ret    

00800bea <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800bea:	55                   	push   %ebp
  800beb:	89 e5                	mov    %esp,%ebp
  800bed:	57                   	push   %edi
  800bee:	56                   	push   %esi
  800bef:	53                   	push   %ebx
  800bf0:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf3:	b8 05 00 00 00       	mov    $0x5,%eax
  800bf8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bfb:	8b 55 08             	mov    0x8(%ebp),%edx
  800bfe:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c01:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c04:	8b 75 18             	mov    0x18(%ebp),%esi
  800c07:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c09:	85 c0                	test   %eax,%eax
  800c0b:	7e 17                	jle    800c24 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c0d:	83 ec 0c             	sub    $0xc,%esp
  800c10:	50                   	push   %eax
  800c11:	6a 05                	push   $0x5
  800c13:	68 24 16 80 00       	push   $0x801624
  800c18:	6a 23                	push   $0x23
  800c1a:	68 41 16 80 00       	push   $0x801641
  800c1f:	e8 b4 03 00 00       	call   800fd8 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c24:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c27:	5b                   	pop    %ebx
  800c28:	5e                   	pop    %esi
  800c29:	5f                   	pop    %edi
  800c2a:	5d                   	pop    %ebp
  800c2b:	c3                   	ret    

00800c2c <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c2c:	55                   	push   %ebp
  800c2d:	89 e5                	mov    %esp,%ebp
  800c2f:	57                   	push   %edi
  800c30:	56                   	push   %esi
  800c31:	53                   	push   %ebx
  800c32:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c35:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c3a:	b8 06 00 00 00       	mov    $0x6,%eax
  800c3f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c42:	8b 55 08             	mov    0x8(%ebp),%edx
  800c45:	89 df                	mov    %ebx,%edi
  800c47:	89 de                	mov    %ebx,%esi
  800c49:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c4b:	85 c0                	test   %eax,%eax
  800c4d:	7e 17                	jle    800c66 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c4f:	83 ec 0c             	sub    $0xc,%esp
  800c52:	50                   	push   %eax
  800c53:	6a 06                	push   $0x6
  800c55:	68 24 16 80 00       	push   $0x801624
  800c5a:	6a 23                	push   $0x23
  800c5c:	68 41 16 80 00       	push   $0x801641
  800c61:	e8 72 03 00 00       	call   800fd8 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c66:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c69:	5b                   	pop    %ebx
  800c6a:	5e                   	pop    %esi
  800c6b:	5f                   	pop    %edi
  800c6c:	5d                   	pop    %ebp
  800c6d:	c3                   	ret    

00800c6e <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c6e:	55                   	push   %ebp
  800c6f:	89 e5                	mov    %esp,%ebp
  800c71:	57                   	push   %edi
  800c72:	56                   	push   %esi
  800c73:	53                   	push   %ebx
  800c74:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c77:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c7c:	b8 08 00 00 00       	mov    $0x8,%eax
  800c81:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c84:	8b 55 08             	mov    0x8(%ebp),%edx
  800c87:	89 df                	mov    %ebx,%edi
  800c89:	89 de                	mov    %ebx,%esi
  800c8b:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c8d:	85 c0                	test   %eax,%eax
  800c8f:	7e 17                	jle    800ca8 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c91:	83 ec 0c             	sub    $0xc,%esp
  800c94:	50                   	push   %eax
  800c95:	6a 08                	push   $0x8
  800c97:	68 24 16 80 00       	push   $0x801624
  800c9c:	6a 23                	push   $0x23
  800c9e:	68 41 16 80 00       	push   $0x801641
  800ca3:	e8 30 03 00 00       	call   800fd8 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800ca8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cab:	5b                   	pop    %ebx
  800cac:	5e                   	pop    %esi
  800cad:	5f                   	pop    %edi
  800cae:	5d                   	pop    %ebp
  800caf:	c3                   	ret    

00800cb0 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800cb0:	55                   	push   %ebp
  800cb1:	89 e5                	mov    %esp,%ebp
  800cb3:	57                   	push   %edi
  800cb4:	56                   	push   %esi
  800cb5:	53                   	push   %ebx
  800cb6:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cb9:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cbe:	b8 09 00 00 00       	mov    $0x9,%eax
  800cc3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc6:	8b 55 08             	mov    0x8(%ebp),%edx
  800cc9:	89 df                	mov    %ebx,%edi
  800ccb:	89 de                	mov    %ebx,%esi
  800ccd:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ccf:	85 c0                	test   %eax,%eax
  800cd1:	7e 17                	jle    800cea <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd3:	83 ec 0c             	sub    $0xc,%esp
  800cd6:	50                   	push   %eax
  800cd7:	6a 09                	push   $0x9
  800cd9:	68 24 16 80 00       	push   $0x801624
  800cde:	6a 23                	push   $0x23
  800ce0:	68 41 16 80 00       	push   $0x801641
  800ce5:	e8 ee 02 00 00       	call   800fd8 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800cea:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5f                   	pop    %edi
  800cf0:	5d                   	pop    %ebp
  800cf1:	c3                   	ret    

00800cf2 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800cf2:	55                   	push   %ebp
  800cf3:	89 e5                	mov    %esp,%ebp
  800cf5:	57                   	push   %edi
  800cf6:	56                   	push   %esi
  800cf7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cf8:	be 00 00 00 00       	mov    $0x0,%esi
  800cfd:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d05:	8b 55 08             	mov    0x8(%ebp),%edx
  800d08:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d0b:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d0e:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d10:	5b                   	pop    %ebx
  800d11:	5e                   	pop    %esi
  800d12:	5f                   	pop    %edi
  800d13:	5d                   	pop    %ebp
  800d14:	c3                   	ret    

00800d15 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d15:	55                   	push   %ebp
  800d16:	89 e5                	mov    %esp,%ebp
  800d18:	57                   	push   %edi
  800d19:	56                   	push   %esi
  800d1a:	53                   	push   %ebx
  800d1b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d23:	b8 0c 00 00 00       	mov    $0xc,%eax
  800d28:	8b 55 08             	mov    0x8(%ebp),%edx
  800d2b:	89 cb                	mov    %ecx,%ebx
  800d2d:	89 cf                	mov    %ecx,%edi
  800d2f:	89 ce                	mov    %ecx,%esi
  800d31:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d33:	85 c0                	test   %eax,%eax
  800d35:	7e 17                	jle    800d4e <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d37:	83 ec 0c             	sub    $0xc,%esp
  800d3a:	50                   	push   %eax
  800d3b:	6a 0c                	push   $0xc
  800d3d:	68 24 16 80 00       	push   $0x801624
  800d42:	6a 23                	push   $0x23
  800d44:	68 41 16 80 00       	push   $0x801641
  800d49:	e8 8a 02 00 00       	call   800fd8 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800d4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d51:	5b                   	pop    %ebx
  800d52:	5e                   	pop    %esi
  800d53:	5f                   	pop    %edi
  800d54:	5d                   	pop    %ebp
  800d55:	c3                   	ret    

00800d56 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800d56:	55                   	push   %ebp
  800d57:	89 e5                	mov    %esp,%ebp
  800d59:	53                   	push   %ebx
  800d5a:	83 ec 04             	sub    $0x4,%esp
  800d5d:	8b 45 08             	mov    0x8(%ebp),%eax
void *addr = (void *) utf->utf_fault_va;
  800d60:	8b 18                	mov    (%eax),%ebx
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	if ((err & FEC_WR) == 0)
  800d62:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800d66:	75 12                	jne    800d7a <pgfault+0x24>
		panic("pgfault: faulting address [%08x] not a write\n", addr);
  800d68:	53                   	push   %ebx
  800d69:	68 50 16 80 00       	push   $0x801650
  800d6e:	6a 1f                	push   $0x1f
  800d70:	68 f8 16 80 00       	push   $0x8016f8
  800d75:	e8 5e 02 00 00       	call   800fd8 <_panic>

	if (!(uvpt[PGNUM(addr)] & PTE_COW))
  800d7a:	89 d8                	mov    %ebx,%eax
  800d7c:	c1 e8 0c             	shr    $0xc,%eax
  800d7f:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800d86:	f6 c4 08             	test   $0x8,%ah
  800d89:	75 14                	jne    800d9f <pgfault+0x49>
		panic("pgfault: fault was not on a copy-on-write page\n");
  800d8b:	83 ec 04             	sub    $0x4,%esp
  800d8e:	68 80 16 80 00       	push   $0x801680
  800d93:	6a 22                	push   $0x22
  800d95:	68 f8 16 80 00       	push   $0x8016f8
  800d9a:	e8 39 02 00 00       	call   800fd8 <_panic>
	//   You should make three system calls.

	// LAB 4: Your code here.


	if ((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0)
  800d9f:	83 ec 04             	sub    $0x4,%esp
  800da2:	6a 07                	push   $0x7
  800da4:	68 00 f0 7f 00       	push   $0x7ff000
  800da9:	6a 00                	push   $0x0
  800dab:	e8 f7 fd ff ff       	call   800ba7 <sys_page_alloc>
  800db0:	83 c4 10             	add    $0x10,%esp
  800db3:	85 c0                	test   %eax,%eax
  800db5:	79 12                	jns    800dc9 <pgfault+0x73>
		panic("sys_page_alloc: %e\n", r);
  800db7:	50                   	push   %eax
  800db8:	68 03 17 80 00       	push   $0x801703
  800dbd:	6a 30                	push   $0x30
  800dbf:	68 f8 16 80 00       	push   $0x8016f8
  800dc4:	e8 0f 02 00 00       	call   800fd8 <_panic>


	void *src_addr = (void *) ROUNDDOWN(addr, PGSIZE);
  800dc9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove(PFTEMP, src_addr, PGSIZE);
  800dcf:	83 ec 04             	sub    $0x4,%esp
  800dd2:	68 00 10 00 00       	push   $0x1000
  800dd7:	53                   	push   %ebx
  800dd8:	68 00 f0 7f 00       	push   $0x7ff000
  800ddd:	e8 54 fb ff ff       	call   800936 <memmove>

	
	if ((r = sys_page_map(0, PFTEMP, 0, src_addr, PTE_P | PTE_U | PTE_W)) < 0)
  800de2:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800de9:	53                   	push   %ebx
  800dea:	6a 00                	push   $0x0
  800dec:	68 00 f0 7f 00       	push   $0x7ff000
  800df1:	6a 00                	push   $0x0
  800df3:	e8 f2 fd ff ff       	call   800bea <sys_page_map>
  800df8:	83 c4 20             	add    $0x20,%esp
  800dfb:	85 c0                	test   %eax,%eax
  800dfd:	79 12                	jns    800e11 <pgfault+0xbb>
	panic("sys_page_map: %e\n", r);
  800dff:	50                   	push   %eax
  800e00:	68 17 17 80 00       	push   $0x801717
  800e05:	6a 38                	push   $0x38
  800e07:	68 f8 16 80 00       	push   $0x8016f8
  800e0c:	e8 c7 01 00 00       	call   800fd8 <_panic>

}
  800e11:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800e14:	c9                   	leave  
  800e15:	c3                   	ret    

00800e16 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800e16:	55                   	push   %ebp
  800e17:	89 e5                	mov    %esp,%ebp
  800e19:	57                   	push   %edi
  800e1a:	56                   	push   %esi
  800e1b:	53                   	push   %ebx
  800e1c:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	int r;
	envid_t child_envid;

	set_pgfault_handler(pgfault);
  800e1f:	68 56 0d 80 00       	push   $0x800d56
  800e24:	e8 f5 01 00 00       	call   80101e <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800e29:	b8 07 00 00 00       	mov    $0x7,%eax
  800e2e:	cd 30                	int    $0x30
  800e30:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800e33:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	child_envid = sys_exofork();
	if (child_envid < 0)
  800e36:	83 c4 10             	add    $0x10,%esp
  800e39:	85 c0                	test   %eax,%eax
  800e3b:	79 12                	jns    800e4f <fork+0x39>
		panic("sys_exofork: %e\n", child_envid);
  800e3d:	50                   	push   %eax
  800e3e:	68 29 17 80 00       	push   $0x801729
  800e43:	6a 75                	push   $0x75
  800e45:	68 f8 16 80 00       	push   $0x8016f8
  800e4a:	e8 89 01 00 00       	call   800fd8 <_panic>
  800e4f:	bb 00 00 00 00       	mov    $0x0,%ebx
	if (child_envid == 0) { // child
  800e54:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800e58:	75 21                	jne    800e7b <fork+0x65>
		thisenv = &envs[ENVX(sys_getenvid())];
  800e5a:	e8 0a fd ff ff       	call   800b69 <sys_getenvid>
  800e5f:	25 ff 03 00 00       	and    $0x3ff,%eax
  800e64:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800e67:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800e6c:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800e71:	b8 00 00 00 00       	mov    $0x0,%eax
  800e76:	e9 3b 01 00 00       	jmp    800fb6 <fork+0x1a0>
	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
		
		
		uint32_t pdx = ROUNDDOWN(page_num, NPDENTRIES) / NPDENTRIES;
  800e7b:	89 d8                	mov    %ebx,%eax
  800e7d:	c1 e8 0a             	shr    $0xa,%eax
		if ((uvpd[pdx] & PTE_P) == PTE_P &&((uvpt[page_num] & PTE_P) == PTE_P)) {
  800e80:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800e87:	a8 01                	test   $0x1,%al
  800e89:	0f 84 92 00 00 00    	je     800f21 <fork+0x10b>
  800e8f:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800e96:	a8 01                	test   $0x1,%al
  800e98:	0f 84 83 00 00 00    	je     800f21 <fork+0x10b>
{
	int r;

	// LAB 4: Your code here.
	int perm = PTE_P|PTE_U;
	void *va = (void *)(pn << PGSHIFT);
  800e9e:	89 df                	mov    %ebx,%edi
  800ea0:	c1 e7 0c             	shl    $0xc,%edi
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  800ea3:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
		perm |= PTE_COW;
  800eaa:	be 05 08 00 00       	mov    $0x805,%esi
	int r;

	// LAB 4: Your code here.
	int perm = PTE_P|PTE_U;
	void *va = (void *)(pn << PGSHIFT);
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  800eaf:	a8 02                	test   $0x2,%al
  800eb1:	75 1d                	jne    800ed0 <fork+0xba>
  800eb3:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800eba:	25 00 08 00 00       	and    $0x800,%eax
		perm |= PTE_COW;
  800ebf:	83 f8 01             	cmp    $0x1,%eax
  800ec2:	19 f6                	sbb    %esi,%esi
  800ec4:	81 e6 00 f8 ff ff    	and    $0xfffff800,%esi
  800eca:	81 c6 05 08 00 00    	add    $0x805,%esi
	if ((r = sys_page_map(0, va, envid, va, perm)) < 0)
  800ed0:	83 ec 0c             	sub    $0xc,%esp
  800ed3:	56                   	push   %esi
  800ed4:	57                   	push   %edi
  800ed5:	ff 75 e4             	pushl  -0x1c(%ebp)
  800ed8:	57                   	push   %edi
  800ed9:	6a 00                	push   $0x0
  800edb:	e8 0a fd ff ff       	call   800bea <sys_page_map>
  800ee0:	83 c4 20             	add    $0x20,%esp
  800ee3:	85 c0                	test   %eax,%eax
  800ee5:	79 12                	jns    800ef9 <fork+0xe3>
		panic("error in duppage(), sys_page_map: %e\n", r);
  800ee7:	50                   	push   %eax
  800ee8:	68 b0 16 80 00       	push   $0x8016b0
  800eed:	6a 52                	push   $0x52
  800eef:	68 f8 16 80 00       	push   $0x8016f8
  800ef4:	e8 df 00 00 00       	call   800fd8 <_panic>
	if ((r = sys_page_map(0, va, 0, va, perm)) < 0)
  800ef9:	83 ec 0c             	sub    $0xc,%esp
  800efc:	56                   	push   %esi
  800efd:	57                   	push   %edi
  800efe:	6a 00                	push   $0x0
  800f00:	57                   	push   %edi
  800f01:	6a 00                	push   $0x0
  800f03:	e8 e2 fc ff ff       	call   800bea <sys_page_map>
  800f08:	83 c4 20             	add    $0x20,%esp
  800f0b:	85 c0                	test   %eax,%eax
  800f0d:	79 12                	jns    800f21 <fork+0x10b>
		panic("error in duppage(), sys_page_map: %e\n", r);
  800f0f:	50                   	push   %eax
  800f10:	68 b0 16 80 00       	push   $0x8016b0
  800f15:	6a 54                	push   $0x54
  800f17:	68 f8 16 80 00       	push   $0x8016f8
  800f1c:	e8 b7 00 00 00       	call   800fd8 <_panic>
	// We're in the parent


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
  800f21:	83 c3 01             	add    $0x1,%ebx
  800f24:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  800f2a:	0f 85 4b ff ff ff    	jne    800e7b <fork+0x65>
		}
	}

	// Allocate exception stack space for child
	
	if ((r = sys_page_alloc(child_envid, (void *) (UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W)) < 0)
  800f30:	83 ec 04             	sub    $0x4,%esp
  800f33:	6a 07                	push   $0x7
  800f35:	68 00 f0 bf ee       	push   $0xeebff000
  800f3a:	ff 75 e0             	pushl  -0x20(%ebp)
  800f3d:	e8 65 fc ff ff       	call   800ba7 <sys_page_alloc>
  800f42:	83 c4 10             	add    $0x10,%esp
  800f45:	85 c0                	test   %eax,%eax
  800f47:	79 15                	jns    800f5e <fork+0x148>
		panic("sys_page_alloc: %e\n", r);
  800f49:	50                   	push   %eax
  800f4a:	68 03 17 80 00       	push   $0x801703
  800f4f:	68 8c 00 00 00       	push   $0x8c
  800f54:	68 f8 16 80 00       	push   $0x8016f8
  800f59:	e8 7a 00 00 00       	call   800fd8 <_panic>

	// Set page fault handler for the child
	if ((r = sys_env_set_pgfault_upcall(child_envid, _pgfault_upcall)) < 0)
  800f5e:	83 ec 08             	sub    $0x8,%esp
  800f61:	68 73 10 80 00       	push   $0x801073
  800f66:	ff 75 e0             	pushl  -0x20(%ebp)
  800f69:	e8 42 fd ff ff       	call   800cb0 <sys_env_set_pgfault_upcall>
  800f6e:	83 c4 10             	add    $0x10,%esp
  800f71:	85 c0                	test   %eax,%eax
  800f73:	79 15                	jns    800f8a <fork+0x174>
		panic("sys_env_set_pgfault_upcall: %e\n", r);
  800f75:	50                   	push   %eax
  800f76:	68 d8 16 80 00       	push   $0x8016d8
  800f7b:	68 90 00 00 00       	push   $0x90
  800f80:	68 f8 16 80 00       	push   $0x8016f8
  800f85:	e8 4e 00 00 00       	call   800fd8 <_panic>

	// Mark child environment as runnable
	if ((r = sys_env_set_status(child_envid, ENV_RUNNABLE)) < 0)
  800f8a:	83 ec 08             	sub    $0x8,%esp
  800f8d:	6a 02                	push   $0x2
  800f8f:	ff 75 e0             	pushl  -0x20(%ebp)
  800f92:	e8 d7 fc ff ff       	call   800c6e <sys_env_set_status>
  800f97:	83 c4 10             	add    $0x10,%esp
  800f9a:	85 c0                	test   %eax,%eax
  800f9c:	79 15                	jns    800fb3 <fork+0x19d>
		panic("sys_env_set_status: %e\n", r);
  800f9e:	50                   	push   %eax
  800f9f:	68 3a 17 80 00       	push   $0x80173a
  800fa4:	68 94 00 00 00       	push   $0x94
  800fa9:	68 f8 16 80 00       	push   $0x8016f8
  800fae:	e8 25 00 00 00       	call   800fd8 <_panic>

	return child_envid;
  800fb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
  800fb6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800fb9:	5b                   	pop    %ebx
  800fba:	5e                   	pop    %esi
  800fbb:	5f                   	pop    %edi
  800fbc:	5d                   	pop    %ebp
  800fbd:	c3                   	ret    

00800fbe <sfork>:

// Challenge!
int
sfork(void)
{
  800fbe:	55                   	push   %ebp
  800fbf:	89 e5                	mov    %esp,%ebp
  800fc1:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  800fc4:	68 52 17 80 00       	push   $0x801752
  800fc9:	68 9d 00 00 00       	push   $0x9d
  800fce:	68 f8 16 80 00       	push   $0x8016f8
  800fd3:	e8 00 00 00 00       	call   800fd8 <_panic>

00800fd8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800fd8:	55                   	push   %ebp
  800fd9:	89 e5                	mov    %esp,%ebp
  800fdb:	56                   	push   %esi
  800fdc:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800fdd:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800fe0:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800fe6:	e8 7e fb ff ff       	call   800b69 <sys_getenvid>
  800feb:	83 ec 0c             	sub    $0xc,%esp
  800fee:	ff 75 0c             	pushl  0xc(%ebp)
  800ff1:	ff 75 08             	pushl  0x8(%ebp)
  800ff4:	56                   	push   %esi
  800ff5:	50                   	push   %eax
  800ff6:	68 68 17 80 00       	push   $0x801768
  800ffb:	e8 a0 f1 ff ff       	call   8001a0 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801000:	83 c4 18             	add    $0x18,%esp
  801003:	53                   	push   %ebx
  801004:	ff 75 10             	pushl  0x10(%ebp)
  801007:	e8 43 f1 ff ff       	call   80014f <vcprintf>
	cprintf("\n");
  80100c:	c7 04 24 d4 13 80 00 	movl   $0x8013d4,(%esp)
  801013:	e8 88 f1 ff ff       	call   8001a0 <cprintf>
  801018:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80101b:	cc                   	int3   
  80101c:	eb fd                	jmp    80101b <_panic+0x43>

0080101e <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  80101e:	55                   	push   %ebp
  80101f:	89 e5                	mov    %esp,%ebp
  801021:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  801024:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  80102b:	75 3c                	jne    801069 <set_pgfault_handler+0x4b>
		
		if ((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE),PTE_U|PTE_P|PTE_W)) < 0)
  80102d:	83 ec 04             	sub    $0x4,%esp
  801030:	6a 07                	push   $0x7
  801032:	68 00 f0 bf ee       	push   $0xeebff000
  801037:	6a 00                	push   $0x0
  801039:	e8 69 fb ff ff       	call   800ba7 <sys_page_alloc>
  80103e:	83 c4 10             	add    $0x10,%esp
  801041:	85 c0                	test   %eax,%eax
  801043:	79 12                	jns    801057 <set_pgfault_handler+0x39>
		panic("sys_page_alloc: %e", r);
  801045:	50                   	push   %eax
  801046:	68 8c 17 80 00       	push   $0x80178c
  80104b:	6a 20                	push   $0x20
  80104d:	68 9f 17 80 00       	push   $0x80179f
  801052:	e8 81 ff ff ff       	call   800fd8 <_panic>
	    sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  801057:	83 ec 08             	sub    $0x8,%esp
  80105a:	68 73 10 80 00       	push   $0x801073
  80105f:	6a 00                	push   $0x0
  801061:	e8 4a fc ff ff       	call   800cb0 <sys_env_set_pgfault_upcall>
  801066:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801069:	8b 45 08             	mov    0x8(%ebp),%eax
  80106c:	a3 08 20 80 00       	mov    %eax,0x802008
}
  801071:	c9                   	leave  
  801072:	c3                   	ret    

00801073 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801073:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801074:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  801079:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80107b:	83 c4 04             	add    $0x4,%esp
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
    
    //trap time eip
	movl 0x28(%esp), %eax
  80107e:	8b 44 24 28          	mov    0x28(%esp),%eax

	//current stack we need it afterwards to pop registers al
	movl %esp, %ebp
  801082:	89 e5                	mov    %esp,%ebp

	//switch to user stack where faulitng va occured
	movl 0x30(%esp), %esp
  801084:	8b 64 24 30          	mov    0x30(%esp),%esp

	// Push trap-time eip to the user stack 
	pushl %eax
  801088:	50                   	push   %eax

	// SAve the user stack esp again for latter use after popping general purpose registers
	movl %esp, 0x30(%ebp)
  801089:	89 65 30             	mov    %esp,0x30(%ebp)

	// Now again go to the user trap frame
	movl %ebp, %esp
  80108c:	89 ec                	mov    %ebp,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	
	// ignore faut  va and err	
	addl $8, %esp
  80108e:	83 c4 08             	add    $0x8,%esp

	// Pop all registers back
	popal
  801091:	61                   	popa   
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

	// Skip %eip
	addl $0x4, %esp
  801092:	83 c4 04             	add    $0x4,%esp

	// Pop eflags back
	popfl
  801095:	9d                   	popf   

	// Go to user stack now
	// LAB 4: Your code here.

	popl %esp
  801096:	5c                   	pop    %esp


	// LAB 4: Your code here.

	ret
  801097:	c3                   	ret    
  801098:	66 90                	xchg   %ax,%ax
  80109a:	66 90                	xchg   %ax,%ax
  80109c:	66 90                	xchg   %ax,%ax
  80109e:	66 90                	xchg   %ax,%ax

008010a0 <__udivdi3>:
  8010a0:	55                   	push   %ebp
  8010a1:	57                   	push   %edi
  8010a2:	56                   	push   %esi
  8010a3:	53                   	push   %ebx
  8010a4:	83 ec 1c             	sub    $0x1c,%esp
  8010a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  8010ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  8010af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  8010b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8010b7:	85 f6                	test   %esi,%esi
  8010b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8010bd:	89 ca                	mov    %ecx,%edx
  8010bf:	89 f8                	mov    %edi,%eax
  8010c1:	75 3d                	jne    801100 <__udivdi3+0x60>
  8010c3:	39 cf                	cmp    %ecx,%edi
  8010c5:	0f 87 c5 00 00 00    	ja     801190 <__udivdi3+0xf0>
  8010cb:	85 ff                	test   %edi,%edi
  8010cd:	89 fd                	mov    %edi,%ebp
  8010cf:	75 0b                	jne    8010dc <__udivdi3+0x3c>
  8010d1:	b8 01 00 00 00       	mov    $0x1,%eax
  8010d6:	31 d2                	xor    %edx,%edx
  8010d8:	f7 f7                	div    %edi
  8010da:	89 c5                	mov    %eax,%ebp
  8010dc:	89 c8                	mov    %ecx,%eax
  8010de:	31 d2                	xor    %edx,%edx
  8010e0:	f7 f5                	div    %ebp
  8010e2:	89 c1                	mov    %eax,%ecx
  8010e4:	89 d8                	mov    %ebx,%eax
  8010e6:	89 cf                	mov    %ecx,%edi
  8010e8:	f7 f5                	div    %ebp
  8010ea:	89 c3                	mov    %eax,%ebx
  8010ec:	89 d8                	mov    %ebx,%eax
  8010ee:	89 fa                	mov    %edi,%edx
  8010f0:	83 c4 1c             	add    $0x1c,%esp
  8010f3:	5b                   	pop    %ebx
  8010f4:	5e                   	pop    %esi
  8010f5:	5f                   	pop    %edi
  8010f6:	5d                   	pop    %ebp
  8010f7:	c3                   	ret    
  8010f8:	90                   	nop
  8010f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801100:	39 ce                	cmp    %ecx,%esi
  801102:	77 74                	ja     801178 <__udivdi3+0xd8>
  801104:	0f bd fe             	bsr    %esi,%edi
  801107:	83 f7 1f             	xor    $0x1f,%edi
  80110a:	0f 84 98 00 00 00    	je     8011a8 <__udivdi3+0x108>
  801110:	bb 20 00 00 00       	mov    $0x20,%ebx
  801115:	89 f9                	mov    %edi,%ecx
  801117:	89 c5                	mov    %eax,%ebp
  801119:	29 fb                	sub    %edi,%ebx
  80111b:	d3 e6                	shl    %cl,%esi
  80111d:	89 d9                	mov    %ebx,%ecx
  80111f:	d3 ed                	shr    %cl,%ebp
  801121:	89 f9                	mov    %edi,%ecx
  801123:	d3 e0                	shl    %cl,%eax
  801125:	09 ee                	or     %ebp,%esi
  801127:	89 d9                	mov    %ebx,%ecx
  801129:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80112d:	89 d5                	mov    %edx,%ebp
  80112f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801133:	d3 ed                	shr    %cl,%ebp
  801135:	89 f9                	mov    %edi,%ecx
  801137:	d3 e2                	shl    %cl,%edx
  801139:	89 d9                	mov    %ebx,%ecx
  80113b:	d3 e8                	shr    %cl,%eax
  80113d:	09 c2                	or     %eax,%edx
  80113f:	89 d0                	mov    %edx,%eax
  801141:	89 ea                	mov    %ebp,%edx
  801143:	f7 f6                	div    %esi
  801145:	89 d5                	mov    %edx,%ebp
  801147:	89 c3                	mov    %eax,%ebx
  801149:	f7 64 24 0c          	mull   0xc(%esp)
  80114d:	39 d5                	cmp    %edx,%ebp
  80114f:	72 10                	jb     801161 <__udivdi3+0xc1>
  801151:	8b 74 24 08          	mov    0x8(%esp),%esi
  801155:	89 f9                	mov    %edi,%ecx
  801157:	d3 e6                	shl    %cl,%esi
  801159:	39 c6                	cmp    %eax,%esi
  80115b:	73 07                	jae    801164 <__udivdi3+0xc4>
  80115d:	39 d5                	cmp    %edx,%ebp
  80115f:	75 03                	jne    801164 <__udivdi3+0xc4>
  801161:	83 eb 01             	sub    $0x1,%ebx
  801164:	31 ff                	xor    %edi,%edi
  801166:	89 d8                	mov    %ebx,%eax
  801168:	89 fa                	mov    %edi,%edx
  80116a:	83 c4 1c             	add    $0x1c,%esp
  80116d:	5b                   	pop    %ebx
  80116e:	5e                   	pop    %esi
  80116f:	5f                   	pop    %edi
  801170:	5d                   	pop    %ebp
  801171:	c3                   	ret    
  801172:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801178:	31 ff                	xor    %edi,%edi
  80117a:	31 db                	xor    %ebx,%ebx
  80117c:	89 d8                	mov    %ebx,%eax
  80117e:	89 fa                	mov    %edi,%edx
  801180:	83 c4 1c             	add    $0x1c,%esp
  801183:	5b                   	pop    %ebx
  801184:	5e                   	pop    %esi
  801185:	5f                   	pop    %edi
  801186:	5d                   	pop    %ebp
  801187:	c3                   	ret    
  801188:	90                   	nop
  801189:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801190:	89 d8                	mov    %ebx,%eax
  801192:	f7 f7                	div    %edi
  801194:	31 ff                	xor    %edi,%edi
  801196:	89 c3                	mov    %eax,%ebx
  801198:	89 d8                	mov    %ebx,%eax
  80119a:	89 fa                	mov    %edi,%edx
  80119c:	83 c4 1c             	add    $0x1c,%esp
  80119f:	5b                   	pop    %ebx
  8011a0:	5e                   	pop    %esi
  8011a1:	5f                   	pop    %edi
  8011a2:	5d                   	pop    %ebp
  8011a3:	c3                   	ret    
  8011a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011a8:	39 ce                	cmp    %ecx,%esi
  8011aa:	72 0c                	jb     8011b8 <__udivdi3+0x118>
  8011ac:	31 db                	xor    %ebx,%ebx
  8011ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
  8011b2:	0f 87 34 ff ff ff    	ja     8010ec <__udivdi3+0x4c>
  8011b8:	bb 01 00 00 00       	mov    $0x1,%ebx
  8011bd:	e9 2a ff ff ff       	jmp    8010ec <__udivdi3+0x4c>
  8011c2:	66 90                	xchg   %ax,%ax
  8011c4:	66 90                	xchg   %ax,%ax
  8011c6:	66 90                	xchg   %ax,%ax
  8011c8:	66 90                	xchg   %ax,%ax
  8011ca:	66 90                	xchg   %ax,%ax
  8011cc:	66 90                	xchg   %ax,%ax
  8011ce:	66 90                	xchg   %ax,%ax

008011d0 <__umoddi3>:
  8011d0:	55                   	push   %ebp
  8011d1:	57                   	push   %edi
  8011d2:	56                   	push   %esi
  8011d3:	53                   	push   %ebx
  8011d4:	83 ec 1c             	sub    $0x1c,%esp
  8011d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  8011db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8011df:	8b 74 24 34          	mov    0x34(%esp),%esi
  8011e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8011e7:	85 d2                	test   %edx,%edx
  8011e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8011ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8011f1:	89 f3                	mov    %esi,%ebx
  8011f3:	89 3c 24             	mov    %edi,(%esp)
  8011f6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011fa:	75 1c                	jne    801218 <__umoddi3+0x48>
  8011fc:	39 f7                	cmp    %esi,%edi
  8011fe:	76 50                	jbe    801250 <__umoddi3+0x80>
  801200:	89 c8                	mov    %ecx,%eax
  801202:	89 f2                	mov    %esi,%edx
  801204:	f7 f7                	div    %edi
  801206:	89 d0                	mov    %edx,%eax
  801208:	31 d2                	xor    %edx,%edx
  80120a:	83 c4 1c             	add    $0x1c,%esp
  80120d:	5b                   	pop    %ebx
  80120e:	5e                   	pop    %esi
  80120f:	5f                   	pop    %edi
  801210:	5d                   	pop    %ebp
  801211:	c3                   	ret    
  801212:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801218:	39 f2                	cmp    %esi,%edx
  80121a:	89 d0                	mov    %edx,%eax
  80121c:	77 52                	ja     801270 <__umoddi3+0xa0>
  80121e:	0f bd ea             	bsr    %edx,%ebp
  801221:	83 f5 1f             	xor    $0x1f,%ebp
  801224:	75 5a                	jne    801280 <__umoddi3+0xb0>
  801226:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80122a:	0f 82 e0 00 00 00    	jb     801310 <__umoddi3+0x140>
  801230:	39 0c 24             	cmp    %ecx,(%esp)
  801233:	0f 86 d7 00 00 00    	jbe    801310 <__umoddi3+0x140>
  801239:	8b 44 24 08          	mov    0x8(%esp),%eax
  80123d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801241:	83 c4 1c             	add    $0x1c,%esp
  801244:	5b                   	pop    %ebx
  801245:	5e                   	pop    %esi
  801246:	5f                   	pop    %edi
  801247:	5d                   	pop    %ebp
  801248:	c3                   	ret    
  801249:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801250:	85 ff                	test   %edi,%edi
  801252:	89 fd                	mov    %edi,%ebp
  801254:	75 0b                	jne    801261 <__umoddi3+0x91>
  801256:	b8 01 00 00 00       	mov    $0x1,%eax
  80125b:	31 d2                	xor    %edx,%edx
  80125d:	f7 f7                	div    %edi
  80125f:	89 c5                	mov    %eax,%ebp
  801261:	89 f0                	mov    %esi,%eax
  801263:	31 d2                	xor    %edx,%edx
  801265:	f7 f5                	div    %ebp
  801267:	89 c8                	mov    %ecx,%eax
  801269:	f7 f5                	div    %ebp
  80126b:	89 d0                	mov    %edx,%eax
  80126d:	eb 99                	jmp    801208 <__umoddi3+0x38>
  80126f:	90                   	nop
  801270:	89 c8                	mov    %ecx,%eax
  801272:	89 f2                	mov    %esi,%edx
  801274:	83 c4 1c             	add    $0x1c,%esp
  801277:	5b                   	pop    %ebx
  801278:	5e                   	pop    %esi
  801279:	5f                   	pop    %edi
  80127a:	5d                   	pop    %ebp
  80127b:	c3                   	ret    
  80127c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801280:	8b 34 24             	mov    (%esp),%esi
  801283:	bf 20 00 00 00       	mov    $0x20,%edi
  801288:	89 e9                	mov    %ebp,%ecx
  80128a:	29 ef                	sub    %ebp,%edi
  80128c:	d3 e0                	shl    %cl,%eax
  80128e:	89 f9                	mov    %edi,%ecx
  801290:	89 f2                	mov    %esi,%edx
  801292:	d3 ea                	shr    %cl,%edx
  801294:	89 e9                	mov    %ebp,%ecx
  801296:	09 c2                	or     %eax,%edx
  801298:	89 d8                	mov    %ebx,%eax
  80129a:	89 14 24             	mov    %edx,(%esp)
  80129d:	89 f2                	mov    %esi,%edx
  80129f:	d3 e2                	shl    %cl,%edx
  8012a1:	89 f9                	mov    %edi,%ecx
  8012a3:	89 54 24 04          	mov    %edx,0x4(%esp)
  8012a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8012ab:	d3 e8                	shr    %cl,%eax
  8012ad:	89 e9                	mov    %ebp,%ecx
  8012af:	89 c6                	mov    %eax,%esi
  8012b1:	d3 e3                	shl    %cl,%ebx
  8012b3:	89 f9                	mov    %edi,%ecx
  8012b5:	89 d0                	mov    %edx,%eax
  8012b7:	d3 e8                	shr    %cl,%eax
  8012b9:	89 e9                	mov    %ebp,%ecx
  8012bb:	09 d8                	or     %ebx,%eax
  8012bd:	89 d3                	mov    %edx,%ebx
  8012bf:	89 f2                	mov    %esi,%edx
  8012c1:	f7 34 24             	divl   (%esp)
  8012c4:	89 d6                	mov    %edx,%esi
  8012c6:	d3 e3                	shl    %cl,%ebx
  8012c8:	f7 64 24 04          	mull   0x4(%esp)
  8012cc:	39 d6                	cmp    %edx,%esi
  8012ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8012d2:	89 d1                	mov    %edx,%ecx
  8012d4:	89 c3                	mov    %eax,%ebx
  8012d6:	72 08                	jb     8012e0 <__umoddi3+0x110>
  8012d8:	75 11                	jne    8012eb <__umoddi3+0x11b>
  8012da:	39 44 24 08          	cmp    %eax,0x8(%esp)
  8012de:	73 0b                	jae    8012eb <__umoddi3+0x11b>
  8012e0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8012e4:	1b 14 24             	sbb    (%esp),%edx
  8012e7:	89 d1                	mov    %edx,%ecx
  8012e9:	89 c3                	mov    %eax,%ebx
  8012eb:	8b 54 24 08          	mov    0x8(%esp),%edx
  8012ef:	29 da                	sub    %ebx,%edx
  8012f1:	19 ce                	sbb    %ecx,%esi
  8012f3:	89 f9                	mov    %edi,%ecx
  8012f5:	89 f0                	mov    %esi,%eax
  8012f7:	d3 e0                	shl    %cl,%eax
  8012f9:	89 e9                	mov    %ebp,%ecx
  8012fb:	d3 ea                	shr    %cl,%edx
  8012fd:	89 e9                	mov    %ebp,%ecx
  8012ff:	d3 ee                	shr    %cl,%esi
  801301:	09 d0                	or     %edx,%eax
  801303:	89 f2                	mov    %esi,%edx
  801305:	83 c4 1c             	add    $0x1c,%esp
  801308:	5b                   	pop    %ebx
  801309:	5e                   	pop    %esi
  80130a:	5f                   	pop    %edi
  80130b:	5d                   	pop    %ebp
  80130c:	c3                   	ret    
  80130d:	8d 76 00             	lea    0x0(%esi),%esi
  801310:	29 f9                	sub    %edi,%ecx
  801312:	19 d6                	sbb    %edx,%esi
  801314:	89 74 24 04          	mov    %esi,0x4(%esp)
  801318:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80131c:	e9 18 ff ff ff       	jmp    801239 <__umoddi3+0x69>
