import common;

/* TODO: Handle quoted string */
Field[] parseConfig(string configPath)
{
	import std.file : read;
	import std.string : splitLines, strip, indexOf;

	auto content = cast(string) read(configPath);
	Field[] fields;

	foreach (line; content.splitLines())
	{
		auto trimmed = line.strip();

		/* Empty line or comment */
		if (trimmed.length == 0 || trimmed[0] == Config.comment)
			continue;

		/* Find separator */
		auto idx = trimmed.indexOf(Config.separator);
		if (idx == -1)
			continue;

		/* Partition */
		auto key = trimmed[0 .. idx].strip();
		auto val = trimmed[idx + 1 .. $].strip();

		/* Strip trailing comment */
		auto commentIdx = val.indexOf(Config.comment);
		if (commentIdx != -1)
			val = val[0 .. commentIdx].strip();

		/* Ensure key and val are not empty */
		if (key.length == 0 || val.length == 0)
			continue;

		fields ~= Field(key, val);
	}

	return fields;
}
