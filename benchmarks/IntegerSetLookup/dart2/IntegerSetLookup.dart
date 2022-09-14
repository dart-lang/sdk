// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmark for https://github.com/dart-lang/sdk/issues/48641.
//
// Measures the average time needed for a lookup in Sets of integers.

// @dart=2.9

import 'dart:math';
import 'dart:collection';
import 'package:benchmark_harness/benchmark_harness.dart';

class SetBenchmark extends BenchmarkBase {
  SetBenchmark(String name, this.mySet) : super(name);

  final Set<int> mySet;

  @override
  void run() {
    mySet.contains(123456789);
  }
}

void main() {
  final list = [
    for (int i = 0; i < 14790; i++) (i + 1) * 0x10000000 + 123456789
  ];

  final r = Random();
  final randomList = List<int>.generate(14790, (_) => r.nextInt(1 << 31));

  final benchmarks = [
    () => SetBenchmark("IntegerSetLookup.DefaultHashSet", {...list}),
    () =>
        SetBenchmark("IntegerSetLookup.HashSet", HashSet<int>()..addAll(list)),
    () =>
        SetBenchmark("IntegerSetLookup.DefaultHashSet_Random", {...randomList}),
    () => SetBenchmark(
        "IntegerSetLookup.HashSet_Random", HashSet<int>()..addAll(randomList)),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
