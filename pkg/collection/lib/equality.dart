// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines equality relations on collections.
 */
library dart.pkg.collection.equality;

import "dart:collection";

const int _HASH_MASK = 0x7fffffff;

/**
 * A generic equality relation on objects.
 */
abstract class Equality<E> {
  const factory Equality() = DefaultEquality;

  /**
   * Compare two elements for being equal.
   *
   * This should be a proper equality relation.
   */
  bool equals(E e1, E e2);

  /**
   * Get a hashcode of an element.
   *
   * The hashcode should be compatible with [equals], so that if
   * `equals(a, b)` then `hash(a) == hash(b)`.
   */
  int hash(E e);

  /**
   * Test whether an object is a valid argument to [equals] and [hash].
   *
   * Some implementations may be restricted to only work on specific types
   * of objects.
   */
  bool isValidKey(Object o);
}

/**
 * Equality of objects that compares only the natural equality of the objects.
 *
 * This equality uses the objects' own [Object.==] and [Object.hashCode] for
 * the equality.
 */
class DefaultEquality implements Equality {
  const DefaultEquality();
  bool equals(Object e1, Object e2) => e1 == e2;
  int hash(Object e) => e.hashCode;
  bool isValidKey(Object o) => true;
}

/**
 * Equality of objects that compares only the identity of the objects.
 */
class IdentityEquality implements Equality {
  const IdentityEquality();
  bool equals(Object e1, Object e2) => identical(e1, e2);
  int hash(Object e) => identityHashCode(e);
  bool isValidKey(Object o) => true;
}

/**
 * Equality on iterables.
 *
 * Two iterables are equal if they have the same elements in the same order.
 */
class IterableEquality<E> implements Equality<Iterable<E>> {
  final Equality<E> _elementEquality;
  const IterableEquality([Equality<E> elementEquality =
                              const DefaultEquality()])
      : _elementEquality = elementEquality;

  bool equals(Iterable<E> elements1, Iterable<E> elements2) {
    if (identical(elements1, elements2)) return true;
    if (elements1 == null || elements2 == null) return false;
    Iterator it1 = elements1.iterator;
    Iterator it2 = elements2.iterator;
    while (true) {
      bool hasNext = it1.moveNext();
      if (hasNext != it2.moveNext()) return false;
      if (!hasNext) return true;
      if (!_elementEquality.equals(it1.current, it2.current)) return false;
    }
  }

  int hash(Iterable<E> elements) {
    // Jenkins's one-at-a-time hash function.
    int hash = 0;
    for (E element in elements) {
      int c = _elementEquality.hash(element);
      hash = (hash + c) & _HASH_MASK;
      hash = (hash + (hash << 10)) & _HASH_MASK;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & _HASH_MASK;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _HASH_MASK;
    return hash;
  }

  bool isValidKey(Object o) => o is Iterable<E>;
}

/**
 * Equality on lists.
 *
 * Two lists are equal if they have the same length and their elements
 * at each index are equal.
 *
 * This is effectively the same as [IterableEquality] except that it
 * accesses elements by index instead of through iteration.
 */
class ListEquality<E> implements Equality<List<E>> {
  final Equality<E> _elementEquality;
  const ListEquality([Equality<E> elementEquality = const DefaultEquality()])
      : _elementEquality = elementEquality;

  bool equals(List<E> e1, List<E> e2) {
    if (identical(e1, e2)) return true;
    if (e1 == null || e2 == null) return false;
    int length = e1.length;
    if (length != e2.length) return false;
    for (int i = 0; i < length; i++) {
      if (!_elementEquality.equals(e1[i], e2[i])) return false;
    }
    return true;
  }

  int hash(List<E> e) {
    // Jenkins's one-at-a-time hash function.
    // This code is almost identical to the one in IterableEquality, except
    // that it uses indexing instead of iterating to get the elements.
    int hash = 0;
    for (int i = 0; i < e.length; i++) {
      int c = _elementEquality.hash(e[i]);
      hash = (hash + c) & _HASH_MASK;
      hash = (hash + (hash << 10)) & _HASH_MASK;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & _HASH_MASK;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _HASH_MASK;
    return hash;
  }

  bool isValidKey(Object o) => o is List<E>;
}

abstract class _UnorderedEquality<E, T extends Iterable<E>>
    implements Equality<T> {
  final Equality<E> _elementEquality;

  const _UnorderedEquality(this._elementEquality);

  bool equals(T e1, T e2) {
    if (identical(e1, e2)) return true;
    if (e1 == null || e2 == null) return false;
    HashMap<E, int> counts = new HashMap(
        equals: _elementEquality.equals,
        hashCode: _elementEquality.hash,
        isValidKey: _elementEquality.isValidKey);
    int length = 0;
    for (var e in e1) {
      int count = counts[e];
      if (count == null) count = 0;
      counts[e] = count + 1;
      length++;
    }
    for (var e in e2) {
      int count = counts[e];
      if (count == null || count == 0) return false;
      counts[e] = count - 1;
      length--;
    }
    return length == 0;
  }

  int hash(T e) {
    int hash = 0;
    for (E element in e) {
      int c = _elementEquality.hash(element);
      hash = (hash + c) & _HASH_MASK;
    }
    hash = (hash + (hash << 3)) & _HASH_MASK;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _HASH_MASK;
    return hash;
  }
}

/**
 * Equality of the elements of two iterables without considering order.
 *
 * Two iterables are considered equal if they have the same number of elements,
 * and the elements of one set can be paired with the elements
 * of the other iterable, so that each pair are equal.
 */
class UnorderedIterableEquality<E> extends _UnorderedEquality<E, Iterable<E>> {
  const UnorderedIterableEquality(
      [Equality<E> elementEquality = const DefaultEquality()])
      : super(elementEquality);

  bool isValidKey(Object o) => o is Iterable<E>;
}

/**
 * Equality of sets.
 *
 * Two sets are considered equal if they have the same number of elements,
 * and the elements of one set can be paired with the elements
 * of the other set, so that each pair are equal.
 *
 * This equality behaves the same as [UnorderedIterableEquality] except that
 * it expects sets instead of iterables as arguments.
 */
class SetEquality<E> extends _UnorderedEquality<E, Set<E>> {
  const SetEquality(
      [Equality<E> elementEquality = const DefaultEquality()])
      : super(elementEquality);

  bool isValidKey(Object o) => o is Set<E>;
}

/**
 *  Internal class used by [MapEquality].
 *
 *  The class represents a map entry as a single object,
 *  using a combined hashCode and equality of the key and value.
 */
class _MapEntry {
  final MapEquality equality;
  final key;
  final value;
  _MapEntry(this.equality, this.key, this.value);

  int get hashCode =>
      (3 * equality._keyEquality.hash(key) +
       7 * equality._valueEquality.hash(value)) & _HASH_MASK;

  bool operator==(Object other) {
    if (other is! _MapEntry) return false;
    _MapEntry otherEntry = other;
    return equality._keyEquality.equals(key, otherEntry.key) &&
           equality._valueEquality.equals(value, otherEntry.value);

  }
}

/**
 * Equality on maps.
 *
 * Two maps are equal if they have the same number of entries, and if the
 * entries of the two maps are pairwise equal on both key and value.
 */
class MapEquality<K, V> implements Equality<Map<K, V>> {
  final Equality<K> _keyEquality;
  final Equality<V> _valueEquality;
  const MapEquality({ Equality<K> keys : const DefaultEquality(),
                      Equality<V> values : const DefaultEquality() })
      : _keyEquality = keys, _valueEquality = values;

  bool equals(Map<K, V> e1, Map<K, V> e2) {
    if (identical(e1, e2)) return true;
    if (e1 == null || e2 == null) return false;
    int length = e1.length;
    if (length != e2.length) return false;
    Map<_MapEntry, int> equalElementCounts = new HashMap();
    for (K key in e1.keys) {
      _MapEntry entry = new _MapEntry(this, key, e1[key]);
      int count = equalElementCounts[entry];
      if (count == null) count = 0;
      equalElementCounts[entry] = count + 1;
    }
    for (K key in e2.keys) {
      _MapEntry entry = new _MapEntry(this, key, e2[key]);
      int count = equalElementCounts[entry];
      if (count == null || count == 0) return false;
      equalElementCounts[entry] = count - 1;
    }
    return true;
  }

  int hash(Map<K, V> map) {
    int hash = 0;
    for (K key in map.keys) {
      int keyHash = _keyEquality.hash(key);
      int valueHash = _valueEquality.hash(map[key]);
      hash = (hash + 3 * keyHash + 7 * valueHash) & _HASH_MASK;
    }
    hash = (hash + (hash << 3)) & _HASH_MASK;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _HASH_MASK;
    return hash;
  }

  bool isValidKey(Object o) => o is Map<K, V>;
}

/**
 * Combines several equalities into a single equality.
 *
 * Tries each equality in order, using [Equality.isValidKey], and returns
 * the result of the first equality that applies to the argument or arguments.
 *
 * For `equals`, the first equality that matches the first argument is used,
 * and if the second argument of `equals` is not valid for that equality,
 * it returns false.
 *
 * Because the equalities are tried in order, they should generally work on
 * disjoint types. Otherwise the multi-equality may give inconsistent results
 * for `equals(e1, e2)` and `equals(e2, e1)`. This can happen if one equality
 * considers only `e1` a valid key, and not `e2`, but an equality which is
 * checked later, allows both.
 */
class MultiEquality<E> implements Equality<E> {
  final Iterable<Equality<E>> _equalities;

  const MultiEquality(Iterable<Equality<E>> equalities)
      : _equalities = equalities;

  bool equals(E e1, E e2) {
    for (Equality<E> eq in _equalities) {
      if (eq.isValidKey(e1)) return eq.isValidKey(e2) && eq.equals(e1, e2);
    }
    return false;
  }

  int hash(E e) {
    for (Equality<E> eq in _equalities) {
      if (eq.isValidKey(e)) return eq.hash(e);
    }
    return -1;
  }

  bool isValidKey(Object o) {
    for (Equality<E> eq in _equalities) {
      if (eq.isValidKey(o)) return true;
    }
    return false;
  }
}

/**
 * Deep equality on collections.
 *
 * Recognizes lists, sets, iterables and maps and compares their elements using
 * deep equality as well.
 *
 * Non-iterable/map objects are compared using a configurable base equality.
 *
 * Works in one of two modes: ordered or unordered.
 *
 * In ordered mode, lists and iterables are required to have equal elements
 * in the same order. In unordered mode, the order of elements in iterables
 * and lists are not importan.
 *
 * A list is only equal to another list, likewise for sets and maps. All other
 * iterables are compared as iterables only.
 */
class DeepCollectionEquality implements Equality {
  final Equality _base;
  final bool _unordered;
  const DeepCollectionEquality([Equality base = const DefaultEquality()])
      : _base = base, _unordered = false;

  /**
   * Creates a deep equality on collections where the order of lists and
   * iterables are not considered important. That is, lists and iterables are
   * treated as unordered iterables.
   */
  const DeepCollectionEquality.unordered(
      [Equality base = const DefaultEquality()])
      : _base = base, _unordered = true;

  bool equals(e1, e2) {
    if (e1 is Set) {
      if (e2 is! Set) return false;
      return new SetEquality(this).equals(e1, e2);
    }
    if (e1 is Map) {
      if (e2 is! Map) return false;
      return new MapEquality(keys: this, values: this).equals(e1, e2);
    }
    if (!_unordered) {
      if (e1 is List) {
        if (e2 is! List) return false;
        return new ListEquality(this).equals(e1, e2);
      }
      if (e1 is Iterable) {
        if (e2 is! Iterable) return false;
        return new IterableEquality(this).equals(e1, e2);
      }
    } else if (e1 is Iterable) {
      if (e2 is! Iterable) return false;
      if (e1 is List != e2 is List) return false;
      return new UnorderedIterableEquality(this).equals(e1, e2);
    }
    return _base.equals(e1, e2);
  }

  int hash(Object o) {
    if (o is Set) return new SetEquality(this).hash(o);
    if (o is Map) return new MapEquality(keys: this, values: this).hash(o);
    if (!_unordered) {
      if (o is List) return new ListEquality(this).hash(o);
      if (o is Iterable) return new IterableEquality(this).hash(o);
    } else if (o is Iterable) {
      return new UnorderedIterableEquality(this).hash(o);
    }
    return _base.hash(o);
  }

  bool isValidKey(Object o) => o is Iterable || o is Map || _base.isValidKey(o);
}
