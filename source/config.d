import err;

struct Config
{
        struct Options
        {
                string shell = "bash";
        }

        struct Worker
        {
                string[string] positions;
                string[string] jobs;
        }

        Options options;
        char[] content;
        Worker[] workers;
        size_t workerId = 0;
        private bool newWorker = false;

        this(string path)
        {
                import std.file : exists, read;

                if (!exists(path))
                        throw new Failure(ENOENT, "Config file `%s` does not exist", path);

                content = cast(char[]) path.read;
                workers.reserve(64);
                workers ~= Worker();
                parse();
        }

        private string executeCommand(char[] command)
        {
                import std.process : execute;
                import std.string : stripRight;

                char[] script = command;

                /* POSIX shells */
                if (options.shell == "bash" || options.shell == "zsh" || options.shell == "sh")
                {
                        script = "set -o pipefail; " ~ command;
                }
                /* VIP service */
                else if (options.shell == "fish")
                {
                        script = command ~ "; for code in $pipestatus; if test $code -ne 0; exit $code; end; end";
                }

                auto result = execute([options.shell, "-c", script]);
                auto output = result.output.stripRight;
                if (result.status != 0)
                        throw new Failure(EPROGFAIL, "Command `%s` failed with output:\n%s", command, output);

                return output;
        }

        private void populate(bool isConfig, char[][2] pair)
        {
                import std.file : exists;
                import std.uni : icmp;

                if (isConfig)
                {
                        if (icmp(pair[0], "shell") == 0)
                        {
                                options.shell = cast(string) pair[1];
                        }
                        else
                        {
                                if (newWorker)
                                {
                                        workers ~= Worker();
                                        ++workerId;
                                        newWorker = false;
                                }
                                if (pair[0].exists)
                                {
                                        workers[workerId].positions[cast(string) pair[0]] = cast(string) pair[1];
                                }
                        }
                }
                else
                {
                        workers[workerId].jobs[cast(string) pair[0]] = executeCommand(pair[1]);
                        newWorker = true;
                }
        }

        private void parse()
        {
                import std.ascii : isGraphical;

                bool inWord, isConfig, isValue;
                inWord = isConfig = isValue = false;
                size_t startIndex = 0;
                char[][2] pair;

                /* for every non empty line, obtain two strings pair
		 * context of the pair is either config or job
		 * strings in pair is separated by space
		 * pairs are separated by newline
		 * AAAHMMMMMMMMMMMMMMMMMMMMMMMMMMMM */

                foreach (i, c; content)
                {
                        if (c == '#')
                        {
                                isConfig = true;
                                inWord = isValue = false;
                        }
                        else if (c.isGraphical)
                        {
                                if (!inWord)
                                {
                                        startIndex = i;
                                        inWord = true;
                                }
                        }
                        else
                        {
                                if (isValue && c == '\n')
                                {
                                        pair[1] = content[startIndex .. i];
                                        populate(isConfig, pair);
                                        inWord = isConfig = isValue = false;
                                }
                                else if (!isValue)
                                {
                                        pair[0] = content[startIndex .. i];
                                        isValue = true;
                                        inWord = false;
                                }
                        }
                }

                /* if file does not end with newline */
                if (isValue && inWord)
                {
                        pair[1] = content[startIndex .. $];
                        populate(isConfig, pair);
                }
        }
}

unittest
{
        auto c = Config(".bumper");
}
