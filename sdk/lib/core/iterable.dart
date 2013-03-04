// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The [Iterable] interface allows to get an [Iterator] out of an
 * [Iterable] object.
 *
 * This interface is used by the for-in construct to iterate over an
 * [Iterable] object.
 * The for-in construct takes an [Iterable] object at the right-hand
 * side, and calls its [iterator] method to get an [Iterator] on it.
 *
 * A user-defined class that implements the [Iterable] interface can
 * be used as the right-hand side of a for-in construct.
 */
abstract class Iterable<E> {
  const Iterable();

  /**
   * Create an [Iterable] that generates its elements dynamically.
   *
   * The [Iterators] created by the [Iterable] will count from
   * zero to [:count - 1:] while iterating, and call [generator]
   * with that index to create the next value.
   *
   * As an [Iterable], [:new Iterable.generate(n, generator)):] is equivalent to
   * [:const [0, ..., n - 1].map(generator):]
   */
  factory Iterable.generate(int count, E generator(int index)) {
    return new _GeneratorIterable<E>(count, generator);
  }

  /**
   * Returns an [Iterator] that iterates over this [Iterable] object.
   */
  Iterator<E> get iterator;

  /**
   * Returns a lazy [Iterable] where each element [:e:] of [this] is replaced
   * by the result of [:f(e):].
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [Iterable] is not iterated over, the supplied function [f] will
   * not be invoked. The transformed elements will not be cached. Iterating
   * multiple times over the the returned [Iterable] will invoke the supplied
   * function [f] multiple times on the same element.
   */
  Iterable map(f(E element)) => new MappedIterable<E, dynamic>(this, f);

  /**
   * Returns a lazy [Iterable] with all elements that satisfy the
   * predicate [f].
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [Iterable] is not iterated over, the supplied function [f] will
   * not be invoked. Iterating will not cache results, and thus iterating
   * multiple times over the the returned [Iterable] will invoke the supplied
   * function [f] multiple times on the same element.
   */
  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);


  /**
   * Expand each element of this [Iterable] into zero or more elements.
   *
   * The resulting Iterable will run through the elements returned
   * by [f] for each element of this, in order.
   *
   * The returned [Iterable] is lazy, and will call [f] for each element
   * of this every time it's iterated.
   */
  Iterable expand(Iterable f(E element)) =>
      new ExpandIterable<E, dynamic>(this, f);

  /**
   * Check whether the collection contains an element equal to [element].
   */
  bool contains(E element) {
    for (E e in this) {
      if (e == element) return true;
    }
    return false;
  }

  /**
   * Applies the function [f] to each element of this collection.
   */
  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  /**
   * Reduce a collection to a single value by iteratively combining each element
   * of the collection with an existing value using the provided function.
   * Use [initialValue] as the initial value, and the function [combine] to
   * create a new value from the previous one and an element.
   *
   * Example of calculating the sum of a collection:
   *
   *   collection.reduce(0, (prev, element) => prev + element);
   */
  dynamic reduce(var initialValue,
                 dynamic combine(var previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  /**
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  /**
   * Convert each element to a [String] and concatenate the strings.
   *
   * Converts each element to a [String] by calling [Object.toString] on it.
   * Then concatenates the strings, optionally separated by the [separator]
   * string.
   */
  String join([String separator]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.add("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.add("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.add(separator);
        buffer.add("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool any(bool f(E element)) {
    for (E element in this) {
      if (f(element)) return true;
    }
    return false;
  }

  List<E> toList({ bool growable: true }) =>
      new List<E>.from(this, growable: growable);
  Set<E> toSet() => new Set<E>.from(this);

  /**
   * Returns the number of elements in [this].
   *
   * Counting all elements may be involve running through all elements and can
   * therefore be slow.
   */
  int get length {
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  /**
   * Find the least element in the iterable.
   *
   * Returns null if the iterable is empty.
   * Otherwise returns an element [:x:] of this [Iterable] so that
   * [:x:] is not greater than [:y:] (that is, [:compare(x, y) <= 0:]) for all
   * other elements [:y:] in the iterable.
   *
   * The [compare] function must be a proper [Comparator<T>]. If a function is
   * not provided, [compare] defaults to [Comparable.compare].
   */
  E min([int compare(E a, E b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterator;
    if (!it.moveNext()) return null;
    E min = it.current;
    while (it.moveNext()) {
      E current = it.current;
      if (compare(min, current) > 0) min = current;
    }
    return min;
  }

  /**
   * Find the largest element in the iterable.
   *
   * Returns null if the iterable is empty.
   * Otherwise returns an element [:x:] of this [Iterable] so that
   * [:x:] is not smaller than [:y:] (that is, [:compare(x, y) >= 0:]) for all
   * other elements [:y:] in the iterable.
   *
   * The [compare] function must be a proper [Comparator<T>]. If a function is
   * not provided, [compare] defaults to [Comparable.compare].
   */
  E max([int compare(E a, E b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterator;
    if (!it.moveNext()) return null;
    E max = it.current;
    while (it.moveNext()) {
      E current = it.current;
      if (compare(max, current) < 0) max = current;
    }
    return max;
  }

  /**
   * Returns true if there is no element in this collection.
   */
  bool get isEmpty => !iterator.moveNext();

  /**
   * Returns an [Iterable] with at most [n] elements.
   *
   * The returned [Iterable] may contain fewer than [n] elements, if [this]
   * contains fewer than [n] elements.
   */
  Iterable<E> take(int n) {
    return new TakeIterable<E>(this, n);
  }

  /**
   * Returns an [Iterable] that stops once [test] is not satisfied anymore.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will start iterating over the elements of [this].
   * When the iterator encounters an element [:e:] that does not satisfy [test],
   * it discards [:e:] and moves into the finished state. That is, it will not
   * ask or provide any more elements.
   */
  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  /**
   * Returns an [Iterable] that skips the first [n] elements.
   *
   * If [this] has fewer than [n] elements, then the resulting [Iterable] will
   * be empty.
   */
  Iterable<E> skip(int n) {
    return new SkipIterable<E>(this, n);
  }

  /**
   * Returns an [Iterable] that skips elements while [test] is satisfied.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will iterate over all elements of [this].
   * As long as the iterator's elements do not satisfy [test] they are
   * discarded. Once an element satisfies the [test] the iterator stops testing
   * and uses every element unconditionally.
   */
  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  /**
   * Returns the first element.
   *
   * If [this] is empty throws a [StateError]. Otherwise this method is
   * equivalent to [:this.elementAt(0):]
   */
  E get first {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    return it.current;
  }

  /**
   * Returns the last element.
   *
   * If [this] is empty throws a [StateError].
   */
  E get last {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    E result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  /**
   * Returns the single element in [this].
   *
   * If [this] is empty or has more than one element throws a [StateError].
   */
  E get single {
    Iterator it = iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    E result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  /**
   * Returns the first element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is `null`, a [StateError] is
   * thrown.
   */
  E firstMatching(bool test(E value), { E orElse() }) {
    // TODO(floitsch): check that arguments are of correct type?
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  /**
   * Returns the last element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is [:null:], a [StateError] is
   * thrown.
   */
  E lastMatching(bool test(E value), {E orElse()}) {
    // TODO(floitsch): check that arguments are of correct type?
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
    throw new StateError("No matching element");
  }

  /**
   * Returns the single element that satisfies [f]. If no or more than one
   * element match then a [StateError] is thrown.
   */
  E singleMatching(bool test(E value)) {
    // TODO(floitsch): check that argument is of correct type?
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        if (foundMatching) {
          throw new StateError("More than one matching element");
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw new StateError("No matching element");
  }

  /**
   * Returns the [index]th element.
   *
   * If [this] [Iterable] has fewer than [index] elements throws a
   * [RangeError].
   *
   * Note: if [this] does not have a deterministic iteration order then the
   * function may simply return any element without any iteration if there are
   * at least [index] elements in [this].
   */
  E elementAt(int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (E element in this) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }
}


typedef E _Generator<E>(int index);

class _GeneratorIterable<E> extends Iterable<E> {
  final int _count;
  final _Generator<E> _generator;
  _GeneratorIterable(this._count, this._generator);
  Iterator<E> get iterator => new _GeneratorIterator(_count, _generator);
}

class _GeneratorIterator<E> implements Iterator<E> {
  final int _count;
  final _Generator<E> _generator;
  int _index = 0;
  E _current;

  _GeneratorIterator(this._count, this._generator);

  bool moveNext() {
    if (_index < _count) {
      _current = _generator(_index);
      _index++;
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  E get current => _current;
}

/**
 * An [Iterator] that allows moving backwards as well as forwards.
 */
abstract class BidirectionalIterator<T> extends Iterator<T> {
  /**
   * Move back to the previous element.
   *
   * Returns true and updates [current] if successful. Returns false
   * and sets [current] to null if there is no previous element.
   */
  bool movePrevious();
}
