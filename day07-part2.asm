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
	addi	sp, sp, -6			# allocate hand space in the stack
	#mv	a1, sp
	#call	decode_hand
	mv	s0, a0
	call	read_cards
	sw	a0, 0(sp)
	add	a0, s0, 6			# skip to bid
	call	parse_integer
	sh	a1, 4(sp)
	inc	a0				# skip LF
end:
	blt	a0, s11, loop_read_hands


	# sort hands
	mv	a0, sp
	mv	a1, s1
	li	a2, 6
	la	a3, compar_hands
	call	quicksort
	
	li	s2, 1				# initialize rank
	clr	s3				# initialize total winnings
loop_winnings:
	lh	t0, 4(sp)			# load bid
	mul	t0, t0, s2			# multiply bid by rank
	add	s3, s3, t0			# add winning to sum
	addi	sp, sp, 6			# move hands pointer
	inc	s2				# increment rank
	dec	s1				# decrement counter
	bnez	s1, loop_winnings

	mv	a0, s3
	call	print_int
	
	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall


	# a0: cards vector pointer
hand_strength:
	add	sp, sp, -16
	sd	ra,  0(sp)
	sd	s0,  8(sp)

	# allocate and zero the counters
	addi	sp, sp, -13
	sd	zero, 0(sp)
	sw	zero, 8(sp)
	sb	zero, 12(sp)

	# count the cards
	.rept 5
	andi	t0, a0, 0b1111			# get card value
	add	t0, t0, sp			# counter address
	lb	t1, 0(t0)			# load counter
	inc	t1				# increment counter
	sb	t1, 0(t0)			# save counter
	srli	a0, a0, 4			# shift cards code
	.endr

	lb	s0, 0(sp)			# load jokers count
	sb	zero, 0(sp)			# zero jokers count

	# sort counts
	mv	a0, sp
	li	a1, 13
	li	a2, 1
	la	a3, compar_counts
	call	quicksort

	addi	sp, sp, 8 			# skip to the 5 last counts

	lb	t0, 4(sp)			# load highest cards count
	add	t0, t0, s0			# add jokers
	sb	t0, 4(sp)			# save highest cards count
	
	clr	t0				# initialize hand type code

	# fill hand type code
	.rept 5
	slli	t0, t0, 4
	lb	t1, 0(sp)
	or	t0, t0, t1
	addi	sp, sp, 1 
	.endr

	la	t1, hand_types
	mv	t2, t1
loop_search_type:
	lw	t3, 0(t1)
	beq	t3, t0, loop_search_type_end
	addi	t1, t1, 4
	j	loop_search_type
loop_search_type_end:
	sub	t1, t1, t2
	srli	a0, t1, 2

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	add	sp, sp, 16
	ret
	


	# a0: input pointer
	# a1: destination pointer
	# return cards code
read_cards:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	clr	s1				# initialize card code
	.rept 5
	slli	s1, s1, 4			# move code 4 bits to the left
	lb	a0, 0(s0)			# load card character from the input
	call	get_card_num			# get card index
	or	s1, s1, a0			# add card index to the code
	inc	s0				# increment input pointer
	.endr
	
	mv	a0, s1
	call	hand_strength
	slli	a0, a0, 20			# shift hand strength left 5 * 4 bits
	or	a0, a0, s1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24
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

compar_counts:
	lb	a0, 0(a0)
	lb	a1, 0(a1)
	sub	a0, a0, a1
	ret

compar_hands:
	lw	a0, 0(a0)
	lw	a1, 0(a1)
	sub	a0, a0, a1
	ret

	.section .rodata

filename:
	.string "inputs/day07"
	#.string "inputs/day07-test"

cards:
	.ascii	"J23456789TQKA"

hand_types:
	.word	0x000011111			# high card
	.word	0x000001112			# one pari
	.word	0x000000122			# two pairs
	.word	0x000000113			# three of a kind
	.word	0x000000023			# full house
	.word	0x000000014			# four of a kind
	.word	0x000000005			# five of a kind
