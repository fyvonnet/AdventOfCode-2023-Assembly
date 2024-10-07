	.include "constants.inc"
	.include "macros.inc"


	.section .rodata

filename:
	.string	"inputs/day21"

	.balign	4
moves_x:
	.word	0, 1, 0, -1
moves_y:
	.word	-1, 0, 1, 0


	.section .bss
	.balign 8

	.set    QUEUE_ELEMCNT, 300
	.set    QUEUE_ELEMSZ, 12
	.set    QUEUE_SIZE, 40 + (QUEUE_ELEMCNT * QUEUE_ELEMSZ)
	.type   queue, @object
	.size   queue, QUEUE_SIZE
queue:  .space  QUEUE_SIZE



	.section .text
	.balign 8

	.globl _start
	.type	_start, @function
_start:
	la      a0, queue
	li      a1, QUEUE_ELEMCNT
	li      a2, QUEUE_ELEMSZ
	call    queue_init

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, s10, a1

	# align stack pointer
	sub	sp, sp, a1
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0
	mv	s0, sp

	mv	a0, s10
	call	line_length
	mv	s1, a0

	mv	t0, s0
	mv	t1, s10
	li	t2, 1
	li	t3, '#'
	li	t4, 'S'
	li	t5, '\n'
	li	t6, '.'
	clr	a0				# X coordinate
	clr	a1				# Y coordinate
loop_parse_input:
	bge	t1, s11, loop_parse_input_end
	lb	a2, (t1)
	beq	a2, t3, input_rock
	beq	a2, t4, input_start
	beq	a2, t5, input_nl
	beq	a2, t6, input_plot

	# should not reach here
	li	a0, 1
	li	a7, SYS_EXIT
	ecall
	
input_start:
	mv	s2, a0
	mv	s3, a1
	li	a3, 2
	sb	a3, (t0)
	j	loop_parse_input_next
	
input_rock:
	sb	t2, (t0)
	j	loop_parse_input_next
input_nl:
	clr	a0
	inc	a1
	inc	t1
	j	loop_parse_input
input_plot:
	sb	zero, (t0)
	j	loop_parse_input_next
loop_parse_input_next:
	inc	a0
	inc	t0
	inc	t1
	j	loop_parse_input
loop_parse_input_end:


	vsetivli zero, 4, e32

	# initialize vectors with relative adjacent coordinates
	la	t0, moves_x
	vle32.v	v0, (t0)
	la	t1, moves_y
	vle32.v	v1, (t1)

	# allocate stack space for adjacent coordinates
	addi	sp, sp, -32
	mv	s4, sp


	# solution to part 1 is the count of squares reachable in an even number of steps [0, 64]

	# initialize queue with starting coordinates and steps countdown
	la	a0, queue
	call	queue_push
	sw	s2, 0(a0)
	sw	s3, 4(a0)
	li	t0, 64
	sw	t0, 8(a0)

	# set start case as occupied
	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s1
	call	get_addr
	li	t0, 1
	lb	t0, (a0)

	clr	s8			# squares count
loop:
	la	a0, queue
	call	queue_pop
	lw	s2, 0(a0)
	lw	s3, 4(a0)
	lw	s7, 8(a0)

	bltz	s7, loop_end

	li	t0, 2
	rem	t0, s7, t0
	bnez	t0, skip_count		# skip count if odd step number
	inc	s8
skip_count:

	dec	s7			# decrements steps countdown

	# compute ajacent coordinates
	vadd.vx	v2, v0, s2
	vadd.vx	v3, v1, s3
	addi	t0, s4, 16
	vse32.v	v2, (s4)
	vse32.v	v3, (t0)

	li	s5, 4			# adjacent squares countdown
	mv	s6, s4			# adjacent coordinates pointer
loop_adjacents:
	lw	s2,  0(s6)		# load adjacent X coordinate
	lw	s3, 16(s6)		# load adjacent Y coordinate

	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s1
	call	get_addr

	lb	t0, (a0)		# check square occupancy
	bnez	t0, skip_adjacent	# skip if occupied
	li	t1, 1			# set map square as occuied
	sb	t1, (a0)
	la	a0, queue
	call	queue_push
	sw	s2, 0(a0)
	sw	s3, 4(a0)
	sw	s7, 8(a0)
skip_adjacent:
	dec	s5			# decrement countdown
	addi	s6, s6, 4		# move pointer to next coordinate
	bnez	s5, loop_adjacents

	j	loop
loop_end:

	mv	a0, s8
	call	print_int

	li	a0, EXIT_SUCCESS
	li	a7, SYS_EXIT
	ecall
	.size	_start, .-_start


	# a0: map
	# a1: x coord
	# a2: y coord
	# a3: row length
	.type	get_addr, @function
get_addr:
	mul     a2, a2, a3
	add     a2, a2, a1
	add     a0, a0, a2
	ret
	.size	get_addr, .-get_addr

