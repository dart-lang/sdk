// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods with named parameters are of correct type.

library generic_methods_named_parameters_test;

import "package:expect/expect.dart";

typedef FunObjObj = Object Function<T>(Object, {Object y});
typedef FunTypObj = Object Function<T>(T, {Object y});
typedef FunObjTyp = Object Function<T>(Object, {T y});
typedef FunTypTyp = Object Function<T>(T, {T y});

Object funObjObj<T>(Object x, {Object y}) => x;
Object funTypObj<T>(T x, {Object y}) => y;
Object funObjTyp<T>(Object x, {T y}) => x;
Object funTypTyp<T>(T x, {T y}) => null;

main() {
  Expect.isTrue(funObjObj is FunObjObj);
  Expect.isTrue(funObjObj is FunTypObj);
  Expect.isTrue(funObjObj is FunObjTyp);
  Expect.isTrue(funObjObj is FunTypTyp);

  Expect.isTrue(funTypObj is! FunObjObj);
  Expect.isTrue(funTypObj is FunTypObj);
  Expect.isTrue(funTypObj is! FunObjTyp);
  Expect.isTrue(funTypObj is FunTypTyp);

  Expect.isTrue(funObjTyp is! FunObjObj);
  Expect.isTrue(funObjTyp is! FunTypObj);
  Expect.isTrue(funObjTyp is FunObjTyp);
  Expect.isTrue(funObjTyp is FunTypTyp);

  Expect.isTrue(funTypTyp is! FunObjObj);
  Expect.isTrue(funTypTyp is! FunTypObj);
  Expect.isTrue(funTypTyp is! FunObjTyp);
  Expect.isTrue(funTypTyp is FunTypTyp);
}
