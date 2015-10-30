module dwin.dwin;

import dwin.log;
import dwin.event;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.window;
import dwin.backend.xcb.atom;
import dwin.backend.xcb.event;
import dwin.util.data;
import xcb.xcb;
import xcb.xproto;

final class DWin {
public:
	this() {
		log = Log.MainLogger();
		xcb = new XCB();

		bind();
		setup();
	}

	void Run() {
		quit = false;
		while (!quit) {
			const xcb_generic_event_t * e = xcb_wait_for_event(xcb.Connection);

			XCBEvent ev = cast(XCBEvent)(e.response_type & ~0x80);

			switch (e.response_type & ~0x80) {
			default:
				log.Info("Event caught: %s", ev);
				break;

			case XCB_BUTTON_RELEASE:
				onButtonRelease(cast(xcb_button_release_event_t *)e);
				break;

			case XCB_BUTTON_PRESS:
				onButtonPress(cast(xcb_button_press_event_t *)e);
				break;
			case XCB_CLIENT_MESSAGE:
				onClientMessage(cast(xcb_client_message_event_t *)e);
				break;
			case XCB_CONFIGURE_REQUEST:
				onConfigureRequest(cast(xcb_configure_request_event_t *)e);
				break;
			case XCB_CONFIGURE_NOTIFY:
				onConfigureNotify(cast(xcb_configure_notify_event_t *)e);
				break;
			case XCB_DESTROY_NOTIFY:
				onDestroyNotify(cast(xcb_destroy_notify_event_t *)e);
				break;
			case XCB_ENTER_NOTIFY:
				onEnterNotify(cast(xcb_enter_notify_event_t *)e);
				break;
			case XCB_EXPOSE:
				onExpose(cast(xcb_expose_event_t *)e);
				break;
			case XCB_FOCUS_IN:
				onFocusIn(cast(xcb_focus_in_event_t *)e);
				break;
			case XCB_KEY_PRESS:
				onKeyPress(cast(xcb_key_press_event_t *)e);
				break;
			case XCB_MAPPING_NOTIFY:
				onMappingNotify(cast(xcb_mapping_notify_event_t *)e);
				break;
			case XCB_MAP_REQUEST:
				onMapRequest(cast(xcb_map_request_event_t *)e);
				break;
			case XCB_MOTION_NOTIFY:
				onMotionNotify(cast(xcb_motion_notify_event_t *)e);
				break;
			case XCB_PROPERTY_NOTIFY:
				onPropertyNotify(cast(xcb_property_notify_event_t *)e);
				break;
			case XCB_UNMAP_NOTIFY:
				onUnmapNotify(cast(xcb_unmap_notify_event_t *)e);
				break;
			}

		}
	}

private:
	enum HandlingEvent {
		NONE,
		MOVE,
		RESIZE
	}

	struct AtomName {
		int id;
		string name;
	}

	enum WMAtoms : AtomName {
		Protocols = AtomName(0, "WM_PROTOCOLS"),
		Delete    = AtomName(1, "WM_DELETE_WINDOW"),
		State     = AtomName(2, "WM_STATE"),
		TakeFocus = AtomName(3, "WM_TAKE_FOCUS")
	}

	enum NETAtoms : AtomName {
		Supported          = AtomName(0, "_NET_SUPPORTED"),
		WMName             = AtomName(1, "_NET_WM_NAME"),
		WMState            = AtomName(2, "_NET_WM_STATE"),
		WMFullscreen       = AtomName(3, "_NET_WM_STATE_FULLSCREEN"),
		ActiveWindow       = AtomName(4, "_NET_ACTIVE_WINDOW"),
		WMWindowType       = AtomName(5, "_NET_WM_WINDOW_TYPE"),
		WMWindowTypeDialog = AtomName(6, "_NET_WM_WINDOW_TYPE_DIALOG"),
		ClientList         = AtomName(7, "_NET_CLIENT_LIST")
	}

	Log log;
	XCB xcb;
	Window window;

	bool quit;
	HandlingEvent handlingEvent = HandlingEvent.NONE;
	xcb_drawable_t win;
	xcb_get_geometry_reply_t * geom;
	enum Loc {
		FIRST,
		SECOND,
		THIRD
	}

	xcb_get_geometry_reply_t oldGeom;
	int pointerDiffX, pointerDiffY;

	Loc row, column;

	Atom[EnumCount!(WMAtoms)()] lookupWMAtoms;
	Atom[EnumCount!(NETAtoms)()] lookupNETAtoms;

	Event!(xcb_button_press_event_t *) onButtonPress;
	Event!(xcb_client_message_event_t *) onClientMessage;
	Event!(xcb_configure_request_event_t *) onConfigureRequest;
	Event!(xcb_configure_notify_event_t *) onConfigureNotify;
	Event!(xcb_destroy_notify_event_t *) onDestroyNotify;
	Event!(xcb_enter_notify_event_t *) onEnterNotify;
	Event!(xcb_expose_event_t *) onExpose;
	Event!(xcb_focus_in_event_t *) onFocusIn;
	Event!(xcb_key_press_event_t *) onKeyPress;
	Event!(xcb_mapping_notify_event_t *) onMappingNotify;
	Event!(xcb_map_request_event_t *) onMapRequest;
	Event!(xcb_motion_notify_event_t *) onMotionNotify;
	Event!(xcb_property_notify_event_t *) onPropertyNotify;
	Event!(xcb_unmap_notify_event_t *) onUnmapNotify;

	Event!(xcb_button_release_event_t *) onButtonRelease;

	void bind() {
		xcb.GrabKey(0, XCB_MOD_MASK_ANY, 9,	XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);

		xcb.GrabButton(1, XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
			XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, 1, XCB_MOD_MASK_ANY);

		xcb.GrabButton(1,	XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
			XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, 3, XCB_MOD_MASK_ANY);
	}

	void setup() {
		import std.traits : EnumMembers;

		foreach (wmAtom; EnumMembers!WMAtoms)
			lookupWMAtoms[wmAtom.id] = Atom(xcb, wmAtom.name);

		foreach (netAtom; EnumMembers!NETAtoms)
			lookupNETAtoms[netAtom.id] = Atom(xcb, netAtom.name);

		window = new Window(xcb, 400, 100, "DWin-Bar");
		window.Drawable.DrawRectangle([
			xcb_rectangle_t(0, 0, 200, 50),
			xcb_rectangle_t(200, 50, 200, 50)
		], true);
		window.Render();
		window.Map();
		xcb.Flush();

		onKeyPress ~= &shouldQuit;
		onButtonPress ~= &doMovingWindow;
		onMotionNotify ~= &handleMoving;
		onButtonRelease ~= &buttonRelease;
	}

	void shouldQuit(xcb_key_press_event_t * key) {
		quit = key.detail == 9 /* Escape */;
	}

	void doMovingWindow(xcb_button_press_event_t * be) {
		if (!(be.state & XCB_MOD_MASK_CONTROL))
			return;

		win = be.child;
		if (!win)
			return;
		// Move the window that was clicked on, to the front.
		xcb_configure_window(xcb.Connection, win, XCB_CONFIG_WINDOW_STACK_MODE, [cast(uint)XCB_STACK_MODE_ABOVE].ptr);

		// Get window size
		geom = xcb_get_geometry_reply(xcb.Connection, xcb_get_geometry(xcb.Connection, win), null);
		xcb_query_pointer_reply_t *pointer = xcb_query_pointer_reply(xcb.Connection, xcb_query_pointer(xcb.Connection, xcb.Root), null);

		if (be.detail == 1) { //Left click
			handlingEvent = HandlingEvent.MOVE;
			pointerDiffX = pointer.root_x - geom.x;
			pointerDiffY = pointer.root_y - geom.y;
			oldGeom = *geom;
		} else {
			handlingEvent = HandlingEvent.RESIZE;
			pointerDiffX = pointer.root_x - (geom.x + geom.width/2);
			pointerDiffY = pointer.root_y - (geom.y + geom.height/2);
			oldGeom = *geom;

			int pointX = (pointer.root_x - geom.x) / (geom.width	/ 4)+1;
			int pointY = (pointer.root_y - geom.y) / (geom.height / 4)+1;

			log.Info("PointX: %d, PointY: %d", pointX, pointY);

			if (pointX & 0b100)
				column = Loc.THIRD;
			else if (pointX & 0b10)
				column = Loc.SECOND;
			else if (pointX & 0b1)
				column = Loc.FIRST;
			else
				assert(0);

			if (pointY & 0b100)
				row = Loc.THIRD;
			else if (pointY & 0b10)
				row = Loc.SECOND;
			else if (pointY & 0b1)
				row = Loc.FIRST;
			else
				assert(0);

			log.Info("Row: %s, Column: %s", row, column);
		}
		xcb.GrabPointer(0, XCB_EVENT_MASK_BUTTON_RELEASE
			| XCB_EVENT_MASK_BUTTON_MOTION | XCB_EVENT_MASK_POINTER_MOTION_HINT,
			XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, XCB_CURRENT_TIME);
		xcb.Flush();
	}

	void handleMoving(xcb_motion_notify_event_t * e) {
		if (handlingEvent == HandlingEvent.NONE)
			return;
		xcb_query_pointer_reply_t *pointer = xcb_query_pointer_reply(xcb.Connection, xcb_query_pointer(xcb.Connection, xcb.Root), null);
		if (handlingEvent == HandlingEvent.MOVE) {
			geom = xcb_get_geometry_reply(xcb.Connection, xcb_get_geometry(xcb.Connection, win), null);

			uint px = pointer.root_x - pointerDiffX;
			uint py = pointer.root_y - pointerDiffY;

			xcb_configure_window(xcb.Connection, win, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, [px, py].ptr);
			xcb.Flush();
		} else if (handlingEvent == HandlingEvent.RESIZE) {
			geom = xcb_get_geometry_reply(xcb.Connection, xcb_get_geometry(xcb.Connection, win), null);


			int px = geom.x;
			int py = geom.y;
			int pw = geom.width; // pointer.root_x - geom.x + pointerDiffX;
			int ph = geom.height; // pointer.root_y - geom.y + pointerDiffY;


			if (row == Loc.FIRST) {
				if (column == Loc.FIRST) {
					immutable uint oldPx = px;
					px = (pointer.root_x) - (pointerDiffX + oldGeom.width	/ 2);
					pw += oldPx - px;

					immutable uint oldPy = py;
					py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
					ph += oldPy - py;

				} else if (column == Loc.SECOND) {
					immutable uint oldPy = py;
					py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
					ph += oldPy - py;
				} else /*if (column == Loc.THIRD) */ {
					pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width	/ 2);

					immutable uint oldPy = py;
					py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
					ph += oldPy - py;
				}
			} else if (row == Loc.SECOND) {
				if (column == Loc.FIRST) {
					immutable uint oldPx = px;
					px = (pointer.root_x) - (pointerDiffX + oldGeom.width	/ 2);
					pw += oldPx - px;

				} else if (column == Loc.SECOND) {

				} else /*if (column == Loc.THIRD) */ {
					pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width	/ 2);
				}
			} else /*if (row == Loc.THIRD) */ {
				if (column == Loc.FIRST) {
					immutable uint oldPx = px;
					px = (pointer.root_x) - (pointerDiffX + oldGeom.width	/ 2);
					pw += oldPx - px;

					ph = (pointer.root_y - oldGeom.y) - (pointerDiffY - oldGeom.height/2);
				} else if (column == Loc.SECOND) {


					ph = (pointer.root_y - oldGeom.y) - (pointerDiffY - oldGeom.height/2);
				} else /*if (column == Loc.THIRD) */ {
					pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width	/ 2);
					ph = (pointer.root_y - oldGeom.y) - (pointerDiffY - oldGeom.height / 2);
				}
			}

			{
				import std.algorithm.comparison : max;
				px = max(px, 0);
				py = max(py, 0);
				pw = max(pw, 16);
				ph = max(ph, 16);
			}

			xcb_configure_window(xcb.Connection, win,
				XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT,
				[cast(uint)px, cast(uint)py, cast(uint)pw, cast(uint)ph].ptr);
			xcb.Flush();
		}
	}

	void buttonRelease(xcb_button_release_event_t * e) {
		handlingEvent = HandlingEvent.NONE;
		xcb.UngrabPointer(XCB_CURRENT_TIME);
		xcb.Flush();
	}
}
