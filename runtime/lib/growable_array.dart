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

  void remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeAt(i);
        return;
      }
    }
  }

  void removeAll(Iterable elements) {
    IterableMixinWorkaround.removeAllList(this, elements);
  }

  void retainAll(Iterable elements) {
    IterableMixinWorkaround.retainAll(this, elements);
  }

  void removeMatching(bool test(E element)) {
    IterableMixinWorkaround.removeMatchingList(this, test);
  }

  void retainMatching(bool test(T element)) {
    IterableMixinWorkaround.removeMatchingList(this,
                                               (T element) => !test(element));
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

  factory _GrowableObjectArray(int length) {
    var data = new _ObjectArray<T>((length == 0) ? 4 : length);
    var result = new _GrowableObjectArray<T>.withData(data);
    result._setLength(length);
    return result;
  }

  factory _GrowableObjectArray.withCapacity(int capacity) {
    var data = new _ObjectArray<T>((capacity == 0)? 4 : capacity);
    return new _GrowableObjectArray<T>.withData(data);
  }

  factory _GrowableObjectArray.from(Collection<T> other) {
    List<T> result = new _GrowableObjectArray<T>();
    result.addAll(other);
    return result;
  }

  factory _GrowableObjectArray.withData(_ObjectArray<T> data)
    native "GrowableObjectArray_allocate";

  int get length native "GrowableObjectArray_getLength";

  int get _capacity native "GrowableObjectArray_getCapacity";

  void set length(int new_length) {
    if (new_length > _capacity) {
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
    if (len == _capacity) {
      _grow(len * 2);
    }
    _setLength(len + 1);
    this[len] = value;
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Iterable<T> iterable) {
    for (T elem in iterable) {
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
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  T get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  T get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  T min([int compare(T a, T b)]) => IterableMixinWorkaround.min(this, compare);

  T max([int compare(T a, T b)]) => IterableMixinWorkaround.max(this, compare);

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

  bool contains(T element) {
    return IterableMixinWorkaround.contains(this, element);
  }

  void forEach(f(T element)) {
    // TODO(srdjan): Use IterableMixinWorkaround.forEach(this, f);
    // Accessing the list directly improves DeltaBlue performance by 25%.
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  String join([String separator]) {
    if (isEmpty) return "";
    if (this.length == 1) return "${this[0]}";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      for (int i = 0; i < this.length; i++) {
        buffer.add("${this[i]}");
      }
    } else {
      buffer.add("${this[0]}");
      for (int i = 1; i < this.length; i++) {
        buffer.add(separator);
        buffer.add("${this[i]}");
      }
    }
    return buffer.toString();
  }

  List mappedBy(f(T element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  reduce(initialValue, combine(previousValue, T element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  Iterable<T> where(bool f(T element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  List<T> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<T> takeWhile(bool test(T value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<T> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<T> skipWhile(bool test(T value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(T element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(T element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  T firstMatching(bool test(T value), {T orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  T lastMatching(bool test(T value), {T orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  T singleMatching(bool test(T value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  T elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  void clear() {
    this.length = 0;
  }

  List<T> get reversed => new ReversedListView<T>(this, 0, null);

  void sort([int compare(T a, T b)]) {
    IterableMixinWorkaround.sortList(this, compare);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  Iterator<T> get iterator {
    return new ListIterator<T>(this);
  }

  List<T> toList() {
    return new List<T>.from(this);
  }

  Set<T> toSet() {
    return new Set<T>.from(this);
  }
}
