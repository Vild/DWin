module dwin.backend.container;

import dwin.backend.layout;
import dwin.backend.window;

abstract class Container {
public:
	abstract void Add(Container container);
	abstract void Remove(Container container);
	abstract void Move(short x, short y);
	abstract void Resize(ushort width, ushort height);

	abstract void Update();
	abstract void Focus();

	@property ref Layout Parent() {
		return parent;
	}

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
	Layout parent;
	bool dead;
	short x;
	short y;
	ushort width;
	ushort height;
}
