	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	mv	s0, a0
	call	line_length
	mv	s1, a0

	slli	a0, s1, 3
	call	malloc
	mv	s3, a0

	slli	a0, s1, 3
	call	malloc
	mv	s4, a0

	# terminator
	addi	sp, sp, -16
	li	t0, -1
	sd	t0, 0(sp)

	# by default all rows and columns will expand, until a galaxy is found
	li	t2, 1000000
	li	t3, 2
	mv	t0, s3
loop_vectors:
	mv	t1, s1
loop_fill:
	sd	t2, 0(t0)
	addi	t0, t0, 8
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
	sd	s8, 0(sp)
	sd	s9, 8(sp)
	li	t0, 1
	slli	t1, s8, 3
	add	t1, t1, s3
	sd	t0, 0(t1)
	slli	t1, s9, 3
	add	t1, t1, s4
	sd	t0, 0(t1)
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
	ld	t0, 0(t3)
	sd	x0, 0(t3)
	dec	t1
	addi	t3, t3, 8
loop_col_coords:
	ld	t2, 0(t3)
	add	t6, t6, t0
	sd	t6, 0(t3)
	mv	t0, t2
	addi	t3, t3, 8
	dec	t1
	bnez	t1, loop_col_coords


	# change rows coordinates to account for expansion
	mv	t1, s1	
	mv	t4, s4
	clr	t6
	ld	t0, 0(t4)
	sd	x0, 0(t4)
	dec	t1
	addi	t4, t4, 8
loop_row_coords:
	ld	t2, 0(t4)
	add	t6, t6, t0
	sd	t6, 0(t4)
	mv	t0, t2
	addi	t4, t4, 8
	dec	t1
	bnez	t1, loop_row_coords


	# change galaxies coordinates
	mv	t0, s0
loop_change_coords:
	ld	t3, 0(t0)
	ld	t4, 8(t0)
	bltz	t3, loop_change_coords_end
	slli	t3, t3, 3
	slli	t4, t4, 3
	add	t3, t3, s3
	add	t4, t4, s4
	ld	t3, 0(t3)
	ld	t4, 0(t4)	
	sd	t3, 0(t0)
	sd	t4, 8(t0)
	addi	t0, t0, 16
	j	loop_change_coords
loop_change_coords_end:


	# compute Manhattan distances for every couple of coordinates and accumulate them
	mv	s0, sp
	clr	s11
loop_outer:	
	ld	s4, 0(s0)
	ld	s5, 8(s0)
	bltz	s4, loop_outer_end
	addi	s1, s0, 16
loop_inner:
	ld	t2, 0(s1)
	ld	t3, 8(s1)
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
	
	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	.section .rodata

filename:
	.string "inputs/day11"

