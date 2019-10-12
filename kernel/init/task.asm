;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_task:
	; pobierz najwyższy identyfikator Local APIC
	movzx	ecx,	byte [kernel_init_apic_id_highest]
	inc	cx	; zmień system liczenia od 1 (zwykle liczymy od 0)

	; zamień identyfikator na rozmiar listy aktywnych zadań poszczególnych procesorów logicznych w Bajtach
	shl	ecx,	STATIC_MULTIPLE_BY_8_shift

	; zamień na strony
	call	library_page_from_size

	; zarezerwuj przestrzeń o podanym rozmiarze
	call	kernel_memory_alloc
	jc	kernel_init_panic_low_memory

	; zachowaj adres listy aktywnych zadań
	mov	qword [kernel_task_active_list],	rdi

	; ustaw wskaźnik na początek listy aktywnych zadań
	mov	rsi,	rdi

	;-----------------------------------------------------------------------
	; przygotuj przestrzeń pod kolejkę zadań
	call	kernel_memory_alloc_page
	jc	kernel_init_panic_low_memory

	; wyczyść kolejkę zadań
	call	kernel_page_drain

	; zapamiętaj adres początku kolejki zadań
	mov	qword [kernel_task_address],	rdi

	; połącz koniec kolejki z początkiem (RoundRobin)
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rdi

	;-----------------------------------------------------------------------
	; pobierz ID procesora BSP
	call	kernel_apic_id_get

	; wstaw do listy zadań aktywnych, pierwszy wpis z kolejki zadań
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	mov	qword [rsi + rax],	rdi

	;-----------------------------------------------------------------------
	; wpisz jądro systemu jako pierwszy proces w kolejce zadań
	mov	ebx,	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_daemon | KERNEL_TASK_FLAG_secured | KERNEL_TASK_FLAG_processing
	mov	r11,	qword [kernel_page_pml4_address]
	call	kernel_task_add

	;-----------------------------------------------------------------------
	; podłącz procedurę obsługi przełączacznia aktywnego zadania
	; pod przerwanie czasu kontrolera, APIC procesora BSP/logicznego
	mov	rax,	KERNEL_APIC_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	kernel_task
	call	kernel_idt_mount