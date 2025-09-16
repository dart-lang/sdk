// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:mirrors';

class A<T> {}

class B extends A<U> {}

class C extends A<C> {}

class D<T> extends A<T> {}

class E<X, Y> extends G<H<Y>> {}

class F<X> implements A<X> {}

class FF<X, Y> implements G<H<Y>> {}

class G<T> {}

class H<T> {}

class U {}

class R {}

void testOriginals() {
  ClassMirror a = reflectClass(A);
  ClassMirror b = reflectClass(B);
  ClassMirror c = reflectClass(C);
  ClassMirror d = reflectClass(D);
  ClassMirror e = reflectClass(E);
  ClassMirror f = reflectClass(F);
  ClassMirror ff = reflectClass(FF);
  ClassMirror superA = a.superclass!;
  ClassMirror superB = b.superclass!;
  ClassMirror superC = c.superclass!;
  ClassMirror superD = d.superclass!;
  ClassMirror superE = e.superclass!;
  ClassMirror superInterfaceF = f.superinterfaces[0];
  ClassMirror superInterfaceFF = ff.superinterfaces[0];

  TypeVariableMirror dT = d.typeVariables[0];
  TypeVariableMirror eY = e.typeVariables[1];
  TypeVariableMirror fX = f.typeVariables[0];
  TypeVariableMirror feY = ff.typeVariables[1];

  Expect.isTrue(superA.isOriginalDeclaration);
  Expect.isFalse(superB.isOriginalDeclaration);
  Expect.isFalse(superC.isOriginalDeclaration);
  Expect.isFalse(superD.isOriginalDeclaration);
  Expect.isFalse(superE.isOriginalDeclaration);
  Expect.isFalse(superInterfaceF.isOriginalDeclaration);
  Expect.isFalse(superInterfaceFF.isOriginalDeclaration);

  Expect.equals(reflectClass(Object), superA);
  Expect.equals(reflect(A<U>()).type, superB);
  Expect.equals(reflect(A<C>()).type, superC);
  Expect.equals(reflect(U()).type, superB.typeArguments[0]);
  Expect.equals(reflect(C()).type, superC.typeArguments[0]);
  Expect.equals(dT, superD.typeArguments[0]);
  Expect.equals(eY, superE.typeArguments[0].typeArguments[0]);
  Expect.equals(feY, superInterfaceFF.typeArguments[0].typeArguments[0]);
  Expect.equals(fX, superInterfaceF.typeArguments[0]);
}

void testInstances() {
  ClassMirror a = reflect(A<U>()).type;
  ClassMirror b = reflect(B()).type;
  ClassMirror c = reflect(C()).type;
  ClassMirror d = reflect(D<U>()).type;
  ClassMirror e = reflect(E<U, R>()).type;
  ClassMirror e0 = reflect(E<U, H<R>>()).type;
  ClassMirror ff = reflect(FF<U, R>()).type;
  ClassMirror f = reflect(F<U>()).type;
  ClassMirror u = reflect(U()).type;
  ClassMirror r = reflect(R()).type;
  ClassMirror hr = reflect(H<R>()).type;

  ClassMirror superA = a.superclass!;
  ClassMirror superB = b.superclass!;
  ClassMirror superC = c.superclass!;
  ClassMirror superD = d.superclass!;
  ClassMirror superE = e.superclass!;
  ClassMirror superE0 = e0.superclass!;
  ClassMirror superInterfaceF = f.superinterfaces[0];
  ClassMirror superInterfaceFF = ff.superinterfaces[0];

  Expect.isTrue(superA.isOriginalDeclaration);
  Expect.isFalse(superB.isOriginalDeclaration);
  Expect.isFalse(superC.isOriginalDeclaration);
  Expect.isFalse(superD.isOriginalDeclaration);
  Expect.isFalse(superE.isOriginalDeclaration);
  Expect.isFalse(superE0.isOriginalDeclaration);
  Expect.isFalse(superInterfaceF.isOriginalDeclaration);
  Expect.isFalse(superInterfaceFF.isOriginalDeclaration);

  Expect.equals(reflectClass(Object), superA);
  Expect.equals(reflect(A<U>()).type, superB);
  Expect.equals(reflect(A<C>()).type, superC);
  Expect.equals(reflect(A<U>()).type, superD);
  Expect.equals(reflect(G<H<R>>()).type, superE);
  Expect.equals(reflect(G<H<H<R>>>()).type, superE0);
  Expect.equals(reflect(G<H<R>>()).type, superInterfaceFF);
  Expect.equals(u, superB.typeArguments[0]);
  Expect.equals(reflect(C()).type, superC.typeArguments[0]);
  Expect.equals(u, superD.typeArguments[0]);
  Expect.equals(r, superE.typeArguments[0].typeArguments[0]);
  Expect.equals(hr, superE0.typeArguments[0].typeArguments[0]);
  Expect.equals(r, superInterfaceFF.typeArguments[0].typeArguments[0]);
  Expect.equals(u, superInterfaceF.typeArguments[0]);
}

void testObject() {
  ClassMirror object = reflectClass(Object);
  Expect.equals(null, object.superclass);
}

void main() {
  testOriginals();
  testInstances();
  testObject();
}
