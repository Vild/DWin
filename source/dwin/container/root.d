module dwin.container.root;

import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.container;
import dwin.container.window;
import dwin.container.screen;

abstract class Root : Container {
	this(Geometry size) {
		super("Root", size, null, BorderStyle(), 1.0);
	}

	override void Update() {
		if (!Dirty)
			return;

		foreach (Screen s; screens)
			s.Update();

		foreach (Window w; stickyWindows)
			w.Update();
	}

	@property ref Screen[] Screens() {
		return screens;
	}

	@property ref Window[] StickyWindows() {
		return stickyWindows;
	}

	@property override bool Dirty() {
		if (super.Dirty)
			return true;

		foreach (Screen s; screens)
			if (s.Dirty)
				return true;

		foreach (Window w; stickyWindows)
			if (w.Dirty)
				return true;

		return false;
	}

protected:
	Screen[] screens;
	Window[] stickyWindows;
}
