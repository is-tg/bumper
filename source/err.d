import std.conv : to;
import std.format : format;
import std.stdio : stderr;

enum ExitCode
{
	SUCCESS,
	ENOFILE,
	EBADFILE,
}

class Failure : Exception
{
	ExitCode code;

	private static enum RED = "\x1b[31m";
	private static enum BOLD = "\x1b[1m";
	private static enum RESET = "\x1b[0m";

	this(Args...)(ExitCode code, string fmt, Args args)
	{
		super(format(fmt, args));
		this.code = code;
	}

	void report() const
	{
		stderr.writeln(RED, BOLD, "ERROR[", to!string(code), "] ", RESET, msg);
	}

	static noreturn raise(Args...)(ExitCode code, string fmt, Args args)
	{
		throw new Failure(code, fmt, args);
	}
}
