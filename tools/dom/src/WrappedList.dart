// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/**
 * A list which just wraps another list, for either intercepting list calls or
 * retyping the list (for example, from List<A> to List<B> where B extends A).
 */
class _WrappedList<E> implements List<E> {
  final List _list;

  _WrappedList(this._list);

  // Iterable APIs

  Iterator<E> get iterator => new _WrappedIterator(_list.iterator);

  Iterable map(f(E element)) => _list.map(f);

  Iterable<E> where(bool f(E element)) => _list.where(f);

  Iterable expand(Iterable f(E element)) => _list.expand(f);

  bool contains(E element) => _list.contains(element);

  void forEach(void f(E element)) { _list.forEach(f); }

  dynamic reduce(initialValue, combine(previousValue, E element)) =>
      _list.reduce(initialValue, combine);

  bool every(bool f(E element)) => _list.every(f);

  String join([String separator]) => _list.join(separator);

  bool any(bool f(E element)) => _list.any(f);

  List<E> toList({ bool growable: true }) =>
      new List.from(_list, growable: growable);

  Set<E> toSet() => _list.toSet();

  int get length => _list.length;

  E min([int compare(E a, E b)]) => _list.min(compare);

  E max([int compare(E a, E b)]) => _list.max(compare);

  bool get isEmpty => _list.isEmpty;

  Iterable<E> take(int n) => _list.take(n);

  Iterable<E> takeWhile(bool test(E value)) => _list.takeWhile(test);

  Iterable<E> skip(int n) => _list.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => _list.skipWhile(test);

  E get first => _list.first;

  E get last => _list.last;

  E get single => _list.single;

  E firstMatching(bool test(E value), { E orElse() }) =>
      _list.firstMatching(test, orElse: orElse);

  E lastMatching(bool test(E value), {E orElse()}) =>
      _list.lastMatching(test, orElse: orElse);

  E singleMatching(bool test(E value)) => _list.singleMatching(test);

  E elementAt(int index) => _list.elementAt(index);

  // Collection APIs

  void add(E element) { _list.add(element); }

  void addAll(Iterable<E> elements) { _list.addAll(elements); }

  void remove(Object element) { _list.remove(element); }

  void removeAll(Iterable elements) { _list.removeAll(elements); }

  void retainAll(Iterable elements) { _list.retainAll(elements); }

  void removeMatching(bool test(E element)) { _list.removeMatching(test); }

  void retainMatching(bool test(E element)) { _list.retainMatching(test); }

  void clear() { _list.clear(); }

  // List APIs

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) { _list[index] = value; }

  void set length(int newLength) { _list.length = newLength; }

  void addLast(E value) { _list.addLast(value); }

  Iterable<E> get reversed => _list.reversed;

  void sort([int compare(E a, E b)]) { _list.sort(compare); }

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(E element, [int start]) => _list.lastIndexOf(element, start);

  E removeAt(int index) => _list.removeAt(index);

  E removeLast() => _list.removeLast();

  List<E> getRange(int start, int length) => _list.getRange(start, length);

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    _list.setRange(start, length, from, startFrom);
  }

  void removeRange(int start, int length) { _list.removeRange(start, length); }

  void insertRange(int start, int length, [E fill]) {
    _list.insertRange(start, length, fill);
  }
}

/**
 * Iterator wrapper for _WrappedList.
 */
class _WrappedIterator<E> implements Iterator<E> {
  Iterator _iterator;

  _WrappedIterator(this._iterator);

  bool moveNext() {
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}
