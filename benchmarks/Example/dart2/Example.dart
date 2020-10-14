// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:benchmark_harness/benchmark_harness.dart';

class Example extends BenchmarkBase {
  const Example() : super('Example');

  // The benchmark code.
  @override
  void run() {}

  // Not measured setup code executed prior to the benchmark runs.
  @override
  void setup() {}

  // Not measures teardown code executed after the benchark runs.
  @override
  void teardown() {}
}

void main() {
  const Example().report();
}
