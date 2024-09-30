	.global	print_hex
	.global	print_dec
	.global	print_bin
	.global	print_str
	.global	print_ln
	.global	print_chr

	.section .text

print_chr:
	addi	sp, sp, -1
	sb	a0, (sp)
	li	a0, 1
	mv	a1, sp
	li	a2, 1
	li	a7, 64
	ecall
	addi	sp, sp, 1
        ret

print_str:
	addi	sp, sp, -16
	sd	s0, 0(sp)
	sd	ra, 8(sp)
print_str_loop:
	lb	t0, 0(a0)
	beqz	t0, print_str_end
	mv	s0, a0
	mv	a0, t0
	call	print_chr
	addi	a0, s0, 1
	j	print_str_loop
print_str_end:
	ld	s0, 0(sp)
	ld	ra, 8(sp)
	addi	sp, sp, 16
	ret

print_dec:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	li	a1, 10
	call	print_base
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

print_hex:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	a0, 8(sp)
	li	a0, 0x30			# 0
	call	print_chr
	li	a0, 0x78			# x
	call	print_chr
	ld	a0, 8(sp)
	li	a1, 0x10
	call	print_base
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

print_bin:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	a0, 8(sp)
	li	a0, 0x30			# 0
	call	print_chr
	li	a0, 0x62			# b
	call	print_chr
	ld	a0, 8(sp)
	li	a1, 0b10
	call	print_base
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret

	
print_base:
	addi	sp, sp, -16
	li	t0, -1
	sh	t0, 0(sp)

print_base_loop:
	remu	t1, a0, a1
	addi	sp, sp, -16
	sh	t1, 0(sp)
	divu	a0, a0, a1
	bnez	a0, print_base_loop


print_base_print_loop:
	la	t0, hex_symbols
	lh	t1, 0(sp)
	addi	sp, sp, 16
	bltz	t1, print_base_print_loop_end
	add	t1, t1, t0
	lb	a0, 0(t1)
	call	print_chr
	j	print_base_print_loop
print_base_print_loop_end:
	ld      ra, 0(sp)
	addi    sp, sp, 16
	ret
	
	

print_ln:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	la	a0, 10
	call	print_chr
	ld	ra, 0(sp)
	addi	sp, sp, 16
	ret



	.section .rodata
	
hex_symbols:
	.string	"0123456789ABCDEF"
	#.string	"0123456789abcdef"

