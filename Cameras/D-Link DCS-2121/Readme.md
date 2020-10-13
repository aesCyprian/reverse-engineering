# D-Link DCS-2121

## Unzipping

By unzipping the firmware update zip we can quickly confirm the file is unlikely to be encrypted with `ent`:

    Entropy = 7.682596 bits per byte.
    
    **Optimum compression would reduce the size**
    **of this 7372200 byte file by 3 percent.**
    
    Chi square distribution for 7372200 samples is 15365227.28, and randomly
    would exceed this value less than 0.01 percent of the times.
    
    Arithmetic mean value of data bytes is 120.4346 (127.5 = random).
    Monte Carlo value for Pi is 3.095889965 (error 1.45 percent).
    Serial correlation coefficient is 0.196715 (totally uncorrelated = 0.0).
    
(at least, not very well)

And this is confirmed with `file`:

    DCS-2121_fw_revALL_1-06_7712_all_en_patch01_20130502.bin: POSIX shell script executable (binary data)
    
Opening up the file we see it's a shell script with a binary blob embedded. By scrolling down a little, we see
multiple lines referring to `cramfs`:

    autoboot.bat for cramfs.
    ...
    rootfstype=cramfs \
    
Which is all very helpful!

## Cramfs

Let's strip away the shell script part of the `.bin` (`Firmware/cramfs.bin`)  and see if we can unpack the cramfs volume.

    dd bs=1 skip=2888 if=DCS-2121_fw_revALL_1-06_7712_all_en_patch01_20130502.bin of=cramfs.bin

## Unpacking

After installing `cramfsprogs`, we can use `binwalk -e` to extract the cramfs volume (`Firmware/cramfs`).

## Looking around

Clearly the DCS-2121 use lighhttpd as its web server. Apparently, a version from 2004, despite
this firmware being from 2013:

    #
    # $Id: lighttpd.conf,v 1.7 2004/11/03 22:26:05 weigon Exp $
    
Let's have a look at the process of accessing `/eng/index.cgi`.

## Authentication

According to `sym.main`, `index.cgi` finds which file you want to go to before authenticating you.

It then calls `fcn.00017654`, which I've renamed `might_go_to_url`, with an argument that
seems to be a constant string `index.cgi`. It doesn't seem to reference the original string it
compared against, interestingly.

## Root

Looking at `/etc/shadow` and `/etc/passwd`, we can see that they're symbolic links to the files `/tmp/shadow`
and `/tmp/passwd`, which are generated at every boot by `/etc/rc.d/rc.local`. Fortunately, this means it's *impossible* to
permenantly change the device's root password. Just telnet into the device with the pair `root:admin`.

    [...]
    start() {
    	touch /tmp/group /tmp/passwd /tmp/shadow
    	echo 'root:x:0:' > /etc/group
    	echo 'root:x:0:0:Linux User,,,:/:/bin/sh' > /etc/passwd
    	echo 'root:$1$gmEGnzIX$bFqGa1xIsjGupHyfeHXWR/:20:0:99999:7:::' > /etc/shadow
    [...]

## RCE
