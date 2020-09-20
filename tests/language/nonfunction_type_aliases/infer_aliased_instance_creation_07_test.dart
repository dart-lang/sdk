// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

import 'package:expect/expect.dart';

class C<X> {
  C(X x, Type t) {
    Expect.equals(t, X);
  }
}

typedef T<X> = C<List<X>>;

Type typeOf<X>() => X;

void main() {
  T(<num>[1], typeOf<List<num>>());
}
