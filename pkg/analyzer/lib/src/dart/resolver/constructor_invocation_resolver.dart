// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [ConstructorInvocation] and
/// [DotShorthandConstructorInvocation2] nodes.
class ConstructorInvocationResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  ConstructorInvocationResolver(this._resolver);

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
    var dotShorthandContextType = switch (shorthandContext) {
      ValidDotShorthandContextResolutionImpl(:var lookupType) => lookupType,
      InvalidDotShorthandContextResolutionImpl() => InvalidTypeImpl.instance,
    };

    if (shorthandContext case ValidDotShorthandContextResolutionImpl(
      lookupType: InterfaceTypeImpl(element: var contextElement),
    )) {
      // This branch will be true if we're resolving an explicitly marked
      // const constructor invocation. Other shorthand constructor invocations
      // already have an element selected from the parsed invocation head.
      if (node.element == null) {
        if (contextElement.getNamedConstructor(node.name.lexeme)
            case ConstructorElementImpl element?
            when element.isAccessibleIn(_resolver.definingLibrary)) {
          node.element = element;
        } else {
          _resolver.diagnosticReporter.report(
            diag.constWithUndefinedConstructor
                .withArguments(
                  className: contextElement.displayName,
                  constructorName: node.name.lexeme,
                )
                .at(node.name),
          );
        }
      }

      var typeArguments = node.typeArguments;
      var constructorElement = node.element;
      if (contextElement is ClassElementImpl &&
          contextElement.isAbstract &&
          constructorElement != null &&
          !constructorElement.isFactory) {
        _resolver.diagnosticReporter.report(
          diag.instantiateAbstractClass.at(node),
        );
      } else if (typeArguments != null) {
        _resolver.diagnosticReporter.report(
          diag.wrongNumberOfTypeArgumentsDotShorthandConstructor
              .withArguments(
                className: contextElement.displayName,
                constructorName: node.name.lexeme,
              )
              .at(typeArguments),
        );
      }
    } else {
      _resolver.diagnosticReporter.report(
        diag.dotShorthandMissingContext.at(node),
      );
    }

    _resolveDotShorthandConstructorInvocation(
      node,
      contextType: contextType,
      dotShorthandContextType: dotShorthandContextType,
    );
  }

  void _resolveConstructorInvocation(
    ConstructorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    var constructorReference = node.constructorReference;
    var typeReference = constructorReference.typeReference;
    if (constructorReference.selector case var selector?
        when typeReference.type is FunctionTypeImpl) {
      var aliasName = switch (typeReference.importPrefix) {
        var prefix? => '${prefix.name.lexeme}.${typeReference.name.lexeme}',
        _ => typeReference.name.lexeme,
      };
      _resolver.diagnosticReporter.report(
        diag.undefinedMethodOnFunctionType
            .withArguments(
              methodName: selector.name2.lexeme,
              functionTypeAliasName: aliasName,
            )
            .at(selector.name2),
      );
    }
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      typeElement: constructorReference.typeReference.element,
      constructorName: constructorReference.selector?.name2,
      definingLibrary: _resolver.definingLibrary,
    );
    constructorReference.element = elementToInfer?.element;
    _resolver.elementResolver.visitConstructorInvocation(node);
    var target = elementToInfer == null
        ? null
        : InvocationTargetConstructorElement(
            elementToInfer.element,
            // TODO(paulberry): eliminate this cast by changing the type of
            // `ConstructorElementToInfer.asType`.
            elementToInfer.asType as FunctionTypeImpl,
          );
    ConstructorInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: target,
    ).resolveInvocation();
    node.recordStaticType(
      typeReference.type is FunctionTypeImpl
          ? InvalidTypeImpl.instance
          : typeReference.type!,
      resolver: _resolver,
    );
    _resolver.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  void _resolveDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation2Impl node, {
    required TypeImpl contextType,
    required TypeImpl dotShorthandContextType,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    _resolver.elementResolver.visitDotShorthandConstructorInvocation2(node);
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      typeElement: dotShorthandContextType.element,
      constructorName: node.name,
      definingLibrary: _resolver.definingLibrary,
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
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: target,
    ).resolveInvocation();
    node.recordStaticType(returnType, resolver: _resolver);
    _resolver.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }
}
