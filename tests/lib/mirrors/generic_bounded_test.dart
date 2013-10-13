// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_bounded;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_test.dart';

class Super<T extends num> {}

class Fixed extends Super<int> {}
class Generic<R> extends Super<R> {}
class Malbounded extends Super<String> {} /// 01: static type warning

main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfInt = reflectClass(Fixed).superclass;
  ClassMirror genericDecl = reflectClass(Generic);
  ClassMirror superOfR = genericDecl.superclass;
  ClassMirror genericOfDouble = reflect(new Generic<double>()).type;
  ClassMirror superOfDouble = genericOfDouble.superclass;
  ClassMirror genericOfBool = reflect(new Generic<bool>()).type;  /// 02: static type warning, dynamic type error
  ClassMirror superOfBool = genericOfBool.superclass;  /// 02: continued
  ClassMirror superOfString = reflectClass(Malbounded).superclass;  /// 01: continued

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration);
  Expect.isFalse(superOfR.isOriginalDeclaration);
  Expect.isFalse(genericOfDouble.isOriginalDeclaration);
  Expect.isFalse(superOfDouble.isOriginalDeclaration);
  Expect.isFalse(genericOfBool.isOriginalDeclaration);  /// 02: continued
  Expect.isFalse(superOfBool.isOriginalDeclaration);  /// 02: continued
  Expect.isFalse(superOfString.isOriginalDeclaration);  /// 01: continued

  TypeVariableMirror tFromSuper = superDecl.typeVariables.single;
  TypeVariableMirror rFromGeneric = genericDecl.typeVariables.single;

  Expect.equals(reflectClass(num), tFromSuper.upperBound);
  Expect.equals(reflectClass(Object), rFromGeneric.upperBound);

  typeParameters(superDecl, [#T]);
  typeParameters(superOfInt, [#T]);
  typeParameters(genericDecl, [#R]);
  typeParameters(superOfR, [#T]);
  typeParameters(genericOfDouble, [#R]);
  typeParameters(superOfDouble, [#T]);
  typeParameters(genericOfBool, [#R]);  /// 02: continued
  typeParameters(superOfBool, [#T]);  /// 02: continued
  typeParameters(superOfString, [#T]);  /// 01: continued

  typeArguments(superDecl, []);
  typeArguments(superOfInt, [reflectClass(int)]);
  typeArguments(genericDecl, []);
  typeArguments(superOfR, [rFromGeneric]);
  typeArguments(genericOfDouble, [reflectClass(double)]);
  typeArguments(superOfDouble, [reflectClass(double)]);
  typeArguments(genericOfBool, [reflectClass(bool)]);  /// 02: continued
  typeArguments(superOfBool, [reflectClass(bool)]);  /// 02: continued
  typeArguments(superOfString, [reflectClass(String)]);  /// 01: continued
}
