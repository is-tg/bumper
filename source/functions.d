string hashFile(string filename)
{
	import std.stdio : File;
	import std.digest.sha : sha256Of;
	import std.digest : toHexString, LetterCase;
	import helper : ensureFileExists;

	ensureFileExists(filename, "Cannot compute hash of non-existent file");

	auto digest = File(filename)
		.byChunk(4 * 1024)
		.sha256Of();

	/* TODO: Make this configurable? */
	return toHexString!(LetterCase.lower)(digest[]).idup;
}

string fileSize(string filename)
{
	import std.file : getSize;
	import std.conv : to;
	import helper : ensureFileExists;

	ensureFileExists(filename, "Cannot compute size of non-existent file");

	return filename.getSize.to!string;
}

string evalFunctions(string funcWithParams)
{
	import common : Config;
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
