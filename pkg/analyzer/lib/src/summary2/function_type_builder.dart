// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/type_builder.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The type builder for a [GenericFunctionType].
class FunctionTypeBuilder extends TypeBuilder {
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  final List<TypeParameterElementImpl2> typeParameters;
  final List<FormalParameterElementImpl> formalParameters;
  final TypeImpl returnType;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// The node for which this builder is created, or `null` if the builder
  /// was detached from its node, e.g. during computing default types for
  /// type parameters.
  final GenericFunctionTypeImpl? node;

  /// The actual built type, not a [TypeBuilder] anymore.
  ///
  /// When [build] is called, the type is built, stored into this field,
  /// and set for the [node].
  FunctionTypeImpl? _type;

  FunctionTypeBuilder(
    this.typeParameters,
    this.formalParameters,
    this.returnType,
    this.nullabilitySuffix, {
    this.node,
  });

  factory FunctionTypeBuilder.of(
    GenericFunctionTypeImpl node,
    NullabilitySuffix nullabilitySuffix,
  ) {
    return FunctionTypeBuilder(
      _getTypeParameters(node.typeParameters),
      getParameters(node.parameters),
      _getNodeType(node.returnType),
      nullabilitySuffix,
      node: node,
    );
  }

  factory FunctionTypeBuilder.v2({
    required List<TypeParameterElementImpl2> typeParameters,
    required List<FormalParameterElementImpl> formalParameters,
    required TypeImpl returnType,
    required NullabilitySuffix nullabilitySuffix,
    GenericFunctionTypeImpl? node,
  }) {
    return FunctionTypeBuilder(
      typeParameters,
      formalParameters,
      returnType,
      nullabilitySuffix,
      node: node,
    );
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    if (visitor is LinkingTypeVisitor<R>) {
      var visitor2 = visitor as LinkingTypeVisitor<R>;
      return visitor2.visitFunctionTypeBuilder(this);
    } else {
      throw StateError('Should not happen outside linking.');
    }
  }

  @override
  TypeImpl build() {
    var type = _type;
    if (type != null) {
      return type;
    }

    for (var typeParameter in typeParameters) {
      var bound = typeParameter.bound;
      if (bound != null) {
        typeParameter.bound = _buildType(bound);
      }
    }

    for (var formalParameter in formalParameters) {
      formalParameter.type = _buildType(formalParameter.type);
    }

    var builtReturnType = _buildType(returnType);
    type = FunctionTypeImpl.v2(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: builtReturnType,
      nullabilitySuffix: nullabilitySuffix,
    );

    var fresh = getFreshTypeParameters2(typeParameters);
    type = fresh.applyToFunctionType(type);

    _type = type;
    node?.type = type;
    return type;
  }

  @override
  String toString() {
    var buffer = StringBuffer();

    if (typeParameters.isNotEmpty) {
      buffer.write('<');
      buffer.write(typeParameters.join(', '));
      buffer.write('>');
    }

    buffer.write('(');
    buffer.write(formalParameters.join(', '));
    buffer.write(')');

    buffer.write(' → ');
    buffer.write(returnType);

    return buffer.toString();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) {
      return this;
    }

    return FunctionTypeBuilder(
      typeParameters,
      formalParameters,
      returnType,
      nullabilitySuffix,
      node: node,
    );
  }

  static List<FormalParameterElementImpl> getParameters(
    FormalParameterListImpl node,
  ) {
    return node.parameters.map((parameter) {
      return FormalParameterElementImpl.synthetic(
        parameter.name?.lexeme ?? '',
        _getParameterType(parameter),
        parameter.kind,
      );
    }).toFixedList();
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static TypeImpl _buildType(TypeImpl type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  /// Return the type of the [node] as is, possibly a [TypeBuilder].
  static TypeImpl _getNodeType(TypeAnnotation? node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return node.typeOrThrow;
    }
  }

  /// Return the type of the [node] as is, possibly a [TypeBuilder].
  static DartType _getParameterType(FormalParameterImpl node) {
    if (node is DefaultFormalParameterImpl) {
      return _getParameterType(node.parameter);
    } else if (node is SimpleFormalParameterImpl) {
      return _getNodeType(node.type);
    } else if (node is FunctionTypedFormalParameterImpl) {
      NullabilitySuffix nullabilitySuffix;
      if (node.question != null) {
        nullabilitySuffix = NullabilitySuffix.question;
      } else {
        nullabilitySuffix = NullabilitySuffix.none;
      }

      return FunctionTypeBuilder(
        _getTypeParameters(node.typeParameters),
        getParameters(node.parameters),
        _getNodeType(node.returnType),
        nullabilitySuffix,
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  static List<TypeParameterElementImpl2> _getTypeParameters(
    TypeParameterListImpl? node,
  ) {
    if (node == null) return const [];
    return node.typeParameters.map((node) {
      return node.declaredFragment!.element;
    }).toFixedList();
  }
}
