namespace __dotnet_template__.Core;

public sealed class Greeter
{
    private readonly string _prefix;

    public Greeter(string prefix = "Hello")
    {
        _prefix = prefix;
    }

    public string Greet(string name)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        return $"{_prefix}, {name}!";
    }
}
