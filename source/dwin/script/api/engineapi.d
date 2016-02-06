module dwin.script.api.engineapi;

import dwin.backend.engine;
import dwin.script.utils;

import dwin.backend.container;
import dwin.backend.layout;
import dwin.backend.screen;
import dwin.backend.window;
import dwin.backend.workspace;

struct EngineAPI {

	void Init(Engine engine) {
		this.engine = engine;
	}

	var GetScreens(var, var[]) {
		var screens = var.emptyArray;
		foreach (screen; engine.Screens)
			screens ~= createVar(screen);
		return screens;
	}

	var RegisterTick(var, var[] args) {
		engine.RegisterTick(() => cast(void)args[0]());
		return var.emptyObject;
	}

	mixin ObjectWrapper;
	Engine engine;

private:
	var createVar(Screen screen) {
		var scr = var.emptyObject;
		scr.Name = screen.Name;
		scr.CurrentWorkspace = screen.CurrentWorkspace;
		scr.OnTop = createVar(screen.OnTop);
		scr.Workspaces = var.emptyArray;
		foreach (workspace; screen.Workspaces)
			scr.Workspaces ~= createVar(workspace);
		return scr;
	}

	var createVar(Workspace workspace) {
		var work = var.emptyObject;
		work.Name = workspace.Name;
		work.OnTop = createVar(workspace.OnTop);
		work.Root = createVar(workspace.Root);
		work.ActiveWindow = createVar(workspace.ActiveWindow);
		return work;
	}

	var createVar(Container con) {
		if (auto win = cast(Window)con)
			return createVar(win);
		else if (auto layout = cast(Layout)con)
			return createVar(layout);
		return var(null);
	}

	var createVar(Layout layout) {
		var l = var.emptyObject;
		l.IsWindow = false;
		l["ToString"] = layout.toString();
		l.IsVisible = layout.IsVisible;
		l.Containers = var.emptyArray;
		foreach (container; layout.Containers)
			l.Containers ~= createVar(container);
		return l;
	}

	var createVar(Window window) {
		if (!window)
			return var.emptyObject;
		var win = var.emptyObject;
		win.IsWindow = true;
		win.Title = window.Title();
		win["ToString"] = window.toString();
		win.IsVisible = window.IsVisible;
		return win;
	}
}
