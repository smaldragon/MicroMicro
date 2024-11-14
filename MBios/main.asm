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
  
  
  # Setup Keyboard Routine
  sei
  lda $4C; sta <IRQ>        # JMP abs
  lda KReadINT.lo; sta <IRQ+1>
  lda KReadINT.hi; sta <IRQ+2>
  cli
ldx 0
stz <KInpPtr>
_INIT
  lda string1.lo; sta <r4>
  lda string1.hi; sta <r5>
  jsr [SOUT]
  clc; lda <rF>; lsr A; lsr A; adc $30; jsr [COUT]
  lda string2.lo; sta <r4>
  lda string2.hi; sta <r5>
  jsr [SOUT]
__fim
	lda 0
	jsr [CIN]; beq (fim)
	jsr [COUT]
jmp [fim]
stp

_SOUT
  ldy 0
__loop
  
  lda [<r4>+Y]; beq(break)
  phy
  jsr [COUT]
  ply;inc Y; bne (loop)
__break
rts

_string1
.byte FF,'MicroMicro 24KiB ',$00
_string2
.byte 'MHz',CR,LF,">"
.pad [VECTORS]
.word NMI
.word RESET
.word IRQ
