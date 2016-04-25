module dwin.backend.xcb.window;

import dwin.container.window;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.backend.xcb.engine;
import dwin.data.changed;

import xcb.xcb;

final class XCBWindow : Window {
public:
	this(XCBEngine engine, xcb_window_t window) {
		super("UNK", Geometry(), null, BorderStyle(), 1);
		this.engine = engine;
		this.window = window;
	}

	override void Update() {
		if (!Dirty)
			return;
		scope (exit)
			super.Update();

		if (geom.changed) {
			uint[] data = [geom.x, geom.y, geom.width, geom.height];
			xcb_configure_window(engine.Connection, window,
													 XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
		}
		if (visible.changed) {
			if (visible)
				xcb_map_window(engine.Connection, window);
			else {
				xcb_unmap_window(engine.Connection, window);
				
			}
		}

		if (needFocus.clear) {
			uint[] data = [XCB_STACK_MODE_TOP];
			xcb_configure_window(engine.Connnection, window, XCB_CONFIG_WINDOW_STACK_MODE, data.ptr);
		}
	}

	override void Focus() {
		needFocus = true;
	}
	
	@property xcb_window_t InternalWindow() {
		return window;
	}

private:
	XCBEngine engine;
	xcb_window_t window;
	Changed!bool needFocus;
}
