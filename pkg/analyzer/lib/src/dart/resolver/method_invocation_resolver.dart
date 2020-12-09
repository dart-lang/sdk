// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:meta/meta.dart';

class MethodInvocationResolver {
  /// Resolver visitor is separated from the elements resolver, which calls
  /// this method resolver. If we rewrite a [MethodInvocation] node, we put
  /// the resulting [FunctionExpressionInvocation] into the original node
  /// under this key.
  static const _rewriteResultKey = 'methodInvocationRewriteResult';

  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElement _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The object providing promoted or declared types of variables.
  final LocalVariableTypeProvider _localVariableTypeProvider;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final InvocationInferenceHelper _inferenceHelper;

  final MigratableAstInfoProvider _migratableAstInfoProvider;

  /// The invocation being resolved.
  MethodInvocationImpl _invocation;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name _currentName;

  MethodInvocationResolver(
    this._resolver,
    this._migratableAstInfoProvider, {
    @required InvocationInferenceHelper inferenceHelper,
  })  : _typeType = _resolver.typeProvider.typeType,
        _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _definingLibraryUri = _resolver.definingLibrary.source.uri,
        _localVariableTypeProvider = _resolver.localVariableTypeProvider,
        _extensionResolver = _resolver.extensionResolver,
        _inferenceHelper = inferenceHelper;

  /// The scope used to resolve identifiers.
  Scope get nameScope => _resolver.nameScope;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(MethodInvocation node) {
    _invocation = node;

    SimpleIdentifier nameNode = node.methodName;
    String name = nameNode.name;
    _currentName = Name(_definingLibraryUri, name);

    Expression receiver = node.realTarget;

    if (receiver == null) {
      _resolveReceiverNull(node, nameNode, name);
      return;
    }

    if (receiver is SimpleIdentifier) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is PrefixElement) {
        _resolveReceiverPrefix(node, receiverElement, nameNode, name);
        return;
      }
    }

    if (receiver is Identifier) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is ExtensionElement) {
        _resolveExtensionMember(
            node, receiver, receiverElement, nameNode, name);
        return;
      }
    }

    if (receiver is SuperExpression) {
      _resolveReceiverSuper(node, receiver, nameNode, name);
      return;
    }

    if (receiver is ExtensionOverride) {
      _resolveExtensionOverride(node, receiver, nameNode, name);
      return;
    }

    if (receiver is Identifier) {
      var element = receiver.staticElement;
      if (element is ClassElement) {
        _resolveReceiverTypeLiteral(node, element, nameNode, name);
        return;
      } else if (element is FunctionTypeAliasElement) {
        _reportUndefinedMethod(
          node,
          name,
          _resolver.typeProvider.typeType.element,
        );
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          _resolveReceiverTypeLiteral(
              node, aliasedType.element, nameNode, name);
          return;
        }
      }
    }

    DartType receiverType = receiver.staticType;

    if (_typeSystem.isDynamicBounded(receiverType)) {
      _resolveReceiverDynamicBounded(node);
      return;
    }

    if (receiverType is NeverTypeImpl) {
      _resolveReceiverNever(node, receiver, receiverType);
      return;
    }

    if (receiverType is VoidType) {
      _reportUseOfVoidType(node, receiver);
      return;
    }

    if (_migratableAstInfoProvider.isMethodInvocationNullAware(node) &&
        _typeSystem.isNonNullableByDefault) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    if (_typeSystem.isFunctionBounded(receiverType)) {
      _resolveReceiverFunctionBounded(
          node, receiver, receiverType, nameNode, name);
      return;
    }

    _resolveReceiverType(
      node: node,
      receiver: receiver,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: receiver,
    );
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov) Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  void _reportInstanceAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element,
    bool nullReceiver,
  ) {
    if (_resolver.enclosingExtension != null) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
        nameNode,
        [element.enclosingElement.displayName],
      );
    } else if (nullReceiver) {
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

  void _reportInvocationOfNonFunction(MethodInvocation node) {
    _setDynamicResolution(node, setNameTypeToDynamic: false);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION,
      node.methodName,
      [node.methodName.name],
    );
  }

  void _reportPrefixIdentifierNotFollowedByDot(SimpleIdentifier target) {
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
      target,
      [target.name],
    );
  }

  void _reportStaticAccessToInstanceMember(
      ExecutableElement element, SimpleIdentifier nameNode) {
    if (!element.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
        nameNode,
        [nameNode.name],
      );
    }
  }

  void _reportUndefinedFunction(
    MethodInvocation node, {
    @required String prefix,
    @required String name,
  }) {
    _setDynamicResolution(node);

    if (nameScope.shouldIgnoreUndefined2(prefix: prefix, name: name)) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_FUNCTION,
      node.methodName,
      [node.methodName.name],
    );
  }

  void _reportUndefinedMethod(
      MethodInvocation node, String name, ClassElement typeReference) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_METHOD,
      node.methodName,
      [name, typeReference.displayName],
    );
  }

  void _reportUseOfVoidType(MethodInvocation node, AstNode errorNode) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.USE_OF_VOID_RESULT,
      errorNode,
    );
  }

  /// [InvocationExpression.staticInvokeType] has been set for the [node].
  /// Use it to set context for arguments, and resolve them.
  void _resolveArguments(MethodInvocation node) {
    // TODO(scheglov) This is bad, don't write raw type, carry it
    _inferenceHelper.inferArgumentTypesForInvocation(
      node,
      node.methodName.staticType,
    );
    node.argumentList.accept(_resolver);
  }

  void _resolveArguments_finishInference(MethodInvocation node) {
    _resolveArguments(node);

    // TODO(scheglov) This is bad, don't put / get raw FunctionType this way.
    _inferenceHelper.inferGenericInvocationExpression(
      node,
      node.methodName.staticType,
    );

    DartType staticStaticType = _inferenceHelper.computeInvokeReturnType(
      node.staticInvokeType,
    );
    _inferenceHelper.recordStaticType(node, staticStaticType);
  }

  /// Given that we are accessing a property of the given [classElement] with the
  /// given [propertyName], return the element that represents the property.
  Element _resolveElement(
      ClassElement classElement, SimpleIdentifier propertyName) {
    // TODO(scheglov) Replace with class hierarchy.
    String name = propertyName.name;
    Element element;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    element ??= classElement.getGetter(name);
    element ??= classElement.getMethod(name);
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  void _resolveExtensionMember(MethodInvocation node, Identifier receiver,
      ExtensionElement extension, SimpleIdentifier nameNode, String name) {
    var getter = extension.getGetter(name);
    if (getter != null) {
      getter = _resolver.toLegacyElement(getter);
      nameNode.staticElement = getter;
      _reportStaticAccessToInstanceMember(getter, nameNode);
      _rewriteAsFunctionExpressionInvocation(node, getter.returnType);
      return;
    }

    var method = extension.getMethod(name);
    if (method != null) {
      method = _resolver.toLegacyElement(method);
      nameNode.staticElement = method;
      _reportStaticAccessToInstanceMember(method, nameNode);
      _setResolution(node, method.type);
      return;
    }

    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
      nameNode,
      [name, extension.name],
    );
  }

  void _resolveExtensionOverride(MethodInvocation node,
      ExtensionOverride override, SimpleIdentifier nameNode, String name) {
    var result = _extensionResolver.getOverrideMember(override, name);
    var member = _resolver.toLegacyElement(result.getter);

    if (member == null) {
      _setDynamicResolution(node);
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
        nameNode,
        [name, override.staticElement.name],
      );
      return;
    }

    if (member.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        nameNode,
      );
    }

    if (node.isCascaded) {
      // Report this error and recover by treating it like a non-cascade.
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        override.extensionName,
      );
    }

    nameNode.staticElement = member;

    if (member is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, member.returnType);
    }

    _setResolution(node, member.type);
  }

  void _resolveReceiverDynamicBounded(MethodInvocation node) {
    var nameNode = node.methodName;

    var objectElement = _typeSystem.typeProvider.objectElement;
    var target = objectElement.getMethod(nameNode.name);

    var hasMatchingObjectMethod = false;
    if (target is MethodElement) {
      var arguments = node.argumentList.arguments;
      hasMatchingObjectMethod = arguments.length == target.parameters.length &&
          !arguments.any((e) => e is NamedExpression);
      if (hasMatchingObjectMethod) {
        target = _resolver.toLegacyElement(target);
        nameNode.staticElement = target;
        node.staticInvokeType = target.type;
        node.staticType = target.returnType;
      }
    }

    if (!hasMatchingObjectMethod) {
      nameNode.staticType = DynamicTypeImpl.instance;
      node.staticInvokeType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
    }

    _setExplicitTypeArgumentTypes();
    node.argumentList.accept(_resolver);
  }

  void _resolveReceiverFunctionBounded(
    MethodInvocation node,
    Expression receiver,
    DartType receiverType,
    SimpleIdentifier nameNode,
    String name,
  ) {
    if (name == FunctionElement.CALL_METHOD_NAME) {
      _setResolution(node, receiverType);
      // TODO(scheglov) Replace this with using FunctionType directly.
      // Here was erase resolution that _setResolution() sets.
      nameNode.staticElement = null;
      nameNode.staticType = _dynamicType;
      return;
    }

    _resolveReceiverType(
      node: node,
      receiver: receiver,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: nameNode,
    );
  }

  void _resolveReceiverNever(
    MethodInvocation node,
    Expression receiver,
    DartType receiverType,
  ) {
    _setExplicitTypeArgumentTypes();

    if (receiverType == NeverTypeImpl.instanceNullable) {
      var methodName = node.methodName;
      var objectElement = _resolver.typeProvider.objectElement;
      var objectMember = objectElement.getMethod(methodName.name);
      if (objectMember != null) {
        objectMember = _resolver.toLegacyElement(objectMember);
        methodName.staticElement = objectMember;
        _setResolution(
          node,
          objectMember.type,
        );
      } else {
        _setDynamicResolution(node);
        _resolver.nullableDereferenceVerifier.report(receiver, receiverType);
      }
      return;
    }

    if (receiverType == NeverTypeImpl.instance) {
      node.methodName.staticType = _dynamicType;
      node.staticInvokeType = _dynamicType;
      node.staticType = NeverTypeImpl.instance;

      _resolveArguments(node);

      _resolver.errorReporter.reportErrorForNode(
        HintCode.RECEIVER_OF_TYPE_NEVER,
        receiver,
      );
      return;
    }

    if (receiverType == NeverTypeImpl.instanceLegacy) {
      node.methodName.staticType = _dynamicType;
      node.staticInvokeType = _dynamicType;
      node.staticType = _dynamicType;

      _resolveArguments(node);
      return;
    }
  }

  void _resolveReceiverNull(
      MethodInvocation node, SimpleIdentifier nameNode, String name) {
    var element = nameScope.lookup(name).getter;
    if (element != null) {
      element = _resolver.toLegacyElement(element);
      nameNode.staticElement = element;
      if (element is MultiplyDefinedElement) {
        MultiplyDefinedElement multiply = element;
        element = multiply.conflictingElements[0];
      }
      if (element is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, element.returnType);
      }
      if (element is ExecutableElement) {
        return _setResolution(node, element.type);
      }
      if (element is VariableElement) {
        _resolver.checkReadOfNotAssignedLocalVariable(nameNode, element);
        var targetType = _localVariableTypeProvider.getType(nameNode);
        return _rewriteAsFunctionExpressionInvocation(node, targetType);
      }
      // TODO(scheglov) This is a questionable distinction.
      if (element is PrefixElement) {
        _setDynamicResolution(node);
        return _reportPrefixIdentifierNotFollowedByDot(nameNode);
      }
      return _reportInvocationOfNonFunction(node);
    }

    DartType receiverType;
    if (_resolver.enclosingClass != null) {
      receiverType = _resolver.enclosingClass.thisType;
    } else if (_resolver.enclosingExtension != null) {
      receiverType = _resolver.enclosingExtension.extendedType;
    } else {
      return _reportUndefinedFunction(
        node,
        prefix: null,
        name: node.methodName.name,
      );
    }

    _resolveReceiverType(
      node: node,
      receiver: null,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: nameNode,
    );
  }

  void _resolveReceiverPrefix(MethodInvocation node, PrefixElement prefix,
      SimpleIdentifier nameNode, String name) {
    // Note: prefix?.bar is reported as an error in ElementResolver.

    if (name == FunctionElement.LOAD_LIBRARY_NAME) {
      var imports = _definingLibrary.getImportsWithPrefix(prefix);
      if (imports.length == 1 && imports[0].isDeferred) {
        var importedLibrary = imports[0].importedLibrary;
        var element = importedLibrary?.loadLibraryFunction;
        element = _resolver.toLegacyElement(element);
        if (element is ExecutableElement) {
          nameNode.staticElement = element;
          return _setResolution(node, element.type);
        }
      }
    }

    var element = prefix.scope.lookup(name).getter;
    element = _resolver.toLegacyElement(element);
    nameNode.staticElement = element;

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];
    }

    if (element is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, element.returnType);
    }

    if (element is ExecutableElement) {
      return _setResolution(node, element.type);
    }

    _reportUndefinedFunction(
      node,
      prefix: prefix.name,
      name: name,
    );
  }

  void _resolveReceiverSuper(MethodInvocation node, SuperExpression receiver,
      SimpleIdentifier nameNode, String name) {
    var enclosingClass = _resolver.enclosingClass;
    if (SuperContext.of(receiver) != SuperContext.valid) {
      _setDynamicResolution(node);
      return;
    }

    var target = _inheritance.getMember2(
      enclosingClass,
      _currentName,
      forSuper: true,
    );
    target = _resolver.toLegacyElement(target);

    // If there is that concrete dispatch target, then we are done.
    if (target != null) {
      nameNode.staticElement = target;
      if (target is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, target.returnType);
      }
      _setResolution(node, target.type);
      return;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    target = _inheritance.getInherited2(enclosingClass, _currentName);
    if (target != null) {
      nameNode.staticElement = target;
      _setResolution(node, target.type);

      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
          nameNode,
          [target.kind.displayName, name]);
      return;
    }

    // Nothing help, there is no target at all.
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_SUPER_METHOD,
        nameNode,
        [name, enclosingClass.displayName]);
  }

  void _resolveReceiverType({
    @required MethodInvocation node,
    @required Expression receiver,
    @required DartType receiverType,
    @required SimpleIdentifier nameNode,
    @required String name,
    @required Expression receiverErrorNode,
  }) {
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name,
      receiverErrorNode: receiverErrorNode,
      nameErrorEntity: nameNode,
    );

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
      return _setResolution(node, target.type);
    }

    _setDynamicResolution(node);

    if (!result.needsGetterError) {
      return;
    }

    String receiverClassName = '<unknown>';
    if (receiverType is InterfaceType) {
      receiverClassName = receiverType.element.name;
    } else if (receiverType is FunctionType) {
      receiverClassName = 'Function';
    }

    if (!nameNode.isSynthetic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_METHOD,
        nameNode,
        [name, receiverClassName],
      );
    }
  }

  void _resolveReceiverTypeLiteral(MethodInvocation node, ClassElement receiver,
      SimpleIdentifier nameNode, String name) {
    if (node.isCascaded) {
      receiver = _typeType.element;
    }

    var element = _resolveElement(receiver, nameNode);
    element = _resolver.toLegacyElement(element);
    if (element != null) {
      if (element is ExecutableElement) {
        nameNode.staticElement = element;
        if (element is PropertyAccessorElement) {
          return _rewriteAsFunctionExpressionInvocation(
              node, element.returnType);
        }
        _setResolution(node, element.type);
      } else {
        _reportInvocationOfNonFunction(node);
      }
      return;
    }

    _reportUndefinedMethod(node, name, receiver);
  }

  /// If the given [type] is a type parameter, replace with its bound.
  /// Otherwise, return the original type.
  DartType _resolveTypeParameter(DartType type) {
    if (type is TypeParameterType) {
      return type.resolveToBound(_resolver.typeProvider.objectType);
    }
    return type;
  }

  /// We have identified that [node] is not a real [MethodInvocation],
  /// because it does not invoke a method, but instead invokes the result
  /// of a getter execution, or implicitly invokes the `call` method of
  /// an [InterfaceType]. So, it should be represented as instead as a
  /// [FunctionExpressionInvocation].
  void _rewriteAsFunctionExpressionInvocation(
    MethodInvocation node,
    DartType getterReturnType,
  ) {
    var targetType = _resolveTypeParameter(getterReturnType);
    node.methodName.staticType = targetType;

    Expression functionExpression;
    var target = node.target;
    if (target == null) {
      functionExpression = node.methodName;
    } else {
      if (target is SimpleIdentifier && target.staticElement is PrefixElement) {
        functionExpression = astFactory.prefixedIdentifier(
          target,
          node.operator,
          node.methodName,
        );
      } else {
        functionExpression = astFactory.propertyAccess(
          target,
          node.operator,
          node.methodName,
        );
      }
      functionExpression.staticType = targetType;
    }

    var invocation = astFactory.functionExpressionInvocation(
      functionExpression,
      node.typeArguments,
      node.argumentList,
    );
    NodeReplacer.replace(node, invocation);
    node.setProperty(_rewriteResultKey, invocation);
    InferenceContext.setTypeFromNode(invocation, node);
  }

  void _setDynamicResolution(MethodInvocation node,
      {bool setNameTypeToDynamic = true}) {
    if (setNameTypeToDynamic) {
      node.methodName.staticType = _dynamicType;
    }
    node.staticInvokeType = _dynamicType;
    node.staticType = _dynamicType;
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(node);
  }

  /// Set explicitly specified type argument types, or empty if not specified.
  /// Inference is done in type analyzer, so inferred type arguments might be
  /// set later.
  ///
  /// TODO(scheglov) when we do inference in this resolver, do we need this?
  void _setExplicitTypeArgumentTypes() {
    var typeArgumentList = _invocation.typeArguments;
    if (typeArgumentList != null) {
      var arguments = typeArgumentList.arguments;
      _invocation.typeArgumentTypes = arguments.map((n) => n.type).toList();
    } else {
      _invocation.typeArgumentTypes = [];
    }
  }

  void _setResolution(MethodInvocation node, DartType type) {
    // TODO(scheglov) We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.methodName.staticType = type;

    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicResolution(node, setNameTypeToDynamic: false);
      return;
    }

    if (type is FunctionType) {
      _inferenceHelper.resolveMethodInvocation(node: node, rawType: type);
      return;
    }

    if (type is VoidType) {
      return _reportUseOfVoidType(node, node.methodName);
    }

    _reportInvocationOfNonFunction(node);
  }

  /// Resolver visitor is separated from the elements resolver, which calls
  /// this method resolver. If we rewrite a [MethodInvocation] node, this
  /// method will return the resulting [FunctionExpressionInvocation], so
  /// that the resolver visitor will know to continue resolving this new node.
  static FunctionExpressionInvocation getRewriteResult(MethodInvocation node) {
    return node.getProperty(_rewriteResultKey);
  }

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static ClassElement getTypeReference(Expression expression) {
    if (expression is Identifier) {
      Element staticElement = expression.staticElement;
      if (staticElement is ClassElement) {
        return staticElement;
      }
    }
    return null;
  }
}
