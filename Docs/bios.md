# BIOS Programming Interface

## Interrupt Vectors

The Interrupt Vectors point to the following addresses in Zero Page:

* `$10-$12` - **IRQ** Video Interrupt
* `$13-$15` - **NMI** Expansion Port Interrupt

## Font

The font is located at the start of the BIOS ROM and includes 96 ASCII characters in a 4x8 resolution (768 bytes total):
* `$E000-$E05F` - Row 1
* `$E060-$E1BF` - Row 2
* `$E0C0-$E11F` - Row 3
* `$E120-$E17F` - Row 4
* `$E180-$E1DF` - Row 5
* `$E1E0-$E23F` - Row 6
* `$E240-$E2BF` - Row 7
* `$E2A0-$E2FF` - Row 8

## Control Codes

The MicroMicro uses the following control codes:

## Function API

There is a function jump table located in page $FF00. The current functions are:

* `jsr $FF00` **CIN**  - Returns input character into A (0 if none)
* `jsr $FF03` **COUT**  - Print character in A
* `jsr $FF06` **BEEP** - Pitched sound based on A
* `jsr $FF09` **CMDIN** - Read Command-Line Input, returns start of string into X (zero page address), length of string into Y
* `jsr $FF0C` **GETCURSOR** - Get Current Cursor Position in X (0-63) and Y (0-29)
* `jsr $FF0F` **SETCURSOR** - Set Current Cursor Position using X (0-63) and Y (0-29)

### Control Codes

`CIN`/`COUT` use the following control codes:

* `$03` **ETX** - Escape/Ctrl-C
* `$07` **BEL** - Play a Beep
* `$08` **BS**  - Backspace
* `$0A` **LF**  - Newline
* `$0C` **FF**  - Clear the screen
* `$0D` **CR**  - Return to start of line
* `$10` **CHI** - Turn on Highlighted Text
* `$11` **CNO** - Turn off Highlighted Text
* `$12` **FON** - Turn on the footer
* `$13` **FOF** - Turn off the footer
* `$7F` **DEL** - Erase character at cursor

## Run Carts

An extended rom subroutine will be automatically jumped to (`$C008`) on boot if the rom begins with 'CART-RUN'.

## Command Carts

An extended rom can add new commands to the bios if it beings with 'CART-CMD'. This extra command table beings at `$C008` and uses the same format as the main bios table.

Each table entry is 8 bytes, 6 bytes for the command name, followed by 2 bytes with the subroutine address, the table is terminated with a single zero-byte.
