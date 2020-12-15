// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart'
    show Namespace, NamespaceBuilder;
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/constant.dart' show EvaluationResultImpl;
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:meta/meta.dart';

/// A concrete implementation of a [ClassElement].
abstract class AbstractClassElementImpl extends ElementImpl
    implements ClassElement {
  /// The type defined by the class.
  InterfaceType _thisType;

  /// A list containing all of the accessors (getters and setters) contained in
  /// this class.
  List<PropertyAccessorElement> _accessors;

  /// A list containing all of the fields contained in this class.
  List<FieldElement> _fields;

  /// A list containing all of the methods contained in this class.
  List<MethodElement> _methods;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  AbstractClassElementImpl(String name, int offset) : super(name, offset);

  AbstractClassElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  /// Initialize using the given serialized information.
  AbstractClassElementImpl.forSerialized(
      CompilationUnitElementImpl enclosingUnit)
      : super.forSerialized(enclosingUnit);

  @override
  List<PropertyAccessorElement> get accessors {
    return _accessors ?? const <PropertyAccessorElement>[];
  }

  /// Set the accessors contained in this class to the given [accessors].
  set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  String get displayName => name;

  @override
  List<FieldElement> get fields => _fields ?? const <FieldElement>[];

  /// Set the fields contained in this class to the given [fields].
  set fields(List<FieldElement> fields) {
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  bool get isDartCoreObject => false;

  @override
  bool get isEnum => false;

  @override
  bool get isMixin => false;

  @override
  List<InterfaceType> get superclassConstraints => const <InterfaceType>[];

  @override
  InterfaceType get thisType {
    if (_thisType == null) {
      List<DartType> typeArguments;
      if (typeParameters.isNotEmpty) {
        typeArguments = typeParameters.map<DartType>((t) {
          return t.instantiate(nullabilitySuffix: _noneOrStarSuffix);
        }).toList();
      } else {
        typeArguments = const <DartType>[];
      }
      return _thisType = instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: _noneOrStarSuffix,
      );
    }
    return _thisType;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitClassElement(this);

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
  PropertyAccessorElement getSetter(String setterName) {
    return getSetterFromAccessors(setterName, accessors);
  }

  @override
  InterfaceType instantiate({
    @required List<DartType> typeArguments,
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    if (typeArguments.length != typeParameters.length) {
      var ta = 'typeArguments.length (${typeArguments.length})';
      var tp = 'typeParameters.length (${typeParameters.length})';
      throw ArgumentError('$ta != $tp');
    }
    return InterfaceTypeImpl(
      element: this,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
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

  ExecutableElement lookUpInheritedConcreteMember(
      String name, LibraryElement library) {
    if (name.endsWith('=')) {
      return lookUpInheritedConcreteSetter(name, library);
    } else {
      return lookUpInheritedConcreteMethod(name, library) ??
          lookUpInheritedConcreteGetter(name, library);
    }
  }

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

  /// Return the static getter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement lookupStaticGetter(
      String name, LibraryElement library) {
    return _first(_implementationsOfGetter(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  /// Return the static method with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  MethodElement lookupStaticMethod(String name, LibraryElement library) {
    return _first(_implementationsOfMethod(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  /// Return the static setter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement lookupStaticSetter(
      String name, LibraryElement library) {
    return _first(_implementationsOfSetter(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(fields, visitor);
  }

  /// Return an iterable containing all of the implementations of a getter with
  /// the given [getterName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The getters that are returned are not filtered in any way. In particular,
  /// they can include getters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The getters are returned based on the depth of their defining class; if
  /// this class contains a definition of the getter it will occur first, if
  /// Object contains a definition of the getter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String getterName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
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

  /// Return an iterable containing all of the implementations of a method with
  /// the given [methodName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The methods that are returned are not filtered in any way. In particular,
  /// they can include methods that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The methods are returned based on the depth of their defining class; if
  /// this class contains a definition of the method it will occur first, if
  /// Object contains a definition of the method it will occur last.
  Iterable<MethodElement> _implementationsOfMethod(String methodName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
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

  /// Return an iterable containing all of the implementations of a setter with
  /// the given [setterName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The setters that are returned are not filtered in any way. In particular,
  /// they can include setters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The setters are returned based on the depth of their defining class; if
  /// this class contains a definition of the setter it will occur first, if
  /// Object contains a definition of the setter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String setterName) sync* {
    ClassElement classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
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

  static PropertyAccessorElement getSetterFromAccessors(
      String setterName, List<PropertyAccessorElement> accessors) {
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

  /// Return the first element from the given [iterable], or `null` if the
  /// iterable is empty.
  static E _first<E>(Iterable<E> iterable) {
    if (iterable.isEmpty) {
      return null;
    }
    return iterable.first;
  }
}

/// An [AbstractClassElementImpl] which is a class.
class ClassElementImpl extends AbstractClassElementImpl
    with TypeParameterizedElementMixin {
  /// The superclass of the class, or `null` for [Object].
  InterfaceType _supertype;

  /// A list containing all of the mixins that are applied to the class being
  /// extended in order to derive the superclass of this class.
  List<InterfaceType> _mixins;

  /// A list containing all of the interfaces that are implemented by this
  /// class.
  List<InterfaceType> _interfaces;

  /// For classes which are not mixin applications, a list containing all of the
  /// constructors contained in this class, or `null` if the list of
  /// constructors has not yet been built.
  ///
  /// For classes which are mixin applications, the list of constructors is
  /// computed on the fly by the [constructors] getter, and this field is
  /// `null`.
  List<ConstructorElement> _constructors;

  /// A flag indicating whether the types associated with the instance members
  /// of this class have been inferred.
  bool hasBeenInferred = false;

  /// This callback is set during mixins inference to handle reentrant calls.
  List<InterfaceType> Function(ClassElementImpl) linkedMixinInferenceCallback;

  /// TODO(scheglov) implement as modifier
  bool _isSimplyBounded = true;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassElementImpl(String name, int offset) : super(name, offset);

  ClassElementImpl.forLinkedNode(CompilationUnitElementImpl enclosing,
      Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    if (linkedNode is ClassDeclaration) {
      linkedNode.name.staticElement = this;
    } else if (linkedNode is ClassTypeAlias) {
      linkedNode.name.staticElement = this;
    }
    hasBeenInferred = !linkedContext.isLinking;
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors != null) return _accessors;

    if (linkedNode != null) {
      if (linkedNode is ClassOrMixinDeclaration) {
        _createPropertiesAndAccessors();
        assert(_accessors != null);
        return _accessors;
      } else {
        return _accessors = const [];
      }
    }

    return _accessors ??= const <PropertyAccessorElement>[];
  }

  @override
  List<InterfaceType> get allSupertypes {
    var sessionImpl = library.session as AnalysisSessionImpl;
    return sessionImpl.classHierarchy.implementedInterfaces(this);
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  List<ConstructorElement> get constructors {
    if (_constructors != null) {
      return _constructors;
    }

    if (isMixinApplication) {
      return _constructors = _computeMixinAppConstructors();
    }

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      var containerRef = reference.getChild('@constructor');
      _constructors = context.getConstructors(linkedNode).map((node) {
        var name = node.name?.name ?? '';
        var reference = containerRef.getChild(name);
        var element = node.declaredElement;
        element ??= ConstructorElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();

      if (_constructors.isEmpty) {
        return _constructors = [
          ConstructorElementImpl.forLinkedNode(
            this,
            containerRef.getChild(''),
            null,
          )
            ..isSynthetic = true
            ..name = ''
            ..nameOffset = -1,
        ];
      }
    }

    if (_constructors.isEmpty) {
      var constructor = ConstructorElementImpl('', -1);
      constructor.isSynthetic = true;
      constructor.enclosingElement = this;
      _constructors = <ConstructorElement>[constructor];
    }

    return _constructors;
  }

  /// Set the constructors contained in this class to the given [constructors].
  ///
  /// Should only be used for class elements that are not mixin applications.
  set constructors(List<ConstructorElement> constructors) {
    assert(!isMixinApplication);
    for (ConstructorElement constructor in constructors) {
      (constructor as ConstructorElementImpl).enclosingElement = this;
    }
    _constructors = constructors;
  }

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  List<FieldElement> get fields {
    if (_fields != null) return _fields;

    if (linkedNode != null) {
      if (linkedNode is ClassOrMixinDeclaration) {
        linkedContext.applyResolution(linkedNode);
        _createPropertiesAndAccessors();
        assert(_fields != null);
        return _fields;
      } else {
        _fields = const [];
      }
    }

    return _fields ?? const <FieldElement>[];
  }

  @override
  bool get hasNonFinalField {
    List<ClassElement> classesToVisit = <ClassElement>[];
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    classesToVisit.add(this);
    while (classesToVisit.isNotEmpty) {
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

  /// Return `true` if the class has a concrete `noSuchMethod()` method distinct
  /// from the one declared in class `Object`, as per the Dart Language
  /// Specification (section 10.4).
  bool get hasNoSuchMethod {
    MethodElement method = lookUpConcreteMethod(
        FunctionElement.NO_SUCH_METHOD_METHOD_NAME, library);
    var definingClass = method?.enclosingElement as ClassElement;
    return definingClass != null && !definingClass.isDartCoreObject;
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
  List<InterfaceType> get interfaces =>
      ElementTypeProvider.current.getClassInterfaces(this);

  set interfaces(List<InterfaceType> interfaces) {
    _interfaces = interfaces;
  }

  List<InterfaceType> get interfacesInternal {
    if (_interfaces != null) {
      return _interfaces;
    }

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      var implementsClause = context.getImplementsClause(linkedNode);
      if (implementsClause != null) {
        return _interfaces = implementsClause.interfaces
            .map((node) => node.type)
            .whereType<InterfaceType>()
            .where(_isInterfaceTypeInterface)
            .toList();
      } else {
        return _interfaces = const [];
      }
    }
    return _interfaces = const <InterfaceType>[];
  }

  @override
  bool get isAbstract {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isAbstract(linkedNode);
    }
    return hasModifier(Modifier.ABSTRACT);
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isDartCoreObject => !isMixin && supertype == null;

  @override
  bool get isMixinApplication {
    if (linkedNode != null) {
      return linkedNode is ClassTypeAlias;
    }
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  /// Set whether this class is a mixin application.
  set isMixinApplication(bool isMixinApplication) {
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  /// TODO(scheglov) implement as modifier
  @override
  bool get isSimplyBounded {
    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
    }
    return _isSimplyBounded;
  }

  /// TODO(scheglov) implement as modifier
  set isSimplyBounded(bool isSimplyBounded) {
    _isSimplyBounded = isSimplyBounded;
  }

  @override
  bool get isValidMixin {
    if (!supertype.isDartCoreObject) {
      return false;
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
  List<MethodElement> get methods {
    if (_methods != null) {
      return _methods;
    }

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      var containerRef = reference.getChild('@method');
      return _methods = context
          .getMethods(linkedNode)
          .where((node) => node.propertyKeyword == null)
          .map((node) {
        var name = node.name.name;
        var reference = containerRef.getChild(name);
        var element = node.declaredElement as MethodElement;
        element ??= MethodElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();
    }

    return _methods = const <MethodElement>[];
  }

  /// Set the methods contained in this class to the given [methods].
  set methods(List<MethodElement> methods) {
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    _methods = methods;
  }

  @override
  List<InterfaceType> get mixins {
    if (linkedMixinInferenceCallback != null) {
      _mixins = linkedMixinInferenceCallback(this);
    }

    if (_mixins != null) {
      return _mixins;
    }

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      var withClause = context.getWithClause(linkedNode);
      if (withClause != null) {
        return _mixins = withClause.mixinTypes
            .map((node) => node.type)
            .whereType<InterfaceType>()
            .where(_isInterfaceTypeInterface)
            .toList();
      } else {
        return _mixins = const [];
      }
    }
    return _mixins = const <InterfaceType>[];
  }

  set mixins(List<InterfaceType> mixins) {
    _mixins = mixins;
  }

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }
    return super.nameOffset;
  }

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  List<String> get superInvokedNames => const <String>[];

  @override
  InterfaceType get supertype {
    if (_supertype != null) return _supertype;

    if (hasModifier(Modifier.DART_CORE_OBJECT)) {
      return null;
    }

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var type = linkedContext.getSuperclass(linkedNode)?.type;
      if (_isInterfaceTypeClass(type)) {
        return _supertype = type;
      }
      if (library.isDartCore && name == 'Object') {
        setModifier(Modifier.DART_CORE_OBJECT, true);
        return null;
      }
      return _supertype = library.typeProvider.objectType;
    }
    return _supertype;
  }

  set supertype(InterfaceType supertype) {
    _supertype = supertype;
  }

  /// Set the type parameters defined for this class to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
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
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeClassElement(this);
  }

  @override
  ConstructorElement getNamedConstructor(String name) =>
      getNamedConstructorFromList(name, constructors);

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(constructors, visitor);
    safelyVisitChildren(methods, visitor);
    safelyVisitChildren(typeParameters, visitor);
  }

  /// Compute a list of constructors for this class, which is a mixin
  /// application.  If specified, [visitedClasses] is a list of the other mixin
  /// application classes which have been visited on the way to reaching this
  /// one (this is used to detect cycles).
  List<ConstructorElement> _computeMixinAppConstructors(
      [List<ClassElementImpl> visitedClasses]) {
    if (supertype == null) {
      // Shouldn't ever happen, since the only classes with no supertype are
      // Object and mixins, and they aren't a mixin application. But for
      // safety's sake just assume an empty list.
      assert(false);
      return <ConstructorElement>[];
    }

    var superElement = supertype.element as ClassElementImpl;

    // First get the list of constructors of the superclass which need to be
    // forwarded to this class.
    Iterable<ConstructorElement> constructorsToForward;
    if (!superElement.isMixinApplication) {
      var library = this.library;
      constructorsToForward = superElement.constructors
          .where((constructor) => constructor.isAccessibleIn(library))
          .where((constructor) => !constructor.isFactory);
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
    var superClassParameters = superElement.typeParameters;
    List<DartType> argumentTypes = List<DartType>.filled(
        superClassParameters.length, DynamicTypeImpl.instance);
    for (int i = 0; i < supertype.typeArguments.length; i++) {
      if (i >= argumentTypes.length) {
        break;
      }
      argumentTypes[i] = supertype.typeArguments[i];
    }
    var substitution =
        Substitution.fromPairs(superClassParameters, argumentTypes);

    bool typeHasInstanceVariables(InterfaceType type) =>
        type.element.fields.any((e) => !e.isSynthetic);

    // Now create an implicit constructor for every constructor found above,
    // substituting type parameters as appropriate.
    return constructorsToForward
        .map((ConstructorElement superclassConstructor) {
      var containerRef = reference.getChild('@constructor');
      var name = superclassConstructor.name;
      var implicitConstructor = ConstructorElementImpl.forLinkedNode(
          this, containerRef.getChild(name), null);
      implicitConstructor.isSynthetic = true;
      implicitConstructor.name = name;
      implicitConstructor.nameOffset = -1;
      implicitConstructor.redirectedConstructor = superclassConstructor;
      var hasMixinWithInstanceVariables = mixins.any(typeHasInstanceVariables);
      implicitConstructor.isConst =
          superclassConstructor.isConst && !hasMixinWithInstanceVariables;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      if (count > 0) {
        List<ParameterElement> implicitParameters =
            List<ParameterElement>.filled(count, null);
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter;
          if (superParameter is DefaultParameterElementImpl) {
            implicitParameter =
                DefaultParameterElementImpl(superParameter.name, -1)
                  ..constantInitializer = superParameter.constantInitializer;
          } else {
            implicitParameter = ParameterElementImpl(superParameter.name, -1);
          }
          implicitParameter.isConst = superParameter.isConst;
          implicitParameter.isFinal = superParameter.isFinal;
          // ignore: deprecated_member_use_from_same_package
          implicitParameter.parameterKind = superParameter.parameterKind;
          implicitParameter.isSynthetic = true;
          implicitParameter.type =
              substitution.substituteType(superParameter.type);
          implicitParameters[i] = implicitParameter;
        }
        implicitConstructor.parameters = implicitParameters;
      }
      implicitConstructor.enclosingElement = this;
      return implicitConstructor;
    }).toList(growable: false);
  }

  void _createPropertiesAndAccessors() {
    assert(_accessors == null);
    assert(_fields == null);

    var context = enclosingUnit.linkedContext;
    var accessorList = <PropertyAccessorElement>[];
    var fieldList = <FieldElement>[];

    var fields = context.getFields(linkedNode);
    for (var field in fields) {
      var name = field.name.name;
      var fieldElement = field.declaredElement as FieldElementImpl;
      fieldElement ??= FieldElementImpl.forLinkedNodeFactory(
          this, reference.getChild('@field').getChild(name), field);
      fieldList.add(fieldElement);

      accessorList.add(fieldElement.getter);
      if (fieldElement.setter != null) {
        accessorList.add(fieldElement.setter);
      }
    }

    var methods = context.getMethods(linkedNode);
    for (var method in methods) {
      var isGetter = method.isGetter;
      var isSetter = method.isSetter;
      if (!isGetter && !isSetter) continue;

      var name = method.name.name;
      var containerRef = isGetter
          ? reference.getChild('@getter')
          : reference.getChild('@setter');

      var accessorElement =
          method.declaredElement as PropertyAccessorElementImpl;
      accessorElement ??= PropertyAccessorElementImpl.forLinkedNode(
          this, containerRef.getChild(name), method);
      accessorList.add(accessorElement);

      var fieldRef = reference.getChild('@field').getChild(name);
      FieldElementImpl field = fieldRef.element;
      if (field == null) {
        field = FieldElementImpl(name, -1);
        fieldRef.element = field;
        field.enclosingElement = this;
        field.isSynthetic = true;
        field.isFinal = isGetter;
        field.isStatic = accessorElement.isStatic;
        fieldList.add(field);
      } else {
        field.isFinal = false;
      }

      accessorElement.variable = field;
      if (isGetter) {
        field.getter ??= accessorElement;
      } else {
        field.setter ??= accessorElement;
      }
    }

    _accessors = accessorList;
    _fields = fieldList;
  }

  /// Return `true` if the given [type] is an [InterfaceType] that can be used
  /// as a class.
  bool _isInterfaceTypeClass(DartType type) {
    if (type is InterfaceType) {
      var element = type.element;
      if (element.isEnum || element.isMixin) {
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
    return false;
  }

  /// Return `true` if the given [type] is an [InterfaceType] that can be used
  /// as an interface or a mixin.
  bool _isInterfaceTypeInterface(DartType type) {
    if (type is InterfaceType) {
      if (type.element.isEnum) {
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
    return false;
  }

  static ConstructorElement getNamedConstructorFromList(
      String name, List<ConstructorElement> constructors) {
    for (ConstructorElement element in constructors) {
      String elementName = element.name;
      if (elementName != null && elementName == name) {
        return element;
      }
    }
    return null;
  }
}

/// A concrete implementation of a [CompilationUnitElement].
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement {
  @override
  final LinkedUnitContext linkedContext;

  /// The source that corresponds to this compilation unit.
  @override
  Source source;

  @override
  LineInfo lineInfo;

  /// The source of the library containing this compilation unit.
  ///
  /// This is the same as the source of the containing [LibraryElement],
  /// except that it does not require the containing [LibraryElement] to be
  /// computed.
  @override
  Source librarySource;

  /// A list containing all of the top-level accessors (getters and setters)
  /// contained in this compilation unit.
  List<PropertyAccessorElement> _accessors;

  /// A list containing all of the enums contained in this compilation unit.
  List<ClassElement> _enums;

  /// A list containing all of the extensions contained in this compilation
  /// unit.
  List<ExtensionElement> _extensions;

  /// A list containing all of the top-level functions contained in this
  /// compilation unit.
  List<FunctionElement> _functions;

  /// A list containing all of the mixins contained in this compilation unit.
  List<ClassElement> _mixins;

  /// A list containing all of the function type aliases contained in this
  /// compilation unit.
  List<FunctionTypeAliasElement> _functionTypeAliases;

  /// A list containing all of the type aliases contained in this compilation
  /// unit.
  List<TypeAliasElement> _typeAliases;

  /// A list containing all of the classes contained in this compilation unit.
  List<ClassElement> _types;

  /// A list containing all of the variables contained in this compilation unit.
  List<TopLevelVariableElement> _variables;

  /// Initialize a newly created compilation unit element to have the given
  /// [name].
  CompilationUnitElementImpl()
      : linkedContext = null,
        super(null, -1);

  CompilationUnitElementImpl.forLinkedNode(LibraryElementImpl enclosingLibrary,
      this.linkedContext, Reference reference, CompilationUnitImpl linkedNode)
      : super.forLinkedNode(enclosingLibrary, reference, linkedNode) {
    _nameOffset = -1;
    linkedNode.declaredElement = this;
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors != null) return _accessors;

    if (linkedNode != null) {
      _createPropertiesAndAccessors(this);
      assert(_accessors != null);
      return _accessors;
    }

    return _accessors ?? const <PropertyAccessorElement>[];
  }

  /// Set the top-level accessors (getters and setters) contained in this
  /// compilation unit to the given [accessors].
  set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
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
    if (_enums != null) return _enums;

    if (linkedNode != null) {
      var containerRef = reference.getChild('@enum');
      CompilationUnit linkedNode = this.linkedNode;
      _enums = linkedNode.declarations.whereType<EnumDeclaration>().map((node) {
        var name = node.name.name;
        var reference = containerRef.getChild(name);
        var element = node.declaredElement;
        element ??= EnumElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();
    }

    return _enums ??= const <ClassElement>[];
  }

  /// Set the enums contained in this compilation unit to the given [enums].
  set enums(List<ClassElement> enums) {
    for (ClassElement enumDeclaration in enums) {
      (enumDeclaration as EnumElementImpl).enclosingElement = this;
    }
    _enums = enums;
  }

  @override
  List<ExtensionElement> get extensions {
    if (_extensions != null) {
      return _extensions;
    }

    if (linkedNode != null) {
      CompilationUnit linkedNode = this.linkedNode;
      var containerRef = reference.getChild('@extension');
      _extensions = <ExtensionElement>[];
      var nextUnnamedExtensionId = 0;
      for (var node in linkedNode.declarations) {
        if (node is ExtensionDeclaration) {
          var nameIdentifier = node.name;
          var refName = nameIdentifier != null
              ? nameIdentifier.name
              : 'extension-${nextUnnamedExtensionId++}';
          var reference = containerRef.getChild(refName);
          var element = node.declaredElement;
          element ??= ExtensionElementImpl.forLinkedNode(this, reference, node);
          _extensions.add(element);
        }
      }
      return _extensions;
    }
    return _extensions ?? const <ExtensionElement>[];
  }

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionElement> extensions) {
    for (ExtensionElement extension in extensions) {
      (extension as ExtensionElementImpl).enclosingElement = this;
    }
    _extensions = extensions;
  }

  @override
  List<FunctionElement> get functions {
    if (_functions != null) return _functions;

    if (linkedNode != null) {
      var containerRef = reference.getChild('@function');
      return _functions = linkedContext.unit_withDeclarations.declarations
          .whereType<FunctionDeclaration>()
          .where((node) => !node.isGetter && !node.isSetter)
          .map((node) {
        var name = node.name.name;
        var reference = containerRef.getChild(name);
        var element = node.declaredElement as FunctionElement;
        element ??= FunctionElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();
    }
    return _functions ?? const <FunctionElement>[];
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    _functions = functions;
  }

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases {
    return _functionTypeAliases ??=
        typeAliases.whereType<FunctionTypeAliasElement>().toList();
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
  String get identifier => '${source.uri}';

  @override
  bool get isSynthetic {
    if (linkedContext != null) {
      return linkedContext.isSynthetic;
    }
    return super.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  List<ClassElement> get mixins {
    if (_mixins != null) return _mixins;

    if (linkedNode != null) {
      CompilationUnit linkedNode = this.linkedNode;
      var containerRef = reference.getChild('@mixin');
      var declarations = linkedNode.declarations;
      return _mixins = declarations.whereType<MixinDeclaration>().map((node) {
        var name = node.name.name;
        var reference = containerRef.getChild(name);
        var element = node.declaredElement as MixinElementImpl;
        element ??= MixinElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();
    }

    return _mixins ?? const <ClassElement>[];
  }

  /// Set the mixins contained in this compilation unit to the given [mixins].
  set mixins(List<ClassElement> mixins) {
    for (MixinElementImpl type in mixins) {
      type.enclosingElement = this;
    }
    _mixins = mixins;
  }

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    if (_variables != null) return _variables;

    if (linkedNode != null) {
      _createPropertiesAndAccessors(this);
      assert(_variables != null);
      return _variables;
    }

    return _variables ?? const <TopLevelVariableElement>[];
  }

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableElement> variables) {
    for (TopLevelVariableElement field in variables) {
      (field as TopLevelVariableElementImpl).enclosingElement = this;
    }
    _variables = variables;
  }

  @override
  List<TypeAliasElement> get typeAliases {
    if (_typeAliases != null) return _typeAliases;

    if (linkedNode != null) {
      var containerRef = reference.getChild('@typeAlias');
      _typeAliases = <TypeAliasElement>[];
      for (var node in linkedContext.unit_withDeclarations.declarations) {
        String name;
        if (node is FunctionTypeAlias) {
          name = node.name.name;
        } else if (node is GenericTypeAlias) {
          name = node.name.name;
        } else {
          continue;
        }

        var reference = containerRef.getChild(name);
        var element = node.declaredElement as TypeAliasElement;
        element ??=
            TypeAliasElementImpl.forLinkedNodeFactory(this, reference, node);
        _typeAliases.add(element);
      }
    }

    return _typeAliases ?? const <TypeAliasElement>[];
  }

  /// Set the function type aliases contained in this compilation unit to the
  /// given [typeAliases].
  set typeAliases(List<FunctionTypeAliasElement> typeAliases) {
    for (FunctionTypeAliasElement typeAlias in typeAliases) {
      (typeAlias as ElementImpl).enclosingElement = this;
    }
    _typeAliases = typeAliases;
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext => null;

  @override
  List<ClassElement> get types {
    if (_types != null) return _types;

    if (linkedNode != null) {
      var containerRef = reference.getChild('@class');
      _types = <ClassElement>[];
      for (var node in linkedContext.unit_withDeclarations.declarations) {
        if (node is ClassDeclaration) {
          var name = node.name.name;
          var reference = containerRef.getChild(name);
          var element = node.declaredElement;
          element ??= ClassElementImpl.forLinkedNode(this, reference, node);
          _types.add(element);
        } else if (node is ClassTypeAlias) {
          var name = node.name.name;
          var reference = containerRef.getChild(name);
          var element = node.declaredElement;
          element ??= ClassElementImpl.forLinkedNode(this, reference, node);
          _types.add(element);
        }
      }
      return _types;
    }

    return _types ?? const <ClassElement>[];
  }

  /// Set the types contained in this compilation unit to the given [types].
  set types(List<ClassElement> types) {
    for (ClassElement type in types) {
      // Another implementation of ClassElement is _DeferredClassElement,
      // which is used to resynthesize classes lazily. We cannot cast it
      // to ClassElementImpl, and it already can provide correct values of the
      // 'enclosingElement' property.
      if (type is ClassElementImpl) {
        type.enclosingElement = this;
      }
    }
    _types = types;
  }

  @override
  bool operator ==(Object object) =>
      object is CompilationUnitElementImpl && source == object.source;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitCompilationUnitElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeCompilationUnitElement(this);
  }

  @override
  ClassElement getEnum(String enumName) {
    for (ClassElement enumDeclaration in enums) {
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

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(enums, visitor);
    safelyVisitChildren(extensions, visitor);
    safelyVisitChildren(functions, visitor);
    safelyVisitChildren(functionTypeAliases, visitor);
    safelyVisitChildren(mixins, visitor);
    safelyVisitChildren(types, visitor);
    safelyVisitChildren(topLevelVariables, visitor);
  }

  static void _createPropertiesAndAccessors(CompilationUnitElementImpl unit) {
    if (unit._variables != null) return;
    assert(unit._accessors == null);

    var accessorMap =
        <CompilationUnitElementImpl, List<PropertyAccessorElement>>{};
    var variableMap =
        <CompilationUnitElementImpl, List<TopLevelVariableElement>>{};

    var units = unit.library.units;
    for (CompilationUnitElementImpl unit in units) {
      var context = unit.linkedContext;

      var accessorList = <PropertyAccessorElement>[];
      accessorMap[unit] = accessorList;

      var variableList = <TopLevelVariableElement>[];
      variableMap[unit] = variableList;

      // TODO(scheglov) Bad, we want to read only functions / variables.
      var unitNode = context.unit_withDeclarations;
      var unitDeclarations = unitNode.declarations;

      var variables = context.topLevelVariables(unitNode);
      for (var variable in variables) {
        var variableElement =
            variable.declaredElement as TopLevelVariableElementImpl;
        if (variableElement == null) {
          var name = variable.name.name;
          var reference = unit.reference.getChild('@variable').getChild(name);
          variableElement = TopLevelVariableElementImpl.forLinkedNodeFactory(
              unit, reference, variable);
        }
        variableList.add(variableElement);

        accessorList.add(variableElement.getter);
        if (variableElement.setter != null) {
          accessorList.add(variableElement.setter);
        }
      }

      for (var node in unitDeclarations) {
        if (node is FunctionDeclaration) {
          var isGetter = node.isGetter;
          var isSetter = node.isSetter;
          if (!isGetter && !isSetter) continue;

          var name = node.name.name;
          var containerRef = isGetter
              ? unit.reference.getChild('@getter')
              : unit.reference.getChild('@setter');

          var accessorElement =
              node.declaredElement as PropertyAccessorElementImpl;
          accessorElement ??= PropertyAccessorElementImpl.forLinkedNode(
              unit, containerRef.getChild(name), node);
          accessorList.add(accessorElement);

          var fieldRef = unit.reference.getChild('@variable').getChild(name);
          TopLevelVariableElementImpl field = fieldRef.element;
          if (field == null) {
            field = TopLevelVariableElementImpl(name, -1);
            fieldRef.element = field;
            field.enclosingElement = unit;
            field.isSynthetic = true;
            field.isFinal = isGetter;
            variableList.add(field);
          } else {
            field.isFinal = false;
          }

          accessorElement.variable = field;
          if (isGetter) {
            field.getter = accessorElement;
          } else {
            field.setter = accessorElement;
          }
        }
      }
    }

    for (CompilationUnitElementImpl unit in units) {
      unit._accessors = accessorMap[unit];
      unit._variables = variableMap[unit];
    }
  }
}

/// A [FieldElement] for a 'const' or 'final' field that has an initializer.
///
/// TODO(paulberry): we should rename this class to reflect the fact that it's
/// used for both const and final fields.  However, we shouldn't do so until
/// we've created an API for reading the values of constants; until that API is
/// available, clients are likely to read constant values by casting to
/// ConstFieldElementImpl, so it would be a breaking change to rename this
/// class.
class ConstFieldElementImpl extends FieldElementImpl with ConstVariableElement {
  /// Initialize a newly created synthetic field element to have the given
  /// [name] and [offset].
  ConstFieldElementImpl(String name, int offset) : super(name, offset);

  ConstFieldElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);
}

/// A field element representing an enum constant.
class ConstFieldElementImpl_EnumValue extends ConstFieldElementImpl_ofEnum {
  final int _index;

  ConstFieldElementImpl_EnumValue(EnumElementImpl enumElement, this._index)
      : super(enumElement);

  ConstFieldElementImpl_EnumValue.forLinkedNode(EnumElementImpl enumElement,
      Reference reference, AstNode linkedNode, this._index)
      : super.forLinkedNode(enumElement, reference, linkedNode);

  @override
  Expression get constantInitializer => null;

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  EvaluationResultImpl get evaluationResult {
    if (_evaluationResult == null) {
      Map<String, DartObjectImpl> fieldMap = <String, DartObjectImpl>{
        'index': DartObjectImpl(
          library.typeSystem,
          library.typeProvider.intType,
          IntState(_index),
        ),
        // TODO(brianwilkerson) There shouldn't be a field with the same name as
        //  the constant, but we can't remove it until a version of dartdoc that
        //  doesn't depend on it has been published and pulled into the SDK. The
        //  map entry below should be removed when
        //  https://github.com/dart-lang/dartdoc/issues/2318 has been resolved.
        name: DartObjectImpl(
          library.typeSystem,
          library.typeProvider.intType,
          IntState(_index),
        ),
      };
      DartObjectImpl value = DartObjectImpl(
        library.typeSystem,
        type,
        GenericState(fieldMap),
      );
      _evaluationResult = EvaluationResultImpl(value);
    }
    return _evaluationResult;
  }

  @override
  bool get hasInitializer => false;

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }
    return super.nameOffset;
  }

  @override
  InterfaceType get type => ElementTypeProvider.current.getFieldType(this);

  @override
  InterfaceType get typeInternal => _enum.thisType;
}

/// The synthetic `values` field of an enum.
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
      _evaluationResult = EvaluationResultImpl(
        DartObjectImpl(
          library.typeSystem,
          type,
          ListState(constantValues),
        ),
      );
    }
    return _evaluationResult;
  }

  @override
  String get name => 'values';

  @override
  InterfaceType get type => ElementTypeProvider.current.getFieldType(this);

  @override
  InterfaceType get typeInternal {
    if (_type == null) {
      return _type = library.typeProvider.listType2(_enum.thisType);
    }
    return _type;
  }
}

/// An abstract constant field of an enum.
abstract class ConstFieldElementImpl_ofEnum extends ConstFieldElementImpl {
  final EnumElementImpl _enum;

  ConstFieldElementImpl_ofEnum(this._enum) : super(null, -1) {
    enclosingElement = _enum;
  }

  ConstFieldElementImpl_ofEnum.forLinkedNode(
      this._enum, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(_enum, reference, linkedNode);

  @override
  set evaluationResult(_) {
    assert(false);
  }

  @override
  bool get isConst => true;

  @override
  set isConst(bool isConst) {
    assert(false);
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  set isFinal(bool isFinal) {
    assert(false);
  }

  @override
  bool get isStatic => true;

  @override
  set isStatic(bool isStatic) {
    assert(false);
  }

  @override
  set type(DartType type) {
    assert(false);
  }
}

/// A [LocalVariableElement] for a local 'const' variable that has an
/// initializer.
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created local variable element to have the given [name]
  /// and [offset].
  ConstLocalVariableElementImpl(String name, int offset) : super(name, offset);
}

/// A concrete implementation of a [ConstructorElement].
class ConstructorElementImpl extends ExecutableElementImpl
    with ConstructorElementMixin
    implements ConstructorElement {
  /// The constructor to which this constructor is redirecting.
  ConstructorElement _redirectedConstructor;

  /// The initializers for this constructor (used for evaluating constant
  /// instance creation expressions).
  List<ConstructorInitializer> _constantInitializers;

  /// The offset of the `.` before this constructor name or `null` if not named.
  int _periodOffset;

  /// Return the offset of the character immediately following the last
  /// character of this constructor's name, or `null` if not named.
  int _nameEnd;

  /// For every constructor we initially set this flag to `true`, and then
  /// set it to `false` during computing constant values if we detect that it
  /// is a part of a cycle.
  bool _isCycleFree = true;

  @override
  bool isConstantEvaluated = false;

  /// Initialize a newly created constructor element to have the given [name]
  /// and [offset].
  ConstructorElementImpl(String name, int offset) : super(name, offset);

  ConstructorElementImpl.forLinkedNode(ClassElementImpl enclosingClass,
      Reference reference, ConstructorDeclarationImpl linkedNode)
      : super.forLinkedNode(enclosingClass, reference, linkedNode) {
    linkedNode?.declaredElement = this;
  }

  /// Return the constant initializers for this element, which will be empty if
  /// there are no initializers, or `null` if there was an error in the source.
  List<ConstructorInitializer> get constantInitializers {
    if (_constantInitializers != null) return _constantInitializers;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      return _constantInitializers = linkedContext.getConstructorInitializers(
        linkedNode,
      );
    }

    return _constantInitializers;
  }

  set constantInitializers(List<ConstructorInitializer> constantInitializers) {
    _constantInitializers = constantInitializers;
  }

  @override
  ConstructorElement get declaration => this;

  @override
  String get displayName {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.displayName;
  }

  @override
  ClassElementImpl get enclosingElement =>
      super.enclosingElement as ClassElementImpl;

  @override
  bool get isConst {
    if (linkedNode != null) {
      ConstructorDeclaration linkedNode = this.linkedNode;
      return linkedNode.constKeyword != null;
    }
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this constructor represents a 'const' constructor.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  bool get isCycleFree {
    return _isCycleFree;
  }

  set isCycleFree(bool isCycleFree) {
    // This property is updated in ConstantEvaluationEngine even for
    // resynthesized constructors, so we don't have the usual assert here.
    _isCycleFree = isCycleFree;
  }

  @override
  bool get isFactory {
    if (linkedNode != null) {
      ConstructorDeclaration linkedNode = this.linkedNode;
      return linkedNode.factoryKeyword != null;
    }
    return hasModifier(Modifier.FACTORY);
  }

  /// Set whether this constructor represents a factory method.
  set isFactory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  bool get isStatic => false;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameEnd {
    if (linkedNode != null) {
      var node = linkedNode as ConstructorDeclaration;
      if (node.name != null) {
        return node.name.end;
      } else {
        return node.returnType.end;
      }
    }

    return _nameEnd;
  }

  set nameEnd(int nameEnd) {
    _nameEnd = nameEnd;
  }

  @override
  int get periodOffset {
    if (linkedNode != null) {
      var node = linkedNode as ConstructorDeclaration;
      return node.period?.offset;
    }

    return _periodOffset;
  }

  set periodOffset(int periodOffset) {
    _periodOffset = periodOffset;
  }

  @override
  ConstructorElement get redirectedConstructor {
    if (_redirectedConstructor != null) return _redirectedConstructor;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      if (isFactory) {
        var node = context.getConstructorRedirected(linkedNode);
        return _redirectedConstructor = node?.staticElement;
      } else {
        var initializers = context.getConstructorInitializers(linkedNode);
        for (var initializer in initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            return _redirectedConstructor = initializer.staticElement;
          }
        }
      }
      return null;
    }

    return _redirectedConstructor;
  }

  set redirectedConstructor(ConstructorElement redirectedConstructor) {
    _redirectedConstructor = redirectedConstructor;
  }

  @override
  InterfaceType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false);
  }

  @override
  InterfaceType get returnTypeInternal {
    return _returnType ??= enclosingElement.thisType;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false);
  }

  @override
  FunctionType get typeInternal {
    // TODO(scheglov) Remove "element" in the breaking changes branch.
    return _type ??= FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// Ensures that dependencies of this constructor, such as default values
  /// of formal parameters, are evaluated.
  void computeConstantDependencies() {
    if (!isConstantEvaluated) {
      AnalysisOptionsImpl analysisOptions = context.analysisOptions;
      computeConstants(library.typeProvider, library.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
  }
}

/// Common implementation for methods defined in [ConstructorElement].
mixin ConstructorElementMixin implements ConstructorElement {
  @override
  bool get isDefaultConstructor {
    // unnamed
    var name = this.name;
    if (name != null && name.isNotEmpty) {
      return false;
    }
    // no required parameters
    for (ParameterElement parameter in parameters) {
      if (parameter.isNotOptional) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }
}

/// A [TopLevelVariableElement] for a top-level 'const' variable that has an
/// initializer.
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  ConstTopLevelVariableElementImpl(String name, int offset)
      : super(name, offset);

  ConstTopLevelVariableElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);
}

/// Mixin used by elements that represent constant variables and have
/// initializers.
///
/// Note that in correct Dart code, all constant variables must have
/// initializers.  However, analyzer also needs to handle incorrect Dart code,
/// in which case there might be some constant variables that lack initializers.
/// This interface is only used for constant variables that have initializers.
///
/// This class is not intended to be part of the public API for analyzer.
mixin ConstVariableElement implements ElementImpl, ConstantEvaluationTarget {
  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression _constantInitializer;

  EvaluationResultImpl _evaluationResult;

  Expression get constantInitializer {
    if (_constantInitializer != null) return _constantInitializer;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      return _constantInitializer = linkedContext.getInitializer(linkedNode);
    }

    return _constantInitializer;
  }

  set constantInitializer(Expression constantInitializer) {
    _constantInitializer = constantInitializer;
  }

  EvaluationResultImpl get evaluationResult => _evaluationResult;

  set evaluationResult(EvaluationResultImpl evaluationResult) {
    _evaluationResult = evaluationResult;
  }

  @override
  bool get isConstantEvaluated => _evaluationResult != null;

  /// Return a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  DartObject computeConstantValue() {
    if (evaluationResult == null) {
      AnalysisOptionsImpl analysisOptions = context.analysisOptions;
      computeConstants(library.typeProvider, library.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
    return evaluationResult?.value;
  }
}

/// A [FieldFormalParameterElementImpl] for parameters that have an initializer.
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultFieldFormalParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  DefaultFieldFormalParameterElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);
}

/// A [ParameterElement] for parameters that have an initializer.
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  DefaultParameterElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static DynamicElementImpl get instance =>
      DynamicTypeImpl.instance.element as DynamicElementImpl;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  DynamicElementImpl() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  T accept<T>(ElementVisitor<T> visitor) => null;
}

/// A concrete implementation of an [ElementAnnotation].
class ElementAnnotationImpl implements ElementAnnotation {
  /// The name of the top-level variable used to mark that a function always
  /// throws, for dead code purposes.
  static const String _ALWAYS_THROWS_VARIABLE_NAME = "alwaysThrows";

  /// The name of the class used to mark an element as being deprecated.
  static const String _DEPRECATED_CLASS_NAME = "Deprecated";

  /// The name of the top-level variable used to mark an element as being
  /// deprecated.
  static const String _DEPRECATED_VARIABLE_NAME = "deprecated";

  /// The name of the top-level variable used to mark an element as not to be
  /// stored.
  static const String _DO_NOT_STORE_VARIABLE_NAME = "doNotStore";

  /// The name of the top-level variable used to mark a method as being a
  /// factory.
  static const String _FACTORY_VARIABLE_NAME = "factory";

  /// The name of the top-level variable used to mark a class and its subclasses
  /// as being immutable.
  static const String _IMMUTABLE_VARIABLE_NAME = "immutable";

  /// The name of the top-level variable used to mark an element as being
  /// internal to its package.
  static const String _INTERNAL_VARIABLE_NAME = "internal";

  /// The name of the top-level variable used to mark a constructor as being
  /// literal.
  static const String _LITERAL_VARIABLE_NAME = "literal";

  /// The name of the top-level variable used to mark a type as having
  /// "optional" type arguments.
  static const String _OPTIONAL_TYPE_ARGS_VARIABLE_NAME = "optionalTypeArgs";

  /// The name of the top-level variable used to mark a function as running
  /// a single test.
  static const String _IS_TEST_VARIABLE_NAME = "isTest";

  /// The name of the top-level variable used to mark a function as running
  /// a test group.
  static const String _IS_TEST_GROUP_VARIABLE_NAME = "isTestGroup";

  /// The name of the class used to JS annotate an element.
  static const String _JS_CLASS_NAME = "JS";

  /// The name of `js` library, used to define JS annotations.
  static const String _JS_LIB_NAME = "js";

  /// The name of `meta` library, used to define analysis annotations.
  static const String _META_LIB_NAME = "meta";

  /// The name of `meta_meta` library, used to define annotations for other
  /// annotations.
  static const String _META_META_LIB_NAME = "meta_meta";

  /// The name of the top-level variable used to mark a method as requiring
  /// overriders to call super.
  static const String _MUST_CALL_SUPER_VARIABLE_NAME = "mustCallSuper";

  /// The name of `angular.meta` library, used to define angular analysis
  /// annotations.
  static const String _NG_META_LIB_NAME = "angular.meta";

  /// The name of the top-level variable used to mark a member as being nonVirtual.
  static const String _NON_VIRTUAL_VARIABLE_NAME = "nonVirtual";

  /// The name of the top-level variable used to mark a method as being expected
  /// to override an inherited method.
  static const String _OVERRIDE_VARIABLE_NAME = "override";

  /// The name of the top-level variable used to mark a method as being
  /// protected.
  static const String _PROTECTED_VARIABLE_NAME = "protected";

  /// The name of the top-level variable used to mark a class as implementing a
  /// proxy object.
  static const String PROXY_VARIABLE_NAME = "proxy";

  /// The name of the class used to mark a parameter as being required.
  static const String _REQUIRED_CLASS_NAME = "Required";

  /// The name of the top-level variable used to mark a parameter as being
  /// required.
  static const String _REQUIRED_VARIABLE_NAME = "required";

  /// The name of the top-level variable used to mark a class as being sealed.
  static const String _SEALED_VARIABLE_NAME = "sealed";

  /// The name of the class used to annotate a class as an annotation with a
  /// specific set of target element kinds.
  static const String _TARGET_CLASS_NAME = 'Target';

  /// The name of the top-level variable used to mark a method as being
  /// visible for templates.
  static const String _VISIBLE_FOR_TEMPLATE_VARIABLE_NAME =
      "visibleForTemplate";

  /// The name of the top-level variable used to mark a method as being
  /// visible for testing.
  static const String _VISIBLE_FOR_TESTING_VARIABLE_NAME = "visibleForTesting";

  @override
  Element element;

  /// The compilation unit in which this annotation appears.
  CompilationUnitElementImpl compilationUnit;

  /// The AST of the annotation itself, cloned from the resolved AST for the
  /// source code.
  Annotation annotationAst;

  /// The result of evaluating this annotation as a compile-time constant
  /// expression, or `null` if the compilation unit containing the variable has
  /// not been resolved.
  EvaluationResultImpl evaluationResult;

  /// Initialize a newly created annotation. The given [compilationUnit] is the
  /// compilation unit in which the annotation appears.
  ElementAnnotationImpl(this.compilationUnit);

  @override
  List<AnalysisError> get constantEvaluationErrors =>
      evaluationResult?.errors ?? const <AnalysisError>[];

  @override
  AnalysisContext get context => compilationUnit.library.context;

  @override
  bool get isAlwaysThrows =>
      element is PropertyAccessorElement &&
      element.name == _ALWAYS_THROWS_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isConstantEvaluated => evaluationResult != null;

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
  bool get isDoNotStore =>
      element is PropertyAccessorElement &&
      element.name == _DO_NOT_STORE_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

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
  bool get isInternal =>
      element is PropertyAccessorElement &&
      element.name == _INTERNAL_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isIsTest =>
      element is PropertyAccessorElement &&
      element.name == _IS_TEST_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isIsTestGroup =>
      element is PropertyAccessorElement &&
      element.name == _IS_TEST_GROUP_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isJS =>
      element is ConstructorElement &&
      element.enclosingElement.name == _JS_CLASS_NAME &&
      element.library?.name == _JS_LIB_NAME;

  @override
  bool get isLiteral =>
      element is PropertyAccessorElement &&
      element.name == _LITERAL_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isMustCallSuper =>
      element is PropertyAccessorElement &&
      element.name == _MUST_CALL_SUPER_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isNonVirtual =>
      element is PropertyAccessorElement &&
      element.name == _NON_VIRTUAL_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isOptionalTypeArgs =>
      element is PropertyAccessorElement &&
      element.name == _OPTIONAL_TYPE_ARGS_VARIABLE_NAME &&
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

  @override
  bool get isSealed =>
      element is PropertyAccessorElement &&
      element.name == _SEALED_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  bool get isTarget =>
      element is ConstructorElement &&
      element.enclosingElement.name == _TARGET_CLASS_NAME &&
      element.library?.name == _META_META_LIB_NAME;

  @override
  bool get isVisibleForTemplate =>
      element is PropertyAccessorElement &&
      element.name == _VISIBLE_FOR_TEMPLATE_VARIABLE_NAME &&
      element.library?.name == _NG_META_LIB_NAME;

  @override
  bool get isVisibleForTesting =>
      element is PropertyAccessorElement &&
      element.name == _VISIBLE_FOR_TESTING_VARIABLE_NAME &&
      element.library?.name == _META_LIB_NAME;

  @override
  LibraryElement get library => compilationUnit.library;

  /// Get the library containing this annotation.
  @override
  Source get librarySource => compilationUnit.librarySource;

  @override
  Source get source => compilationUnit.source;

  @override
  DartObject computeConstantValue() {
    if (evaluationResult == null) {
      AnalysisOptionsImpl analysisOptions = context.analysisOptions;
      LibraryElement library = compilationUnit.library;
      computeConstants(library.typeProvider, library.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
    return evaluationResult?.value;
  }

  @override
  String toSource() => annotationAst.toSource();

  @override
  String toString() => '@$element';
}

/// A base class for concrete implementations of an [Element].
abstract class ElementImpl implements Element {
  /// An Unicode right arrow.
  @deprecated
  static final String RIGHT_ARROW = " \u2192 ";

  static int _NEXT_ID = 0;

  @override
  final int id = _NEXT_ID++;

  /// The enclosing element of this element, or `null` if this element is at the
  /// root of the element structure.
  ElementImpl _enclosingElement;

  Reference reference;
  final AstNode linkedNode;

  /// The name of this element.
  String _name;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element.
  int _nameOffset = 0;

  /// A bit-encoded form of the modifiers associated with this element.
  int _modifiers = 0;

  /// A list containing all of the metadata associated with this element.
  List<ElementAnnotation> _metadata;

  /// A cached copy of the calculated hashCode for this element.
  int _cachedHashCode;

  /// A cached copy of the calculated location for this element.
  ElementLocation _cachedLocation;

  /// The documentation comment for this element.
  String _docComment;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int _codeOffset;

  /// The length of the element's code, or `null` if the element is synthetic.
  int _codeLength;

  /// The language version for the library.
  LibraryLanguageVersion _languageVersion;

  /// Initialize a newly created element to have the given [name] at the given
  /// [_nameOffset].
  ElementImpl(String name, this._nameOffset, {this.reference})
      : linkedNode = null {
    _name = StringUtilities.intern(name);
    reference?.element = this;
  }

  /// Initialize from linked node.
  ElementImpl.forLinkedNode(
      this._enclosingElement, this.reference, this.linkedNode) {
    reference?.element ??= this;
  }

  /// Initialize from serialized information.
  ElementImpl.forSerialized(this._enclosingElement)
      : reference = null,
        linkedNode = null;

  /// The length of the element's code, or `null` if the element is synthetic.
  int get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.context;
  }

  @override
  Element get declaration => this;

  @override
  String get displayName => _name;

  @override
  String get documentationComment => _docComment;

  /// The documentation comment source for this element.
  set documentationComment(String doc) {
    _docComment = doc?.replaceAll('\r\n', '\n');
  }

  @override
  Element get enclosingElement => _enclosingElement;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement(Element element) {
    _enclosingElement = element as ElementImpl;
  }

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement?.enclosingUnit;
  }

  @override
  bool get hasAlwaysThrows {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDeprecated {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDoNotStore {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasFactory {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode {
    // TODO: We might want to re-visit this optimization in the future.
    // We cache the hash code value as this is a very frequently called method.
    return _cachedHashCode ??= location.hashCode;
  }

  @override
  bool get hasInternal {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTest {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTestGroup {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasJS {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasLiteral {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustCallSuper {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasNonVirtual {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOptionalTypeArgs {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOverride {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOverride) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasProtected {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRequired {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasSealed {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTemplate {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTesting {
    var metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  /// Return an identifier that uniquely identifies this element among the
  /// children of this element's parent.
  String get identifier => name;

  bool get isNonFunctionTypeAliasesEnabled {
    return library.featureSet.isEnabled(Feature.nonfunction_type_aliases);
  }

  @override
  bool get isPrivate {
    var name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic {
    if (linkedNode != null) {
      return linkedNode.isSynthetic;
    }
    return hasModifier(Modifier.SYNTHETIC);
  }

  /// Set whether this element is synthetic.
  set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  @override
  LibraryElement get library => thisOrAncestorOfType();

  @override
  Source get librarySource => library?.source;

  LinkedUnitContext get linkedContext {
    return _enclosingElement.linkedContext;
  }

  @override
  ElementLocation get location {
    if (_cachedLocation == null) {
      if (library == null) {
        return ElementLocationImpl.con1(this);
      }
      _cachedLocation = ElementLocationImpl.con1(this);
    }
    return _cachedLocation;
  }

  @override
  List<ElementAnnotation> get metadata {
    if (_metadata != null) return _metadata;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var metadata = linkedContext.getMetadata(linkedNode);
      return _metadata = _buildAnnotations2(enclosingUnit, metadata);
    }

    return _metadata ?? const <ElementAnnotation>[];
  }

  set metadata(List<ElementAnnotation> metadata) {
    _metadata = metadata;
  }

  @override
  String get name => _name;

  /// Changes the name of this element.
  set name(String name) {
    _name = name;
  }

  @override
  int get nameLength => displayName != null ? displayName.length : 0;

  @override
  int get nameOffset => _nameOffset;

  /// Sets the offset of the name of this element in the file that contains the
  /// declaration of this element.
  set nameOffset(int offset) {
    _nameOffset = offset;
  }

  @override
  AnalysisSession get session {
    return _enclosingElement?.session;
  }

  @override
  Source get source {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.source;
  }

  /// Return the context to resolve type parameters in, or `null` if neither
  /// this element nor any of its ancestors is of a kind that can declare type
  /// parameters.
  TypeParameterizedElementMixin get typeParameterContext {
    return _enclosingElement?.typeParameterContext;
  }

  NullabilitySuffix get _noneOrStarSuffix {
    return library?.isNonNullableByDefault == true
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    return object is Element &&
        object.kind == kind &&
        object.location == location;
  }

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeAbstractElement(this);
  }

  /// Set this element as the enclosing element for given [element].
  void encloseElement(ElementImpl element) {
    element.enclosingElement = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      (element as ElementImpl)._enclosingElement = this;
    }
  }

  @override
  String getDisplayString({@required bool withNullability}) {
    var builder = ElementDisplayStringBuilder(
      skipAllDynamicArguments: false,
      withNullability: withNullability,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  String getExtendedDisplayName(String shortName) {
    shortName ??= displayName;
    Source source = this.source;
    if (source != null) {
      return "$shortName (${source.fullName})";
    }
    return shortName;
  }

  /// Return `true` if this element has the given [modifier] associated with it.
  bool hasModifier(Modifier modifier) =>
      BooleanArray.get(_modifiers, modifier.ordinal);

  @override
  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(name)) {
      return library == this.library;
    }
    return true;
  }

  /// Use the given [visitor] to visit all of the [children] in the given array.
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /// Set the code range for this element.
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /// Set whether the given [modifier] is associated with this element to
  /// correspond to the given [value].
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.set(_modifiers, modifier.ordinal, value);
  }

  @override
  E thisOrAncestorMatching<E extends Element>(Predicate<Element> predicate) {
    Element element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement;
    }
    return element as E;
  }

  @override
  E thisOrAncestorOfType<E extends Element>() {
    Element element = this;
    while (element != null && element is! E) {
      element = element.enclosingElement;
    }
    return element as E;
  }

  @override
  String toString() {
    return getDisplayString(withNullability: true);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /// Return annotations for the given [nodeList] in the [unit].
  List<ElementAnnotation> _buildAnnotations2(
      CompilationUnitElementImpl unit, List<Annotation> nodeList) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = List<ElementAnnotation>.filled(length, null);
    for (int i = 0; i < length; i++) {
      var ast = nodeList[i];
      annotations[i] = ElementAnnotationImpl(unit)
        ..annotationAst = ast
        ..element = ast.element;
    }
    return annotations;
  }

  /// If the given [type] is a generic function type, then the element
  /// associated with the type is implicitly a child of this element and should
  /// be visited by the given [visitor].
  void _safelyVisitPossibleChild(DartType type, ElementVisitor visitor) {
    Element element = type?.element;
    if (element is GenericFunctionTypeElementImpl &&
        element.enclosingElement is! FunctionTypeAliasElement) {
      element.accept(visitor);
    }
  }
}

/// Abstract base class for elements whose type is guaranteed to be a function
/// type.
abstract class ElementImplWithFunctionType implements Element {
  /// Gets the element's return type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get returnTypeInternal;

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `type` getter should be used instead.
  FunctionType get typeInternal;
}

/// A concrete implementation of an [ElementLocation].
class ElementLocationImpl implements ElementLocation {
  /// The character used to separate components in the encoded form.
  static const int _SEPARATOR_CHAR = 0x3B;

  /// The path to the element whose location is represented by this object.
  List<String> _components;

  /// The object managing [indexKeyId] and [indexLocationId].
  Object indexOwner;

  /// A cached id of this location in index.
  int indexKeyId;

  /// A cached id of this location in index.
  int indexLocationId;

  /// Initialize a newly created location to represent the given [element].
  ElementLocationImpl.con1(Element element) {
    List<String> components = <String>[];
    Element ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      ancestor = ancestor.enclosingElement;
    }
    _components = components;
  }

  /// Initialize a newly created location from the given [encoding].
  ElementLocationImpl.con2(String encoding) {
    _components = _decode(encoding);
  }

  /// Initialize a newly created location from the given [components].
  ElementLocationImpl.con3(List<String> components) {
    _components = components;
  }

  @override
  List<String> get components => _components;

  @override
  String get encoding {
    StringBuffer buffer = StringBuffer();
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

  /// Decode the [encoding] of a location into a list of components and return
  /// the components.
  List<String> _decode(String encoding) {
    List<String> components = <String>[];
    StringBuffer buffer = StringBuffer();
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
          buffer = StringBuffer();
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

  /// Append an encoded form of the given [component] to the given [buffer].
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

/// An [AbstractClassElementImpl] which is an enum.
class EnumElementImpl extends AbstractClassElementImpl {
  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  EnumElementImpl(String name, int offset) : super(name, offset);

  EnumElementImpl.forLinkedNode(CompilationUnitElementImpl enclosing,
      Reference reference, EnumDeclaration linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    linkedNode.name.staticElement = this;
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors == null) {
      if (linkedNode != null) {
        _resynthesizeMembers2();
      }
    }
    return _accessors ?? const <PropertyAccessorElement>[];
  }

  @override
  List<InterfaceType> get allSupertypes => <InterfaceType>[supertype];

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  List<FieldElement> get constants {
    return fields.where((field) => !field.isSynthetic).toList();
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
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  List<FieldElement> get fields {
    if (_fields == null) {
      if (linkedNode != null) {
        _resynthesizeMembers2();
      }
    }
    return _fields ?? const <FieldElement>[];
  }

  @override
  bool get hasNonFinalField => false;

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
  bool get isSimplyBounded => true;

  @override
  bool get isValidMixin => false;

  @override
  ElementKind get kind => ElementKind.ENUM;

  @override
  List<MethodElement> get methods {
    if (_methods == null) {
      if (linkedNode != null) {
        _resynthesizeMembers2();
      }
    }
    return _methods ?? const <MethodElement>[];
  }

  @override
  List<InterfaceType> get mixins => const <InterfaceType>[];

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  InterfaceType get supertype => library.typeProvider.objectType;

  @override
  List<TypeParameterElement> get typeParameters =>
      const <TypeParameterElement>[];

  @override
  ConstructorElement get unnamedConstructor => null;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeEnumElement(this);
  }

  /// Create the only method enums have - `toString()`.
  void createToStringMethodElement() {
    var method = MethodElementImpl('toString', -1);
    method.isSynthetic = true;
    method.enclosingElement = this;
    if (linkedNode != null) {
      method.returnType = library.typeProvider.stringType;
      method.reference = reference.getChild('@method').getChild('toString');
    }
    _methods = <MethodElement>[method];
  }

  @override
  ConstructorElement getNamedConstructor(String name) => null;

  void _resynthesizeMembers2() {
    var fields = <FieldElementImpl>[];
    var getters = <PropertyAccessorElementImpl>[];

    // Build the 'index' field.
    {
      var field = FieldElementImpl('index', -1)
        ..enclosingElement = this
        ..isSynthetic = true
        ..isFinal = true
        ..type = library.typeProvider.intType;
      fields.add(field);
      getters.add(PropertyAccessorElementImpl_ImplicitGetter(field,
          reference: reference.getChild('@getter').getChild('index'))
        ..enclosingElement = this);
    }

    // Build the 'values' field.
    {
      var field = ConstFieldElementImpl_EnumValues(this);
      fields.add(field);
      getters.add(PropertyAccessorElementImpl_ImplicitGetter(field,
          reference: reference.getChild('@getter').getChild('values'))
        ..enclosingElement = this);
    }

    // Build fields for all enum constants.
    var containerRef = reference.getChild('@constant');
    var constants = (linkedNode as EnumDeclaration).constants;
    for (var i = 0; i < constants.length; ++i) {
      var constant = constants[i];
      var name = constant.name.name;
      var reference = containerRef.getChild(name);
      var field = ConstFieldElementImpl_EnumValue.forLinkedNode(
          this, reference, constant, i);
      fields.add(field);
      getters.add(field.getter);
    }

    _fields = fields;
    _accessors = getters;
    createToStringMethodElement();
  }
}

/// A base class for concrete implementations of an [ExecutableElement].
abstract class ExecutableElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements ExecutableElement, ElementImplWithFunctionType {
  /// A list containing all of the parameters defined by this executable
  /// element.
  List<ParameterElement> _parameters;

  /// The inferred return type of this executable element.
  DartType _returnType;

  /// The type of function defined by this executable element.
  FunctionType _type;

  /// Initialize a newly created executable element to have the given [name] and
  /// [offset].
  ExecutableElementImpl(String name, int offset, {Reference reference})
      : super(name, offset, reference: reference);

  /// Initialize using the given linked node.
  ExecutableElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    if (linkedNode is MethodDeclaration) {
      linkedNode.name.staticElement = this;
    } else if (linkedNode is FunctionDeclaration) {
      linkedNode.name.staticElement = this;
    }
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  String get displayName {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.displayName;
  }

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  bool get hasImplicitReturnType {
    if (linkedNode != null) {
      return linkedContext.hasImplicitReturnType(linkedNode);
    }
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this executable element has an implicit return type.
  set hasImplicitReturnType(bool hasImplicitReturnType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  @override
  bool get isAbstract {
    if (linkedNode != null) {
      return !isExternal && enclosingUnit.linkedContext.isAbstract(linkedNode);
    }
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isAsynchronous {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isAsynchronous(linkedNode);
    }
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  /// Set whether this executable element's body is asynchronous.
  set isAsynchronous(bool isAsynchronous) {
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  @override
  bool get isExternal {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isExternal(linkedNode);
    }
    return hasModifier(Modifier.EXTERNAL);
  }

  /// Set whether this executable element is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isGenerator {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isGenerator(linkedNode);
    }
    return hasModifier(Modifier.GENERATOR);
  }

  /// Set whether this method's body is a generator.
  set isGenerator(bool isGenerator) {
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get isOperator => false;

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  /// Gets the element's parameters, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the [parameters] getter should be used instead.
  List<ParameterElement> get parametersInternal {
    if (_parameters != null) return _parameters;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var context = enclosingUnit.linkedContext;
      var containerRef = reference.getChild('@parameter');
      var formalParameters = context.getFormalParameters(linkedNode);
      _parameters = ParameterElementImpl.forLinkedNodeList(
        this,
        context,
        containerRef,
        formalParameters,
      );
    }

    return _parameters ??= const <ParameterElement>[];
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  set returnType(DartType returnType) {
    _returnType = returnType;
    // We do this because of return type inference. At the moment when we
    // create a local function element we don't know yet its return type,
    // because we have not done static type analysis yet.
    // It somewhere it between we access the type of this element, so it gets
    // cached in the element. When we are done static type analysis, we then
    // should clear this cached type to make it right.
    // TODO(scheglov) Remove when type analysis is done in the single pass.
    _type = null;
  }

  @override
  DartType get returnTypeInternal {
    if (_returnType != null) return _returnType;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      return _returnType;
    }
    return _returnType;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
      element: this,
    );
  }

  /// Set the type parameters defined by this executable element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitPossibleChild(returnType, visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/// A concrete implementation of an [ExportElement].
class ExportElementImpl extends UriReferencedElementImpl
    implements ExportElement {
  /// The library that is exported from this library by this export directive.
  LibraryElement _exportedLibrary;

  /// The combinators that were specified as part of the export directive in the
  /// order in which they were specified.
  List<NamespaceCombinator> _combinators;

  /// Initialize a newly created export element at the given [offset].
  ExportElementImpl(int offset) : super(null, offset);

  ExportElementImpl.forLinkedNode(
      LibraryElementImpl enclosing, ExportDirective linkedNode)
      : super.forLinkedNode(enclosing, null, linkedNode) {
    linkedNode.element = this;
  }

  @override
  List<NamespaceCombinator> get combinators {
    if (_combinators != null) return _combinators;

    if (linkedNode != null) {
      ExportDirective node = linkedNode;
      return _combinators = ImportElementImpl._buildCombinators2(
        enclosingUnit.linkedContext,
        node.combinators,
      );
    }

    return _combinators ?? const <NamespaceCombinator>[];
  }

  set combinators(List<NamespaceCombinator> combinators) {
    _combinators = combinators;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    LibraryElementImpl enclosingLibrary = enclosingElement;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  LibraryElement get exportedLibrary {
    if (_exportedLibrary != null) return _exportedLibrary;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
    }

    return _exportedLibrary;
  }

  set exportedLibrary(LibraryElement exportedLibrary) {
    _exportedLibrary = exportedLibrary;
  }

  @override
  String get identifier => exportedLibrary.name;

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return linkedContext.getDirectiveOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  String get uri {
    if (linkedNode != null) {
      ExportDirective node = linkedNode;
      return node.uri.stringValue;
    }

    return super.uri;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitExportElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExportElement(this);
  }
}

/// A concrete implementation of an [ExtensionElement].
class ExtensionElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements ExtensionElement {
  /// The type being extended.
  DartType _extendedType;

  /// A list containing all of the accessors (getters and setters) contained in
  /// this extension.
  List<PropertyAccessorElement> _accessors;

  /// A list containing all of the fields contained in this extension.
  List<FieldElement> _fields;

  /// A list containing all of the methods contained in this extension.
  List<MethodElement> _methods;

  /// Initialize a newly created extension element to have the given [name] at
  /// the given [offset] in the file that contains the declaration of this
  /// element.
  ExtensionElementImpl(String name, int nameOffset) : super(name, nameOffset);

  /// Initialize using the given linked information.
  ExtensionElementImpl.forLinkedNode(CompilationUnitElementImpl enclosing,
      Reference reference, ExtensionDeclarationImpl linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    linkedNode.declaredElement = this;
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors != null) {
      return _accessors;
    }

    if (linkedNode != null) {
      if (linkedNode is ExtensionDeclaration) {
        _createPropertiesAndAccessors();
        assert(_accessors != null);
        return _accessors;
      } else {
        return _accessors = const [];
      }
    }

    return _accessors ??= const <PropertyAccessorElement>[];
  }

  set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  String get displayName => name ?? '';

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  DartType get extendedType =>
      ElementTypeProvider.current.getExtendedType(this);

  set extendedType(DartType extendedType) {
    _extendedType = extendedType;
  }

  DartType get extendedTypeInternal {
    if (_extendedType != null) return _extendedType;

    if (linkedNode != null) {
      var linkedNode = this.linkedNode as ExtensionDeclaration;
      return _extendedType = linkedNode.extendedType.type;
    }

    return _extendedType;
  }

  @override
  List<FieldElement> get fields {
    if (_fields != null) {
      return _fields;
    }

    if (linkedNode != null) {
      if (linkedNode is ExtensionDeclaration) {
        _createPropertiesAndAccessors();
        assert(_fields != null);
        return _fields;
      } else {
        return _fields = const [];
      }
    }

    return _fields ?? const <FieldElement>[];
  }

  set fields(List<FieldElement> fields) {
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  String get identifier {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.identifier;
  }

  @override
  bool get isSimplyBounded => true;

  @override
  ElementKind get kind => ElementKind.EXTENSION;

  @override
  List<MethodElement> get methods {
    if (_methods != null) {
      return _methods;
    }

    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var containerRef = reference.getChild('@method');
      return _methods = context
          .getMethods(linkedNode)
          .where((node) => node.propertyKeyword == null)
          .map((node) {
        var name = node.name.name;
        var reference = containerRef.getChild(name);
        var element = node.declaredElement as MethodElement;
        element ??= MethodElementImpl.forLinkedNode(this, reference, node);
        return element;
      }).toList();
    }
    return _methods = const <MethodElement>[];
  }

  /// Set the methods contained in this extension to the given [methods].
  set methods(List<MethodElement> methods) {
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    _methods = methods;
  }

  @override
  String get name {
    if (linkedNode != null) {
      return (linkedNode as ExtensionDeclaration).name?.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  /// Set the type parameters defined by this extension to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitExtensionElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionElement(this);
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
  PropertyAccessorElement getSetter(String setterName) {
    return AbstractClassElementImpl.getSetterFromAccessors(
        setterName, accessors);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(fields, visitor);
    safelyVisitChildren(methods, visitor);
    safelyVisitChildren(typeParameters, visitor);
  }

  /// Create the accessors and fields when [linkedNode] is not `null`.
  void _createPropertiesAndAccessors() {
    assert(_accessors == null);
    assert(_fields == null);

    var context = enclosingUnit.linkedContext;
    var accessorList = <PropertyAccessorElement>[];
    var fieldList = <FieldElement>[];

    var fields = context.getFields(linkedNode);
    for (var field in fields) {
      var name = field.name.name;
      var fieldElement = field.declaredElement as FieldElementImpl;
      fieldElement ??= FieldElementImpl.forLinkedNodeFactory(
          this, reference.getChild('@field').getChild(name), field);
      fieldList.add(fieldElement);

      accessorList.add(fieldElement.getter);
      if (fieldElement.setter != null) {
        accessorList.add(fieldElement.setter);
      }
    }

    var methods = context.getMethods(linkedNode);
    for (var method in methods) {
      var isGetter = method.isGetter;
      var isSetter = method.isSetter;
      if (!isGetter && !isSetter) continue;

      var name = method.name.name;
      var containerRef = isGetter
          ? reference.getChild('@getter')
          : reference.getChild('@setter');

      var accessorElement =
          method.declaredElement as PropertyAccessorElementImpl;
      accessorElement ??= PropertyAccessorElementImpl.forLinkedNode(
          this, containerRef.getChild(name), method);
      accessorList.add(accessorElement);

      var fieldRef = reference.getChild('@field').getChild(name);
      FieldElementImpl field = fieldRef.element;
      if (field == null) {
        field = FieldElementImpl(name, -1);
        fieldRef.element = field;
        field.enclosingElement = this;
        field.isSynthetic = true;
        field.isFinal = isGetter;
        field.isStatic = accessorElement.isStatic;
        fieldList.add(field);
      } else {
        // TODO(brianwilkerson) Shouldn't this depend on whether there is a
        //  setter?
        field.isFinal = false;
      }

      accessorElement.variable = field;
      if (isGetter) {
        field.getter = accessorElement;
      } else {
        field.setter = accessorElement;
      }
    }

    _accessors = accessorList;
    _fields = fieldList;
  }
}

/// A concrete implementation of a [FieldElement].
class FieldElementImpl extends PropertyInducingElementImpl
    implements FieldElement {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldElementImpl(String name, int offset) : super(name, offset);

  FieldElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    if (linkedNode is VariableDeclaration) {
      linkedNode.name.staticElement = this;
    }
    if (!linkedNode.isSynthetic) {
      var enclosingRef = enclosing.reference;

      getter = PropertyAccessorElementImpl_ImplicitGetter(
        this,
        reference: enclosingRef.getChild('@getter').getChild(name),
      );

      if (_hasSetter) {
        setter = PropertyAccessorElementImpl_ImplicitSetter(
          this,
          reference: enclosingRef.getChild('@setter').getChild(name),
        );
      }
    }
  }

  factory FieldElementImpl.forLinkedNodeFactory(
      ElementImpl enclosing, Reference reference, AstNode linkedNode) {
    var context = enclosing.enclosingUnit.linkedContext;
    if (context.shouldBeConstFieldElement(linkedNode)) {
      return ConstFieldElementImpl.forLinkedNode(
        enclosing,
        reference,
        linkedNode,
      );
    }
    return FieldElementImpl.forLinkedNode(enclosing, reference, linkedNode);
  }

  @override
  FieldElement get declaration => this;

  @override
  bool get isAbstract {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isAbstract(linkedNode);
    }
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isCovariant {
    if (linkedNode != null) {
      return linkedContext.isExplicitlyCovariant(linkedNode);
    }

    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this field is explicitly marked as being covariant.
  set isCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isEnumConstant =>
      enclosingElement is ClassElement &&
      (enclosingElement as ClassElement).isEnum &&
      !isSynthetic;

  @override
  bool get isExternal {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isExternal(linkedNode);
    }
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isStatic(linkedNode);
    }
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this field is static.
  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);
}

/// A [ParameterElementImpl] that has the additional information of the
/// [FieldElement] associated with the parameter.
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement {
  /// The field associated with this field formal parameter.
  FieldElement _field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterElementImpl(String name, int nameOffset)
      : super(name, nameOffset);

  FieldFormalParameterElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  @override
  FieldElement get field {
    if (_field == null) {
      String fieldName;
      if (linkedNode != null) {
        fieldName = linkedContext.getFieldFormalParameterName(linkedNode);
      }
      if (fieldName != null) {
        Element enclosingConstructor = enclosingElement;
        if (enclosingConstructor is ConstructorElement) {
          Element enclosingClass = enclosingConstructor.enclosingElement;
          if (enclosingClass is ClassElement) {
            FieldElement field = enclosingClass.getField(fieldName);
            if (field != null && !field.isSynthetic) {
              _field = field;
            }
          }
        }
      }
    }
    return _field;
  }

  set field(FieldElement field) {
    _field = field;
  }

  @override
  bool get isInitializingFormal => true;

  @override
  set type(DartType type) {
    _type = type;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A concrete implementation of a [FunctionElement].
class FunctionElementImpl extends ExecutableElementImpl
    implements FunctionElement, FunctionTypedElementImpl {
  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionElementImpl(String name, int offset) : super(name, offset);

  FunctionElementImpl.forLinkedNode(ElementImpl enclosing, Reference reference,
      FunctionDeclaration linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    linkedNode.name.staticElement = this;
  }

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  /// Synthesize an unnamed function element that takes [parameters] and returns
  /// [returnType].
  FunctionElementImpl.synthetic(
      List<ParameterElement> parameters, DartType returnType)
      : super("", -1) {
    isSynthetic = true;
    this.returnType = returnType;
    this.parameters = parameters;
  }

  @override
  ExecutableElement get declaration => this;

  @override
  String get displayName {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.displayName;
  }

  @override
  String get identifier {
    String identifier = super.identifier;
    Element enclosing = enclosingElement;
    if (enclosing is ExecutableElement || enclosing is VariableElement) {
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
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFunctionElement(this);
}

class FunctionTypeAliasElementImpl extends TypeAliasElementImpl
    implements FunctionTypeAliasElement {
  FunctionTypeAliasElementImpl.forLinkedNode(
    CompilationUnitElementImpl enclosingUnit,
    Reference reference,
    TypeAlias linkedNode,
  ) : super.forLinkedNode(enclosingUnit, reference, linkedNode);

  @override
  GenericFunctionTypeElementImpl get function {
    return aliasedElement as GenericFunctionTypeElementImpl;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitFunctionTypeAliasElement(this);
  }

  @override
  FunctionType instantiate({
    List<DartType> typeArguments,
    NullabilitySuffix nullabilitySuffix,
  }) {
    var type = super.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
    if (type is FunctionType) {
      return type;
    } else {
      return _errorFunctionType(nullabilitySuffix);
    }
  }
}

/// Common internal interface shared by elements whose type is a function type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElementImpl
    implements ElementImpl, FunctionTypedElement {
  set returnType(DartType returnType);
}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements
        GenericFunctionTypeElement,
        FunctionTypedElementImpl,
        ElementImplWithFunctionType {
  /// The declared return type of the function.
  DartType _returnType;

  /// The elements representing the parameters of the function.
  List<ParameterElement> _parameters;

  /// Is `true` if the type has the question mark, so is nullable.
  bool _isNullable = false;

  /// The type defined by this element.
  FunctionType _type;

  GenericFunctionTypeElementImpl.forLinkedNode(
      ElementImpl enclosingElement, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosingElement, reference, linkedNode) {
    if (linkedNode is GenericFunctionTypeImpl) {
      linkedNode.declaredElement = this;
    }
  }

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  GenericFunctionTypeElementImpl.forOffset(int nameOffset)
      : super("", nameOffset);

  @override
  String get identifier => '-';

  bool get isNullable {
    if (linkedNode != null) {
      var node = linkedNode;
      if (node is GenericFunctionType) {
        return _isNullable = node.question != null;
      } else {
        return _isNullable = false;
      }
    }
    return _isNullable;
  }

  set isNullable(bool isNullable) {
    _isNullable = isNullable;
  }

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  List<ParameterElement> get parameters {
    if (_parameters == null) {
      if (linkedNode != null) {
        var context = enclosingUnit.linkedContext;
        return _parameters = ParameterElementImpl.forLinkedNodeList(
          this,
          context,
          null,
          context.getFormalParameters(linkedNode),
        );
      }
    }
    return _parameters ?? const <ParameterElement>[];
  }

  /// Set the parameters defined by this function type element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  /// Set the return type defined by this function type element to the given
  /// [returnType].
  @override
  set returnType(DartType returnType) {
    _returnType = returnType;
  }

  @override
  DartType get returnTypeInternal {
    if (_returnType == null) {
      if (linkedNode != null) {
        var context = enclosingUnit.linkedContext;
        return _returnType = context.getReturnType(linkedNode);
      }
    }
    return _returnType;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  /// Set the function type defined by this function type element to the given
  /// [type].
  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix:
          isNullable ? NullabilitySuffix.question : _noneOrStarSuffix,
      element: this,
    );
  }

  @override
  List<TypeParameterElement> get typeParameters {
    if (linkedNode != null) {
      if (linkedNode is FunctionTypeAlias) {
        return const <TypeParameterElement>[];
      }
    }
    return super.typeParameters;
  }

  /// Set the type parameters defined by this function type element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGenericFunctionTypeElement(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitPossibleChild(returnType, visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/// A concrete implementation of a [HideElementCombinator].
class HideElementCombinatorImpl implements HideElementCombinator {
  final LinkedUnitContext linkedContext;
  final HideCombinator linkedNode;

  /// The names that are not to be made visible in the importing library even if
  /// they are defined in the imported library.
  List<String> _hiddenNames;

  HideElementCombinatorImpl()
      : linkedContext = null,
        linkedNode = null;

  HideElementCombinatorImpl.forLinkedNode(this.linkedContext, this.linkedNode);

  @override
  List<String> get hiddenNames {
    if (_hiddenNames != null) return _hiddenNames;

    if (linkedNode != null) {
      return _hiddenNames = linkedNode.hiddenNames.map((i) => i.name).toList();
    }

    return _hiddenNames ?? const <String>[];
  }

  set hiddenNames(List<String> hiddenNames) {
    _hiddenNames = hiddenNames;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
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

/// A concrete implementation of an [ImportElement].
class ImportElementImpl extends UriReferencedElementImpl
    implements ImportElement {
  /// The offset of the prefix of this import in the file that contains the this
  /// import directive, or `-1` if this import is synthetic.
  int _prefixOffset = 0;

  /// The library that is imported into this library by this import directive.
  LibraryElement _importedLibrary;

  /// The combinators that were specified as part of the import directive in the
  /// order in which they were specified.
  List<NamespaceCombinator> _combinators;

  /// The prefix that was specified as part of the import directive, or `null
  ///` if there was no prefix specified.
  PrefixElement _prefix;

  /// The cached value of [namespace].
  Namespace _namespace;

  /// Initialize a newly created import element at the given [offset].
  /// The offset may be `-1` if the import is synthetic.
  ImportElementImpl(int offset) : super(null, offset);

  ImportElementImpl.forLinkedNode(
      LibraryElementImpl enclosing, ImportDirective linkedNode)
      : super.forLinkedNode(enclosing, null, linkedNode) {
    linkedNode.element = this;
  }

  @override
  List<NamespaceCombinator> get combinators {
    if (_combinators != null) return _combinators;

    if (linkedNode != null) {
      ImportDirective node = linkedNode;
      return _combinators = ImportElementImpl._buildCombinators2(
        enclosingUnit.linkedContext,
        node.combinators,
      );
    }

    return _combinators ?? const <NamespaceCombinator>[];
  }

  set combinators(List<NamespaceCombinator> combinators) {
    _combinators = combinators;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    LibraryElementImpl enclosingLibrary = enclosingElement;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  String get identifier => "${importedLibrary.identifier}@$nameOffset";

  @override
  LibraryElement get importedLibrary {
    if (_importedLibrary != null) return _importedLibrary;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
    }

    return _importedLibrary;
  }

  set importedLibrary(LibraryElement importedLibrary) {
    _importedLibrary = importedLibrary;
  }

  @override
  bool get isDeferred {
    if (linkedNode != null) {
      ImportDirective linkedNode = this.linkedNode;
      return linkedNode.deferredKeyword != null;
    }
    return hasModifier(Modifier.DEFERRED);
  }

  /// Set whether this import is for a deferred library.
  set isDeferred(bool isDeferred) {
    setModifier(Modifier.DEFERRED, isDeferred);
  }

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return linkedContext.getDirectiveOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  Namespace get namespace {
    return _namespace ??=
        NamespaceBuilder().createImportNamespaceForDirective(this);
  }

  @override
  PrefixElement get prefix {
    if (_prefix != null) return _prefix;

    if (linkedNode != null) {
      ImportDirective linkedNode = this.linkedNode;
      var prefix = linkedNode.prefix;
      if (prefix != null) {
        var name = prefix.name;
        var library = enclosingElement as LibraryElementImpl;
        _prefix = PrefixElementImpl.forLinkedNode(
          library,
          library.reference.getChild('@prefix').getChild(name),
          prefix,
        );
      }
    }

    return _prefix;
  }

  set prefix(PrefixElement prefix) {
    _prefix = prefix;
  }

  @override
  int get prefixOffset {
    if (linkedNode != null) {
      ImportDirective node = linkedNode;
      return node.prefix?.offset ?? -1;
    }
    return _prefixOffset;
  }

  set prefixOffset(int prefixOffset) {
    _prefixOffset = prefixOffset;
  }

  @override
  String get uri {
    if (linkedNode != null) {
      ImportDirective node = linkedNode;
      return node.uri.stringValue;
    }

    return super.uri;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitImportElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeImportElement(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    prefix?.accept(visitor);
  }

  static List<NamespaceCombinator> _buildCombinators2(
      LinkedUnitContext context, List<Combinator> combinators) {
    return combinators.map((node) {
      if (node is HideCombinator) {
        return HideElementCombinatorImpl.forLinkedNode(context, node);
      }
      if (node is ShowCombinator) {
        return ShowElementCombinatorImpl.forLinkedNode(context, node);
      }
      throw UnimplementedError('${node.runtimeType}');
    }).toList();
  }
}

/// A concrete implementation of a [LabelElement].
class LabelElementImpl extends ElementImpl implements LabelElement {
  /// A flag indicating whether this label is associated with a `switch`
  /// statement.
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchStatement;

  /// A flag indicating whether this label is associated with a `switch` member
  /// (`case` or `default`).
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchMember;

  /// Initialize a newly created label element to have the given [name].
  /// [onSwitchStatement] should be `true` if this label is associated with a
  /// `switch` statement and [onSwitchMember] should be `true` if this label is
  /// associated with a `switch` member.
  LabelElementImpl(String name, int nameOffset, this._onSwitchStatement,
      this._onSwitchMember)
      : super(name, nameOffset);

  @override
  String get displayName => name;

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  /// Return `true` if this label is associated with a `switch` member (`case
  /// ` or`default`).
  bool get isOnSwitchMember => _onSwitchMember;

  /// Return `true` if this label is associated with a `switch` statement.
  bool get isOnSwitchStatement => _onSwitchStatement;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitLabelElement(this);
}

/// A concrete implementation of a [LibraryElement].
class LibraryElementImpl extends ElementImpl implements LibraryElement {
  /// The analysis context in which this library is defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  @override
  TypeProviderImpl typeProvider;

  @override
  TypeSystemImpl typeSystem;

  /// The context of the defining unit.
  @override
  final LinkedUnitContext linkedContext;

  @override
  final FeatureSet featureSet;

  /// The compilation unit that defines this library.
  CompilationUnitElement _definingCompilationUnit;

  /// The entry point for this library, or `null` if this library does not have
  /// an entry point.
  FunctionElement _entryPoint;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<ImportElement> _imports;

  /// A list containing specifications of all of the exports defined in this
  /// library.
  List<ExportElement> _exports;

  /// A list containing all of the compilation units that are included in this
  /// library using a `part` directive.
  List<CompilationUnitElement> _parts = const <CompilationUnitElement>[];

  /// The element representing the synthetic function `loadLibrary` that is
  /// defined for this library, or `null` if the element has not yet been
  /// created.
  FunctionElement _loadLibraryFunction;

  @override
  final int nameLength;

  /// The export [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace _exportNamespace;

  /// The public [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace _publicNamespace;

  /// The cached list of prefixes.
  List<PrefixElement> _prefixes;

  /// The scope of this library, `null` if it has not been created yet.
  LibraryScope _scope;

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(this.context, this.session, String name, int offset,
      this.nameLength, this.featureSet)
      : linkedContext = null,
        super(name, offset);

  LibraryElementImpl.forLinkedNode(
      this.context,
      this.session,
      String name,
      int offset,
      this.nameLength,
      this.linkedContext,
      Reference reference,
      CompilationUnit linkedNode)
      : featureSet = linkedNode.featureSet,
        super.forLinkedNode(null, reference, linkedNode) {
    _name = name;
    _nameOffset = offset;
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

  /// Set the compilation unit that defines this library to the given
  ///  compilation[unit].
  set definingCompilationUnit(CompilationUnitElement unit) {
    assert((unit as CompilationUnitElementImpl).librarySource == unit.source);
    (unit as CompilationUnitElementImpl).enclosingElement = this;
    _definingCompilationUnit = unit;
  }

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var comment = linkedContext.getLibraryDocumentationComment();
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  FunctionElement get entryPoint {
    if (_entryPoint != null) return _entryPoint;

    if (linkedContext != null) {
      var namespace = library.exportNamespace;
      var entryPoint = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
      if (entryPoint is FunctionElement) {
        return _entryPoint = entryPoint;
      }
      return null;
    }

    return _entryPoint;
  }

  set entryPoint(FunctionElement entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  List<LibraryElement> get exportedLibraries {
    HashSet<LibraryElement> libraries = HashSet<LibraryElement>();
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
    if (_exportNamespace != null) return _exportNamespace;

    if (linkedNode != null) {
      var elements = linkedContext.elementFactory;
      return _exportNamespace = elements.buildExportNamespace(source.uri);
    }

    return _exportNamespace;
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  @override
  List<ExportElement> get exports {
    if (_exports != null) return _exports;

    if (linkedNode != null) {
      var unit = linkedContext.unit_withDirectives;
      return _exports = unit.directives
          .whereType<ExportDirective>()
          .map((node) => node.element)
          .toList();
    }

    return _exports ??= const <ExportElement>[];
  }

  /// Set the specifications of all of the exports defined in this library to
  /// the given list of [exports].
  set exports(List<ExportElement> exports) {
    for (ExportElement exportElement in exports) {
      (exportElement as ExportElementImpl).enclosingElement = this;
    }
    _exports = exports;
  }

  @override
  bool get hasExtUri {
    if (linkedNode != null) {
      var unit = linkedContext.unit_withDirectives;
      for (var import in unit.directives) {
        if (import is ImportDirective) {
          var uriLiteral = import.uri;
          if (uriLiteral is SimpleStringLiteral) {
            var uriStr = uriLiteral.value;
            if (DartUriResolver.isDartExtUri(uriStr)) {
              return true;
            }
          }
        }
      }
      return false;
    }

    return hasModifier(Modifier.HAS_EXT_URI);
  }

  /// Set whether this library has an import of a "dart-ext" URI.
  set hasExtUri(bool hasExtUri) {
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
  String get identifier => '${_definingCompilationUnit.source.uri}';

  @override
  List<LibraryElement> get importedLibraries {
    HashSet<LibraryElement> libraries = HashSet<LibraryElement>();
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
    if (_imports != null) return _imports;

    if (linkedNode != null) {
      var unit = linkedContext.unit_withDirectives;
      _imports = unit.directives
          .whereType<ImportDirective>()
          .map((node) => node.element)
          .toList();
      var hasCore = _imports.any((import) {
        return import.importedLibrary?.isDartCore ?? false;
      });
      if (!hasCore) {
        var elements = linkedContext.elementFactory;
        _imports.add(
          ImportElementImpl(-1)
            ..importedLibrary = elements.libraryOfUri('dart:core')
            ..isSynthetic = true
            ..uri = 'dart:core',
        );
      }
      return _imports;
    }

    return _imports ??= const <ImportElement>[];
  }

  /// Set the specifications of all of the imports defined in this library to
  /// the given list of [imports].
  set imports(List<ImportElement> imports) {
    for (ImportElement importElement in imports) {
      (importElement as ImportElementImpl).enclosingElement = this;
      PrefixElementImpl prefix = importElement.prefix as PrefixElementImpl;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    _imports = imports;
    _prefixes = null;
  }

  @override
  bool get isBrowserApplication =>
      entryPoint != null && isOrImportsBrowserLibrary;

  @override
  bool get isDartAsync => name == "dart.async";

  @override
  bool get isDartCore => name == "dart.core";

  @override
  bool get isInSdk {
    Uri uri = definingCompilationUnit.source?.uri;
    if (uri != null) {
      return DartUriResolver.isDartUri(uri);
    }
    return false;
  }

  @override
  bool get isNonNullableByDefault =>
      ElementTypeProvider.current.isLibraryNonNullableByDefault(this);

  bool get isNonNullableByDefaultInternal {
    return featureSet.isEnabled(Feature.non_nullable);
  }

  /// Return `true` if the receiver directly or indirectly imports the
  /// 'dart:html' libraries.
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = <LibraryElement>[];
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
  bool get isSynthetic {
    if (linkedNode != null) {
      return linkedContext.isSynthetic;
    }
    return super.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  LibraryLanguageVersion get languageVersion {
    if (_languageVersion != null) return _languageVersion;

    if (linkedNode != null) {
      _languageVersion = linkedContext.getLanguageVersion(linkedNode);
      return _languageVersion;
    }

    _languageVersion = LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );
    return _languageVersion;
  }

  @override
  LibraryElement get library => this;

  @override
  FunctionElement get loadLibraryFunction {
    assert(_loadLibraryFunction != null);
    return _loadLibraryFunction;
  }

  @override
  List<ElementAnnotation> get metadata {
    if (_metadata != null) return _metadata;

    if (linkedNode != null) {
      var metadata = linkedContext.getLibraryMetadata();
      return _metadata = _buildAnnotations2(definingCompilationUnit, metadata);
    }

    return super.metadata;
  }

  @override
  List<CompilationUnitElement> get parts => _parts;

  /// Set the compilation units that are included in this library using a `part`
  /// directive to the given list of [parts].
  set parts(List<CompilationUnitElement> parts) {
    for (CompilationUnitElement compilationUnit in parts) {
      assert((compilationUnit as CompilationUnitElementImpl).librarySource ==
          source);
      (compilationUnit as CompilationUnitElementImpl).enclosingElement = this;
    }
    _parts = parts;
  }

  @override
  List<PrefixElement> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(imports);

  @override
  Namespace get publicNamespace {
    if (_publicNamespace != null) return _publicNamespace;

    if (linkedNode != null) {
      return _publicNamespace =
          NamespaceBuilder().createPublicNamespaceForLibrary(this);
    }

    return _publicNamespace;
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
  }

  @override
  Scope get scope {
    return _scope ??= LibraryScope(this);
  }

  @override
  Source get source {
    if (_definingCompilationUnit == null) {
      return null;
    }
    return _definingCompilationUnit.source;
  }

  @override
  Iterable<Element> get topLevelElements sync* {
    for (var unit in units) {
      yield* unit.accessors;
      yield* unit.enums;
      yield* unit.extensions;
      yield* unit.functionTypeAliases;
      yield* unit.functions;
      yield* unit.mixins;
      yield* unit.topLevelVariables;
      yield* unit.types;
    }
  }

  @override
  List<CompilationUnitElement> get units {
    List<CompilationUnitElement> units = <CompilationUnitElement>[];
    units.add(_definingCompilationUnit);
    units.addAll(_parts);
    return units;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitLibraryElement(this);

  /// Create the [FunctionElement] to be returned by [loadLibraryFunction].
  /// The [typeProvider] must be already set.
  void createLoadLibraryFunction() {
    _loadLibraryFunction =
        FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1)
          ..enclosingElement = library
          ..isSynthetic = true
          ..returnType = typeProvider.futureDynamicType;
  }

  ClassElement getEnum(String name) {
    ClassElement element = _definingCompilationUnit.getEnum(name);
    if (element != null) {
      return element;
    }
    for (CompilationUnitElement part in _parts) {
      element = part.getEnum(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) {
    return getImportsWithPrefixFromImports(prefixElement, imports);
  }

  @override
  ClassElement getType(String className) {
    return getTypeFromParts(className, _definingCompilationUnit, _parts);
  }

  @override
  T toLegacyElementIfOptOut<T extends Element>(T element) {
    if (isNonNullableByDefault) return element;
    return Member.legacy(element);
  }

  @override
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _definingCompilationUnit?.accept(visitor);
    safelyVisitChildren(exports, visitor);
    safelyVisitChildren(imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  static List<PrefixElement> buildPrefixesFromImports(
      List<ImportElement> imports) {
    HashSet<PrefixElement> prefixes = HashSet<PrefixElement>();
    for (ImportElement element in imports) {
      PrefixElement prefix = element.prefix;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toList(growable: false);
  }

  static List<ImportElement> getImportsWithPrefixFromImports(
      PrefixElement prefixElement, List<ImportElement> imports) {
    int count = imports.length;
    List<ImportElement> importList = <ImportElement>[];
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].prefix, prefixElement)) {
        importList.add(imports[i]);
      }
    }
    return importList;
  }

  static ClassElement getTypeFromParts(
      String className,
      CompilationUnitElement definingCompilationUnit,
      List<CompilationUnitElement> parts) {
    ClassElement type = definingCompilationUnit.getType(className);
    if (type != null) {
      return type;
    }
    for (CompilationUnitElement part in parts) {
      type = part.getType(className);
      if (type != null) {
        return type;
      }
    }
    return null;
  }
}

/// A concrete implementation of a [LocalVariableElement].
class LocalVariableElementImpl extends NonParameterVariableElementImpl
    implements LocalVariableElement {
  @override
  bool hasInitializer;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableElementImpl(String name, int offset) : super(name, offset);

  @override
  String get identifier {
    return '$name$nameOffset';
  }

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  /// Set whether this variable is late.
  set isLate(bool isLate) {
    setModifier(Modifier.LATE, isLate);
  }

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitLocalVariableElement(this);
}

/// A concrete implementation of a [MethodElement].
class MethodElementImpl extends ExecutableElementImpl implements MethodElement {
  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError typeInferenceError;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodElementImpl(String name, int offset) : super(name, offset);

  MethodElementImpl.forLinkedNode(TypeParameterizedElementMixin enclosingClass,
      Reference reference, MethodDeclaration linkedNode)
      : super.forLinkedNode(enclosingClass, reference, linkedNode) {
    linkedNode.name.staticElement = this;
  }

  @override
  MethodElement get declaration => this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

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
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isStatic(linkedNode);
    }
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this method is static.
  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name {
    String name = super.name;
    if (name == '-' && parametersInternal.isEmpty) {
      return 'unary-';
    }
    return super.name;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);
}

/// A [ClassElementImpl] representing a mixin declaration.
class MixinElementImpl extends ClassElementImpl {
  // TODO(brianwilkerson) Consider creating an abstract superclass of
  // ClassElementImpl that contains the portions of the API that this class
  // needs, and make this class extend the new class.

  /// A list containing all of the superclass constraints that are defined for
  /// the mixin.
  List<InterfaceType> _superclassConstraints;

  @override
  List<String> superInvokedNames;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  MixinElementImpl(String name, int offset) : super(name, offset);

  MixinElementImpl.forLinkedNode(CompilationUnitElementImpl enclosing,
      Reference reference, MixinDeclaration linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    linkedNode.name.staticElement = this;
  }

  @override
  bool get isAbstract => true;

  @override
  bool get isMixin => true;

  @override
  List<InterfaceType> get mixins => const <InterfaceType>[];

  @override
  List<InterfaceType> get superclassConstraints {
    if (_superclassConstraints != null) return _superclassConstraints;

    var linkedNode = this.linkedNode;
    if (linkedNode is MixinDeclaration) {
      linkedContext.applyResolution(linkedNode);
      List<InterfaceType> constraints;
      var onClause = linkedNode.onClause;
      if (onClause != null) {
        constraints = onClause.superclassConstraints
            .map((node) => node.type)
            .whereType<InterfaceType>()
            .where(_isInterfaceTypeInterface)
            .toList();
      }
      if (constraints == null || constraints.isEmpty) {
        constraints = [library.typeProvider.objectType];
      }
      return _superclassConstraints = constraints;
    }

    return _superclassConstraints ?? const <InterfaceType>[];
  }

  set superclassConstraints(List<InterfaceType> superclassConstraints) {
    _superclassConstraints = superclassConstraints;
  }

  @override
  InterfaceType get supertype => null;

  @override
  set supertype(InterfaceType supertype) {
    throw StateError('Attempt to set a supertype for a mixin declaratio.');
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMixinElement(this);
  }
}

/// The constants for all of the modifiers defined by the Dart language and for
/// a few additional flags that are useful.
///
/// Clients may not extend, implement or mix-in this class.
class Modifier implements Comparable<Modifier> {
  /// Indicates that the modifier 'abstract' was applied to the element.
  static const Modifier ABSTRACT = Modifier('ABSTRACT', 0);

  /// Indicates that an executable element has a body marked as being
  /// asynchronous.
  static const Modifier ASYNCHRONOUS = Modifier('ASYNCHRONOUS', 1);

  /// Indicates that the modifier 'const' was applied to the element.
  static const Modifier CONST = Modifier('CONST', 2);

  /// Indicates that the modifier 'covariant' was applied to the element.
  static const Modifier COVARIANT = Modifier('COVARIANT', 3);

  /// Indicates that the class is `Object` from `dart:core`.
  static const Modifier DART_CORE_OBJECT = Modifier('DART_CORE_OBJECT', 4);

  /// Indicates that the import element represents a deferred library.
  static const Modifier DEFERRED = Modifier('DEFERRED', 5);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier ENUM = Modifier('ENUM', 6);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier EXTERNAL = Modifier('EXTERNAL', 7);

  /// Indicates that the modifier 'factory' was applied to the element.
  static const Modifier FACTORY = Modifier('FACTORY', 8);

  /// Indicates that the modifier 'final' was applied to the element.
  static const Modifier FINAL = Modifier('FINAL', 9);

  /// Indicates that an executable element has a body marked as being a
  /// generator.
  static const Modifier GENERATOR = Modifier('GENERATOR', 10);

  /// Indicates that the pseudo-modifier 'get' was applied to the element.
  static const Modifier GETTER = Modifier('GETTER', 11);

  /// A flag used for libraries indicating that the defining compilation unit
  /// contains at least one import directive whose URI uses the "dart-ext"
  /// scheme.
  static const Modifier HAS_EXT_URI = Modifier('HAS_EXT_URI', 12);

  /// Indicates that the associated element did not have an explicit type
  /// associated with it. If the element is an [ExecutableElement], then the
  /// type being referred to is the return type.
  static const Modifier IMPLICIT_TYPE = Modifier('IMPLICIT_TYPE', 13);

  /// Indicates that modifier 'lazy' was applied to the element.
  static const Modifier LATE = Modifier('LATE', 14);

  /// Indicates that a class is a mixin application.
  static const Modifier MIXIN_APPLICATION = Modifier('MIXIN_APPLICATION', 15);

  /// Indicates that the pseudo-modifier 'set' was applied to the element.
  static const Modifier SETTER = Modifier('SETTER', 16);

  /// Indicates that the modifier 'static' was applied to the element.
  static const Modifier STATIC = Modifier('STATIC', 17);

  /// Indicates that the element does not appear in the source code but was
  /// implicitly created. For example, if a class does not define any
  /// constructors, an implicit zero-argument constructor will be created and it
  /// will be marked as being synthetic.
  static const Modifier SYNTHETIC = Modifier('SYNTHETIC', 18);

  static const List<Modifier> values = [
    ABSTRACT,
    ASYNCHRONOUS,
    CONST,
    COVARIANT,
    DART_CORE_OBJECT,
    DEFERRED,
    ENUM,
    EXTERNAL,
    FACTORY,
    FINAL,
    GENERATOR,
    GETTER,
    HAS_EXT_URI,
    IMPLICIT_TYPE,
    LATE,
    MIXIN_APPLICATION,
    SETTER,
    STATIC,
    SYNTHETIC
  ];

  /// The name of this modifier.
  final String name;

  /// The ordinal value of the modifier.
  final int ordinal;

  const Modifier(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(Modifier other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// A concrete implementation of a [MultiplyDefinedElement].
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
  /// The unique integer identifier of this element.
  @override
  final int id = ElementImpl._NEXT_ID++;

  /// The analysis context in which the multiply defined elements are defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  /// The name of the conflicting elements.
  @override
  final String name;

  @override
  final List<Element> conflictingElements;

  /// Initialize a newly created element in the given [context] to represent
  /// the given non-empty [conflictingElements].
  MultiplyDefinedElementImpl(
      this.context, this.session, this.name, this.conflictingElements);

  @override
  Element get declaration => null;

  @override
  String get displayName => name;

  @override
  String get documentationComment => null;

  @override
  Element get enclosingElement => null;

  @override
  bool get hasAlwaysThrows => false;

  @override
  bool get hasDeprecated => false;

  @override
  bool get hasDoNotStore => false;

  @override
  bool get hasFactory => false;

  @override
  bool get hasInternal => false;

  @override
  bool get hasIsTest => false;

  @override
  bool get hasIsTestGroup => false;

  @override
  bool get hasJS => false;

  @override
  bool get hasLiteral => false;

  @override
  bool get hasMustCallSuper => false;

  @override
  bool get hasNonVirtual => false;

  @override
  bool get hasOptionalTypeArgs => false;

  @override
  bool get hasOverride => false;

  @override
  bool get hasProtected => false;

  @override
  bool get hasRequired => false;

  @override
  bool get hasSealed => false;

  @override
  bool get hasVisibleForTemplate => false;

  @override
  bool get hasVisibleForTesting => false;

  @override
  bool get isPrivate {
    String name = displayName;
    if (name == null) {
      return false;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic => true;

  bool get isVisibleForTemplate => false;

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
  int get nameLength => displayName != null ? displayName.length : 0;

  @override
  int get nameOffset => -1;

  @override
  Source get source => null;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

  @override
  String getDisplayString({@required bool withNullability}) {
    var elementsStr = conflictingElements.map((e) {
      return e.getDisplayString(
        withNullability: withNullability,
      );
    }).join(', ');
    return '[' + elementsStr + ']';
  }

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
  E thisOrAncestorMatching<E extends Element>(Predicate<Element> predicate) =>
      null;

  @override
  E thisOrAncestorOfType<E extends Element>() => null;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (Element element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        buffer.write(
          element.getDisplayString(withNullability: true),
        );
      }
    }

    buffer.write("[");
    writeList(conflictingElements);
    buffer.write("]");
    return buffer.toString();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }
}

/// The synthetic element representing the declaration of the type `Never`.
class NeverElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static NeverElementImpl get instance =>
      NeverTypeImpl.instance.element as NeverElementImpl;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  NeverElementImpl() : super('Never', -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.NEVER;

  @override
  T accept<T>(ElementVisitor<T> visitor) => null;

  DartType instantiate({
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        return NeverTypeImpl.instanceLegacy;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
    throw StateError('Unsupported nullability: $nullabilitySuffix');
  }
}

/// A [VariableElementImpl], which is not a parameter.
abstract class NonParameterVariableElementImpl extends VariableElementImpl {
  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  NonParameterVariableElementImpl(String name, int offset)
      : super(name, offset);

  NonParameterVariableElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  bool get hasImplicitType {
    if (linkedNode != null) {
      return linkedContext.hasImplicitType(linkedNode);
    }
    return super.hasImplicitType;
  }

  bool get hasInitializer {
    return linkedNode != null && linkedContext.hasInitializer(linkedNode);
  }

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  @override
  set type(DartType type) {
    _type = type;
  }
}

/// A concrete implementation of a [ParameterElement].
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement {
  /// A list containing all of the parameters defined by this parameter element.
  /// There will only be parameters if this parameter is a function typed
  /// parameter.
  List<ParameterElement> _parameters;

  /// A list containing all of the type parameters defined for this parameter
  /// element. There will only be parameters if this parameter is a function
  /// typed parameter.
  List<TypeParameterElement> _typeParameters;

  /// The kind of this parameter.
  ParameterKind _parameterKind;

  /// The Dart code of the default value.
  String _defaultValueCode;

  /// True if this parameter inherits from a covariant parameter. This happens
  /// when it overrides a method in a supertype that has a corresponding
  /// covariant parameter.
  bool inheritsCovariant = false;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  ParameterElementImpl(String name, int nameOffset) : super(name, nameOffset);

  ParameterElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, FormalParameter linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    assert(linkedNode.isNamed || reference == null);
    FormalParameterImpl.setDeclaredElement(linkedNode, this);
  }

  factory ParameterElementImpl.forLinkedNodeFactory(
      ElementImpl enclosing, Reference reference, FormalParameter node) {
    if (node is FieldFormalParameter) {
      return FieldFormalParameterElementImpl.forLinkedNode(
        enclosing,
        reference,
        node,
      );
    } else if (node is FunctionTypedFormalParameter ||
        node is SimpleFormalParameter) {
      return ParameterElementImpl.forLinkedNode(enclosing, reference, node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  /// Creates a synthetic parameter with [name], [type] and [kind].
  factory ParameterElementImpl.synthetic(
      String name, DartType type, ParameterKind kind) {
    ParameterElementImpl element = ParameterElementImpl(name, -1);
    element.type = type;
    element.isSynthetic = true;
    element.parameterKind = kind;
    return element;
  }

  @override
  ParameterElement get declaration => this;

  @override
  String get defaultValueCode {
    var linkedNode = this.linkedNode;
    if (linkedNode is DefaultFormalParameter) {
      return linkedNode.defaultValue?.toSource();
    }

    return _defaultValueCode;
  }

  /// Set Dart code of the default value.
  set defaultValueCode(String defaultValueCode) {
    _defaultValueCode = StringUtilities.intern(defaultValueCode);
  }

  @override
  bool get hasDefaultValue {
    return defaultValueCode != null;
  }

  @override
  bool get hasImplicitType {
    if (linkedNode != null) {
      return linkedContext.hasImplicitType(linkedNode);
    }
    return super.hasImplicitType;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  /// Return true if this parameter is explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    if (linkedNode != null) {
      return linkedContext.isExplicitlyCovariant(linkedNode);
    }
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this variable parameter is explicitly marked as being
  /// covariant.
  set isExplicitlyCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isFinal {
    if (linkedNode != null) {
      FormalParameter linkedNode = this.linkedNode;
      return linkedNode.isFinal;
    }
    return super.isFinal;
  }

  @override
  bool get isInitializingFormal => false;

  @override
  bool get isLate => false;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  String get name {
    if (linkedNode != null) {
      return linkedContext.getFormalParameterName(linkedNode);
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  @override
  ParameterKind get parameterKind {
    if (_parameterKind != null) return _parameterKind;

    if (linkedNode != null) {
      var linkedNode = this.linkedNode as FormalParameterImpl;
      return linkedNode.kind;
    }
    return _parameterKind;
  }

  set parameterKind(ParameterKind parameterKind) {
    _parameterKind = parameterKind;
  }

  @override
  List<ParameterElement> get parameters {
    if (_parameters != null) return _parameters;

    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var formalParameters = context.getFormalParameters(linkedNode);
      if (formalParameters != null) {
        return _parameters = ParameterElementImpl.forLinkedNodeList(
          this,
          context,
          null,
          formalParameters,
        );
      } else {
        return _parameters ??= const <ParameterElement>[];
      }
    }

    return _parameters ??= const <ParameterElement>[];
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    if (_typeParameters != null) return _typeParameters;

    if (linkedNode != null) {
      var typeParameters = linkedContext.getTypeParameters2(linkedNode);
      if (typeParameters == null) {
        return _typeParameters = const [];
      }
      return _typeParameters =
          typeParameters.typeParameters.map<TypeParameterElement>((node) {
        var element = node.declaredElement;
        element ??= TypeParameterElementImpl.forLinkedNode(this, node);
        return element;
      }).toList();
    }

    return _typeParameters ??= const <TypeParameterElement>[];
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameters = typeParameters;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  /// TODO(scheglov) Do we need this method at all?
  /// We should create all parameter elements during applying resolution.
  /// Or when we build elements before linking.
  static List<ParameterElement> forLinkedNodeList(
      ElementImpl enclosing,
      LinkedUnitContext context,
      Reference containerRef,
      List<FormalParameter> formalParameters) {
    if (formalParameters == null) {
      return const [];
    }

    return formalParameters.map((node) {
      var element = node.declaredElement;
      if (element != null) {
        return element;
      }

      if (node is DefaultFormalParameter) {
        NormalFormalParameter parameterNode = node.parameter;
        Reference reference;
        if (node.isNamed) {
          var name = parameterNode.identifier?.name ?? '';
          reference = containerRef?.getChild(name);
          reference?.node = node;
        }
        if (parameterNode is FieldFormalParameter) {
          return DefaultFieldFormalParameterElementImpl.forLinkedNode(
            enclosing,
            reference,
            node,
          );
        } else {
          return DefaultParameterElementImpl.forLinkedNode(
            enclosing,
            reference,
            node,
          );
        }
      } else {
        return ParameterElementImpl.forLinkedNodeFactory(enclosing, null, node);
      }
    }).toList();
  }
}

/// The parameter of an implicit setter.
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
    if (variable is FieldElementImpl) {
      return variable.inheritsCovariant;
    }
    return false;
  }

  @override
  set inheritsCovariant(bool value) {
    PropertyInducingElement variable = setter.variable;
    if (variable is FieldElementImpl) {
      variable.inheritsCovariant = value;
    }
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
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
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  @override
  set type(DartType type) {
    assert(false); // Should never be called.
  }

  @override
  DartType get typeInternal => setter.variable.type;
}

/// A mixin that provides a common implementation for methods defined in
/// [ParameterElement].
mixin ParameterElementMixin implements ParameterElement {
  @override
  bool get isNamed => parameterKind.isNamed;

  @override
  bool get isNotOptional => parameterKind.isRequired;

  @override
  bool get isOptional => parameterKind.isOptional;

  @override
  bool get isOptionalNamed => parameterKind.isOptionalNamed;

  @override
  bool get isOptionalPositional => parameterKind.isOptionalPositional;

  @override
  bool get isPositional => parameterKind.isPositional;

  @override
  bool get isRequiredNamed => parameterKind.isRequiredNamed;

  @override
  bool get isRequiredPositional => parameterKind.isRequiredPositional;

  @override
  // Overridden to remove the 'deprecated' annotation.
  ParameterKind get parameterKind;

  @override
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    bool withNullability = false,
  }) {
    buffer.write(
      type.getDisplayString(
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

/// A concrete implementation of a [PrefixElement].
class PrefixElementImpl extends ElementImpl implements PrefixElement {
  /// The scope of this prefix, `null` if it has not been created yet.
  PrefixScope _scope;

  /// Initialize a newly created method element to have the given [name] and
  /// [nameOffset].
  PrefixElementImpl(String name, int nameOffset) : super(name, nameOffset);

  PrefixElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, SimpleIdentifier linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  @override
  String get displayName => name;

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return (linkedNode as SimpleIdentifier).offset;
    }
    return super.nameOffset;
  }

  @override
  Scope get scope => _scope ??= PrefixScope(enclosingElement, this);

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }
}

/// A concrete implementation of a [PropertyAccessorElement].
class PropertyAccessorElementImpl extends ExecutableElementImpl
    implements PropertyAccessorElement {
  /// The variable associated with this accessor.
  @override
  PropertyInducingElement variable;

  /// Initialize a newly created property accessor element to have the given
  /// [name] and [offset].
  PropertyAccessorElementImpl(String name, int offset) : super(name, offset);

  PropertyAccessorElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  /// Initialize a newly created synthetic property accessor element to be
  /// associated with the given [variable].
  PropertyAccessorElementImpl.forVariable(PropertyInducingElementImpl variable,
      {Reference reference})
      : super(variable.name, variable.nameOffset, reference: reference) {
    this.variable = variable;
    isAbstract = variable is FieldElementImpl && variable.isAbstract;
    isStatic = variable.isStatic;
    isSynthetic = true;
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
  PropertyAccessorElement get declaration => this;

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return "$name$suffix";
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isGetter {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isGetter(linkedNode);
    }
    return hasModifier(Modifier.GETTER);
  }

  /// Set whether this accessor is a getter.
  set isGetter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  bool get isSetter {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isSetter(linkedNode);
    }
    return hasModifier(Modifier.SETTER);
  }

  /// Set whether this accessor is a setter.
  set isSetter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  @override
  bool get isStatic {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isStatic(linkedNode);
    }
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this accessor is static.
  set isStatic(bool isStatic) {
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
    if (linkedNode != null) {
      var name = reference.name;
      if (isSetter) {
        return '$name=';
      }
      return name;
    }
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + variable.displayName,
    );
  }
}

/// Implicit getter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitGetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit getter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitGetter(
      PropertyInducingElementImpl property,
      {Reference reference})
      : super.forVariable(property, reference: reference) {
    property.getter = this;
    enclosingElement = property.enclosingElement;
    reference?.element = this;
  }

  @override
  bool get hasImplicitReturnType => variable.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnTypeInternal => variable.type;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type;

    var type = FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: const <ParameterElement>[],
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
      element: this,
    );

    // Don't cache, because types change during top-level inference.
    if (enclosingElement != null &&
        linkedContext != null &&
        !linkedContext.isLinking) {
      _type = type;
    }

    return type;
  }
}

/// Implicit setter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitSetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit setter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitSetter(
      PropertyInducingElementImpl property,
      {Reference reference})
      : super.forVariable(property, reference: reference) {
    property.setter = this;
    enclosingElement = property.enclosingElement;
  }

  @override
  bool get isSetter => true;

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  @override
  List<ParameterElement> get parametersInternal {
    return _parameters ??= <ParameterElement>[
      ParameterElementImpl_ofImplicitSetter(this)
    ];
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnTypeInternal => VoidTypeImpl.instance;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type;

    var type = FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
      element: this,
    );

    // Don't cache, because types change during top-level inference.
    if (enclosingElement != null &&
        linkedContext != null &&
        !linkedContext.isLinking) {
      _type = type;
    }

    return type;
  }
}

/// A concrete implementation of a [PropertyInducingElement].
abstract class PropertyInducingElementImpl
    extends NonParameterVariableElementImpl implements PropertyInducingElement {
  /// The getter associated with this element.
  @override
  PropertyAccessorElement getter;

  /// The setter associated with this element, or `null` if the element is
  /// effectively `final` and therefore does not have a setter associated with
  /// it.
  @override
  PropertyAccessorElement setter;

  /// This field is set during linking, and performs type inference for
  /// this property. After linking this field is always `null`.
  PropertyInducingElementTypeInference typeInference;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError typeInferenceError;

  /// Initialize a newly created synthetic element to have the given [name] and
  /// [offset].
  PropertyInducingElementImpl(String name, int offset) : super(name, offset);

  PropertyInducingElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  bool get hasTypeInferred => _type != null;

  @override
  bool get isConstantEvaluated => true;

  @override
  bool get isLate {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isLate(linkedNode);
    }
    return hasModifier(Modifier.LATE);
  }

  @override
  DartType get type => ElementTypeProvider.current.getFieldType(this);

  @override
  DartType get typeInternal {
    if (_type != null) return _type;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);

      // While performing inference during linking, the first step is to collect
      // dependencies. During this step we resolve the expression, but we might
      // reference elements that don't have their types inferred yet. So, here
      // we give some type. A better solution would be to infer recursively, but
      // we are not doing this yet.
      if (_type == null) {
        assert(linkedContext.isLinking);
        return DynamicTypeImpl.instance;
      }

      return _type;
    }
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
    return super.typeInternal;
  }

  /// Return `true` if this variable needs the setter.
  bool get _hasSetter {
    if (isConst) {
      return false;
    }

    if (isLate) {
      return !isFinal || !hasInitializer;
    }

    return !isFinal;
  }
}

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  void perform();
}

/// A concrete implementation of a [ShowElementCombinator].
class ShowElementCombinatorImpl implements ShowElementCombinator {
  final LinkedUnitContext linkedContext;
  final ShowCombinator linkedNode;

  /// The names that are to be made visible in the importing library if they are
  /// defined in the imported library.
  List<String> _shownNames;

  /// The offset of the character immediately following the last character of
  /// this node.
  int _end = -1;

  /// The offset of the 'show' keyword of this element.
  int _offset = 0;

  ShowElementCombinatorImpl()
      : linkedContext = null,
        linkedNode = null;

  ShowElementCombinatorImpl.forLinkedNode(this.linkedContext, this.linkedNode);

  @override
  int get end {
    if (linkedNode != null) {
      return linkedNode.end;
    }
    return _end;
  }

  set end(int end) {
    _end = end;
  }

  @override
  int get offset {
    if (linkedNode != null) {
      return linkedNode.keyword.offset;
    }
    return _offset;
  }

  set offset(int offset) {
    _offset = offset;
  }

  @override
  List<String> get shownNames {
    if (_shownNames != null) return _shownNames;

    if (linkedNode != null) {
      return _shownNames = linkedNode.shownNames.map((i) => i.name).toList();
    }

    return _shownNames ?? const <String>[];
  }

  set shownNames(List<String> shownNames) {
    _shownNames = shownNames;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
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

/// A concrete implementation of a [TopLevelVariableElement].
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    implements TopLevelVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableElementImpl(String name, int offset) : super(name, offset);

  TopLevelVariableElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode) {
    if (linkedNode is VariableDeclaration) {
      linkedNode.name.staticElement = this;
    }
    if (!linkedNode.isSynthetic) {
      var enclosingRef = enclosing.reference;

      getter = PropertyAccessorElementImpl_ImplicitGetter(
        this,
        reference: enclosingRef.getChild('@getter').getChild(name),
      );

      if (_hasSetter) {
        setter = PropertyAccessorElementImpl_ImplicitSetter(
          this,
          reference: enclosingRef.getChild('@setter').getChild(name),
        );
      }
    }
  }

  factory TopLevelVariableElementImpl.forLinkedNodeFactory(
      ElementImpl enclosing, Reference reference, AstNode linkedNode) {
    if (enclosing.enclosingUnit.linkedContext.isConst(linkedNode)) {
      return ConstTopLevelVariableElementImpl.forLinkedNode(
        enclosing,
        reference,
        linkedNode,
      );
    }
    return TopLevelVariableElementImpl.forLinkedNode(
      enclosing,
      reference,
      linkedNode,
    );
  }

  @override
  TopLevelVariableElement get declaration => this;

  @override
  bool get isExternal {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isExternal(linkedNode);
    }
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
class TypeAliasElementImpl extends ElementImpl
    with TypeParameterizedElementMixin
    implements TypeAliasElement {
  /// TODO(scheglov) implement as modifier
  @override
  bool isSimplyBounded = true;

  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool _isAliasedElementReady = false;
  ElementImpl _aliasedElement;
  DartType _aliasedType;

  TypeAliasElementImpl(String name, int nameOffset) : super(name, nameOffset);

  TypeAliasElementImpl.forLinkedNode(
    CompilationUnitElementImpl enclosingUnit,
    Reference reference,
    TypeAlias linkedNode,
  ) : super.forLinkedNode(enclosingUnit, reference, linkedNode) {
    var nameNode = linkedNode is FunctionTypeAlias
        ? linkedNode.name
        : (linkedNode as GenericTypeAlias).name;
    nameNode.staticElement = this;
  }

  factory TypeAliasElementImpl.forLinkedNodeFactory(
    CompilationUnitElementImpl enclosingUnit,
    Reference reference,
    TypeAlias linkedNode,
  ) {
    if (linkedNode is FunctionTypeAlias) {
      return FunctionTypeAliasElementImpl.forLinkedNode(
          enclosingUnit, reference, linkedNode);
    } else {
      var aliasedType = (linkedNode as GenericTypeAlias).type;
      if (aliasedType is GenericFunctionType ||
          !enclosingUnit.isNonFunctionTypeAliasesEnabled) {
        return FunctionTypeAliasElementImpl.forLinkedNode(
            enclosingUnit, reference, linkedNode);
      } else {
        return TypeAliasElementImpl.forLinkedNode(
            enclosingUnit, reference, linkedNode);
      }
    }
  }

  @override
  ElementImpl get aliasedElement {
    _ensureAliasedElement();
    return _aliasedElement;
  }

  @override
  DartType get aliasedType {
    if (_aliasedType != null) return _aliasedType;

    _ensureAliasedElement();

    var linkedNode = this.linkedNode;
    if (linkedNode is GenericTypeAlias) {
      var typeNode = linkedNode.type;
      if (isNonFunctionTypeAliasesEnabled) {
        _aliasedType = typeNode.type;
        assert(_aliasedType != null);
      } else if (typeNode is GenericFunctionType) {
        _aliasedType = typeNode.type;
        assert(_aliasedType != null);
      } else {
        _aliasedType = _errorFunctionType(NullabilitySuffix.none);
      }
    } else if (linkedNode is FunctionTypeAlias) {
      _aliasedType = (_aliasedElement as GenericFunctionTypeElementImpl).type;
    }

    return _aliasedType;
  }

  set aliasedType(DartType rawType) {
    _aliasedType = rawType;
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  String get displayName => name;

  @override
  String get documentationComment {
    if (linkedNode != null) {
      var context = enclosingUnit.linkedContext;
      var comment = context.getDocumentationComment(linkedNode);
      return getCommentNodeRawText(comment);
    }
    return super.documentationComment;
  }

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  ElementKind get kind {
    if (isNonFunctionTypeAliasesEnabled) {
      return ElementKind.TYPE_ALIAS;
    } else {
      return ElementKind.FUNCTION_TYPE_ALIAS;
    }
  }

  @override
  String get name {
    if (linkedNode != null) {
      return reference.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  /// Set the type parameters defined for this type to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTypeAliasElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeAliasElement(this);
  }

  @override
  DartType instantiate({
    List<DartType> typeArguments,
    NullabilitySuffix nullabilitySuffix,
  }) {
    if (hasSelfReference) {
      if (isNonFunctionTypeAliasesEnabled) {
        return DynamicTypeImpl.instance;
      } else {
        return _errorFunctionType(nullabilitySuffix);
      }
    }

    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    var type = substitution.substituteType(aliasedType);

    var resultNullability = type.nullabilitySuffix == NullabilitySuffix.question
        ? NullabilitySuffix.question
        : nullabilitySuffix;

    if (type is FunctionType) {
      return FunctionTypeImpl(
        typeFormals: type.typeFormals,
        parameters: type.parameters,
        returnType: type.returnType,
        nullabilitySuffix: resultNullability,
        element: this,
        typeArguments: typeArguments,
      );
    } else {
      return (type as TypeImpl).withNullability(resultNullability);
    }
  }

  void _ensureAliasedElement() {
    if (_isAliasedElementReady) return;
    _isAliasedElementReady = true;

    var linkedNode = this.linkedNode;
    if (linkedNode != null) {
      if (linkedNode is GenericTypeAlias) {
        var type = linkedNode.type;
        if (type is GenericFunctionTypeImpl) {
          _aliasedElement =
              type.declaredElement as GenericFunctionTypeElementImpl;
          // TODO(scheglov) Do we need this?
          // We probably should set it when linking and when applying.
          // TODO(scheglov) And remove the reference.
          _aliasedElement ??= GenericFunctionTypeElementImpl.forLinkedNode(
            this,
            reference.getChild('@function'),
            type,
          );
        } else if (isNonFunctionTypeAliasesEnabled) {
          // No element for `typedef A<T> = List<T>;`
        } else {
          _aliasedElement = GenericFunctionTypeElementImpl.forOffset(-1)
            ..typeParameters = const <TypeParameterElement>[]
            ..parameters = const <ParameterElement>[]
            ..returnType = DynamicTypeImpl.instance;
        }
      } else {
        // TODO(scheglov) Same as above (both).
        _aliasedElement = GenericFunctionTypeElementImpl.forLinkedNode(
          this,
          reference.getChild('@function'),
          linkedNode,
        );
      }
      linkedContext.applyResolution(linkedNode);
    }
  }

  FunctionTypeImpl _errorFunctionType(NullabilitySuffix nullabilitySuffix) {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// A concrete implementation of a [TypeParameterElement].
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement {
  /// The default value of the type parameter. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference.
  DartType defaultType;

  /// The type representing the bound associated with this parameter, or `null`
  /// if this parameter does not have an explicit bound.
  DartType _bound;

  /// The value representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Variance _variance;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  TypeParameterElementImpl(String name, int offset) : super(name, offset);

  TypeParameterElementImpl.forLinkedNode(
      ElementImpl enclosing, TypeParameter linkedNode)
      : super.forLinkedNode(enclosing, null, linkedNode) {
    linkedNode.name.staticElement = this;
  }

  /// Initialize a newly created synthetic type parameter element to have the
  /// given [name], and with [synthetic] set to true.
  TypeParameterElementImpl.synthetic(String name) : super(name, -1) {
    isSynthetic = true;
  }

  @override
  DartType get bound => ElementTypeProvider.current.getTypeParameterBound(this);

  set bound(DartType bound) {
    _bound = bound;
  }

  DartType get boundInternal {
    if (_bound != null) return _bound;

    var linkedNode = this.linkedNode;
    if (linkedNode is TypeParameter) {
      return _bound = linkedNode.bound?.type;
    }

    return _bound;
  }

  @override
  int get codeLength {
    if (linkedNode != null) {
      return linkedContext.getCodeLength(linkedNode);
    }
    return super.codeLength;
  }

  @override
  int get codeOffset {
    if (linkedNode != null) {
      return linkedContext.getCodeOffset(linkedNode);
    }
    return super.codeOffset;
  }

  @override
  TypeParameterElement get declaration => this;

  @override
  String get displayName => name;

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  String get name {
    if (linkedNode != null) {
      var node = linkedNode as TypeParameter;
      return node.name.name;
    }
    return super.name;
  }

  @override
  int get nameOffset {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.getNameOffset(linkedNode);
    }

    return super.nameOffset;
  }

  Variance get variance {
    return _variance ?? Variance.covariant;
  }

  set variance(Variance newVariance) => _variance = newVariance;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is TypeParameterElement) {
      if (other.enclosingElement == null || enclosingElement == null) {
        return identical(other, this);
      }
      return other.location == location;
    }
    return false;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameter(this);
  }

  @override
  TypeParameterType instantiate({
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(
      element: this,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedElementMixin
    implements TypeParameterizedElement, ElementImpl {
  /// A cached list containing the type parameters declared by this element
  /// directly, or `null` if the elements have not been created yet. This does
  /// not include type parameters that are declared by any enclosing elements.
  List<TypeParameterElement> _typeParameterElements;

  @override
  bool get isSimplyBounded => true;

  @override
  List<TypeParameterElement> get typeParameters {
    if (_typeParameterElements != null) return _typeParameterElements;

    if (linkedNode != null) {
      linkedContext.applyResolution(linkedNode);
      var typeParameters = linkedContext.getTypeParameters2(linkedNode);
      if (typeParameters == null) {
        return _typeParameterElements = const [];
      }
      return _typeParameterElements =
          typeParameters.typeParameters.map<TypeParameterElement>((node) {
        var element = node.declaredElement;
        element ??= TypeParameterElementImpl.forLinkedNode(this, node);
        return element;
      }).toList();
    }

    return _typeParameterElements ?? const <TypeParameterElement>[];
  }
}

/// A concrete implementation of a [UriReferencedElement].
abstract class UriReferencedElementImpl extends ElementImpl
    implements UriReferencedElement {
  /// The offset of the URI in the file, or `-1` if this node is synthetic.
  int _uriOffset = -1;

  /// The offset of the character immediately following the last character of
  /// this node's URI, or `-1` if this node is synthetic.
  int _uriEnd = -1;

  /// The URI that is specified by this directive.
  String _uri;

  /// Initialize a newly created import element to have the given [name] and
  /// [offset]. The offset may be `-1` if the element is synthetic.
  UriReferencedElementImpl(String name, int offset) : super(name, offset);

  UriReferencedElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  /// Initialize using the given serialized information.
  UriReferencedElementImpl.forSerialized(ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  /// Return the URI that is specified by this directive.
  @override
  String get uri => _uri;

  /// Set the URI that is specified by this directive to be the given [uri].
  set uri(String uri) {
    _uri = uri;
  }

  /// Return the offset of the character immediately following the last
  /// character of this node's URI, or `-1` if this node is synthetic.
  @override
  int get uriEnd => _uriEnd;

  /// Set the offset of the character immediately following the last character
  /// of this node's URI to the given [offset].
  set uriEnd(int offset) {
    _uriEnd = offset;
  }

  /// Return the offset of the URI in the file, or `-1` if this node is
  /// synthetic.
  @override
  int get uriOffset => _uriOffset;

  /// Set the offset of the URI in the file to the given [offset].
  set uriOffset(int offset) {
    _uriOffset = offset;
  }
}

/// A concrete implementation of a [VariableElement].
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /// The type of this variable.
  DartType _type;

  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  VariableElementImpl(String name, int offset) : super(name, offset);

  VariableElementImpl.forLinkedNode(
      ElementImpl enclosing, Reference reference, AstNode linkedNode)
      : super.forLinkedNode(enclosing, reference, linkedNode);

  /// Initialize using the given serialized information.
  VariableElementImpl.forSerialized(ElementImpl enclosingElement)
      : super.forSerialized(enclosingElement);

  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression get constantInitializer => null;

  @override
  VariableElement get declaration => this;

  @override
  String get displayName => name;

  /// Return the result of evaluating this variable's initializer as a
  /// compile-time constant expression, or `null` if this variable is not a
  /// 'const' variable, if it does not have an initializer, or if the
  /// compilation unit containing the variable has not been resolved.
  EvaluationResultImpl get evaluationResult => null;

  /// Set the result of evaluating this variable's initializer as a compile-time
  /// constant expression to the given [result].
  set evaluationResult(EvaluationResultImpl result) {
    throw StateError("Invalid attempt to set a compile-time constant result");
  }

  @override
  bool get hasImplicitType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this variable element has an implicit type.
  set hasImplicitType(bool hasImplicitType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitType);
  }

  @override
  bool get isConst {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isConst(linkedNode);
    }
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this variable is const.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  bool get isFinal {
    if (linkedNode != null) {
      return enclosingUnit.linkedContext.isFinal(linkedNode);
    }
    return hasModifier(Modifier.FINAL);
  }

  /// Set whether this variable is final.
  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  set type(DartType type) {
    _type = type;
  }

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get typeInternal => _type;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject computeConstantValue() => null;
}
