# Strong Mode

## Overview 

The Dart Development Compiler (DDC) is a new Dart-to-JavaScript compiler that supports a large subset of the Dart programming language.  DDC is motivated by the following goals: 

First, we aim to generate clean, readable, consumable JavaScript output.  This simplifies debugging Dart applications across multiple web platforms.  It also enables better, seamless interoperability between Dart and JavaScript components. 

Second, we aim to compile in a fast, modular fashion.  This enables a faster, better development cycle across a number of platforms and devices that lack native Dart support.  It also allows Dart libraries to be packaged and distributed separately for use in other Dart or JavaScript applications. 

To accomplish these goals, we focus on a subset of Dart applications we can statically type check.  This subset can be viewed as a **strong mode** analogous to Dart’s checked mode and production mode.  A program that runs correctly in strong mode will run the same in checked mode and, thus, in production mode.  The subset we support entails:

 - A stricter, sounder, type system
 - Type inference 
 - Restrictions on certain language constructs

DDC is intended to complement our existing Dart2JS compiler.  Unlike DDC, Dart2JS is focused on raw performance and support for the entire Dart language rather than readability, JavaScript interoperability, or modular compilation. 

This document provides a high-level overview of strong mode.  A corresponding formalism of strong mode can also be found [here](https://dart-lang.github.io/dev_compiler/strong-dart.pdf).

## Motivation

The standard Dart type system is unsound by design.  This means that static type annotations may not match the actual runtime values even when a program is running in checked mode.  This allows considerable flexibility, but it also means that Dart implementations cannot easily use these annotations for optimization or code generation. 

Because of this, existing Dart implementations require dynamic dispatch.  Furthermore, because Dart’s dispatch semantics are different from JavaScript’s, it effectively precludes mapping Dart calls to idiomatic JavaScript.  For example, the following Dart code: 

```dart
var x = a.bar;
b.foo("hello", x);
```

cannot easily be mapped to the identical JavaScript code.  If `a` does not contain a `bar` field, Dart requires a `NoSuchMethodError` while JavaScript simply returns undefined.  If `b` contains a `foo` method, but with the wrong number of arguments, Dart again requires a `NoSuchMethodError` while JavaScript either ignores extra arguments or fills in omitted ones with undefined.   

To capture these differences, the Dart2JS compiler instead generates code that approximately looks like: 

```dart
var x = getInterceptor(a).get$bar(a);
getInterceptor(b).foo$2(b, "hello", x);
```
The “interceptor” is Dart’s dispatch table for the objects `a` and `b`, and the mangled names (`get$bar` and `foo$2`) account for Dart’s different dispatch semantics. 

The above highlights why Dart-JavaScript interoperability hasn’t been seamless: Dart objects and methods do not look like normal JavaScript ones. 

DDC relies on strong mode to map Dart calling conventions to normal JavaScript ones.  If `a` and `b` have static type annotations (with a type other than `dynamic`), strong mode statically verifies that they have a field `bar` and a 2-argument method `foo` respectively.  In this case, DDC safely generates the identical JavaScript:

```javascript
var x = a.bar;
b.foo("hello", x);
```

Note that DDC still supports the `dynamic` type, but relies on runtime helper functions in this case.  E.g., if `a` and `b` are type `dynamic`, DDC instead generates: 

```javascript
var x = dload(a, "bar");
dsend(b, "foo", "hello", x);
```

where `dload` and `dsend` are runtime helpers that implement Dart dispatch semantics.  Programmers are encouraged to use static annotations to avoid this. Strong mode is able to use static checking to enforce much of what checked mode does at runtime.  In the code above, strong mode statically verifies that `b`’s type (if not `dynamic`) has a `foo` method that accepts a `String` as its first argument and `a.bar`’s type as its second.  If the code is sufficiently typed, runtime checks are unnecessary.

## Strong Mode Type System

DDC uses strong mode to ensure that static type annotations are actually correct at runtime.  For this to work, strong mode requires a stricter type system than standard Dart.  To understand this, consider the following, which we will use as our running example: 

```dart
library util;

void info(List<int> list) {
  var length = list.length;
  if (length != 0) print("$length ${list[0]}");
}
```

A developer might reasonably expect the `info` function to print either nothing (empty list) or two integers (non-empty list), and that Dart’s static tooling and checked mode would enforce this. 

However, in the following context, the info method prints “hello world” in checked mode, without any static errors or warnings:

```dart
import ‘dart:collection’;
import ‘utils.dart’;

class MyList extends ListBase<int> implements List {
   Object length;
   
   MyList(this.length);
   
   operator[](index) => "world";
   operator[]=(index, value) {}
}

void main() {
   List<int> list = new MyList("hello");
   info(list);
} 
```

The lack of static or runtime errors is not an oversight; it is by design.  It provides developers a mechanism to circumvent or ignore types when convenient, but it comes at cost.  While the above example is contrived, it demonstrates that developers cannot easily reason about a program modularly: the static type annotations in the `utils` library are of limited use, even in checked mode.

For the same reason, a compiler cannot easily exploit type annotations if they are unsound.  A Dart compiler cannot simply assume that a `List<int>` contains `int` values or even that its `length` is an integer.  Instead, it must either rely on expensive (and often brittle) whole program analysis or on additional runtime checking. 

The fundamental issue above is that static annotations may not match runtime types, even in checked mode: this is a direct consequence of the unsoundness of the Dart type system.  This can make it difficult for both programmers and compilers to rely on static types to reason about programs.
 
Strong mode enforces the correctness of static type annotations.  It simply disallows examples such as the above. It relies on a combination of static checking and runtime assertions.  In our running example, standard Dart rules (checked or otherwise) allow `MyList` to masquerade as a `List<int>`.  DDC disallows this by statically rejecting the declaration of `MyList`.  This allows both the developer and the compiler to better reason about the info method.  For statically checked code, both may assume that the argument is a proper `List<int>`, with integer-valued length and elements.

DDC’s strong mode is strictly stronger than checked mode.  A Dart program execution where (a) the program passes DDC’s static checking and (b) the execution does not trigger DDC’s runtime assertions, will also run in checked mode on any Dart platform.


### Static typing

The primary sources of unsoundness in Dart are generics and functions.  Both introduce circularity in the Dart subtyping relationship.

#### Generics

Generics in Dart are co-variant, with the added rule that the `dynamic` type may serve as both ⊤ (top) and ⊥ (bottom) of the type hierarchy in certain situations.  For example, let *<:<sub>D</sub>*  represent the standard Dart subtyping rule.  Then, for all types `S` and `T`:

`List<S>` <:<sub>D</sub> `List<dynamic>` <:<sub>D</sub> `List<T>`

where `List` is equivalent to `List<dynamic>`.  This introduces circularity - e.g.,:

`List<int>` <:<sub>D</sub> `List` <:<sub>D</sub> `List<String>`<:<sub>D</sub> `List` <:<sub>D</sub> `List<int>`


From a programmer’s perspective, this means that, at compile-time, values that are statically typed `List<int>` may later be typed `List<String>` and vice versa.  At runtime, a plain `List` can interchangeably act as a `List<int>` or a `List<String>` regardless of its actual values.

Our running example exploits this.  A `MyList` may be passed to the `info` function as it’s a subtype of the expected type:

`MyList` <:<sub>D</sub> `List` <:<sub>D</sub>`List<int>`

In strong mode, we introduce a stricter subtyping rule <:<sub>S</sub> to disallow this.  In this case, in the context of a generic type parameter, dynamic may only serve as ⊤.  This means that this is still true:

`List<int>` <:<sub>S</sub> `List`

but that this is not:

`List<int>` ~~<:<sub>S</sub> `List`~~


Our running example fails in strong mode:

`MyList` <:<sub>S</sub> `List` ~~<:<sub>S</sub> `List<int>`~~


#### Functions

The other primary source of unsoundness in Dart is function subtyping.  An unusual feature of the Dart type system is that function types are bivariant in both the parameter types and the return type (see Section 19.5 of the [Dart specification](http://www.google.com/url?q=http%3A%2F%2Fwww.ecma-international.org%2Fpublications%2Ffiles%2FECMA-ST%2FECMA-408.pdf&sa=D&sntz=1&usg=AFQjCNGoFPzBNx2fgejKQgSgiS2dUBstBw)).  As with generics, this leads to circularity:

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

Formal details of the strong mode type system may be found  [here](https://dart-lang.github.io/dev_compiler/strong-dart.pdf).

### Implicit runtime assertions

Although strong mode relies heavily on static checking, it also requires some runtime checking for soundness.  For example, the following code is allowed: 

```dart
dynamic x = …; 
List y = x;
int z = y.length;
```

but a runtime check is required (and inserted by DDC) to ensure that `y` is assigned a `List`.  This is similar to checked mode, but much less pervasive.  Checked mode would also require a runtime check on the assignment of `z`.  Strong mode would not as this is enforced statically instead.

## Type Inference 

A secondary goal of DDC is to preserve the terseness of Dart.  While strong mode requires and/or encourages more static type annotations, our aim is make this as lightweight as possible.

In Dart, per the specification, the static type of a variable `x` declared as:

```dart
var x = <String, String>{ "hello": "world"};
```

is `dynamic` as there is no explicit type annotation on the left-hand side. To discourage code bloat, the Dart style guide generally recommends omitting these type annotations in many situations.  In these cases, the benefits of strong mode would be lost.

To avoid this, strong mode uses limited inference.  In the case above, the strong mode infers and enforces the type of `x` as `Map<String, String>`.  An important aspect to inference is ordering: when an inferred type may be used to infer other type.  To maximize the impact, we perform the following inference in the following order:

- Top-level and static fields
- Instance fields and methods
- Local variables
- Allocation expressions

In all cases, inference tightens the static type or runtime type as compared to the Dart specification.  The `dynamic` type, either alone or in the context of a function or generic parameter type, is inferred to a more specific type.  The effect of this inference (other than stricter type errors) should not be observable at runtime outside the use of the mirrors API.  (Note, in the next section, we discuss corresponding restrictions on `is` and `as` type checks.)

### Top-level and Static Fields

Strong mode will infer the static type of any top-level or static field with: 

- No static type annotation 
- An initializer expression 

The static type of the declared variable is inferred as the static type of the initializer.  For example, consider:

```dart
var PI = 3.14159;
var TAU = PI * 2;
```

Strong mode would infer the static type of `PI` as `double` directly from its initializer.  It would infer the static type of `TAU` as `double`, transitively using `PI`’s inferred type. Standard Dart rules would treat the static type of both `PI` and `TAU` as `dynamic`.  Note that the following later assignment would be allowed in standard Dart, but disallowed (as a static type error) in strong mode:
```dart
PI = "\u{03C0}"; // Unicode string for PI symbol 
```
Strong mode inference avoids circular dependences.  If a variable’s initializer expression refers to another variable whose type would be dependent (directly or transitively) on the first, the static type of that other variable is treated as `dynamic` for the purpose of inference.  In this modified example, 

```dart
var _PI_FIRST = true;
var PI = _PI_FIRST ? 3.14159 : TAU / 2;
var TAU = _PI_FIRST ? PI * 2 : 6.28318;
```

the variables `PI` and `TAU` are circularly dependent on each other.  Strong mode would leave the static type of both as `dynamic`. 

<em>
Note - we’re experimenting with a few arguably simpler variants here:
- Limiting inference to final or const fields (i.e., not var). 
- Limiting transitive inference to explicit program order.
</em>

### Instance Fields and Methods

Strong mode performs two types of inference on instances fields and methods. 

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

Strong mode - without inference - would disallow this: if `m` in `B` could be assigned an arbitrarily typed value, it would violate the type contract in the declaration of `A`.

However, rather than rejecting the above code, strong mode employs inference to tighten the static types to obtain a valid override.  The corresponding types in B are inferred as if it was: 

```dart
class B extends A {
  Map m;
  int value(i) => m[i];
  … 
} 
```

Note that the argument type of `value` is left as `dynamic`.  Tightening this type is not required for soundness. 

The second form inference is limited to instance fields (not methods) and is similar to that on static fields.  For instance fields where the static type is omitted and an initializer is present, the field’s type is inferred as the initializer’s type.  In this continuation of our example: 

```dart
class C extends A {
  var y = 42;
  var m = <int, int>{ 0: 38};
  ...
}
```
the instance field `y` has inferred type `int` based upon its initializer.  Note that override-based inference takes precedence over initializer-based inference.  The instance field `m` has inferred type `Map`, not `Map<int, int>` due to the corresponding declaration in `A`.

<em>
Note - we’re considering with a few variants here as well:
- Limiting inference to final or const fields (i.e., not var).
- Inference on parameter types when omitted (e.g., the argument to `B.value` above).
- When to allow or prefer override-based inference.
</em>

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
z = “$z”;
```
would trigger a static error in strong mode, but is allowed in standard Dart.  In strong mode, the programmer must use an explicit type annotation to avoid inference.  Explicitly declaring `z` with the type `Object` or `dynamic` would suffice in this case.

### Allocation Expressions

The final form of strong mode inference is on allocation expressions.  This inference is rather different from the above: it tightens the runtime type of the corresponding expression using the static type of its context.  Contextual inference is used on expressions that allocated a new object: closure literals, map and list literals, and explicit constructor invocations (i.e., via `new` or `const`).

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

Strong mode sidesteps this difficulty via contextual inference.  It infers the closure type as `(dynamic) -> int`.  This is the most general type allowed by the context: the parameter type of apply.  

#### List and map literals 

Similarly, strong mode infers tighter runtime types for list and map literals.  E.g., in 

```dart
List<String> l = [ "hello", "world" ];
```

the runtime type is inferred as `List<String>` in order to match the context of the left hand side.  In other words, the code above executes as if it was: 

```dart
List<String> l = <String>[ "hello", "world" ]; 
```

Contextual inference may be recursive:

```dart
Map<List<String>, Map<int, int>> map = 
	{ ["hello"]: { 0: 42 }};
```

In this case, the inner map literal is inferred and allocated as a `Map<int, int>`.  Note, strong mode will statically reject code where the contextually required type is not compatible.  This will trigger a static error:

```dart
Map<List<String>, Map<int, int>> map = 
  { ["hello"]: { 0: "world" }}; // STATIC ERROR
```

as "world" is not of type `int`.

#### Constructor invocations

Finally, strong mode performs similar contextual inference on explicit constructor invocations via new or const.  For example:

```dart
Set<String> string = new Set.from(["hello", "world"]);
```

is treated as if it was written as:

```dart
Set<String> string =
  new Set<String>.from(<String>["hello", "world"]);
```

Note, as above, context is propagated downward into the expression.

## General Language Restrictions 

In addition to stricter typing rules, DDC enforces other restrictions on Dart programs.

### Warnings are Errors 

DDC effectively treats all standard Dart static warnings as static errors.  Most of these warnings are required for soundness (e.g., if a concrete class is missing methods required by a declared interface).  A full list of Dart static warnings may found in the [Dart specification](http://www.google.com/url?q=http%3A%2F%2Fwww.ecma-international.org%2Fpublications%2Ffiles%2FECMA-ST%2FECMA-408.pdf&sa=D&sntz=1&usg=AFQjCNGoFPzBNx2fgejKQgSgiS2dUBstBw), or enumerated here: 

[https://github.com/dart-lang/sdk/blob/master/pkg/analyzer/lib/src/generated/error.dart#L3772](https://www.google.com/url?q=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsdk%2Fblob%2Fmaster%2Fpkg%2Fanalyzer%2Flib%2Fsrc%2Fgenerated%2Ferror.dart%23L3772&sa=D&sntz=1&usg=AFQjCNFc4E37M1PshVcw4zk7C9jXgqfGbw)

### Is / As Restrictions 

Dart is and as runtime checks expose the unsoundness of the type system in certain cases.  For example, consider:

```dart
var list = ["hello", "world"];
if (list is List<int>) {
  ...
} else if (list is List<String>) {
  ...
}
```

Perhaps surprisingly, the first test - `list is List<int>` - evaluates to true here.  Such code is highly likely to be erroneous. 

DDC strong mode statically disallows problematic `is` or `as` checks..  In general, an expression:

```dart
x is T
```

or

```dart
x as T
```

is only allowed where `T` is a *ground type*:

- A non-generic class type (e.g., `Object`, `String`, `int`, ...).
- A generic class type where all type parameters are implicitly or explicitly `dynamic` (e.g., `List<dynamic>`, `Map`, …).
- A function type where the return type and all parameter types are `dynamic` (e.g., (`dynamic`, `dynamic`) -> `dynamic`, ([`dynamic`]) -> `dynamic`).

In all other cases, strong mode reports a static error.

### Super Invocations 

In the context of constructor initializer lists, DDC restricts `super` invocations to the end.  This restriction simplifies generated code with minimal effect on the program. 

*Note: Both the VM and Dart2JS ignore the Dart specification on ordering: i.e., they appear to invoke the super constructor after other items on the initializer list regardless of where it appears.*

### For-in Loops 

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

### Await Expressions 

In an await expression of the form: 
```dart
await expr
```
strong mode requires `expr` to be a subtype of `Future`.  In standard Dart, this is not required although tools may provide a hint.

### Open Items 

We do not yet implement but are considering the following restrictions as well.

- Disallow overriding fields: this results in complicated generated
  code where a field definition in a subclass shadows the field
  definition in a base class but both are generally required to be
  allocated.  Users should prefer explicit getters and setters in such
  cases.  See [issue 52](https://github.com/dart-lang/dev_compiler/issues/52).

- `Future<Future<T>>`: the Dart specification automatically flattens
  this type to `Future<T>` (where `T` is not a `Future`).  This can be
  issue as far as soundness.  We are considering forbidding this type
  altogether (with a combination of static and runtime checks).  See
  [issue 228](https://github.com/dart-lang/dev_compiler/issues/228).

