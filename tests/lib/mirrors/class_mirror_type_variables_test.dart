// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class NoTypeParams {}
class A<T, S extends String> {}
class B<Z extends B<Z>> {}
class C<Z extends B<Z>> {}
class D<R,S,T> {
  R foo(R r) => r;
  S bar(S s) => s;
  T baz(T t) => t;
}
class Helper<S> {}
class E<R extends Map<R, Helper<String>>> {}
class F<Z extends Helper<F<Z>>> {}

testNoTypeParams() {
  ClassMirror cm = reflectClass(NoTypeParams);
  Expect.equals(cm.typeVariables.length, 0);
}

void testA() {
  ClassMirror a = reflectClass(A);
  Expect.equals(2, a.typeVariables.length);

  TypeVariableMirror aT = a.typeVariables[0];
  TypeVariableMirror aS = a.typeVariables[1];
  ClassMirror aTBound = aT.upperBound;
  ClassMirror aSBound = aS.upperBound;

  Expect.isTrue(aTBound.isOriginalDeclaration);
  Expect.isTrue(aSBound.isOriginalDeclaration);

  Expect.equals(reflectClass(Object), aTBound);
  Expect.equals(reflectClass(String), aSBound);
}

void testBAndC() {
  ClassMirror b = reflectClass(B);
  ClassMirror c = reflectClass(C);

  Expect.equals(1, b.typeVariables.length);
  Expect.equals(1, c.typeVariables.length);

  TypeVariableMirror bZ = b.typeVariables[0];
  TypeVariableMirror cZ = c.typeVariables[0];
  ClassMirror bZBound = bZ.upperBound;
  ClassMirror cZBound = cZ.upperBound;

  Expect.isFalse(bZBound.isOriginalDeclaration);
  Expect.isFalse(cZBound.isOriginalDeclaration);

  Expect.notEquals(bZBound, cZBound);
  Expect.equals(b, bZBound.originalDeclaration);
  Expect.equals(b, cZBound.originalDeclaration);

  TypeMirror bZBoundTypeArgument = bZBound.typeArguments.single;
  TypeMirror cZBoundTypeArgument = cZBound.typeArguments.single;
  TypeVariableMirror bZBoundTypeVariable = bZBound.typeVariables.single;
  TypeVariableMirror cZBoundTypeVariable = cZBound.typeVariables.single;

  Expect.equals(b, bZ.owner);
  Expect.equals(c, cZ.owner);
  Expect.equals(b, bZBoundTypeVariable.owner); /// 01: ok
  Expect.equals(b, cZBoundTypeVariable.owner); /// 01: ok
  Expect.equals(b, bZBoundTypeArgument.owner);
  Expect.equals(c, cZBoundTypeArgument.owner);

  Expect.notEquals(bZ, cZ);
  Expect.equals(bZ, bZBoundTypeArgument);
  Expect.equals(cZ, cZBoundTypeArgument);
  Expect.equals(bZ, bZBoundTypeVariable); /// 01: ok
  Expect.equals(bZ, cZBoundTypeVariable); /// 01: ok
}

testD() {
  ClassMirror cm;
  cm = reflectClass(D);
  Expect.equals(3, cm.typeVariables.length);
  var values = cm.typeVariables;
  values.forEach((e) {
    Expect.equals(true, e is TypeVariableMirror);
  });
  Expect.equals(#R, values.elementAt(0).simpleName);
  Expect.equals(#S, values.elementAt(1).simpleName);
  Expect.equals(#T, values.elementAt(2).simpleName);
}

void testE() {
  ClassMirror e = reflectClass(E);
  TypeVariableMirror eR = e.typeVariables.single;
  ClassMirror mapRAndHelperOfString = eR.upperBound;

  Expect.isFalse(mapRAndHelperOfString.isOriginalDeclaration);
  Expect.equals(eR, mapRAndHelperOfString.typeArguments.first);
  Expect.equals(reflect(new Helper<String>()).type,
      mapRAndHelperOfString.typeArguments.last);
}

void testF() {
  ClassMirror f = reflectClass(F);
  TypeVariableMirror fZ = f.typeVariables[0];
  ClassMirror fZBound = fZ.upperBound;
  ClassMirror fZBoundTypeArgument = fZBound.typeArguments.single;

  Expect.equals(1, f.typeVariables.length);
  Expect.isFalse(fZBound.isOriginalDeclaration);
  Expect.isFalse(fZBoundTypeArgument.isOriginalDeclaration);
  Expect.equals(f, fZBoundTypeArgument.originalDeclaration);
  Expect.equals(fZ, fZBoundTypeArgument.typeArguments.single);
}

main() {
  testNoTypeParams();
  testA();
  testBAndC();
  testD();
  testE();
  testF();
}
