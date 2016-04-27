module dwin.script.api.engineapi;

import dwin.backend.engine;
import dwin.script.utils;

import dwin.container.container;
import dwin.container.root;
import dwin.container.screen;
import dwin.container.splitcontainer;
import dwin.container.window;
import dwin.container.workspace;

struct EngineAPI {
	void Init(Engine engine) {
		this.engine = engine;
	}

	var GetRoot(var, var[]) {
		Root rootCon = engine.RootContainer;
		var root = _genericVar(rootCon);
		
		root.Screens = var.emptyArray;
		foreach (scr; rootCon.Screens)
			root.Screens ~= createVar(scr);
		
		root.StickyWindows = var.emptyArray;
		foreach (window; rootCon.StickyWindows)
			root.StickyWindows ~= createVar(window);
		return root;
	}
	
	var Quit(var, var[] args) {
		engine.Quit = true;
		return var.emptyObject;
	}

	var RegisterTick(var, var[] args) {
		engine.RegisterTick(() => cast(void)args[0]());
		return var.emptyObject;
	}

	mixin ObjectWrapper;
	Engine engine;

private:
	var _genericVar(Container container) {
		var con = var.emptyObject;
		con.Name = container.Name;
 		con.Geom = var.emptyObject;
		con.Geom.X = container.Geom.x;		
		con.Geom.Y = container.Geom.y;
		con.Geom.Width = container.Geom.width;		
		con.Geom.Height = container.Geom.height;
		con.SplitRatio = container.SplitRatio;
		return con;
	}
	
	var createVar(Screen screen) {
		var scr = _genericVar(screen);
		scr.ActiveWorkspace = screen.ActiveWorkspace;
		scr.Top = createVar(screen.Top);
		scr.Bottom = createVar(screen.Bottom);
		scr.Left = createVar(screen.Left);
		scr.Right = createVar(screen.Right);
		
		scr.Workspaces = var.emptyArray;
		foreach (workspace; screen.Workspaces)
			scr.Workspaces ~= createVar(workspace);
		return scr;
	}

	var createVar(Workspace workspace) {
		var work = _genericVar(workspace);
		work.Focused = createVar(workspace.Focused);
		work.Fullscreen = workspace.Fullscreen;
		work.Root = createVar(workspace.Root);
		
		work.Floating = var.emptyArray;
		foreach (window; workspace.Floating)
			work.Floating ~= createVar(window);
		return work;
	}

	var createVar(Container con) {
		if (auto win = cast(Window)con)
			return createVar(win);
		else if (auto split = cast(SplitContainer)con)
			return createVar(split);
		return var(null);
	}

	var createVar(SplitContainer splitContainer) {
		var split = _genericVar(splitContainer);
		
		split.Containers = var.emptyArray;
		foreach (con; splitContainer.Containers)
			split.Containers ~= createVar(con);

		split.SplitLayout = splitContainer.SplitLayout;
		return split;
	}

	var createVar(Window window) {
		var win = _genericVar(window);
		win.Visible = window.Visible;
		return win;
	}
}
