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

	/*var GetScreens(var, var[]) {
		var screenArray = var.emptyArray;
		var screen0 = var.emptyObject;
		screen0.Name = "DUMMY0";

		var screen0Workspace = var.emptyObject;
		screen0Workspace.Name = "Derp";
		var screen0Layout = var.emptyObject;
		screen0Layout["Type"] = "DummyLayout";
		screen0Layout.IsVisible = true;
		screen0Layout.Containers = var.emptyArray;

		var container0 = var.emptyObject;
		container0.IsWindow = true;
		container0["Title"] = "DummyTitle";
		container0.IsVisible = true;
		screen0Layout.Containers[0] = container0;

		screen0Workspace.Root = screen0Layout;

		screen0.OnTop = screen0Layout;
		screen0.Workspaces = var.emptyArray;
		screen0.Workspaces[0] = screen0Workspace;

		screenArray[0] = screen0;
		return screenArray;
	}*/

	var GetScreens(var, var[]) {
		var screens = var.emptyArray;
		foreach (screen; engine.Screens)
			screens ~= createVar(screen);
		return screens;
	}

	mixin ObjectWrapper;
	Engine engine;

private:
	var createVar(Screen screen) {
		var scr = var.emptyObject;
		scr.Name = screen.Name;
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
		return work;
	}

	var createVar(Container con) {
		if (auto win = cast(Window)con)
			return createVar(win);
		else if (auto layout = cast(Layout)con)
			return createVar(layout);
		assert(0);
	}

	var createVar(Layout layout) {
		var l = var.emptyObject;
		l.IsWindow = false;
		l["Type"] = typeid(layout).name;
		l.IsVisible = layout.IsVisible;
		l.Containers = var.emptyArray;
		foreach (container; layout.Containers)
			l.Containers ~= createVar(container);
		return l;
	}

	var createVar(Window window) {
		var win = var.emptyObject;
		win.IsWindow = true;
		win.Title = window.Title;
		win.IsVisible = window.IsVisible;
		return win;
	}
}
