// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A Dart implementation of two computation kernels used for skeletal
/// animation. SIMD version.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_math/vector_math_operations.dart';

void main() {
  SkeletalAnimationSIMD().report();
}

class SkeletalAnimationSIMD extends BenchmarkBase {
  SkeletalAnimationSIMD() : super('SkeletalAnimationSIMD');

  final Float32x4List A = Float32x4List(4);
  final Float32x4List B = Float32x4List(4);
  final Float32x4List C = Float32x4List(4);
  final Float32x4List D = Float32x4List(1);
  final Float32x4List E = Float32x4List(1);

  @override
  void run() {
    for (int i = 0; i < 100; i++) {
      Matrix44SIMDOperations.multiply(C, 0, A, 0, B, 0);
      Matrix44SIMDOperations.transform4(E, 0, A, 0, D, 0);
    }
  }
}
