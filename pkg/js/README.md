[![pub package](https://img.shields.io/pub/v/js.svg)](https://pub.dev/packages/js)
[![package publisher](https://img.shields.io/pub/publisher/js.svg)](https://pub.dev/packages/js/publisher)

**Important:** Prefer using `dart:js_interop` instead of this package for JS
interop. See the [JS interop documentation] for more details.

Use this package when you want to call JavaScript APIs from Dart code, or vice
versa.

This package's main library, `js`, provides annotations and functions that let
you specify how your Dart code interoperates with JavaScript code. The
Dart-to-JavaScript compilers — dartdevc and dart2js — recognize these
annotations, using them to connect your Dart code with JavaScript.

A second library in this package, `js_util`, provides low-level utilities that
you can use when it isn't possible to wrap JavaScript with a static, annotated
API.

[JS interop documentation]: https://dart.dev/interop/js-interop

## Static Interop

**Important:** Static interop is now supported with extension types in Dart 3.3.
Prefer using `dart:js_interop` with extension types instead of `@staticInterop`.
See the [JS interop documentation] for more details.

In the past, `package:js` has allowed users to use JavaScript interoperability
in more dynamic, class-based ways. While we will continue to allow users to use
that functionality in the foreseeable future, Dart is transitioning to a more
static, inline class-based interop. What this largely means is that we're moving
away from dynamic invocations and instead requiring static typing to use
interop. We're calling this model "static interop".

We are doing this for several reasons, such as idiomaticity, performance, type
soundness, ability to interop with DOM types, and compatibility with Wasm. This
is an ongoing effort that will affect our web library offerings as well.

In version 0.6.6, we introduced a way to use static interop with
`@staticInterop`. `package:js` classes that have this annotation are required
to use the new static semantics via extensions and do not support dynamic
invocations. For more details on how to use `@staticInterop` classes, see below.
To test these classes, see the sections below on `@JSExport` and
`js_util.createStaticInteropMock`.

As this is an ongoing effort, we are also working on interop with inline
classes. [Inline classes][] will be a new language feature that enables
zero-cost wrapping. In the future, users should opt-in to the semantics of
static interop using inline classes instead of `@staticInterop`. It will be
easier to use, more idiomatic, and better supported going forward.

For now, static interop remains experimental and in development. We may make
breaking changes in the future. We'll update this text when the new interop
model matures and is considered stable.

[Inline classes]: https://github.com/dart-lang/language/issues/2727

## Usage

The following examples show how to handle common interoperability tasks.

### Calling JavaScript functions

```dart
@JS()
library stringify;

import 'package:js/js.dart';

// Calls invoke JavaScript `JSON.stringify(obj)`.
@JS('JSON.stringify')
external String stringify(Object obj);
```

### Using JavaScript namespaces and classes

```dart
@JS('google.maps')
library maps;

import 'package:js/js.dart';

// Invokes the JavaScript getter `google.maps.map`.
external Map get map;

// The `Map` constructor invokes JavaScript `new google.maps.Map(location)`
@JS()
class Map {
  external Map(Location location);
  external Location getLocation();
}

// The `Location` constructor invokes JavaScript `new google.maps.LatLng(...)`
//
// We recommend against using custom JavaScript names whenever
// possible. It is easier for users if the JavaScript names and Dart names
// are consistent.
@JS('LatLng')
class Location {
  external Location(num lat, num lng);
}
```

### Passing object literals to JavaScript

Many JavaScript APIs take an object literal as an argument. For example:

```js
// JavaScript
printOptions({ responsive: true });
```

If you want to use `printOptions` from Dart a `Map<String, dynamic>` would be
"opaque" in JavaScript.

Instead, create a Dart class with both the `@JS()` and `@anonymous` annotations.

```dart
@JS()
library print_options;

import 'package:js/js.dart';

void main() {
  printOptions(Options(responsive: true));
}

@JS()
external printOptions(Options options);

@JS()
@anonymous
class Options {
  external bool get responsive;

  // Must have an unnamed factory constructor with named arguments.
  external factory Options({bool responsive});
}
```

### Making a Dart function callable from JavaScript

If you pass a Dart function to a JavaScript API as an argument, wrap the Dart
function using `allowInterop()` or `allowInteropCaptureThis()`.

To make a Dart function callable from JavaScript _by name_, use a setter
annotated with `@JS()`.

```dart
@JS()
library callable_function;

import 'package:js/js.dart';

/// Allows assigning a function to be callable from `window.functionName()`
@JS('functionName')
external set _functionName(void Function() f);

/// Allows calling the assigned function from Dart as well.
@JS()
external void functionName();

void _someDartFunction() {
  print('Hello from Dart!');
}

void main() {
  _functionName = allowInterop(_someDartFunction);
  // JavaScript code may now call `functionName()` or `window.functionName()`.
}
```

### @staticInterop

With `package:js`, we have historically had two different types of classes:
plain `@JS` (those with just the `@JS` annotation) and `@anonymous` classes.
Now, you can use a new one: `@staticInterop`.

These classes are different in that they do not allow instance members within
the class itself. All such members need to go into an extension (hence
“static”). Let’s look at an example:

```dart
@JS()
library static_interop;

import 'package:js/js.dart';

// Assumes there is a top-level `StaticInterop` class in a JS module.
@JS()
@staticInterop
class StaticInterop {
  external factory StaticInterop();
}

extension on StaticInterop {
  external int field;
  external int get getSet;
  external set getSet(int val);
  external int method();
}

void main() {
  var jsObj = StaticInterop();
  jsObj.field = 1;
  jsObj.method();
}
```

The `external` static extension members get lowered to JS naturally:
`jsObj.field` becomes a property get of `field` in JS and `jsObj.method()`
becomes a function invocation of `method` on `jsObj`.

In many ways, these classes are just like the plain `@JS` and `@anonymous`
classes. Like with plain `@JS` classes, you can provide a value in `@JS` if you
want the constructor to use a particular JS class e.g.
`@JS(‘module.MyJSClass’)`. You can also add `@anonymous` to `@staticInterop`
classes if you want the factory constructor with named arguments in order to
make an object literal e.g.
`external factory AnonymousStaticInterop({int? field1, int? field2})`. Also like
with plain `@JS` classes, you can’t inherit non-`package:js` classes. You should
only inherit other `@staticInterop` classes for subtyping and inheriting
extension methods. Lastly, you can freely cast JS objects to and from the three
types of `package:js` classes.

What makes `@staticInterop` unique, however, is that you can use them to
represent DOM objects as well as other JS objects, which you can’t with previous
`package:js` classes. Historically, you’ve needed to use `dart:html` to interact
with the DOM e.g. `DivElement`. Now, you can create your own abstraction for
these objects instead of using the ones we provide in `dart:html`:

```dart
@JS()
library static_interop;

import 'dart:html' as html;

import 'package:js/js.dart';

@JS()
@staticInterop
class JSWindow {}

extension JSWindowExtension on JSWindow {
  external String get name;
  String get nameAllCaps => name.toUpperCase();
}

void main() {
  var jsWindow = html.window as JSWindow;
  print(jsWindow.name.toUpperCase() == jsWindow.nameAllCaps);
}
```

Note that you can have both `external` and non-`external` members in the
extension.

Compared to non-`@staticInterop` `package:js` classes, `@staticInterop` classes:

- Are more performant
- Have better type guarantees
- Generate less code
- Allow non-`external` members
- Allow `external` extension members to be renamed using `@JS()` e.g.
  `@JS('renamedField')`

The only catch is that virtual/dynamic dispatch is _disallowed_. That means
methods are resolved using only the _static_ type of the object.

In general, it's advised to use `@staticInterop` wherever you can, as future JS
interop will only target static dispatch.

### @JSExport and js_util.createDartExport

One of the difficulties with JS interop is that most of it is exclusively
focused on importing JS code to Dart, not the other way around. We have some
functionality like `allowInterop`, which allows you to call Dart functions in
JS, but this becomes cumbersome when you want to use a Dart object. You need to
essentially `allowInterop` all members manually.

`createDartExport` instead lets you do this automatically. Let’s see how with an
example:

```dart
import 'dart:js_util';

import 'package:expect/minitest.dart';
import 'package:js/js.dart';

// The Dart class must have `@JSExport` on it or one of its instance members.
@JSExport()
class Counter {
  int value = 0;
  @JSExport('increment')
  void renamedIncrement() {
    value++;
  }
}

@JS()
@staticInterop
class JSCounter {}

extension on JSCounter {
  external int value;
  external void increment();
}

void main() {
  var dartCounter = Counter();
  var counter = createDartExport<Counter>(dartCounter) as JSCounter;
  expect(counter.value, 0);
  counter.increment();
  expect(counter.value, 1);
  expect(dartCounter.value, 1); // Dart object gets modified
  dartCounter.value = 0;
  expect(counter.value, 0); // Changes in Dart object affect the exported object
}
```

There are a number of things happening here. At a high level, you pass
`createDartExport` an instance of some Dart object that has `@JSExport` either
on it or one of its instance members and the object’s static type if needed.
Using the static type, we transform the `createDartExport` call into a JS object
literal that is a mapping from each member’s Dart name (accounting for renames
using the `@JSExport` annotation) to the member. The JS object essentially wraps
and acts as a proxy to the exported Dart object.

Now, when we use it as a JS object (in this case, using `@staticInterop`), we
can use the same names to access these members. We can also use the same syntax
to access these members e.g. `counter.value = 0`. This now gives us an easy to
do what we wanted before with `allowInterop` for each member.

There are, of course, limitations.

The only members that are “exported” are concrete instance members i.e. fields,
getters, setters, and methods. That means you can’t export static members,
constructors, factories, operators (the syntax complicates things), and
extension methods. You can still have these members - they just won’t be present
in the resulting exported object. Of course, you can use another instance member
to call these members as well, and _that_ instance member will be exported.

In order to use `createDartExport`, you need to have a class that uses
`@JSExport`.If you want to export only some members of a class, omit the
annotation on the class, and only use it on the members you want. If you need to
rename members, you can provide the `@JSExport` annotation on that member a
string value, similar to renaming done via `@JS()`. Inheritance respects the
individual superclass’ annotations. In other words, if the class of the object
you want to export has a superclass, but that superclass has no `@JSExport`
annotation anywhere, none of its superclass’ members are exported.

Lastly, different members can’t have the same export name, unless they are a
getter and setter pair. So, for example, if you have a field and a method and
one of them is renamed to the other’s name, that’s a conflict:

```dart
@JSExport()
class DartClass {
  int member = 0;
  @JSExport('member') // Two incompatible members have the same export name.
  void method() {}
}
```

This holds true with inheritance as well, unless the member is overridden.

### js_util.createStaticInteropMock

One of the neat things about the above example with `Counter` is we’ve
essentially created a mock for `JSCounter`. In the past, to mock a plain `@JS`
or `@anonymous` class, you could create a Dart class that `implements` that
interop class, and due to Dart's virtual dispatch, this would call the Dart
class' members instead. Now that we're using `external` extension members, this
no longer works. We now have to mock at the _JS level_ instead. With
`createDartExport`, you’re essentially using a Dart object to replace a JS
object. This functionality is equivalent to mocking at the JS level, and you can
also use it to mock the old non-`@staticInterop` `package:js` classes!

One useful feature of the old style of mocking using `implements` is it lets you
know if you've implemented the needed members. We can't do that with
`createDartExport`. For example:

```dart
@JSExport()
class Counter {
  // Where is `value` and `increment`?
}
```

This would obviously not be a satisfactory mock for `JSCounter`.
`createDartExport` has no idea what class you're trying to mock, so it can't
tell you if you’ve got your mock class right.

This is where `createStaticInteropMock` comes in. It takes in a separate type
argument, e.g. `createStaticInteropMock<JSCounter, Counter>(Counter())`, to
determine whether mocking _conformance_ is satisfied. This type argument must be
a `@staticInterop` class. With this, you’ll see an error saying that you haven’t
implemented all the needed members. If the mock class implements all the needed
members, the function does the same thing as `createDartExport`, and returns an
object literal that wraps the Dart object.

You can also use `package:mockito` to do the mocking with this API, by providing
a generated mocking object from `package:mockito` to `createStaticInteropMock`.

There are some corner cases here that are worth noting.

It is possible, through the expressiveness of extension methods, to have name
conflicts like this:

```dart
@JS()
@staticInterop
class StaticInterop {}

extension A on StaticInterop {
  external Function member;
}

extension B on StaticInterop {
  external void member();
}
```

This present an issue as a single Dart class cannot implement `member` as both a
field and a function. So, what to do? We require that you only implement _one_
of these members. So, either a Function field or a function are satisfactory.

It is also sometimes desired that the mocking object is the same underlying type
as the JS object you are interfacing. For example, if you want to mock a JS
`Element`, you’d want the type of the mocking object to also be a `Element` in
order to pass `instanceof` checks. In order to do this, we let users pass the JS
prototype of the type they want the mocking object to be as an argument to
`createStaticInteropMock`.

An important note here is that `createStaticInteropMock` looks for _all_
extensions of the `@staticInterop` type in the program, even if they are out of
scope of the current file. In order to avoid a case where other libraries
extending the `@staticInterop` type break your usage of
`createStaticInteropMock`, you should try to only use this API in tests.
`createStaticInteropMock` is meant to detect issues earlier at compile-time, but
if it's too restrictive, you can still use `createDartExport` to workaround that
(and please provide us feedback on why it's restrictive!).

## Reporting issues

Please file bugs and feature requests on the [SDK issue tracker][issues].

[issues]: https://goo.gl/j3rzs0

## Known limitations and bugs

<!-- [TODO: add intro. perhaps move this to another page?] -->

### Differences between dart2js and dartdevc

Dart's production and development JavaScript compilers use different calling
conventions and type representation, and therefore have different challenges in
JavaScript interop. There are currently some known differences in behavior and
bugs in one or both compilers.

#### Dartdevc and dart2js have different representation for Maps

Passing a `Map<String, String>` as an argument to a JavaScript function will
have different behavior depending on the compiler. Calling something like
`JSON.stringify()` will give different results.

**Workaround:** Only pass object literals instead of Maps as arguments. For json
specifically use `jsonEncode` in Dart rather than a JS alternative.

#### Missing validation for anonymous factory constructors in dartdevc

When using an `@anonymous` class to create JavaScript object literals dart2js
will enforce that only named arguments are used, while dartdevc will allow
positional arguments but may generate incorrect code.

**Workaround:** Try builds in both development and release mode to get the full
scope of static validation.

### Common problems

Dart and JavaScript have different semantics and common patterns, which makes it
easy to make some mistakes and difficult for the tools to provide safety. These
common problems are also known as _sharp edges_.

#### Lack of runtime type checking

The return types of methods annotated with `@JS()` are not validated at runtime,
so an incorrect type may "leak" into other Dart code and violate type system
guarantees. This is not true for `@staticInterop` classes unless the
`@trustTypes` annotation is used.

**Workaround:** For any calls into JavaScript code that are not known to be safe
in their return values, validate the results manually with `is` checks.

#### List instances coming from JavaScript will always be `List<dynamic>`

A JavaScript array does not have a reified element type, so an array returned
from a JavaScript function cannot make guarantees about it's elements without
inspecting each one. At runtime a check like `result is List` may succeed, while
`result is List<String>` will always fail.

**Workaround:** Use `.cast()` or construct a new `List` to get an instance with
the expected reified type. For instance if you want a `List<String>` use
`.cast<String>()` or `List<String>.from`.

#### The `JsObject` type from `dart:js` can't be used with `@JS()` annotation

`JsObject` and related code in `dart:js` uses a different approach and may not
be passed as an argument to a method annotated with `@JS()`.

**Workaround:** Avoid importing `dart:js` and only use the `package:js` provided
approach. To handle object literals use `@anonymous` on an `@JS()` annotated
class.

#### `is` checks and `as` casts between JS interop types will always succeed

For any two `@JS()` types, with or without `@anonymous`, a check of whether an
object of one type `is` another type will always return true, regardless of
whether those two types are in the same prototype chain. Similarly, an explicit
cast using `as` will also succeed.
