# Extended ROM Jumping

An extended rom will be automatically jumped to ($C008) on boot if the rom begins with 'CART-RUN'.

# Function API

There is a function jump table located at page $FF00, as well as a subroutine to use this table (by loading the function ID into X) at $FEFD. The current functions are:

* **$00** - CIN - Read character into A (0 if none)
* **$02** - COUT - Print character in A
* **$04** - BEEP - Pitched sound based on A