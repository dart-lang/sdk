// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection.dev;

/**
 * Skeleton class for an unmodifiable [List].
 */
abstract class NonExtensibleListMixin<E>
    extends Iterable<E> implements List<E> {

  Iterator<E> get iterator => new ListIterator(this);

  void forEach(f(E element)) {
    for (int i = 0; i < this.length; i++) f(this[i]);
  }

  bool contains(E value) {
    for (int i = 0; i < length; i++) {
      if (this[i] == value) return true;
    }
    return false;
  }

  reduce(initialValue, combine(previousValue, E element)) {
    var value = initialValue;
    for (int i = 0; i < this.length; i++) {
      value = combine(value, this[i]);
    }
    return value;
  }

  bool every(bool f(E element)) {
    for (int i = 0; i < this.length; i++) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(E element)) {
    for (int i = 0; i < this.length; i++) {
      if (f(this[i])) return true;
    }
    return false;
  }

  bool get isEmpty {
    return this.length == 0;
  }

  E elementAt(int index) {
    return this[index];
  }

  int indexOf(E value, [int start = 0]) {
    for (int i = start; i < length; i++) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  int lastIndexOf(E value, [int start]) {
    if (start == null) start = length - 1;
    for (int i = start; i >= 0; i--) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  E get first {
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  List<E> getRange(int start, int length) {
    List<E> result = <E>[];
    for (int i = 0; i < length; i++) {
      result.add(this[start + i]);
    }
    return result;
  }

  void operator []=(int index, E value) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of an unmodifiable list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }
  void sort([Comparator<E> compare]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear an unmodifiable list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in an unmodifiable list");
  }
}

/**
 * Iterates over a [List] in growing index order.
 */
class ListIterator<E> implements Iterator<E> {
  final List<E> _list;
  int _position;
  E _current;

  ListIterator(this._list) : _position = -1;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _list.length) {
      _current = _list[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _list.length;
    _current = null;
    return false;
  }

  E get current => _current;
}

class MappedList<S, T> extends NonExtensibleListMixin<T> {
  final List<S> _list;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedList(this._list, T this._f(S element));

  T operator[](int index) => _f(_list[index]);
  int get length => _list.length;
}

/**
 * An immutable view of a [List].
 */
class ListView<E> extends NonExtensibleListMixin<E> {
  final List<E> _list;
  final int _offset;
  final int _length;

  /**
   * If the given length is `null` then the ListView's length is bound by
   * the backed [list].
   */
  ListView(List<E> list, this._offset, this._length) : _list = list {
    if (_offset is! int || _offset < 0) {
      throw new ArgumentError(_offset);
    }
    if (_length != null &&
        (_length is! int || _length < 0)) {
      throw new ArgumentError(_length);
    }
  }

  int get length {
    int originalLength = _list.length;
    int skipLength = originalLength - _offset;
    if (skipLength < 0) return 0;
    if (_length == null || _length > skipLength) return skipLength;
    return _length;
  }

  E operator[](int index) {
    int skipIndex = index + _offset;
    if (index < 0 ||
        (_length != null && index >= _length) ||
        index + _offset >= _list.length) {
      throw new RangeError.value(index);
    }
    return _list[index + _offset];
  }

  ListView<E> skip(int skipCount) {
    if (skipCount is! int || skipCount < 0) {
      throw new ArgumentError(skipCount);
    }
    return new ListView(_list, _offset + skipCount, _length);
  }

  ListView<E> take(int takeCount) {
    if (takeCount is! int || takeCount < 0) {
      throw new ArgumentError(takeCount);
    }
    int newLength = takeCount;
    if (_length != null && takeCount > _length) newLength = _length;
    return new ListView(_list, _offset, newLength);
  }
}
