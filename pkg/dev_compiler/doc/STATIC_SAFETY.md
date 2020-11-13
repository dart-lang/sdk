# Strong Mode Static Checking

**Note: This document is out of date.  Please see [Sound Dart](https://dart.dev/guides/language/sound-dart) for up-to-date
documentation on Dart's type system.  The work below was a precursor towards Dart's current type system.**

## Overview

The Dart programming language has an optional, unsound type system.  Although it is similar in appearance to languages such as Java, C#, or C++, its type system and static checking are fundamentally different.  It permits erroneous behavior in ways that may be surprising to programmers coming from those and other conventional typed languages.

In Dart, static type annotations can be often misleading.  Dart code such as:

```dart
  var list = ["hello", "world"];
  List<int> listOfInts = list;
```

produces neither static nor runtime errors.  Actual errors may show up much later on, e.g., with the following code, only at runtime on the invocation of `abs`:

```dart
  Iterable<int> iterableOfInts = listOfInts.map((i) => i.abs());
```

Strong mode aims to catch such errors early by validating that variables - e.g., `listOfInts` - actually match their corresponding static type annotations - e.g., `List<int>`.  It constrains the Dart programming language to a subset of programs that type check under a restricted set of rules.  It statically rejects examples such as the above.

To accomplish this, strong mode involves the following:

 - **Type inference**.  Dart’s standard type rules treats untyped variables as `dynamic`, which
suppresses any static warnings on them.  Strong mode infers static types based upon context.  In the example above, strong mode infers that `list` has type `List`.  Note, in strong mode, programmers may still explicitly use the `dynamic` type.

 - **Strict subtyping**.  Dart’s primary sources of unsoundness are due to its subtyping rules on function types and generic classes.  Strong mode restricts these: e.g., `List` may not used as `List<int>` in the example above.

 - **Generic methods**.  Standard Dart does not yet provide generic methods.  This makes certain polymorphic methods difficult to use soundly.  For example, the `List.map` invocation above is statically typed to return an `Iterable<dynamic>` in standard Dart.  Strong mode allows methods to be annotated as generic. `List.map` is statically typed to return an `Iterable<T>` where `T` is bound to `int` in the previous example.  A number of common higher-order methods are annotated and checked as generic in strong mode, and programmers may annotate their own methods as well.

Strong mode is designed to work in conjunction with the Dart Dev Compiler (DDC), which uses static type verification to generate better code.  DDC augments strong mode static checking with a minimal set of [runtime checks](RUNTIME_SAFETY.md) that aim to provide full soundness of types.

Strong mode static analysis may also be used alone for stricter error checking.

Formal details of the strong mode type system may be found  [here](https://dart-lang.github.io/dev_compiler/strong-dart.pdf).

## Usage

Strong mode is now integrated into the Dart Analyzer.  The analyzer may be invoked in strong mode as follows:

    $ dartanalyzer --strong myapp.dart

Strong mode may also be enabled in IDEs by creating (if necessary) an `.analysis_options` file in your project and appending the following entry to it:

```
analyzer:
  strong-mode: true
```

## Type Inference

With strong mode, we want to provide stronger typing while preserving the
terseness of Dart. [Idiomatic Dart
code](https://dart.dev/guides/language/effective-dart) discourages type annotations
outside of API boundaries, and user shouldn't have to add more types to get
better checking. Instead, strong mode uses type inference.

In Dart, per the specification, the static type of a variable `x` declared as:

```dart
var x = <String, String>{ "hello": "world"};
```

is `dynamic` as there is no explicit type annotation on the left-hand side. To discourage code bloat, the Dart style guide generally recommends omitting these type annotations in many situations.  In these cases, the benefits of strong mode would be lost.

To avoid this, strong mode uses type inference.  In the case above, strong mode infers and enforces the type of `x` as `Map<String, String>`.  An important aspect to inference is ordering: when an inferred type may be used to infer another type.  To maximize the impact, we perform the following inference:

- Top-level and static fields
- Instance fields and methods
- Local variables
- Constructor calls and literals
- Generic method invocations

Inference may tighten the static type as compared to the Dart specification.  An implicitly dynamic type, either alone or in the context of a function or generic parameter type, is inferred to a more specific type.  This inference may result in stricter type errors than standard Dart.

In [DDC](RUNTIME_SAFETY.md), inference may also affect the reified runtime type.

### Top-level and Static Fields

Strong mode infers any untyped top-level field or static field from the type of
its initializer.  The static type of the declared variable is inferred as the static type of the initializer.  For example, consider:

```dart
var PI = 3.14159;
var radius = 2;
var circumference = 2 * PI * radius;
```

Strong mode infers the static type of `PI` as `double` and `radius` as `int` directly from their initializers.  It infers the static type of `circumference` as `double`, transitively using the other inferred types. Standard Dart rules would treat all of these static types as `dynamic`.  Note that the following later assignment would be allowed in standard Dart, but disallowed (as a static type error) in strong mode:
```dart
radius = "five inches";
```
Strong mode inference avoids circular dependences.  If a variable’s initializer expression refers to another variable whose type would be dependent (directly or indirectly) on the first, the static type of that other variable is treated as `dynamic` for the purpose of inference.

### Instance Fields and Methods

Strong mode performs two types of inference on instance fields and methods.

The first uses base types to constrain overrides in subtypes.  Consider the following example:

```dart
abstract class A {
   Map get m;
   int value(int i);
}

class B extends A {
   var m;
   value(i) => m[i];
   …
}
```

In Dart, overridden method, getter, or setter types should be subtypes of the corresponding base class ones (otherwise, static warnings are given).  In standard Dart, the above declaration of `B` is not an error: both `m`’s getter type and `value`’s return type are `dynamic`.

Strong mode -- without inference -- would disallow this: if `m` in `B` could be assigned any kind of object, including one that isn't a Map, it would violate the type contract in the declaration of `A`.

However, rather than rejecting the above code, strong mode employs inference to tighten the static types to obtain a valid override.  The corresponding types in B are inferred as if it was:

```dart
class B extends A {
  Map m;
  int value(int i) => m[i];
  …
}
```

Note that tightening the argument type for `i` to `int` is not required for soundness; it is done for convenience as it is the typical intent.  The programmer may explicitly type this as `dynamic` or `Object` to avoid inferring the narrower type.

The second form inference is limited to instance fields (not methods) and is similar to that on static fields.  For instance fields where the static type is omitted and an initializer is present, the field’s type is inferred as the initializer’s type.  In this continuation of our example:

```dart
class C extends A {
  var y = 42;
  var m = <int, int>{ 0: 38};
  ...
}
```

the instance field `y` has inferred type `int` based upon its initializer.  Note that override-based inference takes precedence over initializer-based inference.  The instance field `m` has inferred type `Map`, not `Map<int, int>` due to the corresponding declaration in `A`.

### Local Variables

As with fields, local variable types are inferred if the static type is omitted and an initializer expression is present.  In the following example:

```dart
Object foo(int x) {
   final y = x + 1;
   var z = y * 2;
   return z;
}
```

the static types of `y` and `z` are both inferred as `int` in strong mode.  Note that local inference is done in program order: the inferred type of `z` is computed using the inferred type of `y`. Local inference may result in strong mode type errors in otherwise legal Dart code.  In the above, a second assignment to `z` with a string value:    
```dart
z = "$z";
```
would trigger a static error in strong mode, but is allowed in standard Dart.  In strong mode, the programmer must use an explicit type annotation to suppress inference.  Explicitly declaring `z` with the type `Object` or `dynamic` would suffice in this case.

### Constructor Calls and Literals

Strong mode also performs contextual inference on allocation expressions.  This inference is rather different from the above: it tightens the runtime type of the corresponding expression using the static type of its context.  Contextual inference is used on expressions that allocate a new object: closure literals, map and list literals, and explicit constructor invocations (i.e., via `new` or `const`).

In DDC, these inferred types are also [reified at runtime](RUNTIME_SAFETY.md) on the newly allocated objects to provide a stronger soundness guarantee.

#### Closure literals

Consider the following example:

```dart
int apply(int f(int arg), int value) {
  return f(value);
}

void main() {  
  int result =
    apply((x) { x = x * 9 ~/ 5; return x + 32; }, 41);
  print(result);
}
```

The function `apply` takes another function `f`, typed `(int) -> int`, as its first argument.  It is invoked in `main` with a closure literal.  In standard Dart, the static type of this closure literal would be `(dynamic) -> dynamic`.  In strong mode, this type cannot be safely converted to `(int) -> int` : it may return a `String` for example.   

Dart has a syntactic limitation in this case: it is not possible to statically annotate the return type of a closure literal.

Strong mode sidesteps this difficulty via contextual inference.  It infers the closure type as `(int) -> int`.  Note, this may trigger further inference and type checks in the body of the closure.

#### List and map literals

Similarly, strong mode infers tighter runtime types for list and map literals.  E.g., in

```dart
List<String> words = [ "hello", "world" ];
```

the runtime type is inferred as `List<String>` in order to match the context of the left hand side.  In other words, the code above type checks and executes as if it was:

```dart
List<String> words = <String>[ "hello", "world" ];
```

Similarly, the following will now trigger a static error in strong mode:

```dart
List<String> words = [ "hello", 42 ]; // Strong Mode Error: 42 is not a String
```

Contextual inference may be recursive:

```dart
Map<List<String>, Map<int, int>> map =
	{ ["hello"]: { 0: 42 }};
```

In this case, the inner map literal is inferred as a `Map<int, int>`.  Note, strong mode will statically reject code where the contextually required type is not compatible.  This will trigger a static error:

```dart
Map<List<String>, Map<int, int>> map =
  { ["hello"]: { 0: "world" }}; // STATIC ERROR
```

as "world" is not of type `int`.

#### Constructor invocations

Finally, strong mode performs similar contextual inference on explicit constructor invocations via `new` or `const`.  For example:

```dart
Set<String> string = new Set.from(["hello", "world"]);
```

is treated as if it was written as:

```dart
Set<String> string =
  new Set<String>.from(<String>["hello", "world"]);
```

Note, as above, context is propagated downward into the expression.

## Strict subtyping

The primary sources of unsoundness in Dart are generics and functions.  Both introduce circularity in the Dart subtyping relationship.

### Generics

Generics in Dart are covariant, with the added rule that the `dynamic` type may serve as both ⊤ (top) and ⊥ (bottom) of the type hierarchy in certain situations.  For example, let *<:<sub>D</sub>*  represent the standard Dart subtyping rule.  Then, for all types `S` and `T`:

`List<S>` <:<sub>D</sub> `List<dynamic>` <:<sub>D</sub> `List<T>`

where `List` is equivalent to `List<dynamic>`.  This introduces circularity - e.g.:

`List<int>` <:<sub>D</sub> `List` <:<sub>D</sub> `List<String>`<:<sub>D</sub> `List` <:<sub>D</sub> `List<int>`

From a programmer’s perspective, this means that, at compile-time, values that are statically typed `List<int>` may later be typed `List<String>` and vice versa.  At runtime, a plain `List` can interchangeably act as a `List<int>` or a `List<String>` regardless of its actual values.

The example taken from [here](https://github.com/dart-lang/dev_compiler/blob/strong/STRONG_MODE.md#motivation) exploits this:

```dart
class MyList extends ListBase<int> implements List {
   Object length;

   MyList(this.length);

   operator[](index) => "world";
   operator[]=(index, value) {}
}
```

A `MyList` may masquerade as a `List<int>` as it is transitively a subtype:

`MyList` <:<sub>D</sub> `List` <:<sub>D</sub>`List<int>`

In strong mode, we introduce a stricter subtyping rule <:<sub>S</sub> to disallow this.  In this case, in the context of a generic type parameter, dynamic may only serve as ⊤.  This means that this is still true:

`List<int>` <:<sub>S</sub> `List`

but that this is not:

`List` ~~<:<sub>S</sub> `List<int>`~~

The example above fails in strong mode:

`MyList` <:<sub>S</sub> `List` ~~<:<sub>S</sub> `List<int>`~~


### Functions

The other primary source of unsoundness in Dart is function subtyping.  An unusual feature of the Dart type system is that function types are bivariant in both the parameter types and the return type (see Section 19.5 of the [Dart specification][dartspec]).  As with generics, this leads to circularity:

`(int) -> int` <:<sub>D</sub> `(Object) -> Object` <:<sub>D</sub> `(int) -> int`

And, as before, this can lead to surprising behavior.  In Dart, an overridden method’s type should be a subtype of the base class method’s type (otherwise, a static warning is given).  In our running example, the (implicit) `MyList.length` getter has type:

`() -> Object`

while the `List.length` getter it overrides has type:

`() -> int`

This is valid in standard Dart as:

`() -> Object` <:<sub>D</sub> `() -> int`

Because of this, a `length` that returns "hello" (a valid `Object`) triggers no static or runtime warnings or errors.

Strong mode enforces the stricter, [traditional function subtyping](https://en.wikipedia.org/wiki/Subtyping#Function_types) rule: subtyping is contravariant in parameter types and covariant in return types.  This permits:

`() -> int` <:<sub>S</sub> `() -> Object`

but disallows:

`() -> Object` <:<sub>S</sub> `() -> int`

With respect to our example, strong mode requires that any subtype of a List have an int-typed length.  It statically rejects the length declaration in MyList.

## Generic Methods

Strong mode introduces generic methods to allow more expressive typing on polymorphic methods.  Such code in standard Dart today often loses static type information.  For example, the `Iterable.map` method is declared as below:

```dart
abstract class Iterable<E> {
  ...
  Iterable map(f(E e));
}
```

Regardless of the static type of the function `f`, the `map` always returns an `Iterable<dynamic>` in standard Dart.  As result, standard Dart tools miss the obvious error on the following code:

```dart
Iterable<int> results = <int>[1, 2, 3].map((x) => x.toString()); // Static error only in strong mode
```

The variable `results` is statically typed as if it contains `int` values, although it clearly contains `String` values at runtime.

The [generic methods proposal](https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md) adds proper generic methods to the Dart language as a first class language construct and to make methods such as the `Iterable.map` generic.

To enable experimentation, strong mode provides a [generic methods prototype](GENERIC_METHODS.md) based on the existing proposal, but usable on all existing Dart implementations today.  Strong mode relies on this to report the error on the example above.

The `Iterable.map` method is now declared as follows:

```dart
abstract class Iterable<E> {
  ...
  Iterable/*<T>*/ map/*<T>*/(/*=T*/ f(E e));
}
```

At a use site, the generic type may be explicitly provided or inferred from context:

```
  var l = <int>[1, 2, 3];
  var i1 = l.map((i) => i + 1);
  var l2 = l.map/*<String>*/((i) { ... });
```

In the first invocation of `map`, the closure is inferred (from context) as `int -> int`, and the generic type of map is inferred as `int` accordingly.  As a result, `i1` is inferred as `Iterable<int>`.  In the second, the type parameter is explicitly bound to `String`, and the closure is checked against this type.  `i2` is typed as `Iterable<String>`.

Further details on generic methods in strong mode and in DDC may be found [here](GENERIC_METHODS.md).

## Additional Restrictions

In addition to stricter typing rules, strong mode enforces other
restrictions on Dart programs.

### Warnings as Errors

Strong mode effectively treats all standard Dart static warnings as static errors.  Most of these warnings are required for soundness (e.g., if a concrete class is missing methods required by a declared interface).  A full list of Dart static warnings may found in the [Dart specification][dartspec], or enumerated here:

[https://github.com/dart-lang/sdk/blob/master/pkg/analyzer/lib/src/generated/error.dart#L3772](https://www.google.com/url?q=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsdk%2Fblob%2Fmaster%2Fpkg%2Fanalyzer%2Flib%2Fsrc%2Fgenerated%2Ferror.dart%23L3772&sa=D&sntz=1&usg=AFQjCNFc4E37M1PshVcw4zk7C9jXgqfGbw)

### Super Invocations

In the context of constructor initializer lists, strong mode restricts `super` invocations to the end.  This restriction simplifies generated code with minimal effect on the program.

### For-in loops

In for-in statements of the form:

```dart
for (var i in e) { … }
```

Strong mode requires the expression `e` to be an `Iterable`.  When the loop variable `i` is also statically typed:

```dart
for (T i in e) { … }
```

the expression `e` is required to be an `Iterable<T>`.

*Note: we may weaken these.*

### Field overrides

By default, fields are overridable in Dart.  

```dart
int init(int n) {
  print('Initializing with $n');
  return n;
}

class A {
  int x = init(42);
}

class B extends A {
  int x;
}
```

Disallow overriding fields: this results in complicated generated
code where a field definition in a subclass shadows the field
  definition in a base class but both are generally required to be
  allocated.  Users should prefer explicit getters and setters in such
  cases.  See [issue 52](https://github.com/dart-lang/dev_compiler/issues/52).

## Optional Features

### Disable implicit casts

This is an optional feature of strong mode. It disables implicit down casts. For example:

```dart
main() {
  num n = 0.5;
  int x = n; // error: invalid assignment
  int y = n as int; // ok at compile time, might fail when run
}
```

Casts from `dynamic` must be explicit as well:

```dart
main() {
  dynamic d = 'hi';
  int x = d; // error: invalid assignment
  int y = d as int; // ok at compile time, might fail when run
}
```

This option is experimental and may be changed or removed in the future.
Try it out in your project by editing .analysis_options:

```yaml
analyzer:
  strong-mode:
    implicit-casts: False
```

Or pass `--no-implicit-casts` to Dart Analyzer:

```
dartanalyzer --strong --no-implicit-casts my_app.dart
```

### Disable implicit dynamic

This is an optional feature of analyzer, intended primarily for use with strong mode's inference.
It rejects implicit uses of `dynamic` that strong mode inference fails to fill in with a concrete type,
ensuring that all types are either successfully inferred or explicitly written. For example:

```dart
main() {
  var x; // error: implicit dynamic
  var i = 123; // okay, inferred to be `int x`
  dynamic y; // okay, declared as dynamic
}
```

This also affects: parameters, return types, fields, creating objects with generic type, generic functions/methods, and
supertypes:

```dart
// error: parameters and return types are implicit dynamic
f(x) => x + 42;
dynamic f(dynamic x) => x + 42; // okay
int f(int x) => x + 42; // okay

class C {
  var f; // error: implicit dynamic field
  dynamic f; // okay
}

main() {
  var x = []; // error: implicit List<dynamic>
  var y = [42]; // okay: List<int>
  var z = <dynamic>[]; // okay: List<dynamic>
  
  T genericFn<T>() => null;
  genericFn(); // error: implicit genericFn<dynamic>
  genericFn<dynamic>(); // okay
  int x = genericFn(); // okay, inferred genericFn<int>
}

// error: implicit supertype Iterable<dynamic>
class C extends Iterable { /* ... */ }
// okay
class C extends Iterable<dynamic> { /* ... */ }
```

This feature is to prevent accidental use of `dynamic` in code that does not intend to use it.

This option is experimental and may be changed or removed in the future.
Try it out in your project by editing .analysis_options:

```yaml
analyzer:
  strong-mode:
    implicit-dynamic: False
```

Or pass `--no-implicit-dynamic` to Dart Analyzer:

```
dartanalyzer --strong --no-implicit-dynamic my_app.dart
```

### Open Items

- Is / As restrictions: Dart's `is` and `as` checks are unsound for certain types
(generic classes, certain function types).  In [DDC](RUNTIME_SAFETY.md), problematic
`is` and `as` checks trigger runtime errors.  We are considering introducing static
errors for these cases.

[dartspec]: https://dart.dev/guides/language/spec "Dart Language Spec"
