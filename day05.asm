	.global _start

	.include "macros.inc"
	.include "constants.inc"

	.set	DEST_START, 	 0
	.set	SOURCE_START, 	 8
	.set	LENGTH, 	16

	.section .text

_start:
	la	a0, arena
	call	arena_init

	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	mv	s10, a0

	addi	sp, sp, -64			# allocate space for 8 pointers
	mv	s0, sp

	call	read_all_numbers
	sd	a1, 0(s0)
	mv	s1, a2				# save seeds count

	addi	s3, s0, 8
	li	s4, 7				# initialize countdown, 7 maps to read

loop_read_maps:
	call	read_all_numbers
	sd	a1, 0(s3)			# store address in pointers vector
	mv	s2, a0				# save input pointer

	mv	a0, a1
	li	t0, 3				# each line contains 3 elements
	div	a1, a2, t0
	li	a2, 24
	la	a3, compar
	call	quicksort
	
	mv	a0, s2				# restore input pointer
	addi	s3, s3, 8			# move to next element of pointers vector
	dec	s4
	bnez	s4, loop_read_maps



        ######     #    ######  #######      #
        #     #   # #   #     #    #        ##
        #     #  #   #  #     #    #       # #
        ######  #     # ######     #         #
        #       ####### #   #      #         #
        #       #     # #    #     #         #
        #       #     # #     #    #       #####


	ld	s2, 0(s0)			# load pointer to seeds vector
	li	s3, -1				# maximum unsigned value
	mv	s4, s1				# initialize countdown
loop_seeds:
	ld	a0, 0(s2)
	add	a1, s0, 8
	call	get_location
	bgtu	a0, s3, no_new_min
	mv	s3, a0
no_new_min:
	dec	s4
	addi	s2, s2, 8			# point to next seed
	bnez	s4, loop_seeds

	mv	a0, s3
	call	print_int


        ######     #    ######  #######     #####
        #     #   # #   #     #    #       #     #
        #     #  #   #  #     #    #             #
        ######  #     # ######     #        #####
        #       ####### #   #      #       #
        #       #     # #    #     #       #
        #       #     # #     #    #       #######


	ld	s2, 0(s0)			# load pointer to seeds vector
	li	s3, -1				# maximum unsigned value
	mv	s4, s1				# initialize countdown
loop_seeds_2:
	ld	s5, 0(s2)
	ld	s6, 8(s2)
loop_locations:
	mv	a0, s5
	add	a1, s0, 8
	call	get_location
	bgtu	a0, s3, no_new_min_2
	mv	s3, a0
no_new_min_2:
	inc	s5
	dec	s6
	bnez	s6, loop_locations
	addi	s2, s2, 16
	addi	s4, s4, -2	
	bnez	s4, loop_seeds_2

        mv      a0, s3
        call    print_int

	
end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall


	# a0: seed number
	# a1: pointer to array of map pointers
get_location:
	addi	sp, sp, -24
	sd	ra, 0(sp)
	sd	s0, 8(sp)
	sd	s1, 16(sp)

	li	s0, 7
	mv	s1, a1
get_location_loop:
	ld	a1, 0(s1)
	call	find_dest_number
	addi	s1, s1, 8
	dec	s0
	bnez	s0, get_location_loop

	ld	ra, 0(sp)
	ld	s0, 8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24
	ret


	# a0: source number
	# a1: map pointer
find_dest_number:
	ld	t0, SOURCE_START(a1)		# load source start value
	bltz	t0, find_dest_end		# source number not in the map, dest number is source number
	bgt	t0, a0, find_dest_end		# source number not in the map, dest number is source number
	ld	t1, LENGTH(a1)
	add	t2, t0, t1			# upper bound of source value
	bge	a0, t2, find_dest_next		# source number not withing current range
	sub	t2, a0, t0			# diff between source number and source range start
	ld	t3, DEST_START(a1)		# load destination start value
	add	a0, t2, t3			# compute destination number
find_dest_end:
	ret
find_dest_next:
	addi	a1, a1, 24
	j	find_dest_number


	# a0: input pointer
read_all_numbers:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	clr	s0				# initialize counter
	call	skip_to_digit

loop_read_numbers:
	call	parse_integer
	addi	sp, sp, -8			# allocate 64 bits on stack
	sd	a1, 0(sp)			# store number in stack
	inc	s0				# increment counter
	inc	a0				# advance text pointer (skip space or LF)
	mv	s1, a0				# save text pointer
	lb	a0, 0(s1)			# read next character
	call	is_digit			# check if next character is digit
	beqz	a0, loop_read_numbers_end	# exit loop if not
	mv	a0, s1				# restore text pointer
	j	loop_read_numbers
loop_read_numbers_end:

	# allocate heap space, 64 bits / number
	la	a0, arena
	li	a1, 8
	mul	a1, a1, s0
	addi	a1, a1, 24			# space for the terminator
	call	arena_alloc

	# move pointer to end of heap space
	li	t1, 8
	mul	t1, t1, s0
	add	t1, t1, a0

	# add terminator
	li	t0, -1
	sd	t0, SOURCE_START(t1)
	addi	t1, t1, -8

	mv	t0, s0				# initialize countdown

loop_copy_numbers:
	ld	t2, 0(sp)			# load number from top of stack
	sd	t2, 0(t1)			# copy to heap
	addi	sp, sp, 8			# free stack space
	addi	t1, t1, -8			
	dec	t0				# decrement countdown
	bnez	t0, loop_copy_numbers		# loop if countdown not null

	mv	a1, a0				# copy heap pointer
	mv	a0, s1				# copy text pointer
	mv	a2, s0				# copy counter
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24

	ret
	
	
compar:
	ld	t0, SOURCE_START(a0)
	ld	t1, SOURCE_START(a1)
	sub	a0, t0, t1
	ret
	

	.section .rodata

filename:
	.string "inputs/day05"
	#.string "inputs/day05-test"


	.section .bss
arena:	.zero	4096
