// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;

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

  E min([int compare(E a, E b)]) {
    if (length == 0) return null;
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    E min = this[0];
    int length = this.length;
    for (int i = 1; i < length; i++) {
      E element = this[i];
      if (compare(min, element) > 0) {
        min = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return min;
  }

  E max([int compare(E a, E b)]) {
    if (length == 0) return null;
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    E max = this[0];
    int length = this.length;
    for (int i = 1; i < length; i++) {
      E element = this[i];
      if (compare(max, element) < 0) {
        max = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return max;
  }

  String join([String separator]) {
    int length = this.length;
    if (separator != null && !separator.isEmpty) {
      if (length == 0) return "";
      String first = "${this[0]}";
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
      StringBuffer buffer = new StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.write(separator);
        buffer.write("${this[i]}");
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write("${this[i]}");
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);

  Iterable map(f(E element)) => new MappedListIterable(this, f);

  reduce(var initialValue, combine(var previousValue, E element)) {
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


  void retainAll(Iterable<E> iterable) {
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

  // List interface.

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

  List<E> getRange(int start, int length) => sublist(start, start + length);

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
      if (startIndex >= a.length) {
        startIndex = a.length - 1;
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

/**
 * Mixin that throws on the length changing operations of [List].
 *
 * Intended to mix-in on top of [ListMixin] for fixed-length lists.
 */
abstract class FixedLengthListMixin<E>  {
  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of a fixed-length list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void insert(int index, E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear a fixed-length list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in a fixed-length list");
  }
}

/**
 * Mixin for an unmodifiable [List] class.
 *
 * This overrides all mutating methods with methods that throw.
 * This mixin is intended to be mixed in on top of [ListMixin] on
 * unmodifiable lists.
 */
abstract class UnmodifiableListMixin<E> {

  void operator []=(int index, E value) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of an unmodifiable list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  E insert(int index, E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeWhere(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void retainWhere(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void sort([Comparator<E> compare]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear an unmodifiable list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in an unmodifiable list");
  }
}


/**
 * Abstract implementation of a list.
 *
 * All operations are defined in terms of `length`, `operator[]`,
 * `operator[]=` and `length=`, which need to be implemented.
 */
abstract class ListBase<E> extends ListMixin<E> implements List<E> {}

/**
 * Abstract implementation of a fixed-length list.
 *
 * All operations are defined in terms of `length`, `operator[]` and
 * `operator[]=`, which need to be implemented.
 */
abstract class FixedLengthListBase<E> extends ListBase<E>
                                      with FixedLengthListMixin<E> {}

/**
 * Abstract implementation of an unmodifiable list.
 *
 * All operations are defined in terms of `length` and `operator[]`,
 * which need to be implemented.
 */
abstract class UnmodifiableListBase<E> extends ListBase<E>
                                       with UnmodifiableListMixin<E> {}

/** An empty fixed-length (and therefore unmodifiable) list. */
class EmptyList<E> extends FixedLengthListBase<E> {
  int get length => 0;
  E operator[](int index) { throw new RangeError.value(index); }
  void operator []=(int index, E value) { throw new RangeError.value(index); }
  Iterable<E> skip(int count) => const EmptyIterable();
  Iterable<E> take(int count) => const EmptyIterable();
  Iterable<E> get reversed => const EmptyIterable();
  void sort([int compare(E a, E b)]) {}
}

class ReversedListIterable<E> extends ListIterable<E> {
  Iterable<E> _source;
  ReversedListIterable(this._source);

  int get length => _source.length;

  E elementAt(int index) => _source.elementAt(_source.length - 1 - index);
}

/**
 * An [Iterable] of the UTF-16 code units of a [String] in index order.
 */
class CodeUnits extends UnmodifiableListBase<int> {
  /** The string that this is the code units of. */
  String _string;

  CodeUnits(this._string);

  int get length => _string.length;
  int operator[](int i) => _string.codeUnitAt(i);
}

class _ListIndicesIterable extends ListIterable<int> {
  List _backedList;

  _ListIndicesIterable(this._backedList);

  int get length => _backedList.length;
  int elementAt(int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    }
    return index;
  }
}

class ListMapView<E> implements Map<int, E> {
  List<E> _values;

  ListMapView(this._values);

  E operator[] (int key) => containsKey(key) ? _values[key] : null;
  int get length => _values.length;

  Iterable<E> get values => new SubListIterable<E>(_values, 0, null);
  Iterable<int> get keys => new _ListIndicesIterable(_values);

  bool get isEmpty => _values.isEmpty;
  bool containsValue(E value) => _values.contains(value);
  bool containsKey(int key) => key is int && key >= 0 && key < length;

  void forEach(void f(int key, E value)) {
    int length = _values.length;
    for (int i = 0; i < length; i++) {
      f(i, _values[i]);
      if (length != _values.length) {
        throw new ConcurrentModificationError(_values);
      }
    }
  }

  void operator[]= (int key, E value) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }

  E putIfAbsent(int key, E ifAbsent()) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }

  E remove(int key) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }

  void clear() {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
}
