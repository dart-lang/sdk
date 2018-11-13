// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// [DataSink] that writes to a list of objects, useful for debugging
/// inconsistencies between serialization and deserialization.
///
/// This data sink works together with [ObjectSource].
class ObjectSink extends AbstractDataSink {
  List<dynamic> _data;

  ObjectSink(this._data, {bool useDataKinds})
      : super(useDataKinds: useDataKinds);

  void _begin(String tag) {
    _data.add(new Tag('begin:$tag'));
  }

  void _end(String tag) {
    _data.add(new Tag('end:$tag'));
  }

  @override
  void _writeEnum(dynamic value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void _writeInt(int value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void _writeString(String value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void _writeUri(Uri value) {
    assert(value != null);
    _data.add(value);
  }

  @override
  void close() {
    _data = null;
  }
}
