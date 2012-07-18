// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListFactory<E> {

  factory List.from(Iterable<E> other) {
    GrowableObjectArray<E> list = new GrowableObjectArray<E>();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  factory List([int length = null]) {
    if (length === null) {
      return new GrowableObjectArray<E>();
    } else {
      return new ObjectArray<E>(length);
    }
  }
}

// TODO(srdjan): Use shared array implementation.
class ObjectArray<E> implements List<E> {

  factory ObjectArray(int length) native "ObjectArray_allocate";

  E operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, E value) native "ObjectArray_setIndexed";

  String toString() {
    return Collections.collectionToString(this);
  }

  int get length() native "ObjectArray_getLength";

  void copyFrom(List src, int srcStart, int dstStart, int count) {
    if (src is ObjectArray) {
      _copyFromObjectArray(src, srcStart, dstStart, count);
    } else {
      Arrays.copy(src, srcStart, this, dstStart, count);
    }
  }

  void _copyFromObjectArray(ObjectArray src,
                            int srcStart,
                            int dstStart,
                            int count)
      native "ObjectArray_copyFromObjectArray";

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    copyFrom(from, startFrom, start, length);
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove range of a non-extendable array");
  }

  void insertRange(int start, int length, [E initialValue = null]) {
    throw const UnsupportedOperationException(
        "Cannot insert range in a non-extendable array");
  }

  List<E> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    List list = new List<E>();
    list.length = length;
    Arrays.copy(this, start, list, 0, length);
    return list;
  }

  /**
   * Collection interface.
   */

  void forEach(f(E element)) {
    Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(this, new GrowableObjectArray.withCapacity(length), f);
  }

  Collection<E> filter(bool f(E element)) {
    return Collections.filter(this, new GrowableObjectArray<E>(), f);
  }

  bool every(bool f(E element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(E element)) {
    return Collections.some(this, f);
  }

  bool isEmpty() {
    return this.length === 0;
  }

  void sort(int compare(E a, E b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  int indexOf(E element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(E element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  Iterator<E> iterator() {
    return new FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Collection<E> elements) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot clear a non-extendable array");
  }

  void set length(int length) {
    throw const UnsupportedOperationException(
        "Cannot change the length of a non-extendable array");
  }

  E removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove in a non-extendable array");
  }

  E last() {
    return this[length - 1];
  }
}


// This is essentially the same class as ObjectArray, but it does not
// permit any modification of array elements from Dart code. We use
// this class for arrays constructed from Dart array literals.
// TODO(hausner): We should consider the trade-offs between two
// classes (and inline cache misses) versus a field in the native
// implementation (checks when modifying). We should keep watching
// the inline cache misses.
class ImmutableArray<E> implements List<E> {

  factory ImmutableArray._uninstantiable() {
    throw const UnsupportedOperationException(
        "ImmutableArray can only be allocated by the VM");
  }

  E operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, E value) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  int get length() native "ObjectArray_getLength";

  void copyFrom(List src, int srcStart, int dstStart, int count) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove range of an immutable array");
  }

  void insertRange(int start, int length, [E initialValue = null]) {
    throw const UnsupportedOperationException(
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

  /**
   * Collection interface.
   */

  void forEach(f(E element)) {
    Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(this, new GrowableObjectArray.withCapacity(length), f);
  }

  Collection<E> filter(bool f(E element)) {
    return Collections.filter(this, new GrowableObjectArray<E>(), f);
  }

  bool every(bool f(E element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(E element)) {
    return Collections.some(this, f);
  }

  bool isEmpty() {
    return this.length === 0;
  }

  void sort(int compare(E a, E b)) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int indexOf(E element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(E element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  Iterator<E> iterator() {
    return new FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw const UnsupportedOperationException(
        "Cannot add to an immutable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Collection<E> elements) {
    throw const UnsupportedOperationException(
        "Cannot add to an immutable array");
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot clear an immutable array");
  }

  void set length(int length) {
    throw const UnsupportedOperationException(
        "Cannot change the length of an immutable array");
  }

  E removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove in a non-extendable array");
  }

  E last() {
    return this[length - 1];
  }
}


// Iterator for arrays with fixed size.
class FixedSizeArrayIterator<E> implements Iterator<E> {
  FixedSizeArrayIterator(List array)
      : _array = array, _length = array.length, _pos = 0 {
    assert(array is ObjectArray || array is ImmutableArray);
  }

  bool hasNext() {
    return _length > _pos;
  }

  E next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final List<E> _array;
  final int _length;  // Cache array length for faster access.
  int _pos;
}
