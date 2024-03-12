        
	.macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.macro	CLR reg
	mv	\reg, zero
	.endm

	.macro	PUSH reg
	addi	sp, sp, -8
	sd	\reg, 0(sp)
	.endm

	.macro	POP reg
	ld	\reg, 0(sp)
	addi	sp, sp, 8
	.endm

