module dwin.script.api.keyboardapi;

import dwin.log;
import dwin.script.utils;
import dwin.io.keyboard;

struct KeyboardAPI {
	void Init(Keyboard keyboard) {
		this.keyboard = keyboard;
	}

	var Bind(var, var[] args) {
		keyboard.Map(cast(string)args[0], delegate(bool pressed) {
			try {
				args[1](pressed);
			}
			catch (Exception e) { // "No such property" throws a object.Exception
				Log.MainLogger.Error("%s", e.msg);
			}
		});

		return var.emptyObject;
	}

	var Unbind(var, var[] args) {
		keyboard.Unmap(cast(string)args[0]);

		return var.emptyObject;
	}

	var IsBinded(var, var[] args) {
		return var(keyboard.IsBinded(cast(string)args[0]));
	}

	Keyboard keyboard;
	mixin ObjectWrapper;
}
