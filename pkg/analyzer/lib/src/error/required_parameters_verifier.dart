// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Checks for missing arguments for required named parameters.
class RequiredParametersVerifier extends SimpleAstVisitor<void> {
  final ErrorReporter _errorReporter;

  RequiredParametersVerifier(this._errorReporter);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var type = node.staticInvokeType;
    if (type is FunctionType) {
      _check(
        type.parameters,
        node.argumentList,
        node,
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(
      node.staticElement?.parameters,
      node.argumentList,
      node.constructorName,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(
      _executableElement(node.methodName.staticElement)?.parameters,
      node.argumentList,
      node.methodName,
    );
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _check(
      _executableElement(node.staticElement)?.parameters,
      node.argumentList,
      node,
    );
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _check(
      _executableElement(node.staticElement)?.parameters,
      node.argumentList,
      node,
    );
  }

  void _check(
    List<ParameterElement> parameters,
    ArgumentList argumentList,
    AstNode node,
  ) {
    if (parameters == null) {
      return;
    }

    for (ParameterElement parameter in parameters) {
      if (parameter.isRequiredNamed) {
        String parameterName = parameter.name;
        if (!_containsNamedExpression(argumentList, parameterName)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT,
            node,
            [parameterName],
          );
        }
      }
      if (parameter.isOptionalNamed) {
        ElementAnnotationImpl annotation = _requiredAnnotation(parameter);
        if (annotation != null) {
          String parameterName = parameter.name;
          if (!_containsNamedExpression(argumentList, parameterName)) {
            String reason = _requiredReason(annotation);
            if (reason != null) {
              _errorReporter.reportErrorForNode(
                HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS,
                node,
                [parameterName, reason],
              );
            } else {
              _errorReporter.reportErrorForNode(
                HintCode.MISSING_REQUIRED_PARAM,
                node,
                [parameterName],
              );
            }
          }
        }
      }
    }
  }

  static bool _containsNamedExpression(ArgumentList args, String name) {
    NodeList<Expression> arguments = args.arguments;
    for (int i = arguments.length - 1; i >= 0; i--) {
      Expression expression = arguments[i];
      if (expression is NamedExpression) {
        if (expression.name.label.name == name) {
          return true;
        }
      }
    }
    return false;
  }

  static ExecutableElement _executableElement(Element element) {
    if (element is ExecutableElement) {
      return element;
    } else {
      return null;
    }
  }

  static ElementAnnotationImpl _requiredAnnotation(ParameterElement element) {
    return element.metadata.firstWhere(
      (e) => e.isRequired,
      orElse: () => null,
    );
  }

  static String _requiredReason(ElementAnnotationImpl annotation) {
    DartObject constantValue = annotation.computeConstantValue();
    String value = constantValue?.getField('reason')?.toStringValue();
    return (value == null || value.isEmpty) ? null : value;
  }
}
