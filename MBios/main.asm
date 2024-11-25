# -------------------------
.cpu 65c02
# Global Temp Registers
.zp r0
.zp r1
.zp r2
.zp r3
.zp r4
.zp r5
.zp r6
.zp r7
.zp r8
.zp r9
.zp rA
.zp rB
.zp rC
.zp rD
.zp rE
.zp rF
.zp IRQ 3
.zp NMI 3
.zp FSIZE 2
.val MAXSIZE $6000

.val InputSize 63
.zp Input InputSize+1
.zp InputL


.org [$E000]
  .asm stdio
  .asm edit
  .asm lang
_RESET
  lda $40; sta <NMI>        # RTI
  
  # Speed Calc
  wai
  lda $65; sta <IRQ+0>      # ADC zp
  lda 0;   sta <IRQ+1>      
  lda $40; sta <IRQ+2>      # RTI
  lda 1;   sta <r0>
  
  ldx 0
  __wait
  inc X; bne (wait)
  lda 0
  clc
  cli
  wai
  sta <rF>
  
  jsr [STDIOINIT]

_INIT
  lda string1.lo; sta <r4>
  lda string1.hi; sta <r5>
  jsr [SOUT]
  clc; lda <rF>; lsr A; lsr A; adc $30; jsr [COUT]
  lda string2.lo; sta <r4>
  lda string2.hi; sta <r5>
  jsr [SOUT]
  
  jsr [cHELP]
  stz <InputL>
  lda '>'; jsr [COUT]
_MAIN
__fim
  lda 0
  jsr [CIN]; beq (fim)
  
  cmp LF; beq (lf)
  cmp BS; beq (bs)
  
  pha
  lda <InputL>; cmp InputSize; beq (inputfull)
  pla;pha
  jsr [COUT]
  pla
  ldx <InputL>; sta <Input+X>; inc <InputL>
bra (fim)
___lf
  jsr [COUT]
  lda  CR; jsr [COUT]
  ldx <InputL>; lda ' '; sta <Input+X>
  jsr [CmdRun]
  stz <InputL>
  lda '>'; jsr [COUT]
bra (fim)
___bs
  pha
  lda <InputL>; beq (inputfull)
  dec <InputL>
  pla
  jsr [COUT]
bra (fim)
___inputfull
  lda BEL; jsr [COUT]
bra (fim)

_SOUT
  ldy 0
__loop
  lda [<r4>+Y]; beq(break)
  phy
  jsr [COUT]
  ply;inc Y; bne (loop)
__break
rts

_cUNKNOWN
  lda string_unknown.lo; sta <r4>
  lda string_unknown.hi; sta <r5>
  jsr [SOUT]
rts

_cHELP
  lda string_help.lo; sta <r4>
  lda string_help.hi; sta <r5>
  jsr [SOUT]
  sei
  ldx 0
  __loop
    
    lda [CmdTable+X]; beq (done)
    lda string_list.lo; sta <r4>
    lda string_list.hi; sta <r5>
    phx; jsr [SOUT]; plx
    ldy 6
    __print
      phy; phx; lda [CmdTable+X]; jsr [COUT]; plx; ply
    sei; inc X; dec Y; bne (print)
    inc X; inc X
    phx
    #lda CR; jsr [COUT]
    #lda LF; jsr [COUT]
    plx
  bra (loop)
  __done
  cli
  lda CR; jsr [COUT]
  lda LF; jsr [COUT]
rts
#jmp [MAIN]


_cCLEAR
  lda FF; jsr [COUT]
rts

_cNEW
  stz <FSIZE+0>; stz <FSIZE+1>
  lda string_new.lo; sta <r4>
  lda string_new.hi; sta <r5>
  jsr [SOUT]
rts

_cSIZE
  sec
  lda MAXSIZE.lo; sbc <FSIZE+0>; sta <r0>
  lda MAXSIZE.hi; sbc <FSIZE+1>; sta <r1>
  
  sed
  lda <r0>; and $0F; adc 0; sta <r2>
  lda <r0>; lsr A; lsr A; lsr A; lsr A; tax
  __loop
  cpx 0; beq (next)
    clc
    lda <r2>; adc $16; sta <r2>
    lda <r3>; adc 00; sta <r3>
  dec X; bra (loop)
  
  __next
  lda <r1>; and $0F; tax
  cpx 0; beq (next)
    clc
    lda <r2>; adc $56; sta <r2>
    lda <r3>; adc $02; sta <r3>
    lda <r4>; adc $00; sta <r4>
  dec X; bra (loop)
  __next
  lda <r1>; and $F0; lsr A; lsr A; lsr A; tax
  cpx 0; beq (next)
    clc
    lda <r2>; adc $96; sta <r2>
    lda <r3>; adc $40; sta <r3>
    lda <r4>; adc $00; sta <r4>
  dec X; bra (loop)
  __next
rts

_cEDIT
	jsr [Edit]
rts

_cPEEK

  lda 16; sta <r4>
  
  lda <Input+5>
  ldx <Input+6>
  jsr [AsciiToHex]
  sta <r6>
  lda <Input+7>
  ldx <Input+8>
  jsr [AsciiToHex]
  sta <r5>
  
  #lda $80; sta <r5>
  #lda $00; sta <r6>
  
  __bigloop
  ldy $00
  ldx $10
  __loop
    phx; phy; lda [<r5>+Y]
    jsr [HexToAscii]
    phx; jsr [COUT]
    pla; jsr [COUT]
    lda ' '; jsr [COUT]
    
    # Write Ascii repr
  ply; inc Y; plx; dec X; bne (loop)
  
  ldy $00
  ldx $10
  __loop2
    phx; phy
    ldx ' '
    lda [<r5>+Y]
    bmi (notchar)
    cmp $20; bcc (notchar)
    cmp $7F; beq (notchar)
      tax
    __notchar
    txa; jsr [COUT]
  ply; inc Y; plx; dec X; bne (loop2)
  
  dec <r4>; beq (break)
    clc
    lda <r5>; adc $10; sta <r5>
    lda <r6>; adc $00; sta <r6>
  bra (bigloop)
  __break
  lda LF; jsr [COUT]
  lda CR; jsr [COUT]
rts

_CmdTable
.byte 'help  '; .word cHELP
.byte 'clear '; .word cCLEAR
.byte 'new   '; .word cNEW
.byte 'edit  '; .word cEDIT
.byte 'peek  '; .word cPEEK
.byte $00

_CmdRun
  ldx 0
  __loop
    ldy 0
    lda [CmdTable+X]; bne (continue)
      jmp [cUNKNOWN]
    __continue
    
    __MatchLoop  
      lda [CmdTable+X]
      cmp [Input+Y]; bne (next)
      cmp ' '; beq (matched)
      #lda $FF; sta [$1F00+X]
    inc X; inc Y; bra (MatchLoop)
    __next
      clc; txa; and %1111_1000; adc 8; tax; bra (loop)
    __matched
      # We Matched
      #jmp [cHELP]
      txa; and %1111_1000; ora %0000_0110; tax; jmp [[CmdTable+X]]
_string1
.byte FF,BEL, CHI,' MicroMicro ',CNO, " 24KiB "
_string2
.byte 'MHz',CR,LF,$00
_string_help
.byte 'Commands:',CR,LF,$00
_string_list
.byte " *"
_string_unknown
.byte 'Unknown Command',BEL,CR,LF,$00
_string_new
.byte 'New File Created',CR,LF,$00
.pad [VECTORS]
.word NMI
.word RESET
.word IRQ
