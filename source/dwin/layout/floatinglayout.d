module dwin.layout.floatinglayout;

import dwin.backend.container;
import dwin.backend.mouse;
import dwin.backend.layout;
import dwin.log;
import dwin.util.data;
import std.math;

class FloatingLayout : Layout {
public:
	override void Add(Container container) {
		super.Add(container);
	}

	override void Remove(Container container) {
		super.Remove(container);
	}

	override void RequestShow(Container container) {
		container.Show();
	}

	override void NotifyHide(Container container) {
		container.Hide();
	}

	override void Move(short x, short y) {
		super.Move(x, y);
	}

	override void Resize(ushort width, ushort height) {
		super.Resize(width, height);
	}

	override void MoveResize(short x, short y, ushort width, ushort height) {
		super.MoveResize(x, y, width, height);
	}

	override void MouseMovePressed(Container target, Mouse mouse) {
		if (state != HandlingState.None)
			return;
		state = HandlingState.Move;
		this.target = target;
		target.Update();
		target.Focus();
		mouse.Style = MouseStyles.Moving;
		pointerDiff = vec2(mouse.X - target.X, mouse.Y - target.Y);
		oldGeom = Geometry(target.X, target.Y, target.Width, target.Height);
	}

	override void MouseResizePressed(Container target, Mouse mouse) {
		if (state != HandlingState.None)
			return;
		state = HandlingState.Resize;
		this.target = target;
		target.Update();
		target.Focus();
		mouse.Style = MouseStyles.Resizing;

		pointerDiff = vec2(mouse.X - (target.X + target.Width / 2), mouse.Y - (target.Y + target.Height / 2));
		oldGeom = Geometry(target.X, target.Y, target.Width, target.Height);

		/*
			---------------
			|1,1| 2,1 |3,1|
			|---|-----|---|
			|1,2| 2,2 |3,2|
			|---|-----|---|
			|1,3| 2,3 |3,3|
			---------------
		*/

		const int pointX = (mouse.X - target.X) / (target.Width / 4) + 1;
		const int pointY = (mouse.Y - target.Y) / (target.Height / 4) + 1;

		if (!!(pointX & 0b100))
			column = GridPos.Third;
		else if (!!(pointX & 0b10))
			column = GridPos.Second;
		else if (!!(pointX & 0b1))
			column = GridPos.First;

		if (!!(pointY & 0b100))
			row = GridPos.Third;
		else if (!!(pointY & 0b10))
			row = GridPos.Second;
		else if (!!(pointY & 0b1))
			row = GridPos.First;
	}

	override void MouseMoveReleased(Container target, Mouse mouse) {
		if (state != HandlingState.Move)
			return;
		state = HandlingState.None;
		target = null;
		mouse.Style = MouseStyles.Normal;
	}

	override void MouseResizeReleased(Container target, Mouse mouse) {
		if (state != HandlingState.Resize)
			return;

		MouseMotion(target, mouse); //Update it a last time!

		state = HandlingState.None;
		target = null;
		mouse.Style = MouseStyles.Normal;
	}

	override void MouseMotion(Container target, Mouse mouse) {
		if (!target)
			return;

		//TODO: (?) crazy hack with xcb_wait_for_event, to handle events faster

		if (state == HandlingState.Move)
			move(target, mouse);
		else if (state == HandlingState.Resize)
			resize(target, mouse);
	}

private:
	enum HandlingState {
		None,
		Move,
		Resize
	}

	enum GridPos {
		First,
		Second,
		Third
	}

	HandlingState state;
	Container target;
	vec2 pointerDiff;
	Geometry oldGeom;

	GridPos row;
	GridPos column;

	void move(Container target, Mouse mouse) {
		short x = cast(short)(mouse.X - pointerDiff.x);
		short y = cast(short)(mouse.Y - pointerDiff.y);

		target.Move(x, y);
	}

	void resize(Container target, Mouse mouse) {
		const int minSize = 32;
		int x = target.X;
		int y = target.Y;
		int w = target.Width;
		int h = target.Height;
		const int oldx = x;
		const int oldy = y;
		const int oldw = w;
		const int oldh = h;

		if (row == GridPos.First) {
			if (column == GridPos.First) {
				x = (mouse.X) - (pointerDiff.x + oldGeom.width / 2);
				w += oldx - x;
				if (w < minSize) {
					x -= (minSize - w);
					w += minSize - w;
				}

				y = (mouse.Y) - (pointerDiff.y + oldGeom.height / 2);
				h += oldy - y;
				if (h < minSize) {
					y -= (minSize - h);
					h += minSize - h;
				}
			} else if (column == GridPos.Second) {
				y = (mouse.Y) - (pointerDiff.y + oldGeom.height / 2);
				h += oldy - y;
				if (h < minSize) {
					y -= (minSize - h);
					h += minSize - h;
				}
			} else /*if (column == GridPos.Third) */ {
				w = (mouse.X - oldGeom.x) - (pointerDiff.x - oldGeom.width / 2);
				if (w < minSize)
					w += minSize - w;

				y = (mouse.Y) - (pointerDiff.y + oldGeom.height / 2);
				h += oldy - y;
				if (h < minSize) {
					y -= (minSize - h);
					h += minSize - h;
				}
			}
		} else if (row == GridPos.Second) {
			if (column == GridPos.First) {
				x = (mouse.X) - (pointerDiff.x + oldGeom.width / 2);
				w += oldx - x;
				if (w < minSize) {
					x -= (minSize - w);
					w += minSize - w;
				}

			} else if (column == GridPos.Second) {

			} else /*if (column == GridPos.Third) */ {
				w = (mouse.X - oldGeom.x) - (pointerDiff.x - oldGeom.width / 2);
				if (w < minSize)
					w += minSize - w;
			}
		} else /*if (row == GridPos.Third) */ {
			if (column == GridPos.First) {
				x = (mouse.X) - (pointerDiff.x + oldGeom.width / 2);
				w += oldx - x;
				if (w < minSize) {
					x -= (minSize - w);
					w += minSize - w;
				}

				h = (mouse.Y - oldGeom.y) - (pointerDiff.y - oldGeom.height / 2);
				if (h < minSize)
					h += minSize - h;
			} else if (column == GridPos.Second) {
				h = (mouse.Y - oldGeom.y) - (pointerDiff.y - oldGeom.height / 2);
				if (h < minSize)
					h += minSize - h;
			} else /*if (column == GridPos.Third) */ {
				w = (mouse.X - oldGeom.x) - (pointerDiff.x - oldGeom.width / 2);
				if (w < minSize)
					w += minSize - w;

				h = (mouse.Y - oldGeom.y) - (pointerDiff.y - oldGeom.height / 2);
				if (h < minSize)
					h += minSize - h;
			}
		}

		target.MoveResize(cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h);
	}
}
