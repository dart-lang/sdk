# Prototype Syntax for Generic Methods

**Note:** This documents the deprecated comment-based syntax for generic
methods. New code should use the [much better real syntax][real]. This document
is preserved in case you run into existing code still using the old syntax.

[real]: GENERIC_METHODS.md

---

Generic methods are a [proposed addition to the Dart language](https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md).

This is a summary of the current (as of January 2016) comment-based generic
method syntax supported by the analyzer strong mode and the Dart Dev Compiler.
The comment-based syntax essentially uses the proposed actual generic method
syntax, but wraps it in comments.  This allows developers to experiment with
generic methods while still ensuring that their code runs on all platforms while
generic methods are still being evaluated for inclusion into the language.

## Declaring generic method parameters

Generic method parameters are listed using a block comment after the method or
function name, inside of angle brackets.

```dart
// This declares a function which takes two unused generic method parameters
int f/*<S, T>*/(int x) => 3;
```

As with classes, you can put bounds on type parameters.

```dart
// This declares a function which takes two unused generic method parameters
// The first parameter (S) must extend num
// The second parameter (T) must extend List<S>
int f/*<S extends num, T extends List<S>>*/(int x) => 3;
```

Class methods (instance and static) can be declared to take generic parameters
in the same way.

```dart
class C {
  static int f/*<S, T>*/(int x) => 3;
  int m/*<S, T>*/(int x) => 3;
}
```

Function typed parameters, local functions, and function expressions can also be
declared to take generic parameters.

```dart
// foo takes a generic method as a parameter
void foo(int f/*<S>*/(int x)) {}

// foo declares a local generic function
void foo() {
  int f/*<S>*/(int x) => 3;
  return;
}

// foo binds a generic function expression to a local variable.
void foo() {
  var x = /*<S>*/(int x) => x;
}
```

We do not currently support a way to declare a function as returning a generic
function.  This will eventually be supported using something analogous to Dart
typedefs.

## Using generic method parameters

The previous examples declared generic method parameters, but did not use them.
You can use a generic method parameter `T` anywhere that a type is expected in
Dart by writing a type followed by `/*=T*/`.  So for example, `dynamic /*=T*/`
will be interpreted as `dynamic` by all non-strong mode tools, but will be
interpreted as `T` by strong mode.  In places where it is valid to leave off a
type, simply writing `/*=T*/` will be interpreted as `dynamic` by non-strong
mode tools, but will be interpreted as `T` by strong mode.  For example:

```dart
// foo is a generic method which takes a single generic method parameter S.
// In strong mode, the parameter x will have type S, and the return type will
// be S
// In normal mode, the parameter x will have type dynamic, and the return
// type will be dynamic.
dynamic/*=S*/ foo/*<S>*/(dynamic/*=S*/ x) { return x; }
```

This can be written more concisely by leaving off the `dynamic`.

```dart
/*=S*/ foo/*<S>*/(/*=S*/ x) {return x;}
```

You can also put a type to the left of the `/*=T/`. This type will be used
for all non-strong mode tools. For example:

```dart
// This method works with `int`, `double`, or `num`. The return type will
// match the type of the parameters.
num/*=T*/ pickAtRandom/*<T extends num>*/(num/*=T*/ x, num/*=T*/ y) { ... }
```


Note that the generic parameter is in scope in the return type of the function,
in the argument list of the function, and in the body of the function.  When
declaring local variables and parameters, you can also use the `/*=T*/` syntax with `var`.

```dart
// foo is a generic method that takes a single generic parameter S, and a value
// x of type S
void foo/*<S>*/(var /*=S*/ x) {
  // In strong mode, y will also have type S
  var /*=S*/ y = x;

  // In strong mode, z will also have type S
  dynamic /*=S*/ z = y;
}
```

Anywhere that a type literal is expected, you can also use the `/*=T*/` syntax to
produce a type literal from the generic method parameter.

```dart
void foo/*<S>*/(/*=S*/ x) {
  // In strong mode, s will get the type literal for S
  Type s = dynamic /*=S*/;

  // In strong mode, this attempts to cast 3 as type S
  var y = (3 as dynamic /*=S*/);
}
```

You can use the `/*=T*/` syntax to replace any type with a generic type
parameter, but you will usually want to replace `dynamic`. Otherwise, since the
original type is used at runtime, it may cause checked mode errors:

```dart
List/*<T>*/ makeList/*<T extends num>*/() {
  return new List<num /*=T*/>();
}

void main() {
  List<int> list = makeList/*<int>*/(); // <-- Fails here.
}
```

This program checks without error in strong mode but fails at runtime in checked
mode since the list that gets created is a `List<num>`. A better choice is:

```dart
List/*<T>*/ makeList/*<T extends num>*/() {
  return new List/*<T>*/();
}

void main() {
  List<int> list = makeList/*<int>*/();
}
```

## Instantiating generic classes with generic method parameters

You can use generic method parameters to instantiate generic classes using the
same `/*=T*/` syntax.

```dart
// foo is a generic method which returns a List<S> in strong mode,
// but which returns List<dynamic> in normal mode.
List<dynamic /*=S*/> foo/*<S>*/(/*=S*/ x) {
   // l0 is a list literal whose reified type will be List<S> in strong mode,
   // and List<dynamic> in normal mode.
   var l0 = <dynamic /*=S*/>[x];

   // as above, but with a regular constructor.
   var l1 = new List<dynamic /*=S*/>();
   return l1;
}
```

In most cases, the entire type argument list to the generic class can be
enclosed in parentheses, eliminating the need for explicitly writing `dynamic`.

```dart
// This is another way of writing the same code as above
List/*<S>*/ foo/*<S>*/(/*=S*/ x) {
   // The shorthand syntax is not yet supported for list and map literals
   var l0 = <dynamic /*=S*/>[x];

   // but with regular constructors you can use it
   var l1 = new List/*<S>*/();
   return l1;
}
```

## Instantiating generic methods

Generic methods can be called without passing type arguments.  Strong mode will
attempt to infer the type arguments automatically.  If it is unable to do so,
then the type arguments will be filled in with whatever their declared bounds
are (by default, `dynamic`).

```dart
class C {
  /*=S*/ inferableFromArgument/*<S>*/(/*=S*/ x) { return null;}
  /*=S*/ notInferable/*<S>*/(int x) { return null;}
}

void main() {
  C c = new C();
  // This line will produce a type error, because strong mode will infer
  // `int` as the generic argument to fill in for S
  String x = c.inferableFromArgument(3);

  // This line will not produce a type error, because strong mode is unable
  // to infer a type and will fill in the type argument with `dynamic`.
  String y = c.notInferable(3);
}
```

In the case that strong mode cannot infer the generic type arguments, the same
syntax that was shown above for instantiating generic classes can be used to
instantiate generic methods explicitly.

```dart
void main() {
  C c = new C();
  // This line will produce a type error, because strong mode will infer
  // `int` as the generic argument to fill in for S
  String x = c.inferableFromArgument(3);

  // This line will produce a type error in strong mode, because `int` is
  // explicitly passed in as the argument to use for S
  String y = c.notInferable/*<int>*/(3);
}
```
