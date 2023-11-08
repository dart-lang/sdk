// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  bool v1;
  num v2;
  A(bool this.v1, {required num this.v2});
}

mixin class M1 {
  num v2 = -1;
}

class C = A with M1;

test() {
  C c = C(true);
}
