// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<T> {}

class B extends A {}

class C extends A<num> {}

class D extends A<int> {}

class E<S> extends A<S> {}

class F<R> extends A<int> {}

class G {}

class H<A, B, C> {}

void expectReflectedType(classMirror, expectedType) {
  if (expectedType == null) {
    Expect.isFalse(
      classMirror.hasReflectedType,
      "$classMirror should not have a reflected type",
    );
    Expect.throwsUnsupportedError(() => classMirror.reflectedType);
  } else {
    Expect.isTrue(
      classMirror.hasReflectedType,
      "$classMirror should have a reflected type",
    );
    Expect.equals(expectedType, classMirror.reflectedType);
  }
}

void main() {
  // Basic non-generic types, including intercepted types.
  expectReflectedType(reflectClass(Object), Object);
  expectReflectedType(reflectClass(String), String);
  expectReflectedType(reflectClass(int), int);
  expectReflectedType(reflectClass(num), num);
  expectReflectedType(reflectClass(double), double);
  expectReflectedType(reflectClass(bool), bool);
  expectReflectedType(reflectClass(Null), Null);

  // Declarations.
  expectReflectedType(reflectClass(A), null);
  expectReflectedType(reflectClass(B), B);
  expectReflectedType(reflectClass(C), C);
  expectReflectedType(reflectClass(D), D);
  expectReflectedType(reflectClass(E), null);
  expectReflectedType(reflectClass(F), null);
  expectReflectedType(reflectClass(G), G);
  expectReflectedType(reflectClass(H), null);

  // Instantiations.
  expectReflectedType(reflect(A()).type, A().runtimeType);
  expectReflectedType(reflect(B()).type, B().runtimeType);
  expectReflectedType(reflect(C()).type, C().runtimeType);
  expectReflectedType(reflect(D()).type, D().runtimeType);
  expectReflectedType(reflect(E()).type, E().runtimeType);
  expectReflectedType(reflect(F()).type, F().runtimeType);
  expectReflectedType(reflect(G()).type, G().runtimeType);
  expectReflectedType(reflect(H()).type, H().runtimeType);

  expectReflectedType(reflect(A<num>()).type, A<num>().runtimeType);
  expectReflectedType(reflect(B()).type.superclass, A<dynamic>().runtimeType);
  expectReflectedType(reflect(C()).type.superclass, A<num>().runtimeType);
  expectReflectedType(reflect(D()).type.superclass, A<int>().runtimeType);
  expectReflectedType(reflect(E<num>()).type, E<num>().runtimeType);
  expectReflectedType(reflect(E<num>()).type.superclass, A<num>().runtimeType);
  expectReflectedType(reflect(F<num>()).type.superclass, A<int>().runtimeType);
  expectReflectedType(reflect(F<num>()).type, F<num>().runtimeType);
  expectReflectedType(
    reflect(H<num, num, num>()).type,
    H<num, num, num>().runtimeType,
  );
}
