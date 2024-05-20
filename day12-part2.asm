	.include "macros.inc"
	.include "constants.inc"

	.bss
	.balign	8
	.type	arena, @object
	.set	ARENA_SIZE,	3*1024*1024
	.size	arena, ARENA_SIZE
arena:	.zero	ARENA_SIZE


	.data
	.type	input, @object
input:	.incbin "inputs/day12"
	.byte	0
	.size	input, .-input


	.text
	.balign	8

	.globl _start
	.type _start, @function
_start:

	la	s0, input
	clr	s7

	addi	sp, sp, -128
	mv	s8, sp
	addi	sp, sp, -128
	mv	s9, sp

loop_read:
	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar
	la	a1, alloc
	clr	a2
	call	redblacktree_init
	mv	s6, a0

	mv	t1, s8
	li	t2, ASCII_SPACE
	clr	s10
	li	s5, 5
	mv	s4, s0
	li	t6, ASCII_QUESTION
loop_copy_line_multiple:
	mv	s0, s4
loop_copy_line:
	lb	t0, (s0)
	sb	t0, (t1)
	inc	s0
	inc	t1
	inc	s10
	bne	t0, t2, loop_copy_line
	dec	t1
	sb	t6, (t1)
	inc	t1
	dec	s10
	dec	s5
	bnez	s5, loop_copy_line_multiple
	dec	t1
	sb	zero, (t1)
	addi	s10, s10, 4			# add question marks

	#la	s1, nums
	mv	s1, s9
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
	#la	s2, nums
	mv	s2, s9
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

	#la	s4, line
	#la	s9, nums

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
	.size	_start, .-_start
	



	# a0: cache
	# a1: i
	# a2: n
	# a3: b
	.type	cache_query, @function
cache_query:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0

	clr	s1
	or	s1, s1, a1
	slli	s1, s1, 16
	or	s1, s1, a2
	slli	s1, s1, 16
	or	s1, s1, a3

	la	a0, arena
	li 	a1, 16
	call	arena_alloc
	sd	s1, 0(a0)
	sd	x0, 8(a0)
	mv	s1, a0

	mv	a0, s0
	mv	a1, s1
	call	redblacktree_insert

	beqz	a0, cache_new
	mv	s0, a0

	la	a0, arena
	mv	a1, s1
	call	arena_free

	li	a0, 1
	ld	a1, 8(s0)
	j	cache_query_end

cache_new:
	li	a0, 0
	addi	a1, s1, 8
	
cache_query_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 32
	ret
	.size	cache_query, .-cache_query

	# s0 : i
	# s1 : n
	# s2 : b
	# s3 : count
	# s4 : value pointer
	# s6 : tree
	# s8 : line
	# s9 : nums
	# s10 : len_line
	# s11 : len_nums
	.type	count, @function
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

	mv	a0, s6
	mv	a1, s0
	mv	a2, s1
	mv	a3, s2
	call	cache_query
	beqz	a0, not_in_cache
	mv	s3, a1

	j	count_ret
	
not_in_cache:

	mv	s4, a1
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
	.size	count, .-count

	.type	compar, @function
compar:
	ld	t0, 0(a0)
	ld	t1, 0(a1)
	sub	a0, t0, t1
	ret
	.size	compar, .-compar


	.type	alloc, @function
alloc:
	addi	sp, sp, -16
	sd	ra,  0(sp)
	mv	a1, a0
	la	a0, arena
	call	arena_alloc
	ld	ra,  0(sp)
	addi	sp, sp, 16
	ret
	.size	alloc, .-alloc
#
