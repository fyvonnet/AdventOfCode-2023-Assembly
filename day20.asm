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
	.set	MOD_PTR,	16
	.set	MOD_TYPE, 	24
	.set	MOD_MEM, 	25

	#.set	LIST_SIZE, 	16
	.set	LIST_SIZE_LONG,	24
	.set	LIST_VAL, 	 0
	.set	LIST_NEXT, 	 8
	.set	LIST_LABEL,	16

	.set	TYPE_CONJ, 	'&'
	.set	TYPE_FLIPFLOP,	'%'
	.set	TYPE_BCAST, 	'b'

	.bss
	.balign	8
	.type	arena, @object
	.set	ARENA_SIZE, 8*1024	
	.size	arena, ARENA_SIZE
arena:	.zero	ARENA_SIZE
	.set	QUEUE_ELEMCNT, 50
	.set	QUEUE_ELEMSZ, 16
	.set	QUEUE_SIZE, 16 + (QUEUE_ELEMCNT * QUEUE_ELEMSZ)
	.type	queue, @object
	.size	queue, QUEUE_SIZE
queue:	.zero	QUEUE_SIZE

	.text

	.global _start
	.type	_start, @function
_start:
	la      a0, filename
	call    map_input_file
	mv	s10, a0
	add	s11, a0, a1

	mv	s0, s10

	la	a0, arena
	li	a1, ARENA_SIZE
	call	arena_init
	
	clr	s1

	# load allo modules from inputs into the stack
	mv	a0, s10
loop_pass1:
	inc	s1
	addi	sp, sp, -TEMP_SIZE
	lb	t0, (a0)
	sd	t0, TEMP_TYPE(sp)
	inc	a0
	call	parse_label
	addi	a0, a0, 4
	sd	a0, TEMP_PTR(sp)
	sd	a1, TEMP_LABEL(sp)
	call	skip_to_next_line
	blt	a0, s11, loop_pass1

	# allocate meory for the modules vector
	la	a0, arena
	li	a1, MOD_SIZE
	mul	a1, a1, s1
	call	arena_alloc
	mv	s0, a0

	
	# copy modules from the stack to the modules vector

	mv	s2, s0			# mods array
	mv	s3, s1			# counter
loop_store_mods:
	ld	s5, TEMP_PTR(sp)
	sd	s5, MOD_PTR(s2)
	ld	s5, TEMP_LABEL(sp)
	sd	s5, MOD_LABEL(s2)
	ld	s5, TEMP_TYPE(sp)
	sb	s5, MOD_TYPE(s2)
	li	t0, TYPE_FLIPFLOP
	clr	s6

	bne	s5, t0, not_flipflop
	# conjunction components have only one input
	la	a0, arena
	li	a1, 8
	call	arena_alloc
	mv	s6, a0
	#sd	s4, (s6)
	sd	zero, (s6)
not_flipflop:

	sd	s6, MOD_INS(s2)
	sb	zero, MOD_MEM(s2)

	addi	s2, s2, MOD_SIZE
	dec	s3
	addi	sp, sp, TEMP_SIZE
	bnez	s3, loop_store_mods


	# sort modules for the binary search
	mv	a0, s0
	mv	a1, s1
	li	a2, MOD_SIZE
	la	a3, compar_labels
	call	quicksort


	mv	a0, s10
	mv	s2, s0
	mv	s9, s1			# countdown
	addi	sp, sp, -16
	mv	s5, sp
loop_origs:

	lb	t0, MOD_TYPE(s2)
	li	t1, TYPE_BCAST

	bne	t0, t1, not_bcast

	mv	s8, s2			# store pointer to broadcast component
not_bcast:

	ld	a0, MOD_PTR(s2)
	sd	x0, MOD_OUTS(s2)

	clr	s6				# initialize counter
loop_dests:
	inc	s6
	call	parse_label

	sd	a1, 0(s5)
	sd	a0, 8(s5)

	mv	a0, s0
	mv	a1, s1
	li	a2, MOD_SIZE
	la	a3, compar_labels
	mv	a4, s5
	call	binsearch
	mv	s3, a0

	clr	s4
	beqz	s3, dest_untyped		# untyped module found
	lb	t0, MOD_TYPE(s3)
	li	t1, TYPE_FLIPFLOP
	ld	s4, MOD_INS(s3)
	beq	t0, t1, dest_flipflop


	# conjunction module
	la	a0, arena
	li	a1, 8
	call	arena_alloc
	mv	s4, a0

	addi	a0, s3, MOD_INS
	mv	a1, s4
	clr	a2
	call	push_signal

add_to_orig:
dest_untyped:
dest_flipflop:

	addi	sp, sp, -16
	sd	s4, 0(sp)
	sd	s3, 8(sp)

	ld	a0, 8(s5)

	li	t1, ','
	lb	t0, (a0)
	addi	a0, a0, 2
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



	dec	a0

	addi	s2, s2, MOD_SIZE

	dec	s9
	bnez	s9, loop_origs

	addi	sp, sp, -16
	mv	s5, sp
	sd	zero, 0(s5)
	sd	zero, 8(s5)

	li	s9, 1000

loop_presses:

	la	a0, queue
	li	a1, QUEUE_ELEMCNT
	li	a2, QUEUE_ELEMSZ
	call	queue_init

	la	a0, queue
	call	queue_push
	sd	s8, (a0)

	# add one low pulse from pressing the button
	ld	t0, 0(s5)
	inc	t0
	sd	t0, 0(s5)

loop_onepress:

	la	a0, queue
	call	queue_pop
	beqz	a0, loop_onepress_end
	ld	s0, (a0)
	ld	s11, 8(a0)

	lb	t0, MOD_TYPE(s0)
	li	t1, TYPE_BCAST
	beq	t0, t1, emit_bcast
	li	t1, TYPE_CONJ
	beq	t0, t1, emit_conj
	li	t1, TYPE_FLIPFLOP
	beq	t0, t1, emit_flipflop
	
	# should not reach here
	li	a0, 2
	li	a7, 93
	ecall

	# brodcaster emits low pulse from the button
emit_bcast:
	li	s1, 0
	j	emit

emit_conj:
	ld	s2, MOD_INS(s0)
loop_emit_conj:
	ld	t0, LIST_VAL(s2)
	ld	t1, (t0)
	beqz	t1, emit_conj_hi
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_emit_conj
	li	s1, 0
	j	emit
emit_conj_hi:
	li	s1, 1
	j	emit

emit_flipflop:
	bgtz	s11, loop_onepress			# ignore if high pulse is received
	lb	s1, MOD_MEM(s0)
	xori	s1, s1, 1
	sb	s1, MOD_MEM(s0)
	j	emit

emit:
	ld	s2, MOD_OUTS(s0)
	slli	t0, s1, 3
	add	s10, s5, t0
loop_emit:
	ld	t0, (s10)
	inc	t0
	sd	t0, (s10)
	
	ld	t0, LIST_VAL(s2)
	beqz	t0, skip_emit
	sd	s1, (t0)
skip_emit:
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_emit

enqueue:
	ld	s2, MOD_OUTS(s0)
loop_enqueue:
	ld	s3, LIST_LABEL(s2)
	beqz	s3, skip_enqueue
	la	a0, queue
	call	queue_push
	sd	s3, (a0)
	sd	s1, 8(a0)
skip_enqueue:
	ld	s2, LIST_NEXT(s2)
	bnez	s2, loop_enqueue


	j	loop_onepress
	
loop_onepress_end:

	dec	s9
	bnez	s9, loop_presses


	ld	t0, 0(s5)
	ld	t1, 8(s5)
	mul	a0, t0, t1
	call	print_int
	
	li      a0, EXIT_SUCCESS
	li      a7, SYS_EXIT
	ecall
	.size	_start, .-_start


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
	li	a1, LIST_SIZE_LONG
	call	arena_alloc

	ld	t0, (s0)
	sd	t0, LIST_NEXT(a0)
	sd	s1, LIST_VAL(a0)
	sd	s2, LIST_LABEL(a0)
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

