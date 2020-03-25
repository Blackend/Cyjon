;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"	; lokalne
	;-----------------------------------------------------------------------
	%include	"kernel/macro/apic.asm"
	;-----------------------------------------------------------------------

; 32 bitowy kod inicjalizacyjny jądra systemu
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej
[ORG KERNEL_BASE_address]

init:
	;-----------------------------------------------------------------------
	; Init - inicjalizacja środowiska pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

; wyrównaj pozycję kodu do pełnej strony
align	KERNEL_PAGE_SIZE_byte,	db	STATIC_NOTHING

clean:
	; ; zwolnij przestrzeń zajętą przez procedury inicjalizacyjne
	; mov	ecx,	clean - $$
	; mov	rdi,	KERNEL_BASE_address
	; call	library_page_from_size	; zamień rozmiar przestrzeni na strony
	; call	kernel_memory_release

kernel:
	; ; uruchom program inicjalizujący środowisko użytkownika
	; mov	ecx,	kernel_init_exec_end - kernel_init_exec
	; mov	rsi,	kernel_init_exec
	; call	kernel_vfs_path_resolve
	; call	kernel_vfs_file_find
	; call	kernel_exec

	; pobierz wskaźnik do aktualnego zadania (jądro) w kolejce
	call	kernel_task_active

	; zwolnij wpis
	mov	word [rdi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY

	; czekaj na wywłaszczenie
	jmp	$

	;-----------------------------------------------------------------------
	; procedury, makra, dane, biblioteki, usługi - wszystko co niezbędne
	; do prawidłowej pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/macro/lock.asm"
	%include	"kernel/macro/debug.asm"
	%include	"kernel/macro/copy.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/ipc.asm"
	%include	"kernel/panic.asm"
	%include	"kernel/page.asm"
	%include	"kernel/memory.asm"
	%include	"kernel/video.asm"
	%include	"kernel/apic.asm"
	%include	"kernel/io_apic.asm"
	%include	"kernel/data.asm"
	%include	"kernel/idt.asm"
	%include	"kernel/task.asm"
;	%include	"kernel/thread.asm"
	%include	"kernel/vfs.asm"
	%include	"kernel/exec.asm"
	%include	"kernel/service.asm"
	%include	"kernel/debug.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/font/canele.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/ps2.asm"
	%include	"kernel/driver/pci.asm"
	%include	"kernel/driver/network/i82540em.asm"
	%include	"kernel/driver/storage/ide.asm"
	%include	"kernel/driver/serial.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/service/tresher.asm"
	%include	"kernel/service/http.asm"
	%include	"kernel/service/tx.asm"
	%include	"kernel/service/network.asm"
	%include	"kernel/service/desu.asm"
	%include	"kernel/service/cero.asm"
	;-----------------------------------------------------------------------
	%include	"library/color.asm"
	%include	"library/input.asm"
	%include	"library/integer_to_string.asm"
	%include	"library/page_align_up.asm"
	%include	"library/page_from_size.asm"
	%include	"library/string_compare.asm"
	%include	"library/string_cut.asm"
	%include	"library/string_digits.asm"
	%include	"library/string_to_integer.asm"
	%include	"library/string_trim.asm"
	%include	"library/string_word_next.asm"
	;-----------------------------------------------------------------------

kernel_end:
