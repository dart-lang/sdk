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

  E reduce(E combine(E value, E element)) =>
      _list.reduce(combine);

  dynamic fold(initialValue, combine(previousValue, E element)) =>
      _list.fold(initialValue, combine);

  bool every(bool f(E element)) => _list.every(f);

  String join([String separator = ""]) => _list.join(separator);

  bool any(bool f(E element)) => _list.any(f);

  List<E> toList({ bool growable: true }) =>
      new List.from(_list, growable: growable);

  Set<E> toSet() => _list.toSet();

  int get length => _list.length;

  bool get isEmpty => _list.isEmpty;

  Iterable<E> take(int n) => _list.take(n);

  Iterable<E> takeWhile(bool test(E value)) => _list.takeWhile(test);

  Iterable<E> skip(int n) => _list.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => _list.skipWhile(test);

  E get first => _list.first;

  E get last => _list.last;

  E get single => _list.single;

  E firstWhere(bool test(E value), { E orElse() }) =>
      _list.firstWhere(test, orElse: orElse);

  E lastWhere(bool test(E value), {E orElse()}) =>
      _list.lastWhere(test, orElse: orElse);

  E singleWhere(bool test(E value)) => _list.singleWhere(test);

  E elementAt(int index) => _list.elementAt(index);

  // Collection APIs

  void add(E element) { _list.add(element); }

  void addAll(Iterable<E> elements) { _list.addAll(elements); }

  void remove(Object element) { _list.remove(element); }

  void removeWhere(bool test(E element)) { _list.removeWhere(test); }

  void retainWhere(bool test(E element)) { _list.retainWhere(test); }

  void clear() { _list.clear(); }

  // List APIs

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) { _list[index] = value; }

  void set length(int newLength) { _list.length = newLength; }

  Iterable<E> get reversed => _list.reversed;

  void sort([int compare(E a, E b)]) { _list.sort(compare); }

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(E element, [int start]) => _list.lastIndexOf(element, start);

  void insert(int index, E element) => _list.insert(index, element);

  void insertAll(int index, Iterable<E> iterable) =>
      _list.insertAll(index, iterable);

  void setAll(int index, Iterable<E> iterable) =>
      _list.setAll(index, iterable);

  E removeAt(int index) => _list.removeAt(index);

  E removeLast() => _list.removeLast();

  List<E> sublist(int start, [int end]) => _list.sublist(start, end);

  Iterable<E> getRange(int start, int end) => _list.getRange(start, end);

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _list.setRange(start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) { _list.removeRange(start, end); }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _list.replaceRange(start, end, iterable);
  }

  void fillRange(int start, int end, [E fillValue]) {
    _list.fillRange(start, end, fillValue);
  }

  Map<int, E> asMap() => _list.asMap();

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
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
