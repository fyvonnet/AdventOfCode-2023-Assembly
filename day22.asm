	.include "macros.inc"
	.include "constants.inc"
	.include "memory.inc"


	.set	HM_BRICK,	 0
	.set	HM_HEIGHT, 	 4

	.set	LIST_NEXT, 	 0
	.set	LIST_BRICK,	 8

	.set	BRICK_DATA_SIZE,64
	.set	COORDS,		16
	.set	BRICKS_ABOVE,	 0		# pointer
	.set	BRICKS_BELOW, 	 8		# pointer
	.set	X_MIN, 		16		# 32 bits integer
	.set	Y_MIN, 		20		# 32 bits integer
	.set	Z_MIN, 		24		# 32 bits integer
	.set	X_MAX, 		28		# 32 bits integer
	.set	Y_MAX,		32		# 32 bits integer
	.set	Z_MAX,		36		# 32 bits integer
	.set	COUNT_BELOW,	40		# 32 bits integer
	.set	REMOVABLE,	44		#  8 bits integer
	.set	FALLEN, 	45		#  8 bits integer





	.section .rodata
filename:
	.string "inputs/day22"


	.bss
	.balign 8

	.set	LISTED_LIST_SIZE, 64*1024
	.type	linked_list, @object
	.size	linked_list, LISTED_LIST_SIZE
linked_list:
	.space	LISTED_LIST_SIZE

	.set	HEIGHTMAP_SIZE, 10*10*8
	.type	heightmap, @object
	.size	heightmap, HEIGHTMAP_SIZE
heightmap:
	.space	HEIGHTMAP_SIZE

	.set	BINTREE_SIZE, 64*1024
	.type	bintree, @object
	.size	bintree, BINTREE_SIZE
bintree:
	.space	BINTREE_SIZE



	.text
	.balign 8


	create_alloc_func linked_list_alloc, linked_list, arena
	create_alloc_func bintree_alloc, bintree, arena


	.globl _start
	.type _start, @function
_start:
	la	a0, linked_list
	la	a1, LISTED_LIST_SIZE
	call	arena_init

	# input lines terminator
	addi	sp, sp, -BRICK_DATA_SIZE
	li	t0, -1
	sw	t0, X_MIN(sp)

	la	a0, filename
	call	map_input_file
	add	s11, a0, a1

	clr	s1				# input lines counter
loop_parse_input:
	inc	s1
	addi	sp, sp, -BRICK_DATA_SIZE
	sw	zero, COUNT_BELOW(sp)
	sd	zero, BRICKS_ABOVE(sp)
	sd	zero, BRICKS_BELOW(sp)
	sb	zero, REMOVABLE(sp)
	sb	zero, FALLEN(sp)
	add	s2, sp, COORDS
	.rept 6
	call	parse_integer
	inc	a0					# skip non-num char
	sw	a1, (s2)
	addi	s2, s2, 4
	.endr
	blt	a0, s11, loop_parse_input

	mv	s0, sp

	# one more under s0 for for the ground at index -1
	addi	sp, sp, -BRICK_DATA_SIZE
	
	mv	a0, s0
	mv	a1, s1
	li	a2, BRICK_DATA_SIZE
	la	a3, compar_sort
	call	quicksort

	# initialize height map with level 0 and brick number -1 (ground)
	la	t0, heightmap
	li	t1, 100
	li	t2, -1
loop_initialize:
	sw	zero, HM_HEIGHT(t0)
	sw	t2, HM_BRICK(t0)
	dec	t1
	addi	t0, t0, 8
	bnez	t1, loop_initialize

	mv	s2, s0					# brick input pointer
	clr	s3					# brick number

loop:
	lw	t0, X_MIN(s2)
	bltz	t0, loop_end

	la	a0, bintree
	li	a1, BINTREE_SIZE
	call	arena_init

	la	a0, heights_set_compar
	la	a1, bintree_alloc
	la	a2, empty_function
	call	redblacktree_init
	mv	s5, a0

	mv	a0, s2
	la	a1, heights_set_insert
	mv	a2, s5
	call	for_all_coords

	call	redblacktree_peek_leftmost
	lw	s11, HM_HEIGHT(a0)			# max height under the brick

	lw	t0, Z_MIN(s2)				# min height of the brick

	sub	t1, t0, s11
	dec	t1					# falling height of brick

	addi	sp, sp, -8
	lw	t0, Z_MAX(s2)
	sub	t0, t0, t1				# new max height after end of fall
	sw	t0, HM_HEIGHT(sp)
	sw	s3, HM_BRICK(sp)
	ld	a2, (sp)
	addi	sp, sp, 8

	mv	a0, s2
	la	a1, heights_map_update
	call    for_all_coords

	# for all supporting bricks
loop_supports:
	mv	a0, s5
	call	redblacktree_pop_leftmost
	blez	a0, loop_supports_end
	lw	t0, HM_HEIGHT(a0)
	bne	t0, s11, loop_supports_end
	lw	t1, HM_BRICK(a0)			# index of supporting brick
	slli	t1, t1, 6				# x64 to match brick data size
	add	s8, t1, s0				# address of the supporting brick datas

	# push brick below to the below list
	la	a0, 16
	call	linked_list_alloc
	ld	t0, BRICKS_BELOW(s2)
	sd	t0, LIST_NEXT(a0)
	sd	s8, LIST_BRICK(a0)
	sd	a0, BRICKS_BELOW(s2)
	

	lw	t2, COUNT_BELOW(s2)
	inc	t2					# current brick supported by one more brick
	sw	t2, COUNT_BELOW(s2)

	# push current brick to the supporting brick's list
	la	a0, 16
	call	linked_list_alloc
	ld	t1, BRICKS_ABOVE(s8)
	sd	t1, LIST_NEXT(a0)
	slli	t0, s3, 6
	add	t0, t0, s0
	sd	t0, LIST_BRICK(a0)
	sd	a0, BRICKS_ABOVE(s8)

	j	loop_supports
loop_supports_end:

	inc	s3
	addi	s2, s2, BRICK_DATA_SIZE

	j	loop

loop_end:


	##########
	# PART 1 #
	##########

	# a brick can be safely disintegrated if
	#	- it supports no other brick;
	#	- it supports only bricks supported by 2 or more bricks.

	clr	a0
	mv	t4, s0
	li	t5, 1
loop_removeable:
	lw	t0, X_MIN(t4)
	bltz	t0, loop_removeable_end
	ld	t2, BRICKS_ABOVE(t4)				# load head of list
loop_check_supported:
	beqz	t2, loop_check_supported_end
	ld	t3, LIST_BRICK(t2)
	lw	t1, COUNT_BELOW(t3)
	beq	t1, t5, loop_check_supported_fail		# can't be removed if brick above has only one support
	ld	t2, LIST_NEXT(t2)
	j	loop_check_supported
loop_check_supported_end:
	sb	t5, REMOVABLE(t4)
	inc	a0
loop_check_supported_fail:
	addi	t4, t4, BRICK_DATA_SIZE
	j	loop_removeable
loop_removeable_end:

	call	print_int



	##########
	# PART 2 #
	##########


	clr	s1
	mv	s2, s0
loop_part2: # for every non-removable brick

	lb	t0, REMOVABLE(s2)
	bnez	t0, loop_part2_next

	# reset memory
	la	a0, bintree
	li	a1, BINTREE_SIZE
	call	arena_init

	# initialize fallen set
	la	a0, brick_ptr_compar
	la	a1, bintree_alloc
	clr	a2
	call	redblacktree_init
	mv	s4, a0

	# insert brick in the fallen set
	mv	a0, s4
	mv	a1, s2
	call	redblacktree_insert

	ld	s3, BRICKS_ABOVE(s2)
loop_call_above:
	beqz	s3, loop_call_above_end
	ld	a0, LIST_BRICK(s3)
	mv	a1, s4
	call	part2_rec
	ld	s3, LIST_NEXT(s3)
	j	loop_call_above

loop_call_above_end:

	mv	a0, s4
	call	redblacktree_count_nodes
	dec	a0				# un-count starting node
	add	s1, s1, a0

loop_part2_next:

	addi	s2, s2, BRICK_DATA_SIZE
	lw	t0, X_MIN(s2)
	bgez	t0, loop_part2


	mv	a0, s1
	call	print_int

	exit 
	.size	_start, .-_start


	# a0: brick ptr
	# a1: fallen set
	.type	part2_rec, @function
part2_rec:
	addi	sp, sp, -48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1

	ld	s2, BRICKS_BELOW(s0)
loop_check_below:
	mv	a0, s1
	ld	a1, LIST_BRICK(s2)
	call	redblacktree_search
	beqz	a0, part2_rec_ret
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_check_below

	mv	a0, s1
	mv	a1, s0
	call	redblacktree_insert

	ld	s2, BRICKS_ABOVE(s0)
loop_call_above_rec:
	beqz	s2, part2_rec_ret
	ld	a0, LIST_BRICK(s2)
	mv	a1, s1
	call	part2_rec
	ld	s2, LIST_NEXT(s2)
	j	loop_call_above_rec

part2_rec_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 48
	ret
	.size	part2_rec, .-part2_rec


	# a0: X
	# a1: Y
	.type	get_addr, @function
get_addr:
	li	t0, 10
	mul	t0, t0, a1
	add	t0, t0, a0
	li	t1, 8
	mul	t0, t0, t1
	la	t1, heightmap
	add	a0, t0, t1
	ret
	.size	get_addr, .-get_addr



	# a0: brick data pointer
	# a1: function pointer
	# a2: pointer
	.type	for_all_coords, @function
for_all_coords:
	addi	sp, sp, -80
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)

	mv 	s0, a0
	mv	s1, a1
	mv	s2, a2
	lw	s3, X_MIN(a0)	# fixed
	lw	s4, X_MIN(a0)	# variable
	lw	s5, Y_MIN(a0)
	lw	s6, X_MAX(a0)
	lw	s7, Y_MAX(a0)
loop_for_all_coords:
	mv	a0, s4		# X
	mv	a1, s5		# Y
	mv	a2, s2		# pointer
	jalr	ra, s1
	inc	s4
	ble	s4, s6, loop_for_all_coords
	mv	s4, s3
	inc	s5
	ble	s5, s7, loop_for_all_coords

	mv	a0, s2

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	addi	sp, sp, 80

	ret
	.size	for_all_coords, .-for_all_coords


	# a0: X
	# a1: Y
	# a2: height/brick
	.type	heights_map_update, @function
heights_map_update:
	addi	sp, sp, -16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a2
	call	get_addr
	sd	s0, (a0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	addi	sp, sp, 16
	ret
	.size	heights_map_update, .-heights_map_update


	# a0: X
	# a1: Y
	# a2: tree
	.type heights_set_insert, @function
heights_set_insert:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a2

	call	get_addr
	mv	s1, a0

	la	a0, 8
	call	bintree_alloc
	ld	t0, (s1)
	sd	t0, (a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 64

	ret
	.size	heights_set_insert, .-heights_set_insert


	.type	heights_set_compar, @function
heights_set_compar:
	lw	t0, HM_HEIGHT(a0)
	lw	t1, HM_HEIGHT(a1)
	sub	t2, t1, t0
	bnez	t2, heights_set_compar_ret
	lw	t0, HM_BRICK(a0)
	lw	t1, HM_BRICK(a1)
	sub	t2, t0, t1
heights_set_compar_ret:
	mv	a0, t2
	ret
	.size	heights_set_compar, .-heights_set_compar
	


	.type	compar_sort, @function
compar_sort:
	lw	t0, Z_MIN(a0)
	lw	t1, Z_MIN(a1)
	sub	a0, t0, t1
	ret
	.size	compar_sort, .-compar_sort

	.type 	brick_ptr_compar, @function
brick_ptr_compar:
	sub	a0, a0, a1
	ret
	.size	brick_ptr_compar, .-brick_ptr_compar
