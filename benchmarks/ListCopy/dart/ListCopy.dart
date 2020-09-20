// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';
import 'package:benchmark_harness/benchmark_harness.dart';

// Benchmark for polymorphic list copying.
//
// Each benchmark creates a list from an Iterable. There are many slightly
// different ways to do this.
//
// In each benchmark the call site is polymorphic in the input type to simulate
// the behaviour of library methods in the context of a large application. The
// input lists are skewed heavily to the default growable list. This attempts to
// model 'real world' copying of 'ordinary' lists.
//
// The benchmarks are run for small lists (2 elements, names ending in
// `.2`) and 'large' lists (100 elements or `.100`). The benchmarks are
// normalized on the number of elements to make the input sizes comparable.
//
// Most inputs have type `Iterable<num>`, but contain only `int` values. This
// allows is to compare the down-conversion versions of copying where each
// element must be checked.

class Benchmark extends BenchmarkBase {
  final int length;
  final Function() copy;

  final List<Iterable<num>> inputs = [];

  Benchmark(String name, this.length, this.copy)
      : super('ListCopy.$name.$length');

  @override
  void setup() {
    // Ensure setup() is idempotent.
    if (inputs.isNotEmpty) return;
    final List<num> base = List.generate(length, (i) => i + 1);
    List<Iterable<num>> makeVariants() {
      return [
        // Weight ordinary lists more.
        ...List.generate(19, (_) => List<num>.of(base)),

        base.toList(growable: false),
        List<num>.unmodifiable(base),
        UnmodifiableListView(base),
        base.reversed,
        String.fromCharCodes(List<int>.from(base)).codeUnits,
        Uint8List.fromList(List<int>.from(base)),
      ];
    }

    const elements = 10000;
    int totalLength = 0;
    while (totalLength < elements) {
      final variants = makeVariants();
      inputs.addAll(variants);
      totalLength +=
          variants.fold<int>(0, (sum, iterable) => sum + iterable.length);
    }

    // Sanity checks.
    for (var sample in inputs) {
      if (sample.length != length) throw 'Wrong length: $length $sample';
    }
    if (totalLength != elements) {
      throw 'totalLength $totalLength != expected $elements';
    }
  }

  @override
  void run() {
    for (var sample in inputs) {
      input = sample;
      // Unroll loop 10 times to reduce loop overhead, which is about 15% for
      // the fastest short input benchmarks.
      copy();
      copy();
      copy();
      copy();
      copy();
      copy();
      copy();
      copy();
      copy();
      copy();
    }
    if (output.length != inputs.first.length) throw 'Bad result: $output';
  }
}

// All the 'copy' methods use [input] and [output] rather than a parameter and
// return value to avoid any possibility of type check in the call sequence.
Iterable<num> input = const [];
var output;

List<Benchmark> makeBenchmarks(int length) => [
      Benchmark('toList', length, () {
        output = input.toList();
      }),
      Benchmark('toList.fixed', length, () {
        output = input.toList(growable: false);
      }),
      Benchmark('List.of', length, () {
        output = List<num>.of(input);
      }),
      Benchmark('List.of.fixed', length, () {
        output = List<num>.of(input, growable: false);
      }),
      Benchmark('List.num.from', length, () {
        output = List<num>.from(input);
      }),
      Benchmark('List.int.from', length, () {
        output = List<int>.from(input);
      }),
      Benchmark('List.num.from.fixed', length, () {
        output = List<num>.from(input, growable: false);
      }),
      Benchmark('List.int.from.fixed', length, () {
        output = List<int>.from(input, growable: false);
      }),
      Benchmark('List.num.unmodifiable', length, () {
        output = List<num>.unmodifiable(input);
      }),
      Benchmark('List.int.unmodifiable', length, () {
        output = List<int>.unmodifiable(input);
      }),
      Benchmark('spread.num', length, () {
        output = <num>[...input];
      }),
      Benchmark('spread.int', length, () {
        output = <int>[...input as dynamic];
      }),
      Benchmark('spread.int.cast', length, () {
        output = <int>[...input.cast<int>()];
      }),
      Benchmark('spread.int.map', length, () {
        output = <int>[...input.map((x) => x as int)];
      }),
      Benchmark('for.int', length, () {
        output = <int>[for (var n in input) n as int];
      }),
    ];

void main() {
  final benchmarks = [...makeBenchmarks(2), ...makeBenchmarks(100)];

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (var benchmark in benchmarks) {
    benchmark.setup();
  }

  for (var benchmark in benchmarks) {
    benchmark.warmup();
  }

  for (var benchmark in benchmarks) {
    // `report` calls `setup`, but `setup` is idempotent.
    benchmark.report();
  }
}
