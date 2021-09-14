// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// Interface for serialization.
// TODO(sigmund): share this with pkg:compiler/src/serialization/*
abstract class DataSink {
  /// The amount of data written to this data sink.
  ///
  /// The units is based on the underlying data structure for this data sink.
  int get length;

  /// Flushes any pending data and closes this data sink.
  ///
  /// The data sink can no longer be written to after closing.
  void close();

  /// Writes a reference to [value] to this data sink. If [value] has not yet
  /// been serialized, [f] is called to serialize the value itself.
  void writeCached<E>(E value, void f(E value));

  /// Writes the potentially `null` [value] to this data sink. If [value] is
  /// non-null [f] is called to write the non-null value to the data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readValueOrNull].
  void writeValueOrNull<E>(E value, void f(E value));

  /// Writes the [values] to this data sink calling [f] to write each value to
  /// the data sink. If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readList].
  void writeList<E>(Iterable<E> values, void f(E value),
      {bool allowNull: false});

  /// Writes the boolean [value] to this data sink.
  void writeBool(bool value);

  /// Writes the non-negative integer [value] to this data sink.
  void writeInt(int value);

  /// Writes the potentially `null` non-negative [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readIntOrNull].
  void writeIntOrNull(int value);

  /// Writes the string [value] to this data sink.
  void writeString(String value);

  /// Writes the potentially `null` string [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStringOrNull].
  void writeStringOrNull(String value);

  /// Writes the string [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStrings].
  void writeStrings(Iterable<String> values, {bool allowNull: false});

  /// Writes the [map] from string to [V] values to this data sink, calling [f]
  /// to write each value to the data sink. If [allowNull] is `true`, [map] is
  /// allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStringMap].
  void writeStringMap<V>(Map<String, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes the enum value [value] to this data sink.
  // TODO(johnniwinther): Change the signature to
  // `void writeEnum<E extends Enum<E>>(E value);` when an interface for enums
  // is added to the language.
  void writeEnum(dynamic value);

  /// Writes the URI [value] to this data sink.
  void writeUri(Uri value);
}

/// Mixin that implements all convenience methods of [DataSink].
abstract class DataSinkMixin implements DataSink {
  @override
  void writeIntOrNull(int value) {
    writeBool(value != null);
    if (value != null) {
      writeInt(value);
    }
  }

  @override
  void writeStringOrNull(String value) {
    writeBool(value != null);
    if (value != null) {
      writeString(value);
    }
  }

  @override
  void writeStrings(Iterable<String> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (String value in values) {
        writeString(value);
      }
    }
  }

  @override
  void writeStringMap<V>(Map<String, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((String key, V value) {
        writeString(key);
        f(value);
      });
    }
  }

  @override
  void writeList<E>(Iterable<E> values, void f(E value),
      {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      values.forEach(f);
    }
  }

  @override
  void writeValueOrNull<E>(E value, void f(E value)) {
    writeBool(value != null);
    if (value != null) {
      f(value);
    }
  }
}

/// Data sink helper that canonicalizes [E] values using indices.
class IndexedSink<E> {
  final void Function(int) _writeInt;
  final Map<E, int> _cache = {};

  IndexedSink(this._writeInt);

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
  void write(E value, void writeValue(E value)) {
    int index = _cache[value];
    if (index == null) {
      index = _cache.length;
      _cache[value] = index;
      _writeInt(index);
      writeValue(value);
    } else {
      _writeInt(index);
    }
  }
}

/// Base implementation of [DataSink] using [DataSinkMixin] to implement
/// convenience methods.
abstract class AbstractDataSink extends DataSinkMixin implements DataSink {
  IndexedSink<String> _stringIndex;
  IndexedSink<Uri> _uriIndex;
  Map<Type, IndexedSink> _generalCaches = {};

  AbstractDataSink() {
    _stringIndex = new IndexedSink<String>(_writeIntInternal);
    _uriIndex = new IndexedSink<Uri>(_writeIntInternal);
  }

  @override
  void writeCached<E>(E value, void f(E value)) {
    IndexedSink sink =
        _generalCaches[E] ??= new IndexedSink<E>(_writeIntInternal);
    sink.write(value, (v) => f(v));
  }

  @override
  void writeEnum(dynamic value) {
    _writeEnumInternal(value);
  }

  @override
  void writeBool(bool value) {
    assert(value != null);
    _writeIntInternal(value ? 1 : 0);
  }

  @override
  void writeUri(Uri value) {
    assert(value != null);
    _writeUri(value);
  }

  @override
  void writeString(String value) {
    assert(value != null);
    _writeString(value);
  }

  @override
  void writeInt(int value) {
    assert(value != null);
    assert(value >= 0 && value >> 30 == 0);
    _writeIntInternal(value);
  }

  void _writeString(String value) {
    _stringIndex.write(value, _writeStringInternal);
  }

  void _writeUri(Uri value) {
    _uriIndex.write(value, _writeUriInternal);
  }

  /// Actual serialization of a URI value, implemented by subclasses.
  void _writeUriInternal(Uri value);

  /// Actual serialization of a String value, implemented by subclasses.
  void _writeStringInternal(String value);

  /// Actual serialization of a non-negative integer value, implemented by
  /// subclasses.
  void _writeIntInternal(int value);

  /// Actual serialization of an enum value, implemented by subclasses.
  void _writeEnumInternal(dynamic value);
}

/// [DataSink] that writes data as a sequence of bytes.
///
/// This data sink works together with [BinarySource].
class BinarySink extends AbstractDataSink {
  final Sink<List<int>> sink;
  BufferedSink _bufferedSink;
  int _length = 0;

  BinarySink(this.sink) : _bufferedSink = new BufferedSink(sink);

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

  void close() {
    _bufferedSink.flushAndDestroy();
    _bufferedSink = null;
    sink.close();
  }

  /// Returns the number of bytes written to this data sink.
  int get length => _length;
}

/// Puts a buffer in front of a [Sink<List<int>>].
// TODO(sigmund): share with the implementation in
// package:kernel/binary/ast_to_binary.dart
class BufferedSink {
  static const int SIZE = 100000;
  static const int SAFE_SIZE = SIZE - 5;
  static const int SMALL = 10000;
  final Sink<List<int>> _sink;
  Uint8List _buffer = new Uint8List(SIZE);
  int length = 0;
  int flushedLength = 0;

  Float64List _doubleBuffer = new Float64List(1);
  Uint8List _doubleBufferUint8;

  int get offset => length + flushedLength;

  BufferedSink(this._sink);

  void addDouble(double d) {
    _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    _doubleBuffer[0] = d;
    addByte4(_doubleBufferUint8[0], _doubleBufferUint8[1],
        _doubleBufferUint8[2], _doubleBufferUint8[3]);
    addByte4(_doubleBufferUint8[4], _doubleBufferUint8[5],
        _doubleBufferUint8[6], _doubleBufferUint8[7]);
  }

  void addByte(int byte) {
    _buffer[length++] = byte;
    if (length == SIZE) {
      _sink.add(_buffer);
      _buffer = new Uint8List(SIZE);
      length = 0;
      flushedLength += SIZE;
    }
  }

  void addByte2(int byte1, int byte2) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
    } else {
      addByte(byte1);
      addByte(byte2);
    }
  }

  void addByte4(int byte1, int byte2, int byte3, int byte4) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
      _buffer[length++] = byte3;
      _buffer[length++] = byte4;
    } else {
      addByte(byte1);
      addByte(byte2);
      addByte(byte3);
      addByte(byte4);
    }
  }

  void addBytes(List<int> bytes) {
    // Avoid copying a large buffer into the another large buffer. Also, if
    // the bytes buffer is too large to fit in our own buffer, just emit both.
    if (length + bytes.length < SIZE &&
        (bytes.length < SMALL || length < SMALL)) {
      _buffer.setRange(length, length + bytes.length, bytes);
      length += bytes.length;
    } else if (bytes.length < SMALL) {
      // Flush as much as we can in the current buffer.
      _buffer.setRange(length, SIZE, bytes);
      _sink.add(_buffer);
      // Copy over the remainder into a new buffer. It is guaranteed to fit
      // because the input byte array is small.
      int alreadyEmitted = SIZE - length;
      int remainder = bytes.length - alreadyEmitted;
      _buffer = new Uint8List(SIZE);
      _buffer.setRange(0, remainder, bytes, alreadyEmitted);
      length = remainder;
      flushedLength += SIZE;
    } else {
      flush();
      _sink.add(bytes);
      flushedLength += bytes.length;
    }
  }

  void flush() {
    _sink.add(_buffer.sublist(0, length));
    _buffer = new Uint8List(SIZE);
    flushedLength += length;
    length = 0;
  }

  void flushAndDestroy() {
    _sink.add(_buffer.sublist(0, length));
  }
}
