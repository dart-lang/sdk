// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

import 'package:expect/expect.dart';

class C {
  factory C() = D;
}

class D implements C {}

typedef T<X> = C;

void main() {
  T<num> x1 = T();
  C x2 = T();
}
