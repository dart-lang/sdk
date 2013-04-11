// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * Abstract implementation of a list.
 *
 * All operations are defined in terms of `length`, `operator[]`,
 * `operator[]=` and `length=`, which need to be implemented.
 */
typedef ListBase<E> = Object with ListMixin<E>;

/**
 * Base implementation of a [List] class.
 *
 * This class can be used as a mixin.
 *
 * This implements all read operations using only the `length` and
 * `operator[]` members. It implements write operations using those and
 * `length=` and `operator[]=`
 *
 * A fixed-length list should mix this class in, and the [FixedLengthListMixin]
 * as well, in that order, to overwrite the methods that modify the length.
 *
 * An unmodifiable list should mix [UnmodifiableListMixin] on top of this
 * mixin to prevent all modifications.
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

  bool contains(E element) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
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

  E firstWhere(bool test(E element), { E orElse() }) {
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

  E lastWhere(bool test(E element), { E orElse() }) {
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
    int length = this.length;
    if (!separator.isEmpty) {
      if (length == 0) return "";
      String first = "${this[0]}";
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
      StringBuffer buffer = new StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.write(separator);
        buffer.write(this[i]);
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(this[i]);
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);

  Iterable map(f(E element)) => new MappedListIterable(this, f);

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

  void remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        this.setRange(i, this.length - i - 1, this, i + 1);
        this.length -= 1;
        return;
      }
    }
  }

  void removeAll(Iterable<Object> elements) {
    if (elements is! Set) {
      elements = elements.toSet();
    }
    _filter(this, elements.contains, false);
  }


  void retainAll(Iterable<E> elements) {
    if (elements is! Set) {
      elements = elements.toSet();
    }
    _filter(this, elements.contains, true);
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

  void sort([Comparator<E> compare]) {
    Sort.sort(this, compare);
  }

  Map<int, E> asMap() {
    return new ListMapView(this);
  }

  List<E> sublist(int start, [int end]) {
    if (end == null) end = length;
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
    int length = end - start;
    List<E> result = new List<E>()..length = length;
    for (int i = 0; i < length; i++) {
      result[i] = this[start + i];
    }
    return result;
  }

  Iterable<E> getRange(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
    return new SubListIterable(this, start, end);
  }

  void insertRange(int start, int length, [E initialValue]) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    int oldLength = this.length;
    int moveLength = oldLength - start;
    this.length += length;
    if (moveLength > 0) {
      this.setRange(start + length, moveLength, this, start);
    }
    for (int i = 0; i < length; i++) {
      this[start + i] = initialValue;
    }
  }

  void removeRange(int start, int length) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (length < 0 || start + length > this.length) {
      throw new RangeError.range(length, 0, this.length - start);
    }
    int end = start + length;
    setRange(start, this.length - end, this, end);
    this.length -= length;
  }

  void clearRange(int start, int length, [E fill]) {
    for (int i = 0; i < length; i++) {
      this[start + i] = fill;
    }
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (length < 0 || start + length > this.length) {
      throw new RangeError.range(length, 0, this.length - start);
    }
    if (startFrom == null) {
      startFrom = 0;
    }
    if (startFrom < 0 || startFrom + length > from.length) {
      throw new RangeError.range(startFrom, 0, from.length - length);
    }
    if (startFrom < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      for (int i = length - 1; i >= 0; i--) {
        this[start + i] = from[startFrom + i];
      }
    } else {
      for (int i = 0; i < length; i++) {
        this[start + i] = from[startFrom + i];
      }
    }
  }

  int indexOf(E element, [int startIndex = 0]) {
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
  int lastIndexOf(E element, [int startIndex]) {
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

  Iterable<E> get reversed => new ReversedListIterable(this);
}
