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
	string size = "1280x720";

	auto Xephyr = spawnProcess([`Xephyr`, `-name`, title, `-ac`, `-br`, `-noreset`, `-screen`, size, `:8`]);
	scope (exit)
		kill(Xephyr);

	import core.thread : Thread;
	import core.time : seconds;

	Thread.sleep(1.seconds);

	auto dwin = new DWin();
	scope (exit)
		dwin.destroy;

	auto childEnv = environment.toAA;
	childEnv["DISPLAY"] = ":8";

	Pid xeyes;
	Pid xterm;

	scope (exit)
		kill(xeyes);
	scope (exit)
		kill(xterm);

	auto spawnThread = new Thread(() {
		Thread.sleep(1.seconds);
		spawnProcess(["feh", "--bg-scale", "http://wild.tk/DWinBG.png"], childEnv);
		xeyes = spawnProcess("xeyes", childEnv);
		xterm = spawnProcess("xterm", childEnv);

		wait(xeyes);
		wait(xterm);
	});

	spawnThread.start();

	dwin.Run();

	return 0;
}
