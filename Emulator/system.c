#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <termios.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>

#include "w6502.c"

/* SDL */

/* must be a power of two, decrease to allow for a lower latency, increase to reduce risk of underrun. */
static Uint16 buffer_size = 4096;
static SDL_AudioDeviceID audio_device;
static SDL_AudioSpec audio_spec;
static int sample_rate = 44100;
float* audio_buf;
int    audio_buf_i;
float* psg_buf;
int    psg_buf_i;
int    psg_buf_size;

int    beep;

const int CPU_CLOCK = 4000000;
const int BAUD_CYCLES = 104 * (CPU_CLOCK/1000000);

const int screen_width = 256; const int screen_height = 240;
const uint8_t* os_keyboard;

const uint32_t tick_interval = 1000/60;
uint32_t next_time = 0;

uint8_t system_ram[0x8000];
uint8_t system_vid[32*256];
uint8_t *system_rom;
int     system_rom_size;

uint8_t *expansion_rom;
int     expansion_rom_size;
int     baud_cur;


int cur_cycle = 7;

int font[256][8][8];


uint32_t palette[16] = {
    0x000000,
    0x630000,
    0x916300,
    0xFF6300,
    
    0x009100,
    0x639100,
    0x91FF00,
    0xFFFF00,
    
    0x0000FF,
    0x6300FF,
    0x9163FF,
    0xFF63FF,
    
    0x0091FF,
    0x6391FF,
    0x91FFFF,
    0xF2FFFF,
};

uint32_t time_left(void)
{
    uint32_t now;

    now = SDL_GetTicks();
    if(next_time <= now)
        return 0;
    else
        return next_time - now;
}


int cpu_state(CPU* cpu) {
    //printf("CYCLE: %x | PC: %x INSTRUCTION: %x A: %x X: %x Y: %x STACK POINTER: %x FLAGS: %x", cpu->C, cpu->PC, cpu->I, cpu->A, cpu->X, cpu->Y, cpu->S, cpu->P);
    if (cpu->C == 1)
    printf("A:%X X:%X Y:%X P:%X SP:%X I:%X C:%X | PC:%4X \n", cpu->A, cpu->X, cpu->Y, cpu->P, cpu->S, cpu->I, cpu->C, cpu->PC);
}

static void audio_callback(void *unused, Uint8 *byte_stream, int byte_stream_length);
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

    /*
     Tell SDL to call this function (audio_callback) that we have defined whenever there is an audiobuffer ready to be filled.
     */
    want.callback = audio_callback;

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
        printf("\naudioSpec get\n");
        printf("----------------\n");
        printf("sample rate:%d\n", audio_spec.freq);
        printf("channels:%d\n", audio_spec.channels);
        printf("samples:%d\n", audio_spec.samples);
        printf("size:%d\n", audio_spec.size);
        printf("----------------\n");
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
    audio_buf = (float*) malloc(buffer_size*2*sizeof(float));
    audio_buf_i = 0;
    
    psg_buf_size = CPU_CLOCK / (int)audio_spec.freq;
    psg_buf = (float*) malloc(buffer_size*2*psg_buf_size);
    psg_buf_i = 0;
    
    SDL_PauseAudioDevice(audio_device, 0); /* unpause audio */
    return 0;
}

uint8_t system_access(CPU *cpu,ACCESS *result) {
    uint8_t operand = result->value;
    
    if (result->address < 0x8000) {
        if (result->type == READ) {
            operand = system_ram[result->address];
        } else {
            system_ram[result->address] = operand;
        }
    } else if (result->address >= 0x8000 && result->type == WRITE) {
      beep = !beep;
    } else if (result->address < 0xA000) {
        // Keyboard Reading
        operand = 0x00;
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
        
        switch ((baud_cur/208)%256) {
            case 0:     // start bit
            case 1:
            // case 2
            case 3:
            case 4:
            //case 5:
            //case 6:
            case 7:
            //case 8:
            //case 9    end bit
                operand += 128;
                break;
            default:
                operand += 0;
        }
        
    } else if (result->address >= 0xE000) { // ROM ACCESS
        int rom_address = result->address & 0x1FFF;
        operand = system_rom[rom_address];
    } else if (result->address >= 0xC000) {
        int rom_address = result->address & 0x1FFF;
        operand = expansion_rom[rom_address];
    }
    
    return operand;
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
    
    cpu->C = 0; cpu->IRQ = 0; cpu->NMI = 0; cpu->RESET = 1;
    cpu->P  = 0x24;
    cpu->S  = 0xFD;
}

int loadexrom(char* filename, CPU* cpu) 
{
	FILE *fp;
    fp = fopen(filename, "rb");
    
    // get rom size
    fseek(fp, 0L, SEEK_END);
    expansion_rom_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (expansion_rom_size > 128*32*1024) expansion_rom_size = 128*32*1024;
    
    // load the file into the rom
    expansion_rom = realloc(expansion_rom, expansion_rom_size * sizeof(int));
    fread(expansion_rom, sizeof(uint8_t), expansion_rom_size, fp);
    fclose(fp);
    
    cpu->C = 0; cpu->IRQ = 0; cpu->NMI = 0; cpu->RESET = 1;
    cpu->P  = 0x24;
    cpu->S  = 0xFD;
}


int quit = 0;


static void audio_callback(void *unused, Uint8 *byte_stream, int byte_stream_length) {

    /*
     This function is called whenever the audio buffer needs to be filled to allow
     for a continuous stream of audio.
     Write samples to byteStream according to byteStreamLength.
     The audio buffer is interleaved, meaning that both left and right channels exist in the same
     buffer.
     */

    int i;
    int16_t *s_byte_stream;
    int remain;
    
    /* zero the buffer */
    memset(byte_stream, 0, byte_stream_length);

    if(quit) {
        return;
    }

    /* cast buffer as 16bit signed int */
    s_byte_stream = (int16_t*)byte_stream;

    /* buffer is interleaved, so get the length of 1 channel */
    remain = byte_stream_length / 2;

    for (i = 0; i < remain; i += 2) {
        float average_l = audio_buf[i];
        float average_r = audio_buf[i];
        
        s_byte_stream[i] = (uint16_t)average_l;
        s_byte_stream[i+1] = (uint16_t)average_r;
    }
    
    //printf ("%i\n",audio_buf_i);
    audio_buf_i = 0;
    
    
}

int main(int argc, char *argv[])
{   
    srand(time(NULL));
    SDL_Init(SDL_INIT_VIDEO);
    
    SDL_Window* window = SDL_CreateWindow(
        "MicroMicro",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        screen_width * 2, screen_height* 2,
        SDL_WINDOW_SHOWN
    );
    SDL_Renderer* renderer = SDL_CreateRenderer(
        window,
        -1,
        0
    );
    SDL_Texture* system_screen = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_RGBA32,
        SDL_TEXTUREACCESS_STREAMING,
        256,240
    ); 
    
    SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
    
    setup_sdl_audio();
    
    w6502_setup();
    CPU cpu;
    cpu.C = 0; cpu.IRQ = 0; cpu.NMI = 0; cpu.RESET = 1;
    cpu.P  = 0x24;
    cpu.S  = 0xFD;
    initram();
    
    system_rom = realloc(system_rom, 8192 * sizeof(int));
    expansion_rom = realloc(expansion_rom, 8192 * sizeof(int));
    loadrom("roms/bios.65x",&cpu);
    
    ACCESS result;
    
    int wait = 0;
    int int_count = 0;
    int cycle_count = -1;
    
    double sbuff_wait = 0;
    double sbuff_reload = 67;
    
    SDL_Event event;
    int cycles_per_line = CPU_CLOCK / 31250;
    while (!quit) {
        if (cycle_count >= cycles_per_line*524 || cycle_count == -1) {
            if (time_left()) {continue;}
            render_screen(system_screen);
            
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, system_screen, NULL, NULL);
            SDL_RenderPresent(renderer);
            SDL_UpdateWindowSurface(window);
            
            next_time = SDL_GetTicks() + tick_interval;
            
            //if (cycle_count > 0) cpu.IRQ = 1;
            cycle_count = 0;
            
            while(SDL_PollEvent(&event)){
               switch (event.type) {
                case SDL_QUIT:
                    quit = 1; break;
                // Drag and Drop
                case SDL_DROPFILE:
                    char* filename = event.drop.file;
                    initram();
                    loadexrom(filename, &cpu);
                    SDL_free(filename);
                    break;
                case SDL_KEYDOWN:
                    switch (event.key.keysym.sym) {
                        // Warm Reset
                        case SDLK_F5:
                            cpu.C = 0;
                            cpu.RESET = 1;
                            break;
                        // Cold Reset
                        case SDLK_F6:
                            system_rom = realloc(system_rom, 8192 * sizeof(int));
                            loadrom("roms/bios.65x",&cpu);
                            cpu.C = 0;
                            cpu.RESET = 1;
                            break;
                    }
                default:
                	break;
               }
            }
          SDL_PumpEvents();
          os_keyboard = SDL_GetKeyboardState(NULL);
        }
        else {
        if (cycle_count < cycles_per_line*522) cpu.IRQ = 0; else cpu.IRQ = 1;
        //printf("\n\nø2 - %d\n", cur_cycle++);
        
        if (audio_buf_i < 4096) {
          if (psg_buf_i < psg_buf_size) {
            psg_buf[psg_buf_i] = beep?2000.0f:0.0f;
            psg_buf_i++;
          } else {
            double average;
            for (int i = 0; i < psg_buf_size; i++) {
                average += (double)psg_buf[i];
            }
            
            average /= psg_buf_size;
            audio_buf[audio_buf_i*2] = average;
            audio_buf[audio_buf_i*2+1] = average;
            audio_buf_i++;
            psg_buf_i=0;
          }
        } else { continue; }
        
        cpu_tick1(&cpu, &result);
        
        uint8_t operand = system_access(&cpu, &result);
        
        //printf(" , %xm %x @%x", result.type, operand, result.address);
        
        cpu_tick2(&cpu, operand);
        
        if (0) {
            cpu_state(&cpu);
            if (result.type == WRITE) {
            printf("Wrote %X(%c) to %4X \n", operand, operand, result.address);
            }
            else {
            printf("Read %X(%c) from %4X \n", operand, operand, result.address);
            }
        }
        int y = (cycle_count / cycles_per_line)/2;
        int x = (cycle_count % cycles_per_line) / (cycles_per_line/64);
        
        if (y < 256 && x >= 32) {
          int a = ( (y/8) ) * 256 + ( x-32 ) * 8 + ( y%8 );
          //printf("X=%i Y=%i A=%i\n",x,y,a);
          system_vid[a] = system_ram[a];
        }
        
        // baud rate counting
        cycle_count += 1;
        baud_cur +=1;
        } 
    }
    SDL_DestroyWindow(window);
    SDL_Quit();
    
    return 0;
}
