// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B {}

class C<T> {
  void a<X extends A>(void Function<Y extends B>(A) p) {}
  void b<X extends A>(void Function<Y extends B>(B) p) {}
  void x<X extends A>(void Function<Y extends B>(X) p) {}
  void y<X extends A>(void Function<Y extends B>(Y) p) {}

  void ar<X extends A>(A Function<Y extends B>() p) {}
  void br<X extends A>(B Function<Y extends B>() p) {}
  void xr<X extends A>(X Function<Y extends B>() p) {}
  void yr<X extends A>(Y Function<Y extends B>() p) {}

  bool testA() => a is void Function<X extends A>(T);
  bool testB() => b is void Function<X extends A>(T);
  bool testX() => x is void Function<X extends A>(T);
  bool testY() => y is void Function<X extends A>(T);

  bool testAR() => ar is void Function<X extends A>(T);
  bool testBR() => br is void Function<X extends A>(T);
  bool testXR() => xr is void Function<X extends A>(T);
  bool testYR() => yr is void Function<X extends A>(T);
}

typedef AF = void Function<Y extends B>(A);
typedef BF = void Function<Y extends B>(B);
typedef YF = void Function<Y extends B>(Y);

typedef ARF = A Function<Y extends B>();
typedef BRF = B Function<Y extends B>();
typedef YRF = Y Function<Y extends B>();

main() {
  Expect.isTrue(C<AF>().testA());
  Expect.isFalse(C<AF>().testB());
  Expect.isTrue(C<AF>().testX());
  Expect.isFalse(C<AF>().testY());

  Expect.isFalse(C<BF>().testA());
  Expect.isTrue(C<BF>().testB());
  Expect.isFalse(C<BF>().testX());
  Expect.isTrue(C<BF>().testY());

  Expect.isFalse(C<YF>().testA());
  Expect.isFalse(C<YF>().testB());
  Expect.isFalse(C<YF>().testX());
  Expect.isTrue(C<YF>().testY());

  Expect.isTrue(C<ARF>().testAR());
  Expect.isFalse(C<ARF>().testBR());
  Expect.isFalse(C<ARF>().testXR());
  Expect.isFalse(C<ARF>().testYR());

  Expect.isFalse(C<BRF>().testAR());
  Expect.isTrue(C<BRF>().testBR());
  Expect.isFalse(C<BRF>().testXR());
  Expect.isFalse(C<BRF>().testYR());

  Expect.isFalse(C<YRF>().testAR());
  Expect.isTrue(C<YRF>().testBR());
  Expect.isFalse(C<YRF>().testXR());
  Expect.isTrue(C<YRF>().testYR());
}
