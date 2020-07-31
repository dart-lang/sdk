// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import "package:expect/expect.dart";

class A {}

class B {}

Type type<T>() => T;

Type listType<T>() => <T>[].runtimeType;

main() {
  var a = new A();
  var b = new B();
  Expect.isTrue(A == A);
  Expect.isTrue(B == B);
  Expect.isFalse(A == B);
  Expect.isTrue(A == a.runtimeType);
  Expect.isTrue(B == b.runtimeType);
  Expect.isFalse(a.runtimeType == b.runtimeType);
  Expect.isFalse(A == int);
  Expect.isFalse(A == 123);
  Expect.isTrue(int == int);
  Expect.isTrue(int == 0.runtimeType);
  Expect.isTrue(int == 0x8000000000000000.runtimeType);
  Expect.isTrue(String == "x".runtimeType);
  Expect.isTrue(String == "\u{1D11E}".runtimeType);

  Expect.isTrue(type<int?>() == type<int?>());
  Expect.isFalse(type<int?>() == type<int>());
  Expect.isFalse(type<int>() == type<int?>());
  Expect.isTrue(type<int>() == type<int>());
}
