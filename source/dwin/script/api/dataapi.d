module dwin.script.api.dataapi;

import dwin.script.utils;

import std.json;
import std.array;

struct DataAPI {
	var fromJson(var, var[] args) {
		return var.fromJson(cast(string)args[0]);
	}

	var toJson(var, var[] args) {
		return var(args[0].toJson);
	}

	var Split(var, var[] args) {
		if (args.length == 1)
			return var(split(cast(string)args[0]));
		else
			return var(split(cast(string)args[0], cast(string)args[1]));
	}

	var Join(var, var[] args) {
		if (args.length == 1)
			return var(join(cast(string[])args[0]));
		else
			return var(join(cast(string[])args[0], cast(string)args[1]));
	}

	mixin ObjectWrapper;
}
