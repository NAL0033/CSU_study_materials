# ============================================================
# io_utils.asm — Menu and user interface
# Functions: display_menu, read_choice, read_expression
# ============================================================
.text

# ------------------------------------------------------------
# display_menu — Show the main menu
# ------------------------------------------------------------
display_menu:
	print_str(menu_title)
	print_str(menu_1)
	print_str(menu_2)
	print_str(menu_3)
	print_str(menu_4)
	jr $ra

# ------------------------------------------------------------
# read_choice — Read menu choice using syscall 8 (NO syscall 5!)
# Syscall 5 leaves \r\n in buffer which poisons the next syscall 8.
# Using syscall 8 for ALL input avoids this entirely.
# Out: $v0 = user choice (1-4)
# ------------------------------------------------------------
read_choice:
rc_prompt:
	print_str(menu_prompt)
	# Read line as string into tmp_buf
	la $a0, tmp_buf
	li $a1, 16
	li $v0, 8
	syscall
	# Parse first byte: convert ASCII digit to int
	la $t0, tmp_buf
	lb $t1, 0($t0)
	li $t2, '1'
	blt $t1, $t2, rc_prompt
	li $t2, '4'
	bgt $t1, $t2, rc_prompt
	subu $v0, $t1, '0'
	jr $ra

# ------------------------------------------------------------
# read_expression — Read expression input
# Handles special commands: 'p' -> recall previous, 'h' -> history combine
# Out: $v0 = 0=normal calc, 1=skip/error, 2=history combine ok
# Side: writes input_buffer (or combined_buffer -> input_buffer)
# ------------------------------------------------------------
read_expression:
re_read_prompt:
	print_str(calc_prompt)

	# Read string via syscall 8
	la $a0, input_buffer
	li $a1, 512
	li $v0, 8
	syscall

	# Strip trailing newline + carriage return
	la $a0, input_buffer
	push_int($ra)
	jal strip_newline
	pop_int($ra)

	# ---- Check empty input ----
	la $t0, input_buffer
	lb $t1, 0($t0)
	bnez $t1, re_check_p
	print_str(empty_input_msg)
	j re_read_prompt

re_check_p:
	# ---- Check 'p' command ----
	li $t2, 'p'
	bne $t1, $t2, re_check_h
	lb $t1, 1($t0)
	bnez $t1, re_check_h      # more than one char -> not p command

	# p command: recall previous
	lw $t1, has_previous
	bnez $t1, re_do_recall
	print_str(no_prev_msg)
	li $v0, 1
	jr $ra

re_do_recall:
	# Copy recall_buffer -> input_buffer
	la $a0, recall_buffer
	la $a1, input_buffer
	push_int($ra)
	jal strcpy
	pop_int($ra)
	print_str(recalled_msg)
	la $a0, input_buffer
	li $v0, 4
	syscall
	println()
	li $v0, 0                # success
	jr $ra

re_check_h:
	# ---- Check 'h' command ----
	li $t2, 'h'
	bne $t1, $t2, re_normal
	lb $t1, 1($t0)
	bnez $t1, re_normal      # more than one char -> not h command

	# h command: history combine
	push_int($ra)
	jal hist_combine
	pop_int($ra)
	bnez $v0, re_h_failed    # hist_combine returned error
	li $v0, 2                # history combine success
	jr $ra

re_h_failed:
	li $v0, 1
	jr $ra

re_normal:
	# Normal expression input
	li $v0, 0
	jr $ra
