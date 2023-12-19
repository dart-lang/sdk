// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C<X, Y> {
  C(Type tx, Type ty) {
    Expect.equals(tx, X);
    Expect.equals(ty, Y);
  }
}

typedef T<Y, X> = C<X, Y>;
