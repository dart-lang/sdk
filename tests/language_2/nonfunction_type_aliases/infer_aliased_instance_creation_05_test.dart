// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

import 'package:expect/expect.dart';

class C<X, Y> {
  C(Type tx, Type ty) {
    Expect.equals(tx, X);
    Expect.equals(ty, Y);
  }
}

typedef T<Y, X> = C<X, Y>;

void main() {
  T<int, String> x1 = T(String, int);
  C<String, int> x2 = T(String, int);
}
