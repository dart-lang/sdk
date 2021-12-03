// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void m(num n, int i) {}
}

class B extends A {
  void m(covariant int i, covariant num n);
}

main() {
  B b = B();
  throws(() => b.m(1.5, 0));
  A a = b;
  throws(() => a.m(1, 1.5));
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Exception expected';
}
