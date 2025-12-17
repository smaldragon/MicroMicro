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
  lda 'p'; jsr [$FF03]
  lda 'o'; jsr [$FF03]
  lda 'n'; jsr [$FF03]
  lda 'g'; jsr [$FF03]
  lda NL; jsr [$FF03]  # newline
rts
_cECHO
  jsr [$FF09]
  __loop
  phx; phy
    lda <$00+X>; jsr [$FF03]
  ply; plx
  inc X; dec Y; bne (loop)
  __done
  lda NL; jsr [$FF03]
rts
.pad [$E000]