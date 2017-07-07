// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Base implementations of [Set].
 */
part of dart.collection;

/**
 * Mixin implementation of [Set].
 *
 * This class provides a base implementation of a `Set` that depends only
 * on the abstract members: [add], [contains], [lookup], [remove],
 * [iterator], [length] and [toSet].
 *
 * Some of the methods assume that `toSet` creates a modifiable set.
 * If using this mixin for an unmodifiable set,
 * where `toSet` should return an unmodifiable set,
 * it's necessary to reimplement
 * [retainAll], [union], [intersection] and [difference].
 *
 * Implementations of `Set` using this mixin should consider also implementing
 * `clear` in constant time. The default implementation works by removing every
 * element.
 */
abstract class SetMixin<E> implements Set<E> {
  // This class reimplements all of [IterableMixin].
  // If/when Dart mixins get more powerful, we should just create a single
  // Mixin class from IterableMixin and the new methods of this class.

  bool add(E value);

  bool contains(Object element);

  E lookup(Object element);

  bool remove(Object value);

  Iterator<E> get iterator;

  Set<E> toSet();

  int get length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  void clear() {
    removeAll(toList());
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) add(element);
  }

  void removeAll(Iterable<Object> elements) {
    for (Object element in elements) remove(element);
  }

  void retainAll(Iterable<Object> elements) {
    // Create a copy of the set, remove all of elements from the copy,
    // then remove all remaining elements in copy from this.
    Set<E> toRemove = toSet();
    for (Object o in elements) {
      toRemove.remove(o);
    }
    removeAll(toRemove);
  }

  void removeWhere(bool test(E element)) {
    List toRemove = [];
    for (E element in this) {
      if (test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  void retainWhere(bool test(E element)) {
    List toRemove = [];
    for (E element in this) {
      if (!test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  bool containsAll(Iterable<Object> other) {
    for (Object o in other) {
      if (!contains(o)) return false;
    }
    return true;
  }

  Set<E> union(Set<E> other) {
    return toSet()..addAll(other);
  }

  Set<E> intersection(Set<Object> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (!other.contains(element)) result.remove(element);
    }
    return result;
  }

  Set<E> difference(Set<Object> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (other.contains(element)) result.remove(element);
    }
    return result;
  }

  List<E> toList({bool growable: true}) {
    List<E> result =
        growable ? (new List<E>()..length = length) : new List<E>(length);
    int i = 0;
    for (E element in this) result[i++] = element;
    return result;
  }

  Iterable<T> map<T>(T f(E element)) =>
      new EfficientLengthMappedIterable<E, T>(this, f);

  E get single {
    if (length > 1) throw IterableElementError.tooMany();
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    return result;
  }

  String toString() => IterableBase.iterableToFullString(this, '{', '}');

  // Copied from IterableMixin.
  // Should be inherited if we had multi-level mixins.

  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      new ExpandIterable<E, T>(this, f);

  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  E reduce(E combine(E value, E element)) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.write("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  bool any(bool test(E element)) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  Iterable<E> take(int n) {
    return new TakeIterable<E>(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return new SkipIterable<E>(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  E get last {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = it.current;
    } while (it.moveNext());
    return result;
  }

  E firstWhere(bool test(E value), {E orElse()}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E value), {E orElse()}) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E value)) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    if (index is! int) throw new ArgumentError.notNull("index");
    RangeError.checkNotNegative(index, "index");
    int elementIndex = 0;
    for (E element in this) {
      if (index == elementIndex) return element;
      elementIndex++;
    }
    throw new RangeError.index(index, this, "index", null, elementIndex);
  }
}

/**
 * Base implementation of [Set].
 *
 * This class provides a base implementation of a `Set` that depends only
 * on the abstract members: [add], [contains], [lookup], [remove],
 * [iterator], [length] and [toSet].
 *
 * Some of the methods assume that `toSet` creates a modifiable set.
 * If using this base class for an unmodifiable set,
 * where `toSet` should return an unmodifiable set,
 * it's necessary to reimplement
 * [retainAll], [union], [intersection] and [difference].
 *
 * Implementations of `Set` using this base should consider also implementing
 * `clear` in constant time. The default implementation works by removing every
 * element.
 */
abstract class SetBase<E> extends SetMixin<E> {
  /**
   * Convert a `Set` to a string as `{each, element, as, string}`.
   *
   * Handles circular references where converting one of the elements
   * to a string ends up converting [set] to a string again.
   */
  static String setToString(Set set) =>
      IterableBase.iterableToFullString(set, '{', '}');
}
