#!/bin/bash
TITLE="DWin - D always win!"
SIZE="1280x720"
XPORT=":8"

dub build

Xephyr -name "$TITLE" -ac -br -noreset -screen "$SIZE" "$XPORT" >/dev/null 2>&1 &
XEPHYRPID=$!
# Wait for Xephyr to start
sleep 1
DISPLAY=$XPORT

xterm &
xterm &
#lxterminal &
xeyes &

#gdb -ex start ./dwin
./dwin
kill -2 $XEPHYRPID
