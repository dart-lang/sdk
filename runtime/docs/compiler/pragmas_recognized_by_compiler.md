# @pragma annotations recognized by the compiler.

## Annotations for return types and field types.

The VM is not able to see across method calls (apart from inlining) and
therefore does not know anything about the return'ed values of calls, except for
the interface type of the signature.

To improve this we have two types of additional information sources the VM
utilizes to gain knowledge about return types:

   - inferred types (stored in kernel metadata): these are computed by global
     transformations (e.g. TFA) and are only available in AOT mode

   - @pragma annotations: these are recognized in JIT and AOT mode

This return type information is mainly used in the VM's type propagator.

Since those annotations side-step the normal type system, they are unsafe and we
therefore restrict those annotations to only have an affect inside dart:
libraries.

### @pragma("vm:exact-result-type", <type>) annotation

Tells the VM about the exact result type (i.e. the exact class-id) of a function
or a field load.

There are two limitations on this pragma:

0. The Dart object returned by the method at runtime must have **exactly** the type specified in the annotation (not a subtype).

1. The exact return type declared in the pragma must be a subtype of the interface type declared in the method signature.
   Note that this restriction is not enforced automatically by the compiler.

If those limitations are violated, undefined behavior may result.
Note that since `null` is an instance of the `Null` type, which is a subtype of any other, exactness of the annotated result type implies that the result must be non-null.

#### Syntax

```dart
class A {}
class B extends A {}

// Reference to type via type literal
@pragma("vm:exact-result-type", B)
A foo() native "foo_impl";

// Reference to type via path
@pragma("vm:exact-result-type", "dart:core#_Smi");
int foo() native "foo_impl";

class C {
  // Reference to type via type literal
  @pragma('vm:exact-result-type', B)
  final B bValue;

  // Reference to type via path
  @pragma('vm:exact-result-type', "dart:core#_Smi")
  final int intValue;
}
```

### @pragma("vm:non-nullable-result-type") annotation

Tells the VM that the method/field cannot return `null`.

There is one limitation on this pragma:

0. The Dart object returned by the method at runtime **must not** return `null`.

If this limitation is violated, undefined behavior may result.

#### Syntax

```dart
@pragma("vm:non-nullable-result-type")
A foo() native "foo_impl";

class C {
  @pragma('vm:non-nullable-result-type");
  final int value;
}
```
