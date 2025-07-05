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
.zp EXTRATBL 2
#.zp FSIZE 2 using BotPTR for now instead
.zp FNAME 9
.zp RUNCODE 4

.val MAXSIZE $6000

.val InputSize 63
.zp Input InputSize+1
.zp InputL


.org [$E000]
  .asm stdio
  .asm edit
  .asm lang
_RESET
  sei; cld
  lda $40; sta <NMI>        # RTI
  
  # -- Clock Speed Calc, stores (clock cyles in a irq)/16 in <rF>
  ## 8 = 2Mhz
  ## 16 = 4Mhz
  ## 32 = 8Mhz
  # align with next irq
  wai
  # interrupt subroutine takes exactly 16 cycles
  lda $65; sta <IRQ+0>      # ADC zp
  lda 0;   sta <IRQ+1>      
  lda $40; sta <IRQ+2>      # RTI
  lda 1;   sta <r0>
  
  # wait loop until the end of the current irq
  ldx 0
  __wait
  inc X; bne (wait)
  
  # activate the irq subroutine
  lda 0
  clc
  cli
  wai
  sta <rF>
  
  jsr [STDIOINIT]
  
  lda <RUNCODE+0>;cmp 'R'; bne (cold)
  lda <RUNCODE+1>;cmp 'u'; bne (cold)
  lda <RUNCODE+2>;cmp 'n'; bne (cold)
  lda <RUNCODE+3>;cmp '!'; bne (cold)
    bra (warm)
  __cold
  jsr [Edit_New]
  stz <FNAME>
  __warm
  lda 'R'; sta <RUNCODE+0>
  lda 'u'; sta <RUNCODE+1>
  lda 'n'; sta <RUNCODE+2>
  lda '!'; sta <RUNCODE+3>
  
_INIT
  lda 32; jsr [BEEP]
  lda 24; jsr [BEEP]
  
  lda string1.lo; sta <r4>
  lda string1.hi; sta <r5>
  jsr [SOUT]
  clc; lda <rF>; lsr A; lsr A; adc $30; jsr [COUT]
  lda string2.lo; sta <r4>
  lda string2.hi; sta <r5>
  jsr [SOUT]
  
  
  # By default EXTRATBL points to a zero byte within itself
  lda EXTRATBL.lo+1; sta <EXTRATBL>
  lda 0; sta <EXTRATBL+1>
  
  #lda TestCmdTable.lo; sta <EXTRATBL+0>
  #lda TestCmdTable.hi; sta <EXTRATBL+1>
  
  # Check for CART-RUN
  lda [$C000]; cmp 'C'; bne (MAIN)
  lda [$C001]; cmp 'A'; bne (MAIN)
  lda [$C002]; cmp 'R'; bne (MAIN)
  lda [$C003]; cmp 'T'; bne (MAIN)
  lda [$C004]; cmp '-'; bne (MAIN)
  lda [$C005]; cmp 'R'; bne (MAIN)
  lda [$C006]; cmp 'U'; bne (MAIN)
  lda [$C007]; cmp 'N'; bne (MAIN)
    jsr [$C008]
    
_MAIN
  jsr [cFILE]
  jsr [cHELP]
  stz <InputL>
  lda '>'; jsr [COUT]
    
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
  ldx <InputL>; lda $00; sta <Input+X>
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

_hInputH8
	# -- Parse an 8bit value hex value from input
	# in:
	#	X→Input Index
	# out:
	#	X→Incremented Input Index
	#	C→Successful
	#	A→Parsed Value
	
	dec X
	__skipspaces
		inc X
		cpx InputSize-1; bcs (fail)
		lda <Input+X>; beq (fail)

	cmp ' '; beq (skipspaces)
	
	# Read Input
	lda <Input+X>; sta <0>
	inc X
	lda <Input+X>; sta <1>
	inc X
	
	phx; lda <0>; ldx <1>
	jsr [AsciiToHex]
	plx; bcc (fail)
	
	__succ
	sec; rts
	__fail
	clc; rts

_cUNKNOWN
  SPrint string_unknown
rts

_cHELP
  SPrint string_help
  sei
  ldx 0
  __loop
    lda [CmdTable+X]; beq (done)
    phx
    SPrint string_list
    plx
    ldy 6
    ___print
      phy; phx; lda [CmdTable+X]; jsr [COUT]; plx; ply
    sei; inc X; dec Y; bne (print)
    inc X; inc X
    phx
    #lda CR; jsr [COUT]
    #lda LF; jsr [COUT]
    plx
  bra (loop)
  ___done
  ldy 0
  __extraloop
    lda [<EXTRATBL>+Y]; beq (done)
    phy
    SPrint string_list
    ply
    ldx 6
    ___print
      phy;phx; lda [<EXTRATBL>+Y]; jsr [COUT]; plx; ply
    sei; inc Y; dec X; bne (print)
    inc Y; inc Y
  bra (extraloop)
  __done
  cli
  lda CR; jsr [COUT]
  lda LF; jsr [COUT]
rts
#jmp [MAIN]


_cFILE
  lda <FNAME>; beq (unnamedfile)
  lda CHI; jsr [COUT]
  lda FNAME.lo; sta <r4>; stz <r5>
  jsr [SOUT]
  lda CNO; jsr [COUT]
  bra (continue)
  __unnamedfile
  lda txtun.lo; sta <r4>; lda txtun.hi; sta <r5>
  jsr [SOUT]
  __continue
  lda ' '; jsr [COUT]
  sec
  lda <BotPTR+0>; sbc $2000.lo; sta <r0>
  lda <BotPTR+1>; sbc $2000.hi; sta <r1>
  jsr [BinToDecPrint]
  lda txt2.lo; sta <r4>
  lda txt2.hi; sta <r5>
  jsr [SOUT]
rts
__txt2
.byte ' bytes',CR,LF,CR,LF,$00
__txtun
.byte "<untitled>"

_cCLEAR
  lda FF; jsr [COUT]
rts

_cNEW
  jsr [Edit_New]
  lda $2000.lo; sta <BotPTR+0>
  lda $2000.hi; sta <BotPTR+1>
  stz <FNAME>
  jmp [cFILE]

_cNAME
  ldx 5
  ldy 0
  
  __findstart
    lda <Input+X>; beq (done)
    cmp ' '; bne (cmdStart)
  inc X; cpx <InputL>; beq (done); bra (findstart)
  __cmdStart
    lda <Input+X>; sta [FNAME+Y]
    inc Y; inc X
  cpx <InputL>; beq (done); cpy 8; beq (done); bra (cmdStart)
  __done
  lda 0; sta [FNAME+Y]
  jmp [cFILE]

_cEDIT
	jsr [Edit]
rts

_cSEND
  lda $2000.lo; sta <r0>
  lda $2000.hi; sta <r1>
  lda <BotPTR+0>; sta <r2>
  lda <BotPTR+1>; sta <r3>
  jmp [FileOUT]
  
_cLOAD
jmp [FileIN]


# ------------------------------
# Memory Monitor Functions
_cPRUN
    # -- Run a "program" at specified address
	ldx 4
	jsr [hInputH8]; bcc (break)
		sta <r2>
	jsr [hInputH8]; bcc (break)
		sta <r1>
	lda $4C # (opcode for JMP)
	    sta <r0>
	jsr [r0]
__break
rts
_cPOKE
	ldx 4
	jsr [hInputH8]; bcc (break)
		sta <r7>
	jsr [hInputH8]; bcc (break)
		sta <r6>
		
    ldy 0
	__WriteLoop
		jsr [hInputH8]; bcc (break)
		sta [<r6>+Y]
    inc Y; bra (WriteLoop)
__break
rts

_cPEEKExit
  rts
_cPEEK
  ldx 4
  jsr [hInputH8]; bcc (cPEEKExit)
    sta <r6>
  jsr [hInputH8]; bcc (cPEEKExit)
	sta <r5>
  
  stz <r7>; stz <r8>
  jsr [hInputH8]; bcc (nolimit)
	sta <r7>; sta <r8>
  __nolimit
  
  __bigloop
  ldy $00
  ldx $10
  
  __loop
    phx; phy; lda [<r5>+Y]
    jsr [HexToAscii]
    phx; jsr [COUT]
    pla; jsr [COUT]
    lda ' '; jsr [COUT]
    
    dec <r7>; bne (nobreak)
    pla; pla
    bra (break)
    ___nobreak
    
    # Write Ascii repr
  ply; inc Y; plx; dec X; bne (loop)
  ___break
  
  lda 48; sta <CursorX>
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
    
    dec <r8>; bne (nobreak)
    pla; pla
    bra (break)
    ___nobreak
    
  ply; inc Y; plx; dec X; bne (loop2)
  
    clc
    lda <r5>; adc $10; sta <r5>
    lda <r6>; adc $00; sta <r6>
  bra (bigloop)
  __break
  lda LF; jsr [COUT]
  lda CR; jsr [COUT]
rts



_CmdRun
  ldx 0
  __loop
    ldy 0
    lda [CmdTable+X]; bne (continue)
      jmp [ExtraCmdRun]
    __continue
    
    __MatchLoop
      lda [CmdTable+X]; cmp ' '; beq (checkmatch)
      cmp [Input+Y]; bne (next)
    inc X; inc Y; bra (MatchLoop)
    ___checkmatch
    	lda [Input+Y]; beq (matched)
    	cmp ' '; beq (matched)
    ___next
      clc; txa; and %1111_1000; adc 8; tax; bra (loop)
    
    # We Matched
    ___matched
    txa; and %1111_1000; ora %0000_0110; tax
    jmp [[CmdTable+X]]
_ExtraCmdRun
  ldy 0
  __loop
    ldx 0
    lda [<EXTRATBL>+Y]; bne (continue)
      jmp [cUNKNOWN]
    __continue
    
    __MatchLoop
      lda [<EXTRATBL>+Y]; cmp ' '; beq (checkmatch)
      cmp [Input+X]; bne (next)
    inc X; inc Y; bra (MatchLoop)
    ___checkmatch
    	lda [Input+X]; beq (matched)
    	cmp ' '; beq (matched)
    ___next
      clc; tya; and %1111_1000; adc 8; tay; bra (loop)
    
    # We Matched
    ___matched
    tya; and %1111_1000; ora %0000_0110; tay
    lda [<EXTRATBL>+Y]; sta <0>; inc Y
    lda [<EXTRATBL>+Y]; sta <1>
    jmp [[0]]
_CmdTable
    .byte 'help  '; .word cHELP
    .byte 'clear '; .word cCLEAR

    .byte 'file  '; .word cFILE
    .byte 'new   '; .word cNEW
    .byte 'name  '; .word cNAME
    .byte 'edit  '; .word cEDIT
    .byte 'save  '; .word FileOUT
    .byte 'load  '; .word FileIN

    .byte 'peek  '; .word cPEEK
    .byte 'poke  '; .word cPOKE
    .byte 'prun  '; .word cPRUN
    
    .byte $00
# Used for testing the extra command table
#_TestCmdTable
#    .byte 'helpi '; .word cHELP
#    .byte 'helpu '; .word cFILE
#    .byte $00

_string1
.byte FF, CHI,' MicroMicro ',CNO, " 24KiB "
_string2
.byte 'MHz',CR,LF,CR,LF,$00
_string_help
.byte 'Commands:',CR,LF,$00
_string_list
.byte " *"
_string_unknown
.byte 'Unknown Command',BEL,CR,LF,$00
_string_new
.byte 'New File Created',CR,LF,$00

.pad [$FEFD]
_FunctionTable
jmp [[$FF00+X]]
.word CIN
.word COUT
.word BEEP

.pad [VECTORS]
.word NMI
.word RESET
.word IRQ
