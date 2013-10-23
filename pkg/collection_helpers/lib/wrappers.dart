// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Delegating wrappers for [Iterable], [List], [Set], [Queue] and [Map].
 */
library dart.collection_helper.wrappers;

import "dart:collection";
import "dart:math" show Random;

/**
 * Creates an [Iterable] that delegates all operations to a base iterable.
 *
 * This class can be used hide non-`Iterable` methods of an iterable object,
 * or it can be extended to add extra functionality on top of an existing
 * iterable object.
 */
class DelegatingIterable<E> implements Iterable<E> {
  Iterable<E> _base;

  /**
   * Create a wrapper that forwards operations to [base].
   */
  DelegatingIterable(Iterable<E> base) : _base = base;

  bool any(bool test(E element)) => _base.any(test);

  bool contains(Object element) => _base.contains(element);

  E elementAt(int index) => _base.elementAt(index);

  bool every(bool test(E element)) => _base.every(test);

  Iterable expand(Iterable f(E element)) => _base.expand(f);

  E get first => _base.first;

  E firstWhere(bool test(E element), {E orElse()}) =>
      _base.firstWhere(test, orElse: orElse);

  fold(initialValue, combine(previousValue, E element)) =>
      _base.fold(initialValue, combine);

  void forEach(void f(E element)) => _base.forEach(f);

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterator<E> get iterator => _base.iterator;

  String join([String separator = ""]) => _base.join(separator);

  E get last => _base.last;

  E lastWhere(bool test(E element), {E orElse()}) =>
      _base.lastWhere(test, orElse: orElse);

  int get length => _base.length;

  Iterable map(f(E element)) => _base.map(f);

  E reduce(E combine(E value, E element)) => _base.reduce(combine);

  E get single => _base.single;

  E singleWhere(bool test(E element)) => _base.singleWhere(test);

  Iterable<E> skip(int n) => _base.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => _base.skipWhile(test);

  Iterable<E> take(int n) => _base.take(n);

  Iterable<E> takeWhile(bool test(E value)) => _base.takeWhile(test);

  List<E> toList({bool growable: true}) => _base.toList(growable: growable);

  Set<E> toSet() => _base.toSet();

  Iterable<E> where(bool test(E element)) => _base.where(test);
}


/**
 * Creates a [List] that delegates all operations to a base list.
 *
 * This class can be used hide non-`List` methods of a list object,
 * or it can be extended to add extra functionality on top of an existing
 * list object.
 */
class DelegatingList<E> extends DelegatingIterable<E> implements List<E> {
  DelegatingList(List<E> base) : super(base);

  List<E> get _listBase => _base;

  E operator [](int index) => _listBase[index];

  void operator []=(int index, E value) {
    _listBase[index] = value;
  }

  void add(E value) {
    _listBase.add(value);
  }

  void addAll(Iterable<E> iterable) {
    _listBase.addAll(iterable);
  }

  Map<int, E> asMap() => _listBase.asMap();

  void clear() {
    _listBase.clear();
  }

  void fillRange(int start, int end, [E fillValue]) {
    _listBase.fillRange(start, end, fillValue);
  }

  Iterable<E> getRange(int start, int end) => _listBase.getRange(start, end);

  int indexOf(E element, [int start = 0]) => _listBase.indexOf(element, start);

  void insert(int index, E element) {
    _listBase.insert(index, element);
  }

  void insertAll(int index, Iterable<E> iterable) {
    _listBase.insertAll(index, iterable);
  }

  int lastIndexOf(E element, [int start]) =>
      _listBase.lastIndexOf(element, start);

  void set length(int newLength) {
    _listBase.length = newLength;
  }

  bool remove(Object value) => _listBase.remove(value);

  E removeAt(int index) => _listBase.removeAt(index);

  E removeLast() => _listBase.removeLast();

  void removeRange(int start, int end) {
    _listBase.removeRange(start, end);
  }

  void removeWhere(bool test(E element)) {
    _listBase.removeWhere(test);
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _listBase.replaceRange(start, end, iterable);
  }

  void retainWhere(bool test(E element)) {
    _listBase.retainWhere(test);
  }

  Iterable<E> get reversed => _listBase.reversed;

  void setAll(int index, Iterable<E> iterable) {
    _listBase.setAll(index, iterable);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _listBase.setRange(start, end, iterable, skipCount);
  }

  void shuffle([Random random]) {
    _listBase.shuffle(random);
  }

  void sort([int compare(E a, E b)]) {
    _listBase.sort(compare);
  }

  List<E> sublist(int start, [int end]) => _listBase.sublist(start, end);
}


/**
 * Creates a [Set] that delegates all operations to a base set.
 *
 * This class can be used hide non-`Set` methods of a set object,
 * or it can be extended to add extra functionality on top of an existing
 * set object.
 */
class DelegatingSet<E> extends DelegatingIterable<E> implements Set<E> {
  DelegatingSet(Set<E> base) : super(base);

  Set<E> get _setBase => _base;

  bool add(E value) => _setBase.add(value);

  void addAll(Iterable<E> elements) {
    _setBase.addAll(elements);
  }

  void clear() {
    _setBase.clear();
  }

  bool containsAll(Iterable<Object> other) => _setBase.containsAll(other);

  Set<E> difference(Set<E> other) => _setBase.difference(other);

  Set<E> intersection(Set<Object> other) => _setBase.intersection(other);

  E lookup(E element) => _setBase.lookup(element);

  bool remove(Object value) => _setBase.remove(value);

  void removeAll(Iterable<Object> elements) {
    _setBase.removeAll(elements);
  }

  void removeWhere(bool test(E element)) {
    _setBase.removeWhere(test);
  }

  void retainAll(Iterable<Object> elements) {
    _setBase.retainAll(elements);
  }

  void retainWhere(bool test(E element)) {
    _setBase.retainWhere(test);
  }

  Set<E> union(Set<E> other) => _setBase.union(other);
}

/**
 * Creates a [Queue] that delegates all operations to a base queue.
 *
 * This class can be used hide non-`Queue` methods of a queue object,
 * or it can be extended to add extra functionality on top of an existing
 * queue object.
 */
class DelegatingQueue<E> extends DelegatingIterable<E> implements Queue<E> {
  DelegatingQueue(Queue<E> queue) : super(queue);

  Queue<E> get _baseQueue => _base;

  void add(E value) {
    _baseQueue.add(value);
  }

  void addAll(Iterable<E> iterable) {
    _baseQueue.addAll(iterable);
  }

  void addFirst(E value) {
    _baseQueue.addFirst(value);
  }

  void addLast(E value) {
    _baseQueue.addLast(value);
  }

  void clear() {
    _baseQueue.clear();
  }

  bool remove(Object object) => _baseQueue.remove(object);

  E removeFirst() => _baseQueue.removeFirst();

  E removeLast() => _baseQueue.removeLast();
}

/**
 * Creates a [Map] that delegates all operations to a base map.
 *
 * This class can be used hide non-`Map` methods of an object that extends
 * `Map`, or it can be extended to add extra functionality on top of an existing
 * map object.
 */
class DelegatingMap<K, V> implements Map<K, V> {
  Map<K, V> _base;
  DelegatingMap(Map<K, V> base) : _base = base;

  V operator [](Object key) => _base[key];

  void operator []=(K key, V value) {
    _base[key] = value;
  }

  void addAll(Map<K, V> other) {
    _base.addAll(other);
  }

  void clear() {
    _base.clear();
  }

  bool containsKey(Object key) => _base.containsKey(key);

  bool containsValue(Object value) => _base.containsValue(value);

  void forEach(void f(K key, V value)) {
    _base.forEach(f);
  }

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterable<K> get keys => _base.keys;

  int get length => _base.length;

  V putIfAbsent(K key, V ifAbsent()) => _base.putIfAbsent(key, ifAbsent);

  V remove(Object key) => _base.remove(key);

  Iterable<V> get values => _base.values;
}
