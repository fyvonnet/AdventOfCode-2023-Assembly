	.include "macros.inc"

	.set	NMEMB,	 0
	.set	SIZE, 	 8
	.set	HEAD, 	16
	.set	TAIL, 	24
	.set	COUNT, 	32
	.set	HEADER_SIZE, 40



	.section .text


	.globl	queue_count
queue_count:
	ld	a0, COUNT(a0)
	ret


	# a0 : base
	# a1 : elements counts
	# a2 : elements size
	.globl	queue_init
queue_init:
	sd	a1, NMEMB(a0)	# elements count
	sd	a2, SIZE(a0)	# element size
	sd	x0, HEAD(a0)	# head
	sd	x0, TAIL(a0)	# tail
	sd	x0, COUNT(a0)
	ret

	.globl	queue_push
queue_push:
	#addi	t6, a0, 20
	ld	t1, NMEMB(a0)	# elements count
	ld	a7, COUNT(a0)
	sub	t0, t1, a7
	beqz	t0, ret_fail	# can't push if queue full
	li	t5, 1
	addi	t6, a0, TAIL
	j	queue_common


	.global	queue_pop
queue_pop:
	#addi	t6, a0, 16
	ld	a7, COUNT(a0)
	beqz	a7, ret_fail	# can't pop if queue empty
	ld	t1, NMEMB(a0)	# elements count
	li	t5, -1
	addi	t6, a0, HEAD
	#j	queue_common

queue_common:
	addi	t0, a0, HEADER_SIZE
	ld	t2, SIZE(a0)	# elements size
	ld	t3, (t6)	# head/tail index
	mul	t4, t3, t2	# offset
	add	t4, t4, t0	# tail address
	addi	t3, t3, 1
	rem	t3, t3, t1
	sd	t3, (t6)	# save new index
	ld	t0, COUNT(a0)
	add	t0, t0, t5
	sd	t0, COUNT(a0)
	mv	a0, t4
	ret


ret_fail:
	clr	a0
	ret
