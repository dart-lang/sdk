# Deeply immutable instances and types

The Dart VM has a concept of deeply immutable instances.

Deeply immutable instances can be shared across isolates within the same group.

## Deeply immutable types

A deeply immutable type is a type for which all instances that have this type are deeply immutable.

This is useful for static checks on classes annotated `@pragma('vm:deeply-immutable')`.
All the instance fields of such classes must have a deeply immutable type.

A list of immutable types:

* `bool`
* `double`
* `int`
* `Null`
* `String`
* `Float32x4`
* `Float64x2`
* `Int32x4`
* `Pointer`
* classes annotated with `@pragma('vm:deeply-immutable')`
* type parameters bound by a deeply immutable type

## Deeply immutable instances without a deeply immutable type

In addition to instances from deeply immutable types,
instances can also be deeply immutable while their type is not deeply immutable:

* `SendPort` (implemented externally `package:isolate`, so cannot be `final` https://github.com/dart-lang/sdk/issues/54885#issuecomment-1967329435)
* `Capability` (has `SendPort` as subtype so cannot be `final`)
* `RegExp` (can be implemented externally, not `final`)
* `StackTrace` (can be implemented externally, not `final`)
* `Type` (can be implemented externally, not `final`)
* const object (the class can be deeply immutable)

This means users cannot mark classes with fields typed with these types as `@pragma('vm:deeply-immutable')`.

## Shallowly immutable instances

The VM also has shallow immutability.

* unmodifiable typed data views (the backing view might not be immutable)
* closures (the context might not be empty)

## Implementation details

### Deeply and shallowly immutable instances

The `UntaggedObject::ImmutableBit` tracks whether an instance is deeply or shallowly immutable at runtime.
For shallow immutable objects, the VM needs to know the layout and what to check when to check for to check deep immutability at runtime.

### Deeply immutable types

The `Class::is_deeply_immutable` tracks whether all instances of a class are deeply immutable.

This bit can be set in two ways:

1. For recognized classes, in the VM initialization.
2. For classes with a Dart source, with the `vm:deeply-immutable` pragma.

The `vm:deeply-immutable` pragma is added to classes of which their _type_ is deeply immutable.

This puts the following restrictions on these classes:

1. All instance fields must
   1. have a deeply immutable type,
   2. be final, and
   3. be non-late.
2. The class must be `final` or `sealed`.
   This ensures no non-deeply-immutable subtypes are added by external code.
3. All subtypes must be deeply immutable.
   This ensures 1.1. can be trusted.
4. The super type must be deeply immutable (except for Object).

These restructions are enforced by [DeeplyImmutableValidator](../../pkg/vm/lib/transformations/ffi/deeply_immutable.dart).
