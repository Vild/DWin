module dwin.backend.engine;

import dwin.log;
import dwin.container.root;
import dwin.container.window;
import dwin.script.scriptmanager;
import dwin.io.mouse;
import dwin.io.keyboard;
import dwin.logic.logiccore;

abstract class Engine {
public:
	this(string scriptFolder) {
		this.scriptFolder = scriptFolder;
		log = Log.MainLogger;

		scriptMgr = new ScriptManager();
	}

	void RunLoop() {
		assert(logicCore);

		scriptMgr.Init(this, scriptFolder);
		scriptMgr.RunCtors();
		import core.thread : Thread;
		import core.time : msecs;

		quit = false;
		while (!quit) {
			foreach (cb; tickCallbacks)
				cb();
			HandleEvent();

			root.Update();
			/*
			try {
				Thread.sleep(100.msecs);
			}
			catch (Exception) {
			}*/
		}
		scriptMgr.RunDtors();
	}

	void RegisterTick(void delegate() cb) {
		tickCallbacks ~= cb;
	}

	abstract void HandleEvent();

	@property ref bool Quit() {
		return quit;
	}

	@property ref LogicCore Logic() {
		return logicCore;
	}

	@property ScriptManager ScriptMgr() {
		return scriptMgr;
	}

	@property Root RootContainer() {
		return root;
	}

	@property Mouse MouseMgr() {
		return mouse;
	}

	@property Keyboard KeyboardMgr() {
		return keyboard;
	}

protected:
	string scriptFolder;
	Log log;
	bool quit;
	void delegate()[] tickCallbacks;

	LogicCore logicCore;
	ScriptManager scriptMgr;
	Root root;
	Mouse mouse;
	Keyboard keyboard;

	Window[] windows;
}
