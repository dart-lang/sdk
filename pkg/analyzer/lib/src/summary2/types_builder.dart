// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

class NodesToBuildType {
  final List<AstNode> declarations = [];
  final List<TypeBuilder> typeBuilders = [];

  void addDeclaration(AstNode node) {
    declarations.add(node);
  }

  void addTypeBuilder(TypeBuilder builder) {
    typeBuilders.add(builder);
  }
}

class TypesBuilder {
  final Dart2TypeSystem typeSystem;

  TypesBuilder(this.typeSystem);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// Build types for all type annotations, and set types for declarations.
  void build(NodesToBuildType nodes) {
    DefaultTypesBuilder(typeSystem).build(nodes.declarations);

    for (var builder in nodes.typeBuilders) {
      builder.build();
    }

    _MixinsInference(typeSystem).perform(nodes.declarations);

    for (var declaration in nodes.declarations) {
      _declaration(declaration);
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

  void _classDeclaration(ClassDeclaration node) {}

  void _declaration(AstNode node) {
    if (node is ClassDeclaration) {
      _classDeclaration(node);
    } else if (node is ClassTypeAlias) {
      // TODO(scheglov) ???
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
    } else if (node is GenericTypeAlias) {
      // TODO(scheglov) ???
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
    } else if (node is MixinDeclaration) {
      // TODO(scheglov) ???
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

  void _functionTypeAlias(FunctionTypeAlias node) {
    var returnTypeNode = node.returnType;
    LazyAst.setReturnType(node, returnTypeNode?.type ?? _dynamicType);
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
    );
    LazyAst.setType(node, type);
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
  final Dart2TypeSystem typeSystem;

  InterfaceType classType;
  List<InterfaceType> mixinTypes = [];
  List<InterfaceType> supertypesForMixinInference;

  _MixinInference(this.typeSystem, this.classType);

  void perform(WithClause withClause) {
    if (withClause == null) return;

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
    var mixinType = _interfaceType(mixinNode.type);

    if (mixinNode.typeArguments != null) {
      return mixinType;
    }

    var mixinElement = mixinType.element;
    if (mixinElement.typeParameters.isEmpty) {
      return mixinType;
    }

    var mixinSupertypeConstraints =
        typeSystem.gatherMixinSupertypeConstraintsForInference(mixinElement);
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
    var inferredMixin = typeSystem.matchSupertypeConstraints(
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
    return typeSystem.typeProvider.objectType;
  }
}

/// Performs mixin inference for all declarations.
class _MixinsInference {
  final Dart2TypeSystem typeSystem;

  _MixinsInference(this.typeSystem);

  void perform(List<AstNode> declarations) {
    for (var node in declarations) {
      if (node is ClassDeclaration || node is ClassTypeAlias) {
        ClassElementImpl element = (node as Declaration).declaredElement;
        element.linkedMixinInferenceCallback = _callbackWhenRecursion;
      }
    }

    for (var declaration in declarations) {
      _inferDeclaration(declaration);
    }
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are inferring the [element] now, i.e. there is a loop.
  ///
  /// This is an error. So, we return the empty list, and break the loop.
  List<InterfaceType> _callbackWhenLoop(ClassElementImpl element) {
    element.linkedMixinInferenceCallback = null;
    return <InterfaceType>[];
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are not inferring the [element] now, i.e. there is no loop.
  List<InterfaceType> _callbackWhenRecursion(ClassElementImpl element) {
    _inferDeclaration(element.linkedNode);
    // The inference was successful, let the element return actual mixins.
    return null;
  }

  void _infer(ClassElementImpl element, WithClause withClause) {
    element.linkedMixinInferenceCallback = _callbackWhenLoop;
    try {
      _MixinInference(typeSystem, element.type).perform(withClause);
    } finally {
      element.linkedMixinInferenceCallback = null;
    }
  }

  void _inferDeclaration(AstNode node) {
    if (node is ClassDeclaration) {
      _infer(node.declaredElement, node.withClause);
    } else if (node is ClassTypeAlias) {
      _infer(node.declaredElement, node.withClause);
    }
  }
}
