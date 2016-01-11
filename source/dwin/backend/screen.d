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
		onTopContainers = new FloatingLayout();
		this.workspaces = workspaces;
	}

	void AddOnTop(Container container) {
		onTopContainers.Add(container);
	}

	void RemoveOnTop(Container container) {
		onTopContainers.Remove(container);
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

	@property FloatingLayout OnTopContainers() {
		return onTopContainers;
	}

protected:
	string name;
	short x;
	short y;
	ushort width;
	ushort height;

	ulong currentWorkspace;

	Workspace[] workspaces;
	FloatingLayout onTopContainers;
}
