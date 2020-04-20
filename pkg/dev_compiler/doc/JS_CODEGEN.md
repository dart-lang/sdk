# Strong Mode and Idiomatic JavaScript

**Note: This document is out of date.  Please see [Sound Dart](https://dart.dev/guides/language/sound-dart) for up-to-date
documentation on Dart's type system.  The work below was a precursor towards Dart's current type system.**

The Dart Dev Compiler (DDC) uses [Strong Mode](STRONG_MODE.md) to safely generate
idiomatic JavaScript.  This enables better interoperability between Dart and JavaScript code.

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
