module dwin.layout.floatinglayout;

import dwin.backend.container;
import dwin.backend.layout;

class FloatingLayout : Layout {
public:
	override void Add(Container container) {
		super.Add(container);
	}

	override void Remove(Container container) {
		super.Remove(container);
	}

	override void Move(short x, short y) {
		super.Move(x, y);
	}

	override void Resize(ushort width, ushort height) {
		super.Resize(width, height);
	}
}
