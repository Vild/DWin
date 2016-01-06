module dwin.backend.xcb.xcb;

import dwin.log;

import xcb.xcb;
import xcb.keysyms;
import dwin.backend.xcb.key;
import dwin.backend.xcb.cursor;
import dwin.backend.xcb.window;

class XCB {
public:
	this() {
		log = Log.MainLogger;
		connection = xcb_connect(null, null);
		conError err = cast(conError)xcb_connection_has_error(connection);
		if (err)
			log.Fatal("Error while connecting to X11, %s", err);
		log.Info("Successfully connect to X11!");

		setup = xcb_get_setup(connection);
		screen = xcb_setup_roots_iterator(setup).data;
		root = new Window(this, screen.root);
		symbols = xcb_key_symbols_alloc(connection);
	}

	~this() {
		xcb_key_symbols_free(symbols);
		xcb_disconnect(connection);
	}

	auto GrabKey(ubyte owner_events, ushort modifiers, xcb_keycode_t key, ubyte pointerMode, ubyte keyboardMode) {
		//dfmt off
		return xcb_grab_key(
			connection,
			owner_events,
			root.Window,
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
			connection,
			key,
			root.Window,
			modifiers
		);
		//dfmt on
	}

	auto GrabButton(ubyte owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode, xcb_cursor_t cursor,
		ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_grab_button(
			connection,
			owner_events,
			root.Window,
			event_mask,
			pointerMode,
			keyboardMode,
			root.Window,
			cursor,
			button,
			modifiers
		);
		//dfmt on
	}

	auto UngrabButton(ubyte owner_events, ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_ungrab_button(
			connection,
			button,
			root.Window,
			modifiers
		);
		//dfmt on
	}

	auto GrabPointer(ubyte owner_events, ushort event_mask, ubyte pointerMode, ubyte keyboardMode,
		xcb_cursor_t cursor, xcb_timestamp_t time) {
		//dfmt off
		return xcb_grab_pointer(
			connection,
			owner_events,
			root.Window,
			event_mask,
			pointerMode,
			keyboardMode,
			root.Window,
			cursor,
			time
		);
		//dfmt on
	}

	auto UngrabPointer(xcb_timestamp_t time) {
		return xcb_ungrab_pointer(connection, time);
	}

	void Flush() {
		xcb_flush(connection);
	}

	@property xcb_connection_t* Connection() {
		return connection;
	}

	@property xcb_screen_t* Screen() {
		return screen;
	}

	@property const(xcb_setup_t)* Setup() {
		return setup;
	}

	@property Window Root() {
		return root;
	}

	@property xcb_key_symbols_t* Symbols() {
		return symbols;
	}

private:
	enum conError {
		Error = 1,
		ClosedExtNotSupported,
		ClosedMemInsufficient,
		ClosedReqLenExceed,
		ClosedParseErr,
		ClosedInvalidScreen
	}

	Log log;
	xcb_connection_t* connection;
	xcb_screen_t* screen;
	const xcb_setup_t* setup;
	Window root;
	xcb_key_symbols_t* symbols;

	Window[] windows;
}
