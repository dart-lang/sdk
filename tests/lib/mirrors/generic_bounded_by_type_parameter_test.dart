// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Super<T, R extends T> {}

class Fixed extends Super<num, int> {}

class Generic<X, Y extends X> extends Super<X, Y> {}

void main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfNumAndInt = reflectClass(Fixed).superclass!;
  ClassMirror genericDecl = reflectClass(Generic);
  ClassMirror superOfXAndY = genericDecl.superclass!;

  ClassMirror genericOfNumAndDouble = reflect(new Generic<num, double>()).type;
  ClassMirror superOfNumAndDouble = genericOfNumAndDouble.superclass!;

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfNumAndInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration);
  Expect.isFalse(superOfXAndY.isOriginalDeclaration);
  Expect.isFalse(genericOfNumAndDouble.isOriginalDeclaration);
  Expect.isFalse(superOfNumAndDouble.isOriginalDeclaration);

  TypeVariableMirror tFromSuper = superDecl.typeVariables[0];
  TypeVariableMirror rFromSuper = superDecl.typeVariables[1];
  TypeVariableMirror xFromGeneric = genericDecl.typeVariables[0];
  TypeVariableMirror yFromGeneric = genericDecl.typeVariables[1];

  Expect.equals(reflectClass(Object), tFromSuper.upperBound);
  Expect.equals(tFromSuper, rFromSuper.upperBound);
  Expect.equals(reflectClass(Object), xFromGeneric.upperBound);
  Expect.equals(xFromGeneric, yFromGeneric.upperBound);

  typeArguments(superDecl, []);
  typeArguments(superOfNumAndInt, [reflectClass(num), reflectClass(int)]);
  typeArguments(genericDecl, []);
  typeArguments(superOfXAndY, [xFromGeneric, yFromGeneric]);
  typeArguments(genericOfNumAndDouble, [
    reflectClass(num),
    reflectClass(double),
  ]);
  typeArguments(superOfNumAndDouble, [reflectClass(num), reflectClass(double)]);
}
