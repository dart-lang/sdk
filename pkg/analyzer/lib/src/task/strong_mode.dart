// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.strong_mode;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, InheritanceManager;
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * Set the type of the sole parameter of the given [element] to the given [type].
 */
void setParameterType(PropertyAccessorElement element, DartType type) {
  if (element is PropertyAccessorElementImpl) {
    ParameterElement parameter = _getParameter(element);
    if (parameter is ParameterElementImpl) {
      //
      // Update the type of the parameter.
      //
      parameter.type = type;
      //
      // Update the type of the setter to reflect the new parameter type.
      //
      FunctionType functionType = element.type;
      if (functionType is FunctionTypeImpl) {
        element.type =
            new FunctionTypeImpl(element, functionType.prunedTypedefs)
              ..typeArguments = functionType.typeArguments;
      } else {
        assert(false);
      }
    } else {
      assert(false);
    }
  } else {
    throw new StateError('element is an instance of ${element.runtimeType}');
    assert(false);
  }
}

/**
 * Set the return type of the given [element] to the given [type].
 */
void setReturnType(ExecutableElement element, DartType type) {
  if (element is ExecutableElementImpl) {
    //
    // Update the return type of the element, which is stored in two places:
    // directly in the element and indirectly in the type of the element.
    //
    element.returnType = type;
    FunctionType functionType = element.type;
    if (functionType is FunctionTypeImpl) {
      element.type = new FunctionTypeImpl(element, functionType.prunedTypedefs)
        ..typeArguments = functionType.typeArguments;
    } else {
      assert(false);
    }
  } else {
    assert(false);
  }
}

/**
 * Return the element for the single parameter of the given [setter], or `null`
 * if the executable element is not a setter or does not have a single
 * parameter.
 */
ParameterElement _getParameter(ExecutableElement setter) {
  if (setter is PropertyAccessorElement && setter.isSetter) {
    List<ParameterElement> parameters = setter.parameters;
    if (parameters.length == 1) {
      return parameters[0];
    }
  }
  return null;
}

/**
 * A function that returns `true` if the given [variable] passes the filter.
 */
typedef bool VariableFilter(VariableElement element);

/**
 * An object used to infer the type of instance fields and the return types of
 * instance methods within a single compilation unit.
 */
class InstanceMemberInferrer {
  /**
   * The type provider used to look up types.
   */
  final TypeProvider typeProvider;

  /**
   * The type system used to compute the least upper bound of types.
   */
  TypeSystem typeSystem;

  /**
   * The inheritance manager used to find overridden method.
   */
  InheritanceManager inheritanceManager;

  /**
   * The classes that have been visited while attempting to infer the types of
   * instance members of some base class.
   */
  HashSet<ClassElementImpl> elementsBeingInferred =
      new HashSet<ClassElementImpl>();

  /**
   * Initialize a newly create inferrer.
   */
  InstanceMemberInferrer(this.typeProvider, {TypeSystem typeSystem})
      : typeSystem = (typeSystem != null) ? typeSystem : new TypeSystemImpl();

  /**
   * Infer type information for all of the instance members in the given
   * compilation [unit].
   */
  void inferCompilationUnit(CompilationUnitElement unit) {
    inheritanceManager = new InheritanceManager(unit.library);
    unit.types.forEach((ClassElement classElement) {
      try {
        _inferClass(classElement);
      } on _CycleException {
        // This is a short circuit return to prevent types that inherit from
        // types containing a circular reference from being inferred.
      }
    });
  }

  /**
   * Compute the best type for the [parameter] at the given [index] that must be
   * compatible with the types of the corresponding parameters of the given
   * [overriddenMethods].
   *
   * At the moment, this method will only return a type other than 'dynamic' if
   * the types of all of the parameters are the same. In the future we might
   * want to be smarter about it, such as by returning the least upper bound of
   * the parameter types.
   */
  DartType _computeParameterType(ParameterElement parameter, int index,
      List<ExecutableElement> overriddenMethods) {
    DartType parameterType = null;
    int length = overriddenMethods.length;
    for (int i = 0; i < length; i++) {
      DartType type = _getTypeOfCorrespondingParameter(
          parameter, index, overriddenMethods[i]);
      if (parameterType == null) {
        parameterType = type;
      } else if (parameterType != type) {
        return typeProvider.dynamicType;
      }
    }
    return parameterType == null ? typeProvider.dynamicType : parameterType;
  }

  /**
   * Compute the best return type for a method that must be compatible with the
   * return types of each of the given [overriddenMethods].
   *
   * At the moment, this method will only return a type other than 'dynamic' if
   * the return types of all of the methods are the same. In the future we might
   * want to be smarter about it.
   */
  DartType _computeReturnType(List<ExecutableElement> overriddenMethods) {
    DartType returnType = null;
    int length = overriddenMethods.length;
    for (int i = 0; i < length; i++) {
      DartType type = _getReturnType(overriddenMethods[i]);
      if (returnType == null) {
        returnType = type;
      } else if (returnType != type) {
        return typeProvider.dynamicType;
      }
    }
    return returnType == null ? typeProvider.dynamicType : returnType;
  }

  DartType _getReturnType(ExecutableElement element) {
    DartType returnType = element.returnType;
    if (returnType == null) {
      return typeProvider.dynamicType;
    }
    return returnType;
  }

  /**
   * Given a [method], return the type of the parameter in the method that
   * corresponds to the given [parameter]. If the parameter is positional, then
   * it appears at the given [index] in its enclosing element's list of
   * parameters.
   */
  DartType _getTypeOfCorrespondingParameter(
      ParameterElement parameter, int index, ExecutableElement method) {
    //
    // Find the corresponding parameter.
    //
    List<ParameterElement> methodParameters = method.parameters;
    ParameterElement matchingParameter = null;
    if (parameter.parameterKind == ParameterKind.NAMED) {
      //
      // If we're looking for a named parameter, only a named parameter with
      // the same name will be matched.
      //
      matchingParameter = methodParameters.lastWhere(
          (ParameterElement methodParameter) =>
              methodParameter.parameterKind == ParameterKind.NAMED &&
                  methodParameter.name == parameter.name,
          orElse: () => null);
    } else {
      //
      // If we're looking for a positional parameter we ignore the difference
      // between required and optional parameters.
      //
      if (index < methodParameters.length) {
        matchingParameter = methodParameters[index];
        if (matchingParameter.parameterKind == ParameterKind.NAMED) {
          matchingParameter = null;
        }
      }
    }
    //
    // Then return the type of the parameter.
    //
    return matchingParameter == null
        ? typeProvider.dynamicType
        : matchingParameter.type;
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
        //
        // Then infer the types for the members.
        //
        classElement.fields.forEach(_inferField);
        classElement.accessors.forEach(_inferExecutable);
        classElement.methods.forEach(_inferExecutable);
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

  /**
   * If the given [fieldElement] represents a non-synthetic instance field for
   * which no type was provided, infer the type of the field.
   */
  void _inferField(FieldElement fieldElement) {
    if (!fieldElement.isSynthetic &&
        !fieldElement.isStatic &&
        fieldElement.hasImplicitType) {
      //
      // First look for overridden getters with the same name as the field.
      //
      List<ExecutableElement> overriddenGetters = inheritanceManager
          .lookupOverrides(fieldElement.enclosingElement, fieldElement.name);
      DartType newType = null;
      if (overriddenGetters.isNotEmpty && _onlyGetters(overriddenGetters)) {
        newType = _computeReturnType(overriddenGetters);
        List<ExecutableElement> overriddenSetters = inheritanceManager
            .lookupOverrides(
                fieldElement.enclosingElement, fieldElement.name + '=');
        if (!_isCompatible(newType, overriddenSetters)) {
          newType = null;
        }
      }
      //
      // If there is no overridden getter or if the overridden getter's type is
      // dynamic, then we can infer the type from the initialization expression
      // without breaking subtype rules. We could potentially infer a consistent
      // return type even if the overridden getter's type was not dynamic, but
      // choose not to for simplicity. The field is required to be final to
      // prevent choosing a type that is inconsistent with assignments we cannot
      // analyze.
      //
      if (newType == null || newType.isDynamic) {
        if (fieldElement.initializer != null &&
            (fieldElement.isFinal || overriddenGetters.isEmpty)) {
          newType = fieldElement.initializer.returnType;
        }
      }
      if (newType == null || newType.isBottom) {
        newType = typeProvider.dynamicType;
      }
      (fieldElement as FieldElementImpl).type = newType;
      setReturnType(fieldElement.getter, newType);
      if (!fieldElement.isFinal && !fieldElement.isConst) {
        setParameterType(fieldElement.setter, newType);
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
    List<ExecutableElement> overriddenMethods = null;
    //
    // Infer the return type.
    //
    if (element.hasImplicitReturnType) {
      overriddenMethods = inheritanceManager.lookupOverrides(
          element.enclosingElement, element.name);
      if (overriddenMethods.isEmpty ||
          !_allSameElementKind(element, overriddenMethods)) {
        return;
      }
      setReturnType(element, _computeReturnType(overriddenMethods));
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
      if (parameter is ParameterElementImpl && parameter.hasImplicitType) {
        if (overriddenMethods == null) {
          overriddenMethods = inheritanceManager.lookupOverrides(
              element.enclosingElement, element.name);
        }
        if (overriddenMethods.isEmpty ||
            !_allSameElementKind(element, overriddenMethods)) {
          return;
        }
        parameter.type = _computeParameterType(parameter, i, overriddenMethods);
        if (element is PropertyAccessorElement) {
          _updateSyntheticVariableType(element);
        }
      }
    }
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
   * Return `true` if the given [type] is compatible with the argument types of
   * all of the given [setters].
   */
  bool _isCompatible(DartType type, List<ExecutableElement> setters) {
    for (ExecutableElement setter in setters) {
      ParameterElement parameter = _getParameter(setter);
      if (parameter != null && !typeSystem.isSubtypeOf(parameter.type, type)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if the list of [elements] contains only getters.
   */
  bool _onlyGetters(List<ExecutableElement> elements) {
    for (ExecutableElement element in elements) {
      if (!(element is PropertyAccessorElement && element.isGetter)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if the list of [elements] contains only methods.
   */
  bool _allSameElementKind(
      ExecutableElement element, List<ExecutableElement> elements) {
    return elements.every((e) => e.kind == element.kind);
  }

  void _inferConstructorFieldFormals(ConstructorElement element) {
    for (ParameterElement p in element.parameters) {
      if (p is FieldFormalParameterElement) {
        _inferFieldFormalParameter(p);
      }
    }
  }

  void _inferFieldFormalParameter(FieldFormalParameterElement element) {
    FieldElement field = element.field;
    if (field != null && element.hasImplicitType) {
      (element as FieldFormalParameterElementImpl).type = field.type;
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
      Element element = node.staticElement;
      if (element is PropertyAccessorElement && element.isSynthetic) {
        element = (element as PropertyAccessorElement).variable;
      }
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
