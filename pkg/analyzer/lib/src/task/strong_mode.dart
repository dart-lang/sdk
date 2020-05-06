// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';

/**
 * An object used to infer the type of instance fields and the return types of
 * instance methods within a single compilation unit.
 */
class InstanceMemberInferrer {
  final InheritanceManager3 inheritance;
  final Set<ClassElement> elementsBeingInferred = HashSet<ClassElement>();

  TypeSystemImpl typeSystem;
  bool isNonNullableByDefault;
  ClassElement currentClassElement;

  /**
   * Initialize a newly create inferrer.
   */
  InstanceMemberInferrer(this.inheritance);

  DartType get _dynamicType => DynamicTypeImpl.instance;

  /**
   * Infer type information for all of the instance members in the given
   * compilation [unit].
   */
  void inferCompilationUnit(CompilationUnitElement unit) {
    typeSystem = unit.library.typeSystem;
    isNonNullableByDefault = typeSystem.isNonNullableByDefault;
    _inferClasses(unit.mixins);
    _inferClasses(unit.types);
  }

  /**
   * Return `true` if the elements corresponding to the [elements] have the same
   * kind as the [element].
   */
  bool _allSameElementKind(
      ExecutableElement element, List<ExecutableElement> elements) {
    var elementKind = element.kind;
    for (int i = 0; i < elements.length; i++) {
      if (elements[i].kind != elementKind) {
        return false;
      }
    }
    return true;
  }

  /**
   * Compute the inferred type for the given property [accessor]. The returned
   * value is never `null`, but might be an error, and/or have the `null` type.
   */
  _FieldOverrideInferenceResult _computeFieldOverrideType(
      PropertyAccessorElement accessor) {
    String name = accessor.displayName;

    var overriddenGetters = inheritance.getOverridden2(
      currentClassElement,
      Name(accessor.library.source.uri, name),
    );

    List<ExecutableElement> overriddenSetters;
    if (overriddenGetters == null || !accessor.variable.isFinal) {
      overriddenSetters = inheritance.getOverridden2(
        currentClassElement,
        Name(accessor.library.source.uri, '$name='),
      );
    }

    // Choose overridden members from getters or/and setters.
    List<ExecutableElement> overriddenElements = <ExecutableElement>[];
    if (overriddenGetters == null && overriddenSetters == null) {
      overriddenElements = const <ExecutableElement>[];
    } else if (overriddenGetters == null && overriddenSetters != null) {
      overriddenElements = overriddenSetters;
    } else if (overriddenGetters != null && overriddenSetters == null) {
      overriddenElements = overriddenGetters;
    } else {
      overriddenElements = <ExecutableElement>[
        ...overriddenGetters,
        ...overriddenSetters,
      ];
    }

    bool isCovariant = false;
    DartType impliedType;
    for (ExecutableElement overriddenElement in overriddenElements) {
      var overriddenElementKind = overriddenElement.kind;
      if (overriddenElement == null) {
        return _FieldOverrideInferenceResult(false, null, true);
      }

      DartType type;
      if (overriddenElementKind == ElementKind.GETTER) {
        type = overriddenElement.returnType;
      } else if (overriddenElementKind == ElementKind.SETTER) {
        if (overriddenElement.parameters.length == 1) {
          ParameterElement parameter = overriddenElement.parameters[0];
          type = parameter.type;
          isCovariant = isCovariant || parameter.isCovariant;
        }
      } else {
        return _FieldOverrideInferenceResult(false, null, true);
      }

      if (impliedType == null) {
        impliedType = type;
      } else if (type != impliedType) {
        return _FieldOverrideInferenceResult(false, null, true);
      }
    }

    return _FieldOverrideInferenceResult(isCovariant, impliedType, false);
  }

  /**
   * Compute the best type for the [parameter] at the given [index] that must be
   * compatible with the types of the corresponding parameters of the given
   * [overriddenTypes].
   *
   * At the moment, this method will only return a type other than 'dynamic' if
   * the types of all of the parameters are the same. In the future we might
   * want to be smarter about it, such as by returning the least upper bound of
   * the parameter types.
   */
  DartType _computeParameterType(ParameterElement parameter, int index,
      List<FunctionType> overriddenTypes) {
    var typesMerger = _OverriddenTypesMerger(typeSystem);

    for (var overriddenType in overriddenTypes) {
      ParameterElement matchingParameter = _getCorrespondingParameter(
        parameter,
        index,
        overriddenType.parameters,
      );
      DartType type = matchingParameter?.type ?? _dynamicType;
      typesMerger.update(type);

      if (typesMerger.hasError) {
        if (parameter is ParameterElementImpl && parameter.linkedNode != null) {
          LazyAst.setTypeInferenceError(
            parameter.linkedNode,
            TopLevelInferenceErrorBuilder(
              kind: TopLevelInferenceErrorKind.overrideConflictParameterType,
            ),
          );
        }
        return _dynamicType;
      }
    }

    return typesMerger.result ?? _dynamicType;
  }

  /**
   * Compute the best return type for a method that must be compatible with the
   * return types of each of the given [overriddenReturnTypes].
   *
   * At the moment, this method will only return a type other than 'dynamic' if
   * the return types of all of the methods are the same. In the future we might
   * want to be smarter about it.
   */
  DartType _computeReturnType(Iterable<DartType> overriddenReturnTypes) {
    var typesMerger = _OverriddenTypesMerger(typeSystem);

    for (DartType type in overriddenReturnTypes) {
      type ??= _dynamicType;
      typesMerger.update(type);
      if (typesMerger.hasError) {
        return _dynamicType;
      }
    }

    return typesMerger.result ?? _dynamicType;
  }

  /**
   * Given a method, return the parameter in the method that corresponds to the
   * given [parameter]. If the parameter is positional, then
   * it appears at the given [index] in its enclosing element's list of
   * parameters.
   */
  ParameterElement _getCorrespondingParameter(ParameterElement parameter,
      int index, List<ParameterElement> methodParameters) {
    //
    // Find the corresponding parameter.
    //
    if (parameter.isNamed) {
      //
      // If we're looking for a named parameter, only a named parameter with
      // the same name will be matched.
      //
      return methodParameters.lastWhere(
          (ParameterElement methodParameter) =>
              methodParameter.isNamed && methodParameter.name == parameter.name,
          orElse: () => null);
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

  /**
   * If the given [element] represents a non-synthetic instance property
   * accessor for which no type was provided, infer its types.
   */
  void _inferAccessor(PropertyAccessorElement element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    if (element.kind == ElementKind.GETTER && !element.hasImplicitReturnType) {
      return;
    }

    _FieldOverrideInferenceResult typeResult =
        _computeFieldOverrideType(element);
    if (typeResult.isError == null || typeResult.type == null) {
      return;
    }

    if (element.kind == ElementKind.GETTER) {
      (element as ExecutableElementImpl).returnType = typeResult.type;
    } else if (element.kind == ElementKind.SETTER) {
      List<ParameterElement> parameters = element.parameters;
      if (parameters.isNotEmpty) {
        var parameter = parameters[0] as ParameterElementImpl;
        if (parameter.hasImplicitType) {
          parameter.type = typeResult.type;
        }
        parameter.inheritsCovariant = typeResult.isCovariant;
      }
    }
    (element.variable as FieldElementImpl).type = typeResult.type;
  }

  /**
   * Infer type information for all of the instance members in the given
   * [classElement].
   */
  void _inferClass(ClassElement classElement) {
    if (classElement is ClassElementImpl) {
      if (classElement.hasBeenInferred) {
        return;
      }
      if (!elementsBeingInferred.add(classElement)) {
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
        _inferType(classElement.supertype);
        classElement.mixins.forEach(_inferType);
        classElement.interfaces.forEach(_inferType);
        classElement.superclassConstraints.forEach(_inferType);
        //
        // Then infer the types for the members.
        //
        currentClassElement = classElement;
        for (FieldElement field in classElement.fields) {
          _inferField(field);
        }
        for (PropertyAccessorElement accessor in classElement.accessors) {
          _inferAccessor(accessor);
        }
        for (MethodElement method in classElement.methods) {
          _inferExecutable(method);
        }
        //
        // Infer initializing formal parameter types. This must happen after
        // field types are inferred.
        //
        classElement.constructors.forEach(_inferConstructorFieldFormals);
        classElement.hasBeenInferred = true;
      } finally {
        elementsBeingInferred.remove(classElement);
      }
    }
  }

  void _inferClasses(List<ClassElement> elements) {
    for (ClassElement element in elements) {
      try {
        _inferClass(element);
      } on _CycleException {
        // This is a short circuit return to prevent types that inherit from
        // types containing a circular reference from being inferred.
      }
    }
  }

  void _inferConstructorFieldFormals(ConstructorElement constructor) {
    for (ParameterElement parameter in constructor.parameters) {
      if (parameter.hasImplicitType &&
          parameter is FieldFormalParameterElementImpl) {
        FieldElement field = parameter.field;
        if (field != null) {
          parameter.type = field.type;
        }
      }
    }
  }

  /**
   * If the given [element] represents a non-synthetic instance method,
   * getter or setter, infer the return type and any parameter type(s) where
   * they were not provided.
   */
  void _inferExecutable(MethodElementImpl element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    // TODO(scheglov) If no implicit types, don't ask inherited.

    List<ExecutableElement> overriddenElements = inheritance.getOverridden2(
      currentClassElement,
      Name(element.library.source.uri, element.name),
    );
    if (overriddenElements == null ||
        !_allSameElementKind(element, overriddenElements)) {
      return;
    }

    List<FunctionType> overriddenTypes =
        _toOverriddenFunctionTypes(element, overriddenElements);
    if (overriddenTypes.isEmpty) {
      return;
    }

    //
    // Infer the return type.
    //
    if (element.hasImplicitReturnType && element.displayName != '[]=') {
      element.returnType =
          _computeReturnType(overriddenTypes.map((t) => t.returnType));
    }
    //
    // Infer the parameter types.
    //
    List<ParameterElement> parameters = element.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; ++i) {
      ParameterElement parameter = parameters[i];
      if (parameter is ParameterElementImpl) {
        _inferParameterCovariance(parameter, i, overriddenTypes);

        if (parameter.hasImplicitType) {
          parameter.type = _computeParameterType(parameter, i, overriddenTypes);
        }
      }
    }

    _resetOperatorEqualParameterTypeToDynamic(element, overriddenElements);
  }

  /**
   * If the given [field] represents a non-synthetic instance field for
   * which no type was provided, infer the type of the field.
   */
  void _inferField(FieldElementImpl field) {
    if (field.isSynthetic || field.isStatic) {
      return;
    }

    _FieldOverrideInferenceResult typeResult =
        _computeFieldOverrideType(field.getter);
    if (typeResult.isError) {
      if (field.linkedNode != null) {
        LazyAst.setTypeInferenceError(
          field.linkedNode,
          TopLevelInferenceErrorBuilder(
            kind: TopLevelInferenceErrorKind.overrideConflictFieldType,
          ),
        );
      }
      return;
    }

    if (field.hasImplicitType) {
      DartType newType = typeResult.type;

      if (newType == null) {
        var initializer = field.initializer;
        if (initializer != null) {
          newType = initializer.returnType;
        }
      }

      if (newType == null || newType.isBottom || newType.isDartCoreNull) {
        newType = _dynamicType;
      }

      field.type = newType;
    }

    if (field.setter != null) {
      var parameter = field.setter.parameters[0] as ParameterElementImpl;
      parameter.inheritsCovariant = typeResult.isCovariant;
    }
  }

  /**
   * If a parameter is covariant, any parameters that override it are too.
   */
  void _inferParameterCovariance(ParameterElementImpl parameter, int index,
      Iterable<FunctionType> overriddenTypes) {
    parameter.inheritsCovariant = overriddenTypes.any((f) {
      var param = _getCorrespondingParameter(parameter, index, f.parameters);
      return param != null && param.isCovariant;
    });
  }

  /**
   * Infer type information for all of the instance members in the given
   * interface [type].
   */
  void _inferType(InterfaceType type) {
    if (type != null) {
      ClassElement element = type.element;
      if (element != null) {
        _inferClass(element);
      }
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
    List<ExecutableElement> overriddenElements,
  ) {
    if (element.name != '==') return;

    var parameters = element.parameters;
    if (parameters.length != 1) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    ParameterElementImpl parameter = parameters[0];
    if (!parameter.hasImplicitType) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    for (MethodElement overridden in overriddenElements) {
      overridden = overridden.declaration;

      // Skip Object itself.
      var enclosingElement = overridden.enclosingElement;
      if (enclosingElement is ClassElement &&
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

    // Reset the type.
    if (!isNonNullableByDefault) {
      parameter.type = _dynamicType;
    }
    element.isOperatorEqualWithParameterTypeFromObject = true;
  }

  /**
   * Return the [FunctionType] of the [overriddenElement] that [element]
   * overrides. Return `null`, in case of type parameters inconsistency.
   *
   * The overridden element must have the same number of generic type
   * parameters as the target element, or none.
   *
   * If we do have generic type parameters on the element we're inferring,
   * we must express its parameter and return types in terms of its own
   * parameters. For example, given `m<T>(t)` overriding `m<S>(S s)` we
   * should infer this as `m<T>(T t)`.
   */
  FunctionType _toOverriddenFunctionType(
      ExecutableElement element, ExecutableElement overriddenElement) {
    var elementTypeParameters = element.typeParameters;
    var overriddenTypeParameters = overriddenElement.typeParameters;

    if (elementTypeParameters.length != overriddenTypeParameters.length) {
      return null;
    }

    var overriddenType = overriddenElement.type;
    if (elementTypeParameters.isEmpty) {
      return overriddenType;
    }

    return replaceTypeParameters(overriddenType, elementTypeParameters);
  }

  /**
   * Return [FunctionType]s of [overriddenElements] that override [element].
   * Return the empty list, in case of type parameters inconsistency.
   */
  List<FunctionType> _toOverriddenFunctionTypes(
      ExecutableElement element, List<ExecutableElement> overriddenElements) {
    var overriddenTypes = <FunctionType>[];
    for (ExecutableElement overriddenElement in overriddenElements) {
      FunctionType overriddenType =
          _toOverriddenFunctionType(element, overriddenElement);
      if (overriddenType == null) {
        return const <FunctionType>[];
      }
      overriddenTypes.add(overriddenType);
    }
    return overriddenTypes;
  }
}

/**
 * A class of exception that is not used anywhere else.
 */
class _CycleException implements Exception {}

/**
 * The result of field type inference.
 */
class _FieldOverrideInferenceResult {
  final bool isCovariant;
  final DartType type;
  final bool isError;

  _FieldOverrideInferenceResult(this.isCovariant, this.type, this.isError);
}

/// Helper for merging types from several overridden executables, according
/// to legacy or NNBD rules.
class _OverriddenTypesMerger {
  final TypeSystemImpl _typeSystem;

  bool hasError = false;

  DartType _legacyResult;

  DartType _notNormalized;
  DartType _currentMerge;

  _OverriddenTypesMerger(this._typeSystem);

  DartType get result {
    if (_typeSystem.isNonNullableByDefault) {
      return _currentMerge ?? _notNormalized;
    } else {
      return _legacyResult;
    }
  }

  void update(DartType type) {
    if (hasError) {
      // Stop updating it.
    } else if (_typeSystem.isNonNullableByDefault) {
      if (_currentMerge == null) {
        if (_notNormalized == null) {
          _notNormalized = type;
          return;
        } else {
          _currentMerge = _typeSystem.normalize(_notNormalized);
        }
      }
      var normType = _typeSystem.normalize(type);
      try {
        _currentMerge = _typeSystem.topMerge(_currentMerge, normType);
      } catch (_) {
        hasError = true;
      }
    } else {
      if (_legacyResult == null) {
        _legacyResult = type;
      } else if (_legacyResult != type) {
        hasError = true;
      }
    }
  }
}
