module dwin.container.screen;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.splitcontainer;

abstract class Screen : Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio) {
		super(name, geom, parent, borderStyle, splitRatio);
	}

	@property SplitContainer Top() {
		return top;
	}

	@property SplitContainer Bottom() {
		return bottom;
	}

	@property SplitContainer Left() {
		return left;
	}

	@property SplitContainer Right() {
		return right;
	}

private:
	SplitContainer top;
	SplitContainer bottom;
	SplitContainer left;
	SplitContainer right;
}
