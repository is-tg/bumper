import common;

/* TODO: Handle quoted string */
Field[] parseConfig(string configPath)
{
	import std.file : read;
	import std.string : splitLines, strip, indexOf;

	auto content = cast(string) configPath.read;
	Field[] fields;

	foreach (line; content.splitLines())
	{
		auto trimmed = line.strip();

		if (trimmed.length == 0 || trimmed[0] == Config.comment)
			continue;

		auto idx = trimmed.indexOf(Config.separator);
		if (idx == -1)
			continue;

		auto key = trimmed[0 .. idx].strip();
		auto val = trimmed[idx + 1 .. $].strip();

		/* Strip trailing comment */
		auto commentIdx = val.indexOf(Config.comment);
		if (commentIdx != -1)
			val = val[0 .. commentIdx].strip();

		fields ~= Field(key, val);
	}

	return fields;
}
