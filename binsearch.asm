	.global	binsearch

	.include "macros.inc"
	.include "constants.inc"

	.section .text


        # a0: base pointer
        # a1: elements count
	# a2: element size
	# a3: comparison function
        # a4: pointer to element searched
binsearch:
	addi	sp, sp, -80
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)
	sd	s6, 56(sp)
	sd	s7, 64(sp)
	
	mv	s3, a0					# base pointer
	mv	s4, a4					# pointer to element searched
	mv	s5, a3					# comparison function
	mv	s6, a2					# element size
        clr	s0					# index of first element
        addi    s2, a1, -1                              # index of last element
binsearch_loop:
	bgt	s0, s2, binsearch_fail
        add     s1, s0, s2 
        srli    s1, s1, 1                               # middle element index

        mul     a0, s1, s6				# middle element offset
        add     a0, a0, s3                              # pointer to middle element
	mv	a1, s4
	mv	s7, a0

	jalr	s5
        bltz	a0, binsearch_right
        bgtz    a0, binsearch_left
	mv	a0, s7

binsearch_ret:
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	ld	s6, 56(sp)
	ld	s7, 64(sp)
	addi	sp, sp, 80
        ret


binsearch_right:
        addi    s0, s1, 1
        j       binsearch_loop
binsearch_left:
        addi    s2, s1, -1
        j       binsearch_loop

binsearch_fail:
	clr	a0
	j	binsearch_ret

