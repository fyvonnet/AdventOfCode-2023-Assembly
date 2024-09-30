	.global map_input_file
	.global parse_integer
	.global print_int
    .global line_length
    .global string_length
    .global skip_to_next_line
    .global skip_to_digit
	.global is_digit
	.global	search_char
	.global exit

	.section .text

exit:
	li	a7, 93
	li	a0, 0
	ecall

map_input_file:
	addi	sp, sp, -128		# alloc space for struct stat

	li	a7, 56			# openat
	mv	a1, a0			# file name
	li	a0, -100		# AT_FDCWD
	li	a2, 0			# O_RDONLY
	ecall

	mv	t0, a0

	li	a7, 80			# newfstat
	mv	a0, t0			# file descriptor
	mv	a1, sp			# load stats in the stack
	ecall

	li	a7, 222			# mmap
	li	a0, 0			# NULL
	ld	a1, 48(sp)		# file size is at offset 48
	li	a2, 1			# PROT_READ
	li	a3, 2			# MAP_PRIVATE
	mv	a4, t0			# file descriptor
	li	a5, 0			# offset
	ecall

	addi	sp, sp, 128
	ret
	
parse_integer:
	li	t1, 0			# final value
	li	t3, 48			# ASCII '0'
	li	t4, 57			# ASCII '9'
	li	t5, 10			# constant 10
	li	t6, 1			# final multiplier
	
	lb	t2, 0(a0)
	li	t0, 43			# ASCII '+'
	beq	t0, t2, skip_plus
	li	t0, 45			# ASCII '-'
	bne	t0, t2, loop_parse_integer
	li	t6, -1
	addi	a0, a0, 1
loop_parse_integer:
	lb	t2, 0(a0)
	blt	t2, t3, end_parse_integer
	blt	t4, t2, end_parse_integer
	sub	t2, t2, t3
	mul	t1, t1, t5
	add	t1, t1, t2
	addi	a0, a0, 1
	j	loop_parse_integer
end_parse_integer:
	#mv	a1, t1
	mul	a1, t1, t6
	ret
skip_plus:
	addi	a0, a0, 1
	j	loop_parse_integer
	

print_int:
	addi	a1, sp, -1
	li	t0, 10
	li	a2, 1
	sb	t0, 0(a1)
	li	t2, 0
	bgez	a0, loop_print_int
	li	t2, 1			# number is negative
	neg	a0, a0
loop_print_int:
	addi	a1, a1, -1
	addi	a2, a2,  1
	rem	t1, a0, t0
	addi	t1, t1, 48		# ASCII '0'
	sb	t1, 0(a1)
	div	a0, a0, t0
	beqz	a0, loop_print_int_end
	j	loop_print_int
loop_print_int_end:
	beqz	t2, end_print_int
	addi	a2, a2, 1
	addi	a1, a1, -1
	li	t1, 45			# ASCII '-'
	sb	t1, 0(a1)
end_print_int:
	li	a7, 64			# SYS_WRITE
	li	a0,  1			# stdout
	ecall
	ret
	
line_length:
    li      t1, 10
    mv      t2, a0
line_length_loop:
    lb      t0, 0(a0)
    addi    a0, a0, 1
    bne     t0, t1, line_length_loop
    addi    a0, a0, -1
    sub     a0, a0, t2
    ret

string_length:
    mv	    t6, zero
string_length_loop:
    lb      t0, 0(a0)
    addi    a0, a0, 1
    addi     t6, t6, 1
    bnez    t0, string_length_loop
    addi    a0, t6, -1
    ret

skip_to_next_line:
    li      t1, 10
skip_to_next_line_loop:
    lb      t0, 0(a0)
    addi    a0, a0, 1
    bne     t0, t1, skip_to_next_line_loop
    ret

    
is_digit:
        li      t0, 0
        li      t1, 48
        blt     a0, t1, is_digit_end
        li      t1, 57
        bgt     a0, t1, is_digit_end
        li      t0, 1
is_digit_end:
        mv      a0, t0
        ret     





        # a0: input pointer
skip_to_digit:
        addi    sp, sp, -16
        sd      s0, 0(sp)
        sd      ra, 8(sp)

        mv      s0, a0
	addi	s0, s0, -1
loop_skip_to_digit:
	addi	s0, s0, 1
        lb      a0, 0(s0)
        call    is_digit
        beqz    a0, loop_skip_to_digit
        mv      a0, s0

        ld      s0, 0(sp)
        ld      ra, 8(sp)
        addi    sp, sp, 16

        ret

	# a0: string
	# a1: char
search_char:
	li	t0, 0
search_char_loop:
	lb	t1, (a0)
	beq	t1, a1, search_char_succ
	beqz	t1, search_char_fail
	addi	t0, t0, 1
	addi	a0, a0, 1
	j	search_char_loop
search_char_succ:
	mv	a0, t0
	ret
search_char_fail:
	li	a0, -1
	ret


