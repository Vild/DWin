module dwin.script.api.ioapi;

import dwin.script.utils;

import std.stdio;
import std.file;

struct IOAPI {
	var ReadFile(var, var[] args) {
		//TODO: Restrict where to read the files from!
		return var(readText("scripts/" ~ cast(string)args[0]));
	}

	mixin ObjectWrapper;
}
