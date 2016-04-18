module dwin.backend.wayland.engine;

import dwin.backend.engine;
import dwin.log;

class WaylandEngine : Engine {
public:
	this(string scriptFolder) {
		super(scriptFolder);
	}

	~this() {
	}

	override void RunLoop() {
		Log.MainLogger.Fatal("WaylandEngine is currently not implement!");
	}

	override void HandleEvent() {
		assert(0);
	}

private:
}
