// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.ast.visitor_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test.dart' show ParserTestCase;
import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BreadthFirstVisitorTest);
  });
}

@reflectiveTest
class BreadthFirstVisitorTest extends ParserTestCase {
  void test_it() {
    String source = r'''
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
A f(var p) {
  if ((p as A).g) {
    return p;
  } else {
    return null;
  }
}''';
    CompilationUnit unit = parseCompilationUnit(source);
    List<AstNode> nodes = new List<AstNode>();
    BreadthFirstVisitor<Object> visitor =
        new _BreadthFirstVisitorTestHelper(nodes);
    visitor.visitAllNodes(unit);
    expect(nodes, hasLength(59));
    EngineTestCase.assertInstanceOf(
        (obj) => obj is CompilationUnit, CompilationUnit, nodes[0]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassDeclaration, ClassDeclaration, nodes[2]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionDeclaration, FunctionDeclaration, nodes[3]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionDeclarationStatement,
        FunctionDeclarationStatement,
        nodes[27]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IntegerLiteral, IntegerLiteral, nodes[58]);
    //3
  }
}

/**
 * A helper class used to collect the nodes that were visited and to preserve
 * the order in which they were visited.
 */
class _BreadthFirstVisitorTestHelper extends BreadthFirstVisitor<Object> {
  List<AstNode> nodes;

  _BreadthFirstVisitorTestHelper(this.nodes) : super();

  @override
  Object visitNode(AstNode node) {
    nodes.add(node);
    return super.visitNode(node);
  }
}
