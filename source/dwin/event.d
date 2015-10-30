module dwin.event;

struct Event(Args...) {
public:
	/// Adds a callback $(PARAM cb)
	void opOpAssign(string op : "~")(cbFunction cb) {
		Add(cb);
	}

	/// Adds a callback $(PARAM cb)
	void opOpAssign(string op : "+")(cbFunction cb) {
		Add(cb);
	}

	/// Adds a callback $(PARAM cb)
	void Add(cbFunction cb) {
		callbacks ~= cb;
	}

	/// Removes a callback $(PARAM cb)
	void opOpAssign(string op : "-")(cbFunction cb) {
		remove(cb);
	}

	/// Removes a callback $(PARAM cb)
	void Remove(cbFunction cb) {
		import std.algorithm.mutation : remove, SwapStrategy;
		callbacks = callbacks.remove!(a => a == cb, SwapStrategy.unstable);
	}

	/// Calls every functions with the arguments $(PARAM args)
	void opCall(Args args) {
		foreach(fn; callbacks)
			fn(args);
	}
private:
	alias cbFunction = void delegate(Args);
	cbFunction[] callbacks;
}
