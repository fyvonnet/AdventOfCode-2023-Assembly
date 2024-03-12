	.global	queue_init
	.global	queue_push
	.global	queue_pop
	.global	queue_empty

	.section .text

queue_init:
	addi	t0, a0, 24
	sd	t0,  0(a0)	# base
	sw	a1,  8(a0)	# elements count
	sw	a2, 12(a0)	# element size
	sw	x0, 16(a0)	# head
	sw	x0, 20(a0)	# tail
	ret

queue_push:
	addi	t6, a0, 20
	j	queue_common

queue_pop:
	addi	t6, a0, 16
	#j	queue_common

queue_common:
	ld	t0,  0(a0)	# base
	lw	t1,  8(a0)	# elements count
	lw	t2, 12(a0)	# elements size
	lw	t3,   (t6)	# head/tail index
	mul	t4, t3, t2	# offset
	add	t4, t4, t0	# tail address
	addi	t3, t3, 1
	rem	t3, t3, t1
	sw	t3,   (t6)
	mv	a0, t4
	ret

queue_empty:
	lw	t0, 16(a0)
	lw	t1, 20(a0)
	li	a0, 0
	bne	t0, t1, not_empty
	li	a0, 1
not_empty:
	ret

