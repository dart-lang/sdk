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
class JSArray<E> extends Interceptor implements List<E>, JSIndexable {

  const JSArray();

  /**
   * Returns a fresh JavaScript Array, marked as fixed-length.
   *
   * [length] must be a non-negative integer.
   */
  factory JSArray.fixed(int length)  {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode.
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError("Length must be a non-negative integer: $length");
    }
    return new JSArray<E>.markFixed(JS('', 'new Array(#)', length));
  }

  /**
   * Returns a fresh growable JavaScript Array of zero length length.
   */
  factory JSArray.emptyGrowable() => new JSArray<E>.markGrowable(JS('', '[]'));

  /**
   * Returns a fresh growable JavaScript Array with initial length.
   *
   * [validatedLength] must be a non-negative integer.
   */
  factory JSArray.growable(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode.
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError("Length must be a non-negative integer: $length");
    }
    return new JSArray<E>.markGrowable(JS('', 'new Array(#)', length));
  }

  /**
   * Constructor for adding type parameters to an existing JavaScript Array.
   * The compiler specially recognizes this constructor.
   *
   *     var a = new JSArray<int>.typed(JS('JSExtendableArray', '[]'));
   *     a is List<int>    --> true
   *     a is List<String> --> false
   *
   * Usually either the [JSArray.markFixed] or [JSArray.markGrowable]
   * constructors is used instead.
   *
   * The input must be a JavaScript Array.  The JS form is just a re-assertion
   * to help type analysis when the input type is sloppy.
   */
  factory JSArray.typed(allocation) => JS('JSArray', '#', allocation);

  factory JSArray.markFixed(allocation) =>
      JS('JSFixedArray', '#', markFixedList(new JSArray<E>.typed(allocation)));

  factory JSArray.markGrowable(allocation) =>
      JS('JSExtendableArray', '#', new JSArray<E>.typed(allocation));

  static List markFixedList(List list) {
    JS('void', r'#.fixed$length = init', list);
    return JS('JSFixedArray', '#', list);
  }

  checkMutable(reason) {
    if (this is !JSMutableArray) {
      throw new UnsupportedError(reason);
    }
  }

  checkGrowable(reason) {
    if (this is !JSExtendableArray) {
      throw new UnsupportedError(reason);
    }
  }

  void add(E value) {
    checkGrowable('add');
    JS('void', r'#.push(#)', this, value);
  }

  E removeAt(int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index >= length) {
      throw new RangeError.value(index);
    }
    checkGrowable('removeAt');
    return JS('var', r'#.splice(#, 1)[0]', this, index);
  }

  void insert(int index, E value) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index > length) {
      throw new RangeError.value(index);
    }
    checkGrowable('insert');
    JS('void', r'#.splice(#, 0, #)', this, index, value);
  }

  void insertAll(int index, Iterable<E> iterable) {
    checkGrowable('insertAll');
    IterableMixinWorkaround.insertAllList(this, index, iterable);
  }

  void setAll(int index, Iterable<E> iterable) {
    checkMutable('setAll');
    IterableMixinWorkaround.setAllList(this, index, iterable);
  }

  E removeLast() {
    checkGrowable('removeLast');
    if (length == 0) throw new RangeError.value(-1);
    return JS('var', r'#.pop()', this);
  }

  bool remove(Object element) {
    checkGrowable('remove');
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        JS('var', r'#.splice(#, 1)', this, i);
        return true;
      }
    }
    return false;
  }

  void removeWhere(bool test(E element)) {
    // This could, and should, be optimized.
    IterableMixinWorkaround.removeWhereList(this, test);
  }

  void retainWhere(bool test(E element)) {
    IterableMixinWorkaround.removeWhereList(this,
                                            (E element) => !test(element));
  }

  Iterable<E> where(bool f(E element)) {
    return new IterableMixinWorkaround<E>().where(this, f);
  }

  Iterable expand(Iterable f(E element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  void addAll(Iterable<E> collection) {
    for (E e in collection) {
      this.add(e);
    }
  }

  void clear() {
    length = 0;
  }

  void forEach(void f(E element)) {
    int getLength() => JS('int', '#.length', this);
    int length = getLength();
    for (int i = 0; i < length; i++) {
      f(JS('', '#[#]', this, i));
      if (length != getLength()) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  Iterable map(f(E element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator = ""]) {
    var list = new List(this.length);
    for (int i = 0; i < this.length; i++) {
      list[i] = "${this[i]}";
    }
    return JS('String', "#.join(#)", list, separator);
  }

  Iterable<E> take(int n) {
    return new IterableMixinWorkaround<E>().takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new IterableMixinWorkaround<E>().takeWhile(this, test);
  }

  Iterable<E> skip(int n) {
    return new IterableMixinWorkaround<E>().skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new IterableMixinWorkaround<E>().skipWhile(this, test);
  }

  E reduce(E combine(E value, E element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  fold(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  dynamic firstWhere(bool test(E value), {Object orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  dynamic lastWhere(bool test(E value), {Object orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  E singleWhere(bool test(E value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  List<E> sublist(int start, [int end]) {
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (start < 0 || start > length) {
      throw new RangeError.range(start, 0, length);
    }
    if (end == null) {
      end = length;
    } else {
      if (end is !int) throw new ArgumentError(end);
      if (end < start || end > length) {
        throw new RangeError.range(end, start, length);
      }
    }
    if (start == end) return <E>[];
    return new JSArray<E>.markGrowable(
        JS('', r'#.slice(#, #)', this, start, end));
  }


  Iterable<E> getRange(int start, int end) {
    return new IterableMixinWorkaround<E>().getRangeList(this, start, end);
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

  void removeRange(int start, int end) {
    checkGrowable('removeRange');
    int receiverLength = this.length;
    if (start < 0 || start > receiverLength) {
      throw new RangeError.range(start, 0, receiverLength);
    }
    if (end < start || end > receiverLength) {
      throw new RangeError.range(end, start, receiverLength);
    }
    Lists.copy(this,
               end,
               this,
               start,
               receiverLength - end);
    this.length = receiverLength - (end - start);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    checkMutable('set range');
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void fillRange(int start, int end, [E fillValue]) {
    checkMutable('fill range');
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    checkGrowable('removeRange');
    IterableMixinWorkaround.replaceRangeList(this, start, end, iterable);
  }

  bool any(bool f(E element)) => IterableMixinWorkaround.any(this, f);

  bool every(bool f(E element)) => IterableMixinWorkaround.every(this, f);

  Iterable<E> get reversed =>
      new IterableMixinWorkaround<E>().reversedList(this);

  void sort([int compare(E a, E b)]) {
    checkMutable('sort');
    IterableMixinWorkaround.sortList(this, compare);
  }

  void shuffle([Random random]) {
    IterableMixinWorkaround.shuffleList(this, random);
  }

  int indexOf(Object element, [int start = 0]) {
    return IterableMixinWorkaround.indexOfList(this, element, start);
  }

  int lastIndexOf(Object element, [int start]) {
    return IterableMixinWorkaround.lastIndexOfList(this, element, start);
  }

  bool contains(Object other) {
    for (int i = 0; i < length; i++) {
      if (this[i] == other) return true;
    }
    return false;
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => ListBase.listToString(this);

  List<E> toList({ bool growable: true }) {
    if (growable) {
      return new JSArray<E>.markGrowable(JS('', '#.slice()', this));
    } else {
      return new JSArray<E>.markFixed(JS('', '#.slice()', this));
    }
  }

  Set<E> toSet() => new Set<E>.from(this);

  Iterator<E> get iterator => new ListIterator<E>(this);

  int get hashCode => Primitives.objectHashCode(this);

  int get length => JS('JSUInt32', r'#.length', this);

  void set length(int newLength) {
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new RangeError.value(newLength);
    checkGrowable('set length');
    JS('void', r'#.length = #', this, newLength);
  }

  E operator [](int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    return JS('var', '#[#]', this, index);
  }

  void operator []=(int index, E value) {
    checkMutable('indexed set');
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    JS('void', r'#[#] = #', this, index, value);
  }

  Map<int, E> asMap() {
    return new IterableMixinWorkaround<E>().asMapList(this);
  }
}

/**
 * Dummy subclasses that allow the backend to track more precise
 * information about arrays through their type. The CPA type inference
 * relies on the fact that these classes do not override [] nor []=.
 */
class JSMutableArray<E> extends JSArray<E> implements JSMutableIndexable {}
class JSFixedArray<E> extends JSMutableArray<E> {}
class JSExtendableArray<E> extends JSMutableArray<E> {}
