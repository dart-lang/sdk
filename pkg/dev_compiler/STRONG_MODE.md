# Strong Mode

**Note: This document is out of date.  Please see [Sound Dart](https://dart.dev/guides/language/sound-dart) for up-to-date
documentation on Dart's type system.  The work below was a precursor towards Dart's current type system.**


Strong mode applies a more restrictive type system to Dart to address its unsound, surprising behavior in certain cases.

Strong mode helps with:

- [Stronger static checking](doc/STATIC_SAFETY.md) to find more errors during static analysis or compilation.
  - This includes a [prototype of generic methods](doc/GENERIC_METHODS.md) for better expressiveness and checking.
- [Stronger runtime checking](doc/RUNTIME_SAFETY.md) in the Dart Dev Compiler (DDC) to find errors at runtime.
- [Idiomatic JavaScript code generation](doc/JS_CODEGEN.md) via DDC for more readable output and better interoperability.

## Motivation

Strong mode aims to ensure that static type annotations are actually correct at runtime.  For this to work, strong mode provides a stricter type system than standard Dart.  Consider the following example:

```dart
// util.dart

void info(List<int> list) {
  var length = list.length;
  if (length != 0) print(length + list[0]);
}
```

A developer might reasonably expect the `info` function to print either nothing (empty list) or a single integer (non-empty list), and that Dart’s static tooling and checked mode would enforce this.

However, in the following context, the info method prints “helloworld” in checked mode, without any static errors or warnings:

```dart
import 'dart:collection';
import 'util.dart';

class MyList extends ListBase<int> implements List {
   Object length;

   MyList(this.length);

   operator[](index) => 'world';
   operator[]=(index, value) {}
}

void main() {
   List<int> list = new MyList('hello');
   info(list);
}
```

The lack of static or runtime errors in the Dart specification's type rules is not an oversight; it is by design.  It provides developers a mechanism to circumvent or ignore types when convenient, but it comes at cost.  While the above example is contrived, it demonstrates that developers cannot easily reason about a program modularly: the static type annotations in the `util` library are of limited use, even in checked mode.

For the same reason, a compiler cannot easily exploit type annotations if they are unsound.  A Dart compiler cannot simply assume that a `List<int>` contains `int` values or even that its `length` is an integer.  Instead, it must either rely on expensive (and often brittle) whole program analysis or on additional runtime checking.  That [additional checking](doc/JS_CODEGEN.md) may lead to larger, slower code and harder-to-read output when Dart is transpiled to a high level language like JavaScript.

The fundamental issue above is that static annotations may not match runtime types, even in checked mode: this is a direct consequence of the unsoundness of the Dart type system.  This can make it difficult for both programmers and compilers to rely on static types to reason about programs.

Strong mode solves that by enforcing the correctness of static type annotations.  It disallows examples such as the above. In this example, standard Dart rules (checked or otherwise) allow `MyList` to masquerade as a `List<int>`.  Strong mode statically rejects the declaration of `MyList`.

DDC augments strong mode static checking with a minimal set of runtime checks required to enforce soundness, similar to how Java and C# handle potentially unsafe casts.  This allows both the developer and the compiler to better reason about the info method.  For statically checked code, both may assume that the argument is a proper `List<int>`, with integer-valued length and elements.

DDC execution is stricter than checked mode.  A Dart program execution where (a) the program passes DDC’s static checking and (b) the execution does not trigger DDC’s runtime assertions, will also run in checked mode on any Dart platform.
