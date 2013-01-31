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

  void remove(Object element) {
    throw new UnsupportedError(
        "Cannot remove element of a non-extendable array");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove element of a non-extendable array");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove element of a non-extendable array");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove element of a non-extendable array");
  }

  void retainMatching(bool test(E element)) {
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

  bool contains(E element) {
    return IterableMixinWorkaround.contains(this, element);
  }

  void forEach(f(E element)) {
    IterableMixinWorkaround.forEach(this, f);
  }

  String join([String separator]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  List mappedBy(f(E element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  Iterable<E> where(bool f(E element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  List<E> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<E> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(E element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(E element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  E firstMatching(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  E lastMatching(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  E singleMatching(bool test(E value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  List<E> get reversed => new ReversedListView<E>(this, 0, null);

  void sort([int compare(E a, E b)]) {
    IterableMixinWorkaround.sortList(this, compare);
  }

  int indexOf(E element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(E element, [int start = null]) {
    if (start == null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Iterable<E> iterable) {
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
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  E min([int compare(E a, E b)]) => IterableMixinWorkaround.min(this, compare);

  E max([int compare(E a, E b)]) => IterableMixinWorkaround.max(this, compare);

  List<E> toList() {
    return new List<E>.from(this);
  }

  Set<E> toSet() {
    return new Set<E>.from(this);
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

  void remove(Object element) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot modify an immutable array");
  }

  void retainMatching(bool test(E element)) {
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

  bool contains(E element) {
    return IterableMixinWorkaround.contains(this, element);
  }

  void forEach(f(E element)) {
    IterableMixinWorkaround.forEach(this, f);
  }

  List mappedBy(f(E element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  String join([String separator]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  Iterable<E> where(bool f(E element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  List<E> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<E> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(E element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(E element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  E firstMatching(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  E lastMatching(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  E singleMatching(bool test(E value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  List<E> get reversed => new ReversedListView<E>(this, 0, null);

  void sort([int compare(E a, E b)]) {
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

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw new UnsupportedError(
        "Cannot add to an immutable array");
  }

  void addLast(E element) {
    add(element);
  }

  void addAll(Iterable<E> elements) {
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
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  E min([int compare(E a, E b)]) => IterableMixinWorkaround.min(this, compare);

  E max([int compare(E a, E b)]) => IterableMixinWorkaround.max(this, compare);

  List<E> toList() {
    return new List<E>.from(this);
  }

  Set<E> toSet() {
    return new Set<E>.from(this);
  }
}


// Iterator for arrays with fixed size.
class _FixedSizeArrayIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;  // Cache array length for faster access.
  int _position;
  E _current;

  _FixedSizeArrayIterator(List array)
      : _array = array, _length = array.length, _position = -1 {
    assert(array is _ObjectArray || array is _ImmutableArray);
  }

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _length;
    _current = null;
    return false;
  }

  E get current {
    return _current;
  }
}
