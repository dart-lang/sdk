// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

part of 'serialization.dart';

/// [DataSinkWriter] that writes to a list of objects, useful for debugging
/// inconsistencies between serialization and deserialization.
///
/// This data sink writer works together with [ObjectDataSource].
class ObjectDataSink implements DataSink {
  List<dynamic> _data;

  ObjectDataSink(this._data);

  @override
  void beginTag(String tag) {
    _data.add(Tag('begin:$tag'));
  }

  @override
  void endTag(String tag) {
    _data.add(Tag('end:$tag'));
  }

  @override
  void writeEnum(dynamic value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void writeInt(int value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void writeString(String value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void close() {
    _data = null;
  }

  /// Returns the number of objects written to this data sink.
  @override
  int get length => _data.length;
}
