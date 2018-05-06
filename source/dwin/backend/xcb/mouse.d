module dwin.backend.xcb.mouse;

import dwin.io.mouse;
import xcb.xcb;
import dwin.backend.xcb.engine;
import dwin.backend.xcb.mousestyle;
import dwin.backend.xcb.root;

class XCBMouse : Mouse {
public:
	this(XCBEngine engine) {
		this.engine = engine;

		styles[MouseStyles.Normal] = new XCBMouseStyle(engine, XCBMouseIcons.XC_left_ptr);
		styles[MouseStyles.Resizing] = new XCBMouseStyle(engine, XCBMouseIcons.XC_sizing);
		styles[MouseStyles.Moving] = new XCBMouseStyle(engine, XCBMouseIcons.XC_fleur);

		styles[MouseStyles.Normal].Apply();
	}

	override void Update() {
		xcb_query_pointer_reply_t* reply = xcb_query_pointer_reply(engine.Connection,
				xcb_query_pointer(engine.Connection, (cast(XCBRoot)engine.RootContainer).InternalWindow), null);

		x = reply.root_x;
		y = reply.root_y;

		buttons[0] = !!(reply.mask & XCB_KEY_BUT_MASK_BUTTON_1);
		buttons[1] = !!(reply.mask & XCB_KEY_BUT_MASK_BUTTON_2);
		buttons[2] = !!(reply.mask & XCB_KEY_BUT_MASK_BUTTON_3);
		buttons[3] = !!(reply.mask & XCB_KEY_BUT_MASK_BUTTON_4);
		buttons[4] = !!(reply.mask & XCB_KEY_BUT_MASK_BUTTON_5);

		xcb_free(reply);
	}

	override void Move(short x, short y) {
		xcb_warp_pointer(engine.Connection, XCB_NONE, (cast(XCBRoot)engine.RootContainer).InternalWindow, 0, 0, 0, 0, x, y);
	}

private:
	XCBEngine engine;
}
