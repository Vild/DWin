module dwin.backend.bindmanager;

import xcb.xcb;
import xcb.xproto;

import dwin.backend.xcb.xcb;
import dwin.backend.xcb.key;

final class BindManager {
public:
	this(XCB xcb) {
		this.xcb = xcb;
	}

	~this() {
		foreach (map, func; mapping)
			Unmap(map);
	}

	void Map(string key, mapFunc func) {
		mapping[key] = func;
	}

	void Unmap(string key) {
		mapping.remove(key);
	}

	void HandleKeyEvent(xcb_key_press_event_t * e) {

	}

private:
	alias mapFunc = void delegate(string key);
	XCB xcb;
	mapFunc[string] mapping;
}

struct KeyBind {
	Key key;
	Modifier modifier;
}
