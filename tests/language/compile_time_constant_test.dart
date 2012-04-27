// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bad {
  int foo;
  static int bar
      = foo /// 01: compile-time error
      ;
  static int toto
      = bar /// 02: compile-time error
      ;
}

void use(x) {}

main() {
  use(Bad.bar);
  use(Bad.toto);
}
