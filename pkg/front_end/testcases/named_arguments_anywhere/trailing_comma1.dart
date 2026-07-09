// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var c = new C();
var z = 42;

class C {
  void instance1({z}) {}
  void instance2(a, {z}) {}
}

main() {}

class Bad {
  method() {
    c.instance1(z:z,,);
    c.instance2(z:z,,);
  }
}
