// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class B {}

class C extends B {
  var z;
}

void test(B x) {
  var y = x is C ? x : new C();
  print(y.z);
}

main() {}
