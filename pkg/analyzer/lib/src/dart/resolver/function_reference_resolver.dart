// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
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

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  FunctionReferenceResolver(this._resolver)
    : _extensionResolver = _resolver.extensionResolver,
      _typeType = _resolver.typeProvider.typeType;

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  void resolve(FunctionReferenceImpl node) {
    var function = node.function;
    node.typeArguments?.accept(_resolver);

    if (function is SimpleIdentifierImpl) {
      _resolveSimpleIdentifierFunction(node, function);
    } else if (function is PrefixedIdentifierImpl) {
      _resolvePrefixedIdentifierFunction(node, function);
    } else if (function is PropertyAccessImpl) {
      _resolvePropertyAccessFunction(node, function);
    } else if (function is ConstructorReferenceImpl) {
      var typeArguments = node.typeArguments;
      if (typeArguments != null) {
        // Something like `List.filled<int>`.
        _resolver.analyzeExpression(function, _resolver.operations.unknownType);
        _resolver.popRewrite();
        // We can safely assume `function.constructorName.name` is non-null
        // because if no name had been given, the construct would have been
        // interpreted as a type literal (e.g. `List<int>`).
        _diagnosticReporter.report(
          diag.wrongNumberOfTypeArgumentsConstructor
              .withArguments(
                className: function.constructorName.type.qualifiedName,
                constructorName: function.constructorName.name!.name,
              )
              .at(typeArguments),
        );
        var constructorElement = function.constructorName.element;
        _resolve(
          node: node,
          rawType: function.staticType,
          target: constructorElement == null
              ? null
              : InvocationTargetConstructorElement(
                  constructorElement,
                  constructorElement.type,
                ),
        );
      }
    } else {
      // TODO(srawlins): Handle `function` being a [SuperExpression].

      _resolver.analyzeExpression(function, _resolver.operations.unknownType);
      function = _resolver.popRewrite()!;
      var functionType = function.staticType;
      if (functionType == null) {
        _resolveDisallowedExpression(node, functionType);
      } else if (functionType is FunctionTypeImpl) {
        _resolve(
          node: node,
          rawType: functionType,
          target: InvocationTargetFunctionTypedExpression(functionType),
        );
      } else {
        var callMethod = _getCallMethod(node, function.staticType);
        if (callMethod is MethodElement) {
          _resolveAsImplicitCallReference(node, callMethod);
          return;
        } else {
          _resolveDisallowedExpression(node, functionType);
        }
      }
    }
  }

  List<TypeImpl> _checkTypeArguments(
    TypeArgumentList typeArgumentList,
    String? name,
    List<TypeParameterElement> typeParameters, {
    required TypeInstantiationTarget? target,
  }) {
    if (typeArgumentList.arguments.length != typeParameters.length) {
      _diagnosticReporter.report(
        target!
            .wrongNumberOfTypeArgumentsError(
              typeParameterCount: typeParameters.length,
              typeArgumentCount: typeArgumentList.arguments.length,
            )
            .at(typeArgumentList),
      );
      return List.filled(typeParameters.length, DynamicTypeImpl.instance);
    } else {
      return typeArgumentList.arguments
          .map((typeAnnotation) => typeAnnotation.typeOrThrow)
          .toList();
    }
  }

  ExecutableElement? _getCallMethod(
    FunctionReferenceImpl node,
    DartType? type,
  ) {
    if (type is! InterfaceTypeImpl) {
      return null;
    }
    var callMethodName = Name(
      _resolver.definingLibrary.uri,
      MethodElement.CALL_METHOD_NAME,
    );
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      // If the interface type is nullable, only an applicable extension method
      // applies.
      return _extensionResolver
          .findExtension(type, node, callMethodName)
          .getter2;
    }
    // Otherwise, a 'call' method on the interface, or on an applicable
    // extension method applies.
    return type.lookUpMethod(
          MethodElement.CALL_METHOD_NAME,
          type.element.library,
        ) ??
        _extensionResolver.findExtension(type, node, callMethodName).getter2;
  }

  void _reportInvalidAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element, {
    required bool implicitReceiver,
  }) {
    var enclosingElement = element.enclosingElement!;
    if (implicitReceiver) {
      if (_resolver.enclosingExtension != null) {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToStaticMemberOfExtendedType
              .withArguments(name: enclosingElement.displayName)
              .at(nameNode),
        );
      } else {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToNonLocalStaticMember
              .withArguments(name: enclosingElement.displayName)
              .at(nameNode),
        );
      }
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.name == null) {
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMemberOfUnnamedExtension
            .withArguments(name: nameNode.name, kind: element.kind.displayName)
            .at(nameNode),
      );
    } else {
      // It is safe to assume that `enclosingElement.name` is non-`null` because
      // it can only be `null` for extensions, and we handle that case above.
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMember
            .withArguments(
              memberName: nameNode.name,
              memberKind: element.kind.displayName,
              enclosingElementName: enclosingElement.name!,
              enclosingElementKind: enclosingElement is MixinElement
                  ? 'mixin'
                  : enclosingElement.kind.displayName,
            )
            .at(nameNode),
      );
    }
  }

  /// Resolves [node]'s static type, as an instantiated function type, and type
  /// argument types, using [rawType] as the uninstantiated function type.
  void _resolve({
    required FunctionReferenceImpl node,
    required DartType? rawType,
    String? name,
    required InvocationTarget? target,
  }) {
    if (rawType == null) {
      node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
    }

    if (rawType is InvalidType) {
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    if (rawType is TypeParameterTypeImpl) {
      // If the type of the function is a type parameter, the tearoff is
      // disallowed, reported in [_resolveDisallowedExpression]. Use the type
      // parameter's bound here in an attempt to assign the intended types.
      rawType = rawType.element.bound;
    }

    if (rawType is FunctionType) {
      // A FunctionReference with type arguments and with a
      // ConstructorReference child is invalid. E.g. `List.filled<int>`.
      // [CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR] is
      // reported elsewhere; don't check type arguments here.
      if (node.function is ConstructorReference) {
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      } else {
        var typeArguments = node.typeArguments;
        if (typeArguments == null) {
          node.recordStaticType(rawType, resolver: _resolver);
        } else {
          var typeArgumentTypes = _checkTypeArguments(
            typeArguments,
            name,
            rawType.typeParameters,
            target: target,
          );

          var invokeType = rawType.instantiate(typeArgumentTypes);
          node.typeArgumentTypes = typeArgumentTypes;
          node.recordStaticType(invokeType, resolver: _resolver);
        }
      }
    } else {
      if (_resolver.isConstructorTearoffsEnabled) {
        // Only report constructor tearoff-related errors if the constructor
        // tearoff feature is enabled.
        _diagnosticReporter.report(
          diag.disallowedTypeInstantiationExpression.at(node.function),
        );
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      } else if (rawType is DynamicType) {
        node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
      } else {
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      }
    }
  }

  void _resolveAsImplicitCallReference(
    FunctionReferenceImpl node,
    MethodElement callMethod,
  ) {
    // `node<...>` is to be treated as `node.call<...>`.
    var callMethodType = callMethod.type;
    var typeArgumentTypes = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!,
      MethodElement.CALL_METHOD_NAME,
      callMethodType.typeParameters,
      target: InvocationTargetExecutableElement(callMethod),
    );
    var callReference = ImplicitCallReferenceImpl(
      expression: node.function,
      element: callMethod,
      typeArguments: node.typeArguments,
      typeArgumentTypes: typeArgumentTypes,
    );
    _resolver.replaceExpression(node, callReference);
    var instantiatedType = callMethodType.instantiate(typeArgumentTypes);
    callReference.recordStaticType(instantiatedType, resolver: _resolver);
  }

  void _resolveConstructorReference(FunctionReferenceImpl node) {
    // TODO(srawlins): Rewrite and resolve [node] as a constructor reference.
    node.function.accept(_resolver);
    node.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
  }

  /// Resolves [node] as a [TypeLiteral] referencing an interface type directly
  /// (not through a type alias).
  void _resolveDirectTypeLiteral(
    FunctionReferenceImpl node,
    IdentifierImpl name,
    InterfaceElementImpl element,
  ) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!,
      name.name,
      element.typeParameters,
      target: TypeInstantiationTargetInterfaceElement(element),
    );
    var type = element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _resolveTypeLiteral(node: node, instantiatedType: type, name: name);
  }

  /// Resolves [node] as a type instantiation on an illegal expression.
  ///
  /// This function attempts to give [node] a static type, to continue working
  /// with what the user may be intending.
  void _resolveDisallowedExpression(
    FunctionReferenceImpl node,
    DartType? rawType,
  ) {
    if (_resolver.isConstructorTearoffsEnabled) {
      // Only report constructor tearoff-related errors if the constructor
      // tearoff feature is enabled.
      _diagnosticReporter.report(
        diag.disallowedTypeInstantiationExpression.at(node.function),
      );
    }
    _resolve(
      node: node,
      rawType: rawType,
      target: InvocationTargetFunctionTypedExpression.orNull(rawType),
    );
  }

  void _resolveExtensionOverride(
    FunctionReferenceImpl node,
    PropertyAccessImpl function,
    ExtensionOverrideImpl override,
  ) {
    var propertyName = function.propertyName;
    var result = _extensionResolver.getOverrideMember(
      override,
      propertyName.name,
    );
    var member = result.getter2;

    if (member == null) {
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    if (member.isStatic) {
      _resolver.diagnosticReporter.report(
        diag.extensionOverrideAccessToStaticMember.at(function.propertyName),
      );
      // Continue to resolve type.
    }

    if (function.isCascaded) {
      _resolver.diagnosticReporter.report(
        diag.extensionOverrideWithCascade.at(override.name),
      );
      // Continue to resolve type.
    }

    if (member is PropertyAccessorElement) {
      _resolve(
        node: node,
        rawType: member.returnType,
        target: InvocationTargetExecutableElement(member),
      );
      return;
    }

    _resolve(
      node: node,
      rawType: member.type,
      name: propertyName.name,
      target: InvocationTargetExecutableElement(member),
    );
  }

  /// Resolve a possible function tearoff of a [FunctionTypedElement] receiver.
  ///
  /// There are three possible valid cases: tearing off the `call` method of a
  /// function element, tearing off an extension element declared on [Function],
  /// and tearing off an extension element declared on a function type.
  Element? _resolveFunctionTypeFunction(
    ExpressionImpl receiver,
    SimpleIdentifier methodName,
    FunctionTypeImpl receiverType,
  ) {
    var methodElement = _resolver.typePropertyResolver
        .resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: methodName.name,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: methodName,
          nameErrorEntity: methodName,
        )
        .getter2;
    if (methodElement != null && methodElement.isStatic) {
      _reportInvalidAccessToStaticMember(
        methodName,
        methodElement,
        implicitReceiver: false,
      );
    }
    return methodElement;
  }

  void _resolvePrefixedIdentifierFunction(
    FunctionReferenceImpl node,
    PrefixedIdentifierImpl function,
  ) {
    _resolver.analyzeExpression(function, _resolver.operations.unknownType);
    _resolver.popRewrite();

    var propertyType = function.typeOrThrow;

    if (function.element is ExtensionElement) {
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    if (propertyType is InvalidType) {
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    if (propertyType is DynamicTypeImpl) {
      _diagnosticReporter.report(
        diag.genericMethodTypeInstantiationOnDynamic.at(function),
      );
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    var callMethod = _getCallMethod(node, propertyType);
    if (callMethod is MethodElement) {
      _resolveAsImplicitCallReference(node, callMethod);
      return;
    }

    if (propertyType is FunctionTypeImpl) {
      function.setPseudoExpressionStaticType(propertyType);
      var functionName = function.identifier.name;
      _resolve(
        node: node,
        rawType: propertyType,
        name: functionName,
        target: InvocationTargetFunctionTypedExpression(propertyType),
      );
      return;
    }

    if (function.prefix.element case PrefixElement prefixElement) {
      if (function.element case var functionElement?) {
        _resolveReceiverPrefix(node, prefixElement, function, functionElement);
        return;
      }
    }

    _diagnosticReporter.report(
      diag.disallowedTypeInstantiationExpression.at(function.identifier),
    );
    node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
  }

  void _resolvePropertyAccessFunction(
    FunctionReferenceImpl node,
    PropertyAccessImpl function,
  ) {
    _resolver.analyzeExpression(function, _resolver.operations.unknownType);
    _resolver.popRewrite();
    var callMethod = _getCallMethod(node, function.staticType);
    if (callMethod is MethodElement) {
      _resolveAsImplicitCallReference(node, callMethod);
      return;
    }
    var target = function.realTarget;

    TypeImpl targetType;
    if (target is SuperExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is ThisExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is SimpleIdentifierImpl) {
      var targetElement = target.scopeLookupResult!.getter;
      if (targetElement is InternalVariableElement) {
        targetType = targetElement.type;
      } else if (targetElement is InternalPropertyAccessorElement) {
        targetType = targetElement.variable.type;
      } else {
        // TODO(srawlins): Can we get here?
        node.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
        return;
      }
    } else if (target is ExtensionOverrideImpl) {
      _resolveExtensionOverride(node, function, target);
      return;
    } else {
      var targetType = target.staticType;
      if (targetType is DynamicType) {
        _diagnosticReporter.report(
          diag.genericMethodTypeInstantiationOnDynamic.at(node),
        );
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
        return;
      } else if (targetType is InvalidType) {
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
        return;
      }
      var functionType = _resolveTypeProperty(
        receiver: target,
        name: function.propertyName,
        nameErrorEntity: function,
      );

      if (functionType is FunctionTypeImpl) {
        function.setPseudoExpressionStaticType(functionType);
        _resolve(
          node: node,
          rawType: functionType,
          name: function.propertyName.name,
          target: InvocationTargetFunctionTypedExpression(functionType),
        );
        return;
      } else if (functionType != null) {
        // If the property is unknown, [UNDEFINED_GETTER] is reported elsewhere.
        // If it is known, we must report the bad type instantiation here.
        _diagnosticReporter.report(
          diag.disallowedTypeInstantiationExpression.at(function.propertyName),
        );
      }

      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    var propertyElement = _resolver.typePropertyResolver
        .resolve(
          receiver: function.realTarget,
          receiverType: targetType,
          name: function.propertyName.name,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: function.propertyName,
          nameErrorEntity: function,
        )
        .getter2;

    _resolve(
      node: node,
      rawType: function.staticType,
      name: propertyElement?.name,
      target: InvocationTargetExecutableElement.orNull(propertyElement),
    );
  }

  void _resolveReceiverPrefix(
    FunctionReferenceImpl node,
    PrefixElement prefixElement,
    PrefixedIdentifierImpl prefix,
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
    if (element is InterfaceElement || element is TypeAliasElement) {
      // A type-instantiated constructor tearoff like `prefix.C<int>.name` is
      // initially represented as a [PropertyAccess] with a
      // [FunctionReference] 'target'.
      if (node.parent is PropertyAccess) {
        _resolveConstructorReference(node);
        return;
      } else if (element is InterfaceElementImpl) {
        _resolveDirectTypeLiteral(node, prefix, element);
        return;
      } else if (element is TypeAliasElementImpl) {
        _resolveTypeAlias(node: node, element: element, typeAlias: prefix);
        return;
      }
    } else if (element is ExtensionElement) {
      prefix.identifier.element = element;
      prefix.identifier.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      prefix.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      _resolveDisallowedExpression(node, InvalidTypeImpl.instance);
      return;
    }

    assert(
      false,
      'Member of prefixed element, $prefixElement, is not a class, mixin, '
      'type alias, or executable element: $element (${element.runtimeType})',
    );
    node.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
  }

  void _resolveSimpleIdentifierFunction(
    FunctionReferenceImpl node,
    SimpleIdentifierImpl function,
  ) {
    var element = function.scopeLookupResult!.getter;

    if (element == null) {
      var receiverType = _resolver.thisType;
      if (receiverType == null) {
        _diagnosticReporter.report(
          diag.undefinedIdentifier
              .withArguments(name: function.name)
              .at(function),
        );
        function.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
        return;
      }

      var result = _resolver.typePropertyResolver.resolve(
        receiver: null,
        receiverType: receiverType,
        name: function.name,
        hasRead: true,
        hasWrite: false,
        propertyErrorEntity: function,
        nameErrorEntity: function,
      );

      var method = result.getter2;
      if (method != null) {
        if (method.isStatic) {
          _reportInvalidAccessToStaticMember(
            function,
            method,
            implicitReceiver: true,
          );
          // Continue to assign types.
        }

        if (method is InternalPropertyAccessorElement) {
          function.element = method;
          function.setPseudoExpressionStaticType(method.returnType);
          _resolve(
            node: node,
            rawType: method.variable.type,
            target: InvocationTargetExecutableElement(method),
          );
          return;
        }

        function.element = method;
        function.setPseudoExpressionStaticType(method.type);
        _resolve(
          node: node,
          rawType: method.type,
          name: function.name,
          target: InvocationTargetExecutableElement(method),
        );
        return;
      } else {
        _resolver.diagnosticReporter.report(
          diag.undefinedMethod
              .withArguments(
                methodName: function.name,
                typeName: receiverType.getDisplayString(),
              )
              .at(function),
        );
        function.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
        node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
        return;
      }
    }

    // Classes and type aliases are checked first so as to include a
    // PropertyAccess parent check, which does not need to be done for
    // functions.
    if (element is InterfaceElement || element is TypeAliasElement) {
      // A type-instantiated constructor tearoff like `C<int>.name` or
      // `prefix.C<int>.name` is initially represented as a [PropertyAccess]
      // with a [FunctionReference] target.
      if (node.parent is PropertyAccess) {
        if (element is TypeAliasElementImpl &&
            element.aliasedType is FunctionType) {
          function.element = element;
          _resolveTypeAlias(node: node, element: element, typeAlias: function);
        } else {
          _resolveConstructorReference(node);
        }
        return;
      } else if (element is InterfaceElementImpl) {
        function.element = element;
        _resolveDirectTypeLiteral(node, function, element);
        return;
      } else if (element is TypeAliasElementImpl) {
        function.element = element;
        _resolveTypeAlias(node: node, element: element, typeAlias: function);
        return;
      }
    } else if (element is MethodElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(element.type);
      _resolve(
        node: node,
        rawType: element.type,
        name: element.name,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    } else if (element is LocalFunctionElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(element.type);
      _resolve(
        node: node,
        rawType: element.type,
        name: element.name,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    } else if (element is TopLevelFunctionElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(element.type);
      _resolve(
        node: node,
        rawType: element.type,
        name: element.name,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    } else if (element is PropertyAccessorElement) {
      function.element = element;
      var variable = element.variable;
      function.setPseudoExpressionStaticType(variable.type);
      var callMethod = _getCallMethod(node, variable.type);
      if (callMethod is MethodElement) {
        _resolveAsImplicitCallReference(node, callMethod);
        return;
      }
      _resolve(
        node: node,
        rawType: element.returnType,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    } else if (element is ExecutableElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(element.type);
      _resolve(
        node: node,
        rawType: element.type,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    } else if (element is VariableElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(element.type);
      var callMethod = _getCallMethod(node, element.type);
      if (callMethod is MethodElement) {
        _resolveAsImplicitCallReference(node, callMethod);
        return;
      }
      _resolve(
        node: node,
        rawType: element.type,
        target: InvocationTargetFunctionTypedExpression.orNull(element.type),
      );
      return;
    } else if (element is ExtensionElement) {
      function.element = element;
      function.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      _resolveDisallowedExpression(node, InvalidTypeImpl.instance);
      return;
    } else {
      _resolveDisallowedExpression(node, DynamicTypeImpl.instance);
      return;
    }
  }

  /// Returns the element that represents the property named [propertyName] on
  /// [classElement].
  ExecutableElement? _resolveStaticElement(
    InterfaceElement classElement,
    SimpleIdentifier propertyName,
  ) {
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
    required TypeAliasElementImpl element,
    required IdentifierImpl typeAlias,
  }) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!,
      element.name,
      element.typeParameters,
      target: TypeInstantiationTargetTypeAliasElement(element),
    );
    var type = element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _resolveTypeLiteral(node: node, instantiatedType: type, name: typeAlias);
  }

  void _resolveTypeLiteral({
    required FunctionReferenceImpl node,
    required TypeImpl instantiatedType,
    required IdentifierImpl name,
  }) {
    // TODO(srawlins): set the static element of [typeName].
    // This involves a fair amount of resolution, as [name] may be a prefixed
    // identifier, etc. [NamedType]s should be resolved in [ResolutionVisitor],
    // and this could be done for nodes like this via [AstRewriter].
    var typeName = name.toNamedType(
      typeArguments: node.typeArguments,
      question: null,
    );
    typeName.type = instantiatedType;
    var typeLiteral = TypeLiteralImpl(type: typeName);
    _resolver.replaceExpression(node, typeLiteral);
    typeLiteral.recordStaticType(_typeType, resolver: _resolver);
  }

  /// Resolves [name] as a property on [receiver].
  ///
  /// Returns `null` if [receiver]'s type is `null`, a [TypeParameterType],
  /// or a type alias for a non-interface type.
  DartType? _resolveTypeProperty({
    required ExpressionImpl receiver,
    required SimpleIdentifierImpl name,
    required SyntacticEntity nameErrorEntity,
  }) {
    if (receiver is IdentifierImpl) {
      var receiverElement = receiver.element;
      if (receiverElement is InterfaceElement) {
        var element = _resolveStaticElement(receiverElement, name);
        name.element = element;
        return element?.referenceType;
      } else if (receiverElement is TypeAliasElement) {
        var aliasedType = receiverElement.aliasedType;
        if (aliasedType is InterfaceType) {
          var element = _resolveStaticElement(aliasedType.element, name);
          name.element = element;
          return element?.referenceType;
        } else {
          return null;
        }
      }
    }

    var receiverType = receiver.staticType;
    if (receiverType == null) {
      return null;
    } else if (receiverType is TypeParameterTypeImpl) {
      return null;
    } else if (receiverType is FunctionTypeImpl) {
      if (name.name == MethodElement.CALL_METHOD_NAME) {
        return receiverType;
      }
      var element = _resolveFunctionTypeFunction(receiver, name, receiverType);
      name.element = element;
      return element?.referenceType;
    }

    var element = _resolver.typePropertyResolver
        .resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: name.name,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: name,
          nameErrorEntity: nameErrorEntity,
        )
        .getter2;
    name.element = element;
    if (element != null && element.isStatic) {
      _reportInvalidAccessToStaticMember(
        name,
        element,
        implicitReceiver: false,
      );
    }
    return element?.referenceType;
  }
}

extension on Element {
  /// Returns the 'type' of `this`, when accessed as a "reference", not
  /// immediately followed by parentheses and arguments.
  ///
  /// For all elements that don't have a type (for example, [LibraryElement]),
  /// `null` is returned. For [PropertyAccessorElement], the return value is
  /// returned. For all other elements, their `type` property is returned.
  DartType? get referenceType {
    var self = this;
    return switch (self) {
      ConstructorElement() => self.type,
      TopLevelFunctionElement() => self.type,
      LocalFunctionElement() => self.type,
      PropertyAccessorElement() => self.returnType,
      MethodElement() => self.type,
      VariableElement() => self.type,
      _ => null,
    };
  }
}
