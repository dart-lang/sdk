// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  bool operator ==(other);
  const A();
}

class B implements A {
  const B();
}

class C extends A {
  const C();
}

class Invalid {
  bool operator ==(other) => false;
  const Invalid();
}

class D implements Invalid {
  const D();
}

main() {
  print(const {A(): 1});
  print(const {B(): 2});
  print(const {C(): 3});
  print(const {D(): 4});
}
