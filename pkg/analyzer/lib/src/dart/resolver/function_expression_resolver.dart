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
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';

class FunctionExpressionResolver {
  final ResolverVisitor _resolver;

  FunctionExpressionResolver({required ResolverVisitor resolver})
    : _resolver = resolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(FunctionExpressionImpl node, {required DartType contextType}) {
    var parent = node.parent;
    var isFunctionDeclaration = parent is FunctionDeclaration;
    var body = node.body;

    if (_resolver.flowAnalysis.flow != null && !isFunctionDeclaration) {
      _resolver.flowAnalysis.executableDeclaration_enter(
        node,
        node.parameters,
        isClosure: true,
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
      _resolver.checkForBodyMayCompleteNormally(body: body, errorNode: body);
      _resolver.flowAnalysis.flow?.functionExpression_end();
      _resolver.nullSafetyDeadCodeVerifier.flowEnd(node);
    }

    var typeParameterList = node.typeParameters;
    if (typeParameterList != null) {
      // Computing the default types for type parameters will normalize the
      // recursive bounds, so we need to check for recursion first.
      //
      // This is only needed for local functions because top-level and
      checkForTypeParameterBoundRecursion(
        _resolver.diagnosticReporter,
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
        inferredType = _resolver.operations
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
