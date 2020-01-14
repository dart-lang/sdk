// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C<T> {
  void Function(T) f<U>(U x) => (y) {};
}

void test(C<A> cA, C<A> cB) {
  // Tear-off of c.f needs to be type checked due to contravariance.  The
  // instantiation should occur after the type check, so if the type is wrong we
  // should get a type error.
  void Function(A) Function(int) tearoffOfCA = cA.f;
  Expect.throwsTypeError(() {
    void Function(A) Function(int) tearoffOfCB = cB.f;
  });
}

main() {
  test(new C<A>(), new C<B>());
}
