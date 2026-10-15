// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart' show V1Ast;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    // ignore: analyzer_v1_ast_use
    defineReflectiveTests(BreadthFirstVisitorTest);
  });
}

@reflectiveTest
@V1Ast('Tests V1 BreadthFirstVisitor.')
class BreadthFirstVisitorTest extends ParserDiagnosticsTest {
  void test_it() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  bool get g => true;
}
class B {
  int f() {
    num q() {
      return 3;
    }
  return q() + 4;
  }
}
A f(p) {
  if ((p as A).g) {
    return p;
  } else {
    return null;
  }
}''');
    var findNode = parseResult.findNode;

    var nodes = <AstNode>[];
    var visitor = _BreadthFirstVisitorTestHelper(nodes);
    visitor.visitAllNodes(parseResult.unit);

    expect(nodes, hasLength(51));
    expect(nodes[0], parseResult.unit);
    expect(nodes[2], findNode.classDeclaration('class B'));
    // The V1 projection of the top-level function `f`.
    expect(nodes[3], parseResult.unit.declarations[2]);
    // The V1 projection of the local function `q`.
    var classB = parseResult.unit.declarations[1] as ClassDeclaration;
    var method = (classB.body as BlockClassBody).members.single;
    method as MethodDeclaration;
    var block = (method.body as BlockFunctionBody).block;
    expect(nodes[24], block.statements[0]);
    expect(nodes[50], findNode.integerLiteral('3'));
  }
}

/// A helper class used to collect the nodes that were visited and to preserve
/// the order in which they were visited.
@V1Ast('Tests V1 BreadthFirstVisitor.')
class _BreadthFirstVisitorTestHelper extends BreadthFirstVisitor<void> {
  List<AstNode> nodes;

  _BreadthFirstVisitorTestHelper(this.nodes) : super();

  @override
  void visitNode(AstNode node) {
    nodes.add(node);
    super.visitNode(node);
  }
}
