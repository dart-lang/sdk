// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

// Returns sWrapped<tWrapped> as a wrapped type.
Object generic1(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#)', sGeneric, t));
}

void checkSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t));
}

void checkProperSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t));
  Expect.isFalse(dart.isSubtypeOf(t, s));
}

void main() {
  checkProperSubtype(B, A);
  checkProperSubtype(C, B);
  checkProperSubtype(C, A);

  checkSubtype(D, generic1(D, B));
  checkSubtype(generic1(D, B), D);
  checkProperSubtype(generic1(D, C), generic1(D, B));
}
