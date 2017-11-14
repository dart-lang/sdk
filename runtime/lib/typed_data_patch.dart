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
        patch;

import "dart:collection" show ListBase;

import 'dart:math' show Random;

/// There are no parts in patch library:

@patch
class ByteData implements TypedData {
  @patch
  factory ByteData(int length) {
    final list = new Uint8List(length) as _TypedList;
    return new _ByteDataView(list, 0, length);
  }

  // Called directly from C code.
  factory ByteData._view(_TypedList typedData, int offsetInBytes, int length) {
    return new _ByteDataView(typedData, offsetInBytes, length);
  }
}

// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.
// This class does not extend ListBase<T> since that would add type arguments
// to instances of _TypeListBase. Instead the subclasses use type specific
// mixins (like _IntListMixin, _DoubleListMixin) to implement ListBase<T>.
abstract class _TypedListBase {
  int get length;
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  // Method(s) implementing the Collection interface.
  String join([String separator = ""]) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(this as Iterable, separator);
    return buffer.toString();
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  // Method(s) implementing the List interface.

  set length(newLength) {
    throw new UnsupportedError("Cannot resize a fixed-length list");
  }

  void clear() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  bool remove(Object element) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void replaceRange(int start, int end, Iterable iterable) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  // Method(s) implementing Object interface.
  String toString() => ListBase.listToString(this as List);

  // Internal utility methods.

  // Returns true if operation succeeds.
  // 'fromCid' and 'toCid' may be cid-s of the views and therefore may not
  // match the cids of 'this' and 'from'.
  // Uses toCid and fromCid to decide if clamping is necessary.
  // Element size of toCid and fromCid must match (test at caller).
  bool _setRange(int startInBytes, int lengthInBytes, _TypedListBase from,
      int startFromInBytes, int toCid, int fromCid) native "TypedData_setRange";
}

abstract class _IntListMixin implements List<int> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  List<int> _createList(int length);

  bool contains(Object element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable<int> so there is
      // no promotion here.
      final fromAsTypedList = from as _TypedListBase;
      if (this.elementSizeInBytes == fromAsTypedList.elementSizeInBytes) {
        if ((count < 10) && (fromAsTypedList.buffer != this.buffer)) {
          Lists.copy(from as List<int>, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
            start * elementSizeInBytes + this.offsetInBytes,
            count * elementSizeInBytes,
            fromAsTypedList.buffer._data,
            skipCount * elementSizeInBytes + fromAsTypedList.offsetInBytes,
            ClassID.getID(this),
            ClassID.getID(from))) {
          return;
        }
      } else if (fromAsTypedList.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<int>;
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
    if (from is List<int>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  Iterable<int> take(int n) => new SubListIterable<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int element)) =>
      new TakeWhileIterable<int>(this, test);

  Iterable<int> skip(int n) => new SubListIterable<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int element)) =>
      new SkipWhileIterable<int>(this, test);

  Iterable<int> get reversed => new ReversedListIterable<int>(this);

  Map<int, int> asMap() => new ListMapView<int>(this);

  Iterable<int> getRange(int start, [int end]) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<int>(this, start, end);
  }

  Iterator<int> get iterator => new _TypedListIterator<int>(this);

  List<int> toList({bool growable: true}) {
    return new List<int>.from(this, growable: growable);
  }

  Set<int> toSet() {
    return new Set<int>.from(this);
  }

  void forEach(void f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  int reduce(int combine(int value, int element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(int element)) => new MappedIterable<int, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(int element)) =>
      new ExpandIterable<int, T>(this, f);

  bool every(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  int firstWhere(bool test(int element), {int orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int lastWhere(bool test(int element), {int orElse()}) {
    var result = null;
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

  int singleWhere(bool test(int element)) {
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
    throw IterableElementError.noElement();
  }

  int elementAt(int index) {
    return this[index];
  }

  void add(int value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<int> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, int value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<int> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(int a, int b)]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(int element, [int start = 0]) {
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

  int lastIndexOf(int element, [int start = null]) {
    if (start == null || start >= this.length) {
      start = this.length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  int removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  int get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  int get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<int> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List<int> result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [int fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

abstract class _DoubleListMixin implements List<double> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  List<double> _createList(int length);

  bool contains(Object element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void setRange(int start, int end, Iterable<double> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable<double> so there is
      // no promotion here.
      final fromAsTypedList = from as _TypedListBase;
      if (this.elementSizeInBytes == fromAsTypedList.elementSizeInBytes) {
        if ((count < 10) && (fromAsTypedList.buffer != this.buffer)) {
          Lists.copy(from as List<double>, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
            start * elementSizeInBytes + this.offsetInBytes,
            count * elementSizeInBytes,
            fromAsTypedList.buffer._data,
            skipCount * elementSizeInBytes + fromAsTypedList.offsetInBytes,
            ClassID.getID(this),
            ClassID.getID(from))) {
          return;
        }
      } else if (fromAsTypedList.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<double>;
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
    if (from is List<double>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<double> where(bool f(double element)) =>
      new WhereIterable<double>(this, f);

  Iterable<double> take(int n) => new SubListIterable<double>(this, 0, n);

  Iterable<double> takeWhile(bool test(double element)) =>
      new TakeWhileIterable<double>(this, test);

  Iterable<double> skip(int n) => new SubListIterable<double>(this, n, null);

  Iterable<double> skipWhile(bool test(double element)) =>
      new SkipWhileIterable<double>(this, test);

  Iterable<double> get reversed => new ReversedListIterable<double>(this);

  Map<int, double> asMap() => new ListMapView<double>(this);

  Iterable<double> getRange(int start, [int end]) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<double>(this, start, end);
  }

  Iterator<double> get iterator => new _TypedListIterator<double>(this);

  List<double> toList({bool growable: true}) {
    return new List<double>.from(this, growable: growable);
  }

  Set<double> toSet() {
    return new Set<double>.from(this);
  }

  void forEach(void f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  double reduce(double combine(double value, double element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(double element)) =>
      new MappedIterable<double, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(double element)) =>
      new ExpandIterable<double, T>(this, f);

  bool every(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  double firstWhere(bool test(double element), {double orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double lastWhere(bool test(double element), {double orElse()}) {
    var result = null;
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

  double singleWhere(bool test(double element)) {
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
    throw IterableElementError.noElement();
  }

  double elementAt(int index) {
    return this[index];
  }

  void add(double value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<double> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, double value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<double> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(double a, double b)]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(double element, [int start = 0]) {
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

  int lastIndexOf(double element, [int start = null]) {
    if (start == null || start >= this.length) {
      start = this.length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  double removeLast() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  double removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(double element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(double element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  double get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  double get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  double get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<double> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List<double> result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [double fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

abstract class _Float32x4ListMixin implements List<Float32x4> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  List<Float32x4> _createList(int length);

  bool contains(Object element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void setRange(int start, int end, Iterable<Float32x4> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable<Float32x4> so there is
      // no promotion here.
      final fromAsTypedList = from as _TypedListBase;
      if (this.elementSizeInBytes == fromAsTypedList.elementSizeInBytes) {
        if ((count < 10) && (fromAsTypedList.buffer != this.buffer)) {
          Lists.copy(from as List<Float32x4>, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
            start * elementSizeInBytes + this.offsetInBytes,
            count * elementSizeInBytes,
            fromAsTypedList.buffer._data,
            skipCount * elementSizeInBytes + fromAsTypedList.offsetInBytes,
            ClassID.getID(this),
            ClassID.getID(from))) {
          return;
        }
      } else if (fromAsTypedList.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<Float32x4>;
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
    if (from is List<Float32x4>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<Float32x4> where(bool f(Float32x4 element)) =>
      new WhereIterable<Float32x4>(this, f);

  Iterable<Float32x4> take(int n) => new SubListIterable<Float32x4>(this, 0, n);

  Iterable<Float32x4> takeWhile(bool test(Float32x4 element)) =>
      new TakeWhileIterable<Float32x4>(this, test);

  Iterable<Float32x4> skip(int n) =>
      new SubListIterable<Float32x4>(this, n, null);

  Iterable<Float32x4> skipWhile(bool test(Float32x4 element)) =>
      new SkipWhileIterable<Float32x4>(this, test);

  Iterable<Float32x4> get reversed => new ReversedListIterable<Float32x4>(this);

  Map<int, Float32x4> asMap() => new ListMapView<Float32x4>(this);

  Iterable<Float32x4> getRange(int start, [int end]) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<Float32x4>(this, start, end);
  }

  Iterator<Float32x4> get iterator => new _TypedListIterator<Float32x4>(this);

  List<Float32x4> toList({bool growable: true}) {
    return new List<Float32x4>.from(this, growable: growable);
  }

  Set<Float32x4> toSet() {
    return new Set<Float32x4>.from(this);
  }

  void forEach(void f(Float32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Float32x4 reduce(Float32x4 combine(Float32x4 value, Float32x4 element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, Float32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(Float32x4 element)) =>
      new MappedIterable<Float32x4, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(Float32x4 element)) =>
      new ExpandIterable<Float32x4, T>(this, f);

  bool every(bool f(Float32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(Float32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  Float32x4 firstWhere(bool test(Float32x4 element), {Float32x4 orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  Float32x4 lastWhere(bool test(Float32x4 element), {Float32x4 orElse()}) {
    var result = null;
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

  Float32x4 singleWhere(bool test(Float32x4 element)) {
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
    throw IterableElementError.noElement();
  }

  Float32x4 elementAt(int index) {
    return this[index];
  }

  void add(Float32x4 value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<Float32x4> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, Float32x4 value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<Float32x4> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(Float32x4 a, Float32x4 b)]) {
    if (compare == null) {
      throw "SIMD don't have default compare.";
    }
    Sort.sort(this, compare);
  }

  int indexOf(Float32x4 element, [int start = 0]) {
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

  int lastIndexOf(Float32x4 element, [int start = null]) {
    if (start == null || start >= this.length) {
      start = this.length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  Float32x4 removeLast() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Float32x4 removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(Float32x4 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(Float32x4 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Float32x4 get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  Float32x4 get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  Float32x4 get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<Float32x4> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List<Float32x4> result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<Float32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [Float32x4 fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

abstract class _Int32x4ListMixin implements List<Int32x4> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  List<Int32x4> _createList(int length);

  bool contains(Object element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void setRange(int start, int end, Iterable<Int32x4> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable<Int32x4> so there is
      // no promotion here.
      final fromAsTypedList = from as _TypedListBase;
      if (this.elementSizeInBytes == fromAsTypedList.elementSizeInBytes) {
        if ((count < 10) && (fromAsTypedList.buffer != this.buffer)) {
          Lists.copy(from as List<Int32x4>, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
            start * elementSizeInBytes + this.offsetInBytes,
            count * elementSizeInBytes,
            fromAsTypedList.buffer._data,
            skipCount * elementSizeInBytes + fromAsTypedList.offsetInBytes,
            ClassID.getID(this),
            ClassID.getID(from))) {
          return;
        }
      } else if (fromAsTypedList.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<Int32x4>;
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
    if (from is List<Int32x4>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<Int32x4> where(bool f(Int32x4 element)) =>
      new WhereIterable<Int32x4>(this, f);

  Iterable<Int32x4> take(int n) => new SubListIterable<Int32x4>(this, 0, n);

  Iterable<Int32x4> takeWhile(bool test(Int32x4 element)) =>
      new TakeWhileIterable<Int32x4>(this, test);

  Iterable<Int32x4> skip(int n) => new SubListIterable<Int32x4>(this, n, null);

  Iterable<Int32x4> skipWhile(bool test(Int32x4 element)) =>
      new SkipWhileIterable<Int32x4>(this, test);

  Iterable<Int32x4> get reversed => new ReversedListIterable<Int32x4>(this);

  Map<int, Int32x4> asMap() => new ListMapView<Int32x4>(this);

  Iterable<Int32x4> getRange(int start, [int end]) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<Int32x4>(this, start, end);
  }

  Iterator<Int32x4> get iterator => new _TypedListIterator<Int32x4>(this);

  List<Int32x4> toList({bool growable: true}) {
    return new List<Int32x4>.from(this, growable: growable);
  }

  Set<Int32x4> toSet() {
    return new Set<Int32x4>.from(this);
  }

  void forEach(void f(Int32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Int32x4 reduce(Int32x4 combine(Int32x4 value, Int32x4 element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, Int32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(Int32x4 element)) =>
      new MappedIterable<Int32x4, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(Int32x4 element)) =>
      new ExpandIterable<Int32x4, T>(this, f);

  bool every(bool f(Int32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(Int32x4 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  Int32x4 firstWhere(bool test(Int32x4 element), {Int32x4 orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  Int32x4 lastWhere(bool test(Int32x4 element), {Int32x4 orElse()}) {
    var result = null;
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

  Int32x4 singleWhere(bool test(Int32x4 element)) {
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
    throw IterableElementError.noElement();
  }

  Int32x4 elementAt(int index) {
    return this[index];
  }

  void add(Int32x4 value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<Int32x4> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, Int32x4 value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<Int32x4> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(Int32x4 a, Int32x4 b)]) {
    if (compare == null) {
      throw "SIMD don't have default compare.";
    }
    Sort.sort(this, compare);
  }

  int indexOf(Int32x4 element, [int start = 0]) {
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

  int lastIndexOf(Int32x4 element, [int start = null]) {
    if (start == null || start >= this.length) {
      start = this.length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  Int32x4 removeLast() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Int32x4 removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(Int32x4 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(Int32x4 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Int32x4 get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  Int32x4 get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  Int32x4 get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<Int32x4> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List<Int32x4> result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<Int32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [Int32x4 fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

abstract class _Float64x2ListMixin implements List<Float64x2> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  _ByteBuffer get buffer;

  List<Float64x2> _createList(int length);

  bool contains(Object element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random random]) {
    if (random == null) random = new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  void setRange(int start, int end, Iterable<Float64x2> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is _TypedListBase) {
      // Note: _TypedListBase is not related to Iterable<Float64x2> so there is
      // no promotion here.
      final fromAsTypedList = from as _TypedListBase;
      if (this.elementSizeInBytes == fromAsTypedList.elementSizeInBytes) {
        if ((count < 10) && (fromAsTypedList.buffer != this.buffer)) {
          Lists.copy(from as List<Float64x2>, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
            start * elementSizeInBytes + this.offsetInBytes,
            count * elementSizeInBytes,
            fromAsTypedList.buffer._data,
            skipCount * elementSizeInBytes + fromAsTypedList.offsetInBytes,
            ClassID.getID(this),
            ClassID.getID(from))) {
          return;
        }
      } else if (fromAsTypedList.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final fromAsList = from as List<Float64x2>;
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
    if (from is List<Float64x2>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  Iterable<Float64x2> where(bool f(Float64x2 element)) =>
      new WhereIterable<Float64x2>(this, f);

  Iterable<Float64x2> take(int n) => new SubListIterable<Float64x2>(this, 0, n);

  Iterable<Float64x2> takeWhile(bool test(Float64x2 element)) =>
      new TakeWhileIterable<Float64x2>(this, test);

  Iterable<Float64x2> skip(int n) =>
      new SubListIterable<Float64x2>(this, n, null);

  Iterable<Float64x2> skipWhile(bool test(Float64x2 element)) =>
      new SkipWhileIterable<Float64x2>(this, test);

  Iterable<Float64x2> get reversed => new ReversedListIterable<Float64x2>(this);

  Map<int, Float64x2> asMap() => new ListMapView<Float64x2>(this);

  Iterable<Float64x2> getRange(int start, [int end]) {
    RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<Float64x2>(this, start, end);
  }

  Iterator<Float64x2> get iterator => new _TypedListIterator<Float64x2>(this);

  List<Float64x2> toList({bool growable: true}) {
    return new List<Float64x2>.from(this, growable: growable);
  }

  Set<Float64x2> toSet() {
    return new Set<Float64x2>.from(this);
  }

  void forEach(void f(Float64x2 element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Float64x2 reduce(Float64x2 combine(Float64x2 value, Float64x2 element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, Float64x2 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(Float64x2 element)) =>
      new MappedIterable<Float64x2, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(Float64x2 element)) =>
      new ExpandIterable<Float64x2, T>(this, f);

  bool every(bool f(Float64x2 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(Float64x2 element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  Float64x2 firstWhere(bool test(Float64x2 element), {Float64x2 orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  Float64x2 lastWhere(bool test(Float64x2 element), {Float64x2 orElse()}) {
    var result = null;
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

  Float64x2 singleWhere(bool test(Float64x2 element)) {
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
    throw IterableElementError.noElement();
  }

  Float64x2 elementAt(int index) {
    return this[index];
  }

  void add(Float64x2 value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<Float64x2> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, Float64x2 value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<Float64x2> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(Float64x2 a, Float64x2 b)]) {
    if (compare == null) {
      throw "SIMD don't have default compare.";
    }
    Sort.sort(this, compare);
  }

  int indexOf(Float64x2 element, [int start = 0]) {
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

  int lastIndexOf(Float64x2 element, [int start = null]) {
    if (start == null || start >= this.length) {
      start = this.length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  Float64x2 removeLast() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Float64x2 removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(Float64x2 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(Float64x2 element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  Float64x2 get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  Float64x2 get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  Float64x2 get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<Float64x2> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List<Float64x2> result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setAll(int index, Iterable<Float64x2> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [Float64x2 fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

class _ByteBuffer implements ByteBuffer {
  final _TypedList _data;

  _ByteBuffer(this._data);

  factory _ByteBuffer._New(data) => new _ByteBuffer(data);

  // Forward calls to _data.
  int get lengthInBytes => _data.lengthInBytes;
  int get hashCode => _data.hashCode;
  bool operator ==(Object other) =>
      (other is _ByteBuffer) && identical(_data, other._data);

  ByteData asByteData([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes - offsetInBytes;
    }
    return new _ByteDataView(this._data, offsetInBytes, length);
  }

  Int8List asInt8List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes - offsetInBytes;
    }
    return new _Int8ArrayView(this, offsetInBytes, length);
  }

  Uint8List asUint8List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ArrayView(this, offsetInBytes, length);
  }

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ClampedArrayView(this, offsetInBytes, length);
  }

  Int16List asInt16List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Int16List.BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(this, offsetInBytes, length);
  }

  Uint16List asUint16List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Uint16List.BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(this, offsetInBytes, length);
  }

  Int32List asInt32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(this, offsetInBytes, length);
  }

  Uint32List asUint32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Uint32List.BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(this, offsetInBytes, length);
  }

  Int64List asInt64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Int64List.BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(this, offsetInBytes, length);
  }

  Uint64List asUint64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Uint64List.BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(this, offsetInBytes, length);
  }

  Float32List asFloat32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Float32List.BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(this, offsetInBytes, length);
  }

  Float64List asFloat64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Float64List.BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(this, offsetInBytes, length);
  }

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
          Float32x4List.BYTES_PER_ELEMENT;
    }
    return new _Float32x4ArrayView(this, offsetInBytes, length);
  }

  Int32x4List asInt32x4List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length =
          (this.lengthInBytes - offsetInBytes) ~/ Int32x4List.BYTES_PER_ELEMENT;
    }
    return new _Int32x4ArrayView(this, offsetInBytes, length);
  }

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
          Float64x2List.BYTES_PER_ELEMENT;
    }
    return new _Float64x2ArrayView(this, offsetInBytes, length);
  }
}

abstract class _TypedList extends _TypedListBase {
  int get elementSizeInBytes;

  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  _ByteBuffer get buffer => new _ByteBuffer(this);

  // Methods implementing the collection interface.

  int get length native "TypedData_length";

  // Internal utility methods.

  int _getInt8(int offsetInBytes) native "TypedData_GetInt8";
  void _setInt8(int offsetInBytes, int value) native "TypedData_SetInt8";

  int _getUint8(int offsetInBytes) native "TypedData_GetUint8";
  void _setUint8(int offsetInBytes, int value) native "TypedData_SetUint8";

  int _getInt16(int offsetInBytes) native "TypedData_GetInt16";
  void _setInt16(int offsetInBytes, int value) native "TypedData_SetInt16";

  int _getUint16(int offsetInBytes) native "TypedData_GetUint16";
  void _setUint16(int offsetInBytes, int value) native "TypedData_SetUint16";

  int _getInt32(int offsetInBytes) native "TypedData_GetInt32";
  void _setInt32(int offsetInBytes, int value) native "TypedData_SetInt32";

  int _getUint32(int offsetInBytes) native "TypedData_GetUint32";
  void _setUint32(int offsetInBytes, int value) native "TypedData_SetUint32";

  int _getInt64(int offsetInBytes) native "TypedData_GetInt64";
  void _setInt64(int offsetInBytes, int value) native "TypedData_SetInt64";

  int _getUint64(int offsetInBytes) native "TypedData_GetUint64";
  void _setUint64(int offsetInBytes, int value) native "TypedData_SetUint64";

  double _getFloat32(int offsetInBytes) native "TypedData_GetFloat32";
  void _setFloat32(int offsetInBytes, double value)
      native "TypedData_SetFloat32";

  double _getFloat64(int offsetInBytes) native "TypedData_GetFloat64";
  void _setFloat64(int offsetInBytes, double value)
      native "TypedData_SetFloat64";

  Float32x4 _getFloat32x4(int offsetInBytes) native "TypedData_GetFloat32x4";
  void _setFloat32x4(int offsetInBytes, Float32x4 value)
      native "TypedData_SetFloat32x4";

  Int32x4 _getInt32x4(int offsetInBytes) native "TypedData_GetInt32x4";
  void _setInt32x4(int offsetInBytes, Int32x4 value)
      native "TypedData_SetInt32x4";

  Float64x2 _getFloat64x2(int offsetInBytes) native "TypedData_GetFloat64x2";
  void _setFloat64x2(int offsetInBytes, Float64x2 value)
      native "TypedData_SetFloat64x2";

  /**
   * Stores the [CodeUnits] as UTF-16 units into this TypedData at
   * positions [start]..[end] (uint16 indices).
   */
  void _setCodeUnits(
      CodeUnits units, int byteStart, int length, int skipCount) {
    assert(byteStart + length * Uint16List.BYTES_PER_ELEMENT <= lengthInBytes);
    String string = CodeUnits.stringOf(units);
    int sliceEnd = skipCount + length;
    RangeError.checkValidRange(
        skipCount, sliceEnd, string.length, "skipCount", "skipCount + length");
    for (int i = 0; i < length; i++) {
      _setUint16(byteStart + i * Uint16List.BYTES_PER_ELEMENT,
          string.codeUnitAt(skipCount + i));
    }
  }
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) native "TypedData_Int8Array_new";

  @patch
  factory Int8List.fromList(List<int> elements) {
    return new Int8List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Int8List extends _TypedList with _IntListMixin implements Int8List {
  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getInt8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setInt8(index, _toInt8(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int8List _createList(int length) {
    return new Int8List(length);
  }
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) native "TypedData_Uint8Array_new";

  @patch
  factory Uint8List.fromList(List<int> elements) {
    return new Uint8List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Uint8List extends _TypedList with _IntListMixin implements Uint8List {
  // Methods implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toUint8(value));
  }

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8List _createList(int length) {
    return new Uint8List(length);
  }
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) native "TypedData_Uint8ClampedArray_new";

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) {
    return new Uint8ClampedList(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Uint8ClampedList extends _TypedList
    with _IntListMixin
    implements Uint8ClampedList {
  // Methods implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toClampedUint8(value));
  }

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) native "TypedData_Int16Array_new";

  @patch
  factory Int16List.fromList(List<int> elements) {
    return new Int16List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Int16List extends _TypedList with _IntListMixin implements Int16List {
  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt16(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    if (iterable is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Int16List.BYTES_PER_ELEMENT;
      _setCodeUnits(iterable, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, iterable, skipCount);
    }
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int16List _createList(int length) {
    return new Int16List(length);
  }

  int _getIndexedInt16(int index) {
    return _getInt16(index * Int16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt16(int index, int value) {
    _setInt16(index * Int16List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) native "TypedData_Uint16Array_new";

  @patch
  factory Uint16List.fromList(List<int> elements) {
    return new Uint16List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Uint16List extends _TypedList with _IntListMixin implements Uint16List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint16(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    if (iterable is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Uint16List.BYTES_PER_ELEMENT;
      _setCodeUnits(iterable, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, iterable, skipCount);
    }
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint16List _createList(int length) {
    return new Uint16List(length);
  }

  int _getIndexedUint16(int index) {
    return _getUint16(index * Uint16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint16(int index, int value) {
    _setUint16(index * Uint16List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) native "TypedData_Int32Array_new";

  @patch
  factory Int32List.fromList(List<int> elements) {
    return new Int32List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Int32List extends _TypedList with _IntListMixin implements Int32List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32List _createList(int length) {
    return new Int32List(length);
  }

  int _getIndexedInt32(int index) {
    return _getInt32(index * Int32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32(int index, int value) {
    _setInt32(index * Int32List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) native "TypedData_Uint32Array_new";

  @patch
  factory Uint32List.fromList(List<int> elements) {
    return new Uint32List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Uint32List extends _TypedList with _IntListMixin implements Uint32List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint32(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint32List _createList(int length) {
    return new Uint32List(length);
  }

  int _getIndexedUint32(int index) {
    return _getUint32(index * Uint32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint32(int index, int value) {
    _setUint32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) native "TypedData_Int64Array_new";

  @patch
  factory Int64List.fromList(List<int> elements) {
    return new Int64List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Int64List extends _TypedList with _IntListMixin implements Int64List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt64(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int64List _createList(int length) {
    return new Int64List(length);
  }

  int _getIndexedInt64(int index) {
    return _getInt64(index * Int64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt64(int index, int value) {
    _setInt64(index * Int64List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) native "TypedData_Uint64Array_new";

  @patch
  factory Uint64List.fromList(List<int> elements) {
    return new Uint64List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Uint64List extends _TypedList with _IntListMixin implements Uint64List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint64(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint64List _createList(int length) {
    return new Uint64List(length);
  }

  int _getIndexedUint64(int index) {
    return _getUint64(index * Uint64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint64(int index, int value) {
    _setUint64(index * Uint64List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) native "TypedData_Float32Array_new";

  @patch
  factory Float32List.fromList(List<double> elements) {
    return new Float32List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Float32List extends _TypedList
    with _DoubleListMixin
    implements Float32List {
  // Method(s) implementing the List interface.
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32(index);
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32List _createList(int length) {
    return new Float32List(length);
  }

  double _getIndexedFloat32(int index) {
    return _getFloat32(index * Float32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32(int index, double value) {
    _setFloat32(index * Float32List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) native "TypedData_Float64Array_new";

  @patch
  factory Float64List.fromList(List<double> elements) {
    return new Float64List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Float64List extends _TypedList
    with _DoubleListMixin
    implements Float64List {
  // Method(s) implementing the List interface.
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64(index);
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64List _createList(int length) {
    return new Float64List(length);
  }

  double _getIndexedFloat64(int index) {
    return _getFloat64(index * Float64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64(int index, double value) {
    _setFloat64(index * Float64List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) native "TypedData_Float32x4Array_new";

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) {
    return new Float32x4List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Float32x4List extends _TypedList
    with _Float32x4ListMixin
    implements Float32x4List {
  Float32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32x4(index);
  }

  void operator []=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32x4(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32x4List _createList(int length) {
    return new Float32x4List(length);
  }

  Float32x4 _getIndexedFloat32x4(int index) {
    return _getFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32x4(int index, Float32x4 value) {
    _setFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) native "TypedData_Int32x4Array_new";

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) {
    return new Int32x4List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Int32x4List extends _TypedList
    with _Int32x4ListMixin
    implements Int32x4List {
  Int32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32x4(index);
  }

  void operator []=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32x4(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32x4List _createList(int length) {
    return new Int32x4List(length);
  }

  Int32x4 _getIndexedInt32x4(int index) {
    return _getInt32x4(index * Int32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32x4(int index, Int32x4 value) {
    _setInt32x4(index * Int32x4List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) native "TypedData_Float64x2Array_new";

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) {
    return new Float64x2List(elements.length)
      ..setRange(0, elements.length, elements);
  }
}

class _Float64x2List extends _TypedList
    with _Float64x2ListMixin
    implements Float64x2List {
  Float64x2 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64x2(index);
  }

  void operator []=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64x2(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float64x2List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64x2List _createList(int length) {
    return new Float64x2List(length);
  }

  Float64x2 _getIndexedFloat64x2(int index) {
    return _getFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64x2(int index, Float64x2 value) {
    _setFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalInt8Array extends _TypedList
    with _IntListMixin
    implements Int8List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getInt8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setInt8(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int8List _createList(int length) {
    return new Int8List(length);
  }
}

class _ExternalUint8Array extends _TypedList
    with _IntListMixin
    implements Uint8List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toUint8(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8List _createList(int length) {
    return new Uint8List(length);
  }
}

class _ExternalUint8ClampedArray extends _TypedList
    with _IntListMixin
    implements Uint8ClampedList {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toClampedUint8(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }
}

class _ExternalInt16Array extends _TypedList
    with _IntListMixin
    implements Int16List {
  // Method(s) implementing the List interface.

  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt16(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int16List _createList(int length) {
    return new Int16List(length);
  }

  int _getIndexedInt16(int index) {
    return _getInt16(index * Int16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt16(int index, int value) {
    _setInt16(index * Int16List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalUint16Array extends _TypedList
    with _IntListMixin
    implements Uint16List {
  // Method(s) implementing the List interface.

  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint16(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint16List _createList(int length) {
    return new Uint16List(length);
  }

  int _getIndexedUint16(int index) {
    return _getUint16(index * Uint16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint16(int index, int value) {
    _setUint16(index * Uint16List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalInt32Array extends _TypedList
    with _IntListMixin
    implements Int32List {
  // Method(s) implementing the List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32List _createList(int length) {
    return new Int32List(length);
  }

  int _getIndexedInt32(int index) {
    return _getInt32(index * Int32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32(int index, int value) {
    _setInt32(index * Int32List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalUint32Array extends _TypedList
    with _IntListMixin
    implements Uint32List {
  // Method(s) implementing the List interface.

  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint32(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint32List _createList(int length) {
    return new Uint32List(length);
  }

  int _getIndexedUint32(int index) {
    return _getUint32(index * Uint32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint32(int index, int value) {
    _setUint32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalInt64Array extends _TypedList
    with _IntListMixin
    implements Int64List {
  // Method(s) implementing the List interface.

  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt64(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int64List _createList(int length) {
    return new Int64List(length);
  }

  int _getIndexedInt64(int index) {
    return _getInt64(index * Int64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt64(int index, int value) {
    _setInt64(index * Int64List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalUint64Array extends _TypedList
    with _IntListMixin
    implements Uint64List {
  // Method(s) implementing the List interface.

  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint64(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint64List _createList(int length) {
    return new Uint64List(length);
  }

  int _getIndexedUint64(int index) {
    return _getUint64(index * Uint64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint64(int index, int value) {
    _setUint64(index * Uint64List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalFloat32Array extends _TypedList
    with _DoubleListMixin
    implements Float32List {
  // Method(s) implementing the List interface.

  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32(index);
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32List _createList(int length) {
    return new Float32List(length);
  }

  double _getIndexedFloat32(int index) {
    return _getFloat32(index * Float32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32(int index, double value) {
    _setFloat32(index * Float32List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalFloat64Array extends _TypedList
    with _DoubleListMixin
    implements Float64List {
  // Method(s) implementing the List interface.

  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64(index);
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64List _createList(int length) {
    return new Float64List(length);
  }

  double _getIndexedFloat64(int index) {
    return _getFloat64(index * Float64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64(int index, double value) {
    _setFloat64(index * Float64List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalFloat32x4Array extends _TypedList
    with _Float32x4ListMixin
    implements Float32x4List {
  // Method(s) implementing the List interface.

  Float32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32x4(index);
  }

  void operator []=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32x4(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32x4List _createList(int length) {
    return new Float32x4List(length);
  }

  Float32x4 _getIndexedFloat32x4(int index) {
    return _getFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32x4(int index, Float32x4 value) {
    _setFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalInt32x4Array extends _TypedList
    with _Int32x4ListMixin
    implements Int32x4List {
  // Method(s) implementing the List interface.

  Int32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32x4(index);
  }

  void operator []=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32x4(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Int32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32x4List _createList(int length) {
    return new Int32x4List(length);
  }

  Int32x4 _getIndexedInt32x4(int index) {
    return _getInt32x4(index * Int32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32x4(int index, Int32x4 value) {
    _setInt32x4(index * Int32x4List.BYTES_PER_ELEMENT, value);
  }
}

class _ExternalFloat64x2Array extends _TypedList
    with _Float64x2ListMixin
    implements Float64x2List {
  // Method(s) implementing the List interface.
  Float64x2 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64x2(index);
  }

  void operator []=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64x2(index, value);
  }

  // Method(s) implementing the TypedData interface.
  int get elementSizeInBytes {
    return Float64x2List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64x2List _createList(int length) {
    return new Float64x2List(length);
  }

  Float64x2 _getIndexedFloat64x2(int index) {
    return _getFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64x2(int index, Float64x2 value) {
    _setFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT, value);
  }
}

@patch
class Float32x4 {
  @patch
  factory Float32x4(double x, double y, double z, double w)
      native "Float32x4_fromDoubles";

  @patch
  factory Float32x4.splat(double v) native "Float32x4_splat";

  @patch
  factory Float32x4.zero() native "Float32x4_zero";

  @patch
  factory Float32x4.fromInt32x4Bits(Int32x4 x)
      native "Float32x4_fromInt32x4Bits";

  @patch
  factory Float32x4.fromFloat64x2(Float64x2 v) native "Float32x4_fromFloat64x2";
}

class _Float32x4 implements Float32x4 {
  Float32x4 operator +(Float32x4 other) native "Float32x4_add";
  Float32x4 operator -() native "Float32x4_negate";
  Float32x4 operator -(Float32x4 other) native "Float32x4_sub";
  Float32x4 operator *(Float32x4 other) native "Float32x4_mul";
  Float32x4 operator /(Float32x4 other) native "Float32x4_div";
  Int32x4 lessThan(Float32x4 other) native "Float32x4_cmplt";
  Int32x4 lessThanOrEqual(Float32x4 other) native "Float32x4_cmplte";
  Int32x4 greaterThan(Float32x4 other) native "Float32x4_cmpgt";
  Int32x4 greaterThanOrEqual(Float32x4 other) native "Float32x4_cmpgte";
  Int32x4 equal(Float32x4 other) native "Float32x4_cmpequal";
  Int32x4 notEqual(Float32x4 other) native "Float32x4_cmpnequal";
  Float32x4 scale(double s) native "Float32x4_scale";
  Float32x4 abs() native "Float32x4_abs";
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit)
      native "Float32x4_clamp";
  double get x native "Float32x4_getX";
  double get y native "Float32x4_getY";
  double get z native "Float32x4_getZ";
  double get w native "Float32x4_getW";
  int get signMask native "Float32x4_getSignMask";

  Float32x4 shuffle(int mask) native "Float32x4_shuffle";
  Float32x4 shuffleMix(Float32x4 zw, int mask) native "Float32x4_shuffleMix";

  Float32x4 withX(double x) native "Float32x4_setX";
  Float32x4 withY(double y) native "Float32x4_setY";
  Float32x4 withZ(double z) native "Float32x4_setZ";
  Float32x4 withW(double w) native "Float32x4_setW";
  Float32x4 min(Float32x4 other) native "Float32x4_min";
  Float32x4 max(Float32x4 other) native "Float32x4_max";
  Float32x4 sqrt() native "Float32x4_sqrt";
  Float32x4 reciprocal() native "Float32x4_reciprocal";
  Float32x4 reciprocalSqrt() native "Float32x4_reciprocalSqrt";
}

@patch
class Int32x4 {
  @patch
  factory Int32x4(int x, int y, int z, int w) native "Int32x4_fromInts";

  @patch
  factory Int32x4.bool(bool x, bool y, bool z, bool w)
      native "Int32x4_fromBools";

  @patch
  factory Int32x4.fromFloat32x4Bits(Float32x4 x)
      native "Int32x4_fromFloat32x4Bits";
}

class _Int32x4 implements Int32x4 {
  Int32x4 operator |(Int32x4 other) native "Int32x4_or";
  Int32x4 operator &(Int32x4 other) native "Int32x4_and";
  Int32x4 operator ^(Int32x4 other) native "Int32x4_xor";
  Int32x4 operator +(Int32x4 other) native "Int32x4_add";
  Int32x4 operator -(Int32x4 other) native "Int32x4_sub";
  int get x native "Int32x4_getX";
  int get y native "Int32x4_getY";
  int get z native "Int32x4_getZ";
  int get w native "Int32x4_getW";
  int get signMask native "Int32x4_getSignMask";
  Int32x4 shuffle(int mask) native "Int32x4_shuffle";
  Int32x4 shuffleMix(Int32x4 zw, int mask) native "Int32x4_shuffleMix";
  Int32x4 withX(int x) native "Int32x4_setX";
  Int32x4 withY(int y) native "Int32x4_setY";
  Int32x4 withZ(int z) native "Int32x4_setZ";
  Int32x4 withW(int w) native "Int32x4_setW";
  bool get flagX native "Int32x4_getFlagX";
  bool get flagY native "Int32x4_getFlagY";
  bool get flagZ native "Int32x4_getFlagZ";
  bool get flagW native "Int32x4_getFlagW";
  Int32x4 withFlagX(bool x) native "Int32x4_setFlagX";
  Int32x4 withFlagY(bool y) native "Int32x4_setFlagY";
  Int32x4 withFlagZ(bool z) native "Int32x4_setFlagZ";
  Int32x4 withFlagW(bool w) native "Int32x4_setFlagW";
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue)
      native "Int32x4_select";
}

@patch
class Float64x2 {
  @patch
  factory Float64x2(double x, double y) native "Float64x2_fromDoubles";

  @patch
  factory Float64x2.splat(double v) native "Float64x2_splat";

  @patch
  factory Float64x2.zero() native "Float64x2_zero";

  @patch
  factory Float64x2.fromFloat32x4(Float32x4 v) native "Float64x2_fromFloat32x4";
}

class _Float64x2 implements Float64x2 {
  Float64x2 operator +(Float64x2 other) native "Float64x2_add";
  Float64x2 operator -() native "Float64x2_negate";
  Float64x2 operator -(Float64x2 other) native "Float64x2_sub";
  Float64x2 operator *(Float64x2 other) native "Float64x2_mul";
  Float64x2 operator /(Float64x2 other) native "Float64x2_div";
  Float64x2 scale(double s) native "Float64x2_scale";
  Float64x2 abs() native "Float64x2_abs";
  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit)
      native "Float64x2_clamp";
  double get x native "Float64x2_getX";
  double get y native "Float64x2_getY";
  int get signMask native "Float64x2_getSignMask";
  Float64x2 withX(double x) native "Float64x2_setX";
  Float64x2 withY(double y) native "Float64x2_setY";
  Float64x2 min(Float64x2 other) native "Float64x2_min";
  Float64x2 max(Float64x2 other) native "Float64x2_max";
  Float64x2 sqrt() native "Float64x2_sqrt";
}

class _TypedListIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E _current;

  _TypedListIterator(List array)
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

  E get current => _current;
}

class _TypedListView extends _TypedListBase implements TypedData {
  _TypedListView(_ByteBuffer _buffer, int _offset, int _length)
      : _typedData = _buffer._data,
        offsetInBytes = _offset,
        length = _length {}

  // Method(s) implementing the TypedData interface.

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  _ByteBuffer get buffer {
    return _typedData.buffer;
  }

  final _TypedList _typedData;
  final int offsetInBytes;
  final int length;
}

class _Int8ArrayView extends _TypedListView
    with _IntListMixin
    implements Int8List {
  // Constructor.
  _Int8ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Int8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, _offsetInBytes,
        length * Int8List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getInt8(offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt8(
        offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT), _toInt8(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int8List _createList(int length) {
    return new Int8List(length);
  }
}

class _Uint8ArrayView extends _TypedListView
    with _IntListMixin
    implements Uint8List {
  // Constructor.
  _Uint8ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, _offsetInBytes,
        length * Uint8List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint8(
        offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT), _toUint8(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8List _createList(int length) {
    return new Uint8List(length);
  }
}

class _Uint8ClampedArrayView extends _TypedListView
    with _IntListMixin
    implements Uint8ClampedList {
  // Constructor.
  _Uint8ClampedArrayView(_ByteBuffer buffer,
      [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Uint8List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
        _toClampedUint8(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }
}

class _Int16ArrayView extends _TypedListView
    with _IntListMixin
    implements Int16List {
  // Constructor.
  _Int16ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Int16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Int16List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int16List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getInt16(offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt16(
        offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT), _toInt16(value));
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    if (iterable is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Int16List.BYTES_PER_ELEMENT;
      _typedData._setCodeUnits(iterable, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, iterable, skipCount);
    }
  }

  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int16List _createList(int length) {
    return new Int16List(length);
  }
}

class _Uint16ArrayView extends _TypedListView
    with _IntListMixin
    implements Uint16List {
  // Constructor.
  _Uint16ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Uint16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Uint16List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint16List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getUint16(offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint16(
        offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT),
        _toUint16(value));
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    if (iterable is CodeUnits) {
      end = RangeError.checkValidRange(start, end, this.length);
      int length = end - start;
      int byteStart = this.offsetInBytes + start * Uint16List.BYTES_PER_ELEMENT;
      _typedData._setCodeUnits(iterable, byteStart, length, skipCount);
    } else {
      super.setRange(start, end, iterable, skipCount);
    }
  }

  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.

  Uint16List _createList(int length) {
    return new Uint16List(length);
  }
}

class _Int32ArrayView extends _TypedListView
    with _IntListMixin
    implements Int32List {
  // Constructor.
  _Int32ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Int32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Int32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int32List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getInt32(offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt32(
        offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT), _toInt32(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32List _createList(int length) {
    return new Int32List(length);
  }
}

class _Uint32ArrayView extends _TypedListView
    with _IntListMixin
    implements Uint32List {
  // Constructor.
  _Uint32ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Uint32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Uint32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint32List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getUint32(offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint32(
        offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT),
        _toUint32(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint32List _createList(int length) {
    return new Uint32List(length);
  }
}

class _Int64ArrayView extends _TypedListView
    with _IntListMixin
    implements Int64List {
  // Constructor.
  _Int64ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Int64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Int64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int64List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getInt64(offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt64(
        offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT), _toInt64(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int64List _createList(int length) {
    return new Int64List(length);
  }
}

class _Uint64ArrayView extends _TypedListView
    with _IntListMixin
    implements Uint64List {
  // Constructor.
  _Uint64ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Uint64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Uint64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint64List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getUint64(offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint64(
        offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT),
        _toUint64(value));
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Uint64List _createList(int length) {
    return new Uint64List(length);
  }
}

class _Float32ArrayView extends _TypedListView
    with _DoubleListMixin
    implements Float32List {
  // Constructor.
  _Float32ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Float32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Float32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float32List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getFloat32(offsetInBytes + (index * Float32List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat32(
        offsetInBytes + (index * Float32List.BYTES_PER_ELEMENT), value);
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32List _createList(int length) {
    return new Float32List(length);
  }
}

class _Float64ArrayView extends _TypedListView
    with _DoubleListMixin
    implements Float64List {
  // Constructor.
  _Float64ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Float64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Float64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float64List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getFloat64(offsetInBytes + (index * Float64List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat64(
        offsetInBytes + (index * Float64List.BYTES_PER_ELEMENT), value);
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64List _createList(int length) {
    return new Float64List(length);
  }
}

class _Float32x4ArrayView extends _TypedListView
    with _Float32x4ListMixin
    implements Float32x4List {
  // Constructor.
  _Float32x4ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Float32x4List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Float32x4List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float32x4List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  Float32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat32x4(
        offsetInBytes + (index * Float32x4List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat32x4(
        offsetInBytes + (index * Float32x4List.BYTES_PER_ELEMENT), value);
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float32x4List _createList(int length) {
    return new Float32x4List(length);
  }
}

class _Int32x4ArrayView extends _TypedListView
    with _Int32x4ListMixin
    implements Int32x4List {
  // Constructor.
  _Int32x4ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Int32x4List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Int32x4List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int32x4List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  Int32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData
        ._getInt32x4(offsetInBytes + (index * Int32x4List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt32x4(
        offsetInBytes + (index * Int32x4List.BYTES_PER_ELEMENT), value);
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Int32x4List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Int32x4List _createList(int length) {
    return new Int32x4List(length);
  }
}

class _Float64x2ArrayView extends _TypedListView
    with _Float64x2ListMixin
    implements Float64x2List {
  // Constructor.
  _Float64x2ArrayView(_ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
      : super(
            buffer,
            _offsetInBytes,
            _defaultIfNull(
                _length,
                ((buffer.lengthInBytes - _offsetInBytes) ~/
                    Float64x2List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes, offsetInBytes,
        length * Float64x2List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float64x2List.BYTES_PER_ELEMENT);
  }

  // Method(s) implementing List interface.
  Float64x2 operator [](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat64x2(
        offsetInBytes + (index * Float64x2List.BYTES_PER_ELEMENT));
  }

  void operator []=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat64x2(
        offsetInBytes + (index * Float64x2List.BYTES_PER_ELEMENT), value);
  }

  // Method(s) implementing TypedData interface.
  int get elementSizeInBytes {
    return Float64x2List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.
  Float64x2List _createList(int length) {
    return new Float64x2List(length);
  }
}

class _ByteDataView implements ByteData {
  _ByteDataView(_TypedList typedData, int _offsetInBytes, int _lengthInBytes)
      : _typedData = typedData,
        _offset = _offsetInBytes,
        length = _lengthInBytes {
    _rangeCheck(_typedData.lengthInBytes, _offset, length);
  }

  // Method(s) implementing TypedData interface.
  _ByteBuffer get buffer {
    return _typedData.buffer;
  }

  int get lengthInBytes {
    return length;
  }

  int get offsetInBytes {
    return _offset;
  }

  int get elementSizeInBytes {
    return 1;
  }

  // Method(s) implementing ByteData interface.

  int getInt8(int byteOffset) {
    if (byteOffset < 0 || byteOffset >= length) {
      throw new RangeError.index(byteOffset, this, "byteOffset");
    }
    return _typedData._getInt8(_offset + byteOffset);
  }

  void setInt8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      throw new RangeError.index(byteOffset, this, "byteOffset");
    }
    _typedData._setInt8(_offset + byteOffset, value);
  }

  int getUint8(int byteOffset) {
    if (byteOffset < 0 || byteOffset >= length) {
      throw new RangeError.index(byteOffset, this, "byteOffset");
    }
    return _typedData._getUint8(_offset + byteOffset);
  }

  void setUint8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      throw new RangeError.index(byteOffset, this, "byteOffset");
    }
    _typedData._setUint8(_offset + byteOffset, value);
  }

  int getInt16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 2, "byteOffset");
    }
    var result = _typedData._getInt16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap16(result).toSigned(16);
  }

  void setInt16(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 2, "byteOffset");
    }
    _typedData._setInt16(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap16(value));
  }

  int getUint16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 2, "byteOffset");
    }
    var result = _typedData._getUint16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap16(result);
  }

  void setUint16(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 2, "byteOffset");
    }
    _typedData._setUint16(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap16(value));
  }

  int getInt32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    var result = _typedData._getInt32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap32(result).toSigned(32);
  }

  void setInt32(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    _typedData._setInt32(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap32(value));
  }

  int getUint32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    var result = _typedData._getUint32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap32(result);
  }

  void setUint32(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    _typedData._setUint32(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap32(value));
  }

  int getInt64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    var result = _typedData._getInt64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap64(result).toSigned(64);
  }

  void setInt64(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    _typedData._setInt64(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap64(value));
  }

  int getUint64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    var result = _typedData._getUint64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _byteSwap64(result);
  }

  void setUint64(int byteOffset, int value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    _typedData._setUint64(_offset + byteOffset,
        identical(endian, Endianness.HOST_ENDIAN) ? value : _byteSwap64(value));
  }

  double getFloat32(int byteOffset,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return _typedData._getFloat32(_offset + byteOffset);
    }
    _convU32[0] = _byteSwap32(_typedData._getUint32(_offset + byteOffset));
    return _convF32[0];
  }

  void setFloat32(int byteOffset, double value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      _typedData._setFloat32(_offset + byteOffset, value);
      return;
    }
    _convF32[0] = value;
    _typedData._setUint32(_offset + byteOffset, _byteSwap32(_convU32[0]));
  }

  double getFloat64(int byteOffset,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return _typedData._getFloat64(_offset + byteOffset);
    }
    _convU64[0] = _byteSwap64(_typedData._getUint64(_offset + byteOffset));
    return _convF64[0];
  }

  void setFloat64(int byteOffset, double value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 8, "byteOffset");
    }
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      _typedData._setFloat64(_offset + byteOffset, value);
      return;
    }
    _convF64[0] = value;
    _typedData._setUint64(_offset + byteOffset, _byteSwap64(_convU64[0]));
  }

  Float32x4 getFloat32x4(int byteOffset,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    return _typedData._getFloat32x4(_offset + byteOffset);
  }

  void setFloat32x4(int byteOffset, Float32x4 value,
      [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat32x4(_offset + byteOffset, value);
  }

  final _TypedList _typedData;
  final int _offset;
  final int length;
}

int _byteSwap16(int value) {
  return ((value & 0xFF00) >> 8) | ((value & 0x00FF) << 8);
}

int _byteSwap32(int value) {
  value = ((value & 0xFF00FF00) >> 8) | ((value & 0x00FF00FF) << 8);
  value = ((value & 0xFFFF0000) >> 16) | ((value & 0x0000FFFF) << 16);
  return value;
}

int _byteSwap64(int value) {
  return (_byteSwap32(value) << 32) | _byteSwap32(value >> 32);
}

final _convU32 = new Uint32List(2);
final _convU64 = new Uint64List.view(_convU32.buffer);
final _convF32 = new Float32List.view(_convU32.buffer);
final _convF64 = new Float64List.view(_convU32.buffer);

// Top level utility methods.
int _toInt(int value, int mask) {
  value &= mask;
  if (value > (mask >> 1)) value -= mask + 1;
  return value;
}

int _toInt8(int value) {
  return _toInt(value, 0xFF);
}

int _toUint8(int value) {
  return value & 0xFF;
}

int _toClampedUint8(int value) {
  if (value < 0) return 0;
  if (value > 0xFF) return 0xFF;
  return value;
}

int _toInt16(int value) {
  return _toInt(value, 0xFFFF);
}

int _toUint16(int value) {
  return value & 0xFFFF;
}

int _toInt32(int value) {
  return _toInt(value, 0xFFFFFFFF);
}

int _toUint32(int value) {
  return value & 0xFFFFFFFF;
}

// Note: in --limit-ints-to-64-bits mode all integers are 64-bit already.
// Still, it is harmless to apply _uint64Mask because (1 << 64) is 0 (all bits
// are shifted out), so _uint64Mask is -1 (its bit pattern is 0xffffffffffffffff).
const _uint64Mask = (1 << 64) - 1;

int _toInt64(int value) {
  // Avoid bigint mask when possible.
  return (ClassID.getID(value) == ClassID.cidBigint)
      ? _toInt(value, _uint64Mask)
      : value;
}

int _toUint64(int value) {
  // Avoid bigint mask when possible.
  return (ClassID.getID(value) == ClassID.cidBigint)
      ? _toInt(value, _uint64Mask)
      : value;
}

void _rangeCheck(int listLength, int start, int length) {
  if (length < 0) {
    throw new RangeError.value(length);
  }
  if (start < 0) {
    throw new RangeError.value(start);
  }
  if (start + length > listLength) {
    throw new RangeError.value(start + length);
  }
}

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw new RangeError('Offset ($offset) must be a multiple of '
        'BYTES_PER_ELEMENT ($alignment)');
  }
}

int _defaultIfNull(object, value) {
  if (object == null) {
    return value;
  }
  return object;
}
