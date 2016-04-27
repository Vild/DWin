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

	T clear() {
		oldData = data;
		return data;
	}

	@property bool changed() {
		return oldData != data;
	}

private:
	T oldData;
}
