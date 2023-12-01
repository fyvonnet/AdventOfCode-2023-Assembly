	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	# sort letter-digits for binary search
	la	a0, ldigits
	li	a1, 9
	li	a2, 11
	la	a3, compar
	call	quicksort

	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	clr	s0

loop_input:
	call	read_next_digit
	li	t0, 10
	mul	s1, t0, a1
	mv	s2, a1				# first digit is also last digit for now
loop_line:
	call    read_next_digit
	li	t0, -1
	beq	a1, t0, loop_line_end		# last digit is -1, EOL reached
	mv	s2, a1				# save last read digit
	j	loop_line			
loop_line_end:
	add	s1, s1, s2			# add last digit read before -1 to the calibration value
stop_here:
	add	s0, s0, s1			# add the calibration value to the sum
	blt	a0, s11, loop_input		# loop of EOF not reached

	mv	a0, s0
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

read_next_digit:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	
	addi	s1, a0, -1
rnd_loop:
	inc	s1
	lb	s0, 0(s1)			# read character
	li	t0, ASCII_LF
	beq	s0, t0, rnd_eol			# EOL reached
	mv	a0, s0
	call	is_digit			# check if digit
	beqz	a0, rnd_ldigit			# not a digit, attemps reading as a letter-digit
	li	t0, ASCII_ZERO
	sub	a1, s0, t0			# turn ASCII code to actual value
	j	rnd_end
rnd_eol:
	li	a1, -1				# eol reached, no new digit
rnd_end:
	inc	s1				# increase input pointer
	mv	a0, s1				# copy pointer back to a0
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24
	ret
rnd_ldigit:
	li	t0, 0				# L
	li	t2, 8				# R
	la	t3, ldigits			# address of the ldigit vector
	li	t4, 11				# length of a ldigit vector element
	lh	t5, 0(s1)			# load the candidate ldigit
rnd_ldigit_loop:
	bgt	t0, t2, rnd_loop		# not a letter digit
	add	t1, t0, t2			# m = L + R
	srli	t1, t1, 1			# m = m / 2
	mul	s6, t1, t4			# m offset
	add	s6, s6, t3			# m address
	lh	s7, 0(s6)			# m value
	blt	s7, t5, search_right
	bgt	s7, t5, search_left
	# corresponding 16-bits value found
	# validate the whole string
	mv	a0, s1				# pointer to cadidate string
	ld	a1, 3(s6)			# pointer to model string
	call	validate
	#li	a1, -1
	beqz	a0, rnd_loop			# not validated, keep on searching
	lb	a1, 2(s6)			# value of the ldigit
	j	rnd_end
search_right:
	addi	t0, t1, 1
	j	rnd_ldigit_loop
search_left:
	addi	t2, t1, -1
	j	rnd_ldigit_loop
	
is_digit:
	li	t0, 0
	li	t1, ASCII_ZERO
	blt	a0, t1, is_digit_end
	li	t1, ASCII_NINE
	bgt	a0, t1, is_digit_end
	li	t0, 1
is_digit_end:
	mv	a0, t0
	ret

	# a0: candidate string
	# a1: model string
validate:
	li	t2, 0
	li	t3, ASCII_LF
validate_loop:
	lb	t1, 0(a1)
	beqz	t1, validate_ok			# end of model string reach, str valid
	lb	t0, 0(a0)
	beq	t0, t3, validate_nok		# eol reached, str not valid
	bne	t0, t1, validate_nok		# characters different, str not valid
	inc	a0
	inc	a1
	j	validate_loop
validate_ok:
	li	a0, 1
	ret
validate_nok:
	li	a0, 0
	ret

compar:
	lh	t0, 0(a0)
	lh	t1, 0(a1)
	sub	a0, t0, t1
	ret

	.section .data

ldigits:

	.ascii	"on"	# 16-bits value for the first two letters
	.byte	1	# corresponding value
	.quad	one	# pointer to model string

	.ascii	"tw"
	.byte	2
	.quad	two

	.ascii	"th"
	.byte	3
	.quad	three

	.ascii	"fo"
	.byte	4
	.quad	four

	.ascii 	"fi"
	.byte	5
	.quad	five

	.ascii	"si"
	.byte	6
	.quad	six

	.ascii	"se"
	.byte	7
	.quad	seven

	.ascii	"ei"
	.byte	8
	.quad	eight

	.ascii	"ni"
	.byte	9
	.quad	nine

	.section .rodata

filename:
	.string "inputs/day01"

one:	.string "one"
two:	.string "two"
three:	.string "three"
four:	.string "four"
five:	.string "five"
six:	.string "six"
seven:	.string "seven"
eight:	.string "eight"
nine:	.string "nine"
