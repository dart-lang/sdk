// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/**
 * A list which just wraps another list, for either intercepting list calls or
 * retyping the list (for example, from List<A> to List<B> where B extends A).
 */
class _WrappedList<E extends Node> extends ListBase<E>
    implements NodeListWrapper {
  final List<Node> _list;

  _WrappedList(this._list);

  // Iterable APIs

  Iterator<E> get iterator => new _WrappedIterator<E>(_list.iterator);

  int get length => _list.length;

  // Collection APIs

  void add(E element) {
    _list.add(element);
  }

  bool remove(Object element) => _list.remove(element);

  void clear() {
    _list.clear();
  }

  // List APIs

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) {
    _list[index] = value;
  }

  set length(int newLength) {
    _list.length = newLength;
  }

  void sort([int compare(E a, E b)]) {
    // Implicit downcast on argument from Node to E-extends-Node.
    _list.sort((Node a, Node b) => compare(a, b));
  }

  int indexOf(Object element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(Object element, [int start]) =>
      _list.lastIndexOf(element, start);

  void insert(int index, E element) => _list.insert(index, element);

  E removeAt(int index) => _list.removeAt(index);

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _list.setRange(start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    _list.removeRange(start, end);
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _list.replaceRange(start, end, iterable);
  }

  void fillRange(int start, int end, [E fillValue]) {
    _list.fillRange(start, end, fillValue);
  }

  List<Node> get rawList => _list;
}

/**
 * Iterator wrapper for _WrappedList.
 */
class _WrappedIterator<E extends Node> implements Iterator<E> {
  Iterator<Node> _iterator;

  _WrappedIterator(this._iterator);

  bool moveNext() {
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}
