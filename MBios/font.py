from PIL import Image

out = [0] * 768 

with Image.open("font.png") as im:
    for y in range(48):
        for x in range(16):
            row = 0
            for b in range(4):
                c = 0
                print(x,y,b)
                #print(im.getpixel((x*4+b,y)))
                if im.getpixel((x*4+b,y)) != (0,0,0,255):
                    c = 1
                row <<= 1
                row += c
                
            out[96*(y%8)+16*int(y/8)+x] = row + (row<<4)
            
with open("font.bin","wb") as f:
    f.write(bytes(out))