// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class GrowableObjectArray<T> implements List<T> {
  factory GrowableObjectArray._uninstantiable() {
    throw const UnsupportedOperationException(
        "GrowableObjectArray can only be allocated by the VM");
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
    Arrays.rangeCheck(this, start, length);
    Arrays.copy(this,
                start + length,
                this,
                start,
                this.length - length - start);
    this.length = this.length - length;
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    if (length == 0) {
      return;
    }
    if ((length < 0) || (length is! int)) {
      throw new IllegalArgumentException("invalid length specified $length");
    }
    if (start < 0 || start > this.length) {
      throw new IndexOutOfRangeException(start);
    }
    var old_length = this.length;
    this.length = old_length + length;  // Will expand if needed.
    Arrays.copy(this,
                start,
                this,
                start + length,
                old_length - start);
    for (int i = start; i < start + length; i++) {
      this[i] = initialValue;
    }
  }

  List<T> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new List<T>();
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  factory GrowableObjectArray() {
    var data = new ObjectArray<T>(4);
    return new GrowableObjectArray<T>.fromObjectArray(data);
  }

  factory GrowableObjectArray.withCapacity(int capacity) {
    var data = new ObjectArray<T>((capacity == 0)? 4 : capacity);
    return new GrowableObjectArray<T>.fromObjectArray(data);
  }

  factory GrowableObjectArray.from(Collection<T> other) {
    List<T> result = new GrowableObjectArray<T>();
    result.addAll(other);
    return result;
  }

  factory GrowableObjectArray.fromObjectArray(ObjectArray<T> data)
    native "GrowableObjectArray_allocate";

  int get length() native "GrowableObjectArray_getLength";

  int get capacity() native "GrowableObjectArray_getCapacity";

  void set length(int new_length) {
    if (new_length > capacity) {
      _grow(new_length);
    } else {
      for (int i = new_length; i < length; i++) {
        this[i] = null;
      }
    }
    _setLength(new_length);
  }

  void _setLength(int new_length) native "GrowableObjectArray_setLength";

  void set data(ObjectArray<T> array) native "GrowableObjectArray_setData";

  T operator [](int index) native "GrowableObjectArray_getIndexed";

  void operator []=(int index, T value) native "GrowableObjectArray_setIndexed";

  // The length of this growable array. It is always less than or equal to the
  // length of the object array, which itself is always greater than 0, so that
  // grow() does not have to check for a zero length object array before
  // doubling its size.
  void add(T value) {
    var len = length;
    if (len == capacity) {
      _grow(len * 2);
    }
    _setLength(len + 1);
    this[len] = value;
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
    var len = length - 1;
    if (len < 0) {
      throw new IndexOutOfRangeException(-1);
    }
    var elem = this[len];
    this[len] = null;
    _setLength(len);
    return elem;
  }

  T last() {
    if (length === 0) {
      throw new IndexOutOfRangeException(-1);
    }
    return this[length - 1];
  }

  int indexOf(T element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, length);
  }

  int lastIndexOf(T element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void _grow(int new_length) {
    var new_data = new ObjectArray<T>(new_length);
    for (int i = 0; i < length; i++) {
      new_data[i] = this[i];
    }
    data = new_data;
  }

  /**
   * Collection interface.
   */

  void forEach(f(T element)) {
    // TODO(srdjan): Use Collections.forEach(this, f);
    // Accessing the list directly improves DeltaBlue performance by 25%.
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  Collection map(f(T element)) {
    return Collections.map(this,
                           new GrowableObjectArray.withCapacity(length), f);
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, T element)) {
    return Collections.reduce(this, initialValue, combine);
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

  String toString() {
    return Collections.collectionToString(this);
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
    return _array.length > _pos;
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
