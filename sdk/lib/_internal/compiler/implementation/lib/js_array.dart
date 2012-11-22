// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/**
 * The interceptor class for [List]. The compiler recognizes this
 * class as an interceptor, and changes references to [:this:] to
 * actually use the receiver of the method, which is generated as an extra
 * argument added to each member.
 */
class JSArray<E> implements List<E> {
  const JSArray();

  void add(E value) {
    checkGrowable(this, 'add');
    JS('void', r'#.push(#)', this, value);
  }

  E removeAt(int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index >= length) {
      throw new RangeError.value(index);
    }
    checkGrowable(this, 'removeAt');
    return JS('var', r'#.splice(#, 1)[0]', this, index);
  }

  E removeLast() {
    checkGrowable(this, 'removeLast');
    if (length == 0) throw new RangeError.value(-1);
    return JS('var', r'#.pop()', this);
  }

  List<E> filter(bool f(E element)) {
    return Collections.filter(this, <E>[], f);
  }

  void addAll(Collection<E> collection) {
    for (E e in collection) {
      this.add(e);
    }
  }

  void addLast(E value) {
    checkGrowable(this, 'addLast');
    JS('void', r'#.push(#)', this, value);
  }

  void clear() {
    length = 0;
  }

  void forEach(void f(E element)) {
    return Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(this, [], f);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  List<E> getRange(int start, int length) {
    // TODO(ngeoffray): Parameterize the return value.
    if (0 == length) return [];
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (length is !int) throw new ArgumentError(length);
    if (length < 0) throw new ArgumentError(length);
    if (start < 0) throw new RangeError.value(start);
    int end = start + length;
    if (end > this.length) {
      throw new RangeError.value(length);
    }
    if (length < 0) throw new ArgumentError(length);
    return JS('=List', r'#.slice(#, #)', this, start, end);
  }

  void insertRange(int start, int length, [E initialValue]) {
    return listInsertRange(this, start, length, initialValue);
  }

  E get last => this[length - 1];

  E get first => this[0];

  void removeRange(int start, int length) {
    checkGrowable(this, 'removeRange');
    if (length == 0) {
      return;
    }
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (length is !int) throw new ArgumentError(length);
    if (length < 0) throw new ArgumentError(length);
    var receiverLength = this.length;
    if (start < 0 || start >= receiverLength) {
      throw new RangeError.value(start);
    }
    if (start + length > receiverLength) {
      throw new RangeError.value(start + length);
    }
    Arrays.copy(this,
                start + length,
                this,
                start,
                receiverLength - length - start);
    this.length = receiverLength - length;
  }

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    checkMutable(this, 'indexed set');
    if (length == 0) return;
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(from); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(startFrom); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (length is !int) throw new ArgumentError(length);
    if (startFrom is !int) throw new ArgumentError(startFrom);
    if (length < 0) throw new ArgumentError(length);
    if (start < 0) throw new RangeError.value(start);
    if (start + length > this.length) {
      throw new RangeError.value(start + length);
    }

    Arrays.copy(from, startFrom, this, start, length);
  }

  bool some(bool f(E element)) => Collections.some(this, f);

  bool every(bool f(E element)) => Collections.every(this, f);

  void sort([Comparator<E> compare = Comparable.compare]) {
    checkMutable(this, 'sort');
    coreSort(this, compare);
  }

  int indexOf(E element, [int start = 0]) {
    if (start is !int) throw new ArgumentError(start);
    return Arrays.indexOf(this, element, start, length);
  }

  int lastIndexOf(E element, [int start]) {
    if (start == null) start = this.length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  bool contains(E other) {
    for (int i = 0; i < length; i++) {
      if (other == this[i]) return true;
    }
    return false;
  }

  bool get isEmpty => length == 0;

  String toString() => Collections.collectionToString(this);

  ListIterator iterator() => new ListIterator(this);

  int get hashCode => Primitives.objectHashCode(this);

  Type get runtimeType => List;

  int get length => JS('int', r'#.length', this);
  
  void set length(int newLength) {
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new RangeError.value(newLength);
    checkGrowable(this, 'set length');
    JS('void', r'#.length = #', this, newLength);
  }
}
