# ---------------------------------
# This is an example Command Cart, it adds the command "ping" and "echo" using the bios interfaces
.cpu 65C02

.val NL $0A

.val CHI $10
.val CNO $11
.val FON $12
.val FOF $13

.val COUT   $FF03
.val CMDIN  $FF09
.val GETCURSOR $FF0C
.val SETCURSOR $FF0F

.org [$C000]
.byte 'CART-CMD'
.byte 'ping  '; .word cPING
.byte 'echo  '; .word cECHO
.byte 'footer'; .word cFOOTER
.byte $00
_cPING
  lda 'p'; jsr [COUT]
  lda 'o'; jsr [COUT]
  lda 'n'; jsr [COUT]
  lda 'g'; jsr [COUT]
  lda NL; jsr [COUT]
rts
_cECHO
  jsr [CMDIN]
  __loop
  phx; phy
    lda <$00+X>; jsr [COUT]
  ply; plx
  inc X; dec Y; bne (loop)
  __done
  lda NL; jsr [COUT]
rts
_cFOOTER
  lda FOF; jsr [COUT]
  jsr [GETCURSOR]; phx; phy
  
  ldx 0; ldy 29; jsr [SETCURSOR]
  
  __sendText
  lda [text+X]; beq (break); jsr [COUT]
  inc X; cpx 64; bne (sendText)
  ___break
  ply; plx; jsr [SETCURSOR]
  lda FON; jsr [COUT]
  lda CNO; jsr [COUT]
rts
__text
.byte CHI,"My cool awesome footer"
.pad [$E000]