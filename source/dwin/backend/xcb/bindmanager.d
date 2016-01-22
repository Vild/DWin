module dwin.backend.xcb.bindmanager;

import xcb.xcb;
import xcb.xproto;
import xcb.keysyms;

import dwin.backend.xcb.xcb;
import dwin.backend.xcb.key;

import dwin.log;

final class BindManager {
public:
	alias MapBind = void delegate(bool isPressed);
	struct KeyBind {
		Modifier modifier;
		Key key;
		MouseButton mouseButton;

		@property bool IsValid() {
			return !!key || !!mouseButton;
		}

		string toString() {
			import std.format : format;

			return format("KeyBind(%s, %x, %s)", modifier, key.key, mouseButton);
		}
	}

	this(XCB xcb) {
		this.xcb = xcb;
		Rebind();
	}

	~this() {
		ungrabKey(XCB_GRAB_ANY, Modifier.Any);
		ungrabButton(MouseButton.Any, Modifier.Any);
	}

	void Rebind() {
		Key.Refresh(xcb);
		immutable uint[] modifiers = [0, XCB_MOD_MASK_LOCK, Key.NumlockMask, Key.NumlockMask | XCB_MOD_MASK_LOCK];

		ungrabKey(XCB_GRAB_ANY, Modifier.Any);
		ungrabButton(MouseButton.Any, Modifier.Any);
		foreach (keyBind, func; mappings) {
			if (keyBind.mouseButton == MouseButton.None) {
				xcb_keycode_t* code = xcb_key_symbols_get_keycode(xcb.Symbols, keyBind.key);
				if (!code)
					continue;

				foreach (mod; modifiers)
					grabKey(true, cast(Modifier)(keyBind.modifier | mod), *code, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);

				xcb_free(code);
			} else {
				foreach (mod; modifiers)
					grabButton(true,
							XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE | XCB_EVENT_MASK_BUTTON_MOTION,
							XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, keyBind.mouseButton,
							cast(Modifier)(keyBind.modifier | mod));
			}
		}
		xcb.Flush();
	}

	void Map(string keys, MapBind func) {
		KeyBind keyBind = toKeyBind(keys);
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s): '%s'", keyBind, keys);
			return;
		}

		Map(keyBind, func);
	}

	void Unmap(string keys) {
		KeyBind keyBind = toKeyBind(keys);
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s): '%s'", keyBind, keys);
			return;
		}

		Unmap(keyBind);
	}

	void Map(KeyBind keyBind, MapBind func) {
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s)", keyBind);
			return;
		}

		Log.MainLogger.Debug("Mapping '%s' to func@0x%x", keyBind, func.funcptr);
		mappings[keyBind] = func;
		Rebind();
	}

	void Unmap(KeyBind keyBind) {
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s)", keyBind);
			return;
		}

		mappings.remove(keyBind);
	}

	void HandleKeyPressEvent(xcb_key_press_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(Key.NumlockMask | Key.MouseMasks)), Key(key), MouseButton.None);
		if (auto map = keyBind in mappings)
			(*map)(true);
	}

	void HandleKeyReleaseEvent(xcb_key_release_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(Key.NumlockMask | Key.MouseMasks)), Key(key), MouseButton.None);
		if (auto map = keyBind in mappings)
			(*map)(false);
	}

	void HandleButtonPressEvent(xcb_button_press_event_t* e) {
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(Key.NumlockMask | Key.MouseMasks)), Key.ParseKey("None"),
				cast(MouseButton)e.detail);

		xcb.Mouse.Set(e.root_x, e.root_y);
		if (auto map = keyBind in mappings)
			(*map)(true);
	}

	void HandleButtonReleaseEvent(xcb_button_release_event_t* e) {
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(Key.NumlockMask | Key.MouseMasks)), Key.ParseKey("None"),
				cast(MouseButton)e.detail);

		xcb.Mouse.Set(e.root_x, e.root_y);
		if (auto map = keyBind in mappings)
			(*map)(false);
	}

private:
	XCB xcb;
	MapBind[KeyBind] mappings;

	KeyBind toKeyBind(string keys) {
		import std.array;
		import std.string;
		import std.algorithm;

		auto split = keys.split("+").map!(strip);

		MouseButton mouse = Key.ParseMouseButton(split[$ - 1]);
		Key key = (mouse == MouseButton.None) ? Key.ParseKey(split[$ - 1]) : Key(0);
		Modifier mod = Modifier.None;

		foreach (m; split[0 .. $ - 1]) {
			const Modifier mo = Key.ParseModifier(m);
			if (!mo)
				return KeyBind(Modifier.None, Key(0), MouseButton.None);
			mod |= mo;
		}

		return KeyBind(cast(Modifier)(mod & ~Key.NumlockMask), key, mouse);
	}

	auto grabKey(bool owner_events, Modifier modifiers, xcb_keycode_t key, ubyte pointerMode, ubyte keyboardMode) {
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

	auto ungrabKey(xcb_keycode_t key, Modifier modifiers) {
		//dfmt off
		return xcb_ungrab_key(
			xcb.Connection,
			key,
			xcb.Root.InternalWindow,
			modifiers
		);
		//dfmt on
	}

	auto grabButton(bool owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode, xcb_cursor_t cursor,
			MouseButton button, Modifier modifiers) {
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

	auto ungrabButton(MouseButton button, Modifier modifiers) {
		return xcb_ungrab_button(xcb.Connection, button, xcb.Root.InternalWindow, modifiers);
	}

}
