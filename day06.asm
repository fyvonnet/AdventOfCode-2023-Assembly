	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1



        ######     #    ######  #######      #
        #     #   # #   #     #    #        ##
        #     #  #   #  #     #    #       # #
        ######  #     # ######     #         #
        #       ####### #   #      #         #
        #       #     # #    #     #         #
        #       #     # #     #    #       #####


	# read all numbers and store them in the stack
	clr	s0					# initialize counter
	addi	s9, sp, -2
loop_read_input:
	inc	s0
	call	skip_to_digit
	call	parse_integer
	addi	sp, sp, -2
	sh	a1, 0(sp)
	inc	a0
	blt	a0, s11, loop_read_input

	# put read numbers in the right order
	mv	t0, sp
loop_invert:
	lh	t1, 0(t0)
	lh	t2, 0(s9)
	sh	t2, 0(t0)
	sh	t1, 0(s9)
	addi	t0, t0, 2
	addi	s9, s9, -2
	blt	t0, s9, loop_invert

	li	t0, 2
	div	s0, s0, t0

	mv	s1, sp					# pointer to race times vector
	mul	t0, t0, s0
	add	s2, sp, t0				# pointer to race distances vector

	li	s3, 1					# initialize margin
loop_races:
	lh	a0, 0(s1)				# load time
	lh	a1, 0(s2)				# load record distance
	call	count_victories
	mul	s3, s3, a0
	addi	s1, s1, 2				# move pointer to next time
	addi	s2, s2, 2				# move pointer to next distance
	dec	s0					# decrement countdown
	bnez	s0, loop_races				# loop if countdown not null

	mv	a0, s3
	call	print_int



        ######     #    ######  #######     #####
        #     #   # #   #     #    #       #     #
        #     #  #   #  #     #    #             #
        ######  #     # ######     #        #####
        #       ####### #   #      #       #
        #       #     # #    #     #       #
        #       #     # #     #    #       #######

	
	mv	a0, s10					# restore input pointer
	call	read_line
	mv	s1, a1
	call	read_line

	mv	a0, s1
	call	count_victories
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



count_victories:
	li	t0, 1					# start with 1ms push time or 1mm/s speed
	dec	a0					# one less ms available
	clr	t4					# initialize counter
loop_times:
	mul	t3, t0, a0				# distance traveled during remaining time
	ble	t3, a1, no_win				# did not beat record
	inc	t4	
no_win:
	inc	t0					# increase puch time and speed
	dec	a0					# decrease remaining race time
	bnez	a0, loop_times				# loop if race time remaining
	mv	a0, t4
	ret


read_line:
	addi	sp, sp, -16
	sd	s0, 0(sp)
	sd	ra, 8(sp)

	addi	sp, sp, -50				# allocate enough stack space for all the digits
	call	skip_to_digit				# skip to first digit
	li	t0, ASCII_LF
	li	t4, ASCII_SPACE
	mv	t2, sp					# digits pointer
loop_read_line:
	lb	t1, 0(a0)
	beq	t1, t0, loop_read_line_end		# eol reached, end loop
	beq	t1, t4, skip_space			# space found, skip character copy
	sb	t1, 0(t2)				# copy digit
	inc	t2					# increment digits pointer
skip_space:
	inc	a0					# increment input pointer
	j	loop_read_line
loop_read_line_end:
	mv	s0, a0					# save input pointer
	mv	a0, sp					# parse integer from stack
	call	parse_integer
	addi	a0, s0, 1				# restore input pointer and skip LF

	addi	sp, sp, 50				# free stack space
	
	ld	s0, 0(sp)
	ld	ra, 8(sp)
	addi	sp, sp, 16

	ret
	
	.section .rodata

filename:
	.string "inputs/day06"

