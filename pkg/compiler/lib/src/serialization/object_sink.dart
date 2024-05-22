// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'serialization.dart' show DataSink;
import 'tags.dart' show Tag;

/// [DataSinkWriter] that writes to a list of objects, useful for debugging
/// inconsistencies between serialization and deserialization.
///
/// This data sink writer works together with [ObjectDataSource].
class ObjectDataSink implements DataSink {
  // [_data] is nullable and non-final to allow storage to be released.
  List<dynamic>? _data;

  ObjectDataSink(this._data);

  @override
  void beginTag(String tag) {
    _data!.add(Tag('begin:$tag'));
  }

  @override
  void endTag(String tag) {
    _data!.add(Tag('end:$tag'));
  }

  @override
  void writeEnum<E extends Enum>(E value) {
    _data!.add(value);
  }

  @override
  void writeInt(int value) {
    _data!.add(value);
  }

  @override
  void writeUint32(int value) {
    _data!.add(value);
  }

  @override
  void writeString(String value) {
    _data!.add(value);
  }

  @override
  void writeDeferred(void writer()) {
    final sizeIndex = length;
    writeInt(0); // placeholder
    final startIndex = length;
    writer();
    final endIndex = length;
    _data![sizeIndex] = endIndex - startIndex;
  }

  final List<(int, int)> _deferredOffsets = [];

  @override
  void startDeferred() {
    final sizeIndex = length;
    writeInt(0); // Padding so the offset won't collide with a nested write.
    final startIndex = length;
    _deferredOffsets.add((sizeIndex, startIndex));
  }

  @override
  void endDeferred() {
    final (sizeIndex, startIndex) = _deferredOffsets.removeLast();
    _data![sizeIndex] = length - startIndex;
  }

  @override
  void close() {
    _data = null;
  }

  /// Returns the number of objects written to this data sink.
  @override
  int get length => _data!.length;
}
