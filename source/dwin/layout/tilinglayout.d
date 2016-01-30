module dwin.layout.tilinglayout;

import dwin.backend.container;
import dwin.backend.mouse;
import dwin.backend.layout;
import dwin.log;
import dwin.util.data;
import std.math;

class TilingLayout : Layout {
	enum Direction {
		Horizontal,
		Vertical
	}

	this(Direction direction = Direction.Horizontal) {
		this.direction = direction;
	}

	override void Add(Container container) {
		super.Add(container);
		rebalance();
	}

	override void Remove(Container container) {
		super.Remove(container);
		rebalance();
	}

	override void RequestShow(Container container) {
		container.Show();
		rebalance();
	}

	override void NotifyHide(Container container) {
		if (IsVisible)
			container.Hide();
		rebalance();
	}

	override void Show(bool eventBased = true) {
		super.Show(eventBased);
		balanceLock = false;
		rebalance();
	}

	override void Hide(bool eventBased = true) {
		balanceLock = true;
		super.Hide(eventBased);
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
		mouse.Style = MouseStyles.Moving;
	}

	override void MouseResizePressed(Container target, Mouse mouse) {
		if (state != HandlingState.None)
			return;

		state = HandlingState.Resize;
		this.target = target;
		target.Update();
		mouse.Style = MouseStyles.Resizing;
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
	}

private:
	enum HandlingState {
		None,
		Move,
		Resize
	}

	Direction direction;
	HandlingState state;
	Container target;

	bool balanceLock;

	void rebalance() {
		if (balanceLock)
			return;

		ulong len;

		foreach (con; containers)
			if (con.IsVisible)
				len++;
		if (!len)
			return;
		vec2 pos = vec2(x, y);
		vec2 size = vec2(width, height);

		if (direction == Direction.Horizontal)
			size.x /= len;
		else
			size.y /= len;

		foreach (ref container; containers) {
			if (!container.IsVisible)
				continue;
			Log.MainLogger.Info("Moved to XY: %s, WH: %s", pos, size);
			container.MoveResize(cast(short)pos.x, cast(short)pos.y, cast(ushort)size.x, cast(ushort)size.y);
			if (direction == Direction.Horizontal)
				pos.x += size.x;
			else
				pos.y += size.y;
		}

	}
}
