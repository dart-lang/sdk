// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.benchmark.eval;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:polymer_expressions/parser.dart' show parse;
import 'package:polymer_expressions/eval.dart' show eval, Scope;

class Foo {
  final Bar bar;
  Foo(this.bar);
}

class Bar {
  String baz;
  Bar(this.baz);
}

/**
 * Measures eval time of several expressions. Parsing time is not included.
 */
class PolymerEvalBenchmark extends BenchmarkBase {
  PolymerEvalBenchmark() : super('PolymerEvalBenchmark');

  final expr = parse('foo.bar.baz');
  final expr2 = parse('(1 + 2) * 3');
  final scope = new Scope(variables: {'foo': new Foo(new Bar('hello'))});

  run() {
    var value = eval(expr, scope);
    if (value != 'hello') throw new StateError(value);
    value = eval(expr2, scope);
    if (value != 9) throw new StateError(value);
  }
}

main() {
  new PolymerEvalBenchmark().report();
}
