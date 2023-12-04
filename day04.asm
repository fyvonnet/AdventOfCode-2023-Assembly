	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	mv	s0, a0
	clr	s2				# initialize sum

loop_input:
	addi	s0, s0, 9 			# skip "Card XXX:"
	##addi	s0, s0, 7 			# skip "Card XXX:"

	clr	s1				# initialize numbers counter
	# skip to next digit
loop_skip_to_digit:
	inc	s0
	lb	a0, 0(s0)
	call	is_digit
	beqz	a0, loop_skip_to_digit

	mv	a0, s0
	call	parse_integer
	mv	s0, a0
	inc	s1
	addi	sp, sp, -1
	sb	a1, 0(sp)

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
	clr	t4				# initialize score
loop_search_dup:
	lb	t2, 0(t1)
	lb	t3, 1(t1)
	bne	t2, t3, not_equal
	beqz	t4, null_score
	slli	t4, t4, 1
	j	score_next
null_score:
	li	t4, 1
score_next:
not_equal:
	inc	t1
	dec	t0
	bnez	t0, loop_search_dup		# loop if countdown not null

	add	s2, s2, t4
	inc	s0				# skip to next line

	add	sp, sp, s1			# free stack space

	blt	s0, s11, loop_input

	mv	a0, s2
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
	#.string "inputs/day04-test"
	.string "inputs/day04"

