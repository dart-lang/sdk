// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

import 'package:expect/expect.dart';

@MirrorsUsed(targets: "lib")
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
  ClassMirror superA = a.superclass;
  ClassMirror superB = b.superclass;
  ClassMirror superC = c.superclass;
  ClassMirror superD = d.superclass;
  ClassMirror superE = e.superclass;
  ClassMirror superInterfaceF = f.superinterfaces[0];
  ClassMirror superInterfaceFF = ff.superinterfaces[0];

  TypeVariableMirror aT = a.typeVariables[0];
  TypeVariableMirror dT = d.typeVariables[0];
  TypeVariableMirror eX = e.typeVariables[0];
  TypeVariableMirror eY = e.typeVariables[1];
  TypeVariableMirror fX = f.typeVariables[0];
  TypeVariableMirror feX = ff.typeVariables[0];
  TypeVariableMirror feY = ff.typeVariables[1];

  Expect.isTrue(superA.isOriginalDeclaration);
  Expect.isFalse(superB.isOriginalDeclaration);
  Expect.isFalse(superC.isOriginalDeclaration);
  Expect.isFalse(superD.isOriginalDeclaration);
  Expect.isFalse(superE.isOriginalDeclaration);
  Expect.isFalse(superInterfaceF.isOriginalDeclaration);
  Expect.isFalse(superInterfaceFF.isOriginalDeclaration);

  Expect.equals(reflectClass(Object), superA);
  Expect.equals(reflect(new A<U>()).type, superB);
  Expect.equals(reflect(new A<C>()).type, superC); //# 01: ok
  Expect.equals(reflect(new U()).type, superB.typeArguments[0]);
  Expect.equals(reflect(new C()).type, superC.typeArguments[0]); //# 01: ok
  Expect.equals(dT, superD.typeArguments[0]);
  Expect.equals(eY, superE.typeArguments[0].typeArguments[0]);
  Expect.equals(feY, superInterfaceFF.typeArguments[0].typeArguments[0]);
  Expect.equals(fX, superInterfaceF.typeArguments[0]);
}

void testInstances() {
  ClassMirror a = reflect(new A<U>()).type;
  ClassMirror b = reflect(new B()).type;
  ClassMirror c = reflect(new C()).type;
  ClassMirror d = reflect(new D<U>()).type;
  ClassMirror e = reflect(new E<U, R>()).type;
  ClassMirror e0 = reflect(new E<U, H<R>>()).type;
  ClassMirror ff = reflect(new FF<U, R>()).type;
  ClassMirror f = reflect(new F<U>()).type;
  ClassMirror u = reflect(new U()).type;
  ClassMirror r = reflect(new R()).type;
  ClassMirror hr = reflect(new H<R>()).type;

  ClassMirror superA = a.superclass;
  ClassMirror superB = b.superclass;
  ClassMirror superC = c.superclass;
  ClassMirror superD = d.superclass;
  ClassMirror superE = e.superclass;
  ClassMirror superE0 = e0.superclass;
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
  Expect.equals(reflect(new A<U>()).type, superB);
  Expect.equals(reflect(new A<C>()).type, superC); //# 01: ok
  Expect.equals(reflect(new A<U>()).type, superD);
  Expect.equals(reflect(new G<H<R>>()).type, superE);
  Expect.equals(reflect(new G<H<H<R>>>()).type, superE0);
  Expect.equals(reflect(new G<H<R>>()).type, superInterfaceFF);
  Expect.equals(u, superB.typeArguments[0]);
  Expect.equals(reflect(new C()).type, superC.typeArguments[0]); //# 01: ok
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

main() {
  testOriginals();
  testInstances();
  testObject();
}
