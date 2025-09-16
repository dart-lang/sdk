// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'generics_helper.dart';

class A<T> {}

class Z<T> {}

class B extends A {}

class C extends A<num> {}

class D extends A<int> {}

class E<S> extends A<S> {}

class F<R> extends A<int> {}

class G {}

class H<A, B, C> {}

class I extends G {}

void main() {
  // Declarations.
  typeParameters(reflectClass(G), []);
  typeParameters(reflectClass(B), []);
  typeParameters(reflectClass(C), []);
  typeParameters(reflectClass(D), []);
  typeParameters(reflectClass(G), []);
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
  typeParameters(reflect(B()).type, []);
  typeParameters(reflect(C()).type, []);
  typeParameters(reflect(D()).type, []);
  typeParameters(reflect(G()).type, []);
  typeParameters(reflect(I()).type, []);

  var numMirror = reflectClass(num);
  var dynamicMirror = currentMirrorSystem().dynamicType;
  typeArguments(reflect(A<num>()).type, [numMirror]);
  typeArguments(reflect(A<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(A()).type, [dynamicMirror]);
  typeArguments(reflect(B()).type, []);
  typeArguments(reflect(C()).type, []);
  typeArguments(reflect(D()).type, []);
  typeArguments(reflect(E<num>()).type, [numMirror]);
  typeArguments(reflect(E<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(E()).type, [dynamicMirror]);
  typeArguments(reflect(F<num>()).type, [numMirror]);
  typeArguments(reflect(F<dynamic>()).type, [dynamicMirror]);
  typeArguments(reflect(F()).type, [dynamicMirror]);
  typeArguments(reflect(G()).type, []);
  typeArguments(reflect(H<dynamic, num, dynamic>()).type, [
    dynamicMirror,
    numMirror,
    dynamicMirror,
  ]);
  typeArguments(reflect(I()).type, []);

  Expect.isFalse(reflect(A<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(B()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(C()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(D()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(E<num>()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(F<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(G()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(H()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(I()).type.isOriginalDeclaration);

  Expect.equals(reflectClass(A), reflect(A<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(B), reflect(B()).type.originalDeclaration);
  Expect.equals(reflectClass(C), reflect(C()).type.originalDeclaration);
  Expect.equals(reflectClass(D), reflect(D()).type.originalDeclaration);
  Expect.equals(reflectClass(E), reflect(E<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(F), reflect(F<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(G), reflect(G()).type.originalDeclaration);
  Expect.equals(reflectClass(H), reflect(H()).type.originalDeclaration);
  Expect.equals(reflectClass(I), reflect(I()).type.originalDeclaration);

  Expect.notEquals(
    reflect(A<num>()).type,
    reflect(A<num>()).type.originalDeclaration,
  );
  Expect.equals(reflect(B()).type, reflect(B()).type.originalDeclaration);
  Expect.equals(reflect(C()).type, reflect(C()).type.originalDeclaration);
  Expect.equals(reflect(D()).type, reflect(D()).type.originalDeclaration);
  Expect.notEquals(
    reflect(E<num>()).type,
    reflect(E<num>()).type.originalDeclaration,
  );
  Expect.notEquals(
    reflect(F<num>()).type,
    reflect(F<num>()).type.originalDeclaration,
  );
  Expect.equals(reflect(G()).type, reflect(G()).type.originalDeclaration);
  Expect.notEquals(reflect(H()).type, reflect(H()).type.originalDeclaration);
  Expect.equals(reflect(I()).type, reflect(I()).type.originalDeclaration);

  // Library members are all uninstantiated generics or non-generics.
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
  Expect.equals(
    reflectClass(A).typeVariables[0],
    reflectClass(A).typeVariables[0],
  );
}
