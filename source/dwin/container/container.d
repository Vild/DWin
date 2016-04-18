module dwin.container.container;

import dwin.data.geometry;
import dwin.data.borderstyle;

abstract class Container {
public:
	this(string name, Geometry geom, Container parent, BorderStyle borderStyle, double splitRatio) {
		this.name = name;
		this.geom = geom;
		this.parent = parent;
		this.borderStyle = borderStyle;
		this.splitRatio = splitRatio;
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

	@property bool DirtyGeometry() {
		return geom != oldGeom;
	}

	@property abstract void Update() {
		oldGeom = geom;
	}

protected:
	string name;
	Geometry geom;
	Container parent;
	BorderStyle borderStyle;
	double splitRatio;
private:
	Geometry oldGeom;
}
