import std.getopt : getopt, defaultGetoptPrinter;

import worker : doWork;

void main(string[] args)
{
        bool help;
        string configFile = ".bumper";

        auto opts = getopt(
                args,
                "help|h", "Easy JSON patching", &help,
                "config|c", "-c <file>, --config <file>\tpath to config file", &configFile,
        );

        if (help)
        {
                defaultGetoptPrinter("bumper", opts.options);
        }
        else
        {
                doWork(configFile);
        }
}
