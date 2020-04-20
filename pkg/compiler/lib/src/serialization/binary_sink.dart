// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// [DataSink] that writes data as a sequence of bytes.
///
/// This data sink works together with [BinarySource].
class BinarySink extends AbstractDataSink {
  final Sink<List<int>> sink;
  BufferedSink _bufferedSink;
  int _length = 0;

  BinarySink(this.sink,
      {bool useDataKinds: false, Map<String, int> tagFrequencyMap})
      : _bufferedSink = new BufferedSink(sink),
        super(useDataKinds: useDataKinds, tagFrequencyMap: tagFrequencyMap);

  @override
  void _begin(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }
  @override
  void _end(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }

  @override
  void _writeUriInternal(Uri value) {
    _writeString(value.toString());
  }

  @override
  void _writeStringInternal(String value) {
    List<int> bytes = utf8.encode(value);
    _writeIntInternal(bytes.length);
    _bufferedSink.addBytes(bytes);
    _length += bytes.length;
  }

  @override
  void _writeIntInternal(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      _bufferedSink.addByte(value);
      _length += 1;
    } else if (value < 0x4000) {
      _bufferedSink.addByte2((value >> 8) | 0x80, value & 0xFF);
      _length += 2;
    } else {
      _bufferedSink.addByte4((value >> 24) | 0xC0, (value >> 16) & 0xFF,
          (value >> 8) & 0xFF, value & 0xFF);
      _length += 4;
    }
  }

  @override
  void _writeEnumInternal(dynamic value) {
    _writeIntInternal(value.index);
  }

  @override
  void close() {
    _bufferedSink.flushAndDestroy();
    _bufferedSink = null;
    sink.close();
  }

  /// Returns the number of bytes written to this data sink.
  @override
  int get length => _length;
}
