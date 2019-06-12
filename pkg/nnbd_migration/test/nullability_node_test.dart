// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullabilityNodeTest);
  });
}

@reflectiveTest
class NullabilityNodeTest {
  final graph = NullabilityGraph();

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  void connect(NullabilityNode source, NullabilityNode destination,
      {bool hard = false, List<NullabilityNode> guards = const []}) {
    graph.connect(source, destination, hard: hard, guards: guards);
  }

  NullabilityNode lub(NullabilityNode left, NullabilityNode right) {
    return NullabilityNode.forLUB(left, right);
  }

  NullabilityNode newNode(int offset) =>
      NullabilityNode.forTypeAnnotation(offset);

  NullabilityNode subst(NullabilityNode inner, NullabilityNode outer) {
    return NullabilityNode.forSubstitution(inner, outer);
  }

  test_always_and_never_state() {
    graph.propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
  }

  test_always_and_never_unaffected_by_hard_edges() {
    connect(always, never, hard: true);
    graph.propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
  }

  test_always_and_never_unaffected_by_soft_edges() {
    connect(always, never);
    graph.propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
  }

  test_always_destination() {
    // always -> 1 -(hard)-> always
    var n1 = newNode(1);
    connect(always, n1);
    connect(n1, always, hard: true);
    graph.propagate();
    // Upstream propagation of non-nullability ignores edges terminating at
    // `always`, so n1 should be nullable.
    expect(n1.isNullable, true);
  }

  test_never_source() {
    // never -> 1
    var n1 = newNode(1);
    connect(never, n1);
    graph.propagate();
    // Downstream propagation of nullability ignores edges originating at
    // `never`, so n1 should be non-nullable.
    expect(n1.isNullable, false);
  }

  test_propagation_downstream_guarded_multiple_guards_all_satisfied() {
    // always -> 1
    // always -> 2
    // always -> 3
    // 1 -(2,3)-> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(always, n3);
    connect(n1, n4, guards: [n2, n3]);
    graph.propagate();
    expect(n4.isNullable, true);
  }

  test_propagation_downstream_guarded_multiple_guards_not_all_satisfied() {
    // always -> 1
    // always -> 2
    // 1 -(2,3)-> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(n1, n4, guards: [n2, n3]);
    graph.propagate();
    expect(n4.isNullable, false);
  }

  test_propagation_downstream_guarded_satisfy_guard_first() {
    // always -> 1
    // always -> 2
    // 2 -(1)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(n2, n3, guards: [n1]);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_guarded_satisfy_source_first() {
    // always -> 1
    // always -> 2
    // 1 -(2)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(n1, n3, guards: [n2]);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_guarded_unsatisfied_guard() {
    // always -> 1
    // 1 -(2)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n1, n3, guards: [n2]);
    graph.propagate();
    expect(n3.isNullable, false);
  }

  test_propagation_downstream_guarded_unsatisfied_source() {
    // always -> 1
    // 2 -(1)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n2, n3, guards: [n1]);
    graph.propagate();
    expect(n3.isNullable, false);
  }

  test_propagation_downstream_through_lub_both() {
    // always -> 1
    // always -> 2
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(lub(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_through_lub_cascaded() {
    // always -> 1
    // LUB(LUB(1, 2), 3) -> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(lub(lub(n1, n2), n3), n4);
    graph.propagate();
    expect(n4.isNullable, true);
  }

  test_propagation_downstream_through_lub_left() {
    // always -> 1
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(lub(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_through_lub_neither() {
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(lub(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, false);
  }

  test_propagation_downstream_through_lub_right() {
    // always -> 2
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n2);
    connect(lub(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_through_substitution_both() {
    // always -> 1
    // always -> 2
    // subst(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(subst(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_through_substitution_cascaded() {
    // always -> 1
    // LUB(LUB(1, 2), 3) -> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(subst(subst(n1, n2), n3), n4);
    graph.propagate();
    expect(n4.isNullable, true);
  }

  test_propagation_downstream_through_substitution_inner() {
    // always -> 1
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(subst(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_downstream_through_substitution_neither() {
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(subst(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, false);
  }

  test_propagation_downstream_through_substitution_outer() {
    // always -> 2
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n2);
    connect(subst(n1, n2), n3);
    graph.propagate();
    expect(n3.isNullable, true);
  }

  test_propagation_simple() {
    // always -(soft)-> 1 -(soft)-> 2 -(hard) -> 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n1, n2);
    connect(n2, n3, hard: true);
    connect(n3, never, hard: true);
    graph.propagate();
    expect(n1.isNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, false);
  }

  test_unconstrainted_node_non_nullable() {
    var n1 = newNode(1);
    graph.propagate();
    expect(n1.isNullable, false);
  }
}
