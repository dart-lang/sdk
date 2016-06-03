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
}

bool _contentEquals(List<Object> first, List<Object> second) {
  if (first.length != second.length) return false;
  for (int i = 0; i < first.length; ++i) {
    if (first[i] != second[i]) return false;
  }
  return true;
}

int _contentHashCode(List<Object> list) {
  int hash = 0;
  for (int i = 0; i < list.length; ++i) {
    hash = (hash * 31 + hash ^ list[i].hashCode) & 0x3fffffff;
  }
  return hash;
}
