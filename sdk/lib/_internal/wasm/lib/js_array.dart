// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

// TODO(joshualitt): Refactor indexing here and in `js_string` to elide range
// checks for internal functions.
class JSArrayImpl implements List<JSAny?> {
  final WasmExternRef? _ref;

  JSArrayImpl(this._ref);

  static JSArrayImpl? box(WasmExternRef? ref) =>
      js.isDartNull(ref) ? null : JSArrayImpl(ref);

  WasmExternRef? get toExternRef => _ref;

  @override
  List<R> cast<R>() => List.castFrom<JSAny?, R>(this);

  @override
  void add(JSAny? value) =>
      js.JS<void>('(a, i) => a.push(i)', toExternRef, value?.toExternRef);

  @override
  JSAny? removeAt(int index) {
    RangeError.checkValueInInterval(index, 0, length - 1);
    return js.JSValue.boxT<JSAny?>(js.JS<WasmExternRef?>(
        '(a, i) => a.splice(i, 1)[0]', toExternRef, index.toJS.toExternRef));
  }

  @override
  void insert(int index, JSAny? value) {
    RangeError.checkValueInInterval(index, 0, length);
    js.JS<void>('(a, i, v) => a.splice(i, 0, v)', toExternRef,
        index.toJS.toExternRef, value?.toExternRef);
  }

  void _setLengthUnsafe(int newLength) => js.JS<void>(
      '(a, l) => a.length = l', toExternRef, newLength.toJS.toExternRef);

  @override
  void insertAll(int index, Iterable<JSAny?> iterable) {
    RangeError.checkValueInInterval(index, 0, length);
    final that =
        iterable is EfficientLengthIterable ? iterable : iterable.toList();
    final thatLength = that.length;
    _setLengthUnsafe(length + thatLength);
    final end = index + thatLength;
    setRange(end, length, this, index);
    setRange(index, end, iterable);
  }

  @override
  void setAll(int index, Iterable<JSAny?> iterable) {
    RangeError.checkValueInInterval(index, 0, length);
    for (final element in iterable) {
      this[index++] = element;
    }
  }

  @override
  JSAny? removeLast() => js.JSValue.boxT<JSAny?>(
      js.JS<WasmExternRef?>('a => a.pop()', toExternRef));

  @override
  bool remove(Object? element) {
    for (var i = 0; i < length; i++) {
      if (this[i] == element) {
        js.JS<void>(
            '(a, i) => a.splice(i, 1)', toExternRef, i.toJS.toExternRef);
        return true;
      }
    }
    return false;
  }

  @override
  void removeWhere(bool Function(JSAny?) test) => _retainWhere(test, false);

  @override
  void retainWhere(bool Function(JSAny?) test) => _retainWhere(test, true);

  void _retainWhere(bool Function(JSAny?) test, bool retainMatching) {
    final retained = <JSAny?>[];
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (test(element) == retainMatching) {
        retained.add(element);
      }
      if (length != end) throw ConcurrentModificationError(this);
    }
    if (retained.length == end) return;
    final newLength = retained.length;
    _setLengthUnsafe(newLength);
    for (var i = 0; i < newLength; i++) {
      this[i] = retained[i];
    }
  }

  @override
  Iterable<JSAny?> where(bool Function(JSAny?) f) {
    return WhereIterable<JSAny?>(this, f);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(JSAny?) f) {
    return ExpandIterable<JSAny?, T>(this, f);
  }

  @override
  void addAll(Iterable<JSAny?> collection) {
    for (final v in collection) {
      add(v);
    }
  }

  @override
  void clear() {
    _setLengthUnsafe(0);
  }

  @override
  void forEach(void Function(JSAny?) f) {
    final end = length;
    for (var i = 0; i < end; i++) {
      f(this[i]);
      if (length != end) throw ConcurrentModificationError(this);
    }
  }

  @override
  Iterable<T> map<T>(T Function(JSAny?) f) =>
      MappedListIterable<JSAny?, T>(this, f);

  @override
  String join([String separator = ""]) {
    WasmExternRef? result;
    if (separator is JSStringImpl) {
      result = js.JS<WasmExternRef?>(
          '(a, s) => a.join(s)', toExternRef, separator.toExternRef);
    } else {
      result = js.JS<WasmExternRef?>(
          '(a, s) => a.join(s)', toExternRef, separator.toJS.toExternRef);
    }
    return JSStringImpl(result);
  }

  @override
  Iterable<JSAny?> take(int n) => SubListIterable<JSAny?>(this, 0, n);

  @override
  Iterable<JSAny?> takeWhile(bool test(JSAny? value)) =>
      TakeWhileIterable<JSAny?>(this, test);

  @override
  Iterable<JSAny?> skip(int n) => SubListIterable<JSAny?>(this, n, null);

  @override
  Iterable<JSAny?> skipWhile(bool Function(JSAny?) test) =>
      SkipWhileIterable<JSAny?>(this, test);

  @override
  JSAny? reduce(JSAny? combine(JSAny? previousValue, JSAny? element)) {
    final end = length;
    if (end == 0) throw IterableElementError.noElement();
    JSAny? value = this[0];
    for (var i = 1; i < end; i++) {
      final element = this[i];
      value = combine(value, element);
      if (end != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  T fold<T>(
      T initialValue, T Function(T previousValue, JSAny? element) combine) {
    final end = length;
    var value = initialValue;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      value = combine(value, element);
      if (end != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  JSAny? firstWhere(bool Function(JSAny?) test, {JSAny? Function()? orElse}) {
    final end = length;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) return element;
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  JSAny? lastWhere(bool Function(JSAny?) test, {JSAny? Function()? orElse}) {
    final end = length;
    for (int i = end - 1; i >= 0; i--) {
      final element = this[i];
      if (test(element)) return element;
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  JSAny? singleWhere(bool Function(JSAny?) test, {JSAny? Function()? orElse}) {
    final end = length;
    JSAny? match;
    var matchFound = false;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (matchFound) return match;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  JSAny? elementAt(int index) => this[index];

  @override
  List<JSAny?> sublist(int start, [int? end]) {
    end = RangeError.checkValidRange(start, end, length);
    return JSArrayImpl(js.JS<WasmExternRef?>('(a, s, e) => a.slice(s, e)',
        toExternRef, start.toJS.toExternRef, end.toJS.toExternRef));
  }

  @override
  Iterable<JSAny?> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    return SubListIterable<JSAny?>(this, start, end);
  }

  @override
  JSAny? get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  @override
  JSAny? get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  @override
  JSAny? get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  @override
  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    int deleteCount = end - start;
    js.JS<void>('(a, s, e) => a.splice(s, e)', toExternRef,
        start.toJS.toExternRef, deleteCount.toJS.toExternRef);
  }

  @override
  void setRange(int start, int end, Iterable<JSAny?> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);
    final rangeLength = end - start;
    if (rangeLength == 0) return;
    RangeError.checkNotNegative(skipCount);

    // TODO(joshualitt): Fast path for when iterable is JS backed.
    List<JSAny?> otherList;
    int otherStart;
    if (iterable is List<JSAny?>) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + rangeLength > otherList.length)
      throw IterableElementError.tooFew();

    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      for (var i = rangeLength - 1; i >= 0; i--) {
        this[start + i] = otherList[otherStart + i];
      }
    } else {
      for (var i = 0; i < rangeLength; i++) {
        this[start + i] = otherList[otherStart + i];
      }
    }
  }

  @override
  void fillRange(int start, int end, [JSAny? fillValue]) {
    RangeError.checkValidRange(start, end, length);
    for (var i = start; i < end; i++) {
      this[i] = fillValue;
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<JSAny?> replacement) {
    RangeError.checkValidRange(start, end, length);
    final replacementList = replacement is EfficientLengthIterable
        ? replacement
        : replacement.toList();
    final removeLength = end - start;
    final insertLength = replacementList.length;
    if (removeLength >= insertLength) {
      final delta = removeLength - insertLength;
      final insertEnd = start + insertLength;
      final newLength = length - delta;
      setRange(start, insertEnd, replacementList);
      if (delta != 0) {
        setRange(insertEnd, newLength, this, end);
        _setLengthUnsafe(newLength);
      }
    } else {
      final delta = insertLength - removeLength;
      final newLength = length + delta;
      final insertEnd = start + insertLength;
      _setLengthUnsafe(newLength);
      setRange(insertEnd, newLength, this, end);
      setRange(start, insertEnd, replacementList);
    }
  }

  @override
  bool any(bool test(JSAny? element)) {
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) return true;
      if (end != length) throw ConcurrentModificationError(this);
    }
    return false;
  }

  @override
  bool every(bool test(JSAny? element)) {
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (!test(element)) return false;
      if (end != length) throw ConcurrentModificationError(this);
    }
    return true;
  }

  @override
  Iterable<JSAny?> get reversed => ReversedListIterable<JSAny?>(this);

  static int _compareAny(JSAny? a, JSAny? b) => js
      .JS<double>('(a, b) => a == b ? 0 : (a > b ? 1 : -1)', a?.toExternRef,
          b?.toExternRef)
      .toInt();

  @override
  void sort([int Function(JSAny?, JSAny?)? compare]) =>
      Sort.sort(this, compare ?? _compareAny);

  @override
  void shuffle([Random? random]) {
    random ??= Random();
    int shufflePoint = length;
    while (shufflePoint > 1) {
      final pos = random.nextInt(shufflePoint);
      shufflePoint--;
      final tmp = this[shufflePoint];
      this[shufflePoint] = this[pos];
      this[pos] = tmp;
    }
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  int lastIndexOf(Object? element, [int? startIndex]) {
    var start = startIndex ?? length - 1;
    if (start >= length) {
      start = length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (var i = start; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  bool contains(Object? other) {
    for (final element in this) {
      if (element == other) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => ListBase.listToString(this);

  @override
  List<JSAny?> toList({bool growable = true}) =>
      List<JSAny?>.of(this, growable: growable);

  @override
  Set<JSAny?> toSet() => Set<JSAny?>.from(this);

  @override
  Iterator<JSAny?> get iterator => JSArrayImplIterator(this);

  @override
  int get length => js.JS<double>('a => a.length', toExternRef).toInt();

  void set length(int newLength) {
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, null);
    }
    js.JS<void>(
        '(a, l) => a.length = l', toExternRef, newLength.toJS.toExternRef);
  }

  @override
  JSAny? operator [](int index) {
    RangeError.checkValueInInterval(index, 0, length - 1);
    return js.JSValue.boxT<JSAny?>(js.JS<WasmExternRef?>(
        '(a, i) => a[i]', toExternRef, index.toJS.toExternRef));
  }

  @override
  void operator []=(int index, JSAny? value) {
    RangeError.checkValueInInterval(index, 0, length - 1);
    js.JS<void>('(a, i, v) => a[i] = v', toExternRef, index.toJS.toExternRef,
        value?.toExternRef);
  }

  @override
  Map<int, JSAny?> asMap() => ListMapView<JSAny?>(this);

  @override
  Iterable<JSAny?> followedBy(Iterable<JSAny?> other) =>
      FollowedByIterable<JSAny?>.firstEfficient(this, other);

  @override
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  @override
  List<JSAny?> operator +(List<JSAny?> other) {
    if (other is JSArrayImpl) {
      return JSArrayImpl(js.JS<WasmExternRef?>(
          '(a, t) => a.concat(t)', toExternRef, other.toExternRef));
    } else {
      return [...this, ...other];
    }
  }

  @override
  int indexWhere(bool Function(JSAny?) test, [int start = 0]) {
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < length; i++) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }

  @override
  int lastIndexWhere(bool Function(JSAny?) test, [int? start]) {
    if (start == null) {
      start = length - 1;
    }
    if (start < 0) {
      return -1;
    }
    for (var i = start; i >= 0; i--) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }

  void set first(JSAny? element) {
    if (isEmpty) {
      throw IterableElementError.noElement();
    }
    this[0] = element;
  }

  void set last(JSAny? element) {
    if (isEmpty) {
      throw IterableElementError.noElement();
    }
    this[length - 1] = element;
  }

  // TODO(joshualitt): Override hash code and operator==?
}

class JSArrayImplIterator implements Iterator<JSAny?> {
  final JSArrayImpl _array;
  final int _length;
  int _index = -1;

  JSArrayImplIterator(this._array) : _length = _array.length {}

  JSAny? get current => _array[_index];

  bool moveNext() {
    if (_length != _array.length) {
      throw ConcurrentModificationError(_array);
    }
    if (_index >= _length - 1) {
      return false;
    }
    _index++;
    return true;
  }
}
