;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_desu_event:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11

	;-----------------------------------------------------------------------
	; pobierz pozycje wskaźnika myszy
	mov	r8d,	dword [driver_ps2_mouse_x]
	mov	r9d,	dword [driver_ps2_mouse_y]

	; delta osi X
	mov	r14,	r8
	sub	r14,	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]

	; delta osi Y
	mov	r15,	r9
	sub	r15,	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]

	;-----------------------------------------------------------------------
	; naciśnięto lewy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
	jnc	.no_mouse_button_left_action	; nie

	; lewy przycisk myszki był już naciśnięty?
	cmp	byte [service_desu_mouse_button_left_semaphore],	STATIC_TRUE
	je	.no_mouse_button_left_action	; tak, zignoruj

	; zapamiętaj ten stan
	mov	byte [service_desu_mouse_button_left_semaphore],	STATIC_TRUE

	; jest już wybrany obiekt aktywny?
	cmp	qword [service_desu_object_selected_pointer],	STATIC_EMPTY
	jne	.no_mouse_button_left_action	; tak, zignoruj przytrzymanie lewego klawisza myszki na innym obiekcie

	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
 	call	service_desu_object_find
	jc	.no_mouse_button_left_action	; brak obiektu

	; ustaw obiekt jako aktywny
	mov	qword [service_desu_object_selected_pointer],	rsi

	; ukryj "kruche" obiekty
	call	service_desu_object_hide

	; obiekt powinien zachować swoją warstwę?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fixed_z
	jnz	.fixed_z	; tak

	; przesuń obiekt na koniec listy
	call	service_desu_object_up

	; aktualizuj wskaźnik obiektu aktywnego
	mov	qword [service_desu_object_selected_pointer],	rsi

	; wyświetl ponownie zawartość obiektu
	or	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

	; wyświetl ponownie zawartość obiektu kursora (przysłoniony przez obiekt)
	or	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

.fixed_z:
; 	; ; pobierz ID okna i PID
; 	; mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
; 	; mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]
; 	;
; 	; ; skomponuj komunikat dla procesu
; 	; mov	rsi,	service_desu_message
; 	;
; 	; ; wyślij informacje o typie akcji
; 	; mov	byte [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.type],	SERVICE_DESU_MESSAGE_TYPE_MOUSE_BUTTON_left_press
; 	;
; 	; ; wyślij informacje o ID okna biorącego udział
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.id],	rax
; 	;
; 	; ; wyślij informacje o pozycji wskaźnika kursora
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value0],	r8	; x
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value1],	r9	; y
; 	;
; 	; ; wyślij komunikat
; 	; call	kernel_ipc_send
;
.no_mouse_button_left_action:
	; puszczono lewy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
	jc	.no_mouse_button_left_release	; nie

.no_mouse_button_left_action_release:
	; usuń stan
	mov	byte [service_desu_mouse_button_left_semaphore],	STATIC_FALSE

.no_mouse_button_left_action_release_selected:
	; usuń informacje o aktywnym obiekcie
	mov	qword [service_desu_object_selected_pointer],	STATIC_EMPTY

.no_mouse_button_left_release:
	;-----------------------------------------------------------------------
	; naciśnięto prawy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
	jnc	.no_mouse_button_right_action	; nie

	; prawy przycisk myszki był już naciśnięty?
	cmp	byte [service_desu_mouse_button_right_semaphore],	STATIC_TRUE
	je	.no_mouse_button_right_action	; tak, zignoruj

	; zapamiętaj ten stan
	mov	byte [service_desu_mouse_button_right_semaphore],	STATIC_TRUE

	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
 	call	service_desu_object_find
	jc	.no_mouse_button_right_action	; brak obiektu pod wskaźnikiem

	; ukryj "kruche" obiekty
	call	service_desu_object_hide

	; pobierz ID okna i PID
	mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
	mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]

	; skomponuj komunikat dla procesu
	mov	rsi,	service_desu_ipc_data

	; wyślij informacje o typie akcji
	mov	byte [rsi + SERVICE_DESU_STRUCTURE_IPC.type],	SERVICE_DESU_IPC_MOUSE_BUTTON_RIGHT_press

	; wyślij informacje o ID okna biorącego udział
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.id],	rax

	; wyślij informacje o pozycji wskaźnika kursora
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.value0],	r8	; x
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.value1],	r9	; y

	; wyślij komunikat
	xor	ecx,	ecx	; standardowy rozmiar komunikatu pod adresem w rejestrze RSI
	call	kernel_ipc_insert

.no_mouse_button_right_action:
	; puszczono prawy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
	jc	.no_mouse_button_right_release	; nie

	; usuń ten stan
	mov	byte [service_desu_mouse_button_right_semaphore],	STATIC_FALSE

.no_mouse_button_right_release:
	; przesunięcie wskaźnika kursora na osi X
	test	r14,	r14
	jnz	.move	; tak

	; przesunięcie wskaźnika kursora na osi Y
	test	r15,	r15
	jz	.end	; nie

.move:
	; przetwórz strefę zajętą przez obiekt kursora
	mov	rsi,	service_desu_object_cursor
	call	service_desu_zone_insert_by_object

	; aktualizuj specyfikacje obiektu kursora
	add	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r14
	add	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r15

	; obiekt kursora został zaaktualizowany
	or	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

	;-----------------------------------------------------------------------

	; jeśli wraz z przyciśniętym lewym klawiszem myszki
	cmp	byte [service_desu_mouse_button_left_semaphore],	STATIC_FALSE
	je	.end	; niestety, nie

	; został wybrany obiekt aktywny/widoczny
	cmp	qword [service_desu_object_selected_pointer],	STATIC_EMPTY
	je	.end	; też nie

	; przemieść obiekt wraz z wskaźnikiem kursora
	call	service_desu_object_move

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_event"
