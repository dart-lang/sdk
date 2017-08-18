// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C {
  var t;
  C.foo(f, x) : t = (() => f(x)) {
    x = 1;
    print(x);
  }
}

main() {
  print(0);
  var c = new C.foo((x) => print('hest${x}'), 0);
  print(2);
  c.t();
  print(3);
}
