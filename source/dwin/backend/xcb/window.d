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

		if (geom.changed) {
			geom.clear;
			uint[] data = [geom.x, geom.y, geom.width, geom.height];
			xcb_configure_window(engine.Connection, window,
				XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
		}
		if (visible.clear) {
			uint eventOff = engine.RootEventMask & ~XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY;
			uint eventOn = engine.RootEventMask;
			xcb_change_window_attributes(engine.Connection, engine.RawRoot, XCB_CW_EVENT_MASK, &eventOff);

			if (visible)
				xcb_map_window(engine.Connection, window);
			else
				xcb_unmap_window(engine.Connection, window);

			xcb_change_window_attributes(engine.Connection, engine.RawRoot, XCB_CW_EVENT_MASK, &eventOn);
		}

		if (needFocus.clear) {
			uint[] data = [XCB_STACK_MODE_TOP_IF];
			xcb_configure_window(engine.Connection, window, XCB_CONFIG_WINDOW_STACK_MODE, data.ptr);
		}
	}

	@property xcb_window_t InternalWindow() {
		return window;
	}

private:
	XCBEngine engine;
	xcb_window_t window;
}
