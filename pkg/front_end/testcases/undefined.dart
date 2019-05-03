// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  var x;
  void f() {}
}

void test(C c) {
  c.x;
  c.y;
  c.f();
  c.g();
  c.x = null;
  c.y = null;
}

main() {}
