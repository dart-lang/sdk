// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int a;
}

class B extends A {
  B() : super.a = 42;
}

class C {
  C() : super = 42;
}

main() {
  try {
    var b = new B();
  } catch (_) {
    // ignore
  }
  try {
    var c = new C();
  } catch (_) {
    // ignore
  }
}
