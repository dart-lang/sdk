// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inference-using-bounds

import '../static_type_helper.dart';

class A1<X extends A1<X, Y>, Y extends A2<X, Y>> {}

class A2<X extends A1<X, Y>, Y extends A2<X, Y>> {}

class B extends A1<B, B> implements A2<B, B> {}

class C1 extends B {}

class C2 extends B {}

class Pair<X, Y> {}

Pair<X, Y> f<X extends A1<X, Y>, Y extends A2<X, Y>>(X x, Y y) =>
    new Pair<X, Y>();

void main() {
  f<B, B>(C1(), C2());
  f(C1(), C2())..expectStaticType<Exactly<Pair<B, B>>>();
}
