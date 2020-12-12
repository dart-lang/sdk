// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:meta/meta.dart';

class FunctionExpressionResolver {
  final ResolverVisitor _resolver;
  final MigrationResolutionHooks _migrationResolutionHooks;
  final InvocationInferenceHelper _inferenceHelper;
  final FlowAnalysisHelper _flowAnalysis;
  final TypePromotionManager _promoteManager;

  FunctionExpressionResolver({
    @required ResolverVisitor resolver,
    @required MigrationResolutionHooks migrationResolutionHooks,
    @required FlowAnalysisHelper flowAnalysis,
    @required TypePromotionManager promoteManager,
  })  : _resolver = resolver,
        _migrationResolutionHooks = migrationResolutionHooks,
        _inferenceHelper = resolver.inferenceHelper,
        _flowAnalysis = flowAnalysis,
        _promoteManager = promoteManager;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(FunctionExpression node) {
    var isFunctionDeclaration = node.parent is FunctionDeclaration;
    var body = node.body;

    if (_flowAnalysis != null) {
      if (_flowAnalysis.flow != null && !isFunctionDeclaration) {
        _flowAnalysis.executableDeclaration_enter(node, node.parameters, true);
      }
    } else {
      _promoteManager.enterFunctionBody(body);
    }

    var contextType = InferenceContext.getContext(node);
    if (contextType is FunctionType) {
      contextType = _matchTypeParameters(
        node.typeParameters,
        contextType,
      );
      if (contextType is FunctionType) {
        _inferFormalParameters(node.parameters, contextType);
        InferenceContext.setType(body, contextType.returnType);
      }
    }

    node.visitChildren(_resolver);
    _resolve2(node);

    if (_flowAnalysis != null) {
      if (_flowAnalysis.flow != null && !isFunctionDeclaration) {
        var bodyContext = BodyInferenceContext.of(node.body);
        _resolver.checkForBodyMayCompleteNormally(
          returnType: bodyContext?.contextType,
          body: body,
          errorNode: body,
        );
        _flowAnalysis.flow?.functionExpression_end();
        _resolver.nullSafetyDeadCodeVerifier?.flowEnd(node);
      }
    } else {
      _promoteManager.exitFunctionBody();
    }
  }

  /// Infer types of implicitly typed formal parameters.
  void _inferFormalParameters(
    FormalParameterList node,
    FunctionType contextType,
  ) {
    if (node == null) {
      return;
    }

    void inferType(ParameterElementImpl p, DartType inferredType) {
      // Check that there is no declared type, and that we have not already
      // inferred a type in some fashion.
      if (p.hasImplicitType && (p.type == null || p.type.isDynamic)) {
        // If no type is declared for a parameter and there is a
        // corresponding parameter in the context type schema with type
        // schema `K`, the parameter is given an inferred type `T` where `T`
        // is derived from `K` as follows.
        inferredType = _typeSystem.greatestClosure(inferredType);

        // If the greatest closure of `K` is `S` and `S` is a subtype of
        // `Null`, then `T` is `Object?`. Otherwise, `T` is `S`.
        if (_typeSystem.isSubtypeOf2(inferredType, _typeSystem.nullNone)) {
          inferredType = _isNonNullableByDefault
              ? _typeSystem.objectQuestion
              : _typeSystem.objectStar;
        }
        if (_migrationResolutionHooks != null) {
          inferredType = _migrationResolutionHooks.modifyInferredParameterType(
              p, inferredType);
        } else {
          inferredType = _typeSystem.nonNullifyLegacy(inferredType);
        }
        if (!inferredType.isDynamic) {
          p.type = inferredType;
        }
      }
    }

    List<ParameterElement> parameters = node.parameterElements;
    {
      Iterator<ParameterElement> positional =
          parameters.where((p) => p.isPositional).iterator;
      Iterator<ParameterElement> fnPositional =
          contextType.parameters.where((p) => p.isPositional).iterator;
      while (positional.moveNext() && fnPositional.moveNext()) {
        inferType(positional.current, fnPositional.current.type);
      }
    }

    {
      Map<String, DartType> namedParameterTypes =
          contextType.namedParameterTypes;
      Iterable<ParameterElement> named = parameters.where((p) => p.isNamed);
      for (ParameterElementImpl p in named) {
        if (!namedParameterTypes.containsKey(p.name)) {
          continue;
        }
        inferType(p, namedParameterTypes[p.name]);
      }
    }
  }

  /// Infers the return type of a local function, either a lambda or
  /// (in strong mode) a local function declaration.
  DartType _inferLocalFunctionReturnType(FunctionExpression node) {
    FunctionBody body = node.body;
    return InferenceContext.getContext(body) ?? DynamicTypeImpl.instance;
  }

  /// Given the downward inference [type], return the function type expressed
  /// in terms of the type parameters from [typeParameterList].
  ///
  /// Return `null` is the number of element in [typeParameterList] is not
  /// the same as the number of type parameters in the [type].
  FunctionType _matchTypeParameters(
      TypeParameterList typeParameterList, FunctionType type) {
    if (typeParameterList == null) {
      if (type.typeFormals.isEmpty) {
        return type;
      }
      return null;
    }

    var typeParameters = typeParameterList.typeParameters;
    if (typeParameters.length != type.typeFormals.length) {
      return null;
    }

    return type.instantiate(typeParameters.map((typeParameter) {
      return typeParameter.declaredElement.instantiate(
        nullabilitySuffix: _resolver.noneOrStarSuffix,
      );
    }).toList());
  }

  void _resolve2(FunctionExpression node) {
    var functionElement = node.declaredElement as ExecutableElementImpl;

    if (_shouldUpdateReturnType(node)) {
      var returnType = _inferLocalFunctionReturnType(node);
      functionElement.returnType = returnType;
    }

    _inferenceHelper.recordStaticType(node, functionElement.type);
  }

  static bool _shouldUpdateReturnType(FunctionExpression node) {
    var parent = node.parent;
    if (parent is FunctionDeclaration) {
      // Local function without declared return type.
      return node.parent.parent is FunctionDeclarationStatement &&
          parent.returnType == null;
    } else {
      // Pure function expression.
      return true;
    }
  }
}
