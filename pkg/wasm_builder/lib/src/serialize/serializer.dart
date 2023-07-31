// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

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

  void _debugTrace(Object data) {
    _traces[_index] ??= data;
  }

  void writeByte(int byte) {
    if (traceEnabled) _debugTrace(StackTrace.current);
    assert(byte == byte & 0xFF);
    _ensure(1);
    _data[_index++] = byte;
  }

  void writeBytes(List<int> bytes) {
    if (traceEnabled) _debugTrace(StackTrace.current);
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

  void writeF32(double value) {
    // Get the binary representation of the F32.
    List<int> bytes = Float32List.fromList([value]).buffer.asUint8List();
    assert(bytes.length == 4);
    if (Endian.host == Endian.big) bytes = bytes.reversed.toList();
    writeBytes(bytes);
  }

  void writeF64(double value) {
    // Get the binary representation of the F64.
    List<int> bytes = Float64List.fromList([value]).buffer.asUint8List();
    assert(bytes.length == 8);
    if (Endian.host == Endian.big) bytes = bytes.reversed.toList();
    writeBytes(bytes);
  }

  void writeName(String name) {
    List<int> bytes = utf8.encode(name);
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

  void writeData(Serializer chunk, [List<int>? watchPoints]) {
    if (traceEnabled) _debugTrace(chunk);
    if (watchPoints != null) {
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
    }
    writeBytes(chunk.data);
  }

  Uint8List get data => Uint8List.sublistView(_data, 0, _index);
}
