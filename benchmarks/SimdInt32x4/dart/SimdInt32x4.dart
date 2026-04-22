// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression benchmark for https://github.com/dart-lang/sdk/issues/63217 and
// https://github.com/dart-lang/sdk/issues/53662: the five binary operators on
// Int32x4 (+, -, |, &, ^) were not specialized in AOT mode, so `Int32x4List`
// loops fell back to boxed runtime calls that ran 10-70x slower than the
// hand-written scalar version or than the JIT.
//
// For every operator there is a scalar variant and a SIMD variant over the
// same Uint32List buffer, so the benchmark suite exposes both the absolute
// cost of each SIMD op and its speedup over the scalar baseline.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

const int words = 2048;

abstract class SimdBench extends BenchmarkBase {
  SimdBench(String name) : super('SimdInt32x4.$name');

  late final Uint32List a;
  late final Uint32List b;

  @override
  void setup() {
    a = Uint32List(words);
    b = Uint32List(words);
    for (int i = 0; i < words; i++) {
      a[i] = 0xA5A5A5A5 ^ i;
      b[i] = 0x5A5A5A5A ^ (i * 31);
    }
  }
}

class OrScalar extends SimdBench {
  OrScalar() : super('orScalar');
  @override
  void run() {
    final n = a.length;
    for (int i = 0; i < n; i++) {
      a[i] |= b[i];
    }
  }
}

class OrSimd extends SimdBench {
  OrSimd() : super('orSimd');
  @override
  void run() {
    final la = Int32x4List.view(a.buffer, a.offsetInBytes, a.length >> 2);
    final lb = Int32x4List.view(b.buffer, b.offsetInBytes, b.length >> 2);
    for (int j = 0; j < la.length; j++) {
      la[j] = la[j] | lb[j];
    }
  }
}

class AndScalar extends SimdBench {
  AndScalar() : super('andScalar');
  @override
  void run() {
    final n = a.length;
    for (int i = 0; i < n; i++) {
      a[i] &= b[i];
    }
  }
}

class AndSimd extends SimdBench {
  AndSimd() : super('andSimd');
  @override
  void run() {
    final la = Int32x4List.view(a.buffer, a.offsetInBytes, a.length >> 2);
    final lb = Int32x4List.view(b.buffer, b.offsetInBytes, b.length >> 2);
    for (int j = 0; j < la.length; j++) {
      la[j] = la[j] & lb[j];
    }
  }
}

class XorScalar extends SimdBench {
  XorScalar() : super('xorScalar');
  @override
  void run() {
    final n = a.length;
    for (int i = 0; i < n; i++) {
      a[i] ^= b[i];
    }
  }
}

class XorSimd extends SimdBench {
  XorSimd() : super('xorSimd');
  @override
  void run() {
    final la = Int32x4List.view(a.buffer, a.offsetInBytes, a.length >> 2);
    final lb = Int32x4List.view(b.buffer, b.offsetInBytes, b.length >> 2);
    for (int j = 0; j < la.length; j++) {
      la[j] = la[j] ^ lb[j];
    }
  }
}

class AddScalar extends SimdBench {
  AddScalar() : super('addScalar');
  @override
  void run() {
    final n = a.length;
    for (int i = 0; i < n; i++) {
      a[i] = a[i] + b[i];
    }
  }
}

class AddSimd extends SimdBench {
  AddSimd() : super('addSimd');
  @override
  void run() {
    final la = Int32x4List.view(a.buffer, a.offsetInBytes, a.length >> 2);
    final lb = Int32x4List.view(b.buffer, b.offsetInBytes, b.length >> 2);
    for (int j = 0; j < la.length; j++) {
      la[j] = la[j] + lb[j];
    }
  }
}

class SubScalar extends SimdBench {
  SubScalar() : super('subScalar');
  @override
  void run() {
    final n = a.length;
    for (int i = 0; i < n; i++) {
      a[i] = a[i] - b[i];
    }
  }
}

class SubSimd extends SimdBench {
  SubSimd() : super('subSimd');
  @override
  void run() {
    final la = Int32x4List.view(a.buffer, a.offsetInBytes, a.length >> 2);
    final lb = Int32x4List.view(b.buffer, b.offsetInBytes, b.length >> 2);
    for (int j = 0; j < la.length; j++) {
      la[j] = la[j] - lb[j];
    }
  }
}

void main() {
  final benchmarks = <BenchmarkBase Function()>[
    OrScalar.new,
    OrSimd.new,
    AndScalar.new,
    AndSimd.new,
    XorScalar.new,
    XorSimd.new,
    AddScalar.new,
    AddSimd.new,
    SubScalar.new,
    SubSimd.new,
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
