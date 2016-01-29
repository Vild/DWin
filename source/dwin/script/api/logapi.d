module dwin.script.api.logapi;

import dwin.log;
import dwin.script.utils;

struct LogAPI {
	void Init() {
		log = Log.MainLogger();
	}

	var Verbose(var, var[] args) {
		log.Verbose!("SCRIPT")("%(%s, %)", args);
		return var.emptyObject;
	}

	var Debug(var, var[] args) {
		log.Debug!("SCRIPT")("%(%s, %)", args);
		return var.emptyObject;
	}

	var Info(var, var[] args) {
		log.Info!("SCRIPT")("%(%s, %)", args);
		return var.emptyObject;
	}

	var Warning(var, var[] args) {
		log.Warning!("SCRIPT")("%(%s, %)", args);
		return var.emptyObject;
	}

	var Error(var, var[] args) {
		log.Error!("SCRIPT")("%(%s, %)", args);
		return var.emptyObject;
	}

	mixin ObjectWrapper;
	Log log;
}
