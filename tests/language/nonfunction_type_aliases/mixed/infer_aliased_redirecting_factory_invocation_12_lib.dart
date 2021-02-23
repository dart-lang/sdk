// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C<X extends String, Y extends num> {
  factory C(Type tx, Type ty) = D<X, Y>;
}

class D<X extends String, Y extends num> implements C<X, Y> {
  D(Type tx, Type ty) {
    Expect.equals(tx, X);
    Expect.equals(ty, Y);
  }
}

typedef T<Y extends int, X extends String> = C<X, Y>;
