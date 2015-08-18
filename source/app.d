import std.getopt;

int main(string[] args) {
	import std.stdio : writeln, writefln;

	auto result = getopt(args,
		);

	if (result.helpWanted) {
		defaultGetoptPrinter("DWin is a tiled based window manager written in the lovely language called D", result.options);
		return 0;
	}

	MainLoop();

	return 0;
}


enum HandlingEvent {
	NONE,
	MOVE,
	RESIZE
}



void MainLoop() {
	import dwin.log;
	import dwin.backend.xcb.xcb;
	import xcb.xcb;
	import xcb.xproto;
	Log log = Log.MainLogger();
	XCB x = new XCB();

	x.GrabKey(0, XCB_MOD_MASK_ANY, 9,	XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);

	x.GrabButton(1, XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
		XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, 1, XCB_MOD_MASK_ANY);

	x.GrabButton(1,	XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
		XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, 3, XCB_MOD_MASK_ANY);
	x.Flush();


	HandlingEvent handlingEvent = HandlingEvent.NONE;
	xcb_drawable_t win;
	xcb_get_geometry_reply_t * geom;
	bool quit = false;
	enum Loc {
		FIRST,
		SECOND,
		THIRD
	}

	xcb_get_geometry_reply_t oldGeom;
	int pointerDiffX, pointerDiffY;

	Loc row, column;

	while (!quit) {
		xcb_generic_event_t * e = xcb_wait_for_event(x.Display);
		switch (e.response_type & ~0x80) {
		case XCB_KEY_PRESS:
			xcb_key_press_event_t * key = cast(xcb_key_press_event_t *)e;
			quit = key.detail == 9/* Escape */;
			break;
		case XCB_BUTTON_PRESS:
			xcb_button_press_event_t * be = cast(xcb_button_press_event_t *)e;

			if (!(be.state&XCB_MOD_MASK_CONTROL))
				break;

			win = be.child;
			if (!win)
				break;
			// Move the window that was clicked on, to the front.
			xcb_configure_window(x.Display, win, XCB_CONFIG_WINDOW_STACK_MODE, [cast(uint)XCB_STACK_MODE_ABOVE].ptr);

			// Get window size
			geom = xcb_get_geometry_reply(x.Display, xcb_get_geometry(x.Display, win), null);
			xcb_query_pointer_reply_t *pointer = xcb_query_pointer_reply(x.Display, xcb_query_pointer(x.Display, x.Root), null);

			if (be.detail == 1) { //Left click
				handlingEvent = HandlingEvent.MOVE;
				pointerDiffX = pointer.root_x - geom.x;
				pointerDiffY = pointer.root_y - geom.y;
				oldGeom = *geom;
				log.Info("handlingEvent: %s, pointerDiffX: %s, pointerDiffY: %s", handlingEvent, pointerDiffX, pointerDiffY);
			} else {
				handlingEvent = HandlingEvent.RESIZE;
				pointerDiffX = pointer.root_x - (geom.x + geom.width/2);
				pointerDiffY = pointer.root_y - (geom.y + geom.height/2);
				oldGeom = *geom;
				log.Info("handlingEvent: %s, pointerDiffX: %s, pointerDiffY: %s", handlingEvent, pointerDiffX, pointerDiffY);

				int pointX = (pointer.root_x - geom.x) / (geom.width  / 4)+1;
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
			x.GrabPointer(0, XCB_EVENT_MASK_BUTTON_RELEASE
				| XCB_EVENT_MASK_BUTTON_MOTION | XCB_EVENT_MASK_POINTER_MOTION_HINT,
				XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, XCB_NONE, XCB_CURRENT_TIME);
			x.Flush();
			break;

		case XCB_MOTION_NOTIFY:
			if (handlingEvent == HandlingEvent.NONE)
				break;
			xcb_query_pointer_reply_t *pointer = xcb_query_pointer_reply(x.Display, xcb_query_pointer(x.Display, x.Root), null);
			if (handlingEvent == HandlingEvent.MOVE) {
				geom = xcb_get_geometry_reply(x.Display, xcb_get_geometry(x.Display, win), null);

				uint px = pointer.root_x - pointerDiffX;
				uint py = pointer.root_y - pointerDiffY;

				xcb_configure_window(x.Display, win, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, [px, py].ptr);
				x.Flush();
			} else if (handlingEvent == HandlingEvent.RESIZE) {
				geom = xcb_get_geometry_reply(x.Display, xcb_get_geometry(x.Display, win), null);


				int px = geom.x;
				int py = geom.y;
				int pw = geom.width; // pointer.root_x - geom.x + pointerDiffX;
				int ph = geom.height; // pointer.root_y - geom.y + pointerDiffY;


				if (row == Loc.FIRST) {
					if (column == Loc.FIRST) {
						log.Info("FIRST, FIRST");
						uint oldPx = px;
						px = (pointer.root_x) - (pointerDiffX + oldGeom.width  / 2);
						pw += oldPx - px;

						uint oldPy = py;
						py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
						ph += oldPy - py;

					} else if (column == Loc.SECOND) {
						log.Info("FIRST, SECOND");
						uint oldPy = py;
						py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
						ph += oldPy - py;
					} else /*if (column == Loc.THIRD) */ {
						log.Info("FIRST, THIRD");
						pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width  / 2);

						uint oldPy = py;
						py = (pointer.root_y) - (pointerDiffY + oldGeom.height / 2);
						ph += oldPy - py;
					}
				} else if (row == Loc.SECOND) {
					if (column == Loc.FIRST) {
						log.Info("SECOND, FIRST");
						uint oldPx = px;
						px = (pointer.root_x) - (pointerDiffX + oldGeom.width  / 2);
						pw += oldPx - px;

					} else if (column == Loc.SECOND) {
						log.Info("SECOND, SECOND");

					} else /*if (column == Loc.THIRD) */ {
						log.Info("SECOND, THIRD");
						pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width  / 2);
					}
				} else /*if (row == Loc.THIRD) */ {
					if (column == Loc.FIRST) {
						log.Info("THIRD, FIRST");
						uint oldPx = px;
						px = (pointer.root_x) - (pointerDiffX + oldGeom.width  / 2);
						pw += oldPx - px;

						ph = (pointer.root_y - oldGeom.y) - (pointerDiffY - oldGeom.height/2);
					} else if (column == Loc.SECOND) {
						log.Info("THIRD, SECOND");
						log.Info("Mouse pixel from top: %s", pointerDiffY);


						ph = (pointer.root_y - oldGeom.y) - (pointerDiffY - oldGeom.height/2);
					} else /*if (column == Loc.THIRD) */ {
						log.Info("THIRD, THIRD");
						pw = (pointer.root_x - oldGeom.x) - (pointerDiffX - oldGeom.width  / 2);
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

				xcb_configure_window(x.Display, win,
					XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT,
					[cast(uint)px, cast(uint)py, cast(uint)pw, cast(uint)ph].ptr);
				x.Flush();
			}
			break;

		case XCB_BUTTON_RELEASE:
			handlingEvent = HandlingEvent.NONE;
			x.UngrabPointer(XCB_CURRENT_TIME);
			x.Flush();
			break;
		default:

			break;
		}

	}
}
