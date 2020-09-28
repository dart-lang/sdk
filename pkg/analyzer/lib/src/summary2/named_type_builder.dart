// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/type_builder.dart';
import 'package:meta/meta.dart';

/// The type builder for a [TypeName].
class NamedTypeBuilder extends TypeBuilder {
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  /// The type system of the library with the type name.
  final TypeSystemImpl typeSystem;

  @override
  final Element element;

  final List<DartType> arguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// The node for which this builder is created, or `null` if the builder
  /// was detached from its node, e.g. during computing default types for
  /// type parameters.
  final TypeName node;

  /// The actual built type, not a [TypeBuilder] anymore.
  ///
  /// When [build] is called, the type is built, stored into this field,
  /// and set for the [node].
  DartType _type;

  NamedTypeBuilder(
      this.typeSystem, this.element, this.arguments, this.nullabilitySuffix,
      {this.node});

  factory NamedTypeBuilder.of(
    TypeSystemImpl typeSystem,
    TypeName node,
    Element element,
    NullabilitySuffix nullabilitySuffix,
  ) {
    List<DartType> arguments;
    var argumentList = node.typeArguments;
    if (argumentList != null) {
      arguments = argumentList.arguments.map((n) => n.type).toList();
    } else {
      arguments = <DartType>[];
    }

    return NamedTypeBuilder(typeSystem, element, arguments, nullabilitySuffix,
        node: node);
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    if (visitor is LinkingTypeVisitor<R>) {
      var visitor2 = visitor as LinkingTypeVisitor<R>;
      return visitor2.visitNamedTypeBuilder(this);
    } else {
      throw StateError('Should not happen outside linking.');
    }
  }

  @override
  DartType build() {
    if (_type != null) {
      return _type;
    }

    var element = this.element;
    if (element is ClassElement) {
      var parameters = element.typeParameters;
      var arguments = _buildArguments(parameters);
      var type = element.instantiate(
        typeArguments: arguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = typeSystem.toLegacyType(type);
      _type = type;
    } else if (element is GenericTypeAliasElement) {
      var rawType = _getRawFunctionType(element);
      if (rawType is FunctionType) {
        var parameters = element.typeParameters;
        var arguments = _buildArguments(parameters);
        var substitution = Substitution.fromPairs(parameters, arguments);
        var instantiated = substitution.substituteType(rawType) as FunctionType;
        var type = FunctionTypeImpl(
          typeFormals: instantiated.typeFormals,
          parameters: instantiated.parameters,
          returnType: instantiated.returnType,
          nullabilitySuffix: nullabilitySuffix,
          element: element,
          typeArguments: arguments,
        );
        type = typeSystem.toLegacyType(type);
        _type = type;
      } else {
        _type = _dynamicType;
      }
    } else if (element is NeverElementImpl) {
      if (typeSystem.isNonNullableByDefault) {
        _type = NeverTypeImpl.instance.withNullability(nullabilitySuffix);
      } else {
        _type = typeSystem.typeProvider.nullType;
      }
    } else if (element is TypeParameterElement) {
      _type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      _type = _dynamicType;
    }

    node?.type = _type;
    return _type;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write(element.displayName);
    if (arguments.isNotEmpty) {
      buffer.write('<');
      buffer.write(arguments.join(', '));
      buffer.write('>');
    }
    return buffer.toString();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) {
      return this;
    }

    return NamedTypeBuilder(typeSystem, element, arguments, nullabilitySuffix,
        node: node);
  }

  /// Build arguments that correspond to the type [parameters].
  List<DartType> _buildArguments(List<TypeParameterElement> parameters) {
    if (parameters.isEmpty) {
      return const <DartType>[];
    } else if (arguments.isNotEmpty) {
      if (arguments.length == parameters.length) {
        var result = List<DartType>(parameters.length);
        for (int i = 0; i < result.length; ++i) {
          var type = arguments[i];
          result[i] = _buildType(type);
        }
        return result;
      } else {
        return _listOfDynamic(parameters.length);
      }
    } else {
      var result = List<DartType>(parameters.length);
      for (int i = 0; i < result.length; ++i) {
        TypeParameterElementImpl parameter = parameters[i];
        var defaultType = parameter.defaultType;
        defaultType = _buildType(defaultType);
        result[i] = defaultType;
      }
      return result;
    }
  }

  DartType _buildFormalParameterType(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return _buildFormalParameterType(node.parameter);
    } else if (node is FunctionTypedFormalParameter) {
      return _buildFunctionType(
        typeParameterList: node.typeParameters,
        returnTypeNode: node.returnType,
        parameterList: node.parameters,
        hasQuestion: node.question != null,
      );
    } else if (node is SimpleFormalParameter) {
      return _buildNodeType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  FunctionType _buildFunctionType({
    @required TypeParameterList typeParameterList,
    @required TypeAnnotation returnTypeNode,
    @required FormalParameterList parameterList,
    @required bool hasQuestion,
  }) {
    var returnType = _buildNodeType(returnTypeNode);
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: _getNullabilitySuffix(hasQuestion),
    );
  }

  DartType _buildGenericFunctionType(GenericFunctionType node) {
    if (node != null) {
      return _buildType(node?.type);
    } else {
      return FunctionTypeImpl(
        typeFormals: const <TypeParameterElement>[],
        parameters: const <ParameterElement>[],
        returnType: _dynamicType,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }
  }

  DartType _buildNodeType(TypeAnnotation node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return _buildType(node.type);
    }
  }

  List<ParameterElementImpl> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return ParameterElementImpl.synthetic(
        parameter.identifier?.name ?? '',
        _buildFormalParameterType(parameter),
        parameter.kind,
      );
    }).toList();
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else if (typeSystem.isNonNullableByDefault) {
      return NullabilitySuffix.none;
    } else {
      return NullabilitySuffix.star;
    }
  }

  DartType _getRawFunctionType(GenericTypeAliasElementImpl element) {
    // If the element is not being linked, there is no reason (or a way,
    // because the linked node might be read only partially) to go through
    // its node - all its types have already been built.
    if (!element.linkedContext.isLinking) {
      return element.function.type;
    }

    var typedefNode = element.linkedNode;

    // Break a possible recursion.
    var existing = LazyAst.getRawFunctionType(typedefNode);
    if (existing != null) {
      return existing;
    } else {
      LazyAst.setRawFunctionType(typedefNode, _dynamicType);
    }

    if (typedefNode is FunctionTypeAlias) {
      var result = _buildFunctionType(
        typeParameterList: null,
        returnTypeNode: typedefNode.returnType,
        parameterList: typedefNode.parameters,
        hasQuestion: false,
      );
      LazyAst.setRawFunctionType(typedefNode, result);
      return result;
    } else if (typedefNode is GenericTypeAlias) {
      var functionNode = typedefNode.functionType;
      var functionType = _buildGenericFunctionType(functionNode);
      LazyAst.setRawFunctionType(typedefNode, functionType);
      return functionType;
    } else {
      throw StateError('(${element.runtimeType}) $element');
    }
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  static List<DartType> _listOfDynamic(int length) {
    return List<DartType>.filled(length, _dynamicType);
  }

  static List<TypeParameterElement> _typeParameters(TypeParameterList node) {
    if (node != null) {
      return node.typeParameters
          .map<TypeParameterElement>((p) => p.declaredElement)
          .toList();
    } else {
      return const <TypeParameterElement>[];
    }
  }
}
