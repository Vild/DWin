module dwin.backend.engine;

import dwin.log;
import dwin.container.root;

import dwin.script.scriptmanager;
import dwin.io.mouse;
import dwin.io.keyboard;

abstract class Engine {
public:
	this(string scriptFolder) {
		this.scriptFolder = scriptFolder;
		log = Log.MainLogger;

		scriptMgr = new ScriptManager();
	}

	void RunLoop() {
		scriptMgr.Init(this, scriptFolder);
		scriptMgr.RunCtors();
		import core.thread : Thread;
		import core.time : msecs;

		quit = false;
		while (!quit) {
			foreach (cb; tickCallbacks)
				cb();
			HandleEvent();

			try {
				Thread.sleep(100.msecs);
			}
			catch (Exception) {
			}
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

	@property ScriptManager ScriptMgr() {
		return scriptMgr;
	}

	@property Root RootDisplay() {
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

	ScriptManager scriptMgr;
	Root root;
	Mouse mouse;
	Keyboard keyboard;
}
