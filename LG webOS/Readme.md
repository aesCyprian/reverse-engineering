# LG webOS

Specifically a `55LF6300-TA`.

## nmap

```
Nmap scan report for 
Host is up (0.012s latency).
Not shown: 994 closed ports
PORT     STATE SERVICE
1027/tcp open  IIS
1032/tcp open  iad3
3000/tcp open  ppp
3001/tcp open  nessus
7778/tcp open  interwise
9998/tcp open  distinct32
```

## Port 1027

XML ouput. See `port1027`.

## Port 1032

Loads an empty page.

## Port 3000

`Hello world`

Websocket `ws://0.0.0.0:3000`.

## Port 3001

Loads infinitely.

## Port 7778

No response.

## Port 9998

    Inspectable web views

    None found, make sure that you have set the developerExtrasEnabled preference property on your WebView.

Based on https://github.com/WebPlatformForEmbedded/WPEWebKit/issues/549 this message comes from
Web Platform for Embedded.

# Scratch

* https://github.com/msloth/lgtv.js/blob/master/index.js
* https://github.com/ConnectSDK/Connect-SDK-Android-Core/blob/master/src/com/connectsdk/service/WebOSTVService.java
* `ws://lgsmarttv.lan:3000`
