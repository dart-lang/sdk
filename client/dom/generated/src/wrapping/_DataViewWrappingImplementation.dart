// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DataViewWrappingImplementation extends _ArrayBufferViewWrappingImplementation implements DataView {
  _DataViewWrappingImplementation() : super() {}

  static create__DataViewWrappingImplementation() native {
    return new _DataViewWrappingImplementation();
  }

  num getFloat32(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getFloat32(this, byteOffset);
    } else {
      return _getFloat32_2(this, byteOffset, littleEndian);
    }
  }
  static num _getFloat32(receiver, byteOffset) native;
  static num _getFloat32_2(receiver, byteOffset, littleEndian) native;

  num getFloat64(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getFloat64(this, byteOffset);
    } else {
      return _getFloat64_2(this, byteOffset, littleEndian);
    }
  }
  static num _getFloat64(receiver, byteOffset) native;
  static num _getFloat64_2(receiver, byteOffset, littleEndian) native;

  int getInt16(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getInt16(this, byteOffset);
    } else {
      return _getInt16_2(this, byteOffset, littleEndian);
    }
  }
  static int _getInt16(receiver, byteOffset) native;
  static int _getInt16_2(receiver, byteOffset, littleEndian) native;

  int getInt32(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getInt32(this, byteOffset);
    } else {
      return _getInt32_2(this, byteOffset, littleEndian);
    }
  }
  static int _getInt32(receiver, byteOffset) native;
  static int _getInt32_2(receiver, byteOffset, littleEndian) native;

  Object getInt8() {
    return _getInt8(this);
  }
  static Object _getInt8(receiver) native;

  int getUint16(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getUint16(this, byteOffset);
    } else {
      return _getUint16_2(this, byteOffset, littleEndian);
    }
  }
  static int _getUint16(receiver, byteOffset) native;
  static int _getUint16_2(receiver, byteOffset, littleEndian) native;

  int getUint32(int byteOffset, bool littleEndian = null) {
    if (littleEndian === null) {
      return _getUint32(this, byteOffset);
    } else {
      return _getUint32_2(this, byteOffset, littleEndian);
    }
  }
  static int _getUint32(receiver, byteOffset) native;
  static int _getUint32_2(receiver, byteOffset, littleEndian) native;

  Object getUint8() {
    return _getUint8(this);
  }
  static Object _getUint8(receiver) native;

  void setFloat32(int byteOffset, num value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setFloat32(this, byteOffset, value);
      return;
    } else {
      _setFloat32_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setFloat32(receiver, byteOffset, value) native;
  static void _setFloat32_2(receiver, byteOffset, value, littleEndian) native;

  void setFloat64(int byteOffset, num value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setFloat64(this, byteOffset, value);
      return;
    } else {
      _setFloat64_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setFloat64(receiver, byteOffset, value) native;
  static void _setFloat64_2(receiver, byteOffset, value, littleEndian) native;

  void setInt16(int byteOffset, int value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setInt16(this, byteOffset, value);
      return;
    } else {
      _setInt16_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setInt16(receiver, byteOffset, value) native;
  static void _setInt16_2(receiver, byteOffset, value, littleEndian) native;

  void setInt32(int byteOffset, int value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setInt32(this, byteOffset, value);
      return;
    } else {
      _setInt32_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setInt32(receiver, byteOffset, value) native;
  static void _setInt32_2(receiver, byteOffset, value, littleEndian) native;

  void setInt8() {
    _setInt8(this);
    return;
  }
  static void _setInt8(receiver) native;

  void setUint16(int byteOffset, int value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setUint16(this, byteOffset, value);
      return;
    } else {
      _setUint16_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setUint16(receiver, byteOffset, value) native;
  static void _setUint16_2(receiver, byteOffset, value, littleEndian) native;

  void setUint32(int byteOffset, int value, bool littleEndian = null) {
    if (littleEndian === null) {
      _setUint32(this, byteOffset, value);
      return;
    } else {
      _setUint32_2(this, byteOffset, value, littleEndian);
      return;
    }
  }
  static void _setUint32(receiver, byteOffset, value) native;
  static void _setUint32_2(receiver, byteOffset, value, littleEndian) native;

  void setUint8() {
    _setUint8(this);
    return;
  }
  static void _setUint8(receiver) native;

  String get typeName() { return "DataView"; }
}
