;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_smp:
	; dostępny jest tylko jeden procesor logiczny?
	cmp	word [kernel_apic_count],	STATIC_TRUE
	jbe	.finish	; tak, pomiń inicjalizacje pozostałych

	; ustaw kod rozruchowy dla procesorów logicznych na docelowe miejsce
	mov	ecx,	kernel_init_boot_file_end - kernel_init_boot_file
	mov	rsi,	kernel_init_boot_file
	mov	rdi,	0x8000	; 0x0000:0x8000
	rep	movsb

	; otwórz docelową ścieżkę dla procesorów logicznych w procedurach inicjalizacyjnych
	mov	byte [kernel_init_smp_semaphore],	STATIC_TRUE

	; pobierz identyfikator procesora BSP
	mov	rdi,	qword [kernel_apic_base_address]
	mov	eax,	dword [rdi + KERNEL_APIC_ID_register]
	shr	eax,	24	; przesuń bity z 24..31 do 0..7

	; zachowaj identyfikator
	mov	dl,	al

	; inicjalizuj kolejne procesory logiczne
	mov	rsi,	kernel_apic_id_table

	; ilość procesorów logicznych
	mov	cx,	word [kernel_apic_count]

.init:
 	; koniec procesorów logicznych do wybudzenia?
 	dec	cx
 	js	.init_done	; tak

 	; pobierz identyfikator procesora logicznego
 	lodsb

 	; procesor BSP?
 	cmp	al,	dl
 	je	.init	; tak, pomiń

 	; wyślij polecenie INIT do procesora logicznego
 	shl	eax,	24	; przesuń bity z 0..7 do 24..31
 	mov	dword [rdi + KERNEL_APIC_ICH_register],	eax
 	mov	eax,	0x00004500
 	mov	dword [rdi + KERNEL_APIC_ICL_register],	eax

 .init_wait:
 	; wykonano polecenie?
 	bt	dword [rdi + KERNEL_APIC_ICL_register],	KERNEL_APIC_ICL_COMMAND_COMPLETE_bit
 	jc	.init_wait	; czekaj

 	; następny procesor logiczny
 	jmp	.init

.init_done:
 	; odczekaj około 10ms
 	mov	rax,	qword [driver_rtc_microtime]
 	add	rax,	10

 .init_wait_for_ipi:
 	; upłynął czas?
 	cmp	rax,	qword [driver_rtc_microtime]
 	ja	.init_wait_for_ipi	; nie

	; wskaż wszystkim procesorom logicznym adres rozpoczęcia pracy

	; uruchom kolejne procesory logiczne
	mov	rsi,	kernel_apic_id_table

	; ilość procesorów logicznych
	mov	cx,	word [kernel_apic_count]

.start:
 	; koniec procesorów logicznych?
 	dec	cx
 	js	.finish	; tak

 	; pobierz identyfikator procesora logicznego
 	lodsb

 	; procesor BSP?
 	cmp	al,	dl
 	je	.start	; tak, pomiń

 	; wyślij polecenie START do procesora logicznego (wektor 0x08 > 0x8000)
 	shl	eax,	24	; przesuń bity z 0..7 do 24..31
 	mov	dword [rdi + KERNEL_APIC_ICH_register],	eax
 	mov	eax,	0x00004608
 	mov	dword [rdi + KERNEL_APIC_ICL_register],	eax

 .start_wait:
 	; wykonano polecenie?
 	bt	dword [rdi + KERNEL_APIC_ICL_register],	KERNEL_APIC_ICL_COMMAND_COMPLETE_bit
 	jc	.start_wait	; czekaj

 	; następny procesor logiczny
 	jmp	.start

.finish:
