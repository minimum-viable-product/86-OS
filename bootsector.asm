;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; nasm -f bin bootsector.asm -o bootsector.bin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Assemble only 8086 instruction set
CPU 8086

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Add offset 7C00h to all internal address references
ORG 0x7C00

;
; TODO: Test CPU isn't already, incorrectly in protected mode?
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reset floppy disk (move read/write arm to cylinder 0)
; Do this immediately before each & every attempt to read
; from the floppy drive (to ensure motor is spinning)

    xor  ax, ax       ; reset disk function
    xor  dl, dl       ; floppy disk
    int  0x13         ; invoke disk driver
    jnc  load_kernel  ; if carry flag clear

    mov  si, error_reseting_disk_sz
    call write_line
    jmp  $  ; endless loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read kernel's sectors into memory
load_kernel:
    xor  ax, ax    ; 0
    mov  es, ax    ; segment 0
    mov  bx, 500h  ; offset

    mov  ah, 2     ; read sector function
    mov  al, 2     ; number of sectors
    mov  ch, 0     ; cylinder
    mov  cl, 2     ; sector (starts at 1)
    mov  dh, 0     ; head
    mov  dl, 0     ; drive (floppy=0-7Fh; hdd=80h-FFh)
    int  13h       ; invoke disk driver
    jnc  execute_kernel  ; if carry flag clear

    mov  si, error_loading_kernel_sz
    call write_line
    jmp  $  ; endless loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
execute_kernel:
    jmp  500h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_line:
    call write_string
    mov  si, newline_sz  ; fall through, appending newline

write_string:
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
error_loading_kernel_sz db "Error loading kernel.", 0
error_reseting_disk_sz  db "Error reseting disk.", 0
newline_sz              db 13, 10, 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pad to end of 512 byte sector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    times 510-($-$$) db 0
    dw   0xAA55
