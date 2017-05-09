// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  T m<T>(T x) => /*@promotedType=none*/ x;
}

class D extends C {
  m<S>(x) => /*@promotedType=none*/ x;
}

main() {
  int y = new D(). /*@typeArgs=int*/ m<int>(42);
  print(/*@promotedType=none*/ y);
}
