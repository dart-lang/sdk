// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [InstanceCreationExpression] and
/// [DotShorthandConstructorInvocation] nodes.
///
/// This resolver is responsible for rewriting a given
/// [InstanceCreationExpression] as a [MethodInvocation] if the parsed
/// [ConstructorName]'s `type` resolves to a [FunctionReference] or
/// [ConstructorReference], instead of a [NamedType].
class InstanceCreationExpressionResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  InstanceCreationExpressionResolver(this._resolver);

  void resolve(
    InstanceCreationExpressionImpl node, {
    required TypeImpl contextType,
  }) {
    // The parser can parse certain code as [InstanceCreationExpression] when it
    // might be an invocation of a method on a [FunctionReference] or
    // [ConstructorReference]. In such a case, it is this resolver's
    // responsibility to rewrite. For example, given:
    //
    //     a.m<int>.apply();
    //
    // the parser will give an InstanceCreationExpression (`a.m<int>.apply()`)
    // with a name of `a.m<int>.apply` (ConstructorName) with a type of
    // `a.m<int>` (TypeName with a name of `a.m` (PrefixedIdentifier) and
    // typeArguments of `<int>`) and a name of `apply` (SimpleIdentifier). If
    // `a.m<int>` is actually a function reference, then the
    // InstanceCreationExpression needs to be rewritten as a MethodInvocation
    // with a target of `a.m<int>` (a FunctionReference) and a name of `apply`.
    if (node.keyword == null) {
      var typeNameTypeArguments = node.constructorName.type.typeArguments;
      if (typeNameTypeArguments != null) {
        // This could be a method call on a function reference or a constructor
        // reference.
        _resolveWithTypeNameWithTypeArguments(
          node,
          typeNameTypeArguments,
          contextType: contextType,
        );
        return;
      }
    }

    _resolveInstanceCreationExpression(node, contextType: contextType);
  }

  /// Resolves a [DotShorthandConstructorInvocation] node.
  void resolveDotShorthand(
    DotShorthandConstructorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    TypeImpl dotShorthandContextType = _resolver
        .getDotShorthandContext()
        .unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    dotShorthandContextType = _resolver.typeSystem.futureOrBase(
      dotShorthandContextType,
    );

    // TODO(kallentu): Support other context types
    if (dotShorthandContextType is InterfaceTypeImpl) {
      InterfaceElementImpl? contextElement = dotShorthandContextType.element;
      // This branch will be true if we're resolving an explicitly marked
      // const constructor invocation. It's completely unresolved, unlike a
      // rewritten [DotShorthandConstructorInvocation] that resulted from
      // resolving a [DotShorthandInvocation].
      if (node.element == null) {
        if (contextElement.getNamedConstructor(node.constructorName.name)
            case ConstructorElementImpl element?
            when element.isAccessibleIn(_resolver.definingLibrary)) {
          node.element = element;
        } else {
          _resolver.diagnosticReporter.atNode(
            node.constructorName,
            CompileTimeErrorCode.constWithUndefinedConstructor,
            arguments: [contextType, node.constructorName.name],
          );
        }
      }

      var typeArguments = node.typeArguments;
      if (contextElement is ClassElementImpl && contextElement.isAbstract) {
        var constructorElement = node.element;
        if (constructorElement != null && !constructorElement.isFactory) {
          _resolver.diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.instantiateAbstractClass,
          );
        }
      } else if (typeArguments != null) {
        _resolver.diagnosticReporter.atNode(
          typeArguments,
          CompileTimeErrorCode
              .wrongNumberOfTypeArgumentsDotShorthandConstructor,
          arguments: [
            dotShorthandContextType.getDisplayString(),
            node.constructorName.name,
          ],
        );
      }
    } else {
      _resolver.diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.dotShorthandMissingContext,
      );
    }

    _resolveDotShorthandConstructorInvocation(
      node,
      contextType: contextType,
      dotShorthandContextType: dotShorthandContextType,
    );
  }

  void _resolveDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocationImpl node, {
    required TypeImpl contextType,
    required TypeImpl dotShorthandContextType,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    _resolver.elementResolver.visitDotShorthandConstructorInvocation(node);
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      typeElement: dotShorthandContextType.element,
      constructorName: node.constructorName,
      definingLibrary: _resolver.definingLibrary,
    );
    var returnType =
        DotShorthandConstructorInvocationInferrer(
          resolver: _resolver,
          node: node,
          argumentList: node.argumentList,
          contextType: contextType,
          whyNotPromotedArguments: whyNotPromotedArguments,
        ).resolveInvocation(
          // TODO(paulberry): eliminate this cast by changing the type of
          // `ConstructorElementToInfer.asType`.
          rawType: elementToInfer?.asType as FunctionTypeImpl?,
        );
    node.recordStaticType(returnType, resolver: _resolver);
    _resolver.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  void _resolveInstanceCreationExpression(
    InstanceCreationExpressionImpl node, {
    required TypeImpl contextType,
  }) {
    var whyNotPromotedArguments = <WhyNotPromotedGetter>[];
    var constructorName = node.constructorName;
    constructorName.accept(_resolver);
    // Re-assign constructorName in case the node got replaced.
    constructorName = node.constructorName;
    _resolver.elementResolver.visitInstanceCreationExpression(node);
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      typeElement: constructorName.type.element,
      constructorName: node.constructorName.name,
      definingLibrary: _resolver.definingLibrary,
    );
    InstanceCreationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
    ).resolveInvocation(
      // TODO(paulberry): eliminate this cast by changing the type of
      // `ConstructorElementToInfer.asType`.
      rawType: elementToInfer?.asType as FunctionTypeImpl?,
    );
    node.recordStaticType(node.constructorName.type.type!, resolver: _resolver);
    _resolver.checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  /// Resolve [node] which has a [NamedType] with type arguments (given as
  /// [typeNameTypeArguments]).
  ///
  /// The instance creation expression may actually be a method call on a
  /// type-instantiated function reference or constructor reference.
  void _resolveWithTypeNameWithTypeArguments(
    InstanceCreationExpressionImpl node,
    TypeArgumentListImpl typeNameTypeArguments, {
    required TypeImpl contextType,
  }) {
    // TODO(srawlins): Lookup the name and potentially rewrite `node` as a
    // [MethodInvocation].
    _resolveInstanceCreationExpression(node, contextType: contextType);
  }
}
