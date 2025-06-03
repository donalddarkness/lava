# OuroLang Syntax Documentation

## Introduction

Welcome to the syntax documentation for Ouro! This document aims to provide a clear and concise overview of the language's grammar and structure. By understanding these rules, you will be able to write valid and functional programs in Ouro.

We aim to provide low-level performance with high-level syntax, streamlining the use of ML/AI to make revolutionary graphics. Ouro combines modern programming paradigms with specialized features for computational graphics, making it ideal for developers working in game development, simulation, and AI-driven visualization applications.

## Basic Elements

### Keywords

Keywords are reserved words that have special meaning in Ouro and cannot be used as identifiers (variable names, function names, etc.). Understanding these keywords is fundamental to mastering the language.

| Keyword | Description |
| --- | --- |
| interface | Defines a set of method signatures that types can agree to implement. Specifies a contract without enforcing implementation. |
| enum | Declares a type consisting of a fixed set of named values (enumerators), typically used for finite options. |
| struct | Defines a composite data type with named fields. Typically value-based and often used for lightweight data containers. |
| void | Indicates that a function or method returns no value. |
| var | Declares a variable with inferred or flexible type, possibly allowing type inference at compile time. |
| const | Declares an immutable value that cannot be changed after it's defined. |
| static | Marks a member as belonging to the type itself rather than any instance of the type. |
| final | Marks a value, method, or type as non-overridable, non-assignable, or non-extendable, depending on context. |
| new | Used to create new instances of types or objects. |
| this | Refers to the current instance within its own type definition. |
| base | Refers to the immediate parent type from which the current type inherits or extends. |
| super | Used to access members or constructors of a parent type, often during inheritance. |
| public | Specifies that a member is accessible from any other part of the code. |
| private | Restricts access to a member so it can only be used within its own type. |
| protected | Allows access to a member from its own type and derived types. |
| true | The boolean literal representing logical truth. |
| false | The boolean literal representing logical falsehood. |
| null | Represents the absence of a value or reference. |
| try | Begins a block of code that may throw an error or exception. |
| catch | Defines a block to handle specific types of exceptions thrown in a preceding `try` block. |
| finally | Defines a block of code that always runs after a `try` or `catch`, regardless of exceptions. |
| assert | Evaluates a condition at runtime, usually to catch logic errors during development. |
| import | Used to include external modules, libraries, or packages in the current file. |
| package | Declares the namespace that contains the current file's declarations. |
| throw | Explicitly raises an exception or error to be caught elsewhere. |
| async | Marks a method as asynchronous, allowing it to perform non-blocking operations. |
| await | Pauses execution of an async method until the awaited task completes. |
| extends | Indicates that a class inherits from another class. |
| implements | Indicates that a class implements a specified interface. |
| for | Used to create loop structures that iterate over collections or execute code a specified number of times. |

### Identifiers

Identifiers are names used to identify variables, functions, types, etc. In Ouro, identifiers must:
- Start with a letter (a-z, A-Z) or an underscore (_).
- Be followed by letters, numbers (0-9), or underscores.
- Be case-sensitive (e.g., `myVariable` and `MyVariable` are different identifiers).
- Not be a reserved keyword.
- Can be of any length, though extremely long identifiers may impact code readability.

```
// Example of valid identifiers
myVariable
_another_one
calculateSum123
UserProfile
DB_CONNECTION_STRING

// Example of invalid identifiers
123start     // (starts with a number)
my-variable  // (contains a hyphen)
if           // (is a keyword)
class        // (is a keyword)
$special     // (contains special character $)
```

### Literals

Literals are fixed values in the source code that represent data directly.

#### Integer Literals

Decimal integers, e.g., `123`, `-45`. Ouro also supports different number bases:

```
// Decimal (base 10)
123
-45
0

// Hexadecimal (base 16, prefixed with 0x)
0x7B      // 123 in decimal
0xFF      // 255 in decimal

// Binary (base 2, prefixed with 0b)
0b1111011 // 123 in decimal
0b10      // 2 in decimal

// Octal (base 8, prefixed with 0o)
0o173     // 123 in decimal
0o7       // 7 in decimal

// You can use underscores for readability in numeric literals
1_000_000 // Same as 1000000
0xFF_EC_A8 // Same as 0xFFECA8
```

#### String Literals

Text enclosed in double quotes (`"`) or single quotes (`'`).

```
"Hello, World!"
'Single quoted string'
"Escaped quote: \"example\""

// Multi-line strings using triple quotes
"""
This is a multi-line
string that preserves
line breaks and indentation.
"""

// String interpolation using ${expression}
let name = "Alice"
"Hello, ${name}!" // "Hello, Alice!"

// Raw strings (ignoring escape sequences) with 'r' prefix
r"This is a raw string: \n is not a newline"
```

#### Boolean Literals

`true` and `false`.

```
true
false

// Boolean operations
let isActive = true
let hasPermission = false
let canAccess = isActive && hasPermission // false
```

#### Float Literals

Numbers with decimal values.

```
1.2
3.14
2.71

// Scientific notation
1.2e3      // 1200.0
7.5e-2     // 0.075

// Float suffixes
3.14f      // 32-bit float
3.14d      // 64-bit double (default)
```

#### Char Literals

A single character in single quotes (`'`).

```
'a'        // Latin character
'7'        // Digit as a character
'™'        // Unicode character
'\n'       // Newline escape sequence
'\u00A9'   // Unicode escape sequence (© symbol)
```

#### Collection Literals

Ouro provides literal syntax for common collection types:

```
// Array literals
let numbers = [1, 2, 3, 4, 5]

// Dictionary/Map literals
let capitals = {"France": "Paris", "Japan": "Tokyo", "Italy": "Rome"}

// Set literals
let uniqueNumbers = #{1, 2, 3, 4, 5}
```

#### Null and Optional Literals

```
// Null literal
let emptyReference = null

// Optional value (present)
int? maybeNumber = 42

// Optional value (absent)
int? noNumber = null
```

## Inheritance

Inheritance is an object-oriented programming concept where a class can derive properties and behaviors from another class, promoting code reuse and hierarchy.

### Extension

A class can extend another class, meaning a `Child` object is a type of `Parent`. Any methods in the parent class are also in the child class. The child class can override them with `@override`.

```
public class Parent {
    public void speak() {
        print("I am a parent");
    }

    public int calculate(int value) {
        return value * 2;
    }
}

public class Child extends Parent {
    @override
    public void speak() {
        print("I am a child");
    }

    // Can call parent's implementation using super
    public void speakBoth() {
        super.speak();
        speak();
    }

    // This method is inherited without change
    // No need to redefine calculate() unless you want to change behavior
}

// Usage
Child child = new Child();
child.speak();        // "I am a child"
child.speakBoth();    // "I am a parent" followed by "I am a child"
child.calculate(5);   // 10 (inherited from Parent)
```

### Multiple Inheritance

Ouro supports interface-based multiple inheritance, but not class-based multiple inheritance:

```
public interface Swimmer {
    void swim();
}

public interface Flyer {
    void fly();
}

// A class can implement multiple interfaces
public class Duck implements Swimmer, Flyer {
    @override
    public void swim() {
        print("Duck is swimming");
    }

    @override
    public void fly() {
        print("Duck is flying");
    }
}
```

### Abstraction

An abstract class cannot be instantiated, a child class must extend it to obtain an instance.

```
public abstract class Abstract {
    // Non-abstract methods can have implementations
    public void concreteMethod() {
        print("This method has a default implementation");
    }

    // Abstract methods have no body and must be implemented by subclasses
    abstract void someMethod();

    // Abstract methods with parameters and return types
    abstract int calculate(int a, int b);
}

public class Concrete extends Abstract {
    @override
    public void someMethod() {
        print("Implemented abstract method");
    }

    @override
    public int calculate(int a, int b) {
        return a + b;
    }

    // concreteMethod() is inherited as is
}
```

### Interfaces

An interface has method declarations with no bodies, like an abstract class. Unlike abstract classes, they cannot have fields or constructors. They can however have `default` methods which all inheritants have by default, and can be overidden.

```
public interface Interface {
    string getName();
    int getAge();

    default void printInfo() {
        print("My name is ${getName()} and I am ${getAge()}");
    }

    // Static methods are allowed in interfaces
    static boolean isAdult(int age) {
        return age >= 18;
    }
}

public class Class implements Interface {
    private string name;
    private int age;

    public Class(string name, int age) {
        this.name = name;
        this.age = age;
    }

    @override
    public string getName() {
        return name;
    }

    @override
    public int getAge() {
        return age;
    }

    // Can override default methods
    @override
    public void printInfo() {
        print("Person: ${getName()}, ${getAge()} years old");
    }
}

// Usage
Class person = new Class("John", 25);
person.printInfo();  // "Person: John, 25 years old"
boolean isAdult = Interface.isAdult(person.getAge());  // true
```

### Sealed Classes

Sealed classes restrict which classes can inherit from them:

```
public sealed class Shape permits Circle, Rectangle {
    // Common shape functionality
}

public class Circle extends Shape {
    // Circle implementation
}

public class Rectangle extends Shape {
    // Rectangle implementation
}

// This would cause a compiler error
public class Triangle extends Shape {
    // Not allowed because Triangle is not in the permits list
}
```

## Data Types

Ouro supports a rich set of data types, including primitive types that exist by default within the language and reference types that are defined as classes.

### Primitive Types

| Type | Description | Example Literals | Range |
| --- | --- | --- | --- |
| byte | Signed 8-bit integer type. | `byte b = -100` | -128 to 127 |
| ubyte | Unsigned 8-bit integer type. | `ubyte ub = 200` | 0 to 255 |
| short | Signed 16-bit integer type. | `short s = -32000` | -32,768 to 32,767 |
| ushort | Unsigned 16-bit integer type. | `ushort us = 65000` | 0 to 65,535 |
| int | Signed 32-bit integer type (default integer). | `int x = 123456` | -2^31 to 2^31-1 |
| uint | Unsigned 32-bit integer type. | `uint ux = 4000000000` | 0 to 2^32-1 |
| long | Signed 64-bit integer type. | `long l = -9000000000000000000` | -2^63 to 2^63-1 |
| ulong | Unsigned 64-bit integer type. | `ulong ul = 18000000000000000000` | 0 to 2^64-1 |
| float | 32-bit floating-point number type. | `float f = 3.14f` | ±1.5e−45 to ±3.4e38 |
| double | 64-bit floating-point number type (typically used for higher precision). | `double d = 2.718281828` | ±5.0e−324 to ±1.7e308 |
| string | A sequence of characters representing text. | `string name = "OuroLang"` | Limited by available memory |
| bool | Boolean type that holds either `true` or `false`. | `bool isReady = true` | true or false |
| char | Represents a single Unicode character. | `char letter = 'A'` | Any Unicode character |
| decimal | 128-bit high-precision decimal type. | `decimal money = 125.37m` | ±1.0e-28 to ±7.9e28 |
| half | 16-bit floating-point type for efficient storage. | `half h = 3.5h` | Limited precision |

### Type Declaration

Ouro is statically typed, meaning a variable's type must remain the same throughout its lifetime.

```
// Explicit type declaration
int age = 30;
string greeting = "Hello";
float price = 19.99f;

// Using var with type inference
var name = "Alice";    // Compiler infers type as string
var count = 10;        // Compiler infers type as int
var isActive = true;   // Compiler infers type as bool

// Type declarations with arrays
int[] numbers = [1, 2, 3, 4, 5];
string[] names = ["Alice", "Bob", "Charlie"];
```

### Type Conversions

Ouro provides both implicit and explicit type conversions:

```
// Implicit conversions (safe, no data loss)
byte b = 10;
int i = b;      // Implicitly converts byte to int

// Explicit conversions (may cause data loss)
int largeNumber = 1000;
byte smallByte = (byte)largeNumber;  // Truncates to fit in byte range

// String conversions
string numStr = "42";
int parsed = int.parse(numStr);  // 42

// Using conversion methods
float f = 3.14f;
string floatStr = f.toString();  // "3.14"
```

### Generics

Ouro supports generic types and methods for type-safe collections and algorithms:

```
// Generic class
public class Box<T> {
    private T value;

    public Box(T value) {
        this.value = value;
    }

    public T getValue() {
        return value;
    }

    public void setValue(T value) {
        this.value = value;
    }
}

// Usage of generics
Box<int> intBox = new Box<int>(42);
int intValue = intBox.getValue();  // 42

Box<string> stringBox = new Box<string>("Hello");
string strValue = stringBox.getValue();  // "Hello"

// Generic method
public <T> void printArray(T[] array) {
    for (T item in array) {
        print(item);
    }
}

// Using generic method
int[] numbers = [1, 2, 3];
string[] words = ["hello", "world"];
printArray(numbers);  // Prints each number
printArray(words);    // Prints each string
```

### Collection Types

Ouro provides several built-in collection types:

```
// Arrays (fixed size)
int[] numbers = [1, 2, 3, 4, 5];
string[] names = new string[3];  // Creates an array with 3 null elements

// Lists (dynamic size)
List<int> numberList = new List<int>();
numberList.add(1);
numberList.add(2);
numberList.add(3);

// Maps (key-value pairs)
Map<string, int> ages = new Map<string, int>();
ages.put("Alice", 30);
ages.put("Bob", 25);
int aliceAge = ages.get("Alice");  // 30

// Sets (unique elements)
Set<string> uniqueNames = new Set<string>();
uniqueNames.add("Alice");
uniqueNames.add("Bob");
uniqueNames.add("Alice");  // Ignored as "Alice" is already in the set
```

## Variables and Constants

Variables store data that can change during program execution, while constants hold data that remains fixed.

### Variable Declaration

Ouro provides multiple ways to declare variables, depending on your needs for type explicitness and mutability.

```
// Explicit type declaration
int count = 0;
string name = "Alice";
bool isActive = true;

// Type inference with 'var' keyword
var message = "Hello";    // Type is inferred as string
var number = 42;          // Type is inferred as int
var pi = 3.14159;         // Type is inferred as double

// Type inference with 'let' keyword (similar to var)
let user = "Bob";         // Type is inferred as string
let age = 25;             // Type is inferred as int

// Multiple declarations of the same type
int x = 5, y = 10, z = 15;

// Declaration without initialization (must provide type)
string response;
int total;
// Later assign values
response = "Accepted";
total = 100;
```

### Constants

Constants are immutable values that cannot be changed after initialization.

```
// Constants with explicit type
const int MAX_USERS = 100;
const string APP_NAME = "OuroEditor";
const double TAX_RATE = 0.07;

// Constants with type inference
const PI = 3.14159265359;  // Inferred as double
const DEBUG_MODE = true;   // Inferred as bool

// Constants in classes
public class Configuration {
    public const int TIMEOUT = 30;  // Seconds
    public const string DEFAULT_THEME = "Dark";
}

// Using class constants
int timeout = Configuration.TIMEOUT;
```

### Variable Scope

The scope of a variable determines where it can be accessed within code:

```
public void demonstrateScope() {
    int outerVariable = 10;  // Accessible throughout method

    {
        int blockVariable = 20;  // Only accessible within this block
        print(outerVariable);    // Works fine
        print(blockVariable);    // Works fine
    }

    print(outerVariable);    // Works fine
    // print(blockVariable); // Error: blockVariable is out of scope

    for (int i = 0; i < 3; i++) {
        // i is only accessible within the loop
        print(i);
    }
    // print(i);  // Error: i is out of scope
}
```

### Variable Shadowing

When a local variable has the same name as a variable in an outer scope:

```
public class ShadowExample {
    private int value = 10;

    public void printValues() {
        print(value);           // 10 (class field)

        int value = 20;         // Creates a local variable that shadows the field
        print(value);           // 20 (local variable)

        print(this.value);      // 10 (explicitly accessing the field with this)
    }
}
```

### Assignment

Ouro provides various ways to assign values to variables:

```
// Basic assignment
let myVariable = "new value";
const someVar = anotherVar + 5;

// Multiple assignment
int a, b;
a = b = 10;  // Both a and b become 10

// Compound assignments
int counter = 0;
counter += 5;        // Same as: counter = counter + 5
counter *= 2;        // Same as: counter = counter * 2

// Conditional assignment
int result = condition ? valueIfTrue : valueIfFalse;

// Null-coalescing assignment
string name = nullableValue ?? "Default Name";
```

The following is an example of invalid code related to variables:

```
let var;                 // A variable must have a type, and no type is explicitly defined or implied
const var = "Hello";
var = "Hi";              // A constant's value is immutable
let var = "Some String";
var = 12;                // Although no type is explicitly defined, the var is implicitly defined to be a string,
                        // and cannot be changed to an int

int x = "string";        // Type mismatch: cannot convert string to int
final int y;             // Final variables must be initialized at declaration
y = 10;                  // Cannot assign to final variable after declaration
```

## Operators

Operators perform operations on one or more operands in OuroLang. Understanding operator precedence is crucial for writing correct expressions.

### Arithmetic Operators

These operators perform basic mathematical operations:

| Operator | Description | Example |
| --- | --- | --- |
| `+` | Addition or unary plus. | `x = 1 + 2` |
| `-` | Subtraction or unary minus. | `x = 5 - 3` |
| `*` | Multiplication. | `x = 2 * 4` |
| `/` | Division. | `x = 10 / 2` |
| `%` | Modulo (remainder). | `x = 7 % 3` |
| `++` | Increment by 1. | `i++` or `++i` |
| `--` | Decrement by 1. | `i--` or `--i` |
| `**` | Exponentiation. | `x = 2 ** 3` |

```
// Examples of arithmetic operators
int a = 10;
int b = 3;

int sum = a + b;        // 13
int difference = a - b; // 7
int product = a * b;    // 30
int quotient = a / b;   // 3 (integer division)
int remainder = a % b;  // 1

// Pre vs post increment/decrement
int i = 5;
int j = i++;  // j = 5, i = 6 (post-increment: value assigned before incrementing)
int k = ++i;  // i = 7, k = 7 (pre-increment: value assigned after incrementing)

// Exponentiation
double squared = 2 ** 2;  // 4.0
double cubed = 2 ** 3;    // 8.0
```

### Assignment Operators

These operators assign values to variables, often combining assignment with another operation:

| Operator | Description | Example |
| --- | --- | --- |
| `=` | Assignment. | `x = 42` |
| `+=` | Add and assign. | `x += 5` |
| `-=` | Subtract and assign. | `x -= 3` |
| `*=` | Multiply and assign. | `x *= 2` |
| `/=` | Divide and assign. | `x /= 4` |
| `%=` | Modulo and assign. | `x %= 2` |
| `&=` | Bitwise AND and assign. | `x &= mask` |
| `|=` | Bitwise OR and assign. | `x |= flag` |
| `^=` | Bitwise XOR and assign. | `x ^= toggle` |
| `<<=` | Left shift and assign. | `x <<= 1` |
| `>>=` | Right shift and assign. | `x >>= 1` |
| `>>>=` | Unsigned right shift and assign. | `x >>>= 1` |
| `?=` | Null-coalescing assignment. | `value ?= default` |
| `**=` | Exponentiation and assign. | `x **= 2` |

```
// Examples of assignment operators
int x = 10;
x += 5;      // x = 15 (same as x = x + 5)
x -= 3;      // x = 12 (same as x = x - 3)
x *= 2;      // x = 24 (same as x = x * 2)
x /= 6;      // x = 4  (same as x = x / 6)

// Null-coalescing assignment
string name = null;
name ?= "Unknown";  // name = "Unknown" because name was null
```

### Comparison Operators

These operators compare values and return boolean results:

| Operator | Description | Example |
| --- | --- | --- |
| `==` | Equality. | `a == b` |
| `!=` | Inequality. | `a != b` |
| `<` | Less than. | `a < b` |
| `>` | Greater than. | `a > b` |
| `<=` | Less than or equal to. | `a <= b` |
| `>=` | Greater than or equal to. | `a >= b` |
| `===` | Strict equality (same type and value). | `a === b` |
| `!==` | Strict inequality. | `a !== b` |
| `<=>` | Spaceship operator (returns -1, 0, or 1). | `a <=> b` |

```
// Examples of comparison operators
int a = 5;
int b = 10;
int c = 5;

bool isEqual = (a == c);         // true
bool isNotEqual = (a != b);      // true
bool isLess = (a < b);           // true
bool isGreaterOrEqual = (a >= c); // true

// Spaceship operator for three-way comparison
int comparison = a <=> b;        // -1 (a is less than b)
int sameComparison = c <=> a;    // 0 (c equals a)
int reverseComparison = b <=> a; // 1 (b is greater than a)

// Strict equality considers type
int num = 5;
string str = "5";
bool strictEquality = (num === str); // false (different types)
```

### Logical Operators

These operators perform boolean logic operations:

| Operator | Description | Example |
| --- | --- | --- |
| `&&` | Logical AND (short-circuit). | `a && b` |
| `||` | Logical OR (short-circuit). | `a || b` |
| `!` | Logical NOT. | `!a` |
| `^` | Logical XOR. | `a ^ b` |
| `??` | Null-coalescing. | `a ?? b` |

```
// Examples of logical operators
bool hasPermission = true;
bool isActive = false;

bool canAccess = hasPermission && isActive; // false (both must be true)
bool canLogin = hasPermission || isActive;  // true (at least one is true)
bool isRestricted = !hasPermission;         // false (opposite of true)

// Short-circuit behavior
bool result = checkFirst() && checkSecond();
// checkSecond() won't be called if checkFirst() returns false

// Null-coalescing operator
string username = getUsername() ?? "Guest";  // If getUsername() returns null, use "Guest"
```

### Bitwise Operators

These operators manipulate individual bits in integer values:

| Operator | Description | Example |
| --- | --- | --- |
| `~` | Bitwise NOT. | `x = ~a` |
| `&` | Bitwise AND. | `x = a & b` |
| `|` | Bitwise OR. | `x = a | b` |
| `^` | Bitwise XOR. | `x = a ^ b` |
| `<<` | Left shift. | `x = x << 2` |
| `>>` | Right shift (signed). | `x = x >> 1` |
| `>>>` | Unsigned right shift. | `x = x >>> 1` |

```
// Examples of bitwise operators
int a = 5;     // 101 in binary
int b = 3;     // 011 in binary

int bitwiseAnd = a & b;   // 001 = 1 (bits set in both a AND b)
int bitwiseOr = a | b;    // 111 = 7 (bits set in either a OR b)
int bitwiseXor = a ^ b;   // 110 = 6 (bits set in a OR b but NOT both)
int bitwiseNot = ~a;      // 11111111111111111111111111111010 (all bits flipped)

// Shift operations
int leftShift = a << 1;   // 1010 = 10 (shift all bits left by 1)
int rightShift = a >> 1;  // 10 = 2 (shift all bits right by 1)
```

### Range & Null Operators

These operators work with ranges and null values:

| Operator | Description | Example |
| --- | --- | --- |
| `...` | Inclusive range. | `for i in 1...5` |
| `..<` | Exclusive range. | `for i in 1..<5` |
| `..` | Range to end. | `array[2..]` |
| `..^` | Range from start with end index. | `array[..^3]` |
| `??` | Null-coalescing. | `x = a ?? b` |
| `?` | Optional type indicator. | `int? maybe` |
| `?.` | Safe navigation. | `obj?.property` |
| `!` | Null assertion. | `nonNullValue = nullableValue!` |

```
// Examples of range and null operators
// Inclusive range (includes both 1 and 5)
for (i in 1...5) {
    print(i);  // Prints 1, 2, 3, 4, 5
}

// Exclusive range (includes 1 but not 5)
for (i in 1..<5) {
    print(i);  // Prints 1, 2, 3, 4
}

// Array slicing
int[] numbers = [0, 1, 2, 3, 4, 5];
int[] slice1 = numbers[2..4];    // [2, 3]
int[] slice2 = numbers[3..];     // [3, 4, 5]
int[] slice3 = numbers[..^2];    // [0, 1, 2, 3]

// Safe navigation operator
User? user = getUser();  // May return null
string? name = user?.name;  // No null reference exception if user is null

// Null assertion
User definiteUser = getUser()!;  // Throws if getUser() returns null
```

### Other Operators

These operators serve specialized purposes:

| Operator | Description | Example |
| --- | --- | --- |
| `$` | Used for interpolation or identifiers. | `print($"Hello, {name}")` |
| `@` | Used for annotations or decorators. | `@Test` |
| `\` | Escape character in strings. | `"Line\nBreak"` |
| `=>` | Arrow operator for lambdas. | `(x) => x * 2` |
| `?:` | Ternary conditional. | `condition ? trueValue : falseValue` |
| `::` | Method reference. | `String::length` |
| `.` | Member access. | `object.property` |
| `[]` | Array or collection access. | `array[index]` |
| `()` | Method invocation. | `method()` |
| `is` | Type checking. | `obj is String` |
| `as` | Type conversion. | `obj as String` |
| `typeof` | Gets type of value. | `typeof(myVar)` |

```
// Examples of other operators
// String interpolation
string name = "Alice";
string greeting = $"Hello, {name}!";  // "Hello, Alice!"

// Ternary conditional operator
bool isLoggedIn = true;
string message = isLoggedIn ? "Welcome back!" : "Please log in";

// Arrow functions (lambdas)
var multiply = (int x, int y) => x * y;
int result = multiply(3, 4);  // 12

// Type checking and casting
if (obj is string) {
    string str = obj as string;
    print(str.length);
}

// Method references
List<string> names = ["Alice", "Bob", "Charlie"];
List<int> lengths = names.map(String::length);  // [5, 3, 7]
```

### Operator Precedence

Operators are evaluated in the following order (from highest to lowest precedence):

1. Postfix (`x++`, `x--`, `()`, `[]`, `.`, `?.`)
2. Prefix (`++x`, `--x`, `+x`, `-x`, `!`, `~`, `await`)
3. Exponentiation (`**`)
4. Multiplicative (`*`, `/`, `%`)
5. Additive (`+`, `-`)
6. Shift (`<<`, `>>`, `>>>`)
7. Relational (`<`, `>`, `<=`, `>=`, `is`, `as`)
8. Equality (`==`, `!=`, `===`, `!==`)
9. Bitwise AND (`&`)
10. Bitwise XOR (`^`)
11. Bitwise OR (`|`)
12. Logical AND (`&&`)
13. Logical OR (`||`)
14. Null coalescing (`??`)
15. Conditional (`?:`)
16. Assignment (`=`, `+=`, `-=`, etc.)

Use parentheses to override the default precedence when needed:

```
// Default precedence
int result1 = 2 + 3 * 4;      // 14 (multiplication before addition)

// Override with parentheses
int result2 = (2 + 3) * 4;    // 20 (addition first, then multiplication)
```

## Control Flow

Control flow statements dictate the order in which statements are executed, allowing for conditional execution, looping, and branching.

### Conditional Statements (If-Else)

Conditional statements execute code based on whether a condition evaluates to true or false.

```
// Basic If
if (condition) {
    // code to execute if condition is true
}

// If-Else
if (condition) {
    // code if true
} else {
    // code if false
}

// If-Else If-Else
if (condition1) {
    // code if condition1 is true
} else if (condition2) {
    // code if condition2 is true
} else {
    // code if no conditions are true
}

// Nested conditions
if (outerCondition) {
    if (innerCondition) {
        // code if both conditions are true
    }
}

// Single-line if statements (when there's only one statement)
if (success) print("Operation successful");

// With logical operators
if (age >= 18 && hasID) {
    print("Can purchase");
}
```

### Switch Statements

Switch statements provide a cleaner way to handle multiple conditions based on a single expression.

```
// Basic switch statement
switch (expression) {
    case value1:
        // code if expression equals value1
        break;
    case value2:
        // code if expression equals value2
        break;
    default:
        // code if no cases match
        break;
}

// Example with strings
switch (dayOfWeek) {
    case "Monday":
        print("Start of work week");
        break;
    case "Friday":
        print("End of work week");
        break;
    case "Saturday":
    case "Sunday":
        print("Weekend!");
        break;
    default:
        print("Midweek");
        break;
}

// Switch with pattern matching
switch (shape) {
    case Circle c when c.radius > 5:
        print("Large circle");
        break;
    case Circle c:
        print("Circle with radius: ${c.radius}");
        break;
    case Rectangle r:
        print("Rectangle: ${r.width} x ${r.height}");
        break;
    case null:
        print("No shape provided");
        break;
    default:
        print("Unknown shape");
        break;
}

// Expression switch (returns a value)
string message = switch (statusCode) {
    case 200 => "OK";
    case 404 => "Not Found";
    case 500 => "Server Error";
    default => "Unknown Status: ${statusCode}";
};
```

### Looping Statements (While, For)

Loops allow you to execute code repeatedly while a condition is true or for a specific number of iterations.

#### While Loop

Executes a block of code as long as a condition is true.

```
// Basic while loop
while (condition) {
    // code to repeat as long as condition is true
}

// Example with counter
int count = 0;
while (count < 5) {
    print(count);
    count++;
}

// Do-while loop (executes at least once)
do {
    // code to execute
} while (condition);

// Example
int i = 0;
do {
    print(i);
    i++;
} while (i < 3);
```
#### For Loop

Ouro provides several formats for iterative execution, offering flexibility for different programming needs.

```
// Traditional C-style For Loop
for (initialization; condition; increment) {
    // code to repeat
}

// Example:
for (int i = 0; i < 10; i++) {
    print(i);  // Prints 0 through 9
}

// For-each loop (iterate through elements)
char[] characters = "abcdefg".toCharArray();
for (char c in characters) {
    print(c);  // Prints a, b, c, d, e, f, g
}

// For-each with collection types
List<string> fruits = ["apple", "banana", "cherry"];
for (string fruit in fruits) {
    print("I like ${fruit}");
}

// For loop with explicit indices
for (int i = 0; i < fruits.length; i++) {
    print("Fruit ${i+1}: ${fruits[i]}");
}

// For loop with range syntax (inclusive)
for (i in 1 ... 5) {
    print(i);  // Prints 1, 2, 3, 4, 5
}

// For loop with range syntax (exclusive)
for (i in 1 ..< 5) {
    print(i);  // Prints 1, 2, 3, 4
}

// For loop with custom step increment
for (i in 0 ... 10 step 2) {
    print(i);  // Prints 0, 2, 4, 6, 8, 10
}

// Multi-dimensional iteration
for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
        processPixel(x, y);
    }
}

// Multi-variable for loops using array syntax
for (var [x, y, z] = [0, 0, 0]; x < 10 && y < 10; [x++, y++, z = calculateZ(x, y)]) {
    // Process each point where z is dynamically calculated from x and y
    print("Point (${x}, ${y}, ${z})");
}

// Multi-variable loop with bounded coordinates
for (var [x, y, z] = [0, 0, 0]; [x, y, z] < [10, 10, 10]; [x++, y++, z++]) {
    // Process 3D grid of points
    print("Grid point (${x}, ${y}, ${z})");
}

// Advanced coordinate processing
for (var [x, y, z] = [0, 0, 0]; x < 10 && y < 10; [x++, y += 2, z = perlin(x, y)]) {
    // Process with custom y step increment and calculated z value
    print("Sampling at (${x}, ${y}) with height ${z}");
}
```
### Loop Control Statements

These statements modify the flow of loops, enabling more sophisticated control patterns and optimized execution:

```
// Break statement: exits the loop completely
for (int i = 0; i < 10; i++) {
    if (i == 5) {
        break;  // Exit the loop when i is 5
    }
    print(i);  // Prints 0, 1, 2, 3, 4
}

// Continue statement: skips the current iteration
for (int i = 0; i < 5; i++) {
    if (i == 2) {
        continue;  // Skip iteration when i is 2
    }
    print(i);  // Prints 0, 1, 3, 4
}

// Labeled breaks and continues for nested loops
outer: for (int i = 0; i < 3; i++) {
    inner: for (int j = 0; j < 3; j++) {
        if (i == 1 && j == 1) {
            break outer;  // Exit both loops
        }
        print("(${i},${j})");
    }
}

// Return statement in loops for early function exit
public bool containsValue(int[] array, int target) {
    for (int value in array) {
        if (value == target) {
            return true;  // Immediately exits both the loop and the method
        }
    }
    return false;
}

// Break with while loops to handle conditional termination
int attempts = 0;
while (true) {  // Infinite loop with controlled exit
    attempts++;
    if (attempts >= 5 || isSuccessful()) {
        break;  // Exit after 5 attempts or on success
    }
}

// Continue with do-while loops for conditional processing
int count = 0;
do {
    count++;
    if (!isValidData(count)) {
        continue;  // Skip processing for invalid data
    }
    processData(count);
} while (count < maxCount);

// Loop-and-a-half pattern for cleaner validation logic
while (true) {
    Input input = getUserInput();
    if (!input.isValid()) {
        print("Invalid input, please try again");
        continue;
    }
    if (input.isExit()) {
        break;
    }
    processValidInput(input);
}

// Early termination pattern for performance optimization
public bool anyMatch(List<int> numbers, Predicate<int> condition) {
    for (int num in numbers) {
        if (condition(num)) {
            return true;  // Stop processing once a match is found
        }
    }
    return false;
}

// Nested loop control with labeled continue
outer: for (int i = 0; i < matrix.length; i++) {
    for (int j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] < 0) {
            print("Skipping row ${i} due to negative value");
            continue outer;  // Skip to the next row
        }
        processCell(matrix[i][j]);
    }
}

// Complex termination condition with accumulation pattern
int sum = 0;
int count = 0;
for (int value in dataset) {
    // Skip invalid data points
    if (value < 0 || value > 100) {
        continue;  // Skip outliers
    }

    // Process valid data
    sum += value;
    count++;

    // Stop after sufficient data collected or threshold reached
    if (count >= 1000 || sum > 10000) {
        break;
    }
}

// Using labeled breaks for state machine implementation
stateMachine: while (true) {
    switch (currentState) {
        case State.INIT:
            if (initialize()) {
                currentState = State.PROCESS;
            } else {
                break stateMachine;  // Exit on initialization failure
            }
            break;

        case State.PROCESS:
            if (processData()) {
                currentState = State.COMPLETE;
            } else {
                currentState = State.ERROR;
            }
            break;

        case State.COMPLETE:
        case State.ERROR:
            break stateMachine;  // Exit the state machine loop
    }
}
```

Best practices for loop control:

1. Use `break` when you've found what you're looking for or a condition makes further iteration unnecessary.
2. Use `continue` to skip over elements that don't need processing.
3. Label loops only when necessary to improve readability.
4. Consider extracting complex loop logic into dedicated methods for better readability.
5. Be careful with `break` and `continue` in deeply nested loops as they can make code harder to follow.
6. When using labeled statements, choose descriptive labels that indicate the purpose of the loop.
7. Consider early termination patterns for performance optimization in large datasets.
8. Use the loop-and-a-half pattern when input validation or conditional continuation creates cleaner code.
9. Document complex loop control flow, especially when using multiple labeled breaks or continues.
10. Consider alternative patterns like streams or functional approaches for complex filtering scenarios.

### Exception Handling

Exception handling allows you to manage runtime errors gracefully, separating error handling code from your main logic flow.

```
// Basic try-catch
try {
    // code that might throw an exception
    int result = divide(10, 0);
} catch (DivideByZeroException e) {
    // code to handle this specific exception
    print("Cannot divide by zero: ${e.message}");
} catch (Exception e) {
    // code to handle any other exception
    print("An error occurred: ${e.message}");
} finally {
    // code that runs regardless of whether an exception occurred
    print("Operation finished");
}

// Try-with-resources (automatically closes resources)
try (FileStream file = new FileStream("data.txt")) {
    // use the file
    string contents = file.readText();
    print(contents);
} // file is automatically closed even if an exception occurs

// Multiple resources in try-with-resources
try (
    FileStream input = new FileStream("input.txt");
    FileStream output = new FileStream("output.txt", FileMode.Create)
) {
    byte[] buffer = new byte[1024];
    int bytesRead;
    while ((bytesRead = input.read(buffer, 0, buffer.length)) > 0) {
        output.write(buffer, 0, bytesRead);
    }
} // Both resources are automatically closed in reverse order

// Throwing exceptions
public int divide(int a, int b) {
    if (b == 0) {
        throw new DivideByZeroException("Cannot divide ${a} by zero");
    }
    return a / b;
}

// Rethrowing exceptions
try {
    processData();
} catch (Exception e) {
    log(e);
    throw;  // Rethrow the same exception
}

// Exception chaining
try {
    // Some database operation
    db.executeQuery(query);
} catch (SQLException e) {
    // Wrap the low-level exception with higher-level context
    throw new DataAccessException("Failed to retrieve user data", e);
}

// Custom exception hierarchy
public class AppException extends Exception {
    public AppException(string message) {
        super(message);
    }

    public AppException(string message, Exception cause) {
        super(message, cause);
    }
}

public class ValidationException extends AppException {
    private string fieldName;

    public ValidationException(string fieldName, string message) {
        super("Validation failed for ${fieldName}: ${message}");
        this.fieldName = fieldName;
    }

    public string getFieldName() {
        return fieldName;
    }
}

// Using custom exceptions
public void validateUser(User user) {
    if (user.name == null || user.name.isEmpty()) {
        throw new ValidationException("name", "Name cannot be empty");
    }

    if (user.email == null || !isValidEmail(user.email)) {
        throw new ValidationException("email", "Invalid email format");
    }
}

// Try-catch with multi-catch pattern
try {
    performComplexOperation();
} catch (IOException | NetworkException e) {
    // Handle both exception types in the same way
    handleConnectionError(e);
} catch (ValidationException e) {
    // Handle validation errors differently
    showValidationError(e.getFieldName(), e.getMessage());
} catch (Exception e) {
    // Handle any other exceptions
    logError(e);
    showGenericError();
} finally {
    cleanup();
}

// Exception filters
try {
    processRequest(request);
} catch (ServiceException e) when (e.statusCode == 503) {
    // Only catch service exceptions with specific status code
    retryLater(request);
} catch (ServiceException e) {
    // Handle other service exceptions
    handleServiceError(e);
}
```

Best practices for exception handling:

1. Use specific exception types rather than catching general Exception when possible.
2. Always include descriptive error messages that help diagnose the problem.
3. Clean up resources in finally blocks or use try-with-resources.
4. Don't catch exceptions you can't handle properly.
5. Preserve the original exception when rethrowing by using exception chaining.
6. Design a clear exception hierarchy for your application's domains.
7. Document the exceptions your methods can throw in comments or documentation.
8. Avoid using exceptions for normal flow control - they should represent exceptional conditions.
9. Log sufficient context with exceptions to aid in debugging.
10. Consider performance implications in high-throughput code paths.
## Method

Methods are blocks of code designed to perform a particular task. They encapsulate functionality, improve code organization, and enable code reuse. In Ouro, methods are first-class citizens and can be defined with various modifiers and features.

### Method Declaration

Methods are defined with a return type, name, parameters, and body.

```
// Syntax: [access_modifier] [static_modifier] [additional_modifiers] [return_type] [methodName]([parameters]) {
//     // method body
//     return value; // if applicable
// }

// Method with return value
public string greet(string name) {
    return "Hello, " + name + "!";
}

// Void method (no return value)
public void printInfo(int id, string name) {
    print("ID: ${id}, Name: ${name}");
}

// Static method (belongs to the class, not instances)
public static int calculateSum(int a, int b) {
    return a + b;
}

// Method with default parameters
public void configure(string host = "localhost", int port = 8080) {
    print("Connecting to ${host}:${port}");
}

// Variable number of parameters (varargs)
public int sum(int... numbers) {
    int total = 0;
    for (int num in numbers) {
        total += num;
    }
    return total;
}

// Generic method
public <T> T getFirstElement(T[] array) {
    if (array.length == 0) {
        throw new IllegalArgumentException("Array cannot be empty");
    }
    return array[0];
}

// Expression-bodied method (shorthand syntax)
public double calculateArea(double radius) => Math.PI * radius * radius;

// Method with multiple type parameters
public <K, V> Map<K, V> zipToMap(K[] keys, V[] values) {
    if (keys.length != values.length) {
        throw new IllegalArgumentException("Keys and values arrays must be the same length");
    }

    Map<K, V> result = new Map<K, V>();
    for (int i = 0; i < keys.length; i++) {
        result.put(keys[i], values[i]);
    }
    return result;
}
```

### Access Modifiers

Access modifiers control the visibility and accessibility of methods:

```
// Public - accessible from any code
public void publicMethod() { /* ... */ }

// Private - only accessible within the same class
private void privateMethod() { /* ... */ }

// Protected - accessible within the same class and subclasses
protected void protectedMethod() { /* ... */ }

// Package-private (default) - accessible within the same package
void packageMethod() { /* ... */ }

// Internal - accessible within the same assembly/module
internal void internalMethod() { /* ... */ }
```

### Method Overloading

Method overloading allows multiple methods with the same name but different parameter types or counts:

```
// Overloaded methods
public void draw(Circle circle) {
    // Code to draw a circle
}

public void draw(Rectangle rectangle) {
    // Code to draw a rectangle
}

public void draw(int x, int y, int radius) {
    // Code to draw a circle at (x,y) with the given radius
}

// Overloading with different parameter counts
public string format(string value) {
    return value.toUpperCase();
}

public string format(string value, int maxLength) {
    if (value.length <= maxLength) {
        return value;
    }
    return value.substring(0, maxLength) + "...";
}

// Usage
Circle c = new Circle(10);
Rectangle r = new Rectangle(5, 3);
draw(c);            // Calls the first method
draw(r);            // Calls the second method
draw(0, 0, 5);      // Calls the third method
```

### Method Overriding

Overriding allows a subclass to provide a specific implementation of a method that is already defined in its parent class:

```
// Base class with method
public class Animal {
    public virtual void makeSound() {
        print("Generic animal sound");
    }

    // Method marked as final cannot be overridden
    public final void breathe() {
        print("Inhale... Exhale...");
    }
}

// Derived class overriding method
public class Dog extends Animal {
    @override
    public void makeSound() {
        print("Woof woof!");
    }

    // This would cause a compilation error
    // @override
    // public void breathe() { }
}
```

### Method Call

Methods are invoked by name, with arguments matching the parameters.

```
// Calling methods
string message = greet("Alice");
printInfo(1001, "Bob");
int result = calculateSum(5, 7);

// Named arguments for clarity
configure(port: 9090, host: "192.168.1.1");

// Using default parameters
configure();           // Uses default values
configure("127.0.0.1"); // Uses custom host, default port

// Passing arrays to varargs method
int total1 = sum(1, 2, 3, 4, 5);  // 15
int[] values = [10, 20, 30];
int total2 = sum(values);         // 60

// Calling generic method
int first = getFirstElement([1, 2, 3]);       // 1
string name = getFirstElement(["Alice", "Bob"]); // "Alice"

// Method chaining
string processed = input.trim().toUpperCase().replace(" ", "_");

// Using method references
list.forEach(System::println);
```

### Method Parameters

Ouro supports various parameter modifiers for specialized behavior:

```
// Reference parameters (pass by reference)
public void swap(ref int a, ref int b) {
    int temp = a;
    a = b;
    b = temp;
}

// Output parameters
public bool tryParse(string input, out int result) {
    try {
        result = int.parse(input);
        return true;
    } catch (Exception) {
        result = 0;
        return false;
    }
}

// Optional parameters with default values
public void connect(string server, int port = 8080, bool secure = false) {
    // Implementation
}

// Using parameter modifiers
int x = 5, y = 10;
swap(ref x, ref y);  // Now x=10 and y=5

int parsedValue;
if (tryParse("123", out parsedValue)) {
    print("Parsed value: ${parsedValue}");
}
```

### Method Recursion

A method can call itself, creating recursive solutions:

```
// Factorial calculation using recursion
public int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

// Fibonacci sequence using recursion
public int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n-1) + fibonacci(n-2);
}

// Optimized recursive methods with tail recursion
public int factorialTailRec(int n, int accumulator = 1) {
    if (n <= 1) {
        return accumulator;
    }
    return factorialTailRec(n - 1, n * accumulator);
}

// Binary search using recursion
public int binarySearch<T>(T[] sortedArray, T key, int low, int high) where T : IComparable<T> {
    if (high < low) {
        return -1; // Not found
    }

    int mid = (low + high) / 2;
    int comparison = sortedArray[mid].compareTo(key);

    if (comparison < 0) {
        return binarySearch(sortedArray, key, mid + 1, high);
    } else if (comparison > 0) {
        return binarySearch(sortedArray, key, low, mid - 1);
    } else {
        return mid; // Found
    }
}
```

### Local Functions

Methods can contain nested method definitions, useful for encapsulating helper logic:

```
public int processData(int[] data) {
    int result = 0;

    // Local function - only visible inside processData
    int square(int x) {
        return x * x;
    }

    // Using the local function
    for (int value in data) {
        result += square(value);
    }

    return result;
}

// More complex example with closures
public Function<int, int> createMultiplier(int factor) {
    // Local function that uses the outer parameter
    int multiply(int x) {
        return x * factor;
    }

    return multiply; // Return the function itself
}

// Usage
var doubler = createMultiplier(2);
print(doubler(5));  // 10
```

### Asynchronous Methods

Ouro supports asynchronous programming with async/await pattern:

```
// Async method that returns a Task
public async Task<string> fetchDataAsync() {
    print("Fetching data...");
    // Simulated delay
    await Task.delay(2000);
    return "Data loaded";
}

// Using async methods
public async Task processAsync() {
    print("Starting");
    string data = await fetchDataAsync();
    print("Result: ${data}");
}

// Parallel execution of multiple async methods
public async Task processManyAsync() {
    Task<int> task1 = calculateAsync(10);
    Task<int> task2 = calculateAsync(20);

    // Wait for both tasks to complete
    await Task.whenAll(task1, task2);

    // Access results
    int sum = task1.getResult() + task2.getResult();
    print("Total: ${sum}");
}
```

### Extension Methods

Extension methods allow you to add methods to existing types without modifying them:

```
// Extension method for String class
public static class StringExtensions {
    public static int countWords(this string text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }

    public static string truncate(this string text, int maxLength) {
        if (text == null || text.length <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength) + "...";
    }
}

// Usage
string message = "This is a test message";
int wordCount = message.countWords();  // 5
string shortened = message.truncate(7);  // "This is..."
```

### Method Best Practices

1. **Keep methods focused**: Each method should do one thing well.

2. **Use descriptive names**: Method names should clearly describe what they do.

3. **Limit parameters**: Methods with many parameters are hard to use. Consider using object parameters for complex cases.

```
// Too many parameters
public void createUser(string name, string email, int age, string address, string phone, bool isActive);

// Better approach
public void createUser(UserInfo userInfo) {
    // Implementation
}
```

4. **Document complex methods**: Use comments to explain complex logic or parameters.

```
/**
 * Calculates the weighted average of values.
 *
 * @param values The values to average
 * @param weights The weight for each value (must match values length)
 * @return The weighted average
 * @throws IllegalArgumentException if arrays have different lengths
 */
public double weightedAverage(double[] values, double[] weights) {
    // Implementation
}
```

5. **Return early**: Exit methods early for special cases to reduce nesting.

```
// Good practice
public User getUser(int id) {
    if (id <= 0) {
        return null;
    }

    // Continue with normal processing
    return database.findUser(id);
}
```

6. **Avoid side effects**: Methods should be predictable and avoid changing state unexpectedly.
### Lambdas and Functional Interfaces

Ouro supports lambda expressions for concise function definitions. Lambdas are anonymous functions that can be passed around as values, enabling functional programming paradigms and more readable, maintainable code.

#### Basic Lambda Syntax

```
// Basic lambda syntax: (parameters) => expression or block
var add = (int a, int b) => a + b;
var greet = (string name) => "Hello, " + name;
var isPositive = (int x) => x > 0;

// With type inference (parameter types can be omitted when inferable)
var multiply = (a, b) => a * b;

// Multi-line lambda with block body
var process = (data) => {
    var result = preprocess(data);
    return transform(result);
};

// No parameters
var getCurrentTime = () => DateTime.now();

// Single parameter can omit parentheses
var square = x => x * x;
```

#### Functional Interfaces

Functional interfaces are interfaces with a single abstract method, providing a target for lambda expressions:

```
// Defining a functional interface
public interface Calculator {
    int calculate(int a, int b);
}

// Using lambda expressions with the interface
Calculator adder = (a, b) => a + b;
Calculator multiplier = (a, b) => a * b;
Calculator subtractor = (a, b) => a - b;

// Using the lambdas
int sum = adder.calculate(3, 4);      // 7
int product = multiplier.calculate(3, 4); // 12
int difference = subtractor.calculate(10, 4); // 6

// Anonymous implementation of the interface (pre-lambda style)
Calculator divider = new Calculator() {
    @override
    public int calculate(int a, int b) {
        return a / b;
    }
};
```

#### Built-in Functional Interfaces

Ouro provides several built-in functional interfaces for common patterns:

```
// Function<T,R> - takes input of type T, returns value of type R
Function<String, Integer> stringLength = (s) => s.length();
int length = stringLength.apply("Hello");  // 5

// Predicate<T> - takes input of type T, returns boolean
Predicate<Integer> isEven = (n) => n % 2 == 0;
boolean result = isEven.test(4);  // true

// Consumer<T> - takes input of type T, returns nothing
Consumer<String> printer = (s) => print(s);
printer.accept("Hello World");  // Prints: Hello World

// Supplier<T> - takes no input, returns value of type T
Supplier<Double> random = () => Math.random();
double value = random.get();  // Random value between 0.0 and 1.0

// BiFunction<T,U,R> - takes two inputs (T and U), returns R
BiFunction<Integer, Integer, String> formattedSum = (a, b) =>
    "Sum: " + (a + b);
String message = formattedSum.apply(10, 20);  // "Sum: 30"

// Comparator<T> - compares two objects of type T
Comparator<String> byLength = (s1, s2) => s1.length() - s2.length();
```

#### Lambdas as Method Parameters

Passing behavior as parameters enables more flexible and reusable code:

```
// Defining methods that accept functional interfaces
public void processList(List<Integer> numbers, Function<Integer, Integer> transformer) {
    for (int i = 0; i < numbers.size(); i++) {
        numbers[i] = transformer.apply(numbers[i]);
    }
}

public List<T> filter<T>(List<T> items, Predicate<T> condition) {
    List<T> result = new List<T>();
    for (T item in items) {
        if (condition.test(item)) {
            result.add(item);
        }
    }
    return result;
}

// Using the methods with lambdas
List<Integer> values = [1, 2, 3, 4, 5];
processList(values, n => n * n);  // Square each value: [1, 4, 9, 16, 25]

List<Integer> numbers = [1, 2, 3, 4, 5, 6, 7, 8];
List<Integer> evenNumbers = filter(numbers, n => n % 2 == 0);  // [2, 4, 6, 8]
List<Integer> largeNumbers = filter(numbers, n => n > 5);      // [6, 7, 8]
```

#### Method References

Method references provide a shorthand for lambdas that simply call an existing method:

```
// Different types of method references
// Static method reference: ClassName::staticMethod
Function<Integer, String> converter = String::valueOf;
String str = converter.apply(123);  // "123"

// Instance method reference on specific object: instance::method
String prefix = "Hello, ";
Function<String, String> greeter = prefix::concat;
String greeting = greeter.apply("John");  // "Hello, John"

// Instance method reference on parameter: ClassName::instanceMethod
Function<String, Integer> lengthFunc = String::length;
Integer len = lengthFunc.apply("Hello");  // 5

// Constructor reference: ClassName::new
Supplier<ArrayList<String>> listFactory = ArrayList::new;
ArrayList<String> newList = listFactory.get();  // Creates new ArrayList

// Example with collection operations
List<String> names = ["Alice", "Bob", "Charlie", "Diana"];
List<Integer> nameLengths = names.map(String::length);  // [5, 3, 7, 5]
names.forEach(System.out::println);  // Prints each name on new line
```

#### Closures and Variable Capture

Lambdas can capture variables from their enclosing scope:

```
int factor = 10;

// Lambda captures 'factor' from outer scope
Function<Integer, Integer> multiplier = x => x * factor;
int result = multiplier.apply(5);  // 50

// Variables captured by lambdas must be effectively final
// This means they cannot be reassigned after being used in a lambda
List<Runnable> actions = new ArrayList<>();

for (int i = 0; i < 5; i++) {
    final int counter = i;  // Must be final or effectively final
    actions.add(() => {
        print("Counter: " + counter);
    });
}

// Execute the runnables
for (Runnable action : actions) {
    action.run();  // Prints Counter: 0, Counter: 1, etc.
}
```

#### Higher-Order Functions

Functions that accept or return other functions:

```
// Function that returns a function
public Function<Integer, Integer> createMultiplier(int factor) {
    return x => x * factor;
}

Function<Integer, Integer> triple = createMultiplier(3);
int result = triple.apply(4);  // 12

// Function composition
public <A, B, C> Function<A, C> compose(Function<B, C> f, Function<A, B> g) {
    return x => f.apply(g.apply(x));
}

Function<Integer, Integer> square = x => x * x;
Function<Integer, String> toString = x => x.toString();
Function<Integer, String> squareAndConvert = compose(toString, square);

String result = squareAndConvert.apply(5);  // "25"
```

### Extension Methods

Extension methods allow adding functionality to existing types without modifying them. This powerful feature enhances code readability and reuse by extending types you don't control.

#### Basic Syntax

Extension methods are defined as static methods in static classes, with the first parameter marked with `this` keyword indicating the type being extended:

```
// Define a static class to contain extension methods
public static class StringExtensions {
    // Extension method for String class
    public static int countWords(this string text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }

    // Another extension method for String
    public static string truncate(this string text, int maxLength) {
        if (text == null || text.length() <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength) + "...";
    }

    // Extension method with multiple parameters
    public static string repeat(this string text, int count) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < count; i++) {
            builder.append(text);
        }
        return builder.toString();
    }
}

// Usage of extension methods
string sentence = "This is a test sentence";
int wordCount = sentence.countWords();         // 5
string shortened = sentence.truncate(7);       // "This is..."
string repeated = "abc".repeat(3);            // "abcabcabc"
```

#### Extension Methods for Collections

```
public static class CollectionExtensions {
    // Sum values in a collection
    public static int sum(this IEnumerable<int> collection) {
        int total = 0;
        foreach (int item in collection) {
            total += item;
        }
        return total;
    }

    // Find first matching element or default value
    public static T firstOrDefault<T>(this IEnumerable<T> collection, Predicate<T> predicate) {
        foreach (T item in collection) {
            if (predicate(item)) {
                return item;
            }
        }
        return default(T);
    }

    // Map each element to a new value (like map/select in other languages)
    public static List<R> map<T, R>(this List<T> list, Function<T, R> mapper) {
        List<R> result = new List<R>();
        for (T item : list) {
            result.add(mapper.apply(item));
        }
        return result;
    }
}

// Usage
List<int> numbers = [1, 2, 3, 4, 5];
int total = numbers.sum();  // 15

Person person = people.firstOrDefault(p => p.name.equals("John"));

List<String> names = ["Alice", "Bob", "Charlie"];
List<Integer> lengths = names.map(s => s.length());  // [5, 3, 7]
```

#### Extension Methods for Custom Types

```
public class Rectangle {
    public double width;
    public double height;

    public Rectangle(double width, double height) {
        this.width = width;
        this.height = height;
    }

    public double area() {
        return width * height;
    }
}

public static class GeometryExtensions {
    // Add perimeter calculation to Rectangle
    public static double perimeter(this Rectangle rect) {
        return 2 * (rect.width + rect.height);
    }

    // Add method to check if rectangle is a square
    public static bool isSquare(this Rectangle rect) {
        return Math.abs(rect.width - rect.height) < 0.001;
    }

    // Add method to scale rectangle
    public static Rectangle scale(this Rectangle rect, double factor) {
        return new Rectangle(rect.width * factor, rect.height * factor);
    }
}

// Usage
Rectangle rect = new Rectangle(5, 10);
double area = rect.area();         // 50 (original method)
double perim = rect.perimeter();   // 30 (extension method)
bool isSquare = rect.isSquare();   // false (extension method)
Rectangle larger = rect.scale(2);  // 10x20 rectangle (extension method)
```

#### Best Practices for Extension Methods

1. **Use sparingly**: Extension methods should provide genuine utility without cluttering the API.
2. **Namespace appropriately**: Place extension methods in namespaces that make sense for their purpose.
3. **Follow naming conventions**: Extension methods should follow the same naming patterns as regular methods.
4. **Keep them pure**: Avoid side effects in extension methods when possible.
5. **Document clearly**: Document extensions particularly well, as they're less obvious than regular methods.

```
// Import extension method namespace
using StringUtils;  // Contains the string extension methods

public void processText() {
    string text = getUserInput();

    // Now you can use the extension methods
    if (text.wordCount() > 100) {
        print("Text is too long!");
        text = text.truncate(500);
    }
}
```

## Comments

Comments are non-executable text within the code, used for explanation and documentation. They help make code more readable and maintainable.

### Single-line Comments

Single-line comments are used for brief explanations or notes.

```
// This is a single-line comment using double slash
int counter = 0; // Initializing counter to zero

## This is an alternative single-line comment using double hash
let x = 10; # Comment after a statement using single hash
```

### Multi-line Comments

Multi-line comments span multiple lines and are useful for longer explanations, documentation, or temporarily disabling blocks of code.

```
/*
 * This is a traditional C-style multi-line comment.
 * It can span multiple lines and is often used for function
 * or class-level documentation.
 */

##
This is an alternative multi-line comment style.
It can span across multiple lines.
*#

let y = 20;
```

### Documentation Comments

Special comment formats that can be processed by documentation generators:

```
/// <summary>
/// Calculates the sum of two integers.
/// </summary>
/// <param name="a">First number to add</param>
/// <param name="b">Second number to add</param>
/// <returns>The sum of a and b</returns>
public int add(int a, int b) {
    return a + b;
}

/**
 * Retrieves user information from the database.
 *
 * @param userId The unique identifier for the user
 * @return User object containing profile information
 * @throws DatabaseException if connection fails
 */
public User getUserInfo(int userId) {
    // Implementation
}
```

### Comment Best Practices

Comments should explain why the code does something, not what it does (which should be obvious from the code itself):

```
// BAD: Increments counter by 1
counter++;

// GOOD: Increment user login attempt count before checking max attempts
loginAttempts++;

/*
 * We're using Fisher-Yates algorithm here because
 * it provides uniform distribution with O(n) complexity.
 */
public void shuffle(int[] array) {
    // Implementation of Fisher-Yates shuffle
}
```

## Error Handling

Error handling allows programs to gracefully manage unexpected situations.

### Try-Catch-Finally

The try-catch-finally pattern handles exceptions:

```
try {
    // Code that might throw an exception
    int result = riskyOperation();
} catch (SpecificException e) {
    // Handle a specific exception type
    log(e.getMessage());
} catch (Exception e) {
    // Handle any other exception
    reportError(e);
} finally {
    // Code that always runs, whether an exception occurred or not
    cleanupResources();
}
```

### Custom Exceptions

You can define your own exception types:

```
public class InvalidUserException extends Exception {
    private int userId;

    public InvalidUserException(string message, int userId) {
        super(message);
        this.userId = userId;
    }

    public int getUserId() {
        return userId;
    }
}

// Using custom exception
public User findUser(int id) {
    User user = database.getUserById(id);
    if (user == null) {
        throw new InvalidUserException("User not found", id);
    }
    return user;
}
```

### Optional Types

Optional types provide an alternative to null references:

```
// Returning Optional instead of null
public Optional<User> findUser(int id) {
    User user = database.getUserById(id);
    return Optional.ofNullable(user);
}

// Using Optional values
Optional<User> result = findUser(123);
if (result.isPresent()) {
    User user = result.get();
    processUser(user);
} else {
    handleMissingUser();
}

// Optional methods
User user = findUser(123)
    .orElse(new GuestUser());

String name = findUser(123)
    .map(u -> u.getName())
    .orElse("Unknown");
```

### Result Type

Result types explicitly represent success or failure:

```
public Result<User, Error> createUser(UserData data) {
    if (!isValid(data)) {
        return Result.failure(new ValidationError("Invalid data"));
    }

    try {
        User newUser = database.insertUser(data);
        return Result.success(newUser);
    } catch (DatabaseException e) {
        return Result.failure(new DatabaseError(e.getMessage()));
    }
}

// Using Result type
Result<User, Error> result = createUser(userData);
if (result.isSuccess()) {
    User user = result.getValue();
    sendWelcomeEmail(user);
} else {
    Error error = result.getError();
    handleError(error);
}
```

## Examples

A few complete examples demonstrating various syntax features.

### Example 1: Basic Program

```
// This is a simple program in Ouro

public class HelloWorld {
    public static void main(string[] args) { // Entry Point
        print("Hello from Vulcano and the Ouro Team!!!"); // Prints a special message

        let count = 0;
        for (i in 1 ... 5) {
            print("Count: ${i}");  // Prints "Count: " followed by the value of i
        }

        // Demonstrate conditional logic
        int time = getCurrentHour();
        if (time < 12) {
            print("Good morning!");
        } else if (time < 18) {
            print("Good afternoon!");
        } else {
            print("Good evening!");
        }
    }

    // Helper method to get current hour
    private static int getCurrentHour() {
        return DateTime.now().hour;
    }
}
```

### Example 2: Function with Conditional Logic

```
public class NumberAnalyzer {
    // Function that returns an optional boolean
    public bool? checkNumber(int num) {
        if (num > 0) {
            return true;       // Positive number
        } else if (num < 0) {
            return false;      // Negative number
        } else {
            return null;       // Zero is neither positive nor negative
        }
    }

    public void analyzeNumbers() {
        // Test the function with different values
        print(String.valueOf(checkNumber(10)) ?= "Zero");   // Output: true
        print(String.valueOf(checkNumber(-5)) ?= "Zero");   // Output: false
        print(String.valueOf(checkNumber(0)) ?= "Zero");    // Output: Zero, `?=` sets default if null

        // Process a list of numbers
        int[] numbers = [5, -3, 0, 10, -7];

        for (int num in numbers) {
            bool? result = checkNumber(num);
            switch (result) {
                case true:
                    print("${num} is positive");
                    break;
                case false:
                    print("${num} is negative");
                    break;
                case null:
                    print("${num} is zero");
                    break;
            }
        }
    }
}
```

### Example 3: Object-Oriented Program

```
// A simple bank account management system

// Base class for all accounts
public abstract class BankAccount {
    private string accountNumber;
    protected double balance;

    public BankAccount(string accountNumber, double initialBalance) {
        this.accountNumber = accountNumber;
        this.balance = initialBalance;
    }

    public string getAccountNumber() {
        return accountNumber;
    }

    public double getBalance() {
        return balance;
    }

    public abstract bool withdraw(double amount);

    public void deposit(double amount) {
        if (amount > 0) {
            balance += amount;
            print("Deposited ${amount}. New balance: ${balance}");
        } else {
            print("Invalid deposit amount");
        }
    }
}

// Checking account implementation
public class CheckingAccount extends BankAccount {
    private double overdraftLimit;

    public CheckingAccount(string accountNumber, double initialBalance, double overdraftLimit) {
        super(accountNumber, initialBalance);
        this.overdraftLimit = overdraftLimit;
    }

    @override
    public bool withdraw(double amount) {
        if (amount <= 0) {
            print("Invalid withdrawal amount");
            return false;
        }

        if (balance + overdraftLimit >= amount) {
            balance -= amount;
            print("Withdrew ${amount}. New balance: ${balance}");

            if (balance < 0) {
                print("Warning: Account is overdrawn");
            }
            return true;
        } else {
            print("Insufficient funds. Available: ${balance + overdraftLimit}");
            return false;
        }
    }
}

// Savings account implementation
public class SavingsAccount extends BankAccount {
    private double interestRate;

    public SavingsAccount(string accountNumber, double initialBalance, double interestRate) {
        super(accountNumber, initialBalance);
        this.interestRate = interestRate;
    }

    @override
    public bool withdraw(double amount) {
        if (amount <= 0) {
            print("Invalid withdrawal amount");
            return false;
        }

        if (balance >= amount) {
            balance -= amount;
            print("Withdrew ${amount}. New balance: ${balance}");
            return true;
        } else {
            print("Insufficient funds. Available: ${balance}");
            return false;
        }
    }

    public void applyInterest() {
        double interest = balance * interestRate;
        balance += interest;
        print("Applied interest: ${interest}. New balance: ${balance}");
    }
}

// Usage example
public class BankDemo {
    public static void main(string[] args) {
        SavingsAccount savings = new SavingsAccount("SA-1001", 1000.0, 0.05);
        CheckingAccount checking = new CheckingAccount("CA-2001", 500.0, 100.0);

        print("Initial savings balance: ${savings.getBalance()}");
        print("Initial checking balance: ${checking.getBalance()}");

        savings.deposit(200.0);
        checking.withdraw(550.0);

        savings.applyInterest();

        print("Final savings balance: ${savings.getBalance()}");
        print("Final checking balance: ${checking.getBalance()}");
    }
}
```

## Naming Conventions

These are the standard naming conventions in the Ouro language. Following these conventions improves code readability and maintainability.

### Case Types

| Type | Explanation | Examples |
| --- | --- | --- |
| Camel Case | Starts with a lowercase word, and each subsequent word begins with a capital letter. | camelCase, myNumber, someKindOfValue |
| Pascal Case | The first letter of all words are capitalized. | PascalCase, MyNumber, SomeKindOfValue |
| Upper Case | Every letter is capitalized, words are seperated by underscore. | UPPER_CASE, MY_NUMBER, SOME_KIND_OF_VALUE |
| Lower Case | Every letter is lower case, when this case is used the standard is to only use one word. | lower, number, value |
| Snake Case | Words separated by underscores, all lowercase. | snake_case, first_name, items_count |
| Kebab Case | Words separated by hyphens, all lowercase (typically used for filenames). | kebab-case, user-profile, login-page |

### Naming Conventions

| Type | Case | Example |
| --- | --- | --- |
| Class Names | Pascal Case | `UserAccount`, `DatabaseConnection` |
| Interface Names | Pascal Case | `Comparable`, `EventListener` |
| Variable Names | Camel Case | `firstName`, `totalAmount` |
| Method Names | Camel Case | `calculateTotal()`, `getUserInfo()` |
| Enum Names | Upper Case | `COLOR_RED`, `STATUS_PENDING` |
| Enum Values | Upper Case | `NORTH`, `SOUTH`, `EAST`, `WEST` |
| Public Constant Names | Upper Case | `MAX_CONNECTIONS`, `DEFAULT_TIMEOUT` |
| Private Fields | Camel Case | `accountBalance`, `_privateField` |
| Package Names | Lower Case | `utils`, `models` |
| File Names | Pascal Case (matches class name) | `UserAccount.ouro`, `StringUtils.ouro` |
| Parameter Names | Camel Case | `firstName`, `totalAmount` |
| Generic Type Parameters | Single uppercase letter | `T`, `E`, `K`, `V` |

### Additional Naming Guidelines

1. **Meaningful Names**: Choose descriptive names that indicate purpose.
   ```
   // Good
   int customerCount;

   // Bad
   int c;
   ```

2. **Avoid Abbreviations**: Unless they are widely understood.
   ```
   // Good
   UserAuthentication userAuth;

   // Bad
   UsrAuthMgr uam;
   ```

3. **Boolean Variables**: Should ask a question.
   ```
   bool isActive;
   bool hasPermission;
   ```

4. **Collections**: Should use plural names.
   ```
   List<User> users;
   Map<string, Product> products;
   ```

5. **Method Names**: Should be verbs or verb phrases.
   ```
   void saveUser();
   bool isValid();
   User getById(int id);
   ```

## Advanced Features

### Asynchronous Programming

Ouro supports asynchronous programming with async/await:

```
public async Task<string> fetchDataAsync() {
    HttpClient client = new HttpClient();
    string response = await client.getStringAsync("https://api.example.com/data");
    return processData(response);
}

public async void processAsync() {
    print("Starting...");
    string result = await fetchDataAsync();
    print("Result: ${result}");
}
```

### Reflection

Reflection allows code to examine and modify its own structure and behavior at runtime:

```
public void inspectObject(object obj) {
    Type type = obj.getType();
    print("Class name: ${type.getName()}");

    print("Properties:");
    for (Property prop in type.getProperties()) {
        string name = prop.getName();
        object value = prop.getValue(obj);
        print("- ${name}: ${value}");
    }

    print("Methods:");
    for (Method method in type.getMethods()) {
        print("- ${method.getName()}");
    }
}
```

### Operator Overloading

Custom types can define their own behavior for operators:

```
public class Vector2 {
    public double x;
    public double y;

    public Vector2(double x, double y) {
        this.x = x;
        this.y = y;
    }

    // Overload + operator
    public static Vector2 operator +(Vector2 a, Vector2 b) {
        return new Vector2(a.x + b.x, a.y + b.y);
    }

    // Overload * operator for scalar multiplication
    public static Vector2 operator *(Vector2 v, double scalar) {
        return new Vector2(v.x * scalar, v.y * scalar);
    }

    @override
    public string toString() {
        return "(${x}, ${y})";
    }
}

// Usage
Vector2 v1 = new Vector2(1.0, 2.0);
Vector2 v2 = new Vector2(3.0, 4.0);
Vector2 sum = v1 + v2;         // (4.0, 6.0)
Vector
Vector2 scaled = v1 * 2.0;     // (2.0, 4.0)
```

### Pattern Matching

Advanced pattern matching for more expressive conditional logic:

```
object shape = getShape();

string description = switch (shape) {
    case Circle c when c.radius < 10 => "Small circle";
    case Circle c => "Circle with radius ${c.radius}";
    case Rectangle r when r.width == r.height => "Square: ${r.width}×${r.height}";
    case Rectangle r => "Rectangle: ${r.width}×${r.height}";
    case null => "No shape";
    default => "Unknown shape type";
};
```

### Memory Management

Ouro provides tools for managing memory efficiently:

```
// Using a scoped block for manual resource management
using (Resource resource = new Resource()) {
    resource.process();
}  // resource is automatically disposed at this point

// Weak references (don't prevent garbage collection)
WeakReference<CacheItem> weakRef = new WeakReference<CacheItem>(item);
if (weakRef.tryGetTarget(out CacheItem? target)) {
    // Use target if it hasn't been garbage collected
}

// Memory-efficient data structures
struct Point {
    public int x;
    public int y;
}  // Allocated on stack instead of heap when possible
```

## Switch Statements

Switch statements provide a cleaner way to handle multiple conditions based on a single expression. They are particularly useful when comparing a variable against a series of values.

### Basic Syntax

```
switch (expression) {
    case value1:
        // code if expression equals value1
        break;
    case value2:
        // code if expression equals value2
        break;
    default:
        // code if no cases match
        break;
}
```

### Examples with Different Data Types

```
// Switch with string
switch (dayOfWeek) {
    case "Monday":
        print("Start of work week");
        break;
    case "Tuesday":
    case "Wednesday":
    case "Thursday":
        print("Mid-week");
        break;
    case "Friday":
        print("End of work week");
        break;
    case "Saturday":
    case "Sunday":
        print("Weekend!");
        break;
    default:
        print("Invalid day");
        break;
}

// Switch with integer
switch (statusCode) {
    case 200:
        print("OK");
        break;
    case 404:
        print("Not Found");
        break;
    case 500:
        print("Server Error");
        break;
    default:
        print("Unknown Status Code");
        break;
}

// Switch with enum
enum Direction { NORTH, SOUTH, EAST, WEST }

Direction userDirection = Direction.NORTH;

switch (userDirection) {
    case NORTH:
        print("Heading north to the mountains");
        break;
    case SOUTH:
        print("Heading south to the beach");
        break;
    case EAST:
        print("Heading east to the forest");
        break;
    case WEST:
        print("Heading west to the desert");
        break;
}

// Switch with pattern matching
switch (shape) {
    case Circle c:
        print("Found a circle with radius: ${c.radius}");
        break;
    case Rectangle r:
        print("Found a rectangle: ${r.width}×${r.height}");
        break;
    case Triangle t when t.isEquilateral():
        print("Found an equilateral triangle");
        break;
    case Triangle t:
        print("Found a triangle");
        break;
    default:
        print("Unknown shape");
        break;
}

```

## Cross-Platform Language Compiler Migration Guide

### Overview

This section provides comprehensive guidelines for migrating cross-platform language compilers to Swift 6, with a focus on modern features, type safety, and platform compatibility.

### Migration Goals

1. **Swift 6 Compatibility**
   - Adopt new type system features
   - Implement strict concurrency model
   - Utilize modern memory management
   - Support new platform APIs

2. **Modern Concurrency**
   - Implement async/await patterns
   - Use structured concurrency
   - Adopt actor-based isolation
   - Support task management

3. **Type System Improvements**
   - Enhanced generic constraints
   - Improved type inference
   - Better null safety
   - Protocol composition

4. **Platform Support**
   - Unified platform abstractions
   - Modern API availability
   - Cross-platform consistency
   - Platform-specific optimizations

### Migration Process

#### 1. Compiler Infrastructure Updates

```swift
// Before: Traditional compiler pipeline
public class Compiler {
    private func parse(source: String) -> AST {
        // Traditional parsing
    }
    
    private func typeCheck(ast: AST) -> TypedAST {
        // Basic type checking
    }
}

// After: Modern async compiler pipeline
public actor Compiler {
    private func parse(source: String) async throws -> AST {
        // Async parsing with modern error handling
    }
    
    private func typeCheck(ast: AST) async throws -> TypedAST {
        // Concurrent type checking
    }
    
    public func compile(source: String) async throws -> CompiledOutput {
        let ast = try await parse(source: source)
        let typedAST = try await typeCheck(ast: ast)
        return try await generateCode(from: typedAST)
    }
}
```

#### 2. Modern Concurrency Implementation

```swift
// Before: Traditional threading
public class CodeGenerator {
    private let queue = DispatchQueue(label: "codegen")
    
    func generateCode(from ast: AST) {
        queue.async {
            // Code generation
        }
    }
}

// After: Modern concurrency
public actor CodeGenerator {
    private var compilationTasks: [Task<CompiledOutput, Error>] = []
    
    func generateCode(from ast: AST) async throws -> CompiledOutput {
        // Structured concurrency for code generation
        async let optimized = optimize(ast)
        async let validated = validate(ast)
        
        let (optResult, valResult) = try await (optimized, validated)
        return try await finalize(optimized: optResult, validated: valResult)
    }
    
    private func optimize(_ ast: AST) async throws -> OptimizedAST {
        // Concurrent optimization passes
    }
}
```

#### 3. Type System Modernization

```swift
// Before: Basic type system
protocol Type {
    var name: String { get }
}

// After: Enhanced type system
protocol Type {
    associatedtype Context
    var name: String { get }
    var genericParameters: [GenericParameter] { get }
    var constraints: [TypeConstraint] { get }
    
    func isSubtype(of other: any Type) async -> Bool
    func resolve(in context: Context) async throws -> ResolvedType
}

// Modern type constraints
struct TypeConstraint {
    let lhs: any Type
    let rhs: any Type
    let relation: ConstraintRelation
    
    enum ConstraintRelation {
        case conformsTo
        case equalTo
        case subtypeOf
    }
}
```

#### 4. Platform Abstraction Layer

```swift
// Before: Platform-specific code
#if os(macOS)
    func compileForMacOS() { }
#elseif os(Linux)
    func compileForLinux() { }
#endif

// After: Unified platform abstraction
public protocol PlatformTarget {
    var name: String { get }
    var architecture: Architecture { get }
    var osVersion: OperatingSystemVersion { get }
    
    func generateCode(for ast: AST) async throws -> PlatformSpecificCode
    func optimize(for platform: PlatformTarget) async throws -> OptimizedCode
}

public struct CrossPlatformCompiler {
    private let targets: [PlatformTarget]
    
    public func compile(source: String, for targets: [PlatformTarget]) async throws -> [PlatformSpecificBinary] {
        let ast = try await parse(source: source)
        return try await withThrowingTaskGroup(of: PlatformSpecificBinary.self) { group in
            for target in targets {
                group.addTask {
                    let code = try await target.generateCode(for: ast)
                    return try await target.optimize(for: target)
                }
            }
            return try await group.collect()
        }
    }
}
```

### Migration Checklist

1. **Compiler Infrastructure**
   - [ ] Update build system to Swift 6
   - [ ] Implement modern error handling
   - [ ] Adopt async/await for compilation pipeline
   - [ ] Update dependency management

2. **Type System**
   - [ ] Implement new type constraints
   - [ ] Update generic system
   - [ ] Add protocol composition
   - [ ] Enhance type inference

3. **Concurrency**
   - [ ] Migrate to structured concurrency
   - [ ] Implement actor-based isolation
   - [ ] Add task management
   - [ ] Update thread safety

4. **Platform Support**
   - [ ] Create platform abstraction layer
   - [ ] Implement cross-platform APIs
   - [ ] Add platform-specific optimizations
   - [ ] Update platform detection

5. **Testing**
   - [ ] Add concurrency tests
   - [ ] Implement platform-specific tests
   - [ ] Add type system tests
   - [ ] Create migration tests

### Best Practices

1. **Incremental Migration**
   - Migrate one component at a time
   - Maintain backward compatibility
   - Use feature flags for new functionality
   - Test thoroughly after each step

2. **Concurrency Safety**
   - Use actors for shared state
   - Implement proper isolation
   - Handle cancellation properly
   - Manage task priorities

3. **Type Safety**
   - Leverage new type system features
   - Use strict null safety
   - Implement proper generic constraints
   - Add comprehensive type checking

4. **Platform Compatibility**
   - Use unified abstractions
   - Implement platform-specific optimizations
   - Handle platform differences gracefully
   - Maintain consistent behavior

5. **Security**
   - Sandbox only needed resources via entitlements.  
   - Validate all inputs to prevent injection:
   ```swift
   public enum ValidationError: Error {
     case invalidCharacters
   }

   public func validateFilename(_ name: String) throws {
     let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_."))
     if name.rangeOfCharacter(from: allowed.inverted) != nil {
       throw ValidationError.invalidCharacters
     }
   }
   ```
   - Apply least-privilege principles for file and network access.

6. **Performance**
   - Profile early with Xcode Instruments to find hot paths.  
   - Favor cache-friendly structures (contiguous arrays, arenas):
   ```swift
   var buffer = [UInt8](repeating: 0, count: 16_384)
   for i in 0..<buffer.count {
     buffer[i] = UInt8(i & 0xFF)
   }
   ```
   - Batch I/O operations and minimize system calls. Use `TaskGroup` for parallel workloads.

### Troubleshooting Guide

1. **Concurrency Issues**
   ```swift
   // Problem: Data races in compiler
   // Solution: Use actors for shared state
   public actor CompilerState {
       private var compilationUnits: [String: CompilationUnit] = [:]
       
       func addUnit(_ unit: CompilationUnit) {
           compilationUnits[unit.id] = unit
       }
   }
   ```

2. **Type System Errors**
   ```swift
   // Problem: Generic constraint violations
   // Solution: Use modern type constraints
   protocol Compilable {
       associatedtype Output
       func compile() async throws -> Output
   }
   
   struct TypeChecker<T: Compilable> {
       func check(_ input: T) async throws -> T.Output {
           return try await input.compile()
       }
   }
   ```

3. **Platform Compatibility**
   ```swift
   // Problem: Platform-specific code
   // Solution: Use platform abstraction
   public struct PlatformAbstraction {
       static func getCompiler(for platform: PlatformTarget) -> any Compiler {
           switch platform {
           case is MacOSPlatform:
               return MacOSCompiler()
           case is LinuxPlatform:
               return LinuxCompiler()
           default:
               return GenericCompiler()
           }
       }
   }
   ```

### Migration Examples

1. **Lexer Migration**
```swift
// Before: Synchronous lexer
public class Lexer {
    func tokenize(_ input: String) -> [Token] {
        // Synchronous tokenization
    }
}

// After: Async lexer with modern features
public actor Lexer {
    private let source: String
    private var position: String.Index
    
    public init(source: String) {
        self.source = source
        self.position = source.startIndex
    }
    
    public func tokenize() async throws -> [Token] {
        var tokens: [Token] = []
        while let token = try await nextToken() {
            tokens.append(token)
        }
        return tokens
    }
    
    private func nextToken() async throws -> Token? {
        // Modern async tokenization
    }
}
```

2. **Parser Migration**
```swift
// Before: Traditional parser
public class Parser {
    func parse(_ tokens: [Token]) -> AST {
        // Synchronous parsing
    }
}

// After: Modern async parser
public actor Parser {
    private let tokens: [Token]
    private var currentIndex: Int
    
    public init(tokens: [Token]) {
        self.tokens = tokens
        self.currentIndex = 0
    }
    
    public func parse() async throws -> AST {
        return try await parseProgram()
    }
    
    private func parseProgram() async throws -> ProgramNode {
        // Modern async parsing with error handling
    }
}
```

3. **Code Generator Migration**
```swift
// Before: Basic code generation
public class CodeGenerator {
    func generate(_ ast: AST) -> String {
        // Synchronous code generation
    }
}

// After: Modern code generation
public actor CodeGenerator {
    private let optimizationLevel: OptimizationLevel
    private let target: PlatformTarget
    
    public func generate(from ast: AST) async throws -> CompiledOutput {
        let optimized = try await optimize(ast)
        let validated = try await validate(optimized)
        return try await emitCode(for: validated)
    }
    
    private func optimize(_ ast: AST) async throws -> OptimizedAST {
        // Modern optimization with concurrency
    }
}
```

### Performance Considerations

1. **Concurrency Optimization**
   - Use task groups for parallel processing
   - Implement proper cancellation
   - Manage memory efficiently
   - Handle resource contention

2. **Type System Performance**
   - Optimize type inference
   - Cache type resolutions
   - Implement efficient constraints
   - Use modern type erasure

3. **Platform-Specific Optimizations**
   - Use platform-specific intrinsics
   - Implement proper memory alignment
   - Optimize for target architecture
   - Handle platform differences

### Testing Strategy

1. **Unit Tests**
```swift
final class CompilerTests: XCTestCase {
    func testAsyncCompilation() async throws {
        let compiler = Compiler()
        let source = "let x = 42"
        let output = try await compiler.compile(source: source)
        XCTAssertNotNil(output)
    }
    
    func testConcurrentCompilation() async throws {
        let compiler = Compiler()
        let sources = ["let x = 1", "let y = 2", "let z = 3"]
        
        let outputs = try await withThrowingTaskGroup(of: CompiledOutput.self) { group in
            for source in sources {
                group.addTask {
                    return try await compiler.compile(source: source)
                }
            }
            return try await group.collect()
        }
        
        XCTAssertEqual(outputs.count, sources.count)
    }
}
```

2. **Integration Tests**
```swift
final class CrossPlatformTests: XCTestCase {
    func testCrossPlatformCompilation() async throws {
        let compiler = CrossPlatformCompiler()
        let source = "let x = 42"
        let targets = [MacOSPlatform(), LinuxPlatform()]
        
        let binaries = try await compiler.compile(source: source, for: targets)
        XCTAssertEqual(binaries.count, targets.count)
        
        for (binary, target) in zip(binaries, targets) {
            XCTAssertTrue(binary.isCompatible(with: target))
        }
    }
}
```

### Documentation

1. **API Documentation**
```swift
/// A modern cross-platform compiler implementation.
///
/// This compiler supports:
/// - Async/await based compilation pipeline
/// - Modern type system features
/// - Cross-platform code generation
/// - Structured concurrency
public actor CrossPlatformCompiler {
    /// Compiles source code for multiple platforms concurrently.
    ///
    /// - Parameters:
    ///   - source: The source code to compile
    ///   - targets: The target platforms for compilation
    /// - Returns: An array of platform-specific binaries
    /// - Throws: CompilationError if compilation fails
    public func compile(
        source: String,
        for targets: [PlatformTarget]
    ) async throws -> [PlatformSpecificBinary]
}
```

2. **Migration Guide**
```markdown
# Cross-Platform Compiler Migration Guide

## Overview
This guide provides step-by-step instructions for migrating
existing compilers to Swift 6 with modern features.

## Steps
1. Update build system
2. Implement async/await
3. Adopt modern type system
4. Add platform abstractions
5. Update testing infrastructure

## Examples
See the examples directory for complete migration examples.
```

### Conclusion

The migration to Swift 6 for cross-platform language compilers involves several key aspects:
1. Modern concurrency with async/await
2. Enhanced type system features
3. Platform abstraction layer
4. Improved testing infrastructure
5. Comprehensive documentation

By following this guide and implementing the provided examples, you can successfully migrate your compiler to Swift 6 while maintaining cross-platform compatibility and modern language features.

### Codebase-Specific Migration Examples

#### 1. Macro Migration (LavaMacros)

```swift
// Before: Traditional macro implementation
public struct ThreadMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Legacy GCD-based implementation
        return [
            """
            func runOnMainThread(_ block: @escaping () -> Void) {
                DispatchQueue.main.async {
                    block()
                }
            }
            """
        ]
    }
}

// After: Modern Swift 6 macro with async/await
public struct ThreadMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Modern async/await implementation
        return [
            """
            @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
            func runOnMainThreadAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
                try await MainActor.run {
                    try await operation()
                }
            }
            """,
            // Add structured concurrency support
            """
            @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
            func withTaskGroup<T>(_ operation: @escaping (inout TaskGroup<T>) async throws -> Void) async throws -> [T] {
                try await withThrowingTaskGroup(of: T.self) { group in
                    try await operation(&group)
                    return try await group.collect()
                }
            }
            """
        ]
    }
}
```

#### 2. Lexer Migration (OuroLangCore)

```swift
// Before: Synchronous lexer implementation
public class Lexer {
    private let source: String
    private var tokens: [Token] = []
    private var startIndex: String.Index
    private var currentIndex: String.Index
    
    public func scanTokens() -> [Token] {
        while !isAtEnd() {
            startIndex = currentIndex
            scanToken()
        }
        return tokens
    }
}

// After: Modern async lexer with improved type safety
public actor Lexer {
    private let source: String
    private var tokens: [Token] = []
    private var startIndex: String.Index
    private var currentIndex: String.Index
    private var line: Int = 1
    private var column: Int = 1
    
    public init(source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self.currentIndex = source.startIndex
    }
    
    public func scanTokens() async throws -> [Token] {
        // Use structured concurrency for token scanning
        try await withThrowingTaskGroup(of: Token.self) { group in
            while !isAtEnd() {
                startIndex = currentIndex
                group.addTask {
                    try await self.scanToken()
                }
            }
            return try await group.collect()
        }
    }
    
    private func scanToken() async throws -> Token {
        // Modern token scanning with improved error handling
        let c = advance()
        switch c {
        case "(": return Token(type: .leftParen, lexeme: "(", line: line, column: column)
        case ")": return Token(type: .rightParen, lexeme: ")", line: line, column: column)
        // ... other cases
        default:
            if isDigit(c) {
                return try await scanNumber()
            } else if isAlpha(c) {
                return try await scanIdentifier()
            }
            throw LexerError.invalidCharacter(c, line: line, column: column)
        }
    }
}
```

#### 3. Platform-Specific Optimizations

```swift
// Platform abstraction for OuroLang compiler
public protocol PlatformTarget {
    var name: String { get }
    var architecture: Architecture { get }
    var osVersion: OperatingSystemVersion { get }
    
    // Modern async code generation
    func generateCode(for ast: AST) async throws -> PlatformSpecificCode
    func optimize(for platform: PlatformTarget) async throws -> OptimizedCode
}

// macOS-specific implementation
public struct MacOSPlatform: PlatformTarget {
    public let name = "macOS"
    public let architecture: Architecture
    public let osVersion: OperatingSystemVersion
    
    public func generateCode(for ast: AST) async throws -> PlatformSpecificCode {
        // Use modern Swift concurrency for code generation
        async let optimized = optimize(ast)
        async let validated = validate(ast)
        
        let (optResult, valResult) = try await (optimized, validated)
        return try await emitCode(for: optResult, validated: valResult)
    }
    
    private func optimize(_ ast: AST) async throws -> OptimizedAST {
        // Platform-specific optimizations
        if #available(macOS 12.0, *) {
            return try await withTaskGroup(of: OptimizedAST.self) { group in
                // Parallel optimization passes
                group.addTask { try await optimizeMemory(ast) }
                group.addTask { try await optimizePerformance(ast) }
                return try await group.collect().first ?? ast
            }
        } else {
            return try await optimizeLegacy(ast)
        }
    }
}
```

#### 4. Performance Optimizations

```swift
// Modern performance optimizations for OuroLang compiler
public actor CompilerOptimizer {
    private var optimizationCache: [String: OptimizedAST] = [:]
    private let optimizationLevel: OptimizationLevel
    
    public func optimize(_ ast: AST) async throws -> OptimizedAST {
        // Use modern Swift concurrency for parallel optimization
        if let cached = optimizationCache[ast.id] {
            return cached
        }
        
        let optimized = try await withThrowingTaskGroup(of: OptimizedAST.self) { group in
            // Parallel optimization passes
            group.addTask { try await optimizeMemory(ast) }
            group.addTask { try await optimizePerformance(ast) }
            group.addTask { try await optimizeSize(ast) }
            
            // Collect and combine results
            let results = try await group.collect()
            return try await combineOptimizations(results)
        }
        
        optimizationCache[ast.id] = optimized
        return optimized
    }
    
    private func optimizeMemory(_ ast: AST) async throws -> OptimizedAST {
        // Memory optimization using modern Swift features
        if #available(macOS 12.0, iOS 15.0, *) {
            return try await withTaskGroup(of: OptimizedAST.self) { group in
                // Parallel memory optimization passes
                group.addTask { try await optimizeAllocations(ast) }
                group.addTask { try await optimizeReferences(ast) }
                return try await combineMemoryOptimizations(group)
            }
        } else {
            return try await optimizeMemoryLegacy(ast)
        }
    }
}
```

### Testing Strategy for Codebase

```swift
// Modern testing approach for OuroLang compiler
final class CompilerTests: XCTestCase {
    func testAsyncCompilation() async throws {
        let compiler = Compiler()
        let source = """
        func main() {
            let x = 42
            print(x)
        }
        """
        
        // Test modern async compilation
        let output = try await compiler.compile(source: source)
        XCTAssertNotNil(output)
        
        // Test platform-specific compilation
        let platforms: [PlatformTarget] = [
            MacOSPlatform(architecture: .arm64, osVersion: .init(major: 12, minor: 0)),
            LinuxPlatform(architecture: .x86_64, osVersion: .init(major: 20, minor: 4))
        ]
        
        let binaries = try await compiler.compile(source: source, for: platforms)
        XCTAssertEqual(binaries.count, platforms.count)
    }
    
    func testConcurrentOptimization() async throws {
        let optimizer = CompilerOptimizer(optimizationLevel: .aggressive)
        let ast = try await parseTestAST()
        
        // Test parallel optimization
        let optimized = try await optimizer.optimize(ast)
        XCTAssertNotNil(optimized)
        
        // Verify optimization results
        let metrics = try await optimized.measurePerformance()
        XCTAssertLessThan(metrics.memoryUsage, 100_000_000) // 100MB
        XCTAssertLessThan(metrics.executionTime, 1.0) // 1 second
    }
    
    func testCrossPlatformCompatibility() async throws {
        let compiler = CrossPlatformCompiler()
        let testCases = [
            ("simple.ouro", "Simple program compilation"),
            ("complex.ouro", "Complex program with async/await"),
            ("error.ouro", "Error handling and recovery")
        ]
        
        for (filename, description) in testCases {
            let source = try loadTestFile(filename)
            let platforms = [MacOSPlatform(), LinuxPlatform(), WindowsPlatform()]
            
            let results = try await withThrowingTaskGroup(of: (PlatformTarget, CompiledOutput).self) { group in
                for platform in platforms {
                    group.addTask {
                        let output = try await compiler.compile(source: source, for: platform)
                        return (platform, output)
                    }
                }
                return try await group.collect()
            }
            
            // Verify cross-platform compatibility
            for (platform, output) in results {
                XCTAssertTrue(output.isValid, "\(description) failed on \(platform.name)")
                XCTAssertTrue(output.isCompatible(with: platform), "\(description) incompatible with \(platform.name)")
            }
        }
    }
}
```

### Platform-Specific Migration Guidelines

1. **macOS/iOS Migration**
   ```swift
   // Modern platform-specific features
   @available(macOS 12.0, iOS 15.0, *)
   public struct ModernPlatformFeatures {
       // Use modern concurrency
       public func compileWithConcurrency(_ source: String) async throws -> CompiledOutput {
           try await withThrowingTaskGroup(of: CompiledOutput.self) { group in
               // Parallel compilation passes
               group.addTask { try await parse(source) }
               group.addTask { try await typeCheck(source) }
               return try await combineResults(group)
           }
       }
       
       // Use modern memory management
       public func optimizeMemory(_ ast: AST) async throws -> OptimizedAST {
           // Use modern memory management features
           return try await withTaskGroup(of: OptimizedAST.self) { group in
               group.addTask { try await optimizeAllocations(ast) }
               group.addTask { try await optimizeReferences(ast) }
               return try await combineOptimizations(group)
           }
       }
   }
   ```

2. **Linux Migration**
   ```swift
   // Linux-specific optimizations
   public struct LinuxPlatformFeatures {
       public func compileForLinux(_ source: String) async throws -> LinuxBinary {
           // Use Linux-specific optimizations
           let ast = try await parse(source)
           let optimized = try await optimizeForLinux(ast)
           return try await generateLinuxBinary(optimized)
       }
       
       private func optimizeForLinux(_ ast: AST) async throws -> OptimizedAST {
           // Linux-specific optimization passes
           return try await withTaskGroup(of: OptimizedAST.self) { group in
               group.addTask { try await optimizeForELF(ast) }
               group.addTask { try await optimizeForLinuxKernel(ast) }
               return try await combineLinuxOptimizations(group)
           }
       }
   }
   ```

3. **Windows Migration**
   ```swift
   // Windows-specific features
   public struct WindowsPlatformFeatures {
       public func compileForWindows(_ source: String) async throws -> WindowsBinary {
           // Use Windows-specific features
           let ast = try await parse(source)
           let optimized = try await optimizeForWindows(ast)
           return try await generateWindowsBinary(optimized)
       }
       
       private func optimizeForWindows(_ ast: AST) async throws -> OptimizedAST {
           // Windows-specific optimization passes
           return try await withTaskGroup(of: OptimizedAST.self) { group in
               group.addTask { try await optimizeForPE(ast) }
               group.addTask { try await optimizeForWindowsAPI(ast) }
               return try await combineWindowsOptimizations(group)
           }
       }
   }
   ```

### Performance Optimization Strategies

1. **Memory Management**
   ```swift
   public actor MemoryOptimizer {
       private var cache: [String: OptimizedAST] = [:]
       
       public func optimize(_ ast: AST) async throws -> OptimizedAST {
           // Use modern memory management
           if let cached = cache[ast.id] {
               return cached
           }
           
           let optimized = try await withTaskGroup(of: OptimizedAST.self) { group in
               // Parallel memory optimization
               group.addTask { try await optimizeStackUsage(ast) }
               group.addTask { try await optimizeHeapUsage(ast) }
               return try await combineMemoryOptimizations(group)
           }
           
           cache[ast.id] = optimized
           return optimized
       }
   }
   ```

2. **Concurrency Optimization**
   ```swift
   public actor ConcurrencyOptimizer {
       public func optimize(_ ast: AST) async throws -> OptimizedAST {
           // Use modern concurrency features
           return try await withThrowingTaskGroup(of: OptimizedAST.self) { group in
               // Parallel optimization passes
               group.addTask { try await optimizeTaskCreation(ast) }
               group.addTask { try await optimizeActorUsage(ast) }
               group.addTask { try await optimizeAsyncAwait(ast) }
               return try await combineConcurrencyOptimizations(group)
           }
       }
   }
   ```

3. **Platform-Specific Optimizations**
   ```swift
   public actor PlatformOptimizer {
       public func optimize(_ ast: AST, for platform: PlatformTarget) async throws -> OptimizedAST {
           // Use platform-specific optimizations
           return try await withTaskGroup(of: OptimizedAST.self) { group in
               // Platform-specific optimization passes
               group.addTask { try await platform.optimizeArchitecture(ast) }
               group.addTask { try await platform.optimizeOSFeatures(ast) }
               return try await platform.combineOptimizations(group)
           }
       }
   }
   ```

### Component-Specific Migration Examples

#### OuroLangLSP

```swift
// Example of using async/await in LSP request handling
public actor LanguageServer {
    public func handleRequest(_ request: Request) async throws -> Response {
        // Use async/await for non-blocking request processing
        return try await processRequest(request)
    }
}
```

#### OuroTranspiler

```swift
// Example of optimizing transpiler with Swift concurrency
public actor Transpiler {
    public func transpile(source: String) async throws -> TranspiledOutput {
        // Use structured concurrency for efficient transpilation
        async let parsed = parse(source)
        async let transformed = transform(parsed)
        return try await generateCode(from: transformed)
    }
}
```

#### OuroLangCore

```swift
// Example of using Swift's type system improvements in AST
public struct ASTNode: Hashable, Codable, Sendable {
    // Use existential any for flexible type handling
    public var type: any TypeProtocol
}
```

#### OuroCompiler

```swift
// Example of using strict concurrency in compiler
public actor Compiler {
    public func compile(source: String) async throws -> CompiledOutput {
        // Use actors to ensure thread-safe compilation
        let ast = try await parse(source)
        return try await generateCode(from: ast)
    }
}
```

### Expanded Testing Section

#### Test Cases for Swift 6 Features

```swift
final class Swift6FeatureTests: XCTestCase {
    func testAsyncAwait() async throws {
        // Test async/await functionality
        let result = try await someAsyncFunction()
        XCTAssertEqual(result, expectedValue)
    }

    func testStructuredConcurrency() async throws {
        // Test structured concurrency with task groups
        let results = try await withThrowingTaskGroup(of: Int.self) { group in
            for i in 0..<10 {
                group.addTask { i * 2 }
            }
            return try await group.collect()
        }
        XCTAssertEqual(results, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
    }
}
```

### Platform-Specific Migration Guidelines

#### macOS/iOS

```swift
// Use platform-specific APIs with Swift 6
@available(macOS 12.0, iOS 15.0, *)
public struct PlatformFeatures {
    public func useModernAPIs() async throws {
        // Example of using modern APIs
        let data = try await URLSession.shared.data(from: someURL)
    }
}
```

#### Linux

```swift
// Optimize for Linux-specific features
public struct LinuxOptimizations {
    public func optimizeForLinux() async throws {
        // Use Linux-specific system calls
        let result = try await someLinuxSpecificFunction()
    }
}
```

#### Windows

```swift
// Use Windows-specific optimizations
public struct WindowsFeatures {
    public func optimizeForWindows() async throws {
        // Example of using Windows APIs
        let result = try await someWindowsSpecificFunction()
    }
}
```

### Performance Optimization Strategies

#### Memory Management

```swift
public actor MemoryManager {
    public func optimizeMemoryUsage() async throws {
        // Use Swift's memory management features
        let optimizedData = try await optimizeDataStructure()
    }
}
```

#### Concurrency Optimization

```swift
public actor ConcurrencyManager {
    public func optimizeConcurrency() async throws {
        // Use Swift's concurrency model for optimization
        let result = try await performConcurrentTasks()
    }
}
```

#### Platform-Specific Optimizations

```swift
public actor PlatformOptimizer {
    public func optimizeForPlatform() async throws {
        // Use platform-specific optimizations
        let optimizedResult = try await optimizeForCurrentPlatform()
    }
}
```

## .ouro Example Scripts

### 1. Codebase Integration

```ouro
// Import core modules from the codebase
import "Lava"
import "OuroLangCore"

func main() {
    let users = ["Alice", "Bob", "Charlie"]
    users.forEach(user => print("Hello, ${user}!"))
}
```

### 2. Linter Errors

```ouro
// This example shows common linter errors detected
func calculateSum(a, b) { // Error: Missing type annotations for parameters
    return a + b
}

missingVar = 10 // Error: 'missingVar' is not declared
```

### 3. Web Example

```ouro
// Simple HTTP server example
import "WebServer"

async func startServer() {
    let server = WebServer(port: 8080)
    await server.route("/", req => {
        return "Hello, .ouro Web!"
    })
    await server.listen()
}

startServer()
```

### 4. Recent Changes

```ouro
// Demonstrates new 'async' and 'await' syntax from recent updates
async func fetchData() {
    let data = await HttpClient.get("https://api.example.com/data")
    print("Received: ${data}")
}

fetchData()
```
