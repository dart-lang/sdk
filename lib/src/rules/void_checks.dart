// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';

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
  A<void> a = new A<void>();
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
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addAssignmentExpression(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  InterfaceType _futureDynamicType;
  InterfaceType _futureOrDynamicType;

  _Visitor(this.rule);

  bool isTypeAcceptableWhenExpectingVoid(DartType type) {
    if (type.isVoid) return true;
    if (type.isDartCoreNull) return true;
    if (type.isDartAsyncFuture &&
        type is ParameterizedType &&
        (type.typeArguments.first.isVoid ||
            type.typeArguments.first.isDartCoreNull)) {
      return true;
    }
    return false;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final type = node.leftHandSide?.bestType;
    if (!_isFunctionRef(type, node.rightHandSide)) {
      _check(type, node.rightHandSide?.bestType, node);
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final typeProvider = node.element.context.typeProvider;
    _futureDynamicType =
        typeProvider.futureType.instantiate([typeProvider.dynamicType]);
    _futureOrDynamicType =
        typeProvider.futureOrType.instantiate([typeProvider.dynamicType]);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    final parameters = node.staticElement.parameters;
    _checkArgs(args, parameters);
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
    final parent = node.getAncestor((e) =>
        e is FunctionExpression ||
        e is MethodDeclaration ||
        e is FunctionDeclaration);
    if (parent is FunctionExpression) {
      final type = parent.bestType;
      if (type is FunctionType) {
        _check(type.returnType, node.expression?.bestType, node);
      }
    } else if (parent is MethodDeclaration) {
      _check(parent.element.returnType, node.expression?.bestType, node);
    } else if (parent is FunctionDeclaration) {
      _check(parent.element.returnType, node.expression?.bestType, node);
    }
  }

  void _check(DartType expectedType, DartType type, AstNode node) {
    if (expectedType == null || type == null) {
      return;
    } else if (expectedType.isVoid &&
            !isTypeAcceptableWhenExpectingVoid(type) ||
        expectedType.isDartAsyncFutureOr &&
            (expectedType as InterfaceType).typeArguments.first.isVoid &&
            !type.isAssignableTo(_futureDynamicType) &&
            !type.isAssignableTo(_futureOrDynamicType)) {
      rule.reportLint(node);
    } else if (expectedType is FunctionType && type is FunctionType) {
      _check(expectedType.returnType, type.returnType, node);
    }
  }

  void _checkArgs(
      NodeList<Expression> args, List<ParameterElement> parameters) {
    for (final arg in args) {
      final type = arg.bestParameterElement.type;
      final expression = arg is NamedExpression ? arg.expression : arg;
      if (!_isFunctionRef(type, expression)) {
        _check(type, expression?.bestType, expression);
      }
    }
  }

  bool _isFunctionRef(DartType type, Expression arg) =>
      type is FunctionType &&
      (arg is SimpleIdentifier ||
          arg is PrefixedIdentifier ||
          arg is FunctionExpression && arg.body is ExpressionFunctionBody);
}
