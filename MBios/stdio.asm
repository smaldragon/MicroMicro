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

#.asm otla

.zp Cursor  2
	.val CursorX Cursor+0
	.val CursorY Cursor+1
.zp CursorFlip 1
.zp CursorTime 1
.zp CursorColour 1
.zp ActiveFooter 1

.val KInpSize 4
.zp KInp    KInpSize

.zp KInpPtr 1
.zp KLast   5
.zp KCur    5
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
.val FON $12  # Footer ON
.val FOF $13  # Footer OFF

.val ALF   $01
.val ARI   $02
.val AUP   $03
.val ADW   $04

# ...............................
# :11|16|21|26|31|36|41|46|51|56:
# :12|15|22|25|32|35|42|45|52|55:
# :13|14|23|24|33|34|43|44|53|54:
# ...............................

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
# ...............................:
# :                              :
# : /  \  ~  ^  `  _  =  [  ]  en:
# : <  >       sf al     {  }  sp:
# ................................

.val SPC ' '
.val ENT LF
.val SHF 0
.val ALT 0
.val HSH $23
.val QOT $27
.val QUIT $FF

_KMapR1
.byte 'q','a', 0 ,'z','s','w',0,0 # normal
.byte 'Q','A', 0 ,'Z','S','W',0,0 # shift
.byte '1','@', 0 ,'*',HSH,'2',0,0 # alt
.byte QUIT,ALF,0 ,'~',ADW,AUP,0,0 # shift+alt

_KMapR2
.byte 'e','d','x','c','f','r',0,0 # normal
.byte 'E','D','X','C','F','R',0,0 # shift
.byte '3','$',$22,QOT,'%','4',0,0 # alt
.byte '^',ARI, 0 , 0 ,'{','|',0,0 # shift+alt

_KMapR3
.byte 't','g','v','b','h','y',0,0 # normal
.byte 'T','G','V','B','H','Y',0,0 # shift
.byte '5','&',',','.','-','6',0,0 # alt
.byte '_','}',';',':','<', 0 ,0,0 # shift+alt

_KMapR4
.byte 'u','j','n','m','k','i',0,0 # normal
.byte 'U','J','N','M','K','I',0,0 # shift
.byte '7','+','?','!','(','8',0,0 # alt
.byte  0 ,'=','/','\','[', 0 ,0,0 # shift+alt

_KMapR5
.byte 'o','l',SPC, 0 ,ENT,'p',0,0 # normal
.byte 'O','L',SPC, 0 ,ENT,'P',0,0 # shift
.byte '9',')', 0 , 0 ,BS ,'0',0,0 # alt
.byte  0 ,']', 0 , 0 , 0 , 0 ,0,0 # shift+alt

_KMapJ1
.byte 'a','b','c','d','e','f',0,0 # normal
.byte 'a','b','c','d','e','f',0,0 # normal
.byte 'a','b','c','d','e','f',0,0 # normal
.byte 'a','b','c','d','e','f',0,0 # normal

_KMapJ2
.byte 'A','B','C','D','E','F',0,0 # normal
.byte 'A','B','C','D','E','F',0,0 # normal
.byte 'A','B','C','D','E','F',0,0 # normal
.byte 'A','B','C','D','E','F',0,0 # normal

##
_KRowRead
  # r01 INPUT: holds pointer to the row's keymap
  # r2  INPUT: holds the row read value
  # r3  TEMP:  is a counter
  lda <r2>; xor <r3>; and <r2>; sta <r2>
  
  lda 6; sta <r3>
  ldx <KInpPtr>; cpx KInpSize; beq (return)
  ldy <KMod>
  __loop
    lsr <r2>
    lda [<r0>+Y]
    beq (notpressed); bcc (notpressed)
      # pressed logic goes here
      inc X; sta <KInp-1+X>; cpx KInpSize; beq (return)
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
  
  .val KRow1 %1001_1111_1111_1110
  .val KRow2 %1001_1111_1111_1101
  .val KRow3 %1001_1111_1111_1011
  .val KRow4 %1001_1111_1111_0111
  .val KRow5 %1001_1111_1110_1111
  .val KJoy1 %1000_1111_1111_1111
  .val KJoy2 %1001_0111_1111_1111
  
  __modifiers
  lda [KRow1]; sta <KCur+0>
  lda [KRow2]; sta <KCur+1>
  lda [KRow3]; sta <KCur+2>
  lda [KRow4]; sta <KCur+3>
  lda [KRow5]; sta <KCur+4>
  
  
  lda <KCur+0>; and %00_000100; sta <r0>
  lda <KCur+4>; and %00_001000; ora <r0>
  asl A; sta <KMod>
  
  __row1
  lda <KLast+0>; sta <r3>
  lda <KCur+0>; cmp <KLast+0>; beq (row2)
    inc <r4>
    sta <r2>; sta <KLast+0>
    lda KMapR1.lo; sta <r0>
    lda KMapR1.hi; sta <r1>
    jsr [KRowRead]
  __row2
  #jmp [blink]
  lda <KLast+1>; sta <r3>
  lda <KCur+1>; cmp <KLast+1>; beq (row3)
    inc <r4>
    sta <r2>; sta <KLast+1>
    lda KMapR2.lo; sta <r0>
    lda KMapR2.hi; sta <r1>
    jsr [KRowRead]
  __row3
  lda <KLast+2>; sta <r3>
  lda <KCur+2>; cmp <KLast+2>; beq (row4)
    inc <r4>
    sta <r2>; sta <KLast+2>
    lda KMapR3.lo; sta <r0>
    lda KMapR3.hi; sta <r1>
    jsr [KRowRead]
  __row4
  lda <KLast+3>; sta <r3>
  lda <KCur+3>; cmp <KLast+3>; beq (row5)
    inc <r4>
    sta <r2>; sta <KLast+3>
    lda KMapR4.lo; sta <r0>
    lda KMapR4.hi; sta <r1>
    jsr [KRowRead]
  __row5
  lda <KLast+4>; sta <r3>
  lda <KCur+4>; cmp <KLast+4>; beq (blink)
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
  stz <ActiveFooter>
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
# Pitched Beep
_BEEP
  phx; phy
  # Frequency is based on rF, so the value will be constant
  .val belLength 100
  pha
  sei
  ldy belLength
  __ouloop
    stz [$FFFF]
    ldx <CPUFreq>
    __inloop
      pla; pha
      __ininloop
      dec A; bne (ininloop)
    dec X; bne (inloop)
  dec Y; bne (ouloop)
  pla
  ply; plx
  cli
rts



# ----------------------------------------------------------------
# Character Input from keyboard
_CIN
  phx
  #phx; phy
  ldx <KInpPtr>; cpx 0; beq (none)
    dec <KInpPtr>; lda <KInp-1+X>; 
    plx
    ora 0
    #ply; plx; 
    rts  
  __none
  plx
  lda 0
  #txa
  #ply; plx
rts
.macro SPrint
    lda {0}.lo; sta <r4>
    lda {0}.hi; sta <r5>
    jsr [SOUT]
.endmacro

.macro SPrintZ
    lda <{0}+0>; sta <r4>
    lda <{0}+1>; sta <r5>
    jsr [SOUT]
.endmacro
_SOUT
  # prints string in r45 until zero termination
  ldy 0
__loop
  lda [<r4>+Y]; beq(done)
  phy
  jsr [COUT]
  ply;inc Y; bne (loop)
  inc <r5>; bra (loop)
__done
rts
# ----------------------------------------------------------------
# Write Character to terminal
_COUT
  pha
  phx; phy
  
  lda <Cursor+0>; and %0011_1111; sta <Cursor+0>
  
  lda 25; sta <CursorTime>
  
  
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
  
  ply; plx
  pla
  cmp DEL; beq (del)
  cmp BEL; beq (bel)
  cmp BS;  beq (bs)
  cmp LF;  beq (lf)
  cmp CR;  beq (cr)
  cmp FF;  beq (ff)
  cmp CHI; beq (chi)
  cmp CNO; beq (cno)
  cmp FON; beq (fon)
  cmp FOF; beq (fof)
  cmp $7F; bcs (invalid)
  cmp 32;  bcs (char)
  ___invalid
cli; rts
__bel
  jmp [belf]
__fon
  lda $FF; sta <ActiveFooter>
rts
__fof
  stz <ActiveFooter>
rts
__lf
  phx; phy
  inc <Cursor+1>
jsr [ScrollFix]
ply; plx
__cr
  stz <Cursor+0>
  cli
rts

__char
pha; phx; phy
jsr [charf]
ply; plx; pla

cli; rts
__chi
  lda $ff; sta <CursorColour>
rts
__cno
  stz <CursorColour>
rts
# DEL - Delete Character at location
__bs
  dec <Cursor+0>; bpl (del)
    lda 63; sta <Cursor+0>
    dec <Cursor+1>; bpl (del)
      #jsr [FixScrollDown]
__del
  phx; phy
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
  ply; plx
rts
# BEL - Bell, plays a short sound
__belf
  lda 48
  jmp [BEEP]
rts

# FF - Form Feed, clears screen
__ff
  phy
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
  ply
  cli
rts
__charf
  sei
  
  pha; jsr [del]; pla
  
  tax; phx
  jsr [ScrollFix]
  plx
  
  lda <Cursor+1>; inc A; inc A; sta <r1>
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
  jsr [ScrollFix]
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
  jsr [ScrollFix]
  cli
rts

# Scroll Function
_ScrollFix
  lda <Cursor+1>; sec; sbc <ActiveFooter>; cmp 30; bcs (notdone)
    rts
  __notdone
  #jsr [Scroll]
  # Setup scroll start point, scroll bottom line
  lda MoveTextUp_loop.lo; sta <r0>
  lda MoveTextUp_loop.hi; sta <r1>
  lda <ActiveFooter>; asl A
_MoveTextUp
  sei
  ldx 0
__loop
  lda [$0300+X]; sta [$0200+X]
  lda [$0400+X]; sta [$0300+X]
  lda [$0500+X]; sta [$0400+X]
  lda [$0600+X]; sta [$0500+X]
  lda [$0700+X]; sta [$0600+X]
  lda [$0800+X]; sta [$0700+X]
  lda [$0900+X]; sta [$0800+X]
  lda [$0A00+X]; sta [$0900+X]
  
  lda [$0B00+X]; sta [$0A00+X]
  lda [$0C00+X]; sta [$0B00+X]
  lda [$0D00+X]; sta [$0C00+X]
  lda [$0E00+X]; sta [$0D00+X]
  lda [$0F00+X]; sta [$0E00+X]
  lda [$1000+X]; sta [$0F00+X]
  lda [$1100+X]; sta [$1000+X]
  lda [$1200+X]; sta [$1100+X]
  
  lda [$1300+X]; sta [$1200+X]
  lda [$1400+X]; sta [$1300+X]
  lda [$1500+X]; sta [$1400+X]
  lda [$1600+X]; sta [$1500+X]
  lda [$1700+X]; sta [$1600+X]
  lda [$1800+X]; sta [$1700+X]
  lda [$1900+X]; sta [$1800+X]
  lda [$1A00+X]; sta [$1900+X]
  
  lda [$1B00+X]; sta [$1A00+X]
  lda [$1C00+X]; sta [$1B00+X]
  lda [$1D00+X]; sta [$1C00+X]
  lda [$1E00+X]; sta [$1D00+X]
  
  bcs (skipfooter)
  lda [$1F00+X]; sta [$1E00+X]
  stz [$1F00+X]
  inc X; beq (end); jmp [[r0]]
  __skipfooter
  stz [$1E00+X]
  inc X; beq (end); jmp [[r0]]
__end
  dec <Cursor+1>
  cli
rts

_MoveTextDown
  sei
  lda <ActiveFooter>; asl A
  ldx 0
__loop
  bcs (skipfooter)
  lda [$1E00+X]; sta [$1F00+X]
  ___skipfooter
  lda [$1D00+X]; sta [$1E00+X]
  lda [$1C00+X]; sta [$1D00+X]
  lda [$1B00+X]; sta [$1C00+X]
  lda [$1A00+X]; sta [$1B00+X]
  lda [$1900+X]; sta [$1A00+X]
  lda [$1800+X]; sta [$1900+X]
  lda [$1700+X]; sta [$1800+X]

  lda [$1600+X]; sta [$1700+X]
  lda [$1500+X]; sta [$1600+X]
  lda [$1400+X]; sta [$1500+X]
  lda [$1300+X]; sta [$1400+X]
  lda [$1200+X]; sta [$1300+X]
  lda [$1100+X]; sta [$1200+X]
  lda [$1000+X]; sta [$1100+X]
  lda [$0F00+X]; sta [$1000+X]

  lda [$0E00+X]; sta [$0F00+X]
  lda [$0D00+X]; sta [$0E00+X]
  lda [$0C00+X]; sta [$0D00+X]
  lda [$0B00+X]; sta [$0C00+X]
  lda [$0A00+X]; sta [$0B00+X]
  lda [$0900+X]; sta [$0A00+X]
  lda [$0800+X]; sta [$0900+X]
  lda [$0700+X]; sta [$0800+X]

  lda [$0600+X]; sta [$0700+X]
  lda [$0500+X]; sta [$0600+X]
  lda [$0400+X]; sta [$0500+X]
  lda [$0300+X]; sta [$0400+X]
  lda [$0200+X]; sta [$0300+X]
  stz [$0200+X]

  inc X; beq (end); jmp [[r0]]
__end
  dec <Cursor+1>
  cli
rts

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
  
  # First Nibble (A)
  ## convert to lowercase
  ora %0010_0000
  ## test
  cmp '0'; bcc (fail)
  sec; sbc $30; cmp $0A; bcc (notletterLo)
    sec; sbc $27
    cmp $10; bcs (fail)
  __notletterLo
  
  ## store first nibble for later
  sta <r1>; asl A; asl A; asl A; asl A; sta <r0>
  
  # Second Nibble (X)
  txa
  ## convert to lowercase
  ora %0010_0000
  ## test
  cmp '0'; bcc (nosecondnibble)
  sec; sbc $30; cmp $0A; bcc (notletterHi)
    sec; sbc $27
    cmp $10; bcs (nosecondnibble)
  __notletterHi
  
  # Return
    ora <r0>
    sec; rts
  __nosecondnibble
    lda <r1>
    sec; rts
  __fail
    lda 0
    clc; rts

_BinToDecPrintZ
    jsr [BinToDec]
    ldx 0
    __print
    lda <r2+X>; phx; jsr [COUT]; plx
    inc X; cpx 5; bne (print)
rts
_BinToDecPrint
    jsr [BinToDec]
    ldx 0
    __findstart
    lda <r2+X>; cmp '0'; bne (print)
    inc X; cpx 4; bne (findstart)
    __print
    lda <r2+X>; phx; jsr [COUT]; plx
    inc X; cpx 5; bne (print)
rts
_BinToDec
    # Input: R0-R1
    # Output: R2~R6
    ldy 0
    ldx 0
    lda '0'
    sta <r2+0>; sta <r2+1>; sta <r2+2>; sta <r2+3>; sta <r2+4>
    
    __loop
        lda <r1>; cmp [tableHi+X]
            bcc (break)
            bne (continue)
        lda <r0>; cmp [tableLo+X]
            bcc (break)
        __continue
        inc <r2+X>
        sec
        lda <r0>; sbc [tableLo+X]; sta <r0>
        lda <r1>; sbc [tableHi+X]; sta <r1>
    bra (loop)
    __break
    inc Y; inc Y; inc Y
    inc X; cpx 5;bne (loop)
rts
__tableHi
.byte 10000.hi, 1000.hi, 100.hi, 10.hi, 1.hi
__tableLo
.byte 10000.lo, 1000.lo, 100.lo, 10.lo, 1.lo

_FileOUT
rts

_FileIN
rts
