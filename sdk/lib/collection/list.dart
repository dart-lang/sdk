// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "collection.dart";

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
    if (length == 0) throw IterableElementError.noElement();
    return this[0];
  }

  E get last {
    if (length == 0) throw IterableElementError.noElement();
    return this[length - 1];
  }

  E get single {
    if (length == 0) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
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

  E firstWhere(bool test(E element), {E orElse()}) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), {E orElse()}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element)) {
    int length = this.length;
    E match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = this[i];
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) {
    if (length == 0) return "";
    StringBuffer buffer = new StringBuffer()..writeAll(this, separator);
    return buffer.toString();
  }

  Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);

  Iterable<T> map<T>(T f(E element)) => new MappedListIterable<E, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      new ExpandIterable<E, T>(this, f);

  E reduce(E combine(E previousValue, E element)) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = this[0];
    for (int i = 1; i < length; i++) {
      value = combine(value, this[i]);
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
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

  Iterable<E> skip(int count) => new SubListIterable<E>(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) {
    return new SkipWhileIterable<E>(this, test);
  }

  Iterable<E> take(int count) => new SubListIterable<E>(this, 0, count);

  Iterable<E> takeWhile(bool test(E element)) {
    return new TakeWhileIterable<E>(this, test);
  }

  List<E> toList({bool growable: true}) {
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
    int i = this.length;
    for (E element in iterable) {
      assert(this.length == i || (throw new ConcurrentModificationError(this)));
      this.length = i + 1;
      this[i] = element;
      i++;
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
    _filter(test, false);
  }

  void retainWhere(bool test(E element)) {
    _filter(test, true);
  }

  void _filter(bool test(var element), bool retainMatching) {
    List<E> retained = <E>[];
    int length = this.length;
    for (int i = 0; i < length; i++) {
      var element = this[i];
      if (test(element) == retainMatching) {
        retained.add(element);
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (retained.length != this.length) {
      this.setRange(0, retained.length, retained);
      this.length = retained.length;
    }
  }

  void clear() {
    this.length = 0;
  }

  // List interface.

  E removeLast() {
    if (length == 0) {
      throw IterableElementError.noElement();
    }
    E result = this[length - 1];
    length--;
    return result;
  }

  void sort([int compare(E a, E b)]) {
    Sort.sort(this, compare ?? _compareAny);
  }

  static int _compareAny(a, b) {
    // In strong mode Comparable.compare requires an implicit cast to ensure
    // `a` and `b` are Comparable.
    return Comparable.compare(a, b);
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
    return new ListMapView<E>(this);
  }

  List<E> sublist(int start, [int end]) {
    int listLength = this.length;
    if (end == null) end = listLength;
    RangeError.checkValidRange(start, end, listLength);
    int length = end - start;
    List<E> result = new List<E>()..length = length;
    for (int i = 0; i < length; i++) {
      result[i] = this[start + i];
    }
    return result;
  }

  Iterable<E> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<E>(this, start, end);
  }

  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    setRange(start, this.length - length, this, end);
    this.length -= length;
  }

  void fillRange(int start, int end, [E fill]) {
    RangeError.checkValidRange(start, end, this.length);
    for (int i = start; i < end; i++) {
      this[i] = fill;
    }
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");

    List<E> otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List<E>) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw IterableElementError.tooFew();
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
    RangeError.checkValidRange(start, end, this.length);
    if (newContents is! EfficientLengthIterable) {
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
      int insertEnd = start + insertLength; // aka. end + delta.
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
    RangeError.checkValueInInterval(index, 0, length, "index");
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
    RangeError.checkValueInInterval(index, 0, length, "index");
    if (iterable is! EfficientLengthIterable || identical(iterable, this)) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    this.length += insertionLength;
    if (iterable.length != insertionLength) {
      // If the iterable's length is linked to this list's length somehow,
      // we can't insert one in the other.
      this.length -= insertionLength;
      throw new ConcurrentModificationError(iterable);
    }
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

  Iterable<E> get reversed => new ReversedListIterable<E>(this);

  String toString() => IterableBase.iterableToFullString(this, '[', ']');
}
