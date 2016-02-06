module dwin.backend.layout;

import dwin.backend.engine;
import dwin.backend.container;
import dwin.backend.mouse;

enum LayoutType {
	Float,
	Tile,
	Tab
}

abstract class Layout : Container {
public:
	this(Engine engine) {
		this.engine = engine;
		visible = false;
	}

	override void Add(Container container) {
		containers ~= container;
		container.Parent = this;
	}

	override void Remove(Container container) {
		import std.algorithm.searching : countUntil;

		const long idx = containers.countUntil(container);
		if (idx == -1)
			return;
		for (ulong i = idx; i < containers.length - 1; i++) // container.length - 1 can't be underflow because the assert makes sure it's atleast 1
			containers[i] = containers[i + 1];
		containers.length--;
	}

	abstract void MouseMovePressed(Container target, Mouse mouse);
	abstract void MouseResizeReleased(Container target, Mouse mouse);
	abstract void MouseMoveReleased(Container target, Mouse mouse);
	abstract void MouseResizePressed(Container target, Mouse mouse);
	abstract void MouseMotion(Container target, Mouse mouse);
	abstract void RequestShow(Container container);
	abstract void NotifyHide(Container container);

	override void Update() {
	}

	override void Show(bool eventBased = true) {
		visible = true;
		foreach (container; Containers)
			container.Show(eventBased);
	}

	override void Hide(bool eventBased = true) {
		visible = false;
		foreach (container; Containers)
			container.Hide(eventBased);
	}

	override void Move(short x, short y) {
		this.x = x;
		this.y = y;
	}

	override void Resize(ushort width, ushort height) {
		this.width = width;
		this.height = height;
	}

	override void MoveResize(short x, short y, ushort width, ushort height) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	override void Focus() {
	}

	@property Container[] Containers() {
		return containers;
	}

	@property override bool IsVisible() {
		return visible;
	}

protected:
	Engine engine;
	bool visible;
	Container[] containers;
}
