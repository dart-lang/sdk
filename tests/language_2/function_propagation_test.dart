// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int call(String str) => 499;
}

typedef int F(String str);

main() {
  var a = new A();
  Expect.isFalse(a is A);

  var a2 = new A();
  Expect.isFalse(a is F);

  Function a3 = new A();
  Expect.isFalse(a3 is A);

  F a4 = new A();
  Expect.isFalse(a4 is A);
}
