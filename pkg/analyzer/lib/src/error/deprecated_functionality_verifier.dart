// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';

class DeprecatedFunctionalityVerifier {
  final DiagnosticReporter _diagnosticReporter;

  final LibraryElement _currentLibrary;

  DeprecatedFunctionalityVerifier(
    this._diagnosticReporter,
    this._currentLibrary,
  );

  void classDeclaration(ClassDeclaration node) {
    _checkForDeprecatedExtend(node.extendsClause?.superclass);
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
    _checkForDeprecatedSubclass(node.withClause?.mixinTypes);
  }

  void classTypeAlias(ClassTypeAlias node) {
    _checkForDeprecatedExtend(node.superclass);
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
  }

  void constructorName(ConstructorName node) {
    var interfaceElement = node.type.element;
    if (interfaceElement is! InterfaceElement) return;
    _checkForDeprecatedInstantiate(element: interfaceElement, errorNode: node);
  }

  void dotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var element = node.element;
    if (element is! ConstructorElement) return;
    _checkForDeprecatedOptional(
      element: element,
      argumentList: node.argumentList,
      errorEntity: node.constructorName,
    );
    _checkForDeprecatedInstantiate(
      element: element.enclosingElement,
      errorNode: node.constructorName,
    );
  }

  void dotShorthandInvocation(DotShorthandInvocation node) {
    var element = node.memberName.element;
    if (element is! ExecutableElement) return;
    _checkForDeprecatedOptional(
      element: element,
      argumentList: node.argumentList,
      errorEntity: node.memberName,
    );
  }

  void enumDeclaration(EnumDeclaration node) {
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
  }

  void instanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.element;
    if (constructor == null) return;
    _checkForDeprecatedOptional(
      element: constructor,
      argumentList: node.argumentList,
      errorEntity: node.constructorName,
    );
    var interfaceElement = node.constructorName.type.element;
    if (interfaceElement is! InterfaceElement) return;
    _checkForDeprecatedInstantiate(
      element: interfaceElement,
      errorNode: node.constructorName,
    );
  }

  void methodInvocation(MethodInvocation node) {
    var method = node.methodName.element;
    if (method is! ExecutableElement) return;
    if (method is LocalFunctionElement) return;
    _checkForDeprecatedOptional(
      element: method,
      argumentList: node.argumentList,
      errorEntity: node.methodName,
    );
  }

  void mixinDeclaration(MixinDeclaration node) {
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    // Not technically "implementing," but is similar enough for
    // `@Deprecated.implement` and `@Deprecated.subclass`.
    _checkForDeprecatedImplement(node.onClause?.superclassConstraints);
  }

  void redirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    var element = node.element;
    if (element is! ConstructorElement) return;
    _checkForDeprecatedOptional(
      element: element,
      argumentList: node.argumentList,
      errorEntity: node.constructorName ?? node.thisKeyword,
    );
  }

  void superConstructorInvocation(SuperConstructorInvocation node) {
    var constructor = node.element;
    if (constructor == null) return;
    _checkForDeprecatedOptional(
      element: constructor,
      argumentList: node.argumentList,
      errorEntity: node.constructorName ?? node.superKeyword,
    );
  }

  void _checkForDeprecatedExtend(NamedType? node) {
    if (node == null) return;
    var element = node.element;
    if (element == null) return;
    if (node.type?.element is InterfaceElement) {
      if (element.library == _currentLibrary) return;
      if (element.isDeprecatedWithKind('extend')) {
        _diagnosticReporter.atNode(
          node,
          WarningCode.deprecatedExtend,
          arguments: [element.name!],
        );
      } else if (element.isDeprecatedWithKind('subclass')) {
        _diagnosticReporter.atNode(
          node,
          WarningCode.deprecatedSubclass,
          arguments: [element.name!],
        );
      }
    }
  }

  void _checkForDeprecatedImplement(List<NamedType>? namedTypes) {
    if (namedTypes == null) return;
    for (var namedType in namedTypes) {
      var element = namedType.element;
      if (element == null) continue;
      if (element.library == _currentLibrary) continue;
      if (namedType.type?.element is InterfaceElement) {
        if (element.isDeprecatedWithKind('implement')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedImplement,
            arguments: [element.name!],
          );
        } else if (element.isDeprecatedWithKind('subclass')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedSubclass,
            arguments: [element.name!],
          );
        }
      }
    }
  }

  void _checkForDeprecatedInstantiate({
    required InterfaceElement element,
    required AstNode errorNode,
  }) {
    if (element.isDeprecatedWithKind('instantiate')) {
      _diagnosticReporter.atNode(
        errorNode,
        WarningCode.deprecatedInstantiate,
        arguments: [element.name!],
      );
    }
  }

  void _checkForDeprecatedMixin(WithClause? node) {
    if (node == null) return;
    for (var mixin in node.mixinTypes) {
      var element = mixin.type?.element;
      if (element is! InterfaceElement) continue;
      if (element.library == _currentLibrary) continue;
      if (element.isDeprecatedWithKind('mixin')) {
        _diagnosticReporter.atNode(
          mixin,
          WarningCode.deprecatedMixin,
          arguments: [element.name!],
        );
      }
    }
  }

  void _checkForDeprecatedOptional({
    required ExecutableElement element,
    required ArgumentList argumentList,
    required SyntacticEntity errorEntity,
  }) {
    var omittedParameters = element.formalParameters.toList();
    for (var argument in argumentList.arguments) {
      var parameter = argument.correspondingParameter;
      if (parameter == null) continue;
      omittedParameters.remove(parameter);
    }
    for (var parameter in omittedParameters) {
      if (parameter.isDeprecatedWithKind('optional')) {
        _diagnosticReporter.atEntity(
          errorEntity,
          WarningCode.deprecatedOptional,
          arguments: [parameter.name ?? '<unknown>'],
        );
      }
    }
  }

  void _checkForDeprecatedSubclass(List<NamedType>? namedTypes) {
    if (namedTypes == null) return;
    for (var namedType in namedTypes) {
      var element = namedType.element;
      if (element == null) continue;
      if (element.library == _currentLibrary) continue;
      if (namedType.type?.element is InterfaceElement) {
        if (element.isDeprecatedWithKind('subclass')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedSubclass,
            arguments: [element.name!],
          );
        }
      }
    }
  }
}
