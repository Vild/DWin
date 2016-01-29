module dwin.script.utils;

public import arsd.jsvar;

struct PublicVar {
}

mixin template ObjectWrapper() {
	var Get() {
		import std.traits : TemplateArgsOf, hasUDA;

		var obj = var.emptyObject;

		var a;
		var[] b;

		alias func = var delegate(var, var[]);

		foreach (memberName; __traits(allMembers, typeof(this))) {
			static if (is(typeof(__traits(getMember, this, memberName)) type)) {
				static if (is(typeof(__traits(getMember, this, memberName)))) {
					static if (hasUDA!(__traits(getMember, this, memberName), PublicVar)) {
						obj[memberName] = &__traits(getMember, this, memberName);
					} else static if (__traits(compiles, (__traits(getMember, this, memberName))(a, b))) {
						static if (!is(typeof(&__traits(getMember, this, memberName)) == var*)) {
							obj[memberName]._function = &__traits(getMember, this, memberName);
						}
					}
				}
			}
		}

		return obj;
	}
}
