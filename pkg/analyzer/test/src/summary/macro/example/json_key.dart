// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An annotation used to specify how a field is serialized.
class JsonKey {
  /// The key in a JSON map to use when reading and writing values corresponding
  /// to the annotated fields.
  ///
  /// If `null`, the field name is used.
  final String? name;

  /// The value to use if the source JSON does not contain this key.
  ///
  /// If the value is explicitly null in the JSON, it will still be retained.
  final Object? defaultValue;

  /// Whether or not to include this field in the serialized form, even if it
  /// is `null`.
  final bool includeIfNull;

  const JsonKey({this.name, this.defaultValue, this.includeIfNull = false});
}
