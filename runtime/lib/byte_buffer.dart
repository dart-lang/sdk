// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ByteBuffer implements List {
  factory ByteBuffer(int length) {
    return _allocate(length);
  }

  int getInt8(int byteOffset) {
    return _getInt8(byteOffset);
  }
  void setInt8(int byteOffset, int value) {
    _setInt8(byteOffset, value);
  }

  int getUint8(int byteOffset) {
    return _getUint8(byteOffset);
  }
  void setUint8(int byteOffset, int value) {
    _setUint8(byteOffset, value);
  }

  int getInt16(int byteOffset) {
    return _getInt16(byteOffset);
  }
  void setInt16(int byteOffset, int value) {
    _setInt16(byteOffset, value);
  }

  int getUint16(int byteOffset) {
    return _getInt16(byteOffset);
  }
  void setUint16(int byteOffset, int value) {
    _setUint16(byteOffset, value);
  }

  int getInt32(int byteOffset) {
    return _getInt32(byteOffset);
  }
  void setInt32(int byteOffset, int value) {
    _setInt32(byteOffset, value);
  }

  int getUint32(int byteOffset) {
    return _getUint32(byteOffset);
  }
  void setUint32(int byteOffset, int value) {
    _setUint32(byteOffset, value);
  }

  int getInt64(int byteOffset) {
    return _getInt64(byteOffset);
  }
  void setInt64(int byteOffset, int value) {
    _setInt64(byteOffset, value);
  }

  int getUint64(int byteOffset) {
    return _getUint64(byteOffset);
  }
  void setUint64(int byteOffset, int value) {
    _setUint64(byteOffset, value);
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

  // Iterable interface

  Iterator iterator() {
    return new ByteBufferIterator(this);
  }

  // Collection interface

  int get length() {
    return _length();
  }

  bool every(bool f(int element)) {
    return Collections.every(this, f);
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
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    _setUint8(index, value);
  }

  void set length(int newLength) {
    throw const UnsupportedOperationException("Cannot add to a byte buffer");
  }

  void add(int element) {
    throw const UnsupportedOperationException("Cannot add to a byte buffer");
  }

  void addLast(int element) {
    add(element);
  }

  void addAll(Collection elements) {
    throw const UnsupportedOperationException("Cannot add to a byte buffer");
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
    throw const UnsupportedOperationException("Cannot clear a byte buffer");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
      "Cannot remove from a byte buffer");
  }

  int last() {
    return this[length - 1];
  }

  // Implementation

  static ByteBuffer _allocate(int length) native "ByteBuffer_allocate";

  int _length() native "ByteBuffer_getLength";

  int _getInt8(int byteOffset) native "ByteBuffer_getInt8";
  void _setInt8(int byteOffset, int value) native "ByteBuffer_setInt8";

  int _getUint8(int byteOffset) native "ByteBuffer_getUint8";
  void _setUint8(int byteOffset, int value) native "ByteBuffer_setUint8";

  int _getInt16(int byteOffset) native "ByteBuffer_getInt16";
  void _setInt16(int byteOffset, int value) native "ByteBuffer_setInt16";

  int _getUint16(int byteOffset) native "ByteBuffer_getUint16";
  void _setUint16(int byteOffset, int value) native "ByteBuffer_setUint16";

  int _getInt32(int byteOffset) native "ByteBuffer_getInt32";
  void _setInt32(int byteOffset, int value) native "ByteBuffer_setInt32";

  int _getUint32(int byteOffset) native "ByteBuffer_getUint32";
  void _setUint32(int byteOffset, int value) native "ByteBuffer_setUint32";

  int _getInt64(int byteOffset) native "ByteBuffer_getInt64";
  void _setInt64(int byteOffset, int value) native "ByteBuffer_setInt64";

  int _getUint64(int byteOffset) native "ByteBuffer_getUint64";
  void _setUint64(int byteOffset, int value) native "ByteBuffer_setUint64";

  double _getFloat32(int byteOffset) native "ByteBuffer_getFloat32";
  void _setFloat32(int byteOffset, double value) native "ByteBuffer_setFloat32";

  double _getFloat64(int byteOffset) native "ByteBuffer_getFloat64";
  void _setFloat64(int byteOffset, double value) native "ByteBuffer_setFloat64";
}


class ByteBufferIterator implements Iterator {
  ByteBufferIterator(List byteBuffer)
      : _byteBuffer = byteBuffer, _length = byteBuffer.length, _pos = 0 {
    assert(byteBuffer is ByteBuffer);
  }

  bool hasNext() {
   return _length > _pos;
  }

  int next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _byteBuffer[_pos++];
  }

  final List _byteBuffer;
  final int _length;  // Cache byte buffer length for faster access.
  int _pos;
}
