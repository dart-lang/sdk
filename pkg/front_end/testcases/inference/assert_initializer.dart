// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class C {
  C.expressionOnly() : assert(/*@typeArgs=bool*/ f());
  C.expressionAndMessage()
      : assert(/*@typeArgs=bool*/ f(), /*@typeArgs=dynamic*/ f());
}

main() {
  // Test type inference of assert statements just to verify that the behavior
  // is the same.
  assert(/*@typeArgs=bool*/ f());
  assert(/*@typeArgs=bool*/ f(), /*@typeArgs=dynamic*/ f());
}
