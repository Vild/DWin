module dwin.backend.workspace;

import dwin.backend.container;
import dwin.backend.layout;
import dwin.layout.floatinglayout;

class Workspace {
public:
	this(string name) {
		this.name = name;
		onTop = new FloatingLayout();
		root = new FloatingLayout();
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

protected:
	string name;
	Layout root;
	FloatingLayout onTop;
}
