// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.benchmark.parse;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:polymer_expressions/parser.dart' show parse;

/**
 * Measures pure parsing time of several expressions
 */
class PolymerParseBenchmark extends BenchmarkBase {
  PolymerParseBenchmark() : super('PolymerParseBenchmark');

  run() {
    parse('foo.bar.baz');
    parse('f()');
    parse('(1 + 2) * 3');
    parse('1 + 2.0 + false + "abcdefg" + {"a": 1}');
    parse('(a * (b * (c * (d * (e)))))');
    parse('a(b(c(d(e(f)))))');
  }
}

main() {
  new PolymerParseBenchmark().report();
}
