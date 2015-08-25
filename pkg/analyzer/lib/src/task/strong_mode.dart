// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.strong_mode;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';

/**
 * An object used to find static variables whose types should be inferred and
 * classes whose members should have types inferred. Clients are expected to
 * visit a [CompilationUnit].
 */
class InferrenceFinder extends SimpleAstVisitor {
  /**
   * The static variables that should have types inferred for them.
   */
  final List<VariableElement> staticVariables = <VariableElement>[];

  /**
   * The classes defined in the unit.
   *
   * TODO(brianwilkerson) We don't currently remove classes whose members do not
   * need to be processed, but we potentially could.
   */
  final List<ClassElement> classes = <ClassElement>[];

  /**
   * Initialize a newly created finder.
   */
  InferrenceFinder();

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classes.add(node.element);
    for (ClassMember member in node.members) {
      member.accept(this);
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    classes.add(node.element);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (CompilationUnitMember declaration in node.declarations) {
      declaration.accept(this);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic && node.fields.type == null) {
      _addVariables(node.fields.variables);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.type == null) {
      _addVariables(node.variables.variables);
    }
  }

  /**
   * Add all of the [variables] with initializers to the list of variables whose
   * type can be inferred. Technically, we only infer the types of variables
   * that do not have a static type, but all variables with initializers
   * potentially need to be re-resolved after inference because they might
   * refer to fields whose type was inferred.
   */
  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      if (variable.initializer != null) {
        staticVariables.add(variable.element);
      }
    }
  }
}

/**
 * An object used to infer the type of instance fields and the return types of
 * instance methods within a single compilation unit.
 */
class InstanceMemberInferrer {
  //
  // Previously, all of our analysis tasks have had the property that they only
  // set fields in the element model that were previously null, and they express
  // all their dependencies using the task model. That had the advantage that
  // if a subtle dependency change causes us to re-execute some tasks that we've
  // executed previously, we can be confident that the results from the previous
  // execution won't pollute the results of the re-execution.
  //
  // The algorithm in this class doesn't have that property, since it decides
  // which types to infer based on looking for types that are "dynamic", and
  // then it *replaces* those types with the inferred types.  This means that if
  // type inference is re-run, it won't re-infer already-inferred types. There
  // is concern that a situation could arising where, for example, class A
  // extends class B, and a change to class B requires inference to be re-run on
  // class A, but since class A has already had inference run on it once before,
  // it will not re-infer properly.
  //
  // This probably isn't a problem today because changing class B will cause
  // class A's element model to be re-built from scratch (wiping out any
  // inference results), but one day we might try to make things more
  // incremental, and that could cause subtle breakages. Similar problems might
  // arise if the type of a declaration in class A is in turn inferred from some
  // other elements.
  //
  // In the future we might want the element model to keep track of a
  // "preliminary type" distinct from the "static type" in order to avoid these
  // problems.
  //

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
  InstanceMemberInferrer(this.typeProvider) {
    typeSystem = new TypeSystemImpl(typeProvider);
  }

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

  /**
   * Return the element for the single parameter of the given [setter], or
   * `null` if the executable element is not a setter or does not have a single
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

  DartType _getReturnType(ExecutableElement element) {
    DartType returnType = element.returnType;
    if (returnType == null) {
      return typeProvider.dynamicType;
    }
    return returnType;
  }

  /**
   * If the given [accessorElement] represents a non-synthetic instance getter
   * for which no return type was provided, infer the return type of the getter.
   */
  void _inferAccessor(PropertyAccessorElement accessorElement) {
    if (!accessorElement.isSynthetic &&
        accessorElement.isGetter &&
        !accessorElement.isStatic &&
        accessorElement.hasImplicitReturnType &&
        _getReturnType(accessorElement).isDynamic) {
      List<ExecutableElement> overriddenGetters = inheritanceManager
          .lookupOverrides(
              accessorElement.enclosingElement, accessorElement.name);
      if (overriddenGetters.isNotEmpty && _onlyGetters(overriddenGetters)) {
        DartType newType = _computeReturnType(overriddenGetters);
        List<ExecutableElement> overriddenSetters = inheritanceManager
            .lookupOverrides(
                accessorElement.enclosingElement, accessorElement.name + '=');
        PropertyAccessorElement setter = (accessorElement.enclosingElement
            as ClassElement).getSetter(accessorElement.name);
        if (setter != null) {
          overriddenSetters.add(setter);
        }
        if (_isCompatible(newType, overriddenSetters)) {
          _setReturnType(accessorElement, newType);
          (accessorElement.variable as FieldElementImpl).type = newType;
        }
      }
    }
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
        classElement.accessors.forEach(_inferAccessor);
        classElement.methods.forEach(_inferMethod);
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
        fieldElement.hasImplicitType &&
        fieldElement.type.isDynamic) {
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
      // Then, if none was found, infer the type from the initialization
      // expression.
      //
      if (newType == null) {
        if (fieldElement.initializer != null &&
            (fieldElement.isFinal || overriddenGetters.isEmpty)) {
          newType = fieldElement.initializer.returnType;
        }
      }
      if (newType != null && !newType.isBottom) {
        (fieldElement as FieldElementImpl).type = newType;
        _setReturnType(fieldElement.getter, newType);
        _setParameterType(fieldElement.setter, newType);
      }
    }
  }

  /**
   * If the given [methodElement] represents a non-synthetic instance method
   * for which no return type was provided, infer the return type of the method.
   */
  void _inferMethod(MethodElement methodElement) {
    if (!methodElement.isSynthetic &&
        !methodElement.isStatic &&
        methodElement.hasImplicitReturnType &&
        _getReturnType(methodElement).isDynamic) {
      List<ExecutableElement> overriddenMethods = inheritanceManager
          .lookupOverrides(methodElement.enclosingElement, methodElement.name);
      if (overriddenMethods.isNotEmpty && _onlyMethods(overriddenMethods)) {
        MethodElementImpl element = methodElement as MethodElementImpl;
        _setReturnType(element, _computeReturnType(overriddenMethods));
      }
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
  bool _onlyMethods(List<ExecutableElement> elements) {
    for (ExecutableElement element in elements) {
      if (element is! MethodElement) {
        return false;
      }
    }
    return true;
  }

  /**
   * Set the type of the sole parameter of the given [element] to the given [type].
   */
  void _setParameterType(PropertyAccessorElement element, DartType type) {
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
              new FunctionTypeImpl(element, functionType.prunedTypedefs);
        }
      }
    }
  }

  /**
   * Set the return type of the given [element] to the given [type].
   */
  void _setReturnType(ExecutableElement element, DartType type) {
    if (element is ExecutableElementImpl) {
      //
      // Update the return type of the element, which is stored in two places:
      // directly in the element and indirectly in the type of the element.
      //
      element.returnType = type;
      FunctionType functionType = element.type;
      if (functionType is FunctionTypeImpl) {
        element.type =
            new FunctionTypeImpl(element, functionType.prunedTypedefs);
      }
    }
  }
}

/**
 * A class of exception that is not used anywhere else.
 */
class _CycleException implements Exception {}
