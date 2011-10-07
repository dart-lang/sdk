// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataViewWrappingImplementation extends ArrayBufferViewWrappingImplementation implements DataView {
  DataViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num getFloat32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getFloat32(byteOffset);
    } else {
      return _ptr.getFloat32(byteOffset, littleEndian);
    }
  }

  num getFloat64(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getFloat64(byteOffset);
    } else {
      return _ptr.getFloat64(byteOffset, littleEndian);
    }
  }

  int getInt16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getInt16(byteOffset);
    } else {
      return _ptr.getInt16(byteOffset, littleEndian);
    }
  }

  int getInt32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getInt32(byteOffset);
    } else {
      return _ptr.getInt32(byteOffset, littleEndian);
    }
  }

  int getInt8() {
    return _ptr.getInt8();
  }

  int getUint16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getUint16(byteOffset);
    } else {
      return _ptr.getUint16(byteOffset, littleEndian);
    }
  }

  int getUint32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getUint32(byteOffset);
    } else {
      return _ptr.getUint32(byteOffset, littleEndian);
    }
  }

  int getUint8() {
    return _ptr.getUint8();
  }

  void setFloat32(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat32(byteOffset, value);
      return;
    } else {
      _ptr.setFloat32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setFloat64(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat64(byteOffset, value);
      return;
    } else {
      _ptr.setFloat64(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt16(byteOffset, value);
      return;
    } else {
      _ptr.setInt16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt32(byteOffset, value);
      return;
    } else {
      _ptr.setInt32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt8() {
    _ptr.setInt8();
    return;
  }

  void setUint16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint16(byteOffset, value);
      return;
    } else {
      _ptr.setUint16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint32(byteOffset, value);
      return;
    } else {
      _ptr.setUint32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint8() {
    _ptr.setUint8();
    return;
  }
}
