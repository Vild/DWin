module dwin.logic.fullscreenlogiccore;

import dwin.logic.logiccore;
import dwin.backend.engine;
import dwin.container.window;
import dwin.data.vec;

final class FullscreenLogicCore : LogicCore {
public:
	this(Engine engine) {
		super(engine);
	}

	override void NewWindow(Window window) {
	}

	override void RemoveWindow(Window window) {
	}

	override void ShowWindow(Window window) {
		auto scr = engine.RootContainer.Screens[0];
		auto wrk = scr.Workspaces[0];
		wrk.Root.Containers ~= window;
		window.Show();
	}

	override void WindowHidden(Window window) {
		auto scr = engine.RootContainer.Screens[0];
		auto wrk = scr.Workspaces[0];

		// Hacky way of getting a ref variable
		(ref con) {
			window.Hide();

			size_t idx = 0;
			for(; idx < con.length; idx++)
				if (con[idx] == window)
					break;

			if (idx == con.length)
				return;
			
			for(; idx < con.length - 1; idx++)
				con[idx] = con[idx + 1];
			con.length--;
		} (wrk.Root.Containers);
	}
}
