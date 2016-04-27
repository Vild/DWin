module dwin.container.window;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.data.changed;

struct Strut {
	uint left;
	uint right;
	uint top;
	uint bottom;

	uint left_start_y;
	uint left_end_y;
	uint right_start_y;
	uint right_end_y;
	uint top_start_x;
	uint top_end_x;
	uint bottom_start_x;
	uint bottom_end_x;
}

abstract class Window : Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio) {
		super(name, geom, parent, borderStyle, splitRatio);
	}

	void Show() {
		visible = true;
	}

	void Hide() {
		visible = false;
	}

	abstract void Close();

	@property string Title() {
		return title;
	}
	
	@property abstract bool isDock();
	@property abstract bool IsSticky();

	@property uint Desktop() {
		return desktop;
	}
	
	@property bool Visible() {
		return visible.data;
	}

	@property override bool Dirty() {
		return super.Dirty || visible.changed;
	}

protected:
	//string class_;
	//string instance;
	Strut strut;	
	uint desktop;
	string title;
	Changed!bool visible;
	bool urgent;
}
