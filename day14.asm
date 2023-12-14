	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	mv	s10, a1
	add	s11, a0, a1

	# allocate stack space for map
	sub	sp, sp, a1

	mv	a0, s0
	call	line_length
	mv	s1, a0

	# copy map without LFs to the stack
	mv	t0, sp
	li	t2, ASCII_LF
loop_copy:
	lb	t1, 0(s0)
	beq	t1, t2, lf_found
	sb	t1, 0(t0)
	inc	t0
lf_found:
	inc	s0
	bne	s0, s11, loop_copy
	sb	zero, 0(t0)

	sub	t0, t0, sp				# characters count
	div	s7, t0, s1				# rows count

	mv	s0, sp

	# make round rocks roll to the top of the map
	add	s2, s0, s1				# start at the second row
	la	s3, ASCII_CAP_O
	la	s6, ASCII_DOT
loop_foreach_rocks:
	lb	t0, 0(s2)
	beqz	t0, loop_foreach_rocks_end		# end of map reached
	bne	t0, s3, skip_rock			# not a square
	sb	s6, 0(s2)				# remove rock from current square
	mv	s4, s2
loop_move_rock:
	sub	s5, s4, s1				# north square pointer
	blt	s5, s0, loop_move_rock_end		# north square is outside the map
	lb	t0, 0(s5)				# load content of north square
	bne	t0, s6, loop_move_rock_end		# north square is occupied
	mv	s4, s5
	j	loop_move_rock
loop_move_rock_end:	
	sb	s3, 0(s4)				# put rock down
skip_rock:
	inc	s2
	j	loop_foreach_rocks
loop_foreach_rocks_end:


	clr	s8					# total load
loop_foreach_row:
	clr	s9					# rocks on current row
	mv	t0, s1					# row countdown
loop_foreach_square:
	lb	t1, 0(s0)				# load square content
	bne	t1, s3, skip_square_2			# skip increment counter if not a round square
	inc	s9
skip_square_2:
	inc	s0					# move to next square
	dec	t0					# decrement raw countdown
	bnez	t0, loop_foreach_square			# loop while countdown not null
	mul	s9, s9, s7				# multiply rocks count with row number
	add	s8, s8, s9				# add to the sum
	dec	s7					# decrease countdown
	bnez	s7, loop_foreach_row			# loop while countdown not null
	
	mv	a0, s8
	call	print_int
	
end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	.section .rodata

filename:
	.string "inputs/day14"

