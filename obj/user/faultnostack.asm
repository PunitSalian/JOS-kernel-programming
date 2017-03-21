
obj/user/faultnostack:     file format elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	68 17 03 80 00       	push   $0x800317
  80003e:	6a 00                	push   $0x0
  800040:	e8 2c 02 00 00       	call   800271 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800045:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80004c:	00 00 00 
}
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	56                   	push   %esi
  800058:	53                   	push   %ebx
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  80005f:	e8 c6 00 00 00       	call   80012a <sys_getenvid>
  800064:	25 ff 03 00 00       	and    $0x3ff,%eax
  800069:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800071:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 db                	test   %ebx,%ebx
  800078:	7e 07                	jle    800081 <libmain+0x2d>
		binaryname = argv[0];
  80007a:	8b 06                	mov    (%esi),%eax
  80007c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	83 ec 08             	sub    $0x8,%esp
  800084:	56                   	push   %esi
  800085:	53                   	push   %ebx
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 0a 00 00 00       	call   80009a <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800096:	5b                   	pop    %ebx
  800097:	5e                   	pop    %esi
  800098:	5d                   	pop    %ebp
  800099:	c3                   	ret    

0080009a <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a0:	6a 00                	push   $0x0
  8000a2:	e8 42 00 00 00       	call   8000e9 <sys_env_destroy>
}
  8000a7:	83 c4 10             	add    $0x10,%esp
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bd:	89 c3                	mov    %eax,%ebx
  8000bf:	89 c7                	mov    %eax,%edi
  8000c1:	89 c6                	mov    %eax,%esi
  8000c3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c5:	5b                   	pop    %ebx
  8000c6:	5e                   	pop    %esi
  8000c7:	5f                   	pop    %edi
  8000c8:	5d                   	pop    %ebp
  8000c9:	c3                   	ret    

008000ca <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ca:	55                   	push   %ebp
  8000cb:	89 e5                	mov    %esp,%ebp
  8000cd:	57                   	push   %edi
  8000ce:	56                   	push   %esi
  8000cf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d5:	b8 01 00 00 00       	mov    $0x1,%eax
  8000da:	89 d1                	mov    %edx,%ecx
  8000dc:	89 d3                	mov    %edx,%ebx
  8000de:	89 d7                	mov    %edx,%edi
  8000e0:	89 d6                	mov    %edx,%esi
  8000e2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e4:	5b                   	pop    %ebx
  8000e5:	5e                   	pop    %esi
  8000e6:	5f                   	pop    %edi
  8000e7:	5d                   	pop    %ebp
  8000e8:	c3                   	ret    

008000e9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e9:	55                   	push   %ebp
  8000ea:	89 e5                	mov    %esp,%ebp
  8000ec:	57                   	push   %edi
  8000ed:	56                   	push   %esi
  8000ee:	53                   	push   %ebx
  8000ef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f7:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	89 cb                	mov    %ecx,%ebx
  800101:	89 cf                	mov    %ecx,%edi
  800103:	89 ce                	mov    %ecx,%esi
  800105:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800107:	85 c0                	test   %eax,%eax
  800109:	7e 17                	jle    800122 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010b:	83 ec 0c             	sub    $0xc,%esp
  80010e:	50                   	push   %eax
  80010f:	6a 03                	push   $0x3
  800111:	68 6a 10 80 00       	push   $0x80106a
  800116:	6a 23                	push   $0x23
  800118:	68 87 10 80 00       	push   $0x801087
  80011d:	e8 1a 02 00 00       	call   80033c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800122:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800125:	5b                   	pop    %ebx
  800126:	5e                   	pop    %esi
  800127:	5f                   	pop    %edi
  800128:	5d                   	pop    %ebp
  800129:	c3                   	ret    

0080012a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	57                   	push   %edi
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800130:	ba 00 00 00 00       	mov    $0x0,%edx
  800135:	b8 02 00 00 00       	mov    $0x2,%eax
  80013a:	89 d1                	mov    %edx,%ecx
  80013c:	89 d3                	mov    %edx,%ebx
  80013e:	89 d7                	mov    %edx,%edi
  800140:	89 d6                	mov    %edx,%esi
  800142:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    

00800149 <sys_yield>:

void
sys_yield(void)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	57                   	push   %edi
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 0a 00 00 00       	mov    $0xa,%eax
  800159:	89 d1                	mov    %edx,%ecx
  80015b:	89 d3                	mov    %edx,%ebx
  80015d:	89 d7                	mov    %edx,%edi
  80015f:	89 d6                	mov    %edx,%esi
  800161:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800163:	5b                   	pop    %ebx
  800164:	5e                   	pop    %esi
  800165:	5f                   	pop    %edi
  800166:	5d                   	pop    %ebp
  800167:	c3                   	ret    

00800168 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	57                   	push   %edi
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
  80016e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800171:	be 00 00 00 00       	mov    $0x0,%esi
  800176:	b8 04 00 00 00       	mov    $0x4,%eax
  80017b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80017e:	8b 55 08             	mov    0x8(%ebp),%edx
  800181:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800184:	89 f7                	mov    %esi,%edi
  800186:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800188:	85 c0                	test   %eax,%eax
  80018a:	7e 17                	jle    8001a3 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80018c:	83 ec 0c             	sub    $0xc,%esp
  80018f:	50                   	push   %eax
  800190:	6a 04                	push   $0x4
  800192:	68 6a 10 80 00       	push   $0x80106a
  800197:	6a 23                	push   $0x23
  800199:	68 87 10 80 00       	push   $0x801087
  80019e:	e8 99 01 00 00       	call   80033c <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001a6:	5b                   	pop    %ebx
  8001a7:	5e                   	pop    %esi
  8001a8:	5f                   	pop    %edi
  8001a9:	5d                   	pop    %ebp
  8001aa:	c3                   	ret    

008001ab <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	57                   	push   %edi
  8001af:	56                   	push   %esi
  8001b0:	53                   	push   %ebx
  8001b1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001c5:	8b 75 18             	mov    0x18(%ebp),%esi
  8001c8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8001ca:	85 c0                	test   %eax,%eax
  8001cc:	7e 17                	jle    8001e5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001ce:	83 ec 0c             	sub    $0xc,%esp
  8001d1:	50                   	push   %eax
  8001d2:	6a 05                	push   $0x5
  8001d4:	68 6a 10 80 00       	push   $0x80106a
  8001d9:	6a 23                	push   $0x23
  8001db:	68 87 10 80 00       	push   $0x801087
  8001e0:	e8 57 01 00 00       	call   80033c <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e8:	5b                   	pop    %ebx
  8001e9:	5e                   	pop    %esi
  8001ea:	5f                   	pop    %edi
  8001eb:	5d                   	pop    %ebp
  8001ec:	c3                   	ret    

008001ed <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001ed:	55                   	push   %ebp
  8001ee:	89 e5                	mov    %esp,%ebp
  8001f0:	57                   	push   %edi
  8001f1:	56                   	push   %esi
  8001f2:	53                   	push   %ebx
  8001f3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001fb:	b8 06 00 00 00       	mov    $0x6,%eax
  800200:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	89 df                	mov    %ebx,%edi
  800208:	89 de                	mov    %ebx,%esi
  80020a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80020c:	85 c0                	test   %eax,%eax
  80020e:	7e 17                	jle    800227 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800210:	83 ec 0c             	sub    $0xc,%esp
  800213:	50                   	push   %eax
  800214:	6a 06                	push   $0x6
  800216:	68 6a 10 80 00       	push   $0x80106a
  80021b:	6a 23                	push   $0x23
  80021d:	68 87 10 80 00       	push   $0x801087
  800222:	e8 15 01 00 00       	call   80033c <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800227:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022a:	5b                   	pop    %ebx
  80022b:	5e                   	pop    %esi
  80022c:	5f                   	pop    %edi
  80022d:	5d                   	pop    %ebp
  80022e:	c3                   	ret    

0080022f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	b8 08 00 00 00       	mov    $0x8,%eax
  800242:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800245:	8b 55 08             	mov    0x8(%ebp),%edx
  800248:	89 df                	mov    %ebx,%edi
  80024a:	89 de                	mov    %ebx,%esi
  80024c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80024e:	85 c0                	test   %eax,%eax
  800250:	7e 17                	jle    800269 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800252:	83 ec 0c             	sub    $0xc,%esp
  800255:	50                   	push   %eax
  800256:	6a 08                	push   $0x8
  800258:	68 6a 10 80 00       	push   $0x80106a
  80025d:	6a 23                	push   $0x23
  80025f:	68 87 10 80 00       	push   $0x801087
  800264:	e8 d3 00 00 00       	call   80033c <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800269:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80026c:	5b                   	pop    %ebx
  80026d:	5e                   	pop    %esi
  80026e:	5f                   	pop    %edi
  80026f:	5d                   	pop    %ebp
  800270:	c3                   	ret    

00800271 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800271:	55                   	push   %ebp
  800272:	89 e5                	mov    %esp,%ebp
  800274:	57                   	push   %edi
  800275:	56                   	push   %esi
  800276:	53                   	push   %ebx
  800277:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80027a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027f:	b8 09 00 00 00       	mov    $0x9,%eax
  800284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800287:	8b 55 08             	mov    0x8(%ebp),%edx
  80028a:	89 df                	mov    %ebx,%edi
  80028c:	89 de                	mov    %ebx,%esi
  80028e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800290:	85 c0                	test   %eax,%eax
  800292:	7e 17                	jle    8002ab <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800294:	83 ec 0c             	sub    $0xc,%esp
  800297:	50                   	push   %eax
  800298:	6a 09                	push   $0x9
  80029a:	68 6a 10 80 00       	push   $0x80106a
  80029f:	6a 23                	push   $0x23
  8002a1:	68 87 10 80 00       	push   $0x801087
  8002a6:	e8 91 00 00 00       	call   80033c <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ae:	5b                   	pop    %ebx
  8002af:	5e                   	pop    %esi
  8002b0:	5f                   	pop    %edi
  8002b1:	5d                   	pop    %ebp
  8002b2:	c3                   	ret    

008002b3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	be 00 00 00 00       	mov    $0x0,%esi
  8002be:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002cc:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002cf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002d1:	5b                   	pop    %ebx
  8002d2:	5e                   	pop    %esi
  8002d3:	5f                   	pop    %edi
  8002d4:	5d                   	pop    %ebp
  8002d5:	c3                   	ret    

008002d6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	57                   	push   %edi
  8002da:	56                   	push   %esi
  8002db:	53                   	push   %ebx
  8002dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002e4:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ec:	89 cb                	mov    %ecx,%ebx
  8002ee:	89 cf                	mov    %ecx,%edi
  8002f0:	89 ce                	mov    %ecx,%esi
  8002f2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	7e 17                	jle    80030f <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002f8:	83 ec 0c             	sub    $0xc,%esp
  8002fb:	50                   	push   %eax
  8002fc:	6a 0c                	push   $0xc
  8002fe:	68 6a 10 80 00       	push   $0x80106a
  800303:	6a 23                	push   $0x23
  800305:	68 87 10 80 00       	push   $0x801087
  80030a:	e8 2d 00 00 00       	call   80033c <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80030f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800312:	5b                   	pop    %ebx
  800313:	5e                   	pop    %esi
  800314:	5f                   	pop    %edi
  800315:	5d                   	pop    %ebp
  800316:	c3                   	ret    

00800317 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800317:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800318:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80031d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80031f:	83 c4 04             	add    $0x4,%esp
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
    
    //trap time eip
	movl 0x28(%esp), %eax
  800322:	8b 44 24 28          	mov    0x28(%esp),%eax

	//current stack we need it afterwards to pop registers al
	movl %esp, %ebp
  800326:	89 e5                	mov    %esp,%ebp

	//switch to user stack where faulitng va occured
	movl 0x30(%esp), %esp
  800328:	8b 64 24 30          	mov    0x30(%esp),%esp

	// Push trap-time eip to the user stack 
	pushl %eax
  80032c:	50                   	push   %eax

	// SAve the user stack esp again for latter use after popping general purpose registers
	movl %esp, 0x30(%ebp)
  80032d:	89 65 30             	mov    %esp,0x30(%ebp)

	// Now again go to the user trap frame
	movl %ebp, %esp
  800330:	89 ec                	mov    %ebp,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	
	// ignore faut  va and err	
	addl $8, %esp
  800332:	83 c4 08             	add    $0x8,%esp

	// Pop all registers back
	popal
  800335:	61                   	popa   
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

	// Skip %eip
	addl $0x4, %esp
  800336:	83 c4 04             	add    $0x4,%esp

	// Pop eflags back
	popfl
  800339:	9d                   	popf   

	// Go to user stack now
	// LAB 4: Your code here.

	popl %esp
  80033a:	5c                   	pop    %esp


	// LAB 4: Your code here.

	ret
  80033b:	c3                   	ret    

0080033c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80033c:	55                   	push   %ebp
  80033d:	89 e5                	mov    %esp,%ebp
  80033f:	56                   	push   %esi
  800340:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800341:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800344:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80034a:	e8 db fd ff ff       	call   80012a <sys_getenvid>
  80034f:	83 ec 0c             	sub    $0xc,%esp
  800352:	ff 75 0c             	pushl  0xc(%ebp)
  800355:	ff 75 08             	pushl  0x8(%ebp)
  800358:	56                   	push   %esi
  800359:	50                   	push   %eax
  80035a:	68 98 10 80 00       	push   $0x801098
  80035f:	e8 b1 00 00 00       	call   800415 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800364:	83 c4 18             	add    $0x18,%esp
  800367:	53                   	push   %ebx
  800368:	ff 75 10             	pushl  0x10(%ebp)
  80036b:	e8 54 00 00 00       	call   8003c4 <vcprintf>
	cprintf("\n");
  800370:	c7 04 24 bc 10 80 00 	movl   $0x8010bc,(%esp)
  800377:	e8 99 00 00 00       	call   800415 <cprintf>
  80037c:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80037f:	cc                   	int3   
  800380:	eb fd                	jmp    80037f <_panic+0x43>

00800382 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800382:	55                   	push   %ebp
  800383:	89 e5                	mov    %esp,%ebp
  800385:	53                   	push   %ebx
  800386:	83 ec 04             	sub    $0x4,%esp
  800389:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80038c:	8b 13                	mov    (%ebx),%edx
  80038e:	8d 42 01             	lea    0x1(%edx),%eax
  800391:	89 03                	mov    %eax,(%ebx)
  800393:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800396:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80039a:	3d ff 00 00 00       	cmp    $0xff,%eax
  80039f:	75 1a                	jne    8003bb <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8003a1:	83 ec 08             	sub    $0x8,%esp
  8003a4:	68 ff 00 00 00       	push   $0xff
  8003a9:	8d 43 08             	lea    0x8(%ebx),%eax
  8003ac:	50                   	push   %eax
  8003ad:	e8 fa fc ff ff       	call   8000ac <sys_cputs>
		b->idx = 0;
  8003b2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8003b8:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8003bb:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8003bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8003c2:	c9                   	leave  
  8003c3:	c3                   	ret    

008003c4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8003c4:	55                   	push   %ebp
  8003c5:	89 e5                	mov    %esp,%ebp
  8003c7:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8003cd:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003d4:	00 00 00 
	b.cnt = 0;
  8003d7:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003de:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003e1:	ff 75 0c             	pushl  0xc(%ebp)
  8003e4:	ff 75 08             	pushl  0x8(%ebp)
  8003e7:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003ed:	50                   	push   %eax
  8003ee:	68 82 03 80 00       	push   $0x800382
  8003f3:	e8 1a 01 00 00       	call   800512 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003f8:	83 c4 08             	add    $0x8,%esp
  8003fb:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800401:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800407:	50                   	push   %eax
  800408:	e8 9f fc ff ff       	call   8000ac <sys_cputs>

	return b.cnt;
}
  80040d:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800413:	c9                   	leave  
  800414:	c3                   	ret    

00800415 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800415:	55                   	push   %ebp
  800416:	89 e5                	mov    %esp,%ebp
  800418:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80041b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80041e:	50                   	push   %eax
  80041f:	ff 75 08             	pushl  0x8(%ebp)
  800422:	e8 9d ff ff ff       	call   8003c4 <vcprintf>
	va_end(ap);

	return cnt;
}
  800427:	c9                   	leave  
  800428:	c3                   	ret    

00800429 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800429:	55                   	push   %ebp
  80042a:	89 e5                	mov    %esp,%ebp
  80042c:	57                   	push   %edi
  80042d:	56                   	push   %esi
  80042e:	53                   	push   %ebx
  80042f:	83 ec 1c             	sub    $0x1c,%esp
  800432:	89 c7                	mov    %eax,%edi
  800434:	89 d6                	mov    %edx,%esi
  800436:	8b 45 08             	mov    0x8(%ebp),%eax
  800439:	8b 55 0c             	mov    0xc(%ebp),%edx
  80043c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80043f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800442:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800445:	bb 00 00 00 00       	mov    $0x0,%ebx
  80044a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80044d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800450:	39 d3                	cmp    %edx,%ebx
  800452:	72 05                	jb     800459 <printnum+0x30>
  800454:	39 45 10             	cmp    %eax,0x10(%ebp)
  800457:	77 45                	ja     80049e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800459:	83 ec 0c             	sub    $0xc,%esp
  80045c:	ff 75 18             	pushl  0x18(%ebp)
  80045f:	8b 45 14             	mov    0x14(%ebp),%eax
  800462:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800465:	53                   	push   %ebx
  800466:	ff 75 10             	pushl  0x10(%ebp)
  800469:	83 ec 08             	sub    $0x8,%esp
  80046c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80046f:	ff 75 e0             	pushl  -0x20(%ebp)
  800472:	ff 75 dc             	pushl  -0x24(%ebp)
  800475:	ff 75 d8             	pushl  -0x28(%ebp)
  800478:	e8 43 09 00 00       	call   800dc0 <__udivdi3>
  80047d:	83 c4 18             	add    $0x18,%esp
  800480:	52                   	push   %edx
  800481:	50                   	push   %eax
  800482:	89 f2                	mov    %esi,%edx
  800484:	89 f8                	mov    %edi,%eax
  800486:	e8 9e ff ff ff       	call   800429 <printnum>
  80048b:	83 c4 20             	add    $0x20,%esp
  80048e:	eb 18                	jmp    8004a8 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800490:	83 ec 08             	sub    $0x8,%esp
  800493:	56                   	push   %esi
  800494:	ff 75 18             	pushl  0x18(%ebp)
  800497:	ff d7                	call   *%edi
  800499:	83 c4 10             	add    $0x10,%esp
  80049c:	eb 03                	jmp    8004a1 <printnum+0x78>
  80049e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004a1:	83 eb 01             	sub    $0x1,%ebx
  8004a4:	85 db                	test   %ebx,%ebx
  8004a6:	7f e8                	jg     800490 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004a8:	83 ec 08             	sub    $0x8,%esp
  8004ab:	56                   	push   %esi
  8004ac:	83 ec 04             	sub    $0x4,%esp
  8004af:	ff 75 e4             	pushl  -0x1c(%ebp)
  8004b2:	ff 75 e0             	pushl  -0x20(%ebp)
  8004b5:	ff 75 dc             	pushl  -0x24(%ebp)
  8004b8:	ff 75 d8             	pushl  -0x28(%ebp)
  8004bb:	e8 30 0a 00 00       	call   800ef0 <__umoddi3>
  8004c0:	83 c4 14             	add    $0x14,%esp
  8004c3:	0f be 80 be 10 80 00 	movsbl 0x8010be(%eax),%eax
  8004ca:	50                   	push   %eax
  8004cb:	ff d7                	call   *%edi
}
  8004cd:	83 c4 10             	add    $0x10,%esp
  8004d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004d3:	5b                   	pop    %ebx
  8004d4:	5e                   	pop    %esi
  8004d5:	5f                   	pop    %edi
  8004d6:	5d                   	pop    %ebp
  8004d7:	c3                   	ret    

008004d8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004d8:	55                   	push   %ebp
  8004d9:	89 e5                	mov    %esp,%ebp
  8004db:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004de:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004e2:	8b 10                	mov    (%eax),%edx
  8004e4:	3b 50 04             	cmp    0x4(%eax),%edx
  8004e7:	73 0a                	jae    8004f3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004e9:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004ec:	89 08                	mov    %ecx,(%eax)
  8004ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8004f1:	88 02                	mov    %al,(%edx)
}
  8004f3:	5d                   	pop    %ebp
  8004f4:	c3                   	ret    

008004f5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004f5:	55                   	push   %ebp
  8004f6:	89 e5                	mov    %esp,%ebp
  8004f8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004fb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004fe:	50                   	push   %eax
  8004ff:	ff 75 10             	pushl  0x10(%ebp)
  800502:	ff 75 0c             	pushl  0xc(%ebp)
  800505:	ff 75 08             	pushl  0x8(%ebp)
  800508:	e8 05 00 00 00       	call   800512 <vprintfmt>
	va_end(ap);
}
  80050d:	83 c4 10             	add    $0x10,%esp
  800510:	c9                   	leave  
  800511:	c3                   	ret    

00800512 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800512:	55                   	push   %ebp
  800513:	89 e5                	mov    %esp,%ebp
  800515:	57                   	push   %edi
  800516:	56                   	push   %esi
  800517:	53                   	push   %ebx
  800518:	83 ec 2c             	sub    $0x2c,%esp
  80051b:	8b 75 08             	mov    0x8(%ebp),%esi
  80051e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800521:	8b 7d 10             	mov    0x10(%ebp),%edi
  800524:	eb 12                	jmp    800538 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800526:	85 c0                	test   %eax,%eax
  800528:	0f 84 42 04 00 00    	je     800970 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80052e:	83 ec 08             	sub    $0x8,%esp
  800531:	53                   	push   %ebx
  800532:	50                   	push   %eax
  800533:	ff d6                	call   *%esi
  800535:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800538:	83 c7 01             	add    $0x1,%edi
  80053b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80053f:	83 f8 25             	cmp    $0x25,%eax
  800542:	75 e2                	jne    800526 <vprintfmt+0x14>
  800544:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800548:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80054f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800556:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80055d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800562:	eb 07                	jmp    80056b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800564:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800567:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056b:	8d 47 01             	lea    0x1(%edi),%eax
  80056e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800571:	0f b6 07             	movzbl (%edi),%eax
  800574:	0f b6 d0             	movzbl %al,%edx
  800577:	83 e8 23             	sub    $0x23,%eax
  80057a:	3c 55                	cmp    $0x55,%al
  80057c:	0f 87 d3 03 00 00    	ja     800955 <vprintfmt+0x443>
  800582:	0f b6 c0             	movzbl %al,%eax
  800585:	ff 24 85 80 11 80 00 	jmp    *0x801180(,%eax,4)
  80058c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80058f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800593:	eb d6                	jmp    80056b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800595:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800598:	b8 00 00 00 00       	mov    $0x0,%eax
  80059d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8005a0:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8005a3:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8005a7:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8005aa:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8005ad:	83 f9 09             	cmp    $0x9,%ecx
  8005b0:	77 3f                	ja     8005f1 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005b2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005b5:	eb e9                	jmp    8005a0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ba:	8b 00                	mov    (%eax),%eax
  8005bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005bf:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c2:	8d 40 04             	lea    0x4(%eax),%eax
  8005c5:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005cb:	eb 2a                	jmp    8005f7 <vprintfmt+0xe5>
  8005cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005d0:	85 c0                	test   %eax,%eax
  8005d2:	ba 00 00 00 00       	mov    $0x0,%edx
  8005d7:	0f 49 d0             	cmovns %eax,%edx
  8005da:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e0:	eb 89                	jmp    80056b <vprintfmt+0x59>
  8005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005e5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005ec:	e9 7a ff ff ff       	jmp    80056b <vprintfmt+0x59>
  8005f1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005f4:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005f7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005fb:	0f 89 6a ff ff ff    	jns    80056b <vprintfmt+0x59>
				width = precision, precision = -1;
  800601:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800604:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800607:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80060e:	e9 58 ff ff ff       	jmp    80056b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800613:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800616:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800619:	e9 4d ff ff ff       	jmp    80056b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80061e:	8b 45 14             	mov    0x14(%ebp),%eax
  800621:	8d 78 04             	lea    0x4(%eax),%edi
  800624:	83 ec 08             	sub    $0x8,%esp
  800627:	53                   	push   %ebx
  800628:	ff 30                	pushl  (%eax)
  80062a:	ff d6                	call   *%esi
			break;
  80062c:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80062f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800632:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800635:	e9 fe fe ff ff       	jmp    800538 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80063a:	8b 45 14             	mov    0x14(%ebp),%eax
  80063d:	8d 78 04             	lea    0x4(%eax),%edi
  800640:	8b 00                	mov    (%eax),%eax
  800642:	99                   	cltd   
  800643:	31 d0                	xor    %edx,%eax
  800645:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800647:	83 f8 08             	cmp    $0x8,%eax
  80064a:	7f 0b                	jg     800657 <vprintfmt+0x145>
  80064c:	8b 14 85 e0 12 80 00 	mov    0x8012e0(,%eax,4),%edx
  800653:	85 d2                	test   %edx,%edx
  800655:	75 1b                	jne    800672 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800657:	50                   	push   %eax
  800658:	68 d6 10 80 00       	push   $0x8010d6
  80065d:	53                   	push   %ebx
  80065e:	56                   	push   %esi
  80065f:	e8 91 fe ff ff       	call   8004f5 <printfmt>
  800664:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800667:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80066a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80066d:	e9 c6 fe ff ff       	jmp    800538 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800672:	52                   	push   %edx
  800673:	68 df 10 80 00       	push   $0x8010df
  800678:	53                   	push   %ebx
  800679:	56                   	push   %esi
  80067a:	e8 76 fe ff ff       	call   8004f5 <printfmt>
  80067f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800682:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800685:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800688:	e9 ab fe ff ff       	jmp    800538 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80068d:	8b 45 14             	mov    0x14(%ebp),%eax
  800690:	83 c0 04             	add    $0x4,%eax
  800693:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800696:	8b 45 14             	mov    0x14(%ebp),%eax
  800699:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80069b:	85 ff                	test   %edi,%edi
  80069d:	b8 cf 10 80 00       	mov    $0x8010cf,%eax
  8006a2:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8006a5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8006a9:	0f 8e 94 00 00 00    	jle    800743 <vprintfmt+0x231>
  8006af:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8006b3:	0f 84 98 00 00 00    	je     800751 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006b9:	83 ec 08             	sub    $0x8,%esp
  8006bc:	ff 75 d0             	pushl  -0x30(%ebp)
  8006bf:	57                   	push   %edi
  8006c0:	e8 33 03 00 00       	call   8009f8 <strnlen>
  8006c5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8006c8:	29 c1                	sub    %eax,%ecx
  8006ca:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8006cd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006d0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8006d4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006d7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006da:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006dc:	eb 0f                	jmp    8006ed <vprintfmt+0x1db>
					putch(padc, putdat);
  8006de:	83 ec 08             	sub    $0x8,%esp
  8006e1:	53                   	push   %ebx
  8006e2:	ff 75 e0             	pushl  -0x20(%ebp)
  8006e5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006e7:	83 ef 01             	sub    $0x1,%edi
  8006ea:	83 c4 10             	add    $0x10,%esp
  8006ed:	85 ff                	test   %edi,%edi
  8006ef:	7f ed                	jg     8006de <vprintfmt+0x1cc>
  8006f1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006f4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8006f7:	85 c9                	test   %ecx,%ecx
  8006f9:	b8 00 00 00 00       	mov    $0x0,%eax
  8006fe:	0f 49 c1             	cmovns %ecx,%eax
  800701:	29 c1                	sub    %eax,%ecx
  800703:	89 75 08             	mov    %esi,0x8(%ebp)
  800706:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800709:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80070c:	89 cb                	mov    %ecx,%ebx
  80070e:	eb 4d                	jmp    80075d <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800710:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800714:	74 1b                	je     800731 <vprintfmt+0x21f>
  800716:	0f be c0             	movsbl %al,%eax
  800719:	83 e8 20             	sub    $0x20,%eax
  80071c:	83 f8 5e             	cmp    $0x5e,%eax
  80071f:	76 10                	jbe    800731 <vprintfmt+0x21f>
					putch('?', putdat);
  800721:	83 ec 08             	sub    $0x8,%esp
  800724:	ff 75 0c             	pushl  0xc(%ebp)
  800727:	6a 3f                	push   $0x3f
  800729:	ff 55 08             	call   *0x8(%ebp)
  80072c:	83 c4 10             	add    $0x10,%esp
  80072f:	eb 0d                	jmp    80073e <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800731:	83 ec 08             	sub    $0x8,%esp
  800734:	ff 75 0c             	pushl  0xc(%ebp)
  800737:	52                   	push   %edx
  800738:	ff 55 08             	call   *0x8(%ebp)
  80073b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80073e:	83 eb 01             	sub    $0x1,%ebx
  800741:	eb 1a                	jmp    80075d <vprintfmt+0x24b>
  800743:	89 75 08             	mov    %esi,0x8(%ebp)
  800746:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800749:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80074c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80074f:	eb 0c                	jmp    80075d <vprintfmt+0x24b>
  800751:	89 75 08             	mov    %esi,0x8(%ebp)
  800754:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800757:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80075a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80075d:	83 c7 01             	add    $0x1,%edi
  800760:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800764:	0f be d0             	movsbl %al,%edx
  800767:	85 d2                	test   %edx,%edx
  800769:	74 23                	je     80078e <vprintfmt+0x27c>
  80076b:	85 f6                	test   %esi,%esi
  80076d:	78 a1                	js     800710 <vprintfmt+0x1fe>
  80076f:	83 ee 01             	sub    $0x1,%esi
  800772:	79 9c                	jns    800710 <vprintfmt+0x1fe>
  800774:	89 df                	mov    %ebx,%edi
  800776:	8b 75 08             	mov    0x8(%ebp),%esi
  800779:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80077c:	eb 18                	jmp    800796 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80077e:	83 ec 08             	sub    $0x8,%esp
  800781:	53                   	push   %ebx
  800782:	6a 20                	push   $0x20
  800784:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800786:	83 ef 01             	sub    $0x1,%edi
  800789:	83 c4 10             	add    $0x10,%esp
  80078c:	eb 08                	jmp    800796 <vprintfmt+0x284>
  80078e:	89 df                	mov    %ebx,%edi
  800790:	8b 75 08             	mov    0x8(%ebp),%esi
  800793:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800796:	85 ff                	test   %edi,%edi
  800798:	7f e4                	jg     80077e <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80079a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80079d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007a3:	e9 90 fd ff ff       	jmp    800538 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007a8:	83 f9 01             	cmp    $0x1,%ecx
  8007ab:	7e 19                	jle    8007c6 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8007ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b0:	8b 50 04             	mov    0x4(%eax),%edx
  8007b3:	8b 00                	mov    (%eax),%eax
  8007b5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007b8:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8007be:	8d 40 08             	lea    0x8(%eax),%eax
  8007c1:	89 45 14             	mov    %eax,0x14(%ebp)
  8007c4:	eb 38                	jmp    8007fe <vprintfmt+0x2ec>
	else if (lflag)
  8007c6:	85 c9                	test   %ecx,%ecx
  8007c8:	74 1b                	je     8007e5 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8007ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8007cd:	8b 00                	mov    (%eax),%eax
  8007cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007d2:	89 c1                	mov    %eax,%ecx
  8007d4:	c1 f9 1f             	sar    $0x1f,%ecx
  8007d7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007da:	8b 45 14             	mov    0x14(%ebp),%eax
  8007dd:	8d 40 04             	lea    0x4(%eax),%eax
  8007e0:	89 45 14             	mov    %eax,0x14(%ebp)
  8007e3:	eb 19                	jmp    8007fe <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8007e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e8:	8b 00                	mov    (%eax),%eax
  8007ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007ed:	89 c1                	mov    %eax,%ecx
  8007ef:	c1 f9 1f             	sar    $0x1f,%ecx
  8007f2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f8:	8d 40 04             	lea    0x4(%eax),%eax
  8007fb:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8007fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800801:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800804:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800809:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80080d:	0f 89 0e 01 00 00    	jns    800921 <vprintfmt+0x40f>
				putch('-', putdat);
  800813:	83 ec 08             	sub    $0x8,%esp
  800816:	53                   	push   %ebx
  800817:	6a 2d                	push   $0x2d
  800819:	ff d6                	call   *%esi
				num = -(long long) num;
  80081b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80081e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800821:	f7 da                	neg    %edx
  800823:	83 d1 00             	adc    $0x0,%ecx
  800826:	f7 d9                	neg    %ecx
  800828:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80082b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800830:	e9 ec 00 00 00       	jmp    800921 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800835:	83 f9 01             	cmp    $0x1,%ecx
  800838:	7e 18                	jle    800852 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80083a:	8b 45 14             	mov    0x14(%ebp),%eax
  80083d:	8b 10                	mov    (%eax),%edx
  80083f:	8b 48 04             	mov    0x4(%eax),%ecx
  800842:	8d 40 08             	lea    0x8(%eax),%eax
  800845:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800848:	b8 0a 00 00 00       	mov    $0xa,%eax
  80084d:	e9 cf 00 00 00       	jmp    800921 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800852:	85 c9                	test   %ecx,%ecx
  800854:	74 1a                	je     800870 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800856:	8b 45 14             	mov    0x14(%ebp),%eax
  800859:	8b 10                	mov    (%eax),%edx
  80085b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800860:	8d 40 04             	lea    0x4(%eax),%eax
  800863:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800866:	b8 0a 00 00 00       	mov    $0xa,%eax
  80086b:	e9 b1 00 00 00       	jmp    800921 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800870:	8b 45 14             	mov    0x14(%ebp),%eax
  800873:	8b 10                	mov    (%eax),%edx
  800875:	b9 00 00 00 00       	mov    $0x0,%ecx
  80087a:	8d 40 04             	lea    0x4(%eax),%eax
  80087d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800880:	b8 0a 00 00 00       	mov    $0xa,%eax
  800885:	e9 97 00 00 00       	jmp    800921 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80088a:	83 ec 08             	sub    $0x8,%esp
  80088d:	53                   	push   %ebx
  80088e:	6a 58                	push   $0x58
  800890:	ff d6                	call   *%esi
			putch('X', putdat);
  800892:	83 c4 08             	add    $0x8,%esp
  800895:	53                   	push   %ebx
  800896:	6a 58                	push   $0x58
  800898:	ff d6                	call   *%esi
			putch('X', putdat);
  80089a:	83 c4 08             	add    $0x8,%esp
  80089d:	53                   	push   %ebx
  80089e:	6a 58                	push   $0x58
  8008a0:	ff d6                	call   *%esi
			break;
  8008a2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8008a8:	e9 8b fc ff ff       	jmp    800538 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8008ad:	83 ec 08             	sub    $0x8,%esp
  8008b0:	53                   	push   %ebx
  8008b1:	6a 30                	push   $0x30
  8008b3:	ff d6                	call   *%esi
			putch('x', putdat);
  8008b5:	83 c4 08             	add    $0x8,%esp
  8008b8:	53                   	push   %ebx
  8008b9:	6a 78                	push   $0x78
  8008bb:	ff d6                	call   *%esi
			num = (unsigned long long)
  8008bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8008c0:	8b 10                	mov    (%eax),%edx
  8008c2:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8008c7:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8008ca:	8d 40 04             	lea    0x4(%eax),%eax
  8008cd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8008d0:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8008d5:	eb 4a                	jmp    800921 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008d7:	83 f9 01             	cmp    $0x1,%ecx
  8008da:	7e 15                	jle    8008f1 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8008dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8008df:	8b 10                	mov    (%eax),%edx
  8008e1:	8b 48 04             	mov    0x4(%eax),%ecx
  8008e4:	8d 40 08             	lea    0x8(%eax),%eax
  8008e7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008ea:	b8 10 00 00 00       	mov    $0x10,%eax
  8008ef:	eb 30                	jmp    800921 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8008f1:	85 c9                	test   %ecx,%ecx
  8008f3:	74 17                	je     80090c <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8008f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f8:	8b 10                	mov    (%eax),%edx
  8008fa:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008ff:	8d 40 04             	lea    0x4(%eax),%eax
  800902:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800905:	b8 10 00 00 00       	mov    $0x10,%eax
  80090a:	eb 15                	jmp    800921 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80090c:	8b 45 14             	mov    0x14(%ebp),%eax
  80090f:	8b 10                	mov    (%eax),%edx
  800911:	b9 00 00 00 00       	mov    $0x0,%ecx
  800916:	8d 40 04             	lea    0x4(%eax),%eax
  800919:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80091c:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800921:	83 ec 0c             	sub    $0xc,%esp
  800924:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800928:	57                   	push   %edi
  800929:	ff 75 e0             	pushl  -0x20(%ebp)
  80092c:	50                   	push   %eax
  80092d:	51                   	push   %ecx
  80092e:	52                   	push   %edx
  80092f:	89 da                	mov    %ebx,%edx
  800931:	89 f0                	mov    %esi,%eax
  800933:	e8 f1 fa ff ff       	call   800429 <printnum>
			break;
  800938:	83 c4 20             	add    $0x20,%esp
  80093b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80093e:	e9 f5 fb ff ff       	jmp    800538 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800943:	83 ec 08             	sub    $0x8,%esp
  800946:	53                   	push   %ebx
  800947:	52                   	push   %edx
  800948:	ff d6                	call   *%esi
			break;
  80094a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80094d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800950:	e9 e3 fb ff ff       	jmp    800538 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800955:	83 ec 08             	sub    $0x8,%esp
  800958:	53                   	push   %ebx
  800959:	6a 25                	push   $0x25
  80095b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80095d:	83 c4 10             	add    $0x10,%esp
  800960:	eb 03                	jmp    800965 <vprintfmt+0x453>
  800962:	83 ef 01             	sub    $0x1,%edi
  800965:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800969:	75 f7                	jne    800962 <vprintfmt+0x450>
  80096b:	e9 c8 fb ff ff       	jmp    800538 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800970:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800973:	5b                   	pop    %ebx
  800974:	5e                   	pop    %esi
  800975:	5f                   	pop    %edi
  800976:	5d                   	pop    %ebp
  800977:	c3                   	ret    

00800978 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800978:	55                   	push   %ebp
  800979:	89 e5                	mov    %esp,%ebp
  80097b:	83 ec 18             	sub    $0x18,%esp
  80097e:	8b 45 08             	mov    0x8(%ebp),%eax
  800981:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800984:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800987:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80098b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80098e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800995:	85 c0                	test   %eax,%eax
  800997:	74 26                	je     8009bf <vsnprintf+0x47>
  800999:	85 d2                	test   %edx,%edx
  80099b:	7e 22                	jle    8009bf <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80099d:	ff 75 14             	pushl  0x14(%ebp)
  8009a0:	ff 75 10             	pushl  0x10(%ebp)
  8009a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8009a6:	50                   	push   %eax
  8009a7:	68 d8 04 80 00       	push   $0x8004d8
  8009ac:	e8 61 fb ff ff       	call   800512 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8009b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8009b4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8009b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8009ba:	83 c4 10             	add    $0x10,%esp
  8009bd:	eb 05                	jmp    8009c4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8009bf:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8009c4:	c9                   	leave  
  8009c5:	c3                   	ret    

008009c6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8009cc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009cf:	50                   	push   %eax
  8009d0:	ff 75 10             	pushl  0x10(%ebp)
  8009d3:	ff 75 0c             	pushl  0xc(%ebp)
  8009d6:	ff 75 08             	pushl  0x8(%ebp)
  8009d9:	e8 9a ff ff ff       	call   800978 <vsnprintf>
	va_end(ap);

	return rc;
}
  8009de:	c9                   	leave  
  8009df:	c3                   	ret    

008009e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009e0:	55                   	push   %ebp
  8009e1:	89 e5                	mov    %esp,%ebp
  8009e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8009e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8009eb:	eb 03                	jmp    8009f0 <strlen+0x10>
		n++;
  8009ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009f4:	75 f7                	jne    8009ed <strlen+0xd>
		n++;
	return n;
}
  8009f6:	5d                   	pop    %ebp
  8009f7:	c3                   	ret    

008009f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009f8:	55                   	push   %ebp
  8009f9:	89 e5                	mov    %esp,%ebp
  8009fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009fe:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a01:	ba 00 00 00 00       	mov    $0x0,%edx
  800a06:	eb 03                	jmp    800a0b <strnlen+0x13>
		n++;
  800a08:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a0b:	39 c2                	cmp    %eax,%edx
  800a0d:	74 08                	je     800a17 <strnlen+0x1f>
  800a0f:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800a13:	75 f3                	jne    800a08 <strnlen+0x10>
  800a15:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800a17:	5d                   	pop    %ebp
  800a18:	c3                   	ret    

00800a19 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800a19:	55                   	push   %ebp
  800a1a:	89 e5                	mov    %esp,%ebp
  800a1c:	53                   	push   %ebx
  800a1d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a20:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800a23:	89 c2                	mov    %eax,%edx
  800a25:	83 c2 01             	add    $0x1,%edx
  800a28:	83 c1 01             	add    $0x1,%ecx
  800a2b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800a2f:	88 5a ff             	mov    %bl,-0x1(%edx)
  800a32:	84 db                	test   %bl,%bl
  800a34:	75 ef                	jne    800a25 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a36:	5b                   	pop    %ebx
  800a37:	5d                   	pop    %ebp
  800a38:	c3                   	ret    

00800a39 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a39:	55                   	push   %ebp
  800a3a:	89 e5                	mov    %esp,%ebp
  800a3c:	53                   	push   %ebx
  800a3d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a40:	53                   	push   %ebx
  800a41:	e8 9a ff ff ff       	call   8009e0 <strlen>
  800a46:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800a49:	ff 75 0c             	pushl  0xc(%ebp)
  800a4c:	01 d8                	add    %ebx,%eax
  800a4e:	50                   	push   %eax
  800a4f:	e8 c5 ff ff ff       	call   800a19 <strcpy>
	return dst;
}
  800a54:	89 d8                	mov    %ebx,%eax
  800a56:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800a59:	c9                   	leave  
  800a5a:	c3                   	ret    

00800a5b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a5b:	55                   	push   %ebp
  800a5c:	89 e5                	mov    %esp,%ebp
  800a5e:	56                   	push   %esi
  800a5f:	53                   	push   %ebx
  800a60:	8b 75 08             	mov    0x8(%ebp),%esi
  800a63:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a66:	89 f3                	mov    %esi,%ebx
  800a68:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a6b:	89 f2                	mov    %esi,%edx
  800a6d:	eb 0f                	jmp    800a7e <strncpy+0x23>
		*dst++ = *src;
  800a6f:	83 c2 01             	add    $0x1,%edx
  800a72:	0f b6 01             	movzbl (%ecx),%eax
  800a75:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a78:	80 39 01             	cmpb   $0x1,(%ecx)
  800a7b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a7e:	39 da                	cmp    %ebx,%edx
  800a80:	75 ed                	jne    800a6f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a82:	89 f0                	mov    %esi,%eax
  800a84:	5b                   	pop    %ebx
  800a85:	5e                   	pop    %esi
  800a86:	5d                   	pop    %ebp
  800a87:	c3                   	ret    

00800a88 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a88:	55                   	push   %ebp
  800a89:	89 e5                	mov    %esp,%ebp
  800a8b:	56                   	push   %esi
  800a8c:	53                   	push   %ebx
  800a8d:	8b 75 08             	mov    0x8(%ebp),%esi
  800a90:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a93:	8b 55 10             	mov    0x10(%ebp),%edx
  800a96:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a98:	85 d2                	test   %edx,%edx
  800a9a:	74 21                	je     800abd <strlcpy+0x35>
  800a9c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800aa0:	89 f2                	mov    %esi,%edx
  800aa2:	eb 09                	jmp    800aad <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800aa4:	83 c2 01             	add    $0x1,%edx
  800aa7:	83 c1 01             	add    $0x1,%ecx
  800aaa:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800aad:	39 c2                	cmp    %eax,%edx
  800aaf:	74 09                	je     800aba <strlcpy+0x32>
  800ab1:	0f b6 19             	movzbl (%ecx),%ebx
  800ab4:	84 db                	test   %bl,%bl
  800ab6:	75 ec                	jne    800aa4 <strlcpy+0x1c>
  800ab8:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800aba:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800abd:	29 f0                	sub    %esi,%eax
}
  800abf:	5b                   	pop    %ebx
  800ac0:	5e                   	pop    %esi
  800ac1:	5d                   	pop    %ebp
  800ac2:	c3                   	ret    

00800ac3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800ac3:	55                   	push   %ebp
  800ac4:	89 e5                	mov    %esp,%ebp
  800ac6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ac9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800acc:	eb 06                	jmp    800ad4 <strcmp+0x11>
		p++, q++;
  800ace:	83 c1 01             	add    $0x1,%ecx
  800ad1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800ad4:	0f b6 01             	movzbl (%ecx),%eax
  800ad7:	84 c0                	test   %al,%al
  800ad9:	74 04                	je     800adf <strcmp+0x1c>
  800adb:	3a 02                	cmp    (%edx),%al
  800add:	74 ef                	je     800ace <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800adf:	0f b6 c0             	movzbl %al,%eax
  800ae2:	0f b6 12             	movzbl (%edx),%edx
  800ae5:	29 d0                	sub    %edx,%eax
}
  800ae7:	5d                   	pop    %ebp
  800ae8:	c3                   	ret    

00800ae9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ae9:	55                   	push   %ebp
  800aea:	89 e5                	mov    %esp,%ebp
  800aec:	53                   	push   %ebx
  800aed:	8b 45 08             	mov    0x8(%ebp),%eax
  800af0:	8b 55 0c             	mov    0xc(%ebp),%edx
  800af3:	89 c3                	mov    %eax,%ebx
  800af5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800af8:	eb 06                	jmp    800b00 <strncmp+0x17>
		n--, p++, q++;
  800afa:	83 c0 01             	add    $0x1,%eax
  800afd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800b00:	39 d8                	cmp    %ebx,%eax
  800b02:	74 15                	je     800b19 <strncmp+0x30>
  800b04:	0f b6 08             	movzbl (%eax),%ecx
  800b07:	84 c9                	test   %cl,%cl
  800b09:	74 04                	je     800b0f <strncmp+0x26>
  800b0b:	3a 0a                	cmp    (%edx),%cl
  800b0d:	74 eb                	je     800afa <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800b0f:	0f b6 00             	movzbl (%eax),%eax
  800b12:	0f b6 12             	movzbl (%edx),%edx
  800b15:	29 d0                	sub    %edx,%eax
  800b17:	eb 05                	jmp    800b1e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800b19:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800b1e:	5b                   	pop    %ebx
  800b1f:	5d                   	pop    %ebp
  800b20:	c3                   	ret    

00800b21 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800b21:	55                   	push   %ebp
  800b22:	89 e5                	mov    %esp,%ebp
  800b24:	8b 45 08             	mov    0x8(%ebp),%eax
  800b27:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b2b:	eb 07                	jmp    800b34 <strchr+0x13>
		if (*s == c)
  800b2d:	38 ca                	cmp    %cl,%dl
  800b2f:	74 0f                	je     800b40 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800b31:	83 c0 01             	add    $0x1,%eax
  800b34:	0f b6 10             	movzbl (%eax),%edx
  800b37:	84 d2                	test   %dl,%dl
  800b39:	75 f2                	jne    800b2d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b3b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b40:	5d                   	pop    %ebp
  800b41:	c3                   	ret    

00800b42 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b42:	55                   	push   %ebp
  800b43:	89 e5                	mov    %esp,%ebp
  800b45:	8b 45 08             	mov    0x8(%ebp),%eax
  800b48:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b4c:	eb 03                	jmp    800b51 <strfind+0xf>
  800b4e:	83 c0 01             	add    $0x1,%eax
  800b51:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800b54:	38 ca                	cmp    %cl,%dl
  800b56:	74 04                	je     800b5c <strfind+0x1a>
  800b58:	84 d2                	test   %dl,%dl
  800b5a:	75 f2                	jne    800b4e <strfind+0xc>
			break;
	return (char *) s;
}
  800b5c:	5d                   	pop    %ebp
  800b5d:	c3                   	ret    

00800b5e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b5e:	55                   	push   %ebp
  800b5f:	89 e5                	mov    %esp,%ebp
  800b61:	57                   	push   %edi
  800b62:	56                   	push   %esi
  800b63:	53                   	push   %ebx
  800b64:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b67:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b6a:	85 c9                	test   %ecx,%ecx
  800b6c:	74 36                	je     800ba4 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b6e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b74:	75 28                	jne    800b9e <memset+0x40>
  800b76:	f6 c1 03             	test   $0x3,%cl
  800b79:	75 23                	jne    800b9e <memset+0x40>
		c &= 0xFF;
  800b7b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b7f:	89 d3                	mov    %edx,%ebx
  800b81:	c1 e3 08             	shl    $0x8,%ebx
  800b84:	89 d6                	mov    %edx,%esi
  800b86:	c1 e6 18             	shl    $0x18,%esi
  800b89:	89 d0                	mov    %edx,%eax
  800b8b:	c1 e0 10             	shl    $0x10,%eax
  800b8e:	09 f0                	or     %esi,%eax
  800b90:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800b92:	89 d8                	mov    %ebx,%eax
  800b94:	09 d0                	or     %edx,%eax
  800b96:	c1 e9 02             	shr    $0x2,%ecx
  800b99:	fc                   	cld    
  800b9a:	f3 ab                	rep stos %eax,%es:(%edi)
  800b9c:	eb 06                	jmp    800ba4 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ba1:	fc                   	cld    
  800ba2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800ba4:	89 f8                	mov    %edi,%eax
  800ba6:	5b                   	pop    %ebx
  800ba7:	5e                   	pop    %esi
  800ba8:	5f                   	pop    %edi
  800ba9:	5d                   	pop    %ebp
  800baa:	c3                   	ret    

00800bab <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800bab:	55                   	push   %ebp
  800bac:	89 e5                	mov    %esp,%ebp
  800bae:	57                   	push   %edi
  800baf:	56                   	push   %esi
  800bb0:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb3:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bb6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800bb9:	39 c6                	cmp    %eax,%esi
  800bbb:	73 35                	jae    800bf2 <memmove+0x47>
  800bbd:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800bc0:	39 d0                	cmp    %edx,%eax
  800bc2:	73 2e                	jae    800bf2 <memmove+0x47>
		s += n;
		d += n;
  800bc4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bc7:	89 d6                	mov    %edx,%esi
  800bc9:	09 fe                	or     %edi,%esi
  800bcb:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800bd1:	75 13                	jne    800be6 <memmove+0x3b>
  800bd3:	f6 c1 03             	test   $0x3,%cl
  800bd6:	75 0e                	jne    800be6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800bd8:	83 ef 04             	sub    $0x4,%edi
  800bdb:	8d 72 fc             	lea    -0x4(%edx),%esi
  800bde:	c1 e9 02             	shr    $0x2,%ecx
  800be1:	fd                   	std    
  800be2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800be4:	eb 09                	jmp    800bef <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800be6:	83 ef 01             	sub    $0x1,%edi
  800be9:	8d 72 ff             	lea    -0x1(%edx),%esi
  800bec:	fd                   	std    
  800bed:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bef:	fc                   	cld    
  800bf0:	eb 1d                	jmp    800c0f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bf2:	89 f2                	mov    %esi,%edx
  800bf4:	09 c2                	or     %eax,%edx
  800bf6:	f6 c2 03             	test   $0x3,%dl
  800bf9:	75 0f                	jne    800c0a <memmove+0x5f>
  800bfb:	f6 c1 03             	test   $0x3,%cl
  800bfe:	75 0a                	jne    800c0a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800c00:	c1 e9 02             	shr    $0x2,%ecx
  800c03:	89 c7                	mov    %eax,%edi
  800c05:	fc                   	cld    
  800c06:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c08:	eb 05                	jmp    800c0f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800c0a:	89 c7                	mov    %eax,%edi
  800c0c:	fc                   	cld    
  800c0d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800c0f:	5e                   	pop    %esi
  800c10:	5f                   	pop    %edi
  800c11:	5d                   	pop    %ebp
  800c12:	c3                   	ret    

00800c13 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800c13:	55                   	push   %ebp
  800c14:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800c16:	ff 75 10             	pushl  0x10(%ebp)
  800c19:	ff 75 0c             	pushl  0xc(%ebp)
  800c1c:	ff 75 08             	pushl  0x8(%ebp)
  800c1f:	e8 87 ff ff ff       	call   800bab <memmove>
}
  800c24:	c9                   	leave  
  800c25:	c3                   	ret    

00800c26 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800c26:	55                   	push   %ebp
  800c27:	89 e5                	mov    %esp,%ebp
  800c29:	56                   	push   %esi
  800c2a:	53                   	push   %ebx
  800c2b:	8b 45 08             	mov    0x8(%ebp),%eax
  800c2e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c31:	89 c6                	mov    %eax,%esi
  800c33:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c36:	eb 1a                	jmp    800c52 <memcmp+0x2c>
		if (*s1 != *s2)
  800c38:	0f b6 08             	movzbl (%eax),%ecx
  800c3b:	0f b6 1a             	movzbl (%edx),%ebx
  800c3e:	38 d9                	cmp    %bl,%cl
  800c40:	74 0a                	je     800c4c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c42:	0f b6 c1             	movzbl %cl,%eax
  800c45:	0f b6 db             	movzbl %bl,%ebx
  800c48:	29 d8                	sub    %ebx,%eax
  800c4a:	eb 0f                	jmp    800c5b <memcmp+0x35>
		s1++, s2++;
  800c4c:	83 c0 01             	add    $0x1,%eax
  800c4f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c52:	39 f0                	cmp    %esi,%eax
  800c54:	75 e2                	jne    800c38 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c56:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c5b:	5b                   	pop    %ebx
  800c5c:	5e                   	pop    %esi
  800c5d:	5d                   	pop    %ebp
  800c5e:	c3                   	ret    

00800c5f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c5f:	55                   	push   %ebp
  800c60:	89 e5                	mov    %esp,%ebp
  800c62:	53                   	push   %ebx
  800c63:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800c66:	89 c1                	mov    %eax,%ecx
  800c68:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800c6b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c6f:	eb 0a                	jmp    800c7b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c71:	0f b6 10             	movzbl (%eax),%edx
  800c74:	39 da                	cmp    %ebx,%edx
  800c76:	74 07                	je     800c7f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c78:	83 c0 01             	add    $0x1,%eax
  800c7b:	39 c8                	cmp    %ecx,%eax
  800c7d:	72 f2                	jb     800c71 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c7f:	5b                   	pop    %ebx
  800c80:	5d                   	pop    %ebp
  800c81:	c3                   	ret    

00800c82 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c82:	55                   	push   %ebp
  800c83:	89 e5                	mov    %esp,%ebp
  800c85:	57                   	push   %edi
  800c86:	56                   	push   %esi
  800c87:	53                   	push   %ebx
  800c88:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c8e:	eb 03                	jmp    800c93 <strtol+0x11>
		s++;
  800c90:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c93:	0f b6 01             	movzbl (%ecx),%eax
  800c96:	3c 20                	cmp    $0x20,%al
  800c98:	74 f6                	je     800c90 <strtol+0xe>
  800c9a:	3c 09                	cmp    $0x9,%al
  800c9c:	74 f2                	je     800c90 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c9e:	3c 2b                	cmp    $0x2b,%al
  800ca0:	75 0a                	jne    800cac <strtol+0x2a>
		s++;
  800ca2:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ca5:	bf 00 00 00 00       	mov    $0x0,%edi
  800caa:	eb 11                	jmp    800cbd <strtol+0x3b>
  800cac:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800cb1:	3c 2d                	cmp    $0x2d,%al
  800cb3:	75 08                	jne    800cbd <strtol+0x3b>
		s++, neg = 1;
  800cb5:	83 c1 01             	add    $0x1,%ecx
  800cb8:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cbd:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cc3:	75 15                	jne    800cda <strtol+0x58>
  800cc5:	80 39 30             	cmpb   $0x30,(%ecx)
  800cc8:	75 10                	jne    800cda <strtol+0x58>
  800cca:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800cce:	75 7c                	jne    800d4c <strtol+0xca>
		s += 2, base = 16;
  800cd0:	83 c1 02             	add    $0x2,%ecx
  800cd3:	bb 10 00 00 00       	mov    $0x10,%ebx
  800cd8:	eb 16                	jmp    800cf0 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800cda:	85 db                	test   %ebx,%ebx
  800cdc:	75 12                	jne    800cf0 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cde:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ce3:	80 39 30             	cmpb   $0x30,(%ecx)
  800ce6:	75 08                	jne    800cf0 <strtol+0x6e>
		s++, base = 8;
  800ce8:	83 c1 01             	add    $0x1,%ecx
  800ceb:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800cf0:	b8 00 00 00 00       	mov    $0x0,%eax
  800cf5:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cf8:	0f b6 11             	movzbl (%ecx),%edx
  800cfb:	8d 72 d0             	lea    -0x30(%edx),%esi
  800cfe:	89 f3                	mov    %esi,%ebx
  800d00:	80 fb 09             	cmp    $0x9,%bl
  800d03:	77 08                	ja     800d0d <strtol+0x8b>
			dig = *s - '0';
  800d05:	0f be d2             	movsbl %dl,%edx
  800d08:	83 ea 30             	sub    $0x30,%edx
  800d0b:	eb 22                	jmp    800d2f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800d0d:	8d 72 9f             	lea    -0x61(%edx),%esi
  800d10:	89 f3                	mov    %esi,%ebx
  800d12:	80 fb 19             	cmp    $0x19,%bl
  800d15:	77 08                	ja     800d1f <strtol+0x9d>
			dig = *s - 'a' + 10;
  800d17:	0f be d2             	movsbl %dl,%edx
  800d1a:	83 ea 57             	sub    $0x57,%edx
  800d1d:	eb 10                	jmp    800d2f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800d1f:	8d 72 bf             	lea    -0x41(%edx),%esi
  800d22:	89 f3                	mov    %esi,%ebx
  800d24:	80 fb 19             	cmp    $0x19,%bl
  800d27:	77 16                	ja     800d3f <strtol+0xbd>
			dig = *s - 'A' + 10;
  800d29:	0f be d2             	movsbl %dl,%edx
  800d2c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800d2f:	3b 55 10             	cmp    0x10(%ebp),%edx
  800d32:	7d 0b                	jge    800d3f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800d34:	83 c1 01             	add    $0x1,%ecx
  800d37:	0f af 45 10          	imul   0x10(%ebp),%eax
  800d3b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800d3d:	eb b9                	jmp    800cf8 <strtol+0x76>

	if (endptr)
  800d3f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d43:	74 0d                	je     800d52 <strtol+0xd0>
		*endptr = (char *) s;
  800d45:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d48:	89 0e                	mov    %ecx,(%esi)
  800d4a:	eb 06                	jmp    800d52 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d4c:	85 db                	test   %ebx,%ebx
  800d4e:	74 98                	je     800ce8 <strtol+0x66>
  800d50:	eb 9e                	jmp    800cf0 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800d52:	89 c2                	mov    %eax,%edx
  800d54:	f7 da                	neg    %edx
  800d56:	85 ff                	test   %edi,%edi
  800d58:	0f 45 c2             	cmovne %edx,%eax
}
  800d5b:	5b                   	pop    %ebx
  800d5c:	5e                   	pop    %esi
  800d5d:	5f                   	pop    %edi
  800d5e:	5d                   	pop    %ebp
  800d5f:	c3                   	ret    

00800d60 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800d60:	55                   	push   %ebp
  800d61:	89 e5                	mov    %esp,%ebp
  800d63:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  800d66:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800d6d:	75 3c                	jne    800dab <set_pgfault_handler+0x4b>
		
		if ((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE),PTE_U|PTE_P|PTE_W)) < 0)
  800d6f:	83 ec 04             	sub    $0x4,%esp
  800d72:	6a 07                	push   $0x7
  800d74:	68 00 f0 bf ee       	push   $0xeebff000
  800d79:	6a 00                	push   $0x0
  800d7b:	e8 e8 f3 ff ff       	call   800168 <sys_page_alloc>
  800d80:	83 c4 10             	add    $0x10,%esp
  800d83:	85 c0                	test   %eax,%eax
  800d85:	79 12                	jns    800d99 <set_pgfault_handler+0x39>
		panic("sys_page_alloc: %e", r);
  800d87:	50                   	push   %eax
  800d88:	68 04 13 80 00       	push   $0x801304
  800d8d:	6a 20                	push   $0x20
  800d8f:	68 17 13 80 00       	push   $0x801317
  800d94:	e8 a3 f5 ff ff       	call   80033c <_panic>
	    sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  800d99:	83 ec 08             	sub    $0x8,%esp
  800d9c:	68 17 03 80 00       	push   $0x800317
  800da1:	6a 00                	push   $0x0
  800da3:	e8 c9 f4 ff ff       	call   800271 <sys_env_set_pgfault_upcall>
  800da8:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800dab:	8b 45 08             	mov    0x8(%ebp),%eax
  800dae:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800db3:	c9                   	leave  
  800db4:	c3                   	ret    
  800db5:	66 90                	xchg   %ax,%ax
  800db7:	66 90                	xchg   %ax,%ax
  800db9:	66 90                	xchg   %ax,%ax
  800dbb:	66 90                	xchg   %ax,%ax
  800dbd:	66 90                	xchg   %ax,%ax
  800dbf:	90                   	nop

00800dc0 <__udivdi3>:
  800dc0:	55                   	push   %ebp
  800dc1:	57                   	push   %edi
  800dc2:	56                   	push   %esi
  800dc3:	53                   	push   %ebx
  800dc4:	83 ec 1c             	sub    $0x1c,%esp
  800dc7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800dcb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800dcf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800dd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800dd7:	85 f6                	test   %esi,%esi
  800dd9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800ddd:	89 ca                	mov    %ecx,%edx
  800ddf:	89 f8                	mov    %edi,%eax
  800de1:	75 3d                	jne    800e20 <__udivdi3+0x60>
  800de3:	39 cf                	cmp    %ecx,%edi
  800de5:	0f 87 c5 00 00 00    	ja     800eb0 <__udivdi3+0xf0>
  800deb:	85 ff                	test   %edi,%edi
  800ded:	89 fd                	mov    %edi,%ebp
  800def:	75 0b                	jne    800dfc <__udivdi3+0x3c>
  800df1:	b8 01 00 00 00       	mov    $0x1,%eax
  800df6:	31 d2                	xor    %edx,%edx
  800df8:	f7 f7                	div    %edi
  800dfa:	89 c5                	mov    %eax,%ebp
  800dfc:	89 c8                	mov    %ecx,%eax
  800dfe:	31 d2                	xor    %edx,%edx
  800e00:	f7 f5                	div    %ebp
  800e02:	89 c1                	mov    %eax,%ecx
  800e04:	89 d8                	mov    %ebx,%eax
  800e06:	89 cf                	mov    %ecx,%edi
  800e08:	f7 f5                	div    %ebp
  800e0a:	89 c3                	mov    %eax,%ebx
  800e0c:	89 d8                	mov    %ebx,%eax
  800e0e:	89 fa                	mov    %edi,%edx
  800e10:	83 c4 1c             	add    $0x1c,%esp
  800e13:	5b                   	pop    %ebx
  800e14:	5e                   	pop    %esi
  800e15:	5f                   	pop    %edi
  800e16:	5d                   	pop    %ebp
  800e17:	c3                   	ret    
  800e18:	90                   	nop
  800e19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e20:	39 ce                	cmp    %ecx,%esi
  800e22:	77 74                	ja     800e98 <__udivdi3+0xd8>
  800e24:	0f bd fe             	bsr    %esi,%edi
  800e27:	83 f7 1f             	xor    $0x1f,%edi
  800e2a:	0f 84 98 00 00 00    	je     800ec8 <__udivdi3+0x108>
  800e30:	bb 20 00 00 00       	mov    $0x20,%ebx
  800e35:	89 f9                	mov    %edi,%ecx
  800e37:	89 c5                	mov    %eax,%ebp
  800e39:	29 fb                	sub    %edi,%ebx
  800e3b:	d3 e6                	shl    %cl,%esi
  800e3d:	89 d9                	mov    %ebx,%ecx
  800e3f:	d3 ed                	shr    %cl,%ebp
  800e41:	89 f9                	mov    %edi,%ecx
  800e43:	d3 e0                	shl    %cl,%eax
  800e45:	09 ee                	or     %ebp,%esi
  800e47:	89 d9                	mov    %ebx,%ecx
  800e49:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e4d:	89 d5                	mov    %edx,%ebp
  800e4f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e53:	d3 ed                	shr    %cl,%ebp
  800e55:	89 f9                	mov    %edi,%ecx
  800e57:	d3 e2                	shl    %cl,%edx
  800e59:	89 d9                	mov    %ebx,%ecx
  800e5b:	d3 e8                	shr    %cl,%eax
  800e5d:	09 c2                	or     %eax,%edx
  800e5f:	89 d0                	mov    %edx,%eax
  800e61:	89 ea                	mov    %ebp,%edx
  800e63:	f7 f6                	div    %esi
  800e65:	89 d5                	mov    %edx,%ebp
  800e67:	89 c3                	mov    %eax,%ebx
  800e69:	f7 64 24 0c          	mull   0xc(%esp)
  800e6d:	39 d5                	cmp    %edx,%ebp
  800e6f:	72 10                	jb     800e81 <__udivdi3+0xc1>
  800e71:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e75:	89 f9                	mov    %edi,%ecx
  800e77:	d3 e6                	shl    %cl,%esi
  800e79:	39 c6                	cmp    %eax,%esi
  800e7b:	73 07                	jae    800e84 <__udivdi3+0xc4>
  800e7d:	39 d5                	cmp    %edx,%ebp
  800e7f:	75 03                	jne    800e84 <__udivdi3+0xc4>
  800e81:	83 eb 01             	sub    $0x1,%ebx
  800e84:	31 ff                	xor    %edi,%edi
  800e86:	89 d8                	mov    %ebx,%eax
  800e88:	89 fa                	mov    %edi,%edx
  800e8a:	83 c4 1c             	add    $0x1c,%esp
  800e8d:	5b                   	pop    %ebx
  800e8e:	5e                   	pop    %esi
  800e8f:	5f                   	pop    %edi
  800e90:	5d                   	pop    %ebp
  800e91:	c3                   	ret    
  800e92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e98:	31 ff                	xor    %edi,%edi
  800e9a:	31 db                	xor    %ebx,%ebx
  800e9c:	89 d8                	mov    %ebx,%eax
  800e9e:	89 fa                	mov    %edi,%edx
  800ea0:	83 c4 1c             	add    $0x1c,%esp
  800ea3:	5b                   	pop    %ebx
  800ea4:	5e                   	pop    %esi
  800ea5:	5f                   	pop    %edi
  800ea6:	5d                   	pop    %ebp
  800ea7:	c3                   	ret    
  800ea8:	90                   	nop
  800ea9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800eb0:	89 d8                	mov    %ebx,%eax
  800eb2:	f7 f7                	div    %edi
  800eb4:	31 ff                	xor    %edi,%edi
  800eb6:	89 c3                	mov    %eax,%ebx
  800eb8:	89 d8                	mov    %ebx,%eax
  800eba:	89 fa                	mov    %edi,%edx
  800ebc:	83 c4 1c             	add    $0x1c,%esp
  800ebf:	5b                   	pop    %ebx
  800ec0:	5e                   	pop    %esi
  800ec1:	5f                   	pop    %edi
  800ec2:	5d                   	pop    %ebp
  800ec3:	c3                   	ret    
  800ec4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ec8:	39 ce                	cmp    %ecx,%esi
  800eca:	72 0c                	jb     800ed8 <__udivdi3+0x118>
  800ecc:	31 db                	xor    %ebx,%ebx
  800ece:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800ed2:	0f 87 34 ff ff ff    	ja     800e0c <__udivdi3+0x4c>
  800ed8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800edd:	e9 2a ff ff ff       	jmp    800e0c <__udivdi3+0x4c>
  800ee2:	66 90                	xchg   %ax,%ax
  800ee4:	66 90                	xchg   %ax,%ax
  800ee6:	66 90                	xchg   %ax,%ax
  800ee8:	66 90                	xchg   %ax,%ax
  800eea:	66 90                	xchg   %ax,%ax
  800eec:	66 90                	xchg   %ax,%ax
  800eee:	66 90                	xchg   %ax,%ax

00800ef0 <__umoddi3>:
  800ef0:	55                   	push   %ebp
  800ef1:	57                   	push   %edi
  800ef2:	56                   	push   %esi
  800ef3:	53                   	push   %ebx
  800ef4:	83 ec 1c             	sub    $0x1c,%esp
  800ef7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800efb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800eff:	8b 74 24 34          	mov    0x34(%esp),%esi
  800f03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800f07:	85 d2                	test   %edx,%edx
  800f09:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800f0d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f11:	89 f3                	mov    %esi,%ebx
  800f13:	89 3c 24             	mov    %edi,(%esp)
  800f16:	89 74 24 04          	mov    %esi,0x4(%esp)
  800f1a:	75 1c                	jne    800f38 <__umoddi3+0x48>
  800f1c:	39 f7                	cmp    %esi,%edi
  800f1e:	76 50                	jbe    800f70 <__umoddi3+0x80>
  800f20:	89 c8                	mov    %ecx,%eax
  800f22:	89 f2                	mov    %esi,%edx
  800f24:	f7 f7                	div    %edi
  800f26:	89 d0                	mov    %edx,%eax
  800f28:	31 d2                	xor    %edx,%edx
  800f2a:	83 c4 1c             	add    $0x1c,%esp
  800f2d:	5b                   	pop    %ebx
  800f2e:	5e                   	pop    %esi
  800f2f:	5f                   	pop    %edi
  800f30:	5d                   	pop    %ebp
  800f31:	c3                   	ret    
  800f32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f38:	39 f2                	cmp    %esi,%edx
  800f3a:	89 d0                	mov    %edx,%eax
  800f3c:	77 52                	ja     800f90 <__umoddi3+0xa0>
  800f3e:	0f bd ea             	bsr    %edx,%ebp
  800f41:	83 f5 1f             	xor    $0x1f,%ebp
  800f44:	75 5a                	jne    800fa0 <__umoddi3+0xb0>
  800f46:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800f4a:	0f 82 e0 00 00 00    	jb     801030 <__umoddi3+0x140>
  800f50:	39 0c 24             	cmp    %ecx,(%esp)
  800f53:	0f 86 d7 00 00 00    	jbe    801030 <__umoddi3+0x140>
  800f59:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f5d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f61:	83 c4 1c             	add    $0x1c,%esp
  800f64:	5b                   	pop    %ebx
  800f65:	5e                   	pop    %esi
  800f66:	5f                   	pop    %edi
  800f67:	5d                   	pop    %ebp
  800f68:	c3                   	ret    
  800f69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f70:	85 ff                	test   %edi,%edi
  800f72:	89 fd                	mov    %edi,%ebp
  800f74:	75 0b                	jne    800f81 <__umoddi3+0x91>
  800f76:	b8 01 00 00 00       	mov    $0x1,%eax
  800f7b:	31 d2                	xor    %edx,%edx
  800f7d:	f7 f7                	div    %edi
  800f7f:	89 c5                	mov    %eax,%ebp
  800f81:	89 f0                	mov    %esi,%eax
  800f83:	31 d2                	xor    %edx,%edx
  800f85:	f7 f5                	div    %ebp
  800f87:	89 c8                	mov    %ecx,%eax
  800f89:	f7 f5                	div    %ebp
  800f8b:	89 d0                	mov    %edx,%eax
  800f8d:	eb 99                	jmp    800f28 <__umoddi3+0x38>
  800f8f:	90                   	nop
  800f90:	89 c8                	mov    %ecx,%eax
  800f92:	89 f2                	mov    %esi,%edx
  800f94:	83 c4 1c             	add    $0x1c,%esp
  800f97:	5b                   	pop    %ebx
  800f98:	5e                   	pop    %esi
  800f99:	5f                   	pop    %edi
  800f9a:	5d                   	pop    %ebp
  800f9b:	c3                   	ret    
  800f9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fa0:	8b 34 24             	mov    (%esp),%esi
  800fa3:	bf 20 00 00 00       	mov    $0x20,%edi
  800fa8:	89 e9                	mov    %ebp,%ecx
  800faa:	29 ef                	sub    %ebp,%edi
  800fac:	d3 e0                	shl    %cl,%eax
  800fae:	89 f9                	mov    %edi,%ecx
  800fb0:	89 f2                	mov    %esi,%edx
  800fb2:	d3 ea                	shr    %cl,%edx
  800fb4:	89 e9                	mov    %ebp,%ecx
  800fb6:	09 c2                	or     %eax,%edx
  800fb8:	89 d8                	mov    %ebx,%eax
  800fba:	89 14 24             	mov    %edx,(%esp)
  800fbd:	89 f2                	mov    %esi,%edx
  800fbf:	d3 e2                	shl    %cl,%edx
  800fc1:	89 f9                	mov    %edi,%ecx
  800fc3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800fc7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800fcb:	d3 e8                	shr    %cl,%eax
  800fcd:	89 e9                	mov    %ebp,%ecx
  800fcf:	89 c6                	mov    %eax,%esi
  800fd1:	d3 e3                	shl    %cl,%ebx
  800fd3:	89 f9                	mov    %edi,%ecx
  800fd5:	89 d0                	mov    %edx,%eax
  800fd7:	d3 e8                	shr    %cl,%eax
  800fd9:	89 e9                	mov    %ebp,%ecx
  800fdb:	09 d8                	or     %ebx,%eax
  800fdd:	89 d3                	mov    %edx,%ebx
  800fdf:	89 f2                	mov    %esi,%edx
  800fe1:	f7 34 24             	divl   (%esp)
  800fe4:	89 d6                	mov    %edx,%esi
  800fe6:	d3 e3                	shl    %cl,%ebx
  800fe8:	f7 64 24 04          	mull   0x4(%esp)
  800fec:	39 d6                	cmp    %edx,%esi
  800fee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800ff2:	89 d1                	mov    %edx,%ecx
  800ff4:	89 c3                	mov    %eax,%ebx
  800ff6:	72 08                	jb     801000 <__umoddi3+0x110>
  800ff8:	75 11                	jne    80100b <__umoddi3+0x11b>
  800ffa:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800ffe:	73 0b                	jae    80100b <__umoddi3+0x11b>
  801000:	2b 44 24 04          	sub    0x4(%esp),%eax
  801004:	1b 14 24             	sbb    (%esp),%edx
  801007:	89 d1                	mov    %edx,%ecx
  801009:	89 c3                	mov    %eax,%ebx
  80100b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80100f:	29 da                	sub    %ebx,%edx
  801011:	19 ce                	sbb    %ecx,%esi
  801013:	89 f9                	mov    %edi,%ecx
  801015:	89 f0                	mov    %esi,%eax
  801017:	d3 e0                	shl    %cl,%eax
  801019:	89 e9                	mov    %ebp,%ecx
  80101b:	d3 ea                	shr    %cl,%edx
  80101d:	89 e9                	mov    %ebp,%ecx
  80101f:	d3 ee                	shr    %cl,%esi
  801021:	09 d0                	or     %edx,%eax
  801023:	89 f2                	mov    %esi,%edx
  801025:	83 c4 1c             	add    $0x1c,%esp
  801028:	5b                   	pop    %ebx
  801029:	5e                   	pop    %esi
  80102a:	5f                   	pop    %edi
  80102b:	5d                   	pop    %ebp
  80102c:	c3                   	ret    
  80102d:	8d 76 00             	lea    0x0(%esi),%esi
  801030:	29 f9                	sub    %edi,%ecx
  801032:	19 d6                	sbb    %edx,%esi
  801034:	89 74 24 04          	mov    %esi,0x4(%esp)
  801038:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80103c:	e9 18 ff ff ff       	jmp    800f59 <__umoddi3+0x69>
