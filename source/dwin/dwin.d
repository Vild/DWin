module dwin.dwin;

import std.container.array;
import std.stdio;
import std.process;

import dwin.log;
import dwin.event;
import dwin.script.script;

import dwin.backend.engine;
import dwin.backend.window;
import dwin.backend.screen;
import dwin.backend.layout;
import dwin.backend.workspace;
import dwin.backend.container;

final class DWin {
public:
	this(int display) {
		import dwin.backend.xcb.xcb : XCB;

		log = Log.MainLogger();

		engine = new XCB(display);
		script = new Script(this, getScriptFolder);

		setup();
		sigchld(0); // Ignore when children dies
		script.RunCtors();
	}

	void Run() {
		import core.thread : Thread;
		import core.time : msecs;

		quit = false;
		while (!quit) {
			engine.DoEvent();
			try {
				Thread.sleep(10.msecs);
			}
			catch (Exception) {
			}
		}
	}

	@property.Engine Engine() {
		return engine;
	}

private:
	Script script;
	bool quit;
	Log log;
	.Engine engine;
	Window window;

	uint lastMove;

	extern (C) static void sigchld(int) nothrow @nogc {
		import core.sys.posix.signal : signal, SIGCHLD, SIG_ERR;
		import core.sys.posix.sys.wait : waitpid, WNOHANG;

		signal(SIGCHLD, &sigchld);
		while (0 < waitpid(-1, null, WNOHANG)) {
		}
	}

	/*

*/

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

	void onNewWindow(Window window) {
		auto m = engine.Mouse;
		m.Update();
		auto scr = engine.FindScreen(m.X, m.Y);
		window.Move(scr.X, scr.Y);
		window.Screen = scr;
		scr.Add(window);
	}

	void onRemoveWindow(Window window) {
		log.Info("Remove Window: %s", window);

		//auto scr = engine.FindScreen(window.X, window.Y);
		//scr.Remove(window);
		window.Parent.Remove(window);
	}

	void onRequestShowWindow(Window window) {
		log.Info("Show: %s, Desktop: %s, IsDock: %s", window, window.Desktop == uint.max, window.IsDock);
		if (window.Desktop == uint.max) {
			auto scr = window.Screen;
			scr.Remove(window);
			scr.AddOnTop(window);
			if (window.IsDock) {
				log.Info("Window %s(%s) is now the dock! %s", window.Title, window.toString, window.Strut);
				foreach (Screen s; engine.Screens) {
					s.MoveResize(cast(short)(s.X + window.Strut.left), cast(short)(s.Y + window.Strut.top),
							cast(ushort)(s.Width - window.Strut.left - window.Strut.right),
							cast(ushort)(s.Height - window.Strut.top - window.Strut.bottom));
				}
			}
		}
		window.Parent.RequestShow(window);
	}

	void onNotifyHideWindow(Window window) {
		log.Info("Hide: %s", window);
		window.Parent.NotifyHide(window);
	}

	void onRequestMoveWindow(Window window, short x, short y) {
		Window root = engine.Root;
		x = (x > root.Width - 32) ? cast(short)(root.Width - 32) : x;
		y = (y > root.Height - 32) ? cast(short)(root.Height - 32) : y;
		window.Move(x, y);
	}

	void onRequestResizeWindow(Window window, ushort width, ushort height) {
		window.Resize(width, height);
	}

	void onRequestBorderSizeWindow(Window window, ushort borderSize) {
		//TODO: implement?
	}

	void onRequestSiblingWindow(Window window, Window sibling) {
		//TODO: implement?
	}

	void onRequestStackModeWindow(Window window, ubyte stackmode) {
		//TODO: implement?
	}

	void onMouseMotion(short x, short y, uint timestamp) {
		timestamp /= 8; //TODO: Extract this to be a config flag
		auto m = engine.Mouse;
		m.Set(x, y);
		if (timestamp == lastMove)
			return;
		lastMove = timestamp;
		if (window)
			window.Parent.MouseMotion(window, m);
	}

	void setup() {
		engine.OnNewWindow ~= &onNewWindow;
		engine.OnRemoveWindow ~= &onRemoveWindow;
		engine.OnRequestShowWindow ~= &onRequestShowWindow;
		engine.OnNotifyHideWindow ~= &onNotifyHideWindow;
		engine.OnRequestMoveWindow ~= &onRequestMoveWindow;
		engine.OnRequestResizeWindow ~= &onRequestResizeWindow;
		engine.OnRequestBorderSizeWindow ~= &onRequestBorderSizeWindow;
		engine.OnRequestSiblingWindow ~= &onRequestSiblingWindow;
		engine.OnRequestStackModeWindow ~= &onRequestStackModeWindow;

		engine.OnMouseMotion ~= &onMouseMotion;

		engine.BindManager.Map("Ctrl + Alt + Shift + Escape", delegate(bool v) { quit = true; });

		engine.BindManager.Map("Ctrl + Button1", delegate(bool v) {
			auto m = engine.Mouse;
			if (v) {
				window = engine.FindWindow(m.X, m.Y);
				if (window)
					window.Parent.MouseMovePressed(window, m);
			} else {
				if (window)
					window.Parent.MouseMoveReleased(window, m);
				window = null;
			}
		});

		engine.BindManager.Map("Ctrl + Button3", delegate(bool v) {
			auto m = engine.Mouse;
			if (v) {
				window = engine.FindWindow(m.X, m.Y);
				if (window)
					window.Parent.MouseResizePressed(window, m);
			} else {
				if (window)
					window.Parent.MouseResizeReleased(window, m);
				window = null;
			}
		});

		engine.BindManager.Map("Ctrl + Shift + Escape", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				Window window = engine.FindWindow(m.X, m.Y);
				if (!window)
					return;
				window.Hide();
				window.Close();
			}
		});

		engine.BindManager.Map("Ctrl + 1", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				auto scr = engine.FindScreen(m.X, m.Y);
				scr.CurrentWorkspace(scr.CurrentWorkspace - 1);
			}
		});

		engine.BindManager.Map("Ctrl + 2", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				auto scr = engine.FindScreen(m.X, m.Y);
				scr.CurrentWorkspace(scr.CurrentWorkspace + 1);
			}
		});

		engine.BindManager.Map("Ctrl + p", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				Window window = engine.FindWindow(m.X, m.Y);
				if (!window)
					return;
				log.Info("Promoting: %s", window.Title);
				window.Parent.Remove(window);
				auto scr = window.Screen;
				scr.Workspaces[scr.CurrentWorkspace].AddOnTop(window);
			}
		});

		engine.BindManager.Map("Ctrl + o", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				Window window = engine.FindWindow(m.X, m.Y);
				if (!window)
					return;
				log.Info("Demoting: %s", window.Title);
				window.Parent.Remove(window);
				auto scr = window.Screen;
				scr.Workspaces[scr.CurrentWorkspace].Add(window);
			}
		});

		engine.BindManager.Map("Ctrl + x", delegate(bool v) {
			if (v) {
				auto m = engine.Mouse;
				m.Update();
				Window window = engine.FindWindow(m.X, m.Y);
				log.Info("1: %s", window);
				if (!window)
					return;

				import dwin.layout.tilinglayout;

				log.Info("Trying to swap: %s", window.Parent);

				if (auto layout = cast(TilingLayout)window.Parent)
					layout.Swap();
			}
		});
	}
}
