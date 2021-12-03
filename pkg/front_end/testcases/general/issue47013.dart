// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void m(int n) {}
}

abstract class I {
  void m(covariant num n);
}

class C extends A implements I {}

void main() {
  throws(() => (C() as dynamic).m(1.1));
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
