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
app = instantiate(app_module, {wasm_dev_rt: rt});
app.main();
```

## Static calls

Statics (top-level functions, static methods, and constructors) are represented
by a fully resolved label (like `package:foo/foo.dart::Foo.bar`). The runtime
maps labels to IDs and IDs to functions. Each call looks up its target by ID.

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
rt.lookupStatic(barId)();
```

## Instance calls

The runtime maps class labels and member names to IDs.
Each class defines its superclass and members.
Calls are dispatched by resolving a member ID from the receiver's class,
walking its superclass hierarchy.

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
rt.startInstanceMemberDefinitions(greeterId);
rt.defineInstanceMember(greeterId, messageId, Greeter.message);
rt.defineInstanceMember(greeterId, greetId, Greeter.greet);
rt.endInstanceMemberDefinitions(greeterId);

// WorldGreeter
worldGreeterId = rt.classId('package:foo/foo.dart::WorldGreeter');
rt.defineClassSupers(worldGreeterId, greeterId);
worldGreeterNewId = rt.staticId('package:foo/foo.dart::WorldGreeter.new');
rt.defineStatic(worldGreeterNewId, WorldGreeter.new);
rt.startInstanceMemberDefinitions(worldGreeterId);
rt.defineInstanceMember(worldGreeterId, messageId, WorldGreeter.message);
rt.endInstanceMemberDefinitions(worldGreeterId);

// main
o = {classId: worldGreeterId};
rt.lookupStatic(worldGreeterNewId)(o);
rt.findTarget(o.classId, greetId)(o);

// Greeter.greet
print(rt.findTarget(this.classId, messageId)(this));
```
