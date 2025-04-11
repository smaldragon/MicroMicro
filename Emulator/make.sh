if [ ! -d build/ ]; then
    mkdir build
fi
if [ ! -d build/roms/ ]; then
    mkdir build/roms
fi

if gcc system.c -Llib -lSDL2 -lSDL2_image; then
    mv a.out build/microemu
    cd build
    ./microemu
fi
