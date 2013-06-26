// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Unmodifiable wrappers for [List], [Set] and [Map] objects.
 *
 * The wrappers allow reading from the source list, but writing is prohibited.
 *
 * A non-growable list wrapper allows writing as well, but not changing the
 * list's length.
 */
library unmodifiable_collection;

export "dart:collection" show UnmodifiableListView;

/**
 * A [List] wrapper that acts as a non-growable list.
 *
 * Writes to the list are written through to the source list, but operations
 * that change the length is not allowed.
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

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _source.setRange(start, end, iterable, skipCount);
  }

  void fillRange(int start, int end, [E fillValue]) {
    _source.fillRange(start, end, fillValue);
  }

  void setAll(int index, Iterable<E> iterable) {
    _source.setAll(index, iterable);
  }


  void set length(int newLength) => _throw();

  void add(E value) => _throw();

  void addAll(Iterable<E> iterable) => _throw();

  void insert(int index, E element) => _throw();

  void insertAll(int index, Iterable<E> iterable) => _throw();

  bool remove(Object value) { _throw(); }

  E removeAt(int index) { _throw(); }

  E removeLast() { _throw(); }

  void removeWhere(bool test(E element)) => _throw();

  void retainWhere(bool test(E element)) => _throw();

  void removeRange(int start, int end) => _throw();

  void replaceRange(int start, int end, Iterable<E> iterable) => _throw();

  void clear() => _throw();
}

/**
 * A [Set] wrapper that acts as an unmodifiable set.
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


  void add(E value) => _throw();

  void addAll(Iterable<E> elements) => _throw();

  bool remove(Object value) { _throw(); }

  void removeAll(Iterable elements) => _throw();

  void retainAll(Iterable elements) => _throw();

  void removeWhere(bool test(E element)) => _throw();

  void retainWhere(bool test(E element)) => _throw();

  void clear() => _throw();
}

/**
 * A [Map] wrapper that acts as an unmodifiable map.
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


  void operator []=(K key, V value) => _throw();

  V putIfAbsent(K key, V ifAbsent()) { _throw(); }

  void addAll(Map<K, V> other) => _throw();

  V remove(K key) { _throw(); }

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
