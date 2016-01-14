module dwin.backend.layout;

import std.container.array;
import std.algorithm.searching;
import dwin.backend.container;

enum LayoutType {
	Float,
	Tile,
	Tab
}

abstract class Layout : Container {
public:
	override void Add(Container container) {
		containers.insertBack(container);
		container.Parent = this;
	}

	override void Remove(Container container) {
		auto idx = containers[].countUntil(container);
		assert(idx >= 0);
		containers.linearRemove(containers[idx .. idx + 1]);
	}

	override void Move(short x, short y) {
		this.x = x;
		this.y = y;
	}

	override void Resize(ushort width, ushort height) {
		this.width = width;
		this.height = height;
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

	@property Array!Container Containers() {
		return containers;
	}

protected:
	short x;
	short y;
	ushort width;
	ushort height;
	Array!Container containers;
}
