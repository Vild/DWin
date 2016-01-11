module dwin.backend.window;

import dwin.backend.layout;

abstract class Window {
public:
	abstract void Update();
	abstract void Move(short x, short y);
	abstract void Resize(ushort width, ushort height);
	abstract void Show();
	abstract void Hide();

	@property abstract string Title();

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

	@property ref Layout ParentLayout() {
		return parentLayout;
	}

protected:
	short x;
	short y;
	ushort width;
	ushort height;
	Layout parentLayout;
}
