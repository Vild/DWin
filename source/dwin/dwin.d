module dwin.dwin;

import std.container.array;
import std.stdio;
import std.process;

import dwin.log;
import dwin.event;

import dwin.backend.engine;

final class DWin {
public:
	this() {
		log = Log.MainLogger();

		version (Wayland) {
			import dwin.backend.wayland.engine : WaylandEngine;

			engine = new WaylandEngine(getScriptFolder);
		} else {
			import dwin.backend.xcb.engine : XCBEngine;

			engine = new XCBEngine(getScriptFolder);
		}
		setup();
	}

	void Run() {
		engine.RunLoop();
	}

private:
	Log log;
	Engine engine;

	string getScriptFolder() {
		import std.file : exists, thisExePath;
		import std.array : split, join;
		import std.string : startsWith;
		import std.path : dirName;

		environment["DWIN_EXEPATH"] = thisExePath.dirName;

		//dfmt off
		static string[] searchPaths = [
			"$PWD/.dwin/scripts/",
			"$XDG_CONFIG_HOME/dwin/scripts/",
			"$HOME/.dwin/scripts/",
			"$DWIN_EXEPATH/scripts/",
			"/usr/share/dwin/scripts/"
		];
		//dfmt on

		foreach (path; searchPaths) {
			string[] part = path.split("/");

			foreach (ref p; part) {
				if (p.startsWith("$"))
					p = environment.get(p[1 .. $]);
			}

			path = part.join("/");

			log.Info("Checking for script folder: %s", path);

			if (exists(path))
				return path;
		}

		log.Fatal("Could not find a script folder!");
		assert(0);
	}

	void setup() {
		import dwin.logic.logiccore;
		import dwin.container.window;
		import core.sys.posix.signal : signal, SIGCHLD, SIG_IGN;

		signal(SIGCHLD, SIG_IGN);
		
		engine.Logic = new class ILogicCore {
			void NewWindow(Window window) {
				log.Info("Window: %s", window);
			}
			
			void RemoveWindow(Window window) {
				log.Info("Window: %s", window);
			}
	
			void ShowWindow(Window window) {
				log.Info("Window: %s", window);
				window.Show();
			}
			
			void WindowHidden(Window window) {
				log.Info("Window: %s", window);
				window.Hide();
			}
		};
	}
}
