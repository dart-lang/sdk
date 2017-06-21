// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  /*@topType=dynamic*/ m(/*@topType=dynamic*/ x) => x;
  dynamic g(int x) => x;
}

class D extends C {
  /*error:INVALID_METHOD_OVERRIDE*/ T m<T>(T x) => x;
  /*error:INVALID_METHOD_OVERRIDE*/ T g<T>(T x) => x;
}

main() {
  int y = /*info:DYNAMIC_CAST*/ (/*info:UNNECESSARY_CAST*/ new D() as C)
      . /*@target=C::m*/ m(42);
  print(y);
}
