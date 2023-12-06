	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# read all numbers and store them in the stack
	clr	s0					# initialize counter
	addi	s9, sp, -2
loop_read_input:
	inc	s0
	call	skip_to_digit
	call	parse_integer
	addi	sp, sp, -2
	sh	a1, 0(sp)
	inc	a0
	blt	a0, s11, loop_read_input

	# put read numbers in the right order
	mv	t0, sp
loop_invert:
	lh	t1, 0(t0)
	lh	t2, 0(s9)
	sh	t2, 0(t0)
	sh	t1, 0(s9)
	addi	t0, t0, 2
	addi	s9, s9, -2
	blt	t0, s9, loop_invert

	li	t0, 2
	div	s0, s0, t0

	mv	s1, sp					# pointer to race times vector
	mul	t0, t0, s0
	add	s2, sp, t0				# pointer to race distances vector

	li	s3, 1					# initialize margin
loop_races:
	lh	t1, 0(s1)				# load time
	lh	t2, 0(s2)				# load record distance
	li	t0, 1					# start with 1ms push time or 1mm/s speed
	dec	t1					# one less ms available
	clr	t4					# initialize counter
loop_times:
	mul	t3, t0, t1				# distance traveled during remaining time
	ble	t3, t2, no_win				# did not beat record
	inc	t4	
no_win:
	inc	t0					# increase puch time and speed
	dec	t1					# decrease remaining race time
	bnez	t1, loop_times				# loop if race time remaining
	mul	s3, s3, t4
	addi	s1, s1, 2
	addi	s2, s2, 2
	dec	s0
	bnez	s0, loop_races

	mv	a0, s3
	call	print_int
	

end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	.section .rodata

filename:
	.string "inputs/day06"
	# .string "inputs/day06-test"

