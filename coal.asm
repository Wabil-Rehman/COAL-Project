org 0x100

section .data

SCREEN_WIDTH    equ 80
SCREEN_HEIGHT   equ 25
BRICK_ROWS      equ 4
BRICKS_PER_ROW  equ 10
BRICK_WIDTH     equ 6
PADDLE_WIDTH    equ 8
INITIAL_LIVES   equ 3
VIDEO_MEM       equ 0xB800

POWERUP_NONE        equ 0
POWERUP_BIG_PADDLE  equ 1
POWERUP_DOUBLE_PTS  equ 2
POWERUP_EXTRA_LIFE  equ 3

COLOR_BRICK_ROW1 equ 0x0C
COLOR_BRICK_ROW2 equ 0x0E
COLOR_BRICK_ROW3 equ 0x0A
COLOR_BRICK_ROW4 equ 0x0B
COLOR_PADDLE    equ 0x19
COLOR_BALL      equ 0x0F
COLOR_TEXT      equ 0x07
COLOR_SCORE     equ 0x0E
COLOR_POWERUP   equ 0x0D
COLOR_TITLE     equ 0x4F
COLOR_START     equ 0x2A

CHAR_BRICK      equ 0xDB
CHAR_PADDLE     equ 0xDB
CHAR_BALL       equ 0x4F
CHAR_SPACE      equ 0x20
CHAR_POWERUP    equ 0x50

ball_x:         dw 40
ball_y:         dw 20
ball_dx:        dw 1
ball_dy:        dw -1
ball_delay:     dw 0
ball_speed:     dw 10
paddle_x:       dw 36
paddle_width:   dw PADDLE_WIDTH
score:          dw 0
lives:          dw INITIAL_LIVES
bricks_left:    dw BRICK_ROWS * BRICKS_PER_ROW
frame_delay:    dw 1
current_level:  dw 1
score_multiplier: dw 1
high_score:     dw 0

powerup_active: db 0
powerup_type:   db 0
powerup_x:      dw 0
powerup_y:      dw 0
powerup_delay:  dw 0

bricks:         times BRICK_ROWS * BRICKS_PER_ROW db 1

filename:       db 'HISCORE.DAT', 0
file_handle:    dw 0

msg_title:      db 'ATARI BREAKOUT ARCADE GAME', 0
msg_rules1:     db 'RULES:', 0
msg_rules2:     db '- Use LEFT/RIGHT arrows to move paddle', 0
msg_rules3:     db '- Break all bricks to win!', 0
msg_rules4:     db '- Different colors = different points!', 0
msg_rules5:     db '- Collect powerups for bonuses!', 0
msg_start:      db 'Press ENTER to start', 0
msg_exit:       db 'Press ESC to exit', 0
msg_score_txt:  db 'SCORE:', 0
msg_lives_txt:  db 'LIVES:', 0
msg_level_txt:  db 'LEVEL:', 0
msg_high_txt:   db 'HIGH:', 0
msg_gameover:   db 'GAME OVER!', 0
msg_level_complete: db 'LEVEL COMPLETE!', 0
msg_final:      db 'Final Score: ', 0
msg_continue:   db 'Press any key...', 0
msg_powerup_big: db 'BIG PADDLE!', 0
msg_powerup_x2: db 'X2 POINTS!', 0
msg_powerup_life: db 'EXTRA LIFE!', 0
msg_new_high:   db 'NEW HIGH SCORE!', 0

section .text
global _start

_start:
    call load_high_score
    call clear_screen_color
    call show_welcome_screen
.wait_start:
    mov ah, 0x00
    int 0x16
    cmp ah, 0x01
    je .exit_program
    cmp ah, 0x1C
    je .start_game
    jmp .wait_start
.start_game:
    call init_game
    call game_loop
.exit_program:
    call clear_screen
    mov ax, 0x4C00
    int 0x21

load_high_score:
    pusha
    mov ax, 0x3D00
    mov dx, filename
    int 0x21
    jc .create_file
    mov [file_handle], ax
    mov bx, ax
    mov ah, 0x3F
    mov cx, 2
    mov dx, high_score
    int 0x21
    mov ah, 0x3E
    mov bx, [file_handle]
    int 0x21
    popa
    ret
.create_file:
    mov word [high_score], 0
    popa
    ret

save_high_score:
    pusha
    mov ah, 0x3C
    mov cx, 0
    mov dx, filename
    int 0x21
    jc .error
    mov [file_handle], ax
    mov bx, ax
    mov ah, 0x40
    mov cx, 2
    mov dx, high_score
    int 0x21
    mov ah, 0x3E
    mov bx, [file_handle]
    int 0x21
.error:
    popa
    ret

show_welcome_screen:
    pusha
    call fill_black_bg
    mov dh, 3
    mov dl, 25
    mov si, msg_title
    mov bl, COLOR_TITLE
    call write_string
    mov dh, 5
    mov dl, 30
    mov si, msg_high_txt
    mov bl, 0x0E
    call write_string
    mov dh, 5
    mov dl, 36
    mov ax, [high_score]
    mov bl, 0x0E
    call write_number
    mov dh, 7
    mov dl, 5
    mov si, msg_rules1
    mov bl, 0x0E
    call write_string
    mov dh, 8
    mov dl, 5
    mov si, msg_rules2
    mov bl, 0x0B
    call write_string
    mov dh, 9
    mov dl, 5
    mov si, msg_rules3
    mov bl, 0x0B
    call write_string
    mov dh, 10
    mov dl, 5
    mov si, msg_rules4
    mov bl, 0x0B
    call write_string
    mov dh, 11
    mov dl, 5
    mov si, msg_rules5
    mov bl, 0x0B
    call write_string
    mov dh, 14
    mov dl, 28
    mov si, msg_start
    mov bl, COLOR_START
    call write_string
    mov dh, 15
    mov dl, 30
    mov si, msg_exit
    mov bl, COLOR_TEXT
    call write_string
    popa
    ret

fill_black_bg:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x0020
.fill:
    stosw
    loop .fill
    popa
    ret

init_game:
    pusha
    mov word [ball_x], 40
    mov word [ball_y], 20
    mov word [ball_dx], 1
    mov word [ball_dy], -1
    mov word [ball_delay], 0
    mov word [ball_speed], 10
    mov word [paddle_x], 36
    mov word [paddle_width], PADDLE_WIDTH
    mov word [score], 0
    mov word [lives], INITIAL_LIVES
    mov word [current_level], 1
    mov word [score_multiplier], 1
    mov byte [powerup_active], 0
    mov word [powerup_delay], 0
    call reset_level
    call clear_screen_game
    call draw_game_screen
    popa
    ret

reset_level:
    pusha
    mov word [bricks_left], BRICK_ROWS * BRICKS_PER_ROW
    mov cx, BRICK_ROWS * BRICKS_PER_ROW
    mov di, bricks
.reset_bricks:
    mov byte [di], 1
    inc di
    loop .reset_bricks
    mov word [ball_x], 40
    mov word [ball_y], 20
    mov word [ball_dx], 1
    mov word [ball_dy], -1
    mov byte [powerup_active], 0
    mov word [powerup_delay], 0
    mov word [score_multiplier], 1
    mov word [paddle_width], PADDLE_WIDTH
    popa
    ret

game_loop:
    pusha
.main_loop:
    call handle_input
    call do_frame_delay
    call update_powerup
    call update_ball
    call check_game_state
    jmp .main_loop

handle_input:
    pusha
    mov ah, 0x01
    int 0x16
    jz .no_key
    mov ah, 0x00
    int 0x16
    cmp ah, 0x01
    je .do_exit
    cmp ah, 0x4B
    je .do_left
    cmp ah, 0x4D
    je .do_right
    jmp .no_key
.do_exit:
    popa
    popa
    jmp _start.exit_program
.do_left:
    mov ax, [paddle_x]
    cmp ax, 1
    jle .no_key
    sub word [paddle_x], 2
    call draw_paddle
    jmp .no_key
.do_right:
    mov ax, [paddle_x]
    add ax, [paddle_width]
    add ax, 2
    cmp ax, SCREEN_WIDTH
    jge .no_key
    add word [paddle_x], 2
    call draw_paddle
.no_key:
    popa
    ret

do_frame_delay:
    pusha
    mov cx, [frame_delay]
.delay_loop:
    push cx
    mov cx, 0x8000
.inner:
    loop .inner
    pop cx
    loop .delay_loop
    popa
    ret

update_powerup:
    pusha
    cmp byte [powerup_active], 1
    jne .done
    call move_powerup
.done:
    popa
    ret

update_ball:
    pusha
    inc word [ball_delay]
    mov ax, [ball_delay]
    cmp ax, [ball_speed]
    jl .skip
    mov word [ball_delay], 0
    call erase_ball
    call move_ball
    call draw_ball
.skip:
    popa
    ret

check_game_state:
    pusha
    cmp word [bricks_left], 0
    je .level_done
    cmp word [lives], 0
    je .game_over
    popa
    ret
.level_done:
    call show_level_complete
    inc word [current_level]
    mov ax, [ball_speed]
    cmp ax, 5
    jle .no_speedup
    dec word [ball_speed]
.no_speedup:
    call reset_level
    call clear_screen_game
    call draw_game_screen
    popa
    ret
.game_over:
    call check_high_score
    call show_gameover_screen
    popa
    popa
    jmp _start.exit_program

check_high_score:
    pusha
    mov ax, [score]
    cmp ax, [high_score]
    jle .not_high
    mov [high_score], ax
    call save_high_score
    call show_new_high_score
.not_high:
    popa
    ret

show_new_high_score:
    pusha
    mov dh, 14
    mov dl, 30
    mov si, msg_new_high
    mov bl, 0x0E
    call write_string
    mov cx, 30
.delay:
    push cx
    mov cx, 0xFFFF
.inner:
    loop .inner
    pop cx
    loop .delay
    popa
    ret

move_ball:
    pusha
    mov ax, [ball_x]
    add ax, [ball_dx]
    mov [ball_x], ax
    mov ax, [ball_y]
    add ax, [ball_dy]
    mov [ball_y], ax
    call check_wall_x
    call check_wall_y
    call check_paddle_hit
    call check_brick_hit
    call check_ball_lost
    popa
    ret

check_wall_x:
    pusha
    mov ax, [ball_x]
    cmp ax, 0
    jle .bounce
    cmp ax, SCREEN_WIDTH - 1
    jge .bounce
    popa
    ret
.bounce:
    neg word [ball_dx]
    mov ax, [ball_x]
    cmp ax, 0
    jg .fix_right
    mov word [ball_x], 0
    popa
    ret
.fix_right:
    mov word [ball_x], SCREEN_WIDTH - 1
    popa
    ret

check_wall_y:
    pusha
    mov ax, [ball_y]
    cmp ax, 1
    jle .bounce
    popa
    ret
.bounce:
    neg word [ball_dy]
    mov word [ball_y], 1
    popa
    ret

check_paddle_hit:
    pusha
    mov ax, [ball_y]
    cmp ax, SCREEN_HEIGHT - 2
    jne .no_hit
    mov ax, [ball_x]
    mov bx, [paddle_x]
    cmp ax, bx
    jl .no_hit
    add bx, [paddle_width]
    cmp ax, bx
    jge .no_hit
    call sound_paddle
    neg word [ball_dy]
    mov word [ball_y], SCREEN_HEIGHT - 3
.no_hit:
    popa
    ret

check_brick_hit:
    pusha
    mov ax, [ball_y]
    cmp ax, 2
    jl .no_hit
    cmp ax, 2 + BRICK_ROWS
    jge .no_hit
    sub ax, 2
    push ax
    mov ax, [ball_x]
    sub ax, 5
    cmp ax, 0
    jl .no_hit_pop
    xor dx, dx
    mov cx, BRICK_WIDTH
    div cx
    cmp ax, BRICKS_PER_ROW
    jge .no_hit_pop
    pop bx
    push ax
    push bx
    mov ax, bx
    mov cx, BRICKS_PER_ROW
    mul cx
    pop bx
    pop cx
    add ax, cx
    mov si, bricks
    add si, ax
    cmp byte [si], 1
    jne .no_hit
    mov byte [si], 0
    dec word [bricks_left]
    push bx
    call get_brick_score
    mov bx, [score_multiplier]
    mul bx
    add [score], ax
    pop bx
    call try_spawn_powerup
    call sound_brick
    call draw_bricks
    call draw_score
    call draw_high_score
    neg word [ball_dy]
    popa
    ret
.no_hit_pop:
    pop ax
.no_hit:
    popa
    ret

get_brick_score:
    cmp bx, 0
    je .r0
    cmp bx, 1
    je .r1
    cmp bx, 2
    je .r2
    mov ax, 10
    ret
.r0:
    mov ax, 40
    ret
.r1:
    mov ax, 30
    ret
.r2:
    mov ax, 20
    ret

try_spawn_powerup:
    pusha
    cmp byte [powerup_active], 1
    je .skip
    mov ah, 0x00
    int 0x1A
    and dx, 0x0F
    cmp dx, 1
    jne .skip
    mov byte [powerup_active], 1
    mov word [powerup_delay], 0
    mov ax, [ball_x]
    mov [powerup_x], ax
    mov ax, [ball_y]
    mov [powerup_y], ax
    mov ah, 0x00
    int 0x1A
    and dx, 0x03
    mov [powerup_type], dl
.skip:
    popa
    ret

check_ball_lost:
    pusha
    mov ax, [ball_y]
    cmp ax, SCREEN_HEIGHT - 1
    jl .ok
    dec word [lives]
    call sound_life_lost
    call draw_lives
    mov word [score_multiplier], 1
    mov word [paddle_width], PADDLE_WIDTH
    mov byte [powerup_active], 0
    mov word [powerup_delay], 0
    mov word [ball_x], 40
    mov word [ball_y], 20
    mov word [ball_dx], 1
    mov word [ball_dy], -1
    call delay_short
.ok:
    popa
    ret

delay_short:
    pusha
    mov cx, 10
.outer:
    push cx
    mov cx, 0xFFFF
.inner:
    loop .inner
    pop cx
    loop .outer
    popa
    ret

move_powerup:
    pusha
    inc word [powerup_delay]
    mov ax, [powerup_delay]
    cmp ax, 8
    jl .no_move
    mov word [powerup_delay], 0
    call erase_powerup_pos
    inc word [powerup_y]
    mov ax, [powerup_y]
    cmp ax, SCREEN_HEIGHT - 2
    jne .draw
    mov ax, [powerup_x]
    mov bx, [paddle_x]
    cmp ax, bx
    jl .missed
    add bx, [paddle_width]
    cmp ax, bx
    jge .missed
    call activate_powerup
    mov byte [powerup_active], 0
    popa
    ret
.missed:
    mov byte [powerup_active], 0
    popa
    ret
.draw:
    call draw_powerup_pos
.no_move:
    popa
    ret

erase_powerup_pos:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, byte [powerup_y]
    mov bl, SCREEN_WIDTH
    mul bl
    add ax, [powerup_x]
    shl ax, 1
    mov di, ax
    mov ax, 0x1020
    stosw
    popa
    ret

draw_powerup_pos:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, byte [powerup_y]
    mov bl, SCREEN_WIDTH
    mul bl
    add ax, [powerup_x]
    shl ax, 1
    mov di, ax
    mov al, CHAR_POWERUP
    mov ah, COLOR_POWERUP
    stosw
    popa
    ret

activate_powerup:
    pusha
    mov al, [powerup_type]
    cmp al, POWERUP_BIG_PADDLE
    je .big
    cmp al, POWERUP_DOUBLE_PTS
    je .double
    inc word [lives]
    call sound_powerup
    call draw_lives
    popa
    ret
.big:
    mov word [paddle_width], 12
    call sound_powerup
    call draw_paddle
    popa
    ret
.double:
    mov word [score_multiplier], 2
    call sound_powerup
    popa
    ret

clear_screen:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x0720
.loop:
    stosw
    loop .loop
    popa
    ret

clear_screen_color:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x0020
.loop:
    stosw
    loop .loop
    popa
    ret

clear_screen_game:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x1020
.loop:
    stosw
    loop .loop
    popa
    ret

draw_game_screen:
    pusha
    call draw_bricks
    call draw_paddle
    call draw_ball
    call draw_score
    call draw_lives
    call draw_level
    call draw_high_score
    popa
    ret

get_brick_color:
    pusha
    cmp bx, 0
    je .r0
    cmp bx, 1
    je .r1
    cmp bx, 2
    je .r2
    mov al, COLOR_BRICK_ROW4
    jmp .done
.r0:
    mov al, COLOR_BRICK_ROW1
    jmp .done
.r1:
    mov al, COLOR_BRICK_ROW2
    jmp .done
.r2:
    mov al, COLOR_BRICK_ROW3
.done:
    mov [.temp], al
    popa
    mov al, [.temp]
    ret
.temp: db 0

draw_bricks:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    xor bx, bx
    mov dh, 2
    xor si, si
.row:
    mov dl, 5
    xor cx, cx
    push bx
    mov bx, si
    call get_brick_color
    mov byte [.color], al
    pop bx
.col:
    push si
    mov si, bricks
    add si, bx
    cmp byte [si], 0
    pop si
    je .skip
    call draw_single_brick
    jmp .next
.skip:
    call erase_single_brick
.next:
    add dl, BRICK_WIDTH
    inc bx
    inc cx
    cmp cx, BRICKS_PER_ROW
    jl .col
    inc dh
    inc si
    cmp dh, 2 + BRICK_ROWS
    jl .row
    popa
    ret
.color: db 0

draw_single_brick:
    pusha
    mov al, dh
    mov bl, SCREEN_WIDTH
    mul bl
    add al, dl
    adc ah, 0
    shl ax, 1
    mov di, ax
    mov cx, BRICK_WIDTH - 1
    mov ah, [draw_bricks.color]
    mov al, CHAR_BRICK
.loop:
    stosw
    loop .loop
    popa
    ret

erase_single_brick:
    pusha
    mov al, dh
    mov bl, SCREEN_WIDTH
    mul bl
    add al, dl
    adc ah, 0
    shl ax, 1
    mov di, ax
    mov cx, BRICK_WIDTH - 1
    mov ax, 0x1020
.loop:
    stosw
    loop .loop
    popa
    ret

draw_paddle:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, SCREEN_HEIGHT - 2
    mov bl, SCREEN_WIDTH
    mul bl
    shl ax, 1
    mov di, ax
    mov cx, SCREEN_WIDTH
    mov ax, 0x1020
.erase:
    stosw
    loop .erase
    mov al, SCREEN_HEIGHT - 2
    mov bl, SCREEN_WIDTH
    mul bl
    add ax, [paddle_x]
    shl ax, 1
    mov di, ax
    mov cx, [paddle_width]
    mov al, CHAR_PADDLE
    mov ah, COLOR_PADDLE
.draw:
    stosw
    loop .draw
    popa
    ret

draw_ball:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, byte [ball_y]
    mov bl, SCREEN_WIDTH
    mul bl
    add ax, [ball_x]
    shl ax, 1
    mov di, ax
    mov al, CHAR_BALL
    mov ah, COLOR_BALL
    stosw
    popa
    ret

erase_ball:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, byte [ball_y]
    mov bl, SCREEN_WIDTH
    mul bl
    add ax, [ball_x]
    shl ax, 1
    mov di, ax
    mov ax, 0x1020
    stosw
    popa
    ret

draw_score:
    pusha
    mov dh, 0
    mov dl, 1
    mov si, msg_score_txt
    mov bl, COLOR_SCORE
    call write_string
    mov dh, 0
    mov dl, 7
    mov ax, [score]
    mov bl, COLOR_SCORE
    call write_number
    popa
    ret

draw_lives:
    pusha
    mov dh, 0
    mov dl, 35
    mov si, msg_lives_txt
    mov bl, COLOR_SCORE
    call write_string
    mov dh, 0
    mov dl, 41
    mov ax, [lives]
    mov bl, COLOR_SCORE
    call write_number
    popa
    ret

draw_level:
    pusha
    mov dh, 0
    mov dl, 50
    mov si, msg_level_txt
    mov bl, COLOR_SCORE
    call write_string
    mov dh, 0
    mov dl, 56
    mov ax, [current_level]
    mov bl, COLOR_SCORE
    call write_number
    popa
    ret

draw_high_score:
    pusha
    mov dh, 0
    mov dl, 65
    mov si, msg_high_txt
    mov bl, COLOR_SCORE
    call write_string
    mov dh, 0
    mov dl, 71
    mov ax, [high_score]
    mov bl, COLOR_SCORE
    call write_number
    popa
    ret

show_level_complete:
    pusha
    mov dh, 12
    mov dl, 30
    mov si, msg_level_complete
    mov bl, 0x2A
    call write_string
    mov cx, 20
.delay:
    push cx
    mov cx, 0xFFFF
.inner:
    loop .inner
    pop cx
    loop .delay
    popa
    ret

show_gameover_screen:
    pusha
    call clear_screen_color
    mov dh, 10
    mov dl, 33
    mov si, msg_gameover
    mov bl, 0x4C
    call write_string
    mov dh, 12
    mov dl, 30
    mov si, msg_final
    mov bl, 0x0E
    call write_string
    mov dh, 12
    mov dl, 44
    mov ax, [score]
    mov bl, 0x0E
    call write_number
    mov dh, 14
    mov dl, 30
    mov si, msg_high_txt
    mov bl, 0x0A
    call write_string
    mov dh, 14
    mov dl, 36
    mov ax, [high_score]
    mov bl, 0x0A
    call write_number
    mov dh, 17
    mov dl, 28
    mov si, msg_continue
    mov bl, COLOR_TEXT
    call write_string
    mov ah, 0x00
    int 0x16
    popa
    ret

sound_paddle:
    pusha
    mov ah, 0x02
    int 0x16
    mov al, 182
    out 43h, al
    mov ax, 2000
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    mov ah, 0x86
    mov cx, 0
    mov dx, 0x3000
    int 0x15
    in al, 61h
    and al, 0xFC
    out 61h, al
    popa
    ret

sound_brick:
    pusha
    mov ah, 0x02
    int 0x16
    mov al, 182
    out 43h, al
    mov ax, 1500
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    mov ah, 0x86
    mov cx, 0
    mov dx, 0x4000
    int 0x15
    in al, 61h
    and al, 0xFC
    out 61h, al
    popa
    ret

sound_life_lost:
    pusha
    mov ah, 0x02
    int 0x16
    mov al, 182
    out 43h, al
    mov ax, 800
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    mov ah, 0x86
    mov cx, 0
    mov dx, 0x6000
    int 0x15
    in al, 61h
    and al, 0xFC
    out 61h, al
    popa
    ret

sound_powerup:
    pusha
    mov ah, 0x02
    int 0x16
    mov al, 182
    out 43h, al
    mov ax, 3000
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    mov ah, 0x86
    mov cx, 0
    mov dx, 0x2000
    int 0x15
    in al, 61h
    and al, 0xFC
    out 61h, al
    popa
    ret

write_string:
    pusha
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, dh
    xor ah, ah
    mov cl, SCREEN_WIDTH
    mul cl
    add al, dl
    adc ah, 0
    shl ax, 1
    mov di, ax
    mov ah, bl
.loop:
    lodsb
    cmp al, 0
    je .done
    stosw
    jmp .loop
.done:
    popa
    ret

write_number:
    pusha
    mov [.row], dh
    mov [.col], dl
    mov [.color], bl
    mov [.num], ax
    mov si, .buf + 4
    mov byte [si], 0
    dec si
    mov ax, [.num]
    mov bx, 10
    cmp ax, 0
    jne .convert
    mov byte [si], '0'
    dec si
    jmp .prep
.convert:
    cmp ax, 0
    je .prep
    xor dx, dx
    div bx
    add dl, '0'
    mov [si], dl
    dec si
    jmp .convert
.prep:
    inc si
    mov ax, VIDEO_MEM
    mov es, ax
    mov al, [.row]
    xor ah, ah
    mov cl, SCREEN_WIDTH
    mul cl
    add al, [.col]
    adc ah, 0
    shl ax, 1
    mov di, ax
    mov ah, [.color]
.write:
    lodsb
    cmp al, 0
    je .done
    stosw
    jmp .write
.done:
    popa
    ret
.row: db 0
.col: db 0
.color: db 0
.num: dw 0
.buf: times 6 db 0
