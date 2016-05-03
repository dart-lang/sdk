// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.element.element;

import 'dart:collection';
import 'dart:math' show min;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart' show EvaluationResultImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/**
 * For AST nodes that could be in both the getter and setter contexts
 * ([IndexExpression]s and [SimpleIdentifier]s), the additional resolved
 * elements are stored in the AST node, in an [AuxiliaryElements]. Because
 * resolved elements are either statically resolved or resolved using propagated
 * type information, this class is a wrapper for a pair of [ExecutableElement]s,
 * not just a single [ExecutableElement].
 */
class AuxiliaryElements {
  /**
   * The element based on propagated type information, or `null` if the AST
   * structure has not been resolved or if the node could not be resolved.
   */
  final ExecutableElement propagatedElement;

  /**
   * The element based on static type information, or `null` if the AST
   * structure has not been resolved or if the node could not be resolved.
   */
  final ExecutableElement staticElement;

  /**
   * Initialize a newly created pair to have both the [staticElement] and the
   * [propagatedElement].
   */
  AuxiliaryElements(this.staticElement, this.propagatedElement);
}

/**
 * A concrete implementation of a [ClassElement].
 */
class ClassElementImpl extends ElementImpl implements ClassElement {
  /**
   * A list containing all of the accessors (getters and setters) contained in
   * this class.
   */
  List<PropertyAccessorElement> _accessors = PropertyAccessorElement.EMPTY_LIST;

  /**
   * For classes which are not mixin applications, a list containing all of the
   * constructors contained in this class, or `null` if the list of
   * constructors has not yet been built.
   *
   * For classes which are mixin applications, the list of constructors is
   * computed on the fly by the [constructors] getter, and this field is
   * `null`.
   */
  List<ConstructorElement> _constructors;

  /**
   * A list containing all of the fields contained in this class.
   */
  List<FieldElement> _fields = FieldElement.EMPTY_LIST;

  /**
   * A list containing all of the mixins that are applied to the class being
   * extended in order to derive the superclass of this class.
   */
  @override
  List<InterfaceType> mixins = InterfaceType.EMPTY_LIST;

  /**
   * A list containing all of the interfaces that are implemented by this class.
   */
  @override
  List<InterfaceType> interfaces = InterfaceType.EMPTY_LIST;

  /**
   * A list containing all of the methods contained in this class.
   */
  List<MethodElement> _methods = MethodElement.EMPTY_LIST;

  /**
   * The superclass of the class, or `null` if the class does not have an
   * explicit superclass.
   */
  @override
  InterfaceType supertype;

  /**
   * The type defined by the class.
   */
  @override
  InterfaceType type;

  /**
   * A list containing all of the type parameters defined for this class.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElement.EMPTY_LIST;

  /**
   * A flag indicating whether the types associated with the instance members of
   * this class have been inferred.
   */
  bool hasBeenInferred = false;

  /**
   * Initialize a newly created class element to have the given [name] at the
   * given [offset] in the file that contains the declaration of this element.
   */
  ClassElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created class element to have the given [name].
   */
  ClassElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Set whether this class is abstract.
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  List<PropertyAccessorElement> get accessors => _accessors;

  /**
   * Set the accessors contained in this class to the given [accessors].
   */
  void set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    this._accessors = accessors;
  }

  @override
  List<InterfaceType> get allSupertypes {
    List<InterfaceType> list = new List<InterfaceType>();
    _collectAllSupertypes(list);
    return list;
  }

  @override
  List<ConstructorElement> get constructors {
    if (!isMixinApplication) {
      assert(_constructors != null);
      return _constructors ?? ConstructorElement.EMPTY_LIST;
    }
    return _computeMixinAppConstructors();
  }

  /**
   * Set the constructors contained in this class to the given [constructors].
   *
   * Should only be used for class elements that are not mixin applications.
   */
  void set constructors(List<ConstructorElement> constructors) {
    assert(!isMixinApplication);
    for (ConstructorElement constructor in constructors) {
      (constructor as ConstructorElementImpl).enclosingElement = this;
    }
    this._constructors = constructors;
  }

  /**
   * Return `true` if [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS] should
   * be reported for this class.
   */
  bool get doesMixinLackConstructors {
    if (!isMixinApplication && mixins.isEmpty) {
      // This class is not a mixin application and it doesn't have a "with"
      // clause, so CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS is
      // inapplicable.
      return false;
    }
    if (supertype == null) {
      // Should never happen, since Object is the only class that has no
      // supertype, and it should have been caught by the test above.
      assert(false);
      return false;
    }
    // Find the nearest class in the supertype chain that is not a mixin
    // application.
    ClassElement nearestNonMixinClass = supertype.element;
    if (nearestNonMixinClass.isMixinApplication) {
      // Use a list to keep track of the classes we've seen, so that we won't
      // go into an infinite loop in the event of a non-trivial loop in the
      // class hierarchy.
      List<ClassElement> classesSeen = <ClassElement>[this];
      while (nearestNonMixinClass.isMixinApplication) {
        if (classesSeen.contains(nearestNonMixinClass)) {
          // Loop in the class hierarchy (which is reported elsewhere).  Don't
          // confuse the user with further errors.
          return false;
        }
        classesSeen.add(nearestNonMixinClass);
        if (nearestNonMixinClass.supertype == null) {
          // Should never happen, since Object is the only class that has no
          // supertype, and it is not a mixin application.
          assert(false);
          return false;
        }
        nearestNonMixinClass = nearestNonMixinClass.supertype.element;
      }
    }
    return !nearestNonMixinClass.constructors.any(isSuperConstructorAccessible);
  }

  /**
   * Set whether this class is defined by an enum declaration.
   */
  void set enum2(bool isEnum) {
    setModifier(Modifier.ENUM, isEnum);
  }

  @override
  List<FieldElement> get fields => _fields;

  /**
   * Set the fields contained in this class to the given [fields].
   */
  void set fields(List<FieldElement> fields) {
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    this._fields = fields;
  }

  @override
  bool get hasNonFinalField {
    List<ClassElement> classesToVisit = new List<ClassElement>();
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    classesToVisit.add(this);
    while (!classesToVisit.isEmpty) {
      ClassElement currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        // check fields
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal &&
              !field.isConst &&
              !field.isStatic &&
              !field.isSynthetic) {
            return true;
          }
        }
        // check mixins
        for (InterfaceType mixinType in currentElement.mixins) {
          ClassElement mixinElement = mixinType.element;
          classesToVisit.add(mixinElement);
        }
        // check super
        InterfaceType supertype = currentElement.supertype;
        if (supertype != null) {
          ClassElement superElement = supertype.element;
          if (superElement != null) {
            classesToVisit.add(superElement);
          }
        }
      }
    }
    // not found
    return false;
  }

  @override
  bool get hasReferenceToSuper => hasModifier(Modifier.REFERENCES_SUPER);

  /**
   * Set whether this class references 'super'.
   */
  void set hasReferenceToSuper(bool isReferencedSuper) {
    setModifier(Modifier.REFERENCES_SUPER, isReferencedSuper);
  }

  @override
  bool get hasStaticMember {
    for (MethodElement method in _methods) {
      if (method.isStatic) {
        return true;
      }
    }
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isStatic) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isAbstract => hasModifier(Modifier.ABSTRACT);

  @override
  bool get isEnum => hasModifier(Modifier.ENUM);

  @override
  bool get isMixinApplication => hasModifier(Modifier.MIXIN_APPLICATION);

  @override
  bool get isOrInheritsProxy =>
      _safeIsOrInheritsProxy(this, new HashSet<ClassElement>());

  @override
  bool get isProxy {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isProxy) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isValidMixin {
    if (!context.analysisOptions.enableSuperMixins) {
      if (hasReferenceToSuper) {
        return false;
      }
      if (!supertype.isObject) {
        return false;
      }
    }
    for (ConstructorElement constructor in constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        return false;
      }
    }
    return true;
  }

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  List<MethodElement> get methods => _methods;

  /**
   * Set the methods contained in this class to the given [methods].
   */
  void set methods(List<MethodElement> methods) {
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    this._methods = methods;
  }

  /**
   * Set whether this class is a mixin application.
   */
  void set mixinApplication(bool isMixinApplication) {
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  @override
  List<TypeParameterElement> get typeParameters => _typeParameters;

  /**
   * Set the type parameters defined for this class to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  @override
  ConstructorElement get unnamedConstructor {
    for (ConstructorElement element in constructors) {
      String name = element.displayName;
      if (name == null || name.isEmpty) {
        return element;
      }
    }
    return null;
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitClassElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    if (isAbstract) {
      buffer.write('abstract ');
    }
    if (isEnum) {
      buffer.write('enum ');
    } else {
      buffer.write('class ');
    }
    String name = displayName;
    if (name == null) {
      buffer.write("{unnamed class}");
    } else {
      buffer.write(name);
    }
    int variableCount = _typeParameters.length;
    if (variableCount > 0) {
      buffer.write("<");
      for (int i = 0; i < variableCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (_typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
      }
      buffer.write(">");
    }
    if (supertype != null && !supertype.isObject) {
      buffer.write(' extends ');
      buffer.write(supertype.displayName);
    }
    if (mixins.isNotEmpty) {
      buffer.write(' with ');
      buffer.write(mixins.map((t) => t.displayName).join(', '));
    }
    if (interfaces.isNotEmpty) {
      buffer.write(' implements ');
      buffer.write(interfaces.map((t) => t.displayName).join(', '));
    }
  }

  @override
  NamedCompilationUnitMember computeNode() {
    if (isEnum) {
      return getNodeMatching((node) => node is EnumDeclaration);
    } else {
      return getNodeMatching(
          (node) => node is ClassDeclaration || node is ClassTypeAlias);
    }
  }

  @override
  ElementImpl getChild(String identifier) {
    //
    // The casts in this method are safe because the set methods would have
    // thrown a CCE if any of the elements in the arrays were not of the
    // expected types.
    //
    for (PropertyAccessorElement accessor in _accessors) {
      PropertyAccessorElementImpl accessorImpl = accessor;
      if (accessorImpl.identifier == identifier) {
        return accessorImpl;
      }
    }
    for (ConstructorElement constructor in _constructors) {
      ConstructorElementImpl constructorImpl = constructor;
      if (constructorImpl.identifier == identifier) {
        return constructorImpl;
      }
    }
    for (FieldElement field in _fields) {
      FieldElementImpl fieldImpl = field;
      if (fieldImpl.identifier == identifier) {
        return fieldImpl;
      }
    }
    for (MethodElement method in _methods) {
      MethodElementImpl methodImpl = method;
      if (methodImpl.identifier == identifier) {
        return methodImpl;
      }
    }
    for (TypeParameterElement typeParameter in _typeParameters) {
      TypeParameterElementImpl typeParameterImpl = typeParameter;
      if (typeParameterImpl.identifier == identifier) {
        return typeParameterImpl;
      }
    }
    return null;
  }

  @override
  FieldElement getField(String name) {
    for (FieldElement fieldElement in _fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement getGetter(String getterName) {
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement getMethod(String methodName) {
    for (MethodElement method in _methods) {
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  ConstructorElement getNamedConstructor(String name) {
    for (ConstructorElement element in constructors) {
      String elementName = element.name;
      if (elementName != null && elementName == name) {
        return element;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement getSetter(String setterName) {
    // TODO (jwren) revisit- should we append '=' here or require clients to
    // include it?
    // Do we need the check for isSetter below?
    if (!StringUtilities.endsWithChar(setterName, 0x3D)) {
      setterName += '=';
    }
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isSetter && accessor.name == setterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) {
    // If this class has no mixins, then all superclass constructors are
    // accessible.
    if (mixins.isEmpty) {
      return true;
    }
    // Otherwise only constructors that lack optional parameters are
    // accessible (see dartbug.com/19576).
    for (ParameterElement parameter in constructor.parameters) {
      if (parameter.parameterKind != ParameterKind.REQUIRED) {
        return false;
      }
    }
    return true;
  }

  @override
  MethodElement lookUpConcreteMethod(
          String methodName, LibraryElement library) =>
      _internalLookUpConcreteMethod(
          methodName, library, true, new HashSet<ClassElement>());

  @override
  PropertyAccessorElement lookUpGetter(
          String getterName, LibraryElement library) =>
      _internalLookUpGetter(getterName, library, true);

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
          String getterName, LibraryElement library) =>
      _internalLookUpConcreteGetter(getterName, library, false);

  @override
  MethodElement lookUpInheritedConcreteMethod(
          String methodName, LibraryElement library) =>
      _internalLookUpConcreteMethod(
          methodName, library, false, new HashSet<ClassElement>());

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
          String setterName, LibraryElement library) =>
      _internalLookUpConcreteSetter(setterName, library, false);

  @override
  MethodElement lookUpInheritedMethod(
          String methodName, LibraryElement library) =>
      _internalLookUpMethod(
          methodName, library, false, new HashSet<ClassElement>());

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) =>
      _internalLookUpMethod(
          methodName, library, true, new HashSet<ClassElement>());

  @override
  PropertyAccessorElement lookUpSetter(
          String setterName, LibraryElement library) =>
      _internalLookUpSetter(setterName, library, true);

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_accessors, visitor);
    safelyVisitChildren(_constructors, visitor);
    safelyVisitChildren(_fields, visitor);
    safelyVisitChildren(_methods, visitor);
    safelyVisitChildren(_typeParameters, visitor);
  }

  void _collectAllSupertypes(List<InterfaceType> supertypes) {
    List<InterfaceType> typesToVisit = new List<InterfaceType>();
    List<ClassElement> visitedClasses = new List<ClassElement>();
    typesToVisit.add(this.type);
    while (!typesToVisit.isEmpty) {
      InterfaceType currentType = typesToVisit.removeAt(0);
      ClassElement currentElement = currentType.element;
      if (!visitedClasses.contains(currentElement)) {
        visitedClasses.add(currentElement);
        if (!identical(currentType, this.type)) {
          supertypes.add(currentType);
        }
        InterfaceType supertype = currentType.superclass;
        if (supertype != null) {
          typesToVisit.add(supertype);
        }
        for (InterfaceType type in currentElement.interfaces) {
          typesToVisit.add(type);
        }
        for (InterfaceType type in currentElement.mixins) {
          ClassElement element = type.element;
          if (!visitedClasses.contains(element)) {
            supertypes.add(type);
          }
        }
      }
    }
  }

  /**
   * Compute a list of constructors for this class, which is a mixin
   * application.  If specified, [visitedClasses] is a list of the other mixin
   * application classes which have been visited on the way to reaching this
   * one (this is used to detect circularities).
   */
  List<ConstructorElement> _computeMixinAppConstructors(
      [List<ClassElementImpl> visitedClasses = null]) {
    // First get the list of constructors of the superclass which need to be
    // forwarded to this class.
    Iterable<ConstructorElement> constructorsToForward;
    if (supertype == null) {
      // Shouldn't ever happen, since the only class with no supertype is
      // Object, and it isn't a mixin application.  But for safety's sake just
      // assume an empty list.
      assert(false);
      constructorsToForward = <ConstructorElement>[];
    } else if (!supertype.element.isMixinApplication) {
      List<ConstructorElement> superclassConstructors =
          supertype.element.constructors;
      // Filter out any constructors with optional parameters (see
      // dartbug.com/15101).
      constructorsToForward =
          superclassConstructors.where(isSuperConstructorAccessible);
    } else {
      if (visitedClasses == null) {
        visitedClasses = <ClassElementImpl>[this];
      } else {
        if (visitedClasses.contains(this)) {
          // Loop in the class hierarchy.  Don't try to forward any
          // constructors.
          return <ConstructorElement>[];
        }
        visitedClasses.add(this);
      }
      try {
        constructorsToForward = getImpl(supertype.element)
            ._computeMixinAppConstructors(visitedClasses);
      } finally {
        visitedClasses.removeLast();
      }
    }

    // Figure out the type parameter substitution we need to perform in order
    // to produce constructors for this class.  We want to be robust in the
    // face of errors, so drop any extra type arguments and fill in any missing
    // ones with `dynamic`.
    List<DartType> parameterTypes =
        TypeParameterTypeImpl.getTypes(supertype.typeParameters);
    List<DartType> argumentTypes = new List<DartType>.filled(
        parameterTypes.length, DynamicTypeImpl.instance);
    for (int i = 0; i < supertype.typeArguments.length; i++) {
      if (i >= argumentTypes.length) {
        break;
      }
      argumentTypes[i] = supertype.typeArguments[i];
    }

    // Now create an implicit constructor for every constructor found above,
    // substituting type parameters as appropriate.
    return constructorsToForward
        .map((ConstructorElement superclassConstructor) {
      ConstructorElementImpl implicitConstructor =
          new ConstructorElementImpl(superclassConstructor.name, -1);
      implicitConstructor.synthetic = true;
      implicitConstructor.redirectedConstructor = superclassConstructor;
      implicitConstructor.returnType = type;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      if (count > 0) {
        List<ParameterElement> implicitParameters =
            new List<ParameterElement>(count);
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter =
              new ParameterElementImpl(superParameter.name, -1);
          implicitParameter.const3 = superParameter.isConst;
          implicitParameter.final2 = superParameter.isFinal;
          implicitParameter.parameterKind = superParameter.parameterKind;
          implicitParameter.synthetic = true;
          implicitParameter.type =
              superParameter.type.substitute2(argumentTypes, parameterTypes);
          implicitParameters[i] = implicitParameter;
        }
        implicitConstructor.parameters = implicitParameters;
      }
      implicitConstructor.enclosingElement = this;
      implicitConstructor.type = new FunctionTypeImpl(implicitConstructor);
      return implicitConstructor;
    }).toList();
  }

  PropertyAccessorElement _internalLookUpConcreteGetter(
      String getterName, LibraryElement library, bool includeThisClass) {
    PropertyAccessorElement getter =
        _internalLookUpGetter(getterName, library, includeThisClass);
    while (getter != null && getter.isAbstract) {
      Element definingClass = getter.enclosingElement;
      if (definingClass is! ClassElement) {
        return null;
      }
      getter = getImpl(definingClass)
          ._internalLookUpGetter(getterName, library, false);
    }
    return getter;
  }

  MethodElement _internalLookUpConcreteMethod(
      String methodName,
      LibraryElement library,
      bool includeThisClass,
      HashSet<ClassElement> visitedClasses) {
    MethodElement method = _internalLookUpMethod(
        methodName, library, includeThisClass, visitedClasses);
    while (method != null && method.isAbstract) {
      ClassElement definingClass = method.enclosingElement;
      if (definingClass == null) {
        return null;
      }
      method = getImpl(definingClass)
          ._internalLookUpMethod(methodName, library, false, visitedClasses);
    }
    return method;
  }

  PropertyAccessorElement _internalLookUpConcreteSetter(
      String setterName, LibraryElement library, bool includeThisClass) {
    PropertyAccessorElement setter =
        _internalLookUpSetter(setterName, library, includeThisClass);
    while (setter != null && setter.isAbstract) {
      Element definingClass = setter.enclosingElement;
      if (definingClass is ClassElementImpl) {
        setter =
            definingClass._internalLookUpSetter(setterName, library, false);
      } else {
        return null;
      }
    }
    return setter;
  }

  PropertyAccessorElement _internalLookUpGetter(
      String getterName, LibraryElement library, bool includeThisClass) {
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    ClassElement currentElement = this;
    if (includeThisClass) {
      PropertyAccessorElement element = currentElement.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    while (currentElement != null && visitedClasses.add(currentElement)) {
      for (InterfaceType mixin in currentElement.mixins.reversed) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          PropertyAccessorElement element = mixinElement.getGetter(getterName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
      PropertyAccessorElement element = currentElement.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    return null;
  }

  MethodElement _internalLookUpMethod(String methodName, LibraryElement library,
      bool includeThisClass, HashSet<ClassElement> visitedClasses) {
    ClassElement currentElement = this;
    if (includeThisClass) {
      MethodElement element = currentElement.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    while (currentElement != null && visitedClasses.add(currentElement)) {
      for (InterfaceType mixin in currentElement.mixins.reversed) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          MethodElement element = mixinElement.getMethod(methodName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
      MethodElement element = currentElement.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    return null;
  }

  PropertyAccessorElement _internalLookUpSetter(
      String setterName, LibraryElement library, bool includeThisClass) {
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    ClassElement currentElement = this;
    if (includeThisClass) {
      PropertyAccessorElement element = currentElement.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    while (currentElement != null && visitedClasses.add(currentElement)) {
      for (InterfaceType mixin in currentElement.mixins.reversed) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          PropertyAccessorElement element = mixinElement.getSetter(setterName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
      PropertyAccessorElement element = currentElement.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    return null;
  }

  bool _safeIsOrInheritsProxy(
      ClassElement classElt, HashSet<ClassElement> visitedClassElts) {
    if (visitedClassElts.contains(classElt)) {
      return false;
    }
    visitedClassElts.add(classElt);
    if (classElt.isProxy) {
      return true;
    } else if (classElt.supertype != null &&
        _safeIsOrInheritsProxy(classElt.supertype.element, visitedClassElts)) {
      return true;
    }
    List<InterfaceType> supertypes = classElt.interfaces;
    for (int i = 0; i < supertypes.length; i++) {
      if (_safeIsOrInheritsProxy(supertypes[i].element, visitedClassElts)) {
        return true;
      }
    }
    supertypes = classElt.mixins;
    for (int i = 0; i < supertypes.length; i++) {
      if (_safeIsOrInheritsProxy(supertypes[i].element, visitedClassElts)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the [ClassElementImpl] of the given [classElement].  May throw an
   * exception if the [ClassElementImpl] cannot be provided (should not happen
   * though).
   */
  static ClassElementImpl getImpl(ClassElement classElement) {
    if (classElement is ClassElementHandle) {
      return getImpl(classElement.actualElement);
    }
    return classElement as ClassElementImpl;
  }
}

/**
 * A concrete implementation of a [CompilationUnitElement].
 */
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement {
  /**
   * The source that corresponds to this compilation unit.
   */
  @override
  Source source;

  /**
   * The source of the library containing this compilation unit.
   *
   * This is the same as the source of the containing [LibraryElement],
   * except that it does not require the containing [LibraryElement] to be
   * computed.
   */
  Source librarySource;

  /**
   * A table mapping the offset of a directive to the annotations associated
   * with that directive, or `null` if none of the annotations in the
   * compilation unit have annotations.
   */
  Map<int, List<ElementAnnotation>> annotationMap = null;

  /**
   * A list containing all of the top-level accessors (getters and setters)
   * contained in this compilation unit.
   */
  List<PropertyAccessorElement> _accessors = PropertyAccessorElement.EMPTY_LIST;

  /**
   * A list containing all of the enums contained in this compilation unit.
   */
  List<ClassElement> _enums = ClassElement.EMPTY_LIST;

  /**
   * A list containing all of the top-level functions contained in this
   * compilation unit.
   */
  List<FunctionElement> _functions = FunctionElement.EMPTY_LIST;

  /**
   * A list containing all of the function type aliases contained in this
   * compilation unit.
   */
  List<FunctionTypeAliasElement> _typeAliases =
      FunctionTypeAliasElement.EMPTY_LIST;

  /**
   * A list containing all of the types contained in this compilation unit.
   */
  List<ClassElement> _types = ClassElement.EMPTY_LIST;

  /**
   * A list containing all of the variables contained in this compilation unit.
   */
  List<TopLevelVariableElement> _variables = TopLevelVariableElement.EMPTY_LIST;

  /**
   * A map from offsets to elements of this unit at these offsets.
   */
  final Map<int, Element> _offsetToElementMap = new HashMap<int, Element>();

  /**
   * Initialize a newly created compilation unit element to have the given
   * [name].
   */
  CompilationUnitElementImpl(String name) : super(name, -1);

  @override
  List<PropertyAccessorElement> get accessors => _accessors;

  /**
   * Set the top-level accessors (getters and setters) contained in this
   * compilation unit to the given [accessors].
   */
  void set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    this._accessors = accessors;
  }

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  List<ClassElement> get enums => _enums;

  /**
   * Set the enums contained in this compilation unit to the given [enums].
   */
  void set enums(List<ClassElement> enums) {
    for (ClassElement enumDeclaration in enums) {
      (enumDeclaration as ClassElementImpl).enclosingElement = this;
    }
    this._enums = enums;
  }

  @override
  List<FunctionElement> get functions => _functions;

  /**
   * Set the top-level functions contained in this compilation unit to the given
   * [functions].
   */
  void set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._functions = functions;
  }

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases => _typeAliases;

  @override
  int get hashCode => source.hashCode;

  @override
  bool get hasLoadLibraryFunction {
    for (int i = 0; i < _functions.length; i++) {
      if (_functions[i].name == FunctionElement.LOAD_LIBRARY_NAME) {
        return true;
      }
    }
    return false;
  }

  @override
  String get identifier => source.encoding;

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  List<TopLevelVariableElement> get topLevelVariables => _variables;

  /**
   * Set the top-level variables contained in this compilation unit to the given
   * [variables].
   */
  void set topLevelVariables(List<TopLevelVariableElement> variables) {
    for (TopLevelVariableElement field in variables) {
      (field as TopLevelVariableElementImpl).enclosingElement = this;
    }
    this._variables = variables;
  }

  /**
   * Set the function type aliases contained in this compilation unit to the
   * given [typeAliases].
   */
  void set typeAliases(List<FunctionTypeAliasElement> typeAliases) {
    for (FunctionTypeAliasElement typeAlias in typeAliases) {
      (typeAlias as FunctionTypeAliasElementImpl).enclosingElement = this;
    }
    this._typeAliases = typeAliases;
  }

  @override
  List<ClassElement> get types => _types;

  /**
   * Set the types contained in this compilation unit to the given [types].
   */
  void set types(List<ClassElement> types) {
    for (ClassElement type in types) {
      // Another implementation of ClassElement is _DeferredClassElement,
      // which is used to resynthesize classes lazily. We cannot cast it
      // to ClassElementImpl, and it already can provide correct values of the
      // 'enclosingElement' property.
      if (type is ClassElementImpl) {
        type.enclosingElement = this;
      }
    }
    this._types = types;
  }

  @override
  bool operator ==(Object object) =>
      object is CompilationUnitElementImpl && source == object.source;

  @override
  accept(ElementVisitor visitor) => visitor.visitCompilationUnitElement(this);

  /**
   * This method is invoked after this unit was incrementally resolved.
   */
  void afterIncrementalResolution() {
    _offsetToElementMap.clear();
  }

  @override
  void appendTo(StringBuffer buffer) {
    if (source == null) {
      buffer.write("{compilation unit}");
    } else {
      buffer.write(source.fullName);
    }
  }

  @override
  CompilationUnit computeNode() => unit;

  /**
   * Return the annotations associated with the directive at the given [offset],
   * or an empty list if the directive has no annotations or if there is no
   * directive at the given offset.
   */
  List<ElementAnnotation> getAnnotations(int offset) {
    if (annotationMap == null) {
      return ElementAnnotation.EMPTY_LIST;
    }
    return annotationMap[offset] ?? ElementAnnotation.EMPTY_LIST;
  }

  @override
  ElementImpl getChild(String identifier) {
    //
    // The casts in this method are safe because the set methods would have
    // thrown a CCE if any of the elements in the arrays were not of the
    // expected types.
    //
    for (PropertyAccessorElement accessor in _accessors) {
      PropertyAccessorElementImpl accessorImpl = accessor;
      if (accessorImpl.identifier == identifier) {
        return accessorImpl;
      }
    }
    for (TopLevelVariableElement variable in _variables) {
      TopLevelVariableElementImpl variableImpl = variable;
      if (variableImpl.identifier == identifier) {
        return variableImpl;
      }
    }
    for (FunctionElement function in _functions) {
      FunctionElementImpl functionImpl = function;
      if (functionImpl.identifier == identifier) {
        return functionImpl;
      }
    }
    for (FunctionTypeAliasElement typeAlias in _typeAliases) {
      FunctionTypeAliasElementImpl typeAliasImpl = typeAlias;
      if (typeAliasImpl.identifier == identifier) {
        return typeAliasImpl;
      }
    }
    for (ClassElement type in _types) {
      ClassElementImpl typeImpl = type;
      if (typeImpl.identifier == identifier) {
        return typeImpl;
      }
    }
    for (ClassElement type in _enums) {
      ClassElementImpl typeImpl = type;
      if (typeImpl.identifier == identifier) {
        return typeImpl;
      }
    }
    return null;
  }

  @override
  Element getElementAt(int offset) {
    if (_offsetToElementMap.isEmpty) {
      accept(new _BuildOffsetToElementMap(_offsetToElementMap));
    }
    return _offsetToElementMap[offset];
  }

  @override
  ClassElement getEnum(String enumName) {
    for (ClassElement enumDeclaration in _enums) {
      if (enumDeclaration.name == enumName) {
        return enumDeclaration;
      }
    }
    return null;
  }

  @override
  ClassElement getType(String className) {
    for (ClassElement type in _types) {
      if (type.name == className) {
        return type;
      }
    }
    return null;
  }

  /**
   * Replace the given [from] top-level variable with [to] in this compilation unit.
   */
  void replaceTopLevelVariable(
      TopLevelVariableElement from, TopLevelVariableElement to) {
    int index = _variables.indexOf(from);
    _variables[index] = to;
  }

  /**
   * Set the annotations associated with the directive at the given [offset] to
   * the given list of [annotations].
   */
  void setAnnotations(int offset, List<ElementAnnotation> annotations) {
    annotationMap ??= new HashMap<int, List<ElementAnnotation>>();
    annotationMap[offset] = annotations;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_accessors, visitor);
    safelyVisitChildren(_enums, visitor);
    safelyVisitChildren(_functions, visitor);
    safelyVisitChildren(_typeAliases, visitor);
    safelyVisitChildren(_types, visitor);
    safelyVisitChildren(_variables, visitor);
  }
}

/**
 * A [FieldElement] for a 'const' or 'final' field that has an initializer.
 *
 * TODO(paulberry): we should rename this class to reflect the fact that it's
 * used for both const and final fields.  However, we shouldn't do so until
 * we've created an API for reading the values of constants; until that API is
 * available, clients are likely to read constant values by casting to
 * ConstFieldElementImpl, so it would be a breaking change to rename this
 * class.
 */
class ConstFieldElementImpl extends FieldElementImpl with ConstVariableElement {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created synthetic field element to have the given
   * [name] and [offset].
   */
  ConstFieldElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created field element to have the given [name].
   */
  ConstFieldElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  DartObject get constantValue => _result?.value;

  @override
  EvaluationResultImpl get evaluationResult => _result;

  @override
  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * A [LocalVariableElement] for a local 'const' variable that has an
 * initializer.
 */
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created local variable element to have the given [name]
   * and [offset].
   */
  ConstLocalVariableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created local variable element to have the given [name].
   */
  ConstLocalVariableElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  DartObject get constantValue => _result?.value;

  @override
  EvaluationResultImpl get evaluationResult => _result;

  @override
  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * A concrete implementation of a [ConstructorElement].
 */
class ConstructorElementImpl extends ExecutableElementImpl
    implements ConstructorElement {
  /**
   * The constructor to which this constructor is redirecting.
   */
  ConstructorElement redirectedConstructor;

  /**
   * The initializers for this constructor (used for evaluating constant
   * instance creation expressions).
   */
  List<ConstructorInitializer> constantInitializers;

  /**
   * The offset of the `.` before this constructor name or `null` if not named.
   */
  int periodOffset;

  /**
   * Return the offset of the character immediately following the last character
   * of this constructor's name, or `null` if not named.
   */
  int nameEnd;

  /**
   * True if this constructor has been found by constant evaluation to be free
   * of redirect cycles, and is thus safe to evaluate.
   */
  bool isCycleFree = false;

  /**
   * Initialize a newly created constructor element to have the given [name] and
   * [offset].
   */
  ConstructorElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created constructor element to have the given [name].
   */
  ConstructorElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Set whether this constructor represents a 'const' constructor.
   */
  void set const2(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  /**
   * Set whether this constructor represents a factory method.
   */
  void set factory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  bool get isConst => hasModifier(Modifier.CONST);

  @override
  bool get isDefaultConstructor {
    // unnamed
    String name = this.name;
    if (name != null && name.length != 0) {
      return false;
    }
    // no required parameters
    for (ParameterElement parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.REQUIRED) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }

  @override
  bool get isFactory => hasModifier(Modifier.FACTORY);

  @override
  bool get isStatic => false;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  accept(ElementVisitor visitor) => visitor.visitConstructorElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    if (enclosingElement == null) {
      String message;
      String name = displayName;
      if (name != null && !name.isEmpty) {
        message =
            'Found constructor element named $name with no enclosing element';
      } else {
        message = 'Found unnamed constructor element with no enclosing element';
      }
      AnalysisEngine.instance.logger.logError(message);
      buffer.write('<unknown class>');
    } else {
      buffer.write(enclosingElement.displayName);
    }
    String name = displayName;
    if (name != null && !name.isEmpty) {
      buffer.write(".");
      buffer.write(name);
    }
    super.appendTo(buffer);
  }

  @override
  ConstructorDeclaration computeNode() =>
      getNodeMatching((node) => node is ConstructorDeclaration);
}

/**
 * A [TopLevelVariableElement] for a top-level 'const' variable that has an
 * initializer.
 */
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created synthetic top-level variable element to have the
   * given [name] and [offset].
   */
  ConstTopLevelVariableElementImpl(String name, int offset)
      : super(name, offset);

  /**
   * Initialize a newly created top-level variable element to have the given
   * [name].
   */
  ConstTopLevelVariableElementImpl.forNode(Identifier name)
      : super.forNode(name);

  @override
  DartObject get constantValue => _result?.value;

  @override
  EvaluationResultImpl get evaluationResult => _result;

  @override
  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Mixin used by elements that represent constant variables and have
 * initializers.
 *
 * Note that in correct Dart code, all constant variables must have
 * initializers.  However, analyzer also needs to handle incorrect Dart code,
 * in which case there might be some constant variables that lack initializers.
 * This interface is only used for constant variables that have initializers.
 *
 * This class is not intended to be part of the public API for analyzer.
 */
abstract class ConstVariableElement {
  /**
   * If this element represents a constant variable, and it has an initializer,
   * a copy of the initializer for the constant.  Otherwise `null`.
   *
   * Note that in correct Dart code, all constant variables must have
   * initializers.  However, analyzer also needs to handle incorrect Dart code,
   * in which case there might be some constant variables that lack
   * initializers.
   */
  Expression constantInitializer;
}

/**
 * A [FieldFormalParameterElementImpl] for parameters that have an initializer.
 */
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created parameter element to have the given [name] and
   * [nameOffset].
   */
  DefaultFieldFormalParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  /**
   * Initialize a newly created parameter element to have the given [name].
   */
  DefaultFieldFormalParameterElementImpl.forNode(Identifier name)
      : super.forNode(name);

  @override
  DartObject get constantValue => _result?.value;

  @override
  EvaluationResultImpl get evaluationResult => _result;

  @override
  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * A [ParameterElement] for parameters that have an initializer.
 */
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created parameter element to have the given [name] and
   * [nameOffset].
   */
  DefaultParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  /**
   * Initialize a newly created parameter element to have the given [name].
   */
  DefaultParameterElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  DartObject get constantValue => _result?.value;

  @override
  EvaluationResultImpl get evaluationResult => _result;

  @override
  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }

  @override
  DefaultFormalParameter computeNode() =>
      getNodeMatching((node) => node is DefaultFormalParameter);
}

/**
 * The synthetic element representing the declaration of the type `dynamic`.
 */
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /**
   * Return the unique instance of this class.
   */
  static DynamicElementImpl get instance =>
      DynamicTypeImpl.instance.element as DynamicElementImpl;

  @override
  DynamicTypeImpl type;

  /**
   * Initialize a newly created instance of this class. Instances of this class
   * should <b>not</b> be created except as part of creating the type associated
   * with this element. The single instance of this class should be accessed
   * through the method [getInstance].
   */
  DynamicElementImpl() : super(Keyword.DYNAMIC.syntax, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  accept(ElementVisitor visitor) => null;
}

/**
 * A concrete implementation of an [ElementAnnotation].
 */
class ElementAnnotationImpl implements ElementAnnotation {
  /**
   * The name of the class used to mark an element as being deprecated.
   */
  static String _DEPRECATED_CLASS_NAME = "Deprecated";

  /**
   * The name of the top-level variable used to mark an element as being
   * deprecated.
   */
  static String _DEPRECATED_VARIABLE_NAME = "deprecated";

  /**
   * The name of the class used to JS annotate an element.
   */
  static String _JS_CLASS_NAME = "JS";

  /**
   * The name of `js` library, used to define JS annotations.
   */
  static String _JS_LIB_NAME = "js";

  /**
   * The name of `meta` library, used to define analysis annotations.
   */
  static String _META_LIB_NAME = "meta";

  /**
   * The name of the top-level variable used to mark a method as requiring
   * overriders to call super.
   */
  static String _MUST_CALL_SUPER_VARIABLE_NAME = "mustCallSuper";

  /**
   * The name of the top-level variable used to mark a method as being expected
   * to override an inherited method.
   */
  static String _OVERRIDE_VARIABLE_NAME = "override";

  /**
   * The name of the top-level variable used to mark a method as being
   * protected.
   */
  static String _PROTECTED_VARIABLE_NAME = "protected";

  /**
   * The name of the top-level variable used to mark a class as implementing a
   * proxy object.
   */
  static String PROXY_VARIABLE_NAME = "proxy";

  /**
   * The name of the class used to mark a parameter as being required.
   */
  static String _REQUIRED_CLASS_NAME = "Required";

  /**
   * The name of the top-level variable used to mark a parameter as being
   * required.
   */
  static String _REQUIRED_VARIABLE_NAME = "required";

  /**
   * The element representing the field, variable, or constructor being used as
   * an annotation.
   */
  Element element;

  /**
   * The compilation unit in which this annotation appears.
   */
  final CompilationUnitElementImpl compilationUnit;

  /**
   * The AST of the annotation itself, cloned from the resolved AST for the
   * source code.
   */
  Annotation annotationAst;

  /**
   * The result of evaluating this annotation as a compile-time constant
   * expression, or `null` if the compilation unit containing the variable has
   * not been resolved.
   */
  EvaluationResultImpl evaluationResult;

  /**
   * Initialize a newly created annotation. The given [compilationUnit] is the
   * compilation unit in which the annotation appears.
   */
  ElementAnnotationImpl(this.compilationUnit);

  @override
  DartObject get constantValue => evaluationResult?.value;

  @override
  AnalysisContext get context => compilationUnit.library.context;

  @override
  bool get isDeprecated {
    if (element?.library?.isDartCore == true) {
      if (element is ConstructorElement) {
        return element.enclosingElement.name == _DEPRECATED_CLASS_NAME;
      } else if (element is PropertyAccessorElement) {
        return element.name == _DEPRECATED_VARIABLE_NAME;
      }
    }
    return false;
  }

  @override
  bool get isJS =>
      element is ConstructorElement &&
      element.enclosingElement.name == _JS_CLASS_NAME &&
      element.library?.name == _JS_LIB_NAME;

  @override
  bool get isMustCallSuper =>
      element is PropertyAccessorElement &&
      element.name == _MUST_CALL_SUPER_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isOverride =>
      element is PropertyAccessorElement &&
      element.name == _OVERRIDE_VARIABLE_NAME &&
      element.library?.isDartCore == true;

  @override
  bool get isProtected =>
      element is PropertyAccessorElement &&
      element.name == _PROTECTED_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isProxy =>
      element is PropertyAccessorElement &&
      element.name == PROXY_VARIABLE_NAME &&
      element.library?.isDartCore == true;

  @override
  bool get isRequired =>
      element is ConstructorElement &&
          element.enclosingElement.name == _REQUIRED_CLASS_NAME &&
          element.library?.name == _META_LIB_NAME ||
      element is PropertyAccessorElement &&
          element.name == _REQUIRED_VARIABLE_NAME &&
          element.library?.name == _META_LIB_NAME;

  /**
   * Get the library containing this annotation.
   */
  Source get librarySource => compilationUnit.librarySource;

  @override
  Source get source => compilationUnit.source;

  @override
  String toString() => '@$element';
}

/**
 * A base class for concrete implementations of an [Element].
 */
abstract class ElementImpl implements Element {
  /**
   * An Unicode right arrow.
   */
  static final String RIGHT_ARROW = " \u2192 ";

  static int _NEXT_ID = 0;

  final int id = _NEXT_ID++;

  /**
   * The enclosing element of this element, or `null` if this element is at the
   * root of the element structure.
   */
  ElementImpl _enclosingElement;

  /**
   * The name of this element.
   */
  String _name;

  /**
   * The offset of the name of this element in the file that contains the
   * declaration of this element.
   */
  int _nameOffset = 0;

  /**
   * A bit-encoded form of the modifiers associated with this element.
   */
  int _modifiers = 0;

  /**
   * A list containing all of the metadata associated with this element.
   */
  List<ElementAnnotation> metadata = ElementAnnotation.EMPTY_LIST;

  /**
   * A cached copy of the calculated hashCode for this element.
   */
  int _cachedHashCode;

  /**
   * A cached copy of the calculated location for this element.
   */
  ElementLocation _cachedLocation;

  /**
   * The documentation comment for this element.
   */
  String _docComment;

  /**
   * The offset to the beginning of the documentation comment,
   * or `null` if this element does not have a documentation comment.
   */
  int _docRangeOffset;

  /**
   * The length of the documentation comment range for this element.
   */
  int _docRangeLength;

  /**
   * The offset of the beginning of the element's code in the file that contains
   * the element, or `null` if the element is synthetic.
   */
  int _codeOffset;

  /**
   * The length of the element's code, or `null` if the element is synthetic.
   */
  int _codeLength;

  /**
   * Initialize a newly created element to have the given [name] at the given
   * [_nameOffset].
   */
  ElementImpl(String name, this._nameOffset) {
    this._name = StringUtilities.intern(name);
  }

  /**
   * Initialize a newly created element to have the given [name].
   */
  ElementImpl.forNode(Identifier name)
      : this(name == null ? "" : name.name, name == null ? -1 : name.offset);

  /**
   * The length of the element's code, or `null` if the element is synthetic.
   */
  int get codeLength => _codeLength;

  /**
   * The offset of the beginning of the element's code in the file that contains
   * the element, or `null` if the element is synthetic.
   */
  int get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.context;
  }

  @override
  String get displayName => _name;

  @override
  SourceRange get docRange {
    if (_docRangeOffset != null && _docRangeLength != null) {
      return new SourceRange(_docRangeOffset, _docRangeLength);
    }
    return null;
  }

  @override
  String get documentationComment => _docComment;

  /**
   * The documentation comment source for this element.
   */
  void set documentationComment(String doc) {
    _docComment = doc?.replaceAll('\r\n', '\n');
  }

  @override
  Element get enclosingElement => _enclosingElement;

  /**
   * Set the enclosing element of this element to the given [element].
   *
   * Throws [FrozenHashCodeException] if the hashCode can't be changed.
   */
  void set enclosingElement(Element element) {
    _enclosingElement = element as ElementImpl;
    _updateCaches();
  }

  @override
  int get hashCode {
    // TODO: We might want to re-visit this optimization in the future.
    // We cache the hash code value as this is a very frequently called method.
    if (_cachedHashCode == null) {
      _cachedHashCode = location.hashCode;
    }
    return _cachedHashCode;
  }

  /**
   * Return an identifier that uniquely identifies this element among the
   * children of this element's parent.
   */
  String get identifier => name;

  @override
  bool get isDeprecated {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isJS {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isOverride {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isOverride) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isPrivate {
    String name = displayName;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isProtected {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isRequired {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isSynthetic => hasModifier(Modifier.SYNTHETIC);

  @override
  LibraryElement get library =>
      getAncestor((element) => element is LibraryElement);

  @override
  ElementLocation get location {
    if (_cachedLocation == null) {
      if (library == null) {
        return new ElementLocationImpl.con1(this);
      }
      _cachedLocation = new ElementLocationImpl.con1(this);
    }
    return _cachedLocation;
  }

  @override
  String get name => _name;

  /**
   * Changes the name of this element.
   *
   * Throws [FrozenHashCodeException] if the hashCode can't be changed.
   */
  void set name(String name) {
    this._name = name;
    _updateCaches();
  }

  @override
  int get nameLength => displayName != null ? displayName.length : 0;

  @override
  int get nameOffset => _nameOffset;

  /**
   * Sets the offset of the name of this element in the file that contains the
   * declaration of this element.
   *
   * Throws [FrozenHashCodeException] if the hashCode can't be changed.
   */
  void set nameOffset(int offset) {
    _nameOffset = offset;
    _updateCaches();
  }

  @override
  Source get source {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.source;
  }

  /**
   * Set whether this element is synthetic.
   */
  void set synthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  @override
  CompilationUnit get unit => context.resolveCompilationUnit(source, library);

  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    return object is Element &&
        object.kind == kind &&
        object.location == location;
  }

  /**
   * Append to the given [buffer] a comma-separated list of the names of the
   * types of this element and every enclosing element.
   */
  void appendPathTo(StringBuffer buffer) {
    Element element = this;
    while (element != null) {
      if (element != this) {
        buffer.write(', ');
      }
      buffer.write(element.runtimeType);
      String name = element.name;
      if (name != null) {
        buffer.write(' (');
        buffer.write(name);
        buffer.write(')');
      }
      element = element.enclosingElement;
    }
  }

  /**
   * Append a textual representation of this element to the given [buffer].
   */
  void appendTo(StringBuffer buffer) {
    if (_name == null) {
      buffer.write("<unnamed ");
      buffer.write(runtimeType.toString());
      buffer.write(">");
    } else {
      buffer.write(_name);
    }
  }

  @override
  String computeDocumentationComment() => documentationComment;

  @override
  AstNode computeNode() => getNodeMatching((node) => node is AstNode);

  /**
   * Set this element as the enclosing element for given [element].
   */
  void encloseElement(ElementImpl element) {
    element.enclosingElement = this;
  }

  @override
  Element getAncestor(Predicate<Element> predicate) {
    Element ancestor = _enclosingElement;
    while (ancestor != null && !predicate(ancestor)) {
      ancestor = ancestor.enclosingElement;
    }
    return ancestor;
  }

  /**
   * Return the child of this element that is uniquely identified by the given
   * [identifier], or `null` if there is no such child.
   */
  ElementImpl getChild(String identifier) => null;

  @override
  String getExtendedDisplayName(String shortName) {
    if (shortName == null) {
      shortName = displayName;
    }
    Source source = this.source;
    if (source != null) {
      return "$shortName (${source.fullName})";
    }
    return shortName;
  }

  /**
   * Return the resolved [AstNode] of the given type enclosing [getNameOffset].
   */
  AstNode getNodeMatching(Predicate<AstNode> predicate) {
    CompilationUnit unit = this.unit;
    if (unit == null) {
      return null;
    }
    int offset = nameOffset;
    AstNode node = new NodeLocator(offset).searchWithin(unit);
    if (node == null) {
      return null;
    }
    return node.getAncestor(predicate);
  }

  /**
   * Return `true` if this element has the given [modifier] associated with it.
   */
  bool hasModifier(Modifier modifier) =>
      BooleanArray.getEnum(_modifiers, modifier);

  @override
  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(_name)) {
      return library == this.library;
    }
    return true;
  }

  /**
   * Use the given [visitor] to visit all of the [children] in the given array.
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Set the code range for this element.
   */
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /**
   * Set the documentation comment source range for this element.
   */
  void setDocRange(int offset, int length) {
    _docRangeOffset = offset;
    _docRangeLength = length;
  }

  /**
   * Set whether the given [modifier] is associated with this element to
   * correspond to the given [value].
   */
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.setEnum(_modifiers, modifier, value);
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    appendTo(buffer);
    return buffer.toString();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /**
   *  Updates cached values after an input changed.
   *
   *  Throws [FrozenHashCodeException] if not allowed.
   */
  void _updateCaches() {
    if (!hasModifier(Modifier.CACHE_KEY)) {
      // Fast path.
      _cachedLocation = null;
      _cachedHashCode = null;
      return;
    }

    // Save originals.
    ElementLocation oldLocation = _cachedLocation;
    int oldHashCode = _cachedHashCode;

    _cachedLocation = null;
    _cachedHashCode = null;

    if (oldHashCode != hashCode) {
      // Prevent cache corruption by restoring originals.
      _cachedLocation = oldLocation;
      _cachedHashCode = oldHashCode;
      throw new FrozenHashCodeException(
          "can't update hashCode for a cache key: $this ($runtimeType)");
    }
  }
}

/**
 * A concrete implementation of an [ElementLocation].
 */
class ElementLocationImpl implements ElementLocation {
  /**
   * The character used to separate components in the encoded form.
   */
  static int _SEPARATOR_CHAR = 0x3B;

  /**
   * The path to the element whose location is represented by this object.
   */
  List<String> _components;

  /**
   * The object managing [indexKeyId] and [indexLocationId].
   */
  Object indexOwner;

  /**
   * A cached id of this location in index.
   */
  int indexKeyId;

  /**
   * A cached id of this location in index.
   */
  int indexLocationId;

  /**
   * Initialize a newly created location to represent the given [element].
   */
  ElementLocationImpl.con1(Element element) {
    List<String> components = new List<String>();
    Element ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      ancestor = ancestor.enclosingElement;
    }
    this._components = components;
  }

  /**
   * Initialize a newly created location from the given [encoding].
   */
  ElementLocationImpl.con2(String encoding) {
    this._components = _decode(encoding);
  }

  /**
   * Initialize a newly created location from the given [components].
   */
  ElementLocationImpl.con3(List<String> components) {
    this._components = components;
  }

  @override
  List<String> get components => _components;

  @override
  String get encoding {
    StringBuffer buffer = new StringBuffer();
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        buffer.writeCharCode(_SEPARATOR_CHAR);
      }
      _encode(buffer, _components[i]);
    }
    return buffer.toString();
  }

  @override
  int get hashCode {
    int result = 0;
    for (int i = 0; i < _components.length; i++) {
      String component = _components[i];
      result = JenkinsSmiHash.combine(result, component.hashCode);
    }
    return result;
  }

  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object is ElementLocationImpl) {
      List<String> otherComponents = object._components;
      int length = _components.length;
      if (otherComponents.length != length) {
        return false;
      }
      for (int i = 0; i < length; i++) {
        if (_components[i] != otherComponents[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => encoding;

  /**
   * Decode the [encoding] of a location into a list of components and return
   * the components.
   */
  List<String> _decode(String encoding) {
    List<String> components = new List<String>();
    StringBuffer buffer = new StringBuffer();
    int index = 0;
    int length = encoding.length;
    while (index < length) {
      int currentChar = encoding.codeUnitAt(index);
      if (currentChar == _SEPARATOR_CHAR) {
        if (index + 1 < length &&
            encoding.codeUnitAt(index + 1) == _SEPARATOR_CHAR) {
          buffer.writeCharCode(_SEPARATOR_CHAR);
          index += 2;
        } else {
          components.add(buffer.toString());
          buffer = new StringBuffer();
          index++;
        }
      } else {
        buffer.writeCharCode(currentChar);
        index++;
      }
    }
    components.add(buffer.toString());
    return components;
  }

  /**
   * Append an encoded form of the given [component] to the given [buffer].
   */
  void _encode(StringBuffer buffer, String component) {
    int length = component.length;
    for (int i = 0; i < length; i++) {
      int currentChar = component.codeUnitAt(i);
      if (currentChar == _SEPARATOR_CHAR) {
        buffer.writeCharCode(_SEPARATOR_CHAR);
      }
      buffer.writeCharCode(currentChar);
    }
  }
}

/**
 * A base class for concrete implementations of an [ExecutableElement].
 */
abstract class ExecutableElementImpl extends ElementImpl
    implements ExecutableElement {
  /**
   * A list containing all of the functions defined within this executable
   * element.
   */
  List<FunctionElement> _functions = FunctionElement.EMPTY_LIST;

  /**
   * A list containing all of the labels defined within this executable element.
   */
  List<LabelElement> _labels = LabelElement.EMPTY_LIST;

  /**
   * A list containing all of the local variables defined within this executable
   * element.
   */
  List<LocalVariableElement> _localVariables = LocalVariableElement.EMPTY_LIST;

  /**
   * A list containing all of the parameters defined by this executable element.
   */
  List<ParameterElement> _parameters = ParameterElement.EMPTY_LIST;

  /**
   * A list containing all of the type parameters defined for this executable
   * element.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElement.EMPTY_LIST;

  /**
   * The return type defined by this executable element.
   */
  DartType returnType;

  /**
   * The type of function defined by this executable element.
   */
  FunctionType type;

  /**
   * Initialize a newly created executable element to have the given [name] and
   * [offset].
   */
  ExecutableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created executable element to have the given [name].
   */
  ExecutableElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Set whether this executable element's body is asynchronous.
   */
  void set asynchronous(bool isAsynchronous) {
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  /**
   * Set whether this executable element is external.
   */
  void set external(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  List<FunctionElement> get functions => _functions;

  /**
   * Set the functions defined within this executable element to the given
   * [functions].
   */
  void set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._functions = functions;
  }

  /**
   * Set whether this method's body is a generator.
   */
  void set generator(bool isGenerator) {
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get hasImplicitReturnType => hasModifier(Modifier.IMPLICIT_TYPE);

  /**
   * Set whether this executable element has an implicit return type.
   */
  void set hasImplicitReturnType(bool hasImplicitReturnType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  @override
  bool get isAbstract => hasModifier(Modifier.ABSTRACT);

  @override
  bool get isAsynchronous => hasModifier(Modifier.ASYNCHRONOUS);

  @override
  bool get isExternal => hasModifier(Modifier.EXTERNAL);

  @override
  bool get isGenerator => hasModifier(Modifier.GENERATOR);

  @override
  bool get isOperator => false;

  @override
  bool get isSynchronous => !hasModifier(Modifier.ASYNCHRONOUS);

  @override
  List<LabelElement> get labels => _labels;

  /**
   * Set the labels defined within this executable element to the given
   * [labels].
   */
  void set labels(List<LabelElement> labels) {
    for (LabelElement label in labels) {
      (label as LabelElementImpl).enclosingElement = this;
    }
    this._labels = labels;
  }

  @override
  List<LocalVariableElement> get localVariables => _localVariables;

  /**
   * Set the local variables defined within this executable element to the given
   * [variables].
   */
  void set localVariables(List<LocalVariableElement> variables) {
    for (LocalVariableElement variable in variables) {
      (variable as LocalVariableElementImpl).enclosingElement = this;
    }
    this._localVariables = variables;
  }

  @override
  List<ParameterElement> get parameters => _parameters;

  /**
   * Set the parameters defined by this executable element to the given
   * [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters => _typeParameters;

  /**
   * Set the type parameters defined by this executable element to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  @override
  void appendTo(StringBuffer buffer) {
    if (this.kind != ElementKind.GETTER) {
      int typeParameterCount = _typeParameters.length;
      if (typeParameterCount > 0) {
        buffer.write('<');
        for (int i = 0; i < typeParameterCount; i++) {
          if (i > 0) {
            buffer.write(", ");
          }
          (_typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
        }
        buffer.write('>');
      }
      buffer.write("(");
      String closing = null;
      ParameterKind kind = ParameterKind.REQUIRED;
      int parameterCount = _parameters.length;
      for (int i = 0; i < parameterCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        ParameterElement parameter = _parameters[i];
        ParameterKind parameterKind = parameter.parameterKind;
        if (parameterKind != kind) {
          if (closing != null) {
            buffer.write(closing);
          }
          if (parameterKind == ParameterKind.POSITIONAL) {
            buffer.write("[");
            closing = "]";
          } else if (parameterKind == ParameterKind.NAMED) {
            buffer.write("{");
            closing = "}";
          } else {
            closing = null;
          }
        }
        kind = parameterKind;
        parameter.appendToWithoutDelimiters(buffer);
      }
      if (closing != null) {
        buffer.write(closing);
      }
      buffer.write(")");
    }
    if (type != null) {
      buffer.write(ElementImpl.RIGHT_ARROW);
      buffer.write(type.returnType);
    }
  }

  @override
  ElementImpl getChild(String identifier) {
    for (FunctionElement function in _functions) {
      FunctionElementImpl functionImpl = function;
      if (functionImpl.identifier == identifier) {
        return functionImpl;
      }
    }
    for (LabelElement label in _labels) {
      LabelElementImpl labelImpl = label;
      if (labelImpl.identifier == identifier) {
        return labelImpl;
      }
    }
    for (LocalVariableElement variable in _localVariables) {
      LocalVariableElementImpl variableImpl = variable;
      if (variableImpl.identifier == identifier) {
        return variableImpl;
      }
    }
    for (ParameterElement parameter in _parameters) {
      ParameterElementImpl parameterImpl = parameter;
      if (parameterImpl.identifier == identifier) {
        return parameterImpl;
      }
    }
    return null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_functions, visitor);
    safelyVisitChildren(_labels, visitor);
    safelyVisitChildren(_localVariables, visitor);
    safelyVisitChildren(_parameters, visitor);
  }
}

/**
 * A concrete implementation of an [ExportElement].
 */
class ExportElementImpl extends UriReferencedElementImpl
    implements ExportElement {
  /**
   * The library that is exported from this library by this export directive.
   */
  LibraryElement exportedLibrary;

  /**
   * The combinators that were specified as part of the export directive in the
   * order in which they were specified.
   */
  List<NamespaceCombinator> combinators = NamespaceCombinator.EMPTY_LIST;

  /**
   * Initialize a newly created export element at the given [offset].
   */
  ExportElementImpl(int offset) : super(null, offset);

  @override
  String get identifier => exportedLibrary.name;

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  accept(ElementVisitor visitor) => visitor.visitExportElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("export ");
    (exportedLibrary as LibraryElementImpl).appendTo(buffer);
  }
}

/**
 * A concrete implementation of a [FieldElement].
 */
class FieldElementImpl extends PropertyInducingElementImpl
    implements FieldElement {
  /**
   * Initialize a newly created synthetic field element to have the given [name]
   * at the given [offset].
   */
  FieldElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created field element to have the given [name].
   */
  FieldElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  @override
  bool get isEnumConstant =>
      enclosingElement != null ? enclosingElement.isEnum : false;

  @override
  ElementKind get kind => ElementKind.FIELD;

  /**
   * Set whether this field is static.
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitFieldElement(this);

  @override
  AstNode computeNode() {
    if (isEnumConstant) {
      return getNodeMatching((node) => node is EnumConstantDeclaration);
    } else {
      return getNodeMatching((node) => node is VariableDeclaration);
    }
  }
}

/**
 * A [ParameterElementImpl] that has the additional information of the
 * [FieldElement] associated with the parameter.
 */
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement {
  /**
   * The field associated with this field formal parameter.
   */
  FieldElement field;

  /**
   * Initialize a newly created parameter element to have the given [name] and
   * [nameOffset].
   */
  FieldFormalParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  /**
   * Initialize a newly created parameter element to have the given [name].
   */
  FieldFormalParameterElementImpl.forNode(Identifier name)
      : super.forNode(name);

  @override
  bool get isInitializingFormal => true;

  @override
  accept(ElementVisitor visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/**
 * Indicates that an ElementImpl's hashCode cannot currently be changed.
 */
class FrozenHashCodeException implements Exception {
  final String _message;

  FrozenHashCodeException(this._message);

  @override
  String toString() => "FrozenHashCodeException($_message)";
}

/**
 * A concrete implementation of a [FunctionElement].
 */
class FunctionElementImpl extends ExecutableElementImpl
    implements FunctionElement {
  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element
   * does not have a visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * Initialize a newly created function element to have the given [name] and
   * [offset].
   */
  FunctionElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created function element to have the given [name].
   */
  FunctionElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize a newly created function element to have no name and the given
   * [offset]. This is used for function expressions, that have no name.
   */
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  /**
   * Synthesize an unnamed function element that takes [parameters] and returns
   * [returnType].
   */
  FunctionElementImpl.synthetic(
      List<ParameterElement> parameters, DartType returnType)
      : super("", -1) {
    synthetic = true;
    this.returnType = returnType;
    this.parameters = parameters;

    type = new FunctionTypeImpl(this);
  }

  @override
  String get identifier {
    String identifier = super.identifier;
    if (!isStatic) {
      identifier += "@$nameOffset";
    }
    return identifier;
  }

  @override
  bool get isEntryPoint {
    return isStatic && displayName == FunctionElement.MAIN_FUNCTION_NAME;
  }

  @override
  bool get isStatic => enclosingElement is CompilationUnitElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitFunctionElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    String name = displayName;
    if (name != null) {
      buffer.write(name);
    }
    super.appendTo(buffer);
  }

  @override
  FunctionDeclaration computeNode() =>
      getNodeMatching((node) => node is FunctionDeclaration);

  /**
   * Set the visible range for this element to the range starting at the given
   * [offset] with the given [length].
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  /**
   * Set the parameters defined by this type alias to the given [parameters]
   * without becoming the parent of the parameters. This should only be used by
   * the [TypeResolverVisitor] when creating a synthetic type alias.
   */
  void shareParameters(List<ParameterElement> parameters) {
    this._parameters = parameters;
  }

  /**
   * Set the type parameters defined by this type alias to the given
   * [parameters] without becoming the parent of the parameters. This should
   * only be used by the [TypeResolverVisitor] when creating a synthetic type
   * alias.
   */
  void shareTypeParameters(List<TypeParameterElement> typeParameters) {
    this._typeParameters = typeParameters;
  }
}

/**
 * A concrete implementation of a [FunctionTypeAliasElement].
 */
class FunctionTypeAliasElementImpl extends ElementImpl
    implements FunctionTypeAliasElement {
  /**
   * A list containing all of the parameters defined by this type alias.
   */
  List<ParameterElement> _parameters = ParameterElement.EMPTY_LIST;

  /**
   * The return type defined by this type alias.
   */
  DartType returnType;

  /**
   * The type of function defined by this type alias.
   */
  FunctionType type;

  /**
   * A list containing all of the type parameters defined for this type.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElement.EMPTY_LIST;

  /**
   * Initialize a newly created type alias element to have the given name.
   *
   * [name] the name of this element
   * [nameOffset] the offset of the name of this element in the file that
   *    contains the declaration of this element
   */
  FunctionTypeAliasElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  /**
   * Initialize a newly created type alias element to have the given [name].
   */
  FunctionTypeAliasElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  List<ParameterElement> get parameters => _parameters;

  /**
   * Set the parameters defined by this type alias to the given [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    if (parameters != null) {
      for (ParameterElement parameter in parameters) {
        (parameter as ParameterElementImpl).enclosingElement = this;
      }
    }
    this._parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters => _typeParameters;

  /**
   * Set the type parameters defined for this type to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitFunctionTypeAliasElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("typedef ");
    buffer.write(displayName);
    int typeParameterCount = _typeParameters.length;
    if (typeParameterCount > 0) {
      buffer.write("<");
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (_typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
      }
      buffer.write(">");
    }
    buffer.write("(");
    int parameterCount = _parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      (_parameters[i] as ParameterElementImpl).appendTo(buffer);
    }
    buffer.write(")");
    if (type != null) {
      buffer.write(ElementImpl.RIGHT_ARROW);
      buffer.write(type.returnType);
    } else if (returnType != null) {
      buffer.write(ElementImpl.RIGHT_ARROW);
      buffer.write(returnType);
    }
  }

  @override
  FunctionTypeAlias computeNode() =>
      getNodeMatching((node) => node is FunctionTypeAlias);

  @override
  ElementImpl getChild(String identifier) {
    for (ParameterElement parameter in _parameters) {
      ParameterElementImpl parameterImpl = parameter;
      if (parameterImpl.identifier == identifier) {
        return parameterImpl;
      }
    }
    for (TypeParameterElement typeParameter in _typeParameters) {
      TypeParameterElementImpl typeParameterImpl = typeParameter;
      if (typeParameterImpl.identifier == identifier) {
        return typeParameterImpl;
      }
    }
    return null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_parameters, visitor);
    safelyVisitChildren(_typeParameters, visitor);
  }
}

/**
 * A concrete implementation of a [HideElementCombinator].
 */
class HideElementCombinatorImpl implements HideElementCombinator {
  /**
   * The names that are not to be made visible in the importing library even if
   * they are defined in the imported library.
   */
  List<String> hiddenNames = StringUtilities.EMPTY_ARRAY;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("show ");
    int count = hiddenNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(hiddenNames[i]);
    }
    return buffer.toString();
  }
}

/**
 * A concrete implementation of an [ImportElement].
 */
class ImportElementImpl extends UriReferencedElementImpl
    implements ImportElement {
  /**
   * The offset of the prefix of this import in the file that contains the this
   * import directive, or `-1` if this import is synthetic.
   */
  int prefixOffset = 0;

  /**
   * The library that is imported into this library by this import directive.
   */
  LibraryElement importedLibrary;

  /**
   * The combinators that were specified as part of the import directive in the
   * order in which they were specified.
   */
  List<NamespaceCombinator> combinators = NamespaceCombinator.EMPTY_LIST;

  /**
   * The prefix that was specified as part of the import directive, or `null` if
   * there was no prefix specified.
   */
  PrefixElement prefix;

  /**
   * Initialize a newly created import element at the given [offset].
   * The offset may be `-1` if the import is synthetic.
   */
  ImportElementImpl(int offset) : super(null, offset);

  /**
   * Set whether this import is for a deferred library.
   */
  void set deferred(bool isDeferred) {
    setModifier(Modifier.DEFERRED, isDeferred);
  }

  @override
  String get identifier => "${importedLibrary.identifier}@$nameOffset";

  @override
  bool get isDeferred => hasModifier(Modifier.DEFERRED);

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  accept(ElementVisitor visitor) => visitor.visitImportElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("import ");
    (importedLibrary as LibraryElementImpl).appendTo(buffer);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    prefix?.accept(visitor);
  }
}

/**
 * A concrete implementation of a [LabelElement].
 */
class LabelElementImpl extends ElementImpl implements LabelElement {
  /**
   * A flag indicating whether this label is associated with a `switch`
   * statement.
   */
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchStatement;

  /**
   * A flag indicating whether this label is associated with a `switch` member
   * (`case` or `default`).
   */
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchMember;

  /**
   * Initialize a newly created label element to have the given [name].
   * [onSwitchStatement] should be `true` if this label is associated with a
   * `switch` statement and [onSwitchMember] should be `true` if this label is
   * associated with a `switch` member.
   */
  LabelElementImpl(String name, int nameOffset, this._onSwitchStatement,
      this._onSwitchMember)
      : super(name, nameOffset);

  /**
   * Initialize a newly created label element to have the given [name].
   * [onSwitchStatement] should be `true` if this label is associated with a
   * `switch` statement and [onSwitchMember] should be `true` if this label is
   * associated with a `switch` member.
   */
  LabelElementImpl.forNode(
      Identifier name, this._onSwitchStatement, this._onSwitchMember)
      : super.forNode(name);

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  /**
   * Return `true` if this label is associated with a `switch` member (`case` or
   * `default`).
   */
  bool get isOnSwitchMember => _onSwitchMember;

  /**
   * Return `true` if this label is associated with a `switch` statement.
   */
  bool get isOnSwitchStatement => _onSwitchStatement;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  accept(ElementVisitor visitor) => visitor.visitLabelElement(this);
}

/**
 * A concrete implementation of a [LibraryElement].
 */
class LibraryElementImpl extends ElementImpl implements LibraryElement {
  /**
   * The analysis context in which this library is defined.
   */
  final AnalysisContext context;

  /**
   * The compilation unit that defines this library.
   */
  CompilationUnitElement _definingCompilationUnit;

  /**
   * The entry point for this library, or `null` if this library does not have
   * an entry point.
   */
  FunctionElement entryPoint;

  /**
   * A list containing specifications of all of the imports defined in this
   * library.
   */
  List<ImportElement> _imports = ImportElement.EMPTY_LIST;

  /**
   * A list containing specifications of all of the exports defined in this
   * library.
   */
  List<ExportElement> _exports = ExportElement.EMPTY_LIST;

  /**
   * A list containing the strongly connected component in the import/export
   * graph in which the current library resides.  Computed on demand, null
   * if not present.  If _libraryCycle is set, then the _libraryCycle field
   * for all libraries reachable from this library in the import/export graph
   * is also set.
   */
  List<LibraryElement> _libraryCycle = null;

  /**
   * A list containing all of the compilation units that are included in this
   * library using a `part` directive.
   */
  List<CompilationUnitElement> _parts = CompilationUnitElement.EMPTY_LIST;

  /**
   * The element representing the synthetic function `loadLibrary` that is
   * defined for this library, or `null` if the element has not yet been created.
   */
  FunctionElement _loadLibraryFunction;

  @override
  final int nameLength;

  /**
   * The export [Namespace] of this library, `null` if it has not been
   * computed yet.
   */
  @override
  Namespace exportNamespace;

  /**
   * The public [Namespace] of this library, `null` if it has not been
   * computed yet.
   */
  @override
  Namespace publicNamespace;

  /**
   * Initialize a newly created library element in the given [context] to have
   * the given [name] and [offset].
   */
  LibraryElementImpl(this.context, String name, int offset, this.nameLength)
      : super(name, offset);

  /**
   * Initialize a newly created library element in the given [context] to have
   * the given [name].
   */
  LibraryElementImpl.forNode(this.context, LibraryIdentifier name)
      : nameLength = name != null ? name.length : 0,
        super.forNode(name);

  @override
  int get codeLength {
    CompilationUnitElement unit = _definingCompilationUnit;
    if (unit is CompilationUnitElementImpl) {
      return unit.codeLength;
    }
    return null;
  }

  @override
  int get codeOffset {
    CompilationUnitElement unit = _definingCompilationUnit;
    if (unit is CompilationUnitElementImpl) {
      return unit.codeOffset;
    }
    return null;
  }

  @override
  CompilationUnitElement get definingCompilationUnit =>
      _definingCompilationUnit;

  /**
   * Set the compilation unit that defines this library to the given compilation
   * [unit].
   */
  void set definingCompilationUnit(CompilationUnitElement unit) {
    assert((unit as CompilationUnitElementImpl).librarySource == unit.source);
    (unit as CompilationUnitElementImpl).enclosingElement = this;
    this._definingCompilationUnit = unit;
  }

  @override
  List<LibraryElement> get exportedLibraries {
    HashSet<LibraryElement> libraries = new HashSet<LibraryElement>();
    for (ExportElement element in _exports) {
      LibraryElement library = element.exportedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return new List.from(libraries);
  }

  @override
  List<ExportElement> get exports => _exports;

  /**
   * Set the specifications of all of the exports defined in this library to the
   * given list of [exports].
   */
  void set exports(List<ExportElement> exports) {
    for (ExportElement exportElement in exports) {
      (exportElement as ExportElementImpl).enclosingElement = this;
    }
    this._exports = exports;
  }

  @override
  bool get hasExtUri => hasModifier(Modifier.HAS_EXT_URI);

  /**
   * Set whether this library has an import of a "dart-ext" URI.
   */
  void set hasExtUri(bool hasExtUri) {
    setModifier(Modifier.HAS_EXT_URI, hasExtUri);
  }

  @override
  bool get hasLoadLibraryFunction {
    if (_definingCompilationUnit.hasLoadLibraryFunction) {
      return true;
    }
    for (int i = 0; i < _parts.length; i++) {
      if (_parts[i].hasLoadLibraryFunction) {
        return true;
      }
    }
    return false;
  }

  @override
  String get identifier => _definingCompilationUnit.source.encoding;

  @override
  List<LibraryElement> get importedLibraries {
    HashSet<LibraryElement> libraries = new HashSet<LibraryElement>();
    for (ImportElement element in _imports) {
      LibraryElement library = element.importedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return new List.from(libraries);
  }

  @override
  List<ImportElement> get imports => _imports;

  /**
   * Set the specifications of all of the imports defined in this library to the
   * given list of [imports].
   */
  void set imports(List<ImportElement> imports) {
    for (ImportElement importElement in imports) {
      (importElement as ImportElementImpl).enclosingElement = this;
      PrefixElementImpl prefix = importElement.prefix as PrefixElementImpl;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    this._imports = imports;
  }

  @override
  bool get isBrowserApplication =>
      entryPoint != null && isOrImportsBrowserLibrary;

  @override
  bool get isDartAsync => name == "dart.async";

  @override
  bool get isDartCore => name == "dart.core";

  @override
  bool get isInSdk =>
      StringUtilities.startsWith5(name, 0, 0x64, 0x61, 0x72, 0x74, 0x2E);

  /**
   * Return `true` if the receiver directly or indirectly imports the
   * 'dart:html' libraries.
   */
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = new List<LibraryElement>();
    Source htmlLibSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    visited.add(this);
    for (int index = 0; index < visited.length; index++) {
      LibraryElement library = visited[index];
      Source source = library.definingCompilationUnit.source;
      if (source == htmlLibSource) {
        return true;
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!visited.contains(importedLibrary)) {
          visited.add(importedLibrary);
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!visited.contains(exportedLibrary)) {
          visited.add(exportedLibrary);
        }
      }
    }
    return false;
  }

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  LibraryElement get library => this;

  @override
  List<LibraryElement> get libraryCycle {
    if (_libraryCycle != null) {
      return _libraryCycle;
    }

    // Global counter for this run of the algorithm
    int counter = 0;
    // The discovery times of each library
    Map<LibraryElementImpl, int> indices = {};
    // The set of scc candidates
    Set<LibraryElementImpl> active = new Set();
    // The stack of discovered elements
    List<LibraryElementImpl> stack = [];
    // For a given library that has not yet been processed by this run of the
    // algorithm, compute the strongly connected components.
    int scc(LibraryElementImpl library) {
      int index = counter++;
      int root = index;
      indices[library] = index;
      active.add(library);
      stack.add(library);
      LibraryElementImpl getActualLibrary(LibraryElement lib) {
        // TODO(paulberry): this means that computing a library cycle will be
        // expensive for libraries resynthesized from summaries, since it will
        // require fully resynthesizing all the libraries in the cycle as well
        // as any libraries they import or export.  Try to find a better way.
        if (lib is LibraryElementHandle) {
          return lib.actualElement;
        } else {
          return lib;
        }
      }
      void recurse(LibraryElementImpl child) {
        if (!indices.containsKey(child)) {
          // We haven't visited this child yet, so recurse on the child,
          // returning the lowest numbered node reachable from the child.  If
          // the child can reach a root which is lower numbered than anything
          // we've reached so far, update the root.
          root = min(root, scc(child));
        } else if (active.contains(child)) {
          // The child has been visited, but has not yet been placed into a
          // component.  If the child is higher than anything we've seen so far
          // update the root appropriately.
          root = min(root, indices[child]);
        }
      }
      // Recurse on all of the children in the import/export graph, filtering
      // out those for which library cycles have already been computed.
      library.exportedLibraries
          .map(getActualLibrary)
          .where((l) => l._libraryCycle == null)
          .forEach(recurse);
      library.importedLibraries
          .map(getActualLibrary)
          .where((l) => l._libraryCycle == null)
          .forEach(recurse);

      if (root == index) {
        // This is the root of a strongly connected component.
        // Pop the elements, and share the component across all
        // of the elements.
        List<LibraryElement> component = <LibraryElement>[];
        LibraryElementImpl cur = null;
        do {
          cur = stack.removeLast();
          active.remove(cur);
          component.add(cur);
          cur._libraryCycle = component;
        } while (cur != library);
      }
      return root;
    }
    scc(library);
    return _libraryCycle;
  }

  @override
  FunctionElement get loadLibraryFunction {
    assert(_loadLibraryFunction != null);
    return _loadLibraryFunction;
  }

  @override
  List<CompilationUnitElement> get parts => _parts;

  /**
   * Set the compilation units that are included in this library using a `part`
   * directive to the given list of [parts].
   */
  void set parts(List<CompilationUnitElement> parts) {
    for (CompilationUnitElement compilationUnit in parts) {
      assert((compilationUnit as CompilationUnitElementImpl).librarySource ==
          source);
      (compilationUnit as CompilationUnitElementImpl).enclosingElement = this;
    }
    this._parts = parts;
  }

  @override
  List<PrefixElement> get prefixes {
    HashSet<PrefixElement> prefixes = new HashSet<PrefixElement>();
    for (ImportElement element in _imports) {
      PrefixElement prefix = element.prefix;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return new List.from(prefixes);
  }

  @override
  Source get source {
    if (_definingCompilationUnit == null) {
      return null;
    }
    return _definingCompilationUnit.source;
  }

  @override
  List<CompilationUnitElement> get units {
    List<CompilationUnitElement> units = new List<CompilationUnitElement>();
    units.add(_definingCompilationUnit);
    units.addAll(_parts);
    return units;
  }

  @override
  List<LibraryElement> get visibleLibraries {
    Set<LibraryElement> visibleLibraries = new Set();
    _addVisibleLibraries(visibleLibraries, false);
    return new List.from(visibleLibraries);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitLibraryElement(this);

  /**
   * Create the [FunctionElement] to be returned by [loadLibraryFunction],
   * using types provided by [typeProvider].
   */
  void createLoadLibraryFunction(TypeProvider typeProvider) {
    FunctionElementImpl function =
        new FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1);
    function.synthetic = true;
    function.enclosingElement = this;
    function.returnType = typeProvider.futureDynamicType;
    function.type = new FunctionTypeImpl(function);
    _loadLibraryFunction = function;
  }

  @override
  ElementImpl getChild(String identifier) {
    CompilationUnitElementImpl unitImpl = _definingCompilationUnit;
    if (unitImpl.identifier == identifier) {
      return unitImpl;
    }
    for (CompilationUnitElement part in _parts) {
      CompilationUnitElementImpl partImpl = part;
      if (partImpl.identifier == identifier) {
        return partImpl;
      }
    }
    for (ImportElement importElement in _imports) {
      ImportElementImpl importElementImpl = importElement;
      if (importElementImpl.identifier == identifier) {
        return importElementImpl;
      }
    }
    for (ExportElement exportElement in _exports) {
      ExportElementImpl exportElementImpl = exportElement;
      if (exportElementImpl.identifier == identifier) {
        return exportElementImpl;
      }
    }
    return null;
  }

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) {
    int count = _imports.length;
    List<ImportElement> importList = new List<ImportElement>();
    for (int i = 0; i < count; i++) {
      if (identical(_imports[i].prefix, prefixElement)) {
        importList.add(_imports[i]);
      }
    }
    return importList;
  }

  @override
  ClassElement getType(String className) {
    ClassElement type = _definingCompilationUnit.getType(className);
    if (type != null) {
      return type;
    }
    for (CompilationUnitElement part in _parts) {
      type = part.getType(className);
      if (type != null) {
        return type;
      }
    }
    return null;
  }

  /** Given an update to this library which may have added or deleted edges
   * in the import/export graph originating from this node only, remove any
   * cached library cycles in the element model which may have been invalidated.
   */
  void invalidateLibraryCycles() {
    if (_libraryCycle == null) {
      // We have already invalidated this node, or we have never computed
      // library cycle information for it.  In the former case, we're done. In
      // the latter case, this node cannot be reachable from any node for which
      // we have computed library cycle information.  Therefore, any edges added
      // or deleted in the update causing this invalidation can only be edges to
      // nodes which either have no library cycle information (and hence do not
      // need invalidation), or which do not reach this node by any path.
      // In either case, no further invalidation is needed.
      return;
    }
    // If we have pre-computed library cycle information, then we must
    // invalidate the information both on this element, and on certain
    // other elements.  Edges originating at this node may have been
    // added or deleted.  A deleted edge that points outside of this cycle
    // cannot change the cycle information for anything outside of this cycle,
    // and so it is sufficient to delete the cached library information on this
    // cycle.  An added edge which points to another node within the cycle
    // only invalidates the cycle.  An added edge which points to a node earlier
    // in the topological sort of cycles induces no invalidation (since there
    // are by definition no back edges from earlier cycles in the topological
    // order, and hence no possible cycle can have been introduced.  The only
    // remaining case is that we have added an edge to a node which is later
    // in the topological sort of cycles.  This can induce cycles, since it
    // represents a new back edge.  It would be sufficient to invalidate the
    // cycle information for all nodes that are between the target and the
    // node in the topological order.  For simplicity, we simply invalidate
    // all nodes which are reachable from the the source node.
    // Note that in the invalidation phase, we do not cut off when we encounter
    // a node with no library cycle information, since we do not know whether
    // we are in the case where invalidation has already been performed, or we
    // are in the case where library cycles have simply never been computed from
    // a newly reachable node.
    Set<LibraryElementImpl> active = new HashSet();
    void invalidate(LibraryElement element) {
      LibraryElementImpl library =
          element is LibraryElementHandle ? element.actualElement : element;
      if (active.add(library)) {
        if (library._libraryCycle != null) {
          library._libraryCycle.forEach(invalidate);
          library._libraryCycle = null;
        }
        library.exportedLibraries.forEach(invalidate);
        library.importedLibraries.forEach(invalidate);
      }
    }
    invalidate(this);
  }

  @override
  bool isUpToDate(int timeStamp) {
    Set<LibraryElement> visitedLibraries = new Set();
    return _safeIsUpToDate(this, timeStamp, visitedLibraries);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _definingCompilationUnit?.accept(visitor);
    safelyVisitChildren(_exports, visitor);
    safelyVisitChildren(_imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  /**
   * Recursively fills set of visible libraries for
   * [getVisibleElementsLibraries].
   */
  void _addVisibleLibraries(
      Set<LibraryElement> visibleLibraries, bool includeExports) {
    // maybe already processed
    if (!visibleLibraries.add(this)) {
      return;
    }
    // add imported libraries
    for (ImportElement importElement in _imports) {
      LibraryElement importedLibrary = importElement.importedLibrary;
      if (importedLibrary != null) {
        (importedLibrary as LibraryElementImpl)
            ._addVisibleLibraries(visibleLibraries, true);
      }
    }
    // add exported libraries
    if (includeExports) {
      for (ExportElement exportElement in _exports) {
        LibraryElement exportedLibrary = exportElement.exportedLibrary;
        if (exportedLibrary != null) {
          (exportedLibrary as LibraryElementImpl)
              ._addVisibleLibraries(visibleLibraries, true);
        }
      }
    }
  }

  /**
   * Return `true` if the given [library] is up to date with respect to the
   * given [timeStamp]. The set of [visitedLibraries] is used to prevent
   * infinite recursion in the case of mutually dependent libraries.
   */
  static bool _safeIsUpToDate(LibraryElement library, int timeStamp,
      Set<LibraryElement> visitedLibraries) {
    if (!visitedLibraries.contains(library)) {
      visitedLibraries.add(library);
      AnalysisContext context = library.context;
      // Check the defining compilation unit.
      if (timeStamp <
          context
              .getModificationStamp(library.definingCompilationUnit.source)) {
        return false;
      }
      // Check the parted compilation units.
      for (CompilationUnitElement element in library.parts) {
        if (timeStamp < context.getModificationStamp(element.source)) {
          return false;
        }
      }
      // Check the imported libraries.
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!_safeIsUpToDate(importedLibrary, timeStamp, visitedLibraries)) {
          return false;
        }
      }
      // Check the exported libraries.
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!_safeIsUpToDate(exportedLibrary, timeStamp, visitedLibraries)) {
          return false;
        }
      }
    }
    return true;
  }
}

/**
 * A concrete implementation of a [LocalVariableElement].
 */
class LocalVariableElementImpl extends VariableElementImpl
    implements LocalVariableElement {
  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element
   * does not have a visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * Initialize a newly created method element to have the given [name] and
   * [offset].
   */
  LocalVariableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created local variable element to have the given [name].
   */
  LocalVariableElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  String get identifier {
    int enclosingOffset =
        enclosingElement != null ? enclosingElement.nameOffset : 0;
    int delta = nameOffset - enclosingOffset;
    return '${super.identifier}@$delta';
  }

  @override
  bool get isPotentiallyMutatedInClosure => true;

  @override
  bool get isPotentiallyMutatedInScope => true;

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitLocalVariableElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(type);
    buffer.write(" ");
    buffer.write(displayName);
  }

  @override
  Declaration computeNode() => getNodeMatching(
      (node) => node is DeclaredIdentifier || node is VariableDeclaration);

  /**
   * Set the visible range for this element to the range starting at the given
   * [offset] with the given [length].
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }
}

/**
 * A concrete implementation of a [MethodElement].
 */
class MethodElementImpl extends ExecutableElementImpl implements MethodElement {
  /**
   * Initialize a newly created method element to have the given [name] at the
   * given [offset].
   */
  MethodElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created method element to have the given [name].
   */
  MethodElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Set whether this method is abstract.
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  @override
  bool get isOperator {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) ||
        (0x41 <= first && first <= 0x5A) ||
        first == 0x5F ||
        first == 0x24);
  }

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name {
    String name = super.name;
    if (name == '-' && parameters.isEmpty) {
      return 'unary-';
    }
    return super.name;
  }

  /**
   * Set whether this method is static.
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitMethodElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(displayName);
    super.appendTo(buffer);
  }

  @override
  MethodDeclaration computeNode() =>
      getNodeMatching((node) => node is MethodDeclaration);
}

/**
 * The enumeration `Modifier` defines constants for all of the modifiers defined
 * by the Dart language and for a few additional flags that are useful.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Modifier extends Enum<Modifier> {
  /**
   * Indicates that the modifier 'abstract' was applied to the element.
   */
  static const Modifier ABSTRACT = const Modifier('ABSTRACT', 0);

  /**
   * Indicates that an executable element has a body marked as being
   * asynchronous.
   */
  static const Modifier ASYNCHRONOUS = const Modifier('ASYNCHRONOUS', 1);

  /**
   * Indicates that the modifier 'const' was applied to the element.
   */
  static const Modifier CONST = const Modifier('CONST', 2);

  /**
   * Indicates that the import element represents a deferred library.
   */
  static const Modifier DEFERRED = const Modifier('DEFERRED', 3);

  /**
   * Indicates that a class element was defined by an enum declaration.
   */
  static const Modifier ENUM = const Modifier('ENUM', 4);

  /**
   * Indicates that a class element was defined by an enum declaration.
   */
  static const Modifier EXTERNAL = const Modifier('EXTERNAL', 5);

  /**
   * Indicates that the modifier 'factory' was applied to the element.
   */
  static const Modifier FACTORY = const Modifier('FACTORY', 6);

  /**
   * Indicates that the modifier 'final' was applied to the element.
   */
  static const Modifier FINAL = const Modifier('FINAL', 7);

  /**
   * Indicates that an executable element has a body marked as being a
   * generator.
   */
  static const Modifier GENERATOR = const Modifier('GENERATOR', 8);

  /**
   * Indicates that the pseudo-modifier 'get' was applied to the element.
   */
  static const Modifier GETTER = const Modifier('GETTER', 9);

  /**
   * A flag used for libraries indicating that the defining compilation unit
   * contains at least one import directive whose URI uses the "dart-ext"
   * scheme.
   */
  static const Modifier HAS_EXT_URI = const Modifier('HAS_EXT_URI', 10);

  /**
   * Indicates that the associated element did not have an explicit type
   * associated with it. If the element is an [ExecutableElement], then the
   * type being referred to is the return type.
   */
  static const Modifier IMPLICIT_TYPE = const Modifier('IMPLICIT_TYPE', 11);

  /**
   * Indicates that a class is a mixin application.
   */
  static const Modifier MIXIN_APPLICATION =
      const Modifier('MIXIN_APPLICATION', 12);

  /**
   * Indicates that a class contains an explicit reference to 'super'.
   */
  static const Modifier REFERENCES_SUPER =
      const Modifier('REFERENCES_SUPER', 13);

  /**
   * Indicates that the pseudo-modifier 'set' was applied to the element.
   */
  static const Modifier SETTER = const Modifier('SETTER', 14);

  /**
   * Indicates that the modifier 'static' was applied to the element.
   */
  static const Modifier STATIC = const Modifier('STATIC', 15);

  /**
   * Indicates that the element does not appear in the source code but was
   * implicitly created. For example, if a class does not define any
   * constructors, an implicit zero-argument constructor will be created and it
   * will be marked as being synthetic.
   */
  static const Modifier SYNTHETIC = const Modifier('SYNTHETIC', 16);

  /**
   * Indicates that this element is being used as an analyzer cache key.
   */
  static const Modifier CACHE_KEY = const Modifier('CACHE_KEY', 17);

  static const List<Modifier> persistedValues = const [
    ABSTRACT,
    ASYNCHRONOUS,
    CONST,
    DEFERRED,
    ENUM,
    EXTERNAL,
    FACTORY,
    FINAL,
    GENERATOR,
    GETTER,
    HAS_EXT_URI,
    IMPLICIT_TYPE,
    MIXIN_APPLICATION,
    REFERENCES_SUPER,
    SETTER,
    STATIC,
    SYNTHETIC
  ];

  static const List<Modifier> transientValues = const [CACHE_KEY];

  static final values = new List.unmodifiable(
      []..addAll(persistedValues)..addAll(transientValues));

  const Modifier(String name, int ordinal) : super(name, ordinal);
}

/**
 * A concrete implementation of a [MultiplyDefinedElement].
 */
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
  /**
   * The unique integer identifier of this element.
   */
  final int id = ElementImpl._NEXT_ID++;

  /**
   * The analysis context in which the multiply defined elements are defined.
   */
  final AnalysisContext context;

  /**
   * The name of the conflicting elements.
   */
  String _name;

  /**
   * A list containing all of the elements that conflict.
   */
  final List<Element> conflictingElements;

  /**
   * Initialize a newly created element in the given [context] to represent a
   * list of [conflictingElements].
   */
  MultiplyDefinedElementImpl(this.context, this.conflictingElements) {
    _name = conflictingElements[0].name;
  }

  @override
  String get displayName => _name;

  @override
  SourceRange get docRange => null;

  @override
  String get documentationComment => null;

  @override
  Element get enclosingElement => null;

  @override
  bool get isDeprecated => false;

  @override
  bool get isJS => false;

  @override
  bool get isOverride => false;

  @override
  bool get isPrivate {
    String name = displayName;
    if (name == null) {
      return false;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isProtected => false;

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isRequired => false;

  @override
  bool get isSynthetic => true;

  @override
  ElementKind get kind => ElementKind.ERROR;

  @override
  LibraryElement get library => null;

  @override
  ElementLocation get location => null;

  @override
  List<ElementAnnotation> get metadata => ElementAnnotation.EMPTY_LIST;

  @override
  String get name => _name;

  @override
  int get nameLength => displayName != null ? displayName.length : 0;

  @override
  int get nameOffset => -1;

  @override
  Source get source => null;

  @override
  DartType get type => DynamicTypeImpl.instance;

  @override
  CompilationUnit get unit => null;

  @override
  accept(ElementVisitor visitor) => visitor.visitMultiplyDefinedElement(this);

  @override
  String computeDocumentationComment() => null;

  @override
  AstNode computeNode() => null;

  @override
  Element getAncestor(Predicate<Element> predicate) => null;

  @override
  String getExtendedDisplayName(String shortName) {
    if (shortName != null) {
      return shortName;
    }
    return displayName;
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    for (Element element in conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("[");
    int count = conflictingElements.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      (conflictingElements[i] as ElementImpl).appendTo(buffer);
    }
    buffer.write("]");
    return buffer.toString();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /**
   * Return an element in the given [context] that represents the fact that the
   * [firstElement] and [secondElement] conflict. (If the elements are the same,
   * then one of the two will be returned directly.)
   */
  static Element fromElements(
      AnalysisContext context, Element firstElement, Element secondElement) {
    List<Element> conflictingElements =
        _computeConflictingElements(firstElement, secondElement);
    int length = conflictingElements.length;
    if (length == 0) {
      return null;
    } else if (length == 1) {
      return conflictingElements[0];
    }
    return new MultiplyDefinedElementImpl(context, conflictingElements);
  }

  /**
   * Add the given [element] to the list of [elements]. If the element is a
   * multiply-defined element, add all of the conflicting elements that it
   * represents.
   */
  static void _add(HashSet<Element> elements, Element element) {
    if (element is MultiplyDefinedElementImpl) {
      for (Element conflictingElement in element.conflictingElements) {
        elements.add(conflictingElement);
      }
    } else {
      elements.add(element);
    }
  }

  /**
   * Use the given elements to construct a list of conflicting elements. If
   * either the [firstElement] or [secondElement] are multiply-defined elements
   * then the conflicting elements they represent will be included in the array.
   * Otherwise, the element itself will be included.
   */
  static List<Element> _computeConflictingElements(
      Element firstElement, Element secondElement) {
    HashSet<Element> elements = new HashSet<Element>();
    _add(elements, firstElement);
    _add(elements, secondElement);
    return new List.from(elements);
  }
}

/**
 * A [MethodElementImpl], with the additional information of a list of
 * [ExecutableElement]s from which this element was composed.
 */
class MultiplyInheritedMethodElementImpl extends MethodElementImpl
    implements MultiplyInheritedExecutableElement {
  /**
   * A list the array of executable elements that were used to compose this
   * element.
   */
  List<ExecutableElement> _elements = MethodElement.EMPTY_LIST;

  MultiplyInheritedMethodElementImpl(Identifier name) : super.forNode(name) {
    synthetic = true;
  }

  @override
  List<ExecutableElement> get inheritedElements => _elements;

  void set inheritedElements(List<ExecutableElement> elements) {
    this._elements = elements;
  }
}

/**
 * A [PropertyAccessorElementImpl], with the additional information of a list of
 * [ExecutableElement]s from which this element was composed.
 */
class MultiplyInheritedPropertyAccessorElementImpl
    extends PropertyAccessorElementImpl
    implements MultiplyInheritedExecutableElement {
  /**
   * A list the array of executable elements that were used to compose this
   * element.
   */
  List<ExecutableElement> _elements = PropertyAccessorElement.EMPTY_LIST;

  MultiplyInheritedPropertyAccessorElementImpl(Identifier name)
      : super.forNode(name) {
    synthetic = true;
  }

  @override
  List<ExecutableElement> get inheritedElements => _elements;

  void set inheritedElements(List<ExecutableElement> elements) {
    this._elements = elements;
  }
}

/**
 * A concrete implementation of a [ParameterElement].
 */
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement {
  /**
   * A list containing all of the parameters defined by this parameter element.
   * There will only be parameters if this parameter is a function typed
   * parameter.
   */
  List<ParameterElement> _parameters = ParameterElement.EMPTY_LIST;

  /**
   * A list containing all of the type parameters defined for this parameter
   * element. There will only be parameters if this parameter is a function
   * typed parameter.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElement.EMPTY_LIST;

  /**
   * The kind of this parameter.
   */
  ParameterKind parameterKind;

  /**
   * The Dart code of the default value.
   */
  String _defaultValueCode;

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element
   * does not have a visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * Initialize a newly created parameter element to have the given [name] and
   * [nameOffset].
   */
  ParameterElementImpl(String name, int nameOffset) : super(name, nameOffset);

  /**
   * Initialize a newly created parameter element to have the given [name].
   */
  ParameterElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Creates a synthetic parameter with [name], [type] and [kind].
   */
  factory ParameterElementImpl.synthetic(
      String name, DartType type, ParameterKind kind) {
    ParameterElementImpl element = new ParameterElementImpl(name, -1);
    element.type = type;
    element.synthetic = true;
    element.parameterKind = kind;
    return element;
  }

  @override
  String get defaultValueCode => _defaultValueCode;

  /**
   * Set Dart code of the default value.
   */
  void set defaultValueCode(String defaultValueCode) {
    this._defaultValueCode = StringUtilities.intern(defaultValueCode);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  bool get isPotentiallyMutatedInClosure => true;

  @override
  bool get isPotentiallyMutatedInScope => true;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  List<ParameterElement> get parameters => _parameters;

  /**
   * Set the parameters defined by this executable element to the given
   * [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters => _typeParameters;

  /**
   * Set the type parameters defined by this parameter element to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  @override
  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  @override
  accept(ElementVisitor visitor) => visitor.visitParameterElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    String left = "";
    String right = "";
    while (true) {
      if (parameterKind == ParameterKind.NAMED) {
        left = "{";
        right = "}";
      } else if (parameterKind == ParameterKind.POSITIONAL) {
        left = "[";
        right = "]";
      } else if (parameterKind == ParameterKind.REQUIRED) {}
      break;
    }
    buffer.write(left);
    appendToWithoutDelimiters(buffer);
    buffer.write(right);
  }

  @override
  FormalParameter computeNode() =>
      getNodeMatching((node) => node is FormalParameter);

  @override
  ElementImpl getChild(String identifier) {
    for (ParameterElement parameter in _parameters) {
      ParameterElementImpl parameterImpl = parameter;
      if (parameterImpl.identifier == identifier) {
        return parameterImpl;
      }
    }
    return null;
  }

  /**
   * Set the visible range for this element to the range starting at the given
   * [offset] with the given [length].
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_parameters, visitor);
  }
}

/**
 * A mixin that provides a common implementation for methods defined in
 * [ParameterElement].
 */
abstract class ParameterElementMixin implements ParameterElement {
  @override
  void appendToWithoutDelimiters(StringBuffer buffer) {
    buffer.write(type);
    buffer.write(" ");
    buffer.write(displayName);
    if (defaultValueCode != null) {
      if (parameterKind == ParameterKind.NAMED) {
        buffer.write(": ");
      }
      if (parameterKind == ParameterKind.POSITIONAL) {
        buffer.write(" = ");
      }
      buffer.write(defaultValueCode);
    }
  }
}

/**
 * A concrete implementation of a [PrefixElement].
 */
class PrefixElementImpl extends ElementImpl implements PrefixElement {
  /**
   * Initialize a newly created method element to have the given [name] and
   * [offset].
   */
  PrefixElementImpl(String name, int nameOffset) : super(name, nameOffset);

  /**
   * Initialize a newly created prefix element to have the given [name].
   */
  PrefixElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  String get identifier => "_${super.identifier}";

  @override
  List<LibraryElement> get importedLibraries => LibraryElement.EMPTY_LIST;

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  accept(ElementVisitor visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("as ");
    super.appendTo(buffer);
  }
}

/**
 * A concrete implementation of a [PropertyAccessorElement].
 */
class PropertyAccessorElementImpl extends ExecutableElementImpl
    implements PropertyAccessorElement {
  /**
   * The variable associated with this accessor.
   */
  PropertyInducingElement variable;

  /**
   * Initialize a newly created property accessor element to have the given
   * [name] and [offset].
   */
  PropertyAccessorElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created property accessor element to have the given
   * [name].
   */
  PropertyAccessorElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize a newly created synthetic property accessor element to be
   * associated with the given [variable].
   */
  PropertyAccessorElementImpl.forVariable(PropertyInducingElementImpl variable)
      : super(variable.name, variable.nameOffset) {
    this.variable = variable;
    static = variable.isStatic;
    synthetic = true;
  }

  /**
   * Set whether this accessor is abstract.
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  PropertyAccessorElement get correspondingGetter {
    if (isGetter || variable == null) {
      return null;
    }
    return variable.getter;
  }

  @override
  PropertyAccessorElement get correspondingSetter {
    if (isSetter || variable == null) {
      return null;
    }
    return variable.setter;
  }

  /**
   * Set whether this accessor is a getter.
   */
  void set getter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  int get hashCode => JenkinsSmiHash.hash2(super.hashCode, isGetter ? 1 : 2);

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return "$name$suffix";
  }

  @override
  bool get isGetter => hasModifier(Modifier.GETTER);

  @override
  bool get isSetter => hasModifier(Modifier.SETTER);

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  @override
  String get name {
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
  }

  /**
   * Set whether this accessor is a setter.
   */
  void set setter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  /**
   * Set whether this accessor is static.
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  bool operator ==(Object object) =>
      super == object &&
      isGetter == (object as PropertyAccessorElement).isGetter;

  @override
  accept(ElementVisitor visitor) => visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(isGetter ? "get " : "set ");
    buffer.write(variable.displayName);
    super.appendTo(buffer);
  }

  @override
  AstNode computeNode() {
    if (isSynthetic) {
      return null;
    }
    if (enclosingElement is ClassElement) {
      return getNodeMatching((node) => node is MethodDeclaration);
    } else if (enclosingElement is CompilationUnitElement) {
      return getNodeMatching((node) => node is FunctionDeclaration);
    }
    return null;
  }
}

/**
 * A concrete implementation of a [PropertyInducingElement].
 */
abstract class PropertyInducingElementImpl extends VariableElementImpl
    implements PropertyInducingElement {
  /**
   * The getter associated with this element.
   */
  PropertyAccessorElement getter;

  /**
   * The setter associated with this element, or `null` if the element is
   * effectively `final` and therefore does not have a setter associated with
   * it.
   */
  PropertyAccessorElement setter;

  /**
   * The propagated type of this variable, or `null` if type propagation has not
   * been performed.
   */
  DartType propagatedType;

  /**
   * Initialize a newly created synthetic element to have the given [name] and
   * [offset].
   */
  PropertyInducingElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created element to have the given [name].
   */
  PropertyInducingElementImpl.forNode(Identifier name) : super.forNode(name);
}

/**
 * A concrete implementation of a [ShowElementCombinator].
 */
class ShowElementCombinatorImpl implements ShowElementCombinator {
  /**
   * The names that are to be made visible in the importing library if they are
   * defined in the imported library.
   */
  List<String> shownNames = StringUtilities.EMPTY_ARRAY;

  /**
   * The offset of the character immediately following the last character of
   * this node.
   */
  int end = -1;

  /**
   * The offset of the 'show' keyword of this element.
   */
  int offset = 0;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("show ");
    int count = shownNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(shownNames[i]);
    }
    return buffer.toString();
  }
}

/**
 * A concrete implementation of a [TopLevelVariableElement].
 */
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    implements TopLevelVariableElement {
  /**
   * Initialize a newly created synthetic top-level variable element to have the
   * given [name] and [offset].
   */
  TopLevelVariableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created top-level variable element to have the given
   * [name].
   */
  TopLevelVariableElementImpl.forNode(Identifier name) : super.forNode(name);

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  accept(ElementVisitor visitor) => visitor.visitTopLevelVariableElement(this);

  @override
  VariableDeclaration computeNode() =>
      getNodeMatching((node) => node is VariableDeclaration);
}

/**
 * A concrete implementation of a [TypeParameterElement].
 */
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement {
  /**
   * The type defined by this type parameter.
   */
  TypeParameterType type;

  /**
   * The type representing the bound associated with this parameter, or `null`
   * if this parameter does not have an explicit bound.
   */
  DartType bound;

  /**
   * Initialize a newly created method element to have the given [name] and
   * [offset].
   */
  TypeParameterElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created type parameter element to have the given [name].
   */
  TypeParameterElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize a newly created synthetic type parameter element to have the
   * given [name], and with [synthetic] set to true.
   */
  TypeParameterElementImpl.synthetic(String name) : super(name, -1) {
    synthetic = true;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  accept(ElementVisitor visitor) => visitor.visitTypeParameterElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(displayName);
    if (bound != null) {
      buffer.write(" extends ");
      buffer.write(bound);
    }
  }
}

/**
 * A concrete implementation of a [UriReferencedElement].
 */
abstract class UriReferencedElementImpl extends ElementImpl
    implements UriReferencedElement {
  /**
   * The offset of the URI in the file, may be `-1` if synthetic.
   */
  int uriOffset = -1;

  /**
   * The offset of the character immediately following the last character of
   * this node's URI, may be `-1` if synthetic.
   */
  int uriEnd = -1;

  /**
   * The URI that is specified by this directive.
   */
  String uri;

  /**
   * Initialize a newly created import element to have the given [name] and
   * [offset]. The offset may be `-1` if the element is synthetic.
   */
  UriReferencedElementImpl(String name, int offset) : super(name, offset);
}

/**
 * A concrete implementation of a [VariableElement].
 */
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /**
   * The declared type of this variable.
   */
  DartType type;

  /**
   * A synthetic function representing this variable's initializer, or `null` if
   * this variable does not have an initializer.
   */
  FunctionElement _initializer;

  /**
   * Initialize a newly created variable element to have the given [name] and
   * [offset].
   */
  VariableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created variable element to have the given [name].
   */
  VariableElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Set whether this variable is const.
   */
  void set const3(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  /**
   * If this element represents a constant variable, and it has an initializer,
   * a copy of the initializer for the constant.  Otherwise `null`.
   *
   * Note that in correct Dart code, all constant variables must have
   * initializers.  However, analyzer also needs to handle incorrect Dart code,
   * in which case there might be some constant variables that lack
   * initializers.
   */
  Expression get constantInitializer => null;

  @override
  DartObject get constantValue => null;

  /**
   * Return the result of evaluating this variable's initializer as a
   * compile-time constant expression, or `null` if this variable is not a
   * 'const' variable, if it does not have an initializer, or if the compilation
   * unit containing the variable has not been resolved.
   */
  EvaluationResultImpl get evaluationResult => null;

  /**
   * Set the result of evaluating this variable's initializer as a compile-time
   * constant expression to the given [result].
   */
  void set evaluationResult(EvaluationResultImpl result) {
    throw new IllegalStateException(
        "Invalid attempt to set a compile-time constant result");
  }

  /**
   * Set whether this variable is final.
   */
  void set final2(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get hasImplicitType => hasModifier(Modifier.IMPLICIT_TYPE);

  /**
   * Set whether this variable element has an implicit type.
   */
  void set hasImplicitType(bool hasImplicitType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitType);
  }

  @override
  FunctionElement get initializer => _initializer;

  /**
   * Set the function representing this variable's initializer to the given
   * [function].
   */
  void set initializer(FunctionElement function) {
    if (function != null) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._initializer = function;
  }

  @override
  bool get isConst => hasModifier(Modifier.CONST);

  @override
  bool get isFinal => hasModifier(Modifier.FINAL);

  @override
  bool get isPotentiallyMutatedInClosure => false;

  @override
  bool get isPotentiallyMutatedInScope => false;

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(type);
    buffer.write(" ");
    buffer.write(displayName);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _initializer?.accept(visitor);
  }
}

/**
 * A visitor that visit all the elements recursively and fill the given [map].
 */
class _BuildOffsetToElementMap extends GeneralizingElementVisitor {
  final Map<int, Element> map;

  _BuildOffsetToElementMap(this.map);

  @override
  void visitElement(Element element) {
    int offset = element.nameOffset;
    if (offset != -1) {
      map[offset] = element;
    }
    super.visitElement(element);
  }
}
