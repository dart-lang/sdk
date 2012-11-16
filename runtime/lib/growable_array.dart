// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _GrowableObjectArray<T> implements List<T> {
  factory _GrowableObjectArray._uninstantiable() {
    throw new UnsupportedError(
        "GrowableObjectArray can only be allocated by the VM");
  }

  T removeAt(int index) {
    if (index is! int) throw new ArgumentError(index);
    T result = this[index];
    int newLength = this.length - 1;
    Arrays.copy(this,
                index + 1,
                this,
                index,
                newLength - index);
    this.length = newLength;
    return result;
  }

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new ArgumentError("negative length $length");
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
      throw new ArgumentError("invalid length specified $length");
    }
    if (start < 0 || start > this.length) {
      throw new RangeError.value(start);
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
    List list = new _GrowableObjectArray<T>.withCapacity(length);
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  factory _GrowableObjectArray() {
    var data = new _ObjectArray<T>(4);
    return new _GrowableObjectArray<T>.fromObjectArray(data);
  }

  factory _GrowableObjectArray.withCapacity(int capacity) {
    var data = new _ObjectArray<T>((capacity == 0)? 4 : capacity);
    return new _GrowableObjectArray<T>.fromObjectArray(data);
  }

  factory _GrowableObjectArray.from(Collection<T> other) {
    List<T> result = new _GrowableObjectArray<T>();
    result.addAll(other);
    return result;
  }

  factory _GrowableObjectArray.fromObjectArray(_ObjectArray<T> data)
    native "GrowableObjectArray_allocate";

  int get length native "GrowableObjectArray_getLength";

  int get capacity native "GrowableObjectArray_getCapacity";

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

  void _setData(_ObjectArray<T> array) native "GrowableObjectArray_setData";

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
    var elem = this[len];
    this[len] = null;
    _setLength(len);
    return elem;
  }

  T get first {
    return this[0];
  }

  T get last {
    return this[length - 1];
  }

  int indexOf(T element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, length);
  }

  int lastIndexOf(T element, [int start = null]) {
    if (start == null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void _grow(int new_length) {
    var new_data = new _ObjectArray<T>(new_length);
    for (int i = 0; i < length; i++) {
      new_data[i] = this[i];
    }
    _setData(new_data);
  }

  // Collection interface.

  bool contains(T element) => Collections.contains(this, element);

  void forEach(f(T element)) {
    // TODO(srdjan): Use Collections.forEach(this, f);
    // Accessing the list directly improves DeltaBlue performance by 25%.
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  Collection map(f(T element)) {
    return Collections.map(this,
                           new _GrowableObjectArray.withCapacity(length), f);
  }

  reduce(initialValue, combine(previousValue, T element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Collection<T> filter(bool f(T element)) {
    return Collections.filter(this, new _GrowableObjectArray<T>(), f);
  }

  bool every(bool f(T element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(T element)) {
    return Collections.some(this, f);
  }

  bool get isEmpty {
    return this.length == 0;
  }

  void clear() {
    this.length = 0;
  }

  void sort([Comparator<T> compare = Comparable.compare]) {
    _Sort.sort(this, compare);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  Iterator<T> iterator() {
    return new SequenceIterator<T>(this);
  }
}
