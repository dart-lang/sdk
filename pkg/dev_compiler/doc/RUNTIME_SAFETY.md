# Strong Mode in the Dart Dev Compiler

## Overview

In the Dart Dev Compiler (DDC), [static strong mode](STATIC_SAFETY.md) checks are augmented with stricter runtime behavior.  Together, they enforce the soundness of Dart type annotations.

In general, and in contrast to Dart's checked mode, most safety is enforced statically, at analysis time.  DDC exploits this to generate relatively few runtime checks while still providing stronger guarantees than checked mode.

In particular, DDC adds the following:

 - Stricter (but fewer) runtime type checks
 - Reified type narrowing
 - Restricted `is`/`as` checks

In all these cases, DDC (with static checks) is stricter than standard checked mode (or production mode).  It may reject (either statically or at runtime) programs that run correctly in checked mode (similar to how checked mode may reject programs that run in production mode).

On the other hand, programs that statically check and run correctly in DDC should also run the same in checked mode.  A caveat to note is that mirrors (or `runtimeType`) may show a more narrow type in DDC (though, in practice, programmers are discouraged from using these features for performance / code size reasons).

## Runtime checks

In practice, strong mode enforces most type annotations at compile time, and, thus, requires less work at runtime to enforce safety.  Consider the following Dart code:

```dart
String foo(Map<int, String> map, int x) {
  return map[x.abs()];
}
```

Strong mode enforces that the function `foo` is only invoked in a manner consistent with its signature.  DDC - which assumes strong mode static checking - inserts no further runtime checks.  In contrast, standard Dart checked mode would check the type of the parameters -- `map` and `x` -- along with the type of the return value at runtime on every invocation of `foo`.  Even Dart production mode, depending on the implementation and its ability to optimize, may require similar checking to dynamically dispatch the map lookup and the method call in the body of `foo`.

Nevertheless, there are cases where DDC still requires runtime checks.  (Note: DDC may eventually provide a mode to elide these checks, but this would violate soundness and is beyond the scope of this document.)

### Implicit casts

Dart has flexible assignability rules.  Programmers are not required to explicitly cast from supertypes to subtypes.  For example, the following is valid Dart:

```dart
Object o = ...;
String s = o;  // Implicit downcast
String s2 = s.substring(1);
```

The assignment to `s` is an implicit downcast from `Object` to `String` and triggers a runtime check in DDC to ensure it is correct.

Note that checked mode would also perform this runtime test.  Unlike checked mode, DDC would not require a check on the assignment to `s2` - this type is established statically.

### Inferred variables

Dart's inference may narrow the static type of certain variables.  If the variable is mutable, DDC enforces the narrower type at runtime when necessary.

In the following example, strong mode will infer of the type of the local variable `y` as an `int`:  

```dart
int bar(Object x) {
  var y = 0;
  if (x != null) {
    y = x;
  }
  return y.abs();
}
```

This allows it to, for example, static verify the call to `y.abs()` and determine that it returns an `int`.  However, the parameter `x` is typed as `Object` and the assignment from `x` to `y` now requires a type check to ensure that `y` is only assigned an `int`.

Note, strong mode and DDC are conservative by enforcing a tighter type than required by standard Dart checked mode.  For example, checked mode would accept a non-`int` `x` with an `abs` method that happened to return an `int`.  In strong mode, a programmer would have to explicitly opt into this behavior by annotating `y` as an `Object` or `dynamic`.

### Covariant generics

Strong mode preserves the covariance of Dart's generic classes.  To support this soundly, DDC injects runtime checks on parameters in method invocations whose type is a class type parameter.  Consider the call to `baz` in the parameterized class `A`:

```dart
class A<T> {
  T baz(T x, int y) => x;
}

void foo(A<Object> a) {
  a.baz(42, 38);
}

void main() {
  var aString = new A<String>();
  foo(aString);
}
```

Statically, sound mode will not generate an error or warning on this code.  The call to `baz` in `foo` is statically valid as `42` is an `Object` (as required by the static type of `a`).  However, the runtime type of `a` in this example is the narrower `A<String>`.  At runtime, when baz is executed, DDC will check that the type of `x` matches the reified type parameter and, in this example, fail.

Note, only `x` requires a runtime check.  Unlike checked mode, no runtime check is required for `y` or the return value.  Both are statically verified.

### Dynamic operations

Strong mode allows programmers to explicitly use `dynamic` as a type.  It also allows programmers to omit types, and in some of these cases inference may fall back on `dynamic` if it cannot determine a static type.  In these cases, DDC inserts runtime checks (typically in the form of runtime helper calls).  

For example, in the following:

```dart
int foo(int x) => x + 1;

void main() {
  dynamic bar = foo;
  bar("hello"); // DDC runtime error
}
```

`foo` (via `bar`) is incorrectly invoked on a `String`.  There is no static error as `bar` is typed `dynamic`.  Instead DDC, performs extra runtime checking on the invocation of `bar`.  In this case, it would generate a runtime type error.  Note, if the type of `bar` had been omitted, it would have been inferred, and the error would have been reported statically.

Nevertheless, there are situations where programmers may prefer a dynamic type for flexibility.

## Runtime type Narrowing

Strong mode statically infers tighter types for functions and generics.  In DDC, this is reflected in the reified type at runtime.  This allows DDC to enforce the stricter type soundly at runtime when necessary.

In particular, this means that DDC may have a stricter concrete runtime type than other Dart implementations for generic classes and functions.  The DDC type will always be a subtype.

This will impact execution in the following ways:
  - DDC may trigger runtime errors where checked mode is forgiving.
  - Code that uses reflection may observe a narrower type in DDC.

### Allocation inference

When strong infers a narrower type for a closure literal or other allocation expression, DDC reifies this narrower type at runtime.  As a result, it can soundly enforce typing errors at runtime.  

The following is an example of where static checking fails to catch a typing error:

```dart
apply(int g(x), y) {
  print(g(y));
}

typedef int Int2Int(int x);

void main() {
  Int2Int f = (x) => x + x;
  apply(f, "hello");
}
```

A programmer examining `apply` would reasonably expect it to print an `int` value.  The analyzer (with or without strong mode) fails to report a problem.  Standard Dart checked simply prints `"hellohello"`.  In DDC, however, a runtime error is thrown on the application of `g` in `apply`.  The closure literal assigned to `f` in `main` is reified as an `int -> int`, and DDC enforces this at runtime.

In this example, if `apply` and its parameters were fully typed, strong mode would report a static error, and DDC would impose no runtime check.

### Generic methods

[Note: This is not yet implemented correctly.](https://github.com/dart-lang/dev_compiler/issues/301)

Similarly, DDC requires that [generic methods](GENERIC_METHODS.md) return the correct reified type.  In strong mode, `Iterable.map` is a generic method.  In DDC, `lengths` in `main` will have a reified type of `List<int>`.  In `foo`, this will trigger a runtime error when a string is added to the list.

```dart
void foo(List l) {
  l.add("a string");
}

void main() {
  Iterable<String> list = <String>["hello", "world"];
  List<int> lengths = list.map((x) => x.length).toList();
  foo(lengths);
  print(lengths[2]);
}
```

Standard checked mode would print `"a string"` without error.

## Is / As restrictions

In standard Dart, `is` and `as` runtime checks expose the unsoundness of the type system in certain cases.  For example, consider:

```dart
var list = <dynamic>["hello", "world"];
if (list is List<int>) {
  ...
} else if (list is List<String>) {
  ...
}
```

Perhaps surprisingly, the first test - `list is List<int>` - evaluates to true here.  Such code is highly likely to be erroneous.

Strong mode provides a stricter subtyping check and DDC enforces this at runtime.  For compatibility with standard Dart semantics, however, DDC throws a runtime error when an `is` or `as` check would return a different answer with strong mode typing semantics.

In the example above, the first `is` check would generate a runtime error.

Note, we are exploring making this a static error or warning in strong mode.  In general, an expression:

```dart
x is T
```

or

```dart
x as T
```

is only guaranteed safe when `T` is a *ground type*:

- A non-generic class type (e.g., `Object`, `String`, `int`, ...).
- A generic class type where all type parameters are implicitly or explicitly `dynamic` (e.g., `List<dynamic>`, `Map`, …).
- A function type where the return type and all parameter types are `dynamic` (e.g., (`dynamic`, `dynamic`) -> `dynamic`, ([`dynamic`]) -> `dynamic`).
