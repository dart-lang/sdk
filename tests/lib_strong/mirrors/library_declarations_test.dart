// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.library_declarations_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';
import 'declarations_model.dart' as declarations_model;

main() {
  LibraryMirror lm =
      currentMirrorSystem().findLibrary(#test.declarations_model);

  Expect.setEquals([
    'Variable(s(_libraryVariable)'
        ' in s(test.declarations_model), private, top-level, static)',
    'Variable(s(libraryVariable)'
        ' in s(test.declarations_model), top-level, static)'
  ], lm.declarations.values.where((dm) => dm is VariableMirror).map(stringify),
      'variables');

  // dart2js stops testing here.
  return; // //# 01: ok

  Expect.setEquals(
      [
        'Method(s(_libraryGetter)'
            ' in s(test.declarations_model), private, top-level, static, getter)',
        'Method(s(libraryGetter)'
            ' in s(test.declarations_model), top-level, static, getter)'
      ],
      lm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isGetter)
          .map(stringify),
      'getters');

  Expect.setEquals(
      [
        'Method(s(_librarySetter=)'
            ' in s(test.declarations_model), private, top-level, static, setter)',
        'Method(s(librarySetter=)'
            ' in s(test.declarations_model), top-level, static, setter)'
      ],
      lm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isSetter)
          .map(stringify),
      'setters');

  Expect.setEquals(
      [
        'Method(s(_libraryMethod)'
            ' in s(test.declarations_model), private, top-level, static)',
        'Method(s(libraryMethod)'
            ' in s(test.declarations_model), top-level, static)'
      ],
      lm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isRegularMethod)
          .map(stringify),
      'regular methods');

  Expect.setEquals([
    'Class(s(Class) in s(test.declarations_model), top-level)',
    'Class(s(ConcreteClass) in s(test.declarations_model), top-level)',
    'Class(s(Interface) in s(test.declarations_model), top-level)',
    'Class(s(Mixin) in s(test.declarations_model), top-level)',
    'Class(s(Superclass) in s(test.declarations_model), top-level)',
    'Class(s(_PrivateClass)'
        ' in s(test.declarations_model), private, top-level)'
  ], lm.declarations.values.where((dm) => dm is ClassMirror).map(stringify),
      'classes');

  Expect.setEquals([
    'Class(s(Class) in s(test.declarations_model), top-level)',
    'Class(s(ConcreteClass) in s(test.declarations_model), top-level)',
    'Class(s(Interface) in s(test.declarations_model), top-level)',
    'Class(s(Mixin) in s(test.declarations_model), top-level)',
    'Type(s(Predicate) in s(test.declarations_model), top-level)',
    'Class(s(Superclass) in s(test.declarations_model), top-level)',
    'Class(s(_PrivateClass)'
        ' in s(test.declarations_model), private, top-level)'
  ], lm.declarations.values.where((dm) => dm is TypeMirror).map(stringify),
      'types');

  Expect.setEquals([
    'Class(s(Class) in s(test.declarations_model), top-level)',
    'Class(s(ConcreteClass) in s(test.declarations_model), top-level)',
    'Class(s(Interface) in s(test.declarations_model), top-level)',
    'Class(s(Mixin) in s(test.declarations_model), top-level)',
    'Type(s(Predicate) in s(test.declarations_model), top-level)',
    'Class(s(Superclass) in s(test.declarations_model), top-level)',
    'Method(s(libraryGetter)'
        ' in s(test.declarations_model), top-level, static, getter)',
    'Method(s(libraryMethod)'
        ' in s(test.declarations_model), top-level, static)',
    'Method(s(librarySetter=)'
        ' in s(test.declarations_model), top-level, static, setter)',
    'Variable(s(libraryVariable)'
        ' in s(test.declarations_model), top-level, static)'
  ], lm.declarations.values.where((dm) => !dm.isPrivate).map(stringify),
      'public');

  Expect.setEquals([
    'Class(s(Class) in s(test.declarations_model), top-level)',
    'Class(s(ConcreteClass) in s(test.declarations_model), top-level)',
    'Class(s(Interface) in s(test.declarations_model), top-level)',
    'Class(s(Mixin) in s(test.declarations_model), top-level)',
    'Type(s(Predicate) in s(test.declarations_model), top-level)',
    'Class(s(Superclass) in s(test.declarations_model), top-level)',
    'Class(s(_PrivateClass) in s(test.declarations_model), private, top-level)',
    'Method(s(_libraryGetter)'
        ' in s(test.declarations_model), private, top-level, static, getter)',
    'Method(s(_libraryMethod)'
        ' in s(test.declarations_model), private, top-level, static)',
    'Method(s(_librarySetter=)'
        ' in s(test.declarations_model), private, top-level, static, setter)',
    'Variable(s(_libraryVariable)'
        ' in s(test.declarations_model), private, top-level, static)',
    'Method(s(libraryGetter)'
        ' in s(test.declarations_model), top-level, static, getter)',
    'Method(s(libraryMethod) in s(test.declarations_model), top-level, static)',
    'Method(s(librarySetter=)'
        ' in s(test.declarations_model), top-level, static, setter)',
    'Variable(s(libraryVariable)'
        ' in s(test.declarations_model), top-level, static)'
  ], lm.declarations.values.map(stringify), 'all declarations');
}
