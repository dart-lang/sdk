// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart'
    show FieldElementForLink_ClassField, ParameterElementForLink;

/**
 * Sets the type of the field. The types in implicit accessors are updated
 * implicitly, and the types of explicit accessors should be updated separately.
 */
void setFieldType(VariableElement field, DartType newType) {
  (field as VariableElementImpl).type = newType;
}

/**
 * A function that returns `true` if the given [element] passes the filter.
 */
typedef bool VariableFilter(VariableElement element);

/**
 * An object used to infer the type of instance fields and the return types of
 * instance methods within a single compilation unit.
 */
class InstanceMemberInferrer {
  final TypeProvider typeProvider;
  final InheritanceManager2 inheritance;
  final Set<ClassElement> elementsBeingInferred = new HashSet<ClassElement>();

  InterfaceType interfaceType;

  /**
   * Initialize a newly create inferrer.
   */
  InstanceMemberInferrer(this.typeProvider, this.inheritance);

  /**
   * Infer type information for all of the instance members in the given
   * compilation [unit].
   */
  void inferCompilationUnit(CompilationUnitElement unit) {
    _inferClasses(unit.mixins);
    _inferClasses(unit.types);
  }

  /**
   * Return `true` if the elements corresponding to the [types] have the same
   * kind as the [element].
   */
  bool _allSameElementKind(
      ExecutableElement element, List<FunctionType> types) {
    var elementKind = element.kind;
    for (int i = 0; i < types.length; i++) {
      if (types[i].element.kind != elementKind) {
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

    var overriddenGetters = inheritance.getOverridden(
      interfaceType,
      new Name(accessor.library.source.uri, name),
    );

    List<FunctionType> overriddenSetters;
    if (overriddenGetters == null || !accessor.variable.isFinal) {
      overriddenSetters = inheritance.getOverridden(
        interfaceType,
        new Name(accessor.library.source.uri, '$name='),
      );
    }

    // Choose overridden types from getters or/and setters.
    List<FunctionType> overriddenTypes = <FunctionType>[];
    if (overriddenGetters == null && overriddenSetters == null) {
      overriddenTypes = const <FunctionType>[];
    } else if (overriddenGetters == null && overriddenSetters != null) {
      overriddenTypes = overriddenSetters;
    } else if (overriddenGetters != null && overriddenSetters == null) {
      overriddenTypes = overriddenGetters;
    } else {
      overriddenTypes = <FunctionType>[]
        ..addAll(overriddenGetters)
        ..addAll(overriddenSetters);
    }

    bool isCovariant = false;
    DartType impliedType;
    for (FunctionType overriddenType in overriddenTypes) {
      var overriddenElementKind = overriddenType.element.kind;
      if (overriddenType == null) {
        return new _FieldOverrideInferenceResult(false, null, true);
      }

      DartType type;
      if (overriddenElementKind == ElementKind.GETTER) {
        type = overriddenType.returnType;
      } else if (overriddenElementKind == ElementKind.SETTER) {
        if (overriddenType.parameters.length == 1) {
          ParameterElement parameter = overriddenType.parameters[0];
          type = parameter.type;
          isCovariant = isCovariant || parameter.isCovariant;
        }
      } else {
        return new _FieldOverrideInferenceResult(false, null, true);
      }

      if (impliedType == null) {
        impliedType = type;
      } else if (type != impliedType) {
        return new _FieldOverrideInferenceResult(false, null, true);
      }
    }

    return new _FieldOverrideInferenceResult(isCovariant, impliedType, false);
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
    DartType parameterType = null;
    int length = overriddenTypes.length;
    for (int i = 0; i < length; i++) {
      ParameterElement matchingParameter = _getCorrespondingParameter(
          parameter, index, overriddenTypes[i].parameters);
      DartType type = matchingParameter?.type ?? typeProvider.dynamicType;
      if (parameterType == null) {
        if (type is FunctionType &&
            type.element is! TypeDefiningElement &&
            type.element.enclosingElement is! TypeDefiningElement) {
          // The resulting parameter's type element has an `enclosingElement` of
          // the overridden parameter. Change it to the overriding parameter.
          parameterType = new FunctionTypeImpl.fresh(type, force: true);
          (parameterType.element as ElementImpl).enclosingElement = parameter;
          // TODO(mfairhurst) handle cases where non-functions contain functions
          // See test_inferredType_parameter_genericFunctionType_asTypeArgument
        } else {
          parameterType = type;
        }
      } else if (parameterType != type) {
        if (parameter is ParameterElementForLink) {
          parameter.setInferenceError(new TopLevelInferenceErrorBuilder(
              kind: TopLevelInferenceErrorKind.overrideConflictParameterType));
        }
        return typeProvider.dynamicType;
      }
    }
    return parameterType ?? typeProvider.dynamicType;
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
    DartType returnType = null;
    for (DartType type in overriddenReturnTypes) {
      if (type == null) {
        type = typeProvider.dynamicType;
      }
      if (returnType == null) {
        returnType = type;
      } else if (returnType != type) {
        return typeProvider.dynamicType;
      }
    }
    return returnType ?? typeProvider.dynamicType;
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
    setFieldType(element.variable, typeResult.type);
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
        throw new _CycleException();
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
        this.interfaceType = classElement.type;
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
  void _inferExecutable(ExecutableElement element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    // TODO(scheglov) If no implicit types, don't ask inherited.

    List<FunctionType> overriddenTypes = inheritance.getOverridden(
      interfaceType,
      new Name(element.library.source.uri, element.name),
    );
    if (overriddenTypes == null ||
        !_allSameElementKind(element, overriddenTypes)) {
      return;
    }
    overriddenTypes = _toOverriddenFunctionTypes(element, overriddenTypes);
    if (overriddenTypes.isEmpty) {
      return;
    }

    //
    // Infer the return type.
    //
    if (element.hasImplicitReturnType && element.displayName != '[]=') {
      (element as ExecutableElementImpl).returnType =
          _computeReturnType(overriddenTypes.map((t) => t.returnType));
      if (element is PropertyAccessorElement) {
        _updateSyntheticVariableType(element);
      }
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
          if (element is PropertyAccessorElement) {
            _updateSyntheticVariableType(element);
          }
        }
      }
    }
  }

  /**
   * If the given [field] represents a non-synthetic instance field for
   * which no type was provided, infer the type of the field.
   */
  void _inferField(FieldElement field) {
    if (field.isSynthetic || field.isStatic) {
      return;
    }

    _FieldOverrideInferenceResult typeResult =
        _computeFieldOverrideType(field.getter);
    if (typeResult.isError) {
      if (field is FieldElementForLink_ClassField) {
        field.setInferenceError(new TopLevelInferenceErrorBuilder(
            kind: TopLevelInferenceErrorKind.overrideConflictFieldType));
      }
      return;
    }

    if (field.hasImplicitType) {
      DartType newType = typeResult.type;
      if (newType == null && field.initializer != null) {
        newType = field.initializer.returnType;
      }

      if (newType == null || newType.isBottom || newType.isDartCoreNull) {
        newType = typeProvider.dynamicType;
      }

      setFieldType(field, newType);
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

  /**
   * If the [element] has formal type parameters, then the [overriddenType]
   * must have it as well, but they are different.  Replace type parameters
   * of the [overriddenType] with type formals of the [element].
   *
   * Return `null`, in case of type parameters inconsistency.
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
      ExecutableElement element, FunctionType overriddenType) {
    List<DartType> typeFormals =
        TypeParameterTypeImpl.getTypes(element.type.typeFormals);
    if (overriddenType.typeFormals.isNotEmpty) {
      if (overriddenType.typeFormals.length != typeFormals.length) {
        return null;
      }
      overriddenType = overriddenType.instantiate(typeFormals);
    }
    return overriddenType;
  }

  /**
   * Return [overriddenTypes] that override [element].
   * Return the empty list, in case of type parameters inconsistency.
   */
  List<FunctionType> _toOverriddenFunctionTypes(
      ExecutableElement element, List<FunctionType> overriddenTypes) {
    var result = <FunctionType>[];
    for (var overriddenType in overriddenTypes) {
      overriddenType = _toOverriddenFunctionType(element, overriddenType);
      if (overriddenType == null) {
        return const <FunctionType>[];
      }
      result.add(overriddenType);
    }
    return result;
  }

  /**
   * If the given [element] is a non-synthetic getter or setter, update its
   * synthetic variable's type to match the getter's return type, or if no
   * corresponding getter exists, use the setter's parameter type.
   *
   * In general, the type of the synthetic variable should not be used, because
   * getters and setters are independent methods. But this logic matches what
   * `TypeResolverVisitor.visitMethodDeclaration` would fill in there.
   */
  void _updateSyntheticVariableType(PropertyAccessorElement element) {
    assert(!element.isSynthetic);
    PropertyAccessorElement getter = element;
    if (element.isSetter) {
      // See if we can find any getter.
      getter = element.correspondingGetter;
    }
    DartType newType;
    if (getter != null) {
      newType = getter.returnType;
    } else if (element.isSetter && element.parameters.isNotEmpty) {
      newType = element.parameters[0].type;
    }
    if (newType != null) {
      (element.variable as VariableElementImpl).type = newType;
    }
  }
}

/**
 * A visitor that will gather all of the variables referenced within a given
 * AST structure. The collection can be restricted to contain only those
 * variables that pass a specified filter.
 */
class VariableGatherer extends RecursiveAstVisitor {
  /**
   * The filter used to limit which variables are gathered, or `null` if no
   * filtering is to be performed.
   */
  final VariableFilter filter;

  /**
   * The variables that were found.
   */
  final Set<VariableElement> results = new HashSet<VariableElement>();

  /**
   * Initialize a newly created gatherer to gather all of the variables that
   * pass the given [filter] (or all variables if no filter is provided).
   */
  VariableGatherer([this.filter = null]);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      Element nonAccessor(Element element) {
        if (element is PropertyAccessorElement && element.isSynthetic) {
          return element.variable;
        }
        return element;
      }

      Element element = nonAccessor(node.staticElement);
      if (element is VariableElement && (filter == null || filter(element))) {
        results.add(element);
      }
    }
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
