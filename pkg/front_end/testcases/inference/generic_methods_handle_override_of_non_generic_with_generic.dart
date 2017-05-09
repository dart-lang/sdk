// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  m(x) => /*@promotedType=none*/ x;
  dynamic g(int x) => /*@promotedType=none*/ x;
}

class D extends C {
  /*error:INVALID_METHOD_OVERRIDE*/ T m<T>(T x) => /*@promotedType=none*/ x;
  /*error:INVALID_METHOD_OVERRIDE*/ T g<T>(T x) => /*@promotedType=none*/ x;
}

main() {
  int y = /*info:DYNAMIC_CAST*/ (/*info:UNNECESSARY_CAST*/ new D() as C).m(42);
  print(/*@promotedType=none*/ y);
}
