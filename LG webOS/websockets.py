#!/usr/bin/python3

import asyncio
import websockets

async def show_float(ws, msg):
    ws.async_send_command(f"", "request", "ssap://system.notifications/createToast", '{"message": "{msg}"')

async def main():
    async with websockets.connect(uri) as websocket:
        print('connected')

if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(main())