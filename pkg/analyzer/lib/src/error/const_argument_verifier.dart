// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';

/// Checks if the arguments for a parameter annotated with `@mustBeConst` are
/// actually constant.
class ConstArgumentsVerifier extends SimpleAstVisitor<void> {
  final DiagnosticReporter _diagnosticReporter;

  ConstArgumentsVerifier(this._diagnosticReporter);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.EQ) {
      _check(arguments: [node.rightHandSide], errorNode: node.operator);
    } else if (node
            .rightHandSide
            .correspondingParameter
            ?.metadata
            .hasMustBeConst ??
        false) {
      // If the operator is not `=`, then the argument cannot be const, as it
      // depends on the value of the left hand side.
      _diagnosticReporter.atNode(
        node.rightHandSide,
        WarningCode.nonConstArgumentForConstParameter,
        arguments: [node.rightHandSide],
      );
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _check(arguments: [node.rightOperand], errorNode: node.operator);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.staticInvokeType is FunctionType) {
      _check(arguments: node.argumentList.arguments, errorNode: node);
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _check(arguments: [node.index], errorNode: node.leftBracket);
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
    _check(arguments: node.argumentList.arguments, errorNode: node.methodName);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
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
      var parameter = argument.correspondingParameter;
      if (parameter == null) {
        continue;
      }

      var parameterName = parameter.name;
      if (parameterName == null) {
        continue;
      }

      if (parameter.metadata.hasMustBeConst) {
        Expression resolvedArgument;
        if (parameter.isNamed) {
          resolvedArgument = (argument as NamedExpression).expression;
        } else {
          resolvedArgument = argument;
        }
        if (!_isConst(resolvedArgument)) {
          _diagnosticReporter.atNode(
            argument,
            WarningCode.nonConstArgumentForConstParameter,
            arguments: [parameterName],
          );
        }
      }
    }
  }

  bool _isConst(Expression expression) {
    if (expression.inConstantContext) {
      return true;
    } else if (expression is InstanceCreationExpression && expression.isConst) {
      return true;
    } else if (expression is Literal) {
      return switch (expression) {
        BooleanLiteral() => true,
        DoubleLiteral() => true,
        IntegerLiteral() => true,
        NullLiteral() => true,
        SimpleStringLiteral() => true,
        AdjacentStrings() => true,
        SymbolLiteral() => true,
        RecordLiteral() => expression.isConst,
        TypedLiteral() => expression.isConst,
        // TODO(mosum): Expand the logic to check if the individual interpolation elements are const.
        StringInterpolation() => false,
      };
    } else if (expression is Identifier) {
      var element = expression.element;
      switch (element) {
        case GetterElement():
          return element.variable.isConst;
        case VariableElement():
          return element.isConst;
      }
    }
    return false;
  }
}
