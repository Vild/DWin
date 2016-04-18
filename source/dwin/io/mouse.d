module dwin.io.mouse;

abstract class MouseStyle {
	abstract void Apply();
}

enum MouseStyles {
	Normal,
	Resizing,
	Moving
}

abstract class Mouse {
public:
	abstract void Update();
	abstract void Move(short x, short y);

	/// This will _NOT_ update the real position of the mouse
	void Set(short x, short y) {
		this.x = x;
		this.y = y;
	}

	@property short X(short x) {
		this.x = x;
		Move(x, y);
		return this.x;
	}

	@property short X() {
		return this.x;
	}

	@property short Y(short y) {
		this.y = y;
		Move(x, y);
		return this.y;
	}

	@property short Y() {
		return this.y;
	}

	@property bool[5] Buttons() {
		return buttons;
	}

	@property void Style(MouseStyles style) {
		styles[style].Apply();
	}

	override string toString() {
		import std.format : format;

		return format("Mouse[X: %s, Y: %s, Buttons: '%(%s, %)']", x, y, buttons);
	}

protected:
	short x;
	short y;
	bool[5] buttons;

	MouseStyle[MouseStyles.max + 1] styles;
}
