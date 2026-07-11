import std.typecons : tuple;

void doWork(string configFile)
{
	import std.file : write;
	import std.process : spawnProcess, wait;

	auto result = getUpdatedContent(configFile);
	string jsonFile = result.jsonFile;
	string updatedContent = result.content;

	/* Use something like /tmp/bumper_blablabla.json */
	string draftFile = getTempFile("bumper_", ".json");

	scope (exit)
	{
		import std.file : remove;
		import std.exception : collectException;

		collectException(remove(draftFile));
	}

	draftFile.write(updatedContent);

	wait(spawnProcess([
		"diff",
		"--color=always",
		jsonFile,
		draftFile
	]));

	if (promptOk())
	{
		jsonFile.write(updatedContent);
	}
}

auto getUpdatedContent(string configFile)
{
	import std.json : JSONValue;
	import patcher : patchJson;

	auto json = JSONValue.emptyObject;
	string jsonFile = patchJson(configFile, json);
	string content = json.toPrettyString ~ '\n';

	return tuple!("jsonFile", "content")(jsonFile, content);
}

string getTempFile(string prefix, string suffix)
{
	import std.path : buildPath;
	import std.file : tempDir;
	import std.uuid : randomUUID;

	return buildPath(tempDir, prefix ~ randomUUID().toString() ~ suffix);
}

bool promptOk()
{
	import std.stdio : write, readln;
	import std.string : icmp, strip;

	write("ok? (y/n): ");
	return icmp(readln.strip, "y") == 0;
}
