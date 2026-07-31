	.file	"calculator.c"
	.text
	.def	strtod;	.scl	3;	.type	32;	.endef
	.seh_proc	strtod
strtod:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	__mingw_strtod
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.globl	history
	.bss
	.align 32
history:
	.space 26400
	.globl	history_count
	.align 4
history_count:
	.space 4
	.globl	p
	.align 8
p:
	.space 8
	.text
	.globl	skip_spaces
	.def	skip_spaces;	.scl	2;	.type	32;	.endef
	.seh_proc	skip_spaces
skip_spaces:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	jmp	.L4
.L5:
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
.L4:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$32, %al
	je	.L5
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$9, %al
	je	.L5
	nop
	nop
	popq	%rbp
	ret
	.seh_endproc
	.globl	parse_number
	.def	parse_number;	.scl	2;	.type	32;	.endef
	.seh_proc	parse_number
parse_number:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	call	skip_spaces
	movq	p(%rip), %rax
	leaq	-16(%rbp), %rdx
	movq	%rax, %rcx
	call	strtod
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movq	%rax, p(%rip)
	movsd	-8(%rbp), %xmm0
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC1:
	.ascii "Error: missing closing parenthesis\0"
	.align 8
.LC2:
	.ascii "Error: unrecognized character %c\12\0"
	.text
	.globl	parse_factor
	.def	parse_factor;	.scl	2;	.type	32;	.endef
	.seh_proc	parse_factor
parse_factor:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$43, %al
	jne	.L9
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	jmp	.L10
.L9:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L11
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	movq	.LC0(%rip), %xmm0
	movq	%rax, %xmm1
	xorpd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movsd	%xmm0, -8(%rbp)
	movq	-8(%rbp), %rax
	jmp	.L10
.L11:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$40, %al
	jne	.L12
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_expression
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$41, %al
	jne	.L13
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	jmp	.L14
.L13:
	leaq	.LC1(%rip), %rax
	movq	%rax, %rcx
	call	puts
.L14:
	movq	-8(%rbp), %rax
	jmp	.L10
.L12:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movzbl	%al, %eax
	subl	$48, %eax
	cmpl	$9, %eax
	jbe	.L15
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$46, %al
	jne	.L16
.L15:
	call	parse_number
	movq	%xmm0, %rax
	jmp	.L10
.L16:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movsbl	%al, %eax
	leaq	.LC2(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
	movq	.LC3(%rip), %rax
.L10:
	movq	%rax, %xmm0
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC4:
	.ascii "Step: %.6g * %.6g = %.6g\12\0"
.LC5:
	.ascii "Error: division by zero\0"
.LC6:
	.ascii "Step: %.6g / %.6g = %.6g\12\0"
	.text
	.globl	parse_term
	.def	parse_term;	.scl	2;	.type	32;	.endef
	.seh_proc	parse_term
parse_term:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	call	parse_factor
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
.L25:
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$42, %al
	je	.L18
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$47, %al
	jne	.L28
.L18:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movb	%al, -9(%rbp)
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	movq	%rax, -24(%rbp)
	cmpb	$42, -9(%rbp)
	jne	.L20
	movsd	-8(%rbp), %xmm0
	mulsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC4(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	jmp	.L25
.L20:
	pxor	%xmm0, %xmm0
	ucomisd	-24(%rbp), %xmm0
	jp	.L22
	pxor	%xmm0, %xmm0
	ucomisd	-24(%rbp), %xmm0
	jne	.L22
	leaq	.LC5(%rip), %rax
	movq	%rax, %rcx
	call	puts
	pxor	%xmm0, %xmm0
	jmp	.L24
.L22:
	movsd	-8(%rbp), %xmm0
	divsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC6(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	jmp	.L25
.L28:
	nop
	movsd	-8(%rbp), %xmm0
.L24:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC7:
	.ascii "Step: %.6g + %.6g = %.6g\12\0"
.LC8:
	.ascii "Step: %.6g - %.6g = %.6g\12\0"
	.text
	.globl	parse_expression
	.def	parse_expression;	.scl	2;	.type	32;	.endef
	.seh_proc	parse_expression
parse_expression:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	call	parse_term
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
.L34:
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$43, %al
	je	.L30
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L37
.L30:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movb	%al, -9(%rbp)
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_term
	movq	%xmm0, %rax
	movq	%rax, -24(%rbp)
	cmpb	$43, -9(%rbp)
	jne	.L32
	movsd	-8(%rbp), %xmm0
	addsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC7(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	jmp	.L34
.L32:
	movsd	-8(%rbp), %xmm0
	subsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC8(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	jmp	.L34
.L37:
	nop
	movsd	-8(%rbp), %xmm0
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC9:
	.ascii "Warning: unparsed content after expression: %s\12\0"
	.text
	.globl	calculate_expression
	.def	calculate_expression;	.scl	2;	.type	32;	.endef
	.seh_proc	calculate_expression
calculate_expression:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, p(%rip)
	call	parse_expression
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L39
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	je	.L39
	movq	p(%rip), %rax
	leaq	.LC9(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_printf
.L39:
	movsd	-8(%rbp), %xmm0
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC10:
	.ascii "r\0"
.LC11:
	.ascii "history.txt\0"
.LC12:
	.ascii " = \0"
	.text
	.globl	load_history
	.def	load_history;	.scl	2;	.type	32;	.endef
	.seh_proc	load_history
load_history:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$568, %rsp
	.seh_stackalloc	568
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movl	$0, history_count(%rip)
	leaq	.LC10(%rip), %rdx
	leaq	.LC11(%rip), %rax
	movq	%rax, %rcx
	call	fopen
	movq	%rax, 424(%rbp)
	cmpq	$0, 424(%rbp)
	je	.L47
	jmp	.L44
.L46:
	leaq	.LC12(%rip), %rdx
	leaq	-96(%rbp), %rax
	movq	%rax, %rcx
	call	strstr
	movq	%rax, 416(%rbp)
	cmpq	$0, 416(%rbp)
	je	.L44
	movq	416(%rbp), %rax
	movb	$0, (%rax)
	movl	history_count(%rip), %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	history(%rip), %rdx
	leaq	(%rax,%rdx), %rcx
	leaq	-96(%rbp), %rax
	movq	%rax, %rdx
	call	strcpy
	movq	416(%rbp), %rax
	addq	$3, %rax
	movl	history_count(%rip), %ebx
	movq	%rax, %rcx
	call	atof
	movq	%xmm0, %rax
	movslq	%ebx, %rdx
	imulq	$264, %rdx, %rdx
	leaq	256+history(%rip), %rcx
	movq	%rax, (%rdx,%rcx)
	movl	history_count(%rip), %eax
	addl	$1, %eax
	movl	%eax, history_count(%rip)
.L44:
	movq	424(%rbp), %rdx
	leaq	-96(%rbp), %rax
	movq	%rdx, %r8
	movl	$512, %edx
	movq	%rax, %rcx
	call	fgets
	testq	%rax, %rax
	je	.L45
	movl	history_count(%rip), %eax
	cmpl	$99, %eax
	jle	.L46
.L45:
	movq	424(%rbp), %rax
	movq	%rax, %rcx
	call	fclose
	jmp	.L41
.L47:
	nop
.L41:
	addq	$568, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC13:
	.ascii "a\0"
	.align 8
.LC14:
	.ascii "Error: cannot open history file\0"
.LC15:
	.ascii "%s = %.10g\12\0"
	.text
	.globl	save_one_history
	.def	save_one_history;	.scl	2;	.type	32;	.endef
	.seh_proc	save_one_history
save_one_history:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movsd	%xmm1, 24(%rbp)
	leaq	.LC13(%rip), %rdx
	leaq	.LC11(%rip), %rax
	movq	%rax, %rcx
	call	fopen
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	jne	.L49
	leaq	.LC14(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L48
.L49:
	movsd	24(%rbp), %xmm0
	movq	24(%rbp), %r8
	movq	16(%rbp), %rcx
	leaq	.LC15(%rip), %rdx
	movq	-8(%rbp), %rax
	movapd	%xmm0, %xmm3
	movq	%r8, %r9
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	__mingw_fprintf
	movq	-8(%rbp), %rax
	movq	%rax, %rcx
	call	fclose
	nop
.L48:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC16:
	.ascii "History full, saving to file only\0"
	.text
	.globl	add_history
	.def	add_history;	.scl	2;	.type	32;	.endef
	.seh_proc	add_history
add_history:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movsd	%xmm1, 24(%rbp)
	movl	history_count(%rip), %eax
	cmpl	$99, %eax
	jle	.L52
	leaq	.LC16(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movsd	24(%rbp), %xmm0
	movq	16(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	save_one_history
	jmp	.L51
.L52:
	movl	history_count(%rip), %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	history(%rip), %rdx
	leaq	(%rax,%rdx), %rcx
	movq	16(%rbp), %rax
	movq	%rax, %rdx
	call	strcpy
	movl	history_count(%rip), %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	256+history(%rip), %rdx
	movsd	24(%rbp), %xmm0
	movsd	%xmm0, (%rax,%rdx)
	movl	history_count(%rip), %eax
	addl	$1, %eax
	movl	%eax, history_count(%rip)
	movsd	24(%rbp), %xmm0
	movq	16(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	save_one_history
	nop
.L51:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC17:
	.ascii "No history records\0"
.LC18:
	.ascii "Enter page number (1 to %d): \0"
.LC19:
	.ascii "%d\0"
.LC20:
	.ascii "Invalid page number\0"
.LC21:
	.ascii "Page %d history:\12\0"
.LC22:
	.ascii "%d. %s = %.10g\12\0"
	.text
	.globl	show_history_page
	.def	show_history_page;	.scl	2;	.type	32;	.endef
	.seh_proc	show_history_page
show_history_page:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	movl	history_count(%rip), %eax
	testl	%eax, %eax
	jne	.L55
	leaq	.LC17(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L54
.L55:
	movl	history_count(%rip), %eax
	addl	$9, %eax
	movslq	%eax, %rdx
	imulq	$1717986919, %rdx, %rdx
	shrq	$32, %rdx
	movl	%edx, %ecx
	sarl	$2, %ecx
	cltd
	movl	%ecx, %eax
	subl	%edx, %eax
	movl	%eax, -12(%rbp)
	movl	-12(%rbp), %eax
	leaq	.LC18(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
	leaq	-20(%rbp), %rax
	leaq	.LC19(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	call	getchar
	movl	-20(%rbp), %eax
	testl	%eax, %eax
	jle	.L57
	movl	-20(%rbp), %eax
	cmpl	%eax, -12(%rbp)
	jge	.L58
.L57:
	leaq	.LC20(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L54
.L58:
	movl	-20(%rbp), %eax
	leal	-1(%rax), %edx
	movl	%edx, %eax
	sall	$2, %eax
	addl	%edx, %eax
	addl	%eax, %eax
	movl	%eax, -16(%rbp)
	movl	-16(%rbp), %eax
	addl	$10, %eax
	movl	%eax, -4(%rbp)
	movl	history_count(%rip), %eax
	cmpl	%eax, -4(%rbp)
	jle	.L59
	movl	history_count(%rip), %eax
	movl	%eax, -4(%rbp)
.L59:
	movl	-20(%rbp), %eax
	leaq	.LC21(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
	movl	-16(%rbp), %eax
	movl	%eax, -8(%rbp)
	jmp	.L60
.L61:
	movl	-8(%rbp), %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	256+history(%rip), %rdx
	movsd	(%rax,%rdx), %xmm0
	movl	-8(%rbp), %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	history(%rip), %rdx
	leaq	(%rax,%rdx), %rcx
	movl	-8(%rbp), %eax
	leal	1(%rax), %edx
	movapd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movq	%xmm1, %r8
	leaq	.LC22(%rip), %rax
	movapd	%xmm0, %xmm3
	movq	%r8, %r9
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	__mingw_printf
	addl	$1, -8(%rbp)
.L60:
	movl	-8(%rbp), %eax
	cmpl	-4(%rbp), %eax
	jl	.L61
.L54:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC23:
	.ascii "History cleared\0"
	.text
	.globl	clear_history
	.def	clear_history;	.scl	2;	.type	32;	.endef
	.seh_proc	clear_history
clear_history:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movl	$0, history_count(%rip)
	leaq	.LC11(%rip), %rax
	movq	%rax, %rcx
	call	remove
	leaq	.LC23(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC24:
	.ascii "Enter expression: \0"
.LC25:
	.ascii "\12\0"
.LC26:
	.ascii "Expression cannot be empty\0"
.LC27:
	.ascii "Calculation steps:\0"
.LC28:
	.ascii "Final result: %.10g\12\0"
	.text
	.globl	input_and_calculate
	.def	input_and_calculate;	.scl	2;	.type	32;	.endef
	.seh_proc	input_and_calculate
input_and_calculate:
	pushq	%rbp
	.seh_pushreg	%rbp
	subq	$304, %rsp
	.seh_stackalloc	304
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	leaq	.LC24(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	movl	$0, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rdx
	leaq	-96(%rbp), %rax
	movq	%rdx, %r8
	movl	$256, %edx
	movq	%rax, %rcx
	call	fgets
	leaq	.LC25(%rip), %rdx
	leaq	-96(%rbp), %rax
	movq	%rax, %rcx
	call	strcspn
	movb	$0, -96(%rbp,%rax)
	leaq	-96(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	jne	.L65
	leaq	.LC26(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L64
.L65:
	leaq	.LC27(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	-96(%rbp), %rax
	movq	%rax, %rcx
	call	calculate_expression
	movq	%xmm0, %rax
	movq	%rax, 168(%rbp)
	movsd	168(%rbp), %xmm0
	movq	168(%rbp), %rdx
	leaq	.LC28(%rip), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	168(%rbp), %xmm0
	leaq	-96(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	add_history
	nop
.L64:
	addq	$304, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC29:
	.ascii "Need at least 2 history records for combined calculation\0"
	.align 8
.LC30:
	.ascii "Select first history record number: \0"
	.align 8
.LC31:
	.ascii "Select second history record number: \0"
.LC32:
	.ascii "Invalid record number\0"
.LC33:
	.ascii "(%s)*(%s)\0"
.LC34:
	.ascii "Combined expression: %s\12\0"
	.text
	.globl	combine_history_and_calculate
	.def	combine_history_and_calculate;	.scl	2;	.type	32;	.endef
	.seh_proc	combine_history_and_calculate
combine_history_and_calculate:
	pushq	%rbp
	.seh_pushreg	%rbp
	subq	$592, %rsp
	.seh_stackalloc	592
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movl	history_count(%rip), %eax
	cmpl	$1, %eax
	jg	.L68
	leaq	.LC29(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L67
.L68:
	call	show_history_page
	leaq	.LC30(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	leaq	452(%rbp), %rax
	leaq	.LC19(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	leaq	.LC31(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	leaq	448(%rbp), %rax
	leaq	.LC19(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	call	getchar
	movl	452(%rbp), %eax
	testl	%eax, %eax
	jle	.L70
	movl	452(%rbp), %edx
	movl	history_count(%rip), %eax
	cmpl	%eax, %edx
	jg	.L70
	movl	448(%rbp), %eax
	testl	%eax, %eax
	jle	.L70
	movl	448(%rbp), %edx
	movl	history_count(%rip), %eax
	cmpl	%eax, %edx
	jle	.L71
.L70:
	leaq	.LC32(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L67
.L71:
	movl	448(%rbp), %eax
	subl	$1, %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	history(%rip), %rdx
	addq	%rax, %rdx
	movl	452(%rbp), %eax
	subl	$1, %eax
	cltq
	imulq	$264, %rax, %rax
	leaq	history(%rip), %rcx
	leaq	(%rax,%rcx), %r8
	leaq	.LC33(%rip), %rcx
	leaq	-80(%rbp), %rax
	movq	%rdx, 32(%rsp)
	movq	%r8, %r9
	movq	%rcx, %r8
	movl	$528, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	leaq	-80(%rbp), %rax
	leaq	.LC34(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_printf
	leaq	.LC27(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	-80(%rbp), %rax
	movq	%rax, %rcx
	call	calculate_expression
	movq	%xmm0, %rax
	movq	%rax, 456(%rbp)
	movsd	456(%rbp), %xmm0
	movq	456(%rbp), %rdx
	leaq	.LC28(%rip), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	456(%rbp), %xmm0
	leaq	-80(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	add_history
	nop
.L67:
	addq	$592, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC35:
	.ascii "\12===== Arithmetic Expression Calculator =====\0"
.LC36:
	.ascii "1. Calculate expression\0"
.LC37:
	.ascii "2. View history\0"
.LC38:
	.ascii "3. Clear history\0"
	.align 8
.LC39:
	.ascii "4. Multiply two history records\0"
.LC40:
	.ascii "5. Exit\0"
.LC41:
	.ascii "Select: \0"
	.text
	.globl	print_menu
	.def	print_menu;	.scl	2;	.type	32;	.endef
	.seh_proc	print_menu
print_menu:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	leaq	.LC35(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC36(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC37(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC38(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC39(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC40(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC41(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC42:
	.ascii "Input error\0"
.LC43:
	.ascii "Program exit\0"
.LC44:
	.ascii "Invalid menu option\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	call	__main
	call	load_history
.L85:
	call	print_menu
	leaq	-4(%rbp), %rax
	leaq	.LC19(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L75
	leaq	.LC42(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L76:
	call	getchar
	cmpl	$10, %eax
	jne	.L76
	jmp	.L77
.L75:
	call	getchar
	movl	-4(%rbp), %eax
	cmpl	$5, %eax
	je	.L78
	cmpl	$5, %eax
	jg	.L79
	cmpl	$4, %eax
	je	.L80
	cmpl	$4, %eax
	jg	.L79
	cmpl	$3, %eax
	je	.L81
	cmpl	$3, %eax
	jg	.L79
	cmpl	$1, %eax
	je	.L82
	cmpl	$2, %eax
	je	.L83
	jmp	.L79
.L82:
	call	input_and_calculate
	jmp	.L77
.L83:
	call	show_history_page
	jmp	.L77
.L81:
	call	clear_history
	jmp	.L77
.L80:
	call	combine_history_and_calculate
	jmp	.L77
.L78:
	leaq	.LC43(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movl	$0, %eax
	jmp	.L86
.L79:
	leaq	.LC44(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L77:
	jmp	.L85
.L86:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 16
.LC0:
	.long	0
	.long	-2147483648
	.long	0
	.long	0
	.align 8
.LC3:
	.long	0
	.long	0
	.def	__main;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (Rev5, Built by MSYS2 project) 16.1.0"
	.def	__mingw_strtod;	.scl	2;	.type	32;	.endef
	.def	puts;	.scl	2;	.type	32;	.endef
	.def	fopen;	.scl	2;	.type	32;	.endef
	.def	strstr;	.scl	2;	.type	32;	.endef
	.def	strcpy;	.scl	2;	.type	32;	.endef
	.def	atof;	.scl	2;	.type	32;	.endef
	.def	fgets;	.scl	2;	.type	32;	.endef
	.def	fclose;	.scl	2;	.type	32;	.endef
	.def	getchar;	.scl	2;	.type	32;	.endef
	.def	remove;	.scl	2;	.type	32;	.endef
	.def	strcspn;	.scl	2;	.type	32;	.endef
