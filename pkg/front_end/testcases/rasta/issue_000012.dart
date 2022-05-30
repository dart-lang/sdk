// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  var field;
}

class B extends A {
  m() {
    super.field = 42;
  }
}

main() {
  new B().m();
}
