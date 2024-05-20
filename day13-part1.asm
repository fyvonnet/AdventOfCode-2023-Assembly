	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1

	clr	s6					# clear rows sum
	clr	s7					# clear columns sum

loop:

	mv	a0, s0
	call	line_length
	mv	s2, a0					# columns count

	add	t6, sp, -1

	clr	s3					# rows counter
	li	t2, ASCII_LF
loop_read_pattern:
	lb	t1, 0(s0)
	bne	t1, t2, not_lf
	inc	s3
	lb	t1, 1(s0)				# load first character after the LF
	beq	t1, t2,  loop_read_pattern_end		# end loop if also LF
	beqz	t1, loop_read_pattern_end
	j	after_lf
not_lf:
	dec	sp
	sb	t1, 0(sp)
after_lf:
	inc	s0
	j	loop_read_pattern
loop_read_pattern_end:

	mv	s1, sp
	mv	t0, sp

loop_invert:
	lb	t1, 0(t0)
	lb	t5, 0(t6)
	sb	t5, 0(t0)
	sb	t1, 0(t6)
	inc	t0
	dec	t6
	bgt	t6, t0, loop_invert

	li	s4, 0
	mv	s5, s3
loop_validate_rows:
	mv	a0, s1
	mv	a1, s4
	mv	a2, s2
	mv	a3, s3
	call	validate_row
	bnez	a0, validate_rows_ok
	inc	s4
	beq	s4, s5, validate_rows_fail
	j	loop_validate_rows

	li	s4, 1
	addi	s5, s2, -2
validate_rows_ok:
	inc	s4
	add	s6, s6, s4

	j	validate_end


# no row is valid, check columns
validate_rows_fail:

	mv	a0, s1
	li	s4, 0
	mv	s5, s2
loop_validate_cols:
	mv	a0, s1
	mv	a1, s4
	mv	a2, s2
	mv	a3, s3
	call	validate_col
	bnez	a0, validate_cols_ok
	inc	s4
	beq	s4, s5, validate_cols_fail
	j	loop_validate_cols
validate_cols_fail:
	# if the program reaches here, we have a problem
	li	a7, SYS_EXIT
	li	a0, 1
	ecall
validate_cols_ok:
	inc	s4
	add	s7, s7, s4

#	mv	a0, s1
#	li	a1, 4
#	mv	a2, s2
#	mv	a3, s3
#	call	validate_col
validate_end:
nop
	addi	s0, s0, 2
	blt	s0, s11, loop

	li	t0, 100
	mul	s6, s6, t0
	add	a0, s6, s7
	call	print_int
end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	# a0: map
	# a1: col
	# a2: n columns
	# a3: n cols
validate_col:
	addi	sp, sp, -56
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	mv	s4, a1
	addi	s5, s4, 1

validate_col_loop:

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s3
	mv	a4, s2


	call	compare_cols
	beqz	a0, validate_col_failed

	dec	s4
	bltz	s4, validate_col_succ
	inc	s5
	beq	s5, s2, validate_col_succ

	j	validate_col_loop

validate_col_succ:
	li	a0, 1
	j	validate_col_ret
	
validate_col_failed:
	clr	a0

validate_col_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 56
	ret

	# a0: map
	# a1: row
	# a2: n columns
	# a3: n rows
validate_row:
	addi	sp, sp, -56
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	#blez	a1, validate_row_failed
	#addi	t0, a3, -2
	#bge	a1, t0, validate_row_failed
	

	mv	s4, a1
	addi	s5, s4, 1

validate_row_loop:

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s2


	call	compare_rows
	beqz	a0, validate_row_failed

	dec	s4
	bltz	s4, validate_row_succ
	inc	s5
	beq	s5, s3, validate_row_succ

	j	validate_row_loop

validate_row_succ:
	li	a0, 1
	j	validate_row_ret
	
validate_row_failed:
	clr	a0

validate_row_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 56
	ret

	# a0: map
	# a1: first col
	# a2: second col
	# a3: length
	# a4: n cols
compare_cols:
	add	a1, a1, a0
	add	a2, a2, a0
compare_cols_loop:
	lb	t0, 0(a1)
	lb	t1, 0(a2)
	bne	t0, t1, cols_not_equal
	add	a1, a1, a4
	add	a2, a2, a4
	dec	a3
	bnez	a3, compare_cols_loop
	li	a0, 1
	ret
cols_not_equal:
	li	a0, 0
	ret

	# a0: map
	# a1: first row
	# a2: second row
	# a3: length
compare_rows:
	mul	a1, a1, a3
	add	a1, a1, a0
	mul	a2, a2, a3
	add	a2, a2, a0
compare_rows_loop:
	lb	t0, 0(a1)
	lb	t1, 0(a2)
	bne	t0, t1, rows_not_equal
	inc	a1
	inc	a2
	dec	a3
	bnez	a3, compare_rows_loop
	li	a0, 1
	ret
rows_not_equal:
	li	a0, 0
	ret

	# a0: map
	# a1: column
	# a2: row
	# a3: nb of columns
get_addr:
	mul	t0, a2, a3
	add	t0, t0, a1
	add	a0, a0, t0
	ret

	.section .rodata

filename:
	#.string "inputs/day13-test"
	.string "inputs/day13"

