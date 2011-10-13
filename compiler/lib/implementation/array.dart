// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ArrayFactory {
  factory Array<E>.from(Iterable<E> other) {
    Array<E> array = new Array<E>();
    for (final e in other) {
      array.add(e);
    }
    return array;
  }

  factory Array<E>.fromArray(Array<E> other, int startIndex, int endIndex) {
    Array array = new Array<E>();
    if (endIndex > other.length) endIndex = other.length;
    if (startIndex < 0) startIndex = 0;
    int count = endIndex - startIndex;
    if (count > 0) {
      array.length = count;
      Arrays.copy(other, startIndex, array, 0, count);
    }
    return array;
  }

  factory Array<E>([int length = null]) {
    bool isFixed = true;
    if (length === null) {
      length = 0;
      isFixed = false;
    } else if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    // TODO(floitsch): make array creation more efficient. Currently we allocate
    // a new TypeToken at every allocation. Either we can optimize them away,
    // or we need to find other ways to pass type-information from Dart to JS.
    ObjectArray array = _new(new TypeToken<E>(), length);
    array._isFixed = isFixed;
    return array;
  }

  static ObjectArray _new(TypeToken typeToken, int length) native;
}


class ListFactory {
  factory List<E>.from(Iterable<E> other) {
    List<E> list = new List<E>();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  // TODO(bak): Until the final transition Array type is needed for other
  factory List<E>.fromList(Array<E> other, int startIndex, int endIndex) {
    List list = new List<E>();
    if (endIndex > other.length) endIndex = other.length;
    if (startIndex < 0) startIndex = 0;
    int count = endIndex - startIndex;
    if (count > 0) {
      list.length = count;
      Arrays.copy(other, startIndex, list, 0, count);
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
    // TODO(floitsch): make array creation more efficient. Currently we allocate
    // a new TypeToken at every allocation. Either we can optimize them away,
    // or we need to find other ways to pass type-information from Dart to JS.
    ObjectArray list = _new(new TypeToken<E>(), length);
    list._isFixed = isFixed;
    return list;
  }

  static ObjectArray _new(TypeToken typeToken, int length) native;
}


class ObjectArray<T> implements Array<T> native "Array" {
  // ObjectArray maps directly to a JavaScript array. If the array is
  // constructed by the ArrayFactory.Array constructor, it has an
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
      return new FixedSizeArrayIterator<T>(this);
    } else {
      return new VariableSizeArrayIterator<T>(this);
    }
  }

  T _indexOperator(int index) native;
  void _indexAssignOperator(int index, T value) native;
  int get length() native;
  void _setLength(int length) native;
  void _add(T value) native;
  void _splice(int start, int length) native;

  void forEach(void f(T element)) {
    Collections.forEach(this, f);
  }

  Collection<T> filter(bool f(T element)) {
    return Collections.filter(this, new Array<T>(), f);
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

  void copyFrom(Array<Object> src, int srcStart, int dstStart, int count) {
    Arrays.copy(src, srcStart, this, dstStart, count);
  }

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove range of a non-extendable array");
    }
    if (length == 0) {
      return;
    }
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    Arrays.copy(from, startFrom, this, start, length);
  }

  void removeRange(int start, int length) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove range of a non-extendable array");
    }
    if (length == 0) {
      return;
    }
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    if (start < 0 || start >= this.length) {
      throw new IndexOutOfRangeException(start);
    }
    if (start + length > this.length) {
      throw new IndexOutOfRangeException(start + length);
    }
    _splice(start, length);
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    throw const NotImplementedException();
  }

  List<T> getRange(int start, int length) {
    throw const NotImplementedException();
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
          "Cannot add to a non-extendable array");
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
          "Cannot add to a non-extendable array");
    } else {
      for (final e in elements) {
        _add(e);
      }
    }
  }

  void clear() {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot clear a non-extendable array");
    } else {
      length = 0;
    }
  }

  void set length(int length) {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot change the length of a non-extendable array");
    } else {
      _setLength(length);
    }
  }

  T removeLast() {
    if (_isFixed) {
      throw const UnsupportedOperationException(
          "Cannot remove in a non-extendable array");
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


// Iterator for arrays with fixed size.
class FixedSizeArrayIterator<T> extends VariableSizeArrayIterator<T> {
  FixedSizeArrayIterator(Array array)
      : super(array),
        _length = array.length {
  }

  bool hasNext() {
    return _length > _pos;
  }

  final int _length;  // Cache array length for faster access.
}


// Iterator for arrays with variable size.
class VariableSizeArrayIterator<T> implements Iterator<T> {
  VariableSizeArrayIterator(Array<T> array)
      : _array = array,
        _pos = 0 {
  }

  bool hasNext() {
    return _array.length > _pos;
  }

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final Array<T> _array;
  int _pos;
}


class _ArrayJsUtil {
  static int _arrayLength(Array array) native {
    return array.length;
  }

  static Array _newArray(int len) native {
    return new Array(len);
  }

  static void _throwIndexOutOfRangeException(int index) native {
    throw new IndexOutOfRangeException(index);
  }
}
