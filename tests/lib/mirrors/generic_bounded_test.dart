// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Super<T extends num> {}

class Fixed extends Super<int> {}

class Generic<R extends double> extends Super<R> {}

void main() {
  ClassMirror superDecl = reflectClass(Super);
  ClassMirror superOfInt = reflectClass(Fixed).superclass!;
  ClassMirror genericDecl = reflectClass(Generic);
  ClassMirror superOfR = genericDecl.superclass!;
  ClassMirror genericOfDouble = reflect(Generic<double>()).type;
  ClassMirror superOfDouble = genericOfDouble.superclass!;

  Expect.isTrue(superDecl.isOriginalDeclaration);
  Expect.isFalse(superOfInt.isOriginalDeclaration);
  Expect.isTrue(genericDecl.isOriginalDeclaration);
  Expect.isFalse(superOfR.isOriginalDeclaration);
  Expect.isFalse(genericOfDouble.isOriginalDeclaration);
  Expect.isFalse(superOfDouble.isOriginalDeclaration);

  TypeVariableMirror tFromSuper = superDecl.typeVariables.single;
  TypeVariableMirror rFromGeneric = genericDecl.typeVariables.single;

  Expect.equals(reflectClass(num), tFromSuper.upperBound);
  Expect.equals(reflectClass(double), rFromGeneric.upperBound);

  typeArguments(superDecl, []);
  typeArguments(superOfInt, [reflectClass(int)]);
  typeArguments(genericDecl, []);
  typeArguments(superOfR, [rFromGeneric]);
  typeArguments(genericOfDouble, [reflectClass(double)]);
  typeArguments(superOfDouble, [reflectClass(double)]);
}
