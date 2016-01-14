module dwin.backend.screen;

import dwin.backend.container;
import dwin.backend.window;
import dwin.backend.workspace;

import dwin.layout.floatinglayout;

class Screen {
public:
	this(string name, short x, short y, ushort width, ushort height, Workspace[] workspaces = [new Workspace("Default")]) {
		this.name = name;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		onTop = new FloatingLayout();
		this.workspaces = workspaces;
	}

	void Add(Container container) {
		workspaces[currentWorkspace].Add(container);
	}

	void Remove(Container container) {
		workspaces[currentWorkspace].Remove(container);
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

	@property short X() {
		return x;
	}

	@property short Y() {
		return y;
	}

	@property ushort Width() {
		return width;
	}

	@property ushort Height() {
		return height;
	}

	@property ulong CurrentWorkspace() {
		return currentWorkspace;
	}

	@property ref Workspace[] Workspaces() {
		return workspaces;
	}

	@property FloatingLayout OnTop() {
		return onTop;
	}

protected:
	string name;
	short x;
	short y;
	ushort width;
	ushort height;

	ulong currentWorkspace;

	Workspace[] workspaces;
	FloatingLayout onTop;
}
