// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * Abstract implementation of a list.
 *
 * `ListBase` can be used as a base class for implementing the `List` interface.
 *
 * All operations are defined in terms of `length`, `operator[]`,
 * `operator[]=` and `length=`, which need to be implemented.
 *
 * *NOTICE*: Forwarding just these four operations to a normal growable [List]
 * (as created by `new List()`) will give very bad performance for `add` and
 * `addAll` operations of `ListBase`. These operations are implemented by
 * increasing the length of the list by one for each `add` operation, and
 * repeatedly increasing the length of a growable list is not efficient.
 * To avoid this, either override 'add' and 'addAll' to also forward directly
 * to the growable list, or, preferably, use `DelegatingList` from
 * "package:collection/wrappers.dart" instead.
 */
abstract class ListBase<E> extends Object with ListMixin<E> {
  /**
   * Convert a `List` to a string as `[each, element, as, string]`.
   *
   * Handles circular references where converting one of the elements
   * to a string ends up converting [list] to a string again.
   */
  static String listToString(List list) =>
      IterableBase.iterableToFullString(list, '[', ']');
}

/**
 * Base implementation of a [List] class.
 *
 * `ListMixin` can be used as a mixin to make a class implement
 * the `List` interface.
 *
 * This implements all read operations using only the `length` and
 * `operator[]` members. It implements write operations using those and
 * `length=` and `operator[]=`
 *
 * *NOTICE*: Forwarding just these four operations to a normal growable [List]
 * (as created by `new List()`) will give very bad performance for `add` and
 * `addAll` operations of `ListBase`. These operations are implemented by
 * increasing the length of the list by one for each `add` operation, and
 * repeatedly increasing the length of a growable list is not efficient.
 * To avoid this, either override 'add' and 'addAll' to also forward directly
 * to the growable list, or, if possible, use `DelegatingList` from
 * "package:collection/wrappers.dart" instead.
 */
abstract class ListMixin<E> implements List<E> {
  // Iterable interface.
  Iterator<E> get iterator => new ListIterator<E>(this);

  E elementAt(int index) => this[index];

  void forEach(void action(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(this[i]);
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  E get first {
    if (length == 0) throw new StateError("No elements");
    return this[0];
  }

  E get last {
    if (length == 0) throw new StateError("No elements");
    return this[length - 1];
  }

  E get single {
    if (length == 0) throw new StateError("No elements");
    if (length > 1) throw new StateError("Too many elements");
    return this[0];
  }

  bool contains(Object element) {
    int length = this.length;
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  bool every(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (!test(this[i])) return false;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return true;
  }

  bool any(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  dynamic firstWhere(bool test(E element), { Object orElse() }) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  dynamic lastWhere(bool test(E element), { Object orElse() }) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E singleWhere(bool test(E element)) {
    int length = this.length;
    E match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = this[i];
      if (test(element)) {
        if (matchFound) {
          throw new StateError("More than one matching element");
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw new StateError("No matching element");
  }

  String join([String separator = ""]) {
    if (length == 0) return "";
    StringBuffer buffer = new StringBuffer()..writeAll(this, separator);
    return buffer.toString();
  }

  Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);

  Iterable map(f(E element)) => new MappedListIterable(this, f);

  Iterable expand(Iterable f(E element)) =>
      new ExpandIterable<E, dynamic>(this, f);

  E reduce(E combine(E previousValue, E element)) {
    if (length == 0) throw new StateError("No elements");
    E value = this[0];
    for (int i = 1; i < length; i++) {
      value = combine(value, this[i]);
    }
    return value;
  }

  fold(var initialValue, combine(var previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      value = combine(value, this[i]);
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return value;
  }

  Iterable<E> skip(int count) => new SubListIterable(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) {
    return new SkipWhileIterable<E>(this, test);
  }

  Iterable<E> take(int count) => new SubListIterable(this, 0, count);

  Iterable<E> takeWhile(bool test(E element)) {
    return new TakeWhileIterable<E>(this, test);
  }

  List<E> toList({ bool growable: true }) {
    List<E> result;
    if (growable) {
      result = new List<E>()..length = length;
    } else {
      result = new List<E>(length);
    }
    for (int i = 0; i < length; i++) {
      result[i] = this[i];
    }
    return result;
  }

  Set<E> toSet() {
    Set<E> result = new Set<E>();
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
    }
    return result;
  }

  // Collection interface.
  void add(E element) {
    this[this.length++] = element;
  }

  void addAll(Iterable<E> iterable) {
    for (E element in iterable) {
      this[this.length++] = element;
    }
  }

  bool remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        this.setRange(i, this.length - 1, this, i + 1);
        this.length -= 1;
        return true;
      }
    }
    return false;
  }

  void removeWhere(bool test(E element)) {
    _filter(this, test, false);
  }

  void retainWhere(bool test(E element)) {
    _filter(this, test, true);
  }

  static void _filter(List source,
                      bool test(var element),
                      bool retainMatching) {
    List retained = [];
    int length = source.length;
    for (int i = 0; i < length; i++) {
      var element = source[i];
      if (test(element) == retainMatching) {
        retained.add(element);
      }
      if (length != source.length) {
        throw new ConcurrentModificationError(source);
      }
    }
    if (retained.length != source.length) {
      source.setRange(0, retained.length, retained);
      source.length = retained.length;
    }
  }

  void clear() { this.length = 0; }

  // List interface.

  E removeLast() {
    if (length == 0) {
      throw new StateError("No elements");
    }
    E result = this[length - 1];
    length--;
    return result;
  }

  void sort([int compare(E a, E b)]) {
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    Sort.sort(this, compare);
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    int length = this.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = this[length];
      this[length] = this[pos];
      this[pos] = tmp;
    }
  }

  Map<int, E> asMap() {
    return new ListMapView(this);
  }

  void _rangeCheck(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
  }

  List<E> sublist(int start, [int end]) {
    if (end == null) end = this.length;
    _rangeCheck(start, end);
    int length = end - start;
    List<E> result = new List<E>()..length = length;
    for (int i = 0; i < length; i++) {
      result[i] = this[start + i];
    }
    return result;
  }

  Iterable<E> getRange(int start, int end) {
    _rangeCheck(start, end);
    return new SubListIterable(this, start, end);
  }

  void removeRange(int start, int end) {
    _rangeCheck(start, end);
    int length = end - start;
    setRange(start, this.length - length, this, end);
    this.length -= length;
  }

  void fillRange(int start, int end, [E fill]) {
    _rangeCheck(start, end);
    for (int i = start; i < end; i++) {
      this[i] = fill;
    }
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _rangeCheck(start, end);
    int length = end - start;
    if (length == 0) return;

    if (skipCount < 0) throw new ArgumentError(skipCount);

    List otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw new StateError("Not enough elements");
    }
    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      for (int i = length - 1; i >= 0; i--) {
        this[start + i] = otherList[otherStart + i];
      }
    } else {
      for (int i = 0; i < length; i++) {
        this[start + i] = otherList[otherStart + i];
      }
    }
  }

  void replaceRange(int start, int end, Iterable<E> newContents) {
    _rangeCheck(start, end);
    if (newContents is! EfficientLength) {
      newContents = newContents.toList();
    }
    int removeLength = end - start;
    int insertLength = newContents.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newLength = this.length - delta;
      this.setRange(start, insertEnd, newContents);
      if (delta != 0) {
        this.setRange(insertEnd, newLength, this, end);
        this.length = newLength;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = this.length + delta;
      int insertEnd = start + insertLength;  // aka. end + delta.
      this.length = newLength;
      this.setRange(insertEnd, newLength, this, end);
      this.setRange(start, insertEnd, newContents);
    }
  }

  int indexOf(Object element, [int startIndex = 0]) {
    if (startIndex >= this.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < this.length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the list [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  int lastIndexOf(Object element, [int startIndex]) {
    if (startIndex == null) {
      startIndex = this.length - 1;
    } else {
      if (startIndex < 0) {
        return -1;
      }
      if (startIndex >= this.length) {
        startIndex = this.length - 1;
      }
    }
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  void insert(int index, E element) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == this.length) {
      add(element);
      return;
    }
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this.length++;
    setRange(index + 1, this.length, this, index);
    this[index] = element;
  }

  E removeAt(int index) {
    E result = this[index];
    setRange(index, this.length - 1, this, index + 1);
    length--;
    return result;
  }

  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (iterable is EfficientLength) {
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

  void setAll(int index, Iterable<E> iterable) {
    if (iterable is List) {
      setRange(index, index + iterable.length, iterable);
    } else {
      for (E element in iterable) {
        this[index++] = element;
      }
    }
  }

  Iterable<E> get reversed => new ReversedListIterable(this);

  String toString() => IterableBase.iterableToFullString(this, '[', ']');
}
