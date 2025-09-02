// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

/// Checks for missing arguments for required named parameters.
class RequiredParametersVerifier extends SimpleAstVisitor<void> {
  final DiagnosticReporter _errorReporter;

  RequiredParametersVerifier(this._errorReporter);

  @override
  void visitAnnotation(Annotation node) {
    var element = node.element;
    var argumentList = node.arguments;
    if (element is ConstructorElement && argumentList != null) {
      var errorNode = node.constructorIdentifier ?? node.classIdentifier;
      if (errorNode != null) {
        _check(
          parameters: element.formalParameters,
          arguments: argumentList.arguments,
          errorEntity: errorNode,
        );
      }
    }
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var constructorElement = node.constructorName.element;
    if (constructorElement is ConstructorElement) {
      _check(
        parameters: constructorElement.formalParameters,
        arguments: node.argumentList.arguments,
        errorEntity: node.constructorName,
      );
    }
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _check(
      parameters: _executableElement(node.memberName.element)?.formalParameters,
      arguments: node.argumentList.arguments,
      errorEntity: node.memberName,
    );
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _check(
      parameters: node.constructorElement?.formalParameters,
      arguments: node.arguments?.argumentList.arguments ?? <Expression>[],
      errorEntity: node.name,
    );
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var type = node.staticInvokeType;
    if (type is FunctionType) {
      _check(
        parameters: type.formalParameters,
        arguments: node.argumentList.arguments,
        errorEntity: node,
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(
      parameters: node.constructorName.element?.formalParameters,
      arguments: node.argumentList.arguments,
      errorEntity: node.constructorName,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == MethodElement.CALL_METHOD_NAME) {
      var targetType = node.realTarget?.staticType;
      if (targetType is FunctionType) {
        _check(
          parameters: targetType.formalParameters,
          arguments: node.argumentList.arguments,
          errorEntity: node.argumentList,
        );
        return;
      }
    }

    _check(
      parameters: _executableElement(node.methodName.element)?.formalParameters,
      arguments: node.argumentList.arguments,
      errorEntity: node.methodName,
    );
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _check(
      parameters: _executableElement(node.element)?.formalParameters,
      arguments: node.argumentList.arguments,
      errorEntity: node,
    );
  }

  @override
  void visitSuperConstructorInvocation(
    SuperConstructorInvocation node, {
    ConstructorElement? enclosingConstructor,
  }) {
    _check(
      parameters: _executableElement(node.element)?.formalParameters,
      enclosingConstructor: enclosingConstructor,
      arguments: node.argumentList.arguments,
      errorEntity: node,
    );
  }

  void _check({
    required List<FormalParameterElement>? parameters,
    ConstructorElement? enclosingConstructor,
    required List<Expression> arguments,
    required SyntacticEntity errorEntity,
  }) {
    if (parameters == null) {
      return;
    }

    for (FormalParameterElement parameter in parameters) {
      if (parameter.isRequiredNamed) {
        String parameterName = parameter.name!;
        if (!_containsNamedExpression(
          enclosingConstructor,
          arguments,
          parameterName,
        )) {
          _containsNamedExpression(
            enclosingConstructor,
            arguments,
            parameterName,
          );
          _errorReporter.atEntity(
            errorEntity,
            CompileTimeErrorCode.missingRequiredArgument,
            arguments: [parameterName],
          );
        }
      }
      if (parameter.isOptionalNamed) {
        var annotation = _requiredAnnotation(parameter);
        if (annotation != null) {
          String parameterName = parameter.name!;
          if (!_containsNamedExpression(
            enclosingConstructor,
            arguments,
            parameterName,
          )) {
            var reason = annotation.getReason(strictCasts: true);
            if (reason != null) {
              _errorReporter.atEntity(
                errorEntity,
                WarningCode.missingRequiredParamWithDetails,
                arguments: [parameterName, reason],
              );
            } else {
              _errorReporter.atEntity(
                errorEntity,
                WarningCode.missingRequiredParam,
                arguments: [parameterName],
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
      return enclosingConstructor.formalParameters.any(
        (e) => e is SuperFormalParameterElement && e.isNamed && e.name == name,
      );
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

  static _RequiredAnnotation? _requiredAnnotation(
    FormalParameterElement element,
  ) {
    var annotation =
        element.metadata.annotations.firstWhereOrNull((e) => e.isRequired)
            as ElementAnnotationImpl?;
    if (annotation != null) {
      return _RequiredAnnotation(annotation);
    }

    if (element.baseElement.isRequiredNamed) {
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

  String? getReason({required bool strictCasts}) {
    if (annotation == null) {
      return null;
    }

    var constantValue = annotation!.computeConstantValue();
    var value = constantValue?.getField('reason')?.toStringValue();
    return (value == null || value.isEmpty) ? null : value;
  }
}

/// The annotation should be a constructor invocation.
///
// TODO(scheglov): This is not ideal.
// Ideally when resolving an annotation we should restructure it into
// specific components - an import prefix, top-level declaration, getter,
// constructor, etc. So that later in the analyzer, or in clients, we
// don't have to identify it again and again.
extension _InstantiatedAnnotation on Annotation {
  SimpleIdentifier? get classIdentifier {
    assert(arguments != null);
    var name = this.name;
    if (name is SimpleIdentifier) {
      return _ifClassElement(name);
    } else if (name is PrefixedIdentifier) {
      return _ifClassElement(name.identifier);
    }
    return null;
  }

  SimpleIdentifier? get constructorIdentifier {
    assert(arguments != null);
    var constructorName = _ifConstructorElement(this.constructorName);
    if (constructorName != null) {
      return constructorName;
    }

    var name = this.name;
    if (name is SimpleIdentifier) {
      return _ifConstructorElement(name);
    } else if (name is PrefixedIdentifier) {
      return _ifConstructorElement(name.identifier);
    }

    return null;
  }

  static SimpleIdentifier? _ifClassElement(SimpleIdentifier? node) {
    return node?.element is InterfaceElement ? node : null;
  }

  static SimpleIdentifier? _ifConstructorElement(SimpleIdentifier? node) {
    return node?.element is ConstructorElement ? node : null;
  }
}
