module dwin.script.api.systemapi;

import dwin.script.utils;

struct SystemAPI {
	var SpawnProcess(var, var[] args) {
		import std.process : spawnProcess;

		auto arg0 = args[0];
		string[] spawnArgs;
		if (arg0.payloadType == var.Type.String)
			spawnArgs ~= cast(string)arg0;
		else
			foreach (arg; arg0)
				spawnArgs ~= cast(string)arg;

		spawnProcess(spawnArgs);

		return var.emptyObject;
	}

	mixin ObjectWrapper;
}
