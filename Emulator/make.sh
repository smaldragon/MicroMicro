rm -r build
mkdir build
cp -R ../MBios build/roms

if gcc system.c -Llib -lSDL2 -lSDL2_image; then
    mv a.out build/microemu
    cd build
    ./microemu
fi
