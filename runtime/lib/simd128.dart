// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Float32x4 {
  /* patch */ factory Float32x4(double x, double y, double z, double w) {
    return new _Float32x4(x, y, z, w);
  }
  /* patch */ factory Float32x4.zero() {
    return new _Float32x4.zero();
  }
}

patch class Uint32x4 {
  /* patch */ factory Uint32x4(int x, int y, int z, int w) {
    return new _Uint32x4(x, y, z, w);
  }
  /* patch */ factory Uint32x4.bool(bool x, bool y, bool z, bool w) {
    return new _Uint32x4.bool(x, y, z, w);
  }
}


patch class Float32x4List {
  /* patch */ factory Float32x4List(int length) {
    return new _Float32x4Array(length);
  }

  /* patch */ factory Float32x4List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Float32x4List.view(ByteArray array,
                                                [int start = 0, int length]) {
    return new _Float32x4ArrayView(array, start, length);
  }

  static _ExternalFloat32x4Array _newTransferable(int length)
      native "Float32x4List_newTransferable";
}


// Expose native square root.
double _sqrt(double x) native "Math_sqrt";
class _Float32x4Dart implements Float32x4 {
  final Float32List _storage = new Float32List(4);
  _Float32x4Dart.empty() {
  }
  _Float32x4Dart.copy(Float32List other) {
    _storage[0] = other._storage[0];
    _storage[1] = other._storage[1];
    _storage[2] = other._storage[2];
    _storage[3] = other._storage[3];
  }
  factory _Float32x4Dart(double x, double y, double z, double w) {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = x;
    instance._storage[1] = y;
    instance._storage[2] = z;
    instance._storage[3] = w;
    return instance;
  }
  factory _Float32x4Dart.zero() {
    var instance = new _Float32x4Dart.empty();
    return instance;
  }
  Float32x4 operator +(Float32x4 other) {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[0] + other._storage[0];
    instance._storage[1] = _storage[1] + other._storage[1];
    instance._storage[2] = _storage[2] + other._storage[2];
    instance._storage[3] = _storage[3] + other._storage[3];
    return instance;
  }
  Float32x4 operator -() {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = -_storage[0];
    instance._storage[1] = -_storage[1];
    instance._storage[2] = -_storage[2];
    instance._storage[3] = -_storage[3];
    return instance;
  }
  Float32x4 operator -(Float32x4 other) {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[0] - other._storage[0];
    instance._storage[1] = _storage[1] - other._storage[1];
    instance._storage[2] = _storage[2] - other._storage[2];
    instance._storage[3] = _storage[3] - other._storage[3];
    return instance;
  }
  Float32x4 operator *(Float32x4 other) {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[0] * other._storage[0];
    instance._storage[1] = _storage[1] * other._storage[1];
    instance._storage[2] = _storage[2] * other._storage[2];
    instance._storage[3] = _storage[3] * other._storage[3];
    return instance;
  }
  Float32x4 operator /(Float32x4 other) {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[0] / other._storage[0];
    instance._storage[1] = _storage[1] / other._storage[1];
    instance._storage[2] = _storage[2] / other._storage[2];
    instance._storage[3] = _storage[3] / other._storage[3];
    return instance;
  }
  Uint32x4 lessThan(Float32x4 other) {
    bool _x = _storage[0] < other._storage[0];
    bool _y = _storage[1] < other._storage[1];
    bool _z = _storage[2] < other._storage[2];
    bool _w = _storage[3] < other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Uint32x4 lessThanOrEqual(Float32x4 other) {
    bool _x = _storage[0] <= other._storage[0];
    bool _y = _storage[1] <= other._storage[1];
    bool _z = _storage[2] <= other._storage[2];
    bool _w = _storage[3] <= other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Uint32x4 greaterThan(Float32x4 other) {
    bool _x = _storage[0] > other._storage[0];
    bool _y = _storage[1] > other._storage[1];
    bool _z = _storage[2] > other._storage[2];
    bool _w = _storage[3] > other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Uint32x4 greaterThanOrEqual(Float32x4 other) {
    bool _x = _storage[0] >= other._storage[0];
    bool _y = _storage[1] >= other._storage[1];
    bool _z = _storage[2] >= other._storage[2];
    bool _w = _storage[3] >= other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Uint32x4 equal(Float32x4 other) {
    bool _x = _storage[0] == other._storage[0];
    bool _y = _storage[1] == other._storage[1];
    bool _z = _storage[2] == other._storage[2];
    bool _w = _storage[3] == other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Uint32x4 notEqual(Float32x4 other) {
    bool _x = _storage[0] != other._storage[0];
    bool _y = _storage[1] != other._storage[1];
    bool _z = _storage[2] != other._storage[2];
    bool _w = _storage[3] != other._storage[3];
    return new Uint32x4.bool(_x, _y, _z, _w);
  }
  Float32x4 scale(double s) {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[0] *= s;
    instance._storage[1] *= s;
    instance._storage[2] *= s;
    instance._storage[3] *= s;
    return instance;
  }
  Float32x4 abs() {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[0] = instance._storage[0].abs();
    instance._storage[1] = instance._storage[1].abs();
    instance._storage[2] = instance._storage[2].abs();
    instance._storage[3] = instance._storage[3].abs();
    return instance;
  }
  Float32x4 clamp(Float32x4 lowerLimit,
                         Float32x4 upperLimit) {
    var instance = new _Float32x4Dart.copy(this);
    if (instance._storage[0] > upperLimit._storage[0]) {
      instance._storage[0] = upperLimit._storage[0];
    }
    if (instance._storage[1] > upperLimit._storage[1]) {
      instance._storage[1] = upperLimit._storage[1];
    }
    if (instance._storage[2] > upperLimit._storage[2]) {
      instance._storage[2] = upperLimit._storage[2];
    }
    if (instance._storage[3] > upperLimit._storage[3]) {
      instance._storage[3] = upperLimit._storage[3];
    }
    if (instance._storage[0] < lowerLimit._storage[0]) {
      instance._storage[0] = lowerLimit._storage[0];
    }
    if (instance._storage[1] < lowerLimit._storage[1]) {
      instance._storage[1] = lowerLimit._storage[1];
    }
    if (instance._storage[2] < lowerLimit._storage[2]) {
      instance._storage[2] = lowerLimit._storage[2];
    }
    if (instance._storage[3] < lowerLimit._storage[3]) {
      instance._storage[3] = lowerLimit._storage[3];
    }
    return instance;
  }
  double get x => _storage[0];
  double get y => _storage[1];
  double get z => _storage[2];
  double get w => _storage[3];
  Float32x4 get xxxx {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[0];
    instance._storage[1] = _storage[0];
    instance._storage[2] = _storage[0];
    instance._storage[3] = _storage[0];
    return instance;
  }
  Float32x4 get yyyy {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[1];
    instance._storage[1] = _storage[1];
    instance._storage[2] = _storage[1];
    instance._storage[3] = _storage[1];
    return instance;
  }
  Float32x4 get zzzz {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[2];
    instance._storage[1] = _storage[2];
    instance._storage[2] = _storage[2];
    instance._storage[3] = _storage[2];
    return instance;
  }
  Float32x4 get wwww {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _storage[3];
    instance._storage[1] = _storage[3];
    instance._storage[2] = _storage[3];
    instance._storage[3] = _storage[3];
    return instance;
  }
  Float32x4 withX(double x) {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[0] = x;
    return instance;
  }
  Float32x4 withY(double y) {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[1] = y;
    return instance;
  }
  Float32x4 withZ(double z) {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[2] = z;
    return instance;
  }
  Float32x4 withW(double w) {
    var instance = new _Float32x4Dart.copy(this);
    instance._storage[3] = w;
    return instance;
  }
  Float32x4 min(Float32x4 other) {
    var instance = new _Float32x4Dart.copy(this);
    if (instance._storage[0] > other._storage[0]) {
      instance._storage[0] = other._storage[0];
    }
    if (instance._storage[1] > other._storage[1]) {
      instance._storage[1] = other._storage[1];
    }
    if (instance._storage[2] > other._storage[2]) {
      instance._storage[2] = other._storage[2];
    }
    if (instance._storage[3] > other._storage[3]) {
      instance._storage[3] = other._storage[3];
    }
    return instance;
  }
  Float32x4 max(Float32x4 other) {
    var instance = new _Float32x4Dart.copy(this);
    if (instance._storage[0] < other._storage[0]) {
      instance._storage[0] = other._storage[0];
    }
    if (instance._storage[1] < other._storage[1]) {
      instance._storage[1] = other._storage[1];
    }
    if (instance._storage[2] < other._storage[2]) {
      instance._storage[2] = other._storage[2];
    }
    if (instance._storage[3] < other._storage[3]) {
      instance._storage[3] = other._storage[3];
    }
    return instance;
  }
  Float32x4 sqrt() {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _sqrt(_storage[0]);
    instance._storage[1] = _sqrt(_storage[1]);
    instance._storage[2] = _sqrt(_storage[2]);
    instance._storage[3] = _sqrt(_storage[3]);
    return instance;
  }
  Float32x4 reciprocal() {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = (1.0 / _storage[0]);
    instance._storage[1] = (1.0 / _storage[1]);
    instance._storage[2] = (1.0 / _storage[2]);
    instance._storage[3] = (1.0 / _storage[3]);
    return instance;
  }
  Float32x4 reciprocalSqrt() {
    var instance = new _Float32x4Dart.empty();
    instance._storage[0] = _sqrt(1.0 / _storage[0]);
    instance._storage[1] = _sqrt(1.0 / _storage[1]);
    instance._storage[2] = _sqrt(1.0 / _storage[2]);
    instance._storage[3] = _sqrt(1.0 / _storage[3]);
    return instance;
  }
  Uint32x4 toUint32x4() {
    Uint32List view = new Uint32List.view(_storage.asByteArray());
    return new Uint32x4(view[0], view[1], view[2], view[3]);
  }
}

class _Uint32x4Dart implements Uint32x4 {
  final Uint32List _storage = new Uint32List(4);
  _Uint32x4Dart.empty() {
  }
  _Uint32x4Dart.copy(_Uint32x4Dart other) {
    _storage[0] = other._storage[0];
    _storage[1] = other._storage[1];
    _storage[2] = other._storage[2];
    _storage[3] = other._storage[3];
  }
  factory _Uint32x4Dart(int x, int y, int z, int w) {
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = x;
    instance._storage[1] = y;
    instance._storage[2] = z;
    instance._storage[3] = w;
    return instance;
  }
  factory _Uint32x4Dart.bool(bool x, bool y, bool z, bool w) {
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = x ? 0xFFFFFFFF : 0x0;
    instance._storage[1] = y ? 0xFFFFFFFF : 0x0;
    instance._storage[2] = z ? 0xFFFFFFFF : 0x0;
    instance._storage[3] = w ? 0xFFFFFFFF : 0x0;
    return instance;
  }
  Uint32x4 operator |(Uint32x4 other) {
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = _storage[0] | other._storage[0];
    instance._storage[1] = _storage[1] | other._storage[1];
    instance._storage[2] = _storage[2] | other._storage[2];
    instance._storage[3] = _storage[3] | other._storage[3];
    return instance;
  }
  Uint32x4 operator &(Uint32x4 other) {
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = _storage[0] & other._storage[0];
    instance._storage[1] = _storage[1] & other._storage[1];
    instance._storage[2] = _storage[2] & other._storage[2];
    instance._storage[3] = _storage[3] & other._storage[3];
    return instance;
  }
  Uint32x4 operator ^(Uint32x4 other) {
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = _storage[0] ^ other._storage[0];
    instance._storage[1] = _storage[1] ^ other._storage[1];
    instance._storage[2] = _storage[2] ^ other._storage[2];
    instance._storage[3] = _storage[3] ^ other._storage[3];
    return instance;
  }
  int get x => _storage[0];
  int get y => _storage[1];
  int get z => _storage[2];
  int get w => _storage[3];
  Uint32x4 withX(int x) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[0] = x & 0xFFFFFFFF;
    return instance;
  }
  Uint32x4 withY(int y) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[1] = y & 0xFFFFFFFF;
    return instance;
  }
  Uint32x4 withZ(int z) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[2] = z & 0xFFFFFFFF;
    return instance;
  }
  Uint32x4 withW(int w) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[3] = w & 0xFFFFFFFF;
    return instance;
  }
  bool get flagX => _storage[0] != 0x0;
  bool get flagY => _storage[1] != 0x0;
  bool get flagZ => _storage[2] != 0x0;
  bool get flagW => _storage[3] != 0x0;
  Uint32x4 withFlagX(bool x) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[0] = x ? 0xFFFFFFFF : 0x0;
    return instance;
  }
  Uint32x4 withFlagY(bool y) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[1] = y ? 0xFFFFFFFF : 0x0;
    return instance;
  }
  Uint32x4 withFlagZ(bool z) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[2] = z ? 0xFFFFFFFF : 0x0;
    return instance;
  }
  Uint32x4 withFlagW(bool w) {
    var instance = new _Uint32x4Dart.copy(this);
    instance._storage[3] = w ? 0xFFFFFFFF : 0x0;
    return instance;
  }
  Float32x4 select(Float32x4 trueValue,
                          Float32x4 falseValue) {
    Uint32x4 trueMask = trueValue.toUint32x4();
    Uint32x4 falseMask = falseValue.toUint32x4();
    var instance = new _Uint32x4Dart.empty();
    instance._storage[0] = (_storage[0] & trueMask._storage[0]);
    instance._storage[1] = (_storage[1] & trueMask._storage[1]);
    instance._storage[2] = (_storage[2] & trueMask._storage[2]);
    instance._storage[3] = (_storage[3] & trueMask._storage[3]);
    instance._storage[0] |= (~_storage[0] & falseMask._storage[0]);
    instance._storage[1] |= (~_storage[1] & falseMask._storage[1]);
    instance._storage[2] |= (~_storage[2] & falseMask._storage[2]);
    instance._storage[3] |= (~_storage[3] & falseMask._storage[3]);
    return instance.toFloat32x4();
  }
  Float32x4 toFloat32x4() {
    Float32List view = new Float32List.view(_storage.asByteArray());
    return new Float32x4(view[0], view[1], view[2], view[3]);
  }
}

class _Float32x4 implements Float32x4 {
  factory _Float32x4(double x, double y, double z, double w)
      native "Float32x4_fromDoubles";
  factory _Float32x4.zero() native "Float32x4_zero";
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
  Uint32x4 lessThan(Float32x4 other) {
    return _cmplt(other);
  }
  Uint32x4 _cmplt(Float32x4 other) native "Float32x4_cmplt";
  Uint32x4 lessThanOrEqual(Float32x4 other) {
    return _cmplte(other);
  }
  Uint32x4 _cmplte(Float32x4 other) native "Float32x4_cmplte";
  Uint32x4 greaterThan(Float32x4 other) {
    return _cmpgt(other);
  }
  Uint32x4 _cmpgt(Float32x4 other) native "Float32x4_cmpgt";
  Uint32x4 greaterThanOrEqual(Float32x4 other) {
    return _cmpgte(other);
  }
  Uint32x4 _cmpgte(Float32x4 other) native "Float32x4_cmpgte";
  Uint32x4 equal(Float32x4 other) {
    return _cmpequal(other);
  }
  Uint32x4 _cmpequal(Float32x4 other)
      native "Float32x4_cmpequal";
  Uint32x4 notEqual(Float32x4 other) {
    return _cmpnequal(other);
  }
  Uint32x4 _cmpnequal(Float32x4 other)
      native "Float32x4_cmpnequal";
  Float32x4 scale(double s) {
    return _scale(s);
  }
  Float32x4 _scale(double s) native "Float32x4_scale";
  Float32x4 abs() {
    return _abs();
  }
  Float32x4 _abs() native "Float32x4_abs";
  Float32x4 clamp(Float32x4 lowerLimit,
                         Float32x4 upperLimit) {
    return _clamp(lowerLimit, upperLimit);
  }
  Float32x4 _clamp(Float32x4 lowerLimit,
                          Float32x4 upperLimit)
      native "Float32x4_clamp";
  double get x native "Float32x4_getX";
  double get y native "Float32x4_getY";
  double get z native "Float32x4_getZ";
  double get w native "Float32x4_getW";
  Float32x4 get xxxx native "Float32x4_getXXXX";
  Float32x4 get yyyy native "Float32x4_getYYYY";
  Float32x4 get zzzz native "Float32x4_getZZZZ";
  Float32x4 get wwww native "Float32x4_getWWWW";
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
  Uint32x4 toUint32x4() {
      return _toUint32x4();
  }
  Uint32x4 _toUint32x4() native "Float32x4_toUint32x4";
}

class _Uint32x4 implements Uint32x4 {
  factory _Uint32x4(int x, int y, int z, int w)
      native "Uint32x4_fromInts";
  factory _Uint32x4.bool(bool x, bool y, bool z, bool w)
      native "Uint32x4_fromBools";
  Uint32x4 operator |(Uint32x4 other) {
    return _or(other);
  }
  Uint32x4 _or(Uint32x4 other) native "Uint32x4_or";
  Uint32x4 operator &(Uint32x4 other) {
    return _and(other);
  }
  Uint32x4 _and(Uint32x4 other) native "Uint32x4_and";
  Uint32x4 operator ^(Uint32x4 other) {
    return _xor(other);
  }
  Uint32x4 _xor(Uint32x4 other) native "Uint32x4_xor";
  int get x native "Uint32x4_getX";
  int get y native "Uint32x4_getY";
  int get z native "Uint32x4_getZ";
  int get w native "Uint32x4_getW";
  Uint32x4 withX(int x) native "Uint32x4_setX";
  Uint32x4 withY(int y) native "Uint32x4_setY";
  Uint32x4 withZ(int z) native "Uint32x4_setZ";
  Uint32x4 withW(int w) native "Uint32x4_setW";
  bool get flagX native "Uint32x4_getFlagX";
  bool get flagY native "Uint32x4_getFlagY";
  bool get flagZ native "Uint32x4_getFlagZ";
  bool get flagW native "Uint32x4_getFlagW";
  Uint32x4 withFlagX(bool x) native "Uint32x4_setFlagX";
  Uint32x4 withFlagY(bool y) native "Uint32x4_setFlagY";
  Uint32x4 withFlagZ(bool z) native "Uint32x4_setFlagZ";
  Uint32x4 withFlagW(bool w) native "Uint32x4_setFlagW";
  Float32x4 select(Float32x4 trueValue,
                          Float32x4 falseValue) {
    return _select(trueValue, falseValue);
  }
  Float32x4 _select(Float32x4 trueValue,
                           Float32x4 falseValue)
      native "Uint32x4_select";
  Float32x4 toFloat32x4() {
      return _toFloat32x4();
  }
  Float32x4 _toFloat32x4() native "Uint32x4_toFloat32x4";
}


class _Float32x4Array extends _ByteArrayBase
    implements Float32x4List {
  factory _Float32x4Array(int length) {
    return _new(length);
  }

  factory _Float32x4Array.view(ByteArray array,
                                    [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float32x4ArrayView(array, start, length);
  }

  Float32x4 operator [](int index) {
    return _getIndexed(index);
  }

  int operator []=(int index, Float32x4 value) {
    _setIndexed(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _ByteArrayIterator<Float32x4>(this);
  }

  List<Float32x4> sublist(int start, [int end]) {
    if (end == null) end = length;
    int length = end - start;
    _rangeCheck(this.length, start, length);
    List<Float32x4> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  List<Float32x4> getRange(int start, int length) {
    return sublist(start, start + length);
  }

  void setRange(int start, int length, List<Float32x4> from,
                [int startFrom = 0]) {
    if (from is _Float32x4Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      IterableMixinWorkaround.setRangeList(
          this, start, length, from, startFrom);
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
  static const int _BYTES_PER_ELEMENT = 16;
  static _Float32x4Array _new(int length)
      native "Float32x4Array_new";
  Float32x4 _getIndexed(int index)
      native "Float32x4Array_getIndexed";
  int _setIndexed(int index, Float32x4 value)
      native "Float32x4Array_setIndexed";
}


class _Float32x4ArrayView extends _ByteArrayViewBase
    implements Float32x4List {
  _Float32x4ArrayView(ByteArray array,
                           [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  Float32x4 operator [](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getFloat32x4(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator []=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setFloat32x4(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<Float32x4> get iterator {
    return new _ByteArrayIterator<Float32x4>(this);
  }

  List<Float32x4> sublist(int start, [int end]) {
    if (end == null) end = length;
    int length = end - start;
    _rangeCheck(this.length, start, length);
    List<Float32x4> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  List<Float32x4> getRange(int start, int length) {
    return sublist(start, start + length);
  }

  void setRange(int start, int length, List<Float32x4> from,
               [int startFrom = 0]) {
    IterableMixinWorkaround.setRangeList(this, start, length, from, startFrom);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 16;
}


class _ExternalFloat32x4Array extends _ByteArrayBase
  implements Float32x4List {
  Float32x4 operator [](int index) {
    return _getIndexed(index);
  }

  int operator []=(int index, Float32x4 value) {
    _setIndexed(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _ByteArrayIterator<Float32x4>(this);
  }

  List<Float32x4> sublist(int start, [int end]) {
    if (end == null) end = length;
    int length = end - start;
    _rangeCheck(this.length, start, length);
    List<Float32x4> result = new Float32x4List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  List<Float32x4> getRange(int start, int length) {
    return sublist(start, start + length);
  }

  void setRange(int start, int length, List<Float32x4> from,
                [int startFrom = 0]) {
    if (from is _ExternalFloat32x4Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      IterableMixinWorkaround.setRangeList(
          this, start, length, from, startFrom);
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

  static const int _BYTES_PER_ELEMENT = 16;

  Float32x4 _getIndexed(int index)
      native "ExternalFloat32x4Array_getIndexed";
  int _setIndexed(int index, Float32x4 value)
      native "ExternalFloat32x4Array_setIndexed";
}
