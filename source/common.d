struct Config
{
	@disable this();

	enum comment = '#';
	enum separator = ':';
	enum substitution = '`';

	enum source = "src.";
	enum hash = "sha256 ";
	enum size = "bytes ";
}

struct Field
{
	string key;
	string value;
}
