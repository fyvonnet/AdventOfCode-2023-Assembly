	.include "macros.inc"
	.include "constants.inc"

	.section .text

	# a0: base address
	# a1: chunks count
	# a2: chunks size
	.global	pool_init
pool_init:
	addi	t2, a0, 8
	sd	t2,  (a0)
loop_pool_init:
	mv	t0, t2
	add	t2, t0, a2
	sd	t2, (t0)
	dec	a1
	bnez	a1, loop_pool_init
	ret

	# a0: pool address
	# a1: chunk address
	.global	chunk_free
chunk_free:
	ld	t1, (a0)
	sd	a1, (a0)
	sd	t1, (a1)
	ret

	# a0: pool address
	.global	chunk_alloc
chunk_alloc:
	ld	t0, (a0)
	ld	t1, (t0)
	sd	t1, (a0)
	mv	a0, t0
	ret
	



	# a0: base address
	# a1: size
	.global	arena_init
arena_init:
	addi	t0, a0, 16
	sd	t0, 0(a0)
	addi	t0, a1, -16
	sd	t0, 8(a0)
	ret

	# a0: arena address
	# a1: size
	.global	arena_alloc
arena_alloc:
	li	t6, 8
	rem	t5, a1, t6
	beqz	t5, arena_alloc_ok
	div	t5, a1, t6
	addi	t5, t5, 1
	mul	a1, t5, t6
arena_alloc_ok:
	ld	t1, 8(a0)
	blt	t1, a1, arena_alloc_fail
	sub	t1, t1, a1
	sd	t1, 8(a0)
	ld	t0, 0(a0)
	add	t1, t0, a1
	sd	t1, 0(a0)
	mv	a0, t0
	ret
arena_alloc_fail:
	li	a0, 0
	ret

	# a0: arena address
	# a1: pointer to memory space
	.global	arena_free
arena_free:
	ld	t0, 0(a0)
	ld	t2, 8(a0)
	sub	t1, t0, a1
	add	t1, t1, t2
	sd	a1, 0(a0)
	sd	t1, 8(a0)
	ret

