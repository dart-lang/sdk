// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_arguments_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<T> {}
class B extends A {}            // Same as class B extends A<dynamic>.
class C extends A
<num, int> // TODO(zarah): Should be "01: static warning".
{} // Same as class C extends A<dynamic>.
class D extends A<int> {}
class E<S> extends A<S> {}
class F<R> extends A<int> {}
class G {}
class H<A,B,C> {}

typeParameters(mirror, parameterNames) {
  Expect.listEquals(parameterNames.map((n) => new Symbol(n)).toList(),
                    mirror.typeVariables.map((v) => v.simpleName).toList());
}

typeArguments(mirror, argumentMirrors) {
  Expect.listEquals(argumentMirrors, mirror.typeArguments);
}

main() {
  // Declarations.
  typeParameters(reflectClass(A), ['T']); /// 01: ok
  typeParameters(reflectClass(B), []); /// 01: ok
  typeParameters(reflectClass(C), []); /// 01: ok
  typeParameters(reflectClass(D), []); /// 01: ok
  typeParameters(reflectClass(E), ['S']); /// 01: ok
  typeParameters(reflectClass(F), ['R']); /// 01: ok
  typeParameters(reflectClass(G), []); /// 01: ok

  typeArguments(reflectClass(A), []);
  typeArguments(reflectClass(B), []);
  typeArguments(reflectClass(C), []);
  typeArguments(reflectClass(D), []);
  typeArguments(reflectClass(E), []);
  typeArguments(reflectClass(F), []);
  typeArguments(reflectClass(G), []);

  Expect.isTrue(reflectClass(A).isOriginalDeclaration);
  Expect.isTrue(reflectClass(B).isOriginalDeclaration);
  Expect.isTrue(reflectClass(C).isOriginalDeclaration);
  Expect.isTrue(reflectClass(D).isOriginalDeclaration);
  Expect.isTrue(reflectClass(E).isOriginalDeclaration);
  Expect.isTrue(reflectClass(F).isOriginalDeclaration);
  Expect.isTrue(reflectClass(G).isOriginalDeclaration);

  Expect.equals(reflectClass(A), reflectClass(A).originalDeclaration);
  Expect.equals(reflectClass(B), reflectClass(B).originalDeclaration);
  Expect.equals(reflectClass(C), reflectClass(C).originalDeclaration);
  Expect.equals(reflectClass(D), reflectClass(D).originalDeclaration);
  Expect.equals(reflectClass(E), reflectClass(E).originalDeclaration);
  Expect.equals(reflectClass(F), reflectClass(F).originalDeclaration);
  Expect.equals(reflectClass(G), reflectClass(G).originalDeclaration);

  // Instantiations.
  typeParameters(reflect(new A<num>()).type, ['T']); /// 01: ok
  typeParameters(reflect(new B<num>()).type, []); /// 01: ok
  typeParameters(reflect(new C()).type, []); /// 01: ok
  typeParameters(reflect(new D()).type, []); /// 01: ok
  typeParameters(reflect(new E()).type, ['S']); /// 01: ok
  typeParameters(reflect(new F<num>()).type, ['R']); /// 01: ok
  typeParameters(reflect(new G()).type, []); /// 01: ok
  typeParameters(reflect(new H()).type, ['A', 'B', 'C']); /// 01: ok

  var numMirror = reflectClass(num);
  var dynamicMirror = currentMirrorSystem().dynamicType;
  typeArguments(reflect(new A<num>()).type, [numMirror]);
  typeArguments(reflect(new A<dynamic>()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new A()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new B()).type, []);
  typeArguments(reflect(new C()).type, []);
  typeArguments(reflect(new D()).type, []);
  typeArguments(reflect(new E<num>()).type, [numMirror]);
  typeArguments(reflect(new E<dynamic>()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new E()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new F<num>()).type, [numMirror]);
  typeArguments(reflect(new F<dynamic>()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new F()).type, [dynamicMirror]); /// 01: ok
  typeArguments(reflect(new G()).type, []);
  typeArguments(reflect(new H<dynamic, num, dynamic>()).type, /// 01: ok
      [dynamicMirror, numMirror, dynamicMirror]); /// 01: ok

  Expect.isFalse(reflect(new A<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new B()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new C()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new D()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new E<num>()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new F<num>()).type.isOriginalDeclaration);
  Expect.isTrue(reflect(new G()).type.isOriginalDeclaration);
  Expect.isFalse(reflect(new H()).type.isOriginalDeclaration); /// 01: ok

  Expect.equals(reflectClass(A),
                reflect(new A<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(B),
                reflect(new B()).type.originalDeclaration);
  Expect.equals(reflectClass(C),
                reflect(new C()).type.originalDeclaration);
  Expect.equals(reflectClass(D),
                reflect(new D()).type.originalDeclaration);
  Expect.equals(reflectClass(E),
                reflect(new E<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(F),
                reflect(new F<num>()).type.originalDeclaration);
  Expect.equals(reflectClass(G),
                reflect(new G()).type.originalDeclaration);
  Expect.equals(reflectClass(H),
                reflect(new H()).type.originalDeclaration);

  Expect.notEquals(reflect(new A<num>()).type,
                   reflect(new A<num>()).type.originalDeclaration);
  Expect.equals(reflect(new B()).type,
                reflect(new B()).type.originalDeclaration);
  Expect.equals(reflect(new C()).type,
                reflect(new C()).type.originalDeclaration);
  Expect.equals(reflect(new D()).type,
                reflect(new D()).type.originalDeclaration);
  Expect.notEquals(reflect(new E<num>()).type,
                   reflect(new E<num>()).type.originalDeclaration);
  Expect.notEquals(reflect(new F<num>()).type,
                   reflect(new F<num>()).type.originalDeclaration);
  Expect.equals(reflect(new G()).type,
                reflect(new G()).type.originalDeclaration);
  Expect.notEquals(reflect(new H()).type, /// 01: ok
                   reflect(new H()).type.originalDeclaration); /// 01: ok

  // Library members are all uninstantaited generics or non-generics.
  currentMirrorSystem().libraries.values.forEach((libraryMirror) {
    libraryMirror.classes.values.forEach((classMirror) {
      // TODO(12282): Deal with generic typedefs.
      if (classMirror is! TypedefMirror) {
        Expect.isTrue(classMirror.isOriginalDeclaration);
        Expect.equals(classMirror, classMirror.originalDeclaration);
      }
    });
  });
}
