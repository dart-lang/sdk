// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "io.dart";

/**
 * Builds a list of bytes, allowing bytes and lists of bytes to be added at the
 * end.
 *
 * Used to efficiently collect bytes and lists of bytes.
 */
abstract class BytesBuilder {
  /**
   * Construct a new empty [BytesBuilder].
   *
   * If [copy] is true, the data is always copied when added to the list. If
   * it [copy] is false, the data is only copied if needed. That means that if
   * the lists are changed after added to the [BytesBuilder], it may effect the
   * output. Default is `true`.
   */
  factory BytesBuilder({bool copy: true}) {
    if (copy) {
      return new _CopyingBytesBuilder();
    } else {
      return new _BytesBuilder();
    }
  }

  /**
   * Appends [bytes] to the current contents of the builder.
   *
   * Each value of [bytes] will be bit-representation truncated to the range
   * 0 .. 255.
   */
  void add(List<int> bytes);

  /**
   * Append [byte] to the current contents of the builder.
   *
   * The [byte] will be bit-representation truncated to the range 0 .. 255.
   */
  void addByte(int byte);

  /**
   * Returns the contents of `this` and clears `this`.
   *
   * The list returned is a view of the internal buffer, limited to the
   * [length].
   */
  List<int> takeBytes();

  /**
   * Returns a copy of the current contents of the builder.
   *
   * Leaves the contents of the builder intact.
   */
  List<int> toBytes();

  /**
   * The number of bytes in the builder.
   */
  int get length;

  /**
   * Returns `true` if the buffer is empty.
   */
  bool get isEmpty;

  /**
   * Returns `true` if the buffer is not empty.
   */
  bool get isNotEmpty;

  /**
   * Clear the contents of the builder.
   */
  void clear();
}

class _CopyingBytesBuilder implements BytesBuilder {
  // Start with 1024 bytes.
  static const int _INIT_SIZE = 1024;

  static final _emptyList = new Uint8List(0);

  int _length = 0;
  Uint8List _buffer;

  _CopyingBytesBuilder([int initialCapacity = 0])
      : _buffer = (initialCapacity <= 0)
            ? _emptyList
            : new Uint8List(_pow2roundup(initialCapacity));

  void add(List<int> bytes) {
    int bytesLength = bytes.length;
    if (bytesLength == 0) return;
    int required = _length + bytesLength;
    if (_buffer.length < required) {
      _grow(required);
    }
    assert(_buffer.length >= required);
    if (bytes is Uint8List) {
      _buffer.setRange(_length, required, bytes);
    } else {
      for (int i = 0; i < bytesLength; i++) {
        _buffer[_length + i] = bytes[i];
      }
    }
    _length = required;
  }

  void addByte(int byte) {
    if (_buffer.length == _length) {
      // The grow algorithm always at least doubles.
      // If we added one to _length it would quadruple unnecessarily.
      _grow(_length);
    }
    assert(_buffer.length > _length);
    _buffer[_length] = byte;
    _length++;
  }

  void _grow(int required) {
    // We will create a list in the range of 2-4 times larger than
    // required.
    int newSize = required * 2;
    if (newSize < _INIT_SIZE) {
      newSize = _INIT_SIZE;
    } else {
      newSize = _pow2roundup(newSize);
    }
    var newBuffer = new Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  List<int> takeBytes() {
    if (_length == 0) return _emptyList;
    var buffer = new Uint8List.view(_buffer.buffer, 0, _length);
    clear();
    return buffer;
  }

  List<int> toBytes() {
    if (_length == 0) return _emptyList;
    return new Uint8List.fromList(
        new Uint8List.view(_buffer.buffer, 0, _length));
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _length = 0;
    _buffer = _emptyList;
  }

  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}

class _BytesBuilder implements BytesBuilder {
  int _length = 0;
  final List<Uint8List> _chunks = [];

  void add(List<int> bytes) {
    Uint8List typedBytes;
    if (bytes is Uint8List) {
      typedBytes = bytes;
    } else {
      typedBytes = new Uint8List.fromList(bytes);
    }
    _chunks.add(typedBytes);
    _length += typedBytes.length;
  }

  void addByte(int byte) {
    _chunks.add(new Uint8List(1)..[0] = byte);
    _length++;
  }

  List<int> takeBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    if (_chunks.length == 1) {
      var buffer = _chunks[0];
      clear();
      return buffer;
    }
    var buffer = new Uint8List(_length);
    int offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    clear();
    return buffer;
  }

  List<int> toBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    var buffer = new Uint8List(_length);
    int offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return buffer;
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _length = 0;
    _chunks.clear();
  }
}
