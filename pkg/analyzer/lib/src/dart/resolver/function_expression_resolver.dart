// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';

class FunctionExpressionResolver {
  final TypeAnalyzer _typeAnalyzer;

  new({required this._typeAnalyzer});

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  void resolve(FunctionExpressionImpl node, {required DartType contextType}) {
    var body = node.body;
    var isClosure = _typeAnalyzer.flowAnalysis.isActive;

    if (isClosure) {
      // Use typeParameters or parameters for the offset if available, because
      // they will be visited before the body, and may contain expressions.
      var enterOffset =
          (node.typeParameters ?? node.parameters ?? node.body).offset;
      var element = node.declaredFragment!.element;
      _typeAnalyzer.flowAnalysis.executableDeclaration_enter(
        node,
        element.formalParameters,
        isClosure: true,
        offset: enterOffset,
      );
    }

    bool wasFunctionTypeSupplied = contextType is FunctionTypeImpl;
    node.wasFunctionTypeSupplied = wasFunctionTypeSupplied;
    TypeImpl? imposedType;
    if (wasFunctionTypeSupplied) {
      var instantiatedType = _matchTypeParameters(
        node.typeParameters,
        contextType,
      );
      if (instantiatedType is FunctionTypeImpl) {
        _inferFormalParameters(node.parameters, instantiatedType);
        var returnType = instantiatedType.returnType;
        if (!(returnType is DynamicType || returnType is UnknownInferredType)) {
          imposedType = returnType;
        }
      }
    }

    node.typeParameters?.accept2(_typeAnalyzer);
    node.parameters?.accept2(_typeAnalyzer);
    imposedType = node.body.resolve(_typeAnalyzer, imposedType);
    _resolve2(node, imposedType);

    if (isClosure) {
      _typeAnalyzer.checkForBodyMayCompleteNormally(
        body: body,
        errorNode: body,
      );
      _typeAnalyzer.flowAnalysis.flow?.functionExpression_end(
        offset: node.body.flowEndOffset,
      );
      _typeAnalyzer.nullSafetyDeadCodeVerifier.flowEnd(node);
    }

    _buildTypeParameterDefaults(node, node.typeParameters);
  }

  /// Resolves the type parameters, formal parameters, and body of the local
  /// function [node], and infers its return type if it isn't declared.
  ///
  /// Flow analysis for the local function is handled by the caller.
  void resolveLocalFunction(LocalFunctionDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    TypeImpl? imposedType;
    var returnType = element.returnType;
    if (!(returnType is DynamicType || returnType is UnknownInferredType)) {
      imposedType = returnType;
    }

    node.typeParameters?.accept2(_typeAnalyzer);
    node.formalParameters.accept2(_typeAnalyzer);
    var bodyReturnType = node.body.resolve(_typeAnalyzer, imposedType);

    if (node.returnType == null) {
      element.returnType = bodyReturnType;
    }

    _buildTypeParameterDefaults(node, node.typeParameters);
  }

  /// Checks the bounds of the type parameters of the local function or
  /// function expression [node], and computes their default types.
  ///
  /// Top-level and member type parameters are handled during linking.
  void _buildTypeParameterDefaults(
    AstNodeImpl node,
    TypeParameterListImpl? typeParameterList,
  ) {
    if (typeParameterList == null) {
      return;
    }
    // Computing the default types for type parameters will normalize the
    // recursive bounds, so we need to check for recursion first.
    checkForTypeParameterBoundRecursion(
      _typeAnalyzer.diagnosticReporter,
      typeParameterList.typeParameters,
    );
    var map = <Fragment, TypeParameter>{};
    for (var typeParameter in typeParameterList.typeParameters) {
      map[typeParameter.declaredFragment!] = typeParameter;
    }
    DefaultTypesBuilder(
      getTypeParameterNode: (fragment) => map[fragment],
    ).build([node]);
  }

  /// Infer types of implicitly typed formal parameters.
  void _inferFormalParameters(
    FormalParameterList? node,
    FunctionTypeImpl contextType,
  ) {
    if (node == null) {
      return;
    }

    void inferType(FormalParameterElementImpl p, TypeImpl inferredType) {
      // Check that there is no declared type, and that we have not already
      // inferred a type in some fashion.
      if (p.hasImplicitType && p.type is DynamicType) {
        // If no type is declared for a parameter and there is a
        // corresponding parameter in the context type schema with type
        // schema `K`, the parameter is given an inferred type `T` where `T`
        // is derived from `K` as follows.
        inferredType = _typeAnalyzer.operations
            .greatestClosureOfSchema(SharedTypeSchemaView(inferredType))
            .unwrapTypeView<TypeImpl>();

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

    var nodeParameterFragments = node.parameterFragments.nonNulls;
    {
      var nodePositional = nodeParameterFragments
          .map((fragment) => fragment.element)
          .where((element) => element.isPositional)
          .iterator;
      var contextPositional = contextType.formalParameters
          .where((element) => element.isPositional)
          .iterator;
      while (nodePositional.moveNext() && contextPositional.moveNext()) {
        inferType(
          nodePositional.current as FormalParameterElementImpl,
          contextPositional.current.type,
        );
      }
    }

    {
      var contextNamedTypes = contextType.namedParameterTypes;
      var nodeNamed = nodeParameterFragments
          .map((fragment) => fragment.element)
          .where((element) => element.isNamed);
      for (var element in nodeNamed) {
        if (!contextNamedTypes.containsKey(element.name)) {
          continue;
        }
        inferType(
          element as FormalParameterElementImpl,
          contextNamedTypes[element.name]!,
        );
      }
    }
  }

  /// Given the downward inference [type], return the function type expressed
  /// in terms of the type parameters from [typeParameterList].
  ///
  /// Return `null` is the number of element in [typeParameterList] is not
  /// the same as the number of type parameters in the [type].
  FunctionTypeImpl? _matchTypeParameters(
    TypeParameterListImpl? typeParameterList,
    FunctionTypeImpl type,
  ) {
    if (typeParameterList == null) {
      if (type.typeParameters.isEmpty) {
        return type;
      }
      return null;
    }

    var typeParameters = typeParameterList.typeParameters;
    if (typeParameters.length != type.typeParameters.length) {
      return null;
    }

    return type.instantiate(
      typeParameters.map((typeParameter) {
        return typeParameter.declaredFragment!.element.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }).toList(),
    );
  }

  void _resolve2(FunctionExpressionImpl node, TypeImpl? imposedType) {
    var functionElement = node.declaredFragment!.element;
    functionElement.returnType = imposedType ?? DynamicTypeImpl.instance;
    node.recordStaticType(functionElement.type, typeAnalyzer: _typeAnalyzer);
  }
}
