	.global main

	.include "macros.inc"
	.include "constants.inc"

	.section .rodata

filename:
	.string "inputs/day01"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	clr	s0

loop_input:
	call	read_next_digit
	li	t0, 10
	mul	s1, t0, a1
	mv	s2, a1				# first digit is also last digit for now
loop_line:
	call    read_next_digit
	li	t0, -1
	beq	a1, t0, loop_line_end
	mv	s2, a1
	j	loop_line
loop_line_end:
	add	s1, s1, s2
	add	s0, s0, s1
	blt	a0, s11, loop_input

	mv	a0, s0
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

read_next_digit:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	
	addi	s1, a0, -1
rnd_loop:
	inc	s1
	lb	s0, 0(s1)
	li	t0, ASCII_LF
	beq	s0, t0, rnd_eol
	mv	a0, s0
	call	is_digit
	beqz	a0, rnd_loop
	li	t0, ASCII_ZERO
	sub	a1, s0, t0
	j	rnd_end
rnd_eol:
	li	a1, -1
rnd_end:
	inc	s1
	mv	a0, s1
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	addi	sp, sp, 24
	ret
	

is_digit:
	li	t0, 0
	li	t1, ASCII_ZERO
	blt	a0, t1, is_digit_end
	li	t1, ASCII_NINE
	bgt	a0, t1, is_digit_end
	li	t0, 1
is_digit_end:
	mv	a0, t0
	ret
