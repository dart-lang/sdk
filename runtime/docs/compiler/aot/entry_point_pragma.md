# `vm:entry-point` pragma

The annotation `@pragma("vm:entry-point", ...)` **must** be placed on a class or
member to indicate that it may be resolved, allocated or invoked directly from
native or VM code _in AOT mode_.

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
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
class C { ... }
```

If the second parameter is missing, `null` or `true`, the class will be
available for allocation directly from native or VM code.

Note that `@pragma("vm:entry-point")` may be added to abstract classes -- in
this case, their name will survive obfuscation, but they won't have any
allocation stubs.

### Procedures

Any one of the following forms may be attached to a procedure (including
getters, setters and constructors):

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
void foo() { ... }
```

If the second parameter is missing, `null` or `true`, the procedure (and its
closurized form, excluding constructors and setters) will available for lookup
and invocation directly from native or VM code.

If the procedure is a *generative* constructor, the enclosing class must also be
annotated for allocation from native or VM code.

If the annotation is "get" or "call", the procedure will only be available for
closurization (access via `Dart_GetField`) or invocation (access via
`Dart_Invoke`).

"@pragma("vm:entry-point", "get") against constructors or setters is disallowed
since they cannot be closurized.

### Fields

Any one of the following forms may be attached to a non-static field. The first
three forms may be attached to static fields.

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", null)
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get"/"set")
int foo;
```

If the second parameter is missing, `null` or `true, the field is marked for
native access and for non-static fields the corresponding getter and setter in
the interface of the enclosing class are marked for native invocation. If the
'get'/'set' parameter is used, only the getter/setter is marked. For static
fields, the implicit getter is always marked. The third form does not make sense
for static fields because they do not belong to an interface.

Note that no form of entry-point annotation allows invoking a field.
