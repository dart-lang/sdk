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
  TypedefMirror nonGenericPredicate = reflectType(NonGenericPredicate);
  TypedefMirror predicateOfDynamic = reflectType(GenericPredicate);
  TypedefMirror transformOfDynamic = reflectType(GenericTransform);

  TypedefMirror predicateDecl = predicateOfDynamic.originalDeclaration;
  TypedefMirror transformDecl = transformOfDynamic.originalDeclaration;

  expectReflectedType(nonGenericPredicate, NonGenericPredicate);
  expectReflectedType(predicateOfDynamic, GenericPredicate);
  expectReflectedType(transformOfDynamic, GenericTransform);
  expectReflectedType(predicateDecl, null);
  expectReflectedType(transformDecl, null);
}
