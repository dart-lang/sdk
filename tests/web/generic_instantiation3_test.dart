// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

bool f<T, S>(T a, S b) => a is S;

typedef bool F<P, Q>(P a, Q b);

class B<X, Y> {
  F<X, Y> c;

  B() : c = f;
}

main() {
  Expect.isTrue(new B<int, int>().c(0, 0));
  Expect.isFalse(new B<int, String>().c(0, ''));
}
