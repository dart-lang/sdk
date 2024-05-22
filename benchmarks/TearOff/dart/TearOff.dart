// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

// Micro-benchmark for taking tear-off of instance method multiple
// times and in a loop.

class BenchTearOffInlined extends BenchmarkBase {
  BenchTearOffInlined() : super('TearOff.Inlined');

  int sum = 0;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void foo(int arg) {
    sum += arg;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void callIt(void Function(int) func, int arg) {
    func(arg);
  }

  @override
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void run() {
    sum = 0;
    callIt(foo, 1);
    callIt(foo, 2);
    callIt(foo, 3);
    callIt(foo, 4);
    callIt(foo, 5);
    for (int i = 11; i < 20; ++i) {
      callIt(foo, i);
    }
    callIt(foo, 6);
    callIt(foo, 7);
    callIt(foo, 8);
    callIt(foo, 9);
    callIt(foo, 10);

    const int expectedSum = 20 * (20 - 1) ~/ 2;
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchTearOffInlinedInTry extends BenchmarkBase {
  BenchTearOffInlinedInTry() : super('TearOff.Inlined.InTry');

  int sum = 0;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void foo(int arg) {
    sum += arg;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void callIt(void Function(int) func, int arg) {
    func(arg);
  }

  @override
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void run() {
    sum = 0;
    try {
      callIt(foo, 1);
      callIt(foo, 2);
      callIt(foo, 3);
      callIt(foo, 4);
      callIt(foo, 5);
      for (int i = 11; i < 20; ++i) {
        callIt(foo, i);
      }
      callIt(foo, 6);
      callIt(foo, 7);
      callIt(foo, 8);
      callIt(foo, 9);
      callIt(foo, 10);
    } finally {
      const int expectedSum = 20 * (20 - 1) ~/ 2;
      sum -= expectedSum;
    }
    if (sum != 0) throw 'Bad result: $sum';
  }
}

class BenchTearOffNotInlined extends BenchmarkBase {
  BenchTearOffNotInlined() : super('TearOff.NotInlined');

  int sum = 0;

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void foo(int arg) {
    sum += arg;
  }

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void callIt(void Function(int) func, int arg) {
    func(arg);
  }

  @override
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void run() {
    sum = 0;
    callIt(foo, 1);
    callIt(foo, 2);
    callIt(foo, 3);
    callIt(foo, 4);
    callIt(foo, 5);
    for (int i = 11; i < 20; ++i) {
      callIt(foo, i);
    }
    callIt(foo, 6);
    callIt(foo, 7);
    callIt(foo, 8);
    callIt(foo, 9);
    callIt(foo, 10);

    const int expectedSum = 20 * (20 - 1) ~/ 2;
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchTearOffNotInlinedInTry extends BenchmarkBase {
  BenchTearOffNotInlinedInTry() : super('TearOff.NotInlined.InTry');

  int sum = 0;

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void foo(int arg) {
    sum += arg;
  }

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void callIt(void Function(int) func, int arg) {
    func(arg);
  }

  @override
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  void run() {
    sum = 0;
    try {
      callIt(foo, 1);
      callIt(foo, 2);
      callIt(foo, 3);
      callIt(foo, 4);
      callIt(foo, 5);
      for (int i = 11; i < 20; ++i) {
        callIt(foo, i);
      }
      callIt(foo, 6);
      callIt(foo, 7);
      callIt(foo, 8);
      callIt(foo, 9);
      callIt(foo, 10);
    } finally {
      const int expectedSum = 20 * (20 - 1) ~/ 2;
      sum -= expectedSum;
    }
    if (sum != 0) throw 'Bad result: $sum';
  }
}

void main() {
  final benchmarks = [
    BenchTearOffInlined(),
    BenchTearOffInlinedInTry(),
    BenchTearOffNotInlined(),
    BenchTearOffNotInlinedInTry(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.warmup();
  }
  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
