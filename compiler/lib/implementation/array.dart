// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListFactory {
  factory List<E>.from(Iterable<E> other) {
    List<E> list = new List<E>();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  factory List<E>([int length = null]) {
    bool isFixed = true;
    if (length === null) {
      length = 0;
      isFixed = false;
    } else if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    // TODO(floitsch): make list creation more efficient. Currently we allocate
    // a new TypeToken at every allocation. Either we can optimize them away,
    // or we need to find other ways to pass type-information from Dart to JS.
    ListImplementation list = _new(new TypeToken<E>(), length);
    list._isFixed = isFixed;
    return list;
  }

  static ListImplementation _new(TypeToken typeToken, int length) native;
}


class ListImplementation<T> implements List<T> native "Array" {
  // ListImplementation maps directly to a JavaScript array. If the list is
  // constructed by the ListFactory.List constructor, it has an
  // additional named property for '_isFixed'. If it is a literal, the
  // code generator will not add the property. It will be 'undefined'
  // and coerce to false.
  bool _isFixed;

  T operator[](int index) {
    if (0 <= index && index < length) {
      return _indexOperator(index);
    }
    throw new IndexOutOfRangeException(index);
  }

  void operator[]=(int index, T value) {
    if (index < 0 || length <= index) {
      throw new IndexOutOfRangeException(index);
    }
    _indexAssignOperator(index, value);
  }

  Iterator<T> iterator() {
    if (_isFixed) {
      return new FixedSizeListIterator<T>(this);
    } else {
      return new VariableSizeListIterator<T>(this);
    }
  }

  T _indexOperator(int index) native;
  void _indexAssignOperator(int index, T value) native;
  int get length() native;
  void _setLength(int length) native;
  void _add(T value) native;
  void _removeRange(int start, int length) native;
  void _insertRange(int start, int length, T initialValue) native;

  void forEach(void f(T element)) {
    Collections.forEach(this, f);
  }

  Collection<T> filter(bool f(T element)) {
    return Collections.filter(this, new List<T>(), f);
  }

  bool every(bool f(T element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(T element)) {
    return Collections.some(this, f);
  }

  bool isEmpty() {
    return this.length == 0;
  }

  void sort(int compare(T a, T b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    Arrays.copy(src, srcStart, this, dstStart, count);
  }

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove range of a non-extendable list");
    }
    if (length == 0) {
      return;
    }
    Arrays.rangeCheck(this, start, length);
    Arrays.copy(from, startFrom, this, start, length);
  }

  void removeRange(int start, int length) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove range of a non-extendable list");
    }
    if (length == 0) {
      return;
    }
    Arrays.rangeCheck(this, start, length);
    _removeRange(start, length);
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot insert range in a non-extendable list");
    }
    if (length == 0) {
      return;
    }
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    if (start < 0 || start > this.length) {
      throw new IndexOutOfRangeException(start);
    }
    _insertRange(start, length, initialValue);
  }

  List<T> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new List<T>();
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  int indexOf(T element, int startIndex) {
    return Arrays.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(T element, int startIndex) {
    return Arrays.lastIndexOf(this, element, startIndex);
  }

  void add(T element) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot add to a non-extendable list");
    } else {
      _add(element);
    }
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Collection<T> elements) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot add to a non-extendable list");
    } else {
      for (final e in elements) {
        _add(e);
      }
    }
  }

  void clear() {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot clear a non-extendable list");
    } else {
      length = 0;
    }
  }

  void set length(int length) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot change the length of a non-extendable list");
    } else {
      _setLength(length);
    }
  }

  T removeLast() {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove in a non-extendable list");
    } else {
      T element = last();
      length = length - 1;
      return element;
    }
  }

  T last() {
    return this[length - 1];
  }
}


// Iterator for lists with fixed size.
class FixedSizeListIterator<T> extends VariableSizeListIterator<T> {
  FixedSizeListIterator(List list)
      : super(list),
        _length = list.length {
  }

  bool hasNext() {
    return _length > _pos;
  }

  final int _length;  // Cache list length for faster access.
}


// Iterator for lists with variable size.
class VariableSizeListIterator<T> implements Iterator<T> {
  VariableSizeListIterator(List<T> list)
      : _list = list,
        _pos = 0 {
  }

  bool hasNext() {
    return _list.length > _pos;
  }

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _list[_pos++];
  }

  final List<T> _list;
  int _pos;
}


class _ListJsUtil {
  static int _listLength(List list) native {
    return list.length;
  }

  static List _newList(int len) native {
    return new List(len);
  }

  static void _throwIndexOutOfRangeException(int index) native {
    throw new IndexOutOfRangeException(index);
  }
}
