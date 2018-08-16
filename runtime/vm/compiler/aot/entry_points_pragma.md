# Entry points @pragma annotations

Dart VM precompiler (AOT compiler) performs whole-program optimizations such as
tree shaking in order to decrease size of the resulting compiled apps and
improve their performance. Such optimizations assume that compiler can see the
whole Dart program, and is able to discover and analyze all Dart functions and
members which can be potentially executed at run time. While the Dart code is
fully available for precompiler, native code of the embedder and native methods
are out of reach of the compiler. Such native code can call back to Dart via
native Dart API.

In order to aid precompiler, programmer can explicitly list entry points
(roots) - Dart classes and members which are accessed from native code. Note
that listing entry points is not optional: as long as program defines native
methods which call into Dart, the entry points are required for the correctness
of compilation.

# Pragma annotation

The annotation `@pragma("vm:entry-point", ...)` can be placed on a class or
member to indicate that it may be allocated or invoked directly from native or
VM code. The allowed uses of the annotation are as follows.

## Classes

Any one of the following forms may be attached to a class:

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
class C { ... }
```

If the second parameter is missing, `null` or `true`, the class will be
available for allocation directly from native or VM code.

## Procedures

Any one of the following forms may be attached to a procedure (including
getters, setters and constructors):

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
void foo() { ... }
```

If the second parameter is missing, `null` or `true`, the procedure will
available for lookup and invocation directly from native or VM code. If the
procedure is a *generative* constructor, the enclosing class will also be marked
for allocation from native or VM code.

## Fields

Any one of the following forms may be attached to a non-static field. The first
three forms may be attached to static fields.

```dart
@pragma("vm:entry-point")
@pragma("vm:entry-point", null)
@pragma("vm:entry-point", true/false)
@pragma("vm:entry-point", !const bool.formEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get"/"set")
void foo() { ... }
```

If the second parameter is missing, `null` or `true, the field is marked for
native access and for non-static fields the corresponding getter and setter in
the interface of the enclosing class are marked for native invocation. If the
'get'/'set' parameter is used, only the getter/setter is marked. For static
fields, the implicit getter is always marked. The third form does not make sense
for static fields because they do not belong to an interface.
