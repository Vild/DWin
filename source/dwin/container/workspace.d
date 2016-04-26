module dwin.container.workspace;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.splitcontainer;
import dwin.container.window;
import dwin.data.changed;

final class Workspace : Container {
public:
	this(string name, Geometry geom, Container parent) {
		super(name, geom, parent, BorderStyle(), 1);
		root = new SplitContainer("Root", geom, this, BorderStyle(), 1, Layout.Horizontal);
	}

	override void Update() {
		if (!Dirty)
			return;
		
		if (fullscreen)  {
			focused.Geom = geom.data;
			focused.Focus();
			fullscreen.clear;
		} else {
			// focused and fullscreen will already exist in the "root" container
			root.Update();
			foreach (Window w; floating)
				w.Update();
		}
		fullscreen.clear;
	}

	@property ref Container Focused() {
		return focused;
	}

	@property ref bool Fullscreen() {
		return fullscreen.data;
	}

	@property ref SplitContainer Root() {
		return root;
	}

	@property ref Window[] Floating() {
		return floating;
	}

	@property override bool Dirty() {
		if (super.Dirty || root.Dirty)
			return true;

		foreach (Window w; floating)
			if (w.Dirty)
				return true;
		
		return false;
	}
	
private:
	Container focused;
	Changed!bool fullscreen;
	SplitContainer root;
	Window[] floating;
}
