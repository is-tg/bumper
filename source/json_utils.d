import std.json : JSONValue, JSONType, parseJSON;

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

/* Arrays and objects are not handled */
JSONValue inferJsonType(string raw)
{
	import std.string : isNumeric;

	if (raw.length == 0)
		return JSONValue(null);

	if (raw == "true")
		return JSONValue(true);

	if (raw == "false")
		return JSONValue(false);

	if (raw.isNumeric)
	{
		import std.algorithm.searching : canFind;
		import std.conv : to;

		bool isFloat = raw.canFind('.') || raw.canFind('e') || raw.canFind('E');
		if (isFloat)
			return JSONValue(raw.to!double);
		else
			return JSONValue(raw.to!long);
	}

	return JSONValue(raw);
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
		bool last = i + 1 == parts
			.length;
		isLastNumeric = part.isNumeric();

		if (isLastNumeric)
		{
			lastIndex = part.to!size_t;
			if (!last)
				current = &(
					*current)[lastIndex];
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
