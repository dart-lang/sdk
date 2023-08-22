// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type IC1Unused(int id) {}

extension type IC2(int id) {
  int foo1() => id + 1;
  int foo2Unused() => id + 2;
  static IC2 bar1(IC2 x) => IC2(x.id + 1);
  static IC2 bar2Unused(IC2 x) => IC2(x.id + 1);
}

unused1() {
  print(IC1Unused(42));
  print(IC1Unused(42).id + 1);
}

class C3Unused {
  foo3Unused(IC2 x) {
    print(x.foo2Unused());
    print(IC2.bar2Unused(x));
  }
}

class C4 {
  foo3(IC2 x) {
    print(x.foo1());
    print(IC2.bar1(x));
  }
}

main() {
  C4().foo3(IC2(42));
}
