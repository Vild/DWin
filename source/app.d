import std.getopt;

int main(string[] args) {
	import std.conv : to;
	import std.process : environment;
	import std.stdio : writeln, writefln;

	string display = environment.get("DISPLAY", ":0.0");

	auto result = getopt(args,
		"d|display", "The display that TileD should start on, will fallback on $DISPLAY", &display
		);

	if (result.helpWanted) {
		defaultGetoptPrinter("TileD is a tilebased window manager written in the lovely language called D", result.options);
		return 0;
	}

	return 0;
}
