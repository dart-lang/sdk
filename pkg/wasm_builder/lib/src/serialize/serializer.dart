// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import '../../source_map.dart';

abstract class Serializable {
  void serialize(Serializer s);
}

// TODO(joshualitt): Now that we have an IR, we should consider switching to a
// visitor pattern.
class Serializer {
  static bool traceEnabled = false;

  // The prefix of `_data` up to `_index` contains the data serialized so far.
  Uint8List _data = Uint8List(24);
  int _index = 0;

  // Stack traces or other serializers attached to byte positions within the
  // chunk of data produced by this serializer.
  late final SplayTreeMap<int, Object> _traces = SplayTreeMap();

  /// Get the current offset in the serialized data.
  int get offset => _index;

  final SourceMapSerializer sourceMapSerializer = SourceMapSerializer();

  void _ensure(int size) {
    // Ensure space for at least `size` additional bytes.
    if (_data.length < _index + size) {
      int newLength = _data.length * 2;
      while (newLength < _index + size) {
        newLength *= 2;
      }
      _data = Uint8List(newLength)..setRange(0, _data.length, _data);
    }
  }

  void debugTrace(Object data) {
    _traces[_index] ??= data;
  }

  void writeByte(int byte) {
    if (traceEnabled) debugTrace(StackTrace.current);
    assert(byte == byte & 0xFF);
    _ensure(1);
    _data[_index++] = byte;
  }

  void writeBytes(Uint8List bytes) {
    if (traceEnabled) debugTrace(StackTrace.current);
    _ensure(bytes.length);
    _data.setRange(_index, _index += bytes.length, bytes);
  }

  void writeSigned(int value) {
    while (value < -0x40 || value >= 0x40) {
      writeByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    writeByte(value & 0x7F);
  }

  void writeUnsigned(int value) {
    assert(value >= 0);
    while (value >= 0x80) {
      writeByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    writeByte(value);
  }

  static int writeUnsignedByteCount(int value) {
    assert(value >= 0);
    int count = 0;
    while (value >= 0x80) {
      count++;
      value >>= 7;
    }
    count++;
    return count;
  }

  static final ByteData _f32ByteData = ByteData(4);
  static final Uint8List _f32Uint8List = _f32ByteData.buffer.asUint8List();
  void writeF32(double value) {
    _f32ByteData.setFloat32(0, value, Endian.little);
    writeBytes(_f32Uint8List);
  }

  static final ByteData _f64ByteData = ByteData(8);
  static final Uint8List _f64Uint8List = _f64ByteData.buffer.asUint8List();
  void writeF64(double value) {
    _f64ByteData.setFloat64(0, value, Endian.little);
    writeBytes(_f64Uint8List);
  }

  void writeName(String name) {
    final bytes = utf8.encode(name);
    writeUnsigned(bytes.length);
    writeBytes(bytes);
  }

  void write(Serializable object) {
    object.serialize(this);
  }

  void writeList(List<Serializable> objects) {
    writeUnsigned(objects.length);
    for (int i = 0; i < objects.length; i++) {
      write(objects[i]);
    }
  }

  void writeData(Serializer chunk, [List<int> watchPoints = const []]) {
    if (traceEnabled) debugTrace(chunk);
    for (int watchPoint in watchPoints) {
      if (_index <= watchPoint && watchPoint < _index + chunk.data.length) {
        int byteValue = chunk.data[watchPoint - _index];
        Object trace = this;
        int offset = watchPoint;
        while (trace is Serializer) {
          int keyOffset = trace._traces.containsKey(offset)
              ? offset
              : trace._traces.lastKeyBefore(offset)!;
          trace = trace._traces[keyOffset]!;
          offset -= keyOffset;
        }
        String byte = byteValue.toRadixString(16).padLeft(2, '0');
        print("Watch $watchPoint: 0x$byte\n$trace");
      }
    }
    writeBytes(chunk.data);
  }

  Uint8List get data => Uint8List.sublistView(_data, 0, _index);
}
