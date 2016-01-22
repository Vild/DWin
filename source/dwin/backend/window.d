module dwin.backend.window;

import dwin.backend.layout;
import dwin.backend.container;
import dwin.log;

abstract class Window : Container {
public:
	override void Add(Container container) {
		Log.MainLogger.Error("Trying to add a container to a window, redirecting it to the parent!");
		parent.Add(container);
	}

	override void Remove(Container container) {
		Log.MainLogger.Error("Trying to remove a container from a window, redirecting it to the parent!");
		parent.Remove(container);
	}

	//abstract void Update();
	//abstract void Move(short x, short y);
	//abstract void Resize(ushort width, ushort height);
	//abstract void MoveResize(short x, short y, ushort width, ushort height);
	abstract void Show();
	abstract void Hide();
	//abstract void Focus();
	abstract void Close();

	@property abstract string Title();
}
