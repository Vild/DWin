module dwin.script.api.bindmanagerapi;

import dwin.log;
import dwin.script.utils;
import dwin.backend.bindmanager;

struct BindManagerAPI {
	void Init(BindManager bindManager) {
		this.bindManager = bindManager;
	}

	var Map(var, var[] args) {
		bindManager.Map(cast(string)args[0], delegate(bool v) {
			try {
				args[1](v);
			}
			catch (Exception e) { // "No such property" throws a object.Exception
				Log.MainLogger.Error("%s", e.msg);
			}
		});

		return var.emptyObject;
	}

	var Unmap(var, var[] args) {
		bindManager.Unmap(cast(string)args[0]);

		return var.emptyObject;
	}

	var IsBinded(var, var[] args) {
		return var(bindManager.IsBinded(cast(string)args[0]));
	}

	BindManager bindManager;
	mixin ObjectWrapper;
}
