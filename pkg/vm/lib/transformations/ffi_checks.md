# FFI static checks

## Translating FFI types

The FFI library defines a number of "native" types, which have corresponding
Dart types. This is a many-to-one mapping, defined by `DartRepresentationOf` in
`native_type.dart`.

## Subtyping restrictions

No class may extend, implement or mixin any classes inside the FFI library, with
the following exception. Any class may extend (but not implement or mixin)
`ffi.Struct`. In this case, the subclass is considered a *struct class*. No
class may extend, implement or mixin a struct class.

## Struct rules

The following restrictions apply to struct classes:

- A struct class must not be generic.
- A struct class `X` must extend `Struct<X>`. That is, the type argument to the
  superclass must be exactly the subclass itself.

Some restrictions apply to fields of struct classes:

- A field of a struct class must not have an initializer.
- A field of a struct class must either have a type which is a subtype of
  `ffi.Pointer` or else be annotated by one of the following types:
    - `ffi.UintN` or `ffi.IntN` for any N
    - `ffi.Float` or `ffi.Double`
  If the field is annotated, the Dart version of the annotated type must be
  identical to the field's declared type. Note that struct classes currently
  must not be used as fields.
- A field of a struct class must not have more than one annotation corresponding
  to an FFI native type.

Finally, struct classes must not have constructors with field initializers.

## `fromFunction` rules

The following restrictions apply to static invocations of the factory
constructor `Pointer<T>.fromFunction(f, e)`. Dynamic invocations of this method,
e.g. through mirrors, are runtime errors. `T` must be a subtype of
`NativeFunction<T'>` for some `T'`. Let `F` be the Dart type which corresponds
to static type of `T'` and `R` be the return type of `F`.

- `T` must be instantiated; i.e., it must not reference any class or function
  type parameters.
- The static type of `f` must be a subtype of `F`.
- Struct classes are not allowed as the top-level class in a parameter or return
  type of `F`.
- The static type of `e` must be a subtype of `R`.
- `e` must be an expression which is legal in a constant context.
- `f` must be a direct reference to a top-level method.
- `e` must not be provided if `R` is `void` or `ffi.Pointer`.
- `e` must be provided otherwise.

## `asFunction` and `lookupFunction ` rules

The following restrictions apply to statically resolved invocations of the
instance method `Pointer<T>.asFunction<F>()` and
`DynamicLibrary.lookupFunction<S, F>()`. Dynamic invocations of these methods,
e.g. through mirrors or a receiver of static type `dynamic`, are runtime errors.
`T` must be a subtype of `NativeFunction<T'>` for some `T'`. Let `F'` be the
Dart type which corresponds to static type of `T'`/`S`.

- `T`, `S` and `F` must be constants; i.e., they must not reference any class or
  function type parameters.
- `F'` must be a subtype of `F`.
