module dwin.log;

import std.stdio : stdout, stderr;
import std.conv : toTextRange;
import std.stdio : File;
import std.string : format;
import std.traits : fullyQualifiedName;

enum LogLevel {
	VERBOSE,
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	FATAL
}

class Log {
public:
	static Log MainLogger() nothrow {
		if (mainLogger is null) {
			mainLogger = new Log();
			mainLogger.AttachHandler(&TerminalHandler);
			mainLogger.AttachHandler(&FileLog);
		}
		return mainLogger;
	}

	alias LogHandlerFunc = void function(LogLevel level, string module_, lazy string message) nothrow;

	void AttachHandler(LogHandlerFunc handler) nothrow {
		handlers ~= handler;
	}

	void opCall(S...)(LogLevel level, string module_, lazy string format_, lazy S args) nothrow {
		foreach (LogHandlerFunc handler; handlers)
			handler(level, module_, formatMessage(format_, args));
	}

	void Verbose(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		Log(LogLevel.VERBOSE, /*getName!*/ this_, format, args);
	}

	void Debug(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		Log(LogLevel.DEBUG, /*getName!*/ this_, format, args);
	}

	void Info(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		Log(LogLevel.INFO, /*getName!*/ this_, format, args);
	}

	void Warning(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		Log(LogLevel.WARNING, /*getName!*/ this_, format, args);
	}

	void Error(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		Log(LogLevel.ERROR, /*getName!*/ this_, format, args);
	}

	void Fatal(string this_ = __FUNCTION__, S...)(lazy string format, lazy S args) nothrow {
		import std.c.stdlib : exit;

		Log(LogLevel.FATAL, /*getName!*/ this_, format, args);
		exit(-1);
	}

	@property ref File LogFile() {
		return Log.logFile;
	}

private:
	static Log mainLogger = null;
	static File logFile;
	LogHandlerFunc[] handlers;

	template getName(alias this_) {
		import std.string : startsWith, endsWith;

		enum _ = fullyQualifiedName!this_;
		static if (_.endsWith("__ctor"))
			enum getName = _[0 .. $ - "__ctor".length] ~ "this" ~ fill!(80 - _.length + 2);
		else static if (_.endsWith("__dtor"))
			enum getName = _[0 .. $ - "__dtor".length] ~ "~this" ~ fill!(80 - _.length + 2);
		else
			enum getName = fullyQualifiedName!this_ ~ fill!(80 - _.length);

	}

	static string fill(int n)() {
		import std.range : repeat, take;
		import std.conv : to;

		static if (n < 0)
			return "";
		return to!string(take(repeat(' '), n));
	}

	string formatMessage(S...)(lazy string format_, lazy S args) {
		string message = format_;
		static if (args.length > 0)
			message = format(format_, args);
		return message;
	}

	version (Posix) {
		enum  {
			COLOR_OFF = "\x1b[0m", /// reset color

			// Regular Colors
			FG_BLACK = "\x1b[0;30m", ///
			FG_RED = "\x1b[0;31m", ///
			FG_GREEN = "\x1b[0;32m", ///
			FG_YELLOW = "\x1b[0;33m", ///
			FG_BLUE = "\x1b[0;34m", ///
			FG_PURPLE = "\x1b[0;35m", ///
			FG_CYAN = "\x1b[0;36m", ///
			FG_WHITE = "\x1b[0;37m", ///

			// Bold
			FG_B_BLACK = "\x1b[1;30m", ///
			FG_B_RED = "\x1b[1;31m", ///
			FG_B_GREEN = "\x1b[1;32m", ///
			FG_B_YELLOW = "\x1b[1;33m", ///
			FG_B_BLUE = "\x1b[1;34m", ///
			FG_B_PURPLE = "\x1b[1;35m", ///
			FG_B_CYAN = "\x1b[1;36m", ///
			FG_B_WHITE = "\x1b[1;37m", ///

			// Underline
			FG_U_BLACK = "\x1b[4;30m", ///
			FG_U_RED = "\x1b[4;31m", ///
			FG_U_GREEN = "\x1b[4;32m", ///
			FG_U_YELLOW = "\x1b[4;33m", ///
			FG_U_BLUE = "\x1b[4;34m", ///
			FG_U_PURPLE = "\x1b[4;35m", ///
			FG_U_CYAN = "\x1b[4;36m", ///
			FG_U_WHITE = "\x1b[4;37m", ///

			// Background
			BG_BLACK = "\x1b[40m", ///
			BG_RED = "\x1b[41m", ///
			BG_GREEN = "\x1b[42m", ///
			BG_YELLOW = "\x1b[43m", ///
			BG_BLUE = "\x1b[44m", ///
			BG_PURPLE = "\x1b[45m", ///
			BG_CYAN = "\x1b[46m", ///
			BG_WHITE = "\x1b[47m", ///

			// High Intensity
			FG_I_BLACK = "\x1b[0;90m", ///
			FG_I_RED = "\x1b[0;91m", ///
			FG_I_GREEN = "\x1b[0;92m", ///
			FG_I_YELLOW = "\x1b[0;93m", ///
			FG_I_BLUE = "\x1b[0;94m", ///
			FG_I_PURPLE = "\x1b[0;95m", ///
			FG_I_CYAN = "\x1b[0;96m", ///
			FG_I_WHITE = "\x1b[0;97m", ///

			// Bold High Intensity
			FG_BI_BLACK = "\x1b[1;90m", ///
			FG_BI_RED = "\x1b[1;91m", ///
			FG_BI_GREEN = "\x1b[1;92m", ///
			FG_BI_YELLOW = "\x1b[1;93m", ///
			FG_BI_BLUE = "\x1b[1;94m", ///
			FG_BI_PURPLE = "\x1b[1;95m", ///
			FG_BI_CYAN = "\x1b[1;96m", ///
			FG_BI_WHITE = "\x1b[1;97m", ///

			// High Intensity backgrounds
			BG_I_BLACK = "\x1b[0;100m", ///
			BG_I_RED = "\x1b[0;101m", ///
			BG_I_GREEN = "\x1b[0;102m", ///
			BG_I_YELLOW = "\x1b[0;103m", ///
			BG_I_BLUE = "\x1b[0;104m", ///
			BG_I_PURPLE = "\x1b[0;105m", ///
			BG_I_CYAN = "\x1b[0;106m", ///
			BG_I_WHITE = "\x1b[0;107m", ///
		}

		static void TerminalHandler(LogLevel level, string module_, lazy string message) nothrow {
			string icon;
			string color;

			final switch (level) {
			case LogLevel.VERBOSE:
				icon = "&";
				color = FG_GREEN;
				break;
			case LogLevel.DEBUG:
				icon = "+";
				color = FG_YELLOW;
				break;
			case LogLevel.INFO:
				icon = "*";
				color = FG_CYAN;
				break;
			case LogLevel.WARNING:
				icon = "#";
				color = FG_PURPLE;
				break;
			case LogLevel.ERROR:
				icon = "-";
				color = FG_RED;
				break;
			case LogLevel.FATAL:
				icon = "!";
				color = FG_BLACK ~ BG_RED;
				break;
			}
			try {
				string levelText = format("[%1$s%3$s%2$s] [%1$s%4$s%2$s] %1$s%5$s%2$s", color, COLOR_OFF, icon, module_, message);

				if (level >= LogLevel.WARNING) {
					stderr.writeln(levelText);
					stderr.flush;
				} else {
					stdout.writeln(levelText);
					stdout.flush;
				}
			}
			catch (Exception) {
				import std.c.stdlib : exit;

				exit(-2);
			}
		}
	} else {
		static void TerminalHandler(LogLevel level, string module_, lazy string message) nothrow {
			return StdTerminalHandler(level, module_, message);
		}
	}

	static void StdTerminalHandler(LogLevel level, string module_, lazy string message) nothrow {
		string icon;

		final switch (level) {
		case LogLevel.VERBOSE:
			icon = "&";
			break;
		case LogLevel.DEBUG:
			icon = "+";
			break;
		case LogLevel.INFO:
			icon = "*";
			break;
		case LogLevel.WARNING:
			icon = "#";
			break;
		case LogLevel.ERROR:
			icon = "-";
			break;
		case LogLevel.FATAL:
			icon = "!";
			break;
		}
		try {
			string levelText = format("[%c] [%s]\t %s", icon, module_, message);

			if (level >= LogLevel.WARNING) {
				stderr.writeln(levelText);
				stderr.flush;
			} else {
				stdout.writeln(levelText);
				stdout.flush;
			}
		}
		catch (Exception) {
			import std.c.stdlib : exit;

			exit(-2);
		}
	}

	static void FileLog(LogLevel level, string module_, lazy string message) nothrow {
		import std.string;
		import std.datetime;

		if (!Log.logFile.isOpen)
			return;
		string icon;

		final switch (level) {
		case LogLevel.VERBOSE:
			icon = "&";
			break;
		case LogLevel.DEBUG:
			icon = "+";
			break;
		case LogLevel.INFO:
			icon = "*";
			break;
		case LogLevel.WARNING:
			icon = "#";
			break;
		case LogLevel.ERROR:
			icon = "-";
			break;
		case LogLevel.FATAL:
			icon = "!";
			break;
		}
		try {
			SysTime t = Clock.currTime;

			auto dateTime = DateTime(Date(t.year, t.month, t.day), TimeOfDay(t.hour, t.minute, t.second));

			string time = dateTime.toSimpleString;

			string levelText = format("[%c] [%s] [%s]\t %s", icon, module_, time, message);

			logFile.writeln(levelText);
			logFile.flush();
		}
		catch (Exception) {
			import std.c.stdlib : exit;

			exit(-2);
		}
	}

}
