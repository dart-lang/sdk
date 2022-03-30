// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart'
    show PrintEmitter, ScoreEmitter;

// Similar to BenchmarkBase from package:benchmark_harness.
class AsyncBenchmarkBase {
  final String name;
  final ScoreEmitter emitter;

  // Empty constructor.
  const AsyncBenchmarkBase(this.name, {this.emitter = const PrintEmitter()});

  // The benchmark code.
  // This function is not used, if both [warmup] and [exercise] are overwritten.
  Future<void> run() async {}

  // Runs a short version of the benchmark. By default invokes [run] once.
  Future<void> warmup() async {
    await run();
  }

  // Exercises the benchmark. By default invokes [run] 10 times.
  Future<void> exercise() async {
    for (var i = 0; i < 10; i++) {
      await run();
    }
  }

  // Not measured setup code executed prior to the benchmark runs.
  Future<void> setup() async {}

  // Not measures teardown code executed after the benchark runs.
  Future<void> teardown() async {}

  // Measures the score for this benchmark by executing it repeatedly until
  // time minimum has been reached.
  static Future<double> measureFor(Function f, int minimumMillis) async {
    final int minimumMicros = minimumMillis * 1000;
    int iter = 0;
    final watch = Stopwatch();
    watch.start();
    int elapsed = 0;
    while (elapsed < minimumMicros) {
      await f();
      elapsed = watch.elapsedMicroseconds;
      iter++;
    }
    return elapsed / iter;
  }

  // Measures the score for the benchmark and returns it.
  Future<double> measure() async {
    await setup();
    // Warmup for at least 100ms. Discard result.
    await measureFor(warmup, 100);
    // Run the benchmark for at least 2000ms.
    final result = await measureFor(exercise, 2000);
    await teardown();
    return result;
  }

  Future<void> report() async {
    emitter.emit(name, await measure());
  }
}
