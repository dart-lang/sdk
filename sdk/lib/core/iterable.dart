// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A collection of values, or "elements", that can be accessed sequentially.
///
/// The elements of the iterable are accessed by getting an [Iterator]
/// using the [iterator] getter, and using it to step through the values.
/// Stepping with the iterator is done by calling [Iterator.moveNext],
/// and if the call returns `true`,
/// the iterator has now moved to the next element,
/// which is then available as [Iterator.current].
/// If the call returns `false`, there are no more elements.
/// The [Iterator.current] value must only be used when the most
/// recent call to [Iterator.moveNext] has returned `true`.
/// If it is used before calling [Iterator.moveNext] the first time
/// on an iterator, or after a call has returned false or has thrown an error,
/// reading [Iterator.current] may throw or may return an arbitrary value.
///
/// You can create more than one iterator from the same `Iterable`.
/// Each time `iterator` is read, it returns a new iterator,
/// and different iterators can be stepped through independently,
/// each giving access to all the elements of the iterable.
/// The iterators of the same iterable *should* provide the same values
/// in the same order (unless the underlying collection is modified between
/// the iterations, which some collections allow).
///
/// You can also iterate over the elements of an `Iterable`
/// using the for-in loop construct, which uses the `iterator` getter behind the
/// scenes.
/// For example, you can iterate over all of the keys of a [Map],
/// because `Map` keys are iterable.
/// ```dart
/// var kidsBooks = {'Matilda': 'Roald Dahl',
///                  'Green Eggs and Ham': 'Dr Seuss',
///                  'Where the Wild Things Are': 'Maurice Sendak'};
/// for (var book in kidsBooks.keys) {
///   print('$book was written by ${kidsBooks[book]}');
/// }
/// ```
/// The [List] and [Set] classes are both `Iterable`,
/// as are most classes in the `dart:collection` library.
///
/// Some [Iterable] collections can be modified.
/// Adding an element to a `List` or `Set` will change which elements it
/// contains, and adding a new key to a `Map` changes the elements of [Map.keys].
/// Iterators created after the change will provide the new elements, and may
/// or may not preserve the order of existing elements
/// (for example, a [HashSet] may completely change its order when a single
/// element is added).
///
/// Changing a collection *while* it is being iterated
/// is generally *not* allowed.
/// Doing so will break the iteration, which is typically signalled
/// by throwing a [ConcurrentModificationError]
/// the next time [Iterator.moveNext] is called.
/// The current value of [Iterator.current] getter
/// should not be affected by the change in the collection,
/// the `current` value was set by the previous call to [Iterator.moveNext].
///
/// Some iterables compute their elements dynamically every time they are
/// iterated, like the one returned by [Iterable.generate] or the iterable
/// returned by a `sync*` generator function. If the computation doesn't depend
/// on other objects that may change, then the generated sequence should be
/// the same one every time it's iterated.
///
/// The members of `Iterable`, other than `iterator` itself,
/// work by looking at the elements of the iterable.
/// This can be implemented by running through the [iterator], but some classes
/// may have more efficient ways of finding the result
/// (like [last] or [length] on a [List], or [contains] on a [Set]).
///
/// The methods that return another `Iterable` (like [map] and [where])
/// are all *lazy* - they will iterate the original (as necessary)
/// every time the returned iterable is iterated, and not before.
///
/// Since an iterable may be iterated more than once, it's not recommended to
/// have detectable side-effects in the iterator.
/// For methods like [map] and [where], the returned iterable will execute the
/// argument function on every iteration, so those functions should also not
/// have side effects.
abstract class Iterable<E> {
  // TODO(lrn): When we allow forwarding const constructors through
  // mixin applications, make this class implement [IterableMixin].
  const Iterable();

  /// Creates an `Iterable` which generates its elements dynamically.
  ///
  /// The generated iterable has [count] elements,
  /// and the element at index `n` is computed by calling `generator(n)`.
  /// Values are not cached, so each iteration computes the values again.
  ///
  /// If [generator] is omitted, it defaults to an identity function
  /// on integers `(int x) => x`, so it may only be omitted if the type
  /// parameter allows integer values. That is, if [E] is a super-type
  /// of [int].
  ///
  /// As an `Iterable`, `Iterable.generate(n, generator))` is equivalent to
  /// `const [0, ..., n - 1].map(generator)`.
  factory Iterable.generate(int count, [E generator(int index)?]) {
    if (count <= 0) return EmptyIterable<E>();
    return _GeneratorIterable<E>(count, generator);
  }

  /// Creates an empty iterable.
  ///
  /// The empty iterable has no elements, and iterating it always stops
  /// immediately.
  const factory Iterable.empty() = EmptyIterable<E>;

  /// Adapts [source] to be an `Iterable<T>`.
  ///
  /// Any time the iterable would produce an element that is not a [T],
  /// the element access will throw. If all elements of [source] are actually
  /// instances of [T], or if only elements that are actually instances of [T]
  /// are accessed, then the resulting iterable can be used as an `Iterable<T>`.
  static Iterable<T> castFrom<S, T>(Iterable<S> source) =>
      CastIterable<S, T>(source);

  /// Returns a new `Iterator` that allows iterating the elements of this
  /// `Iterable`.
  ///
  /// Iterable classes may specify the iteration order of their elements
  /// (for example [List] always iterate in index order),
  /// or they may leave it unspecified (for example a hash-based [Set]
  /// may iterate in any order).
  ///
  /// Each time `iterator` is read, it returns a new iterator,
  /// which can be used to iterate through all the elements again.
  /// The iterators of the same iterable can be stepped through independently,
  /// but should return the same elements in the same order,
  /// as long as the underlying collection isn't changed.
  ///
  /// Modifying the collection may cause new iterators to produce
  /// different elements, and may change the order of existing elements.
  /// A [List] specifies its iteration order precisely,
  /// so modifying the list changes the iteration order predictably.
  /// A hash-based [Set] may change its iteration order completely
  /// when adding a new element to the set.
  ///
  /// Modifying the underlying collection after creating the new iterator
  /// may cause an error the next time [Iterator.moveNext] is called
  /// on that iterator.
  /// Any *modifiable* iterable class should specify which operations will
  /// break iteration.
  Iterator<E> get iterator;

  /// Provides a view of this iterable as an iterable of [R] instances.
  ///
  /// If this iterable only contains instances of [R], all operations
  /// will work correctly. If any operation tries to access an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// When the returned iterable creates a new object that depends on
  /// the type [R], e.g., from [toList], it will have exactly the type [R].
  Iterable<R> cast<R>() => Iterable.castFrom<E, R>(this);

  /// Returns the lazy concatenation of this iterable and [other].
  ///
  /// The returned iterable will provide the same elements as this iterable,
  /// and, after that, the elements of [other], in the same order as in the
  /// original iterables.
  ///
  /// Example:
  /// ```dart
  /// var planets = <String>['Earth', 'Jupiter'];
  /// var updated = planets.followedBy(['Mars', 'Venus']);
  /// print(updated); // (Earth, Jupiter, Mars, Venus)
  /// ```
  Iterable<E> followedBy(Iterable<E> other) {
    var self = this; // TODO(lrn): Remove when we can promote `this`.
    if (self is EfficientLengthIterable<E>) {
      return FollowedByIterable<E>.firstEfficient(self, other);
    }
    return FollowedByIterable<E>(this, other);
  }

  /// The current elements of this iterable modified by [toElement].
  ///
  /// Returns a new lazy [Iterable] with elements that are created by
  /// calling `toElement` on each element of this `Iterable` in
  /// iteration order.
  ///
  /// The returned iterable is lazy, so it won't iterate the elements of
  /// this iterable until it is itself iterated, and then it will apply
  /// [toElement] to create one element at a time.
  /// The converted elements are not cached.
  /// Iterating multiple times over the returned [Iterable]
  /// will invoke the supplied [toElement] function once per element
  /// for on each iteration.
  ///
  /// Methods on the returned iterable are allowed to omit calling `toElement`
  /// on any element where the result isn't needed.
  /// For example, [elementAt] may call `toElement` only once.
  ///
  /// Equivalent to:
  /// ```
  /// Iterable<T> map<T>(T toElement(E e)) sync* {
  ///   for (var value in this) {
  ///     yield toElement(value);
  ///   }
  /// }
  /// ```
  /// Example:
  /// ```dart import:convert
  /// var products = jsonDecode('''
  /// [
  ///   {"name": "Screwdriver", "price": 42.00},
  ///   {"name": "Wingnut", "price": 0.50}
  /// ]
  /// ''');
  /// var values = products.map((product) => product['price'] as double);
  /// var totalPrice = values.fold(0.0, (a, b) => a + b); // 42.5.
  /// ```
  Iterable<T> map<T>(T toElement(E e)) => MappedIterable<E, T>(this, toElement);

  /// Returns a new lazy [Iterable] with all elements that satisfy the
  /// predicate [test].
  ///
  /// The matching elements have the same order in the returned iterable
  /// as they have in [iterator].
  ///
  /// This method returns a view of the mapped elements.
  /// As long as the returned [Iterable] is not iterated over,
  /// the supplied function [test] will not be invoked.
  /// Iterating will not cache results, and thus iterating multiple times over
  /// the returned [Iterable] may invoke the supplied
  /// function [test] multiple times on the same element.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.where((x) => x < 5); // (1, 2, 3)
  /// result = numbers.where((x) => x > 5); // (6, 7)
  /// result = numbers.where((x) => x.isEven); // (2, 6)
  /// ```
  Iterable<E> where(bool test(E element)) => WhereIterable<E>(this, test);

  /// Returns a new lazy [Iterable] with all elements that have type [T].
  ///
  /// The matching elements have the same order in the returned iterable
  /// as they have in [iterator].
  ///
  /// This method returns a view of the mapped elements.
  /// Iterating will not cache results, and thus iterating multiple times over
  /// the returned [Iterable] may yield different results,
  /// if the underlying elements change between iterations.
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  /// Expands each element of this [Iterable] into zero or more elements.
  ///
  /// The resulting Iterable runs through the elements returned
  /// by [toElements] for each element of this, in iteration order.
  ///
  /// The returned [Iterable] is lazy, and calls [toElements] for each element
  /// of this iterable every time the returned iterable is iterated.
  ///
  /// Example:
  /// ```dart
  /// Iterable<int> count(int n) sync* {
  ///   for (var i = 1; i <= n; i++) {
  ///     yield i;
  ///    }
  ///  }
  ///
  /// var numbers = [1, 3, 0, 2];
  /// print(numbers.expand(count)); // (1, 1, 2, 3, 1, 2)
  /// ```
  ///
  /// Equivalent to:
  /// ```
  /// Iterable<T> expand<T>(Iterable<T> toElements(E e)) sync* {
  ///   for (var value in this) {
  ///     yield* toElements(value);
  ///   }
  /// }
  /// ```
  Iterable<T> expand<T>(Iterable<T> toElements(E element)) =>
      ExpandIterable<E, T>(this, toElements);

  /// Whether the collection contains an element equal to [element].
  ///
  /// This operation will check each element in order for being equal to
  /// [element], unless it has a more efficient way to find an element
  /// equal to [element].
  ///
  /// The equality used to determine whether [element] is equal to an element of
  /// the iterable defaults to the [Object.==] of the element.
  ///
  /// Some types of iterable may have a different equality used for its elements.
  /// For example, a [Set] may have a custom equality
  /// (see [Set.identity]) that its `contains` uses.
  /// Likewise the `Iterable` returned by a [Map.keys] call
  /// should use the same equality that the `Map` uses for keys.
  ///
  /// Example:
  /// ```dart
  /// final gasPlanets = <int, String>{1: 'Jupiter', 2: 'Saturn'};
  /// final containsOne = gasPlanets.keys.contains(1); // true
  /// final containsFive = gasPlanets.keys.contains(5); // false
  /// final containsJupiter = gasPlanets.values.contains('Jupiter'); // true
  /// final containsMercury = gasPlanets.values.contains('Mercury'); // false
  /// ```
  bool contains(Object? element) {
    for (E e in this) {
      if (e == element) return true;
    }
    return false;
  }

  /// Invokes [action] on each element of this iterable in iteration order.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 6, 7];
  /// numbers.forEach(print);
  /// // 1
  /// // 2
  /// // 6
  /// // 7
  /// ```
  void forEach(void action(E element)) {
    for (E element in this) action(element);
  }

  /// Reduces a collection to a single value by iteratively combining elements
  /// of the collection using the provided function.
  ///
  /// The iterable must have at least one element.
  /// If it has only one element, that element is returned.
  ///
  /// Otherwise this method starts with the first element from the iterator,
  /// and then combines it with the remaining elements in iteration order,
  /// as if by:
  /// ```
  /// E value = iterable.first;
  /// iterable.skip(1).forEach((element) {
  ///   value = combine(value, element);
  /// });
  /// return value;
  /// ```
  /// Example of calculating the sum of an iterable:
  /// ```dart
  /// final numbers = <double>[10, 2, 5, 0.5];
  /// final result = numbers.reduce((value, element) => value + element);
  /// print(result); // 17.5
  /// ```
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

  /// Reduces a collection to a single value by iteratively combining each
  /// element of the collection with an existing value
  ///
  /// Uses [initialValue] as the initial value,
  /// then iterates through the elements and updates the value with
  /// each element using the [combine] function, as if by:
  /// ```
  /// var value = initialValue;
  /// for (E element in this) {
  ///   value = combine(value, element);
  /// }
  /// return value;
  /// ```
  /// Example of calculating the sum of an iterable:
  /// ```dart
  /// final numbers = <double>[10, 2, 5, 0.5];
  /// const initialValue = 100.0;
  /// final result = numbers.fold<double>(
  ///     initialValue, (previousValue, element) => previousValue + element);
  /// print(result); // 117.5
  /// ```
  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  /// Checks whether every element of this iterable satisfies [test].
  ///
  /// Checks every element in iteration order, and returns `false` if
  /// any of them make [test] return `false`, otherwise returns `true`.
  ///
  /// Example:
  /// ```dart
  /// final planetsByMass = <double, String>{0.06: 'Mercury', 0.81: 'Venus',
  ///   0.11: 'Mars'};
  /// // Checks whether all keys are smaller than 1.
  /// final every = planetsByMass.keys.every((key) => key < 1.0); // true
  /// ```
  bool every(bool test(E element)) {
    for (E element in this) {
      if (!test(element)) return false;
    }
    return true;
  }

  /// Converts each element to a [String] and concatenates the strings.
  ///
  /// Iterates through elements of this iterable,
  /// converts each one to a [String] by calling [Object.toString],
  /// and then concatenates the strings, with the
  /// [separator] string interleaved between the elements.
  ///
  /// Example:
  /// ```dart
  /// final planetsByMass = <double, String>{0.06: 'Mercury', 0.81: 'Venus',
  ///   0.11: 'Mars'};
  /// final joinedNames = planetsByMass.values.join('-'); // Mercury-Venus-Mars
  /// ```
  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write(iterator.current.toString());
      } while (iterator.moveNext());
    } else {
      buffer.write(iterator.current.toString());
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write(iterator.current.toString());
      }
    }
    return buffer.toString();
  }

  /// Checks whether any element of this iterable satisfies [test].
  ///
  /// Checks every element in iteration order, and returns `true` if
  /// any of them make [test] return `true`, otherwise returns false.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.any((element) => element >= 5); // true;
  /// result = numbers.any((element) => element >= 10); // false;
  /// ```
  bool any(bool test(E element)) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  /// Creates a [List] containing the elements of this [Iterable].
  ///
  /// The elements are in iteration order.
  /// The list is fixed-length if [growable] is false.
  ///
  /// Example:
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Mars'};
  /// final keysList = planets.keys.toList(growable: false); // [1, 2, 3]
  /// final valuesList =
  ///     planets.values.toList(growable: false); // [Mercury, Venus, Mars]
  /// ```
  List<E> toList({bool growable = true}) {
    return List<E>.of(this, growable: growable);
  }

  /// Creates a [Set] containing the same elements as this iterable.
  ///
  /// The set may contain fewer elements than the iterable,
  /// if the iterable contains an element more than once,
  /// or it contains one or more elements that are equal.
  /// The order of the elements in the set is not guaranteed to be the same
  /// as for the iterable.
  ///
  /// Example:
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Mars'};
  /// final valueSet = planets.values.toSet(); // {Mercury, Venus, Mars}
  /// ```
  Set<E> toSet() => Set<E>.of(this);

  /// Returns the number of elements in [this].
  ///
  /// Counting all elements may involve iterating through all elements and can
  /// therefore be slow.
  /// Some iterables have a more efficient way to find the number of elements.
  int get length {
    assert(this is! EfficientLengthIterable);
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  /// Whether this collection has no elements.
  ///
  /// May be computed by checking if `iterator.moveNext()` returns `false`.
  ///
  /// Example:
  /// ```dart
  /// final emptyList = <int>[];
  /// print(emptyList.isEmpty); // true;
  /// print(emptyList.iterator.moveNext()); // false
  /// ```
  bool get isEmpty => !iterator.moveNext();

  /// Whether this collection has at least one element.
  ///
  /// May be computed by checking if `iterator.moveNext()` returns `true`.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>{1, 2, 3};
  /// print(numbers.isNotEmpty); // true;
  /// print(numbers.iterator.moveNext()); // true
  /// ```
  bool get isNotEmpty => !isEmpty;

  /// Returns a lazy iterable of the [count] first elements of this iterable.
  ///
  /// The returned `Iterable` may contain fewer than `count` elements, if `this`
  /// contains fewer than `count` elements.
  ///
  /// The elements can be computed by stepping through [iterator] until [count]
  /// elements have been seen.
  ///
  /// The `count` must not be negative.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// final result = numbers.take(4); // (1, 2, 3, 5)
  /// final takeAll = numbers.take(100); // (1, 2, 3, 5, 6, 7)
  /// ```
  Iterable<E> take(int count) {
    return TakeIterable<E>(this, count);
  }

  /// Returns a lazy iterable of the leading elements satisfying [test].
  ///
  /// The filtering happens lazily. Every new iterator of the returned
  /// iterable starts iterating over the elements of `this`.
  ///
  /// The elements can be computed by stepping through [iterator] until an
  /// element is found where `test(element)` is false. At that point,
  /// the returned iterable stops (its `moveNext()` returns false).
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.takeWhile((x) => x < 5); // (1, 2, 3)
  /// result = numbers.takeWhile((x) => x != 3); // (1, 2)
  /// result = numbers.takeWhile((x) => x != 4); // (1, 2, 3, 5, 6, 7)
  /// result = numbers.takeWhile((x) => x.isOdd); // (1)
  /// ```
  Iterable<E> takeWhile(bool test(E value)) {
    return TakeWhileIterable<E>(this, test);
  }

  /// Returns an [Iterable] that provides all but the first [count] elements.
  ///
  /// When the returned iterable is iterated, it starts iterating over `this`,
  /// first skipping past the initial [count] elements.
  /// If `this` has fewer than `count` elements, then the resulting Iterable is
  /// empty.
  /// After that, the remaining elements are iterated in the same order as
  /// in this iterable.
  ///
  /// Some iterables may be able to find later elements without first iterating
  /// through earlier elements, for example when iterating a [List].
  /// Such iterables are allowed to ignore the initial skipped elements.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// final result = numbers.skip(4); // (6, 7)
  /// final skipAll = numbers.skip(100); // () - no elements.
  /// ```
  ///
  /// The [count] must not be negative.
  Iterable<E> skip(int count) {
    return SkipIterable<E>(this, count);
  }

  /// Returns an `Iterable` that skips leading elements while [test] is satisfied.
  ///
  /// The filtering happens lazily. Every new [Iterator] of the returned
  /// iterable iterates over all elements of `this`.
  ///
  /// The returned iterable provides elements by iterating this iterable,
  /// but skipping over all initial elements where `test(element)` returns
  /// true. If all elements satisfy `test` the resulting iterable is empty,
  /// otherwise it iterates the remaining elements in their original order,
  /// starting with the first element for which `test(element)` returns `false`.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.skipWhile((x) => x < 5); // (5, 6, 7)
  /// result = numbers.skipWhile((x) => x != 3); // (3, 5, 6, 7)
  /// result = numbers.skipWhile((x) => x != 4); // ()
  /// result = numbers.skipWhile((x) => x.isOdd); // (2, 3, 5, 6, 7)
  /// ```
  Iterable<E> skipWhile(bool test(E value)) {
    return SkipWhileIterable<E>(this, test);
  }

  /// Returns the first element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise returns the first element in the iteration order,
  /// equivalent to `this.elementAt(0)`.
  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  /// Returns the last element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise may iterate through the elements and returns the last one
  /// seen.
  /// Some iterables may have more efficient ways to find the last element
  /// (for example a list can directly access the last element,
  /// without iterating through the previous ones).
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

  /// Checks that this iterable has only one element, and returns that element.
  ///
  /// Throws a [StateError] if `this` is empty or has more than one element.
  E get single {
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    if (it.moveNext()) throw IterableElementError.tooMany();
    return result;
  }

  /// Returns the first element that satisfies the given predicate [test].
  ///
  /// Iterates through elements and returns the first to satisfy [test].
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.firstWhere((element) => element < 5); // 1
  /// result = numbers.firstWhere((element) => element > 5); // 6
  /// result =
  ///     numbers.firstWhere((element) => element > 10, orElse: () => -1); // -1
  /// ```
  ///
  /// If no element satisfies [test], the result of invoking the [orElse]
  /// function is returned.
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  E firstWhere(bool test(E element), {E orElse()?}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  /// Returns the last element that satisfies the given predicate [test].
  ///
  /// An iterable that can access its elements directly may check its
  /// elements in any order (for example a list starts by checking the
  /// last element and then moves towards the start of the list).
  /// The default implementation iterates elements in iteration order,
  /// checks `test(element)` for each,
  /// and finally returns that last one that matched.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.lastWhere((element) => element < 5); // 3
  /// result = numbers.lastWhere((element) => element > 5); // 7
  /// result = numbers.lastWhere((element) => element > 10,
  ///     orElse: () => -1); // -1
  /// ```
  ///
  /// If no element satisfies [test], the result of invoking the [orElse]
  /// function is returned.
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  E lastWhere(bool test(E element), {E orElse()?}) {
    late E result;
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

  /// Returns the single element that satisfies [test].
  ///
  /// Checks elements to see if `test(element)` returns true.
  /// If exactly one element satisfies [test], that element is returned.
  /// If more than one matching element is found, throws [StateError].
  /// If no matching element is found, returns the result of [orElse].
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[2, 2, 10];
  /// var result = numbers.singleWhere((element) => element > 5); // 10
  /// ```
  /// When no matching element is found, the result of calling [orElse] is
  /// returned instead.
  /// ```dart continued
  /// result = numbers.singleWhere((element) => element == 1,
  ///     orElse: () => -1); // -1
  /// ```
  /// There must not be more than one matching element.
  /// ```dart continued
  /// result = numbers.singleWhere((element) => element == 2); // Throws Error.
  /// ```
  E singleWhere(bool test(E element), {E orElse()?}) {
    late E result;
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
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  /// Returns the [index]th element.
  ///
  /// The [index] must be non-negative and less than [length].
  /// Index zero represents the first element (so `iterable.elementAt(0)` is
  /// equivalent to `iterable.first`).
  ///
  /// May iterate through the elements in iteration order, ignoring the
  /// first [index] elements and then returning the next.
  /// Some iterables may have a more efficient way to find the element.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// final elementAt = numbers.elementAt(4); // 6
  /// ```
  E elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    int elementIndex = 0;
    for (E element in this) {
      if (index == elementIndex) return element;
      elementIndex++;
    }
    throw IndexError.withLength(index, elementIndex,
        indexable: this, name: "index");
  }

  /// Returns a string representation of (some of) the elements of `this`.
  ///
  /// Elements are represented by their own `toString` results.
  ///
  /// The default representation always contains the first three elements.
  /// If there are less than a hundred elements in the iterable, it also
  /// contains the last two elements.
  ///
  /// If the resulting string isn't above 80 characters, more elements are
  /// included from the start of the iterable.
  ///
  /// The conversion may omit calling `toString` on some elements if they
  /// are known to not occur in the output, and it may stop iterating after
  /// a hundred elements.
  String toString() => IterableBase.iterableToShortString(this, '(', ')');
}

class _GeneratorIterable<E> extends ListIterable<E> {
  /// The length of the generated iterable.
  final int length;

  /// The function mapping indices to values.
  final E Function(int) _generator;

  /// Creates the generated iterable.
  ///
  /// If [generator] is `null`, it is checked that `int` is assignable to [E].
  _GeneratorIterable(this.length, E generator(int index)?)
      : // The `as` below is used as check to make sure that `int` is assignable
        // to [E].
        _generator = generator ?? (_id as E Function(int));

  E elementAt(int index) {
    IndexError.check(index, length, indexable: this);
    return _generator(index);
  }

  /// Helper function used as default _generator function.
  static int _id(int n) => n;
}

/// An [Iterator] that allows moving backwards as well as forwards.
///
/// Deprecation note: This interface has turned out to not be
/// valuable as a general reusable interface. There is still only
/// one class implementing it, [RuneIterator], and at least one other
/// bidirectional iterator preferred a different name than `movePrevious`
/// for the other direction.
/// As such, this interface does not carry its own weight, and will be
/// removed in a later release.
@Deprecated("Use the implementing class directly")
abstract class BidirectionalIterator<E> implements Iterator<E> {
  /// Move back to the previous element.
  ///
  /// Returns true and updates [current] if successful. Returns false
  /// and updates [current] to an implementation defined state if there is no
  /// previous element
  bool movePrevious();
}
