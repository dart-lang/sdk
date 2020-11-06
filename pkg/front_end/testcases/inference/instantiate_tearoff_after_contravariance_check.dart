// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  void Function(T) f<U>(U x) => /*@ returnType=Null */ (/*@ type=C::T* */ y) {};
}

void test(C<String> c) {
  // Tear-off of c.f needs to be type checked due to contravariance.  The
  // instantiation should occur after the type check.
  void Function(String) Function(int) tearoff = c. /*@target=C.f*/ f;
}

main() {}
