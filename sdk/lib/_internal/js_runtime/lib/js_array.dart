// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

class _Growable {
  const _Growable();
}

const _ListConstructorSentinel = const _Growable();

/**
 * The interceptor class for [List]. The compiler recognizes this
 * class as an interceptor, and changes references to [:this:] to
 * actually use the receiver of the method, which is generated as an extra
 * argument added to each member.
 */
class JSArray<E> extends Interceptor implements List<E>, JSIndexable {
  const JSArray();

  // This factory constructor is the redirection target of the List() factory
  // constructor. [length] has no type to permit the sentinel value.
  factory JSArray.list([length = _ListConstructorSentinel]) {
    if (_ListConstructorSentinel == length) {
      return new JSArray<E>.emptyGrowable();
    }
    return new JSArray<E>.fixed(length);
  }

  /**
   * Returns a fresh JavaScript Array, marked as fixed-length.
   *
   * [length] must be a non-negative integer.
   */
  factory JSArray.fixed(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode, and against `new Array(null)` which creates a single
    // element Array containing `null`.
    if (length is! int) {
      throw new ArgumentError.value(length, "length", "is not an integer");
    }
    // The JavaScript Array constructor with one argument throws if
    // the value is not a UInt32. Give a better error message.
    int maxJSArrayLength = 0xFFFFFFFF;
    if (length < 0 || length > maxJSArrayLength) {
      throw new RangeError.range(length, 0, maxJSArrayLength, "length");
    }
    return new JSArray<E>.markFixed(JS('', 'new Array(#)', length));
  }

  /**
   * Returns a fresh growable JavaScript Array of zero length length.
   */
  factory JSArray.emptyGrowable() => new JSArray<E>.markGrowable(JS('', '[]'));

  /**
   * Returns a fresh growable JavaScript Array with initial length.
   *
   * [validatedLength] must be a non-negative integer.
   */
  factory JSArray.growable(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode.
    if ((length is! int) || (length < 0)) {
      throw new ArgumentError("Length must be a non-negative integer: $length");
    }
    return new JSArray<E>.markGrowable(JS('', 'new Array(#)', length));
  }

  /**
   * Constructor for adding type parameters to an existing JavaScript Array.
   * The compiler specially recognizes this constructor.
   *
   *     var a = new JSArray<int>.typed(JS('JSExtendableArray', '[]'));
   *     a is List<int>    --> true
   *     a is List<String> --> false
   *
   * Usually either the [JSArray.markFixed] or [JSArray.markGrowable]
   * constructors is used instead.
   *
   * The input must be a JavaScript Array.  The JS form is just a re-assertion
   * to help type analysis when the input type is sloppy.
   */
  factory JSArray.typed(allocation) => JS('JSArray', '#', allocation);

  factory JSArray.markFixed(allocation) =>
      JS('JSFixedArray', '#', markFixedList(new JSArray<E>.typed(allocation)));

  factory JSArray.markGrowable(allocation) =>
      JS('JSExtendableArray', '#', new JSArray<E>.typed(allocation));

  static List markFixedList(List list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('void', r'#.fixed$length = Array', list);
    return JS('JSFixedArray', '#', list);
  }

  static List markUnmodifiableList(List list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('void', r'#.fixed$length = Array', list);
    JS('void', r'#.immutable$list = Array', list);
    return JS('JSUnmodifiableArray', '#', list);
  }

  checkMutable(reason) {
    if (this is! JSMutableArray) {
      throw new UnsupportedError(reason);
    }
  }

  checkGrowable(reason) {
    if (this is! JSExtendableArray) {
      throw new UnsupportedError(reason);
    }
  }

  void add(E value) {
    checkGrowable('add');
    JS('void', r'#.push(#)', this, value);
  }

  E removeAt(int index) {
    checkGrowable('removeAt');
    if (index is! int) throw argumentErrorValue(index);
    if (index < 0 || index >= length) {
      throw new RangeError.value(index);
    }
    return JS('var', r'#.splice(#, 1)[0]', this, index);
  }

  void insert(int index, E value) {
    checkGrowable('insert');
    if (index is! int) throw argumentErrorValue(index);
    if (index < 0 || index > length) {
      throw new RangeError.value(index);
    }
    JS('void', r'#.splice(#, 0, #)', this, index, value);
  }

  void insertAll(int index, Iterable<E> iterable) {
    checkGrowable('insertAll');
    RangeError.checkValueInInterval(index, 0, this.length, "index");
    if (iterable is! EfficientLengthIterable) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    this.length += insertionLength;
    int end = index + insertionLength;
    this.setRange(end, this.length, this, index);
    this.setRange(index, end, iterable);
  }

  void setAll(int index, Iterable<E> iterable) {
    checkMutable('setAll');
    RangeError.checkValueInInterval(index, 0, this.length, "index");
    for (var element in iterable) {
      this[index++] = element;
    }
  }

  E removeLast() {
    checkGrowable('removeLast');
    if (length == 0) throw diagnoseIndexError(this, -1);
    return JS('var', r'#.pop()', this);
  }

  bool remove(Object element) {
    checkGrowable('remove');
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        JS('var', r'#.splice(#, 1)', this, i);
        return true;
      }
    }
    return false;
  }

  /**
   * Removes elements matching [test] from [this] List.
   */
  void removeWhere(bool test(E element)) {
    checkGrowable('removeWhere');
    _removeWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    checkGrowable('retainWhere');
    _removeWhere(test, false);
  }

  void _removeWhere(bool test(E element), bool removeMatching) {
    // Performed in two steps, to avoid exposing an inconsistent state
    // to the [test] function. First the elements to retain are found, and then
    // the original list is updated to contain those elements.

    // TODO(sra): Replace this algorthim with one that retains a list of ranges
    // to be removed.  Most real uses remove 0, 1 or a few clustered elements.

    List retained = [];
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      // !test() ensures bool conversion in checked mode.
      if (!test(element) == removeMatching) {
        retained.add(element);
      }
      if (this.length != end) throw new ConcurrentModificationError(this);
    }
    if (retained.length == end) return;
    this.length = retained.length;
    for (int i = 0; i < retained.length; i++) {
      this[i] = retained[i];
    }
  }

  Iterable<E> where(bool f(E element)) {
    return new WhereIterable<E>(this, f);
  }

  Iterable expand(Iterable f(E element)) {
    return new ExpandIterable<E, dynamic>(this, f);
  }

  void addAll(Iterable<E> collection) {
    int i = this.length;
    checkGrowable('addAll');
    for (E e in collection) {
      assert(
          i++ == this.length || (throw new ConcurrentModificationError(this)));
      JS('void', r'#.push(#)', this, e);
    }
  }

  void clear() {
    length = 0;
  }

  void forEach(void f(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      f(element);
      if (this.length != end) throw new ConcurrentModificationError(this);
    }
  }

  Iterable map(f(E element)) {
    return new MappedListIterable(this, f);
  }

  String join([String separator = ""]) {
    var list = new List(this.length);
    for (int i = 0; i < this.length; i++) {
      list[i] = "${this[i]}";
    }
    return JS('String', "#.join(#)", list, separator);
  }

  Iterable<E> take(int n) {
    return new SubListIterable<E>(this, 0, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return new SubListIterable<E>(this, n, null);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  E reduce(E combine(E previousValue, E element)) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = this[0];
    for (int i = 1; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      value = combine(value, element);
      if (length != this.length) throw new ConcurrentModificationError(this);
    }
    return value;
  }

  fold(var initialValue, combine(var previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      value = combine(value, element);
      if (this.length != length) throw new ConcurrentModificationError(this);
    }
    return value;
  }

  E firstWhere(bool test(E value), {E orElse()}) {
    var end = this.length;
    for (int i = 0; i < end; ++i) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      if (test(element)) return element;
      if (this.length != end) throw new ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), {E orElse()}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element)) {
    int length = this.length;
    E match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    return this[index];
  }

  List<E> sublist(int start, [int end]) {
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    if (start is! int) throw argumentErrorValue(start);
    if (start < 0 || start > length) {
      throw new RangeError.range(start, 0, length, "start");
    }
    if (end == null) {
      end = length;
    } else {
      if (end is! int) throw argumentErrorValue(end);
      if (end < start || end > length) {
        throw new RangeError.range(end, start, length, "end");
      }
    }
    if (start == end) return <E>[];
    return new JSArray<E>.markGrowable(
        JS('', r'#.slice(#, #)', this, start, end));
  }

  Iterable<E> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<E>(this, start, end);
  }

  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void removeRange(int start, int end) {
    checkGrowable('removeRange');
    RangeError.checkValidRange(start, end, this.length);
    int deleteCount = end - start;
    JS('', '#.splice(#, #)', this, start, deleteCount);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    checkMutable('set range');

    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");

    List otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw IterableElementError.tooFew();
    }
    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      // TODO(sra): If [from] is the same Array as [this], we can copy without
      // type annotation checks on the stores.
      for (int i = length - 1; i >= 0; i--) {
        // Use JS to avoid bounds check (the bounds check elimination
        // optimzation is too weak). The 'E' type annotation is a store type
        // check - we can't rely on iterable, it could be List<dynamic>.
        E element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    } else {
      for (int i = 0; i < length; i++) {
        E element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    }
  }

  void fillRange(int start, int end, [E fillValue]) {
    checkMutable('fill range');
    RangeError.checkValidRange(start, end, this.length);
    for (int i = start; i < end; i++) {
      // Store is safe since [fillValue] type has been checked as parameter.
      JS('', '#[#] = #', this, i, fillValue);
    }
  }

  void replaceRange(int start, int end, Iterable<E> replacement) {
    checkGrowable('replace range');
    RangeError.checkValidRange(start, end, this.length);
    if (replacement is! EfficientLengthIterable) {
      replacement = replacement.toList();
    }
    int removeLength = end - start;
    int insertLength = replacement.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newLength = this.length - delta;
      this.setRange(start, insertEnd, replacement);
      if (delta != 0) {
        this.setRange(insertEnd, newLength, this, end);
        this.length = newLength;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = this.length + delta;
      int insertEnd = start + insertLength; // aka. end + delta.
      this.length = newLength;
      this.setRange(insertEnd, newLength, this, end);
      this.setRange(start, insertEnd, replacement);
    }
  }

  bool any(bool test(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      if (test(element)) return true;
      if (this.length != end) throw new ConcurrentModificationError(this);
    }
    return false;
  }

  bool every(bool test(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS('', '#[#]', this, i);
      if (!test(element)) return false;
      if (this.length != end) throw new ConcurrentModificationError(this);
    }
    return true;
  }

  Iterable<E> get reversed => new ReversedListIterable<E>(this);

  void sort([int compare(E a, E b)]) {
    checkMutable('sort');
    Sort.sort(this, compare == null ? Comparable.compare : compare);
  }

  void shuffle([Random random]) {
    checkMutable('shuffle');
    if (random == null) random = new Random();
    int length = this.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = this[length];
      this[length] = this[pos];
      this[pos] = tmp;
    }
  }

  int indexOf(Object element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  int lastIndexOf(Object element, [int startIndex]) {
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

  bool contains(Object other) {
    for (int i = 0; i < length; i++) {
      if (this[i] == other) return true;
    }
    return false;
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => ListBase.listToString(this);

  List<E> toList({bool growable: true}) =>
      growable ? _toListGrowable() : _toListFixed();

  List<E> _toListGrowable() =>
      new JSArray<E>.markGrowable(JS('', '#.slice()', this));

  List<E> _toListFixed() => new JSArray<E>.markFixed(JS('', '#.slice()', this));

  Set<E> toSet() => new Set<E>.from(this);

  Iterator<E> get iterator => new ArrayIterator<E>(this);

  int get hashCode => Primitives.objectHashCode(this);

  int get length => JS('JSUInt32', r'#.length', this);

  set length(int newLength) {
    checkGrowable('set length');
    if (newLength is! int) {
      throw new ArgumentError.value(newLength, 'newLength');
    }
    // TODO(sra): Remove this test and let JavaScript throw an error.
    if (newLength < 0) {
      throw new RangeError.range(newLength, 0, null, 'newLength');
    }
    // JavaScript with throw a RangeError for numbers that are too big. The
    // message does not contain the value.
    JS('void', r'#.length = #', this, newLength);
  }

  E operator [](int index) {
    if (index is! int) throw diagnoseIndexError(this, index);
    if (index >= length || index < 0) throw diagnoseIndexError(this, index);
    return JS('var', '#[#]', this, index);
  }

  void operator []=(int index, E value) {
    checkMutable('indexed set');
    if (index is! int) throw diagnoseIndexError(this, index);
    if (index >= length || index < 0) throw diagnoseIndexError(this, index);
    JS('void', r'#[#] = #', this, index, value);
  }

  Map<int, E> asMap() {
    return new ListMapView<E>(this);
  }
}

/**
 * Dummy subclasses that allow the backend to track more precise
 * information about arrays through their type. The CPA type inference
 * relies on the fact that these classes do not override [] nor []=.
 *
 * These classes are really a fiction, and can have no methods, since
 * getInterceptor always returns JSArray.  We should consider pushing the
 * 'isGrowable' and 'isMutable' checks into the getInterceptor implementation so
 * these classes can have specialized implementations. Doing so will challenge
 * many assuptions in the JS backend.
 */
class JSMutableArray<E> extends JSArray<E> implements JSMutableIndexable {}

class JSFixedArray<E> extends JSMutableArray<E> {}

class JSExtendableArray<E> extends JSMutableArray<E> {}

class JSUnmodifiableArray<E> extends JSArray<E> {} // Already is JSIndexable.

/// An [Iterator] that iterates a JSArray.
///
class ArrayIterator<E> implements Iterator<E> {
  final JSArray<E> _iterable;
  final int _length;
  int _index;
  E _current;

  ArrayIterator(JSArray<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  E get current => _current;

  bool moveNext() {
    int length = _iterable.length;

    // We have to do the length check even on fixed length Arrays.  If we can
    // inline moveNext() we might be able to GVN the length and eliminate this
    // check on known fixed length JSArray.
    if (_length != length) {
      throw throwConcurrentModificationError(_iterable);
    }

    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable[_index];
    _index++;
    return true;
  }
}
