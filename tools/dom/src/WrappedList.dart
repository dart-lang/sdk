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

  E operator [](int index) => _downcast/*<Node, E>*/(_list[index]);

  void operator []=(int index, E value) {
    _list[index] = value;
  }

  set length(int newLength) {
    _list.length = newLength;
  }

  void sort([int compare(E a, E b)]) {
    _list.sort((Node a, Node b) =>
        compare(_downcast/*<Node, E>*/(a), _downcast/*<Node, E>*/(b)));
  }

  int indexOf(Object element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(Object element, [int start]) =>
      _list.lastIndexOf(element, start);

  void insert(int index, E element) => _list.insert(index, element);

  E removeAt(int index) => _downcast/*<Node, E>*/(_list.removeAt(index));

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

  E get current => _downcast/*<Node, E>*/(_iterator.current);
}

// ignore: STRONG_MODE_DOWN_CAST_COMPOSITE
/*=To*/ _downcast/*<From, To extends From>*/(dynamic/*=From*/ x) => x;
