// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_bounded;

@MirrorsUsed(targets: "test.generic_bounded")
import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Super<T extends num> {}

class Fixed extends Super<int> {}
class Generic<R> extends Super<R> {} // //# 02: static type warning
class Malbounded extends Super<String> {} //# 01: static type warning

bool inCheckedMode() {
  try {
    var s = 'string';
    int i = s;
  } catch (e) {
    return true;
  }
  return false;
}

main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfInt = reflectClass(Fixed).superclass;
  ClassMirror genericDecl = reflectClass(Generic); // //# 02: continued
  ClassMirror superOfR = genericDecl.superclass; // //# 02: continued
  ClassMirror genericOfDouble = reflect(new Generic<double>()).type; // //# 02: continued
  ClassMirror superOfDouble = genericOfDouble.superclass; // //# 02: continued

  try {
    ClassMirror genericOfBool = reflect(new Generic<bool>()).type; // //# 02: static type warning
    ClassMirror superOfBool = genericOfBool.superclass; // //# 02: continued
    Expect.isFalse(genericOfBool.isOriginalDeclaration); // //# 02: continued
    Expect.isFalse(superOfBool.isOriginalDeclaration); // //# 02: continued
    typeParameters(genericOfBool, [#R]); // //# 02: continued
    typeParameters(superOfBool, [#T]); // //# 02: continued
    typeArguments(genericOfBool, [reflectClass(bool)]); // //# 02: continued
    typeArguments(superOfBool, [reflectClass(bool)]); // //# 02: continued
    Expect.isFalse(inCheckedMode()); //# 02: continued
  } on TypeError catch (e) {
    Expect.isTrue(inCheckedMode());
  }

  ClassMirror superOfString = reflectClass(Malbounded).superclass; // //# 01: continued

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(superOfR.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(genericOfDouble.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(superOfDouble.isOriginalDeclaration); // //# 02: continued

  Expect.isFalse(superOfString.isOriginalDeclaration); // //# 01: continued

  TypeVariableMirror tFromSuper = superDecl.typeVariables.single;
  TypeVariableMirror rFromGeneric = genericDecl.typeVariables.single; // //# 02: continued

  Expect.equals(reflectClass(num), tFromSuper.upperBound);
  Expect.equals(reflectClass(Object), rFromGeneric.upperBound); // //# 02: continued

  typeParameters(superDecl, [#T]);
  typeParameters(superOfInt, [#T]);
  typeParameters(genericDecl, [#R]); // //# 02: continued
  typeParameters(superOfR, [#T]); // //# 02: continued
  typeParameters(genericOfDouble, [#R]); // //# 02: continued
  typeParameters(superOfDouble, [#T]); // //# 02: continued
  typeParameters(superOfString, [#T]); // //# 01: continued

  typeArguments(superDecl, []);
  typeArguments(superOfInt, [reflectClass(int)]);
  typeArguments(genericDecl, []); // //# 02: continued
  typeArguments(superOfR, [rFromGeneric]); // //# 02: continued
  typeArguments(genericOfDouble, [reflectClass(double)]); // //# 02: continued
  typeArguments(superOfDouble, [reflectClass(double)]); // //# 02: continued
  typeArguments(superOfString, [reflectClass(String)]); // //# 01: continued
}
