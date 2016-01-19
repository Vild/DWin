module dwin.backend.layout;

import std.container.array;
import std.algorithm.searching;
import dwin.backend.container;
import dwin.backend.mouse;

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

	abstract void MouseMovePressed(Container target, Mouse mouse);
	abstract void MouseResizeReleased(Container target, Mouse mouse);
	abstract void MouseMoveReleased(Container target, Mouse mouse);
	abstract void MouseResizePressed(Container target, Mouse mouse);
	abstract void MouseMotion(Container target, Mouse mouse);

	override void Update() {
	}

	override void Move(short x, short y) {
		this.x = x;
		this.y = y;
	}

	override void Resize(ushort width, ushort height) {
		this.width = width;
		this.height = height;
	}

	override void Focus() {
	}

	@property Array!Container Containers() {
		return containers;
	}

protected:
	Array!Container containers;
}
