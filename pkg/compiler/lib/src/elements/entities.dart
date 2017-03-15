// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entities;

import '../common.dart';

/// Abstract interface for entities.
///
/// Implement this directly if the entity is not a Dart language entity.
/// Entities defined within the Dart language should implement [Element].
///
/// For instance, the JavaScript backend need to create synthetic variables for
/// calling intercepted classes and such variables do not correspond to an
/// entity in the Dart source code nor in the terminology of the Dart language
/// and should therefore implement [Entity] directly.
abstract class Entity implements Spannable {
  String get name;
}

/// Stripped down super interface for library like entities.
///
/// Currently only [LibraryElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class LibraryEntity extends Entity {}

/// Stripped down super interface for class like entities.
///
/// Currently only [ClassElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class ClassEntity extends Entity {
  /// If this is a normal class, the enclosing library for this class. If this
  /// is a closure class, the enclosing class of the closure for which it was
  /// created.
  LibraryEntity get library;

  /// Whether this is a synthesized class for a closurized method or local
  /// function.
  bool get isClosure;
}

abstract class TypeVariableEntity extends Entity {
  /// The class or generic method that declared this type variable.
  Entity get typeDeclaration;

  /// The index of this type variable in the type variables of its
  /// [typeDeclaration].
  int get index;
}

/// Stripped down super interface for member like entities, that is,
/// constructors, methods, fields etc.
///
/// Currently only [MemberElement] but later also kernel based Dart members
/// and/or Dart-in-JS properties.
abstract class MemberEntity extends Entity {
  /// Whether this is a member of a library.
  bool get isTopLevel;

  /// Whether this is a static member of a class.
  bool get isStatic;

  /// Whether this is an instance member of a class.
  bool get isInstanceMember;

  /// Whether this is a constructor.
  bool get isConstructor;

  /// Whether this is a field.
  bool get isField;

  /// Whether this is a normal method (neither constructor, getter or setter)
  /// or operator method.
  bool get isFunction;

  /// Whether this is a getter.
  bool get isGetter;

  /// Whether this is a setter.
  bool get isSetter;

  /// Whether this member is assignable, i.e. a non-final field.
  bool get isAssignable;

  /// The enclosing class if this is a constuctor, instance member or
  /// static member of a class.
  ClassEntity get enclosingClass;

  /// The enclosing library if this is a library member, otherwise the
  /// enclosing library of the [enclosingClass].
  LibraryEntity get library;
}

/// Stripped down super interface for field like entities.
///
/// Currently only [FieldElement] but later also kernel based Dart fields
/// and/or Dart-in-JS field-like properties.
abstract class FieldEntity extends MemberEntity {}

/// Stripped down super interface for function like entities.
///
/// Currently only [MethodElement] but later also kernel based Dart constructors
/// and methods and/or Dart-in-JS function-like properties.
abstract class FunctionEntity extends MemberEntity {
  /// Whether this function is external, i.e. the body is not defined in terms
  /// of Dart code.
  bool get isExternal;
}

/// Stripped down super interface for constructor like entities.
///
/// Currently only [ConstructorElement] but later also kernel based Dart
/// constructors and/or Dart-in-JS constructor-like properties.
// TODO(johnniwinther): Remove factory constructors from the set of
// constructors.
abstract class ConstructorEntity extends FunctionEntity {
  /// Whether this is a generative constructor, possibly redirecting.
  bool get isGenerativeConstructor;

  /// Whether this is a factory constructor, possibly redirecting.
  bool get isFactoryConstructor;
}

/// An entity that defines a local entity (memory slot) in generated code.
///
/// Parameters, local variables and local functions (can) define local entity
/// and thus implement [Local] through [LocalElement]. For non-element locals,
/// like `this` and boxes, specialized [Local] classes are created.
///
/// Type variables can introduce locals in factories and constructors
/// but since one type variable can introduce different locals in different
/// factories and constructors it is not itself a [Local] but instead
/// a non-element [Local] is created through a specialized class.
// TODO(johnniwinther): Should [Local] have `isAssignable` or `type`?
abstract class Local extends Entity {
  /// The context in which this local is defined.
  Entity get executableContext;

  /// The outermost member that contains this element.
  ///
  /// For top level, static or instance members, the member context is the
  /// element itself. For parameters, local variables and nested closures, the
  /// member context is the top level, static or instance member in which it is
  /// defined.
  MemberEntity get memberContext;
}
