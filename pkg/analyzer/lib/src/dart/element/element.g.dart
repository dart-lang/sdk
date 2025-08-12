// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/element/generate.dart' to update.

part of 'element.dart';

mixin _ClassFragmentImplMixin on FragmentImpl {
  bool get hasExtendsClause {
    return hasModifier(Modifier.HAS_EXTENDS_CLAUSE);
  }

  set hasExtendsClause(bool value) {
    setModifier(Modifier.HAS_EXTENDS_CLAUSE, value);
  }

  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool value) {
    setModifier(Modifier.ABSTRACT, value);
  }

  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool value) {
    setModifier(Modifier.BASE, value);
  }

  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool value) {
    setModifier(Modifier.FINAL, value);
  }

  bool get isInterface {
    return hasModifier(Modifier.INTERFACE);
  }

  set isInterface(bool value) {
    setModifier(Modifier.INTERFACE, value);
  }

  bool get isMixinApplication {
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  set isMixinApplication(bool value) {
    setModifier(Modifier.MIXIN_APPLICATION, value);
  }

  bool get isMixinClass {
    return hasModifier(Modifier.MIXIN_CLASS);
  }

  set isMixinClass(bool value) {
    setModifier(Modifier.MIXIN_CLASS, value);
  }

  bool get isSealed {
    return hasModifier(Modifier.SEALED);
  }

  set isSealed(bool value) {
    setModifier(Modifier.SEALED, value);
  }
}

mixin _ConstructorFragmentImplMixin on FragmentImpl {
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  set isConst(bool value) {
    setModifier(Modifier.CONST, value);
  }

  bool get isFactory {
    return hasModifier(Modifier.FACTORY);
  }

  set isFactory(bool value) {
    setModifier(Modifier.FACTORY, value);
  }
}

mixin _VariableFragmentImplMixin on FragmentImpl {
  /// Whether the variable element did not have an explicit type specified
  /// for it.
  bool get hasImplicitType {
    return hasModifier(Modifier.HAS_IMPLICIT_TYPE);
  }

  set hasImplicitType(bool value) {
    setModifier(Modifier.HAS_IMPLICIT_TYPE, value);
  }

  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool value) {
    setModifier(Modifier.ABSTRACT, value);
  }

  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  set isConst(bool value) {
    setModifier(Modifier.CONST, value);
  }

  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  set isExternal(bool value) {
    setModifier(Modifier.EXTERNAL, value);
  }

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool value) {
    setModifier(Modifier.FINAL, value);
  }

  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  set isLate(bool value) {
    setModifier(Modifier.LATE, value);
  }

  /// Whether the element is a static variable, as per section 8 of the Dart
  /// Language Specification:
  ///
  /// > A static variable is a variable that is not associated with a particular
  /// > instance, but rather with an entire library or class. Static variables
  /// > include library variables and class variables. Class variables are
  /// > variables whose declaration is immediately nested inside a class
  /// > declaration and includes the modifier static. A library variable is
  /// > implicitly static.
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  set isStatic(bool value) {
    setModifier(Modifier.STATIC, value);
  }
}
