// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';
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
  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// Build types for all type annotations, and set types for declarations.
  void build(NodesToBuildType nodes) {
    DefaultTypesBuilder().build(nodes.declarations);

    for (var builder in nodes.typeBuilders) {
      builder.build();
    }

    _MixinsInference().perform(nodes.declarations);

    for (var declaration in nodes.declarations) {
      _declaration(declaration);
    }
  }

  FunctionType _buildFunctionType(
    TypeParameterList typeParameterList,
    TypeAnnotation returnTypeNode,
    FormalParameterList parameterList,
    NullabilitySuffix nullabilitySuffix,
  ) {
    var returnType = returnTypeNode?.type ?? _dynamicType;
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  void _classDeclaration(ClassDeclaration node) {}

  void _classTypeAlias(ClassTypeAlias node) {}

  void _declaration(AstNode node) {
    if (node is ClassDeclaration) {
      _classDeclaration(node);
    } else if (node is ClassTypeAlias) {
      _classTypeAlias(node);
    } else if (node is ExtensionDeclaration) {
      _extensionDeclaration(node);
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
      var element = node.declaredElement as ExecutableElementImpl;
      element.returnType = returnType;
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
      var element = node.declaredElement as ExecutableElementImpl;
      element.returnType = returnType;
    } else if (node is MixinDeclaration) {
      // TODO(scheglov) ???
    } else if (node is SimpleFormalParameter) {
      var element = node.declaredElement as ParameterElementImpl;
      element.type = node.type?.type ?? _dynamicType;
    } else if (node is VariableDeclarationList) {
      var type = node.type?.type;
      if (type != null) {
        for (var variable in node.variables) {
          (variable.declaredElement as VariableElementImpl).type = type;
        }
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  void _extensionDeclaration(ExtensionDeclaration node) {}

  void _fieldFormalParameter(FieldFormalParameter node) {
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      var element = node.declaredElement as ParameterElementImpl;
      element.type = type;
    } else {
      var element = node.declaredElement as ParameterElementImpl;
      element.type = node.type?.type ?? _dynamicType;
    }
  }

  List<ParameterElement> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return parameter.declaredElement;
    }).toList();
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var returnTypeNode = node.returnType;
    var element = node.declaredElement as FunctionTypeAliasElementImpl;
    element.function.returnType = returnTypeNode?.type ?? _dynamicType;
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
      _nullability(node, node.question != null),
    );
    var element = node.declaredElement as ParameterElementImpl;
    element.type = type;
  }

  bool _isNonNullableByDefault(AstNode node) {
    var unit = node.thisOrAncestorOfType<CompilationUnit>();
    return unit.featureSet.isEnabled(Feature.non_nullable);
  }

  NullabilitySuffix _nullability(AstNode node, bool hasQuestion) {
    if (_isNonNullableByDefault(node)) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    } else {
      return NullabilitySuffix.star;
    }
  }

  List<TypeParameterElement> _typeParameters(TypeParameterList node) {
    if (node == null) {
      return const <TypeParameterElement>[];
    }

    return node.typeParameters
        .map<TypeParameterElement>((p) => p.declaredElement)
        .toList();
  }
}

/// Performs mixins inference in a [ClassDeclaration].
class _MixinInference {
  final ClassElementImpl element;
  final TypeSystemImpl typeSystem;
  final FeatureSet featureSet;
  final InterfaceType classType;

  InterfacesMerger interfacesMerger;

  _MixinInference(this.element, this.featureSet)
      : typeSystem = element.library.typeSystem,
        classType = element.thisType {
    interfacesMerger = InterfacesMerger(typeSystem);
    interfacesMerger.addWithSupertypes(element.supertype);
  }

  NullabilitySuffix get _noneOrStarSuffix {
    return _nonNullableEnabled
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  bool get _nonNullableEnabled => featureSet.isEnabled(Feature.non_nullable);

  void perform(WithClause withClause) {
    if (withClause == null) return;

    for (var mixinNode in withClause.mixinTypes) {
      var mixinType = _inferSingle(mixinNode);
      interfacesMerger.addWithSupertypes(mixinType);
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

    var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
      mixinSupertypeConstraints,
      interfacesMerger.typeList,
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
    var inferredTypeArguments = typeSystem.matchSupertypeConstraints(
      mixinElement,
      mixinSupertypeConstraints,
      matchingInterfaceTypes,
    );
    if (inferredTypeArguments != null) {
      var inferredMixin = mixinElement.instantiate(
        typeArguments: inferredTypeArguments,
        nullabilitySuffix: _noneOrStarSuffix,
      );
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

    _resetHierarchies(declarations);
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
      var featureSet = _unitFeatureSet(element);
      _MixinInference(element, featureSet).perform(withClause);
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

  /// When a loop is detected during mixin inference, we pretend that the list
  /// of mixins of the class is empty. But if this happens during building a
  /// class hierarchy, we cache such incomplete hierarchy. So, here we reset
  /// hierarchies for all classes being linked, indiscriminately.
  void _resetHierarchies(List<AstNode> declarations) {
    for (var declaration in declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        var element = declaration.declaredElement;
        var sessionImpl = element.library.session as AnalysisSessionImpl;
        sessionImpl.classHierarchy.remove(element);
      }
    }
  }

  static FeatureSet _unitFeatureSet(ClassElementImpl element) {
    var unit = element.linkedNode.parent as CompilationUnit;
    return unit.featureSet;
  }
}
