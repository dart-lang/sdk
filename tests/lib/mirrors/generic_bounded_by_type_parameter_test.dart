// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_bounded_by_type_parameter;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Super<T, R extends T> {}

class Fixed extends Super<num, int> {}

class Generic<X, Y> extends Super<X, Y> {} //# 02: compile-time error

main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfNumAndInt = reflectClass(Fixed).superclass;
  ClassMirror genericDecl = reflectClass(Generic); // //# 02: continued
  ClassMirror superOfXAndY = genericDecl.superclass; // //# 02: continued
  ClassMirror genericOfNumAndDouble = reflect(new Generic<num, double>()).type; // //# 02: continued
  ClassMirror superOfNumAndDouble = genericOfNumAndDouble.superclass; // //# 02: continued

  ClassMirror genericOfNumAndBool = reflect(new Generic<num, bool>()).type; // //# 02: compile-time error
  ClassMirror superOfNumAndBool = genericOfNumAndBool.superclass; // //# 02: continued
  Expect.isFalse(genericOfNumAndBool.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(superOfNumAndBool.isOriginalDeclaration); // //# 02: continued
  typeParameters(genericOfNumAndBool, [#X, #Y]); // //# 02: continued
  typeParameters(superOfNumAndBool, [#T, #R]); // //# 02: continued
  typeArguments(genericOfNumAndBool, [reflectClass(num), reflectClass(bool)]); // //# 02: continued
  typeArguments(superOfNumAndBool, [reflectClass(num), reflectClass(bool)]); // //# 02: continued

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfNumAndInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(superOfXAndY.isOriginalDeclaration); //  //# 02: continued
  Expect.isFalse(genericOfNumAndDouble.isOriginalDeclaration); // //# 02: continued
  Expect.isFalse(superOfNumAndDouble.isOriginalDeclaration); // //# 02: continued

  TypeVariableMirror tFromSuper = superDecl.typeVariables[0];
  TypeVariableMirror rFromSuper = superDecl.typeVariables[1];
  TypeVariableMirror xFromGeneric = genericDecl.typeVariables[0]; // //# 02: continued
  TypeVariableMirror yFromGeneric = genericDecl.typeVariables[1]; // //# 02: continued

  Expect.equals(reflectClass(Object), tFromSuper.upperBound);
  Expect.equals(tFromSuper, rFromSuper.upperBound);
  Expect.equals(reflectClass(Object), xFromGeneric.upperBound); // //# 02: continued
  Expect.equals(reflectClass(Object), yFromGeneric.upperBound); // //# 02: continued

  typeParameters(superDecl, [#T, #R]);
  typeParameters(superOfNumAndInt, [#T, #R]);
  typeParameters(genericDecl, [#X, #Y]); // //# 02: continued
  typeParameters(superOfXAndY, [#T, #R]); // //# 02: continued
  typeParameters(genericOfNumAndDouble, [#X, #Y]); // //# 02: continued
  typeParameters(superOfNumAndDouble, [#T, #R]); // //# 02: continued

  typeArguments(superDecl, []);
  typeArguments(superOfNumAndInt, [reflectClass(num), reflectClass(int)]);
  typeArguments(genericDecl, []); // //# 02: continued
  typeArguments(superOfXAndY, [xFromGeneric, yFromGeneric]); // //# 02: continued
  typeArguments(genericOfNumAndDouble, [reflectClass(num), reflectClass(double)]); // //# 02: continued
  typeArguments(superOfNumAndDouble, [reflectClass(num), reflectClass(double)]); // //# 02: continued
}
