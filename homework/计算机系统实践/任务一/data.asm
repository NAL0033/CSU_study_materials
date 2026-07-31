# ============================================================
# data.asm — Data segment definitions
# All static data: buffers, prompt strings, float constants, state flags
# ============================================================

.data
.align 2

# ==================== File names ====================
history_file:    .asciiz "history.txt"

# ==================== Basic strings ====================
newline:         .asciiz "\n"
space:           .asciiz " "
space2:          .asciiz "  "
dot:             .asciiz "."
lparen:          .asciiz "("
rparen:          .asciiz ")"
times_sign:      .asciiz " * "
equals_sign:     .asciiz " = "
plus_char:       .asciiz " + "
minus_char:      .asciiz " - "
mul_char:        .asciiz " * "
div_char:        .asciiz " / "

# ==================== Menu strings ====================
menu_title:      .asciiz "\n========== MIPS Calculator ==========\n"
menu_1:          .asciiz "1. Calculate expression\n"
menu_2:          .asciiz "2. Read history\n"
menu_3:          .asciiz "3. Clear history\n"
menu_4:          .asciiz "4. Exit\n"
menu_prompt:     .asciiz "Enter choice (1-4): "
menu_invalid:    .asciiz "Invalid choice, please re-enter!\n"

# ==================== Calculation prompts ====================
calc_prompt:     .asciiz "Enter expression (p=previous, h=history combine): "
recalled_msg:    .asciiz "[Recalled previous] "
no_prev_msg:     .asciiz "No previous expression.\n"
empty_input_msg: .asciiz "Input is empty, please re-enter.\n"

# ==================== Result/step strings ====================
steps_header:    .asciiz "\n--- Solution Steps ---\n"
result_msg:      .asciiz "Result: "
div_zero_err:    .asciiz "Error: Division by zero!\n"
syntax_err:      .asciiz "Syntax error: Invalid expression format!\n"
paren_err:       .asciiz "Parentheses mismatch!\n"
eval_err:        .asciiz "Evaluation error!\n"
overflow_msg:    .asciiz "Error: Token count exceeds limit!\n"

# ==================== History strings ====================
hist_header:     .asciiz "\n--- History ---\n"
hist_empty:      .asciiz "(No history)\n"
hist_page:       .asciiz "Page "
hist_of:         .asciiz " / "
hist_page2:      .asciiz "\n"
hist_nav:        .asciiz "\n[n]next [p]prev [q]back: "
hist_confirm:    .asciiz "Confirm clear all history? (y/n): "
hist_cleared:    .asciiz "History cleared.\n"
hist_cancelled:  .asciiz "Cancelled.\n"
hist_select:     .asciiz "Enter two indices (e.g. '3 5'): "
hist_badidx:     .asciiz "Invalid index!\n"
hist_need2:      .asciiz "Need at least 2 history entries to combine.\n"
hist_combined:   .asciiz "Combined expression: "
hist_count_msg:  .asciiz " entries): \n"
hist_prompt_num: .asciiz "History #"
hist_colon:      .asciiz ": "

# ==================== Pause prompt ====================
press_any_key:   .asciiz "\nPress Enter to continue..."

# ==================== Float constants (IEEE 754 single precision) ====================
fp_const_10:     .float 10.0
fp_const_neg1:   .float -1.0
fp_const_0:      .float 0.0
fp_const_1:      .float 1.0
fp_const_0_5:    .float 0.5
fp_const_1000000: .float 1000000.0

# ==================== State flags ====================
has_previous:    .word 0          # 1 = recall_buffer has previous expression
eval_err_flag:   .word 0          # set to 1 on error

# ==================== Input buffers ====================
input_buffer:    .space 512       # raw expression from user
combined_buffer: .space 512       # combined expression from history

# ==================== Tokenizer ====================
# Token format (8 bytes = 2 words):
#   offset 0: type (word) — 0=NUMBER, 1=+, 2=-, 3=*, 4=/, 5=(, 6=)
#   offset 4: value (word) — IEEE 754 float bits (NUMBER); 0 (others)
token_array:     .space 1600      # 200 tokens * 8 bytes
token_count:     .word 0          # current token count

# ==================== Postfix expression queue ====================
postfix_queue:   .space 1600      # 200 tokens * 8 bytes
postfix_count:   .word 0          # token count in postfix queue

# ==================== Operator stack (shunting yard) ====================
op_stack:        .space 400       # 100 words
op_top:          .word -1         # stack top index, -1 = empty

# ==================== Evaluation stack (float values) ====================
eval_stack:      .space 400       # 100 IEEE 754 float bits

# ==================== Step recording ====================
# Each record 16 bytes (4 words):
#   offset 0:  operand1 (IEEE 754)
#   offset 4:  operator  (1=+, 2=-, 3=*, 4=/)
#   offset 8:  operand2 (IEEE 754)
#   offset 12: result    (IEEE 754)
step_buffer:     .space 800       # 50 steps * 16 bytes
step_count:      .word 0          # recorded step count

# ==================== History buffers ====================
recall_buffer:   .space 512       # previous expression text
history_content: .space 16384     # full history file content
line_starts:     .space 800       # 200 words: line start offset
line_count:      .word 0          # total history line count

# ==================== Number-to-string conversion temp buffers ====================
float_buf1:      .space 64        # general float string buffer
float_buf2:      .space 64
float_buf3:      .space 64
float_buf4:      .space 64
int_buf:         .space 32        # integer string buffer
tmp_buf:         .space 128       # general temp buffer
