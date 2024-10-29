	.include "constants.inc"
	.include "macros.inc"


	.set	DIGITS,		 0
	.set	DIGITS_INV, 	 8
	.set	INPUT_LINE, 	16
	.set	INPUT_LINE_INV, 24
	.set	DIGIT, 		32
	.set	DIGIT_INV,	40
	.set	POSITION, 	48
	.set	POSITION_INV, 	56


	.section .rodata


digits_str:
	.string	"zero", "one", "two", "three",	"four"
	.string	"five", "six", "seven", "eight", "nine"
	.set DIGIT_STR_LEN, .-digits_str

filename:
	.string	"inputs/day01"
	

	.section .text
	.balign	8


	.globl	_start
	.type	_start, @function
_start:
	clr 	s3
	clr 	s4

	la	a0, filename
	call	map_input_file
	mv	s10, a0
	add	s11, a0, a1

	dec	sp, 64
	mv	s0, sp

	# allocate stack space for the reverse input line
	dec	sp
	sb	zero, (sp)
	mv	s2, sp				# point at the end of the string
	dec	sp, 63

	la	t0, digits_str
	sd	t0, DIGITS(s0)

	dec	sp, DIGIT_STR_LEN
	sd	sp, DIGITS_INV(s0)
	mv	t1, sp

	dec	sp, 10
	mv	s1, sp

	li	t2, 10
	mv	t3, s1
	mv	t4, t0
loop_revert_copy:
	sub	t6, t4, t0
	sb	t6, (t3)
	inc	t3
	dec	sp
	sb	zero, (sp)
loop_seek_null:
	lb	t5, (t4)
	beqz	t5, loop_seek_null_end
	dec	sp
	sb	t5, (sp)
	inc	t4
	j	loop_seek_null
loop_seek_null_end:
	inc	t4
	nop

	# copy the reversed digit string from the stack to the array
loop_copy_back:
	lb	t5, (sp)
	sb	t5, (t1)
	inc	sp
	inc	t1
	bnez	t5, loop_copy_back

	dec	t2
	bnez	t2, loop_revert_copy


loop:

	sd	s10, INPUT_LINE(s0)
	
	mv	t0, s2
	li	t1, '\n'
loop_copy_input_line:
	dec	t0
	lb	t2, (s10)
	beq	t2, t1, loop_copy_input_line_end
	sb	t2, (t0)
	inc	s10
	j	loop_copy_input_line
	
loop_copy_input_line_end:
	inc	s10
	inc	t0
	sd	t0, INPUT_LINE_INV(s0)
	
	mv	a0, s0
	call	search_digit
	addi	a0, s0, 8
	call	search_digit
	mv	a0, s0
	call	compute_value
	add	s3, s3, a0
	
	mv	a0, s0
	mv	a1, s1
	call	search_string
	addi	a0, s0, 8
	mv	a1, s1
	call	search_string
	mv	a0, s0
	call	compute_value
	add	s4, s4, a0
	
	blt	s10, s11, loop
	
	mv	a0, s3
	call	print_int
	mv	a0, s4
	call	print_int
	
	la	a0, EXIT_SUCCESS
	la	a7, SYS_EXIT
	ecall
.size	_start, .-_start



	.type	search_digit, @function
search_digit:
	ld	t6, INPUT_LINE(a0)
	mv	t0, t6
	li	t1, '0'
	li	t2, '9'
search_digit_loop:
	lb	t3, (t0)
	blt	t3, t1, search_digit_loop_next
	bgt	t3, t2, search_digit_loop_next
	sub	t3, t3, t1
	sd	t3, DIGIT(a0)
	sub	t0, t0, t6
	sd	t0, POSITION(a0)
	ret
search_digit_loop_next:
	inc	t0
	j	search_digit_loop
	.size	search_digit, .-search_digit


	# a0: data
	# a1: offsets
	.type	search_string, @function
search_string:
	dec	sp, 64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0				# data
	mv	s1, a1				# offsets
	li	s2, 10				# countdown
	ld	s3, DIGITS(s0)			# letter digits
	clr	s4				# digit number
	ld	s5, INPUT_LINE(s0)		# input line
	mv	s6, s1				# offsets pointer

loop_search_string:
	lb	t0, (s5)
	li	t1, 'a'
	blt	t0, t1, search_string_ret	# abandon when digit found
	lb	t0, (s1)
	add	a0, s3, t0			# digit string
	mv	a1, s5				# input line

	call	strings_equal
	bgtz	a0, search_string_succ

	# no letter digit matches, move to the next input's character
	dec	s2
	beqz	s2, search_string_adv

	# move to the next digit
	inc	s1
	inc	s4
	j	loop_search_string

search_string_adv:
	inc	s5
	dec	s1, 9
	li	s2, 10
	clr	s4
	j	loop_search_string

search_string_succ:
	sd	s4, DIGIT(s0)

search_string_ret:

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	inc	sp, 64
	ret
	.size	search_string, .-search_string


	# a0: substring
	# a1: string
	.type	strings_equal, @function
strings_equal:
	lb	t0, (a0)
	beqz	t0, strings_equal_succ
	lb	t1, (a1)
	bne	t0, t1, strings_equal_fail
	inc	a0
	inc	a1
	j	strings_equal
strings_equal_succ:
	la	a0, 1
	ret
strings_equal_fail:
	clr	a0
	ret
	.size	strings_equal, .-strings_equal


	.type 	compute_value, @function
compute_value:
	ld	t0, DIGIT(a0)
	ld	t1, DIGIT_INV(a0)
	li	t2, 10
	mul	t0, t0, t2
	add	a0, t0, t1
	ret
	.size	compute_value, .-compute_value
	
