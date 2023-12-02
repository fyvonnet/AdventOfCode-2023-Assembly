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

	clr	s4				# initialize sum for part 1
	clr	s5				# initialize sum for part 2

loop_input:
	clr	s6				# max red
	clr	s7				# max green
	clr	s8				# max blue
	li	s9, 1				# mark line as OK
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
	beq	t0, t1, loop_line_end
	addi	a0, a0, 2			# skip ", "
	j	loop_line
loop_line_end:
	beqz	s9, skip_add
	add	s4, s4, s0			# add game number to the part 1 sum
skip_add:
	mul	s6, s6, s7
	mul	s6, s6, s8
	add	s5, s5, s6			# add power to the part 2 sum
	inc	a0
	j	loop_input
	

loop_input_end:

	mv	a0, s4
	call	print_int

	mv	a0, s5
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

blue:
	addi	a0, a0, 4
	ble	a1, s3, blue_ok
	li	s9, 0
blue_ok:
	ble	a1, s8, skip_blue_max
	mv	s8, a1
skip_blue_max:
	j	back

green:
	addi	a0, a0, 5
	ble	a1, s2, green_ok
	li	s9, 0
green_ok:
	ble	a1, s7, skip_green_max
	mv	s7, a1
skip_green_max:
	j	back

red:
	addi	a0, a0, 3
	ble	a1, s1, red_ok
	li	s9, 0
red_ok:
	ble	a1, s6, skip_red_max
	mv	s6, a1
skip_red_max:
	j	back

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

