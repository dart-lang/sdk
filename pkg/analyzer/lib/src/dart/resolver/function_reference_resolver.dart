// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [FunctionReference] nodes.
///
/// This resolver is responsible for writing a given [FunctionReference] as a
/// [ConstructorReference] or as a [TypeLiteral], depending on how a function
/// reference's `function` resolves.
class FunctionReferenceResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  FunctionReferenceResolver(this._resolver);

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  void resolve(FunctionReferenceImpl node) {
    var function = node.function;
    node.typeArguments?.accept(_resolver);

    if (function is SimpleIdentifierImpl) {
      var element = _resolver.nameScope.lookup(function.name).getter;
      if (element is ExecutableElement) {
        function.staticElement = element;
        _resolve(node: node, rawType: element.type);
        return;
      } else if (element is VariableElement) {
        var functionType = element.type;
        if (functionType is FunctionType) {
          function.accept(_resolver);
          _resolve(node: node, rawType: functionType);
          return;
        }
      }
    }

    // TODO(srawlins): Handle `function` being a [SuperExpression].

    if (function is PrefixedIdentifierImpl) {
      var prefixElement =
          _resolver.nameScope.lookup(function.prefix.name).getter;
      if (prefixElement is PrefixElement) {
        var nameNode = function.identifier;
        var name = nameNode.name;
        _resolveReceiverPrefix(node, prefixElement, nameNode, name);
        return;
      }

      if (prefixElement is ClassElement) {
        // TODO(srawlins): Rewrite `node` as a [TypeLiteral], then resolve the
        // [TypeLiteral] instead of `function`.
        function.accept(_resolver);
        node.staticType = DynamicTypeImpl.instance;
        return;
      } else if (prefixElement is TypeAliasElement) {
        var aliasedType = prefixElement.aliasedType;
        if (aliasedType is InterfaceType) {
          // TODO(srawlins): Rewrite `node` as a [TypeLiteral], then resolve
          // the [TypeLiteral] instead of `function`.
          function.accept(_resolver);
          node.staticType = DynamicTypeImpl.instance;
          return;
        }
      } else if (prefixElement is ExtensionElement) {
        // TODO(srawlins): Rewrite `node` as a [TypeLiteral], then resolve the
        // [TypeLiteral] instead of `function`.
        function.accept(_resolver);
        node.staticType = DynamicTypeImpl.instance;
        return;
      }

      ResolutionResult resolveTypeProperty(DartType prefixType) {
        return _resolver.typePropertyResolver.resolve(
          receiver: function.prefix,
          receiverType: prefixType,
          name: function.identifier.name,
          propertyErrorEntity: function.identifier,
          nameErrorEntity: function,
        );
      }

      function.prefix.staticElement = prefixElement;
      ExecutableElement? methodElement;
      if (prefixElement is VariableElement) {
        var prefixType = prefixElement.type;
        function.prefix.staticType = prefixType;
        methodElement = resolveTypeProperty(prefixType).getter;
      } else if (prefixElement is PropertyAccessorElement) {
        var prefixType = prefixElement.returnType;
        function.prefix.staticType = prefixType;
        methodElement = resolveTypeProperty(prefixType).getter;
      }
      if (methodElement is MethodElement) {
        _resolveFunctionReferenceMethod(node: node, function: function);
        return;
      }

      // TODO(srawlins): Check for [ConstructorElement] and rewrite to
      // [ConstructorReference] before resolving.
      function.accept(_resolver);
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    if (function is PropertyAccess) {
      function.accept(_resolver);
      DartType functionType = function.typeOrThrow;

      if (functionType is FunctionType) {
        _resolve(node: node, rawType: function.staticType as FunctionType);
        return;
      }

      // TODO(srawlins): Handle type variables bound to function type, like
      // `T extends void Function<U>(U)`.
    }

    // TODO(srawlins): Enumerate and handle all cases that fall through to
    // here; ultimately it should just be a case of "unknown identifier."
    function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  /// Resolves [node]'s static type, as an instantiated function type, and type
  /// argument types, using [rawType] as the uninstantiated function type.
  void _resolve({
    required FunctionReferenceImpl node,
    required FunctionType rawType,
  }) {
    // `node.typeArguments`, coming from the parser, is never null.
    var typeArgumentList = node.typeArguments!;
    var typeParameters = rawType.typeFormals;

    List<DartType> typeArguments;
    if (typeArgumentList.arguments.length != typeParameters.length) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
        typeArgumentList,
        [
          rawType,
          typeParameters.length,
          typeArgumentList.arguments.length,
        ],
      );
      typeArguments = List.filled(
        typeParameters.length,
        DynamicTypeImpl.instance,
      );
    } else {
      typeArguments = typeArgumentList.arguments
          .map((typeArgument) => typeArgument.typeOrThrow)
          .toList();
    }

    var invokeType = rawType.instantiate(typeArguments);
    node.typeArgumentTypes = typeArguments;
    node.staticType = invokeType;

    // TODO(srawlins): Verify that type arguments conform to bounds. This will
    // probably be done later, not in this resolution phase.
  }

  void _resolveFunctionReferenceMethod({
    required FunctionReferenceImpl node,
    required PrefixedIdentifier function,
  }) {
    function.accept(_resolver);
    var receiver = function.prefix;
    var receiverType = receiver.staticType;
    if (receiverType == null) {
      // TODO(srawlins): Handle this situation; see
      //  `test_staticMethod_explicitReceiver` test case.
      node.staticType = DynamicTypeImpl.instance;
      return;
    }
    var nameNode = function.identifier;
    var name = nameNode.name;
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name,
      propertyErrorEntity: nameNode,
      nameErrorEntity: nameNode,
    );

    var target = result.getter;
    if (target != null) {
      // TODO(srawlins): Set static type on `nameNode`?

      _resolve(
        node: node,
        rawType: function.staticType as FunctionType,
      );
      return;
    }

    // TODO(srawlins): Report unresolved identifier.
    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolveReceiverPrefix(
    FunctionReferenceImpl node,
    PrefixElement prefix,
    SimpleIdentifierImpl nameNode,
    String name,
  ) {
    // TODO(srawlins): Handle `loadLibrary`, as in `p.loadLibrary<int>;`.

    var element = prefix.scope.lookup(name).getter;
    element = _resolver.toLegacyElement(element);
    nameNode.staticElement = element;

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];

      // TODO(srawlins): Add a resolution test for this case.
    }

    if (element is ExecutableElement) {
      var function = node.function;
      function.accept(_resolver);
      return _resolve(
          node: node, rawType: function.typeOrThrow as FunctionType);
    }

    // TODO(srawlins): Handle prefixed constructor references and type literals.

    // TODO(srawlins): Report undefined prefixed identifier.

    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }
}
