// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

class MethodInvocationResolver with ScopeHelpers {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The library fragment of the compilation unit being visited.
  final CompilationUnitElementImpl _libraryFragment;

  /// The object providing promoted or declared types of variables.
  final LocalVariableTypeProvider _localVariableTypeProvider;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final InvocationInferenceHelper _inferenceHelper;

  /// The invocation being resolved.
  MethodInvocationImpl? _invocation;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name? _currentName;

  MethodInvocationResolver(
    this._resolver, {
    required InvocationInferenceHelper inferenceHelper,
  })  : _typeType = _resolver.typeProvider.typeType,
        _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _definingLibraryUri = _resolver.definingLibrary.source.uri,
        _libraryFragment = _resolver.libraryFragment,
        _localVariableTypeProvider = _resolver.localVariableTypeProvider,
        _extensionResolver = _resolver.extensionResolver,
        _inferenceHelper = inferenceHelper;

  @override
  ErrorReporter get errorReporter => _resolver.errorReporter;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Resolves the method invocation, [node].
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? resolve(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    _invocation = node;

    var nameNode = node.methodName;
    String name = nameNode.name;
    _currentName = Name(_definingLibraryUri, name);

    var receiver = node.realTarget;

    if (receiver == null) {
      return _resolveReceiverNull(node, nameNode, name, whyNotPromotedList,
          contextType: contextType);
    }

    if (receiver is SimpleIdentifierImpl) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is PrefixElement) {
        return _resolveReceiverPrefix(
            node, receiverElement, nameNode, name, whyNotPromotedList,
            contextType: contextType);
      }
    }

    if (receiver is IdentifierImpl) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is ExtensionElement) {
        return _resolveExtensionMember(
            node, receiver, receiverElement, nameNode, name, whyNotPromotedList,
            contextType: contextType);
      }
    }

    if (receiver is SuperExpressionImpl) {
      return _resolveReceiverSuper(
          node, receiver, nameNode, name, whyNotPromotedList,
          contextType: contextType);
    }

    if (receiver is ExtensionOverrideImpl) {
      return _resolveExtensionOverride(
          node, receiver, nameNode, name, whyNotPromotedList,
          contextType: contextType);
    }

    if (receiver is IdentifierImpl) {
      var element = receiver.staticElement;
      if (element is InterfaceElement) {
        return _resolveReceiverTypeLiteral(
            node, element, nameNode, name, whyNotPromotedList,
            contextType: contextType);
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          return _resolveReceiverTypeLiteral(
              node, aliasedType.element, nameNode, name, whyNotPromotedList,
              contextType: contextType);
        }
      }
    }

    DartType receiverType = receiver.typeOrThrow;

    if (_typeSystem.isDynamicBounded(receiverType)) {
      _resolveReceiverDynamicBounded(node, receiverType, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    if (receiverType is NeverTypeImpl) {
      return _resolveReceiverNever(
          node, receiver, receiverType, whyNotPromotedList,
          contextType: contextType, nameNode: nameNode, name: name);
    }

    if (receiverType is VoidType) {
      _reportUseOfVoidType(node, receiver, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    if (node.isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    if (receiver is TypeLiteralImpl &&
        receiver.type.typeArguments != null &&
        receiver.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE,
        arguments: [name, receiver.type.qualifiedName],
      );
      _setInvalidTypeResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      return null;
    }

    return _resolveReceiverType(
      node: node,
      receiver: receiver,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: receiver,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
  }

  bool _hasMatchingObjectMethod(
      MethodElement target, NodeListImpl<ExpressionImpl> arguments) {
    return arguments.length == target.parameters.length &&
        !arguments.any((e) => e is NamedExpression);
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov): Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  void _reportInstanceAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element,
    bool nullReceiver,
  ) {
    var enclosingElement = element.enclosingElement3;
    if (nullReceiver) {
      if (_resolver.enclosingExtension != null) {
        _resolver.errorReporter.atNode(
          nameNode,
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          arguments: [enclosingElement.displayName],
        );
      } else {
        _resolver.errorReporter.atNode(
          nameNode,
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          arguments: [enclosingElement.displayName],
        );
      }
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.name == null) {
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode
            .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
        arguments: [
          nameNode.name,
          element.kind.displayName,
        ],
      );
    } else {
      // It is safe to assume that `enclosingElement.name` is non-`null` because
      // it can only be `null` for extensions, and we handle that case above.
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
        arguments: [
          nameNode.name,
          element.kind.displayName,
          enclosingElement.name!,
          enclosingElement is MixinElement
              ? 'mixin'
              : enclosingElement.kind.displayName,
        ],
      );
    }
  }

  void _reportInvocationOfNonFunction(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    _setInvalidTypeResolution(node,
        setNameTypeToDynamic: false,
        whyNotPromotedList: whyNotPromotedList,
        contextType: contextType);
    _resolver.errorReporter.atNode(
      node.methodName,
      CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION,
      arguments: [node.methodName.name],
    );
  }

  void _reportPrefixIdentifierNotFollowedByDot(SimpleIdentifier target) {
    _resolver.errorReporter.atNode(
      target,
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
      arguments: [target.name],
    );
  }

  void _reportStaticAccessToInstanceMember(
      ExecutableElement element, SimpleIdentifier nameNode) {
    if (!element.isStatic) {
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
        arguments: [nameNode.name],
      );
    }
  }

  void _reportUndefinedFunction(
    MethodInvocationImpl node, {
    required String? prefix,
    required String name,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
    required DartType contextType,
  }) {
    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    if (_libraryFragment.shouldIgnoreUndefined(prefix: prefix, name: name)) {
      return;
    }

    _resolver.errorReporter.atNode(
      node.methodName,
      CompileTimeErrorCode.UNDEFINED_FUNCTION,
      arguments: [node.methodName.name],
    );
  }

  void _reportUseOfVoidType(MethodInvocationImpl node, AstNode errorNode,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    _resolver.errorReporter.atNode(
      errorNode,
      CompileTimeErrorCode.USE_OF_VOID_RESULT,
    );
  }

  void _resolveArguments_finishInference(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var rawType = node.methodName.staticType;
    DartType staticStaticType = MethodInvocationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: node.argumentList,
            contextType: contextType,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: rawType is FunctionType ? rawType : null);
    node.recordStaticType(staticStaticType, resolver: _resolver);
  }

  /// Given that we are accessing a property of the given [classElement] with the
  /// given [propertyName], return the element that represents the property.
  Element? _resolveElement(
      InterfaceElement classElement, SimpleIdentifier propertyName) {
    var augmented = classElement.augmented;
    // TODO(scheglov): Replace with class hierarchy.
    String name = propertyName.name;
    Element? element;
    if (propertyName.inSetterContext()) {
      element = augmented.getSetter(name);
    }
    element ??= augmented.getGetter(name);
    element ??= augmented.getMethod(name);
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  /// Resolves the method invocation, [node], as an extension member.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveExtensionMember(
      MethodInvocationImpl node,
      Identifier receiver,
      ExtensionElement extension,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var getter = extension.getGetter(name);
    if (getter != null) {
      nameNode.staticElement = getter;
      _reportStaticAccessToInstanceMember(getter, nameNode);
      return _rewriteAsFunctionExpressionInvocation(node, getter.returnType);
    }

    var method = extension.getMethod(name);
    if (method != null) {
      nameNode.staticElement = method;
      _reportStaticAccessToInstanceMember(method, nameNode);
      _setResolution(node, method.type, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    // This method is only called for named extensions, so we know that
    // `extension.name` is non-`null`.
    _resolver.errorReporter.atNode(
      nameNode,
      CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
      arguments: [name, extension.name!],
    );
    return null;
  }

  /// Resolves the method invocation, [node], as called on an extension
  /// override.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveExtensionOverride(
      MethodInvocationImpl node,
      ExtensionOverride override,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var result = _extensionResolver.getOverrideMember(override, name);
    var member = result.getter;

    if (member == null) {
      _setInvalidTypeResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      // Extension overrides always refer to named extensions, so we can safely
      // assume `override.staticElement!.name` is non-`null`.
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
        arguments: [name, override.element.name!],
      );
      return null;
    }

    if (member.isStatic) {
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
      );
    }

    if (node.isCascaded) {
      // Report this error and recover by treating it like a non-cascade.
      _resolver.errorReporter.atToken(
        override.name,
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
      );
    }

    nameNode.staticElement = member;

    if (member is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, member.returnType);
    }

    _setResolution(node, member.type, whyNotPromotedList,
        contextType: contextType);
    return null;
  }

  void _resolveReceiverDynamicBounded(MethodInvocationImpl node,
      DartType receiverType, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var nameNode = node.methodName;

    var objectElement = _typeSystem.typeProvider.objectElement;
    var target = objectElement.getMethod(nameNode.name);

    FunctionType? rawType;
    if (receiverType is InvalidType) {
      nameNode.staticElement = null;
      nameNode.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      node.staticInvokeType = InvalidTypeImpl.instance;
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
    } else if (target != null &&
        !target.isStatic &&
        _hasMatchingObjectMethod(target, node.argumentList.arguments)) {
      nameNode.staticElement = target;
      rawType = target.type;
      nameNode.setPseudoExpressionStaticType(target.type);
      node.staticInvokeType = target.type;
      node.recordStaticType(target.returnType, resolver: _resolver);
    } else {
      nameNode.staticElement = null;
      nameNode.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.staticInvokeType = DynamicTypeImpl.instance;
      node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
    }

    _setExplicitTypeArgumentTypes();
    MethodInvocationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: node.argumentList,
            whyNotPromotedList: whyNotPromotedList,
            contextType: contextType)
        .resolveInvocation(rawType: rawType);
  }

  /// Resolves the method invocation, [node], as an instance invocation on an
  /// expression of type `Never` or `Never?`.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverNever(
    MethodInvocationImpl node,
    Expression receiver,
    DartType receiverType,
    List<WhyNotPromotedGetter> whyNotPromotedList, {
    required DartType contextType,
    required SimpleIdentifierImpl nameNode,
    required String name,
  }) {
    _setExplicitTypeArgumentTypes();

    if (receiverType == NeverTypeImpl.instanceNullable) {
      var methodName = node.methodName;
      var objectElement = _resolver.typeProvider.objectElement;
      var objectMember = objectElement.getMethod(methodName.name);
      if (objectMember != null) {
        methodName.staticElement = objectMember;
        _setResolution(
          node,
          objectMember.type,
          whyNotPromotedList,
          contextType: contextType,
        );
        return null;
      } else {
        return _resolveReceiverType(
          node: node,
          receiver: receiver,
          receiverType: receiverType,
          nameNode: nameNode,
          name: name,
          receiverErrorNode: receiver,
          whyNotPromotedList: whyNotPromotedList,
          contextType: contextType,
        );
      }
    }

    if (receiverType == NeverTypeImpl.instance) {
      MethodInvocationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: node.argumentList,
              contextType: contextType,
              whyNotPromotedList: whyNotPromotedList)
          .resolveInvocation(rawType: null);

      _resolver.errorReporter.atNode(
        receiver,
        WarningCode.RECEIVER_OF_TYPE_NEVER,
      );

      node.methodName.setPseudoExpressionStaticType(_dynamicType);
      node.staticInvokeType = _dynamicType;
      node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
      return null;
    }
    return null;
  }

  /// Resolves the method invocation, [node], as an instance invocation on an
  /// expression of type `Null`.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverNull(
      MethodInvocationImpl node,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var scopeLookupResult = nameNode.scopeLookupResult!;
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameNode.token,
    );

    var element = scopeLookupResult.getter;
    if (element != null) {
      nameNode.staticElement = element;
      if (element is MultiplyDefinedElement) {
        MultiplyDefinedElement multiply = element;
        element = multiply.conflictingElements[0];
      }
      if (element is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, element.returnType);
      }
      if (element is ExecutableElement) {
        _setResolution(node, element.type, whyNotPromotedList,
            contextType: contextType);
        return null;
      }
      if (element is VariableElement) {
        _resolver.checkReadOfNotAssignedLocalVariable(nameNode, element);
        var targetType =
            _localVariableTypeProvider.getType(nameNode, isRead: true);
        return _rewriteAsFunctionExpressionInvocation(node, targetType);
      }
      // TODO(scheglov): This is a questionable distinction.
      if (element is PrefixElement) {
        _setInvalidTypeResolution(node,
            whyNotPromotedList: whyNotPromotedList, contextType: contextType);
        _reportPrefixIdentifierNotFollowedByDot(nameNode);
        return null;
      }
      _reportInvocationOfNonFunction(node, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    var receiverType = _resolver.thisType;
    if (receiverType == null) {
      _reportUndefinedFunction(
        node,
        prefix: null,
        name: node.methodName.name,
        whyNotPromotedList: whyNotPromotedList,
        contextType: contextType,
      );
      return null;
    }

    element = scopeLookupResult.setter;
    if (element != null) {
      // If the scope lookup reveals a setter, but no getter, then we may still
      // find the getter by looking up the inheritence chain (via
      // TypePropertyResolver, via `_resolveReceiverType`). However, if the
      // setter that was found is either top-level, or declared in an extension,
      // or is static, then we do not keep searching for the getter; this
      // setter represents the property being accessed (erroneously).
      var noGetterIsPossible =
          element.enclosingElement3 is CompilationUnitElement ||
              element.enclosingElement3 is ExtensionElement ||
              (element is ExecutableElement && element.isStatic);
      if (noGetterIsPossible) {
        nameNode.staticElement = element;

        _setInvalidTypeResolution(node,
            setNameTypeToDynamic: false,
            whyNotPromotedList: whyNotPromotedList,
            contextType: contextType);
        var receiverTypeName = switch (receiverType) {
          InterfaceType() => receiverType.element.name,
          FunctionType() => 'Function',
          _ => '<unknown>',
        };
        _resolver.errorReporter.atNode(
          nameNode,
          CompileTimeErrorCode.UNDEFINED_METHOD,
          arguments: [name, receiverTypeName],
        );
        return null;
      }
    }

    return _resolveReceiverType(
      node: node,
      receiver: null,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: nameNode,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
  }

  /// Resolves the method invocation, [node], as a top-level function
  /// invocation, referenced with a prefix.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverPrefix(
      MethodInvocationImpl node,
      PrefixElement prefix,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    // Note: prefix?.bar is reported as an error in ElementResolver.

    if (name == FunctionElement.LOAD_LIBRARY_NAME) {
      var imports = prefix.imports;
      if (imports.length == 1 &&
          imports[0].prefix is DeferredImportElementPrefix) {
        var importedLibrary = imports[0].importedLibrary;
        var element = importedLibrary?.loadLibraryFunction;
        if (element is ExecutableElement) {
          nameNode.staticElement = element;
          _setResolution(
              node, (element as ExecutableElement).type, whyNotPromotedList,
              contextType: contextType);
          return null;
        }
      }
    }

    var scopeLookupResult = prefix.scope.lookup(name);
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameNode.token,
    );

    var element = scopeLookupResult.getter;
    nameNode.staticElement = element;

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];
    }

    if (element is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, element.returnType);
    }

    if (element is ExecutableElement) {
      _setResolution(node, element.type, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    _reportUndefinedFunction(
      node,
      prefix: prefix.name,
      name: name,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
    return null;
  }

  /// Resolves the method invocation, [node], as an instance invocation a
  /// `super` expression.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverSuper(
      MethodInvocationImpl node,
      SuperExpression receiver,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var enclosingClass = _resolver.enclosingClass;
    if (SuperContext.of(receiver) != SuperContext.valid) {
      _setInvalidTypeResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      return null;
    }

    var augmented = enclosingClass!.augmented;
    var target = _inheritance.getMember2(
      augmented.declaration,
      _currentName!,
      forSuper: true,
    );

    // If there is that concrete dispatch target, then we are done.
    if (target != null) {
      nameNode.staticElement = target;
      if (target is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, target.returnType,
            isSuperAccess: true);
      }
      _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    target = _inheritance.getInherited2(augmented.declaration, _currentName!);
    if (target != null) {
      nameNode.staticElement = target;
      _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);

      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
        arguments: [target.kind.displayName, name],
      );
      return null;
    }

    // Nothing help, there is no target at all.
    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    _resolver.errorReporter.atNode(
      nameNode,
      CompileTimeErrorCode.UNDEFINED_SUPER_METHOD,
      arguments: [name, augmented.declaration.displayName],
    );
    return null;
  }

  /// Resolves the type of the receiver of the method invocation, [node].
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverType({
    required MethodInvocationImpl node,
    required Expression? receiver,
    required DartType receiverType,
    required SimpleIdentifierImpl nameNode,
    required String name,
    required Expression receiverErrorNode,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
    required DartType contextType,
  }) {
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name,
      propertyErrorEntity: nameNode,
      nameErrorEntity: nameNode,
    );

    var callFunctionType = result.callFunctionType;
    if (callFunctionType != null) {
      assert(name == FunctionElement.CALL_METHOD_NAME);
      _setResolution(node, callFunctionType, whyNotPromotedList,
          contextType: contextType);
      // TODO(scheglov): Replace this with using FunctionType directly.
      // Here was erase resolution that _setResolution() sets.
      nameNode.staticElement = null;
      nameNode.setPseudoExpressionStaticType(_dynamicType);
      return null;
    }

    if (receiverType.isDartCoreFunction &&
        name == FunctionElement.CALL_METHOD_NAME) {
      _setResolution(node, DynamicTypeImpl.instance, whyNotPromotedList,
          contextType: contextType);
      nameNode.staticElement = null;
      nameNode.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.staticInvokeType = DynamicTypeImpl.instance;
      node.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      return null;
    }

    var recordField = result.recordField;
    if (recordField != null) {
      return _rewriteAsFunctionExpressionInvocation(node, recordField.type);
    }

    var target = result.getter;
    if (target != null) {
      nameNode.staticElement = target;

      if (target.isStatic) {
        _reportInstanceAccessToStaticMember(
          nameNode,
          target,
          receiver == null,
        );
      }

      if (target is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, target.returnType);
      }
      _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);
      return null;
    }

    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    if (!result.needsGetterError) {
      return null;
    }

    String receiverClassName = '<unknown>';
    if (receiverType is InterfaceType) {
      receiverClassName = receiverType.element.name;
    } else if (receiverType is FunctionType) {
      receiverClassName = 'Function';
    }

    if (!nameNode.isSynthetic) {
      _resolver.errorReporter.atNode(
        nameNode,
        CompileTimeErrorCode.UNDEFINED_METHOD,
        arguments: [name, receiverClassName],
      );
    }
    return null;
  }

  /// Resolves the method invocation, [node], as an method invocation with a
  /// type literal target.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocation? _resolveReceiverTypeLiteral(
      MethodInvocationImpl node,
      InterfaceElement receiver,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    if (node.isCascaded) {
      receiver = _typeType.element;
    }

    var element = _resolveElement(receiver, nameNode);
    if (element != null) {
      if (element is ExecutableElement) {
        nameNode.staticElement = element;
        if (element is PropertyAccessorElement) {
          return _rewriteAsFunctionExpressionInvocation(
              node, element.returnType);
        }
        _setResolution(node, element.type, whyNotPromotedList,
            contextType: contextType);
      } else {
        _reportInvocationOfNonFunction(node, whyNotPromotedList,
            contextType: contextType);
      }
      return null;
    }

    _setInvalidTypeResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    if (nameNode.name == 'new') {
      // Attempting to invoke the unnamed constructor via `C.new(`.
      if (_resolver.isConstructorTearoffsEnabled) {
        _resolver.errorReporter.atNode(
          nameNode,
          CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          arguments: [receiver.displayName],
        );
      } else {
        // [ParserErrorCode.EXPERIMENT_NOT_ENABLED] is reported by the parser.
        // Do not report extra errors.
      }
    } else {
      _resolver.errorReporter.atNode(
        node.methodName,
        CompileTimeErrorCode.UNDEFINED_METHOD,
        arguments: [name, receiver.displayName],
      );
    }
    return null;
  }

  /// Rewrites [node] as a [FunctionExpressionInvocation].
  ///
  /// We have identified that [node] is not a real [MethodInvocation],
  /// because it does not invoke a method, but instead invokes the result
  /// of a getter execution, or implicitly invokes the `call` method of
  /// an [InterfaceType]. So, it should be represented as instead as a
  /// [FunctionExpressionInvocation].
  FunctionExpressionInvocation _rewriteAsFunctionExpressionInvocation(
      MethodInvocationImpl node, DartType getterReturnType,
      {bool isSuperAccess = false}) {
    var targetType = _typeSystem.resolveToBound(getterReturnType);

    ExpressionImpl functionExpression;
    var target = node.target;
    if (target == null) {
      functionExpression = node.methodName;
      var element = node.methodName.staticElement;
      if (element is ExecutableElement &&
          element.enclosingElement3 is InstanceElement &&
          !element.isStatic) {
        targetType = _resolver.flowAnalysis.flow
                ?.propertyGet(
                    functionExpression,
                    node.isCascaded
                        ? CascadePropertyTarget.singleton
                        : ThisPropertyTarget.singleton,
                    node.methodName.name,
                    element,
                    SharedTypeView(getterReturnType))
                ?.unwrapTypeView() ??
            targetType;
      }
    } else {
      if (target is SimpleIdentifierImpl &&
          target.staticElement is PrefixElement) {
        functionExpression = PrefixedIdentifierImpl(
          prefix: target,
          period: node.operator!,
          identifier: node.methodName,
        );
      } else {
        functionExpression = PropertyAccessImpl(
          target: target,
          operator: node.operator!,
          propertyName: node.methodName,
        );
      }
      if (target is SuperExpressionImpl) {
        targetType = _resolver.flowAnalysis.flow
                ?.propertyGet(
                    functionExpression,
                    SuperPropertyTarget.singleton,
                    node.methodName.name,
                    node.methodName.staticElement,
                    SharedTypeView(getterReturnType))
                ?.unwrapTypeView() ??
            targetType;
      } else {
        targetType = _resolver.flowAnalysis.flow
                ?.propertyGet(
                    functionExpression,
                    ExpressionPropertyTarget(target),
                    node.methodName.name,
                    node.methodName.staticElement,
                    SharedTypeView(getterReturnType))
                ?.unwrapTypeView() ??
            targetType;
      }
      functionExpression.setPseudoExpressionStaticType(targetType);
    }
    inferenceLogWriter
        ?.enterFunctionExpressionInvocationTarget(node.methodName);
    node.methodName.recordStaticType(targetType, resolver: _resolver);
    inferenceLogWriter?.exitExpression(node.methodName);

    var invocation = FunctionExpressionInvocationImpl(
      function: functionExpression,
      typeArguments: node.typeArguments,
      argumentList: node.argumentList,
    );
    _resolver.replaceExpression(node, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
    return invocation;
  }

  void _setDynamicTypeResolution(MethodInvocationImpl node,
      {bool setNameTypeToDynamic = true,
      required List<WhyNotPromotedGetter> whyNotPromotedList,
      required DartType contextType}) {
    if (setNameTypeToDynamic) {
      node.methodName.setPseudoExpressionStaticType(_dynamicType);
    }
    node.staticInvokeType = _dynamicType;
    node.setPseudoExpressionStaticType(_dynamicType);
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(node, whyNotPromotedList,
        contextType: contextType);
  }

  /// Set explicitly specified type argument types, or empty if not specified.
  /// Inference is done in type analyzer, so inferred type arguments might be
  /// set later.
  ///
  // TODO(scheglov): when we do inference in this resolver, do we need this?
  void _setExplicitTypeArgumentTypes() {
    var typeArgumentList = _invocation!.typeArguments;
    if (typeArgumentList != null) {
      var arguments = typeArgumentList.arguments;
      _invocation!.typeArgumentTypes =
          arguments.map((n) => n.typeOrThrow).toList();
    } else {
      _invocation!.typeArgumentTypes = [];
    }
  }

  void _setInvalidTypeResolution(MethodInvocationImpl node,
      {bool setNameTypeToDynamic = true,
      required List<WhyNotPromotedGetter> whyNotPromotedList,
      required DartType contextType}) {
    if (setNameTypeToDynamic) {
      node.methodName.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
    }
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(node, whyNotPromotedList,
        contextType: contextType);
    node.staticInvokeType = InvalidTypeImpl.instance;
    node.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
  }

  void _setResolution(MethodInvocationImpl node, DartType type,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    inferenceLogWriter?.recordLookupResult(
        expression: node,
        type: type,
        target: node.target,
        methodName: node.methodName.name);
    // TODO(scheglov): We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.methodName.setPseudoExpressionStaticType(type);

    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicTypeResolution(node,
          setNameTypeToDynamic: false,
          whyNotPromotedList: whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (type is FunctionType) {
      _inferenceHelper.resolveMethodInvocation(
          node: node,
          rawType: type,
          whyNotPromotedList: whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (type is VoidType) {
      return _reportUseOfVoidType(node, node.methodName, whyNotPromotedList,
          contextType: contextType);
    }

    _reportInvocationOfNonFunction(node, whyNotPromotedList,
        contextType: contextType);
  }

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static InterfaceElement? getTypeReference(Expression expression) {
    if (expression is Identifier) {
      var staticElement = expression.staticElement;
      if (staticElement is InterfaceElement) {
        return staticElement;
      }
    }
    return null;
  }
}
