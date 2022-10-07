// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/generated/resolver.dart';

class ExtractorPatternResolver {
  final ResolverVisitor resolverVisitor;

  ExtractorPatternResolver(this.resolverVisitor);

  TypeProviderImpl get _typeProvider => resolverVisitor.typeProvider;

  void resolve({
    required ExtractorPatternImpl node,
    required DartType matchedType,
    required Map<PromotableElement, VariableTypeInfo<AstNode, DartType>>
        typeInfos,
    required MatchContext<AstNode, Expression> context,
  }) {
    var inferredType = _inferType(
      matchedType: matchedType,
      typeNode: node.type,
    );

    for (var field in node.fields) {
      // TODO(scheglov) Report an error.
      var nameToken =
          field.fieldName?.name ?? field.pattern.variablePattern!.name;
      var result = resolverVisitor.typePropertyResolver.resolve(
        receiver: null,
        receiverType: inferredType,
        name: nameToken.lexeme,
        propertyErrorEntity: nameToken,
        nameErrorEntity: node,
      );
      // TODO(scheglov) Report an error.
      var getter = result.getter;
      field.fieldElement = getter;
      var fieldType = getter?.returnType ?? _typeProvider.dynamicType;
      field.pattern
          .resolvePattern(resolverVisitor, fieldType, typeInfos, context);
    }
  }

  DartType _inferType({
    required DartType matchedType,
    required NamedTypeImpl typeNode,
  }) {
    if (typeNode.typeArguments == null) {
      var typeNameElement = typeNode.name.staticElement;
      if (typeNameElement is InterfaceElement) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.thisType,
            matchedType: matchedType,
          );
          return typeNode.type = typeNameElement.instantiate(
            typeArguments: typeArguments,
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      } else if (typeNameElement is TypeAliasElement) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.aliasedType,
            matchedType: matchedType,
          );
          return typeNode.type = typeNameElement.instantiate(
            typeArguments: typeArguments,
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      }
    }
    return typeNode.typeOrThrow;
  }

  List<DartType> _inferTypeArguments({
    required List<TypeParameterElement> typeParameters,
    required AstNode errorNode,
    required DartType declaredType,
    required DartType matchedType,
  }) {
    var inferrer = GenericInferrer(
      resolverVisitor.typeSystem,
      typeParameters,
      errorReporter: resolverVisitor.errorReporter,
      errorNode: errorNode,
      genericMetadataIsEnabled: resolverVisitor.genericMetadataIsEnabled,
    );
    inferrer.constrainReturnType(declaredType, matchedType);
    return inferrer.partialInfer().map((typeArgument) {
      if (typeArgument is UnknownInferredType) {
        return _typeProvider.dynamicType;
      } else {
        return typeArgument;
      }
    }).toList();
  }
}
