// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Checks if the arguments for a parameter annotated with `@mustBeConst` are
/// actually constant.
class ConstArgumentsVerifier extends SimpleAstVisitor<void> {
  final ErrorReporter _errorReporter;

  final ConstantEvaluator _constantEvaluator;

  ConstArgumentsVerifier(this._errorReporter)
      : _constantEvaluator = ConstantEvaluator();

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.EQ) {
      _check(
        arguments: [node.rightHandSide],
        errorNode: node.operator,
      );
    } else if (node.rightHandSide.staticParameterElement?.hasMustBeConst ??
        false) {
      // If the operator is not `=`, then the argument cannot be const, as it
      // depends on the value of the left hand side.
      _errorReporter.atNode(
        node.rightHandSide,
        WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER,
        arguments: [node.rightHandSide],
      );
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _check(
      arguments: [node.rightOperand],
      errorNode: node.operator,
    );
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.staticInvokeType is FunctionType) {
      _check(
        arguments: node.argumentList.arguments,
        errorNode: node,
      );
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _check(
      arguments: [node.index],
      errorNode: node.leftBracket,
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.inConstantContext) return;
    _check(
      arguments: node.argumentList.arguments,
      errorNode: node.constructorName,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(
      arguments: node.argumentList.arguments,
      errorNode: node.methodName,
    );
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _check(
      arguments: node.argumentList.arguments,
      errorNode: node.constructorName ?? node.thisKeyword,
    );
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _check(
      arguments: node.argumentList.arguments,
      errorNode: node.constructorName ?? node.superKeyword,
    );
  }

  void _check({
    required List<Expression> arguments,
    required SyntacticEntity errorNode,
  }) {
    for (var argument in arguments) {
      var parameter = argument.staticParameterElement;
      if (parameter != null && parameter.hasMustBeConst) {
        Expression resolvedArgument;
        if (parameter.isNamed) {
          resolvedArgument = (argument as NamedExpression).expression;
        } else {
          resolvedArgument = argument;
        }
        if (resolvedArgument is Identifier) {
          var staticElement = resolvedArgument.staticElement;
          if (staticElement != null &&
              staticElement.nonSynthetic is ConstVariableElement) {
            return;
          }
        }
        if (resolvedArgument.accept(_constantEvaluator) ==
            ConstantEvaluator.NOT_A_CONSTANT) {
          _errorReporter.atNode(
            argument,
            WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER,
            arguments: [parameter.name],
          );
        }
      }
    }
  }
}
