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

	@property ref Screen[] Screens() {
		return screens;
	}

	@property ref Window[] StickyWindows() {
		return stickyWindows;
	}

private:
	Screen[] screens;
	Window[] stickyWindows;
}
