// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmarks passing small and large integers to JS via `js_interop`.
//
// In Wasm, integers that fit into 31 bits can be passed without allocation by
// by passing them as `i31ref`. To take advantage of this, dart2wasm checks the
// size of the integer before passing to JS and passes the integer as `i31ref`
// when possible.
//
// This benchmark compares performance of `int` passing for integers that fit
// into 31 bits and those that don't.

import 'dart:js_interop';

import 'package:benchmark_harness/benchmark_harness.dart';

@JS()
external void eval(String code);

// This returns `void` to avoid adding `dartify` overheads to the benchmark
// results.
// V8 can't figure out this doesn't do anything so the loop and JS calls aren't
// eliminated.
@JS()
external void intId(int i);

// Run benchmarked code for at least 2 seconds.
const int minimumMeasureDurationMillis = 2000;

class IntPassingBenchmark {
  final int start;
  final int end;

  IntPassingBenchmark(this.start, this.end);

  double measure() =>
      BenchmarkBase.measureFor(() {
        for (int i = start; i < end; i += 1) {
          intId(i);
        }
      }, minimumMeasureDurationMillis) /
      (end - start);
}

void main() {
  eval('''
    self.intId = (i) => i;
    ''');

  final maxI31 = (1 << 30) - 1;

  final small = IntPassingBenchmark(maxI31 - 1000000, maxI31).measure();
  report('WasmJSInterop.call.void.1ArgsSmi', small);

  final large = IntPassingBenchmark(maxI31 + 1, maxI31 + 1000001).measure();
  report('WasmJSInterop.call.void.1ArgsInt', large);
}

/// Reports in Golem-specific format.
void report(String name, double nsPerCall) {
  print('$name(RunTimeRaw): $nsPerCall ns.');
}
