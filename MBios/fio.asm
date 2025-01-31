# FIN
_FiIN
asflkdafsdlkasdflkasdflj

# FOUT
_FiOUT
    sei
    .val speed0 r0
    .val speed1 r1
    .val OutByte r2
    lda <rF>; asl A; dec A; sta <speed1> 
    inc A;    asl A; dec A; sta <speed0>
    
    ldx 128
    __startpad
        lda $00; jsr [OutputByte]
    dec X; bne (startpad)
    #lda $FF; jsr [OutputByte]
    
    lda $FF; jsr [OutputByte]
    
    lda $2000.lo; sta <r4>
    lda $2000.hi; sta <r5>
    # FileSend Loop
    __FileLoop
        lda <r4>; cmp <BotPTR+0>; bne (continue)
        lda <r5>; cmp <BotPTR+1>; bne (continue)
            rts
        ___continue
        ldy 0
        lda [<r4>+Y]; jsr [OutputByte]
        clc
        lda <r4>; adc 1; sta <r4>
        lda <r5>; adc 0; sta <r5>
    bra (FileLoop)
    # Sub function
    __OutputByte
    sta <OutByte>
    
    # start bit
    #jsr [out1]
    # data bits
    ldy 8
    __OutputBit
    dec Y; bne (continue)
    # stop bit
    #jsr [out0]
    rts
    ___continue
    asl <OutByte>; bcs (out1)
    #jsr [out0]
    #___out1j
    #jsr [out1]
    
    __out0
        # 4+3
        sta [$8000]; lda [speed0]
        lda [speed0]; nop
        ___loop1
            sta [$0006]; sta [$0006]
        dec A; bne (loop1)
        
        
        sta [$8000]; lda [speed0]
        lda [speed0]; nop
        ___loop2
            sta [$0006]; sta [$0006]
        dec A; bne (loop2)
    jmp [OutputBit]
    
    __out1
        sta [$8000]; lda [speed1]
        lda [speed1]; nop
        ___loop1
            sta [$0006]; sta [$0006]
        dec A; bne (loop1)
        
        sta [$8000]; lda [speed1]
        lda [speed1]; nop
        ___loop2
            sta [$0006]; sta [$0006]
        dec A; bne (loop2)
        
        sta [$8000]; lda [speed1]
        lda [speed1]; nop
        ___loop3
            sta [$0006]; sta [$0006]
        dec A; bne (loop3)
        
        sta [$8000]; lda [speed1]
        lda [speed1]; nop
        ___loop4
            sta [$0006]; sta [$0006]
        dec A; bne (loop4)
    jmp [OutputBit]