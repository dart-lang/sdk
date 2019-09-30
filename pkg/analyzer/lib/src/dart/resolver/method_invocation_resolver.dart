// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

class MethodInvocationResolver {
  static final _nameCall = new Name(null, 'call');

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

  /// The invocation being resolved.
  MethodInvocationImpl _invocation;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name _currentName;

  MethodInvocationResolver(this._resolver)
      : _typeType = _resolver.typeProvider.typeType,
        _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _definingLibraryUri = _resolver.definingLibrary.source.uri,
        _localVariableTypeProvider = _resolver.localVariableTypeProvider,
        _extensionResolver = _resolver.extensionResolver;

  /// The scope used to resolve identifiers.
  Scope get nameScope => _resolver.nameScope;

  void resolve(MethodInvocation node) {
    _invocation = node;

    SimpleIdentifier nameNode = node.methodName;
    String name = nameNode.name;
    _currentName = Name(_definingLibraryUri, name);

    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (nameNode.isSynthetic) {
      return;
    }

    Expression receiver = node.realTarget;

    if (receiver == null) {
      _resolveReceiverNull(node, nameNode, name);
      return;
    }

    if (receiver is NullLiteral) {
      _setDynamicResolution(node);
      return;
    }

    if (receiver is SimpleIdentifier) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is PrefixElement) {
        _resolveReceiverPrefix(node, receiver, receiverElement, nameNode, name);
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

    ClassElement typeReference = getTypeReference(receiver);
    if (typeReference != null) {
      _resolveReceiverTypeLiteral(node, typeReference, nameNode, name);
      return;
    }

    DartType receiverType = receiver.staticType;
    receiverType = _resolveTypeParameter(receiverType);

    if (receiverType is InterfaceType) {
      _resolveReceiverInterfaceType(node, receiverType, nameNode, name);
      return;
    }

    if (receiverType is DynamicTypeImpl) {
      _resolveReceiverDynamic(node, name);
      return;
    }

    if (receiverType is FunctionType) {
      _resolveReceiverFunctionType(
          node, receiver, receiverType, nameNode, name);
      return;
    }

    if (receiverType is VoidType) {
      _reportUseOfVoidType(node, receiver);
      return;
    }

    if (receiverType == BottomTypeImpl.instance) {
      _reportUseOfNeverType(node, receiver);
      return;
    }
  }

  /// Given an [argumentList] and the executable [element] that  will be invoked
  /// using those arguments, compute the list of parameters that correspond to
  /// the list of arguments. Return the parameters that correspond to the
  /// arguments, or `null` if no correspondence could be computed.
  List<ParameterElement> _computeCorrespondingParameters(
      ArgumentList argumentList, DartType type) {
    if (type is InterfaceType) {
      MethodElement callMethod =
          type.lookUpMethod(FunctionElement.CALL_METHOD_NAME, _definingLibrary);
      if (callMethod != null) {
        return _resolveArgumentsToFunction(argumentList, callMethod);
      }
    } else if (type is FunctionType) {
      return _resolveArgumentsToParameters(argumentList, type.parameters);
    }
    return null;
  }

  /// If the invoked [target] is a getter, then actually the return type of
  /// the [target] is invoked.  So, remember the [target] into
  /// [MethodInvocationImpl.methodNameType] and return the actual invoked type.
  DartType _getCalleeType(MethodInvocation node, ExecutableElement target) {
    if (target.kind == ElementKind.GETTER) {
      (node as MethodInvocationImpl).methodNameType = target.type;
      var calleeType = target.returnType;
      calleeType = _resolveTypeParameter(calleeType);
      return calleeType;
    }
    return target.type;
  }

  /// Check for a generic type, and apply type arguments.
  FunctionType _instantiateFunctionType(
      FunctionType invokeType, TypeArgumentList typeArguments, AstNode node) {
    var typeFormals = invokeType.typeFormals;
    var arguments = typeArguments?.arguments;
    if (arguments != null && arguments.length != typeFormals.length) {
      _resolver.errorReporter.reportErrorForNode(
          StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
          node,
          [invokeType, typeFormals.length, arguments?.length ?? 0]);
      arguments = null;
    }

    if (typeFormals.isNotEmpty) {
      if (arguments == null) {
        var typeArguments =
            _resolver.typeSystem.instantiateTypeFormalsToBounds(typeFormals);
        _invocation.typeArgumentTypes = typeArguments;
        return invokeType.instantiate(typeArguments);
      } else {
        var typeArguments = arguments.map((n) => n.type).toList();
        _invocation.typeArgumentTypes = typeArguments;
        return invokeType.instantiate(typeArguments);
      }
    } else {
      _invocation.typeArgumentTypes = const <DartType>[];
    }

    return invokeType;
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov) Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  ExecutableElement _lookUpClassMember(ClassElement element, String name) {
    // TODO(scheglov) Use class hierarchy.
    return element.lookUpMethod(name, _definingLibrary);
  }

  void _reportInvocationOfNonFunction(MethodInvocation node) {
    _setDynamicResolution(node, setNameTypeToDynamic: false);
    _resolver.errorReporter.reportErrorForNode(
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
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

  void _reportUndefinedFunction(
      MethodInvocation node, Identifier ignorableIdentifier) {
    _setDynamicResolution(node);

    // TODO(scheglov) This is duplication.
    if (nameScope.shouldIgnoreUndefined(ignorableIdentifier)) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      StaticTypeWarningCode.UNDEFINED_FUNCTION,
      node.methodName,
      [node.methodName.name],
    );
  }

  void _reportUndefinedMethod(
      MethodInvocation node, String name, ClassElement typeReference) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      StaticTypeWarningCode.UNDEFINED_METHOD,
      node.methodName,
      [name, typeReference.displayName],
    );
  }

  void _reportUseOfNeverType(MethodInvocation node, AstNode errorNode) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      StaticWarningCode.INVALID_USE_OF_NEVER_VALUE,
      errorNode,
    );
  }

  void _reportUseOfVoidType(MethodInvocation node, AstNode errorNode) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      StaticWarningCode.USE_OF_VOID_RESULT,
      errorNode,
    );
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  List<ParameterElement> _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. Return the parameters that
  /// correspond to the arguments.
  List<ParameterElement> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _resolver.errorReporter.reportErrorForNode);
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
    if (element == null) {
      element = classElement.getGetter(name);
    }
    if (element == null) {
      element = classElement.getMethod(name);
    }
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  /// If there is an extension matching the [receiverType] and defining a
  /// member with the given [name], resolve to the corresponding extension
  /// method. Return a result indicating whether the [node] was resolved and if
  /// not why.
  ResolutionResult _resolveExtension(
    MethodInvocation node,
    DartType receiverType,
    SimpleIdentifier nameNode,
    String name,
  ) {
    var result = _extensionResolver.findExtension(
      receiverType,
      name,
      nameNode,
    );

    if (!result.isSingle) {
      _setDynamicResolution(node);
      return result;
    }

    ExecutableElement member = result.getter;
    nameNode.staticElement = member;

    if (member.isStatic) {
      _setDynamicResolution(node);
      _resolver.errorReporter.reportErrorForNode(
          StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
          nameNode,
          [name, member.kind.displayName, member.enclosingElement.name]);
      return result;
    }

    var calleeType = _getCalleeType(node, member);
    _setResolution(node, calleeType);
    return result;
  }

  void _resolveExtensionMember(MethodInvocation node, Identifier receiver,
      ExtensionElement extension, SimpleIdentifier nameNode, String name) {
    ExecutableElement element =
        extension.getMethod(name) ?? extension.getGetter(name);
    if (element == null) {
      _setDynamicResolution(node);
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
        nameNode,
        [name, extension.name],
      );
    } else {
      if (!element.isStatic) {
        _resolver.errorReporter.reportErrorForNode(
            StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
            nameNode,
            [name]);
      }
      nameNode.staticElement = element;
      _setResolution(node, _getCalleeType(node, element));
    }
  }

  void _resolveExtensionOverride(MethodInvocation node,
      ExtensionOverride override, SimpleIdentifier nameNode, String name) {
    var result = _extensionResolver.getOverrideMember(override, name);
    var member = result.getter;

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
      _resolver.errorReporter.reportErrorForToken(
          CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, node.operator);
    }

    nameNode.staticElement = member;
    var calleeType = _getCalleeType(node, member);
    _setResolution(node, calleeType);
  }

  void _resolveReceiverDynamic(MethodInvocation node, String name) {
    _setDynamicResolution(node);
  }

  void _resolveReceiverFunctionType(MethodInvocation node, Expression receiver,
      FunctionType receiverType, SimpleIdentifier nameNode, String name) {
    if (name == FunctionElement.CALL_METHOD_NAME) {
      _setResolution(node, receiverType);
      // TODO(scheglov) Replace this with using FunctionType directly.
      // Here was erase resolution that _setResolution() sets.
      nameNode.staticElement = null;
      nameNode.staticType = _dynamicType;
      return;
    }

    ResolutionResult result =
        _extensionResolver.findExtension(receiverType, name, nameNode);
    if (result.isSingle) {
      nameNode.staticElement = result.getter;
      var calleeType = _getCalleeType(node, result.getter);
      return _setResolution(node, calleeType);
    } else if (result.isAmbiguous) {
      return;
    }
    // We can invoke Object methods on Function.
    var member = _inheritance.getMember(
      _resolver.typeProvider.functionType,
      new Name(null, name),
    );
    if (member != null) {
      nameNode.staticElement = member;
      return _setResolution(node, member.type);
    }

    _reportUndefinedMethod(
      node,
      name,
      _resolver.typeProvider.functionType.element,
    );
  }

  void _resolveReceiverInterfaceType(MethodInvocation node,
      InterfaceType receiverType, SimpleIdentifier nameNode, String name) {
    if (_isCoreFunction(receiverType) &&
        name == FunctionElement.CALL_METHOD_NAME) {
      _setDynamicResolution(node);
      return;
    }

    var target = _inheritance.getMember(receiverType, _currentName);
    if (target != null) {
      nameNode.staticElement = target;
      var calleeType = _getCalleeType(node, target);
      return _setResolution(node, calleeType);
    }

    // Look for an applicable extension.
    var result = _resolveExtension(node, receiverType, nameNode, name);
    if (result.isSingle) {
      return;
    }

    // The interface of the receiver does not have an instance member.
    // Try to recover and find a member in the class.
    var targetElement = _lookUpClassMember(receiverType.element, name);
    if (targetElement != null && targetElement.isStatic) {
      nameNode.staticElement = targetElement;
      _setDynamicResolution(node);
      _resolver.errorReporter.reportErrorForNode(
        StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
        nameNode,
        [
          name,
          targetElement.kind.displayName,
          targetElement.enclosingElement.displayName,
        ],
      );
      return;
    }

    _setDynamicResolution(node);
    if (result.isNone) {
      _resolver.errorReporter.reportErrorForNode(
        StaticTypeWarningCode.UNDEFINED_METHOD,
        nameNode,
        [name, receiverType.element.displayName],
      );
    }
  }

  void _resolveReceiverNull(
      MethodInvocation node, SimpleIdentifier nameNode, String name) {
    var element = nameScope.lookup(nameNode, _definingLibrary);
    if (element != null) {
      nameNode.staticElement = element;
      if (element is MultiplyDefinedElement) {
        MultiplyDefinedElement multiply = element;
        element = multiply.conflictingElements[0];
      }
      if (element is ExecutableElement) {
        var calleeType = _getCalleeType(node, element);
        return _setResolution(node, calleeType);
      }
      if (element is VariableElement) {
        var targetType = _localVariableTypeProvider.getType(nameNode);
        return _setResolution(node, targetType);
      }
      // TODO(scheglov) This is a questionable distinction.
      if (element is PrefixElement) {
        _setDynamicResolution(node);
        return _reportPrefixIdentifierNotFollowedByDot(nameNode);
      }
      return _reportInvocationOfNonFunction(node);
    }

    InterfaceType receiverType;
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      if (_resolver.enclosingExtension == null) {
        return _reportUndefinedFunction(node, node.methodName);
      }
      var extendedType =
          _resolveTypeParameter(_resolver.enclosingExtension.extendedType);
      if (extendedType is InterfaceType) {
        receiverType = extendedType;
      } else if (extendedType is FunctionType) {
        receiverType = _resolver.typeProvider.functionType;
      } else {
        return _reportUndefinedFunction(node, node.methodName);
      }
      enclosingClass = receiverType.element;
    } else {
      receiverType = enclosingClass.thisType;
    }
    var target = _inheritance.getMember(receiverType, _currentName);

    if (target != null) {
      nameNode.staticElement = target;
      var calleeType = _getCalleeType(node, target);
      return _setResolution(node, calleeType);
    }

    var targetElement = _lookUpClassMember(enclosingClass, name);
    if (targetElement != null && targetElement.isStatic) {
      nameNode.staticElement = targetElement;
      _setDynamicResolution(node);
      if (_resolver.enclosingExtension != null) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
            nameNode,
            [targetElement.enclosingElement.displayName]);
      } else {
        _resolver.errorReporter.reportErrorForNode(
            StaticTypeWarningCode
                .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
            nameNode,
            [targetElement.enclosingElement.displayName]);
      }
      return;
    }

    var result = _extensionResolver.findExtension(receiverType, name, nameNode);
    if (result.isSingle) {
      var target = result.getter;
      if (target != null) {
        nameNode.staticElement = target;
        var calleeType = _getCalleeType(node, target);
        _setResolution(node, calleeType);
        return;
      }
    }

    return _reportUndefinedMethod(node, name, enclosingClass);
  }

  void _resolveReceiverPrefix(MethodInvocation node, SimpleIdentifier receiver,
      PrefixElement prefix, SimpleIdentifier nameNode, String name) {
    // Note: prefix?.bar is reported as an error in ElementResolver.

    if (name == FunctionElement.LOAD_LIBRARY_NAME) {
      var imports = _definingLibrary.getImportsWithPrefix(prefix);
      if (imports.length == 1 && imports[0].isDeferred) {
        var importedLibrary = imports[0].importedLibrary;
        var loadLibraryFunction = importedLibrary?.loadLibraryFunction;
        nameNode.staticElement = loadLibraryFunction;
        node.staticInvokeType = loadLibraryFunction?.type;
        node.staticType = loadLibraryFunction?.returnType;
        _setExplicitTypeArgumentTypes();
        return;
      }
    }

    // TODO(scheglov) I don't like how we resolve prefixed names.
    // But maybe this is the only one solution.
    var prefixedName = new PrefixedIdentifierImpl.temp(receiver, nameNode);
    var element = nameScope.lookup(prefixedName, _definingLibrary);
    nameNode.staticElement = element;

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];
    }

    if (element is ExecutableElement) {
      var calleeType = _getCalleeType(node, element);
      return _setResolution(node, calleeType);
    }

    _reportUndefinedFunction(node, prefixedName);
  }

  void _resolveReceiverSuper(MethodInvocation node, SuperExpression receiver,
      SimpleIdentifier nameNode, String name) {
    var enclosingClass = _resolver.enclosingClass;
    if (SuperContext.of(receiver) != SuperContext.valid) {
      return;
    }

    var receiverType = enclosingClass.thisType;
    var target = _inheritance.getMember(
      receiverType,
      _currentName,
      forSuper: true,
    );

    // If there is that concrete dispatch target, then we are done.
    if (target != null) {
      nameNode.staticElement = target;
      var calleeType = _getCalleeType(node, target);
      _setResolution(node, calleeType);
      return;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    target = _inheritance.getInherited(receiverType, _currentName);
    if (target != null) {
      nameNode.staticElement = target;
      var calleeType = _getCalleeType(node, target);
      _setResolution(node, calleeType);

      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
          nameNode,
          [target.kind.displayName, name]);
      return;
    }

    // Nothing help, there is no target at all.
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
        StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
        nameNode,
        [name, enclosingClass.displayName]);
  }

  void _resolveReceiverTypeLiteral(MethodInvocation node, ClassElement receiver,
      SimpleIdentifier nameNode, String name) {
    if (node.isCascaded) {
      receiver = _typeType.element;
    }

    var element = _resolveElement(receiver, nameNode);
    if (element != null) {
      if (element is ExecutableElement) {
        nameNode.staticElement = element;
        var calleeType = _getCalleeType(node, element);
        _setResolution(node, calleeType);
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

  void _setDynamicResolution(MethodInvocation node,
      {bool setNameTypeToDynamic: true}) {
    if (setNameTypeToDynamic) {
      node.methodName.staticType = _dynamicType;
    }
    node.staticInvokeType = _dynamicType;
    node.staticType = _dynamicType;
    _setExplicitTypeArgumentTypes();
  }

  /// Set explicitly specified type argument types, or empty if not specified.
  /// Inference is done in type analyzer, so inferred type arguments might be
  /// set later.
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

    if (type is InterfaceType) {
      var call = _inheritance.getMember(type, _nameCall);
      if (call == null) {
        var result = _extensionResolver.findExtension(
            type, _nameCall.name, node.methodName);
        if (result.isSingle) {
          call = result.getter;
        } else if (result.isAmbiguous) {
          return;
        }
      }
      if (call != null && call.kind == ElementKind.METHOD) {
        type = call.type;
      }
    }

    if (type is FunctionType) {
      // TODO(scheglov) Extract this when receiver is already FunctionType?
      var instantiatedType = _instantiateFunctionType(
        type,
        node.typeArguments,
        node.methodName,
      );
      instantiatedType = _toSyntheticFunctionType(instantiatedType);
      node.staticInvokeType = instantiatedType;
      node.staticType = instantiatedType.returnType;
      // TODO(scheglov) too much magic
      node.argumentList.correspondingStaticParameters =
          _computeCorrespondingParameters(
        node.argumentList,
        instantiatedType,
      );
      return;
    }

    if (type is VoidType) {
      return _reportUseOfVoidType(node, node.methodName);
    }

    if (type == BottomTypeImpl.instance) {
      return _reportUseOfNeverType(node, node.methodName);
    }

    _reportInvocationOfNonFunction(node);
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

  /// As an experiment for using synthetic [FunctionType]s, we replace some
  /// function types with the equivalent synthetic function type instance.
  /// The assumption that we try to prove is that only the set of parameters,
  /// with their names, types and kinds is important, but the element that
  /// encloses them is not (`null` for synthetic function types).
  static FunctionType _toSyntheticFunctionType(FunctionType type) {
//    if (type.element is GenericFunctionTypeElement) {
//      var synthetic = FunctionTypeImpl.synthetic(
//        type.returnType,
//        type.typeFormals.map((e) {
//          return TypeParameterElementImpl.synthetic(e.name)..bound = e.bound;
//        }).toList(),
//        type.parameters.map((p) {
//          return ParameterElementImpl.synthetic(
//            p.name,
//            p.type,
//            // ignore: deprecated_member_use_from_same_package
//            p.parameterKind,
//          );
//        }).toList(),
//      );
//      return synthetic;
//    }
    return type;
  }
}
