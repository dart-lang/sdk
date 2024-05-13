This package provides an experimental macro that encodes and decodes
user-defined Dart classes to JSON maps (maps of type `Map<String, Object?>`).

This relies on the experimental macros language feature, and as such may be
unstable or have breaking changes if the feature changes.

## Applying the JsonCodable macro

To apply the JsonCodable macro to a class, add it as an annotation:

```dart
import 'package:json/json.dart';

@JsonCodable()
class User {
  final String name;

  final int? age;
}
```

The macro generates two members for the `User` class: a `fromJson` constructor
and a `toJson` method, with APIs like the following:

```dart
class User {
  User.fromJson(Map<String, Object?> json);

  Map<String, Object?> toJson();
}
```

Each non-nullable field in the annotated class must have an entry with the same name in the `json` map, but
nullable fields are allowed to have no key at all. The `toJson` will omit null
fields entirely from the map, and will not contain explicit null entries.

### Extending other classes

You are allowed to extend classes other than `Object`, but they must have a
valid `toJson` method and `fromJson` constructor, so the following is allowed:

```dart
@JsonCodable()
class Manager extends User {
  final List<User> reports;
}
```

## Supported field types

All native JSON types are supported (`int`, `double`, `String`, `bool`, `Null`).

The core collection types `List`, `Set`, and `Map` are also supported, if their
elements are supported types. For elements which require more than just a cast,
the type must be statically provided through a generic type argument on the
collection in order for the specialized code to be generated.

Additionally, custom types with a `toJson` method and `fromJson` constructor are
allowed, including as generic type arguments to the collection types.

## Generics

Classes with generic type parameters are not supported, but may be in the
future.

## Configuration

Macro configuration is a feature we intend to add, but it is not available at this time.

Because of this, field names must exactly match the keys in the maps, and
default values are not supported.

## Enabling the macros experiment

Most tools accept the `--enable-experiment=macros` option, and appending that
to your typical command line invocations should be all that is needed. For
example, you can launch your flutter project like:
`flutter run --enable-experiment=macros`.

For the analyzer, you will want to add some configuration to an
`analysis_options.yaml` file at the root of your project:

```yaml
analyzer:
  enable-experiment:
    - macros
```

Note that `dart run` is a little bit special, in that the option must come
_immediately_ following `dart` and before `run` - this is because it is an
option to the Dart VM, and not the Dart script itself. For example,
`dart --enable-experiment=macros run bin/my_script.dart`. This is also how the
`test` package expects to be invoked, so `dart --enable-experiment=macros test`.
