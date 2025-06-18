// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

/// An object used to infer the type of instance fields and the return types of
/// instance methods within a single compilation unit.
///
/// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md
class InstanceMemberInferrer {
  final InheritanceManager3 inheritance;
  final Set<InterfaceFragmentImpl> elementsBeingInferred = {};

  late InterfaceFragmentImpl currentInterfaceElement;

  /// Initialize a newly create inferrer.
  InstanceMemberInferrer(this.inheritance);

  TypeSystemImpl get typeSystem {
    return currentInterfaceElement.library.typeSystem;
  }

  /// Infer type information for all of the instance members in the given
  /// compilation [unit].
  void inferCompilationUnit(LibraryFragmentImpl unit) {
    _inferClasses(unit.classes);
    _inferClasses(unit.enums);
    _inferExtensionTypes(unit.extensionTypes);
    _inferClasses(unit.mixins);
  }

  /// Return `true` if the elements corresponding to the [elements] have the
  /// same kind as the [element].
  bool _allSameElementKind(
    ExecutableFragmentImpl element,
    List<ExecutableFragmentImpl> elements,
  ) {
    var elementKind = element.kind;
    for (int i = 0; i < elements.length; i++) {
      if (elements[i].kind != elementKind) {
        return false;
      }
    }
    return true;
  }

  /// Given a method, return the parameter in the method that corresponds to the
  /// given [parameter]. If the parameter is positional, then it appears at the
  /// given [index] in its enclosing element's list of parameters.
  FormalParameterElementMixin? _getCorrespondingParameter(
    ParameterElementMixin parameter,
    int index,
    List<FormalParameterElementMixin> methodParameters,
  ) {
    //
    // Find the corresponding parameter.
    //
    if (parameter.isNamed) {
      //
      // If we're looking for a named parameter, only a named parameter with
      // the same name will be matched.
      //
      return methodParameters.lastWhereOrNull(
        (methodParameter) =>
            methodParameter.isNamed && methodParameter.name3 == parameter.name2,
      );
    }
    //
    // If we're looking for a positional parameter we ignore the difference
    // between required and optional parameters.
    //
    if (index < methodParameters.length) {
      var matchingParameter = methodParameters[index];
      if (!matchingParameter.isNamed) {
        return matchingParameter;
      }
    }
    return null;
  }

  /// If the given [accessor] represents a non-synthetic instance property
  /// accessor for which no type was provided, infer its types.
  ///
  /// If the given [field] represents a non-synthetic instance field for
  /// which no type was provided, infer the type of the field.
  void _inferAccessorOrField({
    PropertyAccessorFragmentImpl? accessor,
    FieldFragmentImpl? field,
  }) {
    Uri elementLibraryUri;
    String elementName;

    if (accessor != null) {
      if (accessor.isSynthetic || accessor.isStatic) {
        return;
      }
      elementLibraryUri = accessor.library.source.uri;
      elementName = accessor.displayName;
    } else if (field != null) {
      if (field.isSynthetic || field.isStatic) {
        return;
      }
      elementLibraryUri = field.library.source.uri;
      elementName = field.name2 ?? '';
    } else {
      throw UnimplementedError();
    }

    var getterName = Name(elementLibraryUri, elementName);
    var overriddenGetters = inheritance.getOverridden2(
      currentInterfaceElement,
      getterName,
    );
    if (overriddenGetters != null) {
      overriddenGetters =
          overriddenGetters.where((e) {
            return e is PropertyAccessorElementOrMember && e.isGetter;
          }).toList();
    } else {
      overriddenGetters = const [];
    }

    var setterName = Name(elementLibraryUri, '$elementName=');
    var overriddenSetters = inheritance.getOverridden2(
      currentInterfaceElement,
      setterName,
    );
    overriddenSetters ??= const [];

    TypeImpl combinedGetterType() {
      var combinedGetterType = inheritance.combineSignatureTypes(
        typeSystem: typeSystem,
        candidates: overriddenGetters!,
        name: getterName,
      );
      if (combinedGetterType != null) {
        return combinedGetterType.returnType;
      }
      return DynamicTypeImpl.instance;
    }

    TypeImpl combinedSetterType() {
      var combinedSetterType = inheritance.combineSignatureTypes(
        typeSystem: typeSystem,
        candidates: overriddenSetters!,
        name: setterName,
      );
      if (combinedSetterType != null) {
        var parameters = combinedSetterType.parameters;
        if (parameters.isNotEmpty) {
          return parameters[0].type;
        }
      }
      return DynamicTypeImpl.instance;
    }

    if (accessor != null && accessor.isGetter) {
      if (!accessor.hasImplicitReturnType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      //
      // The return type of a getter which overrides/implements both a setter
      // and a getter is inferred to be the return type of the combined member
      // signature of said getter in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty) {
        var returnType = combinedGetterType();
        accessor.returnType = returnType;
        accessor.element.returnType = returnType;
        // TODO(scheglov): store type in FieldElementImpl itself
        (accessor.element.variable3 as FieldElementImpl).firstFragment.type =
            returnType;
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        var returnType = combinedSetterType();
        accessor.returnType = returnType;
        accessor.element.returnType = returnType;
        // TODO(scheglov): store type in FieldElementImpl itself
        (accessor.element.variable3 as FieldElementImpl).firstFragment.type =
            returnType;
        return;
      }

      return;
    }

    if (accessor != null && accessor.isSetter) {
      var parameters = accessor.parameters;
      if (parameters.isEmpty) {
        return;
      }
      var parameter = parameters[0];

      if (overriddenSetters.any((s) => _isCovariantSetter(s.declarationImpl))) {
        parameter.inheritsCovariant = true;
      }

      if (!parameter.hasImplicitType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty && overriddenSetters.isEmpty) {
        parameter.type = combinedGetterType();
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      //
      // The parameter type of a setter which overrides/implements both a
      // setter and a getter is inferred to be the parameter type of the
      // combined member signature of said setter in the direct superinterfaces.
      if (overriddenSetters.isNotEmpty) {
        parameter.type = combinedSetterType();
        return;
      }

      return;
    }

    if (field != null) {
      var setter = field.element.setter2?.firstFragment;
      if (setter != null) {
        if (overriddenSetters.any(
          (s) => _isCovariantSetter(s.declarationImpl),
        )) {
          var parameter = setter.parameters[0];
          parameter.inheritsCovariant = true;
        }
      }

      if (!field.hasImplicitType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty && overriddenSetters.isEmpty) {
        var type = combinedGetterType();
        _setFieldType(field, type);
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        var type = combinedSetterType();
        _setFieldType(field, type);
        return;
      }

      if (overriddenGetters.isNotEmpty && overriddenSetters.isNotEmpty) {
        // The type of a final field which overrides/implements both a setter
        // and a getter is inferred to be the return type of the combined
        // member signature of said getter in the direct superinterfaces.
        if (field.isFinal) {
          var type = combinedGetterType();
          _setFieldType(field, type);
          return;
        }

        // The type of a non-final field which overrides/implements both a
        // setter and a getter is inferred to be the parameter type of the
        // combined member signature of said setter in the direct
        // superinterfaces, if this type is the same as the return type of the
        // combined member signature of said getter in the direct
        // superinterfaces.
        if (!field.isFinal) {
          var getterType = combinedGetterType();
          var setterType = combinedSetterType();

          if (getterType == setterType) {
            _setFieldType(field, getterType);
          }
          return;
        }
      }

      // Otherwise, declarations of static variables and fields that omit a
      // type will be inferred from their initializer if present.
      return;
    }
  }

  /// Infer type information for all of the instance members in the given
  /// [classFragment].
  void _inferClass(InterfaceFragmentImpl classFragment) {
    if (classFragment.isAugmentation) {
      return;
    }

    if (classFragment.hasBeenInferred) {
      return;
    }

    _setInducedModifier(classFragment);

    if (!elementsBeingInferred.add(classFragment)) {
      // We have found a circularity in the class hierarchy. For now we just
      // stop trying to infer any type information for any classes that
      // inherit from any class in the cycle. We could potentially limit the
      // algorithm to only not inferring types in the classes in the cycle,
      // but it isn't clear that the results would be significantly better.
      throw _CycleException();
    }

    try {
      //
      // Ensure that all of instance members in the supertypes have had types
      // inferred for them.
      //
      var element = classFragment.element;
      _inferType(classFragment.supertype);
      element.mixins.forEach(_inferType);
      element.interfaces.forEach(_inferType);
      //
      // Then infer the types for the members.
      //
      // TODO(scheglov): get other members from the container
      currentInterfaceElement = classFragment;
      for (var field in classFragment.fields) {
        _inferAccessorOrField(field: field);
      }
      for (var accessor in classFragment.accessors) {
        _inferAccessorOrField(accessor: accessor);
      }
      for (var method in classFragment.methods) {
        _inferExecutable(method);
      }
      //
      // Infer initializing formal parameter types. This must happen after
      // field types are inferred.
      //
      for (var constructor in classFragment.constructors) {
        _inferConstructor(constructor);
      }
      classFragment.hasBeenInferred = true;
    } finally {
      elementsBeingInferred.remove(classFragment);
    }
  }

  void _inferClasses(List<InterfaceFragmentImpl> elements) {
    for (var element in elements) {
      try {
        _inferClass(element);
      } on _CycleException {
        // This is a short circuit return to prevent types that inherit from
        // types containing a circular reference from being inferred.
      }
    }
  }

  void _inferConstructor(ConstructorFragmentImpl constructor) {
    for (var parameter in constructor.parameters) {
      if (parameter.hasImplicitType) {
        if (parameter is FieldFormalParameterFragmentImpl) {
          var field = parameter.field;
          if (field != null) {
            parameter.type = field.type;
          }
        } else if (parameter is SuperFormalParameterFragmentImpl) {
          var superParameter = parameter.superConstructorParameter;
          if (superParameter != null) {
            parameter.type = superParameter.type;
          } else {
            parameter.type = DynamicTypeImpl.instance;
          }
        }
      }
    }

    var classElement = constructor.enclosingElement3;
    if (classElement is ClassFragmentImpl && classElement.isMixinApplication) {
      _inferMixinApplicationConstructor(classElement, constructor);
    }
  }

  /// If the given [element] represents a non-synthetic instance method,
  /// getter or setter, infer the return type and any parameter type(s) where
  /// they were not provided.
  void _inferExecutable(MethodFragmentImpl element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    var name = Name(element.library.source.uri, element.name2 ?? '');
    var overriddenElements = inheritance.getOverridden2(
      currentInterfaceElement,
      name,
    );
    if (overriddenElements == null ||
        !_allSameElementKind(
          element,
          overriddenElements.map((e) => e.declarationImpl).toList(),
        )) {
      return;
    }

    FunctionTypeImpl? combinedSignatureType;
    var hasImplicitType =
        element.hasImplicitReturnType ||
        element.parameters.any((e) => e.hasImplicitType);
    if (hasImplicitType) {
      var conflicts = <Conflict>[];
      combinedSignatureType = inheritance.combineSignatureTypes(
        typeSystem: typeSystem,
        candidates: overriddenElements,
        name: name,
        conflicts: conflicts,
      );
      if (combinedSignatureType != null) {
        combinedSignatureType = _toOverriddenFunctionType(
          element,
          combinedSignatureType,
        );
      } else {
        var conflictExplanation = '<unknown>';
        if (conflicts.length == 1) {
          var conflict = conflicts.single;
          if (conflict is CandidatesConflict) {
            conflictExplanation = conflict.candidates
                .map((candidate) {
                  var className = candidate.enclosingElementImpl.name2 ?? '';
                  var typeStr = candidate.type.getDisplayString();
                  return '$className.${name.name} ($typeStr)';
                })
                .join(', ');
          }
        }

        element.typeInferenceError = TopLevelInferenceError(
          kind: TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature,
          arguments: [conflictExplanation],
        );
      }
    }

    //
    // Infer the return type.
    //
    if (element.hasImplicitReturnType && element.displayName != '[]=') {
      if (combinedSignatureType != null) {
        element.returnType = combinedSignatureType.returnType;
        // TODO(scheglov): leave only element
        element.element.returnType = combinedSignatureType.returnType;
      } else {
        element.returnType = DynamicTypeImpl.instance;
        // TODO(scheglov): leave only element
        element.element.returnType = DynamicTypeImpl.instance;
      }
    }

    //
    // Infer the parameter types.
    //
    var parameters = element.parameters;
    for (var index = 0; index < parameters.length; index++) {
      var parameter = parameters[index];
      _inferParameterCovariance(parameter, index, overriddenElements);

      if (parameter.hasImplicitType) {
        _inferParameterType(parameter, index, combinedSignatureType);
      }
    }

    _resetOperatorEqualParameterTypeToDynamic(
      element,
      overriddenElements.map((e) => e.declarationImpl).toList(),
    );
  }

  void _inferExtensionTypes(List<ExtensionTypeFragmentImpl> extensionTypes) {
    for (var extensionType in extensionTypes) {
      for (var constructor in extensionType.constructors) {
        _inferConstructor(constructor);
      }
    }
  }

  void _inferMixinApplicationConstructor(
    ClassFragmentImpl classElement,
    ConstructorFragmentImpl constructor,
  ) {
    var superType = classElement.supertype;
    if (superType != null) {
      var index = classElement.constructors.indexOf(constructor);
      var superConstructors =
          superType.elementImpl.constructors
              .where(
                (element) =>
                    element.asElement2.isAccessibleIn2(classElement.library),
              )
              .toList();
      if (index < superConstructors.length) {
        var baseConstructor = superConstructors[index];
        var substitution = Substitution.fromInterfaceType(superType);
        forCorrespondingPairs<
          FormalParameterFragmentImpl,
          FormalParameterFragmentImpl
        >(constructor.parameters, baseConstructor.parameters, (
          parameter,
          baseParameter,
        ) {
          var type = substitution.substituteType(baseParameter.type);
          parameter.type = type;
        });
        // Update arguments of `SuperConstructorInvocation` to have the types
        // (which we have just set) of the corresponding formal parameters.
        // MixinApp(x, y) : super(x, y);
        var initializers = constructor.constantInitializers;
        var initializer = initializers.single as SuperConstructorInvocation;
        forCorrespondingPairs<FormalParameterFragmentImpl, Expression>(
          constructor.parameters,
          initializer.argumentList.arguments,
          (parameter, argument) {
            (argument as SimpleIdentifierImpl).setPseudoExpressionStaticType(
              parameter.type,
            );
          },
        );
      }
    }
  }

  /// If a parameter is covariant, any parameters that override it are too.
  void _inferParameterCovariance(
    FormalParameterFragmentImpl parameter,
    int index,
    Iterable<ExecutableElementOrMember> overridden,
  ) {
    parameter.inheritsCovariant = overridden.any((f) {
      var param = _getCorrespondingParameter(
        parameter,
        index,
        f.parameters.map((f) => f.asElement2).toList(),
      );
      return param != null && param.isCovariant;
    });
  }

  /// Set the type for the [parameter] at the given [index] from the given
  /// [combinedSignatureType], which might be `null` if there is no valid
  /// combined signature for signatures from direct superinterfaces.
  void _inferParameterType(
    FormalParameterFragmentImpl parameter,
    int index,
    FunctionTypeImpl? combinedSignatureType,
  ) {
    if (combinedSignatureType != null) {
      var matchingParameter = _getCorrespondingParameter(
        parameter,
        index,
        combinedSignatureType.parameters,
      );
      if (matchingParameter != null) {
        parameter.type = matchingParameter.type;
      } else {
        parameter.type = DynamicTypeImpl.instance;
      }
    } else {
      parameter.type = DynamicTypeImpl.instance;
    }
  }

  /// Infer type information for all of the instance members in the given
  /// interface [type].
  void _inferType(InterfaceTypeImpl? type) {
    if (type != null) {
      var element = type.elementImpl;
      _inferClass(element);
    }
  }

  /// In legacy mode, an override of `operator==` with no explicit parameter
  /// type inherits the parameter type of the overridden method if any override
  /// of `operator==` between the overriding method and `Object.==` has an
  /// explicit parameter type.  Otherwise, the parameter type of the
  /// overriding method is `dynamic`.
  ///
  /// https://github.com/dart-lang/language/issues/569
  void _resetOperatorEqualParameterTypeToDynamic(
    MethodFragmentImpl element,
    List<ExecutableFragmentImpl> overriddenElements,
  ) {
    if (element.name2 != '==') return;

    var parameters = element.parameters;
    if (parameters.length != 1) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    var parameter = parameters[0];
    if (!parameter.hasImplicitType) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    for (var overridden in overriddenElements) {
      overridden = overridden.declaration;

      // Skip Object itself.
      var enclosingElement =
          ElementImplExtension(overridden).enclosingElementImpl;
      if (enclosingElement is ClassFragmentImpl &&
          enclosingElement.isDartCoreObject) {
        continue;
      }

      // Keep the type if it is not directly from Object.
      if (overridden is MethodFragmentImpl &&
          !overridden.isOperatorEqualWithParameterTypeFromObject) {
        element.isOperatorEqualWithParameterTypeFromObject = false;
        return;
      }
    }

    element.isOperatorEqualWithParameterTypeFromObject = true;
  }

  /// Find and mark the induced modifier of an element, if the [classElement] is
  /// 'sealed'.
  void _setInducedModifier(InterfaceFragmentImpl classElement) {
    // Only sealed elements propagate induced modifiers.
    if (classElement is! ClassFragmentImpl || !classElement.isSealed) {
      return;
    }

    var supertype = classElement.supertype;
    var interfaces = classElement.interfaces;
    var mixins = classElement.mixins;

    if (mixins.any((type) => type.elementImpl.isFinal)) {
      // A sealed declaration is considered 'final' if it has a direct
      // superclass which is 'final'.
      classElement.isFinal = true;
      return;
    }

    if (supertype != null) {
      if (supertype.elementImpl.isFinal) {
        // A sealed declaration is considered 'final' if it has a direct
        // superclass which is 'final'.
        classElement.isFinal = true;
        return;
      }
      if (supertype.elementImpl.isBase) {
        // A sealed declaration is considered 'final' if it has a
        // direct superclass which is 'interface' and it has a direct
        // superinterface which is 'base'.
        if (mixins.any((type) => type.elementImpl.isInterface)) {
          classElement.isFinal = true;
          return;
        }

        // Otherwise, a sealed declaration is considered 'base' if it has a
        // direct superinterface which is 'base' or 'final'.
        classElement.isBase = true;
        return;
      }
      if (supertype.elementImpl.isInterface) {
        // A sealed declaration is considered 'final' if it has a
        // direct superclass which is 'interface' and it has a direct
        // superinterface which is 'base'.
        if (interfaces.any((type) => type.elementImpl.isBase) ||
            mixins.any((type) => type.elementImpl.isBase)) {
          classElement.isFinal = true;
          return;
        }

        // Otherwise, a sealed declaration is considered 'interface' if it has a
        // direct superclass which is 'interface'
        classElement.isInterface = true;
        return;
      }
    }

    if (interfaces.any(
          (type) => type.elementImpl.isBase || type.elementImpl.isFinal,
        ) ||
        mixins.any(
          (type) => type.elementImpl.isBase || type.elementImpl.isFinal,
        )) {
      // A sealed declaration is considered 'base' if it has a direct
      // superinterface which is 'base' or 'final'.
      classElement.isBase = true;
      return;
    }

    if (mixins.any((type) => type.elementImpl.isInterface)) {
      // A sealed declaration is considered 'final' if it has a
      // direct superclass which is 'interface' and it has a direct
      // superinterface which is 'base'.
      if (interfaces.any((type) => type.elementImpl.isBase)) {
        classElement.isFinal = true;
        return;
      }

      // Otherwise, a sealed declaration is considered 'interface' if it has a
      // direct superclass which is 'interface'
      classElement.isInterface = true;
      return;
    }
  }

  /// Return [overriddenType] with type parameters substituted to [element].
  /// Return `null`, in case of type parameters inconsistency.
  ///
  /// The overridden element must have the same number of generic type
  /// parameters as the target element, or none.
  ///
  /// If we do have generic type parameters on the element we're inferring,
  /// we must express its parameter and return types in terms of its own
  /// parameters. For example, given `m<T>(t)` overriding `m<S>(S s)` we
  /// should infer this as `m<T>(T t)`.
  FunctionTypeImpl? _toOverriddenFunctionType(
    ExecutableElementOrMember element,
    FunctionTypeImpl overriddenType,
  ) {
    var elementTypeParameters = element.asElement2.typeParameters2;
    var overriddenTypeParameters = overriddenType.typeParameters;

    if (elementTypeParameters.length != overriddenTypeParameters.length) {
      return null;
    }

    if (elementTypeParameters.isEmpty) {
      return overriddenType;
    }

    return replaceTypeParameters(
      overriddenType,
      // TODO(scheglov): remove this cast
      elementTypeParameters.cast(),
    );
  }

  static bool _isCovariantSetter(ExecutableFragmentImpl element) {
    if (element is PropertyAccessorFragmentImpl) {
      var parameters = element.parameters;
      return parameters.isNotEmpty && parameters[0].isCovariant;
    }
    return false;
  }

  static void _setFieldType(FieldFragmentImpl field, TypeImpl type) {
    field.type = type;
    // TODO(scheglov): We repeat this code.
    field.element.getter2?.returnType = type;
    field.element.getter2?.firstFragment.returnType = type;

    var setterElement = field.element.setter2;
    if (setterElement != null) {
      setterElement.returnType = VoidTypeImpl.instance;
      setterElement.firstFragment.returnType = VoidTypeImpl.instance;
      setterElement.valueFormalParameter.type = type;
      setterElement.valueFormalParameter.firstFragment.type = type;
    }
  }
}

/// A class of exception that is not used anywhere else.
class _CycleException implements Exception {}

extension on InterfaceFragmentImpl {
  bool get isBase {
    var self = this;
    if (self is ClassOrMixinFragmentImpl) return self.isBase;
    return false;
  }

  bool get isFinal {
    var self = this;
    if (self is ClassFragmentImpl) return self.isFinal;
    return false;
  }

  bool get isInterface {
    var self = this;
    if (self is ClassFragmentImpl) return self.isInterface;
    return false;
  }
}
