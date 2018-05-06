module dwin.script.scriptmanager;

import std.stdio;
import std.file;
import std.string;
import std.algorithm.iteration;
import dwin.backend.engine;
import arsd.script;
public import dwin.script.utils;

import dwin.script.api;
import dwin.log;

class ScriptManager {
public:
	this() {
	}

	void Init(Engine engine, string scriptFolder) {
		this.scriptFolder = scriptFolder;

		engineAPI.Init(engine);
		ioAPI.Init(scriptFolder);
		keyboardAPI.Init(engine.KeyboardMgr);
		logAPI.Init();
		mouseAPI.Init(engine.MouseMgr);

		env = var.emptyObject;
		env.Data = dataAPI.Get();
		env.Engine = engineAPI.Get();
		env.Info = infoAPI.Get();
		env.IO = ioAPI.Get();
		env.Keyboard = keyboardAPI.Get();
		env.Log = logAPI.Get();
		env.Mouse = mouseAPI.Get();
		env.System = systemAPI.Get();

		foreach (file; dirEntries(scriptFolder, SpanMode.breadth).filter!(f => f.name.endsWith(".ds"))) {
			Log.MainLogger.Info("Loading script: %s", file);
			runFile(File(file, "r"));
		}
	}

	~this() {
	}

	void RunCtors() {
		foreach (idx, ctor; infoAPI.Ctors)
			ctor();
	}

	void RunDtors() {
		foreach (idx, dtor; infoAPI.Dtors)
			dtor();
	}

	void opDispatch(string func, string callerFile = __FILE__, int callerLine = __LINE__, Args...)(Args args) {
		import std.traits : isSomeString, isBasicType;
		import std.conv : to;

		string line = func ~ "(";
		foreach (idx, arg; args) {
			static if (idx)
				line ~= ", ";
			static if (isSomeString!(typeof(arg)))
				line ~= "\"" ~ arg ~ "\"";
			else static if (isBasicType!(typeof(arg)))
				line ~= to!string(arg);
			else {
				//XXX: Hack to show why the function could not be called!
				pragma(msg, callerFile, "(", callerLine,
						",1): Error: Script Function: " ~ func ~ ", Unsupported argument type: " ~ typeof(arg).stringof);
				static assert(0, "Unsupported argument type: " ~ typeof(arg).stringof);
			}
		}
		line ~= ");";
		run(line);
	}

	@property string ScriptFolder() {
		return scriptFolder;
	}

private:
	string scriptFolder;
	var env;

	DataAPI dataAPI;
	EngineAPI engineAPI;
	InfoAPI infoAPI;
	IOAPI ioAPI;
	KeyboardAPI keyboardAPI;
	LogAPI logAPI;
	MouseAPI mouseAPI;
	SystemAPI systemAPI;

	void run(string str) {
		try {
			interpret(str, env);
		}
		catch (Exception e) { // "No such property" throws a object.Exception
			Log.MainLogger.Error("%s", e.msg);
		}
	}

	void runFile(File file) {
		try {
			interpretFile(file, env);
		}
		catch (Exception e) { // "No such property" throws a object.Exception
			Log.MainLogger.Error("%s", e.msg);
		}
	}
}
