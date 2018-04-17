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

class VoidChecks extends LintRule {
  VoidChecks()
      : super(
            name: 'void_checks',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  InterfaceType _futureDynamicType;
  InterfaceType _futureOrDynamicType;

  @override
  visitCompilationUnit(CompilationUnit node) {
    final typeProvider = node.element.context.typeProvider;
    _futureDynamicType =
        typeProvider.futureType.instantiate([typeProvider.dynamicType]);
    _futureOrDynamicType =
        typeProvider.futureOrType.instantiate([typeProvider.dynamicType]);
    return super.visitCompilationUnit(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final type = node.function.bestType;
    if (type is FunctionType) {
      final args = node.argumentList.arguments;
      final parameters = type.parameters;
      _checkArgs(args, parameters);
    }
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    final parameters = node.staticElement.parameters;
    _checkArgs(args, parameters);
  }

  void _checkArgs(
      NodeList<Expression> args, List<ParameterElement> parameters) {
    final positionalParameters = parameters.where((e) => !e.isNamed).toList();
    int positionalCount = 0;
    for (final arg in args) {
      if (arg is NamedExpression) {
        final type =
            parameters.singleWhere((e) => e.name == arg.name.label.name).type;
        _check(type, arg, arg);
      } else {
        _check(positionalParameters[positionalCount].type, arg, arg);
        positionalCount += 1;
      }
    }
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    _check(node.leftHandSide.bestType, node.rightHandSide, node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    final parent = node.getAncestor((e) =>
        e is MethodInvocation ||
        e is MethodDeclaration ||
        e is FunctionDeclaration ||
        e is FunctionExpressionInvocation);
    if (parent is MethodInvocation) {
      final type = parent.function.bestType;
      if (type is FunctionType) {
        _check(type.returnType, node.expression, node);
      }
    } else if (parent is MethodDeclaration) {
      _check(parent.element.returnType, node.expression, node);
    } else if (parent is FunctionDeclaration) {
      _check(parent.element.returnType, node.expression, node);
    } else if (parent is FunctionExpressionInvocation) {
      _check(parent.bestElement?.returnType, node.expression, node);
    }
  }

  void _check(DartType expectedType, Expression expression, AstNode node) {
    if (expectedType == null) return;
    if (expectedType.isVoid && expression != null ||
        expectedType.isDartAsyncFutureOr &&
            (expectedType as InterfaceType).typeArguments.first.isVoid &&
            !expression.bestType.isAssignableTo(_futureDynamicType) &&
            !expression.bestType.isAssignableTo(_futureOrDynamicType)) {
      rule.reportLint(node);
    }
  }
}
