module dwin.backend.bindmanager;

import dwin.log;

alias Key = uint;

//XXX: This is the same as XCB_MOD_MASK.
enum Modifier : ushort {
	None = 0,
	Shift = 1 << 0,
	Lock = 1 << 1,
	Control = 1 << 2,
	Mod1 = 1 << 3,
	Mod2 = 1 << 4,
	Mod3 = 1 << 5,
	Mod4 = 1 << 6,
	Mod5 = 1 << 7
}

enum MouseButton : ubyte {
	None = 0,
	Button1,
	Button2,
	Button3,
	Button4,
	Button5
}

abstract class BindManager {
	alias MapBind = void delegate(bool isPressed);
	struct KeyBind {
		Key key;
		Modifier modifier;
		MouseButton mouseButton;

		this(Modifier modifier, Key key, MouseButton mouseButton) {
			this.modifier = modifier;
			this.key = key;
			this.mouseButton = mouseButton;
		}

		@property bool IsValid() {
			return !!key || !!mouseButton;
		}

		string toString() {
			import std.format : format;

			return format("KeyBind(%s, %x, %s)", modifier, key, mouseButton);
		}
	}

	abstract void Rebind();

	void Map(string keys, MapBind func) {
		KeyBind keyBind = toKeyBind(keys);
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s): '%s'", keyBind, keys);
			return;
		}

		Map(keyBind, func);
	}

	void Unmap(string keys) {
		KeyBind keyBind = toKeyBind(keys);
		if (!keyBind.IsValid) {
			Log.MainLogger.Error("Invalid mapping (%s): '%s'", keyBind, keys);
			return;
		}

		Unmap(keyBind);
	}

	abstract void Map(KeyBind keyBind, MapBind func);
	abstract void Unmap(KeyBind keyBind);
protected:
	IKeyParser keyParser;
	MapBind[KeyBind] mappings;

	KeyBind toKeyBind(string keys) {
		import std.array;
		import std.string;
		import std.algorithm;

		auto split = keys.split("+").map!(strip);

		MouseButton mouse = keyParser.ParseMouseButton(split[$ - 1]);
		Key key = (mouse == MouseButton.None) ? keyParser.ParseKey(split[$ - 1]) : Key(0);
		Modifier mod = Modifier.None;

		foreach (m; split[0 .. $ - 1]) {
			const Modifier mo = keyParser.ParseModifier(m);
			if (!mo)
				return KeyBind(Modifier.None, Key(0), MouseButton.None);
			mod |= mo;
		}

		return KeyBind(cast(Modifier)(mod & ~keyParser.NumlockMask), key, mouse);
	}
}

interface IKeyParser {
	Key ParseKey(string key);
	Modifier ParseModifier(string mod);
	MouseButton ParseMouseButton(string button);
	@property uint NumlockMask();
	@property uint MouseMasks();
}
