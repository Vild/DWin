module dwin.backend.xcb.font;

import xcb.xcb;
import dwin.backend.xcb.xcb;

final class Font {
public:
	this(XCB xcb, string name) {
		import std.string : toStringz;
		this.xcb = xcb;

		xcb_font_t font = xcb_generate_id(xcb.Connection);
		xcb_open_font(xcb.Connection, font, cast(ubyte)name.length, name.toStringz);

		gc = xcb_generate_id(xcb.Connection);
		uint mask = XCB_GC_FOREGROUND | XCB_GC_BACKGROUND | XCB_GC_FONT;
		uint[] properties = [
			xcb.Screen.black_pixel,
			xcb.Screen.white_pixel,
			font
		];
		xcb_create_gc(xcb.Connection, gc, xcb.Root.Window, mask, properties.ptr);

		xcb_close_font(xcb.Connection, font);
	}

	~this() {
		xcb_free_gc(xcb.Connection, gc);
	}

	@property xcb_gcontext_t GC() { return gc; }

private:
	XCB xcb;
	xcb_gcontext_t gc;
}
