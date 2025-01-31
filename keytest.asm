.cpu 65c02

.zp Cursor 2

.org [$E000]
_RESET
_NMI
_IRQ
__clear
  ldy 0
  stz <Cursor+0>; lda 2
  ___ouloop
  sta <Cursor+1>; lda 0
  ___inloop
    sta [<Cursor>+Y]
  inc Y; bne (inloop)
  lda <Cursor+1>; inc A; cmp 32; bne (ouloop)
  stz <Cursor+1>
__loop
    lda [%1001_1111_1111_1110]
    sta [$0310]
    lda [%1001_1111_1111_1101]
    sta [$0311]
    lda [%1001_1111_1111_1011]
    sta [$0312]
    lda [%1001_1111_1111_0111]
    sta [$0313]
    lda [%1001_1111_1110_1111]
    sta [$0314]
jmp [loop]

.pad [VECTORS]
.word NMI
.word RESET
.word IRQ