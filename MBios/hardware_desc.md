# Video RAM
* 1bit (8 horizontal pixels per byte) frame buffer with a 256x240 resolution
* Occupies RAM from 0x0200 to 0x1FFF (just above the stack page)
* Is organized as a virtual 32x30 character cell display
* * The page number indicates the row-2
* * Bits 7-3 of the address are the column
* * Bits 0-3 are the vertical offset within the character cell
* * This organization is chosen to speed up writing characters to the screen
* * bit 7 of data byte is the leftmost bit

# User RAM
* There are 24KiB of RAM Available for general purpose use from 0x2000 to 0x7FFF
* Additionally there are 512 bytes of "OS RAM" at the beggining of the address space, reserved for the 65c02 stack and zero pages

# BIOS ROM
* The BIOS Rom is 8KiB and lives at the top of memory from 0xE000 to 0xFFFF (mirrored at 0xC000-0xDFFF)

# Input Register
* The built-in input hardware is the keyboard and the audio jack and can be accessed by reading 0x8000 to 0xBFFF
* IBkk kkkk
* I - Audio Input
* B - Beeper State
* k - Keyboard/Joystick Matrix
* The keyboard row is selected with a address bitmap:
* * $BFFE [%1011 1111  1111 1110] - Keyboard Row 1
* * $BFFD [%1011 1111  1111 1101] - Keyboard Row 2
* * $BFFB [%1011 1111  1111 1011] - Keyboard Row 3
* * $BFF7 [%1011 1111  1111 0111] - Keyboard Row 4
* * $BFEF [%1011 1111  1110 1111] - Keyboard Row 5
* * $9FFF [%10x0 1111  1111 1111] - Joystick 1
* * $AFFF [%10x1 0111  1111 1111] - Joystick 2
* * Chosen to allow addition of aditional keyboard or joystick lines

## Keyboard

30 Key Gherkin Layout

```
.---.---.---.---.---.---.---.---.---.---.
| Q | W | E | R | T | Y | U | I | O | P |
|---|---|---|---|---|---|---|---|---|---|
| A | S | D | F | G | H | J | K | L |ent|
|---|---|---|---|---|---|---|---|---|---|
| Z | X | C | V |shf|alt| B | N | M |spc|
+---+---+---+---+---+---+---+---+---+---+

Numbers and Symbols are accessed using alt/shift layers

```
## Joystick


|    | bit 5 | bit 5 | bit 3| bit 2 | bit 1 | bit 0|
-----|-------|-------|------|-------|-------|------|
|    | But.L | But.R | Left | Right | Down  |  Up  |


```
Male DB9
  1
---------------------.
\ Up  Dw  Lf  Rg  x  /
 \  Tl ROW  ROW TR  /
  ------------------
  				 9
```

# Output Register
* The singular output hardware is the "beeper", a 1bit register thats used for both audio generation and storing data to memory
* Its state can be toggled by writing anywhere from 0x8000 to 0xBFFF
* Its current state can be read through bit 6 of the Input Hardware

# Expansion Port
* Can replace any section of the bios or registers in the top half of address space, with additional rom, ram or peripherals
