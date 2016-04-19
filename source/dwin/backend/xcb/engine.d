module dwin.backend.xcb.engine;

public import core.stdc.stdlib : xcb_free = free;

import xcb.xcb;
import xcb.xproto;
import xcb.ewmh;
import xcb.keysyms;
import xcb.icccm;

import dwin.backend.engine;
import dwin.log;
import dwin.backend.xcb.event;
import dwin.backend.xcb.errorcode;
import dwin.backend.xcb.root;
import dwin.backend.xcb.mouse;
import dwin.backend.xcb.keyboard;
import dwin.backend.xcb.window;
import dwin.logic.logiccore;

class XCBEngine : Engine {
public:
	this(string scriptFolder) {
		super(scriptFolder);

		int defScreen;
		con = xcb_connect(null, &defScreen);
		screen = getScreen(defScreen);
		connectionError err = cast(connectionError)xcb_connection_has_error(con);
		if (err)
			log.Fatal("Error while connecting to X11, %s", err);
		log.Info("Successfully connect to X11!");

		symbols = xcb_key_symbols_alloc(con);
		if (!xcb_ewmh_init_atoms_replies(&ewmhCon, xcb_ewmh_init_atoms(con, &ewmhCon), null))
			log.Fatal("Could not connect to ewmh!");

		root = new XCBRoot(this, screen.root);
		mouse = new XCBMouse(this);
		keyboard = new XCBKeyboard(this);

		takeWMControl();
		setup();
	}

	~this() {
		xcb_key_symbols_free(symbols);
		xcb_disconnect(con);
	}

	override void HandleEvent() {
		const xcb_generic_event_t* e = xcb_poll_for_event(con);
		if (!e)
			return;
		XCBEvent ev = cast(XCBEvent)(e.response_type & ~0x80);

		mouse.Update();

		switch (ev) with (XCBEvent) {
		default:
			log.Error("Event caught: %s\tNo action done!", ev);
			break;

		case XCB_NULL_EVENT: // Do nothing
			break;

		case XCB_ENTER_NOTIFY:
			break;

		case XCB_PROPERTY_NOTIFY:
			break;

		case XCB_MAPPING_NOTIFY:
			auto notify = cast(xcb_mapping_notify_event_t*)e;

			xcb_refresh_keyboard_mapping(symbols, notify);
			if (notify.request == XCB_MAPPING_NOTIFY)
				keyboard.Rebind();
			break;

		case XCB_MOTION_NOTIFY:
			break;

		case XCB_BUTTON_PRESS:
			xcb_button_press_event_t* press = cast(xcb_button_press_event_t*)e;
			//auto window = findWindow(press.child);
			(cast(XCBKeyboard)keyboard).HandleButtonPressEvent(press);
			xcb_allow_events(con, XCB_ALLOW_REPLAY_POINTER, press.time);
			break;

		case XCB_BUTTON_RELEASE:
			xcb_button_release_event_t* release = cast(xcb_button_release_event_t*)e;
			//auto window = findWindow(release.child);
			(cast(XCBKeyboard)keyboard).HandleButtonReleaseEvent(release);
			xcb_allow_events(con, XCB_ALLOW_REPLAY_POINTER, release.time);
			break;

		case XCB_KEY_PRESS:
			(cast(XCBKeyboard)keyboard).HandleKeyPressEvent(cast(xcb_key_press_event_t*)e);
			break;

		case XCB_KEY_RELEASE:
			(cast(XCBKeyboard)keyboard).HandleKeyReleaseEvent(cast(xcb_key_release_event_t*)e);
			break;

		case XCB_CREATE_NOTIFY:
			auto notify = cast(xcb_create_notify_event_t*)e;
			auto window = new XCBWindow(this, notify.window);
			uint values = XCB_EVENT_MASK_PROPERTY_CHANGE | XCB_EVENT_MASK_ENTER_WINDOW;
			xcb_change_window_attributes(con, notify.window, XCB_CW_EVENT_MASK, &values);

			log.Error("CreateNotify: %s %s", *notify, window);
			windows ~= window;
			logicCore.NewWindow(window);
			break;

		case XCB_DESTROY_NOTIFY:
			auto notify = cast(xcb_destroy_notify_event_t*)e;

			ulong idx;
			auto window = findWindow(notify.window, &idx);
			if (!window)
				break;
			log.Error("DestroyNotify: %s %s", *notify, window);
			logicCore.RemoveWindow(window);
			window.destroy;
			for (size_t i = idx; i < windows.length - 1; i++)
				windows[i] = windows[i + 1];
			windows.length--;
			break;

		case XCB_MAP_NOTIFY:
			break;

		case XCB_MAP_REQUEST:
			auto map = cast(xcb_map_request_event_t*)e;
			auto window = findWindow(map.window);
			log.Error("MapRequest: %s %s", *map, window);
			if (window)
				logicCore.ShowWindow(window);
			break;

		case XCB_UNMAP_NOTIFY:
			auto unmap = cast(xcb_unmap_notify_event_t*)e;
			auto window = findWindow(unmap.window);
			log.Error("UnmapNotify: %s %s", *unmap, window);
			if (window)
				logicCore.WindowHidden(window);
			break;

		case XCB_CONFIGURE_NOTIFY:
			break;

		case XCB_CONFIGURE_REQUEST:
			break;

		case XCB_CLIENT_MESSAGE:
			break;
		}

		xcb_free(cast(void*)e);
		xcb_flush(con);
	}

	@property xcb_connection_t* Connection() {
		return con;
	}

	@property xcb_key_symbols_t* Symbols() {
		return symbols;
	}
	
private:
	enum connectionError {
		Error = 1,
		ClosedExtNotSupported,
		ClosedMemInsufficient,
		ClosedReqLenExceed,
		ClosedParseErr,
		ClosedInvalidScreen
	}

	//dfmt off
	uint rootEventMask =
		XCB_EVENT_MASK_STRUCTURE_NOTIFY | // CirculateNotify, ConfigureNotify, DestroyNotify, GravityNotify, MapNotify, ReparentNotify, UnmapNotify
		XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | // CirculateNotify, ConfigureNotify, CreateNotify, DestroyNotify, GravityNotify, MapNotify, ReparentNotify, UnmapNotify
		XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT | // CirculateRequest, ConfigureRequest, MapRequest
		XCB_EVENT_MASK_PROPERTY_CHANGE // PropertyNotify
		;
	//dfmt on

	xcb_connection_t* con;
	xcb_screen_t* screen;
	xcb_key_symbols_t* symbols;
	xcb_ewmh_connection_t ewmhCon;
	
	xcb_screen_t* getScreen(int screen) {
		for (auto it = xcb_setup_roots_iterator(xcb_get_setup(con)); it.rem; --screen, xcb_screen_next(&it))
			if (screen == 0)
				return it.data;
		return null;
	}

	void takeWMControl() {
		xcb_generic_error_t* error = xcb_request_check(con, xcb_change_window_attributes_checked(con, screen.root,
			XCB_CW_EVENT_MASK, &rootEventMask));
		if (error) {
			scope (exit)
				xcb_free(error);
			//dfmt off
			log.Fatal(
				"XCB error: %s, sequence: %s, resource id: %s, major code: %s, minor code: %s",
				cast(XCBErrorCode)error.error_code,
				error.sequence,
				error.resource_id,
				error.major_code,
				error.minor_code);
			//dfmt on
		}
	}

	XCBWindow findWindow(xcb_window_t id, ulong* idx = null) {
		foreach (i, win; windows)
			if (auto window = cast(XCBWindow)win)
				if (window.InternalWindow == id) {
					if (idx != null)
						*idx = i;
					return window;
				}

		return null;
	}
	
	void setup() {

	}
}
