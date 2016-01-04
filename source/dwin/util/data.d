module dwin.util.data;

static size_t EnumCount(T)() {
	import std.traits : EnumMembers;

	size_t len = 0;
	foreach (x; EnumMembers!T)
		len++;
	return len;
}
