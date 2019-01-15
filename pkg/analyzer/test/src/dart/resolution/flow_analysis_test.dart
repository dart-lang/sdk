// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefiniteAssignmentFlowTest);
    defineReflectiveTests(TypePromotionFlowTest);
  });
}

@reflectiveTest
class DefiniteAssignmentFlowTest extends DriverResolutionTest {
  FlowAnalysis flow;

  /// Assert that only local variables with the given names are marked as read
  /// before being written.  All the other local variables are implicitly
  /// considered definitely assigned.
  void assertReadBeforeWritten(
      [String name1, String name2, String name3, String name4]) {
    var expected = [name1, name2, name3, name4]
        .where((i) => i != null)
        .map((name) => findElement.localVar(name))
        .toList();
    expect(flow.readBeforeWritten, unorderedEquals(expected));
  }

  test_binaryExpression_logicalAnd_left() async {
    await trackCode(r'''
main(bool c) {
  int v;
  ((v = 0) >= 0) && c;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_logicalAnd_right() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c && ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_logicalOr_left() async {
    await trackCode(r'''
main(bool c) {
  int v;
  ((v = 0) >= 0) || c;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_logicalOr_right() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c || ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_plus_left() async {
    await trackCode(r'''
main() {
  int v;
  (v = 0) + 1;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_plus_right() async {
    await trackCode(r'''
main() {
  int v;
  1 + (v = 0);
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition() async {
    await trackCode(r'''
main() {
  int v;
  if ((v = 0) >= 0) {
    v;
  } else {
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_false() async {
    // new test
    await trackCode(r'''
void f() {
  int v;
  if (false) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalAnd_else() async {
    // new test
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
  } else {
    v;
  }
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_condition_logicalAnd_then() async {
    // new test
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
    v;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalOr_else() async {
    // new test
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
  } else {
    v;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalOr_then() async {
    // new test
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
    v;
  } else {
  }
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_condition_notFalse() async {
    // new test
    await trackCode(r'''
void f() {
  int v;
  if (!false) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_notTrue() async {
    // new test
    await trackCode(r'''
void f() {
  int v;
  if (!true) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_true() async {
    // new test
    await trackCode(r'''
void f() {
  int v;
  if (true) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_then() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_thenElse_all() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
    v;
  } else {
    v = 0;
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_thenElse_else() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_thenElse_then() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    // not assigned
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  /// Resolve the given [code] and track assignments in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var typeSystem = result.unit.declaredElement.context.typeSystem;
    flow = FlowAnalysis(typeSystem);

    var visitor = _AstVisitor(flow, {});
    result.unit.accept(visitor);
  }
}

@reflectiveTest
class TypePromotionFlowTest extends DriverResolutionTest {
  Map<AstNode, DartType> promotedTypes = {};
  FlowAnalysis flow;

  void assertNotPromoted(String search) {
    var node = findNode.simple(search);
    var actualType = promotedTypes[node];
    expect(actualType, isNull);
  }

  void assertPromoted(String search, String expectedType) {
    var node = findNode.simple(search);
    var actualType = promotedTypes[node];
    if (actualType == null) {
      fail('$expectedType expected, but actually not promoted');
    }
    assertElementTypeString(actualType, expectedType);
  }

  test_if_combine_empty() async {
    // new test
    await trackCode(r'''
main(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType() async {
    // new test
    await trackCode(r'''
main(v) {
  if (v is! String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType_return() async {
    // new test
    await trackCode(r'''
main(v) {
  if (v is! String) return;
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_if_isType() async {
    await trackCode(r'''
main(v) {
  if (v is String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertPromoted('v; // 1', 'String');
    assertNotPromoted('v; // 2');
    assertNotPromoted('v; // 3');
  }

  test_if_isType_thenNonBoolean() async {
    await trackCode(r'''
f(Object x) {
  if ((x is String) != 3) {
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_if_logicalNot_isType() async {
    // new test
    await trackCode(r'''
main(v) {
  if (!(v is String)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_logicalOr_throw() async {
    // new test
    await trackCode(r'''
main(v) {
  v is String || (throw 42);
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  /// Resolve the given [code] and track assignments in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var typeSystem = result.unit.declaredElement.context.typeSystem;
    flow = FlowAnalysis(typeSystem);

    var visitor = _AstVisitor(flow, promotedTypes);
    result.unit.accept(visitor);
  }
}

/// [AstVisitor] that drives the [flow] in the way we expect the resolver
/// will do in production.
class _AstVisitor extends RecursiveAstVisitor<void> {
  final FlowAnalysis flow;
  final Map<AstNode, DartType> promotedTypes;

  _AstVisitor(this.flow, this.promotedTypes);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    LocalVariableElement localElement;
    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is LocalVariableElement) {
        localElement = element;
      }
    }

    if (localElement != null) {
      var isPure = node.operator.type == TokenType.EQ;
      if (!isPure) {
        flow.read(localElement);
      }
      right.accept(this);
      flow.write(localElement);
    } else {
      left.accept(this);
      right.accept(this);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var left = node.leftOperand;
    var right = node.rightOperand;

    var operator = node.operator.type;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      left.accept(this);

      flow.logicalAnd_rightBegin(node);
      right.accept(this);

      flow.logicalAnd_end(node);
    } else if (operator == TokenType.BAR_BAR) {
      left.accept(this);

      flow.logicalOr_rightBegin(node);
      right.accept(this);

      flow.logicalOr_end(node);
    } else {
      left.accept(this);
      right.accept(this);
    }

//    var isLogical = operator == TokenType.AMPERSAND_AMPERSAND ||
//        operator == TokenType.BAR_BAR ||
//        operator == TokenType.QUESTION_QUESTION;
//
//    left.accept(this);
//
//    if (isLogical) {
//      tracker.beginBinaryExpressionLogicalRight();
//    }
//
//    right.accept(this);
//
//    if (isLogical) {
//      tracker.endBinaryExpressionLogicalRight();
//    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    super.visitBlockFunctionBody(node);
    flow.verifyStackEmpty();
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    super.visitBooleanLiteral(node);
    if (_isFalseLiteral(node)) {
      flow.falseLiteral(node);
    }
    if (_isTrueLiteral(node)) {
      flow.trueLiteral(node);
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    super.visitExpressionFunctionBody(node);
    flow.verifyStackEmpty();
  }

  @override
  void visitIfStatement(IfStatement node) {
    var condition = node.condition;
    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;

    condition.accept(this);

    flow.ifStatement_thenBegin(node);
    thenStatement.accept(this);

    if (elseStatement != null) {
      flow.ifStatement_elseBegin();
      elseStatement.accept(this);
    }

    flow.ifStatement_end(elseStatement != null);
  }

  @override
  void visitIsExpression(IsExpression node) {
    super.visitIsExpression(node);
    var expression = node.expression;
    var typeAnnotation = node.type;

    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is LocalElement) {
        flow.isExpression_end(node, element, typeAnnotation.type);
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand;

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      operand.accept(this);
      flow.logicalNot_end(node);
    } else {
      operand.accept(this);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    super.visitReturnStatement(node);
    flow.handleExit();
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    var isLocalVariable = element is LocalVariableElement;
    if (isLocalVariable || element is ParameterElement) {
      if (node.inGetterContext()) {
        if (isLocalVariable) {
          flow.read(element);
        }

        var promotedType = flow.promotedType(element);
        if (promotedType != null) {
          promotedTypes[node] = promotedType;
        }
      }
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    flow.handleExit();
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var variables = node.variables.variables;
    for (var i = 0; i < variables.length; ++i) {
      var variable = variables[i];
      flow.add(variable.declaredElement,
          assigned: variable.initializer != null);
    }

    super.visitVariableDeclarationStatement(node);
  }

  static bool _isFalseLiteral(AstNode node) {
    return node is BooleanLiteral && !node.value;
  }

  static bool _isTrueLiteral(AstNode node) {
    return node is BooleanLiteral && node.value;
  }
}
