	.global	cache_init
	.global	cache_query
	

	.set	RED, 		 0
	.set	BLACK,		 1

	.set	TREE_SIZE,	24
	.set	TREE_ROOT,	 0
	.set	TREE_NIL,	 8
	.set	TREE_FREE,	16

	.set	NODE_SIZE,	48
	.set	NODE_LEFT,	 0
	.set	NODE_RIGHT,	 8
	.set	NODE_P,		16
	.set	NODE_KEY,	24
	.set	NODE_VALUE,	32
	.set	NODE_COLOR,	40

	.section .text

cache_init:
	addi	t0, a0, TREE_SIZE	# nil
	li	t1, BLACK
	sb	t1, NODE_COLOR(t0)
	
	# tree.root and tree.nil initialized nith nil
	sd	t0, TREE_ROOT(a0)
	sd	t0, TREE_NIL(a0)

	addi	t0, t0, NODE_SIZE
	sd	t0, TREE_FREE(a0)
	
	ret



	# a0: cache
	# a1: i
	# a2: n
	# a3: b
	# a4: val
cache_query:
	addi	sp, sp, -64
	sd	ra,  0(sp)		
	sd	s0,  8(sp)		# T
	sd	s1, 16(sp)		# z
	#sd	s2, 24(sp)		# x
	sd	s3, 32(sp)		# x
	sd	s4, 40(sp)		# T.nil
	sd	s5, 48(sp)		# y
	#sd	s6, 56(sp)

	mv	s0, a0

	# compute key
	mv	t6, zero
	or	t6, t6, a1
	slli	t6, t6, 16
	or	t6, t6, a2
	slli	t6, t6, 16
	or	t6, t6, a3

	ld	s3, TREE_ROOT(s0)	# x = t.root
	ld	s4, TREE_NIL(s0)	# load t.nil
	mv	s5, s4			# y = t.nil

si_while_loop:
	beq	s3, s4, si_while_loop_end
	mv	s5, s3			# y = x
	ld	t0, NODE_KEY(s3)	# x.value
	blt	t6, t0, move_left
	bgt	t6, t0, move_right
	j	insert_end_found
move_left:
	ld	s3, NODE_LEFT(s3)
	j	si_while_loop
move_right:
	ld	s3, NODE_RIGHT(s3)
	j	si_while_loop
si_while_loop_end:
	ld	s1, TREE_FREE(s0)
	sd	s4, NODE_LEFT(s1)	# z.left = T.nil
	sd	s4, NODE_RIGHT(s1)	# z.right = T.nil
	sd	s5, NODE_P(s1)		# z.p = y
	sd	t6, NODE_KEY(s1)	# z.key = key
	li	t0, RED
	sb	t0, NODE_COLOR(s1)	# z.color = RED

	bne	s5, s4, tree_not_empty	# y != T.nil
	sd	s1, TREE_ROOT(s0)
	j	insert_end_not_found
tree_not_empty:
	ld	t0, NODE_KEY(s5)	# y.value
	bgt	t6, t0, store_right	# z.value > y.value
	sd	s1, NODE_LEFT(s5)
	j       insert_end_not_found
store_right:
	sd	s1, NODE_RIGHT(s5)
	j       insert_end_not_found

insert_end_found:
	li	a0, 1
	ld	a1, NODE_VALUE(s5)
	j	insert_end

insert_end_not_found:	
	addi	t0, s1, NODE_SIZE
	sd	t0, TREE_FREE(s0)
	mv	a0, s0
	mv	a1, s1
	call	insert_fixup
	li	a0, 0
	addi	a1, s1, NODE_VALUE

insert_end:	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	#ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 64
	ret


	# a0: t
	# a1: x
left_rotate:
	# t0: y
	ld	t0, NODE_RIGHT(a1)	# y = x.right
	ld	t1, NODE_LEFT(t0)	# y.left
	sd	t1, NODE_RIGHT(a1)	# x.right = y.left

	ld	t2, TREE_NIL(a0)
	beq	t1, t2, lrjmp0		# y.left == T.nil
	sd	a1, NODE_P(t1)		# y.left.p = x
lrjmp0:
	
	ld	t3, NODE_P(a1)		# x.p
	sd	t3, NODE_P(t0)		# y.p = x.p

	bne	t2, t3, lrjmp1
	sd	t0, TREE_ROOT(a0)	# T.root = y
	j	lrjmp3
lrjmp1:
	ld	t4, NODE_LEFT(t3)	# x.p.left
	bne	a1, t4, lrjmp2		# x != x.p.left
	sd	t0, NODE_LEFT(t3)	# x.p.left = y
	j	lrjmp3
lrjmp2:
	sd	t0, NODE_RIGHT(t3)	# x.p.left = y
lrjmp3:

	sd	a1, NODE_LEFT(t0)	# y.left = x
	sd	t0, NODE_P(a1)		# x.p = y
	ret
		

	# a0: t
	# a1: x
right_rotate:
	# t0: y
	ld	t0, NODE_LEFT(a1)	# y = x.left
	ld	t1, NODE_RIGHT(t0)	# y.right
	sd	t1, NODE_LEFT(a1)	# x.left = y.right

	ld	t3, TREE_NIL(a0)
	beq	t1, t3, rrjmp0		# y.right == T.nil
	sd	a1, NODE_P(t1)		# y.right.p = x
rrjmp0:

	ld	t4, NODE_P(a1)		# x.p
	sd	t4, NODE_P(t0)		# y.p = x.p

	bne	t4, t3, rrjmp1		# x.p != T.nil
	sd	t0, TREE_ROOT(a0)	# T.root = y
	j	rrjmp3
rrjmp1:
	ld	t5, NODE_LEFT(t4)	# x.p.left
	bne	a1, t5, rrjmp2
	sd	t0, NODE_LEFT(t4)	# x.p.left = y
	j	rrjmp3
rrjmp2:
	sd	t0, NODE_RIGHT(t4)	# x.p.right = y
rrjmp3:
	sd	a1, NODE_RIGHT(t0)	# y.right = x;
	sd	t0, NODE_P(a1)		# x.p = y
	ret
	
	



	# a0: t
	# a1: z
insert_fixup:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)		# T
	sd	s1, 16(sp)		# z

	mv	s0, a0			# T
	mv	s1, a1			# z

ifloop:
	li	t0, RED
	ld	t2, NODE_P(s1)		# z.p
	lb	t1, NODE_COLOR(t2)	# z.p.color
	bne	t0, t1, ifend		# z.p.color != RED
	ld	t3, NODE_P(t2)		# z.p.p
	ld	t0, NODE_LEFT(t3)	# z.p.p.left
	bne	t2, t0, ifjmp3		# z.p != z.p.p.left
	ld	t0, NODE_RIGHT(t3)	# y = z.p.p.right
	lb	t1, NODE_COLOR(t0)	# y.color
	li	t4, RED
	bne	t1, t4, ifjmp0		# y.color != RED
	li	t1, BLACK
	sb	t1, NODE_COLOR(t2)	# z.p.color = BLACK
	sb	t1, NODE_COLOR(t0)	# y.color = BLACK
	li	t1, RED
	sb	t1, NODE_COLOR(t3)	# z.p.p.color = RED
	mv	s1, t3			# z = z.p.p
	#j	ifjmp2
	j	ifloop
ifjmp0:
	ld	t2, NODE_P(s1)		# z.p
	ld	t1, NODE_RIGHT(t2)	# z.p.right
	bne	s1, t1, ifjmp1		# z != z.p.right
	mv	s1, t2			# z = z.p
	mv	a0, s0
	mv	a1, s1
	call	left_rotate
ifjmp1:
	ld	t2, NODE_P(s1)		# z.p
	ld	t3, NODE_P(t2)		# z.p.p
	li	t1, BLACK
	sb	t1, NODE_COLOR(t2)	# z.p.color = BLACK
	li	t1, RED
	sb	t1, NODE_COLOR(t3)	# z.p.p.color = BLACK
	mv	a0, s0
	mv	a1, t3
	call	right_rotate
	j	ifloop
ifjmp2:
	#j	ifjmp6
ifjmp3:
	ld	t0, NODE_LEFT(t3)	# y = z.p.p.left
	lb	t1, NODE_COLOR(t0)	# y.color
	li	t4, RED
	bne	t1, t4, ifjmp4		# y.color != RED
	li	t1, BLACK
	sb	t1, NODE_COLOR(t2)	# z.p.color = BLACK
	sb	t1, NODE_COLOR(t0)	# y.color = BLACK
	li	t1, RED
	sb	t1, NODE_COLOR(t3)	# z.p.p.color = RED
	mv	s1, t3			# z = z.p.p
	#j	ifjmp2
	j	ifloop
ifjmp4:
	ld	t2, NODE_P(s1)		# z.p
	ld	t1, NODE_LEFT(t2)	# z.p.left
	bne	s1, t1, ifjmp5		# z != z.p.left
	mv	s1, t2			# z = z.p
	mv	a0, s0
	mv	a1, s1
	call	right_rotate
ifjmp5:
	ld	t2, NODE_P(s1)		# z.p
	ld	t3, NODE_P(t2)		# z.p.p
	li	t1, BLACK
	sb	t1, NODE_COLOR(t2)	# z.p.color = BLACK
	li	t1, RED
	sb	t1, NODE_COLOR(t3)	# z.p.p.color = BLACK
	mv	a0, s0
	mv	a1, t3
	call	left_rotate
	j	ifloop

ifend:
	ld	t0, TREE_ROOT(s0)	# T.root
	li	t1, BLACK
	sb	t1, NODE_COLOR(t0)	# T.root.color = BLACK

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 32
	ret


