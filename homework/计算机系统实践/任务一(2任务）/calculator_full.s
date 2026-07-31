	.file	"calculator_full.c"
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
.lcomm history,52000,32
.lcomm history_count,4,4
.lcomm p,8,8
.lcomm parse_error,4,4
.lcomm last_expr,512,32
	.def	copy_string;	.scl	3;	.type	32;	.endef
	.seh_proc	copy_string
copy_string:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	cmpq	$0, 24(%rbp)
	je	.L6
	movq	24(%rbp), %rax
	leaq	-1(%rax), %rcx
	movq	32(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	strncpy
	movq	24(%rbp), %rax
	leaq	-1(%rax), %rdx
	movq	16(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	jmp	.L3
.L6:
	nop
.L3:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.def	skip_spaces;	.scl	3;	.type	32;	.endef
	.seh_proc	skip_spaces
skip_spaces:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	jmp	.L8
.L9:
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
.L8:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$32, %al
	je	.L9
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$9, %al
	je	.L9
	nop
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC0:
	.ascii "Error: invalid number\0"
	.text
	.def	parse_number;	.scl	3;	.type	32;	.endef
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
	movq	-16(%rbp), %rdx
	movq	p(%rip), %rax
	cmpq	%rax, %rdx
	jne	.L11
	leaq	.LC0(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movl	$1, parse_error(%rip)
	pxor	%xmm0, %xmm0
	jmp	.L13
.L11:
	movq	-16(%rbp), %rax
	movq	%rax, p(%rip)
	movsd	-8(%rbp), %xmm0
.L13:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC3:
	.ascii "Error: missing closing parenthesis\0"
	.align 8
.LC4:
	.ascii "Error: expression is incomplete\0"
	.align 8
.LC5:
	.ascii "Error: unrecognized character %c\12\0"
	.text
	.def	parse_factor;	.scl	3;	.type	32;	.endef
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
	jne	.L15
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	jmp	.L16
.L15:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L17
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	movq	.LC2(%rip), %xmm0
	movq	%rax, %xmm1
	xorpd	%xmm0, %xmm1
	movq	%xmm1, %rax
	jmp	.L16
.L17:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$40, %al
	jne	.L18
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
	jne	.L19
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	jmp	.L20
.L19:
	leaq	.LC3(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movl	$1, parse_error(%rip)
.L20:
	movq	-8(%rbp), %rax
	jmp	.L16
.L18:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movzbl	%al, %eax
	subl	$48, %eax
	cmpl	$9, %eax
	jbe	.L21
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$46, %al
	jne	.L22
.L21:
	call	parse_number
	movq	%xmm0, %rax
	jmp	.L16
.L22:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L23
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	jne	.L24
.L23:
	leaq	.LC4(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L25
.L24:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movsbl	%al, %eax
	leaq	.LC5(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
.L25:
	movl	$1, parse_error(%rip)
	movq	.LC1(%rip), %rax
.L16:
	movq	%rax, %xmm0
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC6:
	.ascii "Step: %.6g * %.6g = %.6g\12\0"
.LC7:
	.ascii "Error: division by zero\0"
.LC8:
	.ascii "Step: %.6g / %.6g = %.6g\12\0"
	.text
	.def	parse_term;	.scl	3;	.type	32;	.endef
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
	jmp	.L27
.L35:
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$42, %al
	je	.L28
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$47, %al
	jne	.L37
.L28:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movb	%al, -9(%rbp)
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_factor
	movq	%xmm0, %rax
	movq	%rax, -24(%rbp)
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	je	.L30
	pxor	%xmm0, %xmm0
	jmp	.L31
.L30:
	cmpb	$42, -9(%rbp)
	jne	.L32
	movsd	-8(%rbp), %xmm0
	mulsd	-24(%rbp), %xmm0
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
	jmp	.L27
.L32:
	pxor	%xmm0, %xmm0
	ucomisd	-24(%rbp), %xmm0
	jp	.L33
	pxor	%xmm0, %xmm0
	ucomisd	-24(%rbp), %xmm0
	jne	.L33
	leaq	.LC7(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movl	$1, parse_error(%rip)
	pxor	%xmm0, %xmm0
	jmp	.L31
.L33:
	movsd	-8(%rbp), %xmm0
	divsd	-24(%rbp), %xmm0
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
.L27:
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	je	.L35
	jmp	.L29
.L37:
	nop
.L29:
	movsd	-8(%rbp), %xmm0
.L31:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC9:
	.ascii "Step: %.6g + %.6g = %.6g\12\0"
.LC10:
	.ascii "Step: %.6g - %.6g = %.6g\12\0"
	.text
	.def	parse_expression;	.scl	3;	.type	32;	.endef
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
	jmp	.L39
.L45:
	call	skip_spaces
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$43, %al
	je	.L40
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L46
.L40:
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	movb	%al, -9(%rbp)
	movq	p(%rip), %rax
	addq	$1, %rax
	movq	%rax, p(%rip)
	call	parse_term
	movq	%xmm0, %rax
	movq	%rax, -24(%rbp)
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	je	.L42
	pxor	%xmm0, %xmm0
	jmp	.L43
.L42:
	cmpb	$43, -9(%rbp)
	jne	.L44
	movsd	-8(%rbp), %xmm0
	addsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC9(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	jmp	.L39
.L44:
	movsd	-8(%rbp), %xmm0
	subsd	-24(%rbp), %xmm0
	movsd	%xmm0, -32(%rbp)
	movsd	-32(%rbp), %xmm2
	movq	-32(%rbp), %r8
	movsd	-24(%rbp), %xmm1
	movq	-24(%rbp), %rcx
	movsd	-8(%rbp), %xmm0
	movq	-8(%rbp), %rdx
	leaq	.LC10(%rip), %rax
	movapd	%xmm2, %xmm3
	movq	%r8, %r9
	movapd	%xmm1, %xmm2
	movq	%rcx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-32(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
.L39:
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	je	.L45
	jmp	.L41
.L46:
	nop
.L41:
	movsd	-8(%rbp), %xmm0
.L43:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC11:
	.ascii "Error: unparsed content after expression: %s\12\0"
	.text
	.def	calculate_expression;	.scl	3;	.type	32;	.endef
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
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, p(%rip)
	movl	$0, parse_error(%rip)
	call	parse_expression
	movq	%xmm0, %rax
	movq	%rax, -8(%rbp)
	call	skip_spaces
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	jne	.L48
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L48
	movq	p(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	je	.L48
	movq	p(%rip), %rax
	leaq	.LC11(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_printf
	movl	$1, parse_error(%rip)
.L48:
	movl	parse_error(%rip), %eax
	testl	%eax, %eax
	je	.L49
	movl	$0, %eax
	jmp	.L50
.L49:
	movq	24(%rbp), %rax
	movsd	-8(%rbp), %xmm0
	movsd	%xmm0, (%rax)
	movl	$1, %eax
.L50:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC12:
	.ascii "r\0"
.LC13:
	.ascii "history.txt\0"
.LC14:
	.ascii " = \0"
	.text
	.def	load_history;	.scl	3;	.type	32;	.endef
	.seh_proc	load_history
load_history:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$1096, %rsp
	.seh_stackalloc	1096
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movl	$0, history_count(%rip)
	leaq	.LC12(%rip), %rdx
	leaq	.LC13(%rip), %rax
	movq	%rax, %rcx
	call	fopen
	movq	%rax, 944(%rbp)
	cmpq	$0, 944(%rbp)
	je	.L60
	jmp	.L54
.L59:
	leaq	.LC14(%rip), %rdx
	leaq	-96(%rbp), %rax
	movq	%rax, %rcx
	call	strstr
	movq	%rax, 936(%rbp)
	cmpq	$0, 936(%rbp)
	je	.L54
	movq	936(%rbp), %rax
	movb	$0, (%rax)
	leaq	-96(%rbp), %rax
	movq	%rax, %rcx
	call	strlen
	movq	%rax, 952(%rbp)
	jmp	.L55
.L57:
	movq	952(%rbp), %rax
	subq	$1, %rax
	movb	$0, -96(%rbp,%rax)
	subq	$1, 952(%rbp)
.L55:
	cmpq	$0, 952(%rbp)
	je	.L56
	movq	952(%rbp), %rax
	subq	$1, %rax
	movzbl	-96(%rbp,%rax), %eax
	cmpb	$13, %al
	je	.L57
	movq	952(%rbp), %rax
	subq	$1, %rax
	movzbl	-96(%rbp,%rax), %eax
	cmpb	$10, %al
	je	.L57
.L56:
	movl	history_count(%rip), %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	history(%rip), %rdx
	addq	%rdx, %rax
	leaq	-96(%rbp), %rdx
	movq	%rdx, %r8
	movl	$512, %edx
	movq	%rax, %rcx
	call	copy_string
	movq	936(%rbp), %rax
	addq	$3, %rax
	movl	history_count(%rip), %ebx
	movq	%rax, %rcx
	call	atof
	movq	%xmm0, %rax
	movslq	%ebx, %rdx
	imulq	$520, %rdx, %rdx
	leaq	512+history(%rip), %rcx
	movq	%rax, (%rdx,%rcx)
	leaq	-96(%rbp), %rdx
	leaq	last_expr(%rip), %rax
	movq	%rdx, %r8
	movl	$512, %edx
	movq	%rax, %rcx
	call	copy_string
	movl	history_count(%rip), %eax
	addl	$1, %eax
	movl	%eax, history_count(%rip)
.L54:
	movq	944(%rbp), %rdx
	leaq	-96(%rbp), %rax
	movq	%rdx, %r8
	movl	$1024, %edx
	movq	%rax, %rcx
	call	fgets
	testq	%rax, %rax
	je	.L58
	movl	history_count(%rip), %eax
	cmpl	$99, %eax
	jle	.L59
.L58:
	movq	944(%rbp), %rax
	movq	%rax, %rcx
	call	fclose
	jmp	.L51
.L60:
	nop
.L51:
	addq	$1096, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC15:
	.ascii "a\0"
	.align 8
.LC16:
	.ascii "Error: cannot open history file\0"
.LC17:
	.ascii "%s = %.10g\12\0"
	.text
	.def	save_one_history;	.scl	3;	.type	32;	.endef
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
	leaq	.LC15(%rip), %rdx
	leaq	.LC13(%rip), %rax
	movq	%rax, %rcx
	call	fopen
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	jne	.L62
	leaq	.LC16(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L61
.L62:
	movsd	24(%rbp), %xmm0
	movq	24(%rbp), %r8
	movq	16(%rbp), %rcx
	leaq	.LC17(%rip), %rdx
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
.L61:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC18:
	.ascii "History memory is full, saving to file only\0"
	.text
	.def	add_history;	.scl	3;	.type	32;	.endef
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
	jg	.L65
	movl	history_count(%rip), %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	history(%rip), %rdx
	addq	%rdx, %rax
	movq	16(%rbp), %rdx
	movq	%rdx, %r8
	movl	$512, %edx
	movq	%rax, %rcx
	call	copy_string
	movl	history_count(%rip), %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	512+history(%rip), %rdx
	movsd	24(%rbp), %xmm0
	movsd	%xmm0, (%rax,%rdx)
	movl	history_count(%rip), %eax
	addl	$1, %eax
	movl	%eax, history_count(%rip)
	jmp	.L66
.L65:
	leaq	.LC18(%rip), %rax
	movq	%rax, %rcx
	call	puts
.L66:
	movq	16(%rbp), %rdx
	leaq	last_expr(%rip), %rax
	movq	%rdx, %r8
	movl	$512, %edx
	movq	%rax, %rcx
	call	copy_string
	movsd	24(%rbp), %xmm0
	movq	16(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	save_one_history
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC19:
	.ascii "No history records\0"
.LC20:
	.ascii "Enter page number (1 to %d): \0"
.LC21:
	.ascii "%d\0"
.LC22:
	.ascii "Invalid page number\0"
.LC23:
	.ascii "Page %d history:\12\0"
.LC24:
	.ascii "%d. %s = %.10g\12\0"
	.text
	.def	show_history_page;	.scl	3;	.type	32;	.endef
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
	jne	.L68
	leaq	.LC19(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L67
.L68:
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
	leaq	.LC20(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
	leaq	-20(%rbp), %rax
	leaq	.LC21(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L70
	leaq	.LC22(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L71:
	call	getchar
	cmpl	$10, %eax
	jne	.L71
	jmp	.L67
.L70:
	call	getchar
	movl	-20(%rbp), %eax
	testl	%eax, %eax
	jle	.L72
	movl	-20(%rbp), %eax
	cmpl	%eax, -12(%rbp)
	jge	.L73
.L72:
	leaq	.LC22(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L67
.L73:
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
	jle	.L74
	movl	history_count(%rip), %eax
	movl	%eax, -4(%rbp)
.L74:
	movl	-20(%rbp), %eax
	leaq	.LC23(%rip), %rcx
	movl	%eax, %edx
	call	__mingw_printf
	movl	-16(%rbp), %eax
	movl	%eax, -8(%rbp)
	jmp	.L75
.L76:
	movl	-8(%rbp), %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	512+history(%rip), %rdx
	movsd	(%rax,%rdx), %xmm0
	movl	-8(%rbp), %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	history(%rip), %rdx
	leaq	(%rax,%rdx), %rcx
	movl	-8(%rbp), %eax
	leal	1(%rax), %edx
	movapd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movq	%xmm1, %r8
	leaq	.LC24(%rip), %rax
	movapd	%xmm0, %xmm3
	movq	%r8, %r9
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	__mingw_printf
	addl	$1, -8(%rbp)
.L75:
	movl	-8(%rbp), %eax
	cmpl	-4(%rbp), %eax
	jl	.L76
.L67:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC25:
	.ascii "History cleared\0"
	.text
	.def	clear_history;	.scl	3;	.type	32;	.endef
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
	movb	$0, last_expr(%rip)
	leaq	.LC13(%rip), %rax
	movq	%rax, %rcx
	call	remove
	leaq	.LC25(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC26:
	.ascii "\15%s%s\0"
	.text
	.def	redraw_input_line;	.scl	3;	.type	32;	.endef
	.seh_proc	redraw_input_line
redraw_input_line:
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
	leaq	.LC26(%rip), %rcx
	movq	%rdx, %r8
	movq	%rax, %rdx
	call	__mingw_printf
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC27:
	.ascii "Enter expression (press Up Arrow for last expression): \0"
.LC28:
	.ascii "%s\0"
.LC29:
	.ascii "\10 \10\0"
.LC30:
	.ascii "\12No previous expression\12%s%s\0"
	.text
	.def	read_expression_line;	.scl	3;	.type	32;	.endef
	.seh_proc	read_expression_line
read_expression_line:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	leaq	.LC27(%rip), %rax
	movq	%rax, -24(%rbp)
	movq	$0, -8(%rbp)
	cmpq	$0, 24(%rbp)
	jne	.L81
	movl	$0, %eax
	jmp	.L82
.L81:
	movq	16(%rbp), %rax
	movb	$0, (%rax)
	movq	-24(%rbp), %rax
	leaq	.LC28(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_printf
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
.L96:
	movq	__imp__getch(%rip), %rax
	call	*%rax
	movl	%eax, -28(%rbp)
	cmpl	$13, -28(%rbp)
	je	.L83
	cmpl	$10, -28(%rbp)
	jne	.L84
.L83:
	movl	$10, %ecx
	call	putchar
	movq	16(%rbp), %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	movl	$1, %eax
	jmp	.L82
.L84:
	cmpl	$8, -28(%rbp)
	je	.L85
	cmpl	$127, -28(%rbp)
	jne	.L86
.L85:
	cmpq	$0, -8(%rbp)
	je	.L97
	subq	$1, -8(%rbp)
	movq	16(%rbp), %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	leaq	.LC29(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
	jmp	.L97
.L86:
	cmpl	$0, -28(%rbp)
	je	.L89
	cmpl	$224, -28(%rbp)
	jne	.L90
.L89:
	movq	__imp__getch(%rip), %rax
	call	*%rax
	movl	%eax, -28(%rbp)
	cmpl	$72, -28(%rbp)
	jne	.L98
	movzbl	last_expr(%rip), %eax
	testb	%al, %al
	je	.L92
	movl	$13, %ecx
	call	putchar
	movl	$0, -12(%rbp)
	jmp	.L93
.L94:
	movl	$32, %ecx
	call	putchar
	addl	$1, -12(%rbp)
.L93:
	cmpl	$119, -12(%rbp)
	jle	.L94
	leaq	last_expr(%rip), %rax
	movq	%rax, %rcx
	call	strlen
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	cmpq	24(%rbp), %rax
	jb	.L95
	movq	24(%rbp), %rax
	subq	$1, %rax
	movq	%rax, -8(%rbp)
.L95:
	movq	-8(%rbp), %rcx
	leaq	last_expr(%rip), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	memcpy
	movq	16(%rbp), %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	movq	16(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rax, %rcx
	call	redraw_input_line
	jmp	.L98
.L92:
	movq	16(%rbp), %rdx
	movq	-24(%rbp), %rax
	leaq	.LC30(%rip), %rcx
	movq	%rdx, %r8
	movq	%rax, %rdx
	call	__mingw_printf
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
	jmp	.L98
.L90:
	movl	-28(%rbp), %eax
	movzbl	%al, %eax
	movl	%eax, %ecx
	movq	__imp_isprint(%rip), %rax
	call	*%rax
	testl	%eax, %eax
	je	.L96
	movq	-8(%rbp), %rax
	addq	$1, %rax
	cmpq	24(%rbp), %rax
	jnb	.L96
	movq	-8(%rbp), %rax
	leaq	1(%rax), %rdx
	movq	%rdx, -8(%rbp)
	movq	16(%rbp), %rdx
	addq	%rdx, %rax
	movl	-28(%rbp), %edx
	movb	%dl, (%rax)
	movq	16(%rbp), %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	movl	-28(%rbp), %eax
	movl	%eax, %ecx
	call	putchar
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	call	fflush
	jmp	.L96
.L97:
	nop
	jmp	.L96
.L98:
	nop
	jmp	.L96
.L82:
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC31:
	.ascii "Expression cannot be empty\0"
.LC32:
	.ascii "Calculation steps:\0"
.LC33:
	.ascii "Final result: %.10g\12\0"
	.align 8
.LC34:
	.ascii "Calculation failed, invalid expression was not saved to history\0"
	.text
	.def	input_and_calculate;	.scl	3;	.type	32;	.endef
	.seh_proc	input_and_calculate
input_and_calculate:
	pushq	%rbp
	.seh_pushreg	%rbp
	subq	$560, %rsp
	.seh_stackalloc	560
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	leaq	-80(%rbp), %rax
	movl	$512, %edx
	movq	%rax, %rcx
	call	read_expression_line
	leaq	-80(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	jne	.L100
	leaq	.LC31(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L99
.L100:
	leaq	.LC32(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	-88(%rbp), %rdx
	leaq	-80(%rbp), %rax
	movq	%rax, %rcx
	call	calculate_expression
	cmpl	$1, %eax
	jne	.L102
	movsd	-88(%rbp), %xmm0
	movapd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movq	%xmm1, %rdx
	leaq	.LC33(%rip), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-88(%rbp), %xmm0
	leaq	-80(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	add_history
	jmp	.L99
.L102:
	leaq	.LC34(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L99:
	addq	$560, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC35:
	.ascii "Need at least 2 history records for combined calculation\0"
	.align 8
.LC36:
	.ascii "Select first history record number: \0"
.LC37:
	.ascii "Invalid record number\0"
	.align 8
.LC38:
	.ascii "Select second history record number: \0"
.LC39:
	.ascii "(%s)*(%s)\0"
.LC40:
	.ascii "Combined expression: %s\12\0"
	.align 8
.LC41:
	.ascii "Calculation failed, combined expression was not saved to history\0"
	.text
	.def	combine_history_and_calculate;	.scl	3;	.type	32;	.endef
	.seh_proc	combine_history_and_calculate
combine_history_and_calculate:
	pushq	%rbp
	.seh_pushreg	%rbp
	subq	$1104, %rsp
	.seh_stackalloc	1104
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movl	history_count(%rip), %eax
	cmpl	$1, %eax
	jg	.L105
	leaq	.LC35(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L104
.L105:
	call	show_history_page
	leaq	.LC36(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	leaq	972(%rbp), %rax
	leaq	.LC21(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L107
	leaq	.LC37(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L108:
	call	getchar
	cmpl	$10, %eax
	jne	.L108
	jmp	.L104
.L107:
	leaq	.LC38(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	leaq	968(%rbp), %rax
	leaq	.LC21(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L109
	leaq	.LC37(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L110:
	call	getchar
	cmpl	$10, %eax
	jne	.L110
	jmp	.L104
.L109:
	call	getchar
	movl	972(%rbp), %eax
	testl	%eax, %eax
	jle	.L111
	movl	972(%rbp), %edx
	movl	history_count(%rip), %eax
	cmpl	%eax, %edx
	jg	.L111
	movl	968(%rbp), %eax
	testl	%eax, %eax
	jle	.L111
	movl	968(%rbp), %edx
	movl	history_count(%rip), %eax
	cmpl	%eax, %edx
	jle	.L112
.L111:
	leaq	.LC37(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L104
.L112:
	movl	968(%rbp), %eax
	subl	$1, %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	history(%rip), %rdx
	addq	%rax, %rdx
	movl	972(%rbp), %eax
	subl	$1, %eax
	cltq
	imulq	$520, %rax, %rax
	leaq	history(%rip), %rcx
	leaq	(%rax,%rcx), %r8
	leaq	.LC39(%rip), %rcx
	leaq	-64(%rbp), %rax
	movq	%rdx, 32(%rsp)
	movq	%r8, %r9
	movq	%rcx, %r8
	movl	$1032, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	leaq	-64(%rbp), %rax
	leaq	.LC40(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_printf
	leaq	.LC32(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	-72(%rbp), %rdx
	leaq	-64(%rbp), %rax
	movq	%rax, %rcx
	call	calculate_expression
	cmpl	$1, %eax
	jne	.L113
	movsd	-72(%rbp), %xmm0
	movapd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movq	%xmm1, %rdx
	leaq	.LC33(%rip), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	__mingw_printf
	movsd	-72(%rbp), %xmm0
	leaq	-64(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rcx
	call	add_history
	jmp	.L104
.L113:
	leaq	.LC41(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L104:
	addq	$1104, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC42:
	.ascii "\12--- Calculate Menu ---\0"
.LC43:
	.ascii "1. Enter expression\0"
	.align 8
.LC44:
	.ascii "2. Multiply two history records\0"
.LC45:
	.ascii "Select: \0"
.LC46:
	.ascii "Input error\0"
.LC47:
	.ascii "Invalid calculate menu option\0"
	.text
	.def	calculate_menu;	.scl	3;	.type	32;	.endef
	.seh_proc	calculate_menu
calculate_menu:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	leaq	.LC42(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC43(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC44(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC45(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	leaq	-4(%rbp), %rax
	leaq	.LC21(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L117
	leaq	.LC46(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L118:
	call	getchar
	cmpl	$10, %eax
	jne	.L118
	jmp	.L116
.L117:
	call	getchar
	movl	-4(%rbp), %eax
	cmpl	$1, %eax
	jne	.L120
	call	input_and_calculate
	jmp	.L116
.L120:
	movl	-4(%rbp), %eax
	cmpl	$2, %eax
	jne	.L122
	call	combine_history_and_calculate
	jmp	.L116
.L122:
	leaq	.LC47(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L116:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC48:
	.ascii "\12===== Arithmetic Expression Calculator =====\0"
.LC49:
	.ascii "1. Calculate expression\0"
.LC50:
	.ascii "2. View history\0"
.LC51:
	.ascii "3. Clear history\0"
.LC52:
	.ascii "4. Exit\0"
	.text
	.def	print_menu;	.scl	3;	.type	32;	.endef
	.seh_proc	print_menu
print_menu:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	leaq	.LC48(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC49(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC50(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC51(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC52(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC45(%rip), %rax
	movq	%rax, %rcx
	call	__mingw_printf
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC53:
	.ascii "Program exit\0"
.LC54:
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
.L134:
	call	print_menu
	leaq	-4(%rbp), %rax
	leaq	.LC21(%rip), %rcx
	movq	%rax, %rdx
	call	__mingw_scanf
	cmpl	$1, %eax
	je	.L125
	leaq	.LC46(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L126:
	call	getchar
	cmpl	$10, %eax
	jne	.L126
	jmp	.L127
.L125:
	call	getchar
	movl	-4(%rbp), %eax
	cmpl	$4, %eax
	je	.L128
	cmpl	$4, %eax
	jg	.L129
	cmpl	$3, %eax
	je	.L130
	cmpl	$3, %eax
	jg	.L129
	cmpl	$1, %eax
	je	.L131
	cmpl	$2, %eax
	je	.L132
	jmp	.L129
.L131:
	call	calculate_menu
	jmp	.L127
.L132:
	call	show_history_page
	jmp	.L127
.L130:
	call	clear_history
	jmp	.L127
.L128:
	leaq	.LC53(%rip), %rax
	movq	%rax, %rcx
	call	puts
	movl	$0, %eax
	jmp	.L135
.L129:
	leaq	.LC54(%rip), %rax
	movq	%rax, %rcx
	call	puts
	nop
.L127:
	jmp	.L134
.L135:
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC1:
	.long	0
	.long	0
	.align 16
.LC2:
	.long	0
	.long	-2147483648
	.long	0
	.long	0
	.def	__main;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (Rev5, Built by MSYS2 project) 16.1.0"
	.def	__mingw_strtod;	.scl	2;	.type	32;	.endef
	.def	strncpy;	.scl	2;	.type	32;	.endef
	.def	puts;	.scl	2;	.type	32;	.endef
	.def	fopen;	.scl	2;	.type	32;	.endef
	.def	strstr;	.scl	2;	.type	32;	.endef
	.def	strlen;	.scl	2;	.type	32;	.endef
	.def	atof;	.scl	2;	.type	32;	.endef
	.def	fgets;	.scl	2;	.type	32;	.endef
	.def	fclose;	.scl	2;	.type	32;	.endef
	.def	getchar;	.scl	2;	.type	32;	.endef
	.def	remove;	.scl	2;	.type	32;	.endef
	.def	fflush;	.scl	2;	.type	32;	.endef
	.def	putchar;	.scl	2;	.type	32;	.endef
	.def	putchar;	.scl	2;	.type	32;	.endef
	.def	memcpy;	.scl	2;	.type	32;	.endef
