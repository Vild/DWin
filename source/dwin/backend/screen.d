module dwin.backend.screen;

import dwin.backend.engine;
import dwin.backend.container;
import dwin.backend.window;
import dwin.backend.workspace;

import dwin.layout.floatinglayout;

class Screen {
public:
	this(Engine engine, string name, short x, short y, ushort width, ushort height, Workspace[] workspaces = null) {
		this.engine = engine;
		this.name = name;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		onTop = new FloatingLayout(engine);
		onTop.MoveResize(x, y, width, height);
		onTop.Show();
		if (!workspaces)
			workspaces = [new Workspace(engine, "Workspace1"), new Workspace(engine, "Workspace2"), new Workspace(engine, "Workspace3")];
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

	void MoveResize(short x, short y, ushort width, ushort height) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		foreach (workspace; workspaces)
			workspace.MoveResize(x, y, width, height);
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

		workspaces[currentWorkspace].Show(false);
		workspaces[this.currentWorkspace].Hide(false);
		this.currentWorkspace = currentWorkspace;

		return this.currentWorkspace;
	}

	@property ref Workspace[] Workspaces() {
		return workspaces;
	}

	@property FloatingLayout OnTop() {
		return onTop;
	}

	override string toString() {
		import std.format : format;

		return format("Screen[Name: %s, X: %s, Y: %s, Width: %s, Height: %s]", name, x, y, width, height);
	}

protected:
	Engine engine;
	string name;
	short x;
	short y;
	ushort width;
	ushort height;

	long currentWorkspace;

	Workspace[] workspaces;
	FloatingLayout onTop;
}
