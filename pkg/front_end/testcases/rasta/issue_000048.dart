// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  bool v1;
  num v2;
  A(bool this.v1, num this.v2);
}

class M1 {
  num v2 = 0;
}

class C = A with M1;

main() {
  C c = new C(true, 2);
}
