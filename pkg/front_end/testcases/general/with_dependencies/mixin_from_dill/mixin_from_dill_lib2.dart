// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo extends B with D {}
abstract class B implements C {
  bool operator==(dynamic) {
    print("B.==");
    return true;
  }
  void x() {
    print("B.x");
  }
}
abstract class C {}
abstract class D implements C {
  bool operator==(dynamic) {
    print("D.==");
    return true;
  }

  void x() {
    print("D.x");
  }
}
