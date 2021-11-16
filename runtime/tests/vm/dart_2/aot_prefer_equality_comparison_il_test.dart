// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit EqualityCompare rather than StrictCompare+BoxInt64
// when comparing non-nullable integer to a Smi.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int factorial(int value) => value == 1 ? value : value * factorial(value - 1);

void matchIL$factorial(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.Branch(match.EqualityCompare(match.any, match.any, kind: '==')),
    ]),
  ]);
}

void main() {
  print(factorial(4));
}
