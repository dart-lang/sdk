// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [Annotation] that resolve to a constructor invocation.
class AnnotationInferrer extends FullInvocationInferrer<AnnotationImpl> {
  /// The identifier pointing to the constructor that's being invoked, or `null`
  /// if a constructor name couldn't be found (should only happen when
  /// recovering from errors).  If the constructor is generic, this identifier's
  /// static element will be updated to point to a [ConstructorMember] with type
  /// arguments filled in.
  final SimpleIdentifierImpl? constructorName;

  AnnotationInferrer({required this.constructorName}) : super._();

  @override
  bool get _needsTypeArgumentBoundsCheck => true;

  @override
  ErrorCode get _wrongNumberOfTypeArgumentsErrorCode =>
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;

  @override
  ArgumentListImpl _getArgumentList(AnnotationImpl node) => node.arguments!;

  @override
  bool _getIsConst(AnnotationImpl node) => true;

  @override
  TypeArgumentListImpl? _getTypeArguments(AnnotationImpl node) =>
      node.typeArguments;

  @override
  bool _isGenericInferenceDisabled(ResolverVisitor resolver) =>
      !resolver.genericMetadataIsEnabled;

  @override
  List<ParameterElement>? _storeResult(AnnotationImpl node,
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    if (invokeType != null) {
      var constructorElement = ConstructorMember.from(
        node.element as ConstructorElement,
        invokeType.returnType as InterfaceType,
      );
      constructorName?.staticElement = constructorElement;
      node.element = constructorElement;
      return constructorElement.parameters;
    }
    return null;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [ExtensionOverride].
class ExtensionOverrideInferrer
    extends InvocationInferrer<ExtensionOverrideImpl> {
  const ExtensionOverrideInferrer() : super._();

  @override
  ArgumentListImpl _getArgumentList(ExtensionOverrideImpl node) =>
      node.argumentList;
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes that require full downward and upward inference.
abstract class FullInvocationInferrer<Node extends AstNodeImpl>
    extends InvocationInferrer<Node> {
  const FullInvocationInferrer._() : super._();

  bool get _needsTypeArgumentBoundsCheck => false;

  ErrorCode get _wrongNumberOfTypeArgumentsErrorCode =>
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD;

  @override
  DartType resolveInvocation({
    required ResolverVisitor resolver,
    required Node node,
    required FunctionType? rawType,
    required DartType? contextType,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
  }) {
    var typeArgumentList = _getTypeArguments(node);

    List<DartType>? typeArgumentTypes;
    FunctionType? invokeType;
    GenericInferrer? inferrer;
    if (_isGenericInferenceDisabled(resolver)) {
      if (rawType != null && rawType.typeFormals.isNotEmpty) {
        typeArgumentTypes = List.filled(
          rawType.typeFormals.length,
          DynamicTypeImpl.instance,
        );
      } else {
        typeArgumentTypes = const <DartType>[];
        invokeType = rawType;
      }

      invokeType = rawType?.instantiate(typeArgumentTypes);
    } else if (typeArgumentList != null) {
      if (rawType != null &&
          typeArgumentList.arguments.length != rawType.typeFormals.length) {
        var typeParameters = rawType.typeFormals;
        _reportWrongNumberOfTypeArguments(
            resolver, typeArgumentList, rawType, typeParameters);
        typeArgumentTypes = List.filled(
          typeParameters.length,
          DynamicTypeImpl.instance,
        );
      } else {
        typeArgumentTypes = typeArgumentList.arguments
            .map((typeArgument) => typeArgument.typeOrThrow)
            .toList(growable: true);
        if (rawType != null && _needsTypeArgumentBoundsCheck) {
          var typeParameters = rawType.typeFormals;
          var substitution = Substitution.fromPairs(
            typeParameters,
            typeArgumentTypes,
          );
          for (var i = 0; i < typeParameters.length; i++) {
            var typeParameter = typeParameters[i];
            var bound = typeParameter.bound;
            if (bound != null) {
              bound = resolver.definingLibrary.toLegacyTypeIfOptOut(bound);
              bound = substitution.substituteType(bound);
              var typeArgument = typeArgumentTypes[i];
              if (!resolver.typeSystem.isSubtypeOf(typeArgument, bound)) {
                resolver.errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
                  typeArgumentList.arguments[i],
                  [typeArgument, typeParameter.name, bound],
                );
              }
            }
          }
        }
      }

      invokeType = rawType?.instantiate(typeArgumentTypes);
    } else if (rawType == null || rawType.typeFormals.isEmpty) {
      typeArgumentTypes = const <DartType>[];
      invokeType = rawType;
    } else {
      rawType = getFreshTypeParameters(rawType.typeFormals)
          .applyToFunctionType(rawType);

      inferrer = resolver.typeSystem.setupGenericTypeInference(
        typeParameters: rawType.typeFormals,
        declaredReturnType: rawType.returnType,
        contextReturnType: contextType,
        isConst: _getIsConst(node),
        errorReporter: resolver.errorReporter,
        errorNode: _getErrorNode(node),
        genericMetadataIsEnabled: resolver.genericMetadataIsEnabled,
      );

      invokeType = rawType.instantiate(inferrer.downwardsInfer());
    }

    super.resolveInvocation(
        resolver: resolver,
        node: node,
        rawType: invokeType,
        contextType: contextType,
        whyNotPromotedList: whyNotPromotedList);

    var argumentList = _getArgumentList(node);

    if (inferrer != null) {
      // Get the parameters that correspond to the uninstantiated generic.
      List<ParameterElement?> rawParameters =
          ResolverVisitor.resolveArgumentsToParameters(
        argumentList: argumentList,
        parameters: rawType!.parameters,
      );

      List<ParameterElement> params = <ParameterElement>[];
      List<DartType> argTypes = <DartType>[];
      for (int i = 0, length = rawParameters.length; i < length; i++) {
        ParameterElement? parameter = rawParameters[i];
        if (parameter != null) {
          params.add(parameter);
          argTypes.add(argumentList.arguments[i].typeOrThrow);
        }
      }
      inferrer.constrainArguments(parameters: params, argumentTypes: argTypes);
      typeArgumentTypes = inferrer.upwardsInfer();
      invokeType = rawType.instantiate(typeArgumentTypes);
    }

    var parameters = _storeResult(node, typeArgumentTypes, invokeType);
    if (parameters != null) {
      argumentList.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
        argumentList: argumentList,
        parameters: parameters,
        errorReporter: resolver.errorReporter,
      );
    }
    var returnType = InvocationInferrer.computeInvokeReturnType(invokeType);
    return _refineReturnType(resolver, node, returnType);
  }

  AstNode _getErrorNode(Node node) => node;

  bool _getIsConst(Node node) => false;

  TypeArgumentListImpl? _getTypeArguments(Node node);

  bool _isGenericInferenceDisabled(ResolverVisitor resolver) => false;

  DartType _refineReturnType(
          ResolverVisitor resolver, Node node, DartType returnType) =>
      returnType;

  void _reportWrongNumberOfTypeArguments(
      ResolverVisitor resolver,
      TypeArgumentList typeArgumentList,
      FunctionType rawType,
      List<TypeParameterElement> typeParameters) {
    resolver.errorReporter.reportErrorForNode(
      _wrongNumberOfTypeArgumentsErrorCode,
      typeArgumentList,
      [
        rawType,
        typeParameters.length,
        typeArgumentList.arguments.length,
      ],
    );
  }

  List<ParameterElement>? _storeResult(
      Node node, List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    return invokeType?.parameters;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [FunctionExpressionInvocation].
class FunctionExpressionInvocationInferrer
    extends InvocationExpressionInferrer<FunctionExpressionInvocationImpl> {
  const FunctionExpressionInvocationInferrer() : super._();

  @override
  ExpressionImpl _getErrorNode(FunctionExpressionInvocationImpl node) =>
      node.function;
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [InstanceCreationExpression].
class InstanceCreationInferrer
    extends FullInvocationInferrer<InstanceCreationExpressionImpl> {
  const InstanceCreationInferrer() : super._();

  @override
  bool get _needsTypeArgumentBoundsCheck => true;

  @override
  ArgumentListImpl _getArgumentList(InstanceCreationExpressionImpl node) =>
      node.argumentList;

  @override
  ConstructorNameImpl _getErrorNode(InstanceCreationExpressionImpl node) =>
      node.constructorName;

  @override
  bool _getIsConst(InstanceCreationExpressionImpl node) => node.isConst;

  @override
  TypeArgumentListImpl? _getTypeArguments(InstanceCreationExpressionImpl node) {
    // For an instance creation expression the type arguments are on the
    // constructor name.
    return node.constructorName.type.typeArguments;
  }

  @override
  void _reportWrongNumberOfTypeArguments(
      ResolverVisitor resolver,
      TypeArgumentList typeArgumentList,
      FunctionType rawType,
      List<TypeParameterElement> typeParameters) {
    // Error reporting for instance creations is done elsewhere.
  }

  @override
  List<ParameterElement>? _storeResult(InstanceCreationExpressionImpl node,
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    if (invokeType != null) {
      var constructedType = invokeType.returnType;
      node.constructorName.type.type = constructedType;
      var constructorElement = ConstructorMember.from(
        node.constructorName.staticElement!,
        constructedType as InterfaceType,
      );
      node.constructorName.staticElement = constructorElement;
      return constructorElement.parameters;
    }
    return null;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes derived from [InvocationExpression].
abstract class InvocationExpressionInferrer<
        Node extends InvocationExpressionImpl>
    extends FullInvocationInferrer<Node> {
  const InvocationExpressionInferrer._() : super._();

  @override
  ArgumentListImpl _getArgumentList(Node node) => node.argumentList;

  @override
  Expression _getErrorNode(Node node) => node.function;

  @override
  TypeArgumentListImpl? _getTypeArguments(Node node) => node.typeArguments;

  @override
  List<ParameterElement>? _storeResult(
      Node node, List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    node.typeArgumentTypes = typeArgumentTypes;
    node.staticInvokeType = invokeType ?? DynamicTypeImpl.instance;
    return super._storeResult(node, typeArgumentTypes, invokeType);
  }
}

/// Base class containing functionality for performing type inference on AST
/// nodes that invoke a method, function, or constructor.
abstract class InvocationInferrer<Node extends AstNodeImpl> {
  const InvocationInferrer._();

  /// Performs type inference on an invocation expression of type [Node].
  /// [rawType] should be the type of the function the invocation is resolved to
  /// (with type arguments not applied yet).
  void resolveInvocation({
    required ResolverVisitor resolver,
    required Node node,
    required FunctionType? rawType,
    required DartType? contextType,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
  }) {
    var parameters = rawType?.parameters;
    var namedParameters = <String, ParameterElement>{};
    if (parameters != null) {
      for (var i = 0; i < parameters.length; i++) {
        var parameter = parameters[i];
        if (parameter.isNamed) {
          namedParameters[parameter.name] = parameter;
        }
      }
    }
    var argumentList = _getArgumentList(node);
    resolver.checkUnreachableNode(argumentList);
    var flow = resolver.flowAnalysis.flow;
    var positionalParameterIndex = 0;
    List<EqualityInfo<PromotableElement, DartType>?>? identicalInfo =
        _isIdentical(node) ? [] : null;
    var arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
      ParameterElement? parameter;
      if (argument is NamedExpression) {
        parameter = namedParameters[argument.name.label.name];
      } else if (parameters != null) {
        while (positionalParameterIndex < parameters.length) {
          var candidate = parameters[positionalParameterIndex++];
          if (!candidate.isNamed) {
            parameter = candidate;
            break;
          }
        }
      }
      DartType? parameterContextType;
      if (parameter != null) {
        var parameterType = parameter.type;
        parameterContextType = _computeContextForArgument(
            resolver, node, parameterType, contextType);
      }
      resolver.analyzeExpression(argument, parameterContextType);
      // In case of rewrites, we need to grab the argument again.
      argument = arguments[i];
      if (flow != null) {
        identicalInfo
            ?.add(flow.equalityOperand_end(argument, argument.typeOrThrow));
        whyNotPromotedList.add(flow.whyNotPromoted(argument));
      }
    }
    if (identicalInfo != null) {
      flow?.equalityOperation_end(argumentList.parent as Expression,
          identicalInfo[0], identicalInfo[1]);
    }
  }

  /// Computes the type context that should be used when evaluating a particular
  /// argument of the invocation.  Usually this is just the type of the
  /// corresponding parameter, but it can be different for certain primitive
  /// numeric operations.
  DartType? _computeContextForArgument(ResolverVisitor resolver, Node node,
          DartType parameterType, DartType? methodInvocationContext) =>
      parameterType;

  /// Gets the argument list for the invocation.  TODO(paulberry): remove?
  ArgumentListImpl _getArgumentList(Node node);

  /// Determines whether [node] is an invocation of the core function
  /// `identical` (which needs special flow analysis treatment).
  bool _isIdentical(Node node) => false;

  /// Computes the return type of the method or function represented by the
  /// given type that is being invoked.
  static DartType computeInvokeReturnType(DartType? type) {
    if (type is FunctionType) {
      return type.returnType;
    } else {
      return DynamicTypeImpl.instance;
    }
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [MethodInvocation].
class MethodInvocationInferrer
    extends InvocationExpressionInferrer<MethodInvocationImpl> {
  const MethodInvocationInferrer() : super._();

  @override
  DartType? _computeContextForArgument(
      ResolverVisitor resolver,
      MethodInvocationImpl node,
      DartType parameterType,
      DartType? methodInvocationContext) {
    var contextType = super._computeContextForArgument(
        resolver, node, parameterType, methodInvocationContext);
    var targetType = node.realTarget?.staticType;
    if (targetType != null) {
      contextType = resolver.typeSystem.refineNumericInvocationContext(
          targetType,
          node.methodName.staticElement,
          methodInvocationContext,
          parameterType);
    }
    return contextType;
  }

  @override
  bool _isIdentical(MethodInvocationImpl node) {
    var invokedMethod = node.methodName.staticElement;
    return invokedMethod is FunctionElement &&
        invokedMethod.isDartCoreIdentical &&
        node.argumentList.arguments.length == 2;
  }

  @override
  DartType _refineReturnType(ResolverVisitor resolver,
      MethodInvocationImpl node, DartType returnType) {
    var targetType = node.realTarget?.staticType;
    if (targetType != null) {
      returnType = resolver.typeSystem.refineNumericInvocationType(
        targetType,
        node.methodName.staticElement,
        [
          for (var argument in node.argumentList.arguments) argument.typeOrThrow
        ],
        returnType,
      );
    }
    return returnType;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [RedirectingConstructorInvocation].
class RedirectingConstructorInvocationInferrer
    extends InvocationInferrer<RedirectingConstructorInvocationImpl> {
  const RedirectingConstructorInvocationInferrer() : super._();

  @override
  ArgumentListImpl _getArgumentList(
          RedirectingConstructorInvocationImpl node) =>
      node.argumentList;
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [SuperConstructorInvocation].
class SuperConstructorInvocationInferrer
    extends InvocationInferrer<SuperConstructorInvocationImpl> {
  const SuperConstructorInvocationInferrer() : super._();

  @override
  ArgumentListImpl _getArgumentList(SuperConstructorInvocationImpl node) =>
      node.argumentList;
}
