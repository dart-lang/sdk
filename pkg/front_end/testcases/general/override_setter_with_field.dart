// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void set x(Object y);
}

class B implements A {
  int x;
}

main() {
  new B().x = 5;
}
