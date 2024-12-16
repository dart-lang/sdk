// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

class IterationBenchmark extends BenchmarkBase {
 
  late final List<int> list = List.generate(1000, (i) => i); 
  int r = 0;
  
  void fn(int i) => r = 123 * i;
  IterationBenchmark(String name) : super(name);
}

class ForLoop extends IterationBenchmark {
  ForLoop() : super('ForLoop');

  @override
  void run() {
    for (final i in list) { 
      fn(i);
    }
  }
}

void main() {
  ForLoop().report();
}
