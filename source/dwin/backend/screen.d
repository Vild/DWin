module dwin.backend.screen;

import dwin.backend.container;
import dwin.backend.window;
import dwin.backend.workspace;

import dwin.layout.floatinglayout;

class Screen {
public:
	this(string name, short x, short y, ushort width, ushort height, Workspace[] workspaces = [new Workspace("Workspace1"),
			new Workspace("Workspace2"), new Workspace("Workspace3")]) {
		this.name = name;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		onTop = new FloatingLayout();
		onTop.MoveResize(x, y, width, height);
		this.workspaces = workspaces;
		foreach (workspace; this.workspaces)
			workspace.MoveResize(x, y, width, height);

		workspaces[this.currentWorkspace].Show();
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

	@property long CurrentWorkspace() {
		return currentWorkspace;
	}

	@property long CurrentWorkspace(long currentWorkspace) {
		long mod(long a, long b) {
			import std.math : abs;

			return (a >= 0) ? a % b : (b - abs(a % b)) % b;
		}

		currentWorkspace = mod(currentWorkspace, workspaces.length);

		workspaces[this.currentWorkspace].Hide(false);
		this.currentWorkspace = currentWorkspace;

		workspaces[this.currentWorkspace].Show(false);
		return this.currentWorkspace;
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

	long currentWorkspace;

	Workspace[] workspaces;
	FloatingLayout onTop;
}
