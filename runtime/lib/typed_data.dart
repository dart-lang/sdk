// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// patch classes for Int8List ..... Float64List and ByteData implementations.

import "dart:_internal";
import 'dart:math' show Random;

patch class Int8List {
  /* patch */ factory Int8List(int length) {
    return new _Int8Array(length);
  }

  /* patch */ factory Int8List.fromList(List<int> elements) {
    return new _Int8Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Int8List.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint8List {
  /* patch */ factory Uint8List(int length) {
    return new _Uint8Array(length);
  }

  /* patch */ factory Uint8List.fromList(List<int> elements) {
    return new _Uint8Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Uint8List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint8ClampedList {
  /* patch */ factory Uint8ClampedList(int length) {
    return new _Uint8ClampedArray(length);
  }

  /* patch */ factory Uint8ClampedList.fromList(List<int> elements) {
    return new _Uint8ClampedArray(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Uint8ClampedList.view(ByteBuffer buffer,
                                            [int offsetInBytes = 0,
                                             int length]) {
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int16List {
  /* patch */ factory Int16List(int length) {
    return new _Int16Array(length);
  }

  /* patch */ factory Int16List.fromList(List<int> elements) {
    return new _Int16Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Int16List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int16ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint16List {
  /* patch */ factory Uint16List(int length) {
    return new _Uint16Array(length);
  }

  /* patch */ factory Uint16List.fromList(List<int> elements) {
    return new _Uint16Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Uint16List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint16ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int32List {
  /* patch */ factory Int32List(int length) {
    return new _Int32Array(length);
  }

  /* patch */ factory Int32List.fromList(List<int> elements) {
    return new _Int32Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Int32List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint32List {
  /* patch */ factory Uint32List(int length) {
    return new _Uint32Array(length);
  }

  /* patch */ factory Uint32List.fromList(List<int> elements) {
    return new _Uint32Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Uint32List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int64List {
  /* patch */ factory Int64List(int length) {
    return new _Int64Array(length);
  }

  /* patch */ factory Int64List.fromList(List<int> elements) {
    return new _Int64Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Int64List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int64ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint64List {
  /* patch */ factory Uint64List(int length) {
    return new _Uint64Array(length);
  }

  /* patch */ factory Uint64List.fromList(List<int> elements) {
    return new _Uint64Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Uint64List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint64ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float32List {
  /* patch */ factory Float32List(int length) {
    return new _Float32Array(length);
  }

  /* patch */ factory Float32List.fromList(List<double> elements) {
    return new _Float32Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Float32List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float64List {
  /* patch */ factory Float64List(int length) {
    return new _Float64Array(length);
  }

  /* patch */ factory Float64List.fromList(List<double> elements) {
    return new _Float64Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Float64List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float64ArrayView(buffer, offsetInBytes, length);
  }
}

patch class Float32x4List {
  /* patch */ factory Float32x4List(int length) {
    return new _Float32x4Array(length);
  }

  /* patch */ factory Float32x4List.fromList(List<Float32x4> elements) {
    return new _Float32x4Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Float32x4List.view(ByteBuffer buffer,
                                         [int offsetInBytes = 0, int length]) {
    return new _Float32x4ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int32x4List {
  /* patch */ factory Int32x4List(int length) {
    return new _Int32x4Array(length);
  }

  /* patch */ factory Int32x4List.fromList(List<Int32x4> elements) {
    return new _Int32x4Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Int32x4List.view(ByteBuffer buffer,
                                        [int offsetInBytes = 0, int length]) {
    return new _Int32x4ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float64x2List {
  /* patch */ factory Float64x2List(int length) {
    return new _Float64x2Array(length);
  }

  /* patch */ factory Float64x2List.fromList(List<Float64x2> elements) {
    return new _Float64x2Array(elements.length)
        ..setRange(0, elements.length, elements);
  }

  /* patch */ factory Float64x2List.view(ByteBuffer buffer,
                                         [int offsetInBytes = 0, int length]) {
    return new _Float64x2ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float32x4 {
  /* patch */ factory Float32x4(double x, double y, double z, double w) {
    return new _Float32x4(x, y, z, w);
  }
  /* patch */ factory Float32x4.splat(double v) {
    return new _Float32x4.splat(v);
  }
  /* patch */ factory Float32x4.zero() {
    return new _Float32x4.zero();
  }
  /* patch */ factory Float32x4.fromInt32x4Bits(Int32x4 x) {
    return new _Float32x4.fromInt32x4Bits(x);
  }
  /* patch */ factory Float32x4.fromFloat64x2(Float64x2 v) {
    return new _Float32x4.fromFloat64x2(v);
  }
}


patch class Int32x4 {
  /* patch */ factory Int32x4(int x, int y, int z, int w) {
    return new _Int32x4(x, y, z, w);
  }
  /* patch */ factory Int32x4.bool(bool x, bool y, bool z, bool w) {
    return new _Int32x4.bool(x, y, z, w);
  }
  /* patch */ factory Int32x4.fromFloat32x4Bits(Float32x4 x) {
    return new _Int32x4.fromFloat32x4Bits(x);
  }
}


patch class Float64x2 {
  /* patch */ factory Float64x2(double x, double y) {
    return new _Float64x2(x, y);
  }

  /* patch */ factory Float64x2.splat(double v) {
    return new _Float64x2.splat(v);
  }

  /* patch */ factory Float64x2.zero() {
    return new _Float64x2.zero();
  }

  /* patch */ factory Float64x2.fromFloat32x4(Float32x4 v) {
    return new _Float64x2.fromFloat32x4(v);
  }
}


patch class ByteData {
  /* patch */ factory ByteData(int length) {
    var list = new _Uint8Array(length);
    return new _ByteDataView(list, 0, length);
  }

  /* patch */ factory ByteData.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _ByteDataView(buffer._data, offsetInBytes, length);
  }

  // Called directly from C code.
  factory ByteData._view(TypedData typedData, int offsetInBytes, int length) {
    return new _ByteDataView(typedData, offsetInBytes, length);
  }
}


// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.

abstract class _TypedListBase {

  // Method(s) implementing the Collection interface.
  bool contains(element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Iterable map(f(element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator = ""]) {
    return IterableMixinWorkaround.join(this, separator);
  }

  dynamic reduce(dynamic combine(value, element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic initialValue, element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  Iterable where(bool f(element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable takeWhile(bool test(element)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable skipWhile(bool test(element)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  dynamic firstWhere(bool test(element), {orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  dynamic lastWhere(bool test(element), {orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  dynamic singleWhere(bool test(element)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Iterable<dynamic> get reversed {
    return IterableMixinWorkaround.reversedList(this);
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
    IterableMixinWorkaround.sortList(this, compare);
  }

  void shuffle([Random random]) {
    IterableMixinWorkaround.shuffleList(this, random);
  }

  int indexOf(element, [int start = 0]) {
    return IterableMixinWorkaround.indexOfList(this, element, start);
  }

  int lastIndexOf(element, [int start = null]) {
    return IterableMixinWorkaround.lastIndexOfList(this, element, start);
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
    throw new StateError("No elements");
  }

  dynamic get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  dynamic get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
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

  Map<int, dynamic> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }

  List sublist(int start, [int end]) {
    if (end == null) end = this.length;
    int length = end - start;
    _rangeCheck(this.length, start, length);
    List result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  Iterable getRange(int start, [int end]) {
    return IterableMixinWorkaround.getRangeList(this, start, end);
  }

  void setRange(int start, int end, Iterable from, [int skipCount = 0]) {
    // Check ranges.
    if ((start < 0) || (start > length)) {
      _throwRangeError(start, length + 1);
    }
    if ((end < 0) || (end > length)) {
      _throwRangeError(end, length + 1);
    }
    if (start > end) {
      _throwRangeError(start, end + 1);
    }
    if (skipCount < 0) {
      throw new ArgumentError(skipCount);
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw new StateError("Not enough elements");
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
        for (int i = 0; i < count; i++) {
          temp_buffer[i] = from[skipCount + i];
        }
        for (int i = start; i < end; i++) {
          this[i] = temp_buffer[i - start];
        }
        return;
      }
    }
    IterableMixinWorkaround.setRangeList(this, start,
                                         end, from, skipCount);
  }

  void setAll(int index, Iterable iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [fillValue]) {
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
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


class _ByteBuffer implements ByteBuffer {
  final _TypedList _data;

  _ByteBuffer(this._data);

  // Forward calls to _data.
  int get lengthInBytes => _data.lengthInBytes;
  int get hashCode => _data.hashCode;
  bool operator==(Object other) =>
      (other is _ByteBuffer) && identical(_data, other._data);
}


abstract class _TypedList extends _TypedListBase {
  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer => new _ByteBuffer(this);

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
}


class _Int8Array extends _TypedList implements Int8List {
  // Factory constructors.

  factory _Int8Array(int length) {
    return _new(length);
  }

  factory _Int8Array.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setInt8(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int8Array _createList(int length) {
    return _new(length);
  }

  static _Int8Array _new(int length) native "TypedData_Int8Array_new";
}


class _Uint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  factory _Uint8Array(int length) {
    return _new(length);
  }

  factory _Uint8Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }


  // Methods implementing List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint8Array _createList(int length) {
    return _new(length);
  }

  static _Uint8Array _new(int length) native "TypedData_Uint8Array_new";
}


class _Uint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  factory _Uint8ClampedArray(int length) {
    return _new(length);
  }

  factory _Uint8ClampedArray.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }

  // Methods implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint8ClampedArray _createList(int length) {
    return _new(length);
  }

  static _Uint8ClampedArray _new(int length)
      native "TypedData_Uint8ClampedArray_new";
}


class _Int16Array extends _TypedList implements Int16List {
  // Factory constructors.

  factory _Int16Array(int length) {
    return _new(length);
  }

  factory _Int16Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Int16List.BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int16Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt16(int index) {
    return _getInt16(index * Int16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt16(int index, int value) {
    _setInt16(index * Int16List.BYTES_PER_ELEMENT, value);
  }

  static _Int16Array _new(int length) native "TypedData_Int16Array_new";
}


class _Uint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  factory _Uint16Array(int length) {
    return _new(length);
  }

  factory _Uint16Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Uint16List.BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint16Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint16(int index) {
    return _getUint16(index * Uint16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint16(int index, int value) {
    _setUint16(index * Uint16List.BYTES_PER_ELEMENT, value);
  }

  static _Uint16Array _new(int length) native "TypedData_Uint16Array_new";
}


class _Int32Array extends _TypedList implements Int32List {
  // Factory constructors.

  factory _Int32Array(int length) {
    return _new(length);
  }

  factory _Int32Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int32Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt32(int index) {
    return _getInt32(index * Int32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32(int index, int value) {
    _setInt32(index * Int32List.BYTES_PER_ELEMENT, value);
  }

  static _Int32Array _new(int length) native "TypedData_Int32Array_new";
}


class _Uint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  factory _Uint32Array(int length) {
    return _new(length);
  }

  factory _Uint32Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Uint32List.BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint32Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint32(int index) {
    return _getUint32(index * Uint32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint32(int index, int value) {
    _setInt32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }

  static _Uint32Array _new(int length) native "TypedData_Uint32Array_new";
}


class _Int64Array extends _TypedList implements Int64List {
  // Factory constructors.

  factory _Int64Array(int length) {
    return _new(length);
  }

  factory _Int64Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int64Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt64(int index) {
    return _getInt64(index * Int64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt64(int index, int value) {
    _setInt64(index * Int64List.BYTES_PER_ELEMENT, value);
  }

  static _Int64Array _new(int length) native "TypedData_Int64Array_new";
}


class _Uint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  factory _Uint64Array(int length) {
    return _new(length);
  }

  factory _Uint64Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Uint64List.BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint64Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint64(int index) {
    return _getUint64(index * Uint64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint64(int index, int value) {
    _setUint64(index * Uint64List.BYTES_PER_ELEMENT, value);
  }

  static _Uint64Array _new(int length) native "TypedData_Uint64Array_new";
}


class _Float32Array extends _TypedList implements Float32List {
  // Factory constructors.

  factory _Float32Array(int length) {
    return _new(length);
  }

  factory _Float32Array.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float32List.BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float32Array _createList(int length) {
    return _new(length);
  }

  double _getIndexedFloat32(int index) {
    return _getFloat32(index * Float32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32(int index, double value) {
    _setFloat32(index * Float32List.BYTES_PER_ELEMENT, value);
  }

  static _Float32Array _new(int length) native "TypedData_Float32Array_new";
}


class _Float64Array extends _TypedList implements Float64List {
  // Factory constructors.

  factory _Float64Array(int length) {
    return _new(length);
  }

  factory _Float64Array.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float64List.BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float64Array _createList(int length) {
    return _new(length);
  }

  double _getIndexedFloat64(int index) {
    return _getFloat64(index * Float64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64(int index, double value) {
    _setFloat64(index * Float64List.BYTES_PER_ELEMENT, value);
  }

  static _Float64Array _new(int length) native "TypedData_Float64Array_new";
}


class _Float32x4Array extends _TypedList implements Float32x4List {
  // Factory constructors.

  factory _Float32x4Array(int length) {
    return _new(length);
  }

  factory _Float32x4Array.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float32x4List.BYTES_PER_ELEMENT;
    }
    return new _Float32x4ArrayView(buffer, offsetInBytes, length);
  }


  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32x4(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float32x4Array _createList(int length) {
    return _new(length);
  }

  Float32x4 _getIndexedFloat32x4(int index) {
    return _getFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32x4(int index, Float32x4 value) {
    _setFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT, value);
  }

  static _Float32x4Array _new(int length) native "TypedData_Float32x4Array_new";
}


class _Int32x4Array extends _TypedList implements Int32x4List {
  // Factory constructors.

  factory _Int32x4Array(int length) {
    return _new(length);
  }

  factory _Int32x4Array.view(ByteBuffer buffer,
                              [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Int32x4List.BYTES_PER_ELEMENT;
    }
    return new _Int32x4ArrayView(buffer, offsetInBytes, length);
  }


  Int32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32x4(index);
  }

  void operator[]=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32x4(index, value);
  }

  Iterator<Int32x4> get iterator {
    return new _TypedListIterator<Int32x4>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int32x4List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int32x4Array _createList(int length) {
    return _new(length);
  }

  Int32x4 _getIndexedInt32x4(int index) {
    return _getInt32x4(index * Int32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32x4(int index, Int32x4 value) {
    _setInt32x4(index * Int32x4List.BYTES_PER_ELEMENT, value);
  }

  static _Int32x4Array _new(int length) native "TypedData_Int32x4Array_new";
}


class _Float64x2Array extends _TypedList implements Float64x2List {
  // Factory constructors.

  factory _Float64x2Array(int length) {
    return _new(length);
  }

  factory _Float64x2Array.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float64x2List.BYTES_PER_ELEMENT;
    }
    return new _Float64x2ArrayView(buffer, offsetInBytes, length);
  }


  Float64x2 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64x2(index);
  }

  void operator[]=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64x2(index, value);
  }

  Iterator<Float64x2> get iterator {
    return new _TypedListIterator<Float64x2>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64x2List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float64x2Array _createList(int length) {
    return _new(length);
  }

  Float64x2 _getIndexedFloat64x2(int index) {
    return _getFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64x2(int index, Float64x2 value) {
    _setFloat64x2(index * Float64x2List.BYTES_PER_ELEMENT, value);
  }

  static _Float64x2Array _new(int length) native "TypedData_Float64x2Array_new";
}


class _ExternalInt8Array extends _TypedList implements Int8List {
  // Factory constructors.

  factory _ExternalInt8Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setInt8(index, value);
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int8List _createList(int length) {
    return new Int8List(length);
  }

  static _ExternalInt8Array _new(int length) native
      "ExternalTypedData_Int8Array_new";
}


class _ExternalUint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  factory _ExternalUint8Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8List _createList(int length) {
    return new Uint8List(length);
  }

  static _ExternalUint8Array _new(int length) native
      "ExternalTypedData_Uint8Array_new";
}


class _ExternalUint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  factory _ExternalUint8ClampedArray(int length) {
    return _new(length);
  }

  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }

  static _ExternalUint8ClampedArray _new(int length) native
      "ExternalTypedData_Uint8ClampedArray_new";
}


class _ExternalInt16Array extends _TypedList implements Int16List {
  // Factory constructors.

  factory _ExternalInt16Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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

  static _ExternalInt16Array _new(int length) native
      "ExternalTypedData_Int16Array_new";
}


class _ExternalUint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  factory _ExternalUint16Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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

  static _ExternalUint16Array _new(int length) native
      "ExternalTypedData_Uint16Array_new";
}


class _ExternalInt32Array extends _TypedList implements Int32List {
  // Factory constructors.

  factory _ExternalInt32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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

  static _ExternalInt32Array _new(int length) native
      "ExternalTypedData_Int32Array_new";
}


class _ExternalUint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  factory _ExternalUint32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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
    _setInt32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalUint32Array _new(int length) native
      "ExternalTypedData_Uint32Array_new";
}


class _ExternalInt64Array extends _TypedList implements Int64List {
  // Factory constructors.

  factory _ExternalInt64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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

  static _ExternalInt64Array _new(int length) native
      "ExternalTypedData_Int64Array_new";
}


class _ExternalUint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  factory _ExternalUint64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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

  static _ExternalUint64Array _new(int length) native
      "ExternalTypedData_Uint64Array_new";
}


class _ExternalFloat32Array extends _TypedList implements Float32List {
  // Factory constructors.

  factory _ExternalFloat32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
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

  static _ExternalFloat32Array _new(int length) native
      "ExternalTypedData_Float32Array_new";
}


class _ExternalFloat64Array extends _TypedList implements Float64List {
  // Factory constructors.

  factory _ExternalFloat64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
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

  static _ExternalFloat64Array _new(int length) native
      "ExternalTypedData_Float64Array_new";
}


class _ExternalFloat32x4Array extends _TypedList implements Float32x4List {
  // Factory constructors.

  factory _ExternalFloat32x4Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32x4(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
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

  static _ExternalFloat32x4Array _new(int length) native
      "ExternalTypedData_Float32x4Array_new";
}


class _ExternalInt32x4Array extends _TypedList implements Int32x4List {
  // Factory constructors.

  factory _ExternalInt32x4Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  Int32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32x4(index);
  }

  void operator[]=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32x4(index, value);
  }

  Iterator<Int32x4> get iterator {
    return new _TypedListIterator<Int32x4>(this);
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

  static _ExternalInt32x4Array _new(int length) native
      "ExternalTypedData_Int32x4Array_new";
}


class _ExternalFloat64x2Array extends _TypedList implements Float64x2List {
  // Factory constructors.

  factory _ExternalFloat64x2Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  Float64x2 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64x2(index);
  }

  void operator[]=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64x2(index, value);
  }

  Iterator<Float64x2> get iterator {
    return new _TypedListIterator<Float64x2>(this);
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

  static _ExternalFloat64x2Array _new(int length) native
      "ExternalTypedData_Float64x2Array_new";
}


class _Float32x4 implements Float32x4 {
  factory _Float32x4(double x, double y, double z, double w)
      native "Float32x4_fromDoubles";
  factory _Float32x4.splat(double v) native "Float32x4_splat";
  factory _Float32x4.zero() native "Float32x4_zero";
  factory _Float32x4.fromInt32x4Bits(Int32x4 x)
      native "Float32x4_fromInt32x4Bits";
  factory _Float32x4.fromFloat64x2(Float64x2 v)
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
}


class _Int32x4 implements Int32x4 {
  factory _Int32x4(int x, int y, int z, int w)
      native "Int32x4_fromInts";
  factory _Int32x4.bool(bool x, bool y, bool z, bool w)
      native "Int32x4_fromBools";
  factory _Int32x4.fromFloat32x4Bits(Float32x4 x)
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
  Float32x4 select(Float32x4 trueValue,
                          Float32x4 falseValue) {
    return _select(trueValue, falseValue);
  }
  Float32x4 _select(Float32x4 trueValue,
                           Float32x4 falseValue)
      native "Int32x4_select";
}


class _Float64x2 implements Float64x2 {
  factory _Float64x2(double x, double y) native "Float64x2_fromDoubles";
  factory _Float64x2.splat(double v) native "Float64x2_splat";
  factory _Float64x2.zero() native "Float64x2_zero";
  factory _Float64x2.fromFloat32x4(Float32x4 v) native "Float64x2_fromFloat32x4";

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
  _TypedListView(_ByteBuffer _buffer, int _offset, int _length)
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

  final TypedData _typedData;
  final int offsetInBytes;
  final int length;
}


class _Int8ArrayView extends _TypedListView implements Int8List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt8(offsetInBytes +
                               (index * Int8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt8(offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT),
                        _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Uint8ArrayView extends _TypedListView implements Uint8List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                         _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Uint8ClampedArrayView extends _TypedListView implements Uint8ClampedList {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                         _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Int16ArrayView extends _TypedListView implements Int16List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt16(offsetInBytes +
                                (index * Int16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt16(offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT),
                         _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Uint16ArrayView extends _TypedListView implements Uint16List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint16(offsetInBytes +
                                 (index * Uint16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint16(offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT),
                          _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Int32ArrayView extends _TypedListView implements Int32List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt32(offsetInBytes +
                                (index * Int32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt32(offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT),
                         _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Uint32ArrayView extends _TypedListView implements Uint32List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint32(offsetInBytes +
                                 (index * Uint32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint32(offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT),
                          _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Int64ArrayView extends _TypedListView implements Int64List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt64(offsetInBytes +
                                (index * Int64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt64(offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT),
                         _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Uint64ArrayView extends _TypedListView implements Uint64List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint64(offsetInBytes +
                                 (index * Uint64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint64(offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT),
                          _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
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


class _Float32ArrayView extends _TypedListView implements Float32List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat32(offsetInBytes +
                                  (index * Float32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat32(offsetInBytes +
                           (index * Float32List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
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


class _Float64ArrayView extends _TypedListView implements Float64List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat64(offsetInBytes +
                                  (index * Float64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat64(offsetInBytes +
                          (index * Float64List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
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


class _Float32x4ArrayView extends _TypedListView implements Float32x4List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat32x4(offsetInBytes +
                                  (index * Float32x4List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat32x4(offsetInBytes +
                             (index * Float32x4List.BYTES_PER_ELEMENT), value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
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


class _Int32x4ArrayView extends _TypedListView implements Int32x4List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt32x4(offsetInBytes +
                                   (index * Int32x4List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Int32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt32x4(offsetInBytes +
                            (index * Int32x4List.BYTES_PER_ELEMENT), value);
  }

  Iterator<Int32x4> get iterator {
    return new _TypedListIterator<Int32x4>(this);
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


class _Float64x2ArrayView extends _TypedListView implements Float64x2List {
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat64x2(offsetInBytes +
                                    (index * Float64x2List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Float64x2 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat64x2(offsetInBytes +
                             (index * Float64x2List.BYTES_PER_ELEMENT), value);
  }

  Iterator<Float64x2> get iterator {
    return new _TypedListIterator<Float64x2>(this);
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
      _throwRangeError(byteOffset, length);
    }
    return _typedData._getInt8(_offset + byteOffset);
  }
  void setInt8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    _typedData._setInt8(_offset + byteOffset, _toInt8(value));
  }

  int getUint8(int byteOffset) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    return _typedData._getUint8(_offset + byteOffset);
  }
  void setUint8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    _typedData._setUint8(_offset + byteOffset, _toUint8(value));
  }

  int getInt16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      _throwRangeError(byteOffset + 1, length);
    }
    var result = _typedData._getInt16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt16(result, endian._littleEndian);
  }
  void setInt16(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      _throwRangeError(byteOffset + 1, length);
    }
    var set_value = _toInt16(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt16(set_value, endian._littleEndian);
    }
    _typedData._setInt16(_offset + byteOffset, set_value);
  }

  int getUint16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      _throwRangeError(byteOffset + 1, length);
    }
    var result = _typedData._getUint16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint16(result, endian._littleEndian);
  }
  void setUint16(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 1 >= length) {
      _throwRangeError(byteOffset + 1, length);
    }
    var set_value = _toUint16(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint16(set_value, endian._littleEndian);
    }
    _typedData._setUint16(_offset + byteOffset, set_value);
  }

  int getInt32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var result = _typedData._getInt32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt32(result, endian._littleEndian);
  }
  void setInt32(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var set_value = _toInt32(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt32(set_value, endian._littleEndian);
    }
    _typedData._setInt32(_offset + byteOffset, set_value);
  }

  int getUint32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var result = _typedData._getUint32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint32(result, endian._littleEndian);
  }
  void setUint32(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var set_value = _toUint32(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint32(set_value, endian._littleEndian);
    }
    _typedData._setUint32(_offset + byteOffset, set_value);
  }

  int getInt64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var result = _typedData._getInt64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt64(result, endian._littleEndian);
  }
  void setInt64(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var set_value = _toInt64(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt64(set_value, endian._littleEndian);
    }
    _typedData._setInt64(_offset + byteOffset, set_value);
  }

  int getUint64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var result = _typedData._getUint64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint64(result, endian._littleEndian);
  }
  void setUint64(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var set_value = _toUint64(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint64(set_value, endian._littleEndian);
    }
    _typedData._setUint64(_offset + byteOffset, set_value);
  }

  double getFloat32(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var result = _typedData._getFloat32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianFloat32(result, endian._littleEndian);
  }
  void setFloat32(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    var set_value = value;
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianFloat32(set_value, endian._littleEndian);
    }
    _typedData._setFloat32(_offset + byteOffset, set_value);
  }

  double getFloat64(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var result = _typedData._getFloat64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianFloat64(result, endian._littleEndian);
  }
  void setFloat64(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 7 >= length) {
      _throwRangeError(byteOffset + 7, length);
    }
    var set_value = value;
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianFloat64(set_value, endian._littleEndian);
    }
    _typedData._setFloat64(_offset + byteOffset, set_value);
  }

  Float32x4 getFloat32x4(int byteOffset,
                         [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    return _typedData._getFloat32x4(_offset + byteOffset);
  }
  void setFloat32x4(int byteOffset,
                    Float32x4 value,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset + 3 >= length) {
      _throwRangeError(byteOffset + 3, length);
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat32x4(_offset + byteOffset, value);

  }


  // Internal utility methods.

  static int _toEndianInt16(int host_value, bool little_endian)
      native "ByteData_ToEndianInt16";
  static int _toEndianUint16(int host_value, bool little_endian)
      native "ByteData_ToEndianUint16";
  static int _toEndianInt32(int host_value, bool little_endian)
      native "ByteData_ToEndianInt32";
  static int _toEndianUint32(int host_value, bool little_endian)
      native "ByteData_ToEndianUint32";
  static int _toEndianInt64(int host_value, bool little_endian)
      native "ByteData_ToEndianInt64";
  static int _toEndianUint64(int host_value, bool little_endian)
      native "ByteData_ToEndianUint64";
  static double _toEndianFloat32(double host_value, bool little_endian)
      native "ByteData_ToEndianFloat32";
  static double _toEndianFloat64(double host_value, bool little_endian)
      native "ByteData_ToEndianFloat64";


  final TypedData _typedData;
  final int _offset;
  final int length;
}


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
  return _toInt(value, 0xFFFFFFFFFFFFFFFF);
}


int _toUint64(int value) {
  return value & 0xFFFFFFFFFFFFFFFF;
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


void _throwRangeError(int index, int length) {
  String message = "$index must be in the range [0..$length)";
  throw new RangeError(message);
}
