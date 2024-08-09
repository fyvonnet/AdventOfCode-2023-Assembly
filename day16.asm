	.include "macros.inc"
	.include "constants.inc"

	.set	EAST, 0
	.set	SOUTH, 1
	.set	WEST, 2
	.set	NORTH, 3

	.bss
	.balign	8
	.type	queue, @object
	.set	ELEM_SZ, 8
	.set	ELEM_NB, 100
	.set	QUEUE_SIZE, 16 + (ELEM_SZ * ELEM_NB)
queue:	.zero	QUEUE_SIZE
	.size	queue, QUEUE_SIZE


	.text


	.globl	_start
_start:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	mv	s2, a1

	# allocate stack space for map
	sub	sp, sp, a1
	mv	s0, sp

	# align stack
	li	t0, 16
	remu	t1, sp, t0
	sub	sp, sp, t1

	mv	a0, s10
	call	line_length
	mv	s1, a0				# columns count

	addi	t0, s1, 1			# add LFs from input
	div	s2, s2, t0			# rows count

	# parse input
	mv	t0, s0
	li	t5, ASCII_LF
	la	t6, signs
loop_load:
	lb	t1, 0(s10)
	beq	t1, t5, skip_sign
	mv	t4, t6
loop_search_sign:
	lb	t3, 0(t4)
	beq	t1, t3, loop_search_sign_end
	inc	t4
	j	loop_search_sign
loop_search_sign_end:
	sub	t4, t4, t6
	sb	t4, 0(t0)
	inc	t0
skip_sign:
	inc	s10
	blt	s10, s11, loop_load

	li	t1, -1
	sb	t1, 0(t0)			# terminator
	

        ######     #    ######  #######      #
        #     #   # #   #     #    #        ##
        #     #  #   #  #     #    #       # #
        ######  #     # ######     #         #
        #       ####### #   #      #         #
        #       #     # #    #     #         #
        #       #     # #     #    #       #####

	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	li	a3, 0
	li	a4, 0
	li	a5, EAST
	call	count_energized
	mv	s11, a0
	call	print_int


        ######     #    ######  #######     #####
        #     #   # #   #     #    #       #     #
        #     #  #   #  #     #    #             #
        ######  #     # ######     #        #####
        #       ####### #   #      #       #
        #       #     # #    #     #       #
        #       #     # #     #    #       #######


	li	s3, 0
	li	s4, 1
loop_left_side:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	li	a5, EAST
	call	count_energized
	ble	a0, s11, no_new_max_left
	mv	s11, a0
no_new_max_left:
	inc	s4
	bne	s4, s2, loop_left_side

	li	s3, 0
	addi	s4, s2, -1
loop_bottom_side:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	li	a5, NORTH
	call	count_energized
	ble	a0, s11, no_new_max_bottom
	mv	s11, a0
no_new_max_bottom:
	inc	s3
	bne	s3, s1, loop_bottom_side

	addi	s3, s1, -1
	li	s4, 0
loop_right_side:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	li	a5, WEST
	call	count_energized
	ble	a0, s11, no_new_max_right
	mv	s11, a0
no_new_max_right:
	inc	s4
	bne	s4, s2, loop_right_side

	li	s3, 0
	li	s4, 0
loop_top_side:
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	li	a5, SOUTH
	call	count_energized
	ble	a0, s11, no_new_max_top
	mv	s11, a0
no_new_max_top:
	inc	s3
	bne	s3, s1, loop_top_side

	mv	a0, s11
	call	print_int


        ####### #     # ######
        #       ##    # #     #
        #       # #   # #     #
        #####   #  #  # #     #
        #       #   # # #     #
        #       #    ## #     #
        ####### #     # ######

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall
	
	# a0: map
	# a1: columns count
	# a2: rows count
	# a3: X start
	# a4: Y start
	# a5: dir start
count_energized:
	addi	sp, sp, -80
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s7, a2
	mv	s4, a3
	mv	s5, a4
	mv	s6, a5

	# initialize queue
	la	a0, queue
	li	a1, ELEM_NB
	li	a2, ELEM_SZ
	call	queue_init

	la	a0, queue
	call	queue_push
	sh	s4, 0(a0)
	sh	s5, 2(a0)
	sb	s6, 4(a0)

	# terminator
	addi	sp, sp, -16
	li	t0, -1
	sb	t0, 4(sp)

loop_beam:
	la	a0, queue
	call	queue_pop
	beqz	a0, loop_beam_end
	lh	s4, 0(a0)
	lh	s5, 2(a0)
	lb	s6, 4(a0)

	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s1
	call	get_addr

	lb	t0, 0(a0)
	andi	t2, t0, 0b111				# extract sign value

	li	t1, 0b1000
	sll	t1, t1, s6
	or	t1, t1, t0				# mark as energized
	sb	t1, 0(a0)

	slli	t0, t2, 3				# x8
	la	t1, funcs
	add	t0, t0, t1
	ld	t0, 0(t0)				# load jump address
	jr	t0
loop_beam_end:
	
	
	# count and reset
	clr	t6					# counter
loop_count:
	lb	t1, 0(s0)
	bltz	t1, loop_count_end
	andi	t0, t1, 0b1111000
	beqz	t0, not_energized
	inc	t6
	andi	t0, t1, 0b111
	sb	t0, 0(s0)
not_energized:
	inc	s0
	j	loop_count
loop_count_end:

	mv	a0, t6

	addi	sp, sp, 16
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	addi	sp, sp, 80
	ret

	# a0: map
	# a1: x coord
	# a2: y coord
	# a3: row length
get_addr:
	mul	a2, a2, a3
	add	a2, a2, a1
	add	a0, a0, a2
	ret

just_move:
	mv	t6, s6
	slli	t6, t6, 1
	la	t0, adjacents
	add	t0, t0, t6
	lb	t1, 0(t0)
	lb	t2, 1(t0)
	add	s4, s4, t1
	add	s5, s5, t2
	addi	sp, sp, -16
	sh	s4, 0(sp)
	sh	s5, 2(sp)
	sb	s6, 4(sp)
	j	enqueue

fore_mirr:
	la	t6, fore_mirr_moves
	j	mirror
	

back_mirr:
	la	t6, back_mirr_moves

mirror:
	add	t6, t6, s6
	lb	s6, 0(t6)
	j	just_move

hsplitter:
	li	t5, EAST
	li	t6, WEST
	j	splitter


vsplitter:
	li	t5, NORTH
	li	t6, SOUTH

splitter:
	beq	s6, t5, just_move
	beq	s6, t6, just_move
	mv	t0, t5
	mv	t1, t6
	.rept 2
	addi	sp, sp, -16			# allocate stack space
	sb	t0, 4(sp)			# store direction
	slli	t0, t0, 1			# compute adjacent offset
	la	t2, adjacents			# load adjacents vector pointer
	add	t0, t0, t2			# compute adjacent square pointer
	mv	t4, s4				# copy column number
	mv	t5, s5				# copy row number
	lb	t2, 0(t0)			# load column change
	add	t4, t4, t2			# apply column change
	sh	t4, 0(sp)			# store new column number in the stack
	lb	t2, 1(t0)			# load row change
	add	t5, t5, t2			# apply row change
	sh	t5, 2(sp)			# store new row number in the stack
	mv	t0, t1				# next movement
	.endr

enqueue:

	lh	s4, 0(sp)
	lh	s5, 2(sp)
	lb	s6, 4(sp)
	
	bltz	s6, loop_beam			# no more elements on the stack
	add	sp, sp, 16			# free stack space

	# check for out-of-bounds coordinates
	bltz	s4, enqueue
	bltz	s5, enqueue
	bge	s4, s1, enqueue
	bge	s5, s7, enqueue

	# check if beam already passed in the same direction
	mv	a0, s0
	mv	a1, s4
	mv	a2, s5
	mv	a3, s1
	call	get_addr
	lb	t0, 0(a0)
	li	t2, 0b1000
	sll	t2, t2, s6
	and	t2, t2, t0
	bnez	t2, enqueue

	# add new element to queue
	la	a0, queue
	call	queue_push
	sh	s4, 0(a0)
	sh	s5, 2(a0)
	sb	s6, 4(a0)
	j	enqueue



	.section .rodata

signs:
	.string	"./\\|-"

fore_mirr_moves:
	.byte	3			# east to north
	.byte	2			# south to west
	.byte	1			# west to south
	.byte	0			# north to east

back_mirr_moves:
	.byte	1			# east to south
	.byte	0			# south to east
	.byte	3			# west to north
	.byte	2			# north to west

adjacents:
	.byte	+1,  0			# east
	.byte	 0, +1			# south
	.byte	-1,  0			# west
	.byte	 0, -1			# north

funcs:
	.quad	just_move
	.quad	fore_mirr
	.quad	back_mirr
	.quad	vsplitter
	.quad	hsplitter

filename:
	.string "inputs/day16"

