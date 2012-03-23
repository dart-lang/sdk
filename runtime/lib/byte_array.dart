// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ByteArray extends List default _InternalByteArray {
  ByteArray(int length);

  int get length();

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


class _ByteArrayBase {

  // Iterable interface

  Iterator iterator() {
    return new _ByteArrayIterator(this);
  }

  // Collection interface

  int get length() {
    return _length();
  }

  bool every(bool f(int element)) {
    return Collections.every(this, f);
  }

  Collection map(f(int element)) {
    return Collections.map(this,
                           new GrowableObjectArray.withCapacity(length), 
                           f);
  }

  Collection filter(bool f(int element)) {
    return Collections.filter(this, new GrowableObjectArray(), f);
  }

  void forEach(f(int element)) {
    Collections.forEach(this, f);
  }

  bool isEmpty() {
    return this.length === 0;
  }

  bool some(bool f(int element)) {
    return Collections.some(this, f);
  }

  // List interface

  int operator[](int index) {
    return getUint8(index);
  }

  void operator[]=(int index, int value) {
    setUint8(index, value);
  }

  void set length(int newLength) {
    throw const UnsupportedOperationException("Cannot add to a byte array");
  }

  void add(int element) {
    throw const UnsupportedOperationException("Cannot add to a byte array");
  }

  void addLast(int element) {
    add(element);
  }

  void addAll(Collection elements) {
    throw const UnsupportedOperationException("Cannot add to a byte array");
  }

  void sort(int compare(int a,  b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  int indexOf(int element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(int element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void clear() {
    throw const UnsupportedOperationException("Cannot clear a byte array");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
      "Cannot remove from a byte array");
  }

  int last() {
    return this[length - 1];
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    }
    if (from is ByteArray) {
      _setRange(start, length, from, startFrom);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }
  
  List getRange(int start, int length) {
    if (length == 0) return [];
    Arrays.rangeCheck(this, start, length);
    ByteArray list = new ByteArray(length);
    list._setRange(0, length, this, start);
    return list;
  }


  // Implementation

  int _toInt(int value, int mask) {
    int result = value & mask;
    return result > (mask >> 1) ? (result - mask) : result;
  }

  int _toInt8(int value) {
    return _toInt(value, (1 << 8) - 1);  // TODO(cshapiro): use a named value
  }

  int _toUint8(int value) {
    return value & ((1 << 8) - 1);  // TODO(cshapiro): use a named value
  }

  int _toInt16(int value) {
    return _toInt(value, (1 << 16) - 1);  // TODO(cshapiro): use a named value
  }

  int _toUint16(int value) {
    return value & ((1 << 16) - 1);  // TODO(cshapiro): use a named value
  }

  int _toInt32(int value) {
    return _toInt(value, (1 << 32) - 1);  // TODO(cshapiro): use a named value
  }

  int _toUint32(int value) {
    return value & ((1 << 32) - 1);  // TODO(cshapiro): use a named value
  }

  int _toInt64(int value) {
    return _toInt(value, (1 << 64) - 1);  // TODO(cshapiro): use a named value
  }

  int _toUint64(int value) {
    return value & ((1 << 64) - 1);  // TODO(cshapiro): use a named value
  }

  int _length() native "ByteArray_getLength";

  void _setRange(int start, int length, ByteArray from, int startFrom)
      native "ByteArray_setRange";
}


class _ByteArrayIterator implements Iterator {
  _ByteArrayIterator(List byteArray)
      : _byteArray = byteArray, _length = byteArray.length, _pos = 0 {
    assert(byteArray is ByteArray);
  }

  bool hasNext() {
   return _length > _pos;
  }

  int next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _byteArray[_pos++];
  }

  final List _byteArray;

  final int _length;

  int _pos;
}


class _InternalByteArray extends _ByteArrayBase implements ByteArray {
  factory _InternalByteArray(int length) {
    return _allocate(length);
  }

  // ByteArray interface

  int getInt8(int byteOffset) {
    return _getInt8(byteOffset);
  }

  void setInt8(int byteOffset, int value) {
    _setInt8(byteOffset, _toInt8(value));
  }

  int getUint8(int byteOffset) {
    return _getUint8(byteOffset);
  }

  void setUint8(int byteOffset, int value) {
    _setUint8(byteOffset, _toUint8(value));
  }

  int getInt16(int byteOffset) {
    return _getInt16(byteOffset);
  }

  void setInt16(int byteOffset, int value) {
    _setInt16(byteOffset, _toInt16(value));
  }

  int getUint16(int byteOffset) {
    return _getInt16(byteOffset);
  }

  void setUint16(int byteOffset, int value) {
    _setUint16(byteOffset, _toUint16(value));
  }

  int getInt32(int byteOffset) {
    return _getInt32(byteOffset);
  }

  void setInt32(int byteOffset, int value) {
    _setInt32(byteOffset, _toInt32(value));
  }

  int getUint32(int byteOffset) {
    return _getUint32(byteOffset);
  }

  void setUint32(int byteOffset, int value) {
    _setUint32(byteOffset, _toUint32(value));
  }

  int getInt64(int byteOffset) {
    return _getInt64(byteOffset);
  }

  void setInt64(int byteOffset, int value) {
    _setInt64(byteOffset, _toInt64(value));
  }

  int getUint64(int byteOffset) {
    return _getUint64(byteOffset);
  }

  void setUint64(int byteOffset, int value) {
    _setUint64(byteOffset, _toUint64(value));
  }

  double getFloat32(int byteOffset) {
    return _getFloat32(byteOffset);
  }

  void setFloat32(int byteOffset, double value) {
    _setFloat32(byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _getFloat64(byteOffset);
  }

  void setFloat64(int byteOffset, double value) {
    _setFloat64(byteOffset, value);
  }

  // Implementation

  static _InternalByteArray _allocate(int length)
    native "InternalByteArray_allocate";

  int _getInt8(int byteOffset)
    native "InternalByteArray_getInt8";

  void _setInt8(int byteOffset, int value)
    native "InternalByteArray_setInt8";

  int _getUint8(int byteOffset)
    native "InternalByteArray_getUint8";

  void _setUint8(int byteOffset, int value)
    native "InternalByteArray_setUint8";

  int _getInt16(int byteOffset)
    native "InternalByteArray_getInt16";

  void _setInt16(int byteOffset, int value)
    native "InternalByteArray_setInt16";

  int _getUint16(int byteOffset)
    native "InternalByteArray_getUint16";

  void _setUint16(int byteOffset, int value)
    native "InternalByteArray_setUint16";

  int _getInt32(int byteOffset)
    native "InternalByteArray_getInt32";

  void _setInt32(int byteOffset, int value)
    native "InternalByteArray_setInt32";

  int _getUint32(int byteOffset)
    native "InternalByteArray_getUint32";

  void _setUint32(int byteOffset, int value)
    native "InternalByteArray_setUint32";

  int _getInt64(int byteOffset)
    native "InternalByteArray_getInt64";

  void _setInt64(int byteOffset, int value)
    native "InternalByteArray_setInt64";

  int _getUint64(int byteOffset)
    native "InternalByteArray_getUint64";

  void _setUint64(int byteOffset, int value)
    native "InternalByteArray_setUint64";

  double _getFloat32(int byteOffset)
    native "InternalByteArray_getFloat32";

  void _setFloat32(int byteOffset, double value)
    native "InternalByteArray_setFloat32";

  double _getFloat64(int byteOffset)
    native "InternalByteArray_getFloat64";

  void _setFloat64(int byteOffset, double value)
    native "InternalByteArray_setFloat64";
}


class _ExternalByteArray extends _ByteArrayBase implements ByteArray {
  // Collection interface

  int get length() {
    return _length();
  }

  // List interface

  int operator[](int index) {
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    _setUint8(index, value);
  }

  // ByteArray interface

  int getInt8(int byteOffset) {
    return _getInt8(byteOffset);
  }

  void setInt8(int byteOffset, int value) {
    _setInt8(byteOffset, _toInt8(value));
  }

  int getUint8(int byteOffset) {
    return _getUint8(byteOffset);
  }

  void setUint8(int byteOffset, int value) {
    _setUint8(byteOffset, _toUint8(value));
  }

  int getInt16(int byteOffset) {
    return _getInt16(byteOffset);
  }

  void setInt16(int byteOffset, int value) {
    _setInt16(byteOffset, _toInt16(value));
  }

  int getUint16(int byteOffset) {
    return _getInt16(byteOffset);
  }

  void setUint16(int byteOffset, int value) {
    _setUint16(byteOffset, _toUint16(value));
  }

  int getInt32(int byteOffset) {
    return _getInt32(byteOffset);
  }

  void setInt32(int byteOffset, int value) {
    _setInt32(byteOffset, _toInt32(value));
  }

  int getUint32(int byteOffset) {
    return _getUint32(byteOffset);
  }

  void setUint32(int byteOffset, int value) {
    _setUint32(byteOffset, _toUint32(value));
  }

  int getInt64(int byteOffset) {
    return _getInt64(byteOffset);
  }

  void setInt64(int byteOffset, int value) {
    _setInt64(byteOffset, _toInt64(value));
  }

  int getUint64(int byteOffset) {
    return _getUint64(byteOffset);
  }

  void setUint64(int byteOffset, int value) {
    _setUint64(byteOffset, _toUint64(value));
  }

  double getFloat32(int byteOffset) {
    return _getFloat32(byteOffset);
  }

  void setFloat32(int byteOffset, double value) {
    _setFloat32(byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _getFloat64(byteOffset);
  }

  void setFloat64(int byteOffset, double value) {
    _setFloat64(byteOffset, value);
  }

  // Implementation

  int _getInt8(int byteOffset)
    native "ExternalByteArray_getInt8";

  void _setInt8(int byteOffset, int value)
    native "ExternalByteArray_setInt8";

  int _getUint8(int byteOffset)
    native "ExternalByteArray_getUint8";

  void _setUint8(int byteOffset, int value)
    native "ExternalByteArray_setUint8";

  int _getInt16(int byteOffset)
    native "ExternalByteArray_getInt16";

  void _setInt16(int byteOffset, int value)
    native "ExternalByteArray_setInt16";

  int _getUint16(int byteOffset)
    native "ExternalByteArray_getUint16";

  void _setUint16(int byteOffset, int value)
    native "ExternalByteArray_setUint16";

  int _getInt32(int byteOffset)
    native "ExternalByteArray_getInt32";

  void _setInt32(int byteOffset, int value)
    native "ExternalByteArray_setInt32";

  int _getUint32(int byteOffset)
    native "ExternalByteArray_getUint32";

  void _setUint32(int byteOffset, int value)
    native "ExternalByteArray_setUint32";

  int _getInt64(int byteOffset)
    native "ExternalByteArray_getInt64";

  void _setInt64(int byteOffset, int value)
    native "ExternalByteArray_setInt64";

  int _getUint64(int byteOffset)
    native "ExternalByteArray_getUint64";

  void _setUint64(int byteOffset, int value)
    native "ExternalByteArray_setUint64";

  double _getFloat32(int byteOffset)
    native "ExternalByteArray_getFloat32";

  void _setFloat32(int byteOffset, double value)
    native "ExternalByteArray_setFloat32";

  double _getFloat64(int byteOffset)
    native "ExternalByteArray_getFloat64";

  void _setFloat64(int byteOffset, double value)
    native "ExternalByteArray_setFloat64";
}
