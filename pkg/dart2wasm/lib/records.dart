// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;

import 'package:dart2wasm/class_info.dart';

import 'package:kernel/ast.dart';

/// Describes shape of a record as the number of positionals + set of field
/// names.
class RecordShape {
  /// Number of positional fields.
  final int positionals;

  /// Maps names of the named fields in the record to their indices in the
  /// record payload.
  final SplayTreeMap<String, int> _names;

  /// Names of named fields, sorted.
  Iterable<String> get names => _names.keys;

  /// Total number of fields.
  int get numFields => positionals + _names.length;

  RecordShape.fromType(RecordType recordType)
      : positionals = recordType.positional.length,
        // RecordType.named is already sorted
        _names = SplayTreeMap.fromIterables(
            recordType.named.map((ty) => ty.name),
            Iterable.generate(recordType.named.length,
                (i) => i + recordType.positional.length));

  @override
  String toString() => 'Record(positionals: $positionals, names: $_names)';

  @override
  bool operator ==(Object other) {
    if (other is! RecordShape) {
      return false;
    }

    if (positionals != other.positionals) {
      return false;
    }

    if (_names.length != other._names.length) {
      return false;
    }

    final names1Iter = _names.keys.iterator;
    final names2Iter = other._names.keys.iterator;
    while (names1Iter.moveNext()) {
      names2Iter.moveNext();
      if (names1Iter.current != names2Iter.current) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(positionals, Object.hashAll(_names.keys));

  /// Struct index of a positional field.
  int getPositionalIndex(int position) => FieldIndex.recordFieldBase + position;

  /// Struct index of a named field.
  int getNameIndex(String name) =>
      FieldIndex.recordFieldBase +
      (_names[name] ??
          (throw 'RecordImplementation.getNameIndex: '
              'name $name not in record: $this'));
}
