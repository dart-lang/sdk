// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_arguments_test;

@MirrorsUsed(targets: "test.type_arguments_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'generics_helper.dart';

class A<T> {}

class Z<T> {}

class B extends A {}

class C
    extends A<num, int> // //# 01: static type warning
{}

class D extends A<int> {}

class E<S> extends A<S> {}

class F<R> extends A<int> {}

class G {}

class H<A, B, C> {}

class I extends G {}

main() {
  // Declarations.
  typeParameters(reflectClass(A), [#T]);
  typeParameters(reflectClass(G), []);
  typeParameters(reflectClass(B), []);
  typeParameters(reflectClass(C), []);
  typeParameters(reflectClass(D), []);
  typeParameters(reflectClass(E), [#S]);
  typeParameters(reflectClass(F), [#R]);
  typeParameters(reflectClass(G), []);
  typeParameters(reflectClass(H), [#A, #B, #C]);
  typeParameters(reflectClass(I), []);

  typeArguments(reflectClass(A), []);
  typeArguments(reflectClass(B), []);
  typeArguments(reflectClass(C), []);
  typeArguments(reflectClass(D), []);
  typeArguments(reflectClass(E), []);
  typeArguments(reflectClass(F), []);
  typeArguments(reflectClass(G), []);
  typeArguments(reflectClass(H), []);
  typeArguments(reflectClass(I), []);

  Expect.isTrue(reflectClass(A).isOriginalDeclaration);
  Expect.isTrue(reflectClass(B).isOriginalDeclaration);
  Expect.isTrue(reflectClass(C).isOriginalDeclaration);
  Expect.isTrue(reflectClass(D).isOriginalDeclaration);
  Expect.isTrue(reflectClass(E).isOriginalDeclaration);
  Expect.isTrue(reflectClass(F).isOriginalDeclaration);
  Expect.isTrue(reflectClass(G).isOriginalDeclaration);
  Expect.isTrue(reflectClass(H).isOriginalDeclaration);
  Expect.isTrue(reflectClass(I).isOriginalDeclaration);

  Expect.equals(reflectClass(A), reflectClass(A).originalDeclaration);
  Expect.equals(reflectClass(B), reflectClass(B).originalDeclaration);
  Expect.equals(reflectClass(C), reflectClass(C).originalDeclaration);
  Expect.equals(reflectClass(D), reflectClass(D).originalDeclaration);
  Expect.equals(reflectClass(E), reflectClass(E).originalDeclaration);
  Expect.equals(reflectClass(F), reflectClass(F).originalDeclaration);
  Expect.equals(reflectClass(G), reflectClass(G).originalDeclaration);
  Expect.equals(reflectClass(H), reflectClass(H).originalDeclaration);
  Expect.equals(reflectClass(I), reflectClass(I).originalDeclaration);

  // Instantiations.
  typeParameters(reflect(new A<num>()).type, [#T]);
  typeParameters(reflect(new B()).type, []);
  typeParameters(reflect(new C()).type, []);
  typeParameters(reflect(new D()).type, []);
  typeParameters(reflect(new E()).type, [#S]);
  typeParameters(reflect(new F<num>()).type, [#R]);
  typeParameters(reflect(new G()).type, []);
  typeParameters(reflect(new H()).type, [#A, #B, #C]);
  typeParameters(reflect(new I()).type, []);

  var numMirror = reflectClass(num);
  var dynamicMirror = currentMirrorSystem().dynamicType;
  typeArguments(reflect(new A<num>()).type, [numMirror]);
  typeArguments(reflect(new A<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(new A()).type, [dynamicMirror]);
  typeArguments(reflect(new B()).type, []);
  typeArguments(reflect(new C()).type, []);
  typeArguments(reflect(new D()).type, []);
  typeArguments(reflect(new E<num>()).type, [numMirror]);
  typeArguments(reflect(new E<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(new E()).type, [dynamicMirror]);
  typeArguments(reflect(new F<num>()).type, [numMirror]);
  typeArguments(reflect(new F<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(new F()).type, [dynamicMirror]);
  typeArguments(reflect(new G()).type, []);
  typeArguments(reflect(new H<dynamic, num, dynamic>()).type,
      [dynamicMirror, numMirror, dynamicMirror]);
  typeArguments(reflect(new I()).type, []);

  Expect.isFalse(reflect(new A<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new B()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new C()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new D()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new E<num>()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new F<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new G()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new H()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new I()).type.isOriginalDeclaration);

  Expect.equals(
      reflectClass(A), reflect(new A<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(B), reflect(new B()).type.originalDeclaration);
  Expect.equals(reflectClass(C), reflect(new C()).type.originalDeclaration);
  Expect.equals(reflectClass(D), reflect(new D()).type.originalDeclaration);
  Expect.equals(
      reflectClass(E), reflect(new E<num>()).type.originalDeclaration);
  Expect.equals(
      reflectClass(F), reflect(new F<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(G), reflect(new G()).type.originalDeclaration);
  Expect.equals(reflectClass(H), reflect(new H()).type.originalDeclaration);
  Expect.equals(reflectClass(I), reflect(new I()).type.originalDeclaration);

  Expect.notEquals(reflect(new A<num>()).type,
      reflect(new A<num>()).type.originalDeclaration);
  Expect.equals(
      reflect(new B()).type, reflect(new B()).type.originalDeclaration);
  Expect.equals(
      reflect(new C()).type, reflect(new C()).type.originalDeclaration);
  Expect.equals(
      reflect(new D()).type, reflect(new D()).type.originalDeclaration);
  Expect.notEquals(reflect(new E<num>()).type,
      reflect(new E<num>()).type.originalDeclaration);
  Expect.notEquals(reflect(new F<num>()).type,
      reflect(new F<num>()).type.originalDeclaration);
  Expect.equals(
      reflect(new G()).type, reflect(new G()).type.originalDeclaration);
  Expect.notEquals(
      reflect(new H()).type, reflect(new H()).type.originalDeclaration);
  Expect.equals(
      reflect(new I()).type, reflect(new I()).type.originalDeclaration);

  // Library members are all uninstantaited generics or non-generics.
  currentMirrorSystem().libraries.values.forEach((libraryMirror) {
    libraryMirror.declarations.values.forEach((declaration) {
      if (declaration is ClassMirror) {
        Expect.isTrue(declaration.isOriginalDeclaration);
        Expect.equals(declaration, declaration.originalDeclaration);
      }
    });
  });

  Expect.equals(reflectClass(A).typeVariables[0].owner, reflectClass(A));
  Expect.equals(reflectClass(Z).typeVariables[0].owner, reflectClass(Z));
  Expect.notEquals(
      reflectClass(A).typeVariables[0], reflectClass(Z).typeVariables[0]);
  Expect.equals(
      reflectClass(A).typeVariables[0], reflectClass(A).typeVariables[0]);
}
