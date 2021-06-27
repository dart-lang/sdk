// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An indexable collection of objects with a length.
///
/// Subclasses of this class implement different kinds of lists.
/// The most common kinds of lists are:
///
/// * Fixed-length list.
///   An error occurs when attempting to use operations
///   that can change the length of the list.
///
/// * Growable list. Full implementation of the API defined in this class.
///
/// The default growable list, as created by `[]`, keeps
/// an internal buffer, and grows that buffer when necessary. This guarantees
/// that a sequence of [add] operations will each execute in amortized constant
/// time. Setting the length directly may take time proportional to the new
/// length, and may change the internal capacity so that a following add
/// operation will need to immediately increase the buffer capacity.
/// Other list implementations may have different performance behavior.
///
/// The following code illustrates that some List implementations support
/// only a subset of the API.
/// ```dart
/// var fixedLengthList = List<int>.filled(5, 0);
/// fixedLengthList.length = 0;  // Error
/// fixedLengthList.add(499);    // Error
/// fixedLengthList[0] = 87;
/// var growableList = [1, 2];
/// growableList.length = 0;
/// growableList.add(499);
/// growableList[0] = 87;
/// ```
/// Lists are [Iterable]. Iteration occurs over values in index order. Changing
/// the values does not affect iteration, but changing the valid
/// indices&mdash;that is, changing the list's length&mdash;between iteration
/// steps causes a [ConcurrentModificationError]. This means that only growable
/// lists can throw ConcurrentModificationError. If the length changes
/// temporarily and is restored before continuing the iteration, the iterator
/// might not detect it.
///
/// It is generally not allowed to modify the list's length (adding or removing
/// elements) while an operation on the list is being performed,
/// for example during a call to [forEach] or [sort].
/// Changing the list's length while it is being iterated, either by iterating it
/// directly or through iterating an [Iterable] that is backed by the list, will
/// break the iteration.
abstract class List<E> implements EfficientLengthIterable<E> {
  /// Creates a list of the given length.
  ///
  /// **NOTICE**: This constructor cannot be used in null-safe code.
  /// Use [List.filled] to create a non-empty list.
  /// This requires a fill value to initialize the list elements with.
  /// To create an empty list, use `[]` for a growable list or
  /// `List.empty` for a fixed length list (or where growability is determined
  /// at run-time).
  ///
  /// The created list is fixed-length if [length] is provided.
  /// ```dart
  /// var fixedLengthList = List(3);
  /// fixedLengthList.length;     // 3
  /// fixedLengthList.length = 1; // Error
  /// ```
  /// The list has length 0 and is growable if [length] is omitted.
  /// ```dart
  /// var growableList = List();
  /// growableList.length; // 0;
  /// growableList.length = 3;
  /// ```
  /// To create a growable list with a given length, for a nullable element type,
  /// just assign the length right after creation:
  /// ```dart
  /// List<SomeNullableType> growableList = []..length = 500;
  /// ```
  /// For a non-nullable element type, an alternative is the following:
  /// ```dart
  /// List<int> growableList = List<int>.filled(500, 0, growable: true);
  /// ```
  /// The [length] must not be negative or null, if it is provided.
  ///
  /// If the element type is not nullable, [length] must not be greater than
  /// zero.
  @Deprecated("Use a list literal, [], or the List.filled constructor instead")
  external factory List([int? length]);

  /// Creates a list of the given length with [fill] at each position.
  ///
  /// The [length] must be a non-negative integer.
  ///
  /// Example:
  /// ```dart
  /// List<int>.filled(3, 0, growable: true); // [0, 0, 0]
  /// ```
  ///
  /// The created list is fixed-length if [growable] is false (the default)
  /// and growable if [growable] is true.
  /// If the list is growable, increasing its [length] will *not* initialize
  /// new entries with [fill].
  /// After being created and filled, the list is no different from any other
  /// growable or fixed-length list created
  /// using `[]` or other [List] constructors.
  ///
  /// All elements of the created list share the same [fill] value.
  /// ```dart
  /// var shared = List.filled(3, []);
  /// shared[0].add(499);
  /// print(shared);  // => [[499], [499], [499]]
  /// ```
  /// You can use [List.generate] to create a list with a fixed length
  /// and a new object at each position.
  /// ```dart
  /// var unique = List.generate(3, (_) => []);
  /// unique[0].add(499);
  /// print(unique); // => [[499], [], []]
  /// ```
  external factory List.filled(int length, E fill, {bool growable = false});

  /// Creates a new empty list.
  ///
  /// If [growable] is `false`, which is the default,
  /// the list is a fixed-length list of length zero.
  /// If [growable] is `true`, the list is growable and equivalent to `<E>[]`.
  @Since("2.9")
  external factory List.empty({bool growable = false});

  /// Creates a list containing all [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `List`, for example as:
  /// ```dart
  /// List<dynamic> dynList = ...some JSON value...;
  /// List<Map<String, dynamic>> fooList =
  ///     List.from(dynList.where((x) => x is Map && map["kind"] == "foo"));
  /// ```
  ///
  /// This constructor creates a growable list when [growable] is true;
  /// otherwise, it returns a fixed-length list.
  external factory List.from(Iterable elements, {bool growable = true});

  /// Creates a list from [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// This constructor creates a growable list when [growable] is true;
  /// otherwise, it returns a fixed-length list.
  external factory List.of(Iterable<E> elements, {bool growable = true});

  /// Generates a list of values.
  ///
  /// Creates a list with [length] positions and fills it with values created by
  /// calling [generator] for each index in the range `0` .. `length - 1`
  /// in increasing order.
  /// ```dart
  /// List<int>.generate(3, (int index) => index * index); // [0, 1, 4]
  /// ```
  /// The created list is fixed-length if [growable] is set to false.
  ///
  /// The [length] must be non-negative.
  external factory List.generate(int length, E generator(int index),
      {bool growable = true});

  /// Creates an unmodifiable list containing all [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// An unmodifiable list cannot have its length or elements changed.
  /// If the elements are themselves immutable, then the resulting list
  /// is also immutable.
  external factory List.unmodifiable(Iterable elements);

  /// Adapts [source] to be a `List<T>`.
  ///
  /// Any time the list would produce an element that is not a [T],
  /// the element access will throw.
  ///
  /// Any time a [T] value is attempted stored into the adapted list,
  /// the store will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T],
  /// and if all elements stored into the returned list are actually instance
  /// of [S],
  /// then the returned list can be used as a `List<T>`.
  static List<T> castFrom<S, T>(List<S> source) => CastList<S, T>(source);

  /// Copy a range of one list into another list.
  ///
  /// This is a utility function that can be used to implement methods like
  /// [setRange].
  ///
  /// The range from [start] to [end] must be a valid range of [source],
  /// and there must be room for `end - start` elements from position [at].
  /// If [start] is omitted, it defaults to zero.
  /// If [end] is omitted, it defaults to [source.length].
  ///
  /// If [source] and [target] is the same list, overlapping source and target
  /// ranges are respected so that the target range ends up containing the
  /// initial content of the source range.
  /// Otherwise the order of element copying is not guaranteed.
  static void copyRange<T>(List<T> target, int at, List<T> source,
      [int? start, int? end]) {
    start ??= 0;
    end = RangeError.checkValidRange(start, end, source.length);
    if (end == null) {
      // TODO(dart-lang/language#440): Remove when promotion works.
      throw "unreachable";
    }
    int length = end - start;
    if (target.length < at + length) {
      throw ArgumentError.value(target, "target",
          "Not big enough to hold $length elements at position $at");
    }
    if (!identical(source, target) || start >= at) {
      for (int i = 0; i < length; i++) {
        target[at + i] = source[start + i];
      }
    } else {
      for (int i = length; --i >= 0;) {
        target[at + i] = source[start + i];
      }
    }
  }

  /// Write the elements of an iterable into a list.
  ///
  /// This is a utility function that can be used to implement methods like
  /// [setAll].
  ///
  /// The elements of [source] are written into [target] from position [at].
  /// The [source] must not contain more elements after writing the last
  /// position of [target].
  ///
  /// If the source is a list, the [copyRange] function is likely to be more
  /// efficient.
  static void writeIterable<T>(List<T> target, int at, Iterable<T> source) {
    RangeError.checkValueInInterval(at, 0, target.length, "at");
    int index = at;
    int targetLength = target.length;
    for (var element in source) {
      if (index == targetLength) {
        throw IndexError(targetLength, target);
      }
      target[index] = element;
      index++;
    }
  }

  /// Returns a view of this list as a list of [R] instances.
  ///
  /// If this list contains only instances of [R], all read operations
  /// will work correctly. If any operation tries to access an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// Elements added to the list (e.g., by using [add] or [addAll])
  /// must be instance of [R] to be valid arguments to the adding function,
  /// and they must be instances of [E] as well to be accepted by
  /// this list as well.
  ///
  /// Typically implemented as `List.castFrom<E, R>(this)`.
  List<R> cast<R>();

  /// The object at the given [index] in the list.
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  E operator [](int index);

  /// Sets the value at the given [index] in the list to [value].
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  void operator []=(int index, E value);

  /// Updates the first position of the list to contain [value].
  ///
  /// Equivalent to `theList[0] = value;`.
  ///
  /// The list must be non-empty.
  void set first(E value);

  /// Updates the last position of the list to contain [value].
  ///
  /// Equivalent to `theList[theList.length - 1] = value;`.
  ///
  /// The list must be non-empty.
  void set last(E value);

  /// The number of objects in this list.
  ///
  /// The valid indices for a list are `0` through `length - 1`.
  int get length;

  /// Changes the length of this list.
  ///
  /// The list must be growable.
  /// If [newLength] is greater than current length,
  /// new entries are initialized to `null`,
  /// so [newLength] must not be greater than the current length
  /// if the element type [E] is non-nullable.
  set length(int newLength);

  /// Adds [value] to the end of this list,
  /// extending the length by one.
  ///
  /// The list must be growable.
  void add(E value);

  /// Appends all objects of [iterable] to the end of this list.
  ///
  /// Extends the length of the list by the number of objects in [iterable].
  /// The list must be growable.
  void addAll(Iterable<E> iterable);

  /// An [Iterable] of the objects in this list in reverse order.
  Iterable<E> get reversed;

  /// Sorts this list according to the order specified by the [compare] function.
  ///
  /// The [compare] function must act as a [Comparator].
  /// ```dart
  /// var numbers = ['two', 'three', 'four'];
  /// // Sort from shortest to longest.
  /// numbers.sort((a, b) => a.length.compareTo(b.length));
  /// print(numbers);  // [two, four, three]
  /// ```
  /// The default [List] implementations use [Comparable.compare] if
  /// [compare] is omitted.
  /// ```dart
  /// List<int> nums = [13, 2, -11];
  /// nums.sort();
  /// print(nums);  // [-11, 2, 13]
  /// ```
  /// In that case, the elements of the list must be [Comparable] to
  /// each other.
  ///
  /// A [Comparator] may compare objects as equal (return zero), even if they
  /// are distinct objects.
  /// The sort function is not guaranteed to be stable, so distinct objects
  /// that compare as equal may occur in any order in the result:
  /// ```dart
  /// var numbers = ['one', 'two', 'three', 'four'];
  /// numbers.sort((a, b) => a.length.compareTo(b.length));
  /// print(numbers);  // [one, two, four, three] OR [two, one, four, three]
  /// ```
  void sort([int compare(E a, E b)?]);

  /// Shuffles the elements of this list randomly.
  void shuffle([Random? random]);

  /// The first index of [element] in this list.
  ///
  /// Searches the list from index [start] to the end of the list.
  /// The first time an object `o` is encountered so that `o == element`,
  /// the index of `o` is returned.
  /// ```dart
  /// var notes = ['do', 're', 'mi', 're'];
  /// notes.indexOf('re');    // 1
  /// notes.indexOf('re', 2); // 3
  /// ```
  /// Returns -1 if [element] is not found.
  /// ```dart
  /// notes.indexOf('fa');    // -1
  /// ```
  int indexOf(E element, [int start = 0]);

  /// The first index in the list that satisfies the provided [test].
  ///
  /// Searches the list from index [start] to the end of the list.
  /// The first time an object `o` is encountered so that `test(o)` is true,
  /// the index of `o` is returned.
  ///
  /// ```dart
  /// var notes = ['do', 're', 'mi', 're'];
  /// notes.indexWhere((note) => note.startsWith('r'));       // 1
  /// notes.indexWhere((note) => note.startsWith('r'), 2);    // 3
  /// ```
  ///
  /// Returns -1 if [element] is not found.
  /// ```dart
  /// notes.indexWhere((note) => note.startsWith('k'));    // -1
  /// ```
  int indexWhere(bool test(E element), [int start = 0]);

  /// The last index in the list that satisfies the provided [test].
  ///
  /// Searches the list from index [start] to 0.
  /// The first time an object `o` is encountered so that `test(o)` is true,
  /// the index of `o` is returned.
  /// If [start] is omitted, it defaults to the [length] of the list.
  ///
  /// ```dart
  /// var notes = ['do', 're', 'mi', 're'];
  /// notes.lastIndexWhere((note) => note.startsWith('r'));       // 3
  /// notes.lastIndexWhere((note) => note.startsWith('r'), 2);    // 1
  /// ```
  ///
  /// Returns -1 if [element] is not found.
  /// ```dart
  /// notes.lastIndexWhere((note) => note.startsWith('k'));    // -1
  /// ```
  int lastIndexWhere(bool test(E element), [int? start]);

  /// The last index of [element] in this list.
  ///
  /// Searches the list backwards from index [start] to 0.
  ///
  /// The first time an object `o` is encountered so that `o == element`,
  /// the index of `o` is returned.
  /// ```dart
  /// var notes = ['do', 're', 'mi', 're'];
  /// notes.lastIndexOf('re', 2); // 1
  /// ```
  /// If [start] is not provided, this method searches from the end of the
  /// list.
  /// ```dart
  /// notes.lastIndexOf('re');  // 3
  /// ```
  /// Returns -1 if [element] is not found.
  /// ```dart
  /// notes.lastIndexOf('fa');  // -1
  /// ```
  int lastIndexOf(E element, [int? start]);

  /// Removes all objects from this list; the length of the list becomes zero.
  ///
  /// The list must be growable.
  void clear();

  /// Inserts [element] at position [index] in this list.
  ///
  /// This increases the length of the list by one and shifts all objects
  /// at or after the index towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  void insert(int index, E element);

  /// Inserts all objects of [iterable] at position [index] in this list.
  ///
  /// This increases the length of the list by the length of [iterable] and
  /// shifts all later objects towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  void insertAll(int index, Iterable<E> iterable);

  /// Overwrites elements with the objects of [iterable].
  ///
  /// The elements of [iterable] are written into this list,
  /// starting at position [index].
  /// ```dart
  /// var list = ['a', 'b', 'c', 'd'];
  /// list.setAll(1, ['bee', 'sea']);
  /// list.join(', '); // 'a, bee, sea, d'
  /// ```
  /// This operation does not increase the length of the list.
  ///
  /// The [index] must be non-negative and no greater than [length].
  ///
  /// The [iterable] must not have more elements than what can fit from [index]
  /// to [length].
  ///
  /// If `iterable` is based on this list, its values may change _during_ the
  /// `setAll` operation.
  void setAll(int index, Iterable<E> iterable);

  /// Removes the first occurrence of [value] from this list.
  ///
  /// Returns true if [value] was in the list, false otherwise.
  /// ```dart
  /// var parts = ['head', 'shoulders', 'knees', 'toes'];
  /// parts.remove('head'); // true
  /// parts.join(', ');     // 'shoulders, knees, toes'
  /// ```
  /// The method has no effect if [value] was not in the list.
  /// ```dart
  /// // Note: 'head' has already been removed.
  /// parts.remove('head'); // false
  /// parts.join(', ');     // 'shoulders, knees, toes'
  /// ```
  ///
  /// The list must be growable.
  bool remove(Object? value);

  /// Removes the object at position [index] from this list.
  ///
  /// This method reduces the length of `this` by one and moves all later objects
  /// down by one position.
  ///
  /// Returns the removed value.
  ///
  /// The [index] must be in the range `0 ≤ index < length`.
  ///
  /// The list must be growable.
  E removeAt(int index);

  /// Removes and returns the last object in this list.
  ///
  /// The list must be growable and non-empty.
  E removeLast();

  /// Removes all objects from this list that satisfy [test].
  ///
  /// An object `o` satisfies [test] if `test(o)` is true.
  /// ```dart
  /// var numbers = ['one', 'two', 'three', 'four'];
  /// numbers.removeWhere((item) => item.length == 3);
  /// numbers.join(', '); // 'three, four'
  /// ```
  /// The list must be growable.
  void removeWhere(bool test(E element));

  /// Removes all objects from this list that fail to satisfy [test].
  ///
  /// An object `o` satisfies [test] if `test(o)` is true.
  /// ```dart
  /// var numbers = ['one', 'two', 'three', 'four'];
  /// numbers.retainWhere((item) => item.length == 3);
  /// numbers.join(', '); // 'one, two'
  /// ```
  /// The list must be growable.
  void retainWhere(bool test(E element));

  /// Returns the concatenation of this list and [other].
  ///
  /// Returns a new list containing the elements of this list followed by
  /// the elements of [other].
  ///
  /// The default behavior is to return a normal growable list.
  /// Some list types may choose to return a list of the same type as themselves
  /// (see [Uint8List.+]);
  List<E> operator +(List<E> other);

  /// Returns a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `List<E>` containing the elements of this list at
  /// positions greater than or equal to [start] and less than [end] in the same
  /// order as they occur in this list.
  ///
  /// ```dart
  /// var colors = ["red", "green", "blue", "orange", "pink"];
  /// print(colors.sublist(1, 3)); // [green, blue]
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(colors.sublist(1)); // [green, blue, orange, pink]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ [length]
  /// If `end` is equal to `start`, then the returned list is empty.
  List<E> sublist(int start, [int? end]);

  /// Creates an [Iterable] that iterates over a range of elements.
  ///
  /// The returned iterable iterates over the elements of this list
  /// with positions greater than or equal to [start] and less than [end].
  ///
  /// The provided range, [start] and [end], must be valid at the time
  /// of the call.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The returned [Iterable] behaves like `skip(start).take(end - start)`.
  /// That is, it does *not* break if this list changes size, it just
  /// ends early if it reaches the end of the list early
  /// (if `end`, or even `start`, becomes greater than [length]).
  /// ```dart
  /// List<String> colors = ['red', 'green', 'blue', 'orange', 'pink'];
  /// Iterable<String> range = colors.getRange(1, 4);
  /// range.join(', ');  // 'green, blue, orange'
  /// colors.length = 3;
  /// range.join(', ');  // 'green, blue'
  /// ```
  Iterable<E> getRange(int start, int end);

  /// Writes some elements of [iterable] into a range of this list.
  ///
  /// Copies the objects of [iterable], skipping [skipCount] objects first,
  /// into the range from [start], inclusive, to [end], exclusive, of this list.
  /// ```dart
  /// var list1 = [1, 2, 3, 4];
  /// var list2 = [5, 6, 7, 8, 9];
  /// // Copies the 4th and 5th items in list2 as the 2nd and 3rd items
  /// // of list1.
  /// list1.setRange(1, 3, list2, 3);
  /// list1.join(', '); // '1, 8, 9, 4'
  /// ```
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The [iterable] must have enough objects to fill the range from `start`
  /// to `end` after skipping [skipCount] objects.
  ///
  /// If `iterable` is this list, the operation correctly copies the elements
  /// originally in the range from `skipCount` to `skipCount + (end - start)` to
  /// the range `start` to `end`, even if the two ranges overlap.
  ///
  /// If `iterable` depends on this list in some other way, no guarantees are
  /// made.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);

  /// Removes a range of elements from the list.
  ///
  /// Removes the elements with positions greater than or equal to [start]
  /// and less than [end], from the list.
  /// This reduces the list's length by `end - start`.
  ///
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The list must be growable.
  void removeRange(int start, int end);

  /// Overwrites a range of elements with [fillValue].
  ///
  /// Sets the positions greater than or equal to [start] and less than [end],
  /// to [fillValue].
  ///
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// Example:
  /// ```dart
  /// var list = List.filled(5, -1);
  /// print(list); //  [-1, -1, -1, -1, -1]
  /// list.fillRange(1, 3, 4);
  /// print(list); //  [-1, 4, 4, -1, -1]
  /// ```
  ///
  /// If the element type is not nullable, the [fillValue] must be provided and
  /// must be non-`null`.
  void fillRange(int start, int end, [E? fillValue]);

  /// Replaces a range of elements with the elements of [replacements].
  ///
  /// Removes the objects in the range from [start] to [end],
  /// then inserts the elements of [replacements] at [start].
  /// ```dart
  /// var list = [1, 2, 3, 4, 5];
  /// list.replaceRange(1, 4, [6, 7]);
  /// list.join(', '); // '1, 6, 7, 5'
  /// ```
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The operation `list.replaceRange(start, end, replacements)`
  /// is roughly equivalent to:
  /// ```dart
  /// list.removeRange(start, end);
  /// list.insertAll(start, replacements);
  /// ```
  /// but may be more efficient.
  ///
  /// The list must be growable.
  /// This method does not work on fixed-length lists, even when [replacements]
  /// has the same number of elements as the replaced range. In that case use
  /// [setRange] instead.
  void replaceRange(int start, int end, Iterable<E> replacements);

  /// An unmodifiable [Map] view of this list.
  ///
  /// The map uses the indices of this list as keys and the corresponding objects
  /// as values. The `Map.keys` [Iterable] iterates the indices of this list
  /// in numerical order.
  /// ```dart
  /// var words = ['fee', 'fi', 'fo', 'fum'];
  /// var map = words.asMap();  // {0: fee, 1: fi, 2: fo, 3: fum}
  /// map[0] + map[1];   // 'feefi';
  /// map.keys.toList(); // [0, 1, 2, 3]
  /// ```
  Map<int, E> asMap();

  /// Whether this list is equal to [other].
  ///
  /// Lists are, by default, only equal to themselves.
  /// Even if [other] is also a list, the equality comparison
  /// does not compare the elements of the two lists.
  bool operator ==(Object other);
}
