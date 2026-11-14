# Wasm Dev Compiler Design Notes

The Wasm dev compiler has three major parts:

- **Compiler** (`pkg/dart2wasm/lib/dev`): compiles Dart to kernel to CFG IR to
  Wasm. Outputs wasm dev modules that each import the runtime.
- **Runtime** (`pkg/wasm_dev_rt`): a dart2wasm-compiled app that holds shared
  module state.
- **Bootstrapper** (`pkg/dart2wasm/bin/run_wasm_dev.js`): instantiates the
  runtime, passes it to the app's modules, then calls `main`.

## Bootstrapper

All of the app's modules import the runtime. Apps define and look up
state-bearing elements (like classes, members, and statics) via the runtime.

```js
rt = instantiate(wasm_dev_rt);
modules = app_modules.map((m) => instantiate(m, {wasm_dev_rt: rt}));
modules[0].main();
```

## Static calls

Statics (top-level functions, static methods, and constructors) are represented
by a fully resolved label (like `package:foo/foo.dart::Foo.bar`). The runtime
maps labels to IDs and IDs to functions in a Wasm table
(`static-functions-table`). Each call invokes its target by ID using
`call_indirect`.

```dart
// package:foo/foo.dart
class Foo {
  static int bar() => 1;
}

void main() => Foo.bar();
```

compiles to:

```
// Once on module init
barId = rt.staticId('package:foo/foo.dart::Foo.bar');
rt.defineStatic(barId, Foo.bar);

// main
rt.staticFunctionsTable[barId]();
```

## Instance calls

The runtime maps class labels, member names, and shapes to IDs.
A shape is a member's positional parameter count and named parameters (sorted),
like `1,a,b` for `foo(x, {b, a})`.
Each class defines its superclass and members by name and shape.
Calls are dispatched by resolving a member ID and shape ID from the receiver's
class, walking its superclass hierarchy.

```dart
// package:foo/foo.dart
class Greeter {
  String message() => 'Hello!';
  void greet() => print(message());
}

class WorldGreeter extends Greeter {
  @override
  String message() => 'Hello, world!';
}

void main() => WorldGreeter().greet();
```

compiles to:

```
// Once on module init

// Greeter
greeterId = rt.classId('package:foo/foo.dart::Greeter');
objectId = rt.classId('dart:core::Object');
rt.defineClassSupers(greeterId, objectId);
greeterNewId = rt.staticId('package:foo/foo.dart::Greeter.new');
rt.defineStatic(greeterNewId, Greeter.new);
messageId = rt.instanceMemberId('message');
greetId = rt.instanceMemberId('greet');
shape0Id = rt.shapeId('0');
rt.startInstanceMemberDefinitions(greeterId);
rt.defineInstanceMember(greeterId, messageId, shape0Id, Greeter.message);
rt.defineInstanceMember(greeterId, greetId, shape0Id, Greeter.greet);
rt.endInstanceMemberDefinitions(greeterId);

// WorldGreeter
worldGreeterId = rt.classId('package:foo/foo.dart::WorldGreeter');
rt.defineClassSupers(worldGreeterId, greeterId);
worldGreeterNewId = rt.staticId('package:foo/foo.dart::WorldGreeter.new');
rt.defineStatic(worldGreeterNewId, WorldGreeter.new);
rt.startInstanceMemberDefinitions(worldGreeterId);
rt.defineInstanceMember(
    worldGreeterId, messageId, shape0Id, WorldGreeter.message);
rt.endInstanceMemberDefinitions(worldGreeterId);

// main
o = {classId: worldGreeterId};
rt.staticFunctionsTable[worldGreeterNewId](o);
rt.findTarget(o.classId, greetId, shape0Id)(o);

// Greeter.greet
print(rt.findTarget(this.classId, messageId, shape0Id)(this));
```

## Calling convention

Every function accepts its parameters: the receiver (for instance members and
constructors), positional parameters (in order), then named parameters (sorted).
Omitted optional parameters are passed a sentinel, which callees replace with
their default value.

Besides the receiver, all arguments and return values are top-typed (and so
boxed when necessary).

```dart
class Greeter {
  String greet(String name, {String? title = 'Dr.', bool loud = false}) =>
      name;
}

String staticGreet(String name, {String? title = 'Dr.', bool loud = false}) =>
    name;

void greetAll(Greeter g) {
  g.greet('Jekyll', title: null);
  staticGreet('Jekyll', title: null);
}
```

compiles to:

```
// Once on module init
greetShapeId = rt.shapeId('1,loud,title');

// Greeter.greet(this, name, loud, title)
final loud_ = identical(loud, sentinel) ? false : unbox(loud);
title = identical(title, sentinel) ? box('Dr.') : title;

// staticGreet(name, loud, title)
final loud_ = identical(loud, sentinel) ? false : unbox(loud);
title = identical(title, sentinel) ? box('Dr.') : title;

// greetAll
rt.findTarget(g.classId, greetId, greetShapeId)(
    g, box('Jekyll'), sentinel, null);
rt.staticFunctionsTable[staticGreetId](box('Jekyll'), sentinel, null);
```
