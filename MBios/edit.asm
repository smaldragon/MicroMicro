# A Gap Buffer Code Editor
.val MEMTOP $8000
.val MEMBOT $2000
.zp BotPTR 2
.zp TopPTR 2
_Edit
__Init
  jsr [Edit_New]
  lda FF; jsr [COUT]
  ldx 0; lda $FF
  ___loop
    sta [$1F00+X]
  inc X; bne (loop)
  #lda $30; sta <BotPTR+1>
__Main
  jsr [CalcSize]
  jsr [CalcSize]
  ___poll
  jsr [CIN]; beq (poll)
  
  cmp LF; beq (lf)
  cmp BS; beq (bs)
  cmp AUP; beq (aup)
  cmp ALF; beq (alf)
  cmp 32; bcc (Main)
  __IncPTR
  ldy 0; sta [<BotPTR>+Y]
  inc <BotPTR+0>; bne (noinc)
    inc <BotPTR+1>
  __noinc
  jsr [COUT]
  jsr [UpdateCurLine]
  lda <Cursor+1>; cmp 29; bcc (noscroll)
  lda 30; sta <r0>; stz <r1>; lda 1; sta <r2>; jsr [ScrollCustom]
  __noscroll
bra (Main)
__alf
jmp [ialf]
__bs
jmp [ibs]
__aup
  jmp [Main]
__lf
  lda <Cursor+0>; pha
  lda <Cursor+1>; pha
  
  jsr [PadCurLine]
  
  
  #jsr [SlowScroll]
  #pla; sta <Cursor+1>; pha
  
  
  pla; sta <Cursor+1>
  pla; sta <Cursor+0>
  lda CR; jsr [COUT]; lda LF
jmp [IncPTR]
__ialf
  jsr [COUT]
  
  lda <BotPTR+1>; cmp $20; bne (good)
  lda <BotPTR+0>; bne (good)
    jmp [Main]
  ___good
  lda <BotPTR+0>; bne (BotOver)
    dec <BotPTR+1>
  __BotOver
  dec <BotPTR+0>
  
  lda <TopPTR+0>; bne (TopOver)
    dec <TopPTR+1>
  __TopOver
  dec <TopPTR+0>
  ldy 0; lda [<BotPTR>+Y]
  ldy 0; sta [<TopPTR>+Y]
jmp [CursorAdjust]

__ibs
  lda <BotPTR+0>; cmp $00; bne (noback)
  lda <BotPTR+1>; cmp $20; bne (noback)
    lda BEL; jsr [COUT]; jmp [Main]
  ___noback
  lda <BotPTR+0>; bne (nodec)
    dec <BotPTR+1>
  ___nodec
  dec <BotPTR+0>
  
  ldy 0; lda [<BotPTR>+Y]; cmp LF; beq (lineend) 
  lda BS; jsr [COUT]
jsr [UpdateCurLine]; jmp [Main]
___lineend
  lda DEL; jsr [COUT]
  
__CursorAdjust
  lda <Cursor+0>; bne (next)
    dec <Cursor+1>
  ___next
  # Adjust Cursor X, r0 is a temp pointer
  ldx 0; ldy 0
  lda <BotPTR>; sta <r0>
  lda <BotPTR+1>; sta <r1>
  ___loop
    
    lda <r0>; cmp MEMBOT.lo; bne (nobreak)
    lda <r1>; cmp MEMBOT.hi; bne (nobreak)
      bra (break)
    ___nobreak
    lda <r0>; bne (nodec1)
      dec <r1>
    ___nodec1
    dec <r0>
    lda [<r0>+Y]; cmp LF; beq (break)
  inc X; bra (loop)
  ___break
  txa; and %0011_1111; sta <Cursor+0>
  #jsr [FixScrollDown]
jmp [Main]

__UpdateCurLine
  lda <TopPTR+0>; sta <r4>
  lda <TopPTR+1>; sta <r5>
  lda <Cursor+0>; sta <r6>; pha
  lda <Cursor+1>; pha
  
  ___loop
  lda <r5>; cmp MEMTOP.hi; beq (return)
    lda DEL; jsr [COUT]
    
    ldy 0; lda [<r4>+Y]
    cmp LF; beq (return); jsr [COUT]
    
    inc <r4>; bne (noinc)
      inc <r5>
    ____noinc
  inc <r6>; bra (loop)
___return
  jsr [PadCurLine]
  
  pla; sta <Cursor+1>
  pla; sta <Cursor+0>
rts

__PadCurLine
  lda 0; jsr [COUT]
  lda <Cursor+1>; cmp 30; bcc (return)
    lda DEL; jsr [COUT]
  inc <Cursor+0>; lda <Cursor+0>; cmp 64; bne (PadCurLine)
  ___return
  stz <Cursor+0>
rts

__CalcSize
  sec
  lda <TopPTR+0>; sbc <BotPTR+0>; sta <r0>
  lda <TopPTR+1>; sbc <BotPTR+1>; sta <r1>
  #lda <BotPTR+0>; sta <r0>
  #lda <BotPTR+1>; sta <r1>
  
  
  lda <Cursor+0>; pha
  lda <Cursor+1>; pha
  
  lda 60; sta <Cursor+0>
  lda 29; sta <Cursor+1>
  lda CHI; jsr [COUT]
  
  lda <r0>; pha
  
  lda <r1>
  jsr [HexToAscii]; phx; pha
  lda DEL;  jsr [COUT]
  pla;      jsr [COUT]
  lda DEL;  jsr [COUT]
  pla; jsr [COUT]
  
  pla
  jsr [HexToAscii]; phx; pha
  lda DEL;  jsr [COUT]
  pla;      jsr [COUT]
  lda DEL;  jsr [COUT]
  pla; jsr [COUT]
  
  lda CNO; jsr [COUT]
  
  pla; sta <Cursor+1>
  pla; sta <Cursor+0>
rts
__New
  lda MEMTOP.lo; sta <TopPTR+0>
  lda MEMTOP.hi; sta <TopPTR+1>
  lda MEMBOT.lo; sta <BotPTR+0>
  lda MEMBOT.hi; sta <BotPTR+1>
  lda 0; tay
  sta [<BotPTR>+Y]
  
rts
