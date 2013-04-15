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
  Iterable map(f(E element));

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
  Iterable<E> where(bool f(E element));

  /**
   * Expand each element of this [Iterable] into zero or more elements.
   *
   * The resulting Iterable will run through the elements returned
   * by [f] for each element of this, in order.
   *
   * The returned [Iterable] is lazy, and will call [f] for each element
   * of this every time it's iterated.
   */
  Iterable expand(Iterable f(E element));

  /**
   * Check whether the collection contains an element equal to [element].
   */
  bool contains(E element);

  /**
   * Applies the function [f] to each element of this collection.
   */
  void forEach(void f(E element));

  /**
   * Reduces a collection to a single value by iteratively combining elements
   * of the collection using the provided function.
   *
   * Example of calculating the sum of an iterable:
   *
   *     iterable.reduce((value, element) => value + element);
   *
   */
  E reduce(E combine(E value, E element));

  /**
   * Reduces a collection to a single value by iteratively combining each
   * element of the collection with an existing value using the provided
   * function.
   *
   * Use [initialValue] as the initial value, and the function [combine] to
   * create a new value from the previous one and an element.
   *
   * Example of calculating the sum of an iterable:
   *
   *     iterable.fold(0, (prev, element) => prev + element);
   *
   */
  dynamic fold(var initialValue,
               dynamic combine(var previousValue, E element));

  /**
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(bool f(E element));

  /**
   * Converts each element to a [String] and concatenates the strings.
   *
   * Converts each element to a [String] by calling [Object.toString] on it.
   * Then concatenates the strings, optionally separated by the [separator]
   * string.
   */
  String join([String separator = ""]) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(this, separator);
    return buffer.toString();
  }

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool any(bool f(E element));

  /**
   * Creates a [List] containing the elements of this [Iterable].
   *
   * The elements will be in iteration order. The list is fixed-length
   * if [growable] is false.
   */
  List<E> toList({ bool growable: true });

  /**
   * Creates a [Set] containing the elements of this [Iterable].
   */
  Set<E> toSet();

  /**
   * Returns the number of elements in [this].
   *
   * Counting all elements may be involve running through all elements and can
   * therefore be slow.
   */
  int get length;

  /**
   * Returns true if there is no element in this collection.
   */
  bool get isEmpty;

  /**
   * Returns an [Iterable] with at most [n] elements.
   *
   * The returned [Iterable] may contain fewer than [n] elements, if [this]
   * contains fewer than [n] elements.
   */
  Iterable<E> take(int n);

  /**
   * Returns an [Iterable] that stops once [test] is not satisfied anymore.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will start iterating over the elements of [this].
   * When the iterator encounters an element [:e:] that does not satisfy [test],
   * it discards [:e:] and moves into the finished state. That is, it will not
   * ask or provide any more elements.
   */
  Iterable<E> takeWhile(bool test(E value));

  /**
   * Returns an [Iterable] that skips the first [n] elements.
   *
   * If [this] has fewer than [n] elements, then the resulting [Iterable] will
   * be empty.
   */
  Iterable<E> skip(int n);

  /**
   * Returns an [Iterable] that skips elements while [test] is satisfied.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will iterate over all elements of [this].
   * As long as the iterator's elements do not satisfy [test] they are
   * discarded. Once an element satisfies the [test] the iterator stops testing
   * and uses every element unconditionally.
   */
  Iterable<E> skipWhile(bool test(E value));

  /**
   * Returns the first element.
   *
   * If [this] is empty throws a [StateError]. Otherwise this method is
   * equivalent to [:this.elementAt(0):]
   */
  E get first;

  /**
   * Returns the last element.
   *
   * If [this] is empty throws a [StateError].
   */
  E get last;

  /**
   * Returns the single element in [this].
   *
   * If [this] is empty or has more than one element throws a [StateError].
   */
  E get single;

  /**
   * Returns the first element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is `null`, a [StateError] is
   * thrown.
   */
  E firstWhere(bool test(E value), { E orElse() });

  /**
   * Returns the last element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is [:null:], a [StateError] is
   * thrown.
   */
  E lastWhere(bool test(E value), {E orElse()});

  /**
   * Returns the single element that satisfies [f]. If no or more than one
   * element match then a [StateError] is thrown.
   */
  E singleWhere(bool test(E value));

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
  E elementAt(int index);
}


typedef E _Generator<E>(int index);

class _GeneratorIterable<E> extends IterableBase<E> {
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
abstract class BidirectionalIterator<E> implements Iterator<E> {
  /**
   * Move back to the previous element.
   *
   * Returns true and updates [current] if successful. Returns false
   * and sets [current] to null if there is no previous element.
   */
  bool movePrevious();
}
