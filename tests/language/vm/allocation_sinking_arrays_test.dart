// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=100 --deterministic

// Tests allocation sinking of arrays and typed data objects.

import 'dart:typed_data';
import 'package:expect/expect.dart';

import 'dart:typed_data';

class Vector2 {
  final Float64List _v2storage;

  @pragma('vm:prefer-inline')
  Vector2.zero() : _v2storage = Float64List(2);

  @pragma('vm:prefer-inline')
  factory Vector2(double x, double y) => Vector2.zero()..setValues(x, y);

  @pragma('vm:prefer-inline')
  factory Vector2.copy(Vector2 other) => Vector2.zero()..setFrom(other);

  @pragma('vm:prefer-inline')
  Vector2 clone() => Vector2.copy(this);

  @pragma('vm:prefer-inline')
  void setValues(double x_, double y_) {
    _v2storage[0] = x_;
    _v2storage[1] = y_;
  }

  @pragma('vm:prefer-inline')
  void setFrom(Vector2 other) {
    final otherStorage = other._v2storage;
    _v2storage[1] = otherStorage[1];
    _v2storage[0] = otherStorage[0];
  }

  @pragma('vm:prefer-inline')
  Vector2 operator +(Vector2 other) => clone()..add(other);

  @pragma('vm:prefer-inline')
  void add(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v2storage[0] = _v2storage[0] + argStorage[0];
    _v2storage[1] = _v2storage[1] + argStorage[1];
  }

  @pragma('vm:prefer-inline')
  double get x => _v2storage[0];

  @pragma('vm:prefer-inline')
  double get y => _v2storage[1];
}

@pragma('vm:never-inline')
String foo(double x, num doDeopt) {
  // All allocations in this function are eliminated by the compiler,
  // except array allocation for string interpolation at the end.
  List v1 = List.filled(2, null);
  v1[0] = 1;
  v1[1] = 'hi';
  Vector2 v2 = new Vector2(1.0, 2.0);
  Vector2 v3 = v2 + Vector2(x, x);
  double sum = v3.x + v3.y;
  // Deoptimization is triggered here to materialize removed allocations.
  doDeopt + 2;
  return "v1: [${v1[0]},${v1[1]}], v2: [${v2.x},${v2.y}], v3: [${v3.x},${v3.y}], sum: $sum";
}

main() {
  // Due to '--optimization-counter-threshold=100 --deterministic'
  // foo() is optimized during the first 100 iterations.
  // After that, on iteration 120 deoptimization is triggered by changed
  // type of 'doDeopt'. That forces materialization of all objects which
  // allocations were removed by optimizer.
  for (int i = 0; i < 130; ++i) {
    final num doDeopt = (i < 120 ? 1 : 2.0);
    final result = foo(3.0, doDeopt);
    Expect.equals("v1: [1,hi], v2: [1.0,2.0], v3: [4.0,5.0], sum: 9.0", result);
  }
}
