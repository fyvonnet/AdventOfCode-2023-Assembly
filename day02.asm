	.global _start

	.include "macros.inc"
	.include "constants.inc"

	.section .text

_start:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	la	s1, color_skip
	la	s2, bag_content

	add	sp, sp, -3			# allocate stack space for maxima for each color
	mv	s3, sp

	clr	s4				# initialize sum for part 1
	clr	s5				# initialize sum for part 2

loop_input:
	# set maxima to zero
	sb	zero, 0(s3)
	sb	zero, 1(s3)
	sb	zero, 2(s3)
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
	li	t0, ASCII_R
	beq	t0, t1, red
	li	t0, ASCII_G
	beq	t0, t1, green
	li	t0, ASCII_B
	beq	t0, t1, blue
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
	li	s6, 1
	mv	t0, s3
	.rept 3
	lb	t1, 0(t0)
	mul	s6, s6, t1
	inc	t0
	.endr
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

red:
	li	t0, 0
	j	next
green:
	li	t0, 1
	j	next
blue:
	li	t0, 2
next:
	# load chracters offset
	add	t1, s1, t0
	lb	t1, 0(t1)
	add	a0, a0, t1

	# check if count OK
	add	t1, s2, t0
	lb	t1, 0(t1)
	ble	a1, t1, ok
	li	s9, 0				# mark line as not valid
ok:
	# check if new maximum found
	add	t1, s3, t0
	lb	t2, 0(t1)
	ble	a1, t2, skip_max
	sb	a1, 0(t1)
skip_max:
	j	back

	.section .rodata

bag_content:
	.byte	12, 13, 14

color_skip:
	.byte	3, 5, 4

filename:
	.string "inputs/day02"

