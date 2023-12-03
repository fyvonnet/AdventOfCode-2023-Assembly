	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	sub	sp, sp, a1			# allocate stack space for map
	dec	sp				# one more byte for null value at the end of map
	mv	s0, sp

	clr	s6				# initialize sum for part 1
	clr	s7				# initialize sum for part 2

	# measure line length
	clr	s1
	mv	t0, a0
	li	t2, ASCII_LF
loop_length:
	inc	s1
	lb	t1, 0(t0)
	inc	t0
	bne	t1, t2, loop_length

	# copy input to map
	mv	t0, s0
loop_copy:
	lb	t1, 0(a0)
	bne	t1, t2, not_lf
	li	t1, ASCII_DOT			# replace LF with dot
not_lf:
	sb	t1, 0(t0)
	inc	t0
	inc	a0
	blt	a0, s11, loop_copy
	sb	zero, 0(t0)			# terminate map with null value

	mv	s2, s0
	dec	s2

	# move to next symbol
loop_symbol:
	inc	s2
	lb	a0, 0(s2)
	li	t0, ASCII_DOT
	beq	a0, t0, loop_symbol		# dot found, move to next character
	beqz	a0, end				# null value found, move to end
	mv	s3, a0				# save the symbol
	call	is_digit
	bnez	a0, loop_symbol			# digit character found, move to next character

	
	sub	t2, s2, s0			# index
	rem	s4, t2, s1			# column (x)
	div	s5, t2, s1			# row (y)

	li	s10, 8				# 8 directions to explore
	la	s9, rel_coord			# pointer to relative coordinates
	clr	s11				# initialize numbers counter

loop_dirs:
	lb	t0, 0(s9)
	add	t1, s4, t0			# new column
	lb	t0, 1(s9)
	add	t2, s5, t0			# new row

	mul	t3, t2, s1
	add	t3, t3, t1
	add	s8, t3, s0
	lb	a0, 0(s8)
	call	is_digit
	beqz	a0, loop_dirs_next		# next if no digit found in this direction

	inc	s11				# one more number found

	# digit found, search beginning of number
loop_search_beg:
	dec	s8
	lb	a0, 0(s8)
	call	is_digit
	bnez	a0, loop_search_beg
	inc	s8

	mv	a0, s8
	call	parse_integer
	add	s6, s6, a1			# add number to sum

	addi	sp, sp, -4
	sw	a1, 0(sp)			# put number on stack

	# overwrite number with dots
	sub	t0, a0, s8			# number of digits in number
loop_overwrite:
	li	t1, ASCII_DOT
	sb	t1, 0(s8)
	inc	s8
	dec	t0
	bnez	t0, loop_overwrite
	
loop_dirs_next:
	addi	s9, s9, 2			# move to next relative coordinate
	dec	s10				# decrement directions countdown
	bnez	s10, loop_dirs			# loop if countdown not null

check_gear:
	# check if we got a gear
	li	t0, 2
	bne	s11, t0, skip_gear		# need to find exactly two numbers around the symbol
	li	t1, ASCII_ASTERISK
	bne	s3, t1, skip_gear		# symbol is not a gear

	# load numbers from the stack and add their product to the part 2 sum
	lw	t0, 0(sp)
	lw	t1, 4(sp)
	mul	t0, t0, t1
	add	s7, s7, t0

skip_gear:
	li	t0, 4
	mul	t0, t0, s11
	add	sp, sp, t0			# free stack space
	
	j	loop_symbol			# move on to next character
	
	
end:
	mv	a0, s6
	call	print_int

	mv	a0, s7
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	.section .rodata

	# relative coordinates for the eight search directions
rel_coord:
	.byte	-1, -1,   0, -1,   1, -1
	.byte   -1,  0,            1,  0
	.byte   -1,  1,   0,  1,   1,  1

filename:
	.string "inputs/day03"

