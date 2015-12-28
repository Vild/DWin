#!/bin/bash
TITLE="DWin - D always win!"
SIZE="1280x720"
XPORT=":8"

dub build || exit 1

Xephyr -name "$TITLE" -ac -br -noreset -screen "$SIZE" "$XPORT" >/dev/null 2>&1 &
XEPHYRPID=$!
# Wait for Xephyr to start
sleep 1
DISPLAY=$XPORT

feh --bg-max ~/Pictures/Wallpaper.arch/archwall_dark_purple.png
xterm &
xterm &
#lxterminal &
#xeyes &

#gdb -ex start ./dwin
./dwin
kill -2 $XEPHYRPID
