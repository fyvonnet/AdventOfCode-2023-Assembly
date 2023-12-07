	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1

	clr	s1				# initialize hands counter
loop_read_hands:
	inc	s1
	addi	sp, sp, -10			# allocate hand space in the stack
	mv	a1, sp
	call	decode_hand
	blt	a0, s11, loop_read_hands

	# sort hands
	mv	a0, sp
	mv	a1, s1
	li	a2, 10
	la	a3, compar_hands
	call	quicksort
	
	li	s2, 1				# initialize rank
	clr	s3				# initialize total winnings
loop_winnings:
	lh	t0, 8(sp)			# load bid
	mul	t0, t0, s2			# multiply bid by rank
	add	s3, s3, t0			# add winning to sum
	addi	sp, sp, 10			# move hands pointer
	inc	s2				# increment rank
	dec	s1				# decrement counter
	bnez	s1, loop_winnings

	mv	a0, s3
	call	print_int
	
	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	# a0: input pointer
	# a1: storage pointer
decode_hand:
	add	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	sh	zero, 0(s1)			# start with 16 bits of zeros

	# load cards in the last 5 bytes
	addi	a1, s1, 3
	call	read_cards

	# store the hand strength in the 3rd byte
	addi	a0, s1, 3
	call	get_hand_strength
	sb	a0, 2(s1)

	# invert bytes order
	mv	t0, s1
	addi	t1, s1, 7
	.rept	4
	lb	t2, 0(t0)
	lb	t3, 0(t1)
	sb	t2, 0(t1)
	sb	t3, 0(t0)
	inc	t0
	dec	t1
	.endr

	addi	a0, s0, 6			# skip to bid
	call	parse_integer
	sh	a1, 8(s1)			# store bid
	inc	a0				# skip lf

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	add	sp, sp, 24
	ret
	


	# a0: cards vector pointer
get_hand_strength:
	add	sp, sp, -16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	mv	s0, a0
	addi	sp, sp, -13
	sd	zero, 0(sp)
	sw	zero, 8(sp)
	sb	zero, 12(sp)
	li	t0, 5
loop_count_cards:
	lb	t1, 0(s0)			# load card strength
	add	t1, t1, sp			# compute counter address
	lb	t2, 0(t1)			# load count
	inc	t2				# increment count
	sb	t2, 0(t1)			# store count
	inc	s0
	dec	t0
	bnez	t0, loop_count_cards

	lb	s0, 0(sp)			# get jokers count
	sb	zero, 0(sp)			# remove jokers from the counts

	# sort count in reverse to generate a 64-bits value
	mv	a0, sp
	li	a1, 13
	li	a2, 1
	la	a3, compar
	call	quicksort

	lb	t0, 0(sp)			# load highest card count
	add	t0, t0, s0			# add jokers
	sb	t0, 0(sp)			# store new count

	# search hand 64-bits value in the hand types vector
	ld	t0, 0(sp)
	la	t1, hand_types
	mv	t3, t1
loop_search_type:
	ld	t2, 0(t1)
	beq	t0, t2, loop_search_type_end
	addi	t1, t1, 8
	j	loop_search_type
loop_search_type_end:
	sub	t1, t1, t3
	srli	a0, t1, 3

	addi	sp, sp, 13

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	add	sp, sp, 16
	ret
	


	# a0: input pointer
	# a1: destination pointer
read_cards:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	li	s2, 5
loop_read_cards:
	lb	a0, 0(s0)
	call	get_card_num
	sb	a0, 0(s1)
	inc	s0
	inc	s1
	dec	s2
	bnez	s2, loop_read_cards

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 32
	ret


	# a0: ascii code of card
	# return: card strength
get_card_num:
	la	t0, cards
	mv	t2, t0
loop_get_card_num:
	lb	t1, 0(t0)
	beq	t1, a0, get_card_num_end
	inc	t0
	j	loop_get_card_num
get_card_num_end:
	sub	a0, t0, t2
	ret

compar:
	lb	a0, 0(a0)
	lb	a1, 0(a1)
	sub	a0, a1, a0
	ret

compar_hands:
	ld	a0, 0(a0)
	ld	a1, 0(a1)
	sub	a0, a0, a1
	ret

	.section .rodata

filename:
	.string "inputs/day07"

cards:
	.ascii	"J23456789TQKA"

hand_types:
	.quad	0x0000000101010101			# high card
	.quad	0x0000000001010102			# one pari
	.quad	0x0000000000010202			# two pairs
	.quad	0x0000000000010103			# three of a kind
	.quad	0x0000000000000203			# full house
	.quad	0x0000000000000104			# four of a kind
	.quad	0x0000000000000005			# five of a kind
