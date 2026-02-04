// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// A compact fixed-size list of N bits.
///
/// [BitVector] is implemented as an extension type over [Int64List]
/// in order to avoid extra object allocation. As a result it does not provide
/// a way to query its exact size, only approximate [capacity].
extension type BitVector._(Int64List _bits) {
  static const int _bitsPerElement = 64;

  /// Creates [BitVector] containing at least [size] bits.
  factory BitVector(int size) =>
      BitVector._(Int64List((size + _bitsPerElement - 1) ~/ _bitsPerElement));

  @pragma("vm:prefer-inline")
  static int _elementIndex(int index) => index ~/ _bitsPerElement;

  @pragma("vm:prefer-inline")
  static int _bitIndex(int index) => 1 << (index & (_bitsPerElement - 1));

  /// Effective capacity of this vector in bits.
  /// Can be larger than size requested in the constructor.
  int get capacity => _bits.length * _bitsPerElement;

  /// Returns value of [index]-th bit.
  @pragma("vm:prefer-inline")
  bool operator [](int index) =>
      _bits[_elementIndex(index)] & _bitIndex(index) != 0;

  /// Sets [index]-th bit.
  @pragma("vm:prefer-inline")
  void add(int index) {
    final elementIndex = _elementIndex(index);
    _bits[elementIndex] = _bits[elementIndex] | _bitIndex(index);
  }

  /// Clears [index]-th bit.
  @pragma("vm:prefer-inline")
  void remove(int index) {
    final elementIndex = _elementIndex(index);
    _bits[elementIndex] = _bits[elementIndex] & ~_bitIndex(index);
  }

  /// Sets [index]-th bit to the given [value].
  @pragma("vm:prefer-inline")
  void operator []=(int index, bool value) {
    if (value) {
      add(index);
    } else {
      remove(index);
    }
  }

  /// Clears all bits.
  void clear() {
    for (var i = 0; i < _bits.length; ++i) {
      _bits[i] = 0;
    }
  }

  /// Bitwise [this] = [this] & [other].
  void intersect(BitVector other) {
    assert(this._bits.length == other._bits.length);
    for (var i = 0; i < _bits.length; ++i) {
      _bits[i] = _bits[i] & other._bits[i];
    }
  }

  /// Bitwise [this] = [this] U [other].
  /// Returns true iff [this] has changed.
  bool addAll(BitVector other) {
    assert(this._bits.length == other._bits.length);
    var changed = false;
    for (var i = 0; i < _bits.length; ++i) {
      final before = _bits[i];
      final after = before | other._bits[i];
      if (before != after) {
        _bits[i] = after;
        changed = true;
      }
    }
    return changed;
  }

  /// Bitwise [this] = [this] U ([a] - [b])
  /// Returns true iff [this] has changed.
  bool addSubtraction(BitVector a, BitVector b) {
    assert(this._bits.length == a._bits.length);
    assert(this._bits.length == b._bits.length);
    var changed = false;
    for (var i = 0; i < _bits.length; ++i) {
      final before = _bits[i];
      final after = before | (a._bits[i] & ~b._bits[i]);
      if (before != after) {
        _bits[i] = after;
        changed = true;
      }
    }
    return changed;
  }

  /// Bitwise [this] = [this] U ([a] & [b])
  /// Returns true iff [this] has changed.
  bool addIntersection(BitVector a, BitVector b) {
    assert(this._bits.length == a._bits.length);
    assert(this._bits.length == b._bits.length);
    var changed = false;
    for (var i = 0; i < _bits.length; ++i) {
      final before = _bits[i];
      final after = before | (a._bits[i] & b._bits[i]);
      if (before != after) {
        _bits[i] = after;
        changed = true;
      }
    }
    return changed;
  }

  /// Iteration over positions of set bits.
  Iterable<int> get elements => _BitVectorIterable(this);
}

final class _BitVectorIterable extends Iterable<int> {
  final BitVector _vector;

  _BitVectorIterable(this._vector);

  @override
  Iterator<int> get iterator => _BitVectorIterator(_vector);
}

final class _BitVectorIterator implements Iterator<int> {
  static const int _bitsPerElement = BitVector._bitsPerElement;

  final BitVector _vector;
  int _bitIndex = -1;
  int _currentElement = 0;

  _BitVectorIterator(this._vector) {
    if (_vector._bits.isNotEmpty) {
      _currentElement = _vector._bits[0];
    }
  }

  @override
  bool moveNext() {
    ++_bitIndex;
    if (_currentElement == 0) {
      // Find the next non-zero element.
      int elementIndex = BitVector._elementIndex(
        _bitIndex + (_bitsPerElement - 1),
      );
      for (;;) {
        if (elementIndex >= _vector._bits.length) {
          // Reached the end of BitVector.
          _bitIndex = _vector.capacity;
          return false;
        }
        _currentElement = _vector._bits[elementIndex];
        if (_currentElement != 0) {
          break;
        }
        ++elementIndex;
      }
      _bitIndex = elementIndex * _bitsPerElement;
    }
    if ((_currentElement & 0xffffffff) == 0) {
      _bitIndex += 32;
      _currentElement = _currentElement >>> 32;
    }
    if ((_currentElement & 0xffff) == 0) {
      _bitIndex += 16;
      _currentElement = _currentElement >>> 16;
    }
    if ((_currentElement & 0xff) == 0) {
      _bitIndex += 8;
      _currentElement = _currentElement >>> 8;
    }
    if ((_currentElement & 0xf) == 0) {
      _bitIndex += 4;
      _currentElement = _currentElement >>> 4;
    }
    if ((_currentElement & 0x3) == 0) {
      _bitIndex += 2;
      _currentElement = _currentElement >>> 2;
    }
    if ((_currentElement & 0x1) == 0) {
      _bitIndex += 1;
      _currentElement = _currentElement >>> 1;
    }
    _currentElement = _currentElement >>> 1;
    return true;
  }

  @override
  int get current {
    assert(0 <= _bitIndex && _bitIndex < _vector.capacity);
    return _bitIndex;
  }
}
