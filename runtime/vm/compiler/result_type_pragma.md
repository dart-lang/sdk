# Result type @pragma annotations

To facilitate type-flow analysis and other optimizations, Dart methods may use the pragma `vm:exact-result-type` to declare an exact return type different than the return type in the signature of the method. There are three limitations on this pragma:

0. The Dart object returned by the method at runtime must have exactly the type specified in the annotation (not a subtype).

1. The exact return type declared in the pragma must be a subtype of the return type declared in the method signature.
   Note that this restriction is not enforced automatically by the compiler.

2. `vm:exact-result-type` may only be attached to methods in the core library.
   This pragma can introduce unsafe behavior since it allows the compiler to make stronger assumptions during optimization than what the sound strong-mode type system allows, so it is only allowed in the core library where the Dart VM team can ensure that it is not misused.

If limitations 0 or 1 are violated, undefined behavior may result.
Note that since `null` is an instance of the `Null` type, which is a subtype of any other, exactness of the annotated result type implies that the result must be non-null.

## Syntax

### Reference to type via type literal

```dart
class A {}
class B extends A {}

@pragma("vm:exact-result-type", B)
A foo() native "foo_impl";
```

### Reference to type via path

```dart
@pragma("vm:exact-result-type", "dart:core#_Smi");
int foo() native "foo_impl";
```
