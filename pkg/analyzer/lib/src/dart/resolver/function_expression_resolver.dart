// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:collection/collection.dart';

class FunctionExpressionResolver {
  final ResolverVisitor _resolver;
  final MigrationResolutionHooks? _migrationResolutionHooks;
  final InvocationInferenceHelper _inferenceHelper;

  FunctionExpressionResolver({
    required ResolverVisitor resolver,
    required MigrationResolutionHooks? migrationResolutionHooks,
  })   : _resolver = resolver,
        _migrationResolutionHooks = migrationResolutionHooks,
        _inferenceHelper = resolver.inferenceHelper;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(FunctionExpressionImpl node) {
    var isFunctionDeclaration = node.parent is FunctionDeclaration;
    var body = node.body;

    if (_resolver.flowAnalysis!.flow != null && !isFunctionDeclaration) {
      _resolver.flowAnalysis!
          .executableDeclaration_enter(node, node.parameters, true);
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

    if (_resolver.flowAnalysis!.flow != null && !isFunctionDeclaration) {
      var bodyContext = BodyInferenceContext.of(node.body);
      _resolver.checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
        body: body,
        errorNode: body,
      );
      _resolver.flowAnalysis!.flow?.functionExpression_end();
      _resolver.nullSafetyDeadCodeVerifier.flowEnd(node);
    }
  }

  /// Infer types of implicitly typed formal parameters.
  void _inferFormalParameters(
    FormalParameterList? node,
    FunctionType contextType,
  ) {
    if (node == null) {
      return;
    }

    void inferType(ParameterElementImpl p, DartType inferredType) {
      // Check that there is no declared type, and that we have not already
      // inferred a type in some fashion.
      if (p.hasImplicitType && p.type.isDynamic) {
        // If no type is declared for a parameter and there is a
        // corresponding parameter in the context type schema with type
        // schema `K`, the parameter is given an inferred type `T` where `T`
        // is derived from `K` as follows.
        inferredType = _typeSystem.greatestClosureOfSchema(inferredType);

        // If the greatest closure of `K` is `S` and `S` is a subtype of
        // `Null`, then `T` is `Object?`. Otherwise, `T` is `S`.
        if (_typeSystem.isSubtypeOf(inferredType, _typeSystem.nullNone)) {
          inferredType = _isNonNullableByDefault
              ? _typeSystem.objectQuestion
              : _typeSystem.objectStar;
        }
        if (_migrationResolutionHooks != null) {
          inferredType = _migrationResolutionHooks!
              .modifyInferredParameterType(p, inferredType);
        } else {
          inferredType = _typeSystem.nonNullifyLegacy(inferredType);
        }
        if (!inferredType.isDynamic) {
          p.type = inferredType;
        }
      }
    }

    var parameters = node.parameterElements.whereNotNull();
    {
      Iterator<ParameterElement> positional =
          parameters.where((p) => p.isPositional).iterator;
      Iterator<ParameterElement> fnPositional =
          contextType.parameters.where((p) => p.isPositional).iterator;
      while (positional.moveNext() && fnPositional.moveNext()) {
        inferType(positional.current as ParameterElementImpl,
            fnPositional.current.type);
      }
    }

    {
      Map<String, DartType> namedParameterTypes =
          contextType.namedParameterTypes;
      Iterable<ParameterElement> named = parameters.where((p) => p.isNamed);
      for (var p in named) {
        if (!namedParameterTypes.containsKey(p.name)) {
          continue;
        }
        inferType(p as ParameterElementImpl, namedParameterTypes[p.name]!);
      }
    }
  }

  /// Infers the return type of a local function, either a lambda or
  /// (in strong mode) a local function declaration.
  DartType _inferLocalFunctionReturnType(FunctionExpression node) {
    var body = node.body;
    return InferenceContext.getContext(body) ?? DynamicTypeImpl.instance;
  }

  /// Given the downward inference [type], return the function type expressed
  /// in terms of the type parameters from [typeParameterList].
  ///
  /// Return `null` is the number of element in [typeParameterList] is not
  /// the same as the number of type parameters in the [type].
  FunctionType? _matchTypeParameters(
      TypeParameterList? typeParameterList, FunctionType type) {
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
      return typeParameter.declaredElement!.instantiate(
        nullabilitySuffix: _resolver.noneOrStarSuffix,
      );
    }).toList());
  }

  void _resolve2(FunctionExpressionImpl node) {
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
      return parent.parent is FunctionDeclarationStatement &&
          parent.returnType == null;
    } else {
      // Pure function expression.
      return true;
    }
  }
}
