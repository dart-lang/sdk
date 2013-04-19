// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _GrowableObjectArray<T> implements List<T> {
  factory _GrowableObjectArray._uninstantiable() {
    throw new UnsupportedError(
        "GrowableObjectArray can only be allocated by the VM");
  }

  void insert(int index, T element) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == this.length) {
      add(element);
      return;
    }
    int oldLength = this.length;
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this.length++;
    Arrays.copy(this,
                index,
                this,
                index + 1,
                oldLength - index);
    this[index] = element;
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

  void insertAll(int index, Iterable<T> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    // TODO(floitsch): we can probably detect more cases.
    if (iterable is! List && iterable is! Set && iterable is! SubListIterable) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    this.length += insertionLength;
    setRange(index + insertionLength, this.length, this, index);
    setAll(index, iterable);
  }

  void setAll(int index, Iterable<T> iterable) {
    if (iterable is List) {
      setRange(index, index + iterable.length, iterable);
    } else {
      for (T element in iterable) {
        this[index++] = element;
      }
    }
  }

  void removeWhere(bool test(T element)) {
    IterableMixinWorkaround.removeWhereList(this, test);
  }

  void retainWhere(bool test(T element)) {
    IterableMixinWorkaround.removeWhereList(this,
                                            (T element) => !test(element));
  }

  Iterable<T> getRange(int start, int end) {
    return IterableMixinWorkaround.getRangeList(this, start, end);
  }

  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    Arrays.indicesCheck(this, start, end);
    Arrays.copy(this,
                end,
                this,
                start,
                this.length - end);
    this.length = this.length - (end - start);
  }

  void replaceRange(int start, int end, Iterable<T> iterable) {
    IterableMixinWorkaround.replaceRangeList(this, start, end, iterable);
  }

  void fillRange(int start, int end, [T fillValue]) {
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }

  List<T> sublist(int start, [int end]) {
    Arrays.indicesCheck(this, start, end);
    if (end == null) end = length;
    int length = end - start;
    if (start == end) return <T>[];
    List list = new _GrowableObjectArray<T>.withCapacity(length);
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  factory _GrowableObjectArray(int length) {
    var data = new _ObjectArray((length == 0) ? 4 : length);
    var result = new _GrowableObjectArray<T>.withData(data);
    if (length > 0) {
      result._setLength(length);
    }
    return result;
  }

  factory _GrowableObjectArray.withCapacity(int capacity) {
    var data = new _ObjectArray((capacity == 0)? 4 : capacity);
    return new _GrowableObjectArray<T>.withData(data);
  }

  factory _GrowableObjectArray.from(Iterable<T> other) {
    List<T> result = new _GrowableObjectArray<T>();
    result.addAll(other);
    return result;
  }

  factory _GrowableObjectArray.withData(_ObjectArray data)
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

  void _setData(_ObjectArray array) native "GrowableObjectArray_setData";

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

  int indexOf(T element, [int start = 0]) {
    return IterableMixinWorkaround.indexOfList(this, element, start);
  }

  int lastIndexOf(T element, [int start = null]) {
    return IterableMixinWorkaround.lastIndexOfList(this, element, start);
  }

  void _grow(int new_length) {
    var new_data = new _ObjectArray(new_length);
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

  String join([String separator = ""]) {
    if (isEmpty) return "";
    if (this.length == 1) return "${this[0]}";
    StringBuffer buffer = new StringBuffer();
    if (separator.isEmpty) {
      for (int i = 0; i < this.length; i++) {
        buffer.write("${this[i]}");
      }
    } else {
      buffer.write("${this[0]}");
      for (int i = 1; i < this.length; i++) {
        buffer.write(separator);
        buffer.write("${this[i]}");
      }
    }
    return buffer.toString();
  }

  Iterable map(f(T element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  T reduce(T combine(T value, T element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  fold(initialValue, combine(previousValue, T element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  Iterable<T> where(bool f(T element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(T element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable<T> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<T> takeWhile(bool test(T value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<T> skip(int n) {
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

  T firstWhere(bool test(T value), {T orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  T lastWhere(bool test(T value), {T orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  T singleWhere(bool test(T value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
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

  Iterable<T> get reversed => IterableMixinWorkaround.reversedList(this);

  void sort([int compare(T a, T b)]) {
    IterableMixinWorkaround.sortList(this, compare);
  }

  String toString() {
    return ToString.iterableToString(this);
  }

  Iterator<T> get iterator {
    return new ListIterator<T>(this);
  }

  List<T> toList({ bool growable: true }) {
    return new List<T>.from(this, growable: growable);
  }

  Set<T> toSet() {
    return new Set<T>.from(this);
  }

  Map<int, T> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }
}
