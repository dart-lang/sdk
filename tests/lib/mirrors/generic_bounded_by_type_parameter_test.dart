// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_bounded_by_type_parameter;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_test.dart';

class Super<T, R extends T> {}

class Fixed extends Super<num, int> {}
class Generic<X, Y> extends Super<X, Y> {}
class Malbounded extends Super<num, String> {} /// 01: static type warning

main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfNumAndInt = reflectClass(Fixed).superclass;
  ClassMirror genericDecl = reflectClass(Generic);
  ClassMirror superOfXAndY = genericDecl.superclass;
  ClassMirror genericOfNumAndDouble = reflect(new Generic<num, double>()).type;
  ClassMirror superOfNumAndDouble = genericOfNumAndDouble.superclass;
  ClassMirror genericOfNumAndBool = reflect(new Generic<num, bool>()).type;  /// 02: static type warning, dynamic type error
  ClassMirror superOfNumAndBool = genericOfNumAndBool.superclass;  /// 02: continued
  ClassMirror superOfNumAndString = reflectClass(Malbounded).superclass;  /// 01: continued

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfNumAndInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration);
  Expect.isFalse(superOfXAndY.isOriginalDeclaration); 
  Expect.isFalse(genericOfNumAndDouble.isOriginalDeclaration);
  Expect.isFalse(superOfNumAndDouble.isOriginalDeclaration);
  Expect.isFalse(genericOfNumAndBool.isOriginalDeclaration);  /// 02: continued
  Expect.isFalse(superOfNumAndBool.isOriginalDeclaration);  /// 02: continued
  Expect.isFalse(superOfNumAndString.isOriginalDeclaration);  /// 01: continued

  TypeVariableMirror tFromSuper = superDecl.typeVariables[0];
  TypeVariableMirror rFromSuper = superDecl.typeVariables[1];
  TypeVariableMirror xFromGeneric = genericDecl.typeVariables[0];
  TypeVariableMirror yFromGeneric = genericDecl.typeVariables[1];

  Expect.equals(reflectClass(Object), tFromSuper.upperBound);
  Expect.equals(tFromSuper, rFromSuper.upperBound);
  Expect.equals(reflectClass(Object), xFromGeneric.upperBound);
  Expect.equals(reflectClass(Object), yFromGeneric.upperBound);

  typeParameters(superDecl, [#T, #R]);
  typeParameters(superOfNumAndInt, [#T, #R]);
  typeParameters(genericDecl, [#X, #Y]);
  typeParameters(superOfXAndY, [#T, #R]);
  typeParameters(genericOfNumAndDouble, [#X, #Y]);
  typeParameters(superOfNumAndDouble, [#T, #R]);
  typeParameters(genericOfNumAndBool, [#X, #Y]);  /// 02: continued
  typeParameters(superOfNumAndBool, [#T, #R]);  /// 02: continued
  typeParameters(superOfNumAndString, [#T, #R]);  /// 01: continued

  typeArguments(superDecl, []);
  typeArguments(superOfNumAndInt, [reflectClass(num), reflectClass(int)]);
  typeArguments(genericDecl, []);
  typeArguments(superOfXAndY, [xFromGeneric, yFromGeneric]);
  typeArguments(genericOfNumAndDouble, [reflectClass(num), reflectClass(double)]);
  typeArguments(superOfNumAndDouble, [reflectClass(num), reflectClass(double)]);
  typeArguments(genericOfNumAndBool, [reflectClass(num), reflectClass(bool)]);  /// 02: continued
  typeArguments(superOfNumAndBool, [reflectClass(num), reflectClass(bool)]);  /// 02: continued
  typeArguments(superOfNumAndString, [reflectClass(num), reflectClass(String)]);  /// 01: continued
}
