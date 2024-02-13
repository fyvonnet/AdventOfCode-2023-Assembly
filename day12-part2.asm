	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:

	la	s0, input
	clr	s7

loop_read:
	la	a0, cache_space
	call	cache_init

	la	t1, line
	li	t2, ASCII_SPACE
	clr	s10
	li	s9, 5
	mv	s8, s0
	li	t6, ASCII_QUESTION
loop_copy_line_multiple:
	mv	s0, s8
loop_copy_line:
	lb	t0, (s0)
	sb	t0, (t1)
	inc	s0
	inc	t1
	inc	s10
	bne	t0, t2, loop_copy_line
	dec	t1
	#li	t6, 63
	sb	t6, (t1)
	inc	t1
	dec	s10
	dec	s9
	bnez	s9, loop_copy_line_multiple
	dec	t1
	sb	zero, (t1)
	addi	s10, s10, 4			# add question marks

	la	s1, nums
	mv	a0, s0
	li	s3, ASCII_LF
	clr	s11
loop_copy_nums:
	call	parse_integer
	sb	a1, (s1)
	lb	t2, (a0)
	inc	a0
	inc	s1
	inc	s11
	bne	t2, s3, loop_copy_nums

	li	t0, 4
loop_duplicate_nums:
	la	s2, nums
	mv	t3, s11
loop_dup:
	lb	t1, (s2)
	sb	t1, (s1)
	inc	s2
	inc	s1
	dec	t3
	bnez	t3, loop_dup
	dec	t0
	bnez	t0, loop_duplicate_nums

	li	t0, -1
	sb	t0, (s1)

	li	t0, 5
	mul	s11, s11, t0

	mv	s0, a0

	la	s8, line
	la	s9, nums
	
	clr	a0
	clr	a1
	clr	a2
	call	count
	add	s7, s7, a0

	lb	t0, (s0)
	bnez	t0, loop_read

	mv	a0, s7
	call	print_int

	li	a7, SYS_EXIT
	li	a0, EXIT_SUCCESS
	ecall
	
	


	# s0 : i
	# s1 : n
	# s2 : b
	# s3 : count
	# s4 : value pointer
	# s8 : line
	# s9 : nums
	# s10 : len_line
	# s11 : len_nums
count:
	addi	sp, sp, -48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, zero

	bne	s0, s10, count.jmp3
	bne	s1, s11, count.jmp1
	bnez	s2, count.jmp1
	li	s3, 1
	j	count_ret
count.jmp1:
	addi	t0, s11, -1
	bne	s1, t0, count.jmp2
	add	t0, t0, s9
	lb	t0, (t0)
	bne	s2, t0, count.jmp2
	li	s3, 1
	j	count_ret
count.jmp2:
	li	s3, 0
	j	count_ret
count.jmp3:

	la	a0, cache_space
	mv	a1, s0
	mv	a2, s1
	mv	a3, s2
	call	cache_query
	beqz	a0, not_in_cache
	mv	s3, a1
	j	count_ret
not_in_cache:
	mv	s4, a1			# value pointer

	clr	s3

	add	t0, s8, s0		# line[i]
	lb	t0, (t0)
	li	t1, ASCII_DOT
	beq	t0, t1, count.jmp4
	li	t1, ASCII_QUESTION
	bne	t0, t1, count.jmp7
count.jmp4:
	bnez	s2, count.jmp5
	addi	a0, s0, 1
	mv	a1, s1
	clr	a2
	call	count
	add	s3, s3, a0
	j	count.jmp7
count.jmp5:
	bne	s1, s11, count.jmp6
	li	s3, 0
	j	count.jmp9
count.jmp6:
	add	t0, s9, s1
	lb	t0, (t0)		# nums[n]
	bne	s2, t0, count.jmp7
	addi	a0, s0, 1
	addi	a1, s1, 1
	clr	a2
	call	count
	add	s3, s3, a0
count.jmp7:
	add	t0, s8, s0		# line[i]
	lb	t0, (t0)
	li	t1, ASCII_HASH
	beq	t0, t1, count.jmp8
	li	t1, ASCII_QUESTION
	bne	t0, t1, count.jmp9
count.jmp8:
	addi	a0, s0, 1
	mv	a1, s1
	addi	a2, s2, 1
	call	count
	add	s3, s3, a0
count.jmp9:

	sd	s3, (s4)

count_ret:
	mv	a0, s3
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	addi	sp, sp, 48
	ret


	.section .data

input:
	.incbin "inputs/day12"
	.byte	0


	.section .bss

	.align 8
cache_space:
	.zero	3*1024*1024

line:	.zero	128
nums:	.zero	128

