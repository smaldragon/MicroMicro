rm -r build
mkdir build
ln -s ../../MBios build/roms
rm w6502.c
ln -s ../kit6502/wdc65c02.c w6502.c

if gcc system.c -Llib -lSDL2 -lSDL2_image; then
    mv a.out build/microemu
    cd build
    ./microemu
fi
