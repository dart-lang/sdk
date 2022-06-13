// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'data_source.dart';
import 'tags.dart' show Tag;

/// [DataSource] that read from a list of objects, useful for debugging
/// inconsistencies between serialization and deserialization.
///
/// This data source works together with [ObjectDataSink].
class ObjectDataSource implements DataSource {
  int _index = 0;
  final List<dynamic> _data;

  ObjectDataSource(this._data);

  T _read<T>() {
    Object? value = _data[_index++];
    if (value is T) return value;
    throw StateError('Expected $T value, found $value.$errorContext');
  }

  @override
  void begin(String tag) {
    Tag expectedTag = Tag('begin:$tag');
    Tag actualTag = _read();
    assert(
        expectedTag == actualTag,
        "Unexpected begin tag. "
        "Expected $expectedTag, found $actualTag.$errorContext");
  }

  @override
  void end(String tag) {
    Tag expectedTag = Tag('end:$tag');
    Tag actualTag = _read();
    assert(
        expectedTag == actualTag,
        "Unexpected end tag. "
        "Expected $expectedTag, found $actualTag.$errorContext");
  }

  @override
  String readString() => _read();

  @override
  E readEnum<E>(List<E> values) => _read();

  @override
  int readInt() => _read();

  @override
  String get errorContext {
    StringBuffer sb = StringBuffer();
    for (int i = _index - 50; i < _index + 10; i++) {
      if (i >= 0 && i < _data.length) {
        if (i == _index - 1) {
          sb.write('\n> ');
        } else {
          sb.write('\n  ');
        }
        sb.write(i);
        sb.write(' ');
        sb.write(_data[i]);
      }
    }
    return sb.toString();
  }
}
