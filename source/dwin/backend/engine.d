module dwin.backend.engine;

import dwin.event;

import dwin.backend.container;
import dwin.backend.layout;
import dwin.backend.mouse;
import dwin.backend.screen;
import dwin.backend.window;
import dwin.backend.workspace;

import dwin.backend.bindmanager;

abstract class Engine {
public:
	abstract void DoEvent();

	Window FindWindow(short x, short y) {
		import dwin.backend.layout : Layout;
		import dwin.backend.container : Container;
		import dwin.backend.workspace : Workspace;

		Window traverseWin(Window window, short x, short y) {
			window.Update();
			if (x >= window.X && x <= window.X + window.Width && y >= window.Y && y <= window.Y + window.Height)
				return window;
			else
				return null;
		}

		Window traverseCon(Container con, short x, short y) {
			if (!con.IsVisible)
				return null;
			if (auto window = cast(Window)con) {
				if (auto win = traverseWin(window, x, y))
					return win;
			} else if (auto layout = cast(Layout)con)
				foreach (container; layout.Containers)
					if (auto win = traverseCon(container, x, y))
						return win;
			return null;
		}

		Window traverseWorkspace(Workspace workspace, short x, short y) {
			if (auto win = traverseCon(workspace.OnTop, x, y))
				return win;
			if (auto win = traverseCon(workspace.Root, x, y))
				return win;
			return null;
		}

		Window traverseLayout(Layout layout, short x, short y) {
			if (!layout.IsVisible)
				return null;
			foreach (container; layout.Containers)
				if (auto win = traverseCon(container, x, y))
					return win;
			return null;
		}

		Window traverseScreen(Screen screen, short x, short y) {
			if (auto win = traverseLayout(screen.OnTop, x, y))
				return win;
			foreach (workspace; screen.Workspaces)
				if (auto win = traverseWorkspace(workspace, x, y))
					return win;
			return null;
		}

		foreach (screen; screens)
			if (auto win = traverseScreen(screen, x, y))
				return win;
		return null;
	}

	Screen FindScreen(short x, short y) {
		foreach (screen; screens)
			if (screen.X <= x && screen.X + screen.Width >= x && screen.Y <= y && screen.Y + screen.Height >= y)
				return screen;
		return screens[0];
	}

	@property.Mouse Mouse() {
		return mouse;
	}

	@property.BindManager BindManager() {
		return bindManager;
	}

	@property Window Root() {
		return root;
	}

	@property Screen[] Screens() {
		return screens;
	}

	@property ref auto OnNewWindow() {
		return onNewWindow;
	}

	@property ref auto OnRemoveWindow() {
		return onRemoveWindow;
	}

	@property ref auto OnRequestShowWindow() {
		return onRequestShowWindow;
	}

	@property ref auto OnNotifyHideWindow() {
		return onNotifyHideWindow;
	}

	@property ref auto OnRequestMoveWindow() {
		return onRequestMoveWindow;
	}

	@property ref auto OnRequestResizeWindow() {
		return onRequestResizeWindow;
	}

	@property ref auto OnRequestBorderSizeWindow() {
		return onRequestBorderSizeWindow;
	}

	@property ref auto OnRequestSiblingWindow() {
		return onRequestSiblingWindow;
	}

	@property ref auto OnRequestStackModeWindow() {
		return onRequestStackModeWindow;
	}

	@property ref auto OnMouseMotion() {
		return onMouseMotion;
	}

protected:
	.Mouse mouse;
	.BindManager bindManager;

	Window root;
	Screen[] screens;
	Window[] windows;

	Event!(Window) onNewWindow;
	Event!(Window) onRemoveWindow;
	Event!(Window) onRequestShowWindow;
	Event!(Window) onNotifyHideWindow;
	Event!(Window, short, short) onRequestMoveWindow;
	Event!(Window, ushort, ushort) onRequestResizeWindow;
	Event!(Window, ushort) onRequestBorderSizeWindow;
	Event!(Window, Window) onRequestSiblingWindow;
	Event!(Window, ubyte) onRequestStackModeWindow;
	Event!(short, short, uint) onMouseMotion;
}
