import config;
import err;
import jdad;

enum
{
        CONFIG_FILE = ".bumper",
        DRAFT_FILE = "draft.json"
}

int main(string[] args)
{
        try
        {
                if (args.length > 2)
                {
                        tryPrint(args[1 .. $]);
                        return ESUCCESS;
                }

                auto config = Config(CONFIG_FILE);

                foreach (worker; config.workers)
                {
                        foreach (source, destination; worker.positions)
                        {
                                auto doc = JsonFile(source);
                                doc.assign(worker.jobs);
                                doc.save(destination);
                        }
                }
        }
        catch (Failure f)
        {
                Failure.print(f.exitCode, f.msg);
                return f.exitCode;
        }

        return ESUCCESS;
}

void tryPrint(string[] arguments)
{
        import std.file : exists;
        import std.uni : icmp;

        if (!exists(arguments[0]))
                throw new Failure(ENOENT, "File `%s` does not exist", arguments[0]);

        if (icmp(arguments[1], "--print") == 0)
                JsonFile(arguments[0]).print();
        else
                throw new Failure(EINVARG, "Unrecognized argument `%s`", arguments[1]);
}
