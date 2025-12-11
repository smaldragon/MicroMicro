#include <stdio.h>
#include <SDL2/SDL.h>
#include <time.h>

#ifdef EMSCRIPTEN
#include <emscripten.h>
#endif

#include "w6502.c"

/* SDL */
SDL_Window* window;
SDL_Renderer* renderer;
SDL_Texture* system_screen;
SDL_Event event;
int quit = 0;

// Timing
const int CPU_CLOCK = 2000000;
const int CYCLES_PER_LINE = CPU_CLOCK / 31250;
const int CYCLES_PER_FRAME = CYCLES_PER_LINE * 524;

const uint32_t tick_interval = 1000/60;
uint32_t next_time = 0;

// Hardware
CPU cpu;
uint8_t system_ram[0x8000];
uint8_t system_vid[32*256];
const int screen_width = 256; const int screen_height = 240;
uint8_t *system_rom;
int     system_rom_size;

uint8_t *expansion_rom;
int     expansion_rom_size;
uint8_t expansion_rom_bank;

int    beep;
const uint8_t* os_keyboard;

// Audio Buffer
static Uint16 buffer_size = 4096;
static SDL_AudioDeviceID audio_device;
static SDL_AudioSpec audio_spec;
static int sample_rate = 48000;
uint16_t* audio_buf;
int    audio_buf_i;
int    audio_buf_size;
float* psg_buf;
int    psg_buf_i;
int    psg_buf_size;

uint32_t time_left(void)
{
    uint32_t now;

    now = SDL_GetTicks();
    if(next_time <= now)
        return 0;
    else
        return next_time - now;
}

static int setup_sdl_audio(void) {

    SDL_AudioSpec want;

    SDL_Init(SDL_INIT_AUDIO | SDL_INIT_TIMER);

    SDL_zero(want);
    SDL_zero(audio_spec);

    want.freq = sample_rate;
    /* request 16bit signed little-endian sample format */
    want.format = AUDIO_S16LSB;
    /* request 2 channels (stereo) */
    want.channels = 2;
    want.samples = buffer_size;

    if(1) {
        printf("\naudioSpec want\n");
        printf("----------------\n");
        printf("sample rate:%d\n", want.freq);
        printf("channels:%d\n", want.channels);
        printf("samples:%d\n", want.samples);
        printf("----------------\n\n");
    }

    audio_device = SDL_OpenAudioDevice(NULL, 0, &want, &audio_spec, 0);
    
    if(1) {
        printf("\naudioSpec got\n");
        printf("----------------\n");
        printf("sample rate:%d\n", audio_spec.freq);
        printf("channels:%d\n", audio_spec.channels);
        printf("samples:%d\n", audio_spec.samples);
        printf("----------------\n\n");
    }

    if (audio_device == 0) {
        if(1) {
            printf("\nFailed to open audio: %s\n", SDL_GetError());
        }
        return 1;
    }

    if (audio_spec.format != want.format) {
        if(1) {
            printf("\nCouldn't get requested audio format.\n");
        }
        return 2;
    }

    buffer_size = audio_spec.samples;
    audio_buf_size = buffer_size*2*sizeof(uint16_t);
    audio_buf = (uint16_t*) malloc(audio_buf_size);
    audio_buf_i = 0;
    
    psg_buf_size = CPU_CLOCK / (int)audio_spec.freq;
    psg_buf = (float*) malloc(buffer_size*2*psg_buf_size);
    psg_buf_i = 0;
    
    SDL_PauseAudioDevice(audio_device, 0); /* unpause audio */
    return 0;
}

int system_reset(CPU *cpu) {
    cpu->C = 0;
    cpu->IRQ = 0;
    cpu->NMI = 0;
    cpu->RESET = 1;
    expansion_rom_bank = 0;
    
    return 0;
}

uint8_t system_access(CPU *cpu,ACCESS *result) {
    uint8_t operand = result->value;
    if (result->type == READ)
        operand = 0x00;
    
    // RAM (RW 0xxx xxxx xxxx xxxx)
    if (!(result->address & 0x8000)) {
        if (result->type == READ) {
            operand = system_ram[result->address];
        } else {
            system_ram[result->address] = operand;
        }
    }
    // BEEP (W 1xxx xxxx xxxx xxxx)
    if (result->address & 0x8000 && result->type == WRITE) {
      beep = !beep;
    }
    // INPUT (RW 10xx xxxx xxxx xxxx)
    if ( (result->address & 0x8000) && !(result->address & 0x4000)) {
        // Keyboard Reading
        int row = -1; //(result->address & 0xF0) >> 4;
        if (!(result->address & 0x01))
          row = 0;
        if (!(result->address & 0x02))
          row = 1;
        if (!(result->address & 0x04))
          row = 2;
        if (!(result->address & 0x08))
          row = 3;
        if (!(result->address & 0x10))
          row = 4;
        uint8_t alt = os_keyboard[SDL_SCANCODE_LALT] || os_keyboard[SDL_SCANCODE_RALT];
    	  int alt_list[22] = {
            SDL_SCANCODE_0,
            SDL_SCANCODE_1,
            SDL_SCANCODE_2,
            SDL_SCANCODE_3,
            SDL_SCANCODE_4,
            SDL_SCANCODE_5,
            SDL_SCANCODE_6,
            SDL_SCANCODE_7,
            SDL_SCANCODE_8,
            SDL_SCANCODE_9,
            
            SDL_SCANCODE_KP_0,
            SDL_SCANCODE_KP_1,
            SDL_SCANCODE_KP_2,
            SDL_SCANCODE_KP_3,
            SDL_SCANCODE_KP_4,
            SDL_SCANCODE_KP_5,
            SDL_SCANCODE_KP_6,
            SDL_SCANCODE_KP_7,
            SDL_SCANCODE_KP_8,
            SDL_SCANCODE_KP_9,
            
            SDL_SCANCODE_DELETE,
            SDL_SCANCODE_BACKSPACE,
        };
        
        for (int i = 0; i < 22; i++) {
            if (os_keyboard[alt_list[i]]) {
                alt = 1;
            }
        }
        
        uint8_t shift = os_keyboard[SDL_SCANCODE_LSHIFT] || os_keyboard[SDL_SCANCODE_RSHIFT];
        
        int shift_list[1] = {
            SDL_SCANCODE_DELETE,
        };
        
        for (int i = 0; i < 1; i++) {
            if (os_keyboard[shift_list[i]]) {
                shift = 1;
            }
        }
        
        switch (row) {
          case 0:
              if (os_keyboard[SDL_SCANCODE_Q] | 
                  os_keyboard[SDL_SCANCODE_1] | 
                  os_keyboard[SDL_SCANCODE_KP_1] )
                operand |= 0x01;
              if (os_keyboard[SDL_SCANCODE_A]) 
                operand |= 0x02;
              if (os_keyboard[SDL_SCANCODE_LSHIFT]|shift) 
                operand |= 0x04;
              if (os_keyboard[SDL_SCANCODE_Z]) 
                operand |= 0x08;
              if (os_keyboard[SDL_SCANCODE_S]) 
                operand |= 0x10;
              if (os_keyboard[SDL_SCANCODE_W] | 
                  os_keyboard[SDL_SCANCODE_2] | 
                  os_keyboard[SDL_SCANCODE_KP_2] ) 
                operand |= 0x20;
              
              break;
         	case 1:
              if (os_keyboard[SDL_SCANCODE_E] | 
                  os_keyboard[SDL_SCANCODE_3] | 
                  os_keyboard[SDL_SCANCODE_KP_3] )
                operand |= 0x01;
              if (os_keyboard[SDL_SCANCODE_D]) operand        |= 0x02;
              if (os_keyboard[SDL_SCANCODE_X]) operand        |= 0x04;
              if (os_keyboard[SDL_SCANCODE_C]) operand        |= 0x08;
              if (os_keyboard[SDL_SCANCODE_F]) operand        |= 0x10;
              if (os_keyboard[SDL_SCANCODE_R] | 
                  os_keyboard[SDL_SCANCODE_4] | 
                  os_keyboard[SDL_SCANCODE_KP_4] ) 
                operand |= 0x20;
              
              break;
          case 2:
              if (os_keyboard[SDL_SCANCODE_T] | 
                  os_keyboard[SDL_SCANCODE_5] | 
                  os_keyboard[SDL_SCANCODE_KP_5] )
                operand |= 0x01;
              if (os_keyboard[SDL_SCANCODE_G]) operand        |= 0x02;
              if (os_keyboard[SDL_SCANCODE_V]) operand        |= 0x04;
              if (os_keyboard[SDL_SCANCODE_B]) operand        |= 0x08;
              if (os_keyboard[SDL_SCANCODE_H]) operand        |= 0x10;
              if (os_keyboard[SDL_SCANCODE_Y] | 
                  os_keyboard[SDL_SCANCODE_6] | 
                  os_keyboard[SDL_SCANCODE_KP_6] ) 
                operand |= 0x20;
              
              break;
          case 3:
              if (os_keyboard[SDL_SCANCODE_U] | 
                  os_keyboard[SDL_SCANCODE_7] | 
                  os_keyboard[SDL_SCANCODE_KP_7] )
                operand |= 0x01;
              if (os_keyboard[SDL_SCANCODE_U]) operand        |= 0x01;
              if (os_keyboard[SDL_SCANCODE_J]) operand        |= 0x02;
              if (os_keyboard[SDL_SCANCODE_N]) operand        |= 0x04;
              if (os_keyboard[SDL_SCANCODE_M]) operand        |= 0x08;
              if (os_keyboard[SDL_SCANCODE_K]) operand        |= 0x10;
              if (os_keyboard[SDL_SCANCODE_I] | 
                  os_keyboard[SDL_SCANCODE_8] | 
                  os_keyboard[SDL_SCANCODE_KP_8] ) 
                operand |= 0x20;
              
              break;
          case 4:
              if (os_keyboard[SDL_SCANCODE_O] | 
                  os_keyboard[SDL_SCANCODE_9] | 
                  os_keyboard[SDL_SCANCODE_KP_9] )
                operand |= 0x01;
              if (os_keyboard[SDL_SCANCODE_L]) operand        |= 0x02;
              if (os_keyboard[SDL_SCANCODE_SPACE]) operand    |= 0x04;
              if (os_keyboard[SDL_SCANCODE_RALT]|alt) operand |= 0x08;
              if (os_keyboard[SDL_SCANCODE_RETURN]||
                  os_keyboard[SDL_SCANCODE_BACKSPACE]) operand|= 0x10;
              if (os_keyboard[SDL_SCANCODE_P] | 
                  os_keyboard[SDL_SCANCODE_0] | 
                  os_keyboard[SDL_SCANCODE_KP_0] ) 
                operand |= 0x20;
              
              break;
        }
        operand |= ((!beep) & 1) << 6;
    }
    // BIOS
    // (RW 1x1x xxxx xxxx xxxx)
    if ( (result->address & 0x8000) && (result->address & 0x2000)) {
        int rom_address = result->address & 0x1FFF;
        operand |= system_rom[rom_address];
    }
    // EXPANSION ROM (RW 110x xxxx xxxx xxxx)
    if (result->address >= 0xC000 && result->address < 0xE000) {
        int rom_address = result->address & 0x1FFF;
        operand |= expansion_rom[(expansion_rom_bank*8192 + rom_address) % expansion_rom_size];
    }
    // EXPANSION ROM BANK
    // (RW 101x xxxx xxxx xxxx)
    if (result->address >= 0xA000 && result->address < 0xC000) {
        expansion_rom_bank = (result->address) & 0xFF;
    }
    
    return operand;
}

int initram()
{
    for (int i = 0; i < 0x7000; i++) {
        system_ram[i] = rand();
    }
    beep = 0;
}

int loadrom(char* filename, CPU* cpu) 
{
	FILE *fp;
    fp = fopen(filename, "rb");
    
    // get rom size
    fseek(fp, 0L, SEEK_END);
    system_rom_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (system_rom_size > 128*32*1024) system_rom_size = 128*32*1024;
    
    // load the file into the rom
    system_rom = realloc(system_rom, system_rom_size * sizeof(int));
    fread(system_rom, sizeof(uint8_t), system_rom_size, fp);
    fclose(fp);
}

int loadexrom(char* filename, CPU* cpu) 
{
    FILE *fp;
    fp = fopen(filename, "rb");
    
    // get rom size
    fseek(fp, 0L, SEEK_END);
    int file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    
    expansion_rom_size = 8192;
    while (expansion_rom_size < file_size) {
        expansion_rom_size *= 2;
    }
    if (expansion_rom_size > 8192*256) expansion_rom_size = 8192*256;
    expansion_rom_bank = 0;
    
    // load the file into the rom
    expansion_rom = realloc(expansion_rom, expansion_rom_size * sizeof(uint8_t));
    
    fread(expansion_rom, sizeof(uint8_t), file_size, fp); fclose(fp);
    
    for (int i = file_size; i < expansion_rom_size; i++) {
        expansion_rom[i] = 0;
    }
    
    printf("Loaded expansion rom \"%s\" (%i bytes) \n", filename, expansion_rom_size);
}


int render_screen(SDL_Texture* texture) {
    int *pixels = NULL;
    int pitch;
    
    SDL_LockTexture(texture, NULL, (void **) &pixels,&pitch);

    for (int i = 0; i < screen_width*screen_height; i++) {
        int x = i%screen_width;
        int y = i/screen_width;
        
        // Address structure
        // 000y yyyy  xxxx xyyy
        int a =   ( (y/8) + 2) * 256
                + ( (x/8) ) * 8
                + ( y%8 );
        int o = 7-(x%8);
        
        int p = (system_vid[a] >> o) & 1;
        
        if (p)
            pixels[x + y*(pitch/4)] = 0xFFFFFF;
        else
            pixels[x + y*(pitch/4)] = 0x000000;
    }
    SDL_UnlockTexture(texture);

}

void main_loop()
{
    // Input
    //SDL_PumpEvents();
    os_keyboard = SDL_GetKeyboardState(NULL);

    while(SDL_PollEvent(&event)){
        switch (event.type) {
        case SDL_QUIT:
            quit = 1;
            break;
        // Drag and Drop
        case SDL_DROPFILE:
            char* filename = event.drop.file;
            initram();
            loadexrom(filename, &cpu);
            SDL_free(filename);
            system_reset(&cpu);
            break;
        case SDL_KEYDOWN:
            switch (event.key.keysym.sym) {
                // Warm Reset
                case SDLK_F5:
                    system_reset(&cpu);
                    break;
                // Cold Reset
                case SDLK_F6:
                    system_rom = realloc(system_rom, 8192 * sizeof(int));
                    loadrom("roms/bios.65x",&cpu);
                    break;
            }
        default:
            break;
        }
    }

    // Emulation
    int cycle_count = 0;
    
    // Fallback if audio device isn't playing
    int audio_timeout = SDL_GetTicks() + tick_interval * 5;
    while (cycle_count < CYCLES_PER_FRAME) {
        
        // AUDIO
        if (SDL_GetQueuedAudioSize(audio_device) > audio_buf_size * 3) {
          if (SDL_GetTicks() < audio_timeout) {
            continue;
          }
        } else {
        if (psg_buf_i < psg_buf_size) {
          psg_buf[psg_buf_i] = beep?2000.0f:0.0f;
          psg_buf_i++;
        }
        if (psg_buf_i == psg_buf_size) {
          double average;
          for (int i = 0; i < psg_buf_size; i++) {
              average += (double)psg_buf[i];
          }

          average /= psg_buf_size;
          audio_buf[audio_buf_i*2] = (uint16_t)average;
          audio_buf[audio_buf_i*2+1] = (uint16_t)average;
          audio_buf_i++;
          psg_buf_i=0;
        }
        if (audio_buf_i >= buffer_size) {
          audio_buf_i = 0;
          SDL_QueueAudio(audio_device, audio_buf, audio_buf_size);
        }
        }
        
        // IRQ
        if (cycle_count < CYCLES_PER_LINE*522) cpu.IRQ = 0; else cpu.IRQ = 1;

        //  CPU
        ACCESS result;
        cpu_tick1(&cpu, &result);
        uint8_t operand = system_access(&cpu, &result);
        cpu_tick2(&cpu, operand);

        // Display
        int y = (cycle_count / CYCLES_PER_LINE)/2;
        int x = (cycle_count % CYCLES_PER_LINE) / (CYCLES_PER_LINE/64);
        if (y < 256 && x >= 32) {
          int a = ( (y/8) ) * 256 + ( x-32 ) * 8 + ( y%8 );
          system_vid[a] = system_ram[a];
        }

        cycle_count++;
    }

    // Render
    while (time_left()) {}
    render_screen(system_screen);
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, system_screen, NULL, NULL);
    SDL_RenderPresent(renderer);
    SDL_UpdateWindowSurface(window);
    next_time = SDL_GetTicks() + tick_interval;
}

int main(int argc, char *argv[])
{   
    srand(time(NULL));
    SDL_Init(SDL_INIT_VIDEO);
    
    window = SDL_CreateWindow(
        "MicroMicro",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        screen_width * 2, screen_height* 2,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    
    renderer = SDL_CreateRenderer(
        window,
        -1,
        0
    );
    SDL_RenderSetLogicalSize(renderer,256,240);
    SDL_RenderSetIntegerScale(renderer,1);
    
    // This needs to be done after the creation of the renderer due to a bug in older sdl2 versions
    // https://github.com/libsdl-org/SDL/issues/8805
    SDL_SetWindowMinimumSize(window,256,240);
    
    system_screen = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_RGBA32,
        SDL_TEXTUREACCESS_STREAMING,
        256,240
    ); 
    
    SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
    
    setup_sdl_audio();
    
    w6502_setup();
    initram();
    loadrom("roms/bios.65x",&cpu);
    // Empty Expansion Rom
    expansion_rom = realloc(expansion_rom, 8192 * sizeof(uint8_t));
    expansion_rom_size = 8192;
    
    system_reset(&cpu);

    #ifdef EMSCRIPTEN
    emscripten_set_main_loop(main_loop, -1, 1);
    #else
    while (!quit){
      main_loop();
    }
    #endif

    SDL_DestroyWindow(window);
    SDL_Quit();
    
    return 0;
}
