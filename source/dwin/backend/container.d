module dwin.backend.container;

import dwin.backend.layout;
import dwin.backend.window;

class Container {
public:
	this(LayoutType type, Window window) {
		this.type = type;
		isLayout = false;
		window = window;
	}

	this(LayoutType type, Layout layout) {
		this.type = type;
		isLayout = true;
		layout = layout;
	}

	void Add(Container container) {
		import dwin.layout.floatinglayout : FloatingLayout;

		if (!isLayout) {
			Window window = this.window;

			if (type == LayoutType.Float)
				layout = new FloatingLayout();
			else
				assert(0); //TODO: Add all the other layouts

			layout.Add(new Container(type, window));
			layout.Add(container);

			isLayout = true;
		} else
			layout.Add(container);
	}

	void Remove(Container container) {
		assert(isLayout);
		layout.Remove(container);
		if (layout.Containers.length == 1 && layout.ShouldCollapseOnOne) {
			Container con = layout.Containers[0];
			layout.destroy;
			if (con.isLayout)
				this.layout = con.TheLayout;
			else
				this.window = con.TheWindow;
			isLayout = false;
		}
	}

	void Move(short x, short y) {
		if (isLayout)
			layout.Move(x, y);
		else
			window.Move(x, y);
	}

	void Resize(ushort width, ushort height) {
		if (isLayout)
			layout.Resize(width, height);
		else
			window.Resize(width, height);
	}

	@property bool IsLayout() {
		return isLayout;
	}

	@property ref Window TheWindow() {
		assert(!isLayout);
		return window;
	}

	@property ref Layout TheLayout() {
		assert(isLayout);
		return layout;
	}

private:
	union {
		Window window;
		Layout layout;
	}

	bool isLayout;
	LayoutType type;
}
