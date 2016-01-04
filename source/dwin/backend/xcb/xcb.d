module dwin.backend.xcb.xcb;

import dwin.log;

import xcb.xcb;
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

		screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;
		root = new Window(this, screen.root);
	}

	~this() {
		xcb_disconnect(connection);
	}

	auto GrabKey(ubyte owner_events, ushort modifiers, xcb_keycode_t key, ubyte pointer_mode, ubyte keyboard_mode) {
		//dfmt off
		return xcb_grab_key(
			connection,
			owner_events,
			root.Window,
			modifiers,
			key,
			pointer_mode,
			keyboard_mode
		);
		//dfmt on
	}

	auto GrabButton(ubyte owner_events, ushort event_mask, ubyte pointer_mode, ubyte keyboard_mode, xcb_cursor_t cursor,
		ubyte button, ushort modifiers) {
		//dfmt off
		return xcb_grab_button(
			connection,
			owner_events,
			root.Window,
			event_mask,
			pointer_mode,
			keyboard_mode,
			root.Window,
			cursor,
			button,
			modifiers
		);
		//dfmt on
	}

	auto GrabPointer(ubyte owner_events, ushort event_mask, ubyte pointer_mode, ubyte keyboard_mode,
		xcb_cursor_t cursor, xcb_timestamp_t time) {
		//dfmt off
		return xcb_grab_pointer(
			connection,
			owner_events,
			root.Window,
			event_mask,
			pointer_mode,
			keyboard_mode,
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

	@property Window Root() {
		return root;
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
	Window root;
}
