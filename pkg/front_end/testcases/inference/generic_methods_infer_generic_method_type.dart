// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  T m<T>(T x) => x;
}

class D extends C {
  /*@topType=D::m::S*/ m<S>(/*@topType=D::m::S*/ x) => x;
}

main() {
  int y = new D(). /*@target=D::m*/ m<int>(42);
  print(y);
}
