// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can eliminate record allocation.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:prefer-inline')
(int, bool) createRecord1(int x, bool y) => (x, y);

@pragma('vm:prefer-inline')
({String foo, bool bar, int baz}) createRecord2(
        String foo, bool bar, int baz) =>
    (foo: foo, bar: bar, baz: baz);

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void test(int x, bool y, String foo, bool bar, int baz) {
  final r1 = createRecord1(x, y);
  print(r1.$1);
  print(r1.$2);
  final r2 = createRecord2(foo, bar, baz);
  print(r2.foo);
  print(r2.baz);
}

void matchIL$test(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'y' << match.Parameter(index: 1),
      'foo' << match.Parameter(index: 2),
      'bar' << match.Parameter(index: 3),
      'baz' << match.Parameter(index: 4),
      match.CheckStackOverflow(),
      'x_boxed' << match.BoxInt64('x'),
      match.MoveArgument('x_boxed'),
      match.StaticCall(),
      match.MoveArgument('y'),
      match.StaticCall(),
      'baz_boxed' << match.BoxInt64('baz'),
      match.MoveArgument('foo'),
      match.StaticCall(),
      match.MoveArgument('baz_boxed'),
      match.StaticCall(),
      match.DartReturn(),
    ]),
  ]);
}

void main(List<String> args) {
  // Make sure all parameters are non-constant.
  test(args.length + 5, int.parse('3') == 3, 'foo' + 3.toString(),
      int.parse('3') == 4, args.length + 7);
}
