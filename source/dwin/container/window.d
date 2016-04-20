module dwin.container.window;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;

abstract class Window : Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio) {
		super(name, geom, parent, borderStyle, splitRatio);
	}

	abstract void Show() {
		visible = true;
	}

	abstract void Hide() {
		visible = false;
	}

	@property bool Visible() {
		return visible;
	}

private:
	//string class_;
	//string instance;
	bool visible;
	bool urgent;
}
