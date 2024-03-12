	.global	create_array
	.global	array_addr
	.global	array_addr_safe

	.section .text

	# a0: rank
	# a1: address of bounds array
	# a2: size of an element
create_array:
	addi	sp, sp, -48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	# allocate structure
	li	a0, 40
	call	malloc
	mv	s3, a0

	# save rank
	sd	s0, 0(s3)

	# save bounds vector address
	sd	s1, 8(s3)

	# save element lengths
	sd	s2, 32(s3)

	# allocate multipliers vector
	mv	a0, s0
	li	a1, 8
	call	calloc
	sd	a0, 16(s3)

	# allocate vector for dimensions lengths in the stack
	li	t0, 8
	mul	t0, t0, s0
	sub	sp, sp, t0

	# compute dim lengths from bounds
	# length = max - min + 1
	mv	t1, s0				# initialize countdown
	mv	t2, sp				# pointer to lengths
	mv	t3, s1				# pointer to bounds
	li	t6, 1				# initialize total number of elements
loop_compute_lengths:
	ld	t4, 8(t3)			# load maximum
	ld	t5, 0(t3)			# load minimum
	sub	t4, t4, t5			# maximum - minimum
	addi	t4, t4, 1			# add 1
	sd	t4, 0(t2)			# save length
	mul	t6, t6, t4			# multiply total number of elements by length
	addi	t2, t2, 8			# move lengths pointer
	addi	t3, t3, 16			# move bounds pointer
	addi	t1, t1, -1			# decrease countdown
	bnez	t1, loop_compute_lengths	# loop if countdown not null

	# allocate vector and save pointer in the structure
	mv	a0, t6
	mv	a1, s2
	call	calloc
	sd	a0, 24(s3)

	ld	t2, 16(s3)			# load multipliers array pointer
	li	t0, 1
	sd	t0, 0(t2)			# first multiplier is 1
	
	addi	t1, s0, -1			# initialize countdown
	mv	t3, sp				# pointer to lengths
loop_compute_multipliers:
	addi	t2, t2, 8			# move ptr to next multiplier
	beqz	t1, loop_compute_multipliers_end
	ld	t4, 0(t3)			# load length
	mul	t0, t0, t4			# multiply length to last multiplier
	sd	t0, 0(t2)			# store new multiplier
	addi	t1, t1, -1			# decrease coutndown
	j	loop_compute_multipliers
loop_compute_multipliers_end:
	
	
	# free lengths vector 
	li	t0, 8
	mul	t0, t0, s0
	add	sp, sp, t0

	mv	a0, s3
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	addi	sp, sp, 48

	ret



# a0: structure pointer
# a1: coordinates vector
array_addr_safe:
	addi	sp, sp, -8
	sd	ra, 0(sp)
	ld	t0, 0(a0)			# load rank
	ld	t1, 8(a0)			# load bounds pointer
	mv	t4, a1				# copy coordinates vector
check_bounds_loop:
	ld	t2, 0(t4)			# load index
	ld	t3, 0(t1)			# load min bound
	blt	t2, t3, check_bounds_fail
	ld	t3, 8(t1)			# load max bound
	bgt	t2, t3, check_bounds_fail
	addi	t1, t1, 16
	addi	t4, t4, 8
	addi	t0, t0, -1
	bnez	t0, check_bounds_loop
	call	array_addr
	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret
check_bounds_fail:
	mv	a0, zero
	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret



# a0: structure pointer
# a1: coordinates vector
array_addr:
	ld	t0, 0(a0)			# load rank
	ld	t1, 8(a0)			# load bounds pointer
	ld	t2, 16(a0)			# load multipliers pointer
	mv	t3, zero			# initialize index
loop_compute_index:
	ld	t4, 0(a1)			# load coordinate
	ld	t5, 0(t1)			# load lower bound
	sub	t4, t4, t5			# substract lower bound from coordinate
	ld	t5, 0(t2)			# load multiplier
	mul	t4, t4, t5			# multiply coordinate with multiplier
	add	t3, t3, t4			# add coordinate to index
	addi	t1, t1, 16			# move bounds pointer
	addi	t2, t2, 8			# move multipliers pointer
	addi	a1, a1, 8			# move coordinates pointer
	addi	t0, t0, -1			# decrease countdown
	bnez	t0, loop_compute_index		# loop if countdown not null

	ld	t1, 32(a0)			# load member size
	mul	t3, t3, t1			# multiply index by member size
	ld	t1, 24(a0)			# load vector address
	add	a0, t3, t1			# add offset to vector address
	
	ret
