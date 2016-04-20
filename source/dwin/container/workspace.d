module dwin.container.workspace;

import dwin.container.container;
import dwin.data.geometry;
import dwin.data.borderstyle;
import dwin.container.splitcontainer;
import dwin.container.window;

final class Workspace : Container {
public:
	this(string name, Geometry geom, Container parent, double splitRatio) {
		super(name, geom, parent, BorderStyle(), splitRatio);
	}

	override void Update() {
		// focused and fullscreen will already exist in the "root" container
		root.Update();
		foreach (Window w; floating)
			w.Update();
	}

	@property ref Container Focused() {
		return focused;
	}

	@property ref Container Fullscreen() {
		return fullscreen;
	}

	@property ref SplitContainer Root() {
		return root;
	}

	@property ref Window[] Floating() {
		return floating;
	}

private:
	Container focused;
	Container fullscreen;
	SplitContainer root;
	Window[] floating;
}
