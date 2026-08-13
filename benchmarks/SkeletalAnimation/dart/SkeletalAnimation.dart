// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A Dart implementation of two computation kernels used for skeletal
/// animation.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_math/vector_math_operations.dart';

void main() {
  SkeletalAnimation().report();
}

class SkeletalAnimation extends BenchmarkBase {
  SkeletalAnimation() : super('SkeletalAnimation');

  final Float32List A = Float32List(16);
  final Float32List B = Float32List(16);
  final Float32List C = Float32List(16);
  final Float32List D = Float32List(4);
  final Float32List E = Float32List(4);

  @override
  void run() {
    for (int i = 0; i < 100; i++) {
      Matrix44Operations.multiply(C, 0, A, 0, B, 0);
      Matrix44Operations.transform4(E, 0, A, 0, D, 0);
    }
  }
}
