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

abstract class SplitContainer : Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio, Layout layout) {
		super(name, geom, parent, borderStyle, splitRatio);
		this.layout = layout;
	}

private:
	Container[] containers;
	Layout layout;
}
