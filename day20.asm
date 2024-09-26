	.include "macros.inc"
	.include "constants.inc"



	.set	TEMP_SIZE, 	32
	.set	TEMP_LABEL, 	 0
	.set	TEMP_TYPE, 	 8
	.set	TEMP_PTR, 	16

	.set	MOD_SIZE, 	32
	.set	MOD_LABEL,	 0
	.set	MOD_INS,	 8
	.set	MOD_OUTS,	16
	.set	MOD_TYPE, 	24
	.set	MOD_MEM, 	25

	.set	LIST_SIZE,	24
	.set	LIST_VAL, 	 0
	.set	LIST_NEXT, 	 8
	.set	LIST_MOD,	16

	.set	TYPE_CONJ, 	'&'
	.set	TYPE_FLIPFLOP,	'%'
	.set	TYPE_BCAST, 	'b'



	.bss


	.balign	8

	.type	arena, @object
	.set	ARENA_SIZE, 16*1024	
	.size	arena, ARENA_SIZE
arena:	.space	ARENA_SIZE

	.set	QUEUE_ELEMCNT, 50
	.set	QUEUE_ELEMSZ, 16
	.set	QUEUE_SIZE, 40 + (QUEUE_ELEMCNT * QUEUE_ELEMSZ)
	.type	queue, @object
	.size	queue, QUEUE_SIZE
queue:	.space	QUEUE_SIZE



	.text


	.global _start
	.type	_start, @function
_start:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init

	la	a0, queue
	li	a1, QUEUE_ELEMCNT
	li	a2, QUEUE_ELEMSZ
	call	queue_init

	la	a0, compar_labels
	la	a1, alloc
	la	a2, free
	call	redblacktree_init
	mv	s0, a0

loop_lines:
	lb	s1, (s10)
	inc	s10
	mv	a0, s10
	call	parse_label
	addi	s10, a0, 3			# skip " ->"

	mv	a0, s0
	call	get_mod_ptr
	mv	s2, a0

	sb	s1, MOD_TYPE(s2)
	
	li	t0, TYPE_BCAST
	bne	s1, t0, not_bcast
	mv	s8, s2				# copy broadcaster pointer
not_bcast:

	clr	s6				# initialize counter
loop_dests:
	inc	s10				# skip space
	inc	s6
	mv	a0, s10
	call	parse_label
	mv	s10, a0				# destination label

	mv	a0, s0
	call	get_mod_ptr
	mv	s3, a0


	# conjunction module
	la	a0, arena
	li	a1, 8
	call	arena_alloc
	mv	s4, a0

	sd	zero, (s4)

	addi	a0, s3, MOD_INS
	mv	a1, s4
	mv	a2, s2
	call	push_signal

	addi	sp, sp, -16
	sd	s4, 0(sp)
	sd	s3, 8(sp)

	li	t1, ','
	lb	t0, (s10)
	inc	s10				# skip ',' or '\n'
	beq	t0, t1, loop_dests

	# copy destination modules from 
	# the stack to the current module
loop_copy:
	addi	a0, s2, MOD_OUTS
	ld	a1, 0(sp)
	ld	a2, 8(sp)
	call	push_signal
	addi	sp, sp, 16
	dec	s6
	bnez	s6, loop_copy
	blt	s10, s11, loop_lines


	# PART 1


	# initialize counters for low and high pulses
	addi	sp, sp, -16
	sd	zero, 0(sp)
	sd	zero, 8(sp)

	li	s9, 1000			# presses countdown
loop_presses:
	la	a0, queue
	call	queue_push
	sd	s8, 0(a0)
	mv	a0, sp
	clr	a1
	call	button_press
	dec	s9
	bnez	s9, loop_presses

	ld	t0, 0(sp)
	ld	t1, 8(sp)
	addi	sp, sp, 16
	mul	a0, t0, t1
	call	print_int


	# PART 2

	# Analysis of the input file shows that the RX module has one conjunction input module that has 4 inputs.
	# That module will send a low pulse when all its inputs receive a high pulse.
	# We need to find out the number of button press before each of the module's inputs receive a high pulse.
	# Solution to part 2 is the product of the press counts for all the inputs.


	la	a0, rx_str
	call	parse_label
	mv	a0, s0
	call	get_mod_ptr

	ld	t0, MOD_INS(a0)
	ld	t0, LIST_MOD(t0)
	ld	s7, MOD_INS(t0)
	
	li	s6, 1				# initialize counts product

loop_ins:
	ld	s3, LIST_MOD(s7)

	mv	a0, s0
	la	a1, reset
	clr	a2
	call	redblacktree_inorder

	la	a0, queue
	li	a1, QUEUE_ELEMCNT
	li	a2, QUEUE_ELEMSZ
	call	queue_init
	
	clr	s9

loop_until_high:
	inc	s9

	la	a0, queue
	call	queue_push
	sd	s8, (a0)

	mv	a0, sp
	mv	a1, s3
	call    button_press

	beqz	a0, loop_until_high
	mul	s6, s6, s9
	ld	s7, LIST_NEXT(s7)

	bnez	s7, loop_ins
	
	mv	a0, s6
	call	print_int
	

	li      a0, EXIT_SUCCESS
	li      a7, SYS_EXIT
	ecall
	.size	_start, .-_start


	# a0: tree
	# a1: label
	.type	get_mod_ptr, @function
get_mod_ptr:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)

	mv	s0, a0
	mv	s1, a1

	la	a0, arena
	li	a1, MOD_SIZE
	call	arena_alloc

	sd	s1, MOD_LABEL(a0)
	sd	zero, MOD_INS(a0)
	sd	zero, MOD_OUTS(a0)
	sb	zero, MOD_TYPE(a0)
	sb	zero, MOD_MEM(a0)

	mv	a1, a0
	mv	a0, s0
	call	redblacktree_insert_or_free
	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 32
	ret
	.size	get_mod_ptr, .-get_mod_ptr


	.type	button_press, @function
button_press:
	addi	sp, sp, -72
	sd	s2,   0(sp)
	sd	s3,   8(sp)
	sd	s5,  16(sp)
	sd	s6,  24(sp)
	sd	s7,  32(sp)
	sd	s10, 40(sp)
	sd	s11, 48(sp)
	sd	ra,  56(sp)
	sd	s1,  64(sp)
	

	mv	s5, a0
	mv	s1, a1

	# add one low pulse from pressing the button
	ld	t0, 0(s5)
	inc	t0
	sd	t0, 0(s5)

loop_onepress:

	la	a0, queue
	call	queue_pop

	clr	a1
	beqz	a0, loop_onepress_end		# end loop when queue empty
	ld	s7, 0(a0)			# load module pointer
	ld	s11, 8(a0)			# load pulse (flipflop only)

	lb	t0, MOD_TYPE(s7)
	li	t1, TYPE_BCAST
	beq	t0, t1, emit_bcast
	li	t1, TYPE_CONJ
	beq	t0, t1, emit_conj
	li	t1, TYPE_FLIPFLOP
	beq	t0, t1, emit_flipflop

	beqz	t0, loop_onepress			# null type modules do not emit
	
	# should not reach here
	li	a0, 2
	li	a7, SYS_EXIT
	ecall

emit_bcast:
	li	s6, 0					# brodcaster emits low pulse from the button
	j	emit

emit_conj:
	ld	s2, MOD_INS(s7)
loop_emit_conj:
	ld	t0, LIST_VAL(s2)
	ld	t1, (t0)
	beqz	t1, emit_conj_hi			# emit a high signal if one low input is detected
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_emit_conj			# emit a low signal if all inputs are high
	li	s6, 0
	j	emit
emit_conj_hi:
	# we got a conjunction module emiting a high signal
	# check if it's the target module 
	beqz	s1, skip_target
	bne	s1, s7, skip_target
	li	a1, 1
	j	loop_onepress_end	
skip_target:
	li	s6, 1
	j	emit

emit_flipflop:
	bgtz	s11, loop_onepress			# ignore module if high pulse is received
	lb	s6, MOD_MEM(s7)				# load memory content
	xori	s6, s6, 1				# invert memory content
	sb	s6, MOD_MEM(s7)				# save back memory content
	j	emit

emit:
	ld	s2, MOD_OUTS(s7)
	slli	t0, s6, 3
	add	s10, s5, t0
loop_emit:
	ld	t0, (s10)
	inc	t0
	sd	t0, (s10)
	
	ld	t0, LIST_VAL(s2)
	sd	s6, (t0)
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_emit

	# enqueue destination modules
	ld	s2, MOD_OUTS(s7)
loop_enqueue:
	beqz	s2, loop_enqueue_end
	ld	s3, LIST_MOD(s2)
	la	a0, queue
	call	queue_push
	sd	s3, 0(a0)
	sd	s6, 8(a0)
	ld	s2, LIST_NEXT(s2)
	j	loop_enqueue
loop_enqueue_end:


	j	loop_onepress
	
loop_onepress_end:
	mv	a0, a1
	ld	s2,   0(sp)
	ld	s3,   8(sp)
	ld	s5,  16(sp)
	ld	s6,  24(sp)
	ld	s7,  32(sp)
	ld	s10, 40(sp)
	ld	s11, 48(sp)
	ld	ra,  56(sp)
	ld	s1,  64(sp)
	addi	sp, sp, 72
	ret
	.size	button_press, .-button_press


	.type	free, @function
free:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	mv	a1, a0
	la	a0, arena
	call	arena_free
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret
	.size	free, .-free


	.type	alloc, @function
alloc:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	mv	a1, a0
	la	a0, arena
	call	arena_alloc
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret
	.size	alloc, .-alloc




	.type	reset, @function
reset:
	sb	zero, MOD_MEM(a0)
	ld	t0, MOD_OUTS(a0)
loop_reset_out:
	beqz	t0, loop_reset_out_end
	ld	t1, LIST_VAL(t0)
	beqz	t1, skip_zero
	sd	zero, (t1)
skip_zero:
	ld	t0, LIST_NEXT(t0)
	j	loop_reset_out
loop_reset_out_end:
	ret
	.size	reset, .-reset


	# a0: ptr to ptr to link head
	# a1: ptr to new signal
	# a2: destination label
	.type	push_signal, @function
push_signal:
	addi	sp, sp, -32
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	la	a0, arena
	li	a1, LIST_SIZE
	call	arena_alloc

	ld	t0, (s0)
	sd	t0, LIST_NEXT(a0)
	sd	s1, LIST_VAL(a0)
	sd	s2, LIST_MOD(a0)
	sd	a0, (s0)

	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 32
	ret
	.size	push_signal, .-push_signal



	.type	parse_label, @function
parse_label:
	li	t0, 'a'
	li	t1, 'z'
	clr	a1
loop_parse_label:
	lb	t2, (a0)
	blt	t2, t0, parse_label_end
	bgt	t2, t1, parse_label_end
	inc	a0
	slli	a1, a1, 8
	add	a1, a1, t2
	j	loop_parse_label
parse_label_end:
	ret
	.size	parse_label, .-parse_label
	


	.type	compar_labels, @function
compar_labels:
	ld	t0, MOD_LABEL(a0)
	ld	t1, MOD_LABEL(a1)
	sub	a0, t0, t1
	ret
	.size	compar_labels, .-compar_labels



	.section .rodata
	.type	filename, @object
filename:
	.string "inputs/day20"
	.size	filename, .-filename
rx_str:
	.string	"rx"

