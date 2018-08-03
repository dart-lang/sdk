// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const factory A() = B;
}

class B implements A {
  const B();

  operator ==(o) => true; //# 00: compile-time error
}

confuse(x) {
  if (new DateTime.now() == 42) return confuse(2);
  return x;
}

main() {
  // It is a compile-time error if the key type overrides operator ==.
  dynamic m = const {const A(): 42};
  Expect.equals(42, m[confuse(const B())]);

  m = const {"foo": 99, const A(): 499};
  Expect.equals(499, m[confuse(const B())]);
}
