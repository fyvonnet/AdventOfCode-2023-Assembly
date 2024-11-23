	#.globl	redblacktree_delete
	#.globl	redblacktree_pop_max
	
	.include "macros.inc"

	.set	RED, 		 0
	.set	BLACK,		 1

	.set	TREE_SIZE,	40
	.set	TREE_ROOT,	 0
	.set	TREE_NIL,	 8
	.set	TREE_COMPARE,	16
	.set	TREE_ALLOC,	24
	.set	TREE_FREE,	32

	.set	NODE_SIZE,	40
	.set	NODE_LEFT,	 0	# 8 bytes
	.set	NODE_RIGHT,	 8	# 8 bytes
	.set	NODE_P,		16	# 8 bytes
	.set	NODE_VALUE, 	24	# 8 bytes
	.set	NODE_COLOR,	32	# 1 byte

	.text

	# a0:	compare
	# a1: 	alloc
	# a2:	free
	.globl	redblacktree_init
	.type	redblacktree_init, @function
redblacktree_init:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	li	a0, TREE_SIZE
	jalr	ra, s1
	mv	s3, a0

	sd	s0, TREE_COMPARE(s3)
	sd	s1, TREE_ALLOC(s3)
	sd	s2, TREE_FREE(s3)

	li	a0, NODE_SIZE
	jalr	ra, s1
	
	sd	a0, TREE_ROOT(s3)
	sd	a0, TREE_NIL(s3)

	li	t0, BLACK
	sb	t0, NODE_COLOR(a0)
	sd	x0, NODE_LEFT(a0)
	sd	x0, NODE_RIGHT(a0)
	sd	x0, NODE_P(a0)
	sd	x0, NODE_VALUE(a0)

	mv	a0, s3

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 64
	ret
	.size	redblacktree_init, .-redblacktree_init


	# a0: tree
	# a1: value
	.globl	redblacktree_search
	.type	redblacktree_search, @function
redblacktree_search:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	mv	s0, a0
	mv	s1, a1

	ld	s2, TREE_COMPARE(s0)
	ld	s3, TREE_ROOT(s0)
	ld	s4, TREE_NIL(s0)

search_loop:
	beq	s3, s4, search_fail
	mv	a0, s1
	ld	a1, NODE_VALUE(s3)
	jalr	ra, s2
	bltz	a0, search_left
	bgtz	a0, search_right
	ld	a0, NODE_VALUE(s3)
	j	search_end

search_left:
	ld	s3, NODE_LEFT(s3)
	j	search_loop
	
search_right:
	ld	s3, NODE_RIGHT(s3)
	j	search_loop
	
search_fail:
	clr	a0

search_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	addi	sp, sp, 64
	ret
	.size	redblacktree_search, .-redblacktree_search


	
	# a0: tree
	# a1: value
	.globl	redblacktree_insert_or_free
	.type	redblacktree_insert_or_free, @function
redblacktree_insert_or_free:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	call	redblacktree_insert

	mv	s2, s1
	clr	a1

	beqz	a0, redblacktree_insert_or_free_ret

	mv	s2, a0
	ld	t0, TREE_FREE(s0)
	mv	a0, s1
	jalr	ra, t0
	li	a1, -1

redblacktree_insert_or_free_ret:
	
	mv	a0, s2

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 64
	ret
	.size	redblacktree_insert_or_free, .-redblacktree_insert_or_free

	
	# a0: tree
	# a1: value
	.globl	redblacktree_insert
	.type	redblacktree_insert, @function
redblacktree_insert:
	addi	sp, sp, -80
	sd	ra,  0(sp)		
	sd	s0,  8(sp)		# T
	sd	s1, 16(sp)		# z.value
	sd	s2, 24(sp)		# x
	sd	s3, 32(sp)		# x
	sd	s4, 40(sp)		# T.nil
	sd	s5, 48(sp)		# y
	sd	s6, 56(sp)		# node pointer
	sd	s7, 64(sp)		# pointer to compare function

	mv	s0, a0
	mv	s1, a1

	ld	s7, TREE_COMPARE(s0)

	ld	s3, TREE_ROOT(s0)	# x = t.root
	ld	s4, TREE_NIL(s0)	# load t.nil
	mv	s5, s4			# y = t.nil

si_while_loop:
	beq	s3, s4, si_while_loop_end
	mv	s5, s3			# y = x
	mv	a0, s1
	ld	a1, NODE_VALUE(s3)	# x.value
	jalr	ra, s7
	bltz	a0, move_left
	bgtz	a0, move_right
	li	a0, -1			# value already present
	ld	s6, NODE_VALUE(s3)
	j	insert_end
move_left:
	ld	s3, NODE_LEFT(s3)
	j	si_while_loop
move_right:
	ld	s3, NODE_RIGHT(s3)
	j	si_while_loop
si_while_loop_end:
	la	a0, NODE_SIZE
	ld	t0, TREE_ALLOC(s0)
	jalr	ra, t0
	mv	s6, a0
	sd	s4, NODE_LEFT(a0)	# z.left = T.nil
	sd	s4, NODE_RIGHT(a0)	# z.right = T.nil
	sd	s5, NODE_P(a0)	# z.p = y
	li	t0, RED
	sb	t0, NODE_COLOR(a0)	# z.color = RED
	sd	s1, NODE_VALUE(a0)

	bne	s5, s4, tree_not_empty	# y != T.nil
	sd	a0, TREE_ROOT(s0)
	j	insert_end_succ
tree_not_empty:
	mv	a0, s1
	ld	a1, NODE_VALUE(s5)	# y.value
	jalr	ra, s7
	
	bgtz	a0, store_right	# z.value > y.value
	sd	s6, NODE_LEFT(s5)
	j       insert_end_succ
store_right:
	sd	s6, NODE_RIGHT(s5)
	j       insert_end_succ

insert_end_succ:	
	mv	a1, s6
	mv	a0, s0
	call	insert_fixup 
	li	s6, 0

insert_end:	
	mv	a0, s6
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	addi	sp, sp, 80
	ret
	.size	redblacktree_insert, .-redblacktree_insert



	# a0: tree
	.globl	redblacktree_pop_leftmost
	.type	redblacktree_pop_leftmost, @function
redblacktree_pop_leftmost:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	la	s4, tree_leftmost
	ld	a1, TREE_ROOT(a0)
	ld	a2, TREE_NIL(a0)
	mv	s0, a0

	bne	a1, a2, rbtpopleft_cont
	li	a0, -1
	j	rbtpopleft_end

rbtpopleft_cont:
	
	jalr	ra, s4
	ld	s4, NODE_VALUE(a0)
	mv	s5, a0

	mv	a0, s0
	mv	a1, s5
	call	delete

	mv	a0, s5
	ld	t0, TREE_FREE(s0)
	jalr	ra, t0

	mv	a0, s4

rbtpopleft_end:

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 64
	ret
	.size	redblacktree_pop_leftmost, .-redblacktree_pop_leftmost

	
	# a0: node value (ignored)
	# a1: ptr to counter
	.type 	count_nodes, @function
count_nodes:
	ld	t0, (a1)
	addi	t0, t0, 1
	sd	t0, (a1)
	ret
	.size	count_nodes, .-count_nodes


	# a0: tree
	.globl	redblacktree_count_nodes
	.type redblacktree_count_nodes, @function
redblacktree_count_nodes:
	addi	sp, sp, -16
	sd	x0,  0(sp)
	sd	ra,  8(sp)

	la	a1, count_nodes
	mv	a2, sp
	call	redblacktree_inorder

	ld	a0,  0(sp)
	ld	ra,  8(sp)
	addi	sp, sp, 16
	ret
	.size	redblacktree_count_nodes, .-redblacktree_count_nodes



	# a0: tree
	# a1: function pointer
	# a2: user pointer
	.globl	redblacktree_inorder
	.type redblacktree_inorder, @function
redblacktree_inorder:
	addi	sp, sp, -16
	sd	ra,  0(sp)

	mv	a3, a2
	mv	a2, a1
	ld	a1, TREE_NIL(a0)
	ld	a0, TREE_ROOT(a0)
	call	inorder

	ld	ra,  0(sp)
	addi	sp, sp, 16
	ret
	.size	redblacktree_inorder, .-redblacktree_inorder


	# a0: root
	# a1: nil
	# a2: function pointer
	.type	inorder, @function
inorder:
	beq	a0, a1, inorder_end

	addi	sp, sp, -48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	
	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	ld	a0, NODE_LEFT(s0)
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	inorder

	ld	a0, NODE_VALUE(s0)
	mv	a1, s3
	jalr	ra, s2
	
	ld	a0, NODE_RIGHT(s0)
	mv	a1, s1
	mv	a2, s2
	call	inorder


	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 48
inorder_end:
	ret
	.size	inorder, .-inorder



	# a0: T
	# a1: z
delete:
	addi	sp, sp, -64
	sd	s0,   0(sp)		# y
	sd	s1,   8(sp)		# y-original-color
	sd	s2,  16(sp)		# x
	sd	s10, 24(sp)		# T
	sd	s11, 32(sp)		# z
	sd	ra,  40(sp)
	
	mv	s10, a0
	mv	s11, a1
	mv	s0, s11			# y = z
	lb	s1, NODE_COLOR(s0)	# y-original-color = y.color
	ld	t0, NODE_LEFT(s11)	# z.left
	ld	t1, TREE_NIL(s10)	# T.nil
	bne	t0, t1, del_elif	# z.left != T.nil?
	ld	s2, NODE_RIGHT(s11)	# x = z.right
	mv	a0, s10			# T
	mv	a1, s11			# z
	ld	a2, NODE_RIGHT(s11)	# z.right
	call	transplant
	j	del_endif
del_elif:
	ld	t0, NODE_RIGHT(s11)	# z.right
	ld	t1, TREE_NIL(s10)	# T.nil
	bne	t0, t1, del_else	# z.right != T.nil?
	ld	s2, NODE_LEFT(s11)	# x = z.left
	mv	a0, s10			# T
	mv	a1, s11			# z
	mv	a2, s2			# z.left
	call	transplant
	j	del_endif
del_else:
	mv	a0, s10			# T
	ld	a1, NODE_RIGHT(s11)	# z.right
	call	tree_leftmost
	mv	s0, a0			# y = tree_leftmost(T, z.right);
	lb	s1, NODE_COLOR(s0)	# y-original-color = y.color
	ld	s2, NODE_RIGHT(s0)	# x = y.right
	ld	t0, NODE_RIGHT(s11)	# z.right
	beq	s0, t0, del_else2	# y == z.right?
	mv	a0, s10			# T
	mv	a1, s0			# y
	mv	a2, s2			# y.right
	call	transplant
	ld	t0, NODE_RIGHT(s11)	# z.right
	sd	t0, NODE_RIGHT(s0)	# y.right = z.right
	ld	t0, NODE_RIGHT(s0)	# y.right
	sd	s0, NODE_P(t0)		# y.right.p = y
	j	del_endif2
del_else2:
	sd	s0, NODE_P(s2)		# x.p = y
del_endif2:
	mv	a0, s10			# T
	mv	a1, s11			# z
	mv	a2, s0			# y
	call	transplant
	ld	t0, NODE_LEFT(s11)	# z.left
	sd	t0, NODE_LEFT(s0)	# y.left = z.left
	ld	t0, NODE_LEFT(s0)	# y.left
	#ld	t1, NODE_P(t0)		# y.left.p
	#sd	s0, NODE_P(t1)		# y.left.p = y
	sd	s0, NODE_P(t0)		# y.left.p = y
	lb	t0, NODE_COLOR(s11)	# z.color
	sb	t0, NODE_COLOR(s0)	# y.color = z.color
del_endif:
	li	t0, BLACK
	bne	t0, s1, del_end
	mv	a0, s10			# T
	mv	a1, s2			# x
	call	rb_delete_fixup
del_end:
	ld	s0,   0(sp)
	ld	s1,   8(sp)
	ld	s2,  16(sp)
	ld	s10, 24(sp)
	ld	s11, 32(sp)
	ld	ra,  40(sp)
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


	



	# a0: T
	# a1: u
	# a2: v
transplant:
	ld	t0, NODE_P(a1)	# u.p
	ld	t1, TREE_NIL(a0)	# T.nil
	bne	t0, t1, tp_elif		# u.p != T.nil?
	sd	a2, TREE_ROOT(a0)	# T.root = v
	j	tp_end
tp_elif:
	ld	t1, NODE_LEFT(t0)	# u.p.left
	bne	a1, t1, tp_else		# u != u.p.left?
	sd	a2, NODE_LEFT(t0)	# u.p.left = v
	j	tp_end
tp_else:
	sd	a2, NODE_RIGHT(t0)	# u.p.right = v
tp_end:
	sd	t0, NODE_P(a2)	# v.p = u.p
	ret





	# a0: T
	# a1: x
rb_delete_fixup:
	addi	sp, sp, -64
	sd	s0, 0(sp)		# T
	sd	s1, 8(sp)		# x
	sd	s2, 16(sp)		# w
	sd	s3, 24(sp)		# x.p
	sd	s4, 32(sp)		# RED
	sd	s5, 40(sp)		# BLACK
	sd	ra, 48(sp)

	li	s4, RED
	li	s5, BLACK

	mv	s0, a0
	mv	s1, a1

fixup_main_loop:
	ld	s3, NODE_P(s1)	# x.p
	ld	t0, TREE_ROOT(a0)
	beq	s1, t0, main_loop_end	# x == T.root?
	lb	t0, NODE_COLOR(s1)
	bne	t0, s5, main_loop_end	# x.color != BLACK?
big_if:
	ld	t0, NODE_LEFT(s3)	# x.p.left
	bne	s1, t0, big_if_else	# x != x.p.left
big_if_then:
	ld	s2, NODE_RIGHT(s3)	# w = x.p.right
	lb	t0, NODE_COLOR(s2)	# x.p.right.color
if_case1:
	bne	t0, s4, endif_case1	# w.color != RED
then_case1:
	sb	s5, NODE_COLOR(s2)	# w.color == BLACK
	sb	s4, NODE_COLOR(s3)	# x.p.color == RED
	mv	a0, s0			# T
	mv	a1, s3			# x.p
	call	left_rotate
	ld	s2, NODE_RIGHT(s3)	# w = x.p.right
endif_case1:
	ld	t0, NODE_LEFT(s2)	# w.left
	lb	t1, NODE_COLOR(t0)	# w.left.color
	bne	t1, s5, else_case2	# w.left.color != BLACK
	ld	t0, NODE_RIGHT(s2)	# w.right
	lb	t1, NODE_COLOR(t0)	# w.right.color
	bne	t1, s5, else_case2	# w.right.color != BLACK
then_case2:
	sb	s4, NODE_COLOR(s2)	# w.color = RED
	mv	s1, s3			# x = x.p
	#j	else_case2
	j	big_if_endif
else_case2:
	nop
if_case3:
	ld	t0, NODE_RIGHT(s2)	# w.right
	lb	t1, NODE_COLOR(t0)	# w.right.color
	bne	t1, s5, endif_case3	# w.right.color != BLACK
then_case3:
	ld 	t0, NODE_LEFT(s2)	# w.left
	sb	s5, NODE_COLOR(t0)	# w.left.color = BLACK
	sb	s4, NODE_COLOR(s2)	# w.color = RED
	mv	a0, s0			# T
	mv	a1, s2			# w
	call	right_rotate
	ld	t0, NODE_P(s1)		# x.p
	ld	s2, NODE_RIGHT(t0)	# w = x.p.right
endif_case3:
	lb	t0, NODE_COLOR(s3)	# x.p.color
	sb	t0, NODE_COLOR(s2)	# w.color = x.p.color
	sb	s5, NODE_COLOR(s3)	# x.p.color = BLACK
	ld	t0, NODE_RIGHT(s2)	# w.right
	sb	s5, NODE_COLOR(t0)	# w.right.color = BLACK
	mv	a0, s0			# T
	mv	a1, s3			# x.p
	call	left_rotate
	ld	s1, TREE_ROOT(s0)	# x = T.root
	j	big_if_endif
big_if_else:
	ld	s2, NODE_LEFT(s3)	# w = x.p.left
	lb	t0, NODE_COLOR(s2)
if_case1_bis:
	bne	t0, s4, endif_case1_bis	# w.color != RED
then_case1_bis:
	sb	s5, NODE_COLOR(s2)	# w.color == BLACK
	sb	s4, NODE_COLOR(s3)	# x.p.color == RED
	mv	a0, s0
	mv	a1, s3
	#call	left_rotate
	call	right_rotate
	ld	s2, NODE_LEFT(s3)	# w = x.p.left
endif_case1_bis:
	ld	t0, NODE_RIGHT(s2)	# w.right
	lb	t1, NODE_COLOR(t0)	# w.right.color
	bne	t1, s5, else_case2_bis	# w.right.color != BLACK
	ld	t0, NODE_LEFT(s2)	# w.left
	lb	t1, NODE_COLOR(t0)	# w.left.color
	bne	t1, s5, else_case2_bis	# w.left.color != BLACK
then_case2_bis:
	sb	s4, NODE_COLOR(s2)	# w.color = RED
	mv	s1, s3			# x = x.p
	#j	else_case2_bis
	j	big_if_endif
else_case2_bis:
	nop
if_case3_bis:
	ld	t0, NODE_LEFT(s2)	# w.left
	lb	t1, NODE_COLOR(t0)	# w.left.color
	bne	t1, s5, endif_case3_bis	# w.left.color != BLACK
then_case3_bis:
	ld 	t0, NODE_RIGHT(s2)	# w.right
	sb	s5, NODE_COLOR(t0)	# w.right.color = BLACK
	sb	s4, NODE_COLOR(s2)	# w.color = RED
	mv	a0, s0
	mv	a1, s2
	#call	right_rotate
	call	left_rotate
	ld	t0, NODE_P(s1)	# x.p
	ld	s2, NODE_LEFT(t0)	# w = x.p.left
endif_case3_bis:
	lb	t0, NODE_COLOR(s3)	# x.p.color
	sb	t0, NODE_COLOR(s2)	# w.color = x.p.color
	sb	s5, NODE_COLOR(s3)	# x.p.color = BLACK
	ld	t0, NODE_LEFT(s2)	# w.left
	sb	s5, NODE_COLOR(t0)	# w.left.color = BLACK
	mv	a0, s0
	mv	a1, s3
	#call	left_rotate
	call	right_rotate
	ld	s1, TREE_ROOT(s0)	# x = T.root
	j	big_if_endif
big_if_endif:
	nop
main_loop_end:
	sb	s5, NODE_COLOR(s1)	# x.color = BLACK
	
	ld	s0, 0(sp)		# T
	ld	s1, 8(sp)		# x
	ld	s2, 16(sp)		# w
	ld	s3, 24(sp)		# x.p
	ld	s4, 32(sp)		# RED
	ld	s5, 40(sp)		# BLACK
	ld	ra, 48(sp)
	addi	sp, sp, 64

	ret


	.globl redblacktree_peek_leftmost
redblacktree_peek_leftmost:
	addi	sp, sp, -64
	sd	ra,  0(sp)

	ld	t0, TREE_ROOT(a0)
	ld	t1, TREE_NIL(a0)

	bne	t0, t1, redblacktree_peek_leftmost_cont

	li	a0, -1
	j	redblacktree_peek_leftmost_ret

redblacktree_peek_leftmost_cont:
	mv	a1, t0
	call	tree_leftmost
	ld	a0, NODE_VALUE(a0)

redblacktree_peek_leftmost_ret:
	ld	ra,  0(sp)
	addi	sp, sp, 64
	ret
	.size	redblacktree_peek_leftmost, .-redblacktree_peek_leftmost
	


	# a0: T
	# a1: x
tree_leftmost:
	ld	t0, TREE_NIL(a0)	# NIL
tree_leftmost_loop:
	ld	t1, NODE_LEFT(a1)
	beq	t0, t1, tree_leftmost_end
	mv	a1, t1
	j	tree_leftmost_loop
tree_leftmost_end:
	mv	a0, a1
	ret
	


	# a0: T
	# a1: x
tree_maximum:
	ld	t0, TREE_NIL(a0)	# NIL
tree_maximum_loop:
	ld	t1, NODE_RIGHT(a1)
	beq	t0, t1, tree_maximum_end
	mv	a1, t1
	j	tree_maximum_loop
tree_maximum_end:
	mv	a0, a1
	ret
	

