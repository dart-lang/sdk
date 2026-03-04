// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'package:expect/expect.dart';

// ignore: import_internal_library
import 'dart:_wasm';
import 'dart:math' as math;

// Flutter has an OffsetBase class that's extended by Offset and Size
// Let's implement those using f64x2 as the storage

abstract final class OffsetBase {
  final WasmF64x2 _storage;

  const OffsetBase(this._storage);

  double get _dx => _storage.extractLane(0).toDouble();
  double get _dy => _storage.extractLane(1).toDouble();

  bool get isInfinite => _dx.isInfinite || _dy.isInfinite;

  bool get isFinite => _dx.isFinite && _dy.isFinite;

  bool operator <(OffsetBase other) => _storage.lt(other._storage).allTrue;

  bool operator <=(OffsetBase other) => _storage.le(other._storage).allTrue;

  bool operator >(OffsetBase other) => _storage.gt(other._storage).allTrue;

  bool operator >=(OffsetBase other) => _storage.ge(other._storage).allTrue;

  @override
  int get hashCode => Object.hash(_dx, _dy);
}

final class Offset extends OffsetBase {
  const Offset(super.storage);

  factory Offset.from(double dx, double dy) {
    return Offset(WasmF64x2.fromLaneValues(dx.toWasmF64(), dy.toWasmF64()));
  }

  @override
  bool operator ==(Object other) {
    return other is Offset && other._storage.eq(_storage).allTrue;
  }

  double get dx => _dx;
  double get dy => _dy;

  Offset operator +(Offset other) => Offset(_storage + other._storage);

  Offset operator -(Offset other) => Offset(_storage - other._storage);

  Offset operator *(double operand) =>
      Offset(_storage * WasmF64x2.splat(operand.toWasmF64()));

  Offset operator /(double operand) =>
      Offset(_storage / WasmF64x2.splat(operand.toWasmF64()));

  double get distance => _distanceSquaredWasm.sqrt().toDouble();

  double get distanceSquared => _distanceSquaredWasm.toDouble();

  WasmF64 get _distanceSquaredWasm {
    final squares = _storage * _storage;
    return (squares + squares.shuffle(squares, const [1, 0])).extractLane(0);
  }

  double get direction => math.atan2(_dy, _dx);

  Offset scale(double scaleX, double scaleY) => Offset(
    _storage * WasmF64x2.fromLaneValues(scaleX.toWasmF64(), scaleY.toWasmF64()),
  );

  Offset translate(double translateX, double translateY) => Offset(
    _storage +
        WasmF64x2.fromLaneValues(
          translateX.toWasmF64(),
          translateY.toWasmF64(),
        ),
  );

  Offset operator -() => Offset(-_storage);

  static Offset? lerp(Offset? a, Offset? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b! * t;
    if (b == null) return a * (1.0 - t);
    return Offset(
      (a._storage * WasmF64x2.splat((1.0 - t).toWasmF64())) +
          (b._storage * WasmF64x2.splat(t.toWasmF64())),
    );
  }

  @override
  String toString() =>
      'Offset(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

final class Size extends OffsetBase {
  const Size._(super.storage);

  factory Size(double width, double height) {
    return Size._(
      WasmF64x2.fromLaneValues(width.toWasmF64(), height.toWasmF64()),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Size && other._storage.eq(_storage).allTrue;
  }

  static Size copy(Size source) => Size(source.width, source.height);

  static Size square(double dimension) => Size(dimension, dimension);

  static Size get zero => Size._(_zeroF64x2);

  double get width => _dx;
  double get height => _dy;

  bool get isEmpty => _storage.le(_zeroF64x2).anyTrue;

  double get aspectRatio {
    var swapped = _storage.shuffle(_storage, const [1, 0]); // [h, w]
    var div = _storage / swapped; // [w/h, h/w]
    var mask = swapped.eq(_zeroF64x2); // [h==0, w==0]
    // Select 0.0 if mask is true (h==0), else div.
    var res = WasmF64x2(mask.bitSelect(_zeroF64x2, div));
    return res.extractLane(0).toDouble();
  }

  double get shortestSide => _storage
      .pmin(_storage.shuffle(_storage, const [1, 0]))
      .extractLane(0)
      .toDouble();

  double get longestSide => _storage
      .pmax(_storage.shuffle(_storage, const [1, 0]))
      .extractLane(0)
      .toDouble();

  Size get center =>
      Size._(_storage * WasmF64x2.splat(WasmF64.fromDouble(0.5)));

  bool contains(Offset offset) {
    return WasmI64x2(
      offset._storage.ge(_zeroF64x2) & offset._storage.lt(_storage),
    ).allTrue;
  }

  @override
  String toString() =>
      'Size(${width.toStringAsFixed(1)}, ${height.toStringAsFixed(1)})';
}

void main() {
  final off1 = Offset.from(10.0, 20.0);
  final off2 = Offset.from(5.0, 5.0);

  print('Offset1: $off1');
  print('Offset2: $off2');

  final sum = off1 + off2;
  print('Sum: $sum');
  Expect.equals(15.0, sum.dx);
  Expect.equals(25.0, sum.dy);

  final sub = off1 - off2;
  print('Sub: $sub');
  Expect.equals(5.0, sub.dx);
  Expect.equals(15.0, sub.dy);

  final scaled = off1 * 2.0;
  print('Scaled: $scaled');
  Expect.equals(20.0, scaled.dx);
  Expect.equals(40.0, scaled.dy);

  final div = off1 / 2.0;
  print('Div: $div');
  Expect.equals(5.0, div.dx);
  Expect.equals(10.0, div.dy);

  // New Offset validations
  Expect.isTrue(off1 > off2);
  Expect.isFalse(off1 < off2);
  Expect.isTrue(sum == Offset.from(15.0, 25.0));
  Expect.isTrue(Offset.from(3.0, 4.0).distance == 5.0);
  Expect.equals(Offset.from(10.0, 0.0).direction, 0.0);
  Expect.equals(Offset.from(0.0, 10.0).direction, math.pi / 2);

  final size = Size(100.0, 200.0);
  print('Size: $size');
  Expect.equals(100.0, size.width);
  Expect.equals(200.0, size.height);
  Expect.isFalse(size.isEmpty);
  Expect.equals(0.5, size.aspectRatio);
  Expect.equals(100.0, size.shortestSide);
  Expect.equals(200.0, size.longestSide);
  Expect.isTrue(size.contains(Offset.from(50.0, 50.0)));
  Expect.isFalse(size.contains(Offset.from(150.0, 50.0)));
  Expect.equals(size.center, Size(50.0, 100.0));

  // Test valid aspectRatio
  Expect.equals(0.5, size.aspectRatio);

  // Test zero height aspectRatio
  final zeroHeight = Size(100.0, 0.0);
  Expect.equals(0.0, zeroHeight.aspectRatio);

  // Test zero width aspectRatio (should be infinite, though unrelated to height check logic)
  final zeroWidth = Size(0.0, 100.0);
  Expect.equals(0.0, zeroWidth.aspectRatio); // 0.0 / 100.0 = 0.0
}

WasmF64x2 get _zeroF64x2 => WasmF64x2.splat(WasmF64.fromDouble(0.0));
