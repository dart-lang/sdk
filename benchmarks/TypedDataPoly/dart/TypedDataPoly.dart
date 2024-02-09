// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

// Benchmark for polymorphic typed_data List access.
//
// The set of benchmarks compares the cost of reading typed data lists, mostly
// different kinds of [Uint8List] - plain [Uint8List]s, [Uint8List]s that are
// views of another [Uint8List], and unmodifiable views of these.
//
// The benchmarks do not try to use external [Uint8List]s, since this is does
// not easily translate to the web.
//
// Each benchmark sums the contents of a `List<int>`. The benchmarks report the
// per-element time. Benchmarks vary by the degree of polymorphism, the kinds of
// typed_data List used, and the length of the List.
//
// The goal of an implementation would be to make as many of the benchmarks as
// possible report a similar time to `TypedDataPoly.mono.array.N`.

/// A convenience for initializing the lists.
extension on List<int> {
  void setToOnes() {
    for (int i = 0; i < length; i++) {
      this[i] = 1;
    }
  }
}

/// Results pass through this global variable to ensure the result is used and
/// so defeat optimizations based on side-effect free computations that have an
/// unused result.
int g = 0;

class Base extends BenchmarkBase {
  final int n;
  Base(String name, this.n) : super('$name.$n');

  @override
  void report() {
    final double millisecondsPerExercise = measure();
    // Report time in nanoseconds per element. [exercise] runs [run] 10 times,
    // and each [run] does 10 summations.
    final double score = millisecondsPerExercise * 1000.0 / n / 10.0 / 10.0;
    print('$name(RunTime): $score ns.');
  }

  void check() {
    if (g != n * 10) throw StateError('n = $n, g = $g');
  }
}

/// Benchmark where the `sum` method is called only with the basic [Uint8List]
/// implementation. This represents the best-case performance.
class Monomorphic extends Base {
  final Uint8List data1;
  Monomorphic(int n)
      : data1 = Uint8List(n)..setToOnes(),
        super('TypedDataPoly.mono.array', n);

  /// An identical [sum] method appears in each benchmark so the compiler
  /// can specialize the method according to different sets of input
  /// implementation types.
  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  /// Each [run] method calls [sum] ten times.
  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    check();
  }
}

/// [Baseline] is modelled after [Monomorphic], but does almost no work in
/// `sum`.  This measures the cost of benchmark code outside of `sum`.
class Baseline extends Base {
  final Uint8List data1;
  Baseline(int n)
      : data1 = Uint8List(n)..setToOnes(),
        super('TypedDataPoly.baseline', n);

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    return list.length;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    g += sum(data1);
    check();
  }
}

/// [Polymorphic1] calls `sum` with a flat allocated `Uint8List`(`A`) and a view
/// of part of a longer list (`V`).
class Polymorphic1 extends Base {
  final List<int> data1;
  final List<int> data2;
  Polymorphic1._(int n, String variant, this.data1, this.data2)
      : super('TypedDataPoly.A_V.$variant', n);

  factory Polymorphic1(int n, String variant) {
    final data1 = Uint8List(n)..setToOnes();
    final data2 = Uint8List.sublistView(Uint8List(n + 1)..setToOnes(), 1);
    if (variant == 'array') return Polymorphic1._(n, variant, data1, data1);
    if (variant == 'view') return Polymorphic1._(n, variant, data2, data2);
    throw UnimplementedError('No variant "$variant"');
  }

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    check();
  }
}

/// [Polymorphic2] calls `sum` with a flat allocated [Uint8List] and an
/// unmodifiable view of the same list. This mildly polymorphic, so
/// there is the possibility that `sum` runs slower than [Monomorphic.sum].
///
/// The workload can be varied:
///
///  - `view` measures the cost of accessing the unmodifiable view.
///
///  - `array` measures the cost of accessing a simple [Uint8List] using the
///     same code that can also access an unmodifiable view of a [Uint8List].
class Polymorphic2 extends Base {
  final List<int> data1;
  final List<int> data2;
  Polymorphic2._(int n, String variant, this.data1, this.data2)
      : super('TypedDataPoly.A_UV.$variant', n);

  factory Polymorphic2(int n, String variant) {
    final data1 = Uint8List(n)..setToOnes();
    final data2 = data1.asUnmodifiableView();
    if (variant == 'array') return Polymorphic2._(n, variant, data1, data1);
    if (variant == 'view') return Polymorphic2._(n, variant, data2, data2);
    throw UnimplementedError('No variant "$variant"');
  }

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    check();
  }
}

/// [Polymorphic3] is similar to [Polymorphic2], but the 'other' list is an
/// unmodifiable view of a modifiable view.
class Polymorphic3 extends Base {
  final List<int> data1;
  final List<int> data2;
  Polymorphic3._(int n, String variant, this.data1, this.data2)
      : super('TypedDataPoly.A_VUV.$variant', n);
  factory Polymorphic3(int n, String variant) {
    final data1 = Uint8List(n)..setToOnes();
    final view1 = Uint8List.sublistView(Uint8List(n + 1)..setToOnes(), 1);
    final data2 = view1.asUnmodifiableView();
    if (variant == 'array') return Polymorphic3._(n, variant, data1, data1);
    if (variant == 'view') return Polymorphic3._(n, variant, data2, data2);
    throw UnimplementedError('No variant "$variant"');
  }

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    check();
  }
}

/// [Polymorphic4] stacks unmodifiable views five levels deep.
class Polymorphic4 extends Base {
  final List<int> data1;
  final List<int> data2;
  Polymorphic4._(int n, String variant, this.data1, this.data2)
      : super('TypedDataPoly.A_UVx5.$variant', n);

  factory Polymorphic4(int n, String variant) {
    final data1 = Uint8List(n)..setToOnes();
    var data2 = data1.asUnmodifiableView();
    data2 = data2.asUnmodifiableView();
    data2 = data2.asUnmodifiableView();
    data2 = data2.asUnmodifiableView();
    data2 = data2.asUnmodifiableView();
    if (variant == 'array') return Polymorphic4._(n, variant, data1, data1);
    if (variant == 'view') return Polymorphic4._(n, variant, data2, data2);
    throw UnimplementedError('No variant "$variant"');
  }

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    g += sum(data1);
    g += sum(data2);
    check();
  }
}

/// Massively polymorphic version with 10 kinds of typed data lists and
/// unmodifiable views.
class Polymorphic5 extends Base {
  final List<int> data1;
  final List<int> data2;
  final List<int> data3;
  final List<int> data4;
  final List<int> data5;
  final List<int> data6;
  final List<int> data7;
  final List<int> data8;
  final List<int> data9;
  final List<int> data10;
  Polymorphic5._(
      int n,
      String variant,
      this.data1,
      this.data2,
      this.data3,
      this.data4,
      this.data5,
      this.data6,
      this.data7,
      this.data8,
      this.data9,
      this.data10)
      : super('TypedDataPoly.mega.$variant', n);

  factory Polymorphic5(int n, String variant) {
    final data1 = Uint8List(n)..setToOnes();
    final data2 = Uint16List(n)..setToOnes();
    final data3 = Uint32List(n)..setToOnes();
    final data4 = Int8List(n)..setToOnes();
    final data5 = Int16List(n)..setToOnes();

    final data6 = data1.asUnmodifiableView();
    final data7 = data2.asUnmodifiableView();
    final data8 = data3.asUnmodifiableView();
    final data9 = data4.asUnmodifiableView();
    final data10 = data5.asUnmodifiableView();

    if (variant == 'array') {
      return Polymorphic5._(n, variant, data1, data1, data1, data1, data1,
          data1, data1, data1, data1, data1);
    }
    if (variant == 'mixed') {
      return Polymorphic5._(n, variant, data1, data2, data3, data4, data5,
          data6, data7, data8, data9, data10);
    }
    throw UnimplementedError('No variant "$variant"');
  }

  @pragma('vm:never-inline')
  @pragma('dart2js:never-inline')
  static int sum(List<int> list) {
    var s = 0;
    for (int i = 0; i < list.length; i++) {
      s += list[i];
    }
    return s;
  }

  @override
  void run() {
    g = 0;
    g += sum(data1);
    g += sum(data2);
    g += sum(data3);
    g += sum(data4);
    g += sum(data5);
    g += sum(data6);
    g += sum(data7);
    g += sum(data8);
    g += sum(data9);
    g += sum(data10);
    check();
  }
}

/// Command-line arguments:
///
/// `--baseline`: Run additional benchmarks to measure the benchmarking loop
/// component.
///
/// `--1`: Run additional benchmarks for singleton lists.
///
/// `--all`: Run all benchmark variants and sizes.
///
void main(List<String> commandLineArguments) {
  final arguments = [...commandLineArguments];

  final Set<int> sizes = {2, 100};

  bool baseline = arguments.remove('--baseline');

  if (arguments.remove('--reset')) {
    sizes.clear();
  }

  if (arguments.remove('--1')) sizes.add(1);
  if (arguments.remove('--2')) sizes.add(2);
  if (arguments.remove('--100')) sizes.add(100);

  final all = arguments.remove('--all');

  if (all) {
    baseline = true;
    sizes.addAll([1, 2, 100]);
  }

  if (arguments.isNotEmpty) {
    throw ArgumentError('Unused command line arguments: $arguments');
  }

  if (sizes.isEmpty) sizes.add(2);

  final benchmarks = [
    for (final length in sizes) ...[
      if (baseline) Baseline(length),
      //
      Monomorphic(length),
      //
      Polymorphic1(length, 'array'),
      Polymorphic1(length, 'view'),
      //
      Polymorphic2(length, 'array'),
      Polymorphic2(length, 'view'),
      //
      Polymorphic3(length, 'array'),
      Polymorphic3(length, 'view'),
      //
      Polymorphic4(length, 'array'),
      Polymorphic4(length, 'view'),
      //
      Polymorphic5(length, 'array'),
      Polymorphic5(length, 'mixed')
    ]
  ];

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (var benchmark in benchmarks) {
    benchmark.setup();
  }

  for (var benchmark in benchmarks) {
    benchmark.warmup();
  }

  for (var benchmark in benchmarks) {
    benchmark.report();
  }
}
