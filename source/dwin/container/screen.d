module dwin.container.screen;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.splitcontainer;

final class Screen : Container {
public:
	this(string name, Geometry geom, Container parent) {
		super(name, geom, parent, BorderStyle(), 1);
		top = new SplitContainer("Top", Geometry(), this, BorderStyle(), 1, Layout.Horizontal);
		bottom = new SplitContainer("Bottom", Geometry(), this, BorderStyle(), 1, Layout.Horizontal);
		left = new SplitContainer("Left", Geometry(), this, BorderStyle(), 1, Layout.Vertical);
		right = new SplitContainer("Right", Geometry(), this, BorderStyle(), 1, Layout.Vertical);
	}

	override void Update() {
		top.Update();
		bottom.Update();
		left.Update();
		right.Update();
		foreach (Container c; containers)
			c.Update();
	}

	void Rebalance() {
		//TODO: 
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

	@property ref Container[] Containers() {
		return containers;
	}

private:
	SplitContainer top;
	SplitContainer bottom;
	SplitContainer left;
	SplitContainer right;
	Container[] containers;
}
