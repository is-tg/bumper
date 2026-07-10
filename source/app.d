import std.json : JSONValue;
import hocon : patchJson;

void main()
{
        import std.file : write;

        /* Json source initialized when the time comes */
        JSONValue json = JSONValue.emptyObject;

        patchJson(".bumper", json);

        "draft.json".write(json.toPrettyString);
}
