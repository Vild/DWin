module dwin.container.screen;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.splitcontainer;
import dwin.container.workspace;

final class Screen : Container {
public:
	this(string name, Geometry geom, Container parent) {
		super(name, geom, parent, BorderStyle(), 1);
		top = new SplitContainer("Top", Geometry(), this, BorderStyle(), 1, Layout.Horizontal);
		bottom = new SplitContainer("Bottom", Geometry(), this, BorderStyle(), 1, Layout.Horizontal);
		left = new SplitContainer("Left", Geometry(), this, BorderStyle(), 1, Layout.Vertical);
		right = new SplitContainer("Right", Geometry(), this, BorderStyle(), 1, Layout.Vertical);
		workspaces ~= new Workspace("0", geom, this);
	}

	override void Update() {
		if (!Dirty)
			return;
		top.Update();
		bottom.Update();
		left.Update();
		right.Update();
		foreach (w; workspaces)
			w.Update();
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

	@property ref Workspace[] Workspaces() {
		return workspaces;
	}

	@property override bool Dirty() {
		if (super.Dirty || top.Dirty || bottom.Dirty || left.Dirty || right.Dirty)
			return true;

		foreach (Workspace w; workspaces)
			if (w.Dirty)
				return true;

		return false;
	}

private:
	SplitContainer top;
	SplitContainer bottom;
	SplitContainer left;
	SplitContainer right;
	Workspace[] workspaces;
}
