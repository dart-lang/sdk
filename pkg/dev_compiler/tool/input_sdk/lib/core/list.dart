// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An indexable collection of objects with a length.
 *
 * Subclasses of this class implement different kinds of lists.
 * The most common kinds of lists are:
 *
 * * Fixed-length list.
 *   An error occurs when attempting to use operations
 *   that can change the length of the list.
 *
 * * Growable list. Full implementation of the API defined in this class.
 *
 * The default growable list, as returned by `new List()` or `[]`, keeps
 * an internal buffer, and grows that buffer when necessary. This guarantees
 * that a sequence of [add] operations will each execute in amortized constant
 * time. Setting the length directly may take time proportional to the new
 * length, and may change the internal capacity so that a following add
 * operation will need to immediately increase the buffer capacity.
 * Other list implementations may have different performance behavior.
 *
 * The following code illustrates that some List implementations support
 * only a subset of the API.
 *
 *     List<int> fixedLengthList = new List(5);
 *     fixedLengthList.length = 0;  // Error
 *     fixedLengthList.add(499);    // Error
 *     fixedLengthList[0] = 87;
 *     List<int> growableList = [1, 2];
 *     growableList.length = 0;
 *     growableList.add(499);
 *     growableList[0] = 87;
 *
 * Lists are [Iterable]. Iteration occurs over values in index order. Changing
 * the values does not affect iteration, but changing the valid
 * indices&mdash;that is, changing the list's length&mdash;between iteration
 * steps causes a [ConcurrentModificationError]. This means that only growable
 * lists can throw ConcurrentModificationError. If the length changes
 * temporarily and is restored before continuing the iteration, the iterator
 * does not detect it.
 *
 * It is generally not allowed to modify the list's length (adding or removing
 * elements) while an operation on the list is being performed,
 * for example during a call to [forEach] or [sort].
 * Changing the list's length while it is being iterated, either by iterating it
 * directly or through iterating an [Iterable] that is backed by the list, will
 * break the iteration.
 */
@SupportJsExtensionMethod()
@JsPeerInterface(name: 'Array')
abstract class List<E> implements Iterable<E>, EfficientLength {
  /**
   * Creates a list of the given length.
   *
   * The created list is fixed-length if [length] is provided.
   *
   *     List fixedLengthList = new List(3);
   *     fixedLengthList.length;     // 3
   *     fixedLengthList.length = 1; // Error
   *
   * The list has length 0 and is growable if [length] is omitted.
   *
   *     List growableList = new List();
   *     growableList.length; // 0;
   *     growableList.length = 3;
   *
   * To create a growable list with a given length, just assign the length
   * right after creation:
   *
   *     List growableList = new List()..length = 500;
   *
   * The [length] must not be negative or null, if it is provided.
   */
  external factory List([int length]);

  /**
   * Creates a fixed-length list of the given length, and initializes the
   * value at each position with [fill]:
   *
   *     new List<int>.filled(3, 0); // [0, 0, 0]
   *
   * The [length] must not be negative or null.
   */
  external factory List.filled(int length, E fill);

  /**
   * Creates a list containing all [elements].
   *
   * The [Iterator] of [elements] provides the order of the elements.
   *
   * This constructor returns a growable list when [growable] is true;
   * otherwise, it returns a fixed-length list.
   */
  external factory List.from(Iterable elements, { bool growable: true });

  /**
   * Generates a list of values.
   *
   * Creates a list with [length] positions and fills it with values created by
   * calling [generator] for each index in the range `0` .. `length - 1`
   * in increasing order.
   *
   *     new List<int>.generate(3, (int index) => index * index); // [0, 1, 4]
   *
   * The created list is fixed-length unless [growable] is true.
   */
  factory List.generate(int length, E generator(int index),
                       { bool growable: true }) {
    List<E> result;
    if (growable) {
      result = <E>[]..length = length;
    } else {
      result = new List<E>(length);
    }
    for (int i = 0; i < length; i++) {
      result[i] = generator(i);
    }
    return result;
  }

  checkMutable(reason) {
    /* TODO(jacobr): implement.
    if (this is !JSMutableArray) {
      throw new UnsupportedError(reason);
    }
    * */
  }

  checkGrowable(reason) {
    /* TODO(jacobr): implement
    if (this is !JSExtendableArray) {
      throw new UnsupportedError(reason);
    }
    * */
  }

  Iterable<E> where(bool f(E element)) {
    return new IterableMixinWorkaround<E>().where(this, f);
  }

  Iterable expand(Iterable f(E element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  void forEach(void f(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      f(JS('', '#[#]', this, i));
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  Iterable map(f(E element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator = ""]) {
    var list = new List(this.length);
    for (int i = 0; i < this.length; i++) {
      list[i] = "${this[i]}";
    }
    return JS('String', "#.join(#)", list, separator);
  }

  Iterable<E> take(int n) {
    return new IterableMixinWorkaround<E>().takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new IterableMixinWorkaround<E>().takeWhile(this, test);
  }

  Iterable<E> skip(int n) {
    return new IterableMixinWorkaround<E>().skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new IterableMixinWorkaround<E>().skipWhile(this, test);
  }

  E reduce(E combine(E value, E element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  fold(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  E firstWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  E lastWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  E singleWhere(bool test(E value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  E get first {
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  bool any(bool f(E element)) => IterableMixinWorkaround.any(this, f);

  bool every(bool f(E element)) => IterableMixinWorkaround.every(this, f);

  bool contains(Object other) {
    for (int i = 0; i < length; i++) {
      if (this[i] == other) return true;
    }
    return false;
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => ListBase.listToString(this);

  List<E> toList({ bool growable: true }) {
    if (growable) {
      return new JSArray<E>.markGrowable(JS('', '#.slice()', this));
    } else {
      return new JSArray<E>.markFixed(JS('', '#.slice()', this));
    }
  }

  Set<E> toSet() => new Set<E>.from(this);

  Iterator<E> get iterator => new ListIterator<E>(this);

  int get hashCode => Primitives.objectHashCode(this);

  // BORDER XXXX

  /**
   * Returns the object at the given [index] in the list
   * or throws a [RangeError] if [index] is out of bounds.
   */
  E operator [](int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    return JS('var', '#[#]', this, index);
  }

  /**
   * Sets the value at the given [index] in the list to [value]
   * or throws a [RangeError] if [index] is out of bounds.
   */
  void operator []=(int index, E value) {
    checkMutable('indexed set');
    if (index is !int) throw new ArgumentError(index);
    if (index >= length || index < 0) throw new RangeError.value(index);
    JS('void', r'#[#] = #', this, index, value);
  }

  /**
   * Returns the number of objects in this list.
   *
   * The valid indices for a list are `0` through `length - 1`.
   */
  int get length => JS('JSUInt32', r'#.length', this);

  /**
   * Changes the length of this list.
   *
   * If [newLength] is greater than
   * the current length, entries are initialized to [:null:].
   *
   * Throws an [UnsupportedError] if the list is fixed-length.
   */
  void set length(int newLength) {
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new RangeError.value(newLength);
    checkGrowable('set length');
    JS('void', r'#.length = #', this, newLength);
  }

  /**
   * Adds [value] to the end of this list,
   * extending the length by one.
   *
   * Throws an [UnsupportedError] if the list is fixed-length.
   */
  void add(E value) {
    checkGrowable('add');
    JS('void', r'#.push(#)', this, value);
  }

  /**
   * Appends all objects of [iterable] to the end of this list.
   *
   * Extends the length of the list by the number of objects in [iterable].
   * Throws an [UnsupportedError] if this list is fixed-length.
   */
  void addAll(Iterable<E> iterable) {
    for (E e in iterable) {
      this.add(e);
    }
  }

  /**
   * Returns an [Iterable] of the objects in this list in reverse order.
   */
  Iterable<E> get reversed =>
      new IterableMixinWorkaround<E>().reversedList(this);

  /**
   * Sorts this list according to the order specified by the [compare] function.
   *
   * The [compare] function must act as a [Comparator].

   *     List<String> numbers = ['one', 'two', 'three', 'four'];
   *     // Sort from shortest to longest.
   *     numbers.sort((x, y) => x.length.compareTo(y.length));
   *     numbers.join(', '); // 'one, two, four, three'
   *
   * The default List implementations use [Comparable.compare] if
   * [compare] is omitted.
   *
   *     List<int> nums = [13, 2, -11];
   *     nums.sort();
         nums.join(', '); // '-11, 2, 13'
   */
  void sort([int compare(E a, E b)]) {
    checkMutable('sort');
    IterableMixinWorkaround.sortList(this, compare);
  }

  /**
   * Shuffles the elements of this list randomly.
   */
  void shuffle([Random random]) {
    IterableMixinWorkaround.shuffleList(this, random);
  }

  /**
   * Returns the first index of [element] in this list.
   *
   * Searches the list from index [start] to the end of the list.
   * The first time an object [:o:] is encountered so that [:o == element:],
   * the index of [:o:] is returned.
   *
   *     List<String> notes = ['do', 're', 'mi', 're'];
   *     notes.indexOf('re');    // 1
   *     notes.indexOf('re', 2); // 3
   *
   * Returns -1 if [element] is not found.
   *
   *     notes.indexOf('fa');    // -1
   */
  int indexOf(E element, [int start = 0]) {
    return IterableMixinWorkaround.indexOfList(this, element, start);
  }

  /**
   * Returns the last index of [element] in this list.
   *
   * Searches the list backwards from index [start] to 0.
   *
   * The first time an object [:o:] is encountered so that [:o == element:],
   * the index of [:o:] is returned.
   *
   *     List<String> notes = ['do', 're', 'mi', 're'];
   *     notes.lastIndexOf('re', 2); // 1
   *
   * If [start] is not provided, this method searches from the end of the
   * list./Returns
   *
   *     notes.lastIndexOf('re');  // 3
   *
   * Returns -1 if [element] is not found.
   *
   *     notes.lastIndexOf('fa');  // -1
   */
  int lastIndexOf(E element, [int start]) {
    return IterableMixinWorkaround.lastIndexOfList(this, element, start);
  }

  /**
   * Removes all objects from this list;
   * the length of the list becomes zero.
   *
   * Throws an [UnsupportedError], and retains all objects, if this
   * is a fixed-length list.
   */
  void clear() {
    length = 0;
  }

  /**
   * Inserts the object at position [index] in this list.
   *
   * This increases the length of the list by one and shifts all objects
   * at or after the index towards the end of the list.
   *
   * An error occurs if the [index] is less than 0 or greater than length.
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  void insert(int index, E element) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index > length) {
      throw new RangeError.value(index);
    }
    checkGrowable('insert');
    JS('void', r'#.splice(#, 0, #)', this, index, element);
  }


  /**
   * Inserts all objects of [iterable] at position [index] in this list.
   *
   * This increases the length of the list by the length of [iterable] and
   * shifts all later objects towards the end of the list.
   *
   * An error occurs if the [index] is less than 0 or greater than length.
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  void insertAll(int index, Iterable<E> iterable) {
    checkGrowable('insertAll');
    IterableMixinWorkaround.insertAllList(this, index, iterable);
  }

  /**
   * Overwrites objects of `this` with the objects of [iterable], starting
   * at position [index] in this list.
   *
   *     List<String> list = ['a', 'b', 'c'];
   *     list.setAll(1, ['bee', 'sea']);
   *     list.join(', '); // 'a, bee, sea'
   *
   * This operation does not increase the length of `this`.
   *
   * The [index] must be non-negative and no greater than [length].
   *
   * The [iterable] must not have more elements than what can fit from [index]
   * to [length].
   *
   * If `iterable` is based on this list, its values may change /during/ the
   * `setAll` operation.
   */
  void setAll(int index, Iterable<E> iterable) {
    checkMutable('setAll');
    IterableMixinWorkaround.setAllList(this, index, iterable);
  }

  /**
   * Removes the first occurence of [value] from this list.
   *
   * Returns true if [value] was in the list, false otherwise.
   *
   *     List<String> parts = ['head', 'shoulders', 'knees', 'toes'];
   *     parts.remove('head'); // true
   *     parts.join(', ');     // 'shoulders, knees, toes'
   *
   * The method has no effect if [value] was not in the list.
   *
   *     // Note: 'head' has already been removed.
   *     parts.remove('head'); // false
   *     parts.join(', ');     // 'shoulders, knees, toes'
   *
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  bool remove(Object element) {
    checkGrowable('remove');
    for (int i = 0; i < this.length; i++) {
      if (this[i] == value) {
        JS('var', r'#.splice(#, 1)', this, i);
        return true;
      }
    }
    return false;
  }

  /**
   * Removes the object at position [index] from this list.
   *
   * This method reduces the length of `this` by one and moves all later objects
   * down by one position.
   *
   * Returns the removed object.
   *
   * The [index] must be in the range `0 ≤ index < length`.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list. In that case
   * the list is not modified.
   */
  E removeAt(int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index >= length) {
      throw new RangeError.value(index);
    }
    checkGrowable('removeAt');
    return JS('var', r'#.splice(#, 1)[0]', this, index);
  }

  /**
   * Pops and returns the last object in this list.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  E removeLast() {
    checkGrowable('removeLast');
    if (length == 0) throw new RangeError.value(-1);
    return JS('var', r'#.pop()', this);
  }

  /**
   * Removes all objects from this list that satisfy [test].
   *
   * An object [:o:] satisfies [test] if [:test(o):] is true.
   *
   *     List<String> numbers = ['one', 'two', 'three', 'four'];
   *     numbers.removeWhere((item) => item.length == 3);
   *     numbers.join(', '); // 'three, four'
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  void removeWhere(bool test(E element)) {
    // This could, and should, be optimized.
    IterableMixinWorkaround.removeWhereList(this, test);
  }


  /**
   * Removes all objects from this list that fail to satisfy [test].
   *
   * An object [:o:] satisfies [test] if [:test(o):] is true.
   *
   *     List<String> numbers = ['one', 'two', 'three', 'four'];
   *     numbers.retainWhere((item) => item.length == 3);
   *     numbers.join(', '); // 'one, two'
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  void retainWhere(bool test(E element)) {
    IterableMixinWorkaround.removeWhereList(this,
                                            (E element) => !test(element));
  }

  /**
   * Returns a new list containing the objects from [start] inclusive to [end]
   * exclusive.
   *
   *     List<String> colors = ['red', 'green', 'blue', 'orange', 'pink'];
   *     colors.sublist(1, 3); // ['green', 'blue']
   *
   * If [end] is omitted, the [length] of `this` is used.
   *
   *     colors.sublist(1);  // ['green', 'blue', 'orange', 'pink']
   *
   * An error occurs if [start] is outside the range `0` .. `length` or if
   * [end] is outside the range `start` .. `length`.
   */
  List<E> sublist(int start, [int end]) {
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (start < 0 || start > length) {
      throw new RangeError.range(start, 0, length);
    }
    if (end == null) {
      end = length;
    } else {
      if (end is !int) throw new ArgumentError(end);
      if (end < start || end > length) {
        throw new RangeError.range(end, start, length);
      }
    }
    if (start == end) return <E>[];
    return new JSArray<E>.markGrowable(
        JS('', r'#.slice(#, #)', this, start, end));
  }

  /**
   * Returns an [Iterable] that iterates over the objects in the range
   * [start] inclusive to [end] exclusive.
   *
   * An error occurs if [end] is before [start].
   *
   * An error occurs if the [start] and [end] are not valid ranges at the time
   * of the call to this method. The returned [Iterable] behaves like
   * `skip(start).take(end - start)`. That is, it does not throw exceptions
   * if `this` changes size.
   *
   *     List<String> colors = ['red', 'green', 'blue', 'orange', 'pink'];
   *     Iterable<String> range = colors.getRange(1, 4);
   *     range.join(', ');  // 'green, blue, orange'
   *     colors.length = 3;
   *     range.join(', ');  // 'green, blue'
   */
  Iterable<E> getRange(int start, int end) {
    return new IterableMixinWorkaround<E>().getRangeList(this, start, end);
  }


  /**
   * Copies the objects of [iterable], skipping [skipCount] objects first,
   * into the range [start], inclusive, to [end], exclusive, of the list.
   *
   *     List<int> list1 = [1, 2, 3, 4];
   *     List<int> list2 = [5, 6, 7, 8, 9];
   *     // Copies the 4th and 5th items in list2 as the 2nd and 3rd items
   *     // of list1.
   *     list1.setRange(1, 3, list2, 3);
   *     list1.join(', '); // '1, 8, 9, 4'
   *
   * The [start] and [end] indices must satisfy `0 ≤ start ≤ end ≤ length`.
   * If [start] equals [end], this method has no effect.
   *
   * The [iterable] must have enough objects to fill the range from `start`
   * to `end` after skipping [skipCount] objects.
   *
   * If `iterable` is this list, the operation will copy the elements originally
   * in the range from `skipCount` to `skipCount + (end - start)` to the
   * range `start` to `end`, even if the two ranges overlap.
   *
   * If `iterable` depends on this list in some other way, no guarantees are
   * made.
   */
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    checkMutable('set range');
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive.
   *
   * The [start] and [end] indices must be in the range
   * `0 ≤ index ≤ length`, and `start ≤ end`.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list. In that case
   * the list is not modified.
   */
  void removeRange(int start, int end) {
    checkGrowable('removeRange');
    int receiverLength = this.length;
    if (start < 0 || start > receiverLength) {
      throw new RangeError.range(start, 0, receiverLength);
    }
    if (end < start || end > receiverLength) {
      throw new RangeError.range(end, start, receiverLength);
    }
    Lists.copy(this,
               end,
               this,
               start,
               receiverLength - end);
    this.length = receiverLength - (end - start);
  }

  /**
   * Sets the objects in the range [start] inclusive to [end] exclusive
   * to the given [fillValue].
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
   */
  void fillRange(int start, int end, [E fillValue]) {
    checkMutable('fill range');
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive
   * and inserts the contents of [replacement] in its place.
   *
   *     List<int> list = [1, 2, 3, 4, 5];
   *     list.replaceRange(1, 4, [6, 7]);
   *     list.join(', '); // '1, 6, 7, 5'
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
   */
  void replaceRange(int start, int end, Iterable<E> replacement) {
    checkGrowable('removeRange');
    IterableMixinWorkaround.replaceRangeList(this, start, end, replacement);
  }

  /**
   * Returns an unmodifiable [Map] view of `this`.
   *
   * The map uses the indices of this list as keys and the corresponding objects
   * as values. The `Map.keys` [Iterable] iterates the indices of this list
   * in numerical order.
   *
   *     List<String> words = ['fee', 'fi', 'fo', 'fum'];
   *     Map<int, String> map = words.asMap();
   *     map[0] + map[1];   // 'feefi';
   *     map.keys.toList(); // [0, 1, 2, 3]
   */
  Map<int, E> asMap() {
    return new IterableMixinWorkaround<E>().asMapList(this);
  }
}
