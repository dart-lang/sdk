// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ByteArray default _Uint8Array {
  // TODO: remove constructor and default implementation after dart:io
  // is updated to use Uint8Array directly instead of ByteArray
  ByteArray(int length);

  int lengthInBytes();

  ByteArray subByteArray([int start, int length]);

  int getInt8(int byteOffset);

  void setInt8(int byteOffset, int value);

  int getUint8(int byteOffset);

  void setUint8(int byteOffset, int value);

  int getInt16(int byteOffset);

  void setInt16(int byteOffset, int value);

  int getUint16(int byteOffset);

  void setUint16(int byteOffset, int value);

  int getInt32(int byteOffset);

  void setInt32(int byteOffset, int value);

  int getUint32(int byteOffset);

  void setUint32(int byteOffset, int value);

  int getInt64(int byteOffset);

  void setInt64(int byteOffset, int value);

  int getUint64(int byteOffset);

  void setUint64(int byteOffset, int value);

  double getFloat32(int byteOffset);

  void setFloat32(int byteOffset, double value);

  double getFloat64(int byteOffset);

  void setFloat64(int byteOffset, double value);
}


interface ByteArrayViewable {
  int bytesPerElement();

  int lengthInBytes();

  ByteArray asByteArray([int offsetInBytes, int lengthInBytes]);
}


interface Int8Array extends List<int>, ByteArrayViewable
    default _Int8Array {
  Int8Array(int length);
  Int8Array.view(ByteArray array, [int start, int length]);
}


interface Uint8Array extends List<int>, ByteArrayViewable
    default _Uint8Array {
  Uint8Array(int length);
  Uint8Array.view(ByteArray array, [int start, int length]);
}


interface Int16Array extends List<int>, ByteArrayViewable
    default _Int16Array {
  Int16Array(int length);
  Int16Array.view(ByteArray array, [int start, int length]);
}


interface Uint16Array extends List<int>, ByteArrayViewable
    default _Uint16Array {
  Uint16Array(int length);
  Uint16Array.view(ByteArray array, [int start, int length]);
}


interface Int32Array extends List<int>, ByteArrayViewable
    default _Int32Array {
  Int32Array(int length);
  Int32Array.view(ByteArray array, [int start, int length]);
}


interface Uint32Array extends List<int>, ByteArrayViewable
    default _Uint32Array {
  Uint32Array(int length);
  Uint32Array.view(ByteArray array, [int start, int length]);

}


interface Int64Array extends List<int>, ByteArrayViewable
    default _Int64Array {
  Int64Array(int length);
  Int64Array.view(ByteArray array, [int start, int length]);
}


interface Uint64Array extends List<int>, ByteArrayViewable
    default _Uint64Array {
  Uint64Array(int length);
  Uint64Array.view(ByteArray array, [int start, int length]);
}


interface Float32Array extends List<double>, ByteArrayViewable
    default _Float32Array {
  Float32Array(int length);
  Float32Array.view(ByteArray array, [int start, int length]);
}


interface Float64Array extends List<double>, ByteArrayViewable
    default _Float64Array {
  Float64Array(int length);
  Float64Array.view(ByteArray array, [int start, int length]);
}


abstract class _ByteArrayBase {
  void add(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addAll(Collection value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  int get length() {
    return _length();
  }

  set length(newLength) {
    throw const UnsupportedOperationException(
        "Cannot resize a non-extendable array");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  ByteArray asByteArray([int offsetInBytes = 0, int lengthInBytes]) {
    if (lengthInBytes === null) {
      lengthInBytes = this.lengthInBytes();
    }
    return new _ByteArrayView(this, offsetInBytes, lengthInBytes);
  }

  int _length() native "ByteArray_getLength";

  void _setRange(int startInBytes, int lengthInBytes,
                 _ByteArrayBase from, int startFromInBytes)
      native "ByteArray_setRange";

  int _getInt8(int byteOffset) native "ByteArray_getInt8";
  void _setInt8(int byteOffset, int value) native "ByteArray_setInt8";

  int _getUint8(int byteOffset) native "ByteArray_getUint8";
  void _setUint8(int byteOffset, int value) native "ByteArray_setUint8";

  int _getInt16(int byteOffset) native "ByteArray_getInt16";
  void _setInt16(int byteOffset, int value) native "ByteArray_setInt16";

  int _getUint16(int byteOffset) native "ByteArray_getUint16";
  void _setUint16(int byteOffset, int value) native "ByteArray_setUint16";

  int _getInt32(int byteOffset) native "ByteArray_getInt32";
  void _setInt32(int byteOffset, int value) native "ByteArray_setInt32";

  int _getUint32(int byteOffset) native "ByteArray_getUint32";
  void _setUint32(int byteOffset, int value) native "ByteArray_setUint32";

  int _getInt64(int byteOffset) native "ByteArray_getInt64";
  void _setInt64(int byteOffset, int value) native "ByteArray_setInt64";

  int _getUint64(int byteOffset) native "ByteArray_getUint64";
  void _setUint64(int byteOffset, int value) native "ByteArray_setUint64";

  double _getFloat32(int byteOffset) native "ByteArray_getFloat32";
  void _setFloat32(int byteOffset, double value) native "ByteArray_setFloat32";

  double _getFloat64(int byteOffset) native "ByteArray_getFloat64";
  void _setFloat64(int byteOffset, double value) native "ByteArray_setFloat64";
}


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


void _rangeCheck(List a, int start, int length) {
  if (length < 0) {
    throw new IllegalArgumentException("negative length $length");
  }
  if (start < 0) {
    throw new IndexOutOfRangeException("negative start $start");
  }
  if (start + length > a.length) {
    throw new IndexOutOfRangeException(start + length);
  }
}


class _Int8Array extends _ByteArrayBase implements Int8Array {
  factory _Int8Array(int length) {
    return _new(length);
  }

  factory _Int8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = array.lengthInBytes();
    }
    return new _Int8ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int8Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int8Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 1;

  static _Int8Array _new(int length) native "Int8Array_new";

  int _getIndexed(int index) native "Int8Array_getIndexed";

  void _setIndexed(int index, int value) native "Int8Array_setIndexed";
}


class _Uint8Array extends _ByteArrayBase implements Uint8Array {
  factory _Uint8Array(int length) {
    return _new(length);
  }

  factory _Uint8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = array.lengthInBytes();
    }
    return new _Uint8ArrayView(array, start, length);
  }

  factory ByteArray(int length) { return _new(length); }  // TODO

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint8Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint8Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 1;

  static _Uint8Array _new(int length) native "Uint8Array_new";

  int _getIndexed(int index) native "Uint8Array_getIndexed";

  void _setIndexed(int index, int value) native "Uint8Array_setIndexed";
}


class _Int16Array extends _ByteArrayBase implements Int16Array {
  factory _Int16Array(int length) {
    return _new(length);
  }

  factory _Int16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int16Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int16Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 2;

  static _Int16Array _new(int length) native "Int16Array_new";

  int _getIndexed(int index) native "Int16Array_getIndexed";

  void _setIndexed(int index, int value) native "Int16Array_setIndexed";
}


class _Uint16Array extends _ByteArrayBase implements Uint16Array {
  factory _Uint16Array(int length) {
    return _new(length);
  }

  factory _Uint16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint16Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint16Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 2;

  static _Uint16Array _new(int length) native "Uint16Array_new";

  int _getIndexed(int index) native "Uint16Array_getIndexed";

  void _setIndexed(int index, int value) native "Uint16Array_setIndexed";
}


class _Int32Array extends _ByteArrayBase implements Int32Array {
  factory _Int32Array(int length) {
    return _new(length);
  }

  factory _Int32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int32Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  static _Int32Array _new(int length) native "Int32Array_new";

  int _getIndexed(int index) native "Int32Array_getIndexed";

  void _setIndexed(int index, int value) native "Int32Array_setIndexed";
}


class _Uint32Array extends _ByteArrayBase implements Uint32Array {
  factory _Uint32Array(int length) {
    return _new(length);
  }

  factory _Uint32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint32Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  static _Uint32Array _new(int length) native "Uint32Array_new";

  int _getIndexed(int index) native "Uint32Array_getIndexed";

  void _setIndexed(int index, int value) native "Uint32Array_setIndexed";
}


class _Int64Array extends _ByteArrayBase implements Int64Array {
  factory _Int64Array(int length) {
    return _new(length);
  }

  factory _Int64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int64Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  static _Int64Array _new(int length) native "Int64Array_new";

  int _getIndexed(int index) native "Int64Array_getIndexed";

  void _setIndexed(int index, int value) native "Int64Array_setIndexed";
}


class _Uint64Array extends _ByteArrayBase implements Uint64Array {
  factory _Uint64Array(int length) {
    return _new(length);
  }

  factory _Uint64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint64Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  static _Uint64Array _new(int length) native "Uint64Array_new";

  int _getIndexed(int index) native "Uint64Array_getIndexed";

  void _setIndexed(int index, int value) native "Uint64Array_setIndexed";
}


class _Float32Array extends _ByteArrayBase implements Float32Array {
  factory _Float32Array(int length) {
    return _new(length);
  }

  factory _Float32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Float32Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Float32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  static _Float32Array _new(int length) native "Float32Array_new";

  int _getIndexed(int index) native "Float32Array_getIndexed";

  void _setIndexed(int index, double value) native "Float32Array_setIndexed";
}


class _Float64Array extends _ByteArrayBase implements Float64Array {
  factory _Float64Array(int length) {
    return _new(length);
  }

  factory _Float64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Float64Array result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Float64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  static _Float64Array _new(int length) native "Float64Array_new";

  int _getIndexed(int index) native "Float64Array_getIndexed";

  void _setIndexed(int index, double value) native "Float64Array_setIndexed";
}


class _ExternalInt8Array extends _ByteArrayBase implements Int8Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Int8Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int8Array result = new Int8Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt8Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalInt8Array_getIndexed";

  void _setIndexed(int index, int value) native "ExternalInt8Array_setIndexed";
}


class _ExternalUint8Array extends _ByteArrayBase implements Uint8Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Uint8Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint8Array result = new Uint8Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint8Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalUint8Array_getIndexed";

  void _setIndexed(int index, int value) native "ExternalUint8Array_setIndexed";
}


class _ExternalInt16Array extends _ByteArrayBase implements Int16Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Int16Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int16Array result = new Int16Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt16Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index) native "ExternalInt16Array_getIndexed";

  void _setIndexed(int index, int value) native "ExternalInt16Array_setIndexed";
}


class _ExternalUint16Array extends _ByteArrayBase implements Uint16Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Uint16Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint16Array result = new Uint16Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint16Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index) native "ExternalUint16Array_getIndexed";

  void _setIndexed(int index, int value)
      native "ExternalUint16Array_setIndexed";
}


class _ExternalInt32Array extends _ByteArrayBase implements Int32Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Int32Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int32Array result = new Int32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index) native "ExternalInt32Array_getIndexed";

  void _setIndexed(int index, int value) native "ExternalInt32Array_setIndexed";
}


class _ExternalUint32Array extends _ByteArrayBase implements Uint32Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Uint32Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint32Array result = new Uint32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index) native "ExternalUint32Array_getIndexed";

  void _setIndexed(int index, int value)
      native "ExternalUint32Array_setIndexed";
}


class _ExternalInt64Array extends _ByteArrayBase implements Int64Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Int64Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Int64Array result = new Int64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index) native "ExternalInt64Array_getIndexed";

  void _setIndexed(int index, int value) native "ExternalInt64Array_setIndexed";
}


class _ExternalUint64Array extends _ByteArrayBase implements Uint64Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  _Uint64Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Uint64Array result = new Uint64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index) native "ExternalUint64Array_getIndexed";

  void _setIndexed(int index, int value)
      native "ExternalUint64Array_setIndexed";
}


class _ExternalFloat32Array extends _ByteArrayBase implements Float32Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  _Float32Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Float32Array result = new Float32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat32Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index) native "ExternalFloat32Array_getIndexed";

  void _setIndexed(int index, int value)
      native "ExternalFloat32Array_setIndexed";
}


class _ExternalFloat64Array extends _ByteArrayBase implements Float64Array {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  _Float64Array getRange(int start, int length) {
    _rangeCheck(this, start, length);
    _Float64Array result = new Float64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat64Array) {
      int startInBytes = start * _BYTES_PER_ELEMENT;
      int lengthInBytes = length * _BYTES_PER_ELEMENT;
      int startFromInBytes = startFrom * _BYTES_PER_ELEMENT;
      _setRange(startInBytes, lengthInBytes, from, startFromInBytes);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static final int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index) native "ExternalFloat64Array_getIndexed";

  void _setIndexed(int index, int value)
      native "ExternalFloat64Array_setIndexed";
}


class _ByteArrayIterator<E> implements Iterator<E> {
  _ByteArrayIterator(_ByteArrayBase array)
    : _array = array, _length = array.length, _pos = 0;

  bool hasNext() {
   return _length > _pos;
  }

  E next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final List<E> _array;

  final int _length;

  int _pos;
}


class _ByteArrayView implements ByteArray {
  _ByteArrayView(this._array, this._offset, this._length) {
  }

  int lengthInBytes() {
    return _length;
  }

  ByteArray subByteArray([int start = 0, int length]) {
    if (length === null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return new _ByteArrayView(_array, _offset + start, length);
  }

  int getInt8(int byteOffset) {
    return _array._getInt8(_offset + byteOffset);
  }
  void setInt8(int byteOffset, int value) {
    _array._setInt8(_offset + byteOffset, value);
  }

  int getUint8(int byteOffset) {
    return _array._getUint8(_offset + byteOffset);
  }
  void setUint8(int byteOffset, int value) {
    _array._setUint8(_offset + byteOffset, value);
  }

  int getInt16(int byteOffset) {
    return _array._getInt16(_offset + byteOffset);
  }
  void setInt16(int byteOffset, int value) {
    _array._setInt16(_offset + byteOffset, value);
  }

  int getUint16(int byteOffset) {
    return _array._getUint16(_offset + byteOffset);
  }
  void setUint16(int byteOffset, int value) {
    _array._setUint16(_offset + byteOffset, value);
  }

  int getInt32(int byteOffset) {
    return _array._getInt32(_offset + byteOffset);
  }
  void setInt32(int byteOffset, int value) {
    _array._setInt32(_offset + byteOffset, value);
  }

  int getUint32(int byteOffset) {
    return _array._getUint32(_offset + byteOffset);
  }
  void setUint32(int byteOffset, int value) {
    _array._setUint32(_offset + byteOffset, value);
  }

  int getInt64(int byteOffset) {
    return _array._getInt64(_offset + byteOffset);
  }
  void setInt64(int byteOffset, int value) {
    _array._setInt64(_offset + byteOffset, value);
  }

  int getUint64(int byteOffset) {
    return _array._getUint64(_offset + byteOffset);
  }
  void setUint64(int byteOffset, int value) {
    _array._setUint64(_offset + byteOffset, value);
  }

  double getFloat32(int byteOffset) {
    return _array._getFloat32(_offset + byteOffset);
  }
  void setFloat32(int byteOffset, double value) {
    _array._setFloat32(_offset + byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _array._getFloat64(_offset + byteOffset);
  }
  void setFloat64(int byteOffset, double value) {
    _array._setFloat64(_offset + byteOffset, value);
  }

  final _ByteArrayBase _array;
  final int _offset;
  final int _length;
}


class _ByteArrayViewBase {
  void add(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addAll(Collection value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  set length(int newLength) {
    throw const UnsupportedOperationException(
        "Cannot resize a non-extendable array");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }
}


class _Int8ArrayView extends _ByteArrayViewBase implements Int8Array {
  _Int8ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getInt8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setInt8(_offset + (index * _BYTES_PER_ELEMENT), _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Int8Array result = new Int8Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 1;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint8ArrayView extends _ByteArrayViewBase implements Uint8Array {
  _Uint8ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getUint8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setUint8(_offset + (index * _BYTES_PER_ELEMENT), _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Uint8Array result = new Uint8Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 1;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int16ArrayView extends _ByteArrayViewBase implements Int16Array {
  _Int16ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getInt16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setInt16(_offset + (index * _BYTES_PER_ELEMENT), _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Int16Array result = new Int16Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 2;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint16ArrayView extends _ByteArrayViewBase implements Uint16Array {
  _Uint16ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getUint16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setUint16(_offset + (index * _BYTES_PER_ELEMENT), _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Uint16Array result = new Uint16Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 2;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int32ArrayView extends _ByteArrayViewBase implements Int32Array {
  _Int32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getInt32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setInt32(_offset + (index * _BYTES_PER_ELEMENT), _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Int32Array result = new Int32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint32ArrayView extends _ByteArrayViewBase implements Uint32Array {
  _Uint32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getUint32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setUint32(_offset + (index * _BYTES_PER_ELEMENT), _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Uint32Array result = new Uint32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int64ArrayView extends _ByteArrayViewBase implements Int64Array {
  _Int64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getInt64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setInt64(_offset + (index * _BYTES_PER_ELEMENT), _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Int64Array result = new Int64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint64ArrayView extends _ByteArrayViewBase implements Uint64Array {
  _Uint64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getUint64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setUint64(_offset + (index * _BYTES_PER_ELEMENT), _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Uint64Array result = new Uint64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Float32ArrayView extends _ByteArrayViewBase implements Float32Array {
  _Float32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  double operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getFloat32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setFloat32(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Float32Array result = new Float32Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Float64ArrayView extends _ByteArrayViewBase implements Float64Array {
  _Float64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = offsetInBytes,
      _length = (length === null) ? (array.lengthInBytes() - offsetInBytes)
    : length {
    if (offsetInBytes < 0 || offsetInBytes >= array.lengthInBytes()) {
      throw new IndexOutOfRangeException(offsetInBytes);
    }
    int lengthInBytes = length * _BYTES_PER_ELEMENT;
    if (length < 0 || (lengthInBytes + _offset) > array.lengthInBytes()) {
      throw new IndexOutOfRangeException(length);
    }
  }

  get length() {
    return _length;
  }

  double operator[](int index) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    return _array.getFloat64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= _length) {
      throw new IndexOutOfRangeException(index);
    }
    _array.setFloat64(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this, start, length);
    Float64Array result = new Float64Array(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static final int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}
