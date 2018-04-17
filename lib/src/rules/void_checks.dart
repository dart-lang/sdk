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
    final type = node.staticInvokeType;
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
        _check(type, arg?.bestType, arg);
      } else {
        _check(positionalParameters[positionalCount].type, arg?.bestType, arg);
        positionalCount += 1;
      }
    }
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    _check(node.leftHandSide?.bestType, node.rightHandSide?.bestType, node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
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
    if (expectedType == null || type == null)
      return;
    else if (expectedType.isVoid ||
        expectedType.isDartAsyncFutureOr &&
            (expectedType as InterfaceType).typeArguments.first.isVoid &&
            !type.isAssignableTo(_futureDynamicType) &&
            !type.isAssignableTo(_futureOrDynamicType)) {
      rule.reportLint(node);
    } else if (expectedType is FunctionType && type is FunctionType) {
      _check(expectedType.returnType, type.returnType, node);
    }
  }

  DartType _findParamType(
    FunctionType type,
    AstNode node,
    InvocationExpression invocation,
  ) {
    int index = 0;
    for (final arg in invocation.argumentList.arguments) {
      if (node.getAncestor((e) => e == arg || e == invocation) == arg) {
        if (arg is NamedExpression) {
          return type.namedParameterTypes[arg.name.label.name];
        } else if (index < type.normalParameterTypes.length) {
          return type.normalParameterTypes[index];
        } else {
          return type
              .optionalParameterTypes[index - type.normalParameterTypes.length];
        }
      }
      if (arg is! NamedExpression) index++;
    }
    return null;
  }
}
