// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Measures SIMD values held in instance fields.
//
// Each type has a field variant and a local variant over identical work.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

const int iterations = 100000;

class F32x4Holder {
  Float32x4 v = Float32x4.zero();
}

class I32x4Holder {
  Int32x4 v = Int32x4(0, 0, 0, 0);
}

class F64x2Holder {
  Float64x2 v = Float64x2.zero();
}

abstract class FieldBench extends BenchmarkBase {
  FieldBench(String name) : super('SimdFields.$name');
}

class F32x4Field extends FieldBench {
  F32x4Field() : super('f32x4Field');
  final h = F32x4Holder();
  final d = Float32x4(1.0, 1.0, 1.0, 1.0);
  @override
  void run() {
    final holder = h;
    final delta = d;
    for (int i = 0; i < iterations; i++) {
      holder.v = holder.v + delta;
    }
  }
}

class F32x4Local extends FieldBench {
  F32x4Local() : super('f32x4Local');
  final d = Float32x4(1.0, 1.0, 1.0, 1.0);
  @override
  void run() {
    final delta = d;
    var v = Float32x4.zero();
    for (int i = 0; i < iterations; i++) {
      v = v + delta;
    }
    if (v.x < 0.0) throw StateError('unreachable');
  }
}

class I32x4Field extends FieldBench {
  I32x4Field() : super('i32x4Field');
  final h = I32x4Holder();
  final d = Int32x4(1, 1, 1, 1);
  @override
  void run() {
    final holder = h;
    final delta = d;
    for (int i = 0; i < iterations; i++) {
      holder.v = holder.v + delta;
    }
  }
}

class I32x4Local extends FieldBench {
  I32x4Local() : super('i32x4Local');
  final d = Int32x4(1, 1, 1, 1);
  @override
  void run() {
    final delta = d;
    var v = Int32x4(0, 0, 0, 0);
    for (int i = 0; i < iterations; i++) {
      v = v + delta;
    }
    if (v.x == 0x7fffffff) throw StateError('unreachable');
  }
}

class F64x2Field extends FieldBench {
  F64x2Field() : super('f64x2Field');
  final h = F64x2Holder();
  final d = Float64x2(1.0, 1.0);
  @override
  void run() {
    final holder = h;
    final delta = d;
    for (int i = 0; i < iterations; i++) {
      holder.v = holder.v + delta;
    }
  }
}

class F64x2Local extends FieldBench {
  F64x2Local() : super('f64x2Local');
  final d = Float64x2(1.0, 1.0);
  @override
  void run() {
    final delta = d;
    var v = Float64x2.zero();
    for (int i = 0; i < iterations; i++) {
      v = v + delta;
    }
    if (v.x < 0.0) throw StateError('unreachable');
  }
}

void main() {
  const benchmarks = [
    F32x4Field.new,
    F32x4Local.new,
    I32x4Field.new,
    I32x4Local.new,
    F64x2Field.new,
    F64x2Local.new,
  ];

  for (final bm in benchmarks) {
    bm()
      ..setup()
      ..run()
      ..run();
  }

  for (final bm in benchmarks) {
    bm().report();
  }
}
