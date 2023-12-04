	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1


	mv	t0, a0
	li	t2, ASCII_LF
loop_seek_eol:
	inc	t0
	lb	t3, 0(t0)
	bne	t2, t3, loop_seek_eol
	inc	t0

	sub	t0, t0, a0			# length of line
	div	s2, a1, t0			# number of cards
	addi	t0, t0, -3			# substract separator and LF from line length
	addi	t0, t0, -9 			# substract "Card XXX:"
	#addi	t0, t0, -7 			# skip "Card X:"

	li	t1, 3				# 3 characters per number
	div	s1, t0, t1			# numbers per line

	li	t0, -1
	dec	sp
	sb	t0, 0(sp)

	sub	sp, sp, s2			# allocate stack space for winning numbers count
	mv	s3, sp
	
	sub	sp, sp, s1			# allocate stack space for numbers vector
	mv	s4, sp				# pointer to vector
	
	


	mv	s5, s3				# copy pointer to winning numbers count
	mv	s0, a0
loop_input:
	mv	s6, s4				# copy pointer to numbers vector
	addi	s0, s0, 9 			# skip "Card XXX:"
	#addi	s0, s0, 7 			# skip "Card X:"

	# skip to next digit
loop_skip_to_digit:
	inc	s0
	lb	a0, 0(s0)
	call	is_digit
	beqz	a0, loop_skip_to_digit

	mv	a0, s0
	call	parse_integer
	mv	s0, a0
	sb	a1, 0(s6)
	inc	s6

	li	t0, ASCII_LF
	lb	t1, 0(s0)
	bne	t0, t1, loop_skip_to_digit	# loop if LF not reached

	mv	a0, sp
	mv	a1, s1
	li	a2, 1
	la	a3, compar
	call	quicksort
	
	addi	t0, s1, -1			# initilize countdown
	mv	t1, sp				# pointer to sorted list of numbers
	clr	t4				# initialize winning numbers counter
loop_search_dup:
	lb	t2, 0(t1)
	lb	t3, 1(t1)
	bne	t2, t3, not_equal
	inc	t4				# increment winning numbers count
not_equal:
	inc	t1
	dec	t0
	bnez	t0, loop_search_dup		# loop if countdown not null

	sb	t4, 0(s5)			# store winning numbers count in the vactor
	inc	s5

	inc	s0				# skip to next line

	blt	s0, s11, loop_input

	add	sp, sp, s1			# free numbers vector


   	######     #    ######  #######      #
   	#     #   # #   #     #    #        ##
   	#     #  #   #  #     #    #       # #
   	######  #     # ######     #         #
   	#       ####### #   #      #         #
  	#       #     # #    #     #         #
   	#       #     # #     #    #       #####


	mv	t0, s3
	clr	t3				# initialize total score
loop_part1:
	lb	t1, 0(t0)
	beqz	t1, no_points			# no winning numbers, no points
	bltz	t1, loop_part1_end		# loop end if negative number read
	li	t2, 1				# initialize score for current card
	dec	t1
loop_score:
	beqz	t1, loop_score_end
	slli	t2, t2, 1			# double score for each winning number
	dec	t1
	j	loop_score
loop_score_end:
	add	t3, t3, t2			# add coard score to total score
no_points:
	inc	t0				# point to next winning number count
	j	loop_part1
loop_part1_end:
	
	mv	a0, t3
	call	print_int


	######     #    ######  #######     #####
	#     #   # #   #     #    #       #     #
	#     #  #   #  #     #    #             #
	######  #     # ######     #        #####
	#       ####### #   #      #       #
	#       #     # #    #     #       #
	#       #     # #     #    #       #######


	addi	sp, sp, -8
	li	t0, -1
	sd	t0, 0(sp)

	clr	a0				# initialize total won cards

	mv	t0, s2
	slli	t0, t0, 3			# make each vector element 64 bits
	sub	sp, sp, t0			# won cards count vector

	# initialize won cards count vector to 1
	mv	t0, sp
	mv	t1, s2
	li	t2, 1
loop_init:
	sd	t2, 0(t0)
	addi	t0, t0, 8
	dec	t1
	bnez	t1, loop_init

	mv	t0, sp				# won cards vector pointer
	mv	t1, s3				# winning cards number vector pointer
loop_part2:
	ld	t2, 0(t0)			# load current card count
	bltz	t2, loop_part2_end		# vector terminator reached, exit loop
	add	a0, a0, t2			# add to sum
	lb	t3, 0(t1)			# load winning numbers count
	beqz	t3, loop_part2_next		# no winning numbers, skip
	addi	t4, t0, 8			# pointer to next card
	mv	t6, t3				# initialize countdown
loop_won_cards:
	beqz	t6, loop_part2_next		# countdown over
	ld	t5, 0(t4)			# load cards alread won
	bltz	t5, loop_part2_next		# vector terminator reached, end loop
	add	t5, t5, t2			# add as much won cards as current cards count
	sd	t5, 0(t4)
	add	t4, t4, 8
	dec	t6
	j	loop_won_cards
loop_part2_next:
	add	t0, t0, 8
	inc	t1
	j	loop_part2
loop_part2_end:

	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

compar:
	lb	t0, 0(a0)
	lb	t1, 0(a1)
	sub	a0, t0, t1
	ret

	.section .rodata

filename:
	.string "inputs/day04"

