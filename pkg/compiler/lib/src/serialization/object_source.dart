// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// [DataSource] that read from a list of objects, useful for debugging
/// inconsistencies between serialization and deserialization.
///
/// This data source works together with [ObjectSink].
class ObjectSource extends AbstractDataSource {
  int _index = 0;
  final List<dynamic> _data;

  ObjectSource(this._data, {bool useDataKinds})
      : super(useDataKinds: useDataKinds);

  T _read<T>() {
    dynamic value = _data[_index++];
    assert(value is T, "Expected $T value, found $value.$_errorContext");
    return value;
  }

  @override
  void _begin(String tag) {
    Tag expectedTag = new Tag('begin:$tag');
    Tag actualTag = _read();
    assert(
        expectedTag == actualTag,
        "Unexpected begin tag. "
        "Expected $expectedTag, found $actualTag.$_errorContext");
  }

  @override
  void _end(String tag) {
    Tag expectedTag = new Tag('end:$tag');
    Tag actualTag = _read();
    assert(
        expectedTag == actualTag,
        "Unexpected end tag. "
        "Expected $expectedTag, found $actualTag.$_errorContext");
  }

  @override
  String _readStringInternal() => _read();

  @override
  E _readEnumInternal<E>(List<E> values) => _read();

  @override
  Uri _readUriInternal() => _read();

  @override
  int _readIntInternal() => _read();

  @override
  String get _errorContext {
    StringBuffer sb = new StringBuffer();
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
