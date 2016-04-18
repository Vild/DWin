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

	@property Vec2 Size() {
		return Vec2(width, height);
	}
}
