// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A value of type [T] read from a yaml/json-like structure.
abstract class Value<T> {
  const Value();

  /// Reads the [T] value from [value].
  ///
  /// If the [value] isn't a valid encoding of [T] an [ArgumentError] is thrown
  /// using [context] to provide additional information in the error message.
  T read(dynamic value, {String context = ''});
}

/// A `bool` value encoded as a bool.
class BoolValue extends Value<bool> {
  const BoolValue();

  @override
  bool read(dynamic value, {String context = ''}) {
    if (value is bool) {
      return value;
    } else {
      throw new ArgumentError("${context}Value must be a boolean.");
    }
  }
}

/// A `String` value encoded as a string.
///
/// If [options] is provided, only values in [options] are allowed.
class StringValue extends Value<String> {
  final Set<String>? options;

  const StringValue({this.options});

  @override
  String read(dynamic value, {String context = ''}) {
    if (value is String) {
      if (options != null && !options!.contains(value)) {
        throw new ArgumentError("${context}Unexpected value '${value}'. "
            "Expected one of: ${options!.join(',')}.");
      }
      return value;
    } else {
      throw new ArgumentError("${context}Value must be a string.");
    }
  }
}

/// An `int` value encoded as an integer.
class IntValue extends Value<int> {
  const IntValue();

  @override
  int read(dynamic value, {String context = ''}) {
    if (value is int) {
      return value;
    } else {
      throw new ArgumentError("${context}Value must be a integer.");
    }
  }
}

/// A `List<E>` value encoded as a list or a single element, if
/// [supportSingleton] is `true`.
///
/// The individual elements of type [E] are read using the [elementReader].
class ListValue<E> extends Value<List<E>> {
  final Value<E> elementReader;
  final bool supportSingleton;

  const ListValue(this.elementReader, {this.supportSingleton = false});

  @override
  List<E> read(dynamic value, {String context = ''}) {
    if (value is List) {
      List<E> list = [];
      for (dynamic element in value) {
        list.add(elementReader.read(element));
      }
      return list;
    } else if (supportSingleton) {
      return [elementReader.read(value, context: context)];
    } else {
      throw new ArgumentError("${context}Value must be a list.");
    }
  }
}

/// A `Map<String, V>` value encoded as a map.
///
/// The individual map entry values of type [V] are read using the
/// [valueReader].
class MapValue<V> extends Value<Map<String, V>> {
  final Value<V> valueReader;

  const MapValue(this.valueReader);

  @override
  Map<String, V> read(dynamic value, {String context = ''}) {
    if (value is Map) {
      Map<String, V> map = {};
      value.forEach((key, value) {
        map[key as String] = valueReader.read(value, context: context);
      });
      return map;
    } else {
      throw new ArgumentError("${context}Value must be a map.");
    }
  }
}

/// An enum value of type [E] encoding as a string using the enum value name.
class EnumValue<E extends Enum> extends Value<E> {
  final List<E> enumValues;

  const EnumValue(this.enumValues);

  @override
  E read(dynamic value, {String context = ''}) {
    if (value is String) {
      for (E enumValue in enumValues) {
        if (value == enumValue.name) {
          return enumValue;
        }
      }
      throw new ArgumentError("${context}Unexpected value: '${value}'. "
          "Expected one of: ${enumValues.map((e) => e.name).join(',')}.");
    } else {
      throw new ArgumentError("${context}Value must be a string.");
    }
  }
}

/// A value of type [O] encoded as a value of type [I], using [valueReader] to
/// decode the value.
class CustomValue<I, O> extends Value<O> {
  final O Function(I) valueReader;

  const CustomValue(this.valueReader);

  @override
  O read(dynamic value, {String context = ''}) {
    if (value is I) {
      return valueReader(value);
    } else {
      throw new ArgumentError("${context}Value must be of type $I.");
    }
  }
}

/// A potentially optional named property of type [T].
///
/// This class can be used to document and support the decoding of properties
/// defined in a yaml/json-like map.
class Property<T> {
  /// The name of the property as found in property map.
  final String name;

  /// The reader used to decode values of this property.
  final Value<T> valueReader;

  /// The default value for this property if omitted.
  final T? defaultValue;

  /// Whether this property is required.
  final bool required;

  /// Creates a required property with given [name] that uses [valueReader] to
  /// decode its value.
  const Property.required(this.name, this.valueReader)
      : required = true,
        defaultValue = null,
        assert(null is! T);

  /// Creates an optional property with given [name] that uses [valueReader] to
  /// decode its value when present and [defaultValue] if omitted.
  const Property.optional(this.name, this.valueReader, {this.defaultValue})
      : required = false,
        assert(defaultValue is T);

  /// Reads this property from [map].
  ///
  /// If [keys] is provided, [name] is removed from [keys] to signal that this
  /// property has been recognized. This can be used to detect and report
  /// unknown/unsupported properties.
  T read(Map map, [Set<String>? keys]) {
    dynamic value = map[name];
    keys?.remove(name);
    if (value == null) {
      if (required) {
        throw new ArgumentError("Missing property '$name'.");
      }
      return defaultValue as T;
    } else {
      return valueReader.read(value, context: "Property '$name': ");
    }
  }
}
