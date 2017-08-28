// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(a);
  const A.named({a: 42});
  const A.optional([a]);
}

main() {
  const A(1);
  const A(); //# 01: compile-time error
  const A(1, 2); //# 02: compile-time error
  const A.named();
  const A.named(b: 1); //# 03: compile-time error
  const A.named(a: 1, a: 2); //# 04: compile-time error
  const A.named(a: 1, b: 2); //# 05: compile-time error
  const A.optional();
  const A.optional(42);
  const A.optional(42, 54); //# 06: compile-time error
}
