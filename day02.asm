	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	li	s1, 12				# red
	li	s2, 13				# green
	li	s3, 14				# blue

	clr	s4				# initialize sum

loop_input:
	bge	a0, s11, loop_input_end
	addi	a0, a0, 5			# skip "Game "
	call	parse_integer
	mv	s0, a1
	addi	a0, a0, 2			# skip ": "
loop_line:
	call	parse_integer
	inc	a0				# skip to color name
	lb	t1, 0(a0)
	li	t0, ASCII_B
	beq	t0, t1, blue
	li	t0, ASCII_G
	beq	t0, t1, green
	li	t0, ASCII_R
	beq	t0, t1, red
back:
	li	t0, ASCII_LF
	lb	t1, 0(a0)
	beq	t0, t1, loop_line_end_succ
	addi	a0, a0, 2			# skip ", "
	j	loop_line
loop_line_end_succ:
	add	s4, s4, s0			# add game number to the sum
	inc	a0				# move to start of next line
	j	loop_input
	

loop_input_end:

	mv	a0, s4
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

blue:
	addi	a0, a0, 4
	ble	a1, s3, back
	call	skip_to_next_line
	j	loop_input

green:
	addi	a0, a0, 5
	ble	a1, s2, back
	call	skip_to_next_line
	j	loop_input

red:
	addi	a0, a0, 3
	ble	a1, s1, back
	call	skip_to_next_line
	j	loop_input

skip_to_next_line:
	li	t1, ASCII_LF
skip_to_next_line_loop:
	lb	t0, 0(a0)
	beq	t0, t1, skip_to_next_line_end
	inc	a0
	j	skip_to_next_line_loop
skip_to_next_line_end:
	inc	a0
	ret

	.section .rodata

filename:
	.string "inputs/day02"

