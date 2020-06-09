// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_demotion.dart';
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
    contextType = nonNullifyType(_resolver.definingLibrary, contextType);

    if (contextType is FunctionType) {
      contextType = _matchFunctionTypeParameters(
        node.typeParameters,
        contextType,
      );
      if (contextType is FunctionType) {
        _inferFormalParameterList(node.parameters, contextType);
        InferenceContext.setType(body, contextType.returnType);
      }
    }

    node.visitChildren(_resolver);
    _resolve2(node);

    if (_flowAnalysis != null) {
      if (_flowAnalysis.flow != null && !isFunctionDeclaration) {
        var bodyContext = BodyInferenceContext.of(node.body);
        _resolver.checkForBodyMayCompleteNormally(
          returnType: bodyContext.contextType,
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

  /// Given a formal parameter list and a function type use the function type
  /// to infer types for any of the parameters which have implicit (missing)
  /// types.  Returns true if inference has occurred.
  bool _inferFormalParameterList(
      FormalParameterList node, DartType functionType) {
    bool inferred = false;
    if (node != null && functionType is FunctionType) {
      void inferType(ParameterElementImpl p, DartType inferredType) {
        // Check that there is no declared type, and that we have not already
        // inferred a type in some fashion.
        if (p.hasImplicitType && (p.type == null || p.type.isDynamic)) {
          inferredType = _typeSystem.greatestClosure(inferredType);
          if (inferredType.isDartCoreNull || inferredType is NeverTypeImpl) {
            inferredType = _isNonNullableByDefault
                ? _typeSystem.objectQuestion
                : _typeSystem.objectStar;
          }
          if (_migrationResolutionHooks != null) {
            inferredType = _migrationResolutionHooks
                .modifyInferredParameterType(p, inferredType);
          }
          if (!inferredType.isDynamic) {
            p.type = inferredType;
            inferred = true;
          }
        }
      }

      List<ParameterElement> parameters = node.parameterElements;
      {
        Iterator<ParameterElement> positional =
            parameters.where((p) => p.isPositional).iterator;
        Iterator<ParameterElement> fnPositional =
            functionType.parameters.where((p) => p.isPositional).iterator;
        while (positional.moveNext() && fnPositional.moveNext()) {
          inferType(positional.current, fnPositional.current.type);
        }
      }

      {
        Map<String, DartType> namedParameterTypes =
            functionType.namedParameterTypes;
        Iterable<ParameterElement> named = parameters.where((p) => p.isNamed);
        for (ParameterElementImpl p in named) {
          if (!namedParameterTypes.containsKey(p.name)) {
            continue;
          }
          inferType(p, namedParameterTypes[p.name]);
        }
      }
    }
    return inferred;
  }

  /// Infers the return type of a local function, either a lambda or
  /// (in strong mode) a local function declaration.
  DartType _inferLocalFunctionReturnType(FunctionExpression node) {
    FunctionBody body = node.body;
    return InferenceContext.getContext(body) ?? DynamicTypeImpl.instance;
  }

  /// Given a downward inference type [fnType], and the declared
  /// [typeParameterList] for a function expression, determines if we can enable
  /// downward inference and if so, returns the function type to use for
  /// inference.
  ///
  /// This will return null if inference is not possible. This happens when
  /// there is no way we can find a subtype of the function type, given the
  /// provided type parameter list.
  FunctionType _matchFunctionTypeParameters(
      TypeParameterList typeParameterList, FunctionType fnType) {
    if (typeParameterList == null) {
      if (fnType.typeFormals.isEmpty) {
        return fnType;
      }

      // A non-generic function cannot be a subtype of a generic one.
      return null;
    }

    NodeList<TypeParameter> typeParameters = typeParameterList.typeParameters;
    if (fnType.typeFormals.isEmpty) {
      // TODO(jmesserly): this is a legal subtype. We don't currently infer
      // here, but we could.  This is similar to
      // Dart2TypeSystem.inferFunctionTypeInstantiation, but we don't
      // have the FunctionType yet for the current node, so it's not quite
      // straightforward to apply.
      return null;
    }

    if (fnType.typeFormals.length != typeParameters.length) {
      // A subtype cannot have different number of type formals.
      return null;
    }

    // Same number of type formals. Instantiate the function type so its
    // parameter and return type are in terms of the surrounding context.
    return fnType.instantiate(typeParameters.map((TypeParameter t) {
      return t.declaredElement.instantiate(
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
