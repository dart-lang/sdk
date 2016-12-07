// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entities;

import 'elements.dart' show Entity;

/// Stripped down super interface for class like entities.
///
/// Currently only [ClassElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class ClassEntity extends Entity {
  bool get isClosure;
  void forEachInstanceField(f(ClassEntity cls, FieldEntity field),
      {bool includeSuperAndInjectedMembers: false});
}

/// Stripped down super interface for member like entities, that is,
/// constructors, methods, fields etc.
///
/// Currently only [MemberElement] but later also kernel based Dart members
/// and/or Dart-in-JS properties.
abstract class MemberEntity extends Entity {
  bool get isField;
  bool get isFunction;
  bool get isGetter;
  bool get isSetter;
  bool get isAssignable;
  ClassEntity get enclosingClass;
}

/// Stripped down super interface for field like entities.
///
/// Currently only [FieldElement] but later also kernel based Dart fields
/// and/or Dart-in-JS field-like properties.
abstract class FieldEntity extends MemberEntity {}

/// Stripped down super interface for function like entities.
///
/// Currently only [FieldElement] but later also kernel based Dart constructors
/// and methods and/or Dart-in-JS function-like properties.
abstract class FunctionEntity extends MemberEntity {}
