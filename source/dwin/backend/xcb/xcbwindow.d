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

	@property override string Title() {
		Update();
		return title;
	}

	@property override bool IsVisible() {
		return visible;
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
		} else if (xcb_icccm_get_wm_name_reply(xcb.Connection, xcb_icccm_get_wm_name(xcb.Connection, window), &icccm_txt_prop, null)) {
			title = icccm_txt_prop.name.fromStringz.idup;
			xcb_icccm_get_text_property_reply_wipe(&icccm_txt_prop);
		} else
			title = "ERROR TITLE";

		xcb_get_property_reply_t* reply = xcb_get_property_reply(xcb.Connection, xcb_get_property(xcb.Connection, 0,
				window, xcb.LookupNETAtoms[xcb.NETAtoms.WMStrutPartial.id].atom, XCB_ATOM_CARDINAL, 0, 12), null);

		if (reply) {
			onlyStrutPartial = true;
			scope (exit)
				xcb_free(reply);
			uint* data = cast(uint*)xcb_get_property_value(reply);
			strut = .Strut(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]);
		} else if (!onlyStrutPartial) {
			reply = xcb_get_property_reply(xcb.Connection, xcb_get_property(xcb.Connection, 0, window,
					xcb.LookupNETAtoms[xcb.NETAtoms.WMStrut.id].atom, XCB_ATOM_CARDINAL, 0, 4), null);
			if (reply) {
				scope (exit)
					xcb_free(reply);
				uint* data = cast(uint*)xcb_get_property_value(reply);
				strut = .Strut(data[0], data[1], data[2], data[3]);
			}
		}

		reply = xcb_get_property_reply(xcb.Connection, xcb_get_property(xcb.Connection, 0, window,
				xcb.EWMH._NET_WM_DESKTOP, XCB_ATOM_CARDINAL, 0, 1), null);
		if (reply) {
			scope (exit)
				xcb_free(reply);

			uint* data = cast(uint*)xcb_get_property_value(reply);
			desktop = *data;
		}

		reply = xcb_get_property_reply(xcb.Connection, xcb_get_property(xcb.Connection, 0, window,
				xcb.EWMH._NET_WM_WINDOW_TYPE, XCB_ATOM_ATOM, 0, uint.max), null);
		if (reply) {
			scope (exit)
				xcb_free(reply);

			int length = xcb_get_property_value_length(reply);
			uint* data = cast(uint*)xcb_get_property_value(reply);
			windowTypes.length = 0;
			foreach (type; data[0 .. length])
				windowTypes ~= type;
		}

		reply = xcb_get_property_reply(xcb.Connection, xcb_get_property(xcb.Connection, 0, window,
				xcb.EWMH._NET_WM_STATE, XCB_ATOM_ATOM, 0, uint.max), null);
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

	override void Move(short x, short y) {
		if (IsSticky)
			return;
		this.x = x;
		this.y = y;
		uint[] data = [x, y];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, data.ptr);
	}

	override void Resize(ushort width, ushort height) {
		if (IsSticky)
			return;
		this.width = width;
		this.height = height;
		uint[] data = [width, height];
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
	}

	override void MoveResize(short x, short y, ushort width, ushort height) {
		if (IsSticky)
			return;
		uint[] data = [x, y, width, height];
		xcb_configure_window(xcb.Connection, window,
				XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, data.ptr);
	}

	override void Focus() {
		uint value = XCB_STACK_MODE_ABOVE;
		xcb_configure_window(xcb.Connection, window, XCB_CONFIG_WINDOW_STACK_MODE, &value);
	}

	override void Close() {
		xcb_icccm_get_wm_protocols_reply_t reply;
		auto Protocols = xcb.LookupWMAtoms[XCB.WMAtoms.Protocols.id];
		auto DeleteWindow = xcb.LookupWMAtoms[XCB.WMAtoms.DeleteWindow.id];

		if (!xcb_icccm_get_wm_protocols_reply(xcb.Connection, xcb_icccm_get_wm_protocols(xcb.Connection, window,
				Protocols), &reply, null))
			xcb_kill_client(xcb.Connection, window);

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
				xcb_send_event(xcb.Connection, 0, window, XCB_EVENT_MASK_NO_EVENT, cast(char*)&e);
				return;
			}
	}

	override void Show(bool eventBased = true) {
		if (eventBased)
			visible = true;

		if (visible && parent.IsVisible)
			Map();
	}

	override void Hide(bool eventBased = true) {
		static bool lastWasEvent = true;

		if (lastWasEvent && eventBased)
			visible = false;

		lastWasEvent = eventBased;

		Unmap();
	}

	void Map() {
		uint values_off = xcb.RootEventMask & ~XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY;
		uint values_on = xcb.RootEventMask;
		xcb_change_window_attributes(xcb.Connection, xcb.Root.InternalWindow, XCB_CW_EVENT_MASK, &values_off);
		xcb_map_window(xcb.Connection, window);
		xcb_change_window_attributes(xcb.Connection, xcb.Root.InternalWindow, XCB_CW_EVENT_MASK, &values_on);
	}

	void Unmap() {
		uint values_off = xcb.RootEventMask & ~XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY;
		uint values_on = xcb.RootEventMask;
		xcb_change_window_attributes(xcb.Connection, xcb.Root.InternalWindow, XCB_CW_EVENT_MASK, &values_off);
		xcb_unmap_window(xcb.Connection, window);
		xcb_change_window_attributes(xcb.Connection, xcb.Root.InternalWindow, XCB_CW_EVENT_MASK, &values_on);
	}

	void ChangeAttributes(uint mask, const uint* value) {
		xcb_change_window_attributes(xcb.Connection, window, mask, value);
	}

	@property xcb_window_t InternalWindow() {
		return window;
	}

	@property xcb_atom_t[] WindowTypes() {
		return windowTypes;
	}

	@property xcb_atom_t[] States() {
		return states;
	}

	@property override bool IsDock() {
		import std.algorithm.searching : canFind;

		return windowTypes.canFind(xcb.EWMH._NET_WM_WINDOW_TYPE_DOCK);
	}

	@property override bool IsSticky() {
		import std.algorithm.searching : canFind;

		return states.canFind(xcb.EWMH._NET_WM_STATE_STICKY);
	}

private:
	XCB xcb;
	xcb_window_t window;
	string title;
	bool visible;
	bool onlyStrutPartial;
	xcb_atom_t[] windowTypes;
	xcb_atom_t[] states;
}
