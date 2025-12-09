ATARI BREAKOUT – 16‑bit x86 Assembly Game

<img width="595" height="273" alt="image" src="https://github.com/user-attachments/assets/5e39b848-787c-4bba-a373-d52bc5d2b374" />



<img width="633" height="411" alt="image" src="https://github.com/user-attachments/assets/8ee2274c-6db6-47d1-a345-9940aee9a1dd" />

A fully playable Atari Breakout–style arcade game implemented in 16‑bit x86 assembly (NASM) for MS‑DOS / DOSBox.

This was developed as a solo university project for the course COAL (Computer Organization and Assembly Language), with the goal of practicing low‑level programming, hardware interaction, and game logic in pure assembly.

Features
Classic Breakout gameplay in 80×25 text mode

Brick system

4 rows × 10 columns = 40 bricks per level

Row‑based scoring:

Top row (red): 40 points

Second row (yellow): 30 points

Third row (green): 20 points

Bottom row (cyan): 10 points

Paddle & ball

Paddle controlled with LEFT/RIGHT arrow keys

Ball with simple physics and bounce off walls, paddle, and bricks

Level progression

Ball speed increases with each completed level (difficulty ramps up)

Power‑ups

Randomly spawned when bricks are destroyed

Types:

Big Paddle – increases paddle width

Double Points – score multiplier ×2

Extra Life – adds one life

HUD / UI

Displays:

SCORE

LIVES

LEVEL

HIGH SCORE

Welcome screen with title, rules, and current high score

“LEVEL COMPLETE” and “GAME OVER” screens

High score persistence

High score stored in HISCORE.DAT as a 2‑byte binary value

Loaded at startup and updated when beaten

PC speaker sound effects

Different tones for:

Paddle hit

Brick hit

Life lost

Power‑up collected

Controls
ENTER – Start game from welcome screen

ESC – Exit game (welcome or in‑game)

Left Arrow – Move paddle left

Right Arrow – Move paddle right

Architecture Overview
Execution Model
Target: 16‑bit real mode

Format: .COM executable (org 0x100)

Segmented memory: single code+data segment

Main Flow
_start:

Load high score from HISCORE.DAT.

Clear screen and display welcome screen (title, rules, high score).

Wait for user:

ENTER → start game

ESC → exit.

init_game:

Initialize ball, paddle, score, lives, level, multipliers, and power‑up state.

Reset all bricks.

Draw initial game screen.

game_loop (runs until exit):

handle_input – non‑blocking keyboard handling (arrow keys, ESC).

do_frame_delay – timing control via busy‑wait loop.

update_powerup – move falling power‑up (if active).

update_ball – move ball at controlled speed.

check_game_state – detect level completion or game over.

On level complete:

Show “LEVEL COMPLETE”.

Increase level and (up to a limit) increase ball speed.

Reset bricks and continue.

On game over:

Compare score and high score.

If beaten, update high_score and save to HISCORE.DAT.

Show “GAME OVER” screen with final score and high score.

Wait for any key and exit.

Technical Details
Graphics
Mode: 80×25 text mode

Video memory: segment 0xB800

Each cell: 2 bytes – one for character, one for attribute (color).

All drawing is done by writing directly to video memory:

draw_bricks, draw_paddle, draw_ball

HUD: draw_score, draw_lives, draw_level, draw_high_score

Screen clears: clear_screen, clear_screen_color, clear_screen_game

Input
BIOS keyboard interrupt: INT 16h

AH=01h – check key (non‑blocking)

AH=00h – read key (blocking)

This provides scan codes to distinguish arrows, ESC, ENTER.

File I/O (High Score)
DOS interrupt: INT 21h

AH=3Dh – open file (HISCORE.DAT)

AH=3Fh – read 2 bytes into high_score

AH=3Ch – create file if missing

AH=40h – write 2 bytes from high_score

AH=3Eh – close file

High score is stored as a 16‑bit word, allowing scores up to 65535.

Randomness / Power‑ups
BIOS timer: INT 1Ah / AH=00h

Reads system tick count.

Uses DX with bit‑masking (e.g., and dx, 0x0F) to generate simple pseudo‑random values:

1/16 chance to spawn a power‑up when a brick is destroyed.

Random selection of power‑up type.

Sound
PC speaker is controlled via:

PIT (Programmable Interval Timer): ports 43h, 42h

Speaker control: port 61h

Timing: INT 15h / AH=86h for microsecond delays per sound effect.

Different frequencies and durations are used for different game events.

Build & Run
Requirements
Assembler: NASM

Runtime: MS‑DOS, FreeDOS, or DOSBox

Build
bash
nasm -f bin breakout.asm -o breakout.com
(Replace breakout.asm with your actual filename.)

Run (DOS / DOSBox)
In DOSBox:

bash
mount c path\to\project
c:
breakout.com
Project Structure
The main file (shown in the code above) contains:

Data definitions:

Constants (equ) for screen size, colors, gameplay parameters

Game state (ball_x, ball_y, paddle_x, score, lives, etc.)

Brick array (bricks)

Power‑up state (powerup_*)

High score file name and handle

Text strings for UI

Core routines (section .text):

_start, init_game, reset_level, game_loop

Input: handle_input

Timing: do_frame_delay, delay_short

Ball: update_ball, move_ball, check_wall_x, check_wall_y, check_paddle_hit, check_brick_hit, check_ball_lost

Power‑ups: try_spawn_powerup, move_powerup, activate_powerup

Scoring & high score: get_brick_score, check_high_score, load_high_score, save_high_score

Rendering: draw_bricks, draw_paddle, draw_ball, draw_score, draw_lives, draw_level, draw_high_score, clear_screen*

Screens: show_welcome_screen, show_level_complete, show_gameover_screen, show_new_high_score

Sound: sound_paddle, sound_brick, sound_life_lost, sound_powerup

Text/number output: write_string, write_number

Educational Focus
This project was created as a solo COAL (Computer Organization and Assembly Language) assignment, focusing on:

Understanding CPU registers, memory, and stacks in real mode

Using BIOS and DOS interrupts directly

Working with hardware (PC speaker, timer, text mode video memory)

Implementing a complete game loop in pure assembly

Managing state, collisions, scoring, and persistence manually

