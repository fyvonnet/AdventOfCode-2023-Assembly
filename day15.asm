	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1


         ######     #    ######  #######      #
         #     #   # #   #     #    #        ##
         #     #  #   #  #     #    #       # #
         ######  #     # ######     #         #
         #       ####### #   #      #         #
         #       #     # #    #     #         #
         #       #     # #     #    #       #####


	clr	s1				# sum
loop:
	call	hash
	add	s1, s1, a1
	blt 	a0, s11, loop
	
	mv	a0, s1
	call	print_int


         ######     #    ######  #######     #####
         #     #   # #   #     #    #       #     #
         #     #  #   #  #     #    #             #
         ######  #     # ######     #        #####
         #       ####### #   #      #       #
         #       #     # #    #     #       #
         #       #     # #     #    #       #######


	# allocate heap memory for box pointers
	li	a0, 256
	li	a1, 8
	call	calloc
	mv	s1, a0

back:
	bge	s0, s11, compute_focusing_power
	mv	a0, s0
	call	decode_label
	# a1: pointer to label string
	# a2: box number
	#mv	s1, a1
	
	mv	s0, a0
	slli	s10, a2, 3
	add	s10, s10, s1					# box address

	mv	a0, a1
	call	str_to_reg					# string's "hash"
	mv	s9, a0

	lb	t0, 0(s0)
	li	t1, ASCII_EQUAL
	beq	t0, t1, insert
	addi	s0, s0, 2
	j	remove

compute_focusing_power:

	clr	s10
	li	s11, 256
	li	s9, 1						# box number
loop_boxes:
	ld	t0, 0(s1)					# load head of list
	li	t1, 1						# slot number
loop_slots:
	beqz	t0, loop_slots_end
	lb	t2, 8(t0)					# load fucusing power
	mul	t2, t2, t1					# multiply focusing power with slot number
	mul	t2, t2, s9
	add	s10, s10, t2					# add product to global sum
	ld	t0, 9(t0)
	inc	t1
	j	loop_slots
loop_slots_end:
	addi	s1, s1, 8
	inc	s9
	dec	s11
	bnez	s11, loop_boxes

	mv	a0, s10
	call	print_int
end:
	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	

nop
remove:
	ld	t0, 0(s10)
	clr	t1						# previous node
loop_remove:
	beqz	t0, back					# null pointer reached or list empty
	ld	t2, 0(t0)					# load hash
	beq	s9, t2, remove_node				# remove node if hash equel
	mv	t1, t0						# current node becomes previous node
	ld	t0, 9(t0)					# load next node
	j	loop_remove
remove_node:
	beqz	t1, remove_first_node
	ld	t2, 9(t0)
	sd	t2, 9(t1)
	mv	a0, t0
	call	free
	j	back
remove_first_node:
	ld	t2, 9(t0)
	sd	t2, 0(s10)
	mv	a0, t0
	call	free
	j	back
	
	
	

insert:
	addi	a0, s0, 1
	call	parse_integer
	addi	s0, a0, 1
	mv	s8, a1
	ld	s7, 0(s10)					# load head of list
	bnez	s7, loop_list_insert
	li	a0, 17
	call	malloc
	sd	s9, 0(a0)
	sb	s8, 8(a0)
	sd	x0, 9(a0)
	sd	a0, 0(s10)
	j	back
	
loop_list_insert:
	ld	t1, 0(s7)
	beq	t1, s9, insert_replace
	ld	t1, 9(s7)
	bnez	t1, loop_list_insert_next			# check if end of list reached
	li	a0, 17
	call	malloc
	sd	s9, 0(a0)
	sb	s8, 8(a0)
	sd	x0, 9(a0)
	sd	a0, 9(s7)
	j	back
loop_list_insert_next:
	mv	s7, t1
	j	loop_list_insert

insert_replace:
	sb	s8, 8(s7)
	j	back
	
	


         ####### #     # ######
         #       ##    # #     #
         #       # #   # #     #
         #####   #  #  # #     #
         #       #   # # #     #
         #       #    ## #     #
         ####### #     # ######



str_to_reg:
	clr	t0
loop_str_to_reg:
	lb	t1, 0(a0)
	beqz	t1, loop_str_to_reg_end
	slli	t0, t0, 8
	or	t0, t0, t1
	inc	a0
	j	loop_str_to_reg
loop_str_to_reg_end:
	mv	a0, t0
	ret
	

decode_label:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)


	clr	s0
	li	t2, ASCII_A
	li	t3, ASCII_Z
loop_read_letters:
	lb	t1, 0(a0)
	blt	t1, t2, loop_read_letters_end
	bgt	t1, t3, loop_read_letters_end
	addi	sp, sp, -16
	sb	t1, 0(sp)
	inc	a0
	inc	s0
	j	loop_read_letters
loop_read_letters_end:
	addi	sp, sp, -16
	sd	zero, 0(sp)
	mv	s1, a0
	addi	a0, s0, 1
	call	malloc
	mv	s2, a0
	ld	a0, 0(sp)

loop_copy_letters:
	add	t0, s2, s0
	lb	t1, 0(sp)
	addi	sp, sp, 16
	sb	t1, 0(t0)
	dec	s0
	bgez	s0, loop_copy_letters

	mv	a0, s2
	call	hash
	mv	a2, a1

	mv	a0, s1
	mv	a1, s2
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 32
	ret
	nop
	

hash:
	clr	a1
	li	t1, 17
	li	t2, 256
	la	t3, ASCII_COMMA
	la	t4, ASCII_LF
loop_hash:
	lb	t0, 0(a0)
	beqz	t0, loop_hash_end
	beq	t0, t3, loop_hash_end
	beq	t0, t4, loop_hash_end
	add	a1, a1, t0
	mul	a1, a1, t1
	rem	a1, a1, t2
	inc	a0
	j	loop_hash
loop_hash_end:
	inc	a0
	ret
	

	.section .rodata

filename:
	.string "inputs/day15"
	.string "inputs/day15-test"
