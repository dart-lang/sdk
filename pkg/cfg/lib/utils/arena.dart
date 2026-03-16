// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Pointer to a memory location in [Uint32Arena].
///
/// The pointer is also represented with a 32-bit unsigned integer which
/// can be stored into [Uint32Arena].
extension type const ArenaPointer(int _index) {
  /// Invalid pointer value.
  static const ArenaPointer Null = ArenaPointer(0xffffffff);

  /// Pointer to the [size]-th element after [this].
  ArenaPointer operator +(int size) {
    assert(this != Null);
    return ArenaPointer(_index + size);
  }

  /// Number of 32-bit elements between [base] and [this] pointers.
  int operator -(ArenaPointer base) {
    assert(this != Null);
    assert(base != Null);
    return this._index - base._index;
  }

  /// 32-bit unsigned integer value of this pointer.
  int toInt() => _index;
}

/// Growable arena containing 32-bit unsigned integer elements.
mixin class Uint32Arena {
  /// Initial capacity of the arena.
  static const int initialSize = 1024;

  /// Maximum size of the arena.
  static const int maxSize = 0x80000000;

  Uint32List _buffer = Uint32List(initialSize);
  int _used = 0;

  /// Loads 32-bit unsigned integer value stored at [ptr].
  ///
  /// [ptr] should point to a valid, previously allocated location.
  @pragma("vm:prefer-inline")
  int operator [](ArenaPointer ptr) {
    assert(ptr._index < _used);
    return _buffer[ptr._index];
  }

  /// Stores low 32 bits of [value] at [ptr].
  ///
  /// [ptr] should point to a valid, previously allocated location.
  @pragma("vm:prefer-inline")
  void operator []=(ArenaPointer ptr, int value) {
    assert(ptr._index < _used);
    _buffer[ptr._index] = value;
  }

  /// Allocate [size] 32-bit elements in this arena and
  /// returns pointer to the first element.
  ///
  /// Allocated elements are zero-initialized.
  /// Expands arena storage as needed, up to [maxSize].
  /// Returns [ArenaPointer.Null] if [size] is zero.
  @pragma("vm:prefer-inline")
  ArenaPointer allocate(int size) {
    assert(size >= 0);
    if (size == 0) {
      return ArenaPointer.Null;
    }
    final index = _used;
    if (index > _buffer.length - size) {
      _expand(size);
    }
    _used += size;
    return ArenaPointer(index);
  }

  @pragma("vm:never-inline")
  void _expand(int size) {
    assert(size > 0);
    int capacity = _buffer.length;
    while (_used > capacity - size) {
      capacity = capacity << 1;
      if (capacity > maxSize) {
        throw StateError('Cannot grow arena beyond $maxSize elements');
      }
    }
    Uint32List old = _buffer;
    _buffer = Uint32List(capacity);
    _buffer.setRange(0, _used, old);
  }
}
