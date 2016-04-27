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

		layout.clear;
		oldLength = containers.length;

		geom.clear;
		needFocus.clear;
	}

	@property ref Container[] Containers() {
		return containers;
	}

	@property ref Layout SplitLayout() {
		return layout.data;
	}

	@property override bool Dirty() {
		if (super.Dirty || layout.changed || containers.length != oldLength)
			return true;

		foreach (Container c; containers)
			if (c.Dirty)
				return true;

		return false;
	}

private:
	Container[] containers;
	size_t oldLength;
	Changed!Layout layout;

	import std.stdio;
	
	void rebalance() {
		if (layout >= Layout.Tabbed) {
			writeln(__FUNCTION__, ":", __LINE__, " --> ", layout);
			Geometry g = geom.data;

			//TODO: Remove size of status bar thingy
			with(containers[0]) {
				Geom = g;
				Focus();
			}
		} else {
			fixSplitRatio();

			if (layout != Layout.Vertical) {
				int xpos = geom.x;
				writeln(__FUNCTION__, ":", __LINE__, " --> ", layout);
				foreach (idx, Container c; containers) {
					Geometry g = geom.data;
					g.x = xpos;
					g.width = cast(int)(c.SplitRatio * g.width);
					xpos += g.width;
					writeln(idx, ": " , c.Geom, " to ", g);
					c.Geom = g;
				}
			} else {
				int ypos = geom.y;
				writeln(__FUNCTION__, ":", __LINE__, " --> ", layout);
				foreach (idx, Container c; containers) {
					Geometry g = geom.data;
					g.y = ypos;
					g.height = cast(int)(c.SplitRatio * g.height);
					ypos += g.height;
					writeln(idx, ": " , c.Geom, " to ", g);
					c.Geom = g;
				}
			}
		}
	}

	void fixSplitRatio() {
		// Algorithm https://github.com/i3/i3/blob/80dddd9961263be8ac3b46a15a9cc9302525071d/src/con.c#L756
    double total = 0;
    int calced;

		foreach (Container c; containers)
			if (c.SplitRatio > 0) {
				total += c.SplitRatio;
				calced++;
			}
    if (calced != containers.length)
			foreach (Container c; containers)
				if (c.SplitRatio <= 0.0) {
					if (calced == 0)
						total += (c.SplitRatio = 1.0);
					else
						total += (c.SplitRatio = total / calced);
				}

    if (total == 0.0) //TODO: When can this be 0?
			foreach (Container c; containers)
        c.SplitRatio = 1.0 / containers.length;
		else if (total != 1.0)
			foreach (Container c; containers)
        c.SplitRatio /= total;
	}
}
