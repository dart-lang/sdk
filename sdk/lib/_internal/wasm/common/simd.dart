// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._simd;

import 'dart:_internal' show FixedLengthListMixin, IterableElementError;

import 'dart:collection' show ListMixin;
import 'dart:typed_data';
import 'dart:_error_utils';
import 'dart:_internal' show WasmTypedDataBase;
import 'dart:_wasm';

final class NaiveInt32x4List extends WasmTypedDataBase
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final Int32List _storage;

  NaiveInt32x4List(int length) : _storage = Int32List(length * 4);

  NaiveInt32x4List.externalStorage(Int32List storage) : _storage = storage;

  NaiveInt32x4List._slowFromList(List<Int32x4> list)
    : _storage = Int32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  factory NaiveInt32x4List.fromList(List<Int32x4> list) {
    if (list is NaiveInt32x4List) {
      return NaiveInt32x4List.externalStorage(
        Int32List.fromList(list._storage),
      );
    } else {
      return NaiveInt32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Int32x4 operator [](int index) {
    IndexErrorUtils.checkIndex(index, length, "[]");
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return I32x4._truncated(_x, _y, _z, _w);
  }

  void operator []=(int index, Int32x4 value) {
    IndexErrorUtils.checkIndex(index, length, "[]=");
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Int32x4List asUnmodifiableView() =>
      NaiveUnmodifiableInt32x4List.externalStorage(_storage);

  Int32x4List sublist(int start, [int? end]) {
    end = RangeErrorUtils.checkValidRange(start, end, length);
    return NaiveInt32x4List.externalStorage(
      _storage.sublist(start * 4, end * 4),
    );
  }

  void setRange(
    int start,
    int end,
    Iterable<Int32x4> from, [
    int skipCount = 0,
  ]) {
    RangeErrorUtils.checkValidRange(start, end, length);
    RangeErrorUtils.checkNotNegative(skipCount, 'skipCount');

    final count = end - start;
    if (count == 0) return;

    final List<Int32x4> fromList = from.skip(skipCount).toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableInt32x4List extends NaiveInt32x4List {
  NaiveUnmodifiableInt32x4List.externalStorage(Int32List storage)
    : super.externalStorage(storage);

  @override
  void operator []=(int index, Int32x4 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

final class NaiveFloat32x4List extends WasmTypedDataBase
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final Float32List _storage;

  NaiveFloat32x4List(int length) : _storage = Float32List(length * 4);

  NaiveFloat32x4List.externalStorage(this._storage);

  NaiveFloat32x4List._slowFromList(List<Float32x4> list)
    : _storage = Float32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  factory NaiveFloat32x4List.fromList(List<Float32x4> list) {
    if (list is NaiveFloat32x4List) {
      return NaiveFloat32x4List.externalStorage(
        Float32List.fromList(list._storage),
      );
    } else {
      return NaiveFloat32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Float32x4 operator [](int index) {
    IndexErrorUtils.checkIndex(index, length, "[]");
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return F32x4(_x, _y, _z, _w);
  }

  void operator []=(int index, Float32x4 value) {
    IndexErrorUtils.checkIndex(index, length, "[]=");
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Float32x4List asUnmodifiableView() =>
      NaiveUnmodifiableFloat32x4List.externalStorage(_storage);

  Float32x4List sublist(int start, [int? end]) {
    end = RangeErrorUtils.checkValidRange(start, end, length);
    return NaiveFloat32x4List.externalStorage(
      _storage.sublist(start * 4, end * 4),
    );
  }

  void setRange(
    int start,
    int end,
    Iterable<Float32x4> from, [
    int skipCount = 0,
  ]) {
    RangeErrorUtils.checkValidRange(start, end, length);
    RangeErrorUtils.checkNotNegative(skipCount, 'skipCount');

    final count = end - start;
    if (count == 0) return;

    final List<Float32x4> fromList = from
        .skip(skipCount)
        .toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableFloat32x4List extends NaiveFloat32x4List {
  NaiveUnmodifiableFloat32x4List.externalStorage(Float32List storage)
    : super.externalStorage(storage);

  @override
  void operator []=(int index, Float32x4 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

final class NaiveFloat64x2List extends WasmTypedDataBase
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final Float64List _storage;

  NaiveFloat64x2List(int length) : _storage = Float64List(length * 2);

  NaiveFloat64x2List.externalStorage(this._storage);

  NaiveFloat64x2List._slowFromList(List<Float64x2> list)
    : _storage = Float64List(list.length * 2) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 2) + 0] = e.x;
      _storage[(i * 2) + 1] = e.y;
    }
  }

  factory NaiveFloat64x2List.fromList(List<Float64x2> list) {
    if (list is NaiveFloat64x2List) {
      return NaiveFloat64x2List.externalStorage(
        Float64List.fromList(list._storage),
      );
    } else {
      return NaiveFloat64x2List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  int get length => _storage.length ~/ 2;

  Float64x2 operator [](int index) {
    IndexErrorUtils.checkIndex(index, length, "[]");
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  void operator []=(int index, Float64x2 value) {
    IndexErrorUtils.checkIndex(index, length, "[]=");
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  Float64x2List asUnmodifiableView() =>
      NaiveUnmodifiableFloat64x2List.externalStorage(_storage);

  Float64x2List sublist(int start, [int? end]) {
    end = RangeErrorUtils.checkValidRange(start, end, length);
    return NaiveFloat64x2List.externalStorage(
      _storage.sublist(start * 2, end * 2),
    );
  }

  void setRange(
    int start,
    int end,
    Iterable<Float64x2> from, [
    int skipCount = 0,
  ]) {
    RangeErrorUtils.checkValidRange(start, end, length);
    RangeErrorUtils.checkNotNegative(skipCount, 'skipCount');

    final count = end - start;
    if (count == 0) return;

    final List<Float64x2> fromList = from
        .skip(skipCount)
        .toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableFloat64x2List extends NaiveFloat64x2List {
  NaiveUnmodifiableFloat64x2List.externalStorage(Float64List storage)
    : super.externalStorage(storage);

  @override
  void operator []=(int index, Float64x2 value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

@pragma("wasm:entry-point")
final class F32x4 extends WasmTypedDataBase implements Float32x4 {
  @pragma("wasm:entry-point")
  final WasmV128 _bits;

  // Scratch storage used by shuffle / shuffleMix. Lane reads from `_bits`
  // already use single wasm v128 lane-extract intrinsics, so no scratch is
  // needed for the simple element-wise operators.
  static final Float32List _list = Float32List(4);

  @pragma("wasm:entry-point")
  F32x4.fromV128(this._bits);

  factory F32x4(double x, double y, double z, double w) => F32x4.fromV128(
    WasmF32x4.fromLaneValues(
      WasmF32.fromDouble(x),
      WasmF32.fromDouble(y),
      WasmF32.fromDouble(z),
      WasmF32.fromDouble(w),
    ),
  );

  factory F32x4.splat(double value) =>
      F32x4.fromV128(WasmF32x4.splat(WasmF32.fromDouble(value)));

  factory F32x4.zero() =>
      F32x4.fromV128(WasmF32x4.splat(WasmF32.fromDouble(0.0)));

  factory F32x4.fromInt32x4Bits(Int32x4 bits) =>
      F32x4.fromV128((bits as I32x4)._bits);

  factory F32x4.fromFloat64x2(Float64x2 xy) => F32x4(xy.x, xy.y, 0.0, 0.0);

  double get x => WasmF32x4(_bits).extractLane(0).toDouble();
  double get y => WasmF32x4(_bits).extractLane(1).toDouble();
  double get z => WasmF32x4(_bits).extractLane(2).toDouble();
  double get w => WasmF32x4(_bits).extractLane(3).toDouble();

  @override
  String toString() {
    return '[${x.toStringAsFixed(6)}, '
        '${y.toStringAsFixed(6)}, '
        '${z.toStringAsFixed(6)}, '
        '${w.toStringAsFixed(6)}]';
  }

  Float32x4 operator +(Float32x4 other) =>
      F32x4.fromV128(WasmF32x4(_bits) + WasmF32x4((other as F32x4)._bits));

  Float32x4 operator -() => F32x4.fromV128(-WasmF32x4(_bits));

  Float32x4 operator -(Float32x4 other) =>
      F32x4.fromV128(WasmF32x4(_bits) - WasmF32x4((other as F32x4)._bits));

  Float32x4 operator *(Float32x4 other) =>
      F32x4.fromV128(WasmF32x4(_bits) * WasmF32x4((other as F32x4)._bits));

  Float32x4 operator /(Float32x4 other) =>
      F32x4.fromV128(WasmF32x4(_bits) / WasmF32x4((other as F32x4)._bits));

  Int32x4 lessThan(Float32x4 other) =>
      I32x4.fromV128(WasmF32x4(_bits).lt(WasmF32x4((other as F32x4)._bits)));

  Int32x4 lessThanOrEqual(Float32x4 other) =>
      I32x4.fromV128(WasmF32x4(_bits).le(WasmF32x4((other as F32x4)._bits)));

  Int32x4 greaterThan(Float32x4 other) =>
      I32x4.fromV128(WasmF32x4(_bits).gt(WasmF32x4((other as F32x4)._bits)));

  Int32x4 greaterThanOrEqual(Float32x4 other) =>
      I32x4.fromV128(WasmF32x4(_bits).ge(WasmF32x4((other as F32x4)._bits)));

  Int32x4 equal(Float32x4 other) =>
      I32x4.fromV128(WasmF32x4(_bits).eq(WasmF32x4((other as F32x4)._bits)));

  Int32x4 notEqual(Float32x4 other) =>
      I32x4.fromV128(~WasmF32x4(_bits).eq(WasmF32x4((other as F32x4)._bits)));

  Float32x4 scale(double scale) => F32x4.fromV128(
    WasmF32x4(_bits) * WasmF32x4.splat(WasmF32.fromDouble(scale)),
  );

  Float32x4 abs() => F32x4.fromV128(WasmF32x4(_bits).abs());

  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _lz = lowerLimit.z;
    double _lw = lowerLimit.w;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _uz = upperLimit.z;
    double _uw = upperLimit.w;
    double _x = x;
    double _y = y;
    double _z = z;
    double _w = w;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _z = _z > _uz ? _uz : _z;
    _w = _w > _uw ? _uw : _w;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    _z = _z < _lz ? _lz : _z;
    _w = _w < _lw ? _lw : _w;
    return F32x4(_x, _y, _z, _w);
  }

  int get signMask => WasmI32x4(_bits).bitmask.toIntUnsigned();

  Float32x4 shuffle(int mask) {
    // mask < 0 || mask > 255
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(mask, 255, 'mask');
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;

    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return F32x4(_x, _y, _z, _w);
  }

  Float32x4 shuffleMix(Float32x4 other, int mask) {
    // mask < 0 || mask > 255
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(mask, 255, 'mask');
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return F32x4(_x, _y, _z, _w);
  }

  Float32x4 withX(double newX) =>
      F32x4.fromV128(WasmF32x4(_bits).replaceLane(0, WasmF32.fromDouble(newX)));

  Float32x4 withY(double newY) =>
      F32x4.fromV128(WasmF32x4(_bits).replaceLane(1, WasmF32.fromDouble(newY)));

  Float32x4 withZ(double newZ) =>
      F32x4.fromV128(WasmF32x4(_bits).replaceLane(2, WasmF32.fromDouble(newZ)));

  Float32x4 withW(double newW) =>
      F32x4.fromV128(WasmF32x4(_bits).replaceLane(3, WasmF32.fromDouble(newW)));

  Float32x4 min(Float32x4 other) {
    double _x = x < other.x ? x : other.x;
    double _y = y < other.y ? y : other.y;
    double _z = z < other.z ? z : other.z;
    double _w = w < other.w ? w : other.w;
    return F32x4(_x, _y, _z, _w);
  }

  Float32x4 max(Float32x4 other) {
    double _x = x > other.x ? x : other.x;
    double _y = y > other.y ? y : other.y;
    double _z = z > other.z ? z : other.z;
    double _w = w > other.w ? w : other.w;
    return F32x4(_x, _y, _z, _w);
  }

  Float32x4 sqrt() => F32x4.fromV128(WasmF32x4(_bits).sqrt());

  Float32x4 reciprocal() => F32x4.fromV128(
    WasmF32x4.splat(WasmF32.fromDouble(1.0)) / WasmF32x4(_bits),
  );

  Float32x4 reciprocalSqrt() => F32x4.fromV128(
    (WasmF32x4.splat(WasmF32.fromDouble(1.0)) / WasmF32x4(_bits)).sqrt(),
  );
}

/// Exposes the raw [WasmV128] backing an [F32x4] to the SIMD-backed
/// `Float32x4List`, which lives in a different library than [F32x4].
extension F32x4Ext on F32x4 {
  @pragma("wasm:prefer-inline")
  WasmV128 get bits => _bits;
}

@pragma("wasm:entry-point")
final class F64x2 extends WasmTypedDataBase implements Float64x2 {
  @pragma("wasm:entry-point")
  final WasmV128 _bits;

  @pragma("wasm:entry-point")
  F64x2.fromV128(this._bits);

  factory F64x2(double x, double y) =>
      F64x2.fromV128(WasmF64x2.fromDoubles(x, y));

  factory F64x2.splat(double v) =>
      F64x2.fromV128(WasmF64x2.splat(WasmF64.fromDouble(v)));

  factory F64x2.zero() =>
      F64x2.fromV128(WasmF64x2.splat(WasmF64.fromDouble(0.0)));

  factory F64x2.fromFloat32x4(Float32x4 v) => F64x2(v.x, v.y);

  double get x => WasmF64x2(_bits).extractLane(0).toDouble();
  double get y => WasmF64x2(_bits).extractLane(1).toDouble();

  String toString() => '[$x, $y]';

  Float64x2 operator +(Float64x2 other) =>
      F64x2.fromV128(WasmF64x2(_bits) + WasmF64x2((other as F64x2)._bits));

  Float64x2 operator -() => F64x2.fromV128(-WasmF64x2(_bits));

  Float64x2 operator -(Float64x2 other) =>
      F64x2.fromV128(WasmF64x2(_bits) - WasmF64x2((other as F64x2)._bits));

  Float64x2 operator *(Float64x2 other) =>
      F64x2.fromV128(WasmF64x2(_bits) * WasmF64x2((other as F64x2)._bits));

  Float64x2 operator /(Float64x2 other) =>
      F64x2.fromV128(WasmF64x2(_bits) / WasmF64x2((other as F64x2)._bits));

  Float64x2 scale(double s) =>
      F64x2.fromV128(WasmF64x2(_bits) * WasmF64x2.splat(WasmF64.fromDouble(s)));

  Float64x2 abs() => F64x2.fromV128(WasmF64x2(_bits).abs());

  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _x = x;
    double _y = y;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    return F64x2(_x, _y);
  }

  int get signMask => WasmI64x2(_bits).bitmask.toIntUnsigned();

  Float64x2 withX(double x) =>
      F64x2.fromV128(WasmF64x2(_bits).replaceLane(0, WasmF64.fromDouble(x)));

  Float64x2 withY(double y) =>
      F64x2.fromV128(WasmF64x2(_bits).replaceLane(1, WasmF64.fromDouble(y)));

  Float64x2 min(Float64x2 other) =>
      F64x2(x < other.x ? x : other.x, y < other.y ? y : other.y);

  Float64x2 max(Float64x2 other) =>
      F64x2(x > other.x ? x : other.x, y > other.y ? y : other.y);

  Float64x2 sqrt() => F64x2.fromV128(WasmF64x2(_bits).sqrt());
}

@pragma("wasm:entry-point")
final class I32x4 extends WasmTypedDataBase implements Int32x4 {
  @pragma("wasm:entry-point")
  final WasmV128 _bits;

  // Scratch storage used by shuffle / shuffleMix. Lane reads from `_bits`
  // already use single wasm v128 lane-extract intrinsics, so no scratch is
  // needed for the simple element-wise operators.
  static final Int32List _list = Int32List(4);

  @pragma("wasm:entry-point")
  I32x4.fromV128(this._bits);

  factory I32x4(int x, int y, int z, int w) =>
      I32x4.fromV128(WasmI32x4.fromInts(x, y, z, w).value);

  factory I32x4.bool(bool x, bool y, bool z, bool w) => I32x4.fromV128(
    WasmI32x4.fromInts(x ? -1 : 0, y ? -1 : 0, z ? -1 : 0, w ? -1 : 0).value,
  );

  factory I32x4.fromFloat32x4Bits(Float32x4 f) =>
      I32x4.fromV128((f as F32x4)._bits);

  factory I32x4._truncated(int x, int y, int z, int w) =>
      I32x4.fromV128(WasmI32x4.fromInts(x, y, z, w).value);

  int get x => WasmI32x4(_bits).extractLane(0).toIntSigned();
  int get y => WasmI32x4(_bits).extractLane(1).toIntSigned();
  int get z => WasmI32x4(_bits).extractLane(2).toIntSigned();
  int get w => WasmI32x4(_bits).extractLane(3).toIntSigned();

  String toString() =>
      '[${_int32ToHex(x)}, ${_int32ToHex(y)}, '
      '${_int32ToHex(z)}, ${_int32ToHex(w)}]';

  Int32x4 operator |(Int32x4 other) =>
      I32x4.fromV128(_bits | (other as I32x4)._bits);
  Int32x4 operator &(Int32x4 other) =>
      I32x4.fromV128(_bits & (other as I32x4)._bits);
  Int32x4 operator ^(Int32x4 other) =>
      I32x4.fromV128(_bits ^ (other as I32x4)._bits);
  Int32x4 operator +(Int32x4 other) => I32x4.fromV128(
    (WasmI32x4(_bits) + WasmI32x4((other as I32x4)._bits)).value,
  );
  Int32x4 operator -(Int32x4 other) => I32x4.fromV128(
    (WasmI32x4(_bits) - WasmI32x4((other as I32x4)._bits)).value,
  );
  Int32x4 operator -() => I32x4.fromV128((-WasmI32x4(_bits)).value);

  int get signMask => WasmI32x4(_bits).bitmask.toIntUnsigned();

  Int32x4 shuffle(int mask) {
    // mask < 0 || mask > 255
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(mask, 255, 'mask');
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return I32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 shuffleMix(Int32x4 other, int mask) {
    // mask < 0 || mask > 255
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(mask, 255, 'mask');
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return I32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 withX(int x) =>
      I32x4.fromV128(WasmI32x4(_bits).replaceLane(0, WasmI32.fromInt(x)));

  Int32x4 withY(int y) =>
      I32x4.fromV128(WasmI32x4(_bits).replaceLane(1, WasmI32.fromInt(y)));

  Int32x4 withZ(int z) =>
      I32x4.fromV128(WasmI32x4(_bits).replaceLane(2, WasmI32.fromInt(z)));

  Int32x4 withW(int w) =>
      I32x4.fromV128(WasmI32x4(_bits).replaceLane(3, WasmI32.fromInt(w)));

  bool get flagX => x != 0;
  bool get flagY => y != 0;
  bool get flagZ => z != 0;
  bool get flagW => w != 0;

  Int32x4 withFlagX(bool flagX) => I32x4.fromV128(
    WasmI32x4(_bits).replaceLane(0, WasmI32.fromInt(flagX ? -1 : 0)),
  );

  Int32x4 withFlagY(bool flagY) => I32x4.fromV128(
    WasmI32x4(_bits).replaceLane(1, WasmI32.fromInt(flagY ? -1 : 0)),
  );

  Int32x4 withFlagZ(bool flagZ) => I32x4.fromV128(
    WasmI32x4(_bits).replaceLane(2, WasmI32.fromInt(flagZ ? -1 : 0)),
  );

  Int32x4 withFlagW(bool flagW) => I32x4.fromV128(
    WasmI32x4(_bits).replaceLane(3, WasmI32.fromInt(flagW ? -1 : 0)),
  );

  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue) => F32x4.fromV128(
    _bits.bitSelect((trueValue as F32x4)._bits, (falseValue as F32x4)._bits),
  );
}

/// Exposes the raw [WasmV128] backing an [I32x4] to the SIMD-backed
/// `Int32x4List`, which lives in a different library than [I32x4].
extension I32x4Ext on I32x4 {
  @pragma("wasm:prefer-inline")
  WasmV128 get bits => _bits;
}

String _int32ToHex(int i) => i.toRadixString(16).padLeft(8, '0');
