// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';

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

  void constructorDeclaration(ConstructorDeclaration node) {
    _checkForDeprecatedOptionalSuperParameters(node);
    _checkForDeprecatedOptionalRedirectedParameters(node);

    // Check redirectiong constructor invocations in the initializer list.
    for (var redirectingConstructorInvocation
        in node.initializers.whereType<RedirectingConstructorInvocation>()) {
      var element = redirectingConstructorInvocation.element;
      if (element is! ConstructorElement) return;
      _checkForDeprecatedOptional(
        element: element,
        argumentList: redirectingConstructorInvocation.argumentList,
        errorEntity:
            redirectingConstructorInvocation.constructorName ??
            redirectingConstructorInvocation.thisKeyword,
      );
    }

    // TODO(srawlins): Detect omitted parameters in a redirecting factory
    // constructor.
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

  void _checkForDeprecatedExtend(NamedType? node) {
    if (node == null) return;
    var element = node.element;
    if (element == null) return;
    if (node.type?.element is InterfaceElement) {
      if (element.library == _currentLibrary) return;
      if (element.isDeprecatedWithKind('extend')) {
        _diagnosticReporter.report(
          diag.deprecatedExtend.withArguments(typeName: element.name!).at(node),
        );
      } else if (element.isDeprecatedWithKind('subclass')) {
        _diagnosticReporter.report(
          diag.deprecatedSubclass
              .withArguments(typeName: element.name!)
              .at(node),
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
          _diagnosticReporter.report(
            diag.deprecatedImplement
                .withArguments(typeName: element.name!)
                .at(namedType),
          );
        } else if (element.isDeprecatedWithKind('subclass')) {
          _diagnosticReporter.report(
            diag.deprecatedSubclass
                .withArguments(typeName: element.name!)
                .at(namedType),
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
      _diagnosticReporter.report(
        diag.deprecatedInstantiate
            .withArguments(typeName: element.name!)
            .at(errorNode),
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
        _diagnosticReporter.report(
          diag.deprecatedMixin.withArguments(typeName: element.name!).at(mixin),
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
        _diagnosticReporter.report(
          diag.deprecatedOptional
              .withArguments(parameterName: parameter.name ?? '<unknown>')
              .at(errorEntity),
        );
      }
    }
  }

  void _checkForDeprecatedOptionalRedirectedParameters(
    ConstructorDeclaration node,
  ) {
    if (node.redirectedConstructor?.element case var redirectedConstructor?) {
      var SourceRange(offset: errorOffset, length: errorLength) =
          node.errorRange;
      var positionalArgumentCount = node.parameters.parameters
          .where((p) => p.isPositional)
          .length;
      var namedArgumentNames = node.parameters.parameters
          .where((p) => p.isNamed)
          .map((p) => p.name?.lexeme)
          .nonNulls
          .toList();
      var redirectedConstructorPositionalParameterCount = 0;
      for (var parameter in redirectedConstructor.formalParameters) {
        if (parameter.isPositional) {
          redirectedConstructorPositionalParameterCount++;
        }
        if (!parameter.isOptional) continue;
        if (!parameter.isDeprecatedWithKind('optional')) continue;
        if (parameter.isPositional) {
          if (redirectedConstructorPositionalParameterCount <=
              positionalArgumentCount) {
            continue;
          }
        } else {
          if (namedArgumentNames.contains(parameter.name)) continue;
        }

        _diagnosticReporter.report(
          diag.deprecatedOptional
              .withArguments(parameterName: parameter.name ?? '<unknown>')
              .atOffset(offset: errorOffset, length: errorLength),
        );
      }
    }
  }

  void _checkForDeprecatedOptionalSuperParameters(ConstructorDeclaration node) {
    var superConstructorInvocations = node.initializers
        .whereType<SuperConstructorInvocation>();
    if (superConstructorInvocations.length > 1) {
      // Error reported elsewhere.
      return;
    }

    var VerifySuperFormalParametersResult(
      :positionalArgumentCount,
      :namedArgumentNames,
    ) = verifySuperFormalParameters(
      constructor: node,
      diagnosticReporter: _diagnosticReporter,
    );

    ConstructorElement superConstructor;
    List<Expression> superConstructorArguments;
    int errorOffset;
    int errorLength;

    if (superConstructorInvocations.isEmpty) {
      // The unnamed super-constructor will be invoked; report a warning for
      // each `@Deprecated.optional` parameter in that constructor without a
      // matching super-parameter.
      if (node.declaredFragment!.element.superConstructor
          case var unnamedSuperConstructor?) {
        superConstructor = unnamedSuperConstructor;
      } else {
        // Error reported elsewhere.
        return;
      }
      superConstructorArguments = [];
      SourceRange(offset: errorOffset, length: errorLength) = node.errorRange;
    } else {
      // Arguments may be passed to the super constructor _either_ in
      // `superConstructorInvocation` or via super-parameters.

      var superConstructorInvocation = superConstructorInvocations.single;
      if (superConstructorInvocation.element
          case var superInvocationConstructor?) {
        superConstructor = superInvocationConstructor;
      } else {
        // Error reported elsewhere.
        return;
      }

      superConstructorArguments =
          superConstructorInvocation.argumentList.arguments;

      var errorEntity =
          superConstructorInvocation.constructorName ??
          superConstructorInvocation.superKeyword;
      errorOffset = errorEntity.offset;
      errorLength = errorEntity.length;
    }

    var namedSuperConstructorArgumentNames = superConstructorArguments
        .whereType<NamedExpression>()
        .map((a) => a.name.label.name)
        .toList();
    var positionalSuperConstructorArgumentCount = superConstructorArguments
        .where((a) => a is! NamedExpression)
        .length;

    var superConstructorPositionalParameterCount = 0;
    for (var parameter in superConstructor.formalParameters) {
      if (parameter.isPositional) {
        superConstructorPositionalParameterCount++;
      }
      if (!parameter.isOptional) continue;
      if (!parameter.isDeprecatedWithKind('optional')) continue;
      if (parameter.isPositional) {
        if (superConstructorPositionalParameterCount <=
            positionalArgumentCount + positionalSuperConstructorArgumentCount) {
          continue;
        }
      } else {
        if (namedArgumentNames.contains(parameter.name)) continue;
        if (namedSuperConstructorArgumentNames.contains(parameter.name)) {
          continue;
        }
      }

      _diagnosticReporter.report(
        diag.deprecatedOptional
            .withArguments(parameterName: parameter.name ?? '<unknown>')
            .atOffset(offset: errorOffset, length: errorLength),
      );
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
          _diagnosticReporter.report(
            diag.deprecatedSubclass
                .withArguments(typeName: element.name!)
                .at(namedType),
          );
        }
      }
    }
  }
}
