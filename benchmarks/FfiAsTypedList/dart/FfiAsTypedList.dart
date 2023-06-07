// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmark for creating TypeData lists from Pointers.
//
// The FfiMemory benchmark tests accessing memory through TypedData.

import 'dart:ffi';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ffi/ffi.dart';

//
// Benchmark fixture.
//

// Number of repeats: 1000
const N = 1000;

class FromPointerInt8 extends BenchmarkBase {
  Pointer<Int8> pointer = nullptr;
  FromPointerInt8() : super('FfiAsTypedList.FromPointerInt8');

  @override
  void setup() => pointer = calloc(1);
  @override
  void teardown() => calloc.free(pointer);

  @override
  void run() {
    for (var i = 0; i < N; i++) {
      pointer.asTypedList(1);
    }
  }
}

//
// Main driver.
//

void main(List<String> args) {
  final benchmarks = [
    FromPointerInt8.new,
  ];

  final filter = args.firstOrNull;
  for (var constructor in benchmarks) {
    final benchmark = constructor();
    if (filter == null || benchmark.name.contains(filter)) {
      benchmark.report();
    }
  }
}
