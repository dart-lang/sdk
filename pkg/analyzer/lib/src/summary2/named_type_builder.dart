// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The type builder for a [TypeName].
class NamedTypeBuilder extends TypeBuilder {
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  final Element element;
  final List<DartType> arguments;
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

  NamedTypeBuilder(this.element, this.arguments, this.nullabilitySuffix,
      {this.node});

  factory NamedTypeBuilder.of(
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

    return NamedTypeBuilder(element, arguments, nullabilitySuffix, node: node);
  }

  @override
  DartType build() {
    if (_type != null) {
      return _type;
    }

    var element = this.element;
    if (element is ClassElement) {
      var parameters = element.typeParameters;
      if (parameters.isEmpty) {
        var rawType = element.type;
        _type = (rawType as TypeImpl).withNullability(nullabilitySuffix);
      } else {
        var arguments = _buildArguments(parameters);
        _type = InterfaceTypeImpl.explicit(
          element,
          arguments,
          nullabilitySuffix: nullabilitySuffix,
        );
      }
    } else if (element is GenericTypeAliasElement) {
      // Break a possible recursion.
      _type = _dynamicType;

      var rawType = _getRawFunctionType(element);

      var parameters = element.typeParameters;
      if (parameters.isEmpty) {
        _type = rawType;
      } else {
        var arguments = _buildArguments(parameters);
        var substitution = Substitution.fromPairs(parameters, arguments);
        _type = substitution.substituteType(rawType);
      }
    } else if (element is TypeParameterElement) {
      _type = TypeParameterTypeImpl(element);
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

  /// Build arguments that correspond to the type [parameters].
  List<DartType> _buildArguments(List<TypeParameterElement> parameters) {
    if (arguments.isNotEmpty) {
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
        node.typeParameters,
        node.returnType,
        node.parameters,
      );
    } else if (node is SimpleFormalParameter) {
      return _buildNodeType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  FunctionType _buildFunctionType(
    TypeParameterList typeParameterList,
    TypeAnnotation returnTypeNode,
    FormalParameterList parameterList,
  ) {
    var returnType = _buildNodeType(returnTypeNode);

    List<TypeParameterElement> typeParameters;
    if (typeParameterList != null) {
      typeParameters = typeParameterList.typeParameters
          .map<TypeParameterElement>((p) => p.declaredElement)
          .toList();
    } else {
      typeParameters = const <TypeParameterElement>[];
    }

    var formalParameters = parameterList.parameters.map((parameter) {
      return ParameterElementImpl.synthetic(
        parameter.identifier?.name ?? '',
        _buildFormalParameterType(parameter),
        // ignore: deprecated_member_use_from_same_package
        parameter.kind,
      );
    }).toList();

    return FunctionTypeImpl.synthetic(
      returnType,
      typeParameters,
      formalParameters,
    );
  }

  DartType _buildNodeType(TypeAnnotation node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return _buildType(node.type);
    }
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  DartType _getRawFunctionType(GenericTypeAliasElementImpl element) {
    // If the element is not being linked, there is no reason (or a way,
    // because the linked node might be read only partially) to go through
    // its node - all its types have already been built.
    if (!element.linkedContext.isLinking) {
      var function = element.function;
      if (function != null) {
        return function.type;
      } else {
        return _dynamicType;
      }
    }

    var typedefNode = element.linkedNode;
    if (typedefNode is FunctionTypeAlias) {
      return _buildFunctionType(
        null,
        typedefNode.returnType,
        typedefNode.parameters,
      );
    } else if (typedefNode is GenericTypeAlias) {
      var functionNode = typedefNode.functionType;
      if (functionNode != null) {
        return _buildFunctionType(
          functionNode.typeParameters,
          functionNode.returnType,
          functionNode.parameters,
        );
      } else {
        return _dynamicType;
      }
    } else {
      throw StateError('(${element.runtimeType}) $element');
    }
  }

  static List<DartType> _listOfDynamic(int length) {
    return List<DartType>.filled(length, _dynamicType);
  }
}
