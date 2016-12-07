// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.canonicalizer;

import 'dart:collection';

/// Generates unique consecutive integer IDs for tuples of variable length.
class TupleCanonicalizer {
  final HashMap<List<Object>, int> _table = new HashMap<List<Object>, int>(
      equals: _contentEquals, hashCode: _contentHashCode);
  final List<List<Object>> _canonicalList = <List<Object>>[];
  List<Object> _buffer = [];

  void _push(Object value) {
    _buffer.add(value);
  }

  int _finish() {
    int index = _table[_buffer];
    if (index == null) {
      index = _canonicalList.length;
      _canonicalList.add(_buffer);
      _table[_buffer] = index;
      _buffer = [];
    } else {
      // The item already existed.  Reuse the buffer object for the next query.
      _buffer.clear();
    }
    return index;
  }

  /// Generate or get the ID for a "unary tuple".
  int get1(Object first) {
    _push(first);
    return _finish();
  }

  /// Generate or get the ID for a pair.
  int get2(Object first, Object second) {
    _push(first);
    _push(second);
    return _finish();
  }

  /// Generate or get the ID for a triple.
  int get3(Object first, Object second, Object third) {
    _push(first);
    _push(second);
    _push(third);
    return _finish();
  }

  List<Object> getFromIndex(int index) {
    return _canonicalList[index];
  }

  int get length => _canonicalList.length;

  static bool _contentEquals(List<Object> first, List<Object> second) {
    if (first.length != second.length) return false;
    for (int i = 0; i < first.length; ++i) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  static int _contentHashCode(List<Object> list) {
    int hash = 0;
    for (int i = 0; i < list.length; ++i) {
      hash = (hash * 31 + hash ^ list[i].hashCode) & 0x3fffffff;
    }
    return hash;
  }
}

/// Maps uint31 pairs to values of type [T].
class Uint31PairMap<T> {
  final HashMap<int, T> _table = new HashMap<int, T>(hashCode: _bigintHash);
  int _key;

  /// Returns the value associated with the given pair, or `null` if no value
  /// is associated with the pair.
  ///
  /// This association can be changed using a subsequent call to [put].
  T lookup(int x, int y) {
    assert(x >= 0 && x >> 31 == 0);
    assert(y >= 0 && y >> 31 == 0);
    int key = (x << 31) + y;
    _key = key;
    return _table[key];
  }

  /// Associates [value] with the pair previously queried using [lookup].
  void put(T value) {
    _table[_key] = value;
  }

  Iterable<T> get values => _table.values;

  static int _bigintHash(int bigint) {
  	int x = 0x3fffffff & (bigint >> 31);
  	int y = 0x3fffffff & bigint;
    int hash = 0x3fffffff & (x * 1367);
    hash = 0x3fffffff & (y * 31 + hash ^ y);
    hash = 0x3fffffff & ((x ^ y) * 31 + hash ^ y);
    return hash;
  }
}
