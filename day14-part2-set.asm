	.global	set_new
	.global set_insert

	.set	RED, 		 0
	.set	BLACK,		 1

	.set	TREE_SIZE,	16
	.set	TREE_ROOT,	 0
	.set	TREE_NIL,	 8

	.set	NODE_SIZE,	45
	.set	NODE_LEFT,	 0
	.set	NODE_RIGHT,	 8
	.set	NODE_P,		16
	.set	NODE_COLOR,	24
	.set	NODE_HASH,	25
	.set	NODE_CYCLE,	33

	.section .text

set_new:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	li	a0, NODE_SIZE
	call	malloc
	mv	s0, a0			# nil
	li	a0, TREE_SIZE
	call	malloc

	# tree.root and tree.nil initialized nith nil
	sd	s0, TREE_ROOT(a0)
	sd	s0, TREE_NIL(a0)

	# t.nil.color = BLACK
	li	t1, BLACK
	sb	t1, NODE_COLOR(s0)

	ld	ra, 0(sp)
	ld	s0, 8(sp)
	addi	sp, sp, 16

	ret
		

	# a0: tree
	# a1: string ptr
	# a2: cycle
set_insert:
	addi	sp, sp, -80
	sd	ra,  0(sp)		
	sd	s0,  8(sp)		# T
	sd	s2, 24(sp)		# x
	sd	s3, 32(sp)		# x
	sd	s4, 40(sp)		# T.nil
	sd	s5, 48(sp)		# y
	sd	s6, 56(sp)
	sd	s8, 72(sp)

	mv	s0, a0
	mv	s8, a2

	li	s6, 5381
	li	t1, 33
loop_djb2:
	lb	t0, 0(a1)
	beqz	t0, loop_djb2_end
	mul	s6, s6, t1
	add	s6, s6, t0
	addi	a1, a1, 1
	j	loop_djb2
loop_djb2_end:
	

	ld	s3, TREE_ROOT(s0)	# x = t.root
	ld	s4, TREE_NIL(s0)	# load t.nil
	mv	s5, s4			# y = t.nil

si_while_loop:
	beq	s3, s4, si_while_loop_end
	mv	s5, s3			# y = x
	ld	t0, NODE_HASH(s3)	# x.value
	blt	s6, t0, move_left
	bgt	s6, t0, move_right
	lw	a0, NODE_CYCLE(s3)	# value already present, return cycle number
	j	insert_end
move_left:
	ld	s3, NODE_LEFT(s3)
	j	si_while_loop
move_right:
	ld	s3, NODE_RIGHT(s3)
	j	si_while_loop
si_while_loop_end:
	li	a0, NODE_SIZE
	call	malloc
	sd	s4, NODE_LEFT(a0)	# z.left = T.nil
	sd	s4, NODE_RIGHT(a0)	# z.right = T.nil
	sd	s5, NODE_P(a0)	# z.p = y
	li	t0, RED
	sb	t0, NODE_COLOR(a0)	# z.color = RED
	sd	s6, NODE_HASH(a0)
	sw	s8, NODE_CYCLE(a0)

	bne	s5, s4, tree_not_empty	# y != T.nil
	sd	a0, TREE_ROOT(s0)
	j	insert_end_succ
tree_not_empty:
	ld	t0, NODE_HASH(s5)	# y.value
	bgt	s6, t0, store_right	# z.value > y.value
	sd	a0, NODE_LEFT(s5)
	j       insert_end_succ
store_right:
	sd	a0, NODE_RIGHT(s5)
	j       insert_end_succ

insert_end_succ:	
	mv	a1, a0
	mv	a0, s0
	call	insert_fixup 
	li	a0, -1

insert_end:	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s8, 72(sp)
	addi	sp, sp, 80
	ret

