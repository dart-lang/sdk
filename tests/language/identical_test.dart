// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test efficient and correct implementation of !identical(a, b).
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'package:expect/expect.dart';

notIdenticalTest1(a) {
  if (!identical("ho", a)) {
    return 2;
  } else {
    return 1;
  }
}

notIdenticalTest2(a) {
  var x = identical("ho", a);
  if (!x) {
    Expect.equals(false, x);
    return x;
  } else {
    Expect.equals(true, x);
    return 1;
  }
}

notIdenticalTest3(a) {
  var x = identical("ho", a);
  return !x;
}

main() {
  for (int i = 0; i < 20; i++) {
    Expect.equals(1, notIdenticalTest1("ho"));
    Expect.equals(1, notIdenticalTest2("ho"));
    Expect.equals(false, notIdenticalTest3("ho"));
  }
}
