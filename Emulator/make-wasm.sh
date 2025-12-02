cp -R ../MBios roms
emcc system.c -s WASM=1 -s USE_SDL=2 --preload-file roms -o build-wasm/index.js
rm -r roms