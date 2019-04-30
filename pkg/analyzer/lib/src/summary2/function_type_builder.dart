// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The type builder for a [GenericFunctionType].
class FunctionTypeBuilder extends TypeBuilder {
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  final List<TypeParameterElement> typeFormals;
  final List<ParameterElement> parameters;
  final DartType returnType;
  final NullabilitySuffix nullabilitySuffix;

  /// The node for which this builder is created, or `null` if the builder
  /// was detached from its node, e.g. during computing default types for
  /// type parameters.
  final GenericFunctionTypeImpl node;

  /// The actual built type, not a [TypeBuilder] anymore.
  ///
  /// When [build] is called, the type is built, stored into this field,
  /// and set for the [node].
  DartType _type;

  FunctionTypeBuilder(
    this.typeFormals,
    this.parameters,
    this.returnType,
    this.nullabilitySuffix, {
    this.node,
  });

  factory FunctionTypeBuilder.of(
    GenericFunctionType node,
    NullabilitySuffix nullabilitySuffix,
  ) {
    return FunctionTypeBuilder(
      node.typeParameters?.typeParameters
              ?.map((n) => n.declaredElement as TypeParameterElement)
              ?.toList() ??
          [],
      node.parameters.parameters.map((n) {
        return ParameterElementImpl.synthetic(
          n.identifier?.name ?? '',
          _getParameterType(n),
          // ignore: deprecated_member_use_from_same_package
          n.kind,
        );
      }).toList(),
      _getNodeType(node.returnType),
      nullabilitySuffix,
      node: node,
    );
  }

  @override
  Element get element => null;

  @override
  DartType build() {
    if (_type != null) {
      return _type;
    }

    var builtReturnType = _buildType(returnType);
    _type = FunctionTypeImpl.synthetic(
      builtReturnType,
      typeFormals,
      parameters.map((e) {
        return ParameterElementImpl.synthetic(
          e.name,
          _buildType(e.type),
          // ignore: deprecated_member_use_from_same_package
          e.parameterKind,
        );
      }).toList(),
      nullabilitySuffix: nullabilitySuffix,
    );

    if (node != null) {
      node.type = _type;
      LazyAst.setReturnType(node, builtReturnType ?? _dynamicType);
    }

    return _type;
  }

  @override
  String toString() {
    var buffer = StringBuffer();

    if (typeFormals.isNotEmpty) {
      buffer.write('<');
      buffer.write(typeFormals.join(', '));
      buffer.write('>');
    }

    buffer.write('(');
    buffer.write(parameters.join(', '));
    buffer.write(')');

    buffer.write(' → ');
    buffer.write(returnType);

    return buffer.toString();
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  /// Return the type of the [node] as is, possibly a [TypeBuilder].
  static DartType _getNodeType(TypeAnnotation node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return node.type;
    }
  }

  /// Return the type of the [node] as is, possibly a [TypeBuilder].
  static DartType _getParameterType(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return _getParameterType(node.parameter);
    } else if (node is SimpleFormalParameter) {
      return _getNodeType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }
}
