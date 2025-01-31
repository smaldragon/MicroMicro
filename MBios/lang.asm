# Programming Language
.zp PC 2
.zp prev
.zp op
_LANG


__iEND
    sec; tya
    adc <PC+0>; sta <PC+0>
    lda 0
    adc <PC+1>; sta <PC+1>
__iRUN
    ldy 0
    lda [<PC>+Y]; asl A; tax
    jmp [[PTable+X]]
# PARSES
__PTable
__pOP
    ldx <op>; bne (doprevop)
    ___newop
        tsx; stx <prev>
        ldx $7F; txs
        sta <op>; jmp [iEND]
    __doprevop
        jmp [[OTable+X]]
__pCLEAR
    ldx <op>; bne (doprevop)
    #  we have performed any remaining op, clear regs
    ldx $ff; txs; stz <prev>
jmp[iEND]
__pDO
    ldx <op>; bne (doprevop)
jmp [iEND]
# OPERATIONS
__OTable
__oADD
    ldy <prev>; beq (done)
    clc
    ___loop
        pla; adc [$0100+Y]; sta [$0100+Y]
        inc Y; beq (done)
    tsx; bpl (loop)
        lda 0; pha
    bra (loop)
    ___done
jmp [iEND]

__oSUB
    ldy <prev>; beq (done)
    sec
    ___loop
        pla; sbc [$0100+Y]; sta [$0100+Y]
        inc Y; beq (done)
    tsx; bpl (loop)
        lda 0; pha
    bra (loop)
    ___done
jmp [iEND]