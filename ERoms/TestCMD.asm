# ---------------------------------
# This is an example Command Cart, it adds the command "ping" and "echo" using the bios interfaces
.cpu 65C02

.val NL $0A
.val COUT   $FF03
.val CMDIN  $FF09

.org [$C000]
.byte 'CART-CMD'
.byte 'ping  '; .word cPING
.byte 'echo  '; .word cECHO
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
.pad [$E000]