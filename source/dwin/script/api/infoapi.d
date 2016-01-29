module dwin.script.api.infoapi;

import dwin.script.utils;

struct InfoAPI {
	var AddCtor(var, var[] args) {
		Ctors[cast(string)args[0]] = args[1];
		return var.emptyObject;
	}

	var AddDtor(var, var[] args) {
		Dtors[cast(string)args[0]] = args[1];
		return var.emptyObject;
	}

	mixin ObjectWrapper;

	var[string] Ctors;
	var[string] Dtors;
}
