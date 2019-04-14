// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';

/// Type annotations and declarations to build types for.
///
/// Not all types can be build during reference resolution phase.
/// For example `A` means `A<num>` if `class A<T extends num>`, but we don't
/// know this until we resolved `A` declaration, and we might have not yet.
///
/// So, we remember type annotations that should be resolved later, and
/// declarations to set types from explicit type annotations.
class NodesToBuildType {
  final List<NodeToBuildType> items = [];

  void addDeclaration(AstNode declaration) {
    items.add(NodeToBuildType._(null, declaration));
  }

  void addTypeAnnotation(TypeAnnotation typeAnnotation) {
    items.add(NodeToBuildType._(typeAnnotation, null));
  }
}

/// A type annotation to build type for, or a declaration to set its explicitly
/// declared type.
class NodeToBuildType {
  final TypeAnnotation typeAnnotation;
  final AstNode declaration;

  NodeToBuildType._(this.typeAnnotation, this.declaration);
}

/// Build types in a [NodesToBuildType].
class TypeBuilder {
  final Dart2TypeSystem typeSystem;

  TypeBuilder(this.typeSystem);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  void build(NodesToBuildType nodesToBuildType) {
    for (var item in nodesToBuildType.items) {
      if (item.typeAnnotation != null) {
        var node = item.typeAnnotation;
        if (node is GenericFunctionType) {
          _buildGenericFunctionType(node);
        } else if (node is TypeName) {
          _buildTypeName(node);
        } else {
          throw StateError('${node.runtimeType}');
        }
      } else if (item.declaration != null) {
        _setTypesForDeclaration(item.declaration);
      }
    }
  }

  FunctionType _buildFunctionType(
    TypeParameterList typeParameterList,
    TypeAnnotation returnTypeNode,
    FormalParameterList parameterList,
  ) {
    var returnType = returnTypeNode?.type ?? _dynamicType;

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
        LazyAst.getType(parameter),
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

  void _buildGenericFunctionType(GenericFunctionTypeImpl node) {
    node.type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
    );
  }

  void _buildTypeName(TypeName node) {
    var element = node.name.staticElement;

    List<DartType> typeArguments;
    var typeArgumentList = node.typeArguments;
    if (typeArgumentList != null) {
      typeArguments = typeArgumentList.arguments.map((a) => a.type).toList();
    }

    if (element is ClassElement) {
      if (element.isEnum) {
        node.type = InterfaceTypeImpl.explicit(element, const []);
      } else {
        var rawType = element.type;

        var typeParametersLength = element.typeParameters.length;
        if (typeParametersLength == 0) {
          node.type = rawType;
          return;
        }

        if (typeArguments == null) {
          node.type = typeSystem.instantiateToBounds(rawType);
          return;
        }

        if (typeArguments.length != typeParametersLength) {
          typeArguments = _listOfDynamic(typeParametersLength);
        }

        node.type = InterfaceTypeImpl.explicit(element, typeArguments);
      }
    } else if (element is GenericTypeAliasElement) {
      var rawType = element.function.type;

      var typeParameters = element.typeParameters;
      var typeParametersLength = typeParameters.length;
      if (typeParametersLength == 0) {
        node.type = rawType;
        return;
      }

      if (typeArguments == null) {
        typeArguments = typeSystem.instantiateTypeFormalsToBounds(
          typeParameters,
        );
      } else if (typeArguments.length != typeParametersLength) {
        typeArguments = _listOfDynamic(typeParametersLength);
      }

      var substitution = Substitution.fromPairs(
        typeParameters,
        typeArguments,
      );
      node.type = substitution.substituteType(rawType);
    } else if (element is TypeParameterElement) {
      node.type = TypeParameterTypeImpl(element);
    } else {
      // We might get all kinds of elements, including not type at all.
      // For example a PrefixElement, or a getter, etc.
      // In all these cases the type is dynamic.
      node.type = _dynamicType;
    }
  }

  void _fieldFormalParameter(FieldFormalParameter node) {
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
      );
      LazyAst.setType(node, type);
    } else {
      LazyAst.setType(node, node.type?.type ?? _dynamicType);
    }
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
    );
    LazyAst.setType(node, type);
  }

  List<DartType> _listOfDynamic(int typeParametersLength) {
    return List<DartType>.filled(typeParametersLength, _dynamicType);
  }

  void _setTypesForDeclaration(AstNode node) {
    if (node is FieldFormalParameter) {
      _fieldFormalParameter(node);
    } else if (node is FunctionDeclaration) {
      var defaultReturnType = node.isSetter ? _voidType : _dynamicType;
      var returnType = node.returnType?.type ?? defaultReturnType;
      LazyAst.setReturnType(node, returnType);
    } else if (node is FunctionTypeAlias) {
      LazyAst.setReturnType(node, node.returnType?.type ?? _dynamicType);
    } else if (node is FunctionTypedFormalParameter) {
      _functionTypedFormalParameter(node);
    } else if (node is GenericFunctionType) {
      LazyAst.setReturnType(node, node.returnType?.type ?? _dynamicType);
    } else if (node is MethodDeclaration) {
      var defaultReturnType = node.isSetter ? _voidType : _dynamicType;
      var returnType = node.returnType?.type ?? defaultReturnType;
      LazyAst.setReturnType(node, returnType);
    } else if (node is SimpleFormalParameter) {
      LazyAst.setType(node, node.type?.type ?? _dynamicType);
    } else if (node is VariableDeclarationList) {
      var type = node.type?.type;
      if (type != null) {
        for (var variable in node.variables) {
          LazyAst.setType(variable, type);
        }
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }
}
