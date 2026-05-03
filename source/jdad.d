import std.json;

import err;

struct JsonFile
{
        JSONValue json;
        JSONValue*[string] data;
        string[] order; /* preserve order */
        size_t maxLen;

        this(string path)
        {
                import std.file : exists, readText;

                if (!exists(path))
                        throw new Failure(ENOENT, "File `%s` does not exist", path);

                json = parseJSON(readText(path), JSONOptions.preserveObjectOrder);
                traverse(json, "");
        }

        private void traverse(ref JSONValue j, string pos)
        {
                import std.conv : to;

                if (pos.length != 0)
                        pos ~= ".";
                switch (j.type)
                {
                case JSONType.object:
                        foreach (string key, ref value; j)
                                traverse(value, pos ~ key);
                        break;
                case JSONType.array:
                        foreach (i, ref val; j.array)
                                traverse(val, pos ~ to!string(i));
                        break;
                default:
                        auto key = pos[0 .. $ - 1];
                        data[key] = &j;
                        order ~= key;
                        maxLen = key.length > maxLen ? key.length : maxLen;
                }
        }

        private JSONValue coerce(string value, JSONType target)
        {
                import std.conv : to;

                switch (target)
                {
                case JSONType.true_:
                case JSONType.false_:
                        return JSONValue(value.to!bool);
                case JSONType.null_:
                        return JSONValue(null);
                case JSONType.string:
                        return JSONValue(value);
                case JSONType.float_:
                        return JSONValue(value.to!double);
                case JSONType.integer:
                        return JSONValue(value.to!long);
                case JSONType.uinteger:
                        return JSONValue(value.to!ulong);
                default:
                        throw new Failure(EINVARG, "Cannot assign to value of type", target);
                }
        }

        void assign(string path, string value)
        {
                auto p = path in data;
                if (!p)
                        throw new Failure(EINVARG, "Unrecognized path `%s`", path);

                **p = coerce(value, (**p).type);
        }

        void assign(string[string] config)
        {
                foreach (path, value; config)
                        assign(path, value);
        }

        void save(string destination)
        {
                import std.stdio : File;

                File(destination, "w").writeln(json.toPrettyString(JSONOptions.doNotEscapeSlashes));
        }

        void print()
        {
                import std.stdio : writefln;

                foreach (key; order)
                        writefln("%-*s : %s", maxLen, key, (*data[key]).toString(JSONOptions.doNotEscapeSlashes));
        }
}
