module dwin.backend.workspace;

import dwin.backend.container;
import dwin.layout.floatinglayout;

class Workspace {
public:
	this(string name) {
		this.name = name;
		onTopContainers = new FloatingLayout();
	}

	void Add(Container container) {
		if (rootContainer)
			rootContainer.Add(container);
		else
			rootContainer = container;
	}

	void Remove(Container container) {
		assert(rootContainer);

		if (rootContainer == container)
			rootContainer = null;
		else
			rootContainer.Remove(container);
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

	@property Container RootContainer() {
		return rootContainer;
	}

	@property FloatingLayout OnTopContainers() {
		return onTopContainers;
	}

protected:
	string name;
	Container rootContainer;
	FloatingLayout onTopContainers;
}
