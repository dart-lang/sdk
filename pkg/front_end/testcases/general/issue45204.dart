// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension S on int {
  void test(int x) {}
}

extension S2<X> on int {
  void test2(int x) {}
  void test3<Y>(Y y) {}
}

foo() {
  3.test();
  4.test(5, 6);
  5.test<int>(6);

  3.test2();
  4.test2(5, 6);
  5.test2<int>(6);

  3.test3();
  4.test3(5, 6);
  5.test3<int>(6);
  6.test3<int, int>(7);
  7.test3<int, int, int>(8);

  S(3).test();
  S(4).test(5, 6);
  S(5).test<int>(6);

  S2(3).test2();
  S2(4).test2(5, 6);
  S2(5).test2<int>(6);

  S2(3).test3();
  S2(4).test3(5, 6);
  S2(5).test3<int>(6);
  S2(6).test3<int, int>(7);
  S2(7).test3<int, int, int>(8);
}

main() {}
