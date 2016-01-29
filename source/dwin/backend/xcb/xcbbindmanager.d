module dwin.backend.xcb.xcbbindmanager;

import xcb.xcb;
import xcb.xproto;
import xcb.keysyms;

import dwin.backend.xcb.xcb;
import dwin.backend.xcb.keyparser;
import dwin.backend.bindmanager;

import dwin.log;

final class XCBBindManager : BindManager {
public:
	this(XCB xcb) {
		this.xcb = xcb;
		keyParser = new XCBKeyParser();
		Rebind();
	}

	override void Rebind() {
		(cast(XCBKeyParser)keyParser).Refresh(xcb);
		immutable uint[] modifiers = [0, XCB_MOD_MASK_LOCK, keyParser.NumlockMask, keyParser.NumlockMask | XCB_MOD_MASK_LOCK];

		ungrabKey(XCB_GRAB_ANY, cast(Modifier)XCB_MOD_MASK_ANY);
		ungrabButton(cast(MouseButton)XCB_BUTTON_INDEX_ANY, cast(Modifier)XCB_MOD_MASK_ANY);
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
					grabButton(true, XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE | XCB_EVENT_MASK_BUTTON_MOTION,
							XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, keyBind.mouseButton,
							cast(Modifier)(keyBind.modifier | mod));
			}
		}
		xcb.Flush();
	}

	override void Map(KeyBind keyBind, MapBind func) {
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s)", keyBind);
			return;
		}

		mappings[keyBind] = func;
		Rebind();
	}

	override void Unmap(KeyBind keyBind) {
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s)", keyBind);
			return;
		}

		mappings.remove(keyBind);
	}

	void HandleKeyPressEvent(xcb_key_press_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(keyParser.NumlockMask | keyParser.MouseMasks)), Key(key), MouseButton.None);
		if (auto map = keyBind in mappings)
			(*map)(true);
	}

	void HandleKeyReleaseEvent(xcb_key_release_event_t* e) {
		xcb_keysym_t key = xcb_key_press_lookup_keysym(xcb.Symbols, e, 0);
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(keyParser.NumlockMask | keyParser.MouseMasks)), Key(key), MouseButton.None);
		if (auto map = keyBind in mappings)
			(*map)(false);
	}

	void HandleButtonPressEvent(xcb_button_press_event_t* e) {
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(keyParser.NumlockMask | keyParser.MouseMasks)),
				keyParser.ParseKey("None"), cast(MouseButton)e.detail);

		xcb.Mouse.Set(e.root_x, e.root_y);
		if (auto map = keyBind in mappings)
			(*map)(true);
	}

	void HandleButtonReleaseEvent(xcb_button_release_event_t* e) {
		KeyBind keyBind = KeyBind(cast(Modifier)(e.state & ~(keyParser.NumlockMask | keyParser.MouseMasks)),
				keyParser.ParseKey("None"), cast(MouseButton)e.detail);

		xcb.Mouse.Set(e.root_x, e.root_y);
		if (auto map = keyBind in mappings)
			(*map)(false);
	}

private:
	XCB xcb;

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
