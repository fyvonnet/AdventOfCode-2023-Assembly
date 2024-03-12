	.global	_start

	.include "macros.inc"
	.include "constants.inc"

	.set	IN_HASH, 0x696E
	.set	CHUNK_COUNT, 1024
	.set	CHUNK_SIZE, 32

	.section .text

_start:

	call	pool_init
	
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s1				# workflows counter

loop_input:
	addi	sp, sp, -80			# allocate space for hash and up to 4 rules
	call	hash
	sd	a1, 0(sp)
	inc	a0				# skip opening brace
	clr	s9				# rules counter
	add	s7, sp, 8			# rule pointer
loop_read_rules:
	inc	s9				# increment rules counter
	lb	t0, 1(a0)			# read comparison operator
	li	t1, ASCII_LT
	beq	t0, t1, rule_lt
	li	t1, ASCII_GT
	beq	t0, t1, rule_gt
	# not a comparison operator, last rule reached
	li	s8,  0
	j	rule_hash
rule_lt:
	li	s8, -1
	j	rule_oper
rule_gt:
	li	s8,  1
rule_oper:
	lb	t0, 0(a0)			# read rating letter
	li	t1, ASCII_X
	beq	t0, t1, rule_x
	li	t1, ASCII_M
	beq	t0, t1, rule_m
	li	t1, ASCII_A
	beq	t0, t1, rule_a
	li	t1, ASCII_S
	beq	t0, t1, rule_s
	# should not reach here
	li	a7, SYS_EXIT
	li	a1, 1
	ecall
rule_x:
	li	t0, 0
	j	rule_next
rule_m:
	li	t0, 1
	j	rule_next
rule_a:
	li	t0, 2
	j	rule_next
rule_s:
	li	t0, 3
rule_next:
	sb	t0, 0(s7)			# store x/m/a/s

	addi	a0, a0, 2

	call	parse_integer
	sh	a1, 2(s7)

	inc	a0				# skip ':'

rule_hash:
	call	hash
	sd	a1, 8(s7)

	sb	s8, 1(s7)			# store comparison operator
	inc	a0				# skip ',' or '}'

	addi	s7, s7, 16

	bnez	s8, loop_read_rules		# no comparison operator, no more rules

	inc	a0				# skip '\n'
	inc	s1				# increment workflows counter

	lb	t0, 0(a0)
	li	t1, ASCII_LF			# loop until empty line reached
	bne	t0, t1, loop_input

	mv	s10, a0

	mv	s0, sp				# save workflows vector base pointer

	mv	a0, s0
	mv	a1, s1
	li	a2, 80
	la	a3, compar
	call	quicksort

	mv	a0, s10				# restore input pointer
	inc	a0				# skip empty input line

	clr	s9				# clear sum

loop_parts:
	# Parse the X/M/A/S values and store them on the stack
	addi	sp, sp, -16
	mv	s10, sp
	.rept 4
	addi	a0, a0, 3
	call	parse_integer
	sw	a1, 0(s10)
	addi	s10, s10, 4
	.endr

	add	a0, a0, 2			# skip "}\n"
	mv	s10, a0				# save input pointer
	
	la	s2, first_hash			# start at IN worflow
loop_workflows:
	ld	t0, (s2)
	blez	t0, loop_workflows_end		# exit loop if result found

	# search worflow pointer
	mv	a0, s0
	mv	a1, s1
	li	a2, 80
	la	a3, compar
	mv	a4, s2
	call	binsearch

	addi	a0, a0, 8			# skip to rules

loop_rules:
	lb	s3, 0(a0)			# load x/m/a/s index
	slli	s3, s3, 2
	add	s3, s3, sp			# pointer to x/m/a/s value
	lw	s3, 0(s3)			# load x/m/a/s value
	lb	s4, 1(a0)			# load difference operator, or 0 for last (default) rule
	lh	s5, 2(a0)			# load comparison value
	addi	s2, a0, 8			# pointer to next hash
	bltz	s4, comp_lt
	bgtz	s4, comp_gt
	j	loop_workflows
comp_lt:
	blt	s3, s5, loop_workflows
	addi	a0, a0, 16
	j	loop_rules
comp_gt:
	bgt	s3, s5, loop_workflows
	addi	a0, a0, 16
	j	loop_rules

loop_workflows_end:
	ld	t0, (s2)
	beqz	t0, skip_add

	# add X/M/A/S values to final sum
	mv	t0, sp
	.rept	4
	lw	t1, 0(t0)
	add	s9, s9, t1
	addi	t0, t0, 4
	.endr
skip_add:


	# loop to next part in EOF to reached
	mv	a0, s10
	blt	a0, s11, loop_parts

	mv	a0, s9
	call	print_int


        ######     #    ######  #######     #####
        #     #   # #   #     #    #       #     #
        #     #  #   #  #     #    #             #
        ######  #     # ######     #        #####
        #       ####### #   #      #       #
        #       #     # #    #     #       #
        #       #     # #     #    #       #######

	# start at IN workflow with complete range of X/M/A/S values
	call	chunk_alloc
	la	t0, first_hash
	li	t1, 1
	li	t2, 4000
	sd	t0,  0(a0)
	sh	t1,  8(a0)
	sh	t2, 10(a0)
	sh	t1, 12(a0)
	sh	t2, 14(a0)
	sh	t1, 16(a0)
	sh	t2, 18(a0)
	sh	t1, 20(a0)
	sh	t2, 22(a0)
	sd	x0, 24(a0)

	mv	s2, a0					# queue head
	mv	s3, a0					# queue tail

	clr	s11

	addi	sp, sp, -16
loop_part2:
	beqz	s2, loop_part2_end			# end when queue is empty
	ld	s4,  0(s2)				# load workflow hash pointer

	# copy X/M/A/S ranges to the stack
	ld	t0,  8(s2)
	sd	t0,  0(sp)
	ld	t0, 16(s2)
	sd	t0,  8(sp)

	mv	a0, s2
	ld	s2, 24(s2)				# point head to next queue element
	call	chunk_free

	ld	t0, 0(s4)
	beqz	t0, loop_part2				# part rejected
	bgtz	t0, apply_rules

	# part accepted, add number of valid combinations to the sum
	mv	a0, sp
	call	combinations
	add	s11, s11, a0
	j	loop_part2

apply_rules:
	# load rules list pointer
	mv	a0, s0
	mv	a1, s1
	li	a2, 80
	la	a3, compar
	mv	a4, s4
	call	binsearch
	addi	s5, a0, 8				# skip to rules
	
loop_enqueue:
	call	chunk_alloc

	ld	t0,  0(sp)
	sd	t0,  8(a0)
	ld	t0,  8(sp)
	sd	t0, 16(a0)

	lb	t0,  1(s5)				# operator
	lb	t1,  0(s5)				# X/M/A/S index
	lh	t2,  2(s5)				# comparison value		
	addi	t3, s5, 8				# pointer to destination workflow hash
	addi	s5, s5, 16				# next rule

	slli	t1, t1, 2
	add	t4, t1, a0
	add	t4, t4, 8				# pointer to the range on the queue
	add	t5, t1, sp				# pointer to the range on the stack

	sd	t3,  0(a0)
	sd	x0, 24(a0)

	bltz	t0, enqueue_lt
	bgtz	t0, enqueue_gt
	j	enqueue_next				# last rule reached

enqueue_lt:
	addi	t6, t2, -1
	sh	t6, 2(t4)
	sh	t2, 0(t5)
	j	enqueue_next

enqueue_gt:
	addi	t6, t2, 1
	sh	t6, 0(t4)
	sh	t2, 2(t5)

enqueue_next:
	beqz	s2, empty_queue
	sd	a0, 24(s3)
	j	skip_empty_queue
empty_queue:
	mv	s2, a0
skip_empty_queue:
	mv	s3, a0
	bnez	t0, loop_enqueue			# no operator, last rule reached
	
	j	loop_part2
loop_part2_end:

	
	mv	a0, s11
	call	print_int
	
	
        ####### #     # ######
        #       ##    # #     #
        #       # #   # #     #
        #####   #  #  # #     #
        #       #   # # #     #
        #       #    ## #     #
        ####### #     # ######


	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

combinations:
	li	t0, 1
	.rept	4
	lh	t2, 2(a0)
	lh	t1, 0(a0)
	sub	t2, t2, t1
	inc	t2
	mul	t0, t0, t2
	addi	a0, a0, 4
	.endr
	mv	a0, t0
	ret

hash:
	lb	t1, 0(a0)
	li	t0, ASCII_CAP_A
	beq	t0, t1, hash_accepted
	li	t0, ASCII_CAP_R
	beq	t0, t1, hash_rejected
	li	t2, ASCII_A
	li	t3, ASCII_Z
	clr	a1
loop_hash:
	blt	t1, t2, hash_end
	bgt	t1, t3, hash_end
	slli	a1, a1, 8
	or	a1, a1, t1
	inc	a0
	lb	t1, 0(a0)
	j	loop_hash
hash_end:
	ret
hash_accepted:
	li	a1, -1
	inc	a0
	ret
hash_rejected:
	li	a1, 0
	inc	a0
	ret


compar:
	ld	t0, 0(a0)
	ld	t1, 0(a1)
	sub	a0, t0, t1
	ret

pool_init:
	la	t0, pool
	li	t1, CHUNK_COUNT
	addi	t2, t0, 8
	sd	t2, (t0)
loop_pool_init:
	mv	t0, t2
	addi	t2, t0, CHUNK_SIZE
	sd	t2, (t0)
	dec	t1
	bnez	t1, loop_pool_init
	ret

chunk_free:
	la	t0, pool
	ld	t1, (t0)
	sd	a0, (t0)
	sd	t1, (a0)
	ret

chunk_alloc:
	la	t0, pool
	ld	a0, (t0)
	ld	t1, (a0)
	sd	t1, (t0)
	ret
	

	.section .bss
	.align	8
pool:	.zero	8 + (CHUNK_SIZE * CHUNK_COUNT)

	.section .rodata
filename:
	.string "inputs/day19"
first_hash:
	.dword	IN_HASH

