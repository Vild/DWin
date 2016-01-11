module dwin.dwin;

import dwin.log;
import dwin.event;
import dwin.backend.xcb.xcb;

import dwin.backend.window;
import dwin.backend.screen;

import std.container.array;

final class DWin {
public:
	this() {
		log = Log.MainLogger();
		xcb = new XCB();

		setup();
		sigchld(0); // Ignore when children dies
	}

	void Run() {
		foreach (screen; xcb.Screens)
			log.Info("Screen: %s", screen.Name);

		while (true) {
			xcb.DoEvent();
		}
	}

private:
	Log log;
	XCB xcb;

	extern (C) static void sigchld(int) nothrow @nogc {
		import core.sys.posix.signal : signal, SIGCHLD, SIG_ERR;
		import core.sys.posix.sys.wait : waitpid, WNOHANG;

		signal(SIGCHLD, &sigchld);
		while (0 < waitpid(-1, null, WNOHANG)) {
		}
	}

	void onNewWindow(Window window) {
		log.Info("New Window: %s", window);
	}

	void onRemoveWindow(Window window) {
		log.Info("Remove Window: %s", window);
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
	}

}
