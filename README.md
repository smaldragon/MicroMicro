# MicroMicro

The MicroMicro is a project designed for a series I inteded(intend) to write about how microcomputers work and how to go about developing one, it was designed to use a relatively small amount of ICs (13), not use any programmable chips, microcontrollers or obselete parts, and to be a self-contained architecture that handles its own input and output without needing to rely on another system (ie. not serial based).

With these requirements in mind, the overall specs are humble but capable:
* an 65c02 8bit cpu, running at 2Mhz
* 32KiB of ram, 8K of which are video ram
* 256x240 black and white display, via vga
* 1bit "beeper" audio
* Ultra-compact 30 Key keyboard using the "gherkin" layout
* Tape Interface for loading and storing data
* Cartridge port for rom programs and peripheral expansion

