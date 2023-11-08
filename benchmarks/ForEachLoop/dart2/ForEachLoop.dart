// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:benchmark_harness/benchmark_harness.dart';

class IterationBenchmark extends BenchmarkBase {
  List<int> list = List.generate(1000, (i) => i);
  var r = 0;
  void fn(int i) => r = 123 * i;
  IterationBenchmark(name) : super(name);
}

class ForEach extends IterationBenchmark {
  ForEach() : super('ForEachLoop');

  @override
  void run() {
    list.forEach(fn);
  }
}

void main() {
  ForEach().report();
}
