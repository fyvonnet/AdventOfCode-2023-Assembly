	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

#	addi	sp, sp, -32
#	mv	s0, sp
#	sd	zero,  0(s0)
#	sd	zero,  8(s0)
#	sd	zero, 16(s0)
#	sd	zero, 24(s0)

	addi	sp, sp, -16
	li	t0, -1
	sd	t0,  0(sp)
	sd	t0,  8(sp)

	clr	s3				# X coordinate
	clr	s4				# Y coordinate
	clr	s5				# counter

	clr	s6				# x min
	clr	s7				# x max
	clr	s8				# y min
	clr	s9				# y max

loop_input:
	lb	t0, 0(a0)
	la	s2, moves
	li	t1, ASCII_CAP_U
	beq	t0, t1, read_next
	li	t1, ASCII_CAP_D
	beq	t0, t1, read_d
	li	t1, ASCII_CAP_L
	beq	t0, t1, read_l
	addi	s2, s2, 6
	j	read_next
read_d:
	addi	s2, s2, 2
	j	read_next
read_l:
	addi	s2, s2, 4
read_next:
	addi	a0, a0, 2
	call	parse_integer
	addi	a0, a0, 11

	lb	t0, 0(s2)
	lb	t1, 1(s2)
	nop

loop_segment:
	inc	s5
	add	s3, s3, t0
	add	s4, s4, t1
	
	bge	s3, s6, no_new_min_x
	mv	s6, s3
no_new_min_x:

	ble	s3, s7, no_new_max_x
	mv	s7, s3
no_new_max_x:
	
	bge	s4, s8, no_new_min_y
	mv	s8, s4
no_new_min_y:

	ble	s4, s9, no_new_max_y
	mv	s9, s4
no_new_max_y:

	addi	sp, sp, -16
	sd	s3, 0(sp)
	sd	s4, 8(sp)
	dec	a1
	bnez	a1, loop_segment

	blt	a0, s11, loop_input
	
	# increase bounds for fill-flood
	dec	s6
	inc	s7
	dec	s8
	inc	s9

	li	a0, 32
	call	malloc
	sd	s6,  0(a0)
	sd	s7,  8(a0)
	sd	s8, 16(a0)
	sd	s9, 24(a0)
	mv	a1, a0

	li	a0, 2
	li	a2, 1
	call	create_array
	mv	s0, a0
	
	# add trench segments to plan
	li	s11, 1
loop_plan:
	mv	a0, s0
	mv	a1, sp
	call	array_addr
	sb	s11, 0(a0)
	addi	sp, sp, 16
	dec	s5
	bnez	s5, loop_plan
	
stop_here:

	# total map area
	sub	s10, s7, s6
	sub	s11, s9, s8
	inc	s10
	inc	s11
	mul	s1, s10, s11

	# initialize queue with corner coordinates
	li	a0, 10
	call	malloc
	sh	s6,  0(a0)
	sh	s8,  2(a0)
	sd	zero, 4(a0)

	mv	s2, a0				# queue head
	mv	s3, a0				# queue tail

	# mark corner coordinates as visited
	mv	a0, s0
	addi	sp, sp, -16
	sd	s6, 0(sp)
	sd	s8, 8(sp)
	mv	a1, sp
	call	array_addr
	li	t0, 1
	sb	t0, 0(a0)

	clr	s11
loop_fill_flood:
	dec	s1
	inc	s11
	mv	a0, s2
	lh	s4, 0(s2)
	lh	s5, 2(s2)
	ld	s2, 4(s2)
	call	free

	la	s6, moves
	li	s9, 4
loop_enqueue:
	lb	t0, 0(s6)
	lb	t1, 1(s6)
	add	s7, s4, t0
	add	s8, s5, t1
	sd	s7, 0(sp)
	sd	s8, 8(sp)
	mv	a0, s0
	mv	a1, sp
	call	array_addr_safe
	beqz	a0, enqueue_skip		# out of bounds
	lb	t0, 0(a0)
	bnez	t0, enqueue_skip		# visited
	li	t0, 1
	sb	t0, 0(a0)
	li	a0, 10
	call	malloc
	sh	s7, 0(a0)
	sh	s8, 2(a0)
	sd	zero, 4(a0)
	beqz	s2, empty_queue
	sd	a0, 4(s3)
	j	enqueue_next
empty_queue:
	mv	s2, a0
enqueue_next:
	mv	s3, a0
enqueue_skip:
	addi	s6, s6, 2
	dec	s9
	bnez	s9, loop_enqueue
after_enqueue:
	bnez	s2, loop_fill_flood

	mv	a0, s1
	call	print_int
	
end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	.section .rodata

filename:
	#.string "inputs/day18-test"
	.string "inputs/day18"

moves:
	.byte	 0, -1			# up
	.byte	 0,  1			# down
	.byte	-1,  0			# left
	.byte	 1,  0			# right
moves_end:
	.byte 	 0
