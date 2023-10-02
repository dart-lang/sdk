// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

// The default set implementation is based on a Uint32List+List where both are
// linear in the number of entries. That means we consume on 64-bit VMs at
// least 12 bytes per entry.
//
// We should consider making a more memory efficient hash set implementation
// that uses Int32List and utilizing the fact that we never store negative
// numbers in it.
typedef IntSet = Set<int>;

/// Set of ints that can hold ints between 0 and up to (but not including)
/// [maxLength].
///
/// The memory usage of this is fixed and depend on the [maxLength], and is
/// something like ~125 kb per mio. as specified by [maxLength], e.g. a max
/// length of 50 mio should take ~6 mb.
class SpecializedIntSet extends SetBase<int> {
  final Uint32List _data;
  final int maxLength;
  int _length = 0;

  SpecializedIntSet(this.maxLength)
      : _data = Uint32List((maxLength + 31) ~/ 32);

  @override
  Iterator<int> get iterator => _SpecializedIntSetIterator(this);

  @override
  int get length => _length;

  @override
  bool add(int value) {
    if (value < 0 || value >= maxLength) {
      throw RangeError.range(value, 0, maxLength - 1);
    }
    final int index = value >> 5;
    final int offset = value & 31;
    final int mask = 1 << (31 - offset);

    if (_data[index] & mask != 0) return false;
    _data[index] |= mask;
    _length++;
    return true;
  }

  @override
  bool contains(Object? element) {
    if (element is! int) return false;
    if (element < 0) return false;
    if (element >= maxLength) return false;

    final int index = element >> 5;
    final int offset = element & 31;
    final int mask = 1 << (31 - offset);
    return _data[index] & mask != 0;
  }

  String getDumpData() {
    final StringBuffer sb = StringBuffer();
    for (int value in _data) {
      if (sb.isNotEmpty) sb.write(" ");
      sb.write(value.toRadixString(2).padLeft(32, "0"));
    }
    return sb.toString();
  }

  @override
  int? lookup(Object? element) {
    if (contains(element)) return element as int;
    return null;
  }

  @override
  bool remove(Object? value) {
    if (value is! int) return false;
    if (value < 0) return false;
    if (value >= maxLength) return false;

    final int index = value >> 5;
    final int offset = value & 31;
    final int mask = 1 << (31 - offset);

    if (_data[index] & mask != 0) {
      _data[index] &= ~mask;
      _length--;
      return true;
    }
    return false;
  }

  @override
  Set<int> toSet() {
    final SpecializedIntSet result = SpecializedIntSet(maxLength);
    result._length = _length;
    result._data.setRange(0, _data.length, _data);
    return result;
  }
}

class _SpecializedIntSetIterator implements Iterator<int> {
  int? _current;
  int _nextToCheck = 0;
  int _returns = 0;
  final SpecializedIntSet _set;

  _SpecializedIntSetIterator(this._set);

  @override
  int get current => _current ?? (throw StateError('No element'));

  @override
  bool moveNext() {
    if (_returns >= _set.length) return false;

    while (_nextToCheck < _set.maxLength) {
      final int index = _nextToCheck >> 5;
      final int dataAtIndex = _set._data[index];
      if (dataAtIndex == 0) {
        // Nothing in this byte.
        _nextToCheck = (index + 1) << 5;
        continue;
      }

      final int restBytes;
      final int offset = _nextToCheck & 31;
      {
        final int maskRest = (1 << (32 - offset)) - 1;
        restBytes = dataAtIndex & maskRest;
      }

      if (restBytes == 0) {
        // No more in this byte.
        _nextToCheck = (index + 1) << 5;
        continue;
      }

      int mask = (1 << (31 - offset));

      while (restBytes & mask == 0) {
        _nextToCheck++;
        mask >>= 1;
      }
      _current = _nextToCheck;
      _nextToCheck++;
      _returns++;
      return true;
    }
    return false;
  }
}
