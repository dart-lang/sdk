// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

/// A circular buffer with a fixed [bufferSize].
class RingBuffer<T> {
  RingBuffer(this._bufferSize) : _buffer = List<T?>.filled(_bufferSize, null);

  /// Iterates through elements currently stored in the [RingBuffer] from oldest
  /// to newest.
  Iterable<T> call() sync* {
    for (var i = _size - 1; i >= 0; --i) {
      yield _buffer[(_count - i - 1) % _bufferSize]!;
    }
  }

  /// Inserts a new element into the [RingBuffer].
  ///
  /// Returns the element evicted as a result of adding the new element if the
  /// buffer is at max capacity, null otherwise.
  T? add(T element) {
    if (_buffer.isEmpty) {
      return null;
    }
    T? evicted;
    final index = _count % _bufferSize;
    if (index < _count) {
      evicted = _buffer[index];
    }
    _buffer[index] = element;
    _count++;
    return evicted;
  }

  /// Resizes the buffer capacity to [size].
  void resize(int size) {
    assert(size >= 0);
    if (size == _bufferSize) {
      return;
    }
    final resized = List<T?>.filled(size, null);
    var count = 0;
    if (size > 0) {
      for (final e in this()) {
        resized[count++ % size] = e;
      }
    }
    _count = count;
    _bufferSize = size;
    _buffer = resized;
  }

  /// Returns true if elements have been evicted from the buffer due to capacity
  /// limits.
  bool get isTruncated => _count > bufferSize;

  /// The maximum number of elements the buffer can hold.
  int get bufferSize => _bufferSize;

  int get _size => min(_count, _bufferSize);

  int _bufferSize;
  int _count = 0;
  List<T?> _buffer;
}
