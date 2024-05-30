	.global _start

	.include "macros.inc"
	.include "constants.inc"

	.section .text

_start:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	mv	s0, a0
	call	line_length
	mv	s1, a0

	slli	t0, s1, 1
	sub	sp, sp, t0
	mv	s3, sp

	slli	t0, s1, 1
	sub	sp, sp, t0
	mv	s4, sp

	# align stack
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0

	# terminator
	addi	sp, sp, -16
	li	t0, -1
	sh	t0, 0(sp)

	# by default all rows and columns will expand, until a galaxy is found
	li	t3, 2
	mv	t0, s3
loop_vectors:
	mv	t1, s1
	li	t2, 2
loop_fill:
	sh	t2, 0(t0)
	addi	t0, t0, 2
	dec	t1
	bnez	t1, loop_fill
	mv	t0, s4
	dec	t3
	bnez	t3, loop_vectors

	li	t6, ASCII_HASH
	li	t5, ASCII_LF
	clr	s8
	clr	s9
	clr	s2
loop_input:
	lb	t0, 0(s0)
	beq	t0, t6, found_hash
	beq	t0, t5, found_lf
	j	loop_input_next
found_hash:
	addi	sp, sp, -16
	sh	s8, 0(sp)
	sh	s9, 2(sp)
	li	t0, 1
	slli	t1, s8, 1
	add	t1, t1, s3
	sh	t0, 0(t1)
	slli	t1, s9, 1
	add	t1, t1, s4
	sh	t0, 0(t1)
	inc	s2
	j	loop_input_next
found_lf:
	inc	s9
	li	s8, -1
loop_input_next:
	inc	s8
	inc	s0
	blt	s0, s11, loop_input

	mv	s0, sp
	

	# change column coordinates to account for expansion
	mv	t1, s1	
	mv	t3, s3
	clr	t6
	lh	t0, 0(t3)
	sh	x0, 0(t3)
	dec	t1
	addi	t3, t3, 2
loop_col_coords:
	lh	t2, 0(t3)
	add	t6, t6, t0
	sh	t6, 0(t3)
	mv	t0, t2
	addi	t3, t3, 2
	dec	t1
	bnez	t1, loop_col_coords


	# change rows coordinates to account for expansion
	mv	t1, s1	
	mv	t4, s4
	clr	t6
	lh	t0, 0(t4)
	sh	x0, 0(t4)
	dec	t1
	addi	t4, t4, 2
loop_row_coords:
	lh	t2, 0(t4)
	add	t6, t6, t0
	sh	t6, 0(t4)
	mv	t0, t2
	addi	t4, t4, 2
	dec	t1
	bnez	t1, loop_row_coords

	# change galaxies coordinates
	mv	t0, s0
loop_change_coords:
	lh	t3, 0(t0)
	lh	t4, 2(t0)
	bltz	t3, loop_change_coords_end
	slli	t3, t3, 1
	slli	t4, t4, 1
	add	t3, t3, s3
	add	t4, t4, s4
	lh	t3, 0(t3)
	lh	t4, 0(t4)	
	sh	t3, 0(t0)
	sh	t4, 2(t0)
	addi	t0, t0, 16
	j	loop_change_coords
loop_change_coords_end:
	
	
	# compute Manhattan distances for every couple of coordinates and accumulate them
	mv	s0, sp
	clr	s11
loop_outer:	
	lh	s4, 0(s0)
	lh	s5, 2(s0)
	bltz	s4, loop_outer_end
	addi	s1, s0, 16
loop_inner:
	lh	t2, 0(s1)
	lh	t3, 2(s1)
	bltz	t2, loop_inner_end
	
	sub	s2, s4, t2
	sub	s3, s5, t3

	mv	a0, s2
	call	abs
	mv	s2, a0

	mv	a0, s3
	call	abs
	mv	s3, a0

	add	s2, s2, s3
	add	s11, s11, s2
	
	addi	s1, s1, 16
	j	loop_inner
loop_inner_end:
	addi	s0, s0, 16
	j	loop_outer
loop_outer_end:

	mv	a0, s11
	call	print_int
	
end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

abs:
	bgez	a0, not_neg
	neg	a0, a0
not_neg:
	ret

	.section .rodata

filename:
	.string "inputs/day11"

