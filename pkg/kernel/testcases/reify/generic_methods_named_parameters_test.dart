// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods with named parameters are of correct type.

library generic_methods_named_parameters_test;

import "test_base.dart";

typedef FunObjObj = Object Function<T>(Object, {Object y});
typedef FunTypObj = Object Function<T>(T, {Object y});
typedef FunObjTyp = Object Function<T>(Object, {T y});
typedef FunTypTyp = Object Function<T>(T, {T y});

Object funObjObj<T>(Object x, {Object y}) => x;
Object funTypObj<T>(T x, {Object y}) => y;
Object funObjTyp<T>(Object x, {T y}) => x;
Object funTypTyp<T>(T x, {T y}) => null;

main() {
  expectTrue(funObjObj is FunObjObj);
  expectTrue(funObjObj is FunTypObj);
  expectTrue(funObjObj is FunObjTyp);
  expectTrue(funObjObj is FunTypTyp);

  expectTrue(funTypObj is! FunObjObj);
  expectTrue(funTypObj is FunTypObj);
  expectTrue(funTypObj is! FunObjTyp);
  expectTrue(funTypObj is FunTypTyp);

  expectTrue(funObjTyp is! FunObjObj);
  expectTrue(funObjTyp is! FunTypObj);
  expectTrue(funObjTyp is FunObjTyp);
  expectTrue(funObjTyp is FunTypTyp);

  expectTrue(funTypTyp is! FunObjObj);
  expectTrue(funTypTyp is! FunTypObj);
  expectTrue(funTypTyp is! FunObjTyp);
  expectTrue(funTypTyp is FunTypTyp);
}
