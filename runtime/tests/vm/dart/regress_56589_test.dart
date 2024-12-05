// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1 --deterministic

import 'dart:core';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  print(float32x4); // Force init.
  print(lowerLimit); // Force init.
  print(zero); // Force init.

  final resultA = regress56589A();
  final resultB = regress56589B();

  print(resultA);
  final resultAAsInt = Int32x4.fromFloat32x4Bits(resultA);
  print(resultAAsInt);
  print(resultB);
  final resultBAsInt = Int32x4.fromFloat32x4Bits(resultB);
  print(resultBAsInt);
  Expect.equals(resultAAsInt.x, resultBAsInt.x);
  Expect.equals(resultAAsInt.y, resultBAsInt.y);
  Expect.equals(resultAAsInt.z, resultBAsInt.z);
  Expect.equals(resultAAsInt.w, resultBAsInt.w);
}

final float32x4 = Float32x4(-0.0, 0.0, -0.0, 0.0);
final lowerLimit = Float32x4(-1.0, -1.0, -0.0, -0.0);
final zero = Float32x4.zero();

// Uses machine code on hardware or simulator.
Float32x4 regress56589A() {
  final result = float32x4.clamp(
    lowerLimit,
    zero,
  );
  return result;
}

// Uses the RTE.
Float32x4 regress56589B() {
  // Some code which forces using the RTE with the VMOptions above.
  someExtraCall(someOtherExtraCall());

  final result = float32x4.clamp(
    lowerLimit,
    zero,
  );
  return result;
}

void someExtraCall(Object? o) {}

Foo someOtherExtraCall() {
  return Foo();
}

class Foo {}
