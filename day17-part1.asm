	.include "constants.inc"
	.include "macros.inc"

	.set	MAP_WIDTH, 0
	.set	MAP_HEIGHT, 2
	.set	MAP_CELL_SIZE, 5

	.set	NORTH, 0
	.set	EAST, 1
	.set	SOUTH, 2
	.set	WEST, 3

	.set	VALUE_SIZE, 	16
	.set    VALUE_LOSS,	0      # 4 bytes
	.set    VALUE_X, 	4      # 2 bytes
	.set    VALUE_Y, 	6      # 2 bytes
	.set    VALUE_DIR, 	8      # 1 byte
	.set    VALUE_STEPS, 	9      # 1 byte

	
	.bss
	.balign	8
	.type	map, @object
	.set	MAP_SIZE, 128*1024
	.size	map, MAP_SIZE
map: 	.zero	MAP_SIZE
	.type	pool, @object
	.set	CHUNKS_CNT, 8*1024
	.set	CHUNKS_SIZE, 40
	.set	POOL_SIZE, 8 + (CHUNKS_CNT * CHUNKS_SIZE)
	.size	pool, POOL_SIZE
pool:	.zero	POOL_SIZE


	.section .rodata
input:	.incbin	"inputs/day17"
	.byte	 0
moves:	.byte  	 0, -1			# north
	.byte  	 1,  0			# east
	.byte  	 0,  1			# south
	.byte 	-1,  0			# west
turns:	.byte EAST,  WEST
	.byte NORTH, SOUTH
	.byte EAST,  WEST
	.byte NORTH, SOUTH


	.text

	.global	_start
_start:
	la	a0, pool
	li	a1, CHUNKS_CNT
	li	a2, CHUNKS_SIZE
	call	pool_init

	la	a0, compar
	la	a1, node_alloc
	la	a2, node_free
	call	redblacktree_init
	mv	s4, a0

	la	s0, map
	la	s1, input

	# measure map
	mv	a0, s1
	call	line_length
	sh	a0,  MAP_WIDTH(s0)
	mv	s10, a0
	dec	s10
	clr	t0
loop_count_lines:
	lb	t1, (s1)
	beqz	t1, loop_count_lines_end
	inc	t0
	add	s1, s1, a0
	j	loop_count_lines
loop_count_lines_end:
	dec	t0
	sh	t0, MAP_HEIGHT(s0)
	mv	s11, a0
	dec	s11


	# copy input to map
	la 	t0, input
	la	t1, map
	addi	t1, t1, 4			# skip width/height
	li	t3, ASCII_LF
loop_copy:
	lb	t2, (t0)
	beqz	t2, loop_copy_end
	beq	t2, t3, skip_write
	addi	t2, t2, -ASCII_ZERO
	sb	t2, 0(t1)
	addi	t1, t1, MAP_CELL_SIZE
skip_write:	
	addi	t0, t0, 1
	j	loop_copy
loop_copy_end:


	# initialize the queue

	li	a0, 0
	li	a1, 1
	call	get_addr
	mv	t1, a0
	inc	t1	
	li	a3, SOUTH
	add	t1, t1, a3
	li	t0, 2				# 1 << 1 step
	sb	t0, (t1)
	lb	a0, (a0)
	li	a1, 0
	li	a2, 1
	li	a4, 1
	mv	a5, s4
	call	enqueue

	li	a0, 1
	li	a1, 0
	call	get_addr
	mv	t1, a0
	inc	t1	
	li	a3, EAST
	add	t1, t1, a3
	li	t0, 2				# 1 << 1 step
	sb	t0, (t1)
	lb	a0, (a0)
	li	a1, 1
	li	a2, 0
	li	a4, 1
	mv	a5, s4
	call	enqueue


main_loop:
	mv	a0, s4
	call	dequeue

	# check if end reached
	bne	a1, s10, main_loop_next
	bne	a2, s11, main_loop_next

	call	print_int
	j	exit

main_loop_next:
	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3

	# only move forward if less than three
	# steps moved in the same directrion
	li	t0, 3
	beq	a4, t0, skip_forward
	inc	a4
	mv	a5, s4
	call	add_to_queue
skip_forward:

	# get possible turns for the current direction
	slli	s3, s3, 1
	la	t0, turns
	add	s9, t0, s3

	# add turns to the queue
	.rept 2
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	lb	a3, (s9)
	li	a4, 1
	mv	a5, s4
	call	add_to_queue
	inc	s9
	.endr

	j	main_loop



	# a0: loss
	# a1: x
	# a2: y
	# a3: direction
	# a4: steps
	# a5: queue
add_to_queue:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3
	mv	s4, a4
	mv	s5, a5

	# load movement values
	slli	t3, s3, 1	
	la	t0, moves
	add	t0, t0, t3
	lb	t1, 0(t0)
	lb	t2, 1(t0)

	# compute new coordinates
	add	s1, s1, t1
	add	s2, s2, t2

	mv	a0, s1
	mv	a1, s2
	call	get_addr
	beqz	a0, atq_end		# new coordinates out of bounds

	lb	t0, 0(a0)
	add	s0, s0, t0		# new loss

	# check if visited for direction and number of steps
	inc	a0			# skip loss value of the square
	add	a0, a0, s3		# add direction
	li	t0, 1
	sll	t0, t0, s4		# steps bit mask
	lb	t1, (a0)		# load direction byte
	and	t2, t1, t0		# check if steps bit is on
	bnez	t2, atq_end		# skip enqueue if bit on

	# mark as visited for direction and number of steps
	or	t2, t1, t0		# add steps bit to direction byte
	sb	t2, (a0)		# store back modified direction byte

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	mv	a5, s5
	call	enqueue

atq_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 64
	ret



dequeue:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	call	redblacktree_pop_min

	lw	s0, VALUE_LOSS(a0)
	lh	s1, VALUE_X(a0)
	lh	s2, VALUE_Y(a0)
	lb	s3, VALUE_DIR(a0)
	lb	s4, VALUE_STEPS(a0)

	mv	a1, a0
	la	a0, pool
	call	chunk_free

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	addi	sp, sp, 64

	ret



	# a0: loss
	# a1: x
	# a2: y
	# a3: direction
	# a4: steps
	# a5: queue
enqueue:
	addi    sp, sp, -64
	sd      s0,  0(sp)
	sd      s1,  8(sp)
	sd      s2, 16(sp)
	sd      s3, 24(sp)
	sd      s4, 32(sp)
	sd      s5, 40(sp)
	sd      ra, 48(sp)
	
	mv	s0, a0
	mv      s1, a1
	mv      s2, a2
	mv      s3, a3
	mv      s4, a4
	mv      s5, a5
	
	call	node_alloc
	sw      s0, VALUE_LOSS(a0)
	sh      s1, VALUE_X(a0)
	sh      s2, VALUE_Y(a0)
	sb      s3, VALUE_DIR(a0)
	sb      s4, VALUE_STEPS(a0)
	
	mv	a1, a0
	mv	a0, s5
	call	redblacktree_insert
	
	ld      s0,  0(sp)
	ld      s1,  8(sp)
	ld      s2, 16(sp)
	ld      s3, 24(sp)
	ld      s4, 32(sp)
	ld      s5, 40(sp)
	ld      ra, 48(sp)
	addi    sp, sp, 64
	ret



	# a0: column (x)
	# a1: row (y)
get_addr:
	bltz	a0, get_addr_oob
	bltz	a1, get_addr_oob
	la	t0, map
	lh	t1, MAP_HEIGHT(t0)
	bge	a1, t1, get_addr_oob
	lh	t1, MAP_WIDTH(t0)
	bge	a0, t1, get_addr_oob
	mul	a1, a1, t1
	add	a1, a1, a0
	li	t2, MAP_CELL_SIZE
	mul	a1, a1, t2
	addi	t0, t0, 4	# skip width / height
	add	a0, t0, a1
	ret
get_addr_oob:
	clr	a0
	ret

node_alloc:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	la	a0, pool
	call	chunk_alloc
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

node_free:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	mv	a1, a0
	la	a0, pool
	call	chunk_free
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

compar:
	lw	t0, VALUE_LOSS(a0)
	lw	t1, VALUE_LOSS(a1)
	sub	t2, t0, t1
	bnez	t2, compar_noteq
	li	t2, -1
compar_noteq:
	mv	a0, t2
	ret

