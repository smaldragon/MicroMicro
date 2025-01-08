# -------------------------
# STDIO
#  handles basic terminal input and output functions
# -------------------------
_FONT
.bin "font"

.val FONT_0 FONT+0-32
.val FONT_1 FONT+96-32
.val FONT_2 FONT+192-32
.val FONT_3 FONT+288-32
.val FONT_4 FONT+384-32
.val FONT_5 FONT+480-32
.val FONT_6 FONT+576-32
.val FONT_7 FONT+672-32

.zp Cursor  2
.zp CursorFlip 1
.zp CursorTime 1
.zp CursorColour 1
.zp KInp    7
.zp KInpPtr 1
.zp KLast   5
.zp KMod    1
.zp KTime   1
.zp KRepeat 1

# Control Codes
.val DEL $7F  # delete
.val BEL $07  # bell
.val LF  $0A  # line feed
.val FF  $0C  # form feed
.val CR  $0D  # carriage return
.val BS  $08  # backspace
.val CHI $10  # color highlight
.val CNO $11  # color normal

.val ALF   $01
.val ARI   $02
.val AUP   $03
.val ADW   $04

# ...............................
# :11|16|21|26|31|36|41|46|51|56:
# :12|15|22|25|32|35|42|45|52|55:
# :13|14|23|24|33|34|43|44|53|54:
# ...............................
# NORMAL
# ................................
# : q  w  e  r  t  y  u  i  o  p :
# : a  s  d  f  g  h  j  k  l  en:
# : z  x  c  v sf al  b  n  m  sp:
# ................................
# SHIFT
# ................................
# : Q  W  E  R  T  Y  U  I  O  P :
# : A  S  D  F  G  H  J  K  L  en:
# : Z  X  C  V sf al  B  N  M  sp:
# ................................
# ALT
# ................................
# : 1  2  3  4  5  6  7  8  9  0 :
# : @  #  $  %  &  -  +  (  )  . :
# : *  "  '  : sf al  ;  !  ?  , :
# ................................
# SHIFT+ALT
# ................................
# :                  dl:
# : /  \  ~  ^  `  _  =  [  ]  en:
# : <  >       sf al     {  }  sp:
# ................................

.val SPC ' '
.val ENT LF
.val SHF 0
.val ALT 0
.val HSH $23
.val QOT $27

_KMapR1
.byte 'q','a','z','x','s','w',0,0 # normal
.byte 'Q','A','Z','X','S','W',0,0 # shift
.byte '1','@','*','"',HSH,'2',0,0 # alt
.byte 0,ALF,0,0,ADW,AUP,0,0 # shift+alt

_KMapR2
.byte 'e','d','c','v','f','r',0,0 # normal
.byte 'E','D','C','V','F','R',0,0 # shift
.byte '3','$',QOT,':','%','4',0,0 # alt
.byte 0,ARI,0,0,0,0,0,0 # shift+alt

_KMapR3
.byte 't','g', 0 , 0 ,'h','y',0,0 # normal
.byte 'T','G', 0 , 0 ,'H','Y',0,0 # shift
.byte '5','&', 0 , 0 ,'-','6',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR4
.byte 'u','j','b','n','k','i',0,0 # normal
.byte 'U','J','B','N','K','I',0,0 # shift
.byte '7','+',';','!','(','8',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR5
.byte 'o','l','m',SPC,ENT,'p',0,0 # normal
.byte 'O','L','M',SPC,ENT,'P',0,0 # shift
.byte '9',')','?',SPC,BS ,'0',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

##
_KRowRead
  # r01 INPUT: holds pointer to the row's keymap
  # r2  INPUT: holds the row read value
  # r3  TEMP:  is a counter
  lda <r2>; xor <r3>; and <r2>; sta <r2>
  
  lda 6; sta <r3>
  ldx <KInpPtr>; cpx 8; beq (return)
  ldy <KMod>
  __loop
    lda [<r0>+Y]
    lsr <r2>; bcc (notpressed)
      # pressed logic goes here
      inc X; sta <KInp-1+X>; cpx 8; beq (return)
    __notpressed
    inc Y
  dec <r3>; bne (loop)
  __return
  stx <KInpPtr>
rts

# ----------------------------------------------------------------
# KeyBoard Interrupt Routine
_KReadINT
  pha; phx; phy
  lda <r0>; pha
  lda <r1>; pha
  lda <r2>; pha
  lda <r3>; pha
  lda <r4>; pha; stz <r4>
  
  __modifiers
  lda [%1000_0000_1111_1011]; asl A; and %0001_1000
  sta <KMod>
  
  __row1
  lda <KLast+0>; sta <r3>
  lda [%1000_0000_1111_1110]; cmp <KLast+0>; beq (row2)
    inc <r4>
    sta <r2>; sta <KLast+0>
    lda KMapR1.lo; sta <r0>
    lda KMapR1.hi; sta <r1>
    jsr [KRowRead]
  __row2
  #jmp [blink]
  lda <KLast+1>; sta <r3>
  lda [%1000_0000_1111_1101]; cmp <KLast+1>; beq (row3)
    inc <r4>
    sta <r2>; sta <KLast+1>
    lda KMapR2.lo; sta <r0>
    lda KMapR2.hi; sta <r1>
    jsr [KRowRead]
  __row3
  lda <KLast+2>; sta <r3>
  lda [%1000_0000_1111_1011]; cmp <KLast+2>; beq (row4)
    inc <r4>
    sta <r2>; sta <KLast+2>
    lda KMapR3.lo; sta <r0>
    lda KMapR3.hi; sta <r1>
    jsr [KRowRead]
  __row4
  lda <KLast+3>; sta <r3>
  lda [%1000_0000_1111_0111]; cmp <KLast+3>; beq (row5)
    inc <r4>
    sta <r2>; sta <KLast+3>
    lda KMapR4.lo; sta <r0>
    lda KMapR4.hi; sta <r1>
    jsr [KRowRead]
  __row5
  lda <KLast+4>; sta <r3>
  lda [%1000_0000_1110_1111]; cmp <KLast+4>; beq (blink)
    inc <r4>
    sta <r2>; sta <KLast+4>
    lda KMapR5.lo; sta <r0>
    lda KMapR5.hi; sta <r1>
    jsr [KRowRead]
  __blink
  lda 30; cmp <CursorTime>; bne (noblink)
    inc <CursorFlip>
    stz <CursorTime>
    ldy 7; ldx $0F
  lda <Cursor+1>; inc A; inc A; sta <r1>
  lda <Cursor+0>; lsr A; bcs (right)
    ldx $F0
  ___right
  asl A; asl A; asl A; sta <r0>
  ___loop
    txa; xor [<r0>+Y]; sta [<r0>+Y]
  dec Y; bpl (loop)
  ___noblink
  inc <CursorTime>
  
  lda <r4>; beq (nopress)
    stz <KRepeat>; lda $40; sta <KTime>
    ldx <KInpPtr>; beq (nopress)
    lda <KInp-1+X>; beq (nopress)
    sta <KRepeat>; inc X
  __nopress
  inc <KTime>; lda %0000_1111; and <KTime>; bne (norepeat)
    lda <KRepeat>; beq (norepeat)
    inc <KInpPtr>; ldx <KInpPtr>
    sta <KInp+X>
    lda $00; sta <KTime>
  __norepeat
  
  pla; sta <r4>
  pla; sta <r3>
  pla; sta <r2>
  pla; sta <r1>
  pla; sta <r0>
  ply; plx; pla
rti

_STDIOINIT
  stz <KInpPtr>
  stz <CursorColour>
  
  # Setup Keyboard Routine
  sei
  lda $4C; sta <IRQ>        # JMP abs
  lda KReadINT.lo; sta <IRQ+1>
  lda KReadINT.hi; sta <IRQ+2>
  cli
rts

# ----------------------------------------------------------------
# Reads a file from audio into [[r0-r1]], max size [[r2-r3]]
_FIN
  
rts
# ----------------------------------------------------------------
# Writes a file to audio from [[r0-r1]] to [[r2-r3]]
_FOUT

rts

# ----------------------------------------------------------------
# Character Input from keyboard
_CIN
  ldx <KInpPtr>; cpx 0; beq (none)
    dec <KInpPtr>; lda <KInp-1+X>; rts  
  __none
  lda 0
  #txa
rts

# ----------------------------------------------------------------
# Write Character to terminal
_COUT
  pha
  
  lda <Cursor+0>; and %0011_1111; sta <Cursor+0>
  
  lda $00; sta <CursorTime>
  
  
  __blinkcheck
  lda $01; bit <CursorFlip>; beq (notblinking)
    ldy 7; ldx $0F
  lda <Cursor+1>; inc A; inc A; sta <r1>
  lda <Cursor+0>; lsr A; bcs (right)
    ldx $F0
  ___right
  asl A; asl A; asl A; sta <r0>
  ___loop
    txa; xor [<r0>+Y]; sta [<r0>+Y]
  dec Y; bpl (loop)
  __notblinking
  stz <CursorFlip>
  
  pla
  cmp DEL; beq (del)
  cmp BEL; beq (bel)
  cmp BS;  beq (bs)
  cmp LF;  beq (lf)
  cmp CR;  beq (cr)
  cmp FF;  beq (ff)
  cmp CHI; beq (chi)
  cmp CNO; beq (cno)
  cmp 32;  bcs (char)
cli; rts
__lf
  inc <Cursor+1>
jsr [ScrollFix]
cli
rts

__cr
  stz <Cursor+0>
  cli
rts

__char
jmp [charf]
__chi
  lda $ff; sta <CursorColour>
  cli
rts
__cno
  stz <CursorColour>
  cli
rts
# DEL - Delete Character at location
__bs
  dec <Cursor+0>; bpl (del)
    lda 63; sta <Cursor+0>
    dec <Cursor+1>; bpl (del)
      #jsr [FixScrollDown]
__del
  ldy 7; ldx $F0
  lda <Cursor+1>; inc A; inc A; sta <r1>
  lda <Cursor+0>; lsr A; bcs (right)
    ldx $0F
  ___right
  asl A; asl A; asl A; sta <r0>
  ___loop
    txa; and [<r0>+Y]; sta [<r0>+Y]
  dec Y; bpl (loop)
  cli
rts
# BEL - Bell, plays a short sound
__bel
  # Frequency is based on rF, so the value will be constant
  .val belLength 100
  sei
  ldy belLength
  ___ouloop
    sta [$C000]
    ldx <rF>
    ___inloop
      lda 30; sta <r0>
      ___ininloop
      dec <r0>; bne (ininloop)
    dec X; bne (inloop)
  dec Y; bne (ouloop)
  cli
rts

# FF - Form Feed, clears screen
__ff
  ldy 0
  stz <Cursor+0>; lda 2
  ___ouloop
  sta <Cursor+1>; lda 0
  ___inloop
    sta [<Cursor>+Y]
  inc Y; bne (inloop)
  lda <Cursor+1>; inc A; cmp 32; bne (ouloop)
  stz <Cursor+1>
  stz <CursorFlip>
  cli
rts
__charf
  sei
  pha
  jsr [del]
  pla
  tax
  lda <Cursor+1>; cmp 30; bcc (cont)
    phx; jsr [ScrollFix]; pla
    bra (charf)
  __cont
  
  inc A; inc A; sta <r1>
  lda <Cursor+0>; lsr A; bcc (left);
  ___right
  asl A; asl A; asl A; sta <r0>
  ldy 0
  lda <CursorColour>; xor [FONT_0+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_1+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_2+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_3+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_4+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_5+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_6+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_7+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]
  lda <Cursor+0>; inc A; cmp 64; bne (noinc)
    inc <Cursor+1>; lda 0
  ___noinc
  sta <Cursor+0>
  cli
rts
  ___left
  asl A; asl A; asl A; sta <r0>
  ldy 0
  lda <CursorColour>; xor [FONT_0+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_1+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_2+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_3+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_4+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_5+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_6+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda <CursorColour>; xor [FONT_7+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]
  lda <Cursor+0>; inc A; cmp 64; bne (noinc)
    inc <Cursor+1>; lda 0
  ___noinc
  sta <Cursor+0>
  cli
rts

# Scroll Function
_ScrollFix
  lda <Cursor+1>; cmp 30; bcs (notdone)
    rts
  __notdone
  jsr [Scroll]
_Scroll
  lda 031; sta <r0>
  lda $00; sta <r1>
  lda $01; sta <r2>
_ScrollCustom
  php; sei
  
  lda <r0>; pha
  lda <r1>; inc A; inc A; pha
  lda 0; jsr [COUT]
  
  dec <Cursor+1>
  # Fill Zero Page Pointers
  
  ldy $02
  ply; pla; sta <r0>
  
  __mainloop
  lda $F0
  ldx 63
  __fill
    sty <$C0+X>; dec X
    sta <$C0+X>; dec X
    
    pha
    tya; clc; adc <r2>
    sta <$C0+X>; dec X
    pla
    sta <$C0+X>
    sec; sbc $10
  dec X; bpl (fill)
  phy; ldy $0F
  __loop
    lda [<$C0>+Y]; sta [<$C2>+Y]
    lda [<$C4>+Y]; sta [<$C6>+Y]
    lda [<$C8>+Y]; sta [<$CA>+Y]
    lda [<$CC>+Y]; sta [<$CE>+Y]

    lda [<$D0>+Y]; sta [<$D2>+Y]
    lda [<$D4>+Y]; sta [<$D6>+Y]
    lda [<$D8>+Y]; sta [<$DA>+Y]
    lda [<$DC>+Y]; sta [<$DE>+Y]

    lda [<$E0>+Y]; sta [<$E2>+Y]
    lda [<$E4>+Y]; sta [<$E6>+Y]
    lda [<$E8>+Y]; sta [<$EA>+Y]
    lda [<$EC>+Y]; sta [<$EE>+Y]

    lda [<$F0>+Y]; sta [<$F2>+Y]
    lda [<$F4>+Y]; sta [<$F6>+Y]
    lda [<$F8>+Y]; sta [<$FA>+Y]
    lda [<$FC>+Y]; sta [<$FE>+Y]
    
  dec Y; bpl (loop)
  pla; clc; adc <r2>; tay; cpy <r0>; bne (mainloop)
  # Empty Remaining Line
  lda 0
  phy; ldy $0F
  __zeroloop
    sta [<$C0>+Y]
    sta [<$C4>+Y]
    sta [<$C8>+Y]
    sta [<$CC>+Y]

    sta [<$D0>+Y]
    sta [<$D4>+Y]
    sta [<$D8>+Y]
    sta [<$DC>+Y]
    
    sta [<$E0>+Y]
    sta [<$E4>+Y]
    sta [<$E8>+Y]
    sta [<$EC>+Y]

    sta [<$F0>+Y]
    sta [<$F4>+Y]
    sta [<$F8>+Y]
    sta [<$FC>+Y]
    
  dec Y; bpl (zeroloop)
  ply
  plp
rts
#jmp [SlowScroll]

_HexToAscii
  # Value to convert in A
  # Results in A and X
  pha
  and $0F; clc; adc $30; cmp $3A; bcc (next1)
    clc; adc $07
  __next1
  tax
  pla
  lsr A; lsr A; lsr A; lsr A
  and $0F; clc; adc $30; cmp $3A; bcc (next2)
    clc; adc $07
  __next2
rts

_AsciiToHex
  # Converts value in A and X
  # result in A
  sec; sbc $30; cmp $0A; bcc (notletterLo)
    and %01011_1111; sec; sbc 7
  __notletterLo
  asl A; asl A; asl A; asl A; sta <r0>
  txa
  sec; sbc $30; cmp $0A; bcc (notletterHi)
    and %01011_1111; sec; sbc 7
  __notletterHi
  ora <r0>
rts
