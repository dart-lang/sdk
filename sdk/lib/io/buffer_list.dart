// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

/**
 * Utility class that holds a number of byte buffers and can deliver
 * the bytes either one by one or in chunks.
 */
class _BufferList {
  _BufferList() {
    clear();
  }

  /**
   * Adds a new buffer to the list possibly with an offset of the
   * first byte of interest. The offset can only be specified if the
   * buffer list is empty.
   */
  void add(List<int> buffer, [int offset = 0]) {
    assert(offset == 0 || _buffers.isEmpty);
    _buffers.addLast(buffer);
    _length += buffer.length;
    if (offset != 0) _index = offset;
  }

  /**
   * Returns the first buffer from the list. This returns the whole
   * buffer and does not remove the buffer from the list. Use
   * [index] to determine the index of the first byte in the buffer.
   */
  List<int> get first => _buffers.first;

  /**
   * Returns the current index of the next byte. This will always be
   * an index into the first buffer as when the index is advanced past
   * the end of a buffer it is removed from the list.
   */
  int get index =>  _index;

  /**
   * Peek at the next available byte.
   */
  int peek() => _buffers.first[_index];

  /**
   * Returns the next available byte removing it from the buffers.
   */
  int next() {
    int value = _buffers.first[_index++];
    _length--;
    if (_index == _buffers.first.length) {
      _buffers.removeFirst();
      _index = 0;
    }
    return value;
  }

  /**
   * Read [count] bytes from the buffer list. If the number of bytes
   * requested is not available null will be returned.
   */
  List<int> readBytes(int count) {
    List<int> result;
    if (_length == 0 || _length < count) return null;
    if (_index == 0 && _buffers.first.length == count) {
      result = _buffers.first;
      _buffers.removeFirst();
      _index = 0;
      _length -= count;
      return result;
    } else {
      int firstRemaining = _buffers.first.length - _index;
      if (firstRemaining >= count) {
        result = _buffers.first.getRange(_index, count);
        _index += count;
        _length -= count;
        if (_index == _buffers.first.length) {
          _buffers.removeFirst();
          _index = 0;
        }
        return result;
      } else {
        result = new Uint8List(count);
        int remaining = count;
        while (remaining > 0) {
          int bytesInFirst = _buffers.first.length - _index;
          if (bytesInFirst <= remaining) {
            result.setRange(count - remaining,
                            bytesInFirst,
                            _buffers.first,
                            _index);
            _buffers.removeFirst();
            _index = 0;
            _length -= bytesInFirst;
            remaining -= bytesInFirst;
          } else {
            result.setRange(count - remaining,
                            remaining,
                            _buffers.first,
                            _index);
            _index = remaining;
            _length -= remaining;
            remaining = 0;
            assert(_index < _buffers.first.length);
          }
        }
        return result;
      }
    }
  }

  /**
   * Remove a number of bytes from the buffer list. Currently the
   * number of bytes to remove must be confined to the first buffer.
   */
  void removeBytes(int count) {
    int firstRemaining = first.length - _index;
    assert(count <= firstRemaining);
    if (count == firstRemaining) {
      _buffers.removeFirst();
      _index = 0;
    } else {
      _index += count;
    }
    _length -= count;
  }


  /**
   * Returns the total number of bytes remaining in the buffers.
   */
  int get length => _length;

  /**
   * Returns whether the buffer list is empty that is has no bytes
   * available.
   */
  bool get isEmpty => _buffers.isEmpty;

  /**
   * Clears the content of the buffer list.
   */
  void clear() {
    _index = 0;
    _length = 0;
    _buffers = new Queue();
  }

  int _length;  // Total number of bytes remaining in the buffers.
  Queue<List<int>> _buffers;  // List of data buffers.
  int _index;  // Index of the next byte in the first buffer.
}
