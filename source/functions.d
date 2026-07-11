import common;

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
