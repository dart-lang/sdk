// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An object that uses an [Iterator] to serve objects one at a time.
 *
 * You can iterate over all objects served by an Iterable object
 * using the for-in loop construct.
 * For example, you can iterate over all of the keys in a [Map],
 * because Map keys are iterable.
 *
 *     Map kidsBooks = {'Matilda': 'Roald Dahl',
 *                      'Green Eggs and Ham': 'Dr Seuss',
 *                      'Where the Wild Things Are': 'Maurice Sendak'};
 *     for (var book in kidsBooks.keys) {
 *       print('$book was written by ${kidsBooks[book]}');
 *     }
 *
 * The [List] class and the [Set] class implement this interface,
 * as do classes in the [dart:collection](#dart-collection) library.
 *
 * You can implement Iterable in your own class.
 * If you do, then an instance of your Iterable class
 * can be the right-hand side of a for-in construct.
 *
 * Some subclasss of [Iterable] can be modified. It is generally not allowed
 * to modify such collections while they are being iterated. Doing so will break
 * the iteration, which is typically signalled by throwing a
 * [ConcurrentModificationError] when it is detected.
 */
abstract class Iterable<E> {
  const Iterable();

  /**
   * Creates an Iterable that generates its elements dynamically.
   *
   * The Iterators created by the Iterable count from
   * zero to [:count - 1:] while iterating, and call [generator]
   * with that index to create the next value.
   *
   * If [generator] is omitted, it defaults to an identity function
   * on integers `(int x) => x`, so it should only be omitted if the type
   * parameter allows integer values.
   *
   * As an Iterable, [:new Iterable.generate(n, generator)):] is equivalent to
   * [:const [0, ..., n - 1].map(generator):]
   */
  factory Iterable.generate(int count, [E generator(int index)]) {
    if (count <= 0) return new EmptyIterable<E>();
    return new _GeneratorIterable<E>(count, generator);
  }

  /**
   * Returns a new `Iterator` that allows iterating the elements of this
   * `Iterable`.
   */
  Iterator<E> get iterator;

  /**
   * Returns a new lazy [Iterable] with elements that are created by
   * calling `f` on the elements of this `Iterable`.
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [Iterable] is not iterated over, the supplied function [f] will
   * not be invoked. The transformed elements will not be cached. Iterating
   * multiple times over the the returned [Iterable] will invoke the supplied
   * function [f] multiple times on the same element.
   */
  Iterable map(f(E element));

  /**
   * Returns a new lazy [Iterable] with all elements that satisfy the
   * predicate [test].
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [Iterable] is not iterated over, the supplied function [test] will
   * not be invoked. Iterating will not cache results, and thus iterating
   * multiple times over the returned [Iterable] will invoke the supplied
   * function [test] multiple times on the same element.
   */
  Iterable<E> where(bool test(E element));

  /**
   * Expands each element of this [Iterable] into zero or more elements.
   *
   * The resulting Iterable runs through the elements returned
   * by [f] for each element of this, in order.
   *
   * The returned [Iterable] is lazy, and calls [f] for each element
   * of this every time it's iterated.
   */
  Iterable expand(Iterable f(E element));

  /**
   * Returns true if the collection contains an element equal to [element].
   *
   * The equality used to determine whether [element] is equal to an element of
   * the iterable, depends on the type of iterable.
   * For example, a [Set] may have a custom equality
   * (see, e.g., [Set.identical]) that its `contains` uses.
   * Likewise the `Iterable` returned by a [Map.keys] call
   * will likely use the same equality that the `Map` uses for keys.
   */
  bool contains(Object element);

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
   * predicate [test]. Returns `false` otherwise.
   */
  bool every(bool test(E element));

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
   * predicate [test]. Returns false otherwise.
   */
  bool any(bool test(E element));

  /**
   * Creates a [List] containing the elements of this [Iterable].
   *
   * The elements are in iteration order. The list is fixed-length
   * if [growable] is false.
   */
  List<E> toList({ bool growable: true });

  /**
   * Creates a [Set] containing the same elements as this iterable.
   *
   * The set may contain fewer elements than the iterable,
   * if the iterable contains the an element more than once,
   * or it contains one or more elements that are equal.
   * The order of the elements in the set is not guaranteed to be the same
   * as for the iterable.
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
   * Returns true if there is at least one element in this collection.
   */
  bool get isNotEmpty;

  /**
   * Returns an [Iterable] with at most [n] elements.
   *
   * The returned [Iterable] may contain fewer than [n] elements, if `this`
   * contains fewer than [n] elements.
   *
   * It is an error if [n] is negative.
   */
  Iterable<E> take(int n);

  /**
   * Returns an Iterable that stops once [test] is not satisfied anymore.
   *
   * The filtering happens lazily. Every new Iterator of the returned
   * Iterable starts iterating over the elements of `this`.
   *
   * When the iterator encounters an element `e` that does not satisfy [test],
   * it discards `e` and moves into the finished state. That is, it does not
   * get or provide any more elements.
   */
  Iterable<E> takeWhile(bool test(E value));

  /**
   * Returns an Iterable that skips the first [n] elements.
   *
   * If `this` has fewer than [n] elements, then the resulting Iterable is
   * empty.
   *
   * It is an error if [n] is negative.
   */
  Iterable<E> skip(int n);

  /**
   * Returns an Iterable that skips elements while [test] is satisfied.
   *
   * The filtering happens lazily. Every new Iterator of the returned
   * Iterable iterates over all elements of `this`.
   *
   * As long as the iterator's elements satisfy [test] they are
   * discarded. Once an element does not satisfy the [test] the iterator stops
   * testing and uses every later element unconditionally. That is, the elements
   * of the returned Iterable are the elements of `this` starting from the
   * first element that does not satisfy [test].
   */
  Iterable<E> skipWhile(bool test(E value));

  /**
   * Returns the first element.
   *
   * If `this` is empty throws a [StateError]. Otherwise this method is
   * equivalent to [:this.elementAt(0):]
   */
  E get first;

  /**
   * Returns the last element.
   *
   * If `this` is empty throws a [StateError].
   */
  E get last;

  /**
   * Returns the single element in `this`.
   *
   * If `this` is empty or has more than one element throws a [StateError].
   */
  E get single;

  /**
   * Returns the first element that satisfies the given predicate [test].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is `null`, a [StateError] is
   * thrown.
   */
  E firstWhere(bool test(E element), { E orElse() });

  /**
   * Returns the last element that satisfies the given predicate [test].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is `null`, a [StateError] is
   * thrown.
   */
  E lastWhere(bool test(E element), {E orElse()});

  /**
   * Returns the single element that satisfies [test]. If no or more than one
   * element match then a [StateError] is thrown.
   */
  E singleWhere(bool test(E element));

  /**
   * Returns the [index]th element.
   *
   * The [index] must be non-negative and less than [length].
   *
   * Note: if `this` does not have a deterministic iteration order then the
   * function may simply return any element without any iteration if there are
   * at least [index] elements in `this`.
   */
  E elementAt(int index);
}

typedef E _Generator<E>(int index);

class _GeneratorIterable<E> extends IterableBase<E>
                            implements EfficientLength {
  final int _start;
  final int _end;
  final _Generator<E> _generator;
  _GeneratorIterable(this._end, E generator(int n))
      : _start = 0,
        _generator = (generator != null) ? generator : _id;

  _GeneratorIterable.slice(this._start, this._end, this._generator);

  Iterator<E> get iterator =>
      new _GeneratorIterator<E>(_start, _end, _generator);
  int get length => _end - _start;

  Iterable<E> skip(int n) {
    if (n < 0) throw new RangeError.value(n);
    if (n == 0) return this;
    int newStart = _start + n;
    if (newStart >= _end) return new EmptyIterable<E>();
    return new _GeneratorIterable<E>.slice(newStart, _end, _generator);
  }

  Iterable<E> take(int n) {
    if (n < 0) throw new RangeError.value(n);
    if (n == 0) return new EmptyIterable<E>();
    int newEnd = _start + n;
    if (newEnd >= _end) return this;
    return new _GeneratorIterable<E>.slice(_start, newEnd, _generator);
  }

  static int _id(int n) => n;
}

class _GeneratorIterator<E> implements Iterator<E> {
  final int _end;
  final _Generator<E> _generator;
  int _index;
  E _current;

  _GeneratorIterator(this._index, this._end, this._generator);

  bool moveNext() {
    if (_index < _end) {
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
 * An Iterator that allows moving backwards as well as forwards.
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
