// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

// Micro-benchmark for subtype tests against record types.
//
// A record has no class or type arguments to key a SubtypeTestCache on, so
// every check here enters the runtime, unlike the SubtypeTestCache suite.
// Lanes vary by field count, which separates the cost of entering the runtime
// from the per-field work. See dart-lang/sdk#61970.

const int checksPerRun = 1000;

void main() {
  const CheckRecord1().report();
  const CheckRecord2().report();
  const CheckRecord3().report();
  const CheckRecord4().report();
}

abstract class CheckBenchmarkBase extends BenchmarkBase {
  const CheckBenchmarkBase(String name) : super('RecordSubtypeTest.$name');

  // Normalized by check count, as the SubtypeTestCache suite does.
  @override
  void report() => emitter.emit(name, measure() / checksPerRun);
}

class CheckRecord1 extends CheckBenchmarkBase {
  const CheckRecord1() : super('Record1');

  @override
  void run() {
    for (int i = 0; i < checksPerRun; i++) {
      checkRecord1<int>(record1);
    }
  }
}

class CheckRecord2 extends CheckBenchmarkBase {
  const CheckRecord2() : super('Record2');

  @override
  void run() {
    for (int i = 0; i < checksPerRun; i++) {
      checkRecord2<int>(record2);
    }
  }
}

class CheckRecord3 extends CheckBenchmarkBase {
  const CheckRecord3() : super('Record3');

  @override
  void run() {
    for (int i = 0; i < checksPerRun; i++) {
      checkRecord3<int>(record3);
    }
  }
}

class CheckRecord4 extends CheckBenchmarkBase {
  const CheckRecord4() : super('Record4');

  @override
  void run() {
    for (int i = 0; i < checksPerRun; i++) {
      checkRecord4<int>(record4);
    }
  }
}

// Never inlined, so the loops cannot hoist the check out.

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
void checkRecord1<S>(dynamic s) => s as (S,);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
void checkRecord2<S>(dynamic s) => s as (S, S);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
void checkRecord3<S>(dynamic s) => s as (S, S, S);

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
void checkRecord4<S>(dynamic s) => s as (S, S, S, S);

final dynamic record1 = (1,);
final dynamic record2 = (1, 2);
final dynamic record3 = (1, 2, 3);
final dynamic record4 = (1, 2, 3, 4);
