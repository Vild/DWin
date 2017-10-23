import std.getopt;
import dwin.dwin;
import std.process;
import std.conv;

int main(string[] args) {
	import std.stdio : writeln, writefln;

	int display = 8;
	bool noXephyr = false;

	auto result = getopt(args, "d|display", "The display to run it on", &display, "n|no-xephyr",
			"Run it native, without Xephyr", &noXephyr);

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
	if (!noXephyr) {
		import core.thread : Thread;
		import core.time : seconds;

		Xephyr = spawnProcess([`Xephyr`, `-keybd`, `ephyr,,,xkbmodel=pc105,xkblayout=se,xkbrules=evdev,xkboption=`,
				`-name`, title, `-ac`, `-br`, `-noreset`, `+extension`, `RANDR`, `+xinerama`, `-screen`, size, `:` ~ to!string(display)]);
		environment["DISPLAY"] = ":" ~ to!string(display);
		Thread.sleep(1.seconds);
	}
	scope (exit)
		if (Xephyr)
			kill(Xephyr);

	spawnProcess(["feh", "--bg-scale", "https://wallpaperscraft.com/image/black_light_dark_figures_73356_1920x1080.jpg"]);

	auto dwin = new DWin(display);
	scope (exit)
		dwin.destroy;

	dwin.Run();

	return 0;
}
