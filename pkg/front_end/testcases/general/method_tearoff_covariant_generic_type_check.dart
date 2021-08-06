// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {
  void f<Y extends X>(Y y) {}
}

expectThrows(void Function() f) {
  try {
    f();
  } catch (e) {
    return;
  }
  throw "Expected an exception to be thrown!";
}

main() {
  A<num> a = new A<int>();
  expectThrows(() {
    void Function<Y extends num>(Y) f = a.f;
  });
}
