; ---------------------------------------------------------------------------
; init.s - 6502 initializer for up5k_basic project
; 2019-03-20 E. Brombaugh
; Note - requires 65C02 support
; ---------------------------------------------------------------------------
;

.import		_acia_init
.import		_video_init
.import		_spi_init
.import		_ledpwm_init
.import		_ps2_init
.import		_basic_init
.import		_cmon
.import		_input
.import		_output
.import		_strout
.import		BAS_COLDSTART
.import		BAS_WARMSTART

; ---------------------------------------------------------------------------
; Reset vector

_init:		ldx	#$28				; Initialize stack pointer to $0128
			txs
			cld						; Clear decimal mode

; ---------------------------------------------------------------------------
; Init ACIA
			jsr _acia_init
			
; ---------------------------------------------------------------------------
; Init video
			jsr _video_init

; ---------------------------------------------------------------------------
; Startup Message
			lda #.lobyte(startup_msg)
			ldy #.hibyte(startup_msg)
			jsr _strout
			
; ---------------------------------------------------------------------------
; Init spi
			jsr _spi_init

; ---------------------------------------------------------------------------
; Init led pwm
			jsr _ledpwm_init

; ---------------------------------------------------------------------------
; Init ps2 input
			jsr _ps2_init

; ---------------------------------------------------------------------------
; Init BASIC
			jsr _basic_init

; ---------------------------------------------------------------------------
; display boot prompt

bp:
			lda #.lobyte(bootprompt)
			ldy #.hibyte(bootprompt)
			jsr _strout
			
; ---------------------------------------------------------------------------
; Cold or Warm Start

bpdone:		jsr _input				; get char
			jsr _output				; echo
			jsr _output				; echo - why needed twice?
			and #$5F				; convert lowercase to uppercase
			cmp #'D'				; D ?
			beq diags				; Diagnostic
bp_skip_D:	cmp #'C'				; C ?
			bne bp_skip_C
			jmp BAS_COLDSTART		; BASIC Cold Start
bp_skip_C:	cmp #'W'				; W ?
			bne bp_skip_W
			jmp BAS_WARMSTART		; BASIC Warm Start
bp_skip_W:	cmp #'M'				; M ?
			bne bpdone
			; fall thru to monitor
			
; ---------------------------------------------------------------------------
; Enter Machine-language monitor

			; help msg
			lda #.lobyte(montxt)	; display monitor text
			ldy #.hibyte(montxt)
			jsr _strout
			
			; run the monitor
			jsr _cmon
			bra _init				; back to full init

; ---------------------------------------------------------------------------
; Diagnostics - currently unused

diags:		lda #.lobyte(diagtxt)	; display diag text
			ldy #.hibyte(diagtxt)
			jsr _strout
			bra bp					; back to boot prompt

; ---------------------------------------------------------------------------
; Non-maskable interrupt (NMI) service routine

_nmi_int:	RTI						; Return from all NMI interrupts

; ---------------------------------------------------------------------------
; Maskable interrupt (IRQ) service routine

_irq_int:	pha						; Save accumulator contents to stack
			phx						; Save X register contents to stack
			phy						; Save Y register to stack
		   
; ---------------------------------------------------------------------------
; check for BRK instruction

			tsx						; Transfer stack pointer to X
			lda $104,X				; Load status register contents (SP + 4)
			and #$10				; Isolate B status bit
			bne break				; If B = 1, BRK detected

; ---------------------------------------------------------------------------
; Restore state and exit ISR

irq_exit:	ply						; Restore Y register contents
			plx						; Restore X register contents
			pla						; Restore accumulator contents
			rti						; Return from all IRQ interrupts

; ---------------------------------------------------------------------------
; BRK detected, stop

break:		jmp break				; If BRK is detected, something very bad
									;   has happened, so loop here forever
									
; ---------------------------------------------------------------------------
; Message Strings

startup_msg:
.byte		" ", 10, 13, "up5k_vga starting...", 0

bootprompt:
.byte		10, 13, "D/C/W/M? ", 0

diagtxt:
.byte		10, 13, "Diagnostics not available", 0

montxt:
.byte		10, 13, "C'MON Monitor", 10, 13
.byte		"AAAAx - examine 128 bytes @ AAAA", 10, 13
.byte		"AAAA@DD,DD,... - store DD bytes @ AAAA", 10, 13
.byte		"AAAAg - go @ AAAA", 10, 13, 0

; ---------------------------------------------------------------------------
; table of vectors for 6502

.segment  "VECTORS"

.addr      _nmi_int					; NMI vector
.addr      _init					; Reset vector
.addr      _irq_int					; IRQ/BRK vector
