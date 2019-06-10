; ---------------------------------------------------------------------------
; video.s - video interface routines
; 2019-03-20 E. Brombaugh
; Note - requires 65C02 support
; ---------------------------------------------------------------------------
;

.export		_video_init
.export		_video_chrout

; ---------------------------------------------------------------------------
; video initializer

.proc _video_init: near
			lda vidtab				; initial cursor location
			sta $0200
			ldy #2					; two passes through the fill
			lda #1					; switch to color region
			sta $F600
			lda #$F3				; white/blue in color region

; fill loop
vi_loop:	stz $e0					; init ptr
			ldx #$D0
			stx $e1
vi_lp2:		sta ($e0)				; save to ptr loc
			inc $e0					; inc low addr
			bne vi_lp2				; loop until wrap
			inc $e1					; inc high addr
			ldx $e1
			cpx #$F0				; done?
			bne vi_lp2				; no, keep looping
			
vi_lp2_end: stz $F600				; switch to glyph region
			lda #$20				; space in glyph region
			dey
			bne vi_loop				; rerun the fill loop
			rts
.endproc

; ---------------------------------------------------------------------------
; video character output for VGA 100x75 display

.proc _video_chrout: near
			sta $0202		; save output char
			pha				; save regs
			phx
			phy
			beq vco_end		; skip to end if null chr
			cmp #$08
			beq vco_bksp	; handle backspace
			cmp #$0A
			beq vco_lf		; handle linefeed
			cmp #$0D		; is it a carriage return?
			bne vco_norm	; no - send normal char to video
			jsr vco_cr1		; handle carriage return normally
			bra vco_end		; skip to end

vco_norm:	sta $0201		; save char in-process
			jsr vco_vout	; output to video memory
			inc $0200
			lda $FFE1		; get default width
			clc
			adc $FFE0		; add to default starting loc
			cmp $0200		; compare to current position
			bmi vco_autocr	; if over then do auto carriage return
vco_nxt:	jsr vco_cr3		; carriage return entry 3

vco_end:	ply				; restore regs
			plx
			pla
			rts
; .......................................................................
; video text output handle backspace
vco_bksp:	ldx $0200		; get current cursor pos
			cpx $FFE0		; compare to initial pos
			beq vco_end		; exit w/o change if equal
			lda #$20		; erase current cursor
			jsr vco_vout1
			dex
			stx $0200		; decrement cursor loc
			lda #$5F		; draw new cursor
			jsr vco_vout1
			bra vco_end		; exit

; .......................................................................
; video text output handle auto carriage return when line length exceeded
vco_autocr: jsr vco_cr2		; handle auto cr w/o char

; .......................................................................
; video text output handle linefeed
vco_lf:		jsr vco_vout	; output char to video mem
			lda $FFE0		; get default cursor loc
			and #$E0		; set 5 lsbits to 0
			sta $0202		; save
			ldx #$07		; copy modifiable code to pg 2 RAM
vco_lflp0:	lda vco_zp,X
			sta $0207,X
			dex
			bpl vco_lflp0
			ldx #$EC		; get high addr for 7.5k
			lda #$64		; set incr to 100
vco_lfskp:	sta $0208		; save incr as low addr of src in RAM routine
			ldy #$00		; init ptr
vco_lflp1:	jsr $0207		; scroll char
			bne vco_lflp1	; loop 256x
			inc $0209		; inc src high addr
			inc $020C		; inc dst high addr
			cpx $0209		; src addr > limit?
			bne vco_lflp1	; no, keep looping
vco_lflp2:	jsr $0207		; yes, scroll again
			cpy $0202		; lsbyte addr done?
			bne vco_lflp2	; no, keep scrolling
			lda #$20		; load last line with spaces
vco_lflp3:	jsr $020A		; 
			dec $0208		;
			bne vco_lflp3	; keep looping
			bra vco_nxt		; done - restore cursor position.


; ---------------------------------------------------------------------------
; video text output char to vidmem routine
vco_vout:	ldx $0200		; get cursor loc
			lda $0201		; get char
vco_vout1:	sta $EC00,X		; 1k output
			rts


; ---------------------------------------------------------------------------
; video text output carriage return routine

vco_cr1:	jsr vco_vout	; output to video memory
vco_cr2:	lda $FFE0		; get default cursor location
			sta $0200		; store it in live location
vco_cr3:	ldx $0200		; get cursor loc
			lda $EC00,X		; get contents of video mem @ cursor loc for 1k
			sta $0201		; save it
			lda #$5F		; underline char
			bra vco_vout1	; output to video memory


; ---------------------------------------------------------------------------
; video text output zp scrolling code

vco_zp:		lda $D000,Y
			sta $D000,Y
			iny
			rts
.endproc

; ---------------------------------------------------------------------------
; table of data for video driver

.segment  "VIDTAB"

vidtab:
.byte		$2c					; $FFE0 - default starting cursor location
.byte		$48					; $FFE1 - default width
.byte		$00					; $FFE0 - vram size: 0 for 1k, !0 for 2k


