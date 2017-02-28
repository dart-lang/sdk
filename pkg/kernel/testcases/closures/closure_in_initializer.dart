// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C {
  var t;
  C.foo(f) : t = (() => f()) {
    print(1);
  }
}

main() {
  print(0);
  var c = new C.foo(() => print('hest'));
  print(2);
  c.t();
  print(3);
}
