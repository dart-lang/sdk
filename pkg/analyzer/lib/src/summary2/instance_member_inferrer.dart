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
import 'package:collection/collection.dart';

/// An object used to infer the type of instance fields and the return types of
/// instance methods within a single compilation unit.
///
/// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md
class InstanceMemberInferrer {
  final InheritanceManager3 inheritance;
  final Set<InterfaceElementImpl> interfacesToInfer = {};

  late InterfaceElementImpl currentInterfaceElement;

  /// Initialize a newly create inferrer.
  InstanceMemberInferrer(this.inheritance);

  TypeSystemImpl get typeSystem {
    return currentInterfaceElement.library.typeSystem;
  }

  void perform(List<InterfaceElementImpl> elements) {
    interfacesToInfer.addAll(elements);
    for (var element in elements) {
      _inferClass(element);
    }
  }

  /// Return `true` if the elements corresponding to the [elements] have the
  /// same kind as the [element].
  bool _allSameElementKind(
    ExecutableElementImpl element,
    List<InternalExecutableElement> elements,
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
  InternalFormalParameterElement? _getCorrespondingParameter(
    FormalParameterElementImpl parameter,
    int index,
    List<InternalFormalParameterElement> methodParameters,
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
            methodParameter.isNamed && methodParameter.name == parameter.name,
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

  /// If the given [getter] represents a non-synthetic instance getter for
  /// which no type was provided, infer its types.
  ///
  /// If the given [setter] represents a non-synthetic instance getter for
  /// which no type was provided, infer its types.
  ///
  /// If the given [field] represents a non-synthetic instance field for
  /// which no type was provided, infer the type of the field.
  void _inferAccessorOrField({
    GetterElementImpl? getter,
    SetterElementImpl? setter,
    FieldElementImpl? field,
  }) {
    Uri elementLibraryUri;
    String elementName;

    if (getter != null) {
      if (getter.isSynthetic || getter.isStatic) {
        return;
      }
      elementLibraryUri = getter.library.uri;
      elementName = getter.displayName;
    } else if (setter != null) {
      if (setter.isSynthetic || setter.isStatic) {
        return;
      }
      elementLibraryUri = setter.library.uri;
      elementName = setter.displayName;
    } else if (field != null) {
      if (field.isSynthetic || field.isStatic) {
        return;
      }
      elementLibraryUri = field.library.uri;
      elementName = field.name ?? '';
    } else {
      throw UnimplementedError();
    }

    var getterName = Name(elementLibraryUri, elementName);
    var overriddenGetters = inheritance.getOverridden(
      currentInterfaceElement,
      getterName,
    );
    if (overriddenGetters != null) {
      overriddenGetters = overriddenGetters
          .whereType<InternalGetterElement>()
          .toList();
    } else {
      overriddenGetters = const [];
    }

    var setterName = Name(elementLibraryUri, '$elementName=');
    var overriddenSetters = inheritance.getOverridden(
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

    if (getter != null) {
      if (!getter.hasImplicitReturnType) {
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
        getter.returnType = returnType;
        var fieldElement = getter.variable as FieldElementImpl;
        fieldElement.type = returnType;
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        var returnType = combinedSetterType();
        getter.returnType = returnType;
        var fieldElement = getter.variable as FieldElementImpl;
        fieldElement.type = returnType;
        return;
      }

      return;
    }

    if (setter != null) {
      var valueFormalParameter = setter.valueFormalParameter;

      if (overriddenSetters.any((s) => _isCovariantSetter(s.baseElement))) {
        valueFormalParameter.inheritsCovariant = true;
      }

      if (!valueFormalParameter.hasImplicitType) {
        return;
      }

      void setSetterValueType(TypeImpl valueType) {
        valueFormalParameter.type = valueType;
        var field = setter.variable as FieldElementImpl;
        if (field.getter == null) {
          field.type = valueType;
        }
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty && overriddenSetters.isEmpty) {
        var valueType = combinedGetterType();
        setSetterValueType(valueType);
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
        var valueType = combinedSetterType();
        setSetterValueType(valueType);
        return;
      }

      return;
    }

    if (field != null) {
      var setter = field.setter;
      if (setter != null) {
        if (overriddenSetters.any((s) => _isCovariantSetter(s.baseElement))) {
          setter.valueFormalParameter.inheritsCovariant = true;
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
        field.type = combinedGetterType();
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        field.type = combinedSetterType();
        return;
      }

      if (overriddenGetters.isNotEmpty && overriddenSetters.isNotEmpty) {
        // The type of a final field which overrides/implements both a setter
        // and a getter is inferred to be the return type of the combined
        // member signature of said getter in the direct superinterfaces.
        if (field.isFinal) {
          field.type = combinedGetterType();
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
            field.type = getterType;
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
  /// [element].
  void _inferClass(InterfaceElementImpl element) {
    if (!interfacesToInfer.remove(element)) {
      return;
    }

    _setInducedModifier(element);

    //
    // Ensure that all of instance members in the supertypes have had types
    // inferred for them.
    //
    _inferType(element.supertype);
    element.mixins.forEach(_inferType);
    element.interfaces.forEach(_inferType);

    //
    // Then infer the types for the members.
    //
    currentInterfaceElement = element;
    for (var field in element.fields) {
      _inferAccessorOrField(field: field);
    }
    for (var getter in element.getters) {
      _inferAccessorOrField(getter: getter);
    }
    for (var setter in element.setters) {
      _inferAccessorOrField(setter: setter);
    }
    for (var method in element.methods) {
      _inferExecutable(method);
    }

    //
    // Infer initializing formal parameter types. This must happen after
    // field types are inferred.
    //
    for (var constructor in element.constructors) {
      _inferConstructor(constructor);
    }
  }

  void _inferConstructor(ConstructorElementImpl constructor) {
    for (var formalParameter in constructor.formalParameters) {
      if (formalParameter.hasImplicitType) {
        if (formalParameter is FieldFormalParameterElementImpl) {
          var field = formalParameter.field;
          if (field != null) {
            formalParameter.type = field.type;
          }
        } else if (formalParameter is SuperFormalParameterElementImpl) {
          var superParameter = formalParameter.superConstructorParameter;
          if (superParameter != null) {
            formalParameter.type = superParameter.type;
          } else {
            formalParameter.type = DynamicTypeImpl.instance;
          }
        }
      }
    }

    var classElement = constructor.enclosingElement;
    if (classElement is ClassElementImpl && classElement.isMixinApplication) {
      _inferMixinApplicationConstructor(classElement, constructor);
    }
  }

  /// If the given [element] represents a non-synthetic instance method,
  /// getter or setter, infer the return type and any parameter type(s) where
  /// they were not provided.
  void _inferExecutable(MethodElementImpl element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    var name = Name.forElement(element);
    if (name == null) {
      return;
    }

    var overriddenElements = inheritance.getOverridden(
      currentInterfaceElement,
      name,
    );
    if (overriddenElements == null ||
        !_allSameElementKind(element, overriddenElements)) {
      return;
    }

    FunctionTypeImpl? combinedSignatureType;
    var hasImplicitType =
        element.hasImplicitReturnType ||
        element.formalParameters.any((e) => e.hasImplicitType);
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
                  var className = candidate.enclosingElement!.name ?? '';
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
      } else {
        element.returnType = DynamicTypeImpl.instance;
      }
    }

    //
    // Infer the parameter types.
    //
    var formalParameters = element.formalParameters;
    for (var index = 0; index < formalParameters.length; index++) {
      var formalParameter = formalParameters[index];
      _inferParameterCovariance(formalParameter, index, overriddenElements);

      if (formalParameter.hasImplicitType) {
        _inferParameterType(formalParameter, index, combinedSignatureType);
      }
    }

    _resetOperatorEqualParameterTypeToDynamic(element, overriddenElements);
  }

  void _inferMixinApplicationConstructor(
    ClassElementImpl classElement,
    ConstructorElementImpl constructor,
  ) {
    var superType = classElement.supertype;
    if (superType != null) {
      var index = classElement.constructors.indexOf(constructor);
      var superConstructors = superType.element.constructors
          .where((element) => element.isAccessibleIn(classElement.library))
          .toList();
      if (index < superConstructors.length) {
        var baseConstructor = superConstructors[index];
        var substitution = Substitution.fromInterfaceType(superType);
        forCorrespondingPairs<
          FormalParameterElementImpl,
          FormalParameterElementImpl
        >(
          constructor.formalParameters.cast(),
          baseConstructor.formalParameters.cast(),
          (parameter, baseParameter) {
            var type = substitution.substituteType(baseParameter.type);
            parameter.type = type;
          },
        );
        // Update arguments of `SuperConstructorInvocation` to have the types
        // (which we have just set) of the corresponding formal parameters.
        // MixinApp(x, y) : super(x, y);
        var initializers = constructor.constantInitializers;
        var initializer = initializers.single as SuperConstructorInvocation;
        forCorrespondingPairs<FormalParameterElementImpl, Expression>(
          constructor.formalParameters.cast(),
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
    FormalParameterElementImpl parameter,
    int index,
    Iterable<InternalExecutableElement> overridden,
  ) {
    parameter.inheritsCovariant = overridden.any((f) {
      var param = _getCorrespondingParameter(
        parameter,
        index,
        f.formalParameters,
      );
      return param != null && param.isCovariant;
    });
  }

  /// Set the type for the [parameter] at the given [index] from the given
  /// [combinedSignatureType], which might be `null` if there is no valid
  /// combined signature for signatures from direct superinterfaces.
  void _inferParameterType(
    FormalParameterElementImpl parameter,
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
      var element = type.element;
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
    MethodElementImpl element,
    List<InternalExecutableElement> overriddenElements,
  ) {
    if (element.name != '==') return;

    var formalParameters = element.formalParameters;
    if (formalParameters.length != 1) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    var formalParameter = formalParameters[0];
    if (!formalParameter.hasImplicitType) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    for (var overridden in overriddenElements) {
      overridden = overridden.baseElement;

      // Skip Object itself.
      var enclosingElement = overridden.enclosingElement;
      if (enclosingElement is ClassElementImpl &&
          enclosingElement.isDartCoreObject) {
        continue;
      }

      // Keep the type if it is not directly from Object.
      if (overridden is MethodElementImpl &&
          !overridden.isOperatorEqualWithParameterTypeFromObject) {
        element.isOperatorEqualWithParameterTypeFromObject = false;
        return;
      }
    }

    element.isOperatorEqualWithParameterTypeFromObject = true;
  }

  /// Find and mark the induced modifier of an element, if the [classElement] is
  /// 'sealed'.
  void _setInducedModifier(InterfaceElementImpl classElement) {
    // Only sealed elements propagate induced modifiers.
    if (classElement is! ClassElementImpl || !classElement.isSealed) {
      return;
    }

    var supertype = classElement.supertype;
    var interfaces = classElement.interfaces;
    var mixins = classElement.mixins;

    if (mixins.any((type) => type.element.isFinal)) {
      // A sealed declaration is considered 'final' if it has a direct
      // superclass which is 'final'.
      classElement.isFinal = true;
      return;
    }

    if (supertype != null) {
      if (supertype.element.isFinal) {
        // A sealed declaration is considered 'final' if it has a direct
        // superclass which is 'final'.
        classElement.isFinal = true;
        return;
      }
      if (supertype.element.isBase) {
        // A sealed declaration is considered 'final' if it has a
        // direct superclass which is 'interface' and it has a direct
        // superinterface which is 'base'.
        if (mixins.any((type) => type.element.isInterface)) {
          classElement.isFinal = true;
          return;
        }

        // Otherwise, a sealed declaration is considered 'base' if it has a
        // direct superinterface which is 'base' or 'final'.
        classElement.isBase = true;
        return;
      }
      if (supertype.element.isInterface) {
        // A sealed declaration is considered 'final' if it has a
        // direct superclass which is 'interface' and it has a direct
        // superinterface which is 'base'.
        if (interfaces.any((type) => type.element.isBase) ||
            mixins.any((type) => type.element.isBase)) {
          classElement.isFinal = true;
          return;
        }

        // Otherwise, a sealed declaration is considered 'interface' if it has a
        // direct superclass which is 'interface'
        classElement.isInterface = true;
        return;
      }
    }

    if (interfaces.any((type) => type.element.isBase || type.element.isFinal) ||
        mixins.any((type) => type.element.isBase || type.element.isFinal)) {
      // A sealed declaration is considered 'base' if it has a direct
      // superinterface which is 'base' or 'final'.
      classElement.isBase = true;
      return;
    }

    if (mixins.any((type) => type.element.isInterface)) {
      // A sealed declaration is considered 'final' if it has a
      // direct superclass which is 'interface' and it has a direct
      // superinterface which is 'base'.
      if (interfaces.any((type) => type.element.isBase)) {
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
    MethodElementImpl element,
    FunctionTypeImpl overriddenType,
  ) {
    var elementTypeParameters = element.typeParameters;
    var overriddenTypeParameters = overriddenType.typeParameters;

    if (elementTypeParameters.length != overriddenTypeParameters.length) {
      return null;
    }

    if (elementTypeParameters.isEmpty) {
      return overriddenType;
    }

    return replaceTypeParameters(overriddenType, elementTypeParameters);
  }

  static bool _isCovariantSetter(ExecutableElementImpl element) {
    if (element is PropertyAccessorElementImpl) {
      var parameters = element.formalParameters;
      return parameters.isNotEmpty && parameters[0].isCovariant;
    }
    return false;
  }
}

extension on InterfaceElementImpl {
  bool get isBase {
    switch (this) {
      case ClassElementImpl self:
        return self.isBase;
      case MixinElementImpl self:
        return self.isBase;
      default:
        return false;
    }
  }

  bool get isFinal {
    switch (this) {
      case ClassElementImpl self:
        return self.isFinal;
      default:
        return false;
    }
  }

  bool get isInterface {
    switch (this) {
      case ClassElementImpl self:
        return self.isInterface;
      default:
        return false;
    }
  }
}
