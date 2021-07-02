# Utility for converting Aliens color palette from linear logical addresses mame format (hexadecimal text format)
# to physical format (two banks SRAM with scrambled address lines) verilog hexmem format.
# Author: @RndMnkIII.
# Date: 02/07/2021.
# Edit filenames in script to match the corresponding files.
# Open a console and execute: python3 cram_addr_conv.py

from ctypes import c_uint16, c_uint8
from random import randint, seed
import sys

### CRAM memory banks init ###
valor:c_uint8=0

cram = []
for i in range(0,0x400):
    cram.append(valor)

cram_e14 = []
for i in range(0,0x200):
    cram_e14.append(valor)

cram_e15 = []
for i in range(0,0x200):
    cram_e15.append(valor)

def cram_write(addr: c_uint16, data: c_uint8) -> c_uint16:
    bank = addr & 0x1 #A0=0 even addr, data store in e15 (upper),else A0=1 odd addr stored in e14
    new_addr:c_uint16 = 0
    if (bank==0):
        new_addr |= (addr & 0x2)        #A1 -> A1 
        new_addr |= ((addr & 0x4)<<2)   #A2 -> A4
        new_addr |= ((addr & 0x8)>>1)   #A3 -> A2
        new_addr |= ((addr & 0x10)>>1)   #A4 -> A3
        new_addr |= ((addr & 0x20)<<3)   #A5 -> A8
        new_addr |= ((addr & 0x40)<<1)   #A6 -> A7
        new_addr |= ((addr & 0x80)>>1)   #A7 -> A6
        new_addr |= ((addr & 0x100)>>8)   #A8 -> A0
        new_addr |= ((addr & 0x200)>>4)   #A9 -> A5
        cram_e15[new_addr] = data
        return new_addr
    else:
        new_addr |= (addr & 0x2)        #A1 -> A1 
        new_addr |= ((addr & 0x4)<<2)   #A2 -> A4
        new_addr |= ((addr & 0x8)>>1)   #A3 -> A2
        new_addr |= ((addr & 0x10)>>1)   #A4 -> A3
        new_addr |= ((addr & 0x20)<<2)   #A5 -> A7
        new_addr |= ((addr & 0x40)<<2)   #A6 -> A8
        new_addr |= ((addr & 0x80)>>1)   #A7 -> A6
        new_addr |= ((addr & 0x100)>>8)   #A8 -> A0
        new_addr |= ((addr & 0x200)>>4)   #A9 -> A5
        cram_e14[new_addr] = data
        return new_addr

def cram_read(addr: c_uint16) -> c_uint8:        
    bank = addr & 0x1 #A0=0 even addr, data store in e15 (upper),else A0=1 odd addr stored in e14
    new_addr:c_uint16 = 0
    if (bank==0):
        new_addr |= (addr & 0x2)        #A1 -> A1 
        new_addr |= ((addr & 0x4)<<2)   #A2 -> A4
        new_addr |= ((addr & 0x8)>>1)   #A3 -> A2
        new_addr |= ((addr & 0x10)>>1)   #A4 -> A3
        new_addr |= ((addr & 0x20)<<3)   #A5 -> A8
        new_addr |= ((addr & 0x40)<<1)   #A6 -> A7
        new_addr |= ((addr & 0x80)>>1)   #A7 -> A6
        new_addr |= ((addr & 0x100)>>8)   #A8 -> A0
        new_addr |= ((addr & 0x200)>>4)   #A9 -> A5
        return cram_e15[new_addr]
    else:
        new_addr |= (addr & 0x2)        #A1 -> A1 
        new_addr |= ((addr & 0x4)<<2)   #A2 -> A4
        new_addr |= ((addr & 0x8)>>1)   #A3 -> A2
        new_addr |= ((addr & 0x10)>>1)   #A4 -> A3
        new_addr |= ((addr & 0x20)<<2)   #A5 -> A7
        new_addr |= ((addr & 0x40)<<2)   #A6 -> A8
        new_addr |= ((addr & 0x80)>>1)   #A7 -> A6
        new_addr |= ((addr & 0x100)>>8)   #A8 -> A0
        new_addr |= ((addr & 0x200)>>4)   #A9 -> A5
        return cram_e14[new_addr]

def read_CRAM_mame(fname):
    with open(fname, 'r') as myFile: # This closes the file for you when you are done
        contents = myFile.read()

    count = 0
    for i in contents.split():
        valor = int(i,16)
        #print (f"{count:03X}: {int(i,16):02X}")
        new_addr=cram_write(addr=count, data=valor)
        print(f"{count:03X} -> {new_addr:03X}: {valor:02X}")
        cram[new_addr] = valor
        count +=1
    print("------------------------------") 

if __name__ == "__main__":

    read_CRAM_mame("ALIENS_TITLE_CRAM.hex")   

    with open("ALIENS_TITLE_CRAM_E15.hex", "w") as f:
        for i in range(0x0, 0x200):
            print(f"@{i:03X} {cram_e15[i]:02X}", file=f)

    with open("ALIENS_TITLE_CRAM_E14.hex", "w") as f:
        for i in range(0x0, 0x200):
            print(f"@{i:03X} {cram_e14[i]:02X}", file=f)