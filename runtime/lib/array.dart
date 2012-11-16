// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(srdjan): Use shared array implementation.
class _ObjectArray<E> implements List<E> {

  factory _ObjectArray(int length) native "ObjectArray_allocate";

  E operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, E value) native "ObjectArray_setIndexed";

  String toString() {
    return Collections.collectionToString(this);
  }

  int get length native "ObjectArray_getLength";

  void _copyFromObjectArray(_ObjectArray src,
                            int srcStart,
                            int dstStart,
                            int count)
      native "ObjectArray_copyFromObjectArray";

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove element of a non-extendable array");
  }

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new ArgumentError("negative length $length");
    }
      if (from is _ObjectArray) {
      _copyFromObjectArray(from, startFrom, start, length);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove range of a non-extendable array");
  }

  void insertRange(int start, int length, [E initialValue = null]) {
    throw new UnsupportedError(
        "Cannot insert range in a non-extendable array");
  }

  List<E> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new _GrowableObjectArray<E>.withCapacity(length);
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  // Collection interface.

  bool contains(E element) => Collections.contains(this, element);

  void forEach(f(E element)) {
    Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(
        this, new _GrowableObjectArray.withCapacity(length), f);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Collection<E> filter(bool f(E element)) {
    return Collections.filter(this, new _GrowableObjectArray<E>(), f);
  }

  bool every(bool f(E element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(E element)) {
    return Collections.some(this, f);
  }

  bool get isEmpty {
    return this.length == 0;
  }

  void sort([Comparator<E> compare = Comparable.compare]) {
    _Sort.sort(this, compare);
  }

  int indexOf(E element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(E element, [int start = null]) {
    if (start == null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  Iterator<E> iterator() {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Collection<E> elements) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear a non-extendable array");
  }

  void set length(int length) {
    throw new UnsupportedError(
        "Cannot change the length of a non-extendable array");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove in a non-extendable array");
  }

  E get first {
    return this[0];
  }

  E get last {
    return this[length - 1];
  }
}


// This is essentially the same class as _ObjectArray, but it does not
// permit any modification of array elements from Dart code. We use
// this class for arrays constructed from Dart array literals.
// TODO(hausner): We should consider the trade-offs between two
// classes (and inline cache misses) versus a field in the native
// implementation (checks when modifying). We should keep watching
// the inline cache misses.
class _ImmutableArray<E> implements List<E> {

  factory _ImmutableArray._uninstantiable() {
    throw new UnsupportedError(
        "ImmutableArray can only be allocated by the VM");
  }

  E operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, E value) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  int get length native "ObjectArray_getLength";

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void copyFrom(List src, int srcStart, int dstStart, int count) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove range of an immutable array");
  }

  void insertRange(int start, int length, [E initialValue = null]) {
    throw new UnsupportedError(
        "Cannot insert range in an immutable array");
  }

  List<E> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new List<E>();
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  // Collection interface.

  bool contains(E element) => Collections.contains(this, element);

  void forEach(f(E element)) {
    Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(
        this, new _GrowableObjectArray.withCapacity(length), f);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Collection<E> filter(bool f(E element)) {
    return Collections.filter(this, new _GrowableObjectArray<E>(), f);
  }

  bool every(bool f(E element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(E element)) {
    return Collections.some(this, f);
  }

  bool get isEmpty {
    return this.length == 0;
  }

  void sort([Comparator<E> compare]) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int indexOf(E element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(E element, [int start = null]) {
    if (start == null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  Iterator<E> iterator() {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw new UnsupportedError(
        "Cannot add to an immutable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Collection<E> elements) {
    throw new UnsupportedError(
        "Cannot add to an immutable array");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear an immutable array");
  }

  void set length(int length) {
    throw new UnsupportedError(
        "Cannot change the length of an immutable array");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove in a non-extendable array");
  }

  E get first {
    return this[0];
  }

  E get last {
    return this[length - 1];
  }
}


// Iterator for arrays with fixed size.
class _FixedSizeArrayIterator<E> implements Iterator<E> {
  _FixedSizeArrayIterator(List array)
      : _array = array, _length = array.length, _pos = 0 {
    assert(array is _ObjectArray || array is _ImmutableArray);
  }

  bool get hasNext {
    return _length > _pos;
  }

  E next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }
    return _array[_pos++];
  }

  final List<E> _array;
  final int _length;  // Cache array length for faster access.
  int _pos;
}
