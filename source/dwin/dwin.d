module dwin.dwin;

import std.stdio;

import dwin.log;
import dwin.event;
import dwin.script.script;

import dwin.backend.engine;
import dwin.backend.window;
import dwin.backend.screen;
import dwin.backend.layout;
import dwin.backend.workspace;
import dwin.backend.container;

import std.container.array;

final class DWin {
public:
	this(int display) {
		import dwin.backend.xcb.xcb : XCB;

		log = Log.MainLogger();

		engine = new XCB(display);
		script = new Script(this);

		setup();
		sigchld(0); // Ignore when children dies
		script.RunCtors();
	}

	void Run() {
		quit = false;
		while (!quit)
			engine.DoEvent();
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

	void onNewWindow(Window window) {
		auto m = engine.Mouse;
		m.Update();
		auto scr = engine.FindScreen(m.X, m.Y);
		window.Screen = scr;
		window.Move(scr.X, scr.Y);
		scr.Add(window);
	}

	void onRemoveWindow(Window window) {
		log.Info("Remove Window: %s", window);

		window.Parent.Remove(window);
	}

	void onRequestShowWindow(Window window) {
		log.Info("Show: %s", window);
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

		engine.BindManager.Map("Escape", delegate(bool v) { quit = true; });

		engine.BindManager.Map("Ctrl + F5", delegate(bool v) {
			if (v)
				printHierarchy();
		});

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
	}

	void print(Screen screen, int indent) {
		writefln("%*sScreen: %s", indent * 2, " ", screen.Name);
		writefln("%*s* OnTop: ", indent * 2, " ");
		print(screen.OnTop, indent + 1);
		writefln("%*s* Workspaces: ", indent * 2, " ");
		foreach (workspace; screen.Workspaces)
			print(workspace, indent + 1);
	}

	void print(Workspace workspace, int indent) {
		writefln("%*s* Name: %s", indent * 2, " ", workspace.Name);
		writefln("%*s* Layout: ", indent * 2, " ");
		print(workspace.Root, indent + 1);
	}

	void print(Container con, int indent) {
		if (auto win = cast(Window)con)
			print(win, indent);
		else if (auto layout = cast(Layout)con)
			print(layout, indent);
	}

	void print(Layout layout, int indent) {
		writefln("%*s* Type: %s", indent * 2, " ", typeid(layout));
		writefln("%*s* Visible: %s", indent * 2, " ", layout.IsVisible);
		foreach (container; layout.Containers)
			print(container, indent + 1);
	}

	void print(Window window, int indent) {
		writefln("%*sWindow: %s Visible: %s", indent * 2, " ", window.Title, window.IsVisible);
	}

	void printHierarchy() {
		writeln("===Printing Hierarchy===");
		foreach (screen; engine.Screens)
			print(screen, 0);
	}

}
