// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/type_builder.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The type builder for a [NamedType].
class NamedTypeBuilder extends TypeBuilder {
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  /// The linker that contains this type.
  final Linker linker;

  /// The type system of the library with the type name.
  final TypeSystemImpl typeSystem;

  @override
  final Element element;

  final List<TypeImpl> arguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// The node for which this builder is created, or `null` if the builder
  /// was detached from its node, e.g. during computing default types for
  /// type parameters.
  final NamedTypeImpl? node;

  /// The actual built type, not a [TypeBuilder] anymore.
  ///
  /// When [build] is called, the type is built, stored into this field,
  /// and set for the [node].
  TypeImpl? _type;

  NamedTypeBuilder({
    required this.linker,
    required this.typeSystem,
    required this.element,
    required this.arguments,
    required this.nullabilitySuffix,
    this.node,
  });

  factory NamedTypeBuilder.of({
    required Linker linker,
    required TypeSystemImpl typeSystem,
    required NamedTypeImpl node,
    required Element element,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    List<TypeImpl> arguments;
    var argumentList = node.typeArguments;
    if (argumentList != null) {
      arguments = argumentList.arguments.map((n) => n.typeOrThrow).toList();
    } else {
      arguments = <TypeImpl>[];
    }

    return NamedTypeBuilder(
      linker: linker,
      typeSystem: typeSystem,
      element: element,
      arguments: arguments,
      nullabilitySuffix: nullabilitySuffix,
      node: node,
    );
  }

  // TODO(scheglov): Only when enabled both in the element, and target?
  bool get _isNonFunctionTypeAliasesEnabled {
    return element.library!.featureSet.isEnabled(
      Feature.nonfunction_type_aliases,
    );
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
  TypeImpl build() {
    if (_type != null) {
      return _type!;
    }

    var element = this.element;
    if (element is InterfaceElementImpl) {
      var parameters = element.typeParameters;
      var arguments = _buildArguments(parameters);
      _type = element.instantiateImpl(
        typeArguments: arguments,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (element is TypeAliasElementImpl) {
      var aliasedType = _getAliasedType(element);
      var parameters = element.typeParameters;
      var arguments = _buildArguments(parameters);
      element.aliasedType = aliasedType;
      _type = element.instantiateImpl(
        typeArguments: arguments,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (element is NeverElementImpl) {
      _type = NeverTypeImpl.instance.withNullability(nullabilitySuffix);
    } else if (element is TypeParameterElementImpl) {
      _type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      _type = _dynamicType;
    }

    node?.type = _type;
    return _type!;
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

    return NamedTypeBuilder(
      linker: linker,
      typeSystem: typeSystem,
      element: element,
      arguments: arguments,
      nullabilitySuffix: nullabilitySuffix,
      node: node,
    );
  }

  TypeImpl _buildAliasedType(TypeAnnotation? node) {
    if (_isNonFunctionTypeAliasesEnabled) {
      if (node != null) {
        return _buildType(node.typeOrThrow);
      } else {
        return _dynamicType;
      }
    } else {
      if (node is GenericFunctionType) {
        return _buildType(node.typeOrThrow);
      } else {
        return FunctionTypeImpl.v2(
          typeParameters: const <TypeParameterElementImpl>[],
          formalParameters: const <InternalFormalParameterElement>[],
          returnType: _dynamicType,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
  }

  /// Build arguments that correspond to the type [parameters].
  List<TypeImpl> _buildArguments(List<TypeParameterElement> parameters) {
    if (parameters.isEmpty) {
      return const <TypeImpl>[];
    } else if (arguments.isNotEmpty) {
      if (arguments.length == parameters.length) {
        return List.generate(arguments.length, (index) {
          var type = arguments[index];
          return _buildType(type);
        }, growable: false);
      } else {
        return _listOfDynamic(parameters.length);
      }
    } else {
      return List.generate(parameters.length, (index) {
        var parameter = parameters[index] as TypeParameterElementImpl;
        var defaultType = parameter.defaultType!;
        return _buildType(defaultType);
      }, growable: false);
    }
  }

  TypeImpl _buildFormalParameterType(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return _buildFormalParameterType(node.parameter);
    } else if (node is FunctionTypedFormalParameterImpl) {
      return _buildFunctionType(
        typeParameterList: node.typeParameters,
        returnTypeNode: node.returnType,
        parameterList: node.parameters,
        hasQuestion: node.question != null,
      );
    } else if (node is SimpleFormalParameterImpl) {
      return _buildNodeType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  FunctionTypeImpl _buildFunctionType({
    required TypeParameterListImpl? typeParameterList,
    required TypeAnnotationImpl? returnTypeNode,
    required FormalParameterList parameterList,
    required bool hasQuestion,
  }) {
    var returnType = _buildNodeType(returnTypeNode);
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl.v2(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: _getNullabilitySuffix(hasQuestion),
    );
  }

  TypeImpl _buildNodeType(TypeAnnotationImpl? node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return _buildType(node.typeOrThrow);
    }
  }

  List<FormalParameterElementImpl> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return FormalParameterElementImpl.synthetic(
        parameter.name?.lexeme ?? '',
        _buildFormalParameterType(parameter),
        parameter.kind,
      );
    }).toFixedList();
  }

  TypeImpl _getAliasedType(TypeAliasElementImpl element) {
    // If the element is not being linked, the types have already been built.
    if (!linker.isLinkingElement(element)) {
      return element.aliasedType;
    }

    var typedefNode = linker.getLinkingNode2(element.firstFragment)!;

    // Break a possible recursion.
    var existing = element.aliasedTypeRaw;
    if (existing != null) {
      return existing;
    } else {
      element.aliasedType = _dynamicType;
    }

    if (typedefNode is FunctionTypeAliasImpl) {
      var result = _buildFunctionType(
        typeParameterList: null,
        returnTypeNode: typedefNode.returnType,
        parameterList: typedefNode.parameters,
        hasQuestion: false,
      );
      element.aliasedType = result;
      return result;
    } else if (typedefNode is GenericTypeAlias) {
      var aliasedTypeNode = typedefNode.type;
      var aliasedType = _buildAliasedType(aliasedTypeNode);
      element.aliasedType = aliasedType;
      return aliasedType;
    } else {
      throw StateError('(${element.runtimeType}) $element');
    }
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static TypeImpl _buildType(TypeImpl type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  static List<TypeImpl> _listOfDynamic(int length) {
    return List<TypeImpl>.filled(length, _dynamicType);
  }

  static List<TypeParameterElementImpl> _typeParameters(
    TypeParameterListImpl? node,
  ) {
    if (node != null) {
      return node.typeParameters
          .map((p) => p.declaredFragment!.element)
          .toFixedList();
    } else {
      return const <TypeParameterElementImpl>[];
    }
  }
}
