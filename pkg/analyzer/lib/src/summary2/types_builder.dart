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
  final Map<InstanceFragmentImpl, _ToInferMixins> _toInferMixins = {};

  TypesBuilder(this._linker);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// Build types for all type annotations, and set types for declarations.
  void build(NodesToBuildType nodes) {
    DefaultTypesBuilder(
      getTypeParameterNode: _linker.getLinkingNode2,
    ).build(nodes.declarations);

    for (var builder in nodes.typeBuilders) {
      builder.build();
    }

    for (var declaration in nodes.declarations) {
      _declaration(declaration);
    }

    buildExtensionTypes(_linker, nodes.declarations);
    _MixinsInference(_toInferMixins).perform();
  }

  FunctionTypeImpl _buildFunctionType(
    TypeParameterListImpl? typeParameterList,
    TypeAnnotationImpl? returnTypeNode,
    FormalParameterList parameterList,
    NullabilitySuffix nullabilitySuffix,
  ) {
    var returnType = returnTypeNode?.type ?? _dynamicType;
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl(
      typeParameters: typeParameters.map((f) => f.asElement2).toList(),
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  void _classDeclaration(ClassDeclarationImpl node) {
    var element = node.declaredFragment!;

    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      var type = extendsClause.superclass.type;
      if (type is InterfaceTypeImpl && _isInterfaceTypeClass(type)) {
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

  void _classTypeAlias(ClassTypeAliasImpl node) {
    var element = node.declaredFragment!;

    var superType = node.superclass.type;
    if (superType is InterfaceTypeImpl && _isInterfaceTypeClass(superType)) {
      element.supertype = superType;
    }

    element.mixins = _toInterfaceTypeList(node.withClause.mixinTypes);

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(element, withClause: node.withClause);

    _toInferMixins[element] = _ToInferMixins(element, node.withClause);
  }

  void _declaration(AstNode node) {
    if (node is ClassDeclarationImpl) {
      _classDeclaration(node);
    } else if (node is ClassTypeAliasImpl) {
      _classTypeAlias(node);
    } else if (node is EnumDeclarationImpl) {
      _enumDeclaration(node);
    } else if (node is ExtensionDeclarationImpl) {
      _extensionDeclaration(node);
    } else if (node is ExtensionTypeDeclarationImpl) {
      _extensionTypeDeclaration(node);
    } else if (node is FieldFormalParameterImpl) {
      _fieldFormalParameter(node);
    } else if (node is FunctionDeclarationImpl) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      var fragment = node.declaredFragment!;
      var element = fragment.element;
      fragment.returnType = returnType;

      switch (element) {
        case GetterElementImpl():
          element.returnType = returnType;
          element.variable3!.firstFragment.type = returnType;
        case SetterElementImpl():
          element.returnType = returnType;
          var valueElement =
              element.formalParameters.singleOrNull
                  as FormalParameterElementImpl?;
          var valueNode =
              node.functionExpression.parameters?.parameters.firstOrNull;
          var valueNodeType = valueNode?.declaredFragment!.type;
          valueElement?.type = valueNodeType ?? InvalidTypeImpl.instance;

          var variableElement = element.variable3!;
          if (variableElement.isSynthetic && valueElement != null) {
            variableElement.firstFragment.type = valueElement.type;
          }
        case TopLevelFunctionElementImpl():
          element.returnType = returnType;
      }
    } else if (node is FunctionTypeAliasImpl) {
      _functionTypeAlias(node);
    } else if (node is FunctionTypedFormalParameterImpl) {
      _functionTypedFormalParameter(node);
    } else if (node is GenericFunctionTypeImpl) {
      _genericFunctionType(node);
    } else if (node is GenericTypeAliasImpl) {
      _genericTypeAlias(node);
    } else if (node is MethodDeclarationImpl) {
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
      var fragment = node.declaredFragment!;
      var element = fragment.element;
      fragment.returnType = returnType;
      switch (element) {
        case GetterElementImpl():
          element.returnType = returnType;
          element.variable3!.firstFragment.type = returnType;
        case SetterElementImpl():
          element.returnType = returnType;
          var fragmentValue =
              element.formalParameters.singleOrNull
                  as FormalParameterElementImpl?;
          var valueNode = node.parameters?.parameters.firstOrNull;
          var valueNodeType = valueNode?.declaredFragment!.type;
          fragmentValue?.type = valueNodeType ?? InvalidTypeImpl.instance;
        case MethodElementImpl():
          element.returnType = returnType;
      }
    } else if (node is MixinDeclarationImpl) {
      _mixinDeclaration(node);
    } else if (node is SimpleFormalParameterImpl) {
      var fragment = node.declaredFragment!;
      fragment.type = node.type?.type ?? _dynamicType;
    } else if (node is SuperFormalParameterImpl) {
      _superFormalParameter(node);
    } else if (node is TypeParameterImpl) {
      _typeParameter(node);
    } else if (node is VariableDeclarationListImpl) {
      var type = node.type?.type;
      if (type != null) {
        for (var variable in node.variables) {
          var variableFragment = variable.declaredFragment!;
          var variableElement = variableFragment.element;
          variableFragment.type = type;
          if (variableElement is PropertyInducingElementImpl) {
            if (variableElement.getter2 case var getterElement?) {
              getterElement.returnType = type;
              getterElement.firstFragment.returnType = type;
            }
            if (variableElement.setter2 case var setterElement?) {
              setterElement.returnType = VoidTypeImpl.instance;
              setterElement.firstFragment.returnType = VoidTypeImpl.instance;
              (setterElement.formalParameters.single
                      as FormalParameterElementImpl)
                  .type = type;
              (setterElement.formalParameters.single
                      as FormalParameterElementImpl)
                  .firstFragment
                  .type = type;
            }
          }
        }
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  void _enumDeclaration(EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    fragment.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(fragment, withClause: node.withClause);
  }

  void _extensionDeclaration(ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    if (node.onClause case var onClause?) {
      var extendedType = onClause.extendedType.typeOrThrow;
      fragment.element.extendedType = extendedType;
    }
  }

  void _extensionTypeDeclaration(ExtensionTypeDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    var typeSystem = fragment.library.typeSystem;
    var interfaces =
        node.implementsClause?.interfaces
            .map((e) => e.type)
            .whereType<InterfaceType>()
            .where(typeSystem.isValidExtensionTypeSuperinterface)
            .toFixedList();
    if (interfaces != null) {
      fragment.interfaces = interfaces;
    }

    _updatedAugmented(fragment);
  }

  void _fieldFormalParameter(FieldFormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      fragment.type = type;
    } else {
      fragment.type = node.type?.type ?? _dynamicType;
    }
  }

  List<FormalParameterElementMixin> _formalParameters(
    FormalParameterList node,
  ) {
    return node.parameters.asImpl.map((parameter) {
      return parameter.declaredFragment!.element;
    }).toFixedList();
  }

  void _functionTypeAlias(FunctionTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var function = fragment.aliasedElement as GenericFunctionTypeFragmentImpl;
    function.returnType = node.returnType?.type ?? _dynamicType;
    fragment.aliasedType = function.type;
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameterImpl node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
      _nullability(node, node.question != null),
    );
    var fragment = node.declaredFragment!;
    fragment.type = type;
  }

  void _genericFunctionType(GenericFunctionTypeImpl node) {
    var fragment = node.declaredFragment!;
    fragment.returnType = node.returnType?.type ?? _dynamicType;
  }

  void _genericTypeAlias(GenericTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var featureSet = fragment.library.featureSet;

    var typeNode = node.type;
    if (featureSet.isEnabled(Feature.nonfunction_type_aliases)) {
      fragment.aliasedType = typeNode.typeOrThrow;
    } else if (typeNode is GenericFunctionType) {
      fragment.aliasedType = typeNode.typeOrThrow;
    } else {
      fragment.aliasedType = _errorFunctionType();
    }
  }

  void _mixinDeclaration(MixinDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    var constraints = _toInterfaceTypeList(
      node.onClause?.superclassConstraints,
    );
    fragment.superclassConstraints = constraints;

    fragment.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces,
    );

    _updatedAugmented(fragment);
  }

  NullabilitySuffix _nullability(AstNode node, bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  void _superFormalParameter(SuperFormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      fragment.type = type;
    } else {
      fragment.type = node.type?.type ?? _dynamicType;
    }
  }

  void _typeParameter(TypeParameterImpl node) {
    var fragment = node.declaredFragment!;
    fragment.bound = node.bound?.type;
  }

  List<TypeParameterFragmentImpl> _typeParameters(TypeParameterListImpl? node) {
    if (node == null) {
      return const <TypeParameterFragmentImpl>[];
    }

    return node.typeParameters.map((p) => p.declaredFragment!).toFixedList();
  }

  // TODO(scheglov): remove it, mostly.
  void _updatedAugmented(
    InstanceFragmentImpl fragment, {
    WithClause? withClause,
  }) {
    if (fragment is InterfaceFragmentImpl) {
      _toInferMixins[fragment] = _ToInferMixins(fragment, withClause);
    }

    // TODO(scheglov): restore?
    // var element = fragment.element;
    // if (fragment is MixinFragmentImpl && element is MixinElementImpl2) {
    //   element.superclassConstraints.addAll(fragment.superclassConstraints);
    // }
  }

  /// The [FunctionType] to use when a function type is expected for a type
  /// alias, but the actual provided type annotation is not a function type.
  static FunctionTypeImpl _errorFunctionType() {
    return FunctionTypeImpl(
      typeParameters: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

/// Performs mixins inference in a [ClassDeclaration].
class _MixinInference {
  final InterfaceFragmentImpl element;
  final TypeSystemImpl typeSystem;
  final FeatureSet featureSet;
  final InterfaceType classType;
  final TypeSystemOperations typeSystemOperations;

  late final InterfacesMerger interfacesMerger;

  _MixinInference(
    this.element,
    this.featureSet, {
    required this.typeSystemOperations,
  }) : typeSystem = element.library.typeSystem,
       classType = element.element.thisType {
    interfacesMerger = InterfacesMerger(typeSystem);
    interfacesMerger.addWithSupertypes(element.supertype);
  }

  void addTypes(Iterable<InterfaceTypeImpl> types) {
    for (var type in types) {
      interfacesMerger.addWithSupertypes(type);
    }
  }

  List<InterfaceTypeImpl> perform(WithClause withClause) {
    var result = <InterfaceTypeImpl>[];
    for (var mixinNode in withClause.mixinTypes) {
      var mixinType = _inferSingle(mixinNode as NamedTypeImpl);
      if (mixinType != null && _isInterfaceTypeInterface(mixinType)) {
        result.add(mixinType);
        interfacesMerger.addWithSupertypes(mixinType);
      }
    }
    return result;
  }

  InterfaceTypeImpl? _findInterfaceTypeForElement(
    InterfaceElement element,
    List<InterfaceTypeImpl> interfaceTypes,
  ) {
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element == element) return interfaceType;
    }
    return null;
  }

  List<InterfaceTypeImpl>? _findInterfaceTypesForConstraints(
    List<InterfaceType> constraints,
    List<InterfaceTypeImpl> interfaceTypes,
  ) {
    var result = <InterfaceTypeImpl>[];
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

  InterfaceTypeImpl? _inferSingle(NamedTypeImpl mixinNode) {
    var mixinType = _interfaceType(mixinNode.typeOrThrow);
    if (mixinType == null) {
      return null;
    }

    if (mixinNode.typeArguments != null) {
      return mixinType;
    }

    List<TypeParameterElementImpl>? typeParameters;
    List<InterfaceTypeImpl>? supertypeConstraints;
    InterfaceTypeImpl Function(List<TypeImpl> typeArguments)? instantiate;
    var mixinElement = mixinNode.element;
    if (mixinElement is InterfaceElementImpl) {
      typeParameters = mixinElement.typeParameters2;
      if (typeParameters.isNotEmpty) {
        supertypeConstraints = typeSystem
            .gatherMixinSupertypeConstraintsForInference(mixinElement);
        instantiate = (typeArguments) {
          return mixinElement.instantiateImpl(
            typeArguments: typeArguments,
            nullabilitySuffix: mixinType.nullabilitySuffix,
          );
        };
      }
    } else if (mixinElement is TypeAliasElementImpl) {
      typeParameters = mixinElement.typeParameters2;
      if (typeParameters.isNotEmpty) {
        var rawType = mixinElement.aliasedType;
        if (rawType is InterfaceTypeImpl) {
          supertypeConstraints = rawType.superclassConstraints;
          instantiate = (typeArguments) {
            return mixinElement.instantiateImpl(
                  typeArguments: typeArguments,
                  nullabilitySuffix: mixinType.nullabilitySuffix,
                )
                as InterfaceTypeImpl;
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
      inferenceUsingBoundsIsEnabled: featureSet.isEnabled(
        Feature.inference_using_bounds,
      ),
      strictInference: false,
      strictCasts: false,
      typeSystemOperations: typeSystemOperations,
    );
    if (inferredTypeArguments == null) {
      return mixinType;
    }

    return instantiate(inferredTypeArguments);
  }

  InterfaceTypeImpl? _interfaceType(DartType type) {
    if (type is InterfaceTypeImpl && _isInterfaceTypeInterface(type)) {
      return type;
    }
    return null;
  }
}

/// Performs mixin inference for all declarations.
class _MixinsInference {
  final Map<InstanceFragmentImpl, _ToInferMixins> _declarations;

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
  List<InterfaceType> _callbackWhenLoop(InterfaceFragmentImpl element) {
    element.mixinInferenceCallback = null;
    return <InterfaceType>[];
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are not inferring the [element] now, i.e. there is no loop.
  List<InterfaceType>? _callbackWhenRecursion(InterfaceFragmentImpl element) {
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
    var declarationMixins = <InterfaceTypeImpl>[];

    try {
      // Casts aren't relevant for mixin inference.
      var typeSystemOperations = TypeSystemOperations(
        element.library.typeSystem,
        strictCasts: false,
      );

      if (declaration.withClause case var withClause?) {
        var inference = _MixinInference(
          element,
          featureSet,
          typeSystemOperations: typeSystemOperations,
        );
        var inferred = inference.perform(withClause);
        element.mixins = inferred;
        declarationMixins.addAll(inferred);
      }

      for (var augmentation in declaration.augmentations) {
        var inference = _MixinInference(
          element,
          featureSet,
          typeSystemOperations: typeSystemOperations,
        );
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
    }
  }

  /// When a loop is detected during mixin inference, we pretend that the list
  /// of mixins of the class is empty. But if this happens during building a
  /// class hierarchy, we cache such incomplete hierarchy. So, here we reset
  /// hierarchies for all classes being linked, indiscriminately.
  void _resetHierarchies() {
    for (var declaration in _declarations.values) {
      var element = declaration.element;
      element.library.session.classHierarchy.remove(element.asElement2);
    }
  }
}

/// The declaration of a class that can have mixins.
class _ToInferMixins {
  final InterfaceFragmentImpl element;
  final WithClause? withClause;
  final List<_ToInferMixinsAugmentation> augmentations = [];

  _ToInferMixins(this.element, this.withClause);
}

class _ToInferMixinsAugmentation {
  final InterfaceFragmentImpl element;
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
