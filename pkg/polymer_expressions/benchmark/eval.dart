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

class EvalBenchmark extends BenchmarkBase {
  final expr;
  final scope;

  EvalBenchmark(String name, String expr, {Object model, Map variables})
      : expr = parse(expr),
        scope = new Scope(model: model, variables: variables),
        super('$name: $expr ');

  run() {
    var value = eval(expr, scope);
  }

}

double total = 0.0;

benchmark(String name, String expr, {Object model, Map variables}) {
  var score = new EvalBenchmark(name, expr, model: model, variables: variables)
      .measure();
  print("$name $expr: $score us");
  total += score;
}

main() {

  benchmark('Constant', '1');
  benchmark('Top-level Name', 'foo',
      variables: {'foo': new Foo(new Bar('hello'))});
  benchmark('Model field', 'bar',
      model: new Foo(new Bar('hello')));
  benchmark('Path', 'foo.bar.baz',
      variables: {'foo': new Foo(new Bar('hello'))});
  benchmark('Map', 'm["foo"]',
      variables: {'m': {'foo': 1}});
  benchmark('Equality', '"abc" == "123"');
  print('total: $total us');

}
