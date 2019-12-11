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
  Expect.type<A>(a);
  Expect.notType<F>(a);

  Function a3 = new A();
  Expect.notType<A>(a3);

  F a4 = new A();
  Expect.notType<A>(a4);
}
