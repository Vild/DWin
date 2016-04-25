module dwin.container.container;

import dwin.data.geometry;
import dwin.data.vec;
import dwin.data.borderstyle;
import dwin.data.changed;

abstract class Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio) {
		this.name = name;
		this.geom = geom;
		this.parent = parent;
		this.borderStyle = borderStyle;
		this.splitRatio = splitRatio;
	}

	abstract void Update() {
		geom.clear();
	}
	
	void Resize(Vec2 size) {
		geom.Size = size;
	}

	void Move(Vec2 pos) {
		geom.Position = pos;
	}

	@property ref string Name() {
		return name;
	}

	@property ref Geometry Geom() {
		return geom;
	}

	@property ref Container Parent() {
		return parent;
	}

	@property ref BorderStyle Border() {
		return borderStyle;
	}

	@property ref double SplitRatio() {
		return splitRatio;
	}

	@property bool Dirty() {
		return geom.changed;
	}
	
protected:
	string name;
	Changed!Geometry geom;
	Container parent;
	BorderStyle borderStyle;
	double splitRatio;
}
