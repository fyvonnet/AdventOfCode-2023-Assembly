	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	# measure row length
	mv	t0, a0
	li	s1, -1
	li	t2, ASCII_LF
loop_measure:
	inc	s1
	lb	t3, 0(t0)
	inc	t0
	bne	t3, t2, loop_measure

	# allocate memory for square map
	mul	a0, s1, s1
	call	malloc
	mv 	s0, a0

	# copy map to memory
	mv	t0, s10
	mv	t1, a0
	li	t3, ASCII_LF
	li	t4, ASCII_CAP_S
	clr	t5					# column
	clr	t6					# row
loop_load:
	lb	t2, 0(t0)
	beq	t2, t3, found_lf			# skip LF
	beq	t2, t4, found_start
back_start:
	sb	t2, 0(t1)
	inc	t5
	inc	t1
back_lf:
	inc	t0
	bne	t0, s11, loop_load


        ######     #    ######  #######      #
        #     #   # #   #     #    #        ##
        #     #  #   #  #     #    #       # #
        ######  #     # ######     #         #
        #       ####### #   #      #         #
        #       #     # #    #     #         #
        #       #     # #     #    #       #####


	mv	s4, s2					# starting X coordinate
	mv	s5, s3					# starting Y coordinate
	li	s6, 0b00001111				# allow all directions at start
	clr	s7					# clear steps count
	
	# terminator
	addi	sp, sp, -16
	li	t0, -1
	sh	t0, 0(sp)

loop_count_steps:
	mv	a0, s4
	call	print_int
	mv	a0, s5
	call	print_int

	mul	t0, s5, s1				# index of beginning of row
	add	t0, t0, s4				# index of square
	add	t6, t0, s0				# address of square

	lb	t0, 0(t6)				# load character at current coordinates
	beqz	t0, loop_count_steps_end
	sb	zero, 0(t6)
	la	t1, possible_directions
loop_search:
	lb	t2, 0(t1)
	beq	t2, t0, loop_search_end
	addi	t1, t1, 3
	j	loop_search
loop_search_end:
	lb	t0, 1(t1)				# load possible directions mask
	and	t0, t0, s6				# apply exclusion mask

	# store angle coordinates in the stack
	lb	t2, 2(t1)
	beqz	t2, skip_store
	addi	sp, sp, -16
	sh	s4, 0(sp)
	sh	s5, 2(sp)
skip_store:

	la	t1, rel_coords
loop_select_dir:
	andi	t2, t0, 1				# check last bit
	bnez	t2, loop_select_dir_end			# exit if bit high
	addi	t1, t1, 3				# move to next candidate direction
	srli	t0, t0, 1				# shift directions mask left
	j	loop_select_dir
loop_select_dir_end:
	lb	t4, 0(t1)
	lb	t5, 1(t1)
	add	s4, s4, t4				# new X coordinate
	add	s5, s5, t5				# new Y coordinate
	lb	s6, 2(t1)				# exclusion mask
	inc	s7
	j	loop_count_steps
loop_count_steps_end:

	addi	sp, sp, -16
	sh	s2, 0(sp)
	sh	s3, 2(sp)
	
	srli	s7, s7, 1				# farthest distance is half the whole loop length

	j	end

	mv	a0, s7
	call	print_int



        ######     #    ######  #######     #####
        #     #   # #   #     #    #       #     #
        #     #  #   #  #     #    #             #
        ######  #     # ######     #        #####
        #       ####### #   #      #       #
        #       #     # #    #     #       #
        #       #     # #     #    #       #######

	# https://en.wikipedia.org/wiki/Pick%27s_theorem
	# https://en.wikipedia.org/wiki/Shoelace_formula


	clr	s11
loop_trapezoid:
	lh	t2, 0(sp)				# x_i+1
	lh	t3, 2(sp)				# y_i+1
	addi	sp, sp, 16
	lh	t0, 0(sp)				# x_i
	lh	t1, 2(sp)				# y_i
	bltz	t0, loop_trapezoid_end
	add	t1, t1, t3				# y_i + y_i+1
	sub	t0, t0, t2				# x_i - x_i+1
	mul	t0, t0, t1				# (y_i + y_i+1) * (x_i - x_i+1)
	add	s11, s11, t0
	j	loop_trapezoid
loop_trapezoid_end:

	li	t0, 2
	div	s11, s11, t0
	bgez	s11, not_neg
	neg	s11, s11
not_neg:

	sub	a0, s11, s7
	inc	a0
	call	print_int

end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

found_start:
	mv	s2, t5
	mv	s3, t6
	li	t2, ASCII_SEVEN
	j	back_start

found_lf:
	inc	t6					# increment row number
	clr	t5					# clear column number
	j	back_lf
	
	.section .rodata

filename:
	.string "inputs/day10"

	# 0b0000URDL
possible_directions:
	.ascii	"|"
	.byte	0b00001010
	.byte	0
	.ascii	"-"
	.byte	0b00000101
	.byte	0
	.ascii	"L"
	.byte	0b00001100
	.byte	1
	.ascii	"J"
	.byte	0b00001001
	.byte	1
	.ascii	"7"
	.byte	0b00000011
	.byte	1
	.ascii	"F"
	.byte	0b00000110
	.byte	1
	
	# relative coordinates (X, Y)
	# masks to exclude origine direction
rel_coords:
	# left
	.byte	-1,  0
	.byte	0b00001011

	# down
	.byte	 0,  1
	.byte	0b00000111

	# right
	.byte	 1,  0
	.byte	0b00001110

	# up
	.byte	 0, -1
	.byte	0b00001101

format: .string "%d %d\n"
