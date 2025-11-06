// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'helper.dart';

const _typeKey = 'type';
const _valueKey = 'value';

/// A constant value that can be recorded and serialized.
///
/// This supports basic constants such as [bool]s or [int]s, as well as
/// [ListConstant], [MapConstant] or [InstanceConstant] for more complex
/// structures.
///
/// This follows the AST constant concept from the Dart SDK.
sealed class Constant {
  /// Creates a [Constant] object.
  const Constant();

  /// Converts this [Constant] object to a JSON representation.
  ///
  /// [constants] needs to be passed, as the [Constant]s are normalized and
  /// stored separately in the JSON.
  Map<String, Object?> toJson(Map<Constant, int> constants);

  /// Converts this [Constant] to the value it represents.
  Object? toValue() => switch (this) {
    NullConstant() => null,
    PrimitiveConstant p => p.value,
    ListConstant<Constant> l => l.value.map((c) => c.toValue()).toList(),
    MapConstant<Constant> m => m.value.map(
      (key, value) => MapEntry(key, value.toValue()),
    ),
    InstanceConstant i => i.fields.map(
      (key, value) => MapEntry(key, value.toValue()),
    ),
  };

  /// Creates a [Constant] object from its JSON representation.
  ///
  /// [constants] needs to be passed, as the [Constant]s are normalized and
  /// stored separately in the JSON.
  static Constant fromJson(
    Map<String, Object?> value,
    List<Constant> constants,
  ) => switch (value[_typeKey] as String) {
    NullConstant._type => const NullConstant(),
    BoolConstant._type => BoolConstant(value[_valueKey] as bool),
    IntConstant._type => IntConstant(value[_valueKey] as int),
    StringConstant._type => StringConstant(value[_valueKey] as String),
    ListConstant._type => ListConstant(
      (value[_valueKey] as List<dynamic>)
          .map((value) => value as int)
          .map((value) => constants[value])
          .toList(),
    ),
    MapConstant._type => MapConstant(
      (value[_valueKey] as Map<String, Object?>).map(
        (key, value) => MapEntry(key, constants[value as int]),
      ),
    ),
    InstanceConstant._type => InstanceConstant(
      fields: (value[_valueKey] as Map<String, Object?>? ?? {}).map(
        (key, value) => MapEntry(key, constants[value as int]),
      ),
    ),
    String() =>
      throw UnimplementedError('This type is not a supported constant'),
  };
}

/// Represents the `null` constant value.
final class NullConstant extends Constant {
  /// The type identifier for JSON serialization.
  static const _type = 'Null';

  /// Creates a [NullConstant] object.
  const NullConstant() : super();

  @override
  Map<String, Object?> toJson(Map<Constant, int> constants) =>
      _toJson(_type, null);

  @override
  bool operator ==(Object other) => other is NullConstant;

  @override
  int get hashCode => 0;
}

/// Represents a constant value of a primitive type.
sealed class PrimitiveConstant<T extends Object> extends Constant {
  /// The underlying value of this constant.
  final T value;

  /// Creates a [PrimitiveConstant] object with the given [value].
  const PrimitiveConstant(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrimitiveConstant<T> && other.value == value;
  }

  @override
  Map<String, Object?> toJson(Map<Constant, int> constants) => valueToJson();

  /// Converts this primitive constant to a JSON representation.
  Map<String, Object?> valueToJson();
}

/// Represents a constant boolean value.
final class BoolConstant extends PrimitiveConstant<bool> {
  /// The type identifier for JSON serialization.
  static const _type = 'bool';

  /// Creates a [BoolConstant] object with the given boolean [value].
  const BoolConstant(super.value);

  @override
  Map<String, Object?> valueToJson() => _toJson(_type, value);
}

/// Represents a constant integer value.
final class IntConstant extends PrimitiveConstant<int> {
  /// The type identifier for JSON serialization.
  static const _type = 'int';

  /// Creates an [IntConstant] object with the given integer [value].
  const IntConstant(super.value);

  @override
  Map<String, Object?> valueToJson() => _toJson(_type, value);
}

/// Represents a constant string value.
final class StringConstant extends PrimitiveConstant<String> {
  /// The type identifier for JSON serialization.
  static const _type = 'String';

  /// Creates a [StringConstant] object with the given string [value].
  const StringConstant(super.value);

  @override
  Map<String, Object?> valueToJson() => _toJson(_type, value);
}

/// Represents a constant list of [Constant] values.
final class ListConstant<T extends Constant> extends Constant {
  /// The type identifier for JSON serialization.
  static const _type = 'list';

  /// The underlying list of constant values.
  final List<T> value;

  /// Creates a [ListConstant] object with the given list of [value]s.
  const ListConstant(this.value);

  @override
  int get hashCode => deepHash(value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ListConstant && deepEquals(other.value, value);
  }

  @override
  Map<String, Object?> toJson(Map<Constant, int> constants) =>
      _toJson(_type, value.map((constant) => constants[constant]).toList());
}

/// Represents a constant map from string keys to [Constant] values.
final class MapConstant<T extends Constant> extends Constant {
  /// The type identifier for JSON serialization.
  static const _type = 'map';

  /// The underlying map of constant values.
  final Map<String, T> value;

  /// Creates a [MapConstant] object with the given map of [value]s.
  const MapConstant(this.value);

  @override
  int get hashCode => deepHash(value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapConstant && deepEquals(other.value, value);
  }

  @override
  Map<String, Object?> toJson(Map<Constant, int> constants) => _toJson(
    _type,
    value.map((key, constant) => MapEntry(key, constants[constant]!)),
  );
}

/// A constant instance of a class with its fields
///
/// Only as far as they can also be represented by constants. This is more or
/// less the same as a [MapConstant].
final class InstanceConstant extends Constant {
  /// The type identifier for JSON serialization.
  static const _type = 'Instance';

  /// The fields of this instance, mapped from field name to [Constant] value.
  final Map<String, Constant> fields;

  /// Creates an [InstanceConstant] object with the given [fields].
  const InstanceConstant({required this.fields});

  /// Creates an [InstanceConstant] object from JSON.
  ///
  /// [json] is a map representing the JSON structure.
  /// [constants] is a list of [Constant] objects that are referenced by index
  /// in the JSON.
  factory InstanceConstant.fromJson(
    Map<String, Object?> json,
    List<Constant> constants,
  ) {
    return InstanceConstant(
      fields: json.map(
        (key, constantIndex) => MapEntry(key, constants[constantIndex as int]),
      ),
    );
  }

  @override
  Map<String, Object?> toJson(Map<Constant, int> constants) => _toJson(
    _type,
    fields.isNotEmpty
        ? fields.map(
          (name, constantIndex) => MapEntry(name, constants[constantIndex]!),
        )
        : null,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InstanceConstant && deepEquals(other.fields, fields);
  }

  @override
  int get hashCode => deepHash(fields);
}

/// Helper to create the JSON structure of constants by storing the value with
/// the type.
Map<String, Object?> _toJson(String type, Object? value) {
  return {_typeKey: type, if (value != null) _valueKey: value};
}
