# ============================================================
# evaluator.asm �� ��׺����ʽ��ֵ + �����¼����ʾ
# ============================================================
.text

# ------------------------------------------------------------
# evaluate �� ��׺����ʽ��ֵ
# ���: �ޣ��� postfix_queue[], postfix_count ��ȡ��
# ����: $f0 = ���ս��, $v0 = step_count, $v1 = 0=�ɹ� 1=����
# ������: д�� eval_stack[], step_buffer[], step_count
# �ƻ�: $t0-$t7, $f0-$f10
# ------------------------------------------------------------
evaluate:
	lw $t0, postfix_count     # $t0 = ʣ�� token ��
	la $t1, postfix_queue     # $t1 = ����ָ��
	li $t2, -1                # $t2 = eval_stack ջ������
	la $t3, eval_stack        # $t3 = eval_stack ����ַ
	la $t4, step_buffer       # $t4 = �����¼ָ��
	li $t5, 0                 # $t5 = �������

eval_loop:
	beqz $t0, eval_check_result

	lw $t6, 0($t1)            # $t6 = token type
	lw $t7, 4($t1)            # $t7 = token value (IEEE 754 bits for NUMBER)

	# ---- NUMBER (type 0) ----
	bnez $t6, eval_operator

	# ѹ�� eval_stack
	addiu $t2, $t2, 1
	sll $t8, $t2, 2
	addu $t8, $t3, $t8
	sw $t7, 0($t8)            # �� IEEE 754 λ��ջ��
	j eval_next

eval_operator:
	# ---- OPERATOR (type 1-4) ----
	# ȷ��ջ������������������
	blt $t2, 1, eval_error

	# ����������2���Ҳ�������
	sll $t8, $t2, 2
	addu $t8, $t3, $t8
	lw $t9, 0($t8)            # $t9 = op2 �� IEEE 754 λ
	addiu $t2, $t2, -1        # ��ջ

	# ����������1�����������
	sll $t8, $t2, 2
	addu $t8, $t3, $t8
	lwc1 $f4, 0($t8)          # $f4 = op1 (float)
	addiu $t2, $t2, -1        # really pop op1

	# ���� op2 �� $f6
	mtc1 $t9, $f6             # $f6 = op2 (float)

	# ��¼����Ĳ�������Ϣ
	sw $t9, 8($t4)            # step.operand2 = op2 λ
	# op1 ��Ҫ�������

	# �������������
	li $t8, 1                 # ADD
	beq $t6, $t8, eval_add
	li $t8, 2                 # SUB
	beq $t6, $t8, eval_sub
	li $t8, 3                 # MUL
	beq $t6, $t8, eval_mul
	li $t8, 4                 # DIV
	beq $t6, $t8, eval_div
	j eval_error

eval_add:
	add.s $f8, $f4, $f6
	j eval_store_result

eval_sub:
	sub.s $f8, $f4, $f6
	j eval_store_result

eval_mul:
	mul.s $f8, $f4, $f6
	j eval_store_result

eval_div:
	# ������Ϊ��
	l.s $f10, fp_const_0
	c.eq.s $f6, $f10
	bc1t eval_div_zero
	div.s $f8, $f4, $f6
	j eval_store_result
eval_div_zero:
	print_str(div_zero_err)
	li $v0, 0
	li $v1, 1
	jr $ra

eval_store_result:
	# ---- ��¼���� ----
	# ��ȡ op1 �� IEEE 754 λ
	mfc1 $t8, $f4
	sw $t8, 0($t4)            # step.operand1

	sw $t6, 4($t4)            # step.operator

	mfc1 $t8, $f8
	sw $t8, 12($t4)           # step.result

	addiu $t4, $t4, 16        # ��һ��¼
	addiu $t5, $t5, 1

	# ---- ���ѹ�� eval_stack ----
	addiu $t2, $t2, 1
	sll $t8, $t2, 2
	addu $t8, $t3, $t8
	s.s $f8, 0($t8)

eval_next:
	addiu $t1, $t1, 8
	addiu $t0, $t0, -1
	j eval_loop

eval_check_result:
	# �������ջ���Ƿ�ǡ����һ��ֵ
	bne $t2, 0, eval_error

	# ���ؽ��
	sll $t8, $t2, 2
	addu $t8, $t3, $t8
	lwc1 $f0, 0($t8)

	sw $t5, step_count
	move $v0, $t5
	li $v1, 0
	jr $ra

eval_error:
	print_str(eval_err)
	li $v0, 0
	li $v1, 1
	jr $ra

# ------------------------------------------------------------
# display_steps �� ��ʾ���ⲽ��
# ���: �ޣ��� step_buffer[], step_count ��ȡ��
# ����: ��
# �ƻ�: $t0-$t7, $f0-$f12
# ------------------------------------------------------------
display_steps:
	lw $t0, step_count
	beqz $t0, ds_done
	la $t1, step_buffer        # $t1 = �����¼ָ��
	li $t2, 0                  # $t2 = ��ǰ��������

ds_loop:
	beq $t2, $t0, ds_done

	# ---- ���ز������� ----
	lw $t3, 0($t1)             # operand1 (IEEE 754 λ)
	lw $t4, 4($t1)             # operator (1-4)
	lw $t5, 8($t1)             # operand2 (IEEE 754 λ)
	lw $t6, 12($t1)            # result (IEEE 754 λ)

	# ---- ��ʾ operand1 ----
	mtc1 $t3, $f12
	la $a0, float_buf1
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($ra)
	jal float_to_str
	pop_int($ra)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)

	la $a0, float_buf1
	li $v0, 4
	syscall

	# ---- ��ʾ����� ----
	li $t7, 1
	beq $t4, $t7, ds_plus
	li $t7, 2
	beq $t4, $t7, ds_minus
	li $t7, 3
	beq $t4, $t7, ds_mul
	li $t7, 4
	beq $t4, $t7, ds_div
	j ds_done

ds_plus:  print_str(plus_char)
	j ds_op2
ds_minus: print_str(minus_char)
	j ds_op2
ds_mul:   print_str(mul_char)
	j ds_op2
ds_div:   print_str(div_char)
	j ds_op2

ds_op2:
	# ---- ��ʾ operand2 ----
	mtc1 $t5, $f12
	la $a0, float_buf2
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($ra)
	jal float_to_str
	pop_int($ra)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)

	la $a0, float_buf2
	li $v0, 4
	syscall

	# ---- ��ʾ�Ⱥźͽ�� ----
	print_str(equals_sign)

	mtc1 $t6, $f12
	la $a0, float_buf3
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($ra)
	jal float_to_str
	pop_int($ra)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)

	la $a0, float_buf3
	li $v0, 4
	syscall
	println()

	# ---- ��һ�� ----
	addiu $t1, $t1, 16
	addiu $t2, $t2, 1
	j ds_loop

ds_done:
	jr $ra
