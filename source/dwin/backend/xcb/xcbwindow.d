module dwin.backend.xcb.xcbwindow;

import xcb.xcb;
import dwin.backend.window;
import dwin.backend.xcb.xcb;

class XCBWindow : Window {
public:
	this(XCB xcb, xcb_window_t window) {
		this.xcb = xcb;
		this.window = window;
	}

	~this() {
		Unmap();
		xcb_destroy_window(xcb.Connection, window);
	}

	@property override string Title() {
		return "DummyTitle";
	}

	override void Update() {
		xcb_get_geometry_reply_t* geom = xcb_get_geometry_reply(xcb.Connection, xcb_get_geometry(xcb.Connection, window), null);
		x = geom.x;
		y = geom.y;
		width = geom.width;
		height = geom.height;
		xcb_free(geom);
	}

	override void Move(short x, short y) {
		uint[] data = [x, y];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, data.ptr);
	}

	override void Resize(ushort width, ushort height) {
		uint[] data = [width, height];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
	}

	override void Show() {
		Map();
	}

	override void Hide() {
		Unmap();
	}

	void Map() {
		xcb_map_window(xcb.Connection, window);
	}

	void Unmap() {
		xcb_unmap_window(xcb.Connection, window);
	}

	void ChangeAttributes(uint mask, const uint* value) {
		xcb_change_window_attributes(xcb.Connection, window, mask, value);
	}

	@property xcb_window_t InternalWindow() {
		return window;
	}

private:
	XCB xcb;
	xcb_window_t window;
}
