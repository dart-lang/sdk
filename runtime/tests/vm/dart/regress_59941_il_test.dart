// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that calling a method which returns Never breaks control flow.
// Regression test for https://github.com/dart-lang/sdk/issues/59941.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void myprint(Object o) {
  print(o);
}

@pragma('vm:never-inline')
Never bar() {
  throw 'baz';
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int foo(bool condition, int arg) {
  int i = arg;
  if (condition) {
    i = 2;
    bar(); // <-- Return type `Never`, so it always throws and can never fall through.
  }
  return i;
}

main() {
  Expect.equals(42, foo(false, 42));
  Expect.equals(43, foo(false, 43));
  Expect.throws(() {
    foo(true, 44);
  });
}

void matchIL$foo(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'condition' << match.Parameter(index: 0),
      'arg' << match.Parameter(index: 1),
      match.CheckStackOverflow(),
      match.Branch(
        match.StrictCompare('condition', match.any, kind: '==='),
        ifTrue: 'B3',
        ifFalse: 'B4',
      ),
    ]),
    'B3' << match.block('Target', [match.StaticCall(), match.Stop()]),
    'B4' << match.block('Target', [match.DartReturn('arg')]),
  ]);
}
