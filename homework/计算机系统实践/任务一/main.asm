# ============================================================
# main.asm — MIPS 汇编计算器 入口文件
# 功能: 支持浮点四则运算表达式求值、解题步骤输出、
#       历史记录存储/读取/清空/组合
# 运行: 在 MARS MIPS 模拟器中打开此文件，汇编后运行
# ============================================================

.globl main

# ---- 引入各模块（按依赖顺序） ----
.include "data.asm"
.include "macros.asm"
.include "converter.asm"
.include "tokenizer.asm"
.include "shunting_yard.asm"
.include "evaluator.asm"
.include "history.asm"
.include "io_utils.asm"

.text

# ============================================================
# main — 程序入口
# ============================================================
main:
	# 初始化状态
	sw $zero, has_previous
	sw $zero, eval_err_flag

	# 欢迎信息
	print_str(menu_title)

# ============================================================
# menu_loop — 主菜单循环
# ============================================================
menu_loop:
	jal display_menu
	jal read_choice
	move $t0, $v0            # $t0 = 用户选项

	# 分支到对应功能
	li $t1, 1
	beq $t0, $t1, do_calculate
	li $t1, 2
	beq $t0, $t1, do_read_history
	li $t1, 3
	beq $t0, $t1, do_clear_history
	li $t1, 4
	beq $t0, $t1, do_exit

	# 无效选项
	print_str(menu_invalid)
	j menu_loop

# ============================================================
# do_calculate — 执行表达式计算
# ============================================================
do_calculate:
	# 1. 读取表达式
	jal read_expression
	# $v0 = 0 正常, 1 跳过, 2 历史组合
	li $t0, 1
	beq $v0, $t0, menu_loop  # 跳过（无上一条等）

	# 2. 词法分析
	jal tokenize
	bnez $v1, menu_loop      # 语法错误 -> 返回菜单

	# 3. 调度场算法（中缀->后缀）
	jal shunting_yard
	bnez $v1, menu_loop      # 括号不匹配 -> 返回菜单

	# 4. 后缀求值
	jal evaluate
	bnez $v1, menu_loop      # 求值错误 -> 返回菜单

	# 5. 显示解题步骤
	print_str(steps_header)
	jal display_steps

	# 6. 显示最终结果
	print_str(result_msg)
	# $f0 保存了 evaluate 的返回值
	mov.s $f12, $f0
	la $a0, float_buf1
	jal float_to_str
	la $a0, float_buf1
	li $v0, 4
	syscall
	println()

	# 7. 保存到历史文件
	la $a0, input_buffer
	jal hist_save

	# 8. 保存到召回缓冲区（上一条表达式）
	la $a0, input_buffer
	la $a1, recall_buffer
	jal strcpy
	li $t0, 1
	sw $t0, has_previous

	j menu_loop

# ============================================================
# do_read_history — 读取历史记录
# ============================================================
do_read_history:
	jal hist_read
	j menu_loop

# ============================================================
# do_clear_history — 清空历史记录
# ============================================================
do_clear_history:
	jal hist_clear
	j menu_loop

# ============================================================
# do_exit — 退出程序
# ============================================================
do_exit:
	li $v0, 10
	syscall
