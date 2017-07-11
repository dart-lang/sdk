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
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart' show CompileTimeErrorCode;
import 'package:analyzer/src/generated/constant.dart' show EvaluationResultImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/task/dart.dart';

/**
 * Assert that the given [object] is null, which in the places where this
 * function is called means that the element is not resynthesized.
 */
void _assertNotResynthesized(Object object) {
  // TODO(scheglov) I comment this check for now.
  // When we make a decision about switch to the new analysis driver,
  // we will need to rework the analysis code to don't call the setters
  // or restore / inline it.
//  assert(object == null);
}

/**
 * A concrete implementation of a [ClassElement].
 */
abstract class AbstractClassElementImpl extends ElementImpl
    implements ClassElement {
  /**
   * A list containing all of the accessors (getters and setters) contained in
   * this class.
   */
  List<PropertyAccessorElement> _accessors;

  /**
   * A list containing all of the fields contained in this class.
   */
  List<FieldElement> _fields;

  /**
   * Initialize a newly created class element to have the given [name] at the
   * given [offset] in the file that contains the declaration of this element.
   */
  AbstractClassElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created class element to have the given [name].
   */
  AbstractClassElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  AbstractClassElementImpl.forSerialized(
      CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  @override
  List<PropertyAccessorElement> get accessors {
    return _accessors ?? const <PropertyAccessorElement>[];
  }

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
  String get displayName => name;

  @override
  List<FieldElement> get fields => _fields ?? const <FieldElement>[];

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
  bool get isEnum;

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitClassElement(this);

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
    for (PropertyAccessorElement accessor in accessors) {
      PropertyAccessorElementImpl accessorImpl = accessor;
      if (accessorImpl.identifier == identifier) {
        return accessorImpl;
      }
    }
    for (FieldElement field in fields) {
      FieldElementImpl fieldImpl = field;
      if (fieldImpl.identifier == identifier) {
        return fieldImpl;
      }
    }
    return null;
  }

  @override
  FieldElement getField(String name) {
    for (FieldElement fieldElement in fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement getGetter(String getterName) {
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
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
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isSetter && accessor.name == setterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement lookUpConcreteMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              !method.isAbstract && method.isAccessibleIn(library)));

  @override
  PropertyAccessorElement lookUpGetter(
          String getterName, LibraryElement library) =>
      _first(_implementationsOfGetter(getterName).where(
          (PropertyAccessorElement getter) => getter.isAccessibleIn(library)));

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
          String getterName, LibraryElement library) =>
      _first(_implementationsOfGetter(getterName).where(
          (PropertyAccessorElement getter) =>
              !getter.isAbstract &&
              getter.isAccessibleIn(library) &&
              getter.enclosingElement != this));

  @override
  MethodElement lookUpInheritedConcreteMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              !method.isAbstract &&
              method.isAccessibleIn(library) &&
              method.enclosingElement != this));

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
          String setterName, LibraryElement library) =>
      _first(_implementationsOfSetter(setterName).where(
          (PropertyAccessorElement setter) =>
              !setter.isAbstract &&
              setter.isAccessibleIn(library) &&
              setter.enclosingElement != this));

  @override
  MethodElement lookUpInheritedMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              method.isAccessibleIn(library) &&
              method.enclosingElement != this));

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName)
          .where((MethodElement method) => method.isAccessibleIn(library)));

  @override
  PropertyAccessorElement lookUpSetter(
          String setterName, LibraryElement library) =>
      _first(_implementationsOfSetter(setterName).where(
          (PropertyAccessorElement setter) => setter.isAccessibleIn(library)));

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(fields, visitor);
  }

  /**
   * Return the first element from the given [iterable], or `null` if the
   * iterable is empty.
   */
  E _first<E>(Iterable<E> iterable) {
    if (iterable.isEmpty) {
      return null;
    }
    return iterable.first;
  }

  /**
   * Return an iterable containing all of the implementations of a getter with
   * the given [getterName] that are defined in this class any any superclass of
   * this class (but not in interfaces).
   *
   * The getters that are returned are not filtered in any way. In particular,
   * they can include getters that are not visible in some context. Clients must
   * perform any necessary filtering.
   *
   * The getters are returned based on the depth of their defining class; if
   * this class contains a definition of the getter it will occur first, if
   * Object contains a definition of the getter it will occur last.
   */
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String getterName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      PropertyAccessorElement getter = classElement.getGetter(getterName);
      if (getter != null) {
        yield getter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        getter = mixin.element?.getGetter(getterName);
        if (getter != null) {
          yield getter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /**
   * Return an iterable containing all of the implementations of a method with
   * the given [methodName] that are defined in this class any any superclass of
   * this class (but not in interfaces).
   *
   * The methods that are returned are not filtered in any way. In particular,
   * they can include methods that are not visible in some context. Clients must
   * perform any necessary filtering.
   *
   * The methods are returned based on the depth of their defining class; if
   * this class contains a definition of the method it will occur first, if
   * Object contains a definition of the method it will occur last.
   */
  Iterable<MethodElement> _implementationsOfMethod(String methodName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      MethodElement method = classElement.getMethod(methodName);
      if (method != null) {
        yield method;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        method = mixin.element?.getMethod(methodName);
        if (method != null) {
          yield method;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /**
   * Return an iterable containing all of the implementations of a setter with
   * the given [setterName] that are defined in this class any any superclass of
   * this class (but not in interfaces).
   *
   * The setters that are returned are not filtered in any way. In particular,
   * they can include setters that are not visible in some context. Clients must
   * perform any necessary filtering.
   *
   * The setters are returned based on the depth of their defining class; if
   * this class contains a definition of the setter it will occur first, if
   * Object contains a definition of the setter it will occur last.
   */
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String setterName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      PropertyAccessorElement setter = classElement.getSetter(setterName);
      if (setter != null) {
        yield setter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        setter = mixin.element?.getSetter(setterName);
        if (setter != null) {
          yield setter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /**
   * Return the [AbstractClassElementImpl] of the given [classElement].  May
   * throw an exception if the [AbstractClassElementImpl] cannot be provided
   * (should not happen though).
   */
  static AbstractClassElementImpl getImpl(ClassElement classElement) {
    if (classElement is ClassElementHandle) {
      return getImpl(classElement.actualElement);
    }
    return classElement as AbstractClassElementImpl;
  }
}

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
 * An [AbstractClassElementImpl] which is a class.
 */
class ClassElementImpl extends AbstractClassElementImpl
    with TypeParameterizedElementMixin {
  /**
   * The unlinked representation of the class in the summary.
   */
  final UnlinkedClass _unlinkedClass;

  /**
   * The superclass of the class, or `null` for [Object].
   */
  InterfaceType _supertype;

  /**
   * The type defined by the class.
   */
  InterfaceType _type;

  /**
   * A list containing all of the mixins that are applied to the class being
   * extended in order to derive the superclass of this class.
   */
  List<InterfaceType> _mixins;

  /**
   * A list containing all of the interfaces that are implemented by this class.
   */
  List<InterfaceType> _interfaces;

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
   * A list containing all of the methods contained in this class.
   */
  List<MethodElement> _methods;

  /**
   * A flag indicating whether the types associated with the instance members of
   * this class have been inferred.
   */
  bool _hasBeenInferred = false;

  /**
   * The version of this element. The version is changed when the element is
   * incrementally updated, so that its lists of constructors, accessors and
   * methods might be different.
   */
  int version = 0;

  /**
   * Initialize a newly created class element to have the given [name] at the
   * given [offset] in the file that contains the declaration of this element.
   */
  ClassElementImpl(String name, int offset)
      : _unlinkedClass = null,
        super(name, offset);

  /**
   * Initialize a newly created class element to have the given [name].
   */
  ClassElementImpl.forNode(Identifier name)
      : _unlinkedClass = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  ClassElementImpl.forSerialized(
      this._unlinkedClass, CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  /**
   * Set whether this class is abstract.
   */
  void set abstract(bool isAbstract) {
    _assertNotResynthesized(_unlinkedClass);
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_unlinkedClass != null && _accessors == null) {
      _resynthesizeFieldsAndPropertyAccessors();
    }
    return _accessors ?? const <PropertyAccessorElement>[];
  }

  @override
  void set accessors(List<PropertyAccessorElement> accessors) {
    _assertNotResynthesized(_unlinkedClass);
    super.accessors = accessors;
  }

  @override
  List<InterfaceType> get allSupertypes {
    List<InterfaceType> list = new List<InterfaceType>();
    _collectAllSupertypes(list);
    return list;
  }

  @override
  int get codeLength {
    if (_unlinkedClass != null) {
      return _unlinkedClass.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedClass != null) {
      return _unlinkedClass.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  List<ConstructorElement> get constructors {
    if (isMixinApplication) {
      return _computeMixinAppConstructors();
    }
    if (_unlinkedClass != null && _constructors == null) {
      _constructors = _unlinkedClass.executables
          .where((e) => e.kind == UnlinkedExecutableKind.constructor)
          .map((e) => new ConstructorElementImpl.forSerialized(e, this))
          .toList(growable: false);
      // Ensure at least implicit default constructor.
      if (_constructors.isEmpty) {
        ConstructorElementImpl constructor = new ConstructorElementImpl('', -1);
        constructor.isSynthetic = true;
        constructor.enclosingElement = this;
        _constructors = <ConstructorElement>[constructor];
      }
    }
    assert(_constructors != null);
    return _constructors ?? const <ConstructorElement>[];
  }

  /**
   * Set the constructors contained in this class to the given [constructors].
   *
   * Should only be used for class elements that are not mixin applications.
   */
  void set constructors(List<ConstructorElement> constructors) {
    _assertNotResynthesized(_unlinkedClass);
    assert(!isMixinApplication);
    for (ConstructorElement constructor in constructors) {
      (constructor as ConstructorElementImpl).enclosingElement = this;
    }
    this._constructors = constructors;
  }

  @override
  String get documentationComment {
    if (_unlinkedClass != null) {
      return _unlinkedClass?.documentationComment?.text;
    }
    return super.documentationComment;
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

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  List<FieldElement> get fields {
    if (_unlinkedClass != null && _fields == null) {
      _resynthesizeFieldsAndPropertyAccessors();
    }
    return _fields ?? const <FieldElement>[];
  }

  @override
  void set fields(List<FieldElement> fields) {
    _assertNotResynthesized(_unlinkedClass);
    super.fields = fields;
  }

  bool get hasBeenInferred {
    if (_unlinkedClass != null) {
      return context.analysisOptions.strongMode;
    }
    return _hasBeenInferred;
  }

  void set hasBeenInferred(bool hasBeenInferred) {
    _assertNotResynthesized(_unlinkedClass);
    _hasBeenInferred = hasBeenInferred;
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

  /**
   * Return `true` if the class has a `noSuchMethod()` method distinct from the
   * one declared in class `Object`, as per the Dart Language Specification
   * (section 10.4).
   */
  bool get hasNoSuchMethod {
    MethodElement method =
        lookUpMethod(FunctionElement.NO_SUCH_METHOD_METHOD_NAME, library);
    ClassElement definingClass = method?.enclosingElement;
    return definingClass != null && !definingClass.type.isObject;
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
    for (MethodElement method in methods) {
      if (method.isStatic) {
        return true;
      }
    }
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isStatic) {
        return true;
      }
    }
    return false;
  }

  @override
  List<InterfaceType> get interfaces {
    if (_unlinkedClass != null && _interfaces == null) {
      ResynthesizerContext context = enclosingUnit.resynthesizerContext;
      _interfaces = _unlinkedClass.interfaces
          .map((EntityRef t) => context.resolveTypeRef(this, t))
          .where(_isClassInterfaceType)
          .toList(growable: false);
    }
    return _interfaces ?? const <InterfaceType>[];
  }

  void set interfaces(List<InterfaceType> interfaces) {
    _assertNotResynthesized(_unlinkedClass);
    _interfaces = interfaces;
  }

  @override
  bool get isAbstract {
    if (_unlinkedClass != null) {
      return _unlinkedClass.isAbstract;
    }
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isEnum => false;

  @override
  bool get isMixinApplication {
    if (_unlinkedClass != null) {
      return _unlinkedClass.isMixinApplication;
    }
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

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
  List<ElementAnnotation> get metadata {
    if (_unlinkedClass != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedClass.annotations);
    }
    return super.metadata;
  }

  @override
  List<MethodElement> get methods {
    if (_unlinkedClass != null) {
      _methods ??= _unlinkedClass.executables
          .where((e) => e.kind == UnlinkedExecutableKind.functionOrMethod)
          .map((e) => new MethodElementImpl.forSerialized(e, this))
          .toList(growable: false);
    }
    return _methods ?? const <MethodElement>[];
  }

  /**
   * Set the methods contained in this class to the given [methods].
   */
  void set methods(List<MethodElement> methods) {
    _assertNotResynthesized(_unlinkedClass);
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    _methods = methods;
  }

  /**
   * Set whether this class is a mixin application.
   */
  void set mixinApplication(bool isMixinApplication) {
    _assertNotResynthesized(_unlinkedClass);
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  @override
  List<InterfaceType> get mixins {
    if (_unlinkedClass != null && _mixins == null) {
      ResynthesizerContext context = enclosingUnit.resynthesizerContext;
      _mixins = _unlinkedClass.mixins
          .map((EntityRef t) => context.resolveTypeRef(this, t))
          .where(_isClassInterfaceType)
          .toList(growable: false);
    }
    return _mixins ?? const <InterfaceType>[];
  }

  void set mixins(List<InterfaceType> mixins) {
    _assertNotResynthesized(_unlinkedClass);
    _mixins = mixins;
  }

  @override
  String get name {
    if (_unlinkedClass != null) {
      return _unlinkedClass.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedClass != null) {
      return _unlinkedClass.nameOffset;
    }
    return offset;
  }

  @override
  InterfaceType get supertype {
    if (_unlinkedClass != null && _supertype == null) {
      if (_unlinkedClass.supertype != null) {
        DartType type = enclosingUnit.resynthesizerContext
            .resolveTypeRef(this, _unlinkedClass.supertype);
        if (_isClassInterfaceType(type)) {
          _supertype = type;
        } else {
          _supertype = context.typeProvider.objectType;
        }
      } else if (_unlinkedClass.hasNoSupertype) {
        return null;
      } else {
        _supertype = context.typeProvider.objectType;
      }
    }
    return _supertype;
  }

  void set supertype(InterfaceType supertype) {
    _assertNotResynthesized(_unlinkedClass);
    _supertype = supertype;
  }

  @override
  InterfaceType get type {
    if (_type == null) {
      InterfaceTypeImpl type = new InterfaceTypeImpl(this);
      type.typeArguments = typeParameterTypes;
      _type = type;
    }
    return _type;
  }

  /**
   * Set the type parameters defined for this class to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    _assertNotResynthesized(_unlinkedClass);
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameterElements = typeParameters;
  }

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedClass?.typeParameters;

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
  void appendTo(StringBuffer buffer) {
    if (isAbstract) {
      buffer.write('abstract ');
    }
    buffer.write('class ');
    String name = displayName;
    if (name == null) {
      buffer.write("{unnamed class}");
    } else {
      buffer.write(name);
    }
    int variableCount = typeParameters.length;
    if (variableCount > 0) {
      buffer.write("<");
      for (int i = 0; i < variableCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
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
  ElementImpl getChild(String identifier) {
    ElementImpl child = super.getChild(identifier);
    if (child != null) {
      return child;
    }
    //
    // The casts in this method are safe because the set methods would have
    // thrown a CCE if any of the elements in the arrays were not of the
    // expected types.
    //
    for (ConstructorElement constructor in _constructors) {
      ConstructorElementImpl constructorImpl = constructor;
      if (constructorImpl.identifier == identifier) {
        return constructorImpl;
      }
    }
    for (MethodElement method in methods) {
      MethodElementImpl methodImpl = method;
      if (methodImpl.identifier == identifier) {
        return methodImpl;
      }
    }
    for (TypeParameterElement typeParameter in typeParameters) {
      TypeParameterElementImpl typeParameterImpl = typeParameter;
      if (typeParameterImpl.identifier == identifier) {
        return typeParameterImpl;
      }
    }
    return null;
  }

  @override
  MethodElement getMethod(String methodName) {
    int length = methods.length;
    for (int i = 0; i < length; i++) {
      MethodElement method = methods[i];
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
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(constructors, visitor);
    safelyVisitChildren(methods, visitor);
    safelyVisitChildren(typeParameters, visitor);
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
        ClassElementImpl superElement = AbstractClassElementImpl
            .getImpl(supertype.element) as ClassElementImpl;
        constructorsToForward =
            superElement._computeMixinAppConstructors(visitedClasses);
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
      implicitConstructor.isSynthetic = true;
      implicitConstructor.redirectedConstructor = superclassConstructor;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      if (count > 0) {
        List<ParameterElement> implicitParameters =
            new List<ParameterElement>(count);
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter =
              new ParameterElementImpl(superParameter.name, -1);
          implicitParameter.isConst = superParameter.isConst;
          implicitParameter.isFinal = superParameter.isFinal;
          implicitParameter.parameterKind = superParameter.parameterKind;
          implicitParameter.isSynthetic = true;
          implicitParameter.type =
              superParameter.type.substitute2(argumentTypes, parameterTypes);
          implicitParameters[i] = implicitParameter;
        }
        implicitConstructor.parameters = implicitParameters;
      }
      implicitConstructor.enclosingElement = this;
      return implicitConstructor;
    }).toList(growable: false);
  }

  /**
   * Resynthesize explicit fields and property accessors and fill [_fields] and
   * [_accessors] with explicit and implicit elements.
   */
  void _resynthesizeFieldsAndPropertyAccessors() {
    assert(_fields == null);
    assert(_accessors == null);
    // Build explicit fields and implicit property accessors.
    var explicitFields = <FieldElement>[];
    var implicitAccessors = <PropertyAccessorElement>[];
    for (UnlinkedVariable v in _unlinkedClass.fields) {
      FieldElementImpl field =
          new FieldElementImpl.forSerializedFactory(v, this);
      explicitFields.add(field);
      implicitAccessors.add(
          new PropertyAccessorElementImpl_ImplicitGetter(field)
            ..enclosingElement = this);
      if (!field.isConst && !field.isFinal) {
        implicitAccessors.add(
            new PropertyAccessorElementImpl_ImplicitSetter(field)
              ..enclosingElement = this);
      }
    }
    // Build explicit property accessors and implicit fields.
    var explicitAccessors = <PropertyAccessorElement>[];
    var implicitFields = <String, FieldElementImpl>{};
    for (UnlinkedExecutable e in _unlinkedClass.executables) {
      if (e.kind == UnlinkedExecutableKind.getter ||
          e.kind == UnlinkedExecutableKind.setter) {
        PropertyAccessorElementImpl accessor =
            new PropertyAccessorElementImpl.forSerialized(e, this);
        explicitAccessors.add(accessor);
        // Create or update the implicit field.
        String fieldName = accessor.displayName;
        FieldElementImpl field = implicitFields[fieldName];
        if (field == null) {
          field = new FieldElementImpl(fieldName, -1);
          implicitFields[fieldName] = field;
          field.enclosingElement = this;
          field.isSynthetic = true;
          field.isFinal = e.kind == UnlinkedExecutableKind.getter;
          field.isStatic = e.isStatic;
        } else {
          field.isFinal = false;
        }
        accessor.variable = field;
        if (e.kind == UnlinkedExecutableKind.getter) {
          field.getter = accessor;
        } else {
          field.setter = accessor;
        }
      }
    }
    // Combine explicit and implicit fields and property accessors.
    _fields = <FieldElement>[]
      ..addAll(explicitFields)
      ..addAll(implicitFields.values);
    _accessors = <PropertyAccessorElement>[]
      ..addAll(explicitAccessors)
      ..addAll(implicitAccessors);
  }

  bool _safeIsOrInheritsProxy(
      ClassElement element, HashSet<ClassElement> visited) {
    if (visited.contains(element)) {
      return false;
    }
    visited.add(element);
    if (element.isProxy) {
      return true;
    } else if (element.supertype != null &&
        _safeIsOrInheritsProxy(element.supertype.element, visited)) {
      return true;
    }
    List<InterfaceType> supertypes = element.interfaces;
    for (int i = 0; i < supertypes.length; i++) {
      if (_safeIsOrInheritsProxy(supertypes[i].element, visited)) {
        return true;
      }
    }
    supertypes = element.mixins;
    for (int i = 0; i < supertypes.length; i++) {
      if (_safeIsOrInheritsProxy(supertypes[i].element, visited)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [type] is a class [InterfaceType].
   */
  static bool _isClassInterfaceType(DartType type) {
    return type is InterfaceType && !type.element.isEnum;
  }
}

/**
 * A concrete implementation of a [CompilationUnitElement].
 */
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement {
  /**
   * The context in which this unit is resynthesized, or `null` if the
   * element is not resynthesized a summary.
   */
  final ResynthesizerContext resynthesizerContext;

  /**
   * The unlinked representation of the unit in the summary.
   */
  final UnlinkedUnit _unlinkedUnit;

  /**
   * The unlinked representation of the part in the summary.
   */
  final UnlinkedPart _unlinkedPart;

  /**
   * The source that corresponds to this compilation unit.
   */
  @override
  Source source;

  @override
  LineInfo lineInfo;

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
  List<PropertyAccessorElement> _accessors;

  /**
   * A list containing all of the enums contained in this compilation unit.
   */
  List<ClassElement> _enums;

  /**
   * A list containing all of the top-level functions contained in this
   * compilation unit.
   */
  List<FunctionElement> _functions;

  /**
   * A list containing all of the function type aliases contained in this
   * compilation unit.
   */
  List<FunctionTypeAliasElement> _typeAliases;

  /**
   * A list containing all of the types contained in this compilation unit.
   */
  List<ClassElement> _types;

  /**
   * A list containing all of the variables contained in this compilation unit.
   */
  List<TopLevelVariableElement> _variables;

  /**
   * Resynthesized explicit top-level property accessors.
   */
  UnitExplicitTopLevelAccessors _explicitTopLevelAccessors;

  /**
   * Resynthesized explicit top-level variables.
   */
  UnitExplicitTopLevelVariables _explicitTopLevelVariables;

  /**
   * Description of top-level variable replacements that should be applied
   * to implicit top-level variables because of re-linking top-level property
   * accessors between different unit of the same library.
   */
  Map<TopLevelVariableElement, TopLevelVariableElement>
      _topLevelVariableReplaceMap;

  /**
   * Initialize a newly created compilation unit element to have the given
   * [name].
   */
  CompilationUnitElementImpl(String name)
      : resynthesizerContext = null,
        _unlinkedUnit = null,
        _unlinkedPart = null,
        super(name, -1);

  /**
   * Initialize using the given serialized information.
   */
  CompilationUnitElementImpl.forSerialized(
      LibraryElementImpl enclosingLibrary,
      this.resynthesizerContext,
      this._unlinkedUnit,
      this._unlinkedPart,
      String name)
      : super.forSerialized(null) {
    _enclosingElement = enclosingLibrary;
    _name = name;
    _nameOffset = -1;
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_unlinkedUnit != null) {
      if (_accessors == null) {
        _explicitTopLevelAccessors ??=
            resynthesizerContext.buildTopLevelAccessors();
        _explicitTopLevelVariables ??=
            resynthesizerContext.buildTopLevelVariables();
        List<PropertyAccessorElementImpl> accessors =
            <PropertyAccessorElementImpl>[];
        accessors.addAll(_explicitTopLevelAccessors.accessors);
        accessors.addAll(_explicitTopLevelVariables.implicitAccessors);
        _accessors = accessors;
      }
    }
    return _accessors ?? PropertyAccessorElement.EMPTY_LIST;
  }

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
  int get codeLength {
    if (_unlinkedUnit != null) {
      return _unlinkedUnit.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedUnit != null) {
      return _unlinkedUnit.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return this;
  }

  @override
  List<ClassElement> get enums {
    if (_unlinkedUnit != null) {
      _enums ??= _unlinkedUnit.enums
          .map((e) => new EnumElementImpl.forSerialized(e, this))
          .toList(growable: false);
    }
    return _enums ?? const <ClassElement>[];
  }

  /**
   * Set the enums contained in this compilation unit to the given [enums].
   */
  void set enums(List<ClassElement> enums) {
    _assertNotResynthesized(_unlinkedUnit);
    for (ClassElement enumDeclaration in enums) {
      (enumDeclaration as EnumElementImpl).enclosingElement = this;
    }
    this._enums = enums;
  }

  @override
  List<FunctionElement> get functions {
    if (_unlinkedUnit != null) {
      _functions ??= _unlinkedUnit.executables
          .where((e) => e.kind == UnlinkedExecutableKind.functionOrMethod)
          .map((e) => new FunctionElementImpl.forSerialized(e, this))
          .toList(growable: false);
    }
    return _functions ?? const <FunctionElement>[];
  }

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
  List<FunctionTypeAliasElement> get functionTypeAliases {
    if (_unlinkedUnit != null) {
      _typeAliases ??= _unlinkedUnit.typedefs.map((t) {
        if (t.style == TypedefStyle.functionType) {
          return new FunctionTypeAliasElementImpl.forSerialized(t, this);
        } else if (t.style == TypedefStyle.genericFunctionType) {
          return new GenericTypeAliasElementImpl.forSerialized(t, this);
        }
      }).toList(growable: false);
    }
    return _typeAliases ?? const <FunctionTypeAliasElement>[];
  }

  @override
  int get hashCode => source.hashCode;

  @override
  bool get hasLoadLibraryFunction {
    List<FunctionElement> functions = this.functions;
    for (int i = 0; i < functions.length; i++) {
      if (functions[i].name == FunctionElement.LOAD_LIBRARY_NAME) {
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
  List<ElementAnnotation> get metadata {
    if (_unlinkedPart != null) {
      return _metadata ??= _buildAnnotations(
          library.definingCompilationUnit as CompilationUnitElementImpl,
          _unlinkedPart.annotations);
    }
    return super.metadata;
  }

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    if (_unlinkedUnit != null) {
      if (_variables == null) {
        _explicitTopLevelAccessors ??=
            resynthesizerContext.buildTopLevelAccessors();
        _explicitTopLevelVariables ??=
            resynthesizerContext.buildTopLevelVariables();
        List<TopLevelVariableElementImpl> variables =
            <TopLevelVariableElementImpl>[];
        variables.addAll(_explicitTopLevelVariables.variables);
        variables.addAll(_explicitTopLevelAccessors.implicitVariables);
        // Ensure that getters and setters in different units use
        // the same top-level variables.
        (enclosingElement as LibraryElementImpl)
            .resynthesizerContext
            .patchTopLevelAccessors();
        _variables = variables;
        _topLevelVariableReplaceMap?.forEach((from, to) {
          int index = _variables.indexOf(from);
          _variables[index] = to;
        });
        _topLevelVariableReplaceMap = null;
      }
    }
    return _variables ?? TopLevelVariableElement.EMPTY_LIST;
  }

  /**
   * Set the top-level variables contained in this compilation unit to the given
   * [variables].
   */
  void set topLevelVariables(List<TopLevelVariableElement> variables) {
    assert(!isResynthesized);
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
    _assertNotResynthesized(_unlinkedUnit);
    for (FunctionTypeAliasElement typeAlias in typeAliases) {
      (typeAlias as ElementImpl).enclosingElement = this;
    }
    this._typeAliases = typeAliases;
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext => null;

  @override
  List<ClassElement> get types {
    if (_unlinkedUnit != null) {
      _types ??= _unlinkedUnit.classes
          .map((c) => new ClassElementImpl.forSerialized(c, this))
          .toList(growable: false);
    }
    return _types ?? const <ClassElement>[];
  }

  /**
   * Set the types contained in this compilation unit to the given [types].
   */
  void set types(List<ClassElement> types) {
    _assertNotResynthesized(_unlinkedUnit);
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
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitCompilationUnitElement(this);

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
      return const <ElementAnnotation>[];
    }
    return annotationMap[offset] ?? const <ElementAnnotation>[];
  }

  @override
  ElementImpl getChild(String identifier) {
    //
    // The casts in this method are safe because the set methods would have
    // thrown a CCE if any of the elements in the arrays were not of the
    // expected types.
    //
    for (PropertyAccessorElement accessor in accessors) {
      PropertyAccessorElementImpl accessorImpl = accessor;
      if (accessorImpl.identifier == identifier) {
        return accessorImpl;
      }
    }
    for (TopLevelVariableElement variable in topLevelVariables) {
      TopLevelVariableElementImpl variableImpl = variable;
      if (variableImpl.identifier == identifier) {
        return variableImpl;
      }
    }
    for (FunctionElement function in functions) {
      FunctionElementImpl functionImpl = function;
      if (functionImpl.identifier == identifier) {
        return functionImpl;
      }
    }
    for (FunctionTypeAliasElement typeAlias in functionTypeAliases) {
      FunctionTypeAliasElementImpl typeAliasImpl = typeAlias;
      if (typeAliasImpl.identifier == identifier) {
        return typeAliasImpl;
      }
    }
    for (ClassElement type in types) {
      ClassElementImpl typeImpl = type;
      if (typeImpl.name == identifier) {
        return typeImpl;
      }
    }
    for (ClassElement type in _enums) {
      EnumElementImpl typeImpl = type;
      if (typeImpl.identifier == identifier) {
        return typeImpl;
      }
    }
    return null;
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
    for (ClassElement type in types) {
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
    if (_unlinkedUnit != null) {
      // Getters and setter in different units should be patched to use the
      // same variables before these variables were asked and returned.
      assert(_variables == null);
      _topLevelVariableReplaceMap ??=
          <TopLevelVariableElement, TopLevelVariableElement>{};
      _topLevelVariableReplaceMap[from] = to;
    } else {
      int index = _variables.indexOf(from);
      _variables[index] = to;
    }
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
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(enums, visitor);
    safelyVisitChildren(functions, visitor);
    safelyVisitChildren(functionTypeAliases, visitor);
    safelyVisitChildren(types, visitor);
    safelyVisitChildren(topLevelVariables, visitor);
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
   * Initialize a newly created synthetic field element to have the given
   * [name] and [offset].
   */
  ConstFieldElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created field element to have the given [name].
   */
  ConstFieldElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  ConstFieldElementImpl.forSerialized(
      UnlinkedVariable unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedVariable, enclosingElement);
}

/**
 * A field element representing an enum constant.
 */
class ConstFieldElementImpl_EnumValue extends ConstFieldElementImpl_ofEnum {
  final UnlinkedEnumValue _unlinkedEnumValue;
  final int _index;

  ConstFieldElementImpl_EnumValue(
      EnumElementImpl enumElement, this._unlinkedEnumValue, this._index)
      : super(enumElement);

  @override
  String get documentationComment {
    if (_unlinkedEnumValue != null) {
      return _unlinkedEnumValue?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  @override
  EvaluationResultImpl get evaluationResult {
    if (_evaluationResult == null) {
      Map<String, DartObjectImpl> fieldMap = <String, DartObjectImpl>{
        name: new DartObjectImpl(
            context.typeProvider.intType, new IntState(_index))
      };
      DartObjectImpl value =
          new DartObjectImpl(type, new GenericState(fieldMap));
      _evaluationResult = new EvaluationResultImpl(value);
    }
    return _evaluationResult;
  }

  @override
  String get name {
    if (_unlinkedEnumValue != null) {
      return _unlinkedEnumValue.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == -1 && _unlinkedEnumValue != null) {
      return _unlinkedEnumValue.nameOffset;
    }
    return offset;
  }

  @override
  InterfaceType get type => _enum.type;
}

/**
 * The synthetic `values` field of an enum.
 */
class ConstFieldElementImpl_EnumValues extends ConstFieldElementImpl_ofEnum {
  ConstFieldElementImpl_EnumValues(EnumElementImpl enumElement)
      : super(enumElement) {
    isSynthetic = true;
  }

  @override
  EvaluationResultImpl get evaluationResult {
    if (_evaluationResult == null) {
      List<DartObjectImpl> constantValues = <DartObjectImpl>[];
      for (FieldElement field in _enum.fields) {
        if (field is ConstFieldElementImpl_EnumValue) {
          constantValues.add(field.evaluationResult.value);
        }
      }
      _evaluationResult = new EvaluationResultImpl(
          new DartObjectImpl(type, new ListState(constantValues)));
    }
    return _evaluationResult;
  }

  @override
  String get name => 'values';

  @override
  InterfaceType get type {
    if (_type == null) {
      InterfaceType listType = context.typeProvider.listType;
      return _type = listType.instantiate(<DartType>[_enum.type]);
    }
    return _type;
  }
}

/**
 * An abstract constant field of an enum.
 */
abstract class ConstFieldElementImpl_ofEnum extends ConstFieldElementImpl {
  final EnumElementImpl _enum;

  ConstFieldElementImpl_ofEnum(this._enum) : super(null, -1) {
    enclosingElement = _enum;
  }

  @override
  void set evaluationResult(_) {
    assert(false);
  }

  @override
  bool get isConst => true;

  @override
  void set isConst(bool isConst) {
    assert(false);
  }

  @override
  void set isFinal(bool isFinal) {
    assert(false);
  }

  @override
  bool get isStatic => true;

  @override
  void set isStatic(bool isStatic) {
    assert(false);
  }

  void set type(DartType type) {
    assert(false);
  }
}

/**
 * A [LocalVariableElement] for a local 'const' variable that has an
 * initializer.
 */
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /**
   * Initialize a newly created local variable element to have the given [name]
   * and [offset].
   */
  ConstLocalVariableElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created local variable element to have the given [name].
   */
  ConstLocalVariableElementImpl.forNode(Identifier name) : super.forNode(name);
}

/**
 * A concrete implementation of a [ConstructorElement].
 */
class ConstructorElementImpl extends ExecutableElementImpl
    implements ConstructorElement {
  /**
   * The constructor to which this constructor is redirecting.
   */
  ConstructorElement _redirectedConstructor;

  /**
   * The initializers for this constructor (used for evaluating constant
   * instance creation expressions).
   */
  List<ConstructorInitializer> _constantInitializers;

  /**
   * The offset of the `.` before this constructor name or `null` if not named.
   */
  int _periodOffset;

  /**
   * Return the offset of the character immediately following the last character
   * of this constructor's name, or `null` if not named.
   */
  int _nameEnd;

  /**
   * True if this constructor has been found by constant evaluation to be free
   * of redirect cycles, and is thus safe to evaluate.
   */
  bool _isCycleFree = false;

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
   * Initialize using the given serialized information.
   */
  ConstructorElementImpl.forSerialized(
      UnlinkedExecutable serializedExecutable, ClassElementImpl enclosingClass)
      : super.forSerialized(serializedExecutable, enclosingClass);

  /**
   * Return the constant initializers for this element, which will be empty if
   * there are no initializers, or `null` if there was an error in the source.
   */
  List<ConstructorInitializer> get constantInitializers {
    if (serializedExecutable != null && _constantInitializers == null) {
      _constantInitializers ??= serializedExecutable.constantInitializers
          .map((i) => _buildConstructorInitializer(i))
          .toList(growable: false);
    }
    return _constantInitializers;
  }

  void set constantInitializers(
      List<ConstructorInitializer> constantInitializers) {
    _assertNotResynthesized(serializedExecutable);
    _constantInitializers = constantInitializers;
  }

  @override
  ClassElementImpl get enclosingElement =>
      super.enclosingElement as ClassElementImpl;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      super.enclosingElement as ClassElementImpl;

  /**
   * Set whether this constructor represents a factory method.
   */
  void set factory(bool isFactory) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  bool get isConst {
    if (serializedExecutable != null) {
      return serializedExecutable.isConst;
    }
    return hasModifier(Modifier.CONST);
  }

  /**
   * Set whether this constructor represents a 'const' constructor.
   */
  void set isConst(bool isConst) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.CONST, isConst);
  }

  bool get isCycleFree {
    if (serializedExecutable != null) {
      return serializedExecutable.isConst &&
          !enclosingUnit.resynthesizerContext
              .isInConstCycle(serializedExecutable.constCycleSlot);
    }
    return _isCycleFree;
  }

  void set isCycleFree(bool isCycleFree) {
    // This property is updated in ConstantEvaluationEngine even for
    // resynthesized constructors, so we don't have the usual assert here.
    _isCycleFree = isCycleFree;
  }

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
  bool get isFactory {
    if (serializedExecutable != null) {
      return serializedExecutable.isFactory;
    }
    return hasModifier(Modifier.FACTORY);
  }

  @override
  bool get isStatic => false;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  int get nameEnd {
    if (serializedExecutable != null) {
      if (serializedExecutable.name.isNotEmpty) {
        return serializedExecutable.nameEnd;
      } else {
        return serializedExecutable.nameOffset + enclosingElement.name.length;
      }
    }
    return _nameEnd;
  }

  void set nameEnd(int nameEnd) {
    _assertNotResynthesized(serializedExecutable);
    _nameEnd = nameEnd;
  }

  @override
  int get periodOffset {
    if (serializedExecutable != null) {
      if (serializedExecutable.name.isNotEmpty) {
        return serializedExecutable.periodOffset;
      }
    }
    return _periodOffset;
  }

  void set periodOffset(int periodOffset) {
    _assertNotResynthesized(serializedExecutable);
    _periodOffset = periodOffset;
  }

  @override
  ConstructorElement get redirectedConstructor {
    if (serializedExecutable != null && _redirectedConstructor == null) {
      if (serializedExecutable.isRedirectedConstructor) {
        if (serializedExecutable.isFactory) {
          _redirectedConstructor = enclosingUnit.resynthesizerContext
              .resolveConstructorRef(
                  enclosingElement, serializedExecutable.redirectedConstructor);
        } else {
          _redirectedConstructor = enclosingElement.getNamedConstructor(
              serializedExecutable.redirectedConstructorName);
        }
      } else {
        return null;
      }
    }
    return _redirectedConstructor;
  }

  void set redirectedConstructor(ConstructorElement redirectedConstructor) {
    _assertNotResynthesized(serializedExecutable);
    _redirectedConstructor = redirectedConstructor;
  }

  @override
  DartType get returnType => enclosingElement.type;

  void set returnType(DartType returnType) {
    assert(false);
  }

  @override
  FunctionType get type {
    return _type ??= new FunctionTypeImpl(this);
  }

  void set type(FunctionType type) {
    assert(false);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

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

  /**
   * Resynthesize the AST for the given serialized constructor initializer.
   */
  ConstructorInitializer _buildConstructorInitializer(
      UnlinkedConstructorInitializer serialized) {
    UnlinkedConstructorInitializerKind kind = serialized.kind;
    String name = serialized.name;
    List<Expression> arguments = <Expression>[];
    {
      int numArguments = serialized.arguments.length;
      int numNames = serialized.argumentNames.length;
      for (int i = 0; i < numArguments; i++) {
        Expression expression = enclosingUnit.resynthesizerContext
            .buildExpression(this, serialized.arguments[i]);
        int nameIndex = numNames + i - numArguments;
        if (nameIndex >= 0) {
          expression = AstTestFactory.namedExpression2(
              serialized.argumentNames[nameIndex], expression);
        }
        arguments.add(expression);
      }
    }
    switch (kind) {
      case UnlinkedConstructorInitializerKind.field:
        ConstructorFieldInitializer initializer =
            AstTestFactory.constructorFieldInitializer(
                false,
                name,
                enclosingUnit.resynthesizerContext
                    .buildExpression(this, serialized.expression));
        initializer.fieldName.staticElement = enclosingElement.getField(name);
        return initializer;
      case UnlinkedConstructorInitializerKind.assertInvocation:
        return AstTestFactory.assertInitializer(
            arguments[0], arguments.length > 1 ? arguments[1] : null);
      case UnlinkedConstructorInitializerKind.superInvocation:
        SuperConstructorInvocation initializer =
            AstTestFactory.superConstructorInvocation2(
                name.isNotEmpty ? name : null, arguments);
        ClassElement superElement = enclosingElement.supertype.element;
        ConstructorElement element = name.isEmpty
            ? superElement.unnamedConstructor
            : superElement.getNamedConstructor(name);
        initializer.staticElement = element;
        initializer.constructorName?.staticElement = element;
        return initializer;
      case UnlinkedConstructorInitializerKind.thisInvocation:
        RedirectingConstructorInvocation initializer =
            AstTestFactory.redirectingConstructorInvocation2(
                name.isNotEmpty ? name : null, arguments);
        ConstructorElement element = name.isEmpty
            ? enclosingElement.unnamedConstructor
            : enclosingElement.getNamedConstructor(name);
        initializer.staticElement = element;
        initializer.constructorName?.staticElement = element;
        return initializer;
    }
    return null;
  }
}

/**
 * A [TopLevelVariableElement] for a top-level 'const' variable that has an
 * initializer.
 */
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
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

  /**
   * Initialize using the given serialized information.
   */
  ConstTopLevelVariableElementImpl.forSerialized(
      UnlinkedVariable unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedVariable, enclosingElement);
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
abstract class ConstVariableElement
    implements ElementImpl, ConstantEvaluationTarget {
  /**
   * If this element represents a constant variable, and it has an initializer,
   * a copy of the initializer for the constant.  Otherwise `null`.
   *
   * Note that in correct Dart code, all constant variables must have
   * initializers.  However, analyzer also needs to handle incorrect Dart code,
   * in which case there might be some constant variables that lack
   * initializers.
   */
  Expression _constantInitializer;

  EvaluationResultImpl _evaluationResult;

  Expression get constantInitializer {
    if (_constantInitializer == null && _unlinkedConst != null) {
      _constantInitializer = enclosingUnit.resynthesizerContext
          .buildExpression(this, _unlinkedConst);
    }
    return _constantInitializer;
  }

  void set constantInitializer(Expression constantInitializer) {
    _assertNotResynthesized(_unlinkedConst);
    _constantInitializer = constantInitializer;
  }

  EvaluationResultImpl get evaluationResult => _evaluationResult;

  void set evaluationResult(EvaluationResultImpl evaluationResult) {
    _evaluationResult = evaluationResult;
  }

  /**
   * If this element is resynthesized from the summary, return the unlinked
   * initializer, otherwise return `null`.
   */
  UnlinkedExpr get _unlinkedConst;

  /**
   * Return a representation of the value of this variable, forcing the value
   * to be computed if it had not previously been computed, or `null` if either
   * this variable was not declared with the 'const' modifier or if the value of
   * this variable could not be computed because of errors.
   */
  DartObject computeConstantValue() {
    if (evaluationResult == null) {
      context?.computeResult(this, CONSTANT_VALUE);
    }
    return evaluationResult?.value;
  }
}

/**
 * A [FieldFormalParameterElementImpl] for parameters that have an initializer.
 */
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
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

  /**
   * Initialize using the given serialized information.
   */
  DefaultFieldFormalParameterElementImpl.forSerialized(
      UnlinkedParam unlinkedParam, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedParam, enclosingElement);
}

/**
 * A [ParameterElement] for parameters that have an initializer.
 */
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
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

  /**
   * Initialize using the given serialized information.
   */
  DefaultParameterElementImpl.forSerialized(
      UnlinkedParam unlinkedParam, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedParam, enclosingElement);

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
   * through the method [instance].
   */
  DynamicElementImpl() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  T accept<T>(ElementVisitor<T> visitor) => null;
}

/**
 * A concrete implementation of an [ElementAnnotation].
 */
class ElementAnnotationImpl implements ElementAnnotation {
  /**
   * The name of the top-level variable used to mark a method parameter as
   * covariant.
   */
  static String _COVARIANT_VARIABLE_NAME = "checked";

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
   * The name of the top-level variable used to mark a method as being a
   * factory.
   */
  static String _FACTORY_VARIABLE_NAME = "factory";

  /**
   * The name of the top-level variable used to mark a class and its subclasses
   * as being immutable.
   */
  static String _IMMUTABLE_VARIABLE_NAME = "immutable";

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
  CompilationUnitElementImpl compilationUnit;

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

  /**
   * Return `true` if this annotation marks the associated parameter as being
   * covariant, meaning it is allowed to have a narrower type in an override.
   */
  bool get isCovariant =>
      element is PropertyAccessorElement &&
      element.name == _COVARIANT_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

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
  bool get isFactory =>
      element is PropertyAccessorElement &&
      element.name == _FACTORY_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isImmutable =>
      element is PropertyAccessorElement &&
      element.name == _IMMUTABLE_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

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
  DartObject computeConstantValue() {
    if (evaluationResult == null) {
      context?.computeResult(this, CONSTANT_VALUE);
    }
    return constantValue;
  }

  @override
  String toSource() => annotationAst.toSource();

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
  List<ElementAnnotation> _metadata;

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
   * Initialize from serialized information.
   */
  ElementImpl.forSerialized(this._enclosingElement);

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
  String get documentationComment => _docComment;

  /**
   * The documentation comment source for this element.
   */
  void set documentationComment(String doc) {
    assert(!isResynthesized);
    _docComment = doc?.replaceAll('\r\n', '\n');
  }

  @override
  Element get enclosingElement => _enclosingElement;

  /**
   * Set the enclosing element of this element to the given [element].
   */
  void set enclosingElement(Element element) {
    _enclosingElement = element as ElementImpl;
  }

  /**
   * Return the enclosing unit element (which might be the same as `this`), or
   * `null` if this element is not contained in any compilation unit.
   */
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement?.enclosingUnit;
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
  bool get isFactory {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isFactory) {
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

  /**
   * Return `true` if this element is resynthesized from a summary.
   */
  bool get isResynthesized => enclosingUnit?.resynthesizerContext != null;

  @override
  bool get isSynthetic => hasModifier(Modifier.SYNTHETIC);

  /**
   * Set whether this element is synthetic.
   */
  void set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  @override
  LibraryElement get library =>
      getAncestor((element) => element is LibraryElement);

  @override
  Source get librarySource => library?.source;

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

  List<ElementAnnotation> get metadata {
    return _metadata ?? const <ElementAnnotation>[];
  }

  void set metadata(List<ElementAnnotation> metadata) {
    assert(!isResynthesized);
    _metadata = metadata;
  }

  @override
  String get name => _name;

  /**
   * Changes the name of this element.
   */
  void set name(String name) {
    this._name = name;
  }

  @override
  int get nameLength => displayName != null ? displayName.length : 0;

  @override
  int get nameOffset => _nameOffset;

  /**
   * Sets the offset of the name of this element in the file that contains the
   * declaration of this element.
   */
  void set nameOffset(int offset) {
    _nameOffset = offset;
  }

  @override
  Source get source {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.source;
  }

  /**
   * Return the context to resolve type parameters in, or `null` if neither this
   * element nor any of its ancestors is of a kind that can declare type
   * parameters.
   */
  TypeParameterizedElementMixin get typeParameterContext {
    return _enclosingElement?.typeParameterContext;
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

  /**
   * Set this element as the enclosing element for given [elements].
   */
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      (element as ElementImpl)._enclosingElement = this;
    }
  }

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) {
    Element ancestor = _enclosingElement;
    while (ancestor != null && !predicate(ancestor)) {
      ancestor = ancestor.enclosingElement;
    }
    return ancestor as E;
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
      BooleanArray.get(_modifiers, modifier.ordinal);

  @override
  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(name)) {
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
    assert(!isResynthesized);
    _codeOffset = offset;
    _codeLength = length;
  }

  /**
   * Set whether the given [modifier] is associated with this element to
   * correspond to the given [value].
   */
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.set(_modifiers, modifier.ordinal, value);
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
   * Return annotations for the given [unlinkedConsts] in the [unit].
   */
  List<ElementAnnotation> _buildAnnotations(
      CompilationUnitElementImpl unit, List<UnlinkedExpr> unlinkedConsts) {
    int length = unlinkedConsts.length;
    if (length != 0) {
      List<ElementAnnotation> annotations = new List<ElementAnnotation>(length);
      ResynthesizerContext context = unit.resynthesizerContext;
      for (int i = 0; i < length; i++) {
        annotations[i] = context.buildAnnotation(this, unlinkedConsts[i]);
      }
      return annotations;
    } else {
      return const <ElementAnnotation>[];
    }
  }

  /**
   * If the element associated with the given [type] is a generic function type
   * element, then make it a child of this element. Return the [type] as a
   * convenience.
   */
  DartType _checkElementOfType(DartType type) {
    Element element = type?.element;
    if (element is GenericFunctionTypeElementImpl &&
        element.enclosingElement == null) {
      element.enclosingElement = this;
    }
    return type;
  }

  /**
   * If the given [type] is a generic function type, then the element associated
   * with the type is implicitly a child of this element and should be visted by
   * the given [visitor].
   */
  void _safelyVisitPossibleChild(DartType type, ElementVisitor visitor) {
    Element element = type?.element;
    if (element is GenericFunctionTypeElementImpl) {
      element.accept(visitor);
    }
  }

  static int findElementIndexUsingIdentical(List items, Object item) {
    int length = items.length;
    for (int i = 0; i < length; i++) {
      if (identical(items[i], item)) {
        return i;
      }
    }
    throw new StateError('Unable to find $item in $items');
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
 * An [AbstractClassElementImpl] which is an enum.
 */
class EnumElementImpl extends AbstractClassElementImpl {
  /**
   * The unlinked representation of the enum in the summary.
   */
  final UnlinkedEnum _unlinkedEnum;

  /**
   * The type defined by the enum.
   */
  InterfaceType _type;

  /**
   * Initialize a newly created class element to have the given [name] at the
   * given [offset] in the file that contains the declaration of this element.
   */
  EnumElementImpl(String name, int offset)
      : _unlinkedEnum = null,
        super(name, offset);

  /**
   * Initialize a newly created class element to have the given [name].
   */
  EnumElementImpl.forNode(Identifier name)
      : _unlinkedEnum = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  EnumElementImpl.forSerialized(
      this._unlinkedEnum, CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  /**
   * Set whether this class is abstract.
   */
  void set abstract(bool isAbstract) {
    _assertNotResynthesized(_unlinkedEnum);
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_unlinkedEnum != null && _accessors == null) {
      _resynthesizeFieldsAndPropertyAccessors();
    }
    return _accessors ?? const <PropertyAccessorElement>[];
  }

  @override
  void set accessors(List<PropertyAccessorElement> accessors) {
    _assertNotResynthesized(_unlinkedEnum);
    super.accessors = accessors;
  }

  @override
  List<InterfaceType> get allSupertypes => <InterfaceType>[supertype];

  @override
  int get codeLength {
    if (_unlinkedEnum != null) {
      return _unlinkedEnum.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedEnum != null) {
      return _unlinkedEnum.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  List<ConstructorElement> get constructors {
    // The equivalent code for enums in the spec shows a single constructor,
    // but that constructor is not callable (since it is a compile-time error
    // to subclass, mix-in, implement, or explicitly instantiate an enum).
    // So we represent this as having no constructors.
    return const <ConstructorElement>[];
  }

  @override
  String get documentationComment {
    if (_unlinkedEnum != null) {
      return _unlinkedEnum?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  @override
  List<FieldElement> get fields {
    if (_unlinkedEnum != null && _fields == null) {
      _resynthesizeFieldsAndPropertyAccessors();
    }
    return _fields ?? const <FieldElement>[];
  }

  @override
  void set fields(List<FieldElement> fields) {
    _assertNotResynthesized(_unlinkedEnum);
    super.fields = fields;
  }

  @override
  bool get hasNonFinalField => false;

  @override
  bool get hasReferenceToSuper => false;

  @override
  bool get hasStaticMember => true;

  @override
  List<InterfaceType> get interfaces => const <InterfaceType>[];

  @override
  bool get isAbstract => false;

  @override
  bool get isEnum => true;

  @override
  bool get isMixinApplication => false;

  @override
  bool get isOrInheritsProxy => false;

  @override
  bool get isProxy => false;

  @override
  bool get isValidMixin => false;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedEnum != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedEnum.annotations);
    }
    return super.metadata;
  }

  @override
  List<MethodElement> get methods => const <MethodElement>[];

  @override
  List<InterfaceType> get mixins => const <InterfaceType>[];

  @override
  String get name {
    if (_unlinkedEnum != null) {
      return _unlinkedEnum.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedEnum != null && _unlinkedEnum.nameOffset != 0) {
      return _unlinkedEnum.nameOffset;
    }
    return offset;
  }

  @override
  InterfaceType get supertype => context.typeProvider.objectType;

  @override
  InterfaceType get type {
    if (_type == null) {
      InterfaceTypeImpl type = new InterfaceTypeImpl(this);
      type.typeArguments = const <DartType>[];
      _type = type;
    }
    return _type;
  }

  @override
  List<TypeParameterElement> get typeParameters =>
      const <TypeParameterElement>[];

  @override
  ConstructorElement get unnamedConstructor => null;

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write('enum ');
    String name = displayName;
    if (name == null) {
      buffer.write("{unnamed enum}");
    } else {
      buffer.write(name);
    }
  }

  @override
  MethodElement getMethod(String name) => null;

  @override
  ConstructorElement getNamedConstructor(String name) => null;

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) => false;

  void _resynthesizeFieldsAndPropertyAccessors() {
    List<FieldElementImpl> fields = <FieldElementImpl>[];
    // Build the 'index' field.
    fields.add(new FieldElementImpl('index', -1)
      ..enclosingElement = this
      ..isSynthetic = true
      ..isFinal = true
      ..type = context.typeProvider.intType);
    // Build the 'values' field.
    fields.add(new ConstFieldElementImpl_EnumValues(this));
    // Build fields for all enum constants.
    for (int i = 0; i < _unlinkedEnum.values.length; i++) {
      UnlinkedEnumValue unlinkedValue = _unlinkedEnum.values[i];
      ConstFieldElementImpl_EnumValue field =
          new ConstFieldElementImpl_EnumValue(this, unlinkedValue, i);
      fields.add(field);
    }
    // done
    _fields = fields;
    _accessors = fields
        .map((FieldElementImpl field) =>
            new PropertyAccessorElementImpl_ImplicitGetter(field)
              ..enclosingElement = this)
        .toList(growable: false);
  }
}

/**
 * A base class for concrete implementations of an [ExecutableElement].
 */
abstract class ExecutableElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements ExecutableElement {
  /**
   * The unlinked representation of the executable in the summary.
   */
  final UnlinkedExecutable serializedExecutable;

  /**
   * A list containing all of the functions defined within this executable
   * element.
   */
  List<FunctionElement> _functions;

  /**
   * A list containing all of the parameters defined by this executable element.
   */
  List<ParameterElement> _parameters;

  /**
   * The declared return type of this executable element.
   */
  DartType _declaredReturnType;

  /**
   * The inferred return type of this executable element.
   */
  DartType _returnType;

  /**
   * The type of function defined by this executable element.
   */
  FunctionType _type;

  /**
   * Initialize a newly created executable element to have the given [name] and
   * [offset].
   */
  ExecutableElementImpl(String name, int offset)
      : serializedExecutable = null,
        super(name, offset);

  /**
   * Initialize a newly created executable element to have the given [name].
   */
  ExecutableElementImpl.forNode(Identifier name)
      : serializedExecutable = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  ExecutableElementImpl.forSerialized(
      this.serializedExecutable, ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  /**
   * Set whether this executable element's body is asynchronous.
   */
  void set asynchronous(bool isAsynchronous) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  @override
  int get codeLength {
    if (serializedExecutable != null) {
      return serializedExecutable.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (serializedExecutable != null) {
      return serializedExecutable.codeRange?.offset;
    }
    return super.codeOffset;
  }

  void set declaredReturnType(DartType returnType) {
    _assertNotResynthesized(serializedExecutable);
    _declaredReturnType = _checkElementOfType(returnType);
  }

  @override
  String get displayName {
    if (serializedExecutable != null) {
      return serializedExecutable.name;
    }
    return super.displayName;
  }

  @override
  String get documentationComment {
    if (serializedExecutable != null) {
      return serializedExecutable?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  /**
   * Set whether this executable element is external.
   */
  void set external(bool isExternal) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  List<FunctionElement> get functions {
    if (serializedExecutable != null) {
      _functions ??= FunctionElementImpl.resynthesizeList(
          this, serializedExecutable.localFunctions);
    }
    return _functions ?? const <FunctionElement>[];
  }

  /**
   * Set the functions defined within this executable element to the given
   * [functions].
   */
  void set functions(List<FunctionElement> functions) {
    _assertNotResynthesized(serializedExecutable);
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._functions = functions;
  }

  /**
   * Set whether this method's body is a generator.
   */
  void set generator(bool isGenerator) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get hasImplicitReturnType {
    if (serializedExecutable != null) {
      return serializedExecutable.returnType == null &&
          serializedExecutable.kind != UnlinkedExecutableKind.constructor;
    }
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /**
   * Set whether this executable element has an implicit return type.
   */
  void set hasImplicitReturnType(bool hasImplicitReturnType) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  @override
  bool get isAbstract {
    if (serializedExecutable != null) {
      return serializedExecutable.isAbstract;
    }
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isAsynchronous {
    if (serializedExecutable != null) {
      return serializedExecutable.isAsynchronous;
    }
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  @override
  bool get isExternal {
    if (serializedExecutable != null) {
      return serializedExecutable.isExternal;
    }
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isGenerator {
    if (serializedExecutable != null) {
      return serializedExecutable.isGenerator;
    }
    return hasModifier(Modifier.GENERATOR);
  }

  @override
  bool get isOperator => false;

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  List<ElementAnnotation> get metadata {
    if (serializedExecutable != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, serializedExecutable.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (serializedExecutable != null) {
      return serializedExecutable.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && serializedExecutable != null) {
      return serializedExecutable.nameOffset;
    }
    return offset;
  }

  @override
  List<ParameterElement> get parameters {
    if (serializedExecutable != null) {
      _parameters ??= ParameterElementImpl.resynthesizeList(
          serializedExecutable.parameters, this);
    }
    return _parameters ?? const <ParameterElement>[];
  }

  /**
   * Set the parameters defined by this executable element to the given
   * [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    _assertNotResynthesized(serializedExecutable);
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  @override
  DartType get returnType {
    if (serializedExecutable != null &&
        _declaredReturnType == null &&
        _returnType == null) {
      bool isSetter =
          serializedExecutable.kind == UnlinkedExecutableKind.setter;
      _returnType = enclosingUnit.resynthesizerContext
          .resolveLinkedType(this, serializedExecutable.inferredReturnTypeSlot);
      _declaredReturnType = enclosingUnit.resynthesizerContext.resolveTypeRef(
          this, serializedExecutable.returnType,
          defaultVoid: isSetter && context.analysisOptions.strongMode,
          declaredType: true);
    }
    return _returnType ?? _declaredReturnType;
  }

  void set returnType(DartType returnType) {
    _assertNotResynthesized(serializedExecutable);
    _returnType = _checkElementOfType(returnType);
  }

  @override
  FunctionType get type {
    if (serializedExecutable != null) {
      _type ??= new FunctionTypeImpl.elementWithNameAndArgs(
          this, null, allEnclosingTypeParameterTypes, false);
    }
    return _type;
  }

  void set type(FunctionType type) {
    _assertNotResynthesized(serializedExecutable);
    _type = type;
  }

  /**
   * Set the type parameters defined by this executable element to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    _assertNotResynthesized(serializedExecutable);
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameterElements = typeParameters;
  }

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      serializedExecutable?.typeParameters;

  @override
  void appendTo(StringBuffer buffer) {
    if (this.kind != ElementKind.GETTER) {
      int typeParameterCount = typeParameters.length;
      if (typeParameterCount > 0) {
        buffer.write('<');
        for (int i = 0; i < typeParameterCount; i++) {
          if (i > 0) {
            buffer.write(", ");
          }
          (typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
        }
        buffer.write('>');
      }
      buffer.write("(");
      String closing = null;
      ParameterKind kind = ParameterKind.REQUIRED;
      int parameterCount = parameters.length;
      for (int i = 0; i < parameterCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        ParameterElement parameter = parameters[i];
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
    for (ParameterElement parameter in parameters) {
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
    _safelyVisitPossibleChild(returnType, visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/**
 * A concrete implementation of an [ExportElement].
 */
class ExportElementImpl extends UriReferencedElementImpl
    implements ExportElement {
  /**
   * The unlinked representation of the export in the summary.
   */
  final UnlinkedExportPublic _unlinkedExportPublic;

  /**
   * The unlinked representation of the export in the summary.
   */
  final UnlinkedExportNonPublic _unlinkedExportNonPublic;

  /**
   * The library that is exported from this library by this export directive.
   */
  LibraryElement _exportedLibrary;

  /**
   * The combinators that were specified as part of the export directive in the
   * order in which they were specified.
   */
  List<NamespaceCombinator> _combinators;

  /**
   * The URI that was selected based on the [context] declared variables.
   */
  String _selectedUri;

  /**
   * Initialize a newly created export element at the given [offset].
   */
  ExportElementImpl(int offset)
      : _unlinkedExportPublic = null,
        _unlinkedExportNonPublic = null,
        super(null, offset);

  /**
   * Initialize using the given serialized information.
   */
  ExportElementImpl.forSerialized(this._unlinkedExportPublic,
      this._unlinkedExportNonPublic, LibraryElementImpl enclosingLibrary)
      : super.forSerialized(enclosingLibrary);

  @override
  List<NamespaceCombinator> get combinators {
    if (_unlinkedExportPublic != null && _combinators == null) {
      _combinators = ImportElementImpl
          ._buildCombinators(_unlinkedExportPublic.combinators);
    }
    return _combinators ?? const <NamespaceCombinator>[];
  }

  void set combinators(List<NamespaceCombinator> combinators) {
    _assertNotResynthesized(_unlinkedExportPublic);
    _combinators = combinators;
  }

  @override
  LibraryElement get exportedLibrary {
    if (_unlinkedExportNonPublic != null && _exportedLibrary == null) {
      LibraryElementImpl library = enclosingElement as LibraryElementImpl;
      _exportedLibrary = library.resynthesizerContext.buildExportedLibrary(uri);
    }
    return _exportedLibrary;
  }

  void set exportedLibrary(LibraryElement exportedLibrary) {
    _assertNotResynthesized(_unlinkedExportNonPublic);
    _exportedLibrary = exportedLibrary;
  }

  @override
  String get identifier => exportedLibrary.name;

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedExportNonPublic != null) {
      return _metadata ??= _buildAnnotations(
          library.definingCompilationUnit as CompilationUnitElementImpl,
          _unlinkedExportNonPublic.annotations);
    }
    return super.metadata;
  }

  void set metadata(List<ElementAnnotation> metadata) {
    _assertNotResynthesized(_unlinkedExportNonPublic);
    super.metadata = metadata;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedExportNonPublic != null) {
      return _unlinkedExportNonPublic.offset;
    }
    return offset;
  }

  @override
  String get uri {
    if (_unlinkedExportPublic != null) {
      return _selectedUri ??= _selectUri(
          _unlinkedExportPublic.uri, _unlinkedExportPublic.configurations);
    }
    return super.uri;
  }

  @override
  void set uri(String uri) {
    _assertNotResynthesized(_unlinkedExportPublic);
    super.uri = uri;
  }

  @override
  int get uriEnd {
    if (_unlinkedExportNonPublic != null) {
      return _unlinkedExportNonPublic.uriEnd;
    }
    return super.uriEnd;
  }

  @override
  void set uriEnd(int uriEnd) {
    _assertNotResynthesized(_unlinkedExportNonPublic);
    super.uriEnd = uriEnd;
  }

  @override
  int get uriOffset {
    if (_unlinkedExportNonPublic != null) {
      return _unlinkedExportNonPublic.uriOffset;
    }
    return super.uriOffset;
  }

  @override
  void set uriOffset(int uriOffset) {
    _assertNotResynthesized(_unlinkedExportNonPublic);
    super.uriOffset = uriOffset;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitExportElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("export ");
    LibraryElementImpl.getImpl(exportedLibrary).appendTo(buffer);
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

  /**
   * Initialize using the given serialized information.
   */
  FieldElementImpl.forSerialized(
      UnlinkedVariable unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedVariable, enclosingElement);

  /**
   * Initialize using the given serialized information.
   */
  factory FieldElementImpl.forSerializedFactory(
      UnlinkedVariable unlinkedVariable, ClassElementImpl enclosingClass) {
    if (unlinkedVariable.initializer?.bodyExpr != null &&
        (unlinkedVariable.isConst ||
            unlinkedVariable.isFinal && !unlinkedVariable.isStatic)) {
      return new ConstFieldElementImpl.forSerialized(
          unlinkedVariable, enclosingClass);
    } else {
      return new FieldElementImpl.forSerialized(
          unlinkedVariable, enclosingClass);
    }
  }

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  /**
   * Return `true` if this field was explicitly marked as being covariant.
   */
  bool get isCovariant {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.isCovariant;
    }
    return hasModifier(Modifier.COVARIANT);
  }

  /**
   * Set whether this field is explicitly marked as being covariant.
   */
  void set isCovariant(bool isCovariant) {
    _assertNotResynthesized(_unlinkedVariable);
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isEnumConstant =>
      enclosingElement != null && enclosingElement.isEnum && !isSynthetic;

  @override
  bool get isStatic {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.isStatic;
    }
    return hasModifier(Modifier.STATIC);
  }

  /**
   * Set whether this field is static.
   */
  void set isStatic(bool isStatic) {
    _assertNotResynthesized(_unlinkedVariable);
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  bool get isVirtual => true;

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

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
  FieldElement _field;

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

  /**
   * Initialize using the given serialized information.
   */
  FieldFormalParameterElementImpl.forSerialized(
      UnlinkedParam unlinkedParam, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedParam, enclosingElement);

  @override
  FieldElement get field {
    if (_unlinkedParam != null && _field == null) {
      Element enclosingConstructor = enclosingElement;
      if (enclosingConstructor is ConstructorElement) {
        Element enclosingClass = enclosingConstructor.enclosingElement;
        if (enclosingClass is ClassElement) {
          FieldElement field = enclosingClass.getField(_unlinkedParam.name);
          if (field != null && !field.isSynthetic) {
            _field = field;
          }
        }
      }
    }
    return _field;
  }

  void set field(FieldElement field) {
    _assertNotResynthesized(_unlinkedParam);
    _field = field;
  }

  @override
  bool get isInitializingFormal => true;

  @override
  DartType get type {
    if (_unlinkedParam != null && _unlinkedParam.type == null) {
      _type ??= field?.type ?? DynamicTypeImpl.instance;
    }
    return super.type;
  }

  @override
  void set type(DartType type) {
    _assertNotResynthesized(_unlinkedParam);
    _type = type;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
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
   * [nameOffset]. This is used for function expressions, that have no name.
   */
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  /**
   * Initialize using the given serialized information.
   */
  FunctionElementImpl.forSerialized(
      UnlinkedExecutable serializedExecutable, ElementImpl enclosingElement)
      : super.forSerialized(serializedExecutable, enclosingElement);

  /**
   * Synthesize an unnamed function element that takes [parameters] and returns
   * [returnType].
   */
  FunctionElementImpl.synthetic(
      List<ParameterElement> parameters, DartType returnType)
      : super("", -1) {
    isSynthetic = true;
    this.returnType = returnType;
    this.parameters = parameters;

    type = new FunctionTypeImpl(this);
  }

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext {
    return (enclosingElement as ElementImpl).typeParameterContext;
  }

  @override
  String get identifier {
    String identifier = super.identifier;
    Element enclosing = this.enclosingElement;
    if (enclosing is ExecutableElement) {
      int id =
          ElementImpl.findElementIndexUsingIdentical(enclosing.functions, this);
      identifier += "@$id";
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
    if (serializedExecutable != null) {
      if (serializedExecutable.visibleLength == 0) {
        return null;
      }
      return new SourceRange(serializedExecutable.visibleOffset,
          serializedExecutable.visibleLength);
    }
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFunctionElement(this);

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
    _assertNotResynthesized(serializedExecutable);
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
    this._typeParameterElements = typeParameters;
  }

  /**
   * Create and return [FunctionElement]s for the given [unlinkedFunctions].
   */
  static List<FunctionElement> resynthesizeList(
      ExecutableElementImpl executableElement,
      List<UnlinkedExecutable> unlinkedFunctions) {
    int length = unlinkedFunctions.length;
    if (length != 0) {
      List<FunctionElement> elements = new List<FunctionElement>(length);
      for (int i = 0; i < length; i++) {
        elements[i] = new FunctionElementImpl.forSerialized(
            unlinkedFunctions[i], executableElement);
      }
      return elements;
    } else {
      return const <FunctionElement>[];
    }
  }
}

/**
 * Implementation of [FunctionElementImpl] for a function typed parameter.
 */
class FunctionElementImpl_forFunctionTypedParameter
    extends FunctionElementImpl {
  @override
  final CompilationUnitElementImpl enclosingUnit;

  /**
   * The enclosing function typed [ParameterElementImpl].
   */
  final ParameterElementImpl _parameter;

  FunctionElementImpl_forFunctionTypedParameter(
      this.enclosingUnit, this._parameter)
      : super('', -1);

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      _parameter.typeParameterContext;

  @override
  bool get isSynthetic => true;
}

/**
 * Implementation of [FunctionElementImpl] for a synthetic function element
 * that was synthesized by a LUB computation.
 */
class FunctionElementImpl_forLUB extends FunctionElementImpl {
  final EntityRef _entityRef;

  FunctionElementImpl_forLUB(ElementImpl enclosingElement, this._entityRef)
      : super.forSerialized(null, enclosingElement);

  @override
  bool get isSynthetic => true;

  @override
  List<ParameterElement> get parameters {
    return _parameters ??= ParameterElementImpl
        .resynthesizeList(_entityRef.syntheticParams, this, synthetic: true);
  }

  @override
  void set parameters(List<ParameterElement> parameters) {
    assert(false);
  }

  @override
  DartType get returnType {
    return _returnType ??= enclosingUnit.resynthesizerContext
        .resolveTypeRef(this, _entityRef.syntheticReturnType);
  }

  @override
  void set returnType(DartType returnType) {
    assert(false);
  }

  @override
  FunctionType get type {
    return _type ??=
        new FunctionTypeImpl.elementWithNameAndArgs(this, null, null, false);
  }

  @override
  void set type(FunctionType type) {
    assert(false);
  }
}

/**
 * A concrete implementation of a [FunctionTypeAliasElement].
 */
class FunctionTypeAliasElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements FunctionTypeAliasElement {
  /**
   * The unlinked representation of the type in the summary.
   */
  final UnlinkedTypedef _unlinkedTypedef;

  /**
   * A list containing all of the parameters defined by this type alias.
   */
  List<ParameterElement> _parameters;

  /**
   * The return type defined by this type alias.
   */
  DartType _returnType;

  /**
   * The type of function defined by this type alias.
   */
  FunctionType _type;

  /**
   * Initialize a newly created type alias element to have the given name.
   *
   * [name] the name of this element
   * [nameOffset] the offset of the name of this element in the file that
   *    contains the declaration of this element
   */
  FunctionTypeAliasElementImpl(String name, int nameOffset)
      : _unlinkedTypedef = null,
        super(name, nameOffset);

  /**
   * Initialize a newly created type alias element to have the given [name].
   */
  FunctionTypeAliasElementImpl.forNode(Identifier name)
      : _unlinkedTypedef = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  FunctionTypeAliasElementImpl.forSerialized(
      this._unlinkedTypedef, CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  @override
  int get codeLength {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  String get displayName => name;

  @override
  String get documentationComment {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementImpl get enclosingUnit =>
      _enclosingElement as CompilationUnitElementImpl;

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedTypedef != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedTypedef.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedTypedef != null) {
      return _unlinkedTypedef.nameOffset;
    }
    return offset;
  }

  @override
  List<ParameterElement> get parameters {
    if (_unlinkedTypedef != null) {
      _parameters ??= ParameterElementImpl.resynthesizeList(
          _unlinkedTypedef.parameters, this);
    }
    return _parameters ?? const <ParameterElement>[];
  }

  /**
   * Set the parameters defined by this type alias to the given [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    _assertNotResynthesized(_unlinkedTypedef);
    if (parameters != null) {
      for (ParameterElement parameter in parameters) {
        (parameter as ParameterElementImpl).enclosingElement = this;
      }
    }
    this._parameters = parameters;
  }

  @override
  DartType get returnType {
    if (_unlinkedTypedef != null && _returnType == null) {
      _returnType = enclosingUnit.resynthesizerContext.resolveTypeRef(
          this, _unlinkedTypedef.returnType,
          declaredType: true);
    }
    return _returnType;
  }

  void set returnType(DartType returnType) {
    _assertNotResynthesized(_unlinkedTypedef);
    _returnType = _checkElementOfType(returnType);
  }

  @override
  FunctionType get type {
    if (_unlinkedTypedef != null && _type == null) {
      _type = new FunctionTypeImpl.forTypedef(this);
    }
    return _type;
  }

  void set type(FunctionType type) {
    _assertNotResynthesized(_unlinkedTypedef);
    _type = type;
  }

  /**
   * Set the type parameters defined for this type to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    _assertNotResynthesized(_unlinkedTypedef);
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameterElements = typeParameters;
  }

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedTypedef?.typeParameters;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFunctionTypeAliasElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("typedef ");
    buffer.write(displayName);
    List<TypeParameterElement> typeParameters = this.typeParameters;
    int typeParameterCount = typeParameters.length;
    if (typeParameterCount > 0) {
      buffer.write("<");
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
      }
      buffer.write(">");
    }
    buffer.write("(");
    List<ParameterElement> parameterList = parameters;
    int parameterCount = parameterList.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      (parameterList[i] as ParameterElementImpl).appendTo(buffer);
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
    for (ParameterElement parameter in parameters) {
      ParameterElementImpl parameterImpl = parameter;
      if (parameterImpl.identifier == identifier) {
        return parameterImpl;
      }
    }
    for (TypeParameterElement typeParameter in typeParameters) {
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
    _safelyVisitPossibleChild(returnType, visitor);
    safelyVisitChildren(parameters, visitor);
    safelyVisitChildren(typeParameters, visitor);
  }
}

/**
 * The element used for a generic function type.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class GenericFunctionTypeElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements GenericFunctionTypeElement {
  /**
   * The unlinked representation of the generic function type in the summary.
   */
  EntityRef _entityRef;

  /**
   * The declared return type of the function.
   */
  DartType _returnType;

  /**
   * The elements representing the parameters of the function.
   */
  List<ParameterElement> _parameters;

  /**
   * The type defined by this element.
   */
  FunctionType _type;

  /**
   * Initialize a newly created function element to have no name and the given
   * [nameOffset]. This is used for function expressions, that have no name.
   */
  GenericFunctionTypeElementImpl.forOffset(int nameOffset)
      : super("", nameOffset);

  /**
   * Initialize from serialized information.
   */
  GenericFunctionTypeElementImpl.forSerialized(
      ElementImpl enclosingElement, this._entityRef)
      : super.forSerialized(enclosingElement);

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext {
    return _enclosingElement.typeParameterContext;
  }

  @override
  String get identifier => '-';

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  List<ParameterElement> get parameters {
    if (_entityRef != null) {
      _parameters ??= ParameterElementImpl.resynthesizeList(
          _entityRef.syntheticParams, this);
    }
    return _parameters ?? const <ParameterElement>[];
  }

  /**
   * Set the parameters defined by this function type element to the given
   * [parameters].
   */
  void set parameters(List<ParameterElement> parameters) {
    _assertNotResynthesized(_entityRef);
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  @override
  DartType get returnType {
    if (_entityRef != null && _returnType == null) {
      _returnType = enclosingUnit.resynthesizerContext.resolveTypeRef(
          this, _entityRef.syntheticReturnType,
          defaultVoid: false, declaredType: true);
    }
    return _returnType;
  }

  /**
   * Set the return type defined by this function type element to the given
   * [returnType].
   */
  void set returnType(DartType returnType) {
    _assertNotResynthesized(_entityRef);
    _returnType = _checkElementOfType(returnType);
  }

  @override
  FunctionType get type {
    if (_entityRef != null) {
      _type ??= new FunctionTypeImpl.elementWithNameAndArgs(
          this, null, allEnclosingTypeParameterTypes, false);
    }
    return _type;
  }

  /**
   * Set the function type defined by this function type element to the given
   * [type].
   */
  void set type(FunctionType type) {
    _assertNotResynthesized(_entityRef);
    _type = type;
  }

  /**
   * Set the type parameters defined by this function type element to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    _assertNotResynthesized(_entityRef);
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameterElements = typeParameters;
  }

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams => _entityRef?.typeParameters;

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @override
  void appendTo(StringBuffer buffer) {
    DartType type = returnType;
    if (type is TypeImpl) {
      type.appendTo(buffer, new HashSet<TypeImpl>());
      buffer.write(' Function');
    } else {
      buffer.write('Function');
    }
    List<TypeParameterElement> typeParams = typeParameters;
    int typeParameterCount = typeParams.length;
    if (typeParameterCount > 0) {
      buffer.write('<');
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          buffer.write(', ');
        }
        (typeParams[i] as TypeParameterElementImpl).appendTo(buffer);
      }
      buffer.write('>');
    }
    List<ParameterElement> params = parameters;
    buffer.write('(');
    for (int i = 0; i < params.length; i++) {
      if (i > 0) {
        buffer.write(', ');
      }
      (params[i] as ParameterElementImpl).appendTo(buffer);
    }
    buffer.write(')');
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitPossibleChild(returnType, visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/**
 * A function type alias of the form
 *     `typedef` identifier typeParameters = genericFunctionType;
 *
 * Clients may not extend, implement or mix-in this class.
 */
class GenericTypeAliasElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements GenericTypeAliasElement {
  /**
   * The unlinked representation of the type in the summary.
   */
  final UnlinkedTypedef _unlinkedTypedef;

  /**
   * The element representing the generic function type.
   */
  GenericFunctionTypeElement _function;

  /**
   * The type of function defined by this type alias.
   */
  FunctionType _type;

  /**
   * Initialize a newly created type alias element to have the given [name].
   */
  GenericTypeAliasElementImpl.forNode(Identifier name)
      : _unlinkedTypedef = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  GenericTypeAliasElementImpl.forSerialized(
      this._unlinkedTypedef, CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  @override
  int get codeLength {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  String get displayName => name;

  @override
  String get documentationComment {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementImpl get enclosingUnit =>
      _enclosingElement as CompilationUnitElementImpl;

  @override
  GenericFunctionTypeElement get function {
    if (_function == null && _unlinkedTypedef != null) {
      DartType type = enclosingUnit.resynthesizerContext.resolveTypeRef(
          this, _unlinkedTypedef.returnType,
          declaredType: true);
      if (type is FunctionType) {
        Element element = type.element;
        if (element is GenericFunctionTypeElement) {
          (element as GenericFunctionTypeElementImpl).enclosingElement = this;
          _function = element;
        }
      }
    }
    return _function;
  }

  /**
   * Set the function element representing the generic function type on the
   * right side of the equals to the given [function].
   */
  void set function(GenericFunctionTypeElement function) {
    _assertNotResynthesized(_unlinkedTypedef);
    if (function != null) {
      (function as GenericFunctionTypeElementImpl).enclosingElement = this;
    }
    _function = function;
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedTypedef != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedTypedef.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (_unlinkedTypedef != null) {
      return _unlinkedTypedef.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedTypedef != null) {
      return _unlinkedTypedef.nameOffset;
    }
    return offset;
  }

  @override
  List<ParameterElement> get parameters =>
      function?.parameters ?? const <ParameterElement>[];

  @override
  DartType get returnType => function?.returnType;

  @override
  FunctionType get type {
    if (_unlinkedTypedef != null && _type == null) {
      _type = new FunctionTypeImpl.forTypedef(this);
    }
    return _type;
  }

  void set type(FunctionType type) {
    _assertNotResynthesized(_unlinkedTypedef);
    _type = type;
  }

  /**
   * Set the type parameters defined for this type to the given
   * [typeParameters].
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    _assertNotResynthesized(_unlinkedTypedef);
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameterElements = typeParameters;
  }

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedTypedef?.typeParameters;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFunctionTypeAliasElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("typedef ");
    buffer.write(displayName);
    var typeParameters = this.typeParameters;
    int typeParameterCount = typeParameters.length;
    if (typeParameterCount > 0) {
      buffer.write("<");
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          buffer.write(", ");
        }
        (typeParameters[i] as TypeParameterElementImpl).appendTo(buffer);
      }
      buffer.write(">");
    }
    buffer.write(" = ");
    if (function != null) {
      (function as ElementImpl).appendTo(buffer);
    }
  }

  @override
  GenericTypeAlias computeNode() =>
      getNodeMatching((node) => node is GenericTypeAlias);

  @override
  ElementImpl getChild(String identifier) {
    for (TypeParameterElement typeParameter in typeParameters) {
      TypeParameterElementImpl typeParameterImpl = typeParameter;
      if (typeParameterImpl.identifier == identifier) {
        return typeParameterImpl;
      }
    }
    return null;
  }

  /**
   * Return the type of the function defined by this typedef after substituting
   * the given [typeArguments] for the type parameters defined for this typedef
   * (but not the type parameters defined by the function). If the number of
   * [typeArguments] does not match the number of type parameters, then
   * `dynamic` will be used in place of each of the type arguments.
   */
  FunctionType typeAfterSubstitution(List<DartType> typeArguments) {
    GenericFunctionTypeElement function = this.function;
    if (function == null) {
      return null;
    }
    FunctionType functionType = function.type;
    List<TypeParameterElement> parameterElements = typeParameters;
    List<DartType> parameterTypes =
        TypeParameterTypeImpl.getTypes(parameterElements);
    int parameterCount = parameterTypes.length;
    if (typeArguments == null ||
        parameterElements.length != typeArguments.length) {
      DartType dynamicType = DynamicElementImpl.instance.type;
      typeArguments = new List<DartType>.filled(parameterCount, dynamicType);
    }
    return functionType.substitute2(typeArguments, parameterTypes);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(typeParameters, visitor);
    function?.accept(visitor);
  }
}

/**
 * A concrete implementation of a [HideElementCombinator].
 */
class HideElementCombinatorImpl implements HideElementCombinator {
  /**
   * The unlinked representation of the combinator in the summary.
   */
  final UnlinkedCombinator _unlinkedCombinator;

  /**
   * The names that are not to be made visible in the importing library even if
   * they are defined in the imported library.
   */
  List<String> _hiddenNames;

  HideElementCombinatorImpl() : _unlinkedCombinator = null;

  /**
   * Initialize using the given serialized information.
   */
  HideElementCombinatorImpl.forSerialized(this._unlinkedCombinator);

  @override
  List<String> get hiddenNames {
    if (_unlinkedCombinator != null) {
      _hiddenNames ??= _unlinkedCombinator.hides.toList(growable: false);
    }
    return _hiddenNames ?? const <String>[];
  }

  void set hiddenNames(List<String> hiddenNames) {
    _assertNotResynthesized(_unlinkedCombinator);
    _hiddenNames = hiddenNames;
  }

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
   * The unlinked representation of the import in the summary.
   */
  final UnlinkedImport _unlinkedImport;

  /**
   * The index of the dependency in the `imports` list.
   */
  final int _linkedDependency;

  /**
   * The offset of the prefix of this import in the file that contains the this
   * import directive, or `-1` if this import is synthetic.
   */
  int _prefixOffset = 0;

  /**
   * The library that is imported into this library by this import directive.
   */
  LibraryElement _importedLibrary;

  /**
   * The combinators that were specified as part of the import directive in the
   * order in which they were specified.
   */
  List<NamespaceCombinator> _combinators;

  /**
   * The prefix that was specified as part of the import directive, or `null` if
   * there was no prefix specified.
   */
  PrefixElement _prefix;

  /**
   * The URI that was selected based on the [context] declared variables.
   */
  String _selectedUri;

  /**
   * Initialize a newly created import element at the given [offset].
   * The offset may be `-1` if the import is synthetic.
   */
  ImportElementImpl(int offset)
      : _unlinkedImport = null,
        _linkedDependency = null,
        super(null, offset);

  /**
   * Initialize using the given serialized information.
   */
  ImportElementImpl.forSerialized(this._unlinkedImport, this._linkedDependency,
      LibraryElementImpl enclosingLibrary)
      : super.forSerialized(enclosingLibrary);

  @override
  List<NamespaceCombinator> get combinators {
    if (_unlinkedImport != null && _combinators == null) {
      _combinators = _buildCombinators(_unlinkedImport.combinators);
    }
    return _combinators ?? const <NamespaceCombinator>[];
  }

  void set combinators(List<NamespaceCombinator> combinators) {
    _assertNotResynthesized(_unlinkedImport);
    _combinators = combinators;
  }

  /**
   * Set whether this import is for a deferred library.
   */
  void set deferred(bool isDeferred) {
    _assertNotResynthesized(_unlinkedImport);
    setModifier(Modifier.DEFERRED, isDeferred);
  }

  @override
  String get identifier => "${importedLibrary.identifier}@$nameOffset";

  @override
  LibraryElement get importedLibrary {
    if (_linkedDependency != null) {
      if (_importedLibrary == null) {
        LibraryElementImpl library = enclosingElement as LibraryElementImpl;
        if (_linkedDependency == 0) {
          _importedLibrary = library;
        } else {
          _importedLibrary = library.resynthesizerContext
              .buildImportedLibrary(_linkedDependency);
        }
      }
    }
    return _importedLibrary;
  }

  void set importedLibrary(LibraryElement importedLibrary) {
    _assertNotResynthesized(_unlinkedImport);
    _importedLibrary = importedLibrary;
  }

  @override
  bool get isDeferred {
    if (_unlinkedImport != null) {
      return _unlinkedImport.isDeferred;
    }
    return hasModifier(Modifier.DEFERRED);
  }

  @override
  bool get isSynthetic {
    if (_unlinkedImport != null) {
      return _unlinkedImport.isImplicit;
    }
    return super.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedImport != null) {
      return _metadata ??= _buildAnnotations(
          library.definingCompilationUnit as CompilationUnitElementImpl,
          _unlinkedImport.annotations);
    }
    return super.metadata;
  }

  void set metadata(List<ElementAnnotation> metadata) {
    _assertNotResynthesized(_unlinkedImport);
    super.metadata = metadata;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedImport != null) {
      if (_unlinkedImport.isImplicit) {
        return -1;
      }
      return _unlinkedImport.offset;
    }
    return offset;
  }

  PrefixElement get prefix {
    if (_unlinkedImport != null) {
      if (_unlinkedImport.prefixReference != 0 && _prefix == null) {
        LibraryElementImpl library = enclosingElement as LibraryElementImpl;
        _prefix = new PrefixElementImpl.forSerialized(_unlinkedImport, library);
      }
    }
    return _prefix;
  }

  void set prefix(PrefixElement prefix) {
    _assertNotResynthesized(_unlinkedImport);
    _prefix = prefix;
  }

  @override
  int get prefixOffset {
    if (_unlinkedImport != null) {
      return _unlinkedImport.prefixOffset;
    }
    return _prefixOffset;
  }

  void set prefixOffset(int prefixOffset) {
    _assertNotResynthesized(_unlinkedImport);
    _prefixOffset = prefixOffset;
  }

  @override
  String get uri {
    if (_unlinkedImport != null) {
      if (_unlinkedImport.isImplicit) {
        return null;
      }
      return _selectedUri ??=
          _selectUri(_unlinkedImport.uri, _unlinkedImport.configurations);
    }
    return super.uri;
  }

  @override
  void set uri(String uri) {
    _assertNotResynthesized(_unlinkedImport);
    super.uri = uri;
  }

  @override
  int get uriEnd {
    if (_unlinkedImport != null) {
      if (_unlinkedImport.isImplicit) {
        return -1;
      }
      return _unlinkedImport.uriEnd;
    }
    return super.uriEnd;
  }

  @override
  void set uriEnd(int uriEnd) {
    _assertNotResynthesized(_unlinkedImport);
    super.uriEnd = uriEnd;
  }

  @override
  int get uriOffset {
    if (_unlinkedImport != null) {
      if (_unlinkedImport.isImplicit) {
        return -1;
      }
      return _unlinkedImport.uriOffset;
    }
    return super.uriOffset;
  }

  @override
  void set uriOffset(int uriOffset) {
    _assertNotResynthesized(_unlinkedImport);
    super.uriOffset = uriOffset;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitImportElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write("import ");
    LibraryElementImpl.getImpl(importedLibrary).appendTo(buffer);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    prefix?.accept(visitor);
  }

  static List<NamespaceCombinator> _buildCombinators(
      List<UnlinkedCombinator> unlinkedCombinators) {
    int length = unlinkedCombinators.length;
    if (length != 0) {
      List<NamespaceCombinator> combinators =
          new List<NamespaceCombinator>(length);
      for (int i = 0; i < length; i++) {
        UnlinkedCombinator unlinkedCombinator = unlinkedCombinators[i];
        combinators[i] = unlinkedCombinator.shows.isNotEmpty
            ? new ShowElementCombinatorImpl.forSerialized(unlinkedCombinator)
            : new HideElementCombinatorImpl.forSerialized(unlinkedCombinator);
      }
      return combinators;
    } else {
      return const <NamespaceCombinator>[];
    }
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
   * [_onSwitchStatement] should be `true` if this label is associated with a
   * `switch` statement and [_onSwitchMember] should be `true` if this label is
   * associated with a `switch` member.
   */
  LabelElementImpl.forNode(
      Identifier name, this._onSwitchStatement, this._onSwitchMember)
      : super.forNode(name);

  @override
  String get displayName => name;

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
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitLabelElement(this);
}

/**
 * A concrete implementation of a [LibraryElement].
 */
class LibraryElementImpl extends ElementImpl implements LibraryElement {
  /**
   * The analysis context in which this library is defined.
   */
  final AnalysisContext context;

  final LibraryResynthesizerContext resynthesizerContext;

  final UnlinkedUnit _unlinkedDefiningUnit;

  /**
   * The compilation unit that defines this library.
   */
  CompilationUnitElement _definingCompilationUnit;

  /**
   * The entry point for this library, or `null` if this library does not have
   * an entry point.
   */
  FunctionElement _entryPoint;

  /**
   * A list containing specifications of all of the imports defined in this
   * library.
   */
  List<ImportElement> _imports;

  /**
   * A list containing specifications of all of the exports defined in this
   * library.
   */
  List<ExportElement> _exports;

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
  Namespace _exportNamespace;

  /**
   * The public [Namespace] of this library, `null` if it has not been
   * computed yet.
   */
  Namespace _publicNamespace;

  /**
   * A bit-encoded form of the capabilities associated with this library.
   */
  int _resolutionCapabilities = 0;

  /**
   * The cached list of prefixes.
   */
  List<PrefixElement> _prefixes;

  /**
   * Initialize a newly created library element in the given [context] to have
   * the given [name] and [offset].
   */
  LibraryElementImpl(this.context, String name, int offset, this.nameLength)
      : resynthesizerContext = null,
        _unlinkedDefiningUnit = null,
        super(name, offset);

  /**
   * Initialize a newly created library element in the given [context] to have
   * the given [name].
   */
  LibraryElementImpl.forNode(this.context, LibraryIdentifier name)
      : nameLength = name != null ? name.length : 0,
        resynthesizerContext = null,
        _unlinkedDefiningUnit = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  LibraryElementImpl.forSerialized(this.context, String name, int offset,
      this.nameLength, this.resynthesizerContext, this._unlinkedDefiningUnit)
      : super.forSerialized(null) {
    _name = name;
    _nameOffset = offset;
    setResolutionCapability(
        LibraryResolutionCapability.resolvedTypeNames, true);
    setResolutionCapability(
        LibraryResolutionCapability.constantExpressions, true);
  }

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
  String get documentationComment {
    if (_unlinkedDefiningUnit != null) {
      return _unlinkedDefiningUnit?.libraryDocumentationComment?.text;
    }
    return super.documentationComment;
  }

  FunctionElement get entryPoint {
    if (resynthesizerContext != null) {
      _entryPoint ??= resynthesizerContext.findEntryPoint();
    }
    return _entryPoint;
  }

  void set entryPoint(FunctionElement entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  List<LibraryElement> get exportedLibraries {
    HashSet<LibraryElement> libraries = new HashSet<LibraryElement>();
    for (ExportElement element in exports) {
      LibraryElement library = element.exportedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return libraries.toList(growable: false);
  }

  @override
  Namespace get exportNamespace {
    if (resynthesizerContext != null) {
      _exportNamespace ??= resynthesizerContext.buildExportNamespace();
    }
    return _exportNamespace;
  }

  void set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  @override
  List<ExportElement> get exports {
    if (_unlinkedDefiningUnit != null && _exports == null) {
      List<UnlinkedExportNonPublic> unlinkedNonPublicExports =
          _unlinkedDefiningUnit.exports;
      List<UnlinkedExportPublic> unlinkedPublicExports =
          _unlinkedDefiningUnit.publicNamespace.exports;
      assert(
          _unlinkedDefiningUnit.exports.length == unlinkedPublicExports.length);
      int length = unlinkedNonPublicExports.length;
      if (length != 0) {
        List<ExportElement> exports = new List<ExportElement>();
        for (int i = 0; i < length; i++) {
          UnlinkedExportPublic serializedExportPublic =
              unlinkedPublicExports[i];
          UnlinkedExportNonPublic serializedExportNonPublic =
              unlinkedNonPublicExports[i];
          ExportElementImpl exportElement = new ExportElementImpl.forSerialized(
              serializedExportPublic, serializedExportNonPublic, library);
          exports.add(exportElement);
        }
        _exports = exports;
      } else {
        _exports = const <ExportElement>[];
      }
    }
    return _exports ?? const <ExportElement>[];
  }

  /**
   * Set the specifications of all of the exports defined in this library to the
   * given list of [exports].
   */
  void set exports(List<ExportElement> exports) {
    _assertNotResynthesized(_unlinkedDefiningUnit);
    for (ExportElement exportElement in exports) {
      (exportElement as ExportElementImpl).enclosingElement = this;
    }
    this._exports = exports;
  }

  @override
  bool get hasExtUri {
    if (_unlinkedDefiningUnit != null) {
      List<UnlinkedImport> unlinkedImports = _unlinkedDefiningUnit.imports;
      for (UnlinkedImport import in unlinkedImports) {
        if (DartUriResolver.isDartExtUri(import.uri)) {
          return true;
        }
      }
      return false;
    }
    return hasModifier(Modifier.HAS_EXT_URI);
  }

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
    for (ImportElement element in imports) {
      LibraryElement library = element.importedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return libraries.toList(growable: false);
  }

  @override
  List<ImportElement> get imports {
    if (_unlinkedDefiningUnit != null && _imports == null) {
      List<UnlinkedImport> unlinkedImports = _unlinkedDefiningUnit.imports;
      int length = unlinkedImports.length;
      if (length != 0) {
        List<ImportElement> imports = new List<ImportElement>();
        LinkedLibrary linkedLibrary = resynthesizerContext.linkedLibrary;
        for (int i = 0; i < length; i++) {
          int dependency = linkedLibrary.importDependencies[i];
          ImportElementImpl importElement = new ImportElementImpl.forSerialized(
              unlinkedImports[i], dependency, library);
          imports.add(importElement);
        }
        _imports = imports;
      } else {
        _imports = const <ImportElement>[];
      }
    }
    return _imports ?? ImportElement.EMPTY_LIST;
  }

  /**
   * Set the specifications of all of the imports defined in this library to the
   * given list of [imports].
   */
  void set imports(List<ImportElement> imports) {
    _assertNotResynthesized(_unlinkedDefiningUnit);
    for (ImportElement importElement in imports) {
      (importElement as ImportElementImpl).enclosingElement = this;
      PrefixElementImpl prefix = importElement.prefix as PrefixElementImpl;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    this._imports = imports;
    this._prefixes = null;
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
  bool get isResynthesized {
    return resynthesizerContext != null;
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
  List<ElementAnnotation> get metadata {
    if (_unlinkedDefiningUnit != null) {
      _metadata ??= _buildAnnotations(
          _definingCompilationUnit as CompilationUnitElementImpl,
          _unlinkedDefiningUnit.libraryAnnotations);
      return _metadata;
    }
    return super.metadata;
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
    if (_prefixes == null) {
      HashSet<PrefixElement> prefixes = new HashSet<PrefixElement>();
      for (ImportElement element in imports) {
        PrefixElement prefix = element.prefix;
        if (prefix != null) {
          prefixes.add(prefix);
        }
      }
      _prefixes = prefixes.toList(growable: false);
    }
    return _prefixes;
  }

  @override
  Namespace get publicNamespace {
    if (resynthesizerContext != null) {
      _publicNamespace ??= resynthesizerContext.buildPublicNamespace();
    }
    return _publicNamespace;
  }

  void set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
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
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitLibraryElement(this);

  /**
   * Create the [FunctionElement] to be returned by [loadLibraryFunction],
   * using types provided by [typeProvider].
   */
  void createLoadLibraryFunction(TypeProvider typeProvider) {
    FunctionElementImpl function =
        new FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1);
    function.isSynthetic = true;
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
    for (ImportElement importElement in imports) {
      ImportElementImpl importElementImpl = importElement;
      if (importElementImpl.identifier == identifier) {
        return importElementImpl;
      }
    }
    for (ExportElement exportElement in exports) {
      ExportElementImpl exportElementImpl = exportElement;
      if (exportElementImpl.identifier == identifier) {
        return exportElementImpl;
      }
    }
    return null;
  }

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) {
    var imports = this.imports;
    int count = imports.length;
    List<ImportElement> importList = new List<ImportElement>();
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].prefix, prefixElement)) {
        importList.add(imports[i]);
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
    // all nodes which are reachable from the source node.
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

  /**
   * Set whether the library has the given [capability] to
   * correspond to the given [value].
   */
  void setResolutionCapability(
      LibraryResolutionCapability capability, bool value) {
    _resolutionCapabilities =
        BooleanArray.set(_resolutionCapabilities, capability.index, value);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _definingCompilationUnit?.accept(visitor);
    safelyVisitChildren(exports, visitor);
    safelyVisitChildren(imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  /**
   * Return the [LibraryElementImpl] of the given [element].
   */
  static LibraryElementImpl getImpl(LibraryElement element) {
    if (element is LibraryElementHandle) {
      return getImpl(element.actualElement);
    }
    return element as LibraryElementImpl;
  }

  /**
   * Return `true` if the [library] has the given [capability].
   */
  static bool hasResolutionCapability(
      LibraryElement library, LibraryResolutionCapability capability) {
    return library is LibraryElementImpl &&
        BooleanArray.get(library._resolutionCapabilities, capability.index);
  }
}

/**
 * Enum of possible resolution capabilities that a [LibraryElementImpl] has.
 */
enum LibraryResolutionCapability {
  /**
   * All elements have their types resolved.
   */
  resolvedTypeNames,

  /**
   * All (potentially) constants expressions are set into corresponding
   * elements.
   */
  constantExpressions,
}

/**
 * The context in which the library is resynthesized.
 */
abstract class LibraryResynthesizerContext {
  /**
   * Return the [LinkedLibrary] that corresponds to the library being
   * resynthesized.
   */
  LinkedLibrary get linkedLibrary;

  /**
   * Return the exported [LibraryElement] for with the given [relativeUri].
   */
  LibraryElement buildExportedLibrary(String relativeUri);

  /**
   * Return the export namespace of the library.
   */
  Namespace buildExportNamespace();

  /**
   * Return the imported [LibraryElement] for the given dependency in the
   * linked library.
   */
  LibraryElement buildImportedLibrary(int dependency);

  /**
   * Return the public namespace of the library.
   */
  Namespace buildPublicNamespace();

  /**
   * Find the entry point of the library.
   */
  FunctionElement findEntryPoint();

  /**
   * Ensure that getters and setters in different units use the same
   * top-level variables.
   */
  void patchTopLevelAccessors();
}

/**
 * A concrete implementation of a [LocalVariableElement].
 */
class LocalVariableElementImpl extends NonParameterVariableElementImpl
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
    return '$name$nameOffset';
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
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitLocalVariableElement(this);

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
   * Initialize using the given serialized information.
   */
  MethodElementImpl.forSerialized(
      UnlinkedExecutable serializedExecutable, ClassElementImpl enclosingClass)
      : super.forSerialized(serializedExecutable, enclosingClass);

  /**
   * Set whether this method is abstract.
   */
  void set abstract(bool isAbstract) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  List<TypeParameterType> get allEnclosingTypeParameterTypes {
    if (isStatic) {
      return const <TypeParameterType>[];
    }
    return super.allEnclosingTypeParameterTypes;
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
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      super.enclosingElement as ClassElementImpl;

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
  bool get isStatic {
    if (serializedExecutable != null) {
      return serializedExecutable.isStatic;
    }
    return hasModifier(Modifier.STATIC);
  }

  /**
   * Set whether this method is static.
   */
  void set isStatic(bool isStatic) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.STATIC, isStatic);
  }

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

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(displayName);
    super.appendTo(buffer);
  }

  @override
  MethodDeclaration computeNode() =>
      getNodeMatching((node) => node is MethodDeclaration);

  @override
  FunctionType getReifiedType(DartType objectType) {
    // Check whether we have any covariant parameters.
    // Usually we don't, so we can use the same type.
    bool hasCovariant = false;
    for (ParameterElement parameter in parameters) {
      if (parameter.isCovariant) {
        hasCovariant = true;
        break;
      }
    }

    if (!hasCovariant) {
      return type;
    }

    List<ParameterElement> covariantParameters = parameters.map((parameter) {
      DartType type = parameter.isCovariant ? objectType : parameter.type;
      return new ParameterElementImpl.synthetic(
          parameter.name, type, parameter.parameterKind);
    }).toList();

    return new FunctionElementImpl.synthetic(covariantParameters, returnType)
        .type;
  }
}

/**
 * The constants for all of the modifiers defined by the Dart language and for a
 * few additional flags that are useful.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Modifier implements Comparable<Modifier> {
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
   * Indicates that the modifier 'covariant' was applied to the element.
   */
  static const Modifier COVARIANT = const Modifier('COVARIANT', 3);

  /**
   * Indicates that the import element represents a deferred library.
   */
  static const Modifier DEFERRED = const Modifier('DEFERRED', 4);

  /**
   * Indicates that a class element was defined by an enum declaration.
   */
  static const Modifier ENUM = const Modifier('ENUM', 5);

  /**
   * Indicates that a class element was defined by an enum declaration.
   */
  static const Modifier EXTERNAL = const Modifier('EXTERNAL', 6);

  /**
   * Indicates that the modifier 'factory' was applied to the element.
   */
  static const Modifier FACTORY = const Modifier('FACTORY', 7);

  /**
   * Indicates that the modifier 'final' was applied to the element.
   */
  static const Modifier FINAL = const Modifier('FINAL', 8);

  /**
   * Indicates that an executable element has a body marked as being a
   * generator.
   */
  static const Modifier GENERATOR = const Modifier('GENERATOR', 9);

  /**
   * Indicates that the pseudo-modifier 'get' was applied to the element.
   */
  static const Modifier GETTER = const Modifier('GETTER', 10);

  /**
   * A flag used for libraries indicating that the defining compilation unit
   * contains at least one import directive whose URI uses the "dart-ext"
   * scheme.
   */
  static const Modifier HAS_EXT_URI = const Modifier('HAS_EXT_URI', 11);

  /**
   * Indicates that the associated element did not have an explicit type
   * associated with it. If the element is an [ExecutableElement], then the
   * type being referred to is the return type.
   */
  static const Modifier IMPLICIT_TYPE = const Modifier('IMPLICIT_TYPE', 12);

  /**
   * Indicates that a class is a mixin application.
   */
  static const Modifier MIXIN_APPLICATION =
      const Modifier('MIXIN_APPLICATION', 13);

  /**
   * Indicates that a class contains an explicit reference to 'super'.
   */
  static const Modifier REFERENCES_SUPER =
      const Modifier('REFERENCES_SUPER', 14);

  /**
   * Indicates that the pseudo-modifier 'set' was applied to the element.
   */
  static const Modifier SETTER = const Modifier('SETTER', 15);

  /**
   * Indicates that the modifier 'static' was applied to the element.
   */
  static const Modifier STATIC = const Modifier('STATIC', 16);

  /**
   * Indicates that the element does not appear in the source code but was
   * implicitly created. For example, if a class does not define any
   * constructors, an implicit zero-argument constructor will be created and it
   * will be marked as being synthetic.
   */
  static const Modifier SYNTHETIC = const Modifier('SYNTHETIC', 17);

  static const List<Modifier> values = const [
    ABSTRACT,
    ASYNCHRONOUS,
    CONST,
    COVARIANT,
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

  /**
   * The name of this modifier.
   */
  final String name;

  /**
   * The ordinal value of the modifier.
   */
  final int ordinal;

  const Modifier(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(Modifier other) => ordinal - other.ordinal;

  @override
  String toString() => name;
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
   * A list containing all of the elements defined in SDK libraries that
   * conflict.
   */
  final List<Element> sdkElements;

  /**
   * A list containing all of the elements defined in non-SDK libraries that
   * conflict.
   */
  final List<Element> nonSdkElements;

  /**
   * Initialize a newly created element in the given [context] to represent a
   * list of conflicting [sdkElements] and [nonSdkElements]. At least one of the
   * lists must contain more than one element.
   */
  MultiplyDefinedElementImpl(
      this.context, this.sdkElements, this.nonSdkElements) {
    if (nonSdkElements.length > 0) {
      _name = nonSdkElements[0].name;
    } else {
      _name = sdkElements[0].name;
    }
  }

  @override
  List<Element> get conflictingElements {
    if (sdkElements.isEmpty) {
      return nonSdkElements;
    } else if (nonSdkElements.isEmpty) {
      return sdkElements;
    }
    List<Element> elements = nonSdkElements.toList();
    elements.addAll(sdkElements);
    return elements;
  }

  @override
  String get displayName => _name;

  @override
  String get documentationComment => null;

  @override
  Element get enclosingElement => null;

  @override
  bool get isDeprecated => false;

  @override
  bool get isFactory => false;

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
  Source get librarySource => null;

  @override
  ElementLocation get location => null;

  @override
  List<ElementAnnotation> get metadata => const <ElementAnnotation>[];

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
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

  @override
  String computeDocumentationComment() => null;

  @override
  AstNode computeNode() => null;

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) => null;

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
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (Element element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        if (element is ElementImpl) {
          element.appendTo(buffer);
        } else {
          buffer.write(element);
        }
      }
    }

    buffer.write("[");
    writeList(nonSdkElements);
    writeList(sdkElements);
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
    Set<Element> sdkElements = new HashSet<Element>.identity();
    Set<Element> nonSdkElements = new HashSet<Element>.identity();
    void add(Element element) {
      if (element != null) {
        if (element is MultiplyDefinedElementImpl) {
          sdkElements.addAll(element.sdkElements);
          nonSdkElements.addAll(element.nonSdkElements);
        } else if (element.library.isInSdk) {
          sdkElements.add(element);
        } else {
          nonSdkElements.add(element);
        }
      }
    }

    add(firstElement);
    add(secondElement);
    int nonSdkCount = nonSdkElements.length;
    if (nonSdkCount == 0) {
      int sdkCount = sdkElements.length;
      if (sdkCount == 0) {
        return null;
      } else if (sdkCount == 1) {
        return sdkElements.first;
      }
    } else if (nonSdkCount == 1) {
      return nonSdkElements.first;
    }
    return new MultiplyDefinedElementImpl(
        context,
        sdkElements.toList(growable: false),
        nonSdkElements.toList(growable: false));
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
    isSynthetic = true;
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
    isSynthetic = true;
  }

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  List<ExecutableElement> get inheritedElements => _elements;

  void set inheritedElements(List<ExecutableElement> elements) {
    this._elements = elements;
  }
}

/**
 * A [VariableElementImpl], which is not a parameter.
 */
abstract class NonParameterVariableElementImpl extends VariableElementImpl {
  /**
   * The unlinked representation of the variable in the summary.
   */
  final UnlinkedVariable _unlinkedVariable;

  /**
   * Initialize a newly created variable element to have the given [name] and
   * [offset].
   */
  NonParameterVariableElementImpl(String name, int offset)
      : _unlinkedVariable = null,
        super(name, offset);

  /**
   * Initialize a newly created variable element to have the given [name].
   */
  NonParameterVariableElementImpl.forNode(Identifier name)
      : _unlinkedVariable = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  NonParameterVariableElementImpl.forSerialized(
      this._unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  @override
  int get codeLength {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  String get documentationComment {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable?.documentationComment?.text;
    }
    return super.documentationComment;
  }

  @override
  bool get hasImplicitType {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.type == null;
    }
    return super.hasImplicitType;
  }

  @override
  void set hasImplicitType(bool hasImplicitType) {
    _assertNotResynthesized(_unlinkedVariable);
    super.hasImplicitType = hasImplicitType;
  }

  @override
  FunctionElement get initializer {
    if (_unlinkedVariable != null && _initializer == null) {
      UnlinkedExecutable unlinkedInitializer = _unlinkedVariable.initializer;
      if (unlinkedInitializer != null) {
        _initializer =
            new FunctionElementImpl.forSerialized(unlinkedInitializer, this)
              ..isSynthetic = true;
      } else {
        return null;
      }
    }
    return super.initializer;
  }

  /**
   * Set the function representing this variable's initializer to the given
   * [function].
   */
  void set initializer(FunctionElement function) {
    _assertNotResynthesized(_unlinkedVariable);
    super.initializer = function;
  }

  @override
  bool get isConst {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.isConst;
    }
    return super.isConst;
  }

  @override
  void set isConst(bool isConst) {
    _assertNotResynthesized(_unlinkedVariable);
    super.isConst = isConst;
  }

  @override
  bool get isFinal {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.isFinal;
    }
    return super.isFinal;
  }

  @override
  void set isFinal(bool isFinal) {
    _assertNotResynthesized(_unlinkedVariable);
    super.isFinal = isFinal;
  }

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedVariable != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedVariable.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (_unlinkedVariable != null) {
      return _unlinkedVariable.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedVariable != null) {
      return _unlinkedVariable.nameOffset;
    }
    return offset;
  }

  @override
  DartType get type {
    if (_unlinkedVariable != null && _declaredType == null && _type == null) {
      _type = enclosingUnit.resynthesizerContext
          .resolveLinkedType(this, _unlinkedVariable.inferredTypeSlot);
      declaredType = enclosingUnit.resynthesizerContext
          .resolveTypeRef(this, _unlinkedVariable.type, declaredType: true);
    }
    return super.type;
  }

  @override
  void set type(DartType type) {
    _assertNotResynthesized(_unlinkedVariable);
    _type = _checkElementOfType(type);
  }

  @override
  TopLevelInferenceError get typeInferenceError {
    if (_unlinkedVariable != null) {
      return enclosingUnit.resynthesizerContext
          .getTypeInferenceError(_unlinkedVariable.inferredTypeSlot);
    }
    // We don't support type inference errors without linking.
    return null;
  }

  /**
   * Subclasses need this getter, see [ConstVariableElement._unlinkedConst].
   */
  UnlinkedExpr get _unlinkedConst => _unlinkedVariable?.initializer?.bodyExpr;
}

/**
 * A concrete implementation of a [ParameterElement].
 */
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement {
  /**
   * The unlinked representation of the parameter in the summary.
   */
  final UnlinkedParam _unlinkedParam;

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
  ParameterKind _parameterKind;

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

  bool _inheritsCovariant = false;

  /**
   * Initialize a newly created parameter element to have the given [name] and
   * [nameOffset].
   */
  ParameterElementImpl(String name, int nameOffset)
      : _unlinkedParam = null,
        super(name, nameOffset);

  /**
   * Initialize a newly created parameter element to have the given [name].
   */
  ParameterElementImpl.forNode(Identifier name)
      : _unlinkedParam = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  ParameterElementImpl.forSerialized(
      this._unlinkedParam, ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  /**
   * Initialize using the given serialized information.
   */
  factory ParameterElementImpl.forSerializedFactory(
      UnlinkedParam unlinkedParameter, ElementImpl enclosingElement,
      {bool synthetic: false}) {
    ParameterElementImpl element;
    if (unlinkedParameter.isInitializingFormal) {
      if (unlinkedParameter.kind == UnlinkedParamKind.required) {
        element = new FieldFormalParameterElementImpl.forSerialized(
            unlinkedParameter, enclosingElement);
      } else {
        element = new DefaultFieldFormalParameterElementImpl.forSerialized(
            unlinkedParameter, enclosingElement);
      }
    } else {
      if (unlinkedParameter.kind == UnlinkedParamKind.required) {
        element = new ParameterElementImpl.forSerialized(
            unlinkedParameter, enclosingElement);
      } else {
        element = new DefaultParameterElementImpl.forSerialized(
            unlinkedParameter, enclosingElement);
      }
    }
    element.isSynthetic = synthetic;
    return element;
  }

  /**
   * Creates a synthetic parameter with [name], [type] and [kind].
   */
  factory ParameterElementImpl.synthetic(
      String name, DartType type, ParameterKind kind) {
    ParameterElementImpl element = new ParameterElementImpl(name, -1);
    element.type = type;
    element.isSynthetic = true;
    element.parameterKind = kind;
    return element;
  }

  @override
  int get codeLength {
    if (_unlinkedParam != null) {
      return _unlinkedParam.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedParam != null) {
      return _unlinkedParam.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  String get defaultValueCode {
    if (_unlinkedParam != null) {
      if (_unlinkedParam.initializer?.bodyExpr == null) {
        return null;
      }
      return _unlinkedParam.defaultValueCode;
    }
    return _defaultValueCode;
  }

  /**
   * Set Dart code of the default value.
   */
  void set defaultValueCode(String defaultValueCode) {
    _assertNotResynthesized(_unlinkedParam);
    this._defaultValueCode = StringUtilities.intern(defaultValueCode);
  }

  @override
  bool get hasImplicitType {
    if (_unlinkedParam != null) {
      return _unlinkedParam.type == null && !_unlinkedParam.isFunctionTyped;
    }
    return super.hasImplicitType;
  }

  @override
  void set hasImplicitType(bool hasImplicitType) {
    _assertNotResynthesized(_unlinkedParam);
    super.hasImplicitType = hasImplicitType;
  }

  /**
   * True if this parameter inherits from a covariant parameter. This happens
   * when it overrides a method in a supertype that has a corresponding
   * covariant parameter.
   */
  bool get inheritsCovariant {
    if (_unlinkedParam != null) {
      return enclosingUnit.resynthesizerContext
          .inheritsCovariant(_unlinkedParam.inheritsCovariantSlot);
    } else {
      return _inheritsCovariant;
    }
  }

  /**
   * Record whether or not this parameter inherits from a covariant parameter.
   */
  void set inheritsCovariant(bool value) {
    _assertNotResynthesized(_unlinkedParam);
    _inheritsCovariant = value;
  }

  @override
  FunctionElement get initializer {
    if (_unlinkedParam != null && _initializer == null) {
      UnlinkedExecutable unlinkedInitializer = _unlinkedParam.initializer;
      if (unlinkedInitializer != null) {
        _initializer =
            new FunctionElementImpl.forSerialized(unlinkedInitializer, this)
              ..isSynthetic = true;
      } else {
        return null;
      }
    }
    return super.initializer;
  }

  /**
   * Set the function representing this variable's initializer to the given
   * [function].
   */
  void set initializer(FunctionElement function) {
    _assertNotResynthesized(_unlinkedParam);
    super.initializer = function;
  }

  @override
  bool get isConst {
    if (_unlinkedParam != null) {
      return false;
    }
    return super.isConst;
  }

  @override
  void set isConst(bool isConst) {
    _assertNotResynthesized(_unlinkedParam);
    super.isConst = isConst;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    for (ElementAnnotationImpl annotation in metadata) {
      if (annotation.isCovariant) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return true if this parameter is explicitly marked as being covariant.
   */
  bool get isExplicitlyCovariant {
    if (_unlinkedParam != null) {
      return _unlinkedParam.isExplicitlyCovariant;
    }
    return hasModifier(Modifier.COVARIANT);
  }

  /**
   * Set whether this variable parameter is explicitly marked as being covariant.
   */
  void set isExplicitlyCovariant(bool isCovariant) {
    _assertNotResynthesized(_unlinkedParam);
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isFinal {
    if (_unlinkedParam != null) {
      return _unlinkedParam.isFinal;
    }
    return super.isFinal;
  }

  @override
  void set isFinal(bool isFinal) {
    _assertNotResynthesized(_unlinkedParam);
    super.isFinal = isFinal;
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
  List<ElementAnnotation> get metadata {
    if (_unlinkedParam != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedParam.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (_unlinkedParam != null) {
      return _unlinkedParam.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedParam != null) {
      if (isSynthetic ||
          (_unlinkedParam.name.isEmpty &&
              _unlinkedParam.kind != UnlinkedParamKind.named &&
              enclosingElement is GenericFunctionTypeElement)) {
        return -1;
      }
      return _unlinkedParam.nameOffset;
    }
    return offset;
  }

  @override
  ParameterKind get parameterKind {
    if (_unlinkedParam != null && _parameterKind == null) {
      switch (_unlinkedParam.kind) {
        case UnlinkedParamKind.named:
          _parameterKind = ParameterKind.NAMED;
          break;
        case UnlinkedParamKind.positional:
          _parameterKind = ParameterKind.POSITIONAL;
          break;
        case UnlinkedParamKind.required:
          _parameterKind = ParameterKind.REQUIRED;
          break;
      }
    }
    return _parameterKind;
  }

  void set parameterKind(ParameterKind parameterKind) {
    _assertNotResynthesized(_unlinkedParam);
    _parameterKind = parameterKind;
  }

  @override
  List<ParameterElement> get parameters {
    _resynthesizeTypeAndParameters();
    return _parameters;
  }

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
  DartType get type {
    _resynthesizeTypeAndParameters();
    return super.type;
  }

  @override
  TopLevelInferenceError get typeInferenceError {
    if (_unlinkedParam != null) {
      return enclosingUnit.resynthesizerContext
          .getTypeInferenceError(_unlinkedParam.inferredTypeSlot);
    }
    // We don't support type inference errors without linking.
    return null;
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
    if (_unlinkedParam != null) {
      if (_unlinkedParam.visibleLength == 0) {
        return null;
      }
      return new SourceRange(
          _unlinkedParam.visibleOffset, _unlinkedParam.visibleLength);
    }
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  /**
   * Subclasses need this getter, see [ConstVariableElement._unlinkedConst].
   */
  UnlinkedExpr get _unlinkedConst => _unlinkedParam?.initializer?.bodyExpr;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitParameterElement(this);

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
    _assertNotResynthesized(_unlinkedParam);
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  /**
   * If this element is resynthesized, and its type and parameters have not
   * been build yet, build them and remember in the corresponding fields.
   */
  void _resynthesizeTypeAndParameters() {
    if (_unlinkedParam != null && _declaredType == null && _type == null) {
      if (_unlinkedParam.isFunctionTyped) {
        CompilationUnitElementImpl enclosingUnit = this.enclosingUnit;
        FunctionElementImpl parameterTypeElement =
            new FunctionElementImpl_forFunctionTypedParameter(
                enclosingUnit, this);
        if (!isSynthetic) {
          parameterTypeElement.enclosingElement = this;
        }
        List<ParameterElement> subParameters = ParameterElementImpl
            .resynthesizeList(_unlinkedParam.parameters, this,
                synthetic: isSynthetic);
        if (isSynthetic) {
          parameterTypeElement.parameters = subParameters;
        } else {
          _parameters = subParameters;
          parameterTypeElement.shareParameters(subParameters);
        }
        parameterTypeElement.returnType = enclosingUnit.resynthesizerContext
            .resolveTypeRef(this, _unlinkedParam.type);
        FunctionTypeImpl parameterType =
            new FunctionTypeImpl.elementWithNameAndArgs(parameterTypeElement,
                null, typeParameterContext.allTypeParameterTypes, false);
        parameterTypeElement.type = parameterType;
        _type = parameterType;
      } else {
        _type = enclosingUnit.resynthesizerContext
            .resolveLinkedType(this, _unlinkedParam.inferredTypeSlot);
        declaredType = enclosingUnit.resynthesizerContext
            .resolveTypeRef(this, _unlinkedParam.type, declaredType: true);
      }
    }
  }

  /**
   * Create and return [ParameterElement]s for the given [unlinkedParameters].
   */
  static List<ParameterElement> resynthesizeList(
      List<UnlinkedParam> unlinkedParameters, ElementImpl enclosingElement,
      {bool synthetic: false}) {
    int length = unlinkedParameters.length;
    if (length != 0) {
      List<ParameterElement> parameters = new List<ParameterElement>(length);
      for (int i = 0; i < length; i++) {
        parameters[i] = new ParameterElementImpl.forSerializedFactory(
            unlinkedParameters[i], enclosingElement,
            synthetic: synthetic);
      }
      return parameters;
    } else {
      return const <ParameterElement>[];
    }
  }
}

/**
 * The parameter of an implicit setter.
 */
class ParameterElementImpl_ofImplicitSetter extends ParameterElementImpl {
  final PropertyAccessorElementImpl_ImplicitSetter setter;

  ParameterElementImpl_ofImplicitSetter(
      PropertyAccessorElementImpl_ImplicitSetter setter)
      : setter = setter,
        super('_${setter.variable.name}', setter.variable.nameOffset) {
    enclosingElement = setter;
    isSynthetic = true;
    parameterKind = ParameterKind.REQUIRED;
  }

  @override
  bool get inheritsCovariant {
    PropertyInducingElement variable = setter.variable;
    if (variable is FieldElementImpl && variable._unlinkedVariable != null) {
      return enclosingUnit.resynthesizerContext
          .inheritsCovariant(variable._unlinkedVariable.inheritsCovariantSlot);
    }
    return super.inheritsCovariant;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    for (ElementAnnotationImpl annotation in setter.variable.metadata) {
      if (annotation.isCovariant) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant {
    PropertyInducingElement variable = setter.variable;
    if (variable is FieldElementImpl) {
      return variable.isCovariant;
    }
    return false;
  }

  @override
  DartType get type => setter.variable.type;

  @override
  void set type(DartType type) {
    assert(false); // Should never be called.
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
   * The unlinked representation of the import in the summary.
   */
  final UnlinkedImport _unlinkedImport;

  /**
   * Initialize a newly created method element to have the given [name] and
   * [nameOffset].
   */
  PrefixElementImpl(String name, int nameOffset)
      : _unlinkedImport = null,
        super(name, nameOffset);

  /**
   * Initialize a newly created prefix element to have the given [name].
   */
  PrefixElementImpl.forNode(Identifier name)
      : _unlinkedImport = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  PrefixElementImpl.forSerialized(
      this._unlinkedImport, LibraryElementImpl enclosingLibrary)
      : super.forSerialized(enclosingLibrary);

  @override
  String get displayName => name;

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
  String get name {
    if (_unlinkedImport != null) {
      if (_name == null) {
        LibraryElementImpl library = enclosingElement as LibraryElementImpl;
        int prefixId = _unlinkedImport.prefixReference;
        return _name = library._unlinkedDefiningUnit.references[prefixId].name;
      }
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedImport != null) {
      return _unlinkedImport.prefixOffset;
    }
    return offset;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

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
   * Initialize using the given serialized information.
   */
  PropertyAccessorElementImpl.forSerialized(
      UnlinkedExecutable serializedExecutable, ElementImpl enclosingElement)
      : super.forSerialized(serializedExecutable, enclosingElement);

  /**
   * Initialize a newly created synthetic property accessor element to be
   * associated with the given [variable].
   */
  PropertyAccessorElementImpl.forVariable(PropertyInducingElementImpl variable)
      : super(variable.name, variable.nameOffset) {
    this.variable = variable;
    isStatic = variable.isStatic;
    isSynthetic = true;
  }

  /**
   * Set whether this accessor is abstract.
   */
  void set abstract(bool isAbstract) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  List<TypeParameterType> get allEnclosingTypeParameterTypes {
    if (isStatic) {
      return const <TypeParameterType>[];
    }
    return super.allEnclosingTypeParameterTypes;
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

  @override
  String get displayName {
    if (serializedExecutable != null && isSetter) {
      String name = serializedExecutable.name;
      assert(name.endsWith('='));
      return name.substring(0, name.length - 1);
    }
    return super.displayName;
  }

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext {
    return (enclosingElement as ElementImpl).typeParameterContext;
  }

  /**
   * Set whether this accessor is a getter.
   */
  void set getter(bool isGetter) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return "$name$suffix";
  }

  @override
  bool get isGetter {
    if (serializedExecutable != null) {
      return serializedExecutable.kind == UnlinkedExecutableKind.getter;
    }
    return hasModifier(Modifier.GETTER);
  }

  @override
  bool get isSetter {
    if (serializedExecutable != null) {
      return serializedExecutable.kind == UnlinkedExecutableKind.setter;
    }
    return hasModifier(Modifier.SETTER);
  }

  @override
  bool get isStatic {
    if (serializedExecutable != null) {
      return serializedExecutable.isStatic ||
          variable is TopLevelVariableElement;
    }
    return hasModifier(Modifier.STATIC);
  }

  /**
   * Set whether this accessor is static.
   */
  void set isStatic(bool isStatic) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  @override
  String get name {
    if (serializedExecutable != null) {
      return serializedExecutable.name;
    }
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
  }

  /**
   * Set whether this accessor is a setter.
   */
  void set setter(bool isSetter) {
    _assertNotResynthesized(serializedExecutable);
    setModifier(Modifier.SETTER, isSetter);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

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
 * Implicit getter for a [PropertyInducingElementImpl].
 */
class PropertyAccessorElementImpl_ImplicitGetter
    extends PropertyAccessorElementImpl {
  /**
   * Create the implicit getter and bind it to the [property].
   */
  PropertyAccessorElementImpl_ImplicitGetter(
      PropertyInducingElementImpl property)
      : super.forVariable(property) {
    property.getter = this;
    enclosingElement = property.enclosingElement;
  }

  @override
  bool get hasImplicitReturnType => variable.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  DartType get returnType => variable.type;

  @override
  void set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get type {
    return _type ??= new FunctionTypeImpl(this);
  }

  @override
  void set type(FunctionType type) {
    assert(false); // Should never be called.
  }
}

/**
 * Implicit setter for a [PropertyInducingElementImpl].
 */
class PropertyAccessorElementImpl_ImplicitSetter
    extends PropertyAccessorElementImpl {
  /**
   * Create the implicit setter and bind it to the [property].
   */
  PropertyAccessorElementImpl_ImplicitSetter(
      PropertyInducingElementImpl property)
      : super.forVariable(property) {
    property.setter = this;
  }

  @override
  bool get isSetter => true;

  @override
  List<ParameterElement> get parameters {
    return _parameters ??= <ParameterElement>[
      new ParameterElementImpl_ofImplicitSetter(this)
    ];
  }

  @override
  DartType get returnType => VoidTypeImpl.instance;

  @override
  void set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get type {
    return _type ??= new FunctionTypeImpl(this);
  }

  @override
  void set type(FunctionType type) {
    assert(false); // Should never be called.
  }
}

/**
 * A concrete implementation of a [PropertyInducingElement].
 */
abstract class PropertyInducingElementImpl
    extends NonParameterVariableElementImpl implements PropertyInducingElement {
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
  DartType _propagatedType;

  /**
   * Initialize a newly created synthetic element to have the given [name] and
   * [offset].
   */
  PropertyInducingElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize a newly created element to have the given [name].
   */
  PropertyInducingElementImpl.forNode(Identifier name) : super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  PropertyInducingElementImpl.forSerialized(
      UnlinkedVariable unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedVariable, enclosingElement);

  @override
  DartType get propagatedType {
    if (_unlinkedVariable != null && _propagatedType == null) {
      _propagatedType = enclosingUnit.resynthesizerContext
          .resolveLinkedType(this, _unlinkedVariable.propagatedTypeSlot);
    }
    return _propagatedType;
  }

  void set propagatedType(DartType propagatedType) {
    _assertNotResynthesized(_unlinkedVariable);
    _propagatedType = _checkElementOfType(propagatedType);
  }

  @override
  DartType get type {
    if (isSynthetic && _type == null) {
      if (getter != null) {
        _type = getter.returnType;
      } else if (setter != null) {
        List<ParameterElement> parameters = setter.parameters;
        _type = parameters.isNotEmpty
            ? parameters[0].type
            : DynamicTypeImpl.instance;
      } else {
        _type = DynamicTypeImpl.instance;
      }
    }
    return super.type;
  }
}

/**
 * The context in which elements are resynthesized.
 */
abstract class ResynthesizerContext {
  bool get isStrongMode;

  /**
   * Build [ElementAnnotationImpl] for the given [UnlinkedExpr].
   */
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedExpr uc);

  /**
   * Build [Expression] for the given [UnlinkedExpr].
   */
  Expression buildExpression(ElementImpl context, UnlinkedExpr uc);

  /**
   * Build explicit top-level property accessors.
   */
  UnitExplicitTopLevelAccessors buildTopLevelAccessors();

  /**
   * Build explicit top-level variables.
   */
  UnitExplicitTopLevelVariables buildTopLevelVariables();

  /**
   * Return the error reported during type inference for the given [slot],
   * or `null` if there was no error.
   */
  TopLevelInferenceError getTypeInferenceError(int slot);

  /**
   * Return `true` if the given parameter [slot] inherits `@covariant` behavior.
   */
  bool inheritsCovariant(int slot);

  /**
   * Return `true` if the given const constructor [slot] is a part of a cycle.
   */
  bool isInConstCycle(int slot);

  /**
   * Resolve an [EntityRef] into a constructor.  If the reference is
   * unresolved, return `null`.
   */
  ConstructorElement resolveConstructorRef(
      ElementImpl context, EntityRef entry);

  /**
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType resolveLinkedType(ElementImpl context, int slot);

  /**
   * Resolve an [EntityRef] into a type.  If the reference is
   * unresolved, return [DynamicTypeImpl.instance].
   *
   * TODO(paulberry): or should we have a class representing an
   * unresolved type, for consistency with the full element model?
   */
  DartType resolveTypeRef(ElementImpl context, EntityRef type,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false});
}

/**
 * A concrete implementation of a [ShowElementCombinator].
 */
class ShowElementCombinatorImpl implements ShowElementCombinator {
  /**
   * The unlinked representation of the combinator in the summary.
   */
  final UnlinkedCombinator _unlinkedCombinator;

  /**
   * The names that are to be made visible in the importing library if they are
   * defined in the imported library.
   */
  List<String> _shownNames;

  /**
   * The offset of the character immediately following the last character of
   * this node.
   */
  int _end = -1;

  /**
   * The offset of the 'show' keyword of this element.
   */
  int _offset = 0;

  ShowElementCombinatorImpl() : _unlinkedCombinator = null;

  /**
   * Initialize using the given serialized information.
   */
  ShowElementCombinatorImpl.forSerialized(this._unlinkedCombinator);

  @override
  int get end {
    if (_unlinkedCombinator != null) {
      return _unlinkedCombinator.end;
    }
    return _end;
  }

  void set end(int end) {
    _assertNotResynthesized(_unlinkedCombinator);
    _end = end;
  }

  @override
  int get offset {
    if (_unlinkedCombinator != null) {
      return _unlinkedCombinator.offset;
    }
    return _offset;
  }

  void set offset(int offset) {
    _assertNotResynthesized(_unlinkedCombinator);
    _offset = offset;
  }

  @override
  List<String> get shownNames {
    if (_unlinkedCombinator != null) {
      _shownNames ??= _unlinkedCombinator.shows.toList(growable: false);
    }
    return _shownNames ?? const <String>[];
  }

  void set shownNames(List<String> shownNames) {
    _assertNotResynthesized(_unlinkedCombinator);
    _shownNames = shownNames;
  }

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

  /**
   * Initialize using the given serialized information.
   */
  TopLevelVariableElementImpl.forSerialized(
      UnlinkedVariable unlinkedVariable, ElementImpl enclosingElement)
      : super.forSerialized(unlinkedVariable, enclosingElement);

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);

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
   * The unlinked representation of the type parameter in the summary.
   */
  final UnlinkedTypeParam _unlinkedTypeParam;

  /**
   * The number of type parameters whose scope overlaps this one, and which are
   * declared earlier in the file.
   *
   * TODO(scheglov) make private?
   */
  final int nestingLevel;

  /**
   * The type defined by this type parameter.
   */
  TypeParameterType _type;

  /**
   * The type representing the bound associated with this parameter, or `null`
   * if this parameter does not have an explicit bound.
   */
  DartType _bound;

  /**
   * Initialize a newly created method element to have the given [name] and
   * [offset].
   */
  TypeParameterElementImpl(String name, int offset)
      : _unlinkedTypeParam = null,
        nestingLevel = null,
        super(name, offset);

  /**
   * Initialize a newly created type parameter element to have the given [name].
   */
  TypeParameterElementImpl.forNode(Identifier name)
      : _unlinkedTypeParam = null,
        nestingLevel = null,
        super.forNode(name);

  /**
   * Initialize using the given serialized information.
   */
  TypeParameterElementImpl.forSerialized(this._unlinkedTypeParam,
      TypeParameterizedElementMixin enclosingElement, this.nestingLevel)
      : super.forSerialized(enclosingElement);

  /**
   * Initialize a newly created synthetic type parameter element to have the
   * given [name], and with [synthetic] set to true.
   */
  TypeParameterElementImpl.synthetic(String name)
      : _unlinkedTypeParam = null,
        nestingLevel = null,
        super(name, -1) {
    isSynthetic = true;
  }

  DartType get bound {
    if (_unlinkedTypeParam != null) {
      if (_unlinkedTypeParam.bound == null) {
        return null;
      }
      return _bound ??= enclosingUnit.resynthesizerContext.resolveTypeRef(
          this, _unlinkedTypeParam.bound,
          instantiateToBoundsAllowed: false, declaredType: true);
    }
    return _bound;
  }

  void set bound(DartType bound) {
    _assertNotResynthesized(_unlinkedTypeParam);
    _bound = _checkElementOfType(bound);
  }

  @override
  int get codeLength {
    if (_unlinkedTypeParam != null) {
      return _unlinkedTypeParam.codeRange?.length;
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (_unlinkedTypeParam != null) {
      return _unlinkedTypeParam.codeRange?.offset;
    }
    return super.codeOffset;
  }

  @override
  String get displayName => name;

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  List<ElementAnnotation> get metadata {
    if (_unlinkedTypeParam != null) {
      return _metadata ??=
          _buildAnnotations(enclosingUnit, _unlinkedTypeParam.annotations);
    }
    return super.metadata;
  }

  @override
  String get name {
    if (_unlinkedTypeParam != null) {
      return _unlinkedTypeParam.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    int offset = super.nameOffset;
    if (offset == 0 && _unlinkedTypeParam != null) {
      return _unlinkedTypeParam.nameOffset;
    }
    return offset;
  }

  TypeParameterType get type {
    if (_unlinkedTypeParam != null) {
      _type ??= new TypeParameterTypeImpl(this);
    }
    return _type;
  }

  void set type(TypeParameterType type) {
    _type = type;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

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
 * Mixin representing an element which can have type parameters.
 */
abstract class TypeParameterizedElementMixin
    implements TypeParameterizedElement, ElementImpl {
  /**
   * The cached number of type parameters that are in scope in this context, or
   * `null` if the number has not yet been computed.
   */
  int _nestingLevel;

  /**
   * A cached list containing the type parameters declared by this element
   * directly, or `null` if the elements have not been created yet. This does
   * not include type parameters that are declared by any enclosing elements.
   */
  List<TypeParameterElement> _typeParameterElements;

  /**
   * A cached list containing the type parameter types declared by this element
   * directly, or `null` if the list has not been computed yet.
   */
  List<TypeParameterType> _typeParameterTypes;

  /**
   * A cached list containing all of the type parameter types of this element,
   * including those declared by this element directly and those declared by any
   * enclosing elements, or `null` if the list has not been computed yet.
   */
  List<TypeParameterType> _allTypeParameterTypes;

  /**
   * Return all type parameter types of the element that encloses element.
   * Not `null`, but might be empty for top-level and static class members.
   */
  List<TypeParameterType> get allEnclosingTypeParameterTypes {
    return enclosingTypeParameterContext?.allTypeParameterTypes ??
        const <TypeParameterType>[];
  }

  /**
   * Return all type parameter types of this element.
   */
  List<TypeParameterType> get allTypeParameterTypes {
    if (_allTypeParameterTypes == null) {
      _allTypeParameterTypes = <TypeParameterType>[];
      // The most logical order would be (enclosing, this).
      // But we have to have it like this to be consistent with (inconsistent
      // by itself) element builder for generic functions.
      _allTypeParameterTypes.addAll(typeParameterTypes);
      _allTypeParameterTypes.addAll(allEnclosingTypeParameterTypes);
    }
    return _allTypeParameterTypes;
  }

  /**
   * Get the type parameter context enclosing this one, if any.
   */
  TypeParameterizedElementMixin get enclosingTypeParameterContext;

  /**
   * The unit in which this element is resynthesized.
   */
  CompilationUnitElementImpl get enclosingUnit;

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  /**
   * Find out how many type parameters are in scope in this context.
   */
  int get typeParameterNestingLevel =>
      _nestingLevel ??= unlinkedTypeParams.length +
          (enclosingTypeParameterContext?.typeParameterNestingLevel ?? 0);

  @override
  List<TypeParameterElement> get typeParameters {
    if (_typeParameterElements == null) {
      List<UnlinkedTypeParam> unlinkedParams = unlinkedTypeParams;
      if (unlinkedParams != null) {
        int enclosingNestingLevel =
            enclosingTypeParameterContext?.typeParameterNestingLevel ?? 0;
        int numTypeParameters = unlinkedParams.length;
        _typeParameterElements =
            new List<TypeParameterElement>(numTypeParameters);
        for (int i = 0; i < numTypeParameters; i++) {
          _typeParameterElements[i] =
              new TypeParameterElementImpl.forSerialized(
                  unlinkedParams[i], this, enclosingNestingLevel + i);
        }
      }
    }
    return _typeParameterElements ?? const <TypeParameterElement>[];
  }

  /**
   * Get a list of [TypeParameterType] objects corresponding to the
   * element's type parameters.
   */
  List<TypeParameterType> get typeParameterTypes {
    return _typeParameterTypes ??= typeParameters
        .map((TypeParameterElement e) => e.type)
        .toList(growable: false);
  }

  /**
   * Get the [UnlinkedTypeParam]s representing the type parameters declared by
   * this element, or `null` if this element isn't from a summary.
   *
   * TODO(scheglov) make private after switching linker to Impl
   */
  List<UnlinkedTypeParam> get unlinkedTypeParams;

  /**
   * Convert the given [index] into a type parameter type.
   */
  TypeParameterType getTypeParameterType(int index) {
    List<TypeParameterType> types = typeParameterTypes;
    if (index <= types.length) {
      return types[types.length - index];
    } else if (enclosingTypeParameterContext != null) {
      return enclosingTypeParameterContext
          .getTypeParameterType(index - types.length);
    } else {
      // If we get here, it means that a summary contained a type parameter index
      // that was out of range.
      throw new RangeError('Invalid type parameter index');
    }
  }

  /**
   * Find out if the given [typeParameter] is in scope in this context.
   */
  bool isTypeParameterInScope(TypeParameterElement typeParameter) {
    if (typeParameter.enclosingElement == this) {
      return true;
    } else if (enclosingTypeParameterContext != null) {
      return enclosingTypeParameterContext
          .isTypeParameterInScope(typeParameter);
    } else {
      return false;
    }
  }
}

/**
 * Container with information about explicit top-level property accessors and
 * corresponding implicit top-level variables.
 */
class UnitExplicitTopLevelAccessors {
  final List<PropertyAccessorElementImpl> accessors =
      <PropertyAccessorElementImpl>[];
  final List<TopLevelVariableElementImpl> implicitVariables =
      <TopLevelVariableElementImpl>[];
}

/**
 * Container with information about explicit top-level variables and
 * corresponding implicit top-level property accessors.
 */
class UnitExplicitTopLevelVariables {
  final List<TopLevelVariableElementImpl> variables;
  final List<PropertyAccessorElementImpl> implicitAccessors =
      <PropertyAccessorElementImpl>[];

  UnitExplicitTopLevelVariables(int numberOfVariables)
      : variables = numberOfVariables != 0
            ? new List<TopLevelVariableElementImpl>(numberOfVariables)
            : const <TopLevelVariableElementImpl>[];
}

/**
 * A concrete implementation of a [UriReferencedElement].
 */
abstract class UriReferencedElementImpl extends ElementImpl
    implements UriReferencedElement {
  /**
   * The offset of the URI in the file, or `-1` if this node is synthetic.
   */
  int _uriOffset = -1;

  /**
   * The offset of the character immediately following the last character of
   * this node's URI, or `-1` if this node is synthetic.
   */
  int _uriEnd = -1;

  /**
   * The URI that is specified by this directive.
   */
  String _uri;

  /**
   * Initialize a newly created import element to have the given [name] and
   * [offset]. The offset may be `-1` if the element is synthetic.
   */
  UriReferencedElementImpl(String name, int offset) : super(name, offset);

  /**
   * Initialize using the given serialized information.
   */
  UriReferencedElementImpl.forSerialized(ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  /**
   * Return the URI that is specified by this directive.
   */
  String get uri => _uri;

  /**
   * Set the URI that is specified by this directive to be the given [uri].
   */
  void set uri(String uri) {
    _uri = uri;
  }

  /**
   * Return the offset of the character immediately following the last character
   * of this node's URI, or `-1` if this node is synthetic.
   */
  int get uriEnd => _uriEnd;

  /**
   * Set the offset of the character immediately following the last character of
   * this node's URI to the given [offset].
   */
  void set uriEnd(int offset) {
    _uriEnd = offset;
  }

  /**
   * Return the offset of the URI in the file, or `-1` if this node is synthetic.
   */
  int get uriOffset => _uriOffset;

  /**
   * Set the offset of the URI in the file to the given [offset].
   */
  void set uriOffset(int offset) {
    _uriOffset = offset;
  }

  String _selectUri(
      String defaultUri, List<UnlinkedConfiguration> configurations) {
    for (UnlinkedConfiguration configuration in configurations) {
      if (context.declaredVariables.get(configuration.name) ==
          configuration.value) {
        return configuration.uri;
      }
    }
    return defaultUri;
  }
}

/**
 * A concrete implementation of a [VariableElement].
 */
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /**
   * The declared type of this variable.
   */
  DartType _declaredType;

  /**
   * The inferred type of this variable.
   */
  DartType _type;

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
   * Initialize using the given serialized information.
   */
  VariableElementImpl.forSerialized(ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

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
  DartObject get constantValue => evaluationResult?.value;

  void set declaredType(DartType type) {
    _declaredType = _checkElementOfType(type);
  }

  @override
  String get displayName => name;

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
    throw new StateError(
        "Invalid attempt to set a compile-time constant result");
  }

  @override
  bool get hasImplicitType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

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
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /**
   * Set whether this variable is const.
   */
  void set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  /**
   * Set whether this variable is final.
   */
  void set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get isPotentiallyMutatedInClosure => false;

  @override
  bool get isPotentiallyMutatedInScope => false;

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  DartType get type => _type ?? _declaredType;

  void set type(DartType type) {
    _type = _checkElementOfType(type);
  }

  /**
   * Return the error reported during type inference for this variable, or
   * `null` if this variable is not a subject of type inference, or there was
   * no error.
   */
  TopLevelInferenceError get typeInferenceError {
    return null;
  }

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write(type);
    buffer.write(" ");
    buffer.write(displayName);
  }

  @override
  DartObject computeConstantValue() => null;

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _initializer?.accept(visitor);
  }
}
