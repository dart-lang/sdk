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

  void remove(Object element) {
    checkGrowable(this, 'remove');
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        JS('var', r'#.splice(#, 1)', this, i);
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
    // This could, and should, be optimized.
    IterableMixinWorkaround.removeMatchingList(this, test);
  }

  void retainMatching(bool test(E element)) {
    IterableMixinWorkaround.removeMatchingList(this,
                                               (E element) => !test(element));
  }

  Iterable<E> where(bool f(E element)) {
    return IterableMixinWorkaround.where(this, f);
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
    return IterableMixinWorkaround.forEach(this, f);
  }

  List mappedBy(f(E element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  String join([String separator]) {
    if (separator == null) separator = "";
    var list = new List(this.length);
    for (int i = 0; i < this.length; i++) {
      list[i] = "${this[i]}";
    }
    return JS('String', "#.join(#)", list, separator);
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

  reduce(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
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
    checkMutable(this, 'set range');
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

  bool any(bool f(E element)) => IterableMixinWorkaround.any(this, f);

  bool every(bool f(E element)) => IterableMixinWorkaround.every(this, f);

  List<E> get reversed => new ReversedListView<E>(this, 0, null);

  void sort([int compare(E a, E b)]) {
    checkMutable(this, 'sort');
    IterableMixinWorkaround.sortList(this, compare);
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

  List<E> toList() => new List<E>.from(this);

  Set<E> toSet() => new Set<E>.from(this);

  Iterator<E> get iterator => new ListIterator<E>(this);

  int get hashCode => Primitives.objectHashCode(this);

  Type get runtimeType {
    // Call getRuntimeTypeString to get the name including type arguments.
    return new TypeImpl(getRuntimeTypeString(this));
  }

  int get length => JS('int', r'#.length', this);

  void set length(int newLength) {
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new RangeError.value(newLength);
    checkGrowable(this, 'set length');
    JS('void', r'#.length = #', this, newLength);
  }

  E operator [](int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    return JS('var', '#[#]', this, index);
  }

  void operator []=(int index, E value) {
    checkMutable(this, 'indexed set');
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    JS('void', r'#[#] = #', this, index, value);
  }
}
