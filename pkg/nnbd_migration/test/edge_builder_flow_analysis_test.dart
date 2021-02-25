// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EdgeBuilderFlowAnalysisTest);
  });
}

@reflectiveTest
class EdgeBuilderFlowAnalysisTest extends EdgeBuilderTestBase {
  Future<void> test_as() async {
    await analyze('''
void f(num n) {
  h(n);
  n as int;
  g(n);
}
void g(int i) {}
void h(num m) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var nNode = decoratedTypeAnnotation('num n').node;
    var mNode = decoratedTypeAnnotation('num m').node;
    // No edge from n to i because n is known to be non-nullable at the site of
    // the call to g
    assertNoEdge(nNode, iNode);
    // But there is an edge from n to m.
    assertEdge(nNode, mNode, hard: true);
  }

  Future<void> test_assert_initializer_condition_promotes_to_message() async {
    await analyze('''
class C {
  C(int i)
      : assert(i == null, g(i)) {
    h(i);
  }
}
String g(int j) => 'foo';
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i is known to be non-nullable at the site of
    // the call to g
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k.
    assertEdge(iNode, kNode, hard: true);
  }

  Future<void> test_assert_initializer_does_not_promote_beyond_assert() async {
    await analyze('''
class C {
  C(int i)
      : assert(i != null) {
    g(i);
    if (i == null) return;
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // There is an edge from i to j because i not promoted by the assert.
    assertEdge(iNode, jNode, hard: true);
    // But there is no edge from i to k.
    assertNoEdge(iNode, kNode);
  }

  Future<void> test_assert_statement_condition_promotes_to_message() async {
    await analyze('''
void f(int i) {
  assert(i == null, g(i));
  h(i);
}
String g(int j) => 'foo';
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i is known to be non-nullable at the site of
    // the call to g
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k.
    assertEdge(iNode, kNode, hard: true);
  }

  Future<void> test_assert_statement_does_not_promote_beyond_assert() async {
    await analyze('''
void f(int i) {
  assert(i != null);
  g(i);
  if (i == null) return;
  h(i);
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // There is an edge from i to j because i not promoted by the assert.
    assertEdge(iNode, jNode, hard: true);
    // But there is no edge from i to k.
    assertNoEdge(iNode, kNode);
  }

  Future<void> test_assignmentExpression() async {
    await analyze('''
void f(int i, int j) {
  if (i != null) {
    g(i);
    i = j;
    h(i);
  }
}
void g(int k) {}
void h(int l) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    var lNode = decoratedTypeAnnotation('int l').node;
    // No edge from i to k because i's type is promoted to non-nullable
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to l, because it is after the assignment
    assertEdge(iNode, lNode, hard: false);
    // And there is an edge from j to i, because a null value of j would lead to
    // a null value for i.
    assertEdge(jNode, iNode, hard: false);
  }

  Future<void> test_assignmentExpression_lhs_before_rhs() async {
    await analyze('''
void f(int i, List<int> l) {
  if (i != null) {
    l[i = g(i)] = h(i);
  }
}
int g(int j) => 1;
int h(int k) => 1;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    var gReturnNode = decoratedTypeAnnotation('int g').node;
    // No edge from i to j, because i's type is promoted before the call to g.
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, because the call to h happens after the
    // assignment.
    assertEdge(iNode, kNode, hard: false);
    // And there is an edge from g's return type to i, due to the assignment.
    assertEdge(gReturnNode, iNode, hard: false);
  }

  Future<void> test_assignmentExpression_null_aware() async {
    await analyze('''
void f(bool b, int i, int j) {
  if (b) {
    j ??= i is int ? i : throw 'foo';
    g(i);
    j = i is int ? i : throw 'foo';
    h(i);
  }
}
void g(int k) {}
void h(int l) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    var lNode = decoratedTypeAnnotation('int l').node;
    // No edge from i to l because i's type is promoted to non-nullable
    assertNoEdge(iNode, lNode);
    // But there is an edge from i to k, because the RHS of the `??=` is not
    // guaranteed to execute
    assertEdge(iNode, kNode, hard: false);
  }

  Future<void> test_assignmentExpression_write_after_rhs() async {
    await analyze('''
void f(int i) {
  if (i != null) {
    i = g(i);
    h(i);
  }
}
int g(int j) => 1;
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    var gReturnNode = decoratedTypeAnnotation('int g').node;
    // No edge from i to j because i's type is promoted before the call to g.
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, because the call to h happens after the
    // assignment.
    assertEdge(iNode, kNode, hard: false);
    // And there is an edge from g's return type to i, due to the assignment.
    assertEdge(gReturnNode, iNode, hard: false);
  }

  Future<void> test_binaryExpression_ampersandAmpersand_left() async {
    await analyze('''
bool f(int i) => i != null && i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_binaryExpression_ampersandAmpersand_right() async {
    await analyze('''
void f(bool b, int i, int j) {
  if (b && i != null) {
    print(i.isEven);
    print(j.isEven);
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_binaryExpression_barBar_left() async {
    await analyze('''
bool f(int i) => i == null || i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_binaryExpression_barBar_right() async {
    await analyze('''
void f(bool b, int i, int j) {
  if (b || i == null) {} else {
    print(i.isEven);
    print(j.isEven);
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_booleanLiteral_false() async {
    await analyze('''
void f(int i, int j) {
  if (i != null || false) {} else return;
  if (j != null || true) {} else return;
  i.isEven;
  j.isEven;
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never i is known to be non-nullable at the site of
    // the call to i.isEven
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_booleanLiteral_true() async {
    await analyze('''
void f(int i, int j) {
  if (i == null && true) return;
  if (j == null && false) return;
  i.isEven;
  j.isEven;
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never i is known to be non-nullable at the site of
    // the call to i.isEven
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_break_labeled() async {
    await analyze('''
void f(int i) {
  L: while(true) {
    while (b()) {
      if (i != null) break L;
    }
    g(i);
  }
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_break_unlabeled() async {
    await analyze('''
void f(int i) {
  while (true) {
    if (i != null) break;
    g(i);
  }
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void>
      test_catch_cancels_promotions_based_on_assignments_in_body() async {
    await analyze('''
void f(int i) {
  if (i == null) return;
  try {
    g(i);
    i = null;
    if (i == null) return;
    g(i);
  } catch (_) {
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i is promoted at the time of both calls to g.
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, because there is no guarantee that i is
    // promoted at all times during the execution of the try block.
    assertEdge(iNode, kNode, hard: false);
  }

  Future<void> test_catch_falls_through_to_after_try() async {
    await analyze('''
void f(int i) {
  try {
    g(i);
    return;
  } catch (_) {
    if (i == null) return;
  }
  h(i);
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i's type is promoted to non-nullable
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j.
    assertEdge(iNode, jNode, hard: true);
  }

  Future<void> test_catch_resets_to_state_before_try() async {
    await analyze('''
void f(int i) {
  try {
    if (i == null) return;
    g(i);
  } catch (_) {
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i's type is promoted to non-nullable
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, since we assume an exception might
    // occur at any time during the body of the try.
    assertEdge(iNode, kNode, hard: false);
  }

  Future<void> test_conditionalExpression() async {
    await analyze('''
int f(int i, int l) => i == null ? g(l) : h(i);
int g(int j) => 1;
int h(int k) => 1;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    var lNode = decoratedTypeAnnotation('int l').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from l to j
    assertEdge(lNode, jNode, hard: false, guards: [iNode]);
  }

  Future<void> test_conditionalExpression_propagates_promotions() async {
    await analyze('''
void f(bool b, int i, int j, int k) {
  if (b ? (i != null && j != null) : (i != null && k != null)) {
    i.isEven;
    j.isEven;
    k.isEven;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to never because i is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there are edges from j and k to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
    assertEdge(kNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_constructorDeclaration_assert() async {
    await analyze('''
class C {
  C(int i, int j) : assert(i == null || i.isEven, j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_constructorDeclaration_initializer() async {
    await analyze('''
class C {
  bool b1;
  bool b2;
  C(int i, int j) : b1 = i == null || i.isEven, b2 = j.isEven;
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_constructorDeclaration_redirection() async {
    await analyze('''
class C {
  C(bool b1, bool b2);
  C.redirect(int i, int j) : this(i == null || i.isEven, j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_continue_labeled() async {
    await analyze('''
void f(int i) {
  L: do {
    do {
      if (i != null) continue L;
    } while (g(i));
    break;
  } while (h(i));
}
bool g(int j) => true;
bool h(int k) => true;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_continue_unlabeled() async {
    await analyze('''
void f(int i) {
  do {
    if (i != null) continue;
    h(i);
    break;
  } while (g(i));
}
bool g(int j) => true;
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i is promoted at the time of the call to g.
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to h.
    assertEdge(iNode, kNode, hard: false);
  }

  Future<void> test_do_break_target() async {
    await analyze('''
void f(int i) {
  L: do {
    do {
      if (i != null) break L;
      if (b()) break;
    } while (true);
    g(i);
  } while (true);
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_do_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  do {
    i.isEven;
    j.isEven;
    j = null;
  } while (true);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_do_cancels_promotions_for_assignments_in_condition() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  do {} while (i.isEven && j.isEven && g(j = null));
}
bool g(int k) => true;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_do_continue_target() async {
    await analyze('''
void f(int i) {
  L: do {
    do {
      if (i != null) continue L;
      g(i);
    } while (true);
  } while (h(i));
}
void g(int j) {}
bool h(int k) => true;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_field_initializer() async {
    await analyze('''
bool b1 = true;
bool b2 = true;
class C {
  bool b = b1 || b2;
}
''');
    // No assertions; we just want to verify that the presence of `||` inside a
    // field doesn't cause flow analysis to crash.
  }

  Future<void> test_finally_promotions_are_preserved() async {
    await analyze('''
void f(int i) {
  try {
    g(i);
  } finally {
    if (i == null) return;
  }
  h(i);
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i's type is promoted to non-nullable in the
    // finally block.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j.
    assertEdge(iNode, jNode, hard: true);
  }

  Future<void> test_finally_temporarily_resets_to_state_before_try() async {
    await analyze('''
void f(int i) {
  try {
    if (i == null) return;
    g(i);
  } finally {
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i's type is promoted to non-nullable in the
    // try-block.
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, since we assume an exception might
    // occur at any time during the body of the try.
    assertEdge(iNode, kNode, hard: false);
  }

  Future<void> test_for_break_target() async {
    await analyze('''
void f(int i) {
  L: for (;;) {
    for (;;) {
      if (i != null) break L;
      if (b()) break;
    }
    g(i);
  }
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_for_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  for (;;) {
    i.isEven;
    j.isEven;
    j = null;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_for_cancels_promotions_for_assignments_in_updaters() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  for (;; j = null) {
    i.isEven;
    j.isEven;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_collection_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  <Object>[for (;;) <Object>[i.isEven, j.isEven, (j = null)]];
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_collection_cancels_promotions_for_assignments_in_updaters() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  <Object>[for (;; j = null) <Object>[i.isEven, j.isEven]];
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_collection_preserves_promotions_for_assignments_in_initializer() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  <Object>[for(var v = h(i.isEven && j.isEven && g(i = null));;) null];
}
bool g(int k) => true;
int h(bool b) => 0;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because it is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_for_continue_target() async {
    await analyze('''
void f(int i) {
  L: for (; b(); h(i)) {
    for (; b(); g(i)) {
      if (i != null) continue L;
    }
    return;
  }
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_for_each_assigns_to_declared_var() async {
    await analyze('''
void f(Iterable<int> x) {
  for (int i in x) {
    g(i);
  }
}
void g(int j) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    // No edge from never to i because it is assigned before it is used.
    assertNoEdge(never, iNode);
  }

  Future<void> test_for_each_assigns_to_identifier() async {
    await analyze('''
void f(Iterable<int> x) {
  int i;
  for (i in x) {
    g(i);
  }
}
void g(int j) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    // No edge from never to i because it is assigned before it is used.
    assertNoEdge(never, iNode);
  }

  Future<void>
      test_for_each_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j, Iterable<Object> x) {
  if (i == null) return;
  if (j == null) return;
  for (var v in x) {
    i.isEven;
    j.isEven;
    j = null;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_for_each_collection_assigns_to_declared_var() async {
    await analyze('''
void f(Iterable<int> x) {
  [for (int i in x) g(i)];
}
void g(int j) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    // No edge from never to i because it is assigned before it is used.
    assertNoEdge(never, iNode);
  }

  Future<void> test_for_each_collection_assigns_to_identifier() async {
    await analyze('''
void f(Iterable<int> x) {
  int i;
  [for (i in x) g(i)];
}
void g(int j) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    // No edge from never to i because it is assigned before it is used.
    assertNoEdge(never, iNode);
  }

  Future<void>
      test_for_each_collection_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j, Iterable<Object> x) {
  if (i == null) return;
  if (j == null) return;
  <Object>[for (var v in x) <Object>[i.isEven, j.isEven, (j = null)]];
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_each_collection_preserves_promotions_for_assignments_in_iterable() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  <Object>[for(var v in h(i.isEven && j.isEven && g(i = null))) null];
}
bool g(int k) => true;
Iterable<Object> h(bool b) => <Object>[];
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because it is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_each_preserves_promotions_for_assignments_in_iterable() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  for(var v in h(i.isEven && j.isEven && g(i = null))) {}
}
bool g(int k) => true;
Iterable<Object> h(bool b) => <Object>[];
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because it is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_for_preserves_promotions_for_assignments_in_initializer() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  for(var v = h(i.isEven && j.isEven && g(i = null));;) {}
}
bool g(int k) => true;
int h(bool b) => 0;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because it is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_function_withFormals() async {
    await analyze('''
void f(Function<T>() f) {
  if (f == null) return;
  f();
}
''');
    var fNode = decoratedGenericFunctionTypeAnnotation('Function<T>() f').node;
    // No edge to never because it had been promoted before invoked.
    assertNoEdge(fNode, graph.never);
  }

  Future<void> test_functionDeclaration() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  print(i.isEven);
  print(j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_functionDeclaration_expression_body() async {
    await analyze('''
bool f(int i) => i == null || i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void>
      test_functionDeclaration_resets_unconditional_control_flow() async {
    await analyze('''
void f(bool b, int i, int j) {
  assert(i != null);
  if (b) return;
  assert(j != null);
}
void g(int k) {
  assert(k != null);
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
    assertNoEdge(always, decoratedTypeAnnotation('int j').node);
    assertEdge(decoratedTypeAnnotation('int k').node, never, hard: true);
  }

  Future<void> test_functionExpression_parameters() async {
    await analyze('''
void f() {
  var g = (int i, int j) {
    if (i == null) return;
    print(i.isEven);
    print(j.isEven);
  };
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_if() async {
    await analyze('''
void f(int i) {
  if (i == null) {
    g(i);
  } else {
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j
    assertEdge(iNode, jNode, hard: false, guards: [iNode]);
  }

  Future<void> test_if_without_else() async {
    await analyze('''
void f(int i) {
  if (i == null) {
    g(i);
    return;
  }
  h(i);
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j
    assertEdge(iNode, jNode, hard: false, guards: [iNode]);
  }

  Future<void> test_ifNull() async {
    await analyze('''
void f(int i, int x) {
  x ?? (i == null ? throw 'foo' : g(i));
  h(i);
}
int g(int j) => 0;
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to j because i's type is promoted to non-nullable
    assertNoEdge(iNode, jNode);
    // But there is an edge from i to k, because the RHS of the `??` isn't
    // guaranteed to execute.
    assertEdge(iNode, kNode, hard: true);
  }

  Future<void> test_is() async {
    await analyze('''
void f(num n) {
  if (n is int) {
    g(n);
  }
  h(n);
}
void g(int i) {}
void h(num m) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var nNode = decoratedTypeAnnotation('num n').node;
    var mNode = decoratedTypeAnnotation('num m').node;
    // No edge from n to i because n is known to be non-nullable at the site of
    // the call to g
    assertNoEdge(nNode, iNode);
    // But there is an edge from n to m.
    assertEdge(nNode, mNode, hard: true);
  }

  Future<void> test_is_not() async {
    await analyze('''
void f(num n) {
  if (n is! int) {} else {
    g(n);
  }
  h(n);
}
void g(int i) {}
void h(num m) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var nNode = decoratedTypeAnnotation('num n').node;
    var mNode = decoratedTypeAnnotation('num m').node;
    // No edge from n to i because n is known to be non-nullable at the site of
    // the call to g
    assertNoEdge(nNode, iNode);
    // But there is an edge from n to m.
    assertEdge(nNode, mNode, hard: true);
  }

  Future<void> test_local_function_parameters() async {
    await analyze('''
void f() {
  void g(int i, int j) {
    if (i == null) return;
    print(i.isEven);
    print(j.isEven);
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_not() async {
    await analyze('''
void f(int i) {
  if (!(i == null)) {
    h(i);
  } else {
    g(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_not_null_then_promote() async {
    await analyze('''
void f(dynamic n) {
  if (n == null) {
    return;
  } else if (n is List<int>) {
    n.length; // Ensure this doesn't crash during method lookup.
    g(n); // Test this is wired correctly in graph.
  }
}
void g(List<int> j) {}
''');
    var nNode = decoratedTypeAnnotation('dynamic n').node;
    var jNode = decoratedTypeAnnotation('List<int> j').node;
    var jParamNode = decoratedTypeAnnotation('int> j').node;
    var intParamNode = decoratedTypeAnnotation('int>)').node;
    // No edge from n to g because i is known to be non-nullable at the site of
    // the call to g()
    assertNoEdge(nNode, jNode);
    // But there is an edge from nonNull(List<int>) to j
    assertEdge(inSet(neverClosure), jNode, hard: false);
    assertEdge(intParamNode, jParamNode, hard: false, checkable: false);
  }

  Future<void> test_postfixDecrement() async {
    await analyze('''
void f(C c1) {
  if (c1 != null) {
    g(c1);
    c1--;
    h(c1);
  }
}
void g(C c2) {}
void h(C c3) {}
class C {
  C operator-(int i) => this;
}
''');
    var c1Node = decoratedTypeAnnotation('C c1').node;
    var c2Node = decoratedTypeAnnotation('C c2').node;
    var c3Node = decoratedTypeAnnotation('C c3').node;
    // No edge from c1 to c2 because c1's type is promoted to non-nullable
    assertNoEdge(c1Node, c2Node);
    // But there is an edge from c1 to c3, because the decrement un-does the
    // promotion.
    assertEdge(c1Node, c3Node, hard: false);
  }

  Future<void> test_postfixIncrement() async {
    await analyze('''
void f(C c1) {
  if (c1 != null) {
    g(c1);
    c1++;
    h(c1);
  }
}
void g(C c2) {}
void h(C c3) {}
class C {
  C operator+(int i) => this;
}
''');
    var c1Node = decoratedTypeAnnotation('C c1').node;
    var c2Node = decoratedTypeAnnotation('C c2').node;
    var c3Node = decoratedTypeAnnotation('C c3').node;
    // No edge from c1 to c2 because c1's type is promoted to non-nullable
    assertNoEdge(c1Node, c2Node);
    // But there is an edge from c1 to c3, because the increment un-does the
    // promotion.
    assertEdge(c1Node, c3Node, hard: false);
  }

  Future<void> test_prefixDecrement() async {
    await analyze('''
void f(C c1) {
  if (c1 != null) {
    g(c1);
    --c1;
    h(c1);
  }
}
void g(C c2) {}
void h(C c3) {}
class C {
  C operator-(int i) => this;
}
''');
    var c1Node = decoratedTypeAnnotation('C c1').node;
    var c2Node = decoratedTypeAnnotation('C c2').node;
    var c3Node = decoratedTypeAnnotation('C c3').node;
    // No edge from c1 to c2 because c1's type is promoted to non-nullable
    assertNoEdge(c1Node, c2Node);
    // But there is an edge from c1 to c3, because the decrement un-does the
    // promotion.
    assertEdge(c1Node, c3Node, hard: false);
  }

  Future<void> test_prefixIncrement() async {
    await analyze('''
void f(C c1) {
  if (c1 != null) {
    g(c1);
    ++c1;
    h(c1);
  }
}
void g(C c2) {}
void h(C c3) {}
class C {
  C operator+(int i) => this;
}
''');
    var c1Node = decoratedTypeAnnotation('C c1').node;
    var c2Node = decoratedTypeAnnotation('C c2').node;
    var c3Node = decoratedTypeAnnotation('C c3').node;
    // No edge from c1 to c2 because c1's type is promoted to non-nullable
    assertNoEdge(c1Node, c2Node);
    // But there is an edge from c1 to c3, because the increment un-does the
    // promotion.
    assertEdge(c1Node, c3Node, hard: false);
  }

  Future<void> test_rethrow() async {
    await analyze('''
void f(int i, int j) {
  try {
    g();
  } catch (_) {
    if (i == null) rethrow;
    print(i.isEven);
    print(j.isEven);
  }
}
void g() {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_return() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  print(i.isEven);
  print(j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_switch_break_target() async {
    await analyze('''
void f(int i, int x, int y) {
  L: switch (x) {
    default:
      switch (y) {
        default:
          if (i != null) break L;
          if (b()) break;
          return;
      }
      g(i);
      return;
  }
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_switch_cancels_promotions_for_labeled_cases() async {
    await analyze('''
void f(int i, int x, bool b) {
  if (i == null) return;
  switch (x) {
    L:
    case 1:
      g(i);
      break;
    case 2:
      h(i);
      i = null;
      if (b) continue L;
      break;
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i's type is promoted to non-nullable at the
    // time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_switch_default() async {
    await analyze('''
void f(int i, int j, int x, int y) {
  if (i == null) {
    switch (x) {
      default: return;
    }
  }
  if (j == null) {
    switch (y) {
      case 0: return;
    }
  }
  i.isEven;
  j.isEven;
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because the switch statement is guaranteed to
    // complete by returning, so i is promoted to non-nullable.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never, because the switch statement is not
    // guaranteed to complete by returning, so j is not promoted.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_throw() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) throw 'foo';
  print(i.isEven);
  print(j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to `never`.
    assertEdge(jNode, inSet(pointsToNever), hard: true);
  }

  Future<void> test_topLevelVar_initializer() async {
    await analyze('''
bool b1 = true;
bool b2 = true;
bool b3 = b1 || b2;
''');
    // No assertions; we just want to verify that the presence of `||` inside a
    // top level variable doesn't cause flow analysis to crash.
  }

  Future<void> test_try_falls_through_to_after_try() async {
    await analyze('''
void f(int i) {
  try {
    g(i);
    if (i == null) return;
  } catch (_) {
    return;
  }
  h(i);
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i's type is promoted to non-nullable
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j.
    assertEdge(iNode, jNode, hard: true);
  }

  Future<void> test_while_break_target() async {
    await analyze('''
void f(int i) {
  L: while (true) {
    while (true) {
      if (i != null) break L;
      if (b()) break;
    }
    g(i);
  }
  h(i);
}
bool b() => true;
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is promoted at the time of the call to h.
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j, because i is not promoted at the time
    // of the call to g.
    assertEdge(iNode, jNode, hard: false);
  }

  Future<void> test_while_cancels_promotions_for_assignments_in_body() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  while (true) {
    i.isEven;
    j.isEven;
    j = null;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void>
      test_while_cancels_promotions_for_assignments_in_condition() async {
    await analyze('''
void f(int i, int j) {
  if (i == null) return;
  if (j == null) return;
  while (i.isEven && j.isEven && g(j = null)) {}
}
bool g(int k) => true;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never because its promotion was cancelled.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }

  Future<void> test_while_promotes() async {
    await analyze('''
void f(int i, int j) {
  while (i != null) {
    i.isEven;
    j.isEven;
  }
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to never because is is promoted.
    assertNoEdge(iNode, inSet(pointsToNever));
    // But there is an edge from j to never.
    assertEdge(jNode, inSet(pointsToNever), hard: false);
  }
}
