module dwin.backend.xcb.xcbwindow;

import xcb.xcb;
import xcb.ewmh;
import xcb.icccm;

import dwin.backend.window;
import dwin.backend.xcb.xcb;
import dwin.log;

class XCBWindow : Window {
public:
	this(XCB xcb, xcb_window_t window) {
		this.xcb = xcb;
		this.window = window;
		this.visible = false;
		this.dead = false;

		Update();
	}

	~this() {
		Unmap();
		xcb_destroy_window(xcb.Connection, window);
	}

	@property override string Title() {
		Update();
		return title;
	}

	override void Update() {
		import std.string : fromStringz;

		if (dead)
			return;

		xcb_get_geometry_reply_t* geom = xcb_get_geometry_reply(xcb.Connection, xcb_get_geometry(xcb.Connection, window), null);
		if (geom) {
			x = geom.x;
			y = geom.y;
			width = geom.width;
			height = geom.height;
			xcb_free(geom);
		}

		xcb_ewmh_get_utf8_strings_reply_t ewmh_txt_prop;
		xcb_icccm_get_text_property_reply_t icccm_txt_prop;

		if ((visible && xcb_ewmh_get_wm_name_reply(xcb.EWMH, xcb_ewmh_get_wm_visible_name(xcb.EWMH, window),
				&ewmh_txt_prop, null)) || xcb_ewmh_get_wm_name_reply(xcb.EWMH, xcb_ewmh_get_wm_name(xcb.EWMH, window),
				&ewmh_txt_prop, null)) {
			title = ewmh_txt_prop.strings.fromStringz.idup;
			xcb_ewmh_get_utf8_strings_reply_wipe(&ewmh_txt_prop);
		} else if (xcb_icccm_get_wm_name_reply(xcb.Connection, xcb_icccm_get_wm_name(xcb.Connection, window), &icccm_txt_prop,
				null)) {
			title = icccm_txt_prop.name.fromStringz.idup;
			xcb_icccm_get_text_property_reply_wipe(&icccm_txt_prop);
		} else
			title = "ERROR TITLE";
	}

	override void Move(short x, short y) {
		this.x = x;
		this.y = y;
		uint[] data = [x, y];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, data.ptr);
	}

	override void Resize(ushort width, ushort height) {
		this.width = width;
		this.height = height;
		uint[] data = [width, height];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
	}

	override void MoveResize(short x, short y, ushort width, ushort height) {
		uint[] data = [x, y, width, height];
		xcb_configure_window(xcb.Connection, window,
				XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
	}

	override void Focus() {
		uint value = XCB_STACK_MODE_ABOVE;
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_STACK_MODE, &value);
	}

	override void Show() {
		visible = true;
		Map();
	}

	override void Hide() {
		visible = false;
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
	string title;
	bool visible;
}
