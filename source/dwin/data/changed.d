module dwin.data.changed;

struct Changed(T) {
public:
	T data;
	this(T data) {
		this.data = data;
	}

	ref T opAssign(T newData) {
		oldData = data;
		data = newData;
		return data;
	}

	ref T opAssign(Changed!T newData) {
		oldData = data;
		data = newData.data;
		return data;
	}

	ref T opCast(X)() if (is(typeof(X) == typeof(T))) {
		return data;
	}

	X opCast(X)() {
		return cast(X)data;
	}

	ref T opDot() {
		return data;
	}

	template opDispatch() {
		enum opDispatch = mixin("data." ~ s);
	}

	template opUnary() {
		enum opUnary = mixin(s ~ "data");
	}

	int opCmp(X)(auto ref const X b) if (is(T : X) || is(typeof(a.opCmp(b))) || is(typeof(b.opCmp(a)))) {
		alias data a;
		static if (is(typeof(a.opCmp(b))))
			return a.opCmp(b);
		else static if (is(typeof(b.opCmp(a))))
			return -b.opCmp(a);
		else
			return a < b ? -1 : a > b ? +1 : 0;
	}

	bool opEquals(X)(X b) if (is(T : X) || is(typeof(a.opEquals(b))) || is(typeof(b.opEquals(a)))) {
		alias data a;
		static if (is(typeof(a.opEquals(b))))
			return a.opEquals(b);
		else static if (is(typeof(b.opEquals(a))))
			return b.opEquals(a);
		else
			return a == b;
	}

	T clear() {
		oldData = data;
		return data;
	}

	@property bool changed() {
		return oldData != data;
	}

	string toString() const {
		import std.conv : to;

		return to!string(data);
	}

private:
	T oldData;
}
