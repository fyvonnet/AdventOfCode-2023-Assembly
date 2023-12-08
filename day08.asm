	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	# add terminator
	dec	sp
	li	t0, -1
	sb	t0, 0(sp)

	# save position of last element of the directions vector
	addi	t6, sp, -1
	
	li	t2, ASCII_CAP_L
	li	t3, ASCII_LF
loop_read_dirs:
	lb	t0, 0(a0)
	beq	t0, t3, loop_read_dirs_end
	li	t1, 0					# 0 for left
	beq	t0, t2, left
	li	t1, 1					# 1 for right
left:
	dec	sp
	sb	t1, 0(sp)
	inc	a0
	j	loop_read_dirs
loop_read_dirs_end:
	addi	a0, a0, 2				# skip LFs 

	mv	s0, sp					# copy directions vector address

	# invert directions order
	mv	t0, s0
loop_invert:
	lb	t1, 0(t0)
	lb	t5, 0(t6)
	sb	t1, 0(t6)
	sb	t5, 0(t0)
	inc	t0
	dec	t6
	blt	t0, t6, loop_invert

	clr	s2					# clear nodes counter
loop_read_nodes:
	inc	s2					# increment counter
	addi	sp, sp, -12
	call	read_letters
	sw	a1, 0(sp)
	addi	a0, a0, 4				# skip " = ("
	call	read_letters
	sw	a1, 4(sp)
	addi	a0, a0, 2				# skip ", "
	call	read_letters
	sw	a1, 8(sp)
	addi	a0, a0, 2				# skip ")\n"
	blt	a0, s11, loop_read_nodes
	mv	s1, sp					# copy nodes vector pointer


	mv	a0, s1
	mv	a1, s2
	li	a2, 12
	la	a3, compar
	call	quicksort

	la	a0, zzz
	call	read_letters
	mv	s11, a1

	mv	s3, s0					# pointer to directions vector
	mv	s4, s1					# pointer to AAA node (first node)
	clr	s5					# clear the steps counter

search_loop:
	inc	s5					# increment steps counter
	lw	t0, 0(s4)				# load node number
	addi	s4, s4, 4				# point to destinations
	lb	t0, 0(s3)				# load direction
	bgez	t0, dir_ok				# end of vector reached if direction negative
	mv	s3, s0					# move back to beginning of vector
	lb	t0, 0(s3)				# load direction
dir_ok:
	slli	t0, t0, 2
	add	s4, s4, t0				# point to the next destination number
	lw	a2, 0(s4)				# load next destination number
	beq	a2, s11, search_loop_end		# ZZZ reached
	
	# get next destination	address
	mv	a0, s1
	mv	a1, s2
	call	binsearch

	mv	s4, a0
	inc	s3					# point to next direction
	j	search_loop
search_loop_end:

	mv	a0, s5
	call 	print_int

end:

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall


	# a0: base pointer
	# a1: elements count
	# a2: element searched
binsearch:
	li	t0, 0					# index of first element
	addi	t2, a1, -1				# index of last element
	li	t3, 12					# length of node
binsearch_loop:
	add	t1, t0, t2
	srli	t1, t1, 1				# middle index
	mul	t5, t1, t3
	add	t5, t5, a0				# pointer to middle element
	lw	t6, 0(t5)				# load middle element
	blt	t6, a2, binsearch_right
	bgt	t6, a2, binsearch_left
	mv	a0, t5
	ret
binsearch_right:
	addi	t0, t1, 1
	j	binsearch_loop
binsearch_left:
	addi	t2, t1, -1
	j	binsearch_loop
	

read_letters:
	clr	a1
	.rept 3
	slli	a1, a1, 8
	lb	t0, 0(a0)
	or	a1, a1, t0
	inc	a0
	.endr
	ret

compar:
	lw	a0, 0(a0)
	lw	a1, 0(a1)
	sub	a0, a0, a1
	ret

	.section .rodata

filename:
	.string "inputs/day08"

zzz:
	.string	"ZZZ"

