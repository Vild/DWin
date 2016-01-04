module dwin.backend.xcb.drawable;

import xcb.xcb;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.font;

final class Drawable {
public:
	this(XCB xcb, xcb_drawable_t parent, ushort width, ushort height) {
		this.xcb = xcb;
		this.width = width;
		this.height = height;
		drawable = xcb_generate_id(xcb.Connection);
		xcb_create_pixmap(xcb.Connection, xcb.Screen.root_depth, drawable, parent, width, height);
		gc = xcb_generate_id(xcb.Connection);
		xcb_create_gc(xcb.Connection, gc, drawable, 0, null);
	}

	~this() {
		xcb_free_gc(xcb.Connection, gc);
		xcb_free_pixmap(xcb.Connection, drawable);
	}

	void ChangeColor(uint fg, uint bg) {
		uint[] colors = [fg, bg];
		xcb_change_gc(xcb.Connection, gc, XCB_GC_FOREGROUND | XCB_GC_BACKGROUND, colors.ptr);
	}

	void DrawArc(xcb_arc_t[] arcs, bool filled) {
		if (filled)
			xcb_poly_fill_arc(xcb.Connection, drawable, gc, cast(uint)arcs.length, arcs.ptr);
		else
			xcb_poly_arc(xcb.Connection, drawable, gc, cast(uint)arcs.length, arcs.ptr);
	}

	void DrawLine(xcb_point_t[] lines, bool relativeToEarlierCoord) {
		xcb_poly_line(xcb.Connection, relativeToEarlierCoord ? XCB_COORD_MODE_PREVIOUS : XCB_COORD_MODE_ORIGIN, drawable,
			gc, cast(uint)lines.length, lines.ptr);
	}

	void DrawPoint(xcb_point_t[] points, bool relativeToEarlierCoord) {
		xcb_poly_point(xcb.Connection, relativeToEarlierCoord ? XCB_COORD_MODE_PREVIOUS : XCB_COORD_MODE_ORIGIN,
			drawable, gc, cast(uint)points.length, points.ptr);
	}

	void DrawRectangle(xcb_rectangle_t[] rectangle, bool filled) {
		if (filled)
			xcb_poly_fill_rectangle(xcb.Connection, drawable, gc, cast(uint)rectangle.length, rectangle.ptr);
		else
			xcb_poly_rectangle(xcb.Connection, drawable, gc, cast(uint)rectangle.length, rectangle.ptr);
	}

	void DrawSegment(xcb_segment_t[] segments) {
		xcb_poly_segment(xcb.Connection, drawable, gc, cast(uint)segments.length, segments.ptr);
	}

	void DrawDrawable(xcb_drawable_t src, ushort src_x, ushort src_y, ushort x, ushort y, ushort width, ushort height) {
		xcb_copy_area(xcb.Connection, src, drawable, gc, src_x, src_y, x, y, width, height);
	}

	void DrawText(Font font, ushort x, ushort y, string str) {
		import std.string : toStringz;

		xcb_image_text_8(xcb.Connection, cast(ubyte)str.length, drawable, font.GC, x, y, str.toStringz);
	}

	void Resize(ushort width, ushort height) {
		this.width = width;
		this.height = height;

		xcb_free_pixmap(xcb.Connection, drawable);
		xcb_create_pixmap(xcb.Connection, xcb.Screen.root_depth, drawable, xcb.Root.Window, width, height);
	}

	@property xcb_drawable_t Drawable() {
		return drawable;
	}

protected:
	XCB xcb;
	ushort width;
	ushort height;
	xcb_drawable_t drawable;
	xcb_gcontext_t gc;
}
