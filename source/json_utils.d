import std.json : JSONValue;

string getJsonValue(JSONValue json, string path)
{
	import std.json : JSONType;

	foreach (part; getParts(path))
		json = *navigate(&json, part);

	/* Prevent including escaped quotes in strings */
	if (json.type() == JSONType.string)
		return json.str();
	else
		return json.toString();
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

		bool isFloat = raw.canFind('.')
			|| raw.canFind('e')
			|| raw.canFind('E');
		if (isFloat)
			return JSONValue(raw.to!double);
		else
			return JSONValue(raw.to!long);
	}

	return JSONValue(raw);
}

void setJsonValue(ref JSONValue json, string path, string value)
{
	import std.string : isNumeric;
	import std.conv : to;

	auto parts = getParts(path);
	auto current = &json;

	foreach (part; parts[0 .. $ - 1])
		current = navigate(current, part);

	auto last = parts[$ - 1];
	auto finalValue = inferJsonType(value);

	if (last.isNumeric())
		(*current)[last.to!size_t] = finalValue;
	else
		(*current)[last] = finalValue;
}

string[] getParts(string path)
{
	import std.string : split;

	return path.split('.');
}

JSONValue* navigate(JSONValue* current, string part)
{
	import std.json : JSONException;
	import std.string : isNumeric;
	import std.conv : to;

	try
	{
		return part.isNumeric()
			? &(*current)[part.to!size_t] /* Array index */
			 : &(*current)[part]; /* Object index */
	}
	catch (JSONException e)
	{
		import err : Failure, ExitCode;

		Failure.raise(
			ExitCode.EBADFILE,
			"Key \"%s\" not found in JSON object %s",
			part,
			*current
		);
	}
}
