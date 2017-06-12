// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A collection of values, or "elements", that can be accessed sequentially.
 *
 * The elements of the iterable are accessed by getting an [Iterator]
 * using the [iterator] getter, and using it to step through the values.
 * Stepping with the iterator is done by calling [Iterator.moveNext],
 * and if the call returns `true`,
 * the iterator has now moved to the next element,
 * which is then available as [Iterator.current].
 * If the call returns `false`, there are no more elements,
 * and `iterator.current` returns `null`.
 *
 * You can create more than one iterator from the same `Iterable`.
 * Each time `iterator` is read, it returns a new iterator,
 * and different iterators can be stepped through independently,
 * each giving access to all the elements of the iterable.
 * The iterators of the same iterable *should* provide the same values
 * in the same order (unless the underlying collection is modified between
 * the iterations, which some collections allow).
 *
 * You can also iterate over the elements of an `Iterable`
 * using the for-in loop construct, which uses the `iterator` getter behind the
 * scenes.
 * For example, you can iterate over all of the keys of a [Map],
 * because `Map` keys are iterable.
 *
 *     Map kidsBooks = {'Matilda': 'Roald Dahl',
 *                      'Green Eggs and Ham': 'Dr Seuss',
 *                      'Where the Wild Things Are': 'Maurice Sendak'};
 *     for (var book in kidsBooks.keys) {
 *       print('$book was written by ${kidsBooks[book]}');
 *     }
 *
 * The [List] and [Set] classes are both `Iterable`,
 * as are most classes in the [dart:collection](#dart-collection) library.
 *
 * Some [Iterable] collections can be modified.
 * Adding an element to a `List` or `Set` will change which elements it
 * contains, and adding a new key to a `Map` changes the elements of [Map.keys].
 * Iterators created after the change will provide the new elements, and may
 * or may not preserve the order of existing elements
 * (for example, a [HashSet] may completely change its order when a single
 * element is added).
 *
 * Changing a collection *while* it is being iterated
 * is generally *not* allowed.
 * Doing so will break the iteration, which is typically signalled
 * by throwing a [ConcurrentModificationError]
 * the next time [Iterator.moveNext] is called.
 * The current value of [Iterator.current] getter
 * should not be affected by the change in the collection,
 * the `current` value was set by the previous call to [Iterator.moveNext].
 *
 * Some iterables compute their elements dynamically every time they are
 * iterated, like the one returned by [Iterable.generate] or the iterable
 * returned by a `sync*` generator function. If the computation doesn't depend
 * on other objects that may change, then the generated sequence should be
 * the same one every time it's iterated.
 *
 * The members of `Iterable`, other than `iterator` itself,
 * work by looking at the elements of the iterable.
 * This can be implemented by running through the [iterator], but some classes
 * may have more efficient ways of finding the result
 * (like [last] or [length] on a [List], or [contains] on a [Set]).
 *
 * The methods that return another `Iterable` (like [map] and [where])
 * are all *lazy* - they will iterate the original (as necessary)
 * every time the returned iterable is iterated, and not before.
 *
 * Since an iterable may be iterated more than once, it's not recommended to
 * have detectable side-effects in the iterator.
 * For methods like [map] and [where], the returned iterable will execute the
 * argument function on every iteration, so those functions should also not
 * have side effects.
 */
abstract class Iterable<E> {
  const Iterable();

  /**
   * Creates an `Iterable` which generates its elements dynamically.
   *
   * The generated iterable has [count] elements,
   * and the element at index `n` is computed by calling `generator(n)`.
   * Values are not cached, so each iteration computes the values again.
   *
   * If [generator] is omitted, it defaults to an identity function
   * on integers `(int x) => x`, so it may only be omitted if the type
   * parameter allows integer values. That is, if [E] is one of
   * `int`, `num`, `Object` or `dynamic`.
   *
   * As an `Iterable`, `new Iterable.generate(n, generator))` is equivalent to
   * `const [0, ..., n - 1].map(generator)`.
   */
  factory Iterable.generate(int count, [E generator(int index)]) {
    if (count <= 0) return new EmptyIterable<E>();
    return new _GeneratorIterable<E>(count, generator);
  }

  /**
   * Creates an empty iterable.
   *
   * The empty iterable has no elements, and iterating it always stops
   * immediately.
   */
  const factory Iterable.empty() = EmptyIterable<E>;

  /**
   * Returns a new `Iterator` that allows iterating the elements of this
   * `Iterable`.
   *
   * Iterable classes may specify the iteration order of their elements
   * (for example [List] always iterate in index order),
   * or they may leave it unspecified (for example a hash-based [Set]
   * may iterate in any order).
   *
   * Each time `iterator` is read, it returns a new iterator,
   * which can be used to iterate through all the elements again.
   * The iterators of the same iterable can be stepped through independently,
   * but should return the same elements in the same order,
   * as long as the underlying collection isn't changed.
   *
   * Modifying the collection may cause new iterators to produce
   * different elements, and may change the order of existing elements.
   * A [List] specifies its iteration order precisely,
   * so modifying the list changes the iteration order predictably.
   * A hash-based [Set] may change its iteration order completely
   * when adding a new element to the set.
   *
   * Modifying the underlying collection after creating the new iterator
   * may cause an error the next time [Iterator.moveNext] is called
   * on that iterator.
   * Any *modifiable* iterable class should specify which operations will
   * break iteration.
   */
  Iterator<E> get iterator;

  /**
   * Returns a new lazy [Iterable] with elements that are created by
   * calling `f` on each element of this `Iterable` in iteration order.
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [Iterable] is not iterated over, the supplied function [f] will
   * not be invoked. The transformed elements will not be cached. Iterating
   * multiple times over the returned [Iterable] will invoke the supplied
   * function [f] multiple times on the same element.
   *
   * Methods on the returned iterable are allowed to omit calling `f`
   * on any element where the result isn't needed.
   * For example, [elementAt] may call `f` only once.
   */
  Iterable<T> map<T>(T f(E e)) => new MappedIterable<E, T>(this, f);

  /**
   * Returns a new lazy [Iterable] with all elements that satisfy the
   * predicate [test].
   *
   * The matching elements have the same order in the returned iterable
   * as they have in [iterator].
   *
   * This method returns a view of the mapped elements.
   * As long as the returned [Iterable] is not iterated over,
   * the supplied function [test] will not be invoked.
   * Iterating will not cache results, and thus iterating multiple times over
   * the returned [Iterable] may invoke the supplied
   * function [test] multiple times on the same element.
   */
  Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);

  /**
   * Expands each element of this [Iterable] into zero or more elements.
   *
   * The resulting Iterable runs through the elements returned
   * by [f] for each element of this, in iteration order.
   *
   * The returned [Iterable] is lazy, and calls [f] for each element
   * of this every time it's iterated.
   *
   * Example:
   *
   *     var pairs = [[1, 2], [3, 4]];
   *     var flattened = pairs.expand((pair) => pair).toList();
   *     print(flattened); // => [1, 2, 3, 4];
   *
   *     var input = [1, 2, 3];
   *     var duplicated = input.expand((i) => [i, i]).toList();
   *     print(duplicated); // => [1, 1, 2, 2, 3, 3]
   *
   */
  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      new ExpandIterable<E, T>(this, f);

  /**
   * Returns true if the collection contains an element equal to [element].
   *
   * This operation will check each element in order for being equal to
   * [element], unless it has a more efficient way to find an element
   * equal to [element].
   *
   * The equality used to determine whether [element] is equal to an element of
   * the iterable defaults to the [Object.==] of the element.
   *
   * Some types of iterable may have a different equality used for its elements.
   * For example, a [Set] may have a custom equality
   * (see [Set.identity]) that its `contains` uses.
   * Likewise the `Iterable` returned by a [Map.keys] call
   * should use the same equality that the `Map` uses for keys.
   */
  bool contains(Object element) {
    for (E e in this) {
      if (e == element) return true;
    }
    return false;
  }

  /**
   * Applies the function [f] to each element of this collection in iteration
   * order.
   */
  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  /**
   * Reduces a collection to a single value by iteratively combining elements
   * of the collection using the provided function.
   *
   * The iterable must have at least one element.
   * If it has only one element, that element is returned.
   *
   * Otherwise this method starts with the first element from the iterator,
   * and then combines it with the remaining elements in iteration order,
   * as if by:
   *
   *     E value = iterable.first;
   *     iterable.skip(1).forEach((element) {
   *       value = combine(value, element);
   *     });
   *     return value;
   *
   * Example of calculating the sum of an iterable:
   *
   *     iterable.reduce((value, element) => value + element);
   *
   */
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

  /**
   * Reduces a collection to a single value by iteratively combining each
   * element of the collection with an existing value
   *
   * Uses [initialValue] as the initial value,
   * then iterates through the elements and updates the value with
   * each element using the [combine] function, as if by:
   *
   *     var value = initialValue;
   *     for (E element in this) {
   *       value = combine(value, element);
   *     }
   *     return value;
   *
   * Example of calculating the sum of an iterable:
   *
   *     iterable.fold(0, (prev, element) => prev + element);
   *
   */
  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  /**
   * Checks whether every element of this iterable satisfies [test].
   *
   * Checks every element in iteration order, and returns `false` if
   * any of them make [test] return `false`, otherwise returns `true`.
   */
  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  /**
   * Converts each element to a [String] and concatenates the strings.
   *
   * Iterates through elements of this iterable,
   * converts each one to a [String] by calling [Object.toString],
   * and then concatenates the strings, with the
   * [separator] string interleaved between the elements.
   */
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

  /**
   * Checks whether any element of this iterable satisfies [test].
   *
   * Checks every element in iteration order, and returns `true` if
   * any of them make [test] return `true`, otherwise returns false.
   */
  bool any(bool f(E element)) {
    for (E element in this) {
      if (f(element)) return true;
    }
    return false;
  }

  /**
   * Creates a [List] containing the elements of this [Iterable].
   *
   * The elements are in iteration order.
   * The list is fixed-length if [growable] is false.
   */
  List<E> toList({bool growable: true}) {
    return new List<E>.from(this, growable: growable);
  }

  /**
   * Creates a [Set] containing the same elements as this iterable.
   *
   * The set may contain fewer elements than the iterable,
   * if the iterable contains an element more than once,
   * or it contains one or more elements that are equal.
   * The order of the elements in the set is not guaranteed to be the same
   * as for the iterable.
   */
  Set<E> toSet() => new Set<E>.from(this);

  /**
   * Returns the number of elements in [this].
   *
   * Counting all elements may involve iterating through all elements and can
   * therefore be slow.
   * Some iterables have a more efficient way to find the number of elements.
   */
  int get length {
    assert(this is! EfficientLengthIterable);
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  /**
   * Returns `true` if there are no elements in this collection.
   *
   * May be computed by checking if `iterator.moveNext()` returns `false`.
   */
  bool get isEmpty => !iterator.moveNext();

  /**
   * Returns true if there is at least one element in this collection.
   *
   * May be computed by checking if `iterator.moveNext()` returns `true`.
   */
  bool get isNotEmpty => !isEmpty;

  /**
   * Returns a lazy iterable of the [count] first elements of this iterable.
   *
   * The returned `Iterable` may contain fewer than `count` elements, if `this`
   * contains fewer than `count` elements.
   *
   * The elements can be computed by stepping through [iterator] until [count]
   * elements have been seen.
   *
   * The `count` must not be negative.
   */
  Iterable<E> take(int count) {
    return new TakeIterable<E>(this, count);
  }

  /**
   * Returns a lazy iterable of the leading elements satisfying [test].
   *
   * The filtering happens lazily. Every new iterator of the returned
   * iterable starts iterating over the elements of `this`.
   *
   * The elements can be computed by stepping through [iterator] until an
   * element is found where `test(element)` is false. At that point,
   * the returned iterable stops (its `moveNext()` returns false).
   */
  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  /**
   * Returns an [Iterable] that provides all but the first [count] elements.
   *
   * When the returned iterable is iterated, it starts iterating over `this`,
   * first skipping past the initial [count] elements.
   * If `this` has fewer than `count` elements, then the resulting Iterable is
   * empty.
   * After that, the remaining elements are iterated in the same order as
   * in this iterable.
   *
   * Some iterables may be able to find later elements without first iterating
   * through earlier elements, for example when iterating a [List].
   * Such iterables are allowed to ignore the initial skipped elements.
   *
   * The [count] must not be negative.
   */
  Iterable<E> skip(int count) {
    return new SkipIterable<E>(this, count);
  }

  /**
   * Returns an `Iterable` that skips leading elements while [test] is satisfied.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * iterable iterates over all elements of `this`.
   *
   * The returned iterable provides elements by iterating this iterable,
   * but skipping over all initial elements where `test(element)` returns
   * true. If all elements satisfy `test` the resulting iterable is empty,
   * otherwise it iterates the remaining elements in their original order,
   * starting with the first element for which `test(element)` returns `false`.
   */
  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  /**
   * Returns the first element.
   *
   * Throws a [StateError] if `this` is empty.
   * Otherwise returns the first element in the iteration order,
   * equivalent to `this.elementAt(0)`.
   */
  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  /**
   * Returns the last element.
   *
   * Throws a [StateError] if `this` is empty.
   * Otherwise may iterate through the elements and returns the last one
   * seen.
   * Some iterables may have more efficient ways to find the last element
   * (for example a list can directly access the last element,
   * without iterating through the previous ones).
   */
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

  /**
   * Checks that this iterable has only one element, and returns that element.
   *
   * Throws a [StateError] if `this` is empty or has more than one element.
   */
  E get single {
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    if (it.moveNext()) throw IterableElementError.tooMany();
    return result;
  }

  /**
   * Returns the first element that satisfies the given predicate [test].
   *
   * Iterates through elements and returns the first to satisfy [test].
   *
   * If no element satisfies [test], the result of invoking the [orElse]
   * function is returned.
   * If [orElse] is omitted, it defaults to throwing a [StateError].
   */
  E firstWhere(bool test(E element), {E orElse()}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  /**
   * Returns the last element that satisfies the given predicate [test].
   *
   * An iterable that can access its elements directly may check its
   * elements in any order (for example a list starts by checking the
   * last element and then moves towards the start of the list).
   * The default implementation iterates elements in iteration order,
   * checks `test(element)` for each,
   * and finally returns that last one that matched.
   *
   * If no element satisfies [test], the result of invoking the [orElse]
   * function is returned.
   * If [orElse] is omitted, it defaults to throwing a [StateError].
   */
  E lastWhere(bool test(E element), {E orElse()}) {
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

  /**
   * Returns the single element that satisfies [test].
   *
   * Checks all elements to see if `test(element)` returns true.
   * If exactly one element satisfies [test], that element is returned.
   * Otherwise, if there are no matching elements, or if there is more than
   * one matching element, a [StateError] is thrown.
   */
  E singleWhere(bool test(E element)) {
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

  /**
   * Returns the [index]th element.
   *
   * The [index] must be non-negative and less than [length].
   * Index zero represents the first element (so `iterable.elementAt(0)` is
   * equivalent to `iterable.first`).
   *
   * May iterate through the elements in iteration order, skipping the
   * first `index` elements and returning the next.
   * Some iterable may have more efficient ways to find the element.
   */
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

  /**
   * Returns a string representation of (some of) the elements of `this`.
   *
   * Elements are represented by their own `toString` results.
   *
   * The default representation always contains the first three elements.
   * If there are less than a hundred elements in the iterable, it also
   * contains the last two elements.
   *
   * If the resulting string isn't above 80 characters, more elements are
   * included from the start of the iterable.
   *
   * The conversion may omit calling `toString` on some elements if they
   * are known to not occur in the output, and it may stop iterating after
   * a hundred elements.
   */
  String toString() => IterableBase.iterableToShortString(this, '(', ')');
}

typedef E _Generator<E>(int index);

class _GeneratorIterable<E> extends ListIterable<E> {
  /// The length of the generated iterable.
  final int length;

  /// The function mapping indices to values.
  final _Generator<E> _generator;

  /// Creates the generated iterable.
  ///
  /// If [generator] is `null`, it is checked that `int` is assignable to [E].
  _GeneratorIterable(this.length, E generator(int index))
      : // The `as` below is used as check to make sure that `int` is assignable
        // to [E].
        _generator = (generator != null) ? generator : _id as _Generator<E>;

  E elementAt(int index) {
    RangeError.checkValidIndex(index, this);
    return _generator(index);
  }

  /// Helper function used as default _generator function.
  static int _id(int n) => n;
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
