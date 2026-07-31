# ============================================================
# shunting_yard.asm �� ���ȳ��㷨
# ����׺ token_array[] ת��Ϊ��׺ postfix_queue[]
# ============================================================
.text

# ------------------------------------------------------------
# shunting_yard �� ��׺->��׺
# ���: �ޣ��� token_array[], token_count ��ȡ��
# ����: $v0 = postfix_count, $v1 = 0=�ɹ� 1=���Ų�ƥ��
# ������: д�� postfix_queue[], postfix_count
# �ƻ�: $t0-$t7
# ------------------------------------------------------------
shunting_yard:
	lw $t0, token_count      # $t0 = ʣ�� token ��
	la $t1, token_array      # $t1 = ���� token ָ��
	la $t2, postfix_queue    # $t2 = �������д��ָ��
	li $t3, 0                # $t3 = �������
	li $t4, -1               # $t4 = op_top
	sw $t4, op_top

	li $t7, 200              # �������

sy_token_loop:
	beqz $t0, sy_pop_remaining

	lw $t5, 0($t1)           # $t5 = token type
	lw $t6, 4($t1)           # $t6 = token value

	# ---- NUMBER ----
	bnez $t5, sy_check_add
	# NUMBER: ֱ��д�����
	bge $t3, $t7, sy_overflow
	sw $t5, 0($t2)
	sw $t6, 4($t2)
	addiu $t2, $t2, 8
	addiu $t3, $t3, 1
	j sy_next_token

sy_check_add:
	li $t8, 1
	blt $t5, $t8, sy_next     # type < 1, skip (shouldn't happen for non-NUMBER)
	li $t8, 4
	ble $t5, $t8, sy_operator # type 1-4 -> �����

	# ---- LPAREN (5) ----
	li $t8, 5
	bne $t5, $t8, sy_check_rparen
	# �������������ջ
	addiu $t4, $t4, 1
	sll $t8, $t4, 2
	la $t9, op_stack
	addu $t9, $t9, $t8
	sw $t5, 0($t9)
	j sy_next_token

sy_check_rparen:
	# ---- RPAREN (6) ----
	li $t8, 6
	bne $t5, $t8, sy_next_token

	# ��ջֱ������ '('
sy_pop_to_lparen:
	bltz $t4, sy_paren_err
	sll $t8, $t4, 2
	la $t9, op_stack
	addu $t9, $t9, $t8
	lw $t8, 0($t9)           # $t8 = ջ�������
	addiu $t4, $t4, -1       # ��ջ

	li $t9, 5
	beq $t8, $t9, sy_next_token  # ���� '(' ֹͣ

	# д���������
	bge $t3, $t7, sy_overflow
	sw $t8, 0($t2)
	sw $zero, 4($t2)
	addiu $t2, $t2, 8
	addiu $t3, $t3, 1
	j sy_pop_to_lparen

sy_operator:
	# ---- ����� (type 1-4) ----
	move $a0, $t5
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($t7)
	push_int($ra)
	jal get_precedence
	pop_int($ra)
	pop_int($t7)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)
	# $v0 =��ǰ��������ȼ�

sy_op_while:
	bltz $t4, sy_push_op     # ջ����ֱ����ջ

	sll $t8, $t4, 2
	la $t9, op_stack
	addu $t9, $t9, $t8
	lw $t8, 0($t9)           # $t8 = ջ�������

	# ջ���� '(' ��ֹͣ
	li $t9, 5
	beq $t8, $t9, sy_push_op

	# ��ȡջ�����ȼ�
	move $a0, $t8
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($t7)
	push_int($v0)
	push_int($ra)
	jal get_precedence
	pop_int($ra)
	pop_int($t9)             # $t9 = ջ�����ȼ�
	pop_int($t7)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)

	# ��ǰ���ȼ� <= ջ�����ȼ� -> ��ջ�����ϣ�
	bge $v0, $t9, sy_pop_op
	j sy_push_op

sy_pop_op:
	# ��ջ�������
	addiu $t4, $t4, -1
	bge $t3, $t7, sy_overflow
	sw $t8, 0($t2)
	sw $zero, 4($t2)
	addiu $t2, $t2, 8
	addiu $t3, $t3, 1
	j sy_op_while

sy_push_op:
	# ��ǰ�������ջ
	addiu $t4, $t4, 1
	sll $t8, $t4, 2
	la $t9, op_stack
	addu $t9, $t9, $t8
	sw $t5, 0($t9)

sy_next_token:
	addiu $t1, $t1, 8
	addiu $t0, $t0, -1
	j sy_token_loop

sy_next:
	# δ֪ token ���ͣ�����
	addiu $t1, $t1, 8
	addiu $t0, $t0, -1
	j sy_token_loop

sy_pop_remaining:
	# ---- ���������ջ ----
	bltz $t4, sy_done
	sll $t8, $t4, 2
	la $t9, op_stack
	addu $t9, $t9, $t8
	lw $t8, 0($t9)
	addiu $t4, $t4, -1

	# ����Ƿ���δƥ��� '('
	li $t9, 5
	beq $t8, $t9, sy_paren_err

	bge $t3, $t7, sy_overflow
	sw $t8, 0($t2)
	sw $zero, 4($t2)
	addiu $t2, $t2, 8
	addiu $t3, $t3, 1
	j sy_pop_remaining

sy_done:
	sw $t3, postfix_count
	move $v0, $t3
	li $v1, 0
	jr $ra

sy_paren_err:
	print_str(paren_err)
	li $v0, 0
	li $v1, 1
	jr $ra

sy_overflow:
	print_str(overflow_msg)
	li $v0, 0
	li $v1, 1
	jr $ra
