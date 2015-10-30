module dwin.backend.xcb.window;

import xcb.xcb;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.drawable;

class Window {
public:
	this(XCB xcb, ushort width, ushort height, string title) {
		this.xcb = xcb;
		this.width = width;
		this.height = height;
		this.title = title;

		window = xcb_generate_id(xcb.Connection);

		xcb_create_window(xcb.Connection, XCB_COPY_FROM_PARENT, window, xcb.Screen.root, 0, 0, width, height, 10, XCB_WINDOW_CLASS_INPUT_OUTPUT, xcb.Screen.root_visual, 0, null);
		gc = xcb_generate_id(xcb.Connection);
		xcb_create_gc(xcb.Connection, gc, window, 0, null);

		drawable = new .Drawable(xcb, window, width, height);
	}

	this(XCB xcb, xcb_window_t window) {
		this.xcb = xcb;
		this.window = window;
		this.width = 0;
		this.height = 0;
		this.title = null;
		this.gc = 0;
		drawable = null;
	}

	~this() {
		Unmap();
		xcb_free_gc(xcb.Connection, gc);
		xcb_destroy_window(xcb.Connection, window);
	}

	void Map() {
		xcb_map_window(xcb.Connection, window);
	}

	void Unmap() {
		xcb_unmap_window(xcb.Connection, window);
	}

	void Render() {
		xcb_copy_area(xcb.Connection, drawable.Drawable, window, gc, 0, 0, 0, 0, width, height);
	}

	@property .Drawable Drawable() { return drawable; }
	@property xcb_window_t Window() { return window; }

private:
	XCB xcb;
	ushort width;
	ushort height;
	string title;

	xcb_window_t window;
	xcb_gcontext_t gc;

	.Drawable drawable;
}
