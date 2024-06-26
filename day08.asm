	.global _start

	.include "macros.inc"
	.include "constants.inc"

	.set	LEFT, 4
	.set	RIGHT, 8

	.section .text

_start:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	# add terminator
	dec	sp
	li	t0, -1
	sb	t0, 0(sp)

	# save position of last element of the directions vector
	addi	t6, sp, -1
	
	li	t2, ASCII_CAP_L
	li	t3, ASCII_LF
loop_read_dirs:
	lb	t0, 0(a0)
	beq	t0, t3, loop_read_dirs_end
	li	t1, LEFT
	beq	t0, t2, left
	li	t1, RIGHT
left:
	dec	sp
	sb	t1, 0(sp)
	inc	a0
	j	loop_read_dirs
loop_read_dirs_end:
	addi	a0, a0, 2				# skip LFs 

	mv	s0, sp					# copy directions vector address

	# invert directions order
	mv	t0, s0
loop_invert:
	lb	t1, 0(t0)
	lb	t5, 0(t6)
	sb	t1, 0(t6)
	sb	t5, 0(t0)
	inc	t0
	dec	t6
	blt	t0, t6, loop_invert

	# nodes vector terminator
	addi	sp, sp, -16
	sw	zero, 0(sp)

	clr	s2					# clear nodes counter
loop_read_nodes:
	inc	s2					# increment counter
	addi	sp, sp, -16
	call	read_letters
	sw	a1, 0(sp)
	addi	a0, a0, 4				# skip " = ("
	call	read_letters
	sw	a1, 4(sp)
	addi	a0, a0, 2				# skip ", "
	call	read_letters
	sw	a1, 8(sp)
	addi	a0, a0, 2				# skip ")\n"
	blt	a0, s11, loop_read_nodes
	mv	s1, sp					# copy nodes vector pointer

	# sort nodes
	mv	a0, s1
	mv	a1, s2
	li	a2, 16
	la	a3, compar_codes
	call	quicksort


	# vector terminator
	addi	sp, sp, -4
	sw	zero, 0(sp)

	addi	s7, sp, -4				# set pointer to last element of the list (AAA)


	# filter nodes ending with A
	mv	t4, s1	
	li	t5, ASCII_CAP_A
	clr	t6
loop_filter:
	lw	t0, 0(t4)
	beqz	t0, loop_filter_end			# nodes vector terminator reached
	andi	t1, t0, 0b11111111			# isolate last character
	bne	t1, t5, skip_store			# last character is not A
	addi	sp, sp, -4
	sw	t0, 0(sp)
	inc	t6
skip_store:
	addi	t4, t4, 16
	j	loop_filter
loop_filter_end:


	mv	s8, sp

loop_a_nodes:
	lw	s6, 0(s8)
	beqz	s6, loop_a_nodes_end
	mv	s3, s0					# pointer to directions vector
	mv	s4, s1					# pointer to AAA node (first node)
	clr	s5					# clear the steps counter

loop_search:
	andi	t0, s6, 0b11111111
	li	t1, ASCII_CAP_Z
	beq	t0, t1, loop_search_end

	inc	s5

	addi	sp, sp, -16
	sw	s6, 0(sp)

	mv	a0, s1
	mv	a1, s2
	li	a2, 16
	la	a3, compar_codes
	mv	a4, sp
	call	binsearch

	addi	sp, sp, 16

	lb	t0, 0(s3)				# load direction
	bgez	t0, direction_ok			# check if direction is positive
	mv	s3, s0					# reset directions pointer
	lb	t0, 0(s3)				# load direction again
direction_ok:
	inc	s3					# point to next direction
	add	a0, a0, t0				# point to next node
	lw	s6, 0(a0)				# load node number
	j	loop_search
loop_search_end:

	sw	s5, 0(s8)				# store number of steps
	addi	s8, s8, 4
	j	loop_a_nodes
loop_a_nodes_end:
	
	lw	a0, 0(s7)				# load number of steps for AAA
	call	print_int

	# compute GCD of first 2 elements
	lw	a0, 0(sp)
	lw	a1, 4(sp)
	call	gcd

	addi	s8, sp, 8

	# compute GCD of the list
loop_gcd:
	lw	a1, 0(s8)
	beqz	a1, loop_gcd_end
	call	gcd
	addi	s8, s8, 4
	j	loop_gcd
loop_gcd_end:

	mv	s8, sp
	mv	s7, a0	
loop_lcm:
	lw	t0, 0(s8)
	beqz	t0, loop_lcm_end
	div	t0, t0, a0
stop_here:
	mul	s7, s7, t0
	addi	s8, s8, 4
	j	loop_lcm
loop_lcm_end:
	
	mv	a0, s7
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall


gcd:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	bnez	s1, b_not_null
	mv	a0, s0
	j	gcd_end
b_not_null:
	ble	s1, s0, b_less_equal_a
	mv	a0, s1
	mv	a1, s0
	call	gcd
	j	gcd_end
b_less_equal_a:
	mv	a0, s1
	rem	a1, s0, s1
	call	gcd
gcd_end:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24
	ret


read_letters:
	clr	a1
	.rept 3
	slli	a1, a1, 8
	lb	t0, 0(a0)
	or	a1, a1, t0
	inc	a0
	.endr
	ret


compar_codes:
	lw	t0, 0(a0)
	lw	t1, 0(a1)
	sub	a0, t0, t1
	ret

	.section .rodata

filename:
	.string "inputs/day08"

