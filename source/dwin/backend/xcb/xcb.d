module dwin.backend.xcb.xcb;

import dwin.log;
import dwin.event;

import xcb.xcb;
import xcb.keysyms;
import xcb.ewmh;
import xcb.xinerama;
import dwin.backend.screen;
import dwin.backend.window;
import dwin.backend.xcb.atom;
import dwin.backend.xcb.bindmanager;
import dwin.backend.xcb.event;
import dwin.backend.xcb.key;
import dwin.backend.xcb.xcbwindow;
import dwin.backend.xcb.xcbmouse;
import dwin.util.data;

import std.traits;
import std.algorithm.searching;
import std.algorithm.mutation;
public import std.c.stdlib : xcb_free = free;

class XCB {
public:
	this() {
		log = Log.MainLogger;
		connection = xcb_connect(":8", &defaultScreen);
		conError err = cast(conError)xcb_connection_has_error(connection);
		if (err)
			log.Fatal("Error while connecting to X11, %s", err);
		log.Info("Successfully connect to X11!");

		symbols = xcb_key_symbols_alloc(connection);
		auto cookie = xcb_ewmh_init_atoms(connection, &ewmhConnection);
		if (!xcb_ewmh_init_atoms_replies(&ewmhConnection, cookie, null))
			log.Fatal("Could not connect to ewmh!");

		rootScreen = getScreen(defaultScreen);
		root = new XCBWindow(this, rootScreen.root);
		mouse = new XCBMouse(this);

		bindMgr = new BindManager(this);

		checkOtherWM();
		setup();
	}

	~this() {
		xcb_key_symbols_free(symbols);
		xcb_disconnect(connection);
	}

	void DoEvent() {
		const xcb_generic_event_t* e = xcb_wait_for_event(connection);

		XCBEvent ev = cast(XCBEvent)(e.response_type & ~0x80);

		switch (ev) with (XCBEvent) {
		default:
			log.Error("Event caught: %s\tNo action done!", ev);
			break;

		case XCB_NULL_EVENT: // Do nothing
			break;

		case XCB_PROPERTY_NOTIFY:
			auto notify = cast(xcb_property_notify_event_t*)e;

			if (notify.state == XCB_PROPERTY_DELETE)
				break; // Ignore
			else
				log.Error("Doesn't handle XCB_PROPERTY_NOTIFY state: %s", notify.state);
			break;

		case XCB_MAPPING_NOTIFY:
			auto notify = cast(xcb_mapping_notify_event_t*)e;

			xcb_refresh_keyboard_mapping(symbols, notify);
			if (notify.request == XCB_MAPPING_NOTIFY)
				bindMgr.Rebind();
			break;

		case XCB_MOTION_NOTIFY:
			auto notify = cast(xcb_motion_notify_event_t*)e;
			onMouseMotion(notify.root_x, notify.root_y);
			xcb_allow_events(connection, XCB_ALLOW_REPLAY_POINTER, notify.time);
			break;

		case XCB_BUTTON_PRESS:
			xcb_button_press_event_t* press = cast(xcb_button_press_event_t*)e;
			//auto window = findWindow(press.child);
			bindMgr.HandleButtonPressEvent(press);
			xcb_allow_events(connection, XCB_ALLOW_REPLAY_POINTER, press.time);
			break;

		case XCB_BUTTON_RELEASE:
			xcb_button_release_event_t* release = cast(xcb_button_release_event_t*)e;
			//auto window = findWindow(release.child);
			bindMgr.HandleButtonReleaseEvent(release);
			xcb_allow_events(connection, XCB_ALLOW_REPLAY_POINTER, release.time);
			break;

		case XCB_KEY_PRESS:
			bindMgr.HandleKeyPressEvent(cast(xcb_key_press_event_t*)e);
			break;

		case XCB_KEY_RELEASE:
			bindMgr.HandleKeyReleaseEvent(cast(xcb_key_release_event_t*)e);
			break;

		case XCB_CREATE_NOTIFY:
			auto notify = cast(xcb_create_notify_event_t*)e;
			auto window = new XCBWindow(this, notify.window);
			windows ~= window;
			onNewWindow(window);
			break;

		case XCB_DESTROY_NOTIFY:
			auto notify = cast(xcb_destroy_notify_event_t*)e;

			ulong idx;
			auto window = findWindow(notify.window, &idx);
			window.Dead = true;
			onRemoveWindow(window);
			window.destroy;
			windows = windows.remove(idx);

			break;

		case XCB_MAP_NOTIFY: // Skip check of this because every time we call xcb_map_window, it will trigger this event
			auto notify = cast(xcb_map_notify_event_t*)e;
			if (notify.override_redirect)
				log.Warning("Map notify with override_redirect!");
			break;

		case XCB_MAP_REQUEST:
			auto map = cast(xcb_map_request_event_t*)e;
			auto window = findWindow(map.window);
			if (window)
				onRequestShowWindow(window);
			break;

		case XCB_UNMAP_NOTIFY:
			auto unmap = cast(xcb_unmap_notify_event_t*)e;
			auto window = findWindow(unmap.window);
			if (window)
				onRequestHideWindow(window);
			break;

		case XCB_CONFIGURE_NOTIFY:
			auto notify = cast(xcb_configure_notify_event_t*)e;
			if (notify.window == Root.InternalWindow) {
				log.Error("Didn't handle window configure notify, PLEASE FIX"); //TODO: Fix this
				if (Root.Width != notify.width || Root.Height != notify.height)
					log.Info("Root window went from %sx%s to %sx%s", Root.Width, Root.Height, notify.width, notify.height);
			}
			break;

		case XCB_CONFIGURE_REQUEST:
			auto request = cast(xcb_configure_request_event_t*)e;
			XCBWindow window = findWindow(request.window);
			if (!window)
				break;

			bool check1 = !!(request.value_mask & XCB_CONFIG_WINDOW_X);
			bool check2 = !!(request.value_mask & XCB_CONFIG_WINDOW_Y);

			if (check1 || check2)
				onRequestMoveWindow(window, (check1) ? request.x : window.X, (check2) ? request.y : window.Y);

			check1 = !!(request.value_mask & XCB_CONFIG_WINDOW_WIDTH);
			check2 = !!(request.value_mask & XCB_CONFIG_WINDOW_HEIGHT);
			if (check1 || check2)
				onRequestResizeWindow(window, (check1) ? request.width : window.Width, (check2) ? request.height : window.Height);

			if (request.value_mask & XCB_CONFIG_WINDOW_BORDER_WIDTH)
				onRequestBorderSizeWindow(window, request.border_width);
			if (request.value_mask & XCB_CONFIG_WINDOW_SIBLING) {
				auto sibling = findWindow(request.sibling);
				onRequestSiblingWindow(window, sibling);
			}
			if (request.value_mask & XCB_CONFIG_WINDOW_STACK_MODE)
				onRequestStackModeWindow(window, request.stack_mode);
			break;

		case XCB_CLIENT_MESSAGE:
			auto msg = cast(xcb_client_message_event_t*)e;
			log.Info("ClientMessage: format: %s, window: %s, type: %s, data: %s", msg.format, msg.window, msg.type, msg.data);
			break;
		}
		Flush();
	}

	void Flush() {
		xcb_flush(connection);
	}

	Window FindWindow(short x, short y) {
		import dwin.backend.layout : Layout;
		import dwin.backend.container : Container;
		import dwin.backend.workspace : Workspace;

		Window traverseWin(Window window, short x, short y) {
			window.Update();
			log.Debug("%s >= %s && %s <= %s && %s >= %s && %s <= %s", x, window.X, x, window.X + window.Width, y,
					window.Y, y, window.Y + window.Height);
			if (x >= window.X && x <= window.X + window.Width && y >= window.Y && y <= window.Y + window.Height)
				return window;
			else
				return null;
		}

		Window traverseCon(Container con, short x, short y) {
			if (auto window = cast(Window)con) {
				if (auto win = traverseWin(window, x, y))
					return win;
			} else if (auto layout = cast(Layout)con)
				foreach (container; layout.Containers)
					if (auto win = traverseCon(container, x, y))
						return win;
			return null;
		}

		Window traverseWorkspace(Workspace workspace, short x, short y) {
			if (auto win = traverseCon(workspace.Root, x, y))
				return win;
			return null;
		}

		Window traverseLayout(Layout layout, short x, short y) {
			foreach (container; layout.Containers)
				if (auto win = traverseCon(container, x, y))
					return win;
			return null;
		}

		Window traverseScreen(Screen screen, short x, short y) {
			if (auto win = traverseLayout(screen.OnTop, x, y))
				return win;
			foreach (workspace; screen.Workspaces)
				if (auto win = traverseWorkspace(workspace, x, y))
					return win;
			return null;
		}

		foreach (screen; screens)
			if (auto win = traverseScreen(screen, x, y))
				return win;
		return null;
	}

	@property xcb_connection_t* Connection() {
		return connection;
	}

	@property int DefaultScreen() {
		return defaultScreen;
	}

	@property xcb_screen_t* RootScreen() {
		return rootScreen;
	}

	@property XCBMouse Mouse() {
		return mouse;
	}

	@property BindManager BindMgr() {
		return bindMgr;
	}

	@property Screen[] Screens() {
		return screens;
	}

	@property XCBWindow Root() {
		return root;
	}

	@property xcb_key_symbols_t* Symbols() {
		return symbols;
	}

	@property xcb_ewmh_connection_t* EWMH() {
		return &ewmhConnection;
	}

	@property ref XCBWindow[] Windows() {
		return windows;
	}

	@property ref auto OnNewWindow() {
		return onNewWindow;
	}

	@property ref auto OnRemoveWindow() {
		return onRemoveWindow;
	}

	@property ref auto OnRequestShowWindow() {
		return onRequestShowWindow;
	}

	@property ref auto OnRequestHideWindow() {
		return onRequestHideWindow;
	}

	@property ref auto OnRequestMoveWindow() {
		return onRequestMoveWindow;
	}

	@property ref auto OnRequestResizeWindow() {
		return onRequestResizeWindow;
	}

	@property ref auto OnRequestBorderSizeWindow() {
		return onRequestBorderSizeWindow;
	}

	@property ref auto OnRequestSiblingWindow() {
		return onRequestSiblingWindow;
	}

	@property ref auto OnRequestStackModeWindow() {
		return onRequestStackModeWindow;
	}

	@property ref auto OnMouseMotion() {
		return onMouseMotion;
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

	struct AtomName {
		ulong id;
		string name;
	}

	//dfmt off
	enum WMAtoms : AtomName {
		Protocols = AtomName(0, "WM_PROTOCOLS"),
		Delete = AtomName(1, "WM_DELETE_WINDOW"),
		State = AtomName(2, "WM_STATE"),
		TakeFocus = AtomName(3, "WM_TAKE_FOCUS")
	}

	enum NETAtoms : AtomName {
		Supported = AtomName(0, "_NET_SUPPORTED"),
		WMName = AtomName(1, "_NET_WM_NAME"),
		WMState = AtomName(2, "_NET_WM_STATE"),
		WMFullscreen = AtomName(3, "_NET_WM_STATE_FULLSCREEN"),
		ActiveWindow = AtomName(4, "_NET_ACTIVE_WINDOW"),
		WMWindowType = AtomName(5, "_NET_WM_WINDOW_TYPE"),
		WMWindowTypeDialog = AtomName(6, "_NET_WM_WINDOW_TYPE_DIALOG"),
		ClientList = AtomName(7, "_NET_CLIENT_LIST")
	}
	//dfmt on

	Log log;
	xcb_connection_t* connection;
	int defaultScreen;
	xcb_screen_t* rootScreen;
	xcb_key_symbols_t* symbols;
	xcb_ewmh_connection_t ewmhConnection;
	XCBWindow root;
	XCBMouse mouse;

	Atom[EnumCount!(WMAtoms)()] lookupWMAtoms;
	Atom[EnumCount!(NETAtoms)()] lookupNETAtoms;

	BindManager bindMgr;
	XCBWindow[] windows;
	Screen[] screens;

	Event!(Window) onNewWindow;
	Event!(Window) onRemoveWindow;
	Event!(Window) onRequestShowWindow;
	Event!(Window) onRequestHideWindow;
	Event!(Window, short, short) onRequestMoveWindow;
	Event!(Window, ushort, ushort) onRequestResizeWindow;
	Event!(Window, ushort) onRequestBorderSizeWindow;
	Event!(Window, Window) onRequestSiblingWindow;
	Event!(Window, ubyte) onRequestStackModeWindow;

	Event!(short, short) onMouseMotion;

	XCBWindow findWindow(xcb_window_t id, ulong* idx = null) {
		foreach (i, window; windows)
			if (window.InternalWindow == id) {
				if (idx != null)
					*idx = i;
				return window;
			}

		return null;
	}

	xcb_screen_t* getScreen(int screen) {
		for (auto it = xcb_setup_roots_iterator(xcb_get_setup(connection)); it.rem; --screen, xcb_screen_next(&it))
			if (screen == 0)
				return it.data;
		return null;
	}

	void setup() {
		import std.format : format;

		foreach (wmAtom; EnumMembers!WMAtoms)
			lookupWMAtoms[wmAtom.id] = Atom(this, wmAtom.name);

		foreach (netAtom; EnumMembers!NETAtoms)
			lookupNETAtoms[netAtom.id] = Atom(this, netAtom.name);

		lookupNETAtoms[NETAtoms.Supported.id].Change(root, lookupNETAtoms);

		lookupNETAtoms[NETAtoms.ClientList.id].Delete(root);

		if (xcb_xinerama_is_active_reply(connection, xcb_xinerama_is_active(connection), null).state) {
			xcb_xinerama_query_screens_reply_t* reply = xcb_xinerama_query_screens_reply(connection,
					xcb_xinerama_query_screens(connection), null);

			auto it = xcb_xinerama_query_screens_screen_info_iterator(reply);
			for (; it.rem > 0; xcb_xinerama_screen_info_next(&it))
				screens ~= new Screen(format("Screen %d", reply.number - it.rem), it.data.x_org, it.data.y_org,
					it.data.width, it.data.height);

			xcb_free(reply);
		} else {
			Root.Update();
			screens ~= new Screen("Root Screen", Root.X, Root.Y, Root.Width, Root.Height);
		}

		Flush();
	}

	void checkOtherWM() {
		//dfmt off
		uint values =
			XCB_EVENT_MASK_STRUCTURE_NOTIFY | // CirculateNotify, ConfigureNotify, DestroyNotify, GravityNotify, MapNotify, ReparentNotify, UnmapNotify
			XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | // CirculateNotify, ConfigureNotify, CreateNotify, DestroyNotify, GravityNotify, MapNotify, ReparentNotify, UnmapNotify
			XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT | // CirculateRequest, ConfigureRequest, MapRequest
			XCB_EVENT_MASK_PROPERTY_CHANGE | // PropertyNotify
			XCB_EVENT_MASK_BUTTON_PRESS | // KeyPress
			XCB_EVENT_MASK_BUTTON_RELEASE | // KeyRelease
			XCB_EVENT_MASK_POINTER_MOTION; // MotionNotify

		//dfmt on
		xcb_generic_error_t* error = xcb_request_check(connection, xcb_change_window_attributes_checked(connection,
				root.InternalWindow, XCB_CW_EVENT_MASK, &values));
		if (error) {
			//dfmt off
			log.Fatal(
				"XCB error: %s, sequence: %s, resource id: %s, major code: %s, minor code: %s",
				cast(XCBErrorCode)error.error_code,
				error.sequence,
				error.resource_id,
				error.major_code,
				error.minor_code);
			//dfmt on
			xcb_free(error);
		}
	}

}

enum XCBErrorCode {
	Success,
	BadRequest,
	BadValue,
	BadWindow,
	BadPixmap,
	BadAtom,
	BadCursor,
	BadFont,
	BadMatch,
	BadDrawable,
	BadAccess,
	BadAlloc,
	BadColor,
	BadGC,
	BadIDChoice,
	BadName,
	BadLength,
	BadImplementation,
	Unknown
}
