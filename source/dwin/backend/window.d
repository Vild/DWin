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

	abstract void Update();
	//abstract void Move(short x, short y);
	//abstract void Resize(ushort width, ushort height);
	abstract void Show();
	abstract void Hide();

	@property abstract string Title();

	@property ref bool Dead() {
		return dead;
	}

	@property short X() {
		return x;
	}

	@property short X(short x) {
		this.x = x;
		Move(x, y);
		return this.x;
	}

	@property short Y() {
		return y;
	}

	@property short Y(short y) {
		this.y = y;
		Move(x, y);
		return this.y;
	}

	@property ushort Width() {
		return width;
	}

	@property ushort Width(ushort width) {
		this.width = width;
		Resize(width, height);
		return this.width;
	}

	@property ushort Height() {
		return height;
	}

	@property ushort Height(ushort height) {
		this.height = height;
		Resize(width, height);
		return this.height;
	}

protected:
	bool dead;
	short x;
	short y;
	ushort width;
	ushort height;
}
