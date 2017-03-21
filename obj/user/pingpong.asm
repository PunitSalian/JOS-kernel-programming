
obj/user/pingpong:     file format elf32-i386


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
  80002c:	e8 8d 00 00 00       	call   8000be <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 1c             	sub    $0x1c,%esp
	envid_t who;

	if ((who = fork()) != 0) {
  80003c:	e8 de 0d 00 00       	call   800e1f <fork>
  800041:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800044:	85 c0                	test   %eax,%eax
  800046:	74 27                	je     80006f <umain+0x3c>
  800048:	89 c3                	mov    %eax,%ebx
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  80004a:	e8 23 0b 00 00       	call   800b72 <sys_getenvid>
  80004f:	83 ec 04             	sub    $0x4,%esp
  800052:	53                   	push   %ebx
  800053:	50                   	push   %eax
  800054:	68 e0 14 80 00       	push   $0x8014e0
  800059:	e8 4b 01 00 00       	call   8001a9 <cprintf>
		ipc_send(who, 0, 0, 0);
  80005e:	6a 00                	push   $0x0
  800060:	6a 00                	push   $0x0
  800062:	6a 00                	push   $0x0
  800064:	ff 75 e4             	pushl  -0x1c(%ebp)
  800067:	e8 72 10 00 00       	call   8010de <ipc_send>
  80006c:	83 c4 20             	add    $0x20,%esp
	}

	while (1) {
		uint32_t i = ipc_recv(&who, 0, 0);
  80006f:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  800072:	83 ec 04             	sub    $0x4,%esp
  800075:	6a 00                	push   $0x0
  800077:	6a 00                	push   $0x0
  800079:	56                   	push   %esi
  80007a:	e8 f6 0f 00 00       	call   801075 <ipc_recv>
  80007f:	89 c3                	mov    %eax,%ebx
		cprintf("%x got %d from %x\n", sys_getenvid(), i, who);
  800081:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800084:	e8 e9 0a 00 00       	call   800b72 <sys_getenvid>
  800089:	57                   	push   %edi
  80008a:	53                   	push   %ebx
  80008b:	50                   	push   %eax
  80008c:	68 f6 14 80 00       	push   $0x8014f6
  800091:	e8 13 01 00 00       	call   8001a9 <cprintf>
		if (i == 10)
  800096:	83 c4 20             	add    $0x20,%esp
  800099:	83 fb 0a             	cmp    $0xa,%ebx
  80009c:	74 18                	je     8000b6 <umain+0x83>
			return;
		i++;
  80009e:	83 c3 01             	add    $0x1,%ebx
		ipc_send(who, i, 0, 0);
  8000a1:	6a 00                	push   $0x0
  8000a3:	6a 00                	push   $0x0
  8000a5:	53                   	push   %ebx
  8000a6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8000a9:	e8 30 10 00 00       	call   8010de <ipc_send>
		if (i == 10)
  8000ae:	83 c4 10             	add    $0x10,%esp
  8000b1:	83 fb 0a             	cmp    $0xa,%ebx
  8000b4:	75 bc                	jne    800072 <umain+0x3f>
			return;
	}

}
  8000b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000b9:	5b                   	pop    %ebx
  8000ba:	5e                   	pop    %esi
  8000bb:	5f                   	pop    %edi
  8000bc:	5d                   	pop    %ebp
  8000bd:	c3                   	ret    

008000be <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	56                   	push   %esi
  8000c2:	53                   	push   %ebx
  8000c3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000c6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  8000c9:	e8 a4 0a 00 00       	call   800b72 <sys_getenvid>
  8000ce:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000d3:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000d6:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000db:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000e0:	85 db                	test   %ebx,%ebx
  8000e2:	7e 07                	jle    8000eb <libmain+0x2d>
		binaryname = argv[0];
  8000e4:	8b 06                	mov    (%esi),%eax
  8000e6:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000eb:	83 ec 08             	sub    $0x8,%esp
  8000ee:	56                   	push   %esi
  8000ef:	53                   	push   %ebx
  8000f0:	e8 3e ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000f5:	e8 0a 00 00 00       	call   800104 <exit>
}
  8000fa:	83 c4 10             	add    $0x10,%esp
  8000fd:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800100:	5b                   	pop    %ebx
  800101:	5e                   	pop    %esi
  800102:	5d                   	pop    %ebp
  800103:	c3                   	ret    

00800104 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800104:	55                   	push   %ebp
  800105:	89 e5                	mov    %esp,%ebp
  800107:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80010a:	6a 00                	push   $0x0
  80010c:	e8 20 0a 00 00       	call   800b31 <sys_env_destroy>
}
  800111:	83 c4 10             	add    $0x10,%esp
  800114:	c9                   	leave  
  800115:	c3                   	ret    

00800116 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800116:	55                   	push   %ebp
  800117:	89 e5                	mov    %esp,%ebp
  800119:	53                   	push   %ebx
  80011a:	83 ec 04             	sub    $0x4,%esp
  80011d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800120:	8b 13                	mov    (%ebx),%edx
  800122:	8d 42 01             	lea    0x1(%edx),%eax
  800125:	89 03                	mov    %eax,(%ebx)
  800127:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80012a:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80012e:	3d ff 00 00 00       	cmp    $0xff,%eax
  800133:	75 1a                	jne    80014f <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800135:	83 ec 08             	sub    $0x8,%esp
  800138:	68 ff 00 00 00       	push   $0xff
  80013d:	8d 43 08             	lea    0x8(%ebx),%eax
  800140:	50                   	push   %eax
  800141:	e8 ae 09 00 00       	call   800af4 <sys_cputs>
		b->idx = 0;
  800146:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80014c:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80014f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800153:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800156:	c9                   	leave  
  800157:	c3                   	ret    

00800158 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800158:	55                   	push   %ebp
  800159:	89 e5                	mov    %esp,%ebp
  80015b:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800161:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800168:	00 00 00 
	b.cnt = 0;
  80016b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800172:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800175:	ff 75 0c             	pushl  0xc(%ebp)
  800178:	ff 75 08             	pushl  0x8(%ebp)
  80017b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800181:	50                   	push   %eax
  800182:	68 16 01 80 00       	push   $0x800116
  800187:	e8 1a 01 00 00       	call   8002a6 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80018c:	83 c4 08             	add    $0x8,%esp
  80018f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800195:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80019b:	50                   	push   %eax
  80019c:	e8 53 09 00 00       	call   800af4 <sys_cputs>

	return b.cnt;
}
  8001a1:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001a7:	c9                   	leave  
  8001a8:	c3                   	ret    

008001a9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001a9:	55                   	push   %ebp
  8001aa:	89 e5                	mov    %esp,%ebp
  8001ac:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001af:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001b2:	50                   	push   %eax
  8001b3:	ff 75 08             	pushl  0x8(%ebp)
  8001b6:	e8 9d ff ff ff       	call   800158 <vcprintf>
	va_end(ap);

	return cnt;
}
  8001bb:	c9                   	leave  
  8001bc:	c3                   	ret    

008001bd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001bd:	55                   	push   %ebp
  8001be:	89 e5                	mov    %esp,%ebp
  8001c0:	57                   	push   %edi
  8001c1:	56                   	push   %esi
  8001c2:	53                   	push   %ebx
  8001c3:	83 ec 1c             	sub    $0x1c,%esp
  8001c6:	89 c7                	mov    %eax,%edi
  8001c8:	89 d6                	mov    %edx,%esi
  8001ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8001cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001d3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001d6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001d9:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001de:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001e1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001e4:	39 d3                	cmp    %edx,%ebx
  8001e6:	72 05                	jb     8001ed <printnum+0x30>
  8001e8:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001eb:	77 45                	ja     800232 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001ed:	83 ec 0c             	sub    $0xc,%esp
  8001f0:	ff 75 18             	pushl  0x18(%ebp)
  8001f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8001f6:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8001f9:	53                   	push   %ebx
  8001fa:	ff 75 10             	pushl  0x10(%ebp)
  8001fd:	83 ec 08             	sub    $0x8,%esp
  800200:	ff 75 e4             	pushl  -0x1c(%ebp)
  800203:	ff 75 e0             	pushl  -0x20(%ebp)
  800206:	ff 75 dc             	pushl  -0x24(%ebp)
  800209:	ff 75 d8             	pushl  -0x28(%ebp)
  80020c:	e8 2f 10 00 00       	call   801240 <__udivdi3>
  800211:	83 c4 18             	add    $0x18,%esp
  800214:	52                   	push   %edx
  800215:	50                   	push   %eax
  800216:	89 f2                	mov    %esi,%edx
  800218:	89 f8                	mov    %edi,%eax
  80021a:	e8 9e ff ff ff       	call   8001bd <printnum>
  80021f:	83 c4 20             	add    $0x20,%esp
  800222:	eb 18                	jmp    80023c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800224:	83 ec 08             	sub    $0x8,%esp
  800227:	56                   	push   %esi
  800228:	ff 75 18             	pushl  0x18(%ebp)
  80022b:	ff d7                	call   *%edi
  80022d:	83 c4 10             	add    $0x10,%esp
  800230:	eb 03                	jmp    800235 <printnum+0x78>
  800232:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800235:	83 eb 01             	sub    $0x1,%ebx
  800238:	85 db                	test   %ebx,%ebx
  80023a:	7f e8                	jg     800224 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80023c:	83 ec 08             	sub    $0x8,%esp
  80023f:	56                   	push   %esi
  800240:	83 ec 04             	sub    $0x4,%esp
  800243:	ff 75 e4             	pushl  -0x1c(%ebp)
  800246:	ff 75 e0             	pushl  -0x20(%ebp)
  800249:	ff 75 dc             	pushl  -0x24(%ebp)
  80024c:	ff 75 d8             	pushl  -0x28(%ebp)
  80024f:	e8 1c 11 00 00       	call   801370 <__umoddi3>
  800254:	83 c4 14             	add    $0x14,%esp
  800257:	0f be 80 13 15 80 00 	movsbl 0x801513(%eax),%eax
  80025e:	50                   	push   %eax
  80025f:	ff d7                	call   *%edi
}
  800261:	83 c4 10             	add    $0x10,%esp
  800264:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800267:	5b                   	pop    %ebx
  800268:	5e                   	pop    %esi
  800269:	5f                   	pop    %edi
  80026a:	5d                   	pop    %ebp
  80026b:	c3                   	ret    

0080026c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80026c:	55                   	push   %ebp
  80026d:	89 e5                	mov    %esp,%ebp
  80026f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800272:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800276:	8b 10                	mov    (%eax),%edx
  800278:	3b 50 04             	cmp    0x4(%eax),%edx
  80027b:	73 0a                	jae    800287 <sprintputch+0x1b>
		*b->buf++ = ch;
  80027d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800280:	89 08                	mov    %ecx,(%eax)
  800282:	8b 45 08             	mov    0x8(%ebp),%eax
  800285:	88 02                	mov    %al,(%edx)
}
  800287:	5d                   	pop    %ebp
  800288:	c3                   	ret    

00800289 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
  80028c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80028f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800292:	50                   	push   %eax
  800293:	ff 75 10             	pushl  0x10(%ebp)
  800296:	ff 75 0c             	pushl  0xc(%ebp)
  800299:	ff 75 08             	pushl  0x8(%ebp)
  80029c:	e8 05 00 00 00       	call   8002a6 <vprintfmt>
	va_end(ap);
}
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	c9                   	leave  
  8002a5:	c3                   	ret    

008002a6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002a6:	55                   	push   %ebp
  8002a7:	89 e5                	mov    %esp,%ebp
  8002a9:	57                   	push   %edi
  8002aa:	56                   	push   %esi
  8002ab:	53                   	push   %ebx
  8002ac:	83 ec 2c             	sub    $0x2c,%esp
  8002af:	8b 75 08             	mov    0x8(%ebp),%esi
  8002b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b5:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002b8:	eb 12                	jmp    8002cc <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002ba:	85 c0                	test   %eax,%eax
  8002bc:	0f 84 42 04 00 00    	je     800704 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8002c2:	83 ec 08             	sub    $0x8,%esp
  8002c5:	53                   	push   %ebx
  8002c6:	50                   	push   %eax
  8002c7:	ff d6                	call   *%esi
  8002c9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002cc:	83 c7 01             	add    $0x1,%edi
  8002cf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002d3:	83 f8 25             	cmp    $0x25,%eax
  8002d6:	75 e2                	jne    8002ba <vprintfmt+0x14>
  8002d8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002dc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002e3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002ea:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002f1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002f6:	eb 07                	jmp    8002ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002fb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ff:	8d 47 01             	lea    0x1(%edi),%eax
  800302:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800305:	0f b6 07             	movzbl (%edi),%eax
  800308:	0f b6 d0             	movzbl %al,%edx
  80030b:	83 e8 23             	sub    $0x23,%eax
  80030e:	3c 55                	cmp    $0x55,%al
  800310:	0f 87 d3 03 00 00    	ja     8006e9 <vprintfmt+0x443>
  800316:	0f b6 c0             	movzbl %al,%eax
  800319:	ff 24 85 e0 15 80 00 	jmp    *0x8015e0(,%eax,4)
  800320:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800323:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800327:	eb d6                	jmp    8002ff <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800329:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80032c:	b8 00 00 00 00       	mov    $0x0,%eax
  800331:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800334:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800337:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80033b:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80033e:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800341:	83 f9 09             	cmp    $0x9,%ecx
  800344:	77 3f                	ja     800385 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800346:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800349:	eb e9                	jmp    800334 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80034b:	8b 45 14             	mov    0x14(%ebp),%eax
  80034e:	8b 00                	mov    (%eax),%eax
  800350:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800353:	8b 45 14             	mov    0x14(%ebp),%eax
  800356:	8d 40 04             	lea    0x4(%eax),%eax
  800359:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80035f:	eb 2a                	jmp    80038b <vprintfmt+0xe5>
  800361:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800364:	85 c0                	test   %eax,%eax
  800366:	ba 00 00 00 00       	mov    $0x0,%edx
  80036b:	0f 49 d0             	cmovns %eax,%edx
  80036e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800371:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800374:	eb 89                	jmp    8002ff <vprintfmt+0x59>
  800376:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800379:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800380:	e9 7a ff ff ff       	jmp    8002ff <vprintfmt+0x59>
  800385:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800388:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80038b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80038f:	0f 89 6a ff ff ff    	jns    8002ff <vprintfmt+0x59>
				width = precision, precision = -1;
  800395:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800398:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80039b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003a2:	e9 58 ff ff ff       	jmp    8002ff <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003a7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003ad:	e9 4d ff ff ff       	jmp    8002ff <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b5:	8d 78 04             	lea    0x4(%eax),%edi
  8003b8:	83 ec 08             	sub    $0x8,%esp
  8003bb:	53                   	push   %ebx
  8003bc:	ff 30                	pushl  (%eax)
  8003be:	ff d6                	call   *%esi
			break;
  8003c0:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003c3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003c9:	e9 fe fe ff ff       	jmp    8002cc <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003ce:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d1:	8d 78 04             	lea    0x4(%eax),%edi
  8003d4:	8b 00                	mov    (%eax),%eax
  8003d6:	99                   	cltd   
  8003d7:	31 d0                	xor    %edx,%eax
  8003d9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003db:	83 f8 08             	cmp    $0x8,%eax
  8003de:	7f 0b                	jg     8003eb <vprintfmt+0x145>
  8003e0:	8b 14 85 40 17 80 00 	mov    0x801740(,%eax,4),%edx
  8003e7:	85 d2                	test   %edx,%edx
  8003e9:	75 1b                	jne    800406 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  8003eb:	50                   	push   %eax
  8003ec:	68 2b 15 80 00       	push   $0x80152b
  8003f1:	53                   	push   %ebx
  8003f2:	56                   	push   %esi
  8003f3:	e8 91 fe ff ff       	call   800289 <printfmt>
  8003f8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003fb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800401:	e9 c6 fe ff ff       	jmp    8002cc <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800406:	52                   	push   %edx
  800407:	68 34 15 80 00       	push   $0x801534
  80040c:	53                   	push   %ebx
  80040d:	56                   	push   %esi
  80040e:	e8 76 fe ff ff       	call   800289 <printfmt>
  800413:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800416:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800419:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80041c:	e9 ab fe ff ff       	jmp    8002cc <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800421:	8b 45 14             	mov    0x14(%ebp),%eax
  800424:	83 c0 04             	add    $0x4,%eax
  800427:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80042f:	85 ff                	test   %edi,%edi
  800431:	b8 24 15 80 00       	mov    $0x801524,%eax
  800436:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800439:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80043d:	0f 8e 94 00 00 00    	jle    8004d7 <vprintfmt+0x231>
  800443:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800447:	0f 84 98 00 00 00    	je     8004e5 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80044d:	83 ec 08             	sub    $0x8,%esp
  800450:	ff 75 d0             	pushl  -0x30(%ebp)
  800453:	57                   	push   %edi
  800454:	e8 33 03 00 00       	call   80078c <strnlen>
  800459:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80045c:	29 c1                	sub    %eax,%ecx
  80045e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800461:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800464:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800468:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80046b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80046e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800470:	eb 0f                	jmp    800481 <vprintfmt+0x1db>
					putch(padc, putdat);
  800472:	83 ec 08             	sub    $0x8,%esp
  800475:	53                   	push   %ebx
  800476:	ff 75 e0             	pushl  -0x20(%ebp)
  800479:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80047b:	83 ef 01             	sub    $0x1,%edi
  80047e:	83 c4 10             	add    $0x10,%esp
  800481:	85 ff                	test   %edi,%edi
  800483:	7f ed                	jg     800472 <vprintfmt+0x1cc>
  800485:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800488:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80048b:	85 c9                	test   %ecx,%ecx
  80048d:	b8 00 00 00 00       	mov    $0x0,%eax
  800492:	0f 49 c1             	cmovns %ecx,%eax
  800495:	29 c1                	sub    %eax,%ecx
  800497:	89 75 08             	mov    %esi,0x8(%ebp)
  80049a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80049d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004a0:	89 cb                	mov    %ecx,%ebx
  8004a2:	eb 4d                	jmp    8004f1 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004a4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004a8:	74 1b                	je     8004c5 <vprintfmt+0x21f>
  8004aa:	0f be c0             	movsbl %al,%eax
  8004ad:	83 e8 20             	sub    $0x20,%eax
  8004b0:	83 f8 5e             	cmp    $0x5e,%eax
  8004b3:	76 10                	jbe    8004c5 <vprintfmt+0x21f>
					putch('?', putdat);
  8004b5:	83 ec 08             	sub    $0x8,%esp
  8004b8:	ff 75 0c             	pushl  0xc(%ebp)
  8004bb:	6a 3f                	push   $0x3f
  8004bd:	ff 55 08             	call   *0x8(%ebp)
  8004c0:	83 c4 10             	add    $0x10,%esp
  8004c3:	eb 0d                	jmp    8004d2 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8004c5:	83 ec 08             	sub    $0x8,%esp
  8004c8:	ff 75 0c             	pushl  0xc(%ebp)
  8004cb:	52                   	push   %edx
  8004cc:	ff 55 08             	call   *0x8(%ebp)
  8004cf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004d2:	83 eb 01             	sub    $0x1,%ebx
  8004d5:	eb 1a                	jmp    8004f1 <vprintfmt+0x24b>
  8004d7:	89 75 08             	mov    %esi,0x8(%ebp)
  8004da:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004e0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e3:	eb 0c                	jmp    8004f1 <vprintfmt+0x24b>
  8004e5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004eb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004f1:	83 c7 01             	add    $0x1,%edi
  8004f4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004f8:	0f be d0             	movsbl %al,%edx
  8004fb:	85 d2                	test   %edx,%edx
  8004fd:	74 23                	je     800522 <vprintfmt+0x27c>
  8004ff:	85 f6                	test   %esi,%esi
  800501:	78 a1                	js     8004a4 <vprintfmt+0x1fe>
  800503:	83 ee 01             	sub    $0x1,%esi
  800506:	79 9c                	jns    8004a4 <vprintfmt+0x1fe>
  800508:	89 df                	mov    %ebx,%edi
  80050a:	8b 75 08             	mov    0x8(%ebp),%esi
  80050d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800510:	eb 18                	jmp    80052a <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800512:	83 ec 08             	sub    $0x8,%esp
  800515:	53                   	push   %ebx
  800516:	6a 20                	push   $0x20
  800518:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80051a:	83 ef 01             	sub    $0x1,%edi
  80051d:	83 c4 10             	add    $0x10,%esp
  800520:	eb 08                	jmp    80052a <vprintfmt+0x284>
  800522:	89 df                	mov    %ebx,%edi
  800524:	8b 75 08             	mov    0x8(%ebp),%esi
  800527:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80052a:	85 ff                	test   %edi,%edi
  80052c:	7f e4                	jg     800512 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80052e:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800531:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800534:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800537:	e9 90 fd ff ff       	jmp    8002cc <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80053c:	83 f9 01             	cmp    $0x1,%ecx
  80053f:	7e 19                	jle    80055a <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800541:	8b 45 14             	mov    0x14(%ebp),%eax
  800544:	8b 50 04             	mov    0x4(%eax),%edx
  800547:	8b 00                	mov    (%eax),%eax
  800549:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80054c:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80054f:	8b 45 14             	mov    0x14(%ebp),%eax
  800552:	8d 40 08             	lea    0x8(%eax),%eax
  800555:	89 45 14             	mov    %eax,0x14(%ebp)
  800558:	eb 38                	jmp    800592 <vprintfmt+0x2ec>
	else if (lflag)
  80055a:	85 c9                	test   %ecx,%ecx
  80055c:	74 1b                	je     800579 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  80055e:	8b 45 14             	mov    0x14(%ebp),%eax
  800561:	8b 00                	mov    (%eax),%eax
  800563:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800566:	89 c1                	mov    %eax,%ecx
  800568:	c1 f9 1f             	sar    $0x1f,%ecx
  80056b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80056e:	8b 45 14             	mov    0x14(%ebp),%eax
  800571:	8d 40 04             	lea    0x4(%eax),%eax
  800574:	89 45 14             	mov    %eax,0x14(%ebp)
  800577:	eb 19                	jmp    800592 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800579:	8b 45 14             	mov    0x14(%ebp),%eax
  80057c:	8b 00                	mov    (%eax),%eax
  80057e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800581:	89 c1                	mov    %eax,%ecx
  800583:	c1 f9 1f             	sar    $0x1f,%ecx
  800586:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800589:	8b 45 14             	mov    0x14(%ebp),%eax
  80058c:	8d 40 04             	lea    0x4(%eax),%eax
  80058f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800592:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800595:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800598:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80059d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005a1:	0f 89 0e 01 00 00    	jns    8006b5 <vprintfmt+0x40f>
				putch('-', putdat);
  8005a7:	83 ec 08             	sub    $0x8,%esp
  8005aa:	53                   	push   %ebx
  8005ab:	6a 2d                	push   $0x2d
  8005ad:	ff d6                	call   *%esi
				num = -(long long) num;
  8005af:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005b2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005b5:	f7 da                	neg    %edx
  8005b7:	83 d1 00             	adc    $0x0,%ecx
  8005ba:	f7 d9                	neg    %ecx
  8005bc:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8005bf:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005c4:	e9 ec 00 00 00       	jmp    8006b5 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c9:	83 f9 01             	cmp    $0x1,%ecx
  8005cc:	7e 18                	jle    8005e6 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  8005ce:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d1:	8b 10                	mov    (%eax),%edx
  8005d3:	8b 48 04             	mov    0x4(%eax),%ecx
  8005d6:	8d 40 08             	lea    0x8(%eax),%eax
  8005d9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005dc:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005e1:	e9 cf 00 00 00       	jmp    8006b5 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8005e6:	85 c9                	test   %ecx,%ecx
  8005e8:	74 1a                	je     800604 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  8005ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ed:	8b 10                	mov    (%eax),%edx
  8005ef:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005f4:	8d 40 04             	lea    0x4(%eax),%eax
  8005f7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005fa:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005ff:	e9 b1 00 00 00       	jmp    8006b5 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800604:	8b 45 14             	mov    0x14(%ebp),%eax
  800607:	8b 10                	mov    (%eax),%edx
  800609:	b9 00 00 00 00       	mov    $0x0,%ecx
  80060e:	8d 40 04             	lea    0x4(%eax),%eax
  800611:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800614:	b8 0a 00 00 00       	mov    $0xa,%eax
  800619:	e9 97 00 00 00       	jmp    8006b5 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80061e:	83 ec 08             	sub    $0x8,%esp
  800621:	53                   	push   %ebx
  800622:	6a 58                	push   $0x58
  800624:	ff d6                	call   *%esi
			putch('X', putdat);
  800626:	83 c4 08             	add    $0x8,%esp
  800629:	53                   	push   %ebx
  80062a:	6a 58                	push   $0x58
  80062c:	ff d6                	call   *%esi
			putch('X', putdat);
  80062e:	83 c4 08             	add    $0x8,%esp
  800631:	53                   	push   %ebx
  800632:	6a 58                	push   $0x58
  800634:	ff d6                	call   *%esi
			break;
  800636:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800639:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80063c:	e9 8b fc ff ff       	jmp    8002cc <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800641:	83 ec 08             	sub    $0x8,%esp
  800644:	53                   	push   %ebx
  800645:	6a 30                	push   $0x30
  800647:	ff d6                	call   *%esi
			putch('x', putdat);
  800649:	83 c4 08             	add    $0x8,%esp
  80064c:	53                   	push   %ebx
  80064d:	6a 78                	push   $0x78
  80064f:	ff d6                	call   *%esi
			num = (unsigned long long)
  800651:	8b 45 14             	mov    0x14(%ebp),%eax
  800654:	8b 10                	mov    (%eax),%edx
  800656:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80065b:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80065e:	8d 40 04             	lea    0x4(%eax),%eax
  800661:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800664:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800669:	eb 4a                	jmp    8006b5 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80066b:	83 f9 01             	cmp    $0x1,%ecx
  80066e:	7e 15                	jle    800685 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800670:	8b 45 14             	mov    0x14(%ebp),%eax
  800673:	8b 10                	mov    (%eax),%edx
  800675:	8b 48 04             	mov    0x4(%eax),%ecx
  800678:	8d 40 08             	lea    0x8(%eax),%eax
  80067b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80067e:	b8 10 00 00 00       	mov    $0x10,%eax
  800683:	eb 30                	jmp    8006b5 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800685:	85 c9                	test   %ecx,%ecx
  800687:	74 17                	je     8006a0 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800689:	8b 45 14             	mov    0x14(%ebp),%eax
  80068c:	8b 10                	mov    (%eax),%edx
  80068e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800693:	8d 40 04             	lea    0x4(%eax),%eax
  800696:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800699:	b8 10 00 00 00       	mov    $0x10,%eax
  80069e:	eb 15                	jmp    8006b5 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a3:	8b 10                	mov    (%eax),%edx
  8006a5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006aa:	8d 40 04             	lea    0x4(%eax),%eax
  8006ad:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006b0:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006b5:	83 ec 0c             	sub    $0xc,%esp
  8006b8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006bc:	57                   	push   %edi
  8006bd:	ff 75 e0             	pushl  -0x20(%ebp)
  8006c0:	50                   	push   %eax
  8006c1:	51                   	push   %ecx
  8006c2:	52                   	push   %edx
  8006c3:	89 da                	mov    %ebx,%edx
  8006c5:	89 f0                	mov    %esi,%eax
  8006c7:	e8 f1 fa ff ff       	call   8001bd <printnum>
			break;
  8006cc:	83 c4 20             	add    $0x20,%esp
  8006cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006d2:	e9 f5 fb ff ff       	jmp    8002cc <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006d7:	83 ec 08             	sub    $0x8,%esp
  8006da:	53                   	push   %ebx
  8006db:	52                   	push   %edx
  8006dc:	ff d6                	call   *%esi
			break;
  8006de:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006e4:	e9 e3 fb ff ff       	jmp    8002cc <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006e9:	83 ec 08             	sub    $0x8,%esp
  8006ec:	53                   	push   %ebx
  8006ed:	6a 25                	push   $0x25
  8006ef:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006f1:	83 c4 10             	add    $0x10,%esp
  8006f4:	eb 03                	jmp    8006f9 <vprintfmt+0x453>
  8006f6:	83 ef 01             	sub    $0x1,%edi
  8006f9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006fd:	75 f7                	jne    8006f6 <vprintfmt+0x450>
  8006ff:	e9 c8 fb ff ff       	jmp    8002cc <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800704:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800707:	5b                   	pop    %ebx
  800708:	5e                   	pop    %esi
  800709:	5f                   	pop    %edi
  80070a:	5d                   	pop    %ebp
  80070b:	c3                   	ret    

0080070c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80070c:	55                   	push   %ebp
  80070d:	89 e5                	mov    %esp,%ebp
  80070f:	83 ec 18             	sub    $0x18,%esp
  800712:	8b 45 08             	mov    0x8(%ebp),%eax
  800715:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800718:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80071b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80071f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800722:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800729:	85 c0                	test   %eax,%eax
  80072b:	74 26                	je     800753 <vsnprintf+0x47>
  80072d:	85 d2                	test   %edx,%edx
  80072f:	7e 22                	jle    800753 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800731:	ff 75 14             	pushl  0x14(%ebp)
  800734:	ff 75 10             	pushl  0x10(%ebp)
  800737:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80073a:	50                   	push   %eax
  80073b:	68 6c 02 80 00       	push   $0x80026c
  800740:	e8 61 fb ff ff       	call   8002a6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800745:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800748:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80074b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80074e:	83 c4 10             	add    $0x10,%esp
  800751:	eb 05                	jmp    800758 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800753:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800758:	c9                   	leave  
  800759:	c3                   	ret    

0080075a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80075a:	55                   	push   %ebp
  80075b:	89 e5                	mov    %esp,%ebp
  80075d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800760:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800763:	50                   	push   %eax
  800764:	ff 75 10             	pushl  0x10(%ebp)
  800767:	ff 75 0c             	pushl  0xc(%ebp)
  80076a:	ff 75 08             	pushl  0x8(%ebp)
  80076d:	e8 9a ff ff ff       	call   80070c <vsnprintf>
	va_end(ap);

	return rc;
}
  800772:	c9                   	leave  
  800773:	c3                   	ret    

00800774 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800774:	55                   	push   %ebp
  800775:	89 e5                	mov    %esp,%ebp
  800777:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80077a:	b8 00 00 00 00       	mov    $0x0,%eax
  80077f:	eb 03                	jmp    800784 <strlen+0x10>
		n++;
  800781:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800784:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800788:	75 f7                	jne    800781 <strlen+0xd>
		n++;
	return n;
}
  80078a:	5d                   	pop    %ebp
  80078b:	c3                   	ret    

0080078c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80078c:	55                   	push   %ebp
  80078d:	89 e5                	mov    %esp,%ebp
  80078f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800792:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800795:	ba 00 00 00 00       	mov    $0x0,%edx
  80079a:	eb 03                	jmp    80079f <strnlen+0x13>
		n++;
  80079c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079f:	39 c2                	cmp    %eax,%edx
  8007a1:	74 08                	je     8007ab <strnlen+0x1f>
  8007a3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007a7:	75 f3                	jne    80079c <strnlen+0x10>
  8007a9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007ab:	5d                   	pop    %ebp
  8007ac:	c3                   	ret    

008007ad <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007ad:	55                   	push   %ebp
  8007ae:	89 e5                	mov    %esp,%ebp
  8007b0:	53                   	push   %ebx
  8007b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b7:	89 c2                	mov    %eax,%edx
  8007b9:	83 c2 01             	add    $0x1,%edx
  8007bc:	83 c1 01             	add    $0x1,%ecx
  8007bf:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007c3:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007c6:	84 db                	test   %bl,%bl
  8007c8:	75 ef                	jne    8007b9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ca:	5b                   	pop    %ebx
  8007cb:	5d                   	pop    %ebp
  8007cc:	c3                   	ret    

008007cd <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007cd:	55                   	push   %ebp
  8007ce:	89 e5                	mov    %esp,%ebp
  8007d0:	53                   	push   %ebx
  8007d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007d4:	53                   	push   %ebx
  8007d5:	e8 9a ff ff ff       	call   800774 <strlen>
  8007da:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007dd:	ff 75 0c             	pushl  0xc(%ebp)
  8007e0:	01 d8                	add    %ebx,%eax
  8007e2:	50                   	push   %eax
  8007e3:	e8 c5 ff ff ff       	call   8007ad <strcpy>
	return dst;
}
  8007e8:	89 d8                	mov    %ebx,%eax
  8007ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007ed:	c9                   	leave  
  8007ee:	c3                   	ret    

008007ef <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007ef:	55                   	push   %ebp
  8007f0:	89 e5                	mov    %esp,%ebp
  8007f2:	56                   	push   %esi
  8007f3:	53                   	push   %ebx
  8007f4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fa:	89 f3                	mov    %esi,%ebx
  8007fc:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ff:	89 f2                	mov    %esi,%edx
  800801:	eb 0f                	jmp    800812 <strncpy+0x23>
		*dst++ = *src;
  800803:	83 c2 01             	add    $0x1,%edx
  800806:	0f b6 01             	movzbl (%ecx),%eax
  800809:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80080c:	80 39 01             	cmpb   $0x1,(%ecx)
  80080f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800812:	39 da                	cmp    %ebx,%edx
  800814:	75 ed                	jne    800803 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800816:	89 f0                	mov    %esi,%eax
  800818:	5b                   	pop    %ebx
  800819:	5e                   	pop    %esi
  80081a:	5d                   	pop    %ebp
  80081b:	c3                   	ret    

0080081c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80081c:	55                   	push   %ebp
  80081d:	89 e5                	mov    %esp,%ebp
  80081f:	56                   	push   %esi
  800820:	53                   	push   %ebx
  800821:	8b 75 08             	mov    0x8(%ebp),%esi
  800824:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800827:	8b 55 10             	mov    0x10(%ebp),%edx
  80082a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80082c:	85 d2                	test   %edx,%edx
  80082e:	74 21                	je     800851 <strlcpy+0x35>
  800830:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800834:	89 f2                	mov    %esi,%edx
  800836:	eb 09                	jmp    800841 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800838:	83 c2 01             	add    $0x1,%edx
  80083b:	83 c1 01             	add    $0x1,%ecx
  80083e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800841:	39 c2                	cmp    %eax,%edx
  800843:	74 09                	je     80084e <strlcpy+0x32>
  800845:	0f b6 19             	movzbl (%ecx),%ebx
  800848:	84 db                	test   %bl,%bl
  80084a:	75 ec                	jne    800838 <strlcpy+0x1c>
  80084c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80084e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800851:	29 f0                	sub    %esi,%eax
}
  800853:	5b                   	pop    %ebx
  800854:	5e                   	pop    %esi
  800855:	5d                   	pop    %ebp
  800856:	c3                   	ret    

00800857 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800857:	55                   	push   %ebp
  800858:	89 e5                	mov    %esp,%ebp
  80085a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800860:	eb 06                	jmp    800868 <strcmp+0x11>
		p++, q++;
  800862:	83 c1 01             	add    $0x1,%ecx
  800865:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800868:	0f b6 01             	movzbl (%ecx),%eax
  80086b:	84 c0                	test   %al,%al
  80086d:	74 04                	je     800873 <strcmp+0x1c>
  80086f:	3a 02                	cmp    (%edx),%al
  800871:	74 ef                	je     800862 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800873:	0f b6 c0             	movzbl %al,%eax
  800876:	0f b6 12             	movzbl (%edx),%edx
  800879:	29 d0                	sub    %edx,%eax
}
  80087b:	5d                   	pop    %ebp
  80087c:	c3                   	ret    

0080087d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80087d:	55                   	push   %ebp
  80087e:	89 e5                	mov    %esp,%ebp
  800880:	53                   	push   %ebx
  800881:	8b 45 08             	mov    0x8(%ebp),%eax
  800884:	8b 55 0c             	mov    0xc(%ebp),%edx
  800887:	89 c3                	mov    %eax,%ebx
  800889:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80088c:	eb 06                	jmp    800894 <strncmp+0x17>
		n--, p++, q++;
  80088e:	83 c0 01             	add    $0x1,%eax
  800891:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800894:	39 d8                	cmp    %ebx,%eax
  800896:	74 15                	je     8008ad <strncmp+0x30>
  800898:	0f b6 08             	movzbl (%eax),%ecx
  80089b:	84 c9                	test   %cl,%cl
  80089d:	74 04                	je     8008a3 <strncmp+0x26>
  80089f:	3a 0a                	cmp    (%edx),%cl
  8008a1:	74 eb                	je     80088e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a3:	0f b6 00             	movzbl (%eax),%eax
  8008a6:	0f b6 12             	movzbl (%edx),%edx
  8008a9:	29 d0                	sub    %edx,%eax
  8008ab:	eb 05                	jmp    8008b2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008ad:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008b2:	5b                   	pop    %ebx
  8008b3:	5d                   	pop    %ebp
  8008b4:	c3                   	ret    

008008b5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008b5:	55                   	push   %ebp
  8008b6:	89 e5                	mov    %esp,%ebp
  8008b8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008bf:	eb 07                	jmp    8008c8 <strchr+0x13>
		if (*s == c)
  8008c1:	38 ca                	cmp    %cl,%dl
  8008c3:	74 0f                	je     8008d4 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008c5:	83 c0 01             	add    $0x1,%eax
  8008c8:	0f b6 10             	movzbl (%eax),%edx
  8008cb:	84 d2                	test   %dl,%dl
  8008cd:	75 f2                	jne    8008c1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008d4:	5d                   	pop    %ebp
  8008d5:	c3                   	ret    

008008d6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008d6:	55                   	push   %ebp
  8008d7:	89 e5                	mov    %esp,%ebp
  8008d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e0:	eb 03                	jmp    8008e5 <strfind+0xf>
  8008e2:	83 c0 01             	add    $0x1,%eax
  8008e5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008e8:	38 ca                	cmp    %cl,%dl
  8008ea:	74 04                	je     8008f0 <strfind+0x1a>
  8008ec:	84 d2                	test   %dl,%dl
  8008ee:	75 f2                	jne    8008e2 <strfind+0xc>
			break;
	return (char *) s;
}
  8008f0:	5d                   	pop    %ebp
  8008f1:	c3                   	ret    

008008f2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f2:	55                   	push   %ebp
  8008f3:	89 e5                	mov    %esp,%ebp
  8008f5:	57                   	push   %edi
  8008f6:	56                   	push   %esi
  8008f7:	53                   	push   %ebx
  8008f8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008fb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008fe:	85 c9                	test   %ecx,%ecx
  800900:	74 36                	je     800938 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800902:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800908:	75 28                	jne    800932 <memset+0x40>
  80090a:	f6 c1 03             	test   $0x3,%cl
  80090d:	75 23                	jne    800932 <memset+0x40>
		c &= 0xFF;
  80090f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800913:	89 d3                	mov    %edx,%ebx
  800915:	c1 e3 08             	shl    $0x8,%ebx
  800918:	89 d6                	mov    %edx,%esi
  80091a:	c1 e6 18             	shl    $0x18,%esi
  80091d:	89 d0                	mov    %edx,%eax
  80091f:	c1 e0 10             	shl    $0x10,%eax
  800922:	09 f0                	or     %esi,%eax
  800924:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800926:	89 d8                	mov    %ebx,%eax
  800928:	09 d0                	or     %edx,%eax
  80092a:	c1 e9 02             	shr    $0x2,%ecx
  80092d:	fc                   	cld    
  80092e:	f3 ab                	rep stos %eax,%es:(%edi)
  800930:	eb 06                	jmp    800938 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800932:	8b 45 0c             	mov    0xc(%ebp),%eax
  800935:	fc                   	cld    
  800936:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800938:	89 f8                	mov    %edi,%eax
  80093a:	5b                   	pop    %ebx
  80093b:	5e                   	pop    %esi
  80093c:	5f                   	pop    %edi
  80093d:	5d                   	pop    %ebp
  80093e:	c3                   	ret    

0080093f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80093f:	55                   	push   %ebp
  800940:	89 e5                	mov    %esp,%ebp
  800942:	57                   	push   %edi
  800943:	56                   	push   %esi
  800944:	8b 45 08             	mov    0x8(%ebp),%eax
  800947:	8b 75 0c             	mov    0xc(%ebp),%esi
  80094a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80094d:	39 c6                	cmp    %eax,%esi
  80094f:	73 35                	jae    800986 <memmove+0x47>
  800951:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800954:	39 d0                	cmp    %edx,%eax
  800956:	73 2e                	jae    800986 <memmove+0x47>
		s += n;
		d += n;
  800958:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095b:	89 d6                	mov    %edx,%esi
  80095d:	09 fe                	or     %edi,%esi
  80095f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800965:	75 13                	jne    80097a <memmove+0x3b>
  800967:	f6 c1 03             	test   $0x3,%cl
  80096a:	75 0e                	jne    80097a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80096c:	83 ef 04             	sub    $0x4,%edi
  80096f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800972:	c1 e9 02             	shr    $0x2,%ecx
  800975:	fd                   	std    
  800976:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800978:	eb 09                	jmp    800983 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80097a:	83 ef 01             	sub    $0x1,%edi
  80097d:	8d 72 ff             	lea    -0x1(%edx),%esi
  800980:	fd                   	std    
  800981:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800983:	fc                   	cld    
  800984:	eb 1d                	jmp    8009a3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800986:	89 f2                	mov    %esi,%edx
  800988:	09 c2                	or     %eax,%edx
  80098a:	f6 c2 03             	test   $0x3,%dl
  80098d:	75 0f                	jne    80099e <memmove+0x5f>
  80098f:	f6 c1 03             	test   $0x3,%cl
  800992:	75 0a                	jne    80099e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800994:	c1 e9 02             	shr    $0x2,%ecx
  800997:	89 c7                	mov    %eax,%edi
  800999:	fc                   	cld    
  80099a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80099c:	eb 05                	jmp    8009a3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80099e:	89 c7                	mov    %eax,%edi
  8009a0:	fc                   	cld    
  8009a1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009a3:	5e                   	pop    %esi
  8009a4:	5f                   	pop    %edi
  8009a5:	5d                   	pop    %ebp
  8009a6:	c3                   	ret    

008009a7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009a7:	55                   	push   %ebp
  8009a8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009aa:	ff 75 10             	pushl  0x10(%ebp)
  8009ad:	ff 75 0c             	pushl  0xc(%ebp)
  8009b0:	ff 75 08             	pushl  0x8(%ebp)
  8009b3:	e8 87 ff ff ff       	call   80093f <memmove>
}
  8009b8:	c9                   	leave  
  8009b9:	c3                   	ret    

008009ba <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009ba:	55                   	push   %ebp
  8009bb:	89 e5                	mov    %esp,%ebp
  8009bd:	56                   	push   %esi
  8009be:	53                   	push   %ebx
  8009bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009c5:	89 c6                	mov    %eax,%esi
  8009c7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ca:	eb 1a                	jmp    8009e6 <memcmp+0x2c>
		if (*s1 != *s2)
  8009cc:	0f b6 08             	movzbl (%eax),%ecx
  8009cf:	0f b6 1a             	movzbl (%edx),%ebx
  8009d2:	38 d9                	cmp    %bl,%cl
  8009d4:	74 0a                	je     8009e0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d6:	0f b6 c1             	movzbl %cl,%eax
  8009d9:	0f b6 db             	movzbl %bl,%ebx
  8009dc:	29 d8                	sub    %ebx,%eax
  8009de:	eb 0f                	jmp    8009ef <memcmp+0x35>
		s1++, s2++;
  8009e0:	83 c0 01             	add    $0x1,%eax
  8009e3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e6:	39 f0                	cmp    %esi,%eax
  8009e8:	75 e2                	jne    8009cc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009ef:	5b                   	pop    %ebx
  8009f0:	5e                   	pop    %esi
  8009f1:	5d                   	pop    %ebp
  8009f2:	c3                   	ret    

008009f3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009f3:	55                   	push   %ebp
  8009f4:	89 e5                	mov    %esp,%ebp
  8009f6:	53                   	push   %ebx
  8009f7:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009fa:	89 c1                	mov    %eax,%ecx
  8009fc:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009ff:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a03:	eb 0a                	jmp    800a0f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a05:	0f b6 10             	movzbl (%eax),%edx
  800a08:	39 da                	cmp    %ebx,%edx
  800a0a:	74 07                	je     800a13 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0c:	83 c0 01             	add    $0x1,%eax
  800a0f:	39 c8                	cmp    %ecx,%eax
  800a11:	72 f2                	jb     800a05 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a13:	5b                   	pop    %ebx
  800a14:	5d                   	pop    %ebp
  800a15:	c3                   	ret    

00800a16 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a16:	55                   	push   %ebp
  800a17:	89 e5                	mov    %esp,%ebp
  800a19:	57                   	push   %edi
  800a1a:	56                   	push   %esi
  800a1b:	53                   	push   %ebx
  800a1c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a1f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a22:	eb 03                	jmp    800a27 <strtol+0x11>
		s++;
  800a24:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a27:	0f b6 01             	movzbl (%ecx),%eax
  800a2a:	3c 20                	cmp    $0x20,%al
  800a2c:	74 f6                	je     800a24 <strtol+0xe>
  800a2e:	3c 09                	cmp    $0x9,%al
  800a30:	74 f2                	je     800a24 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a32:	3c 2b                	cmp    $0x2b,%al
  800a34:	75 0a                	jne    800a40 <strtol+0x2a>
		s++;
  800a36:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a39:	bf 00 00 00 00       	mov    $0x0,%edi
  800a3e:	eb 11                	jmp    800a51 <strtol+0x3b>
  800a40:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a45:	3c 2d                	cmp    $0x2d,%al
  800a47:	75 08                	jne    800a51 <strtol+0x3b>
		s++, neg = 1;
  800a49:	83 c1 01             	add    $0x1,%ecx
  800a4c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a51:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a57:	75 15                	jne    800a6e <strtol+0x58>
  800a59:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5c:	75 10                	jne    800a6e <strtol+0x58>
  800a5e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a62:	75 7c                	jne    800ae0 <strtol+0xca>
		s += 2, base = 16;
  800a64:	83 c1 02             	add    $0x2,%ecx
  800a67:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a6c:	eb 16                	jmp    800a84 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a6e:	85 db                	test   %ebx,%ebx
  800a70:	75 12                	jne    800a84 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a72:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a77:	80 39 30             	cmpb   $0x30,(%ecx)
  800a7a:	75 08                	jne    800a84 <strtol+0x6e>
		s++, base = 8;
  800a7c:	83 c1 01             	add    $0x1,%ecx
  800a7f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a84:	b8 00 00 00 00       	mov    $0x0,%eax
  800a89:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a8c:	0f b6 11             	movzbl (%ecx),%edx
  800a8f:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a92:	89 f3                	mov    %esi,%ebx
  800a94:	80 fb 09             	cmp    $0x9,%bl
  800a97:	77 08                	ja     800aa1 <strtol+0x8b>
			dig = *s - '0';
  800a99:	0f be d2             	movsbl %dl,%edx
  800a9c:	83 ea 30             	sub    $0x30,%edx
  800a9f:	eb 22                	jmp    800ac3 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa1:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aa4:	89 f3                	mov    %esi,%ebx
  800aa6:	80 fb 19             	cmp    $0x19,%bl
  800aa9:	77 08                	ja     800ab3 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aab:	0f be d2             	movsbl %dl,%edx
  800aae:	83 ea 57             	sub    $0x57,%edx
  800ab1:	eb 10                	jmp    800ac3 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ab3:	8d 72 bf             	lea    -0x41(%edx),%esi
  800ab6:	89 f3                	mov    %esi,%ebx
  800ab8:	80 fb 19             	cmp    $0x19,%bl
  800abb:	77 16                	ja     800ad3 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800abd:	0f be d2             	movsbl %dl,%edx
  800ac0:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ac3:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ac6:	7d 0b                	jge    800ad3 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ac8:	83 c1 01             	add    $0x1,%ecx
  800acb:	0f af 45 10          	imul   0x10(%ebp),%eax
  800acf:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad1:	eb b9                	jmp    800a8c <strtol+0x76>

	if (endptr)
  800ad3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ad7:	74 0d                	je     800ae6 <strtol+0xd0>
		*endptr = (char *) s;
  800ad9:	8b 75 0c             	mov    0xc(%ebp),%esi
  800adc:	89 0e                	mov    %ecx,(%esi)
  800ade:	eb 06                	jmp    800ae6 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae0:	85 db                	test   %ebx,%ebx
  800ae2:	74 98                	je     800a7c <strtol+0x66>
  800ae4:	eb 9e                	jmp    800a84 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ae6:	89 c2                	mov    %eax,%edx
  800ae8:	f7 da                	neg    %edx
  800aea:	85 ff                	test   %edi,%edi
  800aec:	0f 45 c2             	cmovne %edx,%eax
}
  800aef:	5b                   	pop    %ebx
  800af0:	5e                   	pop    %esi
  800af1:	5f                   	pop    %edi
  800af2:	5d                   	pop    %ebp
  800af3:	c3                   	ret    

00800af4 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800af4:	55                   	push   %ebp
  800af5:	89 e5                	mov    %esp,%ebp
  800af7:	57                   	push   %edi
  800af8:	56                   	push   %esi
  800af9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800afa:	b8 00 00 00 00       	mov    $0x0,%eax
  800aff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b02:	8b 55 08             	mov    0x8(%ebp),%edx
  800b05:	89 c3                	mov    %eax,%ebx
  800b07:	89 c7                	mov    %eax,%edi
  800b09:	89 c6                	mov    %eax,%esi
  800b0b:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b0d:	5b                   	pop    %ebx
  800b0e:	5e                   	pop    %esi
  800b0f:	5f                   	pop    %edi
  800b10:	5d                   	pop    %ebp
  800b11:	c3                   	ret    

00800b12 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b12:	55                   	push   %ebp
  800b13:	89 e5                	mov    %esp,%ebp
  800b15:	57                   	push   %edi
  800b16:	56                   	push   %esi
  800b17:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b18:	ba 00 00 00 00       	mov    $0x0,%edx
  800b1d:	b8 01 00 00 00       	mov    $0x1,%eax
  800b22:	89 d1                	mov    %edx,%ecx
  800b24:	89 d3                	mov    %edx,%ebx
  800b26:	89 d7                	mov    %edx,%edi
  800b28:	89 d6                	mov    %edx,%esi
  800b2a:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b2c:	5b                   	pop    %ebx
  800b2d:	5e                   	pop    %esi
  800b2e:	5f                   	pop    %edi
  800b2f:	5d                   	pop    %ebp
  800b30:	c3                   	ret    

00800b31 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b31:	55                   	push   %ebp
  800b32:	89 e5                	mov    %esp,%ebp
  800b34:	57                   	push   %edi
  800b35:	56                   	push   %esi
  800b36:	53                   	push   %ebx
  800b37:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b3a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b3f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b44:	8b 55 08             	mov    0x8(%ebp),%edx
  800b47:	89 cb                	mov    %ecx,%ebx
  800b49:	89 cf                	mov    %ecx,%edi
  800b4b:	89 ce                	mov    %ecx,%esi
  800b4d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b4f:	85 c0                	test   %eax,%eax
  800b51:	7e 17                	jle    800b6a <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b53:	83 ec 0c             	sub    $0xc,%esp
  800b56:	50                   	push   %eax
  800b57:	6a 03                	push   $0x3
  800b59:	68 64 17 80 00       	push   $0x801764
  800b5e:	6a 23                	push   $0x23
  800b60:	68 81 17 80 00       	push   $0x801781
  800b65:	e8 13 06 00 00       	call   80117d <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b6d:	5b                   	pop    %ebx
  800b6e:	5e                   	pop    %esi
  800b6f:	5f                   	pop    %edi
  800b70:	5d                   	pop    %ebp
  800b71:	c3                   	ret    

00800b72 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b72:	55                   	push   %ebp
  800b73:	89 e5                	mov    %esp,%ebp
  800b75:	57                   	push   %edi
  800b76:	56                   	push   %esi
  800b77:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b78:	ba 00 00 00 00       	mov    $0x0,%edx
  800b7d:	b8 02 00 00 00       	mov    $0x2,%eax
  800b82:	89 d1                	mov    %edx,%ecx
  800b84:	89 d3                	mov    %edx,%ebx
  800b86:	89 d7                	mov    %edx,%edi
  800b88:	89 d6                	mov    %edx,%esi
  800b8a:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b8c:	5b                   	pop    %ebx
  800b8d:	5e                   	pop    %esi
  800b8e:	5f                   	pop    %edi
  800b8f:	5d                   	pop    %ebp
  800b90:	c3                   	ret    

00800b91 <sys_yield>:

void
sys_yield(void)
{
  800b91:	55                   	push   %ebp
  800b92:	89 e5                	mov    %esp,%ebp
  800b94:	57                   	push   %edi
  800b95:	56                   	push   %esi
  800b96:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b97:	ba 00 00 00 00       	mov    $0x0,%edx
  800b9c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800ba1:	89 d1                	mov    %edx,%ecx
  800ba3:	89 d3                	mov    %edx,%ebx
  800ba5:	89 d7                	mov    %edx,%edi
  800ba7:	89 d6                	mov    %edx,%esi
  800ba9:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800bab:	5b                   	pop    %ebx
  800bac:	5e                   	pop    %esi
  800bad:	5f                   	pop    %edi
  800bae:	5d                   	pop    %ebp
  800baf:	c3                   	ret    

00800bb0 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800bb0:	55                   	push   %ebp
  800bb1:	89 e5                	mov    %esp,%ebp
  800bb3:	57                   	push   %edi
  800bb4:	56                   	push   %esi
  800bb5:	53                   	push   %ebx
  800bb6:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb9:	be 00 00 00 00       	mov    $0x0,%esi
  800bbe:	b8 04 00 00 00       	mov    $0x4,%eax
  800bc3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bc6:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bcc:	89 f7                	mov    %esi,%edi
  800bce:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bd0:	85 c0                	test   %eax,%eax
  800bd2:	7e 17                	jle    800beb <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bd4:	83 ec 0c             	sub    $0xc,%esp
  800bd7:	50                   	push   %eax
  800bd8:	6a 04                	push   $0x4
  800bda:	68 64 17 80 00       	push   $0x801764
  800bdf:	6a 23                	push   $0x23
  800be1:	68 81 17 80 00       	push   $0x801781
  800be6:	e8 92 05 00 00       	call   80117d <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800beb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bee:	5b                   	pop    %ebx
  800bef:	5e                   	pop    %esi
  800bf0:	5f                   	pop    %edi
  800bf1:	5d                   	pop    %ebp
  800bf2:	c3                   	ret    

00800bf3 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800bf3:	55                   	push   %ebp
  800bf4:	89 e5                	mov    %esp,%ebp
  800bf6:	57                   	push   %edi
  800bf7:	56                   	push   %esi
  800bf8:	53                   	push   %ebx
  800bf9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bfc:	b8 05 00 00 00       	mov    $0x5,%eax
  800c01:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c04:	8b 55 08             	mov    0x8(%ebp),%edx
  800c07:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c0a:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c0d:	8b 75 18             	mov    0x18(%ebp),%esi
  800c10:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c12:	85 c0                	test   %eax,%eax
  800c14:	7e 17                	jle    800c2d <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c16:	83 ec 0c             	sub    $0xc,%esp
  800c19:	50                   	push   %eax
  800c1a:	6a 05                	push   $0x5
  800c1c:	68 64 17 80 00       	push   $0x801764
  800c21:	6a 23                	push   $0x23
  800c23:	68 81 17 80 00       	push   $0x801781
  800c28:	e8 50 05 00 00       	call   80117d <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c2d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c30:	5b                   	pop    %ebx
  800c31:	5e                   	pop    %esi
  800c32:	5f                   	pop    %edi
  800c33:	5d                   	pop    %ebp
  800c34:	c3                   	ret    

00800c35 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c35:	55                   	push   %ebp
  800c36:	89 e5                	mov    %esp,%ebp
  800c38:	57                   	push   %edi
  800c39:	56                   	push   %esi
  800c3a:	53                   	push   %ebx
  800c3b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c3e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c43:	b8 06 00 00 00       	mov    $0x6,%eax
  800c48:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c4b:	8b 55 08             	mov    0x8(%ebp),%edx
  800c4e:	89 df                	mov    %ebx,%edi
  800c50:	89 de                	mov    %ebx,%esi
  800c52:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c54:	85 c0                	test   %eax,%eax
  800c56:	7e 17                	jle    800c6f <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c58:	83 ec 0c             	sub    $0xc,%esp
  800c5b:	50                   	push   %eax
  800c5c:	6a 06                	push   $0x6
  800c5e:	68 64 17 80 00       	push   $0x801764
  800c63:	6a 23                	push   $0x23
  800c65:	68 81 17 80 00       	push   $0x801781
  800c6a:	e8 0e 05 00 00       	call   80117d <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c6f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c72:	5b                   	pop    %ebx
  800c73:	5e                   	pop    %esi
  800c74:	5f                   	pop    %edi
  800c75:	5d                   	pop    %ebp
  800c76:	c3                   	ret    

00800c77 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c77:	55                   	push   %ebp
  800c78:	89 e5                	mov    %esp,%ebp
  800c7a:	57                   	push   %edi
  800c7b:	56                   	push   %esi
  800c7c:	53                   	push   %ebx
  800c7d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c80:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c85:	b8 08 00 00 00       	mov    $0x8,%eax
  800c8a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c8d:	8b 55 08             	mov    0x8(%ebp),%edx
  800c90:	89 df                	mov    %ebx,%edi
  800c92:	89 de                	mov    %ebx,%esi
  800c94:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c96:	85 c0                	test   %eax,%eax
  800c98:	7e 17                	jle    800cb1 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c9a:	83 ec 0c             	sub    $0xc,%esp
  800c9d:	50                   	push   %eax
  800c9e:	6a 08                	push   $0x8
  800ca0:	68 64 17 80 00       	push   $0x801764
  800ca5:	6a 23                	push   $0x23
  800ca7:	68 81 17 80 00       	push   $0x801781
  800cac:	e8 cc 04 00 00       	call   80117d <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800cb1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cb4:	5b                   	pop    %ebx
  800cb5:	5e                   	pop    %esi
  800cb6:	5f                   	pop    %edi
  800cb7:	5d                   	pop    %ebp
  800cb8:	c3                   	ret    

00800cb9 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800cb9:	55                   	push   %ebp
  800cba:	89 e5                	mov    %esp,%ebp
  800cbc:	57                   	push   %edi
  800cbd:	56                   	push   %esi
  800cbe:	53                   	push   %ebx
  800cbf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cc2:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cc7:	b8 09 00 00 00       	mov    $0x9,%eax
  800ccc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ccf:	8b 55 08             	mov    0x8(%ebp),%edx
  800cd2:	89 df                	mov    %ebx,%edi
  800cd4:	89 de                	mov    %ebx,%esi
  800cd6:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cd8:	85 c0                	test   %eax,%eax
  800cda:	7e 17                	jle    800cf3 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cdc:	83 ec 0c             	sub    $0xc,%esp
  800cdf:	50                   	push   %eax
  800ce0:	6a 09                	push   $0x9
  800ce2:	68 64 17 80 00       	push   $0x801764
  800ce7:	6a 23                	push   $0x23
  800ce9:	68 81 17 80 00       	push   $0x801781
  800cee:	e8 8a 04 00 00       	call   80117d <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800cf3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cf6:	5b                   	pop    %ebx
  800cf7:	5e                   	pop    %esi
  800cf8:	5f                   	pop    %edi
  800cf9:	5d                   	pop    %ebp
  800cfa:	c3                   	ret    

00800cfb <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800cfb:	55                   	push   %ebp
  800cfc:	89 e5                	mov    %esp,%ebp
  800cfe:	57                   	push   %edi
  800cff:	56                   	push   %esi
  800d00:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d01:	be 00 00 00 00       	mov    $0x0,%esi
  800d06:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d0e:	8b 55 08             	mov    0x8(%ebp),%edx
  800d11:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d14:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d17:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d19:	5b                   	pop    %ebx
  800d1a:	5e                   	pop    %esi
  800d1b:	5f                   	pop    %edi
  800d1c:	5d                   	pop    %ebp
  800d1d:	c3                   	ret    

00800d1e <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d1e:	55                   	push   %ebp
  800d1f:	89 e5                	mov    %esp,%ebp
  800d21:	57                   	push   %edi
  800d22:	56                   	push   %esi
  800d23:	53                   	push   %ebx
  800d24:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d27:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d2c:	b8 0c 00 00 00       	mov    $0xc,%eax
  800d31:	8b 55 08             	mov    0x8(%ebp),%edx
  800d34:	89 cb                	mov    %ecx,%ebx
  800d36:	89 cf                	mov    %ecx,%edi
  800d38:	89 ce                	mov    %ecx,%esi
  800d3a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d3c:	85 c0                	test   %eax,%eax
  800d3e:	7e 17                	jle    800d57 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d40:	83 ec 0c             	sub    $0xc,%esp
  800d43:	50                   	push   %eax
  800d44:	6a 0c                	push   $0xc
  800d46:	68 64 17 80 00       	push   $0x801764
  800d4b:	6a 23                	push   $0x23
  800d4d:	68 81 17 80 00       	push   $0x801781
  800d52:	e8 26 04 00 00       	call   80117d <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800d57:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d5a:	5b                   	pop    %ebx
  800d5b:	5e                   	pop    %esi
  800d5c:	5f                   	pop    %edi
  800d5d:	5d                   	pop    %ebp
  800d5e:	c3                   	ret    

00800d5f <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800d5f:	55                   	push   %ebp
  800d60:	89 e5                	mov    %esp,%ebp
  800d62:	53                   	push   %ebx
  800d63:	83 ec 04             	sub    $0x4,%esp
  800d66:	8b 45 08             	mov    0x8(%ebp),%eax
void *addr = (void *) utf->utf_fault_va;
  800d69:	8b 18                	mov    (%eax),%ebx
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	if ((err & FEC_WR) == 0)
  800d6b:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800d6f:	75 12                	jne    800d83 <pgfault+0x24>
		panic("pgfault: faulting address [%08x] not a write\n", addr);
  800d71:	53                   	push   %ebx
  800d72:	68 90 17 80 00       	push   $0x801790
  800d77:	6a 1f                	push   $0x1f
  800d79:	68 10 18 80 00       	push   $0x801810
  800d7e:	e8 fa 03 00 00       	call   80117d <_panic>

	if (!(uvpt[PGNUM(addr)] & PTE_COW))
  800d83:	89 d8                	mov    %ebx,%eax
  800d85:	c1 e8 0c             	shr    $0xc,%eax
  800d88:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800d8f:	f6 c4 08             	test   $0x8,%ah
  800d92:	75 14                	jne    800da8 <pgfault+0x49>
		panic("pgfault: fault was not on a copy-on-write page\n");
  800d94:	83 ec 04             	sub    $0x4,%esp
  800d97:	68 c0 17 80 00       	push   $0x8017c0
  800d9c:	6a 22                	push   $0x22
  800d9e:	68 10 18 80 00       	push   $0x801810
  800da3:	e8 d5 03 00 00       	call   80117d <_panic>
	//   You should make three system calls.

	// LAB 4: Your code here.


	if ((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0)
  800da8:	83 ec 04             	sub    $0x4,%esp
  800dab:	6a 07                	push   $0x7
  800dad:	68 00 f0 7f 00       	push   $0x7ff000
  800db2:	6a 00                	push   $0x0
  800db4:	e8 f7 fd ff ff       	call   800bb0 <sys_page_alloc>
  800db9:	83 c4 10             	add    $0x10,%esp
  800dbc:	85 c0                	test   %eax,%eax
  800dbe:	79 12                	jns    800dd2 <pgfault+0x73>
		panic("sys_page_alloc: %e\n", r);
  800dc0:	50                   	push   %eax
  800dc1:	68 1b 18 80 00       	push   $0x80181b
  800dc6:	6a 30                	push   $0x30
  800dc8:	68 10 18 80 00       	push   $0x801810
  800dcd:	e8 ab 03 00 00       	call   80117d <_panic>


	void *src_addr = (void *) ROUNDDOWN(addr, PGSIZE);
  800dd2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove(PFTEMP, src_addr, PGSIZE);
  800dd8:	83 ec 04             	sub    $0x4,%esp
  800ddb:	68 00 10 00 00       	push   $0x1000
  800de0:	53                   	push   %ebx
  800de1:	68 00 f0 7f 00       	push   $0x7ff000
  800de6:	e8 54 fb ff ff       	call   80093f <memmove>

	
	if ((r = sys_page_map(0, PFTEMP, 0, src_addr, PTE_P | PTE_U | PTE_W)) < 0)
  800deb:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800df2:	53                   	push   %ebx
  800df3:	6a 00                	push   $0x0
  800df5:	68 00 f0 7f 00       	push   $0x7ff000
  800dfa:	6a 00                	push   $0x0
  800dfc:	e8 f2 fd ff ff       	call   800bf3 <sys_page_map>
  800e01:	83 c4 20             	add    $0x20,%esp
  800e04:	85 c0                	test   %eax,%eax
  800e06:	79 12                	jns    800e1a <pgfault+0xbb>
	panic("sys_page_map: %e\n", r);
  800e08:	50                   	push   %eax
  800e09:	68 2f 18 80 00       	push   $0x80182f
  800e0e:	6a 38                	push   $0x38
  800e10:	68 10 18 80 00       	push   $0x801810
  800e15:	e8 63 03 00 00       	call   80117d <_panic>

}
  800e1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800e1d:	c9                   	leave  
  800e1e:	c3                   	ret    

00800e1f <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800e1f:	55                   	push   %ebp
  800e20:	89 e5                	mov    %esp,%ebp
  800e22:	57                   	push   %edi
  800e23:	56                   	push   %esi
  800e24:	53                   	push   %ebx
  800e25:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	int r;
	envid_t child_envid;

	set_pgfault_handler(pgfault);
  800e28:	68 5f 0d 80 00       	push   $0x800d5f
  800e2d:	e8 91 03 00 00       	call   8011c3 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800e32:	b8 07 00 00 00       	mov    $0x7,%eax
  800e37:	cd 30                	int    $0x30
  800e39:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800e3c:	89 45 e0             	mov    %eax,-0x20(%ebp)

	child_envid = sys_exofork();
	if (child_envid < 0)
  800e3f:	83 c4 10             	add    $0x10,%esp
  800e42:	85 c0                	test   %eax,%eax
  800e44:	79 15                	jns    800e5b <fork+0x3c>
		panic("sys_exofork: %e\n", child_envid);
  800e46:	50                   	push   %eax
  800e47:	68 41 18 80 00       	push   $0x801841
  800e4c:	68 82 00 00 00       	push   $0x82
  800e51:	68 10 18 80 00       	push   $0x801810
  800e56:	e8 22 03 00 00       	call   80117d <_panic>
  800e5b:	bf 00 00 00 00       	mov    $0x0,%edi
  800e60:	bb 00 00 00 00       	mov    $0x0,%ebx
	if (child_envid == 0) { // child
  800e65:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800e69:	75 21                	jne    800e8c <fork+0x6d>
		// Fix thisenv like dumbfork does and return 0
		thisenv = &envs[ENVX(sys_getenvid())];
  800e6b:	e8 02 fd ff ff       	call   800b72 <sys_getenvid>
  800e70:	25 ff 03 00 00       	and    $0x3ff,%eax
  800e75:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800e78:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800e7d:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800e82:	b8 00 00 00 00       	mov    $0x0,%eax
  800e87:	e9 c7 01 00 00       	jmp    801053 <fork+0x234>


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
		uint32_t pdx = ROUNDDOWN(page_num, NPDENTRIES) / NPDENTRIES;
  800e8c:	89 d8                	mov    %ebx,%eax
  800e8e:	c1 e8 0a             	shr    $0xa,%eax
		if ((uvpd[pdx] & PTE_P) == PTE_P &&((uvpt[page_num] & PTE_P) == PTE_P)) {
  800e91:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800e98:	a8 01                	test   $0x1,%al
  800e9a:	0f 84 18 01 00 00    	je     800fb8 <fork+0x199>
  800ea0:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800ea7:	a8 01                	test   $0x1,%al
  800ea9:	0f 84 09 01 00 00    	je     800fb8 <fork+0x199>
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uint32_t perm = PTE_P | PTE_COW;
	envid_t this_envid = thisenv->env_id;
  800eaf:	a1 04 20 80 00       	mov    0x802004,%eax
  800eb4:	8b 40 48             	mov    0x48(%eax),%eax
  800eb7:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// LAB 4: Your code here.
	if (uvpt[pn] & PTE_SHARE) {
  800eba:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800ec1:	f6 c4 04             	test   $0x4,%ah
  800ec4:	74 3a                	je     800f00 <fork+0xe1>
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), uvpt[pn] & PTE_SYSCALL)) < 0)
  800ec6:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800ecd:	83 ec 0c             	sub    $0xc,%esp
  800ed0:	25 07 0e 00 00       	and    $0xe07,%eax
  800ed5:	50                   	push   %eax
  800ed6:	57                   	push   %edi
  800ed7:	ff 75 e0             	pushl  -0x20(%ebp)
  800eda:	57                   	push   %edi
  800edb:	ff 75 e4             	pushl  -0x1c(%ebp)
  800ede:	e8 10 fd ff ff       	call   800bf3 <sys_page_map>
  800ee3:	83 c4 20             	add    $0x20,%esp
  800ee6:	85 c0                	test   %eax,%eax
  800ee8:	0f 89 ca 00 00 00    	jns    800fb8 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  800eee:	50                   	push   %eax
  800eef:	68 2f 18 80 00       	push   $0x80182f
  800ef4:	6a 51                	push   $0x51
  800ef6:	68 10 18 80 00       	push   $0x801810
  800efb:	e8 7d 02 00 00       	call   80117d <_panic>
	} else if (uvpt[pn] & PTE_COW || uvpt[pn] & PTE_W) {
  800f00:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f07:	f6 c4 08             	test   $0x8,%ah
  800f0a:	75 0b                	jne    800f17 <fork+0xf8>
  800f0c:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f13:	a8 02                	test   $0x2,%al
  800f15:	74 6b                	je     800f82 <fork+0x163>
		if (uvpt[pn] & PTE_U)
  800f17:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f1e:	83 e0 04             	and    $0x4,%eax
			perm |= PTE_U;
  800f21:	83 f8 01             	cmp    $0x1,%eax
  800f24:	19 f6                	sbb    %esi,%esi
  800f26:	83 e6 fc             	and    $0xfffffffc,%esi
  800f29:	81 c6 05 08 00 00    	add    $0x805,%esi

		// Map page COW, U and P in child
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), perm)) < 0)
  800f2f:	83 ec 0c             	sub    $0xc,%esp
  800f32:	56                   	push   %esi
  800f33:	57                   	push   %edi
  800f34:	ff 75 e0             	pushl  -0x20(%ebp)
  800f37:	57                   	push   %edi
  800f38:	ff 75 e4             	pushl  -0x1c(%ebp)
  800f3b:	e8 b3 fc ff ff       	call   800bf3 <sys_page_map>
  800f40:	83 c4 20             	add    $0x20,%esp
  800f43:	85 c0                	test   %eax,%eax
  800f45:	79 12                	jns    800f59 <fork+0x13a>
			panic("sys_page_map: %e\n", r);
  800f47:	50                   	push   %eax
  800f48:	68 2f 18 80 00       	push   $0x80182f
  800f4d:	6a 58                	push   $0x58
  800f4f:	68 10 18 80 00       	push   $0x801810
  800f54:	e8 24 02 00 00       	call   80117d <_panic>

		// Map page COW, U and P in parent
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), this_envid, (void *) (pn*PGSIZE), perm)) < 0)
  800f59:	83 ec 0c             	sub    $0xc,%esp
  800f5c:	56                   	push   %esi
  800f5d:	57                   	push   %edi
  800f5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800f61:	50                   	push   %eax
  800f62:	57                   	push   %edi
  800f63:	50                   	push   %eax
  800f64:	e8 8a fc ff ff       	call   800bf3 <sys_page_map>
  800f69:	83 c4 20             	add    $0x20,%esp
  800f6c:	85 c0                	test   %eax,%eax
  800f6e:	79 48                	jns    800fb8 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  800f70:	50                   	push   %eax
  800f71:	68 2f 18 80 00       	push   $0x80182f
  800f76:	6a 5c                	push   $0x5c
  800f78:	68 10 18 80 00       	push   $0x801810
  800f7d:	e8 fb 01 00 00       	call   80117d <_panic>

	} else { // map pages that are present but not writable or COW with their original permissions
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), uvpt[pn] & PTE_SYSCALL)) < 0)
  800f82:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f89:	83 ec 0c             	sub    $0xc,%esp
  800f8c:	25 07 0e 00 00       	and    $0xe07,%eax
  800f91:	50                   	push   %eax
  800f92:	57                   	push   %edi
  800f93:	ff 75 e0             	pushl  -0x20(%ebp)
  800f96:	57                   	push   %edi
  800f97:	ff 75 e4             	pushl  -0x1c(%ebp)
  800f9a:	e8 54 fc ff ff       	call   800bf3 <sys_page_map>
  800f9f:	83 c4 20             	add    $0x20,%esp
  800fa2:	85 c0                	test   %eax,%eax
  800fa4:	79 12                	jns    800fb8 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  800fa6:	50                   	push   %eax
  800fa7:	68 2f 18 80 00       	push   $0x80182f
  800fac:	6a 60                	push   $0x60
  800fae:	68 10 18 80 00       	push   $0x801810
  800fb3:	e8 c5 01 00 00       	call   80117d <_panic>
	// We're in the parent


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
  800fb8:	83 c3 01             	add    $0x1,%ebx
  800fbb:	81 c7 00 10 00 00    	add    $0x1000,%edi
  800fc1:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  800fc7:	0f 85 bf fe ff ff    	jne    800e8c <fork+0x6d>
		}
	}

	// Allocate exception stack space for child
	
	if ((r = sys_page_alloc(child_envid, (void *) (UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W)) < 0)
  800fcd:	83 ec 04             	sub    $0x4,%esp
  800fd0:	6a 07                	push   $0x7
  800fd2:	68 00 f0 bf ee       	push   $0xeebff000
  800fd7:	ff 75 dc             	pushl  -0x24(%ebp)
  800fda:	e8 d1 fb ff ff       	call   800bb0 <sys_page_alloc>
  800fdf:	83 c4 10             	add    $0x10,%esp
  800fe2:	85 c0                	test   %eax,%eax
  800fe4:	79 15                	jns    800ffb <fork+0x1dc>
		panic("sys_page_alloc: %e\n", r);
  800fe6:	50                   	push   %eax
  800fe7:	68 1b 18 80 00       	push   $0x80181b
  800fec:	68 98 00 00 00       	push   $0x98
  800ff1:	68 10 18 80 00       	push   $0x801810
  800ff6:	e8 82 01 00 00       	call   80117d <_panic>

	// Set page fault handler for the child
	if ((r = sys_env_set_pgfault_upcall(child_envid, _pgfault_upcall)) < 0)
  800ffb:	83 ec 08             	sub    $0x8,%esp
  800ffe:	68 18 12 80 00       	push   $0x801218
  801003:	ff 75 dc             	pushl  -0x24(%ebp)
  801006:	e8 ae fc ff ff       	call   800cb9 <sys_env_set_pgfault_upcall>
  80100b:	83 c4 10             	add    $0x10,%esp
  80100e:	85 c0                	test   %eax,%eax
  801010:	79 15                	jns    801027 <fork+0x208>
		panic("sys_env_set_pgfault_upcall: %e\n", r);
  801012:	50                   	push   %eax
  801013:	68 f0 17 80 00       	push   $0x8017f0
  801018:	68 9c 00 00 00       	push   $0x9c
  80101d:	68 10 18 80 00       	push   $0x801810
  801022:	e8 56 01 00 00       	call   80117d <_panic>

	// Mark child environment as runnable
	if ((r = sys_env_set_status(child_envid, ENV_RUNNABLE)) < 0)
  801027:	83 ec 08             	sub    $0x8,%esp
  80102a:	6a 02                	push   $0x2
  80102c:	ff 75 dc             	pushl  -0x24(%ebp)
  80102f:	e8 43 fc ff ff       	call   800c77 <sys_env_set_status>
  801034:	83 c4 10             	add    $0x10,%esp
  801037:	85 c0                	test   %eax,%eax
  801039:	79 15                	jns    801050 <fork+0x231>
		panic("sys_env_set_status: %e\n", r);
  80103b:	50                   	push   %eax
  80103c:	68 52 18 80 00       	push   $0x801852
  801041:	68 a0 00 00 00       	push   $0xa0
  801046:	68 10 18 80 00       	push   $0x801810
  80104b:	e8 2d 01 00 00       	call   80117d <_panic>

	return child_envid;
  801050:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  801053:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801056:	5b                   	pop    %ebx
  801057:	5e                   	pop    %esi
  801058:	5f                   	pop    %edi
  801059:	5d                   	pop    %ebp
  80105a:	c3                   	ret    

0080105b <sfork>:

// Challenge!
int
sfork(void)
{
  80105b:	55                   	push   %ebp
  80105c:	89 e5                	mov    %esp,%ebp
  80105e:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  801061:	68 6a 18 80 00       	push   $0x80186a
  801066:	68 a9 00 00 00       	push   $0xa9
  80106b:	68 10 18 80 00       	push   $0x801810
  801070:	e8 08 01 00 00       	call   80117d <_panic>

00801075 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801075:	55                   	push   %ebp
  801076:	89 e5                	mov    %esp,%ebp
  801078:	56                   	push   %esi
  801079:	53                   	push   %ebx
  80107a:	8b 75 08             	mov    0x8(%ebp),%esi
  80107d:	8b 45 0c             	mov    0xc(%ebp),%eax
  801080:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.

	int r;
	if (pg == NULL)
  801083:	85 c0                	test   %eax,%eax
		pg = (void *) KERNBASE; // KERNBASE should be rejected by sys_ipc_recv()
  801085:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
  80108a:	0f 44 c2             	cmove  %edx,%eax

	if ((r = sys_ipc_recv(pg)) != 0) {
  80108d:	83 ec 0c             	sub    $0xc,%esp
  801090:	50                   	push   %eax
  801091:	e8 88 fc ff ff       	call   800d1e <sys_ipc_recv>
  801096:	83 c4 10             	add    $0x10,%esp
  801099:	85 c0                	test   %eax,%eax
  80109b:	74 16                	je     8010b3 <ipc_recv+0x3e>
		if (from_env_store != NULL)
  80109d:	85 f6                	test   %esi,%esi
  80109f:	74 06                	je     8010a7 <ipc_recv+0x32>
			*from_env_store = 0;
  8010a1:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (perm_store != NULL)
  8010a7:	85 db                	test   %ebx,%ebx
  8010a9:	74 2c                	je     8010d7 <ipc_recv+0x62>
			*perm_store = 0;
  8010ab:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8010b1:	eb 24                	jmp    8010d7 <ipc_recv+0x62>
		return r;
	}

	if (from_env_store != NULL)
  8010b3:	85 f6                	test   %esi,%esi
  8010b5:	74 0a                	je     8010c1 <ipc_recv+0x4c>
		*from_env_store = thisenv->env_ipc_from;
  8010b7:	a1 04 20 80 00       	mov    0x802004,%eax
  8010bc:	8b 40 74             	mov    0x74(%eax),%eax
  8010bf:	89 06                	mov    %eax,(%esi)
	if (perm_store != NULL)
  8010c1:	85 db                	test   %ebx,%ebx
  8010c3:	74 0a                	je     8010cf <ipc_recv+0x5a>
		*perm_store = thisenv->env_ipc_perm;
  8010c5:	a1 04 20 80 00       	mov    0x802004,%eax
  8010ca:	8b 40 78             	mov    0x78(%eax),%eax
  8010cd:	89 03                	mov    %eax,(%ebx)

return thisenv->env_ipc_value;
  8010cf:	a1 04 20 80 00       	mov    0x802004,%eax
  8010d4:	8b 40 70             	mov    0x70(%eax),%eax
	return 0;
}
  8010d7:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8010da:	5b                   	pop    %ebx
  8010db:	5e                   	pop    %esi
  8010dc:	5d                   	pop    %ebp
  8010dd:	c3                   	ret    

008010de <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  8010de:	55                   	push   %ebp
  8010df:	89 e5                	mov    %esp,%ebp
  8010e1:	57                   	push   %edi
  8010e2:	56                   	push   %esi
  8010e3:	53                   	push   %ebx
  8010e4:	83 ec 0c             	sub    $0xc,%esp
  8010e7:	8b 75 0c             	mov    0xc(%ebp),%esi
  8010ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8010ed:	8b 7d 14             	mov    0x14(%ebp),%edi
	// LAB 4: Your code here.
	if (pg == NULL)
		pg = (void *) KERNBASE;
  8010f0:	85 db                	test   %ebx,%ebx
  8010f2:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  8010f7:	0f 44 d8             	cmove  %eax,%ebx

	int r = sys_ipc_try_send(to_env, val, pg, perm);
  8010fa:	57                   	push   %edi
  8010fb:	53                   	push   %ebx
  8010fc:	56                   	push   %esi
  8010fd:	ff 75 08             	pushl  0x8(%ebp)
  801100:	e8 f6 fb ff ff       	call   800cfb <sys_ipc_try_send>

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  801105:	83 c4 10             	add    $0x10,%esp
  801108:	eb 17                	jmp    801121 <ipc_send+0x43>
		if (r == 0)
  80110a:	85 c0                	test   %eax,%eax
  80110c:	74 2e                	je     80113c <ipc_send+0x5e>
			return;

		sys_yield(); // release CPU before attempting to send again
  80110e:	e8 7e fa ff ff       	call   800b91 <sys_yield>

		r = sys_ipc_try_send(to_env, val, pg, perm);
  801113:	57                   	push   %edi
  801114:	53                   	push   %ebx
  801115:	56                   	push   %esi
  801116:	ff 75 08             	pushl  0x8(%ebp)
  801119:	e8 dd fb ff ff       	call   800cfb <sys_ipc_try_send>
  80111e:	83 c4 10             	add    $0x10,%esp
	if (pg == NULL)
		pg = (void *) KERNBASE;

	int r = sys_ipc_try_send(to_env, val, pg, perm);

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  801121:	83 f8 f9             	cmp    $0xfffffff9,%eax
  801124:	74 e4                	je     80110a <ipc_send+0x2c>
  801126:	85 c0                	test   %eax,%eax
  801128:	74 e0                	je     80110a <ipc_send+0x2c>
		sys_yield(); // release CPU before attempting to send again

		r = sys_ipc_try_send(to_env, val, pg, perm);
	}

panic("ipc_send: %e\n", r);
  80112a:	50                   	push   %eax
  80112b:	68 80 18 80 00       	push   $0x801880
  801130:	6a 4a                	push   $0x4a
  801132:	68 8e 18 80 00       	push   $0x80188e
  801137:	e8 41 00 00 00       	call   80117d <_panic>
}
  80113c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80113f:	5b                   	pop    %ebx
  801140:	5e                   	pop    %esi
  801141:	5f                   	pop    %edi
  801142:	5d                   	pop    %ebp
  801143:	c3                   	ret    

00801144 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  801144:	55                   	push   %ebp
  801145:	89 e5                	mov    %esp,%ebp
  801147:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  80114a:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  80114f:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801152:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801158:	8b 52 50             	mov    0x50(%edx),%edx
  80115b:	39 ca                	cmp    %ecx,%edx
  80115d:	75 0d                	jne    80116c <ipc_find_env+0x28>
			return envs[i].env_id;
  80115f:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801162:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801167:	8b 40 48             	mov    0x48(%eax),%eax
  80116a:	eb 0f                	jmp    80117b <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  80116c:	83 c0 01             	add    $0x1,%eax
  80116f:	3d 00 04 00 00       	cmp    $0x400,%eax
  801174:	75 d9                	jne    80114f <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801176:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80117b:	5d                   	pop    %ebp
  80117c:	c3                   	ret    

0080117d <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80117d:	55                   	push   %ebp
  80117e:	89 e5                	mov    %esp,%ebp
  801180:	56                   	push   %esi
  801181:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  801182:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801185:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80118b:	e8 e2 f9 ff ff       	call   800b72 <sys_getenvid>
  801190:	83 ec 0c             	sub    $0xc,%esp
  801193:	ff 75 0c             	pushl  0xc(%ebp)
  801196:	ff 75 08             	pushl  0x8(%ebp)
  801199:	56                   	push   %esi
  80119a:	50                   	push   %eax
  80119b:	68 98 18 80 00       	push   $0x801898
  8011a0:	e8 04 f0 ff ff       	call   8001a9 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8011a5:	83 c4 18             	add    $0x18,%esp
  8011a8:	53                   	push   %ebx
  8011a9:	ff 75 10             	pushl  0x10(%ebp)
  8011ac:	e8 a7 ef ff ff       	call   800158 <vcprintf>
	cprintf("\n");
  8011b1:	c7 04 24 2d 18 80 00 	movl   $0x80182d,(%esp)
  8011b8:	e8 ec ef ff ff       	call   8001a9 <cprintf>
  8011bd:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8011c0:	cc                   	int3   
  8011c1:	eb fd                	jmp    8011c0 <_panic+0x43>

008011c3 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8011c3:	55                   	push   %ebp
  8011c4:	89 e5                	mov    %esp,%ebp
  8011c6:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  8011c9:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  8011d0:	75 3c                	jne    80120e <set_pgfault_handler+0x4b>
		
		if ((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE),PTE_U|PTE_P|PTE_W)) < 0)
  8011d2:	83 ec 04             	sub    $0x4,%esp
  8011d5:	6a 07                	push   $0x7
  8011d7:	68 00 f0 bf ee       	push   $0xeebff000
  8011dc:	6a 00                	push   $0x0
  8011de:	e8 cd f9 ff ff       	call   800bb0 <sys_page_alloc>
  8011e3:	83 c4 10             	add    $0x10,%esp
  8011e6:	85 c0                	test   %eax,%eax
  8011e8:	79 12                	jns    8011fc <set_pgfault_handler+0x39>
		panic("sys_page_alloc: %e", r);
  8011ea:	50                   	push   %eax
  8011eb:	68 bc 18 80 00       	push   $0x8018bc
  8011f0:	6a 20                	push   $0x20
  8011f2:	68 cf 18 80 00       	push   $0x8018cf
  8011f7:	e8 81 ff ff ff       	call   80117d <_panic>
	    sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  8011fc:	83 ec 08             	sub    $0x8,%esp
  8011ff:	68 18 12 80 00       	push   $0x801218
  801204:	6a 00                	push   $0x0
  801206:	e8 ae fa ff ff       	call   800cb9 <sys_env_set_pgfault_upcall>
  80120b:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80120e:	8b 45 08             	mov    0x8(%ebp),%eax
  801211:	a3 08 20 80 00       	mov    %eax,0x802008
}
  801216:	c9                   	leave  
  801217:	c3                   	ret    

00801218 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801218:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801219:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80121e:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801220:	83 c4 04             	add    $0x4,%esp
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
    
    //trap time eip
	movl 0x28(%esp), %eax
  801223:	8b 44 24 28          	mov    0x28(%esp),%eax

	//current stack we need it afterwards to pop registers al
	movl %esp, %ebp
  801227:	89 e5                	mov    %esp,%ebp

	//switch to user stack where faulitng va occured
	movl 0x30(%esp), %esp
  801229:	8b 64 24 30          	mov    0x30(%esp),%esp

	// Push trap-time eip to the user stack 
	pushl %eax
  80122d:	50                   	push   %eax

	// SAve the user stack esp again for latter use after popping general purpose registers
	movl %esp, 0x30(%ebp)
  80122e:	89 65 30             	mov    %esp,0x30(%ebp)

	// Now again go to the user trap frame
	movl %ebp, %esp
  801231:	89 ec                	mov    %ebp,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	
	// ignore faut  va and err	
	addl $8, %esp
  801233:	83 c4 08             	add    $0x8,%esp

	// Pop all registers back
	popal
  801236:	61                   	popa   
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

	// Skip %eip
	addl $0x4, %esp
  801237:	83 c4 04             	add    $0x4,%esp

	// Pop eflags back
	popfl
  80123a:	9d                   	popf   

	// Go to user stack now
	// LAB 4: Your code here.

	popl %esp
  80123b:	5c                   	pop    %esp


	// LAB 4: Your code here.

	ret
  80123c:	c3                   	ret    
  80123d:	66 90                	xchg   %ax,%ax
  80123f:	90                   	nop

00801240 <__udivdi3>:
  801240:	55                   	push   %ebp
  801241:	57                   	push   %edi
  801242:	56                   	push   %esi
  801243:	53                   	push   %ebx
  801244:	83 ec 1c             	sub    $0x1c,%esp
  801247:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80124b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80124f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801253:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801257:	85 f6                	test   %esi,%esi
  801259:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80125d:	89 ca                	mov    %ecx,%edx
  80125f:	89 f8                	mov    %edi,%eax
  801261:	75 3d                	jne    8012a0 <__udivdi3+0x60>
  801263:	39 cf                	cmp    %ecx,%edi
  801265:	0f 87 c5 00 00 00    	ja     801330 <__udivdi3+0xf0>
  80126b:	85 ff                	test   %edi,%edi
  80126d:	89 fd                	mov    %edi,%ebp
  80126f:	75 0b                	jne    80127c <__udivdi3+0x3c>
  801271:	b8 01 00 00 00       	mov    $0x1,%eax
  801276:	31 d2                	xor    %edx,%edx
  801278:	f7 f7                	div    %edi
  80127a:	89 c5                	mov    %eax,%ebp
  80127c:	89 c8                	mov    %ecx,%eax
  80127e:	31 d2                	xor    %edx,%edx
  801280:	f7 f5                	div    %ebp
  801282:	89 c1                	mov    %eax,%ecx
  801284:	89 d8                	mov    %ebx,%eax
  801286:	89 cf                	mov    %ecx,%edi
  801288:	f7 f5                	div    %ebp
  80128a:	89 c3                	mov    %eax,%ebx
  80128c:	89 d8                	mov    %ebx,%eax
  80128e:	89 fa                	mov    %edi,%edx
  801290:	83 c4 1c             	add    $0x1c,%esp
  801293:	5b                   	pop    %ebx
  801294:	5e                   	pop    %esi
  801295:	5f                   	pop    %edi
  801296:	5d                   	pop    %ebp
  801297:	c3                   	ret    
  801298:	90                   	nop
  801299:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8012a0:	39 ce                	cmp    %ecx,%esi
  8012a2:	77 74                	ja     801318 <__udivdi3+0xd8>
  8012a4:	0f bd fe             	bsr    %esi,%edi
  8012a7:	83 f7 1f             	xor    $0x1f,%edi
  8012aa:	0f 84 98 00 00 00    	je     801348 <__udivdi3+0x108>
  8012b0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8012b5:	89 f9                	mov    %edi,%ecx
  8012b7:	89 c5                	mov    %eax,%ebp
  8012b9:	29 fb                	sub    %edi,%ebx
  8012bb:	d3 e6                	shl    %cl,%esi
  8012bd:	89 d9                	mov    %ebx,%ecx
  8012bf:	d3 ed                	shr    %cl,%ebp
  8012c1:	89 f9                	mov    %edi,%ecx
  8012c3:	d3 e0                	shl    %cl,%eax
  8012c5:	09 ee                	or     %ebp,%esi
  8012c7:	89 d9                	mov    %ebx,%ecx
  8012c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012cd:	89 d5                	mov    %edx,%ebp
  8012cf:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012d3:	d3 ed                	shr    %cl,%ebp
  8012d5:	89 f9                	mov    %edi,%ecx
  8012d7:	d3 e2                	shl    %cl,%edx
  8012d9:	89 d9                	mov    %ebx,%ecx
  8012db:	d3 e8                	shr    %cl,%eax
  8012dd:	09 c2                	or     %eax,%edx
  8012df:	89 d0                	mov    %edx,%eax
  8012e1:	89 ea                	mov    %ebp,%edx
  8012e3:	f7 f6                	div    %esi
  8012e5:	89 d5                	mov    %edx,%ebp
  8012e7:	89 c3                	mov    %eax,%ebx
  8012e9:	f7 64 24 0c          	mull   0xc(%esp)
  8012ed:	39 d5                	cmp    %edx,%ebp
  8012ef:	72 10                	jb     801301 <__udivdi3+0xc1>
  8012f1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8012f5:	89 f9                	mov    %edi,%ecx
  8012f7:	d3 e6                	shl    %cl,%esi
  8012f9:	39 c6                	cmp    %eax,%esi
  8012fb:	73 07                	jae    801304 <__udivdi3+0xc4>
  8012fd:	39 d5                	cmp    %edx,%ebp
  8012ff:	75 03                	jne    801304 <__udivdi3+0xc4>
  801301:	83 eb 01             	sub    $0x1,%ebx
  801304:	31 ff                	xor    %edi,%edi
  801306:	89 d8                	mov    %ebx,%eax
  801308:	89 fa                	mov    %edi,%edx
  80130a:	83 c4 1c             	add    $0x1c,%esp
  80130d:	5b                   	pop    %ebx
  80130e:	5e                   	pop    %esi
  80130f:	5f                   	pop    %edi
  801310:	5d                   	pop    %ebp
  801311:	c3                   	ret    
  801312:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801318:	31 ff                	xor    %edi,%edi
  80131a:	31 db                	xor    %ebx,%ebx
  80131c:	89 d8                	mov    %ebx,%eax
  80131e:	89 fa                	mov    %edi,%edx
  801320:	83 c4 1c             	add    $0x1c,%esp
  801323:	5b                   	pop    %ebx
  801324:	5e                   	pop    %esi
  801325:	5f                   	pop    %edi
  801326:	5d                   	pop    %ebp
  801327:	c3                   	ret    
  801328:	90                   	nop
  801329:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801330:	89 d8                	mov    %ebx,%eax
  801332:	f7 f7                	div    %edi
  801334:	31 ff                	xor    %edi,%edi
  801336:	89 c3                	mov    %eax,%ebx
  801338:	89 d8                	mov    %ebx,%eax
  80133a:	89 fa                	mov    %edi,%edx
  80133c:	83 c4 1c             	add    $0x1c,%esp
  80133f:	5b                   	pop    %ebx
  801340:	5e                   	pop    %esi
  801341:	5f                   	pop    %edi
  801342:	5d                   	pop    %ebp
  801343:	c3                   	ret    
  801344:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801348:	39 ce                	cmp    %ecx,%esi
  80134a:	72 0c                	jb     801358 <__udivdi3+0x118>
  80134c:	31 db                	xor    %ebx,%ebx
  80134e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801352:	0f 87 34 ff ff ff    	ja     80128c <__udivdi3+0x4c>
  801358:	bb 01 00 00 00       	mov    $0x1,%ebx
  80135d:	e9 2a ff ff ff       	jmp    80128c <__udivdi3+0x4c>
  801362:	66 90                	xchg   %ax,%ax
  801364:	66 90                	xchg   %ax,%ax
  801366:	66 90                	xchg   %ax,%ax
  801368:	66 90                	xchg   %ax,%ax
  80136a:	66 90                	xchg   %ax,%ax
  80136c:	66 90                	xchg   %ax,%ax
  80136e:	66 90                	xchg   %ax,%ax

00801370 <__umoddi3>:
  801370:	55                   	push   %ebp
  801371:	57                   	push   %edi
  801372:	56                   	push   %esi
  801373:	53                   	push   %ebx
  801374:	83 ec 1c             	sub    $0x1c,%esp
  801377:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80137b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80137f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801383:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801387:	85 d2                	test   %edx,%edx
  801389:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80138d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801391:	89 f3                	mov    %esi,%ebx
  801393:	89 3c 24             	mov    %edi,(%esp)
  801396:	89 74 24 04          	mov    %esi,0x4(%esp)
  80139a:	75 1c                	jne    8013b8 <__umoddi3+0x48>
  80139c:	39 f7                	cmp    %esi,%edi
  80139e:	76 50                	jbe    8013f0 <__umoddi3+0x80>
  8013a0:	89 c8                	mov    %ecx,%eax
  8013a2:	89 f2                	mov    %esi,%edx
  8013a4:	f7 f7                	div    %edi
  8013a6:	89 d0                	mov    %edx,%eax
  8013a8:	31 d2                	xor    %edx,%edx
  8013aa:	83 c4 1c             	add    $0x1c,%esp
  8013ad:	5b                   	pop    %ebx
  8013ae:	5e                   	pop    %esi
  8013af:	5f                   	pop    %edi
  8013b0:	5d                   	pop    %ebp
  8013b1:	c3                   	ret    
  8013b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013b8:	39 f2                	cmp    %esi,%edx
  8013ba:	89 d0                	mov    %edx,%eax
  8013bc:	77 52                	ja     801410 <__umoddi3+0xa0>
  8013be:	0f bd ea             	bsr    %edx,%ebp
  8013c1:	83 f5 1f             	xor    $0x1f,%ebp
  8013c4:	75 5a                	jne    801420 <__umoddi3+0xb0>
  8013c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8013ca:	0f 82 e0 00 00 00    	jb     8014b0 <__umoddi3+0x140>
  8013d0:	39 0c 24             	cmp    %ecx,(%esp)
  8013d3:	0f 86 d7 00 00 00    	jbe    8014b0 <__umoddi3+0x140>
  8013d9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8013dd:	8b 54 24 04          	mov    0x4(%esp),%edx
  8013e1:	83 c4 1c             	add    $0x1c,%esp
  8013e4:	5b                   	pop    %ebx
  8013e5:	5e                   	pop    %esi
  8013e6:	5f                   	pop    %edi
  8013e7:	5d                   	pop    %ebp
  8013e8:	c3                   	ret    
  8013e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013f0:	85 ff                	test   %edi,%edi
  8013f2:	89 fd                	mov    %edi,%ebp
  8013f4:	75 0b                	jne    801401 <__umoddi3+0x91>
  8013f6:	b8 01 00 00 00       	mov    $0x1,%eax
  8013fb:	31 d2                	xor    %edx,%edx
  8013fd:	f7 f7                	div    %edi
  8013ff:	89 c5                	mov    %eax,%ebp
  801401:	89 f0                	mov    %esi,%eax
  801403:	31 d2                	xor    %edx,%edx
  801405:	f7 f5                	div    %ebp
  801407:	89 c8                	mov    %ecx,%eax
  801409:	f7 f5                	div    %ebp
  80140b:	89 d0                	mov    %edx,%eax
  80140d:	eb 99                	jmp    8013a8 <__umoddi3+0x38>
  80140f:	90                   	nop
  801410:	89 c8                	mov    %ecx,%eax
  801412:	89 f2                	mov    %esi,%edx
  801414:	83 c4 1c             	add    $0x1c,%esp
  801417:	5b                   	pop    %ebx
  801418:	5e                   	pop    %esi
  801419:	5f                   	pop    %edi
  80141a:	5d                   	pop    %ebp
  80141b:	c3                   	ret    
  80141c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801420:	8b 34 24             	mov    (%esp),%esi
  801423:	bf 20 00 00 00       	mov    $0x20,%edi
  801428:	89 e9                	mov    %ebp,%ecx
  80142a:	29 ef                	sub    %ebp,%edi
  80142c:	d3 e0                	shl    %cl,%eax
  80142e:	89 f9                	mov    %edi,%ecx
  801430:	89 f2                	mov    %esi,%edx
  801432:	d3 ea                	shr    %cl,%edx
  801434:	89 e9                	mov    %ebp,%ecx
  801436:	09 c2                	or     %eax,%edx
  801438:	89 d8                	mov    %ebx,%eax
  80143a:	89 14 24             	mov    %edx,(%esp)
  80143d:	89 f2                	mov    %esi,%edx
  80143f:	d3 e2                	shl    %cl,%edx
  801441:	89 f9                	mov    %edi,%ecx
  801443:	89 54 24 04          	mov    %edx,0x4(%esp)
  801447:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80144b:	d3 e8                	shr    %cl,%eax
  80144d:	89 e9                	mov    %ebp,%ecx
  80144f:	89 c6                	mov    %eax,%esi
  801451:	d3 e3                	shl    %cl,%ebx
  801453:	89 f9                	mov    %edi,%ecx
  801455:	89 d0                	mov    %edx,%eax
  801457:	d3 e8                	shr    %cl,%eax
  801459:	89 e9                	mov    %ebp,%ecx
  80145b:	09 d8                	or     %ebx,%eax
  80145d:	89 d3                	mov    %edx,%ebx
  80145f:	89 f2                	mov    %esi,%edx
  801461:	f7 34 24             	divl   (%esp)
  801464:	89 d6                	mov    %edx,%esi
  801466:	d3 e3                	shl    %cl,%ebx
  801468:	f7 64 24 04          	mull   0x4(%esp)
  80146c:	39 d6                	cmp    %edx,%esi
  80146e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801472:	89 d1                	mov    %edx,%ecx
  801474:	89 c3                	mov    %eax,%ebx
  801476:	72 08                	jb     801480 <__umoddi3+0x110>
  801478:	75 11                	jne    80148b <__umoddi3+0x11b>
  80147a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80147e:	73 0b                	jae    80148b <__umoddi3+0x11b>
  801480:	2b 44 24 04          	sub    0x4(%esp),%eax
  801484:	1b 14 24             	sbb    (%esp),%edx
  801487:	89 d1                	mov    %edx,%ecx
  801489:	89 c3                	mov    %eax,%ebx
  80148b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80148f:	29 da                	sub    %ebx,%edx
  801491:	19 ce                	sbb    %ecx,%esi
  801493:	89 f9                	mov    %edi,%ecx
  801495:	89 f0                	mov    %esi,%eax
  801497:	d3 e0                	shl    %cl,%eax
  801499:	89 e9                	mov    %ebp,%ecx
  80149b:	d3 ea                	shr    %cl,%edx
  80149d:	89 e9                	mov    %ebp,%ecx
  80149f:	d3 ee                	shr    %cl,%esi
  8014a1:	09 d0                	or     %edx,%eax
  8014a3:	89 f2                	mov    %esi,%edx
  8014a5:	83 c4 1c             	add    $0x1c,%esp
  8014a8:	5b                   	pop    %ebx
  8014a9:	5e                   	pop    %esi
  8014aa:	5f                   	pop    %edi
  8014ab:	5d                   	pop    %ebp
  8014ac:	c3                   	ret    
  8014ad:	8d 76 00             	lea    0x0(%esi),%esi
  8014b0:	29 f9                	sub    %edi,%ecx
  8014b2:	19 d6                	sbb    %edx,%esi
  8014b4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014bc:	e9 18 ff ff ff       	jmp    8013d9 <__umoddi3+0x69>
