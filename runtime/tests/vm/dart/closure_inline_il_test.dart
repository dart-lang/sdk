// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that CallSiteInliner canonicalizes LoadField instructions on call
// arguments during inlining, forwarding closures stored in contexts so nested
// closure calls are inlined and all closure/context allocations are removed.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:prefer-inline')
int apply(int Function() f) => f();

@pragma('vm:prefer-inline')
int wrapAndApply(int Function(int) g, int v) => apply(() => g(v));

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testNestedClosureInlining(int x) {
  var y = x + 1;
  return wrapAndApply((int z) => y + z, 42);
}

void matchIL$testNestedClosureInlining(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'y' << match.BinaryInt64Op('x', match.any),
      'res' << match.BinaryInt64Op('y', match.any),
      match.DartReturn('res'),
    ]),
  ]);
}

void main() {
  Expect.equals(53, testNestedClosureInlining(10));
  Expect.equals(0x100000000 + 43, testNestedClosureInlining(0x100000000));
}
