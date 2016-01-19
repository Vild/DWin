module dwin.backend.xcb.xcbmouse;

import dwin.backend.mouse;
import xcb.xcb;
import dwin.backend.xcb.xcb;
import dwin.backend.xcb.xcbmousestyle;

class XCBMouse : Mouse {
public:
	this(XCB xcb) {
		this.xcb = xcb;

		styles[MouseStyles.Normal] = new XCBMouseStyle(xcb, XCBMouseIcons.XC_left_ptr);
		styles[MouseStyles.Resizing] = new XCBMouseStyle(xcb, XCBMouseIcons.XC_sizing);
		styles[MouseStyles.Moving] = new XCBMouseStyle(xcb, XCBMouseIcons.XC_fleur);

		styles[MouseStyles.Normal].Apply();
	}

	override void Update() {
		xcb_query_pointer_reply_t* reply = xcb_query_pointer_reply(xcb.Connection, xcb_query_pointer(xcb.Connection,
				xcb.Root.InternalWindow), null);

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
		xcb_warp_pointer(xcb.Connection, XCB_NONE, xcb.Root.InternalWindow, 0, 0, 0, 0, x, y);
	}

private:
	XCB xcb;
}
