// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

/// Checks for missing arguments for required named parameters.
class RequiredParametersVerifier extends SimpleAstVisitor<void> {
  final ErrorReporter _errorReporter;

  RequiredParametersVerifier(this._errorReporter);

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _check(
      parameters: node.constructorElement?.parameters,
      arguments: node.arguments?.argumentList.arguments ?? <Expression>[],
      errorNode: node.name,
    );
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var type = node.staticInvokeType;
    if (type is FunctionType) {
      _check(
        parameters: type.parameters,
        arguments: node.argumentList.arguments,
        errorNode: node,
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(
      parameters: node.constructorName.staticElement?.parameters,
      arguments: node.argumentList.arguments,
      errorNode: node.constructorName,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == FunctionElement.CALL_METHOD_NAME) {
      var targetType = node.realTarget?.staticType;
      if (targetType is FunctionType) {
        _check(
          parameters: targetType.parameters,
          arguments: node.argumentList.arguments,
          errorNode: node.argumentList,
        );
        return;
      }
    }

    _check(
      parameters: _executableElement(node.methodName.staticElement)?.parameters,
      arguments: node.argumentList.arguments,
      errorNode: node.methodName,
    );
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _check(
      parameters: _executableElement(node.staticElement)?.parameters,
      arguments: node.argumentList.arguments,
      errorNode: node,
    );
  }

  @override
  void visitSuperConstructorInvocation(
    SuperConstructorInvocation node, {
    ConstructorElement? enclosingConstructor,
  }) {
    _check(
      parameters: _executableElement(node.staticElement)?.parameters,
      enclosingConstructor: enclosingConstructor,
      arguments: node.argumentList.arguments,
      errorNode: node,
    );
  }

  void _check({
    required List<ParameterElement>? parameters,
    ConstructorElement? enclosingConstructor,
    required List<Expression> arguments,
    required AstNode errorNode,
  }) {
    if (parameters == null) {
      return;
    }

    for (ParameterElement parameter in parameters) {
      if (parameter.isRequiredNamed) {
        String parameterName = parameter.name;
        if (!_containsNamedExpression(
            enclosingConstructor, arguments, parameterName)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT,
            errorNode,
            [parameterName],
          );
        }
      }
      if (parameter.isOptionalNamed) {
        var annotation = _requiredAnnotation(parameter);
        if (annotation != null) {
          String parameterName = parameter.name;
          if (!_containsNamedExpression(
              enclosingConstructor, arguments, parameterName)) {
            var reason = annotation.reason;
            if (reason != null) {
              _errorReporter.reportErrorForNode(
                HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS,
                errorNode,
                [parameterName, reason],
              );
            } else {
              _errorReporter.reportErrorForNode(
                HintCode.MISSING_REQUIRED_PARAM,
                errorNode,
                [parameterName],
              );
            }
          }
        }
      }
    }
  }

  static bool _containsNamedExpression(
    ConstructorElement? enclosingConstructor,
    List<Expression> arguments,
    String name,
  ) {
    for (int i = arguments.length - 1; i >= 0; i--) {
      Expression expression = arguments[i];
      if (expression is NamedExpression) {
        if (expression.name.label.name == name) {
          return true;
        }
      }
    }

    if (enclosingConstructor != null) {
      return enclosingConstructor.parameters.any((e) =>
          e is SuperFormalParameterElement && e.isNamed && e.name == name);
    }

    return false;
  }

  static ExecutableElement? _executableElement(Element? element) {
    if (element is ExecutableElement) {
      return element;
    } else {
      return null;
    }
  }

  static _RequiredAnnotation? _requiredAnnotation(ParameterElement element) {
    var annotation = element.metadata.firstWhereOrNull((e) => e.isRequired)
        as ElementAnnotationImpl?;
    if (annotation != null) {
      return _RequiredAnnotation(annotation);
    }

    if (element.declaration.isRequiredNamed) {
      return _RequiredAnnotation(annotation);
    }

    return null;
  }
}

class _RequiredAnnotation {
  /// The instance of `@required` annotation.
  /// If `null`, then the parameter is `required` in null safety.
  final ElementAnnotationImpl? annotation;

  _RequiredAnnotation(this.annotation);

  String? get reason {
    if (annotation == null) {
      return null;
    }

    var constantValue = annotation!.computeConstantValue();
    var value = constantValue?.getField('reason')?.toStringValue();
    return (value == null || value.isEmpty) ? null : value;
  }
}
