module dwin.backend.workspace;

import dwin.backend.engine;
import dwin.backend.container;
import dwin.backend.window;
import dwin.backend.layout;
import dwin.layout.floatinglayout;
import dwin.layout.tilinglayout;

class Workspace {
public:
	this(Engine engine, string name) {
		this.engine = engine;
		this.name = name;
		onTop = new FloatingLayout(engine);
		root = new TilingLayout(engine);
	}

	void Add(Container container) {
		if (auto window = cast(Window)container) {
			window.Workspace = this;
			activeWindow = window;
		}

		root.Add(container);

		if (auto layout = cast(TilingLayout)root)
			layout.ShouldDie();
	}

	void Remove(Container container) {
		root.Remove(container);
		if (auto window = cast(Window)container) {
			window.Workspace = null;
			if (activeWindow == window)
				activeWindow = null;
		}
		if (auto layout = cast(TilingLayout)root)
			layout.ShouldDie();
	}

	void AddOnTop(Container container) {
		onTop.Add(container);
	}

	void RemoveOnTop(Container container) {
		onTop.Remove(container);
	}

	void Show(bool eventBased = true) {
		onTop.Show(eventBased);
		root.Show(eventBased);
	}

	void Hide(bool eventBased = true) {
		onTop.Hide(eventBased);
		root.Hide(eventBased);
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

	@property ref string Name() {
		return name;
	}

	@property Layout Root() {
		return root;
	}

	@property FloatingLayout OnTop() {
		return onTop;
	}

	@property ref Window ActiveWindow() {
		return activeWindow;
	}

protected:
	Engine engine;
	string name;
	Layout root;
	FloatingLayout onTop;
	Window activeWindow;
}
