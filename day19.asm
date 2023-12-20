	.global main

	.include "macros.inc"
	.include "constants.inc"

	.set	IN_HASH, 0x696E

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	clr	s1				# workflows counter

loop_input:
	call	hash
	mv	s7, a1
	inc	a0				# skip opening brace
	clr	s9				# rules counter
loop_read_rules:
	inc	s9				# increment rules counter
	addi	sp, sp, -16
	lb	t0, 1(a0)			# read comparison operator
	li	t1, ASCII_LT
	beq	t0, t1, rule_lt
	li	t1, ASCII_GT
	beq	t0, t1, rule_gt
	# not a comparison operator, last rule
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
	sb	t0, 0(sp)			# store x/m/a/s

	addi	a0, a0, 2

	call	parse_integer
	sh	a1, 2(sp)

	inc	a0				# skip ':'

rule_hash:
	call	hash
	sd	a1, 4(sp)

	sb	s8 , 1(sp)
	inc	a0				# skip ',' or '}'

	bnez	s8, loop_read_rules

	inc	a0				# skip '\n'

	# copy rule in a linked list
	clr	s8				# previous rule pointer (null for last rule)
	mv	s10, a0
loop_link:
	li	a0, 20
	call	malloc

	ld	t0, 0(sp)
	sd	t0, 0(a0)
	ld	t0, 8(sp)
	sd	t0, 8(a0)
	
	sd	s8, 12(a0)
	mv	s8, a0
	addi	sp, sp, 16
	dec	s9
	bnez	s9, loop_link
	
	inc	s1				# increment workflows counter
	addi	sp, sp, -16
	sd	s7, 0(sp)
	sd	s8, 8(sp)

	mv	a0, s10

	lb	t0, 0(a0)
	li	t1, ASCII_LF			# loop until empty line reached
	bne	t0, t1, loop_input

	mv	s0, sp				# save workflows vector base pointer

	mv	a0, s0
	mv	a1, s1
	li	a2, 16
	la	a3, compar
	call	quicksort

	mv	a0, s10				# restore input pointer
	inc	a0				# skip empty input line

	clr	s9				# clear sum

loop_parts:
	# Parse the X/M/A/S values
	addi	sp, sp, -16
	mv	s10, sp
	.rept 4
	addi	a0, a0, 3
	call	parse_integer
	sw	a1, 0(s10)
	addi	s10, s10, 4
	.endr

	add	a0, a0, 2			# skip "}\n"
	mv	s10, a0
	
	li	s2, IN_HASH			# start at IN worflow
loop_workflows:
	blez	s2, loop_workflows_end		# exit loop if result found

	# search worflow pointer
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	call	binsearch
	mv	s2, a0

loop_rules:
	lb	s3, 0(s2)			# load x/m/a/s index
	slli	s3, s3, 2
	add	s3, s3, sp
	lw	s3, 0(s3)
	lb	s4, 1(s2)			# load difference operator, or 0 for last (default) rule
	lh	s5, 2(s2)			# load comparison value
	bltz	s4, comp_lt
	bgtz	s4, comp_gt
	ld	s2, 4(s2)			# load default worflow / result		
	j	loop_workflows
comp_lt:
	blt	s3, s5, comp_ok
	ld	s2, 12(s2)
	j	loop_rules
comp_gt:
	bgt	s3, s5, comp_ok
	ld	s2, 12(s2)
	j	loop_rules
comp_ok:
	ld	s2, 4(s2)
	j	loop_workflows

loop_workflows_end:
	beqz	s2, skip_add
	mv	t0, sp
	.rept	4
	lw	t1, 0(t0)
	add	s9, s9, t1
	addi	t0, t0, 4
	.endr
skip_add:


	mv	a0, s10
	blt	a0, s11, loop_parts

	mv	a0, s9
	call	print_int

end:


	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

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


        # a0: base pointer
        # a1: elements count
        # a2: element searched
binsearch:
        li      t0, 0                                   # index of first element
        addi    t2, a1, -1                              # index of last element
        li      t3, 16                                  # length of node
binsearch_loop:
        add     t1, t0, t2
        srli    t1, t1, 1                               # middle index
        mul     t5, t1, t3
        add     t5, t5, a0                              # pointer to middle element
        lw      t6, 0(t5)                               # load middle element
        blt     t6, a2, binsearch_right
        bgt     t6, a2, binsearch_left
	ld	a0, 8(t5)				# load pointer to first rule
        ret
binsearch_right:
        addi    t0, t1, 1
        j       binsearch_loop
binsearch_left:
        addi    t2, t1, -1
        j       binsearch_loop


compar:
	ld	t0, 0(a0)
	ld	t1, 0(a1)
	sub	a0, t0, t1
	ret
	
	

	.section .rodata

filename:
	.string "inputs/day19"
	.string "inputs/day19-test"

