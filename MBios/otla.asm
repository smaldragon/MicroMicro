_OTLA_OUT
sei
sec
lda <BotPTR+0>; sbc $2000.lo; sta <r0>
lda <BotPTR+1>; sbc $2000.hi; sta <r1>
lda $2000.lo; sta <r2>
lda $2000.hi; sta <r3>
lda <rF>; sta <rD>

# Decrement Bytes Left Counter
_OTLA_MAIN
    # 21 cycles
    sec
    lda <r0>; sbc 1; sta <r0>
    lda <r1>; sbc 0; sta <r1>
    bcs (TransferNotOver)
        cli; rts
    __TransferNotOver
    # 30 cycles
    ldy 0; lda [<r2>+Y]; sta <rB>
    sec
    lda <r2>; adc 1; sta <r2>
    lda <r3>; adc 0; sta <r3>
    
    ldy 4
    _OTLA_BYTE_LOOP
    #.val byte 10
    #.val r0   0
    #.val r1   1
    #.val r2   2
    #.val r3   3
    #.val re   14
    #.val rf   15
    #.val BotPTR 16
    sta [$8000]
    #    3           3              2          2     2    | 12 cycles
    lda <rB>; lda <rB>; and %0000_00011; asl A; tax
    #    5           5            6           | 16 cycles
    lsr <rB>; lsr <rB>; jmp [[OTLA_TLB+X]]
    _OTLA_RETURN
    dec Y; bne (OTLA_BYTE_LOOP)
    # 4
jmp [OTLA_MAIN]
 

_OTLA_TLB
.word OTLA_00 
.word OTLA_01
.word OTLA_10
.word OTLA_11
_OTLA_00
    # _-
    # 200 cycles @2mhz
    
    lda [rD]; dec A; dec A
    __wait1
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait1)
    nop;nop;nop
    # 200 cycles @2mhz
    sta [$8000]
    lda [rD]; dec A
    __wait2
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait2)
    nop;nop;bit<$00>
jmp [OTLA_RETURN]

_OTLA_01
    # __-
    # 400 cycles @2mhz
    lda [rD]; asl A; dec A; dec A
    __wait1
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait1)
    nop; nop
    # 200 cycles @2mhz
    sta [$8000]
    lda [rD]; dec A
    __wait2
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait2)
    nop;nop;nop;bit<$00>
jmp [OTLA_RETURN]
_OTLA_10
    # __--
    # 400 cycles @2mhz
    lda [rD]; asl A; dec A; dec A
    __wait1
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait1)
    nop; nop
    # 400 cycles @2mhz
    sta [$8000]
    lda [rD]; asl A; dec A
    __wait2
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait2)
    nop;nop;bit<$00>
jmp [OTLA_RETURN]

_OTLA_11
    # ___--
    # 600 cycles @2mhz
    lda <rD>; asl A; clc; adc <rD>; dec A; dec A
    __wait1
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait1)
    # 400 cycles @2mhz
    sta [$8000]
    lda [rD]; asl A; dec A
    __wait2
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
        bit [$0000]
    dec A; bne (wait2)
    nop;nop;bit<$00>
jmp [OTLA_RETURN]