// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Builds a list of bytes, allowing bytes and lists of bytes to be added at the
 * end.
 *
 * Used to efficiently collect bytes and lists of bytes, using an internal
 * buffer. Note that it's optimized for IO, using an initial buffer of 1K bytes.
 */
class BytesBuilder {
  // Start with 1024 bytes.
  static const int _INIT_SIZE = 1024;

  int _length = 0;
  Uint8List _buffer;

  /**
   * Construct a new empty [BytesBuilder].
   */
  BytesBuilder();

  /**
   * Appends [bytes] to the current contents of the builder.
   *
   * Each value of [bytes] will be bit-representation truncated to the range
   * 0 .. 255.
   */
  void add(List<int> bytes) {
    int bytesLength = bytes.length;
    if (bytesLength == 0) return;
    int required = _length + bytesLength;
    if (_buffer == null) {
      int size = _pow2roundup(required);
      size = max(size, _INIT_SIZE);
      _buffer = new Uint8List(size);
    } else if (_buffer.length < required) {
      // We will create a list in the range of 2-4 times larger than
      // required.
      int size = _pow2roundup(required) * 2;
      var newBuffer = new Uint8List(size);
      newBuffer.setRange(0, _buffer.length, _buffer);
      _buffer = newBuffer;
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

  /**
   * Append [byte] to the current contents of the builder.
   *
   * The [byte] will be bit-representation truncated to the range 0 .. 255.
   */
  void addByte(int byte) => add([byte]);

  /**
   * Returns the contents of `this` and clears `this`.
   *
   * The list returned is a view of the the internal buffer, limited to the
   * [length].
   */
  List<int> takeBytes() {
    if (_buffer == null) return new Uint8List(0);
    var buffer = new Uint8List.view(_buffer.buffer, 0, _length);
    clear();
    return buffer;
  }

  /**
   * Returns a copy of the current contents of the builder.
   *
   * Leaves the contents of the builder intact.
   */
  List<int> toBytes() {
    if (_buffer == null) return new Uint8List(0);
    return new Uint8List.fromList(
        new Uint8List.view(_buffer.buffer, 0, _length));
  }

  /**
   * The number of bytes in the builder.
   */
  int get length => _length;

  /**
   * Returns `true` if the buffer is empty.
   */
  bool get isEmpty => _length == 0;

  /**
   * Returns `true` if the buffer is empty.
   */
  bool get isNotEmpty => _length != 0;

  /**
   * Clear the contents of the builder.
   */
  void clear() {
    _length = 0;
    _buffer = null;
  }

  int _pow2roundup(int x) {
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}
