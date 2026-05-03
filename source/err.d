enum
{
	ESUCCESS, /* Successful exit status */
	ENOARG, /* No arguments passed */
	ENOENT, /* No such entity */
	EBADFILE, /* Bad file */
	EINVARG, /* Invalid argument */
	EPROGFAIL /* Program execution failed */
}

class Failure : Exception
{
	import std.format : format;

	int exitCode;
	this(Args...)(int code, string fmt, Args args)
	{
		super(format(fmt, args));
		exitCode = code;
	}

	static void print(Args...)(int code, string fmt, Args args)
	{
		import std.stdio : stderr, writeln;

		stderr.writeln("ERROR ", format(fmt, args));
		stderr.writeln("Process exited with code ", code);
	}
}
