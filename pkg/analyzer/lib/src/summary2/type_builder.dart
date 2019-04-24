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

class TypeBuilder {
  final Dart2TypeSystem typeSystem;

  /// The set of type annotations, and declaration in the build unit, for which
  /// we need to build types, but have not built yet.
  final Set<AstNode> _nodesToBuildType = Set.identity();

  TypeBuilder(this.typeSystem);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// The [nodes] list is a mix of [TypeAnnotation]s and declarations, where
  /// usually type annotations come before declarations that use them, but this
  /// is not guaranteed, and not even always possible. For example references
  /// to typedefs declared in another unit being built - we need to build types
  /// for this typedef, which might reference another unit (encountered before
  /// or after the one defining the typedef).
  void build(List<AstNode> nodes) {
    _nodesToBuildType.addAll(nodes);
    for (var item in nodes) {
      _build(item);
    }
  }

  void _build(AstNode node) {
    if (node == null) return;
    if (!_nodesToBuildType.remove(node)) return;

    if (node is TypeAnnotation) {
      _typeAnnotation(node);
    } else {
      _declaration(node);
    }
  }

  void _buildElement(Element element) {
    var node = (element as ElementImpl).linkedNode;
    _build(node);
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
        _getType(parameter),
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

  void _classDeclaration(ClassDeclaration node) {
    _typeParameterList(node.typeParameters);

    _build(node.extendsClause?.superclass);
    _MixinInference(this).perform(node);
  }

  void _declaration(AstNode node) {
    if (node is ClassDeclaration) {
      _classDeclaration(node);
    } else if (node is FieldFormalParameter) {
      _fieldFormalParameter(node);
    } else if (node is FunctionDeclaration) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      LazyAst.setReturnType(node, returnType);
    } else if (node is FunctionTypeAlias) {
      _functionTypeAlias(node);
    } else if (node is FunctionTypedFormalParameter) {
      _functionTypedFormalParameter(node);
    } else if (node is GenericFunctionType) {
      _genericFunctionType(node);
    } else if (node is GenericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node is MethodDeclaration) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else if (node.isOperator && node.name.name == '[]=') {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      LazyAst.setReturnType(node, returnType);
    } else if (node is SimpleFormalParameter) {
      _build(node.type);
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

  void _formalParameterList(FormalParameterList node) {
    for (var formalParameter in node.parameters) {
      if (formalParameter is SimpleFormalParameter) {
        _build(formalParameter);
      }
    }
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var returnTypeNode = node.returnType;
    _build(returnTypeNode);
    LazyAst.setReturnType(node, returnTypeNode?.type ?? _dynamicType);

    _typeParameterList(node.typeParameters);
    _formalParameterList(node.parameters);
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
    );
    LazyAst.setType(node, type);
  }

  void _genericFunctionType(GenericFunctionTypeImpl node) {
    var returnTypeNode = node.returnType;
    _build(returnTypeNode);
    LazyAst.setReturnType(node, returnTypeNode?.type ?? _dynamicType);

    _typeParameterList(node.typeParameters);
    _formalParameterList(node.parameters);

    node.type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
    );
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    _typeParameterList(node.typeParameters);
    _build(node.functionType);
  }

  List<DartType> _listOfDynamic(int typeParametersLength) {
    return List<DartType>.filled(typeParametersLength, _dynamicType);
  }

  void _typeAnnotation(TypeAnnotation node) {
    if (node is GenericFunctionType) {
      _genericFunctionType(node);
    } else if (node is TypeName) {
      node.type = _dynamicType;
      _typeName(node);
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  List<DartType> _typeArgumentList(TypeArgumentList node) {
    if (node == null) return null;

    var argumentNodes = node.arguments;
    var argumentTypes = List<DartType>(argumentNodes.length);
    for (var i = 0; i < argumentNodes.length; ++i) {
      var argumentNode = argumentNodes[i];
      _build(argumentNode);
      argumentTypes[i] = argumentNode.type;
    }
    return argumentTypes;
  }

  void _typeName(TypeName node) {
    var element = node.name.staticElement;
    if (element is ClassElement) {
      if (element.isEnum) {
        node.type = InterfaceTypeImpl.explicit(element, const []);
      } else {
        _buildElement(element);
        var typeArguments = _typeArgumentList(node.typeArguments);

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
      _buildElement(element);
      var typeArguments = _typeArgumentList(node.typeArguments);

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

  void _typeParameterList(TypeParameterList node) {
    if (node == null) return;

    for (var typeParameter in node.typeParameters) {
      _build(typeParameter.bound);
    }
  }

  static DartType _getType(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return _getType(node.parameter);
    }
    return LazyAst.getType(node);
  }
}

/// Performs mixins inference in a [ClassDeclaration].
class _MixinInference {
  final TypeBuilder builder;

  InterfaceType classType;
  List<InterfaceType> mixinTypes = [];
  List<InterfaceType> supertypesForMixinInference;

  _MixinInference(this.builder);

  void perform(ClassDeclaration node) {
    var withClause = node.withClause;
    if (withClause == null) return;

    classType = node.declaredElement.type;

    for (var mixinNode in withClause.mixinTypes) {
      var mixinType = _inferSingle(mixinNode);
      mixinTypes.add(mixinType);

      _addSupertypes(mixinType);
    }
  }

  void _addSupertypes(InterfaceType type) {
    if (supertypesForMixinInference != null) {
      ClassElementImpl.collectAllSupertypes(
        supertypesForMixinInference,
        type,
        classType,
      );
    }
  }

  InterfaceType _findInterfaceTypeForElement(
    ClassElement element,
    List<InterfaceType> interfaceTypes,
  ) {
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element == element) return interfaceType;
    }
    return null;
  }

  List<InterfaceType> _findInterfaceTypesForConstraints(
    List<InterfaceType> constraints,
    List<InterfaceType> interfaceTypes,
  ) {
    var result = <InterfaceType>[];
    for (var constraint in constraints) {
      var interfaceType = _findInterfaceTypeForElement(
        constraint.element,
        interfaceTypes,
      );

      // No matching interface type found, so inference fails.
      if (interfaceType == null) {
        return null;
      }

      result.add(interfaceType);
    }
    return result;
  }

  InterfaceType _inferSingle(TypeName mixinNode) {
    builder._build(mixinNode);
    var mixinType = _interfaceType(mixinNode.type);

    if (mixinNode.typeArguments != null) {
      return mixinType;
    }

    var mixinElement = mixinType.element;
    if (mixinElement.typeParameters.isEmpty) {
      return mixinType;
    }

    var mixinSupertypeConstraints = builder.typeSystem
        .gatherMixinSupertypeConstraintsForInference(mixinElement);
    if (mixinSupertypeConstraints.isEmpty) {
      return mixinType;
    }

    if (supertypesForMixinInference == null) {
      supertypesForMixinInference = <InterfaceType>[];
      _addSupertypes(classType.superclass);
      for (var previousMixinType in mixinTypes) {
        _addSupertypes(previousMixinType);
      }
    }

    var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
      mixinSupertypeConstraints,
      supertypesForMixinInference,
    );

    // Note: if matchingInterfaceType is null, that's an error.  Also,
    // if there are multiple matching interface types that use
    // different type parameters, that's also an error.  But we can't
    // report errors from the linker, so we just use the
    // first matching interface type (if there is one).  The error
    // detection logic is implemented in the ErrorVerifier.
    if (matchingInterfaceTypes == null) {
      return mixinType;
    }

    // Try to pattern match matchingInterfaceTypes against
    // mixinSupertypeConstraints to find the correct set of type
    // parameters to apply to the mixin.
    var inferredMixin = builder.typeSystem.matchSupertypeConstraints(
      mixinElement,
      mixinSupertypeConstraints,
      matchingInterfaceTypes,
    );
    if (inferredMixin != null) {
      mixinType = inferredMixin;
      mixinNode.type = inferredMixin;
    }

    return mixinType;
  }

  InterfaceType _interfaceType(DartType type) {
    if (type is InterfaceType && !type.element.isEnum) {
      return type;
    }
    return builder.typeSystem.typeProvider.objectType;
  }
}
