module dwin.script.api.systemapi;

import dwin.script.utils;
import std.process;

struct SystemAPI {
	var GetDate(var, var[]) {
		import std.datetime : Clock, DateTime;

		auto time = cast(DateTime)Clock.currTime;
		return var(time.toString);
	}

	var SpawnProcess(var, var[] args) {
		auto arg0 = args[0];
		string[] spawnArgs;
		if (arg0.payloadType == var.Type.String)
			spawnArgs = parseArgs(cast(string)arg0);
		else
			foreach (arg; arg0)
				spawnArgs ~= cast(string)arg;

		spawnProcess(spawnArgs);

		return var.emptyObject;
	}

	var PipeProcess(var, var[] args) {
		auto id = cast(string)args[0];
		auto pArgs = args[1];
		string[] spawnArgs;
		if (pArgs.payloadType == var.Type.String)
			spawnArgs = parseArgs(cast(string)pArgs);
		else
			foreach (arg; pArgs)
				spawnArgs ~= cast(string)arg;

		processes[id] = pipeProcess(spawnArgs);
		return var.emptyObject;
	}

	var WritePipeProcess(var, var[] args) {
		if (ProcessPipes* pipes = (cast(string)args[0]) in processes) {
			pipes.stdin.writeln(cast(string)args[1]);
			pipes.stdin.flush();
		}

		return var.emptyObject;
	}

	var KillPipeProcess(var, var[] args) {
		if (ProcessPipes* pipes = (cast(string)args[0]) in processes) {
			kill(pipes.pid);
			processes.remove(cast(string)args[0]);
		}

		return var.emptyObject;
	}

	string[] parseArgs(string arg) {
		string[] args;
		string tmp;
		bool strip = false;
		char inQuote = '\0';
		foreach (char ch; arg) {
			if (strip) {
				tmp ~= ch;
				strip = false;
				continue;
			}

			if (ch == '\\' && !strip)
				strip = true;
			else {
				if (ch == '\"' && !strip && (inQuote == '\0' || inQuote == '\"'))
					inQuote = (inQuote == '\0') ? ch : '\0';
				else if (ch == '\'' && !strip && (inQuote == '\0' || inQuote == '\''))
					inQuote = (inQuote == '\0') ? ch : '\0';
				else if (ch == ' ' && !strip && inQuote == '\0') {
					args ~= tmp;
					tmp = "";
				} else
					tmp ~= ch;

				strip = false;
			}
		}
		if (tmp.length)
			args ~= tmp;
		return args;
	}

	ProcessPipes[string] processes;
	mixin ObjectWrapper;
}
