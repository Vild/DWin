module dwin.layout.tilinglayout;

import dwin.backend.engine;
import dwin.backend.container;
import dwin.backend.mouse;
import dwin.backend.layout;
import dwin.log;
import dwin.util.data;
import std.math;

class TilingLayout : Layout {
	this(Engine engine, bool isHorizontal = true, Container left = null, Container right = null) {
		super(engine);
		this.isHorizontal = isHorizontal;

		visible = left || right;
		leftSizeRatio = 0.5;

		if (left)
			Add(left);
		if (right)
			Add(right);
		Refresh();
	}

	override void Add(Container container) {
		container.Parent = this;
		if (!container.IsVisible)
			return;

		if (!left) {
			left = container;
			left.Parent = this;
		} else if (!right) {
			right = container;
			right.Parent = this;
		} else {
			if (auto layout = cast(TilingLayout)right) {
				layout.Add(container);
				return;
			} else {
				right = new TilingLayout(engine, !isHorizontal, right, container);
				right.Parent = this;
			}
		}

		Refresh();
	}

	override void Remove(Container container) {
		// Check if left or right is the container
		if (left == container) {
			left = right;
			right = null;
		} else if (right == container) {
			right = null;
		}  // else check if left and/or right is a TilingLayout and query them
		else {
			if (auto layout = cast(TilingLayout)left)
				layout.Remove(container);

			if (auto layout = cast(TilingLayout)right)
				layout.Remove(container);
		}
		Refresh();
	}

	override void RequestShow(Container container) {
		container.Show();
		if (!left) {
			left = container;
			left.Parent = this;
		} else if (!right) {
			right = container;
			right.Parent = this;
		} else {
			if (auto layout = cast(TilingLayout)right) {
				layout.Add(container);
				return;
			} else {
				right = new TilingLayout(engine, !isHorizontal, right, container);
				right.Parent = this;
			}
		}

		Refresh();
	}

	override void NotifyHide(Container container) {
		if (IsVisible)
			container.Hide();
		if (container.IsVisible) {
			// Check if left or right is the container
			if (left == container) {
				left = right;
				right = null;
			} else if (right == container) {
				right = null;
			}  // else check if left and/or right is a TilingLayout and query them
			else {
				killOff();
				if (auto layout = cast(TilingLayout)left) {
					layout.Remove(container);
					killOff();
					return;
				}
				if (auto layout = cast(TilingLayout)right) {
					layout.Remove(container);
					killOff();
					return;
				}
			}
			Refresh();
		}
	}

	override void Show(bool eventBased = true) {
		super.Show(eventBased);
	}

	override void Hide(bool eventBased = true) {
		super.Hide(eventBased);
	}

	override void Move(short x, short y) {
		super.Move(x, y);
		Refresh();
	}

	override void Resize(ushort width, ushort height) {
		super.Resize(width, height);
		Refresh();
	}

	override void MoveResize(short x, short y, ushort width, ushort height) {
		super.MoveResize(x, y, width, height);
		Refresh();
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

		pointerDiff = vec2(0);
		gridPos = target.GetGridPosition(mouse.X - target.X, mouse.Y - target.Y);

		if (gridPos.x == PositionPart.First)
			pointerDiff.x = target.X - mouse.X;
		else if (gridPos.x == PositionPart.Third)
			pointerDiff.x = target.X + target.Width - mouse.X;

		if (gridPos.y == PositionPart.First)
			pointerDiff.y = target.Y - mouse.Y;
		else if (gridPos.y == PositionPart.Third)
			pointerDiff.y = target.Y + target.Height - mouse.Y;
	}

	override void MouseMoveReleased(Container target, Mouse mouse) {
		if (state != HandlingState.Move)
			return;

		state = HandlingState.None;
		this.target = null;
		mouse.Style = MouseStyles.Normal;
	}

	override void MouseResizeReleased(Container target, Mouse mouse) {
		if (state != HandlingState.Resize)
			return;

		MouseMotion(target, mouse); //Update it a last time!

		state = HandlingState.None;
		this.target = null;
		mouse.Style = MouseStyles.Normal;
	}

	override void MouseMotion(Container target, Mouse mouse) {
		if (!target)
			return;

		if (state == HandlingState.Move)
			move(target, mouse);
		else if (state == HandlingState.Resize)
			resize(target, mouse);
	}

	Container PullContainer() {
		return left;
	}

	bool ShouldDie() {
		killOff();
		return !right;
	}

	void Swap() {
		Container tmp = left;
		left = right;
		right = tmp;

		Refresh();
	}

	void Refresh() {
		killOff();

		//XXX: To fix that sometimes left/right.Parent is sometimes wrong
		if (left)
			left.Parent = this;
		if (right)
			right.Parent = this;

		if (left && right) {
			if (isHorizontal) {
				const ushort leftWidth = cast(ushort)(width * leftSizeRatio);
				const ushort rightWidth = cast(ushort)(width - leftWidth);

				left.MoveResize(X, Y, leftWidth, height);
				right.MoveResize(cast(short)(X + leftWidth), Y, rightWidth, height);
			} else {
				const ushort leftHeight = cast(ushort)(height * leftSizeRatio);
				const ushort rightHeight = cast(ushort)(height - leftHeight);
				left.MoveResize(X, Y, width, leftHeight);
				right.MoveResize(X, cast(short)(Y + leftHeight), width, rightHeight);
			}
		} else if (left)
			left.MoveResize(X, Y, Width, Height);
	}

	@property override Container[] Containers() {
		if (left && right)
			return [left, right];
		else if (left)
			return [left];
		else
			return [];
	}

	@property double LeftSizeRatio() {
		return leftSizeRatio;
	}

	@property double LeftSizeRatio(double leftSizeRatio) {
		const double maxSize = (isHorizontal) ? width : height;
		const double minSizeRatio = 32 / (maxSize * 1.0);

		if (leftSizeRatio < minSizeRatio)
			leftSizeRatio = minSizeRatio;
		else if (leftSizeRatio > 1 - minSizeRatio)
			leftSizeRatio = 1 - minSizeRatio;

		if (cast(ushort)(this.leftSizeRatio * maxSize) != cast(ushort)(leftSizeRatio * maxSize)) {
			this.leftSizeRatio = leftSizeRatio;
			Refresh();
		}

		return leftSizeRatio;
	}

	@property ref Container Left() {
		return left;
	}

	@property ref Container Right() {
		return right;
	}

	override string toString() {
		import std.format : format;

		return format("%s %s: %s", cast(void*)this, typeid(this).name, isHorizontal ? "Horizontal" : "Vertical");
	}

private:
	enum HandlingState {
		None,
		Move,
		Resize
	}

	bool isHorizontal;
	Container left;
	Container right;
	double leftSizeRatio;

	HandlingState state;
	Container target;
	vec2 pointerDiff;

	GridPosition gridPos;

	void killOff() {
		while (right) {
			auto layout = cast(TilingLayout)right;
			if (!layout || !layout.ShouldDie())
				break;

			right = layout.PullContainer();
			if (right) {
				right.Parent = this;
			}
			layout.destroy;
		}

		while (left) {
			auto layout = cast(TilingLayout)left;
			if (!layout || !layout.ShouldDie())
				break;

			left = layout.PullContainer();
			if (left) {
				left.Parent = this;
			}
			layout.destroy;
		}

		if (!left) {
			left = right;
			right = null;
		}
	}

	void move(Container target, Mouse mouse) {
		Container atMouse = engine.FindWindow(mouse.X, mouse.Y);
		if (atMouse && atMouse != this.target) {
			if (auto layout = cast(TilingLayout)atMouse.Parent) {
				Container* loc1;
				if (this.target == left)
					loc1 = &left;
				else if (this.target == right)
					loc1 = &right;
				else
					assert(0);

				Container* loc2;
				if (atMouse == layout.Left)
					loc2 = &layout.Left();
				else if (atMouse == layout.Right)
					loc2 = &layout.Right();
				else
					assert(0);

				Container tmp = *loc1;
				*loc1 = *loc2;
				*loc2 = tmp;

				loc1.Parent = this;
				loc2.Parent = layout;

				Refresh();
				layout.Refresh();
				MouseMoveReleased(target, mouse);
				layout.MouseMovePressed(target, mouse);
			}
		}
	}

	void resize(Container target, Mouse mouse) {
		TilingLayout parent = cast(TilingLayout)Parent;
		TilingLayout grandParent = parent ? cast(TilingLayout)parent.Parent : null;

		if (isHorizontal) {
			if (gridPos.x == PositionPart.First) {
				if (target == left) {
					if (grandParent && grandParent.Containers[1] == parent)
						grandParent.LeftSizeRatio = ((mouse.X + pointerDiff.x - grandParent.X) / (grandParent.Width * 1.0));
				} else
					LeftSizeRatio = ((mouse.X + pointerDiff.x - X) / (Width * 1.0));
			} else if (gridPos.x == PositionPart.Third) {
				if (target == left)
					LeftSizeRatio = ((mouse.X + pointerDiff.x - X) / (Width * 1.0));
				else {
					if (grandParent && grandParent.Containers[0] == parent)
						grandParent.LeftSizeRatio = ((mouse.X + pointerDiff.x - grandParent.X) / (grandParent.Width * 1.0));
				}
			}

			if (parent)
				if ((gridPos.y == PositionPart.First && parent.Containers[1] == this)
						|| (gridPos.y == PositionPart.Third && parent.Containers[0] == this))
					parent.LeftSizeRatio = (mouse.Y + pointerDiff.y - parent.Y) / (Parent.Height * 1.0);
		} else {
			if (gridPos.y == PositionPart.First) {
				if (target == left) {
					if (grandParent && grandParent.Containers[1] == parent)
						grandParent.LeftSizeRatio = ((mouse.Y + pointerDiff.y - grandParent.Y) / (grandParent.Height * 1.0));
				} else
					LeftSizeRatio = ((mouse.Y + pointerDiff.y - Y) / (Height * 1.0));
			} else if (gridPos.y == PositionPart.Third) {
				if (target == left)
					LeftSizeRatio = ((mouse.Y + pointerDiff.y - Y) / (Height * 1.0));
				else {
					if (grandParent && grandParent.Containers[0] == parent)
						grandParent.LeftSizeRatio = ((mouse.Y + pointerDiff.y - grandParent.Y) / (grandParent.Height * 1.0));
				}
			}

			if (parent)
				if ((gridPos.x == PositionPart.First && parent.Containers[1] == this)
						|| (gridPos.x == PositionPart.Third && parent.Containers[0] == this))
					parent.LeftSizeRatio = (mouse.X + pointerDiff.x - parent.X) / (Parent.Width * 1.0);
		}

	}
}
