	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	# terminator
	addi	sp, sp, -16
	sd	zero, (sp)

	# clear sums
	clr	s8
	clr	s9

loop_lines:

	# read one input line as the first sequence
	call	read_line
	addi	sp, sp, -16
	mv	s10, a0				# save input pointer
	mv	s1, a1				# copy counter
	sd	a2, (sp)			# store vector pointer in stack


	# generate differences sequences until all-zero sequence reached
	mv	a0, a2
loop_diffs:
	dec	s1
	mv	a1, s1
	call	differences			# get difference vector pointer
	beqz	a0, loop_diffs_end		# end loop if null pointer received
	addi	sp, sp, -16			# allocate stack space
	sd	a0, (sp)			# store pointer on the stack
	j	loop_diffs
loop_diffs_end:

	# initialize first extrapolated values
	clr	s2
	clr	s3

	# extrapolate values from the last to the first sequence
loop_extra:
	ld	a2, (sp)			# load vector pointer
	beqz	a2, loop_extra_end		# null pointer reached, end loop
	
	# extrapolate value at end of vector (part 1)
	li	t6, 4
	mul	t6, t6, s1
	add	t1, a2, t6
	lw	t3, 0(t1)			# load last valueof the vector
	add	s2, s2, t3

	# extrapolate value at beginning of vector (part 2)
	lw	t3, 0(a2)			# load first value of the vector
	sub	s3, t3, s3			# extrapolate new value

	ld	a0, (sp)			# load first vector pointer
	call	free				# free vector
	addi	sp, sp, 16			# free stack space
	inc	s1
	j	loop_extra
loop_extra_end:

	# add extrapolated values to their sums
	add	s8, s8, s2
	add	s9, s9, s3

	mv	a0, s10
	blt	a0, s11, loop_lines		# loop if end of file not reached

	mv	a0, s8
	call	print_int

	mv	a0, s9
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall



differences:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	slli	a0, a1, 2
	call	malloc
	mv	t3, a0

	li	a1, 1				# all-zero flag

loop_diff:
	lw	t0, 0(s0)			# load value
	lw	t1, 4(s0)			# load next value
	sub	t2, t1, t0			# compute difference
	sw	t2, 0(t3)			# store in differences vector
	beqz	t2, is_zero			# check if diff is null
	clr	a1				# clear all-zero flag of not null
is_zero:
	add	s0, s0, 4
	add	t3, t3, 4
	dec	s1
	bnez	s1, loop_diff

	beqz	a1, not_all_zero
	call	free
	clr	a0				# return null pointer when all differences are null
not_all_zero:
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 32

	ret

	



	# rea

read_line:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	dec	a0
	clr	s2

loop_read_line:
	inc	a0
	inc	s2
	call	parse_integer
	addi	sp, sp, -16
	sw	a1, (sp)
	lb	t0, (a0)
	li	t1, ASCII_LF
	bne	t0, t1, loop_read_line

	mv	s0, a0				# save input pointer
	slli	a0, s2, 2
	call	malloc
	mv	a2, a0				# copy allocated memory pointer 
	mv	a0, s0				# restore input pointer

	# copy elements from the stack to the heap
	li	t0, 4
	mul	t0, t0, s2
	add	t0, t0, a2
	sb	zero, 0(t0)			# clear interpolated value
	addi	t0, t0, -4
	mv	t1, s2				# initialize countdown
loop_copy:
	lw	t2, (sp)
	sw	t2, (t0)
	addi	sp, sp, 16
	addi	t0, t0, -4
	dec	t1
	bnez	t1, loop_copy

	inc	a0				# skip LF

	mv	a1, s2				# vector pointer

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 32
	ret
	
	

	.section .rodata

filename:
	.string "inputs/day09"

