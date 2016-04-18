module dwin.backend.xcb.root;

import xcb.xcb;

import dwin.container.root;
import dwin.backend.xcb.engine;
import dwin.data.geometry;

final class XCBRoot : Root {
public:
	this(XCBEngine engine, xcb_window_t window) {
		this.engine = engine;
		this.window = window;

		xcb_get_geometry_reply_t* geom = xcb_get_geometry_reply(engine.Connection, xcb_get_geometry(engine.Connection, window),
			null);
		Geometry g;
		if (geom) {
			g.x = geom.x;
			g.y = geom.y;
			g.width = geom.width;
			g.height = geom.height;
			xcb_free(geom);
		}
		super(g);
	}

	@property override void Update() {
		super.Update();
	}

	@property xcb_window_t InternalWindow() {
		return window;
	}

private:
	XCBEngine engine;
	xcb_window_t window;
}
