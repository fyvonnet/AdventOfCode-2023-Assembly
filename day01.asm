	.global _start

	.include "macros.inc"
	.include "constants.inc"

	.section .text

_start:
	# sort letter-digits for binary search
	la	a0, ldigits
	li	a1, 9				# 9 elements
	li	a2, 11				# elements are 11 bytes long
	la	a3, compar
	call	quicksort

	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	addi	sp, sp, -8
	sd	a0, 0(sp)			# save input pointer

	# part 1
	li	s4, 0				# skip letter digits
	call	solve

	ld	a0, 0(sp)			# restore input pointer
	addi	sp, sp, 8

	# part 2
	li	s4, 1				# don't skip letter digits
	call	solve

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall


solve:
	addi	sp, sp, -8
	sd	ra, 0(sp)

	clr	s0				# initialize sum

loop_input:
	# read first digit fromp the beginning of the line
	li	a1, 1				# move forward
	call	read_next_digit
	li	t0, 10
	mul	s1, t0, a1

	# move pointer to the end of line
	li	t1, ASCII_LF
	dec	a0
loop:
	inc	a0
	lb	t0, 0(a0)
	bne	t0, t1, loop

	addi	s3, a0, 1			# save pointer to begining of next line
	addi	a0, a0, -1			# move input pointer to last character of the line
	
	# read second digit from  the end of the line
	li	a1, -1				# move backward
	call    read_next_digit
	add	s1, s1, a1			# add second digit to the calibration value
	add	s0, s0, s1			# add the calibration value to the sum
	mv	a0, s3				# move to next line
	blt	a0, s11, loop_input		# loop of EOF not reached

	mv	a0, s0
	call	print_int

	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret

read_next_digit:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	
	mv	s2, a1
	sub	t0, zero, a1
	add	s1, a0, t0			# pre-move pointer in reverse direction
rnd_loop:
	add	s1, s1, s2			# move input pointer
	lb	s0, 0(s1)			# read character
	mv	a0, s0
	call	is_digit			# check if digit
	beqz	s4, skip_ldigit			# skip search for letter digit on part 1
	beqz	a0, rnd_ldigit			# not a digit, attemps reading as a letter-digit
skip_ldigit:
	beqz	a0, rnd_loop			# not a digit, keep on searching
	li	t0, ASCII_ZERO
	sub	a1, s0, t0			# turn ASCII code to actual value
rnd_end:
	add	s1, s1, s2			# move input pointer
	mv	a0, s1				# copy pointer back to a0

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 32
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
	beqz	a0, rnd_loop			# not validated, keep on searching
	lb	a1, 2(s6)			# value of the ldigit
	j	rnd_end
search_right:
	addi	t0, t1, 1
	j	rnd_ldigit_loop			# L = m + 1
search_left:
	addi	t2, t1, -1			# R = m - 1
	j	rnd_ldigit_loop
	

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
