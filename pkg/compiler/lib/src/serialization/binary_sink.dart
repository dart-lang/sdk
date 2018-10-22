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

  BinarySink(this.sink, {bool useDataKinds: false})
      : _bufferedSink = new BufferedSink(sink),
        super(useDataKinds: useDataKinds);

  void _begin(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }
  void _end(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }

  @override
  void _writeUri(Uri value) {
    _writeString(value.toString());
  }

  @override
  void _writeString(String value) {
    List<int> bytes = utf8.encode(value);
    _writeInt(bytes.length);
    _bufferedSink.addBytes(bytes);
  }

  @override
  void _writeInt(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      _bufferedSink.addByte(value);
    } else if (value < 0x4000) {
      _bufferedSink.addByte2((value >> 8) | 0x80, value & 0xFF);
    } else {
      _bufferedSink.addByte4((value >> 24) | 0xC0, (value >> 16) & 0xFF,
          (value >> 8) & 0xFF, value & 0xFF);
    }
  }

  @override
  void _writeEnum(dynamic value) {
    _writeInt(value.index);
  }

  void close() {
    _bufferedSink.flushAndDestroy();
    _bufferedSink = null;
    sink.close();
  }
}
