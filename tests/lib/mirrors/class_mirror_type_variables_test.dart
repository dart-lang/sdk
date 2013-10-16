// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class NoTypeParams {}
class A<T, S extends String> {}
class B<Z extends B<Z>> {}
class C<R,S,T> {
  R foo(R r) => r;
  S bar(S s) => s;
  T baz(T t) => t;
}

testNoTypeParams() {
  ClassMirror cm = reflectClass(NoTypeParams);
  Expect.equals(cm.typeVariables.length, 0);
}

void testA() {
  ClassMirror a = reflectClass(A);
  Expect.equals(2, a.typeVariables.length);

  TypeVariableMirror aT = a.typeVariables[0];
  TypeVariableMirror aS = a.typeVariables[1];
  TypeMirror aTBound = aT.upperBound.originalDeclaration;
  TypeMirror aSBound = aS.upperBound.originalDeclaration;

  Expect.equals(reflectClass(Object), aTBound);
  Expect.equals(reflectClass(String), aSBound);
}

void testB() {
  ClassMirror b = reflectClass(B);
  Expect.equals(1, b.typeVariables.length);

  TypeVariableMirror bZ = b.typeVariables[0];
  ClassMirror bZBound = bZ.upperBound.originalDeclaration;
  Expect.equals(b, bZBound);
  Expect.equals(bZ, bZBound.typeVariables[0]);
}

testC() {
  ClassMirror cm;
  cm = reflectClass(C);
  Expect.equals(3, cm.typeVariables.length);
  var values = cm.typeVariables;
  values.forEach((e) {
    Expect.equals(true, e is TypeVariableMirror);
  });
  Expect.equals(#R, values.elementAt(0).simpleName);
  Expect.equals(#S, values.elementAt(1).simpleName);
  Expect.equals(#T, values.elementAt(2).simpleName);
}

main() {
  testNoTypeParams();
  testA();
  testB();
  testC();
}