# MicroMicro

![](https://media.discordapp.net/attachments/981765485416824848/1275155935702290603/yiiipie.png?ex=6708c242&is=670770c2&hm=54e79b028233559de8f67a981f7ab9159cd7667d98175947ddda5625e0829947&)

The MicroMicro (working name) is a project designed for a series I inteded(intend) to write, about how microcomputers work and how to go about developing one. It was designed to use a relatively small amount of integrated circuits (13), not use any programmable chips, microcontrollers or obselete parts, and to be a self-contained architecture that handles its own input and output (ie. not serial based).

With these requirements in mind, the overall specs are humble but capable:
* an 65c02 8bit cpu, running at 2Mhz
* 32KiB of ram, 8K of which are video ram
* 256x240 black and white display, via vga
* 1bit "beeper" audio
* Ultra-compact 30 Key keyboard using the "gherkin" layout
* Tape Interface for loading and storing data
* Cartridge port for rom programs and peripheral expansion

*Potential Features*
* 2 atari-style joystick ports
* custom case made from pcbs

The software side is still up in the air, but I'm aiming for the following features:
* A text editor
* An high-level programming language (undecided on which)
* A built-in assembler
* Saving and loading via the tape interface

This code would likely be custom and documented to follow the article structure of the hardware side of things.
