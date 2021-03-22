// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';

class InvocationInferenceHelper {
  final ResolverVisitor _resolver;
  final ErrorReporter _errorReporter;
  final TypeSystemImpl _typeSystem;
  final MigrationResolutionHooks? _migrationResolutionHooks;
  final bool _genericMetadataIsEnabled;

  List<DartType>? _typeArgumentTypes;
  FunctionType? _invokeType;

  InvocationInferenceHelper({
    required ResolverVisitor resolver,
    required ErrorReporter errorReporter,
    required TypeSystemImpl typeSystem,
    required MigrationResolutionHooks? migrationResolutionHooks,
  })   : _resolver = resolver,
        _errorReporter = errorReporter,
        _typeSystem = typeSystem,
        _migrationResolutionHooks = migrationResolutionHooks,
        _genericMetadataIsEnabled = resolver.definingLibrary.featureSet
            .isEnabled(Feature.generic_metadata);

  /// Compute the return type of the method or function represented by the given
  /// type that is being invoked.
  DartType computeInvokeReturnType(DartType? type) {
    if (type is FunctionType) {
      return type.returnType;
    } else {
      return DynamicTypeImpl.instance;
    }
  }

  FunctionType? inferArgumentTypesForGeneric(AstNode inferenceNode,
      DartType? uninstantiatedType, TypeArgumentList? typeArguments,
      {AstNode? errorNode, bool isConst = false}) {
    errorNode ??= inferenceNode;
    uninstantiatedType = _getFreshType(uninstantiatedType);
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
        genericMetadataIsEnabled: _genericMetadataIsEnabled,
      );
      if (typeArguments != null) {
        return uninstantiatedType.instantiate(typeArguments);
      }
    }
    return null;
  }

  void inferArgumentTypesForInvocation(
    InvocationExpression node,
    DartType? type,
  ) {
    var inferred = inferArgumentTypesForGeneric(node, type, node.typeArguments);
    InferenceContext.setType(
        node.argumentList, inferred ?? node.staticInvokeType);
  }

  /// Given a possibly generic invocation like `o.m(args)` or `(f)(args)` try to
  /// infer the instantiated generic function type.
  ///
  /// This takes into account both the context type, as well as information from
  /// the argument types.
  void inferGenericInvocationExpression(
    InvocationExpressionImpl node,
    DartType? type,
  ) {
    var arguments = node.argumentList;
    var freshType = _getFreshType(type);

    var inferred = inferGenericInvoke(
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
  FunctionType? inferGenericInvoke(
      AstNode node,
      DartType? fnType,
      TypeArgumentList? typeArguments,
      ArgumentList argumentList,
      AstNode errorNode,
      {bool isConst = false}) {
    if (typeArguments == null &&
        fnType is FunctionType &&
        fnType.typeFormals.isNotEmpty) {
      // Get the parameters that correspond to the uninstantiated generic.
      var typeArgs = _inferUpwards(
        rawType: fnType,
        argumentList: argumentList,
        contextType: InferenceContext.getContext(node),
        isConst: isConst,
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
        var typeArgs =
            typeArguments.arguments.map((n) => n.typeOrThrow).toList();
        node.typeArgumentTypes = typeArgs;
      } else {
        node.typeArgumentTypes = const <DartType>[];
      }
    }

    return null;
  }

  /// Given an uninstantiated generic function type, referenced by the
  /// [identifier] in the tear-off [expression], try to infer the instantiated
  /// generic function type from the surrounding context.
  DartType inferTearOff(
    Expression expression,
    SimpleIdentifier identifier,
    DartType tearOffType,
  ) {
    var context = InferenceContext.getContext(expression);
    if (context is FunctionType && tearOffType is FunctionType) {
      var typeArguments = _typeSystem.inferFunctionTypeInstantiation(
        context,
        tearOffType,
        errorReporter: _resolver.errorReporter,
        errorNode: expression,
        genericMetadataIsEnabled: _genericMetadataIsEnabled,
      )!;
      (identifier as SimpleIdentifierImpl).tearOffTypeArgumentTypes =
          typeArguments;
      if (typeArguments.isNotEmpty) {
        return tearOffType.instantiate(typeArguments);
      }
    }
    return tearOffType;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplication
  void recordStaticType(ExpressionImpl expression, DartType type) {
    var hooks = _migrationResolutionHooks;
    if (hooks != null) {
      type = hooks.modifyExpressionType(expression, type);
    }

    expression.staticType = type;
    if (_typeSystem.isBottom(type)) {
      _resolver.flowAnalysis?.flow?.handleExit();
    }
  }

  /// Finish resolution of the [FunctionExpressionInvocation].
  ///
  /// We have already found the invoked [ExecutableElement], and the [rawType]
  /// is its not yet instantiated type. Here we perform downwards inference,
  /// resolution of arguments, and upwards inference.
  void resolveFunctionExpressionInvocation({
    required FunctionExpressionInvocationImpl node,
    required FunctionType rawType,
    required List<Map<DartType, NonPromotionReason> Function()>
        whyNotPromotedInfo,
  }) {
    _resolveInvocation(
      rawType: rawType,
      typeArgumentList: node.typeArguments,
      argumentList: node.argumentList,
      contextType: InferenceContext.getContext(node),
      isConst: false,
      errorNode: node.function,
      whyNotPromotedInfo: whyNotPromotedInfo,
    );

    node.typeArgumentTypes = _typeArgumentTypes;
    node.staticInvokeType = _invokeType;
  }

  /// Finish resolution of the [MethodInvocation].
  ///
  /// We have already found the invoked [ExecutableElement], and the [rawType]
  /// is its not yet instantiated type. Here we perform downwards inference,
  /// resolution of arguments, and upwards inference.
  void resolveMethodInvocation({
    required MethodInvocationImpl node,
    required FunctionType rawType,
    required List<Map<DartType, NonPromotionReason> Function()>
        whyNotPromotedInfo,
  }) {
    _resolveInvocation(
      rawType: rawType,
      typeArgumentList: node.typeArguments,
      argumentList: node.argumentList,
      contextType: InferenceContext.getContext(node),
      isConst: false,
      errorNode: node.function,
      whyNotPromotedInfo: whyNotPromotedInfo,
    );

    node.typeArgumentTypes = _typeArgumentTypes;
    node.staticInvokeType = _invokeType;

    var returnType = computeInvokeReturnType(_invokeType);
    var targetType = node.realTarget?.staticType;
    if (targetType != null) {
      returnType = _typeSystem.refineNumericInvocationType(
        targetType,
        node.methodName.staticElement,
        [
          for (var argument in node.argumentList.arguments) argument.typeOrThrow
        ],
        returnType,
      );
    }
    recordStaticType(node, returnType);
  }

  List<DartType>? _inferDownwards({
    required FunctionType rawType,
    required DartType? contextType,
    required bool isConst,
    required AstNode errorNode,
  }) {
    return _typeSystem.inferGenericFunctionOrType(
      typeParameters: rawType.typeFormals,
      parameters: const <ParameterElement>[],
      declaredReturnType: rawType.returnType,
      argumentTypes: const <DartType>[],
      contextReturnType: contextType,
      downwards: true,
      isConst: isConst,
      errorReporter: _errorReporter,
      errorNode: errorNode,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    );
  }

  /// TODO(scheglov) Instead of [isConst] sanitize [contextType] before calling.
  List<DartType>? _inferUpwards({
    required FunctionType rawType,
    required DartType? contextType,
    required ArgumentList argumentList,
    required bool isConst,
    required AstNode errorNode,
  }) {
    rawType = _getFreshType(rawType) as FunctionType;

    // Get the parameters that correspond to the uninstantiated generic.
    List<ParameterElement?> rawParameters =
        ResolverVisitor.resolveArgumentsToParameters(
            argumentList, rawType.parameters, null);

    List<ParameterElement> params = <ParameterElement>[];
    List<DartType> argTypes = <DartType>[];
    for (int i = 0, length = rawParameters.length; i < length; i++) {
      ParameterElement? parameter = rawParameters[i];
      if (parameter != null) {
        params.add(parameter);
        argTypes.add(argumentList.arguments[i].typeOrThrow);
      }
    }
    var typeArgs = _typeSystem.inferGenericFunctionOrType(
      typeParameters: rawType.typeFormals,
      parameters: params,
      declaredReturnType: rawType.returnType,
      argumentTypes: argTypes,
      contextReturnType: contextType,
      isConst: isConst,
      errorReporter: _errorReporter,
      errorNode: errorNode,
      genericMetadataIsEnabled: _genericMetadataIsEnabled,
    );
    return typeArgs;
  }

  bool _isCallToIdentical(AstNode? invocation) {
    if (invocation is MethodInvocation) {
      var invokedMethod = invocation.methodName.staticElement;
      return invokedMethod != null &&
          invokedMethod.name == 'identical' &&
          invokedMethod.library!.isDartCore;
    }
    return false;
  }

  void _resolveArguments(ArgumentList argumentList,
      List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo) {
    _resolver.visitArgumentList(argumentList,
        isIdentical: _isCallToIdentical(argumentList.parent),
        whyNotPromotedInfo: whyNotPromotedInfo);
  }

  void _resolveInvocation({
    required FunctionType rawType,
    required DartType? contextType,
    required TypeArgumentList? typeArgumentList,
    required ArgumentListImpl argumentList,
    required bool isConst,
    required AstNode errorNode,
    required List<Map<DartType, NonPromotionReason> Function()>
        whyNotPromotedInfo,
  }) {
    if (typeArgumentList != null) {
      _resolveInvocationWithTypeArguments(
        rawType: rawType,
        typeArgumentList: typeArgumentList,
        argumentList: argumentList,
        whyNotPromotedInfo: whyNotPromotedInfo,
      );
    } else {
      _resolveInvocationWithoutTypeArguments(
        rawType: rawType,
        contextType: contextType,
        argumentList: argumentList,
        isConst: isConst,
        errorNode: errorNode,
        whyNotPromotedInfo: whyNotPromotedInfo,
      );
    }
    _setCorrespondingParameters(argumentList, _invokeType!);
  }

  void _resolveInvocationWithoutTypeArguments({
    required FunctionType rawType,
    required DartType? contextType,
    required ArgumentList argumentList,
    required bool isConst,
    required AstNode errorNode,
    required List<Map<DartType, NonPromotionReason> Function()>
        whyNotPromotedInfo,
  }) {
    var typeParameters = rawType.typeFormals;

    if (typeParameters.isEmpty) {
      InferenceContext.setType(argumentList, rawType);
      _resolveArguments(argumentList, whyNotPromotedInfo);

      _typeArgumentTypes = const <DartType>[];
      _invokeType = rawType;
    } else {
      rawType = _getFreshType(rawType) as FunctionType;

      var downwardsTypeArguments = _inferDownwards(
        rawType: rawType,
        contextType: contextType,
        isConst: isConst,
        errorNode: errorNode,
      )!;

      var downwardsInvokeType = rawType.instantiate(downwardsTypeArguments);
      InferenceContext.setType(argumentList, downwardsInvokeType);

      _resolveArguments(argumentList, whyNotPromotedInfo);

      _typeArgumentTypes = _inferUpwards(
        rawType: rawType,
        argumentList: argumentList,
        contextType: contextType,
        isConst: isConst,
        errorNode: errorNode,
      );
      _invokeType = rawType.instantiate(_typeArgumentTypes!);
    }
  }

  void _resolveInvocationWithTypeArguments({
    required FunctionType rawType,
    required TypeArgumentList typeArgumentList,
    required ArgumentList argumentList,
    required List<Map<DartType, NonPromotionReason> Function()>
        whyNotPromotedInfo,
  }) {
    var typeParameters = rawType.typeFormals;

    List<DartType> typeArguments;
    if (typeArgumentList.arguments.length != typeParameters.length) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
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
          .toList(growable: true);
    }

    var invokeType = rawType.instantiate(typeArguments);
    InferenceContext.setType(argumentList, invokeType);

    _resolveArguments(argumentList, whyNotPromotedInfo);

    _typeArgumentTypes = typeArguments;
    _invokeType = invokeType;
  }

  void _setCorrespondingParameters(
    ArgumentListImpl argumentList,
    FunctionType invokeType,
  ) {
    var parameters = ResolverVisitor.resolveArgumentsToParameters(
      argumentList,
      invokeType.parameters,
      _errorReporter.reportErrorForNode,
    );
    argumentList.correspondingStaticParameters = parameters;
  }

  static DartType? _getFreshType(DartType? type) {
    if (type is FunctionType) {
      var parameters = getFreshTypeParameters(type.typeFormals);
      return parameters.applyToFunctionType(type);
    } else {
      return type;
    }
  }
}
