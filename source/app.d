import std.getopt;
import dwin.dwin;
import std.process;

int main(string[] args) {
	import std.stdio : writeln, writefln;

	auto result = getopt(args);

	if (result.helpWanted) {
		defaultGetoptPrinter("DWin is a tiled based window manager written in the lovely language called D", result.options);
		return 0;
	}

	string title = "DWin - D always win!";
	string size = "1920x1080";

	/*

rules:      evdev
model:      pc105
layout:     se
options:    terminate:ctrl_alt_bksp

-keybd ephyr,,,xkbmodel=pc105,xkblayout=se,xkbrules=evdev,xkboption=terminate:ctrl_alt_bksp

*/

	auto Xephyr = spawnProcess([`Xephyr`, `-keybd`, `ephyr,,,xkbmodel=pc105,xkblayout=se,xkbrules=evdev,xkboption=`,
		`-name`, title, `-ac`, `-br`, `-noreset`, `-screen`, size, `:8`]);
	scope (exit)
		kill(Xephyr);

	import core.thread : Thread;
	import core.time : seconds;

	auto childEnv = environment.toAA;
	childEnv["DISPLAY"] = ":8";

	Thread.sleep(1.seconds);
	spawnProcess(["feh", "--bg-scale", "http://wild.tk/DWinBG.png"], childEnv);

	auto dwin = new DWin();
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
