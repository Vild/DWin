module dwin.container.splitcontainer;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;

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
		bool needsUpdate = true;
		foreach (Container c; containers)
			needsUpdate |= c.DirtyGeometry;

		rebalance();
		
		foreach (Container c; containers)
			c.Update();
	}

	@property Container[] Containers() {
		return containers;
	}

	@property Layout SplitLayout() {
		return layout;
	}
	
private:
	Container[] containers;
	Layout layout;

	void rebalance() {
	}
}
