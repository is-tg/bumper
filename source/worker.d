void doWork(string configFile)
{
	import std.file : write;
	import helper : ensureFileExists;

	ensureFileExists(configFile, "Config file does not exist");

	auto result = getUpdatedContent(configFile);
	string jsonFile = result.jsonFile;
	string updatedContent = result.content;

	/* Use something like /tmp/bumper_blablabla.json */
	string draftFile = getTempFile("bumper_", ".json");

	scope (exit)
	{
		import std.exception : collectException;
		import std.file : remove;

		collectException(remove(draftFile));
	}

	draftFile.write(updatedContent);

	showDiff(jsonFile, draftFile);

	if (promptOk())
	{
		jsonFile.write(updatedContent);
	}
}

void showDiff(string originalFile, string updatedFile)
{
	import std.process : spawnProcess, wait;

	wait(spawnProcess([
		"diff",
		"--color=always",
		originalFile,
		updatedFile,
	]));
}

auto getUpdatedContent(string configFile)
{
	import std.json : JSONValue;
	import std.typecons : tuple;
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
