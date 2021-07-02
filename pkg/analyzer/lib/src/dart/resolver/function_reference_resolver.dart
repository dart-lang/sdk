// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
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

  final bool _isNonNullableByDefault;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  FunctionReferenceResolver(this._resolver, this._isNonNullableByDefault)
      : _typeType = _resolver.typeProvider.typeType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  NullabilitySuffix get _nullabilitySuffixForTypeNames =>
      _isNonNullableByDefault ? NullabilitySuffix.none : NullabilitySuffix.star;

  void resolve(FunctionReferenceImpl node) {
    var function = node.function;
    node.typeArguments?.accept(_resolver);

    if (function is SimpleIdentifierImpl) {
      var element = _resolver.nameScope.lookup(function.name).getter;

      // Classes and type aliases are checked first so as to include a
      // PropertyAccess parent check, which does not need to be done for
      // functions.
      if (element is ClassElement || element is TypeAliasElement) {
        // A type-instantiated constructor tearoff like `C<int>.name` or
        // `prefix.C<int>.name` is initially represented as a [PropertyAccess]
        // with a [FunctionReference] target.
        if (node.parent is PropertyAccess) {
          _resolveConstructorReference(node);
          return;
        } else if (element is ClassElement) {
          function.staticElement = element;
          _resolveDirectTypeLiteral(node, function, element);
          return;
        } else if (element is TypeAliasElement) {
          function.staticElement = element;
          _resolveTypeAlias(node: node, element: element, typeAlias: function);
          return;
        }
      } else if (element is ExecutableElement) {
        function.staticElement = element;
        _resolve(node: node, name: element.name, rawType: element.type);
        return;
      } else if (element is VariableElement) {
        var functionType = element.type;
        if (functionType is FunctionType) {
          function.accept(_resolver);
          _resolve(node: node, name: element.name ?? '', rawType: functionType);
          return;
        }
      }
    }

    // TODO(srawlins): Handle `function` being a [SuperExpression].

    if (function is PrefixedIdentifierImpl) {
      var prefixElement =
          _resolver.nameScope.lookup(function.prefix.name).getter;
      if (prefixElement is PrefixElement) {
        _resolveReceiverPrefix(node, prefixElement, function);
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
        _resolveFunctionReferenceMethod(
            node: node, function: function, element: methodElement);
        return;
      }

      // TODO(srawlins): Need to report cases where [methodElement] is not
      // generic. The 'test_instanceGetter_explicitReceiver' test case needs to
      // be updated to handle this.

      function.accept(_resolver);
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    if (function is PropertyAccessImpl) {
      function.accept(_resolver);
      var target = function.target;
      DartType targetType;
      if (target is SuperExpressionImpl) {
        targetType = target.typeOrThrow;
      } else if (target is ThisExpressionImpl) {
        targetType = target.typeOrThrow;
      } else if (target is SimpleIdentifierImpl) {
        var targetElement = _resolver.nameScope.lookup(target.name).getter;
        if (targetElement is VariableElement) {
          targetType = targetElement.type;
        } else if (targetElement is PropertyAccessorElement) {
          targetType = targetElement.returnType;
        } else {
          // TODO(srawlins): Can we get here?
          node.staticType = DynamicTypeImpl.instance;
          return;
        }
      } else {
        // TODO(srawlins): Can we get here? PrefixedIdentifier?
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
      var propertyElement = _resolver.typePropertyResolver
          .resolve(
            receiver: function.realTarget,
            receiverType: targetType,
            name: function.propertyName.name,
            propertyErrorEntity: function.propertyName,
            nameErrorEntity: function,
          )
          .getter;

      var functionType = function.typeOrThrow;
      if (functionType is FunctionType && propertyElement != null) {
        _resolve(
          node: node,
          name: propertyElement.name,
          rawType: functionType,
        );
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

  List<DartType> _checkTypeArguments(
    TypeArgumentList typeArgumentList,
    String name,
    List<TypeParameterElement> typeParameters,
    CompileTimeErrorCode errorCode,
  ) {
    if (typeArgumentList.arguments.length != typeParameters.length) {
      _errorReporter.reportErrorForNode(
        errorCode,
        typeArgumentList,
        [name, typeParameters.length, typeArgumentList.arguments.length],
      );
      return List.filled(typeParameters.length, DynamicTypeImpl.instance);
    } else {
      return typeArgumentList.arguments
          .map((typeAnnotation) => typeAnnotation.typeOrThrow)
          .toList();
    }
  }

  /// Resolves [node]'s static type, as an instantiated function type, and type
  /// argument types, using [rawType] as the uninstantiated function type.
  void _resolve({
    required FunctionReferenceImpl node,
    required String name,
    required FunctionType rawType,
  }) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, name, rawType.typeFormals,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION,
    );

    var invokeType = rawType.instantiate(typeArguments);
    node.typeArgumentTypes = typeArguments;
    node.staticType = invokeType;
  }

  void _resolveConstructorReference(FunctionReferenceImpl node) {
    // TODO(srawlins): Rewrite and resolve [node] as a constructor reference.
    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  /// Resolves [node] as a [TypeLiteral] referencing an interface type directly
  /// (not through a type alias).
  void _resolveDirectTypeLiteral(
      FunctionReferenceImpl node, Identifier name, ClassElement element) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, name.name, element.typeParameters,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
    );
    var type = element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _nullabilitySuffixForTypeNames,
    );
    _resolveTypeLiteral(node: node, instantiatedType: type, name: name);
  }

  void _resolveFunctionReferenceMethod({
    required FunctionReferenceImpl node,
    required PrefixedIdentifier function,
    required MethodElement element,
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

      _resolve(node: node, name: name, rawType: element.type);
      return;
    }

    // TODO(srawlins): Report unresolved identifier.
    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolveReceiverPrefix(
    FunctionReferenceImpl node,
    PrefixElement prefixElement,
    PrefixedIdentifier prefix,
  ) {
    // TODO(srawlins): Handle `loadLibrary`, as in `p.loadLibrary<int>;`.

    var nameNode = prefix.identifier;
    var name = nameNode.name;
    var element = prefixElement.scope.lookup(name).getter;
    element = _resolver.toLegacyElement(element);

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];

      // TODO(srawlins): Add a resolution test for this case.
    }

    // Classes and type aliases are checked first so as to include a
    // PropertyAccess parent check, which does not need to be done for
    // functions.
    if (element is ClassElement || element is TypeAliasElement) {
      // A type-instantiated constructor tearoff like `prefix.C<int>.name` is
      // initially represented as a [PropertyAccess] with a
      // [FunctionReference] 'target'.
      if (node.parent is PropertyAccess) {
        _resolveConstructorReference(node);
        return;
      } else if (element is ClassElement) {
        node.function.accept(_resolver);
        _resolveDirectTypeLiteral(node, prefix, element);
        return;
      } else if (element is TypeAliasElement) {
        prefix.accept(_resolver);
        (nameNode as SimpleIdentifierImpl).staticElement = element;
        _resolveTypeAlias(node: node, element: element, typeAlias: prefix);
        return;
      }
    } else if (element is ExecutableElement) {
      node.function.accept(_resolver);
      _resolve(
        node: node,
        name: element.name,
        rawType: node.function.typeOrThrow as FunctionType,
      );
      return;
    }

    // TODO(srawlins): Report undefined prefixed identifier.

    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolveTypeAlias({
    required FunctionReferenceImpl node,
    required TypeAliasElement element,
    required Identifier typeAlias,
  }) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, element.name, element.typeParameters,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
    );
    var type = element.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: _nullabilitySuffixForTypeNames);
    _resolveTypeLiteral(node: node, instantiatedType: type, name: typeAlias);
  }

  void _resolveTypeLiteral({
    required FunctionReferenceImpl node,
    required DartType instantiatedType,
    required Identifier name,
  }) {
    var typeName = astFactory.typeName(name, node.typeArguments);
    typeName.type = instantiatedType;
    typeName.name.staticType = instantiatedType;
    var typeLiteral = astFactory.typeLiteral(typeName: typeName);
    typeLiteral.staticType = _typeType;
    NodeReplacer.replace(node, typeLiteral);
  }
}
