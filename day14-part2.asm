	.include "macros.inc"
	.include "constants.inc"

	.set	ROUND, ASCII_CAP_O
	.set	CUBE, ASCII_HASH
	.set	EMPTY, ASCII_DOT

	.bss
	.balign 8
	.type	arena, @object
	.set	ARENA_SIZE, 16*1024
	.size	arena, ARENA_SIZE
arena:	.zero	ARENA_SIZE



	.text


	.global _start
_start:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	mv	s10, a1
	add	s11, a0, a1

	# allocate stack space for map
	sub	sp, sp, a1

	# align stack
	li	t0, 0b1111
	not	t0, t0
	and	sp, sp, t0

	mv	a0, s0
	call	line_length
	mv	s1, a0

	# copy map without LFs to the stack
	mv	t0, sp
	li	t2, ASCII_LF
loop_copy:
	lb	t1, 0(s0)
	beq	t1, t2, lf_found
	sb	t1, 0(t0)
	inc	t0
lf_found:
	inc	s0
	bne	s0, s11, loop_copy
	sb	zero, 0(t0)				# string terminator
	mv	s0, sp

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, compar
	la	a1, alloc
	clr	a2
	call	redblacktree_init
	mv	s10, a0

	# insert the initial mapo in the set
	mv	a0, s10
	mv	a1, s0
	clr	a2
	call	set_insert

	li	s11, 0

loop_cycles:

	la	s2, moves
	inc	s11

loop_tilts:

	# load start coordinates
	lb	s3, 0(s2)
	bgez	s3, x_not_neg
	addi	s3, s1, -1
x_not_neg:
	lb	s4, 1(s2)
	bgez	s4, y_not_neg
	addi	s4, s1, -1
y_not_neg:

	nop

loop_move_along_side:
	beq	s3, s1, loop_move_along_side_end
	beq	s4, s1, loop_move_along_side_end
	bltz	s3, loop_move_along_side_end
	bltz	s4, loop_move_along_side_end

	# save side coordinates
	addi	sp, sp, -16
	sb	s3, 0(sp)
	sb	s4, 1(sp)

	# load rounds rock search moves
	lb	s5, 2(s2)
	lb	s6, 3(s2)

loop_search_rock:
	beq	s3, s1, loop_search_rock_end
	beq	s4, s1, loop_search_rock_end
	bltz	s3, loop_search_rock_end
	bltz	s4, loop_search_rock_end
	mv	a0, s0
	mv	a1, s1
	mv	a2, s3
	mv	a3, s4
	call	get_addr
	li	t0, ROUND
	lb	t1, 0(a0)
	bne	t0, t1, not_round

	# round rock found, move it downward
	addi	sp, sp, -16
	sb	s3, 0(sp)
	sb	s4, 1(sp)
	mv	a0, s0
	mv	a1, s1
	mv	a2, s3
	mv	a3, s4
	call	get_addr
	li	t0, EMPTY
	sb	t0, 0(a0)
	sub	s7, s3, s5					# front coordinate (x)
	sub	s8, s4, s6					# front coordinate (y)
loop_move_rock:
	beq	s7, s1, loop_move_rock_end
	beq	s8, s1, loop_move_rock_end
	bltz	s7, loop_move_rock_end
	bltz	s8, loop_move_rock_end
	mv	a0, s0
	mv	a1, s1
	mv	a2, s7
	mv	a3, s8
	call	get_addr
	li	t0, EMPTY
	lb	t1, 0(a0)
	bne	t0, t1, loop_move_rock_end
	mv	s3, s7
	mv	s4, s8
	sub	s7, s7, s5
	sub	s8, s8, s6
	j	loop_move_rock
loop_move_rock_end:	
	mv	a0, s0
	mv	a1, s1
	mv	a2, s3
	mv	a3, s4
	call	get_addr
	li	t0, ROUND
	sb	t0, 0(a0)
	lb	s3, 0(sp)
	lb	s4, 1(sp)
	addi	sp, sp, 16
	
not_round:
	add	s3, s3, s5
	add	s4, s4, s6
	j	loop_search_rock
loop_search_rock_end:
	lb	s3, 0(sp)
	lb	s4, 1(sp)
	addi	sp, sp, 16
	lb	t0, 4(s2)
	lb	t1, 5(s2)
	add	s3, s3, t0
	add	s4, s4, t1
	j	loop_move_along_side
	
loop_move_along_side_end:

	lb	t0, 6(s2)
	beqz	t0, loop_tilts_end
	addi	s2, s2, 7
	j	loop_tilts

loop_tilts_end:
	
	mv	a0, s10
	mv	a1, s0
	mv	a2, s11
	call	set_insert
	mv	s9, a0

	mv	a0, s0
	mv	a1, s1
	call	total_load
	addi	sp, sp, -8
	sd	a0, 0(sp)

	bltz	s9, loop_cycles

	li	t0, 1000000000
	sub	t0, t0, s9
	sub	t1, s11, s9
	rem	t2, t0, t1
	add	t2, t2, s9
	slli	t2, t2, 3
	sub	t2, s0, t2
	ld	a0, 0(t2)
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	# a0: map
	# a1: side
	# a2: column
	# a3: row
get_addr:
	mul	t0, a3, a1
	add	t0, t0, a2
	add	t0, t0, a0
	mv	a0, t0
	ret

	# a0: map
	# a1: side
total_load:
	clr	t0
	mv	t1, a1
	li	t3, ROUND
loop_load_rows:
	mv	t2, a1
loop_load_cols:
	lb	t4, 0(a0)
	bne	t4, t3, load_not_round
	add	t0, t0, t1
load_not_round:
	inc	a0
	dec	t2
	bnez	t2, loop_load_cols
	dec	t1
	bnez	t1, loop_load_rows
	mv	a0, t0
	ret


	# a0: tree
	# a1: map
	# a2: cycle
set_insert:	
	addi	sp, sp, -64
	sd	s0,  0(sp)
	sd	s1,  8(sp)
	sd	s2, 16(sp)
	sd	ra, 24(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	
	la	a0, 16
	call	alloc

	li      t6, 5381
	li      t1, 33
loop_djb2:
	lb      t0, (s1)
	beqz    t0, loop_djb2_end
	mul     t6, t6, t1
	add     t6, t6, t0
	inc	s1
	j       loop_djb2
loop_djb2_end:

	sd	t6, 0(a0)
	sd	s2, 8(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert

	bnez 	a0, set_insert_found
	li	a0, -1
	j	set_insert_end

set_insert_found:
	ld	a0, 8(a0)

set_insert_end:
	ld	s0,  0(sp)
	ld	s1,  8(sp)
	ld	s2, 16(sp)
	ld	ra, 24(sp)
	addi	sp, sp, 64
	ret

compar:
	ld	t0, 0(a0)
	ld	t1, 0(a1)
	sub	a0, t0, t1
	ret

alloc:
	addi	sp, sp, -16
	sd	ra,  0(sp)
	mv	a1, a0
	la	a0, arena
	call	arena_alloc
	ld	ra,  0(sp)
	addi	sp, sp, 16
	ret
	
	


	
	.section .rodata

filename:
	.string "inputs/day14"

moves:
	# north
	.byte	0, 0					# start coordinates
	.byte	0, 1					# searching for or moving stones
	.byte	1, 0					# move along side
	.byte	1					# continue

	# west
	.byte	0, 0
	.byte	1, 0
	.byte	0, 1
	.byte	1

	# south
	.byte	0, -1
	.byte	0, -1
	.byte	1, 0
	.byte 	1

	# easr
	.byte	-1, 0
	.byte	-1, 0
	.byte	0, 1
	.byte	0

