// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 14972.

library test.declarations_type;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {}

main() {
  var classDeclarations = reflectClass(C).declarations;
  Expect.isTrue(classDeclarations is Map<Symbol, DeclarationMirror>);
  Expect.isTrue(classDeclarations.values is Iterable<DeclarationMirror>);
  Expect.isTrue(classDeclarations.values.where((x) => true)
      is Iterable<DeclarationMirror>);
  Expect.isFalse(classDeclarations is Map<Symbol, MethodMirror>);
  Expect.isFalse(classDeclarations.values is Iterable<MethodMirror>);
  Expect.isFalse(
      classDeclarations.values.where((x) => true) is Iterable<MethodMirror>);

  var libraryDeclarations =
      (reflectClass(C).owner as LibraryMirror).declarations;
  Expect.isTrue(libraryDeclarations is Map<Symbol, DeclarationMirror>);
  Expect.isTrue(libraryDeclarations.values is Iterable<DeclarationMirror>);
  Expect.isTrue(libraryDeclarations.values.where((x) => true)
      is Iterable<DeclarationMirror>);
  Expect.isFalse(libraryDeclarations is Map<Symbol, ClassMirror>);
  Expect.isFalse(libraryDeclarations.values is Iterable<ClassMirror>);
  Expect.isFalse(
      libraryDeclarations.values.where((x) => true) is Iterable<ClassMirror>);
}
