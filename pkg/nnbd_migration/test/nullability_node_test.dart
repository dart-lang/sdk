// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullabilityNodeTest);
  });
}

@reflectiveTest
class NullabilityNodeTest {
  final graph = NullabilityGraphForTesting();

  /// A list of all edges that couldn't be satisfied.  May contain duplicates.
  List<NullabilityEdge> unsatisfiedEdges;

  List<NullabilityNodeForSubstitution> unsatisfiedSubstitutions;

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  void assertUnsatisfied(List<NullabilityEdge> expectedUnsatisfiedEdges) {
    expect(unsatisfiedEdges.toSet(), expectedUnsatisfiedEdges.toSet());
  }

  NullabilityEdge connect(NullabilityNode source, NullabilityNode destination,
      {bool hard = false,
      bool checkable = true,
      List<NullabilityNode> guards = const []}) {
    return graph.connect(source, destination, _TestEdgeOrigin(),
        hard: hard, checkable: checkable, guards: guards);
  }

  NullabilityNode lub(NullabilityNode left, NullabilityNode right) {
    return NullabilityNode.forLUB(left, right);
  }

  NullabilityNode newNode(int id) =>
      NullabilityNode.forTypeAnnotation(NullabilityNodeTarget.text('node $id'));

  void propagate() {
    var propagationResult = graph.propagate(null);
    unsatisfiedEdges = propagationResult.unsatisfiedEdges;
    unsatisfiedSubstitutions = propagationResult.unsatisfiedSubstitutions;
  }

  NullabilityNode subst(NullabilityNode inner, NullabilityNode outer) {
    return NullabilityNode.forSubstitution(inner, outer);
  }

  void test_always_and_never_state() {
    propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
    assertUnsatisfied([]);
  }

  void test_always_and_never_unaffected_by_hard_edges() {
    var edge = connect(always, never, hard: true);
    propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
    assertUnsatisfied([edge]);
  }

  void test_always_and_never_unaffected_by_soft_edges() {
    var edge = connect(always, never);
    propagate();
    expect(always.isNullable, isTrue);
    expect(never.isNullable, isFalse);
    assertUnsatisfied([edge]);
  }

  void test_always_destination() {
    // always -> 1 -(hard)-> always
    var n1 = newNode(1);
    connect(always, n1);
    connect(n1, always, hard: true);
    propagate();
    // Upstream propagation of non-nullability ignores edges terminating at
    // `always`, so n1 should be nullable.
    expect(n1.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_edge_satisfied_due_to_guard() {
    // always -> 1
    // 1 -(2) -> 3
    // 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n1, n3, guards: [n2]);
    connect(n3, never, hard: true);
    propagate();
    expect(n1.isNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, false);
    // Although n1 is nullable and n3 is non-nullable, the edge from 1 to 3 is
    // considered satisfied because the guard (n2) is non-nullable.
    assertUnsatisfied([]);
  }

  void test_lubNode_relatesInBothDirections() {
    final nodeA = newNode(1);
    final nodeB = newNode(2);
    final lubNode = lub(nodeA, nodeB);

    expect(nodeA.outerCompoundNodes, [lubNode]);
    expect(nodeB.outerCompoundNodes, [lubNode]);
  }

  void test_never_source() {
    // never -> 1
    var n1 = newNode(1);
    connect(never, n1);
    propagate();
    // Downstream propagation of nullability ignores edges originating at
    // `never`, so n1 should be non-nullable.
    expect(n1.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_always_union() {
    // always == 1
    // 1 -(hard)-> never
    // 1 -> 2
    // 1 -> 3
    // 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    union(always, n1);
    var edge_1_never = connect(n1, never, hard: true);
    connect(n1, n2);
    var edge_1_3 = connect(n1, n3);
    connect(n3, never, hard: true);
    propagate();
    // Union edges take precedence over hard ones, so n1 should be nullable.
    expect(n1.isNullable, true);
    // And nullability should be propagated to n2.
    expect(n2.isNullable, true);
    // But it should not be propagated to n3 because non-nullability propagation
    // takes precedence over ordinary nullability propagation.
    expect(n3.isNullable, false);
    assertUnsatisfied([edge_1_never, edge_1_3]);
  }

  void test_propagation_always_union_reversed() {
    // always == 1
    // 1 -(hard)-> never
    // 1 -> 2
    // 1 -> 3
    // 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    union(n1, always);
    var edge_1_never = connect(n1, never, hard: true);
    connect(n1, n2);
    var edge_1_3 = connect(n1, n3);
    connect(n3, never, hard: true);
    propagate();
    // Union edges take precedence over hard ones, so n1 should be nullable.
    expect(n1.isNullable, true);
    // And nullability should be propagated to n2.
    expect(n2.isNullable, true);
    // But it should not be propagated to n3 because non-nullability propagation
    // takes precedence over ordinary nullability propagation.
    expect(n3.isNullable, false);
    assertUnsatisfied([edge_1_never, edge_1_3]);
  }

  void test_propagation_downstream_breadth_first() {
    // always -> 1 -> 2
    //           1 -> 3 -> 4
    // always -> 5 -> 4
    //           5 -> 6 -> 2
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(4);
    var n5 = newNode(5);
    var n6 = newNode(6);
    connect(always, n1);
    connect(n1, n2);
    connect(n1, n3);
    connect(n3, n4);
    connect(always, n5);
    connect(n5, n4);
    connect(n5, n6);
    connect(n6, n2);
    propagate();
    // Node 2 should be caused by node 1, since that's the shortest path back to
    // "always".  Similarly, node 4 should be caused by node 5.
    expect(_downstreamCauseNode(n2), same(n1));
    expect(_downstreamCauseNode(n4), same(n5));
  }

  void test_propagation_downstream_guarded_multiple_guards_all_satisfied() {
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
    propagate();
    expect(n4.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_guarded_multiple_guards_not_all_satisfied() {
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
    propagate();
    expect(n4.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_guarded_satisfy_guard_first() {
    // always -> 1
    // always -> 2
    // 2 -(1)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(n2, n3, guards: [n1]);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_guarded_satisfy_source_first() {
    // always -> 1
    // always -> 2
    // 1 -(2)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(n1, n3, guards: [n2]);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_guarded_unsatisfied_guard() {
    // always -> 1
    // 1 -(2)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n1, n3, guards: [n2]);
    propagate();
    expect(n3.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_guarded_unsatisfied_source() {
    // always -> 1
    // 2 -(1)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(n2, n3, guards: [n1]);
    propagate();
    expect(n3.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_reverse_substitution_exact() {
    // always -> subst(1, 2)
    // 3 -(uncheckable)-> 1
    // 4 -(uncheckable)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(4);
    connect(always, subst(n1, n2));
    connect(n3, n1, checkable: false);
    connect(n4, n3, checkable: false);
    propagate();
    expect(n1.isNullable, true);
    expect(n1.isExactNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, true);
    expect(n3.isExactNullable, true);
    expect(n4.isNullable, true);
    expect(n4.isExactNullable, true);
  }

  void test_propagation_downstream_reverse_substitution_exact_checkable() {
    // always -> subst(1, 2)
    // 3 -(uncheckable)-> 1
    // 4 -(checkable)-> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(4);
    connect(always, subst(n1, n2));
    connect(n3, n1, checkable: false);
    connect(n4, n3, checkable: true);
    propagate();
    expect(n1.isNullable, true);
    expect(n1.isExactNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, true);
    expect(n3.isExactNullable, true);
    expect(n4.isNullable, false);
    expect(n4.isExactNullable, false);
  }

  void test_propagation_downstream_reverse_substitution_inner_non_nullable() {
    // 1 -> never (hard)
    // always -> subst(1, 2)
    // 3 -> 2
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(n1, never, hard: true);
    connect(always, subst(n1, n2));
    connect(n3, n2);
    propagate();
    expect(n1.isNullable, false);
    expect(n2.isNullable, true);
    expect(n2.isExactNullable, false);
    expect(n3.isNullable, false);
  }

  void test_propagation_downstream_reverse_substitution_non_null_intent() {
    // always -> subst(1, 2)
    // 3 -(uncheckable)-> 1
    // 4 -(checkable)-> 3
    // 4 -(hard) -> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(4);
    connect(always, subst(n1, n2));
    connect(n3, n1, checkable: false);
    connect(n4, n3, checkable: false);
    connect(n4, never, hard: true);
    propagate();
    expect(n1.isNullable, true);
    expect(n1.isExactNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, true);
    expect(n3.isExactNullable, true);
    expect(n4.isNullable, false);
    expect(n4.isExactNullable, false);
  }

  void
      test_propagation_downstream_reverse_substitution_outer_already_nullable() {
    // always -> 2
    // always -> subst(1, 2)
    // 3 -> 2
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n2);
    connect(always, subst(n1, n2));
    connect(n3, n2);
    propagate();
    expect(n1.isNullable, false);
    expect(n2.isNullable, true);
    expect(n2.isExactNullable, false);
    expect(n3.isNullable, false);
  }

  void test_propagation_downstream_reverse_substitution_unsatisfiable() {
    // 1 -> never (hard)
    // 2 -> never (hard)
    // always -> subst(1, 2)
    var n1 = newNode(1);
    var n2 = newNode(2);
    connect(n1, never, hard: true);
    connect(n2, never, hard: true);
    var substitutionNode = subst(n1, n2);
    connect(always, substitutionNode);
    propagate();
    expect(n1.isNullable, false);
    expect(n2.isNullable, false);
    expect(substitutionNode.isNullable, false);
    expect(unsatisfiedSubstitutions, isEmpty);
  }

  void test_propagation_downstream_through_lub_both() {
    // always -> 1
    // always -> 2
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(lub(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_lub_cascaded() {
    // always -> 1
    // LUB(LUB(1, 2), 3) -> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(lub(lub(n1, n2), n3), n4);
    propagate();
    expect(n4.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_lub_left() {
    // always -> 1
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(lub(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_lub_neither() {
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(lub(n1, n2), n3);
    propagate();
    expect(n3.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_lub_right() {
    // always -> 2
    // LUB(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n2);
    connect(lub(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_substitution_both() {
    // always -> 1
    // always -> 2
    // subst(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(always, n2);
    connect(subst(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_substitution_cascaded() {
    // always -> 1
    // subst(subst(1, 2), 3) -> 4
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(3);
    connect(always, n1);
    connect(subst(subst(n1, n2), n3), n4);
    propagate();
    expect(n4.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_substitution_inner() {
    // always -> 1
    // subst(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    connect(subst(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_substitution_neither() {
    // subst(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(subst(n1, n2), n3);
    propagate();
    expect(n3.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_substitution_outer() {
    // always -> 2
    // subst(1, 2) -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n2);
    connect(subst(n1, n2), n3);
    propagate();
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_union() {
    // always -> 1
    // 1 == 2
    // 2 -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    union(n1, n2);
    connect(n2, n3);
    propagate();
    expect(n1.isNullable, true);
    expect(n2.isNullable, true);
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_downstream_through_union_reversed() {
    // always -> 1
    // 2 == 1
    // 2 -> 3
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    union(n2, n1);
    connect(n2, n3);
    propagate();
    expect(n1.isNullable, true);
    expect(n2.isNullable, true);
    expect(n3.isNullable, true);
    assertUnsatisfied([]);
  }

  void test_propagation_simple() {
    // always -(soft)-> 1 -(soft)-> 2 -(hard) -> 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    connect(always, n1);
    var edge_1_2 = connect(n1, n2);
    connect(n2, n3, hard: true);
    connect(n3, never, hard: true);
    propagate();
    expect(n1.isNullable, true);
    expect(n2.isNullable, false);
    expect(n3.isNullable, false);
    assertUnsatisfied([edge_1_2]);
  }

  void test_propagation_upstream_breadth_first() {
    // never <- 1 <- 2
    //          1 <- 3 <- 4
    // never <- 5 <- 4
    //          5 <- 6 <- 2
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var n4 = newNode(4);
    var n5 = newNode(5);
    var n6 = newNode(6);
    connect(n1, never, hard: true);
    connect(n2, n1, hard: true);
    connect(n3, n1, hard: true);
    connect(n4, n3, hard: true);
    connect(n5, never, hard: true);
    connect(n4, n5, hard: true);
    connect(n6, n5, hard: true);
    connect(n2, n6, hard: true);
    propagate();
    // Node 2 should be caused by node 1, since that's the shortest path back to
    // "always".  Similarly, node 4 should be caused by node 5.
    expect(_upstreamCauseNode(n2), same(n1));
    expect(_upstreamCauseNode(n4), same(n5));
  }

  void test_propagation_upstream_through_union() {
    // always -> 1
    // always -> 2
    // always -> 3
    // 1 -(hard)-> 2
    // 2 == 3
    // 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var edge_always_1 = connect(always, n1);
    var edge_always_2 = connect(always, n2);
    var edge_always_3 = connect(always, n3);
    connect(n1, n2, hard: true);
    union(n2, n3);
    connect(n3, never, hard: true);
    propagate();
    expect(n1.isNullable, false);
    expect(n2.isNullable, false);
    expect(n3.isNullable, false);
    assertUnsatisfied([edge_always_1, edge_always_2, edge_always_3]);
  }

  void test_propagation_upstream_through_union_reversed() {
    // always -> 1
    // always -> 2
    // always -> 3
    // 1 -(hard)-> 2
    // 3 == 2
    // 3 -(hard)-> never
    var n1 = newNode(1);
    var n2 = newNode(2);
    var n3 = newNode(3);
    var edge_always_1 = connect(always, n1);
    var edge_always_2 = connect(always, n2);
    var edge_always_3 = connect(always, n3);
    connect(n1, n2, hard: true);
    union(n3, n2);
    connect(n3, never, hard: true);
    propagate();
    expect(n1.isNullable, false);
    expect(n2.isNullable, false);
    expect(n3.isNullable, false);
    assertUnsatisfied([edge_always_1, edge_always_2, edge_always_3]);
  }

  void test_satisfied_edge_destination_nullable() {
    var n1 = newNode(1);
    var edge = connect(always, n1);
    propagate();
    assertUnsatisfied([]);
    expect(edge.isSatisfied, true);
  }

  void test_satisfied_edge_source_non_nullable() {
    var n1 = newNode(1);
    var n2 = newNode(1);
    var edge = connect(n1, n2);
    propagate();
    assertUnsatisfied([]);
    expect(edge.isSatisfied, true);
  }

  void test_satisfied_edge_two_sources_first_non_nullable() {
    var n1 = newNode(1);
    var n2 = newNode(1);
    connect(always, n2);
    var edge = connect(n1, never, guards: [n2]);
    propagate();
    assertUnsatisfied([]);
    expect(edge.isSatisfied, true);
  }

  void test_satisfied_edge_two_sources_second_non_nullable() {
    var n1 = newNode(1);
    var n2 = newNode(1);
    connect(always, n1);
    var edge = connect(n1, never, guards: [n2]);
    propagate();
    assertUnsatisfied([]);
    expect(edge.isSatisfied, true);
  }

  void test_substitution_simplify_null() {
    var n1 = newNode(1);
    expect(subst(null, n1), same(n1));
    expect(subst(n1, null), same(n1));
  }

  void test_substitutionNode_relatesInBothDirections() {
    final nodeA = newNode(1);
    final nodeB = newNode(2);
    final substNode = subst(nodeA, nodeB);

    expect(nodeA.outerCompoundNodes, [substNode]);
    expect(nodeB.outerCompoundNodes, [substNode]);
  }

  void test_unconstrainted_node_non_nullable() {
    var n1 = newNode(1);
    propagate();
    expect(n1.isNullable, false);
    assertUnsatisfied([]);
  }

  void test_unsatisfied_edge_multiple_sources() {
    var n1 = newNode(1);
    connect(always, n1);
    var edge = connect(always, never, guards: [n1]);
    propagate();
    assertUnsatisfied([edge]);
    expect(edge.isSatisfied, false);
  }

  void test_unsatisfied_edge_single_source() {
    var edge = connect(always, never);
    propagate();
    assertUnsatisfied([edge]);
    expect(edge.isSatisfied, false);
  }

  void union(NullabilityNode x, NullabilityNode y) {
    graph.union(x, y, _TestEdgeOrigin());
  }

  NullabilityNode _downstreamCauseNode(NullabilityNode node) =>
      (node.whyNullable as SimpleDownstreamPropagationStep).edge.sourceNode;

  NullabilityNode _upstreamCauseNode(NullabilityNode node) =>
      node.whyNotNullable.principalCause.node;
}

class _TestEdgeOrigin implements EdgeOrigin {
  @override
  CodeReference get codeReference => null;

  @override
  String get description => 'Test edge';

  @override
  EdgeOriginKind get kind => null;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
