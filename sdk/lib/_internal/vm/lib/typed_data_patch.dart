// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:typed_data" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal"
    show
        ClassID,
        CodeUnits,
        ExpandIterable,
        FixedLengthListMixin,
        FollowedByIterable,
        IterableElementError,
        ListMapView,
        Lists,
        MappedIterable,
        MappedIterable,
        ReversedListIterable,
        SkipWhileIterable,
        Sort,
        SubListIterable,
        TakeWhileIterable,
        WhereIterable,
        WhereTypeIterable,
        patch,
        unsafeCast;

import "dart:collection" show ListBase;

import 'dart:math' show Random;
import 'dart:math' as math show max, min, sqrt;

/// There are no parts in patch library:

@patch
class ByteData {
  @patch
  @pragma("vm:recognized", "other")
  factory ByteData(int length) {
    final list = Uint8List(length) as _TypedList;
    _rangeCheck(list.lengthInBytes, 0, length);
    return _ByteDataView._(list, 0, length);
  }

  factory ByteData._view(_TypedList typedData, int offsetInBytes, int length) {
    _rangeCheck(typedData.lengthInBytes, offsetInBytes, length);
    return _ByteDataView._(typedData, offsetInBytes, length);
  }
}

// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.
// This class does not extend ListBase<T> since that would add type arguments
// to instances of _TypeListBase. Instead the subclasses mix in
// _TypedListMixin with their element type to implement ListBase<T>.
abstract final class _TypedListBase {
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataBase_length")
  external int get length;

  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;
  _TypedList get _typedData;

  // Method(s) implementing the Collection interface.
  String join([String separator = ""]) {
    StringBuffer buffer = StringBuffer();
    buffer.writeAll(this as Iterable, separator);
    return buffer.toString();
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  // Method(s) implementing the List interface.

  @pragma("vm:prefer-inline")
  void _setRange(int start, int end, Iterable from, [int skipCount = 0]) {
    // Range check all numeric inputs.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable so there is no
      // promotion here.
      final fromAsTyped = unsafeCast<_TypedListBase>(from);
      if (fromAsTyped.elementSizeInBytes == elementSizeInBytes) {
        // Check that from has enough elements, which is assumed by
        // _fastSetRange, using the more efficient _TypedListBase length getter.
        final count = end - start;
        if ((fromAsTyped.length - skipCount) < count) {
          throw IterableElementError.tooFew();
        }
        if (count == 0) return;
        return _fastSetRange(start, count, fromAsTyped, skipCount);
      }
    }
    // _slowSetRange checks that from has enough elements internally.
    return _slowSetRange(start, end, from, skipCount);
  }

  // Method(s) implementing the Object interface.
  String toString() => ListBase.listToString(this as List);

  // Internal utility methods.
  void _fastSetRange(int start, int count, _TypedListBase from, int skipCount);
  void _slowSetRange(int start, int end, Iterable from, int skipCount);

  @pragma("vm:prefer-inline")
  bool get _containsUnsignedBytes => false;

  // Performs a copy of the [count] elements starting at [skipCount] in [from]
  // to [this] starting at [start].
  //
  // Primarily called by Dart code to handle clamping.
  //
  // Element sizes of [this] and [from] must match. [this] must be a clamped
  // typed data object, and the values in [from] must require possible clamping
  // (tests at caller).
  @pragma("vm:external-name", "TypedDataBase_setClampedRange")
  @pragma("vm:entry-point")
  external void _setClampedRange(
    int start,
    int count,
    _TypedListBase from,
    int skipOffset,
  );

  // Performs a copy of the [count] elements starting at [skipCount] in [from]
  // to [this] starting at [start].
  //
  // The element sizes of [this] and [from] must be 1 (test at caller).
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _memMove1(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  );

  // Performs a copy of the [count] elements starting at [skipCount] in [from]
  // to [this] starting at [start].
  //
  // The element sizes of [this] and [from] must be 2 (test at caller).
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _memMove2(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  );

  // Performs a copy of the [count] elements starting at [skipCount] in [from]
  // to [this] starting at [start].
  //
  // The element sizes of [this] and [from] must be 4 (test at caller).
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _memMove4(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  );

  // Performs a copy of the [count] elements starting at [skipCount] in [from]
  // to [this] starting at [start].
  //
  // The element sizes of [this] and [from] must be 8 (test at caller).
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _memMove8(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  );

  // Performs a copy of the elements starting at [skipCount] in [from] to
  // [this] starting at [start] (inclusive) and ending at [end] (exclusive).
  //
  // The element sizes of [this] and [from] must be 16 (test at caller).
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _memMove16(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  );
}

base mixin _TypedListMixin<E, L extends List<E>> on _TypedListBase
    implements TypedDataList<E> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  L _createList(int length);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<E, R>(this);
  void set first(E value) {
    if (length == 0) throw IterableElementError.tooFew();
    this[0] = value;
  }

  void set last(E value) {
    if (length == 0) throw IterableElementError.tooFew();
    this[length - 1] = value;
  }

  int indexWhere(bool Function(E element) test, [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    int startIndex = (start == null || start >= this.length)
        ? this.length - 1
        : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  List<E> operator +(List<E> other) => [...this, ...other];

  bool contains(Object? element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void _slowSetRange(int start, int end, Iterable from, int skipCount) {
    // The numeric inputs have already been checked, all that's left is to
    // check that from has enough elements when applicable.
    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable so there is no
      // promotion here.
      final fromAsTyped = unsafeCast<_TypedListBase>(from);
      if (fromAsTyped.buffer == this.buffer) {
        final count = end - start;
        if ((fromAsTyped.length - skipCount) < count) {
          throw IterableElementError.tooFew();
        }
        if (count == 0) return;
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<E>;
        final tempBuffer = _createList(count);
        for (var i = 0; i < count; i++) {
          tempBuffer[i] = fromAsList[skipCount + i];
        }
        for (var i = start; i < end; i++) {
          this[i] = tempBuffer[i - start];
        }
        return;
      }
    }

    List otherList;
    int otherStart;
    if (from is List<E>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    final count = end - start;
    if ((otherList.length - otherStart) < count) {
      throw IterableElementError.tooFew();
    }
    if (count == 0) return;
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<E> where(bool Function(E element) f) => WhereIterable<E>(this, f);

  Iterable<E> take(int n) => SubListIterable<E>(this, 0, n);

  Iterable<E> takeWhile(bool Function(E element) test) =>
      TakeWhileIterable<E>(this, test);

  Iterable<E> skip(int n) => SubListIterable<E>(this, n, null);

  Iterable<E> skipWhile(bool Function(E element) test) =>
      SkipWhileIterable<E>(this, test);

  Iterable<E> get reversed => ReversedListIterable<E>(this);

  Map<int, E> asMap() => ListMapView<E>(this);

  Iterable<E> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<E>(this, start, endIndex);
  }

  Iterator<E> get iterator => _TypedListIterator<E>(this);

  List<E> toList({bool growable = true}) {
    return List<E>.of(this, growable: growable);
  }

  Set<E> toSet() {
    return Set<E>.of(this);
  }

  void forEach(void Function(E element) f) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  E reduce(E Function(E value, E element) combine) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T Function(T initialValue, E element) combine) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T Function(E element) f) => MappedIterable<E, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      ExpandIterable<E, T>(this, f);

  bool every(bool Function(E element) f) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool Function(E element) f) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    var len = this.length;
    for (var i = len - 1; i >= 0; --i) {
      var element = this[i];
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    var result = null;
    bool foundMatching = false;
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
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

  E elementAt(int index) {
    return this[index];
  }

  void sort([int Function(E a, E b)? compare]) {
    if (compare == null && this is! List<num>) {
      throw "SIMD don't have default compare.";
    }
    Sort.sort(this, compare ?? Comparable.compare as int Function(E, E));
  }

  int indexOf(E element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexOf(E element, [int? start]) {
    int startIndex = (start == null || start >= this.length)
        ? this.length - 1
        : start;
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
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

  L sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    var length = endIndex - start;
    L result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<E> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [E? fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }

  @pragma("vm:prefer-inline")
  void setRange(int start, int end, Iterable<E> from, [int skipCount = 0]) =>
      _setRange(start, end, from, skipCount);
}

@pragma("vm:entry-point")
final class _ByteBuffer implements ByteBuffer {
  final _TypedList _data;

  _ByteBuffer(this._data);

  @pragma("vm:entry-point")
  factory _ByteBuffer._New(data) => _ByteBuffer(data);

  // Forward calls to _data.
  int get lengthInBytes => _data.lengthInBytes;
  int get hashCode => _data.hashCode;
  bool operator ==(Object other) =>
      (other is _ByteBuffer) && identical(_data, other._data);

  @pragma("vm:prefer-inline")
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= this.lengthInBytes - offsetInBytes;
    _rangeCheck(this._data.lengthInBytes, offsetInBytes, length);
    return _ByteDataView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    length ??= (this.lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Int8List.bytesPerElement,
    );
    return _Int8ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Uint8List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Uint8List.bytesPerElement,
    );
    return _Uint8ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/
        Uint8ClampedList.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Uint8ClampedList.bytesPerElement,
    );
    return _Uint8ClampedArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Int16List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    return _Int16ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Uint16List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    return _Uint16ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Int32List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    return _Int32ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Uint32List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    return _Uint32ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Int64List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    return _Int64ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Uint64List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Uint64List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    return _Uint64ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Float32List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    return _Float32ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Float64List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    return _Float64ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Float32x4List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    return _Float32x4ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Int32x4List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    return _Int32x4ArrayView._(this._data, offsetInBytes, length);
  }

  @pragma("vm:prefer-inline")
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    _rangeCheck(
      this.lengthInBytes,
      offsetInBytes,
      length * Float64x2List.bytesPerElement,
    );
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    return _Float64x2ArrayView._(this._data, offsetInBytes, length);
  }
}

abstract final class _TypedList extends _TypedListBase {
  int get elementSizeInBytes;

  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  _ByteBuffer get buffer => _ByteBuffer(this);

  // Internal utility methods.

  _TypedList get _typedData => this;

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getInt8(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setInt8(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getUint8(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setUint8(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getInt16(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setInt16(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getUint16(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setUint16(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getInt32(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setInt32(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getUint32(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setUint32(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getInt64(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setInt64(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int _getUint64(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setUint64(int offsetInBytes, int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external double _getFloat32(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setFloat32(int offsetInBytes, double value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external double _getFloat64(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setFloat64(int offsetInBytes, double value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external Float32x4 _getFloat32x4(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setFloat32x4(int offsetInBytes, Float32x4 value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32x4)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external Int32x4 _getInt32x4(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setInt32x4(int offsetInBytes, Int32x4 value);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external Float64x2 _getFloat64x2(int offsetInBytes);
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external void _setFloat64x2(int offsetInBytes, Float64x2 value);

  // The _nativeGetX and _nativeSetX methods are only used as a fallback when
  // unboxed double or SIMD values are unsupported by the flow graph compiler.

  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "TypedData_GetFloat32")
  external double _nativeGetFloat32(int offsetInBytes);
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypedData_SetFloat32")
  external void _nativeSetFloat32(int offsetInBytes, double value);

  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "TypedData_GetFloat64")
  external double _nativeGetFloat64(int offsetInBytes);
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypedData_SetFloat64")
  external void _nativeSetFloat64(int offsetInBytes, double value);

  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "TypedData_GetFloat32x4")
  external Float32x4 _nativeGetFloat32x4(int offsetInBytes);
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypedData_SetFloat32x4")
  external void _nativeSetFloat32x4(int offsetInBytes, Float32x4 value);

  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", _Int32x4)
  @pragma("vm:external-name", "TypedData_GetInt32x4")
  external Int32x4 _nativeGetInt32x4(int offsetInBytes);
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypedData_SetInt32x4")
  external void _nativeSetInt32x4(int offsetInBytes, Int32x4 value);

  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "TypedData_GetFloat64x2")
  external Float64x2 _nativeGetFloat64x2(int offsetInBytes);
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypedData_SetFloat64x2")
  external void _nativeSetFloat64x2(int offsetInBytes, Float64x2 value);

  /**
   * Stores the [CodeUnits] as UTF-16 units into this TypedData at
   * positions [start]..[end] (uint16 indices).
   */
  void _setCodeUnits(
    CodeUnits units,
    int byteStart,
    int length,
    int skipCount,
  ) {
    assert(byteStart + length * Uint16List.bytesPerElement <= lengthInBytes);
    String string = CodeUnits.stringOf(units);
    int sliceEnd = skipCount + length;
    RangeError.checkValidRange(
      skipCount,
      sliceEnd,
      string.length,
      "skipCount",
      "skipCount + length",
    );
    for (int i = 0; i < length; i++) {
      _setUint16(
        byteStart + i * Uint16List.bytesPerElement,
        string.codeUnitAt(skipCount + i),
      );
    }
  }
}

abstract final class _TypedIntListBase extends _TypedList
    with FixedLengthListMixin<int> {}

abstract final class _TypedDoubleListBase extends _TypedList
    with FixedLengthListMixin<double> {}

abstract final class _TypedFloat32x4ListBase extends _TypedList
    with FixedLengthListMixin<Float32x4> {}

abstract final class _TypedInt32x4ListBase extends _TypedList
    with FixedLengthListMixin<Int32x4> {}

abstract final class _TypedFloat64x2ListBase extends _TypedList
    with FixedLengthListMixin<Float64x2> {}

base mixin _Int8ListCommonMixin on _TypedListBase implements Int8List {
  int get elementSizeInBytes => Int8List.bytesPerElement;

  Int8List asUnmodifiableView() => _UnmodifiableInt8ArrayView(this);

  Int8List _createList(int length) => Int8List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove1(start, count, from, skipCount);
}

base mixin _Uint8ListCommonMixin on _TypedListBase implements Uint8List {
  int get elementSizeInBytes => Uint8List.bytesPerElement;

  Uint8List asUnmodifiableView() => _UnmodifiableUint8ArrayView(this);

  Uint8List _createList(int length) => Uint8List(length);

  @pragma("vm:prefer-inline")
  bool get _containsUnsignedBytes => true;

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove1(start, count, from, skipCount);
}

base mixin _Uint8ClampedListCommonMixin on _TypedListBase
    implements Uint8ClampedList {
  int get elementSizeInBytes => Uint8List.bytesPerElement;

  Uint8ClampedList asUnmodifiableView() =>
      _UnmodifiableUint8ClampedArrayView(this);

  Uint8ClampedList _createList(int length) => Uint8ClampedList(length);

  @pragma("vm:prefer-inline")
  bool get _containsUnsignedBytes => true;

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => from._containsUnsignedBytes
      ? _memMove1(start, count, from, skipCount)
      : _setClampedRange(start, count, from, skipCount);
}

base mixin _Int16ListCommonMixin on _TypedListBase implements Int16List {
  int get elementSizeInBytes => Int16List.bytesPerElement;

  Int16List asUnmodifiableView() => _UnmodifiableInt16ArrayView(this);

  Int16List _createList(int length) => Int16List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove2(start, count, from, skipCount);
}

base mixin _Uint16ListCommonMixin on _TypedListBase implements Uint16List {
  int get elementSizeInBytes => Uint16List.bytesPerElement;

  Uint16List asUnmodifiableView() => _UnmodifiableUint16ArrayView(this);

  Uint16List _createList(int length) => Uint16List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove2(start, count, from, skipCount);
}

base mixin _Int32ListCommonMixin on _TypedListBase implements Int32List {
  int get elementSizeInBytes => Int32List.bytesPerElement;

  Int32List asUnmodifiableView() => _UnmodifiableInt32ArrayView(this);

  Int32List _createList(int length) => Int32List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove4(start, count, from, skipCount);
}

base mixin _Uint32ListCommonMixin on _TypedListBase implements Uint32List {
  int get elementSizeInBytes => Uint32List.bytesPerElement;

  Uint32List asUnmodifiableView() => _UnmodifiableUint32ArrayView(this);

  Uint32List _createList(int length) => Uint32List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove4(start, count, from, skipCount);
}

base mixin _Int64ListCommonMixin on _TypedListBase implements Int64List {
  int get elementSizeInBytes => Int64List.bytesPerElement;

  Int64List asUnmodifiableView() => _UnmodifiableInt64ArrayView(this);

  Int64List _createList(int length) => Int64List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove8(start, count, from, skipCount);
}

base mixin _Uint64ListCommonMixin on _TypedListBase implements Uint64List {
  int get elementSizeInBytes => Uint64List.bytesPerElement;

  Uint64List asUnmodifiableView() => _UnmodifiableUint64ArrayView(this);

  Uint64List _createList(int length) => Uint64List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove8(start, count, from, skipCount);
}

base mixin _Float32ListCommonMixin on _TypedListBase implements Float32List {
  int get elementSizeInBytes => Float32List.bytesPerElement;

  Float32List asUnmodifiableView() => _UnmodifiableFloat32ArrayView(this);

  Float32List _createList(int length) => Float32List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove4(start, count, from, skipCount);
}

base mixin _Float64ListCommonMixin on _TypedListBase implements Float64List {
  int get elementSizeInBytes => Float64List.bytesPerElement;

  Float64List asUnmodifiableView() => _UnmodifiableFloat64ArrayView(this);

  Float64List _createList(int length) => Float64List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove8(start, count, from, skipCount);
}

base mixin _Float32x4ListCommonMixin on _TypedListBase
    implements Float32x4List {
  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  Float32x4List asUnmodifiableView() => _UnmodifiableFloat32x4ArrayView(this);

  Float32x4List _createList(int length) => Float32x4List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove16(start, count, from, skipCount);
}

base mixin _Int32x4ListCommonMixin on _TypedListBase implements Int32x4List {
  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  Int32x4List asUnmodifiableView() => _UnmodifiableInt32x4ArrayView(this);

  Int32x4List _createList(int length) => Int32x4List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove16(start, count, from, skipCount);
}

base mixin _Float64x2ListCommonMixin on _TypedListBase
    implements Float64x2List {
  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  Float64x2List asUnmodifiableView() => _UnmodifiableFloat64x2ArrayView(this);

  Float64x2List _createList(int length) => Float64x2List(length);

  @pragma("vm:prefer-inline")
  void _fastSetRange(
    int start,
    int count,
    _TypedListBase from,
    int skipCount,
  ) => _memMove16(start, count, from, skipCount);
}

@patch
class Int8List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int8List)
  @pragma("vm:prefer-inline")
  external factory Int8List(int length);

  @patch
  factory Int8List.fromList(List<int> elements) {
    return Int8List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Int8List extends _TypedIntListBase
    with _TypedListMixin<int, Int8List>, _Int8ListCommonMixin
    implements Int8List {
  factory _Int8List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt8(index, value);
  }
}

@patch
class Uint8List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint8List)
  @pragma("vm:prefer-inline")
  external factory Uint8List(int length);

  @patch
  factory Uint8List.fromList(List<int> elements) {
    return Uint8List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Uint8List extends _TypedIntListBase
    with _TypedListMixin<int, Uint8List>, _Uint8ListCommonMixin
    implements Uint8List {
  factory _Uint8List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint8(index, value);
  }
}

@patch
class Uint8ClampedList {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint8ClampedList)
  @pragma("vm:prefer-inline")
  external factory Uint8ClampedList(int length);

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) {
    return Uint8ClampedList(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Uint8ClampedList extends _TypedIntListBase
    with _TypedListMixin<int, Uint8ClampedList>, _Uint8ClampedListCommonMixin
    implements Uint8ClampedList {
  factory _Uint8ClampedList._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint8(index, _toClampedUint8(value));
  }
}

@patch
class Int16List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int16List)
  @pragma("vm:prefer-inline")
  external factory Int16List(int length);

  @patch
  factory Int16List.fromList(List<int> elements) {
    return Int16List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Int16List extends _TypedIntListBase
    with _TypedListMixin<int, Int16List>, _Int16ListCommonMixin
    implements Int16List {
  factory _Int16List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt16(index * Int16List.bytesPerElement, value);
  }

  @pragma("vm:prefer-inline")
  @override
  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    if (from is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Int16List.bytesPerElement;
      _setCodeUnits(from, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, from, skipCount);
    }
  }
}

@patch
class Uint16List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint16List)
  @pragma("vm:prefer-inline")
  external factory Uint16List(int length);

  @patch
  factory Uint16List.fromList(List<int> elements) {
    return Uint16List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Uint16List extends _TypedIntListBase
    with _TypedListMixin<int, Uint16List>, _Uint16ListCommonMixin
    implements Uint16List {
  factory _Uint16List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint16(index * Uint16List.bytesPerElement, value);
  }

  @pragma("vm:prefer-inline")
  @override
  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    if (from is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Uint16List.bytesPerElement;
      _setCodeUnits(from, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, from, skipCount);
    }
  }
}

@patch
class Int32List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32List)
  @pragma("vm:prefer-inline")
  external factory Int32List(int length);

  @patch
  factory Int32List.fromList(List<int> elements) {
    return Int32List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Int32List extends _TypedIntListBase
    with _TypedListMixin<int, Int32List>, _Int32ListCommonMixin
    implements Int32List {
  factory _Int32List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt32(index * Int32List.bytesPerElement, value);
  }
}

@patch
class Uint32List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint32List)
  @pragma("vm:prefer-inline")
  external factory Uint32List(int length);

  @patch
  factory Uint32List.fromList(List<int> elements) {
    return Uint32List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Uint32List extends _TypedIntListBase
    with _TypedListMixin<int, Uint32List>, _Uint32ListCommonMixin
    implements Uint32List {
  factory _Uint32List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint32(index * Uint32List.bytesPerElement, value);
  }
}

@patch
class Int64List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int64List)
  @pragma("vm:prefer-inline")
  external factory Int64List(int length);

  @patch
  factory Int64List.fromList(List<int> elements) {
    return Int64List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Int64List extends _TypedIntListBase
    with _TypedListMixin<int, Int64List>, _Int64ListCommonMixin
    implements Int64List {
  factory _Int64List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt64(index * Int64List.bytesPerElement, value);
  }
}

@patch
class Uint64List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint64List)
  @pragma("vm:prefer-inline")
  external factory Uint64List(int length);

  @patch
  factory Uint64List.fromList(List<int> elements) {
    return Uint64List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Uint64List extends _TypedIntListBase
    with _TypedListMixin<int, Uint64List>, _Uint64ListCommonMixin
    implements Uint64List {
  factory _Uint64List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint64(index * Uint64List.bytesPerElement, value);
  }
}

@patch
class Float32List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32List)
  @pragma("vm:prefer-inline")
  external factory Float32List(int length);

  @patch
  factory Float32List.fromList(List<double> elements) {
    return Float32List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Float32List extends _TypedDoubleListBase
    with _TypedListMixin<double, Float32List>, _Float32ListCommonMixin
    implements Float32List {
  factory _Float32List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat32(index * Float32List.bytesPerElement, value);
  }
}

@patch
class Float64List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64List)
  @pragma("vm:prefer-inline")
  external factory Float64List(int length);

  @patch
  factory Float64List.fromList(List<double> elements) {
    return Float64List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Float64List extends _TypedDoubleListBase
    with _TypedListMixin<double, Float64List>, _Float64ListCommonMixin
    implements Float64List {
  factory _Float64List._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat64(index * Float64List.bytesPerElement, value);
  }
}

@patch
class Float32x4List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4List)
  @pragma("vm:prefer-inline")
  external factory Float32x4List(int length);

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) {
    return Float32x4List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Float32x4List extends _TypedFloat32x4ListBase
    with _TypedListMixin<Float32x4, Float32x4List>, _Float32x4ListCommonMixin
    implements Float32x4List {
  factory _Float32x4List._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float32x4)
  external Float32x4 operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, Float32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat32x4(index * Float32x4List.bytesPerElement, value);
  }
}

@patch
class Int32x4List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32x4List)
  @pragma("vm:prefer-inline")
  external factory Int32x4List(int length);

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) {
    return Int32x4List(elements.length)..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Int32x4List extends _TypedInt32x4ListBase
    with _TypedListMixin<Int32x4, Int32x4List>, _Int32x4ListCommonMixin
    implements Int32x4List {
  factory _Int32x4List._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Int32x4)
  external Int32x4 operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, Int32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt32x4(index * Int32x4List.bytesPerElement, value);
  }
}

@patch
class Float64x2List {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2List)
  @pragma("vm:prefer-inline")
  external factory Float64x2List(int length);

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) {
    return Float64x2List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

@pragma("vm:entry-point")
final class _Float64x2List extends _TypedFloat64x2ListBase
    with _TypedListMixin<Float64x2, Float64x2List>, _Float64x2ListCommonMixin
    implements Float64x2List {
  factory _Float64x2List._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float64x2)
  external Float64x2 operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, Float64x2 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat64x2(index * Float64x2List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalInt8Array extends _TypedIntListBase
    with _TypedListMixin<int, Int8List>, _Int8ListCommonMixin
    implements Int8List {
  factory _ExternalInt8Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt8(index, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalUint8Array extends _TypedIntListBase
    with _TypedListMixin<int, Uint8List>, _Uint8ListCommonMixin
    implements Uint8List {
  factory _ExternalUint8Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint8(index, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalUint8ClampedArray extends _TypedIntListBase
    with _TypedListMixin<int, Uint8ClampedList>, _Uint8ClampedListCommonMixin
    implements Uint8ClampedList {
  factory _ExternalUint8ClampedArray._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint8(index, _toClampedUint8(value));
  }
}

@pragma("vm:entry-point")
final class _ExternalInt16Array extends _TypedIntListBase
    with _TypedListMixin<int, Int16List>, _Int16ListCommonMixin
    implements Int16List {
  factory _ExternalInt16Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt16(index * Int16List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalUint16Array extends _TypedIntListBase
    with _TypedListMixin<int, Uint16List>, _Uint16ListCommonMixin
    implements Uint16List {
  factory _ExternalUint16Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint16(index * Uint16List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalInt32Array extends _TypedIntListBase
    with _TypedListMixin<int, Int32List>, _Int32ListCommonMixin
    implements Int32List {
  factory _ExternalInt32Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt32(index * Int32List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalUint32Array extends _TypedIntListBase
    with _TypedListMixin<int, Uint32List>, _Uint32ListCommonMixin
    implements Uint32List {
  factory _ExternalUint32Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint32(index * Uint32List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalInt64Array extends _TypedIntListBase
    with _TypedListMixin<int, Int64List>, _Int64ListCommonMixin
    implements Int64List {
  factory _ExternalInt64Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt64(index * Int64List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalUint64Array extends _TypedIntListBase
    with _TypedListMixin<int, Uint64List>, _Uint64ListCommonMixin
    implements Uint64List {
  factory _ExternalUint64Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _setUint64(index * Uint64List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalFloat32Array extends _TypedDoubleListBase
    with _TypedListMixin<double, Float32List>, _Float32ListCommonMixin
    implements Float32List {
  factory _ExternalFloat32Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat32(index * Float32List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalFloat64Array extends _TypedDoubleListBase
    with _TypedListMixin<double, Float64List>, _Float64ListCommonMixin
    implements Float64List {
  factory _ExternalFloat64Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat64(index * Float64List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalFloat32x4Array extends _TypedFloat32x4ListBase
    with _TypedListMixin<Float32x4, Float32x4List>, _Float32x4ListCommonMixin
    implements Float32x4List {
  factory _ExternalFloat32x4Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float32x4)
  external Float32x4 operator [](int index);

  void operator []=(int index, Float32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat32x4(index * Float32x4List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalInt32x4Array extends _TypedInt32x4ListBase
    with _TypedListMixin<Int32x4, Int32x4List>, _Int32x4ListCommonMixin
    implements Int32x4List {
  factory _ExternalInt32x4Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Int32x4)
  external Int32x4 operator [](int index);

  void operator []=(int index, Int32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setInt32x4(index * Int32x4List.bytesPerElement, value);
  }
}

@pragma("vm:entry-point")
final class _ExternalFloat64x2Array extends _TypedFloat64x2ListBase
    with _TypedListMixin<Float64x2, Float64x2List>, _Float64x2ListCommonMixin
    implements Float64x2List {
  factory _ExternalFloat64x2Array._uninstantiable() {
    throw "Unreachable";
  }

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float64x2)
  external Float64x2 operator [](int index);

  void operator []=(int index, Float64x2 value) {
    index = _typedDataIndexCheck(this, index, length);
    _setFloat64x2(index * Float64x2List.bytesPerElement, value);
  }
}

@patch
@pragma('vm:deeply-immutable')
class Float32x4 {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_fromDoubles")
  external factory Float32x4(double x, double y, double z, double w);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  factory Float32x4.splat(double value) =>
      Float32x4(value, value, value, value);

  @patch
  @pragma("vm:recognized", "other")
  factory Float32x4.zero() => Float32x4(0.0, 0.0, 0.0, 0.0);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_fromInt32x4Bits")
  external factory Float32x4.fromInt32x4Bits(Int32x4 x);

  @patch
  @pragma("vm:recognized", "other")
  factory Float32x4.fromFloat64x2(Float64x2 xy) =>
      Float32x4(xy.x, xy.y, 0.0, 0.0);
}

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _Float32x4 implements Float32x4 {
  @pragma("vm:recognized", "graph-intrinsic")
  Float32x4 operator +(Float32x4 other) =>
      Float32x4(x + other.x, y + other.y, z + other.z, w + other.w);
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_negate")
  external Float32x4 operator -();
  @pragma("vm:recognized", "graph-intrinsic")
  Float32x4 operator -(Float32x4 other) =>
      Float32x4(x - other.x, y - other.y, z - other.z, w - other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Float32x4 operator *(Float32x4 other) =>
      Float32x4(x * other.x, y * other.y, z * other.z, w * other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Float32x4 operator /(Float32x4 other) =>
      Float32x4(x / other.x, y / other.y, z / other.z, w / other.w);
  @pragma("vm:recognized", "other")
  Int32x4 lessThan(Float32x4 other) => Int32x4(
    x < other.x ? -1 : 0,
    y < other.y ? -1 : 0,
    z < other.z ? -1 : 0,
    w < other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  Int32x4 lessThanOrEqual(Float32x4 other) => Int32x4(
    x <= other.x ? -1 : 0,
    y <= other.y ? -1 : 0,
    z <= other.z ? -1 : 0,
    w <= other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  Int32x4 greaterThan(Float32x4 other) => Int32x4(
    x > other.x ? -1 : 0,
    y > other.y ? -1 : 0,
    z > other.z ? -1 : 0,
    w > other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  Int32x4 greaterThanOrEqual(Float32x4 other) => Int32x4(
    x >= other.x ? -1 : 0,
    y >= other.y ? -1 : 0,
    z >= other.z ? -1 : 0,
    w >= other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  Int32x4 equal(Float32x4 other) => Int32x4(
    x == other.x ? -1 : 0,
    y == other.y ? -1 : 0,
    z == other.z ? -1 : 0,
    w == other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  Int32x4 notEqual(Float32x4 other) => Int32x4(
    x != other.x ? -1 : 0,
    y != other.y ? -1 : 0,
    z != other.z ? -1 : 0,
    w != other.w ? -1 : 0,
  );
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_scale")
  external Float32x4 scale(double scale);
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_abs")
  external Float32x4 abs();
  @pragma("vm:prefer-inline")
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) =>
      min(upperLimit).max(lowerLimit);
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float32x4_getX")
  external double get x;
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float32x4_getY")
  external double get y;
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float32x4_getZ")
  external double get z;
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float32x4_getW")
  external double get w;
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Float32x4_getSignMask")
  external int get signMask;

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_shuffle")
  external Float32x4 shuffle(int mask);
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_shuffleMix")
  external Float32x4 shuffleMix(Float32x4 zw, int mask);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_setX")
  external Float32x4 withX(double x);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_setY")
  external Float32x4 withY(double y);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_setZ")
  external Float32x4 withZ(double z);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_setW")
  external Float32x4 withW(double w);

  @pragma("vm:recognized", "other")
  Float32x4 min(Float32x4 other) => Float32x4(
    math.min(x, other.x),
    math.min(y, other.y),
    math.min(z, other.z),
    math.min(w, other.w),
  );
  @pragma("vm:recognized", "other")
  Float32x4 max(Float32x4 other) => Float32x4(
    math.max(x, other.x),
    math.max(y, other.y),
    math.max(z, other.z),
    math.max(w, other.w),
  );
  @pragma("vm:recognized", "other")
  Float32x4 sqrt() =>
      Float32x4(math.sqrt(x), math.sqrt(y), math.sqrt(z), math.sqrt(w));
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_reciprocal")
  external Float32x4 reciprocal();
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Float32x4_reciprocalSqrt")
  external Float32x4 reciprocalSqrt();

  String toString() => 'V128';
}

@patch
@pragma('vm:deeply-immutable')
class Int32x4 {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32x4)
  @pragma("vm:external-name", "Int32x4_fromInts")
  external factory Int32x4(int x, int y, int z, int w);

  @patch
  @pragma("vm:recognized", "other")
  factory Int32x4.splat(int value) => Int32x4(value, value, value, value);

  @patch
  @pragma("vm:prefer-inline")
  factory Int32x4.zero() => Int32x4.splat(0);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  factory Int32x4.bool(bool x, bool y, bool z, bool w) =>
      Int32x4(x ? -1 : 0, y ? -1 : 0, z ? -1 : 0, w ? -1 : 0);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32x4)
  @pragma("vm:external-name", "Int32x4_fromFloat32x4Bits")
  external factory Int32x4.fromFloat32x4Bits(Float32x4 x);
}

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _Int32x4 implements Int32x4 {
  @pragma("vm:recognized", "graph-intrinsic")
  Int32x4 operator |(Int32x4 other) =>
      Int32x4(x | other.x, y | other.y, z | other.z, w | other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Int32x4 operator &(Int32x4 other) =>
      Int32x4(x & other.x, y & other.y, z & other.z, w & other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Int32x4 operator ^(Int32x4 other) =>
      Int32x4(x ^ other.x, y ^ other.y, z ^ other.z, w ^ other.w);
  @pragma("vm:recognized", "other")
  Int32x4 operator ~() => Int32x4(~x, ~y, ~z, ~w);
  @pragma("vm:recognized", "other")
  Int32x4 andNot(Int32x4 other) =>
      Int32x4(x & ~other.x, y & ~other.y, z & ~other.z, w & ~other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Int32x4 operator +(Int32x4 other) =>
      Int32x4(x + other.x, y + other.y, z + other.z, w + other.w);
  @pragma("vm:recognized", "graph-intrinsic")
  Int32x4 operator -(Int32x4 other) =>
      Int32x4(x - other.x, y - other.y, z - other.z, w - other.w);

  Int32x4 operator -() => Int32x4(-x, -y, -z, -w);

  Int32x4 abs() => Int32x4(x.abs(), y.abs(), z.abs(), w.abs());

  @pragma("vm:recognized", "other")
  Int32x4 operator <<(int shiftAmount) {
    final int n = shiftAmount & 31;
    return Int32x4(x << n, y << n, z << n, w << n);
  }

  @pragma("vm:recognized", "other")
  Int32x4 operator >>(int shiftAmount) {
    final int n = shiftAmount & 31;
    return Int32x4(x >> n, y >> n, z >> n, w >> n);
  }

  @pragma("vm:recognized", "other")
  Int32x4 operator >>>(int shiftAmount) {
    final int n = shiftAmount & 31;
    return Int32x4(
      x.toUnsigned(32) >> n,
      y.toUnsigned(32) >> n,
      z.toUnsigned(32) >> n,
      w.toUnsigned(32) >> n,
    );
  }

  @pragma("vm:recognized", "other")
  Int32x4 equal(Int32x4 other) => Int32x4(
    x == other.x ? -1 : 0,
    y == other.y ? -1 : 0,
    z == other.z ? -1 : 0,
    w == other.w ? -1 : 0,
  );

  @pragma("vm:recognized", "other")
  Int32x4 notEqual(Int32x4 other) => Int32x4(
    x != other.x ? -1 : 0,
    y != other.y ? -1 : 0,
    z != other.z ? -1 : 0,
    w != other.w ? -1 : 0,
  );

  Int32x4 lessThan(Int32x4 other) => Int32x4(
    x < other.x ? -1 : 0,
    y < other.y ? -1 : 0,
    z < other.z ? -1 : 0,
    w < other.w ? -1 : 0,
  );

  Int32x4 lessThanOrEqual(Int32x4 other) => Int32x4(
    x <= other.x ? -1 : 0,
    y <= other.y ? -1 : 0,
    z <= other.z ? -1 : 0,
    w <= other.w ? -1 : 0,
  );

  Int32x4 greaterThan(Int32x4 other) => Int32x4(
    x > other.x ? -1 : 0,
    y > other.y ? -1 : 0,
    z > other.z ? -1 : 0,
    w > other.w ? -1 : 0,
  );

  Int32x4 greaterThanOrEqual(Int32x4 other) => Int32x4(
    x >= other.x ? -1 : 0,
    y >= other.y ? -1 : 0,
    z >= other.z ? -1 : 0,
    w >= other.w ? -1 : 0,
  );

  Int32x4 min(Int32x4 other) => Int32x4(
    x < other.x ? x : other.x,
    y < other.y ? y : other.y,
    z < other.z ? z : other.z,
    w < other.w ? w : other.w,
  );

  Int32x4 max(Int32x4 other) => Int32x4(
    x > other.x ? x : other.x,
    y > other.y ? y : other.y,
    z > other.z ? z : other.z,
    w > other.w ? w : other.w,
  );

  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Int32x4_getX")
  external int get x;
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Int32x4_getY")
  external int get y;
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Int32x4_getZ")
  external int get z;
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Int32x4_getW")
  external int get w;
  @pragma("vm:recognized", "other")
  int get signMask {
    final int mx = (x >> 31) & 1;
    final int my = (y >> 31) & 1;
    final int mz = (z >> 31) & 1;
    final int mw = (w >> 31) & 1;
    return mx | my << 1 | mz << 2 | mw << 3;
  }

  @pragma("vm:recognized", "other")
  bool get anyTrue => (x | y | z | w) != 0;

  @pragma("vm:recognized", "other")
  bool get allTrue => flagX && flagY && flagZ && flagW;

  @pragma("vm:prefer-inline")
  static int _lane(int index, int x, int y, int z, int w) => switch (index) {
    0 => x,
    1 => y,
    2 => z,
    _ => w,
  };

  @pragma("vm:recognized", "other")
  Int32x4 shuffle(int mask) {
    if (mask < 0 || mask > 255) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    final int l0 = x;
    final int l1 = y;
    final int l2 = z;
    final int l3 = w;
    return Int32x4(
      _lane(mask & 0x3, l0, l1, l2, l3),
      _lane((mask >> 2) & 0x3, l0, l1, l2, l3),
      _lane((mask >> 4) & 0x3, l0, l1, l2, l3),
      _lane((mask >> 6) & 0x3, l0, l1, l2, l3),
    );
  }

  @pragma("vm:recognized", "other")
  Int32x4 shuffleMix(Int32x4 zw, int mask) {
    if (mask < 0 || mask > 255) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    final int l0 = x;
    final int l1 = y;
    final int l2 = z;
    final int l3 = w;
    final int r0 = zw.x;
    final int r1 = zw.y;
    final int r2 = zw.z;
    final int r3 = zw.w;
    return Int32x4(
      _lane(mask & 0x3, l0, l1, l2, l3),
      _lane((mask >> 2) & 0x3, l0, l1, l2, l3),
      _lane((mask >> 4) & 0x3, r0, r1, r2, r3),
      _lane((mask >> 6) & 0x3, r0, r1, r2, r3),
    );
  }

  @pragma("vm:recognized", "other")
  Int32x4 withX(int newX) => Int32x4(newX, y, z, w);

  @pragma("vm:recognized", "other")
  Int32x4 withY(int newY) => Int32x4(x, newY, z, w);

  @pragma("vm:recognized", "other")
  Int32x4 withZ(int newZ) => Int32x4(x, y, newZ, w);

  @pragma("vm:recognized", "other")
  Int32x4 withW(int newW) => Int32x4(x, y, z, newW);

  @pragma("vm:recognized", "other")
  bool get flagX => x != 0;
  @pragma("vm:recognized", "other")
  bool get flagY => y != 0;
  @pragma("vm:recognized", "other")
  bool get flagZ => z != 0;
  @pragma("vm:recognized", "other")
  bool get flagW => w != 0;

  @pragma("vm:recognized", "other")
  Int32x4 withFlagX(bool newFlagX) => Int32x4(newFlagX ? -1 : 0, y, z, w);

  @pragma("vm:recognized", "other")
  Int32x4 withFlagY(bool newFlagY) => Int32x4(x, newFlagY ? -1 : 0, z, w);

  @pragma("vm:recognized", "other")
  Int32x4 withFlagZ(bool newFlagZ) => Int32x4(x, y, newFlagZ ? -1 : 0, w);

  @pragma("vm:recognized", "other")
  Int32x4 withFlagW(bool newFlagW) => Int32x4(x, y, z, newFlagW ? -1 : 0);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4)
  @pragma("vm:external-name", "Int32x4_select")
  external Float32x4 select(Float32x4 trueValue, Float32x4 falseValue);

  String toString() => 'V128';
}

@patch
@pragma('vm:deeply-immutable')
class Float64x2 {
  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "Float64x2_fromDoubles")
  external factory Float64x2(double x, double y);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  factory Float64x2.splat(double v) => Float64x2(v, v);

  @patch
  @pragma("vm:recognized", "other")
  factory Float64x2.zero() => Float64x2(0.0, 0.0);

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "Float64x2_fromFloat32x4")
  external factory Float64x2.fromFloat32x4(Float32x4 v);
}

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _Float64x2 implements Float64x2 {
  @pragma("vm:recognized", "graph-intrinsic")
  Float64x2 operator +(Float64x2 other) => Float64x2(x + other.x, y + other.y);
  @pragma("vm:recognized", "other")
  Float64x2 operator -() => Float64x2(-x, -y);
  @pragma("vm:recognized", "graph-intrinsic")
  Float64x2 operator -(Float64x2 other) => Float64x2(x - other.x, y - other.y);
  @pragma("vm:recognized", "graph-intrinsic")
  Float64x2 operator *(Float64x2 other) => Float64x2(x * other.x, y * other.y);
  @pragma("vm:recognized", "graph-intrinsic")
  Float64x2 operator /(Float64x2 other) => Float64x2(x / other.x, y / other.y);
  @pragma("vm:recognized", "other")
  Float64x2 scale(double s) => Float64x2(x * s, y * s);
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "Float64x2_abs")
  external Float64x2 abs();
  @pragma("vm:prefer-inline")
  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit) =>
      min(upperLimit).max(lowerLimit);
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float64x2_getX")
  external double get x;
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  @pragma("vm:external-name", "Float64x2_getY")
  external double get y;
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "Float64x2_getSignMask")
  external int get signMask;

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "Float64x2_setX")
  external Float64x2 withX(double x);

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2)
  @pragma("vm:external-name", "Float64x2_setY")
  external Float64x2 withY(double y);

  @pragma("vm:recognized", "other")
  Float64x2 min(Float64x2 other) =>
      Float64x2(math.min(x, other.x), math.min(y, other.y));
  @pragma("vm:recognized", "other")
  Float64x2 max(Float64x2 other) =>
      Float64x2(math.max(x, other.x), math.max(y, other.y));
  @pragma("vm:recognized", "other")
  Float64x2 sqrt() => Float64x2(math.sqrt(x), math.sqrt(y));

  String toString() => 'V128';
}

final class _TypedListIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E? _current;

  _TypedListIterator(List<E> array)
    : _array = array,
      _length = array.length,
      _position = -1 {
    assert(array is _TypedList || array is _TypedListView);
  }

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _length;
    _current = null;
    return false;
  }

  E get current => _current as E;
}

abstract final class _TypedListView extends _TypedListBase
    implements TypedData {
  // Method(s) implementing the TypedData interface.

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  _ByteBuffer get buffer {
    return _typedData.buffer;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataView_typedData")
  external _TypedList get _typedData;

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataView_offsetInBytes")
  external int get offsetInBytes;
}

abstract final class _TypedIntListViewBase extends _TypedListView
    with FixedLengthListMixin<int> {}

abstract final class _TypedDoubleListViewBase extends _TypedListView
    with FixedLengthListMixin<double> {}

abstract final class _TypedFloat32x4ListViewBase extends _TypedListView
    with FixedLengthListMixin<Float32x4> {}

abstract final class _TypedInt32x4ListViewBase extends _TypedListView
    with FixedLengthListMixin<Int32x4> {}

abstract final class _TypedFloat64x2ListViewBase extends _TypedListView
    with FixedLengthListMixin<Float64x2> {}

@pragma("vm:entry-point")
final class _Int8ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Int8List>, _Int8ListCommonMixin
    implements Int8List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int8ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Int8ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setInt8(
      offsetInBytes + (index * Int8List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Uint8ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Uint8List>, _Uint8ListCommonMixin
    implements Uint8List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint8ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Uint8ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setUint8(
      offsetInBytes + (index * Uint8List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Uint8ClampedArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Uint8ClampedList>, _Uint8ClampedListCommonMixin
    implements Uint8ClampedList {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint8ClampedArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Uint8ClampedArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setUint8(
      offsetInBytes + (index * Uint8List.bytesPerElement),
      _toClampedUint8(value),
    );
  }
}

@pragma("vm:entry-point")
final class _Int16ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Int16List>, _Int16ListCommonMixin
    implements Int16List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int16ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Int16ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setInt16(
      offsetInBytes + (index * Int16List.bytesPerElement),
      value,
    );
  }

  @pragma("vm:prefer-inline")
  @override
  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    if (from is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Int16List.bytesPerElement;
      _typedData._setCodeUnits(from, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, from, skipCount);
    }
  }
}

@pragma("vm:entry-point")
final class _Uint16ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Uint16List>, _Uint16ListCommonMixin
    implements Uint16List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint16ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Uint16ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setUint16(
      offsetInBytes + (index * Uint16List.bytesPerElement),
      value,
    );
  }

  @pragma("vm:prefer-inline")
  @override
  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    if (from is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Uint16List.bytesPerElement;
      _typedData._setCodeUnits(from, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, from, skipCount);
    }
  }
}

@pragma("vm:entry-point")
final class _Int32ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Int32List>, _Int32ListCommonMixin
    implements Int32List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Int32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setInt32(
      offsetInBytes + (index * Int32List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Uint32ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Uint32List>, _Uint32ListCommonMixin
    implements Uint32List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Uint32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setUint32(
      offsetInBytes + (index * Uint32List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Int64ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Int64List>, _Int64ListCommonMixin
    implements Int64List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Int64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setInt64(
      offsetInBytes + (index * Int64List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Uint64ArrayView extends _TypedIntListViewBase
    with _TypedListMixin<int, Uint64List>, _Uint64ListCommonMixin
    implements Uint64List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Uint64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Uint64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, int value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setUint64(
      offsetInBytes + (index * Uint64List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Float32ArrayView extends _TypedDoubleListViewBase
    with _TypedListMixin<double, Float32List>, _Float32ListCommonMixin
    implements Float32List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Float32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setFloat32(
      offsetInBytes + (index * Float32List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Float64ArrayView extends _TypedDoubleListViewBase
    with _TypedListMixin<double, Float64List>, _Float64ListCommonMixin
    implements Float64List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Float64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  external double operator [](int index);

  @pragma("vm:prefer-inline")
  void operator []=(int index, double value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setFloat64(
      offsetInBytes + (index * Float64List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Float32x4ArrayView extends _TypedFloat32x4ListViewBase
    with _TypedListMixin<Float32x4, Float32x4List>, _Float32x4ListCommonMixin
    implements Float32x4List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float32x4ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Float32x4ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float32x4)
  external Float32x4 operator [](int index);

  void operator []=(int index, Float32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setFloat32x4(
      offsetInBytes + (index * Float32x4List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Int32x4ArrayView extends _TypedInt32x4ListViewBase
    with _TypedListMixin<Int32x4, Int32x4List>, _Int32x4ListCommonMixin
    implements Int32x4List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Int32x4ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Int32x4ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Int32x4)
  external Int32x4 operator [](int index);

  void operator []=(int index, Int32x4 value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setInt32x4(
      offsetInBytes + (index * Int32x4List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _Float64x2ArrayView extends _TypedFloat64x2ListViewBase
    with _TypedListMixin<Float64x2, Float64x2List>, _Float64x2ListCommonMixin
    implements Float64x2List {
  // Constructor.
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Float64x2ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _Float64x2ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the List interface.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", _Float64x2)
  external Float64x2 operator [](int index);

  void operator []=(int index, Float64x2 value) {
    index = _typedDataIndexCheck(this, index, length);
    _typedData._setFloat64x2(
      offsetInBytes + (index * Float64x2List.bytesPerElement),
      value,
    );
  }
}

@pragma("vm:entry-point")
final class _ByteDataView implements ByteData {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _ByteDataView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _ByteDataView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  // Method(s) implementing the TypedData interface.
  _ByteBuffer get buffer {
    return _typedData.buffer;
  }

  int get lengthInBytes {
    return length;
  }

  int get elementSizeInBytes {
    return 1;
  }

  // Method(s) implementing the ByteData interface.
  ByteData asUnmodifiableView() => _UnmodifiableByteDataView(this);

  @pragma("vm:prefer-inline")
  int getInt8(int byteOffset) {
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    return _typedData._getInt8(offsetInBytes + byteOffset);
  }

  @pragma("vm:prefer-inline")
  void setInt8(int byteOffset, int value) {
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setInt8(offsetInBytes + byteOffset, value);
  }

  @pragma("vm:prefer-inline")
  int getUint8(int byteOffset) {
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    return _typedData._getUint8(offsetInBytes + byteOffset);
  }

  @pragma("vm:prefer-inline")
  void setUint8(int byteOffset, int value) {
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setUint8(offsetInBytes + byteOffset, value);
  }

  @pragma("vm:prefer-inline")
  int getInt16(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 1].
    _byteDataByteOffsetCheck(this, byteOffset + 1, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getInt16(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap16(result).toSigned(16);
  }

  @pragma("vm:prefer-inline")
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 1].
    _byteDataByteOffsetCheck(this, byteOffset + 1, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setInt16(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap16(value),
    );
  }

  @pragma("vm:prefer-inline")
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 1].
    _byteDataByteOffsetCheck(this, byteOffset + 1, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getUint16(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap16(result);
  }

  @pragma("vm:prefer-inline")
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 1].
    _byteDataByteOffsetCheck(this, byteOffset + 1, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setUint16(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap16(value),
    );
  }

  @pragma("vm:prefer-inline")
  int getInt32(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getInt32(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap32(result).toSigned(32);
  }

  @pragma("vm:prefer-inline")
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setInt32(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap32(value),
    );
  }

  @pragma("vm:prefer-inline")
  int getUint32(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getUint32(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap32(result);
  }

  @pragma("vm:prefer-inline")
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setUint32(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap32(value),
    );
  }

  @pragma("vm:prefer-inline")
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getInt64(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap64(result).toSigned(64);
  }

  @pragma("vm:prefer-inline")
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setInt64(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap64(value),
    );
  }

  @pragma("vm:prefer-inline")
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    var result = _typedData._getUint64(offsetInBytes + byteOffset);
    if (identical(endian, Endian.host)) {
      return result;
    }
    return _byteSwap64(result);
  }

  @pragma("vm:prefer-inline")
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    _typedData._setUint64(
      offsetInBytes + byteOffset,
      identical(endian, Endian.host) ? value : _byteSwap64(value),
    );
  }

  @pragma("vm:prefer-inline")
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    if (identical(endian, Endian.host)) {
      return _typedData._getFloat32(offsetInBytes + byteOffset);
    }
    _convU32[0] = _byteSwap32(
      _typedData._getUint32(offsetInBytes + byteOffset),
    );
    return _convF32[0];
  }

  @pragma("vm:prefer-inline")
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 3].
    _byteDataByteOffsetCheck(this, byteOffset + 3, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    if (identical(endian, Endian.host)) {
      _typedData._setFloat32(offsetInBytes + byteOffset, value);
      return;
    }
    _convF32[0] = value;
    _typedData._setUint32(offsetInBytes + byteOffset, _byteSwap32(_convU32[0]));
  }

  @pragma("vm:prefer-inline")
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    if (identical(endian, Endian.host)) {
      return _typedData._getFloat64(offsetInBytes + byteOffset);
    }
    _convU64[0] = _byteSwap64(
      _typedData._getUint64(offsetInBytes + byteOffset),
    );
    return _convF64[0];
  }

  @pragma("vm:prefer-inline")
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 7].
    _byteDataByteOffsetCheck(this, byteOffset + 7, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    if (identical(endian, Endian.host)) {
      _typedData._setFloat64(offsetInBytes + byteOffset, value);
      return;
    }
    _convF64[0] = value;
    _typedData._setUint64(offsetInBytes + byteOffset, _byteSwap64(_convU64[0]));
  }

  Float32x4 getFloat32x4(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 15].
    _byteDataByteOffsetCheck(this, byteOffset + 15, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    return _typedData._getFloat32x4(offsetInBytes + byteOffset);
  }

  void setFloat32x4(
    int byteOffset,
    Float32x4 value, [
    Endian endian = Endian.big,
  ]) {
    // Check bounds for range [byteOffset, byteOffset + 15].
    _byteDataByteOffsetCheck(this, byteOffset + 15, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat32x4(offsetInBytes + byteOffset, value);
  }

  Float64x2 getFloat64x2(int byteOffset, [Endian endian = Endian.big]) {
    // Check bounds for range [byteOffset, byteOffset + 15].
    _byteDataByteOffsetCheck(this, byteOffset + 15, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    return _typedData._getFloat64x2(offsetInBytes + byteOffset);
  }

  void setFloat64x2(
    int byteOffset,
    Float64x2 value, [
    Endian endian = Endian.big,
  ]) {
    // Check bounds for range [byteOffset, byteOffset + 15].
    _byteDataByteOffsetCheck(this, byteOffset + 15, length);
    byteOffset = _byteDataByteOffsetCheck(this, byteOffset, length);
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat64x2(offsetInBytes + byteOffset, value);
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataView_typedData")
  external _TypedList get _typedData;

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataView_offsetInBytes")
  external int get offsetInBytes;

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "TypedDataBase_length")
  external int get length;
}

@pragma("vm:prefer-inline")
int _byteSwap16(int value) {
  return ((value & 0xFF00) >> 8) | ((value & 0x00FF) << 8);
}

@pragma("vm:prefer-inline")
int _byteSwap32(int value) {
  value = ((value & 0xFF00FF00) >> 8) | ((value & 0x00FF00FF) << 8);
  value = ((value & 0xFFFF0000) >> 16) | ((value & 0x0000FFFF) << 16);
  return value;
}

@pragma("vm:prefer-inline")
int _byteSwap64(int value) {
  return (_byteSwap32(value) << 32) | _byteSwap32(value >> 32);
}

final _convU32 = Uint32List(2);
final _convU64 = Uint64List.view(_convU32.buffer);
final _convF32 = Float32List.view(_convU32.buffer);
final _convF64 = Float64List.view(_convU32.buffer);

// Top level utility methods.
@pragma("vm:exact-result-type", "dart:core#_Smi")
int _toClampedUint8(int value) {
  if (value < 0) return 0;
  if (value > 0xFF) return 0xFF;
  return value;
}

// Length should be non-negative.
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
int _typedDataIndexCheck(Object indexable, int index, int length) {
  if (index < 0 || index >= length) {
    throw IndexError.withLength(
      index,
      length,
      indexable: indexable,
      name: "index",
    );
  }
  return index;
}

// Length should be non-negative.
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
int _byteDataByteOffsetCheck(ByteData indexable, int byteOffset, int length) {
  if (byteOffset < 0 || byteOffset >= length) {
    throw IndexError.withLength(
      byteOffset,
      length,
      indexable: indexable,
      name: "byteOffset",
    );
  }
  return byteOffset;
}

// In addition to explicitly checking the range, this method implicitly ensures
// that all arguments are non-null (a no such method error gets thrown
// otherwise).
void _rangeCheck(int listLength, int start, int length) {
  if (length < 0) {
    throw RangeError.value(length);
  }
  if (start < 0) {
    throw RangeError.value(start);
  }
  if (start + length > listLength) {
    throw RangeError.value(start + length);
  }
}

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw RangeError(
      'Offset ($offset) must be a multiple of '
      'BYTES_PER_ELEMENT ($alignment)',
    );
  }
}

@pragma("vm:entry-point")
final class _UnmodifiableInt8ArrayView extends _Int8ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableInt8ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableInt8ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableInt8ArrayView(Int8List list) =>
      _UnmodifiableInt8ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Int8List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableUint8ArrayView extends _Uint8ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableUint8ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableUint8ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableUint8ArrayView(Uint8List list) =>
      _UnmodifiableUint8ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Uint8List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableUint8ClampedArrayView extends _Uint8ClampedArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableUint8ClampedArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableUint8ClampedArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableUint8ClampedArrayView(Uint8ClampedList list) =>
      _UnmodifiableUint8ClampedArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Uint8ClampedList asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableInt16ArrayView extends _Int16ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableInt16ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableInt16ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableInt16ArrayView(Int16List list) =>
      _UnmodifiableInt16ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Int16List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableUint16ArrayView extends _Uint16ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableUint16ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableUint16ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableUint16ArrayView(Uint16List list) =>
      _UnmodifiableUint16ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Uint16List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableInt32ArrayView extends _Int32ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableInt32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableInt32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableInt32ArrayView(Int32List list) =>
      _UnmodifiableInt32ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Int32List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableUint32ArrayView extends _Uint32ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableUint32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableUint32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableUint32ArrayView(Uint32List list) =>
      _UnmodifiableUint32ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Uint32List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableInt64ArrayView extends _Int64ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableInt64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableInt64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableInt64ArrayView(Int64List list) =>
      _UnmodifiableInt64ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Int64List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableUint64ArrayView extends _Uint64ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableUint64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableUint64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableUint64ArrayView(Uint64List list) =>
      _UnmodifiableUint64ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Uint64List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableFloat32ArrayView extends _Float32ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableFloat32ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableFloat32ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableFloat32ArrayView(Float32List list) =>
      _UnmodifiableFloat32ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, double value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Float32List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableFloat64ArrayView extends _Float64ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableFloat64ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableFloat64ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableFloat64ArrayView(Float64List list) =>
      _UnmodifiableFloat64ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, double value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Float64List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableFloat32x4ArrayView extends _Float32x4ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableFloat32x4ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableFloat32x4ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableFloat32x4ArrayView(Float32x4List list) =>
      _UnmodifiableFloat32x4ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, Float32x4 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Float32x4List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableInt32x4ArrayView extends _Int32x4ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableInt32x4ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableInt32x4ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableInt32x4ArrayView(Int32x4List list) =>
      _UnmodifiableInt32x4ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, Int32x4 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Int32x4List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableFloat64x2ArrayView extends _Float64x2ArrayView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableFloat64x2ArrayView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableFloat64x2ArrayView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableFloat64x2ArrayView(Float64x2List list) =>
      _UnmodifiableFloat64x2ArrayView._(
        unsafeCast<_TypedListBase>(list)._typedData,
        list.offsetInBytes,
        list.length,
      );

  void operator []=(int index, Float64x2 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  Float64x2List asUnmodifiableView() => this;
}

@pragma("vm:entry-point")
final class _UnmodifiableByteDataView extends _ByteDataView {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _UnmodifiableByteDataView)
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external factory _UnmodifiableByteDataView._(
    _TypedList buffer,
    int offsetInBytes,
    int length,
  );

  @pragma("vm:prefer-inline")
  factory _UnmodifiableByteDataView(ByteData data) =>
      _UnmodifiableByteDataView._(
        unsafeCast<_ByteDataView>(data).buffer._data,
        data.offsetInBytes,
        data.lengthInBytes,
      );

  void setInt8(int byteOffset, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setUint8(int byteOffset, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setFloat32x4(
    int byteOffset,
    Float32x4 value, [
    Endian endian = Endian.big,
  ]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  _ByteBuffer get buffer => _UnmodifiableByteBufferView(_typedData.buffer);

  ByteData asUnmodifiableView() => this;
}

final class _UnmodifiableByteBufferView extends _ByteBuffer {
  _UnmodifiableByteBufferView(ByteBuffer data)
    : super(unsafeCast<_ByteBuffer>(data)._data);

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint8ArrayView(super.asUint8List(offsetInBytes, length));

  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt8ArrayView(super.asInt8List(offsetInBytes, length));

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint8ClampedArrayView(
        super.asUint8ClampedList(offsetInBytes, length),
      );

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint16ArrayView(super.asUint16List(offsetInBytes, length));

  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt16ArrayView(super.asInt16List(offsetInBytes, length));

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint32ArrayView(super.asUint32List(offsetInBytes, length));

  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt32ArrayView(super.asInt32List(offsetInBytes, length));

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint64ArrayView(super.asUint64List(offsetInBytes, length));

  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt64ArrayView(super.asInt64List(offsetInBytes, length));

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt32x4ArrayView(super.asInt32x4List(offsetInBytes, length));

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat32ArrayView(super.asFloat32List(offsetInBytes, length));

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat64ArrayView(super.asFloat64List(offsetInBytes, length));

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat32x4ArrayView(
        super.asFloat32x4List(offsetInBytes, length),
      );

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat64x2ArrayView(
        super.asFloat64x2List(offsetInBytes, length),
      );

  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableByteDataView(super.asByteData(offsetInBytes, length));
}

@pragma('vm:prefer-inline')
bool _listRangeEquals<T extends List<int>>(
  T a,
  int aStart,
  T b,
  int bStart,
  int count,
) {
  if (count <= 32) {
    for (int i = 0; i < count; i++) {
      if (a[aStart + i] != b[bStart + i]) return false;
    }
    return true;
  }
  return _typedDataMemEquals(
    unsafeCast<TypedData>(a),
    aStart,
    unsafeCast<TypedData>(b),
    bStart,
    count,
  );
}

@patch
@pragma('vm:prefer-inline')
bool _uint8ListRangeEquals(
  Uint8List a,
  int aStart,
  Uint8List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _int8ListRangeEquals(
  Int8List a,
  int aStart,
  Int8List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _uint8ClampedListRangeEquals(
  Uint8ClampedList a,
  int aStart,
  Uint8ClampedList b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _uint16ListRangeEquals(
  Uint16List a,
  int aStart,
  Uint16List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _int16ListRangeEquals(
  Int16List a,
  int aStart,
  Int16List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _uint32ListRangeEquals(
  Uint32List a,
  int aStart,
  Uint32List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _int32ListRangeEquals(
  Int32List a,
  int aStart,
  Int32List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _uint64ListRangeEquals(
  Uint64List a,
  int aStart,
  Uint64List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _int64ListRangeEquals(
  Int64List a,
  int aStart,
  Int64List b,
  int bStart,
  int count,
) => _listRangeEquals(a, aStart, b, bStart, count);

@patch
@pragma('vm:prefer-inline')
bool _byteDataRangeEquals(
  ByteData a,
  int aStart,
  ByteData b,
  int bStart,
  int count,
) {
  if (count <= 32) {
    for (int i = 0; i < count; i++) {
      if (a.getUint8(aStart + i) != b.getUint8(bStart + i)) return false;
    }
    return true;
  }
  return _typedDataMemEquals(a, aStart, b, bStart, count);
}

@pragma("vm:external-name", "TypedDataBase_memEquals")
external bool _typedDataMemEquals(
  TypedData a,
  int aStart,
  TypedData b,
  int bStart,
  int count,
);
