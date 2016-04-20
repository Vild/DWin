module dwin.script.api.mouseapi;

import dwin.script.utils;

import dwin.io.mouse;

struct MouseAPI {
	void Init(Mouse mouse) {
		import std.traits : EnumMembers;

		this.mouse = mouse;

		Styles = var.emptyObject;

		foreach (i, member; EnumMembers!MouseStyles)
			mixin("Styles." ~ __traits(allMembers, MouseStyles)[i] ~ " = var(cast(int)" ~ member.stringof ~ ");");
	}

	var Move(var, var[] args) {
		mouse.Move(cast(short)args[0], cast(short)args[1]);
		return var.emptyObject;
	}

	var X(var, var[] args) {
		return var(mouse.X);
	}

	var Y(var, var[] args) {
		return var(mouse.Y);
	}

	var Buttons(var, var[] args) {
		return var(mouse.Buttons);
	}

	var Style(var, var[] args) {
		int styleID = cast(int)args[0];
		import std.format : format;

		assert(MouseStyles.min <= styleID && styleID <= MouseStyles.max, format("ID = %d", styleID));
		mouse.Style(cast(MouseStyles)styleID);
		return var.emptyObject;
	}

	@PublicVar var Styles;
	Mouse mouse;
	mixin ObjectWrapper;
}
