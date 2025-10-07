// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'reflected_type_helper.dart';

class A<T> {}

class B extends A {}

class D extends A<int> {}

class E<S> extends A<S> {}

class F<R> extends A<int> {}

class G {}

class H<A, B, C> {}

void main() {
  // Declarations. Generic reflected classes discard type arguments and have
  // no reflected type.
  expectReflectedType(reflectClass(A), null);
  expectReflectedType(reflectClass(A<num>), null);
  expectReflectedType(reflectClass(B), B);
  expectReflectedType(reflectClass(D), D);
  expectReflectedType(reflectClass(E), null);
  expectReflectedType(reflectClass(F), null);
  expectReflectedType(reflectClass(G), G);
  expectReflectedType(reflectClass(H), null);

  // Types. Generic reflected class types have a reflected type.
  expectReflectedType(reflectType(A), A<dynamic>);
  expectReflectedType(reflectType(A<num>), A<num>);
  expectReflectedType(reflectType(B), B);
  expectReflectedType(reflectType(D), D);
  expectReflectedType(reflectType(E), E<dynamic>);
  expectReflectedType(reflectType(F), F<dynamic>);
  expectReflectedType(reflectType(G), G);
  expectReflectedType(reflectType(H), H<dynamic, dynamic, dynamic>);

  // Instances.
  expectReflectedType(reflect(A()).type, A);
  expectReflectedType(reflect(B()).type, B);
  expectReflectedType(reflect(D()).type, D);
  expectReflectedType(reflect(E()).type, E);
  expectReflectedType(reflect(F()).type, F);
  expectReflectedType(reflect(G()).type, G);
  expectReflectedType(reflect(H()).type, H);

  expectReflectedType(reflect(A<num>()).type, A<num>);
  expectReflectedType(reflect(B()).type.superclass!, A<dynamic>);
  expectReflectedType(reflect(D()).type.superclass!, A<int>);
  expectReflectedType(reflect(E<num>()).type, E<num>);
  expectReflectedType(reflect(E<num>()).type.superclass!, A<num>);
  expectReflectedType(reflect(F<num>()).type.superclass!, A<int>);
  expectReflectedType(reflect(F<num>()).type, F<num>);
  expectReflectedType(reflect(H<num, num, num>()).type, H<num, num, num>);
}
