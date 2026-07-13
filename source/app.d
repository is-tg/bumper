import std.getopt : getopt, defaultGetoptPrinter;

import err : Failure, ExitCode;
import worker : doWork;

int main(string[] args)
{
        string configFile = ".bumper";

        auto opts = getopt(
                args,
                "config|c", "Pass path to config file", &configFile,
        );

        if (opts.helpWanted)
        {
                defaultGetoptPrinter("Easy JSON patching.", opts.options);
        }
        else
        {
                try
                        doWork(configFile);
                catch (Failure f)
                {
                        f.report();
                        return cast(int) f.code;
                }
        }

        return ExitCode.SUCCESS;
}
