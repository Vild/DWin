module dwin.backend.xcb.window;

import dwin.container.window;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.backend.xcb.engine;
import dwin.data.changed;

import std.string;

import xcb.xcb;
import xcb.ewmh;
import xcb.icccm;

final class XCBWindow : Window {
public:
	this(XCBEngine engine, xcb_window_t window) {
		super("UNK", Geometry(), null, BorderStyle(), 1);
		this.engine = engine;
		this.window = window;

		if (WMDeleteWindow == 0) {
			string s = "WM_DELETE_WINDOW";
			auto reply = xcb_intern_atom_reply(engine.Connection, xcb_intern_atom_unchecked(engine.Connection, false, cast(ushort)s.length, s.toStringz), null);
			if (reply) {
				WMDeleteWindow = reply.atom;
				xcb_free(reply);
			}
		}
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
		xcb_get_geometry_reply_t* geomReply = xcb_get_geometry_reply(engine.Connection, xcb_get_geometry(engine.Connection, window), null);
		if (geomReply) {
			geom = Geometry(geomReply.x, geomReply.y, geomReply.width, geomReply.height);
			xcb_free(geomReply);
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

		xcb_ewmh_get_utf8_strings_reply_t ewmh_txt_prop;
		xcb_icccm_get_text_property_reply_t icccm_txt_prop;

		if ((visible && xcb_ewmh_get_wm_name_reply(engine.EWMHConnection, xcb_ewmh_get_wm_visible_name(engine.EWMHConnection, window), &ewmh_txt_prop, null)) || xcb_ewmh_get_wm_name_reply(engine.EWMHConnection, xcb_ewmh_get_wm_name(engine.EWMHConnection, window), &ewmh_txt_prop, null)) {
			title = ewmh_txt_prop.strings.fromStringz.idup;
			xcb_ewmh_get_utf8_strings_reply_wipe(&ewmh_txt_prop);
		} else if (xcb_icccm_get_wm_name_reply(engine.Connection, xcb_icccm_get_wm_name(engine.Connection, window), &icccm_txt_prop, null)) {
			title = icccm_txt_prop.name.fromStringz.idup;
			xcb_icccm_get_text_property_reply_wipe(&icccm_txt_prop);
		} else
			title = "ERROR TITLE";

		xcb_get_property_reply_t* reply = xcb_get_property_reply(engine.Connection, xcb_get_property(engine.Connection, 0, window, engine.EWMHConnection._NET_WM_STRUT_PARTIAL, XCB_ATOM_CARDINAL, 0, 12), null);

		if (reply) {
			onlyStrutPartial = true;
			scope (exit)
				xcb_free(reply);
			uint* data = cast(uint*)xcb_get_property_value(reply);
			strut = .Strut(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]);
		} else if (!onlyStrutPartial) {
			reply = xcb_get_property_reply(engine.Connection, xcb_get_property(engine.Connection, 0, window, engine.EWMHConnection._NET_WM_STRUT, XCB_ATOM_CARDINAL, 0, 4), null);
			if (reply) {
				scope (exit)
					xcb_free(reply);
				uint* data = cast(uint*)xcb_get_property_value(reply);
				strut = .Strut(data[0], data[1], data[2], data[3]);
			}
		}

		reply = xcb_get_property_reply(engine.Connection, xcb_get_property(engine.Connection, 0, window, engine.EWMHConnection._NET_WM_DESKTOP, XCB_ATOM_CARDINAL, 0, 1), null);
		if (reply) {
			scope (exit)
				xcb_free(reply);

			uint* data = cast(uint*)xcb_get_property_value(reply);
			desktop = *data;
		}

		reply = xcb_get_property_reply(engine.Connection, xcb_get_property(engine.Connection, 0, window, engine.EWMHConnection._NET_WM_WINDOW_TYPE, XCB_ATOM_ATOM, 0, uint.max), null);
		if (reply) {
			scope (exit)
				xcb_free(reply);

			int length = xcb_get_property_value_length(reply);
			uint* data = cast(uint*)xcb_get_property_value(reply);
			windowTypes.length = 0;
			foreach (type; data[0 .. length])
				windowTypes ~= type;
		}

		reply = xcb_get_property_reply(engine.Connection, xcb_get_property(engine.Connection, 0, window, engine.EWMHConnection._NET_WM_STATE, XCB_ATOM_ATOM, 0, uint.max), null);
		if (reply) {
			scope (exit)
				xcb_free(reply);

			int length = xcb_get_property_value_length(reply);
			uint* data = cast(uint*)xcb_get_property_value(reply);
			states.length = 0;
			foreach (s; data[0 .. length])
				states ~= s;
		}
	}

	override void Close() {
		xcb_icccm_get_wm_protocols_reply_t reply;
		auto Protocols = engine.EWMHConnection.WM_PROTOCOLS;
		auto DeleteWindow = WMDeleteWindow;

		if (!xcb_icccm_get_wm_protocols_reply(engine.Connection, xcb_icccm_get_wm_protocols(engine.Connection, window, Protocols), &reply, null))
			xcb_kill_client(engine.Connection, window);

		scope (exit)
			xcb_icccm_get_wm_protocols_reply_wipe(&reply);

		foreach (atom; reply.atoms[0 .. reply.atoms_len])
			if (atom == DeleteWindow) {
				xcb_client_message_event_t e;
				e.response_type = XCB_CLIENT_MESSAGE;
				e.window = window;
				e.format = 32;
				e.sequence = 0;
				e.type = Protocols;
				e.data.data32[0] = DeleteWindow;
				e.data.data32[1] = XCB_CURRENT_TIME;
				xcb_send_event(engine.Connection, 0, window, XCB_EVENT_MASK_NO_EVENT, cast(char*)&e);
				return;
			}
	}
	
	@property override bool isDock() {
		import std.algorithm.searching : canFind;
		return windowTypes.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_DOCK);
	}

	@property override bool IsSticky() {
		import std.algorithm.searching : canFind;

		return states.canFind(engine.EWMHConnection._NET_WM_STATE_STICKY) ||
			states.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_TOOLBAR) ||
			states.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_MENU) ||
			states.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_SPLASH) ||
			states.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_TOOLTIP) ||
			states.canFind(engine.EWMHConnection._NET_WM_WINDOW_TYPE_NOTIFICATION)
			;
	}
	
	@property xcb_window_t InternalWindow() {
		return window;
	}

private:
	static xcb_atom_t WMDeleteWindow = 0;
	
	XCBEngine engine;
	xcb_window_t window;
	
	bool onlyStrutPartial;
	xcb_atom_t[] windowTypes;
	xcb_atom_t[] states;
}
