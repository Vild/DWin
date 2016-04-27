module dwin.container.splitcontainer;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.data.changed;

enum Layout {
	Horizontal,
	Vertical,
	Tabbed,
	Stacked
}

final class SplitContainer : Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio, Layout layout) {
		super(name, geom, parent, borderStyle, splitRatio);
		this.layout = layout;
	}

	override void Update() {
		if (!Dirty)
			return;

		rebalance();

		foreach (Container c; containers)
			c.Update();
	}

	@property ref Container[] Containers() {
		return containers;
	}

	@property ref Layout SplitLayout() {
		return layout.data;
	}

	@property override bool Dirty() {
		if (super.Dirty || layout.changed)
			return true;

		foreach (Container c; containers)
			if (c.Dirty)
				return true;

		return false;
	}

private:
	Container[] containers;
	Changed!Layout layout;

	void rebalance() {

		//assert(0, "TODO: implement rebalance");
	}
}
