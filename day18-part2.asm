	.include "macros.inc"
	.include "constants.inc"


	.section .rodata
	.type	input, @object
input:	.incbin	"inputs/day18"
	.byte	0
	.size	input, .-input
	.type	moves, @object
moves:	.byte	 1,  0	# right
	.byte	 0,  1	# down
	.byte	-1,  0	# left
	.byte	 0, -1	# up
	.size	moves, .-moves


	.text


	.global	_start
	.type	_start, @function
_start:
	la	s0, input
	clr	s2				# shoelace function accumulator
	clr	s5				# coordinate X
	clr 	s6				# coordinate Y
	clr	s7				# counter
	clr	s8				# total dig distance

	addi	sp, sp, -16
	sd	zero, 0(sp)
	sd	zero, 8(sp)
	
main_loop:
	inc	s7

	# skip to hexadecimal code
	li	t0, '#'
loop_skip:
	lb	t1, (s0)
	beq	t1, t0, loop_skip_end
	inc	s0
	j	loop_skip
loop_skip_end:
	inc	s0

	# read the distance
	clr	s1
	li	t0, '9'
	li	t1, 5
	li	t3, 16
loop_read_dist:
	lb	t2, (s0)
	bgt	t2, t0, read_letter
	addi	t2, t2, -'0'
	j	read_next
read_letter:
	addi	t2, t2, -'a'
	addi	t2, t2, 10
read_next:
	mul	s1, s1, t3
	add	s1, s1, t2
	dec	t1
	inc	s0
	bnez	t1, loop_read_dist

	# addi distance to total
	add	s8, s8, s1

	# read movement
	lb	t0, (s0)
	addi	t0, t0, -'0'
	slli	t0, t0, 1
	la	t1, moves
	add	t0, t0, t1
	lb	t1, 0(t0)
	mul	t1, t1, s1
	add	s3, s5, t1
	lb	t1, 1(t0)
	mul	t1, t1, s1
	add	s4, s6, t1

	mul	t0, s4, s5
	mul	t1, s3, s6
	sub	t0, t0, t1
	add	s2, s2, t0

	mv	s5, s3
	mv	s6, s4

	addi	s0, s0, 3			# skip "x)\n"

	lb	t0, (s0)
	bnez	t0, main_loop
	

	bgez	s2, not_neg
	neg	s2, s2
not_neg:
	srli	s2, s2, 1
	
	# Pick's theorem: i = A - b/2 +1
	srli	s8, s8, 1
	add	a0, s2, s8
	inc	a0

	call	print_dec
	call	print_ln

	j	exit
	.size	_start, .-_start

