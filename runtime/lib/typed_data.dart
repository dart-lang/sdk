// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unlike the other SDK libraries, this file is not a patch that is applied to
// dart:typed_data.  Instead, it completely replaces the implementation from the
// SDK.
library dart.typed_data;

import "dart:_internal";
import "dart:collection" show ListBase;
import 'dart:math' show Random;

/**
 * A typed view of a sequence of bytes.
 */
abstract class TypedData {
  /**
   * Returns the number of bytes in the representation of each element in this
   * list.
   */
  int get elementSizeInBytes;

  /**
   * Returns the offset in bytes into the underlying byte buffer of this view.
   */
  int get offsetInBytes;

  /**
   * Returns the length of this view, in bytes.
   */
  int get lengthInBytes;

  /**
   * Returns the byte buffer associated with this object.
   */
  ByteBuffer get buffer;
}


/**
 * Describes endianness to be used when accessing or updating a
 * sequence of bytes.
 */
class Endianness {
  const Endianness._(this._littleEndian);

  static const Endianness BIG_ENDIAN = const Endianness._(false);
  static const Endianness LITTLE_ENDIAN = const Endianness._(true);
  static final Endianness HOST_ENDIAN =
    (new ByteData.view(new Uint16List.fromList([1]).buffer)).getInt8(0) == 1 ?
    LITTLE_ENDIAN : BIG_ENDIAN;

  final bool _littleEndian;
}


/**
 * A fixed-length, random-access sequence of bytes that also provides random
 * and unaligned access to the fixed-width integers and floating point
 * numbers represented by those bytes.
 *
 * `ByteData` may be used to pack and unpack data from external sources
 * (such as networks or files systems), and to process large quantities
 * of numerical data more efficiently than would be possible
 * with ordinary [List] implementations.
 * `ByteData` can save space, by eliminating the need for object headers,
 * and time, by eliminating the need for data copies.
 * Finally, `ByteData` may be used to intentionally reinterpret the bytes
 * representing one arithmetic type as another.
 * For example this code fragment determine what 32-bit signed integer
 * is represented by the bytes of a 32-bit floating point number:
 *
 *     var buffer = new Uint8List(8).buffer;
 *     var bdata = new ByteData.view(buffer);
 *     bdata.setFloat32(0, 3.04);
 *     int huh = bdata.getInt32(0);
 */
class ByteData implements TypedData {
  /**
   * Creates a [ByteData] of the specified length (in elements), all of
   * whose bytes are initially zero.
   */
  factory ByteData(int length) {
    var list = new Uint8List(length);
    return new _ByteDataView(list, 0, length);
  }

  // Called directly from C code.
  factory ByteData._view(TypedData typedData, int offsetInBytes, int length) {
    return new _ByteDataView(typedData, offsetInBytes, length);
  }

  /**
   * Creates an [ByteData] _view_ of the specified region in [buffer].
   *
   * Changes in the [ByteData] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  factory ByteData.view(ByteBuffer buffer,
                        [int offsetInBytes = 0, int length]) {
    return buffer.asByteData(offsetInBytes, length);
  }

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this object, in two's complement binary
   * representation.
   *
   * The return value will be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getInt8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * two's complement binary representation of the specified [value], which
   * must fit in a single byte.
   *
   * In other words, [value] must be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  void setInt8(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this object, in unsigned binary form.
   *
   * The return value will be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getUint8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * unsigned binary representation of the specified [value], which must fit
   * in a single byte.
   *
   * In other words, [value] must be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative,
   * or greater than or equal to the length of this object.
   */
  void setUint8(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the two bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between 2<sup>15</sup> and 2<sup>15</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getInt16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in two bytes.
   *
   * In other words, [value] must lie
   * between 2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setInt16(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getUint16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in two bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setUint16(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the (possibly negative) integer represented by the four bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between 2<sup>31</sup> and 2<sup>31</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getInt32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in four bytes.
   *
   * In other words, [value] must lie
   * between 2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setInt32(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getUint32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in four bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setUint32(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the (possibly negative) integer represented by the eight bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between 2<sup>63</sup> and 2<sup>63</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getInt64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes.
   *
   * In other words, [value] must lie
   * between 2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setInt64(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getUint64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setUint64(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  double getFloat32(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 single-precision binary floating-point
   * (binary32) representation of the specified [value].
   *
   * **Note that this method can lose precision.** The input [value] is
   * a 64-bit floating point value, which will be converted to 32-bit
   * floating point value by IEEE 754 rounding rules before it is stored.
   * If [value] cannot be represented exactly as a binary32, it will be
   * converted to the nearest binary32 value.  If two binary32 values are
   * equally close, the one whose least significant bit is zero will be used.
   * Note that finite (but large) values can be converted to infinity, and
   * small non-zero values can be converted to zero.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setFloat32(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  double getFloat64(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setFloat64(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]);
}


// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.
// This class does not extend ListBase<T> since that would add type arguments
// to instances of _TypeListBase. Instead the subclasses use type specific
// mixins (like _IntListMixin, _DoubleListMixin) to implement ListBase<T>.
abstract class _TypedListBase {

  // Method(s) implementing the Collection interface.
  bool contains(element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  String join([String separator = ""]) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(this, separator);
    return buffer.toString();
  }

  dynamic reduce(dynamic combine(value, element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var i = 0;
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic initialValue, element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable map(f(element)) => new MappedIterable(this, f);

  Iterable expand(Iterable f(element)) => new ExpandIterable(this, f);

  bool every(bool f(element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  dynamic firstWhere(bool test(element), {orElse()}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  dynamic lastWhere(bool test(element), {orElse()}) {
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

  dynamic singleWhere(bool test(element)) {
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

  dynamic elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  // Method(s) implementing the List interface.

  set length(newLength) {
    throw new UnsupportedError(
        "Cannot resize a fixed-length list");
  }

  void add(value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addAll(Iterable value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void insert(int index, value) {
    throw new UnsupportedError(
        "Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable values) {
    throw new UnsupportedError(
        "Cannot insert into a fixed-length list");
  }

  void sort([int compare(a, b)]) {
    if (compare == null) compare = Comparable.compare;
    Sort.sort(this, compare);
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

  int indexOf(element, [int start = 0]) {
    return Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(element, [int start = null]) {
    if (start == null) start = this.length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  int removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  bool remove(Object element) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  bool removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  dynamic get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  dynamic get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  dynamic get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void replaceRange(int start, int end, Iterable iterable) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  List toList({bool growable: true}) {
    return new List.from(this, growable: growable);
  }

  Set toSet() {
    return new Set.from(this);
  }

  List sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    var length = end - start;
    List result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int end, Iterable from, [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length);  // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (from is _TypedListBase) {
      if (this.elementSizeInBytes == from.elementSizeInBytes) {
        if ((count < 10) && (from.buffer != this.buffer)) {
          Lists.copy(from, skipCount, this, start, count);
          return;
        } else if (this.buffer._data._setRange(
              start * elementSizeInBytes + this.offsetInBytes,
              count * elementSizeInBytes,
              from.buffer._data,
              skipCount * elementSizeInBytes + from.offsetInBytes,
              ClassID.getID(this), ClassID.getID(from))) {
          return;
        }
      } else if (from.buffer == this.buffer) {
        // Different element sizes, but same buffer means that we need
        // an intermediate structure.
        // TODO(srdjan): Optimize to skip copying if the range does not overlap.
        final temp_buffer = new List(count);
        for (var i = 0; i < count; i++) {
          temp_buffer[i] = from[skipCount + i];
        }
        for (var i = start; i < end; i++) {
          this[i] = temp_buffer[i - start];
        }
        return;
      }
    }

    if (count == 0) return;
    List otherList;
    int otherStart;
    if (from is List) {
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

  void setAll(int index, Iterable iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }


  // Method(s) implementing Object interface.

  String toString() => ListBase.listToString(this);


  // Internal utility methods.

  // Returns true if operation succeeds.
  // 'fromCid' and 'toCid' may be cid-s of the views and therefore may not
  // match the cids of 'this' and 'from'.
  // Uses toCid and fromCid to decide if clamping is necessary.
  // Element size of toCid and fromCid must match (test at caller).
  bool _setRange(int startInBytes, int lengthInBytes,
                 _TypedListBase from, int startFromInBytes,
                 int toCid, int fromCid)
      native "TypedData_setRange";
}


class _IntListMixin {
  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  Iterable<int> take(int n) => new SubListIterable<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int element)) =>
    new TakeWhileIterable<int>(this, test);

  Iterable<int> skip(int n) => new SubListIterable<int>(this, n, null);

  Iterable<int> skipWhile(bool test(element)) =>
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
}


class _DoubleListMixin {
  Iterable<double> where(bool f(int element)) =>
    new WhereIterable<double>(this, f);

  Iterable<double> take(int n) => new SubListIterable<double>(this, 0, n);

  Iterable<double> takeWhile(bool test(int element)) =>
    new TakeWhileIterable<double>(this, test);

  Iterable<double> skip(int n) => new SubListIterable<double>(this, n, null);

  Iterable<double> skipWhile(bool test(element)) =>
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
}


class _Float32x4ListMixin {
  Iterable<Float32x4> where(bool f(int element)) =>
    new WhereIterable<Float32x4>(this, f);

  Iterable<Float32x4> take(int n) => new SubListIterable<Float32x4>(this, 0, n);

  Iterable<Float32x4> takeWhile(bool test(int element)) =>
    new TakeWhileIterable<Float32x4>(this, test);

  Iterable<Float32x4> skip(int n) =>
    new SubListIterable<Float32x4>(this, n, null);

  Iterable<Float32x4> skipWhile(bool test(element)) =>
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
}


class _Int32x4ListMixin {
  Iterable<Int32x4> where(bool f(int element)) =>
    new WhereIterable<Int32x4>(this, f);

  Iterable<Int32x4> take(int n) => new SubListIterable<Int32x4>(this, 0, n);

  Iterable<Int32x4> takeWhile(bool test(int element)) =>
    new TakeWhileIterable<Int32x4>(this, test);

  Iterable<Int32x4> skip(int n) => new SubListIterable<Int32x4>(this, n, null);

  Iterable<Int32x4> skipWhile(bool test(element)) =>
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
}


class _Float64x2ListMixin {
  Iterable<Float64x2> where(bool f(int element)) =>
    new WhereIterable<Float64x2>(this, f);

  Iterable<Float64x2> take(int n) => new SubListIterable<Float64x2>(this, 0, n);

  Iterable<Float64x2> takeWhile(bool test(int element)) =>
    new TakeWhileIterable<Float64x2>(this, test);

  Iterable<Float64x2> skip(int n) =>
    new SubListIterable<Float64x2>(this, n, null);

  Iterable<Float64x2> skipWhile(bool test(element)) =>
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
}


class ByteBuffer {
  final _TypedList _data;

  ByteBuffer(this._data);

  factory ByteBuffer._New(data) => new ByteBuffer(data);

  // Forward calls to _data.
  int get lengthInBytes => _data.lengthInBytes;
  int get hashCode => _data.hashCode;
  bool operator==(Object other) =>
      (other is ByteBuffer) && identical(_data, other._data);

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
      length = (this.lengthInBytes - offsetInBytes) ~/
               Int16List.BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(this, offsetInBytes, length);
  }

  Uint16List asUint16List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Uint16List.BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(this, offsetInBytes, length);
  }

  Int32List asInt32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(this, offsetInBytes, length);
  }

  Uint32List asUint32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Uint32List.BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(this, offsetInBytes, length);
  }

  Int64List asInt64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Int64List.BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(this, offsetInBytes, length);
  }

  Uint64List asUint64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Uint64List.BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(this, offsetInBytes, length);
  }

  Float32List asFloat32List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Float32List.BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(this, offsetInBytes, length);
  }

  Float64List asFloat64List([int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (this.lengthInBytes - offsetInBytes) ~/
               Float64List.BYTES_PER_ELEMENT;
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
      length = (this.lengthInBytes - offsetInBytes) ~/
               Int32x4List.BYTES_PER_ELEMENT;
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
  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer => new ByteBuffer(this);

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
  void _setCodeUnits(CodeUnits units,
                     int byteStart, int length, int skipCount) {
    assert(byteStart + length * Uint16List.BYTES_PER_ELEMENT <= lengthInBytes);
    String string = CodeUnits.stringOf(units);
    int sliceEnd = skipCount + length;
    RangeError.checkValidRange(skipCount, sliceEnd,
                               string.length,
                               "skipCount", "skipCount + length");
    for (int i = 0; i < length; i++) {
      _setUint16(byteStart + i * Uint16List.BYTES_PER_ELEMENT,
                 string.codeUnitAt(skipCount + i));
    }
  }
}


class Int8List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Int8List(int length) native "TypedData_Int8Array_new";

  factory Int8List.fromList(List<int> elements) {
    return new Int8List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Int8List.view(ByteBuffer buffer,
                        [int offsetInBytes = 0, int length]) {
    return buffer.asInt8List(offsetInBytes, length);
  }

  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setInt8(index, _toInt8(value));
  }

  static const int BYTES_PER_ELEMENT = 1;

  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int8List _createList(int length) {
    return new Int8List(length);
  }
}


class Uint8List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Uint8List(int length) native "TypedData_Uint8Array_new";

  factory Uint8List.fromList(List<int> elements) {
    return new Uint8List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Uint8List.view(ByteBuffer buffer,
                         [int offsetInBytes = 0, int length]) {
    return buffer.asUint8List(offsetInBytes, length);
  }

  // Methods implementing List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toUint8(value));
  }

  static const int BYTES_PER_ELEMENT = 1;

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.

  Uint8List _createList(int length) {
    return new Uint8List(length);
  }
}


class Uint8ClampedList extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Uint8ClampedList(int length) native "TypedData_Uint8ClampedArray_new";

  factory Uint8ClampedList.fromList(List<int> elements) {
    return new Uint8ClampedList(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Uint8ClampedList.view(ByteBuffer buffer,
                                [int offsetInBytes = 0, int length]) {
    return buffer.asUint8ClampedList(offsetInBytes, length);
  }

  // Methods implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setUint8(index, _toClampedUint8(value));
  }

  static const int BYTES_PER_ELEMENT = 1;

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }
}


class Int16List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Int16List(int length) native "TypedData_Int16Array_new";

  factory Int16List.fromList(List<int> elements) {
    return new Int16List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Int16List.view(ByteBuffer buffer,
                         [int offsetInBytes = 0, int length]) {
    return buffer.asInt16List(offsetInBytes, length);
  }

  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
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
  static const int BYTES_PER_ELEMENT = 2;

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


class Uint16List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Uint16List(int length) native "TypedData_Uint16Array_new";

  factory Uint16List.fromList(List<int> elements) {
    return new Uint16List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Uint16List.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    return buffer.asUint16List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
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
  static const int BYTES_PER_ELEMENT = 2;

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


class Int32List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Int32List(int length) native "TypedData_Int32Array_new";

  factory Int32List.fromList(List<int> elements) {
    return new Int32List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Int32List.view(ByteBuffer buffer,
                         [int offsetInBytes = 0, int length]) {
    return buffer.asInt32List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32(index, _toInt32(value));
  }


  // Method(s) implementing TypedData interface.
  static const int BYTES_PER_ELEMENT = 4;

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


class Uint32List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Uint32List(int length) native "TypedData_Uint32Array_new";

  factory Uint32List.fromList(List<int> elements) {
    return new Uint32List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Uint32List.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    return buffer.asUint32List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint32(index, _toUint32(value));
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 4;

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


class Int64List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Int64List(int length) native "TypedData_Int64Array_new";

  factory Int64List.fromList(List<int> elements) {
    return new Int64List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Int64List.view(ByteBuffer buffer,
                         [int offsetInBytes = 0, int length]) {
    return buffer.asInt64List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt64(index, _toInt64(value));
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 8;

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


class Uint64List extends _TypedList with _IntListMixin implements List<int>, TypedData {
  // Factory constructors.

  factory Uint64List(int length) native "TypedData_Uint64Array_new";

  factory Uint64List.fromList(List<int> elements) {
    return new Uint64List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Uint64List.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    return buffer.asUint64List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedUint64(index, _toUint64(value));
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 8;

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


class Float32List extends _TypedList with _DoubleListMixin implements List<double>, TypedData {
  // Factory constructors.

  factory Float32List(int length) native "TypedData_Float32Array_new";

  factory Float32List.fromList(List<double> elements) {
    return new Float32List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Float32List.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    return buffer.asFloat32List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32(index, value);
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 4;

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


class Float64List extends _TypedList with _DoubleListMixin implements List<double>, TypedData {
  // Factory constructors.

  factory Float64List(int length) native "TypedData_Float64Array_new";

  factory Float64List.fromList(List<double> elements) {
    return new Float64List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Float64List.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    return buffer.asFloat64List(offsetInBytes, length);
  }

  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64(index, value);
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 8;

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


class Float32x4List extends _TypedList with _Float32x4ListMixin implements List<Float32x4>, TypedData {
  // Factory constructors.

  factory Float32x4List(int length) native "TypedData_Float32x4Array_new";

  factory Float32x4List.fromList(List<Float32x4> elements) {
    return new Float32x4List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Float32x4List.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    return buffer.asFloat32x4List(offsetInBytes, length);
  }

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat32x4(index, value);
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 16;

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


class Int32x4List extends _TypedList with _Int32x4ListMixin implements List<Int32x4>, TypedData {
  // Factory constructors.

  factory Int32x4List(int length) native "TypedData_Int32x4Array_new";

  factory Int32x4List.fromList(List<Int32x4> elements) {
    return new Int32x4List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Int32x4List.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    return buffer.asInt32x4List(offsetInBytes, length);
  }

  Int32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32x4(index);
  }

  void operator[]=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedInt32x4(index, value);
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 16;

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


class Float64x2List extends _TypedList with _Float64x2ListMixin implements List<Float64x2>, TypedData {
  // Factory constructors.

  factory Float64x2List(int length) native "TypedData_Float64x2Array_new";

  factory Float64x2List.fromList(List<Float64x2> elements) {
    return new Float64x2List(elements.length)
        ..setRange(0, elements.length, elements);
  }

  factory Float64x2List.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    return buffer.asFloat64x2List(offsetInBytes, length);
  }

  Float64x2 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64x2(index);
  }

  void operator[]=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _setIndexedFloat64x2(index, value);
  }


  // Method(s) implementing the TypedData interface.
  static const int BYTES_PER_ELEMENT = 16;

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


class _ExternalInt8Array extends _TypedList with _IntListMixin implements Int8List {
  // Method(s) implementing the List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalUint8Array extends _TypedList with _IntListMixin implements Uint8List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalUint8ClampedArray extends _TypedList with _IntListMixin implements Uint8ClampedList {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalInt16Array extends _TypedList with _IntListMixin implements Int16List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalUint16Array extends _TypedList with _IntListMixin implements Uint16List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalInt32Array extends _TypedList with _IntListMixin implements Int32List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalUint32Array extends _TypedList with _IntListMixin implements Uint32List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalInt64Array extends _TypedList with _IntListMixin implements Int64List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalUint64Array extends _TypedList with _IntListMixin implements Uint64List {
  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
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


class _ExternalFloat32Array extends _TypedList with _DoubleListMixin implements Float32List {
  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
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


class _ExternalFloat64Array extends _TypedList with _DoubleListMixin implements Float64List {
  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
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


class _ExternalFloat32x4Array extends _TypedList with _Float32x4ListMixin implements Float32x4List {
  // Method(s) implementing the List interface.

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
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


class _ExternalInt32x4Array extends _TypedList with _Int32x4ListMixin implements Int32x4List {
  // Method(s) implementing the List interface.

  Int32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedInt32x4(index);
  }

  void operator[]=(int index, Int32x4 value) {
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


class _ExternalFloat64x2Array extends _TypedList with _Float64x2ListMixin implements Float64x2List {
  // Method(s) implementing the List interface.

  Float64x2 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _getIndexedFloat64x2(index);
  }

  void operator[]=(int index, Float64x2 value) {
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


class Float32x4 {
  factory Float32x4(double x, double y, double z, double w)
      native "Float32x4_fromDoubles";
  factory Float32x4.splat(double v) native "Float32x4_splat";
  factory Float32x4.zero() native "Float32x4_zero";
  factory Float32x4.fromInt32x4Bits(Int32x4 x)
      native "Float32x4_fromInt32x4Bits";
  factory Float32x4.fromFloat64x2(Float64x2 v)
      native "Float32x4_fromFloat64x2";
  Float32x4 operator +(Float32x4 other) {
    return _add(other);
  }
  Float32x4 _add(Float32x4 other) native "Float32x4_add";
  Float32x4 operator -() {
    return _negate();
  }
  Float32x4 _negate() native "Float32x4_negate";
  Float32x4 operator -(Float32x4 other) {
    return _sub(other);
  }
  Float32x4 _sub(Float32x4 other) native "Float32x4_sub";
  Float32x4 operator *(Float32x4 other) {
    return _mul(other);
  }
  Float32x4 _mul(Float32x4 other) native "Float32x4_mul";
  Float32x4 operator /(Float32x4 other) {
    return _div(other);
  }
  Float32x4 _div(Float32x4 other) native "Float32x4_div";
  Int32x4 lessThan(Float32x4 other) {
    return _cmplt(other);
  }
  Int32x4 _cmplt(Float32x4 other) native "Float32x4_cmplt";
  Int32x4 lessThanOrEqual(Float32x4 other) {
    return _cmplte(other);
  }
  Int32x4 _cmplte(Float32x4 other) native "Float32x4_cmplte";
  Int32x4 greaterThan(Float32x4 other) {
    return _cmpgt(other);
  }
  Int32x4 _cmpgt(Float32x4 other) native "Float32x4_cmpgt";
  Int32x4 greaterThanOrEqual(Float32x4 other) {
    return _cmpgte(other);
  }
  Int32x4 _cmpgte(Float32x4 other) native "Float32x4_cmpgte";
  Int32x4 equal(Float32x4 other) {
    return _cmpequal(other);
  }
  Int32x4 _cmpequal(Float32x4 other)
      native "Float32x4_cmpequal";
  Int32x4 notEqual(Float32x4 other) {
    return _cmpnequal(other);
  }
  Int32x4 _cmpnequal(Float32x4 other)
      native "Float32x4_cmpnequal";
  Float32x4 scale(double s) {
    return _scale(s);
  }
  Float32x4 _scale(double s) native "Float32x4_scale";
  Float32x4 abs() {
    return _abs();
  }
  Float32x4 _abs() native "Float32x4_abs";
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) {
    return _clamp(lowerLimit, upperLimit);
  }
  Float32x4 _clamp(Float32x4 lowerLimit, Float32x4 upperLimit)
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
  Float32x4 min(Float32x4 other) {
    return _min(other);
  }
  Float32x4 _min(Float32x4 other) native "Float32x4_min";
  Float32x4 max(Float32x4 other) {
    return _max(other);
  }
  Float32x4 _max(Float32x4 other) native "Float32x4_max";
  Float32x4 sqrt() {
    return _sqrt();
  }
  Float32x4 _sqrt() native "Float32x4_sqrt";
  Float32x4 reciprocal() {
    return _reciprocal();
  }
  Float32x4 _reciprocal() native "Float32x4_reciprocal";
  Float32x4 reciprocalSqrt() {
    return _reciprocalSqrt();
  }
  Float32x4 _reciprocalSqrt() native "Float32x4_reciprocalSqrt";

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int XXXX = 0x0;
  static const int XXXY = 0x40;
  static const int XXXZ = 0x80;
  static const int XXXW = 0xC0;
  static const int XXYX = 0x10;
  static const int XXYY = 0x50;
  static const int XXYZ = 0x90;
  static const int XXYW = 0xD0;
  static const int XXZX = 0x20;
  static const int XXZY = 0x60;
  static const int XXZZ = 0xA0;
  static const int XXZW = 0xE0;
  static const int XXWX = 0x30;
  static const int XXWY = 0x70;
  static const int XXWZ = 0xB0;
  static const int XXWW = 0xF0;
  static const int XYXX = 0x4;
  static const int XYXY = 0x44;
  static const int XYXZ = 0x84;
  static const int XYXW = 0xC4;
  static const int XYYX = 0x14;
  static const int XYYY = 0x54;
  static const int XYYZ = 0x94;
  static const int XYYW = 0xD4;
  static const int XYZX = 0x24;
  static const int XYZY = 0x64;
  static const int XYZZ = 0xA4;
  static const int XYZW = 0xE4;
  static const int XYWX = 0x34;
  static const int XYWY = 0x74;
  static const int XYWZ = 0xB4;
  static const int XYWW = 0xF4;
  static const int XZXX = 0x8;
  static const int XZXY = 0x48;
  static const int XZXZ = 0x88;
  static const int XZXW = 0xC8;
  static const int XZYX = 0x18;
  static const int XZYY = 0x58;
  static const int XZYZ = 0x98;
  static const int XZYW = 0xD8;
  static const int XZZX = 0x28;
  static const int XZZY = 0x68;
  static const int XZZZ = 0xA8;
  static const int XZZW = 0xE8;
  static const int XZWX = 0x38;
  static const int XZWY = 0x78;
  static const int XZWZ = 0xB8;
  static const int XZWW = 0xF8;
  static const int XWXX = 0xC;
  static const int XWXY = 0x4C;
  static const int XWXZ = 0x8C;
  static const int XWXW = 0xCC;
  static const int XWYX = 0x1C;
  static const int XWYY = 0x5C;
  static const int XWYZ = 0x9C;
  static const int XWYW = 0xDC;
  static const int XWZX = 0x2C;
  static const int XWZY = 0x6C;
  static const int XWZZ = 0xAC;
  static const int XWZW = 0xEC;
  static const int XWWX = 0x3C;
  static const int XWWY = 0x7C;
  static const int XWWZ = 0xBC;
  static const int XWWW = 0xFC;
  static const int YXXX = 0x1;
  static const int YXXY = 0x41;
  static const int YXXZ = 0x81;
  static const int YXXW = 0xC1;
  static const int YXYX = 0x11;
  static const int YXYY = 0x51;
  static const int YXYZ = 0x91;
  static const int YXYW = 0xD1;
  static const int YXZX = 0x21;
  static const int YXZY = 0x61;
  static const int YXZZ = 0xA1;
  static const int YXZW = 0xE1;
  static const int YXWX = 0x31;
  static const int YXWY = 0x71;
  static const int YXWZ = 0xB1;
  static const int YXWW = 0xF1;
  static const int YYXX = 0x5;
  static const int YYXY = 0x45;
  static const int YYXZ = 0x85;
  static const int YYXW = 0xC5;
  static const int YYYX = 0x15;
  static const int YYYY = 0x55;
  static const int YYYZ = 0x95;
  static const int YYYW = 0xD5;
  static const int YYZX = 0x25;
  static const int YYZY = 0x65;
  static const int YYZZ = 0xA5;
  static const int YYZW = 0xE5;
  static const int YYWX = 0x35;
  static const int YYWY = 0x75;
  static const int YYWZ = 0xB5;
  static const int YYWW = 0xF5;
  static const int YZXX = 0x9;
  static const int YZXY = 0x49;
  static const int YZXZ = 0x89;
  static const int YZXW = 0xC9;
  static const int YZYX = 0x19;
  static const int YZYY = 0x59;
  static const int YZYZ = 0x99;
  static const int YZYW = 0xD9;
  static const int YZZX = 0x29;
  static const int YZZY = 0x69;
  static const int YZZZ = 0xA9;
  static const int YZZW = 0xE9;
  static const int YZWX = 0x39;
  static const int YZWY = 0x79;
  static const int YZWZ = 0xB9;
  static const int YZWW = 0xF9;
  static const int YWXX = 0xD;
  static const int YWXY = 0x4D;
  static const int YWXZ = 0x8D;
  static const int YWXW = 0xCD;
  static const int YWYX = 0x1D;
  static const int YWYY = 0x5D;
  static const int YWYZ = 0x9D;
  static const int YWYW = 0xDD;
  static const int YWZX = 0x2D;
  static const int YWZY = 0x6D;
  static const int YWZZ = 0xAD;
  static const int YWZW = 0xED;
  static const int YWWX = 0x3D;
  static const int YWWY = 0x7D;
  static const int YWWZ = 0xBD;
  static const int YWWW = 0xFD;
  static const int ZXXX = 0x2;
  static const int ZXXY = 0x42;
  static const int ZXXZ = 0x82;
  static const int ZXXW = 0xC2;
  static const int ZXYX = 0x12;
  static const int ZXYY = 0x52;
  static const int ZXYZ = 0x92;
  static const int ZXYW = 0xD2;
  static const int ZXZX = 0x22;
  static const int ZXZY = 0x62;
  static const int ZXZZ = 0xA2;
  static const int ZXZW = 0xE2;
  static const int ZXWX = 0x32;
  static const int ZXWY = 0x72;
  static const int ZXWZ = 0xB2;
  static const int ZXWW = 0xF2;
  static const int ZYXX = 0x6;
  static const int ZYXY = 0x46;
  static const int ZYXZ = 0x86;
  static const int ZYXW = 0xC6;
  static const int ZYYX = 0x16;
  static const int ZYYY = 0x56;
  static const int ZYYZ = 0x96;
  static const int ZYYW = 0xD6;
  static const int ZYZX = 0x26;
  static const int ZYZY = 0x66;
  static const int ZYZZ = 0xA6;
  static const int ZYZW = 0xE6;
  static const int ZYWX = 0x36;
  static const int ZYWY = 0x76;
  static const int ZYWZ = 0xB6;
  static const int ZYWW = 0xF6;
  static const int ZZXX = 0xA;
  static const int ZZXY = 0x4A;
  static const int ZZXZ = 0x8A;
  static const int ZZXW = 0xCA;
  static const int ZZYX = 0x1A;
  static const int ZZYY = 0x5A;
  static const int ZZYZ = 0x9A;
  static const int ZZYW = 0xDA;
  static const int ZZZX = 0x2A;
  static const int ZZZY = 0x6A;
  static const int ZZZZ = 0xAA;
  static const int ZZZW = 0xEA;
  static const int ZZWX = 0x3A;
  static const int ZZWY = 0x7A;
  static const int ZZWZ = 0xBA;
  static const int ZZWW = 0xFA;
  static const int ZWXX = 0xE;
  static const int ZWXY = 0x4E;
  static const int ZWXZ = 0x8E;
  static const int ZWXW = 0xCE;
  static const int ZWYX = 0x1E;
  static const int ZWYY = 0x5E;
  static const int ZWYZ = 0x9E;
  static const int ZWYW = 0xDE;
  static const int ZWZX = 0x2E;
  static const int ZWZY = 0x6E;
  static const int ZWZZ = 0xAE;
  static const int ZWZW = 0xEE;
  static const int ZWWX = 0x3E;
  static const int ZWWY = 0x7E;
  static const int ZWWZ = 0xBE;
  static const int ZWWW = 0xFE;
  static const int WXXX = 0x3;
  static const int WXXY = 0x43;
  static const int WXXZ = 0x83;
  static const int WXXW = 0xC3;
  static const int WXYX = 0x13;
  static const int WXYY = 0x53;
  static const int WXYZ = 0x93;
  static const int WXYW = 0xD3;
  static const int WXZX = 0x23;
  static const int WXZY = 0x63;
  static const int WXZZ = 0xA3;
  static const int WXZW = 0xE3;
  static const int WXWX = 0x33;
  static const int WXWY = 0x73;
  static const int WXWZ = 0xB3;
  static const int WXWW = 0xF3;
  static const int WYXX = 0x7;
  static const int WYXY = 0x47;
  static const int WYXZ = 0x87;
  static const int WYXW = 0xC7;
  static const int WYYX = 0x17;
  static const int WYYY = 0x57;
  static const int WYYZ = 0x97;
  static const int WYYW = 0xD7;
  static const int WYZX = 0x27;
  static const int WYZY = 0x67;
  static const int WYZZ = 0xA7;
  static const int WYZW = 0xE7;
  static const int WYWX = 0x37;
  static const int WYWY = 0x77;
  static const int WYWZ = 0xB7;
  static const int WYWW = 0xF7;
  static const int WZXX = 0xB;
  static const int WZXY = 0x4B;
  static const int WZXZ = 0x8B;
  static const int WZXW = 0xCB;
  static const int WZYX = 0x1B;
  static const int WZYY = 0x5B;
  static const int WZYZ = 0x9B;
  static const int WZYW = 0xDB;
  static const int WZZX = 0x2B;
  static const int WZZY = 0x6B;
  static const int WZZZ = 0xAB;
  static const int WZZW = 0xEB;
  static const int WZWX = 0x3B;
  static const int WZWY = 0x7B;
  static const int WZWZ = 0xBB;
  static const int WZWW = 0xFB;
  static const int WWXX = 0xF;
  static const int WWXY = 0x4F;
  static const int WWXZ = 0x8F;
  static const int WWXW = 0xCF;
  static const int WWYX = 0x1F;
  static const int WWYY = 0x5F;
  static const int WWYZ = 0x9F;
  static const int WWYW = 0xDF;
  static const int WWZX = 0x2F;
  static const int WWZY = 0x6F;
  static const int WWZZ = 0xAF;
  static const int WWZW = 0xEF;
  static const int WWWX = 0x3F;
  static const int WWWY = 0x7F;
  static const int WWWZ = 0xBF;
  static const int WWWW = 0xFF;

}


class Int32x4 {
  factory Int32x4(int x, int y, int z, int w)
      native "Int32x4_fromInts";
  factory Int32x4.bool(bool x, bool y, bool z, bool w)
      native "Int32x4_fromBools";
  factory Int32x4.fromFloat32x4Bits(Float32x4 x)
      native "Int32x4_fromFloat32x4Bits";
  Int32x4 operator |(Int32x4 other) {
    return _or(other);
  }
  Int32x4 _or(Int32x4 other) native "Int32x4_or";
  Int32x4 operator &(Int32x4 other) {
    return _and(other);
  }
  Int32x4 _and(Int32x4 other) native "Int32x4_and";
  Int32x4 operator ^(Int32x4 other) {
    return _xor(other);
  }
  Int32x4 _xor(Int32x4 other) native "Int32x4_xor";
  Int32x4 operator +(Int32x4 other) {
    return _add(other);
  }
  Int32x4 _add(Int32x4 other) native "Int32x4_add";
  Int32x4 operator -(Int32x4 other) {
    return _sub(other);
  }
  Int32x4 _sub(Int32x4 other) native "Int32x4_sub";
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
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue) {
    return _select(trueValue, falseValue);
  }
  Float32x4 _select(Float32x4 trueValue, Float32x4 falseValue)
      native "Int32x4_select";

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int XXXX = 0x0;
  static const int XXXY = 0x40;
  static const int XXXZ = 0x80;
  static const int XXXW = 0xC0;
  static const int XXYX = 0x10;
  static const int XXYY = 0x50;
  static const int XXYZ = 0x90;
  static const int XXYW = 0xD0;
  static const int XXZX = 0x20;
  static const int XXZY = 0x60;
  static const int XXZZ = 0xA0;
  static const int XXZW = 0xE0;
  static const int XXWX = 0x30;
  static const int XXWY = 0x70;
  static const int XXWZ = 0xB0;
  static const int XXWW = 0xF0;
  static const int XYXX = 0x4;
  static const int XYXY = 0x44;
  static const int XYXZ = 0x84;
  static const int XYXW = 0xC4;
  static const int XYYX = 0x14;
  static const int XYYY = 0x54;
  static const int XYYZ = 0x94;
  static const int XYYW = 0xD4;
  static const int XYZX = 0x24;
  static const int XYZY = 0x64;
  static const int XYZZ = 0xA4;
  static const int XYZW = 0xE4;
  static const int XYWX = 0x34;
  static const int XYWY = 0x74;
  static const int XYWZ = 0xB4;
  static const int XYWW = 0xF4;
  static const int XZXX = 0x8;
  static const int XZXY = 0x48;
  static const int XZXZ = 0x88;
  static const int XZXW = 0xC8;
  static const int XZYX = 0x18;
  static const int XZYY = 0x58;
  static const int XZYZ = 0x98;
  static const int XZYW = 0xD8;
  static const int XZZX = 0x28;
  static const int XZZY = 0x68;
  static const int XZZZ = 0xA8;
  static const int XZZW = 0xE8;
  static const int XZWX = 0x38;
  static const int XZWY = 0x78;
  static const int XZWZ = 0xB8;
  static const int XZWW = 0xF8;
  static const int XWXX = 0xC;
  static const int XWXY = 0x4C;
  static const int XWXZ = 0x8C;
  static const int XWXW = 0xCC;
  static const int XWYX = 0x1C;
  static const int XWYY = 0x5C;
  static const int XWYZ = 0x9C;
  static const int XWYW = 0xDC;
  static const int XWZX = 0x2C;
  static const int XWZY = 0x6C;
  static const int XWZZ = 0xAC;
  static const int XWZW = 0xEC;
  static const int XWWX = 0x3C;
  static const int XWWY = 0x7C;
  static const int XWWZ = 0xBC;
  static const int XWWW = 0xFC;
  static const int YXXX = 0x1;
  static const int YXXY = 0x41;
  static const int YXXZ = 0x81;
  static const int YXXW = 0xC1;
  static const int YXYX = 0x11;
  static const int YXYY = 0x51;
  static const int YXYZ = 0x91;
  static const int YXYW = 0xD1;
  static const int YXZX = 0x21;
  static const int YXZY = 0x61;
  static const int YXZZ = 0xA1;
  static const int YXZW = 0xE1;
  static const int YXWX = 0x31;
  static const int YXWY = 0x71;
  static const int YXWZ = 0xB1;
  static const int YXWW = 0xF1;
  static const int YYXX = 0x5;
  static const int YYXY = 0x45;
  static const int YYXZ = 0x85;
  static const int YYXW = 0xC5;
  static const int YYYX = 0x15;
  static const int YYYY = 0x55;
  static const int YYYZ = 0x95;
  static const int YYYW = 0xD5;
  static const int YYZX = 0x25;
  static const int YYZY = 0x65;
  static const int YYZZ = 0xA5;
  static const int YYZW = 0xE5;
  static const int YYWX = 0x35;
  static const int YYWY = 0x75;
  static const int YYWZ = 0xB5;
  static const int YYWW = 0xF5;
  static const int YZXX = 0x9;
  static const int YZXY = 0x49;
  static const int YZXZ = 0x89;
  static const int YZXW = 0xC9;
  static const int YZYX = 0x19;
  static const int YZYY = 0x59;
  static const int YZYZ = 0x99;
  static const int YZYW = 0xD9;
  static const int YZZX = 0x29;
  static const int YZZY = 0x69;
  static const int YZZZ = 0xA9;
  static const int YZZW = 0xE9;
  static const int YZWX = 0x39;
  static const int YZWY = 0x79;
  static const int YZWZ = 0xB9;
  static const int YZWW = 0xF9;
  static const int YWXX = 0xD;
  static const int YWXY = 0x4D;
  static const int YWXZ = 0x8D;
  static const int YWXW = 0xCD;
  static const int YWYX = 0x1D;
  static const int YWYY = 0x5D;
  static const int YWYZ = 0x9D;
  static const int YWYW = 0xDD;
  static const int YWZX = 0x2D;
  static const int YWZY = 0x6D;
  static const int YWZZ = 0xAD;
  static const int YWZW = 0xED;
  static const int YWWX = 0x3D;
  static const int YWWY = 0x7D;
  static const int YWWZ = 0xBD;
  static const int YWWW = 0xFD;
  static const int ZXXX = 0x2;
  static const int ZXXY = 0x42;
  static const int ZXXZ = 0x82;
  static const int ZXXW = 0xC2;
  static const int ZXYX = 0x12;
  static const int ZXYY = 0x52;
  static const int ZXYZ = 0x92;
  static const int ZXYW = 0xD2;
  static const int ZXZX = 0x22;
  static const int ZXZY = 0x62;
  static const int ZXZZ = 0xA2;
  static const int ZXZW = 0xE2;
  static const int ZXWX = 0x32;
  static const int ZXWY = 0x72;
  static const int ZXWZ = 0xB2;
  static const int ZXWW = 0xF2;
  static const int ZYXX = 0x6;
  static const int ZYXY = 0x46;
  static const int ZYXZ = 0x86;
  static const int ZYXW = 0xC6;
  static const int ZYYX = 0x16;
  static const int ZYYY = 0x56;
  static const int ZYYZ = 0x96;
  static const int ZYYW = 0xD6;
  static const int ZYZX = 0x26;
  static const int ZYZY = 0x66;
  static const int ZYZZ = 0xA6;
  static const int ZYZW = 0xE6;
  static const int ZYWX = 0x36;
  static const int ZYWY = 0x76;
  static const int ZYWZ = 0xB6;
  static const int ZYWW = 0xF6;
  static const int ZZXX = 0xA;
  static const int ZZXY = 0x4A;
  static const int ZZXZ = 0x8A;
  static const int ZZXW = 0xCA;
  static const int ZZYX = 0x1A;
  static const int ZZYY = 0x5A;
  static const int ZZYZ = 0x9A;
  static const int ZZYW = 0xDA;
  static const int ZZZX = 0x2A;
  static const int ZZZY = 0x6A;
  static const int ZZZZ = 0xAA;
  static const int ZZZW = 0xEA;
  static const int ZZWX = 0x3A;
  static const int ZZWY = 0x7A;
  static const int ZZWZ = 0xBA;
  static const int ZZWW = 0xFA;
  static const int ZWXX = 0xE;
  static const int ZWXY = 0x4E;
  static const int ZWXZ = 0x8E;
  static const int ZWXW = 0xCE;
  static const int ZWYX = 0x1E;
  static const int ZWYY = 0x5E;
  static const int ZWYZ = 0x9E;
  static const int ZWYW = 0xDE;
  static const int ZWZX = 0x2E;
  static const int ZWZY = 0x6E;
  static const int ZWZZ = 0xAE;
  static const int ZWZW = 0xEE;
  static const int ZWWX = 0x3E;
  static const int ZWWY = 0x7E;
  static const int ZWWZ = 0xBE;
  static const int ZWWW = 0xFE;
  static const int WXXX = 0x3;
  static const int WXXY = 0x43;
  static const int WXXZ = 0x83;
  static const int WXXW = 0xC3;
  static const int WXYX = 0x13;
  static const int WXYY = 0x53;
  static const int WXYZ = 0x93;
  static const int WXYW = 0xD3;
  static const int WXZX = 0x23;
  static const int WXZY = 0x63;
  static const int WXZZ = 0xA3;
  static const int WXZW = 0xE3;
  static const int WXWX = 0x33;
  static const int WXWY = 0x73;
  static const int WXWZ = 0xB3;
  static const int WXWW = 0xF3;
  static const int WYXX = 0x7;
  static const int WYXY = 0x47;
  static const int WYXZ = 0x87;
  static const int WYXW = 0xC7;
  static const int WYYX = 0x17;
  static const int WYYY = 0x57;
  static const int WYYZ = 0x97;
  static const int WYYW = 0xD7;
  static const int WYZX = 0x27;
  static const int WYZY = 0x67;
  static const int WYZZ = 0xA7;
  static const int WYZW = 0xE7;
  static const int WYWX = 0x37;
  static const int WYWY = 0x77;
  static const int WYWZ = 0xB7;
  static const int WYWW = 0xF7;
  static const int WZXX = 0xB;
  static const int WZXY = 0x4B;
  static const int WZXZ = 0x8B;
  static const int WZXW = 0xCB;
  static const int WZYX = 0x1B;
  static const int WZYY = 0x5B;
  static const int WZYZ = 0x9B;
  static const int WZYW = 0xDB;
  static const int WZZX = 0x2B;
  static const int WZZY = 0x6B;
  static const int WZZZ = 0xAB;
  static const int WZZW = 0xEB;
  static const int WZWX = 0x3B;
  static const int WZWY = 0x7B;
  static const int WZWZ = 0xBB;
  static const int WZWW = 0xFB;
  static const int WWXX = 0xF;
  static const int WWXY = 0x4F;
  static const int WWXZ = 0x8F;
  static const int WWXW = 0xCF;
  static const int WWYX = 0x1F;
  static const int WWYY = 0x5F;
  static const int WWYZ = 0x9F;
  static const int WWYW = 0xDF;
  static const int WWZX = 0x2F;
  static const int WWZY = 0x6F;
  static const int WWZZ = 0xAF;
  static const int WWZW = 0xEF;
  static const int WWWX = 0x3F;
  static const int WWWY = 0x7F;
  static const int WWWZ = 0xBF;
  static const int WWWW = 0xFF;

}


class Float64x2 {
  factory Float64x2(double x, double y) native "Float64x2_fromDoubles";
  factory Float64x2.splat(double v) native "Float64x2_splat";
  factory Float64x2.zero() native "Float64x2_zero";
  factory Float64x2.fromFloat32x4(Float32x4 v) native "Float64x2_fromFloat32x4";

  Float64x2 operator +(Float64x2 other) {
    return _add(other);
  }
  Float64x2 _add(Float64x2 other) native "Float64x2_add";
  Float64x2 operator -() {
    return _negate();
  }
  Float64x2 _negate() native "Float64x2_negate";
  Float64x2 operator -(Float64x2 other) {
    return _sub(other);
  }
  Float64x2 _sub(Float64x2 other) native "Float64x2_sub";
  Float64x2 operator *(Float64x2 other) {
    return _mul(other);
  }
  Float64x2 _mul(Float64x2 other) native "Float64x2_mul";
  Float64x2 operator /(Float64x2 other) {
    return _div(other);
  }
  Float64x2 _div(Float64x2 other) native "Float64x2_div";


  /// Returns a copy of [this] each lane being scaled by [s].
  Float64x2 scale(double s) native "Float64x2_scale";
  /// Returns the absolute value of this [Float64x2].
  Float64x2 abs() native "Float64x2_abs";

  /// Clamps [this] to be in the range [lowerLimit]-[upperLimit].
  Float64x2 clamp(Float64x2 lowerLimit,
                  Float64x2 upperLimit) native "Float64x2_clamp";

  /// Extracted x value.
  double get x native "Float64x2_getX";
  /// Extracted y value.
  double get y native "Float64x2_getY";

  /// Extract the sign bits from each lane return them in the first 2 bits.
  int get signMask native "Float64x2_getSignMask";

  /// Returns a new [Float64x2] copied from [this] with a new x value.
  Float64x2 withX(double x) native "Float64x2_setX";
  /// Returns a new [Float64x2] copied from [this] with a new y value.
  Float64x2 withY(double y) native "Float64x2_setY";

  /// Returns the lane-wise minimum value in [this] or [other].
  Float64x2 min(Float64x2 other) native "Float64x2_min";

  /// Returns the lane-wise maximum value in [this] or [other].
  Float64x2 max(Float64x2 other) native "Float64x2_max";

  /// Returns the lane-wise square root of [this].
  Float64x2 sqrt() native "Float64x2_sqrt";
}



class _TypedListIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E _current;

  _TypedListIterator(List array)
      : _array = array, _length = array.length, _position = -1 {
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
  _TypedListView(ByteBuffer _buffer, int _offset, int _length)
    : _typedData = _buffer._data,
      offsetInBytes = _offset,
      length = _length {
  }

  // Method(s) implementing the TypedData interface.

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer {
    return _typedData.buffer;
  }

  final _TypedList _typedData;
  final int offsetInBytes;
  final int length;
}


class _Int8ArrayView extends _TypedListView with _IntListMixin implements Int8List {
  // Constructor.
  _Int8ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                _offsetInBytes,
                length * Int8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getInt8(offsetInBytes +
                               (index * Int8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt8(offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT),
                        _toInt8(value));
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


class _Uint8ArrayView extends _TypedListView with _IntListMixin implements Uint8List {
  // Constructor.
  _Uint8ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                _offsetInBytes,
                length * Uint8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                         _toUint8(value));
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


class _Uint8ClampedArrayView extends _TypedListView with _IntListMixin implements Uint8ClampedList {
  // Constructor.
  _Uint8ClampedArrayView(ByteBuffer buffer,
                         [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
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


class _Int16ArrayView extends _TypedListView with _IntListMixin implements Int16List {
  // Constructor.
  _Int16ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int16List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int16List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getInt16(offsetInBytes +
                                (index * Int16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt16(offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT),
                         _toInt16(value));
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


class _Uint16ArrayView extends _TypedListView with _IntListMixin implements Uint16List {
  // Constructor.
  _Uint16ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint16List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint16List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getUint16(offsetInBytes +
                                 (index * Uint16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint16(offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT),
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


class _Int32ArrayView extends _TypedListView with _IntListMixin implements Int32List {
  // Constructor.
  _Int32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getInt32(offsetInBytes +
                                (index * Int32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt32(offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT),
                         _toInt32(value));
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


class _Uint32ArrayView extends _TypedListView with _IntListMixin implements Uint32List {
  // Constructor.
  _Uint32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getUint32(offsetInBytes +
                                 (index * Uint32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint32(offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT),
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


class _Int64ArrayView extends _TypedListView with _IntListMixin implements Int64List {
  // Constructor.
  _Int64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getInt64(offsetInBytes +
                                (index * Int64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt64(offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT),
                         _toInt64(value));
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


class _Uint64ArrayView extends _TypedListView with _IntListMixin implements Uint64List {
  // Constructor.
  _Uint64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Uint64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getUint64(offsetInBytes +
                                 (index * Uint64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setUint64(offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT),
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


class _Float32ArrayView extends _TypedListView with _DoubleListMixin implements Float32List {
  // Constructor.
  _Float32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float32List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat32(offsetInBytes +
                                  (index * Float32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat32(offsetInBytes +
                           (index * Float32List.BYTES_PER_ELEMENT), value);
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


class _Float64ArrayView extends _TypedListView with _DoubleListMixin implements Float64List {
  // Constructor.
  _Float64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float64List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat64(offsetInBytes +
                                  (index * Float64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat64(offsetInBytes +
                          (index * Float64List.BYTES_PER_ELEMENT), value);
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


class _Float32x4ArrayView extends _TypedListView with _Float32x4ListMixin implements Float32x4List {
  // Constructor.
  _Float32x4ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float32x4List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float32x4List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float32x4List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat32x4(offsetInBytes +
                                  (index * Float32x4List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat32x4(offsetInBytes +
                             (index * Float32x4List.BYTES_PER_ELEMENT), value);
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


class _Int32x4ArrayView extends _TypedListView with _Int32x4ListMixin implements Int32x4List {
  // Constructor.
  _Int32x4ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int32x4List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int32x4List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Int32x4List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  Int32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getInt32x4(offsetInBytes +
                                   (index * Int32x4List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setInt32x4(offsetInBytes +
                            (index * Int32x4List.BYTES_PER_ELEMENT), value);
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


class _Float64x2ArrayView extends _TypedListView with _Float64x2ListMixin implements Float64x2List {
  // Constructor.
  _Float64x2ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float64x2List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float64x2List.BYTES_PER_ELEMENT);
    _offsetAlignmentCheck(_offsetInBytes, Float64x2List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  Float64x2 operator[](int index) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    return _typedData._getFloat64x2(offsetInBytes +
                                    (index * Float64x2List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      throw new RangeError.index(index, this, "index");
    }
    _typedData._setFloat64x2(offsetInBytes +
                             (index * Float64x2List.BYTES_PER_ELEMENT), value);
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
  _ByteDataView(TypedData typedData, int _offsetInBytes, int _lengthInBytes)
    : _typedData = typedData,
      _offset = _offsetInBytes,
      length = _lengthInBytes {
    _rangeCheck(_typedData.lengthInBytes, _offset, length);
  }


  // Method(s) implementing TypedData interface.

  ByteBuffer get buffer {
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
  void setInt16(int byteOffset,
                int value,
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
  void setUint16(int byteOffset,
                 int value,
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
  void setInt32(int byteOffset,
                int value,
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
  void setUint32(int byteOffset,
                 int value,
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
  void setInt64(int byteOffset,
                int value,
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
  void setUint64(int byteOffset,
                 int value,
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
  void setFloat32(int byteOffset,
                  double value,
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
  void setFloat64(int byteOffset,
                  double value,
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
  void setFloat32x4(int byteOffset,
                    Float32x4 value,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      throw new RangeError.range(byteOffset, 0, length - 4, "byteOffset");
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat32x4(_offset + byteOffset, value);

  }

  final TypedData _typedData;
  final int _offset;
  final int length;
}

int _byteSwap16(int value) {
  return ((value & 0xFF00) >> 8) |
         ((value & 0x00FF) << 8);
}

int _byteSwap32(int value) {
  value = ((value & 0xFF00FF00) >> 8)  | ((value & 0x00FF00FF) << 8);
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


int _toInt64(int value) {
  // Avoid bigint mask when possible.
  return (ClassID.getID(value) == ClassID.cidBigint) ?
      _toInt(value, 0xFFFFFFFFFFFFFFFF) : value;
}


int _toUint64(int value) {
  // Avoid bigint mask when possible.
  return (ClassID.getID(value) == ClassID.cidBigint) ?
      _toInt(value, 0xFFFFFFFFFFFFFFFF) : value;
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
