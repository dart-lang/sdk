// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection.dev;

/**
 * Class implementing the read-operations on [List].
 *
 * Implements all read-only operations, except [:operator[]:] and [:length:],
 * in terms of those two operations.
 */
abstract class ListBase<E> extends Collection<E> implements List<E> {
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

  List mappedBy(f(E element)) {
    return new MappedList(this, f);
  }

  List<E> take(int n) {
    return new ListView(this, 0, n);
  }

  List<E> skip(int n) {
    return new ListView(this, n, null);
  }

  String toString() => ToString.collectionToString(this);
}

/**
 * Abstract class implementing the non-length changing operations of [List].
 */
abstract class FixedLengthListBase<E> extends ListBase<E> {
  void operator[]=(int index, E value);

  List<E> get reversed => new ReversedListView<E>(this, 0, null);

  void sort([Comparator<E> compare]) {
    Sort.sort(this, compare);
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    if (length < 0) throw new ArgumentError("length: $length");
    if (startFrom == null) startFrom = 0;
    for (int i = 0; i < length; i++) {
      this[start + i] = from[startFrom + i];
    }
  }

  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of a fixed-length list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear a fixed-length list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in a fixed-length list");
  }
}

/**
 * An unmodifiable [List].
 */
abstract class UnmodifiableListBase<E> extends ListBase<E> {

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
  final int _length;
  int _position;
  E _current;

  ListIterator(List<E> list)
      : _list = list, _position = -1, _length = list.length;

  bool moveNext() {
    if (_list.length != _length) {
      throw new ConcurrentModificationError(_list);
    }
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _position = nextPosition;
      _current = _list[nextPosition];
      return true;
    }
    _current = null;
    return false;
  }

  E get current => _current;
}

class MappedList<S, T> extends UnmodifiableListBase<T> {
  final List<S> _list;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedList(this._list, T this._f(S element));

  T operator[](int index) => _f(_list[index]);
  int get length => _list.length;
}

/** An empty fixed-length list. */
class EmptyList<E> extends FixedLengthListBase<E> {
  int get length => 0;
  E operator[](int index) { throw new RangeError.value(index); }
  void operator []=(int index, E value) { throw new RangeError.value(index); }
  List<E> skip(int count) => this;
  List<E> take(int count) => this;
  List<E> get reversed => this;
  void sort([int compare(E a, E b)]) {}
}

/**
 * A fixed-length view of a sub-range of another [List].
 *
 * The range is described by start and end points relative
 * to the other List's start or end.
 *
 * The range changes dynamically as the underlying list changes
 * its length.
 */
abstract class SubListView<E> extends UnmodifiableListBase<E> {
  final List<E> _list;
  final int _start;
  final int _end;

  /**
   * Create a sub-list view.
   *
   * Both [_start] and [_end] can be given as positions
   * relative to the start of [_list] (a non-negative integer)
   * or relative to the end of [_list] (a negative integer or
   * null, with null being at the end of the list).
   */
  SubListView(this._list, this._start, this._end);

  int _absoluteIndex(int relativeIndex) {
    if (relativeIndex == null) return _list.length;
    if (relativeIndex < 0) {
      int result = _list.length + relativeIndex;
      if (result < 0) return 0;
      return result;
    }
    if (relativeIndex > _list.length) {
      return _list.length;
    }
    return relativeIndex;
  }

  int get length {
    int result = _absoluteIndex(_end) - _absoluteIndex(_start);
    if (result >= 0) return result;
    return 0;
  }

  _createListView(int start, int end) {
    if (start == null) return new EmptyList<E>();
    if (end != null) {
      if (start < 0) {
        if (end <= start) return new EmptyList<E>();
      } else {
        if (end >= 0 && end <= start) return new EmptyList<E>();
      }
    }
    return new ListView(_list, start, end);
  }

  _createReversedListView(int start, int end) {
    if (start == null) return new EmptyList<E>();
    if (end != null) {
      if (start < 0) {
        if (end <= start) return new EmptyList<E>();
      } else {
        if (end >= 0 && end <= start) return new EmptyList<E>();
      }
    }
    return new ReversedListView(_list, start, end);
  }
}


/**
 * A fixed-length view of a sub-range of a [List].
 */
class ListView<E> extends SubListView<E> {

  ListView(List<E> list, int start, int end) : super(list, start, end);

  E operator[](int index) {
    int start = _absoluteIndex(_start);
    int end = _absoluteIndex(_end);
    int length = end - start;
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    }
    return _list[start + index];
  }

  List<E> skip(int count) {
    if (count is! int || count < 0) {
      throw new ArgumentError(count);
    }
    if (_start == null) {
      return new EmptyList<E>();
    }
    int newStart = _start + count;
    if (_start < 0 && newStart >= 0) {
      return new EmptyList<E>();
    }
    return _createListView(newStart, _end);
  }

  List<E> take(int count) {
    if (count is! int || count < 0) {
      throw new ArgumentError(count);
    }
    if (_start == null) {
      return new EmptyList<E>();
    }
    int newEnd = _start + count;
    if (_start < 0 && newEnd >= 0) {
      newEnd = null;
    }
    return _createListView(_start, newEnd);
  }

  List<E> get reversed => new ReversedListView(_list, _start, _end);
}

/**
 * Reversed view of a [List], or a slice of a list.
 *
 * The view is fixed-length and becomes invalid if the underlying
 * list changes its length below the slice used by this reversed list.
 *
 * Start index and end index can be either positive, negative or null.
 * Positive means an index relative to the start of the list,
 * negative means an index relative to the end of the list, and null
 * means at the end of the list (since there is no -0 integer).
 */
class ReversedListView<E> extends SubListView<E> {

  ReversedListView(List<E> list, int start, int end)
      : super(list, start, end);

  E operator[](int index) {
    int start = _absoluteIndex(_start);
    int end = _absoluteIndex(_end);
    int length = end - start;
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    }
    return _list[end - index - 1];
  }

  List<E> skip(int count) {
    if (count is! int || count < 0) {
      throw new ArgumentError(count);
    }
    if (_end == null) {
      return _createReversedListView(_start, -count);
    }
    int newEnd = _end - count;
    if (_end >= 0 && newEnd < 0) {
      return new EmptyList<E>();
    }
    return _createReversedListView(_start, newEnd);
  }

  List<E> take(int count) {
    if (count is! int || count < 0) {
      throw new ArgumentError(count);
    }
    int newStart;
    if (_end == null) {
      newStart = -count;
    } else {
      newStart = _end - count;
      if (_end >= 0 && newStart < 0) {
        return new EmptyList<E>();
      }
    }
    return _createReversedListView(newStart, _end);
  }

  Iterator<E> get iterator => new ReverseListIterator<E>(
      _list, _absoluteIndex(_start), _absoluteIndex(_end));

  List<E> get reversed {
    return new ListView(_list, _start, _end);
  }
}

/**
 * An [Iterator] over a slice of a list that access elements in reverse order.
 */
class ReverseListIterator<E> implements Iterator<E> {
  final List<E> _list;
  final int _start;
  final int _originalLength;
  int _index;
  E _current;

  ReverseListIterator(List<E> list, int start, int end)
      : _list = list,
        _start = start,
        _index = end,
        _originalLength = list.length;

  bool moveNext() {
    if (_list.length != _originalLength) {
      throw new ConcurrentModificationError(list);
    }
    if (_index <= _start) return false;
    _index -= 1;
    _current = _list[_index];
    return true;
  }

  E get current => _current;
}
