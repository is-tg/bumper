import std.json : JSONValue, parseJSON, JSONOptions;

import common;
import parser;
import functions;
import json_utils;

string resolveSubstitutions(string rhs, Field[] store, JSONValue srcJson)
{
	import std.string : indexOf, startsWith;
	import std.algorithm : find;

	string result;
	size_t i = 0;

	while (i < rhs.length)
	{
		if (rhs[i] == Config.substitution)
		{
			/* Find closing backtick */
			auto end = rhs.indexOf(Config.substitution, i + 1);
			if (end == -1)
				break;

			auto sub = rhs[i + 1 .. end];

			/* Check local fields first */
			Field[] found = find!(f => f.key == sub)(store);
			if (found.length != 0)
			{
				result ~= found[0].value;
			}
			else if (sub.startsWith(Config.source))
			{
				/* Strip source prefix */
				auto key = sub[Config.source.length .. $];
				/* Look up value in json source */
				result ~= getJsonValue(srcJson, key);
			}

			/* Skip past closing backtick */
			i = end + 1;
		}
		else
		{
			result ~= rhs[i];
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
	import helper : ensureFileExists;

	string srcFile;
	Field[] fields = null;
	auto rawFields = parseConfig(configFile);

	foreach (i, Field field; rawFields)
	{
		auto substituted = resolveSubstitutions(field.value, fields, json);
		auto value = evalFunctions(substituted);

		if (field.key == Config.source[0 .. $ - 1])
		{
			ensureFileExists(value, "Config '" ~ Config.source[0 .. $ - 1] ~ "' references non-existent file");
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
