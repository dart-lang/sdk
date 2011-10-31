// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class GrowableObjectArray<T> implements List<T> {
  ObjectArray<T> backingArray;

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    Arrays.copy(src, srcStart, this, dstStart, count);
  }

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    Arrays.copy(from, startFrom, this, start, length);
  }

  void removeRange(int start, int length) {
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
    Arrays.copy(backingArray,
                start + length,
                backingArray,
                start,
                this.length - length - start);
    this.length = this.length - length;
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    if (length == 0) {
      return;
    }
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    if (start < 0 || start > this.length) {
      throw new IndexOutOfRangeException(start);
    }
    if (this.length + length >= backingArray.length) {
      grow(backingArray.length + length);
    }
    Arrays.copy(backingArray,
                start,
                backingArray,
                start + length,
                this.length - start);
    if (initialValue !== null) {
      for (int i = start; i < start + length; i++) {
        backingArray[i] = initialValue;
      }
    }
    this.length = this.length + length;
  }

  List<T> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new List<T>();
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  // The length of this growable array. It is always less than the
  // length of the backing array.
  int _length;
  // Constant used by indexOf and lastIndexOf when the element given
  // is not in the array.
  static final int ABSENT = -1;

  GrowableObjectArray()
      : _length = 0, backingArray = new ObjectArray<T>(4) {}

  GrowableObjectArray.withCapacity(int capacity) {
    _length = 0;
    if (capacity <= 0) {
      capacity = 4;
    }
    backingArray = new ObjectArray<T>(capacity);
  }

  GrowableObjectArray._usingArray(List<T> array) {
    backingArray = array;
    _length = array.length;
    if (_length == 0) {
      grow(4);
    }
  }

  factory GrowableObjectArray.from(Collection<T> other) {
    List result = new GrowableObjectArray();
    result.addAll(other);
    return result;
  }

  int get length() {
    return _length;
  }

  void set length(int new_length) {
    if (new_length >= backingArray.length) {
      grow(new_length);
    } else {
      for (int i = new_length; i < _length; i++) {
        backingArray[i] = null;
      }
    }
    _length = new_length;
  }

  T operator [](int index) {
    if (index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return backingArray[index];
  }

  void operator []=(int index, T value) {
    if (index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    backingArray[index] = value;
  }

  void grow(int capacity) {
    ObjectArray<T> newArray = new ObjectArray<T>(capacity);
    int length = backingArray.length;
    for (int i = 0; i < length; i++) {
      newArray[i] = backingArray[i];
    }
    backingArray = newArray;
  }

  int add(T value) {
    if (_length == backingArray.length) {
      grow(_length * 2);
    }
    backingArray[_length] = value;
    return ++_length;
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Collection<T> collection) {
    for (T elem in collection) {
      add(elem);
    }
  }

  T removeLast() {
    _length--;
    return backingArray[_length];
  }

  T last() {
    if (_length === 0) {
      throw new IndexOutOfRangeException(-1);
    }
    return backingArray[_length - 1];
  }

  int indexOf(T element, int startIndex) {
    return Arrays.indexOf(backingArray, element, startIndex, _length);
  }

  int lastIndexOf(T element, int startIndex) {
    return Arrays.lastIndexOf(backingArray, element, startIndex);
  }

  /**
   * Collection interface.
   */

  void forEach(f(T element)) {
    // TODO(srdjan): Use Collections.forEach(this, f);
    // Using backingArray directly improves DeltaBlue performance by 25%.
    for (int i = 0; i < _length; i++) {
      f(backingArray[i]);
    }
  }

  Collection<T> filter(bool f(T element)) {
    return Collections.filter(this, new GrowableObjectArray<T>(), f);
  }

  bool every(bool f(T element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(T element)) {
    return Collections.some(this, f);
  }

  bool isEmpty() {
    return this.length === 0;
  }

  void clear() {
    this.length = 0;
  }

  void sort(int compare(T a, T b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  Iterator<T> iterator() {
    return new VariableSizeArrayIterator<T>(this);
  }
}


// Iterator for arrays with variable size.
class VariableSizeArrayIterator<T> implements Iterator<T> {
  VariableSizeArrayIterator(GrowableObjectArray<T> array)
      : _array = array,  _pos = 0 {
  }

  bool hasNext() {
    return _array._length > _pos;
  }

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final GrowableObjectArray<T> _array;
  int _pos;
}

