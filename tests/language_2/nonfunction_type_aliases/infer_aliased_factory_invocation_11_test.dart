// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

import 'package:expect/expect.dart';

class C<X extends Iterable<num>> {
  factory C(Type t) => D<X>(t);
}

class D<X extends Iterable<num>> implements C<X> {
  D(Type t) {
    Expect.equals(t, X);
  }
}

typedef T<X extends int> = C<List<X>>;

Type typeOf<X>() => X;

void main() {
  T<int> x1 = T(typeOf<List<int>>());
  C<Iterable<num>> x2 = T(typeOf<List<int>>());
}
