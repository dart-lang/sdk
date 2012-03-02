
class _DataViewImpl extends _ArrayBufferViewImpl implements DataView {
  _DataViewImpl._wrap(ptr) : super._wrap(ptr);

  num getFloat32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getFloat32(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getFloat32(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  num getFloat64(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getFloat64(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getFloat64(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  int getInt16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getInt16(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getInt16(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  int getInt32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getInt32(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getInt32(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  Object getInt8() {
    return _wrap(_ptr.getInt8());
  }

  int getUint16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getUint16(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getUint16(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  int getUint32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _wrap(_ptr.getUint32(_unwrap(byteOffset)));
    } else {
      return _wrap(_ptr.getUint32(_unwrap(byteOffset), _unwrap(littleEndian)));
    }
  }

  Object getUint8() {
    return _wrap(_ptr.getUint8());
  }

  void setFloat32(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat32(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setFloat32(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setFloat64(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat64(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setFloat64(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setInt16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt16(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setInt16(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setInt32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt32(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setInt32(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setInt8() {
    _ptr.setInt8();
    return;
  }

  void setUint16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint16(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setUint16(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setUint32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint32(_unwrap(byteOffset), _unwrap(value));
      return;
    } else {
      _ptr.setUint32(_unwrap(byteOffset), _unwrap(value), _unwrap(littleEndian));
      return;
    }
  }

  void setUint8() {
    _ptr.setUint8();
    return;
  }
}
