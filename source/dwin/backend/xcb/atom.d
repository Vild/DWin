module dwin.backend.xcb.atom;

import xcb.xcb;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.window;
import std.string : toStringz;
import std.conv : to;
import std.c.stdlib : free;

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
			free(reply);
		}
	}

	this(xcb_atom_t atom) {
		this.atom = atom;
	}

	Atom[] GetAtom(Window window) {
		Atom[] ret;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.Window,
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
			free(reply);
		}
		return ret;
	}

	Window[] GetWindow(Window window) {
		Window[] ret;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.Window,
			atom,
			XCB_ATOM_WINDOW,
			0,
			0
		);
		//dfmt on
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			xcb_window_t[] tmp = (cast(xcb_window_t*)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			foreach (win; tmp)
				ret ~= new Window(xcb, win);
			free(reply);
		}
		return ret;
	}

	string GetString(Window window) {
		string ret = null;
		//dfmt off
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(
			xcb.Connection,
			0,
			window.Window,
			atom,
			XCB_ATOM_STRING,
			0,
			0
		);
		//dfmt on
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			char[] tmp = (cast(char*)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			ret = tmp.to!string;
			free(reply);
		}
		return ret;
	}

	void Change(Window window, Atom[] value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.Window,
			atom,
			XCB_ATOM_ATOM,
			32,
			cast(uint)value.length,
			cast(ubyte*)value.ptr
		);
		//dfmt on
	}

	void Change(Window window, Atom value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.Window,
			atom,
			XCB_ATOM_ATOM,
			32,
			1,
			cast(ubyte*)&value
		);
		//dfmt on
	}

	void Change(Window window, Window value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.Window,
			atom,
			XCB_ATOM_WINDOW,
			32,
			1,
			cast(ubyte*)&value
		);
		//dfmt on
	}

	void Change(Window window, string value) {
		//dfmt off
		xcb_change_property(
			xcb.Connection,
			XCB_PROP_MODE_REPLACE,
			window.Window,
			atom,
			XCB_ATOM_STRING,
			8,
			cast(uint)value.length,
			value.toStringz
		);
		//dfmt on
	}

	void Delete(Window window) {
		xcb_delete_property(xcb.Connection, window.Window, atom);
	}

	@property bool IsValid() {
		return atom != XCB_ATOM_NONE;
	}

	alias atom this;
	xcb_atom_t atom;
	XCB xcb;
}
