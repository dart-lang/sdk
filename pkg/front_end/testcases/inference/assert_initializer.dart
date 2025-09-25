// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

T f<T>() => throw '';

class C {
  C.expressionOnly() : assert(f());
  C.expressionAndMessage() : assert(f(), f());
}

main() {
  // Test type inference of assert statements just to verify that the behavior
  // is the same.
  assert(f());
  assert(f(), f());
}
