#!/usr/bin/env python3
v430 = bytearray(open('Firmware/sfv130_430ES.img', 'rb').read())
v410 = bytearray(open('Firmware/sfv130_410ES.img', 'rb').read())

up_to = len(v430) if len(v430) < len(v410) else len(v410)
xord = bytearray(up_to)

with open('Firmware/xor_v430v410.bin', 'wb') as out_file:
    for b in range(up_to):
        xord[b] = v430[b] ^ v410[b]
    out_file.write(xord)
