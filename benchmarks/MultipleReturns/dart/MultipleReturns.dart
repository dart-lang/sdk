// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

// Micro-benchmark for multiple returns.
//
// The goal of this benchmark is to compare and track performance of
// various ways to return multiple values from a method.

int input1 = int.parse('42');
String input2 = input1.toString();

const int N = 1000000;
final int expectedSum = (input1 + input2.length) * N;

class ResultClass {
  final int result0;
  final String result1;
  const ResultClass(this.result0, this.result1);
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
List<Object> inlinedList() => [input1, input2];

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
List<Object> notInlinedList() => [input1, input2];

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
List<Object> forwardedList() => notInlinedList();

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
ResultClass inlinedClass() => ResultClass(input1, input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
ResultClass notInlinedClass() => ResultClass(input1, input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
ResultClass forwardedClass() => notInlinedClass();

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
(int, String) inlinedRecord() => (input1, input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
(int, String) notInlinedRecord() => (input1, input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
(int, String) forwardedRecord() => notInlinedRecord();

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
({int result0, String result1}) inlinedRecordNamed() =>
    (result0: input1, result1: input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
({int result0, String result1}) notInlinedRecordNamed() =>
    (result0: input1, result1: input2);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
({int result0, String result1}) forwardedRecordNamed() =>
    notInlinedRecordNamed();

class BenchInlinedList extends BenchmarkBase {
  BenchInlinedList() : super('MultipleReturns.Inlined.List');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = inlinedList();
      final int r0 = result[0] as int;
      final String r1 = result[1] as String;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchNotInlinedList extends BenchmarkBase {
  BenchNotInlinedList() : super('MultipleReturns.NotInlined.List');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = notInlinedList();
      final int r0 = result[0] as int;
      final String r1 = result[1] as String;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchForwardedList extends BenchmarkBase {
  BenchForwardedList() : super('MultipleReturns.Forwarded.List');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = forwardedList();
      final int r0 = result[0] as int;
      final String r1 = result[1] as String;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchInlinedClass extends BenchmarkBase {
  BenchInlinedClass() : super('MultipleReturns.Inlined.Class');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = inlinedClass();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchNotInlinedClass extends BenchmarkBase {
  BenchNotInlinedClass() : super('MultipleReturns.NotInlined.Class');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = notInlinedClass();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchForwardedClass extends BenchmarkBase {
  BenchForwardedClass() : super('MultipleReturns.Forwarded.Class');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = forwardedClass();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchInlinedRecord extends BenchmarkBase {
  BenchInlinedRecord() : super('MultipleReturns.Inlined.Record');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = inlinedRecord();
      final int r0 = result.$1;
      final String r1 = result.$2;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchNotInlinedRecord extends BenchmarkBase {
  BenchNotInlinedRecord() : super('MultipleReturns.NotInlined.Record');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = notInlinedRecord();
      final int r0 = result.$1;
      final String r1 = result.$2;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchForwardedRecord extends BenchmarkBase {
  BenchForwardedRecord() : super('MultipleReturns.Forwarded.Record');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = forwardedRecord();
      final int r0 = result.$1;
      final String r1 = result.$2;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchInlinedRecordNamed extends BenchmarkBase {
  BenchInlinedRecordNamed() : super('MultipleReturns.Inlined.RecordNamed');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = inlinedRecordNamed();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchNotInlinedRecordNamed extends BenchmarkBase {
  BenchNotInlinedRecordNamed()
      : super('MultipleReturns.NotInlined.RecordNamed');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = notInlinedRecordNamed();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

class BenchForwardedRecordNamed extends BenchmarkBase {
  BenchForwardedRecordNamed() : super('MultipleReturns.Forwarded.RecordNamed');

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      final result = forwardedRecordNamed();
      final int r0 = result.result0;
      final String r1 = result.result1;
      sum += r0 + r1.length;
    }
    if (sum != expectedSum) throw 'Bad result: $sum';
  }
}

void main() {
  final benchmarks = [
    BenchInlinedList(),
    BenchInlinedClass(),
    BenchInlinedRecord(),
    BenchInlinedRecordNamed(),
    BenchNotInlinedList(),
    BenchNotInlinedClass(),
    BenchNotInlinedRecord(),
    BenchNotInlinedRecordNamed(),
    BenchForwardedList(),
    BenchForwardedClass(),
    BenchForwardedRecord(),
    BenchForwardedRecordNamed(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.warmup();
  }
  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
