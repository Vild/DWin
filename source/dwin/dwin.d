module dwin.dwin;

import std.stdio;

import dwin.log;
import dwin.event;
import dwin.backend.xcb.xcb;

import dwin.backend.window;
import dwin.backend.screen;
import dwin.backend.layout;
import dwin.backend.workspace;
import dwin.backend.container;

import std.container.array;

final class DWin {
public:
	this(int display) {
		log = Log.MainLogger();
		xcb = new XCB(display);

		setup();
		sigchld(0); // Ignore when children dies
	}

	void Run() {
		quit = false;
		while (!quit)
			xcb.DoEvent();
	}

private:
	bool quit;
	Log log;
	XCB xcb;
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
		log.Info("New Window: %s", window);

		xcb.Screens[0].Add(window);
	}

	void onRemoveWindow(Window window) {
		log.Info("Remove Window: %s", window);

		window.Parent.Remove(window);
	}

	void onRequestShowWindow(Window window) {
		log.Info("Show: %s", window);
		window.Show();
	}

	void onRequestHideWindow(Window window) {
		log.Info("Hide: %s", window);
		window.Hide();
	}

	void onRequestMoveWindow(Window window, short x, short y) {
		window.Move(x, y);
	}

	void onRequestResizeWindow(Window window, ushort width, ushort height) {
		Screen scr = xcb.Screens[0];
		width = (width < scr.Width) ? width : scr.Width;
		height = (height < scr.Height) ? height : scr.Height;
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
		auto m = xcb.Mouse;
		m.Set(x, y);
		if (timestamp == lastMove)
			return;
		lastMove = timestamp;
		if (window)
			if (Layout parent = window.Parent)
				parent.MouseMotion(window, m);
	}

	void setup() {
		xcb.OnNewWindow ~= &onNewWindow;
		xcb.OnRemoveWindow ~= &onRemoveWindow;
		xcb.OnRequestShowWindow ~= &onRequestShowWindow;
		xcb.OnRequestHideWindow ~= &onRequestHideWindow;
		xcb.OnRequestMoveWindow ~= &onRequestMoveWindow;
		xcb.OnRequestResizeWindow ~= &onRequestResizeWindow;
		xcb.OnRequestBorderSizeWindow ~= &onRequestBorderSizeWindow;
		xcb.OnRequestSiblingWindow ~= &onRequestSiblingWindow;
		xcb.OnRequestStackModeWindow ~= &onRequestStackModeWindow;

		xcb.OnMouseMotion ~= &onMouseMotion;

		import std.process : environment, spawnProcess;

		auto childEnv = environment.toAA;
		childEnv["DISPLAY"] = ":8";
		xcb.BindMgr.Map("Escape", delegate(bool v) { quit = true; });
		xcb.BindMgr.Map("Ctrl + Enter", delegate(bool v) {
			if (v)
				spawnProcess("xterm", childEnv);
		});
		xcb.BindMgr.Map("Ctrl + Backspace", delegate(bool v) {
			if (v)
				spawnProcess("xeyes", childEnv);
		});

		xcb.BindMgr.Map("Ctrl + F5", delegate(bool v) {
			if (v)
				printHierarchy();
		});

		xcb.BindMgr.Map("Ctrl + Button1", delegate(bool v) {
			auto m = xcb.Mouse;
			if (v) {
				window = xcb.FindWindow(m.X, m.Y);
				if (window)
					if (Layout parent = window.Parent)
						parent.MouseMovePressed(window, m);
			} else {
				if (window)
					if (Layout parent = window.Parent)
						parent.MouseMoveReleased(window, m);
				window = null;
			}
		});

		xcb.BindMgr.Map("Ctrl + Button3", delegate(bool v) {
			auto m = xcb.Mouse;
			if (v) {
				window = xcb.FindWindow(m.X, m.Y);
				if (window)
					if (Layout parent = window.Parent)
						parent.MouseResizePressed(window, m);
			} else {
				if (window)
					if (Layout parent = window.Parent)
						parent.MouseResizeReleased(window, m);
				window = null;
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
		foreach (container; layout.Containers)
			print(container, indent + 1);
	}

	void print(Window window, int indent) {
		writefln("%*sWindow: %s", indent * 2, " ", window.Title);
	}

	void printHierarchy() {
		writeln("===Printing Hierarchy===");
		foreach (screen; xcb.Screens)
			print(screen, 0);
	}

}
