// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we detect that a function literal is not a compile time constant.

class A {
  static Function func;

  static SetFunc([String fmt(int i) = (i) => "$i"]) {
    func = fmt;
  }
}

main() {
  A.SetFunc();
}
