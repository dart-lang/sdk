// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
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

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final bool _isNonNullableByDefault;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  FunctionReferenceResolver(this._resolver, this._isNonNullableByDefault)
      : _extensionResolver = _resolver.extensionResolver,
        _typeType = _resolver.typeProvider.typeType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  NullabilitySuffix get _nullabilitySuffixForTypeNames =>
      _isNonNullableByDefault ? NullabilitySuffix.none : NullabilitySuffix.star;

  void resolve(FunctionReferenceImpl node) {
    var function = node.function;
    node.typeArguments?.accept(_resolver);

    if (function is SimpleIdentifierImpl) {
      _resolveSimpleIdentifierFunction(node, function);
    } else if (function is PrefixedIdentifierImpl) {
      _resolvePrefixedIdentifierFunction(node, function);
    } else if (function is PropertyAccessImpl) {
      _resolvePropertyAccessFunction(node, function);
    } else {
      // TODO(srawlins): Handle `function` being a [SuperExpression].

      function.accept(_resolver);
      _resolveDisallowedExpression(node, node.function.staticType);
    }
  }

  List<DartType> _checkTypeArguments(
    TypeArgumentList typeArgumentList,
    String? name,
    List<TypeParameterElement> typeParameters,
    CompileTimeErrorCode errorCode,
  ) {
    if (typeArgumentList.arguments.length != typeParameters.length) {
      if (name == null &&
          errorCode ==
              CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION) {
        errorCode = CompileTimeErrorCode
            .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION;
        _errorReporter.reportErrorForNode(
          errorCode,
          typeArgumentList,
          [typeParameters.length, typeArgumentList.arguments.length],
        );
      } else {
        assert(name != null);
        _errorReporter.reportErrorForNode(
          errorCode,
          typeArgumentList,
          [name, typeParameters.length, typeArgumentList.arguments.length],
        );
      }
      return List.filled(typeParameters.length, DynamicTypeImpl.instance);
    } else {
      return typeArgumentList.arguments
          .map((typeAnnotation) => typeAnnotation.typeOrThrow)
          .toList();
    }
  }

  void _reportInvalidAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element, {
    required bool implicitReceiver,
  }) {
    if (_resolver.enclosingExtension != null) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
        nameNode,
        [element.enclosingElement.displayName],
      );
    } else if (implicitReceiver) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
        nameNode,
        [element.enclosingElement.displayName],
      );
    } else {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
        nameNode,
        [
          nameNode.name,
          element.kind.displayName,
          element.enclosingElement.displayName,
        ],
      );
    }
  }

  /// Resolves [node]'s static type, as an instantiated function type, and type
  /// argument types, using [rawType] as the uninstantiated function type.
  void _resolve({
    required FunctionReferenceImpl node,
    required DartType? rawType,
    String? name,
  }) {
    if (rawType == null) {
      node.staticType = DynamicTypeImpl.instance;
    }

    if (rawType is TypeParameterTypeImpl) {
      // If the type of the function is a type parameter, the tearoff is
      // disallowed, reported in [_resolveDisallowedExpression]. Use the type
      // parameter's bound here in an attempt to assign the intended types.
      rawType = rawType.element.bound;
    }

    if (rawType is FunctionType) {
      var typeArguments = _checkTypeArguments(
        // `node.typeArguments`, coming from the parser, is never null.
        node.typeArguments!, name, rawType.typeFormals,
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION,
      );

      var invokeType = rawType.instantiate(typeArguments);
      node.typeArgumentTypes = typeArguments;
      node.staticType = invokeType;
    } else {
      node.staticType = DynamicTypeImpl.instance;
    }
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

  /// Resolves [node] as a type instantiation on an illegal expression.
  ///
  /// This function attempts to give [node] a static type, to continue working
  /// with what the user may be intending.
  void _resolveDisallowedExpression(
      FunctionReferenceImpl node, DartType? rawType) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION,
      node.function,
      [],
    );
    _resolve(node: node, rawType: rawType);
  }

  void _resolveExtensionOverride(
    FunctionReferenceImpl node,
    PropertyAccessImpl function,
    ExtensionOverride override,
  ) {
    var propertyName = function.propertyName;
    var result =
        _extensionResolver.getOverrideMember(override, propertyName.name);
    var member = _resolver.toLegacyElement(result.getter);

    if (member == null) {
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    if (member.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        function.propertyName,
      );
      // Continue to resolve type.
    }

    if (function.isCascaded) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        override.extensionName,
      );
      // Continue to resolve type.
    }

    if (member is PropertyAccessorElement) {
      function.accept(_resolver);
      _resolveDisallowedExpression(node, member.returnType);
      return;
    }

    _resolve(node: node, rawType: member.type, name: propertyName.name);
  }

  void _resolvePrefixedIdentifierFunction(
      FunctionReferenceImpl node, PrefixedIdentifierImpl function) {
    var prefixElement = function.prefix.scopeLookupResult!.getter;

    if (prefixElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
        function.prefix,
        [function.name],
      );
      function.staticType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    function.prefix.staticElement = prefixElement;
    if (prefixElement is PrefixElement) {
      var functionName = function.identifier.name;
      var functionElement = prefixElement.scope.lookup(functionName).getter;
      if (functionElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME,
          function.identifier,
          [function.identifier.name, function.prefix.name],
        );
        function.staticType = DynamicTypeImpl.instance;
        node.staticType = DynamicTypeImpl.instance;
        return;
      } else {
        functionElement = _resolver.toLegacyElement(functionElement);
        _resolveReceiverPrefix(node, prefixElement, function, functionElement);
        return;
      }
    }

    DartType? prefixType;
    if (prefixElement is VariableElement) {
      prefixType = prefixElement.type;
    } else if (prefixElement is PropertyAccessorElement) {
      prefixType = prefixElement.returnType;
    }

    function.prefix.staticType = prefixType;
    if (prefixType != null && prefixType.isDynamic) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
        function,
        [],
      );
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    var methodElement = _resolveTypeProperty(
      receiver: function.prefix,
      receiverElement: prefixElement,
      name: function.identifier,
      nameErrorEntity: function,
    );

    if (methodElement is MethodElement) {
      function.identifier.staticElement = methodElement;
      function.staticType = methodElement.type;
      _resolve(
        node: node,
        rawType: methodElement.type,
        name: function.identifier.name,
      );
      return;
    }

    if (methodElement is PropertyAccessorElement) {
      function.accept(_resolver);
      _resolveDisallowedExpression(node, methodElement.returnType);
      return;
    }

    function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolvePropertyAccessFunction(
      FunctionReferenceImpl node, PropertyAccessImpl function) {
    function.accept(_resolver);
    var target = function.realTarget;

    DartType targetType;
    if (target is SuperExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is ThisExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is SimpleIdentifierImpl) {
      var targetElement = target.scopeLookupResult!.getter;
      if (targetElement is VariableElement) {
        targetType = targetElement.type;
      } else if (targetElement is PropertyAccessorElement) {
        targetType = targetElement.returnType;
      } else {
        // TODO(srawlins): Can we get here?
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
    } else if (target is PrefixedIdentifierImpl) {
      var prefixElement = target.prefix.scopeLookupResult!.getter;
      if (prefixElement is PrefixElement) {
        var prefixName = target.identifier.name;
        var targetElement = prefixElement.scope.lookup(prefixName).getter;

        var methodElement = _resolveTypeProperty(
          receiver: target,
          receiverElement: targetElement,
          name: function.propertyName,
          nameErrorEntity: function,
        );

        if (methodElement == null) {
          // TODO(srawlins): Can we get here?
          node.staticType = DynamicTypeImpl.instance;
          return;
        } else {
          _resolveReceiverPrefix(node, prefixElement, target, methodElement);
          return;
        }
      } else {
        // TODO(srawlins): Can we get here?
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
    } else if (target is ExtensionOverrideImpl) {
      _resolveExtensionOverride(node, function, target);
      return;
    } else {
      targetType = target.typeOrThrow;
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

    if (propertyElement is TypeParameterElement) {
      _resolveDisallowedExpression(node, propertyElement!.type);
      return;
    }

    _resolve(
      node: node,
      rawType: function.staticType,
      name: propertyElement?.name,
    );
  }

  void _resolveReceiverPrefix(
    FunctionReferenceImpl node,
    PrefixElement prefixElement,
    PrefixedIdentifier prefix,
    Element element,
  ) {
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
        _resolveTypeAlias(node: node, element: element, typeAlias: prefix);
        return;
      }
    } else if (element is ExecutableElement) {
      node.function.accept(_resolver);
      _resolve(
        node: node,
        rawType: node.function.typeOrThrow as FunctionType,
        name: element.name,
      );
      return;
    }

    // TODO(srawlins): Report undefined prefixed identifier.

    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolveSimpleIdentifierFunction(
      FunctionReferenceImpl node, SimpleIdentifierImpl function) {
    var element = function.scopeLookupResult!.getter;

    if (element == null) {
      DartType receiverType;
      var enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        receiverType = enclosingClass.thisType;
      } else {
        var enclosingExtension = _resolver.enclosingExtension;
        if (enclosingExtension != null) {
          receiverType = enclosingExtension.extendedType;
        } else {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
            function,
            [function.name],
          );
          function.staticType = DynamicTypeImpl.instance;
          node.staticType = DynamicTypeImpl.instance;
          return;
        }
      }

      var result = _resolver.typePropertyResolver.resolve(
        receiver: null,
        receiverType: receiverType,
        name: function.name,
        propertyErrorEntity: function,
        nameErrorEntity: function,
      );

      var method = result.getter;
      if (method != null) {
        if (method.isStatic) {
          _reportInvalidAccessToStaticMember(function, method,
              implicitReceiver: true);
          // Continue to assign types.
        }

        if (method is PropertyAccessorElement) {
          _resolveDisallowedExpression(node, method.returnType);
          return;
        }

        function.staticElement = method;
        function.staticType = method.type;
        _resolve(node: node, rawType: method.type, name: function.name);
        return;
      } else {
        _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_METHOD,
          function,
          [function.name, enclosingClass],
        );
        function.staticType = DynamicTypeImpl.instance;
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
    }

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
    } else if (element is MethodElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolve(node: node, rawType: element.type, name: element.name);
      return;
    } else if (element is FunctionElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolve(node: node, rawType: element.type, name: element.name);
      return;
    } else if (element is PropertyAccessorElement) {
      function.staticElement = element;
      function.staticType = element.returnType;
      _resolveDisallowedExpression(node, element.returnType);
      return;
    } else if (element is ExecutableElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolveDisallowedExpression(node, element.type);
      return;
    } else if (element is VariableElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolveDisallowedExpression(node, element.type);
      return;
    } else {
      _resolveDisallowedExpression(node, DynamicTypeImpl.instance);
      return;
    }
  }

  /// Returns the element that represents the property named [propertyName] on
  /// [classElement].
  ExecutableElement? _resolveStaticElement(
      ClassElement classElement, SimpleIdentifier propertyName) {
    String name = propertyName.name;
    ExecutableElement? element;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    element ??= classElement.getGetter(name);
    element ??= classElement.getMethod(name);
    if (element != null && element.isAccessibleIn(_resolver.definingLibrary)) {
      return element;
    }
    return null;
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

  /// Resolves [name] as a property on [receiver] (with element
  /// [receiverElement]).
  ///
  /// Returns `null` if [receiverElement] is `null`, a [TypeParameterElement],
  /// or a [TypeAliasElement] for a non-interface type.
  ExecutableElement? _resolveTypeProperty({
    required Expression receiver,
    required Element? receiverElement,
    required SimpleIdentifier name,
    required SyntacticEntity nameErrorEntity,
  }) {
    if (receiverElement == null) {
      return null;
    }
    if (receiverElement is TypeParameterElement) {
      return null;
    }
    if (receiverElement is ClassElement) {
      return _resolveStaticElement(receiverElement, name);
    } else if (receiverElement is TypeAliasElement) {
      var aliasedType = receiverElement.aliasedType;
      if (aliasedType is InterfaceType) {
        return _resolveStaticElement(aliasedType.element, name);
      } else {
        return null;
      }
    }

    DartType receiverType;
    if (receiverElement is VariableElement) {
      receiverType = receiverElement.type;
    } else if (receiverElement is PropertyAccessorElement) {
      receiverType = receiverElement.returnType;
    } else {
      assert(false,
          'Unexpected receiverElement type: ${receiverElement.runtimeType}');
      return null;
    }
    var methodElement = _resolver.typePropertyResolver
        .resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: name.name,
          propertyErrorEntity: name,
          nameErrorEntity: nameErrorEntity,
        )
        .getter;
    if (methodElement != null && methodElement.isStatic) {
      _reportInvalidAccessToStaticMember(name, methodElement,
          implicitReceiver: false);
    }
    return methodElement;
  }
}
