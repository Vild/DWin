module dwin.backend.container;

import dwin.backend.layout;
import dwin.backend.window;
import dwin.backend.screen;

enum PositionPart {
	First,
	Second,
	Third
}

struct GridPosition {
	PositionPart x;
	PositionPart y;
}

abstract class Container {
public:
	abstract void Add(Container container);
	abstract void Remove(Container container);
	abstract void Move(short x, short y) {
	}

	abstract void Resize(ushort width, ushort height);
	abstract void MoveResize(short x, short y, ushort width, ushort height) {
		Move(x, y);
	}

	abstract void Show(bool eventBased = true);
	abstract void Hide(bool eventBased = true);

	abstract void Update();
	abstract void Focus();

	GridPosition GetGridPosition(int x, int y) {
		const int pointX = x / (width / 4) + 1;
		const int pointY = y / (height / 4) + 1;

		GridPosition pos;

		/*
			---------------
			|1,1| 2,1 |3,1|
			|---|-----|---|
			|1,2| 2,2 |3,2|
			|---|-----|---|
			|1,3| 2,3 |3,3|
			---------------
		*/

		if (!!(pointX & 0b100))
			pos.x = PositionPart.Third;
		else if (!!(pointX & 0b10))
			pos.x = PositionPart.Second;
		else if (!!(pointX & 0b1))
			pos.x = PositionPart.First;

		if (!!(pointY & 0b100))
			pos.y = PositionPart.Third;
		else if (!!(pointY & 0b10))
			pos.y = PositionPart.Second;
		else if (!!(pointY & 0b1))
			pos.y = PositionPart.First;

		return pos;
	}

	@property ref.Screen Screen() {
		return screen;
	}

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
		Move(x, y);
		return this.x;
	}

	@property short Y() {
		return y;
	}

	@property short Y(short y) {
		Move(x, y);
		return this.y;
	}

	@property ushort Width() {
		return width;
	}

	@property ushort Width(ushort width) {
		Resize(width, height);
		return this.width;
	}

	@property ushort Height() {
		return height;
	}

	@property ushort Height(ushort height) {
		Resize(width, height);
		return this.height;
	}

	@property abstract bool IsVisible();

protected:
	.Screen screen;
	Layout parent;
	bool dead;
	short x;
	short y;
	ushort width;
	ushort height;
}
