
obj/user/primes:     file format elf32-i386


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
  80002c:	e8 c7 00 00 00       	call   8000f8 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <primeproc>:

#include <inc/lib.h>

unsigned
primeproc(void)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 1c             	sub    $0x1c,%esp
	int i, id, p;
	envid_t envid;

	// fetch a prime from our left neighbor
top:
	p = ipc_recv(&envid, 0, 0);
  80003c:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  80003f:	83 ec 04             	sub    $0x4,%esp
  800042:	6a 00                	push   $0x0
  800044:	6a 00                	push   $0x0
  800046:	56                   	push   %esi
  800047:	e8 a9 10 00 00       	call   8010f5 <ipc_recv>
  80004c:	89 c3                	mov    %eax,%ebx
	cprintf("CPU %d: %d ", thisenv->env_cpunum, p);
  80004e:	a1 04 20 80 00       	mov    0x802004,%eax
  800053:	8b 40 5c             	mov    0x5c(%eax),%eax
  800056:	83 c4 0c             	add    $0xc,%esp
  800059:	53                   	push   %ebx
  80005a:	50                   	push   %eax
  80005b:	68 20 15 80 00       	push   $0x801520
  800060:	e8 c4 01 00 00       	call   800229 <cprintf>

	// fork a right neighbor to continue the chain
	if ((id = fork()) < 0)
  800065:	e8 35 0e 00 00       	call   800e9f <fork>
  80006a:	89 c7                	mov    %eax,%edi
  80006c:	83 c4 10             	add    $0x10,%esp
  80006f:	85 c0                	test   %eax,%eax
  800071:	79 12                	jns    800085 <primeproc+0x52>
		panic("fork: %e", id);
  800073:	50                   	push   %eax
  800074:	68 2c 15 80 00       	push   $0x80152c
  800079:	6a 1a                	push   $0x1a
  80007b:	68 35 15 80 00       	push   $0x801535
  800080:	e8 cb 00 00 00       	call   800150 <_panic>
	if (id == 0)
  800085:	85 c0                	test   %eax,%eax
  800087:	74 b6                	je     80003f <primeproc+0xc>
		goto top;

	// filter out multiples of our prime
	while (1) {
		i = ipc_recv(&envid, 0, 0);
  800089:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  80008c:	83 ec 04             	sub    $0x4,%esp
  80008f:	6a 00                	push   $0x0
  800091:	6a 00                	push   $0x0
  800093:	56                   	push   %esi
  800094:	e8 5c 10 00 00       	call   8010f5 <ipc_recv>
  800099:	89 c1                	mov    %eax,%ecx
		if (i % p)
  80009b:	99                   	cltd   
  80009c:	f7 fb                	idiv   %ebx
  80009e:	83 c4 10             	add    $0x10,%esp
  8000a1:	85 d2                	test   %edx,%edx
  8000a3:	74 e7                	je     80008c <primeproc+0x59>
			ipc_send(id, i, 0, 0);
  8000a5:	6a 00                	push   $0x0
  8000a7:	6a 00                	push   $0x0
  8000a9:	51                   	push   %ecx
  8000aa:	57                   	push   %edi
  8000ab:	e8 ae 10 00 00       	call   80115e <ipc_send>
  8000b0:	83 c4 10             	add    $0x10,%esp
  8000b3:	eb d7                	jmp    80008c <primeproc+0x59>

008000b5 <umain>:
	}
}

void
umain(int argc, char **argv)
{
  8000b5:	55                   	push   %ebp
  8000b6:	89 e5                	mov    %esp,%ebp
  8000b8:	56                   	push   %esi
  8000b9:	53                   	push   %ebx
	int i, id;

	// fork the first prime process in the chain
	if ((id = fork()) < 0)
  8000ba:	e8 e0 0d 00 00       	call   800e9f <fork>
  8000bf:	89 c6                	mov    %eax,%esi
  8000c1:	85 c0                	test   %eax,%eax
  8000c3:	79 12                	jns    8000d7 <umain+0x22>
		panic("fork: %e", id);
  8000c5:	50                   	push   %eax
  8000c6:	68 2c 15 80 00       	push   $0x80152c
  8000cb:	6a 2d                	push   $0x2d
  8000cd:	68 35 15 80 00       	push   $0x801535
  8000d2:	e8 79 00 00 00       	call   800150 <_panic>
  8000d7:	bb 02 00 00 00       	mov    $0x2,%ebx
	if (id == 0)
  8000dc:	85 c0                	test   %eax,%eax
  8000de:	75 05                	jne    8000e5 <umain+0x30>
		primeproc();
  8000e0:	e8 4e ff ff ff       	call   800033 <primeproc>

	// feed all the integers through
	for (i = 2; ; i++)
		ipc_send(id, i, 0, 0);
  8000e5:	6a 00                	push   $0x0
  8000e7:	6a 00                	push   $0x0
  8000e9:	53                   	push   %ebx
  8000ea:	56                   	push   %esi
  8000eb:	e8 6e 10 00 00       	call   80115e <ipc_send>
		panic("fork: %e", id);
	if (id == 0)
		primeproc();

	// feed all the integers through
	for (i = 2; ; i++)
  8000f0:	83 c3 01             	add    $0x1,%ebx
  8000f3:	83 c4 10             	add    $0x10,%esp
  8000f6:	eb ed                	jmp    8000e5 <umain+0x30>

008000f8 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000f8:	55                   	push   %ebp
  8000f9:	89 e5                	mov    %esp,%ebp
  8000fb:	56                   	push   %esi
  8000fc:	53                   	push   %ebx
  8000fd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800100:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  800103:	e8 ea 0a 00 00       	call   800bf2 <sys_getenvid>
  800108:	25 ff 03 00 00       	and    $0x3ff,%eax
  80010d:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800110:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800115:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80011a:	85 db                	test   %ebx,%ebx
  80011c:	7e 07                	jle    800125 <libmain+0x2d>
		binaryname = argv[0];
  80011e:	8b 06                	mov    (%esi),%eax
  800120:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800125:	83 ec 08             	sub    $0x8,%esp
  800128:	56                   	push   %esi
  800129:	53                   	push   %ebx
  80012a:	e8 86 ff ff ff       	call   8000b5 <umain>

	// exit gracefully
	exit();
  80012f:	e8 0a 00 00 00       	call   80013e <exit>
}
  800134:	83 c4 10             	add    $0x10,%esp
  800137:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80013a:	5b                   	pop    %ebx
  80013b:	5e                   	pop    %esi
  80013c:	5d                   	pop    %ebp
  80013d:	c3                   	ret    

0080013e <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80013e:	55                   	push   %ebp
  80013f:	89 e5                	mov    %esp,%ebp
  800141:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800144:	6a 00                	push   $0x0
  800146:	e8 66 0a 00 00       	call   800bb1 <sys_env_destroy>
}
  80014b:	83 c4 10             	add    $0x10,%esp
  80014e:	c9                   	leave  
  80014f:	c3                   	ret    

00800150 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	56                   	push   %esi
  800154:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800155:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800158:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80015e:	e8 8f 0a 00 00       	call   800bf2 <sys_getenvid>
  800163:	83 ec 0c             	sub    $0xc,%esp
  800166:	ff 75 0c             	pushl  0xc(%ebp)
  800169:	ff 75 08             	pushl  0x8(%ebp)
  80016c:	56                   	push   %esi
  80016d:	50                   	push   %eax
  80016e:	68 50 15 80 00       	push   $0x801550
  800173:	e8 b1 00 00 00       	call   800229 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800178:	83 c4 18             	add    $0x18,%esp
  80017b:	53                   	push   %ebx
  80017c:	ff 75 10             	pushl  0x10(%ebp)
  80017f:	e8 54 00 00 00       	call   8001d8 <vcprintf>
	cprintf("\n");
  800184:	c7 04 24 8d 18 80 00 	movl   $0x80188d,(%esp)
  80018b:	e8 99 00 00 00       	call   800229 <cprintf>
  800190:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800193:	cc                   	int3   
  800194:	eb fd                	jmp    800193 <_panic+0x43>

00800196 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800196:	55                   	push   %ebp
  800197:	89 e5                	mov    %esp,%ebp
  800199:	53                   	push   %ebx
  80019a:	83 ec 04             	sub    $0x4,%esp
  80019d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001a0:	8b 13                	mov    (%ebx),%edx
  8001a2:	8d 42 01             	lea    0x1(%edx),%eax
  8001a5:	89 03                	mov    %eax,(%ebx)
  8001a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001aa:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001ae:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001b3:	75 1a                	jne    8001cf <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001b5:	83 ec 08             	sub    $0x8,%esp
  8001b8:	68 ff 00 00 00       	push   $0xff
  8001bd:	8d 43 08             	lea    0x8(%ebx),%eax
  8001c0:	50                   	push   %eax
  8001c1:	e8 ae 09 00 00       	call   800b74 <sys_cputs>
		b->idx = 0;
  8001c6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001cc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001cf:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001d6:	c9                   	leave  
  8001d7:	c3                   	ret    

008001d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001d8:	55                   	push   %ebp
  8001d9:	89 e5                	mov    %esp,%ebp
  8001db:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001e1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001e8:	00 00 00 
	b.cnt = 0;
  8001eb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001f2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001f5:	ff 75 0c             	pushl  0xc(%ebp)
  8001f8:	ff 75 08             	pushl  0x8(%ebp)
  8001fb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800201:	50                   	push   %eax
  800202:	68 96 01 80 00       	push   $0x800196
  800207:	e8 1a 01 00 00       	call   800326 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80020c:	83 c4 08             	add    $0x8,%esp
  80020f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800215:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80021b:	50                   	push   %eax
  80021c:	e8 53 09 00 00       	call   800b74 <sys_cputs>

	return b.cnt;
}
  800221:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800227:	c9                   	leave  
  800228:	c3                   	ret    

00800229 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800229:	55                   	push   %ebp
  80022a:	89 e5                	mov    %esp,%ebp
  80022c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80022f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800232:	50                   	push   %eax
  800233:	ff 75 08             	pushl  0x8(%ebp)
  800236:	e8 9d ff ff ff       	call   8001d8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80023b:	c9                   	leave  
  80023c:	c3                   	ret    

0080023d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80023d:	55                   	push   %ebp
  80023e:	89 e5                	mov    %esp,%ebp
  800240:	57                   	push   %edi
  800241:	56                   	push   %esi
  800242:	53                   	push   %ebx
  800243:	83 ec 1c             	sub    $0x1c,%esp
  800246:	89 c7                	mov    %eax,%edi
  800248:	89 d6                	mov    %edx,%esi
  80024a:	8b 45 08             	mov    0x8(%ebp),%eax
  80024d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800250:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800253:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800256:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800259:	bb 00 00 00 00       	mov    $0x0,%ebx
  80025e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800261:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800264:	39 d3                	cmp    %edx,%ebx
  800266:	72 05                	jb     80026d <printnum+0x30>
  800268:	39 45 10             	cmp    %eax,0x10(%ebp)
  80026b:	77 45                	ja     8002b2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80026d:	83 ec 0c             	sub    $0xc,%esp
  800270:	ff 75 18             	pushl  0x18(%ebp)
  800273:	8b 45 14             	mov    0x14(%ebp),%eax
  800276:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800279:	53                   	push   %ebx
  80027a:	ff 75 10             	pushl  0x10(%ebp)
  80027d:	83 ec 08             	sub    $0x8,%esp
  800280:	ff 75 e4             	pushl  -0x1c(%ebp)
  800283:	ff 75 e0             	pushl  -0x20(%ebp)
  800286:	ff 75 dc             	pushl  -0x24(%ebp)
  800289:	ff 75 d8             	pushl  -0x28(%ebp)
  80028c:	e8 ef 0f 00 00       	call   801280 <__udivdi3>
  800291:	83 c4 18             	add    $0x18,%esp
  800294:	52                   	push   %edx
  800295:	50                   	push   %eax
  800296:	89 f2                	mov    %esi,%edx
  800298:	89 f8                	mov    %edi,%eax
  80029a:	e8 9e ff ff ff       	call   80023d <printnum>
  80029f:	83 c4 20             	add    $0x20,%esp
  8002a2:	eb 18                	jmp    8002bc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002a4:	83 ec 08             	sub    $0x8,%esp
  8002a7:	56                   	push   %esi
  8002a8:	ff 75 18             	pushl  0x18(%ebp)
  8002ab:	ff d7                	call   *%edi
  8002ad:	83 c4 10             	add    $0x10,%esp
  8002b0:	eb 03                	jmp    8002b5 <printnum+0x78>
  8002b2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002b5:	83 eb 01             	sub    $0x1,%ebx
  8002b8:	85 db                	test   %ebx,%ebx
  8002ba:	7f e8                	jg     8002a4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002bc:	83 ec 08             	sub    $0x8,%esp
  8002bf:	56                   	push   %esi
  8002c0:	83 ec 04             	sub    $0x4,%esp
  8002c3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002c6:	ff 75 e0             	pushl  -0x20(%ebp)
  8002c9:	ff 75 dc             	pushl  -0x24(%ebp)
  8002cc:	ff 75 d8             	pushl  -0x28(%ebp)
  8002cf:	e8 dc 10 00 00       	call   8013b0 <__umoddi3>
  8002d4:	83 c4 14             	add    $0x14,%esp
  8002d7:	0f be 80 73 15 80 00 	movsbl 0x801573(%eax),%eax
  8002de:	50                   	push   %eax
  8002df:	ff d7                	call   *%edi
}
  8002e1:	83 c4 10             	add    $0x10,%esp
  8002e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002e7:	5b                   	pop    %ebx
  8002e8:	5e                   	pop    %esi
  8002e9:	5f                   	pop    %edi
  8002ea:	5d                   	pop    %ebp
  8002eb:	c3                   	ret    

008002ec <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002ec:	55                   	push   %ebp
  8002ed:	89 e5                	mov    %esp,%ebp
  8002ef:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002f2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002f6:	8b 10                	mov    (%eax),%edx
  8002f8:	3b 50 04             	cmp    0x4(%eax),%edx
  8002fb:	73 0a                	jae    800307 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002fd:	8d 4a 01             	lea    0x1(%edx),%ecx
  800300:	89 08                	mov    %ecx,(%eax)
  800302:	8b 45 08             	mov    0x8(%ebp),%eax
  800305:	88 02                	mov    %al,(%edx)
}
  800307:	5d                   	pop    %ebp
  800308:	c3                   	ret    

00800309 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800309:	55                   	push   %ebp
  80030a:	89 e5                	mov    %esp,%ebp
  80030c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80030f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800312:	50                   	push   %eax
  800313:	ff 75 10             	pushl  0x10(%ebp)
  800316:	ff 75 0c             	pushl  0xc(%ebp)
  800319:	ff 75 08             	pushl  0x8(%ebp)
  80031c:	e8 05 00 00 00       	call   800326 <vprintfmt>
	va_end(ap);
}
  800321:	83 c4 10             	add    $0x10,%esp
  800324:	c9                   	leave  
  800325:	c3                   	ret    

00800326 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800326:	55                   	push   %ebp
  800327:	89 e5                	mov    %esp,%ebp
  800329:	57                   	push   %edi
  80032a:	56                   	push   %esi
  80032b:	53                   	push   %ebx
  80032c:	83 ec 2c             	sub    $0x2c,%esp
  80032f:	8b 75 08             	mov    0x8(%ebp),%esi
  800332:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800335:	8b 7d 10             	mov    0x10(%ebp),%edi
  800338:	eb 12                	jmp    80034c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80033a:	85 c0                	test   %eax,%eax
  80033c:	0f 84 42 04 00 00    	je     800784 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800342:	83 ec 08             	sub    $0x8,%esp
  800345:	53                   	push   %ebx
  800346:	50                   	push   %eax
  800347:	ff d6                	call   *%esi
  800349:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80034c:	83 c7 01             	add    $0x1,%edi
  80034f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800353:	83 f8 25             	cmp    $0x25,%eax
  800356:	75 e2                	jne    80033a <vprintfmt+0x14>
  800358:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80035c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800363:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80036a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800371:	b9 00 00 00 00       	mov    $0x0,%ecx
  800376:	eb 07                	jmp    80037f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800378:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80037b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80037f:	8d 47 01             	lea    0x1(%edi),%eax
  800382:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800385:	0f b6 07             	movzbl (%edi),%eax
  800388:	0f b6 d0             	movzbl %al,%edx
  80038b:	83 e8 23             	sub    $0x23,%eax
  80038e:	3c 55                	cmp    $0x55,%al
  800390:	0f 87 d3 03 00 00    	ja     800769 <vprintfmt+0x443>
  800396:	0f b6 c0             	movzbl %al,%eax
  800399:	ff 24 85 40 16 80 00 	jmp    *0x801640(,%eax,4)
  8003a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003a3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003a7:	eb d6                	jmp    80037f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8003b1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003b7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003bb:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003be:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003c1:	83 f9 09             	cmp    $0x9,%ecx
  8003c4:	77 3f                	ja     800405 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003c6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003c9:	eb e9                	jmp    8003b4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ce:	8b 00                	mov    (%eax),%eax
  8003d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d6:	8d 40 04             	lea    0x4(%eax),%eax
  8003d9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003df:	eb 2a                	jmp    80040b <vprintfmt+0xe5>
  8003e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003e4:	85 c0                	test   %eax,%eax
  8003e6:	ba 00 00 00 00       	mov    $0x0,%edx
  8003eb:	0f 49 d0             	cmovns %eax,%edx
  8003ee:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003f4:	eb 89                	jmp    80037f <vprintfmt+0x59>
  8003f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003f9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800400:	e9 7a ff ff ff       	jmp    80037f <vprintfmt+0x59>
  800405:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800408:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80040b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80040f:	0f 89 6a ff ff ff    	jns    80037f <vprintfmt+0x59>
				width = precision, precision = -1;
  800415:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800418:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80041b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800422:	e9 58 ff ff ff       	jmp    80037f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800427:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80042d:	e9 4d ff ff ff       	jmp    80037f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800432:	8b 45 14             	mov    0x14(%ebp),%eax
  800435:	8d 78 04             	lea    0x4(%eax),%edi
  800438:	83 ec 08             	sub    $0x8,%esp
  80043b:	53                   	push   %ebx
  80043c:	ff 30                	pushl  (%eax)
  80043e:	ff d6                	call   *%esi
			break;
  800440:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800443:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800446:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800449:	e9 fe fe ff ff       	jmp    80034c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80044e:	8b 45 14             	mov    0x14(%ebp),%eax
  800451:	8d 78 04             	lea    0x4(%eax),%edi
  800454:	8b 00                	mov    (%eax),%eax
  800456:	99                   	cltd   
  800457:	31 d0                	xor    %edx,%eax
  800459:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80045b:	83 f8 08             	cmp    $0x8,%eax
  80045e:	7f 0b                	jg     80046b <vprintfmt+0x145>
  800460:	8b 14 85 a0 17 80 00 	mov    0x8017a0(,%eax,4),%edx
  800467:	85 d2                	test   %edx,%edx
  800469:	75 1b                	jne    800486 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80046b:	50                   	push   %eax
  80046c:	68 8b 15 80 00       	push   $0x80158b
  800471:	53                   	push   %ebx
  800472:	56                   	push   %esi
  800473:	e8 91 fe ff ff       	call   800309 <printfmt>
  800478:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80047b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800481:	e9 c6 fe ff ff       	jmp    80034c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800486:	52                   	push   %edx
  800487:	68 94 15 80 00       	push   $0x801594
  80048c:	53                   	push   %ebx
  80048d:	56                   	push   %esi
  80048e:	e8 76 fe ff ff       	call   800309 <printfmt>
  800493:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800496:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800499:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80049c:	e9 ab fe ff ff       	jmp    80034c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a4:	83 c0 04             	add    $0x4,%eax
  8004a7:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ad:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004af:	85 ff                	test   %edi,%edi
  8004b1:	b8 84 15 80 00       	mov    $0x801584,%eax
  8004b6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004b9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004bd:	0f 8e 94 00 00 00    	jle    800557 <vprintfmt+0x231>
  8004c3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004c7:	0f 84 98 00 00 00    	je     800565 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cd:	83 ec 08             	sub    $0x8,%esp
  8004d0:	ff 75 d0             	pushl  -0x30(%ebp)
  8004d3:	57                   	push   %edi
  8004d4:	e8 33 03 00 00       	call   80080c <strnlen>
  8004d9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004dc:	29 c1                	sub    %eax,%ecx
  8004de:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004e1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004e4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004e8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004eb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ee:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f0:	eb 0f                	jmp    800501 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004f2:	83 ec 08             	sub    $0x8,%esp
  8004f5:	53                   	push   %ebx
  8004f6:	ff 75 e0             	pushl  -0x20(%ebp)
  8004f9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004fb:	83 ef 01             	sub    $0x1,%edi
  8004fe:	83 c4 10             	add    $0x10,%esp
  800501:	85 ff                	test   %edi,%edi
  800503:	7f ed                	jg     8004f2 <vprintfmt+0x1cc>
  800505:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800508:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80050b:	85 c9                	test   %ecx,%ecx
  80050d:	b8 00 00 00 00       	mov    $0x0,%eax
  800512:	0f 49 c1             	cmovns %ecx,%eax
  800515:	29 c1                	sub    %eax,%ecx
  800517:	89 75 08             	mov    %esi,0x8(%ebp)
  80051a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80051d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800520:	89 cb                	mov    %ecx,%ebx
  800522:	eb 4d                	jmp    800571 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800524:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800528:	74 1b                	je     800545 <vprintfmt+0x21f>
  80052a:	0f be c0             	movsbl %al,%eax
  80052d:	83 e8 20             	sub    $0x20,%eax
  800530:	83 f8 5e             	cmp    $0x5e,%eax
  800533:	76 10                	jbe    800545 <vprintfmt+0x21f>
					putch('?', putdat);
  800535:	83 ec 08             	sub    $0x8,%esp
  800538:	ff 75 0c             	pushl  0xc(%ebp)
  80053b:	6a 3f                	push   $0x3f
  80053d:	ff 55 08             	call   *0x8(%ebp)
  800540:	83 c4 10             	add    $0x10,%esp
  800543:	eb 0d                	jmp    800552 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800545:	83 ec 08             	sub    $0x8,%esp
  800548:	ff 75 0c             	pushl  0xc(%ebp)
  80054b:	52                   	push   %edx
  80054c:	ff 55 08             	call   *0x8(%ebp)
  80054f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800552:	83 eb 01             	sub    $0x1,%ebx
  800555:	eb 1a                	jmp    800571 <vprintfmt+0x24b>
  800557:	89 75 08             	mov    %esi,0x8(%ebp)
  80055a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80055d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800560:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800563:	eb 0c                	jmp    800571 <vprintfmt+0x24b>
  800565:	89 75 08             	mov    %esi,0x8(%ebp)
  800568:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800571:	83 c7 01             	add    $0x1,%edi
  800574:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800578:	0f be d0             	movsbl %al,%edx
  80057b:	85 d2                	test   %edx,%edx
  80057d:	74 23                	je     8005a2 <vprintfmt+0x27c>
  80057f:	85 f6                	test   %esi,%esi
  800581:	78 a1                	js     800524 <vprintfmt+0x1fe>
  800583:	83 ee 01             	sub    $0x1,%esi
  800586:	79 9c                	jns    800524 <vprintfmt+0x1fe>
  800588:	89 df                	mov    %ebx,%edi
  80058a:	8b 75 08             	mov    0x8(%ebp),%esi
  80058d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800590:	eb 18                	jmp    8005aa <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800592:	83 ec 08             	sub    $0x8,%esp
  800595:	53                   	push   %ebx
  800596:	6a 20                	push   $0x20
  800598:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80059a:	83 ef 01             	sub    $0x1,%edi
  80059d:	83 c4 10             	add    $0x10,%esp
  8005a0:	eb 08                	jmp    8005aa <vprintfmt+0x284>
  8005a2:	89 df                	mov    %ebx,%edi
  8005a4:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005aa:	85 ff                	test   %edi,%edi
  8005ac:	7f e4                	jg     800592 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005b1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005b4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b7:	e9 90 fd ff ff       	jmp    80034c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005bc:	83 f9 01             	cmp    $0x1,%ecx
  8005bf:	7e 19                	jle    8005da <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c4:	8b 50 04             	mov    0x4(%eax),%edx
  8005c7:	8b 00                	mov    (%eax),%eax
  8005c9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005cc:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d2:	8d 40 08             	lea    0x8(%eax),%eax
  8005d5:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d8:	eb 38                	jmp    800612 <vprintfmt+0x2ec>
	else if (lflag)
  8005da:	85 c9                	test   %ecx,%ecx
  8005dc:	74 1b                	je     8005f9 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005de:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e1:	8b 00                	mov    (%eax),%eax
  8005e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e6:	89 c1                	mov    %eax,%ecx
  8005e8:	c1 f9 1f             	sar    $0x1f,%ecx
  8005eb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f1:	8d 40 04             	lea    0x4(%eax),%eax
  8005f4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005f7:	eb 19                	jmp    800612 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fc:	8b 00                	mov    (%eax),%eax
  8005fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800601:	89 c1                	mov    %eax,%ecx
  800603:	c1 f9 1f             	sar    $0x1f,%ecx
  800606:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800609:	8b 45 14             	mov    0x14(%ebp),%eax
  80060c:	8d 40 04             	lea    0x4(%eax),%eax
  80060f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800612:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800615:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800618:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80061d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800621:	0f 89 0e 01 00 00    	jns    800735 <vprintfmt+0x40f>
				putch('-', putdat);
  800627:	83 ec 08             	sub    $0x8,%esp
  80062a:	53                   	push   %ebx
  80062b:	6a 2d                	push   $0x2d
  80062d:	ff d6                	call   *%esi
				num = -(long long) num;
  80062f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800632:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800635:	f7 da                	neg    %edx
  800637:	83 d1 00             	adc    $0x0,%ecx
  80063a:	f7 d9                	neg    %ecx
  80063c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80063f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800644:	e9 ec 00 00 00       	jmp    800735 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800649:	83 f9 01             	cmp    $0x1,%ecx
  80064c:	7e 18                	jle    800666 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80064e:	8b 45 14             	mov    0x14(%ebp),%eax
  800651:	8b 10                	mov    (%eax),%edx
  800653:	8b 48 04             	mov    0x4(%eax),%ecx
  800656:	8d 40 08             	lea    0x8(%eax),%eax
  800659:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80065c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800661:	e9 cf 00 00 00       	jmp    800735 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800666:	85 c9                	test   %ecx,%ecx
  800668:	74 1a                	je     800684 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80066a:	8b 45 14             	mov    0x14(%ebp),%eax
  80066d:	8b 10                	mov    (%eax),%edx
  80066f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800674:	8d 40 04             	lea    0x4(%eax),%eax
  800677:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80067a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80067f:	e9 b1 00 00 00       	jmp    800735 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800684:	8b 45 14             	mov    0x14(%ebp),%eax
  800687:	8b 10                	mov    (%eax),%edx
  800689:	b9 00 00 00 00       	mov    $0x0,%ecx
  80068e:	8d 40 04             	lea    0x4(%eax),%eax
  800691:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800694:	b8 0a 00 00 00       	mov    $0xa,%eax
  800699:	e9 97 00 00 00       	jmp    800735 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80069e:	83 ec 08             	sub    $0x8,%esp
  8006a1:	53                   	push   %ebx
  8006a2:	6a 58                	push   $0x58
  8006a4:	ff d6                	call   *%esi
			putch('X', putdat);
  8006a6:	83 c4 08             	add    $0x8,%esp
  8006a9:	53                   	push   %ebx
  8006aa:	6a 58                	push   $0x58
  8006ac:	ff d6                	call   *%esi
			putch('X', putdat);
  8006ae:	83 c4 08             	add    $0x8,%esp
  8006b1:	53                   	push   %ebx
  8006b2:	6a 58                	push   $0x58
  8006b4:	ff d6                	call   *%esi
			break;
  8006b6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006bc:	e9 8b fc ff ff       	jmp    80034c <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006c1:	83 ec 08             	sub    $0x8,%esp
  8006c4:	53                   	push   %ebx
  8006c5:	6a 30                	push   $0x30
  8006c7:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c9:	83 c4 08             	add    $0x8,%esp
  8006cc:	53                   	push   %ebx
  8006cd:	6a 78                	push   $0x78
  8006cf:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d4:	8b 10                	mov    (%eax),%edx
  8006d6:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006db:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006de:	8d 40 04             	lea    0x4(%eax),%eax
  8006e1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006e4:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e9:	eb 4a                	jmp    800735 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006eb:	83 f9 01             	cmp    $0x1,%ecx
  8006ee:	7e 15                	jle    800705 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f3:	8b 10                	mov    (%eax),%edx
  8006f5:	8b 48 04             	mov    0x4(%eax),%ecx
  8006f8:	8d 40 08             	lea    0x8(%eax),%eax
  8006fb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006fe:	b8 10 00 00 00       	mov    $0x10,%eax
  800703:	eb 30                	jmp    800735 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800705:	85 c9                	test   %ecx,%ecx
  800707:	74 17                	je     800720 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800709:	8b 45 14             	mov    0x14(%ebp),%eax
  80070c:	8b 10                	mov    (%eax),%edx
  80070e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800713:	8d 40 04             	lea    0x4(%eax),%eax
  800716:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800719:	b8 10 00 00 00       	mov    $0x10,%eax
  80071e:	eb 15                	jmp    800735 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800720:	8b 45 14             	mov    0x14(%ebp),%eax
  800723:	8b 10                	mov    (%eax),%edx
  800725:	b9 00 00 00 00       	mov    $0x0,%ecx
  80072a:	8d 40 04             	lea    0x4(%eax),%eax
  80072d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800730:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800735:	83 ec 0c             	sub    $0xc,%esp
  800738:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80073c:	57                   	push   %edi
  80073d:	ff 75 e0             	pushl  -0x20(%ebp)
  800740:	50                   	push   %eax
  800741:	51                   	push   %ecx
  800742:	52                   	push   %edx
  800743:	89 da                	mov    %ebx,%edx
  800745:	89 f0                	mov    %esi,%eax
  800747:	e8 f1 fa ff ff       	call   80023d <printnum>
			break;
  80074c:	83 c4 20             	add    $0x20,%esp
  80074f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800752:	e9 f5 fb ff ff       	jmp    80034c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800757:	83 ec 08             	sub    $0x8,%esp
  80075a:	53                   	push   %ebx
  80075b:	52                   	push   %edx
  80075c:	ff d6                	call   *%esi
			break;
  80075e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800761:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800764:	e9 e3 fb ff ff       	jmp    80034c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800769:	83 ec 08             	sub    $0x8,%esp
  80076c:	53                   	push   %ebx
  80076d:	6a 25                	push   $0x25
  80076f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800771:	83 c4 10             	add    $0x10,%esp
  800774:	eb 03                	jmp    800779 <vprintfmt+0x453>
  800776:	83 ef 01             	sub    $0x1,%edi
  800779:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80077d:	75 f7                	jne    800776 <vprintfmt+0x450>
  80077f:	e9 c8 fb ff ff       	jmp    80034c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800784:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800787:	5b                   	pop    %ebx
  800788:	5e                   	pop    %esi
  800789:	5f                   	pop    %edi
  80078a:	5d                   	pop    %ebp
  80078b:	c3                   	ret    

0080078c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80078c:	55                   	push   %ebp
  80078d:	89 e5                	mov    %esp,%ebp
  80078f:	83 ec 18             	sub    $0x18,%esp
  800792:	8b 45 08             	mov    0x8(%ebp),%eax
  800795:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800798:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80079b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80079f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007a2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a9:	85 c0                	test   %eax,%eax
  8007ab:	74 26                	je     8007d3 <vsnprintf+0x47>
  8007ad:	85 d2                	test   %edx,%edx
  8007af:	7e 22                	jle    8007d3 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007b1:	ff 75 14             	pushl  0x14(%ebp)
  8007b4:	ff 75 10             	pushl  0x10(%ebp)
  8007b7:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007ba:	50                   	push   %eax
  8007bb:	68 ec 02 80 00       	push   $0x8002ec
  8007c0:	e8 61 fb ff ff       	call   800326 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007c8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007ce:	83 c4 10             	add    $0x10,%esp
  8007d1:	eb 05                	jmp    8007d8 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007d3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d8:	c9                   	leave  
  8007d9:	c3                   	ret    

008007da <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007da:	55                   	push   %ebp
  8007db:	89 e5                	mov    %esp,%ebp
  8007dd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007e0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007e3:	50                   	push   %eax
  8007e4:	ff 75 10             	pushl  0x10(%ebp)
  8007e7:	ff 75 0c             	pushl  0xc(%ebp)
  8007ea:	ff 75 08             	pushl  0x8(%ebp)
  8007ed:	e8 9a ff ff ff       	call   80078c <vsnprintf>
	va_end(ap);

	return rc;
}
  8007f2:	c9                   	leave  
  8007f3:	c3                   	ret    

008007f4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007f4:	55                   	push   %ebp
  8007f5:	89 e5                	mov    %esp,%ebp
  8007f7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fa:	b8 00 00 00 00       	mov    $0x0,%eax
  8007ff:	eb 03                	jmp    800804 <strlen+0x10>
		n++;
  800801:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800804:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800808:	75 f7                	jne    800801 <strlen+0xd>
		n++;
	return n;
}
  80080a:	5d                   	pop    %ebp
  80080b:	c3                   	ret    

0080080c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80080c:	55                   	push   %ebp
  80080d:	89 e5                	mov    %esp,%ebp
  80080f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800812:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800815:	ba 00 00 00 00       	mov    $0x0,%edx
  80081a:	eb 03                	jmp    80081f <strnlen+0x13>
		n++;
  80081c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081f:	39 c2                	cmp    %eax,%edx
  800821:	74 08                	je     80082b <strnlen+0x1f>
  800823:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800827:	75 f3                	jne    80081c <strnlen+0x10>
  800829:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80082b:	5d                   	pop    %ebp
  80082c:	c3                   	ret    

0080082d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80082d:	55                   	push   %ebp
  80082e:	89 e5                	mov    %esp,%ebp
  800830:	53                   	push   %ebx
  800831:	8b 45 08             	mov    0x8(%ebp),%eax
  800834:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800837:	89 c2                	mov    %eax,%edx
  800839:	83 c2 01             	add    $0x1,%edx
  80083c:	83 c1 01             	add    $0x1,%ecx
  80083f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800843:	88 5a ff             	mov    %bl,-0x1(%edx)
  800846:	84 db                	test   %bl,%bl
  800848:	75 ef                	jne    800839 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80084a:	5b                   	pop    %ebx
  80084b:	5d                   	pop    %ebp
  80084c:	c3                   	ret    

0080084d <strcat>:

char *
strcat(char *dst, const char *src)
{
  80084d:	55                   	push   %ebp
  80084e:	89 e5                	mov    %esp,%ebp
  800850:	53                   	push   %ebx
  800851:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800854:	53                   	push   %ebx
  800855:	e8 9a ff ff ff       	call   8007f4 <strlen>
  80085a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80085d:	ff 75 0c             	pushl  0xc(%ebp)
  800860:	01 d8                	add    %ebx,%eax
  800862:	50                   	push   %eax
  800863:	e8 c5 ff ff ff       	call   80082d <strcpy>
	return dst;
}
  800868:	89 d8                	mov    %ebx,%eax
  80086a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80086d:	c9                   	leave  
  80086e:	c3                   	ret    

0080086f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80086f:	55                   	push   %ebp
  800870:	89 e5                	mov    %esp,%ebp
  800872:	56                   	push   %esi
  800873:	53                   	push   %ebx
  800874:	8b 75 08             	mov    0x8(%ebp),%esi
  800877:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80087a:	89 f3                	mov    %esi,%ebx
  80087c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80087f:	89 f2                	mov    %esi,%edx
  800881:	eb 0f                	jmp    800892 <strncpy+0x23>
		*dst++ = *src;
  800883:	83 c2 01             	add    $0x1,%edx
  800886:	0f b6 01             	movzbl (%ecx),%eax
  800889:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80088c:	80 39 01             	cmpb   $0x1,(%ecx)
  80088f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800892:	39 da                	cmp    %ebx,%edx
  800894:	75 ed                	jne    800883 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800896:	89 f0                	mov    %esi,%eax
  800898:	5b                   	pop    %ebx
  800899:	5e                   	pop    %esi
  80089a:	5d                   	pop    %ebp
  80089b:	c3                   	ret    

0080089c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80089c:	55                   	push   %ebp
  80089d:	89 e5                	mov    %esp,%ebp
  80089f:	56                   	push   %esi
  8008a0:	53                   	push   %ebx
  8008a1:	8b 75 08             	mov    0x8(%ebp),%esi
  8008a4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008a7:	8b 55 10             	mov    0x10(%ebp),%edx
  8008aa:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008ac:	85 d2                	test   %edx,%edx
  8008ae:	74 21                	je     8008d1 <strlcpy+0x35>
  8008b0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008b4:	89 f2                	mov    %esi,%edx
  8008b6:	eb 09                	jmp    8008c1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b8:	83 c2 01             	add    $0x1,%edx
  8008bb:	83 c1 01             	add    $0x1,%ecx
  8008be:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008c1:	39 c2                	cmp    %eax,%edx
  8008c3:	74 09                	je     8008ce <strlcpy+0x32>
  8008c5:	0f b6 19             	movzbl (%ecx),%ebx
  8008c8:	84 db                	test   %bl,%bl
  8008ca:	75 ec                	jne    8008b8 <strlcpy+0x1c>
  8008cc:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008ce:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008d1:	29 f0                	sub    %esi,%eax
}
  8008d3:	5b                   	pop    %ebx
  8008d4:	5e                   	pop    %esi
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008dd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008e0:	eb 06                	jmp    8008e8 <strcmp+0x11>
		p++, q++;
  8008e2:	83 c1 01             	add    $0x1,%ecx
  8008e5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008e8:	0f b6 01             	movzbl (%ecx),%eax
  8008eb:	84 c0                	test   %al,%al
  8008ed:	74 04                	je     8008f3 <strcmp+0x1c>
  8008ef:	3a 02                	cmp    (%edx),%al
  8008f1:	74 ef                	je     8008e2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f3:	0f b6 c0             	movzbl %al,%eax
  8008f6:	0f b6 12             	movzbl (%edx),%edx
  8008f9:	29 d0                	sub    %edx,%eax
}
  8008fb:	5d                   	pop    %ebp
  8008fc:	c3                   	ret    

008008fd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008fd:	55                   	push   %ebp
  8008fe:	89 e5                	mov    %esp,%ebp
  800900:	53                   	push   %ebx
  800901:	8b 45 08             	mov    0x8(%ebp),%eax
  800904:	8b 55 0c             	mov    0xc(%ebp),%edx
  800907:	89 c3                	mov    %eax,%ebx
  800909:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80090c:	eb 06                	jmp    800914 <strncmp+0x17>
		n--, p++, q++;
  80090e:	83 c0 01             	add    $0x1,%eax
  800911:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800914:	39 d8                	cmp    %ebx,%eax
  800916:	74 15                	je     80092d <strncmp+0x30>
  800918:	0f b6 08             	movzbl (%eax),%ecx
  80091b:	84 c9                	test   %cl,%cl
  80091d:	74 04                	je     800923 <strncmp+0x26>
  80091f:	3a 0a                	cmp    (%edx),%cl
  800921:	74 eb                	je     80090e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800923:	0f b6 00             	movzbl (%eax),%eax
  800926:	0f b6 12             	movzbl (%edx),%edx
  800929:	29 d0                	sub    %edx,%eax
  80092b:	eb 05                	jmp    800932 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80092d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800932:	5b                   	pop    %ebx
  800933:	5d                   	pop    %ebp
  800934:	c3                   	ret    

00800935 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800935:	55                   	push   %ebp
  800936:	89 e5                	mov    %esp,%ebp
  800938:	8b 45 08             	mov    0x8(%ebp),%eax
  80093b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093f:	eb 07                	jmp    800948 <strchr+0x13>
		if (*s == c)
  800941:	38 ca                	cmp    %cl,%dl
  800943:	74 0f                	je     800954 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800945:	83 c0 01             	add    $0x1,%eax
  800948:	0f b6 10             	movzbl (%eax),%edx
  80094b:	84 d2                	test   %dl,%dl
  80094d:	75 f2                	jne    800941 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80094f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800954:	5d                   	pop    %ebp
  800955:	c3                   	ret    

00800956 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800956:	55                   	push   %ebp
  800957:	89 e5                	mov    %esp,%ebp
  800959:	8b 45 08             	mov    0x8(%ebp),%eax
  80095c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800960:	eb 03                	jmp    800965 <strfind+0xf>
  800962:	83 c0 01             	add    $0x1,%eax
  800965:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800968:	38 ca                	cmp    %cl,%dl
  80096a:	74 04                	je     800970 <strfind+0x1a>
  80096c:	84 d2                	test   %dl,%dl
  80096e:	75 f2                	jne    800962 <strfind+0xc>
			break;
	return (char *) s;
}
  800970:	5d                   	pop    %ebp
  800971:	c3                   	ret    

00800972 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800972:	55                   	push   %ebp
  800973:	89 e5                	mov    %esp,%ebp
  800975:	57                   	push   %edi
  800976:	56                   	push   %esi
  800977:	53                   	push   %ebx
  800978:	8b 7d 08             	mov    0x8(%ebp),%edi
  80097b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80097e:	85 c9                	test   %ecx,%ecx
  800980:	74 36                	je     8009b8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800982:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800988:	75 28                	jne    8009b2 <memset+0x40>
  80098a:	f6 c1 03             	test   $0x3,%cl
  80098d:	75 23                	jne    8009b2 <memset+0x40>
		c &= 0xFF;
  80098f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800993:	89 d3                	mov    %edx,%ebx
  800995:	c1 e3 08             	shl    $0x8,%ebx
  800998:	89 d6                	mov    %edx,%esi
  80099a:	c1 e6 18             	shl    $0x18,%esi
  80099d:	89 d0                	mov    %edx,%eax
  80099f:	c1 e0 10             	shl    $0x10,%eax
  8009a2:	09 f0                	or     %esi,%eax
  8009a4:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009a6:	89 d8                	mov    %ebx,%eax
  8009a8:	09 d0                	or     %edx,%eax
  8009aa:	c1 e9 02             	shr    $0x2,%ecx
  8009ad:	fc                   	cld    
  8009ae:	f3 ab                	rep stos %eax,%es:(%edi)
  8009b0:	eb 06                	jmp    8009b8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009b5:	fc                   	cld    
  8009b6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b8:	89 f8                	mov    %edi,%eax
  8009ba:	5b                   	pop    %ebx
  8009bb:	5e                   	pop    %esi
  8009bc:	5f                   	pop    %edi
  8009bd:	5d                   	pop    %ebp
  8009be:	c3                   	ret    

008009bf <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009bf:	55                   	push   %ebp
  8009c0:	89 e5                	mov    %esp,%ebp
  8009c2:	57                   	push   %edi
  8009c3:	56                   	push   %esi
  8009c4:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c7:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009cd:	39 c6                	cmp    %eax,%esi
  8009cf:	73 35                	jae    800a06 <memmove+0x47>
  8009d1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009d4:	39 d0                	cmp    %edx,%eax
  8009d6:	73 2e                	jae    800a06 <memmove+0x47>
		s += n;
		d += n;
  8009d8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009db:	89 d6                	mov    %edx,%esi
  8009dd:	09 fe                	or     %edi,%esi
  8009df:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009e5:	75 13                	jne    8009fa <memmove+0x3b>
  8009e7:	f6 c1 03             	test   $0x3,%cl
  8009ea:	75 0e                	jne    8009fa <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009ec:	83 ef 04             	sub    $0x4,%edi
  8009ef:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009f2:	c1 e9 02             	shr    $0x2,%ecx
  8009f5:	fd                   	std    
  8009f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f8:	eb 09                	jmp    800a03 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009fa:	83 ef 01             	sub    $0x1,%edi
  8009fd:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a00:	fd                   	std    
  800a01:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a03:	fc                   	cld    
  800a04:	eb 1d                	jmp    800a23 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a06:	89 f2                	mov    %esi,%edx
  800a08:	09 c2                	or     %eax,%edx
  800a0a:	f6 c2 03             	test   $0x3,%dl
  800a0d:	75 0f                	jne    800a1e <memmove+0x5f>
  800a0f:	f6 c1 03             	test   $0x3,%cl
  800a12:	75 0a                	jne    800a1e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a14:	c1 e9 02             	shr    $0x2,%ecx
  800a17:	89 c7                	mov    %eax,%edi
  800a19:	fc                   	cld    
  800a1a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a1c:	eb 05                	jmp    800a23 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a1e:	89 c7                	mov    %eax,%edi
  800a20:	fc                   	cld    
  800a21:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a23:	5e                   	pop    %esi
  800a24:	5f                   	pop    %edi
  800a25:	5d                   	pop    %ebp
  800a26:	c3                   	ret    

00800a27 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a27:	55                   	push   %ebp
  800a28:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a2a:	ff 75 10             	pushl  0x10(%ebp)
  800a2d:	ff 75 0c             	pushl  0xc(%ebp)
  800a30:	ff 75 08             	pushl  0x8(%ebp)
  800a33:	e8 87 ff ff ff       	call   8009bf <memmove>
}
  800a38:	c9                   	leave  
  800a39:	c3                   	ret    

00800a3a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a3a:	55                   	push   %ebp
  800a3b:	89 e5                	mov    %esp,%ebp
  800a3d:	56                   	push   %esi
  800a3e:	53                   	push   %ebx
  800a3f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a42:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a45:	89 c6                	mov    %eax,%esi
  800a47:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a4a:	eb 1a                	jmp    800a66 <memcmp+0x2c>
		if (*s1 != *s2)
  800a4c:	0f b6 08             	movzbl (%eax),%ecx
  800a4f:	0f b6 1a             	movzbl (%edx),%ebx
  800a52:	38 d9                	cmp    %bl,%cl
  800a54:	74 0a                	je     800a60 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a56:	0f b6 c1             	movzbl %cl,%eax
  800a59:	0f b6 db             	movzbl %bl,%ebx
  800a5c:	29 d8                	sub    %ebx,%eax
  800a5e:	eb 0f                	jmp    800a6f <memcmp+0x35>
		s1++, s2++;
  800a60:	83 c0 01             	add    $0x1,%eax
  800a63:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a66:	39 f0                	cmp    %esi,%eax
  800a68:	75 e2                	jne    800a4c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a6a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a6f:	5b                   	pop    %ebx
  800a70:	5e                   	pop    %esi
  800a71:	5d                   	pop    %ebp
  800a72:	c3                   	ret    

00800a73 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a73:	55                   	push   %ebp
  800a74:	89 e5                	mov    %esp,%ebp
  800a76:	53                   	push   %ebx
  800a77:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a7a:	89 c1                	mov    %eax,%ecx
  800a7c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a83:	eb 0a                	jmp    800a8f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a85:	0f b6 10             	movzbl (%eax),%edx
  800a88:	39 da                	cmp    %ebx,%edx
  800a8a:	74 07                	je     800a93 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a8c:	83 c0 01             	add    $0x1,%eax
  800a8f:	39 c8                	cmp    %ecx,%eax
  800a91:	72 f2                	jb     800a85 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a93:	5b                   	pop    %ebx
  800a94:	5d                   	pop    %ebp
  800a95:	c3                   	ret    

00800a96 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a96:	55                   	push   %ebp
  800a97:	89 e5                	mov    %esp,%ebp
  800a99:	57                   	push   %edi
  800a9a:	56                   	push   %esi
  800a9b:	53                   	push   %ebx
  800a9c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a9f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa2:	eb 03                	jmp    800aa7 <strtol+0x11>
		s++;
  800aa4:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa7:	0f b6 01             	movzbl (%ecx),%eax
  800aaa:	3c 20                	cmp    $0x20,%al
  800aac:	74 f6                	je     800aa4 <strtol+0xe>
  800aae:	3c 09                	cmp    $0x9,%al
  800ab0:	74 f2                	je     800aa4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ab2:	3c 2b                	cmp    $0x2b,%al
  800ab4:	75 0a                	jne    800ac0 <strtol+0x2a>
		s++;
  800ab6:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab9:	bf 00 00 00 00       	mov    $0x0,%edi
  800abe:	eb 11                	jmp    800ad1 <strtol+0x3b>
  800ac0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ac5:	3c 2d                	cmp    $0x2d,%al
  800ac7:	75 08                	jne    800ad1 <strtol+0x3b>
		s++, neg = 1;
  800ac9:	83 c1 01             	add    $0x1,%ecx
  800acc:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ad1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ad7:	75 15                	jne    800aee <strtol+0x58>
  800ad9:	80 39 30             	cmpb   $0x30,(%ecx)
  800adc:	75 10                	jne    800aee <strtol+0x58>
  800ade:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ae2:	75 7c                	jne    800b60 <strtol+0xca>
		s += 2, base = 16;
  800ae4:	83 c1 02             	add    $0x2,%ecx
  800ae7:	bb 10 00 00 00       	mov    $0x10,%ebx
  800aec:	eb 16                	jmp    800b04 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800aee:	85 db                	test   %ebx,%ebx
  800af0:	75 12                	jne    800b04 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800af2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800af7:	80 39 30             	cmpb   $0x30,(%ecx)
  800afa:	75 08                	jne    800b04 <strtol+0x6e>
		s++, base = 8;
  800afc:	83 c1 01             	add    $0x1,%ecx
  800aff:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b04:	b8 00 00 00 00       	mov    $0x0,%eax
  800b09:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b0c:	0f b6 11             	movzbl (%ecx),%edx
  800b0f:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b12:	89 f3                	mov    %esi,%ebx
  800b14:	80 fb 09             	cmp    $0x9,%bl
  800b17:	77 08                	ja     800b21 <strtol+0x8b>
			dig = *s - '0';
  800b19:	0f be d2             	movsbl %dl,%edx
  800b1c:	83 ea 30             	sub    $0x30,%edx
  800b1f:	eb 22                	jmp    800b43 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b21:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b24:	89 f3                	mov    %esi,%ebx
  800b26:	80 fb 19             	cmp    $0x19,%bl
  800b29:	77 08                	ja     800b33 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b2b:	0f be d2             	movsbl %dl,%edx
  800b2e:	83 ea 57             	sub    $0x57,%edx
  800b31:	eb 10                	jmp    800b43 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b33:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b36:	89 f3                	mov    %esi,%ebx
  800b38:	80 fb 19             	cmp    $0x19,%bl
  800b3b:	77 16                	ja     800b53 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b3d:	0f be d2             	movsbl %dl,%edx
  800b40:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b43:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b46:	7d 0b                	jge    800b53 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b48:	83 c1 01             	add    $0x1,%ecx
  800b4b:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b4f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b51:	eb b9                	jmp    800b0c <strtol+0x76>

	if (endptr)
  800b53:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b57:	74 0d                	je     800b66 <strtol+0xd0>
		*endptr = (char *) s;
  800b59:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b5c:	89 0e                	mov    %ecx,(%esi)
  800b5e:	eb 06                	jmp    800b66 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b60:	85 db                	test   %ebx,%ebx
  800b62:	74 98                	je     800afc <strtol+0x66>
  800b64:	eb 9e                	jmp    800b04 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b66:	89 c2                	mov    %eax,%edx
  800b68:	f7 da                	neg    %edx
  800b6a:	85 ff                	test   %edi,%edi
  800b6c:	0f 45 c2             	cmovne %edx,%eax
}
  800b6f:	5b                   	pop    %ebx
  800b70:	5e                   	pop    %esi
  800b71:	5f                   	pop    %edi
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	57                   	push   %edi
  800b78:	56                   	push   %esi
  800b79:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7a:	b8 00 00 00 00       	mov    $0x0,%eax
  800b7f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b82:	8b 55 08             	mov    0x8(%ebp),%edx
  800b85:	89 c3                	mov    %eax,%ebx
  800b87:	89 c7                	mov    %eax,%edi
  800b89:	89 c6                	mov    %eax,%esi
  800b8b:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b8d:	5b                   	pop    %ebx
  800b8e:	5e                   	pop    %esi
  800b8f:	5f                   	pop    %edi
  800b90:	5d                   	pop    %ebp
  800b91:	c3                   	ret    

00800b92 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b92:	55                   	push   %ebp
  800b93:	89 e5                	mov    %esp,%ebp
  800b95:	57                   	push   %edi
  800b96:	56                   	push   %esi
  800b97:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b98:	ba 00 00 00 00       	mov    $0x0,%edx
  800b9d:	b8 01 00 00 00       	mov    $0x1,%eax
  800ba2:	89 d1                	mov    %edx,%ecx
  800ba4:	89 d3                	mov    %edx,%ebx
  800ba6:	89 d7                	mov    %edx,%edi
  800ba8:	89 d6                	mov    %edx,%esi
  800baa:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800bac:	5b                   	pop    %ebx
  800bad:	5e                   	pop    %esi
  800bae:	5f                   	pop    %edi
  800baf:	5d                   	pop    %ebp
  800bb0:	c3                   	ret    

00800bb1 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bb1:	55                   	push   %ebp
  800bb2:	89 e5                	mov    %esp,%ebp
  800bb4:	57                   	push   %edi
  800bb5:	56                   	push   %esi
  800bb6:	53                   	push   %ebx
  800bb7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bba:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bbf:	b8 03 00 00 00       	mov    $0x3,%eax
  800bc4:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc7:	89 cb                	mov    %ecx,%ebx
  800bc9:	89 cf                	mov    %ecx,%edi
  800bcb:	89 ce                	mov    %ecx,%esi
  800bcd:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bcf:	85 c0                	test   %eax,%eax
  800bd1:	7e 17                	jle    800bea <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bd3:	83 ec 0c             	sub    $0xc,%esp
  800bd6:	50                   	push   %eax
  800bd7:	6a 03                	push   $0x3
  800bd9:	68 c4 17 80 00       	push   $0x8017c4
  800bde:	6a 23                	push   $0x23
  800be0:	68 e1 17 80 00       	push   $0x8017e1
  800be5:	e8 66 f5 ff ff       	call   800150 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bea:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bed:	5b                   	pop    %ebx
  800bee:	5e                   	pop    %esi
  800bef:	5f                   	pop    %edi
  800bf0:	5d                   	pop    %ebp
  800bf1:	c3                   	ret    

00800bf2 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bf2:	55                   	push   %ebp
  800bf3:	89 e5                	mov    %esp,%ebp
  800bf5:	57                   	push   %edi
  800bf6:	56                   	push   %esi
  800bf7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf8:	ba 00 00 00 00       	mov    $0x0,%edx
  800bfd:	b8 02 00 00 00       	mov    $0x2,%eax
  800c02:	89 d1                	mov    %edx,%ecx
  800c04:	89 d3                	mov    %edx,%ebx
  800c06:	89 d7                	mov    %edx,%edi
  800c08:	89 d6                	mov    %edx,%esi
  800c0a:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c0c:	5b                   	pop    %ebx
  800c0d:	5e                   	pop    %esi
  800c0e:	5f                   	pop    %edi
  800c0f:	5d                   	pop    %ebp
  800c10:	c3                   	ret    

00800c11 <sys_yield>:

void
sys_yield(void)
{
  800c11:	55                   	push   %ebp
  800c12:	89 e5                	mov    %esp,%ebp
  800c14:	57                   	push   %edi
  800c15:	56                   	push   %esi
  800c16:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c17:	ba 00 00 00 00       	mov    $0x0,%edx
  800c1c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c21:	89 d1                	mov    %edx,%ecx
  800c23:	89 d3                	mov    %edx,%ebx
  800c25:	89 d7                	mov    %edx,%edi
  800c27:	89 d6                	mov    %edx,%esi
  800c29:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c2b:	5b                   	pop    %ebx
  800c2c:	5e                   	pop    %esi
  800c2d:	5f                   	pop    %edi
  800c2e:	5d                   	pop    %ebp
  800c2f:	c3                   	ret    

00800c30 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c30:	55                   	push   %ebp
  800c31:	89 e5                	mov    %esp,%ebp
  800c33:	57                   	push   %edi
  800c34:	56                   	push   %esi
  800c35:	53                   	push   %ebx
  800c36:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c39:	be 00 00 00 00       	mov    $0x0,%esi
  800c3e:	b8 04 00 00 00       	mov    $0x4,%eax
  800c43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c46:	8b 55 08             	mov    0x8(%ebp),%edx
  800c49:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c4c:	89 f7                	mov    %esi,%edi
  800c4e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c50:	85 c0                	test   %eax,%eax
  800c52:	7e 17                	jle    800c6b <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c54:	83 ec 0c             	sub    $0xc,%esp
  800c57:	50                   	push   %eax
  800c58:	6a 04                	push   $0x4
  800c5a:	68 c4 17 80 00       	push   $0x8017c4
  800c5f:	6a 23                	push   $0x23
  800c61:	68 e1 17 80 00       	push   $0x8017e1
  800c66:	e8 e5 f4 ff ff       	call   800150 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c6e:	5b                   	pop    %ebx
  800c6f:	5e                   	pop    %esi
  800c70:	5f                   	pop    %edi
  800c71:	5d                   	pop    %ebp
  800c72:	c3                   	ret    

00800c73 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c73:	55                   	push   %ebp
  800c74:	89 e5                	mov    %esp,%ebp
  800c76:	57                   	push   %edi
  800c77:	56                   	push   %esi
  800c78:	53                   	push   %ebx
  800c79:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7c:	b8 05 00 00 00       	mov    $0x5,%eax
  800c81:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c84:	8b 55 08             	mov    0x8(%ebp),%edx
  800c87:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c8a:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c8d:	8b 75 18             	mov    0x18(%ebp),%esi
  800c90:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c92:	85 c0                	test   %eax,%eax
  800c94:	7e 17                	jle    800cad <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c96:	83 ec 0c             	sub    $0xc,%esp
  800c99:	50                   	push   %eax
  800c9a:	6a 05                	push   $0x5
  800c9c:	68 c4 17 80 00       	push   $0x8017c4
  800ca1:	6a 23                	push   $0x23
  800ca3:	68 e1 17 80 00       	push   $0x8017e1
  800ca8:	e8 a3 f4 ff ff       	call   800150 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800cad:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cb0:	5b                   	pop    %ebx
  800cb1:	5e                   	pop    %esi
  800cb2:	5f                   	pop    %edi
  800cb3:	5d                   	pop    %ebp
  800cb4:	c3                   	ret    

00800cb5 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800cb5:	55                   	push   %ebp
  800cb6:	89 e5                	mov    %esp,%ebp
  800cb8:	57                   	push   %edi
  800cb9:	56                   	push   %esi
  800cba:	53                   	push   %ebx
  800cbb:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cbe:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cc3:	b8 06 00 00 00       	mov    $0x6,%eax
  800cc8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ccb:	8b 55 08             	mov    0x8(%ebp),%edx
  800cce:	89 df                	mov    %ebx,%edi
  800cd0:	89 de                	mov    %ebx,%esi
  800cd2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cd4:	85 c0                	test   %eax,%eax
  800cd6:	7e 17                	jle    800cef <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd8:	83 ec 0c             	sub    $0xc,%esp
  800cdb:	50                   	push   %eax
  800cdc:	6a 06                	push   $0x6
  800cde:	68 c4 17 80 00       	push   $0x8017c4
  800ce3:	6a 23                	push   $0x23
  800ce5:	68 e1 17 80 00       	push   $0x8017e1
  800cea:	e8 61 f4 ff ff       	call   800150 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800cef:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cf2:	5b                   	pop    %ebx
  800cf3:	5e                   	pop    %esi
  800cf4:	5f                   	pop    %edi
  800cf5:	5d                   	pop    %ebp
  800cf6:	c3                   	ret    

00800cf7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800cf7:	55                   	push   %ebp
  800cf8:	89 e5                	mov    %esp,%ebp
  800cfa:	57                   	push   %edi
  800cfb:	56                   	push   %esi
  800cfc:	53                   	push   %ebx
  800cfd:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d00:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d05:	b8 08 00 00 00       	mov    $0x8,%eax
  800d0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d0d:	8b 55 08             	mov    0x8(%ebp),%edx
  800d10:	89 df                	mov    %ebx,%edi
  800d12:	89 de                	mov    %ebx,%esi
  800d14:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d16:	85 c0                	test   %eax,%eax
  800d18:	7e 17                	jle    800d31 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d1a:	83 ec 0c             	sub    $0xc,%esp
  800d1d:	50                   	push   %eax
  800d1e:	6a 08                	push   $0x8
  800d20:	68 c4 17 80 00       	push   $0x8017c4
  800d25:	6a 23                	push   $0x23
  800d27:	68 e1 17 80 00       	push   $0x8017e1
  800d2c:	e8 1f f4 ff ff       	call   800150 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d31:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d34:	5b                   	pop    %ebx
  800d35:	5e                   	pop    %esi
  800d36:	5f                   	pop    %edi
  800d37:	5d                   	pop    %ebp
  800d38:	c3                   	ret    

00800d39 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d39:	55                   	push   %ebp
  800d3a:	89 e5                	mov    %esp,%ebp
  800d3c:	57                   	push   %edi
  800d3d:	56                   	push   %esi
  800d3e:	53                   	push   %ebx
  800d3f:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d42:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d47:	b8 09 00 00 00       	mov    $0x9,%eax
  800d4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d4f:	8b 55 08             	mov    0x8(%ebp),%edx
  800d52:	89 df                	mov    %ebx,%edi
  800d54:	89 de                	mov    %ebx,%esi
  800d56:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d58:	85 c0                	test   %eax,%eax
  800d5a:	7e 17                	jle    800d73 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d5c:	83 ec 0c             	sub    $0xc,%esp
  800d5f:	50                   	push   %eax
  800d60:	6a 09                	push   $0x9
  800d62:	68 c4 17 80 00       	push   $0x8017c4
  800d67:	6a 23                	push   $0x23
  800d69:	68 e1 17 80 00       	push   $0x8017e1
  800d6e:	e8 dd f3 ff ff       	call   800150 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d73:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d76:	5b                   	pop    %ebx
  800d77:	5e                   	pop    %esi
  800d78:	5f                   	pop    %edi
  800d79:	5d                   	pop    %ebp
  800d7a:	c3                   	ret    

00800d7b <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d7b:	55                   	push   %ebp
  800d7c:	89 e5                	mov    %esp,%ebp
  800d7e:	57                   	push   %edi
  800d7f:	56                   	push   %esi
  800d80:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d81:	be 00 00 00 00       	mov    $0x0,%esi
  800d86:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d8b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d8e:	8b 55 08             	mov    0x8(%ebp),%edx
  800d91:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d94:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d97:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d99:	5b                   	pop    %ebx
  800d9a:	5e                   	pop    %esi
  800d9b:	5f                   	pop    %edi
  800d9c:	5d                   	pop    %ebp
  800d9d:	c3                   	ret    

00800d9e <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d9e:	55                   	push   %ebp
  800d9f:	89 e5                	mov    %esp,%ebp
  800da1:	57                   	push   %edi
  800da2:	56                   	push   %esi
  800da3:	53                   	push   %ebx
  800da4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800da7:	b9 00 00 00 00       	mov    $0x0,%ecx
  800dac:	b8 0c 00 00 00       	mov    $0xc,%eax
  800db1:	8b 55 08             	mov    0x8(%ebp),%edx
  800db4:	89 cb                	mov    %ecx,%ebx
  800db6:	89 cf                	mov    %ecx,%edi
  800db8:	89 ce                	mov    %ecx,%esi
  800dba:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800dbc:	85 c0                	test   %eax,%eax
  800dbe:	7e 17                	jle    800dd7 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dc0:	83 ec 0c             	sub    $0xc,%esp
  800dc3:	50                   	push   %eax
  800dc4:	6a 0c                	push   $0xc
  800dc6:	68 c4 17 80 00       	push   $0x8017c4
  800dcb:	6a 23                	push   $0x23
  800dcd:	68 e1 17 80 00       	push   $0x8017e1
  800dd2:	e8 79 f3 ff ff       	call   800150 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800dd7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800dda:	5b                   	pop    %ebx
  800ddb:	5e                   	pop    %esi
  800ddc:	5f                   	pop    %edi
  800ddd:	5d                   	pop    %ebp
  800dde:	c3                   	ret    

00800ddf <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800ddf:	55                   	push   %ebp
  800de0:	89 e5                	mov    %esp,%ebp
  800de2:	53                   	push   %ebx
  800de3:	83 ec 04             	sub    $0x4,%esp
  800de6:	8b 45 08             	mov    0x8(%ebp),%eax
void *addr = (void *) utf->utf_fault_va;
  800de9:	8b 18                	mov    (%eax),%ebx
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	if ((err & FEC_WR) == 0)
  800deb:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800def:	75 12                	jne    800e03 <pgfault+0x24>
		panic("pgfault: faulting address [%08x] not a write\n", addr);
  800df1:	53                   	push   %ebx
  800df2:	68 f0 17 80 00       	push   $0x8017f0
  800df7:	6a 1f                	push   $0x1f
  800df9:	68 70 18 80 00       	push   $0x801870
  800dfe:	e8 4d f3 ff ff       	call   800150 <_panic>

	if (!(uvpt[PGNUM(addr)] & PTE_COW))
  800e03:	89 d8                	mov    %ebx,%eax
  800e05:	c1 e8 0c             	shr    $0xc,%eax
  800e08:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800e0f:	f6 c4 08             	test   $0x8,%ah
  800e12:	75 14                	jne    800e28 <pgfault+0x49>
		panic("pgfault: fault was not on a copy-on-write page\n");
  800e14:	83 ec 04             	sub    $0x4,%esp
  800e17:	68 20 18 80 00       	push   $0x801820
  800e1c:	6a 22                	push   $0x22
  800e1e:	68 70 18 80 00       	push   $0x801870
  800e23:	e8 28 f3 ff ff       	call   800150 <_panic>
	//   You should make three system calls.

	// LAB 4: Your code here.


	if ((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0)
  800e28:	83 ec 04             	sub    $0x4,%esp
  800e2b:	6a 07                	push   $0x7
  800e2d:	68 00 f0 7f 00       	push   $0x7ff000
  800e32:	6a 00                	push   $0x0
  800e34:	e8 f7 fd ff ff       	call   800c30 <sys_page_alloc>
  800e39:	83 c4 10             	add    $0x10,%esp
  800e3c:	85 c0                	test   %eax,%eax
  800e3e:	79 12                	jns    800e52 <pgfault+0x73>
		panic("sys_page_alloc: %e\n", r);
  800e40:	50                   	push   %eax
  800e41:	68 7b 18 80 00       	push   $0x80187b
  800e46:	6a 30                	push   $0x30
  800e48:	68 70 18 80 00       	push   $0x801870
  800e4d:	e8 fe f2 ff ff       	call   800150 <_panic>


	void *src_addr = (void *) ROUNDDOWN(addr, PGSIZE);
  800e52:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove(PFTEMP, src_addr, PGSIZE);
  800e58:	83 ec 04             	sub    $0x4,%esp
  800e5b:	68 00 10 00 00       	push   $0x1000
  800e60:	53                   	push   %ebx
  800e61:	68 00 f0 7f 00       	push   $0x7ff000
  800e66:	e8 54 fb ff ff       	call   8009bf <memmove>

	
	if ((r = sys_page_map(0, PFTEMP, 0, src_addr, PTE_P | PTE_U | PTE_W)) < 0)
  800e6b:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800e72:	53                   	push   %ebx
  800e73:	6a 00                	push   $0x0
  800e75:	68 00 f0 7f 00       	push   $0x7ff000
  800e7a:	6a 00                	push   $0x0
  800e7c:	e8 f2 fd ff ff       	call   800c73 <sys_page_map>
  800e81:	83 c4 20             	add    $0x20,%esp
  800e84:	85 c0                	test   %eax,%eax
  800e86:	79 12                	jns    800e9a <pgfault+0xbb>
	panic("sys_page_map: %e\n", r);
  800e88:	50                   	push   %eax
  800e89:	68 8f 18 80 00       	push   $0x80188f
  800e8e:	6a 38                	push   $0x38
  800e90:	68 70 18 80 00       	push   $0x801870
  800e95:	e8 b6 f2 ff ff       	call   800150 <_panic>

}
  800e9a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800e9d:	c9                   	leave  
  800e9e:	c3                   	ret    

00800e9f <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800e9f:	55                   	push   %ebp
  800ea0:	89 e5                	mov    %esp,%ebp
  800ea2:	57                   	push   %edi
  800ea3:	56                   	push   %esi
  800ea4:	53                   	push   %ebx
  800ea5:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	int r;
	envid_t child_envid;

	set_pgfault_handler(pgfault);
  800ea8:	68 df 0d 80 00       	push   $0x800ddf
  800ead:	e8 4b 03 00 00       	call   8011fd <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800eb2:	b8 07 00 00 00       	mov    $0x7,%eax
  800eb7:	cd 30                	int    $0x30
  800eb9:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800ebc:	89 45 e0             	mov    %eax,-0x20(%ebp)

	child_envid = sys_exofork();
	if (child_envid < 0)
  800ebf:	83 c4 10             	add    $0x10,%esp
  800ec2:	85 c0                	test   %eax,%eax
  800ec4:	79 15                	jns    800edb <fork+0x3c>
		panic("sys_exofork: %e\n", child_envid);
  800ec6:	50                   	push   %eax
  800ec7:	68 a1 18 80 00       	push   $0x8018a1
  800ecc:	68 82 00 00 00       	push   $0x82
  800ed1:	68 70 18 80 00       	push   $0x801870
  800ed6:	e8 75 f2 ff ff       	call   800150 <_panic>
  800edb:	bf 00 00 00 00       	mov    $0x0,%edi
  800ee0:	bb 00 00 00 00       	mov    $0x0,%ebx
	if (child_envid == 0) { // child
  800ee5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800ee9:	75 21                	jne    800f0c <fork+0x6d>
		// Fix thisenv like dumbfork does and return 0
		thisenv = &envs[ENVX(sys_getenvid())];
  800eeb:	e8 02 fd ff ff       	call   800bf2 <sys_getenvid>
  800ef0:	25 ff 03 00 00       	and    $0x3ff,%eax
  800ef5:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800ef8:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800efd:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800f02:	b8 00 00 00 00       	mov    $0x0,%eax
  800f07:	e9 c7 01 00 00       	jmp    8010d3 <fork+0x234>


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
		uint32_t pdx = ROUNDDOWN(page_num, NPDENTRIES) / NPDENTRIES;
  800f0c:	89 d8                	mov    %ebx,%eax
  800f0e:	c1 e8 0a             	shr    $0xa,%eax
		if ((uvpd[pdx] & PTE_P) == PTE_P &&((uvpt[page_num] & PTE_P) == PTE_P)) {
  800f11:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800f18:	a8 01                	test   $0x1,%al
  800f1a:	0f 84 18 01 00 00    	je     801038 <fork+0x199>
  800f20:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f27:	a8 01                	test   $0x1,%al
  800f29:	0f 84 09 01 00 00    	je     801038 <fork+0x199>
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uint32_t perm = PTE_P | PTE_COW;
	envid_t this_envid = thisenv->env_id;
  800f2f:	a1 04 20 80 00       	mov    0x802004,%eax
  800f34:	8b 40 48             	mov    0x48(%eax),%eax
  800f37:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// LAB 4: Your code here.
	if (uvpt[pn] & PTE_SHARE) {
  800f3a:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f41:	f6 c4 04             	test   $0x4,%ah
  800f44:	74 3a                	je     800f80 <fork+0xe1>
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), uvpt[pn] & PTE_SYSCALL)) < 0)
  800f46:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f4d:	83 ec 0c             	sub    $0xc,%esp
  800f50:	25 07 0e 00 00       	and    $0xe07,%eax
  800f55:	50                   	push   %eax
  800f56:	57                   	push   %edi
  800f57:	ff 75 e0             	pushl  -0x20(%ebp)
  800f5a:	57                   	push   %edi
  800f5b:	ff 75 e4             	pushl  -0x1c(%ebp)
  800f5e:	e8 10 fd ff ff       	call   800c73 <sys_page_map>
  800f63:	83 c4 20             	add    $0x20,%esp
  800f66:	85 c0                	test   %eax,%eax
  800f68:	0f 89 ca 00 00 00    	jns    801038 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  800f6e:	50                   	push   %eax
  800f6f:	68 8f 18 80 00       	push   $0x80188f
  800f74:	6a 51                	push   $0x51
  800f76:	68 70 18 80 00       	push   $0x801870
  800f7b:	e8 d0 f1 ff ff       	call   800150 <_panic>
	} else if (uvpt[pn] & PTE_COW || uvpt[pn] & PTE_W) {
  800f80:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f87:	f6 c4 08             	test   $0x8,%ah
  800f8a:	75 0b                	jne    800f97 <fork+0xf8>
  800f8c:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f93:	a8 02                	test   $0x2,%al
  800f95:	74 6b                	je     801002 <fork+0x163>
		if (uvpt[pn] & PTE_U)
  800f97:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  800f9e:	83 e0 04             	and    $0x4,%eax
			perm |= PTE_U;
  800fa1:	83 f8 01             	cmp    $0x1,%eax
  800fa4:	19 f6                	sbb    %esi,%esi
  800fa6:	83 e6 fc             	and    $0xfffffffc,%esi
  800fa9:	81 c6 05 08 00 00    	add    $0x805,%esi

		// Map page COW, U and P in child
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), perm)) < 0)
  800faf:	83 ec 0c             	sub    $0xc,%esp
  800fb2:	56                   	push   %esi
  800fb3:	57                   	push   %edi
  800fb4:	ff 75 e0             	pushl  -0x20(%ebp)
  800fb7:	57                   	push   %edi
  800fb8:	ff 75 e4             	pushl  -0x1c(%ebp)
  800fbb:	e8 b3 fc ff ff       	call   800c73 <sys_page_map>
  800fc0:	83 c4 20             	add    $0x20,%esp
  800fc3:	85 c0                	test   %eax,%eax
  800fc5:	79 12                	jns    800fd9 <fork+0x13a>
			panic("sys_page_map: %e\n", r);
  800fc7:	50                   	push   %eax
  800fc8:	68 8f 18 80 00       	push   $0x80188f
  800fcd:	6a 58                	push   $0x58
  800fcf:	68 70 18 80 00       	push   $0x801870
  800fd4:	e8 77 f1 ff ff       	call   800150 <_panic>

		// Map page COW, U and P in parent
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), this_envid, (void *) (pn*PGSIZE), perm)) < 0)
  800fd9:	83 ec 0c             	sub    $0xc,%esp
  800fdc:	56                   	push   %esi
  800fdd:	57                   	push   %edi
  800fde:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800fe1:	50                   	push   %eax
  800fe2:	57                   	push   %edi
  800fe3:	50                   	push   %eax
  800fe4:	e8 8a fc ff ff       	call   800c73 <sys_page_map>
  800fe9:	83 c4 20             	add    $0x20,%esp
  800fec:	85 c0                	test   %eax,%eax
  800fee:	79 48                	jns    801038 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  800ff0:	50                   	push   %eax
  800ff1:	68 8f 18 80 00       	push   $0x80188f
  800ff6:	6a 5c                	push   $0x5c
  800ff8:	68 70 18 80 00       	push   $0x801870
  800ffd:	e8 4e f1 ff ff       	call   800150 <_panic>

	} else { // map pages that are present but not writable or COW with their original permissions
		if ((r = sys_page_map(this_envid, (void *) (pn*PGSIZE), envid, (void *) (pn*PGSIZE), uvpt[pn] & PTE_SYSCALL)) < 0)
  801002:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  801009:	83 ec 0c             	sub    $0xc,%esp
  80100c:	25 07 0e 00 00       	and    $0xe07,%eax
  801011:	50                   	push   %eax
  801012:	57                   	push   %edi
  801013:	ff 75 e0             	pushl  -0x20(%ebp)
  801016:	57                   	push   %edi
  801017:	ff 75 e4             	pushl  -0x1c(%ebp)
  80101a:	e8 54 fc ff ff       	call   800c73 <sys_page_map>
  80101f:	83 c4 20             	add    $0x20,%esp
  801022:	85 c0                	test   %eax,%eax
  801024:	79 12                	jns    801038 <fork+0x199>
			panic("sys_page_map: %e\n", r);
  801026:	50                   	push   %eax
  801027:	68 8f 18 80 00       	push   $0x80188f
  80102c:	6a 60                	push   $0x60
  80102e:	68 70 18 80 00       	push   $0x801870
  801033:	e8 18 f1 ff ff       	call   800150 <_panic>
	// We're in the parent


	uint32_t page_num;
	pte_t *pte;
	for (page_num = 0; page_num < PGNUM(UTOP - PGSIZE); page_num++) {
  801038:	83 c3 01             	add    $0x1,%ebx
  80103b:	81 c7 00 10 00 00    	add    $0x1000,%edi
  801041:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  801047:	0f 85 bf fe ff ff    	jne    800f0c <fork+0x6d>
		}
	}

	// Allocate exception stack space for child
	
	if ((r = sys_page_alloc(child_envid, (void *) (UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W)) < 0)
  80104d:	83 ec 04             	sub    $0x4,%esp
  801050:	6a 07                	push   $0x7
  801052:	68 00 f0 bf ee       	push   $0xeebff000
  801057:	ff 75 dc             	pushl  -0x24(%ebp)
  80105a:	e8 d1 fb ff ff       	call   800c30 <sys_page_alloc>
  80105f:	83 c4 10             	add    $0x10,%esp
  801062:	85 c0                	test   %eax,%eax
  801064:	79 15                	jns    80107b <fork+0x1dc>
		panic("sys_page_alloc: %e\n", r);
  801066:	50                   	push   %eax
  801067:	68 7b 18 80 00       	push   $0x80187b
  80106c:	68 98 00 00 00       	push   $0x98
  801071:	68 70 18 80 00       	push   $0x801870
  801076:	e8 d5 f0 ff ff       	call   800150 <_panic>

	// Set page fault handler for the child
	if ((r = sys_env_set_pgfault_upcall(child_envid, _pgfault_upcall)) < 0)
  80107b:	83 ec 08             	sub    $0x8,%esp
  80107e:	68 52 12 80 00       	push   $0x801252
  801083:	ff 75 dc             	pushl  -0x24(%ebp)
  801086:	e8 ae fc ff ff       	call   800d39 <sys_env_set_pgfault_upcall>
  80108b:	83 c4 10             	add    $0x10,%esp
  80108e:	85 c0                	test   %eax,%eax
  801090:	79 15                	jns    8010a7 <fork+0x208>
		panic("sys_env_set_pgfault_upcall: %e\n", r);
  801092:	50                   	push   %eax
  801093:	68 50 18 80 00       	push   $0x801850
  801098:	68 9c 00 00 00       	push   $0x9c
  80109d:	68 70 18 80 00       	push   $0x801870
  8010a2:	e8 a9 f0 ff ff       	call   800150 <_panic>

	// Mark child environment as runnable
	if ((r = sys_env_set_status(child_envid, ENV_RUNNABLE)) < 0)
  8010a7:	83 ec 08             	sub    $0x8,%esp
  8010aa:	6a 02                	push   $0x2
  8010ac:	ff 75 dc             	pushl  -0x24(%ebp)
  8010af:	e8 43 fc ff ff       	call   800cf7 <sys_env_set_status>
  8010b4:	83 c4 10             	add    $0x10,%esp
  8010b7:	85 c0                	test   %eax,%eax
  8010b9:	79 15                	jns    8010d0 <fork+0x231>
		panic("sys_env_set_status: %e\n", r);
  8010bb:	50                   	push   %eax
  8010bc:	68 b2 18 80 00       	push   $0x8018b2
  8010c1:	68 a0 00 00 00       	push   $0xa0
  8010c6:	68 70 18 80 00       	push   $0x801870
  8010cb:	e8 80 f0 ff ff       	call   800150 <_panic>

	return child_envid;
  8010d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  8010d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8010d6:	5b                   	pop    %ebx
  8010d7:	5e                   	pop    %esi
  8010d8:	5f                   	pop    %edi
  8010d9:	5d                   	pop    %ebp
  8010da:	c3                   	ret    

008010db <sfork>:

// Challenge!
int
sfork(void)
{
  8010db:	55                   	push   %ebp
  8010dc:	89 e5                	mov    %esp,%ebp
  8010de:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  8010e1:	68 ca 18 80 00       	push   $0x8018ca
  8010e6:	68 a9 00 00 00       	push   $0xa9
  8010eb:	68 70 18 80 00       	push   $0x801870
  8010f0:	e8 5b f0 ff ff       	call   800150 <_panic>

008010f5 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  8010f5:	55                   	push   %ebp
  8010f6:	89 e5                	mov    %esp,%ebp
  8010f8:	56                   	push   %esi
  8010f9:	53                   	push   %ebx
  8010fa:	8b 75 08             	mov    0x8(%ebp),%esi
  8010fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  801100:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.

	int r;
	if (pg == NULL)
  801103:	85 c0                	test   %eax,%eax
		pg = (void *) KERNBASE; // KERNBASE should be rejected by sys_ipc_recv()
  801105:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
  80110a:	0f 44 c2             	cmove  %edx,%eax

	if ((r = sys_ipc_recv(pg)) != 0) {
  80110d:	83 ec 0c             	sub    $0xc,%esp
  801110:	50                   	push   %eax
  801111:	e8 88 fc ff ff       	call   800d9e <sys_ipc_recv>
  801116:	83 c4 10             	add    $0x10,%esp
  801119:	85 c0                	test   %eax,%eax
  80111b:	74 16                	je     801133 <ipc_recv+0x3e>
		if (from_env_store != NULL)
  80111d:	85 f6                	test   %esi,%esi
  80111f:	74 06                	je     801127 <ipc_recv+0x32>
			*from_env_store = 0;
  801121:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (perm_store != NULL)
  801127:	85 db                	test   %ebx,%ebx
  801129:	74 2c                	je     801157 <ipc_recv+0x62>
			*perm_store = 0;
  80112b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  801131:	eb 24                	jmp    801157 <ipc_recv+0x62>
		return r;
	}

	if (from_env_store != NULL)
  801133:	85 f6                	test   %esi,%esi
  801135:	74 0a                	je     801141 <ipc_recv+0x4c>
		*from_env_store = thisenv->env_ipc_from;
  801137:	a1 04 20 80 00       	mov    0x802004,%eax
  80113c:	8b 40 74             	mov    0x74(%eax),%eax
  80113f:	89 06                	mov    %eax,(%esi)
	if (perm_store != NULL)
  801141:	85 db                	test   %ebx,%ebx
  801143:	74 0a                	je     80114f <ipc_recv+0x5a>
		*perm_store = thisenv->env_ipc_perm;
  801145:	a1 04 20 80 00       	mov    0x802004,%eax
  80114a:	8b 40 78             	mov    0x78(%eax),%eax
  80114d:	89 03                	mov    %eax,(%ebx)

return thisenv->env_ipc_value;
  80114f:	a1 04 20 80 00       	mov    0x802004,%eax
  801154:	8b 40 70             	mov    0x70(%eax),%eax
	return 0;
}
  801157:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80115a:	5b                   	pop    %ebx
  80115b:	5e                   	pop    %esi
  80115c:	5d                   	pop    %ebp
  80115d:	c3                   	ret    

0080115e <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80115e:	55                   	push   %ebp
  80115f:	89 e5                	mov    %esp,%ebp
  801161:	57                   	push   %edi
  801162:	56                   	push   %esi
  801163:	53                   	push   %ebx
  801164:	83 ec 0c             	sub    $0xc,%esp
  801167:	8b 75 0c             	mov    0xc(%ebp),%esi
  80116a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80116d:	8b 7d 14             	mov    0x14(%ebp),%edi
	// LAB 4: Your code here.
	if (pg == NULL)
		pg = (void *) KERNBASE;
  801170:	85 db                	test   %ebx,%ebx
  801172:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  801177:	0f 44 d8             	cmove  %eax,%ebx

	int r = sys_ipc_try_send(to_env, val, pg, perm);
  80117a:	57                   	push   %edi
  80117b:	53                   	push   %ebx
  80117c:	56                   	push   %esi
  80117d:	ff 75 08             	pushl  0x8(%ebp)
  801180:	e8 f6 fb ff ff       	call   800d7b <sys_ipc_try_send>

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  801185:	83 c4 10             	add    $0x10,%esp
  801188:	eb 17                	jmp    8011a1 <ipc_send+0x43>
		if (r == 0)
  80118a:	85 c0                	test   %eax,%eax
  80118c:	74 2e                	je     8011bc <ipc_send+0x5e>
			return;

		sys_yield(); // release CPU before attempting to send again
  80118e:	e8 7e fa ff ff       	call   800c11 <sys_yield>

		r = sys_ipc_try_send(to_env, val, pg, perm);
  801193:	57                   	push   %edi
  801194:	53                   	push   %ebx
  801195:	56                   	push   %esi
  801196:	ff 75 08             	pushl  0x8(%ebp)
  801199:	e8 dd fb ff ff       	call   800d7b <sys_ipc_try_send>
  80119e:	83 c4 10             	add    $0x10,%esp
	if (pg == NULL)
		pg = (void *) KERNBASE;

	int r = sys_ipc_try_send(to_env, val, pg, perm);

	while ((r == -E_IPC_NOT_RECV) || (r == 0)) {
  8011a1:	83 f8 f9             	cmp    $0xfffffff9,%eax
  8011a4:	74 e4                	je     80118a <ipc_send+0x2c>
  8011a6:	85 c0                	test   %eax,%eax
  8011a8:	74 e0                	je     80118a <ipc_send+0x2c>
		sys_yield(); // release CPU before attempting to send again

		r = sys_ipc_try_send(to_env, val, pg, perm);
	}

panic("ipc_send: %e\n", r);
  8011aa:	50                   	push   %eax
  8011ab:	68 e0 18 80 00       	push   $0x8018e0
  8011b0:	6a 4a                	push   $0x4a
  8011b2:	68 ee 18 80 00       	push   $0x8018ee
  8011b7:	e8 94 ef ff ff       	call   800150 <_panic>
}
  8011bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011bf:	5b                   	pop    %ebx
  8011c0:	5e                   	pop    %esi
  8011c1:	5f                   	pop    %edi
  8011c2:	5d                   	pop    %ebp
  8011c3:	c3                   	ret    

008011c4 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  8011c4:	55                   	push   %ebp
  8011c5:	89 e5                	mov    %esp,%ebp
  8011c7:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  8011ca:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  8011cf:	6b d0 7c             	imul   $0x7c,%eax,%edx
  8011d2:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  8011d8:	8b 52 50             	mov    0x50(%edx),%edx
  8011db:	39 ca                	cmp    %ecx,%edx
  8011dd:	75 0d                	jne    8011ec <ipc_find_env+0x28>
			return envs[i].env_id;
  8011df:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8011e2:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8011e7:	8b 40 48             	mov    0x48(%eax),%eax
  8011ea:	eb 0f                	jmp    8011fb <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8011ec:	83 c0 01             	add    $0x1,%eax
  8011ef:	3d 00 04 00 00       	cmp    $0x400,%eax
  8011f4:	75 d9                	jne    8011cf <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  8011f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8011fb:	5d                   	pop    %ebp
  8011fc:	c3                   	ret    

008011fd <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8011fd:	55                   	push   %ebp
  8011fe:	89 e5                	mov    %esp,%ebp
  801200:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  801203:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  80120a:	75 3c                	jne    801248 <set_pgfault_handler+0x4b>
		
		if ((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE),PTE_U|PTE_P|PTE_W)) < 0)
  80120c:	83 ec 04             	sub    $0x4,%esp
  80120f:	6a 07                	push   $0x7
  801211:	68 00 f0 bf ee       	push   $0xeebff000
  801216:	6a 00                	push   $0x0
  801218:	e8 13 fa ff ff       	call   800c30 <sys_page_alloc>
  80121d:	83 c4 10             	add    $0x10,%esp
  801220:	85 c0                	test   %eax,%eax
  801222:	79 12                	jns    801236 <set_pgfault_handler+0x39>
		panic("sys_page_alloc: %e", r);
  801224:	50                   	push   %eax
  801225:	68 f8 18 80 00       	push   $0x8018f8
  80122a:	6a 20                	push   $0x20
  80122c:	68 0b 19 80 00       	push   $0x80190b
  801231:	e8 1a ef ff ff       	call   800150 <_panic>
	    sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  801236:	83 ec 08             	sub    $0x8,%esp
  801239:	68 52 12 80 00       	push   $0x801252
  80123e:	6a 00                	push   $0x0
  801240:	e8 f4 fa ff ff       	call   800d39 <sys_env_set_pgfault_upcall>
  801245:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801248:	8b 45 08             	mov    0x8(%ebp),%eax
  80124b:	a3 08 20 80 00       	mov    %eax,0x802008
}
  801250:	c9                   	leave  
  801251:	c3                   	ret    

00801252 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801252:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801253:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  801258:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80125a:	83 c4 04             	add    $0x4,%esp
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
    
    //trap time eip
	movl 0x28(%esp), %eax
  80125d:	8b 44 24 28          	mov    0x28(%esp),%eax

	//current stack we need it afterwards to pop registers al
	movl %esp, %ebp
  801261:	89 e5                	mov    %esp,%ebp

	//switch to user stack where faulitng va occured
	movl 0x30(%esp), %esp
  801263:	8b 64 24 30          	mov    0x30(%esp),%esp

	// Push trap-time eip to the user stack 
	pushl %eax
  801267:	50                   	push   %eax

	// SAve the user stack esp again for latter use after popping general purpose registers
	movl %esp, 0x30(%ebp)
  801268:	89 65 30             	mov    %esp,0x30(%ebp)

	// Now again go to the user trap frame
	movl %ebp, %esp
  80126b:	89 ec                	mov    %ebp,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	
	// ignore faut  va and err	
	addl $8, %esp
  80126d:	83 c4 08             	add    $0x8,%esp

	// Pop all registers back
	popal
  801270:	61                   	popa   
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

	// Skip %eip
	addl $0x4, %esp
  801271:	83 c4 04             	add    $0x4,%esp

	// Pop eflags back
	popfl
  801274:	9d                   	popf   

	// Go to user stack now
	// LAB 4: Your code here.

	popl %esp
  801275:	5c                   	pop    %esp


	// LAB 4: Your code here.

	ret
  801276:	c3                   	ret    
  801277:	66 90                	xchg   %ax,%ax
  801279:	66 90                	xchg   %ax,%ax
  80127b:	66 90                	xchg   %ax,%ax
  80127d:	66 90                	xchg   %ax,%ax
  80127f:	90                   	nop

00801280 <__udivdi3>:
  801280:	55                   	push   %ebp
  801281:	57                   	push   %edi
  801282:	56                   	push   %esi
  801283:	53                   	push   %ebx
  801284:	83 ec 1c             	sub    $0x1c,%esp
  801287:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80128b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80128f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801293:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801297:	85 f6                	test   %esi,%esi
  801299:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80129d:	89 ca                	mov    %ecx,%edx
  80129f:	89 f8                	mov    %edi,%eax
  8012a1:	75 3d                	jne    8012e0 <__udivdi3+0x60>
  8012a3:	39 cf                	cmp    %ecx,%edi
  8012a5:	0f 87 c5 00 00 00    	ja     801370 <__udivdi3+0xf0>
  8012ab:	85 ff                	test   %edi,%edi
  8012ad:	89 fd                	mov    %edi,%ebp
  8012af:	75 0b                	jne    8012bc <__udivdi3+0x3c>
  8012b1:	b8 01 00 00 00       	mov    $0x1,%eax
  8012b6:	31 d2                	xor    %edx,%edx
  8012b8:	f7 f7                	div    %edi
  8012ba:	89 c5                	mov    %eax,%ebp
  8012bc:	89 c8                	mov    %ecx,%eax
  8012be:	31 d2                	xor    %edx,%edx
  8012c0:	f7 f5                	div    %ebp
  8012c2:	89 c1                	mov    %eax,%ecx
  8012c4:	89 d8                	mov    %ebx,%eax
  8012c6:	89 cf                	mov    %ecx,%edi
  8012c8:	f7 f5                	div    %ebp
  8012ca:	89 c3                	mov    %eax,%ebx
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
  8012e0:	39 ce                	cmp    %ecx,%esi
  8012e2:	77 74                	ja     801358 <__udivdi3+0xd8>
  8012e4:	0f bd fe             	bsr    %esi,%edi
  8012e7:	83 f7 1f             	xor    $0x1f,%edi
  8012ea:	0f 84 98 00 00 00    	je     801388 <__udivdi3+0x108>
  8012f0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8012f5:	89 f9                	mov    %edi,%ecx
  8012f7:	89 c5                	mov    %eax,%ebp
  8012f9:	29 fb                	sub    %edi,%ebx
  8012fb:	d3 e6                	shl    %cl,%esi
  8012fd:	89 d9                	mov    %ebx,%ecx
  8012ff:	d3 ed                	shr    %cl,%ebp
  801301:	89 f9                	mov    %edi,%ecx
  801303:	d3 e0                	shl    %cl,%eax
  801305:	09 ee                	or     %ebp,%esi
  801307:	89 d9                	mov    %ebx,%ecx
  801309:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80130d:	89 d5                	mov    %edx,%ebp
  80130f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801313:	d3 ed                	shr    %cl,%ebp
  801315:	89 f9                	mov    %edi,%ecx
  801317:	d3 e2                	shl    %cl,%edx
  801319:	89 d9                	mov    %ebx,%ecx
  80131b:	d3 e8                	shr    %cl,%eax
  80131d:	09 c2                	or     %eax,%edx
  80131f:	89 d0                	mov    %edx,%eax
  801321:	89 ea                	mov    %ebp,%edx
  801323:	f7 f6                	div    %esi
  801325:	89 d5                	mov    %edx,%ebp
  801327:	89 c3                	mov    %eax,%ebx
  801329:	f7 64 24 0c          	mull   0xc(%esp)
  80132d:	39 d5                	cmp    %edx,%ebp
  80132f:	72 10                	jb     801341 <__udivdi3+0xc1>
  801331:	8b 74 24 08          	mov    0x8(%esp),%esi
  801335:	89 f9                	mov    %edi,%ecx
  801337:	d3 e6                	shl    %cl,%esi
  801339:	39 c6                	cmp    %eax,%esi
  80133b:	73 07                	jae    801344 <__udivdi3+0xc4>
  80133d:	39 d5                	cmp    %edx,%ebp
  80133f:	75 03                	jne    801344 <__udivdi3+0xc4>
  801341:	83 eb 01             	sub    $0x1,%ebx
  801344:	31 ff                	xor    %edi,%edi
  801346:	89 d8                	mov    %ebx,%eax
  801348:	89 fa                	mov    %edi,%edx
  80134a:	83 c4 1c             	add    $0x1c,%esp
  80134d:	5b                   	pop    %ebx
  80134e:	5e                   	pop    %esi
  80134f:	5f                   	pop    %edi
  801350:	5d                   	pop    %ebp
  801351:	c3                   	ret    
  801352:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801358:	31 ff                	xor    %edi,%edi
  80135a:	31 db                	xor    %ebx,%ebx
  80135c:	89 d8                	mov    %ebx,%eax
  80135e:	89 fa                	mov    %edi,%edx
  801360:	83 c4 1c             	add    $0x1c,%esp
  801363:	5b                   	pop    %ebx
  801364:	5e                   	pop    %esi
  801365:	5f                   	pop    %edi
  801366:	5d                   	pop    %ebp
  801367:	c3                   	ret    
  801368:	90                   	nop
  801369:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801370:	89 d8                	mov    %ebx,%eax
  801372:	f7 f7                	div    %edi
  801374:	31 ff                	xor    %edi,%edi
  801376:	89 c3                	mov    %eax,%ebx
  801378:	89 d8                	mov    %ebx,%eax
  80137a:	89 fa                	mov    %edi,%edx
  80137c:	83 c4 1c             	add    $0x1c,%esp
  80137f:	5b                   	pop    %ebx
  801380:	5e                   	pop    %esi
  801381:	5f                   	pop    %edi
  801382:	5d                   	pop    %ebp
  801383:	c3                   	ret    
  801384:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801388:	39 ce                	cmp    %ecx,%esi
  80138a:	72 0c                	jb     801398 <__udivdi3+0x118>
  80138c:	31 db                	xor    %ebx,%ebx
  80138e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801392:	0f 87 34 ff ff ff    	ja     8012cc <__udivdi3+0x4c>
  801398:	bb 01 00 00 00       	mov    $0x1,%ebx
  80139d:	e9 2a ff ff ff       	jmp    8012cc <__udivdi3+0x4c>
  8013a2:	66 90                	xchg   %ax,%ax
  8013a4:	66 90                	xchg   %ax,%ax
  8013a6:	66 90                	xchg   %ax,%ax
  8013a8:	66 90                	xchg   %ax,%ax
  8013aa:	66 90                	xchg   %ax,%ax
  8013ac:	66 90                	xchg   %ax,%ax
  8013ae:	66 90                	xchg   %ax,%ax

008013b0 <__umoddi3>:
  8013b0:	55                   	push   %ebp
  8013b1:	57                   	push   %edi
  8013b2:	56                   	push   %esi
  8013b3:	53                   	push   %ebx
  8013b4:	83 ec 1c             	sub    $0x1c,%esp
  8013b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  8013bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8013bf:	8b 74 24 34          	mov    0x34(%esp),%esi
  8013c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8013c7:	85 d2                	test   %edx,%edx
  8013c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8013cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8013d1:	89 f3                	mov    %esi,%ebx
  8013d3:	89 3c 24             	mov    %edi,(%esp)
  8013d6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8013da:	75 1c                	jne    8013f8 <__umoddi3+0x48>
  8013dc:	39 f7                	cmp    %esi,%edi
  8013de:	76 50                	jbe    801430 <__umoddi3+0x80>
  8013e0:	89 c8                	mov    %ecx,%eax
  8013e2:	89 f2                	mov    %esi,%edx
  8013e4:	f7 f7                	div    %edi
  8013e6:	89 d0                	mov    %edx,%eax
  8013e8:	31 d2                	xor    %edx,%edx
  8013ea:	83 c4 1c             	add    $0x1c,%esp
  8013ed:	5b                   	pop    %ebx
  8013ee:	5e                   	pop    %esi
  8013ef:	5f                   	pop    %edi
  8013f0:	5d                   	pop    %ebp
  8013f1:	c3                   	ret    
  8013f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013f8:	39 f2                	cmp    %esi,%edx
  8013fa:	89 d0                	mov    %edx,%eax
  8013fc:	77 52                	ja     801450 <__umoddi3+0xa0>
  8013fe:	0f bd ea             	bsr    %edx,%ebp
  801401:	83 f5 1f             	xor    $0x1f,%ebp
  801404:	75 5a                	jne    801460 <__umoddi3+0xb0>
  801406:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80140a:	0f 82 e0 00 00 00    	jb     8014f0 <__umoddi3+0x140>
  801410:	39 0c 24             	cmp    %ecx,(%esp)
  801413:	0f 86 d7 00 00 00    	jbe    8014f0 <__umoddi3+0x140>
  801419:	8b 44 24 08          	mov    0x8(%esp),%eax
  80141d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801421:	83 c4 1c             	add    $0x1c,%esp
  801424:	5b                   	pop    %ebx
  801425:	5e                   	pop    %esi
  801426:	5f                   	pop    %edi
  801427:	5d                   	pop    %ebp
  801428:	c3                   	ret    
  801429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801430:	85 ff                	test   %edi,%edi
  801432:	89 fd                	mov    %edi,%ebp
  801434:	75 0b                	jne    801441 <__umoddi3+0x91>
  801436:	b8 01 00 00 00       	mov    $0x1,%eax
  80143b:	31 d2                	xor    %edx,%edx
  80143d:	f7 f7                	div    %edi
  80143f:	89 c5                	mov    %eax,%ebp
  801441:	89 f0                	mov    %esi,%eax
  801443:	31 d2                	xor    %edx,%edx
  801445:	f7 f5                	div    %ebp
  801447:	89 c8                	mov    %ecx,%eax
  801449:	f7 f5                	div    %ebp
  80144b:	89 d0                	mov    %edx,%eax
  80144d:	eb 99                	jmp    8013e8 <__umoddi3+0x38>
  80144f:	90                   	nop
  801450:	89 c8                	mov    %ecx,%eax
  801452:	89 f2                	mov    %esi,%edx
  801454:	83 c4 1c             	add    $0x1c,%esp
  801457:	5b                   	pop    %ebx
  801458:	5e                   	pop    %esi
  801459:	5f                   	pop    %edi
  80145a:	5d                   	pop    %ebp
  80145b:	c3                   	ret    
  80145c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801460:	8b 34 24             	mov    (%esp),%esi
  801463:	bf 20 00 00 00       	mov    $0x20,%edi
  801468:	89 e9                	mov    %ebp,%ecx
  80146a:	29 ef                	sub    %ebp,%edi
  80146c:	d3 e0                	shl    %cl,%eax
  80146e:	89 f9                	mov    %edi,%ecx
  801470:	89 f2                	mov    %esi,%edx
  801472:	d3 ea                	shr    %cl,%edx
  801474:	89 e9                	mov    %ebp,%ecx
  801476:	09 c2                	or     %eax,%edx
  801478:	89 d8                	mov    %ebx,%eax
  80147a:	89 14 24             	mov    %edx,(%esp)
  80147d:	89 f2                	mov    %esi,%edx
  80147f:	d3 e2                	shl    %cl,%edx
  801481:	89 f9                	mov    %edi,%ecx
  801483:	89 54 24 04          	mov    %edx,0x4(%esp)
  801487:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80148b:	d3 e8                	shr    %cl,%eax
  80148d:	89 e9                	mov    %ebp,%ecx
  80148f:	89 c6                	mov    %eax,%esi
  801491:	d3 e3                	shl    %cl,%ebx
  801493:	89 f9                	mov    %edi,%ecx
  801495:	89 d0                	mov    %edx,%eax
  801497:	d3 e8                	shr    %cl,%eax
  801499:	89 e9                	mov    %ebp,%ecx
  80149b:	09 d8                	or     %ebx,%eax
  80149d:	89 d3                	mov    %edx,%ebx
  80149f:	89 f2                	mov    %esi,%edx
  8014a1:	f7 34 24             	divl   (%esp)
  8014a4:	89 d6                	mov    %edx,%esi
  8014a6:	d3 e3                	shl    %cl,%ebx
  8014a8:	f7 64 24 04          	mull   0x4(%esp)
  8014ac:	39 d6                	cmp    %edx,%esi
  8014ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8014b2:	89 d1                	mov    %edx,%ecx
  8014b4:	89 c3                	mov    %eax,%ebx
  8014b6:	72 08                	jb     8014c0 <__umoddi3+0x110>
  8014b8:	75 11                	jne    8014cb <__umoddi3+0x11b>
  8014ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  8014be:	73 0b                	jae    8014cb <__umoddi3+0x11b>
  8014c0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8014c4:	1b 14 24             	sbb    (%esp),%edx
  8014c7:	89 d1                	mov    %edx,%ecx
  8014c9:	89 c3                	mov    %eax,%ebx
  8014cb:	8b 54 24 08          	mov    0x8(%esp),%edx
  8014cf:	29 da                	sub    %ebx,%edx
  8014d1:	19 ce                	sbb    %ecx,%esi
  8014d3:	89 f9                	mov    %edi,%ecx
  8014d5:	89 f0                	mov    %esi,%eax
  8014d7:	d3 e0                	shl    %cl,%eax
  8014d9:	89 e9                	mov    %ebp,%ecx
  8014db:	d3 ea                	shr    %cl,%edx
  8014dd:	89 e9                	mov    %ebp,%ecx
  8014df:	d3 ee                	shr    %cl,%esi
  8014e1:	09 d0                	or     %edx,%eax
  8014e3:	89 f2                	mov    %esi,%edx
  8014e5:	83 c4 1c             	add    $0x1c,%esp
  8014e8:	5b                   	pop    %ebx
  8014e9:	5e                   	pop    %esi
  8014ea:	5f                   	pop    %edi
  8014eb:	5d                   	pop    %ebp
  8014ec:	c3                   	ret    
  8014ed:	8d 76 00             	lea    0x0(%esi),%esi
  8014f0:	29 f9                	sub    %edi,%ecx
  8014f2:	19 d6                	sbb    %edx,%esi
  8014f4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014fc:	e9 18 ff ff ff       	jmp    801419 <__umoddi3+0x69>
