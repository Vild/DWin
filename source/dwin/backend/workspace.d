module dwin.backend.workspace;

import dwin.backend.container;
import dwin.backend.layout;
import dwin.layout.floatinglayout;
import dwin.layout.tilinglayout;

class Workspace {
public:
	this(string name) {
		this.name = name;
		onTop = new FloatingLayout();
		root = new TilingLayout();
	}

	void Add(Container container) {
		root.Add(container);
	}

	void Remove(Container container) {
		root.Remove(container);
	}

	void AddOnTop(Container container) {
		onTop.Add(container);
	}

	void RemoveOnTop(Container container) {
		onTop.Remove(container);
	}

	@property ref string Name() {
		return name;
	}

	@property Layout Root() {
		return root;
	}

	@property FloatingLayout OnTop() {
		return onTop;
	}

	void Move(short x, short y) {
		onTop.Move(x, y);
		root.Move(x, y);
	}

	void Resize(ushort width, ushort height) {
		onTop.Resize(width, height);
		root.Resize(width, height);
	}

	void MoveResize(short x, short y, ushort width, ushort height) {
		onTop.MoveResize(x, y, width, height);
		root.MoveResize(x, y, width, height);
	}

protected:
	string name;
	Layout root;
	FloatingLayout onTop;
}
