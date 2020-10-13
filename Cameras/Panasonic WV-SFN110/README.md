# Panasonic WV-SFN110

## binwalk

We can extract two files using `binwalk --dd='.*' -Me sfv130_430ES.img`:

* MySQL MyISAM index file Version 10 - I've renamed `binwalk/wvsfn110.myi`
* MySQL ISAM compressed data file Version 10 - I've renamed `binwalk/table`

### Encrypted?

According to a binvis graph (`Firmware/binwalk/table.png`) this data is highly random and either
encrypted, compressed, or junk. But given the files are un{encrypted, compresed} according to
`file`, I think these are false-positives.

# Okay, so it's encrypted

Let's compare this version, version 4.30, with an older version, 4.10
(`Firmware/sfv130_410ES.img`), by XORing them (`Firmware/xor_v430v410.bin`) using `xor_firmware.py`.

Now we can compare them with binvis to see if there's any less random areas (`Firmware/xor_v430v410.png`).

Looking at the image, we can see that a huge chunk of the two files (from `00000000` to exactly `00400080`) 
are nearly completely identical. The only differences are:

* `00000002` - `00000005` - **The firmware version!**
    * v4.30: `0x33304532` - ASCII `30E2`
    * v4.10: `0x31304531` - ASCII `10E1`
    * `00000000` - `00000001` is ASCII `4`. That makes ASCII `430E2` and `410E1` respectively!
* `00000010` - `00000011` - **Unknown**
    * v4.30: `0x2E26`
    * v4.10: `0xE625` 
* `00000020` - `00000021` - **Unknown**
    * v4.30: `0x92BF`
    * v4.10: `0x733C`
* `0000007E` - `0000007F` - **Unknown**
    * v4.30: `0xC099`
    * v4.10: `0x0598`

# Scratch

**You can probably ignore this**

