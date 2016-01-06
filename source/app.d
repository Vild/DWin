import std.getopt;
import dwin.dwin;

int main(string[] args) {
	import std.stdio : writeln, writefln;

	auto result = getopt(args);

	if (result.helpWanted) {
		defaultGetoptPrinter("DWin is a tiled based window manager written in the lovely language called D", result.options);
		return 0;
	}

	auto dwin = new DWin();
	scope (exit)
		dwin.destroy;

	import std.process : spawnProcess, kill;

	auto xeyes = spawnProcess("xeyes");
	scope (exit)
		kill(xeyes);

	auto xterm1 = spawnProcess("xterm");
	scope (exit)
		kill(xterm1);

	dwin.Run();

	return 0;
}
