module dwin.script.api.ioapi;

import dwin.script.utils;

import std.stdio;
import std.file;

struct IOAPI {
	void Init(string scriptFolder) {
		this.scriptFolder = scriptFolder;
	}

	var ReadFile(var, var[] args) {
		//TODO: Restrict where to read the files from!
		return var(readText(scriptFolder ~ cast(string)args[0]));
	}

	mixin ObjectWrapper;
	string scriptFolder;
}
