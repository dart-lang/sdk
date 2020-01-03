// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

class InvocationInferenceHelper {
  final LibraryElementImpl _definingLibrary;
  final ElementTypeProvider _elementTypeProvider;
  final ErrorReporter _errorReporter;
  final FlowAnalysisHelper _flowAnalysis;
  final TypeSystemImpl _typeSystem;
  final TypeProviderImpl _typeProvider;

  InvocationInferenceHelper({
    @required LibraryElementImpl definingLibrary,
    @required ElementTypeProvider elementTypeProvider,
    @required ErrorReporter errorReporter,
    @required FlowAnalysisHelper flowAnalysis,
    @required TypeSystemImpl typeSystem,
  })  : _definingLibrary = definingLibrary,
        _elementTypeProvider = elementTypeProvider,
        _errorReporter = errorReporter,
        _typeSystem = typeSystem,
        _typeProvider = typeSystem.typeProvider,
        _flowAnalysis = flowAnalysis;

  /// Compute the return type of the method or function represented by the given
  /// type that is being invoked.
  DartType /*!*/ computeInvokeReturnType(DartType type,
      {@required bool isNullAware}) {
    TypeImpl /*!*/ returnType;
    if (type is InterfaceType) {
      MethodElement callMethod = type.lookUpMethod2(
          FunctionElement.CALL_METHOD_NAME, _definingLibrary);
      returnType =
          _elementTypeProvider.safeExecutableType(callMethod)?.returnType ??
              DynamicTypeImpl.instance;
    } else if (type is FunctionType) {
      returnType = type.returnType ?? DynamicTypeImpl.instance;
    } else {
      returnType = DynamicTypeImpl.instance;
    }

    if (isNullAware && _typeSystem.isNonNullableByDefault) {
      returnType = _typeSystem.makeNullable(returnType);
    }

    return returnType;
  }

  FunctionType inferArgumentTypesForGeneric(AstNode inferenceNode,
      DartType uninstantiatedType, TypeArgumentList typeArguments,
      {AstNode errorNode, bool isConst = false}) {
    errorNode ??= inferenceNode;
    if (typeArguments == null &&
        uninstantiatedType is FunctionType &&
        uninstantiatedType.typeFormals.isNotEmpty) {
      var typeArguments = _typeSystem.inferGenericFunctionOrType(
        typeParameters: uninstantiatedType.typeFormals,
        parameters: const <ParameterElement>[],
        declaredReturnType: uninstantiatedType.returnType,
        argumentTypes: const <DartType>[],
        contextReturnType: InferenceContext.getContext(inferenceNode),
        downwards: true,
        isConst: isConst,
        errorReporter: _errorReporter,
        errorNode: errorNode,
      );
      if (typeArguments != null) {
        return uninstantiatedType.instantiate(typeArguments);
      }
    }
    return null;
  }

  void inferArgumentTypesForInvocation(InvocationExpression node) {
    DartType inferred = inferArgumentTypesForGeneric(
        node, node.function.staticType, node.typeArguments);
    InferenceContext.setType(
        node.argumentList, inferred ?? node.staticInvokeType);
  }

  /// Given a possibly generic invocation like `o.m(args)` or `(f)(args)` try to
  /// infer the instantiated generic function type.
  ///
  /// This takes into account both the context type, as well as information from
  /// the argument types.
  void inferGenericInvocationExpression(InvocationExpression node) {
    ArgumentList arguments = node.argumentList;
    var type = node.function.staticType;
    var freshType = _getFreshType(type);

    FunctionType inferred = inferGenericInvoke(
        node, freshType, node.typeArguments, arguments, node.function);
    if (inferred != null && inferred != node.staticInvokeType) {
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              arguments, inferred.parameters, null);
      node.staticInvokeType = inferred;
    }
  }

  /// Given a possibly generic invocation or instance creation, such as
  /// `o.m(args)` or `(f)(args)` or `new T(args)` try to infer the instantiated
  /// generic function type.
  ///
  /// This takes into account both the context type, as well as information from
  /// the argument types.
  FunctionType inferGenericInvoke(
      Expression node,
      DartType fnType,
      TypeArgumentList typeArguments,
      ArgumentList argumentList,
      AstNode errorNode,
      {bool isConst = false}) {
    if (typeArguments == null &&
        fnType is FunctionType &&
        fnType.typeFormals.isNotEmpty) {
      // Get the parameters that correspond to the uninstantiated generic.
      List<ParameterElement> rawParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              argumentList, fnType.parameters, null);

      List<ParameterElement> params = <ParameterElement>[];
      List<DartType> argTypes = <DartType>[];
      for (int i = 0, length = rawParameters.length; i < length; i++) {
        ParameterElement parameter = rawParameters[i];
        if (parameter != null) {
          params.add(parameter);
          argTypes.add(argumentList.arguments[i].staticType);
        }
      }
      var typeArgs = _typeSystem.inferGenericFunctionOrType(
        typeParameters: fnType.typeFormals,
        parameters: params,
        declaredReturnType: fnType.returnType,
        argumentTypes: argTypes,
        contextReturnType: InferenceContext.getContext(node),
        isConst: isConst,
        errorReporter: _errorReporter,
        errorNode: errorNode,
      );
      if (node is InvocationExpressionImpl) {
        node.typeArgumentTypes = typeArgs;
      }
      if (typeArgs != null) {
        return fnType.instantiate(typeArgs);
      }
      return fnType;
    }

    // There is currently no other place where we set type arguments
    // for FunctionExpressionInvocation(s), so set it here, if not inferred.
    if (node is FunctionExpressionInvocationImpl) {
      if (typeArguments != null) {
        var typeArgs = typeArguments.arguments.map((n) => n.type).toList();
        node.typeArgumentTypes = typeArgs;
      } else {
        node.typeArgumentTypes = const <DartType>[];
      }
    }

    return null;
  }

  /// Given a method invocation [node], attempt to infer a better
  /// type for the result if the target is dynamic and the method
  /// being called is one of the object methods.
  bool inferMethodInvocationObject(MethodInvocation node) {
    // If we have a call like `toString()` or `libraryPrefix.toString()`, don't
    // infer it.
    Expression target = node.realTarget;
    if (target == null ||
        target is SimpleIdentifier && target.staticElement is PrefixElement) {
      return false;
    }
    DartType nodeType = node.staticInvokeType;
    if (nodeType == null ||
        !nodeType.isDynamic ||
        node.argumentList.arguments.isNotEmpty) {
      return false;
    }
    // Object methods called on dynamic targets can have their types improved.
    String name = node.methodName.name;
    MethodElement inferredElement =
        _typeProvider.objectType.element.getMethod(name);
    if (inferredElement == null || inferredElement.isStatic) {
      return false;
    }
    DartType inferredType =
        _elementTypeProvider.getExecutableType(inferredElement);
    if (inferredType is FunctionType) {
      DartType returnType = inferredType.returnType;
      if (inferredType.parameters.isEmpty &&
          returnType is InterfaceType &&
          _typeProvider.nonSubtypableClasses.contains(returnType.element)) {
        node.staticInvokeType = inferredType;
        recordStaticType(node, inferredType.returnType);
        return true;
      }
    }
    return false;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplication
  void recordStaticType(Expression expression, DartType type) {
    var elementTypeProvider = this._elementTypeProvider;
    if (elementTypeProvider is MigrationResolutionHooks) {
      // TODO(scheglov) type cannot be null
      type = elementTypeProvider.modifyExpressionType(
        expression,
        type ?? DynamicTypeImpl.instance,
      );
    }

    // TODO(scheglov) type cannot be null
    if (type == null) {
      expression.staticType = DynamicTypeImpl.instance;
    } else {
      expression.staticType = type;
      if (identical(type, NeverTypeImpl.instance)) {
        _flowAnalysis?.flow?.handleExit();
      }
    }
  }

  static DartType _getFreshType(DartType type) {
    if (type is FunctionType) {
      var parameters = getFreshTypeParameters(type.typeFormals);
      return parameters.applyToFunctionType(type);
    } else {
      return type;
    }
  }
}
