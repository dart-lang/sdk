// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  List<T> f<T>(T g()) => <T>[g()];
}

main() {
  var /*@type=List<int>*/ v =
      new C(). /*@target=C::f*/ f<int>(/*@returnType=int*/ () {
    return 1;
  });
}
