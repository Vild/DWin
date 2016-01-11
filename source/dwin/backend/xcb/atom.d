module dwin.backend.xcb.atom;

import xcb.xcb;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.xcbwindow;
import std.string : toStringz;
import std.conv : to;

struct Atom {
	this(XCB xcb, string name, bool createOnMissing = true) {
		atom = XCB_ATOM_NONE;
		this.xcb = xcb;
		//dfmt off
		xcb_intern_atom_cookie_t c = xcb_intern_atom_unchecked(
			xcb.Connection,
			!createOnMissing,
			cast(ushort)name.length,
			name.toStringz
		);
		//dfmt on
		if (auto reply = xcb_intern_atom_reply(xcb.Connection, c, null)) {
			atom = reply.atom;
			xcb_free(reply);
		}
	}

	this(xcb_atom_t atom) {
		this.atom = atom;
	}

	Atom[] GetAtom(XCBWindow window) {
		Atom[] ret;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.InternalWindow,
			atom,
			XCB_ATOM_ATOM,
			0,
			0
		);
		//dfmt on
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			xcb_atom_t[] tmp = (cast(xcb_atom_t*)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			foreach (atom; tmp)
				ret ~= Atom(atom);
			xcb_free(reply);
		}
		return ret;
	}

	XCBWindow[] GetWindow(XCBWindow window) {
		XCBWindow[] ret;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.InternalWindow,
			atom,
			XCB_ATOM_WINDOW,
			0,
			0
		);
		//dfmt on
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			xcb_window_t[] tmp = (cast(xcb_window_t*)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			foreach (win; tmp)
				ret ~= new XCBWindow(xcb, win);
			xcb_free(reply);
		}
		return ret;
	}

	string GetString(XCBWindow window) {
		string ret = null;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.InternalWindow,
			atom,
			XCB_ATOM_STRING,
			0,
			0
		);
		//dfmt on
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			char[] tmp = (cast(char*)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			ret = tmp.to!string;
			xcb_free(reply);
		}
		return ret;
	}

	void Change(XCBWindow window, Atom[] value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.InternalWindow,
			atom,
			XCB_ATOM_ATOM,
			32,
			cast(uint)value.length,
			cast(ubyte*)value.ptr
		);
		//dfmt on
	}

	void Change(XCBWindow window, Atom value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.InternalWindow,
			atom,
			XCB_ATOM_ATOM,
			32,
			1,
			cast(ubyte*)&value
		);
		//dfmt on
	}

	void Change(XCBWindow window, XCBWindow value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.InternalWindow,
			atom,
			XCB_ATOM_WINDOW,
			32,
			1,
			cast(ubyte*)&value
		);
		//dfmt on
	}

	void Change(XCBWindow window, string value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.InternalWindow,
			atom,
			XCB_ATOM_STRING,
			8,
			cast(uint)value.length,
			value.toStringz
		);
		//dfmt on
	}

	void Delete(XCBWindow window) {
		xcb_delete_property(xcb.Connection, window.InternalWindow, atom);
	}

	@property bool IsValid() {
		return atom != XCB_ATOM_NONE;
	}

	bool opEquals(xcb_atom_t other) {
		return atom == other;
	}

	alias atom this;
	xcb_atom_t atom;
	XCB xcb;
}
