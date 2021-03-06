;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; 16 bitowy kod głównego programu rozruchowego =================================
;===============================================================================
[bits 16]

; pozycja kodu w przestrzeni segmentu CS
[org 0x1000]

;===============================================================================
zero:
	;-----------------------------------------------------------------------
	; wczytaj plik jadra systemu
	;-----------------------------------------------------------------------
	%include	"zero/storage.asm"

	;-----------------------------------------------------------------------
	; przygotuj mapę pamięci
	;-----------------------------------------------------------------------
	%include	"zero/memory.asm"

	;-----------------------------------------------------------------------
	; włącz tryb graficzny
	;-----------------------------------------------------------------------
	%include	"zero/graphics.asm"

	;-----------------------------------------------------------------------
	; przełącz procesor w tryb 32 bitowy
	;-----------------------------------------------------------------------
	%include	"zero/protected_mode.asm"

	;-----------------------------------------------------------------------
	; przełącz procesor w tryb 64 bitowy
	;-----------------------------------------------------------------------
	%include	"zero/long_mode.asm"

	;-----------------------------------------------------------------------
	; konfiguruj obslugę wyjątków i przerwań sprzętowych
	;-----------------------------------------------------------------------
	%include	"zero/idt.asm"

	;-----------------------------------------------------------------------
	; włącz przerwania sprzętowe na kontrolerze PIC
	;-----------------------------------------------------------------------
	%include	"zero/pic.asm"

	;-----------------------------------------------------------------------
	; wyłącz przerwanie na kontrolerze PIT
	;-----------------------------------------------------------------------
	%include	"zero/pit.asm"

	;-----------------------------------------------------------------------
	; przekaż wszystkie niezbędne informacje do jadra systemu
	;-----------------------------------------------------------------------
	%include	"zero/kernel.asm"

	;-----------------------------------------------------------------------
	; procedura zaokrąglająca adres do pełnej strony
	;-----------------------------------------------------------------------
	%include	"zero/page.asm"

	;-----------------------------------------------------------------------
	; zmienne programu rozruchowego
	;-----------------------------------------------------------------------
	%include	"zero/data.asm"

;===============================================================================
zero_end:
