# ============================================================
# tokenizer.asm �� �ʷ�������
# �� input_buffer �еı���ʽ�ַ������Ϊ token ����
# ============================================================
.text

# ------------------------------------------------------------
# tokenize �� �ʷ�����
# ���: �ޣ��� input_buffer ȫ�ֱ�����ȡ��
# ����: $v0 = token_count, $v1 = 0=�ɹ� 1=ʧ��
# ������: д�� token_array[], token_count
# �ƻ�: $t0-$t9, $f0-$f8
# ------------------------------------------------------------
tokenize:
	la $t0, input_buffer      # $t0 = ����ָ��
	la $t1, token_array       # $t1 = token �������ַ
	li $t2, 0                 # $t2 = token ����
	li $t3, 1                 # $t3 = expect_operand (1=�ڴ�������)
	li $t4, 200               # ��� token ��

tokenize_loop:
	# �����հ��ַ�
	lb $t5, 0($t0)
	beqz $t5, tokenize_done   # '\0' -> ����
	li $t6, '\n'
	beq $t5, $t6, tokenize_done
	li $t6, ' '
	beq $t5, $t6, tokenize_skip_ws
	li $t6, '\t'
	beq $t5, $t6, tokenize_skip_ws
	j tokenize_classify

tokenize_skip_ws:
	addiu $t0, $t0, 1
	j tokenize_loop

tokenize_classify:
	# ��� token ��������
	bge $t2, $t4, tokenize_overflow

	# ---- ������ ----
	li $t6, '('
	bne $t5, $t6, tok_check_rparen
	# �� token: type=LPAREN(5), value=0
	li $t6, 5
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 1               # '(' ���ڴ�������
	addiu $t0, $t0, 1
	j tokenize_loop

tok_check_rparen:
	# ---- ������ ----
	li $t6, ')'
	bne $t5, $t6, tok_check_plus
	li $t6, 6
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 0               # ')' ���ڴ������
	addiu $t0, $t0, 1
	j tokenize_loop

tok_check_plus:
	# ---- �Ӻ� ----
	li $t6, '+'
	bne $t5, $t6, tok_check_minus
	beqz $t3, tok_plus_bin   # �ڴ�������? ��->��Ԫ
	# һԪ�Ӻţ���������������
	addiu $t0, $t0, 1
	j tokenize_loop
tok_plus_bin:
	li $t6, 1                # ADD
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 1               # ��������ڴ�������
	addiu $t0, $t0, 1
	j tokenize_loop

tok_check_minus:
	# ---- ���� / һԪ���� ----
	li $t6, '-'
	bne $t5, $t6, tok_check_mul
	bnez $t3, tok_unary_minus
	# ��Ԫ����
	li $t6, 2                # SUB
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 1
	addiu $t0, $t0, 1
	j tokenize_loop

tok_unary_minus:
	# һԪ���ţ����� '-'���Ѻ�������ֽ���Ϊ����
	addiu $t0, $t0, 1
	lb $t5, 0($t0)
	# ���� '(' �� '-' ֮��Ŀհ�
tok_minus_skip_ws:
	li $t6, ' '
	bne $t5, $t6, tok_minus_parse
	addiu $t0, $t0, 1
	lb $t5, 0($t0)
	j tok_minus_skip_ws

tok_minus_parse:
	# ---- ���һԪ���ź�����ʲô ----
	li $t6, '('
	bne $t5, $t6, tok_parse_neg_number

	# "-(...)" ����� -> չ��Ϊ "0-(...)"
	# �ȴ� NUMBER(0.0)
	l.s $f8, fp_const_0
	sw $zero, 0($t1)         # type = NUMBER(0)
	s.s $f8, 4($t1)          # value = 0.0
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	bge $t2, $t4, tokenize_overflow

	# �ٴ� SUB �����
	li $t6, 2                 # SUB
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	bge $t2, $t4, tokenize_overflow

	# ���ƶ� $t0 ������ָ�� '('��������ѭ���������� '('
	li $t3, 1                # ��������ڴ�������
	j tokenize_loop

tok_parse_neg_number:
	# ����Ƿ�������
	lb $t5, 0($t0)
	move $a0, $t5
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($ra)
	jal is_digit
	pop_int($ra)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)
	beqz $v0, tokenize_syntax_err

	# ��������
	move $a0, $t0
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($ra)
	jal str_to_float
	pop_int($ra)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	# $f0 = ����ֵ, $v0 = ��ָ��
	neg.s $f0, $f0           # ȡ��
	move $t0, $v0

	sw $zero, 0($t1)         # type = NUMBER(0)
	s.s $f0, 4($t1)          # value = ��������ֵ
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 0               # ���ֺ��ڴ������
	j tokenize_loop

tok_check_mul:
	# ---- �˺� ----
	li $t6, '*'
	bne $t5, $t6, tok_check_div
	li $t6, 3                # MUL
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 1
	addiu $t0, $t0, 1
	j tokenize_loop

tok_check_div:
	# ---- ���� ----
	li $t6, '/'
	bne $t5, $t6, tok_check_digit_or_dot
	li $t6, 4                # DIV
	sw $t6, 0($t1)
	sw $zero, 4($t1)
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 1
	addiu $t0, $t0, 1
	j tokenize_loop

tok_check_digit_or_dot:
	# ---- ���ֻ�С���� ----
	move $a0, $t5
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($ra)
	jal is_digit
	pop_int($ra)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)
	bnez $v0, tok_parse_number

	# ��� '.'
	lb $t5, 0($t0)
	li $t6, '.'
	beq $t5, $t6, tok_parse_number

	# �޷�ʶ����ַ�
	j tokenize_syntax_err

tok_parse_number:
	# �������֣����������ֻ� '.' ��ͷ��
	move $a0, $t0
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($ra)
	jal str_to_float
	pop_int($ra)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	# $f0 = ֵ, $v0 = ��ָ��
	move $t0, $v0

	sw $zero, 0($t1)         # type = NUMBER(0)
	s.s $f0, 4($t1)          # value = ����ֵ
	addiu $t1, $t1, 8
	addiu $t2, $t2, 1
	li $t3, 0               # ���ֺ��ڴ������
	j tokenize_loop

tokenize_done:
	sw $t2, token_count
	li $v0, 0               # �ɹ�
	move $v0, $t2            # $v0 = token ����
	li $v1, 0               # �޴���
	jr $ra

tokenize_overflow:
	print_str(overflow_msg)
	li $v0, 0
	li $v1, 1
	jr $ra

tokenize_syntax_err:
	print_str(syntax_err)
	li $v0, 0
	li $v1, 1
	jr $ra
