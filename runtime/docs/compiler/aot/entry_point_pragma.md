# `vm:entry-point` pragma

The annotation `@pragma("vm:entry-point", ...)` **must** be placed on a class or
member to indicate that it may be resolved, allocated or invoked directly from
native or VM code _in AOT mode_.

To reduce the differences between JIT and AOT mode, entry point annotations are
also checked in JIT mode except for uses of the `dart:mirrors` library and
debugging uses via the VM service.

## Background

Dart VM precompiler (AOT compiler) performs whole-program optimizations such as
tree shaking and type flow analysis (TFA) in order to decrease size of the
resulting compiled apps and improve their performance. Such optimizations
assume that compiler can see the whole Dart program, and is able to discover
and analyse all Dart functions and members which can be potentially executed at
run time. While the Dart code is fully available for precompiler, native code
of the embedder and native methods are out of reach of the compiler. Such
native code can call back to Dart via native Dart API.

In order to guide precompiler, programmer **must** explicitly list entry points
(roots) - Dart classes and members which are accessed from native code. Note
that listing entry points is not optional: as long as program defines native
methods which call into Dart, the entry points are required for the correctness
of compilation.

In addition, when obfuscation is enabled, the precompiler needs to know which
symbols need to be preserved to ensure they can be resolved from native code.

## Syntax

The allowed uses of the annotation are as follows.

### Classes

Any one of the following forms may be attached to a class:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
class C { ... }
```

If the second parameter is missing, `null` or `true`, the class will be
available for allocation directly from native or VM code.

Note that `@pragma("vm:entry-point")` may be added to abstract classes -- in
this case, their name will survive obfuscation, but they won't have any
allocation stubs.

### Getters

Any one of the following forms may be attached to getters:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
void get foo { ... }
```

The `"get"` annotation allows retrieval of the getter value via
`Dart_GetField`. `Dart_Invoke` can only be used with getters that return a
closure value, in which case it is the same as retrieving the closure via
`Dart_GetField` and then invoking the closure using `Dart_InvokeClosure`, so
the "get" annotation is also needed for such uses.

If the second parameter is missing, `null` or `true`, it behaves the same
as the `"get"` parameter.

Getters cannot be closurized.

### Setters

Any one of the following forms may be attached to setters:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "set")
void set foo(int value) { ... }
```

The `"set"` annotation allows setting the value via `Dart_SetField`.

If the second parameter is missing, `null` or `true`, it behaves the same
as the `"set"` parameter.

Setters cannot be closurized.

### Constructors

Any one of the following forms may be attached to constructors:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "call")
C(this.foo) { ... }
```

If the annotation is `"call"`, then the procedure is available for invocation
(access via `Dart_Invoke`).

If the second parameter is missing, `null` or `true`, it behaves the same
as the `"call"` parameter.

If the constructor is _generative_, the enclosing class must also be annotated
for allocation from native or VM code.

Constructors cannot be closurized.

### Other Procedures

Any one of the following forms may be attached to other types of procedures:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
void foo(int value) { ... }
```

If the annotation is `"get"`, then the procedure is only available for
closurization (access via `Dart_GetField`).

If the annotation is `"call"`, then the procedure is only available for
invocation (access via `Dart_Invoke`).

If the second parameter is missing, `null` or `true`, the procedure is available
for both closurization and invocation.

### Fields

Any one of the following forms may be attached to a non-static field. The first
three forms may be attached to static fields.

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", null)
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get"/"set")
int foo;
```

If the second parameter is missing, `null` or `true`, the field is marked for
native access and for non-static fields the corresponding getter and setter in
the interface of the enclosing class are marked for native invocation. If the
`"get"` or `"set"` parameter is used, only the getter or setter is marked. For
static fields, the implicit getter is always marked if the field is marked
for native access.

A field containing a closure may only be invoked using `Dart_Invoke` if the
getter is marked, in which case it is the same as retrieving the closure from
the field using `Dart_GetField` and then invoking the closure using
`Dart_InvokeClosure`.
