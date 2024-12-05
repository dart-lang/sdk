// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';
import 'package:analyzer/src/summary2/extension_type.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/type_builder.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Return `true` if [type] can be used as a class.
bool _isInterfaceTypeClass(InterfaceType type) {
  if (type.element is! ClassElement) {
    return false;
  }
  return _isInterfaceTypeInterface(type);
}

/// Return `true` if [type] can be used as an interface or a mixin.
bool _isInterfaceTypeInterface(InterfaceType type) {
  if (type.element is EnumElement) {
    return false;
  }
  if (type.element is ExtensionTypeElement) {
    return false;
  }
  if (type.isDartCoreFunction || type.isDartCoreNull) {
    return false;
  }
  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    return false;
  }
  return true;
}

List<InterfaceType> _toInterfaceTypeList(List<NamedType>? nodeList) {
  if (nodeList != null) {
    return nodeList
        .map((e) => e.type)
        .whereType<InterfaceType>()
        .where(_isInterfaceTypeInterface)
        .toList();
  }
  return const [];
}

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
  final Linker _linker;
  final Map<InstanceElementImpl, _ToInferMixins> _toInferMixins = {};

  TypesBuilder(this._linker);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// Build types for all type annotations, and set types for declarations.
  void build(NodesToBuildType nodes) {
    DefaultTypesBuilder(_linker).build(nodes.declarations);

    for (var builder in nodes.typeBuilders) {
      builder.build();
    }

    for (var declaration in nodes.declarations) {
      _declaration(declaration);
    }

    buildExtensionTypes(_linker, nodes.declarations);
    _MixinsInference(_toInferMixins).perform();
  }

  FunctionType _buildFunctionType(
    TypeParameterList? typeParameterList,
    TypeAnnotation? returnTypeNode,
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

  void _classDeclaration(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;

    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      var type = extendsClause.superclass.type;
      if (type is InterfaceType && _isInterfaceTypeClass(type)) {
        element.supertype = type;
      }
    } else if (element.isDartCoreObject) {
      element.setModifier(Modifier.DART_CORE_OBJECT, true);
    }

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(element, withClause: node.withClause);
  }

  void _classTypeAlias(ClassTypeAlias node) {
    var element = node.declaredElement as ClassElementImpl;

    var superType = node.superclass.type;
    if (superType is InterfaceType && _isInterfaceTypeClass(superType)) {
      element.supertype = superType;
    }

    element.mixins = _toInterfaceTypeList(
      node.withClause.mixinTypes,
    );

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _toInferMixins[element] = _ToInferMixins(element, node.withClause);
  }

  void _declaration(AstNode node) {
    if (node is ClassDeclaration) {
      _classDeclaration(node);
    } else if (node is ClassTypeAlias) {
      _classTypeAlias(node);
    } else if (node is EnumDeclaration) {
      _enumDeclaration(node);
    } else if (node is ExtensionDeclaration) {
      _extensionDeclaration(node);
    } else if (node is ExtensionTypeDeclarationImpl) {
      _extensionTypeDeclaration(node);
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
    } else if (node is GenericFunctionTypeImpl) {
      _genericFunctionType(node);
    } else if (node is GenericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node is MethodDeclaration) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else if (node.isOperator && node.name.lexeme == '[]=') {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      var element = node.declaredElement as ExecutableElementImpl;
      element.returnType = returnType;
    } else if (node is MixinDeclaration) {
      _mixinDeclaration(node);
    } else if (node is SimpleFormalParameter) {
      var element = node.declaredElement as ParameterElementImpl;
      element.type = node.type?.type ?? _dynamicType;
    } else if (node is SuperFormalParameter) {
      _superFormalParameter(node);
    } else if (node is TypeParameterImpl) {
      _typeParameter(node);
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

  void _enumDeclaration(EnumDeclaration node) {
    var element = node.declaredElement as EnumElementImpl;

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(element, withClause: node.withClause);
  }

  void _extensionDeclaration(ExtensionDeclaration node) {
    var element = node.declaredElement as ExtensionElementImpl;
    if (element.augmentationTarget == null) {
      if (node.onClause case var onClause?) {
        var extendedType = onClause.extendedType.typeOrThrow;
        element.augmented.extendedType = extendedType;
      }
    } else {
      _updatedAugmented(element);
    }
  }

  void _extensionTypeDeclaration(ExtensionTypeDeclarationImpl node) {
    var element = node.declaredElement as ExtensionTypeElementImpl;

    var typeSystem = element.library.typeSystem;
    var interfaces = node.implementsClause?.interfaces
        .map((e) => e.type)
        .whereType<InterfaceType>()
        .where(typeSystem.isValidExtensionTypeSuperinterface)
        .toFixedList();
    if (interfaces != null) {
      element.interfaces = interfaces;
    }

    _updatedAugmented(element);
  }

  void _fieldFormalParameter(FieldFormalParameter node) {
    var element = node.declaredElement as FieldFormalParameterElementImpl;
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      element.type = type;
    } else {
      element.type = node.type?.type ?? _dynamicType;
    }
  }

  List<ParameterElement> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return parameter.declaredElement!;
    }).toFixedList();
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var element = node.declaredElement as TypeAliasElementImpl;
    var function = element.aliasedElement as GenericFunctionTypeElementImpl;
    function.returnType = node.returnType?.type ?? _dynamicType;
    element.aliasedType = function.type;
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

  void _genericFunctionType(GenericFunctionTypeImpl node) {
    var element = node.declaredElement!;
    element.returnType = node.returnType?.type ?? _dynamicType;
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    var element = node.declaredElement as TypeAliasElementImpl;
    var featureSet = element.library.featureSet;

    var typeNode = node.type;
    if (featureSet.isEnabled(Feature.nonfunction_type_aliases)) {
      element.aliasedType = typeNode.typeOrThrow;
    } else if (typeNode is GenericFunctionType) {
      element.aliasedType = typeNode.typeOrThrow;
    } else {
      element.aliasedType = _errorFunctionType();
    }
  }

  void _mixinDeclaration(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;

    var constraints = _toInterfaceTypeList(
      node.onClause?.superclassConstraints,
    );
    element.superclassConstraints = constraints;

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(element);
  }

  NullabilitySuffix _nullability(AstNode node, bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  void _superFormalParameter(SuperFormalParameter node) {
    var element = node.declaredElement as SuperFormalParameterElementImpl;
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      element.type = type;
    } else {
      element.type = node.type?.type ?? _dynamicType;
    }
  }

  void _typeParameter(TypeParameterImpl node) {
    var element = node.declaredElement!;
    element.bound = node.bound?.type;
  }

  List<TypeParameterElement> _typeParameters(TypeParameterList? node) {
    if (node == null) {
      return const <TypeParameterElement>[];
    }

    return node.typeParameters
        .map<TypeParameterElement>((p) => p.declaredElement!)
        .toFixedList();
  }

  void _updatedAugmented(
    InstanceElementImpl element, {
    WithClause? withClause,
  }) {
    // Always schedule mixin inference for the declaration.
    if (element.augmentationTarget == null) {
      if (element is InterfaceElementImpl) {
        _toInferMixins[element] = _ToInferMixins(element, withClause);
      }
    }

    // Here we merge declaration and augmentations.
    // If there are no augmentations, nothing to do.
    var augmented = element.augmented;
    if (augmented is! AugmentedInstanceElementImpl) {
      return;
    }

    var declaration = augmented.declaration;
    var declarationTypeParameters = declaration.typeParameters;

    var augmentationTypeParameters = element.typeParameters;
    if (augmentationTypeParameters.length != declarationTypeParameters.length) {
      return;
    }

    var toDeclaration = Substitution.fromPairs(
      augmentationTypeParameters,
      declarationTypeParameters.instantiateNone(),
    );

    var fromDeclaration = Substitution.fromPairs(
      declarationTypeParameters,
      augmentationTypeParameters.instantiateNone(),
    );

    // Schedule mixing inference for augmentations.
    if (element.augmentationTarget != null) {
      if (element is InterfaceElementImpl && withClause != null) {
        var toInferMixins = _toInferMixins[declaration];
        if (toInferMixins != null) {
          toInferMixins.augmentations.add(
            _ToInferMixinsAugmentation(
              element: element,
              withClause: withClause,
              toDeclaration: toDeclaration,
              fromDeclaration: fromDeclaration,
            ),
          );
        }
      }
    }

    if (element is InterfaceElementImpl &&
        declaration is InterfaceElementImpl &&
        augmented is AugmentedInterfaceElementImpl) {
      if (declaration.supertype == null) {
        var elementSuperType = element.supertype;
        if (elementSuperType != null) {
          var superType = toDeclaration.mapInterfaceType(elementSuperType);
          declaration.supertype = superType;
        }
      }

      augmented.interfaces.addAll(
        toDeclaration.mapInterfaceTypes(element.interfaces),
      );
    }

    if (element is MixinElementImpl && augmented is AugmentedMixinElementImpl) {
      augmented.superclassConstraints.addAll(
        toDeclaration.mapInterfaceTypes(element.superclassConstraints),
      );
    }
  }

  /// The [FunctionType] to use when a function type is expected for a type
  /// alias, but the actual provided type annotation is not a function type.
  static FunctionTypeImpl _errorFunctionType() {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

/// Performs mixins inference in a [ClassDeclaration].
class _MixinInference {
  final InterfaceElementImpl element;
  final TypeSystemImpl typeSystem;
  final FeatureSet featureSet;
  final InterfaceType classType;
  final TypeSystemOperations typeSystemOperations;

  late final InterfacesMerger interfacesMerger;

  _MixinInference(this.element, this.featureSet,
      {required this.typeSystemOperations})
      : typeSystem = element.library.typeSystem,
        classType = element.thisType {
    interfacesMerger = InterfacesMerger(typeSystem);
    interfacesMerger.addWithSupertypes(element.supertype);
  }

  void addTypes(Iterable<InterfaceType> types) {
    for (var type in types) {
      interfacesMerger.addWithSupertypes(type);
    }
  }

  List<InterfaceType> perform(WithClause withClause) {
    var result = <InterfaceType>[];
    for (var mixinNode in withClause.mixinTypes) {
      var mixinType = _inferSingle(mixinNode as NamedTypeImpl);
      if (mixinType != null && _isInterfaceTypeInterface(mixinType)) {
        result.add(mixinType);
        interfacesMerger.addWithSupertypes(mixinType);
      }
    }
    return result;
  }

  InterfaceType? _findInterfaceTypeForElement(
    InterfaceElement element,
    List<InterfaceType> interfaceTypes,
  ) {
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element == element) return interfaceType;
    }
    return null;
  }

  List<InterfaceType>? _findInterfaceTypesForConstraints(
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

  InterfaceType? _inferSingle(NamedTypeImpl mixinNode) {
    var mixinType = _interfaceType(mixinNode.typeOrThrow);
    if (mixinType == null) {
      return null;
    }

    if (mixinNode.typeArguments != null) {
      return mixinType;
    }

    List<TypeParameterElement>? typeParameters;
    List<InterfaceType>? supertypeConstraints;
    InterfaceType Function(List<DartType> typeArguments)? instantiate;
    var mixinElement = mixinNode.element;
    if (mixinElement is InterfaceElement) {
      typeParameters = mixinElement.typeParameters;
      if (typeParameters.isNotEmpty) {
        supertypeConstraints = typeSystem
            .gatherMixinSupertypeConstraintsForInference(mixinElement);
        instantiate = (typeArguments) {
          return mixinElement.instantiate(
            typeArguments: typeArguments,
            nullabilitySuffix: mixinType.nullabilitySuffix,
          );
        };
      }
    } else if (mixinElement is TypeAliasElementImpl) {
      typeParameters = mixinElement.typeParameters;
      if (typeParameters.isNotEmpty) {
        var rawType = mixinElement.rawType;
        if (rawType is InterfaceType) {
          supertypeConstraints = rawType.superclassConstraints;
          instantiate = (typeArguments) {
            return mixinElement.instantiate(
              typeArguments: typeArguments,
              nullabilitySuffix: mixinType.nullabilitySuffix,
            ) as InterfaceType;
          };
        }
      }
    }

    if (typeParameters == null ||
        supertypeConstraints == null ||
        instantiate == null) {
      return mixinType;
    }

    var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
      supertypeConstraints,
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
      typeParameters,
      supertypeConstraints,
      matchingInterfaceTypes,
      genericMetadataIsEnabled: featureSet.isEnabled(Feature.generic_metadata),
      inferenceUsingBoundsIsEnabled:
          featureSet.isEnabled(Feature.inference_using_bounds),
      strictInference: false,
      strictCasts: false,
      typeSystemOperations: typeSystemOperations,
    );
    if (inferredTypeArguments == null) {
      return mixinType;
    }

    return instantiate(inferredTypeArguments);
  }

  InterfaceType? _interfaceType(DartType type) {
    if (type is InterfaceType && _isInterfaceTypeInterface(type)) {
      return type;
    }
    return null;
  }
}

/// Performs mixin inference for all declarations.
class _MixinsInference {
  final Map<InstanceElementImpl, _ToInferMixins> _declarations;

  _MixinsInference(this._declarations);

  void perform() {
    for (var declaration in _declarations.values) {
      var element = declaration.element;
      element.mixinInferenceCallback = _callbackWhenRecursion;
    }

    for (var declaration in _declarations.values) {
      _inferDeclaration(declaration);
    }

    _resetHierarchies();
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are inferring the [element] now, i.e. there is a loop.
  ///
  /// This is an error. So, we return the empty list, and break the loop.
  List<InterfaceType> _callbackWhenLoop(InterfaceElementImpl element) {
    element.mixinInferenceCallback = null;
    return <InterfaceType>[];
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are not inferring the [element] now, i.e. there is no loop.
  List<InterfaceType>? _callbackWhenRecursion(InterfaceElementImpl element) {
    var declaration = _declarations[element];
    if (declaration != null) {
      _inferDeclaration(declaration);
    }
    // The inference was successful, let the element return actual mixins.
    return null;
  }

  void _inferDeclaration(_ToInferMixins declaration) {
    var element = declaration.element;
    element.mixinInferenceCallback = _callbackWhenLoop;

    var featureSet = element.library.featureSet;
    var declarationMixins = <InterfaceType>[];

    try {
      // Casts aren't relevant for mixin inference.
      var typeSystemOperations =
          TypeSystemOperations(element.library.typeSystem, strictCasts: false);

      if (declaration.withClause case var withClause?) {
        var inference = _MixinInference(element, featureSet,
            typeSystemOperations: typeSystemOperations);
        var inferred = inference.perform(withClause);
        element.mixins = inferred;
        declarationMixins.addAll(inferred);
      }

      for (var augmentation in declaration.augmentations) {
        var inference = _MixinInference(element, featureSet,
            typeSystemOperations: typeSystemOperations);
        inference.addTypes(
          augmentation.fromDeclaration.mapInterfaceTypes(declarationMixins),
        );
        var inferred = inference.perform(augmentation.withClause);
        augmentation.element.mixins = inferred;
        declarationMixins.addAll(
          augmentation.toDeclaration.mapInterfaceTypes(inferred),
        );
      }
    } finally {
      element.mixinInferenceCallback = null;
      switch (element.augmented) {
        case AugmentedInterfaceElementImpl augmented:
          augmented.mixins.addAll(declarationMixins);
      }
    }
  }

  /// When a loop is detected during mixin inference, we pretend that the list
  /// of mixins of the class is empty. But if this happens during building a
  /// class hierarchy, we cache such incomplete hierarchy. So, here we reset
  /// hierarchies for all classes being linked, indiscriminately.
  void _resetHierarchies() {
    for (var declaration in _declarations.values) {
      var element = declaration.element;
      element.library.session.classHierarchy.remove(element);
    }
  }
}

/// The declaration of a class that can have mixins.
class _ToInferMixins {
  final InterfaceElementImpl element;
  final WithClause? withClause;
  final List<_ToInferMixinsAugmentation> augmentations = [];

  _ToInferMixins(this.element, this.withClause) {
    assert(element.augmentationTarget == null);
  }
}

class _ToInferMixinsAugmentation {
  final InterfaceElementImpl element;
  final WithClause withClause;
  final MapSubstitution toDeclaration;
  final MapSubstitution fromDeclaration;

  _ToInferMixinsAugmentation({
    required this.element,
    required this.withClause,
    required this.toDeclaration,
    required this.fromDeclaration,
  }) {
    assert(element.isAugmentation);
  }
}
