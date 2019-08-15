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
  test_binaryExpression_ampersandAmpersand_left() async {
    await analyze('''
bool f(int i) => i != null && i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

  test_binaryExpression_ampersandAmpersand_right() async {
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
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: false);
  }

  test_binaryExpression_barBar_left() async {
    await analyze('''
bool f(int i) => i == null || i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

  test_binaryExpression_barBar_right() async {
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
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: false);
  }

  test_constructorDeclaration_assert() async {
    await analyze('''
class C {
  C(int i, int j) : assert(i == null || i.isEven, j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

  test_constructorDeclaration_initializer() async {
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
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

  test_constructorDeclaration_redirection() async {
    await analyze('''
class C {
  C(bool b1, bool b2);
  C.redirect(int i, int j) : this(i == null || i.isEven, j.isEven);
}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

  test_field_initializer() async {
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

  test_functionDeclaration() async {
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
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: false);
  }

  test_functionDeclaration_expression_body() async {
    await analyze('''
bool f(int i) => i == null || i.isEven;
bool g(int j) => j.isEven;
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    // No edge from i to `never` because i's type is promoted to non-nullable
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: true);
  }

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

  test_if() async {
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

  test_if_conditional_control_flow_after() async {
    // Asserts after ifs don't demonstrate non-null intent.
    // TODO(paulberry): if both branches complete normally, they should.
    await analyze('''
void f(bool b, int i) {
  if (b) return;
  assert(i != null);
}
''');

    assertNoEdge(always, decoratedTypeAnnotation('int i').node);
  }

  test_if_conditional_control_flow_within() async {
    // Asserts inside ifs don't demonstrate non-null intent.
    await analyze('''
void f(bool b, int i) {
  if (b) {
    assert(i != null);
  } else {
    assert(i != null);
  }
}
''');

    assertNoEdge(always, decoratedTypeAnnotation('int i').node);
  }

  test_if_without_else() async {
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

  test_return() async {
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
    assertNoEdge(iNode, never);
    // But there is an edge from j to `never`.
    assertEdge(jNode, never, hard: false);
  }

  test_topLevelVar_initializer() async {
    await analyze('''
bool b1 = true;
bool b2 = true;
bool b3 = b1 || b2;
''');
    // No assertions; we just want to verify that the presence of `||` inside a
    // top level variable doesn't cause flow analysis to crash.
  }
}
