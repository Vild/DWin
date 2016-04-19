module dwin.backend.xcb.window;

import dwin.container.window;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.backend.xcb.engine;

import xcb.xcb;

final class XCBWindow : Window {
public:
	this(XCBEngine engine, xcb_window_t window) {
		super("UNK", Geometry(), null, BorderStyle(), 1);
		this.engine = engine;
		this.window = window;
	}

	override void Update() {
		if (!DirtyGeometry)
			return;
		scope (exit)
			super.Update();

		//TODO: Send new cords to X11
	}

	override void Show() {
		super.Show();
		xcb_map_window(engine.Connection, window);
	}

	override void Hide() {
		super.Hide();
		xcb_unmap_window(engine.Connection, window);
	}
	
	@property xcb_window_t InternalWindow() {
		return window;
	}
	
private:
	XCBEngine engine;
	xcb_window_t window;
}
