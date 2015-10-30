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
		xcb_intern_atom_cookie_t c = xcb_intern_atom_unchecked(xcb.Connection, !createOnMissing, cast(ushort)name.length, name.toStringz);
		if (auto reply = xcb_intern_atom_reply(xcb.Connection, c, null)) {
			atom = reply.atom;
			free(reply);
		}
	}

	this(xcb_atom_t atom) {
		this.atom = atom;
	}

	Atom[] GetPropertyAtom(XCB xcb, Window window) {
		Atom[] ret;
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(xcb.Connection, 0, window.Window, atom, XCB_ATOM_ATOM, 0, 0);
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			xcb_atom_t[] tmp = (cast(xcb_atom_t *)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			foreach (atom; tmp)
				ret ~= Atom(atom);
			free(reply);
		}
		return ret;
	}

	Window[] GetPropertyWindow(XCB xcb, Window window) {
		Window[] ret;
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(xcb.Connection, 0, window.Window, atom, XCB_ATOM_WINDOW, 0, 0);
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			xcb_window_t[] tmp = (cast(xcb_window_t *)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			foreach (win; tmp)
				ret ~= new Window(xcb, win);
			free(reply);
		}
		return ret;
	}

	string GetPropertyString(XCB xcb, Window window) {
		string ret = null;
		xcb_get_property_cookie_t c = xcb_get_property_unchecked(xcb.Connection, 0, window.Window, atom, XCB_ATOM_STRING, 0, 0);
		if (auto reply = xcb_get_property_reply(xcb.Connection, c, null)) {
			char[] tmp = (cast(char *)xcb_get_property_value(reply))[0 .. xcb_get_property_value_length(reply)];
			ret = tmp.to!string;
			free(reply);
		}
		return ret;
	}

	void ChangeProperty(XCB xcb, Window window, Atom atom) {
		xcb_change_property(xcb.Connection, XCB_PROP_MODE_REPLACE, window.Window, atom, XCB_ATOM_ATOM, 32, 1, cast(ubyte *)&atom);
	}

	void ChangeProperty(XCB xcb, Window window, Window value) {
		xcb_change_property(xcb.Connection, XCB_PROP_MODE_REPLACE, window.Window, atom, XCB_ATOM_WINDOW, 32, 1, cast(ubyte *)&value);
	}

	void ChangeProperty(XCB xcb, Window window, string str) {
		xcb_change_property(xcb.Connection, XCB_PROP_MODE_REPLACE, window.Window, atom, XCB_ATOM_STRING, 8, cast(uint)str.length, str.toStringz);
	}

	@property bool IsValid() { return atom != XCB_ATOM_NONE; }


	alias atom this;
	xcb_atom_t atom;
}
