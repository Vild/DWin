module dwin.backend.container;

import dwin.backend.layout;
import dwin.backend.window;

abstract class Container {
public:
	abstract void Add(Container container);
	abstract void Remove(Container container);
	abstract void Move(short x, short y);
	abstract void Resize(ushort width, ushort height);

	@property ref Layout Parent() {
		return parent;
	}

protected:
	Layout parent;
}
