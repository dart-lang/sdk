// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/static_namespace.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// A resolver for [ConstructorInvocation] and
/// [DotShorthandConstructorInvocation2] nodes.
class ConstructorInvocationResolver {
  /// The type analyzer driving this participant.
  final TypeAnalyzer _typeAnalyzer;

  new(this._typeAnalyzer);

  void resolve(
    ConstructorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    _resolveConstructorInvocation(node, contextType: contextType);
  }

  /// Resolves a [DotShorthandConstructorInvocation2] node.
  void resolveDotShorthand(
    DotShorthandConstructorInvocation2Impl node, {
    required TypeImpl contextType,
    required DotShorthandContextResolutionImpl shorthandContext,
  }) {
    var declaration = switch (shorthandContext) {
      MissingDotShorthandContextResolutionImpl() => null,
      InvalidDotShorthandContextResolutionImpl() => null,
      ValidDotShorthandContextResolutionImpl(:var declaration) => declaration,
    };

    if (declaration != null) {
      // This branch will be true if we're resolving an explicitly marked
      // const constructor invocation. Other shorthand constructor invocations
      // already have an element selected from the parsed invocation head.
      if (node.element == null) {
        if (declaration.getNamedConstructor(node.name.lexeme)
            case ConstructorElementImpl element?
            when element.isAccessibleIn(_typeAnalyzer.definingLibrary)) {
          node.element = element;
        } else {
          _typeAnalyzer.diagnosticReporter.report(
            diag.constWithUndefinedConstructor
                .withArguments(
                  className: declaration.displayName,
                  constructorName: node.name.lexeme,
                )
                .at(node.name),
          );
        }
      }

      var typeArguments = node.typeArguments;
      var constructorElement = node.element;
      if (declaration is ClassElementImpl &&
          declaration.isAbstract &&
          constructorElement != null &&
          !constructorElement.isFactory) {
        _typeAnalyzer.diagnosticReporter.report(
          diag.instantiateAbstractClass.at(node),
        );
      } else if (typeArguments != null) {
        _typeAnalyzer.diagnosticReporter.report(
          diag.wrongNumberOfTypeArgumentsDotShorthandConstructor
              .withArguments(
                className: declaration.displayName,
                constructorName: node.name.lexeme,
              )
              .at(typeArguments),
        );
      }
    } else {
      _typeAnalyzer.diagnosticReporter.report(
        diag.dotShorthandMissingContext.at(node),
      );
    }

    _resolveDotShorthandConstructorInvocation(
      node,
      contextType: contextType,
      declaration: declaration,
    );
  }

  void _resolveConstructorInvocation(
    ConstructorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    var constructorReference = node.constructorReference;
    var typeReference = constructorReference.typeReference;
    // `X<T>.name()`, where `X` aliases a type that is not an interface type,
    // has no constructor to call. An invalid type, such as of an alias that
    // expands to a type parameter, is already reported.
    if (constructorReference.selector case var selector?
        when typeReference.type is! InvalidTypeImpl &&
            StaticNamespace.of(typeReference.element) is EmptyStaticNamespace &&
            !selector.name2.isSynthetic) {
      _typeAnalyzer.diagnosticReporter.report(
        diag.newWithUndefinedConstructorNoConstructors
            .withArguments(
              name: selector.name2.lexeme,
              aliasName: typeReference.qualifiedName,
              typeLiteral: typeReference.toSource(),
            )
            .at(selector.name2),
      );
    }
    var elementToInfer = _typeAnalyzer.inferenceHelper
        .constructorElementToInfer(
          typeElement: constructorReference.typeReference.element,
          constructorName: constructorReference.selector?.name2,
          definingLibrary: _typeAnalyzer.definingLibrary,
        );
    constructorReference.element = elementToInfer?.element;
    _typeAnalyzer.elementResolver.visitConstructorInvocation(node);
    var target = elementToInfer == null
        ? null
        : InvocationTargetConstructorElement(
            elementToInfer.element,
            // TODO(paulberry): eliminate this cast by changing the type of
            // `ConstructorElementToInfer.asType`.
            elementToInfer.asType as FunctionTypeImpl,
          );
    ConstructorInvocationInferrer(
      typeAnalyzer: _typeAnalyzer,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: target,
    ).resolveInvocation();
    // Read after inference, which replaces the type with its inferred type
    // arguments.
    var type = typeReference.type!;
    node.recordStaticType(
      type is InterfaceTypeImpl ? type : InvalidTypeImpl.instance,
      typeAnalyzer: _typeAnalyzer,
    );
    _typeAnalyzer.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  void _resolveDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation2Impl node, {
    required TypeImpl contextType,
    required InterfaceElementImpl? declaration,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    _typeAnalyzer.elementResolver.visitDotShorthandConstructorInvocation2(node);
    var elementToInfer = _typeAnalyzer.inferenceHelper
        .constructorElementToInfer(
          typeElement: declaration,
          constructorName: node.name,
          definingLibrary: _typeAnalyzer.definingLibrary,
        );
    var target = elementToInfer == null
        ? null
        : InvocationTargetConstructorElement(
            elementToInfer.element,
            // TODO(paulberry): eliminate this cast by changing the type of
            // `ConstructorElementToInfer.asType`.
            elementToInfer.asType as FunctionTypeImpl,
          );
    var returnType = DotShorthandConstructorInvocationInferrer(
      typeAnalyzer: _typeAnalyzer,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: target,
    ).resolveInvocation();
    node.recordStaticType(returnType, typeAnalyzer: _typeAnalyzer);
    _typeAnalyzer.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }
}
