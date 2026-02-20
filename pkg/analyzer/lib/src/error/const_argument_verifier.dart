// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Checks if the arguments for a parameter annotated with `@mustBeConst` are
/// actually constant.
class ConstArgumentsVerifier extends SimpleAstVisitor<void> {
  final DiagnosticReporter _diagnosticReporter;

  ConstArgumentsVerifier(this._diagnosticReporter);

  @override
  void visitAnonymousMethodInvocation(AnonymousMethodInvocation node) {
    var parameters = node.parameters?.parameters;
    if (parameters == null || parameters.isEmpty) {
      return;
    }

    var parameter = parameters.first;
    var element = parameter.declaredFragment?.element;
    if (element == null) {
      return;
    }

    if (element.metadata.hasMustBeConst) {
      var target = node.realTarget;
      if (!_isConst(target)) {
        _diagnosticReporter.report(
          diag.nonConstArgumentForConstParameter
              .withArguments(name: element.name!)
              .at(target),
        );
      }
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _check(arguments: [node.rightHandSide], errorNode: node.operator);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _check(arguments: [node.rightOperand], errorNode: node.operator);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _checkTearoff(node, node.constructorName.element);
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
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkTearoff(node.identifier, node.element);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkTearoff(node.propertyName, node.propertyName.element);
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
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is PropertyAccess && parent.propertyName == node) return;
    if (parent is PrefixedIdentifier && parent.identifier == node) return;
    if (parent is DotShorthandPropertyAccess && parent.propertyName == node) {
      return;
    }
    if (parent is DotShorthandInvocation && parent.memberName == node) return;
    if (parent is MethodInvocation && parent.methodName == node) return;
    _checkTearoff(node, node.element);
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
          _diagnosticReporter.report(
            diag.nonConstArgumentForConstParameter
                .withArguments(name: parameterName)
                .at(argument),
          );
        }
      }
    }
  }

  void _checkTearoff(Expression node, Element? element) {
    if (element is! ExecutableElement) return;
    if (!element.formalParameters.any((p) => p.metadata.hasMustBeConst)) return;
    if (_isTearOff(node)) {
      var name = element.name;
      if (name != null && name.isNotEmpty) {
        _diagnosticReporter.report(
          diag.tearoffWithMustBeConstParameter
              .withArguments(name: name)
              .at(node),
        );
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

  bool _isTearOff(Expression node) {
    if (node is ConstructorReference) return true;
    if (node is FunctionReference) return true;
    if (node is DotShorthandPropertyAccess) return true;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is ConstructorName) {
        parent = parent.parent;
      }
      while (parent is ParenthesizedExpression) {
        parent = parent.parent;
      }
      if (parent is InvocationExpression) return false;
      if (node.element is TopLevelFunctionElement) return true;
      if (node.element is MethodElement) return true;
    }
    return false;
  }
}
