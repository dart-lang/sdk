// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't assign to `void`.";

class VoidChecks extends LintRule {
  VoidChecks()
      : super(
          name: LintNames.void_checks,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.void_checks;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addAssignedVariablePattern(this, visitor);
    registry.addAssignmentExpression(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final TypeSystem typeSystem;

  _Visitor(this.rule, LinterContext context) : typeSystem = context.typeSystem;

  bool isTypeAcceptableWhenExpectingFutureOrVoid(DartType type) {
    if (type is DynamicType) return true;
    if (isTypeAcceptableWhenExpectingVoid(type)) return true;
    if (type.isDartAsyncFutureOr ||
        type.isDartAsyncFuture &&
            type is InterfaceType &&
            isTypeAcceptableWhenExpectingFutureOrVoid(
                type.typeArguments.first)) {
      return true;
    }

    return false;
  }

  bool isTypeAcceptableWhenExpectingVoid(DartType type) {
    if (type is VoidType) return true;
    if (type.isDartCoreNull) return true;
    if (type is NeverType) return true;
    if (type.isDartAsyncFuture &&
        type is InterfaceType &&
        isTypeAcceptableWhenExpectingVoid(type.typeArguments.first)) {
      return true;
    }
    return false;
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var valueType = node.matchedValueType;
    var element = node.element2;
    if (element is! VariableElement2) return;
    _check(element.type, valueType, node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var type = node.writeType;
    _check(type, node.rightHandSide.staticType, node,
        checkedNode: node.rightHandSide);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var args = node.argumentList.arguments;
    var parameters = node.constructorName.element?.formalParameters;
    if (parameters != null) {
      _checkArgs(args, parameters);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.staticInvokeType;
    if (type is FunctionType) {
      var args = node.argumentList.arguments;
      var parameters = type.formalParameters;
      _checkArgs(args, parameters);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    var parent = node.thisOrAncestorMatching((e) =>
        e is FunctionExpression ||
        e is MethodDeclaration ||
        e is FunctionDeclaration);
    if (parent is FunctionExpression) {
      var type = parent.staticType;
      if (type is FunctionType) {
        _check(type.returnType, node.expression?.staticType, node,
            checkedNode: node.expression);
      }
    } else if (parent is MethodDeclaration) {
      _check(parent.declaredFragment?.element.returnType,
          node.expression?.staticType, node,
          checkedNode: node.expression);
    } else if (parent is FunctionDeclaration) {
      var parentElement = parent.declaredFragment?.element;
      _check(parentElement?.returnType, node.expression?.staticType, node,
          checkedNode: node.expression);
    }
  }

  void _check(DartType? expectedType, DartType? type, AstNode node,
      {AstNode? checkedNode}) {
    checkedNode ??= node;
    if (expectedType == null || type == null) {
      return;
    }
    if (expectedType is VoidType &&
        type is! DynamicType &&
        node is ReturnStatement) {
      return;
    }
    if (expectedType is VoidType && !isTypeAcceptableWhenExpectingVoid(type)) {
      rule.reportLint(node);
    } else if (expectedType.isDartAsyncFutureOr &&
        (expectedType as InterfaceType).typeArguments.first is VoidType &&
        !isTypeAcceptableWhenExpectingFutureOrVoid(type)) {
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
      NodeList<Expression> args, List<FormalParameterElement> parameters) {
    for (var arg in args) {
      var parameterElement = arg.correspondingParameter;
      if (parameterElement != null) {
        var type = parameterElement.type;
        var expression = arg is NamedExpression ? arg.expression : arg;
        _check(type, expression.staticType, expression);
      }
    }
  }
}
