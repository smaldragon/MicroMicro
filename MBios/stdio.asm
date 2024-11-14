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
.zp KInp    7
.zp KInpPtr 1
.zp KLast   5
.zp KMod    1

.val DEL $7F
.val BEL $07
.val LF  $0A
.val FF  $0C
.val CR  $0D
.val BS  $08
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

_KMapR1
.byte 'q','a','z','x','s','w',0,0 # normal
.byte 'Q','A','Z','X','S','W',0,0 # shift
.byte '1', 0 , 0 , 0 , 0 ,'2',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR2
.byte 'e','d','c','v','f','r',0,0 # normal
.byte 'E','D','C','V','F','R',0,0 # shift
.byte '3', 0 , 0 , 0 , 0 ,'4',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR3
.byte 't','g',SHF,ALT,'h','y',0,0 # normal
.byte 'T','G',SHF,ALT,'H','Y',0,0 # shift
.byte '5', 0 , 0 , 0 , 0 ,'6',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR4
.byte 'u','j','b','n','k','i',0,0 # normal
.byte 'U','J','B','N','K','I',0,0 # shift
.byte '7', 0 , 0 , 0 , 0 ,'8',0,0 # alt
.byte 0,0,0,0,0,0,0,0 # shift+alt

_KMapR5
.byte 'o','l','m',SPC,ENT,'p',0,0 # normal
.byte '9','L','M',SPC,ENT,'0',0,0 # shift
.byte 0,0,0,0,0,0,0,0 # alt
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
	
	__modifiers
	lda [%1000_0000_1111_1011]; asl A; and %0001_1000
	sta <KMod>
	
	__row1
	lda <KLast+0>; sta <r3>
	#lda [%1000_0000_1111_1110]; cmp <KLast+0>; beq (row2)
	lda [%1000_0000_1111_1110]; cmp <KLast+0>; beq (row2)
		sta <r2>; sta <KLast+0>
		lda KMapR1.lo; sta <r0>
		lda KMapR1.hi; sta <r1>
		jsr [KRowRead]
	__row2
	#jmp [blink]
	lda <KLast+1>; sta <r3>
	lda [%1000_0000_1111_1101]; cmp <KLast+1>; beq (row3)
		sta <r2>; sta <KLast+1>
		lda KMapR2.lo; sta <r0>
		lda KMapR2.hi; sta <r1>
		jsr [KRowRead]
	__row3
	lda <KLast+2>; sta <r3>
	lda [%1000_0000_1111_1011]; cmp <KLast+2>; beq (row4)
		sta <r2>; sta <KLast+2>
		lda KMapR3.lo; sta <r0>
		lda KMapR3.hi; sta <r1>
		jsr [KRowRead]
	__row4
	lda <KLast+3>; sta <r3>
	lda [%1000_0000_1111_0111]; cmp <KLast+3>; beq (row5)
		sta <r2>; sta <KLast+3>
		lda KMapR4.lo; sta <r0>
		lda KMapR4.hi; sta <r1>
		jsr [KRowRead]
	__row5
	lda <KLast+4>; sta <r3>
	lda [%1000_0000_1110_1111]; cmp <KLast+4>; beq (blink)
		sta <r2>; sta <KLast+4>
		lda KMapR5.lo; sta <r0>
		lda KMapR5.hi; sta <r1>
		jsr [KRowRead]

  __blink
  lda <rF>; asl A; dec A; and <CursorTime>; bne (noblink)
  	inc <CursorFlip>
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
  
  pla; sta <r3>
  pla; sta <r2>
  pla; sta <r1>
  pla; sta <r0>
  ply; plx; pla
rti


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
  stz <CursorTime>
  pha
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
  cmp 32;  bcs (char)
rts
__lf
  inc <Cursor+1>
rts
__cr
  stz <Cursor+0>
rts

__char
jmp [charf]
# DEL - Delete Character at location
__bs
	dec <Cursor+0>; bpl (del)
		lda 63; sta <Cursor+0>
		dec <Cursor+1>; bpl (del)
			stz <Cursor+0>; stz <Cursor+1>
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
rts
# BEL - Bell, plays a short sound
__bel
  # Frequency is based on rF, so the value will be constant
  .val belLength 100
  
  ldy belLength
  ___ouloop
    sta [$8000]
    ldx <rF>
    ___inloop
      lda 5; sta <r0>
      ___ininloop
      dec <r0>; bne (ininloop)
    dec X; bne (inloop)
  dec Y; bne (ouloop)
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
rts
__charf
  tax
  lda <Cursor+1>; cmp 30; bcc (cont)
    txa; pha; jsr [FixScroll]; pla
    bra (charf)
  __cont
  
  inc A; inc A; sta <r1>
  lda <Cursor+0>; lsr A; bcc (left);
  ___right
  asl A; asl A; asl A; sta <r0>
  ldy 0
  lda [FONT_0+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_1+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_2+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_3+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_4+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_5+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_6+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_7+X]; and $0F; ora [<r0>+Y]; sta [<r0>+Y]
  lda <Cursor+0>; inc A; cmp 64; bne (noinc)
    inc <Cursor+1>; lda 0
  ___noinc
  sta <Cursor+0>
rts
  ___left
  asl A; asl A; asl A; sta <r0>
  ldy 0
  lda [FONT_0+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_1+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_2+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_3+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_4+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_5+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_6+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]; inc Y
  lda [FONT_7+X]; and $F0; ora [<r0>+Y]; sta [<r0>+Y]
  lda <Cursor+0>; inc A; cmp 64; bne (noinc)
    inc <Cursor+1>; lda 0
  ___noinc
  sta <Cursor+0>
rts

_FixScroll
  sei
  __loop
  ldx 30
  lda <Cursor+1>; cmp 29; beq (done)
    
    dec <Cursor+1>
    stz <r0>; lda 2; sta <r1>
    stz <r2>; lda 3; sta <r3>
    __rowloop
    ldy 0
    ___inloop
      lda [<r2>+Y]; sta [<r0>+Y]
    inc Y; bne (inloop)
    lda 0; ldy 0
    ___eloop
      sta [$2000+Y]
    inc Y; bne (eloop)
    inc <r1>; inc <r3>; dec X; bne (rowloop)
  bra (loop)
  __done
  cli
rts
