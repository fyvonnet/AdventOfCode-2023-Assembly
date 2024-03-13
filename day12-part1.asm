	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1

	clr	s10

loop:
	mv	a0, s0
	call	decode_springs
	mv	s1, a0
	lb	t0, 0(a0)
	add	s0, s0, t0			# move to end of springs conditions
	inc	s0				# skip space
	mv	a0, s0
	call	read_groups
	mv	s2, a1

	# 0(s1)	 : total
	# 1(s1)  : unknown
	# 2(s1)  : hashes
	# s1 + 3 : spring conditions

	# 0(s2)	 : groups counter
	# 1(s2)  : sum of groups / total needed
	# s2 + 2 : groups

	# total missing: sum of groups - hashes
	lb	t0, 1(s2)
	lb	t1, 2(s1)
	sub	s4, t0, t1
	
	# generate as much bits as unknown conditions
	li	s3, 1
	lb	t0, 1(s1)
	sll	s3, s3, t0

	lb	s5, 0(s1)
	slli	t0, s5, 3
	sub	sp, sp, t0
	
loop_masks_copy:
	mv	t0, s5				# countdown
	addi	t1, s1, 3			# condition pointer
	mv	t2, sp				# copy pointer
loop_copy:
	lb	t3, 0(t1)
	sd	t3, 0(t2)
	inc	t1
	addi	t2, t2, 8
	dec	t0
	bnez	t0, loop_copy
	
loop_masks:
	dec	s3	
	bltz	s3, loop_masks_end
	mv	a0, s3
	call	count_bits
	bne	a0, s4, loop_masks

	
	mv	t3, s3				# replacement mask
	mv	t0, sp				# conditions pointer
	lb	t6, 1(s1)			# countdown (unknowns count)
loop_replace:
	ld	t1, 0(t0)			# load current condition
	bgez	t1, skip_replace		# skip if not unknown
	andi	t2, t3, 1			# get last bit of mask
	sd	t2, 0(t0)			# store bit as replacement condition
	srli	t3, t3, 1			# shift mask
	dec	t6
	beqz	t6, loop_replace_end
skip_replace:
	addi	t0, t0, 8
	j	loop_replace
loop_replace_end:

	mv	a0, sp
	lb	a1, 0(s1)
	mv	a2, s2
	call	validate_groups
	beqz	a0, skip_point
	inc	s10
skip_point:
	j	loop_masks_copy
loop_masks_end:
	mv	a0, s0
	call	skip_to_next_line
	mv	s0, a0
	blt	s0, s11, loop

	mv	a0, s10
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

count_bits:
	clr	t0
loop_count_bits:
	andi	t1, a0, 1
	add	t0, t0, t1
	srli	a0, a0, 1
	bnez	a0, loop_count_bits
	mv	a0, t0
	ret

	# a0: conditions vector
	# a1: length
	# a2: groups comparison
validate_groups:
	mv	t6, sp
	clr	t0				# hash count
	clr	t1				# groups count
loop_vg:
	ld	t3, 0(a0)
	beqz	t3, vg_dot
	inc	t0
	j	loop_vg_next
vg_dot:
	beqz	t0, loop_vg_next
	inc	t1
	addi	sp, sp, -8
	sd	t0, 0(sp)
	clr	t0
loop_vg_next:
	addi	a0, a0, 8
	dec	a1
	bnez	a1, loop_vg
	
loop_vg_end:
	beqz	t0, validate_next
	inc	t1
	addi	sp, sp, -8
	sd	t0, 0(sp)

validate_next:
	addi	t0, t6, -8

	lb	t2, 0(a2)			# copy groups count from reference group vector
	bne	t1, t2, validate_fail		# fail if groups count don't match

	addi	a2, a2, 2			# point to start of reference lengths
validate_lengths:
	ld	t3, 0(t0)
	lb	t4, 0(a2)	
	bne	t3, t4, validate_fail
	addi	t0, t0, -8
	addi	a2, a2, 1
	dec	t1
	bnez	t1, validate_lengths
	mv	sp, t6
	li	a0, 1
	ret
	
validate_fail:
	mv	sp, t6
	li	a0, 0
	ret

	
read_groups:
	addi	sp, sp, -48
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	
	clr	s0				# groups counter
	clr	s1				# sum of groups
loop_read_groups:
	call	parse_integer
	addi	sp, sp, -8
	sb	a1, 0(sp)
	inc	s0
	add	s1, s1, a1
	li	t0, ASCII_LF
	lb	t1, 0(a0)
	inc	a0
	bne	t0, t1, loop_read_groups
	mv	s2, a0

	addi	a0, s0, 2			# 2 counters
	call	malloc

	# store counters
	sb	s0, 0(a0)
	sb	s1, 1(a0)


	addi	t0, s0, 1
	add	t0, t0, a0
loop_copy_groups:
	lb	t1, 0(sp)
	sb	t1, 0(t0)
	addi	sp, sp, 8
	dec	t0
	dec	s0
	bnez	s0, loop_copy_groups

	mv	a1, a0
	add	a0, s2, 1

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 48
	ret
	

	# a0: string pointer
decode_springs:
	addi	sp, sp, -40
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)

	clr	s0				# total counter
	clr	s1				# unknown counter
	clr	s2				# hash counter
	li	a1, ASCII_SPACE
	li	a2, ASCII_HASH
	li	a3, ASCII_DOT
	li	a4, ASCII_QUESTION
	dec	a0
loop_decode_springs:
	inc	a0
	lb	t0, 0(a0)
	beq	t0, a1, loop_decode_springs_end
	addi	sp, sp, -8
	inc	s0
	beq	t0, a2, hash_found
	beq	t0, a3, dot_found
	beq	t0, a4, quest_found
loop_decode_springs_end:

	add	a0, s0, 3			# spring conditions + 3 counters
	call	malloc

	sb	s0, 0(a0)
	sb	s1, 1(a0)
	sb	s2, 2(a0)

	addi	t0, s0, 2
	add	t0, t0, a0
loop_copy_spring_conds:
	lb	t1, 0(sp)
	sb	t1, 0(t0)
	dec	t0
	addi	sp, sp, 8
	dec	s0
	bnez	s0, loop_copy_spring_conds

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	addi	sp, sp, 40
	ret


	
hash_found:
	inc	s2
	li	t0, 1
	sb	t0, 0(sp)
	j	loop_decode_springs

dot_found:
	sb	zero, 0(sp)
	j	loop_decode_springs

quest_found:
	li	t0, -1
	sb	t0, 0(sp)
	inc	s1
	j	loop_decode_springs



	
	


	.section .rodata

filename:
	.string "inputs/day12"

