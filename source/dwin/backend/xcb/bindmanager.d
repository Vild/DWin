module dwin.backend.bindmanager;

import xcb.xcb;
import xcb.xproto;

import dwin.backend.xcb.xcb;
import dwin.backend.xcb.key;

final class BindManager {
public:
	this(XCB xcb) {
		this.xcb = xcb;
	}

	~this() {
		foreach (map, func; mapping)
			Unmap(map);
	}

	void Map(string key, mapFunc func) {
		mapping[key] = func;
	}

	void Unmap(string key) {
		mapping.remove(key);
	}

	void HandleKeyEvent(xcb_key_press_event_t * e) {

	}


	auto GrabKey(ubyte owner_events, ushort modifiers, xcb_keycode_t key, ubyte pointerMode, ubyte keyboardMode) {
		//dfmt off
		return xcb_grab_key(
			xcb.Connection,
			owner_events,
			xcb.Root.InternalWindow,
			modifiers,
			key,
			pointerMode,
			keyboardMode
		);
		//dfmt on
	}

	auto UngrabKey(ubyte owner_events, xcb_keycode_t key, ushort modifiers) {
		//dfmt off
		return xcb_ungrab_key(
			xcb.Connection,
			key,
			xcb.Root.InternalWindow,
			modifiers
		);
		//dfmt on
	}

	auto GrabButton(ubyte owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode, xcb_cursor_t cursor,
		ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_grab_button(
			xcb.Connection,
			owner_events,
			xcb.Root.InternalWindow,
			event_mask,
			pointerMode,
			keyboardMode,
			xcb.Root.InternalWindow,
			cursor,
			button,
			modifiers
		);
		//dfmt on
	}

	auto UngrabButton(ubyte owner_events, ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_ungrab_button(
			xcb.Connection,
			button,
			xcb.Root.InternalWindow,
			modifiers
		);
		//dfmt on
	}

	auto GrabPointer(ubyte owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode, xcb_cursor_t cursor, xcb_timestamp_t time) {
		//dfmt off
		return xcb_grab_pointer(
			xcb.Connection,
			owner_events,
			xcb.Root.InternalWindow,
			event_mask,
			pointerMode,
			keyboardMode,
			xcb.Root.InternalWindow,
			cursor,
			time
		);
		//dfmt on
	}

	auto UngrabPointer(xcb_timestamp_t time) {
		return xcb_ungrab_pointer(xcb.Connection, time);
	}
private:
	alias mapFunc = bool delegate(string key);
	XCB xcb;
	mapFunc[string] mapping;
}

struct KeyBind {
	Key key;
	Modifier modifier;
}
