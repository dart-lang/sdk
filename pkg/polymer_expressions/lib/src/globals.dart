// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Contains functions that are included by default in [PolymerExpressions].
 *
 *   - [enumerate]: a convenient way to iterate over items and the indexes.
 */
// Code from https://github.com/google/quiver-dart/commit/52edc4baf37e99ff6a8f99c648b29b135fc0b880
library polymer_expressions.src.globals;

import 'dart:collection';
import 'package:observe/observe.dart' show reflectable;

/**
 * Returns an [Iterable] of [IndexedValue]s where the nth value holds the nth
 * element of [iterable] and its index.
 */
Iterable<IndexedValue> enumerate(Iterable iterable) =>
    new EnumerateIterable(iterable);

@reflectable class IndexedValue<V> {
  final int index;
  final V value;

  operator==(o) => o is IndexedValue && o.index == index && o.value == value;
  int get hashCode => value.hashCode;
  String toString() => '($index, $value)';

  IndexedValue(this.index, this.value);
}

/**
 * An [Iterable] of [IndexedValue]s where the nth value holds the nth
 * element of [iterable] and its index. See [enumerate].
 */
// This was inspired by MappedIterable internal to Dart collections.
class EnumerateIterable<V> extends IterableBase<IndexedValue<V>> {
  final Iterable<V> _iterable;

  EnumerateIterable(this._iterable);

  Iterator<IndexedValue<V>> get iterator =>
      new EnumerateIterator<V>(_iterable.iterator);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;

  // Index based lookup can be done before transforming.
  IndexedValue<V> get first => new IndexedValue<V>(0, _iterable.first);
  IndexedValue<V> get last => new IndexedValue<V>(length - 1, _iterable.last);
  IndexedValue<V> get single => new IndexedValue<V>(0, _iterable.single);
  IndexedValue<V> elementAt(int index) =>
      new IndexedValue<V>(index, _iterable.elementAt(index));
}

/** The [Iterator] returned by [EnumerateIterable.iterator]. */
class EnumerateIterator<V> extends Iterator<IndexedValue<V>> {
  final Iterator<V> _iterator;
  int _index = 0;
  IndexedValue<V> _current;

  EnumerateIterator(this._iterator);

  IndexedValue<V> get current => _current;

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = new IndexedValue(_index++, _iterator.current);
      return true;
    }
    _current = null;
    return false;
  }
}
