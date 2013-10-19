// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Wrappers that prevent List, Set, or Map objects from being modified.
 *
 * The [Set] and [Map] wrappers allow reading from the wrapped collection,
 * but prohibit writing.
 *
 * The [List] wrapper prevents changes to the length of the wrapped list,
 * but allows changes to the contents.
 */
library unmodifiable_collection;

import "dart:math" show Random;
export "dart:collection" show UnmodifiableListView;

/**
 * A fixed-length list.
 *
 * A NonGrowableListView contains a [List] object and ensures that
 * its length does not change.
 * Methods that would change the length of the list,
 * such as [add] and [remove], throw an [UnsupportedError].
 *
 * This class _does_ allow changes to the contents of the wrapped list.
 * You can, for example, [sort] the list.
 * Permitted operations defer to the wrapped list.
 */
class NonGrowableListView<E> extends _IterableView<E>
                                     implements List<E> {
  List<E> _source;
  NonGrowableListView(List<E> source) : _source = source;

  static void _throw() {
    throw new UnsupportedError(
        "Cannot change the length of a fixed-length list");
  }

  int get length => _source.length;

  E operator [](int index) => _source[index];

  int indexOf(E element, [int start = 0]) => _source.indexOf(element, start);

  int lastIndexOf(E element, [int start])
      => _source.lastIndexOf(element, start);

  Iterable<E> getRange(int start, int end) => _source.getRange(start, end);

  List<E> sublist(int start, [int end]) => _source.sublist(start, end);

  Iterable<E> get reversed => _source.reversed;

  Map<int, E> asMap() => _source.asMap();

  void operator []=(int index, E value) { _source[index] = value; }

  void sort([int compare(E a, E b)]) { _source.sort(compare); }

  void shuffle([Random random]) { _source.shuffle(random); }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _source.setRange(start, end, iterable, skipCount);
  }

  void fillRange(int start, int end, [E fillValue]) {
    _source.fillRange(start, end, fillValue);
  }

  void setAll(int index, Iterable<E> iterable) {
    _source.setAll(index, iterable);
  }


  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void set length(int newLength) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  bool add(E value) {
    _throw();
  }

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void addAll(Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void insert(int index, E element) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void insertAll(int index, Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  bool remove(Object value) { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  E removeAt(int index) { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  E removeLast() { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void removeWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void retainWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void removeRange(int start, int end) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void replaceRange(int start, int end, Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void clear() => _throw();
}

/**
 * An unmodifiable set.
 *
 * An UnmodifiableSetView contains a [Set] object and ensures
 * that it does not change.
 * Methods that would change the set,
 * such as [add] and [remove], throw an [UnsupportedError].
 * Permitted operations defer to the wrapped set.
 */
class UnmodifiableSetView<E> extends _IterableView<E>
                                      implements Set<E> {
  Set<E> _source;
  UnmodifiableSetView(Set<E> source) : _source = source;

  void _throw() {
    throw new UnsupportedError("Cannot modify an unmodifiable Set");
  }

  bool containsAll(Iterable<E> other) => _source.containsAll(other);

  Set<E> intersection(Set<E> other) => _source.intersection(other);

  Set<E> union(Set<E> other) => _source.union(other);

  Set<E> difference(Set<E> other) => _source.difference(other);

  E lookup(Object object) => _source.lookup(object);

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  bool add(E value) {
    _throw();
  }

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void addAll(Iterable<E> elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  bool remove(Object value) { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void removeAll(Iterable elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void retainAll(Iterable elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void removeWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void retainWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void clear() => _throw();
}

/**
 * An unmodifiable map.
 *
 * An UnmodifiableMapView contains a [Map] object and ensures
 * that it does not change.
 * Methods that would change the map,
 * such as [addAll] and [remove], throw an [UnsupportedError].
 * Permitted operations defer to the wrapped map.
 */
class UnmodifiableMapView<K, V> implements Map<K, V> {
  Map<K, V> _source;
  UnmodifiableMapView(Map<K, V> source) : _source = source;

  static void _throw() {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  int get length => _source.length;

  bool get isEmpty => _source.isEmpty;

  bool get isNotEmpty => _source.isNotEmpty;

  V operator [](K key) => _source[key];

  bool containsKey(K key) => _source.containsKey(key);

  bool containsValue(V value) => _source.containsValue(value);

  void forEach(void f(K key, V value)) => _source.forEach(f);

  Iterable<K> get keys => _source.keys;

  Iterable<V> get values => _source.values;


  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void operator []=(K key, V value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  V putIfAbsent(K key, V ifAbsent()) { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void addAll(Map<K, V> other) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  V remove(K key) { _throw(); }

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void clear() => _throw();
}

abstract class _IterableView<E> {
  Iterable<E> get _source;

  bool any(bool test(E element)) => _source.any(test);

  bool contains(E element) => _source.contains(element);

  E elementAt(int index) => _source.elementAt(index);

  bool every(bool test(E element)) => _source.every(test);

  Iterable expand(Iterable f(E element)) => _source.expand(f);

  E get first => _source.first;

  E firstWhere(bool test(E element), { E orElse() })
      => _source.firstWhere(test, orElse: orElse);

  dynamic fold(var initialValue,
               dynamic combine(var previousValue, E element))
      => _source.fold(initialValue, combine);

  void forEach(void f(E element)) => _source.forEach(f);

  bool get isEmpty => _source.isEmpty;

  bool get isNotEmpty => _source.isNotEmpty;

  Iterator<E> get iterator => _source.iterator;

  String join([String separator = ""]) => _source.join(separator);

  E get last => _source.last;

  E lastWhere(bool test(E element), {E orElse()})
      => _source.lastWhere(test, orElse: orElse);

  int get length => _source.length;

  Iterable map(f(E element)) => _source.map(f);

  E reduce(E combine(E value, E element)) => _source.reduce(combine);

  E get single => _source.single;

  E singleWhere(bool test(E element)) => _source.singleWhere(test);

  Iterable<E> skip(int n) => _source.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => _source.skipWhile(test);

  Iterable<E> take(int n) => _source.take(n);

  Iterable<E> takeWhile(bool test(E value)) => _source.takeWhile(test);

  List<E> toList({ bool growable: true }) => _source.toList(growable: growable);

  Set<E> toSet() => _source.toSet();

  Iterable<E> where(bool test(E element)) => _source.where(test);
}
