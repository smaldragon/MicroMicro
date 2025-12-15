ln -s ../MBios roms
rm w6502.c
ln -s ../kit6502/wdc65c02.c w6502.c

emcc -O3 system.c -s WASM=1 -s USE_SDL=2 --preload-file roms -o build-wasm/index.js

rm -r roms
