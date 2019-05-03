// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class MethodInvocationResolver {
  static final _nameCall = new Name(null, 'call');

  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  /// The manager for the inheritance mappings.
  final InheritanceManager2 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElement _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The object keeping track of which elements have had their types promoted.
  final TypePromotionManager _promoteManager;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name _currentName;

  MethodInvocationResolver(this._resolver)
      : _typeType = _resolver.typeProvider.typeType,
        _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _definingLibraryUri = _resolver.definingLibrary.source.uri,
        _promoteManager = _resolver.promoteManager;

  /// The scope used to resolve identifiers.
  Scope get nameScope => _resolver.nameScope;

  void resolve(MethodInvocation node) {
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

    if (receiver is SuperExpression) {
      _resolveReceiverSuper(node, receiver, nameNode, name);
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
        return _resolveArgumentsToFunction(false, argumentList, callMethod);
      }
    } else if (type is FunctionType) {
      return _resolveArgumentsToParameters(
          false, argumentList, type.parameters);
    }
    return null;
  }

  /// If the element of the invoked [targetType] is a getter, then actually
  /// the return type of the [targetType] is invoked.  So, remember the
  /// [targetType] into [MethodInvocationImpl.methodNameType] and return the
  /// actual invoked type.
  DartType _getCalleeType(MethodInvocation node, FunctionType targetType) {
    if (targetType.element.kind == ElementKind.GETTER) {
      (node as MethodInvocationImpl).methodNameType = targetType;
      var calleeType = targetType.returnType;
      calleeType = _resolveTypeParameter(calleeType);
      return calleeType;
    }
    return targetType;
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
        return _resolver.typeSystem.instantiateToBounds(invokeType);
      } else {
        return invokeType.instantiate(arguments.map((n) => n.type).toList());
      }
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

  void _reportUseOfVoidType(MethodInvocation node, AstNode errorNode) {
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
      StaticWarningCode.USE_OF_VOID_RESULT,
      errorNode,
    );
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to the
  /// list of arguments. An error will be reported if any of the arguments cannot
  /// be matched to a parameter. The flag [reportAsError] should be `true` if a
  /// compile-time error should be reported; or `false` if a compile-time warning
  /// should be reported. Return the parameters that correspond to the arguments,
  /// or `null` if no correspondence could be computed.
  List<ParameterElement> _resolveArgumentsToFunction(bool reportAsError,
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(
        reportAsError, argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. The flag [reportAsError]
  /// should be `true` if a compile-time error should be reported; or `false` if
  /// a compile-time warning should be reported. Return the parameters that
  /// correspond to the arguments.
  List<ParameterElement> _resolveArgumentsToParameters(bool reportAsError,
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _resolver.errorReporter.reportErrorForNode,
        reportAsError: reportAsError);
  }

  /// Given that we are accessing a property of the given [classElement] with the
  /// given [propertyName], return the element that represents the property.
  Element _resolveElement(
      ClassElement classElement, SimpleIdentifier propertyName) {
    // TODO(scheglov) Replace with class hierarchy.
    String name = propertyName.name;
    Element element = null;
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

    // We can invoke Object methods on Function.
    var type = _inheritance.getMember(
      _resolver.typeProvider.objectType,
      new Name(null, name),
    );
    if (type != null) {
      nameNode.staticElement = type.element;
      return _setResolution(node, type);
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

    var targetType = _inheritance.getMember(receiverType, _currentName);
    if (targetType != null) {
      var calleeType = _getCalleeType(node, targetType);

      // TODO(scheglov) This is bad, we have to create members here.
      // Find a way to avoid this.
      Element element;
      var baseElement = targetType.element;
      if (baseElement is MethodElement) {
        element = MethodMember.from(baseElement, receiverType);
      } else if (baseElement is PropertyAccessorElement) {
        element = PropertyAccessorMember.from(baseElement, receiverType);
      }
      nameNode.staticElement = element;

      return _setResolution(node, calleeType);
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
    _resolver.errorReporter.reportErrorForNode(
      StaticTypeWarningCode.UNDEFINED_METHOD,
      nameNode,
      [name, receiverType.element.displayName],
    );
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
        var calleeType = _getCalleeType(node, element.type);
        return _setResolution(node, calleeType);
      }
      if (element is VariableElement) {
        var targetType = _promoteManager.getStaticType(element);
        return _setResolution(node, targetType);
      }
      // TODO(scheglov) This is a questionable distinction.
      if (element is PrefixElement) {
        _setDynamicResolution(node);
        return _reportPrefixIdentifierNotFollowedByDot(nameNode);
      }
      return _reportInvocationOfNonFunction(node);
    }

    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      return _reportUndefinedFunction(node, node.methodName);
    }

    var receiverType = enclosingClass.type;
    var targetType = _inheritance.getMember(receiverType, _currentName);

    if (targetType != null) {
      nameNode.staticElement = targetType.element;
      var calleeType = _getCalleeType(node, targetType);
      return _setResolution(node, calleeType);
    }

    var targetElement = _lookUpClassMember(enclosingClass, name);
    if (targetElement != null && targetElement.isStatic) {
      nameNode.staticElement = targetElement;
      _setDynamicResolution(node);
      _resolver.errorReporter.reportErrorForNode(
        StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
        nameNode,
        [receiverType.displayName],
      );
      return;
    }

    return _reportUndefinedMethod(node, name, enclosingClass);
  }

  void _resolveReceiverPrefix(MethodInvocation node, SimpleIdentifier receiver,
      PrefixElement prefix, SimpleIdentifier nameNode, String name) {
    if (node.operator.type == TokenType.QUESTION_PERIOD) {
      _reportPrefixIdentifierNotFollowedByDot(receiver);
    }

    if (name == FunctionElement.LOAD_LIBRARY_NAME) {
      var imports = _definingLibrary.getImportsWithPrefix(prefix);
      if (imports.length == 1 && imports[0].isDeferred) {
        var importedLibrary = imports[0].importedLibrary;
        var loadLibraryFunction = importedLibrary?.loadLibraryFunction;
        nameNode.staticElement = loadLibraryFunction;
        node.staticInvokeType = loadLibraryFunction?.type;
        node.staticType = loadLibraryFunction?.returnType;
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
      var calleeType = _getCalleeType(node, element.type);
      return _setResolution(node, calleeType);
    }

    _reportUndefinedFunction(node, prefixedName);
  }

  void _resolveReceiverSuper(MethodInvocation node, SuperExpression receiver,
      SimpleIdentifier nameNode, String name) {
    if (!_isSuperInValidContext(receiver)) {
      return;
    }

    var receiverType = _resolver.enclosingClass.type;
    var targetType = _inheritance.getMember(
      receiverType,
      _currentName,
      forSuper: true,
    );

    // If there is that concrete dispatch target, then we are done.
    if (targetType != null) {
      nameNode.staticElement = targetType.element;
      var calleeType = _getCalleeType(node, targetType);
      _setResolution(node, calleeType);
      return;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    targetType = _inheritance.getInherited(receiverType, _currentName);
    if (targetType != null) {
      nameNode.staticElement = targetType.element;
      var calleeType = _getCalleeType(node, targetType);
      _setResolution(node, calleeType);

      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
          nameNode,
          [targetType.element.kind.displayName, name]);
      return;
    }

    // Nothing help, there is no target at all.
    _setDynamicResolution(node);
    _resolver.errorReporter.reportErrorForNode(
        StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
        nameNode,
        [name, _resolver.enclosingClass.displayName]);
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
        var calleeType = _getCalleeType(node, element.type);
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
  }

  void _setResolution(MethodInvocation node, DartType type) {
    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicResolution(node);
      return;
    }

    // TODO(scheglov) We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.methodName.staticType = type;

    if (type is InterfaceType) {
      var call = _inheritance.getMember(type, _nameCall);
      if (call != null && call.element.kind == ElementKind.METHOD) {
        type = call;
      }
    }

    if (type is FunctionType) {
      // TODO(scheglov) Extract this when receiver is already FunctionType?
      var instantiatedType = _instantiateFunctionType(
        type,
        node.typeArguments,
        node.methodName,
      );
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

  /// Return `true` if the given 'super' [expression] is used in a valid context.
  static bool _isSuperInValidContext(SuperExpression expression) {
    for (AstNode node = expression; node != null; node = node.parent) {
      if (node is CompilationUnit) {
        return false;
      } else if (node is ConstructorDeclaration) {
        return node.factoryKeyword == null;
      } else if (node is ConstructorFieldInitializer) {
        return false;
      } else if (node is MethodDeclaration) {
        return !node.isStatic;
      }
    }
    return false;
  }
}
