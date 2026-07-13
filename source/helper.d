void ensureFileExists(string filename, string errmsg)
{
	import std.file : exists;
	import err : Failure, ExitCode;

	if (!filename.exists())
		Failure.raise(ExitCode.ENOFILE, errmsg ~ ": %s", filename);
}
