// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialization/serialization.dart';

/// A canonicalized record shape comprising zero or more positional fields
/// followed by zero or more named fields in sorted order.
class RecordShape {
  /// Tag used for identifying serialized [RecordShape] objects in a debugging
  /// data stream.
  static const String tag = 'record-shape';

  /// Number of positional fields.
  final int positionalFieldCount;

  /// Names of named fields in canonical order.
  final List<String> fieldNames;

  int get namedFieldCount => fieldNames.length;

  int get fieldCount => positionalFieldCount + namedFieldCount;

  RecordShape._(this.positionalFieldCount, [this.fieldNames = const []]);

  factory RecordShape(int positionalFieldCount, List<String> names) {
    assert(positionalFieldCount >= 0);
    if (names.isEmpty) {
      if (0 <= positionalFieldCount && positionalFieldCount < _common.length) {
        return _common[positionalFieldCount];
      }
      return RecordShape._(positionalFieldCount, const []);
    }
    assert(_isSorted(names));
    return RecordShape._(positionalFieldCount, names);
  }

  static bool _isSorted(List<String> names) {
    for (int i = 1; i < names.length; i++) {
      if (names[i - 1].compareTo(names[i]) >= 0) return false;
    }
    return true;
  }

  static final List<RecordShape> _common = [
    RecordShape._(0),
    RecordShape._(1),
    RecordShape._(2),
    RecordShape._(3),
    RecordShape._(4),
    RecordShape._(5),
  ];

  /// Deserializes a [RecordShape] object from [source].
  factory RecordShape.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    int positionals = source.readInt();
    List<String> names = source.readStrings()!;
    source.end(tag);
    return RecordShape(positionals, names);
  }

  /// Serializes this [RecordShape] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(positionalFieldCount);
    sink.writeStrings(fieldNames);
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecordShape && _sameShape(this, other);

  @override
  late final int hashCode = _hashCode();

  int _hashCode() {
    return Object.hash(positionalFieldCount, Object.hashAll(fieldNames));
  }

  static bool _sameShape(RecordShape a, RecordShape b) {
    if (a.positionalFieldCount != b.positionalFieldCount) return false;
    if (a.fieldNames.length != b.fieldNames.length) return false;
    for (int i = 0; i < a.fieldNames.length; i++) {
      if (a.fieldNames[i] != b.fieldNames[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    if (fieldNames.isEmpty) {
      return 'RecordShape($positionalFieldCount)';
    }
    return 'RecordShape($positionalFieldCount, {${fieldNames.join(", ")}})';
  }
}
