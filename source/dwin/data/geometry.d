module dwin.data.geometry;

import dwin.data.vec;

struct Geometry {
	int x;
	int y;

	int width;
	int height;

	@property Vec2 Position() {
		return Vec2(x, y);
	}

	@property Vec2 Position(Vec2 pos) {
		x = pos.x;
		y = pos.y;

		return pos;
	}

	@property Vec2 Size() {
		return Vec2(width, height);
	}

	@property Vec2 Size(Vec2 size) {
		width = size.x;
		height = size.y;
		return size;
	}
}
