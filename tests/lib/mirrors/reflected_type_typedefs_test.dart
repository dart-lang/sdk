// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_typedefs;

import 'dart:mirrors';

import 'reflected_type_helper.dart';

typedef bool NonGenericPredicate(num n);
typedef bool GenericPredicate<T>(T t);
typedef S GenericTransform<S>(S s);

main() {
  final nonGenericPredicate = reflectType(NonGenericPredicate) as TypedefMirror;
  final predicateOfDynamic = reflectType(GenericPredicate) as TypedefMirror;
  final transformOfDynamic = reflectType(GenericTransform) as TypedefMirror;

  final predicateDecl = predicateOfDynamic.originalDeclaration as TypedefMirror;
  final transformDecl = transformOfDynamic.originalDeclaration as TypedefMirror;

  expectReflectedType(nonGenericPredicate, NonGenericPredicate);
  expectReflectedType(predicateOfDynamic, GenericPredicate);
  expectReflectedType(transformOfDynamic, GenericTransform);
  expectReflectedType(predicateDecl, null);
  expectReflectedType(transformDecl, null);
}
