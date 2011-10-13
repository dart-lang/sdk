// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ArrayFactory<T> {
  factory Array.from(Iterable<T> other) {
    GrowableObjectArray<T> array = new GrowableObjectArray<T>();
    for (final e in other) {
      array.add(e);
    }
    return array;
  }

  factory Array.fromArray(Array<T> other, int startIndex, int endIndex) {
    Array array = new Array<T>();
    if (endIndex > other.length) endIndex = other.length;
    if (startIndex < 0) startIndex = 0;
    int count = endIndex - startIndex;
    if (count > 0) {
      array.length = count;
      Arrays.copy(other, startIndex, array, 0, count);
    }
    return array;
  }

  factory Array([int length = null]) {
    if (length === null) {
      return new GrowableObjectArray<T>();
    } else {
      return new ObjectArray<T>(length);
    }
  }
}

class ListFactory<T> {

  factory List.from(Iterable<T> other) {
    GrowableObjectArray<T> list = new GrowableObjectArray<T>();
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  factory List.fromList(List<T> other, int startIndex, int endIndex) {
    List list = new List<T>();
    if (endIndex > other.length) endIndex = other.length;
    if (startIndex < 0) startIndex = 0;
    int count = endIndex - startIndex;
    if (count > 0) {
      list.length = count;
      Arrays.copy(other, startIndex, list, 0, count);
    }
    return list;
  }

  factory List([int length = null]) {
    if (length === null) {
      return new GrowableObjectArray<T>();
    } else {
      return new ObjectArray<T>(length);
    }
  }
}

// TODO(srdjan): Use shared array implementation.
class ObjectArray<T> implements Array<T> {

  factory ObjectArray(int length) native "ObjectArray_allocate";

  T operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, T value) native "ObjectArray_setIndexed";

  String toString() {
    return Arrays.asString(this);
  }

  int get length() native "ObjectArray_getLength";

  void copyFrom(Array src, int srcStart, int dstStart, int count) {
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

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    copyFrom(from, start, startFrom, count);
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove range of a non-extendable array");
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    throw const NotImplementedException();
  }

  List<T> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    return new List<T>.fromList(this, start, start + length);
  }

  /**
   * Collection interface.
   */

  void forEach(f(T element)) {
    Collections.forEach(this, f);
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

  void sort(int compare(T a, T b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  int indexOf(T element, int startIndex) {
    return Arrays.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(T element, int startIndex) {
    return Arrays.lastIndexOf(this, element, startIndex);
  }

  Iterator<T> iterator() {
    return new FixedSizeArrayIterator<T>(this);
  }

  void add(T element) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Collection<T> elements) {
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

  T removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove in a non-extendable array");
  }

  T last() {
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
class ImmutableArray<T> implements Array<T> {

  T operator [](int index) native "ObjectArray_getIndexed";

  void operator []=(int index, T value) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  int get length() native "ObjectArray_getLength";

  void copyFrom(Array src, int srcStart, int dstStart, int count) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  void setRange(int start, int length, List<T> from, [int startFrom = 0]) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove range of an immutable array");
  }

  void insertRange(int start, int length, [T initialValue = null]) {
    throw const NotImplementedException();
  }

  List<T> getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    return new List<T>.fromList(this, start, start + length);
  }

  /**
   * Collection interface.
   */

  void forEach(f(T element)) {
    Collections.forEach(this, f);
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

  void sort(int compare(T a, T b)) {
    throw const UnsupportedOperationException(
        "Cannot modify an immutable array");
  }

  String toString() {
    return "ImmutableArray";
  }

  int indexOf(T element, int startIndex) {
    return Arrays.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(T element, int startIndex) {
    return Arrays.lastIndexOf(this, element, startIndex);
  }

  Iterator<T> iterator() {
    return new FixedSizeArrayIterator<T>(this);
  }

  void add(T element) {
    throw const UnsupportedOperationException(
        "Cannot add to an immutable array");
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Collection<T> elements) {
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

  T removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove in a non-extendable array");
  }

  T last() {
    return this[length - 1];
  }
}


// Iterator for arrays with fixed size.
class FixedSizeArrayIterator<T> implements Iterator<T> {
  FixedSizeArrayIterator(Array array)
      : _array = array, _length = array.length, _pos = 0 {
    assert(array is ObjectArray || array is ImmutableArray);
  }

  bool hasNext() {
   return _length > _pos;
  }

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final Array<T> _array;
  final int _length;  // Cache array length for faster access.
  int _pos;
}
