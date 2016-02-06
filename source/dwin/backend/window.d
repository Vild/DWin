module dwin.backend.window;

import dwin.backend.layout;
import dwin.backend.container;
import dwin.backend.workspace;
import dwin.log;

struct Strut {
	uint left;
	uint right;
	uint top;
	uint bottom;

	uint left_start_y;
	uint left_end_y;
	uint right_start_y;
	uint right_end_y;
	uint top_start_x;
	uint top_end_x;
	uint bottom_start_x;
	uint bottom_end_x;
}

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
	//abstract void Show(bool eventBased = true);
	//abstract void Hide(bool eventBased = true);
	//abstract void Focus();
	abstract void Close();

	@property abstract string Title();
	//@property abstract bool IsVisible();

	override string toString() {
		import std.format : format;

		return format("%s %s: %s", cast(void*)this, typeid(this).name, Title);
	}

	@property.Strut Strut() {
		return strut;
	}

	@property uint Desktop() {
		return desktop;
	}

	@property ref.Workspace Workspace() {
		return workspace;
	}

	@property abstract bool IsDock();
	@property abstract bool IsSticky();

protected:
	.Strut strut;
	uint desktop;
	.Workspace workspace;
}
