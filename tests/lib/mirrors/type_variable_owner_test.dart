// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Owner of a type variable should be the declaration of the generic class or
// typedef, not an instantiation.

import "dart:mirrors";

import "package:expect/expect.dart";

class A<T> {}

class B<R> extends A<R> {}

void testTypeVariableOfClass() {
  ClassMirror aDecl = reflectClass(A);
  ClassMirror bDecl = reflectClass(B);
  ClassMirror aOfInt = reflect(A<int>()).type;
  ClassMirror aOfR = bDecl.superclass!;
  ClassMirror bOfString = reflect(B<String>()).type;
  ClassMirror aOfString = bOfString.superclass!;

  Expect.equals(aDecl, aDecl.typeVariables[0].owner);
  Expect.equals(aDecl, aOfInt.typeVariables[0].owner);
  Expect.equals(aDecl, aOfR.typeVariables[0].owner);
  Expect.equals(aDecl, aOfString.typeVariables[0].owner);

  Expect.equals(bDecl, bDecl.typeVariables[0].owner);
  Expect.equals(bDecl, bOfString.typeVariables[0].owner);
}

void main() {
  testTypeVariableOfClass();
}
