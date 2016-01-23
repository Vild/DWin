# DWin - *D always win*

**PLEASE NOTE THAT DWIN IS IN A PRE-ALPHA STATE. NOT READY FOR PRODUCTION USE!**

## Description
DWin is a tiling window manager written in the lovely language called [D](//dlang.org).

It currently uses X11 as it's backend but will also be ported to wayland in the future.

##Usage

```
DWin is a tiled based window manager written in the lovely language called D
-d   --display The display to run it on
-n --no-xephyr Run it native, without Xephyr
-h      --help This help information.
```

To start DWin natively make a ~/.xinitrc file with the following content

```
dwin -d 0 -n
```

And then run `startx`

You can then:

- Spawn xterm: Ctrl + Enter
- Spawn xeyes: Ctrl + Backspace
- Move a window: Ctrl + Mouse1
- Resize a window: Ctrl + Mouse3
- Close a window: Ctrl + Shift + Escape
- Move to a workspace on the left: Ctrl + 1
- Move to a workspace on the right: Ctrl + 2
- Promote window to OnTop: Ctrl + P
- Promote window to OnTop: Ctrl + O
- Print window hierarchy: Ctrl + F5
- Kill DWin: Escape

## Authors
Dan "Wild" Printzell

## License
[Mozilla Public License, version 2.0](LICENSE)
