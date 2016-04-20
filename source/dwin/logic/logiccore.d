module dwin.logic.logiccore;

import dwin.backend.engine;
import dwin.container.window;
import dwin.data.vec;

abstract class LogicCore {
public:
	this(Engine engine) {
		this.engine = engine;
	}

	abstract void NewWindow(Window window);
	abstract void RemoveWindow(Window window);

	abstract void ShowWindow(Window window);
	abstract void WindowHidden(Window window);

	/+void MoveWindow(Window window, Vec2 position);
	void ResizeWindow(Window window, Vec2 size);
	void MouseMovedMotion(Vec2 position);+/
protected:
	Engine engine;
}
