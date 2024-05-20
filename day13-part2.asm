	.global _start

	.include "constants.inc"
	.include "macros.inc"

	.set	PATTERN_WIDTH, -2
	.set	PATTERN_HEIGHT, -1


	.section .text

_start:

	la	s0, input
	addi	sp, sp, -512
	addi	s1, sp, 2
	clr	s11

loop:
	mv	a0, s0
	call	line_length
	sb	a0, PATTERN_WIDTH(s1)
	mv	t0, s1
	li	t2, ASCII_LF
	clr	t3
loop_copy_pattern:
	lb	t1, (s0)
	bne	t1, t2, not_lf
	inc	t3
	inc	s0
	lb	t1, (s0)
	beqz	t1, loop_copy_pattern_end
	beq	t1, t2, loop_copy_pattern_end
not_lf:
	sb	t1, (t0)
	inc	s0
	inc	t0
	j	loop_copy_pattern
loop_copy_pattern_end:
	sb	zero, (t0)
	sb	t3, PATTERN_HEIGHT(s1)
	inc	s0


	# check for horizontal symmetries
	lb	s2, PATTERN_HEIGHT(s1)
	addi	s2, s2, -2				# start at next-to-last row
loop_check_horiz:
	mv	a0, s1
	mv	a1, s2
	call	horizontal_symmetry
	bnez	a0, hsymm_found
	dec	s2
	bgez	s2, loop_check_horiz

	# horizontal symmetry not found,
	# check for vertical symmetries
	lb	s2, PATTERN_WIDTH(s1)
	addi	s2, s2, -2				# start at next-to-last row
loop_check_vert:
	mv	a0, s1
	mv	a1, s2
	call	vertical_symmetry
	bnez	a0, vsymm_found
	dec	s2
	bgez	s2, loop_check_vert

	# should not reach here
fail:	j fail

hsymm_found:
	inc	s2
	li	t0, 100
	mul	s2, s2, t0
	j	next

vsymm_found:
	inc	s2					# count of lines above the symmetry line

next:
	add	s11, s11, s2
	lb	t0, (s0)
	bnez	t0, loop
	
end:

	mv	a0, s11
	call	print_int
	j	exit


	# a0: base ptr
	# a1: upper row
vertical_symmetry:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0				# pattern base address
	mv	s1, a1				# left column
	addi	s2, s1, 1			# right column
	clr	s3				# differences counter

loop_vsymm:
	# code here
	mv	a0, s0
	mv 	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	compare_columns
	li	t0, 1
	bgt	a0, t0, vsymm_fail

	dec	s1
	inc	s2
	mv	s3, a0

	bltz	s1, loop_vsymm_end
	lb	t0, PATTERN_WIDTH(s0)
	beq	s2, t0, loop_vsymm_end
	j	loop_vsymm
loop_vsymm_end:
	li	t0, 1
	bne	t0, s3, vsymm_fail
	li	a0, 1
	j	vsymm_ret
vsymm_fail:
	clr	a0
vsymm_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 64
	ret
	

	# a0: base ptr
	# a1: upper row
horizontal_symmetry:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0				# pattern base address
	mv	s1, a1				# upper row
	addi	s2, s1, 1			# lower row
	clr	s3				# differences counter

loop_hsymm:
	# code here
	mv	a0, s0
	mv 	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	compare_rows
	li	t0, 1
	bgt	a0, t0, hsymm_fail

	dec	s1
	inc	s2
	mv	s3, a0

	bltz	s1, loop_hsymm_end
	lb	t0, PATTERN_HEIGHT(s0)
	beq	s2, t0, loop_hsymm_end
	j	loop_hsymm
loop_hsymm_end:
	li	t0, 1
	bne	t0, s3, hsymm_fail
	li	a0, 1
	j	hsymm_ret
hsymm_fail:
	clr	a0
hsymm_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 64
	ret
	


	# a0: base address
	# a1: first row
	# a2: second row
	# a3: count init
compare_rows:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s6, a3		# diff count

	clr 	s3		# column
	lb	s4, PATTERN_WIDTH(a0)
	#clr	s6		# diff count
loop_compare_rows:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s3
	call	get_symbol
	mv	s5, a0
	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	call	get_symbol
	beq	a0, s5, requal
	inc	s6
requal:
	inc	s3
	bne	s3, s4, loop_compare_rows
	mv	a0, s6

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	addi	sp, sp, 64
	ret


	# a0: base address
	# a1: first column
	# a2: second column
	# a3: count init
compare_columns:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s6, a3		# diff count

	clr 	s3		# row
	lb	s4, PATTERN_HEIGHT(a0)
	#clr	s6		# diff count
loop_compare_columns:
	mv	a0, s0
	mv	a1, s3
	mv	a2, s1
	call	get_symbol
	mv	s5, a0
	mv	a0, s0
	mv	a1, s3
	mv	a2, s2
	call	get_symbol
	beq	a0, s5, cequal
	inc	s6
cequal:
	inc	s3
	bne	s3, s4, loop_compare_columns
	mv	a0, s6

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	addi	sp, sp, 64
	ret


	# a0: base address
	# a1: row
	# a2: column
get_symbol:
	lb	t0, PATTERN_WIDTH(a0)
	mul	t0, t0, a1
	add	t0, t0, a2
	add	t0, t0, a0
	mv	a1, t0
	lb	a0, (t0)
	ret


	.section .rodata

input:	.incbin "inputs/day13"
	.zero	2

