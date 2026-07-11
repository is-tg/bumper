import std.json : JSONValue, parseJSON, JSONOptions;

import common;
import parser;
import functions;
import json_utils;

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

/* Json source is initialized when the time comes */
string patchJson(string configFile, ref JSONValue json)
{
	import std.file : readText;
	import std.string : startsWith;

	string srcFile;
	Field[] fields = null;
	auto rawFields = parseConfig(configFile);

	/* Resolve substitutions then functions */
	foreach (i, Field field; rawFields)
	{
		auto substituted = resolveSubstitutions(field.value, fields, json);
		auto value = evalFunctions(substituted);

		if (field.key == Config.source[0 .. $ - 1])
		{
			srcFile = value;
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

	return srcFile;
}
