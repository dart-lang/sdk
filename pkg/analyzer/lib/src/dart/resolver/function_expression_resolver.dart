// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/resolver.dart';

class FunctionExpressionResolver {
  final ResolverVisitor _resolver;

  FunctionExpressionResolver({required ResolverVisitor resolver})
      : _resolver = resolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(FunctionExpressionImpl node, {required DartType contextType}) {
    var parent = node.parent;
    // Note: `isFunctionDeclaration` must have an explicit type to work around
    // https://github.com/dart-lang/language/issues/1785.
    bool isFunctionDeclaration = parent is FunctionDeclaration;
    var body = node.body;

    if (_resolver.flowAnalysis.flow != null && !isFunctionDeclaration) {
      _resolver.flowAnalysis
          .executableDeclaration_enter(node, node.parameters, isClosure: true);
    }

    bool wasFunctionTypeSupplied = contextType is FunctionType;
    node.wasFunctionTypeSupplied = wasFunctionTypeSupplied;
    DartType? imposedType;
    if (wasFunctionTypeSupplied) {
      var instantiatedType = _matchTypeParameters(
        node.typeParameters,
        contextType,
      );
      if (instantiatedType is FunctionType) {
        _inferFormalParameters(node.parameters, instantiatedType);
        var returnType = instantiatedType.returnType;
        if (!(returnType is DynamicType || returnType is UnknownInferredType)) {
          imposedType = returnType;
        }
      }
    }

    node.typeParameters?.accept(_resolver);
    node.parameters?.accept(_resolver);
    imposedType = node.body.resolve(_resolver, imposedType);
    if (isFunctionDeclaration) {
      // A side effect of visiting the children is that the parameters are now
      // in scope, so we can visit the documentation comment now.
      parent.documentationComment?.accept(_resolver);
    }
    _resolve2(node, imposedType);

    if (_resolver.flowAnalysis.flow != null && !isFunctionDeclaration) {
      _resolver.checkForBodyMayCompleteNormally(
        body: body,
        errorNode: body,
      );
      _resolver.flowAnalysis.flow?.functionExpression_end();
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
      if (p.hasImplicitType && p.type is DynamicType) {
        // If no type is declared for a parameter and there is a
        // corresponding parameter in the context type schema with type
        // schema `K`, the parameter is given an inferred type `T` where `T`
        // is derived from `K` as follows.
        inferredType = _typeSystem.greatestClosureOfSchema(inferredType);

        // If the greatest closure of `K` is `S` and `S` is a subtype of
        // `Null`, then `T` is `Object?`. Otherwise, `T` is `S`.
        if (_typeSystem.isSubtypeOf(inferredType, _typeSystem.nullNone)) {
          inferredType = _typeSystem.objectQuestion;
        }
        if (inferredType is! DynamicType) {
          p.type = inferredType;
        }
      }
    }

    var parameters = node.parameterElements.nonNulls;
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
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }).toList());
  }

  void _resolve2(FunctionExpressionImpl node, DartType? imposedType) {
    var functionElement = node.declaredElement as ExecutableElementImpl;

    if (_shouldUpdateReturnType(node)) {
      functionElement.returnType = imposedType ?? DynamicTypeImpl.instance;
    }

    node.recordStaticType(functionElement.type, resolver: _resolver);
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
