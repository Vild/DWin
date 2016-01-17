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
		Key key;
		Modifier modifier;

		@property bool IsValid() {
			return !!key;
		}

		string toString() {
			import std.format : format;

			return format("KeyBind(%s, %s)", key, modifier);
		}
	}

	this(XCB xcb) {
		this.xcb = xcb;
		Rebind();
	}

	~this() {
		ungrabKey(XCB_GRAB_ANY, XCB_MOD_MASK_ANY);
		UngrabPointer(XCB_CURRENT_TIME);
	}

	void Rebind() {
		Key.Refresh(xcb);
		immutable uint[] modifiers = [0, XCB_MOD_MASK_LOCK, Key.NumlockMask, Key.NumlockMask | XCB_MOD_MASK_LOCK];
		ungrabKey(XCB_GRAB_ANY, XCB_MOD_MASK_ANY);
		foreach (keyBind, func; mappings) {
			xcb_keycode_t* code = xcb_key_symbols_get_keycode(xcb.Symbols, keyBind.key);
			if (!code)
				continue;

			foreach (mod; modifiers)
				grabKey(true, cast(ushort)(keyBind.modifier | mod), *code, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);
			xcb_free(code);
		}
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

		Log.MainLogger.Debug("Mapping: %s", keyBind);
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

	void HandleKeyDownEvent(xcb_key_press_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(Key(key), cast(xcb_mod_mask_t)(e.state & ~Key.NumlockMask));
		if (auto map = keyBind in mappings)
			(*map)(true);
	}

	void HandleKeyUpEvent(xcb_key_press_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(Key(key), cast(xcb_mod_mask_t)(e.state & ~Key.NumlockMask));
		if (auto map = keyBind in mappings)
			(*map)(false);
	}

	auto GrabPointer(bool owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode, xcb_cursor_t cursor, xcb_timestamp_t time) {
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
	XCB xcb;
	MapBind[KeyBind] mappings;

	KeyBind toKeyBind(string keys) {
		import std.array;
		import std.string;
		import std.algorithm;

		auto split = keys.split("+").map!(strip);
		Key key = Key.ParseKey(split[$ - 1]);
		Modifier mod = cast(Modifier)0; // Hack to fix that the enum starts at 1

		foreach (m; split[0 .. $ - 1]) {
			Modifier mo = Key.ParseModifier(m);
			if (!mo)
				return KeyBind(Key(0), cast(Modifier)0);
			mod |= mo;
			Log.MainLogger.Verbose("Mod: %s", mo);
		}

		Log.MainLogger.Warning("'%s' = Key: %s, Mod: %s", keys, key, mod);
		return KeyBind(key, mod);
	}

	auto grabKey(bool owner_events, ushort modifiers, xcb_keycode_t key, ubyte pointerMode, ubyte keyboardMode) {
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

	auto ungrabKey(xcb_keycode_t key, ushort modifiers) {
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

	auto ungrabButton(ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_ungrab_button(
			xcb.Connection,
			button,
			xcb.Root.InternalWindow,
			modifiers
		);
		//dfmt on
	}
}
