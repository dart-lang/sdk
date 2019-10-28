// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't assign to void.";

const _details = r'''

**DO NOT** assign to void.

**BAD:**
```
class A<T> {
  T value;
  void test(T arg) { }
}

void main() {
  A<void> a = A<void>();
  a.value = 1; // LINT
  a.test(1); // LINT
}
```
''';

class VoidChecks extends LintRule implements NodeLintRule {
  VoidChecks()
      : super(
            name: 'void_checks',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addAssignmentExpression(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  final TypeSystem typeSystem;

  InterfaceType _futureDynamicType;

  _Visitor(this.rule, this.context) : typeSystem = context.typeSystem;

  bool isTypeAcceptableWhenExpectingVoid(DartType type) {
    if (type.isVoid) return true;
    if (type.isDartCoreNull) return true;
    if (type.isDartAsyncFuture &&
        type is InterfaceType &&
        (type.typeArguments.first.isVoid ||
            type.typeArguments.first.isDartCoreNull)) {
      return true;
    }
    return false;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final type = node.leftHandSide?.staticType;
    _check(type, node.rightHandSide?.staticType, node,
        checkedNode: node.rightHandSide);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _futureDynamicType = context.typeProvider.futureDynamicType;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    final parameters = node.staticElement?.parameters;
    if (parameters != null) {
      _checkArgs(args, parameters);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticInvokeType;
    if (type is FunctionType) {
      final args = node.argumentList.arguments;
      final parameters = type.parameters;
      _checkArgs(args, parameters);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final parent = node.thisOrAncestorMatching((e) =>
        e is FunctionExpression ||
        e is MethodDeclaration ||
        e is FunctionDeclaration);
    if (parent is FunctionExpression) {
      final type = parent.staticType;
      if (type is FunctionType) {
        _check(type.returnType, node.expression?.staticType, node,
            checkedNode: node.expression);
      }
    } else if (parent is MethodDeclaration) {
      _check(
          parent.declaredElement.returnType, node.expression?.staticType, node,
          checkedNode: node.expression);
    } else if (parent is FunctionDeclaration) {
      _check(
          parent.declaredElement.returnType, node.expression?.staticType, node,
          checkedNode: node.expression);
    }
  }

  void _check(DartType expectedType, DartType type, AstNode node,
      {AstNode checkedNode}) {
    checkedNode ??= node;
    if (expectedType == null || type == null) {
      return;
    } else if (expectedType.isVoid &&
            !isTypeAcceptableWhenExpectingVoid(type) ||
        expectedType.isDartAsyncFutureOr &&
            (expectedType as InterfaceType).typeArguments.first.isVoid &&
            !typeSystem.isAssignableTo(type, _futureDynamicType)) {
      rule.reportLint(node);
    } else if (checkedNode is FunctionExpression &&
        checkedNode.body is! ExpressionFunctionBody &&
        expectedType is FunctionType &&
        type is FunctionType) {
      _check(expectedType.returnType, type.returnType, node,
          checkedNode: checkedNode);
    }
  }

  void _checkArgs(
      NodeList<Expression> args, List<ParameterElement> parameters) {
    for (final arg in args) {
      final parameterElement = arg.staticParameterElement;
      if (parameterElement != null) {
        final type = parameterElement.type;
        final expression = arg is NamedExpression ? arg.expression : arg;
        _check(type, expression?.staticType, expression);
      }
    }
  }
}
