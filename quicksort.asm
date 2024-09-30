	.globl	quicksort

	.section .text

quicksort:
	addi	sp, sp, -96
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)
	sd	s8, 72(sp)
	sd	s9, 80(sp)

	mv	s0, a0		# base
	mv	s2, a2		# size
	mv	s3, a3		# compar
	
	addi	a1, a1, -1
	mul	a1, a1, s2	# hi
	add	a1, a1, a0
	call	_quicksort

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	ld	s8, 72(sp)
	ld	s9, 80(sp)
	addi	sp, sp, 96
	ret


_quicksort:
	bge	a0, a1, end_quicksort
	blt	a0, s0, end_quicksort

	addi	sp, sp, -32
	sd	ra, 0(sp)
	sd	a0, 8(sp)
	sd	a1, 16(sp)

	call	partition
	mv	s9, a0

	ld	a0, 8(sp)
	sub	a1, s9, s2
	call	_quicksort
	
	add	a0, s9, s2
	ld	a1, 16(sp)
	call	_quicksort
	
	ld	ra, 0(sp)
	addi	sp, sp, 32
end_quicksort:
	ret


partition:
	addi	sp, sp, -16
	sd	ra, 0(sp)

	mv	s4, a1		# pivot
	sub	s5, a0, s2	# i = lo - 1
	mv	s6, a0		# j = lo

loop_partition:
	mv	a0, s6
	mv	a1, s4
	jalr	ra, s3		# call compar
	bgtz	a0, skip_swap
	add	s5, s5, s2	# i = i + 1
	mv	a0, s5
	mv	a1, s6
	call	swap
skip_swap:
	add	s6, s6, s2	# j = j + 1
	bne	s6, s4, loop_partition

	add	s5, s5, s2
	mv	a0, s4
	mv	a1, s5
	call	swap
	mv	a0, s5

	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

swap:
	mv	t0, a0
	mv	t1, a1
	mv	t2, s2
swap_loop:
	lb	t3, 0(t0)
	lb	t4, 0(t1)
	sb	t4, 0(t0)
	sb	t3, 0(t1)
	addi	t0, t0, 1
	addi	t1, t1, 1
	addi	t2, t2, -1
	bnez	t2, swap_loop
	ret
