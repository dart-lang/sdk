// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";
import "dart:typed_data";

import "package:expect/expect.dart";

// This test tests check null for Simd Operations

final rng = Random();

// Returns null
@pragma('vm:never-inline')
Float64x2 f() {
  var v = rng.nextInt(1000000000) + 100;

  // Ensures that v is not a perfect number
  while (v == 496 || v == 8128 || v == 33550336) {
    v = rng.nextInt(1000000000) + 100;
  }

  // Checks if v is a perfect number
  var sum = 0;
  for (var i = 1; i * i <= v; i++) {
    if (v % i == 0) {
      sum += i;
      if (i * i != v) {
        sum += v ~/ i;
      }
    }
  }

  if (sum == v) {
    // Always false
    return Float64x2(sum.toDouble(), 10.0);
  }

  return null;
}

main() {
  closure1() {
    final a = Float64x2(0.0, 1.0);
    final b = f();
    return a - b;
  }

  closure2() {
    final a = f() == null ? Float64x2(0.0, 1.0) : null;
    final b = f();
    final c = b / a;
    return c + a;
  }

  closure3() {
    final a = f();
    final b = f();
    return a * b;
  }

  closure4() {
    final a = Float64x2(0.0, 1.0);
    final b = Float64x2(2.0, 4.0);
    return b - a;
  }

  Expect.throwsArgumentError(closure1);
  Expect.throwsNoSuchMethodError(closure2);
  Expect.throwsNoSuchMethodError(closure3);
  final r = closure4();
  Expect.equals(r.x, 2.0);
  Expect.equals(r.y, 3.0);
}
