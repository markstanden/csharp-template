using __dotnet_template__.Core;

namespace __dotnet_template__.Core.Tests;

public sealed class GreeterTests
{
    [Theory]
    [InlineData("Hello")]
    [InlineData("Welcome")]
    [InlineData("Please come in")]
    public void Greet_WithValidPrefix_ReturnsExpectedPrefixedGreeting(string prefix)
    {
        // Arrange
        const string name = "World";
        Greeter greeter = new(prefix: prefix);

        // Act
        string result = greeter.Greet(name);

        // Assert
        result.ShouldBe($"{prefix}, {name}!");
    }

    [Theory]
    [InlineData("World")]
    [InlineData("John")]
    [InlineData("Jane")]
    public void Greet_WithValidName_ReturnsExpectedPrefixedGreeting(string name)
    {
        // Arrange
        const string prefix = "Hello";
        Greeter greeter = new(prefix: prefix);

        // Act
        string result = greeter.Greet(name);

        // Assert
        result.ShouldBe($"{prefix}, {name}!");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData("\n")]
    [InlineData("\r")]
    [InlineData("\r\n")]
    [InlineData("\t")]
    public void Greet_WithWhitespaceName_ThrowsArgumentExceptionWithExpectedMessage(string name)
    {
        // Arrange
        const string parameterName = "name";
        const string prefix = "Hello";
        Greeter greeter = new(prefix: prefix);

        // Act
        Action act = () => greeter.Greet(name);

        // Assert
        Exception ex = act.ShouldThrow<Exception>();
        ex.ShouldBeOfType<ArgumentException>();
        ex.Message.ShouldContain(parameterName);
        ex.Message.ShouldContain("empty string");
    }
}
