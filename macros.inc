        
	.macro  INC reg, val=1
        addi \reg, \reg, \val
        .endm

        .macro  DEC reg, val=1
        addi \reg, \reg, -\val
        .endm

	.macro	CLR reg
	mv	\reg, zero
	.endm

	.macro	EXIT status=0
	li	a0, \status
	li	a7, 93
	ecall
	.endm


	.macro	STORE_ALL_TEMP_REGS
	addi	sp, sp, -128
	sd	t0,   0(sp)
	sd	t1,   8(sp)
	sd	t2,  16(sp)
	sd	t3,  24(sp)
	sd	t4,  32(sp)
	sd	t5,  40(sp)
	sd	t6,  48(sp)
	sd	a0,  56(sp)
	sd	a1,  64(sp)
	sd	a2,  72(sp)
	sd	a3,  80(sp)
	sd	a4,  88(sp)
	sd	a5,  96(sp)
	sd	a6, 104(sp)
	sd	a7, 112(sp)
	sd	ra, 120(sp)
	.endm

	.macro	LOAD_ALL_TEMP_REGS
	ld	t0,   0(sp)
	ld	t1,   8(sp)
	ld	t2,  16(sp)
	ld	t3,  24(sp)
	ld	t4,  32(sp)
	ld	t5,  40(sp)
	ld	t6,  48(sp)
	ld	a0,  56(sp)
	ld	a1,  64(sp)
	ld	a2,  72(sp)
	ld	a3,  80(sp)
	ld	a4,  88(sp)
	ld	a5,  96(sp)
	ld	a6, 104(sp)
	ld	a7, 112(sp)
	ld	ra, 120(sp)
	addi	sp, sp, 128
	.endm

	.set	SAVED_REG_T0,   0
	.set	SAVED_REG_T1,   8
	.set	SAVED_REG_T2,  16
	.set	SAVED_REG_T3,  24
	.set	SAVED_REG_T4,  32
	.set	SAVED_REG_T5,  40
	.set	SAVED_REG_T6,  48
	.set	SAVED_REG_A0,  56
	.set	SAVED_REG_A1,  64
	.set	SAVED_REG_A2,  72
	.set	SAVED_REG_A3,  80
	.set	SAVED_REG_A4,  88
	.set	SAVED_REG_A5,  96
	.set	SAVED_REG_A6, 104
	.set	SAVED_REG_A7, 112
	.set	SAVED_REG_RA, 120
