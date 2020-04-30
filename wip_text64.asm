;
;   meia4 version 1.0
;

;
;   This is a experimental code and of course that has a lot of bugs!
;   That's an idea that born in my mind during my lunch hour;
;

;
;	K I S S !
;

INCLUDE	./library/msx1bios.asm
INCLUDE	./library/msx1variables.asm

HTIMI:	equ 0xFD9F

PAL:		equ 5						; 1/10s em 50Hz
NTSC:		equ 6						; 1/10s em 60Hz

			org 0xd000-7				; just a suggestion

BINHEAD:	db 0xfe
			dw BINSTART
			dw BINSTOP
			dw BINEXEC

; o mais relocável possível, é possível?

;           usr0(_str_) = print
;           usr1(_int_)
;               1: inverse, 2: underline, 4: strike, 8: disabled
;           usr2(_int_)
;               0: normal CLS, 1: fast CLS (no attribute)
;           usr3(_int_)
;               0: up, 1: down, 2: left, 3: right


meia4Print:
            ret

meia4Mode:
            ret

meia4Clear:
            ret

meia4Scroll:
            ret

meia4SetWidth:
            ret

meia4SetHeight:
            ret



initScreen:
            call INIGRP             ; start the SCREEN 2
            call __clearScreen      ; clear screen
            xor a                   ; 'A'=0
            ld (tex64PosX),a
            ld (tex64PosY),a



__clearScreen:


BINSTART:
BINEXEC:	call INIGRP				; inicia SCR2

			call TXT64CLRS				; limpa a tela

			ld a,2						; X=2
			ld (TXT64POSX),a
			ld a,1
			ld (TXT64POSY),a			; coloca o cursor em (2,1)

			;~ ld b,24
;~ LOOP0:		push bc
			;~ call TXT64SCRL
			;~ pop bc
			;~ djnz LOOP0

			call TXT64WRT

LOOP:		jr LOOP

MENSA:		db 'A',0

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Rotina de escrita em 64 colunas
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64WRT:	ld de,MENSA					; linha de texto (TEMP)

TXT64WRT0:	ld a,(de)					; lê o primeiro caracter
			cp 0
			ret z						; NULL é fim da string, saio da rotina

			and 0x7f					; esta versão é 7-bit only :-/

			ld (TXT64CHAR),a			; armazeno o caracter a ser impresso

			push de						; salva DE

										; calcula a posição da VRAM e armazena
			call TXT64VRMP				; em TXT64POSV e tanmbém a máscara a
										; ser utilizada em TXT64EVEN

		;	ld hl,TXT64POSV				; HL já vem assim da outra rotina
			ld de,TXT64BYTE				; posição do buffer na RAM

			ld b,8						; 8 bytes ao todo
TXT64WRT1:	call RDVRM					; leio o byte na VRAM
			ld (de),a					; armazena o byte lido
			inc de						; incrementa DE
			inc hl						; incrementa HL
			djnz TXT64WRT1				; recupero o bloco da VRAM

			;
			; PARTE 3 - Calculo a posição do padrão do caracter a escrever
			;
			ld de,8
			ld hl,0
			ld a,(TXT64CHAR)
			ld b,a						; valor do caracter lido

TXT64WRT2:	add hl,de
			djnz TXT64WRT2				; multiplica o caracter por 8

			ex de,hl					; inverto DE com HL

			ld hl,TXT64FONT				; a tabela de caracteres
			add hl,de					; mais a posição do caracter

			;
			; PARTE 4 - Copio um padrão sobre o outro
			;
			ld b,8						; número de vezes a repetir

			ld de,TXT64BYTE

TXT64WRT3:	push bc						; salvo BC

			ld a,(TXT64EVEN)			; carrego a máscara

			and (hl)

			ld a,(TXT64EVEN)			; recarrego a máscara
			xor 255						; inverto os bits

			ex de,hl					; inverto DE com HL

			or (hl)						; aplica a máscara

			ex de,hl					; (des)inverto DE com HL

			push hl

			ld hl,(TXT64POSV)
			call WRTVRM					; aproveito o laço para
			inc hl						; escrever na VRAM
			ld (TXT64POSV),hl

			pop hl

			inc hl
			inc de

			pop bc

			djnz TXT64WRT3

			pop de

			inc de

			ld hl,TXT64POSX
			inc (hl)					; avança X

			pop de						; recupera DE

			inc de						; vou para a próximo caracter

			jr TXT64WRT0

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Calcula o endereço da VRAM a partir de X e Y
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64VRMP:	ld a,(TXT64POSX)			; posição de X

			ld hl,TXT64EVEN
			ld (hl),0xf0				; já assumo a máscara para X par

			bit 0,a						; testo o bit 0 de A
			cp 0
			jr z,TXT64VRMP0				; se for par vou para TXT64VRAM0

			ld (hl),0x0f				; altera para a máscara de ímpar

TXT64VRMP0:	and 0x1e					; divido por 2 e faço um shift
										; >1 = 000001111
										; <1 = 000011110 (fica igual)
			sla a						; <1 = 011111100
			sla a						; <1 = 111111000

			ld l,a						; L=A*8

			ld a,(TXT64POSY)			; posição de Y

			ld h,a						; H=A*256

			ld (TXT64POSV),hl			; armazeno a posição da VRAM

			ret							; saio da rotina



;~ ; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;~ ; *
;~ ; *  Aplica a máscara para o novo caracter
;~ ; *
;~ ; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;~ ;
;~ TXT64MASK:	ld b,0xf0					; a princípo é par (XXXX0000)
			;~ ld a,(TXT64CHAR)
			;~
			;~ cp 0						; é mesmo zero?
			;~ jr TXT64MASK0
			;~ ld b,0x0f					; então é ímpar (0000XXXX)
			;~
;~ TXT64MASK0:	ld c,b
			;~
			;~ ld b,8
			;~ ld hl,TXT64BYTE				; endereço inicial do caracter
			;~
;~ TXT64MASK1:	ld a,(hl)					; recupera o byte
			;~ and c						; aplica a máscara
			;~ ld (hl),a					; armazena o byte com máscara
			;~ inc hl						; nova posição de HL
			;~ djnz TXT64MASK1
			;~
			;~ ret							; saio da rotina

; passo 5 : incrementar o contador (é o mesmo caracter?)
; passo 5.1 : passo 3
; passo 6 ; retornar o bloco para a VRAM
; passo 7 ; acabou a tela? (SCROLL)

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Limpa a tela - OK
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64CLRS:	ld a,0
			ld bc,6144
			ld hl,0
			call FILVRM

			ld a,0xf4
			ld bc,6144
			ld hl,8192
			call FILVRM

			xor a
			ld (TXT64POSX),a			; cursor em (0,0)
			ld (TXT64POSY),a

			ret							; saio da rotina

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *
; *  Rotaciona a tela para cima - OK
; *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TXT64SCRL:	ld b,23
			ld de,0						; linha 0
			ld hl,256					; linha 1

TXT64SCRL0:	push bc						; guarda BC

			ld (TXT64SCRL1+1),hl
			ld (TXT64SCRL2+1),de

			inc d
			inc h

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
			ld hl,23*256
			call FILVRM				; limpa a última linha da tela

			ret							; saio da rotina

TXT64CHAR:	db 0						; Caracter a ser impresso
TXT64EVEN:	db 0						; É ímpar?
TXT64POSX:	db 0						; posição X do cursor
TXT64POSY:	db 0						; posição Y do cursor
TXT64POSV:	dw 0						; posição na VRAM

TXT64BYTE:	db 0,0,0,0,0,0,0,0			; buffer de impressão

TXT64FONT:	incbin	./font64.inc		; 1024KiB

TXT64BUFF:
			rept 256
			db 0						; buffer do programa
			endm

BINSTOP:
;	MSX Rulez a Lot!

;   vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4