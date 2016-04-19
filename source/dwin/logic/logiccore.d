module dwin.logic.logiccore;

import dwin.container.window;
import dwin.data.vec;

interface ILogicCore {
	void NewWindow(Window window);
	void RemoveWindow(Window window);
	
	void ShowWindow(Window window);
	void WindowHidden(Window window);

	/+void MoveWindow(Window window, Vec2 position);
	void ResizeWindow(Window window, Vec2 size);
	void MouseMovedMotion(Vec2 position);+/
}
