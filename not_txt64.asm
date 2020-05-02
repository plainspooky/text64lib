;
;   TXT64 version 1
;

;
;   This is a experimental code and of course that has a lot of bugs!
;   That's an idea that born in my mind during my lunch hour;
;

;  5 BLOAD "TX64DRV.BIN",r
; 10 COLOR 15,4,0:SCREEN 2
; 20 POKE WIDTH,64:POKE HEIGHT,24
; 30 A%=USR0(0)'INITSCR
; 40 PRINT USR0("Teste")
; 50 LOCATE 64,2:PRINT USR0("Agora aqui")
; 60 POKE MODE,1 USR0(256)
; 70 LOCATE 64,3:PRINT USR0("Invertido agora")
; 80 POKE MODE,1 USR0(512)
;
; USR0(0) ; limpa a tela : 0 = limpa a tela; 1-24 = número de linhas ; 64
; USR1(0) ; print sem NL
; USR2(0) ; print com NL
;
;


INCLUDE	./library/msx1bios.asm
INCLUDE	./library/msx1variables.asm

HTIMI:		equ 0xFD9F

PAL:		equ 5						; 1/10s em 50Hz
NTSC:		equ 6						; 1/10s em 60Hz

;
; só irei implementar o ajuste do número de linhas
;
WIDTH:		equ 64
HEIGHT:		equ 10
MAXHEIGHT:	equ HEIGHT-1

			org 0xc000-7				; just a suggestion

BINHEAD:	db 0xfe
			dw BINSTART
			dw BINSTOP
			dw BINEXEC

BINSTART:
BINEXEC:	call INIGRP					; inicia SCR2

			call TXT64CLS				; limpa a tela

			ld a,0xaa
			ld bc,6144
			ld hl,0
			call FILVRM

			ld a,0						; X=2
			ld (TXT64POSX),a

			ld a,0
			ld (TXT64POSY),a			; coloca o cursor em (2,1)

			ld a,0
			ld (TX64MODE),a			; invertido?

			ld b,64

LOOP0:		push bc

			call TXT64WRT

			ld a,(TX64MODE)
			xor 1
			ld (TX64MODE),a

			pop bc
			djnz LOOP0

LOOP:		jr LOOP

MENSA:		db ' A routine that simulates a 64x24 text mode that works fine '
			db 'on MSX, MSX2, MSX2+ and MSX Turbo R! Now with normal and '
			db 'inverse text! :-) ',7,0

; Rotinas:
; TXT64SCR (gerencia a tela)
;	TXT64CR
;	TXT64NL
;	TXT64ESC
;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Rotina de escrita em 64 colunas
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TX64WRIT:	ld de,MENSA					; provisório

TX64WRIT0:	ld a,(de)

			cp 0						; se for NULL saio da rotina
			ret z

			push de						; salvo DE

			cp 7
			jp z,TX64_Beep

			cp 8						; volta um caracter
			jp z,TX64_Backspace

			cp 9						; tabulação
			jp z,TX64_Tabspace

			;~ cp 10						; avanço de linha
			;~ jp z,TX64_Linefeed
			;~
			;~ cp 11						; cursor em home (0,0)
			;~ jp z,TX64_Home
			;~
			;~ cp 12
			;~ jp z,TX64_ClearScreen		; limpa a tela
			;~
			;~ cp 13
			;~ jp z,TX64_CarriageReturn	; retorno de carro
			;~
			;~ cp 27
			;~ jp z,TX64_EscapeCodes
			;~
			;~ cp 28
			;~ jp z,TX64_CsrRight
			;~
			;~ cp 29
			;~ jp z,TX64_CsrLeft
			;~
			;~ cp 30
			;~ jp z,TX64_CsrUp
			;~
			;~ cp 31
			;~ jp z,TX64_CsrDown

			jp TX64CHPUT				; rotina de impressão de caracter

TX64WRIT1:	pop de						; recupera DE

			inc de						; vou para a próximo caracter

			jp TXT64WRIT0


;
; Beep
;
TX64_Beep:
			call BEEP
			jp TX64WRT1

;
; Backspace
;
TX64_Backspace:
			ld a,(TX64POSX)
			dec a
			cp -1
			jr nz,
			xor a
TX64_Backspace1:
			ld (TX64POSX)
			jp TX64WRIT1

;
; Tabulating
;
TX64_Tabspace:
			ld a,(TX64POSX)
			and 0xf8
			rept 8
			inc a
			endm



; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Imprime um caracter tentando ser compatível com a rotina CHPUT da BIOS
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TX64CHPUT:								; preciso salvar todo mundo!

			and 0x7f					; por enquanto é apenas 7-bit

			ld (TX64CHAR),a				; armazeno o caracter a imprimir

			ld a,(CSRX)					; Lê a posição X do cursor (CSRX)
			dec a						; A=A-1

			push af
			and 1						; só preciso do primeiro bit
			ld (TX64EVEN),a				; 0 = coluna par, 1 = coluna ímpar
			pop af

			srl a						; >1 = 000111111
			sla a						; <1 = 001111110
			sla a						; <1 = 011111100
			sla a						; <1 = 111111000

			ld l,a						; L= (X\2)*8

			ld a,(CSRY)					; Lê a posição Y do cursor (CSRY)
			dec a						; A=A-1
			ld h,a						; H=Y*256

			ld (TX64POSV),hl			; armazeno a posição da VRAM

			ld de,8
			ld hl,TX64FONT				; aponto a tabela de caracteres em 4x8

			ld a,(TX64CHAR)				; o caracter que será impresso

			ld b,a						; armazeno em B

TX64CHPUT1:	add hl,de
			djnz TX64CHPUT1				; multiplica o caracter por 8

			ld (TX64POSC),hl			; salvo a posição do caracter

			ex de,hl					; inverto DE com HL

			ld hl,(TX64POSV)			; HL agora contém o endereço da VRAM

			ld b,8						; os 8 bytes do caracter

TX64CHPUT2:	push bc

			call RDVRM					; lê o byte na VRAM

			ex af,af'

			ld a,(TX64EVEN)				; par ou ímpar?
			cp 1
			jr z,TX64CHPUT3

			ld a,0x0f					; máscara para par
			jr TX64CHPUT4

TX64CHPUT3:	ld a,0xf0					; máscara para ímpar

TX64CHPUT4:	ld (TX64_MASK1+1),a
			xor 255						; inverto a máscara
			ld (TX64_MASK2+1),a

			ld a,(TX64MODE)				; texto normal ou invertido?
			cp 1
			jr nz,TX64CHPUT5

			ld a,255					; A=11111111
			jr TX64CHPUT6

TX64CHPUT5:	xor a						; A=00000000

TX64CHPUT6:	ld (TX64_MODE1+1),a

			ex af,af'

TX64_MASK1:	and 0xff					; apago o espaço do caracter

			ld b,a
			ld a,(de)					; leio o endereço apontado em DE

TX64_MODE1:	xor 255

TX64_MASK2:	and 0xff					; seleciono apenas o caracter par

			or b						; aplico o novo caracter

			call WRTVRM					; escrevo na VRAM

			inc de						; nova posição da fonte
			inc hl						; nova posição da VRAM

			pop bc						; recupero BC

			djnz TX64CHPUT2

			; ------------------ fim da impressão

			ld a,(TXT64POSX)			; leio a posição da coluna
			inc a						; avanço para o próximo caracter
			cp WIDTH					; é 64?
			jr nz,TXT64CHR5				; senão segue para WRT5
			xor a						; zero o número da coluna
			ld (TXT64POSX),a			; armazeno a coluna

			ld a,(TXT64POSY)			; recupero a linha
			inc a						; incremento a nova linha
			cp HEIGHT					; é 24?
			jr nz, TXT64CHR6			; senão segue para WRT6
			ld a,MAXHEIGHT				; valor máximo da linha
			ld (TXT64POSY),a			; armazeno a nova posição

			call TXT64SCRL				; faço scroll da tela
			jr TXT64CHR7

TXT64CHR5:	ld (TXT64POSX),a			; armazeno a posição da coluna
			jr TXT64CHR7

TXT64CHR6:	ld (TXT64POSY),a

TXT64CHR7:	jp TXT64WRT1


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Limpa a tela - OK
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64CLS:	ld a,0
			ld bc,6144
			ld hl,0
			call FILVRM

			ld a,0xf4					; é gambi, depois sofistico
			ld bc,6144					;
			ld hl,8192					;
			call FILVRM					;

			xor a
			ld (TXT64POSX),a			; cursor em (0,0)
			ld (TXT64POSY),a

			ret							; saio da rotina

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Rotaciona a tela uma linha para cima
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64SCRL:	ld b,(HEIGHT)
			ld de,0						; linha 0
			ld hl,256					; linha 1

TXT64SCRL0:	push bc						; guarda BC

			ld (TXT64SCRL1+1),hl
			ld (TXT64SCRL2+1),de

			inc d						; é igual a DE=DE+256
			inc h						; é igual a HL=HL+256

			push de
			push hl

			ld bc,256
TXT64SCRL1:	ld hl,0
			ld de,TXT64BUFF
			call LDIRMV					; copia a linha da tela na RAM

			ld bc,256
TXT64SCRL2:	ld de,0
			ld hl,TXT64BUFF
			call LDIRVM					; copia a linha para a VRAM

			pop hl						; recupera HL
			pop de						; recupera DE
			pop bc						; recupera BC
			djnz TXT64SCRL0

			ld a,0
			ld bc,256
			ld hl,MAXHEIGHT*256
			call FILVRM					; limpa a última linha da tela

			ret							; saio da rotina

; - variáveis do programa

TX64CHAR:	db 0						; Caracter a ser impresso

TX64EVEN:	db 0						; É ímpar?
TX64MODE:	db 0						; 0 = normal, 1 = invertido

TX64POSX:	db 0						; posição X do cursor
TX64POSY:	db 0						; posição Y do cursor

TX64POSV:	dw 0						; posição na VRAM
TX64POSC:	dw 0						; posição do padao de caracter

TXT64FONT:	include	./font64.asm		; 1024KiB

TXT64BUFF:
			rept 256
			db 0						; buffer de linha do scroll
			endm

BINSTOP:
;	MSX Rulez a Lot!