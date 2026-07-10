import std.stdio : writeln;
import std.json;

/* TODO: Error handling... */

struct Config
{
	@disable this();

	enum comment = '#';
	enum separator = ':';
	enum substitution = '`';

	enum source = "src.";
	enum hash = "sha256 ";
	enum size = "bytes ";
}

struct Field
{
	string key;
	string value;
}

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

string hashFile(string filename)
{
	import std.stdio : File;
	import std.digest.sha : sha256Of;
	import std.digest : toHexString, LetterCase;

	auto digest = File(filename)
		.byChunk(4 * 1024)
		.sha256Of();

	return toHexString!(LetterCase.lower)(digest[]).idup;
}

string fileSize(string filename)
{
	import std.file : getSize;
	import std.conv : to;

	return filename.getSize.to!string;
}

string evalFunctions(string funcWithParams)
{
	import std.string : startsWith, strip;

	if (funcWithParams.startsWith(Config.hash))
	{
		auto param = funcWithParams[Config.hash.length .. $].strip();
		return hashFile(param);
	}
	else if (funcWithParams.startsWith(Config.size))
	{
		auto param = funcWithParams[Config.size.length .. $].strip();
		return fileSize(param);
	}
	return funcWithParams;
}

string resolveSubstitutions(string raw, Field[] store, JSONValue srcJson)
{
	import std.string : indexOf, startsWith;
	import std.algorithm : find;

	string result;
	size_t i = 0;

	while (i < raw.length)
	{
		if (raw[i] == Config.substitution)
		{
			/* Find closing backtick */
			auto end = raw.indexOf(Config.substitution, i + 1);
			if (end == -1)
				break;

			auto path = raw[i + 1 .. end];

			/* Check local fields first */
			Field[] found = find!(f => f.key == path)(store);
			if (found.length != 0)
			{
				result ~= found[0].value;
			}
			else
			{
				if (path.startsWith(Config.source))
					path = path[Config.source.length .. $];

				result ~= getJsonValue(srcJson, path);
			}

			i = end + 1; /* Skip past closing backtick */
		}
		else
		{
			result ~= raw[i];
			i++;
		}
	}

	return result;
}

string getJsonValue(JSONValue json, string path)
{
	import std.string : split, isNumeric;
	import std.conv : to;

	JSONValue current = json;
	foreach (part; path.split("."))
	{
		if (part.isNumeric())
			current = current[part.to!size_t];
		else
			current = current[part];
	}

	if (current.type == JSONType.string)
		return current.str;

	/* FIXME: Arrays/Objects will fail conversion */
	return current.to!string;
}

JSONValue inferJsonType(string raw)
{
	try
	{
		return raw.parseJSON;
	}
	catch (Exception _)
	{
		return ('\"' ~ raw ~ '\"').parseJSON;
	}
}

/* Use opIndexAssign to update json which is a tuple array when preserving order */
void setJsonValue(ref JSONValue json, string path, string value)
{
	import std.string : split, isNumeric;
	import std.conv : to;

	JSONValue* parent = &json;
	string lastKey;
	size_t lastIndex;
	bool isLastNumeric = false;

	auto parts = path.split(".");
	JSONValue* current = &json;

	foreach (i, part; parts)
	{
		parent = current;

		bool last = i + 1 == parts.length;
		isLastNumeric = part.isNumeric();

		if (isLastNumeric)
		{
			lastIndex = part.to!size_t;
			if (!last)
				current = &(*current)[lastIndex];
		}
		else
		{
			lastKey = part;
			if (!last)
				current = &(*current)[lastKey];
		}
	}

	auto finalValue = inferJsonType(value);

	if (isLastNumeric)
		(*parent)[lastIndex] = finalValue;
	else
		(*parent)[lastKey] = finalValue;
}

void patchJson(string configFile, ref JSONValue json)
{
	import std.file : readText;
	import std.string : startsWith;

	Field[] fields = null;
	auto rawFields = parseConfig(configFile);

	/* Resolve substitutions then functions */
	foreach (i, Field field; rawFields)
	{
		auto substituted = resolveSubstitutions(field.value, fields, json);
		auto value = evalFunctions(substituted);

		if (field.key == Config.source[0 .. $ - 1])
		{
			json = parseJSON(value.readText, JSONOptions.preserveObjectOrder);
		}
		else if (field.key.startsWith(Config.source))
		{
			setJsonValue(json, field.key[Config.source.length .. $], value);
		}
		else
		{
			fields ~= Field(field.key, value);
		}
	}
}
