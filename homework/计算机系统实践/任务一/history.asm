# ============================================================
# history.asm — History management (file I/O)
# Functions: hist_save, hist_read, hist_clear, hist_combine
# ============================================================
.text

# ------------------------------------------------------------
# hist_save — Save expression to history.txt
# In: $a0 = expression string address
# Out: none
# Clobbers: $t0-$t3
# ------------------------------------------------------------
hist_save:
	move $t0, $a0

	# Open file (mode 9 = write-append-create)
	la $a0, history_file
	li $a1, 9
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, hist_save_err
	move $t1, $v0

	# Compute length
	move $a0, $t0
	push_int($t0)
	push_int($t1)
	push_int($ra)
	jal strlen
	pop_int($ra)
	pop_int($t1)
	pop_int($t0)
	move $t2, $v0

	# Write expression
	move $a0, $t1
	move $a1, $t0
	move $a2, $t2
	li $v0, 15
	syscall

	# Write newline
	move $a0, $t1
	la $a1, newline
	li $a2, 1
	li $v0, 15
	syscall

	# Close file
	move $a0, $t1
	li $v0, 16
	syscall

hist_save_done:
	jr $ra

hist_save_err:
	jr $ra

# ------------------------------------------------------------
# hist_read — Read and paginate history
# In: none
# Out: none
# Clobbers: $t0-$t7
# ------------------------------------------------------------
hist_read:
	la $a0, history_file
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, hist_empty_show
	move $t0, $v0

	move $a0, $t0
	la $a1, history_content
	li $a2, 16384
	li $v0, 14
	syscall
	move $t1, $v0

	move $a0, $t0
	li $v0, 16
	syscall

	beqz $t1, hist_empty_show

	# Parse line offsets
	la $t2, history_content
	la $t3, line_starts
	li $t4, 0
	sw $zero, 0($t3)          # first line at offset 0
	addiu $t3, $t3, 4
	addiu $t4, $t4, 1
	li $t6, 0

hist_parse_lines:
	bge $t6, $t1, hist_parse_done
	addu $t7, $t2, $t6
	lb $t5, 0($t7)
	li $t7, '\n'
	bne $t5, $t7, hist_parse_next

	addiu $t7, $t6, 1
	bge $t7, $t1, hist_parse_done
	sw $t7, 0($t3)
	addiu $t3, $t3, 4
	addiu $t4, $t4, 1
	li $t7, 200
	bge $t4, $t7, hist_parse_done

hist_parse_next:
	addiu $t6, $t6, 1
	j hist_parse_lines

hist_parse_done:
	sw $t4, line_count

	# Paginate
	li $t5, 0                 # current page (0-based)
	li $t6, 10                # per page
	addiu $t7, $t4, 9
	li $t8, 10
	div $t7, $t8
	mflo $t7                  # total pages

hist_page_display:
	print_str(hist_header)
	print_str(hist_page)
	move $a0, $t5
	addiu $a0, $a0, 1
	la $a1, int_buf
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($t7)
	push_int($ra)
	jal int_to_str
	pop_int($ra)
	pop_int($t7)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	la $a0, int_buf
	li $v0, 4
	syscall
	print_str(hist_of)
	move $a0, $t7
	la $a1, int_buf
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($t7)
	push_int($ra)
	jal int_to_str
	pop_int($ra)
	pop_int($t7)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	la $a0, int_buf
	li $v0, 4
	syscall
	print_str(hist_page2)

	# Compute range
	mult $t5, $t6
	mflo $t0
	addiu $t1, $t0, 10
	ble $t1, $t4, hist_page_ok
	move $t1, $t4
hist_page_ok:

	move $t2, $t0
hist_show_line:
	bge $t2, $t1, hist_page_nav

	sll $t3, $t2, 2
	la $t8, line_starts
	addu $t8, $t8, $t3
	lw $t3, 0($t8)            # $t3 = line offset

	print_str(hist_prompt_num)
	move $a0, $t2
	addiu $a0, $a0, 1
	la $a1, int_buf
	push_int($t0)
	push_int($t1)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($t6)
	push_int($t7)
	push_int($ra)
	jal int_to_str
	pop_int($ra)
	pop_int($t7)
	pop_int($t6)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t1)
	pop_int($t0)
	la $a0, int_buf
	li $v0, 4
	syscall
	print_str(hist_colon)

	la $t8, history_content
	addu $t8, $t8, $t3
hist_show_chars:
	lb $t9, 0($t8)
	beqz $t9, hist_show_line_end
	li $s0, '\n'
	beq $t9, $s0, hist_show_line_end
	move $a0, $t9
	li $v0, 11
	syscall
	addiu $t8, $t8, 1
	j hist_show_chars
hist_show_line_end:
	println()
	addiu $t2, $t2, 1
	j hist_show_line

hist_page_nav:
	li $t8, 1
	ble $t7, $t8, hist_wait_key
	print_str(hist_nav)
	li $v0, 12
	syscall
	move $t8, $v0
	li $t9, 'n'
	beq $t8, $t9, hist_next_page
	li $t9, 'p'
	beq $t8, $t9, hist_prev_page
	li $t9, 'q'
	beq $t8, $t9, hist_read_done
	j hist_read_done

hist_next_page:
	addiu $t3, $t5, 1
	bge $t3, $t7, hist_page_display
	addiu $t5, $t5, 1
	j hist_page_display

hist_prev_page:
	blez $t5, hist_page_display
	addiu $t5, $t5, -1
	j hist_page_display

hist_wait_key:
	print_str(press_any_key)
	li $v0, 12
	syscall
	j hist_read_done

hist_empty_show:
	print_str(hist_empty)
	j hist_read_done

hist_read_done:
	jr $ra

# ------------------------------------------------------------
# hist_clear — Clear all history
# In: none / Out: none / Clobbers: $t0
# ------------------------------------------------------------
hist_clear:
	print_str(hist_confirm)
	li $v0, 12
	syscall
	move $t0, $v0
	li $t1, 'y'
	beq $t0, $t1, hist_clear_do
	li $t1, 'Y'
	bne $t0, $t1, hist_clear_cancel
hist_clear_do:
	la $a0, history_file
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	move $a0, $v0
	li $v0, 16
	syscall
	print_str(hist_cleared)
	jr $ra

hist_clear_cancel:
	print_str(hist_cancelled)
	jr $ra

# ------------------------------------------------------------
# hist_combine — Select two history entries, combine as (a)*(b)
# In: none
# Out: $v0 = 0=success, 1=fail
# Side: writes combined_buffer, then copies to input_buffer
# Clobbers: $t0-$t7
# ------------------------------------------------------------
hist_combine:
	lw $t0, line_count
	bgtz $t0, hc_has_lines

	# Load history if not yet loaded
	la $a0, history_file
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, hc_need2
	move $t1, $v0

	move $a0, $t1
	la $a1, history_content
	li $a2, 16384
	li $v0, 14
	syscall
	move $t2, $v0

	move $a0, $t1
	li $v0, 16
	syscall

	beqz $t2, hc_need2

	# Parse lines
	la $t3, line_starts
	li $t4, 1
	sw $zero, 0($t3)
	addiu $t3, $t3, 4
	li $t6, 0
hc_parse_loop:
	bge $t6, $t2, hc_parse_end
	la $t7, history_content
	addu $t7, $t7, $t6
	lb $t5, 0($t7)
	li $t7, '\n'
	bne $t5, $t7, hc_parse_next
	addiu $t7, $t6, 1
	bge $t7, $t2, hc_parse_end
	sw $t7, 0($t3)
	addiu $t3, $t3, 4
	addiu $t4, $t4, 1
hc_parse_next:
	addiu $t6, $t6, 1
	j hc_parse_loop
hc_parse_end:
	sw $t4, line_count
	move $t0, $t4

hc_has_lines:
	li $t1, 2
	blt $t0, $t1, hc_need2

	# Display entry list (up to 20)
	print_str(hist_header)
	li $t3, 20
	bgt $t0, $t3, hc_set_max
	move $t3, $t0
hc_set_max:
	move $t4, $t3             # $t4 = number to display
	li $t2, 0                 # current row

hc_show_loop:
	bge $t2, $t4, hc_prompt

	sll $t5, $t2, 2
	la $t6, line_starts
	addu $t6, $t6, $t5
	lw $t5, 0($t6)            # $t5 = line offset

	print_str(hist_prompt_num)
	move $a0, $t2
	addiu $a0, $a0, 1
	la $a1, int_buf
	push_int($t0)
	push_int($t2)
	push_int($t3)
	push_int($t4)
	push_int($t5)
	push_int($ra)
	jal int_to_str
	pop_int($ra)
	pop_int($t5)
	pop_int($t4)
	pop_int($t3)
	pop_int($t2)
	pop_int($t0)
	la $a0, int_buf
	li $v0, 4
	syscall
	print_str(hist_colon)

	la $t6, history_content
	addu $t6, $t6, $t5
hc_show_chars:
	lb $t7, 0($t6)
	beqz $t7, hc_show_eol
	li $t8, '\n'
	beq $t7, $t8, hc_show_eol
	move $a0, $t7
	li $v0, 11
	syscall
	addiu $t6, $t6, 1
	j hc_show_chars
hc_show_eol:
	println()
	addiu $t2, $t2, 1
	j hc_show_loop

hc_prompt:
	# ---- Read two indices via syscall 8 (NO syscall 5!) ----
	print_str(hist_select)
	la $a0, tmp_buf
	li $a1, 32
	li $v0, 8
	syscall
	la $a0, tmp_buf
	push_int($ra)
	jal strip_newline
	pop_int($ra)

	# Parse first number from string
	la $t7, tmp_buf
	# Skip leading spaces
hc_skip1:
	lb $t8, 0($t7)
	beqz $t8, hc_badidx
	li $t9, ' '
	beq $t8, $t9, hc_skip1_nxt
	j hc_p1
hc_skip1_nxt:
	addiu $t7, $t7, 1
	j hc_skip1
hc_p1:
	li $t5, 0
hc_p1_lp:
	lb $t8, 0($t7)
	li $t9, '0'
	blt $t8, $t9, hc_p1_done
	li $t9, '9'
	bgt $t8, $t9, hc_p1_done
	subu $t8, $t8, '0'
	li $t9, 10
	mult $t5, $t9
	mflo $t5
	addu $t5, $t5, $t8
	addiu $t7, $t7, 1
	j hc_p1_lp
hc_p1_done:
	# Skip to second number
hc_skip2:
	lb $t8, 0($t7)
	beqz $t8, hc_p2
	li $t9, ' '
	beq $t8, $t9, hc_skip2_nxt
	j hc_p2
hc_skip2_nxt:
	addiu $t7, $t7, 1
	j hc_skip2
hc_p2:
	li $t6, 0
hc_p2_lp:
	lb $t8, 0($t7)
	beqz $t8, hc_p2_done
	li $t9, '0'
	blt $t8, $t9, hc_p2_done
	li $t9, '9'
	bgt $t8, $t9, hc_p2_done
	subu $t8, $t8, '0'
	li $t9, 10
	mult $t6, $t9
	mflo $t6
	addu $t6, $t6, $t8
	addiu $t7, $t7, 1
	j hc_p2_lp
hc_p2_done:
	# $t5 = first index (1-based), $t6 = second index (1-based)

	# Convert to 0-based and validate: 1 <= input <= line_count
	addiu $t5, $t5, -1
	bltz $t5, hc_badidx
	bge $t5, $t0, hc_badidx
	addiu $t6, $t6, -1
	bltz $t6, hc_badidx
	bge $t6, $t0, hc_badidx

	# Build combined expression: (expr1)*(expr2)
	la $t4, combined_buffer

	# '('
	li $t7, '('
	sb $t7, 0($t4)
	addiu $t4, $t4, 1

	# Copy expr1
	sll $t7, $t5, 2
	la $t8, line_starts
	addu $t8, $t8, $t7
	lw $t7, 0($t8)
	la $a1, history_content
	addu $a1, $a1, $t7

hc_copy1:
	lb $t9, 0($a1)
	beqz $t9, hc_copy1_done
	li $t3, '\n'
	beq $t9, $t3, hc_copy1_done
	sb $t9, 0($t4)
	addiu $t4, $t4, 1
	addiu $a1, $a1, 1
	j hc_copy1
hc_copy1_done:

	# ')*( '
	li $t7, ')'
	sb $t7, 0($t4)
	addiu $t4, $t4, 1
	li $t7, '*'
	sb $t7, 0($t4)
	addiu $t4, $t4, 1
	li $t7, '('
	sb $t7, 0($t4)
	addiu $t4, $t4, 1

	# Copy expr2
	sll $t7, $t6, 2
	la $t8, line_starts
	addu $t8, $t8, $t7
	lw $t7, 0($t8)
	la $a1, history_content
	addu $a1, $a1, $t7

hc_copy2:
	lb $t9, 0($a1)
	beqz $t9, hc_copy2_done
	li $t3, '\n'
	beq $t9, $t3, hc_copy2_done
	sb $t9, 0($t4)
	addiu $t4, $t4, 1
	addiu $a1, $a1, 1
	j hc_copy2
hc_copy2_done:

	# ')'
	li $t7, ')'
	sb $t7, 0($t4)
	addiu $t4, $t4, 1
	# '\0'
	sb $zero, 0($t4)

	# Display combined result
	print_str(hist_combined)
	la $a0, combined_buffer
	li $v0, 4
	syscall
	println()

	# Copy combined_buffer to input_buffer
	la $a0, combined_buffer
	la $a1, input_buffer
	push_int($ra)
	jal strcpy
	pop_int($ra)

	li $v0, 0
	jr $ra

hc_need2:
	print_str(hist_need2)
	li $v0, 1
	jr $ra

hc_badidx:
	print_str(hist_badidx)
	li $v0, 1
	jr $ra
