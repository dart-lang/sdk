// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that deeply-immutable runtme type check is omitted when types
// are statically known.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:deeply-immutable')
final class FunctionFoo {
  final void Function(int) baz;
  FunctionFoo(this.baz);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
runtime_check_is_present() {
  final ff = FunctionFoo((int x) {
    print(x);
  });
  ff.baz(42);
}

@pragma('vm:deeply-immutable')
final class IntFoo {
  final int baz;
  IntFoo(this.baz);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
runtime_check_is_omitted() {
  IntFoo(42);
}

void main() {
  runtime_check_is_present();
  runtime_check_is_omitted();
}

bool hasCheckFieldImmutability(FlowGraph graph) {
  return containsInstruction(graph, const {'CheckFieldImmutability'});
}

void matchIL$runtime_check_is_present(FlowGraph graph) {
  Expect.isTrue(
    hasCheckFieldImmutability(graph),
    "should have immutability checks",
  );
}

void matchIL$runtime_check_is_omitted(FlowGraph graph) {
  Expect.isFalse(
    hasCheckFieldImmutability(graph),
    "should not have immutability checks",
  );
}
