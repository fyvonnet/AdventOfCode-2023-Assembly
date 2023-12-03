	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	sub	sp, sp, a1			# allocate stack space for map
	mv	s0, sp

	clr	s6				# initialize sum

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
	mv	s11, t0				# copy pointer to end of map

	mv	s2, s0
	dec	s2
	li	s3, ASCII_DOT

	# move to next symbol
loop_symbol:
	inc	s2
	bge	s2, s11, end	
	lb	a0, 0(s2)
	beq	a0, s3, loop_symbol		# dot found, move to next character
	call	is_digit
	bnez	a0, loop_symbol			# digit character found, move to next character
	
	sub	t2, s2, s0			# index
	rem	s4, t2, s1			# column (x)
	div	s5, t2, s1			# row (y)

	li	s10, 8				# 8 directions to explore
	la	s9, rel_coord			# pointer to relative coordinates

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

	# overwrite number with dots
	sub	t0, a0, s8			# number of digits in number
loop_overwrite:
	sb	s3, 0(s8)
	inc	s8
	dec	t0
	bnez	t0, loop_overwrite
	
loop_dirs_next:
	addi	s9, s9, 2			# move to next relative coordinate
	dec	s10				# decrement directions countdown
	bnez	s10, loop_dirs			# loop if countdown not null
	
	j	loop_symbol			# move on to next character
	
	
end:
	mv	a0, s6
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

