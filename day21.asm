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

	.set    QUEUE_ELEMCNT, 5000
	.set    QUEUE_ELEMSZ, 8
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

	# initialize vectors
	vsetivli zero, 4, e32
	la	t0, moves_x
	la	t1, moves_y
	vle32.v	v0, (t0)
	vle32.v	v1, (t1)

	# allocate stack space for adjacent coordinates
	addi	sp, sp, -32
	mv	s4, sp

	# initialize queue with starting coordinates
	la	a0, queue
	call	queue_push
	sw	s2, 0(a0)
	sw	s3, 4(a0)

	la	s8, 64			# turns countdown
loop_turns:
	la	a0, queue
	call	queue_count
	mv	s7, a0
loop_oneturn:
	la	a0, queue
	call	queue_pop
	lw	s2, 0(a0)
	lw	s3, 4(a0)

	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s1
	call	get_addr
	sb	zero, (a0)		# clear square

	
	# compute ajacent coordinates
	vadd.vx	v2, v0, s2
	vadd.vx	v3, v1, s3
	addi	t0, s4, 16
	vse32.v	v2, (s4)
	vse32.v	v3, (t0)

	li	s5, 4
	mv	s6, s4			# adjacent coordinates pointer
loop_adjacents:
	lw	s2,  0(s6)
	lw	s3, 16(s6)

	mv	a0, s0
	mv	a1, s2
	mv	a2, s3
	mv	a3, s1
	call	get_addr
	lb	t0, (a0)		# check square content
	bnez	t0, skip_adjacent	# rock present or square already stepped on
	li	t1, 1			# set map square so we won't step on the same square twice
	sb	t1, (a0)
	la	a0, queue
	call	queue_push
	sw	s2, 0(a0)
	sw	s3, 4(a0)
skip_adjacent:
	dec	s5
	addi	s6, s6, 4
	bnez	s5, loop_adjacents

	dec	s7
	bnez	s7, loop_oneturn

	dec	s8
	bnez	s8, loop_turns

	la	a0, queue
	call	queue_count
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

