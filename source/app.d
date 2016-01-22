import std.getopt;
import dwin.dwin;
import std.process;
import std.conv;

int main(string[] args) {
	import std.stdio : writeln, writefln;

	int display = 8;
	bool noXephyr = false;

	auto result = getopt(args, "d|display", "The display to run it on", &display, "o|noXephyr", "noXephyr", &noXephyr);

	if (result.helpWanted) {
		defaultGetoptPrinter("DWin is a tiled based window manager written in the lovely language called D", result.options);
		return 0;
	}

	writeln("Display: ", display, " noXephyr: ", noXephyr);

	string title = "DWin - D always win!";
	string size = "1920x1080";

	/*
		This is hardcoded for now!
		Output from `setxkbmap -query`
			rules:      evdev
			model:      pc105
			layout:     se
			options:    terminate:ctrl_alt_bksp

		Turn it into this:
			-keybd ephyr,,,xkbmodel=pc105,xkblayout=se,xkbrules=evdev,xkboption=terminate:ctrl_alt_bksp
	*/
	Pid Xephyr;
	if (!noXephyr)
		Xephyr = spawnProcess([`Xephyr`, `-keybd`, `ephyr,,,xkbmodel=pc105,xkblayout=se,xkbrules=evdev,xkboption=`,
				`-name`, title, `-ac`, `-br`, `-noreset`, `-screen`, size, `:` ~ to!string(display)]);
	scope (exit)
		if (Xephyr)
			kill(Xephyr);

	import core.thread : Thread;
	import core.time : seconds;

	auto childEnv = environment.toAA;
	childEnv["DISPLAY"] = ":" ~ to!string(display);

	Thread.sleep(1.seconds);
	spawnProcess(["feh", "--bg-scale", "http://wild.tk/DWinBG.png"], childEnv);

	auto dwin = new DWin(display);
	scope (exit)
		dwin.destroy;

	Pid xeyes;
	Pid xterm;

	scope (exit)
		kill(xeyes);
	scope (exit)
		kill(xterm);

	auto spawnThread = new Thread(() {
		Thread.sleep(1.seconds);
		xeyes = spawnProcess("xeyes", childEnv);
		xterm = spawnProcess("xterm", childEnv);

		wait(xeyes);
		wait(xterm);
	});

	spawnThread.start();

	dwin.Run();

	return 0;
}
