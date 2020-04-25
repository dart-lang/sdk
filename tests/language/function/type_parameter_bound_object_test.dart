// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Q hest<Q>(dynamic x) {
  if (x is Q) return x;
  throw "unreached";
}

Q Function<Q>(dynamic) pony = hest;
Q Function<Q extends Object?>(dynamic) zebra = hest;

main() {
  hest(42).fisk(); //# 01: runtime error
  pony(42).fisk(); //# 02: runtime error
  zebra(42).fisk(); //# 03: compile-time error
}
