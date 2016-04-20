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
		scr.Containers ~= window;
		//		scr.Rebalance();
		window.Show();
		window.Resize(scr.Geom.Size);
		window.Move(Vec2(0, 0));
	}

	override void WindowHidden(Window window) {
		auto scr = engine.RootContainer.Screens[0];
		window.Hide();

		size_t idx = 0;
		for(; idx < scr.Containers.length; idx++)
			if (scr.Containers[idx] == window)
				break;
		for(; idx < scr.Containers.length - 1; idx++)
			scr.Containers[idx] = scr.Containers[idx + 1];
		scr.Containers.length--;
	}
}
