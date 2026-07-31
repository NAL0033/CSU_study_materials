# ============================================================
# converter.asm — 数字->字符串转换
# 函数: int_to_str, float_to_str, str_to_float
# ============================================================
.text

# ------------------------------------------------------------
# int_to_str — 有符号整数 -> 字符串
# 入参: $a0 = 整数, $a1 = 输出缓冲区地址
# 出参: 无（写入缓冲区，以 '\0' 结尾）
# 破坏: $t0-$t5
# ------------------------------------------------------------
int_to_str:
	move $t0, $a1           # $t0 = 缓冲区写入指针
	move $t1, $a0           # $t1 = 要转换的整数

	bgez $t1, its_positive
	# 负数处理
	li $t2, '-'
	sb $t2, 0($t0)
	addiu $t0, $t0, 1
	sub $t1, $zero, $t1     # 取绝对值

its_positive:
	# 先提取各位数字（倒序存入系统栈）
	li $t2, 0               # $t2 = 数字位数计数
	li $t4, 10

its_extract:
	div $t1, $t4
	mflo $t1                # 商
	mfhi $t3                # 余数 = 当前最低位数字
	addiu $t3, $t3, '0'     # 转 ASCII
	push_int($t3)           # 压栈
	addiu $t2, $t2, 1
	bgtz $t1, its_extract

	# 处理 0 的特殊情况
	bnez $t2, its_pop
	li $t3, '0'
	sb $t3, 0($t0)
	addiu $t0, $t0, 1
	j its_done

its_pop:
	pop_int($t3)
	sb $t3, 0($t0)
	addiu $t0, $t0, 1
	addiu $t2, $t2, -1
	bgtz $t2, its_pop

its_done:
	sb $zero, 0($t0)        # '\0' 结尾
	jr $ra

# ------------------------------------------------------------
# float_to_str — 单精度浮点 -> 字符串（保留最多 6 位小数，去除末尾零）
# 入参: $f12 = 浮点值, $a0 = 输出缓冲区地址
# 出参: 无
# 破坏: $t0-$t7, $f0-$f8
# ------------------------------------------------------------
float_to_str:
	move $t7, $a0           # $t7 = 缓冲区指针
	mov.s $f0, $f12          # $f0 = 原始值

	# ---- 处理负数 ----
	l.s $f2, fp_const_0
	c.lt.s $f0, $f2
	bc1f fts_positive
	li $t0, '-'
	sb $t0, 0($t7)
	addiu $t7, $t7, 1
	neg.s $f0, $f0          # 取绝对值

fts_positive:
	# ---- 分离整数部分 ----
	# trunc.w.s: 向零截断 (3.7->3, -3.7->-3)
	trunc.w.s $f4, $f0
	mfc1 $t0, $f4               # $t0 = 整数部分 (word)
	cvt.s.w $f4, $f4            # $f4 = 整数部分 (as float)
	sub.s $f6, $f0, $f4         # $f6 = 小数部分 (0.0 ~ 0.999...)

	# ---- 输出整数部分 ----
	move $a0, $t0
	move $a1, $t7
	push_int($ra)
	jal int_to_str
	pop_int($ra)

	# 移动指针到整数部分末尾
fts_skip_int:
	lb $t1, 0($t7)
	beqz $t1, fts_add_dot
	addiu $t7, $t7, 1
	j fts_skip_int

fts_add_dot:
	# ---- 输出小数点 ----
	li $t1, '.'
	sb $t1, 0($t7)
	addiu $t7, $t7, 1

	# ---- 提取 6 位小数 ----
	l.s $f8, fp_const_1000000
	mul.s $f6, $f6, $f8        # $f6 = frac * 1000000.0
	l.s $f8, fp_const_0_5
	add.s $f6, $f6, $f8        # 四舍五入
	trunc.w.s $f6, $f6          # 截断取整
	mfc1 $t0, $f6               # $t0 = 小数整数 (0~1000000)

	# ---- 输出 6 位小数（带前导零） ----
	li $t1, 100000
	li $t2, 6                 # 小数位数

fts_frac_loop:
	beqz $t2, fts_trim_zeros
	div $t0, $t1
	mflo $t3                  # 商 = 当前位数字
	mfhi $t0                  # 余数

	addiu $t3, $t3, '0'
	sb $t3, 0($t7)
	addiu $t7, $t7, 1

	div $t1, $t1, 10          # 除数 /= 10
	addiu $t2, $t2, -1
	j fts_frac_loop

fts_trim_zeros:
	# ---- 去除末尾多余的零 ----
	addiu $t7, $t7, -1        # 回退到最后一个字符
fts_trim_loop:
	lb $t1, 0($t7)
	li $t2, '0'
	bne $t1, $t2, fts_trim_done
	sb $zero, 0($t7)          # 抹掉零
	addiu $t7, $t7, -1
	j fts_trim_loop
fts_trim_done:
	# 如果小数点后全为零，删掉小数点
	lb $t1, 0($t7)
	li $t2, '.'
	bne $t1, $t2, fts_done
	sb $zero, 0($t7)

fts_done:
	jr $ra

# ------------------------------------------------------------
# str_to_float — 字符串 -> 单精度浮点
# 入参: $a0 = 字符串地址（指向数字起始位置）
# 出参: $f0 = 浮点值, $v0 = 数字后第一个字符的地址
# 破坏: $t0-$t7, $f0-$f8
# ------------------------------------------------------------
str_to_float:
	move $t0, $a0           # $t0 = 当前读取位置

	# ---- 符号处理 ----
	li $t1, 1               # $t1 = 符号 (1 = 正, -1 = 负)
	lb $t2, 0($t0)
	li $t3, '-'
	bne $t2, $t3, stf_check_plus
	li $t1, -1
	addiu $t0, $t0, 1
	j stf_parse_int
stf_check_plus:
	li $t3, '+'
	bne $t2, $t3, stf_parse_int
	addiu $t0, $t0, 1

stf_parse_int:
	# ---- 整数部分 ----
	li $t2, 0               # $t2 = 整数部分累加值
stf_int_loop:
	lb $t3, 0($t0)
	li $t4, '0'
	blt $t3, $t4, stf_int_done
	li $t4, '9'
	bgt $t3, $t4, stf_int_done
	subu $t3, $t3, '0'
	li $t4, 10
	mult $t2, $t4
	mflo $t2
	addu $t2, $t2, $t3
	addiu $t0, $t0, 1
	j stf_int_loop
stf_int_done:

	# ---- 小数部分 ----
	li $t4, 0               # $t4 = 小数部分累加值
	li $t5, 0               # $t5 = 小数位数计数
	lb $t3, 0($t0)
	li $t6, '.'
	bne $t3, $t6, stf_build_float

	addiu $t0, $t0, 1       # 跳过 '.'
stf_frac_loop:
	lb $t3, 0($t0)
	li $t6, '0'
	blt $t3, $t6, stf_frac_done
	li $t6, '9'
	bgt $t3, $t6, stf_frac_done
	subu $t3, $t3, '0'
	li $t6, 10
	mult $t4, $t6
	mflo $t4
	addu $t4, $t4, $t3
	addiu $t5, $t5, 1
	addiu $t0, $t0, 1
	j stf_frac_loop
stf_frac_done:

stf_build_float:
	# ---- 用 FPU 组合整数和小数部分 ----
	# result = int_part + frac_part / (10^frac_digits)
	mtc1 $t2, $f0
	cvt.s.w $f0, $f0        # $f0 = (float)整数部分

	beqz $t5, stf_apply_sign

	mtc1 $t4, $f2
	cvt.s.w $f2, $f2        # $f2 = (float)小数部分

	# 计算 10^frac_digits
	l.s $f4, fp_const_1     # $f4 = 1.0
	l.s $f6, fp_const_10    # $f6 = 10.0
	move $t6, $t5
stf_pow10_loop:
	beqz $t6, stf_divide
	mul.s $f4, $f4, $f6
	addiu $t6, $t6, -1
	j stf_pow10_loop
stf_divide:
	div.s $f2, $f2, $f4     # $f2 = frac_part / 10^n
	add.s $f0, $f0, $f2     # $f0 = int_part + frac_part

stf_apply_sign:
	# 应用符号
	li $t2, -1
	bne $t1, $t2, stf_done
	neg.s $f0, $f0

stf_done:
	move $v0, $t0            # 返回数字之后的地址
	jr $ra
