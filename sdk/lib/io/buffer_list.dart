// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Utility class that can fast concatenate [List<int>]s of bytes. Use
 * [readBytes] to get the final buffer.
 */
class _BufferList {
  const int _INIT_SIZE = 1 * 1024;

  _BufferList() {
    clear();
  }

  int pow2roundup(int x) {
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }

  /**
   * Adds a new buffer to the list.
   */
  void add(List<int> buffer) {
    int bufferLength = buffer.length;
    int required = _length + bufferLength;
    if (_buffer == null) {
      int size = pow2roundup(required);
      if (size < _INIT_SIZE) size = _INIT_SIZE;
      _buffer = new Uint8List(size);
    } else if (_buffer.length < required) {
      // This will give is a list in the range of 2-4 times larger than
      // required.
      int size = pow2roundup(required) * 2;
      Uint8List newBuffer = new Uint8List(size);
      newBuffer.setRange(0, _buffer.length, _buffer);
      _buffer = newBuffer;
    }
    assert(_buffer.length >= required);
    if (buffer is Uint8List) {
      _buffer.setRange(_length, required, buffer);
    } else {
      for (int i = 0; i < bufferLength; i++) {
        _buffer[_length + i] = buffer[i];
      }
    }
    _length = required;
  }

  /**
   * Same as [add].
   */
  void write(List<int> buffer) {
    add(buffer);
  }

  /**
   * Read all the bytes from the buffer list. If it's empty, an empty list
   * is returned. A call to [readBytes] will clear the buffer.
   */
  List<int> readBytes() {
    if (_buffer == null) return new Uint8List(0);
    var buffer = new Uint8List.view(_buffer.buffer, 0, _length);
    clear();
    return buffer;
  }

  /**
   * Returns the total number of bytes in the buffer.
   */
  int get length => _length;

  /**
   * Returns whether the buffer list is empty.
   */
  bool get isEmpty => _length == 0;

  /**
   * Returns whether the buffer list is not empty.
   */
  bool get isNotEmpty => !isEmpty;

  /**
   * Clears the content of the buffer list.
   */
  void clear() {
    _length = 0;
    _buffer = null;
  }

  int _length;  // Total number of bytes in the buffer.
  Uint8List _buffer;  // Internal buffer.
}
