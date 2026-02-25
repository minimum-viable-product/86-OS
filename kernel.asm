;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; nasm -f bin kernel.asm -o kernel.bin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CPU 8086
ORG 500h


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
command_shell:
    ;call set_video_mode
    call clear_screen

    mov  ah, 3  ; function: set repeat rate
    mov  al, 5  ; (AT+)
    mov  bh, 0  ; delay (0=250ms; AT+)
    mov  bl, 0  ; repeat rate (4=20cps; 0=30cps)
    int  16h    ; invoke keyboard driver

    mov  si, os_title_sz
    call write_line

    mov  si, initial_video_mode_label_sz
    call write_string
    call get_initial_video_mode
    call write_line

    call write_blank_line

.write_prompt:
    call write_blank_line
    mov  si, command_prompt_sz
    call write_string

.get_keyboard_character:
    mov  ah, 0             ; function: read character from keyboard
    int  16h               ; invoke keyboard driver
    cmp  al, 0Dh           ; was `enter` key?
    je   .process_command  ; if `enter` key

.process_character:
    xor  cx, cx
    mov  cl, [command_buffer_count]
    mov  bp, cx
    mov  [command_buffer + bp], al
    inc  byte [command_buffer_count]
    call write_character
    jmp  .get_keyboard_character

.process_command:
    call write_blank_line
    xor  cx, cx
    mov  cl, [command_buffer_count]
    mov  si, command_buffer
    call write_string_sized
    mov  byte [command_buffer_count], 0
    jmp  .write_prompt

    jmp  $  ; effectively halt machine


command_buffer        times 256 db 0
command_buffer_count            db 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_screen:
    mov  ah, 6     ; function: initialize window function
    mov  al, 0     ; blank the window
    mov  bh, 0111_0000b  ; attribute used for blanking
    mov  ch, 0     ; upper y
    mov  cl, 0     ; left x
    mov  dh, 24    ; lower y
    mov  dl, 79    ; right x
    int  0x10      ; invoke display driver
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_initial_video_mode:
    int  11h  ; function: get bios equipment flags
    and  ax, 11_0000b
    cmp  ax, 00_0000b
    je   return_unused_string
    cmp  ax, 01_0000b
    je   return_40x25_color_string
    cmp  ax, 10_0000b
    je   return_80x25_color_string
    cmp  ax, 11_0000b
    je   return_80x25_mono_string

    mov  si, error_sz
    call write_line
    jmp  $  ; endless loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_current_video_mode:
    mov  ah, 0Fh
    ; TODO
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return_unused_string:
    mov  si, unused_sz
    ret
return_40x25_color_string:
    mov  si, color_40x25_sz
    ret
return_80x25_color_string:
    mov  si, color_80x25_sz
    ret
return_80x25_mono_string:
    mov  si, mono_80x25_sz
    ret

unused_sz       db "unused", 0
color_40x25_sz  db "40x25 color", 0
color_80x25_sz  db "80x25 color", 0
mono_80x25_sz   db "80x25 monochrome", 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reboot:
    jmp  0xFFFF:0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_video_mode:
    mov  ah, 0
    mov  al, 7  ; 80x25 monochrome text
    int  0x10   ; Invoke display driver
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_number:
    add  al, 48

write_character:  ; from AL
    mov  ah, 0xE
    int  0x10
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_blank_line:
    mov  si, empty_sz

write_line:
    call write_string
    mov  si, newline_sz

write_string:  ; from DS:SI
.loop:
    lodsb         ; Load string byte from DS:SI into AL
    cmp  al, 0    ; Test for "NULL" 0 byte, signaling end of string
    je   .done    ; Jump out of loop if AL equaled 0
    mov  ah, 0xE  ; Write character in teletype mode
    int  0x10     ; Invoke display driver
    jmp  .loop
.done:
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_string_sized:  ; from DS:SI, size in CX
    cmp  cx, 0
    je   .done
.loop:
    lodsb
    mov  ah, 0Eh
    int  10h
    loop .loop
.done:
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global string data;  Uses suffix `_sz` for "string zero"

command_prompt_sz            db "> ", 0
empty_sz                     db 0
error_sz                     db "ERROR!", 0
initial_video_mode_label_sz  db "Initial video mode: ", 0
newline_sz                   db 13, 10, 0
os_title_sz                  db "8 6 / O S", 0
press_any_key_to_reset_sz    db "Press any key to reset...", 0
unknown_command_sz           db 13, 10, "Unknown command.", 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Verify kernel sector count (nasm error if larger)
    times 512*2-($-$$) db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
